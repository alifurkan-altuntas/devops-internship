# 🐧 Temel Linux Komutları & Metin İşleme

Bu belge, stajın 3. günündeki temel Linux yönetimi görevleri sırasında toplanan notları, komut varyasyonlarını (`--help` keşifleri), ve gözlemleri içerir.

---

## 1. Sistem Kimliği: `hostname` vs `hostnamectl`

Ortam analizi sırasında, Ubuntu ve Rocky Linux ortamları arasında sistem kimliklendirmesiyle ilgili önemli bir davranış farkı gözlemlendi.

| Özellik           | Eski `hostname`                                                                                     | Modern `hostnamectl`                                                                              |
| :---------------- | :-------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------ |
| **Mimari**        | Kernel'de geçici (volatile) çalışma zamanı flag'leri okur/ayarlar.                                  | Modern `systemd` ekosistemine derinlemesine entegre.                                              |
| **Kalıcılık**     | Değişiklikler kalıcı değildir, config dosyaları manuel değiştirilmedikçe reboot sonrası geri döner. | Statik hostname'leri, sistem yapılandırma katmanlarına anında ve kalıcı olarak bağlar.            |
| **Çıktı Kapsamı** | Sadece düz makine adını döndürür.                                                                   | OS detayları, Kernel versiyonu, Mimari, ve Donanım Sağlayıcısı dahil tam sistem bilgisi döndürür. |

### 🔍 Gözlem (Rocky Linux Varsayılanı)

Rocky Linux 9.8'de `hostname` çalıştırıldığında, shell `.localdomain` döndürdü (örn. `localhost.localdomain`). Bu, kurumsal sunucuların varsayılan olarak bir **Fully Qualified Domain Name (FQDN)** düzeni beklediği, temel bir RHEL-ekosistemi tasarım örüntüsü — Ubuntu'nun varsayılan olarak kısa, yerel isimlendirme yapılarını kullanmasından farklı.

### 🛠️ Pratik Flag Varyasyonları (`--help` Keşifleri)

- `hostname -I`: Host'a atanmış tüm aktif IPv4/IPv6 ağ arayüzü adreslerini dinamik olarak yakalar (otomasyon routing için gerekli).
- `hostnamectl set-hostname <isim>`: Sunucunun kimliğini, manuel dosya metni düzenlemeye gerek kalmadan, tüm sistem yapılandırmaları boyunca kalıcı olarak günceller.

---

## 2. Linux Metin İşleme: `grep`, `cut`, ve `awk` ile Stream Piping

Ham veri dökümlerini (örn. tüm sistem metadata dosyalarını) işlemek yerine, temiz çıktı filtrelemesi standart akışlar (`stdin`, `stdout`) üzerinden yapılır.

### 📦 Pipeline Şablonu

```bash
cat /etc/os-release | grep "PRETTY_NAME" | cut -d '=' -f 2 | tr -d '"'

```

1. **`cat`**: os-release dosyasının içeriğini okur.
2. **`grep`**: Hassas bir filtre olarak çalışır, sorgu kelimesiyle eşleşen belirli string parçasını ayırır.
3. **`cut -d '=' -f 2`**: Ayrılmış metin satırını, delimiter (`-d`) işareti `=` kullanarak sütunlara böler, ikinci alanı (`-f`) çıkarır.
4. **`tr -d '"'`**: Gereksiz tırnak metadata'sını silerek çıktıyı temizler.

### 🦅 `awk`'ın Gücü (Sütun-Bazlı Ayrıştırma)

`grep` satırları ayırırken, `cut` karakterleri keserken, `awk` satırları indekslenmiş dikey sütunlara (`$1`, `$2`, `$3`...) ayrılmış yapısal veri kümeleri olarak işler.

`awk`, disk kullanımını temiz bir şekilde çıkarmak için kullanıldı:

```bash
df -h / | awk 'NR==2 {print "Total: " $2 " | Used: " $3 " | Free: " $4}'

```

- **`NR==2`**: `awk`'ı üst başlık sütunlarını görmezden gelip, doğrudan canlı veri içeren 2 numaralı satıra atlamaya yönlendirir.
- **İndeks Seçiciler**: Değişken boşluklara bakmaksızın dikey indeksleri dinamik olarak hedefler ($2 = Toplam Kapasite, $5 = Kullanım %, $4 = Kullanılabilir Tampon Alanı).

---

## 3. `df` vs `du`

İkisi de, düşük disk alanını sorun yaratmadan önce yakalamak için günlük olarak kullanılır.

