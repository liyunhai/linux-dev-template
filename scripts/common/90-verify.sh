#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 90-verify.sh
#
# 作用：
#   统一执行模板中的所有验证脚本。
#
# 说明：
#   - 每个验证脚本负责一个模块
#   - 本脚本只负责按顺序调用，并给出整体结果
#   - 如果其中任何一个脚本返回非 0，本脚本会直接失败退出
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CHECKS_DIR="${REPO_ROOT}/checks"

log() {
  printf '[90-verify] %s\n' "$*"
}

run_check() {
  local check_script="$1"

  if [ ! -x "${check_script}" ]; then
    log "making executable: ${check_script}"
    chmod +x "${check_script}"
  fi

  "${check_script}"
}

run_module_check() {
  local module="$1" check_name="$2"
  [[ -n "${REQUESTED_MODULES[$module]:-}" ]] || return 0
  run_check "${CHECKS_DIR}/${check_name}"
}

main() {
  local module
  declare -A REQUESTED_MODULES=()
  if (($#)); then
    for module in "$@"; do REQUESTED_MODULES["$module"]=true; done
  else
    for module in shell tmux zellij herdr yazi python node; do
      REQUESTED_MODULES["$module"]=true
    done
  fi

  log "running checks..."

  run_module_check shell verify-shell.sh
  run_module_check nerd-font verify-nerd-font.sh
  run_module_check tmux verify-tmux.sh
  run_module_check zellij verify-zellij.sh
  run_module_check herdr verify-herdr.sh
  run_module_check yazi verify-yazi.sh
  run_module_check python verify-python.sh
  run_module_check node verify-node.sh
  run_module_check postgres verify-postgres.sh
  run_module_check nginx verify-nginx.sh

  log "all checks passed"
}

main "$@"
