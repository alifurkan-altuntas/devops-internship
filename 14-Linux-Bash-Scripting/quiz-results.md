# 📊 Phase 14 Quiz Results — Bash Scripting

**Score: 15/15 (100%)**

---

**1. In Bash, how do you assign a value to a variable?**
A) `name = "altun"`
B) `name="altun"`
C) `var name = "altun"`
D) `let name = "altun"`

**My answer: B** ✅ — no spaces around `=`

---

**2. What does `$(...)` do in Bash?**
A) Starts a comment
B) Runs the command inside and substitutes its output
C) Declares a new variable
D) Escapes special characters

**My answer: B** ✅

---

**3. In `usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)`, what does `cut -d'%' -f1` do?**
A) Deletes the entire line containing `%`
B) Splits the text using `%` as the delimiter and takes the first field
C) Counts how many `%` symbols exist
D) Replaces `%` with a space

**My answer: B** ✅

---

**4. Why was `NR==2` used instead of just printing every line with `awk`?**
A) To skip the header line and only process the data line
B) To print line 2 twice
C) To count the number of records
D) It has no effect, it's optional

**My answer: A** ✅

---

**5. Which syntax is correct for a numeric comparison in Bash's `if` statement?**
A) `if ($usage > 80)`
B) `if [$usage -gt 80]`
C) `if [ $usage -gt 80 ]`
D) `if usage -gt 80`

**My answer: C** ✅

---

**6. What does `-gt` mean in a Bash condition?**
A) Greater than
B) Greater type
C) Group test
D) Generate text

**My answer: A** ✅

---

**7. What was the actual cause of the `[48: command not found` error encountered while writing the script?**
A) The variable `usage` was empty
B) There was no space between `[` and `$usage`
C) `df` wasn't installed
D) The script had no shebang line

**My answer: B** ✅

---

**8. What is the shebang line (`#!/bin/bash`) used for?**
A) It's just a comment with no real effect
B) It tells the system which interpreter should run the script
C) It imports the bash library
D) It sets the script's file permissions

**My answer: B** ✅

---

**9. Which command is used to give a script execute permission?**
A) `chmod +r script.sh`
B) `chmod +x script.sh`
C) `chmod +w script.sh`
D) `sudo run script.sh`

**My answer: B** ✅

---

**10. How do you run a script that already has execute permission, from the same directory?**
A) `run script.sh`
B) `bash run script.sh`
C) `./script.sh`
D) `script.sh start`

**My answer: C** ✅

---

**11. In an `if/else` block, what happens if the `if` condition is false?**
A) The script stops immediately with an error
B) Nothing happens at all, ever
C) The code inside `else` runs instead
D) Both `if` and `else` blocks run

**My answer: C** ✅

---

**12. Which keyword closes a Bash `if` statement?**
A) `end`
B) `endif`
C) `fi`
D) `done`

**My answer: C** ✅

---

**13. In `echo "WARNING: Disk usage is ${usage}%"`, why are the curly braces `{}` used around `usage`?**
A) They're required for all variables, with no exceptions
B) They clearly separate the variable name from the following text (here, the `%` sign)
C) They convert the variable to a string
D) They have no real purpose, just a style choice

**My answer: B** ✅

---

**14. If you wanted this script to run automatically every hour without manual execution, which tool would you use?**
A) `systemctl restart`
B) `cron` (via `crontab`)
C) `chmod`
D) `awk`

**My answer: B** ✅

---

**15. Why didn't this script need a `for` loop or a `function`?**
A) Bash doesn't support loops or functions
B) The task only required checking a single value once, so a loop/function wasn't a natural fit
C) Loops and functions are deprecated in modern Bash
D) `if` statements can't be used together with loops

**My answer: B** ✅

---

ℹ️ _All answers given without revisiting or correcting after submission._
