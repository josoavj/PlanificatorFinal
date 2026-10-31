#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${1:-$SCRIPT_DIR/Planificator.sql}"
REPOSITORY="josoavj/PlanificatorFinal"
ARCHIVE="$(mktemp)"
trap 'rm -f "$ARCHIVE"' EXIT

command -v curl >/dev/null 2>&1 || {
  echo "Erreur : curl est requis."
  exit 1
}

echo "Téléchargement du schéma SQL depuis la dernière release..."
curl -fL "https://github.com/$REPOSITORY/releases/latest/download/planificator-linux-x64.tar.gz" -o "$ARCHIVE"
tar -xOzf "$ARCHIVE" "Database/Planificator.sql" > "$OUTPUT_FILE"

echo "Schéma téléchargé : $OUTPUT_FILE"
echo "Attention : ce script SQL recrée la base Planificator."
