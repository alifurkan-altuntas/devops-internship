# 🔑 Linux Permissions & Security Hardening

This document covers file system authorization layers, ownership structures, custom identity maskings, and advanced security boundaries implemented on Virtual Private Servers (VPS).

---

## 1. Enterprise Task 1: Shared Secure Directory (Sticky Bit Architecture)

In collaborative enterprise environments, providing a shared folder with full write access (`777`) introduces a critical vulnerability: any user can cross-delete or alter files belonging to other operators. To mitigate these risks, a **Sticky Bit** boundary layer was successfully simulated.

### 🛠️ Step-by-Step Laboratory Deployment

1. **Created the Shared Infrastructure Node:**
```bash
   sudo mkdir /tmp/test
   sudo chmod 777 /tmp/test

```

2. **Injected the Special Sticky Bit Permission:**
To restrict cross-deletion rules while preserving global write capabilities, the dynamic directory mask was modified:

```bash
   sudo chmod +t /tmp/test

```

*Alternative absolute command layout:* `sudo chmod 1777 /tmp/test`

3. **Status Verification:**

```bash
   ls -ld /tmp/test

```

*Expected system flag output:* `drwxrwxrwt ... /tmp/test` (The trailing **`t`** token indicates the active Sticky Bit perimeter).

### 🔐 Sticky Bit Behavioral Notes

The Sticky Bit does **not** restrict file reading or modification permissions directly. Instead, it introduces a directory-level ownership boundary that controls file deletion and renaming operations.

Within a Sticky Bit protected directory:

- File owners may delete or rename their own files.
- The directory owner may manage files within the directory.
- Root retains full administrative control.
- Other users, even with write permissions on the directory, cannot delete or rename files owned by another user.

This mechanism is widely used on shared temporary storage locations such as `/tmp`, where all users require write access but cross-user file removal must be prevented.

### 🔒 Post-Mortem Verification Analytics

During functional runtime verification across distinct local profile entities:

* **Test Case A (Ownership Execution):** User `altun` initiates a target file `touch /tmp/test/test.txt`. The process finishes with exit code `0`.
* **Test Case B (Cross-Deletion Trap):** User `devopstester` attempts to sweep the file array via `rm /tmp/test/test.txt`.
* **System Defense Log Output:**

```text
  rm: cannot remove '/tmp/test/test.txt': Operation not permitted

```

The security policy effectively locks write streams down to file owners and root administrators only, successfully preventing unauthorized system asset destruction.

---

## 2. Enterprise Task 2: Ownership Migration & Group Alignment (`chown` & `chgrp`)

During infrastructure handovers, non-privileged users should not own configuration blocks, and files must be aligned with dedicated organizational groups to maintain strict access control boundaries.

### 🛠️ Execution & Verification Logs

1. **Reassigning Resource Ownership (`chown`):**
Migrated the owner link of an infrastructure asset from a deployment account directly to the primary administrator profile recursively:

```bash
   sudo chown -R altun /tmp/test

```
This operation updates the user ownership of all files and directories beneath the target path while preserving existing group assignments.

*Verification:* `ls -l /tmp/test` confirms that the user column has successfully transitioned to `altun`.

### 🛠️ Combined User & Group Ownership Migration

The `chown` utility can also update both the owner and the group simultaneously:

```bash
sudo chown -R altun:wheel /tmp/test
```

This command assigns ownership to user `altun` and group `wheel` in a single transaction.

2. **Isolating Group Constraints (`chgrp`):**
Aligned the target resource tree with the system's administrative `wheel` group to enforce collaborative boundaries while preserving the individual owner:

```bash
   sudo chgrp -R wheel /tmp/test

```

*Verification:* Running `ls -l` validates the secondary security matrix column shows `wheel` tracking.

---

## 3. Enterprise Task 3: Volatile Masking Constraints (`umask`)

To enforce a proactive security footprint, the operating system must filter default creation masks. This ensures that new files do not inherit broad default permissions, mitigating potential horizontal security leaks.

### 🛠️ Mathematical & Tactical Verification

1. **Inspecting Active System Filters:**

```bash
   umask

```

*Default System Return:* `0022`

2. **Mathematical Evaluation of the Subtraction Filter:**
When a new resource is initiated, the kernel subtracts the active `umask` from the systemic maximum base ($666$ for standard data files, $777$ for directory nodes):
* **Directory Node:** $777 - 022 = 755$ (`rwxr-xr-x`)
* **Standard File:** $666 - 022 = 644$ (`rw-r--r--`)


3. **Hardening the Pipeline (Zero-Trust Configuration):**
Tightened the masking parameters to ensure that secondary groups and public entities receive zero baseline visibility upon new file generation:

```bash
   umask 0077
   touch enterprise_hardened.conf
   ls -l enterprise_hardened.conf

```

*Resulting Authorization Flags:* `-rw-------` ($666 - 077 = 600$). The system effectively isolates the production footprint natively.

---

## 📊 Comprehensive Permission Administration Matrix

| Command | Operational Purpose | Production Practical Example | Essential Options | Option Mechanics / Output |
| --- | --- | --- | --- | --- |
| **`chmod`** | Modifies operational file system access control flags (`rwx`). | `chmod 755 script.sh` | **`+t`** / **`-R`** | `+t` applies the Sticky Bit isolation layer; `-R` triggers recursive inheritance. |
| **`chown`** | Reassigns target profile account ownership links. | `chown -R altun /var/www` | **`-R`** | Batch updates directory trees to align ownership structures. |
| **`chgrp`** | Reassigns target resource group connectivity constraints. | `chgrp wheel app.log` | **`-R`** | Cascades specialized group permission maps across target objects. |
| **`umask`** | Configures active subtraction filters for new files/directories. | `umask 022` | *None* | Subtracts values dynamically against base tokens (`666` files / `777` folders). |

---

ℹ️ *All storage authorization policies, dynamic masks, and recursive identities validated under zero-trust production constraints.*