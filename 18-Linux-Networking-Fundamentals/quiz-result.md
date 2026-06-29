# 📊 Phase 18 Quiz Results — OSI Model & Routing/Forwarding

**Score: 15/15 (100%)**

---

**1. Which OSI layer is responsible for assigning IP addresses and routing between networks?**
A) Layer 2 (Data Link)
B) Layer 3 (Network)
C) Layer 4 (Transport)
D) Layer 7 (Application)

**My answer: B** ✅

---

**2. A plain `dig google.com` query (no `@resolver`, no encryption) involves which layers?**
A) Layers 3, 4, 6, 7
B) Layers 3, 4, 7 (not 6)
C) Only Layer 7
D) Layers 1 through 7, always

**My answer: B** ✅

---

**3. Why does `curl https://example.com` involve Layer 6, while `curl http://example.com` does not?**
A) HTTPS uses a different IP protocol entirely
B) HTTPS triggers TLS encryption, which is what Layer 6 handles
C) HTTP doesn't use Layer 3
D) There is no real difference

**My answer: B** ✅

---

**4. What determines whether something is "Layer 7," according to what was clarified in this phase?**
A) The tool being used (e.g. PuTTY vs. a terminal)
B) The protocol being spoken (e.g. SSH, HTTP, DNS), regardless of the tool
C) Whether a domain name was used instead of an IP
D) The operating system of the client

**My answer: B** ✅

---

**5. Why is Layer 2 (MAC) necessary even when Layer 3 (IP) already specifies the destination?**
A) MAC addresses are required for IP addresses to exist
B) MAC handles delivery within the local network segment; IP alone can't get a packet to the next physical device
C) Layer 2 is optional and rarely used
D) MAC addresses replace IP addresses entirely

**My answer: B** ✅

---

**6. When a packet passes through a router, what happens to its Layer 2 (MAC) and Layer 3 (IP) headers?**
A) Both are left completely unchanged
B) The IP header is read but unchanged; the MAC header is stripped and rewritten at each hop
C) The MAC header is read but unchanged; the IP header is rewritten at each hop
D) Both are stripped and never restored

**My answer: B** ✅

---

**7. Why does the IP address stay the same across the whole journey, while the MAC address changes at every hop?**
A) IP is the final destination address; MAC is only meaningful within a single local network segment
B) IP addresses are encrypted, MAC addresses are not
C) This is arbitrary and has no functional reason
D) MAC addresses are actually longer-lived than IP addresses

**My answer: A** ✅

---

**8. What is ICMP primarily used for?**
A) Carrying application data like HTTP requests
B) Carrying control/diagnostic messages about the network itself
C) Encrypting traffic between hosts
D) Assigning IP addresses to new devices

**My answer: B** ✅

---

**9. In a comparative `traceroute` test against Cloudflare, Google, Claude.ai, and a company website, what did the differing results across destinations indicate?**
A) The local server's network was broken
B) Each destination has its own policy on responding to ICMP, independent of the local network
C) `traceroute` only works for some countries
D) DNS was misconfigured

**My answer: B** ✅

---

**10. Why might an organization like Google allow `ping` but block `traceroute`?**
A) `traceroute` and `ping` use completely unrelated protocols
B) A basic alive-check is low-risk, while `traceroute` can expose internal network topology to potential attackers
C) `ping` doesn't use ICMP, so it's automatically safer
D) Blocking `traceroute` is required by law

**My answer: B** ✅

---

**11. What is the core difference between "routing" and "forwarding"?**
A) They are the same thing, just different names
B) Routing is the planning step (deciding the best path); forwarding is the execution step (actually sending the packet onward)
C) Routing only applies to IPv6; forwarding only applies to IPv4
D) Forwarding happens before routing

**My answer: B** ✅

---

**12. In `ip route` output, what does `proto static` indicate about a route?**
A) It was automatically discovered by a dynamic routing protocol
B) It was manually configured rather than auto-generated
C) It only applies to IPv6 traffic
D) It is a temporary, soon-to-expire rule

**My answer: B** ✅

---

**13. What's the key difference between static and dynamic routing?**
A) Static routing is manually configured and doesn't adapt to network changes; dynamic routing protocols (like BGP, OSPF) automatically discover and update paths
B) Dynamic routing only works on local networks
C) Static routing is always faster than dynamic routing
D) There is no real difference in practice

**My answer: A** ✅

---

**14. What does enabling `ip_forward` actually allow a Linux machine to do?**
A) Browse the internet faster
B) Receive and pass along packets that are not addressed to itself — acting like a router
C) Encrypt all outgoing traffic automatically
D) Block all incoming connections

**My answer: B** ✅

---

**15. Why was `ip_forward=1` found active on a server running Docker, even though the server itself isn't a router?**
A) It was a leftover, meaningless setting with no real cause
B) Docker requires it so containers (on their own isolated network) can reach the outside internet through the host
C) All Linux servers have this on by default regardless of installed software
D) It was caused by a misconfigured DNS resolver

**My answer: B** ✅

---

ℹ️ _All answers given without revisiting or correcting after submission._
