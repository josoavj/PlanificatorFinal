#!/usr/bin/env bash

set -euo pipefail

REPOSITORY="josoavj/PlanificatorFinal"
DOWNLOAD_DIR="${PLANIFICATOR_DOWNLOAD_DIR:-$PWD/planificator}"
ARCHIVE="$DOWNLOAD_DIR/planificator-linux-x64.tar.gz"
DATABASE_SCRIPT="$DOWNLOAD_DIR/Database/Planificator.sql"
DB_USER="${PLANIFICATOR_DB_USER:-root}"
DB_PASSWORD="${PLANIFICATOR_DB_PASSWORD:-}"
DB_HOST="${PLANIFICATOR_DB_HOST:-localhost}"
DB_PORT="${PLANIFICATOR_DB_PORT:-3306}"

echo "================================"
echo "Installation de Planificator"
echo "================================"

command -v curl >/dev/null 2>&1 || { echo "Erreur : curl est requis."; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "Erreur : tar est requis."; exit 1; }

mkdir -p "$DOWNLOAD_DIR"
echo "Téléchargement de la dernière release Linux..."
curl -fL "https://github.com/$REPOSITORY/releases/latest/download/planificator-linux-x64.tar.gz" -o "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$DOWNLOAD_DIR"
chmod +x "$DOWNLOAD_DIR/bundle/planificator"

if ! command -v mysql >/dev/null 2>&1 && ! command -v mariadb >/dev/null 2>&1; then
  echo "Erreur : MariaDB/MySQL n'est pas installé."
  exit 1
fi

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files mariadb.service >/dev/null 2>&1; then
  if ! systemctl is-active --quiet mariadb; then
    echo "Démarrage de MariaDB..."
    sudo systemctl start mariadb
  fi
fi

if [ ! -f "$DATABASE_SCRIPT" ]; then
  echo "Erreur : le script SQL est absent de l'archive."
  exit 1
fi

MYSQL_COMMAND="${MYSQL_COMMAND:-}"
if command -v mariadb >/dev/null 2>&1; then
  MYSQL_COMMAND="mariadb"
elif command -v mysql >/dev/null 2>&1; then
  MYSQL_COMMAND="mysql"
fi

MYSQL_ARGS=(-h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER")
if [ -n "$DB_PASSWORD" ]; then
  MYSQL_ARGS+=("-p$DB_PASSWORD")
fi

echo "Importation du schéma Planificator..."
"$MYSQL_COMMAND" "${MYSQL_ARGS[@]}" < "$DATABASE_SCRIPT"

echo ""
echo "Installation terminée."
echo "Application : $DOWNLOAD_DIR/bundle/planificator"
echo "Base : $DB_HOST:$DB_PORT/$DB_USER"
