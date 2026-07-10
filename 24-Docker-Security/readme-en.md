# 🔒 Docker Security — Non-Root Containers, .dockerignore, Image Scanning

Docker security was approached at three layers: user privileges inside the container, what files make it into the image, and security vulnerabilities inside the image itself.

---

## 1. Non-Root Container

### The Problem

By default, containers run as **root**:

```bash
docker run python:3.11-slim whoami
# root
```

Running as root is dangerous — if someone gets into the application, they have full access inside the container.

### The Fix — Creating Our Own User

```dockerfile
FROM python:3.11-slim

RUN useradd -m -u 1000 appuser

USER appuser

WORKDIR /home/appuser
COPY --chown=appuser:appuser app.py .
CMD ["python", "app.py"]
```

- **`useradd -m -u 1000 appuser`** → create a user named `appuser`, `-m` creates a home directory, `-u 1000` sets the user ID to 1000
- **`USER appuser`** → run everything from here as this user — without this line, the user is created but it still runs as root
- **`--chown=appuser:appuser`** → the copied files should be owned by appuser

```bash
docker run python-nonroot whoami
# appuser
```

### Test — Root vs Non-Root

```bash
# Root container — can delete system files
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

## 2. `.dockerignore`

### The Problem

`COPY . .` copies **everything** in the project folder into the image:

```
app.py
requirements.txt
Dockerfile
.env          ← secrets here! (SECRET_KEY=topsecretpassword123)
.git/         ← full git history
```

**Envelope analogy:** You're sending an envelope and you put everything into it — your letter, your shopping list, and your bank card PIN. Once it's in the post, the PIN is out there too.

`.dockerignore` works like a "don't put these in" list before sealing the envelope.

### The Fix

```bash
# .dockerignore file
.env
.git
*.md
__pycache__
*.pyc
Dockerfile*
tests/
.dockerignore
```

**Note:** `.dockerignore` itself was added to the list — if it made it into the image, it would reveal which files were excluded. Added to avoid sharing unnecessary information.

### Test

```bash
# Create a .env file
echo "SECRET_KEY=topsecretpassword123" > .env

# Build WITHOUT .dockerignore
mv .dockerignore .dockerignore.bak
docker build -f Dockerfile.bad -t python-noignore .
docker run python-noignore ls -la | grep .env
# -rw-rw-r-- 1 root root 28 .env  ← it got in!

# Build WITH .dockerignore
mv .dockerignore.bak .dockerignore
docker build -f Dockerfile.bad -t python-withignore .
docker run python-withignore ls -la | grep .env
# (no output — .env didn't make it into the image) ✅
```

---

## 3. Image Scanning (Trivy)

### The Problem

You pull an image, it contains libraries. Some of those libraries may have known security vulnerabilities — you might be running a vulnerable image without knowing it.

### Installation

```bash
wget https://github.com/aquasecurity/trivy/releases/download/v0.72.0/trivy_0.72.0_Linux-64bit.deb
sudo dpkg -i trivy_0.72.0_Linux-64bit.deb
```

### Scanning

```bash
trivy image python:3.11 --severity HIGH,CRITICAL
trivy image python:3.11-slim --severity HIGH,CRITICAL
```

### Results

```bash
trivy image python:3.11 --severity HIGH,CRITICAL 2>/dev/null | grep "^Total:"
# Total: 412 (HIGH: 363, CRITICAL: 49)

trivy image python:3.11-slim --severity HIGH,CRITICAL 2>/dev/null | grep "^Total:"
# Total: 20 (HIGH: 18, CRITICAL: 2)
```

|                      | HIGH | CRITICAL | Total   |
| -------------------- | ---- | -------- | ------- |
| **python:3.11**      | 363  | 49       | **412** |
| **python:3.11-slim** | 18   | 2        | **20**  |

**20x fewer vulnerabilities** — just from using the slim image. `python:3.11` has dozens of extra libraries, with 400+ known vulnerabilities between them. `slim` doesn't have those libraries.

Each vulnerability in the Trivy output looks like:

```
CVE-2026-24049   HIGH   wheel 0.45.1   → 0.46.2   Privilege Escalation...
```

- **CVE** → the vulnerability's ID number
- **HIGH/CRITICAL** → severity level
- **wheel 0.45.1** → which library and version is affected
- **0.46.2** → which version fixes it

---

## 4-Layer Security Summary

| Method                | What It Achieves                                    |
| --------------------- | --------------------------------------------------- |
| **Slim/alpine image** | Fewer libraries → fewer vulnerabilities (412 → 20)  |
| **Non-root user**     | Limited damage even if someone gets in              |
| **`.dockerignore`**   | Secrets and unnecessary files stay out of the image |
| **Trivy**             | Identify existing vulnerabilities and fix them      |

---

ℹ️ _All tests performed on a real Ubuntu VPS._
