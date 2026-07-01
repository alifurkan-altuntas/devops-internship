# 🔀 Forward Proxy vs Reverse Proxy

This document covers the difference between forward and reverse proxies, what Nginx does as a reverse proxy, and a 502 error encountered during the first setup attempt.

> 💡 This phase established the conceptual foundation. The in-depth hands-on implementation of Nginx (path-based routing, path rewrite, path blocking, forward proxy setup) was completed in the next phase: see [19-Nginx-Derinlestirme](../19-Nginx-Derinlestirme/).

---

## 1. Forward Proxy

Sits in front of the **client**. It makes requests to the internet on your behalf — the destination server sees the proxy, not you.

```
Client → Forward Proxy → Destination Server (e.g. google.com)
```

**Used for:**

- Controlling/filtering internet access in corporate networks
- Hiding the client's real IP
- Content filtering

**Example:** Like the turnstile at a company entrance — employees pass through it on the way out. The sites they visit see the company, not the individual employee. The company can also log and control what gets accessed.

---

## 2. Reverse Proxy

Sits in front of the **server(s)**. Clients connect to the proxy, and the proxy forwards the request to the actual backend server. The client has no idea what's running behind it.

```
Client → Reverse Proxy (Nginx) → Backend Server
```

**Used for:**

- **Load balancing** — distributing traffic across multiple backend servers
- **SSL termination** — handling HTTPS at the proxy, sending plain HTTP to the backend
- **Single entry point** — serving multiple services (API, frontend, admin panel) under one domain, routed by path
- **Security** — hiding the real IP/structure of backend servers from the outside

**Example:** Like a receptionist at a large company — "do you have an appointment, who are you here to see?" — and then sending you to the right place. You only interact with reception; you don't know the building's internal layout.

This maps directly to Nginx's `location` blocks:

```nginx
location /api/ {
    proxy_pass http://backend1:8080;
}
location /admin/ {
    proxy_pass http://backend2:9090;
}
```

Different paths get routed to different backends, just like asking for "accounting" vs "HR" gets you sent to different floors.

---

## 3. First Reverse Proxy Attempt and the 502 Error

### What Was Done

1. Started a basic Python HTTP server on port 8080 as the "backend":
   ```bash
   python3 -m http.server 8080
   ```
2. Changed the `location /` block in Nginx's config:
   ```nginx
   location / {
       proxy_pass http://localhost:8080;
   }
   ```
3. Tested config syntax and restarted Nginx:
   ```bash
   sudo nginx -t
   sudo systemctl restart nginx
   ```
4. Tried `curl localhost` → got **502 Bad Gateway**.

### Why It Failed

The Python backend and Nginx were running on **different VMs**. `localhost` always refers to "this machine" — so when Nginx (on Ubuntu) tried `proxy_pass http://localhost:8080`, it was looking for a backend on itself, not on the other VM where the backend was actually running. There was nothing listening on Ubuntu's own port 8080, hence the 502.

### What 502 Actually Means

`502 Bad Gateway` = "I (the proxy) tried to forward your request, but I couldn't reach the destination." Common causes:

- The backend service isn't running
- Wrong IP/port in `proxy_pass`
- Backend is on a different machine and `localhost` doesn't point there
- A firewall is blocking the connection between proxy and backend

### The Fix

Either run both Nginx and the backend on the **same machine** (so `localhost` is valid), or use the backend VM's actual IP address in `proxy_pass` instead of `localhost`.

This was resolved in the next phase on a real server, with both the backend and Nginx running on the same machine.

---

## 📊 Quick Reference

| Term                | What it does                                                      | Real-world analogy                                         |
| ------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------- |
| **Forward Proxy**   | Sits in front of the client, makes requests on its behalf         | Turnstile employees pass through on the way out            |
| **Reverse Proxy**   | Sits in front of the server, routes incoming requests to backends | Receptionist directing visitors to the right office        |
| **`proxy_pass`**    | Nginx directive that forwards requests to another address/port    | The instruction telling the receptionist where to send you |
| **502 Bad Gateway** | Proxy couldn't reach the backend it was told to forward to        | The office you were sent to doesn't answer                 |

---

ℹ️ _This phase was mostly conceptual. The hands-on setup hit a real issue (wrong host for `proxy_pass`) that wasn't fully resolved here — understanding why it failed was the actual learning, and the full working setup was completed in [19-Nginx-Derinlestirme](../19-Nginx-Derinlestirme/)._
