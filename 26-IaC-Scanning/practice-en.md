# 🐳 IaC Scanning — Hands-On Tests

This document covers the hands-on tests behind the concepts explained in readme.md.

---

## 1. Attempting to Scan docker-compose

```bash
cd ~/docker-practice
trivy config docker-compose.yml
# FATAL error: lstat docker-compose.yml: no such file or directory
```

Wrong folder. Moved to the correct one:

```bash
cd ~/compose-practice
trivy config docker-compose.yml
# Detected config files   num=0
# WARN Supported files for scanner(s) not found. scanners=[misconfig]
```

The file was found but no findings came up — the compose file was too simple. A deliberately insecure compose file was considered (`privileged: true`, host volume, plaintext secrets), but while trying it, this came up: **this Trivy version doesn't support docker-compose scanning at all.** We moved on to Dockerfiles.

---

## 2. Comparing Dockerfile.bad and Dockerfile.good

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

**Unexpected result:** both gave the same 2 warnings. Looking at the content of `Dockerfile.good` explained why:

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

`Dockerfile.good` never had a `USER` at all — it was an old demo focused solely on shrinking image size using `python:3.11-slim`. "Good" here only meant size/vulnerability count; non-root security had been done in a separate file (`python-nonroot`, with `useradd` + `USER appuser`) — the two were never combined.

---

## 3. Building a Clean Dockerfile

Slim + non-root + healthcheck combined:

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

Zero findings — adding USER and HEALTHCHECK passed all 27 rules checked by the static scan.

---

## 4. Testing HEALTHCHECK Live

### First Attempt — Container Didn't Show Up

```bash
docker build -f Dockerfile.clean -t python-clean .
docker run -d --name healthcheck-test python-clean
docker ps
```

`healthcheck-test` was **nowhere in the list**. Investigated why:

```bash
docker ps -a | grep healthcheck-test
# Exited (0) About a minute ago

docker logs healthcheck-test
# Hello Docker! Updated.
```

`app.py` content:

```python
print("Hello Docker! Updated.")
```

A single line that exits immediately — the container finishes its job and shuts down before the health check even gets a chance to run. `docker ps` doesn't show stopped containers anyway.

### Fix — A Process That Stays Alive

```bash
cat > ~/docker-practice/app.py << 'EOF'
import time
print("Hello Docker! Updated.")
while True:
    time.sleep(60)
EOF

docker rm -f healthcheck-test
docker build -f Dockerfile.clean -t python-clean .
docker run -d --name healthcheck-test python-clean
```

Waited 15-20 seconds and checked:

```bash
docker ps
```

```
CONTAINER ID   IMAGE          STATUS
7ef850f7e03d   python-clean   Up 55 seconds (healthy)
```

**`(healthy)` ✅** — seen once the health check actually had time to run.

### Testing a Broken Health Check

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

**`(unhealthy)` ✅** — with a deliberately broken command, the container was marked "unhealthy" even though the process was still running.

**Practical significance:** orchestrators like Kubernetes automatically restart an "unhealthy" container or stop routing traffic to it. Without a health check, a crashed service keeps receiving traffic as if it were "alive."

```bash
docker rm -f healthcheck-test
```

---

ℹ️ _All tests were performed on a real Ubuntu VPS._
