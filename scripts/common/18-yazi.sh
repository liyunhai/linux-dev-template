#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"
CONFIG_SOURCE="${REPO_ROOT}/dotfiles/.config/yazi"
CONFIG_TARGET="${HOME}/.config/yazi"
INSTALL_DIR="${HOME}/.local/bin"
RELEASE_API="https://api.github.com/repos/sxyazi/yazi/releases/latest"

log() { printf '[18-yazi] %s\n' "$*"; }
die() { printf '[18-yazi] ERROR: %s\n' "$*" >&2; exit 1; }
require_command() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1 (run 00-base.sh first)"; }

release_asset() {
  case "$(uname -m)" in
    x86_64) printf '%s' 'yazi-x86_64-unknown-linux-gnu.zip' ;;
    aarch64|arm64) printf '%s' 'yazi-aarch64-unknown-linux-gnu.zip' ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac
}

install_prerequisites() {
  log "installing preview and navigation helpers..."
  install_module_packages yazi
}

install_yazi() (
  local asset tmpdir metadata url digest archive extracted_dir
  asset="$(release_asset)"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf -- "$tmpdir"' EXIT
  metadata="${tmpdir}/release.json"
  archive="${tmpdir}/${asset}"

  log "downloading latest stable Yazi release..."
  curl -fL --retry 3 "$RELEASE_API" -o "$metadata"
  url="$(jq -er --arg asset "$asset" '.assets[] | select(.name == $asset) | .browser_download_url' "$metadata")" \
    || die "release asset not found: $asset"
  digest="$(jq -er --arg asset "$asset" '.assets[] | select(.name == $asset) | .digest | sub("^sha256:"; "")' "$metadata")" \
    || die "release checksum not found: $asset"
  curl -fL --retry 3 "$url" -o "$archive"
  printf '%s  %s\n' "$digest" "$archive" | sha256sum -c -

  unzip -q "$archive" -d "$tmpdir/unpacked"
  extracted_dir="$(find "$tmpdir/unpacked" -mindepth 1 -maxdepth 1 -type d -print -quit)"
  [[ -n "$extracted_dir" && -x "${extracted_dir}/yazi" && -x "${extracted_dir}/ya" ]] \
    || die "release archive does not contain yazi and ya"
  mkdir -p "$INSTALL_DIR"
  install -m 0755 "${extracted_dir}/yazi" "${INSTALL_DIR}/yazi"
  install -m 0755 "${extracted_dir}/ya" "${INSTALL_DIR}/ya"
)

ensure_fd_compat() {
  if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    mkdir -p "$INSTALL_DIR"
    ln -sfn "$(command -v fdfind)" "${INSTALL_DIR}/fd"
  fi
}

install_config() {
  [[ -d "$CONFIG_SOURCE" ]] || die "config template not found: $CONFIG_SOURCE"
  mkdir -p "$CONFIG_TARGET"
  local name source target
  for name in yazi.toml keymap.toml theme.toml init.lua; do
    source="${CONFIG_SOURCE}/${name}"
    target="${CONFIG_TARGET}/${name}"
    [[ -f "$source" ]] || die "missing config template: $source"
    if [[ -f "$target" ]] && ! cmp -s "$source" "$target"; then
      cp -a "$target" "${target}.bak.$(date +%Y%m%d-%H%M%S)"
      log "backed up existing ${name}"
    fi
    cp "$source" "$target"
  done
}

main() {
  require_command sudo
  require_command curl
  require_command jq
  require_command unzip
  require_command sha256sum
  install_prerequisites
  install_yazi
  ensure_fd_compat
  install_config
  "${INSTALL_DIR}/yazi" --version
  "${INSTALL_DIR}/ya" --version
  log "done; start with: yazi"
}

main "$@"
