# 🔀 Forward Proxy vs Reverse Proxy

This document covers the difference between forward and reverse proxies, what Nginx does as a reverse proxy, and a (failed, then understood) attempt at setting one up.

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

**How I understood it:** like a courier carrying a package on your behalf — the other side only sees the courier, not you.

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

**How I understood it:** like a security/front desk person at a company — think of reception asking "do you have an appointment? who are you here for?" and then sending you to the right place. You only go where they direct you; you don't know about the rest of the building.

This maps directly to Nginx's `location` blocks — the receptionist isn't just saying "who are you here for," it's routing based on _where_ you're going:

```nginx
location /api/ {
    proxy_pass http://backend1:8080;
}
location /admin/ {
    proxy_pass http://backend2:9090;
}
```

Different paths get routed to different backends, just like asking for "accounting" vs "HR" gets you sent to different floors.

If the backend the receptionist tries to reach isn't available, you get turned away — that's the real-world version of a **502 Bad Gateway**.

---

## 3. Setting Up a Reverse Proxy with Nginx (and what went wrong)

### The goal

Run a simple backend service on one port, and configure Nginx to forward requests from port 80 to that backend port — so visiting Nginx's address actually serves the backend's response.

### What I did

1. Started a basic Python HTTP server on port 8080 as the "backend":
   ```bash
   python3 -m http.server 8080
   ```
2. Edited Nginx's config (`/etc/nginx/nginx.conf` on Ubuntu) and changed the `location /` block:
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
4. Tried `curl localhost` → got a **502 Bad Gateway**.

### Why it failed

I had the Python backend and Nginx running on **different VMs** without realizing it mattered. `localhost` always refers to "this machine" — so when Nginx (on Ubuntu) tried `proxy_pass http://localhost:8080`, it was looking for a backend on _itself_, not on the other VM where the backend was actually running. There was nothing listening on Ubuntu's own port 8080, hence the 502.

### What 502 actually means

`502 Bad Gateway` = "I (the proxy) tried to forward your request, but I couldn't reach the destination." Common causes:

- The backend service isn't running
- Wrong IP/port in `proxy_pass`
- Backend is on a different machine and `localhost` doesn't point there
- A firewall is blocking the connection between proxy and backend

### Where I landed

Got the concept solid through this mistake, even though I didn't finish the hands-on setup in one sitting. The fix would have been either:

- Running both Nginx and the backend on the **same machine** (so `localhost` is valid), or
- Using the backend VM's actual IP address in `proxy_pass` instead of `localhost`

Planning to come back and actually complete the working setup once this is clear.

---

## 📊 Quick Reference

| Term                | What it does                                                      | Real-world analogy                                         |
| ------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------- |
| **Forward Proxy**   | Sits in front of the client, makes requests on its behalf         | A courier delivering your request without revealing you    |
| **Reverse Proxy**   | Sits in front of the server, routes incoming requests to backends | A receptionist directing visitors to the right office      |
| **`proxy_pass`**    | Nginx directive that forwards requests to another address/port    | The instruction telling the receptionist where to send you |
| **502 Bad Gateway** | Proxy couldn't reach the backend it was told to forward to        | The office you were sent to doesn't answer                 |

---

ℹ️ _This phase was mostly conceptual — the hands-on reverse proxy setup hit a real issue (wrong host for `proxy_pass`) that wasn't fully resolved yet, but understanding why it failed was the actual goal here._
