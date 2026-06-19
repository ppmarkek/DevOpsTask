# Local fallback deploy WITHOUT Argo CD (manual testing only).
# WARNING: If Argo CD is bootstrapped with selfHeal enabled, direct helm upgrade
# will be reverted on the next Argo sync. Use Git push + Image Updater instead.
#
# Usage:
#   .\scripts\deploy-prod.ps1 -UseLocalImage
#   .\scripts\deploy-prod.ps1 -Repo "ghcr.io/USER/devopstask/wordpress" -Tag "main"

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

Write-Warning "This script bypasses GitOps. Do not use when Argo CD selfHeal is active."

kubectl config use-context $KubeContext

if ($UseLocalImage) {
    $Repo = "wordpress-devops"
    $Tag = "prod"
    $PullPolicy = "Never"
    $PullSecretsJson = "[]"
} elseif ([string]::IsNullOrWhiteSpace($Repo)) {
    Write-Error "Set -Repo ghcr.io/YOUR_USER/devopstask/wordpress or use -UseLocalImage"
    exit 1
} else {
    $PullPolicy = "Always"
    $PullSecretsJson = '["ghcr-credentials"]'
    docker pull "${Repo}:${Tag}"
    kind load docker-image "${Repo}:${Tag}" --name wp-prod 2>$null
}

& (Join-Path $RootDir "scripts\bootstrap-secrets.ps1") -SecretName "wp-prod-db-credentials" -Context $KubeContext

helm upgrade --install $ReleaseName $ChartDir `
    -f (Join-Path $ChartDir "values-prod.yaml") `
    --set image.repository=$Repo `
    --set image.tag=$Tag `
    --set image.pullPolicy=$PullPolicy `
    --set-json "image.pullSecrets=$PullSecretsJson"

kubectl get pods,hpa,pdb -l app.kubernetes.io/instance=$ReleaseName
Write-Host ""
Write-Host "Prod: http://prod.wordpress.local:8082"
