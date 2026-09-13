# Enable Auto-update for VesktopCustomCommands on Windows
$ErrorActionPreference = "Stop"

$ConfigPath = "$env:USERPROFILE\.vesktopCustomCommands\.config"
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config file not found at $ConfigPath. Please run install.ps1 first."
    exit 1
}

$content = Get-Content $ConfigPath
if ($content -match '^auto_update=') {
    $content = $content -replace '^auto_update=.*', 'auto_update="true"'
} else {
    $content += 'auto_update="true"'
}
$content | Set-Content $ConfigPath -Encoding UTF8
Write-Host "auto_update set to 'true' in $ConfigPath"

# Ensure Scheduled Task is registered
$TaskName = "VesktopCustomCommands-AutoRepatch"
$ScriptPath = "$env:USERPROFILE\.vesktopCustomCommands\vcc-autorepatch.ps1"
$Action = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
schtasks.exe /Create /TN "$TaskName" /TR "$Action" /SC MINUTE /MO 15 /F | Out-Null
Write-Host "Scheduled task '$TaskName' active."
