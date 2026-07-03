# 🚀 DevOps & Linux Altyapı Yolculuğu - Türkiye Sigorta

🌐 [Read in English](./README-EN.md)

Bu repo, stajım boyunca takip ettiğim öğrenme sürecimi, altyapı otomasyonu pratiklerimi, hata çözümlerimi ve Linux sistem yönetimi görevlerimi belgeleyen DevOps mühendisliği günlüğümdür.

## 📍 Şu An Neredeyim

Verilen Linux yol haritasının tüm 17 fazını, son mini proje dahil, tamamladım — Nginx, Docker, Git ve SSH, gerçek (kiralık) bir sunucuda kurulu, ve bu repodan doğrudan çekilen bir sayfayı sunuyor.

Yol haritasının dışında, eğitmenimin verdiği ek konular üzerinde çalıştım: `sed`, `at`, path bazlı IP gruplama, OSI modeli, routing & forwarding, DNS derinlemesine (resolver zinciri, 8 kayıt tipi, TTL, negative caching, debug araçları, cloud kesintileri araştırması) — her biri için quiz çözüldü, 3'ünde de %100 alındı.

Nginx derinleşmesi tamamlandı: reverse proxy, path bazlı yönlendirme, path rewrite, path engelleme, forward proxy (Squid). 20 test senaryosu gerçek sunucuda denendi — test sürecinde IPv6/IPv4 çakışması keşfedildi ve belgelendi. Kendi inisiyatifimle rate limiting ve load balancing de eklendi (round-robin, failover, `least_conn`, `ip_hash`).

Tüm fazların (01–20) Türkçe/İngilizce belge dönüşümü tamamlandı.

Sırada Kubernetes fazı var.

---

## 📁 Repo Yapısı

- [01-Linux-Basics](./01-Linux-Basics/): Temel Linux komutları ve metin işleme (`awk`, `grep`, `cut`), ve özel otomasyon scriptleri. ([EN](./01-Linux-Basics/readme-en.md) / [TR](./01-Linux-Basics/readme.md))
- [02-Vagrant-Automation](./02-Vagrant-Automation/): Infrastructure as Code (IaC) ortamları, ve çoklu dağıtım provisioning. ([EN](./02-Vagrant-Automation/readme-en.md) / [TR](./02-Vagrant-Automation/readme.md))
- [03-File-System-Management](./03-File-System-Management/): Depolama diagnostiği, disk yazma işlemleri (`dd`), ve sıralama pipeline'ları. ([EN](./03-File-System-Management/readme-en.md) / [TR](./03-File-System-Management/readme.md))
- [04-User-Privilege-Management](./04-User-Privilege-Management/): Kimlik erişim kontrolü, sistem grup yaşam döngüleri, ve sudoers yapılandırması (Least Privilege Prensibi). ([EN](./04-User-Privilege-Management/readme-en.md) / [TR](./04-User-Privilege-Management/readme.md))
- [05-Linux-Permissions](./05-Linux-Permissions/): Dosya sistemi erişim kontrolü, recursive sahiplik değişiklikleri, ve sticky bit izolasyonu. ([EN](./05-Linux-Permissions/readme-en.md) / [TR](./05-Linux-Permissions/readme.md))
- [06-Linux-Process-Management](./06-Linux-Process-Management/): Süreç durum izleme, CPU önceliği ayarlamaları (`nice`/`renice`), ve sinyaller. ([EN](./06-Linux-Process-Management/readme-en.md) / [TR](./06-Linux-Process-Management/readme.md))
- [07-Linux-Service-Management](./07-Linux-Service-Management/): Systemd servis yönetimi, kesintisiz yeniden yüklemeler, ve journalctl ile log yönetimi. ([EN](./07-Linux-Service-Management/readme-en.md) / [TR](./07-Linux-Service-Management/readme.md))
- [08-Linux-Log-Analysis](./08-Linux-Log-Analysis/): Log işleme pipeline'ları, `sed`, ve dağıtımlar arası IPv4/IPv6 farkları. ([EN](./08-Linux-Log-Analysis/readme-en.md) / [TR](./08-Linux-Log-Analysis/readme.md))
- [09-Linux-Network-Management](./09-Linux-Network-Management/): DNS sorguları, dinleyen portları kontrol etme, ve TLS sertifika doğrulama. ([EN](./09-Linux-Network-Management/readme-en.md) / [TR](./09-Linux-Network-Management/readme.md))
- [10-Linux-Storage-Management](./10-Linux-Storage-Management/): Disk partition'lama, `ext4` ile formatlama, ve `/etc/fstab` üzerinden kalıcı mount'lar. ([EN](./10-Linux-Storage-Management/readme-en.md) / [TR](./10-Linux-Storage-Management/readme.md))
- [11-Linux-LVM-Management](./11-Linux-LVM-Management/): LVM kurulumu, canlı volume büyütme, ve bir disk-alanı olayının anlatımı. ([EN](./11-Linux-LVM-Management/readme-en.md) / [TR](./11-Linux-LVM-Management/readme.md))
- [12-Linux-SSH-Management](./12-Linux-SSH-Management/): Key çiftleri ile şifresiz SSH erişimi, SSH config kısayolları, ve SCP/SFTP ile dosya transferleri. ([EN](./12-Linux-SSH-Management/readme-en.md) / [TR](./12-Linux-SSH-Management/readme.md))
- [13-Linux-Proxy-Management](./13-Linux-Proxy-Management/): Forward vs reverse proxy kavramları, Nginx'in `proxy_pass`'i, ve gerçek bir 502 Bad Gateway debug hikayesi. ([EN](./13-Linux-Proxy-Management/readme-en.md) / [TR](./13-Linux-Proxy-Management/readme.md))
- [14-Linux-Bash-Scripting](./14-Linux-Bash-Scripting/): Değişkenler, komut yerine geçirme (command substitution), sayısal koşullar, ve bir disk kullanım uyarı scripti. ([EN](./14-Linux-Bash-Scripting/readme-en.md) / [TR](./14-Linux-Bash-Scripting/readme.md))
- [15-Linux-Cron-Automation](./15-Linux-Cron-Automation/): `cron` ve `at` ile zamanlama, gerçek bir `sudo`-cron-içinde debug hikayesi, ve `logrotate`'e bir bakış. ([EN](./15-Linux-Cron-Automation/readme-en.md) / [TR](./15-Linux-Cron-Automation/readme.md))
- [16-Git-Basics](./16-Git-Basics/): `git clone`, branching, merging, ve bu repo üzerinde gerçekten çözülen bir push-reddedildi/editör-takıldı çakışması. ([EN](./16-Git-Basics/readme-en.md) / [TR](./16-Git-Basics/readme.md))
- [17-Mini-Project](./17-Mini-Project/): Gerçek bir kiralık sunucuda Nginx, Docker, Git, ve SSH kurulumu — bu repodan çekilip canlıya alınan statik bir sayfa. ([EN](./17-Mini-Project/readme-en.md) / [TR](./17-Mini-Project/readme.md))
- [18-Linux-Networking-Fundamentals](./18-Linux-Networking-Fundamentals/): OSI modeli, routing & forwarding, ve DNS (resolver zinciri, kayıt tipleri, TTL) — gerçek senaryolarla ve `tcpdump`/`dig +trace` ile doğrulanmış. Ayrıca AWS/Cloudflare/Google Cloud'un gerçek kesintilerine dair araştırma içerir. ([EN](./18-Linux-Networking-Fundamentals/readme-en.md) / [TR](./18-Linux-Networking-Fundamentals/readme.md) — Outage araştırması: [EN](./18-Linux-Networking-Fundamentals/dns-outages-EN.md) / [TR](./18-Linux-Networking-Fundamentals/dns-outages-TR.md))
- [19-Nginx-Derinleşme](./19-Nginx-Derinleşme/): Reverse proxy, path bazlı yönlendirme, path rewrite, path engelleme, ve forward proxy (Squid) — gerçek bir sunucuda uygulamalı olarak test edildi. ([EN](./19-Nginx-Derinleşme/readme-en.md) / [TR](./19-Nginx-Derinleşme/readme.md))
- [20-Rate-Limiting-Load-Balancing](./20-Rate-Limiting-Load-Balancing/): Nginx'te rate limiting (`limit_req_zone`, `burst`, `nodelay`) ve load balancing (round-robin, failover, `least_conn`, `ip_hash`). ([TR](./20-Rate-Limiting-Load-Balancing/README.md) / [EN](./20-Rate-Limiting-Load-Balancing/README-EN.md))

