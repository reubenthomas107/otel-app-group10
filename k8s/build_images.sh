#!/bin/bash

set -euo pipefail

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/opentelemetry-demo"

IMAGE_TAG="latest"

LOCAL_REPO="ghcr.io/open-telemetry/demo"

IMAGE_DIRS=$(find . -mindepth 2 -maxdepth 5 -type f -name Dockerfile | grep -v '/genproto/' | sed 's|^\./||' | xargs -n1 dirname)

echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | sudo docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "$IMAGE_DIRS"

for DIR in $IMAGE_DIRS; do
  if [[ "$DIR" == src/* ]]; then
    IMAGE_NAME=$(echo "$DIR" | sed -n 's|^src/\([^/]*\).*|\1|p')
  else
    IMAGE_NAME=$(echo "$DIR" | sed 's|/|-|g')
  fi

  echo "$IMAGE_NAME"

  if ! aws ecr describe-repositories --repository-names "opentelemetry-demo/$IMAGE_NAME" --region $AWS_REGION >/dev/null 2>&1; then
    echo "Creating ECR repository: $IMAGE_NAME"
    aws ecr create-repository --repository-name "opentelemetry-demo/$IMAGE_NAME" --region $AWS_REGION >/dev/null
  else
    echo "ECR repository $IMAGE_NAME already exists"
  fi

  ECR_IMAGE="${ECR_REPO}/${IMAGE_NAME}:latest"
  LOCAL_IMAGE="${LOCAL_REPO}:latest-${IMAGE_NAME}"

  echo "Building image: $IMAGE_NAME"
  if ! sudo docker compose build "$IMAGE_NAME"; then
    echo "Build failed for $IMAGE_NAME. Skipping..."
    continue
  fi

  echo -e "Pushing image: $IMAGE_NAME \nECR: $ECR_IMAGE"
  sudo docker tag "$LOCAL_IMAGE" "$ECR_IMAGE"

  sudo docker push "$ECR_IMAGE"

  echo "Cleanup Space"
  sudo docker rmi "$LOCAL_IMAGE" "$ECR_IMAGE" || true
  sudo docker builder prune -af

done

echo "All images have been built and pushed to ECR."