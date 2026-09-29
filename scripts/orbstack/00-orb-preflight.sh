#!/usr/bin/env bash
# =============================================================================
# 00-orb-preflight.sh
# =============================================================================
# Purpose:
#   Run a light preflight inside an OrbStack Ubuntu machine.
#
# Official references:
#   - OrbStack machines: https://docs.orbstack.dev/machines/
#   - OrbStack commands: https://docs.orbstack.dev/machines/commands
# =============================================================================
set -Eeuo pipefail

main() {
  echo "[orb-preflight] hostname: $(hostname)"
  echo "[orb-preflight] kernel: $(uname -r)"
  echo "[orb-preflight] init process: $(ps -p 1 -o comm= | tr -d ' ')"
}

main "$@"
