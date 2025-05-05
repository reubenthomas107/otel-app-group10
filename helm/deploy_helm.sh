#!/bin/bash

NAMESPACE="helm-otel-demo"

# Add the OpenTelemetry-Demo Helm chart repository
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add jaeger https://jaegertracing.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add opensearch https://opensearch-project.github.io/helm-charts

# Update the Helm repository to the latest version
helm repo update

# Deploy the application using the Helm chart in a different namespace (helm-otel-demo)
helm upgrade --install $NAMESPACE ../opentelemetry-helm-charts/charts/opentelemetry-demo --namespace $NAMESPACE --create-namespace --values values_file.yaml --wait --timeout 3m

# helm upgrade --install $NAMESPACE open-telemetry/opentelemetry-demo --namespace $NAMESPACE --create-namespace --values values_file.yaml --wait --timeout 3m

# Check if the deployment was successful
# if [ $? -eq 0 ]; then
#   echo "Helm chart deployed successfully."
# else
#   echo "Failed to deploy the Helm chart."
#   exit 1
# fi

# Wait for the pods to be in a running state
kubectl wait --for=condition=Ready pods --all -n $NAMESPACE --timeout=180s

#kubectl wait --for=condition=available --timeout=120s deployment/otel-app -n $NAMESPACE

# Check if the pods are running
if kubectl get pods -n $NAMESPACE | grep -q "Running"; then
  echo "All pods are running."
else
  echo "Some pods are not running."
  exit 1
fi

# Details of the Ingress Resource
echo "Details of the Ingress Controller:"
kubectl get ingress -n $NAMESPACE

# Display the status of all resources in the namespace
echo "Displaying the status of all resources in the $NAMESPACE namespace:"
kubectl get all -n $NAMESPACE