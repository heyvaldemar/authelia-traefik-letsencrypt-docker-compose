# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_(no unreleased changes yet)_

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

[Unreleased]: https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/releases/tag/v1.0.0
