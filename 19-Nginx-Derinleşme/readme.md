# 🌐 Nginx Derinleşme — Reverse Proxy, Path Yönetimi, ve Forward Proxy

✅ **Durum: Tamamlandı.** Reverse proxy kurulumu, path bazlı yönlendirme, path rewrite, path engelleme, ve forward proxy (Squid) — hepsi gerçek bir sunucuda uygulamalı olarak test edildi.

---

## 1. Reverse Proxy Nedir

Nginx, bir **reverse proxy** olarak, dışarıdan gelen istekleri alıp arka plandaki servislere iletir. Kullanıcı, arka planda kaç servis olduğunu, hangi portlarda çalıştığını bilmez — sadece Nginx ile muhatap olur.

**Neden kullanılır:**

- Backend servislerin port/IP bilgisi dışarıya çıkmaz böylece gizlilik sağlanır
- Tek bir giriş noktası (port 80/443) üzerinden birden fazla servis yönetilir
- Load balancing, SSL sonlandırma, rate limiting Nginx'te yapılır, backend'e yük binmez

**Örnek:** Büyük bir şirkete giriyorsunuz. Direkt ofislere gidemiyorsunuz — danışma görevlisi (Nginx) soruyor: "Kime gidiyordunuz?" O, hangi ofisin nerede olduğunu biliyor, sizi doğru yere yönlendiriyor. Binanın iç yapısını (kaç kat, hangi oda) hiç bilmiyorsunuz. Eğer o ofis o gün kapalıysa danışma "ulaşamıyorum" diyor — bu tam olarak **502 Bad Gateway.**

### 502 Bad Gateway ile Karşılaşınca

502 gördüğünde şu sırayla bakılır:

1. İnternet bağlantısı çalışıyor mu?
2. Backend servisi (arkadaki uygulama) çalışıyor mu?

Danışma görevlisi orada ama bağlamak istediği ofis kapalıysa, bu 502'dir — Nginx çalışıyor, ama arkasındaki servis çalışmıyor.

---

## 2. Temel Reverse Proxy Kurulumu

### Ortam

Backend servisi simüle etmek için Python'un yerleşik HTTP sunucusu kullanıldı:

```bash
mkdir -p /tmp/backend
echo "<h1>Backend Servisi Çalışıyor - Port 8080</h1>" > /tmp/backend/index.html
cd /tmp/backend && python3 -m http.server 8080 &
```

### Nginx Yapılandırması

```nginx
location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### Direktiflerin Anlamı

**`proxy_pass http://localhost:8080`** — gelen isteği 8080 portuna ilet.

**`proxy_set_header Host $host`** — iletirken, isteğin hangi domain'e geldiğini de söyle. Bir Nginx arkasında birden fazla domain olabilir; backend "bu istek bana mı, yoksa yan servise mi geldi" diye bilmek ister.

**`proxy_set_header X-Real-IP $remote_addr`** — iletirken, kullanıcının gerçek IP'sini de söyle.

**Örnek (X-Real-IP olmadan):** Danışma görevlisi sizi ofise götürüyor, ama ofisteki kişi "bu kim, nereden geldi" bilmiyor — çünkü danışma sadece "biri geldi" dedi, kimin geldiğini söylemedi. `X-Real-IP` olmadan backend, her isteğin `127.0.0.1`'den (Nginx'ten) geldiğini sanır, gerçek kullanıcıyı hiç görmez.

### Doğrulama

```bash
sudo nginx -t && sudo systemctl reload nginx
```

Dışarıdan (Windows'tan) port 80'e istek:

```
PS C:\> curl http://<SERVER_IP>
<h1>Backend Servisi Çalışıyor - Port 8080</h1>
```

Kullanıcı 8080'i hiç görmedi — sadece port 80'e gitti, Nginx arkada halletti.

Backend logunda isteklerin artık `127.0.0.1`'den (Nginx'ten) geldiği görüldü, kullanıcının IP'sinden değil:

```
127.0.0.1 - - [01/Jul/2026 08:54:05] "GET / HTTP/1.0" 200 -
127.0.0.1 - - [01/Jul/2026 08:54:17] "GET / HTTP/1.0" 200 -
```

---

## 3. Path Bazlı Yönlendirme

Aynı Nginx üzerinden, farklı path'lere gelen istekler farklı backend servislerine yönlendirildi.

