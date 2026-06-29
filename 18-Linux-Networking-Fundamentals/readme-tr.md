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

## 📊 Hızlı Referans

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
