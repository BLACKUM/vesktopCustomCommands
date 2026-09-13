# VesktopCustomCommands (VCC) - Auto-repatch & Auto-update for Windows
param (
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$ConfigPath = "$env:USERPROFILE\.vesktopCustomCommands\.config"
if (-not (Test-Path $ConfigPath)) {
    exit 0
}

# Parse config
$config = @{
    vencord_path = "$env:APPDATA\vesktop\sessionData\vencordFiles"
    auto_repatch = "false"
    auto_restart = "false"
    auto_update  = "false"
}

Get-Content $ConfigPath | ForEach-Object {
    $line = $_.Trim()
    if ($line -match '^([a-zA-Z0-9_]+)\s*=\s*["'']?(.*?)["'']?$') {
        $k = $matches[1]
        $v = $matches[2]
        if ($v -like '~*') {
            $v = $v -replace '^[~][\\/]', "$env:USERPROFILE\"
        }
        $config[$k] = [System.Environment]::ExpandEnvironmentVariables($v)
    }
}

$VencordPath = $config["vencord_path"]
$AutoRepatch = $config["auto_repatch"] -eq "true"
$AutoRestart = $config["auto_restart"] -eq "true"
$AutoUpdate  = $config["auto_update"] -eq "true"

$RepoBase = "https://raw.githubusercontent.com/NitramO-YT/vesktopCustomCommands/main"
$SampleUrl = "$RepoBase/dist/vencord/vencordDesktopMain_sample.js"
$CustomCodeUrl = "$RepoBase/dist/vencord/customCode.js"

function Restart-Vesktop {
    $procs = Get-Process -Name vesktop -ErrorAction SilentlyContinue
    if ($procs) {
        $exePath = $procs[0].Path
        if (-not $exePath) {
            $exePath = "$env:LOCALAPPDATA\vesktop\vesktop.exe"
        }
        Write-Host "[VCC] Restarting Vesktop..."
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        if (Test-Path $exePath) {
            Start-Process -FilePath $exePath
            Write-Host "[VCC] Vesktop restarted."
        }
    }
}

# Check Auto-repatch
if ($AutoRepatch -or $Force) {
    $mainFile = Join-Path $VencordPath "vencordDesktopMain.js"
    $vccDir = Join-Path $VencordPath "vesktopCustomCommands"
    $customCodeFile = Join-Path $vccDir "customCode.js"

    if (Test-Path $mainFile) {
        $content = [System.IO.File]::ReadAllText($mainFile)
        if ($content -notmatch '\[VesktopCustomCommands\]') {
            Write-Host "[VCC] VCC patch missing in vencordDesktopMain.js. Re-patching..."
            
            # Ensure customCode.js exists
            if (-not (Test-Path $vccDir)) {
                New-Item -ItemType Directory -Path $vccDir -Force | Out-Null
            }
            if (-not (Test-Path $customCodeFile)) {
                Write-Host "[VCC] Downloading customCode.js..."
                Invoke-WebRequest -Uri $CustomCodeUrl -OutFile $customCodeFile -UseBasicParsing
            }

            # Fetch injection sample
            $injectionCode = (Invoke-WebRequest -Uri $SampleUrl -UseBasicParsing).Content

            # Make backup if not present
            $backupFile = "$mainFile.bak"
            if (-not (Test-Path $backupFile)) {
                Copy-Item -Path $mainFile -Destination $backupFile -Force
            }

            if ($content -match '//# sourceURL=') {
                $patchedContent = $content -replace '//# sourceURL=', ($injectionCode + '//# sourceURL=')
                [System.IO.File]::WriteAllText($mainFile, $patchedContent)
                Write-Host "[VCC] Injection successful!"

                if ($AutoRestart) {
                    Restart-Vesktop
                }
            } else {
                Write-Warning "[VCC] Source map marker '//# sourceURL=' not found. Could not auto-repatch."
            }
        }
    }
}

# Check Auto-update
if ($AutoUpdate) {
    try {
        $vccHome = "$env:USERPROFILE\.vesktopCustomCommands"
        $filesToUpdate = @(
            @{ Remote = "$RepoBase/dist/vesktopCustomCommands/mute.bat"; Local = Join-Path $vccHome "mute.bat" },
            @{ Remote = "$RepoBase/dist/vesktopCustomCommands/deafen.bat"; Local = Join-Path $vccHome "deafen.bat" },
            @{ Remote = "$RepoBase/dist/vesktopCustomCommands/mute.vbs"; Local = Join-Path $vccHome "mute.vbs" },
            @{ Remote = "$RepoBase/dist/vesktopCustomCommands/deafen.vbs"; Local = Join-Path $vccHome "deafen.vbs" },
            @{ Remote = "$RepoBase/dist/vesktopCustomCommands/mute.ps1"; Local = Join-Path $vccHome "mute.ps1" },
            @{ Remote = "$RepoBase/dist/vesktopCustomCommands/deafen.ps1"; Local = Join-Path $vccHome "deafen.ps1" },
            @{ Remote = "$RepoBase/dist/vesktopCustomCommands/vcc-autorepatch.ps1"; Local = Join-Path $vccHome "vcc-autorepatch.ps1" }
        )

        foreach ($f in $filesToUpdate) {
            $remoteContent = (Invoke-WebRequest -Uri $f.Remote -UseBasicParsing).Content
            if (Test-Path $f.Local) {
                $localContent = [System.IO.File]::ReadAllText($f.Local)
                if ($remoteContent -ne $localContent) {
                    [System.IO.File]::WriteAllText($f.Local, $remoteContent)
                    Write-Host "[VCC] Updated $($f.Local)"
                }
            }
        }
    } catch {
        Write-Warning "[VCC] Failed checking for updates: $_"
    }
}
