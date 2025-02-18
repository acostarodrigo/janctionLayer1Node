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
APP_FILE="$HOME/.janctiond/config/app.toml"

# Download genesis.json and config.toml files
cd $HOME/.janctiond/config
curl -O https://github.com/acostarodrigo/janction_testnet/blob/main/genesis.json
curl -O https://github.com/acostarodrigo/janction_testnet/blob/main/config.toml

# Replace in the config file to enable
sed -i.bak "s/^enable = false/enable = true/" "$APP_FILE"

# Replace in the config file for the address
sed -i.bak 's/^address = "localhost:9090"/address = "0.0.0.0:9090"/' "$APP_FILE"

# Remove backup files
rm "$APP_FILE.bak"

# add money to alice from faucet
# key=$($JANCTIOND_BIN keys show alice -a)



