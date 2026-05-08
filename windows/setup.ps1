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
# Set PowerShell 7 as the default profile in Windows Terminal
Write-Step "Setting PowerShell 7 as default terminal profile..."
$wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtSettings) {
    $wt = Get-Content $wtSettings -Raw | ConvertFrom-Json
    $pwshProfile = $wt.profiles.list | Where-Object { $_.source -eq "Windows.Terminal.PowershellCore" }
    if ($pwshProfile) {
        if ($wt.defaultProfile -ne $pwshProfile.guid) {
            $wt.defaultProfile = $pwshProfile.guid
            Write-Host "Windows Terminal default set to PowerShell 7." -ForegroundColor Green
        } else {
            Write-Host "Windows Terminal already defaults to PowerShell 7." -ForegroundColor Yellow
        }
        # Set font face to JetBrainsMono Nerd Font if not already set
        $fontChanged = $false
        $profileIndex = [array]::IndexOf($wt.profiles.list.guid, $pwshProfile.guid)
        if ($profileIndex -ge 0) {
            $font = $wt.profiles.list[$profileIndex].font
if (-not $font -or $font.face -ne "JetBrainsMono Nerd Font") {
                if (-not $font) {
                    $wt.profiles.list[$profileIndex] | Add-Member -NotePropertyName "font" -NotePropertyValue @{ face = "JetBrainsMono Nerd Font" } -Force
                } else {
                    $wt.profiles.list[$profileIndex].font.face = "JetBrainsMono Nerd Font"
                }
                $fontChanged = $true
            }
        }
        if ($fontChanged -or $wt.defaultProfile -ne $pwshProfile.guid) {
            $wt | ConvertTo-Json -Depth 10 | Set-Content $wtSettings
            if ($fontChanged) { Write-Host "Font set to JetBrainsMono Nerd Font." -ForegroundColor Green }
        } else {
            Write-Host "Font already set to JetBrainsMono Nerd Font." -ForegroundColor Yellow
        }
    } else {
        Write-Host "PowerShell 7 profile not found in Windows Terminal. Restart Windows Terminal once then re-run." -ForegroundColor Yellow
    }
} else {
    Write-Host "Windows Terminal settings not found, skipping." -ForegroundColor Yellow
}

# Install JetBrainsMono Nerd Font
Write-Step "Installing JetBrainsMono Nerd Font..."
$fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
$fontZip = "$env:TEMP\JetBrainsMono.zip"
$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
if (-not (Test-Path "$fontDir\JetBrainsMonoNerdFont-Regular.ttf")) {
    Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip -UseBasicParsing
    Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force
    Remove-Item $fontZip
    Write-Host "JetBrainsMono NF downloaded." -ForegroundColor Green
} else {
    Write-Host "JetBrainsMono NF already downloaded, skipping." -ForegroundColor Yellow
}

# Install to system font directory (elevated) so DirectWrite picks it up
$sysFontDir = "$env:windir\Fonts"
if (-not (Test-Path "$sysFontDir\JetBrainsMonoNerdFont-Regular.ttf")) {
    $elevatedScript = Join-Path $PSScriptRoot "install-fonts-elevated.ps1"
    $task = Register-ScheduledTask -TaskName "InstallJetBrainsFonts" `
        -Action (New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$elevatedScript`"") `
        -RunLevel Highest -User $env:USERNAME -Force -ErrorAction SilentlyContinue
    if ($task) {
        Start-ScheduledTask -TaskName "InstallJetBrainsFonts"
        Start-Sleep -Seconds 10
        Unregister-ScheduledTask -TaskName "InstallJetBrainsFonts" -Confirm:$false
    }
}
if (Test-Path "$sysFontDir\JetBrainsMonoNerdFont-Regular.ttf") {
    Write-Host "JetBrainsMono NF installed system-wide." -ForegroundColor Green
} else {
    Write-Host "Could not install system-wide. The font is available per-user; restart may be needed." -ForegroundColor Yellow
}

Write-Host "`nDone! Restart Windows Terminal to apply changes." -ForegroundColor Green
