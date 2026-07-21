# 🐳 IaC Scanning — Uygulamalı Testler

Bu belgede kavramsal öğrenilen konular gerçek ortamda test edildi.

---

## 1. docker-compose Taraması Denemeleri

```bash
cd ~/docker-practice
trivy config docker-compose.yml
# FATAL error: lstat docker-compose.yml: no such file or directory
```

Yanlış klasördeydik. Doğru klasöre geçildi:

```bash
cd ~/compose-practice
trivy config docker-compose.yml
# Detected config files   num=0
# WARN Supported files for scanner(s) not found. scanners=[misconfig]
```

Dosya bulundu ama hiç bulgu çıkmadı — compose dosyası çok basitti. Kasıtlı güvensiz bir compose dosyası denemesi düşünüldü (`privileged: true`, host volume, açık şifreler) ama denerken şu ortaya çıktı: **bu Trivy sürümü docker-compose taramasını hiç desteklemiyor.** Dockerfile'a geçildi.

---

## 2. Dockerfile.bad ve Dockerfile.good Karşılaştırması

```bash
trivy config ~/docker-practice/Dockerfile.bad
```

```
Dockerfile.bad (dockerfile)
Tests: 27 (SUCCESSES: 25, FAILURES: 2)
DS-0002 (HIGH): Specify at least 1 USER command...
DS-0026 (LOW): Add HEALTHCHECK instruction...
```

```bash
trivy config ~/docker-practice/Dockerfile.good
```

```
Dockerfile.good (dockerfile)
Tests: 27 (SUCCESSES: 25, FAILURES: 2)
DS-0002 (HIGH): Specify at least 1 USER command...
DS-0026 (LOW): Add HEALTHCHECK instruction...
```

**Beklenmedik sonuç:** İkisi de aynı 2 uyarıyı verdi. `Dockerfile.good` içeriğine bakılınca sebep anlaşıldı:

```dockerfile
FROM python:3.11 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY app.py .
CMD ["python", "app.py"]
```

`Dockerfile.good` hiçbir zaman `USER` içermemişti — sadece `python:3.11-slim` kullanan, image boyutunu küçültme amaçlı eski bir demoydu. "İyi" derken kastedilen sadece boyut/açık sayısıydı, non-root güvenliği ayrı bir dosyada (`python-nonroot`, `useradd`+`USER appuser` ile) yapılmıştı — ikisi hiç birleştirilmemişti.

---

## 3. Temiz Dockerfile Oluşturma

Slim + non-root + healthcheck birleştirildi:

```bash
cat > ~/docker-practice/Dockerfile.clean << 'EOF'
FROM python:3.11 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.11-slim
RUN useradd -m -u 1000 appuser
WORKDIR /home/appuser
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appuser app.py .
USER appuser
ENV PATH=/home/appuser/.local/bin:$PATH
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import sys; sys.exit(0)"
CMD ["python", "app.py"]
EOF

trivy config ~/docker-practice/Dockerfile.clean
```

```
Dockerfile.clean (dockerfile)
Tests: 27 (SUCCESSES: 27, FAILURES: 0)
```

0 bulgu — USER ve HEALTHCHECK eklenince statik taramanın kontrol ettiği 27 kuralın tamamı geçildi.

---

## 4. HEALTHCHECK'i Canlı Test Etme

### İlk Deneme — Container Görünmedi

```bash
docker build -f Dockerfile.clean -t python-clean .
docker run -d --name healthcheck-test python-clean
docker ps
```

`healthcheck-test` listede **hiç görünmedi**. Sebep araştırıldı:

```bash
docker ps -a | grep healthcheck-test
# Exited (0) About a minute ago

docker logs healthcheck-test
# Merhaba Docker! Güncellendi.
```

`app.py` içeriği:

```python
print("Merhaba Docker! Güncellendi.")
```

Tek satır, hemen bitiyor — container görevini tamamlayıp kapanıyor, health check'in çalışmaya fırsatı bile olmuyor. `docker ps` durmuş container'ı zaten göstermiyor.

### Düzeltme — Ayakta Kalan Bir Process

```bash
cat > ~/docker-practice/app.py << 'EOF'
import time
print("Merhaba Docker! Güncellendi.")
while True:
    time.sleep(60)
EOF

docker rm -f healthcheck-test
docker build -f Dockerfile.clean -t python-clean .
docker run -d --name healthcheck-test python-clean
```

15-20 saniye beklenip kontrol edildi:

```bash
docker ps
```

```
CONTAINER ID   IMAGE          STATUS
7ef850f7e03d   python-clean   Up 55 seconds (healthy)
```

**`(healthy)` ✅** — health check gerçekten çalıştığında görüldü.

### Bozuk Health Check Testi

```bash
docker rm -f healthcheck-test
docker run -d --name healthcheck-test --health-cmd="exit 1" --health-interval=5s python-clean
```

```bash
docker ps
```

```
CONTAINER ID   IMAGE          STATUS
16e9638458a8   python-clean   Up 29 seconds (unhealthy)
```

**`(unhealthy)` ✅** — kasıtlı bozuk komutla container "unhealthy" işaretlendi, process ayakta olmasına rağmen.

**Pratik önemi:** Kubernetes gibi orchestrator'lar `unhealthy` container'ı otomatik yeniden başlatır ya da trafiği ona yönlendirmeyi keser. Health check olmadan, çökmüş bir servis "yaşıyormuş" gibi trafik almaya devam eder.

```bash
docker rm -f healthcheck-test
```

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde yapılmıştır._
