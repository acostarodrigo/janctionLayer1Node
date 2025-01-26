#!/usr/bin/env bash

rm -rf $HOME/.minid
MINID_BIN=$(which minid)
if [ -z "$MINID_BIN" ]; then
    GOBIN=$(go env GOPATH)/bin
    MINID_BIN=$(which $GOBIN/minid)
fi

if [ -z "$MINID_BIN" ]; then
    echo "please verify minid is installed"
    exit 1
fi

# configure minid
$MINID_BIN config set client chain-id demo
$MINID_BIN config set client keyring-backend test
$MINID_BIN keys add alice
$MINID_BIN keys add bob
$MINID_BIN init test --chain-id demo --default-denom mini
# update genesis
$MINID_BIN genesis add-genesis-account alice 100000000000mini --keyring-backend test
$MINID_BIN genesis add-genesis-account bob 1000mini --keyring-backend test
# create default validator
$MINID_BIN genesis gentx alice 100000000000mini --chain-id demo
$MINID_BIN genesis collect-gentxs
# video Rendering settings
$MINID_BIN videoRendering enable true
key=$($MINID_BIN keys show alice -a)
$MINID_BIN videoRendering setWorker alice $key test 0 1