package audiostemcommands

import (
	"github.com/cometbft/cometbft/libs/cli"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/spf13/cobra"
)

var DefaultNodeHome string

func Commands(defaultNodeHome string) *cobra.Command {
	DefaultNodeHome = defaultNodeHome
	cmd := &cobra.Command{
		Use:   "audioStem",
		Short: "Manage your audio stem configuration",
		Long: `AudioStem management commands. 
		
Allows you to configure your node as an audio stem tasks worker to execute audio stem tasks submitted to the chain.

You will be able to use your Janction node to earn tokens by steming audios.
Configurations are:

Enabled [bool]: defines if the node is enabled to execute audio stem tasks. Defaults to false. 
WorkerName [string]: sets the name of the key that will be used to sign audio stem task work.
WorkerKeyLocation [string]: specifies where the key is stored, in test keychain or OS. If OS is specified, password is retrieved from env var ${PASSWORD}
MinReward [uint]: the absolute minimum reward your node will accept for any given audio stem task submitted. Defaults to zero.
GPUAmount [uint]: how many GPUs you are allowing the node to use while audio stem tasks.
`,
	}

	cmd.AddCommand(
		SetWorker(),
		EnableVideoRendering(),
	)

	cmd.PersistentFlags().String(cli.OutputFlag, "text", "Output format (text|json)")
	flags.AddKeyringFlags(cmd.PersistentFlags())

	return cmd
}
