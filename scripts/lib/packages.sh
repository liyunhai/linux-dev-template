#!/usr/bin/env bash

# System packages are grouped by module so installers share their workflow
# while package names remain specific to the distribution.
# shellcheck source=os.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/os.sh"

packages_for_module() {
  local module="$1" curl_package=curl
  local -a packages=()
  load_os_release || return 1
  case "$OS_ID" in
    ubuntu|fedora) ;;
    *) printf '[packages] ERROR: unsupported distribution: %s\n' "$OS_ID" >&2; return 1 ;;
  esac
  # Fedora can provide curl through curl or curl-minimal. A file dependency
  # lets DNF retain the installed provider instead of forcing a conflicting one.
  [[ "$OS_ID" != fedora ]] || curl_package=/usr/bin/curl

  case "$module" in
    base)
      packages=(ca-certificates "$curl_package" wget unzip zip jq tree ripgrep fd-find
        fzf htop git make tar)
      if [[ "$OS_ID" == fedora ]]; then
        packages+=(gcc gcc-c++ glibc-devel gnupg2 openssh-clients pkgconf-pkg-config)
      else
        packages+=(build-essential gnupg software-properties-common openssh-client pkg-config)
      fi
      ;;
    shell) packages=(zsh) ;;
    nerd-font) packages=(fontconfig) ;;
    clipboard) packages=(wl-clipboard) ;;
    tmux)
      packages=(tmux)
      [[ "$OS_ID" != ubuntu ]] || packages+=(xclip xsel)
      ;;
    alacritty|ghostty|zellij|herdr|node) ;;
    yazi)
      packages=(zoxide file poppler-utils mediainfo)
      if [[ "$OS_ID" == fedora ]]; then packages+=(7zip); else packages+=(p7zip-full); fi
      ;;
    direnv) packages=(direnv) ;;
    python)
      packages=(python3 python3-pip pipx)
      [[ "$OS_ID" != ubuntu ]] || packages+=(python3-venv)
      ;;
    db-clients)
      if [[ "$OS_ID" == fedora ]]; then
        packages=(sqlite postgresql mysql valkey)
      else
        packages=(sqlite3 postgresql-client mysql-client redis-tools)
      fi
      ;;
    postgres)
      if [[ "$OS_ID" == fedora ]]; then
        packages=(postgresql-server)
      else
        packages=(postgresql)
      fi
      ;;
    nginx) packages=(nginx) ;;
    devtools)
      packages=(yamllint shfmt gh)
      if [[ "$OS_ID" == fedora ]]; then packages+=(ShellCheck); else packages+=(shellcheck); fi
      ;;
    openvpn-helper)
      if [[ "$OS_ID" == fedora ]]; then packages=(libsecret); else packages=(libsecret-tools); fi
      ;;
    *) printf '[packages] ERROR: unknown module: %s\n' "$module" >&2; return 1 ;;
  esac

  if ((${#packages[@]})); then printf '%s\n' "${packages[@]}"; fi
}

install_module_packages() {
  local package_list
  local -a packages=()
  require_supported_environment || return 1
  package_list="$(packages_for_module "$1")" || return 1
  [[ -n "$package_list" ]] || return 0
  mapfile -t packages <<<"$package_list"
  command -v "$PACKAGE_MANAGER" >/dev/null 2>&1 || {
    printf '[packages] ERROR: package manager not found: %s\n' "$PACKAGE_MANAGER" >&2
    return 1
  }
  case "$PACKAGE_MANAGER" in
    apt)
      sudo apt update || return 1
      sudo apt install -y "${packages[@]}"
      ;;
    dnf) sudo dnf install -y "${packages[@]}" ;;
  esac
}
