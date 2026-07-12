# Hanten(反転).spoon

[日本語版 README はこちら](README.ja.md)

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
        alertLabels = {
            eng = "Aa 英数",     -- label shown when switching to English
            jpn = "🇯🇵 日本語"   -- label shown when switching to the CJK source
        },

        -- Log verbosity: "error", "warning", "info", "debug", or "verbose"
        logLevel = "info",

        -- Enable/disable inputSourceChanged watcher
        useSourceChangedWatcher = true,

        -- Send JIS Eisu/Kana keycodes alongside the API call.
        -- Harmless on ANSI keyboards, but can be disabled if unwanted.
        useJISKeys = true,

        -- Fallback: press a shortcut repeatedly until IME switches.
        -- Set sourceSwitchShortcut to the IME-switching shortcut configured in
        -- macOS (System Settings > Keyboard > Shortcuts > Input Sources).
        useShortcutFallback = true,
        sourceSwitchShortcut = {
            mods = {"ctrl"},
            key  = "space",
            delayUS = 50000,
            interval = 0.1,
            maxPresses = 10
        },

        -- Workaround for the "bounce back" issue where some CJK input methods
        -- revert to English right after switching: bounces jpn -> eng and then
        -- presses sourceSwitchShortcut so the IME lands on jpn reliably.
        -- Enable only if switching to jpn visibly flips back on its own.
        -- When enabled, it replaces useShortcutFallback for the jpn target.
        useCjkBounce = false,

        -- Workaround for Chromium-based browsers (Chrome, Edge, Brave, Arc, etc.)
        -- that ignore IME changes until a keypress: sends a harmless F19 key to
        -- the browser after switching. Enable if the IME indicator changes but
        -- typing still uses the previous input method in these browsers.
        useChromiumNudge = false,
        extraChromiumBundleIDs = {},  -- e.g. {"com.example.ChromiumFork"}

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

## 🔍 Finding IME Source IDs

The `sources` config needs macOS input source IDs. To list them, open the Hammerspoon Console (menu bar icon → Console) and run:

```lua
hs.inspect(hs.keycodes.methods(true))  -- input methods (IMEs)
hs.inspect(hs.keycodes.layouts(true))  -- keyboard layouts
```

Or check the current one after switching to it manually:

```lua
hs.keycodes.currentSourceID()
```

Common examples:

| Input source | Source ID |
|--------------|-----------|
| ABC | `com.apple.keylayout.ABC` |
| Google Japanese Input | `com.google.inputmethod.Japanese.base` |
| macOS Japanese (Hiragana) | `com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese` |

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

## 🩺 Troubleshooting

- **Nothing happens at all**: Make sure Hammerspoon has Accessibility permission (System Settings > Privacy & Security > Accessibility). Key events cannot be sent without it.
- **Switching fails only in password fields / some terminals**: macOS "Secure Input" blocks synthetic key events while it is active. This is by design and cannot be bypassed.
- **"IME sourceID invalid" alert on start**: The source ID in your `sources`, `defaultIME`, or `appRules` doesn't exist on this Mac. See [Finding IME Source IDs](#-finding-ime-source-ids).
- **IME flips back to English right after switching to Japanese**: Try `behavior = { useCjkBounce = true }`.
- **Chromium browsers show the new IME but type with the old one**: Try `behavior = { useChromiumNudge = true }`.
- **Digging deeper**: Set `behavior = { logLevel = "debug" }` and watch the Hammerspoon Console, or bind the `debug` hotkey to see the current/last-known source IDs.

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
