# 🏗️ Linux Service & Log Management (`systemd` Architecture)

This document covers systemd service management, journalctl, and distro defaults across major Linux distribution families.

---

## 1. Service Lifecycle & Log Auditing

Apps, web servers, and databases typically run as background daemons under `systemd` (PID 1). This lab covers provisioning Nginx and manipulating its internal states cleanly.

### 🛠️ Steps

1. **Installing Nginx (Different Package Managers):**
   Depending on the target operating system family, appropriate package managers must be utilized to resolve upstream dependencies:
   - **RHEL / Rocky Linux (DNF):**
     ```bash
     sudo dnf install nginx -y
     ```
   - **Debian / Ubuntu (APT):**
     ```bash
     sudo apt install nginx -y
     ```

2. **Checking Initial Status:**
   ```bash
   systemctl status nginx
   ```

   _RHEL/Rocky Linux Output:_ Disabled by default. The unit file initializes as `Loaded: ...; disabled; ...` and `Active: inactive (dead)`.

   _Ubuntu Output:_ Enabled and started automatically right after install.

3. **Enabling and Starting the Service:**
   To make sure it survives a reboot and runs now:
   ```bash
   sudo systemctl enable nginx
   sudo systemctl start nginx
   ```
   _Verification:_ `systemctl status nginx` now yields a green `Active: active (running)` token along with the structural `Enabled` configuration flag.

4. **Stop, Restart, Reload:**

   - To stop the service:
     ```bash
     sudo systemctl stop nginx
     ```
   - To fully stop and restart the process (triggers a hard connection reset):
     ```bash
     sudo systemctl restart nginx
     ```
   - To apply configuration changes without dropping active connections (zero-downtime):
     ```bash
     sudo systemctl reload nginx
     ```

---

## 2. Viewing Logs with `journalctl`

Logs are viewed via `journalctl` instead of flat text files. Beyond the basics, two flags make this genuinely useful for troubleshooting rather than just scrolling through everything: **`-p`** (priority/severity) and **`--since`** (time range).

### Basic Usage

```bash
journalctl -u nginx          # full log history for the service
journalctl -u nginx -f       # live tail of new log entries
```

### Filtering by Severity (`-p`)

Systemd logs have severity levels, from most to least critical:

| Level | Meaning |
| --- | --- |
| `emerg` | System is unusable |
| `alert` | Immediate action required |
| `crit` | Critical condition |
| `err` | Error |
| `warning` | Warning |
| `notice` | Normal but significant |
| `info` | Informational |
| `debug` | Debug-level detail |

`-p` filters to a level **and everything more severe than it**. So:
```bash
journalctl -u nginx -p err
```
shows `err`, `crit`, `alert`, and `emerg` entries — but not `warning` or below. This cuts out routine noise and surfaces only what's actually worth looking at.

### Filtering by Time (`--since`, `--until`)

```bash
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2026-06-22 14:00:00" --until "2026-06-22 15:00:00"
```

`--since` accepts both relative ("1 hour ago", "yesterday") and absolute timestamps.

### Combining Both — A Real Troubleshooting Scenario

If Nginx is reported as having problems and the goal is "what went wrong in the last hour," combining both flags narrows this down immediately:

```bash
journalctl -u nginx -p err --since "1 hour ago"
```

This reads as: *"show me only the error-level-or-worse logs for Nginx, from the last hour"* — instead of scrolling through a full, mostly irrelevant log history to manually spot the one line that matters.

---

## 📊 Command Reference

| Command | Purpose | Example | Notes |
| --- | --- | --- | --- |
| **`systemctl start`** | Starts the service now. | `sudo systemctl start nginx` | Does not persist across reboots on its own. |
| **`systemctl enable`** | Sets the service to start on boot. | `sudo systemctl enable nginx` | Persistence — separate from `start`. |
| **`systemctl stop`** | Stops the running service. | `sudo systemctl stop nginx` | |
| **`systemctl restart`** | Stops and starts the service (brief downtime). | `sudo systemctl restart nginx` | |
| **`systemctl reload`** | Reloads config without downtime. | `sudo systemctl reload nginx` | Not all services support this — depends on the unit. |
| **`journalctl -u`** | Shows logs for a specific unit. | `journalctl -u nginx` | |
| **`journalctl -p`** | Filters logs by severity level (and more severe). | `journalctl -u nginx -p err` | Levels: emerg, alert, crit, err, warning, notice, info, debug. |
| **`journalctl --since` / `--until`** | Filters logs by time range. | `journalctl --since "1 hour ago"` | Accepts relative or absolute timestamps. |
| **`journalctl -f`** | Live-follows new log entries. | `journalctl -u nginx -f` | |

---

ℹ️ _All commands tested locally._