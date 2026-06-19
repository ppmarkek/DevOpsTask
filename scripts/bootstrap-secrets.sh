#!/usr/bin/env bash
# Create database credentials Secret in the cluster (not stored in Git).
# Usage: ./scripts/bootstrap-secrets.sh wp-dev-db-credentials [context]

set -euo pipefail

SECRET_NAME="${1:?Secret name required, e.g. wp-dev-db-credentials}"
CONTEXT="${2:-}"
NAMESPACE="${3:-default}"
FORCE="${FORCE:-}"

if [[ -n "$CONTEXT" ]]; then
  kubectl config use-context "$CONTEXT"
fi

if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null && [[ -z "$FORCE" ]]; then
  echo "Secret '$SECRET_NAME' already exists (set FORCE=1 to recreate)."
  exit 0
fi

if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null; then
  kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE"
fi

ROOT_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"
WP_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"

echo "==> Creating Secret '$SECRET_NAME' in namespace '$NAMESPACE'..."
kubectl create secret generic "$SECRET_NAME" \
  -n "$NAMESPACE" \
  --from-literal=mariadb-root-password="$ROOT_PASSWORD" \
  --from-literal=mariadb-password="$WP_PASSWORD" \
  --from-literal=db-password="$WP_PASSWORD"

echo "Done. Set standaloneMariadb.existingSecret: $SECRET_NAME in Helm values."
