#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"
CONFIG_SOURCE="${REPO_ROOT}/dotfiles/.config/zellij/config.kdl"
CONFIG_TARGET="${HOME}/.config/zellij/config.kdl"
INSTALL_DIR="${HOME}/.local/bin"

log() { printf '[16-zellij] %s\n' "$*"; }
die() { printf '[16-zellij] ERROR: %s\n' "$*" >&2; exit 1; }
require_command() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1 (run 00-base.sh first)"; }

release_asset() {
  case "$(uname -m)" in
    x86_64) printf '%s' 'zellij-x86_64-unknown-linux-musl.tar.gz' ;;
    aarch64|arm64) printf '%s' 'zellij-aarch64-unknown-linux-musl.tar.gz' ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac
}

install_zellij() (
  local asset checksum_asset tmpdir archive checksum_file expected_checksum
  asset="$(release_asset)"
  checksum_asset="${asset%.tar.gz}.sha256sum"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf -- "$tmpdir"' EXIT
  archive="${tmpdir}/${asset}"
  checksum_file="${tmpdir}/${checksum_asset}"

  log "downloading latest stable release for $(uname -m)..."
  curl -fL --retry 3 "https://github.com/zellij-org/zellij/releases/latest/download/${checksum_asset}" -o "$checksum_file"
  curl -fL --retry 3 "https://github.com/zellij-org/zellij/releases/latest/download/${asset}" -o "$archive"
  tar -xzf "$archive" -C "$tmpdir"
  [[ -x "${tmpdir}/zellij" ]] || die "release archive does not contain zellij"

  expected_checksum="$(awk 'NR == 1 { print $1 }' "$checksum_file")"
  [[ "$expected_checksum" =~ ^[[:xdigit:]]{64}$ ]] || die "invalid release checksum"
  printf '%s  %s\n' "$expected_checksum" "${tmpdir}/zellij" | sha256sum -c -

  mkdir -p "$INSTALL_DIR"
  install -m 0755 "${tmpdir}/zellij" "${INSTALL_DIR}/zellij"
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
  require_command tar
  require_command sha256sum
  install_zellij
  install_config
  "${INSTALL_DIR}/zellij" --version
  log "done; start with: zellij"
}

main "$@"
