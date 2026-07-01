# 🌐 Nginx Deep Dive — Reverse Proxy, Path Management, and Forward Proxy

✅ **Status: Complete.** Reverse proxy setup, path-based routing, path rewrite, path blocking, and forward proxy (Squid) — all tested hands-on on a real server.

---

## 1. What a Reverse Proxy Is

Nginx, acting as a **reverse proxy**, receives incoming requests and forwards them to backend services. The user never sees how many services are running behind it, or on which ports — they only ever talk to Nginx.

**Why it's used:**

- Backend services' ports/IPs stay hidden from the outside world with that privacy happens
- A single entry point (port 80/443) manages multiple services
- Load balancing, SSL termination, rate limiting all happen at Nginx — the backend doesn't carry that load

**Example:** You walk into a large company building. You can't go directly to the offices — the receptionist (Nginx) asks: "Who were you here to see?" They know which office is where and direct you there. You never learn the building's internal layout. And if that office is closed for the day, the receptionist says "I can't reach them" — that's exactly **502 Bad Gateway.**

### When You See 502 Bad Gateway

502 means the receptionist is there, but the office they're trying to connect you to is closed. The troubleshooting sequence:

1. Is internet connectivity working?
2. Is the backend service actually running?

Nginx is up, but the service behind it is not — that's 502.

---

## 2. Basic Reverse Proxy Setup

### Environment

Python's built-in HTTP server was used to simulate a backend:

```bash
mkdir -p /tmp/backend
echo "<h1>Backend Service Running - Port 8080</h1>" > /tmp/backend/index.html
cd /tmp/backend && python3 -m http.server 8080 &
```

### Nginx Configuration

```nginx
location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### What Each Directive Does

**`proxy_pass http://localhost:8080`** — forward the incoming request to port 8080.

**`proxy_set_header Host $host`** — tell the backend which domain the request originally came to. When one Nginx serves multiple domains, the backend needs to know which one the request was actually for.

**`proxy_set_header X-Real-IP $remote_addr`** — pass the real user IP to the backend.

**Example (without X-Real-IP):** The receptionist walks you to the office, but the person inside doesn't know who you are or where you came from — the receptionist just said "someone's here" without saying who. Without `X-Real-IP`, the backend sees every request as coming from `127.0.0.1` (Nginx itself) and has no way to identify the real user.

### Verification

```bash
sudo nginx -t && sudo systemctl reload nginx
```

Request to port 80 from outside (Windows):

```
PS C:\> curl http://91.151.88.38
<h1>Backend Service Running - Port 8080</h1>
```

The user never saw port 8080 — only port 80, with Nginx handling the rest behind the scenes.

The backend log confirmed requests now arrive from `127.0.0.1` (Nginx), not the user's IP directly:

```
127.0.0.1 - - [01/Jul/2026 08:54:05] "GET / HTTP/1.0" 200 -
127.0.0.1 - - [01/Jul/2026 08:54:17] "GET / HTTP/1.0" 200 -
```

---

## 3. Path-Based Routing

Different paths routed to different backend services through the same Nginx instance.

### Environment

Two more services started:

```bash
mkdir -p /tmp/users && echo "<h1>Users Service</h1>" > /tmp/users/index.html
cd /tmp/users && python3 -m http.server 3000 &

mkdir -p /tmp/computers && echo "<h1>Computers Service</h1>" > /tmp/computers/index.html
cd /tmp/computers && python3 -m http.server 4000 &
```

### Nginx Configuration

```nginx
location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}

location /users/ {
    proxy_pass http://localhost:3000/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}

location /computers/ {
    proxy_pass http://localhost:4000/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### Test Results

```
PS C:\> curl http://91.151.88.38/
<h1>Backend Service Running - Port 8080</h1>

PS C:\> curl http://91.151.88.38/users/
<h1>Users Service</h1>

