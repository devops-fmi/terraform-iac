output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = aws_eks_cluster.main-eks-cluster.endpoint
}