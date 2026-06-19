# Install Argo CD and Argo CD Image Updater into the current kubectl context
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

Write-Host "==> Installing Argo CD Image Updater..."
helm repo add argo https://argoproj.github.io/argo-helm 2>$null
helm repo update argo

if ($env:GHCR_TOKEN) {
    $ghcrUser = if ($env:GHCR_USERNAME) { $env:GHCR_USERNAME } else { "ppmarkek" }
    Write-Host "==> Creating GHCR pull secret in argocd and default namespaces..."
    kubectl create secret docker-registry ghcr-credentials `
        -n argocd `
        --docker-server=ghcr.io `
        --docker-username=$ghcrUser `
        --docker-password=$env:GHCR_TOKEN `
        --dry-run=client -o yaml | kubectl apply -f -

    kubectl create secret docker-registry ghcr-credentials `
        -n default `
        --docker-server=ghcr.io `
        --docker-username=$ghcrUser `
        --docker-password=$env:GHCR_TOKEN `
        --dry-run=client -o yaml | kubectl apply -f -
}

helm upgrade --install argocd-image-updater argo/argocd-image-updater `
    --namespace argocd `
    --set config.log.level=info `
    --set config.registries[0].name=ghcr `
    --set config.registries[0].api_url=https://ghcr.io `
    --set config.registries[0].prefix=ghcr.io `
    --set config.registries[0].default=true `
    $(if ($env:GHCR_TOKEN) { "--set config.registries[0].credentials=pullsecret:argocd/ghcr-credentials" }) `
    --wait --timeout 5m

Write-Host ""
Write-Host "Argo CD + Image Updater installed."
Write-Host "UI: kubectl port-forward svc/argocd-server -n argocd 9090:443 --context $Context"
Write-Host "    https://localhost:9090  (user: admin)"
Write-Host ""
Write-Host "Optional: configure Git write-back for Image Updater:"
Write-Host "  `$env:GITHUB_TOKEN = '<pat-with-repo-scope>'"
Write-Host "  .\scripts\argocd-configure-git-writeback.ps1 -Context $Context"
