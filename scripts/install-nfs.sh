#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Deploying NFS server..."
kubectl apply -f "$ROOT_DIR/nfs-server.yaml"
kubectl wait --for=condition=ready pod -l role=nfs-server --timeout=120s

echo "==> Installing NFS provisioner (storageClass: nfs-client)..."
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ 2>/dev/null || true
helm repo update

helm upgrade --install nfs-subdir-external-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace nfs-provisioner --create-namespace \
  --set nfs.server=nfs-server.default.svc.cluster.local \
  --set nfs.path=/exports \
  --set storageClass.name=nfs-client \
  --set storageClass.defaultClass=false

kubectl get storageclass
