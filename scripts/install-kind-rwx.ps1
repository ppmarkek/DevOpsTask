# RWX storage for kind (step 2.3) — reliable on Docker Desktop
# Usage: .\scripts\install-kind-rwx.ps1

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Applying local RWX storage (hostPath on kind node)..."
kubectl apply -f (Join-Path $RootDir "kind-rwx-storage.yaml")

Write-Host ""
kubectl get storageclass local-rwx
kubectl get pv wp-uploads-pv
Write-Host ""
Write-Host "Done. Use persistence.storageClass=local-rwx in values-local.yaml"
