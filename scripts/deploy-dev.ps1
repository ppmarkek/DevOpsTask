# Deploy latest CI image to dev (local fallback without self-hosted runner)
# Usage:
#   .\scripts\deploy-dev.ps1
#   .\scripts\deploy-dev.ps1 -Tag "dev-abc1234" -Repo "ghcr.io/USER/DevOpsTask/wordpress"

param(
    [string]$Tag = "develop",
    [string]$Repo = "",
    [switch]$UseLocalImage
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ChartDir = Join-Path $RootDir "helm\wordpress"
$ReleaseName = "wp-dev"
$KubeContext = "kind-wp-dev"

kubectl config use-context $KubeContext

if ($UseLocalImage) {
    $Repo = "wordpress-devops"
    $Tag = "dev"
    $PullPolicy = "Never"
    Write-Host "==> Deploying local image wordpress-devops:dev"
} elseif ([string]::IsNullOrWhiteSpace($Repo)) {
    Write-Error "Set -Repo ghcr.io/YOUR_USER/DevOpsTask/wordpress or use -UseLocalImage"
    exit 1
} else {
    $PullPolicy = "Always"
    Write-Host "==> Pulling $Repo`:$Tag ..."
    docker pull "${Repo}:${Tag}"
    Write-Host "==> Loading into kind (optional if cluster pulls from GHCR)..."
    kind load docker-image "${Repo}:${Tag}" --name wp-dev 2>$null
}

helm upgrade --install $ReleaseName $ChartDir `
    -f (Join-Path $ChartDir "values-dev.yaml") `
    --set image.repository=$Repo `
    --set image.tag=$Tag `
    --set image.pullPolicy=$PullPolicy

kubectl get pods -l app.kubernetes.io/instance=$ReleaseName
Write-Host ""
Write-Host "Dev: http://dev.wordpress.local:8081"
