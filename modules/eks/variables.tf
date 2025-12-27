variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Version of the cluster"
  type        = string
}

variable "node_groups" {
  description = "Configuration map for EKS node group"
  type = map(
    object({
      instance_types = list(string)
      capacity_type  = string

      scaling_config = object({
        desired_size = number
        max_size     = number
        min_size     = number
      })
    })
  )
}
