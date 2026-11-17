# SoftLadyLux: deployment guide

Hosting and domain are not decided, so this guide is generic: any Linux server with Docker and Docker
Compose v2 works. Services: `db` (PostgreSQL 16), `backend` (Django/Gunicorn), `worker` (Django-Q2),
`frontend` (Nuxt), `nginx`. There is no Redis. Only nginx publishes ports.

## 1. Server
- Linux with Docker Engine 24+ and the Compose plugin; 2 vCPU, 2 GB RAM, 20 GB disk is enough to start
  (SRS §9: up to 5,000 products, 50,000 orders a year, 100 concurrent shoppers on one server).
- Ports 80 and 443 open to the internet. Nothing else needs to be exposed (the database is internal).
- A domain name whose DNS A/AAAA record points at the server.
- Keep the system clock correct (NTP): OTP expiry and JWT lifetimes depend on it. The app uses Asia/Dhaka.

## 2. Get the code
```
git clone <backend repo>  backend
git clone <frontend repo> frontend
```
Both folders must sit side by side in one project folder. Run every command below from that folder.

## 3. Configure
```
cp backend/.env.production.example backend/.env
cp frontend/.env.production.example frontend/.env
```
Fill in every `REPLACE_ME` (each file explains its values). Generate secrets with
`python3 -c "import secrets; print(secrets.token_urlsafe(64))"`. **Never commit `.env`.**
The backend refuses to start while a value is unsafe (placeholder secret, `DEBUG=true`, default admin
path, open `ALLOWED_HOSTS`, insecure cookies). Check by hand:
```
docker compose -f deploy/docker-compose.yml run --rm --no-deps -e RUN_MIGRATIONS=0 backend python -m apps.core.envcheck
```
Warnings (console email, fake SMS) do not block but mean those features are not live yet.
Set `NUXT_PUBLIC_SITE_URL` in `frontend/.env` so sitemap and canonical URLs use the public origin.

## 4. TLS: pick one
**A. Nginx terminates TLS (default).** Put `fullchain.pem` and `privkey.pem` in `deploy/certs/`
(see the README there; the folder is git-ignored). Start:
```
docker compose -f deploy/docker-compose.yml up -d --build
```
Port 80 redirects to 443 (except `/api/v1/health/`, kept for uptime checks). HSTS is sent for this host only (not subdomains). To renew,
replace the two files and run `docker compose -f deploy/docker-compose.yml exec nginx nginx -s reload`.

**B. A provider proxy or load balancer terminates TLS.** The proxy must forward plain HTTP to port 80
and set `X-Forwarded-Proto: https`; only the proxy may reach that port.
```
docker compose -f deploy/docker-compose.yml -f deploy/docker-compose.proxy-tls.yml up -d --build
```
Django then sees HTTPS and sets HSTS and secure cookies.

Use `HTTP_PORT` / `HTTPS_PORT` to change the published ports.

## 5. First run
The backend applies migrations and creates the cache table on start. Wait for `healthy`:
```
docker compose -f deploy/docker-compose.yml ps
```
Create the Owner account (password from a prompt, or `OWNER_PASSWORD` in the environment):
```
docker compose -f deploy/docker-compose.yml exec backend python manage.py create_owner --email owner@your-domain --name "Owner Name"
```
Sign in at `https://your-domain/admin/login`, then fill **Settings** (company, address, phone, support
hours, WhatsApp/Messenger, bKash/Nagad numbers, delivery fees, GTM ID, SMS) and upload the logo, slides
and products. Until real values are entered the storefront shows clearly marked `[PLACEHOLDERS]`.

## 6. Staging
Use a separate server (or the same server with another project name and ports) and a staging
domain. For realistic content run the demo seed there only:
```
docker compose -f deploy/docker-compose.yml exec backend python manage.py seed_demo --i-know-this-is-not-production
```
(`--reset` hides the demo products again; they cannot be deleted because their stock history is
immutable.) The photos are generated line drawings. To use your own licensed photos add
`--photos-dir /path/to/folder` with files named like the product slug (for example
`silk-touch-plunge-bra-1.jpg`). Never run `seed_demo` on production. Then follow `docs/RELEASE_CHECKLIST.md`.

## 7. Upgrade
```
git -C backend pull && git -C frontend pull
docker compose -f deploy/docker-compose.yml up -d --build
```
Take a backup first (see `docs/RUNBOOK.md`). Migrations run automatically on backend start. Roll back by
checking out the previous commits, rebuilding, and (only if a migration must be undone) restoring the
backup taken before the upgrade.

## 8. What is configured where
| What | Where |
|---|---|
| Secrets, domain, cookies, SMTP, SMS, public site URL | `backend/.env` (server only) |
| Storefront API base and Nuxt image directory | `frontend/.env` (server only) |
| Company data, fees, payment numbers, social links, GTM ID, SMS credentials | Admin → Settings |
| Colours | Admin → Theme colours |
| Home page content, pages | Admin → Website content |
| Staff and permissions | Admin → Staff & permissions (Owner only) |
