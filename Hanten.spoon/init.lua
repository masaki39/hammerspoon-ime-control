-- =============================================================================
-- Hanten Spoon for Hammerspoon
-- Robust IME (Input Method Editor) switching for macOS
-- License: Unlicense (Public Domain)
-- =============================================================================

local obj = {}
obj.name = "Hanten"
obj.version = "1.0.8"
obj.author = "masaki39"
obj.license = "Unlicense"
obj.__index = obj
obj.sources = nil    -- SpoonInstall-compatible config override
obj.appRules = nil   -- SpoonInstall-compatible config override
obj.defaultIME = nil -- SpoonInstall-compatible config override

local logger = hs.logger.new('Hanten', 'info')

local KEYCODES = {
    eisu = 102,
    kana = 104,
    f19  = 80
}

local CHROMIUM_BUNDLE_IDS = {
    ["com.google.Chrome"]        = true,
    ["com.google.Chrome.canary"] = true,
    ["com.microsoft.Edge"]       = true,
    ["com.brave.Browser"]        = true,
    ["com.vivaldi.Vivaldi"]      = true,
    ["com.operasoftware.Opera"]  = true,
}

-- Returns a fresh default config table; called on each start() to prevent accumulation
local function makeDefaultConfig()
    return {
        sources = {
            eng = "com.apple.keylayout.ABC",
            jpn = "com.google.inputmethod.Japanese.base"
        },

        appRules = {},
        defaultIME = nil,

        behavior = {
            retryInterval = 0.1,
            retryCount = 5,
            alertDuration = 0.5,
            showAlert = true,
            useSourceChangedWatcher = true,
            useShortcutFallback = true,
            useCjkBounce = false,
            useChromiumNudge = false,
            sourceSwitchShortcut = {
                mods = {"ctrl"},
                key  = "space",
                delayUS = 50000,
                interval = 0.1,
                maxPresses = 10
            },

            applyDelay = 0.05,
            alertDelay = 0.02,
            keyTapDelay = 0.005,
            justAppliedThreshold = 1.0,
            callDedupeThreshold = 0.2,
        }
    }
end

obj._defaultConfig = makeDefaultConfig()

local STATE = {
    lastKnownIME = nil,
    lastApplyTime = 0,
    alertUUID = nil,
    appWatcher = nil,
    systemWatcher = nil,
    sourceChangedEnabled = false,
    sourceChangedInstalled = false,
    running = false,

    timers = {},
    keyUpTimers = {},
    hotkeys = {},
    hotkeyMap = nil
}

local function safeCall(fn)
    local ok, err = xpcall(fn, debug.traceback)
    if not ok then
        logger:e(string.format("Error in timer callback: %s", err))
    end
end

local timerManager = {}

function timerManager.start(name, delay, fn)
    timerManager.stop(name)
    STATE.timers[name] = hs.timer.doAfter(delay, function()
        STATE.timers[name] = nil
        safeCall(fn)
    end)
end

-- Capture t before storing so old closures cannot nil out a replacement timer
function timerManager.doWhile(name, checkFn, actionFn, interval)
    timerManager.stop(name)
    local t
    t = hs.timer.doWhile(
        function()
            local shouldContinue = checkFn()
            if not shouldContinue and STATE.timers[name] == t then
                STATE.timers[name] = nil
            end
            return shouldContinue
        end,
        function()
            safeCall(actionFn)
        end,
        interval
    )
    STATE.timers[name] = t
end

function timerManager.stop(name)
    if STATE.timers[name] then
        STATE.timers[name]:stop()
        STATE.timers[name] = nil
    end
end

function timerManager.stopAll()
    local activeTimers = STATE.timers
    STATE.timers = {}

    for _, t in pairs(activeTimers) do
        t:stop()
    end

    local activeKeyUpTimers = STATE.keyUpTimers
    STATE.keyUpTimers = {}

    for t, _ in pairs(activeKeyUpTimers) do
        t:stop()
    end
end

