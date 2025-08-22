package videoupscalercommands

import (
	"bufio"
	"strings"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/spf13/cobra"
)

func EnableVideoRendering() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "enable <bool>",
		Example: "janctiond videoRendering enable true",
		Short:   "Enables or disables the node as a video rendering task worker",
		Long: `Enabling this node as a Video Rendering task worker allows you to earn money by executing video rendering tasks submitted to the network.

Disable at any time to stop executing tasks submitted to the blockchain.
`,
		Args: cobra.ExactArgs(1),
		RunE: runEnableCmdPrepare,
	}

	return cmd
}

func runEnableCmdPrepare(cmd *cobra.Command, args []string) error {
	clientCtx, err := client.GetClientQueryContext(cmd)
	if err != nil {
		return err
	}

	buf := bufio.NewReader(clientCtx.Input)
	return runEnable(clientCtx, cmd, args, buf)
}

func runEnable(ctx client.Context, cmd *cobra.Command, args []string, inBuf *bufio.Reader) error {
	enabled := parseBool(args[0])
	conf, err := GetConf()
	if err != nil {
		return err
	}

	conf.Enabled = enabled
	err = conf.SaveConf()
	return err
}

func parseBool(str string) bool {
	str = strings.ToLower(str)
	return str == "true" || str == "1"
}
