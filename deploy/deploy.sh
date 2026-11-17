#!/usr/bin/env bash
# SoftLadyLux: one-command production deploy, run from your LOCAL machine (project root or anywhere).
#
#   ./deploy/deploy.sh                     run every stage; on a re-run, resume where it failed
#   ./deploy/deploy.sh --status            show which stages are done
#   ./deploy/deploy.sh --from 06           re-run from stage 06 onward
#   ./deploy/deploy.sh --only 01           run one stage only
#   ./deploy/deploy.sh --from 03 --skip-data   later code-only redeploy: never touches prod data
#   ./deploy/deploy.sh --force-db          allow stage 08 to REPLACE a non-empty production database
#   ./deploy/deploy.sh --purge-image-cache empty nginx's resized-image cache (safe; images regenerate)
#
# What it does (SRS §9 deployment, backups, HTTPS): backs up the local dev database and media,
# prepares the server (Docker, swap, firewall, clock), syncs the code, writes production .env files,
# builds, restores the data into the production volumes, issues a Let's Encrypt certificate (certbot
# sidecar keeps renewing it), smoke-tests the live site and enables daily backups.
#
# Needs SSH key login (never a password in this script): run once  ssh-copy-id -p 22 root@<server>
# Settings below can be overridden by environment variables or by deploy/deploy.conf (git-ignored).
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[ -f deploy/deploy.conf ] && . deploy/deploy.conf

SERVER="${SERVER:-36.50.40.178}"
SSH_PORT="${SSH_PORT:-22}"
SSH_USER="${SSH_USER:-root}"
REMOTE_DIR="${REMOTE_DIR:-/opt/project_workplace/softladylux_project}"
REMOTE_BK="${REMOTE_BK:-/opt/project_workplace/backups}"   # outside REMOTE_DIR: rsync --delete never touches it
DOMAIN="${DOMAIN:-softladylux.com}"
LE_EMAIL="${LE_EMAIL:-softladylux@gmail.com}"
LOCAL_DB_CT="${LOCAL_DB_CT:-softladylux-dev-db}"
LOCAL_MEDIA_VOL="${LOCAL_MEDIA_VOL:-softladylux_media}"
PROD_MEDIA_VOL="softladylux-prod_media"   # compose project "softladylux-prod" + volume "media"
ALPINE="alpine:3.20"

STATE="deploy/.deploy-state"
BKDIR="deploy/backups"
LOGDIR="deploy/logs"
mkdir -p "$STATE" "$BKDIR" "$LOGDIR"
LOG="$LOGDIR/deploy-$(date +%Y%m%d-%H%M%S).log"

# ---------------------------------------------------------------------------------------------------
# Output helpers
if [ -t 1 ]; then B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; C=$'\e[36m'; N=$'\e[0m'; else B='' G='' Y='' R='' C='' N=''; fi
exec > >(tee -a "$LOG") 2>&1
say()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
die()  { printf '  %s✗ %s%s\n' "$R" "$*" "$N"; return 1; }   # non-zero return fires the ERR trap (resume hint)

CURRENT_STAGE=""
on_err() {
  local code=$? line=$1
  printf '\n%s✗ FAILED at stage %s (line %s, exit %s)%s\n' "$R$B" "${CURRENT_STAGE:-setup}" "$line" "$code" "$N"
  printf '  Log: %s\n  Fix the problem above, then re-run %s./deploy/deploy.sh%s: it resumes from this stage.\n' "$LOG" "$B" "$N"
  exit "$code"
}
trap 'on_err $LINENO' ERR
trap 'printf "\n%sInterrupted. Re-run ./deploy/deploy.sh to resume.%s\n" "$Y" "$N"; exit 130' INT

# ---------------------------------------------------------------------------------------------------
# SSH: one multiplexed connection for every remote command
CP="$HOME/.ssh/cm-softladylux-%r@%h:%p"
SSH_OPTS=(-p "$SSH_PORT" -o ControlMaster=auto -o "ControlPath=$CP" -o ControlPersist=10m
          -o ServerAliveInterval=30 -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new)
