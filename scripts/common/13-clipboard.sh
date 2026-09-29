#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"

require_supported_environment
[[ "$OS_ID" == fedora && "$(detect_platform)" == native ]] || {
  printf '[13-clipboard] ERROR: configure clipboard tools on the terminal host for WSL/OrbStack\n' >&2
  exit 1
}
install_module_packages clipboard
command -v wl-copy >/dev/null
command -v wl-paste >/dev/null
printf '[13-clipboard] installed Wayland clipboard commands for terminal tools\n'
