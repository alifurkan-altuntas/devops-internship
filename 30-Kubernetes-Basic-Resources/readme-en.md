# ☸️ Kubernetes Basic Resources — Pod, ReplicaSet, Deployment, Service, ConfigMaps, Secrets, Canary Deployment

29th phase compared five installation methods. This phase I worked through the roadmap's Basic Resources section — for each topic, first with a real-world analogy, immediately followed by a technical explanation, and proving as much as possible with real tests.

---

## 1. Pod, ReplicaSet, Deployment

Can be thought of like a manager giving a task to an employee — the manager (kube-controller-manager) doesn't do the work itself, it tells the employee (ReplicaSet) "how many there should be," and the employee tracks that and fills the gap if anything's missing.

**Technically:** A standalone Pod doesn't come back when deleted — it has no self-healing ability. That ability shows up with **ReplicaSet**: ReplicaSet continuously counts "how many pods are there" (via label-based `selector`), and if short, creates a **new** pod — not a revival of the deleted one, a completely new name/IP. Learned this is a loop inside kube-controller-manager (Phase 28's "is everything okay controller").

When ReplicaSet's `template` field changes (anything, even an environment variable, not just the image), Deployment treats it as a "new version" and automatically triggers a **rolling update**. Proved this with a real test: used `kubectl set image` to go from v1 to v2, watched live with `-w` — the new pod became `Running` first, only then did the old pod move to `Terminating`, never a moment with zero pods. Saw a transient `Error` state, confirmed via `describe`/`get pods` it was just the normal appearance of a container shutting down.

---

## 2. Service

### The Core Mechanism — Selector, Endpoints, DNS

An apartment building has tenants that keep changing (pods come and go, each with a different IP), but the entrance has a fixed "package reception number" — the courier always calls the same number, no matter who's currently living there.

**Technically:** This fixed number is the **Service**. A pod comes up, gets an IP, has a label. The Service has a `selector` looking for that same label. The actual work is done by **DNS** (coreDNS) — once the Service exists, a name record is created automatically, resolving to whichever pods currently match the label. Proved this with the **Label Magic** test: set up a Service looking for a label (`inservice: mypods`) that no pod had initially, `endpoints` came back empty; manually adding and removing this label on pods updated `endpoints` **instantly** without ever restarting the Service — even merged pods from two completely different Deployments into the same Service.

### NodePort and LoadBalancer

Every apartment building (node) has its own known side door (a number in the 30000-32767 range) at its entrance — whichever building you go to, you can enter through this side door and get routed to the right unit. LoadBalancer is like a **single front desk** set up at the entrance to the whole city — everyone coming from outside only knows this one desk's address, and the desk decides which building's side door to route them to. But if there's no one to set up this desk (a cloud provider), the desk never opens.

**Technically:** LoadBalancer is actually built on top of NodePort — on my own VDS (no cloud provider integration), proved that `EXTERNAL-IP` stays `<pending>` forever, but the automatically assigned NodePort (the side door) worked fine over the real IP.

Also solved a puzzle: `curl localhost:31720` failed but `curl 91.151.88.38:31720` worked. The cause is that `127.0.0.1` has a **relative meaning** — "the server itself" from the sender's perspective, but "the pod itself" from the pod's perspective. If this relative meaning isn't corrected during NAT (missing masquerade), the pod's reply goes to the wrong place — this is called **hairpin NAT**. Also proved via an empty `ss -tlnp | grep 31720` result that NodePort isn't a real "listener," it's iptables/DNAT-based redirection.

### ExternalName

Like calling a package reception number and having it tell you "the number you actually want is in another city, call this instead" — the courier company itself never goes to that city, it just points you to the right number.

**Technically:** A special Service type with none of the others' `selector`/`endpoints` — it only creates a DNS **CNAME** record and never carries any traffic itself. Pointed an ExternalName Service at `google.com`, ran a DNS query from inside a test pod — got real Google IPs back, `kube-proxy`/`iptables` never got involved. `CLUSTER-IP: <none>` and no `endpoints` object being created at all confirmed this runs entirely "outside, not inside."

---

## 3. ConfigMaps

A centralized, publicly readable resource that multiple Deployments can reference, taking effect once updated — can be thought of like an **official gazette**: a single publication that can affect multiple "institutions" (Deployments), nothing secret about it.

**Found and proved a critical asymmetry:**

