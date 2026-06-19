# Bootstrap GitOps for prod cluster (kind-wp-prod)
# Usage: .\scripts\argocd-bootstrap-prod.ps1

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Context = "kind-wp-prod"

& (Join-Path $RootDir "scripts\argocd-install.ps1") -Context $Context

Write-Host "==> Bootstrapping database credentials..."
& (Join-Path $RootDir "scripts\bootstrap-secrets.ps1") -SecretName "wp-prod-db-credentials" -Context $Context

Write-Host "==> Applying Argo CD Application (wp-prod)..."
kubectl apply -f (Join-Path $RootDir "argocd\applications\prod.yaml")

Write-Host "==> Waiting for initial sync..."
Start-Sleep -Seconds 15
kubectl get applications -n argocd
kubectl get pods -l app.kubernetes.io/instance=wp-prod 2>$null

$secret = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
if ($secret) {
    $password = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($secret))
    Write-Host ""
    Write-Host "============================================"
    Write-Host " Argo CD Prod ready"
    Write-Host " UI:     kubectl port-forward svc/argocd-server -n argocd 9091:443 --context $Context"
    Write-Host " URL:    https://localhost:9091"
    Write-Host " Login:  admin / $password"
    Write-Host " Site:   http://prod.wordpress.local:8082"
    Write-Host ""
    Write-Host " GitOps: push to 'main' -> CI pushes GHCR -> Image Updater syncs wp-prod"
    Write-Host "============================================"
}
