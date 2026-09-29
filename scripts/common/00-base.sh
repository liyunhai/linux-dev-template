#!/usr/bin/env bash
# =============================================================================
# 00-base.sh
# =============================================================================
# Purpose:
#   Install the baseline packages that almost every later layer depends on.
#
# Why this exists:
#   This script installs a shared development foundation on Fedora and on
#   Ubuntu in WSL or OrbStack, using distribution-specific package names.
#
# Official references:
#   - Git on Linux: https://git-scm.com/install/linux
#   - WSL file/perf guidance: https://learn.microsoft.com/en-us/windows/wsl/filesystems
#
# Notes:
#   - Safe to re-run.
#   - Installs only broadly useful packages.
#   - Does not modify shell config or service config.
# =============================================================================
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"

main() {
  echo "[00-base] installing base packages..."
  install_module_packages base

  echo "[00-base] ensuring workspace layout exists..."
  mkdir -p "$HOME/workspace"/{apps,libs,infra,playground}
  mkdir -p "$HOME/bin"
  mkdir -p "$HOME/.local/bin"

  echo "[00-base] done."
}

main "$@"
