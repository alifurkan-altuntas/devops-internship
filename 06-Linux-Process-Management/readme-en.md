# ⚙️ Linux Process Management & Signaling

This document covers process monitoring, resource usage, and signals implemented on a test environment.

---

## 1. Simulating and Killing a Runaway Process

Processes can sometimes consume excessive CPU or hang. This lab simulates catching and terminating a rogue CPU-bound process using purely native tools.

### 🛠️ Steps

1. **Started a high-load background process:**
   A background process writing continuously to `/dev/null`:

   ```bash
   dd if=/dev/zero of=/dev/null &
   ```

2. **Real-time resource monitoring with `top`:**
   `top` is used since it's available by default everywhere, unlike `htop`:

   ```bash
   top
   ```

   Observation: `dd` shows up using ~100% of a CPU core.

### 📊 `top` vs `htop`

| Feature          | `top`                                                           | `htop`                                                       |
| ---------------- | --------------------------------------------------------------- | ------------------------------------------------------------ |
| **Availability** | Built-in everywhere by default.                                 | Needs to be installed separately (`apt`/`dnf install htop`). |
| **Interface**    | Plain text, manual sort keys (`Shift+P` CPU, `Shift+M` Memory). | Color UI, mouse support, visual resource meters.             |
| **Process Tree** | Flat list; no built-in parent/child view.                       | Built-in tree view (`F5`).                                   |
| **Control**      | Requires typing the PID manually for signals.                   | Kill processes directly with `F9`.                           |

> **Note:** `htop` is more convenient, but `top` should still be learned since some locked-down servers won't have `htop` installed.

---

3. **Getting the PID:**
   Cleaner than `ps aux | grep dd`:

   ```bash
   pidof dd
   ```

4. **Force-killing the process (SIGKILL) (`kill -9`):**
   When graceful signals like `SIGTERM` (-15) are ignored, `SIGKILL` (-9) forces an immediate stop:

   ```bash
   kill -9 [Target_PID]
   ```

   Validation: Re-running `top` or `pidof dd` confirms the process is gone.

---

## 🏎️ Process Prioritization (`nice` & `renice`)

The OS kernel schedules CPU cycles based on a relative priority metric called "Nice values," ranging from `-20` (highest priority) to `19` (lowest priority).

### 🛠️ Examples

1. **Starting a low-priority process (`nice`):**
   For background jobs (e.g. backups) that shouldn't compete with active services:

   ```bash
   nice -n 19 ./report.sh &
   ```

2. **Adjusting priority of a running process (`renice`):**
   To change priority without restarting the process:

   ```bash
   sudo renice -n 15 -p 4821
   ```

   System response: `4821 (process ID) old priority 0, new priority 15`

---

## 📊 Command Reference

| Command      | Purpose                                          | Example                | Key Options          | Notes                                                            |
| ------------ | ------------------------------------------------ | ---------------------- | -------------------- | ---------------------------------------------------------------- |
| **`top`**    | Real-time system resource monitoring.            | `top`                  | Built-in             | Standard monitoring available across all distributions natively. |
| **`pidof`**  | Returns PIDs matching an exact binary name.      | `pidof nginx`          | —                    | Clean output, returns raw PID integers directly.                 |
| **`kill`**   | Sends a signal to a target process ID.           | `kill -9 1432`         | **`-9`** / **`-15`** | `-9` SIGKILL (immediate stop); `-15` SIGTERM (graceful exit).    |
| **`pkill`**  | Terminates processes by name match.              | `pkill dd`             | —                    | Finds and kills processes by name instead of PID.                |
| **`nice`**   | Starts a new process with a custom CPU priority. | `nice -n 10 ./task.sh` | **`-n`**             | Biases thread weight in the kernel scheduling engine.            |
| **`renice`** | Modifies priority of an already-running process. | `renice -n -5 -p 221`  | **`-n`** / **`-p`**  | Adjusts priority on the fly using explicit PID.                  |

---

ℹ️ _All commands tested locally._
