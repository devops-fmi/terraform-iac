vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidr = ["10.0.10.0/24", "10.0.11.0/24"]

region             = "eu-central-1"
availability_zones = ["eu-central-1a", "eu-central-1b"]

eks_cluster_name = "elibrary-fmi-devops-eks-cluster"

cluster_version = "1.34"

node_groups = {
  general = {
    instance_types = ["t3.small"]
    capacity_type  = "ON_DEMAND"

    scaling_config = {
      desired_size = 2
      max_size     = 4
      min_size     = 1
    }
  }
}
