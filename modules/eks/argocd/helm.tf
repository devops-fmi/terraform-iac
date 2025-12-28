terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  lifecycle {
    ignore_changes = [metadata[0].labels, metadata[0].annotations]
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  version          = "7.6.1"
  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [kubernetes_namespace.argocd]
}
