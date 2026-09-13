# Disable Auto-repatch for VesktopCustomCommands on Windows
$ErrorActionPreference = "Stop"

$ConfigPath = "$env:USERPROFILE\.vesktopCustomCommands\.config"
if (-not (Test-Path $ConfigPath)) {
    exit 0
}

# Update auto_repatch in .config
$content = Get-Content $ConfigPath
if ($content -match '^auto_repatch=') {
    $content = $content -replace '^auto_repatch=.*', 'auto_repatch="false"'
} else {
    $content += 'auto_repatch="false"'
}
$content | Set-Content $ConfigPath -Encoding UTF8
Write-Host "auto_repatch set to 'false' in $ConfigPath"

# Check if auto_update is still true
$autoUpdate = $false
$content | ForEach-Object {
    if ($_ -match '^auto_update="true"') { $autoUpdate = $true }
}

$TaskName = "VesktopCustomCommands-AutoRepatch"
if (-not $autoUpdate) {
    cmd.exe /c "schtasks.exe /Delete /TN ""$TaskName"" /F >NUL 2>&1"
    Write-Host "Scheduled task '$TaskName' removed."
} else {
    Write-Host "Auto-update is still enabled; scheduled task kept active."
}
