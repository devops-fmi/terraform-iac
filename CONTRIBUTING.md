# Contributing to Terraform AWS EKS Infrastructure

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Security](#security)

## Getting Started

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform >= 1.0
- Git
- Basic understanding of Terraform and AWS EKS

### Initial Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/terraform-iac.git
   cd terraform-iac
   ```

3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/devops-fmi/terraform-iac.git
   ```

4. Run the setup script:
   ```bash
   ./scripts/setup.sh
   ```

## Development Workflow

### Making Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the code standards below

3. **Format your code**:
   ```bash
   terraform fmt -recursive
   ```

4. **Validate your changes**:
   ```bash
   terraform init -backend=false
   terraform validate
   ```

5. **Test your changes** (if applicable):
   - Test in a dev environment first
   - Document any manual testing performed
   - Include test results in PR description

### Keeping Your Fork Updated

```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

## Pull Request Process

### Before Submitting

- [ ] Code is formatted with `terraform fmt`
- [ ] Configuration passes `terraform validate`
- [ ] Changes are tested in a non-production environment
- [ ] Documentation is updated (README, comments, etc.)
- [ ] Commit messages are clear and descriptive
- [ ] No sensitive data (credentials, keys, etc.) is included

### Submitting a Pull Request

1. **Push your changes**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Open a Pull Request** on GitHub with:
   - Clear title describing the change
   - Detailed description of what and why
   - Reference any related issues
   - Include test results or manual verification steps
   - Screenshots (if UI-related)

3. **Address review comments**:
   - Make requested changes
   - Push updates to your branch
   - Respond to reviewer comments

4. **Wait for CI checks**:
   - Terraform Plan workflow will run automatically
   - Fix any issues identified by the workflow

### PR Title Format

Use conventional commit format:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Test additions or updates
- `chore:` - Maintenance tasks

Examples:
- `feat: add support for spot instances in node groups`
- `fix: correct subnet CIDR calculation for prod environment`
- `docs: update README with new deployment instructions`

## Code Standards

### Terraform Code Style

1. **Naming Conventions**:
   - Use lowercase with hyphens for resource names: `aws_vpc.main`
   - Use descriptive names: `eks_cluster_role` not `role1`
   - Prefix related resources: `eks_*`, `vpc_*`

2. **File Organization**:
   - `main.tf` - Primary resources
   - `variables.tf` - Input variables
   - `outputs.tf` - Output values
   - `versions.tf` - Provider version constraints (if separated)

3. **Resource Naming**:
   ```hcl
   # Good
   resource "aws_vpc" "main" {
     cidr_block = var.vpc_cidr
     tags = {
       Name = "${var.cluster_name}-vpc"
     }
   }
   
   # Bad
   resource "aws_vpc" "vpc1" {
     cidr_block = "10.0.0.0/16"
   }
   ```

4. **Variables**:
   - Always include description
   - Add validation where appropriate
   - Set sensible defaults
   - Group related variables

5. **Comments**:
   - Explain "why" not "what"
   - Document complex logic
   - Keep comments up-to-date

### Documentation Standards

- Update README.md for significant changes
- Document new variables in both code and README
- Include examples for new features
- Keep architecture diagrams current

## Testing

### Manual Testing

Before submitting a PR:

1. **Initialize Terraform**:
   ```bash
   terraform init -backend-config=environments/dev-backend.hcl
   ```

2. **Run Plan**:
   ```bash
   terraform plan -var-file=environments/dev.tfvars
   ```

3. **Review Output**:
   - Verify expected changes
   - Check for unintended modifications
   - Ensure no resources are destroyed unexpectedly

4. **Test in Dev Environment** (if safe):
   ```bash
   terraform apply -var-file=environments/dev.tfvars
   ```

5. **Verify Functionality**:
   - Test EKS cluster access
   - Verify node group scaling
   - Check security group rules

### Automated Testing

- GitHub Actions will automatically run `terraform plan` on PRs
- Review the plan output in the PR comments
- Address any issues identified

## Security

### Security Best Practices

- **Never commit secrets**: Use AWS Secrets Manager or Parameter Store
- **Use IAM roles**: Prefer OIDC over static credentials
- **Follow least privilege**: Grant minimum necessary permissions
- **Enable encryption**: Use encrypted S3 buckets and EBS volumes
- **Review security groups**: Ensure they're not overly permissive
- **Keep dependencies updated**: Regularly update provider versions

### Reporting Security Issues

If you discover a security vulnerability:

1. **Do not** open a public issue
2. Email the maintainers directly
3. Provide detailed information about the vulnerability
4. Allow time for patching before disclosure

### Security Checklist for PRs

- [ ] No hardcoded credentials or secrets
- [ ] IAM policies follow least privilege
- [ ] Security groups are appropriately restrictive
- [ ] Encryption is enabled where applicable
- [ ] No public exposure of private resources

## Questions?

If you have questions:

- Open a GitHub Discussion
- Review existing issues
- Check the documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Thank You!

Your contributions help make this project better for everyone!
