#!/usr/bin/env bash

set -e

home=./chora
chain=chora

# set script input options
while getopts ":h:" option; do
  case $option in
    h)
      home=$OPTARG;;
    c)
      chain=$OPTARG;;
    \?)
      echo "Error: invalid option"
      exit 1
  esac
done

# check home directory and confirm removal if exists
if [ -d "$home" ]; then
  read -r -p "WARNING: This script will remove $home. Would you like to continue? [y/N] " confirm
  case "$confirm" in
    [yY][eE][sS]|[yY])
      rm -rf "$home"
      ;;
    *)
      exit 0
      ;;
  esac
fi

make build

./build/chora config chain-id "$chain"

./build/chora config keyring-backend test

./build/chora keys add test --home "$home" --keyring-backend test

# TODO: chain-id flag does not work with init command
./build/chora init test --home "$home" --chain-id "$chain"

# TODO: keyring-backed flag does not work with add-genesis command
./build/chora add-genesis-account test 5000000000stake --keyring-backend test --home "$home"

# TODO: keyring-backed and chain-id flags do not work with gentx command
./build/chora gentx test 1000000stake --keyring-backend test --chain-id "$chain" --home "$home"

./build/chora collect-gentxs --home "$home"

cat <<< $(jq '.app_state.gov.voting_params.voting_period = "20s"' "$home"/config/genesis.json) > "$home/config/genesis.json"

./build/chora start --minimum-gas-prices 0stake --home "$home"
