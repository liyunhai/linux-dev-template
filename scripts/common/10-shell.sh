#!/usr/bin/env bash
# =============================================================================
# 10-shell.sh
# =============================================================================
# Purpose:
#   Install zsh, Oh My Zsh, Powerlevel10k, and common zsh plugins.
#
# Why this exists:
#   We want the interactive shell experience to be nearly identical between
#   Fedora, WSL Ubuntu, and OrbStack Ubuntu.
#
# Official references:
#   - Oh My Zsh: https://ohmyz.sh/
#   - Nerd Fonts: https://www.nerdfonts.com/
#
# Important:
#   - Nerd Fonts must be installed on the terminal host OS for WSL/OrbStack.
#   - Existing .zshrc files are preserved unless --install-zshrc-template is
#     explicitly provided. The original is backed up before replacement.
# =============================================================================
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
CHANGE_DEFAULT_SHELL="${CHANGE_DEFAULT_SHELL:-false}"
INSTALL_ZSHRC_TEMPLATE=false

# shellcheck source=../lib/config.sh
source "${REPO_ROOT}/scripts/lib/config.sh"

clone_or_update() {
  local repo_url="$1"
  local target_dir="$2"

  if [[ -d "$target_dir/.git" ]]; then
    echo "[10-shell] updating $(basename "$target_dir")..."
    git -C "$target_dir" pull --ff-only
  else
    echo "[10-shell] cloning $(basename "$target_dir")..."
    git clone --depth=1 "$repo_url" "$target_dir"
  fi
}

usage() {
  cat <<'EOF'
Usage: ./scripts/common/10-shell.sh [--install-zshrc-template] [--set-default-shell]

Options:
  --install-zshrc-template  Back up and replace an existing ~/.zshrc with the
                            project template. Without this option, an existing
                            user configuration is preserved.
  --set-default-shell       Change this user's login shell to zsh with chsh.
  -h, --help                Show this help.
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --install-zshrc-template) INSTALL_ZSHRC_TEMPLATE=true ;;
      --set-default-shell) CHANGE_DEFAULT_SHELL=true ;;
      -h|--help) usage; exit 0 ;;
      *) printf '[10-shell] ERROR: unknown option: %s\n' "$1" >&2; exit 1 ;;
    esac
    shift
  done
}

main() {
  parse_args "$@"
  local zshrc_existed_before_install=false command_name
  [[ ! -f "$HOME/.zshrc" ]] || zshrc_existed_before_install=true

  for command_name in git curl fzf; do
    command -v "$command_name" >/dev/null 2>&1 || {
      printf '[10-shell] ERROR: %s is required; run 00-base.sh first\n' "$command_name" >&2
      exit 1
    }
  done

  echo "[10-shell] installing zsh and shell helpers..."
  install_module_packages shell

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "[10-shell] installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "[10-shell] Oh My Zsh already installed."
  fi

  mkdir -p "$ZSH_CUSTOM_DIR/themes" "$ZSH_CUSTOM_DIR/plugins"

  clone_or_update https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git \
    "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
  clone_or_update https://github.com/zsh-users/zsh-completions.git \
    "$ZSH_CUSTOM_DIR/plugins/zsh-completions"

  echo "[10-shell] installing dotfiles into ~/.config/shell ..."
  install_config_file "$REPO_ROOT/dotfiles/shell/aliases.zsh" "$HOME/.config/shell/aliases.zsh"
  install_config_file "$REPO_ROOT/dotfiles/shell/exports.zsh" "$HOME/.config/shell/exports.zsh"
  install_config_file "$REPO_ROOT/dotfiles/shell/functions.zsh" "$HOME/.config/shell/functions.zsh"

  if ! "$zshrc_existed_before_install" || "$INSTALL_ZSHRC_TEMPLATE"; then
    # The Oh My Zsh installer creates a starter .zshrc. Replace that generated
    # file with this template only when the user had no .zshrc before the run.
    install_config_file "$REPO_ROOT/dotfiles/.zshrc" "$HOME/.zshrc"
    echo "[10-shell] installed project ~/.zshrc"
  else
    echo "[10-shell] ~/.zshrc already exists; not overwriting."
    echo "[10-shell] compare with: $REPO_ROOT/dotfiles/.zshrc"
  fi

  if [[ ! -f "$HOME/.p10k.zsh" ]]; then
    cp "$REPO_ROOT/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
  fi

  if "$CHANGE_DEFAULT_SHELL" \
    && [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    echo "[10-shell] changing default shell to zsh..."
    command -v chsh >/dev/null 2>&1 || {
      printf '[10-shell] ERROR: chsh is required to change the login shell\n' >&2
      exit 1
    }
    chsh -s "$(command -v zsh)"
  elif ! "$CHANGE_DEFAULT_SHELL"; then
    echo "[10-shell] keeping the current login shell; use --set-default-shell to change it."
  fi

  cat <<MSG
[10-shell] done.
[10-shell] next steps:
  1. Select JetBrainsMono Nerd Font in the Fedora terminal, or install and select
     a Nerd Font on the Windows/macOS terminal host for WSL/OrbStack.
  2. After changing the login shell, log out and back in to start zsh.
     To change it later, run this script with --set-default-shell.
  3. Optionally run: p10k configure
MSG
}

main "$@"
