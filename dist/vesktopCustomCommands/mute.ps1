# VesktopCustomCommands - Mute trigger
$configPath = "$env:USERPROFILE\.vesktopCustomCommands\.config"
$defaultPath = "$env:APPDATA\vesktop\sessionData\vencordFiles"
$vencordPath = $defaultPath

if (Test-Path $configPath) {
    Get-Content $configPath | ForEach-Object {
        $line = $_.Trim()
        if ($line -match '^vencord_path\s*=\s*["'']?(.*?)["'']?$') {
            $val = $matches[1]
            if ($val -like '~*') {
                $val = $val -replace '^[~][\\/]', "$env:USERPROFILE\"
            }
            $vencordPath = [System.Environment]::ExpandEnvironmentVariables($val)
        }
    }
}

$proc = Get-Process -Name vesktop -ErrorAction SilentlyContinue
if (-not $proc) {
    Write-Error "Error: Vesktop is not running. The 'mute' file will not be created."
    exit 1
}

$targetDir = Join-Path $vencordPath "vesktopCustomCommands"
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$muteFile = Join-Path $targetDir "mute"
New-Item -ItemType File -Path $muteFile -Force | Out-Null
Write-Host "File 'mute' created successfully at: $muteFile"
