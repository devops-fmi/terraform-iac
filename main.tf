terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.25.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
  }

  backend "s3" {
    bucket       = "elibrary-terraform-state-bucket"
    key          = "dev/terraform-state"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true # Enable state locking via native file lock
  }

  required_version = ">= 1.14"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "elibrary-fmi-devops-course"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


module "vpc" {
  source = "./modules/vpc"

  region              = var.region
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones  # List of availability zones to distribute subnets across
  private_subnet_cidr = var.private_subnet_cidr # CIDR blocks for private subnets
  public_subnet_cidr  = var.public_subnet_cidr  # CIDR blocks for public subnets
  eks_cluster_name    = var.eks_cluster_name    # Optional: used inside VPC module for tagging or naming
}


module "eks" {
  source = "./modules/eks"

  region           = var.region
  eks_cluster_name = var.eks_cluster_name          # Name of the EKS cluster to create
  cluster_version  = var.cluster_version           # Kubernetes version for the EKS control plane
  vpc_id           = module.vpc.vpc_id             # Use VPC ID output from the VPC module
  subnet_ids       = module.vpc.private_subnet_ids # Use private subnet IDs from the VPC module
  node_groups      = var.node_groups               # Map of node group configurations to launch worker nodes
}

module "argocd" {
  source = "./modules/eks/argocd"

  cluster_name = module.eks.cluster_name

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}
