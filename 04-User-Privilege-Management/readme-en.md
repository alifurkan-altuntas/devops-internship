# 🔑 Linux User Administration & Privilege Management

This document covers user/group management and sudo restrictions using the Least Privilege Principle inside the `sudoers` architecture.

---

## 1. Restricting sudo Access (Least Privilege)

Giving full root access via the `wheel` or `sudo` group is risky for accounts that don't need it. To mitigate this, a test account (`devopstester`) was restricted to only run `systemctl restart nginx`, blocking all other service management sub-commands.

### 🛠️ Step-by-Step Security Implementation

1. **Created the Test Account:**

   ```bash
   sudo useradd -m devopstester
   sudo passwd devopstester

   ```

2. **Configured sudo Permissions via `visudo`:**
   To enforce strict boundaries, the structural configuration file `/etc/sudoers` was modified securely using the `sudo visudo` command by appending the following specific instruction at the bottom of the registry:

```text
    devopstester ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
```

### 🔍 Binary Path Verification

Before creating a sudoers rule, verify the exact location of the binary:

```bash
which systemctl
```

Example output:

```text
/usr/bin/systemctl
```

The path may vary between Linux distributions and environments.

- **`devopstester`**: The restricted account.
- **`NOPASSWD:`**: Skips the password prompt for this specific command — useful for automation.
- **`/usr/bin/systemctl restart nginx`**: Restricts execution to the exact command invocation, including its arguments.

---

### 🔒 Why `visudo` Instead of Editing `/etc/sudoers` Directly?

`visudo` provides several safety mechanisms:

- Syntax validation before saving
- File locking to prevent simultaneous edits
- Protection against malformed configurations
- Reduced risk of accidentally breaking sudo access

---

## 2. Verification & Results

Testing as `devopstester`:

- **Test Case A (`sudo systemctl restart nginx`):** Ran successfully without a password prompt.
- **Test Case B (`sudo systemctl stop nginx`):** Blocked, with this error:

```text
Sorry, user devopstester is not allowed to execute '/usr/bin/systemctl stop nginx' as root on altun.

```

Confirms the restriction works as intended.

---

## 📊 User & Privilege Administration Command Matrix

| Command        | Operational Purpose                                                                 | Production Practical Example | Essential Options | Option Mechanics / Output                                                           |
| -------------- | ----------------------------------------------------------------------------------- | ---------------------------- | ----------------- | ----------------------------------------------------------------------------------- |
| **`useradd`**  | Creates a new local user account inside the `/etc/passwd` registry.                 | `useradd -m devopsuser`      | **`-m`**          | Automates the creation of a clean home directory tree structure.                    |
| **`passwd`**   | Sets or updates encrypted authentication keys for a targeted user node.             | `passwd devopsuser`          | _None_            | Updates password layers securely.                                                   |
| **`usermod`**  | Modifies existing user profile structures and secondary runtime parameters.         | `usermod -aG wheel user`     | **`-aG`**         | Appends (`a`) the user to a targeted group (`G`) without purging older memberships. |
| **`groupadd`** | Creates a new local group inside the `/etc/group`.                                  | `groupadd security-team`     | _None_            | Generates logical group objects for role-based access.                              |
| **`id`**       | Shows UID, GID, and group memberships for a user.                                   | `id devopstester`            | _None_            | Returns **UID**, **GID**, and groups.                                               |
| **`sudo`**     | Executes dedicated target operational binaries utilizing elevated root permissions. | `sudo visudo`                | _None_            | Runs commands as root per `/etc/sudoers` rules.                                     |

---

ℹ️ _All steps tested and verified._
