# 🚀 DevOps & Linux Infrastructure Journey - Türkiye Sigorta

🌐 [Türkçe oku](./README.md)

Welcome to my DevOps engineering journal. This repository documents my learning path, infrastructure automation practices, error resolutions, and Linux systems administration tasks during my internship.

## 📍 Where I Am Now

Completed all 17 phases of the Linux roadmap, including the mini project — Nginx, Docker, Git, and SSH are set up on a real rented server, serving a page pulled directly from this repo.

Beyond the roadmap, worked through additional topics assigned by my mentor: `sed`, `at`, path-based IP grouping, OSI model, routing & forwarding, and DNS in depth (resolver chain, 8 record types, TTL, negative caching, debug tools, real cloud outage research) — scored 15/15 on all three quizzes.

Completed Nginx deep dive: reverse proxy, path-based routing, path rewrite, path blocking, and forward proxy (Squid). Ran 20 test scenarios against the real config — discovered and documented an IPv6/IPv4 mismatch during testing. Also added rate limiting and load balancing on my own initiative (round-robin, failover, `least_conn`, `ip_hash`).

Bilingual documentation (TR/EN) complete for all phases (01–20).

Completed new task: OpenResty (PostgreSQL, MySQL, Redis, token authentication) and rclone with S3 (performance parameters, `rclone serve http`).

---

## 📁 Repository Structure

