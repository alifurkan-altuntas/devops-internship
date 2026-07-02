# 🧪 Nginx Test Senaryoları

Nginx config'ini yazdıktan sonra 20 farklı senaryodan geçirdim — routing, path engelleme, rewrite, hata durumları. Bir tanesi beklediğim sonucu vermedi ve en çok o testten bir şey öğrendim.

---

## Ortam

```
Sunucu: <SERVER_IP> (Ubuntu 24.04)
Nginx: 1.24.0

Backend servisleri:
  /           → python3 -m http.server 8080 (/tmp/backend/)
  /users/     → python3 -m http.server 3000 (/tmp/users/)
  /computers/ → python3 -m http.server 4000 (/tmp/computers/)
  /admin      → içeriden izin var, dışarıdan engelli
```

---

## TC-01 — Kök Path, İçeriden

```bash
curl http://localhost/
```

Nginx'in 8080'deki backend'e yönlendirip yönlendirmediğini gördüm.

**Beklenen:** Backend cevabı
**Sonuç:** ✅ `<h1> Backend servisi çalışıyor - port 8080</h1>`

---

## TC-02 — Kök Path, Dışarıdan

```bash
curl http://<SERVER_IP>/
```

Kullanıcı port 80'e gidiyor, 8080'den haberi olmuyor.

**Beklenen:** Backend cevabı (8080 portu görünmeden)
**Sonuç:** ✅ `<h1> Backend servisi çalışıyor - port 8080</h1>`

---

## TC-03 — /users/ Yönlendirmesi, İçeriden

```bash
curl http://localhost/users/
```

**Beklenen:** Port 3000'den cevap
**Sonuç:** ✅ `<h1>Users servisi</h1>`

---

## TC-04 — /computers/ Yönlendirmesi, İçeriden

```bash
curl http://localhost/computers/
```

**Beklenen:** Port 4000'den cevap
**Sonuç:** ✅ `<h1>Computers Servisi</h1>`

---

## TC-05 — /users/ Yönlendirmesi, Dışarıdan

```bash
curl http://<SERVER_IP>/users/
```

**Beklenen:** Port 3000'den cevap
**Sonuç:** ✅ `<h1>Users servisi</h1>`

---

## TC-06 — /computers/ Yönlendirmesi, Dışarıdan

```bash
curl http://<SERVER_IP>/computers/
```

**Beklenen:** Port 4000'den cevap
**Sonuç:** ✅ `<h1>Computers Servisi</h1>`

---

## TC-07 — Trailing Slash Olmadan: /users

```bash
curl http://localhost/users
```

`/users/` olarak tanımlı — slash olmadan gelince Nginx otomatik yönlendiriyor.

**Beklenen:** 301 Moved Permanently
**Sonuç:** ✅ `301 Moved Permanently`

---

## TC-08 — Trailing Slash Olmadan: Redirect Takibi

```bash
curl -L http://localhost/users
```

`-L` ile 301'i takip ettim.

**Beklenen:** Users servisi cevabı
**Sonuç:** ✅ `<h1>Users servisi</h1>`

---

## TC-09 — Trailing Slash Olmadan: /computers

```bash
curl http://localhost/computers
```

**Beklenen:** 301 Moved Permanently
**Sonuç:** ✅ `301 Moved Permanently`

---

## TC-10 — /computers Redirect Takibi

```bash
curl -L http://localhost/computers
```

**Beklenen:** Computers servisi cevabı
**Sonuç:** ✅ `<h1>Computers Servisi</h1>`

---

## TC-11 — /admin İçeriden ⚠️

```bash
curl http://localhost/admin
```

Bu testi yaparken sonuç beklediğim gibi gelmedi. Config'de `allow 127.0.0.1` vardı, çalışması gerekiyordu — ama 403 geldi. Nerede hata olduğunu çözmeye çalıştım.

Önceki Linux eğitimlerinden Ubuntu'nun IPv6'yı tercih ettiğini hatırladım. Ama bunu yine de test etmem lazımdı — Ubuntu'nun localhost'a hangi IP ile bağlandığını görmem gerekiyordu:

```bash
curl -v http://localhost/admin 2>&1 | grep "Connected"
# * Connected to localhost (::1) port 80
```

IPv6 ile bağlanıyordu. Config'de `allow 127.0.0.1` (IPv4) vardı, `::1` izin listesinde yoktu, bu yüzden `deny all`'a düşüyordu.

Config'e `allow ::1` ekledim, bu sefer geçti. Bir de `127.0.0.1` ile direkt test ettim — bu da çalıştı, çünkü IPv4 üzerinden gidiyor ve `allow 127.0.0.1` yeterli oluyor:

```bash
curl -v http://127.0.0.1/admin 2>&1 | grep "Connected"
# * Connected to 127.0.0.1 (127.0.0.1) port 80
```

Son config:

```nginx
location /admin {
    allow 127.0.0.1;
    allow ::1;
    deny all;
}
```

