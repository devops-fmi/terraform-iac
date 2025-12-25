#!/bin/bash

# Setup script for Terraform AWS EKS Infrastructure
# This script creates the necessary S3 buckets and DynamoDB tables for Terraform state management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENTS=("dev" "staging" "prod")

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Terraform AWS EKS Setup Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials are not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI is installed and configured${NC}"
echo ""

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "AWS Account ID: ${YELLOW}${AWS_ACCOUNT_ID}${NC}"
echo -e "AWS Region: ${YELLOW}${AWS_REGION}${NC}"
echo ""

# Function to create S3 bucket
create_s3_bucket() {
    local bucket_name=$1
    local environment=$2
    
    echo -n "Creating S3 bucket: ${bucket_name}... "
    
    if ! aws s3api head-bucket --bucket "${bucket_name}" 2>/dev/null; then
        if [ "${AWS_REGION}" = "us-east-1" ]; then
            aws s3api create-bucket \
                --bucket "${bucket_name}" \
                --region "${AWS_REGION}" > /dev/null 2>&1
        else
            aws s3api create-bucket \
                --bucket "${bucket_name}" \
                --region "${AWS_REGION}" \
                --create-bucket-configuration LocationConstraint="${AWS_REGION}" > /dev/null 2>&1
        fi
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "${bucket_name}" \
            --versioning-configuration Status=Enabled > /dev/null 2>&1
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "${bucket_name}" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    },
                    "BucketKeyEnabled": true
                }]
            }' > /dev/null 2>&1
        
        # Block public access
        aws s3api put-public-access-block \
            --bucket "${bucket_name}" \
            --public-access-block-configuration \
                "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" > /dev/null 2>&1
        
        echo -e "${GREEN}✓ Created${NC}"
    else
        echo -e "${YELLOW}Already exists${NC}"
    fi
}

# Function to create DynamoDB table
create_dynamodb_table() {
    local table_name=$1
    local environment=$2
    
    echo -n "Creating DynamoDB table: ${table_name}... "
    
    if ! aws dynamodb describe-table --table-name "${table_name}" --region "${AWS_REGION}" > /dev/null 2>&1; then
        aws dynamodb create-table \
            --table-name "${table_name}" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "${AWS_REGION}" \
            --tags "Key=Environment,Value=${environment}" "Key=ManagedBy,Value=Terraform" \
            > /dev/null 2>&1
        
        echo -e "${GREEN}✓ Created${NC}"
    else
        echo -e "${YELLOW}Already exists${NC}"
    fi
}

# Create resources for each environment
for env in "${ENVIRONMENTS[@]}"; do
    echo -e "${YELLOW}Setting up ${env} environment...${NC}"
    
    BUCKET_NAME="terraform-state-eks-${env}"
    TABLE_NAME="terraform-state-lock-eks-${env}"
    
    create_s3_bucket "${BUCKET_NAME}" "${env}"
    create_dynamodb_table "${TABLE_NAME}" "${env}"
    
    echo ""
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Initialize Terraform for each environment:"
echo "   ${YELLOW}terraform init -backend-config=environments/dev-backend.hcl${NC}"
echo ""
echo "2. Plan and apply for an environment:"
echo "   ${YELLOW}terraform plan -var-file=environments/dev.tfvars${NC}"
echo "   ${YELLOW}terraform apply -var-file=environments/dev.tfvars${NC}"
echo ""
echo "3. Add AWS_ACCOUNT_ID to GitHub Secrets:"
echo "   ${YELLOW}AWS_ACCOUNT_ID: ${AWS_ACCOUNT_ID}${NC}"
echo ""
