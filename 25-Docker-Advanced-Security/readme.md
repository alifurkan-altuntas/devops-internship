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

## 📊 Özet

| Teknik                 | Ne Sağlıyor                                    |
| ---------------------- | ---------------------------------------------- |
| Distroless image       | 94MB, shell yok, CRITICAL açık sıfır           |
| Read-only filesystem   | Diske yazılamıyor, zararlı dosya bırakılamıyor |
| Resource limits        | Sunucu kaynakları tüketilemez, OOM Kill        |
| BuildKit paralel build | Bağımsız stage'ler aynı anda — daha hızlı      |
| BuildKit secret mount  | Şifreler image history'ye girmiyor             |
| Hadolint               | Build öncesi Dockerfile hataları yakalanıyor   |
| Image tag immutability | SHA ile sabitlemek — her build aynı sonuç      |

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde yapılmıştır._
