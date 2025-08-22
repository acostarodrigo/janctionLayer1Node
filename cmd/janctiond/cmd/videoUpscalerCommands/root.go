package videoupscalercommands

import (
	"github.com/cometbft/cometbft/libs/cli"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/spf13/cobra"
)

var DefaultNodeHome string

func Commands(defaultNodeHome string) *cobra.Command {
	DefaultNodeHome = defaultNodeHome
	cmd := &cobra.Command{
		Use:   "videoUpscaler",
		Short: "Manage your video upscaler task configuration",
		Long: `Video Upscaler management commands. 
		
Allows you to configure your node as a Video rendering tasks worker to execute video rendering tasks submitted to the chain.

You will be able to use your Janction node to earn tokens by rendering videos.
Configurations are:

Enabled [bool]: defines if the node is enabled to execute render video tasks. Defaults to false. 
WorkerName [string]: sets the name of the key that will be used to sign video rendering task work.
WorkerKeyLocation [string]: specifies where the key is stored, in test keychain or OS. If OS is specified, password is retrieved from env var ${PASSWORD}
MinReward [uint]: the absolute minimum reward your node will accept for any given video rendering task submitted. Defaults to zero.
GPUAmount [uint]: how many GPUs you are allowing the node to use while rendering video tasks.
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
