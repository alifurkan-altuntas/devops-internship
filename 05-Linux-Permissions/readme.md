# 🔑 Linux İzinleri & Güvenlik Sıkılaştırma

Bu belge, dosya izinlerini, sahipliği, umask'ı ve sticky bit'i kapsar.

---

## 1. `ls -l` Çıktısını Okuma

```text
-rwxr-xr-x  1 altun altun  4096 Jun 19 18:09 script.sh
drwxr-x---  1 altun altun  4096 Jun 19 18:09 folder/
lrwxrwxrwx  1 altun altun     7 Jun 19 18:09 link -> target
```

En baştaki karakter **izin değil, tür** göstergesidir:

| Karakter | Anlamı                |
| -------- | --------------------- |
| `-`      | Normal dosya          |
| `d`      | **D**izin (directory) |
| `l`      | Sembolik **l**ink     |

Geri kalan 9 karakter, 3'er karakterlik üç gruba ayrılır (`rwx`) ve sırasıyla **kullanıcı (sahip)**, **grup** ve **diğerleri**'ni temsil eder.

---

## 2. `chmod` Sayısal Sistemi

Her iznin sabit bir sayısal değeri vardır:

| Sayı  | İzin           |
| ----- | -------------- |
| **4** | okuma (r)      |
| **2** | yazma (w)      |
| **1** | çalıştırma (x) |

Bu değerler **toplanarak** bir kombinasyonu temsil eder — 0-7 arasındaki her kombinasyonun tek bir anlamı vardır:

| Toplam | İzinler | Anlamı                     |
| ------ | ------- | -------------------------- |
| 7      | rwx     | okuma + yazma + çalıştırma |
| 6      | rw-     | okuma + yazma              |
| 5      | r-x     | okuma + çalıştırma         |
| 4      | r--     | sadece okuma               |
| 0      | ---     | izin yok                   |

`chmod` komutu üç rakam kullanır — birer tane **kullanıcı, grup, diğerleri** için:

```bash
chmod 750 file
```

= kullanıcı: `7` (rwx), grup: `5` (r-x), diğerleri: `0` (---)

### Örnekler

- **`chmod 700`** — sadece sahip tam erişime sahip (rwx); grup ve diğerlerinin hiçbir izni yok. Yalnızca sahibin dokunması gereken özel dosyalar için.
- **`chmod 555`** — herkes (kullanıcı, grup, diğerleri) okuyabilir ve çalıştırabilir, ama kimse yazamaz. Paylaşılan, salt okunur scriptler için yaygın.
- **`chmod 074`** — sahibin hiç izni yok; grubun tam erişimi var; diğerleri sadece okuyabilir. Alışılmadık ama geçerli bir kombinasyon — sahibin en fazla yetkiye sahip olması zorunlu değil.

### Dosya vs Dizin Maksimum İzinleri

- **Dosyalar**: varsayılan maksimum `666` (rw-rw-rw-) — execute, gerçekten bir script/binary olmadıkça dosya için anlamlı değildir, bu yüzden otomatik verilmez.
- **Dizinler**: varsayılan maksimum `777` (rwxrwxrwx) — bir dizindeki execute biti "içine girme/geçme izni" anlamına gelir (`cd` ile girebilme, içini listeleyebilme). `x` olmadan, `r` ayarlanmış olsa bile dizine girilemez.

Bu yüzden `umask` matematiği dosyalar için `666`'dan, dizinler için `777`'den çıkarma yapar — farklı başlangıç noktaları vardır.

---

## 3. Sticky Bit ile Paylaşımlı Dizin

Tam yazma erişimine (`777`) sahip paylaşımlı bir klasör, bir güvenlik açığı oluşturur: herhangi bir kullanıcı başkasının dosyalarını silebilir veya değiştirebilir. **Sticky bit** bunu çözer.

### 🛠️ Adımlar

1. **Paylaşımlı dizin oluşturuldu:**

   ```bash
   sudo mkdir /tmp/test
   sudo chmod 777 /tmp/test
   ```

