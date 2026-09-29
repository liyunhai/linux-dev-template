#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/terminals.sh
source "${REPO_ROOT}/scripts/lib/terminals.sh"

install_terminal_config alacritty
