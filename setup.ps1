#Requires -Version 7
<#
.SYNOPSIS
    Windows dev environment bootstrap from GabiMotroc/dotfiles.
.DESCRIPTION
    Installs Oh My Posh and lazygit, pulls the custom theme from GitHub
    and puts it in the right place. Run this on any new Windows machine.
.EXAMPLE
    irm https://raw.githubusercontent.com/GabiMotroc/dotfiles/main/windows/setup.ps1 | iex
#>
$ErrorActionPreference = "Stop"
$repoRaw  = "https://raw.githubusercontent.com/GabiMotroc/dotfiles/main"
$themeDest = "$env:USERPROFILE\oh-my-posh\themes\custom.omp.json"
$profileLine = 'oh-my-posh init pwsh --config "$env:USERPROFILE\oh-my-posh\themes\custom.omp.json" | Invoke-Expression'
function Write-Step($msg) {
    Write-Host "`n>> $msg" -ForegroundColor Cyan
}
function Install-WingetPackage($id, $name) {
    Write-Step "Installing $name..."
    $installed = winget list --id $id 2>&1 | Select-String $id
    if ($installed) {
        Write-Host "$name already installed, skipping." -ForegroundColor Yellow
    } else {
        winget install --id $id --silent --accept-package-agreements --accept-source-agreements
        Write-Host "$name installed." -ForegroundColor Green
    }
}
# Install tools
Install-WingetPackage "JanDeDobbeleer.OhMyPosh" "Oh My Posh"
Install-WingetPackage "JesseDuffield.lazygit"    "lazygit"
# Pull and apply oh-my-posh theme
Write-Step "Pulling Oh My Posh theme from dotfiles repo..."
New-Item -ItemType Directory -Path (Split-Path $themeDest) -Force | Out-Null
Invoke-WebRequest "$repoRaw/windows/oh-my-posh/custom.omp.json" -OutFile $themeDest
Write-Host "Theme saved to $themeDest" -ForegroundColor Green
# Add to PowerShell profile if not already there
Write-Step "Updating PowerShell profile..."
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($profileContent -notlike "*oh-my-posh*") {
    Add-Content $PROFILE "`n# === Oh My Posh ===`n$profileLine"
    Write-Host "Added oh-my-posh init to profile." -ForegroundColor Green
} else {
    Write-Host "Profile already has oh-my-posh, skipping." -ForegroundColor Yellow
}
Write-Host "`nDone!" -ForegroundColor Green
Write-Host "Remaining manual step:" -ForegroundColor Cyan
Write-Host "  Install JetBrainsMono NF font from https://www.nerdfonts.com" -ForegroundColor White
Write-Host "  Then set it in Windows Terminal: Settings > PowerShell > Appearance > Font" -ForegroundColor White
Write-Host "`nRestart your terminal to apply changes." -ForegroundColor Cyan
