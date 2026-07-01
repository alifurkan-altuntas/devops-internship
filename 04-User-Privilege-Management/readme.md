# 🔑 Linux Kullanıcı Yönetimi & Yetki Kontrolü

Bu belge, kullanıcı/grup yönetimi ve `sudoers` mimarisi içinde En Düşük Yetki Prensibi (Least Privilege) kullanılarak sudo kısıtlamalarını kapsar.

---

## 1. sudo Erişimini Kısıtlama (En Düşük Yetki Prensibi)

`wheel` veya `sudo` grubu aracılığıyla tam root erişimi vermek, buna ihtiyaç duymayan hesaplar için risklidir. Bunu azaltmak için, bir test hesabı (`devopstester`) yalnızca `systemctl restart nginx` komutunu çalıştıracak şekilde kısıtlandı; diğer tüm servis yönetimi alt komutları engellendi.

### 🛠️ Adım Adım Güvenlik Uygulaması

1. **Test Hesabı Oluşturuldu:**

   ```bash
   sudo useradd -m devopstester
   sudo passwd devopstester
   ```

2. **`visudo` ile sudo İzinleri Yapılandırıldı:**
   Kısıtlamaları uygulamak için `/etc/sudoers` yapılandırma dosyası `sudo visudo` komutu kullanılarak güvenli bir şekilde düzenlendi ve en alta şu satır eklendi:

   ```text
   devopstester ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
   ```

### 🔍 Binary Yolunu Doğrulama

`sudoers` kuralı yazmadan önce, binary'nin tam konumu doğrulanmalıdır:

```bash
which systemctl
```

Örnek çıktı:

```text
/usr/bin/systemctl
```

Bu yol Linux dağıtımları ve ortamlar arasında farklılık gösterebilir.

- **`devopstester`** — kısıtlanan hesap
- **`NOPASSWD:`** — bu komut için şifre sorulmaz (otomasyon için yararlı)
- **`/usr/bin/systemctl restart nginx`** — yalnızca bu tam komut, argümanları dahil çalıştırılabilir

---

### 🔒 Neden Direkt `/etc/sudoers` Düzenlemek Yerine `visudo`?

`visudo`'nun tek ama kritik farkı: **kaydetmeden önce syntax doğrulaması yapar.** Yanlış bir şey yazıldıysa hata verir. Direkt düzenlenseydi, hatalı bir satır `sudo`'yu tamamen kırabilir ve sisteme erişimi kaybedebilirdin.

Ek olarak:

- Dosyayı kilitler, eş zamanlı düzenlemeleri engeller
- Hatalı yapılandırmaları önler
- Yanlışlıkla sudo erişimini kırma riskini azaltır

---

## 2. Doğrulama & Sonuçlar

`devopstester` olarak test edildi:

- **Test A (`sudo systemctl restart nginx`):** Şifre sorulmadan başarıyla çalıştı. ✅
- **Test B (`sudo systemctl stop nginx`):** Engellendi:

```text
Sorry, user devopstester is not allowed to execute '/usr/bin/systemctl stop nginx' as root on altun.
```

Kısıtlamanın doğru çalıştığı doğrulandı.

---

## 📊 Kullanıcı & Yetki Yönetimi Komut Referansı

| Komut          | Amacı                                                | Örnek                    | Önemli Seçenekler | Açıklama                                                           |
| -------------- | ---------------------------------------------------- | ------------------------ | ----------------- | ------------------------------------------------------------------ |
| **`useradd`**  | `/etc/passwd`'a yeni kullanıcı ekler.                | `useradd -m devopsuser`  | **`-m`**          | Ev dizini otomatik oluşturur.                                      |
| **`passwd`**   | Kullanıcı şifresini ayarlar/günceller.               | `passwd devopsuser`      | —                 | Şifreler güvenli şekilde güncellenir.                              |
| **`usermod`**  | Mevcut kullanıcı profilini değiştirir.               | `usermod -aG wheel user` | **`-aG`**         | Eski grup üyeliklerini silmeden ekler (`a` = append, `G` = group). |
| **`groupadd`** | `/etc/group`'a yeni grup ekler.                      | `groupadd security-team` | —                 | Rol tabanlı erişim için mantıksal grup oluşturur.                  |
| **`id`**       | Kullanıcının UID, GID ve grup üyeliklerini gösterir. | `id devopstester`        | —                 | **UID**, **GID** ve grupları döndürür.                             |
| **`sudo`**     | Komutu yükseltilmiş root yetkileriyle çalıştırır.    | `sudo visudo`            | —                 | `/etc/sudoers` kurallarına göre çalışır.                           |

---

ℹ️ _Tüm adımlar test edilmiş ve doğrulanmıştır._
