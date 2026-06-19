# ⚙️ Phase 6: Linux Process Management & Signaling - Quiz Logs

This document tracks the comprehensive assessment results regarding process identification loops, native system observation frameworks, signaling mechanics, and dynamic CPU priority scheduling architectures.

---

## 📊 Performance Overview

- **Total Examination Questions:** 5
- **Correct Formulations:** 5
- **Discrepancies identified:** 0
- **Aggregated Metric Score:** 100%

---

## 📑 Itemized Question Diagnostics & Structural Verification

### Q1: High-efficiency precision PID extraction excluding pipe overhead.
- **Context Syntax:** Isolating the absolute PID of a process without generating substring noise from standard grep patterns.
- **Options:** A) `top -i` | B) `pidof dd` | C) `nice dd` | D) `pkill dd`
- **Your Selection:** **B**
- **Evaluation:** ✅ **Correct & Validated.** (Using `pidof` purges stream gürültüsü, returning raw index integers matching exact target binaries).

### Q2: Interactive resource tracing under air-gapped distribution boundaries.
- **Context Syntax:** Monitoring system metrics dynamically on minimalist installations without installing third-party utilities.
- **Options:** A) `ps -ef` | B) `killall` | C) `top` | D) `renice`
- **Your Selection:** **C**
- **Evaluation:** ✅ **Correct & Validated.**

### Q3: Enforcing absolute kernel-level termination loops for non-responsive registers.
- **Context Syntax:** Trapping and dropping a locked process that ignores standard lifecycle signals.
- **Options:** A) `-1` (SIGHUP) | B) `-9` (SIGKILL) | C) `-19` (SIGSTOP) | D) `-2` (SIGINT)
- **Your Selection:** **B**
- **Evaluation:** ✅ **Correct & Validated.** (Sinyal `-9` triggers an uncatchable SIGKILL execution line at the kernel scheduler layer).

### Q4: Configuring baseline cooperative priority parameters upon execution initialization.
- **Context Syntax:** Initiating a task under the lowest priority weight to protect concurrent processing nodes.
- **Options:** A) `-20` | B) `0` | C) `19` | D) `99`
- **Your Selection:** **C**
- **Evaluation:** ✅ **Correct & Validated.** (Sayısal değer `19` establishes maximum niceness / lowest scheduling priority weight).

### Q5: String-based process termination without referencing explicit PID mappings.
- **Context Syntax:** Issuing batch execution shutdowns utilizing human-readable text descriptors directly.
- **Options:** A) `pkill` | B) `ps aux` | C) `renice` | D) `nice`
- **Your Selection:** **A**
- **Evaluation:** ✅ **Correct & Validated.**

---
ℹ️ *Candidate telemetry metrics compiled and logged with maximum proficiency distinction score.*