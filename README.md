DevOps Internship Journey

This repository is dedicated to documenting my daily learning processes, infrastructure automation practices, and Linux tasks during my DevOps internship under the guidance.

## 📅 Daily Progress Logs

### 🔹 June 17, 2026
- **Tasks & Objectives:**
  - Initialized the local testing laboratory environments.
  - Downloaded and initiated the deployment of **Ubuntu VM** and **Rocky Linux 9.8 (Minimal ISO)** on VMware.
  - Created the public tracking repository and structured the documentation standard (`Markdown`).
- **Notes:** *Ready for command-line practices as soon as the operating systems are initialized.*

---
ℹ️ *Note: All practices are tested locally on standalone virtualization instances before documenting.*

- **Vagrant Integration & Infrastructure as Code:**
  - Decided to switch from manual ISO setups to **Vagrant** to automate virtual machine provisioning over the `vmware_desktop` provider.
- **Troubleshooting: Vagrant VMware Plugin Fix:**
  - *The Issue:* Vagrant threw an error because it couldn't find a default provider (like VirtualBox).
  - *The Solution:* Installed the official VMware plugin to bridge Vagrant with VMware Workstation:
```bash
    vagrant plugin install vagrant-vmware-desktop
```
- **Troubleshooting: Box 404 Error:**
  - *The Issue:* `vagrant init rocky Linux/9` caused a 404 error due to an incorrect registry name format.
  - *The Solution:* Switched to a verified, VMware-compatible box:
```bash
    vagrant init generic/rocky9
    vagrant up
```
- **Core Linux Telemetry & Text Processing:**
  - Investigated `hostname`, `hostnamectl`, `timedatectl`, `uname -a`, and `cat /etc/os-release`.
  - Noticed that Rocky Linux defaults to `.localdomain` due to enterprise FQDN architectures, unlike Ubuntu.
  - Explored the fundamentals of data stream piping using `grep`, `cut`, `awk`, and `tr` to filter out raw data.
- **Automation Task: Advanced System Reporting Script:**
  - Created a robust bash script (`report.sh`) to dynamically parse system logs into a clean, side-by-side aligned layout.

```bash
#!/bin/bash
echo "=========================================="
echo "         Host Report         "
echo "=========================================="
echo -n "1. HostName:                 "
hostname
echo -n "2. Ip Address:               "
hostname -I
echo -n "3. System Information:       "
cat /etc/os-release | grep "PRETTY_NAME" | cut -d '=' -f 2 | tr -d '"'
echo "Disk Information:"
df -h / | awk 'NR==2 {print "Toplam: " $2 " | Kullanilan: " $3 " | Bos: " $4}'
echo "=========================================="
```
