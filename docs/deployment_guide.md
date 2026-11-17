# SoftLadyLux: deployment guide (step by step)

Server: `root@36.50.40.178` · Site: https://softladylux.com

You **don't need to push or pull on the server**. `deploy/deploy.sh` runs on your computer and copies
your local project files straight to the server, so the server never needs git. Pushing to GitHub is
only a backup copy for yourself (step 6).

Run every command on **your local computer**, in the project folder.

---

## First deploy

### Step 1: Go to the project folder
```bash
cd /home/mahbub/workspace/softladylux_project
```

### Step 2: Make sure your local database is running
The deploy copies your local data, so the local database has to be up:
```bash
docker compose -f deploy/docker-compose.dev.yml up -d db
```
Don't change anything in your local admin panel during the deploy, because the backup is taken at the start.

### Step 3: Create an SSH key (one time only)
Skip this if you already have one (`ls ~/.ssh/*.pub` shows a file). Press Enter at every question:
```bash
ssh-keygen -t ed25519
```

### Step 4: Install the key on the server (one time only)
It asks for the root password once. After this, no password is needed:
```bash
ssh-copy-id -p 22 root@36.50.40.178
```
Test it. It should print `ok` without asking for a password:
```bash
ssh root@36.50.40.178 echo ok
```

### Step 5: Run the deploy
```bash
./deploy/deploy.sh
```
It takes about 15–20 minutes, mostly the build. You'll see each stage tick off with ✓. At the end it prints
your site link and admin link.

**If it stops with ✗ FAILED:** read the red message, fix the problem, and run `./deploy/deploy.sh` again.
It continues from where it stopped. The full log of every run is in `deploy/logs/`.

### Step 6: Check the site, then back up the code
1. Open https://softladylux.com.
2. Log in at https://softladylux.com/admin/login with the same accounts you use locally.
3. Optional: push to GitHub as a backup:
```bash
git push origin main && git -C frontend push origin main
```

### Step 7: Change the root password
It was shared in plain text. Log in to the server and set a new one:
```bash
ssh root@36.50.40.178 passwd
```

---

## Later

### When you change code
Edit it locally, then run:
```bash
./deploy/deploy.sh --from 03 --skip-data
```
`--skip-data` makes sure your live production orders and products are never overwritten by local data.

### To turn on email
Put your SMTP details (`EMAIL_HOST`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, …) in
`/opt/project_workplace/softladylux_project/backend/.env` on the server, then run:
```bash
./deploy/deploy.sh --from 11 --skip-data
```

### If a changed image still shows the old version
This only happens if a file was overwritten by hand on the server; uploads from the admin panel never
need it:
```bash
./deploy/deploy.sh --purge-image-cache
```

---

## Quick reference

| Command | What it does |
|---|---|
| `./deploy/deploy.sh` | Full deploy; re-run it to continue after a failure |
| `./deploy/deploy.sh --status` | Show which stages are done |
| `./deploy/deploy.sh --from 06` | Re-run from stage 06 onward |
| `./deploy/deploy.sh --only 01` | Run a single stage |
| `./deploy/deploy.sh --from 03 --skip-data` | Code-only redeploy (production data untouched) |
| `./deploy/deploy.sh --force-db` | Replace a non-empty production database with the local backup (careful!) |
| `./deploy/deploy.sh --purge-image-cache` | Empty the resized-image cache |
| `./deploy/deploy.sh --help` | Show all options |

**Stages:** 00 preflight · 01 local backup · 02 server setup · 03 copy code · 04 production settings ·
05 upload backup · 06 build · 07 start database · 08 restore database · 09 restore media ·
10 temporary certificate · 11 start everything · 12 Let's Encrypt certificate · 13 smoke test ·
14 daily backups · 15 summary.

For the technical details (what each file configures, manual commands), see `docs/DEPLOYMENT.md`.
