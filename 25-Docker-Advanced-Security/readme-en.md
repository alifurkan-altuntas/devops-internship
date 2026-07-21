# 🔒 Docker Advanced Security

In phase 24 we covered the basics — non-root containers, .dockerignore, Trivy. This phase goes deeper.

---

## 1. Distroless Image

A distroless image contains no Linux distribution at all — just the bare minimum needed to run the application. Unlike Alpine, which still has a shell and basic tools, distroless has none of that. For Python, it only includes what's needed to run Python itself.

Python distroless image: `gcr.io/distroless/python3` — maintained by Google.

```dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM gcr.io/distroless/python3
COPY --from=builder /root/.local /root/.local
COPY app.py .
CMD ["app.py"]
```

Note: `CMD` changes too — no shell means you can't write `python app.py`, just `app.py` directly.

### Test — No Shell

```bash
docker run -it python-distroless sh
# /usr/bin/python3.13: can't open file '//sh': No such file or directory
```

When `sh` was typed, Python tried to open it as a script and failed — there's no shell. Even if someone breaks in, there are no tools to run commands with.

### Comparison

| Image            | Size    | Vulnerabilities  | Shell  |
| ---------------- | ------- | ---------------- | ------ |
| python:3.11      | 1.62 GB | 412              | ✅ yes |
| python:3.11-slim | 190 MB  | 28               | ✅ yes |
| distroless       | 94 MB   | 21 (CRITICAL: 0) | ❌ no  |

---

## 2. Read-Only Filesystem

`--read-only` locks the container's filesystem — no writes to disk, only reads and execution.

```bash
# Normal container — can write to disk
docker run python-good sh -c "echo 'test' > /tmp/test.txt"
# test

# Read-only container — cannot write
docker run --read-only python-good sh -c "echo 'test' > /tmp/test.txt"
# sh: 1: cannot create /tmp/test.txt: Read-only file system
```

If someone breaks into the container and tries to drop a malicious file, download a script, or modify a config — they can't.

### --tmpfs for RAM Writes

If the application needs to write temporary files, `/tmp` can be made writable in RAM:

```bash
docker run --read-only --tmpfs /tmp python-good sh -c "echo 'temp' > /tmp/test.txt && cat /tmp/test.txt"
# temp
```

Can write to RAM but not to disk. Combined with distroless: no disk writes, and even if something is written to RAM, there are no tools to execute it.

---

## 3. Resource Limits

In case of unauthorized access or a breach, resource limits prevent an attacker from overloading the server, running cryptominers, or executing large attack payloads. The container gets only what it needs — nothing more.

### Memory Limit

```bash
docker run --memory 10m --memory-swap 10m python-good python3 -c "
data = []
for i in range(1000000):
    data.append('x' * 1000)
"
# Exit code: 137 — OOM Kill
```

- **`--memory 10m`** → Max 10MB RAM. If swap is available, data spills to disk and the program continues.
- **`--memory-swap 10m`** → Max 10MB RAM + Swap combined. No swap either — when space runs out, the kernel kills the container.

**What is swap:** When RAM fills up, the OS moves data to disk and uses it as if it were RAM. Restricting swap too means there's genuinely nowhere to go — the container gets killed (exit code 137, OOM Kill).

### CPU Limit

```bash
docker run --cpus 0.5 python-good python3 app.py
```

The container can use at most half a CPU core.

---

## 4. BuildKit

BuildKit is Docker's next-generation build engine. Two important features: parallel builds and secret mounting.

### Parallel Build

BuildKit runs independent stages simultaneously.

The first tests used the same base image (`python:3.11-slim`) for both stages — no difference showed up. Why? Docker serializes access to the same image; two stages can't use it simultaneously. We questioned it, investigated, and re-tested with different base images:

```bash
# Dockerfile.parallel — stage1: python:3.11-slim, stage2: python:3.10-slim

# Normal build — sequential
time docker build --no-cache -f Dockerfile.parallel -t test-normal .
# real 0m41.372s

# BuildKit — parallel
time DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.parallel -t test-buildkit .
# real 0m31.861s
```

