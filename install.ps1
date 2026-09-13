# VesktopCustomCommands (VCC) - Windows Installer
# Run in PowerShell: powershell -ExecutionPolicy Bypass -File .\install.ps1
# Or one-liner: irm https://raw.githubusercontent.com/NitramO-YT/vesktopCustomCommands/main/install.ps1 | iex

param (
    [switch]$Silent,
    [switch]$Yes,
    [string]$CustomVencordPath
)

$ErrorActionPreference = "Stop"

$RepoBase = "https://raw.githubusercontent.com/NitramO-YT/vesktopCustomCommands/main"
$RepoDist = "$RepoBase/dist"
$IsLocal = $PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "dist\vencord\customCode.js"))

function Write-VccHeader {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "   vesktopCustomCommands (VCC) for Windows   " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
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

function Get-FileContentOrDownload {
    param(
        [string]$RelativePath
    )
    if ($IsLocal) {
        $localPath = Join-Path $PSScriptRoot $RelativePath
        if (Test-Path $localPath) {
            return [System.IO.File]::ReadAllText($localPath)
        }
    }
    $url = "$RepoBase/$($RelativePath -replace '\\', '/')"
    return (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
}

function Copy-OrDownloadFile {
    param(
        [string]$RelativePath,
        [string]$DestinationPath
    )
    $destDir = Split-Path $DestinationPath -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if ($IsLocal) {
        $localPath = Join-Path $PSScriptRoot $RelativePath
        if (Test-Path $localPath) {
            Copy-Item -Path $localPath -Destination $DestinationPath -Force
            return
        }
    }
    $url = "$RepoBase/$($RelativePath -replace '\\', '/')"
    Invoke-WebRequest -Uri $url -OutFile $DestinationPath -UseBasicParsing
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
    } else {
        Write-Host "Please start Vesktop manually to apply the changes." -ForegroundColor Yellow
    }
}

Write-VccHeader

if (-not (Prompt-Choice "Do you want to install vesktopCustomCommands?")) {
    Write-Host "Installation cancelled." -ForegroundColor Yellow
    exit 0
}

# 1. Determine Vencord Path
$DefaultVencord = "$env:APPDATA\vesktop\sessionData\vencordFiles"
$FallbackVencord = "$env:APPDATA\Vencord\dist"

$VencordPath = $DefaultVencord
if ($CustomVencordPath) {
    $VencordPath = $CustomVencordPath
} elseif (-not (Test-Path $DefaultVencord) -and (Test-Path $FallbackVencord)) {
    $VencordPath = $FallbackVencord
}

if (-not $Silent -and -not $Yes) {
    $confirmPath = Prompt-Choice "Is the path of Vencord/Vesktop: `"$VencordPath`"?" "y"
    if (-not $confirmPath) {
        $userPath = Read-Host "Please enter the path to your Vencord directory"
        if (-not [string]::IsNullOrWhiteSpace($userPath)) {
            $VencordPath = $userPath.Trim('"').Trim("'")
        }
    }
}

if ($VencordPath -like '~*') {
    $VencordPath = $VencordPath -replace '^[~][\\/]', "$env:USERPROFILE\"
}
$VencordPath = [System.Environment]::ExpandEnvironmentVariables($VencordPath)

if (-not (Test-Path $VencordPath)) {
    Write-Host "Creating directory: $VencordPath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $VencordPath -Force | Out-Null
}

$mainFile = Join-Path $VencordPath "vencordDesktopMain.js"

# 2. Check for main file existence
if (-not (Test-Path $mainFile)) {
    Write-Warning "The main file 'vencordDesktopMain.js' does not exist in: $VencordPath"
    if (Prompt-Choice "Do you want to launch Vesktop to allow it to create the files automatically?") {
        $exe = Detect-VesktopExe
        if ($exe) {
            Write-Host "Starting Vesktop..." -ForegroundColor Cyan
            $proc = Start-Process -FilePath $exe -PassThru
            Start-Sleep -Seconds 6
            Write-Host "Stopping Vesktop..." -ForegroundColor Cyan
            Get-Process -Name vesktop -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }
    }
    if (-not (Test-Path $mainFile)) {
        Write-Error "Error: vencordDesktopMain.js not found. Please start Vesktop at least once, then run this installer again."
        exit 1
    }
}

# 3. Patching vencordDesktopMain.js
Write-Host "Checking vencordDesktopMain.js..." -ForegroundColor Cyan
$mainContent = [System.IO.File]::ReadAllText($mainFile)

if ($mainContent -match '\[VesktopCustomCommands\]') {
    Write-Host "The main file is already patched. Skipping injection." -ForegroundColor Green
} else {
    Write-Host "Making a backup of vencordDesktopMain.js..." -ForegroundColor Cyan
    $backupFile = "$mainFile.bak"
    if (-not (Test-Path $backupFile)) {
        Copy-Item -Path $mainFile -Destination $backupFile -Force
    }

    Write-Host "Injecting VesktopCustomCommands code..." -ForegroundColor Cyan
    $injectionSnippet = Get-FileContentOrDownload "dist\vencord\vencordDesktopMain_sample.js"
    $injectionSnippet = $injectionSnippet.Trim()

    if ($mainContent -match '//# sourceURL=') {
        $patchedContent = $mainContent -replace '//# sourceURL=', ($injectionSnippet + '//# sourceURL=')
        [System.IO.File]::WriteAllText($mainFile, $patchedContent)
        Write-Host "vencordDesktopMain.js patched successfully!" -ForegroundColor Green
    } else {
        Write-Error "Error: Source map marker '//# sourceURL=' not found in vencordDesktopMain.js."
        exit 1
    }
}

# 4. Deploy customCode.js to Vencord path
$vccVencordDir = Join-Path $VencordPath "vesktopCustomCommands"
$customCodeDest = Join-Path $vccVencordDir "customCode.js"
Write-Host "Deploying customCode.js to $customCodeDest..." -ForegroundColor Cyan
Copy-OrDownloadFile "dist\vencord\customCode.js" $customCodeDest
Write-Host "customCode.js deployed successfully." -ForegroundColor Green

# 5. Deploy scripts to $env:USERPROFILE\.vesktopCustomCommands
$vccHome = "$env:USERPROFILE\.vesktopCustomCommands"
if (-not (Test-Path $vccHome)) {
    New-Item -ItemType Directory -Path $vccHome -Force | Out-Null
}

$filesToDeploy = @(
    "mute.bat",
    "deafen.bat",
    "mute.vbs",
    "deafen.vbs",
    "mute.ps1",
    "deafen.ps1",
    "vesktopShortcuts.ahk",
    "vcc-autorepatch.ps1",
    "enable_autorepatch.ps1",
    "disable_autorepatch.ps1",
    "enable_autorestart.ps1",
    "disable_autorestart.ps1",
    "enable_autoupdate.ps1",
    "disable_autoupdate.ps1"
)

foreach ($file in $filesToDeploy) {
    Copy-OrDownloadFile "dist\vesktopCustomCommands\$file" (Join-Path $vccHome $file)
}
Write-Host "Scripts deployed to $vccHome" -ForegroundColor Green

# 6. Configure .config file
$configFile = Join-Path $vccHome ".config"
$autoRepatch = "false"
$autoRestart = "false"
$autoUpdate  = "false"
$repatchInterval = "1m"

if (Test-Path $configFile) {
    Get-Content $configFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -match '^auto_repatch=["'']?(.*?)["'']?$') { $autoRepatch = $matches[1] }
        if ($line -match '^auto_restart=["'']?(.*?)["'']?$') { $autoRestart = $matches[1] }
        if ($line -match '^auto_update=["'']?(.*?)["'']?$') { $autoUpdate = $matches[1] }
    }
}

# 7. Ask for Auto-repatch & Auto-update
if (-not $Silent -and -not $Yes) {
    Write-Host ""
    if (Prompt-Choice "Do you want to enable automatic repatch (checks and re-applies if removed by an update)?") {
        $autoRepatch = "true"
        if (Prompt-Choice "Do you also want to enable auto-restart of Vesktop after a repatch?") {
            $autoRestart = "true"
        }
    }
    if (Prompt-Choice "Do you want to enable automatic updates (fetches latest VCC files from GitHub)?") {
        $autoUpdate = "true"
    }
}

# Write config
$configContent = @"
# VesktopCustomCommands Configuration
vencord_path="$VencordPath"
auto_repatch="$autoRepatch"
auto_restart="$autoRestart"
autorepatch_interval="$repatchInterval"
auto_update="$autoUpdate"
"@
[System.IO.File]::WriteAllText($configFile, $configContent)
Write-Host "Configuration saved to $configFile" -ForegroundColor Green

# 8. Setup Task Scheduler if auto-repatch or auto-update enabled
$TaskName = "VesktopCustomCommands-AutoRepatch"
if ($autoRepatch -eq "true" -or $autoUpdate -eq "true") {
    $script = Join-Path $vccHome "vcc-autorepatch.ps1"
    $action = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
    schtasks.exe /Create /TN "$TaskName" /TR "$action" /SC MINUTE /MO 1 /F | Out-Null
    Write-Host "Windows Scheduled Task '$TaskName' registered." -ForegroundColor Green
} else {
    cmd.exe /c "schtasks.exe /Delete /TN ""$TaskName"" /F >NUL 2>&1"
}

# 9. Offer restart
Write-Host ""
$runningProcs = Get-Process -Name vesktop -ErrorAction SilentlyContinue
if ($runningProcs) {
    if (Prompt-Choice "Vesktop is currently running. Do you want to restart it now to apply changes?") {
        Restart-Vesktop
    } else {
        Write-Host "Please restart Vesktop manually to apply changes." -ForegroundColor Yellow
    }
} else {
    if (Prompt-Choice "Vesktop is not running. Do you want to start it now?") {
        $exe = Detect-VesktopExe
        if ($exe -and (Test-Path $exe)) {
            Start-Process -FilePath $exe
            Write-Host "Vesktop started." -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "     Installation completed successfully!    " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "How to configure your shortcuts on Windows:" -ForegroundColor Cyan
Write-Host "1. Silent triggers (recommended, 0-flash):" -ForegroundColor White
Write-Host "   Mute:   wscript.exe //B //Nologo `"$vccHome\mute.vbs`"" -ForegroundColor Gray
Write-Host "   Deafen: wscript.exe //B //Nologo `"$vccHome\deafen.vbs`"" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Batch triggers (for Stream Deck / Macro keys):" -ForegroundColor White
Write-Host "   Mute:   `"$vccHome\mute.bat`"" -ForegroundColor Gray
Write-Host "   Deafen: `"$vccHome\deafen.bat`"" -ForegroundColor Gray
Write-Host ""
Write-Host "3. AutoHotkey users (ready-to-use):" -ForegroundColor White
Write-Host "   Run `"$vccHome\vesktopShortcuts.ahk`" (Ctrl+Shift+M / Ctrl+Shift+D)" -ForegroundColor Gray
Write-Host ""
