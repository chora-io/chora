package app

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/address"
)

const (
	// Name is the name of the application.
	Name = "chora"

	// EnvPrefix is the environment variable prefix used to map environment
	// variables to command flags.
	EnvPrefix = "CHORA"

	// Bech32PrefixAccAddr defines the Bech32 prefix of an account's address.
	Bech32PrefixAccAddr = Name

	// Bech32PrefixAccPub defines the Bech32 prefix of an account's public key.
	Bech32PrefixAccPub = Name + "pub"

	// Bech32PrefixValAddr defines the Bech32 prefix of a validator's operator address.
	Bech32PrefixValAddr = Name + "valoper"

	// Bech32PrefixValPub defines the Bech32 prefix of a validator's operator public key.
	Bech32PrefixValPub = Name + "valoperpub"

	// Bech32PrefixConsAddr defines the Bech32 prefix of a consensus node address.
	Bech32PrefixConsAddr = Name + "valcons"

	// Bech32PrefixConsPub defines the Bech32 prefix of a consensus node public key.
	Bech32PrefixConsPub = Name + "valconspub"
)

func init() {
	config := sdk.GetConfig()
	config.SetBech32PrefixForAccount(Bech32PrefixAccAddr, Bech32PrefixAccPub)
	config.SetBech32PrefixForValidator(Bech32PrefixValAddr, Bech32PrefixValPub)
	config.SetBech32PrefixForConsensusNode(Bech32PrefixConsAddr, Bech32PrefixConsPub)
	config.SetAddressVerifier(func(bytes []byte) error {
		n := len(bytes)
		if (n != 0) && (n <= address.MaxAddrLen) {
			return nil
		}
		return fmt.Errorf("unexpected address length %d", n)
	})
	config.Seal()
}
