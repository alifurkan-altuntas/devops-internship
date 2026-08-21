# ☸️ Kubernetes Installation Methods — Vagrant, kubeadm, MicroK8s, minikube, Kubespray

28th phase covered Kubernetes fundamentals (GitOps, cluster architecture, kubectl). This phase I compared the five installation methods the k8s-tr roadmap suggests (Vagrant, Kubespray, MicroK8s, kubeadm, minikube) — one by one, by actually installing and testing each.

---

## A Clarification First — What I'm Actually Learning

I'm not learning five different Kubernetes — Kubernetes itself (Pod, Service, kube-apiserver, etcd, kubectl commands) stays the same across all of them, that was already covered in Phase 28. What I'm learning here is **different methods for installing the same Kubernetes** — like taking a car, a bus, or walking to reach the same house: the house you arrive at (Kubernetes itself) is the same, only the road (the installation method) differs.

In the real world, nobody tries all of these at once either — a company picks **one and sticks with it** based on need: managed services (EKS, GKE, AKS) in the cloud, Kubespray/kubeadm on bare metal, lightweight distributions like MicroK8s for edge/IoT, minikube on a developer's own laptop. I tried all of them myself here to see the real differences between them.

---

## 1. Vagrant — Why I Didn't Attempt It

In Phase 02 (very early in the internship) I had set up Vagrant on my own computer (with the VMware provider) and ran into two real issues ("no usable providers" and a wrong box name error) — that experience was already documented.

But before attempting Vagrant on this VPS, I checked whether the server technically even allows it:

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

```
0
```

The result was `0` — **nested virtualization is completely disabled** on this VPS. This means VirtualBox/VMware can't start a virtual machine on this server at all, not just Vagrant, no KVM-based virtualization would work either. No need to even try — technically impossible, confirmed.

---

## 2. kubeadm — The Longest, Most Educational Journey

### Prerequisites

Disabled swap (`swapoff -a`), loaded kernel modules (`overlay`, `br_netfilter`), and set the required sysctl parameters (`ip_forward=1` etc.).

### CRI-O Installation — First Outdated-Source Issue

The CRI-O repo address on the k8s-tr page (`devel:kubic:libcontainers`) **no longer worked** — this repo structure has been removed. I researched and used the current method (`isv:/cri-o:/stable`).

### kubeadm/kubelet/kubectl Installation — Second Outdated-Source Issue

The same problem came up again — k8s-tr's `apt.kubernetes.io` address has been **deprecated since 2023**. I used the current `pkgs.k8s.io` address instead.

### First `kubeadm init` — Swap Came Back

The first attempt failed. Checked the kubelet logs: swap had turned back on. Cause: `swapoff -a` was temporary, an entry in `/etc/fstab` was automatically re-enabling swap on reboot. Commented out the swap line in `/etc/fstab` to disable it permanently.

### Second `kubeadm init` — Successful, Then a Mix-Up

Once swap was permanently off, `kubeadm init` completed successfully. But afterward I ran a `kubeadm reset`, then tried `init` again forgetting `sudo` and without the correct parameters — got an error. Running the correct command again gave a clean, successful install.

### Node "Ready" But No CNI — Tested Without Assuming

`kubectl get nodes` showed the node as `Ready` even though I hadn't installed Calico yet — that looked suspicious. Tested it with a real nginx pod:

**Obstacle 1 — Taint:** The pod couldn't be scheduled onto any node. kubeadm automatically applies a `NoSchedule` taint to the control-plane node (normally worker nodes are separate). Since I only had one node, I removed it manually:

```bash
kubectl taint nodes ubuntu node-role.kubernetes.io/control-plane:NoSchedule-
```

**Obstacle 2 — No Real Network:** Once the taint was gone, the pod got stuck in `ContainerCreating`, no IP. Checked `/etc/cni/net.d/` — there was no valid Kubernetes CNI config at all, just a file CRI-O had left disabled and **a Podman network config left over from Phase 27** (Docker Alternatives, the Podman trial).

Installed Calico:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

**One Last Surprise — Wrong CNI Was Being Used:** Calico's pods came up `Running`, but the test pod got an IP like `10.88.0.4` — not the `192.168.x.x` range we wanted, that's **Podman's default network range**. The old `87-podman-bridge.conflist` file was still taking priority over Calico. Removing it (moved to `/root`) got the pod a real IP from the correct range, `192.168.243.193`.

---

## 3. MicroK8s — Nearly Zero Friction

```bash
sudo snap install microk8s --classic
```

Installed with a single command. Aside from a permissions fix (`sudo usermod -a -G microk8s altun`), no manual steps were needed — CNI, DNS, all came ready.

**A confusing moment:** I had defined `alias kubectl="microk8s kubectl"` — this later caused me to unknowingly **still be testing MicroK8s** while trying to test minikube (realized it when `type kubectl` showed "aliased to microk8s kubectl"). Removed the alias and switched to the real `kubectl` binary.