PS C:\> curl http://91.151.88.38/computers/
<h1>Computers Service</h1>
```

The receptionist now routes different requests to different offices — `/users/` goes to floor 3 (port 3000), `/computers/` goes to floor 4 (port 4000).

---

## 4. Path Rewrite

The trailing `/` in `proxy_pass` controls whether path rewriting happens.

### The Difference

```
proxy_pass http://localhost:3000    →  /users/list  →  localhost:3000/users/list  (404)
proxy_pass http://localhost:3000/   →  /users/list  →  localhost:3000/list        (200)
```

**Example:** Without the trailing slash, the system doesn't interpret it as "go into that folder" — it doesn't strip the `/users/` prefix, so it gets sent to the backend as-is. The backend doesn't know what `/users/list` means, returns 404. With the trailing slash, Nginx strips the prefix and only sends `/list` to the backend — which it understands, returns 200.

### 301 Behavior

Requesting `/users` (no trailing slash) triggers a `301 Moved Permanently` to `/users/`. This is Nginx's standard behavior when a `location /users/` block is defined. `curl -L` follows the redirect automatically:

```bash
curl -L http://91.151.88.38/users
# <h1>Users Service</h1>
```

---

## 5. Path Blocking

### Block Everyone

```nginx
location /admin {
    deny all;
}
```

`deny all` already returns 403 — adding `return 403` alongside it is redundant and can cause conflicts. This was discovered directly during testing: with `return 403` present, even localhost requests were blocked. Removing it fixed the issue.

### Block Outside, Allow Internal (Real-World Usage)

```nginx
location /admin {
    allow 127.0.0.1;
    deny all;
}
```

Nginx reads rules **top to bottom**, stopping at the first match:

1. Coming from `127.0.0.1`? → Allow
2. Anyone else? → 403

**Example:** A security guard placed at the office door with one instruction: "Only let in people coming from inside the building (localhost). Turn everyone else away."

### Test Results

```bash
# From inside (localhost)
curl http://localhost/admin
# → Backend response (allowed through)
```

```
# From outside (Windows)
PS C:\> curl http://91.151.88.38/admin
<html><head><title>403 Forbidden</title></head>
<body><center><h1>403 Forbidden</h1></center></body></html>
```

---

## 6. Forward Proxy (Squid)

Nginx is built for reverse proxying. For forward proxying, **Squid** was used instead.

### The Difference

|                   | Reverse Proxy (Nginx) | Forward Proxy (Squid)           |
| ----------------- | --------------------- | ------------------------------- |
| **Who is hidden** | The backend server    | The client (user)               |
| **Sits on**       | The server side       | The client side                 |
| **Used for**      | Websites, APIs        | Corporate internet control, VPN |
| **Example**       | Receptionist          | Turnstile                       |

**Example (Forward Proxy):** Like the turnstile at a company entrance — employees pass through it on the way out. The sites they visit see the **company's IP**, not the individual employee's. The company can also log and control what gets accessed.

### Setup and Test

```bash
sudo apt install squid -y
# running on port 3128
```

Added to `/etc/squid/squid.conf` (for testing only):

```
http_access allow all
```

Windows system proxy set to `91.151.88.38:3128`. Visiting `ifconfig.me` in the browser returned **Squid's IP** (`91.151.88.38`) instead of the real Windows IP (`37.154.226.48`).

The Squid access log confirmed **all Windows traffic** was passing through Squid:

```
37.154.226.48 TCP_TUNNEL/200 CONNECT claude.ai:443
37.154.226.48 TCP_TUNNEL/200 CONNECT amp-api.music.apple.com:443
37.154.226.48 TCP_TUNNEL/200 CONNECT activity.windows.com:443
37.154.226.48 TCP_TUNNEL/200 CONNECT dc1.ksn.kaspersky-labs.com:443
```

This log directly confirmed that the proxy was working and **all outgoing internet traffic was passing through the proxy server** — including `claude.ai`, meaning even this conversation's traffic went through Squid.

After testing, `http_access allow all` was removed and the Windows proxy setting was turned off.

---

## 📊 Quick Reference

| Directive                                 | Purpose                                             |
| ----------------------------------------- | --------------------------------------------------- |
| `proxy_pass http://host:port`             | Forward the request to the specified backend        |
| `proxy_pass http://host:port/`            | Forward and strip the matched path prefix (rewrite) |
| `proxy_set_header Host $host`             | Pass the original domain name to the backend        |
| `proxy_set_header X-Real-IP $remote_addr` | Pass the real user IP to the backend                |
| `deny all`                                | Block all requests (returns 403)                    |
| `allow 127.0.0.1`                         | Allow only localhost                                |
| `location /path/`                         | Define a rule for a specific path                   |

---

ℹ️ _All tests performed on a real Ubuntu VPS (`91.151.88.38`). Python's built-in HTTP server was used as the backend service._
