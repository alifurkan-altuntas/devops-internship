# 🚀 DevOps & Linux Infrastructure Journey - Türkiye Sigorta

Welcome to my DevOps engineering journal. This repository documents my learning path, infrastructure automation practices, error resolutions, and Linux systems administration tasks during my internship.

## 📍 Where I Am Now

I'm currently on **Phase 15 (Cron & Automation)**, completed as of June 22. So far I've gone through Linux basics, permissions, process and service management, log analysis, networking, storage (partitioning, fstab, LVM), SSH/file transfer, proxy concepts, Bash scripting, and cron automation. Each phase has notes, and most have a short quiz I took to check my understanding.

Next up: **Mini Project**.

---

## 📁 Repository Structure

- [01-Linux-Basics](./01-Linux-Basics/): Core Linux commands and text processing (`awk`, `grep`, `cut`), and custom automation scripts.
- [02-Vagrant-Automation](./02-Vagrant-Automation/): Infrastructure as Code (IaC) environments, and multi-distro provisioning.
- [03-File-System-Management](./03-File-System-Management/): Storage diagnostics, disk write operations (`dd`), and sorting pipelines.
- [04-User-Privilege-Management](./04-User-Privilege-Management/): Identity access control, system group lifecycles, and sudoers configuration (Least Privilege Principle).
- [05-Linux-Permissions](./05-Linux-Permissions/): File system access control, recursive ownership changes, and sticky bit isolation.
- [06-Linux-Process-Management](./06-Linux-Process-Management/): Process status monitoring, CPU priority adjustments (`nice`/`renice`), and signals.
- [07-Linux-Service-Management](./07-Linux-Service-Management/): Systemd service management, zero-downtime reloads, and Log Management with journalctl.
- [08-Linux-Log-Analysis](./08-Linux-Log-Analysis/): Log parsing pipelines and IPv4/IPv6 differences across distros.
- [09-Linux-Network-Management](./09-Linux-Network-Management/): DNS lookups, checking listening ports, and TLS certificate verification.
- [10-Linux-Storage-Management](./10-Linux-Storage-Management/): Disk partitioning, formatting with `ext4`, and persistent mounts via `/etc/fstab`.
- [11-Linux-LVM-Management](./11-Linux-LVM-Management/): LVM setup, live volume resizing, and a disk-space incident writeup.
- [12-Linux-SSH-Management](./12-Linux-SSH-Management/): Passwordless SSH access via key pairs, SSH config shortcuts, and file transfers with SCP/SFTP.
- [13-Linux-Proxy-Management](./13-Linux-Proxy-Management/): Forward vs reverse proxy concepts, Nginx's `proxy_pass`, and a real 502 Bad Gateway debugging story.
- [14-Linux-Bash-Scripting](./14-Linux-Bash-Scripting/): Variables, command substitution, numeric conditions, and a disk usage alert script.
- [15-Linux-Cron-Automation](./15-Linux-Cron-Automation/): Scheduling scripts with `cron`, a real `sudo`-in-cron debugging story, and a look at `logrotate`.

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
- [Phase 12 Quiz Logs](./12-Linux-SSH-Management/quiz-results.md): Quiz on SSH keys, SCP, and SFTP.
- [Phase 13 Quiz Logs](./13-Linux-Proxy-Management/quiz-results.md): Quiz on forward/reverse proxy and Nginx routing.
- [Phase 14 Quiz Logs](./14-Linux-Bash-Scripting/quiz-results.md): Quiz on Bash variables, conditions, and scripting basics.
- [Phase 15 Quiz Logs](./15-Linux-Cron-Automation/quiz-results.md): Quiz on cron scheduling, sudoers, and log rotation.

### 🎓 Courses & Certifications

- **DevOps - Linux Temelleri** (Udemy, via Türkiye Sigorta) — Completed June 23, 2026. Taken as an alternative learning path on a day when hands-on VM work wasn't possible on the company laptop.

---

## 📅 Daily Progress Logs

### 🔹 June 17, 2026 | Vagrant Setup & Linux Basics

