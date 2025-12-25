# Backend configuration for staging environment
# Initialize with: terraform init -backend-config=environments/staging-backend.hcl

bucket         = "terraform-state-eks-staging"
key            = "eks/staging/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock-eks-staging"
