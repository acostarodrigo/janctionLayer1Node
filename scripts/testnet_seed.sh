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
GENESIS_FILE="$HOME/.janctiond/config/genesis.json"
GITHUB="$HOME/janction_testnet"

# Get the public IP address
public_ip=$(curl -4 -s https://icanhazip.com)

# Gets the Layer 1 node id
seed=$($JANCTIOND_BIN comet show-node-id)

# Create the string with seed and public IP
seed_and_ip="${seed}@${public_ip}:26656"

# Replace seed value
sed -i.bak "s/^seeds = \"\"/seeds = \"$seed_and_ip\"/" "$CONFIG_FILE" 

# Replace in the config file for CORS allowed origins
sed -i.bak "s/^cors_allowed_origins = \[\]/cors_allowed_origins = \[\"*\"\]/" "$CONFIG_FILE"
sed -i.bak 's|^laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|' "$CONFIG_FILE"

# Replace in the config file to enable
sed -i.bak "s/^enable = false/enable = true/" "$APP_FILE"

# Replace in the config file for the address
sed -i.bak 's/^address = "localhost:9090"/address = "0.0.0.0:9090"/' "$APP_FILE"

cd $HOME
eval "$(ssh-agent -s)"
ssh-agent
ssh-add githubaccess

cp $GENESIS_FILE $GITHUB
cp $CONFIG_FILE $GITHUB

cd $GITHUB
# Add the config.toml file
git add config.toml
git add genesis.json
git commit -m "New testnet files"
git push origin

# Remove backup files
rm "$CONFIG_FILE.bak"
rm "$APP_FILE.bak"

echo "Starting node..."
$JANCTIOND_BIN start