#!/usr/bin/env bash

rm -rf $HOME/.janctiond
MINID_BIN=$(which janctiond)
if [ -z "$MINID_BIN" ]; then
    GOBIN=$(go env GOPATH)/bin
    MINID_BIN=$(which $GOBIN/janctiond)
fi

if [ -z "$MINID_BIN" ]; then
    echo "please verify janctiond is installed"
    exit 1
fi

# configure janctiond
$MINID_BIN config set client chain-id demo
$MINID_BIN config set client keyring-backend test
$MINID_BIN keys add alice
$MINID_BIN keys add bob
$MINID_BIN init test --chain-id demo --default-denom jct
# update genesis
$MINID_BIN genesis add-genesis-account alice 100000000000jct --keyring-backend test
$MINID_BIN genesis add-genesis-account bob 1000jct --keyring-backend test
# create default validator
$MINID_BIN genesis gentx alice 1000000jct --chain-id demo
$MINID_BIN genesis collect-gentxs
# video Rendering settings
$MINID_BIN videoRendering enable true
key=$($MINID_BIN keys show alice -a)
$MINID_BIN videoRendering setWorker alice $key test 0 1