# ☸️ Kubernetes Fundamentals — GitOps, Why Containers, Docker, Cluster Architecture, kubectl

27th phase covered Docker's alternatives (Podman, containerd, CRI-O, Buildah). This phase I moved on to Kubernetes — following the k8s-tr.github.io roadmap, I worked through the Fundamental Concepts section (GitOps, Why Containers, Docker, Cluster Architecture, kubectl) start to finish.

---

## 1. GitOps

Learned that this is an approach to managing and automating infrastructure and application deployments based on documents and config files in a Git repository.

In the traditional approach, changes are made directly to the cluster (things like `kubectl apply`) — this change only lives in terminal history, no one can trace who did what and when. GitOps flips this: the cluster is never touched directly. Instead, the "desired state" is written as YAML into a Git repo. A tool (like ArgoCD) continuously watches this repo and automatically closes the gap between the repo and the cluster's actual state.

I understood this as the same "document everything and push it" habit I already have with my own GitHub repo, applied to real running infrastructure — Git history becomes the change record, `git revert` makes rollback easy, and no one needs direct access to the cluster, they just push to Git.

Can be thought of like updating a blueprint instead of giving a construction worker verbal instructions — the worker keeps checking the blueprint and adjusting the building to match it.

---

## 2. Why Containers?

### Container History

Learned that the container idea goes back to **1979 (chroot)** — wasn't expecting it to be that old. Everyone assumes Docker (2013) is where containers started, but the idea predates it by 34 years:

```
chroot (Unix)     → 1979
FreeBSD Jails     → 2000
LXC (Linux)       → 2008
Docker            → 2013
Kubernetes        → 2014
Openshift         → 2011, 2015
```

### Why We Need Containers

Covered eight points — agile app deployment, CI/CD, immutability (eliminates the "worked on my machine" problem), observability, application-centric management, microservices, resource isolation, resource utilization efficiency.

### Why We Use Kubernetes

Saw seven main headings: service discovery and load balancing, storage management, automated rollouts/rollbacks (the foundation of GitOps), automated bin packing (scheduling), self-healing, secret and configuration management, extensibility.

**Self-healing** stood out to me specifically — learned that Kubernetes restarts failed containers, kills ones that don't respond to health checks, and never sends traffic to a container until it's ready. Connected this to the `healthy`/`unhealthy` states we tested with HEALTHCHECK back in Phase 26 (IaC Scanning) — a health check detects the container's status and can trigger intervention based on it; we only ever _saw_ the status in `docker ps`, Kubernetes actually _acts_ on it automatically.

---

## 3. Docker (k8s-tr's Angle)

This page mostly covered commands I already knew (`docker run`, `docker ps`, `docker build`, `docker tag`, `docker push`). The one genuinely new technique was **`envsubst`**:

```dockerfile
FROM nginx
ENV APP_LOCATION google
ENV NGINX_PORT 8080
COPY config/orig.conf /etc/nginx/conf.d/orig.conf
RUN envsubst < /etc/nginx/conf.d/orig.conf > /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/conf.d/orig.conf
```

