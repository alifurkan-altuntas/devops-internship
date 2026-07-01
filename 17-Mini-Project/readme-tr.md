# 🚀 Mini Proje — Gerçek Bir Sunucuda Nginx, Docker, Git & SSH

Bu belge, gerçek kiralık bir Linux sunucusunu (yerel VM değil) Nginx, Docker, Git ve SSH anahtar tabanlı erişimle kurulumunu ve bu repodan Git aracılığıyla çekilen basit bir statik web sayfasının yayınlanmasını kapsar.

---

## 1. İlk Erişim & Kullanıcı Kurulumu

Sunucuya başlangıçta `root` olarak bağlanıldı. Önceki fazlardan gelen En Düşük Yetki Prensibi doğrultusunda, doğrudan root olarak çalışmak yerine ayrı bir sudo yetkili kullanıcı oluşturuldu:

```bash
adduser altun
usermod -aG sudo altun
```

`adduser` (etkileşimli), kolaylık için `useradd` yerine kullanıldı — şifre ve temel bilgileri doğrudan sorar.

Grup üyeliği doğrulandı:

```bash
groups altun
```

---

## 2. SSH Anahtar Tabanlı Erişim

Yeni kullanıcıya geçildi ve şifresiz SSH erişimi kuruldu — orijinal SSH fazıyla aynı şekilde, sadece bu sefer Vagrant VM yerine gerçek bir sunucuda:

```bash
su - altun
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys   # yerel makinenin açık anahtarı buraya yapıştırıldı
chmod 600 ~/.ssh/authorized_keys
```

Yerel makineden doğrulandı:

```bash
ssh altun@<sunucu_ip>
```

Şifre istemi olmadan bağlanıldı (yalnızca anahtarın kendi parolası soruldu, varsa).

---

## 3. Nginx Kurulumu

```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl status nginx
```

Ubuntu, kurulumdan hemen sonra Nginx'i otomatik olarak etkinleştirir ve başlatır (önceki Servis Yönetimi fazında gözlemlenen davranışla tutarlı). Doğrulandı:

```bash
curl localhost
```

ve tarayıcıdan sunucunun IP'sine gidilerek varsayılan "Welcome to nginx!" sayfası görüldü.

---

## 4. Docker Kurulumu

Docker'ın Ubuntu için resmi kurulum adımları izlendi (eski `.list`/`.gpg` yöntemi yerine güncel `.sources` formatı kullanıldı):

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Daemon çalışıyor mu doğrulandı ve standart hello-world image'ı ile test edildi:

```bash
sudo systemctl status docker
sudo docker run hello-world
```

Çıktı onayladı: _"Hello from Docker! This message shows that your installation appears to be working correctly."_

Docker komutları boyunca `sudo` ile çalıştırıldı — daemon'ın soketi varsayılan olarak root'a aittir. (`usermod -aG docker altun` ile `sudo`'yu atlamak mümkündür ama root erişiminin ne zaman kullandığının farkındalığı için `sudo` bilinçli olarak korundu.)

---

## 5. Git Kurulumu ve Bu Repoyu Klonlama

```bash
sudo apt install git -y
git --version
git clone https://github.com/alifurkan-altuntas/devops-internship.git
```

Bu, eğitim reposunun tamamını — mini projenin `index.html`'i dahil — sunucuya indirdi.

---

## 6. Web Sayfasını Yayınlama

Nginx varsayılan olarak `/var/www/html/` klasöründen dosya sunar. Repodaki sayfa oraya manuel olarak kopyalandı:

```bash
sudo cp ~/devops-internship/17-Mini-Project/index.html /var/www/html/index.html
```

### 🔍 Gerçek Bir Tuzak: Kaynak Dosya vs. Servis Edilen Dosya

Klonlanan repo (`~/devops-internship/...`) ve Nginx'in gerçekte servis ettiği dosya (`/var/www/html/index.html`) **iki ayrı kopyadır**, aynı dosya değil. Güncellenmiş bir sürüm almak için `git pull` çalıştırmak yalnızca repo kopyasını günceller — Nginx'in servis ettiğini **otomatik olarak güncellemez**.

Bu doğrudan yaşandı: HTML düzenlenip GitHub'a push edildi, sonra sunucuda `git pull` çalıştırıldı — ama canlı sayfa hâlâ eski versiyonu gösteriyordu, çünkü `cp` adımı atlanmıştı. Kopyalama komutunu tekrar çalıştırmak sorunu çözdü:

```bash
cd ~/devops-internship
git pull
sudo cp ~/devops-internship/17-Mini-Project/index.html /var/www/html/index.html
```

Gerçek bir production ortamında bu manuel adım genellikle otomatize edilir — ya bir symlink (Nginx'in doğrudan repo dosyasına işaret etmesi, kopyalamaya gerek kalmaz), küçük bir deploy scripti veya CI/CD pipeline ile. Bu proje için manuel `cp` kasıtlı olarak basit tutuldu, ama bu adımın _neden_ var olduğunu anlamak, onu atlamaktan daha önemlidir.

### Bir Diğer Gerçek Sorun: `https://` vs `http://`

Tarayıcıdan `https://<ip>` ile ziyaret edildiğinde "refused to connect" alındı, oysa sunucuda `curl localhost` sorunsuz çalışıyordu. Sebep: yalnızca port 80 (HTTP) yapılandırılmıştı — TLS sertifikası veya port 443 dinleyicisi kurulmamıştı, bu yüzden HTTPS'e bağlanacak bir şey yoktu. `http://<ip>` olarak açıkça yazılması sorunu çözdü. (Bu, önceki Proxy fazındaki 502 hatasıyla aynı kategori — servis çalışıyordu ama istek yanlış yere gidiyordu.)

---

## 📊 Bu Sunucuda Çalışan Bileşenler

| Bileşen       | Durum                               | Notlar                                                                      |
| ------------- | ----------------------------------- | --------------------------------------------------------------------------- |
| **Nginx**     | Aktif, port 80'de servis veriyor    | HTTPS/TLS yapılandırılmadı                                                  |
| **Docker**    | Aktif, `hello-world` ile doğrulandı | Komutlar `sudo` ile çalıştırıldı                                            |
| **Git**       | Kurulu, repo klonlandı              | Kaynak dosyalar servis edilenden ayrı                                       |
| **SSH**       | Yalnızca anahtar tabanlı            | Şifre girişi bu fazda devre dışı bırakılmadı, ama anahtar erişimi çalışıyor |
| **Kullanıcı** | `altun`, sudo yetkili, root değil   | Doğrudan root olarak çalışmak yerine oluşturuldu                            |

---

ℹ️ _Bu, yerel bir VM'de değil, gerçek kiralık bir sunucuda yapıldı — temel komutlar önceki fazlarla aynıydı, ama hataların sonuçları (firewall, DNS, açık servisler) burada sanal bir Vagrant VM'in tam olarak kopyalayamadığı şekilde gerçektir._
