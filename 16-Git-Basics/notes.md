# 🔧 Git — Branching, Merging, and a Real Push Conflict

This document covers `git clone`, `git commit`, `git push`, `git branch`, and `git merge` — and a real debugging session that came out of testing them on this actual repo.

---

## 1. The Basic Git Workflow

```
Working Directory → Staging Area → Local Repository → Remote (GitHub)
   (your files)        (git add)      (git commit)        (git push)
```

This repo had already been using this flow throughout every phase — this section is mainly about the commands that hadn't come up yet: `clone`, `branch`, and `merge`.

### `git clone`

Downloads a full copy of a remote repository to the local machine:
```bash
git clone https://github.com/user/repo.git
```
Not used directly on this repo (it was created locally and connected to GitHub from the start), but this is the command that would be used to pull this exact repo down onto a different machine.

### `git commit` / `git push`

Already in regular use throughout this journal:
```bash
git add file
git commit -m "message"
git push origin main
```

---

## 2. Branching (Tested Live on This Repo)

A branch is an isolated line of work, separate from `main`, that doesn't affect `main` until explicitly merged.

### Creating and switching to a branch

```bash
git checkout -b test-branch
```
This creates `test-branch` and switches to it in one step.

### Confirming isolation

A file (`test-file.txt`) was committed on `test-branch`. Switching back to `main` and listing files showed the file **did not exist there** — proving the two branches are independent until merged:

```bash
git checkout main
dir
# test-file.txt is not listed here
```

### Merging back into `main`

```bash
git merge test-branch
```
Output:
```text
Updating 64cd35a..f41fc2a
Fast-forward
```

**Fast-forward** means `main` hadn't changed since the branch was created, so Git didn't need to create a real merge commit — it just moved `main`'s pointer forward to match `test-branch`. After this, `test-file.txt` appeared on `main` too.

### Cleaning up

```bash
git branch -d test-branch   # delete the now-merged branch
git rm test-file.txt        # remove the test file
git commit -m "clean up test branch demo file"
```

---

## 3. The Real Problem: Push Rejected, Then a Stuck Merge

### Push rejected

```bash
git push origin main
```
```text
! [rejected]        main -> main (fetch first)
hint: Updates were rejected because the remote contains work that you do not
have locally.
```

This meant GitHub's copy of `main` had changes that the local copy didn't — likely from something done outside this terminal session (e.g. via the GitHub web UI or GitHub Desktop). The standard fix is to pull first.

### Pull got stuck

```bash
git pull origin main
```

This time, instead of a clean fast-forward, both local and remote had diverged — Git needed to create a real merge commit, which requires a commit message. Git tried to open the configured editor to write that message:

```text
hint: Waiting for your editor to close the file...
"C:\Program Files\JetBrains\WebStorm 2022.2.3\bin\webstorm64.exe": No such file or directory
error: there was a problem with the editor
Not committing merge; use 'git commit' to complete the merge.
```

The configured editor (WebStorm) wasn't actually installed at that path — so Git couldn't open anything to write the message, and the merge was left half-done (changes pulled in, but not committed).

### Fixing the editor, then completing the merge

```bash
git config --global core.editor "notepad"
git commit
```

This time Notepad opened with an auto-generated merge message; saving and closing it completed the merge:
```text
[main e48d7b4] Merge branch 'main' of https://github.com/.../devops-internship
```

`git config --global` applies to every repository on the machine, not just this one — so this fixes the editor issue going forward, not just for this repo.

### Push succeeded

```bash
git push origin main
```
```text
1a7283e..e48d7b4  main -> main
```

---

## 4. Key Takeaways

- A rejected push usually means the remote has commits the local repo doesn't — `git pull` first, then push again.
- Not every merge is a simple fast-forward — if both sides changed independently, Git needs an actual merge commit (and a message for it).
- Git's editor setting (`core.editor`) matters more than it seems — if it points to something that isn't actually installed, merges/commits that need a message will hang.
- `git branch` (no arguments) only **lists** existing branches — it does not create one. Creating one requires a name: `git branch new-name`.

---

## 📊 Command Reference

| Command | Purpose |
| --- | --- |
| **`git clone <url>`** | Downloads a full copy of a remote repo locally. |
| **`git branch`** | Lists local branches (does *not* create one without a name). |
| **`git branch <name>`** | Creates a new branch. |
| **`git checkout -b <name>`** | Creates a new branch and switches to it in one step. |
| **`git merge <branch>`** | Merges the named branch into the branch currently checked out. |
| **`git pull`** | Fetches and merges remote changes into the local branch. |
| **`git push origin main`** | Sends local commits on `main` to the remote repository. |
| **`git config --global core.editor "notepad"`** | Sets the default editor Git uses for commit/merge messages, machine-wide. |

---

ℹ️ _Branching wasn't used for the rest of this repo's history — for a single person working alone on a learning journal, committing directly to `main` is simple and sufficient; branching adds value mainly in team settings or for isolating risky changes._
