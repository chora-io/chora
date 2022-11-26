package main

import (
	"os"

	svrcmd "github.com/cosmos/cosmos-sdk/server/cmd"

	"github.com/choraio/chora/app"
	"github.com/choraio/chora/app/client/cmd"
)

func main() {
	rootCmd, _ := cmd.NewRootCmd()
	if err := svrcmd.Execute(rootCmd, app.EnvPrefix, app.DefaultNodeHome); err != nil {
		os.Exit(1)
	}
}
