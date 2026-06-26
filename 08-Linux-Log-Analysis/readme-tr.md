# Linux Log Analizi & Metin İşleme

Bu belge, log dosyalarını işleme (parsing) pipeline'larını, dağıtımlar arası IPv4/IPv6 farklarını ve `sed` ile metin düzenlemeyi kapsar.

---

## 1. Log İşleme & Trafik Analizi

En çok trafik gönderen kaynakları veya kırık (404) rotaları bulmak, access log dosyasının işlenmesini gerektirir.

### Adımlar

1. **Ubuntu'da `curl` Eksikliği:**
   - **Rocky Linux:** `curl` varsayılan olarak kurulu gelir.
   - **Ubuntu:** Minimal kurulumda `command not found` hatası verir — şu şekilde düzeltildi:
     ```bash
     sudo apt update && sudo apt install curl -y
     ```

2. **Test HTTP İstekleri Oluşturma:**
   ```bash
   curl -I http://localhost/        # başarılı istek
   curl -I http://localhost/aa      # 404 tetikleyici
   ```

---

## 2. Log Satırı Formatını Anlamak

```text
::1 - - [19/Jun/2026:17:54:14 +0300] "GET /aa HTTP/1.1" 404 0 "-" "curl/8.5.0"
```

Önemli sütunlar:

- **Sütun 1 (`$1`):** İstemci IP adresi (veya loopback).
- **Sütun 7 (`$7`):** İstenen path (örn. `/aa`).
- **Sütun 9 (`$9`):** HTTP durum kodu (örn. `404`).

### Farklı Dağıtımlarda IPv4 vs IPv6

`localhost`'a yapılan aynı `curl` isteği, dağıtıma göre farklı formatlar döndürür:

- **Ubuntu:** `/etc/hosts`'ta IPv6'yı önceliklendirir — loopback `::1` olarak görünür.
- **Rocky Linux:** Varsayılan olarak IPv4 kullanır — loopback `127.0.0.1` olarak görünür.

---

## 3. Log Okuma: `tail -n` vs `tail -f`

| Flag            | Davranış                                                                                                                                     |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **`-n <sayı>`** | Son N satırı **bir kez** gösterir, sonra komut sona erer.                                                                                    |
| **`-f`**        | Dosyayı canlı **takip eder (f**ollow**)** — açık kalır, yeni satırlar geldikçe yazdırır, kendiliğinden hiç bitmez (`Ctrl+C` ile durdurulur). |

```bash
tail -n 50 /var/log/nginx/error.log     # son 50 satır, tek seferlik
tail -f /var/log/nginx/error.log        # canlı akış, yeni girişler
tail -n 50 -f /var/log/nginx/error.log  # ikisi birlikte: önce geçmiş, sonra canlı takip
```

---

## 4. İşleme Pipeline'ları

### En Çok İstek Gönderen IP'yi Bulma

```bash
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr
```

- `awk '{print $1}'` — IP'yi (Sütun 1) çıkarır.
- `sort` — aynı girdileri yan yana getirir, böylece `uniq` bunları sayabilir.
- `uniq -c` — her IP'nin kaç kez geçtiğini sayar (bu kısım gerçekten **sayma** yapar, filtreleme değil).
- `sort -nr` — sayısal olarak, büyükten küçüğe sıralar.

### Path Bazlı İstek Sayma (Path Bazlı Gruplama)

Bu, kavramsal olarak SQL'deki `GROUP BY` + `COUNT()`'a benzer: "bu belirli path için, her IP'den kaç istek geldi?"

```bash
grep "/bir-path" /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c
```

