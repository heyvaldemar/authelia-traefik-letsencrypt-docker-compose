#!/bin/bash
# Generate secure secrets for various services

LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > config/secrets/JWT_SECRET &&
LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > config/secrets/SESSION_SECRET &&
LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > config/secrets/STORAGE_PASSWORD &&
LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > config/secrets/STORAGE_ENCRYPTION_KEY &&
LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > config/secrets/REDIS_PASSWORD &&
LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > config/secrets/SMTP_PASSWORD

echo "All secrets generated successfully."
