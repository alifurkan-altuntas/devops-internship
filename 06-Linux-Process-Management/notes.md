# ⚙️ Linux Process Management & Signaling

This document covers process monitoring, resource usage, and signals implemented on a test environment.

---

## 1. Simulating and Killing a Runaway Process

Processes can sometimes consume excessive CPU or hang. This laboratory exercise simulates catching and terminating a rogue CPU-bound process using purely native tools.

### 🛠️ Steps

1. **Initiate a Controlled High-Load Background Process:**
   Started a background process that writes continuously to `/dev/null`:

```bash
   dd if=/dev/zero of=/dev/null &

```

2. **Dynamic Resource Tracing via Native Utilities (`top`):**
   `top` is used since it's available by default everywhere, unlike `htop`:

```bash
   top

```

_Observation:_ `dd` shows up using ~100% of a CPU core.

### 📊 `top` vs `htop`

Comparison of the two tools:

| Observability Metric        | (`top`)                                                         | (`htop`)                                                     |
| :-------------------------- | :-------------------------------------------------------------- | :----------------------------------------------------------- |
| **System Availability**     | Built-in everywhere by default.                                 | Needs to be installed separately (`apt`/`dnf install htop`). |
| **Visual Interface Layout** | Plain text, manual sort keys (`Shift+P` CPU, `Shift+M` Memory). | Color UI, mouse support, visual resource meters.             |
| **Process Tree Auditing**   | Flat list; no built-in parent/child view.                       | Built-in tree view (`F5`).                                   |
| **Operational Control**     | Requires typing the PID manually for signals.                   | Kill processes directly with `F9`.                           |

> **Note:** `htop` is more convenient, but `top` should still be learned since some locked-down servers won't have `htop` installed.

---

3. **Getting the PID:**
   `pidof` is cleaner than `ps aux | grep dd`:

```bash
   pidof dd

```

_Extracted Target Identity:_ `[Target_PID]`

4. **Force-Killing a Process (SIGKILL) (`kill -9`):**
   When polite lifecycle signals like `SIGTERM` (-15) are ignored by locked registers, an uncatchable, unignorable execution sweep is forced via `SIGKILL` (-9):

```bash
   kill -9 [Target_PID]

```

_Validation Loop:_ Re-running `top` or `pidof dd` confirms the process is gone.

---

## 🏎️ Process Prioritization Management (`nice` & `renice`)

Operating system kernels schedule processor clock cycles based on a relative priority metric called "Nice values," scaling across a strict boundary grid from `-20` (highest execution priority/least nice) to `19` (lowest execution priority/most cooperative).

### 🛠️ Examples

1. **Deploying a Cooperative Resource Boundary (`nice`):**
   For background jobs (e.g. backups) that shouldn't compete with active services:

```bash
   nice -n 19 ./report.sh &

```

2. **Dynamic Live Priority Adjustments (`renice`):**
   To adjust priority of an already-running process without restarting it:

```bash
   sudo renice -n 15 -p 4821

```

_System Response:_ `4821 (process ID) old priority 0, new priority 15`

---

## 📊 Process Administration Command Matrix

| Command      | Operational Purpose                                                                | Production Practical Example | Essential Options    | Option Mechanics / Output                                                                 |
| ------------ | ---------------------------------------------------------------------------------- | ---------------------------- | -------------------- | ----------------------------------------------------------------------------------------- |
| **`top`**    | Dynamic, native real-time system resource allocation tracking.                     | `top`                        | _Built-in_           | Standard monitoring core available across all minimalist distributions natively.          |
| **`pidof`**  | Captures the absolute PID array matching an exact system binary name.              | `pidof nginx`                | _None_               | Purges standard out noise, returning raw index integers directly.                         |
| **`kill`**   | Transmits specific architectural signal tokens to target process IDs.              | `kill -9 1432`               | **`-9`** / **`-15`** | `-9` triggers SIGKILL (immediate execution halt); `-15` triggers SIGTERM (graceful exit). |
| **`pkill`**  | Sweeps and drops target execution lines utilizing exact string matching.           | `pkill dd`                   | _None_               | Evaluates application processes by string name descriptors instead of integers.           |
| **`nice`**   | Starts a new process with a custom CPU priority.                                   | `nice -n 10 ./task.sh`       | **`-n`**             | Biases the thread weight across the kernel scheduling engine layout.                      |
| **`renice`** | Modifies the execution priority weights of an already running process dynamically. | `renice -n -5 -p 221`        | **`-n`** / **`-p`**  | Adjusts the active runtime metrics on the fly using explicit target PID filters.          |

---

ℹ️ _All commands tested locally._
