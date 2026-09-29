#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${REPO_ROOT}/scripts/lib/packages.sh"

DRY_RUN=false
CURRENT_STEP="startup"
PROFILE=""
WITH_MODULES=""
SKIP_MODULES=""
CHANGE_DEFAULT_SHELL=false

ALL_MODULES=(
  base shell nerd-font clipboard tmux zellij herdr yazi direnv python node db-clients
  postgres nginx devtools
)
CLI_MODULES=(
  base shell tmux zellij herdr yazi direnv python node db-clients
  devtools
)
DESKTOP_MODULES=("${CLI_MODULES[@]}" nerd-font clipboard)

log() { printf '[bootstrap] %s\n' "$*"; }
die() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

Installs a development environment on Fedora or Ubuntu in WSL 2 or OrbStack.
Fedora Workstation defaults to desktop; Fedora Server and Ubuntu guests default
to cli. PostgreSQL and nginx are optional modules.

Options:
  --profile PROFILE       Use cli or desktop instead of auto-detection.
  --with MODULES          Add comma-separated modules to the profile.
  --skip MODULES          Remove comma-separated modules from the profile.
  --set-default-shell     Change the login shell to zsh after installing it.
  --dry-run               Print the execution plan without changing the system.
  -h, --help              Show this help.

Modules:
  base, shell, nerd-font, clipboard, tmux, zellij, herdr, yazi, direnv, python, node,
  db-clients, postgres, nginx, devtools

Examples:
  ./bootstrap.sh --dry-run
  ./bootstrap.sh --with postgres,nginx --dry-run
  ./bootstrap.sh --profile cli --skip herdr --set-default-shell
EOF
}

check_host() {
  if ! "$DRY_RUN" && [[ "$EUID" -eq 0 ]]; then
    die "run as your normal user, not with sudo"
  fi
  load_os_release || exit 1
  declare -g PLATFORM
  PLATFORM="$(detect_platform)"
  log "detected OS: $OS_NAME"
  log "detected platform: $PLATFORM"
  require_supported_environment || exit 1
}

run_script() {
  local relative_path="$1"
  shift
  CURRENT_STEP="$relative_path"
  [[ -f "${REPO_ROOT}/${relative_path}" ]] || die "script not found: $relative_path"
  if "$DRY_RUN"; then
    printf '  %s' "$relative_path"
    (($# == 0)) || printf ' %s' "$@"
    printf '\n'
  else
    log "running ${relative_path}"
    bash "${REPO_ROOT}/${relative_path}" "$@"
  fi
}

module_exists() {
  local requested="$1" module
  for module in "${ALL_MODULES[@]}"; do
    [[ "$module" == "$requested" ]] && return 0
  done
  return 1
}

add_csv_modules() {
  local csv="$1" item
  local -n target="$2"
  [[ -n "$csv" ]] || return 0
  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    module_exists "$item" || die "unknown module: $item"
    target["$item"]=true
  done < <(tr ',' '\n' <<<"$csv")
}

remove_csv_modules() {
  local csv="$1" item
  local -n target="$2"
  [[ -n "$csv" ]] || return 0
  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    module_exists "$item" || die "unknown module: $item"
    unset 'target[$item]'
  done < <(tr ',' '\n' <<<"$csv")
}

select_modules() {
  local module
  declare -gA SELECTED_MODULES=()
  declare -ga SELECTED_MODULE_LIST=()

  case "$PROFILE" in
    cli)
      for module in "${CLI_MODULES[@]}"; do SELECTED_MODULES["$module"]=true; done
      ;;
    desktop)
      for module in "${DESKTOP_MODULES[@]}"; do SELECTED_MODULES["$module"]=true; done
      ;;
    *) die "profile must be cli or desktop: $PROFILE; enable optional services with --with postgres,nginx" ;;
  esac

  add_csv_modules "$WITH_MODULES" SELECTED_MODULES
  remove_csv_modules "$SKIP_MODULES" SELECTED_MODULES

  if [[ "$PLATFORM" != native ]] \
    && [[ -n "${SELECTED_MODULES[nerd-font]:-}${SELECTED_MODULES[clipboard]:-}" ]]; then
    die "nerd-font and clipboard modules require a native Fedora host; configure the terminal host for WSL/OrbStack"
  fi

  for module in "${ALL_MODULES[@]}"; do
    [[ -n "${SELECTED_MODULES[$module]:-}" ]] && SELECTED_MODULE_LIST+=("$module")
  done
  return 0
}