- [01-Linux-Basics](./01-Linux-Basics/): Core Linux commands and text processing (`awk`, `grep`, `cut`), and custom automation scripts. ([EN](./01-Linux-Basics/readme-en.md) / [TR](./01-Linux-Basics/readme.md))
- [02-Vagrant-Automation](./02-Vagrant-Automation/): Infrastructure as Code (IaC) environments, and multi-distro provisioning. ([EN](./02-Vagrant-Automation/readme-en.md) / [TR](./02-Vagrant-Automation/readme.md))
- [03-File-System-Management](./03-File-System-Management/): Storage diagnostics, disk write operations (`dd`), and sorting pipelines. ([EN](./03-File-System-Management/readme-en.md) / [TR](./03-File-System-Management/readme.md))
- [04-User-Privilege-Management](./04-User-Privilege-Management/): Identity access control, system group lifecycles, and sudoers configuration (Least Privilege Principle). ([EN](./04-User-Privilege-Management/readme-en.md) / [TR](./04-User-Privilege-Management/readme.md))
- [05-Linux-Permissions](./05-Linux-Permissions/): File system access control, recursive ownership changes, and sticky bit isolation. ([EN](./05-Linux-Permissions/readme-en.md) / [TR](./05-Linux-Permissions/readme.md))
- [06-Linux-Process-Management](./06-Linux-Process-Management/): Process status monitoring, CPU priority adjustments (`nice`/`renice`), and signals. ([EN](./06-Linux-Process-Management/readme-en.md) / [TR](./06-Linux-Process-Management/readme.md))
- [07-Linux-Service-Management](./07-Linux-Service-Management/): Systemd service management, zero-downtime reloads, and Log Management with journalctl. ([EN](./07-Linux-Service-Management/readme-en.md) / [TR](./07-Linux-Service-Management/readme.md))
- [08-Linux-Log-Analysis](./08-Linux-Log-Analysis/): Log parsing pipelines, `sed`, and IPv4/IPv6 differences across distros. ([EN](./08-Linux-Log-Analysis/readme-en.md) / [TR](./08-Linux-Log-Analysis/readme.md))
- [09-Linux-Network-Management](./09-Linux-Network-Management/): DNS lookups, checking listening ports, and TLS certificate verification. ([EN](./09-Linux-Network-Management/readme-en.md) / [TR](./09-Linux-Network-Management/readme.md))
- [10-Linux-Storage-Management](./10-Linux-Storage-Management/): Disk partitioning, formatting with `ext4`, and persistent mounts via `/etc/fstab`. ([EN](./10-Linux-Storage-Management/readme-en.md) / [TR](./10-Linux-Storage-Management/readme.md))
- [11-Linux-LVM-Management](./11-Linux-LVM-Management/): LVM setup, live volume resizing, and a disk-space incident writeup. ([EN](./11-Linux-LVM-Management/readme-en.md) / [TR](./11-Linux-LVM-Management/readme.md))
- [12-Linux-SSH-Management](./12-Linux-SSH-Management/): Passwordless SSH access via key pairs, SSH config shortcuts, and file transfers with SCP/SFTP. ([EN](./12-Linux-SSH-Management/readme-en.md) / [TR](./12-Linux-SSH-Management/readme.md))
- [13-Linux-Proxy-Management](./13-Linux-Proxy-Management/): Forward vs reverse proxy concepts, Nginx's `proxy_pass`, and a real 502 Bad Gateway debugging story. ([EN](./13-Linux-Proxy-Management/readme-en.md) / [TR](./13-Linux-Proxy-Management/readme.md))
- [14-Linux-Bash-Scripting](./14-Linux-Bash-Scripting/): Variables, command substitution, numeric conditions, and a disk usage alert script. ([EN](./14-Linux-Bash-Scripting/readme-en.md) / [TR](./14-Linux-Bash-Scripting/readme.md))
- [15-Linux-Cron-Automation](./15-Linux-Cron-Automation/): Scheduling with `cron` and `at`, a real `sudo`-in-cron debugging story, and a look at `logrotate`. ([EN](./15-Linux-Cron-Automation/readme-en.md) / [TR](./15-Linux-Cron-Automation/readme.md))
- [16-Git-Basics](./16-Git-Basics/): `git clone`, branching, merging, and a real push-rejected/editor-stuck conflict resolved on this exact repo. ([EN](./16-Git-Basics/readme-en.md) / [TR](./16-Git-Basics/readme.md))
- [17-Mini-Project](./17-Mini-Project/): Nginx, Docker, Git, and SSH set up on a real rented server — a static page pulled from this repo and published live. ([EN](./17-Mini-Project/readme-en.md) / [TR](./17-Mini-Project/readme.md))
- [18-Linux-Networking-Fundamentals](./18-Linux-Networking-Fundamentals/): OSI model, routing & forwarding, and DNS (resolver chain, record types, TTL) — verified hands-on with `tcpdump` and `dig +trace`. Also includes research into real outages from AWS/Cloudflare/Google Cloud. ([EN](./18-Linux-Networking-Fundamentals/readme-en.md) / [TR](./18-Linux-Networking-Fundamentals/readme.md) — Outage research: [EN](./18-Linux-Networking-Fundamentals/dns-outages-EN.md) / [TR](./18-Linux-Networking-Fundamentals/dns-outages-TR.md))
- [19-Nginx-Derinleşme](./19-Nginx-Derinleşme/): Reverse proxy, path-based routing, path rewrite, path blocking, and forward proxy (Squid) — all tested hands-on on a real server. ([EN](./19-Nginx-Derinleşme/readme-en.md) / [TR](./19-Nginx-Derinleşme/readme.md))
- [20-Rate-Limiting-Load-Balancing](./20-Rate-Limiting-Load-Balancing/): Nginx rate limiting (`limit_req_zone`, `burst`, `nodelay`) and load balancing (round-robin, failover, `least_conn`, `ip_hash`). ([TR](./20-Rate-Limiting-Load-Balancing/README.md) / [EN](./20-Rate-Limiting-Load-Balancing/README-EN.md))
- [21-OpenResty-API](./21-OpenResty-API/): Token authentication with OpenResty, PostgreSQL, MySQL, and Redis integration — deployed with Docker Compose. ([TR](./21-OpenResty-API/README.md) / [EN](./21-OpenResty-API/README-EN.md))
- [22-rclone-S3](./22-rclone-S3/): Connecting to Amazon S3 with rclone, testing performance parameters, and exposing a private bucket over HTTP with `rclone serve http`. ([TR](./22-rclone-S3/README.md) / [EN](./22-rclone-S3/README-EN.md))

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
- [Phase 16 Quiz Logs](./16-Git-Basics/quiz-results.md): Quiz on Git branching, merging, and resolving a push conflict.
- [Phase 19 & 20 Quiz Results](./19-Nginx-Derinlestirme/quiz-results.md): Nginx reverse proxy, path management, forward proxy, rate limiting and load balancing — 15/15.

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
  - 🛠️ Automated Environment Setup: See [Vagrant Logs & Troubleshooting (EN](./02-Vagrant-Automation/readme-en.md) / [TR)](./02-Vagrant-Automation/readme.md)
  - 📜 Linux Basics & Custom Script: See [Linux Basics Notes (EN](./01-Linux-Basics/readme-en.md) / [TR)](./01-Linux-Basics/readme.md)

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
  - 🪵 Text Process Workspace: See [Log Analysis Notes (EN](./08-Linux-Log-Analysis/readme-en.md) / [TR)](./08-Linux-Log-Analysis/readme.md)
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
  - ⏰ Cron & Automation Workspace: See [Cron & Automation Notes (EN](./15-Linux-Cron-Automation/readme-en.md) / [TR)](./15-Linux-Cron-Automation/readme.md)
  - 📊 Quiz Results: See [Phase 15 Quiz Results](./15-Linux-Cron-Automation/quiz-results.md)

