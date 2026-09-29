# DMS Projector

> **Quick display projection and screen mirroring flyout for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell), inspired by Windows `Win + P`.**

[![DMS Plugin](https://img.shields.io/badge/DMS-Plugin-blue?style=flat-square)](https://danklinux.com/plugins)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Compositor: Hyprland / Wayland](https://img.shields.io/badge/Compositor-Hyprland%20%2F%20Wayland-informational?style=flat-square)](#)

---

## Features

- **PC Screen Only**: Turn off external HDMI/DisplayPort monitors and use only your laptop/primary display.
- **Duplicate (Mirror)**: Clone your desktop across both screens instantly with auto-matching resolutions.
- **Extend**: Spread your workspaces across multiple monitors (supports Right, Left, Above, or Below placement).
- **Second Screen Only**: Turn off your laptop screen and output solely to your TV or projector.
- **Material 3 Flyout UI**: Styled to match DankMaterialShell with active mode badges, smooth hover effects, and crisp Material Symbols.
- **Zero Lag Execution**: Fast, non-blocking asynchronous commands.
- **OSD Notifications**: Optional feedback on display mode switches.
- **Bilingual**: Full support for English and Spanish.

---

## Installation

### Option 1: Via DMS CLI (when published)
```bash
dms plugins install dms-projector
```

### Option 2: Manual Installation
Clone or symlink this repository directly into your DMS plugins directory:
```bash
ln -s /home/osvaldx/Desktop/dev/dms-projector ~/.config/DankMaterialShell/plugins/dmsProjector
```
Then restart or reload DankMaterialShell (`Super + Shift + R` or `killall quickshell && quickshell`).

---

## Global Shortcut Setup (`Super + P`)

To open the projector menu quickly from your keyboard just like in Windows:

### Hyprland (`hyprland.conf`)
Add this keybind to your Hyprland configuration:
```ini
# Open DMS Projector Flyout
bind = $mainMod, P, exec, dms ipc call widget toggle dmsProjector
```

---

## Configuration

Open **DankMaterialShell Settings -> Plugins -> DMS Projector** to configure:

| Setting | Options | Default | Description |
|---|---|---|---|
| **Language** | `Español`, `English` | `Español` | Interface and notification language |
| **Extended Direction** | `Right`, `Left`, `Above`, `Below` | `Right` | Where to place the external screen when extending |
| **Show Notifications** | `true` / `false` | `true` | System OSD toast on projection change |
| **Hide when no external** | `true` / `false` | `false` | Hide bar widget when no HDMI/DP monitor is plugged |
| **Primary Output Override** | Text (e.g. `eDP-1`) | Auto-detect | Manually specify primary screen name |
| **Secondary Output Override** | Text (e.g. `HDMI-A-1`) | Auto-detect | Manually specify external screen name |

---

## License

MIT License (c) 2026 [osvaldx](https://github.com/osvaldx)
