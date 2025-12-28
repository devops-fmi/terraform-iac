#!/bin/bash

set -e

echo "Updating kubeconfig to point to EKS cluster..."
aws eks update-kubeconfig --region eu-central-1 --name elibrary-fmi-devops-eks-cluster
echo ""

echo "Creating ArgoCD namespace"
kubectl create namespace argocd
echo ""

echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
