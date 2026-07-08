# 🐳 Docker — Image, Container, Dockerfile ve Image Optimizasyonu

Docker’ı daha önce sadece `hello-world` ile test etmiştim. Bu fazda temel kavramları, Dockerfile yazımını ve image optimizasyon tekniklerini öğrendim.

-----

## Temel Kavramlar

### Sanal Makine vs Container

**Sanal Makine:** Gerçek bir bilgisayar gibi — masaüstü, ses sürücüsü, yazıcı desteği, kullanılmayan onlarca servis, ve en önemlisi kendi kernel’i. Ağır ve yavaş başlıyor.

**Container:** Bir kullanıcı kullanmayacak, bir servis kullanacak. İçinde sadece o servisin çalışması için gerekenler var — fazlası yok. Kernel host’tan geliyor, container içinde yok.

```
Sanal Makine:
  [Uygulama]
  [Tam İşletim Sistemi — kernel dahil]
  [Hypervisor]
  [Host OS]

Container:
  [Uygulama + kütüphaneler]
  [Docker Engine]
  [Host OS kernel — paylaşılıyor]
```

### Image Nedir

Şablon — içinde uygulamanın çalışması için gereken her şey var (kütüphaneler, araçlar, config dosyaları, minimal OS). Ama çalışmıyor, sadece bekliyor.

Image’lar Docker Hub’dan çekilebilir — npm gibi düşün, hazır paketler var. Ya da Dockerfile ile kendin oluşturabilirsin.

### Container Nedir

Image’dan çalıştırılan kopya. `docker run` deyince image’dan bir container oluşuyor. Aynı image’dan istediğin kadar container açabilirsin — hepsi birbirinden bağımsız çalışır.

```
Image = kalıp/şablon (çalışmıyor)
Container = o kalıptan çalıştırılan kopya (çalışıyor)
```

### Dockerfile vs docker-compose.yml

**Dockerfile** → tek bir image nasıl oluşturulur, onu tarif eder. Bir Dockerfile = bir image.

**docker-compose.yml** → birden fazla container’ı birlikte nasıl çalıştıracağını tarif eder.

```yaml
openresty:
    build: .          # Dockerfile kullan, image oluştur
postgres:
    image: postgres:15  # hazır image kullan, Dockerfile yok
```

- `build: .` → Dockerfile’dan image oluştur
- `image: postgres:15` → Docker Hub’dan hazır image çek

OpenResty fazında sadece OpenResty için Dockerfile yazdık çünkü pgmoon eklememiz gerekiyordu. PostgreSQL, MySQL, Redis için hazır image yeterliydi.

-----

## Dockerfile Optimizasyonu

### 1. Doğru Base Image Seçmek

```dockerfile
FROM ubuntu    # 70MB+ — masaüstü araçları, onlarca gereksiz servis
FROM alpine    # 5MB   — sadece minimal Linux
```

Alpine çok küçük çünkü gereksiz hiçbir şey yok — kullanıcı arayüzü yok, kullanılmayan servisler yok. Sadece servisin çalışması için gerekenler var.

Güvenlik açısından da önemli: image içinde ne kadar az araç olursa, birisi container’a sızarsa o kadar az şey kullanabilir.

### 2. Multi-Stage Build

Bir uygulamayı **yazmak** için dev kit lazım, **çalıştırmak** için sadece runtime lazım — ikisi aynı şey değil.

```
Dev kit (JDK, pip, gcc):  yazmak + derlemek + çalıştırmak
Runtime (JRE, python):    sadece çalıştırmak
```

Eski yöntemde dev kit final image’a giriyordu — yüzlerce MB gereksiz yük. Multi-stage build bunu çözüyor:

```dockerfile
# 1. aşama — geçici çalışma alanı (iskele)
FROM openjdk:17 AS builder
COPY . .
RUN mvn package              # derlendi → app.jar oluştu
                             # bu aşama bitti, atıldı 🗑️

# 2. aşama — final image (bina)
FROM openjdk:17-jre-slim     # sadece runtime, çok daha küçük
COPY --from=builder app.jar . # builder'dan sadece app.jar'ı al
CMD ["java", "-jar", "app.jar"]
```

**`AS builder`** → bu aşamaya isim ver, sonraki aşamada `--from=builder` ile referans ver.

**`COPY --from=builder`** → sadece builder aşamasından bu dosyayı al.

1. `FROM` gelince Docker otomatik olarak “1. aşama bitti” diyor — dev kit, kaynak kod, geçici dosyalar atılıyor. Final image’da sadece runtime + derlenmiş uygulama var.

İnşaattaki iskele gibi: bina tamamlanınca iskele sökülüyor, bina kalıyor.

### 3. Layer Caching

Her `RUN`, `COPY`, `ADD` satırı ayrı bir **layer** (katman) oluşturuyor. Docker her build’de “bu layer değişti mi?” diye bakıyor:

- Değişmemişse → cache’den alıyor ⚡
- Değiştiyse → o satırdan itibaren her şeyi yeniden yapıyor 🔄

**Kural: En az değişen → en üste, en çok değişen → en alta**

```dockerfile
# Yanlış sıra
FROM python:3.11-slim
COPY . .                              # kod değişince bu layer değişiyor
RUN pip install -r requirements.txt  # gereksiz yere tekrar çalışıyor
CMD ["python", "app.py"]

# Doğru sıra
FROM python:3.11-slim
COPY requirements.txt .              # nadiren değişiyor
RUN pip install -r requirements.txt  # cache'den geliyor ⚡
COPY . .                             # sık değişiyor, en sona
CMD ["python", "app.py"]
```

Sadece kod değiştirince:

- `COPY requirements.txt` → değişmedi → cache ✅
- `pip install` → değişmedi → cache ✅ (dakikalar kazanıldı)
- `COPY . .` → değişti → yeniden yapıldı 🔄

### 4. RUN Satırlarını Birleştirme

Her `RUN` satırı bir layer = bir fotoğraf. Sırayla yazmak demek her seferinde bir adım eklemek demek — bunun olmaması lazım, kompakt hale getirmek gerekiyor, bir adımda 2 işi yapalım.

Bir şeyi ekleyip ayrı satırda silersen, silme işlemi yeni layer oluşturuyor ama önceki layer hâlâ duruyor.

```dockerfile
# Yanlış — 3 layer, curl hâlâ içerde saklı
RUN apk add curl        # layer 1: curl eklendi (+20MB)
RUN curl ... -o app     # layer 2: dosya indirildi
RUN apk del curl        # layer 3: curl silindi ama layer 1 hâlâ var!

# Doğru — 1 layer, net sonuç 0MB ekleme
RUN apk add curl && \
    curl ... -o app && \
    apk del curl
```

Tek `RUN` satırı = tek layer = curl geldi gitti, image’a girmedi.

-----

## 📊 Özet

|Teknik                     |Ne Sağlıyor                   |
|---------------------------|------------------------------|
|Alpine/slim base image     |Küçük başlangıç noktası       |
|Multi-stage build          |Dev kit final image’a girmiyor|
|Layer caching (doğru sıra) |Build süresi kısalıyor        |
|RUN satırlarını birleştirme|Gereksiz layer oluşmuyor      |

-----

ℹ️ *Kavramsal öğrenme — uygulamalı örnekler sonraki fazda.*
