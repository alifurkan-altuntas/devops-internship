# 🏗️ Linux Logical Volume Management (LVM)

This document covers LVM basics: physical volumes, volume groups, logical volumes, online resizing, and a real incident caused by running out of host disk space.

---

## 1. LVM Basics & Live Scaling

Traditional partitioning (MBR/GPT) is rigid — resizing usually requires downtime. LVM avoids this by adding a flexible abstraction layer with three components:

### 🏗️ LVM Components

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

````

2. **System Behavior:** The guest kernel logged a watchdog error:
```text
kernel:watchdog: BUG: soft lockup - CPU#1 stuck for 33s! [vmtoolsd:726]

````

3. **Root Cause:** The VM uses a thin-provisioned virtual disk on the host. Writing 50GB of zeros caused the VM's disk file to actually grow by 50GB on the host. This filled the host's disk completely, which caused the hypervisor to stall the VM's I/O and network, freezing the guest.

### 🛠️ Fix

- **Ran `vagrant halt`** from the host to force-stop the frozen VM and free up disk space.
- **Used `fallocate` Instead:** `fallocate` reserves space instantly without writing real data, avoiding this issue:

```bash
sudo fallocate -l 500M /tmp/lvm_disk1.img

```

---

## 🛠️ LVM Setup

Using smaller MB-sized files this time to avoid repeating the same issue.

1. **Creating Loop Devices:**

```bash
sudo fallocate -l 500M /tmp/lvm_disk1.img
sudo fallocate -l 200M /tmp/lvm_disk2.img
sudo losetup -fP /tmp/lvm_disk1.img
sudo losetup -fP /tmp/lvm_disk2.img

```

2. **Setting Up PV, VG, and LV:**

```bash
# Create the physical volume
sudo pvcreate /dev/loop0

# Create the volume group
sudo vgcreate test_pool /dev/loop0

# Create a logical volume using all available space
sudo lvcreate -l 100%FREE -n test_data test_pool

```

3. **Formatting and Mounting:**

```bash
sudo mkfs.ext4 /dev/test_pool/test_data
sudo mkdir -p /mnt/lvm_test
sudo mount /dev/test_pool/test_data /mnt/lvm_test

```

4. **Expanding Storage Without Downtime (+200M):**
   To add more space without unmounting:

```bash
# Create a PV from the new loop device
sudo pvcreate /dev/loop1

# Add it to the volume group
sudo vgextend test_pool /dev/loop1

# Extend the logical volume
sudo lvextend -l +100%FREE /dev/test_pool/test_data

# Resize the filesystem to match
sudo resize2fs /dev/test_pool/test_data

```

---

## 📊 Command Reference

| Utility Command | Operational Scope | Practical Implementation Example             | Core Engineering Functionality               |
| --------------- | ----------------- | -------------------------------------------- | -------------------------------------------- |
| **`pvcreate`**  | Physical Layer    | `sudo pvcreate /dev/loop0`                   | Initializes a block device for use with LVM. |
| **`vgcreate`**  | Pooling Layer     | `sudo vgcreate pool_name /dev/loop0`         | Combines PVs into a volume group.            |
| **`lvcreate`**  | Abstraction Layer | `sudo lvcreate -n data_vol -L 10G pool_name` | Creates a logical volume from the pool.      |
| **`lvextend`**  | Scaling Layer     | `sudo lvextend -l +100%FREE /dev/pool/vol`   | Grows a logical volume.                      |
| **`resize2fs`** | Filesystem Layer  | `sudo resize2fs /dev/pool/vol`               | Resizes the filesystem to use the new space. |

---

ℹ️ _All commands tested locally._
