# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Rapid double-toggle no longer re-targets the same IME: `toggleIME` now bases
  the toggle direction on the last known IME while a switch is in flight,
  instead of the OS state that lags behind by `applyDelay`.
- `behavior` settings passed via SpoonInstall's `config` are no longer silently
  ignored by `start()`.
- Log messages no longer embed the logger table: all `hs.logger` calls use the
  dot syntax required by the API.
- A new `applyIME` call now also cancels an in-flight shortcut-fallback loop
  that was still pressing the switch shortcut toward the previous target.
- Only one fallback workaround runs per failed switch: with both
  `useCjkBounce` and `useShortcutFallback` enabled, the two no longer fire
  together and press the same shortcut twice.
- `hotkeys` passed inside the `start()` config no longer leaks into the
  internal config table.

### Added
- `behavior.logLevel` to control log verbosity.
- `behavior.alertLabels` to customize the toggle alert labels (previously
  hardcoded Japanese labels).
- `behavior.useJISKeys` to disable sending JIS Eisu/Kana keycodes.
- `behavior.extraChromiumBundleIDs` to extend the Chromium browser list, and
  more browsers in the built-in list (Chrome Beta/Dev, Chromium, Edge
  `com.microsoft.edgemac`, Arc).
- Config validation now also checks raw source IDs in `defaultIME` and
  `appRules`.
- Japanese README (`README.ja.md`), IME source ID discovery guide,
  workaround/troubleshooting docs.
- CI (luacheck, version consistency, release zip sync check) and stricter
  `version.sh` (clean-tree check, duplicate-tag check, `.DS_Store` exclusion).

## [1.0.8] - 2026-06-09
### Added
- `behavior.callDedupeThreshold` to suppress duplicate `applyIME` calls.
### Changed
- Default config is rebuilt on each `start()` so repeated starts do not
  accumulate settings; improved Chromium detection.

## [1.0.7] - 2026-05-24
### Changed
- Default logger level changed from `debug` to `info`.
- Project renamed to Hanten(反転) in documentation.

## [1.0.6] - 2026-04-13
### Changed
- Renamed Spoon from ImeControl to Hanten.

## [1.0.5] - 2026-03-22
### Added
- `defaultIME` option for a global default IME on app switch.

## [1.0.4] - 2026-03-07
### Removed
- `hs.window.filter.default` usage and `spoon_list.json`.

## [1.0.3] - 2026-03-06
### Fixed
- Updated `docs.json`.

## [1.0.2] - 2026-03-06
### Changed
- Improved `version.sh`.

## [1.0.1] - 2026-03-06
- Initial Spoon release.
