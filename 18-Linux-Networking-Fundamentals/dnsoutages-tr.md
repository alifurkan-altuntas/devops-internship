# 🔥 Gerçek Dünya Cloud Kesintileri — Tek Hata Noktası Olarak DNS

Bu belge, AWS, Cloudflare, ve Google Cloud'dan gerçek, araştırılmış olayları kapsar, her birinde DNS'in nasıl bir rol oynadığına (ya da oynamadığına) odaklanarak. Amaç: bu fazda öğrenilen DNS kavramlarını (A kayıtları, otomasyon, cache'leme, resolver zincirleri), gerçekten dünya çapında haber olmuş büyük ölçekli arızalarla bağlamak.

---

## 1. AWS — 19-20 Ekim 2025: DynamoDB DNS Race Condition

### Ne Oldu

AWS'nin `us-east-1` bölgesinde (en eski ve en yoğun AWS veri merkezi), yaklaşık 15 saat süren bir kesinti — DynamoDB, EC2, Lambda, ve düzinelerce bağımlı servisi etkiledi. Zoom, Slack, Monday.com gibi büyük platformlar etkilendi.

### Kök Sebep — Bu Fazda Öğrendiklerimizle Doğrudan İlişkili

DynamoDB, **yüz binlerce DNS kaydını** otomatik olarak yönetir, iki iç bileşen kullanarak:

- **DNS Planner**: load balancer sağlığını izler, trafiğin nereye gitmesi gerektiğine karar verir.
- **DNS Enactor**: bu kararları, DNS kayıtlarını güncelleyerek gerçekten uygular (güvenlik için birden fazla bölgede, yedekli olarak çalışır).

Bir **race condition** (bu DNS Enactor süreçlerinden ikisinin, birbirine çok yakın zamanlarda çalışıp birbirinin işine karışması), otomasyonun DynamoDB'nin bölgesel endpoint'i (`dynamodb.us-east-1.amazonaws.com`) için **DNS kaydını tamamen silmesine** sebep oldu. A kaydı, basitçe... kayboldu.

### Bunu Öğrendiklerimizle Bağlayalım

Bu, tam olarak DNS cache'leme ve otomasyonun nasıl çalıştığı sayesinde **mümkün olan** bir hata türü:

- Endpoint'in **hiç A kaydı yoktu** — yanlış bir kayıt değil, _boş_ bir kayıt. Bu domain'i çözmeye çalışan her şey **hiçbir cevap alamadı** — bu fazda daha önce test ettiğimiz `NXDOMAIN` ile aynı kategoride bir hata, ama burada bu, **var olması gereken** bir kayıtta **istenmeyen** bir hataydı.
- DynamoDB, **birçok başka AWS servisinin (ve birçok şirketin kendi altyapısının) bağımlı olduğu** bir servis olduğu için, tek bir eksik DNS kaydı sadece DynamoDB'yi değil, **zincirleme olarak dışarı** yayıldı — tıpkı bir router arızasının, ona bağımlı her şeyi etkilemesi gibi.
- Çözüm, **manuel müdahale** gerektirdi — bu kadar hızlı ve geniş çapta DNS kayıtlarını güncelleyen bir otomasyon güçlü, ama içindeki bir hata, bir insan tepki veremeden **küresel olarak** her şeyi bozabiliyor.

### Asıl Ders

Tek, otomatik bir sistemin **sessizce bir DNS kaydını silmesi**, internetin büyük bir kısmını **15 saat boyunca** çökertti. Bu, "ya authoritative sunucu yanlış cevap verirse" sorusunun gerçek dünya versiyonu — sadece burada, **hiç** cevap vermedi.

---

## 2. Cloudflare — Birden Fazla Büyük DNS-İlişkili Olay

Cloudflare, bu fazın test sürecinde sürekli kullandığımız `1.1.1.1` public DNS resolver'ını çalıştırıyor — bu da kendi kesinti geçmişini özellikle ilişkili kılıyor.

### 4 Ekim 2023 — DNSSEC İmza Süresinin Dolması

İnternetin **root zone**'una, 21 Eylül'de yeni bir DNS kayıt tipi (`ZONEMD`) eklendi. 4 Ekim'de, bu değişikliğe bağlı **DNSSEC imzalarının** süresi doldu, ve Cloudflare'in resolver'ları — ki bunlar DNS cevaplarının değiştirilmediğini doğrulamak için DNSSEC imzalarını kontrol eder — yeni imzayı **doğrulayamadı.** Sonuç: Cloudflare'in resolver'ları, yaklaşık 3 saat boyunca, geçerli sorgulara `SERVFAIL` hatası döndürdü.

**Bu fazla bağlantı:** bu, daha önce `dig +trace` çıktısında gördüğümüz **tam olarak aynı root-zone mekanizmasını** içeren, gerçek bir hata — o zaman "DNSSEC, ileri seviye konu, şimdilik atla" diye not ettiğimiz `DS` ve `RRSIG` satırları hatırlarsan. İşte tam olarak o mekanizmanın, büyük bir resolver'ı bozduğu bir örnek.

### 14 Temmuz 2025 — Uykuda Kalan Bir Config Hatası, 1.1.1.1'i Çökertiyor

6 Haziran'da girilen bir yapılandırma hatası, **bir aydan fazla tamamen uykuda kaldı** (hiçbir etki, hiçbir alarm, çünkü etkilenen yapılandırma henüz hiç kullanılmıyordu). 14 Temmuz'da, ilgisiz bir değişiklik bunu tetikledi: 1.1.1.1 resolver'ının IP aralıkları, **internetin yönlendirme tablolarından yanlışlıkla geri çekildi** (bir BGP seviyesi sorunu, tam olarak DNS değil, ama DNS _hizmetini_ ulaşılamaz hale getirdi). Sonuç: 1.1.1.1, küresel olarak 62 dakika boyunca çöktü.

**İlginç bir yan not:** kaos sırasında, başka bir şirketin router'ı kısa süreliğine `1.1.1.1` için de bir rota duyurdu (küçük, kasıtsız bir BGP hijack) — bu, gerçek sebep değildi, ama birden fazla ağ-seviyesi sorununun nasıl çakışıp, anlık olarak birbiriyle ilişkili görünebileceğinin iyi bir gerçek dünya örneği.

### 18 Kasım 2025 — Bot Management Feature Dosyası

Esasen bir DNS hatası değil, ama aynı kırılganlık temasını gösteriyor: rutin bir veritabanı izin değişikliği, Cloudflare'in bot tespiti tarafından kullanılan dahili bir "feature dosyasının" **boyutunun ikiye katlanmasına** sebep oldu, bu da Cloudflare'in çekirdek proxy yazılımındaki **sert bir limiti aştı**, ve yazılımın **tüm küresel ağlarında çökmesine** sebep oldu. Yaklaşık 3 saat sürdü, X, ChatGPT, Spotify, ve binlerce başka siteye erişimi bozdu.

### Üçünden de Çıkan Genel Ders

Cloudflare'in kendi olay sonrası raporları, tekrar tekrar **aynı şeyi** söylüyor: **çoğu büyük kesintiye saldırılar değil, dahili yapılandırma değişiklikleri sebep oluyor.** Küresel ve anlık olarak yayılan tek bir kötü config (ki bu normalde bir _özellik_ — her yere hızlı güncelleme), her şeyi aynı anda çökertmenin tam mekanizması haline geliyor.

---

## 3. Google Cloud — 12 Haziran 2025: DNS Değil, Ama Neden Olduğunu Anlamak Değerli

### Ne Oldu

50'den fazla Google Cloud ürününü etkileyen, 7 saatten uzun süren bir kesinti — ayrıca Cloudflare'in bir kısmını (bazı Cloudflare servisleri Google Cloud'a bağımlı olduğu için), Spotify ve Discord gibi başka servisleri de etkiledi.

### Kök Sebep — Önemli Bir Ayrım

Bu, **bir DNS hatası değildi** — bir **yetkilendirme (IAM) hatasıydı.** Servisler arası kimlik doğrulama için kullanılan bir politika veritabanı, geçersiz veriyle bozuldu, ve bu bozulma Google'ın iç sistemleri aracılığıyla **küresel olarak çoğaldı.** Servisler, kimlik doğrulamanın kendisi hâlâ çalışıyor olsa bile, **neyi yapmaya izinli olduklarını** doğrulayamadı.

### Bu Neden Yine de DNS Notlarına Dahil Edilmeli

Bu, bilinçli, önemli bir karşı-örnek: **her büyük internet kesintisi bir DNS sorunu değil.** Bunu özellikle eklemeye değer, _çünkü_ DNS'in sorumlu olduğu şeyin sınırını gösteriyor — DNS, "bu servisi nerede bulurum" sorusuna cevap verir, bu kesinti ise "onu bulduktan sonra kullanmaya izinli miyim" ile ilgiliydi, tamamen farklı bir hata katmanı. Bu ayrımı tanımak, DNS'in gerçek kapsamını anlamanın bir parçası.

Bu kesinti, **gerçekten** başka şirketlerin altyapısına (Cloudflare, Spotify, Discord) zincirleme olarak yayıldı — tıpkı AWS DynamoDB hatasının yaptığı gibi — modern altyapıda, neredeyse hiçbir şeyin gerçekten izole bir şekilde başarısız olmadığının bir hatırlatıcısı.

---

## 📊 Özet Tablo

| Olay                | Tarih           | Kök Sebep                                                     | DNS Dahil mi?                                                          | Süre      |
| ------------------- | --------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------- | --------- |
| AWS DynamoDB        | 19-20 Ekim 2025 | Race condition, bir DNS A kaydını sildi                       | ✅ Doğrudan — boş DNS kaydı                                            | ~15 saat  |
| Cloudflare DNSSEC   | 4 Ekim 2023     | Root zone değişikliği sonrası DNSSEC imzalarının süresi doldu | ✅ Doğrudan — resolver doğrulama hatası                                | ~3 saat   |
| Cloudflare 1.1.1.1  | 14 Temmuz 2025  | Uykuda kalan config hatası + BGP rota geri çekilmesi          | 🟡 Dolaylı — DNS hizmeti ulaşılamaz oldu, kendisi bir DNS hatası değil | 62 dakika |
| Cloudflare Bot Mgmt | 18 Kasım 2025   | Aşırı büyük dahili config dosyası, çekirdek proxy'yi çökertti | ❌ DNS değil — proxy/yazılım hatası                                    | ~3 saat   |
| Google Cloud IAM    | 12 Haziran 2025 | Bozulmuş yetkilendirme politika veritabanı                    | ❌ DNS değil — yetkilendirme hatası                                    | ~7 saat   |

---

## 🎓 Genel Çıkarımlar

1. **DNS otomasyonu güçlü ve tehlikeli.** DynamoDB'nin yüz binlerce kaydı verimli bir şekilde yönetmesini sağlayan aynı otomasyon, hiçbir insan müdahalesi olmadan onlardan birini silen şeyin tam olarak kendisi.
2. **DNSSEC, bir güvenlik özelliği olsa da, kendisi de potansiyel bir hata noktası** — eğer imzaların süresi dolarsa veya doğrulanamazsa, resolver'lar "kapalı başarısız olur" (fail closed — kötü veri sunmaktan daha iyi, ama yine de bir kesinti).
3. **Her kesinti DNS değil** — Google Cloud ve Cloudflare bot-management olayları, tam olarak DNS'in **sorumlu olmadığı** şeyi gösterdiği için değerli, bu fazda gerçekten öğrenilenin sınırını netleştiriyor.
4. **Bağımlılıklar zincirleme yayılır.** Bir şirketin çekirdek servisindeki (AWS DynamoDB, Google IAM) bir hata, ona bağımlı diğer şirketlere doğru dalgalanır — bu fazın başlarında `traceroute`/router-hop tartışmasında gördüğümüz "yoldaki her cihaz önemli" fikrinin aynısı, sadece network hop'ları yerine bütün şirketler ölçeğinde.

---

## 📚 Kaynaklar

- AWS DynamoDB kesinti analizi — Forbes: https://www.forbes.com/sites/kateoflahertyuk/2025/10/23/aws-outage-new-analysis-explains-what-went-wrong-and-why/
- AWS DynamoDB kesintisi, kök sebep doğrulaması — BleepingComputer: https://www.bleepingcomputer.com/news/technology/amazon-this-weeks-aws-outage-caused-by-major-dns-failure/
- AWS DynamoDB kesintisi, tam teknik döküm — Pragmatic Engineer (Gergely Orosz): https://newsletter.pragmaticengineer.com/p/what-caused-the-large-aws-outage
- AWS kesintisi ve kritik altyapı zafiyeti olarak DNS — Akamai: https://www.akamai.com/blog/security/when-cloud-breaks-lessons-aws-outage
- Cloudflare DNSSEC olayı (4 Ekim 2023) ve kesinti geçmişi — N2W Software: https://n2ws.com/blog/cloudflare-outage
- Cloudflare 1.1.1.1 kesintisi (14 Temmuz 2025), resmi rapor — Cloudflare Blog: https://blog.cloudflare.com/cloudflare-1-1-1-1-incident-on-july-14-2025/
- Cloudflare 1.1.1.1 kesintisi, bağımsız analiz — ThousandEyes: https://www.thousandeyes.com/blog/cloudflare-outage-analysis-july-14-2025
- Cloudflare Bot Management kesintisi (18 Kasım 2025), resmi rapor — Cloudflare Blog: https://blog.cloudflare.com/18-november-2025-outage/
- Cloudflare Bot Management kesintisi, bağımsız analiz — ThousandEyes: https://www.thousandeyes.com/blog/cloudflare-outage-analysis-november-18-2025
- Google Cloud IAM kesintisi (12 Haziran 2025), bağımsız analiz — ThousandEyes: https://www.thousandeyes.com/blog/google-cloud-outage-analysis-june-12-2025
- Google Cloud IAM kesintisi, Cloudflare/Spotify/Discord'a zincirleme etkisi — Network World: https://www.networkworld.com/article/4006705/google-cloud-outage-disrupts-over-50-services-globally-for-over-7-hours.html
- Google Cloud IAM kesintisi, ek detay — TechRadar: https://www.techradar.com/pro/we-know-what-caused-the-recent-massive-google-cloud-outage-and-its-a-bit-embarassing

---

ℹ️ _Web araştırması yoluyla araştırılmıştır; tüm olaylar, şirketlerin kendi mühendislik bloglarından ve bağımsız izleme servislerinden (ThousandEyes, vb.) gelen gerçek, belgelenmiş olay sonrası raporlarına dayanmaktadır._
