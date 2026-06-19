# Local fallback deploy WITHOUT Argo CD (manual testing only).
# WARNING: If Argo CD is bootstrapped with selfHeal enabled, direct helm upgrade
# will be reverted on the next Argo sync. Use Git push + Image Updater instead.
#
# Usage:
#   .\scripts\deploy-dev.ps1 -UseLocalImage
#   .\scripts\deploy-dev.ps1 -Repo "ghcr.io/USER/devopstask/wordpress" -Tag "develop"

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

Write-Warning "This script bypasses GitOps. Do not use when Argo CD selfHeal is active."

kubectl config use-context $KubeContext

if ($UseLocalImage) {
    $Repo = "wordpress-devops"
    $Tag = "dev"
    $PullPolicy = "Never"
    $PullSecretsJson = "[]"
    Write-Host "==> Deploying local image wordpress-devops:dev"
} elseif ([string]::IsNullOrWhiteSpace($Repo)) {
    Write-Error "Set -Repo ghcr.io/YOUR_USER/devopstask/wordpress or use -UseLocalImage"
    exit 1
} else {
    $PullPolicy = "Always"
    $PullSecretsJson = '["ghcr-credentials"]'
    Write-Host "==> Pulling $Repo`:$Tag ..."
    docker pull "${Repo}:${Tag}"
    Write-Host "==> Loading into kind (optional if cluster pulls from GHCR)..."
    kind load docker-image "${Repo}:${Tag}" --name wp-dev 2>$null
}

& (Join-Path $RootDir "scripts\bootstrap-secrets.ps1") -SecretName "wp-dev-db-credentials" -Context $KubeContext

helm upgrade --install $ReleaseName $ChartDir `
    -f (Join-Path $ChartDir "values-dev.yaml") `
    --set image.repository=$Repo `
    --set image.tag=$Tag `
    --set image.pullPolicy=$PullPolicy `
    --set-json "image.pullSecrets=$PullSecretsJson"

kubectl get pods -l app.kubernetes.io/instance=$ReleaseName
Write-Host ""
Write-Host "Dev: http://dev.wordpress.local:8081"
