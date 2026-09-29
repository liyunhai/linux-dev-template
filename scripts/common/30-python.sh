#!/usr/bin/env bash
# =============================================================================
# 30-python.sh
# =============================================================================
# Purpose:
#   Install the Python development toolchain:
#   - system python
#   - venv (a separate package on Ubuntu)
#   - python3-pip
#   - pipx
#   - uv
#   - common quality tools
#
# Why this stack:
#   For a reusable dev template, `venv + pipx + uv` is lighter and simpler than
#   making Conda the default.
#
# Official references:
#   - Python venv: https://docs.python.org/3/library/venv.html
#   - uv install: https://docs.astral.sh/uv/getting-started/installation/
#   - pre-commit: https://pre-commit.com/
# =============================================================================
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"

# shellcheck source=../lib/config.sh
source "${REPO_ROOT}/scripts/lib/config.sh"

main() {
  echo "[30-python] installing Python system packages..."
  install_module_packages python

  echo "[30-python] ensuring pip config exists..."
  install_config_file \
    "$REPO_ROOT/dotfiles/.config/pip/pip.conf" \
    "$HOME/.config/pip/pip.conf"

  echo "[30-python] ensuring pipx path..."
  python3 -m pipx ensurepath

  if ! command -v uv >/dev/null 2>&1; then
    echo "[30-python] installing uv via official installer..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
  else
    echo "[30-python] uv already present."
  fi

  export PATH="$HOME/.local/bin:$PATH"

  echo "[30-python] installing python dev tools with pipx..."
  pipx install --force ruff
  pipx install --force black
  pipx install --force pytest
  pipx install --force pre-commit

  cat <<MSG
[30-python] done.
[30-python] recommended checks:
  python3 --version
  uv --version
  pipx list
MSG
}

main "$@"
