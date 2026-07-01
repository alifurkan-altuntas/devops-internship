# 🐚 Bash Scripting — Variables, Conditions, and a Disk Usage Alert

This document covers Bash variables, command substitution, numeric comparisons, and writing a small script that checks disk usage and warns if it crosses a threshold.

---

## 1. The Task

Write a script that checks disk usage and prints a warning if it exceeds 80%.

Expected output:

```
WARNING: Disk usage is 85%
```

---

## 2. Getting the Disk Usage Value

### Starting point: `df -h`

```bash
df -h /
```

Output:

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G  9.0G   10G   47% /
```

The `Use%` column is what's needed — but this output isn't directly usable in a script. It needs to be narrowed down to just the number.

### Isolating the right line

Using `NR==2` skips the header row and grabs only the data row:

```bash
df -h / | awk 'NR==2 {print $5}'
```

This gives just the `Use%` column value, e.g. `48%`.

### Stripping the `%` sign

```bash
df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1
```

`cut -d'%' -f1` splits the text using `%` as the delimiter and keeps the first part — leaving just the number (`48`).

### Storing it in a variable

```bash
usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
```

`$(...)` is command substitution — it runs the command and stores its output in the variable. No spaces are allowed around `=` when assigning a Bash variable (`name = "x"` fails, `name="x"` works).

---

## 3. Comparing the Value

Bash doesn't use `>` or `<` for numeric comparisons inside `[ ]` — it uses specific flags:

| Operator | Meaning          |
| -------- | ---------------- |
| `-gt`    | greater than     |
| `-lt`    | less than        |
| `-ge`    | greater or equal |
| `-le`    | less or equal    |
| `-eq`    | equal            |

```bash
if [ $usage -gt 80 ]; then
    echo "WARNING: Disk usage is ${usage}%"
fi
```

### A real error along the way

Writing this the first time produced:

```text
./disk_check.sh: line 4: [48: command not found
```

The cause: missing space between `[` and `$usage` — it had been written as `[$usage` instead of `[ $usage`. Bash's `[` is actually a command, and it needs a space on both sides to be recognized correctly; written without it, bash tried to run a (nonexistent) command literally named `[48`.

Fixing the spacing resolved it immediately.

---

## 4. Adding an `else` Branch

To get feedback either way (not just silence when under the threshold):

```bash
#!/bin/bash

usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)

if [ $usage -gt 80 ]; then
    echo "WARNING: Disk usage is ${usage}%"
else
    echo "OK: Disk usage is ${usage}%"
fi
```

The curly braces in `${usage}%` aren't strictly required everywhere, but they clearly mark where the variable name ends — useful right before a `%` sign that could otherwise blur into the variable name visually.

---

## 5. Why No Loop or Function Here

The task only needed to check a single value once — adding a `for` loop or wrapping it in a `function` wouldn't have served a real purpose for this specific script. Both make sense once there's an actual repeating or reusable need (e.g. checking multiple mount points, or running on a schedule via `cron`) — forcing them in just to "use everything" would have been artificial rather than useful.

---

## 📊 Command Reference

| Concept                  | Example                  | Purpose                                                      |
| ------------------------ | ------------------------ | ------------------------------------------------------------ |
| **Variable assignment**  | `name="value"`           | No spaces around `=`.                                        |
| **Command substitution** | `var=$(command)`         | Stores a command's output in a variable.                     |
| **`awk 'NR==2'`**        | `awk 'NR==2 {print $5}'` | Selects a specific line by number.                           |
| **`cut -d -f`**          | `cut -d'%' -f1`          | Splits text by a delimiter and picks a field.                |
| **Numeric comparison**   | `[ $a -gt $b ]`          | Bash's way of comparing numbers (`-gt`, `-lt`, `-eq`, etc.). |
| **`if`/`else`/`fi`**     | see above                | Bash conditional block; closed with `fi`, not `end`.         |
| **`chmod +x`**           | `chmod +x script.sh`     | Grants execute permission so the script can be run directly. |
| **`./script.sh`**        | `./script.sh`            | Runs an executable script in the current directory.          |

---

ℹ️ _Tested locally; the script checks `/` only — it isn't currently set up to run automatically (e.g. via `cron`), since that wasn't part of this task._