**10 seconds faster** — two independent stages ran in parallel. Using `--progress=plain` we could see steps `#5` and `#6` starting at the same time in the logs — proved.

**Lesson learned:** Parallel builds only make a meaningful difference when stages use different base images and are truly independent. The real advantage shows up in large CI/CD environments. We didn't just accept the claim — we questioned it, tested it, and proved it.

### Secret Mount

With normal `--build-arg`, secrets end up in image history:

```bash
docker build --build-arg SECRET=mysecret123 -f Dockerfile.secret-bad -t test .
docker history test
# ARG SECRET=mysecret123   ← visible to anyone!
```

With BuildKit secret mount, secrets never enter the image:

```dockerfile
FROM python:3.11-slim
RUN --mount=type=secret,id=mysecret \
    cat /run/secrets/mysecret
```

```bash
echo "mysecret123" > /tmp/mysecret.txt

DOCKER_BUILDKIT=1 docker build \
  --secret id=mysecret,src=/tmp/mysecret.txt \
  -f Dockerfile.secret-good \
  -t test-secret-good .

docker history test-secret-good | grep secret
# (no output — secret never entered the image) ✅
```

The secret is only accessible during that RUN step at `/run/secrets/mysecret`, then deleted.

---

## 5. Hadolint — Dockerfile Linter

Hadolint catches errors and bad practices in Dockerfiles before you even build.

```bash
docker run --rm -i hadolint/hadolint < Dockerfile.good
```

### Issues Found and Fixed

**DL3045 — COPY without WORKDIR**

```dockerfile
# Bad
COPY requirements.txt .   # where is "."?

# Good
WORKDIR /app
COPY requirements.txt .
```

**DL3042 — pip cache directory**

```dockerfile
# Bad — cache bloats the image
RUN pip install -r requirements.txt

# Good
RUN pip install --no-cache-dir -r requirements.txt
```

After fixing:

```bash
docker run --rm -i hadolint/hadolint < Dockerfile.good
# (no output — clean) ✅
```

Added to a CI/CD pipeline, it automatically checks every Dockerfile on push.

---

## 6. Image Tag Immutability

Using `latest` means the image can change between builds — a breaking update could ship silently, or two people building from the same Dockerfile could get different results. That's why version tags are used, and better yet, SHA digests.

```bash
# Find SHA
docker inspect python:3.11-slim --format '{{index .RepoDigests 0}}'
# python@sha256:e031123e3d85762b141ad1cbc56452ba69c6e722ebf2f042cc0dc86c47c0d8b3
```

```dockerfile
# Bad — can pull a different image each time
FROM python:latest
FROM python:3.11-slim

# Good — SHA never changes, always the same image
FROM python:3.11-slim@sha256:e031123e3d85762b141ad1cbc56452ba69c6e722ebf2f042cc0dc86c47c0d8b3
```

---

---

## 7. docker-bench-security

Trivy worked for image and container security. For scanning the Docker installation itself, we used docker-bench-security. Like an external auditor visiting a company — it checks the system against CIS (Center for Internet Security) standards. Which settings are correct, which are critical, which are low priority — it checks each one against production environment expectations.

**What is CIS:** Center for Internet Security — industry-standard security rules built from real attack data and expert consensus from security researchers, companies, and universities worldwide. They publish separate benchmarks for Docker, Kubernetes, Linux, and others. Updated periodically — we used CIS Docker Benchmark 1.6.0.

### Installation and Run

```bash
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
sudo sh docker-bench-security.sh 2>/dev/null | tail -20
```

### Result Types

| Type   | Meaning                |
| ------ | ---------------------- |
| [PASS] | Secure ✅              |
| [WARN] | Needs attention ⚠️     |
| [NOTE] | Manual review required |
| [INFO] | Informational only     |

### Our Results

```
Checks: 117
Score: 7
```

**PASS:**