The config file uses variables like `${NGINX_PORT}`, and `envsubst` fills these placeholders with the real values defined via `ENV`. I compared this to defining a variable in code — the actual values (google, 8080) that go in place of the variables are written afterward, in the Dockerfile. The same Dockerfile can be built with different `ENV` values to get the same image structure configured differently for different environments (dev/test/prod) — I think of this as a simplified precursor to Kubernetes ConfigMaps (which I'll see later, in Basic Resources).

---

## 4. Cluster Architecture

I built this section around a **hotel** — starting from the three-plane split and mapping every component into the same scenario:

- **Data plane** = the hotel's guests and the actual service they receive
- **Control plane** = the front desk and hotel management
- **Management plane** = accounting/payments — a subset of the control plane

### Control Plane Components

**kube-apiserver = Front Desk.** Everyone arriving at the hotel goes through the front desk first — reservation/registration gets checked. No one can skip the front desk and walk straight into a room. This is the component that accepts and validates every REST request coming into the cluster, and is the single connection point to etcd. Runs as a static pod: `/etc/kubernetes/manifests/kube-apiserver.yaml`.

**etcd = The Hotel's Guest Register.** Who's currently staying in which room, who stayed there in the past — it's all in this register. When a guest checks out and a new one checks in, the old entry isn't crossed out — a new line gets added to the register instead. **The old value is never deleted — there's a law of immutability.** Cleaning up old entries requires a separate "compact" operation.

The register is kept as an **odd number** of copies (3, 5, etc.) — because the weakness of even numbers, splitting evenly into a tie, disappears with odd numbers; there's always a clear majority (leader election via the Raft algorithm).

Entries in the register are kept in alphabetical/sorted order (like a dictionary), stored in a flat layout (a binary key space). Unlike the hotel's other staff (static pods), this register service runs as a **separate, independent system** (a standalone Docker container). Its own settings can be checked from a special outside window (`/config`, over HTTP). Resource-wise it doesn't need much CPU, but on live systems 8GB of memory and an average disk are enough.

**A critical warning I also learned:** if this register system becomes unstable (insufficient resources, network issues), the tables can never reach a clear majority/leader. In that case, the hotel **cannot make any changes** to its current state — no new guest can be accepted, not even a new room can be opened. This is why etcd is recommended to run in an isolated, stable environment — the stability of the entire cluster depends on this one register.

**kube-controller-manager = The "Is Everything Okay" Controller.** Continuously checks the gap between the desired state and the actual state and tries to fix it — the same thermostat logic we talked about in GitOps.

**kube-scheduler = Room Assignment Staff.** Once the front desk accepts a guest, this is who decides which physical room (node) they go to — looking at criteria like resource needs, affinity/antiaffinity, taints/tolerations, data locality. **It doesn't matter what language the app inside the pod is written in** — it just checks whether the resources needed to run exist.

### Node Components

**kubelet = Floor Supervisor.** Every floor has a supervisor. Their first job is to report to the central office "I'm here" (registering the node with the API Server as a Node resource). Their duties:

1. Gets special access codes from the front desk (downloading pod secrets)
2. Attaches extra storage to a room (mounting volumes)
3. Instructs the room service team (running the container)
4. Reports status regularly to central (reporting node/pod status)
5. Checks doors/lights (running liveness probes)

**coredns = The Hotel's Internal Phone Directory.** Say "room 302" and it automatically connects you to the right place — like a hosts file on a computer, it handles in-cluster DNS resolution. Runs as a deployment in the `kube-system` namespace.

**kube-proxy = Internal Switchboard Routing.** Handles reachability of Services/Endpoints, node network rules, and assigns virtual IPs to Services/Pods. Runs as a DaemonSet (one copy per node).

**container-runtime = Room Service/Maintenance Crew.** The layer that actually carries out the floor supervisor's instructions — runs as a system service.

**CNI (Calico) = The Hotel's Corridor/Access System.** Provides the cluster's network infrastructure, connectivity between pods. `calico-kube-controllers` runs as a deployment, `calico-node` as a daemonset. Alternatives: Cilium, Weave.

---

## 5. kubectl

```bash
echo $KUBECONFIG
kubectl config view
```

`KUBECONFIG` is like a keyring — it determines which cluster you connect to and with what permissions.

**Discovery commands:**

```bash
kubectl get nodes
kubectl get nodes --show-labels
kubectl get namespaces
kubectl get pods -A -o wide
```

**Creating a namespace** — like opening a new wing at the hotel, an isolated area with its own records:

```bash
kubectl create namespace mystuff
kubectl config set-context --current --namespace=mystuff
kubectl create deployment myapp --image=quay.io/rhdevelopers/quarkus-demo:v1
```

**Scaling and rolling updates** — a live example of the roadmap's "Continuous Updates" topic, being able to change a running app's version without downtime:

```bash
kubectl scale deployment myapp --replicas=3
kubectl set image deployment/myapp quarkus-demo=quay.io/rhdevelopers/myboot:v2
```

**Connecting to a pod** — exactly the same habit as `docker exec -it <container> sh`, just pod instead of container:

```bash
kubectl exec -it quarkus-demo-deployment-5979886fb7-c888m -- curl localhost:8080
```

**Cleanup** — namespaces are like folders, deleting one automatically removes everything inside it (deployment, pod, service), no need to handle them one by one:

```bash
kubectl delete namespace mystuff
```

---

## 📊 Summary

| Topic                        | What I Learned                                                                                          |
| ---------------------------- | ------------------------------------------------------------------------------------------------------- |
| GitOps                       | Instead of touching the cluster by hand, a tool automatically applies the target written to Git         |
| Container history            | Goes back to 1979 (chroot), 34 years before Docker                                                      |
| envsubst                     | The technique that fills config variables with the Dockerfile's ENV values                              |
| Cluster architecture         | Via the hotel analogy — front desk (apiserver), guest register (etcd), floor supervisor (kubelet), etc. |
| etcd immutability            | When a value is updated, the old one isn't deleted, a new version is added                              |
| etcd odd-numbered membership | Even-numbered voting can tie, odd-numbered always produces a clear majority                             |
| self-healing                 | Automatic intervention based on health check status — the cluster-level version of HEALTHCHECK          |
| kubectl                      | Most Docker commands have a direct equivalent (exec, ps→get pods, etc.)                                 |

---

ℹ️ _This phase was entirely conceptual — terminology and architecture were reinforced by following the k8s-tr.github.io roadmap before setting up an actual cluster. Hands-on setup comes in the next phase._
