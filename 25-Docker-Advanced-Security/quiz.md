# 📊 Docker Deep Dive Quiz Results

**Score: 15/15 (100%)**

---

**1. What is the core purpose of multi-stage build?**
A) To slow down the build process
B) To keep tools needed at build time but not at runtime out of the final image
C) Just to use more than one Dockerfile
D) To automatically push the image to Docker Hub

**My answer: B** ✅

---

**2. Why does the order of commands in a Dockerfile matter for layer caching?**
A) It doesn't matter, order makes no difference
B) Frequently-changing steps should go first, rarely-changing ones last
C) Rarely-changing steps should go first, frequently-changing ones last
D) Only the order of `RUN` matters, `COPY` doesn't

**My answer: C** ✅

---

**3. Why doesn't data disappear when a Docker Compose container is deleted and recreated?**
A) Docker automatically backs up data
B) Data is kept in a volume, independent of the container
C) Data is baked into the image
D) Network configuration stores the data

**My answer: B** ✅

---

**4. How do two services on the same network reach each other in Docker Compose?**
A) Only by IP address
B) By service name — thanks to Docker's own DNS resolution
C) Only via `localhost`
D) They can't, a separate network is required

**My answer: B** ✅

---

**5. What concrete security benefit does a non-root container provide?**
A) It runs the container faster
B) It prevents an attacker from gaining root on the host in a container escape scenario
C) It shrinks the image size
D) No real difference, it's cosmetic only

**My answer: B** ✅

---

**6. What is the purpose of the `.dockerignore` file?**
A) To speed up the image's runtime
B) To prevent certain files (e.g. `.env`) from entering the build context and the image
C) To automatically restart the container
D) To block pushing to Docker Hub

**My answer: B** ✅

---

**7. What problem does Kaniko actually solve?**
A) Shrinking image size
B) Building images in a CI/CD environment without needing the Docker daemon or root privileges
C) Making multi-stage builds easier
D) Setting up networking between containers

**My answer: B** ✅

---

**8. What's the key difference between Jib and Kaniko?**
A) Jib works in any language, Kaniko only in Java
B) Jib only works for Java and needs no Dockerfile at all
C) They do the same thing, no difference
D) Jib only works on Windows

**My answer: B** ✅

---

**9. What does BuildKit's secret mount feature provide?**
A) It automatically encrypts the image
B) It keeps sensitive data used during the build out of the image history
C) It runs the container as root
D) It encrypts network traffic

**My answer: B** ✅

---

**10. Why can't a Windows Server Core image run on a Linux VPS (e.g. Ubuntu)?**
A) Docker doesn't support Windows images
B) Windows images are too large
C) A container shares the host's kernel, and a Linux kernel can't run a Windows container
D) It's a licensing issue

**My answer: C** ✅

---

**11. What does "Docker runs everywhere" actually mean?**
A) It runs on any operating system/kernel
B) It runs consistently within the same kernel family (e.g. across different Linux distros)
C) It only runs in cloud environments
D) It only runs on x86 architecture

**My answer: B** ✅

---

**12. Why can Docker Desktop run Linux containers on Mac/Windows?**
A) The Mac/Windows kernel is compatible with Linux
B) It quietly runs a hidden Linux virtual machine in the background
C) Containers don't actually run, they're simulated
D) Apple and Microsoft have licensed the Linux kernel

**My answer: B** ✅

---

**13. What was the concrete benefit of using `python:3.11-slim` multi-stage instead of `python:3.11` (1.62GB)?**
A) Just a visual difference, no practical benefit
B) Image size shrank by ~8.5x (down to 191MB)
C) It only affected build speed, not size
D) It increased the number of vulnerabilities

**My answer: B** ✅

---

**14. What does using `FROM php:8.2-apache` mean in the PHP example?**
A) It only includes the PHP CLI tool, no web server
B) It comes with both PHP and the Apache web server ready to go
C) It only provides a database connection
D) It works together with Node.js

**My answer: B** ✅ (hesitated — went back and forth between A and B, settled on B)

---

**15. Does `docker compose down` also delete volumes in Docker Compose?**
A) Yes, always
B) No, volumes stay by default (the `-v` flag is needed to delete them)
C) It only deletes networks, not containers
D) It only deletes images

**My answer: B** ✅

---

ℹ️ _All answers given without revisiting or correcting after submission._
