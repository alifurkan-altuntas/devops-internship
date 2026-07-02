# 🌐 OSI Modeli — Katmanlar, Gerçek Senaryolar, ve Gerçek Paket Doğrulaması

✅ **Durum: Tamamlandı.** 7 katman, gerçek senaryolarda katman ayırt etme, encapsulation/decapsulation, router davranışı, ve gerçek dünya sağlayıcıları arasında ICMP/traceroute davranışı — hepsi işlendi ve uygulamalı olarak doğrulandı.

---

## 1. OSI Modeli Nedir

Ağ iletişimini 7 katmana bölen kavramsal bir çerçeve. Her katmanın kendi işi var, ve sadece kendi üstündeki/altındaki katmanla nasıl konuşacağını bilmesi gerekir.

```
7. Application   ← kullanıcının/uygulamanın doğrudan kullandığı protokoller (HTTP, DNS, FTP, SSH)
6. Presentation  ← veri formatı, şifreleme (TLS/SSL), sıkıştırma
5. Session       ← bir bağlantıyı başlatma/sürdürme/sonlandırma
4. Transport     ← TCP/UDP, port numaraları, güvenilir vs güvenilmez iletim
3. Network       ← IP adresleri, ağlar arası yönlendirme
2. Data Link     ← MAC adresleri, aynı yerel ağ içindeki iletişim
1. Physical      ← kablolar, sinyaller, ham bitler
```

---

## 2. Gerçek Örnekler Üzerinde Çalışma

Her işlem 7 katmanın hepsini kullanmıyor.

### `dig google.com` (düz DNS sorgusu)

- **Layer 3** — sorgu, bir DNS sunucusuna IP üzerinden yönlendirilir.
- **Layer 4** — DNS genelde UDP, port 53 kullanır.
- **Layer 7** — DNS, bir uygulama katmanı protokolüdür.
- **Layer 6 — kullanılmıyor.** Düz bir DNS sorgusunda şifreleme/format dönüşümü yok.

### `curl https://example.com` (HTTPS)

- Yukarıdakiyle aynı Layer 3, 4, 7.
- **Layer 6 — kullanılıyor**, çünkü `https://` TLS şifrelemesini tetikliyor.

### `ssh user@<ip>` (IP ile bağlanma)

- **Layer 1-4** — her zaman gerekli.
- **Layer 5** — oturum yönetimi.
- **Layer 6** — SSH varsayılan olarak şifreler.
- **Layer 7** — SSH'ın kendisi bir uygulama katmanı protokolü, DNS'in devrede olup olmamasından bağımsız olarak.

**Buradaki kilit netleşme:** Layer 7, hangi **aracın** kullanıldığıyla değil, hangi **protokolün konuşulduğuyla** ilgili. IP ile bağlanmak sadece DNS'in devrede olmadığı anlamına gelir, SSH'ın kendisini Layer 7'den çıkarmaz.

---

## 3. Layer 2 vs Layer 3 — İkisi de Neden Gerekli

- **Layer 3 (IP)** = bir zarfın üzerine yazılan adres.
- **Layer 2 (MAC)** = o zarfı, yerel ağ içinde doğru eve gerçekten ulaştıran şey.

---

## 4. Encapsulation ve Decapsulation

Veri, Layer 7'den Layer 1'e inerken, her katman onu kendi header'ıyla sarar:

```
[Layer 2: MAC header]
  [Layer 3: IP header]
    [Layer 4: TCP/UDP header — port bilgisini içerir]
      [Layer 7: gerçek veri]
```

Alıcı tarafta bu işlem tersten gerçekleşir (**decapsulation**) — her katman kendi header'ını soyar, kalanını üst katmana iletir.

### Yol Üzerindeki Her Router'da Gerçekte Ne Olur

Bir paket sadece bir kez sarılıp, hedefte bir kez açılmıyor — yol üzerindeki **her router**, paketi kısmen açıp yeniden sarıyor:

