# 🏗️ Linux Mantıksal Hacim Yönetimi (LVM)

Bu belge, LVM temellerini kapsar: fiziksel hacimler, hacim grupları, mantıksal hacimler, çevrimiçi boyutlandırma ve host disk alanı dolmasından kaynaklanan gerçek bir olay.

---

## 1. Neden Düz Bölümler Yerine LVM

### Geleneksel Bölümlemenin Sorunu

`fdisk` gibi araçlarla oluşturulan normal bir bölümün boyutu, oluşturma sırasında özünde sabittir. Bir bölüm daha sonra yer doluysa — büyüyen bir veritabanı, biriken loglar — yeniden boyutlandırmak zor, çoğunlukla riskli ve sıklıkla kesinti veya disk düzenini sıfırdan yeniden oluşturmayı gerektirir.

### LVM Bunu Nasıl Çözer

LVM, kaynak havuzlama gibi çalışır — bir hypervisor'ın fiziksel RAM/CPU'yu havuzlayıp VM'lere dilimler dağıtmasına kavramsal olarak benzer. Fiziksel disk alanı önce paylaşılan bir havuza girer, kullanılabilir hacimler daha sonra bu havuzdan ihtiyaç duyuldukça ayrılır:

```
Fiziksel Disk(ler) → Hacim Grubu (havuz) → Mantıksal Hacim(ler) (dağıtılan dilimler)
```

Havuzda hâlâ boş alan olduğu sürece, mevcut bir Mantıksal Hacim **canlı olarak, kesinti olmadan** büyütülebilir — ekstra alan zaten havuzda bekliyordu, sadece henüz o hacme atanmamıştı.

### Somut Örnek

Şu an yalnızca 20GB gereken 50GB'lık bir disk düşünün:

```bash
# 50GB'lık diski havuza ekle
sudo pvcreate /dev/sdb
sudo vgcreate disk_pool /dev/sdb

# Kullanmak için yalnızca 20GB ayır
sudo lvcreate -L 20G -n data_volume disk_pool
sudo mkfs.ext4 /dev/disk_pool/data_volume
sudo mount /dev/disk_pool/data_volume /mnt/data

# Havuzda 30GB boş kalır. Daha sonra 20GB yetmezse:
sudo lvextend -l +10G /dev/disk_pool/data_volume
sudo resize2fs /dev/disk_pool/data_volume
```

Unmount yok, yeniden oluşturma yok, kesinti yok — hacim, havuzda zaten rezerve edilmiş alana büyür.

---

## 2. LVM Bileşenleri

- **Fiziksel Hacim (PV):** `pvcreate` aracılığıyla bir raw block device'ı (örn. `/dev/loop0`) LVM'nin kullanabileceği bir şeye dönüştürür.
- **Hacim Grubu (VG):** Bir veya daha fazla PV'yi tek bir depolama havuzunda birleştirir, `vgcreate` ile.
- **Mantıksal Hacim (LV):** Havuzdan kullanılabilir bir sanal disk ayırır, `lvcreate` ile.

---

## 🚨 Olay: Host Disk Alanı Doldu

Büyük disk yazma testleri sırasında sanal makine tamamen dondu.

### 📝 Olay Tanılaması

1. **Tetikleyici İşlem:** 50GB'lık bir test dosyası oluşturulmaya çalışıldı:

   ```bash
   sudo dd if=/dev/zero of=/tmp/lvm_disk1.img bs=1M count=51200
   ```

2. **Sistem Davranışı:** Misafir kernel bir watchdog hatası kaydetti:

   ```text
   kernel:watchdog: BUG: soft lockup - CPU#1 stuck for 33s! [vmtoolsd:726]
   ```

3. **Kök Sebep:** Sanal makineler kendi diskim üzerine kuruluydu. VM, ince sağlanmış (thin-provisioned) bir sanal disk kullanıyordu — 50GB sıfır yazmak, host'taki VM disk dosyasının gerçekten 50GB büyümesine neden oldu. Bu, host'un diskini tamamen doldurdu ve hypervisor'ın VM'in I/O ve ağını durdurmasına, misafiri dondurmasına sebep oldu.

### 🛠️ Çözüm

- **`vagrant halt`** komutunu host'tan çalıştırarak dondurulmuş VM'i zorla durduruldu ve disk alanı serbest bırakıldı.
- **`fallocate` kullanıldı:** Gerçek veri yazmadan alanı anında rezerve eder, bu sorunu önler:
  ```bash
  sudo fallocate -l 500M /tmp/lvm_disk1.img
  ```

---

## 3. LVM Kurulumu (Daha Küçük Ölçek, Aynı Kavramlar)

Disk alanı olayını tekrarlamamak için bu sefer daha küçük MB boyutlu dosyalar kullanıldı.

1. **Loop Device'lar Oluşturuldu:**

   ```bash
   sudo fallocate -l 500M /tmp/lvm_disk1.img
   sudo fallocate -l 200M /tmp/lvm_disk2.img
   sudo losetup -fP /tmp/lvm_disk1.img
   sudo losetup -fP /tmp/lvm_disk2.img
   ```

2. **PV, VG ve LV Kurulumu:**

   ```bash
   sudo pvcreate /dev/loop0
   sudo vgcreate test_pool /dev/loop0
   sudo lvcreate -l 100%FREE -n test_data test_pool
   ```

3. **Biçimlendirme ve Mount Etme:**

   ```bash
   sudo mkfs.ext4 /dev/test_pool/test_data
   sudo mkdir -p /mnt/lvm_test
   sudo mount /dev/test_pool/test_data /mnt/lvm_test
   ```

4. **Kesinti Olmadan Depolama Genişletme (+200M):**
   ```bash
   sudo pvcreate /dev/loop1                                  # yeni loop device'ı PV'ye dönüştür
   sudo vgextend test_pool /dev/loop1                        # mevcut havuza ekle
   sudo lvextend -l +100%FREE /dev/test_pool/test_data       # mantıksal hacmi büyüt
   sudo resize2fs /dev/test_pool/test_data                   # dosya sistemini eşleştir
   ```

---

## 📊 Komut Referansı

| Komut           | Katman        | Örnek                                        | Amacı                                                                         |
| --------------- | ------------- | -------------------------------------------- | ----------------------------------------------------------------------------- |
| **`pvcreate`**  | Fiziksel      | `sudo pvcreate /dev/loop0`                   | Bir block device'ı LVM kullanımı için başlatır.                               |
| **`vgcreate`**  | Havuzlama     | `sudo vgcreate pool_name /dev/loop0`         | PV'leri bir hacim grubunda (havuz) birleştirir.                               |
| **`lvcreate`**  | Mantıksal     | `sudo lvcreate -n data_vol -L 10G pool_name` | Havuzdan kullanılabilir bir hacim oluşturur.                                  |
| **`vgextend`**  | Havuzlama     | `sudo vgextend pool_name /dev/loop1`         | Mevcut havuza daha fazla fiziksel alan ekler.                                 |
| **`lvextend`**  | Mantıksal     | `sudo lvextend -l +100%FREE /dev/pool/vol`   | Havuzdaki boş alanı kullanarak mantıksal hacmi büyütür.                       |
| **`resize2fs`** | Dosya Sistemi | `sudo resize2fs /dev/pool/vol`               | Dosya sistemini yeni hacim boyutuyla eşleşecek şekilde yeniden boyutlandırır. |

---

ℹ️ _Tüm komutlar yerel ortamda test edilmiştir._
