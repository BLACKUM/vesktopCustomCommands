@echo off
setlocal enabledelayedexpansion

set "CONFIG_FILE=%USERPROFILE%\.vesktopCustomCommands\.config"
set "DEFAULT_VENCORD=%APPDATA%\vesktop\sessionData\vencordFiles"
set "VENCORD_PATH=%DEFAULT_VENCORD%"

if exist "%CONFIG_FILE%" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
        set "KEY=%%A"
        set "VAL=%%B"
        set "KEY=!KEY: =!"
        if "!KEY!"=="vencord_path" (
            set "VENCORD_PATH=!VAL!"
            set "VENCORD_PATH=!VENCORD_PATH:"=!"
            set "VENCORD_PATH=!VENCORD_PATH:'=!"
        )
    )
)

if "%VENCORD_PATH:~0,2%"=="~\" set "VENCORD_PATH=%USERPROFILE%\%VENCORD_PATH:~2%"
if "%VENCORD_PATH:~0,2%"=="~/" set "VENCORD_PATH=%USERPROFILE%\%VENCORD_PATH:~2%"
set "VENCORD_PATH=%VENCORD_PATH:/=\%"

set "TARGET_DIR=%VENCORD_PATH%\vesktopCustomCommands"
set "MUTE_FILE=%TARGET_DIR%\mute"

tasklist /FI "IMAGENAME eq vesktop.exe" 2>NUL | find /I /N "vesktop.exe" >NUL
if errorlevel 1 (
    echo Error: Vesktop is not running. The 'mute' file will not be created.
    exit /b 1
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%" >NUL 2>&1
type nul > "%MUTE_FILE%"

if exist "%MUTE_FILE%" (
    echo File 'mute' created successfully at: %MUTE_FILE%
    exit /b 0
) else (
    echo Error: Unable to create the 'mute' file.
    exit /b 1
)
