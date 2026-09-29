#!/usr/bin/env bash
# =============================================================================
# 99-orb-notes.sh
# =============================================================================
# Purpose:
#   Print host-side OrbStack reminders.
# =============================================================================
set -Eeuo pipefail

cat <<'EOF2'
OrbStack reminders:
- machines can be managed with: orb help
- keep your Ubuntu machine's shell, Python, Node, and project layout aligned with WSL
- machines typically resolve as: <machine-name>.orb.local
EOF2
