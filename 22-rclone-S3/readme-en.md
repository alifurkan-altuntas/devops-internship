# 🗄️ rclone & Amazon S3 — Cloud Storage and Secure Access

I hadn't used S3 before — this phase taught me both S3 and rclone at the same time.

---

## What S3 Is

Amazon S3 (Simple Storage Service) is a cloud-based file storage service. Unlike a regular disk — files live on the internet, accessible from anywhere via URL. No CPU, no operating system, just storage. Store as much as you want, Amazon handles it. You pay for what you use.

Every S3 bucket is **private** by default — nobody can access it without credentials. Those credentials are an AWS Access Key + Secret Key pair.

---

## What rclone Is

A bridge for cloud storage services — supports dozens of providers including Google Drive, S3, and Dropbox. Handles file copying, syncing, and encryption.

**Example:** You have a computer at home and one at the office — you want the same files on both. Instead of carrying a USB drive, you sync both to S3 with rclone. S3 sits in the middle as the bridge.

---

## Installation and S3 Connection

```bash
curl https://rclone.org/install.sh | sudo bash
rclone config
```

During configuration I selected region `eu-central-1` (Frankfurt). I made a mistake here — for the location constraint I typed `EU` instead of `eu-central-1`. I assumed `EU` would cover all European regions, but that's not how it works — the region and location constraint have to match exactly. The first upload attempt gave this error:

```
api error IllegalLocationConstraintException: The EU location constraint is incompatible
for the region specific endpoint this request was sent to.
```

Switching to `eu-central-1` fixed it.

Testing the connection:

```bash
rclone ls s3:alifurkan-devops
# (empty bucket, no output — connection working)
```

---

## Performance Parameters

### `--transfers N` — Parallel Transfers

How many files are transferred in parallel. Default is 4.

**Example:** Should the library have one assistant or sixteen? One person carries each book one at a time, sixteen people carry sixteen at once. `--transfers 16` means sixteen workers running in parallel. S3 and similar services handle 16-32 parallel transfers comfortably.

### `--checkers N` — Parallel Checks

How many files are checked in parallel. Default is 8. When syncing large directories, the bottleneck is often the checking phase, not the transfer itself.

**What bottleneck means here:** Sometimes finding which files are missing or changed takes longer than actually transferring them. Like in a library — before you can carry books, you have to figure out which ones are missing. If that search is slow, it doesn't matter how fast the carrying is.

### `--buffer-size SIZE` — Memory Buffer

How much memory is held per transfer. Default is 16MB.

**Example:** The size of the basket each worker carries — too large and it becomes harder to handle. Testing with 64MB caused overhead: 10 files × 64MB = 640MB RAM allocation, and it was actually slower. 16MB is more balanced.

### `--fast-list` — Fast Directory Listing

Lists the directory with a single API call instead of many. Saves minutes on buckets with millions of files, but uses more RAM.

**Example:** Normally rclone walks through folders one by one, checking each section of the warehouse as it goes. With `--fast-list` it grabs the entire list in one shot — fast, but it has to hold that list in RAM. Like pulling all the items you'll need close to you before starting work — easy to reach, but takes up space.

### `--bwlimit` — Bandwidth Limit

**Note:** the unit is Byte/s, not bit/s.

```
To use half of a 10 Mbit/s connection:
5 Mbit/s ÷ 8 = 0.625 MB/s → --bwlimit 0.625M
```

**Example:** One water pipe in the house serves both drinking water and garden irrigation. Open it fully for the garden and there's nothing left inside. Without a limit, rclone can consume all available bandwidth and leave nothing for other processes — `--bwlimit` says "use this much, leave the rest."

### Test Results

10 files × 5MB each (50MB total):

**Test 1 — Default vs performance parameters:**

```bash
time rclone copy ~/test-files s3:alifurkan-devops/test1 -P
# Elapsed time: 1.1s / real: 1.507s

time rclone copy ~/test-files s3:alifurkan-devops/test2 -P \
  --transfers 16 --checkers 16 --buffer-size 16M --fast-list
# Elapsed time: 1.0s / real: 1.373s
```

