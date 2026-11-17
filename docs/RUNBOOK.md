# SoftLadyLux: operations runbook

Commands assume the project folder (parent of `backend/` and `frontend/`) and
`COMPOSE="docker compose -f deploy/docker-compose.yml"`.

## Health
- `curl https://your-domain/api/v1/health/` → `{"status":"ok","database":"ok"}`.
- `scripts/smoke.sh https://your-domain` runs the post-deploy checks (add `-k` for a self-signed cert).
- `$COMPOSE ps` shows `healthy` for backend, frontend, nginx and worker.
- Logs: `$COMPOSE logs -f backend|worker|frontend|nginx` (rotated: 5 × 10 MB per service).

## Backups (SRS §9)
`scripts/backup.sh --mode all|db-only|media-only` (default `all`). The newest 14 of each kind are kept.
- **Daily schedule:** `$COMPOSE --profile backup up -d backup` runs `--mode all` every 24 hours into the
  `backups` volume. Look at them: `$COMPOSE run --rm --no-deps backup ls -l /app/backups` (or inspect the volume).
- **By hand:** `$COMPOSE exec backend scripts/backup.sh --mode db-only` (writes to `/app/backups` if
  `BACKUP_DIR` is set, else `./backups` inside the container).
- **Copy backups off the server** at least daily (object storage, another machine). A backup that lives
  only on the server is lost with the server. Example: `docker cp $(docker compose ... ps -q backup):/app/backups ./offsite`.
- Before every upgrade, run `--mode all`.

## Restore (tested drill)
Stop the app, restore into an **empty** database, then migrate. `restore.sh` refuses a non-empty database
or media folder unless `--force`.
```
$COMPOSE stop backend worker frontend nginx
# 1) fresh database
$COMPOSE exec db psql -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS softladylux; CREATE DATABASE softladylux;"
# 2) load the dump and the media archive
$COMPOSE run --rm --no-deps -v /path/to/backups:/restore:ro backend scripts/restore.sh --db /restore/db-YYYYMMDD-HHMMSS.sql.gz
$COMPOSE run --rm --no-deps -v /path/to/backups:/restore:ro backend scripts/restore.sh --media /restore/media-YYYYMMDD-HHMMSS.tar.gz
# 3) start; migrations and the cache table are applied on start
$COMPOSE up -d
$COMPOSE exec backend python manage.py check
```
Verify: sign in to admin, open Orders and Products, open a product photo, run `scripts/smoke.sh`.
**Run this drill on a copy before you need it, and again after major changes.** The last recorded drill is
at the bottom of this file.

## Migrations
- They run automatically when `backend` starts (`RUN_MIGRATIONS=1`). Run only **one** backend replica.
- Check pending ones: `$COMPOSE exec backend python manage.py showmigrations | grep "\[ \]"`.
- Undo a migration only from a backup taken before it: restore, then deploy the older code.

## Rotating secrets
- `SECRET_KEY`: change it in `backend/.env`, restart `backend worker`. All sessions and unused OTPs become invalid
  (people log in again). Nothing else is lost.
- `POSTGRES_PASSWORD`: change it inside PostgreSQL (`ALTER USER … PASSWORD`), then in `backend/.env` (both
  `POSTGRES_PASSWORD` and `DATABASE_URL`), then `$COMPOSE up -d`.
- SMS/SMTP credentials: Admin → Settings → SMS, or `backend/.env` (env wins), then restart `backend worker`.

## Common problems
| Symptom | Check |
|---|---|
| "We'll be right back" page | nginx is up but backend/frontend are not: `$COMPOSE ps`, then `logs frontend backend`. |
| Backend restarts and exits at once | `$COMPOSE logs backend`: the environment check lists unsafe values (`ERROR:` lines). Fix `backend/.env`. |
| 400 "Bad Request (400)" | The domain is missing from `ALLOWED_HOSTS`. |
| Admin or account forms fail with CSRF/403 | `CSRF_TRUSTED_ORIGINS` must contain the exact `https://` origin; `COOKIE_SECURE=true` needs HTTPS. |
| Photos upload fails (413) | nginx allows 30 MB per request; the product form sends 2 photos per request. Each file is limited to 5 MB. |
| Customers get no SMS | Admin → Settings → SMS is complete (API key, username, sender name, URL); use **Send test SMS** there to see the gateway reply. Check the MiMSMS balance. `$COMPOSE logs worker` for `OTP SMS … failed` / `Order SMS … failed`. |
| No emails | SMTP variables set and `EMAIL_BACKEND` is the SMTP backend; the owner mailbox is Admin → Settings → support email. Failures are logged and never block orders. |
| Queued tasks not running | `$COMPOSE logs worker`; restart it: `$COMPOSE restart worker`. |
| Disk filling up | Backups volume and media: delete old backups after copying them off; `docker system df`. |
| Settings/theme changes not showing | Public caches are cleared on save in a shared database cache; if stale, `$COMPOSE exec backend python manage.py shell -c "from django.core.cache import cache; cache.clear()"`. |

## Steadfast courier (SRS v1.7 §4.18)

Steadfast has **no sandbox**: every booking is a real parcel. Details: `docs/STEADFAST_API_NOTES.md`.

Go-live:
1. On the Steadfast dashboard → API, create a named key (e.g. "SoftLadyLux website").
2. Admin → Settings → Courier: paste the API key and secret key, save, press **Test connection**
   (both lines must show ✓). Auto-booking is on by default.
3. Steadfast dashboard → Webhook: callback URL = the address shown on the Courier tab
   (`https://<domain>/api/v1/webhooks/steadfast/`), auth token = generate one there, then paste the same
   token into Settings → Courier and save. The webhook needs the public HTTPS domain.
4. Live smoke test with the owner: confirm one low-value COD order, check it moves to Shipping with a
   tracking code, then cancel the parcel in the Steadfast dashboard.

Operations:
- Statuses also refresh every 2 hours (Django-Q schedule "Steadfast reconciliation"), so a missed
  webhook only delays an update. The worker container must be running.
- "Steadfast keys rejected" (CRR-06): a 401/403 paused every courier call to avoid Steadfast's 60-minute
  lockout. Fix the keys (or the account at Steadfast) and **save** Settings → Courier to resume.
- Orders flagged "Booking failed": open the order, fix the phone/address, press **Retry booking**, or
  ship by hand. The "To book" and "Courier attention" tabs on Orders list them.
- "Courier returning parcel" never restocks by itself: mark the order Returned when the goods arrive.
- Rotating keys: create a new key at Steadfast, paste it, save, Test connection, then revoke the old key.

## Drill record
| Date | Backup | Result |
|---|---|---|
| 2026-11-04 | `db-20261104-023803.sql.gz` + `media-…tar.gz` from the M6 test stack (non-root `app` user, PostgreSQL 16, `pg_dump` 16.15) | Restored into a fresh database: 10 key tables had identical row counts (users 1, products 8, variants 26, categories 8, media 20, palettes 12, pages 4, coupons 1, stock movements 26, audit log 4). A second restore over the populated database was refused (46 tables). Media restore: 20 of 20 files. **The first attempt failed** because the image shipped `pg_dump` 17 (its dump uses `SET transaction_timeout`, which PostgreSQL 16 rejects); the image now installs `postgresql-client-16`. |
