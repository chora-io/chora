package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/cosmos/cosmos-sdk/server/cmd"

	"github.com/chora-io/chora/app"
)

func TestInitCmd(t *testing.T) {
	tmp := os.TempDir()
	nodeHome := filepath.Join(tmp, "test_init_cmd")

	// clean up test home directory
	err := os.RemoveAll(nodeHome)
	require.NoError(t, err)

	// create new test home directory
	err = os.Mkdir(nodeHome, 0755)
	require.NoError(t, err)

	rootCmd := NewRootCmd()
	rootCmd.SetArgs([]string{
		"init",
		"test",
		fmt.Sprintf("--%s=%s", flags.FlagHome, nodeHome),
	})

	err = cmd.Execute(rootCmd, app.EnvPrefix, nodeHome)
	require.NoError(t, err)
}
