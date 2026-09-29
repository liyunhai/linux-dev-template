#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT
fail() { printf '[test-postgres] ERROR: %s\n' "$*" >&2; exit 1; }
source "${REPO_ROOT}/scripts/lib/postgres.sh"

DATA_DIR="${TMP_DIR}/custom-data"
SERVICE_ENV="PGDATA=${DATA_DIR} OTHER=value"
systemctl() { printf '%s\n' "$SERVICE_ENV"; }
sudo() {
  case "$1" in
    test|find) "$@" ;;
    postgresql-setup)
      printf '%s\n' "$*" >>"${TMP_DIR}/initializations"
      mkdir -p "$DATA_DIR"
      printf '18\n' >"${DATA_DIR}/PG_VERSION"
      ;;
    *) fail "unexpected sudo command: $*" ;;
  esac
}

initialize_fedora_postgres
initialize_fedora_postgres
[[ "$(wc -l <"${TMP_DIR}/initializations")" -eq 1 ]] || fail 'existing cluster was initialized again'
grep -qx 'postgresql-setup --initdb --unit postgresql' "${TMP_DIR}/initializations" \
  || fail 'initialization did not use the service unit'

DATA_DIR="${TMP_DIR}/incomplete-data"
SERVICE_ENV="PGDATA=${DATA_DIR}"
mkdir "$DATA_DIR"
printf 'existing data\n' >"${DATA_DIR}/important-file"
if initialize_fedora_postgres >"${TMP_DIR}/rejected" 2>&1; then fail 'nonempty directory was accepted'; fi
[[ "$(cat "${DATA_DIR}/important-file")" == 'existing data' ]] || fail 'existing data was modified'
[[ "$(wc -l <"${TMP_DIR}/initializations")" -eq 1 ]] || fail 'incomplete cluster was overwritten'
SERVICE_ENV='OTHER=value'
if initialize_fedora_postgres >"${TMP_DIR}/rejected" 2>&1; then fail 'missing PGDATA was accepted'; fi
SERVICE_ENV='PGDATA=/'
if initialize_fedora_postgres >"${TMP_DIR}/rejected" 2>&1; then fail 'unsafe PGDATA was accepted'; fi
printf '[test-postgres] all tests passed\n'
