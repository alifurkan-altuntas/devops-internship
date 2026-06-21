# 🔑 Linux Permissions & Security Hardening

This document covers file permissions, ownership, umask, and the sticky bit implemented on Virtual Private Servers (VPS).

---

## 1. Shared Directory with Sticky Bit

A shared folder with full write access (`777`) introduces a vulnerability: any user can cross-delete or alter files belonging to other operators. To mitigate these risks, the **sticky bit** was used to fix this.

### 🛠️ Steps

1. **Created the shared directory:**

```bash
   sudo mkdir /tmp/test
   sudo chmod 777 /tmp/test

```

2. **Added the sticky bit:**
   To prevent cross-deletion while keeping write access open:

```bash
   sudo chmod +t /tmp/test

```

_Alternative absolute command layout:_ `sudo chmod 1777 /tmp/test`

3. **Status Verification:**

```bash
   ls -ld /tmp/test

```

_Expected system flag output:_ `drwxrwxrwt ... /tmp/test` (The trailing **`t`** token indicates the active Sticky Bit perimeter).

### 🔐 How It Works

The Sticky Bit does **not** restrict file reading or modification permissions directly. Instead, it introduces a directory-level ownership boundary that controls file deletion and renaming operations.

Within a Sticky Bit protected directory:

- File owners may delete or rename their own files.
- The directory owner may manage files within the directory.
- Root retains full administrative control.
- Other users, even with write permissions on the directory, cannot delete or rename files owned by another user.

This mechanism is widely used on shared temporary storage locations such as `/tmp`, where all users require write access but cross-user file removal must be prevented.

### 🔒 Test Results

Tested with two different users:

- **Test Case A (Ownership Execution):** User `altun` runs `touch /tmp/test/test.txt` — succeeds.
- **Test Case B (Cross-Deletion Trap):** User `devopstester` tries `rm /tmp/test/test.txt` — fails.
- **Output:**

```text
  rm: cannot remove '/tmp/test/test.txt': Operation not permitted

```

Confirms only the file owner and root can delete the file.

---

## 2. Changing Ownership & Group (`chown` & `chgrp`)

Files should be owned by the right user and group for proper access control.

### 🛠️ Steps

1. **Changing owner (`chown`):**
   Changed ownership recursively to `altun`:

```bash
   sudo chown -R altun /tmp/test

```

This operation updates the user ownership of all files and directories beneath the target path while preserving existing group assignments.

_Verification:_ `ls -l /tmp/test` confirms that the user column has successfully transitioned to `altun`.

### 🛠️ Changing Owner & Group Together

The `chown` utility can also update both the owner and the group simultaneously:

```bash
sudo chown -R altun:wheel /tmp/test
```

This command assigns ownership to user `altun` and group `wheel` in a single transaction.

2. **Changing Group Ownership (`chgrp`):**
   Changed the group to `wheel`, while preserving the individual owner:

```bash
   sudo chgrp -R wheel /tmp/test

```

_Verification:_ `ls -l` confirms the group column now shows `wheel`.

---

## 3. Default Permission Masking (`umask`)

umask controls the default permissions of new files and directories. This ensures that new files do not inherit broad default permissions, mitigating potential horizontal security leaks.

### 🛠️ Calculation & Verification

1. **Inspecting Active System Filters:**

```bash
   umask

```

_Default System Return:_ `0022`

2. **How the Math Works:**
   When a new resource is initiated, the kernel subtracts the active `umask` from the systemic maximum base ($666$ for standard data files, $777$ for directory nodes):

- **Directory Node:** $777 - 022 = 755$ (`rwxr-xr-x`)
- **Standard File:** $666 - 022 = 644$ (`rw-r--r--`)

3. **Restricting Default Permissions:**
   Tightened umask so new files are private by default:

```bash
   umask 0077
   touch enterprise_hardened.conf
   ls -l enterprise_hardened.conf

```

_Resulting Authorization Flags:_ `-rw-------` ($666 - 077 = 600$). Only the owner has access.

---

## 📊 Command Reference

| Command     | Operational Purpose                                              | Production Practical Example | Essential Options   | Option Mechanics / Output                                                         |
| ----------- | ---------------------------------------------------------------- | ---------------------------- | ------------------- | --------------------------------------------------------------------------------- |
| **`chmod`** | Modifies operational file system access control flags (`rwx`).   | `chmod 755 script.sh`        | **`+t`** / **`-R`** | `+t` applies the Sticky Bit isolation layer; `-R` triggers recursive inheritance. |
| **`chown`** | Reassigns target profile account ownership links.                | `chown -R altun /var/www`    | **`-R`**            | Batch updates directory trees to align ownership structures.                      |
| **`chgrp`** | Reassigns target resource group connectivity constraints.        | `chgrp wheel app.log`        | **`-R`**            | Cascades specialized group permission maps across target objects.                 |
| **`umask`** | Configures active subtraction filters for new files/directories. | `umask 022`                  | _None_              | Subtracts values dynamically against base tokens (`666` files / `777` folders).   |

---

ℹ️ _All commands tested locally._
