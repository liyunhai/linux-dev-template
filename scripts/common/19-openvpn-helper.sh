#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/packages.sh
source "${REPO_ROOT}/scripts/lib/packages.sh"
BIN_DIR="${HOME}/.local/bin"

require_supported_environment

echo "[19-openvpn-helper] checking OpenVPN 3..."
command -v openvpn3 >/dev/null 2>&1 || {
  echo "[19-openvpn-helper] ERROR: openvpn3 is not installed" >&2
  exit 1
}

if ! command -v secret-tool >/dev/null 2>&1; then
  echo "[19-openvpn-helper] installing the system keyring command..."
  install_module_packages openvpn-helper
fi

mkdir -p "$BIN_DIR"
install -m 0755 "$REPO_ROOT/bin/vpn" "$BIN_DIR/vpn"
for name in vpn-up vpn-down vpn-restart vpn-status; do
  ln -sfn vpn "$BIN_DIR/$name"
done

cat <<'EOF'
[19-openvpn-helper] done.
[19-openvpn-helper] Run this once to store credentials securely:
  vpn setup

[19-openvpn-helper] Then use: vpn-up, vpn-down, vpn-status, vpn-restart
EOF
