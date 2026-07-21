# 🔒 Docker İleri Seviye Güvenlik

24. fazda temel güvenlik konularını öğrendik — non-root container, .dockerignore, Trivy. Bu fazda daha ileri seviye konulara geçtik.

---

## 1. Distroless Image

Distroless image içerisinde herhangi bir distro bulunmayan, sadece core özelliklere sahip, işletim sistemi niteliği taşımayacak kadar küçük bir image. Alpine'dan farkı şu: Alpine'da shell var, komut var. Distroless'ta bunlar da yok — sadece uygulamanın çalışması için gereken runtime var.

Python için distroless: `gcr.io/distroless/python3` — Google tarafından geliştiriliyor.

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

Distroless'ta `CMD` de değişiyor — shell yok, `python app.py` yerine direkt `app.py` yazılıyor.

### Test — Shell Yok

```bash
docker run -it python-distroless sh
# /usr/bin/python3.13: can't open file '//sh': No such file or directory
```

Shell yazmaya çalışınca Python "sh diye bir script bulamadım" dedi — shell bile yok. Birisi sızsa bile komut çalıştıracak araç yok.

### Karşılaştırma

| Image            | Boyut   | Güvenlik Açığı   | Shell  |
| ---------------- | ------- | ---------------- | ------ |
| python:3.11      | 1.62 GB | 412              | ✅ var |
| python:3.11-slim | 190 MB  | 28               | ✅ var |
| distroless       | 94 MB   | 21 (CRITICAL: 0) | ❌ yok |

---

## 2. Read-Only Filesystem

`--read-only` ile container'ın dosya sistemini salt okunur yapılır — diske yazma olmaz, sadece okuma ve çalıştırma olur.

```bash
# Normal container — diske yazabilir
docker run python-good sh -c "echo 'test' > /tmp/test.txt"
# test

# Read-only container — yazamaz
docker run --read-only python-good sh -c "echo 'test' > /tmp/test.txt"
# sh: 1: cannot create /tmp/test.txt: Read-only file system
```

Birisi container'a sızıp zararlı dosya bırakmak, script indirmek veya config değiştirmek istese yapamıyor.

### --tmpfs ile RAM'e Yazma

Uygulama geçici dosya yazması gerekiyorsa `/tmp` RAM'de yazılabilir yapılabilir:

```bash
docker run --read-only --tmpfs /tmp python-good sh -c "echo 'temp' > /tmp/test.txt && cat /tmp/test.txt"
# temp
```

RAM'e yazabilir ama diske yazamaz. Distroless ile birlikte kullanılınca: diske de yazamıyor, RAM'e yazsa bile çalıştıracak araç yok.

---

## 3. Resource Limits

Olası bir izinsiz erişim veya hacklenme durumunda hacker'ın sunucuyu yüke sokmasını, zararlı yazılımlar ve kod blokları çalıştırmasını engellemek için kaynak limiti koyulur. Sunucunun kendi ihtiyacı dışında kaynak verilmek istenmez.

### Memory Limiti

```bash
docker run --memory 10m --memory-swap 10m python-good python3 -c "
data = []
for i in range(1000000):
    data.append('x' * 1000)
"
# Exit code: 137 — OOM Kill
```

- **`--memory 10m`** → RAM max 10MB. Ama swap varsa diske taşır, program devam eder.
- **`--memory-swap 10m`** → RAM + Swap toplam max 10MB. Swap da kapalı, yer kalmayınca kernel container'ı öldürür.

**Swap nedir:** RAM dolunca işletim sistemi verileri diske taşır, sanki RAM'miş gibi kullanır. Swap'ı da kısıtlayınca gerçekten yer kalmıyor, container ölüyor — exit code 137 (OOM Kill).

### CPU Limiti

```bash
docker run --cpus 0.5 python-good python3 app.py
```

Container maksimum yarım CPU core kullanabilir.

---

## 4. BuildKit

BuildKit, Docker'ın yeni nesil build motoru. İki önemli özelliği var: paralel build ve secret mount.

### Paralel Build

BuildKit birbirine bağımlı olmayan stage'leri aynı anda build eder.

İlk testlerde aynı base image (`python:3.11-slim`) kullandık — fark görünmedi. Neden? Docker aynı image için serialize ediyor, iki stage aynı anda aynı image'ı kullanamıyor. Sorguladık, araştırdık, farklı base image ile tekrar test ettik:

```bash
# Dockerfile.parallel — stage1: python:3.11-slim, stage2: python:3.10-slim

# Normal build — sırayla yapıyor
time docker build --no-cache -f Dockerfile.parallel -t test-normal .
# real 0m41.372s

# BuildKit — paralel yapıyor
time DOCKER_BUILDKIT=1 docker build --no-cache -f Dockerfile.parallel -t test-buildkit .
# real 0m31.861s
```

