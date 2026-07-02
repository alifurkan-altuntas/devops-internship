# 🧪 Nginx Test Cases

After writing the Nginx config, I ran it through 20 different scenarios — routing, path blocking, rewrite, and error conditions. One of them didn't return what I expected, and that's where I learned the most.

---

## Environment

```
Server: <SERVER_IP> (Ubuntu 24.04)
Nginx: 1.24.0

Backend services:
  /           → python3 -m http.server 8080 (/tmp/backend/)
  /users/     → python3 -m http.server 3000 (/tmp/users/)
  /computers/ → python3 -m http.server 4000 (/tmp/computers/)
  /admin      → allowed from inside, blocked from outside
```

---

## TC-01 — Root Path, From Inside

```bash
curl http://localhost/
```

Checking whether Nginx forwards requests to the backend on port 8080.

**Expected:** Backend response
**Result:** ✅ `<h1> Backend servisi çalışıyor - port 8080</h1>`

---

## TC-02 — Root Path, From Outside

```bash
curl http://<SERVER_IP>/
```

The user hits port 80 — never sees port 8080.

**Expected:** Backend response (without port 8080 being visible)
**Result:** ✅ `<h1> Backend servisi çalışıyor - port 8080</h1>`

---

## TC-03 — /users/ Routing, From Inside

```bash
curl http://localhost/users/
```

**Expected:** Response from port 3000
**Result:** ✅ `<h1>Users servisi</h1>`

---

## TC-04 — /computers/ Routing, From Inside

```bash
curl http://localhost/computers/
```

**Expected:** Response from port 4000
**Result:** ✅ `<h1>Computers Servisi</h1>`

---

## TC-05 — /users/ Routing, From Outside

```bash
curl http://<SERVER_IP>/users/
```

**Expected:** Response from port 3000
**Result:** ✅ `<h1>Users servisi</h1>`

---

## TC-06 — /computers/ Routing, From Outside

```bash
curl http://<SERVER_IP>/computers/
```

**Expected:** Response from port 4000
**Result:** ✅ `<h1>Computers Servisi</h1>`

---

## TC-07 — No Trailing Slash: /users

```bash
curl http://localhost/users
```

The location is defined as `/users/` — without the slash, Nginx automatically redirects.

**Expected:** 301 Moved Permanently
**Result:** ✅ `301 Moved Permanently`

---

## TC-08 — No Trailing Slash: Following the Redirect

```bash
curl -L http://localhost/users
```

Used `-L` to follow the 301.

**Expected:** Users service response
**Result:** ✅ `<h1>Users servisi</h1>`

---

## TC-09 — No Trailing Slash: /computers

```bash
curl http://localhost/computers
```

**Expected:** 301 Moved Permanently
**Result:** ✅ `301 Moved Permanently`

---

## TC-10 — /computers Redirect Follow

```bash
curl -L http://localhost/computers
```

**Expected:** Computers service response
**Result:** ✅ `<h1>Computers Servisi</h1>`

---

## TC-11 — /admin From Inside ⚠️

```bash
curl http://localhost/admin
```

This test didn't return what I expected. The config had `allow 127.0.0.1` — it should have worked — but 403 came back. I started looking for what went wrong.

From earlier Linux training I remembered that Ubuntu tends to prefer IPv6. But I needed to actually verify it — I needed to see which IP Ubuntu was using to connect to localhost:

```bash
curl -v http://localhost/admin 2>&1 | grep "Connected"
# * Connected to localhost (::1) port 80
```

It was connecting over IPv6. The config only had `allow 127.0.0.1` (IPv4) — `::1` wasn't in the allow list, so it was falling through to `deny all`.

I added `allow ::1` and it worked. Then I also tested with `127.0.0.1` directly — that worked too, because it goes over IPv4 and `allow 127.0.0.1` is enough on its own:

```bash
curl -v http://127.0.0.1/admin 2>&1 | grep "Connected"
# * Connected to 127.0.0.1 (127.0.0.1) port 80
```

Final config:

```nginx
location /admin {
    allow 127.0.0.1;
    allow ::1;
    deny all;
}
```

**Expected:** 404 (allowed through, reached backend, but no `/admin` file exists)
**Result:** ✅ `404 Not Found` — confirmed with both `localhost` and `127.0.0.1`

---

## TC-12 — /admin From Outside