2. **Sticky bit eklendi:**

   ```bash
   sudo chmod +t /tmp/test
   ```

   Alternatif: `sudo chmod 1777 /tmp/test`

3. **Durum doğrulandı:**
   ```bash
   ls -ld /tmp/test
   ```
   Beklenen çıktı: `drwxrwxrwt ... /tmp/test` — sondaki **`t`** aktif sticky bit'i gösterir.

### 🔐 Nasıl Çalışır

Sticky bit, okuma veya değiştirmeyi doğrudan kısıtlamaz. Bunun yerine, dizin seviyesinde silme işlemi için bir kural ekler:

- Dosya sahipleri kendi dosyalarını silebilir veya yeniden adlandırabilir.
- Dizin sahibi, dizin içindeki dosyaları yönetebilir.
- Root tam kontrole sahiptir.
- Diğer kullanıcılar — dizinde yazma izinleri olsa bile — başkasına ait dosyaları silemez veya yeniden adlandıramaz.

**Örnek:** Ortak bir ofis masası gibi düşünün. Herkes masaya kendi eşyasını koyabilir, herkes masadaki eşyaları görebilir, hatta alıp kullanabilir — ama **başkasının eşyasını çöpe atamazsın.** Sadece o eşyanın sahibi onu kaldırabilir. `/tmp` tam olarak böyle çalışır — herkesin yazabildiği ama kimsenin başkasının dosyasını silemediği bir yer.

### 🔒 Test Sonuçları

- **Test A:** `altun` kullanıcısı `touch /tmp/test/test.txt` çalıştırdı — başarılı. ✅
- **Test B:** `devopstester` kullanıcısı `rm /tmp/test/test.txt` denedi — başarısız:
  ```text
  rm: cannot remove '/tmp/test/test.txt': Operation not permitted
  ```

Yalnızca dosya sahibi ve root'un dosyayı silebileceği doğrulandı.

---

## 4. Sahiplik & Grup Değiştirme (`chown` & `chgrp`)

```bash
sudo chown -R altun /tmp/test           # sahibi değiştir
sudo chown -R altun:wheel /tmp/test     # sahibi VE grubu birlikte değiştir
sudo chgrp -R wheel /tmp/test           # sadece grubu değiştir
```

`-R` değişikliği hedef yolun altındaki her şeye özyinelemeli olarak uygular.

---

## 5. Varsayılan İzin Maskeleme (`umask`)

`umask`, yeni oluşturulan dosya ve dizinlerin varsayılan izinlerini, yukarıda belirtilen maksimum değerlerden çıkarma yaparak kontrol eder.

```bash
umask
```

Varsayılan dönüş: `0022`

### Matematik

- **Dizin:** `777 - 022 = 755` (`rwxr-xr-x`)
- **Dosya:** `666 - 022 = 644` (`rw-r--r--`)

Sıkılaştırma:

```bash
umask 0077
touch hardened.conf
ls -l hardened.conf
```

Sonuç: `-rw-------` (`666 - 077 = 600`) — yalnızca sahip erişebilir.

---

## 📊 Komut Referansı

| Komut       | Amacı                                                          | Örnek                           | Notlar                                                    |
| ----------- | -------------------------------------------------------------- | ------------------------------- | --------------------------------------------------------- |
| **`chmod`** | Dosya izin bayraklarını ayarlar (`rwx`).                       | `chmod 750 script.sh`           | `+t` sticky bit ekler; `-R` özyinelemeli uygular.         |
| **`chown`** | Dosya sahibini (ve isteğe bağlı olarak grubu) değiştirir.      | `chown -R altun:wheel /var/www` |                                                           |
| **`chgrp`** | Yalnızca grubu değiştirir.                                     | `chgrp wheel app.log`           |                                                           |
| **`umask`** | Yeni dosyalar/dizinler için varsayılan izin maskesini ayarlar. | `umask 022`                     | Dosyalar için `666`'dan, dizinler için `777`'den çıkarır. |

---

ℹ️ _Tüm komutlar yerel ortamda test edilmiştir._
