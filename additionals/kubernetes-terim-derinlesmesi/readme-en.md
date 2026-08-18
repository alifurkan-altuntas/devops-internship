# 🔍 Kubernetes Terminology Deep Dive — etcd, Raft, CNI/kube-proxy (in progress)

Based on feedback from Edib Bey, I researched and went deeper into some topics that stayed shallow in the Cluster Architecture document from Phase 28. This document is the record of that research — over time it'll grow with new sections (kubernetes.io and microservices.io readings).

---

## etcd — General Working Principle

I had seen etcd in Phase 28 as something specific to Kubernetes, but it's actually a general distributed systems tool, independent of Kubernetes. Researching it, I arrived at the following:

- **It works like a "board of directors"** — multiple copies (odd-numbered membership), all holding the same information, no one can unilaterally decide anything, majority approval is required. This prevents two different nodes both claiming "I'm the leader" at once (**split-brain**).
- **Its real value isn't just "keeping history"** — every change gets a sequence number (**revision**), just like commit order on GitHub. If someone tries to overwrite based on stale information, the operation gets rejected (the same logic that prevents two simultaneous withdrawal requests from conflicting on the same ATM account).
- **The watch mechanism** — interested parties don't keep asking "did it change yet?" (polling), they get notified automatically when something changes (like subscribing to a YouTube channel). If the connection drops, it can pick up from its last known revision and ask "what changed since then" (like a `git pull`) to catch up.
- **It has alternatives** — Zookeeper (older, part of the Hadoop ecosystem), Consul (more focused on service discovery and health checking). etcd stands out because it's embedded in Kubernetes' control plane and has high raw key-value performance.

---

## Raft — The Consensus Protocol etcd Uses

Raft is a sort of helper mechanism for etcd (in our board-of-directors analogy) — if the chairperson on the board can no longer be active, it triggers the process of confirming that inactivity and electing a new chairperson.

**How it works:** The leader sends a regular signal (**heartbeat**, roughly every 100ms) to the other members saying "I'm still here." Each member keeps its own counter (**election timeout**, 150-300ms) — if no heartbeat arrives within that time, the member decides on its own "there's no leader, I'm a candidate" and votes for itself.

Confusion is avoided because everyone's waiting period is different (**randomized**), and this affects the voting — usually one member becomes a candidate before the others, and the rest (whose own timers haven't expired yet) vote for it, so a majority forms quickly. In the case of a possible second round (if two members become candidates at nearly the same time and votes get split, called a **split vote**), the randomness usually resolves it without needing a third round.

The **term** number adds another layer of safety — every election round has a number, and a lower term can never override a higher one. So if a member drops off the network for a long time and comes back with stale information ("I'm still the leader of term 3"), it learns the current term (say, term 5), updates itself automatically, and rejoins the board as an ordinary follower without causing confusion.

---

## CNI / kube-proxy — Pod-to-Pod and Service-Based Communication

I worked through the networking topic Edib Bey called "more critical" using an apartment/package delivery scenario.

### The Core Problem — Pods on Different Nodes Finding Each Other

An apartment/unit analogy can be used for pods on different nodes to communicate with each other — the physical network (the postal service) only knows the address of the apartment buildings (nodes), not the individual units (pods). There are two ways to solve this:

1. **The postal service puts all packages headed to the same building into one big envelope, delivers it to that building's security desk, and the security desk opens it and distributes the individual envelopes to the units** — this approach makes sense when the postal service can't interfere with the building directly (like a VPS, a rented server where you have no access to the underlying physical network). This corresponds to the **overlay/VXLAN** approach.
2. **Since I own the postal service, I send packages directly to the units in the buildings, because I can teach the postal service the unit addresses** — viable when you have full control over your own physical infrastructure. This corresponds to the **BGP** approach.

I looked for real proof on my own VPS (a rented server, using VXLAN) — found a network interface called `vxlan.calico` (via `ip link show`), and confirmed Calico was running with `VXLANMODE: Always` (via `calicoctl get ippool`).

### The Changing-IP Problem in Pod-to-Pod Communication — Service

Pods talk to each other, but pod IPs can change, and that causes a problem. Continuing the package delivery analogy: an apartment building has tenants that keep changing (pods come and go, each with a different unit/IP), but the building's entrance has a fixed "package reception number" — the courier always calls the same number, and that number knows which unit to route to, no matter who's currently living there. The sender never has to know "which unit the current tenant is in," they just need the fixed reception number. This fixed number corresponds to Kubernetes' **Service** resource — pods are the changing unit/tenant, the Service is the fixed reception number.

### kube-proxy — Distributed Routing

The job of translating traffic sent to a Service's IP into the real pod's IP isn't done in one central place — it's done **on every node itself** (as a DaemonSet). This has two benefits:

- **Resilience:** In a crash, the whole system doesn't go down, only that node does — a node handling its own traffic makes it act like a regional manager, which also makes management easier ("this pod is on this node, so I can fix it from that node").
- **Speed:** Like a line at a government office — if everyone with different needs is forced through one single counter, the line moves slowly, but if everyone goes to the counter for their own category, the line shortens and speed increases. In a centralized approach, if traffic arrives at 2 nodes at the same time, one gets processed first and then the other, and delay increases as traffic grows — when nodes handle their own traffic, it can be processed in parallel, quickly.

**iptables vs IPVS:** The way kube-proxy does this Service→pod translation splits into two methods. `iptables` scans rules sequentially (top to bottom) — fine when there are few Services, but as the count grows (say, 10,000), the list to scan gets longer and delay increases. `IPVS` works more like an alphabetical/indexed lookup, keeping the lookup time nearly constant no matter how much the Service count grows.

---

ℹ️ _These sections were built entirely through research and back-and-forth questions — concepts were understood first through analogy (board of directors, apartment/package delivery, government office line) before being matched to the real terminology (heartbeat, election timeout, term, VXLAN, BGP, Service, kube-proxy, iptables/IPVS)._
