#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT

fail() {
  printf '[test-bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local actual="$1" expected="$2"
  grep -Fq -- "$expected" <<<"$actual" || fail "expected output to contain: $expected"
}

assert_not_contains() {
  local actual="$1" unexpected="$2"
  if grep -Fq -- "$unexpected" <<<"$actual"; then
    fail "expected output not to contain: $unexpected"
  fi
}

write_fixtures() {
  local os_id tool
  mkdir -p "${TMP_DIR}/bin" "${TMP_DIR}/home"
  for os_id in ubuntu linuxmint fedora; do
    printf 'ID=%s\nPRETTY_NAME="Test %s"\n' "$os_id" "$os_id" \
      >"${TMP_DIR}/${os_id}-os-release"
  done

  # A dry run must never call installation, service, or download commands.
  for tool in sudo apt dnf systemctl curl git mkdir chsh fc-cache fc-match; do
    cat >"${TMP_DIR}/bin/${tool}" <<'BLOCKER'
#!/usr/bin/env bash
printf 'unexpected command: %s\n' "$0 $*" >>"$TEST_MUTATION_LOG"
exit 99
BLOCKER
    chmod +x "${TMP_DIR}/bin/${tool}"
  done
}

run_bootstrap() {
  local platform="$1" os_id="$2"
  shift 2
  TEST_PLATFORM="$platform" \
    TEST_MUTATION_LOG="${TMP_DIR}/mutations.log" \
    OS_RELEASE_FILE="${TMP_DIR}/${os_id}-os-release" \
    HOME="${TMP_DIR}/home" \
    PATH="${TMP_DIR}/bin:${PATH}" \
    bash -c '
      source "$1"
      # Override only detection in the test process, without a production bypass.
      detect_platform() { printf "%s" "$TEST_PLATFORM"; }
      main "${@:2}"
    ' bootstrap-test "${REPO_ROOT}/bootstrap.sh" "$@"
}

assert_rejected() {
  local expected="$1" output
  shift
  if output="$(run_bootstrap "$@" 2>&1)"; then
    fail "unsupported input unexpectedly succeeded: $*"
  fi
  assert_contains "$output" "$expected"
  assert_not_contains "$output" 'running scripts/'
}

test_supported_plans() {
  local platform plan relative_script
  for platform in wsl orbstack; do
    plan="$(run_bootstrap "$platform" ubuntu --dry-run)"
    assert_contains "$plan" 'detected OS: Test ubuntu'
    assert_contains "$plan" "detected platform: $platform"
    assert_contains "$plan" 'install profile: cli'
    assert_not_contains "$plan" 'scripts/common/60-postgres.sh'
    assert_not_contains "$plan" 'scripts/common/70-nginx.sh'
    assert_not_contains "$plan" 'scripts/common/12-nerd-font.sh'
    assert_contains "$plan" 'scripts/common/90-verify.sh base shell tmux'
    assert_not_contains "$plan" 'running scripts/'

    if [[ "$platform" == wsl ]]; then
      assert_contains "$plan" 'scripts/wsl/00-wsl-preflight.sh'
      assert_not_contains "$plan" 'scripts/orbstack/'
    else
      assert_contains "$plan" 'scripts/orbstack/00-orb-preflight.sh'
      assert_contains "$plan" 'scripts/orbstack/01-machine-setup.sh'
      assert_not_contains "$plan" 'scripts/wsl/'
    fi

    # Every script printed in the plan must still exist after cleanup.
    while IFS= read -r relative_script; do
      [[ -f "${REPO_ROOT}/${relative_script}" ]] \
        || fail "planned script does not exist: $relative_script"
    done < <(awk '/^  scripts\// { print $1 }' <<<"$plan")
  done
}

test_module_overrides() {
  local plan
  plan="$(run_bootstrap wsl ubuntu --dry-run --profile cli \
    --with postgres --with nginx --skip shell,herdr --set-default-shell)"
  assert_contains "$plan" 'scripts/common/60-postgres.sh'
  assert_contains "$plan" 'scripts/common/70-nginx.sh'
  assert_not_contains "$plan" 'scripts/common/10-shell.sh'
  assert_not_contains "$plan" 'scripts/common/17-herdr.sh'
  assert_contains "$plan" 'scripts/common/90-verify.sh base tmux'
}

test_unsupported_environments() {
  local platform os_id
  for platform in native wsl orbstack; do
    for os_id in linuxmint fedora; do
      assert_rejected 'Ubuntu in WSL 2 or OrbStack is required' \
        "$platform" "$os_id" --dry-run
    done
  done
  assert_rejected 'Ubuntu in WSL 2 or OrbStack is required' native ubuntu --dry-run
}

test_invalid_arguments() {
  local profile module option
  for profile in server desktop unknown; do
    assert_rejected 'profile must be cli' wsl ubuntu --dry-run --profile "$profile"
  done
  for module in docker nerd-font unknown; do
    assert_rejected "unknown module: $module" wsl ubuntu --dry-run --with "$module"
    assert_rejected "unknown module: $module" orbstack ubuntu --dry-run --skip "$module"
  done
  assert_rejected 'unknown option: --replace-docker-packages' \
    wsl ubuntu --dry-run --replace-docker-packages
  for option in --profile --with --skip; do
    assert_rejected "$option requires a value" wsl ubuntu --dry-run "$option"
  done
}

test_empty_selection() {
  local plan
  plan="$(run_bootstrap wsl ubuntu --dry-run \
    --skip base,shell,tmux,zellij,herdr,yazi,direnv,python,node,db-clients,devtools)"
  assert_contains "$plan" 'no modules selected; skipping module checks'
  assert_not_contains "$plan" 'scripts/common/'
}

test_skipping_last_module() {
  local plan
  plan="$(run_bootstrap orbstack ubuntu --dry-run --skip devtools)"
  assert_contains "$plan" 'scripts/common/90-verify.sh'
  assert_not_contains "$plan" 'scripts/common/80-devtools.sh'
}

test_read_only_behavior() {
  [[ ! -e "${TMP_DIR}/mutations.log" ]] || fail "dry run called a blocked command"
  [[ -z "$(find "${TMP_DIR}/home" -mindepth 1 -print -quit)" ]] \
    || fail "dry run wrote user files"
}

main() {
  write_fixtures
  test_supported_plans
  test_module_overrides
  test_unsupported_environments
  test_invalid_arguments
  test_empty_selection
  test_skipping_last_module
  test_read_only_behavior
  printf '[test-bootstrap] all tests passed\n'
}

main "$@"
