# Backend configuration for dev environment
# Initialize with: terraform init -backend-config=environments/dev-backend.hcl

bucket         = "terraform-state-eks-dev"
key            = "eks/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock-eks-dev"
