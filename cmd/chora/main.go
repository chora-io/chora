package main

import (
	"os"

	sdkcmd "github.com/cosmos/cosmos-sdk/server/cmd"

	"github.com/chora-io/chora/app"
	"github.com/chora-io/chora/app/cmd"
)

func main() {
	rootCmd := cmd.NewRootCmd()
	if err := sdkcmd.Execute(rootCmd, app.EnvPrefix, app.DefaultNodeHome); err != nil {
		os.Exit(1)
	}
}