**Test 2 — `--fast-list` in isolation:**

```bash
time rclone copy ~/test-files s3:alifurkan-devops/test1 -P --transfers 4
# Elapsed time: 1.4s / real: 1.851s / Speed: 39 MB/s

time rclone copy ~/test-files s3:alifurkan-devops/test2 -P --transfers 4 --fast-list
# Elapsed time: 1.0s / real: 1.400s / Speed: 50 MB/s
```

|           | Without `--fast-list` | With `--fast-list` |
| --------- | --------------------- | ------------------ |
| **Time**  | 1.851s                | 1.400s             |
| **Speed** | 39 MB/s               | 50 MB/s            |

`--fast-list` made a 25% difference even with a small number of files — the listing overhead was bigger than expected.

The difference between default and full performance parameters was small because the files are small and few. The first attempt used `--buffer-size 64M` and was actually slower — 640MB RAM allocation created overhead. Dropping to 16M balanced it out.

**Performance parameters make a real difference with hundreds of files or GB-scale data.** Adjust parameters based on file size and connection, not blindly.

---

## `rclone serve http` — Exposing a Private S3 Bucket

The S3 bucket is private — nobody can access it without credentials. But some users need access to the files. Handing out AWS credentials to everyone is risky and hard to manage — if someone leaves, you have to revoke their key.

The solution: put rclone in the middle.

```
User → rclone (HTTP) → Private S3 (with AWS credentials)
```

**Example:** A private library that requires a membership card to enter. You put an assistant at the door — the assistant has the card (AWS credentials), goes in, and brings back the requested file. People outside can't enter without a card, but they can ask the assistant to fetch files. Users never even know S3 exists.

```bash
rclone serve http s3:alifurkan-devops --addr :8090
```

Visiting `http://91.151.88.38:8090` from a browser showed the S3 folders and files — nobody used AWS credentials directly, nobody knew about S3.

```
http://91.151.88.38:8090           → test1/ and test2/ folders listed
http://91.151.88.38:8090/test1/    → 10 × 5.00 MiB files visible (file1.bin - file10.bin)
http://91.151.88.38:8090/test2/    → same files, different folder
```

![Root — test1 and test2 folders](images/browser-root.png)
![test1 folder contents](images/browser-test1.png)
![test2 folder contents](images/browser-test2.png)

The S3 bucket is still private — but through rclone, anyone could browse it.

**Why this matters:**

- AWS credentials stay on the server, inside rclone — users never see S3
- Who connected and when shows up in rclone's logs
- To revoke access, just stop rclone — no need to touch the AWS key

You can give people access without giving them credentials, and still see exactly who connected from where.

This is the same logic as Nginx's reverse proxy — users see only the front-facing layer, never the system behind it.

---

## `rclone mount` — Using S3 as a Local Disk

While `rclone serve http` serves S3 over HTTP, `rclone mount` attaches S3 to the system as if it were a local disk. Going into `/mnt/s3` shows the S3 files as if they were on your own disk.

### Setup

```bash
sudo mkdir -p /mnt/s3
sudo chown altun:altun /mnt/s3
```

### Mount Without Cache

```bash
rclone mount s3:alifurkan-devops /mnt/s3 --daemon
```

**`--daemon`** — run in the background. Doesn't block the terminal, returns immediately after starting.

```bash
ls /mnt/s3
# test1  test2
```

Every read goes to S3:

```bash
time cat /mnt/s3/test1/file1.bin > /dev/null
# real 0m1.247s
```

### Mount With Cache

```bash
fusermount3 -u /mnt/s3   # unmount first

rclone mount s3:alifurkan-devops /mnt/s3 \
  --vfs-cache-mode full \
  --vfs-cache-max-size 2G \
  --vfs-cache-max-age 24h \
  --daemon
```

