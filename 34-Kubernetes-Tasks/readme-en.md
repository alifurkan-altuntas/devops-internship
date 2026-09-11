---
layout: page
---

# ☸️ Kubernetes Tasks — Security, Internal Load Balancing, Log Collection, Best Practices, CKA Topics

33rd phase completed the Additional Tools section. This phase I worked through the roadmap's Tasks section — five topics, all proven with real tests.

---

## 1. Security — JVM Memory Management

**Software example:** Like a tenant choosing to use only **part** of the total electricity quota the landlord provides — the landlord (Kubernetes) gives 800MB, but the tenant (JVM) decides on its own to use only 200MB, wasting the rest.

**Real function:** Java 10+ JVMs are "container-aware" — they can see the container's memory limit. But their default behavior is **very conservative**: in containers above 512MB they allocate only **25%** of the limit to heap, and in containers below 256MB, **50%**.

**Cross-reference:** This adds a **JVM-specific layer** to what I learned about `requests`/`limits` in Phase 31 — Kubernetes setting a memory limit isn't enough, the application inside (like a JVM) also needs to **interpret that limit correctly**.

Proved with a real test: a JVM in a `200Mi` limit (small category) allocated `50%` (100MB) to heap, one in an `800Mi` limit (large category) allocated `25%` (200MB); proved with `MaxRAMPercentage=75.0` that this ratio is **manually controllable** (jumped to 600MB).

**YAML:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: jvm-tuned
spec:
  containers:
    - name: app
      image: eclipse-temurin:21-jdk
      resources:
        limits:
          memory: "800Mi"
      env:
        - name: JAVA_TOOL_OPTIONS
          value: "-XX:MaxRAMPercentage=75.0"
```

---

## 2. Internal Load Balancing

**Software example:** Like an office phone switchboard routing incoming calls to different branches **outside the company** — the switchboard (nginx) routes based only on the **number (IP:port)**, not the content of the call.

**Real function:** nginx's `stream` block load-balances **raw TCP traffic** to any target (IP/hostname) **manually defined** in a ConfigMap — these targets don't have to be a Service Kubernetes knows about; they can even be real servers outside the cluster.

**Cross-reference:** This is a **fundamentally different** third method from Phase 31's Ingress (L7, reads path/host) and Service (L4, but only a pod selector) — it never uses Kubernetes' own selector mechanism at all. The `subPath` field lets you mount a **single file** from a ConfigMap without disturbing the rest of the directory.

Proved with a real test: got **exact round-robin** distribution (`BACKEND-1, BACKEND-2, BACKEND-1...`) between two backends.

**YAML:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-lb-conf
data:
  nginx.conf: |
    stream {
        upstream myservis_lb {
        server backend1.lbtest.svc.cluster.local:5678;
        server backend2.lbtest.svc.cluster.local:5678;
      }
          server {
            listen     9200;
            proxy_pass myservis_lb;
        }
    }
```

---

## 3. Log Collection

**Software example:** Like talking on the phone with one person (`kubectl logs`) versus listening to **multiple people at once** on a conference call (`stern`).

**Real function:** `kubectl logs` requires a **single pod name** — seeing multiple pods' logs requires separate commands. `stern` follows **all pods matching a regex simultaneously**, in a single, color-coded command.

**Cross-reference:** Researched that the page's `wercker/stern` repo is abandoned, used the currently maintained fork `stern/stern` instead.

Proved with a real test: `stern my-deployment` showed the startup logs of 3 different pods **on a single screen, interleaved**, each line labeled with its source pod.

---

## 4. Best Practices

**Software example:** Like a building requiring both a **mandatory security check** (Pod Security Admission) and a **limit on how many people can be inside at once** (ResourceQuota) — the two constrain different things.

**Real function:** Deep-tested two items from the checklist — **Pod Security Admission** (labeling a namespace with a security standard and rejecting non-compliant pods at admission time) and **ResourceQuota** (capping a namespace's **total** resource usage — pod count, CPU).

**Cross-reference:** Researched and found that the checklist's `PodSecurityPolicy` item **no longer exists** (completely removed in Kubernetes v1.25) — some checklist items are outdated. This showed that ResourceQuota is a **namespace-level** layer on top of Phase 31's **pod-level** `requests`/`limits`.

Proved with a real test: a privileged (`privileged: true`) pod in a `restricted`-labeled namespace was **rejected at admission time** (with an error listing five separate security rules); a `pods: "2"`-quota namespace **rejected the 3rd pod** with an `exceeded quota` error.

**YAML:**

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
spec:
  hard:
    pods: "2"
    requests.cpu: "500m"
```

---

## 5. CKA Topics

**Software example:** Like a university curriculum producing a **summary** of the courses a student has already taken — this page doesn't teach anything new, it maps what's already been learned during the internship onto the CKA certification's categories.

**Real function:** Realized that almost all nine of CKA's categories (Cluster Architecture, Containers, Workloads, Services/Networking, Storage, Security, Policies, Scheduling/Eviction, Cluster Management) have already been covered with real tests since Phase 28.

**Cross-reference:** Proved that the "eviction" concept in the "Scheduling and Eviction" category directly matches the `disk-pressure` taint I **actually encountered** during Phase 33's Istio test (Kubernetes automatically protecting itself by taking action on pods when a node runs low on resources).

---

## 📊 Summary

| Topic                   | What I Learned                                                                                    |
| ----------------------- | ------------------------------------------------------------------------------------------------- |
| Security (JVM)          | JVM defaults to using only 25-50% of a container's memory limit, adjustable with MaxRAMPercentage |
| Internal Load Balancing | nginx's stream block TCP-load-balances to manually defined targets, no Kubernetes selector needed |
| Log Collection          | stern does multi-pod tailing in one command, which kubectl logs cannot                            |
| Best Practices          | Pod Security Admission (namespace-level security), ResourceQuota (namespace-level quota)          |
| CKA Topics              | What was learned during the internship already covers nearly all CKA categories                   |

---

ℹ️ _All tests were performed on a real Ubuntu VPS (on the Kubespray cluster) — each topic proven with a software-ecosystem example, its real function, cross-references to related phases, and real YAML/kubectl tests. Along the way, outdated/removed sources (stern's abandoned original repo, PodSecurityPolicy's complete removal in v1.25) were identified and replaced with current equivalents._
