# Configure Argo CD Image Updater to write image tag changes back to Git.
# Requires a GitHub PAT with repo write access (classic: repo scope; fine-grained: contents write).
#
# Usage:
#   $env:GITHUB_TOKEN = "ghp_..."
#   .\scripts\argocd-configure-git-writeback.ps1 -Context kind-wp-dev

param(
    [Parameter(Mandatory = $true)]
    [string]$Context,

    [string]$GitToken = $env:GITHUB_TOKEN,
    [string]$GitUser = "argocd-image-updater",
    [string]$GitEmail = "argocd-image-updater@users.noreply.github.com"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($GitToken)) {
    Write-Error "Set GITHUB_TOKEN environment variable or pass -GitToken (PAT with repo write access)."
    exit 1
}

kubectl config use-context $Context

Write-Host "==> Creating Git credentials secret in argocd namespace..."
kubectl create secret generic git-creds `
    -n argocd `
    --from-literal=username=$GitUser `
    --from-literal=password=$GitToken `
    --dry-run=client -o yaml | kubectl apply -f -

Write-Host "==> Patching argocd-image-updater ConfigMap..."
$patchJson = @"
{"data":{"git.user":"$GitUser","git.email":"$GitEmail","git.credentials":"secret:argocd/git-creds#username,secret:argocd/git-creds#password"}}
"@
kubectl patch configmap argocd-image-updater-config -n argocd --type merge -p $patchJson

Write-Host "==> Restarting Image Updater..."
kubectl rollout restart deployment argocd-image-updater-controller -n argocd 2>$null
kubectl rollout restart deployment argocd-image-updater -n argocd 2>$null

Write-Host ""
Write-Host "Git write-back configured. Image Updater will commit tag changes to the repo branch configured on each Application."