- **`--vfs-cache-mode full`** → cache both reads and writes
- **`--vfs-cache-max-size 2G`** → use up to 2GB of disk for cache
- **`--vfs-cache-max-age 24h`** → remove cache entries not accessed in 24 hours

**Example:** Like taking an item from the back of the warehouse and putting it on the nearby shelf — the first time you have to go all the way to the back (takes time), but after that you always grab it from the nearby shelf (fast). `--vfs-cache-max-age` is "how long does it stay on the nearby shelf" — when the time runs out, clear it off, and go back to the warehouse next time it's needed. Same logic as TTL in Redis.

### Test Results

```bash
time cat /mnt/s3/test1/file1.bin > /dev/null   # first read
# real 0m2.047s  → downloaded from S3, written to cache

time cat /mnt/s3/test1/file1.bin > /dev/null   # second read
# real 0m0.030s  → served from cache (42x faster)
```

Tested with `--vfs-cache-max-age 10s` — after 10 seconds the cache expired and the file was re-downloaded from S3:

| Read    | Time    | What happened                                           |
| ------- | ------- | ------------------------------------------------------- |
| 1st     | 2.322s  | Downloaded from S3, written to cache                    |
| 2nd–7th | ~0.030s | Served from cache                                       |
| 8th     | 1.354s  | 10 seconds passed, cache expired, re-downloaded from S3 |

### Unmounting

```bash
fusermount3 -u /mnt/s3
```

### Basic Commands

```bash
# List bucket contents
rclone ls s3:alifurkan-devops

# List directories (including subdirectories)
rclone lsd s3:alifurkan-devops

# Upload local files to S3
rclone copy ~/test-files s3:alifurkan-devops/test -P

# Download from S3 to local
rclone copy s3:alifurkan-devops/test ~/downloaded -P

# Sync source to destination (deletes extra files on destination)
rclone sync ~/test-files s3:alifurkan-devops/backup -P

# Delete a folder from S3
rclone delete s3:alifurkan-devops/test --rmdirs

# Serve private S3 over HTTP
rclone serve http s3:alifurkan-devops --addr :8090

# Mount S3 as a local disk
rclone mount s3:alifurkan-devops /mnt/s3 --daemon

# Mount with cache
rclone mount s3:alifurkan-devops /mnt/s3 \
  --vfs-cache-mode full \
  --vfs-cache-max-size 2G \
  --vfs-cache-max-age 24h \
  --daemon

# Unmount
fusermount3 -u /mnt/s3
```

### High-Performance Upload

```bash
# Performance-tuned upload
rclone copy ~/large-folder s3:alifurkan-devops/backup -P \
  --transfers 16 \
  --checkers 16 \
  --buffer-size 16M \
  --fast-list

# Bandwidth-limited upload (to avoid overloading the server)
rclone copy ~/folder s3:alifurkan-devops/backup \
  --bwlimit 5M \
  --transfers 4
```

### Parameter Reference

| Parameter            | Default | Purpose                           |
| -------------------- | ------- | --------------------------------- |
| `--transfers N`      | 4       | Number of parallel file transfers |
| `--checkers N`       | 8       | Number of parallel file checks    |
| `--buffer-size SIZE` | 16M     | In-memory buffer per transfer     |
| `--fast-list`        | —       | List with a single API call       |
| `--bwlimit`          | —       | Bandwidth limit (Byte/s)          |
| `-P`                 | —       | Show progress                     |

---

## `rclone serve http` — Cache and Security

### Why Cache is Necessary

Tested without cache first — sent 10 parallel requests, it froze for a moment, took 9 seconds. Then ran the same test with cache on and it finished in 0.194 seconds. Every request hitting S3 directly slows things down that much — 10 users asking for the same file means 10 separate requests to S3, slow and expensive.

**Counter analogy:** Every customer walks in and you go to the back of the warehouse to get the same product. With cache, after the first customer you put it on the counter — the next customers get it from there, no more warehouse trips.

