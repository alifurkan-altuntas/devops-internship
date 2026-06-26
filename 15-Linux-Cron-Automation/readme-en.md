# ⏰ Cron & Automation — Disk Reports, Log Archiving, and One-Time Jobs

This document covers scheduling recurring scripts with `cron`, scheduling one-time jobs with `at`, and a real debugging process around running `sudo` commands inside a cron job.

---

## 1. The Task

Set up automation that, every night:

- Archives logs
- Generates a disk usage report

---

## 2. Crontab Syntax

```
* * * * * command
│ │ │ │ │
│ │ │ │ └─ Day of week (0-7, 0 and 7 = Sunday)
│ │ │ └─── Month (1-12)
│ │ └───── Day of month (1-31)
│ └─────── Hour (0-23)
└───────── Minute (0-59)
```

Field order: **minute, hour, day of month, month, day of week.**

To run something every night at 02:00:

```
0 2 * * *
```

Both "day of month" and "day of week" are separate fields — setting both to `*` means "every day," regardless of which day of the month or week it is. A rule like `0 2 * * 1-5` would mean "every weekday at 02:00."

---

## 3. Disk Usage Report Script

Reuses the disk-checking logic from the Bash Scripting phase, but writes the result to a file instead of printing it — since cron runs in the background with nobody watching the screen.

```bash
#!/bin/bash

today=$(date +%Y-%m-%d)
usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)

mkdir -p ~/disk_reports
report_file="$HOME/disk_reports/disk_report_$today.txt"

if [ $usage -gt 80 ]; then
    echo "WARNING: Disk usage is ${usage}% on $today" > $report_file
else
    echo "OK: Disk usage is ${usage}% on $today" > $report_file
fi

echo "Report saved to $report_file"
```

This one worked fine under cron immediately — no `sudo` involved anywhere, since both reading disk usage and writing to the user's own home directory stay within normal user permissions.

---

## 4. Log Archiving Script (and the real debugging process)

### The goal

Compress Nginx's `access.log`, save it with a date-stamped name in an archive folder, then empty the original log file so Nginx can keep writing to it.

### First version

```bash
#!/bin/bash

today=$(date +%Y-%m-%d)
mkdir -p ~/nginx_archive

gzip -c /var/log/nginx/access.log > ~/nginx_archive/access-$today.log.gz
sudo truncate -s 0 /var/log/nginx/access.log

echo "Log archived as access-$today.log.gz"
```

Key pieces:

- **`gzip -c`**: compresses the file but sends the output to stdout instead of replacing the original file in place. Without `-c`, plain `gzip file` would compress _and delete_ the original — not what we want here, since Nginx may still be writing to it, and we want a custom name/location anyway.
- **`truncate -s 0`**: resets the file's size to 0 bytes without deleting the file. This matters because deleting the file outright (`rm`) could break Nginx's open file handle — `truncate` keeps the file reference intact, just empties the contents.

### Problem 1: Permission denied on redirect

Running `sudo gzip -c file > archive/file.gz` failed with "Permission denied," because `sudo` only applies to the `gzip` command — the `>` redirection itself runs with the _current user's_ permissions, not root's. Since reading the log turned out not to require `sudo` at all, this was avoided entirely by dropping `sudo` from that line once it was confirmed unnecessary (`cat /var/log/nginx/access.log` worked without it).

### Problem 2: `chmod: Operation not permitted`

```text
chmod: 'archive_logs.sh' ögesinin erişim izinleri değiştiriliyor: İşleme izin verilmedi
```

Cause: the script file itself was owned by `root` — likely from having opened it with `sudo nano` at some point. Fixed with:

```bash
sudo chown altun:altun archive_logs.sh
```

### Problem 3: The script "succeeded" under cron but did nothing

Cron logs (`/var/log/syslog`, filtered with `grep -a CRON`) showed the script being triggered, and it printed "Log archived..." — but the archive file was effectively empty/missing meaningful content. Redirecting the script's actual output to a debug file revealed the real error:

```bash
* * * * * /home/altun/archive_logs.sh >> /home/altun/cron_debug.log 2>&1
```

```text
sudo: a password is required
```

**Root cause:** `sudo` requires an interactive terminal to prompt for a password. Cron runs non-interactively — nobody is there to type a password — so every `sudo` command inside the script silently failed. The script still printed its final `echo` line because that part didn't depend on `sudo` succeeding.

