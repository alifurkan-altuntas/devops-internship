# 🌐 OSI Model — Layers, Real Scenarios, and Real Packet Verification

✅ **Status: Completed.** The 7 layers, real-scenario layer identification, encapsulation/decapsulation, router behavior, and ICMP/traceroute behavior across real-world providers have all been worked through and verified hands-on.

---

## 1. What the OSI Model Is

A conceptual framework that splits network communication into 7 layers. Each layer has its own job and only needs to know how to talk to the layer above/below it — not the internal details of every other layer.

```
7. Application   ← protocols the user/application directly uses (HTTP, DNS, FTP, SSH)
6. Presentation  ← data format, encryption (TLS/SSL), compression
5. Session       ← starting/maintaining/ending a connection
4. Transport     ← TCP/UDP, port numbers, reliable vs unreliable delivery
3. Network       ← IP addresses, routing between networks
2. Data Link     ← MAC addresses, communication within the same local network
1. Physical      ← cables, signals, raw bits
```

---

## 2. Working Through Real Examples

Not every operation uses all 7 layers — this was the most useful realization from working through examples.

### `dig google.com` (plain DNS query, no `@resolver`)

- **Layer 3** — the query needs to be routed to a DNS server via IP.
- **Layer 4** — DNS typically uses UDP, port 53.
- **Layer 7** — DNS itself is an application-layer protocol.
- **Layer 6 — not used.** A plain DNS query has no encryption or format conversion happening.

### `curl https://example.com` (HTTPS)

- Same Layers 3, 4, 7 as above.
- **Layer 6 — used this time**, because `https://` triggers TLS encryption, and encryption is exactly what Layer 6 is for.

### `ssh user@<ip>` (connecting by IP, not a domain)

- **Layers 1–4** — always required (physical transmission, MAC, IP routing, TCP + port 22).
- **Layer 5** — session management (the connection has a defined start, duration, and end).
- **Layer 6** — SSH encrypts its traffic by default, so this is active.
- **Layer 7** — SSH itself is an application-layer protocol, same category as HTTP or FTP. This is true _regardless_ of whether DNS was involved.

**Key clarification reached here:** Layer 7 isn't about which _tool_ is being used (PuTTY, a terminal, an FTP client) — it's about which _protocol_ is being spoken. Connecting by IP instead of a domain name just means DNS (a separate Layer 7 protocol) isn't involved — it doesn't remove SSH itself from Layer 7.

---

## 3. Layer 2 vs Layer 3 — Why Both Are Necessary

- **Layer 3 (IP)** is the address — like the address written on an envelope ("which city, which street").
- **Layer 2 (MAC)** is what actually gets the envelope to the right house on that street, within the local network.

---

## 4. Encapsulation and Decapsulation

As data travels down from Layer 7 to Layer 1 to actually be sent, each layer wraps it in its own header — like nesting envelopes inside each other:

```
[Layer 2: MAC header]
  [Layer 3: IP header]
    [Layer 4: TCP/UDP header — includes the port]
      [Layer 7: the actual data — e.g. an HTTP request]
```

On the receiving end, this happens in reverse (**decapsulation**) — each layer strips off its own header and passes what's left up to the next layer, until the original data reaches the application at Layer 7.

### What Actually Happens at Each Router Along the Way

A packet doesn't just get encapsulated once and decapsulated once at the final destination — each router along the path partially decapsulates and re-encapsulates it:

| Layer                | What a router does with it                                                                                    |
| -------------------- | ------------------------------------------------------------------------------------------------------------- |
| Layer 7 (HTTP, etc.) | Never touched — completely ignored                                                                            |
| Layer 4 (TCP/port)   | Generally not touched for basic routing                                                                       |
| Layer 3 (IP)         | **Read only** — used to decide where to forward the packet, but the IP addresses themselves are never changed |
| Layer 2 (MAC)        | **Stripped and rewritten** at every hop                                                                       |

**Why MAC changes but IP doesn't:** the IP address is the final destination — it has to stay the same no matter how many routers the packet passes through. The MAC address is only meaningful within a single local network segment, so each router has to strip the old one off and attach a new MAC header relevant to the _next_ local segment the packet is entering.

Simple analogy: the IP address is like the final address written on an envelope — it never changes in transit. The MAC address is like a local courier's handoff code — it gets replaced at every depot the envelope passes through, because each depot only needs to know how to get it to the _next_ depot.

