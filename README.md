# Hanten(反転).spoon

Robust IME (Input Method Editor) switching for [Hammerspoon](https://www.hammerspoon.org/). Switch between English and CJK input methods reliably with app-based auto-switching and system recovery.

## ✨ Features

- 🎯 **Reliable IME Switching**: JIS keycodes + macOS APIs for robust switching
- 🌐 **Default IME**: Set a global default IME that applies to all apps via `defaultIME`
- 🔄 **App-Based Auto-Switch**: Per-app overrides via `appRules` (takes priority over `defaultIME`)
- 💾 **System Recovery**: Monitors and restores IME state on wake/unlock
- 🪟 **Focus Tracking**: Refreshes IME state when switching windows
- ⚙️ **Customizable**: Timing adjustments, fallback mechanisms, optional alerts
- 🔑 **Optional Hotkeys**: Manual IME toggle and debug info keybindings

## 📦 Installation

Install [Hammerspoon](https://www.hammerspoon.org/) first if you haven't:

```bash
brew install --cask hammerspoon
```

Download [Hanten.spoon.zip](https://github.com/masaki39/hanten/raw/main/Spoons/Hanten.spoon.zip), open it to install, and add to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Hanten")
spoon.Hanten:start({
    -- All settings optional; defaults shown
    sources = {
        eng = "com.apple.keylayout.ABC",            -- default
        jpn = "com.google.inputmethod.Japanese.base" -- default
    },
    defaultIME = "eng",  -- always switch to English when changing apps (optional)
    appRules = {
        -- ["com.apple.Terminal"] = "eng",  -- overrides defaultIME for specific apps
        -- ["com.some.jpnapp"]    = "jpn",
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
spoon.SpoonInstall.repos.hanten = {
    url = "https://github.com/masaki39/hanten",
    desc = "Hanten Spoon repository",
    branch = "main",
}
spoon.SpoonInstall:andUse("Hanten", {
    repo = "hanten",
    config = {
        sources = {
            eng = "com.apple.keylayout.ABC",            -- default
            jpn = "com.google.inputmethod.Japanese.base" -- default
        },
        defaultIME = "eng",  -- optional
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

## ⚙️ Additional Settings

All `behavior` options can be passed inside the `start()` config:

```lua
spoon.Hanten:start({
    behavior = {
        -- Alert shown when toggling IME manually
        showAlert = true,
        alertDuration = 0.5,

        -- Enable/disable inputSourceChanged watcher
        useSourceChangedWatcher = true,

        -- Fallback: press a shortcut repeatedly until IME switches
        useShortcutFallback = true,
        sourceSwitchShortcut = {
            mods = {"ctrl"},
            key  = "space",
            delayUS = 50000,
            interval = 0.1,
            maxPresses = 10
        },

        -- Workaround for CJK input method bounce issue
        useCjkBounce = false,

        -- Workaround for Chromium-based browsers (Chrome, Edge, Brave, etc.)
        useChromiumNudge = false,

        -- Retry settings when IME switch fails
        retryInterval = 0.1,
        retryCount = 5,

        -- Timing adjustments (advanced)
        applyDelay = 0.05,
        alertDelay = 0.02,
        keyTapDelay = 0.005,
        justAppliedThreshold = 1.0,
        callDedupeThreshold = 0.2   -- suppress duplicate applyIME calls within this window (seconds)
    }
})
```

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
