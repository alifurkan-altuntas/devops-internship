# 🔐 Linux SSH, SCP & SFTP

Bu belge, anahtar çiftleri kullanarak şifresiz SSH erişimi kurulumunu ve SCP/SFTP ile dosya transferini kapsar.

---

## 1. Şifresiz SSH Erişimi Kurulumu

SSH anahtar tabanlı kimlik doğrulama, şifre yerine bir anahtar çifti kullanır:

- **Özel anahtar** makinenizde kalır, asla paylaşılmaz.
- **Açık anahtar** sunucunun `~/.ssh/authorized_keys` dosyasına eklenir.
- Sunucu, eşleşen özel anahtara sahip olduğunuzu doğrulamak için açık anahtarı kullanır — şifre gerekmez.

### 🛠️ Adımlar

1. **Anahtar çifti oluşturma:**

   ```bash
   ssh-keygen -t ed25519 -C "etiketiniz"
   ```

   - `-t ed25519`: modern bir algoritma — RSA'ya göre daha küçük anahtar boyutu ama eşdeğer veya daha iyi güvenlik.
   - `-C`: anahtarı tanımlamak için bir etiket/yorum, isteğe bağlı.
   - Varsayılan kayıt konumunu kabul etmek için Enter. Parola isteğe bağlıdır ama önerilir (bu parola özel anahtarı yerel olarak korur — sunucu şifresinden ayrıdır).

2. **Açık anahtarı sunucuya kopyalama.**

   Bunun için standart araç `ssh-copy-id`'dir:

   ```bash
   ssh-copy-id user@server_ip
   ```

   Bu şunları otomatikleştirir: şifreyle bağlanma, sunucuda `~/.ssh` yoksa oluşturma, izinleri düzeltme ve açık anahtarı `authorized_keys`'e ekleme (mevcut anahtarların üzerine yazmadan).

   **Not:** `ssh-copy-id` bir bash scriptidir ve Windows'ta varsayılan olarak mevcut değildir. Windows'ta aynı sonuç manuel olarak elde edilmelidir:

   ```bash
   # Açık anahtarı göster (istemcide)
   cat ~/.ssh/id_ed25519.pub

   # Sunucuya şifreyle bağlan
   ssh user@server_ip

   # Sunucuda: klasör ve dosyayı hazırla
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   nano ~/.ssh/authorized_keys   # açık anahtarı buraya yapıştır
   chmod 600 ~/.ssh/authorized_keys
   ```

3. **Bağlantıyı test etme:**

   ```bash
   ssh user@server_ip
   ```

   Anahtara parola belirlendiyse, SSH bunu sorar — sunucu şifresini değil. Parola belirlenmemişse anında bağlanır.

### 🔐 `chmod` İzinleri Neden Önemli

SSH, `.ssh` ve `authorized_keys` üzerindeki izinleri güvenmeden önce aktif olarak kontrol eder. İzinler çok açıksa, SSH bunları sessizce kullanmayı reddedebilir ve şifre doğrulamasına geri dönebilir:

- `chmod 700 ~/.ssh` → yalnızca sahip klasörü okuyabilir/yazabilir/girebilir.
- `chmod 600 ~/.ssh/authorized_keys` → yalnızca sahip dosyayı okuyabilir/yazabilir.

Bunun sebebi: `authorized_keys` "kimin girebileceği"nin listesidir. Başkaları dosyayı düzenleyebilseydi, kendi anahtarlarını ekleyip sisteme erişim sağlayabilirlerdi — bu yüzden SSH, güvenli olmadığından emin olamadığı bir dosyaya güvenmez.

4. **Şifre girişini devre dışı bırakma (isteğe bağlı ama önerilen):**

   `/etc/ssh/sshd_config` dosyasını düzenle:

   ```text
   PasswordAuthentication no
   ```

   **Önemli:** bu satır yorumlanmışsa (`#` ile başlıyorsa), etkisi yoktur — ayarın gerçekten uygulanması için `#` kaldırılmalıdır.

   Ardından servisi yeniden başlat:

   ```bash
   sudo systemctl restart sshd
   ```

### 🔍 Gerçekten Çalıştığını Doğrulama

Kısıtlamanın gerçek olduğunu doğrulamak için her iki yönü de test etmek değerlidir:

- Anahtarı `authorized_keys`'den kaldır ve bağlanmayı dene → başarısız olmalı.
- Geri ekle ve tekrar dene → başarılı olmalı.

Bu, bağlantının gerçekten o anahtara bağlı olduğunu, başka bir şeye değil, kanıtlar.

