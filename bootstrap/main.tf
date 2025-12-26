# bootstrap/main.tf

provider "aws" {
  region = "eu-central-1"
  profile = "default"
}

# 1. The S3 Bucket to store the .tfstate file
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-company-terraform-state-prod" # Must be globally unique

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# 2. Enable Versioning (Crucial for state recovery)
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Enable Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID" # This attribute name is mandatory for Terraform

  attribute {
    name = "LockID"
    type = "S"
  }
}