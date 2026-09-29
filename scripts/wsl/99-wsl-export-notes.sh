#!/usr/bin/env bash
# =============================================================================
# 99-wsl-export-notes.sh
# =============================================================================
# Purpose:
#   Print reminders for exporting/importing this WSL distro as a reusable base.
#
# Why this is not automated:
#   Export/import is usually best run from Windows, where you decide the target
#   file paths and naming convention.
# =============================================================================
set -Eeuo pipefail

cat <<'EOF2'
From Windows PowerShell, example export/import commands:

  wsl --shutdown
  wsl --export Ubuntu-24.04 D:\WSL\ubuntu-dev-template.tar
  wsl --import Ubuntu-24.04-Dev D:\WSL\Ubuntu-24.04-Dev D:\WSL\ubuntu-dev-template.tar --version 2

After import, launch the new distro and verify:
  - systemd is active
  - terminal development tools work
  - any selected postgres/nginx services work
  - dotfiles are in place
EOF2
