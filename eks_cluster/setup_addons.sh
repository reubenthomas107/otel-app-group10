#!/bin/bash

CLUSTER_NAME="otel-app-cluster"
CLUSTER_REGION=us-east-1
CLUSTER_VPC=$(aws eks describe-cluster --name $CLUSTER_NAME --region $CLUSTER_REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)

# Add the EKS Helm chart repository
helm repo add eks https://aws.github.io/eks-charts

# Update the EKS Helm repository to the latest version
helm repo update eks

# Install the AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
--namespace kube-system \
--set clusterName=${CLUSTER_NAME} \
--set serviceAccount.create=false \
--set region=${CLUSTER_REGION} \
--set vpcId=${CLUSTER_VPC} \
--set serviceAccount.name=aws-load-balancer-controller


# TODO: Install the AWS CloudWatch Container Insights