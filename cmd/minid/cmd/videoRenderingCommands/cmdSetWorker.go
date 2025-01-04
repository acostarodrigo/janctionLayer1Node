package videorenderingcommands

import (
	"bufio"
	"errors"
	"strconv"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/spf13/cobra"
)

func SetWorker() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "setWorker <name> <key_chain_location: test|os> <minReward> <gpu amount>",
		Short: "Configures the video rendering worker parameters",
		Long: `Worker name is the key is used to submit transactions related to video rendering tasks.

Key chain location is either test or os. If os, env variable ${password} will be used to automatically sign transactions.
Min reward is the minimum amount of native tokens to accept any task.
GPU Amount is the amount of available GPUs that will be used to render new video animations.
`,
		Args: cobra.ExactArgs(4),
		RunE: runsetWorkerCmdPrepare,
	}

	return cmd
}

func runsetWorkerCmdPrepare(cmd *cobra.Command, args []string) error {
	clientCtx, err := client.GetClientQueryContext(cmd)
	if err != nil {
		return err
	}

	buf := bufio.NewReader(clientCtx.Input)
	return runSetWorker(clientCtx, cmd, args, buf)
}

func runSetWorker(ctx client.Context, cmd *cobra.Command, args []string, inBuf *bufio.Reader) error {
	conf, err := GetConf()
	if err != nil {
		return err
	}

	conf.WorkerName = args[0]
	if args[1] != "os" && args[1] != "test" {
		return errors.New("accepted values for key chain location are test or os")
	}
	conf.WorkerKeyLocation = args[1]
	minReward, err := strconv.ParseInt(args[2], 10, 64)
	if err != nil {
		return err
	}

	conf.MinReward = minReward

	gpu, err := strconv.ParseInt(args[3], 10, 64)
	if err != nil {
		return err
	}
	conf.GPUAmount = gpu
	err = conf.SaveConf()
	return err
}
