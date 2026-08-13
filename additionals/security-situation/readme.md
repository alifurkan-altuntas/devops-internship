# 🚨 Gerçek Bir Güvenlik Olayı — DNS Rebinding ve Açık Forward Proxy (SSRF)

Docker İleri Örnekler fazına devam ederken sunucumda disk %100 dolup admin paneline giremedim. Sorunu araştırırken, 1 Temmuz'daki forward proxy denememizden (Faz 19) kalan bir yapılandırmanın, bir saldırgan tarafından haftalardır kötüye kullanıldığını keşfettim.

---

## Nasıl Fark Ettim

`mkdir` komutu bile "No space left on device" hatası verdi. `df -h /` ile disk kullanımını kontrol ettim: `/dev/sda2 40G 38G 0 100% /`.

```bash
docker system df
```

Docker'ın kendisi sadece ~6.5GB tutuyordu, sorun orada değildi. `du -h --max-depth=1 /` ile katman katman derine indim:

```
/var         27G
  /var/log   21G
    /var/log/nginx   20G
```

`ls -lh /var/log/nginx/` çıktısında `access.log.1` **9.2GB**, `error.log.1` **4.5GB** — tek bir günde oluşmuş.

---

## Ne Buldum

```bash
sudo tail -50 /var/log/nginx/error.log
```

Saniyede yüzlerce satır, hepsi aynı isteği tekrarlıyordu:

```
2026/08/13 10:49:13 [error] ... limiting requests ... request: "GET /M?N=ZZJ26070054541&QO=4440 HTTP/1.0", host: "www.zzjjyzx.com:80", referrer: "https://www.youtube.com/"
```

`www.zzjjyzx.com` rastgele/anlamsız bir domain — klasik tıklama sahteciliği (click-fraud) botnet paterni. İstekler hem `127.0.0.1`'den (sunucunun kendisinden) hem dış bir IP'den (`134.195.157.224`) geliyordu.

---

## Kök Sebep — Adım Adım Ortaya Çıkış

**İlk şüphe:** `default` server bloğundaki eski `proxy_pass http://localhost:8080;` — düzelttim (`return 444;`), ama trafik durmadı.

**İkinci ipucu:** `error.log`'da `upstream: "http://127.0.0.1:80/..."` — nginx kendi kendine, port 80'e istek atıyordu. `default` bloğu artık bunu yapmıyordu, demek ki başka bir yerden geliyordu.

**Kanıt:**

```bash
dig +short www.zzjjyzx.com
# 127.0.0.1
```

Saldırganın domaini **kasıtlı olarak `127.0.0.1`'e** çözümlenecek şekilde ayarlanmıştı (DNS rebinding).

```bash
sudo ss -tlnp | grep 8888
# LISTEN 0 511 0.0.0.0:8888 ... nginx
```

`forward-proxy.conf` (1 Temmuz'daki Squid alternatifi denememiz, port 8888) hâlâ **tüm internete açık** duruyordu, `ufw` kapalıydı, hiçbir kısıtlama yoktu:

```nginx
server {
    listen 8888;
    resolver 8.8.8.8;
    location / {
        proxy_pass http://$http_host$request_uri;
    }
}
```

**Saldırı akışı:**

1. Saldırgan port 8888'e (bizim açık forward proxy'miz) bağlanıyor
2. `Host: www.zzjjyzx.com` header'ıyla istek atıyor
3. Bu domain DNS'te `127.0.0.1`'e işaret ediyor
4. `proxy_pass http://$http_host$request_uri;` sunucunun **kendi kendine** istek atmasına neden oluyor
5. Sunucumuz, botun trafiğini "meşru" gösteren bir röle/açık proxy gibi kullanılıyor — ve bu döngü, logları doldurup diski bitiriyor

---

## Çözüm

```bash
sudo rm /etc/nginx/sites-enabled/forward-proxy.conf
sudo nginx -t && sudo systemctl reload nginx
sudo gzip /var/log/nginx/access.log.1
sudo gzip /var/log/nginx/error.log.1
```

D�rt dakika sonra log tamamen durdu, disk %68'e (13GB boş) düştü.

---

## Alınan Dersler

1. **Öğrenme amaçlı kurulan bir servis, "sadece test ettim" diye güvenli kalmıyor** — `forward-proxy.conf`'u kapatmayı unutmuştuk, haftalarca canlıda, tüm internete açık kaldı.
2. **DNS rebinding gerçek bir tehdit** — bir domainin `127.0.0.1`'e işaret etmesini kimse engellemiyor, DNS bunu kontrol etmiyor.
3. **`return 444;` gibi bir düzeltme, sorunun tamamını çözmeyebilir** — birden fazla server bloğu/config dosyası varsa, hepsini kontrol etmek gerekiyor.
4. **`docker system df` küçük çıkması, disk sorununun Docker'la ilgili olmadığı anlamına gelmiyor** — asıl kaynağı bulmak için katman katman (`/`, `/var`, `/var/log`, `/var/log/nginx`) inmek gerekti.

---

ℹ️ _Bu olay gerçek bir Ubuntu VPS'te, gerçek zamanlı yaşanmış ve çözülmüştür._
