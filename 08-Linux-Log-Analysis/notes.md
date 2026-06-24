# Linux Log Analysis & Text Manipulation

This document covers log parsing pipelines and IPv4/IPv6 differences across distros.

---

## 1. Log Parsing & Traffic Analysis

Finding top traffic sources or broken routes (404s) requires parsing the access log.

### 🛠️ Steps

1. **Missing `curl` on Ubuntu:**
   - **Rocky Linux:** `curl` is available by default.
   - **Ubuntu:** `command not found` on a minimal install — fixed with:
     ```bash
     sudo apt update && sudo apt install curl -y
     ```

2. **Generating Test HTTP Requests:**
   ```bash
   curl -I http://localhost/        # successful request
   curl -I http://localhost/aa      # 404 trigger
   ```

---

## 2. Understanding the Log Line Format

```text
::1 - - [19/Jun/2026:17:54:14 +0300] "GET /aa HTTP/1.1" 404 0 "-" "curl/8.5.0"
```

Key columns:

- **Column 1 (`$1`):** Client IP address (or loopback).
- **Column 7 (`$7`):** Requested path (e.g., `/aa`).
- **Column 9 (`$9`):** HTTP status code (e.g., `404`).

### IPv4 vs IPv6 on Different Distros

Same `curl` request to `localhost` returns different formats per distro:

- **Ubuntu:** prioritizes IPv6 in `/etc/hosts` — loopback shows as `::1`.
- **Rocky Linux:** defaults to IPv4 — loopback shows as `127.0.0.1`.

---

## 3. Reading Logs: `tail -n` vs `tail -f`

These two flags do fundamentally different things and are easy to conflate:

| Flag              | Behavior                                                                                                                 |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **`-n <number>`** | Shows the last N lines, **once**, then the command exits — back to a normal prompt immediately.                          |
| **`-f`**          | **F**ollows the file — stays open, printing new lines as they're written, and never exits on its own (`Ctrl+C` to stop). |

```bash
tail -n 50 /var/log/nginx/error.log     # last 50 lines, one-time snapshot
tail -f /var/log/nginx/error.log        # live stream of new entries
```

They can be combined — show recent history, then keep watching:

```bash
tail -n 50 -f /var/log/nginx/error.log
```

**When to use which:**

- Want to check "what just happened" once, without staying glued to a terminal → `-n`. Pair with `| less` for easy scrolling through more output.
- Want to actively watch a service in real time (e.g. right after a restart, or while reproducing an issue) → `-f`.

---

## 4. Parsing Pipelines

### Finding the Top IP

```bash
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr
```

- `awk '{print $1}'` — extracts the IP (Column 1).
- `sort` — groups identical entries together so `uniq` can count them.
- `uniq -c` — counts occurrences of each IP.
- `sort -nr` — sorts numerically, highest first.

### Counting 404 Errors by Path

```bash
sudo grep " 404 " /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -nr
```

- `grep " 404 "` — keeps only lines with a 404 status.
- `awk '{print $7}'` — extracts the requested path.
- `sort | uniq -c | sort -nr` — counts and ranks by frequency.

---

## 📊 Command Reference

| Command        | Purpose                                                     | Example                       | Notes                                                      |
| -------------- | ----------------------------------------------------------- | ----------------------------- | ---------------------------------------------------------- |
| **`awk`**      | Extracts specific columns from structured text.             | `awk '{print $7}' access.log` |                                                            |
| **`grep`**     | Filters lines matching a pattern.                           | `grep " 404 " access.log`     |                                                            |
| **`tail -n`**  | Shows the last N lines, once.                               | `tail -n 50 access.log`       | Exits immediately after printing.                          |
| **`tail -f`**  | Follows a file live, for new entries.                       | `tail -f access.log`          | Stays running; `Ctrl+C` to stop.                           |
| **`uniq -c`**  | Counts repeated adjacent lines.                             | `uniq -c`                     | Requires sorted input first.                               |
| **`sort -nr`** | Sorts numerically, descending.                              | `sort -nr`                    |                                                            |
| **`less`**     | Paginated viewer — doesn't load the whole file into memory. | `less access.log`             | Good for scrolling through `tail -n` output on large logs. |

---

ℹ️ _All commands tested locally._
