# Production Environment Configuration
environment              = "prod"
cluster_name             = "eks-prod"
aws_region               = "us-east-1"
vpc_cidr                 = "10.2.0.0/16"
availability_zones_count = 3
kubernetes_version       = "1.28"

# Node configuration for production (larger instances, higher availability)
node_instance_types = ["t3.large"]
node_desired_size   = 3
node_min_size       = 3
node_max_size       = 10

# Enable full logging for production
cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
