#Requires -Version 7
<#
.SYNOPSIS
    Windows dev environment setup script.
.DESCRIPTION
    Installs: Oh My Posh, lazygit
    Copies oh-my-posh theme to correct location.
    Run from the root of the dotfiles repo.
#>
$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
function Write-Step($msg) {
    Write-Host "`n>> $msg" -ForegroundColor Cyan
}
function Install-WingetPackage($id, $name) {
    Write-Step "Installing $name..."
    $installed = winget list --id $id 2>$null | Select-String $id
    if ($installed) {
        Write-Host "$name already installed, skipping." -ForegroundColor Yellow
    } else {
        winget install --id $id --silent --accept-package-agreements --accept-source-agreements
    }
}
# Install tools
Install-WingetPackage "JanDeDobbeleer.OhMyPosh" "Oh My Posh"
Install-WingetPackage "JesseDuffield.lazygit"    "lazygit"
# Copy oh-my-posh theme
Write-Step "Copying Oh My Posh theme..."
$themeSource = Join-Path $scriptDir "windows\oh-my-posh\custom.omp.json"
$themeDest   = Join-Path $env:USERPROFILE "oh-my-posh\themes\custom.omp.json"
New-Item -ItemType Directory -Path (Split-Path $themeDest) -Force | Out-Null
Copy-Item -Path $themeSource -Destination $themeDest -Force
Write-Host "Theme copied to $themeDest" -ForegroundColor Green
Write-Host "`nDone!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Install JetBrainsMono NF font from https://www.nerdfonts.com" -ForegroundColor White
Write-Host "  2. Add to your PowerShell profile:" -ForegroundColor White
Write-Host '     oh-my-posh init pwsh --config "$env:USERPROFILE\oh-my-posh\themes\custom.omp.json" | Invoke-Expression' -ForegroundColor Gray