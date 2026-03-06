-- =============================================================================
-- Hammerspoon Configuration Entry Point
-- ImeControl Spoon Example Configuration
-- =============================================================================

hs.loadSpoon("ImeControl")

-- Start ImeControl with default settings
spoon.ImeControl:start({
    -- Optional: customize input sources
    -- sources = {
    --     eng = "com.apple.keylayout.US",
    --     jpn = "com.apple.inputmethod.Kotoeri.Roman"
    -- },

    -- Optional: define app-specific IME rules
    -- When these apps are focused, IME will automatically switch
    -- appRules = {
    --     ["com.apple.Terminal"] = "eng",
    --     ["com.googlecode.iterm2"] = "eng",
    --     ["com.apple.Safari"] = "jpn",
    -- },

    -- Optional: customize behavior settings
    -- behavior = {
    --     showAlert = true,
    --     alertDuration = 0.8
    -- }
})

-- Optional: enable keybindings
-- Uncomment the section below to enable IME toggle and debug hotkeys
-- spoon.ImeControl:bindHotkeys({
--     toggle = { {"shift"}, "f12" },
--     debug  = { {"shift"}, "f11" },
-- })

-- Auto-reload config on file changes
local function reloadConfig(files)
    for _, file in ipairs(files) do
        if file:sub(-4) == ".lua" then
            hs.reload()
            return
        end
    end
end
hs.pathwatcher.new(hs.configdir, reloadConfig):start()
hs.alert.show("Hammerspoon Config Loaded")
