#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/n8n"
BACKUP_DIR="/opt/backups"
DATE="$(date +%F-%H-%M-%S)"

# Load environment variables from .env
set -a
source "${APP_DIR}/.env"
set +a

mkdir -p "${BACKUP_DIR}"

echo "Creating PostgreSQL backup..."
docker exec -t n8n-postgres-1 pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" > "${BACKUP_DIR}/db-${DATE}.sql"

# Verify DB backup
if [ ! -s "${BACKUP_DIR}/db-${DATE}.sql" ]; then
  echo "ERROR: Database backup is empty!"
  exit 1
fi

echo "Archiving n8n files..."
tar -czf "${BACKUP_DIR}/n8n-${DATE}.tar.gz" -C "${APP_DIR}" n8n

echo "Saving environment file..."
cp "${APP_DIR}/.env" "${BACKUP_DIR}/env-${DATE}.bak"

echo "Removing backups older than 7 days..."
find "${BACKUP_DIR}" -type f -mtime +7 -delete

echo "Backup created:"
echo "  - ${BACKUP_DIR}/db-${DATE}.sql"
echo "  - ${BACKUP_DIR}/n8n-${DATE}.tar.gz"
echo "  - ${BACKUP_DIR}/env-${DATE}.bak"

echo "Uploading backups to Google Drive..."
if rclone copy /opt/backups gdrive:n8n-backups --progress; then
  echo "Remote backup upload succeeded."
else
  echo "WARNING: Remote backup upload failed. Local backup is still available."
fi

echo "Backup process completed successfully at $(date)"

echo "SUCCESS $(date)" >> /var/log/n8n-backup.log
