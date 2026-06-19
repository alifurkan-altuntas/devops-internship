# 🚀 DevOps & Linux Infrastructure Journey - Türkiye Sigorta

Welcome to my DevOps engineering journal. This repository is dedicated to documenting my structured learning path, infrastructure automation practices, error resolutions, and Linux systems administration tasks during my internship.

## 📁 Repository Structure

- [01-Linux-Basics](./01-Linux-Basics/): Core Linux administration telemetry, stream processing (`awk`, `grep`, `cut`), and custom automation scripts.
- [02-Vagrant-Automation](./02-Vagrant-Automation/): Infrastructure as Code (IaC) environments, provider bridges, and multi-distribution provisioning logs.
- [03-File-System-Management](./03-File-System-Management/): Storage diagnostics, physical block allocation strategies (`dd`), and advanced data stream sorting pipelines.
- [04-User-Privilege-Management](./04-User-Privilege-Management/): Identity access control, system group lifecycles, and granular sudoers security constraints (Least Privilege Principle).
- [05-Linux-Permissions](./05-Linux-Permissions/): File system access control, recursive ownership migration matrices, and advanced isolation layers.
- [06-Linux-Process-Management](./06-Linux-Process-Management/): Process status monitoring, CPU priority adjustments (`nice`/`renice`), and kernel-level signal operations.
- [07-Linux-Service-Management](./07-Linux-Service-Management/): Systemd service lifecycle automation, zero-downtime reconfigurations, and binary log auditing.
- [08-Linux-Log-Analysis](./08-Linux-Log-Analysis/): Multi-stage text processing pipelines, column-based pattern extraction, and cross-distribution network diagnostics.

### 📝 Evaluation & Assessment Artifacts

- [challenges.md](./challenges.md): Verified production scenario matrices, question sheets, and technical system administration answers (Phases 1-4).
- [quiz-results.md](./quiz-results.md): Comprehensive 20-question engineering evaluation logs with 85% success performance profile (Phases 1-4).
- [Phase 5 Quiz Logs](./05-Linux-Permissions/quiz-results.md): Targeted 5-question assessment telemetry covering masking filters and special directory perimeters.
- [Phase 6 Quiz Logs](./06-Linux-Process-Management/quiz-results.md): Perfect metric evaluation (100% Score) monitoring process tracking loops and signal states.
- [Phase 7 Quiz Logs](./07-Linux-Service-Management/quiz-results.md): Infrastructure service assessment (100% Score) analyzing daemon initialization states and runtime journals.
- [Phase 8 Quiz Logs](./08-Linux-Log-Analysis/quiz-results.md): High-performance log manipulation assessment (100% Score) parsing structured token streams.

---

## 📅 Daily Progress Logs

### 🔹 June 17, 2026 | Automated Provisioning & Dynamic Telemetry

- **Tasks & Objectives:**
  - Initialized isolated testing laboratory environments using **Vagrant** over the `vmware_desktop` provider to embrace Infrastructure as Code (IaC) workflows.
  - Deployed and configured **Ubuntu** and **Rocky Linux 9.8 (Minimal CLI)** server instances.
  - Explored core Linux telemetry commands and analyzed enterprise configuration standards (FQDN defaults on Rocky Linux).
  - Designed and tested a production-ready system monitoring shell script to parse live metrics dynamically.
- **Milestones & Deliverables:**
  - 🛠️ Automated Environment Setup: See [Vagrant Logs & Troubleshooting](./02-Vagrant-Automation/)
  - 📜 Enterprise Scripting & Telemetry Parsing: See [Linux Basics & Custom Report Script](./01-Linux-Basics/)

### 🔹 June 18, 2026 | File System Manipulation & Enterprise Storage Auditing

- **Tasks & Objectives:**
  - Mastered Linux file system directory hierarchies, dynamic permissions, and storage diagnostic navigation (`pwd`, `ls`, `cd`, `mkdir`, `rm`, `cp`, `mv`).
  - Executed physical storage pressure emulation by generating a 10 GB continuous telemetry payload using low-level block writes.
  - Analyzed architectural behaviors of standard utilities (`dd` vs `fallocate`) regarding metadata mapping vs raw data writing on sparse block engines.
  - Engineered an emergency production diagnostics pipeline combining find syntax, disk utilities, and human-readable reverse sort mechanisms to trap the top 10 heaviest files under root nodes.
- **Milestones & Deliverables:**
  - 🗂️ File System Operations & Pipelines: See [Storage Diagnostics & Command Matrix](./03-File-System-Management/)

### 🔹 June 18, 2026 | Identity Access Control & Security Hardening (Least Privilege)

- **Tasks & Objectives:**
  - Studied Linux user and group authentication mechanics (`useradd`, `groupadd`, `id`) and security boundaries within `/etc/passwd` and `/etc/group`.
  - Implemented the **Least Privilege Principle (En Düşük Yetki İlkesi)** to enforce structural operating system hardening.
  - Provisioned a restricted operator account (`devopstester`) configured specifically via `visudo` and the `/etc/sudoers` architecture.
  - Isolated execution vectors to allow the restricted user to run _only_ `systemctl restart nginx` targeted explicitly at root space (`ALL=(root)`), maintaining credentials verification prompts as an extra security layer while successfully blocking unauthorized operations (e.g., `systemctl stop nginx`).
