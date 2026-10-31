#!/usr/bin/env bash
set -euo pipefail

: "${MYSQL_HOST:=localhost}"
: "${MYSQL_PORT:=3306}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_DATABASE:=Planificator}"
: "${BACKUP_DIR:=./backups}"

mkdir -p "$BACKUP_DIR"
timestamp="$(date +%Y%m%d_%H%M%S)"
output="$BACKUP_DIR/${MYSQL_DATABASE}_${timestamp}.sql"

if [[ -n "${MYSQL_PASSWORD:-}" ]]; then
  MYSQL_PWD="$MYSQL_PASSWORD" mysqldump \
    --host="$MYSQL_HOST" --port="$MYSQL_PORT" --user="$MYSQL_USER" \
    --single-transaction --routines --triggers --events "$MYSQL_DATABASE" > "$output"
else
  mysqldump \
    --host="$MYSQL_HOST" --port="$MYSQL_PORT" --user="$MYSQL_USER" \
    --single-transaction --routines --triggers --events "$MYSQL_DATABASE" > "$output"
fi

echo "Backup créé: $output"
