#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 15-tmux.sh
#
# 作用：
#   1. 检查已有 Git，安装 tmux（Ubuntu 保留 xclip/xsel）
#   2. 安装 TPM（Tmux Plugin Manager）
#   3. 备份有差异的 ~/.tmux.conf 后安装项目配置
#   4. 在独立的临时 tmux 服务中自动安装配置声明的插件
#   5. 支持 --dry-run 查看计划，不执行安装
#
# 设计原则：
#   - 尽量幂等：重复执行不会反复破坏环境
#   - 尽量保守：已有配置优先备份，不直接硬覆盖
#   - Fedora / WSL / OrbStack Ubuntu 都能使用
#
# 参考：
#   - TPM 官方建议通过 git clone 安装到 ~/.tmux/plugins/tpm
#   - TPM 提供 bin/install_plugins 命令行入口
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 假定目录结构为：
# linux-dev-template/
#   scripts/common/15-tmux.sh
#   dotfiles/.tmux.conf
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"
# shellcheck source=../lib/config.sh
source "${REPO_ROOT}/scripts/lib/config.sh"

TEMPLATE_TMUX_CONF="${REPO_ROOT}/dotfiles/.tmux.conf"
TARGET_TMUX_CONF="${HOME}/.tmux.conf"
TPM_DIR="${HOME}/.tmux/plugins/tpm"
DRY_RUN=false

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

parse_args() {
  while (($#)); do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
      -h|--help)
        printf 'Usage: ./scripts/common/15-tmux.sh [--dry-run]\n'
        exit 0
        ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done
}

print_plan() {
  log "dry-run: no packages, configuration, plugins, or tmux services will be changed"
  printf '  packages (%s):\n' "$PACKAGE_MANAGER"
  packages_for_module tmux
  printf '  TPM: clone or update %s\n' "$TPM_DIR"
  printf '  config: %s -> %s (back up differences)\n' "$TEMPLATE_TMUX_CONF" "$TARGET_TMUX_CONF"
  printf '  plugins: install @plugin entries in %s through TPM bin/install_plugins\n' "$TEMPLATE_TMUX_CONF"
  printf '  temporary tmux service: separate socket, cleaned up after installation\n'
  printf '  requires: Git installed by 00-base.sh; optional Wayland clipboard tools come from 13-clipboard.sh\n'
  printf '  requires: ~/.tmux.conf as the active user config; consolidate an existing XDG tmux/tmux.conf first\n'
}

install_tmux_packages() {
  log "installing tmux packages..."
  install_module_packages tmux

  # 说明：
  # - tmux: 主程序
  # - Git 由 00-base 提供；这里只检测，不安装
  # - Ubuntu 客户机保留 xclip / xsel 依赖
  # - Wayland 剪贴板工具由独立的 13-clipboard 模块提供
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
  install_config_file "$TEMPLATE_TMUX_CONF" "$TARGET_TMUX_CONF"
}

install_tmux_plugins() (
  # TPM's CLI uses tmux commands to read its manager path. A dedicated server
  # supplies that environment without loading plugins or changing live sessions.
  local setup_dir socket server_pid
  [[ -x "${TPM_DIR}/bin/install_plugins" ]] || die "TPM plugin installer not found"
  unset TMUX
  setup_dir="$(mktemp -d)"
  socket="${setup_dir}/tmux.sock"
  trap 'tmux -S "$socket" kill-server >/dev/null 2>&1 || true; rm -rf -- "$setup_dir"' EXIT

  log "installing tmux plugins..."
  tmux -S "$socket" -f /dev/null new-session -d -s plugin-install 'cat'
  tmux -S "$socket" set-environment -g TMUX_PLUGIN_MANAGER_PATH "${HOME}/.tmux/plugins/"
  server_pid="$(tmux -S "$socket" display-message -p '#{pid}')"

  # TPM prioritizes an XDG config. Point only the installer's config lookup at
  # our chosen file, so an unrelated XDG tmux config cannot supply the list.
  mkdir -p "${setup_dir}/tmux"
  ln -s "$TARGET_TMUX_CONF" "${setup_dir}/tmux/tmux.conf"
  TMUX="${socket},${server_pid},0" XDG_CONFIG_HOME="$setup_dir" \
    "${TPM_DIR}/bin/install_plugins" || die "plugin installation failed; check GitHub access and rerun 15-tmux.sh"
  log "plugin installation complete; existing plugins were retained"
)

print_next_steps() {
  cat <<'EON'
[15-tmux] tmux, configuration, and plugin installation completed.

Next steps:
  1. Start tmux:
       tmux

  2. If tmux was already running, reload its config:
       Prefix + r
     This template uses Ctrl-a as Prefix. If the existing session uses another
     Prefix, run inside it: tmux source-file ~/.tmux.conf

  3. Check tmux version:
       tmux -V

Plugins are installed automatically. Prefix + I remains available for manual
installation later. Existing plugin repositories are not updated by that step.
EON
}

main() {
  parse_args "$@"
  require_supported_environment
  if "$DRY_RUN"; then
    print_plan
    return 0
  fi
  [[ "$EUID" -ne 0 ]] || die "run as your normal user, not with sudo"
  require_command sudo
  command -v git >/dev/null 2>&1 || die "git is required for TPM and plugins; run 00-base.sh first"
  [[ -f "$TEMPLATE_TMUX_CONF" ]] || die "template tmux config not found: $TEMPLATE_TMUX_CONF"

  # The template and reload shortcut use ~/.tmux.conf. Tmux and TPM prioritize
  # an existing XDG config, so refuse ambiguity before installing anything.
  local xdg_conf="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
  [[ ! -f "$xdg_conf" ]] || die "existing XDG tmux config takes precedence: $xdg_conf; consolidate it into ~/.tmux.conf before using this installer"

  install_tmux_packages
  install_tpm
  install_tmux_conf
  install_tmux_plugins
  print_next_steps

  log "done"
}

main "$@"
