# 🐧 Core Linux Commands & Text Processing

This document contains notes, command variations (`--help` discoveries), and observations gathered during Day 3 core Linux administration tasks.

---

## 1. System Identity: `hostname` vs `hostnamectl`

During environment analysis, a significant behavioral difference was observed between Ubuntu and Rocky Linux environments regarding system identification.

| Attribute        | Legacy `hostname`                                                                                      | Modern `hostnamectl`                                                                              |
| :--------------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------ |
| **Architecture** | Reads/sets volatile runtime flags in the kernel.                                                       | Integrated deeply into the modern `systemd` ecosystem.                                            |
| **Persistence**  | Changes are non-persistent and revert after a reboot unless configuration files are manually modified. | Persistently binds static hostnames directly to system configuration layers instantly.            |
| **Output Scope** | Returns only the plain machine name.                                                                   | Returns full system info including OS details, Kernel version, Architecture, and Hardware Vendor. |

### 🔍 Observation (Rocky Linux Default)

When running `hostname` on Rocky Linux 9.8, the shell returned `.localdomain` (e.g., `localhost.localdomain`). This is a fundamental RHEL-ecosystem design pattern where enterprise servers expect a **Fully Qualified Domain Name (FQDN)** layout by default, unlike Ubuntu which defaults to shorthand local naming structures.

### 🛠️ Practical Flag Variations (`--help` Discoveries)

- `hostname -I`: Dynamically captures all active IPv4/IPv6 network interface addresses assigned to the host (essential for automation routing).
- `hostnamectl set-hostname <name>`: Persistently updates the server's identity across all system configurations without requiring manual file text editing.

---

## 2. Linux Text Processing: Stream Piping with `grep`, `cut`, and `awk`

Instead of processing raw data dumps (e.g., viewing entire system metadata files), filtering clean output is done via standard streams (`stdin`, `stdout`).

### 📦 The Pipeline Blueprint

```bash
cat /etc/os-release | grep "PRETTY_NAME" | cut -d '=' -f 2 | tr -d '"'

```

1. **`cat`**: Reads the contents of the os-release file.
2. **`grep`**: Acts as a precise filter, isolating the specific string segment matching the query keyword.
3. **`cut -d '=' -f 2`**: Splits the isolated text line down into columns using the delimiter (`-d`) sign `=`, extracting the second field (`-f`).
4. **`tr -d '"'`**: Scrubs the output clean by deleting unnecessary quotation metadata.

### 🦅 The Power of `awk` (Column-Oriented Parsing)

While `grep` isolates rows and `cut` trims characters, `awk` processes lines as structural datasets broken down into indexed vertical columns (`$1`, `$2`, `$3`...).

`awk` was used to extract disk usage cleanly:

```bash
df -h / | awk 'NR==2 {print "Total: " $2 " | Used: " $3 " | Free: " $4}'

```

- **`NR==2`**: Directs `awk` to ignore the top header columns and jump straight to row index number 2 containing live data.
- **Index Selectors**: Targets vertical indices dynamically regardless of variable spaces ($2 = Total Capacity, $5 = Utilization %, $4 = Available Buffer Space).

---

## 3. `df` vs `du`

Both are used daily to catch low disk space before it causes problems.

- **`df -h` (Disk Free):** Scans mounted block filesystems globally, translating raw bytes into human-readable notation (G, M). Used for quick overviews.
- **`du -sh <path>` (Disk Usage):** Recursively traverses specific local directory nodes (e.g., `/var/log`) to compile precise space allocation metrics. Used to find what's taking up space (logs, caches, etc.).

---

## 📊 Command Reference

### 1. Core Commands

