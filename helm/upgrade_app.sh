#!/bin/bash

NAMESPACE="helm-otel-demo"

# Simulating the updates to configuration or application code

# Updating the replica count for the frontend-proxy
helm upgrade --install $NAMESPACE open-telemetry/opentelemetry-demo --namespace $NAMESPACE \
--set components.frontend-proxy.replicas=3 \
--set components.frontend.replicas=2 \
--values values_file.yaml \
--wait --timeout 3m


# Wait for the pods to be in a running state
kubectl wait --for=condition=Ready pods --all -n $NAMESPACE --timeout=180s

# Check the update history
echo "Update history for the release:"
helm history $NAMESPACE -n $NAMESPACE



# Check if the deployment was successful (Run test cases to verify successful deployment)



# Rolling back to the previous stable version
helm rollback $NAMESPACE $(helm history $NAMESPACE -n $NAMESPACE --output json | jq '.[-2].revision') -n $NAMESPACE
