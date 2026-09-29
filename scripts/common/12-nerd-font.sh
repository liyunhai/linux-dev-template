#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"

FONT_FAMILY="JetBrainsMono Nerd Font"
FONT_DIR="${HOME}/.local/share/fonts/JetBrainsMono-NF"
RELEASE_API="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
ASSET_NAME="JetBrainsMono.zip"
FORCE_INSTALL=false

FONT_FILES=(
  JetBrainsMonoNerdFont-Regular.ttf
  JetBrainsMonoNerdFont-Bold.ttf
  JetBrainsMonoNerdFont-Italic.ttf
  JetBrainsMonoNerdFont-BoldItalic.ttf
)

log() { printf '[12-nerd-font] %s\n' "$*"; }
die() { printf '[12-nerd-font] ERROR: %s\n' "$*" >&2; exit 1; }
require_command() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1 (run 00-base.sh first)"; }

usage() {
  cat <<'EOF'
Usage: ./scripts/common/12-nerd-font.sh [--force]

Installs the regular, bold, italic, and bold-italic JetBrainsMono Nerd Font
variants for the current user. Existing files are retained unless --force is
provided.
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --force) FORCE_INSTALL=true ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done
}

fonts_are_installed() {
  local name
  for name in "${FONT_FILES[@]}"; do
    [[ -f "${FONT_DIR}/${name}" ]] || return 1
  done
}

install_fontconfig() {
  if ! command -v fc-cache >/dev/null 2>&1 || ! command -v fc-match >/dev/null 2>&1; then
    log "installing fontconfig..."
    install_module_packages nerd-font
  fi
}

install_fonts() (
  local tmpdir metadata archive url digest source_file name
  tmpdir="$(mktemp -d)"
  trap 'rm -rf -- "$tmpdir"' EXIT
  metadata="${tmpdir}/release.json"
  archive="${tmpdir}/${ASSET_NAME}"

  log "downloading latest ${FONT_FAMILY} release metadata..."
  curl -fL --retry 3 "$RELEASE_API" -o "$metadata"
  url="$(jq -er --arg asset "$ASSET_NAME" '.assets[] | select(.name == $asset) | .browser_download_url' "$metadata")" \
    || die "release asset not found: $ASSET_NAME"
  digest="$(jq -er --arg asset "$ASSET_NAME" '.assets[] | select(.name == $asset) | .digest | sub("^sha256:"; "")' "$metadata")" \
    || die "release checksum not found: $ASSET_NAME"

  curl -fL --retry 3 "$url" -o "$archive"
  [[ "$digest" =~ ^[[:xdigit:]]{64}$ ]] || die "invalid release checksum"
  printf '%s  %s\n' "$digest" "$archive" | sha256sum -c -
  unzip -q "$archive" -d "${tmpdir}/unpacked"

  mkdir -p "$FONT_DIR"
  for name in "${FONT_FILES[@]}"; do
    source_file="$(find "${tmpdir}/unpacked" -type f -name "$name" -print -quit)"
    [[ -n "$source_file" ]] || die "font file not found in release: $name"
    install -m 0644 "$source_file" "${FONT_DIR}/${name}"
  done
)

verify_font() {
  local matched_family
  fc-cache -f "$FONT_DIR"
  matched_family="$(fc-match -f '%{family[0]}' "$FONT_FAMILY")"
  [[ "$matched_family" == "$FONT_FAMILY" ]] \
    || die "fontconfig did not select ${FONT_FAMILY} (selected: ${matched_family})"
  log "font installed: $(fc-match -f '%{family[0]} %{style[0]}\n' "$FONT_FAMILY")"
}

main() {
  parse_args "$@"
  require_supported_environment
  [[ "$OS_ID" == fedora && "$(detect_platform)" == native ]] || die "install fonts on the terminal host for WSL/OrbStack"
  require_command curl
  require_command jq
  require_command unzip
  require_command sha256sum
  require_command find
  install_fontconfig
  if ! "$FORCE_INSTALL" && fonts_are_installed; then
    log "requested font files are already installed; skipping download"
  else
    install_fonts
  fi
  verify_font

  cat <<'EOF'
[12-nerd-font] done.
[12-nerd-font] Select "JetBrainsMono Nerd Font" (not "Mono" or "Propo") in
[12-nerd-font] the terminal profile, then fully close and reopen the terminal.
EOF
}

main "$@"
