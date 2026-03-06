# ImeControl.spoon

A Hammerspoon Spoon for robust IME (Input Method Editor) switching on macOS, optimized for users who frequently switch between English and CJK (Chinese, Japanese, Korean) input methods.

## Features

- **Reliable IME Switching**: Uses a combination of JIS keycodes and macOS APIs to ensure IME state is properly applied
- **App-Based Auto-Switch**: Automatically switch IME when specific applications are focused via `appRules`
- **Watchdog & System Recovery**: Monitors and automatically restores IME state on system wake or screen unlock
- **Focus Tracking**: Refreshes IME state when switching between windows
- **Customizable Behavior**: Supports timing adjustments, fallback mechanisms, and optional visual alerts
- **Hotkey Support**: Optional keybindings for manual IME toggle and debug info

## Installation

### Option 1: Via SpoonInstall

<details>
<summary>🚀 Using SpoonInstall (Recommended)</summary>

Add this to your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.repos.imecontrol = {
    url = "https://github.com/masaki39/hammerspoon-ime-control",
    desc = "ImeControl Spoon repository",
    branch = "main",
}
spoon.SpoonInstall:andUse("ImeControl", {
    repo = "imecontrol",
    start = true,
})
```

</details>

### Option 2: Manual Installation

1. **Install Hammerspoon**: Download and install [Hammerspoon](https://www.hammerspoon.org/).
2. **Download the Spoon**:
   - Download `Spoons/ImeControl.spoon.zip` from the latest release
   - Extract to `~/.hammerspoon/Spoons/`

   Or clone the repository:
   ```bash
   git clone https://github.com/masaki39/hammerspoon-ime-control.git ~/.hammerspoon/Spoons/ImeControl.spoon
   ```
3. **Reload Configuration**: Reload Hammerspoon configuration from the menu bar.

## Quick Start

Add the following to your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("ImeControl")
spoon.ImeControl:start()
```

## Configuration

### Basic Setup

```lua
hs.loadSpoon("ImeControl")

spoon.ImeControl:start({
    -- Customize input sources (optional)
    sources = {
        eng = "com.apple.keylayout.ABC",
        jpn = "com.google.inputmethod.Japanese.base"
    },

    -- Auto-switch IME for specific apps
    appRules = {
        ["com.apple.Terminal"] = "eng",
        ["com.googlecode.iterm2"] = "eng",
        ["com.apple.Safari"] = "jpn",
    },

    -- Customize behavior
    behavior = {
        showAlert = true,
        alertDuration = 0.5
    }
})
```

### Enable Hotkeys

```lua
spoon.ImeControl:bindHotkeys({
    toggle = { {"shift"}, "f12" },  -- Toggle IME
    debug  = { {"shift"}, "f11" },  -- Show debug info
})
```

### Configuration Options

Key options you may want to customize:

- **sources**: Customize the bundle IDs for your IME methods (eng/jpn)
- **appRules**: Define IME preferences for specific applications
- **behavior.showAlert**: Show visual confirmation when toggling (default: true)
- **behavior.alertDuration**: Duration of the alert (default: 0.5 seconds)

## Common Setup Examples

### For macOS Standard Japanese Input

```lua
spoon.ImeControl:start({
    sources = {
        eng = "com.apple.keylayout.ABC",
        jpn = "com.apple.inputmethod.Kotoeri.Roman"
    }
})
```

### For Terminal-Heavy Workflow

```lua
spoon.ImeControl:start({
    appRules = {
        ["com.apple.Terminal"] = "eng",
        ["com.googlecode.iterm2"] = "eng",
        ["com.microsoft.VSCode"] = "eng",
    }
})
```

## License

This software is released under the **Unlicense** (Public Domain). You are free to use, modify, and distribute it for any purpose.
