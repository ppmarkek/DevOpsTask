# Install Argo CD into the current kubectl context
# Usage: .\scripts\argocd-install.ps1 -Context kind-wp-dev

param(
    [Parameter(Mandatory = $true)]
    [string]$Context
)

$ErrorActionPreference = "Stop"

Write-Host "==> Using context: $Context"
kubectl config use-context $Context

Write-Host "==> Creating namespace argocd..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

Write-Host "==> Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host "==> Waiting for Argo CD server..."
kubectl wait --namespace argocd `
    --for=condition=available deployment/argocd-server `
    --timeout=300s

Write-Host ""
Write-Host "Argo CD installed."
Write-Host "UI: kubectl port-forward svc/argocd-server -n argocd 9090:443 --context $Context"
Write-Host "    https://localhost:9090  (user: admin)"
