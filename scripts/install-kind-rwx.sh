#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$ROOT_DIR/kind-rwx-storage.yaml"
kubectl get storageclass local-rwx
kubectl get pv wp-uploads-pv
