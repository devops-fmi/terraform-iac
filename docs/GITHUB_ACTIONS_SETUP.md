# GitHub Actions Setup Guide

This guide walks you through setting up GitHub Actions for automated Terraform deployments.

## Prerequisites

- AWS Account with admin access
- GitHub repository with appropriate permissions
- Terraform infrastructure already applied once manually

## Step-by-Step Setup

### 1. Initial Manual Deployment

First, deploy the infrastructure manually to create the GitHub Actions IAM role:

```bash
# Run the setup script to create S3 and DynamoDB resources
./scripts/setup.sh

# Initialize Terraform
terraform init -backend-config=environments/dev-backend.hcl

# Apply to create the IAM role and OIDC provider
terraform apply -var-file=environments/dev.tfvars
```

### 2. Get the IAM Role ARN

After successful deployment, get the GitHub Actions role ARN:

```bash
terraform output github_actions_role_arn
```

Example output:
```
arn:aws:iam::123456789012:role/github-actions-terraform-admin
```

### 3. Get Your AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

Example output:
```
123456789012
```

### 4. Configure GitHub Repository Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add the following secret:
   - Name: `AWS_ACCOUNT_ID`
   - Value: Your AWS account ID (e.g., `123456789012`)

### 5. Configure GitHub Environments (Optional but Recommended)

For better control and protection rules:

1. Go to **Settings** > **Environments**
2. Create three environments: `dev`, `staging`, `prod`
3. For each environment, configure:

   **Dev Environment:**
   - No required reviewers (auto-deploy)
   - Deployment branches: Any branch (for testing)

   **Staging Environment:**
   - Optional: Add 1 required reviewer
   - Deployment branches: `main` branch only

   **Prod Environment:**
   - Required: Add 2 required reviewers
   - Deployment branches: `main` branch only
   - Optional: Add a wait timer (e.g., 5 minutes)

### 6. Test the Workflows

#### Test Plan Workflow (Pull Request)

1. Create a test branch:
   ```bash
   git checkout -b test-github-actions
   ```

2. Make a small change (e.g., update a comment in `main.tf`):
   ```bash
   echo "# Test change" >> main.tf
   ```

3. Commit and push:
   ```bash
   git add main.tf
   git commit -m "test: verify GitHub Actions workflow"
   git push origin test-github-actions
   ```

4. Open a Pull Request on GitHub

5. Verify that the **Terraform Plan** workflow runs:
   - Check the Actions tab
   - Review the plan output in PR comments
   - Ensure no errors occur

#### Test Apply Workflow (Main Branch)

1. Merge the test PR to `main`

2. Verify that the **Terraform Apply** workflow runs:
   - Check the Actions tab
   - Monitor the apply process
   - Verify successful deployment

3. If using environments with reviewers:
   - Wait for the review request
   - Approve the deployment
   - Verify the apply completes

### 7. Workflow Behavior

#### Automatic Triggers

**Terraform Plan** runs on:
- Pull requests to `main` branch
- Changes to `.tf`, `.tfvars`, or workflow files
- Runs for all environments (dev, staging, prod)
- Posts plan output as PR comments

**Terraform Apply** runs on:
- Push to `main` branch
- Runs for all environments in sequence
- Uses environment protection rules (if configured)

#### Manual Triggers

You can manually trigger the apply workflow:

1. Go to **Actions** tab
2. Select **Terraform Apply** workflow
3. Click **Run workflow**
4. Choose the environment (dev, staging, or prod)
5. Click **Run workflow** button

## Workflow Files

### terraform-plan.yml

- **Purpose**: Preview infrastructure changes
- **Trigger**: Pull requests to main
- **Permissions**: Read-only
- **Outputs**: Plan details in PR comments

### terraform-apply.yml

- **Purpose**: Apply infrastructure changes
- **Trigger**: Push to main, manual dispatch
- **Permissions**: Write (via IAM role)
- **Outputs**: Apply status and outputs

## Troubleshooting

### Error: "Error assuming role"

**Cause**: AWS Account ID secret is incorrect or missing

**Solution**:
1. Verify `AWS_ACCOUNT_ID` secret is set correctly
2. Check the IAM role ARN: `terraform output github_actions_role_arn`
3. Ensure the role exists in AWS

### Error: "No such bucket"

**Cause**: S3 backend bucket doesn't exist

**Solution**:
1. Run the setup script: `./scripts/setup.sh`
2. Verify buckets exist: `aws s3 ls | grep terraform-state-eks`

### Error: "Access Denied"

**Cause**: IAM role lacks necessary permissions

**Solution**:
1. Check the IAM role has AdministratorAccess policy attached
2. Verify the trust relationship includes GitHub OIDC provider
3. Review CloudTrail logs for specific permission issues

### Workflow Fails with "terraform validate" Error

**Cause**: Invalid Terraform configuration

**Solution**:
1. Run locally: `terraform validate`
2. Fix the validation errors
3. Run `terraform fmt` to format code
4. Commit and push fixes

### Plan Shows Unexpected Changes

**Cause**: Configuration drift or state issues

**Solution**:
1. Review the plan output carefully
2. Check if manual changes were made in AWS Console
3. Use `terraform refresh` to update state
4. Consider using `terraform import` for drifted resources

## Security Considerations

### IAM Role Permissions

The GitHub Actions role has `AdministratorAccess`. This is required for:
- Creating VPCs, subnets, route tables
- Managing EKS clusters and node groups
- Creating IAM roles and policies
- Managing security groups

**Note**: For production use, consider creating a custom policy with only the necessary permissions.

### OIDC Trust Policy

The trust policy is configured to trust only:
- GitHub's OIDC provider
- This specific repository (`devops-fmi/terraform-iac`)
- Any branch/tag in the repository

To restrict further:
1. Edit the trust policy in `main.tf`
2. Change the condition to match specific branches:
   ```hcl
   StringLike = {
     "token.actions.githubusercontent.com:sub" = "repo:devops-fmi/terraform-iac:ref:refs/heads/main"
   }
   ```

### Secrets Management

- Never commit AWS credentials to the repository
- Use GitHub Secrets for sensitive values
- Rotate credentials regularly
- Use environment-specific secrets when needed

## Best Practices

1. **Always review plans**: Check PR comments before merging
2. **Use environments**: Set up approval requirements for prod
3. **Monitor workflows**: Check Actions tab regularly
4. **Enable notifications**: Get alerts for workflow failures
5. **Keep backups**: S3 versioning is enabled for state files
6. **Document changes**: Use clear commit messages
7. **Test in dev first**: Validate changes in dev before prod

## Additional Resources

- [GitHub Actions with AWS OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)

## Support

If you encounter issues:
1. Check the workflow logs in GitHub Actions
2. Review this troubleshooting guide
3. Check AWS CloudTrail for API errors
4. Open an issue in the repository
