#!/usr/bin/env bash
set -Eeuo pipefail

command -v wl-copy >/dev/null
command -v wl-paste >/dev/null
printf '[verify-clipboard] wl-copy and wl-paste are available\n'
