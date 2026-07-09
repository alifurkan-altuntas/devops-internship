# 🐳 Docker — Uygulamalı Testler

Bu belgede kavramsal öğrenilen konular gerçek ortamda test edildi.

---

## Ortam

```bash
mkdir -p ~/docker-practice && cd ~/docker-practice
```

İki dosya oluşturuldu:

```bash
cat > app.py << 'EOF'
print("Merhaba Docker!")
EOF

cat > requirements.txt << 'EOF'
requests==2.31.0
EOF
```

---

## 1. Image Boyutu Karşılaştırması — Single Stage vs Multi-Stage

### Neden İki Dockerfile Yazdık

İki farklı Dockerfile oluşturduk — `Dockerfile.bad` (yanlış yazılmış) ve `Dockerfile.good` (doğru yazılmış). Amaç karşılaştırma yapmak: aynı işi yapan iki image'ın boyut farkını görmek.

### Dockerfile.bad — Yanlış Yazım

```dockerfile
FROM python:3.11
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

3 sorun var:

1. `COPY . .` önce → layer caching bozuk, kod değişince pip install tekrar çalışır
2. Multi-stage build yok → dev araçları final image'a giriyor
3. `python:3.11` → gereksiz büyük image

```bash
docker build -f Dockerfile.bad -t python-bad .
docker images python-bad
```

```
IMAGE               ID             DISK USAGE   CONTENT SIZE
python-bad:latest   1ba39ff23b0b       1.62GB          415MB
```

### Dockerfile.good — Doğru Yazım

```dockerfile
FROM python:3.11 AS builder
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.11-slim
COPY --from=builder /root/.local /root/.local
COPY app.py .
CMD ["python", "app.py"]
```

```bash
docker build -f Dockerfile.good -t python-good .
docker images python-good
```

```
IMAGE                ID             DISK USAGE   CONTENT SIZE
python-good:latest   7b5881ac2002        191MB         46.5MB
```

### Karşılaştırma

|                 | Disk Usage | Content Size |
| --------------- | ---------- | ------------ |
| **python-bad**  | 1.62GB     | 415MB        |
| **python-good** | 191MB      | 46.5MB       |

**8 kat daha küçük** — sadece multi-stage build ve slim image ile.

### Çalışıyor mu?

```bash
docker run python-good
# Merhaba Docker!
```

---

## 2. Layer Caching Testi

### `time` Komutu Neden Kullandık

`time` komutun ne kadar sürdüğünü ölçer. Cache'li build ile cache'siz build arasındaki farkı sayılarla görmek için kullandık.

### Test 1 — Sadece Kod Değişince

`app.py` güncellendi, `requirements.txt` değişmedi:

```bash
echo 'print("Merhaba Docker! Güncellendi.")' > app.py
time docker build -f Dockerfile.good -t python-good .
```

Çıktı:

```
=> CACHED [builder 2/3] COPY requirements.txt .          0.0s
=> CACHED [builder 3/3] RUN pip install --user -r ...    0.0s  ⚡
=> CACHED [stage-1 2/3] COPY --from=builder ...          0.0s
```

`pip install` tekrar çalışmadı — requirements.txt değişmedi, cache'den geldi. Sadece `app.py` kopyalama yeniden yapıldı.

### Test 2 — requirements.txt Değişince

```bash
echo "requests==2.28.0" > requirements.txt
time docker build -f Dockerfile.good -t python-good .
```

Bu sefer:

```
=> CACHED [builder 1/3] FROM python:3.11        ← base image cache'den ✅
=> COPY requirements.txt .                       ← değişti, yeniden yapıldı
=> RUN pip install --user -r requirements.txt    ← CACHED değil, tekrar çalıştı
```

Base image'lar cache'den geldi ama `pip install` yeniden çalıştı — requirements.txt değişti.

**Sonuç:** En az değişen üste, en çok değişen alta — bu kural layer caching'in temelidir.

---

## 3. Docker Compose — Volumes ve Networks

### docker-compose.yml

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8081:80"
    networks:
      - frontend
      - backend

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: testdb
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
    volumes:
      - ./pgdata:/var/lib/postgresql/data
    networks:
      - backend

networks:
  frontend:
  backend:
```

### Networks Nasıl Çalışıyor

`networks` bloğu iki yerde yazılıyor:

```yaml
# 1. Tanımlama — en altta
networks:
  frontend:
  backend:

# 2. Atama — her servis altında
services:
  web:
    networks:
      - frontend
      - backend # her iki ağda
  db:
    networks:
      - backend # sadece iç ağda
```

**Şirketteki kat örneği:**

- `frontend` → zemin kat, dışarıya açık
- `backend` → üst kat, sadece çalışanlar

`web` her iki katta — dışarıyla ve veritabanıyla konuşabiliyor. `db` sadece üst katta — dışarıdan kimse direkt erişemiyor.

IP yazmıyoruz — sadece isim yazıyoruz, Docker IP'yi ve DNS'i otomatik hallediyor.

### Volume Testi

```bash
docker compose up -d
sudo ls ~/compose-practice/pgdata   # veriler burada

docker compose down   # container silindi
docker compose up -d  # yeniden başlatıldı
sudo ls ~/compose-practice/pgdata   # veriler hâlâ burada ✅
```

Container silindi, yeniden başlatıldı — ama `pgdata` klasörü host'ta kaldı, veriler kaybolmadı.

**Taşıma senaryosu:** Container başka bir cihaza taşınırsa volume erişilemez — volume host'ta kaldı. Bu yüzden production'da veritabanları uzak bir yerde tutulur (S3, NFS), container ile aynı yerde değil. Volume her zaman erişilebilir olmak zorunda.

### Dışarıdan Test

```bash
curl http://localhost:8081          # içeriden ✅
curl http://91.151.88.38:8081       # dışarıdan ✅
```

Her ikisi de Nginx'in karşılama sayfasını döndürdü.

---

ℹ️ _Tüm testler gerçek bir Ubuntu VDS üzerinde yapılmıştır._