local function validateConfig()
    local methods = hs.keycodes.methods(true)
    local layouts = hs.keycodes.layouts(true)
    local valid = true

    local function exists(id)
        for _, mID in ipairs(methods) do if mID == id then return true end end
        for _, lID in ipairs(layouts) do if lID == id then return true end end
        return false
    end

    for name, id in pairs(obj._defaultConfig.sources) do
        if not exists(id) then
            local msg = string.format("IME sourceID invalid: '%s' (%s)", name, id)
            logger:w(msg)
            hs.alert.show(msg, 3)
            valid = false
        end
    end
    return valid
end

local function isChromium(bundleID)
    return bundleID ~= nil and CHROMIUM_BUNDLE_IDS[bundleID] ~= nil
end

-- Store {keyCode, app} so stop() can send targeted key-ups if this timer is cancelled
local function postJISKey(keyCode, app)
    hs.eventtap.event.newKeyEvent({}, keyCode, true):post(app)

    local timer
    timer = hs.timer.doAfter(obj._defaultConfig.behavior.keyTapDelay, function()
        hs.eventtap.event.newKeyEvent({}, keyCode, false):post(app)
        if timer then STATE.keyUpTimers[timer] = nil end
    end)
    STATE.keyUpTimers[timer] = {keyCode = keyCode, app = app}
end

local function chromiumNudge()
    if not obj._defaultConfig.behavior.useChromiumNudge then return end

    local app = hs.application.frontmostApplication()
    if not app then return end
    if not isChromium(app:bundleID()) then return end

    timerManager.start("chromiumNudge", 0.02, function()
        postJISKey(KEYCODES.f19, app)
    end)
end

local function cjkBounceWorkaround(targetID)
    if not obj._defaultConfig.behavior.useCjkBounce or targetID ~= obj._defaultConfig.sources.jpn then return end
    local sc = obj._defaultConfig.behavior.sourceSwitchShortcut
    if not sc then return end

    logger:d("Starting CJK bounce workaround")
    hs.keycodes.currentSourceID(targetID)

    timerManager.start("cjkBounce1", 0.03, function()
        hs.keycodes.currentSourceID(obj._defaultConfig.sources.eng)

        timerManager.start("cjkBounce2", 0.03, function()
            hs.eventtap.keyStroke(sc.mods, sc.key, sc.delayUS or 200000)
        end)
    end)
end

local function fallbackByShortcut(targetID)
    local sc = obj._defaultConfig.behavior.sourceSwitchShortcut
    if not (obj._defaultConfig.behavior.useShortcutFallback and sc) then return end

    logger:d(string.format("Starting shortcut fallback for %s", targetID))
    local presses = 0
    timerManager.doWhile("shortcutFallback",
        function()
            presses = presses + 1
            local current = hs.keycodes.currentSourceID()
            local shouldContinue = presses <= sc.maxPresses and current ~= targetID
            if not shouldContinue then
                if current == targetID then
                    logger:i(string.format("Shortcut fallback succeeded after %d presses", presses - 1))
                else
                    logger:w(string.format("Shortcut fallback failed after %d presses", sc.maxPresses))
                end
            end
            return shouldContinue
        end,
        function()
            hs.eventtap.keyStroke(sc.mods, sc.key, sc.delayUS or 50000)
        end,
        sc.interval or 0.05
    )
end

local function applyIME(sourceID, force)
    if not sourceID then return end

    local current = hs.keycodes.currentSourceID()
    local now = hs.timer.secondsSinceEpoch()

    local recentlyApplied = (now - STATE.lastApplyTime) < obj._defaultConfig.behavior.callDedupeThreshold
    if not force and sourceID == current and recentlyApplied then
        return
    end

    logger:d(string.format("applyIME: %s (Current: %s, Last: %s, Force: %s)",
        sourceID, tostring(current), tostring(STATE.lastKnownIME), tostring(force)))

    STATE.lastApplyTime = now

    timerManager.stop("apply")
    timerManager.stop("enforcement")
    timerManager.stop("cjkBounce1")
    timerManager.stop("cjkBounce2")

    STATE.lastKnownIME = sourceID

    local forceKey = nil
    if sourceID == obj._defaultConfig.sources.eng then
        forceKey = KEYCODES.eisu
    elseif sourceID == obj._defaultConfig.sources.jpn then
        forceKey = KEYCODES.kana
    end

    if forceKey then
        postJISKey(forceKey)
    end

    timerManager.start("apply", obj._defaultConfig.behavior.applyDelay, function()
        hs.keycodes.currentSourceID(sourceID)

        chromiumNudge()

        if hs.keycodes.currentSourceID() ~= sourceID then
            local count = 0
            timerManager.doWhile("enforcement",
                function()
                    count = count + 1
                    local current = hs.keycodes.currentSourceID()
                    local shouldContinue = count <= obj._defaultConfig.behavior.retryCount and current ~= sourceID

                    if not shouldContinue and current ~= sourceID then
                        fallbackByShortcut(sourceID)
                        cjkBounceWorkaround(sourceID)
                    end

                    return shouldContinue
                end,
                function()
                    if forceKey then postJISKey(forceKey) end
                    hs.keycodes.currentSourceID(sourceID)
                end,
                obj._defaultConfig.behavior.retryInterval
            )
        end
    end)
