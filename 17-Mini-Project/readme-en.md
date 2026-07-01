# 🚀 Mini Project — Nginx, Docker, Git & SSH on a Real Server

This document covers setting up a real rented Linux server (not a local VM) with Nginx, Docker, Git, and SSH key-based access, and publishing a simple static web page pulled from this repository via Git.

---

## 1. Initial Access & User Setup

Connected to the server initially as `root`. Following the Least Privilege principle from earlier phases, created a separate sudo-enabled user instead of working as root directly:

```bash
adduser altun
usermod -aG sudo altun
```

`adduser` (interactive) was used instead of `useradd` for convenience — it prompts for a password and basic info directly.

Verified group membership:

```bash
groups altun
```

---

## 2. SSH Key-Based Access

Switched into the new user and set up passwordless SSH access, the same way as the original SSH phase — just this time on a real server instead of a Vagrant VM:

```bash
su - altun
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys   # pasted the local machine's public key here
chmod 600 ~/.ssh/authorized_keys
```

Verified from the local machine:

```bash
ssh altun@<server_ip>
```

Connected without a password prompt (only the key's own passphrase, if set).

---

## 3. Installing Nginx

```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl status nginx
```

Ubuntu enables and starts Nginx automatically right after install (consistent with what was observed in the earlier Service Management phase). Verified with:

```bash
curl localhost
```

and by visiting the server's IP in a browser, confirming the default "Welcome to nginx!" page.

---

## 4. Installing Docker

Followed Docker's official installation steps for Ubuntu (using the current `.sources` format from their documentation, rather than the older `.list`/`.gpg` method):

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verified the daemon was running and tested with the standard hello-world image:

```bash
sudo systemctl status docker
sudo docker run hello-world
```

Output confirmed: _"Hello from Docker! This message shows that your installation appears to be working correctly."_

Docker commands were run with `sudo` throughout — the daemon's socket is root-owned by default. (Adding the user to the `docker` group to skip `sudo` is possible via `usermod -aG docker altun`, but `sudo` was kept deliberately here for clarity about when root access is actually being used.)

---

## 5. Installing Git and Cloning This Repository

```bash
sudo apt install git -y
git --version
git clone https://github.com/alifurkan-altuntas/devops-internship.git
```

This pulled the entire training repository — including this mini-project's `index.html` — onto the server.

---

## 6. Publishing the Web Page

Nginx serves files from `/var/www/html/` by default. The page from this repo was copied there manually:

```bash
sudo cp ~/devops-internship/17-Mini-Project/index.html /var/www/html/index.html
```

### 🔍 A Real Gotcha: Source File vs. Served File

The cloned repo (`~/devops-internship/...`) and the file Nginx actually serves (`/var/www/html/index.html`) are **two separate copies**, not the same file. Running `git pull` to get an updated version only updates the repo copy — it does **not** automatically update what Nginx is serving.

This came up directly: the HTML was edited and pushed to GitHub, then `git pull` was run on the server — but the live page still showed the old version, because the `cp` step had been skipped. Re-running the copy command fixed it:

```bash
cd ~/devops-internship
git pull
sudo cp ~/devops-internship/17-Mini-Project/index.html /var/www/html/index.html
```

In a real production setup, this manual step is usually automated — either with a symlink (so Nginx points directly at the repo file, no copy needed), a small deploy script, or a CI/CD pipeline. For this project, the manual `cp` was kept intentionally simple, but understanding _why_ the extra step exists matters more than skipping it.

### Another Real Issue: `https://` vs `http://`

Visiting the server in a browser via `https://<ip>` returned "refused to connect," while `curl localhost` on the server worked fine. The cause: only port 80 (HTTP) was ever configured — no TLS certificate or port 443 listener was set up, so HTTPS had nothing to connect to. Browsing to `http://<ip>` explicitly resolved it. (This is the same category of mistake as the 502 error from the earlier Proxy phase — the service was working, but the request was going to the wrong place.)

---

## 📊 What's Running on This Server

| Component  | Status                              | Notes                                                                       |
| ---------- | ----------------------------------- | --------------------------------------------------------------------------- |
| **Nginx**  | Active, serving on port 80          | No HTTPS/TLS configured                                                     |
| **Docker** | Active, verified with `hello-world` | Commands run with `sudo`                                                    |
| **Git**    | Installed, repo cloned              | Source files separate from what's served                                    |
| **SSH**    | Key-based only                      | Password login not disabled in this phase, but key access confirmed working |
| **User**   | `altun`, sudo-enabled, non-root     | Created instead of working directly as root                                 |

---

ℹ️ _This was done on a real rented server, not a local VM — the core commands were identical to earlier phases, but the consequences of mistakes (firewall, DNS, exposed services) are real here in a way a sandboxed Vagrant VM doesn't fully replicate._