- **Milestones & Deliverables:**
  - 🔑 Role-Based Access Controls: See [User Administration & Sudoers Constraints](./04-User-Privilege-Management/)

### 🔹 June 19, 2026 | Comprehensive Technical Assessment & Post-Mortem Analysis

- **Tasks & Objectives:**
  - Consolidated knowledge domains across all completed infrastructural modules through a rigorous testing phase.
  - Resolved situational system challenge matrices regarding file stream bottlenecks, sparse token mapping behaviors, and systemd execution restrictions.
  - Executed a comprehensive 20-question administration quiz covering Infrastructure as Code logic, advanced filtering pipelines, and rule parsing validations inside privileged security subsystems.
  - Documented explicit engineering post-mortems for architectural gaps (Vagrant daemon layer metrics and kernel release flag identifiers) to construct a clean validation profile.
- **Milestones & Deliverables:**
  - 📝 Scenario Solutions: See [Verified Production Scenario Matrices](./challenges.md)
  - 📊 Examination Logs: See [20-Question Evaluation & Post-Mortem Analytics](./quiz-results.md)

### 🔹 June 19, 2026 | Storage Authorization Layers & Shared Environment Hardening

- **Tasks & Objectives:**
  - Analyzed standard Linux authorization maps (`rwx`), numerical masking conversions (`755` vs `644`), and user layout masks (`umask`).
  - Audited asset distribution commands (`chown` and `chgrp`) to automate recursive file tree ownership migrations.
  - Deployed a shared production storage facility (`/tmp/test`) configured with custom **Sticky Bit** privileges (`+t`).
  - Successfully trapped and logged unauthorized deletion streams across independent operator profiles to preserve environment integrity.
- **Milestones & Deliverables:**
  - 🔑 Security Hardening Workspace: See [Storage Diagnostics & Permissions Matrix](./05-Linux-Permissions/notes.md)
  - 📊 Validation Diagnostics: See [Phase 5 Assessment Analytics](./05-Linux-Permissions/quiz-results.md)

### 🔹 June 19, 2026 | Kernel Process Telemetry & Prioritization Engineering

- **Tasks & Objectives:**
  - Explored native process status architectures (`ps`, `pidof`) and implemented real-time monitoring via native utilities (`top`) to ensure compatibility with minimalist air-gapped nodes.
  - Simulated production failure scenarios by deploying background processor stress tests and intercepting them seamlessly with precise kernel signals (`SIGKILL -9`).
  - Evaluated architectural differences between universal tracking engines and modern tree-view visualization overlays (`htop`).
  - Mastered CPU resource balance scheduling by configuring custom initial load weights (`nice`) and shifting current prioritization grids dynamically (`renice`).
- **Milestones & Deliverables:**
  - ⚙️ Process Operations Workspace: See [Process Telemetry & Matrix Logs](./06-Linux-Process-Management/notes.md)
  - 📊 Performance Evaluation: See [Phase 6 Clean Validation Analytics (100% Score)](./06-Linux-Process-Management/quiz-results.md)

### 🔹 June 19, 2026 | Service Lifecycle Automation & Centralized Journal Auditing

- **Tasks & Objectives:**
  - Provisioned enterprise web utilities (Nginx) across distinct distribution ecosystems, analyzing package execution management layers (`dnf` vs `apt`).
  - Deconstructed architectural deployment philosophies, contrasting user-friendly automatic startup defaults with enterprise zero-trust initialization constraints.
  - Implemented core systemd automation blocks, distinguishing structural persistence links (`enable`) from dynamic real-time runtime state changes (`start`).
  - Engineered zero-downtime hot-reconfigurations (`reload`) and hooked into unified binary journal streams (`journalctl -u -f`) to track runtime service logs dynamically.
- **Milestones & Deliverables:**
  - 🏗️ Service Control Workspace: See [Systemd Daemon Lifecycles & Configurations](./07-Linux-Service-Management/notes.md)
  - 📊 Operational Analytics: See [Phase 7 Performance Evaluation (100% Score)](./07-Linux-Service-Management/quiz-results.md)

  ### 🔹 June 19, 2026 | High-Density Log Processing & Stream Token Engineering

- **Tasks & Objectives:**
  - Explored structural web logs format patterns, mapping column tokens (`$1` Client IP, `$7` Path URI, `$9` HTTP Status) to decode native transaction layouts.
  - Analyzed multi-distribution networking behaviors, troubleshooting default IPv6 loopback routing (`::1`) on Ubuntu against backward-compatible IPv4 layers (`127.0.0.1`) inside Rocky Linux.
  - Resolved utility packaging anomalies, mitigating minimal image footprint variations via on-demand compilation loops for network diagnostics tools (`curl`).
  - Constructed enterprise text analytics pipelines leveraging chained filters (`grep`, `awk`, `sort`, `uniq`) to isolate brute-force vectors and audit corrupted 404 path triggers.
- **Milestones & Deliverables:**
  - 🪵 Text Process Workspace: See [Log Analytics & Command Processing Templates](./08-Linux-Log-Analysis/notes.md)
  - 📊 Operational Analytics: See [Phase 8 Performance Evaluation (100% Score)](./08-Linux-Log-Analysis/quiz-results.md)

---

ℹ️ _Note: All mechanisms, network layers, and automation scripts are rigorously tested locally within sandboxed virtualization instances before integration._
