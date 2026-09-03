# Authelia + Traefik + Let's Encrypt — Docker Compose

[![Deployment Verification](https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml/badge.svg?branch=main)](https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository deploys **Authelia** — single sign-on and two-factor authentication in front of the apps Traefik routes — with automatic **Let's Encrypt TLS**, backed by **PostgreSQL** and **Redis**. Traefik's `forwardauth` middleware is pre-wired: add one label to any service and it sits behind Authelia.

## Getting started

```bash
# 1. Clone
git clone https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose
cd authelia-traefik-letsencrypt-docker-compose

# 2. Create the two Docker networks the stack expects
docker network create traefik-network
docker network create authelia-network

# 3. Generate the six secret files (gitignored, one set per deployment)
chmod +x generate-authelia-secrets.sh && ./generate-authelia-secrets.sh

# 4. Point the config at your domain
#    Replace example.com with your domain in config/configuration.yml
#    (access-control rule, session cookie domain, authelia_url).
$EDITOR config/configuration.yml

# 5. Copy the environment template and fill in required values
cp .env.example .env
$EDITOR .env

# 6. Set your own user in config/users_database.yml
#    Generate a password hash:
#    docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'YOUR_PASSWORD'

# 7. Deploy
docker compose -f authelia-traefik-letsencrypt-docker-compose.yml -p authelia up -d
```

### Protecting an app

Add these labels to any Traefik-routed service on the same `traefik-network`:

```yaml
- "traefik.http.routers.myapp.middlewares=authelia"
```

The `authelia` forwardauth middleware is defined by this stack; unauthenticated requests are redirected to the portal, and authenticated ones carry `Remote-User`/`Remote-Groups` headers.

### What success looks like

```bash
docker compose -f authelia-traefik-letsencrypt-docker-compose.yml -p authelia ps
curl -fsk "https://${AUTHELIA_HOSTNAME}/api/health"   # {"status":"OK"}
```

### Common first-deploy issues

- **Authelia restarts in a loop.** Almost always configuration: `docker logs authelia-authelia-1` names the exact key. Missing secret files (step 3 skipped) and a cookie domain that doesn't match `authelia_url` are the usual suspects.
- **Password-reset links don't arrive.** By default they land in `/config/notification.txt` (filesystem notifier) — enable the SMTP block in `config/configuration.yml` for real mail, and re-add `AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE` to the compose environment.
- **Cert issuance fails.** DNS hasn't propagated or port 80 isn't reachable.

## Supply chain trust

Four images — [`traefik`](https://hub.docker.com/_/traefik), [`authelia/authelia`](https://hub.docker.com/r/authelia/authelia), [`postgres`](https://hub.docker.com/_/postgres), [`redis`](https://hub.docker.com/_/redis) — pinned to `tag@sha256:<digest>` as interpolation defaults in the compose `x-images` block. Redis is the official image (the previously used Bitnami image has been frozen since Broadcom's 2025 catalog change). `git pull` alone delivers the tested combination.

The daily `check-pin-freshness` CI job re-resolves each pin against its registry and compares the pinned Authelia and Traefik versions against the latest upstream releases. GitHub Actions are pinned by commit SHA; Dependabot keeps those fresh.

## Production checklist

- [ ] **Generate fresh secrets** — never deploy with someone else's `config/secrets/`.
- [ ] **Replace the sample user** in `config/users_database.yml` — its password is the documented word `authelia`.
- [ ] **Enable SMTP** for real password-reset mail.
- [ ] **Back up `config/secrets/` and the database volume together** — the storage encryption key and the database are only useful as a pair.
- [ ] **Regenerate the Traefik dashboard hash** — never ship the placeholder.

## Unattended updates

Releases are the update channel: a tag is cut only after CI has built the pinned images, booted the full stack, and passed the smoke tests. `update.sh` moves a deployment to the newest tag and nothing else:

```bash
./update.sh --dry-run   # show what would be applied
./update.sh             # update within the current major and redeploy
```

Put it on a timer for hands-off minor/patch updates:

```bash
# crontab -e
17 5 * * *  /opt/authelia-traefik-letsencrypt-docker-compose/update.sh >> /var/log/authelia-update.log 2>&1
```

The script refuses to cross a MAJOR template version on its own — majors are breaking by definition and their release notes exist to be read. After reading them, `./update.sh --allow-major` performs the jump. It also refuses to touch a checkout with local modifications: your customization belongs in `.env`, which updates never overwrite.

This is deliberately a host-side script and not a container in the stack: an in-stack updater needs the Docker socket (root on the host) and turns "someone pushed to a repo" into "someone deployed to your machine" with no operator in the loop. A cron job under your own user updates only to tagged, CI-verified states and leaves the trust boundary where it was.

## Resource limits

Every service carries memory and CPU limits plus reservations as compose-level defaults — the same values CI boots the stack under. Override any of them in `.env` (the knobs and their defaults are listed in `.env.example`, e.g. `TRAEFIK_MEMORY_LIMIT=512m`) and the override survives every `git pull`. If a service is OOM-killed under real load, `docker inspect <container> --format '{{.State.OOMKilled}}'` says so; raise its `_MEMORY_LIMIT` and recreate.

## Backups

The `backups` container runs `pg_dump | gzip` of the Authelia database on a loop: an initial delay (`AUTHELIA_BACKUP_INIT_SLEEP`, default 30m), then one timestamped dump every `AUTHELIA_BACKUP_INTERVAL` (default 24h), pruning files older than `AUTHELIA_POSTGRES_BACKUP_PRUNE_DAYS` (default 7). The database password is read from `config/secrets/STORAGE_PASSWORD`, the same file PostgreSQL uses. Each cycle logs `Database backup OK: <file> (<bytes> bytes)` or `Database backup FAILED`; a failed dump is kept as `<file>.failed` for diagnosis — grep the log for `FAILED` from your monitoring.

**Verify backups are running:**

```bash
docker compose -p authelia logs backups | tail -5
```

**Restore** with the interactive script (`chmod +x authelia-restore-database.sh` once): it lists dumps, stops Authelia, recreates the database from the selected dump, and starts Authelia again.

```bash
./authelia-restore-database.sh
```

**Off-host replication.** Dumps land in the `authelia-database-backups` named volume — if the host dies, backups die with it. Bind-mount the path to a host directory covered by your off-host backup solution (restic, rclone, Borg, S3 sync).

### Backup and restore, proven

`tests/e2e-backup-restore.sh` runs against the live stack and is what CI executes after the HTTPS smoke. The scenario that matters most is the restore roundtrip: insert a marker row, restore the earliest post-marker backup, assert the marker is gone — a backup that cannot be restored fails the build. Run it yourself on a staging copy with short intervals in `.env` (`AUTHELIA_BACKUP_INIT_SLEEP=15s`, `AUTHELIA_BACKUP_INTERVAL=60s`); it stops the database container briefly to prove failure detection.

## Container hardening

Every service runs with `security_opt: no-new-privileges:true`, so a process cannot gain privileges through setuid binaries even if it escapes its initial capability set. Infrastructure containers (the reverse proxy, databases, caches, backups) run with `cap_drop: [ALL]` and add back only what their entrypoints need: `NET_BIND_SERVICE` for Traefik to bind :80/:443, `CHOWN`/`SETUID`/`SETGID` (and friends) for database images to own their data directory and drop to their service user. Application containers keep the default capability set on purpose: upstream images assume it, and a wrong guess there is a boot loop in production rather than a hardening win. CI boots the stack under exactly these settings on every push, so what ships is what was tested.

## Testing

The [Deployment Verification](https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml?query=branch%3Amain) workflow runs on every push, pull request, and every day at 06:00 UTC: shellcheck + actionlint, Trivy scans of all four pinned images, the weekly freshness check, and a deploy-and-test job that generates fresh secrets, boots the stack, and requires `/api/health` to answer `OK` through Traefik.

## Security Notes

- **Pre-rotation advisory.** Releases before v1.0.0 (2026-09-01) tracked the six secret files in git — session secret, storage encryption key, database and Redis passwords, JWT secret. If your deployment reused them, regenerate all six (`./generate-authelia-secrets.sh`) and restart. Changing the storage encryption key invalidates encrypted storage data (TOTP secrets, webauthn devices): run `authelia storage encryption change-key` to migrate, or reset the storage and re-enroll second factors.
- The default access-control policy is `deny` — only rules you add grant access.
- PostgreSQL and Redis listen only on the internal network.

---

## About the maintainer

<div align="center">

**Maintained by [Vladimir Mikhalev](https://github.com/heyvaldemar)** — Docker Captain · IBM Champion · AWS Community Builder

[YouTube](https://www.youtube.com/channel/UCf85kQ0u1sYTTTyKVpxrlyQ?sub_confirmation=1) · [Blog](https://heyvaldemar.com) · [LinkedIn](https://www.linkedin.com/in/heyvaldemar/)

</div>
