<#
.SYNOPSIS
    Windows dev environment bootstrap from GabiMotroc/dotfiles.
.DESCRIPTION
    Installs PowerShell 7, Oh My Posh, and lazygit, then applies
    the custom oh-my-posh theme. Run this on any new Windows machine.
    If running from PowerShell 5.1 it installs pwsh and re-launches itself.
.EXAMPLE
    irm https://raw.githubusercontent.com/GabiMotroc/dotfiles/main/windows/setup.ps1 | iex
#>
$ErrorActionPreference = "Stop"

# Bootstrap: ensure we're running under PowerShell 7+
if ($PSVersionTable.PSEdition -ne 'Core') {
    Write-Host ">> PowerShell 7 required. Installing..." -ForegroundColor Cyan
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if (-not $pwsh) {
        winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
        $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
        if (-not $pwsh) { throw "PowerShell 7 installation failed." }
    }
    & $pwsh.Source -NoProfile -File $MyInvocation.MyCommand.Path
    exit $LASTEXITCODE
}
$localRepo  = "$PSScriptRoot\.."
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
# Copy oh-my-posh theme from local repo
Write-Step "Copying Oh My Posh theme from local repo..."
New-Item -ItemType Directory -Path (Split-Path $themeDest) -Force | Out-Null
Copy-Item -Path "$localRepo\windows\oh-my-posh\custom.omp.json" -Destination $themeDest -Force
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
