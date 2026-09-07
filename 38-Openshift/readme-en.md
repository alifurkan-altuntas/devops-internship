# ☸️ OpenShift — What It Is, Comparison, Management, Build & Push, OC Client

Phase 37 completed the Security section, and with it **the entire Kubernetes roadmap**. This is the roadmap's **final, supplementary section** — OpenShift isn't a Kubernetes feature, it's a separate, enterprise platform **Red Hat built on top of Kubernetes.**

---

## 1. What Is OpenShift, Comparison

**Software example:** If Kubernetes is a "bare" engine (just the parts), OpenShift is the **full car** — bodywork, seats, A/C already installed, ready to turn the key and drive (PaaS — Platform as a Service).

**Real function:** OpenShift **builds on** Kubernetes and offers, **ready-made and integrated**, some of the tools covered **separately** throughout this internship.

**Cross-reference:** Matched the page's comparison list against tools set up **separately** during this internship:

- _"Provides CI/CD service"_ → **ARGO-CD**, set up separately in Phase 33, comes ready in OpenShift
- _"Built-in container registry"_ → where Docker Hub was used in Phase 33, OpenShift has its **own internal** registry
- _"Embedded DevSecOps layer"_ → **Kyverno/NeuVector**, set up separately in Phase 35, come integrated in OpenShift
- _"Web console"_ → similar to Phase 33's **Dashboard**, but form-based and more comprehensive

**Honest finding — a genuine external obstacle:** Tried to actually test OpenShift by setting up **CodeReady Containers (CRC)** — this required **creating a free Red Hat account and downloading a "pull secret"** from Red Hat's website. A **genuine problem** was encountered during account creation (an external obstacle, not a config/code error), so OpenShift was covered **conceptually rather than with real tests** — a boundary to honestly accept, similar to NeuVector's VPS resource constraint.

---

## 2. Management — Build

**Software example:** Like turning the `docker build` command learned in Phases 19-27 into a process **automatically triggered inside Kubernetes**.

**Real function:** `BuildConfig` is a resource **that doesn't exist at all in plain Kubernetes**, recognized only by OpenShift (`build.openshift.io/v1`) — it converts a Git repo directly into a container image.

**Cross-reference:** The `triggers` field's `GitHub`/`GitLab`/`ImageChange` (auto-rebuild on push or base image update) closely resembles Phase 33's **ARGO-CD webhook-based automation** — the difference being ARGO-CD only automated **deployment**, `BuildConfig` automates the **build stage** too.

**YAML:**

```yaml
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: myapp-build
spec:
  source:
    type: Git
    git:
      uri: https://github.com/edib/oc-example.git
      ref: master
  strategy:
    type: Docker
    dockerStrategy: {}
  output:
    to:
      kind: ImageStreamTag
      name: "merhaba-bash:latest"
  triggers:
    - type: ConfigChange
    - type: ImageChange
```

---

## 3. Build & Push (oc-build)

**Software example:** The `docker push` command, redirected to OpenShift's **own, internal** registry.

**Real function:** `oc whoami -t` returns the current session's token; this token is used with `podman login`/`docker login` to log into **OpenShift's own registry** (`default-route-openshift-image-registry.apps-crc.testing`) — no external registry (Docker Hub, Harbor) needed at all.

**Cross-reference:** The page's mention of the **"Developer Sandbox"** — a **free, web-hosted** trial OpenShift environment from Red Hat — noted as an alternative way to bypass the CRC/pull-secret obstacle, worth **trying in the future** as a backlog item.

**Command:**

```bash
oc login --token=<token> --server=<server-hostname>
oc whoami
podman login -u kubeadmin -p $(oc whoami -t) default-route-openshift-image-registry.apps-crc.testing --tls-verify=false
oc new-project demo
podman push default-route-openshift-image-registry.apps-crc.testing/demo/alpine:latest --tls-verify=false
```

---

## 4. OC Client

**Software example:** OpenShift's own counterpart to `kubectl` — most commands are familiar, but some offer OpenShift-specific shortcuts.

**Real function:** `oc get route` — **`Route`** is OpenShift's **own, built-in** Ingress alternative.

**Cross-reference:** In Phase 31, setting up Ingress required installing a **separate controller** (nginx-ingress) — in OpenShift, `Route` comes ready **with no extra installation needed.** `oc expose deploy` is **one step beyond** Phase 30's `kubectl expose deployment` (creating a Service) — it creates both the Service and an externally-accessible `Route` in a single command.

**Command:**

```bash
oc create deployment myapp --image=quay.io/rhdevelopers/quarkus-demo:v1
oc expose deploy myapp
oc expose service myapp
oc get route
```

---

## 📊 Summary

| Topic                  | What Was Learned                                                                                               |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- |
| What It Is, Comparison | OpenShift = Kubernetes + ready-integrated tools (CI/CD, registry, DevSecOps, web console)                      |
| Management (Build)     | `BuildConfig`, an OpenShift-specific resource that auto-converts a Git repo into an image                      |
| Build & Push           | Logging into the internal registry with an `oc whoami -t` token; Developer Sandbox as an alternative test path |
| OC Client              | `Route`, an install-free OpenShift alternative to Ingress; `oc expose` creates a Service+Route together        |

---

ℹ️ _This topic was covered conceptually rather than with real tests, due to a genuine external obstacle (a problem encountered during Red Hat account creation), with cross-references to tools set up throughout the internship. This is the final document covering the complete roadmap — from Fundamental Concepts to Security, and now this supplementary OpenShift section._