end

local function toggleIME()
    logger:d("toggleIME called")
    local current = hs.keycodes.currentSourceID()
    local target = (current == obj._defaultConfig.sources.eng) and obj._defaultConfig.sources.jpn or obj._defaultConfig.sources.eng
    local label  = (target == obj._defaultConfig.sources.jpn) and "🇯🇵 日本語" or "Aa 英数"

    applyIME(target, true)

    if obj._defaultConfig.behavior.showAlert then
        timerManager.start("alert", obj._defaultConfig.behavior.alertDelay, function()
            if STATE.alertUUID then hs.alert.closeSpecific(STATE.alertUUID) end
            local uuid = hs.alert.show(label, obj._defaultConfig.behavior.alertDuration)
            STATE.alertUUID = uuid

            timerManager.start("alertClose", obj._defaultConfig.behavior.alertDuration + 0.05, function()
                if STATE.alertUUID == uuid then
                    hs.alert.closeSpecific(uuid)
                    STATE.alertUUID = nil
                end
            end)
        end)
    end
end

local function showDebugInfo()
    hs.alert.show(string.format("Current: %s\nLast: %s", hs.keycodes.currentSourceID(), STATE.lastKnownIME))
end

function obj:bindHotkeys(map)
    for _, hk in ipairs(STATE.hotkeys) do
        hk:delete()
    end
    STATE.hotkeys = {}

    STATE.hotkeyMap = map

    if map.toggle then
        local hk = hs.hotkey.bind(map.toggle[1], map.toggle[2], toggleIME)
        table.insert(STATE.hotkeys, hk)
        logger:i(string.format("Bound toggle hotkey: %s+%s", table.concat(map.toggle[1], "+"), map.toggle[2]))
    end

    if map.debug then
        local hk = hs.hotkey.bind(map.debug[1], map.debug[2], showDebugInfo)
        table.insert(STATE.hotkeys, hk)
        logger:i(string.format("Bound debug hotkey: %s+%s", table.concat(map.debug[1], "+"), map.debug[2]))
    end

    return self
end

function obj:stop()
    local wasRunning = STATE.running
    STATE.running = false

    -- Drain pending key-up timers with their app targets before stopAll clears the table
    local pendingKeyUps = STATE.keyUpTimers
    STATE.keyUpTimers = {}
    for t, info in pairs(pendingKeyUps) do
        t:stop()
        hs.eventtap.event.newKeyEvent({}, info.keyCode, false):post(info.app)
    end

    timerManager.stopAll()

    if STATE.appWatcher then STATE.appWatcher:stop(); STATE.appWatcher = nil end
    if STATE.systemWatcher then STATE.systemWatcher:stop(); STATE.systemWatcher = nil end

    for _, hk in ipairs(STATE.hotkeys) do
        hk:delete()
    end
    STATE.hotkeys = {}

    -- Unregister the inputSourceChanged callback so it can be re-installed correctly on next start()
    if STATE.sourceChangedInstalled then
        hs.keycodes.inputSourceChanged(nil)
        STATE.sourceChangedInstalled = false
    end
    STATE.sourceChangedEnabled = false

    if STATE.alertUUID then
        hs.alert.closeSpecific(STATE.alertUUID)
        STATE.alertUUID = nil
    end

    if wasRunning then
        logger:i("Stopped")
    end

    return self
end

