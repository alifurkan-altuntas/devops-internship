# 💾 Linux Depolama & Dosya Sistemi Yönetimi

Bu belge, loop device oluşturma, bölümleme, biçimlendirme ve fstab aracılığıyla kalıcı mount yapılandırmasını kapsar.

---

## 1. Sanal Disk Oluşturma ve Mount Etme

Sisteme depolama eklemek, çoğunlukla gerçek donanım bağlamadan önce yeni bir diski simüle etmeyi gerektirir. Bu lab, yeni bir disk eklemeyi ve biçimlendirmeyi simüle etmek için bir loop device kullanır.

### 🛠️ Adımlar

1. **Loop Device Oluşturma:**
   1GB'lık bir image dosyası oluşturuldu ve loop device olarak mount edildi:

   ```bash
   sudo dd if=/dev/zero of=/tmp/test_disk.img bs=1M count=1024
   sudo losetup -fP /tmp/test_disk.img
   ```

   `lsblk`, `/dev/loop0`'da yeni 1G'lık bölümlenmemiş bir cihaz olduğunu doğrular.

2. **Diski Bölümleme:**

   ```bash
   sudo fdisk /dev/loop0
   ```

   `fdisk`, **etkileşimli bir menü** açar — açıkça onaylanana kadar diske hiçbir şey yazılmaz. Mevcut alanın tamamını kullanan bir bölüm oluşturmak için tipik akış:

   | Tuş                     | Anlamı                                                                                         |
   | ----------------------- | ---------------------------------------------------------------------------------------------- |
   | `n`                     | **n**ew — yeni bölüm oluştur                                                                   |
   | _(Enter, Enter, Enter)_ | Bölüm numarası, ilk sektör ve son sektör için varsayılanları kabul et (tüm boş alanı kullanır) |
   | `w`                     | **w**rite — değişiklikleri diske yaz ve çık                                                    |

   ```text
   Command (m for help): n
   Partition type: p (primary)
   Partition number: [Enter]
   First sector: [Enter]
   Last sector: [Enter]   ← diskin geri kalanını kullan
   Command (m for help): w
   ```

   **Önemli:** `w` tuşuna basılana kadar hiçbir şey yazılmaz. Bir şeyler yanlış görünüyorsa, `w` yerine `q` (quit) ile çıkmak her şeyi güvenle iptal eder.

   Bu işlem, DOS bölüm tablosuyla `/dev/loop0p1` birincil bölümünü oluşturur.

3. **Dosya Sistemi Oluşturma:**
   Bölüm `ext4` olarak biçimlendirildi:

   ```bash
   sudo mkfs.ext4 /dev/loop0p1
   ```

4. **Bölümü Mount Etme:**
   Mount noktası oluşturuldu ve bölüm mount edildi:

   ```bash
   sudo mkdir -p /mnt/test_storage
   sudo mount /dev/loop0p1 /mnt/test_storage
   ```

5. **UUID ile Kalıcı Mount Yapılandırması:**
   `/dev/loop0p1` gibi cihaz yolları yeniden başlatmalar arasında değişebilir, bu yüzden `/etc/fstab`'da UUID kullanılır:

   ```bash
   sudo blkid /dev/loop0p1
   sudo vim /etc/fstab
   ```

   **`fstab` girişi:**

   ```text
   UUID=37675d89-63ea-4e43-ab1b-dc5906d10ee7  /mnt/test_storage  ext4  defaults  0  2
   ```

6. **fstab Girişini Güvenli Şekilde Test Etme:**

   ```bash
   sudo umount /mnt/test_storage
   sudo mount -a
   ```

   ### 🔍 Bu Adım Neden Önemli

   `/etc/fstab`'daki bir yazım hatası veya yanlış UUID o an değil, **bir sonraki yeniden başlatmada** sorun çıkarır. Sistem boot sırasında fstab'daki her şeyi otomatik olarak mount etmeye çalışır. Hatalı bir giriş sistemin **emergency mode**'a düşmesine neden olabilir — normale dönmek için recovery console üzerinden root şifresiyle manuel müdahale gerekir.

   `mount -a`, `/etc/fstab`'ı yeniden okur ve henüz mount edilmemiş her şeyi mount eder — sistem çalışırken, hemen şimdi. Hata varsa anında gösterir ve yerinde düzeltilebilir. Temiz çalışırsa, giriş yeniden başlatmayı güvenle atlatır. "Sunucuyu yeniden başlattım ve artık açılmıyor" senaryosundan tamamen kaçınılmış olur.

---

## 🔬 `/etc/fstab`'ı Anlamak

Her satırın 6 alanı vardır:

- **Alan 1 (Cihaz Tanımlayıcı):** `UUID=37675d89-...` — bölümü benzersiz kimliğiyle tanımlar.
- **Alan 2 (Mount Noktası):** `/mnt/test_storage` — bölümün nereye mount edileceği.
- **Alan 3 (Dosya Sistemi Türü):** `ext4`
- **Alan 4 (Mount Parametreleri):** `defaults` — standart mount seçenekleri (okuma/yazma, boot'ta otomatik mount, vb.)
- **Alan 5 (Dump Yedekleme):** `0` — bu bölüm için eski `dump` yedekleme aracını devre dışı bırakır.
- **Alan 6 (FSCK Sırası):** `2` — root (`/`) önce kontrol edilir (`1`), bu bölüm sonra (`2`).

---

## 📊 Komut Referansı

| Araç                   | Kapsam                | Örnek                         | Amacı                                                                                                                           |
| ---------------------- | --------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **`lsblk`**            | Blok Katmanı          | `lsblk`                       | Block device'ları ağaç görünümünde gösterir.                                                                                    |
| **`fdisk`**            | Bölümleme Katmanı     | `sudo fdisk /dev/loop0`       | Etkileşimli bölüm editörü — `w` tuşuna basılana kadar hiçbir şey yazılmaz.                                                      |
| **`mkfs.ext4`**        | Dosya Sistemi Katmanı | `sudo mkfs.ext4 /dev/loop0p1` | Bölümü ext4 dosya sistemiyle biçimlendirir.                                                                                     |
| **`blkid`**            | Metadata Katmanı      | `sudo blkid /dev/loop0p1`     | Bölüm UUID'sini ve dosya sistemi türünü gösterir.                                                                               |
| **`mount` / `umount`** | Çalışma Zamanı        | `sudo mount -a`               | Dosya sistemlerini mount/unmount eder; `-a` fstab'daki her şeyi mount eder ve yeniden başlatmadan önce güvenli test yöntemidir. |
| **`df`**               | Metrik Takip          | `df -h`                       | Disk kullanımını ve mount noktalarını gösterir.                                                                                 |

---

ℹ️ _Tüm komutlar yerel ortamda test edilmiştir._