**Stopping it was also harder than expected:** the `microk8s stop` command **wasn't actually stopping it** — the `kubelite` process kept running in the background. The real fix was `sudo snap stop microk8s`, which stopped all services at the snap level.

Test: the pod went `Running` instantly, got a real IP, no extra steps needed.

---

## 4. minikube — Fast With the Docker Driver

```bash
minikube start --driver=docker
```

Since Docker was already installed on the server, it started directly without any additional virtualization.

**The same alias problem repeated:** the first test showed `kubectl get nodes` returning **`v1.35.6`** (MicroK8s's version), while minikube itself had said **`v1.35.1`** — a mismatch showing the old alias was still active. Fixed it with `unalias kubectl`, then confirmed I was really connected to `minikube` via `kubectl config current-context`.

Test: pod went `Running`, got an IP like `10.244.0.4` from minikube's own default network — CNI came ready again.

---

## 5. Kubespray — Longest, But Most Automated

### First Obstacle — Script Removed

The `contrib/inventory_builder/inventory.py` script the k8s-tr page recommends had been **permanently removed** in the `release-2.28` version I was using (removed in v2.27.0 — found a GitHub discussion confirming this). Edited the inventory (`inventory.ini`) manually — put my single server into `kube_control_plane`, `etcd:children`, and `kube_node` all at once.

### Second Obstacle — SSH Couldn't Connect to Itself

Ansible needs the server to be able to SSH into **itself** (the key on my own computer isn't on the server). Generated a new SSH key on the server, added it to its own `authorized_keys`, and confirmed it could connect to itself.

### Third Obstacle — sudo Password

Added the `--ask-become-pass` flag so Ansible could prompt for the sudo password.

### Fourth Obstacle — Old kubeadm etcd Port Conflict

17 minutes into the install, etcd failed to start: `bind: address already in use`, port `2380`. An old leftover `etcd` process from kubeadm was still running. Killed it, but this time **Kubespray's own etcd** (which was in an auto-restart loop) immediately took over and started successfully.

### Fifth Obstacle — The Deepest Issue: Leftover `/etc/kubernetes/` Directory

The next step, control-plane setup, failed with a **certificate file not found** error (`/etc/kubernetes/ssl/apiserver.crt not found`). Cause: the `/etc/kubernetes/pki/` directory left over from kubeadm was still there, while Kubespray expected a different directory structure (`/etc/kubernetes/ssl/`) — the two had conflicted.

Did a full cleanup:

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/pki /etc/kubernetes/ssl /etc/kubernetes/manifests
sudo rm -f /etc/kubernetes/*.conf /etc/kubernetes/*.yaml /etc/kubernetes/*.env /etc/kubernetes/*.old
sudo rm -rf /etc/cni/net.d/*
rm -f ~/.kube/config
```

After this full cleanup, ran the Ansible playbook from scratch — this time **`failed=0`**, completed entirely without issue (~20 minutes). Calico also got installed automatically, no manual taint removal or CNI config cleanup needed.

Test: node `Ready`, pod `Running`, real IP (`10.233.102.132`, from Kubespray's own Calico CIDR).

---

## 📊 Comparison

| Tool      | CNI Ready                     | Manual Steps                                                 | Clean Install Time\* |
| --------- | ----------------------------- | ------------------------------------------------------------ | -------------------- |
| Vagrant   | —                             | Impossible (no nested virtualization)                        | —                    |
| kubeadm   | ❌ Installed manually         | A lot (swap/fstab, outdated repos, taint, old Podman config) | ~15 min              |
| MicroK8s  | ✅ Ready                      | Almost none (just a group permission)                        | ~2 min               |
| minikube  | ✅ Ready                      | None                                                         | ~3 min               |
| Kubespray | ✅ Automatic (within Ansible) | SSH key setup + cleaning up old leftovers                    | ~20 min              |

\* These times are only the runtime of a **single, trouble-free** install command (`kubeadm init`, `ansible-playbook`, etc.) — for comparison purposes. **The real total time was much longer:** trying all five methods, finding and fixing the issues, took **3 days total** (August 15, 17, and 18) — mostly due to port conflicts, leftover files, and config clashes encountered with kubeadm and Kubespray in particular.

---

## 📝 General Lesson

When removing an installation, I had to really make sure it was actually removed — otherwise it causes conflicts and leads to errors in the next installation, wasting a lot of time. "I think I stopped it" isn't enough — it needs to be verified for real with `ss`/`ps`; we saw that even MicroK8s's `stop` command didn't actually stop it. Also, choosing the right tool based on the actual need matters a lot — all five do the same job, but which one is right depends on the environment (cloud, bare metal, edge, developer's laptop).

---

ℹ️ _All tests were done on a real Ubuntu VPS, across August 15-18, 2026 (a 3-day effort involving many real errors and fixes)._
