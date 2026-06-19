# Run PowerShell AS ADMINISTRATOR:
#   Set-ExecutionPolicy Bypass -Scope Process -Force; .\scripts\add-hosts.ps1

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

$entries = @(
    "127.0.0.1 wordpress.local",
    "127.0.0.1 dev.wordpress.local",
    "127.0.0.1 prod.wordpress.local"
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run this script as Administrator (right-click PowerShell -> Run as administrator)."
    exit 1
}

foreach ($entry in $entries) {
    $hostname = ($entry -split '\s+')[1]
    if (Select-String -Path $hostsPath -Pattern "\s$([regex]::Escape($hostname))(\s|$)" -Quiet) {
        Write-Host "Already exists: $entry"
    } else {
        Add-Content -Path $hostsPath -Value $entry
        Write-Host "Added: $entry"
    }
}

Write-Host ""
Write-Host "Open in browser:"
Write-Host "  Local: http://wordpress.local"
Write-Host "  Dev:   http://dev.wordpress.local:8081"
Write-Host "  Prod:  http://prod.wordpress.local:8082"
