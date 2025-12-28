output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = aws_eks_cluster.main-eks-cluster.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main-eks-cluster.name
}
