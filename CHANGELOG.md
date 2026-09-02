# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_(no unreleased changes yet)_

## [1.3.0] - 2026-09-02

### Added

- **A `backups` service** — the compose file had declared the backup
  volumes since day one but never ran anything against them. The new
  service dumps PostgreSQL on a loop (`pg_dump | gzip` under `pipefail`,
  logging `Database backup OK: <file> (<bytes> bytes)` or `FAILED` per
  cycle, keeping a failed dump as `<file>.failed`, pruning only its own
  files). It reads the database password from the same secret file
  PostgreSQL uses, so nothing about backups lives in `.env`; the
  schedule knobs (`AUTHELIA_BACKUP_INIT_SLEEP`, `AUTHELIA_BACKUP_INTERVAL`,
  `AUTHELIA_POSTGRES_BACKUP_PRUNE_DAYS`, path and name) have defaults
  listed in `.env.example`.
- **`authelia-restore-database.sh`** — interactive restore: lists dumps,
  stops Authelia, drops and recreates the database from the selected
  dump, starts Authelia again.
- **`tests/e2e-backup-restore.sh`** — seven scenarios against the live
  stack, run by CI on every push: backup produced, readable, valid
  content, failure detected when the database is down, **restore
  genuinely replaces database state**, prune keeps recent files.

## [1.2.0] - 2026-09-02

### Added

- **Resource limits on every service, as `.env`-overridable defaults.**
  Each service now carries memory and CPU limits plus reservations
  (`<SERVICE>_MEMORY_LIMIT`, `_CPU_LIMIT`, `_MEMORY_RESERVATION`,
  `_CPU_RESERVATION`, defaults listed in `.env.example`). Set any of
  them in `.env` and the override survives every `git pull`. The
  defaults are what CI boots the stack under, so they are known to be
  enough for a fresh install; raise a limit if a service is OOM-killed
  under your real load (`docker inspect` shows `OOMKilled=true`).

## [1.1.0] - 2026-09-02

### Added

- **`update.sh`** — unattended updates to the newest tagged release,
  and nothing else: a tag is cut only after CI has booted the pinned
  images and passed the smoke tests, so "update to the latest tag" means
  "update to a combination a machine has already run". It refuses to
  cross a major version on its own (`--allow-major` after reading the
  notes), refuses a checkout with local modifications, and supports
  `--dry-run`. Put it on a cron timer for hands-off minor/patch updates.

## [1.0.0] - 2026-09-01

First semver release. Brings this template to the fleet standard established
in [keycloak-traefik-letsencrypt-docker-compose](https://github.com/heyvaldemar/keycloak-traefik-letsencrypt-docker-compose)
v1.2.0.

### Security (act on this)

- **The six secret files under `config/secrets/` were tracked in git** —
  session secret, storage encryption key, database and Redis passwords,
  JWT secret. Any deployment that used them as shipped was running on
  publicly known secrets. They are now gitignored;
  `./generate-authelia-secrets.sh` creates a fresh set per deployment.
  ❗ If your deployment reused the tracked values, regenerate all six and
  restart — note that changing the storage encryption key requires
  resetting the storage (see the release notes).

### Changed

- **Authelia 4.38 → 4.39.20**, **Traefik 3.2 → 3.7** (3.2's Docker client
  cannot talk to Docker Engine 29), **PostgreSQL 16 digest-pinned**, and
  **Redis moved from the frozen `bitnami/redis` image to the official
  `redis:7.4`** (Bitnami's public images stopped updating with Broadcom's
  2025 catalog change). All pins live in the compose `x-images` block.
- **The notifier defaults to the filesystem provider** so the stack works
  without an SMTP relay: reset links land in `/config/notification.txt`.
  The SMTP block is commented in `config/configuration.yml` for
  production mail.
- `config/configuration.yml` now uses `example.com` placeholders and
  info-level logging.

### Added

- **Deployment Verification workflow**: shellcheck + actionlint; Trivy
  scans of all four pinned images; weekly `check-pin-freshness`; and a
  deploy-and-test job that generates fresh secrets, boots the stack, and
  requires `/api/health` to answer `OK` through Traefik.

[Unreleased]: https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/releases/tag/v1.0.0
