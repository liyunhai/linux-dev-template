#!/usr/bin/env bash
# =============================================================================
# 40-node.sh
# =============================================================================
# Purpose:
#   Install Node.js via nvm and then install common global developer tools.
#
# Why nvm:
#   nvm makes it easy to keep the template aligned with the current LTS release
#   while still allowing project-specific version pinning later.
#
# Official references:
#   - Node download page (nvm guidance): https://nodejs.org/en/download
#
# Notes:
#   - This script uses `nvm install --lts` so you do not need to hard-code a
#     Node version into the template.
# =============================================================================
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"

NVM_VERSION="v0.40.3"
export NVM_DIR="$HOME/.nvm"

load_nvm() {
  # shellcheck disable=SC1091
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
}

main() {
  echo "[40-node] installing prerequisites..."
  install_module_packages node

  if [[ ! -d "$NVM_DIR" ]]; then
    echo "[40-node] installing nvm..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
  else
    echo "[40-node] nvm already installed."
  fi

  load_nvm

  echo "[40-node] installing latest LTS Node.js..."
  nvm install --lts
  nvm alias default 'lts/*'
  nvm use default

  echo "[40-node] updating npm and installing global packages..."
  npm install -g npm@latest pnpm typescript tsx eslint prettier pm2 npm-check-updates

  cat <<MSG
[40-node] done.
[40-node] recommended checks:
  node -v
  npm -v
  pnpm -v
MSG
}

main "$@"
