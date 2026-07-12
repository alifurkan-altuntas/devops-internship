# 🔒 Docker Security — Hands-On Tests

Security topics tested in a real environment.

---

## Environment

```bash
cd ~/docker-practice
```

---

## 1. Non-Root Container Test

### Default State — Running as Root

```bash
docker run python:3.11-slim whoami
# root
docker run python-good whoami
# root
docker run python-bad whoami
# root
```

All root — every container runs as root by default.

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

### Root vs Non-Root — Difference Test

```bash
# Root container — deleted a system file
docker run python-good rm /etc/passwd
echo "Exit code: $?"
# Exit code: 0 — deleted!

# Non-root container — no permission
docker run python-nonroot rm /etc/passwd
# rm: cannot remove '/etc/passwd': Permission denied
echo "Exit code: $?"
# Exit code: 1
```

The root container deleted `/etc/passwd`. The non-root container got `Permission denied`. Even if someone breaks into the container, they're limited by the non-root user's permissions.

---

## 2. `.dockerignore` Test

### Create a Test File

```bash
echo "SECRET_KEY=topsecretpassword123" > .env
cat .env
# SECRET_KEY=topsecretpassword123
```

### WITHOUT `.dockerignore` — .env Gets In

```bash
mv .dockerignore .dockerignore.bak
docker build -f Dockerfile.bad -t python-noignore .
docker run python-noignore ls -la | grep .env
# -rw-rw-r-- 1 root root 28 .env  ← it got in!
```

### WITH `.dockerignore` — .env Stays Out

```bash
mv .dockerignore.bak .dockerignore
docker build -f Dockerfile.bad -t python-withignore .
docker run python-withignore ls -la | grep .env
# (no output — .env didn't make it into the image) ✅
```

### The `.dockerignore` File Itself

Without adding `.dockerignore` to the list, it gets into the image too:

```bash
# When .dockerignore isn't in the list
docker run python-test ls -la | grep dockerignore
# -rw-rw-r-- 1 root root 52 .dockerignore  ← got in!

# After adding it to the list
echo ".dockerignore" >> .dockerignore
docker build -f Dockerfile.bad -t python-test .
docker run python-test ls -la | grep dockerignore
# (no output) ✅
```

Added to avoid sharing unnecessary information about which files are excluded.

### Final `.dockerignore`

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

### Installation

```bash
wget https://github.com/aquasecurity/trivy/releases/download/v0.72.0/trivy_0.72.0_Linux-64bit.deb
sudo dpkg -i trivy_0.72.0_Linux-64bit.deb
```

### Scanning

```bash
trivy image python:3.11 --severity HIGH,CRITICAL 2>/dev/null | grep "^Total:"
# Total: 412 (HIGH: 363, CRITICAL: 49)

trivy image python:3.11-slim --severity HIGH,CRITICAL 2>/dev/null | grep "^Total:"
# Total: 20 (HIGH: 18, CRITICAL: 2)
```

### Results

|                      | HIGH | CRITICAL | Total   |
| -------------------- | ---- | -------- | ------- |
| **python:3.11**      | 363  | 49       | **412** |
| **python:3.11-slim** | 18   | 2        | **20**  |

**20x fewer vulnerabilities** — just from using the slim image.

Each vulnerability in Trivy output:

```
CVE-2026-24049   HIGH   wheel 0.45.1   → 0.46.2   Privilege Escalation...
```

- **CVE** → the vulnerability's ID number
- **HIGH/CRITICAL** → severity level
- **0.46.2** → which version fixes it

---

ℹ️ _All tests performed on a real Ubuntu VPS._
