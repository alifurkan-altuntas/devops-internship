# 🔐 Linux SSH, SCP & SFTP

This document covers setting up passwordless SSH access using key pairs, and transferring files with SCP and SFTP.

---

## 1. Setting Up Passwordless SSH Access

SSH key-based authentication uses a key pair instead of a password:

- **Private key** stays on your machine, never shared.
- **Public key** gets added to the server's `~/.ssh/authorized_keys`.
- The server uses the public key to verify you hold the matching private key — no password needed.

### 🛠️ Steps

1. **Generate a key pair:**

   ```bash
   ssh-keygen -t ed25519 -C "your_label"
   ```

   - `-t ed25519`: a modern algorithm — smaller key size than RSA but equivalent or better security.
   - `-C`: just a label/comment to identify the key, optional.
   - Press Enter to accept the default save location. A passphrase is optional but recommended (this passphrase protects the private key locally — it's separate from any server password).

2. **Copy the public key to the server.**

   The standard tool for this is `ssh-copy-id`:

   ```bash
   ssh-copy-id user@server_ip
   ```

   This automates: connecting with a password, creating `~/.ssh` on the server if missing, fixing its permissions, and appending your public key to `authorized_keys` (without overwriting existing keys).

   **Note:** `ssh-copy-id` is a bash script and isn't available on Windows by default. On Windows, the same result has to be done manually:

   ```bash
   # Show the public key (on the client)
   cat ~/.ssh/id_ed25519.pub

   # Connect to the server with a password
   ssh user@server_ip

   # On the server: prepare the folder and file
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   nano ~/.ssh/authorized_keys   # paste the public key here
   chmod 600 ~/.ssh/authorized_keys
   ```

3. **Test the connection:**

   ```bash
   ssh user@server_ip
   ```

   If a passphrase was set on the key, SSH will prompt for that — not a server password. If no passphrase was set, it connects immediately.

### 🔐 Why the `chmod` Permissions Matter

SSH actively checks the permissions on `.ssh` and `authorized_keys` before trusting them. If they're too open, SSH may silently refuse to use them and fall back to password auth:

- `chmod 700 ~/.ssh` → only the owner can read/write/enter the folder.
- `chmod 600 ~/.ssh/authorized_keys` → only the owner can read/write the file.

The reason: `authorized_keys` is effectively a list of "who is allowed in." If anyone else could edit it, they could add their own key and gain access to the system — so SSH refuses to honor a file it can't be sure is private.

4. **Disable password login (optional, but the actual goal of "passwordless access"):**

   Edit `/etc/ssh/sshd_config`:

   ```text
   PasswordAuthentication no
   ```

   **Important:** if this line is commented out (starts with `#`), it has no effect — the `#` has to be removed for the setting to actually apply.

   Then restart the service:

   ```bash
   sudo systemctl restart sshd
   ```

### 🔍 Verifying It Actually Works

To confirm the restriction is real, it's worth testing both directions:

- Remove the key from `authorized_keys` and try connecting → should fail.
- Add it back and try again → should succeed.

This proves the connection is genuinely depending on that specific key, not something else.

### 🗂️ Managing Multiple Keys

If you have separate keys for different servers, SSH won't automatically guess which one to use unless it's at the default path (`~/.ssh/id_ed25519`). For a key saved under a custom name, specify it explicitly:

```bash
ssh -i ~/.ssh/id_ed25519_ubuntu user@server_ip
```

Forgetting this is a common cause of `Permission denied (publickey)` even when the key itself is correct — SSH was just trying the wrong (or no) key.

Verbose mode helps diagnose this:

```bash
ssh -v -i ~/.ssh/id_ed25519_ubuntu user@server_ip
```

### 📄 Simplifying with an SSH Config File

Instead of typing `-i` every time, connection details can be saved in `~/.ssh/config`:

```text
Host ubuntu-vm
    HostName 192.168.1.50
    User altun
    IdentityFile ~/.ssh/id_ed25519_ubuntu

Host rocky-vm
    HostName 192.168.1.60
    User vagrant
    IdentityFile ~/.ssh/id_ed25519
```

After this, connecting is as simple as:

```bash
ssh ubuntu-vm
```

No IP, username, or key path needs to be typed each time.

---

## 2. Transferring Files: SCP vs SFTP

Both run over SSH, so the same key-based authentication applies — no extra setup needed once SSH access works.

### 🛠️ SCP (Secure Copy)

One-shot file/folder transfers from the command line.

```bash
# Upload a file
scp localfile.txt user@server_ip:/home/user/

# Download a file
scp user@server_ip:/home/user/remotefile.txt ./

# Copy a folder (recursive)
scp -r local_folder user@server_ip:/home/user/
```

### 🛠️ SFTP (SSH File Transfer Protocol)

Opens an interactive session for browsing and transferring files.

```bash
sftp user@server_ip
```

Inside the session:

```text
pwd      # remote working directory
lpwd     # local working directory
ls       # list remote files
cd       # change remote directory
lcd      # change local directory
get file # download a file
put file # upload a file
exit     # close the session
```

---

## 📊 Command Reference

| Command           | Purpose                                              | Example                            | Notes                                                                              |
| ----------------- | ---------------------------------------------------- | ---------------------------------- | ---------------------------------------------------------------------------------- |
| **`ssh-keygen`**  | Generates a public/private key pair.                 | `ssh-keygen -t ed25519`            | `-t` sets the algorithm; `ed25519` is the modern default.                          |
| **`ssh-copy-id`** | Copies a public key to a server's `authorized_keys`. | `ssh-copy-id user@host`            | Bash script — not available on Windows by default.                                 |
| **`chmod`**       | Sets file/folder permissions.                        | `chmod 600 ~/.ssh/authorized_keys` | SSH requires strict permissions on key-related files or it may refuse to use them. |
| **`ssh -i`**      | Connects using a specific private key.               | `ssh -i ~/.ssh/key user@host`      | Needed when the key isn't at the default path.                                     |
| **`scp`**         | Copies files/folders over SSH.                       | `scp -r folder user@host:/path/`   | `-r` for recursive (folders).                                                      |
| **`sftp`**        | Opens an interactive file transfer session.          | `sftp user@host`                   | Supports `get`, `put`, `ls`, `cd`, etc.                                            |

---

ℹ️ _All commands tested locally between a Windows host and Ubuntu/Rocky Linux VMs._
