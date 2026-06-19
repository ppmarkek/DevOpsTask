# Stop dev environment (Windows PowerShell)
# Usage: .\scripts\dev-down.ps1

$ClusterName = "wp-dev"
$ReleaseName = "wp-dev"
$KubeContext = "kind-$ClusterName"

if (kubectl config get-contexts -o name 2>$null | Select-String -Quiet $KubeContext) {
    kubectl config use-context $KubeContext
    Write-Host "==> Uninstalling Helm release..."
    helm uninstall $ReleaseName 2>$null
}

Write-Host "==> Deleting kind cluster..."
kind delete cluster --name $ClusterName 2>$null

Write-Host "==> Done. Dev cluster '$ClusterName' removed."
