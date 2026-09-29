#!/usr/bin/env bash

# Initialize Fedora's distribution-provided service without overwriting an
# existing cluster or guessing a data directory when its unit is customized.
initialize_fedora_postgres() {
  local service_environment data_dir existing_files
  service_environment="$(systemctl show postgresql.service --property=Environment --value)" || return 1
  if [[ "$service_environment" =~ (^|[[:space:]])PGDATA=([^[:space:]]+) ]]; then
    data_dir="${BASH_REMATCH[2]}"
  else
    printf '[60-postgres] ERROR: cannot determine PGDATA from postgresql.service; inspect the unit before initializing\n' >&2
    return 1
  fi
  [[ "$data_dir" == /* && "$data_dir" != / ]] || {
    printf '[60-postgres] ERROR: unsupported PostgreSQL data directory: %s\n' "$data_dir" >&2
    return 1
  }
  if sudo test -s "${data_dir}/PG_VERSION"; then
    printf '[60-postgres] existing cluster retained: %s\n' "$data_dir"
    return 0
  fi
  if sudo test -d "$data_dir"; then
    existing_files="$(sudo find "$data_dir" -mindepth 1 -maxdepth 1 -print -quit)" || return 1
    [[ -z "$existing_files" ]] || {
      printf '[60-postgres] ERROR: data directory is nonempty without PG_VERSION; inspect it before initializing: %s\n' "$data_dir" >&2
      return 1
    }
  fi
  sudo postgresql-setup --initdb --unit postgresql
}
