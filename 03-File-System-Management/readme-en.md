# 📁 Linux File System Management & Storage Diagnostics

This document covers practical Linux storage operations, file system navigation, pipeline sorting, and automated space auditing workflows.

---

## 1. Creating a 10 GB Test File

A 10 GB file was generated to simulate low disk space conditions.

### 🛠️ Steps

```bash
mkdir -p /tmp/disk-test && cd /tmp/disk-test
dd if=/dev/zero of=test_file.img bs=1G count=10
```

### 🔍 Why `dd` Instead of `fallocate`?

The two tools handle disk space very differently:

- **`dd`**: Streams data from `/dev/zero` and actually writes it to disk. The file genuinely occupies disk space and shows up correctly in `du`.
- **`fallocate`**: Reserves blocks instantly without any physical disk I/O — it marks the space as used without writing anything to it. Under some auditing configurations, `du` may report the real block size as zero (`0`) because no data has actually been pushed to disk yet.

**When to use which:**

- **`dd`** → when you need to test what actually happens when a file occupies real disk space. Slower, because it's actually writing.
- **`fallocate`** → when you need to reserve space quickly without writing anything to it. During LVM testing, the VM froze because `dd` was filling the host's disk — switching to `fallocate` fixed that (see 11-LVM-Management).

---

## 2. Finding the 10 Largest Files

Useful when a server is running low on disk space and you need to find what's consuming it.

### 📦 Command

```bash
sudo find / -type f -exec du -ah {} + 2>/dev/null | sort -rh | head -n 10
```

### Pipeline Breakdown

1. **`find / -type f`** — recursively scans from the root directory, matching only regular files.
2. **`-exec du -ah {} +`** — passes each found file to `du`, showing its size in human-readable format.
3. **`2>/dev/null`** — discards permission errors to keep the output clean.
4. **`| sort -rh`** — sorts numerically from largest to smallest.
5. **`| head -n 10`** — keeps only the top 10 results.

---

## 📊 Command Reference

| Command      | Purpose                                           | Example                   | Key Flags                                               |
| ------------ | ------------------------------------------------- | ------------------------- | ------------------------------------------------------- |
| **`pwd`**    | Prints the current working directory path.        | `pwd`                     | —                                                       |
| **`ls`**     | Lists directory contents.                         | `ls -la /var/log`         | `-la`: includes hidden files with permissions and sizes |
| **`cd`**     | Changes the active directory.                     | `cd /etc/systemd`         | `..`: parent directory, `~`: home directory             |
| **`mkdir`**  | Creates a new directory.                          | `mkdir -p /opt/app/logs`  | `-p`: creates nested parent directories automatically   |
| **`rm`**     | Permanently deletes files.                        | `rm -rf /tmp/cache`       | `-rf`: recursive and no confirmation — use carefully    |
| **`cp`**     | Copies files or directories.                      | `cp -r /src /dest`        | `-r`: copies directories recursively                    |
| **`mv`**     | Moves or renames a file.                          | `mv data.log archive.log` | —                                                       |
| **`find`**   | Searches the directory tree dynamically.          | `find . -name "*.conf"`   | `-name`: match by name, `-type`: match by type          |
| **`locate`** | Fast search using a prebuilt index database.      | `locate nginx.conf`       | Requires `updatedb` to refresh the index                |
| **`du`**     | Shows disk usage for files or directories.        | `du -sh /var`             | `-sh`: summary in human-readable format                 |
| **`df`**     | Shows disk space usage across mounted partitions. | `df -hT`                  | `-hT`: human-readable format + filesystem type          |

---

ℹ️ _All commands tested locally._
