# 💾 Linux Storage & File System Management

This document covers creating a loop device, partitioning it, formatting it, and mounting it persistently via fstab.

---

## 1. Creating and Mounting a Virtual Disk

Adding storage to a system often means simulating a new disk before attaching real hardware. This lab uses a loop device to simulate adding and formatting a new disk.

### 🛠️ Steps

1. **Creating a Loop Device:**
   Created a 1GB image file and mounted it as a loop device:
   ```bash
   sudo dd if=/dev/zero of=/tmp/sahte_disk.img bs=1M count=1024
   sudo losetup -fP /tmp/sahte_disk.img
   ```

````

`lsblk` confirms a new 1G unpartitioned device at `/dev/loop0`.

2. **Partitioning the Disk:**
Partitioned the new device:
```bash
sudo fdisk /dev/loop0

````

- Created a primary partition `/dev/loop0p1` with a DOS partition table.

3. **Creating a Filesystem:**
   Formatted the partition as `ext4`:

```bash
sudo mkfs.ext4 /dev/loop0p1

```

4. **Mounting the Partition:**
   Created a mount point and mounted the partition:

```bash
sudo mkdir -p /mnt/kurumsal_depo
sudo mount /dev/loop0p1 /mnt/kurumsal_depo

```

5. **Making the Mount Persistent via UUID:**
   Device paths like `/dev/loop0p1` can change between reboots, so UUID is used instead in `/etc/fstab`. Got the UUID and added it to fstab:

```bash
sudo blkid /dev/loop0p1
sudo vim /etc/fstab

```

- **`fstab`entry:**

```text
UUID=37675d89-63ea-4e43-ab1b-dc5906d10ee7  /mnt/kurumsal_depo  ext4  defaults  0  2

```

6. **Testing the fstab Entry Safely:**
   To catch fstab errors before they cause a boot failure, unmounted and remounted using fstab:

```bash
sudo umount /mnt/kurumsal_depo
sudo mount -a

```

- If `mount -a` remounts it without errors, the fstab entry is correct.

---

## 🔬 Understanding (`/etc/fstab`)

Each line in `fstab` has 6 fields:

- **Field 1 (Device Identifier):** `UUID=37675d89-...` – Identifies the partition by its unique ID.
- **Field 2 (Mount Point Target):** `/mnt/kurumsal_depo` – Where the partition gets mounted.
- **Field 3 (Filesystem Type):** `ext4` – The filesystem type.
- **Field 4 (Mount Parameters):** `defaults` – Standard mount options (read/write, auto-mount on boot, etc.).
- **Field 5 (Dump Backup Flags):** `0` – Disables the legacy `dump` backup utility for this partition.
- **Field 6 (FSCK File System Check Sequence):** `2` – Sets fsck check order — root (`/`) is checked first (`1`), this partition after (`2`).

---

## 📊 Command Reference

| Utility                | Interface Scope | Sandbox Practical Execution | Architectural Purpose / Troubleshooting Utility |
| ---------------------- | --------------- | --------------------------- | ----------------------------------------------- |
| **`lsblk`**            | Block Layer     | `lsblk`                     | Shows block devices in a tree view.             |
| **`blkid`**            | Metadata Layer  | `sudo blkid /dev/loop0p1`   | Shows partition UUID and filesystem type.       |
| **`mount` / `umount`** | Runtime Linkage | `sudo mount -a`             | Mounts or unmounts filesystems.                 |
| **`df`**               | Metric Tracking | `df -h`                     | Shows disk usage and mount points.              |

---

ℹ️ _All commands tested locally._
