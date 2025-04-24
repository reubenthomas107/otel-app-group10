#!/bin/bash

CLUSTER_NAME="otel-app-cluster"
REGION="us-east-1"

# Check if the cluster already exists
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "EKS cluster '$CLUSTER_NAME' already exists. Skipping creation..."
else
  echo "Creating EKS cluster - '$CLUSTER_NAME'..."
  eksctl create cluster -f ~/eks_cluster/eks_cluster_setup.yaml
fi
