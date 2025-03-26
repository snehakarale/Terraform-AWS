terraform {
  # Specifies the required providers for Terraform.
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Provider source
      version = ">= 5.0"        # Version of the AWS provider
    }

  }
  required_version = "~> 1.2" # Specifies the Terraform version required.
}

# AWS provider configuration block.
provider "aws" {

  region = "us-east-1"
  #define tags that are automatically added to all resources managed by Terraform.
  default_tags {
    tags = {
      Management = "Terraform"
    }
  }

}