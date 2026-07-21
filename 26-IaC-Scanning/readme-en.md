# 🔍 IaC Scanning — Trivy Config, Dockerfile Misconfigurations, HEALTHCHECK

In phase 25 we covered the security of the Docker image and its runtime. This phase covers scanning the infrastructure code itself (Dockerfile, docker-compose.yml, Kubernetes YAML, Terraform) statically.

---

## 1. What Is IaC Scanning

Infrastructure as Code — defining infrastructure (servers, networks, security rules) as code instead of setting it up by hand. Dockerfile, docker-compose.yml, and Kubernetes YAML files are all IaC. IaC scanning is like Hadolint checking a Dockerfile — but it scans all infrastructure files, not just Dockerfiles.

**Tool:** Trivy — besides scanning images, `trivy config` also does IaC scanning.

---

## 2. docker-compose Isn't Supported

```bash
trivy config docker-compose.yml
# Detected config files   num=0
# WARN [report] Supported files for scanner(s) not found. scanners=[misconfig]
```

This Trivy version doesn't support docker-compose scanning. We moved on to Dockerfiles.

---

## 3. Scanning a Dockerfile

```bash
trivy config Dockerfile.bad
```

```
Dockerfile.bad (dockerfile)
Tests: 27 (SUCCESSES: 25, FAILURES: 2)
DS-0002 (HIGH): Specify at least 1 USER command in Dockerfile with non-root user as argument
DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
```

The same two findings showed up in `Dockerfile.good` too — because that file was just a size/vulnerability-count demo using `python:3.11-slim`, and never included a `USER` or `HEALTHCHECK`. IaC scanning and image content scanning (Trivy image) check different things:

| Command        | What It Scans                                                                     |
| -------------- | --------------------------------------------------------------------------------- |
| `trivy config` | Static structure of the Dockerfile/YAML — is there a USER, is there a HEALTHCHECK |
| `trivy image`  | The built image's content — packages, CVEs                                        |

---

## 4. A Clean Dockerfile

The `USER` and `HEALTHCHECK` missing from both `Dockerfile.bad` and `Dockerfile.good` were added, combining slim + non-root + healthcheck:

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

**Zero findings** — but that doesn't mean "everything is fixed," it means "we passed the 27 rules this specific config test checks." Other protections like `.dockerignore` and slim images aren't covered by this test — they're checked by separate tests (Trivy image, Hadolint).

---

## 5. HEALTHCHECK

HEALTHCHECK lets Docker ask "is this container actually working?" Even if the container's process is still running, the application inside it might have crashed or hung — as long as the process hasn't died, Docker won't notice.

### Testing a Real vs Broken Health Check

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

Both `(healthy)` and `(unhealthy)` were observed — this is the foundation of how orchestrators like Kubernetes automatically restart or stop routing traffic to a crashed container.

---

## 📊 Summary

| Check            | What It Provides                                                                     |
| ---------------- | ------------------------------------------------------------------------------------ |
| `trivy config`   | Scans the static structure of Dockerfile/YAML — finds missing USER, HEALTHCHECK etc. |
| Clean Dockerfile | Combining slim + non-root + healthcheck gives zero findings in static scan           |
| HEALTHCHECK      | Tests whether the container is actually working — healthy/unhealthy                  |

---

ℹ️ _All tests were performed on a real Ubuntu VPS._
