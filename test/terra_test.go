package main

import (
	"fmt"
	"log"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

var (
	globalEnvVars = make(map[string]string)
)

const (
	location = "ap-south-1"
	ami_id   = "ami-0e6329e45466hj2"
)

func setTerraformVariables() (map[string]string, error) {
	aws_access_key := os.Getenv("aws_access_key")
	aws_secret_key := os.Getenv("aws_secret_key")

	if aws_access_key != "" {
		globalEnvVars[aws_access_key] = aws_access_key
		globalEnvVars[aws_secret_key] = aws_secret_key
	}
	return globalEnvVars, nil
}
func TestTerraformInstance(t *testing.T) {
	t.Parallel()
	setTerraformVariables()

	expectedInstanceType := "t2.micro"
	expectedLocation := "ap-south-1"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../module",
		// Getting enVars from environment variables
		Vars: map[string]interface{}{

			"instance_type": expectedInstanceType,
			"location":      expectedLocation,
		},
		EnvVars: globalEnvVars,
	})
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	init, err := terraform.InitE(t, terraformOptions)
	if err != nil {
		log.Println(err)
	}
	t.Log(init)
	//terraform vaildate
	// validate, err := terraform.ValidateE(t, terraformOptions)
	// if err != nil {
	// 	log.Println(err)
	// }
	//t.Log(validate)
	//terraform planning
	plan, err := terraform.PlanE(t, terraformOptions)
	if err != nil {
		log.Println(err)
	}
	t.Log(plan)
	//terraform applying
	apply, err := terraform.ApplyE(t, terraformOptions)
	if err != nil {
		log.Println(err)
	}
	t.Log(apply)

	// expectedInstanceType := terraform.Output(t, terraformOptions, "instance_type")
	//expectedAmiId := terraform.Output(t, terraformOptions, "ami_id")
	// expectedLocation := terraform.Output(t, terraformOptions, "location")

	fmt.Printf("ami-id :: %s\n", ami_id)
	fmt.Printf("instance_type :: %s\n", expectedInstanceType)
	fmt.Printf("location :: %s\n", expectedLocation)
}
