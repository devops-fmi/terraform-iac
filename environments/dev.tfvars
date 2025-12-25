# Development Environment Configuration
environment              = "dev"
cluster_name             = "eks-dev"
aws_region               = "us-east-1"
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2
kubernetes_version       = "1.28"

# Node configuration for dev (smaller instances)
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

# Enable basic logging for dev
cluster_log_types = ["api", "audit"]
