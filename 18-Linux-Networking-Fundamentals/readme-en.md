# 🌐 OSI Model — Layers, Real Scenarios, and a First Look at Packets

⚠️ **Status: In progress.** The 7 layers and how to identify which ones are active in a real scenario are solid. Encapsulation/decapsulation is introduced but not yet fully worked through — to be continued.

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
- **Layer 6 — not used.** A plain DNS query has no encryption or format conversion happening. (Initially guessed Layer 6 would be involved here — wrong. Layer 6 only matters when something is actually being encrypted/transformed, and classic DNS isn't.)

### `curl https://example.com` (HTTPS)

- Same Layers 3, 4, 7 as above.
- **Layer 6 — used this time**, because `https://` triggers TLS encryption, and encryption is exactly what Layer 6 is for.

### `ssh user@<ip>` (connecting by IP, not a domain)

- **Layers 1–4** — always required (physical transmission, MAC, IP routing, TCP + port 22).
- **Layer 5** — session management (the connection has a defined start, duration, and end).
- **Layer 6** — SSH encrypts its traffic by default, so this is active.
- **Layer 7** — SSH itself is an application-layer protocol, same category as HTTP or FTP. This is true *regardless* of whether DNS was involved.

**Key clarification reached here:** Layer 7 isn't about which *tool* is being used (PuTTY, a terminal, an FTP client) — it's about which *protocol* is being spoken. SSH via PuTTY and SSH via a terminal's `ssh` command are both Layer 7 = SSH. Connecting by IP instead of a domain name just means DNS (a separate Layer 7 protocol) isn't involved — it doesn't remove SSH itself from Layer 7.

---

## 3. Layer 2 vs Layer 3 — Why Both Are Necessary

- **Layer 3 (IP)** is the address — like the address written on an envelope ("which city, which street").
- **Layer 2 (MAC)** is what actually gets the envelope to the right house on that street, within the local network.

Without Layer 3, there'd be no destination address at all. Without Layer 2, having an address wouldn't matter — there'd be no way to actually hand the data to the next device (e.g. the local router) to get it moving toward that destination.

---

## 4. Encapsulation (introduced, not yet fully covered)

As data travels down from Layer 7 to Layer 1 to actually be sent, each layer wraps it in its own header — like nesting envelopes inside each other:

```
[Layer 2: MAC header]
  [Layer 3: IP header]
    [Layer 4: TCP/UDP header — includes the port]
      [Layer 7: the actual data — e.g. an HTTP request]
```

On the receiving end, this happens in reverse (**decapsulation**) — each layer strips off its own header and passes what's left up to the next layer, until the original data (e.g. the HTTP request) reaches the application at Layer 7.

**Important real-world note:** in practice, Layers 5 and 6 usually don't appear as separate, visible headers in actual packets — their jobs (session handling, encryption) tend to be absorbed into the application-layer protocol itself (e.g. TLS sits conceptually at Layer 6, but isn't a distinct "Layer 6 header" you'd see in a packet capture). This is part of why the simpler 4-layer TCP/IP model is more commonly used in practice than the full 7-layer OSI model — OSI is mainly a teaching tool.

| OSI (7 layers) | TCP/IP (4 layers) |
| --- | --- |
| 7 - Application | Application |
| 6 - Presentation | Application |
| 5 - Session | Application |
| 4 - Transport | Transport |
| 3 - Network | Internet |
| 2 - Data Link | Link |
| 1 - Physical | Link |

---

## 5. First Look: Seeing Layers in a Real Packet

A log line from Nginx only shows what reaches Layer 7 — the lower-layer headers are already stripped away by the time the application sees the request:

```
172.68.50.150 - - [26/Jun/2026:03:55:24 +0000] "GET / HTTP/1.1" 200 425 "-" "Mozilla/5.0 ..."
```

To actually see the lower layers, the raw traffic itself has to be captured — not the application's log:

```bash
sudo apt install tcpdump -y
sudo tcpdump -i any port 80 -nn -X
```

Running `curl localhost` while this was capturing showed the real request as a packet:

```text
14:46:34.548687 lo In IP6 ::1.39502 > ::1.80: Flags [P.], seq 1:73, ... length 72: HTTP: GET / HTTP/1.1
        ...
        4745 5420 2f20 4854 5450 2f31 2e31 0d0a   GET / HTTP/1.1..
        486f 7374 3a20 6c6f 6361 6c68 6f73 740d   Host: localhost.
```

Breaking down what's actually visible here:
- **`::1.39502 > ::1.80`** — this is Layer 3 (the `::1` IPv6 addresses) and Layer 4 (the ports — `.39502` source, `.80` destination, i.e. Nginx) sitting right next to each other in the same line.
- **`GET / HTTP/1.1`** and the readable text in the hex dump — this is Layer 7, the actual HTTP request, sitting in plain, unencrypted text.
- **No Layer 6 activity** — because this was `http://`, not `https://`, there's no encryption, so the request is fully readable in the capture. (Repeating this with `https://` would show unreadable, encrypted bytes instead — not yet tested.)

This confirmed, concretely, that OSI layers aren't just an abstract diagram — the IP, the port, and the actual HTTP text are genuinely sitting inside the same captured packet, layered the way the model describes.

---

## 📊 Quick Reference

| Layer | Job | Real Example Seen |
| --- | --- | --- |
| 7 - Application | The protocol itself (HTTP, DNS, SSH, FTP) | `GET / HTTP/1.1` visible in the packet capture |
| 6 - Presentation | Encryption / format | TLS in `https://`; absent in plain `http://` |
| 5 - Session | Connection lifecycle | SSH session duration |
| 4 - Transport | TCP/UDP, ports | Port 80 (`::1.80`) in the capture |
| 3 - Network | IP, routing | `::1` source/destination IP in the capture |
| 2 - Data Link | MAC, local network delivery | Not directly visible in this capture (loopback) |
| 1 - Physical | Raw signal transmission | Not directly observable at this level |

---

ℹ️ _Next steps: finish encapsulation/decapsulation in more depth, then move on to routing & forwarding._
