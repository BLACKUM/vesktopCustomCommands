[ ![🇫🇷 Français](https://img.shields.io/badge/%F0%9F%87%AB%F0%9F%87%B7-Fran%C3%A7ais-blue) ](README.fr.md) [ ![🇪🇸 Español](https://img.shields.io/badge/%F0%9F%87%AA%F0%9F%87%B8-Espa%C3%B1ol-blue) ](README.es.md) [ ![🇩🇪 Deutsch](https://img.shields.io/badge/%F0%9F%87%A9%F0%9F%87%AA-Deutsch-blue) ](README.de.md) [ ![🇮🇹 Italiano](https://img.shields.io/badge/%F0%9F%87%AE%F0%9F%87%B9-Italiano-blue) ](README.it.md) [ ![🇷🇺 Русский](https://img.shields.io/badge/%F0%9F%87%B7%F0%9F%87%BA-%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-blue) ](README.ru.md) [ ![🇯🇵 日本語](https://img.shields.io/badge/%F0%9F%87%AF%F0%9F%87%B5-%E6%97%A5%E6%9C%AC%E8%AA%9E-blue) ](README.ja.md) [ ![🇨🇳 中文](https://img.shields.io/badge/%F0%9F%87%A8%F0%9F%87%B3-%E4%B8%AD%E6%96%87-blue) ](README.zh.md) [ ![🇰🇷 한국어](https://img.shields.io/badge/%F0%9F%87%B0%F0%9F%87%B7-%ED%95%9C%EA%B5%AD%EC%96%B4-blue) ](README.ko.md)

# Introduction to vesktopCustomCommands (VCC)
VCC is a system that allows you to add a mute and deafen global shortcut to Vesktop, it is a workaround to the lack of global shortcuts in Vesktop for now and until a better solution is found by the Vesktop team.
It's basically a set of scripts (`mute.sh` & `deafen.sh`) that you can call from a custom global shortcut in your system to mute and deafen yourself in Vesktop, and it triggers theses actions in Vesktop by injecting a custom Javascript code in the Vencord main file.

# Shortcuts configuration in your system

### Linux
Configure a custom global shortcut in your system (desktop environment settings, sxhkd, sway/hyprland bind, etc.) to call the scripts in `~/.vesktopCustomCommands/`:
```plaintext
~/.vesktopCustomCommands/mute.sh
~/.vesktopCustomCommands/deafen.sh
```

### Windows
Choose whichever method fits your setup:

1. **Silent Triggers (Recommended, zero console flashing / instant)**
   Configure your macro keys, Elgato Stream Deck, or Windows shortcut keys to run:
   ```cmd
   wscript.exe //B //Nologo "%USERPROFILE%\.vesktopCustomCommands\mute.vbs"
   wscript.exe //B //Nologo "%USERPROFILE%\.vesktopCustomCommands\deafen.vbs"
   ```

2. **AutoHotkey (Ready-to-use global keybindings)**
   Run `%USERPROFILE%\.vesktopCustomCommands\vesktopShortcuts.ahk`:
   - `Ctrl + Shift + M` -> Toggle Mute
   - `Ctrl + Shift + D` -> Toggle Deafen
   *(Tip: Place a shortcut to `vesktopShortcuts.ahk` in `shell:startup` to run on boot!)*

3. **Batch Files (For Stream Deck, Razer Synapse, Logitech G Hub, Corsair iCUE)**
   ```cmd
   "%USERPROFILE%\.vesktopCustomCommands\mute.bat"
   "%USERPROFILE%\.vesktopCustomCommands\deafen.bat"
   ```

---

# Installation

## Automatic installation

### Linux
Run this command in your terminal and follow the instructions:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/NitramO-YT/vesktopCustomCommands/refs/heads/main/install.sh)"
```

### Windows
Open PowerShell and run:
```powershell
irm https://raw.githubusercontent.com/NitramO-YT/vesktopCustomCommands/main/install.ps1 | iex
```
*(Or locally from cloned repo: `powershell -ExecutionPolicy Bypass -File .\install.ps1`)*

Note: If a config file already exists at `~/.vesktopCustomCommands/.config` (Linux) or `%USERPROFILE%\.vesktopCustomCommands\.config` (Windows), the installer preserves it and only updates the `vencord_path` entry if necessary.

### Optional: Automatic repatch

During installation, you can enable an automatic repatch system that periodically checks whether the VCC patch is still present in the Vencord main file and re-applies it if it has been removed (e.g. after an update or a reset of Vencord/Vesktop).

- Why is it needed? Vesktop/Vencord updates or certain startup scenarios can restore the main file to its original state, removing the VCC injection. The auto-repatch ensures your shortcuts keep working without manual intervention.
- Settings are stored in `.config`:
  - `auto_repatch="true|false"` (default: `false`)
  - `auto_restart="true|false"` (default: `false`) – if enabled, Vesktop will be automatically restarted after a repatch. You can toggle this later with the commands below.
  - `autorepatch_interval="30s|1m|3m"` (default: `30s` on Linux, `1m` on Windows) – interval of checks.
  - On Linux: A user `systemd` timer runs at the chosen interval.
  - On Windows: A scheduled task `VesktopCustomCommands-AutoRepatch` runs automatically.
  - To enable auto-repatch :
    - Linux:
      ```bash
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/NitramO-YT/vesktopCustomCommands/refs/heads/main/dist/vesktopCustomCommands/enable_autorepatch.sh)"
      ```
    - Windows:
      ```powershell
      powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.vesktopCustomCommands\enable_autorepatch.ps1"
      ```
  - To disable auto-repatch :
    - Linux:
      ```bash
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/NitramO-YT/vesktopCustomCommands/refs/heads/main/dist/vesktopCustomCommands/disable_autorepatch.sh)"
      ```
    - Windows:
      ```powershell
      powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.vesktopCustomCommands\disable_autorepatch.ps1"
      ```

  - To enable auto-restart (after repatch):
    - Linux: `enable_autorestart.sh`
    - Windows: `enable_autorestart.ps1`
  - To disable auto-restart:
    - Linux: `disable_autorestart.sh`
    - Windows: `disable_autorestart.ps1`

Manual configuration: edit `.config` and set `auto_repatch` and `auto_restart`.

### Optional: Automatic update

You can enable an automatic update system that periodically checks if a newer version is available on GitHub and updates the necessary files.

- Settings in `.config`:
  - `auto_update="true|false"` (default: `false`)
- To enable auto-update:
  - Linux: `enable_autoupdate.sh`
  - Windows: `enable_autoupdate.ps1`
- To disable auto-update:
  - Linux: `disable_autoupdate.sh`
  - Windows: `disable_autoupdate.ps1`

## Manual installation

### Linux
1. Download the `dist` folder from the repository.
2. Inject `dist/vencord/vencordDesktopMain_sample.js` into your `vencordDesktopMain.js` (usually `~/.config/Vencord/dist/vencordDesktopMain.js` or in `~/.config/vesktop/sessionData/vencordFiles/`) right before `//# sourceURL=`.
3. Create folder `vesktopCustomCommands` in your Vencord directory and place `dist/vencord/customCode.js` inside.
4. Create folder `~/.vesktopCustomCommands`, place `mute.sh`, `deafen.sh`, and `.config` inside, and make them executable (`chmod +x`).
5. Restart Vesktop.

