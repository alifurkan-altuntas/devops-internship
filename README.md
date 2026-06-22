# 🚀 DevOps & Linux Infrastructure Journey - Türkiye Sigorta

Welcome to my DevOps engineering journal. This repository is dedicated to documenting my structured learning path, infrastructure automation practices, error resolutions, and Linux systems administration tasks during my internship.

## 📁 Repository Structure

- [01-Linux-Basics](./01-Linux-Basics/): Core Linux commands and text processing (`awk`, `grep`, `cut`), and custom automation scripts.
- [02-Vagrant-Automation](./02-Vagrant-Automation/): Infrastructure as Code (IaC) environments, and multi-distro provisioning.
- [03-File-System-Management](./03-File-System-Management/): Storage diagnostics, disk write operations (`dd`), and sorting pipelines.
- [04-User-Privilege-Management](./04-User-Privilege-Management/): Identity access control, system group lifecycles, and sudoers configuration (Least Privilege Principle).
- [05-Linux-Permissions](./05-Linux-Permissions/): File system access control, recursive ownership changes, and sticky bit isolation.
- [06-Linux-Process-Management](./06-Linux-Process-Management/): Process status monitoring, CPU priority adjustments (`nice`/`renice`), and signals.
- [07-Linux-Service-Management](./07-Linux-Service-Management/): Systemd service management, zero-downtime reloads, and Log Management with journalctl.
- [08-Linux-Log-Analysis](./08-Linux-Log-Analysis/): Log parsing pipelines and IPv4/IPv6 differences across distros.
- [09-Linux-Network-Management](./09-Linux-Network-Management/): DNS lookups, checking listening ports, and TLS certificate verification..
- [10-Linux-Storage-Management](./10-Linux-Storage-Management/): Disk partitioning, formatting with `ext4`, and persistent mounts via `/etc/fstab`.
- [11-Linux-LVM-Management](./11-Linux-LVM-Management/): LVM setup, live volume resizing, and a disk-space incident writeup.

### 📝 Evaluation & Assessment Artifacts

- [challenges.md](./challenges.md): Scenario questions and answers (Phases 1-4).
- [quiz-results.md](./quiz-results.md): 20-question quiz, 85% score (Phases 1-4).
- [Phase 5 Quiz Logs](./05-Linux-Permissions/quiz-results.md): 5-question quiz on umask and sticky bit.
- [Phase 6 Quiz Logs](./06-Linux-Process-Management/quiz-results.md): Quiz on process monitoring and signals.
- [Phase 7 Quiz Logs](./07-Linux-Service-Management/quiz-results.md): Quiz on systemd and journalctl.
- [Phase 8 Quiz Logs](./08-Linux-Log-Analysis/quiz-results.md): Quiz on log parsing.
- [Phase 9 Quiz Logs](./09-Linux-Network-Management/quiz-results.md): Quiz on networking and TLS.
- [Phase 10 Quiz Logs](./10-Linux-Storage-Management/quiz-results.md): Quiz on storage and fstab.
- [Phase 11 Quiz Logs](./11-Linux-LVM-Management/quiz-results.md): Quiz on LVM.

---

## 📅 Daily Progress Logs

### 🔹 June 17, 2026 | Vagrant Setup & Linux Basics

- **Tasks & Objectives:**
  - Initialized isolated testing laboratory environments using **Vagrant** over the `vmware_desktop` provider to embrace Infrastructure as Code (IaC) workflows.
  - Deployed and configured **Ubuntu** and **Rocky Linux 9.8 (Minimal CLI)** server instances.
  - Explored core Linux commands and analyzed enterprise configuration standards (FQDN defaults on Rocky Linux).
  - Wrote a shell script to monitor live system metrics.
- **Milestones & Deliverables:**
  - 🛠️ Automated Environment Setup: See [Vagrant Logs & Troubleshooting](./02-Vagrant-Automation/)
  - 📜 Linux Basics & Custom Script: See [Linux Basics & Custom Report Script](./01-Linux-Basics/)

### 🔹 June 18, 2026 | File System & Storage Diagnostics

- **Tasks & Objectives:**
  - Mastered Linux file system directory hierarchies, dynamic permissions, and storage diagnostic navigation (`pwd`, `ls`, `cd`, `mkdir`, `rm`, `cp`, `mv`).
  - Generated a 10 GB test file using low-level block writes.
  - Compared how `dd` and `fallocate` handle disk writes (sparse vs physical allocation).
  - Built a command pipeline with `find`, `du`, and `sort` to list the 10 largest files on the system.
- **Milestones & Deliverables:**
  - 🗂️ File System Operations & Pipelines: See [Storage Diagnostics & Command Matrix](./03-File-System-Management/)

### 🔹 June 18, 2026 | Identity Access Control & Security Hardening (Least Privilege)

- **Tasks & Objectives:**
  - Studied Linux user and group authentication mechanics (`useradd`, `groupadd`, `id`) and security boundaries within `/etc/passwd` and `/etc/group`.
  - Implemented the **Least Privilege Principle (En Düşük Yetki İlkesi)** to enforce structural operating system hardening.
  - Provisioned a restricted operator account (`devopstester`) configured specifically via `visudo` and the `/etc/sudoers` architecture.
  - Restricted the user to run _only_ `systemctl restart nginx` targeted explicitly at root space (`ALL=(root)`), maintaining credentials verification prompts as an extra security layer while successfully blocking unauthorized operations (e.g., `systemctl stop nginx`).
