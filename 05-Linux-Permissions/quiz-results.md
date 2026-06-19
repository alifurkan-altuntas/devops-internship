# 🧠 Phase 5: Linux Permissions & Security Hardening - Quiz Logs

This document tracks the comprehensive assessment results regarding user mask configurations, identity alignment processes, resource group segregation, and special authorization boundaries.

---

## 📊 Performance Overview

- **Total Examination Questions:** 5
- **Correct Formulations:** 4
- **Discrepancies identified:** 1
- **Aggregated Metric Score:** 80% (Highly Proficient Level Reached)

---

## 📑 Itemized Question Diagnostics & Structural Post-Mortem

### Q1: Volatile `umask 077` applied to standard data file tracking.
- **Context Syntax:** Following an explicit `umask 077` hardening routine, a file resource `enterprise.conf` is generated via `touch`.
- **Options:** A) 755 | B) 644 | C) 600 | D) 700
- **Your Selection:** **D**
- **Evaluation:** ❌ **Incorrect**
- **Post-Mortem Analysis:** Standard file assets fall back to a baseline computational masking ceiling of `666` (excluding execution flags for protection loops). Subtracting the active template filter ($666 - 077$) isolates the resulting security matrix explicitly to **600 (`rw-------`)**. Selection `D` represents directory computation parameters ($777 - 077 = 700$), making it a minor mathematical base mismatch.

### Q2: Recursive batch ownership translation on `/var/www/html`.
- **Context Syntax:** Reassigning user ownership rules dynamically down an active file tree matrix in a single operation.
- **Options:** A) `sudo chown altun /var/www/html` | B) `sudo chown -R altun /var/www/html` | C) `sudo chgrp -R altun /var/www/html` | D) `sudo chmod 755 /var/www/html`
- **Your Selection:** **B**
- **Evaluation:** ✅ **Correct & Validated.** (The uppercase `-R` flag properly applies recursive tree traversal logic).

### Q3: Targeted group migration while preserving primary identity owners.
- **Context Syntax:** Modifying group assignments exclusively without disrupting user identification mappings.
- **Options:** A) `chmod` | B) `chown` | C) `umask` | D) `chgrp`
- **Your Selection:** **D**
- **Evaluation:** ✅ **Correct & Validated.**

### Q4: Target directory layout computation under enterprise `umask 022`.
- **Context Syntax:** Determining the active directory permission footprint following a `mkdir` instruction under defaults.
- **Options:** A) 755 (`rwxr-xr-x`) | B) 644 (`rw-r--r--`) | C) 777 (`rwxrwxrwx`) | D) 700 (`rwx------`)
- **Your Selection:** **A**
- **Evaluation:** ✅ **Correct & Validated.** (Directory calculations accurately utilize the `777` base: $777 - 022 = 755$).

### Q5: Functional structural capabilities of the `chown` management layer.
- **Context Syntax:** Evaluating ownership and permission assignment parameters within enterprise systems.
- **Options:** A) Limited to `rwx` flags | B) Capable of reassigning user and group arrays side-by-side using `owner:group` layouts | C) Available to unprivileged user profiles globally | D) Bound to specific distribution families
- **Your Selection:** **B**
- **Evaluation:** ✅ **Correct & Validated.**

---
ℹ️ *Candidate telemetry metrics compiled and logged into active systems administration audit pathways.*