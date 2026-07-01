# 💾 Linux Storage & File System Management

This document covers creating a loop device, partitioning it, formatting it, and mounting it persistently via fstab.

---

## 1. Creating and Mounting a Virtual Disk

Adding storage to a system often means simulating a new disk before attaching real hardware. This lab uses a loop device to simulate adding and formatting a new disk.

### 🛠️ Steps

1. **Creating a Loop Device:**
   Created a 1GB image file and mounted it as a loop device:

   ```bash
   sudo dd if=/dev/zero of=/tmp/test_disk.img bs=1M count=1024
   sudo losetup -fP /tmp/test_disk.img
   ```

   `lsblk` confirms a new 1G unpartitioned device at `/dev/loop0`.

2. **Partitioning the Disk:**

   ```bash
   sudo fdisk /dev/loop0
   ```

   `fdisk` opens an **interactive menu** — nothing is written to disk until explicitly confirmed. The typical flow to create one partition using all available space:

   | Key                     | Meaning                                                                                   |
   | ----------------------- | ----------------------------------------------------------------------------------------- |
   | `n`                     | **n**ew — create a new partition                                                          |
   | _(Enter, Enter, Enter)_ | Accept defaults for partition number, first sector, and last sector (uses all free space) |
   | `w`                     | **w**rite — commit the changes to disk and exit                                           |

   ```text
   Command (m for help): n
   Partition type: p (primary)
   Partition number: [Enter]
   First sector: [Enter]
   Last sector: [Enter]   ← uses the rest of the disk
   Command (m for help): w
   ```

   **Important:** until `w` is pressed, nothing is actually written. Exiting with `q` (quit) instead discards everything safely.

   This creates a primary partition `/dev/loop0p1` with a DOS partition table.

3. **Creating a Filesystem:**
   Formatted the partition as `ext4`:

   ```bash
   sudo mkfs.ext4 /dev/loop0p1
   ```

4. **Mounting the Partition:**
   Created a mount point and mounted the partition:

   ```bash
   sudo mkdir -p /mnt/test_storage
   sudo mount /dev/loop0p1 /mnt/test_storage
   ```

5. **Making the Mount Persistent via UUID:**
   Device paths like `/dev/loop0p1` can change between reboots, so UUID is used instead in `/etc/fstab`:

   ```bash
   sudo blkid /dev/loop0p1
   sudo vim /etc/fstab
   ```

   **`fstab` entry:**

   ```text
   UUID=37675d89-63ea-4e43-ab1b-dc5906d10ee7  /mnt/test_storage  ext4  defaults  0  2
   ```

6. **Testing the fstab Entry Safely:**

   ```bash
   sudo umount /mnt/test_storage
   sudo mount -a
   ```

   ### 🔍 Why This Step Actually Matters

   A typo or wrong UUID in `/etc/fstab` won't show up immediately — it only causes a problem **the next time the system boots**, when the kernel tries to mount everything in fstab automatically. A broken entry at that point can drop the system into **emergency mode**, requiring manual intervention with the root password through a recovery console.

   `mount -a` re-reads `/etc/fstab` and mounts anything not already mounted — right now, while the system is still running normally. If there's a mistake, it shows an error immediately and it can be fixed on the spot. If it runs clean, the entry is safe to survive a reboot. This avoids the classic "rebooted the server and now it won't come back up" scenario entirely.

---

## 🔬 Understanding `/etc/fstab`

Each line has 6 fields:

- **Field 1 (Device Identifier):** `UUID=37675d89-...` — identifies the partition by its unique ID.
- **Field 2 (Mount Point):** `/mnt/test_storage` — where the partition gets mounted.
- **Field 3 (Filesystem Type):** `ext4`
- **Field 4 (Mount Parameters):** `defaults` — standard mount options (read/write, auto-mount on boot, etc.)
- **Field 5 (Dump Backup):** `0` — disables the legacy `dump` backup utility for this partition.
- **Field 6 (FSCK Sequence):** `2` — root (`/`) is checked first (`1`), this partition after (`2`).

---

## 📊 Command Reference

| Utility                | Scope            | Example                       | Purpose                                                                                                      |
| ---------------------- | ---------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **`lsblk`**            | Block Layer      | `lsblk`                       | Shows block devices in a tree view.                                                                          |
| **`fdisk`**            | Partition Layer  | `sudo fdisk /dev/loop0`       | Interactive partition editor — nothing is written until `w` is pressed.                                      |
| **`mkfs.ext4`**        | Filesystem Layer | `sudo mkfs.ext4 /dev/loop0p1` | Formats a partition with the ext4 filesystem.                                                                |
| **`blkid`**            | Metadata Layer   | `sudo blkid /dev/loop0p1`     | Shows partition UUID and filesystem type.                                                                    |
| **`mount` / `umount`** | Runtime          | `sudo mount -a`               | Mounts or unmounts filesystems; `-a` mounts everything in fstab and is the safe way to test before a reboot. |
| **`df`**               | Metric Tracking  | `df -h`                       | Shows disk usage and mount points.                                                                           |

---

ℹ️ _All commands tested locally._
