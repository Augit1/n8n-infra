# n8n Infrastructure (Self-Hosted)

This repository contains the infrastructure setup for running a self-hosted n8n instance using Docker Compose.

It includes:
- n8n (workflow automation)
- PostgreSQL (database)
- Caddy (reverse proxy with automatic HTTPS)
- Backup and restore scripts

---

## Stack Overview

- n8n: Workflow automation tool
- PostgreSQL: Persistent database
- Caddy: Reverse proxy with automatic TLS (Let's Encrypt)
- Docker Compose: Orchestration

---

## Project Structure

/opt/n8n
├── docker-compose.yml
├── backup.sh
├── restore.sh
├── Caddyfile
├── .env                (NOT committed)
├── n8n/                (NOT committed - app data)
├── postgres/           (NOT committed - database data)
├── backups/            (NOT committed - local backups)
├── caddy_data/         (NOT committed)
├── caddy_config/       (NOT committed)

---

## Environment Variables

Create a .env file in /opt/n8n with at least:

POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=your_password

N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_password

N8N_ENCRYPTION_KEY=your_very_secure_key
DOMAIN_NAME=your.domain.com

WARNING: Never commit your .env file.

---

## Start the Stack

docker compose up -d

---

## Backup

Run:

./backup.sh

This will:
- Dump PostgreSQL database
- Archive n8n data
- Save .env
- Remove backups older than 7 days
- Upload backups to Google Drive (via rclone)

Backups are stored in:
/opt/backups

---

## Restore

Run:

./restore.sh <db.sql> <n8n.tar.gz> <env.bak>

This will:
- Stop the stack
- Restore .env
- Restore n8n files
- Recreate the database
- Import the backup
- Restart services

WARNING: This will overwrite existing data.

---

## Remote Backup (Google Drive)

Backups are uploaded using rclone.

Configure it once:

rclone config

Then verify:

rclone listremotes

Expected:
gdrive:

---

## Best Practices

- Always test restore regularly
- Keep backups both locally and remotely
- Never commit secrets or data directories
- Monitor disk usage (/opt/backups)
- Use private repositories

---

## Security Notes

Do NOT commit:
- .env
- n8n/
- postgres/
- backups/
- caddy_data/
- caddy_config/

---

## Requirements

- Docker
- Docker Compose
- rclone (for remote backups)

---

## Notes

- This setup is production-ready for small to medium workloads
- Backups and restore have been tested
- Designed for easy recovery on a new server

---

## License

Private infrastructure repository.

