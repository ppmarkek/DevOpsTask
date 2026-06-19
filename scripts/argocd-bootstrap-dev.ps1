# Bootstrap GitOps for dev cluster (kind-wp-dev)
# Usage: .\scripts\argocd-bootstrap-dev.ps1

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Context = "kind-wp-dev"

& (Join-Path $RootDir "scripts\argocd-install.ps1") -Context $Context

Write-Host "==> Applying Argo CD Application (wp-dev)..."
kubectl apply -f (Join-Path $RootDir "argocd\applications\dev.yaml")

Write-Host "==> Waiting for initial sync..."
Start-Sleep -Seconds 15
kubectl get applications -n argocd
kubectl get pods -l app.kubernetes.io/instance=wp-dev 2>$null

$secret = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
if ($secret) {
    $password = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($secret))
    Write-Host ""
    Write-Host "============================================"
    Write-Host " Argo CD Dev ready"
    Write-Host " UI:     kubectl port-forward svc/argocd-server -n argocd 9090:443 --context $Context"
    Write-Host " URL:    https://localhost:9090"
    Write-Host " Login:  admin / $password"
    Write-Host " Site:   http://dev.wordpress.local:8081"
    Write-Host ""
    Write-Host " GitOps: push to 'develop' -> Argo syncs wp-dev"
    Write-Host "============================================"
}
