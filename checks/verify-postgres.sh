#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/lib/os.sh
source "${REPO_ROOT}/scripts/lib/os.sh"

echo "[verify-postgres] checking PostgreSQL client..."
command -v psql >/dev/null
psql --version

if systemd_is_active; then
  echo "[verify-postgres] checking PostgreSQL service status..."
  sudo systemctl is-enabled postgresql >/dev/null
  sudo systemctl is-active postgresql >/dev/null
fi

echo "[verify-postgres] ok"
