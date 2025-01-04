package videorenderingcommands

import (
	"log"
	"testing"
)

func Test_GetConfiguration(t *testing.T) {
	DefaultNodeHome = "/Users/rodrigoacosta/.minid"
	conf, err := GetConf()

	if err != nil {
		log.Println("error", err.Error())
	}

	log.Println(conf.Enabled)
}