### 📝 Değerlendirme & Sınav Materyalleri

- [challenges.md](./challenges.md): Senaryo soruları ve cevapları (Faz 1-4).
- [quiz-results.md](./quiz-results.md): 20 soruluk quiz, %85 skor (Faz 1-4).
- [Faz 5 Quiz Sonuçları](./05-Linux-Permissions/quiz-results.md): umask ve sticky bit üzerine 5 soruluk quiz.
- [Faz 6 Quiz Sonuçları](./06-Linux-Process-Management/quiz-results.md): Süreç izleme ve sinyaller üzerine quiz.
- [Faz 7 Quiz Sonuçları](./07-Linux-Service-Management/quiz-results.md): systemd ve journalctl üzerine quiz.
- [Faz 8 Quiz Sonuçları](./08-Linux-Log-Analysis/quiz-results.md): Log işleme üzerine quiz.
- [Faz 9 Quiz Sonuçları](./09-Linux-Network-Management/quiz-results.md): Networking ve TLS üzerine quiz.
- [Faz 10 Quiz Sonuçları](./10-Linux-Storage-Management/quiz-results.md): Depolama ve fstab üzerine quiz.
- [Faz 11 Quiz Sonuçları](./11-Linux-LVM-Management/quiz-results.md): LVM üzerine quiz.
- [Faz 12 Quiz Sonuçları](./12-Linux-SSH-Management/quiz-results.md): SSH key'leri, SCP, ve SFTP üzerine quiz.
- [Faz 13 Quiz Sonuçları](./13-Linux-Proxy-Management/quiz-results.md): Forward/reverse proxy ve Nginx routing üzerine quiz.
- [Faz 14 Quiz Sonuçları](./14-Linux-Bash-Scripting/quiz-results.md): Bash değişkenleri, koşullar, ve scripting temelleri üzerine quiz.
- [Faz 15 Quiz Sonuçları](./15-Linux-Cron-Automation/quiz-results.md): Cron zamanlama, sudoers, ve log rotasyonu üzerine quiz.
- [Faz 16 Quiz Sonuçları](./16-Git-Basics/quiz-results.md): Git branching, merging, ve bir push çakışması çözme üzerine quiz.

### 🎓 Kurslar & Sertifikalar

- **DevOps - Linux Temelleri** (Udemy, Türkiye Sigorta üzerinden) — 23 Haziran 2026'da tamamlandı. Şirket laptop'unda hands-on VM çalışmasının mümkün olmadığı bir günde, alternatif bir öğrenme yolu olarak alındı.

---

## 📅 Günlük İlerleme Kayıtları

### 🔹 17 Haziran 2026 | Vagrant Kurulumu & Linux Temelleri

_Daha önce Vagrant kullanmamıştım — önceki sanallaştırma deneyimim direkt VMware ile oldu. VirtualBox kurulu olmadığı için (Vagrant'ın varsayılan provider'ı), `vagrant up` sürekli başarısız oluyordu. Vagrant'ı VMware provider'ı ile çalıştırmanın yolunu araştırmam gerekti._