Tam bir istek satırıyla kesin eşleşme için (başka path'lerin içinde geçen `/` ile yanlış eşleşmeyi önlemek için):

```bash
grep '"GET / HTTP/1.1"' /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c
```

Sadece `/` aramak, neredeyse her satırla eşleşir, çünkü `/` karakteri zaman damgalarında, path'lerde, hatta `HTTP/1.1`'in içinde bile geçer — aramayı tam istek satırına (`"GET / HTTP/1.1"`) sabitlemek bu sorunu önler.

### Path Bazında 404 Hatalarını Sayma

```bash
sudo grep " 404 " /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -nr
```

---

## 5. `sed` ile Metin Düzenleme

`awk` sütun seçmek/çıkarmak için; `sed` (**s**tream **ed**itor, akış düzenleyici) ise metin bulup değiştirmek (veya silmek) için kullanılır.

### Temel Bulma & Değiştirme

```bash
sed 's/eski/yeni/' dosya.txt
```

Her satırdaki **ilk** eşleşmeyi değiştirir, sonucu ekrana basar — dosyanın kendisi **değiştirilmez**.

### Büyük/Küçük Harf Duyarlılığı

`sed`, varsayılan olarak **büyük/küçük harf duyarlıdır** — `dunya` ve `Dunya` farklı kelimeler olarak görülür. Bu doğrudan test edildi: hem `Dunya` hem `dunya` içeren bir satırda, `sed 's/dunya/world/'` sadece küçük harfli olanı değiştirdi.

Büyük/küçük harf duyarsız eşleştirme için `I` flag'i kullanılır:

```bash
sed 's/dunya/world/I'
```

Bu, aynı testte hem `Dunya` hem `dunya`'yı değiştirdi.

### Değişiklikleri Dosyaya Yazma (`-i`)

```bash
sed -i 's/eski/yeni/' dosya.txt
```

`-i` (in-place, yerinde) değişikliği kalıcı yapar — bu olmadan `sed` sadece ekrana basar, dosya değişmeden kalır.

### Satır Silme

Satır numarasına göre:

```bash
sed '2d' dosya.txt        # 2. satırı siler
```

Desene (pattern) göre (eşleşen herhangi bir satırı siler):

```bash
sed '/anahtar_kelime/d' dosya.txt
```

İkisi de 4 satırlık bir test dosyasında doğrudan doğrulandı — `sed '2d'`, ikinci satırı kaldırdı, `sed '/satir3/d'` ise o kelimeyi içeren satırı, pozisyonu ne olursa olsun kaldırdı. İkisine de `-i` eklemek, silmeyi kalıcı yapar.

---

## 📊 Komut Referansı

| Komut                | Amaç                                                       | Örnek                         | Notlar                                |
| -------------------- | ---------------------------------------------------------- | ----------------------------- | ------------------------------------- |
| **`awk`**            | Yapılandırılmış metinden belirli sütunları çıkarır.        | `awk '{print $7}' access.log` |                                       |
| **`grep`**           | Bir desene uyan satırları filtreler.                       | `grep " 404 " access.log`     |                                       |
| **`tail -n`**        | Son N satırı, bir kez gösterir.                            | `tail -n 50 access.log`       |                                       |
| **`tail -f`**        | Bir dosyayı canlı takip eder, yeni girişler için.          | `tail -f access.log`          |                                       |
| **`uniq -c`**        | Bitişik tekrar eden satırları sayar.                       | `uniq -c`                     | Önce sıralanmış girdi gerektirir.     |
| **`sort -nr`**       | Sayısal olarak, büyükten küçüğe sıralar.                   | `sort -nr`                    |                                       |
| **`sed 's/x/y/'`**   | Metin bulup değiştirir (satırda ilk eşleşme).              | `sed 's/eski/yeni/'`          |                                       |
| **`sed 's/x/y/g'`**  | Satırdaki tüm eşleşmeleri değiştirir, sadece ilkini değil. | `sed 's/eski/yeni/g'`         |                                       |
| **`sed 's/x/y/I'`**  | Büyük/küçük harf duyarsız bulma & değiştirme.              | `sed 's/dunya/world/I'`       |                                       |
| **`sed -i`**         | `sed` değişikliklerini doğrudan dosyaya yazar.             | `sed -i 's/eski/yeni/' dosya` | Olmadan, çıktı sadece ekrana basılır. |
| **`sed 'Nd'`**       | Belirli bir satırı, numarasına göre siler.                 | `sed '2d' dosya`              |                                       |
| **`sed '/desen/d'`** | Desene uyan herhangi bir satırı siler.                     | `sed '/hata/d' dosya`         |                                       |
| **`less`**           | Büyük log dosyaları için sayfalı görüntüleyici.            | `less access.log`             |                                       |

---

ℹ️ _Tüm komutlar gerçek bir sunucuda yerel olarak test edilmiştir._