- ConfigMap used **as an environment variable** → static, only read once when the container starts, doesn't update even if changed unless the pod restarts
- ConfigMap **mounted as a file (volume)** → dynamic, kubelet periodically checks (~every 60 seconds) in the background and updates it **live**, no pod restart needed

Proved this with a real test: opened a pod with a volume-mounted ConfigMap, changed the ConfigMap, saw the file's content change without the pod ever restarting (`RESTARTS: 0`, `AGE` kept climbing uninterrupted).

Also tested creating a ConfigMap **in bulk** from a `.properties` file with `--from-env-file`, and mounting a shell script inside a ConfigMap as an **executable file** in the container — both confirmed with real output.

---

## 4. Secrets

### Base64 Is Not Encryption

Whoever holds the key to the door (kubectl/etcd access) already speaks the language spoken inside (base64) — because it's a **universal standard** (RFC 4648) everyone already knows, not a "secret language" specific to Kubernetes. Someone with a visa already understands everyone in the country because they already speak the local language.

**Technically:** Noticed a contradiction on the page — one part said "automatically encrypted," another said "not encrypted, just base64 encoded." Resolved this with a real test: decoded the value from `kubectl get secret -o yaml` with `base64 --decode`, **with no key or password at all**, and got the real password back. **Also proved this by looking directly at etcd:** used `etcdctl get /registry/secrets/...` and saw the Secret's raw data in etcd was **plaintext** — didn't even need kubectl.

### Real Encryption — EncryptionConfiguration

If a language everyone knows (base64) doesn't offer enough protection, the conversation needs to be turned into a secret code that only someone holding a **special codebook (key)** can decipher — knowing the language is no longer enough, you need that special codebook too.

**Technically:** Set this up and tested before/after side by side:

1. Created an `EncryptionConfiguration` file with a randomly generated AES key
2. Added `--encryption-provider-config` and the necessary volume mount to kube-apiserver's static pod manifest
3. **Old Secret** (written before encryption) stayed plaintext in etcd — encryption **doesn't apply retroactively**
4. **New Secret** (written after encryption) appeared in etcd with a `k8s:enc:aescbc:v1:key1:` prefix, followed by completely meaningless cryptographic data — can no longer even be decoded with `base64 --decode`

This concretely showed why companies in the real world layer on additional protection like `EncryptionConfiguration`, HashiCorp Vault, or the External Secrets Operator — the default Secret protection isn't as strong as the name suggests.

Also tested and proved that volume-mounted Secrets update **live**, just like ConfigMaps.

---

## 5. Canary Deployment

Comes from miners using canary birds for gas detection — the canary detects danger early through a **small group**, before everyone is affected.

**Technically:** Two Deployments with the same label (one with many replicas, the stable old version; one with few replicas, the new test version) sit **permanently side by side** in the same Service's pool. The difference from rolling update — rolling update fully replaces old with new, canary keeps both **running together**, with traffic split between them proportional to replica count.

Proved this with a real test: 3 replicas of `v1` + 1 replica of `v3`, both connected to the same Service. Of 10 requests, 8 went to `v1` ("Aloha" response), 2 went to `v3` ("Jambo" response) — roughly a 3:1 ratio, matching the replica count. If there's a problem, `v3` can be pulled back **instantly** by scaling its replicas to zero, with no impact on the remaining users.

---

## 📊 Summary

| Topic                     | What I Learned                                                                             |
| ------------------------- | ------------------------------------------------------------------------------------------ |
| ReplicaSet                | A deleted pod isn't revived, a new one is created — a loop inside kube-controller-manager  |
| Rolling update            | New pod comes up first, then old one shuts down — zero downtime                            |
| Service/DNS               | coreDNS does the actual work, selector→endpoints updates live                              |
| NodePort/LoadBalancer     | LoadBalancer sits on top of NodePort; hairpin NAT comes from 127.0.0.1's relative meaning  |
| ExternalName              | No selector/endpoints, just a DNS CNAME — carries no traffic at all                        |
| ConfigMap env vs volume   | Environment variable is static (needs pod restart), volume is dynamic (updates live)       |
| Secret base64             | Not encryption, a universal encoding — anyone can decode it                                |
| Secret encryption at rest | Off by default, enabled via EncryptionConfiguration, doesn't apply retroactively           |
| Canary Deployment         | Two same-labeled Deployments sit permanently side by side, traffic splits by replica ratio |

---

ℹ️ _All tests were performed on a real Ubuntu VPS (on the Kubespray cluster) — each topic was first understood conceptually through an analogy, then proven with technical terminology and real `kubectl`/`etcdctl` tests._
