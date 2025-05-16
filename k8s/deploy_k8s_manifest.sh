#!/bin/bash

K8S_NAMESPACE="otel-demo"

#cd /home/ec2-user
#git clone https://github.com/open-telemetry/opentelemetry-demo.git
#kubectl create --namespace $K8S_NAMESPACE -f opentelemetry-demo/kubernetes/opentelemetry-demo.yaml

kubectl create --namespace $K8S_NAMESPACE -f manifests/opentelemetry-demo.yaml
kubectl create --namespace $K8S_NAMESPACE -f manifests/ingress.yaml
kubectl create --namespace $K8S_NAMESPACE -f manifests/hpa.yaml

kubectl wait --for=condition=Ready pods --all -n $K8S_NAMESPACE --timeout=180s