# 🐳 Docker Advanced Security — Hands-On Tests

This document covers the hands-on tests behind the concepts explained in readme.md.

---

## 1. Distroless — No Shell Test

```bash
cd ~/docker-practice
docker build -f Dockerfile.distroless -t python-distroless .
docker images python-bad python-good python-nonroot python-distroless
```

```
python-distroless:latest   347c7ab05d9a   94.1MB   23.3MB
```

### Whoami and Shell Test

```bash
docker run python-distroless whoami
docker run -it python-distroless sh
# /usr/bin/python3.13: can't open file '//sh': No such file or directory
```

### Vulnerability Count via Trivy

```bash
trivy image python-distroless --severity HIGH,CRITICAL 2>/dev/null | grep "^Total:"
```

| Image             | HIGH+CRITICAL |
| ----------------- | ------------- |
| python-distroless | 21            |

CRITICAL dropped from 3 to 0 — no critical vulnerabilities in distroless.

---

## 2. Resource Limits — OOM Kill Test

```bash
docker run --memory 10m --memory-swap 10m python-good python3 -c "
data = []
for i in range(1000000):
    data.append('x' * 1000)
"
echo "Exit code: $?"
```

```
Exit code: 137
```

We set "RAM + swap total max 10MB." RAM filled up, no swap available — nowhere left to go, the kernel killed the container → exit code 137.

### Read-Only + Distroless Together

Even if `/tmp` is made writable in RAM, distroless has no shell — no tools to run malicious code with. Combining read-only and distroless gives double protection.

---

## 3. BuildKit — Questioning the Parallel Build Claim

The first test used the same base image (`python:3.11-slim`) for both stages — no difference showed up:

```bash
time docker build --no-cache -f Dockerfile.good -t test-normal .
# real 0m10.2s
time DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.good -t test-buildkit .
# real 0m0.8s (came from cache, not real parallelism)
```

This result wasn't accepted at face value — it was questioned: "Clearing the cache removed the speed advantage, and BuildKit can't speed up network-bound downloads." The test was redone with different base images (`python:3.11-slim` + `python:3.10-slim`):

```bash
time docker build --no-cache -f Dockerfile.parallel -t test-normal .
# real 0m41.372s
time DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.parallel -t test-buildkit .
# real 0m31.861s
```

```bash
docker build --progress=plain --no-cache -f Dockerfile.parallel -t test-buildkit2 . 2>&1 | grep -E "^#[56]"
```

Steps `#5` and `#6` started at the same time in the logs — parallelism proved.

**Conclusion:** We questioned it before accepting it, tested it, and proved it under the right conditions.

---

## 4. docker-bench-security — Full Run

```bash
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
sudo sh docker-bench-security.sh 2>&1 | head -80
sudo sh docker-bench-security.sh 2>/dev/null | tail -20
```

```
Checks: 117
Score: 7
```

**PASS:** Docker version up to date (29.6.0), logging level 'info', no insecure registries, Swarm mode disabled (auto-PASS).

**WARN:** No separate partition for containers, audit logging not enabled for Docker files, inter-container network not restricted on default bridge.

This environment is a dev/test environment, so the WARNs don't apply to us directly — in production they'd need to be addressed one by one.

---

## 5. Cosign — Signing and Tampering Test

```bash
wget https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64 && sudo mv cosign-linux-amd64 /usr/local/bin/cosign

cosign generate-key-pair
# cosign.key (private) / cosign.pub (public)
```

```bash
docker tag python-good alifurkanaltuntas/python-good:v1.0
docker push alifurkanaltuntas/python-good:v1.0

IMAGE_SHA=$(docker inspect alifurkanaltuntas/python-good:v1.0 --format '{{index .RepoDigests 0}}')
cosign sign --key cosign.key $IMAGE_SHA
cosign verify --key cosign.pub $IMAGE_SHA 2>/dev/null | python3 -m json.tool
```

### Tampering Test

We acted like an attacker — pushed a different (bad) image to the same tag:

```bash
docker tag python-bad alifurkanaltuntas/python-good:v1.0
docker push alifurkanaltuntas/python-good:v1.0

cosign verify --key cosign.pub alifurkanaltuntas/python-good:v1.0
# Error: no signatures found
```

The image content changed, the SHA changed, the old signature no longer matched. Without Cosign, no one would have noticed at step 3.

---

## 6. Seccomp and AppArmor — Proof Tests

### Seccomp — Blocking mkdir

```bash
docker inspect python-good | grep -i seccomp   # empty — doesn't mean it's off
docker info | grep -i seccomp                   # seccomp — active

cat > /tmp/seccomp-test.json << 'EOF'
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "syscalls": [{"names": ["mkdir"], "action": "SCMP_ACT_ERRNO"}]
}
EOF

docker run --rm python-good mkdir /tmp/testdir && echo "mkdir worked"
docker run --rm --security-opt seccomp=/tmp/seccomp-test.json python-good mkdir /tmp/testdir
echo "Exit code: $?"
```

```
mkdir worked
mkdir: cannot create directory '/tmp/testdir': Operation not permitted
Exit code: 1
```

### AppArmor — Blocking File Read

```bash
sudo aa-status | head -5
# 134 profiles loaded, 41 in enforce mode, including docker-default

sudo nano /etc/apparmor.d/docker-python-test
```

