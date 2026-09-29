#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 15-tmux.sh
#
# 作用：
#   1. 安装 tmux 与安装插件所需的基础依赖
#   2. 安装 TPM（Tmux Plugin Manager）
#   3. 将模板中的 .tmux.conf 复制到用户家目录（默认不强制覆盖）
#   4. 给出后续启用插件的操作提示
#
# 设计原则：
#   - 尽量幂等：重复执行不会反复破坏环境
#   - 尽量保守：已有配置优先备份，不直接硬覆盖
#   - Fedora / WSL / OrbStack Ubuntu 都能使用
#
# 参考：
#   - TPM 官方建议通过 git clone 安装到 ~/.tmux/plugins/tpm
#   - tmux 插件通常在 tmux 会话内通过 prefix + I 安装
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 假定目录结构为：
# linux-dev-template/
#   scripts/common/15-tmux.sh
#   dotfiles/.tmux.conf
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"

TEMPLATE_TMUX_CONF="${REPO_ROOT}/dotfiles/.tmux.conf"
TARGET_TMUX_CONF="${HOME}/.tmux.conf"
TPM_DIR="${HOME}/.tmux/plugins/tpm"

log() {
  printf '[15-tmux] %s\n' "$*"
}

warn() {
  printf '[15-tmux] WARNING: %s\n' "$*" >&2
}

die() {
  printf '[15-tmux] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

backup_file_if_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    local backup="${file}.bak.${ts}"
    cp "$file" "$backup"
    log "existing file backed up: $file -> $backup"
  fi
}

install_tmux_packages() {
  log "installing tmux prerequisites..."
  install_module_packages tmux

  # 说明：
  # - tmux: 主程序
  # - git: 安装 TPM 和插件时需要
  # - Ubuntu 客户机保留 xclip / xsel 依赖
  # - Fedora desktop 配置通过 clipboard 模块提供 wl-copy / wl-paste
}

install_tpm() {
  mkdir -p "${HOME}/.tmux/plugins"

  if [ -d "${TPM_DIR}/.git" ]; then
    log "TPM already installed at ${TPM_DIR}, updating..."
    git -C "${TPM_DIR}" pull --ff-only || warn "failed to update TPM, keeping existing copy"
  else
    log "installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "${TPM_DIR}"
  fi
}

install_tmux_conf() {
  [ -f "${TEMPLATE_TMUX_CONF}" ] || die "template tmux config not found: ${TEMPLATE_TMUX_CONF}"

  if [ -f "${TARGET_TMUX_CONF}" ]; then
    if cmp -s "${TEMPLATE_TMUX_CONF}" "${TARGET_TMUX_CONF}"; then
      log "${HOME}/.tmux.conf already matches template, skipping copy"
      return 0
    fi

    backup_file_if_exists "${TARGET_TMUX_CONF}"
  fi

  cp "${TEMPLATE_TMUX_CONF}" "${TARGET_TMUX_CONF}"
  log "installed tmux config: ${TARGET_TMUX_CONF}"
}

print_next_steps() {
  cat <<'EON'
[15-tmux] tmux base installation completed.

Next steps:
  1. Start tmux:
       tmux

  2. Inside tmux, install plugins with:
       Prefix + I
     Note:
       - This template sets Prefix to Ctrl-a
       - So press: Ctrl-a Shift-i

  3. Reload tmux config at any time:
       Prefix + r

  4. Check tmux version:
       tmux -V

If plugin installation fails due to network/proxy issues:
  - verify GitHub access from this Linux environment
  - verify git/curl proxy settings
EON
}

main() {
  require_command sudo

  install_tmux_packages
  install_tpm
  install_tmux_conf
  print_next_steps

  log "done"
}

main "$@"
