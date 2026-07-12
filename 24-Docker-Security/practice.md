# 🔒 Docker Güvenliği — Uygulamalı Testler

Bu belgede güvenlik konuları gerçek ortamda test edildi.

---

## Ortam

```bash
cd ~/docker-practice
```

---

## 1. Non-Root Container Testi

### Varsayılan Durum — Root Olarak Çalışma

```bash
docker run python:3.11-slim whoami
# root
docker run python-good whoami
# root
docker run python-bad whoami
# root
```

Hepsi root — varsayılan olarak her container root çalışıyor.

### Dockerfile.nonroot

```dockerfile
FROM python:3.11-slim

RUN useradd -m -u 1000 appuser

USER appuser

WORKDIR /home/appuser
COPY --chown=appuser:appuser app.py .
CMD ["python", "app.py"]
```

```bash
docker build -f Dockerfile.nonroot -t python-nonroot .
docker run python-nonroot whoami
# appuser
```

### Root vs Non-Root — Fark Testi

```bash
# Root container — sistem dosyasını silebildi
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

## 2. `.dockerignore` Testi

### Test Dosyası Oluştur

```bash
echo "SECRET_KEY=cokgizlisifre123" > .env
cat .env
# SECRET_KEY=cokgizlisifre123
```

### `.dockerignore` OLMADAN — .env image'a giriyor

```bash
mv .dockerignore .dockerignore.bak
docker build -f Dockerfile.bad -t python-noignore .
docker run python-noignore ls -la | grep .env
# -rw-rw-r-- 1 root root 28 .env  ← girdi!
```

### `.dockerignore` İLE — .env image'a girmiyor

```bash
mv .dockerignore.bak .dockerignore
docker build -f Dockerfile.bad -t python-withignore .
docker run python-withignore ls -la | grep .env
# (çıktı yok — .env image'a girmedi) ✅
```

### `.dockerignore` Dosyasının Kendisi

`.dockerignore` dosyasını listeye eklemeyince image'a giriyor:

```bash
# .dockerignore listede yokken
docker run python-test ls -la | grep dockerignore
# -rw-rw-r-- 1 root root 52 .dockerignore  ← girdi!

# Listeye ekleyince
echo ".dockerignore" >> .dockerignore
docker build -f Dockerfile.bad -t python-test .
docker run python-test ls -la | grep dockerignore
# (çıktı yok) ✅
```

Dosyanın kendisi de listeye eklendi — "hangi dosyaların hariç tutulduğu" bilgisini gereksiz yere paylaşmamak için.

### `.dockerignore` Son Hali

```
.env
.git
*.md
__pycache__
*.pyc
Dockerfile*
tests/
.dockerignore
```

---

## 3. Trivy Image Scanning

### Kurulum

```bash
wget https://github.com/aquasecurity/trivy/releases/download/v0.72.0/trivy_0.72.0_Linux-64bit.deb
sudo dpkg -i trivy_0.72.0_Linux-64bit.deb
```

### Tarama

```bash
trivy image python:3.11 --severity HIGH,CRITICAL 2>/dev/null | grep "^Total:"
# Total: 412 (HIGH: 363, CRITICAL: 49)

trivy image python:3.11-slim --severity HIGH,CRITICAL 2>/dev/null | grep "^Total:"
# Total: 20 (HIGH: 18, CRITICAL: 2)
```

### Sonuç

| | HIGH | CRITICAL | Toplam |
|---|---|---|---|
| **python:3.11** | 363 | 49 | **412** |
| **python:3.11-slim** | 18 | 2 | **20** |

**20 kat daha az güvenlik açığı** — sadece slim image kullanarak.

Trivy çıktısında her açık için:

```
CVE-2026-24049   HIGH   wheel 0.45.1   → 0.46.2   Privilege Escalation...
```

- **CVE** → güvenlik açığının kimlik numarası
- **HIGH/CRITICAL** → tehlike seviyesi
- **0.46.2** → hangi versiyona geçince düzelir

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde yapılmıştır._