```
#include <tunables/global>
profile docker-python-test flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  file, network, capability,
  deny /tmp/secret.txt r,
}
```

```bash
sudo apparmor_parser -r /etc/apparmor.d/docker-python-test
echo "secret data" > /tmp/secret.txt

docker run --rm -v /tmp/secret.txt:/tmp/secret.txt python-good cat /tmp/secret.txt
# secret data

docker run --rm --security-opt apparmor=docker-python-test \
  -v /tmp/secret.txt:/tmp/secret.txt python-good cat /tmp/secret.txt
# cat: /tmp/secret.txt: Permission denied
```

---

## 7. Kaniko — Proving It Doesn't Use the Docker Daemon

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -v ~/.docker/config.json:/kaniko/.docker/config.json:ro \
  gcr.io/kaniko-project/executor:latest \
  --context /workspace --dockerfile /workspace/Dockerfile.good \
  --destination alifurkanaltuntas/python-good:kaniko --no-push
```

```
INFO[0136] Skipping push to container registry due to --no-push flag
```

The question "how do we know it's not using Docker" was answered with 3 pieces of proof:

**Proof 1 — Kaniko's log terminology:** instead of the `sha256:xxx: Pull complete` lines seen in `docker build`, Kaniko uses its own terms: `Resolved base name`, `Taking snapshot`, `Unpacking rootfs`.

**Proof 2 — Looking for a shell:**

```bash
docker run --rm --entrypoint sh gcr.io/kaniko-project/executor:latest -c "which docker || echo 'docker yok'"
# exec: "sh": executable file not found in $PATH
```

No shell exists in the Kaniko image at all.

**Proof 3 (most conclusive) — Image count:**

```bash
docker info | grep "Images"   # count before Kaniko
# ... run Kaniko with --no-push ...
docker info | grep "Images"   # count after Kaniko
```

The count never changed — the Docker daemon was never involved.

Real push:

```bash
docker run --rm -v $(pwd):/workspace -v ~/.docker/config.json:/kaniko/.docker/config.json:ro \
  gcr.io/kaniko-project/executor:latest \
  --context /workspace --dockerfile /workspace/Dockerfile.good \
  --destination alifurkanaltuntas/python-good:kaniko
```

```
Pushing image to alifurkanaltuntas/python-good:kaniko
Pushed index.docker.io/alifurkanaltuntas/python-good@sha256:5ace3811c...
```

---

## 8. Jib — Dockerfile-less Build

```xml
<plugin>
  <groupId>com.google.cloud.tools</groupId>
  <artifactId>jib-maven-plugin</artifactId>
  <version>3.4.0</version>
  <configuration>
    <to><image>alifurkanaltuntas/jib-demo:v1.0</image></to>
  </configuration>
</plugin>
```

```bash
mvn compile jib:build
```

```
BUILD SUCCESS
Built and pushed image as alifurkanaltuntas/jib-demo:v1.0
```

No Dockerfile was written, `docker build` wasn't used, the Docker daemon wasn't used.

**Jib's layer strategy:** JRE (unchanging) → dependencies (rarely change) → class files (change often). When code changes, only the last layer is rebuilt.

---

## 9. Falco — Setup and Debugging Process

```bash
curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | \
  sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | \
  sudo tee -a /etc/apt/sources.list.d/falcosecurity.list
sudo apt-get update && sudo apt-get install -y falco

sudo systemctl status falco
# Active: active (running) — syscalls monitored via modern_ebpf
```

### First Attempt — No Alert

```bash
sudo journalctl -fu falco &
docker run --rm -it python-good sh
# ran cat /etc/passwd, whoami, ls /tmp
```

```bash
sudo journalctl -u falco --since "5 minutes ago" | grep -i "shell\|passwd\|Notice\|Warning"
# (empty)
```

The cause was investigated: Falco was writing to stdout, not to logs — `journalctl -fu falco` wasn't showing it.

### Correct Approach — Service Log

```bash
sudo journalctl -u falco-modern-bpf --no-pager | tail -30
```

```
15:04:21.179308896: Notice A shell was spawned in a container with an attached terminal
  evt_type=execve user=root process=sh command=sh
  container_id=98eb5017d870 container_name=pedantic_hugle
  container_image_repository=python-good container_image_tag=latest
```

Caught — which container, which user, which command, exact timestamp.

---

## 10. SBOM — Syft and Grype Setup

```bash
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin
syft python-good --output table | head -40
```

```
✔ Cataloged contents
  ├── Packages       [127 packages]
  ├── Executables    [758 executables]
  ├── File metadata  [2,722 locations]
```

```bash
syft python-good --output spdx-json > sbom.json
du -h sbom.json
cat sbom.json | python3 -m json.tool | wc -l
```

```
2.4M    sbom.json
89764
```

```bash
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin
grype sbom:./sbom.json | head -20
```

```
✔ Scanned for vulnerabilities   [207 vulnerability matches]
  ├── by severity: 7 critical, 36 high, 70 medium, 7 low, 51 negligible
  └── by status:   40 fixed, 167 not-fixed
```

**Real-world scenario:** If a critical vulnerability comes out for `certifi`, there's no need to touch the image at all — `syft python-good --output json | grep certifi` immediately shows which version is in which image. Even if the image is deleted, `sbom.json` remains and can be scanned retrospectively with Grype.

---

ℹ️ _All tests were performed on a real Ubuntu VPS._
