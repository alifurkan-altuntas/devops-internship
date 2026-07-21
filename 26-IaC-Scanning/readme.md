# 🔍 IaC Scanning — Trivy Config, Dockerfile Misconfigurations, HEALTHCHECK

25. fazda Docker image'ının ve çalışma zamanının güvenliğini öğrendik. Bu fazda altyapı kodunun kendisini (Dockerfile, docker-compose.yml, Kubernetes YAML, Terraform) statik olarak taramayı öğrendik.

---

## 1. IaC Scanning Nedir

Infrastructure as Code — sunucu, ağ, güvenlik kuralları gibi altyapıyı elle kurmak yerine kod olarak tanımlamak. Dockerfile, docker-compose.yml, Kubernetes YAML dosyaları hepsi IaC. IaC scanning, Hadolint'in Dockerfile'ı kontrol etmesi gibi — ama sadece Dockerfile değil, tüm altyapı dosyalarını tarıyor.

**Araç:** Trivy — image taramanın yanı sıra `trivy config` ile IaC taraması da yapıyor.

---

## 2. docker-compose Desteklenmiyor

```bash
trivy config docker-compose.yml
# Detected config files   num=0
# WARN [report] Supported files for scanner(s) not found. scanners=[misconfig]
```

Bu Trivy sürümünde docker-compose taraması desteklenmiyor. Dockerfile'a geçildi.

---

## 3. Dockerfile Taraması

```bash
trivy config Dockerfile.bad
```

```
Dockerfile.bad (dockerfile)
Tests: 27 (SUCCESSES: 25, FAILURES: 2)
DS-0002 (HIGH): Specify at least 1 USER command in Dockerfile with non-root user as argument
DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

Aynı iki bulgu `Dockerfile.good`'da da çıktı — çünkü o dosya sadece `python:3.11-slim` kullanan boyut/açık-sayısı demosuydu, hiç `USER` veya `HEALTHCHECK` içermiyordu. IaC taraması ile image içeriği taraması (Trivy image) farklı şeyler kontrol ediyor:

| Komut          | Neyi tarar                                                        |
| -------------- | ----------------------------------------------------------------- |
| `trivy config` | Dockerfile/YAML yapısı (statik) — USER var mı, HEALTHCHECK var mı |
| `trivy image`  | Build edilmiş image içeriği — paketler, CVE'ler                   |

---

## 4. Temiz Dockerfile

`Dockerfile.bad` ve `Dockerfile.good`'un ikisinde de eksik olan `USER` ve `HEALTHCHECK` eklenerek slim + non-root + healthcheck birleştirildi:

```dockerfile
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
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import sys; sys.exit(0)"
CMD ["python", "app.py"]
```

```bash
trivy config Dockerfile.clean
# Dockerfile.clean (dockerfile)
# Tests: 27 (SUCCESSES: 27, FAILURES: 0)
```

**0 bulgu** — ama bu "her şeyi düzelttik" demek değil, "IaC/config testinin baktığı 27 kuralı geçtik" demek. `.dockerignore` ve slim image gibi diğer güvenlik önlemleri bu testin kapsamında değil, ayrı testlerle (Trivy image, Hadolint) kontrol ediliyor.

---

## 5. HEALTHCHECK

HEALTHCHECK, Docker'a "bu container gerçekten çalışıyor mu" sorusunu sordurur. Container process'i ayakta olsa bile içindeki uygulama çökmüş, donmuş olabilir — process ölmediği sürece Docker bunu fark etmez.

### Gerçek ve Bozuk Health Check Testi

```bash
docker build -f Dockerfile.clean -t python-clean .
docker run -d --name healthcheck-test python-clean
docker ps
# STATUS: Up 55 seconds (healthy)
```

```bash
docker run -d --name healthcheck-test --health-cmd="exit 1" --health-interval=5s python-clean
docker ps
# STATUS: Up 29 seconds (unhealthy)
```

`(healthy)` ve `(unhealthy)` ikisi de gözlemlendi — bu durum Kubernetes gibi orchestrator'ların çökmüş container'ı otomatik yeniden başlatmasının/trafiği kesmesinin temelini oluşturuyor.

---

## 📊 Özet

| Kontrol          | Ne Sağlıyor                                                                    |
| ---------------- | ------------------------------------------------------------------------------ |
| `trivy config`   | Dockerfile/YAML statik yapısını tarar — USER, HEALTHCHECK gibi eksikleri bulur |
| Temiz Dockerfile | Slim + non-root + healthcheck birleşince statik tarama 0 bulgu verir           |
| HEALTHCHECK      | Container'ın gerçekten çalışıp çalışmadığını test eder — healthy/unhealthy     |

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde yapılmıştır._
