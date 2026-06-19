# Run PowerShell AS ADMINISTRATOR:
#   Set-ExecutionPolicy Bypass -Scope Process -Force; .\scripts\add-hosts.ps1

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$entry = "127.0.0.1 wordpress.local"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run this script as Administrator (right-click PowerShell -> Run as administrator)."
    exit 1
}

if (Select-String -Path $hostsPath -Pattern "wordpress\.local" -Quiet) {
    Write-Host "Entry already exists in hosts file."
} else {
    Add-Content -Path $hostsPath -Value $entry
    Write-Host "Added: $entry"
}

Write-Host ""
Write-Host "Open in browser:"
Write-Host "  http://wordpress.local       (if kind ports 80 work)"
Write-Host "  http://wordpress.local:8080  (if using kubectl port-forward)"
