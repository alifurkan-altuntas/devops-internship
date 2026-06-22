# 📊 Phase 15 Quiz Results — Cron & Automation

**Score: 14/15 (93%)** — 1 left blank

---

**1. What is the correct field order in a crontab line?**
A) Hour, Minute, Day of Month, Month, Day of Week
B) Minute, Hour, Day of Month, Month, Day of Week
C) Minute, Hour, Day of Week, Month, Day of Month
D) Day of Month, Hour, Minute, Month, Day of Week

**My answer: B** ✅

---

**2. What does `0 2 * * *` mean?**
A) Every 2 minutes
B) Every day at 02:00
C) Every 2 hours
D) Once a month at midnight

**My answer: B** ✅

---

**3. In crontab, what does `1-5` in the "day of week" field represent?**
A) The 1st through 5th day of the month
B) Monday through Friday
C) The first 5 hours of the day
D) 1 to 5 minutes past the hour

**My answer: B** ✅

---

**4. Why did `archive_logs.sh` fail when run via cron, but succeed when run manually?**
A) The script had a syntax error
B) Cron couldn't respond to the `sudo` password prompt, since it runs non-interactively
C) Cron doesn't support bash scripts
D) The script file didn't have execute permission

**My answer: B** ✅

---

**5. What does `gzip -c file > newfile.gz` do differently from plain `gzip file`?**
A) It deletes the original file immediately
B) It compresses to a new file without modifying or deleting the original
C) It runs the compression in the background
D) It compresses without using gzip format

**My answer: B** ✅

---

**6. What does `truncate -s 0 file.log` do?**
A) Deletes the file entirely
B) Renames the file
C) Resets the file's size to 0 bytes, without deleting the file itself
D) Compresses the file

**My answer: C** ✅

---

**7. Why is `truncate` generally safer than `rm` for resetting an active log file?**
A) `truncate` is faster
B) The file path/reference stays intact, so the program writing to it (e.g. Nginx) isn't disrupted
C) `rm` requires more disk space
D) There is no real difference

**My answer: B** ✅

---

**8. What was the root cause of the `chmod: Operation not permitted` error encountered on `archive_logs.sh`?**
A) The file had no read permission
B) The file was owned by `root` (likely created via `sudo nano`), not by the current user
C) `chmod` was misspelled
D) The script didn't have a shebang line

**My answer: B** ✅

---

**9. Which command was used to fix the file ownership issue?**
A) `chmod 777 file`
B) `chown altun:altun file`
C) `sudo rm file`
D) `mv file newfile`

**My answer: B** ✅

---

**10. What does adding a line like `altun ALL=(ALL) NOPASSWD: /usr/bin/truncate -s 0 /var/log/nginx/access.log` to sudoers accomplish?**
A) Gives `altun` full root access with no password, for any command
B) Allows `altun` to run that one specific command without being prompted for a password
C) Disables sudo entirely for all users
D) Grants permission to edit the sudoers file itself

**My answer: B** ✅

---

**11. Why was the sudoers rule written for that one exact command instead of a broader rule (e.g. `ALL`)?**
A) Broader rules are not supported by `visudo`
B) Following the Least Privilege principle — granting only the specific access actually needed
C) It was a syntax requirement
D) `truncate` cannot be used with wildcards

**My answer: B** ✅

---

**12. What tool does Nginx already use, by default, to handle log rotation in production?**
A) `cron` directly
B) `logrotate`
C) `systemd-journald`
D) `tee`

**My answer: B** ✅

---

**13. In a `logrotate` config, what does `create 0640 www-data adm` do?**
A) Deletes the old log file with no replacement
B) Creates a new empty log file after rotation, with specific permissions and ownership
C) Compresses the file to 640KB
D) Forces the file to never rotate

**My answer: B** ✅

---

**14. Why did the disk usage script (`disk_report.sh`) not run into the same `sudo` problem as the log archiving script?**
A) It used a different version of bash
B) It didn't require any `sudo` commands — both reading disk usage and writing the report stayed within the user's own permissions
C) Cron treats scripts differently based on their length
D) It was scheduled at a different time

**My answer: B** ✅

---

**15. What was the actual reason `cron`'s failure wasn't immediately visible in the terminal?**
A) Cron jobs never produce any output
B) The error output was sent to mail by default, and with no mail system (MTA) installed, it was silently discarded
C) The script crashed the entire system
D) Cron logs are encrypted

**My answer: (left blank — wasn't sure)** ⬜
**Correct answer: B**

---

## Note on the blank

Q15 was left blank rather than guessed. The correct answer (B) describes exactly what showed up in the cron logs during this phase — the `"No MTA installed, discarding output"` message — which was the actual reason the `sudo` failure stayed invisible until output was manually redirected to a debug file.

---

ℹ️ _All answers given without revisiting or correcting after submission._
