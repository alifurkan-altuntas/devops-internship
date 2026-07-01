# 🏗️ Linux Logical Volume Management (LVM)

This document covers LVM basics: physical volumes, volume groups, logical volumes, online resizing, and a real incident caused by running out of host disk space.

---

## 1. Why LVM Instead of Plain Partitions

### The Problem With Traditional Partitioning

With a regular partition (e.g. via `fdisk`), the size is essentially fixed at creation time. If a partition runs out of space later — a growing database, accumulating logs — resizing it is difficult, often risky, and frequently requires downtime or rebuilding the disk layout from scratch.

### How LVM Solves This

LVM works like resource pooling — conceptually similar to how a hypervisor pools physical RAM/CPU and hands out slices to individual VMs. The physical disk space goes into a shared pool first, and usable volumes are carved out of that pool as needed:

```
Physical Disk(s) → Volume Group (the pool) → Logical Volume(s) (slices handed out)
```

As long as the pool still has free space, an existing Logical Volume can be grown **live, with no downtime** — because the extra space was already sitting in the pool, just not yet assigned to that volume.

### Concrete Example

Imagine a 50GB disk where only 20GB is needed right now:

```bash
# Add the full 50GB disk to the pool
sudo pvcreate /dev/sdb
sudo vgcreate disk_pool /dev/sdb

# Carve out only 20GB to actually use
sudo lvcreate -L 20G -n data_volume disk_pool
sudo mkfs.ext4 /dev/disk_pool/data_volume
sudo mount /dev/disk_pool/data_volume /mnt/data

# 30GB remains free in the pool. Later, if 20GB isn't enough:
sudo lvextend -l +10G /dev/disk_pool/data_volume
sudo resize2fs /dev/disk_pool/data_volume
```

No unmounting, no rebuilding, no downtime — the volume just grows into space already reserved in the pool.

---

## 2. LVM Components

- **Physical Volume (PV):** Turns a raw block device (e.g. `/dev/loop0`) into something LVM can use, via `pvcreate`.
- **Volume Group (VG):** Combines one or more PVs into a single storage pool, via `vgcreate`.
- **Logical Volume (LV):** Carves out a usable virtual disk from the pool, via `lvcreate`.

---

## 🚨 Incident: Host Ran Out of Disk Space

While testing with large disk writes, the VM froze completely.

### 📝 Incident Diagnostics

1. **Trigger Action:** Tried to create a 50GB test file:

   ```bash
   sudo dd if=/dev/zero of=/tmp/lvm_disk1.img bs=1M count=51200
   ```

2. **System Behavior:** The guest kernel logged a watchdog error:

   ```text
   kernel:watchdog: BUG: soft lockup - CPU#1 stuck for 33s! [vmtoolsd:726]
   ```

3. **Root Cause:** The VMs were installed on the same local disk as the host machine. The VM used a thin-provisioned virtual disk — writing 50GB of zeros caused the VM's disk file to actually grow by 50GB on the host. This filled the host's disk completely, causing the hypervisor to stall the VM's I/O and network, freezing the guest.

### 🛠️ Fix

- **Ran `vagrant halt`** from the host to force-stop the frozen VM and free up disk space.
- **Used `fallocate` instead:** reserves space instantly without writing real data, avoiding this issue:
  ```bash
  sudo fallocate -l 500M /tmp/lvm_disk1.img
  ```

---

## 3. LVM Setup (Smaller Scale, Same Concepts)

Using smaller MB-sized files this time to avoid repeating the disk-space incident.

1. **Creating Loop Devices:**

   ```bash
   sudo fallocate -l 500M /tmp/lvm_disk1.img
   sudo fallocate -l 200M /tmp/lvm_disk2.img
   sudo losetup -fP /tmp/lvm_disk1.img
   sudo losetup -fP /tmp/lvm_disk2.img
   ```

2. **Setting Up PV, VG, and LV:**

   ```bash
   sudo pvcreate /dev/loop0
   sudo vgcreate test_pool /dev/loop0
   sudo lvcreate -l 100%FREE -n test_data test_pool
   ```

3. **Formatting and Mounting:**

   ```bash
   sudo mkfs.ext4 /dev/test_pool/test_data
   sudo mkdir -p /mnt/lvm_test
   sudo mount /dev/test_pool/test_data /mnt/lvm_test
   ```

4. **Expanding Storage Without Downtime (+200M):**
   ```bash
   sudo pvcreate /dev/loop1                                  # turn the new loop device into a PV
   sudo vgextend test_pool /dev/loop1                        # add it to the existing pool
   sudo lvextend -l +100%FREE /dev/test_pool/test_data       # grow the logical volume
   sudo resize2fs /dev/test_pool/test_data                   # resize the filesystem to match
   ```

---

## 📊 Command Reference

| Command         | Layer      | Example                                      | Purpose                                              |
| --------------- | ---------- | -------------------------------------------- | ---------------------------------------------------- |
| **`pvcreate`**  | Physical   | `sudo pvcreate /dev/loop0`                   | Initializes a block device for use with LVM.         |
| **`vgcreate`**  | Pooling    | `sudo vgcreate pool_name /dev/loop0`         | Combines PVs into a volume group (the pool).         |
| **`lvcreate`**  | Logical    | `sudo lvcreate -n data_vol -L 10G pool_name` | Creates a usable volume from the pool.               |
| **`vgextend`**  | Pooling    | `sudo vgextend pool_name /dev/loop1`         | Adds more physical space into an existing pool.      |
| **`lvextend`**  | Logical    | `sudo lvextend -l +100%FREE /dev/pool/vol`   | Grows a logical volume using free space in the pool. |
| **`resize2fs`** | Filesystem | `sudo resize2fs /dev/pool/vol`               | Resizes the filesystem to match the new volume size. |

---

ℹ️ _All commands tested locally._
