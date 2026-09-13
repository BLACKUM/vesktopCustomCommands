# Disable Auto-restart for VesktopCustomCommands on Windows
$ErrorActionPreference = "Stop"

$ConfigPath = "$env:USERPROFILE\.vesktopCustomCommands\.config"
if (-not (Test-Path $ConfigPath)) {
    exit 0
}

$content = Get-Content $ConfigPath
if ($content -match '^auto_restart=') {
    $content = $content -replace '^auto_restart=.*', 'auto_restart="false"'
} else {
    $content += 'auto_restart="false"'
}
$content | Set-Content $ConfigPath -Encoding UTF8
Write-Host "auto_restart set to 'false' in $ConfigPath"
