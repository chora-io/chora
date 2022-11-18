package app

import (
	"encoding/json"
)

// GenesisState is the genesis state of the blockchain.
type GenesisState map[string]json.RawMessage
