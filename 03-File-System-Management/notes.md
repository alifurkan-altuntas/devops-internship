# 📁 Linux File System Management & Storage Diagnostics

This document covers practical Linux storage operations, file system navigation, pipeline sorting, and automated space auditing workflows.

---

## 1. Creating a 10 GB Test File

To simulate low disk space, a 10 GB file was generated.

### 🛠️ Steps

```bash
mkdir -p /tmp/disk-test && cd /tmp/disk-test
dd if=/dev/zero of=test_file.img bs=1G count=10

```

### 🔍 Why `dd` instead of `fallocate`?

`fallocate` was avoided in favor of `dd` because of how each allocates disk space:

- **`fallocate` Mechanism:** Instantly modifies metadata pointers to reserve raw file system blocks without physical disk I/O (creating sparse spaces). Under specific auditing configurations, utilities like `du` may interpret the real block size as zero (`0`) because live binary frames have not been pushed to storage sectors yet.
- **`dd`:** Writes real data by streaming from `/dev/zero`, so the file actually occupies disk space and shows up correctly in `du`.

---

## 2. Finding the 10 Largest Files

Useful when a server runs low on disk space and you need to find what's eating it up.

### 📦 Command

```bash
sudo find / -type f -exec du -ah {} + 2>/dev/null | sort -rh | head -n 10

```

### 🦅 Pipeline Breakdown

Breakdown:

1. **`find / -type f`:** Recursively scans starting from the root directory (`/`) to catch normal system data files, filtering out structural directory headers.
2. **`-exec du -ah {} +`:** Passes each found file to the **`du` (Disk Usage)** command, evaluating exact block consumption footprints in human-readable (`h`) formats.
3. **`2>/dev/null`:** Discards permission errors by redirecting them to `/dev/null`.
4. **`| sort -rh`:** Sorts the output numerically, largest first.
5. **`| head -n 10`:** Keeps only the top 10 results on stdout.

---

## 📊 Linux File System & Directory Command Matrix

| Command      | Purpose                                                                       | Example                   | Crucial Flag Variations   | Flag Mechanics                                                                                |
| ------------ | ----------------------------------------------------------------------------- | ------------------------- | ------------------------- | --------------------------------------------------------------------------------------------- |
| **`pwd`**    | Prints absolute path of current active working directory layer.               | `pwd`                     | _None_                    | —                                                                                             |
| **`ls`**     | Lists vertical contents of directory paths with underlying attributes.        | `ls -la /var/log`         | **`-la`**                 | Returns all hidden data structures (`a`) with complete permissions and size layout (`l`).     |
| **`cd`**     | Alters the active runtime path location of the terminal environment.          | `cd /etc/systemd`         | **`..`** / **`~`**        | Navigates one step upward (`..`) or shifts directly to user home home root (`~`).             |
| **`mkdir`**  | Instantiates a fresh directory structure inside the target destination path.  | `mkdir -p /opt/app/logs`  | **`-p`**                  | Automates nested parent link creation without throwing terminal crash states.                 |
| **`rm`**     | Purges target data pointers and files permanently from disk sectors.          | `rm -rf /tmp/cache`       | **`-rf`**                 | Forces recursive deletion (`r`) without confirmation (`f`) — be careful.                      |
| **`cp`**     | Duplicates file streams from structural source nodes to target paths.         | `cp -r /src /dest`        | **`-r`**                  | Enables recursive processing to replicate entire subdirectory configurations.                 |
| **`mv`**     | Shifts storage directory mappings or modifies local file name keys.           | `mv data.log archive.log` | _None_                    | Relocates nodes or executes instant target file renaming operations.                          |
| **`find`**   | Performs dynamic, live runtime directory searches across active sector trees. | `find . -name "*.conf"`   | **`-name`** / **`-type`** | Isolates searches based on exact string wildcards (`-name`) or file types (`-type`).          |
| **`locate`** | High-speed pattern indexing via structural db logs.                           | `locate nginx.conf`       | _Requires `updatedb_`     | Queries compiled storage indices instantly; requires manual database refreshes.               |
| **`du`**     | Compiles actual block metrics and file utilization sizes.                     | `du -sh /var`             | **`-sh`**                 | Summarizes (`s`) full directory paths into human-readable (`h`) megabyte/gigabyte text tiers. |
| **`df`**     | Quantifies global system volume availability and block statistics.            | `df -hT`                  | **`-hT`**                 | Renders human notation (`h`) while displaying the active filesystem kernel layout (`T`).      |

---

ℹ️ _All commands tested locally._
