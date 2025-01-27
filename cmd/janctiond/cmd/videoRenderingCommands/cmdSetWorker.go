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
		Use:     "setWorker <name> <address> <key_chain_location: test|os> <minReward> <gpu amount>",
		Short:   "Configures the video rendering worker parameters",
		Example: "janctiond videoRendering setWorker alice janction15q9yw9qrrmpatsxcngwqycrgr3r7wv295kf3na test 0 1",
		Long: `Worker name is the key is used to submit transactions related to video rendering tasks.
Worker address is the crypto address to be used to sign transactions
Key chain location is either test or os. If os, env variable ${password} will be used to automatically sign transactions.
Min reward is the minimum amount of native tokens to accept any task.
GPU Amount is the amount of available GPUs that will be used to render new video animations.
`,
		Args: cobra.ExactArgs(5),
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
	// TODO validate address is valid
	conf.WorkerAddress = args[1]
	if args[2] != "os" && args[2] != "test" {
		return errors.New("accepted values for key chain location are test or os")
	}
	conf.WorkerKeyLocation = args[2]
	minReward, err := strconv.ParseInt(args[3], 10, 64)
	if err != nil {
		return err
	}

	conf.MinReward = minReward

	gpu, err := strconv.ParseInt(args[4], 10, 64)
	if err != nil {
		return err
	}
	conf.GPUAmount = gpu
	err = conf.SaveConf()
	return err
}
