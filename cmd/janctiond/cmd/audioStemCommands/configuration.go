package audiostemcommands

import (
	"errors"
	"io/fs"
	"log"
	"os"

	"github.com/BurntSushi/toml"
)

type AudioStemConfiguration struct {
	Enabled           bool   `toml:"enabled"`
	WorkerName        string `toml:"worker_name"`
	WorkerAddress     string `toml:"worker_address"`
	WorkerKeyLocation string `toml:"worker_key_location"`
	MinReward         int64  `toml:"min_reward"`
	GPUAmount         int64  `toml:"gpu_amount"`
}

func GetConf() (*AudioStemConfiguration, error) {
	conf := AudioStemConfiguration{Enabled: false}

	// we verify if the default config path exists
	_, err := os.Stat(DefaultNodeHome)
	if errors.Is(err, fs.ErrNotExist) {
		return &conf, nil
	}

	var path string = DefaultNodeHome + "/config/audioStem.toml"
	// Load the YAML file
	file, err := os.Open(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			conf.SaveConf()
			return &conf, nil
		}

		log.Fatalf("Unable to open AudioStem configuration file. %v", err.Error())
		return nil, err
	}
	defer file.Close()

	decoder := toml.NewDecoder(file)
	if _, err := decoder.Decode(&conf); err != nil {
		log.Fatalf("Failed to decode YAML: %v\n", err.Error())
		return nil, err
	}

	return &conf, nil
}

func (c *AudioStemConfiguration) SaveConf() error {
	// we verify if the default config path exists
	_, err := os.Stat(DefaultNodeHome)
	if errors.Is(err, fs.ErrNotExist) {
		return nil
	}

	var path string = DefaultNodeHome + "/config/audioStem.toml"
	// Marshal the struct into YAML format
	data, err := toml.Marshal(&c)
	if err != nil {
		log.Fatalf("Error marshaling to YAML: %v\n", err)
		return err
	}

	// Save the YAML data to a file
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = file.Write(data)
	if err != nil {
		return err
	}

	return nil
}
