terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
  }
  backend "s3" {
    bucket         = "dev-tarak01-tf-bucket-terraform"
    region         = "us-east-1"
    key            = "EKS-Terraform/eks.tfstate"
    encrypt        = true
    dynamodb_table = "dev-tarak01-tf-lock"
  }
}

provider "aws" {
  region = var.aws-region
}
 