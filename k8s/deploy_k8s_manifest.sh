#!/bin/bash

K8S_NAMESPACE="otel-demo"

cd /home/ec2-user
git clone https://github.com/open-telemetry/opentelemetry-demo.git

kubectl create --namespace $K8S_NAMESPACE -f opentelemetry-demo/kubernetes/opentelemetry-demo.yaml