| Command           | Core Purpose                                                                            | Practical Example     | Flag / Option             | Flag Function                                                                          |
| :---------------- | :-------------------------------------------------------------------------------------- | :-------------------- | :------------------------ | :------------------------------------------------------------------------------------- |
| **`hostname`**    | Displays or temporarily modifies the system's network name.                             | `hostname`            | **`-I`** (Capital i)      | Lists all active **IP addresses** assigned to the host side-by-side.                   |
|                   |                                                                                         |                       | **`-f`**                  | Displays the **FQDN** (Fully Qualified Domain Name) of the server.                     |
|                   |                                                                                         |                       | **`-s`**                  | Displays the short hostname only (the segment before the first dot).                   |
| **`hostnamectl`** | Persistently manages system identity across modern `systemd` distributions.             | `hostnamectl`         | **`status`**              | Default subcommand; prints OS, Kernel, Architecture, and hardware specs.               |
|                   |                                                                                         |                       | **`set-hostname <name>`** | Commits the new hostname directly to system files **persistently**.                    |
| **`timedatectl`** | Manages system clock, local timezones, and NTP network synchronization status.          | `timedatectl`         | **`list-timezones`**      | Dumps a comprehensive list of all valid global timezones.                              |
|                   |                                                                                         |                       | **`set-timezone <zone>`** | Synchronizes the server clock to a target zone persistently (e.g., `Europe/Istanbul`). |
|                   |                                                                                         |                       | **`set-ntp true`**        | Enables automatic time synchronization via network atom clocks.                        |
| **`uname`**       | Extracts low-level technical metadata about the Linux kernel and hardware architecture. | `uname`               | **`-a`** (All)            | Summarizes all available system and kernel attributes in a single line.                |
|                   |                                                                                         |                       | **`-r`** (Release)        | Extracts the exact **Kernel release version** (critical for docker/driver updates).    |
|                   |                                                                                         |                       | **`-m`** (Machine)        | Returns the underlying hardware architecture (e.g., `x86_64` or `arm64`).              |
| **`cat`**         | Standard utility used to read, concatenate, and stream file contents to stdout.         | `cat /etc/os-release` | **`-n`**                  | Prepends **line numbers** to all output rows when printing file data.                  |

---

### 2. Storage & Stream Processing Tools

| Tool       | Core Purpose                                                                              | Practical Example    | Flag / Option      | Flag Function                                                                               |
| :--------- | :---------------------------------------------------------------------------------------- | :------------------- | :----------------- | :------------------------------------------------------------------------------------------ |
| **`df`**   | Reports filesystem storage space utilization, free blocks, and global capacities.         | `df -h /`            | **`-h`** (Human)   | Converts raw blocks into **Human-Readable** notation (Megabytes/Gigabytes).                 |
|            |                                                                                           |                      | **`-t <type>`**    | Filters the layout to display only specified filesystem types (e.g., `ext4`, `xfs`).        |
|            |                                                                                           |                      | **`--total`**      | Appends a summary row displaying total aggregated metrics at the bottom.                    |
| **`du`**   | Recursively measures estimated disk space allocation of specific directories or files.    | `du -sh /var/log`    | **`-s`** (Summary) | Suppresses subdirectory cascades, returning only the **total aggregated size**.             |
|            |                                                                                           |                      | **`-h`** (Human)   | Formats directory capacities in human-readable notation (`M` or `G`).                       |
| **`grep`** | Parses inputs line-by-line to isolate streams matching a targeted text pattern.           | `grep "PRETTY_NAME"` | **`-i`**           | Ignores case sensitivity during pattern matching (e.g., parses both `ubuntu` and `Ubuntu`). |
|            |                                                                                           |                      | **`-v`**           | Inverts the filter; returns lines that **do not** match the targeted string.                |
| **`cut`**  | Slices structured text rows horizontally based on specified byte positions or characters. | `cut -d '=' -f 2`    | **`-d '<char>'`**  | Sets the custom **delimiter** symbol (e.g., `=` or `,`) used to split the row.              |
|            |                                                                                           |                      | **`-f <num>`**     | Selects the precise **field index number** to extract from the segmented line.              |
| **`awk`**  | Advanced text pattern scanning and processing language built for columnized layouts.      | `awk '{print $1}'`   | **`NR==<num>`**    | Restricts actions to a specific **Number of Record** row index (e.g., `NR==2`).             |
|            |                                                                                           |                      | **`$1, $2...`**    | Index variables representing vertical data columns parsed by empty spaces.                  |
| **`tr`**   | Specialized character translation filter used to map, substitute, or purge string tokens. | `tr -d '"'`          | **`-d`** (Delete)  | Explicitly **deletes** the targeted tokens (e.g., strips away quotation marks).             |

---

ℹ️ _All commands verified on both Ubuntu and Rocky Linux._
