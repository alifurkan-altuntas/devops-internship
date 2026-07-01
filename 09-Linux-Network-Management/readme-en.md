# 🌐 Linux Network & Port Management

This document covers DNS lookups, checking listening ports, and verifying TLS certificates.

---

## 1. DNS Resolution and Troubleshooting

### Basic Lookup

```bash
dig google.com
```

Uses the system's configured (local) DNS resolver.

### Bypassing the Local Resolver

```bash
dig @8.8.8.8 google.com
```

Forces the query to go directly to Google's public DNS server, skipping any local caching or resolver.

### The Actual Troubleshooting Flow

If DNS resolution is failing, the goal is to isolate **where** the problem is:

1. **Try the default resolver, then a public one:**

   ```bash
   dig google.com
   dig @8.8.8.8 google.com
   ```

   - Both fail → likely a general network/connectivity issue, or the domain itself is broken.
   - Only the local one fails → the local resolver/DNS configuration is the problem.

2. **If it looks local, check the resolver configuration:**

   ```bash
   cat /etc/resolv.conf
   ```

   This file lists the `nameserver` entries the system actually uses. A wrong, outdated, or unreachable IP here is a common and very findable cause.

3. **Rule out a pure connectivity issue:**
   ```bash
   ping 8.8.8.8
   ```
   If a raw IP isn't reachable either, the problem isn't DNS — it's the network connection itself. If the IP works but domain names don't resolve, that confirms it's a DNS-layer issue specifically.

> 💡 For an in-depth treatment of DNS (resolver chain, record types, TTL, debug tools) see [18-Linux-Networking-Fundamentals](../18-Linux-Networking-Fundamentals/).

---

## 2. Checking Listening Ports

```bash
sudo ss -lntp | grep :80
```

### `-l` vs `-a`

| Flag     | Shows                                                                                                        |
| -------- | ------------------------------------------------------------------------------------------------------------ |
| **`-l`** | Only **listening** sockets — what's actually waiting for incoming connections on a port.                     |
| **`-a`** | **Both** listening sockets **and** established connections — a superset of `-l`, not a separate alternative. |

For "what's listening on port X," `-l` is the direct and sufficient answer:

```bash
sudo ss -lntp | grep :80
```

Output:

```text
LISTEN 0   511   0.0.0.0:80   0.0.0.0:* users:(("nginx",pid=32381,fd=6))
LISTEN 0   511      [::]:80      [::]:* users:(("nginx",pid=32381,fd=7))
```

Confirms Nginx (PID 32381) is bound to port 80 over both IPv4 (`0.0.0.0`) and IPv6 (`[::]`).

---

## 3. Checking a TLS Certificate

```bash
openssl s_client -connect example.com:443 -showcerts
```

Returns `Verification: OK` and confirms the TLS version/cipher in use (e.g. `TLSv1.3` with `TLS_AES_256_GCM_SHA384`).

### Understanding the Certificate Trust Chain

- **`depth=4` (Root CA):** trusted by the OS by default.
- **`depth=3` / `depth=2` (Intermediate):** link the root to the end certificate.
- **`depth=1` (Issuing CA):** issues the certificate for this specific domain.
- **`depth=0` (End entity):** the actual site.

### Certificate Validity

```text
NotBefore: May 31 21:39:12 2026 GMT; NotAfter: Aug 29 21:41:26 2026 GMT
```

If not renewed before the expiration date, visitors see certificate warnings in their browser.

---

## 📊 Command Reference

| Utility                    | Protocol Layer | Example                              | Purpose                                                                                        |
| -------------------------- | -------------- | ------------------------------------ | ---------------------------------------------------------------------------------------------- |
| **`dig`**                  | UDP / 53       | `dig @8.8.8.8 google.com`            | Looks up DNS records; can target a specific resolver to isolate local vs. remote DNS issues.   |
| **`cat /etc/resolv.conf`** | —              | `cat /etc/resolv.conf`               | Shows which DNS servers the system is actually configured to use.                              |
| **`ss`**                   | TCP/UDP        | `sudo ss -lntp`                      | `-l` shows listening sockets only; `-a` shows listening + established connections.             |
| **`openssl s_client`**     | TCP / 443      | `openssl s_client -connect site:443` | Inspects a TLS certificate's validity, issuer, and trust chain.                                |
| **`ip`**                   | Layer 3        | `ip a` / `ip route`                  | Shows interfaces, addresses, and routing info.                                                 |
| **`ping`**                 | ICMP           | `ping -c 4 8.8.8.8`                  | Checks raw reachability — useful for distinguishing a DNS problem from a connectivity problem. |

---

ℹ️ _All commands tested locally._
