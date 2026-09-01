#!/bin/bash
# Generate the six secret files Authelia and its dependencies read at
# startup. Run once per deployment; the files are gitignored.
#
# openssl with finite input on purpose: the previous implementation piped
# /dev/urandom through tr | fold | head, which can hang forever in
# environments that ignore SIGPIPE (GitHub Actions runners do).

set -euo pipefail

gen() {
  openssl rand -base64 96 | tr -dc 'a-zA-Z0-9' | head -c 64 > "config/secrets/$1"
  echo "config/secrets/$1 written"
}

gen JWT_SECRET
gen SESSION_SECRET
gen STORAGE_PASSWORD
gen STORAGE_ENCRYPTION_KEY
gen REDIS_PASSWORD
gen SMTP_PASSWORD

echo "All secrets generated successfully."
