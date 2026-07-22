# 🔄 Docker Alternatives — Podman, containerd, CRI-O, Buildah

In phase 26 we covered IaC scanning, examining Docker's own codebase. This phase steps back to look at alternative container engines to Docker itself — why they exist, how they differ from Docker, and why Docker is still the most widely used.

---

## 1. Podman

A container engine from Red Hat that mimics Docker's commands almost exactly (`podman run`, `podman build`, `podman ps`). Docker's architecture has a constantly running background daemon (`dockerd`) — every command goes to this daemon, which runs with root privileges. Podman removes this daemon entirely: every container runs on its own, as a regular process, with no root required (**rootless**, **daemonless**).

In phases 24-25 we tried to make Docker secure after the fact with non-root containers, seccomp, AppArmor. Podman looks like it already solves part of this problem architecturally.

**Proved it:** running the same container in both and checking with `ps aux` on the host, Docker's process shows as `root`, Podman's shows as a regular user (`altun`). The daemonless claim was also confirmed — `podman.service` only runs briefly when a request comes in (socket-activated), while Docker's stays continuously active (`active (running)`, running for 3 weeks).

**Pros:** Command set very close to Docker (easy migration), rootless, daemonless, good systemd integration, official support in RHEL.
**Cons:** GUI not as mature as Docker Desktop, missing some Docker-specific features like Swarm, smaller ecosystem. No meaningful build speed difference found in practice (~8%, within measurement-noise range).

---

## 2. containerd

Actually a component that already exists inside Docker — it handles low-level tasks like pulling and running images, and Docker builds a user-friendly layer on top (CLI, networking, volume management). containerd can also be used standalone.

Kubernetes now uses containerd directly instead of Docker (dockershim was removed in Kubernetes 1.24) — **95%** of Kubernetes clusters run containerd.

**Pros:** Very lightweight, fast, the official/default runtime for Kubernetes.
**Cons:** Not user-friendly on its own, no easy CLI like `docker run` (needs extra tools like nerdctl), not practical for daily development.

---

## 3. CRI-O

Even more minimal than containerd, designed purely for Kubernetes. Its only job is to fulfill Kubernetes' "run a container" commands (CRI — Container Runtime Interface).

**Pros:** Most minimal, smallest attack surface, default in Red Hat OpenShift.
**Cons:** Nearly useless outside Kubernetes — not a general-purpose Docker alternative.

---

## 4. Buildah

Podman's sibling — but Buildah only builds, it doesn't run containers. Same logic as Kaniko/Jib from phase 25: build and run are separated. Can build images with plain shell commands too, without a Dockerfile.

---

## 5. Rancher Desktop / Podman Desktop

Not runtimes themselves, but desktop GUI tools — replacements for the now-licensed Docker Desktop. Rancher Desktop lets you choose between containerd or Docker, and spins up a local Kubernetes cluster (K3s) with one click. Podman Desktop is Podman's GUI. Both are free.

---

## 📊 Comparison

|               | Docker                       | Podman                              | containerd                       |
| ------------- | ---------------------------- | ----------------------------------- | -------------------------------- |
| Architecture  | Daemon (root)                | Daemonless, rootless                | Minimal runtime                  |
| In Kubernetes | Removed (dockershim)         | Supported but not its main strength | Default runtime, 95% of clusters |
| Strongest at  | Local development, ecosystem | Security-focused environments, RHEL | Production Kubernetes            |

---

## 🤔 Why Docker Is Still Most Used

No alternative "replaces" Docker — each is better in a specific niche:

1. **Ecosystem and habit** — Docker Hub, Docker Compose, a decade of documentation, all built around Docker.
2. **Developer experience** — Docker Desktop still offers the most polished experience.
3. **Doesn't matter day-to-day** — Podman's rootless/daemonless advantage is real but doesn't matter much for most developers; its real importance shows up in environments with high security sensitivity (RHEL, regulated industries).
4. **OCI standard makes migration easy but not required** — since the image format is standard, you can switch whenever you want, which reduces the pressure to switch urgently.

**In short:** Docker = development comfort and ecosystem. Podman = security priority/RHEL. containerd/CRI-O = production Kubernetes. Buildah/Kaniko = build-only in CI/CD. All comply with the OCI standard, so they can partially substitute for each other, but there's no single winner — it's chosen based on the use case.

---

ℹ️ _All tests were performed on a real Ubuntu VPS. See `practice.md` for step-by-step commands and outputs._
