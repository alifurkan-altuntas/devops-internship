# 🔑 Linux Permissions & Security Hardening

This document covers file permissions, ownership, umask, and the sticky bit.

---

## 1. Reading `ls -l` Output

```text
-rwxr-xr-x  1 altun altun  4096 Jun 19 18:09 script.sh
drwxr-x---  1 altun altun  4096 Jun 19 18:09 folder/
lrwxrwxrwx  1 altun altun     7 Jun 19 18:09 link -> target
```

The very first character indicates the **type**, not a permission:

| Character | Meaning                                        |
| --------- | ---------------------------------------------- |
| `-`       | Regular file (no special letter — just a dash) |
| `d`       | **D**irectory                                  |
| `l`       | Symbolic **l**ink                              |

The remaining 9 characters are split into three groups of 3 (`rwx`), representing **user (owner)**, **group**, and **others**, in that order.

---

## 2. The `chmod` Numeric System

Each permission has a fixed numeric value:

| Number | Permission  |
| ------ | ----------- |
| **4**  | read (r)    |
| **2**  | write (w)   |
| **1**  | execute (x) |

These values are **added together** to represent a combination — each combination from 0-7 has exactly one possible meaning:

| Sum | Permissions | Meaning                |
| --- | ----------- | ---------------------- |
| 7   | rwx         | read + write + execute |
| 6   | rw-         | read + write           |
| 5   | r-x         | read + execute         |
| 4   | r--         | read only              |
| 0   | ---         | no permissions         |

A `chmod` command uses three digits — one each for **user, group, others**:

```bash
chmod 750 file
```

= user: `7` (rwx), group: `5` (r-x), others: `0` (---)

### Worked Examples

- **`chmod 700`** — user has full access (rwx); group and others have nothing. Useful for private files only the owner should touch.
- **`chmod 555`** — everyone (user, group, others) can read and execute, but nobody can write. Common for shared, read-only scripts.
- **`chmod 074`** — user has no permissions at all; group has full access; others can only read. An unusual but valid combination — there's no rule that the owner needs the most access.

### File vs. Directory Maximum Permissions

This is easy to get backwards, so worth stating clearly:

- **Files**: maximum is `666` (rw-rw-rw-) by default — execute isn't meaningful for a file unless it's actually a script/binary, so it isn't granted automatically.
- **Directories**: maximum is `777` (rwxrwxrwx) by default — the execute bit on a directory means "permission to enter/traverse it" (`cd` into it, list its contents). Without `x`, a directory can't be entered at all, even if `r` is set.

This is exactly why `umask` math (covered below) subtracts from `666` for files and `777` for directories — they have different baselines.

---

## 3. Shared Directory with Sticky Bit

A shared folder with full write access (`777`) introduces a vulnerability: any user can cross-delete or alter files belonging to other operators. The **sticky bit** fixes this.

### 🛠️ Steps

1. **Created the shared directory:**

   ```bash
   sudo mkdir /tmp/test
   sudo chmod 777 /tmp/test
   ```

2. **Added the sticky bit:**

   ```bash
   sudo chmod +t /tmp/test
   ```

   _Alternative absolute command:_ `sudo chmod 1777 /tmp/test`

3. **Status Verification:**
   ```bash
   ls -ld /tmp/test
   ```
   _Expected output:_ `drwxrwxrwt ... /tmp/test` — the trailing **`t`** indicates the active sticky bit.

### 🔐 How It Works

The sticky bit does **not** restrict reading or modification directly. Instead, it adds a directory-level rule about deletion:

- File owners may delete or rename their own files.
- The directory owner may manage files within the directory.
- Root retains full control.
- Other users — even with write permission on the directory — cannot delete or rename files owned by someone else.

Widely used on shared temp locations like `/tmp`, where everyone needs write access but cross-user deletion must be blocked.

### 🔒 Test Results

- **Test Case A:** User `altun` runs `touch /tmp/test/test.txt` — succeeds.
- **Test Case B:** User `devopstester` tries `rm /tmp/test/test.txt` — fails:
  ```text
  rm: cannot remove '/tmp/test/test.txt': Operation not permitted
  ```

Confirms only the file owner and root can delete the file.

---

## 4. Changing Ownership & Group (`chown` & `chgrp`)

```bash
sudo chown -R altun /tmp/test           # change owner
sudo chown -R altun:wheel /tmp/test     # change owner AND group together
sudo chgrp -R wheel /tmp/test           # change group only
```

`-R` applies the change recursively to everything beneath the target path.

---

## 5. Default Permission Masking (`umask`)

`umask` controls the default permissions of newly created files and directories, by subtracting from the baseline maximums covered above.

```bash
umask
```

_Default return:_ `0022`

### The Math

- **Directory:** `777 - 022 = 755` (`rwxr-xr-x`)
- **File:** `666 - 022 = 644` (`rw-r--r--`)

Tightening it:

```bash
umask 0077
touch hardened.conf
ls -l hardened.conf
```

_Result:_ `-rw-------` (`666 - 077 = 600`) — only the owner has access.

---

## 📊 Command Reference

| Command     | Purpose                                                     | Example                         | Notes                                               |
| ----------- | ----------------------------------------------------------- | ------------------------------- | --------------------------------------------------- |
| **`chmod`** | Sets file permission flags (`rwx`).                         | `chmod 750 script.sh`           | `+t` adds the sticky bit; `-R` applies recursively. |
| **`chown`** | Changes file owner (and optionally group).                  | `chown -R altun:wheel /var/www` |                                                     |
| **`chgrp`** | Changes the group only.                                     | `chgrp wheel app.log`           |                                                     |
| **`umask`** | Sets the default permission mask for new files/directories. | `umask 022`                     | Subtracts from `666` (files) / `777` (directories). |

---

ℹ️ _All commands tested locally._
