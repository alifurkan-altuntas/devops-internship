# 🚀 DevOps & Linux Infrastructure Journey - Türkiye Sigorta

Welcome to my DevOps engineering journal. This repository is dedicated to documenting my structured learning path, infrastructure automation practices, error resolutions, and Linux systems administration tasks during my internship.

## 📁 Repository Structure
- [01-Linux-Basics](./01-Linux-Basics/): Core Linux administration telemetry, stream processing (`awk`, `grep`, `cut`), and custom automation scripts.
- [02-Vagrant-Automation](./02-Vagrant-Automation/): Infrastructure as Code (IaC) environments, provider bridges, and multi-distribution provisioning logs.
- [03-File-System-Management](./03-File-System-Management/): Storage diagnostics, physical block allocation strategies (`dd`), and advanced data stream sorting pipelines.

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

---
ℹ️ *Note: All mechanisms, network layers, and automation scripts are rigorously tested locally within sandboxed virtualization instances before integration.*