**10 saniye fark** — iki bağımsız stage paralel çalıştı. `--progress=plain` ile loglara bakınca `#5` ve `#6` numaralı adımların aynı anda başladığını gördük — kanıtlandı.

**Öğrenilen:** Paralel build sadece farklı base image kullanan bağımsız stage'lerde fark yaratır. Aynı base image veya birbirine bağımlı stage'lerde avantaj az olur. Asıl fark büyük CI/CD ortamlarında görünür. Kabul etmeden önce sorguladık, test ettik, kanıtladık.

### Secret Mount

Normal `--build-arg` ile şifre image history'ye giriyor:

```bash
docker build --build-arg SECRET=gizlisifre123 -f Dockerfile.secret-bad -t test .
docker history test
# ARG SECRET=gizlisifre123   ← herkes görebilir!
```

BuildKit secret mount ile şifre image'a girmiyor:

```dockerfile
FROM python:3.11-slim
RUN --mount=type=secret,id=mysecret \
    cat /run/secrets/mysecret
```

```bash
echo "gizlisifre123" > /tmp/mysecret.txt

DOCKER_BUILDKIT=1 docker build \
  --secret id=mysecret,src=/tmp/mysecret.txt \
  -f Dockerfile.secret-good \
  -t test-secret-good .

docker history test-secret-good | grep gizli
# (çıktı yok — şifre image'a girmedi) ✅
```

Şifre sadece o RUN adımında `/run/secrets/mysecret` olarak erişilebilir, build bitince siliniyor.

---

## 5. Hadolint — Dockerfile Linter

Hadolint, Dockerfile'daki hataları ve kötü pratikleri build öncesi bulan araç.

```bash
docker run --rm -i hadolint/hadolint < Dockerfile.good
```

### Bulunan Sorunlar ve Çözümler

**DL3045 — WORKDIR tanımlı değilken COPY**

```dockerfile
# Kötü
COPY requirements.txt .   # "." neresi?

# İyi
WORKDIR /app
COPY requirements.txt .
```

**DL3042 — pip cache dizini**

```dockerfile
# Kötü — cache image'a giriyor, boyut şişiyor
RUN pip install -r requirements.txt

# İyi
RUN pip install --no-cache-dir -r requirements.txt
```

Düzeltmelerden sonra:

```bash
docker run --rm -i hadolint/hadolint < Dockerfile.good
# (çıktı yok — temiz) ✅
```

CI/CD pipeline'a eklenince her Dockerfile push edildiğinde otomatik kontrol eder.

---

## 6. Image Tag Immutability

`latest` kullanmak güncelleme geldiğinde sürüm değişmesine ve çalışmamasına sebep olabilir. Diyelim ki bir kez kuruldu, başkası kurmak istedi — son sürümü kurması gerekiyor ve uyumsuzluk çıkabilir. Bu yüzden sürüm yazılıyor, hatta sürüm de değil — SHA imzası yazılıyor.

```bash
# SHA bul
docker inspect python:3.11-slim --format '{{index .RepoDigests 0}}'
# python@sha256:e031123e3d85762b141ad1cbc56452ba69c6e722ebf2f042cc0dc86c47c0d8b3
```

```dockerfile
# Kötü — her build farklı image çekebilir
FROM python:latest
FROM python:3.11-slim

# İyi — her build aynı image, SHA değişmez
FROM python:3.11-slim@sha256:e031123e3d85762b141ad1cbc56452ba69c6e722ebf2f042cc0dc86c47c0d8b3
```

---

## 7. docker-bench-security

Trivy image ve container güvenliği için çalışıyordu. Docker kurulumunun kendisi için güvenlik taraması yapmak için docker-bench-security kullandık. Firmalara dışarıdan denetlemeye gelenler gibi — sistemi CIS (Center for Internet Security) standartlarına göre inceliyor. Hangi ayarlar doğru, hangileri kritik, hangileri düşük önem derecesinde — production ortamına göre tek tek kontrol ediyor.

**CIS nedir:** Center for Internet Security — dünya genelinde güvenlik uzmanları, şirketler ve araştırmacıların gerçek saldırı verileri ve uzman konsensüsüyle oluşturduğu endüstri standardı güvenlik kuralları. Docker, Kubernetes, Linux gibi sistemler için ayrı ayrı benchmark yayınlıyorlar. Periyodik güncelleniyor — biz CIS Docker Benchmark 1.6.0 kullandık.

### Kurulum ve Çalıştırma

```bash
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
sudo sh docker-bench-security.sh 2>/dev/null | tail -20
```

### Sonuç Tipleri

| Tip    | Anlamı                     |
| ------ | -------------------------- |
| [PASS] | Güvenli ✅                 |
| [WARN] | Dikkat edilmesi gereken ⚠️ |
| [NOTE] | Manuel kontrol gerekli     |
| [INFO] | Sadece bilgi               |