```bash
curl http://<SERVER_IP>/admin
```

**Expected:** 403 Forbidden
**Result:** ✅ `403 Forbidden`

---

## TC-13 — What Happens When the Backend Is Down?

```bash
kill $(lsof -t -i:8080)
curl http://localhost/
```

Nginx is running but there's no backend — the receptionist is there but the office is closed.

**Expected:** 502 Bad Gateway
**Result:** ✅ `502 Bad Gateway`

```bash
# Restarted the backend after the test
cd /tmp/backend && python3 -m http.server 8080 &
```

---

## TC-14 — Non-Existent Path

```bash
curl http://localhost/birseyyok
```

The request goes through Nginx and reaches the backend — but the backend has no such file.

**Expected:** 404 (from the backend, not Nginx)
**Result:** ✅ `404 File not found` — came from the Python backend

---

## TC-15 — Nginx's Footprint in the Backend Log

```bash
curl http://<SERVER_IP>/
```

Checked the backend terminal.

**Expected:** `127.0.0.1` in the log, not the user's real IP
**Result:** ✅ `127.0.0.1 - - "GET / HTTP/1.0" 200` — request came from Nginx, not the user directly

---

## TC-16 — Non-Existent File Under /users/

```bash
curl http://localhost/users/olmayan.html
```

**Expected:** 404 from the users backend (port 3000)
**Result:** ✅ `404 File not found`

---

## TC-17 — POST Request

```bash
curl -X POST http://localhost/users/
```

Python's built-in HTTP server doesn't support POST.

**Expected:** 501 Not Implemented
**Result:** ✅ `501 Unsupported method ('POST')`

---

## TC-18 — Is the Host Header Being Forwarded?

```bash
curl -v http://localhost/users/ 2>&1 | grep -i "host"
```

Checking whether `proxy_set_header Host $host` is actually doing anything.

**Expected:** `Host: localhost` visible in the request
**Result:** ✅ `> Host: localhost`

---

## TC-19 — Path Case Sensitivity

```bash
curl http://localhost/Users/
curl http://localhost/USERS/
```

Nginx location blocks are case-sensitive — `/Users/` and `/USERS/` aren't defined.

**Expected:** 404
**Result:** ✅ Both returned `404 File not found`

---

## TC-20 — /admin/ With Trailing Slash, From Outside

```bash
curl http://<SERVER_IP>/admin/
```

Testing whether a trailing slash changes anything for blocking.

**Expected:** 403 Forbidden
**Result:** ✅ `403 Forbidden` — trailing slash makes no difference

---

## Summary

| Test  | Scenario                           | Expected        | Result |
| ----- | ---------------------------------- | --------------- | ------ |
| TC-01 | `localhost/`                       | 200 + Backend   | ✅     |
| TC-02 | `<SERVER_IP>/`                     | 200 + Backend   | ✅     |
| TC-03 | `localhost/users/`                 | 200 + Users     | ✅     |
| TC-04 | `localhost/computers/`             | 200 + Computers | ✅     |
| TC-05 | `<SERVER_IP>/users/`               | 200 + Users     | ✅     |
| TC-06 | `<SERVER_IP>/computers/`           | 200 + Computers | ✅     |
| TC-07 | `localhost/users` (no slash)       | 301             | ✅     |
| TC-08 | `localhost/users` + `-L`           | 200 + Users     | ✅     |
| TC-09 | `localhost/computers` (no slash)   | 301             | ✅     |
| TC-10 | `localhost/computers` + `-L`       | 200 + Computers | ✅     |
| TC-11 | `localhost/admin` (from inside)    | 404             | ✅     |
| TC-12 | `<SERVER_IP>/admin` (from outside) | 403             | ✅     |
| TC-13 | Backend down                       | 502             | ✅     |
| TC-14 | Non-existent path                  | 404             | ✅     |
| TC-15 | Backend log check                  | 127.0.0.1       | ✅     |
| TC-16 | `/users/olmayan.html`              | 404             | ✅     |
| TC-17 | POST request                       | 501             | ✅     |
| TC-18 | Host header                        | Host: localhost | ✅     |
| TC-19 | `/Users/` (uppercase)              | 404             | ✅     |
| TC-20 | `/admin/` (trailing slash)         | 403             | ✅     |

**20/20 ✅**

---

ℹ️ _All tests were run against a real Nginx config on a live Ubuntu VDS._