| Katman              | Router'ın Yaptığı Şey                                                                                             |
| ------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Layer 7 (HTTP, vb.) | Hiç dokunulmaz, görmezden gelinir                                                                                 |
| Layer 4 (TCP/port)  | Temel routing için genelde dokunulmaz                                                                             |
| Layer 3 (IP)        | **Sadece okunur** — paketin nereye gideceğine karar vermek için kullanılır, ama IP adresinin kendisi hiç değişmez |
| Layer 2 (MAC)       | Her hop'ta **sökülür ve yeniden yazılır**                                                                         |

**MAC değişirken IP neden değişmiyor:** IP adresi nihai hedef — paket kaç router'dan geçerse geçsin aynı kalmalı. MAC adresi ise sadece **tek bir yerel ağ segmenti** içinde anlamlı, bu yüzden her router, eski MAC'i söküp, paketin girdiği **bir sonraki** yerel segment için yeni bir MAC header eklemek zorunda.

Basit benzetme: IP adresi, bir zarfın üzerindeki nihai adres gibi — yolculuk boyunca hiç değişmez. MAC adresi ise yerel bir kuryenin teslim kodu gibi — zarfın geçtiği her depoda değişir, çünkü her depo sadece zarfı **bir sonraki depoya** ulaştırmayı bilmesi gerekir.

---

## 5. ICMP, ve `traceroute`'un Bazen Sonuçsuz Gitmesinin Sebebi

**ICMP (Internet Control Message Protocol)**, bir kontrol/diagnostik protokolü — uygulama verisi taşımaz, ağın kendisi hakkında durum/hata mesajları taşır. Layer 3'te, IP ile birlikte çalışır.

- **`ping`**, bir ICMP **Echo Request** gönderir; bir cevap (**Echo Reply**) gelirse "buradayım" demektir.
- **`traceroute`**, kasıtlı olarak düşük TTL değerleriyle paketler gönderir. Bir router'ın TTL'i sıfıra düştüğünde, o router bir ICMP **"Time Exceeded"** mesajıyla cevap verir — traceroute, yoldaki her hop'u bu şekilde keşfeder.

### Gerçek Test: Sağlayıcıları Karşılaştırma

Aynı sunucudan, birden fazla gerçek hedefe `traceroute` çalıştırılarak, başarısızlıkların **yerel** (sunucunun kendi ağı) mı yoksa **hedefe özgü** mü olduğu ayrıldı:

