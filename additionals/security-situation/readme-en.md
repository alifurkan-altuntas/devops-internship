# 🚨 A Real Security Incident — DNS Rebinding and an Open Forward Proxy (SSRF)

While continuing the Docker Advanced Examples phase, my disk filled to 100% and I couldn't even log into the admin panel. Investigating, I discovered that a leftover configuration from our July 1 forward proxy experiment (Phase 19) had been abused by an attacker for weeks.

---

## How I Noticed

Even `mkdir` returned "No space left on device." Checked disk usage with `df -h /`: `/dev/sda2 40G 38G 0 100% /`.

```bash
docker system df
```

Docker itself only held ~6.5GB, that wasn't the problem. Dug in layer by layer with `du -h --max-depth=1 /`:

```
/var         27G
  /var/log   21G
    /var/log/nginx   20G
```

`ls -lh /var/log/nginx/` showed `access.log.1` at **9.2GB** and `error.log.1` at **4.5GB** — generated in a single day.

---

## What I Found

```bash
sudo tail -50 /var/log/nginx/error.log
```

Hundreds of lines per second, all repeating the same request:

```
2026/08/13 10:49:13 [error] ... limiting requests ... request: "GET /M?N=ZZJ26070054541&QO=4440 HTTP/1.0", host: "www.zzjjyzx.com:80", referrer: "https://www.youtube.com/"
```

`www.zzjjyzx.com` is a random/meaningless domain — a classic click-fraud botnet pattern. Requests were coming from both `127.0.0.1` (the server itself) and an external IP (`134.195.157.224`).

---

## Root Cause — Step by Step

**First suspicion:** the old `proxy_pass http://localhost:8080;` in the `default` server block — fixed it (`return 444;`), but traffic didn't stop.

**Second clue:** `error.log` showed `upstream: "http://127.0.0.1:80/..."` — nginx was making requests to itself on port 80. The `default` block no longer did that, so it had to be coming from somewhere else.

**Proof:**

```bash
dig +short www.zzjjyzx.com
# 127.0.0.1
```

The attacker's domain was **deliberately** set to resolve to `127.0.0.1` (DNS rebinding).

```bash
sudo ss -tlnp | grep 8888
# LISTEN 0 511 0.0.0.0:8888 ... nginx
```

`forward-proxy.conf` (our July 1 Squid alternative experiment, port 8888) was still **open to the entire internet**, `ufw` was disabled, no restrictions at all:

```nginx
server {
    listen 8888;
    resolver 8.8.8.8;
    location / {
        proxy_pass http://$http_host$request_uri;
    }
}
```

**Attack flow:**

1. The attacker connects to port 8888 (our open forward proxy)
2. Sends a request with the `Host: www.zzjjyzx.com` header
3. This domain's DNS points to `127.0.0.1`
4. `proxy_pass http://$http_host$request_uri;` causes the server to make a request **to itself**
5. Our server was used as a relay/open proxy to make the bot's traffic look "legitimate" — and this loop filled the logs and exhausted the disk

---

## The Fix

```bash
sudo rm /etc/nginx/sites-enabled/forward-proxy.conf
sudo nginx -t && sudo systemctl reload nginx
sudo gzip /var/log/nginx/access.log.1
sudo gzip /var/log/nginx/error.log.1
```

Four minutes later the logging stopped completely, disk usage dropped to 68% (13GB free).

---

## Lessons Learned

1. **A service set up "just for learning" doesn't stay safe just because it was "only a test"** — we forgot to disable `forward-proxy.conf`, and it sat live, open to the entire internet, for weeks.
2. **DNS rebinding is a real threat** — nothing stops a domain from pointing to `127.0.0.1`, DNS doesn't check that.
3. **A fix like `return 444;` might not solve the whole problem** — if there are multiple server blocks/config files, all of them need to be checked.
4. **A small `docker system df` output doesn't mean the disk issue isn't Docker-related, or isn't** — finding the actual source required going layer by layer (`/`, `/var`, `/var/log`, `/var/log/nginx`).

---

ℹ️ _This incident happened and was resolved in real time, on a real Ubuntu VPS._
