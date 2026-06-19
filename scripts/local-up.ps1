# Local environment — Windows PowerShell
# Usage: .\scripts\local-up.ps1

$ErrorActionPreference = "Stop"

$ClusterName = "devops-wp"
$ReleaseName = "wp"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ChartDir = Join-Path $RootDir "helm\wordpress"
$ImageName = "wordpress-devops:local"

Write-Host "==> Building Docker image..."
docker build -t $ImageName -f (Join-Path $RootDir "docker\Dockerfile") $RootDir

$clusters = kind get clusters 2>$null
if ($clusters -notcontains $ClusterName) {
    Write-Host "==> Creating kind cluster..."
    kind create cluster --name $ClusterName --config (Join-Path $RootDir "scripts\kind-config.yaml")
} else {
    Write-Host "==> Kind cluster '$ClusterName' already exists."
}

Write-Host "==> Loading image into kind..."
kind load docker-image $ImageName --name $ClusterName

Write-Host "==> Installing ingress-nginx..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx `
    --for=condition=ready pod `
    --selector=app.kubernetes.io/component=controller `
    --timeout=120s

Write-Host "==> Installing shared storage (RWX for kind)..."
& (Join-Path $RootDir "scripts\install-kind-rwx.ps1")

Write-Host "==> Helm install/upgrade..."
helm dependency update $ChartDir
$status = helm status $ReleaseName 2>$null
if ($LASTEXITCODE -eq 0) {
    helm upgrade $ReleaseName $ChartDir -f (Join-Path $ChartDir "values-local.yaml")
} else {
    helm install $ReleaseName $ChartDir -f (Join-Path $ChartDir "values-local.yaml")
}

Write-Host ""
kubectl get pods
kubectl get ingress

Write-Host ""
Write-Host "============================================"
Write-Host " Next steps:"
Write-Host " 1. Open NEW PowerShell AS ADMINISTRATOR:"
Write-Host "    cd G:\DevOpsTask"
Write-Host "    .\scripts\add-hosts.ps1"
Write-Host ""
Write-Host " 2. Browser: http://wordpress.local"
Write-Host "    (no port-forward needed if kind-config ports work)"
Write-Host "============================================"