| Hedef                    | `traceroute` tamamlandı mı?                                                                                                                    | `ping` sonucu                                                        |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `1.1.1.1` (Cloudflare)   | ✅ Hedefe ulaştı                                                                                                                               | (ayrıca test edilmedi — traceroute zaten ulaşılabilirliği doğruladı) |
| `claude.ai`              | ✅ Hedefe ulaştı                                                                                                                               | (aynı)                                                               |
| `google.com` / `8.8.8.8` | ❌ Hiç tamamlanmadı (4. hop'tan sonra sessizlik)                                                                                               | ✅ `ping` başarılı, %0 paket kaybı                                   |
| `turkiyesigorta.com.tr`  | ❌ Hiç tamamlanmadı, ama sonraki hop'larda şirketin iç ağına ait `10.x.x.x` adresleri görüldü, paketin şirketin iç ağına ulaştığını gösteriyor | ❌ `ping` tamamen başarısız — %100 paket kaybı                       |

**Sonuç:** Cloudflare ve Claude.ai'ın traceroute'ları aynı makineden sorunsuz tamamlandığı için, sorun **yerel ağda/sağlayıcıda değil** — her hedefin ICMP'ye cevap verme **kendi politikası** farklılık gösteriyor.

### Kurumların Bunu Neden Farklı Ele Aldığı

- **Cloudflare**, tamamen açık bırakıyor — bir altyapı/network sağlayıcısı olarak, şeffaflık ve gösterilebilir performans, değer önerilerinin bir parçası.
- **Google**, `ping`'e izin veriyor ama `traceroute`'u engelliyor — basit bir "ayakta mısın" kontrolü düşük riskli ve izleme araçları tarafından yaygın kullanılıyor, ama iç ağ topolojisini (traceroute'un göstereceği) açığa çıkarmak, büyük, sürekli hedef olan bir altyapı için gereksiz bir risk.
- **Türkiye Sigorta**, ICMP'yi tamamen engelliyor — finans/sigorta sektöründe yaygın olan deny-by-default güvenlik duruşuyla tutarlı; ICMP'nin neredeyse hiçbir iş değeri yok ama bir risk taşıyor, bu yüzden kısmen değil, tamamen devre dışı bırakılıyor.

Bu, önceki fazlarda (SSH, sudoers) öğrenilen Least Privilege prensibinin **aynı temel mantığı** — burada komut seviyesi yerine ağ seviyesi erişime uygulanmış: sadece gerçekten gerekli olanı aç, açığa çıkan riskle karşılaştırarak.

---

## 6. Routing & Forwarding

Bu iki terim, İngilizce anlamlarıyla doğrudan örtüşüyor, bu da akılda tutmayı kolaylaştırdı:

- **Routing** = planlama adımı. Router'lar (veya bir host'un kendi routing tablosu), bir paketin hedefe ulaşmak için **hangi yolu** kullanması gerektiğini hesaplar.
- **Forwarding** = uygulama adımı. Yol belirlendikten sonra, paketi gerçekten **bir adım ileri** göndermek.

Basit benzetme: routing, Google Maps'in en iyi rotayı hesaplaması; forwarding, o rota boyunca her kavşakta gerçekten dönmek.

### Gerçek Bir Routing Tablosunu Okumak

```bash
ip route
```

```text
default via 91.151.88.1 dev ens192 proto static
91.151.88.0/24 dev ens192 proto kernel scope link src <SERVER_IP>
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
```

- **1. Satır (`default via ...`)** — yedek kural: başka bir kural eşleşmezse, paketi bu gateway'e gönder. `proto static`, bu kuralın elle (bu durumda, sunucu sağlayıcının varsayılan kurulumuyla) yapılandırıldığını, otomatik keşfedilmediğini gösterir.
- **2. Satır (`91.151.88.0/24 ... scope link`)** — bu IP aralığındaki herhangi bir şeye, gateway'e gerek kalmadan **doğrudan** ulaşılabilir, çünkü aynı yerel ağda. `proto kernel`, bu kuralın, interface'e IP atandığında **kernel tarafından otomatik** oluşturulduğunu gösterir.
- **3. Satır (`172.17.0.0/16 ... docker0 ... linkdown`)** — Docker'ın container'lar için kendi sanal ağı. Buradaki `linkdown`, sadece o an **aktif çalışan hiçbir container olmadığını** gösteriyordu (`docker ps -a`, iki container'ın `Exited` durumda olduğunu, çalışmadığını doğruladı) — interface var ama şu an aktif değil.

### Statik vs Dinamik Routing

`proto static` / `proto kernel` etiketleri bu ayrıma işaret ediyor:

- **Statik routing**: bir insan, elle bir kural tanımlar ("X'e ulaşmak için, Y'den geç"). Basit, ama uyum sağlamaz — bir yol kesilirse, biri elle düzeltene kadar kesik kalır. Bu sunucu gibi, tek bir belirgin çıkış yolu olan küçük kurulumlar için uygundur.
- **Dinamik routing**: router'lar, birbirleriyle konuşarak en iyi yolları **otomatik olarak keşfeder ve güncellerler**, **BGP** (internetteki büyük ağlar/ISP'ler arası kullanılır) veya **OSPF** (büyük kurumsal ağlar içinde yaygın) gibi protokoller kullanarak. Bir yol başarısız olursa otomatik olarak uyum sağlar.

### IP Forwarding

Normalde, bir sunucu sadece **kendisine adreslenmiş** paketleri işler. **IP forwarding**, bir makinenin, **kendisine adreslenmemiş** bir paketi alıp, onu bir router gibi davranarak **iletmesine** izin veren kernel ayarıdır.

```bash
cat /proc/sys/net/ipv4/ip_forward
```

Düz bir web sunucusunda, başkalarının trafiğini yönlendirmesi için açık bir sebep olmadığından, `0` (kapalı) dönmesi bekleniyordu. Bunun yerine `1` (açık) döndü — tahmin etmek yerine **gerçekten araştırılması gereken** beklenmedik bir sonuç.

**Gerçek sebep:** Docker. Resmi dokümantasyona göre, Docker gibi container platformları, container'ların dış dünyaya ulaşabilmesi için **özellikle** IP forwarding'e dayanır — host, izole container ağı (`docker0`, `172.17.0.0/16`) ile gerçek ağ arasında trafiği yönlendirmek zorundadır. Çoğu Linux sistemi, güvenlik sebepleriyle bunu varsayılan olarak kapalı tutar, ama Docker kurmak, tam olarak bunu açmayı gerektiren bir kullanım senaryosudur. Yani buradaki `ip_forward=1`, rastgele kalmış bir ayar veya sunucu sağlayıcının varsayılanı değil — **Docker'ın kurulu olmasının doğrudan, beklenen bir sonucu.**

---

## 7. DNS — Domain Çözümlemesi Gerçekte Nasıl Çalışır

### Resolver Zinciri

DNS, bir domain adını çözerken **tek bir sunucuya sormaz** — **hiyerarşik bir zincir** izler, her seviye cevaba bir adım daha yaklaştırır.

```
Sen → Recursive Resolver → Root Sunucu → TLD Sunucu (.com) → Authoritative Sunucu → Cevap!
```

- **Recursive Resolver**: sorgunun ilk gittiği yer (ISP'nin DNS'i, veya `8.8.8.8` gibi public bir resolver). Görevi, senin yerine tüm zinciri dolaşıp, sadece nihai sonucu sana vermek.
- **Root Sunucu**: gerçek IP'yi bilmez, ama `.com`, `.org` gibi uzantıları kimin yönettiğini bilir, oraya yönlendirir.
- **TLD Sunucu**: hâlâ gerçek IP'yi bilmez, ama belirli domain için hangi sunucuların authoritative olduğunu bilir, oraya yönlendirir.
- **Authoritative Sunucu**: gerçekten bilen sunucu — gerçek cevap buradan gelir.

Her seviyede, birden fazla yedek sunucu var (örn. 13 root sunucu, birkaç TLD sunucu, birkaç authoritative sunucu) — ama **sadece biri** gerçekten sorgulanır, esasen rastgele seçilerek. Diğerleri, seçilen cevap vermezse diye, sadece **yedek olarak** duruyor. Bu doğrudan gözlemlendi: gerçek bir `dig +trace google.com`, Google'ın authoritative sunucularından birine 3 kere IPv6 üzerinden zaman aşımı yaşadıktan sonra, başarıyla farklı birine (`ns2.google.com`) IPv4 üzerinden geçtiğini gösterdi.

**Örnek:** Birine telefon numarası soruyorsunuz, o bilmiyor ama "şu 13 kişi biliyor" diyor. O 13 kişiden birini rastgele seçip soruyorsunuz, o da "bilmiyorum ama bu konuyu bilen 13 kişi var" diyor. O 13 kişiden birini rastgele seçip soruyorsunuz, o diyor ki "bilmiyorum ama bu kişinin 4 tane numarası var." 4 numaradan birini rastgele arıyorsunuz ve kişiye ulaşıyorsunuz. Eğer seçtiğiniz cevap vermezse, sıradakini deniyorsunuz.

### Gerçek Zinciri İzlemek (`dig +trace`)

```bash
dig +trace google.com
```

Gerçek bir çalıştırma, 4 aşamayı sırayla gösterdi: yerel resolver'ın 13 root sunucu ismini döndürmesi, (rastgele seçilen) bir root sunucunun 13 `.com` TLD sunucusuna işaret etmesi, bir TLD sunucusunun Google'ın 4 authoritative sunucusuna (`ns1`-`ns4.google.com`) işaret etmesi, ve son olarak bir authoritative sunucunun (`ns2.google.com`) gerçek cevabı vermesi:

```
google.com.    300    IN    A    172.217.20.78
```

İzleme sürecindeki her adımda `DS` ve `RRSIG` gibi satırlar da görüldü — bunlar, DNS cevaplarının değiştirilmediğini kriptografik olarak doğrulamak için kullanılan **DNSSEC** imzaları. Burada derinlemesine işlenmedi (ileri seviye konu), ama var olduklarını bilmek değerli — ve aynı klasördeki outage araştırma belgesinin gösterdiği gibi, 2023'te gerçek bir Cloudflare olayı, tam olarak bu imzaların süresi dolup doğrulanamadığı için yaşandı.

### TTL — Bazı Kayıtlar Neden Daha Uzun Cache'lenir

Yukarıdaki cevaptaki `300`, **TTL (Time To Live)**, saniye cinsinden — bu cevabın, tekrar sorulmadan önce ne kadar süre cache'de tutulabileceği.

Aynı izlemede, farklı kayıt tipleri çok farklı TTL'lere sahipti:

```
.                  6677     ← root sunucular, saatler süren TTL
com.               172800   ← TLD kayıtları, 2 gün
google.com.  A     300      ← gerçek IP, sadece 5 dakika
```

Bu, bilinçli bir denge: neredeyse hiç değişmeyen kayıtlar (root/TLD sunucular), gereksiz sorguları en aza indirmek için uzun TTL alır. Sık değişebilecek kayıtlar (bir şirketin gerçek IP'si, özellikle load balancing ile), güncellemelerin hızlı yayılması için kısa TTL alır.

**Doğrudan doğrulandı**: aynı `dig google.com` sorgusunu art arda iki kere çalıştırmak, TTL'in geri saydığını (141 → 139, iki saniye arayla) ve ikinci sorgunun 34ms yerine 0ms sürdüğünü gösterdi — ikinci cevabın, hiç zincir dolaşmadan, doğrudan cache'den geldiğinin kanıtı.

**Örnek:** Kendi telefon rehberiniz var ve numaraları insanlara tekrar tekrar sormak yerine, bir kez öğrenip kaydediyorsunuz. Sık kullandığınız numaraları haftada bir doğruluğunu kontrol ederken, nadiren kullandıklarınızı ayda bir, var olup olmadığından emin olmak istediğiniz numaraları ise 2-3 haftada bir kontrol ediyorsunuz — sürekli tekrar tekrar sormak hem zaman kaybı, hem iş yükü, hem de gereksiz yük.

### Negative Caching (NXDOMAIN)

Var olmayan bir domain'i sorgulamak `NXDOMAIN` döndürür, _o negatif cevap için_ bir TTL ile birlikte (SOA kaydının son alanında bulunur):

```bash
dig thereisnodomainlikethat.com
```

```
;; status: NXDOMAIN
com.   900   IN   SOA   a.gtld-servers.net. ...
```

Buradaki `900`, "bu domain yok" bilgisinin kendisinin 15 dakika boyunca cache'lendiği anlamına gelir — bu yüzden aynı var olmayan domain için tekrarlanan sorgular, her seferinde tüm zinciri tekrar dolaşmaz. Bu, yazım hataları veya var olmayan isimlere tekrar tekrar çarpan tarama botları gibi şeylerden kaynaklanan gereksiz yükü önler.

**Örnek:** Telefon rehberinizdeki var olmayan numaraları ne çok sık ne çok nadir kontrol ediyorsunuz — zaten sahibi yoktu, ama belki birinin o numarayı aldığını öğrenmek için ara sıra bakıyorsunuz. Ne kullandığınız numaralar kadar sık, ne de hiç bakmayacak kadar nadir.

### Kayıt Tipleri

| Tip       | Amacı                                                                  | Görülen Gerçek Örnek                                                                                                                                                                |
| --------- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A**     | Domain → IPv4 adresi                                                   | `google.com → 142.251.38.238`                                                                                                                                                       |
| **AAAA**  | Domain → IPv6 adresi                                                   | `google.com → 2a00:1450:4017:801::200e`                                                                                                                                             |
| **CNAME** | Domain → başka bir domain adı (takma ad)                               | `google.com`'un kendisinde yok (apex domain'lerde CNAME olamaz); `www.google.com`'da da yok — Google bunun yerine doğrudan A kayıtları kullanıyor (load balancing için 8 tane)      |
| **MX**    | Bu domain'e mailin nereye teslim edileceği                             | `google.com → 10 smtp.google.com.`; `turkiyesigorta.com.tr`'nin, failover için 10/20/30 öncelikli üç tanesi var                                                                     |
| **TXT**   | Serbest metin, sahiplik doğrulama ve e-posta güvenliği için kullanılır | Google'ın `google.com` TXT kayıtları, Facebook, Apple, DocuSign doğrulamalarını ve bir SPF kaydını içeriyordu                                                                       |
| **NS**    | Bu domain için hangi sunucuların authoritative olduğu                  | `google.com` kendi sunucularını kullanıyor; `turkiyesigorta.com.tr` Microsoft Azure DNS kullanıyor; `claude.ai` Cloudflare kullanıyor                                               |
| **SRV**   | Belirli bir servis için host + port                                    | `_sip._tcp.google.com` test edildi — NXDOMAIN döndü, çünkü Google orada bu servisi çalıştırmıyor; SRV kayıtları sadece bir domain'in gerçekten çalıştırdığı servisler için var olur |
| **PTR**   | Ters sorgu: IP → domain adı                                            | `8.8.8.8 → dns.google.`; `1.1.1.1` ve `1.0.0.1`, ikisi de → `one.one.one.one.`                                                                                                      |

Belirtmeye değer birkaç gerçek bulgu:

- **CNAME, bir domain'in apex/kök seviyesinde olamaz** — `google.com`'un kendisi başka kayıt tipleri (NS, SOA) taşımak zorunda, bu yüzden orada bir CNAME çakışırdı. Sadece alt domain'ler CNAME kullanabilir.
- **Büyük şirketler genelde, yüksek trafikli alt domain'ler için CNAME'i tamamen atlıyor**, bunun yerine birden fazla doğrudan A kaydı kullanıyor (`www.google.com`'un 8 farklı IP döndürmesinde görüldüğü gibi) — muhtemelen performans için, çünkü CNAME ekstra bir çözümleme adımı ekliyor.
- **PTR kayıtları isteğe bağlı, otomatik değil.** Cloudflare ve Google, marka tutarlılığı için bilinçli olarak eşleşen PTR kayıtları kurmuş (`1.1.1.1 → one.one.one.one`, ve `one.one.one.one`'ın kendisi de kendi A kaydı üzerinden `1.1.1.1`'e geri çözümleniyor) — ama birçok IP'nin (örn. test edilen rastgele `8.4.4.8`) hiç PTR kaydı yok. Bu, pratikte en çok mail sunucuları için önemli, çünkü eksik/uyumsuz PTR kayıtları, spam olarak işaretlenme ihtimalini artırır.
- **MX önceliği** (mail sunucu isminden önceki sayı), sırayı belirler: düşük sayılar önce denenir. `turkiyesigorta.com.tr`'nin üç MX kaydı (öncelik 10, 20, 30), gerçek bir mail sunucu failover örneği — ana sunucu çökerse, mail otomatik olarak yedeğe yönlenir.

**Örnek (MX):** Google apartmanı kapıya bir not asmış: "Kargo ve postacılar, gönderileri dairelere değil kapıcıya teslim etsin — kapıcı ilgili dairelere ulaştıracak." Birden fazla kapıcı varsa (mx1, mx2, mx3), önce birincisine gidilir, o yoksa ikincisine, o da yoksa üçüncüsüne.

**Örnek (CNAME):** Birinin hem resmi ismi hem de lakabı olması gibi — "Ali Furkan" dersen de, "Furkan" dersen de aynı kişiye ulaşırsın. CNAME de böyle: farklı bir isim ama aynı yere gidiyor.

**Örnek (PTR):** Profesyonel kurumlar bunu çift taraflı yapıyor — öyle de yazılsa böyle de yazılsa "aynı yere gidiyoruz" demeye getiriyorlar. Cloudflare, `1.1.1.1` yazsan da `one.one.one.one` yazsan da aynı yere ulaştırıyor.

**Örnek (TXT):** Kargo firmaları kendi kargocularına özel bir kod veriyor ve diyor ki: "Bundan sonra apartmanlara gittiğinde bu kodu göster. Kodu olmayan biri Google adına geliyorum diyorsa, o gerçek değildir." Her servis (Apple, Facebook, Microsoft) kendi kodunu veriyor, Google da bunları TXT kaydına ekliyor.

### `dig` Dışındaki Debug Araçları

```bash
nslookup google.com    # dig'e daha eski, daha basit bir alternatif
host google.com        # daha da minimal çıktı
resolvectl status      # bir sorgu aracı değil — sistemin kendi DNS yapılandırmasını gösterir
```

`resolvectl status`, bu sunucunun gerçek DNS kurulumunu ortaya çıkardı: `Current DNS Server: 8.8.4.4`, sunucu sağlayıcının varsayılan olarak ayarladığı `8.8.8.8` ve `8.8.4.4` (Google'ın public resolver'ları) ile birlikte — sunucunun kendi DNS çözümlemesini çalıştırmadığını, sadece Google'a yönlendirdiğini doğruluyor.

### Gerçek Dünya Cloud Kesintileri

Bu klasördeki ayrı bir belge, AWS, Cloudflare, ve Google Cloud'dan araştırılmış, gerçek DNS-ilişkili (ve DNS'e yakın) kesintileri kapsıyor — bu kavramları gerçek, büyük ölçekli arızalarla bağlıyor. Bkz. [dns-outages-TR.md](./dns-outages-TR.md).

---

---

| Katman           | İşi                                      | Görülen Gerçek Örnek                                           |
| ---------------- | ---------------------------------------- | -------------------------------------------------------------- |
| 7 - Application  | Protokolün kendisi (HTTP, DNS, SSH, FTP) | Paket yakalamasında görünen `GET / HTTP/1.1`                   |
| 6 - Presentation | Şifreleme / format                       | `https://`'da TLS; düz `http://`'da yok                        |
| 5 - Session      | Bağlantının yaşam döngüsü                | SSH oturum süresi                                              |
| 4 - Transport    | TCP/UDP, portlar                         | Paket yakalamasındaki port 80                                  |
| 3 - Network      | IP, yönlendirme                          | Her router tarafından okunan (değiştirilmeyen) kaynak/hedef IP |
| 2 - Data Link    | MAC, yerel ağ teslimi                    | Her router hop'unda sökülüp yeniden yazılır                    |
| 1 - Physical     | Ham sinyal iletimi                       | Bu seviyede doğrudan gözlemlenemedi                            |

| Kavram                | Özet                                                                                                                                               |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Encapsulation         | Her katman, inerken (L7 → L1) veriyi kendi header'ıyla sarar                                                                                       |
| Decapsulation         | Her katman, çıkarken (L1 → L7) kendi header'ını soyar                                                                                              |
| Router davranışı      | Yönlendirmek için IP'yi (Layer 3) okur; her hop'ta MAC'i (Layer 2) söker ve yeniden yazar; Layer 7'ye hiç dokunmaz                                 |
| ICMP                  | `ping` (Echo Request/Reply) ve `traceroute` (Time Exceeded) tarafından kullanılan bir Layer 3 kontrol protokolü                                    |
| ICMP neden engellenir | İç ağ topolojisini gizler ve saldırı yüzeyini azaltır — politika, bir kurumun şeffaflığa mı yoksa risk azaltmaya mı öncelik verdiğine göre değişir |

---

ℹ️ _Doğrudan test edildi: `tcpdump` ile gerçek paket yakalama, ve Cloudflare, Google, Claude.ai, ve Türkiye Sigorta arasında farklı gerçek dünya ICMP politikalarını gözlemlemek için karşılaştırmalı bir `traceroute`/`ping` testi._
