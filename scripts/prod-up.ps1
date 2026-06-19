# Prod environment (Windows PowerShell)
# Usage: .\scripts\prod-up.ps1

$ErrorActionPreference = "Stop"

$ClusterName = "wp-prod"
$ReleaseName = "wp-prod"
$KubeContext = "kind-$ClusterName"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ChartDir = Join-Path $RootDir "helm\wordpress"
$ImageName = "wordpress-devops:prod"

Write-Host "==> Building Docker image..."
docker build -t $ImageName -f (Join-Path $RootDir "docker\Dockerfile") $RootDir

$clusters = kind get clusters 2>$null
if ($clusters -notcontains $ClusterName) {
    Write-Host "==> Creating kind cluster '$ClusterName'..."
    kind create cluster --name $ClusterName --config (Join-Path $RootDir "scripts\kind-config-prod.yaml")
} else {
    Write-Host "==> Kind cluster '$ClusterName' already exists."
}

kubectl config use-context $KubeContext

Write-Host "==> Loading image into kind..."
kind load docker-image $ImageName --name $ClusterName

Write-Host "==> Installing ingress-nginx..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx `
    --for=condition=ready pod `
    --selector=app.kubernetes.io/component=controller `
    --timeout=120s

Write-Host "==> Installing shared storage (RWX)..."
& (Join-Path $RootDir "scripts\install-kind-rwx.ps1")

Write-Host "==> Bootstrapping database credentials..."
& (Join-Path $RootDir "scripts\bootstrap-secrets.ps1") -SecretName "wp-prod-db-credentials" -Context $KubeContext

Write-Host "==> Helm install/upgrade..."
$releaseExists = helm list -n default -q 2>$null | Where-Object { $_ -eq $ReleaseName }
$helmArgs = @(
    $ReleaseName, $ChartDir,
    "-f", (Join-Path $ChartDir "values-prod.yaml"),
    "--set", "image.repository=wordpress-devops",
    "--set", "image.tag=prod",
    "--set", "image.pullPolicy=Never",
    "--set-json", "image.pullSecrets=[]"
)
if ($releaseExists) {
    helm upgrade @helmArgs
} else {
    helm install @helmArgs
}

Write-Host ""
kubectl get pods
kubectl get hpa
kubectl get pdb
kubectl get ingress

Write-Host ""
Write-Host "============================================"
Write-Host " Prod environment is up!"
Write-Host ""
Write-Host " 1. Hosts (Administrator): .\scripts\add-hosts.ps1"
Write-Host " 2. Browser: http://prod.wordpress.local:8082"
Write-Host "============================================"
