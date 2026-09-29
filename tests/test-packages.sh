#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT
fail() { printf '[test-packages] ERROR: %s\n' "$*" >&2; exit 1; }

for os_id in ubuntu fedora linuxmint; do
  printf 'ID=%s\n' "$os_id" >"${TMP_DIR}/${os_id}"
done

run_install() (
  export OS_RELEASE_FILE="${TMP_DIR}/$1"
  local test_platform="$2" fail_command="${3:-}"
  source "${REPO_ROOT}/scripts/lib/packages.sh"
  detect_platform() { printf '%s' "$test_platform"; }
  # Only record dispatch; never execute a package manager or invoke real sudo.
  apt() { return 99; }
  dnf() { return 99; }
  sudo() {
    printf '%s\n' "$*" >>"${TMP_DIR}/calls"
    [[ "$1 $2" != "$fail_command" ]]
  }
  install_module_packages python
)

run_install fedora native
[[ "$(wc -l <"${TMP_DIR}/calls")" -eq 1 ]] || fail 'Fedora should use a single install command'
grep -q '^dnf install -y ' "${TMP_DIR}/calls" || fail 'Fedora did not dispatch to dnf'
if grep -q 'python3-venv' "${TMP_DIR}/calls"; then fail 'Fedora venv must not use the Ubuntu package'; fi
rm "${TMP_DIR}/calls"
run_install ubuntu wsl
grep -qx 'apt update' "${TMP_DIR}/calls" || fail 'Ubuntu metadata was not refreshed'
grep -q '^apt install -y .*python3-venv' "${TMP_DIR}/calls" || fail 'Ubuntu venv package was not installed'
rm "${TMP_DIR}/calls"
if run_install ubuntu wsl 'apt update'; then fail 'metadata failure was ignored'; fi
[[ "$(wc -l <"${TMP_DIR}/calls")" -eq 1 ]] || fail 'install ran after metadata failure'
rm "${TMP_DIR}/calls"
if run_install fedora native 'dnf install'; then fail 'dnf failure was ignored'; fi
rm "${TMP_DIR}/calls"
if run_install linuxmint native >"${TMP_DIR}/rejected" 2>&1; then fail 'unsupported OS was accepted'; fi
[[ ! -e "${TMP_DIR}/calls" ]] || fail 'unsupported OS called sudo'

printf '[test-packages] all tests passed\n'
