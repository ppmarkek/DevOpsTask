# Install in-cluster NFS + RWX storage class for kind (step 2.3)
# Usage: .\scripts\install-nfs.ps1

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Deploying NFS server..."
kubectl apply -f (Join-Path $RootDir "nfs-server.yaml")
kubectl wait --for=condition=ready pod -l role=nfs-server --timeout=120s

Write-Host "==> Installing NFS provisioner (storageClass: nfs-client)..."
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ 2>$null
helm repo update

helm upgrade --install nfs-subdir-external-provisioner `
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner `
  --namespace nfs-provisioner --create-namespace `
  --set nfs.server=nfs-server.default.svc.cluster.local `
  --set nfs.path=/exports `
  --set storageClass.name=nfs-client `
  --set storageClass.defaultClass=false

Write-Host ""
Write-Host "==> Storage classes:"
kubectl get storageclass
Write-Host ""
Write-Host "Done. Use persistence.storageClass=nfs-client and accessMode=ReadWriteMany in values-local.yaml"