---

## 5. ICMP, and Why `traceroute` Sometimes Goes Nowhere

**ICMP (Internet Control Message Protocol)** is a control/diagnostic protocol — it doesn't carry application data, it carries status and error messages about the network itself. It operates at Layer 3, alongside IP.

- **`ping`** sends an ICMP **Echo Request**; a reply (**Echo Reply**) means "I'm here."
- **`traceroute`** sends packets with deliberately low TTL values. When a router's TTL hits zero, it responds with an ICMP **"Time Exceeded"** message — this is how traceroute discovers each hop along the path.

### Real Test: Comparing Providers

Ran `traceroute` against several real targets from the same server, to isolate whether failures were local (the server's own network) or specific to the destination:

| Target                   | `traceroute` completed?                                                                                                                 | `ping` result                                                      |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| `1.1.1.1` (Cloudflare)   | ✅ Reached the destination                                                                                                              | (not separately tested — traceroute itself confirmed reachability) |
| `claude.ai`              | ✅ Reached the destination                                                                                                              | (same)                                                             |
| `google.com` / `8.8.8.8` | ❌ Never completed (silence past hop 4)                                                                                                 | ✅ `ping` succeeded, 0% packet loss                                |
| `turkiyesigorta.com.tr`  | ❌ Never completed, but later hops showed internal `10.x.x.x` addresses, suggesting the packet did reach the company's internal network | ❌ `ping` failed completely — 100% packet loss                     |

**Conclusion:** since Cloudflare and Claude.ai's traceroutes completed cleanly from the same machine, the local network/provider wasn't the problem — each destination's _own_ policy on responding to ICMP is what varied.

### Why Different Organizations Handle This Differently

- **Cloudflare** leaves it fully open — as an infrastructure/network provider, transparency and demonstrable performance are part of their value proposition.
- **Google** allows `ping` but blocks `traceroute` — a basic "are you alive" check is low-risk and widely used by monitoring tools, but exposing internal network topology (which `traceroute` would reveal) is an unnecessary risk for a major, constantly-targeted infrastructure.
- **Türkiye Sigorta** blocks ICMP entirely — consistent with a deny-by-default security posture common in finance/insurance, where ICMP has essentially no business value but does carry some risk, so it's fully disabled rather than partially allowed.

This is the same underlying idea as the Least Privilege principle from earlier phases (SSH, sudoers) — applied here to network-level access instead of command-level access: allow only what's actually needed, weighed against the risk of what's exposed.

---

## 📊 Quick Reference

| Layer            | Job                                       | Real Example Seen                                        |
| ---------------- | ----------------------------------------- | -------------------------------------------------------- |
| 7 - Application  | The protocol itself (HTTP, DNS, SSH, FTP) | `GET / HTTP/1.1` visible in a packet capture             |
| 6 - Presentation | Encryption / format                       | TLS in `https://`; absent in plain `http://`             |
| 5 - Session      | Connection lifecycle                      | SSH session duration                                     |
| 4 - Transport    | TCP/UDP, ports                            | Port 80 in a packet capture                              |
| 3 - Network      | IP, routing                               | Source/destination IP read (not modified) by each router |
| 2 - Data Link    | MAC, local network delivery               | Stripped and rewritten at every router hop               |
| 1 - Physical     | Raw signal transmission                   | Not directly observable at this level                    |

| Concept               | Summary                                                                                                                                       |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Encapsulation         | Each layer wraps data in its own header on the way down (L7 → L1)                                                                             |
| Decapsulation         | Each layer strips its own header on the way up (L1 → L7)                                                                                      |
| Router behavior       | Reads IP (Layer 3) to route; strips and rewrites MAC (Layer 2) at every hop; never touches Layer 7                                            |
| ICMP                  | A Layer 3 control protocol used by `ping` (Echo Request/Reply) and `traceroute` (Time Exceeded)                                               |
| Why ICMP gets blocked | Hides internal network topology and reduces attack surface — policy varies by how much an organization values transparency vs. risk reduction |

---

ℹ️ _Tested directly: real packet capture with `tcpdump`, and a comparative `traceroute`/`ping` test across Cloudflare, Google, Claude.ai, and Türkiye Sigorta to observe different real-world ICMP policies._
