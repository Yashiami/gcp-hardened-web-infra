#!/usr/bin/env bash
set -euo pipefail

BACKUP_BUCKET="${BACKUP_BUCKET:?BACKUP_BUCKET must be set}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE="/tmp/web-backup-${TIMESTAMP}.tar.gz"

trap 'rm -f "$ARCHIVE"' EXIT

tar -czf "$ARCHIVE" -C / opt/web-app/data etc/nginx/conf.d/app.conf
gcloud storage cp "$ARCHIVE" "gs://${BACKUP_BUCKET}/snapshots/web-backup-${TIMESTAMP}.tar.gz"

echo "[$(date -u +%FT%TZ)] Backup uploaded: gs://${BACKUP_BUCKET}/snapshots/web-backup-${TIMESTAMP}.tar.gz"
