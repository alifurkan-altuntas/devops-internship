# 📁 Linux Dosya Sistemi Yönetimi & Depolama Tanılaması

Bu belge, Linux'ta depolama işlemleri, dosya sistemi gezintisi, pipeline sıralama ve otomatik alan denetimi iş akışlarını kapsar.

---

## 1. 10 GB Test Dosyası Oluşturma

Düşük disk alanını simüle etmek için 10 GB'lık bir dosya oluşturuldu.

### 🛠️ Adımlar

```bash
mkdir -p /tmp/disk-test && cd /tmp/disk-test
dd if=/dev/zero of=test_file.img bs=1G count=10
```

### 🔍 Neden `fallocate` Değil de `dd`?

İkisi disk alanını farklı şekilde ele alır:

- **`dd`**: `/dev/zero`'dan veri akışı yazarak dosyayı gerçekten diske yazar. Dosya gerçekten disk alanı kaplar ve `du` ile doğru görünür.
- **`fallocate`**: Fiziksel disk I/O olmadan blokları anında rezerve eder — "mış gibi yapar." Bazı denetim yapılandırmalarında `du` gerçek blok boyutunu sıfır (`0`) olarak gösterebilir çünkü veriler henüz diske yazılmamıştır.

**Hangisi ne zaman kullanılır:**

- **`dd`** → gerçek bir dosyanın disk üzerinde yer kapladığını test etmek istiyorsan. Yavaş, çünkü gerçekten yazıyor.
- **`fallocate`** → disk alanını hızlıca rezerve etmek ama içine hiçbir şey yazmamak için. LVM testinde VM donmuştu — tam da bu yüzden `fallocate`'e geçildi (bkz. 11-LVM-Management).

---

## 2. En Büyük 10 Dosyayı Bulma

Sunucu disk alanı dolmaya başladığında, neyin yer kapladığını bulmak için kullanılır.

### 📦 Komut

```bash
sudo find / -type f -exec du -ah {} + 2>/dev/null | sort -rh | head -n 10
```

### Pipeline Açıklaması

1. **`find / -type f`** — kök dizinden (`/`) başlayarak tüm normal dosyaları tarar.
2. **`-exec du -ah {} +`** — bulunan her dosyayı `du` komutuna gönderir, insan tarafından okunabilir formatta boyutunu gösterir.
3. **`2>/dev/null`** — izin hatalarını gizler, çıktıyı temiz tutar.
4. **`| sort -rh`** — en büyükten küçüğe doğru sıralar.
5. **`| head -n 10`** — sadece ilk 10 sonucu gösterir.

---

## 📊 Komut Referansı

| Komut        | Amacı                                              | Örnek                     | Önemli Flag'ler                                        |
| ------------ | -------------------------------------------------- | ------------------------- | ------------------------------------------------------ |
| **`pwd`**    | Mevcut çalışma dizininin tam yolunu gösterir.      | `pwd`                     | —                                                      |
| **`ls`**     | Dizin içeriğini listeler.                          | `ls -la /var/log`         | `-la`: gizli dosyalar dahil, izin ve boyut bilgisiyle  |
| **`cd`**     | Aktif dizini değiştirir.                           | `cd /etc/systemd`         | `..`: üst dizin, `~`: ev dizini                        |
| **`mkdir`**  | Yeni dizin oluşturur.                              | `mkdir -p /opt/app/logs`  | `-p`: iç içe dizinleri otomatik oluşturur              |
| **`rm`**     | Dosyaları kalıcı olarak siler.                     | `rm -rf /tmp/cache`       | `-rf`: özyinelemeli ve onaysız siler — dikkatli kullan |
| **`cp`**     | Dosya veya dizin kopyalar.                         | `cp -r /src /dest`        | `-r`: dizinleri özyinelemeli kopyalar                  |
| **`mv`**     | Dosyayı taşır veya yeniden adlandırır.             | `mv data.log archive.log` | —                                                      |
| **`find`**   | Dizin ağacında dinamik arama yapar.                | `find . -name "*.conf"`   | `-name`: ada göre, `-type`: türe göre                  |
| **`locate`** | Veritabanı üzerinden hızlı arama yapar.            | `locate nginx.conf`       | `updatedb` ile güncelleme gerektirir                   |
| **`du`**     | Dosya/dizin disk kullanımını gösterir.             | `du -sh /var`             | `-sh`: özet, insan okunabilir format                   |
| **`df`**     | Sistemdeki disk bölümlerinin kullanımını gösterir. | `df -hT`                  | `-hT`: insan okunabilir format + dosya sistemi türü    |

---

ℹ️ _Tüm komutlar yerel ortamda test edilmiştir._