### 🔹 June 23, 2026 | DevOps - Linux Temelleri (Udemy Course)

_Couldn't do hands-on work today since the company laptop doesn't allow running VMs or the tools I'd normally use. Used the day to complete a DevOps - Linux Temelleri course on Udemy instead, to keep making progress even without direct lab access._

- **Tasks & Objectives:**
  - Completed the "DevOps - Linux Temelleri" course on Udemy.
- **Milestones & Deliverables:**
  - 🎓 Course Completion: DevOps - Linux Temelleri (Udemy)

### 🔹 June 23, 2026 | Docker & Networking Research

_Continued the A'dan Z'ye Docker course (finished the intro, now in the setup/installation section), and spent time researching core networking concepts — the internet, protocols, end systems, packet switching, latency, and throughput. Also went through the graduation/review questions from the Linux roadmap given earlier in the internship._

- **Tasks & Objectives:**
  - Finished the intro section of the "A'dan Z'ye Docker" Udemy course, currently in the installation section.
  - Researched networking fundamentals: the internet, protocols, end systems, packet switching, latency, and throughput.
  - Worked through the graduation/review questions from the assigned Linux roadmap.
- **Milestones & Deliverables:**
  - 🐳 In progress: A'dan Z'ye Docker (Udemy)
  - 🌐 Networking fundamentals research (no hands-on lab this session)

### 🔹 June 24, 2026 | Git — Branching, Merging, and a Real Push Conflict

_Tested `git branch` and `git merge` directly on this repo — created a test branch, committed a file to it, confirmed `main` was unaffected, then merged it back in (a clean fast-forward). Cleaning up afterward led to a real conflict: `git push` got rejected because the remote had changes the local repo didn't have yet. Running `git pull` to fix that got stuck — the merge needed a commit message, and Git tried to open a configured editor (WebStorm) that wasn't actually installed at that path, so the merge was left half-done. Fixed it by setting Notepad as the default editor (`git config --global core.editor "notepad"`), completing the commit, and pushing successfully. Also mixed up `git branch` (lists branches) with creating one when answering the quiz, even though the command itself was used correctly during the actual hands-on part._

- **Tasks & Objectives:**
  - Created and switched to a new branch (`git checkout -b`), committed a file to it, and confirmed branch isolation by checking that `main` didn't have the file until merged.
  - Performed a fast-forward merge (`git merge`) and cleaned up the test branch/file afterward.
  - Hit and resolved a real `git push` rejection caused by unsynced remote changes.
  - Diagnosed and fixed a stuck `git pull`/merge caused by a misconfigured, nonexistent editor path.
  - Reconfigured Git's default editor globally (`git config --global core.editor`).
- **Milestones & Deliverables:**
  - 🔧 Git Workspace: See [Git Notes](./16-Git-Basics/notes.md)
  - 📊 Quiz Results: See [Phase 16 Quiz Results](./16-Git-Basics/quiz-results.md)

