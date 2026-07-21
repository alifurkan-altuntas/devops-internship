# 🐳 Docker İleri Seviye Güvenlik — Uygulamalı Testler

Bu belgede kavramsal öğrenilen konular gerçek ortamda test edildi.

---

## 1. Distroless — Shell Yok Testi

```bash
cd ~/docker-practice
docker build -f Dockerfile.distroless -t python-distroless .
docker images python-bad python-good python-nonroot python-distroless
```

```
python-distroless:latest   347c7ab05d9a   94.1MB   23.3MB
```

### Shell ve Whoami Testi

```bash
docker run python-distroless whoami
docker run -it python-distroless sh
# /usr/bin/python3.13: can't open file '//sh': No such file or directory
```

### Trivy ile Açık Sayısı

```bash
trivy image python-distroless --severity HIGH,CRITICAL 2>/dev/null | grep "^Total:"
```

| Image             | HIGH+CRITICAL |
| ----------------- | ------------- |
| python-distroless | 21            |

CRITICAL 3 → 0 düştü — distroless'ta kritik açık yok.

---

## 2. Resource Limits — OOM Kill Testi

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

"RAM + Swap toplam max 10MB" dedik. RAM doldu, swap da yok — hiçbir yere sığamadı, kernel "bu container çok yer istiyor, öldüreyim" dedi → exit code 137.

### Read-Only + Distroless Birlikte

Sızılsa bile `/tmp` RAM'de yazılabilir yapılsa da, distroless kullanıldığı için shell yok — çalıştıracak araç yok. Read-only + distroless birlikte kullanılınca ikili koruma sağlanıyor.

---

## 3. BuildKit — Paralel Build Sorgulaması

İlk testte aynı base image (`python:3.11-slim`) kullanan iki stage denendi — fark görünmedi:

```bash
time docker build --no-cache -f Dockerfile.good -t test-normal .
# real 0m10.2s
time DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.good -t test-buildkit .
# real 0m0.8s (cache'den geldi, gerçek paralellik değil)
```

Bu sonuç kabul edilmedi — sorgulandı: "Cache silince hız avantajı kalmadı, network bottleneck BuildKit'i hızlandıramaz." Farklı base image'larla (`python:3.11-slim` + `python:3.10-slim`) tekrar test edildi:

```bash
time docker build --no-cache -f Dockerfile.parallel -t test-normal .
# real 0m41.372s
time DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.parallel -t test-buildkit .
# real 0m31.861s
```

```bash
docker build --progress=plain --no-cache -f Dockerfile.parallel -t test-buildkit2 . 2>&1 | grep -E "^#[56]"
```

`#5` ve `#6` adımlarının aynı anda başladığı loglardan görüldü — paralellik kanıtlandı.

**Sonuç:** Kabul etmeden önce sorguladık, test ettik, farklı koşullarda kanıtladık.

---

## 4. docker-bench-security — Tam Çalıştırma

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

**PASS olanlar:** Docker versiyonu güncel (29.6.0), logging seviyesi 'info', güvensiz registry yok, Swarm mode kapalı (otomatik PASS).

**WARN olanlar:** Container'lar için ayrı partition yok, audit logging açık değil, default bridge üzerinde container'lar arası network kısıtlanmamış.

Bu ortam test/geliştirme ortamı olduğu için WARN'lar bizi bağlamıyor — production olsaydı tek tek kapatılması gerekirdi.

---

## 5. Cosign — İmzalama ve Sahtekârlık Testi

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

### Sahtekârlık Testi

Saldırgan gibi davranıldı — aynı tag'e farklı (kötü) image push edildi:

```bash
docker tag python-bad alifurkanaltuntas/python-good:v1.0
docker push alifurkanaltuntas/python-good:v1.0

cosign verify --key cosign.pub alifurkanaltuntas/python-good:v1.0
# Error: no signatures found
```

Image içeriği değişti, SHA değişti, eski imza artık eşleşmiyor. Cosign olmadan 3. adımda kimse fark etmezdi.

---

## 6. Seccomp ve AppArmor — Kanıt Testleri

### Seccomp — mkdir Engelleme

