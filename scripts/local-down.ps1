# Stop local environment (Windows PowerShell)
# Usage: .\scripts\local-down.ps1

$ClusterName = "devops-wp"
$ReleaseName = "wp"

Write-Host "==> Uninstalling Helm release..."
helm uninstall $ReleaseName 2>$null

Write-Host "==> Deleting kind cluster..."
kind delete cluster --name $ClusterName 2>$null

Write-Host "==> Done."