-- appRules is replaced entirely so start({appRules={}}) clears all rules.
-- Other tables are merged 2 levels deep so partial overrides work, e.g.
-- {behavior={showAlert=false}} or {behavior={sourceSwitchShortcut={key='grave'}}}.
local function loadConfig(userConfig)
    if not userConfig then return end
    for k, v in pairs(userConfig) do
        if k == "appRules" then
            obj._defaultConfig[k] = v
        elseif type(v) == "table" and type(obj._defaultConfig[k]) == "table" then
            for subK, subV in pairs(v) do
                if type(subV) == "table" and type(obj._defaultConfig[k][subK]) == "table" then
                    for subSubK, subSubV in pairs(subV) do
                        obj._defaultConfig[k][subK][subSubK] = subSubV
                    end
                else
                    obj._defaultConfig[k][subK] = subV
                end
            end
        else
            obj._defaultConfig[k] = v
        end
    end
end

function obj:start(userConfig)
    self:stop()

    -- Reset config to defaults before applying user overrides so repeated
    -- start() calls do not accumulate settings from previous runs
    obj._defaultConfig = makeDefaultConfig()

    -- Merge: direct properties (SpoonInstall) → userConfig (userConfig wins)
    local effectiveConfig = {}
    if self.sources then effectiveConfig.sources = self.sources end
    if self.appRules then effectiveConfig.appRules = self.appRules end
    if self.defaultIME then effectiveConfig.defaultIME = self.defaultIME end
    if userConfig then
        for k, v in pairs(userConfig) do
            effectiveConfig[k] = v
        end
    end
    loadConfig(next(effectiveConfig) ~= nil and effectiveConfig or nil)

    validateConfig()

    STATE.running = true
    STATE.lastKnownIME = hs.keycodes.currentSourceID() or obj._defaultConfig.sources.eng

    local hotkeyMap = (userConfig and userConfig.hotkeys) or STATE.hotkeyMap
    if hotkeyMap then
        self:bindHotkeys(hotkeyMap)
    end

    -- 1. IME Change Watcher
    if obj._defaultConfig.behavior.useSourceChangedWatcher then
        STATE.sourceChangedEnabled = true
        if not STATE.sourceChangedInstalled then
            hs.keycodes.inputSourceChanged(function()
                if not STATE.sourceChangedEnabled then return end
                local current = hs.keycodes.currentSourceID()
                local now = hs.timer.secondsSinceEpoch()
                local justApplied = (now - STATE.lastApplyTime) < (obj._defaultConfig.behavior.justAppliedThreshold or 1.0)

                if current and current ~= STATE.lastKnownIME then
                    STATE.lastKnownIME = current

                    if not justApplied then
                        timerManager.stop("apply")
                        timerManager.stop("enforcement")
                    else
                        logger:d("inputSourceChanged during switching -> keep enforcement")
                    end
                end
            end)
            STATE.sourceChangedInstalled = true
        end
    else
        STATE.sourceChangedEnabled = false
    end

    STATE.appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
        if eventType == hs.application.watcher.activated then
            local bundleID = appObject:bundleID()
            local rule = bundleID and obj._defaultConfig.appRules[bundleID]
            local targetRule = rule or obj._defaultConfig.defaultIME

            if targetRule then
                local targetID = targetRule
                if targetRule == "eng" then
                    targetID = obj._defaultConfig.sources.eng
                elseif targetRule == "jpn" then
                    targetID = obj._defaultConfig.sources.jpn
                end
                logger:d(string.format("App focused: %s -> applying %s", bundleID, targetID))
                applyIME(targetID)
            end
        end
    end)
    STATE.appWatcher:start()

    STATE.systemWatcher = hs.caffeinate.watcher.new(function(event)
        if event == hs.caffeinate.watcher.systemDidWake or
           event == hs.caffeinate.watcher.screensDidUnlock then
            logger:i("System wake/unlock detected")
            -- currentSourceID() may return nil briefly after wake; fall back to last known
            applyIME(hs.keycodes.currentSourceID() or STATE.lastKnownIME or obj._defaultConfig.sources.eng)
        end
    end)
    STATE.systemWatcher:start()

    logger:i("Initialized")

    return self
end

return obj
