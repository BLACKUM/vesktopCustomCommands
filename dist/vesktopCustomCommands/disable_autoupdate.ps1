# Disable Auto-update for VesktopCustomCommands on Windows
$ErrorActionPreference = "Stop"

$ConfigPath = "$env:USERPROFILE\.vesktopCustomCommands\.config"
if (-not (Test-Path $ConfigPath)) {
    exit 0
}

$content = Get-Content $ConfigPath
if ($content -match '^auto_update=') {
    $content = $content -replace '^auto_update=.*', 'auto_update="false"'
} else {
    $content += 'auto_update="false"'
}
$content | Set-Content $ConfigPath -Encoding UTF8
Write-Host "auto_update set to 'false' in $ConfigPath"

# Check if auto_repatch is still true
$autoRepatch = $false
$content | ForEach-Object {
    if ($_ -match '^auto_repatch="true"') { $autoRepatch = $true }
}

$TaskName = "VesktopCustomCommands-AutoRepatch"
if (-not $autoRepatch) {
    cmd.exe /c "schtasks.exe /Delete /TN ""$TaskName"" /F >NUL 2>&1"
    Write-Host "Scheduled task '$TaskName' removed."
}