RSYNC_SSH="ssh -p $SSH_PORT -o ControlMaster=auto -o ControlPath=$CP -o ControlPersist=10m"
r() { ssh "${SSH_OPTS[@]}" "$SSH_USER@$SERVER" "$@"; }

# remote <<'EOF' ... EOF : run a bash script on the server with the settings and helpers predefined.
remote() {
  {
    printf 'set -Eeuo pipefail\n'
    printf '%s=%q\n' REMOTE_DIR "$REMOTE_DIR" REMOTE_BK "$REMOTE_BK" DOMAIN "$DOMAIN" WWW "$WWW" \
      LE_EMAIL "$LE_EMAIL" STAMP "${STAMP:-}" FORCE_DB "$FORCE_DB" SSH_PORT "$SSH_PORT" \
      PROD_MEDIA_VOL "$PROD_MEDIA_VOL" ALPINE "$ALPINE"
    cat <<'PRE'
ok()   { printf '  \e[32m✓\e[0m %s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf '  \e[33m!\e[0m %s\n' "$*"; }
die()  { printf '  \e[31m✗ %s\e[0m\n' "$*"; exit 1; }
dc()   { docker compose -f "$REMOTE_DIR/deploy/docker-compose.prod.yml" "$@"; }
psql_db() { docker exec -i softladylux-prod-db sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$@"' sh "$@"; }
wait_healthy() {  # wait_healthy <seconds> <container>...
  local t="$1"; shift; local end=$((SECONDS + t)) c s bad
  while :; do
    bad=""
    for c in "$@"; do
      s="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$c" 2>/dev/null || echo missing)"
      [ "$s" = healthy ] || [ "$s" = running ] || bad="$bad $c($s)"
    done
    [ -z "$bad" ] && return 0
    [ "$SECONDS" -ge "$end" ] && { warn "not healthy:$bad"; return 1; }
    sleep 5
  done
}
mkdir -p "$REMOTE_DIR"; cd "$REMOTE_DIR"
PRE
    cat
  } | ssh "${SSH_OPTS[@]}" "$SSH_USER@$SERVER" bash -s
}

# Exact per-table row counts; the same SQL runs locally (backup) and on the server (after restore).
COUNTS_SQL="select format('select %L, count(*) from public.%I', tablename, tablename) from pg_tables where schemaname = 'public' order by tablename \\gexec"

# ---------------------------------------------------------------------------------------------------
# Stages
STAGES=(
  "00:preflight" "01:local-backup" "02:server-bootstrap" "03:sync-code" "04:configure-env"
  "05:upload-backups" "06:build" "07:volumes-and-db" "08:restore-db" "09:restore-media"
  "10:temp-cert" "11:start-stack" "12:issue-cert" "13:smoke-test" "14:enable-backups" "15:summary"
)
ALWAYS=" 00 15 "            # run every time (checks / report), never marked done
DATA_STAGES=" 01 05 08 09 " # skipped by --skip-data
WWW=0
FORCE_DB=0
STAMP="$(cat "$STATE/stamp" 2>/dev/null || true)"

need_stamp() { [ -n "$STAMP" ] && [ -d "$BKDIR/$STAMP" ] || die "No local backup recorded. Run stage 01 first (./deploy/deploy.sh --only 01)."; }

stage_00() {
  local t missing=""
  for t in docker ssh rsync curl gzip sha256sum getent openssl; do command -v "$t" >/dev/null || missing="$missing $t"; done
  [ -z "$missing" ] || die "Missing local tools:$missing"
  ok "local tools present"

  local ips; ips="$(getent ahostsv4 "$DOMAIN" | awk '{print $1}' | sort -u | tr '\n' ' ' || true)"
  [[ " $ips " == *" $SERVER "* ]] || die "$DOMAIN resolves to '${ips:-nothing}', not $SERVER. Fix the DNS A record (Let's Encrypt needs it)."
  ok "$DOMAIN → $SERVER"
  if getent ahostsv4 "www.$DOMAIN" | awk '{print $1}' | grep -qx "$SERVER"; then
    WWW=1; ok "www.$DOMAIN → $SERVER (included in the certificate)"
  else
    info "www.$DOMAIN does not point here: certificate for $DOMAIN only (add an A record for www and re-run --from 12 to include it)"
  fi
  if command -v dig >/dev/null && [ -n "$(dig +short AAAA "$DOMAIN")" ]; then
    warn "$DOMAIN has an AAAA (IPv6) record: make sure it points at this server too, or remove it (Let's Encrypt prefers IPv6)."
  fi

  if ! ssh "${SSH_OPTS[@]}" -o BatchMode=yes "$SSH_USER@$SERVER" true 2>/dev/null; then
    ls "$HOME"/.ssh/id_*.pub >/dev/null 2>&1 || info "No SSH key yet. Create one:  ssh-keygen -t ed25519"
    die "SSH key login to $SSH_USER@$SERVER failed. Run once (it asks for the password):  ssh-copy-id -p $SSH_PORT $SSH_USER@$SERVER"
  fi
  ok "SSH key login to $SSH_USER@$SERVER"

  if [[ "$SKIP_DATA" != 1 ]]; then
    docker inspect -f '{{.State.Running}}' "$LOCAL_DB_CT" 2>/dev/null | grep -q true \
      || die "Local database container '$LOCAL_DB_CT' is not running. Start it: docker compose -f deploy/docker-compose.dev.yml up -d db"
    docker volume inspect "$LOCAL_MEDIA_VOL" >/dev/null 2>&1 || die "Local media volume '$LOCAL_MEDIA_VOL' not found."
    ok "local database and media volume found"
  fi
}

stage_01() {
  STAMP="$(date +%Y%m%d-%H%M%S)"
  local d="$BKDIR/$STAMP"; mkdir -p "$d"
  info "database dump from $LOCAL_DB_CT …"
  docker exec "$LOCAL_DB_CT" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner --no-privileges' | gzip -9 > "$d/db.sql.gz"
  gzip -t "$d/db.sql.gz"
  printf '%s\n' "$COUNTS_SQL" > "$d/counts.sql"
  docker exec -i "$LOCAL_DB_CT" sh -c 'psql -v ON_ERROR_STOP=1 -At -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < "$d/counts.sql" | sort > "$d/db.counts"
  local tables; tables="$(wc -l < "$d/db.counts")"
  [ "$tables" -gt 0 ] || die "The dump has no tables: is $LOCAL_DB_CT the right database?"
  ok "database: $(du -h "$d/db.sql.gz" | cut -f1), $tables tables"

  info "media archive from volume $LOCAL_MEDIA_VOL …"
  # The node-alpine image copied its empty cdrom/floppy/usb folders into the volume: leave them out.
  docker run --rm -v "$LOCAL_MEDIA_VOL":/m:ro "$ALPINE" \
    tar -czf - -C /m --exclude=./cdrom --exclude=./floppy --exclude=./usb . > "$d/media.tar.gz"
  gzip -t "$d/media.tar.gz"
  docker run --rm -v "$LOCAL_MEDIA_VOL":/m:ro "$ALPINE" sh -c \
    'cd /m && find . -type f ! -path "./cdrom/*" ! -path "./floppy/*" ! -path "./usb/*" | wc -l' | tr -d ' ' > "$d/media.count"
  [ "$(cat "$d/media.count")" -gt 0 ] || warn "the media volume has no files"
  ok "media: $(du -h "$d/media.tar.gz" | cut -f1), $(cat "$d/media.count") files"

  (cd "$d" && sha256sum db.sql.gz media.tar.gz db.counts counts.sql media.count > SHA256SUMS)
  echo "$STAMP" > "$STATE/stamp"
  ok "backup saved in $d"
}

stage_02() {
  remote <<'EOF'
export DEBIAN_FRONTEND=noninteractive
command -v apt-get >/dev/null || die "This script supports Debian/Ubuntu servers (apt-get not found)."
apt-get update -qq
apt-get install -y -qq rsync curl ca-certificates openssl >/dev/null
ok "base packages"
if ! command -v docker >/dev/null; then
  info "installing Docker (get.docker.com) …"
  curl -fsSL https://get.docker.com | sh >/dev/null
fi
systemctl enable --now docker >/dev/null 2>&1 || true
docker compose version >/dev/null || die "Docker Compose v2 plugin missing (apt-get install docker-compose-plugin)."
ok "$(docker --version | cut -d, -f1), $(docker compose version --short | sed 's/^/compose /')"

if [ -z "$(swapon --noheadings 2>/dev/null)" ]; then
  fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
  chmod 600 /swapfile; mkswap /swapfile >/dev/null; swapon /swapfile
  grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
echo 'vm.swappiness=10' > /etc/sysctl.d/99-softladylux.conf; sysctl -q -p /etc/sysctl.d/99-softladylux.conf
ok "swap: $(swapon --noheadings --show=SIZE | head -1 | tr -d ' ')"

timedatectl set-timezone Asia/Dhaka 2>/dev/null || true
timedatectl set-ntp true 2>/dev/null || true
ok "clock: $(date '+%Z %F %T') (NTP on)"

if command -v ufw >/dev/null; then
  ufw allow "$SSH_PORT"/tcp >/dev/null; ufw allow 80/tcp >/dev/null; ufw allow 443/tcp >/dev/null
  ufw --force enable >/dev/null
  ok "firewall: ports $SSH_PORT, 80, 443 open"
else
  info "ufw not installed: firewall left as is"
fi
free_gb=$(df -BG --output=avail / | tail -1 | tr -dc 0-9)
[ "$free_gb" -ge 5 ] || die "Only ${free_gb} GB free on /: need at least 5 GB."
ok "disk: ${free_gb} GB free"
EOF
}

stage_03() {
  info "rsync $ROOT → $SERVER:$REMOTE_DIR"
  # Excluded paths are never deleted on the server either: its .env files and certificates are safe.
  rsync -az --delete --human-readable --stats -e "$RSYNC_SSH" \
    --include='.env.example' --include='.env.production.example' \
    --exclude='.env' --exclude='.env.*' \
    --exclude='.git/' --exclude='node_modules/' --exclude='.nuxt/' --exclude='.output/' \
    --exclude='__pycache__/' --exclude='.pytest_cache/' --exclude='.ruff_cache/' --exclude='.coverage' \
    --exclude='/backend/media/' --exclude='/backend/staticfiles/' --exclude='/backend/backups/' \
    --exclude='/picture_to_upload/' --exclude='/docs/' --exclude='/prompt.txt' --exclude='/task.md' \
    --exclude='/deploy/backups/' --exclude='/deploy/.deploy-state/' --exclude='/deploy/logs/' \
    --exclude='/deploy/deploy.conf' --exclude='/deploy/certs/*.pem' \
    --info=stats1 ./ "$SSH_USER@$SERVER:$REMOTE_DIR/"
  ok "code synced"
}

stage_04() {
  remote <<'EOF'
gen() { openssl rand -base64 96 | tr -dc 'A-Za-z0-9' | head -c "$1"; }
ts=$(date +%Y%m%d-%H%M%S)
be=backend/.env
if [ -f "$be" ] && grep -q '^DJANGO_SETTINGS_MODULE=config.settings.prod' "$be"; then
  ok "backend/.env already set up for production: kept"
else
  [ -f "$be" ] && { mv "$be" "$be.dev-uploaded.$ts"; info "uploaded dev backend/.env moved to $be.dev-uploaded.$ts"; }
  secret=$(gen 64); dbpw=$(gen 32); admin="manage-$(gen 16)"
  hosts="$DOMAIN,www.$DOMAIN"; origins="https://$DOMAIN,https://www.$DOMAIN"
  sed -e "s|^SECRET_KEY=.*|SECRET_KEY=$secret|" \
      -e "s|^ALLOWED_HOSTS=.*|ALLOWED_HOSTS=$hosts|" \
      -e "s|^CSRF_TRUSTED_ORIGINS=.*|CSRF_TRUSTED_ORIGINS=$origins|" \
      -e "s|^ADMIN_URL=.*|ADMIN_URL=$admin|" \
      -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$dbpw|" \
      -e "s|^DATABASE_URL=.*|DATABASE_URL=postgres://softladylux:$dbpw@db:5432/softladylux|" \
      -e "s|^DEFAULT_FROM_EMAIL=.*|DEFAULT_FROM_EMAIL=SoftLadyLux <no-reply@$DOMAIN>|" \
      backend/.env.production.example > "$be.tmp"
  ! grep -q 'REPLACE_ME' "$be.tmp" || { grep -n REPLACE_ME "$be.tmp"; die "placeholders left in backend/.env"; }
  chmod 600 "$be.tmp"; mv "$be.tmp" "$be"
  ok "backend/.env created (new secret key, database password, admin path)"
fi

fe=frontend/.env
if [ -f "$fe" ] && grep -q "^NUXT_PUBLIC_SITE_URL=https://$DOMAIN\$" "$fe"; then
  ok "frontend/.env already set up for production: kept"
else
  [ -f "$fe" ] && { mv "$fe" "$fe.dev-uploaded.$ts"; info "uploaded dev frontend/.env moved to $fe.dev-uploaded.$ts"; }
  sed -e "s|^NUXT_PUBLIC_SITE_URL=.*|NUXT_PUBLIC_SITE_URL=https://$DOMAIN|" frontend/.env.production.example > "$fe.tmp"
  ! grep -q 'REPLACE_ME' "$fe.tmp" || die "placeholders left in frontend/.env"
  chmod 600 "$fe.tmp"; mv "$fe.tmp" "$fe"
  ok "frontend/.env created"
fi
EOF
}

stage_05() {
  need_stamp
  info "uploading backup $STAMP …"
  r "mkdir -p '$REMOTE_BK/$STAMP'"
  rsync -a -e "$RSYNC_SSH" "$BKDIR/$STAMP/" "$SSH_USER@$SERVER:$REMOTE_BK/$STAMP/"
  r "cd '$REMOTE_BK/$STAMP' && sha256sum -c --quiet SHA256SUMS"
  ok "backup on the server: $REMOTE_BK/$STAMP (checksums match)"
}

stage_06() {
  remote <<'EOF'
info "building images (backend, frontend, then nginx; several minutes on 2 vCPU) …"
start=$SECONDS
dc build
ok "images built in $(( (SECONDS - start) / 60 )) min $(( (SECONDS - start) % 60 )) s"
dc run --rm --no-deps --entrypoint python backend -m apps.core.envcheck
ok "production settings check passed"
docker image prune -f >/dev/null
EOF
}

stage_07() {
  remote <<'EOF'
dc up --no-start
dc up -d db
wait_healthy 120 softladylux-prod-db || { dc logs --tail=40 db; die "database did not become healthy"; }
ok "volumes created, database running"
EOF
}

stage_08() {
  need_stamp
  remote <<'EOF'
f="$REMOTE_BK/$STAMP/db.sql.gz"; [ -f "$f" ] || die "missing $f (run stage 05)"
dc stop backend worker backup >/dev/null 2>&1 || true   # nothing may write while the data is replaced
n=$(psql_db -Atqc "select count(*) from information_schema.tables where table_schema='public'")
if [ "$n" != 0 ]; then
  if [ "$FORCE_DB" = 1 ]; then
    warn "production database has $n tables: replacing it (--force-db)"
    psql_db -qc 'drop schema public cascade; create schema public;'
  else
    die "The production database already has $n tables. To keep it: re-run with --skip-data. To replace it with the local backup: --force-db"
  fi
fi
info "restoring $STAMP (one transaction: all or nothing) …"
gunzip -c "$f" | psql_db -1 -q >/dev/null
psql_db -At < "$REMOTE_BK/$STAMP/counts.sql" | sort > "$REMOTE_BK/$STAMP/prod.counts"
if ! diff -u "$REMOTE_BK/$STAMP/db.counts" "$REMOTE_BK/$STAMP/prod.counts"; then
  die "row counts differ from the local database (diff above)"
fi
ok "database restored: $(wc -l < "$REMOTE_BK/$STAMP/prod.counts") tables, every row count matches"
EOF
}

stage_09() {
  need_stamp
  remote <<'EOF'
f="$REMOTE_BK/$STAMP/media.tar.gz"; [ -f "$f" ] || die "missing $f (run stage 05)"
docker volume inspect "$PROD_MEDIA_VOL" >/dev/null || die "volume $PROD_MEDIA_VOL missing (run stage 07)"
# Files belong to the app user (uid 10001): the entrypoint only fixes the top folder.
got=$(docker run --rm -v "$PROD_MEDIA_VOL":/m -v "$REMOTE_BK/$STAMP":/b:ro "$ALPINE" sh -c '
  tar -xzf /b/media.tar.gz -C /m && chown -R 10001:10001 /m &&
  cd /m && find . -type f ! -path "./cdrom/*" ! -path "./floppy/*" ! -path "./usb/*" | wc -l' | tr -d ' ')
want=$(cat "$REMOTE_BK/$STAMP/media.count")
[ "$got" -ge "$want" ] || die "media volume has $got files, expected $want"
ok "media restored: $got files (local: $want)"
EOF
}

stage_10() {
  remote <<'EOF'
mkdir -p deploy/certs
if [ -s deploy/certs/fullchain.pem ] && [ -s deploy/certs/privkey.pem ]; then
  ok "certificate files already present"
else
  openssl req -x509 -nodes -newkey rsa:2048 -days 2 -subj "/CN=$DOMAIN" \
    -keyout deploy/certs/privkey.pem -out deploy/certs/fullchain.pem 2>/dev/null
  chmod 600 deploy/certs/privkey.pem
  ok "temporary self-signed certificate created (replaced by Let's Encrypt in stage 12)"
fi
EOF
}

stage_11() {
  remote <<'EOF'
info "starting the stack (the backend runs migrations on start) …"
dc up -d --remove-orphans
if ! wait_healthy 300 softladylux-prod-db softladylux-prod-backend softladylux-prod-worker softladylux-prod-frontend softladylux-prod-nginx softladylux-prod-certbot; then
  dc ps
  for s in backend worker frontend nginx; do echo "--- $s"; dc logs --tail=30 "$s"; done
  die "the stack did not become healthy within 5 minutes (logs above)"
fi
dc ps --format 'table {{.Service}}\t{{.Status}}' | sed 's/^/  /'
ok "all services healthy"
EOF
}

stage_12() {
  remote <<'EOF'
domains=(-d "$DOMAIN"); [ "$WWW" = 1 ] && domains+=(-d "www.$DOMAIN")
served() { echo | openssl s_client -connect 127.0.0.1:443 -servername "$1" 2>/dev/null || true; }  # PEM nginx serves for a name
le_ok() {  # served certificate is from Let's Encrypt, valid 30+ more days, and covers www when wanted
  local pem; pem="$(served "$DOMAIN")"
  openssl x509 -noout -checkend 2592000 <<<"$pem" >/dev/null 2>&1 || return 1
  openssl x509 -noout -issuer <<<"$pem" 2>/dev/null | grep -q "Let's Encrypt" || return 1
  [ "$WWW" = 0 ] || openssl x509 -noout -ext subjectAltName <<<"$pem" 2>/dev/null | grep -q "www.$DOMAIN"
}
certbot() { dc run --rm --no-deps --entrypoint certbot certbot "$@"; }
if le_ok; then
  ok "Let's Encrypt certificate already active"
else
  info "dry run against Let's Encrypt staging (protects the rate limit) …"
  certbot certonly --webroot -w /var/www/certbot "${domains[@]}" --email "$LE_EMAIL" \
    --agree-tos --no-eff-email --non-interactive --dry-run
  info "requesting the real certificate …"
  certbot certonly --webroot -w /var/www/certbot "${domains[@]}" --cert-name "$DOMAIN" --email "$LE_EMAIL" \
    --agree-tos --no-eff-email --non-interactive --keep-until-expiring --expand
  dc run --rm --no-deps --entrypoint sh certbot -c \
    "cp -L /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem /certs/"
  chmod 600 deploy/certs/privkey.pem
  docker exec softladylux-prod-nginx nginx -s reload
  sleep 2
  le_ok || die "nginx is not serving the Let's Encrypt certificate"
fi
ok "$(openssl x509 -noout -enddate <<<"$(served "$DOMAIN")" | sed 's/notAfter=/Let'"'"'s Encrypt certificate valid until /')"
EOF
}

stage_13() {
  local base="https://$DOMAIN" fails=0 code h asset ipx
  check() { if eval "$2"; then ok "$1"; else printf '  %s✗%s %s\n' "$R" "$N" "$1"; fails=$((fails + 1)); fi; }
  st() { curl -s -o /dev/null -w '%{http_code}' --max-time 30 "$@"; }

  check "HTTPS health endpoint 200"        '[ "$(st "$base/api/v1/health/")" = 200 ]'
  check "home page 200"                    '[ "$(st "$base/")" = 200 ]'
  check "admin login page 200"             '[ "$(st "$base/admin/login")" = 200 ]'
  check "sitemap.xml 200"                  '[ "$(st "$base/sitemap.xml")" = 200 ]'
  check "plain HTTP redirects to HTTPS"    '[[ "$(curl -s -o /dev/null -w "%{http_code} %{redirect_url}" --max-time 20 "http://$DOMAIN/")" == 301\ https://* ]]'
  check "trusted certificate (no -k)"      'curl -sf -o /dev/null --max-time 20 "$base/api/v1/health/"'

  h="$(curl -s --max-time 30 "$base/")"
  asset="$(grep -o '/_nuxt/[^"]*\.js' <<<"$h" | head -1 || true)"
  if [ -n "$asset" ]; then
    check "/_nuxt served by nginx, gzip + immutable" \
      'curl -s -I -H "Accept-Encoding: gzip" --max-time 20 "$base$asset" | tr -d "\r" | grep -qi "^cache-control: .*immutable" '
  else
    warn "no /_nuxt asset found in the home page: static check skipped"
  fi
  ipx="$(grep -o '/_ipx/[^" ,]*' <<<"$h" | head -1 | sed 's/&amp;/\&/g' || true)"
  if [ -n "$ipx" ]; then
    curl -s -o /dev/null --max-time 60 "$base$ipx" || true
    check "resized image cached by nginx (X-Cache: HIT)" \
      'curl -s -I --max-time 30 "$base$ipx" | tr -d "\r" | grep -qi "^x-cache: HIT"'
  else
    warn "no image on the home page yet: image-cache check skipped"
  fi

  say "  ${C}full smoke test (backend/scripts/smoke.sh; data-specific checks are warnings):${N}"
  if bash backend/scripts/smoke.sh "$base" | sed 's/^/    /'; then ok "smoke.sh: all passed"
  else warn "smoke.sh reported failures above: review them (e.g. /shop/bras needs that category)"; fi

  [ "$fails" -eq 0 ] || die "$fails essential check(s) failed"
}

stage_14() {
  remote <<'EOF'
dc --profile backup up -d backup
sleep 3
[ "$(docker inspect -f '{{.State.Running}}' softladylux-prod-backup)" = true ] || { dc logs --tail=30 backup; die "backup service not running"; }
ok "daily backups on (db + media, newest 14 kept, volume softladylux-prod_backups)"
EOF
}

stage_15() {
  local admin
  admin="$(r "grep '^ADMIN_URL=' '$REMOTE_DIR/backend/.env' | cut -d= -f2" 2>/dev/null || echo '?')"
  say ""
  say "${G}${B}SoftLadyLux is live${N}"
  info "Storefront:        https://$DOMAIN"
  info "Admin panel:       https://$DOMAIN/admin/login   (same accounts as your local database)"
  info "Django admin:      https://$DOMAIN/api/$admin/   (developer only)"
  info "Server secrets:    $REMOTE_DIR/backend/.env and frontend/.env (only on the server)"
  info "Data backup used:  $BKDIR/${STAMP:-none} (copy on the server: $REMOTE_BK/${STAMP:-none})"
  info "Log of this run:   $LOG"
  say "  Next steps:"
  info "• Fill the SMTP settings in backend/.env (email is off until then), then: ./deploy/deploy.sh --from 11 --skip-data"
  info "• Copy the backups volume off the server regularly (docs/RUNBOOK.md)"
  info "• Change the root password: it was shared in plain text"
  info "• Code-only redeploy later:  ./deploy/deploy.sh --from 03 --skip-data"
}

# ---------------------------------------------------------------------------------------------------
# Command line
FROM="" ONLY="" SKIP_DATA=0
usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; }
while [ $# -gt 0 ]; do
  case "$1" in
    --status) for s in "${STAGES[@]}"; do id=${s%%:*}
                if [[ "$ALWAYS" == *" $id "* ]]; then st="(every run)"; elif [ -f "$STATE/$s.done" ]; then st="${G}done${N} $(date -r "$STATE/$s.done" '+%F %T')"; else st="${Y}pending${N}"; fi
                printf '  %s %-20s %s\n' "$id" "${s#*:}" "$st"; done
              exit 0 ;;
    --from) FROM="${2:?--from needs a stage number}"; shift 2 ;;
    --only) ONLY="${2:?--only needs a stage number}"; shift 2 ;;
    --skip-data) SKIP_DATA=1; shift ;;
    --force-db) FORCE_DB=1; shift ;;
    --purge-image-cache)
      r "docker exec softladylux-prod-nginx sh -c 'rm -rf /var/cache/nginx/ipx/*'" && echo "Image cache emptied (images regenerate on next view)."
      exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 2 ;;
  esac
