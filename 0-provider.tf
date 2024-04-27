// Setting the terraform configuration
// Docs on providers:  https://developer.hashicorp.com/terraform/language/providers
// For this project, AWS provider is required: 
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs
terraform {
  required_version = ">= 0.12"
    
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

// Configuring the provider
// We could also define a profile = "nameProfile"
// If not set, "default" profile is taken
provider "aws" {
    region = "eu-central-1"
    shared_credentials_files = ["/Users/didie/.aws/credentials"]
}