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
--set serviceAccount.name=aws-load-balancer-controller \
2>&1 | tee addon_output.log

status=$?
set -e

if grep -q "cannot re-use a name that is still in use" addon_output.log; then
    echo "ALB Helm chart already installed, continuing..."
elif [ $status -eq 0 ]; then
    echo "ALB Helm chart installed successfully"
else
    echo "Helm install failed with unexpected error"
    exit 1
fi


# TODO: Install the AWS CloudWatch Container Insights
eksctl create iamserviceaccount \
--name cloudwatch-agent \
--namespace amazon-cloudwatch \
--cluster ${CLUSTER_NAME} \
--region ${CLUSTER_REGION} \
--role-name aws-cloudwatch-agent \
--attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
--role-only \
--approve

aws eks create-addon \
--addon-name amazon-cloudwatch-observability \
--cluster-name ${CLUSTER_NAME} \
--region ${CLUSTER_REGION} \
--service-account-role-arn arn:aws:iam::619715105204:role/aws-cloudwatch-agent \
2>&1 | tee addon_output.log

status=$?
set -e

if grep -q "already exists." addon_output.log; then
    echo "Add-on already installed, continuing..."
elif [ $status -eq 0 ]; then
    echo "CloudWatch Container Insights installed successfully"
else
    echo "Failed to install CloudWatch Container Insights"
    exit 1
fi