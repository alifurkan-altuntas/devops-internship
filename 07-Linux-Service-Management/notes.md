# 🏗️ Linux Service & Log Management (`systemd` Architecture)

This document covers systemd service management, journalctl, and distro defaults across major Linux distribution families.

---

## 1. Service Lifecycle & Log Auditing

Apps, web servers, and databases typically run as background daemons under `systemd` (PID 1). This lab covers provisioning Nginx and manipulating its internal states cleanly.

### 🛠️ Steps

1. **Installing Nginx (Different Package Managers):**
   Depending on the target operating system family, appropriate package managers must be utilized to resolve upstream dependencies:
   - **RHEL / Rocky Linux Architecture (Modern DNF Engine):**
     ```bash
     sudo dnf install nginx -y
     ```
   - **Debian / Ubuntu Architecture (Advanced APT Engine):**
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

- To fully stop and restart the process (Triggers a hard connection reset):

```bash
sudo systemctl restart nginx

```

- To inject configuration alterations dynamically without dropping active client connections or interrupting runtime listening sockets (Zero-Downtime Production standard):

```bash
sudo systemctl reload nginx

```

5. **Viewing Logs with (`journalctl`):**
   Logs are viewed via `journalctl` instead of flat text files:

- Full log history for the service:

```bash
journalctl -u nginx

```

- Live tail of new log entries:

```bash
journalctl -u nginx -f

```

---

## 📊 Observability & System Control Matrix

| Command                 | Operational Purpose                            | Production Practical Example   | Essential Sub-Options | Functional Mechanics / Output                                                       |
| ----------------------- | ---------------------------------------------- | ------------------------------ | --------------------- | ----------------------------------------------------------------------------------- |
| **`systemctl start`**   | Starts the service now.                        | `sudo systemctl start nginx`   | _None_                | Spawns background process loops immediately; does not persist across reboots.       |
| **`systemctl enable`**  | Sets the service to start on boot.             | `sudo systemctl enable nginx`  | _None_                | Automates service initialization on boot without manual administrator input.        |
| **`systemctl stop`**    | Stops the running service.                     | `sudo systemctl stop nginx`    | _None_                | Safely flushes running operations, releasing allocated network socket loops.        |
| **`systemctl restart`** | Stops and starts the service (brief downtime). | `sudo systemctl restart nginx` | _None_                | Clears leaky cache spaces but causes brief consumer connection drops.               |
| **`systemctl reload`**  | Reloads config without downtime.               | `sudo systemctl reload nginx`  | _None_                | Enforces hot-swapping parameters seamlessly with zero application downtime.         |
| **`journalctl -u`**     | Shows logs for a specific unit.                | `journalctl -u nginx`          | **`-f`**              | Appending `-f` locks the output into real-time follow mode for continuous auditing. |

---

ℹ️ _All commands tested locally._
