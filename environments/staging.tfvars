# Staging Environment Configuration
environment              = "staging"
cluster_name             = "eks-staging"
aws_region               = "us-east-1"
vpc_cidr                 = "10.1.0.0/16"
availability_zones_count = 2
kubernetes_version       = "1.28"

# Node configuration for staging (medium instances)
node_instance_types = ["t3.large"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 5

# Enable more logging for staging
cluster_log_types = ["api", "audit", "authenticator"]
