#!/usr/bin/env bash

set -e

# default home
home=./chora

# default chain id
chain_id=chora-local

# default mnemonic (never to be used in production or on a live network)
mnemonic="cool trust waste core unusual report duck amazing fault juice wish century across ghost cigar diary correct draw glimpse face crush rapid quit equip"

# set script input options
while getopts ":h:c:m:" option; do
  case $option in
    h)
      home=$OPTARG;;
    c)
      chain_id=$OPTARG;;
    m)
      mnemonic=$OPTARG;;
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

./build/chora config chain-id "$chain_id"

./build/chora config keyring-backend test

# TODO: keyring-backed config option does not work with add-genesis command
echo "$mnemonic" | ./build/chora keys add test --home "$home" --keyring-backend test --recover

# TODO: chain-id flag does not work with init command
./build/chora init test --home "$home" --chain-id "$chain_id"

# TODO: keyring-backed config option does not work with add-genesis command
./build/chora add-genesis-account test 5000000000stake --home "$home" --keyring-backend test

# TODO: keyring-backed and chain-id config options do not work with gentx command
./build/chora gentx test 1000000stake --keyring-backend test --home "$home" --chain-id "$chain_id"

./build/chora collect-gentxs --home "$home"

cat <<< $(jq '.app_state.gov.voting_params.voting_period = "20s"' "$home"/config/genesis.json) > "$home/config/genesis.json"

./build/chora start --api.enable true --api.swagger true --api.enabled-unsafe-cors --minimum-gas-prices 0stake --home "$home"
