# Terraform AWS EKS Infrastructure as Code

This repository contains Terraform Infrastructure as Code (IaC) for provisioning and managing AWS EKS (Elastic Kubernetes Service) clusters across multiple environments.

## 🏗️ Architecture

This setup provisions:
- **AWS EKS Cluster** with managed node groups
- **VPC** with public and private subnets across multiple availability zones
- **NAT Gateways** for private subnet internet access
- **Security Groups** for cluster and node security
- **IAM Roles** for EKS cluster, nodes, and GitHub Actions OIDC authentication
- **Multi-environment support** (dev, staging, prod)

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.0 installed
4. **S3 Buckets** for Terraform state (one per environment):
   - `terraform-state-eks-dev`
   - `terraform-state-eks-staging`
   - `terraform-state-eks-prod`
5. **DynamoDB Tables** for state locking (one per environment):
   - `terraform-state-lock-eks-dev`
   - `terraform-state-lock-eks-staging`
   - `terraform-state-lock-eks-prod`

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/devops-fmi/terraform-iac.git
cd terraform-iac
```

### 2. Create S3 Backend and DynamoDB Table

Before running Terraform, create the S3 buckets and DynamoDB tables for state management:

```bash
# Create S3 bucket for dev environment
aws s3api create-bucket \
  --bucket terraform-state-eks-dev \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-eks-dev \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock-eks-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1

# Repeat for staging and prod environments
```

### 3. Initialize Terraform

```bash
# For dev environment
terraform init -backend-config=environments/dev-backend.hcl

# For staging environment
terraform init -backend-config=environments/staging-backend.hcl

# For prod environment
terraform init -backend-config=environments/prod-backend.hcl
```

### 4. Plan and Apply

```bash
# Plan for dev environment
terraform plan -var-file=environments/dev.tfvars

# Apply for dev environment
terraform apply -var-file=environments/dev.tfvars
```

## 🔐 GitHub Actions Setup

This repository uses GitHub Actions for automated infrastructure deployment with AWS OIDC authentication.

### Prerequisites for GitHub Actions

1. **AWS IAM OIDC Provider**: The Terraform configuration creates this automatically
2. **AWS Account ID**: Store as GitHub secret `AWS_ACCOUNT_ID`
3. **GitHub Environments**: Create environments (dev, staging, prod) in repository settings

### Setup Steps

1. **Apply Terraform manually first** to create the IAM role:
   ```bash
   terraform apply -var-file=environments/dev.tfvars
   ```

2. **Note the GitHub Actions Role ARN** from the output:
   ```bash
   terraform output github_actions_role_arn
   ```

3. **Add AWS Account ID to GitHub Secrets**:
   - Go to repository Settings > Secrets and variables > Actions
   - Add new secret: `AWS_ACCOUNT_ID` with your AWS account ID

4. **Configure Branch Protection** (optional but recommended):
   - Go to Settings > Branches
   - Add rule for `main` branch
   - Enable "Require a pull request before merging"
   - Enable "Require status checks to pass before merging"

### Workflows

#### Terraform Plan (PR)
- Triggers on pull requests to `main`
- Runs `terraform plan` for all environments
- Posts plan output as PR comment
- Read-only operation

#### Terraform Apply (Main)
- Triggers on push to `main` branch
- Runs `terraform apply` for all environments
- Automatically applies infrastructure changes
- Can be triggered manually via workflow_dispatch

## 📁 Project Structure

```
.
├── main.tf                      # Main Terraform configuration
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output definitions
├── terraform.tfvars.example     # Example variables file
├── environments/
│   ├── dev.tfvars              # Dev environment variables
│   ├── dev-backend.hcl         # Dev backend configuration
│   ├── staging.tfvars          # Staging environment variables
│   ├── staging-backend.hcl     # Staging backend configuration
│   ├── prod.tfvars             # Production environment variables
│   └── prod-backend.hcl        # Production backend configuration
└── .github/
    └── workflows/
        ├── terraform-plan.yml   # PR workflow
        └── terraform-apply.yml  # Main branch workflow
```

## 🌍 Environments

### Development (dev)
- **Purpose**: Development and testing
- **Node Size**: t3.medium
- **Node Count**: 1-3 nodes
- **VPC CIDR**: 10.0.0.0/16
- **AZs**: 2

### Staging (staging)
- **Purpose**: Pre-production testing
- **Node Size**: t3.large
- **Node Count**: 2-5 nodes
- **VPC CIDR**: 10.1.0.0/16
- **AZs**: 2

### Production (prod)
- **Purpose**: Production workloads
- **Node Size**: t3.large
- **Node Count**: 3-10 nodes
- **VPC CIDR**: 10.2.0.0/16
- **AZs**: 3

## 🔧 Configuration

### Customizing Variables

Edit the environment-specific `.tfvars` files in the `environments/` directory:

```hcl
environment              = "dev"
cluster_name             = "eks-dev"
aws_region               = "us-east-1"
node_instance_types      = ["t3.medium"]
node_desired_size        = 2
node_min_size            = 1
node_max_size            = 4
```

### Available Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `environment` | Environment name | Required |
| `cluster_name` | EKS cluster name | Required |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `availability_zones_count` | Number of AZs | `2` |
| `kubernetes_version` | Kubernetes version | `1.28` |
| `node_instance_types` | EC2 instance types | `["t3.medium"]` |
| `node_desired_size` | Desired node count | `2` |
| `node_min_size` | Minimum node count | `1` |
| `node_max_size` | Maximum node count | `4` |

## 🔑 Accessing the EKS Cluster

After the cluster is created, configure kubectl:

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-dev

# Verify connection
kubectl get nodes
kubectl get pods -A
```

## 🛡️ Security

- **IAM Roles**: Separate roles for cluster, nodes, and GitHub Actions
- **OIDC Authentication**: GitHub Actions uses OIDC for secure, keyless AWS authentication
- **Network Isolation**: Private subnets for worker nodes
- **Encryption**: S3 state encryption enabled
- **State Locking**: DynamoDB prevents concurrent modifications

### GitHub Actions IAM Role

The Terraform configuration creates an IAM role with:
- **Trust Policy**: GitHub OIDC provider for this repository
- **Permissions**: AdministratorAccess (required for full infrastructure management)
- **Usage**: Automatically assumed by GitHub Actions workflows

## 📊 Outputs

After applying, Terraform provides:
- EKS cluster endpoint
- Cluster certificate authority data
- VPC and subnet IDs
- GitHub Actions role ARN
- Node group details

View outputs:
```bash
terraform output
```

## 🧹 Cleanup

To destroy the infrastructure:

```bash
# For dev environment
terraform destroy -var-file=environments/dev.tfvars

# Confirm with 'yes' when prompted
```

## 🤝 Contributing

1. Create a feature branch
2. Make changes
3. Open a pull request
4. Terraform plan will run automatically
5. After review and merge, Terraform apply runs on main

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Troubleshooting

### Common Issues

1. **State Locking Error**: Ensure DynamoDB table exists and has proper permissions
2. **OIDC Authentication Failed**: Verify AWS Account ID secret is correct
3. **Insufficient Permissions**: Ensure IAM role has necessary policies attached
4. **Resource Quota Exceeded**: Check AWS service quotas for EKS and EC2

### Getting Help

- Check [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- Review [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- Open an issue in this repository