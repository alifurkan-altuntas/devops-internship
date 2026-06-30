# 🔥 Real-World Cloud Outages — DNS as a Single Point of Failure

This document covers real, researched incidents from AWS, Cloudflare, and Google Cloud, focusing on what role DNS played (or didn't) in each one. The goal: connect the DNS concepts learned in this phase (A records, automation, caching, resolver chains) to actual, large-scale failures that made global news.

---

## 1. AWS — October 19-20, 2025: The DynamoDB DNS Race Condition

### What Happened

A roughly 15-hour outage in AWS's `us-east-1` region (the oldest and busiest AWS data center), affecting DynamoDB, EC2, Lambda, and dozens of dependent services. Major platforms like Zoom, Slack, and Monday.com were impacted.

### The Root Cause — Directly Tied to What This Phase Covered

DynamoDB manages **hundreds of thousands of DNS records** automatically, using two internal components:

- **DNS Planner**: monitors load balancer health and decides where traffic should go.
- **DNS Enactor**: actually applies those decisions by updating DNS records (running redundantly across multiple zones for safety).

A **race condition** (two of these DNS Enactor processes running at slightly different times, stepping on each other) caused the automation to **delete the DNS record entirely** for DynamoDB's regional endpoint (`dynamodb.us-east-1.amazonaws.com`). The A record just... disappeared.

### Connecting This to What We Learned

This is exactly the kind of failure that's possible because of how DNS caching and automation work:

- The endpoint had **no A record at all** — not a wrong one, an _empty_ one. Anything trying to resolve that domain got nothing back, the same category of failure as the `NXDOMAIN` test run earlier in this phase, except here it was an _unintended_ failure on a record that should have existed.
- Because DynamoDB is a **dependency for many other AWS services** (and many companies' own infrastructure), one missing DNS record didn't just take down DynamoDB — it cascaded outward, the same way a router failure cascades because everything downstream depends on it.
- The fix required **manual intervention** — automation that updates DNS records that fast and that broadly is powerful, but a bug in it can break things globally before a human can react.

### Key Lesson

A single, automated system silently deleting one DNS record took down a massive chunk of the internet for 15 hours. This is the real-world version of "what if the authoritative server gives a bad answer" — except here, it gave _no_ answer at all.

---

## 2. Cloudflare — Multiple Major DNS-Related Incidents

Cloudflare runs the `1.1.1.1` public DNS resolver used throughout this phase's testing — which makes its own outage history especially relevant.

### October 4, 2023 — DNSSEC Signature Expiration

A new DNS record type (`ZONEMD`) was added to the internet's **root zone** on September 21. On October 4, the **DNSSEC signatures** tied to that change expired, and Cloudflare's resolvers — which validate DNSSEC signatures to confirm DNS answers haven't been tampered with — couldn't validate the new signature. Result: Cloudflare's resolvers returned `SERVFAIL` errors for valid queries, for about 3 hours.

**Connection to this phase:** this is a direct, real failure involving the exact root-zone mechanics seen in the `dig +trace` output earlier — including the `DS` and `RRSIG` lines that were noted as "DNSSEC, advanced topic, skip for now." Here's a case where exactly that mechanism broke a major resolver.

### July 14, 2025 — A Dormant Config Error Takes Down 1.1.1.1

A configuration error introduced on June 6 sat **completely dormant** for over a month (no impact, no alerts, because nothing was using the affected configuration yet). On July 14, an unrelated change triggered it: the IP ranges for the 1.1.1.1 resolver were accidentally withdrawn from the internet's routing tables (a BGP-level issue, not strictly DNS, but it made the DNS _service_ unreachable). Result: 1.1.1.1 was down globally for 62 minutes.

**Interesting side note:** during the chaos, another company's router briefly advertised a route for `1.1.1.1` too (a minor, unintentional BGP hijack) — not the actual cause, but a good real-world example of how multiple network-level issues can overlap and momentarily look related.

### November 18, 2025 — Bot Management Feature File

Not primarily a DNS failure, but illustrates the same fragility theme: a routine database permissions change caused an internal "feature file" (used by Cloudflare's bot detection) to double in size, exceeding a hard limit in Cloudflare's core proxy software, causing it to crash across their entire global network. Lasted about 3 hours, broke access to X, ChatGPT, Spotify, and thousands of other sites.

### Key Lesson Across All Three

Cloudflare's own postmortems repeatedly conclude the same thing: **internal configuration changes, not attacks, cause most major outages.** A single bad config, propagated globally and instantly (which is normally a _feature_ — fast updates everywhere), becomes the exact mechanism that takes everything down at once.

---

## 3. Google Cloud — June 12, 2025: Not DNS, But Worth Understanding Why

### What Happened

A 7+ hour outage affecting 50+ Google Cloud products, which also took down parts of Cloudflare (since some Cloudflare services depend on Google Cloud) and other services like Spotify and Discord.

### The Root Cause — Important Distinction

This one was **not a DNS failure** — it was an **authorization (IAM) failure**. A policy database used for service-to-service authentication got corrupted with invalid data, and that corruption replicated globally through Google's internal systems. Services couldn't verify what they were _allowed_ to do, even though identity verification itself was still working.

### Why This Belongs in DNS Notes Anyway

This is an important, deliberate counterexample: **not every major internet outage is a DNS problem.** It's worth including specifically _because_ it shows the boundary of what DNS is responsible for — DNS answers "where do I find this service," while this outage was about "am I allowed to use this service once I find it," a completely different layer of failure. Recognizing that distinction is itself part of understanding DNS's actual scope.

The outage _did_ cascade into other companies' infrastructure (Cloudflare, Spotify, Discord) the same way the AWS DynamoDB failure did — a reminder that in modern infrastructure, almost nothing fails in true isolation.

---

## 📊 Summary Table

| Incident            | Date            | Root Cause                                         | DNS Involved?                                                 | Duration   |
| ------------------- | --------------- | -------------------------------------------------- | ------------------------------------------------------------- | ---------- |
| AWS DynamoDB        | Oct 19-20, 2025 | Race condition deleted a DNS A record              | ✅ Directly — empty DNS record                                | ~15 hours  |
| Cloudflare DNSSEC   | Oct 4, 2023     | Expired DNSSEC signatures after a root zone change | ✅ Directly — resolver validation failure                     | ~3 hours   |
| Cloudflare 1.1.1.1  | Jul 14, 2025    | Dormant config error + BGP route withdrawal        | 🟡 Indirectly — DNS service unreachable, not a DNS bug itself | 62 minutes |
| Cloudflare Bot Mgmt | Nov 18, 2025    | Oversized internal config file crashed core proxy  | ❌ Not DNS — proxy/software failure                           | ~3 hours   |
| Google Cloud IAM    | Jun 12, 2025    | Corrupted authorization policy database            | ❌ Not DNS — authorization failure                            | ~7 hours   |

---

## 🎓 Overall Takeaways

1. **DNS automation is powerful and dangerous.** The same automation that lets DynamoDB manage hundreds of thousands of records efficiently is exactly what deleted one of them with no human in the loop.
2. **DNSSEC, while a security feature, is itself a potential failure point** — if signatures expire or can't be validated, resolvers fail closed (better than serving bad data, but still an outage).
3. **Not every outage is DNS** — the Google Cloud and Cloudflare bot-management incidents are useful precisely because they show what DNS _isn't_ responsible for, sharpening the boundary of what was actually learned in this phase.
4. **Dependencies cascade.** A failure in one company's core service (AWS DynamoDB, Google IAM) ripples outward into other companies that depend on it — the same "every device along the path matters" idea seen in the `traceroute`/router-hop discussion earlier in this phase, just at the scale of entire companies instead of network hops.

---

## 📚 Sources

- AWS DynamoDB outage analysis — Forbes: https://www.forbes.com/sites/kateoflahertyuk/2025/10/23/aws-outage-new-analysis-explains-what-went-wrong-and-why/
- AWS DynamoDB outage, root cause confirmation — BleepingComputer: https://www.bleepingcomputer.com/news/technology/amazon-this-weeks-aws-outage-caused-by-major-dns-failure/
- AWS DynamoDB outage, full technical breakdown — Pragmatic Engineer (Gergely Orosz): https://newsletter.pragmaticengineer.com/p/what-caused-the-large-aws-outage
- AWS outage and DNS as critical infrastructure weakness — Akamai: https://www.akamai.com/blog/security/when-cloud-breaks-lessons-aws-outage
- Cloudflare DNSSEC incident (Oct 4, 2023) and outage history — N2W Software: https://n2ws.com/blog/cloudflare-outage
- Cloudflare 1.1.1.1 outage (July 14, 2025), official postmortem — Cloudflare Blog: https://blog.cloudflare.com/cloudflare-1-1-1-1-incident-on-july-14-2025/
- Cloudflare 1.1.1.1 outage, independent analysis — ThousandEyes: https://www.thousandeyes.com/blog/cloudflare-outage-analysis-july-14-2025
- Cloudflare Bot Management outage (Nov 18, 2025), official postmortem — Cloudflare Blog: https://blog.cloudflare.com/18-november-2025-outage/
- Cloudflare Bot Management outage, independent analysis — ThousandEyes: https://www.thousandeyes.com/blog/cloudflare-outage-analysis-november-18-2025
- Google Cloud IAM outage (June 12, 2025), independent analysis — ThousandEyes: https://www.thousandeyes.com/blog/google-cloud-outage-analysis-june-12-2025
- Google Cloud IAM outage, cascading impact on Cloudflare/Spotify/Discord — Network World: https://www.networkworld.com/article/4006705/google-cloud-outage-disrupts-over-50-services-globally-for-over-7-hours.html
- Google Cloud IAM outage, additional detail — TechRadar: https://www.techradar.com/pro/we-know-what-caused-the-recent-massive-google-cloud-outage-and-its-a-bit-embarassing

---

ℹ️ _Researched via web search; all incidents are real, documented postmortems from the companies' own engineering blogs and independent monitoring services (ThousandEyes, etc.)._