```bash
docker inspect python-good | grep -i seccomp   # boş — ama olmadığı anlamına gelmiyor
docker info | grep -i seccomp                   # seccomp — aktif

cat > /tmp/seccomp-test.json << 'EOF'
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "syscalls": [{"names": ["mkdir"], "action": "SCMP_ACT_ERRNO"}]
}
EOF

docker run --rm python-good mkdir /tmp/testdir && echo "mkdir çalıştı"
docker run --rm --security-opt seccomp=/tmp/seccomp-test.json python-good mkdir /tmp/testdir
echo "Exit code: $?"
```

```
mkdir çalıştı
mkdir: cannot create directory '/tmp/testdir': Operation not permitted
Exit code: 1
```

### AppArmor — Dosya Okuma Engelleme

```bash
sudo aa-status | head -5
# 134 profiles are loaded, 41 in enforce mode, docker-default dahil

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
echo "gizli veri" > /tmp/secret.txt

docker run --rm -v /tmp/secret.txt:/tmp/secret.txt python-good cat /tmp/secret.txt
# gizli veri

docker run --rm --security-opt apparmor=docker-python-test \
  -v /tmp/secret.txt:/tmp/secret.txt python-good cat /tmp/secret.txt
# cat: /tmp/secret.txt: Permission denied
```

---

## 7. Kaniko — Docker Daemon Kullanmadığının Kanıtı

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

"Docker kullanmadığını nasıl anladık ki" sorusuna 3 kanıtla cevap arandı:

**Kanıt 1 — Kaniko'nun log terimleri:** `docker build`'de görülen `sha256:xxx: Pull complete` yerine, Kaniko `Resolved base name`, `Taking snapshot`, `Unpacking rootfs` gibi kendi terimlerini kullanıyor.

**Kanıt 2 — Shell arama:**

```bash
docker run --rm --entrypoint sh gcr.io/kaniko-project/executor:latest -c "which docker || echo 'docker yok'"
# exec: "sh": executable file not found in $PATH
```

Kaniko image'ında shell bile yok.

**Kanıt 3 (en net) — Image sayısı:**

```bash
docker info | grep "Images"   # Kaniko öncesi say
# ... Kaniko --no-push ile çalıştır ...
docker info | grep "Images"   # Kaniko sonrası tekrar say
```

Sayı hiç değişmedi — Docker daemon işleme hiç dahil olmadı.

Gerçek push:

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

## 8. Jib — Dockerfile'sız Build

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

Dockerfile yazılmadı, `docker build` kullanılmadı, Docker daemon kullanılmadı.

**Jib'in katman stratejisi:** JRE (değişmez) → bağımlılıklar (nadiren değişir) → class dosyaları (sık değişir). Kod değişince sadece 3. katman yeniden build ediliyor.

---

## 9. Falco — Kurulum ve Debug Süreci

```bash
curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | \
  sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | \
  sudo tee -a /etc/apt/sources.list.d/falcosecurity.list
sudo apt-get update && sudo apt-get install -y falco

sudo systemctl status falco
# Active: active (running) — modern_ebpf ile syscall izleniyor
```

### İlk Deneme — Alert Gelmedi

```bash
sudo journalctl -fu falco &
docker run --rm -it python-good sh
# cat /etc/passwd, whoami, ls /tmp çalıştırıldı
```

```bash
sudo journalctl -u falco --since "5 minutes ago" | grep -i "shell\|passwd\|Notice\|Warning"
# (boş)
```

Sebep araştırıldı: Falco loglara değil stdout'a yazıyordu, `journalctl -fu falco` bunu göstermiyordu.

### Doğru Yöntem — Servis Logu

```bash
sudo journalctl -u falco-modern-bpf --no-pager | tail -30
```

```
15:04:21.179308896: Notice A shell was spawned in a container with an attached terminal
  evt_type=execve user=root process=sh command=sh
  container_id=98eb5017d870 container_name=pedantic_hugle
  container_image_repository=python-good container_image_tag=latest
```

Yakalandı — hangi container, hangi kullanıcı, hangi komut, tam timestamp.

---

## 10. SBOM — Syft ve Grype Kurulumu

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

**Gerçek senaryo:** `certifi` için kritik bir açık çıksa, image'a hiç gerek kalmadan `syft python-good --output json | grep certifi` ile hangi image'da hangi versiyonun olduğu anında görülebiliyor. Image silinse bile `sbom.json` kalıyor, Grype ile geriye dönük taranabiliyor.

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde yapılmıştır._
