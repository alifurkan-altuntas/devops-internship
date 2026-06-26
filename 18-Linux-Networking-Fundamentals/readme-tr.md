# 🌐 OSI Modeli — Katmanlar, Gerçek Senaryolar, ve Paketlere İlk Bakış

⚠️ **Durum: Devam ediyor.** 7 katman ve gerçek bir senaryoda hangilerinin devrede olduğunu ayırt etmek sağlam. Encapsulation/decapsulation tanıtıldı ama henüz derinlemesine işlenmedi — devamı gelecek.

---

## 1. OSI Modeli Nedir

Ağ iletişimini 7 katmana bölen kavramsal bir çerçeve. Her katmanın kendi işi var, ve sadece kendi üstündeki/altındaki katmanla nasıl konuşacağını bilmesi gerekir — diğer her katmanın iç detaylarını bilmesine gerek yoktur.

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

Her işlem 7 katmanın hepsini kullanmıyor — örnekler üzerinde çalışırken en faydalı fark edilen şey bu oldu.

### `dig google.com` (düz DNS sorgusu, `@resolver` olmadan)

- **Layer 3** — sorgunun, bir DNS sunucusuna IP üzerinden yönlendirilmesi gerekiyor.
- **Layer 4** — DNS genelde UDP, port 53 kullanır.
- **Layer 7** — DNS'in kendisi bir uygulama katmanı protokolüdür.
- **Layer 6 — kullanılmıyor.** Düz bir DNS sorgusunda hiçbir şifreleme veya format dönüşümü gerçekleşmiyor. (Başlangıçta Layer 6'nın burada devrede olacağı tahmin edildi — yanlıştı. Layer 6, sadece gerçekten bir şey şifrelenirken/dönüştürülürken önemlidir, ve klasik DNS bunu yapmaz.)

### `curl https://example.com` (HTTPS)

- Yukarıdakiyle aynı Layer 3, 4, 7.
- **Layer 6 — bu sefer kullanılıyor**, çünkü `https://`, TLS şifrelemesini tetikliyor, ve şifreleme tam olarak Layer 6'nın işi.

### `ssh user@<ip>` (domain değil, IP ile bağlanma)

- **Layer 1-4** — her zaman gerekli (fiziksel iletim, MAC, IP yönlendirme, TCP + port 22).
- **Layer 5** — oturum yönetimi (bağlantının tanımlı bir başlangıcı, süresi, ve sonu var).
- **Layer 6** — SSH, trafiğini varsayılan olarak şifreler, bu yüzden bu katman aktif.
- **Layer 7** — SSH'ın kendisi bir uygulama katmanı protokolü, HTTP veya FTP ile aynı kategoride. Bu, DNS'in devrede olup olmamasından **bağımsız olarak** doğru.

**Burada netleşen kilit nokta:** Layer 7, hangi **aracın** kullanıldığıyla ilgili değil (PuTTY, bir terminal, bir FTP client) — hangi **protokolün konuşulduğuyla** ilgili. PuTTY ile SSH ve terminalin `ssh` komutuyla SSH, ikisi de Layer 7 = SSH'dır. Domain adı yerine IP ile bağlanmak, sadece DNS'in (ayrı bir Layer 7 protokolü) devrede olmadığı anlamına gelir — SSH'ın kendisini Layer 7'den çıkarmaz.

---

## 3. Layer 2 vs Layer 3 — İkisi de Neden Gerekli

- **Layer 3 (IP)**, adresin kendisidir — bir zarfın üzerine yazılan adres gibi ("hangi şehir, hangi sokak").
- **Layer 2 (MAC)**, o zarfı, o sokaktaki **doğru eve**, yerel ağ içinde gerçekten ulaştıran şeydir.

Layer 3 olmadan, hiç bir hedef adres olmazdı. Layer 2 olmadan, bir adrese sahip olmak hiçbir şey değiştirmezdi — veriyi, o hedefe doğru yola çıkarması için bir sonraki cihaza (örneğin yerel router'a) **fiziksel olarak teslim etmenin** hiçbir yolu olmazdı.

---

## 4. Encapsulation (tanıtıldı, henüz tam işlenmedi)

Veri, Layer 7'den Layer 1'e doğru, gerçekten gönderilmek üzere inerken, her katman onu kendi header'ıyla sarar — birbirinin içine geçmiş zarflar gibi:

```
[Layer 2: MAC header]
  [Layer 3: IP header]
    [Layer 4: TCP/UDP header — port bilgisini içerir]
      [Layer 7: gerçek veri — örn. bir HTTP isteği]
```

Alıcı tarafta, bu işlem tersten gerçekleşir (**decapsulation**) — her katman kendi header'ını soyar, kalanını bir üst katmana iletir, ta ki orijinal veri (örn. HTTP isteği) Layer 7'deki uygulamaya ulaşana kadar.

**Önemli gerçek dünya notu:** pratikte, Layer 5 ve 6 genelde gerçek paketlerde **ayrı, görünür header'lar** olarak çıkmaz — görevleri (oturum yönetimi, şifreleme) genelde uygulama katmanı protokolünün kendisine gömülür (örn. TLS, kavramsal olarak Layer 6'da yer alır, ama bir paket yakalamasında göreceğin ayrı bir "Layer 6 header" değildir). Bu, pratikte 7 katmanlı tam OSI modelinden çok, daha basit 4 katmanlı TCP/IP modelinin kullanılmasının sebeplerinden biri — OSI ağırlıklı olarak bir öğretim aracıdır.

| OSI (7 katman)   | TCP/IP (4 katman) |
| ---------------- | ----------------- |
| 7 - Application  | Application       |
| 6 - Presentation | Application       |
| 5 - Session      | Application       |
| 4 - Transport    | Transport         |
| 3 - Network      | Internet          |
| 2 - Data Link    | Link              |
| 1 - Physical     | Link              |

---

## 5. İlk Bakış: Katmanları Gerçek Bir Pakette Görmek

Nginx'in bir log satırı, sadece Layer 7'ye ulaşan kısmı gösterir — alt katman header'ları, uygulama isteği görene kadar zaten soyulmuş olur:

```
172.68.50.150 - - [26/Jun/2026:03:55:24 +0000] "GET / HTTP/1.1" 200 425 "-" "Mozilla/5.0 ..."
```

Alt katmanları gerçekten görmek için, uygulamanın logu değil, ham trafiğin kendisi yakalanmalı:

```bash
sudo apt install tcpdump -y
sudo tcpdump -i any port 80 -nn -X
```

Bu yakalama çalışırken `curl localhost` çalıştırmak, gerçek isteği bir paket olarak gösterdi:

```text
14:46:34.548687 lo In IP6 ::1.39502 > ::1.80: Flags [P.], seq 1:73, ... length 72: HTTP: GET / HTTP/1.1
        ...
        4745 5420 2f20 4854 5450 2f31 2e31 0d0a   GET / HTTP/1.1..
        486f 7374 3a20 6c6f 6361 6c68 6f73 740d   Host: localhost.
```

Burada gerçekten görünen şeyi parçalayalım:

- **`::1.39502 > ::1.80`** — bu, Layer 3 (`::1` IPv6 adresleri) ve Layer 4 (portlar — `.39502` kaynak, `.80` hedef, yani Nginx), aynı satırda yan yana duruyor.
- **`GET / HTTP/1.1`** ve hex dökümündeki okunabilir metin — bu, Layer 7, gerçek HTTP isteği, düz, şifrelenmemiş metin olarak duruyor.
- **Layer 6 aktivitesi yok** — çünkü bu `http://` idi, `https://` değil, hiçbir şifreleme yok, bu yüzden istek yakalamada tamamen okunabilir. (Bunu `https://` ile tekrarlamak, okunamaz, şifrelenmiş byte'lar gösterirdi — henüz denenmedi.)

Bu, somut olarak şunu doğruladı: OSI katmanları soyut bir diyagram değil — IP, port, ve gerçek HTTP metni, gerçekten **aynı yakalanan paketin içinde**, modelin tarif ettiği şekilde katmanlı olarak duruyor.

---

## 📊 Hızlı Referans

| Katman           | İşi                                      | Görülen Gerçek Örnek                         |
| ---------------- | ---------------------------------------- | -------------------------------------------- |
| 7 - Application  | Protokolün kendisi (HTTP, DNS, SSH, FTP) | Paket yakalamasında görünen `GET / HTTP/1.1` |
| 6 - Presentation | Şifreleme / format                       | `https://`'da TLS; düz `http://`'da yok      |
| 5 - Session      | Bağlantının yaşam döngüsü                | SSH oturum süresi                            |
| 4 - Transport    | TCP/UDP, portlar                         | Yakalamadaki port 80 (`::1.80`)              |
| 3 - Network      | IP, yönlendirme                          | Yakalamadaki `::1` kaynak/hedef IP           |
| 2 - Data Link    | MAC, yerel ağ teslimi                    | Bu yakalamada doğrudan görünmedi (loopback)  |
| 1 - Physical     | Ham sinyal iletimi                       | Bu seviyede doğrudan gözlemlenemedi          |

---

ℹ️ _Sıradaki adımlar: encapsulation/decapsulation'ı daha derinlemesine bitirmek, sonra routing & forwarding'e geçmek._
