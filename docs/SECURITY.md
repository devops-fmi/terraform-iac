# Security Considerations

## IAM Permissions for GitHub Actions

The default configuration grants the GitHub Actions IAM role `AdministratorAccess` to simplify initial setup and ensure all necessary permissions are available. However, this follows the principle of **maximum convenience** rather than **least privilege**.

### Why AdministratorAccess?

The infrastructure setup requires permissions to:
- Create and manage VPCs, subnets, route tables, and internet/NAT gateways
- Create and manage EKS clusters and node groups
- Create and manage IAM roles, policies, and instance profiles
- Create and manage security groups and network ACLs
- Create and manage EC2 instances (as part of node groups)
- Create and manage Elastic IPs
- Create and manage CloudWatch log groups
- Tag resources

### Recommended: Custom IAM Policy for Production

For production environments, replace `AdministratorAccess` with a custom policy. Here's an example:

```hcl
# Replace the policy attachment in main.tf with:

resource "aws_iam_policy" "github_actions_eks" {
  name        = "github-actions-eks-management"
  description = "Custom policy for GitHub Actions to manage EKS infrastructure"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EKS Permissions
          "eks:*",
          
          # EC2 Permissions for VPC and Node Groups
          "ec2:Describe*",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpc*",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroup*",
          "ec2:RevokeSecurityGroup*",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          
          # IAM Permissions
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          
          # Auto Scaling
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:Describe*",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:CreateLaunchConfiguration",
          "autoscaling:DeleteLaunchConfiguration",
          
          # CloudWatch Logs
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:TagLogGroup",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_custom_policy" {
  role       = aws_iam_role.github_actions_admin.name
  policy_arn = aws_iam_policy.github_actions_eks.arn
}

# Remove or comment out the AdministratorAccess attachment:
# resource "aws_iam_role_policy_attachment" "github_actions_admin_policy" {
#   role       = aws_iam_role.github_actions_admin.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }
```

### Additional Security Hardening

1. **Restrict to Main Branch Only**:
   ```hcl
   # In main.tf, update the trust policy condition:
   StringEquals = {
     "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
     "token.actions.githubusercontent.com:sub" = "repo:devops-fmi/terraform-iac:ref:refs/heads/main"
   }
   ```

2. **Use GitHub Environment Protection Rules**:
   - Require manual approval for production deployments
   - Limit deployment to specific branches
   - Add deployment branch policies

3. **Enable AWS CloudTrail**:
   - Monitor all API calls made by the GitHub Actions role
   - Set up alerts for suspicious activity
   - Regularly review logs

4. **Rotate Credentials**:
   - While OIDC doesn't use long-lived credentials, periodically review and update the trust relationship
   - Update OIDC thumbprints if GitHub changes them

5. **Use Separate Roles per Environment**:
   - Create different IAM roles for dev, staging, and prod
   - Grant different permissions based on environment sensitivity
   - Use environment-specific trust policies

## State File Security

The Terraform state file contains sensitive information:

1. **Encryption**: Already enabled via S3 server-side encryption
2. **Versioning**: Enabled to recover from accidental changes
3. **Access Control**: Restrict S3 bucket access to necessary IAM roles only
4. **Locking**: DynamoDB table prevents concurrent modifications

### Additional State Security Measures

```bash
# Add bucket policy to restrict access
aws s3api put-bucket-policy --bucket terraform-state-eks-prod --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::terraform-state-eks-prod",
        "arn:aws:s3:::terraform-state-eks-prod/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}'

# Enable S3 bucket logging
aws s3api put-bucket-logging --bucket terraform-state-eks-prod \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "my-logging-bucket",
      "TargetPrefix": "terraform-state-logs/"
    }
  }'
```

## Network Security

1. **Private Subnets**: Worker nodes run in private subnets
2. **Security Groups**: Minimal required access between components
3. **Network ACLs**: Consider adding for additional network layer security
4. **VPC Flow Logs**: Enable to monitor network traffic

## EKS Security Best Practices

1. **API Server Endpoint**:
   - Current: Public and private access enabled
   - Consider: Private-only for production

2. **Secrets Encryption**:
   - Enable envelope encryption for Kubernetes secrets
   - Use AWS KMS for encryption keys

3. **Pod Security**:
   - Implement Pod Security Standards
   - Use Network Policies to restrict pod-to-pod communication

4. **RBAC**:
   - Use IAM roles for service accounts (IRSA)
   - Apply least privilege for workload permissions

## Monitoring and Alerting

1. **CloudWatch Alarms**: Set up alerts for:
   - Unauthorized API calls
   - Failed authentication attempts
   - Resource creation/deletion

2. **AWS Config**: Monitor configuration compliance

3. **GuardDuty**: Enable for threat detection

## Compliance

Ensure compliance with:
- SOC 2
- HIPAA (if applicable)
- PCI DSS (if applicable)
- GDPR (if applicable)

## Security Checklist

Before deploying to production:

- [ ] Replace AdministratorAccess with custom policy
- [ ] Enable CloudTrail logging
- [ ] Enable VPC Flow Logs
- [ ] Configure CloudWatch alarms
- [ ] Enable GuardDuty
- [ ] Implement GitHub environment protection rules
- [ ] Review and restrict security group rules
- [ ] Enable EKS secrets encryption
- [ ] Configure pod security policies
- [ ] Set up backup and disaster recovery
- [ ] Document incident response procedures
- [ ] Conduct security review/audit

## References

- [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [Terraform Security Best Practices](https://developer.hashicorp.com/terraform/tutorials/aws/security-terraform)
- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
