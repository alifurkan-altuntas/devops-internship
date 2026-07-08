# 🐳 Docker — Images, Containers, Dockerfile, and Image Optimization

I’d only used Docker for `hello-world` before. In this phase I learned the core concepts, how to write a Dockerfile, and image optimization techniques.

-----

## Core Concepts

### Virtual Machine vs Container

**Virtual Machine:** Like a real computer — desktop environment, audio drivers, printer support, dozens of unused services, and its own kernel. Heavy and slow to start.

**Container:** A service will use it, not a user. Only what that service needs to run is inside — nothing more. The kernel comes from the host; it’s not inside the container.

```
Virtual Machine:
  [Application]
  [Full OS — including kernel]
  [Hypervisor]
  [Host OS]

Container:
  [Application + libraries]
  [Docker Engine]
  [Host OS kernel — shared]
```

### What an Image Is

A template — everything the application needs to run is inside (libraries, tools, config files, minimal OS). But it’s not running, just waiting.

Images can be pulled from Docker Hub — think of it like npm, with ready-made packages. Or you can build your own with a Dockerfile.

### What a Container Is

A running copy made from an image. When you run `docker run`, a container is created from the image. You can spin up as many containers as you want from the same image — each runs independently.

```
Image = mold/template (not running)
Container = a copy cast from that mold (running)
```

### Dockerfile vs docker-compose.yml

**Dockerfile** → describes how to build a single image. One Dockerfile = one image.

**docker-compose.yml** → describes how to run multiple containers together.

```yaml
openresty:
    build: .            # use Dockerfile, build image
postgres:
    image: postgres:15  # use ready-made image, no Dockerfile
```

- `build: .` → build image from Dockerfile
- `image: postgres:15` → pull ready-made image from Docker Hub

In the OpenResty phase we only wrote a Dockerfile for OpenResty because we needed to add pgmoon. The ready-made images were enough for PostgreSQL, MySQL, and Redis.

-----

## Dockerfile Optimization

### 1. Choosing the Right Base Image

```dockerfile
FROM ubuntu    # 70MB+ — desktop tools, dozens of unused services
FROM alpine    # 5MB   — minimal Linux only
```

Alpine is tiny because there’s nothing unnecessary — no UI, no unused services. Only what the service needs to run.

Security matters too: the fewer tools inside an image, the less someone can do if they get into the container.

### 2. Multi-Stage Build

**Writing** an application requires a dev kit. **Running** it only requires a runtime. These aren’t the same thing.

```
Dev kit (JDK, pip, gcc):  write + compile + run
Runtime (JRE, python):    run only
```

Without multi-stage build, the dev kit ends up in the final image — hundreds of MB of unnecessary weight. Multi-stage build solves this:

```dockerfile
# Stage 1 — temporary workspace (the scaffolding)
FROM openjdk:17 AS builder
COPY . .
RUN mvn package              # compiled → app.jar created
                             # this stage is done, discarded 🗑️

# Stage 2 — final image (the building)
FROM openjdk:17-jre-slim     # runtime only, much smaller
COPY --from=builder app.jar . # take only app.jar from builder
CMD ["java", "-jar", "app.jar"]
```

**`AS builder`** → give this stage a name, reference it later with `--from=builder`.

**`COPY --from=builder`** → take only this file from the builder stage.

When the second `FROM` appears, Docker automatically says “stage 1 is done” — the dev kit, source code, and temporary files are discarded. The final image only has runtime + compiled application.

Like scaffolding on a construction site: once the building is done, the scaffolding comes down. The building stays.

### 3. Layer Caching

Every `RUN`, `COPY`, and `ADD` instruction creates a separate **layer**. On each build, Docker checks “did this layer change?”:

- Unchanged → taken from cache ⚡
- Changed → everything from that point on is rebuilt 🔄

**Rule: least-changing instructions at the top, most-changing at the bottom**

```dockerfile
# Wrong order
FROM python:3.11-slim
COPY . .                              # changes when code changes
RUN pip install -r requirements.txt  # runs again unnecessarily
CMD ["python", "app.py"]

# Correct order
FROM python:3.11-slim
COPY requirements.txt .              # rarely changes
RUN pip install -r requirements.txt  # served from cache ⚡
COPY . .                             # changes often, goes last
CMD ["python", "app.py"]
```

When only the code changes:

- `COPY requirements.txt` → unchanged → cache ✅
- `pip install` → unchanged → cache ✅ (minutes saved)
- `COPY . .` → changed → rebuilt 🔄

### 4. Combining RUN Instructions

Every `RUN` instruction is a layer — a snapshot. Writing them separately means adding a new step each time — it shouldn’t be like that. Keep it compact, do two things in one step.

If you add something and delete it in a separate instruction, the deletion creates a new layer but the previous layer still exists.

```dockerfile
# Wrong — 3 layers, curl is still stored inside
RUN apk add curl        # layer 1: curl added (+20MB)
RUN curl ... -o app     # layer 2: file downloaded
RUN apk del curl        # layer 3: curl deleted, but layer 1 still exists!

# Correct — 1 layer, net result 0MB added
RUN apk add curl && \
    curl ... -o app && \
    apk del curl
```

One `RUN` instruction = one layer = curl came and went, never made it into the image.

-----

## 📊 Summary

|Technique                    |What It Achieves                    |
|-----------------------------|------------------------------------|
|Alpine/slim base image       |Small starting point                |
|Multi-stage build            |Dev kit never enters the final image|
|Layer caching (correct order)|Faster build times                  |
|Combining RUN instructions   |No unnecessary layers               |

-----

ℹ️ *Conceptual learning — hands-on examples in the next phase.*
