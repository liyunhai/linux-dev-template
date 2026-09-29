#!/usr/bin/env bash
# =============================================================================
# 60-postgres.sh
# =============================================================================
# Purpose:
#   Install PostgreSQL as an optional local development service.
#
# Why PostgreSQL is optional:
#   Projects that need a local database can select this service explicitly.
#
# Official references:
#   - PostgreSQL on Ubuntu: https://www.postgresql.org/download/linux/ubuntu/
#   - PostgreSQL on Fedora: https://www.postgresql.org/download/linux/redhat/
#
# Notes:
#   - Fedora requires initialization before the first service start.
#   - On WSL, this behaves best when systemd is enabled.
# =============================================================================
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"
# shellcheck source=../lib/postgres.sh
source "${REPO_ROOT}/scripts/lib/postgres.sh"

main() {
  echo "[60-postgres] installing PostgreSQL..."
  install_module_packages postgres

  if [[ "$OS_ID" == fedora ]]; then
    systemd_is_active || {
      printf '[60-postgres] ERROR: Fedora PostgreSQL initialization requires a running systemd\n' >&2
      exit 1
    }
    initialize_fedora_postgres
  fi

  if systemd_is_active; then
    echo "[60-postgres] enabling PostgreSQL service..."
    sudo systemctl enable --now postgresql
    sudo systemctl status postgresql --no-pager
  else
    echo "[60-postgres] systemd not detected; skipping service enable/start."
  fi

  cat <<MSG
[60-postgres] done.
[60-postgres] to create a user/db manually, use the postgres admin account.
MSG
}

main "$@"
