# 🌐 Linux Network & Port Management

This document covers DNS lookups, checking listening ports, and verifying TLS certificates.

---

## 1. DNS, Ports, and TLS Verification

Common networking tasks: diagnosing DNS issues, checking which process owns a port, and verifying TLS certificates. This lab demonstrates low-level networking validations using native system utilities.

### 🛠️ Steps

1. **DNS Resolution:**
   To bypass local DNS caching, queried a public resolver directly:
   ```bash
   dig @8.8.8.8 google.com
   ```

````

* Without `@8.8.8.8`, `dig google.com` queries the local gateway and returns a cached result. Forcing Google's public resolver took 18ms and confirmed routing works correctly.

2. **Checking Listening Ports:**
To find which process is listening on port 80:
```bash
sudo ss -lntp | grep :80

````

- **Output:**

```text
LISTEN 0   511   0.0.0.0:80   0.0.0.0:* users:(("nginx",pid=32381,fd=6))
LISTEN 0   511      [::]:80      [::]:* users:(("nginx",pid=32381,fd=7))

```

3. **Checking a TLS Certificate:**
   To check a certificate without a browser:

```bash
openssl s_client -connect example.com:443 -showcerts

```

- Returns `Verification: OK` and confirms the connection uses TLSv1.3 with `TLS_AES_256_GCM_SHA384`.

---

## 🔬 Understanding the Certificate Trust Chain

The connection shows the full trust chain:

- **`depth=4` (Root Certificate Authority):** `Comodo CA Limited / AAA Certificate Services` (trusted by the OS by default).
- **`depth=3` & `depth=2` (Intermediate Bridges):** Intermediate certificates that link the root to the end certificate.
- **`depth=1` (Edge Issuing Authority):** `Cloudflare TLS Issuing ECC CA 3` (issues the certificate for this specific domain).
- **`depth=0` (End-Entity Target):** `example.com` (the actual site).

> **Certificate Validity:**
> `NotBefore: May 31 21:39:12 2026 GMT; NotAfter: Aug 29 21:41:26 2026 GMT`
> If the certificate isn't renewed before the expiration date, visitors will see certificate warnings.

---

## 📊 Command Reference

| Utility       | Protocol Layer | Sandbox Lab Practical Example        | Core Operational Purpose / Troubleshooting Utility                                       |
| ------------- | -------------- | ------------------------------------ | ---------------------------------------------------------------------------------------- |
| **`dig`**     | UDP / 53       | `dig @8.8.8.8 google.com`            | Looks up DNS records; useful for diagnosing resolver issues.                             |
| **`ss`**      | TCP/UDP        | `sudo ss -lntp`                      | Lists listening sockets and the PID that owns each one. Faster than the older `netstat`. |
| **`openssl`** | TCP / 443      | `openssl s_client -connect site:443` | Connects via TLS to check certificate validity and issuer.                               |
| **`ip`**      | Layer 3        | `ip a` / `ip route`                  | Shows network interfaces, MAC addresses, and routing info.                               |
| **`ping`**    | ICMP           | `ping -c 4 8.8.8.8`                  | Checks if a host is reachable and measures latency.                                      |

---

ℹ️ _All commands tested locally._
