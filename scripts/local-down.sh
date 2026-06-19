#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="devops-wp"
RELEASE_NAME="wp"

echo "==> Uninstalling Helm release..."
helm uninstall "$RELEASE_NAME" 2>/dev/null || true

echo "==> Deleting kind cluster..."
kind delete cluster --name "$CLUSTER_NAME" 2>/dev/null || true

echo "==> Done. Cluster '$CLUSTER_NAME' removed."