run_selected_module() {
  local module="$1" script="$2"
  [[ -n "${SELECTED_MODULES[$module]:-}" ]] || return 0
  run_script "$script"
  if "$DRY_RUN"; then
    local package_list
    package_list="$(packages_for_module "$module")" || die "cannot resolve packages for $module"
    if [[ -n "$package_list" ]]; then
      printf '    packages (%s): %s\n' "$PACKAGE_MANAGER" "${package_list//$'\n'/ }"
    fi
    if [[ "$module" == postgres && "$OS_ID" == fedora ]]; then
      log "PostgreSQL: initialize only a new data directory, then enable the service"
    fi
  fi
}

prepare_wsl() {
  run_script scripts/wsl/00-wsl-preflight.sh
  if ! "$DRY_RUN" && ! systemd_is_active; then
    run_script scripts/wsl/01-write-wslconf.sh
    log "WSL must restart before installation can continue."
    log "Run 'wsl --shutdown' from Windows, reopen Ubuntu, then rerun ./bootstrap.sh."
    exit 2
  fi
}

load_installed_tool_paths() {
  export PATH="${HOME}/.local/bin:${HOME}/bin:${PATH}"
  export NVM_DIR="${HOME}/.nvm"
  # shellcheck disable=SC1091
  if [[ -s "${NVM_DIR}/nvm.sh" ]]; then source "${NVM_DIR}/nvm.sh"; fi
}

main() {
  while (($#)); do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
      --profile)
        (($# >= 2)) || die "--profile requires a value"
        PROFILE="$2"
        shift
        ;;
      --with)
        (($# >= 2)) || die "--with requires a value"
        WITH_MODULES="${WITH_MODULES:+${WITH_MODULES},}$2"
        shift
        ;;
      --skip)
        (($# >= 2)) || die "--skip requires a value"
        SKIP_MODULES="${SKIP_MODULES:+${SKIP_MODULES},}$2"
        shift
        ;;
      --set-default-shell) CHANGE_DEFAULT_SHELL=true ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done

  check_host
  PROFILE="${PROFILE:-$(default_install_profile)}"
  select_modules
  log "install profile: $PROFILE"
  log "package manager: $PACKAGE_MANAGER"
  log "selected modules: ${SELECTED_MODULE_LIST[*]}"
  export CHANGE_DEFAULT_SHELL
  "$DRY_RUN" || sudo -v

  case "$PLATFORM" in
    wsl) prepare_wsl ;;
    orbstack)
      run_script scripts/orbstack/00-orb-preflight.sh
      run_script scripts/orbstack/01-machine-setup.sh
      ;;
  esac

  run_selected_module base scripts/common/00-base.sh
  run_selected_module shell scripts/common/10-shell.sh
  run_selected_module nerd-font scripts/common/12-nerd-font.sh
  run_selected_module clipboard scripts/common/13-clipboard.sh
  run_selected_module tmux scripts/common/15-tmux.sh
  run_selected_module zellij scripts/common/16-zellij.sh
  run_selected_module herdr scripts/common/17-herdr.sh
  run_selected_module yazi scripts/common/18-yazi.sh
  run_selected_module direnv scripts/common/20-direnv.sh
  run_selected_module python scripts/common/30-python.sh
  run_selected_module node scripts/common/40-node.sh
  run_selected_module db-clients scripts/common/50-db-clients.sh
  run_selected_module postgres scripts/common/60-postgres.sh
  run_selected_module nginx scripts/common/70-nginx.sh
  run_selected_module devtools scripts/common/80-devtools.sh

  if ((${#SELECTED_MODULE_LIST[@]} == 0)); then
    log "no modules selected; skipping module checks"
    return 0
  fi

  if "$DRY_RUN"; then
    run_script scripts/common/90-verify.sh "${SELECTED_MODULE_LIST[@]}"
  else
    load_installed_tool_paths
    run_script scripts/common/90-verify.sh "${SELECTED_MODULE_LIST[@]}"
    log "installation complete; open a new login session to refresh the shell environment"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  trap 'printf "[bootstrap] ERROR: failed at %s (line %s)\n" "$CURRENT_STEP" "$LINENO" >&2' ERR
  main "$@"
fi
