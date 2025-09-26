#!/usr/bin/env bash

rm -rf $HOME/.janctiond
JANCTIOND_BIN=$(which janctiond)
if [ -z "$JANCTIOND_BIN" ]; then
    GOBIN=$(go env GOPATH)/bin
    JANCTIOND_BIN=$(which $GOBIN/janctiond)
fi

if [ -z "$JANCTIOND_BIN" ]; then
    echo "please verify janctiond is installed"
    exit 1
fi

echo "Downloading images..."
docker pull blendergrid/blender
docker pull rodrigoa77/audio-stem
docker pull rodrigoa77/upscaler-cpu

echo "Running " $JANCTIOND_BIN
# configure janctiond
$JANCTIOND_BIN config set client chain-id main
$JANCTIOND_BIN config set client keyring-backend test
$JANCTIOND_BIN keys add alice
$JANCTIOND_BIN keys add bob
$JANCTIOND_BIN init test --chain-id main --default-denom jct
# update genesis
$JANCTIOND_BIN genesis add-genesis-account alice 100000000000jct --keyring-backend test
$JANCTIOND_BIN genesis add-genesis-account bob 1000jct --keyring-backend test
# create default validator
$JANCTIOND_BIN genesis gentx alice 1000000jct --chain-id main
$JANCTIOND_BIN genesis collect-gentxs
# video Rendering settings
$JANCTIOND_BIN videoRendering enable true
key=$($JANCTIOND_BIN keys show alice -a)
$JANCTIOND_BIN videoRendering setWorker alice $key test 0 1
# audio stem settings
$JANCTIOND_BIN audioStem enable true
$JANCTIOND_BIN audioStem setWorker alice $key test 0 1
# video upscaer settings
$JANCTIOND_BIN videoUpscaler enable true
$JANCTIOND_BIN videoUpscaler setWorker alice $key test 0 1