```bash
# With cache — 10 parallel requests
time (for i in {1..10}; do
  curl -s -u admin:pass http://localhost:8090/test1/file1.bin > /dev/null &
done; wait)
# real 0m0.194s

# Without cache — same test
# real 0m9.033s
```

**46x faster** — just by enabling cache.

### VFS Cache Parameters

```bash
rclone serve http s3:alifurkan-devops --addr :8090 \
  --vfs-cache-mode full \
  --vfs-cache-max-size 10G \
  --vfs-cache-max-age 24h \
  --dir-cache-time 1h \
  --buffer-size 32M \
  --rc --rc-addr :5572 --rc-no-auth \
  --log-file ~/rclone-http.log \
  --log-level INFO &
```

| Parameter                  | Description                                                                 |
| -------------------------- | --------------------------------------------------------------------------- |
| `--vfs-cache-mode full`    | Cache files to disk — stop hitting S3 constantly                            |
| `--vfs-cache-max-size 10G` | Max 10GB disk for cache — evict least-used when full                        |
| `--vfs-cache-max-age 24h`  | Remove files not accessed in 24 hours — taking up counter space for nothing |
| `--dir-cache-time 1h`      | Cache directory listings for 1 hour                                         |
| `--buffer-size 32M`        | Pre-load 32MB per file in RAM                                               |
| `--rc --rc-addr :5572`     | Enable remote control on port 5572                                          |
| `--rc-no-auth`             | No auth required for remote control                                         |
| `--log-file`               | Write logs to file                                                          |

### Dir Cache — Why New Files Don't Appear Immediately

Uploaded `tarayici.txt` to S3, it didn't show up in the browser right away. Wasn't surprised — we had caching on, figured that was why. With `--dir-cache-time 1h`, the directory listing stays in cache for 1 hour, rclone doesn't check S3 again.

![New file not visible](images/nofile.png)

Cleared the cache with `rclone rc vfs/forget` and it appeared:

```bash
rclone rc vfs/forget
```

![File visible after cache cleared](images/file.png)

**Trade-off:** Longer `--dir-cache-time` means fewer requests to S3 but new files appear later. Shorter means new files appear faster but S3 gets hit more often. `vfs/forget` lets you balance between the two — clear manually when needed.

### Auth — Security

This won't be open to everyone in production. Using `--user` and `--pass` flags exposes the password in the command line and it ends up in logs too. For privacy, you can't leave the password visible, so used environment variables instead:

```bash
export RCLONE_USER=admin
export RCLONE_PASS=gizlisifre123

rclone serve http s3:alifurkan-devops --addr :8090 ...
```

This way the password shows up as `XXXX` in logs — not exposed.

Test results:

- Without auth → `401 Unauthorized`
- With auth → `200 OK`
- From browser → login screen appeared:

![Auth login screen](images/auth.png)

### Clearing Cache with Remote Control

With `--rc` I can manage rclone while it's running — no need to stop and restart to send commands like `vfs/forget`.

```bash
# Clear cache — new files appear immediately
rclone rc vfs/forget
```

**Shop intercom:** You can tell the manager "refresh the counter" while the shop is still open. `--rc` is that intercom, `rclone rc vfs/forget` is the "refresh the counter listing" command — no need to close the shop.

### Full Command for Production Use

```bash
export RCLONE_USER=admin
export RCLONE_PASS=gizlisifre123

rclone serve http s3:bucket-name --addr :8090 \
  --vfs-cache-mode full \
  --vfs-cache-max-size 10G \
  --vfs-cache-max-age 24h \
  --dir-cache-time 1h \
  --buffer-size 32M \
  --rc --rc-addr :5572 --rc-no-auth \
  --log-file ~/rclone-http.log \
  --log-level INFO
```

---

ℹ️ _All tests performed on a real Ubuntu VDS and Amazon S3 (eu-central-1)._
