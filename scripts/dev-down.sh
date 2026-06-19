#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="wp-dev"
RELEASE_NAME="wp-dev"

kubectl config use-context "kind-${CLUSTER_NAME}" 2>/dev/null || true
helm uninstall "$RELEASE_NAME" 2>/dev/null || true
kind delete cluster --name "$CLUSTER_NAME" 2>/dev/null || true

echo "==> Dev cluster removed."