### Sonuçlarımız

```
Checks: 117
Score: 7
```

**PASS olanlar:**

- Docker versiyonu güncel (29.6.0) ✅
- Logging seviyesi 'info' ✅
- Güvensiz registry kullanılmıyor ✅
- Swarm mode kapalı — Swarm kontrolleri otomatik PASS ✅

**WARN olanlar:**

- Container'lar için ayrı partition yok
- Docker dosyaları için audit logging açık değil
- Default bridge üzerinde container'lar arası network kısıtlanmamış

**Not:** Bu ortam geliştirme/test ortamı. WARN olan konular production ortamında tek tek kapatılması gereken açıklar. Kör güven olmaz — CIS benchmark bir başlangıç noktası, sistemi anlayan kişi neyin gerekli olduğuna kendisi karar verir.

---

## 8. Image Signing (Cosign)

Container image'larını kendi imzamızla imzaladık ki doğruluğunu ve değiştirilmediğini teyit edebilelim. HTTPS sertifikası gibi — sitenin gerçek sahibinden geldiğini ve içeriğin değiştirilmediğini kanıtlıyor.

**Cosign** — Sigstore projesi tarafından geliştirilen açık kaynak image imzalama aracı. Kubernetes ekosisteminde standart haline geliyor.

### Kurulum

```bash
wget https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
```

### Key Pair Oluşturma

```bash
cosign generate-key-pair
# cosign.key → private key (imzalamak için)
# cosign.pub → public key (doğrulamak için)
```

### Image'ı İmzalama

```bash
# Önce image'ı registry'e push et
docker tag python-good alifurkanaltuntas/python-good:v1.0
docker push alifurkanaltuntas/python-good:v1.0

# SHA ile imzala — tag yerine SHA kullanmak daha güvenli
IMAGE_SHA=$(docker inspect alifurkanaltuntas/python-good:v1.0 --format '{{index .RepoDigests 0}}')
cosign sign --key cosign.key $IMAGE_SHA
```

Tag ile imzalarsak Cosign uyarı veriyor: "tag başka bir image'a yönlendirilebilir, SHA kullan." SHA değiştirilemez — image değiştirilirse SHA değişir.

### İmza Doğrulama

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

### Değiştirilmiş Image Testi

```bash
# Saldırgan gibi davrandık — aynı tag'e farklı image push ettik
docker tag python-bad alifurkanaltuntas/python-good:v1.0
docker push alifurkanaltuntas/python-good:v1.0

# Doğrulama başarısız — image değiştirilmiş!
cosign verify --key cosign.pub alifurkanaltuntas/python-good:v1.0
# Error: no signatures found
```

Image'ın içeriği değişti, SHA değişti, imza eşleşmedi — Cosign "bu image değiştirilmiş" dedi.

**Gerçek dünya senaryosu:** Saldırgan registry'e sızıp image'ı zararlı kodla değiştirdi. Başka sunucu `cosign verify` yapınca "imza eşleşmiyor" aldı — image çalıştırılmadı. Cosign olmadan kimse fark etmezdi.

---

## 9. Seccomp

"Secure Computing" kısaltması — Linux kernel'in bir özelliği, container'ın kernel'e yaptığı sistem çağrılarını (system call: dosya oku, ağa bağlan...) kısıtlıyor. Docker varsayılan olarak zaten bir profil uyguluyor (`docker info | grep seccomp` ile görülüyor).

Özel bir profil yazıp `mkdir` çağrısını engelledik:

```bash
docker run --rm python-good mkdir /tmp/testdir && echo "mkdir çalıştı"
# mkdir çalıştı

docker run --rm --security-opt seccomp=/tmp/seccomp-test.json python-good mkdir /tmp/testdir
# mkdir: cannot create directory '/tmp/testdir': Operation not permitted
```