### 🗂️ Birden Fazla Anahtarı Yönetme

Farklı sunucular için ayrı anahtarlarınız varsa (örn. Rocky Linux için biri, Ubuntu için biri), SSH hangisini kullanacağını varsayılan yol (`~/.ssh/id_ed25519`) değilse otomatik olarak tahmin etmez. Özel bir isimle kaydedilen bir anahtar için açıkça belirtilmesi gerekir:

```bash
ssh -i ~/.ssh/id_ed25519_ubuntu user@server_ip
```

Bunu unutmak, anahtar doğru olsa bile `Permission denied (publickey)` hatasının yaygın bir sebebidir — SSH yanlış (veya hiç) anahtar deniyordu.

Verbose modu, bunu teşhis etmeye yardımcı olur:

```bash
ssh -v -i ~/.ssh/id_ed25519_ubuntu user@server_ip
```

### 📄 SSH Config Dosyasıyla Basitleştirme

Her seferinde `-i` yazmak yerine, bağlantı ayrıntıları `~/.ssh/config`'e kaydedilebilir:

```text
Host ubuntu-vm
    HostName 192.168.1.50
    User altun
    IdentityFile ~/.ssh/id_ed25519_ubuntu

Host rocky-vm
    HostName 192.168.1.60
    User vagrant
    IdentityFile ~/.ssh/id_ed25519
```

Sonrasında bağlanmak şu kadar basit:

```bash
ssh ubuntu-vm
```

Her seferinde IP, kullanıcı adı veya anahtar yolu yazmak gerekmez.

---

## 2. Dosya Transferi: SCP vs SFTP

Her ikisi de SSH üzerinden çalışır, bu yüzden aynı anahtar tabanlı kimlik doğrulama geçerlidir — SSH erişimi çalışıyorsa ekstra kurulum gerekmez.

### 🛠️ SCP (Güvenli Kopyalama)

Komut satırından tek seferlik dosya/klasör transferleri.

```bash
# Dosya yükle
scp localfile.txt user@server_ip:/home/user/

# Dosya indir
scp user@server_ip:/home/user/remotefile.txt ./

# Klasör kopyala (özyinelemeli)
scp -r local_folder user@server_ip:/home/user/
```

### 🛠️ SFTP (SSH Dosya Transfer Protokolü)

Dosyalara göz atmak ve transfer etmek için etkileşimli oturum açar — ne taşıyacağınıza karar vermeden önce etrafı incelemeniz gerektiğinde yararlıdır.

```bash
sftp user@server_ip
```

Oturum içinde:

```text
pwd      # uzak çalışma dizini
lpwd     # yerel çalışma dizini
ls       # uzak dosyaları listele
cd       # uzak dizini değiştir
lcd      # yerel dizini değiştir
get file # dosya indir
put file # dosya yükle
exit     # oturumu kapat
```

---

## 📊 Komut Referansı

| Komut             | Amacı                                                   | Örnek                              | Notlar                                                               |
| ----------------- | ------------------------------------------------------- | ---------------------------------- | -------------------------------------------------------------------- |
| **`ssh-keygen`**  | Açık/özel anahtar çifti oluşturur.                      | `ssh-keygen -t ed25519`            | `-t` algoritmayı belirler; `ed25519` modern varsayılan.              |
| **`ssh-copy-id`** | Açık anahtarı sunucunun `authorized_keys`'ine kopyalar. | `ssh-copy-id user@host`            | Bash scripti — Windows'ta varsayılan olarak mevcut değil.            |
| **`chmod`**       | Dosya/klasör izinlerini ayarlar.                        | `chmod 600 ~/.ssh/authorized_keys` | SSH, izinler çok açıksa anahtar dosyalarını kullanmayı reddedebilir. |
| **`ssh -i`**      | Belirli bir özel anahtarla bağlanır.                    | `ssh -i ~/.ssh/key user@host`      | Anahtar varsayılan yolda değilse gereklidir.                         |
| **`scp`**         | Dosyaları/klasörleri SSH üzerinden kopyalar.            | `scp -r folder user@host:/path/`   | `-r` klasörler için özyinelemeli.                                    |
| **`sftp`**        | Etkileşimli dosya transfer oturumu açar.                | `sftp user@host`                   | `get`, `put`, `ls`, `cd` vb. destekler.                              |

---

ℹ️ _Tüm komutlar Windows host ile Ubuntu/Rocky Linux VM'ler arasında yerel olarak test edilmiştir._
