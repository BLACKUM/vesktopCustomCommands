' VesktopCustomCommands - Silent Mute Trigger
Option Explicit

Dim fso, shell, userProfile, appData, configFile, defaultVencord, vencordPath
Dim file, line, parts, key, val, targetDir, muteFile, procs

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

' Check if Vesktop is running
Set procs = GetObject("winmgmts:").ExecQuery("Select ProcessId from Win32_Process Where Name = 'vesktop.exe'")
If procs.Count = 0 Then
    WScript.Quit 1
End If

userProfile = shell.ExpandEnvironmentStrings("%USERPROFILE%")
appData = shell.ExpandEnvironmentStrings("%APPDATA%")
configFile = userProfile & "\.vesktopCustomCommands\.config"
defaultVencord = appData & "\vesktop\sessionData\vencordFiles"
vencordPath = defaultVencord

If fso.FileExists(configFile) Then
    Set file = fso.OpenTextFile(configFile, 1)
    Do Until file.AtEndOfStream
        line = Trim(file.ReadLine)
        If InStr(line, "=") > 0 And Left(line, 1) <> "#" Then
            parts = Split(line, "=", 2)
            key = Trim(parts(0))
            If key = "vencord_path" Then
                val = Trim(parts(1))
                val = Replace(val, Chr(34), "")
                val = Replace(val, "'", "")
                If Left(val, 2) = "~\" Or Left(val, 2) = "~/" Then
                    val = userProfile & Mid(val, 2)
                End If
                val = Replace(val, "/", "\")
                vencordPath = shell.ExpandEnvironmentStrings(val)
            End If
        End If
    Loop
    file.Close
End If

targetDir = vencordPath & "\vesktopCustomCommands"
muteFile = targetDir & "\mute"

If Not fso.FolderExists(targetDir) Then
    fso.CreateFolder(targetDir)
End If

fso.CreateTextFile(muteFile, True).Close
