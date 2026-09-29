#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"
CONFIG_SOURCE="${REPO_ROOT}/dotfiles/.config/herdr/config.toml"
CONFIG_TARGET="${HOME}/.config/herdr/config.toml"
INSTALL_DIR="${HOME}/.local/bin"
RELEASE_MANIFEST_URL="https://herdr.dev/latest.json"

log() { printf '[17-herdr] %s\n' "$*"; }
die() { printf '[17-herdr] ERROR: %s\n' "$*" >&2; exit 1; }
require_command() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1 (run 00-base.sh first)"; }

platform_key() {
  case "$(uname -m)" in
    x86_64) printf '%s' 'linux-x86_64' ;;
    aarch64|arm64) printf '%s' 'linux-aarch64' ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac
}

install_herdr() (
  local key tmpdir manifest url checksum binary
  key="$(platform_key)"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf -- "$tmpdir"' EXIT
  manifest="${tmpdir}/latest.json"
  binary="${tmpdir}/herdr"

  log "downloading latest stable release metadata..."
  curl -fL --retry 3 "$RELEASE_MANIFEST_URL" -o "$manifest"
  url="$(jq -er --arg key "$key" '.assets[$key]' "$manifest")" || die "release asset missing for $key"
  checksum="$(jq -er --arg key "$key" '.sha256[$key]' "$manifest")" || die "release checksum missing for $key"
  curl -fL --retry 3 "$url" -o "$binary"
  printf '%s  %s\n' "$checksum" "$binary" | sha256sum -c -

  mkdir -p "$INSTALL_DIR"
  install -m 0755 "$binary" "${INSTALL_DIR}/herdr"
)

install_config() {
  [[ -f "$CONFIG_SOURCE" ]] || die "config template not found: $CONFIG_SOURCE"
  mkdir -p "$(dirname "$CONFIG_TARGET")"
  if [[ -f "$CONFIG_TARGET" ]] && ! cmp -s "$CONFIG_SOURCE" "$CONFIG_TARGET"; then
    cp -a "$CONFIG_TARGET" "${CONFIG_TARGET}.bak.$(date +%Y%m%d-%H%M%S)"
    log "backed up existing config"
  fi
  cp "$CONFIG_SOURCE" "$CONFIG_TARGET"
}

main() {
  require_supported_environment
  require_command curl
  require_command jq
  require_command sha256sum
  install_herdr
  install_config
  "${INSTALL_DIR}/herdr" --version
  "${INSTALL_DIR}/herdr" config check
  log "done; start with: herdr"
}

main "$@"
