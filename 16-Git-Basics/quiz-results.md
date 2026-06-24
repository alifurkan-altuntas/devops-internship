# 📊 Phase 16 Quiz Results — Git

**Score: 14/15 (93%)** — 1 incorrect

---

**1. What does `git clone` do?**
A) Creates a new branch
B) Downloads a complete copy of a remote repository to your local machine
C) Deletes a repository
D) Merges two branches

**My answer: B** ✅

---

**2. What is the correct order of the basic Git workflow?**
A) `git push` → `git add` → `git commit`
B) `git add` → `git commit` → `git push`
C) `git commit` → `git add` → `git push`
D) `git push` → `git commit` → `git add`

**My answer: B** ✅

---

**3. What does `git branch` (with no arguments) do?**
A) Creates a new branch
B) Deletes the current branch
C) Lists all local branches, marking the current one
D) Pushes branches to the remote

**My answer: A** ❌
**Correct answer: C**

---

**4. What does `git checkout -b new-branch` do?**
A) Only creates a new branch, without switching to it
B) Creates a new branch AND switches to it immediately
C) Deletes a branch named "new-branch"
D) Merges into a branch named "new-branch"

**My answer: B** ✅

---

**5. After creating a commit on a separate branch, why didn't that change show up on `main`?**
A) Git automatically syncs all branches
B) Branches are isolated — a commit on one branch doesn't affect another until merged
C) The commit failed silently
D) `main` was deleted

**My answer: B** ✅

---

**6. What does `git merge test-branch` do when run while on `main`?**
A) Deletes `test-branch`
B) Brings the changes from `test-branch` into the current branch (`main`)
C) Renames `main` to `test-branch`
D) Pushes `main` to `test-branch`

**My answer: B** ✅

---

**7. What does a "Fast-forward" merge mean?**
A) Git skipped the merge entirely
B) `main` hadn't changed since the branch was created, so Git just moved the pointer forward — no real merge needed
C) The merge happened faster than usual due to file size
D) It means the merge failed

**My answer: B** ✅

---

**8. Why did `git push` get rejected with "the remote contains work you do not have locally"?**
A) The internet connection was too slow
B) The remote repository had changes (from another source) that weren't pulled into the local repo yet
C) The branch name was misspelled
D) GitHub blocked the account temporarily

**My answer: B** ✅

---

**9. What is the typical fix when `git push` is rejected for this reason?**
A) Force delete the remote repository
B) Run `git pull` first to bring in remote changes, then push again
C) Create a new repository
D) Rename the branch

**My answer: B** ✅

---

**10. Why did `git pull` get stuck with "Waiting for your editor to close the file"?**
A) The internet disconnected
B) The merge required a commit message, and Git tried to open a configured editor that didn't exist on the system
C) The repository was corrupted
D) `git pull` doesn't support merges

**My answer: B** ✅

---

**11. What does `git config --global core.editor "notepad"` do?**
A) Only affects the current repository
B) Sets Notepad as Git's default editor for all repositories on this machine
C) Installs Notepad
D) Deletes the previous editor setting permanently with no way to change it again

**My answer: B** ✅

---

**12. Why was a fast-forward merge not possible the second time (during the `pull`)?**
A) `main` had changed on the remote at the same time as local changes were made, so Git needed a real merge commit
B) The branch was deleted
C) The internet connection failed
D) `git pull` never produces fast-forwards

**My answer: A** ✅

---

**13. What does `git rm filename` do, as used in this phase?**
A) Only deletes the file from the working directory, Git ignores it
B) Removes the file and stages that removal for the next commit
C) Permanently deletes the file from all of Git's history
D) Renames the file

**My answer: B** ✅

---

**14. What is the main real-world reason to use branches in a team setting?**
A) To make commits load faster
B) So multiple people can work on different things in parallel without disrupting the main, stable codebase
C) Branches are required by GitHub for any repository
D) To reduce repository file size

**My answer: B** ✅

---

**15. In this phase's scenario, why wasn't using a separate branch (instead of committing directly to `main`) strictly necessary for this specific personal repo?**
A) Git doesn't allow branches in personal repos
B) For a single person working alone on a learning journal, branching adds complexity without a corresponding real benefit at this scale
C) Branches only work with `git clone`
D) `main` cannot be modified directly

**My answer: B** ✅

---

## Note on the miss

**Q3:** Mixed up `git branch` (no arguments) with `git branch <name>`. The no-argument version only *lists* existing branches — it doesn't create one. This was actually used correctly during the hands-on part of this phase (`git branch` was run right after creating `test-branch` with a separate command, and it correctly just listed both branches) — the mix-up was only in answering the question itself, not in the actual command usage.

---

ℹ️ _All answers given without revisiting or correcting after submission._
