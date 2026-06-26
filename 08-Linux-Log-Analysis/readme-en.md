# Linux Log Analysis & Text Manipulation

This document covers log parsing pipelines, IPv4/IPv6 differences across distros, and editing text with `sed`.

---

## 1. Log Parsing & Traffic Analysis

Finding top traffic sources or broken routes (404s) requires parsing the access log.

### Steps

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

| Flag              | Behavior                                                                                                             |
| ----------------- | -------------------------------------------------------------------------------------------------------------------- |
| **`-n <number>`** | Shows the last N lines, **once**, then the command exits.                                                            |
| **`-f`**          | **F**ollows the file — stays open, printing new lines as they're written, never exits on its own (`Ctrl+C` to stop). |

```bash
tail -n 50 /var/log/nginx/error.log     # last 50 lines, one-time snapshot
tail -f /var/log/nginx/error.log        # live stream of new entries
tail -n 50 -f /var/log/nginx/error.log  # both: recent history, then keep watching
```

---

## 4. Parsing Pipelines

### Finding the Top IP

```bash
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr
```

- `awk '{print $1}'` — extracts the IP (Column 1).
- `sort` — groups identical entries so `uniq` can count them.
- `uniq -c` — counts how many times each IP appears (this is the part that does the actual counting — not filtering, counting).
- `sort -nr` — sorts numerically, highest first.

### Counting Requests by Path (Path-Based Grouping)

This is conceptually similar to SQL's `GROUP BY` + `COUNT()`: "for this specific path, how many requests came from each IP?"

```bash
grep "/some-path" /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c
```

For an exact match on a full request line (avoiding partial matches against other paths that happen to contain a `/`):

```bash
grep '"GET / HTTP/1.1"' /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c
```

Searching for just `/` would match almost every line, since `/` appears in timestamps, paths, and even inside `HTTP/1.1` itself — anchoring the search to the full request line (`"GET / HTTP/1.1"`) avoids that.

### Trying This on Real Traffic

Tested directly on a real rented server's access log, which already had genuine internet traffic — bots and scanners, not test requests:

```bash
grep "/favicon.ico" /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c
```

```text
      1 104.23.162.82
      1 141.101.105.88
      1 162.158.167.208
      1 162.159.115.35
```

**What this showed:** every IP appeared exactly once — no single source repeated its request to this path. This is a meaningful observation, not just a neutral one: in real security monitoring, this exact pipeline is used to spot the opposite pattern — an IP appearing with an unusually high count (e.g. `500 1.2.3.4`) is a signal of suspicious activity (brute-forcing, scraping, or a DDoS attempt). A flat, evenly-distributed count like the one above is what normal, low-volume bot/crawler traffic looks like — nothing to investigate further.

### Counting 404 Errors by Path

```bash
sudo grep " 404 " /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -nr
```

---

## 5. Editing Text with `sed`

`awk` is for selecting/extracting columns; `sed` (**s**tream **ed**itor) is for finding and replacing (or deleting) text.

### Basic Find & Replace

```bash
sed 's/old/new/' file.txt
```

Replaces the **first** match per line, prints the result to the screen — the file itself is **not modified**.

### Case Sensitivity

By default, `sed` is **case-sensitive** — `dunya` and `Dunya` are treated as different strings. Confirmed directly: in a line containing both `Dunya` and `dunya`, `sed 's/dunya/world/'` only replaced the lowercase one.

Use the `I` flag for case-insensitive matching:

```bash
sed 's/dunya/world/I'
```

This replaced both `Dunya` and `dunya` in the same test.

### Writing Changes to the File (`-i`)

```bash
sed -i 's/old/new/' file.txt
```

`-i` (in-place) makes the change permanent — without it, `sed` only prints to the screen and the file stays untouched.

### Deleting Lines

By line number:

```bash
sed '2d' file.txt        # deletes line 2
```

By pattern (deletes any line containing the match):

```bash
sed '/keyword/d' file.txt
```

Both confirmed directly on a 4-line test file — `sed '2d'` removed the second line, and `sed '/satir3/d'` removed whichever line contained that word, regardless of its position. Adding `-i` to either makes the deletion permanent.

---

## 📊 Command Reference

| Command                | Purpose                                             | Example                       | Notes                             |
| ---------------------- | --------------------------------------------------- | ----------------------------- | --------------------------------- |
| **`awk`**              | Extracts specific columns from structured text.     | `awk '{print $7}' access.log` |                                   |
| **`grep`**             | Filters lines matching a pattern.                   | `grep " 404 " access.log`     |                                   |
| **`tail -n`**          | Shows the last N lines, once.                       | `tail -n 50 access.log`       |                                   |
| **`tail -f`**          | Follows a file live, for new entries.               | `tail -f access.log`          |                                   |
| **`uniq -c`**          | Counts repeated adjacent lines.                     | `uniq -c`                     | Requires sorted input first.      |
| **`sort -nr`**         | Sorts numerically, descending.                      | `sort -nr`                    |                                   |
| **`sed 's/x/y/'`**     | Finds and replaces text (first match per line).     | `sed 's/old/new/'`            |                                   |
| **`sed 's/x/y/g'`**    | Replaces all matches in a line, not just the first. | `sed 's/old/new/g'`           |                                   |
| **`sed 's/x/y/I'`**    | Case-insensitive find & replace.                    | `sed 's/dunya/world/I'`       |                                   |
| **`sed -i`**           | Writes `sed` changes directly to the file.          | `sed -i 's/old/new/' file`    | Without it, output is print-only. |
| **`sed 'Nd'`**         | Deletes a specific line by number.                  | `sed '2d' file`               |                                   |
| **`sed '/pattern/d'`** | Deletes any line matching a pattern.                | `sed '/error/d' file`         |                                   |
| **`less`**             | Paginated viewer for large logs.                    | `less access.log`             |                                   |

---

ℹ️ _All commands tested locally on a real server._
