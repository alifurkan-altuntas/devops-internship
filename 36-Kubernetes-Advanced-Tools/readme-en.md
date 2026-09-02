# ☸️ Kubernetes Advanced Topics — Network Configuration, Gateway API, Kubectl Shortcuts

Phase 35 covered Kyverno and NeuVector. This phase covered the roadmap's Advanced Topics section — three topics, all proven with real tests.

---

## 1. Network Configuration

**Software example:** Knowing the physical standard of an electrical outlet (the CNI spec) isn't enough — you also need to know which company's cable (Calico, Flannel) you're using. CNI is the "interface standard"; Calico is a product that **implements** that standard.

**Real function:** In Phase 28, CNI was covered only conceptually — this phase inspected its **real files**.

**Cross-reference:** In `/etc/cni/net.d/10-calico.conflist`, saw that Calico **chains three separate plugins**: `calico` (the main network setup), `portmap` (the underlying layer of Phase 30's NodePort logic), and **`bandwidth`** (a feature never touched before). In `/opt/cni/bin/`, alongside Calico's own binaries, saw **other CNI plugins** like `flannel`, `bridge`, `macvlan` — unused but ready — proof that CNI is genuinely a pluggable standard.

While researching, found an **old, documented unit bug** on GitHub: _"Setting `kubernetes.io/egress-bandwidth: "1M"` actually only applies `1Kbit`."_ Proved with a real test that this **has since been fixed** — `tc qdisc show` output correctly showed `rate 1Mbit`, and real traffic measured with `iperf3` confirmed it: the first second spiked to `182 Mbit/s` thanks to accumulated "credit" (`burst: ~20MB`), then dropped to `0 bit/s` once the credit ran out — a behavior that forces an average of `1 Mbit/s` (a token bucket mechanism).

**YAML:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: bw-client
  annotations:
    kubernetes.io/egress-bandwidth: "1M"
spec:
  containers:
    - name: iperf
      image: networkstatic/iperf3
      command: ["sleep", "infinity"]
```

---

## 2. Gateway API

```mermaid
graph LR
    C[External Request] --> GW[Gateway - port 80 listener]
    GW --> HR[HTTPRoute - routing rule]
    HR -->|path: /| SVC[Service: myboot]
```

**Software example:** If Ingress is a receptionist who can only route HTTP, Gateway API is a multilingual concierge who can route any kind of guest (HTTP, gRPC, raw TCP/UDP).

**Real function:** A `Gateway` resource defines a "listener" (which port/protocol is open); `HTTPRoute` carries the **actual routing logic** — replacing Ingress's `rules` field, but with a far more flexible structure.

**Cross-reference:** Found the page's NGINX Gateway Fabric install command was **incomplete/incorrect** — it said `helm upgrade` but there was never a `helm install` step, as if upgrading an already-installed release. Researched and used the correct first-install command (`helm install`). Noticed in the Gateway API's CRD list (`httproutes`, `grpcroutes`, `tcproutes`, `tlsroutes`, `udproutes`) that it supports protocols Ingress **doesn't** — comparing against Phase 31's test showing `kubectl explain service.spec` has no path/host field, while Ingress only has HTTP path/host.

Proved with a real test: that the installed `Gateway` + `HTTPRoute` chain **genuinely** routed traffic to Phase 30's `myboot` application (a real response received via `curl` through the `NodePort`).

**YAML:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-nodeport-gateway
  namespace: nginx-gateway
spec:
  gatewayClassName: nginx
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-route
  namespace: gwtest
spec:
  parentRefs:
    - name: my-nodeport-gateway
      namespace: nginx-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: myboot
          port: 8080
```

---

## 3. Kubectl Shortcuts

**Software example:** Like assigning a keyboard shortcut (`Ctrl+C`, `Ctrl+V`) to a frequently used combination — shrinking a long command into a few easy-to-remember letters.

**Real function:** `alias` (a fixed-text shortcut) vs `function` (a shortcut that can take parameters and contain logic) — the difference showed why parameterized shortcuts like `kns` (switches namespace) and `kx` (execs into a pod) need to be `function`s, not `alias`es.

**Cross-reference:** While adding the page's multi-line shortcut definitions to `.bashrc`, proved with a real test that a **multi-line heredoc (`cat <<EOF`) block breaks in the terminal**, and nothing was actually added — proving the risk of assuming "added" without checking the file. Fixed it with single-line `echo >>` commands instead.

Proved with a real test: that `kns kube-system` **exactly** performed the long `kubectl config set-context --current --namespace=kube-system` command (the following `kgp` genuinely listed `kube-system` pods); that `kx with-label-pod` replaced `kubectl exec -it with-label-pod -- bash` and **genuinely entered the pod** (a `root@with-label-pod:/#` prompt).

**YAML/Command:**

```bash
kns() { kubectl config set-context --current --namespace="$1"; }
kx() { kubectl exec -it "$1" -- bash; }
```

---

## 📊 Summary

| Topic                 | What Was Learned                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------------ |
| Network Configuration | CNI made concrete with real files; proved an old bandwidth unit bug has since been fixed         |
| Gateway API           | Ingress's more flexible, multi-protocol successor; found and fixed an incomplete install command |
| Kubectl Shortcuts     | The alias/function distinction, and the real risk of heredoc breaking silently in the terminal   |

---

ℹ️ _All tests were performed on a real Ubuntu VPS (on the Kubespray cluster) — each topic proven with a software-ecosystem example, its real function, cross-references to related phases, and real YAML/kubectl tests. Along the way, an old GitHub bug was found to no longer apply, an install command was found to be incomplete, and a heredoc block was found to silently fail in the terminal — all identified and corrected._
