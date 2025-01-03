package app

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v2"
)

type Config struct {
	Modules []Module `yaml:"modules"`
}

type Module struct {
	Name   string                 `yaml:"name"`
	Config map[string]interface{} `yaml:"config"`
}

func SetRootPath() {
	// Load the YAML file
	file, err := os.Open("./app/app.yaml")
	if err != nil {
		fmt.Printf("Failed to open file: %v\n", err)
		return
	}
	defer file.Close()

	// Decode the YAML
	var cfg Config
	decoder := yaml.NewDecoder(file)
	if err := decoder.Decode(&cfg); err != nil {
		fmt.Printf("Failed to decode YAML: %v\n", err)
		return
	}

	// Modify the videoRendering module's config
	for i, module := range cfg.Modules {
		if module.Name == "videoRendering" {
			module.Config["path"] = DefaultNodeHome
			cfg.Modules[i] = module
		}
	}

	// Write the modified YAML back to the file
	outputFile, err := os.Create("./app/app.yaml")
	if err != nil {
		fmt.Printf("Failed to create output file: %v\n", err)
		return
	}
	defer outputFile.Close()

	encoder := yaml.NewEncoder(outputFile)
	defer encoder.Close()

	if err := encoder.Encode(cfg); err != nil {
		fmt.Printf("Failed to encode YAML: %v\n", err)
		return
	}

}