**Beklenen:** 404 (izin verildi, backend'e gitti, `/admin` diye dosya yok)
**Sonuç:** ✅ `404 Not Found` — hem `localhost` hem `127.0.0.1` ile doğrulandı

---

## TC-12 — /admin Dışarıdan

```bash
curl http://<SERVER_IP>/admin
```

**Beklenen:** 403 Forbidden
**Sonuç:** ✅ `403 Forbidden`

---

## TC-13 — Backend Kapalıyken Ne Olur?

```bash
kill $(lsof -t -i:8080)
curl http://localhost/
```

Nginx çalışıyor ama backend yok — danışma görevlisi orada ama ofis kapalı.

**Beklenen:** 502 Bad Gateway
**Sonuç:** ✅ `502 Bad Gateway`

```bash
# Test sonrası backend tekrar başlatıldı
cd /tmp/backend && python3 -m http.server 8080 &
```

---

## TC-14 — Var Olmayan Path

```bash
curl http://localhost/birseyyok
```

İstek Nginx'ten geçip backend'e gidiyor, ama backend'de böyle bir dosya yok.

**Beklenen:** 404 (Nginx değil, backend veriyor)
**Sonuç:** ✅ `404 File not found` — Python backend'den geldi

---

## TC-15 — Backend Logunda Nginx'in İzi

```bash
curl http://<SERVER_IP>/
```

Backend terminaline baktım.

**Beklenen:** Kullanıcının IP'si değil, `127.0.0.1` görünmeli
**Sonuç:** ✅ `127.0.0.1 - - "GET / HTTP/1.0" 200` — istek Nginx'ten geldi, kullanıcıdan değil

---

## TC-16 — /users/ Altında Var Olmayan Dosya

```bash
curl http://localhost/users/olmayan.html
```

**Beklened:** 404 (users backend'den, port 3000)
**Sonuç:** ✅ `404 File not found`

---

## TC-17 — POST İsteği

```bash
curl -X POST http://localhost/users/
```

Python'un yerleşik HTTP sunucusu POST'u desteklemiyor.

**Beklenen:** 501 Not Implemented
**Sonuç:** ✅ `501 Unsupported method ('POST')`

---

## TC-18 — Host Header İletiliyor mu?

```bash
curl -v http://localhost/users/ 2>&1 | grep -i "host"
```

`proxy_set_header Host $host` direktifinin gerçekten çalışıp çalışmadığını gördüm.

**Beklenen:** `Host: localhost` header'ı görünmeli
**Sonuç:** ✅ `> Host: localhost`

---

## TC-19 — Path Büyük/Küçük Harf

```bash
curl http://localhost/Users/
curl http://localhost/USERS/
```

Nginx location'ları case-sensitive — `/Users/` ve `/USERS/` tanımlı değil.

**Beklenen:** 404
**Sonuç:** ✅ İkisi de `404 File not found`

---

## TC-20 — /admin/ Trailing Slash ile Dışarıdan

```bash
curl http://<SERVER_IP>/admin/
```

Trailing slash'ın engellemeyi etkileyip etkilemediğini test ettim.

**Beklenen:** 403 Forbidden
**Sonuç:** ✅ `403 Forbidden` — trailing slash fark yaratmıyor

---

## Özet

| Test  | Senaryo                           | Beklenen        | Sonuç |
| ----- | --------------------------------- | --------------- | ----- |
| TC-01 | `localhost/`                      | 200 + Backend   | ✅    |
| TC-02 | `<SERVER_IP>/`                    | 200 + Backend   | ✅    |
| TC-03 | `localhost/users/`                | 200 + Users     | ✅    |
| TC-04 | `localhost/computers/`            | 200 + Computers | ✅    |
| TC-05 | `<SERVER_IP>/users/`              | 200 + Users     | ✅    |
| TC-06 | `<SERVER_IP>/computers/`          | 200 + Computers | ✅    |
| TC-07 | `localhost/users` (slash yok)     | 301             | ✅    |
| TC-08 | `localhost/users` + `-L`          | 200 + Users     | ✅    |
| TC-09 | `localhost/computers` (slash yok) | 301             | ✅    |
| TC-10 | `localhost/computers` + `-L`      | 200 + Computers | ✅    |
| TC-11 | `localhost/admin` (içeriden)      | 404             | ✅    |
| TC-12 | `<SERVER_IP>/admin` (dışarıdan)   | 403             | ✅    |
| TC-13 | Backend kapalı                    | 502             | ✅    |
| TC-14 | Var olmayan path                  | 404             | ✅    |
| TC-15 | Backend log kontrolü              | 127.0.0.1       | ✅    |
| TC-16 | `/users/olmayan.html`             | 404             | ✅    |
| TC-17 | POST isteği                       | 501             | ✅    |
| TC-18 | Host header                       | Host: localhost | ✅    |
| TC-19 | `/Users/` (büyük harf)            | 404             | ✅    |
| TC-20 | `/admin/` (trailing slash)        | 403             | ✅    |

**20/20 ✅**

---

ℹ️ _Tüm testler gerçek bir Ubuntu VDS üzerinde, gerçek Nginx yapılandırmasına karşı yapıldı._
