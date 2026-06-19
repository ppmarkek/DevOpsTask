#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="wp-dev"
RELEASE_NAME="wp-dev"
KUBE_CONTEXT="kind-${CLUSTER_NAME}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHART_DIR="$ROOT_DIR/helm/wordpress"
IMAGE_NAME="wordpress-devops:dev"

echo "==> Building Docker image..."
docker build -t "$IMAGE_NAME" -f "$ROOT_DIR/docker/Dockerfile" "$ROOT_DIR"

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "==> Creating kind cluster..."
  kind create cluster --name "$CLUSTER_NAME" --config "$ROOT_DIR/scripts/kind-config-dev.yaml"
else
  echo "==> Kind cluster '$CLUSTER_NAME' already exists."
fi

kubectl config use-context "$KUBE_CONTEXT"

echo "==> Loading image into kind..."
kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"

echo "==> Installing ingress-nginx..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

bash "$ROOT_DIR/scripts/install-kind-rwx.sh"

if helm status "$RELEASE_NAME" &>/dev/null; then
  helm upgrade "$RELEASE_NAME" "$CHART_DIR" -f "$CHART_DIR/values-dev.yaml"
else
  helm install "$RELEASE_NAME" "$CHART_DIR" -f "$CHART_DIR/values-dev.yaml"
fi

kubectl get pods
kubectl get ingress

echo ""
echo "Browser: http://dev.wordpress.local:8081"
echo "Run add-hosts.ps1 as Administrator first."
