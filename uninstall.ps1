# VesktopCustomCommands (VCC) - Windows Uninstaller
# Run in PowerShell: powershell -ExecutionPolicy Bypass -File .\uninstall.ps1

param (
    [switch]$Silent,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

function Write-VccHeader {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host "  vesktopCustomCommands (VCC) - Uninstaller  " -ForegroundColor Red
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host ""
}

function Prompt-Choice {
    param(
        [string]$Message,
        [string]$Default = "y"
    )
    if ($Silent -or $Yes) { return $true }
    $suffix = if ($Default -eq "y") { "[Y/n]" } else { "[y/N]" }
    $reply = Read-Host "$Message $suffix"
    if ([string]::IsNullOrWhiteSpace($reply)) {
        return ($Default -eq "y")
    }
    return ($reply -match '^[Yy]')
}

function Detect-VesktopExe {
    $proc = Get-Process -Name vesktop -ErrorAction SilentlyContinue
    if ($proc -and $proc[0].Path) {
        return $proc[0].Path
    }
    $defaultExe = "$env:LOCALAPPDATA\vesktop\vesktop.exe"
    if (Test-Path $defaultExe) {
        return $defaultExe
    }
    return ""
}

function Restart-Vesktop {
    $exePath = Detect-VesktopExe
    $procs = Get-Process -Name vesktop -ErrorAction SilentlyContinue
    if ($procs) {
        Write-Host "Closing Vesktop..." -ForegroundColor Yellow
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    if ($exePath -and (Test-Path $exePath)) {
        Write-Host "Starting Vesktop from $exePath..." -ForegroundColor Green
        Start-Process -FilePath $exePath
        Write-Host "Vesktop was restarted successfully." -ForegroundColor Green
    }
}

Write-VccHeader

if (-not (Prompt-Choice "Do you really want to uninstall vesktopCustomCommands?")) {
    Write-Host "Uninstallation cancelled." -ForegroundColor Yellow
    exit 0
}

# 1. Read config
$vccHome = "$env:USERPROFILE\.vesktopCustomCommands"
$configFile = Join-Path $vccHome ".config"
$vencordPath = "$env:APPDATA\vesktop\sessionData\vencordFiles"

if (Test-Path $configFile) {
    Get-Content $configFile | ForEach-Object {
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

# 2. Restore vencordDesktopMain.js
$mainFile = Join-Path $vencordPath "vencordDesktopMain.js"
$backupFile = "$mainFile.bak"

if (Test-Path $backupFile) {
    Write-Host "Restoring vencordDesktopMain.js from backup..." -ForegroundColor Cyan
    Copy-Item -Path $backupFile -Destination $mainFile -Force
    Remove-Item -Path $backupFile -Force -ErrorAction SilentlyContinue
    Write-Host "Backup restored successfully." -ForegroundColor Green
} elseif (Test-Path $mainFile) {
    Write-Host "Removing VCC injection from vencordDesktopMain.js..." -ForegroundColor Cyan
    $content = [System.IO.File]::ReadAllText($mainFile)
    $pattern = '/\* === VesktopCustomCommands Injection === \*/[\s\S]*?/\* === End VesktopCustomCommands === \*/'
    if ($content -match $pattern) {
        $cleanedContent = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, '')
        [System.IO.File]::WriteAllText($mainFile, $cleanedContent)
        Write-Host "Injection removed from vencordDesktopMain.js." -ForegroundColor Green
    }
}

# 3. Remove customCode directory in Vencord path
$vccDir = Join-Path $vencordPath "vesktopCustomCommands"
if (Test-Path $vccDir) {
    Write-Host "Removing $vccDir..." -ForegroundColor Cyan
    Remove-Item -Path $vccDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed VCC folder from Vencord directory." -ForegroundColor Green
}

# 4. Remove Scheduled Task
$TaskName = "VesktopCustomCommands-AutoRepatch"
Write-Host "Removing scheduled task '$TaskName' if present..." -ForegroundColor Cyan
cmd.exe /c "schtasks.exe /Delete /TN ""$TaskName"" /F >NUL 2>&1"

# 5. Remove ~/.vesktopCustomCommands directory
if (Test-Path $vccHome) {
    Write-Host "Removing $vccHome..." -ForegroundColor Cyan
    Remove-Item -Path $vccHome -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed VCC user profile directory." -ForegroundColor Green
}

# 6. Offer to restart Vesktop
$runningProcs = Get-Process -Name vesktop -ErrorAction SilentlyContinue
if ($runningProcs) {
    if (Prompt-Choice "Vesktop is currently running. Do you want to restart it now to complete uninstallation?") {
        Restart-Vesktop
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "    Uninstallation completed successfully!   " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
