# 📊 Phase 12 Quiz Results — SSH, SCP & SFTP

**Score: 15/15 (100%)**

---

**1. In SSH key-based authentication, which key gets uploaded to the server?**
A) Private key
B) Public key
C) Both
D) Neither, only the passphrase is uploaded

**My answer: B** ✅

---

**2. In `ssh-keygen -t ed25519`, what does the `-t` flag specify?**
A) Target server address
B) Key expiration time
C) The cryptographic algorithm to use
D) Terminal mode

**My answer: C** ✅

---

**3. Why is `ed25519` often preferred over RSA?**
A) It's older and more widely supported
B) It offers equivalent or better security with a smaller key size
C) It doesn't require a passphrase
D) It only works on Windows

**My answer: B** ✅

---

**4. Where is the `authorized_keys` file located on the server?**
A) `/etc/ssh/`
B) `~/.ssh/`
C) `/var/ssh/keys/`
D) `~/ssh-config/`

**My answer: B** ✅

---

**5. What does `chmod 700 ~/.ssh` do?**
A) Makes the folder accessible to everyone
B) Restricts the folder so only the owner can read/write/enter it
C) Deletes the folder
D) Makes the folder read-only

**My answer: B** ✅

---

**6. If `authorized_keys` has overly permissive permissions (e.g. `777`), what happens?**
A) SSH may refuse to use the file
B) Nothing changes
C) The file gets deleted automatically
D) Only root can access it

**My answer: A** ✅

---

**7. If a line in `sshd_config` starts with `#`, what does that mean?**
A) The line becomes mandatory
B) The line is a comment and is ignored
C) The line is encrypted
D) The file is corrupted

**My answer: B** ✅

---

**8. After setting `PasswordAuthentication no`, which step is required?**
A) Rebooting the server
B) Restarting the SSH service (`systemctl restart ssh`)
C) Nothing, it applies automatically
D) Deleting the public key

**My answer: B** ✅

---

**9. If a machine has multiple SSH keys (e.g. separate keys for Rocky and Ubuntu), how do you specify which key to use when connecting?**
A) `ssh --key filename user@host`
B) `ssh -i /path/to/key user@host`
C) SSH automatically tries all of them, no need to specify
D) `ssh -t filename user@host`

**My answer: B** ✅

---

**10. What is the purpose of the SSH config file (`~/.ssh/config`)?**
A) To store server user passwords
B) To define shortcuts for connection info like host, username, and key file
C) To manage firewall rules
D) To start the SSH service

**My answer: B** ✅

---

**11. What does `ssh-copy-id` automate?**
A) Generating a new key
B) Copying the public key to the server and adding it to `authorized_keys`
C) Restarting the server
D) Changing a password

**My answer: B** ✅

---

**12. Why doesn't `ssh-copy-id` work by default on Windows?**
A) Windows doesn't support SSH
B) It's a bash script, and Windows doesn't have native bash
C) Windows can't generate keys
D) It's a licensing restriction

**My answer: B** ✅

---

**13. Which flag is required to copy a folder (with its contents) using SCP?**
A) `-c`
B) `-r`
C) `-a`
D) `-f`

**My answer: B** ✅

---

**14. How does SFTP fundamentally differ from SCP?**
A) SFTP doesn't use encryption, SCP does
B) SFTP provides an interactive session (browsing, listing), SCP does a one-time copy
C) SFTP only works on Windows
D) There is no real difference

**My answer: B** ✅

---

**15. If an SSH connection fails with "Permission denied (publickey)" and you're sure the key is correct, what should you check first?**
A) Your internet connection
B) The permissions (`chmod`) on `authorized_keys` and `.ssh`
C) Reinstall the server
D) Delete and regenerate the public key

**My answer: B** ✅

---

ℹ️ _All answers given without revisiting or correcting after submission — this reflects what genuinely stuck from working through the phase._
