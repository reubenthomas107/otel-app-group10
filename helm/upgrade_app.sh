#!/bin/bash

NAMESPACE="helm-otel-demo"

echo "Running deploy with run type: $1"
# Simulating the updates to configuration or application code

if [[ "$1" == "upgrade" ]]; then
    echo "Running upgrade..."
    # Simulating the upgrade process
    # Updating the replica count for the frontend-proxy
    helm upgrade --install $NAMESPACE ../opentelemetry-helm-charts/charts/opentelemetry-demo --namespace $NAMESPACE \
    --set components.frontend-proxy.replicas=3 \
    --set components.frontend.replicas=2 \
    --values values_file.yaml \
    --wait --timeout 3m
else
    echo "Running failure simulation..."
    helm upgrade --install $NAMESPACE ../opentelemetry-helm-charts/charts/opentelemetry-demo --namespace $NAMESPACE \
    --set components.frontend-proxy.replicas=3 \
    --set components.frontend.replicas=2 \
    --values values_file.yaml \
    --wait --timeout 3m

    #TODO: Write failure simulation code here - maybe, image pull error
fi


# Wait for the pods to be in a running state
kubectl wait --for=condition=Ready pods --all -n $NAMESPACE --timeout=180s

# Check the update history
echo "Update history for the release:"
helm history $NAMESPACE -n $NAMESPACE


# Check if the deployment was successful (Run test cases to verify successful deployment)
bash /home/ec2-user/tests/test_deployment.sh
STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo "Deployment test cases passed."
else
    echo "Deployment test cases failed, rolling back to the previous stable Helm version...."
    # Rolling back to the previous stable version
    #helm rollback $NAMESPACE $(helm history $NAMESPACE -n $NAMESPACE --output json | jq '.[-2].revision') -n $NAMESPACE
    helm rollback $NAMESPACE 1 -n $NAMESPACE
    echo "Rolled back to the previous stable version."
fi