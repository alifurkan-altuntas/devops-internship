# 📊 Phase 18 Quiz Results — DNS

**Score: 15/15 (100%)**

---

**1. What does `dig +trace` do?**
A) Only queries the A record
B) Shows every step of the DNS resolution process (root → TLD → authoritative) in real time
C) Clears the DNS cache
D) Only queries IPv6

**My answer: B** ✅

---

**2. You query a domain and see TTL 300. What does this mean?**
A) This record is valid for 300 days
B) This record is cached for 300 seconds, then re-queried
C) This record has 300 backup servers
D) This record can be queried 300 times

**My answer: B** ✅

---

**3. You run `dig google.com` twice in a row. The second query takes 0ms. Why?**
A) Google's servers are very fast
B) The DNS chain is shorter on the second query
C) The answer came from cache — the chain wasn't re-walked
D) Only the root server was queried the second time

**My answer: C** ✅

---

**4. What does NXDOMAIN mean?**
A) The DNS server is busy
B) The domain doesn't exist
C) The TTL has expired
D) No IPv6 address was found

**My answer: B** ✅

---

**5. What is negative caching for?**
A) Prevents incorrect DNS answers
B) Caches the result of non-existent domain queries too, preventing unnecessary repeated lookups
C) Protects the DNS server from attacks
D) Enables caching of large files

**My answer: B** ✅

---

**6. What's the difference between `dig @8.8.8.8 google.com` and `dig google.com`?**
A) No difference
B) The first uses IPv6, the second uses IPv4
C) The first queries Google's public DNS server directly; the second uses the system's default resolver
D) The first only returns A records; the second returns all records

**My answer: C** ✅

---

**7. What does an MX record do?**
A) Returns the domain's IPv6 address
B) Tells anyone sending mail to this domain which server to deliver it to
C) Specifies the domain's web server
D) Validates the SSL certificate

**My answer: B** ✅

---

**8. `turkiyesigorta.com.tr` has 3 MX records with priorities 10, 20, 30. What happens when someone sends mail?**
A) All three servers receive it simultaneously
B) One is chosen at random
C) Priority 10 is tried first; if it fails, 20; if that fails, 30
D) The highest priority (30) is tried first

**My answer: C** ✅

---

**9. Why does `google.com` have an A record but no CNAME?**
A) Google prefers not to use CNAME
B) At the apex/root of a domain, CNAME conflicts with other required records (NS, SOA) — the DNS standard doesn't allow it
C) CNAME is only used for IPv6
D) Google's server is too large

**My answer: B** ✅

---

**10. What does a PTR record do and why does it matter?**
A) Converts a domain to IPv4; required for websites
B) Converts an IP address to a domain name; especially important for mail servers (missing PTR increases chance of being marked as spam)
C) Clears the DNS cache
D) Validates TLS certificates

**My answer: B** ✅

_Self-note: recognized this was the correct answer from multiple choice, but would have struggled to recall it unprompted in an open-ended format._

---

**11. What does `resolvectl status` show?**
A) All DNS records on the system
B) History of DNS queries
C) Which DNS server the system is using and the network interface DNS configuration
D) The list of root servers

**My answer: C** ✅

---

**12. In a `dig +trace` output, you see IPv6 timeouts before it continues. What does this mean?**
A) DNS is broken
B) The attempt over IPv6 failed; it automatically fell back to IPv4
C) Root servers are down
D) TTL has expired

**My answer: B** ✅

---

**13. What is a TXT record used for? (Choose the most comprehensive answer)**
A) Only for website verification
B) Proving domain ownership to third-party services, email security via SPF, and carrying free-form text for various service integrations
C) Only for IPv6 addresses
D) For SSL certificate information

**My answer: B** ✅

---

**14. What exactly happened in the AWS DynamoDB outage?**
A) AWS's servers physically burned
B) A DDoS attack took down DNS servers
C) A race condition in the automated DNS management system caused a DNS record to be completely deleted, taking down everything dependent on that service
D) TTL was set too short so answers couldn't be returned

**My answer: C** ✅

---

**15. What happened in Cloudflare's 2023 DNSSEC outage?**
A) Cloudflare was hacked
B) After a new record type was added to the root zone, DNSSEC signatures expired; Cloudflare's system rejected even correct answers because the signatures were invalid
C) Cloudflare's servers went down during an update
D) The DNS cache was completely cleared

**My answer: B** ✅

---

ℹ️ _All answers given without revisiting or correcting after submission. Two letters were mistyped (questions 1 and 4) and corrected after flagging._