done

norm() { [[ "$1" =~ ^[0-9]{1,2}$ ]] || { echo "Stage must be a number 00-15, got '$1'"; exit 2; }; printf '%02d' "$((10#$1))"; }
[ -z "$FROM" ] || FROM="$(norm "$FROM")"
[ -z "$ONLY" ] || ONLY="$(norm "$ONLY")"
if [ -n "$FROM" ]; then  # forget completed stages from FROM onward so they run again
  for s in "${STAGES[@]}"; do [ "${s%%:*}" \< "$FROM" ] || rm -f "$STATE/$s.done"; done
fi

say "${B}SoftLadyLux deploy → $SSH_USER@$SERVER:$REMOTE_DIR ($DOMAIN)${N}   log: $LOG"
for s in "${STAGES[@]}"; do
  id=${s%%:*}; name=${s#*:}
  if [ -n "$ONLY" ] && [ "$id" != "$ONLY" ] && [ "$id" != 00 ]; then continue; fi
  if [ "$SKIP_DATA" = 1 ] && [[ "$DATA_STAGES" == *" $id "* ]]; then say "${C}↷ $id $name${N} (skipped: --skip-data)"; continue; fi
  if [[ "$ALWAYS" != *" $id "* ]] && [ -f "$STATE/$s.done" ] && [ -z "$ONLY" ]; then say "${C}↷ $id $name${N} (done)"; continue; fi
  CURRENT_STAGE="$id-$name"
  say "${B}▶ $id $name${N}"
  "stage_$id"
  [[ "$ALWAYS" == *" $id "* ]] || touch "$STATE/$s.done"
  say "${G}✓ $id $name${N}"
done
CURRENT_STAGE=""