3 mod var: `SCMP_ACT_ALLOW` (izin ver), `SCMP_ACT_ERRNO` (hata döndür), `SCMP_ACT_KILL` (process'i öldür).

---

## 10. AppArmor

Seccomp sistem çağrılarını kısıtlarken, AppArmor **dosya, ağ ve kaynak erişimini** kısıtlıyor — "hangi araçları kullanabilirsin" değil "hangi odalara girebilirsin." Docker'da `docker-default` profili zaten aktif.

Özel bir profille bir dosyayı okumayı engelledik:

```bash
docker run --rm -v /tmp/secret.txt:/tmp/secret.txt python-good cat /tmp/secret.txt
# gizli veri

docker run --rm --security-opt apparmor=docker-python-test \
  -v /tmp/secret.txt:/tmp/secret.txt python-good cat /tmp/secret.txt
# cat: /tmp/secret.txt: Permission denied
```

|             | Seccomp                 | AppArmor                       |
| ----------- | ----------------------- | ------------------------------ |
| Ne kısıtlar | Sistem çağrıları        | Dosya, ağ, kaynak erişimi      |
| Docker'da   | Varsayılan profil aktif | `docker-default` profili aktif |

---

## 11. Kaniko

`docker build` Docker daemon'a ihtiyaç duyuyor, daemon root yetkisiyle çalışıyor — Kubernetes pod'una root vermek güvenlik riski. **Kaniko** bunu Docker daemon'a hiç bağlanmadan çözüyor, CI/CD pod'unda normal kullanıcı olarak çalışıyor.

```bash
docker run --rm -v $(pwd):/workspace -v ~/.docker/config.json:/kaniko/.docker/config.json:ro \
  gcr.io/kaniko-project/executor:latest \
  --context /workspace --dockerfile /workspace/Dockerfile.good \
  --destination alifurkanaltuntas/python-good:kaniko
# Pushed index.docker.io/alifurkanaltuntas/python-good@sha256:5ace3811c...
```

**Kanıtladık:** Kaniko çalışmadan önce ve sonra Docker daemon'ın image sayısı sayıldı, hiç değişmedi — Docker daemon işleme hiç dahil olmadı. Kaniko image'ının içinde shell bile yok (`which docker` denendiğinde `sh` bulunamadı).

---

## 12. Jib

Jib Java içindi, sadece Java. Kaniko her dilde çalışıyordu ama Dockerfile gerektiriyordu — Jib Dockerfile'a bile ihtiyaç duymuyor, doğrudan Maven plugin'i olarak build edip push ediyor.

```bash
mvn compile jib:build
# BUILD SUCCESS — Built and pushed image as alifurkanaltuntas/jib-demo:v1.0
```

|            | Kaniko  | Jib         |
| ---------- | ------- | ----------- |
| Dil        | Her dil | Sadece Java |
| Dockerfile | Gerekli | Gerekmiyor  |

---

## 13. Falco (Runtime Security)

Trivy image'ı build öncesi (statik) tarıyor. Falco bir nevi canlı kameraları izleyen güvenlik görevlisi gibi — container **çalışırken** içinde olanları izliyor, tehlikeli ya da değil olarak sınıflandırıyor (eBPF ile kernel system call'larını izleyerek).

Container içinde shell açtık, Falco yakaladı:

```
Notice A shell was spawned in a container with an attached terminal
  user=root process=sh command=sh
  container_image_repository=python-good container_image_tag=latest
```

Hangi container, hangi kullanıcı, hangi komut, tam timestamp — hepsi görünüyor. Production'da bu alertler Slack/PagerDuty'ye gönderilebilir.

---

## 14. SBOM (Syft + Grype)

Trivy anlık tarama — image olması lazım. SBOM geriye dönük raporlama için kullanılabilir; güvenlik sürecinde bir açık tespit edildiğinde diğer hangi image'larda o açığın olduğuna bakılabilir.

```bash
syft python-good --output spdx-json > sbom.json
# 127 paket kataloglandı

grype sbom:./sbom.json
# 207 vulnerability matches (7 critical, 36 high, 70 medium, 7 low)
```

**Syft** = fotoğraf çek (bileşenleri listele), **Grype** = o fotoğrafa bak, sorunluları bul. `sbom.json` kalıcı — image silinse bile bu dosya üzerinden geriye dönük tarama yapılabiliyor.

---

## 📊 Özet

| Teknik                 | Ne Sağlıyor                                                          |
| ---------------------- | -------------------------------------------------------------------- |
| Distroless image       | 94MB, shell yok, CRITICAL açık sıfır                                 |
| Read-only filesystem   | Diske yazılamıyor, zararlı dosya bırakılamıyor                       |
| Resource limits        | Sunucu kaynakları tüketilemez, OOM Kill                              |
| BuildKit               | Paralel build + secret mount                                         |
| Hadolint               | Build öncesi Dockerfile hataları yakalanıyor                         |
| Image tag immutability | SHA ile sabitlemek — her build aynı sonuç                            |
| docker-bench-security  | Docker kurulumunu CIS benchmark'a göre tarıyor — 117 kontrol         |
| Image signing (Cosign) | Image imzalanıyor — değiştirilirse "no signatures found"             |
| Seccomp                | Sistem çağrılarını kısıtlar                                          |
| AppArmor               | Dosya/ağ/kaynak erişimini kısıtlar                                   |
| Kaniko                 | Docker daemon ve root olmadan CI/CD pod'unda image build             |
| Jib                    | Java için Dockerfile'sız build                                       |
| Falco                  | Runtime'da anormal davranışları gerçek zamanlı tespit                |
| SBOM (Syft+Grype)      | Kalıcı bileşen listesi — image silinse bile geriye dönük taranabilir |

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde yapılmıştır._
