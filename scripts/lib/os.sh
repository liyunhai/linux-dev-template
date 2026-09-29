#!/usr/bin/env bash

# Shared environment helpers. Call load_os_release before using OS_ID or
# OS_NAME. Installation currently targets Ubuntu in WSL 2 or OrbStack.

load_os_release() {
  local os_release_file="${OS_RELEASE_FILE:-/etc/os-release}"
  local ID="" PRETTY_NAME=""

  [[ -r "$os_release_file" ]] || {
    printf '[os] ERROR: OS release file not found: %s\n' "$os_release_file" >&2
    return 1
  }

  # shellcheck disable=SC1091
  source "$os_release_file"
  OS_ID="${ID:-unknown}"
  OS_NAME="${PRETTY_NAME:-$OS_ID}"

  export OS_ID OS_NAME
}

detect_platform() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    printf '%s' wsl
  elif [[ "$(uname -r)" == *[Oo]rbstack* ]] || [[ -e /opt/orbstack-guest ]]; then
    printf '%s' orbstack
  else
    printf '%s' native
  fi
}

require_supported_environment() {
  load_os_release || return 1
  local platform
  platform="$(detect_platform)"
  case "${OS_ID}:${platform}" in
    ubuntu:wsl|ubuntu:orbstack) return 0 ;;
    *)
      printf '[os] ERROR: Ubuntu in WSL 2 or OrbStack is required (detected: %s; platform: %s)\n' \
        "$OS_NAME" "$platform" >&2
      return 1
      ;;
  esac
}

systemd_is_active() {
  command -v systemctl >/dev/null 2>&1 \
    && [[ -d /run/systemd/system ]] \
    && systemctl show-environment >/dev/null 2>&1
}