### Ortam

İki servis daha başlatıldı:

```bash
mkdir -p /tmp/users && echo "<h1>Users Servisi</h1>" > /tmp/users/index.html
cd /tmp/users && python3 -m http.server 3000 &

mkdir -p /tmp/computers && echo "<h1>Computers Servisi</h1>" > /tmp/computers/index.html
cd /tmp/computers && python3 -m http.server 4000 &
```

### Nginx Yapılandırması

```nginx
location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}

location /users/ {
    proxy_pass http://localhost:3000/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}

location /computers/ {
    proxy_pass http://localhost:4000/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### Test Sonuçları

```
PS C:\> curl http://<SERVER_IP>/
<h1>Backend Servisi Çalışıyor - Port 8080</h1>

PS C:\> curl http://<SERVER_IP>/users/
<h1>Users Servisi</h1>

PS C:\> curl http://<SERVER_IP>/computers/
<h1>Computers Servisi</h1>
```

Danışma görevlisi artık farklı talepleri farklı ofislere yönlendiriyor — `/users/` diyeni 3. kata (3000), `/computers/` diyeni 4. kata (4000) gönderiyor.

---

## 4. Path Rewrite

`proxy_pass` direktifinde sondaki `/` karakteri, path rewrite'ı belirler.

### Fark

```
proxy_pass http://localhost:3000    →  /users/liste  →  localhost:3000/users/liste  (404)
proxy_pass http://localhost:3000/   →  /users/liste  →  localhost:3000/liste        (200)
```

**Örnek:** Eğer sonda `/` olmazsa, sistem "o klasörün içine gir" olarak almıyor — yani `/users/` prefix'ini soymuyor, backend'e olduğu gibi gönderiyor. Backend `/users/liste` diye bir şey tanımıyor, 404 veriyor. Sonda `/` olduğunda ise Nginx prefix'i soyuyor, backend'e sadece `/liste` gönderiyor — backend bunu anlıyor, 200 veriyor.

### 301 Davranışı

`/users` (trailing slash olmadan) yazılınca Nginx otomatik olarak `/users/`'a yönlendiriyor (301 Moved Permanently). `curl -L` ile redirect takip edilebilir:

```bash
curl -L http://<SERVER_IP>/users
# <h1>Users Servisi</h1>
```

---

## 5. Path Engelleme

### Herkesi Engelleme

```nginx
location /admin {
    deny all;
}
```

`deny all` zaten 403 döndürür — ayrıca `return 403` yazmak gereksiz ve bazen çakışmaya sebep olur (test sırasında bizzat karşılaşıldı: `return 403` eklenince localhost da engellenmeye başladı, kaldırınca düzeldi).

### Sadece Dışarıyı Engelleme (Gerçek Dünya Kullanımı)

```nginx
location /admin {
    allow 127.0.0.1;
    allow ::1;
    deny all;
}
```

Nginx kuralları **yukarıdan aşağıya** okur, ilk eşleşmede durur:

1. `127.0.0.1`'den mi geliyor? → Geç
2. `::1`'den mi geliyor? → Geç
3. Başka biri? → 403

**Neden `allow ::1` de gerekiyor?** `allow 127.0.0.1` teknik olarak doğru — ama Ubuntu gibi bazı sistemlerde `localhost` yazıldığında sistem bunu IPv4 (`127.0.0.1`) değil, IPv6 adresi olan `::1` olarak çözümler. Nginx bu iki adresi farklı şeyler olarak görür. Bu, test sırasında doğrudan gözlemlendi:

```bash
curl -v http://localhost/admin 2>&1 | grep "Connected"
# * Connected to localhost (::1) port 80
```

`localhost` yazılınca istek `::1`'den geliyordu. Config'de sadece `allow 127.0.0.1` varken bu istek izin listesinde bulunamadı ve `deny all`'a düştü — 403. `allow ::1` eklenince düzeldi.

Fakat `127.0.0.1` direkt yazılınca IPv4 üzerinden gidiyor ve `allow 127.0.0.1` yeterli oluyor:

```bash
curl -v http://127.0.0.1/admin 2>&1 | grep "Connected"
# * Connected to 127.0.0.1 (127.0.0.1) port 80
```

Taşınabilir ve güvenli bir config için her iki adresi de yazmak gerekir.

**Örnek:** Odanın önüne bir güvenlik görevlisi koydunuz. Talimat: "Sadece içeriden (localhost) gelenleri al, dışarıdan gelenleri geri çevir." Ama localhost'un iki kapısı var — biri IPv4, biri IPv6. İkisini de izin listesine eklemezsen, birinden gelen içerideki kişiyi dışarıdan zannedip geri çeviriyorsun.

### Test Sonuçları

```bash
# İçeriden — localhost (IPv6 üzerinden)
curl http://localhost/admin
# → 404 Not Found (izin verildi, backend'e gitti, /admin diye dosya yok)