### 🔹 June 24, 2026 | Full Review & Mini Project (Real Server)

_Did a full review pass over everything so far, going through scenario-style questions modeled on the roadmap's actual graduation criteria (e.g. "what's listening on port 443," "why would DNS resolution fail," "how do you add a new disk") instead of just rereading notes. Answering out loud surfaced real gaps — forgot `-p err` for filtering journalctl by severity, mixed up `tail -f` with `tail -n`, got `ss -l` vs `-a` slightly wrong, forgot the partition step when describing adding a new disk, and reversed which is more important to understand why LVM exists versus just running the commands. Went back into the notes for Storage, Service Management, Permissions, Log Analysis, Network, and LVM and filled in what was actually missing — not just typos, but real explanatory gaps (e.g. the `chmod` 4/2/1 breakdown wasn't actually spelled out anywhere before this)._

_Then did the mini-project on the real server purchased this week — created a non-root sudo user, set up SSH key access the same way as the original SSH phase, installed Nginx and Docker (verified with `hello-world`), installed Git and cloned this exact repository, and published a static page from it. Hit two real issues: forgot that the cloned repo and the file Nginx actually serves are separate copies, so `git pull` alone didn't update the live page until the file was re-copied; and got a "refused to connect" in the browser that turned out to be from trying `https://` when only port 80 (HTTP) was ever configured — same category of mistake as the 502 from the Proxy phase, just a different layer._

- **Tasks & Objectives:**
  - Answered scenario-based review questions covering processes, ports, DNS, disk management, log analysis, SSH, cron, and file permissions.
  - Identified and fixed real gaps in the notes for 6 phases (Storage, Service Management, Permissions, Log Analysis, Network, LVM).
  - Set up a non-root sudo user and SSH key-based access on a real rented server.
  - Installed and verified Nginx and Docker on the server.
  - Installed Git, cloned this repository, and published a static page from it via Nginx.
  - Debugged a stale-deployment issue (source file vs. served file) and an HTTPS-vs-HTTP connection issue.
- **Milestones & Deliverables:**
  - 📝 Deepened Notes: [Storage](./10-Linux-Storage-Management/notes.md) · [Service Management](./07-Linux-Service-Management/notes.md) · [Permissions](./05-Linux-Permissions/notes.md) · [Log Analysis](./08-Linux-Log-Analysis/notes.md) · [Network](./09-Linux-Network-Management/notes.md) · [LVM](./11-Linux-LVM-Management/notes.md)
  - 🚀 Mini Project: See [Mini Project Notes](./17-Mini-Project/notes.md)

### 🔹 June 26, 2026 | Path-Based Grouping & OSI Model (In Progress)

