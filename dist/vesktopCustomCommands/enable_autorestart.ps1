# Enable Auto-restart for VesktopCustomCommands on Windows
$ErrorActionPreference = "Stop"

$ConfigPath = "$env:USERPROFILE\.vesktopCustomCommands\.config"
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config file not found at $ConfigPath. Please run install.ps1 first."
    exit 1
}

$content = Get-Content $ConfigPath
if ($content -match '^auto_restart=') {
    $content = $content -replace '^auto_restart=.*', 'auto_restart="true"'
} else {
    $content += 'auto_restart="true"'
}
$content | Set-Content $ConfigPath -Encoding UTF8
Write-Host "auto_restart set to 'true' in $ConfigPath"
