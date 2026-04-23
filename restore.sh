#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage:"
  echo "  $0 <db-backup.sql|db-backup.sql.gz> <n8n-backup.tar.gz> <env-backup.bak>"
  exit 1
fi

DB_BACKUP="$1"
N8N_BACKUP="$2"
ENV_BACKUP="$3"

APP_DIR="/opt/n8n"
POSTGRES_CONTAINER="n8n-postgres-1"

if [ ! -f "${DB_BACKUP}" ]; then
  echo "Database backup not found: ${DB_BACKUP}"
  exit 1
fi

if [ ! -f "${N8N_BACKUP}" ]; then
  echo "n8n archive not found: ${N8N_BACKUP}"
  exit 1
fi

if [ ! -f "${ENV_BACKUP}" ]; then
  echo ".env backup not found: ${ENV_BACKUP}"
  exit 1
fi

echo "Stopping stack..."
cd "${APP_DIR}"
docker compose down --remove-orphans

echo "Restoring .env..."
cp "${ENV_BACKUP}" "${APP_DIR}/.env"

echo "Loading environment variables..."
set -a
source "${APP_DIR}/.env"
set +a

echo "Restoring n8n files..."
rm -rf "${APP_DIR}/n8n"
tar -xzf "${N8N_BACKUP}" -C "${APP_DIR}"

if [ ! -d "${APP_DIR}/n8n" ]; then
  echo "Expected restored directory ${APP_DIR}/n8n not found after extraction."
  exit 1
fi

echo "Fixing permissions..."
chown -R 1000:1000 "${APP_DIR}/n8n"
chown -R 999:999 "${APP_DIR}/postgres"

echo "Starting PostgreSQL only..."
docker compose up -d postgres

echo "Waiting for PostgreSQL to become ready..."
until docker exec "${POSTGRES_CONTAINER}" pg_isready -U "${POSTGRES_USER}" -d postgres >/dev/null 2>&1; do
  sleep 2
done

echo "Recreating database..."
docker exec -i "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -d postgres -c "DROP DATABASE IF EXISTS \"${POSTGRES_DB}\";"
docker exec -i "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -d postgres -c "CREATE DATABASE \"${POSTGRES_DB}\";"

echo "Restoring database backup..."
if [[ "${DB_BACKUP}" == *.gz ]]; then
  gunzip -c "${DB_BACKUP}" | docker exec -i "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"
else
  cat "${DB_BACKUP}" | docker exec -i "${POSTGRES_CONTAINER}" psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"
fi

echo "Starting full stack..."
docker compose up -d

echo "Restore completed successfully."
