# 🐳 Docker Alternatives — Hands-On Tests

This document covers Podman setup and comparison tests against Docker.

---

## 1. Installing Podman

```bash
sudo apt update
sudo apt install -y podman
podman --version
```

```
podman version 4.9.3
```

(A "Pending kernel upgrade" warning also appeared at the end of setup — the running kernel differed from the expected version, would update on reboot; didn't affect the tests.)

The install also created systemd units like `podman.service` and `podman.socket` — at first glance this seemed to contradict the "daemonless" claim, which we investigated in the next test.

---

## 2. Testing the Daemonless Claim

```bash
systemctl status podman.service
```

```
○ podman.service - Podman API Service
     Active: inactive (dead) since Wed 2026-07-22 11:07:45 UTC; 1min 26s ago
   Duration: 5.216s
TriggeredBy: ● podman.socket
```

```bash
systemctl status podman.socket
```

```
● podman.socket - Podman API Socket
     Active: active (listening) since Wed 2026-07-22 11:07:40 UTC; 2min 38s ago
     Listen: /run/podman/podman.sock (Stream)
```

`podman.service` only ran for 5.2 seconds then stopped — it's **socket-activated**, meaning it doesn't run continuously, it only wakes up when a request comes in. Comparing with Docker:

```bash
systemctl status docker
```

```
● docker.service - Docker Application Container Engine
     Active: active (running) since Wed 2026-07-01 07:32:24 UTC; 3 weeks 0 days ago
   Main PID: 958 (dockerd)
      Tasks: 106
     Memory: 235.6M
```

Docker started **3 weeks ago** and is still running continuously (`dockerd`, PID 958). As proof, we stopped Podman's socket entirely and tried running a container:

```bash
sudo systemctl stop podman.socket
podman run hello-world
```

```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

`podman run` worked fine even with the socket down — the CLI doesn't need that service at all (the service only exists for an optional REST API).

---

## 3. Testing the Rootless Claim

We ran the same container in both Docker and Podman, and checked who the **host machine** sees as the owner of the process.

**Docker:**

```bash
docker run -d --name root-test python-good sleep 300
ps aux | grep sleep
```

```
root      385024  1.6  0.0   3012  1788 ?        Ss   11:14   0:00 sleep 300
```

**Podman:** (used `docker.io/library/alpine` since Docker's local image store isn't visible to Podman)

```bash
podman run -d --name root-test-podman docker.io/library/alpine sleep 300
ps aux | grep sleep
```

```
altun     385153  4.7  0.0   1628  1028 ?        Ss   11:15   0:00 sleep 300
```

|                        | Docker   | Podman    |
| ---------------------- | -------- | --------- |
| Inside the container   | root     | root      |
| Owner seen by the host | **root** | **altun** |

In both cases the process runs as root inside the container since no `USER` was set, but the host sees something completely different — Podman uses a **user namespace** to map the container's root to a regular user on the host (`UID mapping`). In a container escape scenario, Docker gives root on the host; Podman only gives regular-user privileges.

```bash
podman rm -f root-test-podman
docker rm -f root-test
```

---

## 4. Build Speed Test

The first attempt showed Podman **2.2x slower** (26.3s vs 11.7s) — but it wasn't a fair test: Docker's `python:3.11-slim` layer was already cached, while Podman was pulling from scratch. Podman also builds in OCI format by default, so we got a `HEALTHCHECK is not supported for OCI image format` warning, fixed with `--format docker`.

An obstacle came up along the way: an old Docker Hub access token in `~/.docker/config.json` was read by Podman and rejected (`unauthorized`). Cleared it with `docker logout`.

For a fair retest, both sides' image stores were fully wiped (`docker system prune -af`, `podman rmi -a -f`) — `docker system prune -af` alone reclaimed 3.153GB, only removing stopped containers/unused images; running sites (nginx, openresty) were unaffected.

```bash
time docker build --no-cache -f Dockerfile.clean -t python-clean-docker .
# real 1m19.326s

time podman build --no-cache --format docker -f Dockerfile.clean -t python-clean-podman .
# real 1m25.856s
```

**Result: ~8% difference** — likely measurement noise, since the tests ran at different times and a single layer download (236MB) alone took 46.4 seconds, meaning the result depended heavily on network conditions at that moment.

**Important discovery:** Docker's and Podman's image stores are **completely isolated** from each other — neither sees the other's cache. That's why Podman looked "very fast" in the first test — it was actually reusing its own earlier cache.

---

## 📊 Summary

| Test        | Finding                                                                                       |
| ----------- | --------------------------------------------------------------------------------------------- |
| Daemonless  | Podman's service is socket-activated, only wakes on request; Docker stays active continuously |
| Rootless    | Docker's container shows as root on the host, Podman's shows as a regular user                |
| Build speed | ~8% difference, within measurement-noise range — no meaningful performance gap                |
| Image store | Docker and Podman are fully isolated, neither sees the other's cache                          |

---

ℹ️ _All tests were performed on a real Ubuntu VPS._
