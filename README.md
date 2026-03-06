# ImeControl.spoon

Robust IME (Input Method Editor) switching for [Hammerspoon](https://www.hammerspoon.org/). Switch between English and CJK input methods reliably with app-based auto-switching and system recovery.

## ✨ Features

- 🎯 **Reliable IME Switching**: JIS keycodes + macOS APIs for robust switching
- 🔄 **App-Based Auto-Switch**: Auto-switch IME for specific applications via `appRules`
- 💾 **System Recovery**: Monitors and restores IME state on wake/unlock
- 🪟 **Focus Tracking**: Refreshes IME state when switching windows
- ⚙️ **Customizable**: Timing adjustments, fallback mechanisms, optional alerts
- 🔑 **Optional Hotkeys**: Manual IME toggle and debug info keybindings

## 📦 Installation

Install [Hammerspoon](https://www.hammerspoon.org/) first if you haven't:

```bash
brew install --cask hammerspoon
```

Download [ImeControl.spoon.zip](https://github.com/masaki39/hammerspoon-ime-control/raw/main/Spoons/ImeControl.spoon.zip), open it to install, and add to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("ImeControl")
spoon.ImeControl:start({
    -- All settings optional; defaults shown
    sources = {
        eng = "com.apple.keylayout.ABC",            -- default
        jpn = "com.google.inputmethod.Japanese.base" -- default
    },
    appRules = {
        -- ["com.apple.Terminal"] = "eng",
    }
}):bindHotkeys({
    toggle = { {"shift"}, "f12" },
    debug  = { {"shift"}, "f11" },
})
```

<details>
<summary>🚀 Via SpoonInstall</summary>

Download [SpoonInstall.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/main/Spoons/SpoonInstall.spoon.zip) and open it to install if you haven't.

Add to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.repos.imecontrol = {
    url = "https://github.com/masaki39/hammerspoon-ime-control",
    desc = "ImeControl Spoon repository",
    branch = "main",
}
spoon.SpoonInstall:andUse("ImeControl", {
    repo = "imecontrol",
    config = {
        sources = {
            eng = "com.apple.keylayout.ABC",            -- default
            jpn = "com.google.inputmethod.Japanese.base" -- default
        },
        appRules = {
            -- ["com.apple.Terminal"] = "eng",
        }
    },
    hotkeys = {
        toggle = { {"shift"}, "f12" },
        debug  = { {"shift"}, "f11" },
    },
    start = true,
})
```

</details>

## 🔍 Finding App Bundle IDs

To use `appRules`, you need each app's bundle identifier. Run in Terminal:

```bash
osascript -e 'id of app "Terminal"'
# => com.apple.Terminal
```

Common examples:

| App | Bundle ID |
|-----|-----------|
| Terminal | `com.apple.Terminal` |
| iTerm2 | `com.googlecode.iterm2` |
| VS Code | `com.microsoft.VSCode` |
| Xcode | `com.apple.dt.Xcode` |

## 🏷️ Version Management (for developers)

Use `version.sh` to bump the version, regenerate the zip, and commit + tag in one step:

```bash
chmod +x version.sh   # first time only
./version.sh patch    # patch bump (default)
./version.sh minor    # minor bump
./version.sh major    # major bump
```

Then push:

```bash
git push && git push --tags
```

## License

This software is released under the **Unlicense** (Public Domain). You are free to use, modify, and distribute it for any purpose.