# İçeriden — direkt IPv4
curl http://127.0.0.1/admin
# → 404 Not Found (izin verildi, backend'e gitti, /admin diye dosya yok)
```

```
# Dışarıdan (Windows)
PS C:\> curl http://<SERVER_IP>/admin
<html><head><title>403 Forbidden</title></head>
<body><center><h1>403 Forbidden</h1></center></body></html>
```

---

## 6. Forward Proxy (Squid)

Nginx, reverse proxy için tasarlanmıştır. Forward proxy için **Squid** kullanıldı.

### Fark

|                    | Reverse Proxy (Nginx) | Forward Proxy (Squid)           |
| ------------------ | --------------------- | ------------------------------- |
| **Kim gizleniyor** | Backend sunucu        | İstemci (kullanıcı)             |
| **Nerede duruyor** | Sunucu tarafında      | İstemci tarafında               |
| **Kullanım**       | Web siteleri, API'ler | Kurumsal internet kontrolü, VPN |
| **Benzetme**       | Danışma görevlisi     | Turnike                         |

**Örnek (Forward Proxy):** Şirketteki turnike gibi — çalışanlar dışarıya çıkarken turnike'den geçiyor. Dışarıdaki siteler çalışanın kim olduğunu değil, **şirketin IP'sini** görüyor. Şirket ise kimin nereye gittiğini kontrol edip loglayabiliyor.

### Kurulum ve Test

```bash
sudo apt install squid -y
# port 3128'de çalışıyor
```

`/etc/squid/squid.conf`'a eklendi (test için):

```
http_access allow all
```

Windows sistem proxy ayarı: `<SERVER_IP>:3128`

Tarayıcıdan `ifconfig.me`'ye girilince **Squid'in IP'si** (`<SERVER_IP>`) göründü — gerçek Windows IP'si (`37.154.226.48`) değil.

Squid logunda Windows'un **tüm trafiğinin** Squid'den geçtiği görüldü:

```
37.154.226.48 TCP_TUNNEL/200 CONNECT claude.ai:443
37.154.226.48 TCP_TUNNEL/200 CONNECT amp-api.music.apple.com:443
37.154.226.48 TCP_TUNNEL/200 CONNECT activity.windows.com:443
37.154.226.48 TCP_TUNNEL/200 CONNECT dc1.ksn.kaspersky-labs.com:443
```

Bu log, proxy'nin çalıştığını ve **bütün verinin internete çıkarken proxy server üzerinden geçtiğini** doğrudan gösterdi — `claude.ai` dahil, bu konuşmanın trafiği bile Squid'den geçti.

Test bittikten sonra `http_access allow all` kaldırıldı, Windows proxy ayarı kapatıldı.

---

## 📊 Hızlı Referans

| Direktif                                  | Görevi                                     |
| ----------------------------------------- | ------------------------------------------ |
| `proxy_pass http://host:port`             | İsteği belirtilen backend'e ilet           |
| `proxy_pass http://host:port/`            | İsteği ilet, path prefix'ini soy (rewrite) |
| `proxy_set_header Host $host`             | Orijinal domain bilgisini backend'e ilet   |
| `proxy_set_header X-Real-IP $remote_addr` | Kullanıcının gerçek IP'sini backend'e ilet |
| `deny all`                                | Tüm istekleri engelle (403)                |
| `allow 127.0.0.1` / `allow ::1`           | Localhost'a izin ver (IPv4 ve IPv6)        |
| `location /path/`                         | Belirli bir path için kural tanımla        |

---

ℹ️ _Tüm testler gerçek bir Ubuntu VDS üzerinde (`<SERVER_IP>`) yapılmıştır. Backend servisler olarak Python'un yerleşik HTTP sunucusu kullanılmıştır._