- Docker version is up to date (29.6.0) ✅
- Logging level set to 'info' ✅
- No insecure registries in use ✅
- Swarm mode disabled — Swarm checks auto-PASS ✅

**WARN:**

- No separate partition for containers
- Audit logging not enabled for Docker files
- Network traffic between containers on default bridge not restricted

**Note:** This is a development/test environment. The WARN items are things that should be addressed in a production environment. Blind trust isn't the right approach — CIS benchmark is a starting point, and the person who understands the system decides what's actually necessary.

---

## 8. Image Signing (Cosign)

We signed container images with our own key to verify their authenticity and that they haven't been tampered with. Like an HTTPS certificate — it proves the content came from the real owner and hasn't been modified.

**Cosign** — an open source image signing tool by the Sigstore project. Becoming the standard in the Kubernetes ecosystem.

### Installation

```bash
wget https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
```

### Generating a Key Pair

```bash
cosign generate-key-pair
# cosign.key → private key (for signing)
# cosign.pub → public key (for verification)
```

### Signing an Image

```bash
# Push image to registry first
docker tag python-good alifurkanaltuntas/python-good:v1.0
docker push alifurkanaltuntas/python-good:v1.0

# Sign with SHA — safer than signing by tag
IMAGE_SHA=$(docker inspect alifurkanaltuntas/python-good:v1.0 --format '{{index .RepoDigests 0}}')
cosign sign --key cosign.key $IMAGE_SHA
```

Signing by tag triggers a warning from Cosign: "tag can be redirected to a different image, use SHA." SHA can't be changed — if the image changes, the SHA changes.

### Verifying the Signature

```bash
cosign verify --key cosign.pub $IMAGE_SHA 2>/dev/null | python3 -m json.tool
```

```json
[
  {
    "critical": {
      "identity": {
        "docker-reference": "index.docker.io/alifurkanaltuntas/python-good@sha256:d5a3da9..."
      },
      "image": {
        "docker-manifest-digest": "sha256:d5a3da9..."
      }
    }
  }
]
```

### Tampered Image Test

```bash
# Acted like an attacker — pushed a different image to the same tag
docker tag python-bad alifurkanaltuntas/python-good:v1.0
docker push alifurkanaltuntas/python-good:v1.0

# Verification fails — image was tampered with!
cosign verify --key cosign.pub alifurkanaltuntas/python-good:v1.0
# Error: no signatures found
```

The image content changed, the SHA changed, the signature didn't match — Cosign said "this image has been modified."

**Real world scenario:** An attacker breaches the registry and replaces the image with a malicious version. Another server runs `cosign verify` and gets "signature mismatch" — the image is not run. Without Cosign, nobody would notice.

---

## 9. Seccomp

Short for "Secure Computing" — a Linux kernel feature that restricts the system calls a container can make to the kernel (opening files, network access, spawning processes...). Docker already applies a default profile (visible via `docker info | grep seccomp`).

We wrote a custom profile blocking the `mkdir` syscall:

```bash
docker run --rm python-good mkdir /tmp/testdir && echo "mkdir worked"
# mkdir worked

docker run --rm --security-opt seccomp=/tmp/seccomp-test.json python-good mkdir /tmp/testdir
# mkdir: cannot create directory '/tmp/testdir': Operation not permitted
```

Three modes: `SCMP_ACT_ALLOW` (allow), `SCMP_ACT_ERRNO` (return error), `SCMP_ACT_KILL` (kill the process).

---

## 10. AppArmor

Where seccomp restricts system calls, AppArmor restricts **file, network, and resource access** — not "which tools you can use" but "which rooms you can enter." Docker already applies a `docker-default` profile.

We wrote a custom profile blocking a file from being read:

```bash
docker run --rm -v /tmp/secret.txt:/tmp/secret.txt python-good cat /tmp/secret.txt
# secret data

docker run --rm --security-opt apparmor=docker-python-test \
  -v /tmp/secret.txt:/tmp/secret.txt python-good cat /tmp/secret.txt
# cat: /tmp/secret.txt: Permission denied
```

