# Enable Auto-repatch for VesktopCustomCommands on Windows
$ErrorActionPreference = "Stop"

$ConfigPath = "$env:USERPROFILE\.vesktopCustomCommands\.config"
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config file not found at $ConfigPath. Please run install.ps1 first."
    exit 1
}

# Update or add auto_repatch in .config
$content = Get-Content $ConfigPath
if ($content -match '^auto_repatch=') {
    $content = $content -replace '^auto_repatch=.*', 'auto_repatch="true"'
} else {
    $content += 'auto_repatch="true"'
}
$content | Set-Content $ConfigPath -Encoding UTF8
Write-Host "auto_repatch set to 'true' in $ConfigPath"

# Register Windows Scheduled Task
$TaskName = "VesktopCustomCommands-AutoRepatch"
$ScriptPath = "$env:USERPROFILE\.vesktopCustomCommands\vcc-autorepatch.ps1"
$Action = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""

# Register via schtasks for maximum compatibility across Windows PowerShell versions
schtasks.exe /Create /TN "$TaskName" /TR "$Action" /SC MINUTE /MO 1 /F | Out-Null
Write-Host "Scheduled task '$TaskName' registered (runs every minute)."

# Run once immediately
& "$ScriptPath"
