#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="devops-wp"
RELEASE_NAME="wp"
NAMESPACE="default"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHART_DIR="$ROOT_DIR/helm/wordpress"
IMAGE_NAME="wordpress-devops:local"

echo "==> Building Docker image..."
docker build -t "$IMAGE_NAME" -f "$ROOT_DIR/docker/Dockerfile" "$ROOT_DIR"

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "==> Creating kind cluster..."
  kind create cluster --name "$CLUSTER_NAME" --config "$ROOT_DIR/scripts/kind-config.yaml"
else
  echo "==> Kind cluster '$CLUSTER_NAME' already exists."
fi

echo "==> Loading image into kind..."
kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"

echo "==> Installing ingress-nginx (kind manifest)..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "==> Installing shared storage (RWX for kind)..."
bash "$ROOT_DIR/scripts/install-kind-rwx.sh"

echo "==> Updating Helm dependencies..."
helm dependency update "$CHART_DIR"

if helm status "$RELEASE_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo "==> Upgrading WordPress release..."
  helm upgrade "$RELEASE_NAME" "$CHART_DIR" -f "$CHART_DIR/values-local.yaml" -n "$NAMESPACE"
else
  echo "==> Installing WordPress release..."
  helm install "$RELEASE_NAME" "$CHART_DIR" -f "$CHART_DIR/values-local.yaml" -n "$NAMESPACE"
fi

echo ""
echo "==> Waiting for pods..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance="$RELEASE_NAME" --timeout=300s 2>/dev/null || true
kubectl get pods
kubectl get ingress

echo ""
echo "============================================"
echo " Local environment is up!"
echo ""
echo " 1. Add to hosts (admin):"
echo "    127.0.0.1 wordpress.local"
echo "    Windows: run scripts/add-hosts.ps1 as Administrator"
echo ""
echo " 2. Open: http://wordpress.local"
echo "============================================"
