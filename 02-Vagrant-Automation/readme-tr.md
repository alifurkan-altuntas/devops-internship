# 🛠️ Vagrant Kurulumu & Sorun Giderme

Vagrant'ı VMware provider'ı ile kurarken karşılaşılan sorunlar, ve bunların nasıl düzeltildiği.

---

## 1. Sorun: VMware Provider Bulunamadı

### 🚨 Problem

Vagrant, varsayılan olarak VirtualBox'ı kullanır. Sadece VMware kurulu bir host'ta `vagrant up` çalıştırmak, 'kullanılabilir provider yok' hatasıyla başarısız olur.

### 🔍 Sebep

Vagrant'ın, VMware ile iletişim kurabilmesi için bir plugin'e ihtiyacı var. Bu olmadan, Vagrant box'ı çalıştıracak bir provider bulamaz.

### 🛠️ Adım Adım Çözüm Süreci

Çözüm:

1. **Eski Vagrantfile'ı sildim**, temiz başlamak için.
2. **Vagrant VMware Utility'i kurdum**, VMware desteği için gereken arka plan servisi.
3. **Vagrant plugin'ini kurdum:**

```bash
   vagrant plugin install vagrant-vmware-desktop

```

4. **Vagrant ortamını yeniden başlattım.**

---

## 2. Sorun: Box Bulunamadı (404 Hatası)

### 🚨 Problem

`vagrant init rocky Linux/9` çalıştırmak, box registry'den `404 Not Found` döndürdü.

### 🔍 Sebep

Box adı yanlış/hatalıydı — registry'deki hiçbir şeyle eşleşmiyordu.

### 🛠️ Adım Adım Çözüm Süreci

Çözüm:

1. Çalışan bir box için Vagrant Cloud registry'sini aradım.
2. Doğru box adını kullandım:

```bash
   vagrant init generic/rocky9

```

3. VM'i kaldırdım:

```bash
   vagrant up

```

---

## 📊 Referans

### 1. Bileşenler

| Bileşen                      | Rolü                                                           | Çalışma Katmanı             | Bağımlılık / Gereksinimler                                   |
| :--------------------------- | :------------------------------------------------------------- | :-------------------------- | :----------------------------------------------------------- |
| **`Vagrant CLI`**            | `Vagrantfile`'ı okur ve VM yaşam döngüsünü yönetir.            | Host Kullanıcı Kapsamı      | Örnekleri çalıştırmak için bir hypervisor motoru gerektirir. |
| **`Vagrant VMware Utility`** | VMware için ağ ve durum yönetimini halleden arka plan servisi. | Host Sistem Kapsamı         | Native bir OS servisi/binary olarak kurulmalıdır.            |
| **`vagrant-vmware-desktop`** | Vagrant'ın VMware ile konuşmasını sağlayan plugin.             | Vagrant Uygulama Kapsamı    | Hem host utility'i hem aktif Vagrant binary'sini gerektirir. |
| **`Vagrant Boxes`**          | Önceden hazırlanmış OS imajları (örn. `generic/rocky9`).       | Paylaşılan Depolama Cache'i | Public HashiCorp Cloud Registry'den otomatik olarak çekilir. |

---

### 2. Sorun & Çözüm Referans Tablosu

| Hedef Alan                   | Karşılaşılan Hata / Belirti                                  | Kök Sebep                                     | Komut / Çözüm Eylemi                                          | Beklenen Başarı Sonucu                                                                     |
| :--------------------------- | :----------------------------------------------------------- | :-------------------------------------------- | :------------------------------------------------------------ | :----------------------------------------------------------------------------------------- |
| **Provider Bağlantısı**      | `"No usable providers were found on this system..."`         | VMware ile iletişim kurmak için eksik plugin. | `vagrant plugin install vagrant-vmware-desktop`               | Vagrant'ın `vmware_desktop` motorunu başarıyla okuyup eşleştirmesini sağlar.               |
| **Registry Eşleştirme**      | Box başlatma sırasında `HTTP 404 Not Found`.                 | Yanlış box adı (`rocky Linux/9`).             | `vagrant init generic/rocky9`                                 | Vagrant'ı doğrudan, doğrulanmış, son derece uyumlu bir evrensel imaj düzenine yönlendirir. |
| **Yaşam Döngüsü Çalıştırma** | VM donuyor veya ağ arayüzü senkronizasyonu başarısız oluyor. | Eski config veya eksik kurulum.               | `rm Vagrantfile && vagrant init generic/rocky9 && vagrant up` | Temiz bir sıfırlama ve yeni bir VM.                                                        |

---

ℹ️ _Tüm adımlar yerel olarak test edilmiştir._
