#!/usr/bin/env bash
set -euo pipefail

# ----- Config (edit defaults or pass as env vars) -----
REPO_OWNER="${REPO_OWNER:-acostarodrigo}"
REPO_NAME="${REPO_NAME:-janctionLayer1Node}"
# VERSION: set to a tag like v0.8.0. If empty, uses "latest"
VERSION="${VERSION:-}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Chain/Testnet wiring (provide these when you want auto-join):
CHAIN_ID="${CHAIN_ID:-janction-testnet-1}"   # e.g. janction-testnet-1
MONIKER="${MONIKER:-janction-node}"          # node name
GENESIS_URL="${GENESIS_URL:-}"               # e.g. https://…/genesis.json
ADDRBOOK_URL="${ADDRBOOK_URL:-}"             # optional
SEEDS="${SEEDS:-}"                           # comma-separated nodeID@host:port
PERSISTENT_PEERS="${PERSISTENT_PEERS:-}"     # comma-separated nodeID@host:port
MIN_GAS_PRICES="${MIN_GAS_PRICES:-0.025ujct}"

# Systemd setup
SETUP_SYSTEMD="${SETUP_SYSTEMD:-true}"       # set false to skip
RUN_AS_USER="${RUN_AS_USER:-janction}"       # system user for the service
DATA_DIR="${DATA_DIR:-/var/lib/janctiond}"   # HOME for the service
LOG_DIR="${LOG_DIR:-/var/log/janctiond}"

# ----- Detect arch and compose asset name -----
OS="linux"
ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported arch: $ARCH_RAW"; exit 1 ;;
esac

# Expected GoReleaser asset name convention:
#   janctiond_<version>_linux_<arch>.tar.gz  and checksums.txt
asset_prefix="janctiond"
if [[ -z "${VERSION}" ]]; then
  # Use latest
  api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
  VERSION="$(curl -fsSL "$api_url" | grep -m1 '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
fi

TARBALL="${asset_prefix}_${VERSION}_${OS}_${ARCH}.tar.gz"
CHECKSUMS="checksums_${VERSION}.txt"
BASE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}"

echo "-> Installing janctiond ${VERSION} for ${OS}/${ARCH}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "-> Downloading tarball and checksums"
curl -fL "${BASE_URL}/${TARBALL}" -o "${tmp}/${TARBALL}"
curl -fL "${BASE_URL}/${CHECKSUMS}" -o "${tmp}/${CHECKSUMS}"

echo "-> Verifying checksum"
( cd "$tmp" && grep " ${TARBALL}\$" "${CHECKSUMS}" | sha256sum -c - )

echo "-> Extracting and installing binary to ${INSTALL_DIR}"
tar -xzf "${tmp}/${TARBALL}" -C "${tmp}"
sudo install -m 0755 "${tmp}/janctiond" "${INSTALL_DIR}/janctiond"

if [[ "${SETUP_SYSTEMD}" == "false" ]]; then
  echo "-> Skipping systemd setup. Binary installed at ${INSTALL_DIR}/janctiond"
  exit 0
fi

echo "-> Creating system user, dirs, and default layout"
if ! id -u "${RUN_AS_USER}" >/dev/null 2>&1; then
  sudo useradd --system --create-home --home-dir "${DATA_DIR}" --shell /usr/sbin/nologin "${RUN_AS_USER}"
fi
sudo mkdir -p "${DATA_DIR}" "${LOG_DIR}"
sudo chown -R "${RUN_AS_USER}:${RUN_AS_USER}" "${DATA_DIR}" "${LOG_DIR}"

# Initialize if no config yet
if [[ ! -f "${DATA_DIR}/config/config.toml" ]]; then
  echo "-> Running janctiond init"
  sudo -u "${RUN_AS_USER}" HOME="${DATA_DIR}" \
    ${INSTALL_DIR}/janctiond init "${MONIKER}" --chain-id "${CHAIN_ID}"
fi

# Fetch genesis / addrbook if provided
conf_dir="${DATA_DIR}/config"
if [[ -n "${GENESIS_URL}" ]]; then
  echo "-> Fetching genesis from ${GENESIS_URL}"
  sudo -u "${RUN_AS_USER}" bash -c "curl -fL '${GENESIS_URL}' -o '${conf_dir}/genesis.json'"
fi
if [[ -n "${ADDRBOOK_URL}" ]]; then
  echo "-> Fetching addrbook from ${ADDRBOOK_URL}"
  sudo -u "${RUN_AS_USER}" bash -c "curl -fL '${ADDRBOOK_URL}' -o '${conf_dir}/addrbook.json'"
fi

# Patch config/app tomls
echo "-> Patching config.toml and app.toml"
sudo -u "${RUN_AS_USER}" bash -c "
  set -e
  CFG='${conf_dir}/config.toml'
  APP='${conf_dir}/app.toml'
  [[ -n '${SEEDS}' ]] && sed -i -E \"s|^seeds *=.*|seeds = '${SEEDS}'|\" \"\$CFG\"
  [[ -n '${PERSISTENT_PEERS}' ]] && sed -i -E \"s|^persistent_peers *=.*|persistent_peers = '${PERSISTENT_PEERS}'|\" \"\$CFG\"
  sed -i -E \"s|^minimum-gas-prices *=.*|minimum-gas-prices = '${MIN_GAS_PRICES}'|\" \"\$APP\" || true
"

# Write systemd units
echo "-> Installing systemd unit"
sudo tee /etc/systemd/system/janctiond.service >/dev/null <<UNIT
[Unit]
Description=Janction Cosmos Node
Wants=network-online.target
After=network-online.target

[Service]
User=${RUN_AS_USER}
Environment=HOME=${DATA_DIR}
WorkingDirectory=${DATA_DIR}
ExecStart=${INSTALL_DIR}/janctiond start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
StandardOutput=append:${LOG_DIR}/janctiond.log
StandardError=append:${LOG_DIR}/janctiond.err

[Install]
WantedBy=multi-user.target
UNIT

# Optional stack target to group services (ipfs, faucet, janctiond)
sudo tee /etc/systemd/system/janction-stack.target >/dev/null <<UNIT
[Unit]
Description=Janction stack (IPFS + Faucet + Node)
Requires=janctiond.service
Wants=ipfs.service
After=ipfs.service
UNIT

echo "-> Reloading and starting"
sudo systemctl daemon-reload
sudo systemctl enable janctiond.service
sudo systemctl start janctiond.service

echo "✅ janctiond installed and started."
echo "   Data dir: ${DATA_DIR}"
echo "   Logs:     ${LOG_DIR}/janctiond.log"
