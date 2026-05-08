$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class GdiFont {
    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern int AddFontResource(string lpszFilename);
}
"@

$srcDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$sysDir = "$env:windir\Fonts"

Copy-Item -Path "$srcDir\JetBrainsMonoNerdFont-*.ttf" -Destination $sysDir -Force

$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
$ttfs = Get-ChildItem $sysDir -Filter "JetBrainsMonoNerdFont-*.ttf"
foreach ($f in $ttfs) {
    $fc = New-Object System.Drawing.Text.PrivateFontCollection
    $fc.AddFontFile($f.FullName)
    $family = $fc.Families[0].Name
    $fc.Dispose()
    Set-ItemProperty -Path $regPath -Name "$family (TrueType)" -Value $f.Name -Force
    Write-Host "Registered: $family"
    [GdiFont]::AddFontResource($f.FullName) | Out-Null
}

net stop FontCache 2>$null; net start FontCache
Write-Host "`nFonts installed system-wide!" -ForegroundColor Green
