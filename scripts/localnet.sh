#!/usr/bin/env bash

set -eo pipefail

# default home
home=./local

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

./build/chora config set client chain-id "$chain_id" --home "$home"

./build/chora config set client keyring-backend test --home "$home"

# NOTE: keyring-backend config setting does not work with keys add command
echo "$mnemonic" | ./build/chora keys add validator --home "$home" --keyring-backend test --recover

# NOTE: chain-id config setting does not work with init command
./build/chora init validator --home "$home" --chain-id "$chain_id"

# NOTE: keyring-backed config setting does not work with genesis add-genesis-account command
./build/chora genesis add-genesis-account validator 5000000000uchora --home "$home" --keyring-backend test

# NOTE: keyring-backed and chain-id config settings do not work with genesis gentx command
./build/chora genesis gentx validator 1000000uchora --keyring-backend test --home "$home" --chain-id "$chain_id"

./build/chora genesis collect-gentxs --home "$home"

sed -i "s/stake/uchora/g" "$home/config/genesis.json"

cat <<< $(jq '.app_state.gov.voting_params.voting_period = "20s"' "$home"/config/genesis.json) > "$home/config/genesis.json"

./build/chora start --api.enable true --api.swagger true --api.enabled-unsafe-cors --minimum-gas-prices 0chora --home "$home"
