# Stop prod environment — Windows PowerShell
# Usage: .\scripts\prod-down.ps1

$ClusterName = "wp-prod"
$ReleaseName = "wp-prod"
$KubeContext = "kind-$ClusterName"

if (kubectl config get-contexts -o name 2>$null | Select-String -Quiet $KubeContext) {
    kubectl config use-context $KubeContext
    helm uninstall $ReleaseName 2>$null
}

kind delete cluster --name $ClusterName 2>$null
Write-Host "==> Prod cluster removed."