- **Görevler & Hedefler:**
  - Infrastructure as Code (IaC) iş akışlarını benimsemek için **Vagrant**'ı `vmware_desktop` provider'ı üzerinden kullanarak izole test ortamları başlattım.
  - **Ubuntu** ve **Rocky Linux 9.8 (Minimal CLI)** sunucu örnekleri kurdum ve yapılandırdım.
  - Temel Linux komutlarını araştırdım ve kurumsal yapılandırma standartlarını analiz ettim (Rocky Linux'ta FQDN varsayılanları).
  - Canlı sistem metriklerini izlemek için bir shell scripti yazdım.
- **Kilometre Taşları & Çıktılar:**
  - 🛠️ Otomatik Ortam Kurulumu: [Vagrant Logları & Sorun Giderme (EN](./02-Vagrant-Automation/readme-en.md) / [TR)](./02-Vagrant-Automation/readme.md)
  - 📜 Linux Temelleri & Özel Script: [Linux Temelleri Notları (EN](./01-Linux-Basics/readme-en.md) / [TR)](./01-Linux-Basics/readme.md)

### 🔹 18 Haziran 2026 | Dosya Sistemi & Depolama Diagnostiği

_`dd` ile `fallocate` arasındaki farkı sadece okumak yerine gerçekten görmek istedim — gerçek bir 10GB dosya oluşturmak, sparse vs fiziksel allocation ayrımını netleştirdi._

- **Görevler & Hedefler:**
  - Linux dosya sistemi dizin hiyerarşilerini, dinamik izinleri, ve depolama diagnostik navigasyonunu (`pwd`, `ls`, `cd`, `mkdir`, `rm`, `cp`, `mv`) öğrendim.
  - Düşük seviyeli blok yazma ile 10 GB'lık bir test dosyası oluşturdum.
  - `dd` ve `fallocate`'in disk yazmalarını nasıl ele aldığını karşılaştırdım (sparse vs fiziksel allocation).
  - Sistemdeki en büyük 10 dosyayı listelemek için `find`, `du`, ve `sort` ile bir komut pipeline'ı kurdum.
- **Kilometre Taşları & Çıktılar:**
  - 🗂️ Dosya Sistemi İşlemleri & Pipeline'lar: [Depolama Diagnostiği & Komut Matrisi (EN](./03-File-System-Management/readme-en.md) / [TR)](./03-File-System-Management/readme.md)

### 🔹 18 Haziran 2026 | Kimlik Erişim Kontrolü & Güvenlik Sıkılaştırma (Least Privilege)

_Sudoers kısıtlamasının nasıl çalıştığını gerçekten anlamak için, sadece izin verilen komutu test etmedim — kısıtlamanın tam olarak nerede ve nasıl bloke ettiğini görmek için, izin kapsamı dışındaki komutları da kasıtlı olarak denedim._

- **Görevler & Hedefler:**
  - Linux kullanıcı ve grup kimlik doğrulama mekaniklerini (`useradd`, `groupadd`, `id`) ve `/etc/passwd` ile `/etc/group` içindeki güvenlik sınırlarını öğrendim.
  - Yapısal işletim sistemi sıkılaştırmasını uygulamak için **Least Privilege Prensibi (En Düşük Yetki İlkesi)**'ni uyguladım.
  - `visudo` ve `/etc/sudoers` mimarisi üzerinden özel olarak yapılandırılmış, kısıtlı bir operatör hesabı (`devopstester`) oluşturdum.
  - Kullanıcıyı, root alanına (`ALL=(root)`) açıkça yönlendirilmiş, _sadece_ `systemctl restart nginx` çalıştırabilecek şekilde kısıtladım — kimlik doğrulama isteminin ek bir güvenlik katmanı olarak korunmasını sağlarken, yetkisiz işlemleri (örn. `systemctl stop nginx`) başarıyla bloke ettim.
- **Kilometre Taşları & Çıktılar:**
  - 🔑 Rol-Bazlı Erişim Kontrolleri: [Kullanıcı Yönetimi & Sudoers Kısıtlamaları (EN](./04-User-Privilege-Management/readme-en.md) / [TR)](./04-User-Privilege-Management/readme.md)

### 🔹 19 Haziran 2026 | Genel Tekrar & Quiz Sonuçları

_Önceki tüm fazları kapsayan 20 soruluk quiz'i çözdüm. Cevapları, gerçekten öğrendiğime dayanarak verdim, sonradan değiştirmeden veya düzeltmeden — bu, gerçekten oturan bilgiyi teyit etmek içindi._

- **Görevler & Hedefler:**
  - Tamamlanan tüm altyapı modüllerindeki bilgi alanlarını, zorlu bir test fazı üzerinden bütünleştirdim.
  - Dosya akışları, sparse dosyalar, ve systemd kısıtlamalarını kapsayan senaryo bazlı sorular üzerinde çalıştım.
  - IaC, filtreleme pipeline'ları, ve sudoers kurallarını kapsayan 20 soruluk bir quiz çözdüm.
  - Hataları ve öğrenilen dersleri belgeledim (Vagrant provider kurulumu ve kernel versiyon flag'leri).
- **Kilometre Taşları & Çıktılar:**
  - 📝 Senaryo Çözümleri: [Doğrulanmış Production Senaryo Matrisleri](./challenges.md)
  - 📊 Quiz Sonuçları: [20 Soruluk Quiz Sonuçları](./quiz-results.md)

### 🔹 19 Haziran 2026 | Dosya İzinleri & Paylaşılan Dizin Güvenliği

_İzin sayıları (`755` veya `777` gibi) ilk başta bana mantıklı gelmedi — her basamağın gerçekte neyi temsil ettiğini anlayamadım. Farklı kombinasyonlarla deney yaptıktan sonra, her basamağın belirli bir sahip türü (kullanıcı/grup/diğerleri) için bir izin seviyesine (okuma/yazma/çalıştırma) karşılık geldiğini anladım. Bu netleştikten sonra, farklı komutlarla daha fazla test yaparak pekiştirdim._

- **Görevler & Hedefler:**
  - Standart Linux yetkilendirme haritalarını (`rwx`), sayısal maskeleme dönüşümlerini (`755` vs `644`), ve kullanıcı düzeni maskelerini (`umask`) analiz ettim.
  - Recursive dosya ağacı sahiplik geçişlerini otomatikleştirmek için varlık dağıtım komutlarını (`chown` ve `chgrp`) denetledim.
  - Özel **Sticky Bit** ayrıcalıklarıyla (`+t`) yapılandırılmış, paylaşılan bir test dizini (`/tmp/test`) kurdum.
  - Yetkisiz kullanıcıların, bağımsız operatör profilleri arasında başkalarının dosyalarını silemediğini başarıyla test ettim ve doğruladım, ortam bütünlüğünü koruyarak.
- **Kilometre Taşları & Çıktılar:**
  - 🔑 Güvenlik Sıkılaştırma Çalışma Alanı: [Depolama Diagnostiği & İzinler Matrisi (EN](./05-Linux-Permissions/readme-en.md) / [TR)](./05-Linux-Permissions/readme.md)
  - 📊 Doğrulama Diagnostiği: [Faz 5 Değerlendirme Analitiği](./05-Linux-Permissions/quiz-results.md)

### 🔹 19 Haziran 2026 | Linux Süreç Yönetimi

_`htop`'un varsayılan olarak kurulu olmadığını fark ettim ve önce kurulumda bir şey atladığımı düşündüm. Araştırdıktan sonra bunun normal olduğunu öğrendim — `htop` ayrıca kurulması gereken daha gelişmiş bir araç, `top` ise yerleşik geliyor. Her komutu farklı flag'lerle tekrar tekrar pratik ettim, gerçekten oturması için._

- **Görevler & Hedefler:**
  - Çalışan süreçleri kontrol etmek için `ps` ve `pidof`'u, gerçek zamanlı izleme için `top`'u kullandım.
  - Kaçak (runaway) bir süreç simüle ettim ve `SIGKILL -9` ile öldürdüm.
  - `top` ve `htop`'u karşılaştırdım.
  - `nice` ve `renice` ile CPU önceliği zamanlamasını pratik ettim.
- **Kilometre Taşları & Çıktılar:**
  - ⚙️ Süreç İşlemleri Çalışma Alanı: [Süreç Yönetimi Notları (EN](./06-Linux-Process-Management/readme-en.md) / [TR)](./06-Linux-Process-Management/readme.md)
  - 📊 Performans Değerlendirmesi: [Faz 6 Temiz Doğrulama Analitiği (%100 Skor)](./06-Linux-Process-Management/quiz-results.md)

### 🔹 19 Haziran 2026 | Servis Yönetimi & Loglama

_Rocky Linux'un `apt` kullanmadığını, bunun yerine `dnf`/`yum` kullandığını fark ettim. Nedenini araştırınca, bunun iki dağıtım ailesinin farklı kitleler için inşa edilmesinden kaynaklandığını öğrendim: Debian/Ubuntu (`apt`) genel/masaüstü kullanıma daha yakın, RHEL/Rocky (`dnf`) ise daha kurumsal ortamlar için inşa edilmiş. Aynı örüntü Nginx'in kendisinde de çıktı — Ubuntu kurulumdan sonra otomatik olarak etkinleştirip başlatıyor, Rocky ise varsayılan olarak devre dışı bırakıyor. Bu iki farkın da neden var olduğunu araştırmak (sadece komutları ezberlemek değil) bunun gerçekten oturmasını sağladı._

- **Görevler & Hedefler:**
  - Her iki dağıtıma da Nginx kurdum ve `dnf` ile `apt`'ı karşılaştırdım.
  - Ubuntu'nun otomatik-başlatma varsayılanını, Rocky Linux'un devre-dışı-varsayılan davranışıyla karşılaştırdım.
  - `enable` (reboot'lar arası kalıcı) ile `start` (şimdi çalıştırır)'ı karşılaştırdım.
  - Kesintisiz config değişiklikleri için `reload`'u, logları canlı takip etmek için `journalctl -u -f`'i kullandım.
- **Kilometre Taşları & Çıktılar:**
  - 🏗️ Servis Kontrol Çalışma Alanı: [Systemd Daemon Yaşam Döngüleri & Yapılandırmaları (EN](./07-Linux-Service-Management/readme-en.md) / [TR)](./07-Linux-Service-Management/readme.md)
  - 📊 Quiz Sonuçları: [Faz 7 Performans Değerlendirmesi (%100 Skor)](./07-Linux-Service-Management/quiz-results.md)

### 🔹 19 Haziran 2026 | Linux Log Analizi

_Ubuntu'nun localhost için IPv6 loopback adresini (`::1`) döndürmesini beklemiyordum — Rocky Linux bunun yerine bildiğimiz `127.0.0.1` (IPv4) döndürdü. Araştırınca, Ubuntu'nun genel/ev kullanımına daha yönelik olduğu için, modern networking stack'lerin beklendiği yerlerde varsayılan olarak IPv6 kullandığını öğrendim; Rocky ise kurumsal ortamlarda daha yaygın desteklendiği ve daha kararlı olduğu için IPv4'e bağlı kalıyor. Komutların kendisi ilk başta alışılmadık geldi, ama birkaç kez çalıştırdıktan sonra oturdu._

- **Görevler & Hedefler:**
  - Nginx log formatını ve hangi sütunların IP, path, ve durum koduna karşılık geldiğini öğrendim.
  - Ubuntu'da IPv6 loopback (`::1`) ile Rocky Linux'ta IPv4 (`127.0.0.1`)'i karşılaştırdım.
  - Ubuntu'nun minimal imajındaki eksik `curl`'u elle kurarak düzelttim.
  - En çok istek gönderen IP'leri bulmak ve 404 hatalarını path'e göre saymak için `grep`/`awk`/`sort`/`uniq` pipeline'ları kurdum.
- **Kilometre Taşları & Çıktılar:**
  - 🪵 Metin İşleme Çalışma Alanı: [Log Analizi Notları (EN](./08-Linux-Log-Analysis/readme-en.md) / [TR)](./08-Linux-Log-Analysis/readme.md)
  - 📊 Quiz Sonuçları: [Faz 8 Performans Değerlendirmesi (%100 Skor)](./08-Linux-Log-Analysis/quiz-results.md)

### 🔹 21 Haziran 2026 | Networking & TLS

_İlk kez bir TLS sertifikasını doğrudan inceledim — ilk başta tam olarak neye baktığımı anlamadım. Daha derine indikçe, sertifikanın kendisinin bir geçerlilik penceresi (yayın ve bitiş tarihleri) olduğunu, ve ayrıca TLS'in tekrarlanan bağlantılarda her seferinde tam handshake ve sertifika kontrolü yapmaması için session resumption kullandığını anladım — bu da aynı sunucuya sonraki bağlantıları hızlandıran şey._

- **Görevler & Hedefler:**
  - Yerel DNS cache'ini atlayıp çözümlemeyi doğrulamak için `dig @8.8.8.8`'i kullandım.
  - Hem IPv4 hem IPv6 üzerinden, bir portu hangi sürecin dinlediğini bulmak için `ss -lntp`'yi kullandım.
  - Bir sertifikanın trust chain'ini, issuer'ını, ve bitiş tarihini incelemek için `openssl s_client`'ı kullandım.
- **Kilometre Taşları & Çıktılar:**
  - 🌐 Networking Çalışma Alanı: [Network & TLS Notları (EN](./09-Linux-Network-Management/readme-en.md) / [TR)](./09-Linux-Network-Management/readme.md)
  - 📊 Quiz Sonuçları: [Faz 9 Quiz Sonuçları](./09-Linux-Network-Management/quiz-results.md)

### 🔹 22 Haziran 2026 | Depolama & LVM

_Bu faz gerçek bir hata içeriyordu: `dd` ile test ederken host makinenin diskini doldurdum ve VM'i tamamen kilitledim. Bundan kurtulmak — ve `fallocate`'e geçmek — planlanan alıştırmanın tek başına öğretebileceğinden daha fazlasını öğretti._

- **Görevler & Hedefler:**
  - `/etc/fstab`'da UUID kullanarak kalıcı mount'lar kurdum, ve reboot öncesi `mount -a` ile girişi doğruladım.
  - LVM kurdum: fiziksel volume'lar → volume group → mantıksal volume.
  - `dd` ile host diskini doldurmanın sebep olduğu bir VM dondurmasından kurtuldum, ve bunu önlemek için `fallocate`'e geçtim.
  - Bir mantıksal volume'u ve dosya sistemini, unmount etmeden, canlı olarak büyüttüm.
- **Kilometre Taşları & Çıktılar:**
  - 💾 Depolama Çalışma Alanı: [Depolama Yönetimi Notları (EN](./10-Linux-Storage-Management/readme-en.md) / [TR)](./10-Linux-Storage-Management/readme.md)
  - 🏗️ LVM Çalışma Alanı: [LVM Yönetimi Notları (EN](./11-Linux-LVM-Management/readme-en.md) / [TR)](./11-Linux-LVM-Management/readme.md)
  - 📊 Quiz Sonuçları: [Faz 10 Quiz Sonuçları](./10-Linux-Storage-Management/quiz-results.md) / [Faz 11 Quiz Sonuçları](./11-Linux-LVM-Management/quiz-results.md)

### 🔹 22 Haziran 2026 | SSH, SCP & SFTP

_Windows'ta `ssh-copy-id` mevcut değildi, bu yüzden aynı şeyi elle yapmam gerekti — public key'i `authorized_keys`'e kendim yapıştırdım ve izinleri elle ayarladım. Bu, komutu sadece çalıştırmak yerine, gerçekte ne yaptığını çok daha net hale getirdi. Şifre ile girişi kapattıktan sonra gerçek bir "Permission denied (publickey)" hatasıyla da karşılaştım, bunun sebebi Ubuntu VM için ayrı bir key'im olması ve SSH'ın varsayılan olarak yanlış olanı denemesiydi — doğru key dosyasına işaret etmek için `-i` kullanmam gerekti, ve sonra her seferinde yazmak zorunda kalmamak için bir SSH config dosyası kurdum. Bu süreçte, `#` işaretini kaldırana kadar sessizce hiçbir şey yapmayan, `sshd_config`'te yorum satırı olarak kalmış bir satırla da karşılaştım._

- **Görevler & Hedefler:**
  - Bir SSH key çifti (`ssh-keygen -t ed25519`) oluşturdum ve public key'i elle bir VM'in `authorized_keys`'ine ekledim (Windows'ta `ssh-copy-id` yok).
  - `.ssh` ve `authorized_keys` üzerinde doğru izinleri (`chmod 700`/`600`) ayarladım, ve SSH'ın bunu neden zorunlu kıldığını öğrendim.
  - Şifre kimlik doğrulamasını (`PasswordAuthentication no`) devre dışı bıraktım, ve kısıtlamayı hem key varken hem yokken test ederek doğruladım.
  - Yanlış key dosyası kullanmaktan kaynaklanan bir `Permission denied (publickey)` hatasını debug ettim, ve `-i` ile bir SSH config dosyasıyla düzelttim.
  - Host ve VM arasında `scp` ve `sftp` ile dosya transferi yaptım.
- **Kilometre Taşları & Çıktılar:**
  - 🔐 SSH Çalışma Alanı: [SSH, SCP & SFTP Notları (EN](./12-Linux-SSH-Management/readme-en.md) / [TR)](./12-Linux-SSH-Management/readme.md)
  - 📊 Quiz Sonuçları: [Faz 12 Quiz Sonuçları](./12-Linux-SSH-Management/quiz-results.md)

### 🔹 22 Haziran 2026 | Forward & Reverse Proxy

_Bu faz, tamamen pratik olmaktan çok ağırlıklı olarak kavramsaldı. Forward proxy'yi, senin adına bir isteği taşıyan bir kurye gibi anladım — karşı taraf sadece kuryeyi görür, seni görmez — ve reverse proxy'yi, bir şirketteki danışma görevlisi gibi: birini sorarsın, seni doğru yere yönlendirirler, ve binanın kalanıyla hiç doğrudan ilgilenmezsin. Gerçek bir Nginx reverse proxy'sini bir backend servise yönlendirerek kurmaya çalıştım, ama bir 502 Bad Gateway aldım. Backend ve Nginx'in farklı VM'lerde olduğu ve `proxy_pass`'imin `localhost`'a işaret ettiği ortaya çıktı — bu, sadece Nginx'in kendisinin çalıştığı makineyi işaret eder, backend'in gerçekte olduğu diğer VM'i değil. Bu oturumda çalışan kurulumu bitiremedim, ama tam olarak neden başarısız olduğunu anlamak gerçek kazanımdı._

- **Görevler & Hedefler:**
  - Forward proxy (client'ın önünde durur) ile reverse proxy (server'ın önünde durur) arasındaki farkı öğrendim.
  - Basit bir backend servisi ve `proxy_pass` kullanan bir Nginx reverse proxy'si kurdum.
  - `proxy_pass`'in backend VM'in gerçek IP'si yerine `localhost`'a işaret etmesinden kaynaklanan gerçek bir `502 Bad Gateway`'i tespit ettim ve diagnoz ettim.
  - Bir 502 hatasının tam olarak ne anlama geldiğini (proxy backend'e ulaşamadı) diğer hata kodlarına kıyasla öğrendim.
- **Kilometre Taşları & Çıktılar:**
  - 🔀 Proxy Çalışma Alanı: [Forward & Reverse Proxy Notları (EN](./13-Linux-Proxy-Management/readme-en.md) / [TR)](./13-Linux-Proxy-Management/readme.md)
  - 📊 Quiz Sonuçları: [Faz 13 Quiz Sonuçları](./13-Linux-Proxy-Management/quiz-results.md)

### 🔹 22 Haziran 2026 | Bash Scripting

_Disk kullanımı %80'i geçtiğinde uyarı veren bir script yazdım, bunu zaten bildiğim komutlardan bir araya getirerek — `df`, doğru satırı yakalamak için `awk 'NR==2'`, ve yüzde işaretini temizlemek için `cut -d'%' -f1`, sonra sonucu command substitution ile bir değişkende sakladım. Bu süreçte gerçek bir hatayla karşılaştım: `[48: command not found`, `[` ile `$usage` arasında bir boşluk eksikliğinden kaynaklanıyordu — Bash'in `[`'i aslında bir komut, çalışması için her iki tarafında da boşluk olması gerekiyor. Düzelttim, sonra script'in kullanım iyi olduğunda sessiz kalmak yerine her zaman bir şey yazdırması için bir `else` dalı ekledim. Bir loop veya function eklemedim, çünkü görev sadece tek bir kontrol gerektiriyordu — listedeki her konuyu "kullanmak" için zorla eklemek yerine, onları dışarıda bırakmak daha dürüst geldi._

- **Görevler & Hedefler:**
  - Disk kullanımını düz bir sayı olarak çıkarmak için `df`, `awk`, ve `cut`'ı birleştiren bir script yazdım.
  - Sonucu command substitution (`$(...)`) kullanarak bir değişkende sakladım.
  - %80 kullanımın üstünde bir uyarı, aksi halde bir "OK" mesajı yazdırmak için `-gt` ile bir `if`/`else` bloğu kullandım.
  - Koşul syntax'ındaki bir boşluk eksikliğinden kaynaklanan gerçek bir `[48: command not found` hatasını debug ettim.
  - Scripti `chmod +x` ile çalıştırılabilir yaptım ve `./script.sh` ile doğrudan çalıştırdım.
- **Kilometre Taşları & Çıktılar:**
  - 🐚 Bash Scripting Çalışma Alanı: [Bash Scripting Notları (EN](./14-Linux-Bash-Scripting/readme-en.md) / [TR)](./14-Linux-Bash-Scripting/readme.md)
  - 📊 Quiz Sonuçları: [Faz 14 Quiz Sonuçları](./14-Linux-Bash-Scripting/quiz-results.md)

### 🔹 22 Haziran 2026 | Cron & Otomasyon

_İki script yazdım — biri disk kullanım raporları için, biri Nginx loglarını arşivlemek için — ve ikisini de cron ile zamanladım. Disk raporu scripti hemen çalıştı, ama log arşivleme scripti, elle çalıştığı halde, cron üzerinden çalıştırıldığında gerçekte hiçbir şey yapmadan "başarılı" olmaya devam etti. Bunu bulmak biraz zaman aldı: `sudo`, şifre sormak için interaktif bir terminal gerektirir, ve cron'da cevap verecek kimse olmadığı için, script içindeki her `sudo` komutu sessizce başarısız oluyordu. Bu hata ilk başta görünmezdi çünkü cron, varsayılan olarak çıktısını e-posta ile göndermeye çalışır, ve hiçbir mail sistemi kurulu olmadığı için, o çıktı — gerçek hata dahil — sadece göz ardı ediliyordu. Gerçek hatayı, script'in çıktısını elle bir dosyaya yönlendirerek buldum. Ayrıca, script'in kendisinin `root`'a ait olduğu (bir noktada `sudo nano` ile açıldığından) ayrı bir sorunla da karşılaştım, bu `chown` ile sahipliği düzeltene kadar `chmod`'u bile engelliyordu. `sudo` sorununu, daha geniş bir erişim vermek yerine, gerçekten root gerektiren tek komut için dar kapsamlı bir `sudoers` kuralıyla çözdüm. Bu süreçte, Nginx'in gerçek kurulumlarda bu tam iş için varsayılan olarak kullandığı `logrotate`'e de baktım._

- **Görevler & Hedefler:**
  - Disk kullanım raporunu bir dosyaya yazmak için `disk_report.sh`'ı (Bash Scripting fazındaki mantığı yeniden kullanarak) yazdım.
  - Nginx'in `access.log`'unu `gzip -c` ile sıkıştırmak ve `truncate -s 0` ile sıfırlamak için `archive_logs.sh`'ı yazdım.
  - Sadece cron altında görünen, elle çalıştırmalarda görünmeyen bir `sudo: a password is required` hatasını diagnoz ettim.
  - Bir dosya sahiplik sorununu (`chown`) düzelttim ve gerektiren tek komut için dar kapsamlı bir `sudoers` NOPASSWD kuralı ekledim.
  - Her iki scripti de `crontab -e` ile her gece saat 02:00'de çalışacak şekilde zamanladım.
  - Bu tür log yönetimi için standart gerçek dünya aracı olan `logrotate`'e baktım.
- **Kilometre Taşları & Çıktılar:**
  - ⏰ Cron & Otomasyon Çalışma Alanı: [Cron & Otomasyon Notları (EN](./15-Linux-Cron-Automation/readme-en.md) / [TR)](./15-Linux-Cron-Automation/readme.md)
  - 📊 Quiz Sonuçları: [Faz 15 Quiz Sonuçları](./15-Linux-Cron-Automation/quiz-results.md)

### 🔹 23 Haziran 2026 | DevOps - Linux Temelleri (Udemy Kursu)

_Şirket laptop'unun VM çalıştırmaya veya normalde kullandığım araçlara izin vermemesi yüzünden bugün hands-on çalışma yapamadım. Doğrudan lab erişimi olmadan da ilerlemeye devam etmek için, günü Udemy'deki DevOps - Linux Temelleri kursunu tamamlamak için kullandım._

- **Görevler & Hedefler:**
  - Udemy'deki "DevOps - Linux Temelleri" kursunu tamamladım.
- **Kilometre Taşları & Çıktılar:**
  - 🎓 Kurs Tamamlama: DevOps - Linux Temelleri (Udemy)

### 🔹 23 Haziran 2026 | Docker & Networking Araştırması

_A'dan Z'ye Docker kursuna devam ettim (girişi bitirdim, şu an kurulum bölümündeyim), ve temel networking kavramları üzerine araştırma yaptım — internet, protokoller, uç sistemler, paket anahtarlama, gecikme, ve işlem hacmi. Ayrıca stajın başında verilen Linux yol haritasındaki mezuniyet/tekrar sorularını da çalıştım._

- **Görevler & Hedefler:**
  - Udemy'deki "A'dan Z'ye Docker" kursunun giriş bölümünü bitirdim, şu an kurulum bölümündeyim.
  - Networking temellerini araştırdım: internet, protokoller, uç sistemler, paket anahtarlama, gecikme, ve işlem hacmi.
  - Verilen Linux yol haritasındaki mezuniyet/tekrar sorularını çalıştım.
- **Kilometre Taşları & Çıktılar:**
  - 🐳 Devam ediyor: A'dan Z'ye Docker (Udemy)
  - 🌐 Networking temelleri araştırması (bu oturumda hands-on lab yok)

### 🔹 24 Haziran 2026 | Git — Branching, Merging, ve Gerçek Bir Push Çakışması

_`git branch` ve `git merge`'i doğrudan bu repo üzerinde test ettim — bir test branch'i oluşturdum, içine bir dosya commit ettim, `main`'in etkilenmediğini doğruladım, sonra geri merge ettim (temiz bir fast-forward). Sonrasında temizlik yaparken gerçek bir çakışmayla karşılaştım: `git push`, remote'da local'de henüz olmayan değişiklikler olduğu için reddedildi. Bunu düzeltmek için `git pull` çalıştırmak takıldı — merge bir commit mesajı gerektiriyordu, ve Git, o path'te gerçekte kurulu olmayan yapılandırılmış bir editörü (WebStorm) açmaya çalıştı, bu yüzden merge yarım kaldı. Notepad'i varsayılan editör olarak ayarlayarak (`git config --global core.editor "notepad"`) düzelttim, commit'i tamamladım, ve başarıyla push ettim. Ayrıca, quiz'i cevaplarken `git branch`'i (branch'leri listeler) bir branch oluşturmakla karıştırdım, gerçi hands-on kısmında komutun kendisini doğru kullanmıştım._

- **Görevler & Hedefler:**
  - Yeni bir branch oluşturdum ve geçtim (`git checkout -b`), içine bir dosya commit ettim, ve `main`'in dosyayı merge edilene kadar almadığını kontrol ederek branch izolasyonunu doğruladım.
  - Bir fast-forward merge (`git merge`) yaptım ve sonrasında test branch/dosyasını temizledim.
  - Senkronize olmamış remote değişikliklerden kaynaklanan gerçek bir `git push` reddini çözdüm.
  - Yanlış yapılandırılmış, var olmayan bir editör path'inden kaynaklanan takılı bir `git pull`/merge'i diagnoz ettim ve düzelttim.
  - Git'in varsayılan editörünü global olarak yeniden yapılandırdım (`git config --global core.editor`).
- **Kilometre Taşları & Çıktılar:**
  - 🔧 Git Çalışma Alanı: [Git Notları (EN](./16-Git-Basics/readme-en.md) / [TR)](./16-Git-Basics/readme.md)
  - 📊 Quiz Sonuçları: [Faz 16 Quiz Sonuçları](./16-Git-Basics/quiz-results.md)

### 🔹 24 Haziran 2026 | Genel Tekrar & Mini Proje (Gerçek Sunucu)

_Şu ana kadarki her şey üzerinde genel bir tekrar turu yaptım, yol haritasının gerçek mezuniyet kriterlerine modellenmiş senaryo tarzı sorular üzerinden geçerek (örn. "443 portunu kim dinliyor," "DNS çözümlemesi neden başarısız olur," "yeni bir disk nasıl eklenir") sadece notları yeniden okumak yerine. Sesli cevaplamak gerçek eksikleri ortaya çıkardı — journalctl'ı severity'ye göre filtrelemek için `-p err`'i unuttum, `tail -f`'i `tail -n` ile karıştırdım, `ss -l` ile `-a`'yı biraz yanlış aldım, yeni bir disk eklemeyi anlatırken partition adımını unuttum, ve LVM'in neden var olduğunu anlamanın komutları çalıştırmaktan daha önemli olduğunu tersine çevirdim. Storage, Service Management, Permissions, Log Analysis, Network, ve LVM notlarına geri dönüp gerçekte eksik olanı doldurdum — sadece yazım hataları değil, gerçek açıklama eksikleri (örn. `chmod` 4/2/1 dökümü bundan önce hiçbir yerde gerçekten açıklanmamıştı)._

_Sonra bu hafta satın alınan gerçek sunucuda mini projeyi yaptım — root olmayan, sudo yetkili bir kullanıcı oluşturdum, orijinal SSH fazındaki aynı şekilde SSH key erişimi kurdum, Nginx ve Docker'ı kurdum (`hello-world` ile doğruladım), Git'i kurdum ve tam olarak bu repoyu klonladım, ve ondan statik bir sayfa yayınladım. İki gerçek sorunla karşılaştım: klonlanan repo ile Nginx'in gerçekte sunduğu dosyanın ayrı kopyalar olduğunu unuttum, bu yüzden sadece `git pull`, dosya yeniden kopyalanana kadar canlı sayfayı güncellemedi; ve tarayıcıda bir "bağlantı reddedildi" aldım, bunun sebebi sadece port 80'in (HTTP) yapılandırılmış olmasına rağmen `https://` denemekti — Proxy fazındaki 502 ile aynı kategoride bir hata, sadece farklı bir katmanda._

- **Görevler & Hedefler:**
  - Süreçler, portlar, DNS, disk yönetimi, log analizi, SSH, cron, ve dosya izinlerini kapsayan senaryo bazlı tekrar sorularını cevapladım.
  - 6 faz için (Storage, Service Management, Permissions, Log Analysis, Network, LVM) notlardaki gerçek eksikleri belirledim ve düzelttim.
  - Gerçek bir kiralık sunucuda root olmayan, sudo yetkili bir kullanıcı ve SSH key bazlı erişim kurdum.
  - Sunucuda Nginx ve Docker'ı kurdum ve doğruladım.
  - Git'i kurdum, bu repoyu klonladım, ve Nginx üzerinden ondan statik bir sayfa yayınladım.
  - Eski bir deployment sorununu (kaynak dosya vs sunulan dosya) ve bir HTTPS-vs-HTTP bağlantı sorununu debug ettim.
- **Kilometre Taşları & Çıktılar:**
  - 📝 Derinleştirilmiş Notlar: [Depolama](./10-Linux-Storage-Management/readme.md) · [Servis Yönetimi](./07-Linux-Service-Management/readme.md) · [İzinler](./05-Linux-Permissions/readme.md) · [Log Analizi](./08-Linux-Log-Analysis/readme.md) · [Network](./09-Linux-Network-Management/readme.md) · [LVM](./11-Linux-LVM-Management/readme.md)
  - 🚀 Mini Proje: [Mini Proje Notları (EN](./17-Mini-Project/readme-en.md) / [TR)](./17-Mini-Project/readme.md)

### 🔹 26 Haziran 2026 | Path Bazlı Gruplama & OSI Modeli (Devam Ediyor)

_Eğitmenimin verdiği ek görevlerle devam ettim. Önce, bir Nginx access log'unda path bazlı IP gruplamayı (SQL'deki `GROUP BY` + `COUNT()`'a benzer bir mantıkla) gerçek sunucu trafiği üzerinde test ettim — her IP'nin tam olarak bir kez geçtiğini gördüm, ve bunun normal/şüphesiz trafiğin nasıl göründüğünü (yüksek tekrarlı bir IP'nin aksine) gösterdiğini öğrendim._

_Sonra OSI modeline başladım. 7 katmanı kavramsal olarak öğrendikten sonra, gerçek senaryolarla (`dig`, `curl https://`, `ssh`) hangi katmanların devrede olup olmadığını ayırt etmeyi pratik ettim — örneğin düz bir DNS sorgusunda Layer 6'nın (şifreleme) hiç devrede olmadığını, ama `https://` veya SSH'da olduğunu kendi kendime çıkardım. Layer 7'nin "hangi aracı kullandığın" değil "hangi protokolü konuştuğun" ile ilgili olduğunu fark ettim (PuTTY, terminal, veya FTP programı — hepsi sadece bir protokolü çalıştıran araçlar). Encapsulation kavramını (her katmanın veriyi kendi header'ıyla sarması) öğrendim, ve `tcpdump` ile gerçek bir paket yakalayıp, IP/port/HTTP metninin gerçekten aynı paketin içinde, katmanlı şekilde durduğunu kendi gözümle doğruladım. Encapsulation/decapsulation konusu henüz tam bitmedi, bu yüzden OSI fazını "devam ediyor" olarak işaretledim — yarım kalan bir temelin üzerine yeni konular eklemek yerine, dürüstçe nerede olduğumu not etmek daha doğru geldi._

- **Görevler & Hedefler:**
  - Bir Nginx access log'unda, `grep`/`awk`/`sort`/`uniq -c` ile path bazlı IP gruplamasını gerçek sunucu trafiğinde test ettim.
  - OSI modelinin 7 katmanını öğrendim, ve gerçek komutlarla (`dig`, `curl`, `ssh`) hangi katmanların devrede olduğunu ayırt etmeyi pratik ettim.
  - Layer 2 (MAC) ile Layer 3 (IP) arasındaki farkı ve neden ikisinin de gerekli olduğunu netleştirdim.
  - Encapsulation kavramını öğrendim, ve `tcpdump` kurup gerçek bir HTTP isteğini paket seviyesinde yakaladım.
  - OSI fazını, encapsulation/decapsulation tam bitmediği için "devam ediyor" olarak işaretledim.
- **Kilometre Taşları & Çıktılar:**
  - 🪵 Path Bazlı Gruplama: [Log Analizi Notları (EN](./08-Linux-Log-Analysis/readme-en.md) / [TR)](./08-Linux-Log-Analysis/readme.md) güncellendi
  - 🌐 OSI Modeli (Devam Ediyor): [OSI Modeli Notları (EN](./18-Linux-Networking-Fundamentals/readme-en.md) / [TR)](./18-Linux-Networking-Fundamentals/readme.md)

### 🔹 29 Haziran 2026 | OSI Tamamlama, Routing & Forwarding, DNS Sorgu Zinciri

_OSI modelini tamamen bitirdim: encapsulation/decapsulation'ı derinlemesine işledim, her router'da MAC header'ının değişip IP header'ının değişmediğini netleştirdim. ICMP protokolünü öğrendim, ve Cloudflare, Google, Claude.ai, ve kendi şirketimin (Türkiye Sigorta) web sitesine karşı gerçek bir `traceroute`/`ping` karşılaştırması yaparak, hangi kurumun ICMP trafiğine nasıl bir politika izlediğini gözlemledim — bu, önceki fazlarda öğrendiğim Least Privilege prensibinin ağ seviyesindeki bir yansımasıydı._

_Sonra routing ve forwarding konusuna geçtim. `ip route` ile gerçek routing tablomu inceledim, statik ve dinamik routing arasındaki farkı öğrendim. `ip_forward` ayarını kontrol ettiğimde beklenmedik şekilde aktif çıktı — önce sunucu sağlayıcıdan kaynaklandığını düşündüm, ama araştırınca bunun Docker'ın container'ların internete çıkabilmesi için gereken, tamamen normal bir davranış olduğunu öğrendim._

_Son olarak DNS sorgu zincirine başladım — recursive resolver, root sunucular, TLD sunucular, ve authoritative sunucular arasındaki hiyerarşiyi öğrendim, `dig +trace` ile bu sürecin gerçek zamanlı çıktısını gördüm (root sunuculardan `.com` TLD sunucularına kadar). Bu konu henüz tamamlanmadı, yarın devam edilecek._

- **Görevler & Hedefler:**
  - OSI modelinde encapsulation/decapsulation'ı tamamladım, router'ların MAC/IP header'larına ne yaptığını netleştirdim.
  - ICMP protokolünü öğrendim, gerçek bir `traceroute`/`ping` karşılaştırmasıyla farklı kurumların güvenlik politikalarını gözlemledim.
  - Routing ve forwarding kavramlarını, gerçek bir routing tablosu üzerinde öğrendim.
  - `ip_forward` ayarının neden aktif olduğunu araştırarak, Docker bağlantısını doğruladım.
  - DNS sorgu zincirine başladım, `dig +trace` ile gerçek bir çözümleme sürecini izledim.
- **Kilometre Taşları & Çıktılar:**
  - 🌐 OSI Modeli (Tamamlandı) & Routing/Forwarding: [Notlar (EN](./18-Linux-Networking-Fundamentals/readme-en.md) / [TR)](./18-Linux-Networking-Fundamentals/readme.md)

### 🔹 30 Haziran 2026 | DNS Kayıt Tipleri, TTL, ve Cloud Outage Araştırması

_DNS'in kalan kısmını tamamladım. Önce, dünkü `dig +trace` çıktısını satır satır analiz ettim — root sunuculardan TLD'ye, oradan authoritative sunucuya kadar olan zinciri, kendi telefon rehberi benzetmemle ("birine soruyorum, o da bilmiyor ama bilen birini biliyor" zinciri) anladım. Her seviyede 13 (veya 4) yedek sunucu olduğunu, ama sadece birinin gerçekten sorgulandığını fark ettim — bu, IPv6 zaman aşımı yaşanan gerçek bir örnekte (otomatik olarak IPv4'e geçiş) doğrulandı._

_TTL'i, aynı sorguyu art arda iki kere çalıştırarak test ettim — TTL'in gerçekten azaldığını (141 → 139) ve ikinci sorgunun anında (0ms) geldiğini gördüm, cache'in nasıl çalıştığını somut olarak kanıtladım. Negative caching'i de (`NXDOMAIN`) test ettim, var olmayan bir domain için bile bir TTL olduğunu öğrendim._

_Sonra 8 DNS kayıt tipinin (A, AAAA, CNAME, MX, TXT, NS, SRV, PTR) hepsini, gerçek domain'ler üzerinde tek tek sorguladım. Kendi domain'im olsaydı (alifurkan.com) bunları nasıl kullanacağımı somut bir senaryo üzerinden düşündüm. Türkiye Sigorta'nın 3 farklı mail sunucusu (failover için) olduğunu, Azure DNS kullandığını; Google'ın bazı alt domain'lerde CNAME yerine doğrudan çoklu A kaydı kullandığını; Cloudflare ve Google'ın kendi IP'lerine bilinçli olarak PTR kaydı atadığını (one.one.one.one, dns.google) kendi başıma keşfettim ve doğruladım._

_Son olarak, AWS, Cloudflare, ve Google Cloud'un gerçek, yakın tarihli kesintilerini araştırdım — AWS'nin DynamoDB'sinde bir DNS kaydının otomasyon hatasıyla tamamen silinmesi, Cloudflare'in DNSSEC imzalarının süresinin dolmasıyla yaşadığı kesinti, ve Google'ın (DNS değil, yetkilendirme kaynaklı) kesintisini karşılaştırarak, "her büyük kesinti DNS değildir" ayrımını da net bir şekilde gördüm. Bunu ayrı, kaynakçalı bir belgeye yazdım._

- **Görevler & Hedefler:**
  - `dig +trace` çıktısını detaylı analiz ettim, resolver zincirinin (root → TLD → authoritative) her adımını kavradım.
  - TTL'in gerçekten azaldığını ve cache'in çalıştığını, art arda iki sorguyla kanıtladım.
  - Negative caching'i (`NXDOMAIN`) test ettim.
  - 8 DNS kayıt tipini (A, AAAA, CNAME, MX, TXT, NS, SRV, PTR), gerçek domain'ler üzerinde sorgulayarak öğrendim.
  - `nslookup`, `host`, `resolvectl` debug araçlarını test ettim.
  - AWS, Cloudflare, ve Google Cloud'un gerçek DNS-ilişkili kesintilerini araştırdım, kaynakçalı bir belge oluşturdum.
- **Kilometre Taşları & Çıktılar:**
  - 🌐 DNS (Tamamlandı): [Networking Notları (EN](./18-Linux-Networking-Fundamentals/readme-en.md) / [TR)](./18-Linux-Networking-Fundamentals/readme.md)
  - 🔥 Cloud Outage Araştırması: [Notlar (EN](./18-Linux-Networking-Fundamentals/dns-outages-EN.md) / [TR)](./18-Linux-Networking-Fundamentals/dns-outages-TR.md)

### 🔹 1 Temmuz 2026 | Nginx Derinleşme — Reverse Proxy, Path Yönetimi, Forward Proxy

_Nginx derinleşme fazını tamamladım. Python'un yerleşik HTTP sunucusunu backend olarak kullanarak Nginx'i önüne koydum — gelen isteklerin artık backend logunda `127.0.0.1`'den (Nginx'ten) geldiğini görerek reverse proxy'nin gerçekten çalıştığını doğruladım. Sonra aynı Nginx üzerinden path bazlı yönlendirme kurdum: `/users/` → port 3000, `/computers/` → port 4000. Path rewrite'ı (`proxy_pass`'teki sondaki `/` farkı) test ederken, slash olmadan 404 aldım, ekleyince 200 — "klasörün içine gir" mantığını bu şekilde kavradım. Path engelleme kısmında `return 403` ile `deny all`'ı birlikte kullanınca localhost da engellenmeye başladı, `return 403`'ü kaldırınca düzeldi — bu gerçek bir hataydı, belgeye de girdi._

_Forward proxy için Squid kurdum. Windows'ta sistem proxy olarak `<SERVER_IP>:3128` ayarladım, tarayıcıdan `ifconfig.me`'ye girince kendi IP'm yerine sunucunun IP'si göründü. Squid logunda Windows'tan çıkan tüm trafiği (`claude.ai`, `apple.com`, `windows.com` dahil) gördüm — proxy'nin gerçekten çalıştığını ve bütün verinin internete çıkarken Squid üzerinden geçtiğini doğrudan gözlemledim._

- **Görevler & Hedefler:**
  - Nginx'i reverse proxy olarak yapılandırdım, backend logundan doğruladım.
  - Path bazlı yönlendirme kurdum (3 farklı servis, 3 farklı port).
  - Path rewrite'ı (trailing slash farkı) test ederek öğrendim.
  - Path engellemeyi (`allow`/`deny`) iç/dış ağ ayrımıyla uyguladım.
  - Squid ile forward proxy kurup, Windows trafiğinin tamamının proxy'den geçtiğini logda doğruladım.
- **Kilometre Taşları & Çıktılar:**
  - 🌐 Nginx Derinleşme: [Notlar (EN](./19-Nginx-Derinleşme/readme-en.md) / [TR)](./19-Nginx-Derinleşme/readme.md)

### 🔹 2 Temmuz 2026 | Nginx Test Senaryoları & Belge Güncellemeleri

_Nginx config'ini 20 farklı senaryodan geçirdim — routing, path engelleme, rewrite, hata durumları. 19 tanesi beklediğim gibi geldi, bir tanesi gelmedi: `curl http://localhost/admin` deyince 403 aldım, oysa config'de `allow 127.0.0.1` vardı ve izin vermesi gerekiyordu. Önceki Linux eğitimlerinden Ubuntu'nun IPv6'yı tercih ettiğini hatırladım, ama bunu test etmem lazımdı. `curl -v` ile baktım — Ubuntu `localhost`'u `::1` (IPv6) olarak çözümlüyordu, `127.0.0.1` (IPv4) olarak değil. Nginx bu iki adresi ayrı ayrı değerlendiriyor, bu yüzden `allow 127.0.0.1` yetmiyordu. Config'e `allow ::1` ekledim, düzeldi. Sonra `127.0.0.1` ile direkt de test ettim — o da çalıştı, çünkü IPv4 üzerinden gidiyor. İkisini birden yazmanın doğru yaklaşım olduğunu kanıtlamış oldum._

_Aynı zamanda önceki fazların (03–19) Türkçe/İngilizce belge dönüşümünü tamamladım. Nginx README'sinde de IPv6 meselesini ve doğru test sonuçlarını güncelledim._

- **Görevler & Hedefler:**
  - 20 test senaryosu yazıp gerçek sunucuda denedim.
  - TC-11'de IPv6/IPv4 çakışmasını keşfettim, `allow ::1` ekleyerek çözdüm.
  - Nginx README (TR + EN) güncellendi — `allow ::1`, açıklama, test sonuçları.
  - test-cases.md ve test-cases-EN.md oluşturuldu.
  - 03–19 arası tüm fazların bilingual belge dönüşümü tamamlandı.
- **Kilometre Taşları & Çıktılar:**
  - 🧪 Test Senaryoları: [TR](./19-Nginx-Derinleşme/test-cases.md) / [EN](./19-Nginx-Derinleşme/test-cases-en.md)
  - 🌐 Nginx Derinleşme: [README (TR](./19-Nginx-Derinleşme/readme.md) / [EN)](./19-Nginx-Derinleşme/readme-en.md)

### 🔹 3 Temmuz 2026 | Rate Limiting & Load Balancing

_Rate limiting için `limit_req_zone` ile zone tanımlayıp tüm location'lara uyguladım — 20 istek attığımda ilk 12'si geçti, sonrası 503 döndü. Load balancing için users servisi için ikinci bir instance açıp `upstream` bloğu tanımladım. Round-robin çalıştı, sonra Instance 1'i kapattım — Nginx otomatik olarak Instance 2'ye geçti, hiç kesinti olmadı. Instance 1 geri gelince round-robin'e döndü. `least_conn` ve `ip_hash` yöntemlerini de araştırdım — bu fazda kullanmadım ama ne zaman gerektiğini anladım._

- **Görevler & Hedefler:**
  - Rate limiting kurdum ve test ettim (`limit_req_zone`, `burst`, `nodelay`).
  - Load balancing kurdum — round-robin, failover, ve dışarıdan test.
  - `least_conn` ve `ip_hash` yöntemlerini araştırdım.
- **Kilometre Taşları & Çıktılar:**
  - 🚦 Rate Limiting & Load Balancing: [README (TR](./20-Rate-Limiting-Load-Balancing/README.md) / [EN)](./20-Rate-Limiting-Load-Balancing/README-EN.md)

---

ℹ️ _Not: Burada belgelenen her şey, hem yerel sandboxed VM'lerde hem de gerçek bir kiralık sunucuda yerel olarak test edilmiştir._
