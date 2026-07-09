# 🐳 Docker — Hands-On Tests

In this document, the concepts learned were tested in a real environment.

---

## Environment

```bash
mkdir -p ~/docker-practice && cd ~/docker-practice
```

Two files created:

```bash
cat > app.py << 'EOF'
print("Merhaba Docker!")
EOF

cat > requirements.txt << 'EOF'
requests==2.31.0
EOF
```

---

## 1. Image Size Comparison — Single Stage vs Multi-Stage

### Why We Wrote Two Dockerfiles

Two different Dockerfiles were created — `Dockerfile.bad` (written incorrectly) and `Dockerfile.good` (written correctly). The goal was comparison: to see the size difference between two images that do the same job.

### Dockerfile.bad — Wrong Approach

```dockerfile
FROM python:3.11
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

3 problems:

1. `COPY . .` first → layer caching broken, pip install re-runs whenever code changes
2. No multi-stage build → dev tools end up in the final image
3. `python:3.11` → unnecessarily large image

```bash
docker build -f Dockerfile.bad -t python-bad .
docker images python-bad
```

```
IMAGE               ID             DISK USAGE   CONTENT SIZE
python-bad:latest   1ba39ff23b0b       1.62GB          415MB
```

### Dockerfile.good — Correct Approach

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

### Comparison

|                 | Disk Usage | Content Size |
| --------------- | ---------- | ------------ |
| **python-bad**  | 1.62GB     | 415MB        |
| **python-good** | 191MB      | 46.5MB       |

**8x smaller** — just from multi-stage build and slim base image.

### Does It Work?

```bash
docker run python-good
# Merhaba Docker!
```

---

## 2. Layer Caching Test

### Why We Used `time`

`time` measures how long a command takes to run. Used to see the difference between a cached build and an uncached one in actual numbers.

### Test 1 — Only Code Changes

`app.py` updated, `requirements.txt` unchanged:

```bash
echo 'print("Merhaba Docker! Güncellendi.")' > app.py
time docker build -f Dockerfile.good -t python-good .
```

Output:

```
=> CACHED [builder 2/3] COPY requirements.txt .          0.0s
=> CACHED [builder 3/3] RUN pip install --user -r ...    0.0s  ⚡
=> CACHED [stage-1 2/3] COPY --from=builder ...          0.0s
```

`pip install` didn't run again — requirements.txt didn't change, served from cache. Only the `app.py` copy step was re-run.

### Test 2 — requirements.txt Changes

```bash
echo "requests==2.28.0" > requirements.txt
time docker build -f Dockerfile.good -t python-good .
```

This time:

```
=> CACHED [builder 1/3] FROM python:3.11        ← base image from cache ✅
=> COPY requirements.txt .                       ← changed, rebuilt
=> RUN pip install --user -r requirements.txt    ← not CACHED, ran again
```

Base images came from cache but `pip install` ran again — because requirements.txt changed.

**Conclusion:** Least-changing instructions at the top, most-changing at the bottom — this is the foundation of layer caching.

---

## 3. Docker Compose — Volumes and Networks

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

### How Networks Work

`networks` is written in two places:

```yaml
# 1. Definition — at the bottom
networks:
  frontend:
  backend:

# 2. Assignment — under each service
services:
  web:
    networks:
      - frontend
      - backend # on both networks
  db:
    networks:
      - backend # internal only
```

**Office floor analogy:**

- `frontend` → ground floor, open to the outside
- `backend` → upper floor, staff only

`web` is on both floors — can talk to the outside and to the database. `db` is only upstairs — nobody can reach it directly from outside.

No IP addresses written — just names. Docker handles the IP assignment and DNS automatically.

### Volume Test

```bash
docker compose up -d
sudo ls ~/compose-practice/pgdata   # data is here

docker compose down   # container removed
docker compose up -d  # restarted
sudo ls ~/compose-practice/pgdata   # data still here ✅
```

Container removed and restarted — but the `pgdata` folder stayed on the host, data wasn't lost.

**Migration scenario:** If the container moves to another machine, the volume becomes inaccessible — it stayed on the original host. This is why databases in production are stored somewhere external (S3, NFS), not on the same machine as the container. The volume always needs to be reachable.

### External Test

```bash
curl http://localhost:8081          # from inside ✅
curl http://91.151.88.38:8081       # from outside ✅
```

Both returned Nginx's welcome page.

---

ℹ️ _All tests performed on a real Ubuntu VDS._
