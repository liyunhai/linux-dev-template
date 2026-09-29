#!/usr/bin/env bash
# =============================================================================
# 50-db-clients.sh
# =============================================================================
# Purpose:
#   Install common database client tools without making every database service
#   run locally by default.
#
# Why this split:
#   A reusable dev template should stay reasonably light. Client tools are cheap,
#   while multiple always-on database services increase complexity and memory use.
#
# Official references:
#   - WSL DB guide: https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-database
# =============================================================================
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"

main() {
  echo "[50-db-clients] installing database clients..."
  install_module_packages db-clients

  echo "[50-db-clients] done."
}

main "$@"