This failure wasn't visible at first because cron tries to email command output by default, and with no mail system (MTA) installed, that output (including the error) was silently discarded — visible in `journalctl` as `"No MTA installed, discarding output"`.

### The fix: a narrow `sudoers` rule

Rather than giving broad `sudo` access, a rule was added for the _one_ command that genuinely needed root (truncating a file owned by `www-data`):

```bash
sudo visudo
```

```text
altun ALL=(ALL) NOPASSWD: /usr/bin/truncate -s 0 /var/log/nginx/access.log
```

This follows the Least Privilege principle from earlier phases — only that exact command, with that exact path, gets passwordless access. Nothing broader.

### Final working version

```bash
#!/bin/bash

today=$(date +%Y-%m-%d)
mkdir -p ~/nginx_archive

gzip -c /var/log/nginx/access.log > ~/nginx_archive/access-$today.log.gz
sudo truncate -s 0 /var/log/nginx/access.log

echo "Log archived as access-$today.log.gz"
```

After the `sudoers` fix, this ran without any password prompt, both manually and under cron.

---

## 5. Side Note: `logrotate`

In real production environments, Nginx already ships with its own log rotation setup via `logrotate` (`/etc/logrotate.d/nginx`), which runs daily as root and handles exactly this kind of task — compressing, rotating, and recreating log files with correct ownership:

```text
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        invoke-rc.d nginx rotate >/dev/null 2>&1
    endscript
}
```

Worth understanding even though the custom script above was still built and fixed for this task — in a real setup, this existing mechanism wouldn't normally be reinvented from scratch.

---

## 6. Scheduling Both Scripts

```bash
crontab -e
```

```
0 2 * * * /home/altun/archive_logs.sh
0 2 * * * /home/altun/disk_report.sh
```

Both run every night at 02:00. Verified with:

```bash
crontab -l
```

---

## 7. One-Time Scheduling with `at`

`cron` is for **recurring** jobs. `at` is for something that should run **exactly once**, at a specific point in the future — no repeating schedule needed.

### Installing and Enabling `at`

Not installed by default on this server:

```bash
sudo apt install at -y
sudo systemctl enable --now atd
```

`atd` is the background service that actually runs `at` jobs — conceptually the same role `crond` plays for cron.

### Scheduling a One-Time Job

```bash
echo "echo Merhaba > /home/altun/at_test.txt" | at now + 1 minute
```

This schedules the command to run once, one minute from now.

### Checking Pending Jobs

```bash
atq
```

**Important:** `atq` only lists jobs that are still **pending**. Once a job actually runs, it disappears from `atq` — that doesn't mean it failed, it means it's done. The real way to confirm a job ran is to check its actual result:

```bash
cat /home/altun/at_test.txt
```

This came up directly: a job looked "missing" from `atq` after its scheduled time passed, but the output file confirmed it had in fact run successfully — `atq` going empty was just expected behavior, not a failure.

### Cancelling a Pending Job

```bash
atrm <job_number>
```

Uses the job number shown by `atq`.

---

## 📊 Command Reference

| Command                     | Purpose                                                                       |
| --------------------------- | ----------------------------------------------------------------------------- |
| **`crontab -e`**            | Edit the current user's cron jobs.                                            |
| **`crontab -l`**            | List the current user's scheduled cron jobs.                                  |
| **`gzip -c file > out.gz`** | Compress without deleting/modifying the original file.                        |
| **`truncate -s 0 file`**    | Reset a file's size to 0 without deleting it.                                 |
| **`sudo visudo`**           | Safely edit sudoers rules (syntax-checked before saving).                     |
| **`NOPASSWD:`**             | Allows a specific command to run via `sudo` without a password prompt.        |
| **`chown user:user file`**  | Changes file ownership — needed when a file was created as `root` by mistake. |
| **`journalctl -u cron`**    | View cron's own logs to debug why a job didn't behave as expected.            |
| **`at now + <time>`**       | Schedules a one-time command to run at a future point.                        |
| **`atq`**                   | Lists pending (not-yet-run) `at` jobs.                                        |
| **`atrm <job_number>`**     | Cancels a pending `at` job.                                                   |

---

ℹ️ _The real lesson here wasn't the scripts themselves — both were fairly simple — but debugging why something that worked manually silently failed when automated, and learning that cron's non-interactive nature is what broke it. Same spirit with `at`: the job didn't actually fail, it just disappeared from the wrong place to check._
