# Deploy latest CI image to prod (local fallback)
# Usage:
#   .\scripts\deploy-prod.ps1 -Repo "ghcr.io/USER/DevOpsTask/wordpress" -Tag "main"

param(
    [string]$Tag = "main",
    [string]$Repo = "",
    [switch]$UseLocalImage
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ChartDir = Join-Path $RootDir "helm\wordpress"
$ReleaseName = "wp-prod"
$KubeContext = "kind-wp-prod"

kubectl config use-context $KubeContext

if ($UseLocalImage) {
    $Repo = "wordpress-devops"
    $Tag = "prod"
    $PullPolicy = "Never"
} elseif ([string]::IsNullOrWhiteSpace($Repo)) {
    Write-Error "Set -Repo ghcr.io/YOUR_USER/DevOpsTask/wordpress or use -UseLocalImage"
    exit 1
} else {
    $PullPolicy = "Always"
    docker pull "${Repo}:${Tag}"
    kind load docker-image "${Repo}:${Tag}" --name wp-prod 2>$null
}

helm upgrade --install $ReleaseName $ChartDir `
    -f (Join-Path $ChartDir "values-prod.yaml") `
    --set image.repository=$Repo `
    --set image.tag=$Tag `
    --set image.pullPolicy=$PullPolicy

kubectl get pods,hpa,pdb -l app.kubernetes.io/instance=$ReleaseName
Write-Host ""
Write-Host "Prod: http://prod.wordpress.local:8082"