- **Milestones & Deliverables:**
  - 🔑 Role-Based Access Controls: See [User Administration & Sudoers Constraints](./04-User-Privilege-Management/)

### 🔹 June 19, 2026 | Review & Quiz Results

- **Tasks & Objectives:**
  - Consolidated knowledge domains across all completed infrastructural modules through a rigorous testing phase.
  - Worked through scenario-based questions covering file streams, sparse files, and systemd restrictions.
  - Took a 20-question quiz covering IaC, filtering pipelines, and sudoers rules.
  - Documented mistakes and lessons learned (Vagrant provider setup and kernel version flags).
- **Milestones & Deliverables:**
  - 📝 Scenario Solutions: See [Verified Production Scenario Matrices](./challenges.md)
  - 📊 Quiz Results: See [20-Question Quiz Results](./quiz-results.md)

### 🔹 June 19, 2026 | File Permissions & Shared Directory Security

- **Tasks & Objectives:**
  - Analyzed standard Linux authorization maps (`rwx`), numerical masking conversions (`755` vs `644`), and user layout masks (`umask`).
  - Audited asset distribution commands (`chown` and `chgrp`) to automate recursive file tree ownership migrations.
  - Set up a shared test directory (`/tmp/test`) configured with custom **Sticky Bit** privileges (`+t`).
  - Successfully tested and confirmed that unauthorized users couldn't delete others' files across independent operator profiles, preserving environment integrity.
- **Milestones & Deliverables:**
  - 🔑 Security Hardening Workspace: See [Storage Diagnostics & Permissions Matrix](./05-Linux-Permissions/notes.md)
  - 📊 Validation Diagnostics: See [Phase 5 Assessment Analytics](./05-Linux-Permissions/quiz-results.md)

### 🔹 June 19, 2026 | Linux Process Management

- **Tasks & Objectives:**
  - Used `ps` and `pidof` to check running processes and `top` for real-time monitoring.
  - Simulated a runaway process and killed it with `SIGKILL -9`.
  - Compared `top` and `htop`.
  - Practiced CPU priority scheduling with `nice` and `renice`.
- **Milestones & Deliverables:**
  - ⚙️ Process Operations Workspace: See [Process Management Notes](./06-Linux-Process-Management/notes.md)
  - 📊 Performance Evaluation: See [Phase 6 Clean Validation Analytics (100% Score)](./06-Linux-Process-Management/quiz-results.md)

### 🔹 June 19, 2026 | Service Management & Logging

- **Tasks & Objectives:**
  - Installed Nginx on both distros and compared `dnf` vs `apt`.
  - Compared Ubuntu's auto-start default with Rocky Linux's disabled-by-default behavior.
  - Compared `enable` (persists across reboots) vs `start` (runs now).
  - Used `reload` for zero-downtime config changes and `journalctl -u -f` to follow logs live.
- **Milestones & Deliverables:**
  - 🏗️ Service Control Workspace: See [Systemd Daemon Lifecycles & Configurations](./07-Linux-Service-Management/notes.md)
  - 📊 Quiz Results: See [Phase 7 Performance Evaluation (100% Score)](./07-Linux-Service-Management/quiz-results.md)

  ### 🔹 June 19, 2026 | Linux Log Analysis

- **Tasks & Objectives:**
  - Learned the Nginx log format and which columns map to IP, path, and status code.
  - Compared IPv6 loopback (`::1`) on Ubuntu vs IPv4 (`127.0.0.1`) on Rocky Linux.
  - Fixed missing `curl` on Ubuntu's minimal image by installing it manually.
  - Built `grep`/`awk`/`sort`/`uniq` pipelines to find top IPs and count 404 errors by path.
- **Milestones & Deliverables:**
  - 🪵 Text Process Workspace: See [Log Analytics & Command Processing Templates](./08-Linux-Log-Analysis/notes.md)
  - 📊 Quiz Results: See [Phase 8 Performance Evaluation (100% Score)](./08-Linux-Log-Analysis/quiz-results.md)

  ### 🔹 June 21, 2026 | Networking & TLS

- **Tasks & Objectives:**
  - Used `dig @8.8.8.8` to bypass local DNS caching and verify resolution.
  - Used `ss -lntp` to find which process was listening on a port, across both IPv4 and IPv6.
  - Used `openssl s_client` to inspect a certificate's trust chain, issuer, and expiration date.

### 🔹 June 22, 2026 | Storage & LVM

- **Tasks & Objectives:**
  - Set up persistent mounts using UUID in `/etc/fstab`, and verified the entry with `mount -a` before rebooting.
  - Set up LVM: physical volumes → volume group → logical volume.
  - Recovered from a VM freeze caused by filling the host disk with `dd`, and switched to `fallocate` to avoid it.
  - Resized a logical volume and its filesystem live, without unmounting.

---

ℹ️ _Note: Everything documented here was tested locally in sandboxed VMs._
