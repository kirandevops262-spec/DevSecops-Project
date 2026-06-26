terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80.0"
    }
  }

  backend "s3" {
    bucket         = "dev-tarak01-tf-bucket-terraform"
    region         = "us-east-1"
    key            = "EKS-Terraform/vpc.tfstate"
    encrypt        = true
    dynamodb_table = "dev-tarak01-tf-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "DevSecOps-EKS"
      ManagedBy   = "Terraform"
      Environment = var.env
    }
  }
}
