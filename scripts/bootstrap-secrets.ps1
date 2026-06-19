# Create database credentials Secret in the cluster (not stored in Git).
# Usage:
#   .\scripts\bootstrap-secrets.ps1 -SecretName wp-dev-db-credentials
#   .\scripts\bootstrap-secrets.ps1 -SecretName wp-prod-db-credentials -Context kind-wp-prod

param(
    [Parameter(Mandatory = $true)]
    [string]$SecretName,

    [string]$Namespace = "default",
    [string]$Context = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

if ($Context) {
    kubectl config use-context $Context
}

$exists = kubectl get secret $SecretName -n $Namespace -o name 2>$null
if ($exists -and -not $Force) {
    Write-Host "Secret '$SecretName' already exists in namespace '$Namespace' (use -Force to recreate)."
    exit 0
}

if ($exists -and $Force) {
    kubectl delete secret $SecretName -n $Namespace
}

function New-RandomPassword {
    param([int]$Length = 24)
    $bytes = New-Object byte[] $Length
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return [Convert]::ToBase64String($bytes).Substring(0, $Length) -replace '[+/=]', 'x'
}

$rootPassword = New-RandomPassword
$wpPassword = New-RandomPassword

Write-Host "==> Creating Secret '$SecretName' in namespace '$Namespace'..."
kubectl create secret generic $SecretName `
    -n $Namespace `
    --from-literal=mariadb-root-password=$rootPassword `
    --from-literal=mariadb-password=$wpPassword `
    --from-literal=db-password=$wpPassword

Write-Host "Done. Helm values should set standaloneMariadb.existingSecret: $SecretName"