_Hadn't used Vagrant before — my previous virtualization experience was with VMware directly. Since I didn't have VirtualBox installed (Vagrant's default provider), it kept failing on `vagrant up`. Had to research how to get Vagrant working with VMware as the provider instead._

- **Tasks & Objectives:**
  - Initialized isolated testing laboratory environments using **Vagrant** over the `vmware_desktop` provider to embrace Infrastructure as Code (IaC) workflows.
  - Deployed and configured **Ubuntu** and **Rocky Linux 9.8 (Minimal CLI)** server instances.
  - Explored core Linux commands and analyzed enterprise configuration standards (FQDN defaults on Rocky Linux).
  - Wrote a shell script to monitor live system metrics.
- **Milestones & Deliverables:**
  - 🛠️ Automated Environment Setup: See [Vagrant Logs & Troubleshooting](./02-Vagrant-Automation/)
  - 📜 Linux Basics & Custom Script: See [Linux Basics & Custom Report Script](./01-Linux-Basics/)

### 🔹 June 18, 2026 | File System & Storage Diagnostics

_Wanted to actually see the difference between `dd` and `fallocate` instead of just reading about it — generating a real 10GB file made the sparse vs. physical allocation distinction click._

- **Tasks & Objectives:**
  - Mastered Linux file system directory hierarchies, dynamic permissions, and storage diagnostic navigation (`pwd`, `ls`, `cd`, `mkdir`, `rm`, `cp`, `mv`).
  - Generated a 10 GB test file using low-level block writes.
  - Compared how `dd` and `fallocate` handle disk writes (sparse vs physical allocation).
  - Built a command pipeline with `find`, `du`, and `sort` to list the 10 largest files on the system.
- **Milestones & Deliverables:**
  - 🗂️ File System Operations & Pipelines: See [Storage Diagnostics & Command Matrix](./03-File-System-Management/)

### 🔹 June 18, 2026 | Identity Access Control & Security Hardening (Least Privilege)

_To really understand how the sudoers restriction worked, I didn't just test the allowed command — I deliberately tried commands outside the permission scope to see exactly how and where it would get blocked._

- **Tasks & Objectives:**
  - Studied Linux user and group authentication mechanics (`useradd`, `groupadd`, `id`) and security boundaries within `/etc/passwd` and `/etc/group`.
  - Implemented the **Least Privilege Principle (En Düşük Yetki İlkesi)** to enforce structural operating system hardening.
  - Provisioned a restricted operator account (`devopstester`) configured specifically via `visudo` and the `/etc/sudoers` architecture.
  - Restricted the user to run _only_ `systemctl restart nginx` targeted explicitly at root space (`ALL=(root)`), maintaining credentials verification prompts as an extra security layer while successfully blocking unauthorized operations (e.g., `systemctl stop nginx`).
- **Milestones & Deliverables:**
  - 🔑 Role-Based Access Controls: See [User Administration & Sudoers Constraints](./04-User-Privilege-Management/)

### 🔹 June 19, 2026 | Review & Quiz Results

_Took the 20-question quiz covering everything from the previous phases. Answered based on what I'd actually learned, without changing or correcting answers afterward — this was meant to confirm what had genuinely stuck._

- **Tasks & Objectives:**
  - Consolidated knowledge domains across all completed infrastructural modules through a rigorous testing phase.
  - Worked through scenario-based questions covering file streams, sparse files, and systemd restrictions.
  - Took a 20-question quiz covering IaC, filtering pipelines, and sudoers rules.
  - Documented mistakes and lessons learned (Vagrant provider setup and kernel version flags).
- **Milestones & Deliverables:**
  - 📝 Scenario Solutions: See [Verified Production Scenario Matrices](./challenges.md)
  - 📊 Quiz Results: See [20-Question Quiz Results](./quiz-results.md)

### 🔹 June 19, 2026 | File Permissions & Shared Directory Security

_The permission numbers (like `755` or `777`) didn't make sense to me at first — I couldn't tell what each digit actually represented. After experimenting with different combinations, I understood that each digit maps to a permission level (read/write/execute) for a specific owner type (user/group/others). Once that clicked, I reinforced it by running more tests with different commands._

- **Tasks & Objectives:**
  - Analyzed standard Linux authorization maps (`rwx`), numerical masking conversions (`755` vs `644`), and user layout masks (`umask`).
  - Audited asset distribution commands (`chown` and `chgrp`) to automate recursive file tree ownership migrations.
  - Set up a shared test directory (`/tmp/test`) configured with custom **Sticky Bit** privileges (`+t`).
  - Successfully tested and confirmed that unauthorized users couldn't delete others' files across independent operator profiles, preserving environment integrity.
- **Milestones & Deliverables:**
  - 🔑 Security Hardening Workspace: See [Storage Diagnostics & Permissions Matrix](./05-Linux-Permissions/notes.md)
  - 📊 Validation Diagnostics: See [Phase 5 Assessment Analytics](./05-Linux-Permissions/quiz-results.md)

### 🔹 June 19, 2026 | Linux Process Management

_Noticed `htop` wasn't installed by default and initially thought I'd missed something during setup. After looking into it, I learned this is normal — `htop` is a more advanced tool that has to be installed separately, while `top` comes built in. Practiced each command repeatedly with different flags to make sure it stuck._

- **Tasks & Objectives:**
  - Used `ps` and `pidof` to check running processes and `top` for real-time monitoring.
  - Simulated a runaway process and killed it with `SIGKILL -9`.
  - Compared `top` and `htop`.
  - Practiced CPU priority scheduling with `nice` and `renice`.
- **Milestones & Deliverables:**
  - ⚙️ Process Operations Workspace: See [Process Management Notes](./06-Linux-Process-Management/notes.md)
  - 📊 Performance Evaluation: See [Phase 6 Clean Validation Analytics (100% Score)](./06-Linux-Process-Management/quiz-results.md)

### 🔹 June 19, 2026 | Service Management & Logging

_Found that Rocky Linux doesn't use `apt` — it uses `dnf`/`yum` instead. Looking into why, I learned this comes down to the two distro families being built for different audiences: Debian/Ubuntu (`apt`) leans more toward general/desktop use, while RHEL/Rocky (`dnf`) is built more for enterprise environments. The same pattern showed up with Nginx itself — Ubuntu enables and starts it automatically right after install, while Rocky leaves it disabled by default. Researching why both of these differences exist (and not just memorizing the commands) is what made it stick._

- **Tasks & Objectives:**
  - Installed Nginx on both distros and compared `dnf` vs `apt`.
  - Compared Ubuntu's auto-start default with Rocky Linux's disabled-by-default behavior.
  - Compared `enable` (persists across reboots) vs `start` (runs now).
  - Used `reload` for zero-downtime config changes and `journalctl -u -f` to follow logs live.
- **Milestones & Deliverables:**
  - 🏗️ Service Control Workspace: See [Systemd Daemon Lifecycles & Configurations](./07-Linux-Service-Management/notes.md)
  - 📊 Quiz Results: See [Phase 7 Performance Evaluation (100% Score)](./07-Linux-Service-Management/quiz-results.md)

### 🔹 June 19, 2026 | Linux Log Analysis

_Wasn't expecting Ubuntu to return the IPv6 loopback address (`::1`) for localhost — Rocky Linux returned the familiar `127.0.0.1` (IPv4) instead. Looking into it, I learned Ubuntu defaults to IPv6 because it's geared more toward general/home use where modern networking stacks are expected, while Rocky sticks with IPv4 since it's more widely supported and stable in enterprise environments. The commands themselves weren't easy to get used to at first, but they clicked after running through them a few times._

- **Tasks & Objectives:**
  - Learned the Nginx log format and which columns map to IP, path, and status code.
  - Compared IPv6 loopback (`::1`) on Ubuntu vs IPv4 (`127.0.0.1`) on Rocky Linux.
  - Fixed missing `curl` on Ubuntu's minimal image by installing it manually.
  - Built `grep`/`awk`/`sort`/`uniq` pipelines to find top IPs and count 404 errors by path.
- **Milestones & Deliverables:**
  - 🪵 Text Process Workspace: See [Log Analytics & Command Processing Templates](./08-Linux-Log-Analysis/notes.md)
  - 📊 Quiz Results: See [Phase 8 Performance Evaluation (100% Score)](./08-Linux-Log-Analysis/quiz-results.md)

### 🔹 June 21, 2026 | Networking & TLS

_First time inspecting a TLS certificate directly — at first I didn't fully understand what I was looking at. After digging deeper, I understood that the certificate itself has a validity window (issue and expiration dates), and separately, TLS also uses session resumption so that repeated connections don't have to redo the full handshake and certificate check every time — which is what speeds up subsequent connections to the same server._

- **Tasks & Objectives:**
  - Used `dig @8.8.8.8` to bypass local DNS caching and verify resolution.
  - Used `ss -lntp` to find which process was listening on a port, across both IPv4 and IPv6.
  - Used `openssl s_client` to inspect a certificate's trust chain, issuer, and expiration date.
- **Milestones & Deliverables:**
  - 🌐 Networking Workspace: See [Network & TLS Notes](./09-Linux-Network-Management/notes.md)
  - 📊 Quiz Results: See [Phase 9 Quiz Results](./09-Linux-Network-Management/quiz-results.md)

### 🔹 June 22, 2026 | Storage & LVM

_This phase included a real mistake: I filled the host machine's disk while testing with `dd` and froze the VM completely. Recovering from that — and switching to `fallocate` — taught me more than the planned exercise would have on its own._

- **Tasks & Objectives:**
  - Set up persistent mounts using UUID in `/etc/fstab`, and verified the entry with `mount -a` before rebooting.
  - Set up LVM: physical volumes → volume group → logical volume.
  - Recovered from a VM freeze caused by filling the host disk with `dd`, and switched to `fallocate` to avoid it.
  - Resized a logical volume and its filesystem live, without unmounting.
- **Milestones & Deliverables:**
  - 💾 Storage Workspace: See [Storage Management Notes](./10-Linux-Storage-Management/notes.md)
  - 🏗️ LVM Workspace: See [LVM Management Notes](./11-Linux-LVM-Management/notes.md)
  - 📊 Quiz Results: See [Phase 10 Quiz Results](./10-Linux-Storage-Management/quiz-results.md) / [Phase 11 Quiz Results](./11-Linux-LVM-Management/quiz-results.md)

### 🔹 June 22, 2026 | SSH, SCP & SFTP

_Didn't have `ssh-copy-id` available on Windows, so I had to do the same thing manually — paste the public key into `authorized_keys` myself and set the permissions by hand. That made it much clearer what the command actually does instead of just running it. Also ran into a real "Permission denied (publickey)" error after disabling password login, which turned out to be because I had a separate key for the Ubuntu VM and SSH was trying the wrong one by default — had to use `-i` to point to the right key file, and later set up an SSH config file so I wouldn't have to type it out every time. Along the way I also hit a leftover commented-out line in `sshd_config` that silently did nothing until I removed the `#`._

- **Tasks & Objectives:**
  - Generated an SSH key pair (`ssh-keygen -t ed25519`) and manually added the public key to a VM's `authorized_keys` (no `ssh-copy-id` on Windows).
  - Set correct permissions (`chmod 700`/`600`) on `.ssh` and `authorized_keys`, and learned why SSH enforces this.
  - Disabled password authentication (`PasswordAuthentication no`) and verified the restriction by testing both with and without the key in place.
  - Debugged a `Permission denied (publickey)` error caused by using the wrong key file, and fixed it with `-i` and an SSH config file.
  - Transferred files between host and VM using `scp` and `sftp`.
- **Milestones & Deliverables:**
  - 🔐 SSH Workspace: See [SSH, SCP & SFTP Notes](./12-Linux-SSH-Management/notes.md)
  - 📊 Quiz Results: See [Phase 12 Quiz Results](./12-Linux-SSH-Management/quiz-results.md)

### 🔹 June 22, 2026 | Forward & Reverse Proxy

_This phase was mostly conceptual rather than fully hands-on. I understood forward proxy as a courier carrying a request on your behalf — the other side only sees the courier, not you — and reverse proxy as a front desk person at a company: you ask for someone, they send you to the right place, and you never deal with the rest of the building directly. Tried setting up an actual Nginx reverse proxy pointing to a backend service, but hit a 502 Bad Gateway. Turned out the backend and Nginx were on different VMs, and I had `proxy_pass` pointing to `localhost` — which only ever refers to the machine Nginx itself is running on, not the other VM where the backend actually was. Didn't finish the working setup in this session, but understanding exactly why it failed was the real takeaway._

- **Tasks & Objectives:**
  - Learned the difference between forward proxy (sits in front of the client) and reverse proxy (sits in front of the server).
  - Set up a basic backend service and an Nginx reverse proxy using `proxy_pass`.
  - Hit and diagnosed a real `502 Bad Gateway` caused by `proxy_pass` pointing to `localhost` instead of the backend VM's actual IP.
  - Learned what a 502 error specifically means (proxy couldn't reach the backend) vs. other error codes.
- **Milestones & Deliverables:**
  - 🔀 Proxy Workspace: See [Forward & Reverse Proxy Notes](./13-Linux-Proxy-Management/notes.md)
  - 📊 Quiz Results: See [Phase 13 Quiz Results](./13-Linux-Proxy-Management/quiz-results.md)

### 🔹 June 22, 2026 | Bash Scripting

_Built a script that warns when disk usage goes over 80%, piecing it together from commands I already knew — `df`, `awk 'NR==2'` to grab the right line, and `cut -d'%' -f1` to strip the percent sign, then storing the result in a variable with command substitution. Hit a real error along the way: `[48: command not found`, caused by missing a space between `[` and `$usage` — Bash's `[` is actually a command, so it needs spacing on both sides to work. Fixed it, then added an `else` branch so the script always prints something instead of staying silent when usage is fine. Didn't add a loop or a function, since the task only needed a single check — felt more honest to leave them out than to force them in just to "use" every topic in the list._

- **Tasks & Objectives:**
  - Wrote a script combining `df`, `awk`, and `cut` to extract disk usage as a plain number.
  - Stored the result in a variable using command substitution (`$(...)`).
  - Used an `if`/`else` block with `-gt` to print a warning above 80% usage, and an "OK" message otherwise.
  - Debugged a real `[48: command not found` error caused by a missing space in the condition syntax.
  - Made the script executable with `chmod +x` and ran it directly with `./script.sh`.
- **Milestones & Deliverables:**
  - 🐚 Bash Scripting Workspace: See [Bash Scripting Notes](./14-Linux-Bash-Scripting/notes.md)
  - 📊 Quiz Results: See [Phase 14 Quiz Results](./14-Linux-Bash-Scripting/quiz-results.md)

### 🔹 June 22, 2026 | Cron & Automation

_Wrote two scripts — one for disk usage reports, one for archiving Nginx logs — and scheduled both with cron. The disk report script worked immediately, but the log archiving script kept "succeeding" without actually doing anything when run through cron, even though it worked fine manually. Took a while to track down: `sudo` needs an interactive terminal to ask for a password, and cron runs with nobody there to answer it, so every `sudo` command inside the script was silently failing. The failure was invisible at first because cron tries to email its output by default, and with no mail system installed, that output — including the actual error — was just getting discarded. Found the real error by redirecting the script's output to a file manually. Also hit a separate issue where the script itself was owned by `root` (from opening it with `sudo nano` at some point), which blocked even `chmod` until I fixed the ownership with `chown`. Solved the `sudo` problem with a narrow `sudoers` rule for just the one command that actually needed root, instead of giving broader access. Along the way also looked into `logrotate`, which is what Nginx actually uses by default for this exact job in real setups._

- **Tasks & Objectives:**
  - Wrote `disk_report.sh` (reused logic from the Bash Scripting phase) to write a disk usage report to a file.
  - Wrote `archive_logs.sh` to compress Nginx's `access.log` with `gzip -c` and reset it with `truncate -s 0`.
  - Diagnosed a `sudo: a password is required` failure that only showed up under cron, not manual runs.
  - Fixed a file ownership issue (`chown`) and added a narrowly scoped `sudoers` NOPASSWD rule for the one command that needed it.
  - Scheduled both scripts with `crontab -e` to run nightly at 02:00.
  - Looked into `logrotate` as the standard real-world tool for this kind of log management.
- **Milestones & Deliverables:**
  - ⏰ Cron & Automation Workspace: See [Cron & Automation Notes](./15-Linux-Cron-Automation/notes.md)
  - 📊 Quiz Results: See [Phase 15 Quiz Results](./15-Linux-Cron-Automation/quiz-results.md)

### 🔹 June 23, 2026 | DevOps - Linux Temelleri (Udemy Course)

_Couldn't do hands-on work today since the company laptop doesn't allow running VMs or the tools I'd normally use. Used the day to complete a DevOps - Linux Temelleri course on Udemy instead, to keep making progress even without direct lab access._

- **Tasks & Objectives:**
  - Completed the "DevOps - Linux Temelleri" course on Udemy Business.
- **Milestones & Deliverables:**
  - 🎓 Course Completion: DevOps - Linux Temelleri (Udemy)

---

ℹ️ _Note: Everything documented here was tested locally in sandboxed VMs._
