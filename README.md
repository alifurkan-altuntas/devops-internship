# 🚀 DevOps & Linux Infrastructure Journey - Türkiye Sigorta

Welcome to my DevOps engineering journal. This repository is dedicated to documenting my structured learning path, infrastructure automation practices, error resolutions, and Linux systems administration tasks during my internship.

## 📁 Repository Structure

- [01-Linux-Basics](./01-Linux-Basics/): Core Linux administration telemetry, stream processing (`awk`, `grep`, `cut`), and custom automation scripts.
- [02-Vagrant-Automation](./02-Vagrant-Automation/): Infrastructure as Code (IaC) environments, provider bridges, and multi-distribution provisioning logs.
- [03-File-System-Management](./03-File-System-Management/): Storage diagnostics, physical block allocation strategies (`dd`), and advanced data stream sorting pipelines.
- [04-User-Privilege-Management](./04-User-Privilege-Management/): Identity access control, system group lifecycles, and granular sudoers security constraints (Least Privilege Principle).

### 📝 Evaluation & Assessment Artifacts

- [challenges.md](./challenges.md): Verified production scenario matrices, question sheets, and technical system administration answers.
- [quiz-results.md](./quiz-results.md): Comprehensive 20-question comprehensive evaluation logs with 85% success performance profile and infrastructure post-mortems.

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

---

ℹ️ _Note: All mechanisms, network layers, and automation scripts are rigorously tested locally within sandboxed virtualization instances before integration._