|           | Seccomp                | AppArmor                        |
| --------- | ---------------------- | ------------------------------- |
| Restricts | System calls           | File, network, resource access  |
| In Docker | Default profile active | `docker-default` profile active |

---

## 11. Kaniko

`docker build` needs the Docker daemon, and the daemon runs with root privileges — giving a Kubernetes pod root access is a serious security risk. **Kaniko** solves this by never connecting to the Docker daemon at all, running as a normal user inside a CI/CD pod.

```bash
docker run --rm -v $(pwd):/workspace -v ~/.docker/config.json:/kaniko/.docker/config.json:ro \
  gcr.io/kaniko-project/executor:latest \
  --context /workspace --dockerfile /workspace/Dockerfile.good \
  --destination alifurkanaltuntas/python-good:kaniko
# Pushed index.docker.io/alifurkanaltuntas/python-good@sha256:5ace3811c...
```

**Proof:** we counted the Docker daemon's image count before and after running Kaniko — it never changed, meaning the daemon was never involved. Kaniko's own image doesn't even have a shell (trying `which docker` failed to find `sh`).

---

## 12. Jib

Jib is for Java only. Kaniko works with any language but requires a Dockerfile — Jib doesn't even need one, building and pushing directly as a Maven plugin.

```bash
mvn compile jib:build
# BUILD SUCCESS — Built and pushed image as alifurkanaltuntas/jib-demo:v1.0
```

|            | Kaniko   | Jib        |
| ---------- | -------- | ---------- |
| Language   | Any      | Java only  |
| Dockerfile | Required | Not needed |

---

## 13. Falco (Runtime Security)

Trivy scans images before build (static). Falco is more like a security guard watching live camera feeds — it watches what happens **inside a running container** and flags it as suspicious or not (via eBPF, tracking kernel syscalls in real time).

We opened a shell inside a container, and Falco caught it:

```
Notice A shell was spawned in a container with an attached terminal
  user=root process=sh command=sh
  container_image_repository=python-good container_image_tag=latest
```

Which container, which user, which command, exact timestamp — all captured. In production these alerts can be routed to Slack/PagerDuty.

---

## 14. SBOM (Syft + Grype)

Trivy scans on demand — it needs the image to exist. SBOM works differently: it can be used for retrospective reporting, and when a vulnerability is found in one package, you can check which other images contain it too.

```bash
syft python-good --output spdx-json > sbom.json
# 127 packages catalogued

grype sbom:./sbom.json
# 207 vulnerability matches (7 critical, 36 high, 70 medium, 7 low)
```

**Syft** = take a photo (list the components), **Grype** = look at that photo and find the problems. The `sbom.json` file persists — even if the image is deleted, this file can still be scanned retrospectively.

---

---

## 📊 Summary

| Technique              | What It Provides                                               |
| ---------------------- | -------------------------------------------------------------- |
| Distroless image       | 94MB, no shell, zero CRITICAL vulnerabilities                  |
| Read-only filesystem   | Disk can't be written to, no malicious files can be dropped    |
| Resource limits        | Server resources can't be exhausted, OOM Kill                  |
| BuildKit               | Parallel build + secret mount                                  |
| Hadolint               | Catches Dockerfile mistakes before build                       |
| Image tag immutability | Pinning with SHA — same result every build                     |
| docker-bench-security  | Scans Docker's installation against CIS benchmark — 117 checks |
| Image signing (Cosign) | Signs images — tampering shows "no signatures found"           |
| Seccomp                | Restricts system calls                                         |
| AppArmor               | Restricts file/network/resource access                         |
| Kaniko                 | Daemon-less, rootless image builds in CI/CD                    |
| Jib                    | Dockerfile-less builds for Java                                |
| Falco                  | Real-time detection of anomalous runtime behavior              |
| SBOM (Syft+Grype)      | Persistent, retrospectively scannable component inventory      |

---

ℹ️ _All tests were performed on a real Ubuntu VPS._
