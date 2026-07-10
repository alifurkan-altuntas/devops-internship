# 🔒 Docker Güvenliği — Non-Root Container, .dockerignore, Image Scanning

Docker'da güvenlik üç katmanda ele alındı: container içindeki kullanıcı yetkisi, image'a giren dosyalar ve image içindeki güvenlik açıkları.

---

## 1. Non-Root Container

### Sorun

Varsayılan olarak container'lar **root** olarak çalışıyor:

```bash
docker run python:3.11-slim whoami
# root
```

Root olarak çalışmak tehlikeli — birisi uygulamaya sızarsa container içinde her şeye erişebilir.

### Çözüm — Kendi Kullanıcımızı Oluşturmak

```dockerfile
FROM python:3.11-slim

RUN useradd -m -u 1000 appuser

USER appuser

WORKDIR /home/appuser
COPY --chown=appuser:appuser app.py .
CMD ["python", "app.py"]
```

- **`useradd -m -u 1000 appuser`** → `appuser` adında bir kullanıcı oluştur, `-m` home directory oluştur, `-u 1000` kullanıcı ID'si 1000 olsun
- **`USER appuser`** → bundan sonra bu kullanıcıyla çalış — bu satır olmadan kullanıcı oluşturulur ama hâlâ root olarak çalışılır
- **`--chown=appuser:appuser`** → kopyalanan dosyaların sahibi appuser olsun

```bash
docker run python-nonroot whoami
# appuser
```

### Test — Root vs Non-Root

```bash
# Root container — sistem dosyasını silebiliyor
docker run python-good rm /etc/passwd
echo "Çıkış kodu: $?"
# Çıkış kodu: 0 — sildi!

# Non-root container — yetkisi yok
docker run python-nonroot rm /etc/passwd
# rm: cannot remove '/etc/passwd': Permission denied
echo "Çıkış kodu: $?"
# Çıkış kodu: 1
```

Root container `/etc/passwd`'ı silebildi — non-root `Permission denied` aldı. Birisi container'a sızsa bile non-root kullanıcıyla sınırlı kalır.

---

## 2. `.dockerignore`

### Sorun

`COPY . .` deyince proje klasöründeki **her şey** image'a giriyor:

```
app.py
requirements.txt
Dockerfile
.env          ← şifreler burada! (SECRET_KEY=cokgizlisifre123)
.git/         ← tüm git geçmişi
```

**Zarf benzetmesi:** Bir zarf gönderiyorsun, içine her şeyi koyuyorsun — mektup, alışveriş listesi, ve banka kartı şifren. Zarfı postaya verince şifren de gidiyor.

`.dockerignore` zarfı kapatmadan önce "bunları koyma" listesi gibi çalışıyor.

### Çözüm

```bash
# .dockerignore dosyası
.env
.git
*.md
__pycache__
*.pyc
Dockerfile*
tests/
.dockerignore
```

**Not:** `.dockerignore`'u da listeye ekledik — dosyanın kendisi image'a girse "hangi dosyaların hariç tutulduğu" bilgisi paylaşılmış olur, gereksiz bilgi vermemek için eklendi.

### Test

```bash
# .env dosyası oluştur
echo "SECRET_KEY=cokgizlisifre123" > .env

# .dockerignore OLMADAN build et
mv .dockerignore .dockerignore.bak
docker build -f Dockerfile.bad -t python-noignore .
docker run python-noignore ls -la | grep .env
# -rw-rw-r-- 1 root root 28 .env  ← girdi!

# .dockerignore İLE build et
mv .dockerignore.bak .dockerignore
docker build -f Dockerfile.bad -t python-withignore .
docker run python-withignore ls -la | grep .env
# (çıktı yok — .env image'a girmedi) ✅
```

---

## 3. Image Scanning (Trivy)

### Sorun

Image indiriyorsun, içinde kütüphaneler var. Bu kütüphanelerin bazılarında bilinen güvenlik açıkları olabilir — farkında olmadan açık içeren bir image kullanıyor olabilirsin.

### Kurulum

```bash
wget https://github.com/aquasecurity/trivy/releases/download/v0.72.0/trivy_0.72.0_Linux-64bit.deb
sudo dpkg -i trivy_0.72.0_Linux-64bit.deb
```

### Tarama

```bash
trivy image python:3.11 --severity HIGH,CRITICAL
trivy image python:3.11-slim --severity HIGH,CRITICAL
```

### Sonuçlar

```bash
trivy image python:3.11 --severity HIGH,CRITICAL 2>/dev/null | grep "^Total:"
# Total: 412 (HIGH: 363, CRITICAL: 49)

trivy image python:3.11-slim --severity HIGH,CRITICAL 2>/dev/null | grep "^Total:"
# Total: 20 (HIGH: 18, CRITICAL: 2)
```

| | HIGH | CRITICAL | Toplam |
|---|---|---|---|
| **python:3.11** | 363 | 49 | **412** |
| **python:3.11-slim** | 18 | 2 | **20** |

**20 kat daha az güvenlik açığı** — sadece slim image kullanarak. `python:3.11` içinde onlarca ekstra kütüphane var, bunların 400+ güvenlik açığı var. `slim`'de bunlar yok.

Trivy çıktısında her açık için şunlar görünüyor:

```
CVE-2026-24049   HIGH   wheel 0.45.1   → 0.46.2   Privilege Escalation...
```

- **CVE** → güvenlik açığının kimlik numarası
- **HIGH/CRITICAL** → tehlike seviyesi
- **wheel 0.45.1** → hangi kütüphanenin hangi versiyonunda
- **0.46.2** → hangi versiyona geçince düzelir

---

## 4 Katmanlı Güvenlik Özeti

| Yöntem | Ne Sağlıyor |
|--------|------------|
| **Slim/alpine image** | Az kütüphane → az güvenlik açığı (412 → 20) |
| **Non-root user** | Sızılsa bile sınırlı yetki |
| **`.dockerignore`** | Şifreler ve gereksiz dosyalar image'a girmesin |
| **Trivy** | Mevcut açıkları tespit et, düzelt |

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde yapılmıştır._