_Continued with the additional tasks given by my mentor. First, tested path-based IP grouping (conceptually similar to SQL's `GROUP BY` + `COUNT()`) on a real Nginx access log with actual server traffic — every IP appeared exactly once, which is what normal, non-suspicious traffic looks like, as opposed to a single IP repeating at a high count._

_Then started on the OSI model. After learning the 7 layers conceptually, practiced identifying which ones are actually active in real scenarios (`dig`, `curl https://`, `ssh`) — worked out on my own that a plain DNS query never involves Layer 6 (encryption), while `https://` or SSH does. Realized Layer 7 is about which protocol is being spoken, not which tool is used to speak it (PuTTY, a terminal, or an FTP client are all just tools running some protocol). Learned encapsulation (each layer wrapping data in its own header), and installed `tcpdump` to capture a real HTTP request as a packet, confirming with my own eyes that the IP, port, and HTTP text genuinely sit inside the same packet, layered the way the model describes. Encapsulation/decapsulation isn't fully finished, so the OSI phase is marked as "in progress" — felt more honest to note exactly where things stand than to build new topics on top of a half-finished foundation._

- **Tasks & Objectives:**
  - Tested path-based IP grouping (`grep`/`awk`/`sort`/`uniq -c`) on real server traffic in an Nginx access log.
  - Learned the OSI model's 7 layers, and practiced identifying which ones are active using real commands (`dig`, `curl`, `ssh`).
  - Clarified the difference between Layer 2 (MAC) and Layer 3 (IP), and why both are necessary.
  - Learned the concept of encapsulation, and installed `tcpdump` to capture a real HTTP request at the packet level.
  - Marked the OSI phase as "in progress," since encapsulation/decapsulation isn't fully covered yet.
- **Milestones & Deliverables:**
  - 🪵 Path-Based Grouping: [Log Analysis Notes (EN](./08-Linux-Log-Analysis/readme-en.md) / [TR)](./08-Linux-Log-Analysis/readme.md) updated
  - 🌐 OSI Model (In Progress): [OSI Model Notes (EN](./18-Linux-Networking-Fundamentals/readme-en.md) / [TR)](./18-Linux-Networking-Fundamentals/readme.md)

### 🔹 June 29, 2026 | Completing OSI, Routing & Forwarding, DNS Resolution Chain

_Finished the OSI model entirely: went deep into encapsulation/decapsulation, clarifying that MAC headers change at every router hop while IP headers stay the same. Learned ICMP, and ran a real `traceroute`/`ping` comparison against Cloudflare, Google, Claude.ai, and my own company's website (Türkiye Sigorta), observing how each organization's ICMP policy differed — a network-level echo of the Least Privilege principle from earlier phases._

_Then moved on to routing and forwarding. Examined my own real routing table with `ip route`, learned the difference between static and dynamic routing. Checking `ip_forward` showed it unexpectedly active — first assumed it was a hosting-provider default, but research showed it's actually a normal consequence of having Docker installed, since containers need it to reach the internet._

_Finally started on the DNS resolution chain — learned the hierarchy between recursive resolvers, root servers, TLD servers, and authoritative servers, and used `dig +trace` to watch this process happen in real time (from root servers down through the `.com` TLD servers). This topic isn't finished yet — to be continued tomorrow._

- **Tasks & Objectives:**
  - Completed encapsulation/decapsulation in the OSI model, clarified what routers do to MAC/IP headers.
  - Learned ICMP, and observed different organizations' security policies through a real `traceroute`/`ping` comparison.
  - Learned routing and forwarding concepts using a real routing table.
  - Investigated why `ip_forward` was active, confirming the Docker connection.
  - Started the DNS resolution chain, following a real resolution process with `dig +trace`.
- **Milestones & Deliverables:**
  - 🌐 OSI Model (Complete) & Routing/Forwarding: [Notes (EN](./18-Linux-Networking-Fundamentals/readme-en.md) / [TR)](./18-Linux-Networking-Fundamentals/readme.md)

### 🔹 June 30, 2026 | DNS Record Types, TTL, and Cloud Outage Research

_Finished the rest of DNS. First, went through yesterday's `dig +trace` output line by line — understood the chain from root servers to TLD to the authoritative server using my own phone-book analogy ("I ask someone, they don't know but know who does" chain). Noticed each level has 13 (or 4) backup servers, but only one is actually queried — confirmed directly with a real IPv6 timeout case (automatic fallback to IPv4)._

_Tested TTL by running the same query twice in a row — saw the TTL actually decrease (141 → 139) and the second query return instantly (0ms), concrete proof of how caching works. Also tested negative caching (`NXDOMAIN`), learning that even a non-existent domain has its own TTL._

_Then queried all 8 DNS record types (A, AAAA, CNAME, MX, TXT, NS, SRV, PTR) one by one against real domains. Worked through how I'd actually use each one if I had my own domain (alifurkan.com). Discovered and confirmed on my own that Türkiye Sigorta runs three mail servers (for failover) and uses Azure DNS; that Google skips CNAME in favor of multiple direct A records on some subdomains; and that Cloudflare and Google deliberately set matching PTR records for their own IPs (one.one.one.one, dns.google)._

_Finally, researched real, recent outages from AWS, Cloudflare, and Google Cloud — comparing AWS's DynamoDB DNS record being deleted by an automation bug, Cloudflare's outage from expired DNSSEC signatures, and Google's outage (authorization-related, not DNS), which made the "not every major outage is a DNS problem" distinction clear. Wrote this up as a separate, sourced document._

- **Tasks & Objectives:**
  - Analyzed `dig +trace` output in detail, understood every step of the resolver chain (root → TLD → authoritative).
  - Confirmed TTL actually decreasing and caching working, via two consecutive queries.
  - Tested negative caching (`NXDOMAIN`).
  - Learned all 8 DNS record types (A, AAAA, CNAME, MX, TXT, NS, SRV, PTR) by querying real domains.
  - Tested `nslookup`, `host`, and `resolvectl` debug tools.
  - Researched real DNS-related outages from AWS, Cloudflare, and Google Cloud, producing a sourced document.
- **Milestones & Deliverables:**
  - 🌐 DNS (Complete): [Networking Notes (EN](./18-Linux-Networking-Fundamentals/readme-en.md) / [TR)](./18-Linux-Networking-Fundamentals/readme.md)
  - 🔥 Cloud Outage Research: [Notes (EN](./18-Linux-Networking-Fundamentals/dns-outages-EN.md) / [TR)](./18-Linux-Networking-Fundamentals/dns-outages-TR.md)

### 🔹 July 1, 2026 | Nginx Deep Dive — Reverse Proxy, Path Management, Forward Proxy

_Completed the Nginx deep dive phase. Used Python's built-in HTTP server as a backend and put Nginx in front of it — confirmed the reverse proxy was working by seeing requests arrive in the backend log from `127.0.0.1` (Nginx) instead of the user's actual IP. Then set up path-based routing: `/users/` → port 3000, `/computers/` → port 4000. Learned path rewrite through the trailing slash difference in `proxy_pass` — without it, got 404; with it, got 200, because the system wasn't interpreting the path as "go into that folder" without the slash. During path blocking, using `return 403` alongside `deny all` caused localhost to be blocked too — removing it fixed the issue. A real mistake that made it into the notes._

_Set up Squid as a forward proxy. Configured Windows to use `<SERVER_IP>:3128` as a system proxy, visited `ifconfig.me` in the browser and saw the server's IP instead of my real Windows IP. The Squid access log showed all Windows outgoing traffic — `claude.ai`, `apple.com`, `windows.com` included — passing through the proxy. Directly confirmed that the proxy was working and all data leaving the machine was going through Squid._

- **Tasks & Objectives:**
  - Configured Nginx as a reverse proxy, verified via backend log.
  - Set up path-based routing (3 different services, 3 different ports).
  - Learned path rewrite (trailing slash difference) through hands-on testing.
  - Applied path blocking with internal/external distinction (`allow`/`deny`).
  - Set up Squid as a forward proxy, confirmed all Windows traffic passing through it via the access log.
- **Milestones & Deliverables:**
  - 🌐 Nginx Deep Dive: [Notes (EN](./19-Nginx-Derinleşme/readme-en.md) / [TR)](./19-Nginx-Derinleşme/readme.md)

### 🔹 July 2, 2026 | Nginx Test Cases & Documentation Updates

_Ran the Nginx config through 20 different scenarios — routing, path blocking, rewrite, and error conditions. 19 came back as expected, one didn't: `curl http://localhost/admin` returned 403, even though the config had `allow 127.0.0.1` and should have let it through. From earlier Linux training I remembered Ubuntu tends to prefer IPv6, but I needed to actually verify it. Ran `curl -v` and saw Ubuntu was resolving `localhost` as `::1` (IPv6), not `127.0.0.1` (IPv4). Nginx treats these as two separate addresses, so `allow 127.0.0.1` alone wasn't enough. Added `allow ::1` to the config and it worked. Then tested with `127.0.0.1` directly — that worked too, since it goes over IPv4. Confirmed that writing both is the right approach._

_Also completed the bilingual documentation conversion for all phases (03–19), and updated the Nginx README to reflect the IPv6 finding and correct test results._

- **Tasks & Objectives:**
  - Wrote and ran 20 test scenarios against the real server.
  - Discovered the IPv6/IPv4 mismatch in TC-11, fixed it by adding `allow ::1`.
  - Updated Nginx README (TR + EN) — `allow ::1`, explanation, corrected test results.
  - Created test-cases.md and test-cases-EN.md.
  - Completed bilingual documentation for all phases 03–19.
- **Milestones & Deliverables:**
  - 🧪 Test Cases: [TR](./19-Nginx-Derinleşme/test-cases.md) / [EN](./19-Nginx-Derinleşme/test-cases-en.md)
  - 🌐 Nginx Deep Dive: [README (TR](./19-Nginx-Derinleşme/readme.md) / [EN)](./19-Nginx-Derinleşme/readme-en.md)

### 🔹 July 3, 2026 | Rate Limiting & Load Balancing

_For rate limiting, defined a zone with `limit_req_zone` and applied it to all locations — sending 20 requests, the first 12 went through and the rest returned 503. For load balancing, set up a second instance for the users service and defined an upstream block. Round-robin worked, then I killed Instance 1 — Nginx automatically switched to Instance 2, no downtime. When Instance 1 came back, round-robin resumed. Also researched `least_conn` and `ip_hash` — didn't use them in this phase but understood when they're needed._

- **Tasks & Objectives:**
  - Set up and tested rate limiting (`limit_req_zone`, `burst`, `nodelay`).
  - Set up load balancing — round-robin, failover, and external testing.
  - Researched `least_conn` and `ip_hash` methods.
- **Milestones & Deliverables:**
  - 🚦 Rate Limiting & Load Balancing: [README (TR](./20-Rate-Limiting-Load-Balancing/README.md) / [EN)](./20-Rate-Limiting-Load-Balancing/README-EN.md)

### 🔹 July 6, 2026 | OpenResty — Token Authentication, PostgreSQL, MySQL, Redis

_Implemented new task: built a token-protected API with OpenResty, connecting to PostgreSQL, MySQL, and Redis. All services came up with a single `docker compose up`. The official OpenResty image didn't include pgmoon — package managers didn't work on Alpine, so pulled it directly from GitHub. Also discovered that `resolver 127.0.0.11` is needed in nginx.conf for container name resolution — without it, Nginx can't resolve "postgres" to an IP. Token missing: 401. Token valid: users from PostgreSQL, products from MySQL, data from Redis cache — all working._

- **Tasks & Objectives:**
  - Set up OpenResty, PostgreSQL, MySQL, and Redis with Docker Compose.
  - Token authentication — `auth.lua` checks every incoming request.
  - PostgreSQL (`/users`), MySQL (`/products`), Redis (`/cache`) endpoints.
  - Added pgmoon via Dockerfile.
  - `resolver 127.0.0.11` — required for container DNS resolution.
- **Milestones & Deliverables:**
  - 🔐 OpenResty API: [README (TR](./21-OpenResty-API/README.md) / [EN)](./21-OpenResty-API/README-EN.md)

### 🔹 July 8, 2026 | rclone & Amazon S3 — Cloud Storage and Secure Access

_Explored rclone, created an Amazon S3 bucket and connected to it. During configuration I typed `EU` for the location constraint instead of `eu-central-1` — assumed `EU` would cover all European regions, but it has to match the region exactly. Caught the error and fixed it. Tested performance parameters: `--transfers`, `--checkers`, `--buffer-size`, `--fast-list`, `--bwlimit`. A 64MB buffer created overhead with 10 small files, 16MB was more balanced. Used `rclone serve http` to expose the private bucket on port 8090 — files in S3 became browsable from a browser without any AWS credentials._

- **Tasks & Objectives:**
  - Created AWS S3 bucket, connected via rclone.
  - Encountered and fixed a location_constraint mismatch error.
  - Tested performance parameters (`--transfers`, `--checkers`, `--buffer-size`, `--fast-list`, `--bwlimit`).
  - Exposed a private S3 bucket over HTTP with `rclone serve http`.
- **Milestones & Deliverables:**
  - 🗄️ rclone & S3: [README (TR](./22-rclone-S3/README.md) / [EN)](./22-rclone-S3/README-EN.md)

---

ℹ️ _Note: Everything documented here was tested locally, both in sandboxed VMs and on a real rented server._