### Windows
1. Download the `dist` folder from the repository.
2. Locate `vencordDesktopMain.js` (typically at `%APPDATA%\vesktop\sessionData\vencordFiles\vencordDesktopMain.js`).
3. Inject the content of `dist/vencord/vencordDesktopMain_sample.js` right before `//# sourceURL=` at the end of `vencordDesktopMain.js`.
4. Create a folder `vesktopCustomCommands` in that directory and copy `dist/vencord/customCode.js` into it.
5. Create `%USERPROFILE%\.vesktopCustomCommands` and copy the Windows scripts (`mute.bat`, `deafen.bat`, `mute.vbs`, `deafen.vbs`, `vesktopShortcuts.ahk`, `.config`) into it.
6. Restart Vesktop.

---

# Uninstallation

## Automatic uninstallation

### Linux
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/NitramO-YT/vesktopCustomCommands/refs/heads/main/uninstall.sh)"
```

### Windows
```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```
During uninstallation, you'll be asked whether you want to remove EVERYTHING, including your settings (`~/.vesktopCustomCommands/.config`).
- Answer "y": all files and settings are removed.
- Answer "n": only program files are removed; your `.config` is preserved.

If settings are removed, the auto-repatch service/timer and helper scripts are also removed. If you refuse automatic uninstallation, follow the manual uninstallation steps below (the same instructions are also echoed by the script).

## Manual uninstallation

### Linux
1. Remove the custom global shortcuts in your system that call the scripts `mute.sh` and `deafen.sh` in `~/.vesktopCustomCommands/` folder.
2. Remove the `.config` file in `~/.vesktopCustomCommands`.
3. Remove the `~/.vesktopCustomCommands` folder.
4. Remove the `customCode.js` file in your Vencord path `~/.config/Vencord/dist/vesktopCustomCommands/`.
5. Remove the `vesktopCustomCommands` folder in your Vencord path `~/.config/Vencord/dist/`.
6. Remove the injected code in your Vencord main file (usually located in `~/.config/Vencord/dist/vencordDesktopMain.js`) or replace it with the backup you made if you did. (You can also delete the file and start Vesktop to recreate it).
7. Restart Vesktop to apply the changes.

### Windows
1. Remove any custom shortcuts, macro key binds, or AutoHotkey scripts configured to run `mute.bat` / `mute.vbs` / `deafen.bat` / `deafen.vbs`.
2. Delete the scheduled task if registered: `schtasks /Delete /TN "VesktopCustomCommands-AutoRepatch" /F`.
3. Remove the `%USERPROFILE%\.vesktopCustomCommands` folder.
4. Remove `%APPDATA%\vesktop\sessionData\vencordFiles\vesktopCustomCommands` (or your custom Vencord path).
5. Remove the injected code in `vencordDesktopMain.js` (or restore `vencordDesktopMain.js.bak`).
6. Restart Vesktop.

---

# Issues and improvements

If you have any issues or improvements to suggest, please open an issue!

# Contributions

I know that this system is not perfect and that I have not respected all the standards and semantics, that's why I'm counting on those who would like to help me improve this system, issues and pull requests are open, and I am open to any constructive criticism!

---

# Explanation of the main goal of this project

I was a user used to KDE Neon under X11 and so my Discord worked well, overall, and recently I switched to KDE Neon under Wayland and I discovered that Discord had a lot of problems on it, especially screen sharing was impossible for me, so looking to solve my problems with Discord, I discovered Vesktop and by extension Vencord, and I discovered all the problems it solved and even some that I already had under X11 (like the pure and simple absence of the possibility to share sound during a screen sharing), I installed it and everything was perfect, except for a small detail, the lack of support for Global Keyboard Shortcuts, the only possibility was the default Discord shortcuts (`Ctrl + Shift + M` and `Ctrl + Shift + D`) which only work if the window is active, so I started looking for shortcuts in Vesktop and I could see and read that the problem is known but the solution is still far from being found, especially on Wayland which seems to complicate the life of developers who are looking to make global keyboard shortcuts, so I thought I would give up on it, but like any good developer, I couldn't resign myself, so I thought of a solution, and I found a makeshift but robust solution, I didn't want an unstable system so I tried to make my system as simple and functional as possible, I could have forked Vesktop and worked hard to find a solution or integrate mine, but already I don't have this pretension and time, and moreover I don't think it's serious or healthy to create an alternative repository for people who want global keyboard shortcuts in their Vesktop, so I thought the ideal was to think of it as a mod or an addon that is added on top of the official one, a bit like Vencord itself in the end, that people interested can install it if they need it on their side. that will be enough until Vesktop finds a solution for global keyboard shortcuts!

---

Thank you :)



<!-- Made with ❤️ by NitramO -->