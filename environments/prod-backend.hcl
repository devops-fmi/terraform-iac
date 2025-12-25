# Backend configuration for production environment
# Initialize with: terraform init -backend-config=environments/prod-backend.hcl

bucket         = "terraform-state-eks-prod"
key            = "eks/prod/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock-eks-prod"
