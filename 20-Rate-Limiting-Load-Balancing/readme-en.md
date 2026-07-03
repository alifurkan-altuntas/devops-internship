# 🚦 Nginx — Rate Limiting and Load Balancing

After the Nginx deep dive phase, I added two more things: limiting the number of requests and distributing traffic across multiple backends.

---

## 1. Rate Limiting

Limits how many requests a single IP can make within a given time window. Used in practice for brute force protection, DDoS mitigation, and API abuse prevention.

**Example:** The reception desk only lets in 5 people per minute — anyone beyond that gets turned away.

### How It Works

Two parts: defining the zone and applying it.

**Zone definition** — added to the `http` block in `nginx.conf`:

```nginx
limit_req_zone $binary_remote_addr zone=genel:10m rate=5r/s;
```

- **`$binary_remote_addr`** — track requests per IP
- **`zone=genel:10m`** — a memory zone named "genel", 10MB (roughly 160,000 IPs)
- **`rate=5r/s`** — maximum 5 requests per second per IP

**Applying to locations** — added to `/`, `/users/`, `/computers/`:

```nginx
limit_req zone=genel burst=10 nodelay;
```

- **`burst=10`** — spike tolerance: if someone sends 10 requests at once, accept them — block anything beyond that
- **`nodelay`** — don't queue burst requests, process them immediately

**`burst` ve `nodelay` olmadan ne olurdu?**

Sadece `limit_req zone=genel;` yazsaydık — her saniyede 5'ten fazla istek anında 503 alırdı, hiç tolerans yok. `nodelay` olmadan ise burst istekleri sıraya alınır ve yavaş yavaş işlenir — kullanıcı bekler. İkisi birlikte "anında kabul et ama limitin üstüne çıkma" demek.

### Test

Sent 20 requests back to back:

```bash
for i in {1..20}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost/; done
```

```
200 200 200 200 200 200 200 200 200 200 200 200
503 503 503 503
200
503 503 503
```

First 12 requests went through, then 503s started. After a short pause, 200 came back — Nginx reset the time window. Came out exactly as expected.

Rate limiting wasn't added to `/admin` — it's already restricted via `allow`/`deny`, and all 20 requests returned 403 regardless.

---

## 2. Load Balancing

Running multiple instances of the same backend and having Nginx distribute traffic between them. If one goes down, the others continue — users notice nothing.

**Example:** Instead of one person at the reception desk, there are 2 or 3 — whoever is free takes the next visitor. Or instead of one lane on the road, there are 4 or 5 — traffic spreads out, no bottleneck.

**For failover:** Think of a junction with one road in and two roads out — if one road closes, all traffic automatically takes the other.

### Configuration

Upstream block added to `nginx.conf`:

```nginx
upstream users_backend {
    server localhost:3000;
    server localhost:3001;
}
```

`/users/` location updated:

```nginx
location /users/ {
    limit_req zone=genel burst=10 nodelay;
    proxy_pass http://users_backend/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

Second instance set up:

```bash
mkdir -p /tmp/users2
echo "<h1>Users Servisi — Instance 2</h1>" > /tmp/users2/index.html
cd /tmp/users2 && python3 -m http.server 3001 &
```

### Alternative Load Balancing Methods

Round-robin worked fine here because the backends are simple and requests are equal in duration. But in production, there are two other methods worth knowing:

**`least_conn`** — sends the request to the backend with the fewest active connections. Useful when some requests take much longer than others (e.g. file uploads) — round-robin would keep sending to a busy backend while the other is free.

**Example:** Like a navigation app — when calculating a route, it picks the shortest and least congested road. If the right lane is jammed, it routes you left.

```nginx
upstream users_backend {
    least_conn;
    server localhost:3000;
    server localhost:3001;
}
```

**`ip_hash`** — the same IP always goes to the same backend. Needed when the application stores session data on the backend itself. With round-robin, a user who logged in on Instance 1 might get routed to Instance 2 on the next request — and their session is gone. `ip_hash` prevents this.

**Example:** Like always going to the same barber — you don't go to a different one because yours already knows how you like your hair. Go to a stranger and you have to explain everything from scratch. `ip_hash` works the same way — the user always lands on the same backend, and that backend already knows their session.

```nginx
upstream users_backend {
    ip_hash;
    server localhost:3000;
    server localhost:3001;
}
```

Neither was used in this phase — the Python backends are stateless and requests are uniform. But knowing when to reach for each one matters in a real deployment.

### Round-Robin

```bash
for i in {1..6}; do curl -s http://localhost/users/; echo; done
```

```
Users servisi
Users servisi
Users servisi
Users Servisi — Instance 2
Users servisi
Users Servisi — Instance 2
```

Nginx distributed traffic between both instances.

### Failover

Killed Instance 1:

```bash
kill $(lsof -t -i:3000)
for i in {1..4}; do curl -s http://localhost/users/; echo; done
```

```
Users Servisi — Instance 2
Users Servisi — Instance 2
Users Servisi — Instance 2
Users Servisi — Instance 2
```

Instance 1 went down, Nginx automatically switched to Instance 2 — no downtime. When Instance 1 came back, round-robin resumed.

Also tested from outside (Windows), same behavior:

```
Users servisi
Users Servisi — Instance 2
Users servisi
Users Servisi — Instance 2
Users servisi
Users Servisi — Instance 2
```

---

## 📊 Quick Reference

| Directive                          | Purpose                                         |
| ---------------------------------- | ----------------------------------------------- |
| `limit_req_zone`                   | Defines a rate limiting zone (in `nginx.conf`)  |
| `limit_req`                        | Applies the zone to a specific location         |
| `burst`                            | Spike tolerance                                 |
| `nodelay`                          | Don't queue burst requests, process immediately |
| `upstream`                         | Defines a backend pool                          |
| `proxy_pass http://upstream_name/` | Routes traffic to the upstream pool             |

---

ℹ️ _All tests performed on a real Ubuntu VDS._
