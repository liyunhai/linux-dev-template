#!/usr/bin/env bash

# Shared environment helpers for Fedora and Ubuntu in WSL 2 or OrbStack.

load_os_release() {
  local os_release_file="${OS_RELEASE_FILE:-/etc/os-release}"
  local ID="" PRETTY_NAME="" VERSION_ID="" VARIANT_ID=""

  [[ -r "$os_release_file" ]] || {
    printf '[os] ERROR: OS release file not found: %s\n' "$os_release_file" >&2
    return 1
  }

  # shellcheck disable=SC1091
  source "$os_release_file"
  OS_ID="${ID:-unknown}"
  OS_NAME="${PRETTY_NAME:-$OS_ID}"
  OS_VERSION_ID="${VERSION_ID:-}"
  OS_VARIANT_ID="${VARIANT_ID:-}"
  case "$OS_ID" in
    ubuntu) PACKAGE_MANAGER=apt ;;
    fedora) PACKAGE_MANAGER=dnf ;;
    *) PACKAGE_MANAGER="" ;;
  esac

  export OS_ID OS_NAME OS_VERSION_ID OS_VARIANT_ID PACKAGE_MANAGER
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
    fedora:native)
      if [[ -e /run/ostree-booted ]]; then
        printf '[os] ERROR: a Fedora installation managed by dnf is required\n' >&2
        return 1
      fi
      return 0
      ;;
    *)
      printf '[os] ERROR: Fedora with dnf, or Ubuntu in WSL 2 or OrbStack, is required (detected: %s; platform: %s)\n' \
        "$OS_NAME" "$platform" >&2
      return 1
      ;;
  esac
}

default_install_profile() {
  load_os_release || return 1
  if [[ "$OS_ID" == fedora && "$OS_VARIANT_ID" == workstation ]]; then
    printf '%s' desktop
  else
    printf '%s' cli
  fi
}

systemd_is_active() {
  command -v systemctl >/dev/null 2>&1 \
    && [[ -d /run/systemd/system ]] \
    && systemctl show-environment >/dev/null 2>&1
}
