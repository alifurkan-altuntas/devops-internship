# 📊 Phase 13 Quiz Results — Forward & Reverse Proxy

**Score: 13/15 (87%)** — 1 incorrect, 1 left blank

---

**1. A forward proxy sits in front of which side of a connection?**
A) The server
B) The client
C) Both equally
D) Neither, it's a standalone service

**My answer: B** ✅

---

**2. In a forward proxy setup, what does the destination server see?**
A) The client's real IP
B) The proxy's IP
C) No IP at all
D) A random IP each time

**My answer: B** ✅

---

**3. A reverse proxy sits in front of:**
A) The client
B) The server(s)
C) The DNS resolver
D) The router only

**My answer: B** ✅

---

**4. In a reverse proxy setup, what does the client know about the backend?**
A) The exact IP and port of every backend server
B) Nothing — it only interacts with the proxy
C) The backend's operating system
D) The backend's file system structure

**My answer: B** ✅

---

**5. Which of these is a common reason to use a reverse proxy?**
A) Hiding the client's identity from websites
B) Load balancing across multiple backend servers
C) Encrypting traffic between two clients
D) Speeding up DNS resolution

**My answer: B** ✅

---

**6. What does "SSL termination" at a reverse proxy mean?**
A) SSL is disabled completely
B) The proxy handles HTTPS decryption, then sends plain HTTP to the backend
C) The backend handles all encryption, proxy does nothing
D) SSL certificates are deleted after use

**My answer: (left blank)** ⬜
**Correct answer: B**

---

**7. In Nginx, which directive forwards a request to another address/port?**
A) `forward_to`
B) `proxy_pass`
C) `redirect_pass`
D) `send_request`

**My answer: B** ✅

---

**8. What does this Nginx config block do?**

```nginx
location /api/ {
    proxy_pass http://backend1:8080;
}
```

A) Blocks all traffic to `/api/`
B) Forwards requests starting with `/api/` to `backend1` on port 8080
C) Creates a new API automatically
D) Redirects the client to a different domain

**My answer: B** ✅

---

**9. What does a `502 Bad Gateway` error mean?**
A) The client sent a malformed request
B) The proxy successfully reached the backend, but the backend returned an error
C) The proxy could not reach the backend it was told to forward to
D) The DNS lookup failed

**My answer: B** ❌
**Correct answer: C**

---

**10. In the hands-on attempt, why did `proxy_pass http://localhost:8080` fail?**
A) Port 8080 was blocked by a firewall on every machine
B) The backend and Nginx were on different VMs, and `localhost` only refers to the machine Nginx is running on
C) Nginx doesn't support the `proxy_pass` directive
D) Python's HTTP server cannot run on port 8080

**My answer: B** ✅

---

**11. What does `localhost` always refer to?**
A) The nearest server on the network
B) The current machine you're on
C) The default gateway
D) The DNS server

**My answer: B** ✅

---

**12. If a backend service is running on a different VM than Nginx, what should `proxy_pass` point to instead of `localhost`?**
A) `127.0.0.1`
B) The backend VM's actual IP address
C) The Nginx VM's own IP address
D) `0.0.0.0`

**My answer: B** ✅

---

**13. Which of these is NOT a typical cause of a 502 error?**
A) The backend service isn't running
B) Wrong IP/port in `proxy_pass`
C) A firewall blocking proxy-to-backend traffic
D) The client's browser cache is full

**My answer: D** ✅

---

**14. After editing an Nginx config file, which command checks the syntax before applying changes?**
A) `nginx -t`
B) `nginx -check`
C) `systemctl verify nginx`
D) `nginx --validate`

**My answer: A** ✅

---

**15. Using the receptionist analogy: if the receptionist tries to send you to an office that doesn't answer, what's the real-world equivalent in proxy terms?**
A) 404 Not Found
B) 502 Bad Gateway
C) 403 Forbidden
D) 200 OK

**My answer: B** ✅

---

## Notes on the misses

- **Q6 (left blank):** Hadn't covered SSL termination hands-on yet, so left it rather than guess.
- **Q9 (incorrect):** Mixed up the cause of a 502 — picked "backend returned an error" instead of "proxy couldn't reach the backend at all." This is actually the exact distinction that mattered in the real 502 I hit during the hands-on attempt (Nginx never reached the backend, the backend never even got the request) — worth remembering for next time.

---

ℹ️ _Answers given without revisiting or changing them after submission._
