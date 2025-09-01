#!/usr/bin/env bash
set -euo pipefail

# ---- Defaults (override with flags) ----
USER_NAME="${USER_NAME:-ubuntu}"
USER_HOME="${USER_HOME:-/home/${USER_NAME}}"
JANCTION_HOME="${JANCTION_HOME:-${USER_HOME}/.janctiond}"
IPFS_PATH="${IPFS_PATH:-${USER_HOME}/.ipfs}"

JANCTIOND_BIN="${JANCTIOND_BIN:-$(command -v janctiond || true)}"
IPFS_BIN="${IPFS_BIN:-$(command -v ipfs || true)}"

SYSTEMD_DIR="/etc/systemd/system"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNITS_DIR="${REPO_ROOT}"
SCRIPTS_DIR="${REPO_ROOT}"

UNITS=("ipfs.service" "faucet.service" "janctiond.service" "janction-stack.target")

START_AFTER_INSTALL=1

usage() {
  cat <<EOF
Usage: sudo ./install-janction-services.sh [options]

Options:
  --user NAME              System user (default: ${USER_NAME})
  --home PATH              Home dir (default: ${USER_HOME})
  --janction-home PATH     Janction node home (default: ${JANCTION_HOME})
  --ipfs-path PATH         IPFS repo path (default: ${IPFS_PATH})
  --janctiond-bin PATH     Full path to janctiond (default: auto-detect)
  --ipfs-bin PATH          Full path to ipfs (default: auto-detect)
  --no-start               Install only; don’t start
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) USER_NAME="$2"; shift 2;;
    --home) USER_HOME="$2"; shift 2;;
    --janction-home) JANCTION_HOME="$2"; shift 2;;
    --ipfs-path) IPFS_PATH="$2"; shift 2;;
    --janctiond-bin) JANCTIOND_BIN="$2"; shift 2;;
    --ipfs-bin) IPFS_BIN="$2"; shift 2;;
    --no-start) START_AFTER_INSTALL=0; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1"; usage; exit 1;;
  esac
done

# ---- Ensure binaries ----
if [[ -z "$JANCTIOND_BIN" || ! -x "$JANCTIOND_BIN" ]]; then
  JANCTIOND_BIN="/usr/local/bin/janctiond"
fi
if [[ -z "$IPFS_BIN" || ! -x "$IPFS_BIN" ]]; then
  IPFS_BIN="/usr/local/bin/ipfs"
fi

echo "==> Using:"
echo "    USER_NAME      = ${USER_NAME}"
echo "    USER_HOME      = ${USER_HOME}"
echo "    JANCTION_HOME  = ${JANCTION_HOME}"
echo "    IPFS_PATH      = ${IPFS_PATH}"
echo "    JANCTIOND_BIN  = ${JANCTIOND_BIN}"
echo "    IPFS_BIN       = ${IPFS_BIN}"
echo

# ---- Install wait-for-ipfs.sh ----
install_wait_script() {
  local dest="/usr/local/bin/wait-for-ipfs.sh"
  if [[ -f "${SCRIPTS_DIR}/wait-for-ipfs.sh" ]]; then
    echo "==> Installing wait-for-ipfs.sh from repo"
    install -m 0755 "${SCRIPTS_DIR}/wait-for-ipfs.sh" "$dest"
  else
    echo "==> Creating default wait-for-ipfs.sh"
    cat > "$dest" <<'EOS'
#!/usr/bin/env bash
set -e
API_URL="${1:-http://127.0.0.1:5001/api/v0/version}"
TRIES=60
SLEEP=2
for i in $(seq 1 "$TRIES"); do
  if curl -s --max-time 2 "$API_URL" >/dev/null; then
    exit 0
  fi
  sleep "$SLEEP"
done
echo "IPFS API not responding" >&2
exit 1
EOS
    chmod 0755 "$dest"
  fi
}

# ---- Copy unit files ----
template_and_install_unit() {
  local src="$1"
  local dest="${SYSTEMD_DIR}/$(basename "$src")"
  echo "==> Installing $(basename "$src")"
  sed \
    -e "s|@USER@|${USER_NAME}|g" \
    -e "s|@JANCTION_HOME@|${JANCTION_HOME}|g" \
    -e "s|@IPFS_PATH@|${IPFS_PATH}|g" \
    -e "s|@JANCTIOND_BIN@|${JANCTIOND_BIN}|g" \
    -e "s|@IPFS_BIN@|${IPFS_BIN}|g" \
    "$src" > "$dest"
  chmod 0644 "$dest"
}

mkdir -p "${JANCTION_HOME}" "${IPFS_PATH}"
chown -R "${USER_NAME}:${USER_NAME}" "${JANCTION_HOME}" "${IPFS_PATH}"

install_wait_script
for u in "${UNITS[@]}"; do
  template_and_install_unit "${UNITS_DIR}/${u}"
done

systemctl daemon-reload
systemctl enable ipfs.service faucet.service janctiond.service janction-stack.target

if [[ $START_AFTER_INSTALL -eq 1 ]]; then
  systemctl start janction-stack.target
fi

echo "==> Installed and enabled. Use 'systemctl status janction-stack.target' to check."
