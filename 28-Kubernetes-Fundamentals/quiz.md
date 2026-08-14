# 📊 Kubernetes Fundamentals Quiz Results

**Score: 15/15 (100%)**

---

**1. In GitOps, what is the basic method for making changes to a cluster?**
A) Running `kubectl` commands directly by hand
B) Changing the YAML definition in a Git repo, and having a tool (like ArgoCD) apply it automatically
C) Only making changes through a web interface
D) A cluster can never be changed

**My answer: B** ✅ — it also enables traceability, since it's a YAML file being changed, who did what and when can be tracked, like commits on GitHub

---

**2. What year does the idea of containers date back to?**
A) 2008 (LXC)
B) 2013 (Docker)
C) 1979 (chroot)
D) 2000 (FreeBSD Jails)

**My answer: C** ✅ — the first idea appeared in 1979 and developed over time into a better form

---

**3. What does Kubernetes' "self-healing" feature rely on to work?**
A) Restarting all pods at random times
B) Detecting containers that don't respond to health checks and intervening accordingly
C) Only manual commands from the user
D) It doesn't rely on any check, it isn't automatic

**My answer: B** ✅ — a health check detects the container's status and intervention can be taken based on that status

---

**4. What is the purpose of the `envsubst` technique in a Dockerfile?**
A) To compress the image
B) To fill `${VARIABLE}` placeholders in a config file with the real values defined via `ENV`
C) To automatically restart the container
D) To reset network settings

**My answer: B** ✅

---

**5. What is the fundamental difference between the control plane and the data plane?**
A) They're the same thing, no difference
B) The data plane carries the actual service traffic, the control plane serves/manages that plane
C) The control plane only does logging
D) The data plane is only used in test environments

**My answer: B** ✅

---

**6. What is the core responsibility of kube-apiserver?**
A) Running pods directly
B) Accepting and validating all REST requests coming into the cluster, being the single connection point to etcd
C) Only routing network traffic
D) Performing DNS resolution

**My answer: B** ✅ — the name itself gives it away, apiserver's purpose is to control incoming/outgoing requests

---

**7. When a value in etcd is "updated," what actually happens?**
A) The old value is deleted and overwritten with the new one
B) The old value is preserved, a new version is added instead (immutable)
C) The value can never be changed
D) The value is only kept temporarily in memory, never written to disk

**My answer: B** ✅ — there's a law against deletion, the old value isn't deleted

---

**8. Why does etcd run as a cluster with an odd number of members?**
A) Even numbers aren't technically supported
B) An odd number eliminates the possibility of a tied vote
C) To reduce cost
D) Odd numbers run faster

**My answer: B** ✅ — even numbers have the weakness of splitting evenly and tying; since odd numbers can't split evenly like that, the possibility of a tie disappears

---

**9. What does kube-scheduler NOT consider when placing a pod on a node?**
A) Resource requirements
B) Node affinity/antiaffinity
C) Taints and tolerations
D) The programming language of the app inside the pod

**My answer: D** ✅ — the language doesn't matter, it checks whether what's needed for it to run is available; pods are like containers

---

**10. What is the first thing kubelet does?**
A) Run a container directly
B) Register the node it's on with the API Server as a Node resource
C) Start etcd
D) Set up a DNS server

**My answer: B** ✅

---

**11. What is coredns's job?**
A) Building containers
B) Providing in-cluster DNS resolution
C) Checking resource limits
D) Collecting logs

**My answer: B** ✅ — like the hosts file on computers

---

**12. What does kube-proxy provide?**
A) The image build process
B) Reachability of Services/Endpoints, node network rules, and virtual IP assignment
C) Only firewall rules
D) A pod's CPU limit

**My answer: B** ✅

---

**13. What is the job of the CNI (Container Network Interface) layer (e.g. Calico)?**
A) Storing images
B) Providing the cluster's network infrastructure (connectivity between pods)
C) Only doing DNS resolution
D) Handling user authentication

**My answer: B** ✅

---

**14. What happens when `kubectl delete namespace mystuff` is run?**
A) Only the namespace's name is deleted, contents remain
B) Everything inside the namespace (deployment, pod, service) is automatically deleted
C) Nothing is deleted, it just shows a warning
D) Only pods are deleted, deployments remain

**My answer: B** ✅ — namespaces are like folders, deleting one takes everything inside it with it

---

**15. The command `kubectl set image deployment/myapp app=image:v2` is directly related to which roadmap concept?**
A) Resource Limits
B) Continuous Updates (rolling update)
C) Secrets management
D) CNI configuration

**My answer: B** ✅ — reasoned it out just from seeing "v2" in the command

---

ℹ️ _All answers given without revisiting or correcting after submission._
