#!/bin/bash

set -euo pipefail

NAMESPACE="helm-otel-demo"
FRONTEND_URL="https://ecapp-group10.velixor.me"

echo "Checking for unhealthy pods in namespace '$NAMESPACE'..."
UNHEALTHY_PODS=()

# Iterate through all pods and inspect container statuses
for pod in $(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
  bad_state=$(kubectl get pod "$pod" -n "$NAMESPACE" -o json | jq -r '
    .status.containerStatuses[]? | select(
      .state.waiting.reason == "CrashLoopBackOff" or
      .state.waiting.reason == "ErrImagePull" or
      .state.waiting.reason == "ImagePullBackOff"
    ) | .state.waiting.reason')

  if [[ -n "$bad_state" ]]; then
    UNHEALTHY_PODS+=("$pod")
    echo "Pod '$pod' is unhealthy: $bad_state"

    echo "Details:"
    kubectl get pod "$pod" -n "$NAMESPACE" -o json | jq -r '
      .status.containerStatuses[] |
      "  Container: \(.name)\n  Image: \(.image)\n  State: \(.state.waiting.reason // "Running")\n"'
    echo ""
  fi
done

if [[ ${#UNHEALTHY_PODS[@]} -gt 0 ]]; then
  echo "Validation failed: ${#UNHEALTHY_PODS[@]} unhealthy pod(s) found."
  exit 1
else
  echo "All pods are healthy."
fi


# Testing the OpenTelemetry Demo Frontend Website
echo -e "\n\nTesting the OpenTelemetry Demo Frontend Website..."

echo "Testing frontend availability at $FRONTEND_URL..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL")

if [[ "$STATUS" -ne 200 ]]; then
  echo "Frontend returned HTTP status $STATUS"
  exit 1
else
  echo "Frontend is reachable with status $STATUS"
fi

# Testing the product API
echo -e "\nTesting Product API..."
STATUS=$(curl -s -X GET "$FRONTEND_URL/api/products/OLJCESPC7Z" -H "Content-Type: application/json" -o /dev/null -w "%{http_code}") 

if [[ "$STATUS" -ne 200 ]]; then
  echo "Product API Failed to load product ID:OLJCESPC7Z; Returned HTTP status $STATUS"
  exit 1
else
  echo "Product API is reachable with status $STATUS"
fi

# Testing the Add to Cart API
echo -e "\nTesting Cart API to simulate a user action..."
STATUS=$(curl -s -X POST "$FRONTEND_URL/api/cart" -H "Content-Type: application/json" \
    -d "{\"item\": {\"productId\": \"OLJCESPC7Z\",\"quantity\": 1 }, \"userId\": \"1\"}" -o /dev/null -w "%{http_code}")

if [[ "$STATUS" -ne 200 ]]; then
  echo "Cart API request failed with status $STATUS"
  exit 1
else
  echo "Cart API request succeeded with status $STATUS"
fi

# Testing the Checkout API
echo -e "\nTesting Checkout API..."
PEOPLE=('{ "email": "larry_sergei@example.com", "address": { "streetAddress": "1600 Amphitheatre Parkway", "zipCode": "94043", "city": "Mountain View", "state": "CA", "country": "United States" }, "userCurrency": "USD", "creditCard": { "creditCardNumber": "4432-8015-6152-0454", "creditCardExpirationMonth": 1, "creditCardExpirationYear": 2039, "creditCardCvv": 672 } }')
CHECKOUT_PAYLOAD=$(echo "${PEOPLE}" | jq --arg userId "1" '. + {userId: $userId}')

STATUS=$(curl -s -X POST "$FRONTEND_URL/api/checkout" \
  -H "Content-Type: application/json" \
  -d "$CHECKOUT_PAYLOAD" -o /dev/null -w "%{http_code}")

if [[ "$STATUS" -ne 200 ]]; then
  echo "Checkout request failed with status: $STATUS"
  exit 1
else
  echo "Checkout API request succeeded with status: $STATUS"
fi


# Testing the Grafana Endpoint
echo -e "\nTesting Grafana endpoint..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL/grafana")
if [[ "$STATUS" -ne 200 ]]; then
  echo "Grafana endpoint request failed with HTTP status: $STATUS"
  exit 1
else
  echo "Grafana endpoint is reachable with status: $STATUS"
fi

# Testing the LoadGenerator Endpoint
echo -e "\nTesting LoadGenerator endpoint..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL/loadgen/")
if [[ "$STATUS" -ne 200 ]]; then
  echo "LoadGenerator endpoint request failed with HTTP status: $STATUS"
  exit 1
else
  echo "LoadGenerator endpoint is reachable with status: $STATUS"
fi


# Testing the Jaeger Endpoint
echo -e "\nTesting Jaeger endpoint..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL/jaeger/ui/")
if [[ "$STATUS" -ne 200 ]]; then
  echo "Jaeger endpoint request failed with HTTP status: $STATUS"
  exit 1
else
  echo "Jaeger endpoint is reachable with status: $STATUS"
fi

# Testing the Feature Flag endpoint
echo -e "\nTesting Flagd Configurator UI endpoint..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL/feature")
if [[ "$STATUS" -ne 200 ]]; then
  echo "Flagd Configurator UI endpoint request failed with HTTP status: $STATUS"
  exit 1
else
  echo "Flagd Configurator UI endpoint is reachable with status: $STATUS"
fi


echo -e "\n\nAll checks passed. Deployment is healthy!"