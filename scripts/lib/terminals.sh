#!/usr/bin/env bash

# Configuration-only modules for terminals already installed on native Fedora.
# shellcheck source=os.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/os.sh"
# shellcheck source=config.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config.sh"

install_terminal_config() {
  local terminal="$1" filename config_home matched_family
  config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  case "$terminal" in
    alacritty) filename=alacritty.toml ;;
    ghostty) filename=config.ghostty ;;
    *) printf '[terminals] ERROR: unknown terminal: %s\n' "$terminal" >&2; return 1 ;;
  esac

  require_supported_environment || return 1
  [[ "$OS_ID" == fedora && "$(detect_platform)" == native ]] || {
    printf '[terminals] ERROR: configure the terminal on the host for WSL/OrbStack\n' >&2
    return 1
  }
  [[ "$EUID" -ne 0 ]] || {
    printf '[terminals] ERROR: run as your normal user, not with sudo\n' >&2
    return 1
  }
  [[ "$config_home" == /* ]] || {
    printf '[terminals] ERROR: XDG_CONFIG_HOME must be an absolute path\n' >&2
    return 1
  }
  command -v "$terminal" >/dev/null 2>&1 || {
    printf '[terminals] ERROR: install %s before selecting its configuration module\n' "$terminal" >&2
    return 1
  }
  command -v fc-match >/dev/null 2>&1 || {
    printf '[terminals] ERROR: install the nerd-font module first\n' >&2
    return 1
  }
  matched_family="$(fc-match -f '%{family[0]}' 'JetBrainsMono Nerd Font')" || return 1
  [[ "$matched_family" == 'JetBrainsMono Nerd Font' ]] || {
    printf '[terminals] ERROR: JetBrainsMono Nerd Font is missing; install the nerd-font module first\n' >&2
    return 1
  }

  install_config_file "${REPO_ROOT}/dotfiles/.config/${terminal}/${filename}" \
    "${config_home}/${terminal}/${filename}" || return 1
  printf '[terminals] %s configured; reopen the terminal to review the appearance\n' "$terminal"
}