- **`df -h` (Disk Free):** Mount edilmiş blok dosya sistemlerini genel olarak tarar, ham byte'ları insan-okunabilir notasyona (G, M) çevirir. Hızlı genel bakışlar için kullanılır.
- **`du -sh <yol>` (Disk Usage):** Belirli yerel dizin düğümlerini (örn. `/var/log`) recursive olarak gezer, kesin alan tahsis metriklerini derler. Neyin yer kapladığını bulmak için kullanılır (loglar, cache'ler, vb.).

---

## 📊 Komut Referansı

### 1. Temel Komutlar

| Komut             | Temel Amaç                                                                          | Pratik Örnek          | Flag / Seçenek             | Flag Fonksiyonu                                                                        |
| :---------------- | :---------------------------------------------------------------------------------- | :-------------------- | :------------------------- | :------------------------------------------------------------------------------------- |
| **`hostname`**    | Sistemin ağ adını gösterir veya geçici olarak değiştirir.                           | `hostname`            | **`-I`** (Büyük i)         | Host'a atanmış tüm aktif **IP adreslerini** yan yana listeler.                         |
|                   |                                                                                     |                       | **`-f`**                   | Sunucunun **FQDN**'sini (Fully Qualified Domain Name) gösterir.                        |
|                   |                                                                                     |                       | **`-s`**                   | Sadece kısa hostname'i gösterir (ilk noktadan önceki kısım).                           |
| **`hostnamectl`** | Modern `systemd` dağıtımları boyunca sistem kimliğini kalıcı olarak yönetir.        | `hostnamectl`         | **`status`**               | Varsayılan alt komut; OS, Kernel, Mimari, ve donanım özelliklerini yazdırır.           |
|                   |                                                                                     |                       | **`set-hostname <isim>`**  | Yeni hostname'i sistem dosyalarına **kalıcı olarak** işler.                            |
| **`timedatectl`** | Sistem saatini, yerel zaman dilimlerini, ve NTP ağ senkronizasyon durumunu yönetir. | `timedatectl`         | **`list-timezones`**       | Tüm geçerli global zaman dilimlerinin kapsamlı bir listesini döker.                    |
|                   |                                                                                     |                       | **`set-timezone <bölge>`** | Sunucu saatini, hedef bölgeye kalıcı olarak senkronize eder (örn. `Europe/Istanbul`).  |
|                   |                                                                                     |                       | **`set-ntp true`**         | Ağ atom saatleri üzerinden otomatik zaman senkronizasyonunu etkinleştirir.             |
| **`uname`**       | Linux kernel'i ve donanım mimarisi hakkında düşük seviyeli teknik metadata çıkarır. | `uname`               | **`-a`** (All)             | Mevcut tüm sistem ve kernel özelliklerini tek bir satırda özetler.                     |
|                   |                                                                                     |                       | **`-r`** (Release)         | Tam **Kernel release versiyonunu** çıkarır (docker/driver güncellemeleri için kritik). |
|                   |                                                                                     |                       | **`-m`** (Machine)         | Altta yatan donanım mimarisini döndürür (örn. `x86_64` veya `arm64`).                  |
| **`cat`**         | Dosya içeriklerini okumak, birleştirmek, ve stdout'a akıtmak için standart araç.    | `cat /etc/os-release` | **`-n`**                   | Dosya verisi yazdırılırken tüm çıktı satırlarının başına **satır numaraları** ekler.   |

---

### 2. Depolama & Stream İşleme Araçları

| Araç       | Temel Amaç                                                                                                      | Pratik Örnek         | Flag / Seçenek        | Flag Fonksiyonu                                                                                                           |
| :--------- | :-------------------------------------------------------------------------------------------------------------- | :------------------- | :-------------------- | :------------------------------------------------------------------------------------------------------------------------ |
| **`df`**   | Dosya sistemi depolama alanı kullanımını, boş blokları, ve global kapasiteleri raporlar.                        | `df -h /`            | **`-h`** (Human)      | Ham blokları **İnsan-Okunabilir** notasyona (Megabyte/Gigabyte) çevirir.                                                  |
|            |                                                                                                                 |                      | **`-t <tip>`**        | Düzeni, sadece belirtilen dosya sistemi tiplerini (örn. `ext4`, `xfs`) gösterecek şekilde filtreler.                      |
|            |                                                                                                                 |                      | **`--total`**         | Altta toplam birleştirilmiş metrikleri gösteren bir özet satırı ekler.                                                    |
| **`du`**   | Belirli dizin veya dosyaların tahmini disk alanı tahsisini recursive olarak ölçer.                              | `du -sh /var/log`    | **`-s`** (Summary)    | Alt dizin döküntülerini bastırır, sadece **toplam birleştirilmiş boyutu** döndürür.                                       |
|            |                                                                                                                 |                      | **`-h`** (Human)      | Dizin kapasitelerini insan-okunabilir notasyonla (`M` veya `G`) formatlar.                                                |
| **`grep`** | Girdileri satır satır ayrıştırır, hedeflenen metin desenine uyan akışları ayırır.                               | `grep "PRETTY_NAME"` | **`-i`**              | Desen eşleştirme sırasında büyük/küçük harf duyarlılığını görmezden gelir (örn. hem `ubuntu` hem `Ubuntu`'yu ayrıştırır). |
|            |                                                                                                                 |                      | **`-v`**              | Filtreyi ters çevirir; hedeflenen string ile **eşleşmeyen** satırları döndürür.                                           |
| **`cut`**  | Yapılandırılmış metin satırlarını, belirtilen byte pozisyonlarına veya karakterlere göre yatay olarak dilimler. | `cut -d '=' -f 2`    | **`-d '<karakter>'`** | Satırı bölmek için kullanılan özel **delimiter** sembolünü (örn. `=` veya `,`) ayarlar.                                   |
|            |                                                                                                                 |                      | **`-f <numara>`**     | Bölünmüş satırdan çıkarılacak kesin **alan indeks numarasını** seçer.                                                     |
| **`awk`**  | Sütunlu düzenler için inşa edilmiş, gelişmiş metin desen tarama ve işleme dili.                                 | `awk '{print $1}'`   | **`NR==<numara>`**    | İşlemleri belirli bir **Number of Record** satır indeksiyle sınırlar (örn. `NR==2`).                                      |
|            |                                                                                                                 |                      | **`$1, $2...`**       | Boşluklarla ayrıştırılmış dikey veri sütunlarını temsil eden indeks değişkenleri.                                         |
| **`tr`**   | String token'larını eşlemek, değiştirmek, veya temizlemek için kullanılan özel karakter çevirme filtresi.       | `tr -d '"'`          | **`-d`** (Delete)     | Hedeflenen token'ları açıkça **siler** (örn. tırnak işaretlerini kaldırır).                                               |

---

ℹ️ _Tüm komutlar hem Ubuntu hem Rocky Linux'ta doğrulanmıştır._
