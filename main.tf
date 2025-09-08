terraform {
  required_version = ">= 1.0, < 2.0" # Anything above1.0 but less than 2.0. 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

module "demo_infra" {
  source = "./01_basic_infra"
}

# Terraform state in S3 bucket. bucket variable needs a hard coded pre-existing bucket name. Terraform 
# cannot create a bucket to store state. I created it manually. 
terraform {
  backend "s3" {
    bucket = "store-tf-state-somthingrandom" # Change it to your unique bucket name.
    key    = "basic_vpc_subnet_ec2_loadbalancer/terraform.tfstate"
    region = "us-east-1" # This need not be same as the region where the resources are created.
  }
}
