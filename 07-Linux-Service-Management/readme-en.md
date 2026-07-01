# 🏗️ Linux Service & Log Management (`systemd` Architecture)

This document covers systemd service management, journalctl, and distro defaults across major Linux distribution families.

---

## 1. Service Lifecycle & Log Auditing

Apps, web servers, and databases typically run as background daemons under `systemd` (PID 1). This section covers provisioning Nginx and manipulating its internal states.

### 🛠️ Steps

1. **Installing Nginx (Different Package Managers):**
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

   - **RHEL/Rocky Linux output:** Disabled by default — `Loaded: ...; disabled; ...` and `Active: inactive (dead)`.
   - **Ubuntu output:** Enabled and started automatically right after install.

3. **Enabling and Starting the Service:**

   ```bash
   sudo systemctl enable nginx
   sudo systemctl start nginx
   ```

   Verification: `systemctl status nginx` now shows `Active: active (running)` and `Enabled`.

4. **Stop, Restart, Reload:**

   ```bash
   sudo systemctl stop nginx       # stop the service
   sudo systemctl restart nginx    # stop and start (brief downtime)
   sudo systemctl reload nginx     # apply config changes without dropping connections (zero downtime)
   ```

---

## 2. Viewing Logs with `journalctl`

Logs are viewed via `journalctl` instead of flat text files. Two flags make this genuinely useful for troubleshooting: **`-p`** (priority/severity) and **`--since`** (time range).

### Basic Usage

```bash
journalctl -u nginx          # full log history for the service
journalctl -u nginx -f       # live tail of new log entries
```

### Filtering by Severity (`-p`)

Systemd log severity levels, from most to least critical:

| Level     | Meaning                   |
| --------- | ------------------------- |
| `emerg`   | System is unusable        |
| `alert`   | Immediate action required |
| `crit`    | Critical condition        |
| `err`     | Error                     |
| `warning` | Warning                   |
| `notice`  | Normal but significant    |
| `info`    | Informational             |
| `debug`   | Debug-level detail        |

`-p` filters to a level **and everything more severe than it**:

```bash
journalctl -u nginx -p err
```

Shows `err`, `crit`, `alert`, and `emerg` entries — but not `warning` or below. Cuts out routine noise and surfaces only what's worth looking at.

### Filtering by Time (`--since`, `--until`)

```bash
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2026-06-22 14:00:00" --until "2026-06-22 15:00:00"
```

`--since` accepts both relative ("1 hour ago", "yesterday") and absolute timestamps.

### Combining Both — A Real Troubleshooting Scenario

Nginx is reported as having problems, and the goal is "what went wrong in the last hour":

```bash
journalctl -u nginx -p err --since "1 hour ago"
```

This reads as: _"show me only error-level-or-worse logs for Nginx from the last hour"_ — instead of scrolling through a full, mostly irrelevant log history to manually spot the one line that matters.

---

## 📊 Command Reference

| Command                  | Purpose                                           | Example                           | Notes                                                          |
| ------------------------ | ------------------------------------------------- | --------------------------------- | -------------------------------------------------------------- |
| **`systemctl start`**    | Starts the service now.                           | `sudo systemctl start nginx`      | Does not persist across reboots on its own.                    |
| **`systemctl enable`**   | Sets the service to start on boot.                | `sudo systemctl enable nginx`     | Persistence — separate from `start`.                           |
| **`systemctl stop`**     | Stops the running service.                        | `sudo systemctl stop nginx`       |                                                                |
| **`systemctl restart`**  | Stops and starts the service (brief downtime).    | `sudo systemctl restart nginx`    |                                                                |
| **`systemctl reload`**   | Reloads config without downtime.                  | `sudo systemctl reload nginx`     | Not all services support this.                                 |
| **`journalctl -u`**      | Shows logs for a specific unit.                   | `journalctl -u nginx`             |                                                                |
| **`journalctl -p`**      | Filters logs by severity level (and more severe). | `journalctl -u nginx -p err`      | Levels: emerg, alert, crit, err, warning, notice, info, debug. |
| **`journalctl --since`** | Filters logs by time range.                       | `journalctl --since "1 hour ago"` | Accepts relative or absolute timestamps.                       |
| **`journalctl -f`**      | Live-follows new log entries.                     | `journalctl -u nginx -f`          |                                                                |

---

ℹ️ _All commands tested locally._
