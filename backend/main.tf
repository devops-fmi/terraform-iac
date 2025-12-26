terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.25.0"
    }
  }
  
  backend "s3" {
    bucket       = "elibrary-terraform-state-bucket"
    key          = "dev/terraform-state"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true # Enable state locking via native file lock
  }

  required_version = ">= 1.2"
}



provider "aws" {
  region  = "eu-central-1"
  profile = "default"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "elibrary-fmi-devops-course"
    }
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "elibrary-terraform-state-bucket" # Must be globally unique

  lifecycle {
    prevent_destroy = true
  }
}
