#Requires AutoHotkey v2.0+
#SingleInstance Force

; VesktopCustomCommands - Global Hotkeys for Windows
; Keybindings:
;   PgUp  -> Toggle Deafen
;   PgDn  -> Toggle Mute
;
; To start automatically on boot:
; Press Win + R, type "shell:startup", and place a shortcut to this script there.

VccDir := EnvGet("USERPROFILE") . "\.vesktopCustomCommands"

PgUp::
{
    Run 'wscript.exe //B //Nologo "' . VccDir . '\deafen.vbs"', , 'Hide'
}

PgDn::
{
    Run 'wscript.exe //B //Nologo "' . VccDir . '\mute.vbs"', , 'Hide'
}
