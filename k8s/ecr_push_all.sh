#!/bin/bash

AWS_ACCOUNT_ID=619715105204
AWS_REGION=us-east-1
ECR_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

cd opentelemetry-demo || exit 1

services=$(find . -name Dockerfile | sed 's|^\./||' | sed 's|/Dockerfile||')

for service in $services; do
  IMAGE_NAME=$(echo "$service" | tr '/' '-')
  FULL_TAG="$ECR_URL/$IMAGE_NAME:latest"

  echo "📦 Building and pushing: $service -> $FULL_TAG"

  # Create ECR repo if it doesn't exist
  aws ecr describe-repositories --repository-names "$IMAGE_NAME" --region "$AWS_REGION" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "$IMAGE_NAME" --region "$AWS_REGION"

  # Build and push
  docker build -t "$FULL_TAG" -f "$service/Dockerfile" .
  docker push "$FULL_TAG"

  echo "✅ Done: $FULL_TAG"
done

