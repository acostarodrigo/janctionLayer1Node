#!/usr/bin/env bash

JANCTIOND_BIN=$(which janctiond)
if [ -z "$JANCTIOND_BIN" ]; then
    GOBIN=$(go env GOPATH)/bin
    JANCTIOND_BIN=$(which $GOBIN/janctiond)
fi

if [ -z "$JANCTIOND_BIN" ]; then
    echo "please verify janctiond is installed"
    exit 1
fi


CONFIG_FILE="$HOME/.janctiond/config/config.toml"
GENESIS_FILE="$HOME/.janctiond/config/genesis.json"
APP_FILE="$HOME/.janctiond/config/app.toml"

# Download genesis.json and config.toml files
rm $CONFIG_FILE
rm $GENESIS_FILE
cd $HOME/.janctiond/config
curl -O https://raw.githubusercontent.com/acostarodrigo/janction_testnet/main/genesis.json
curl -O https://raw.githubusercontent.com/acostarodrigo/janction_testnet/main/config.toml



# Replace in the config file to enable
sed -i.bak "s/^enable = false/enable = true/" "$APP_FILE"
sed -i.bak 's|^laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|' "$CONFIG_FILE"

# Replace in the config file for the address
sed -i.bak 's/^address = "localhost:9090"/address = "0.0.0.0:9090"/' "$APP_FILE"

# Remove backup files
rm "$APP_FILE.bak"
rm "$CONFIG_FILE.bak"

# add money to alice from faucet
key=$($JANCTIOND_BIN keys show alice -a)
$JANCTIOND_BIN tx bank send alice key 10000000 --yes --node tcp://3.19.120.0:26657

echo "Starting node..."
$JANCTIOND_BIN start

