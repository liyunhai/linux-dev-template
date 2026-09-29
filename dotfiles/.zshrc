# ~/.zshrc
#
# Shared zsh configuration for Fedora and WSL/OrbStack Ubuntu development machines.
#
# Design goals:
# - readable and easy to modify
# - minimize platform-specific branches
# - keep terminal host settings out of WSL/OrbStack guests

export ZSH="$HOME/.oh-my-zsh"

# Prefer a deterministic theme path. Powerlevel10k is installed manually under
# ${ZSH_CUSTOM}/themes/powerlevel10k.
ZSH_THEME="powerlevel10k/powerlevel10k"

# Oh My Zsh plugins. Keep this list modest; too many plugins slow startup.
plugins=(
  git
  fzf
  z
  extract
  sudo
  python
  pip
  node
  npm
  direnv
  colored-man-pages
  command-not-found
)

# Load Oh My Zsh first.
source "$ZSH/oh-my-zsh.sh"

# Add local user binaries to PATH.
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# NVM setup. The install script writes here by default.
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# direnv hook. It becomes active after the direnv module is installed.
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# uv (Astral) default binary path lives under ~/.local/bin for standalone install.
# Nothing special is required if PATH already includes ~/.local/bin.

# Common aliases and helper functions.
[[ -f "$HOME/.config/shell/aliases.zsh" ]] && source "$HOME/.config/shell/aliases.zsh"
[[ -f "$HOME/.config/shell/exports.zsh" ]] && source "$HOME/.config/shell/exports.zsh"
[[ -f "$HOME/.config/shell/functions.zsh" ]] && source "$HOME/.config/shell/functions.zsh"

# Third-party zsh plugins installed outside Oh My Zsh's bundled plugin set.
[[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
  && source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
  && source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions/src" ]] \
  && fpath+=("${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions/src")

# Powerlevel10k configuration.
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
