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

## 📊 Summary

| Technique               | What It Achieves                                   |
| ----------------------- | -------------------------------------------------- |
| Distroless image        | 94MB, no shell, zero CRITICAL vulnerabilities      |
| Read-only filesystem    | No disk writes, malicious files can't be dropped   |
| Resource limits         | Server resources can't be exhausted, OOM Kill      |
| BuildKit parallel build | Independent stages run simultaneously — faster     |
| BuildKit secret mount   | Secrets never enter image history                  |
| Hadolint                | Dockerfile errors caught before building           |
| Image tag immutability  | SHA pinning — every build produces the same result |

---

ℹ️ _All tests performed on a real Ubuntu VPS._
