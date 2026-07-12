# Hanten(反転).spoon

[English README is here](README.md)

[Hammerspoon](https://www.hammerspoon.org/) 用の堅牢なIME(入力ソース)切替Spoonです。英語とCJK系入力メソッドの切替を確実に行い、アプリごとの自動切替やスリープ復帰後の状態復元にも対応します。

## ✨ 特徴

- 🎯 **確実なIME切替**: JISキーコード + macOS API の併用による堅牢な切替
- 🌐 **デフォルトIME**: `defaultIME` で全アプリ共通のデフォルトIMEを設定可能
- 🔄 **アプリ別自動切替**: `appRules` でアプリごとの上書き(`defaultIME` より優先)
- 💾 **システム復元**: スリープ復帰・ロック解除時にIME状態を監視・復元
- 🪟 **フォーカス追従**: ウィンドウ切替時にIME状態をリフレッシュ
- ⚙️ **カスタマイズ可能**: タイミング調整、フォールバック機構、アラート表示の切替
- 🔑 **ホットキー対応**: 手動トグルとデバッグ表示のキーバインド(任意)

## 📦 インストール

まだの場合は先に [Hammerspoon](https://www.hammerspoon.org/) をインストールしてください:

```bash
brew install --cask hammerspoon
```

[Hanten.spoon.zip](https://github.com/masaki39/hanten/raw/main/Spoons/Hanten.spoon.zip) をダウンロードして開き(インストールされます)、`~/.hammerspoon/init.lua` に追記します:

```lua
hs.loadSpoon("Hanten")
spoon.Hanten:start({
    -- 設定はすべて省略可能。以下はデフォルト値
    sources = {
        eng = "com.apple.keylayout.ABC",            -- デフォルト
        jpn = "com.google.inputmethod.Japanese.base" -- デフォルト
    },
    defaultIME = "eng",  -- アプリ切替時に常に英語へ(省略可)
    appRules = {
        -- ["com.apple.Terminal"] = "eng",  -- 特定アプリでdefaultIMEを上書き
        -- ["com.some.jpnapp"]    = "jpn",
    }
}):bindHotkeys({
    toggle = { {"shift"}, "f12" },
    debug  = { {"shift"}, "f11" },
})
```

<details>
<summary>🚀 SpoonInstall経由</summary>

まだの場合は [SpoonInstall.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/main/Spoons/SpoonInstall.spoon.zip) をダウンロードして開いてください。

`~/.hammerspoon/init.lua` に追記:

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
            eng = "com.apple.keylayout.ABC",            -- デフォルト
            jpn = "com.google.inputmethod.Japanese.base" -- デフォルト
        },
        defaultIME = "eng",  -- 省略可
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

## ⚙️ 詳細設定

`behavior` 以下のオプションはすべて `start()` の設定に含められます:

```lua
spoon.Hanten:start({
    behavior = {
        -- 手動トグル時のアラート表示
        showAlert = true,
        alertDuration = 0.5,
        alertLabels = {
            eng = "Aa 英数",     -- 英語切替時のラベル
            jpn = "🇯🇵 日本語"   -- CJK切替時のラベル
        },

        -- ログレベル: "error", "warning", "info", "debug", "verbose"
        logLevel = "info",

        -- inputSourceChangedウォッチャーの有効/無効
        useSourceChangedWatcher = true,

        -- API呼び出しに加えてJIS英数/かなキーを送出する。
        -- ANSIキーボードでも無害だが、不要なら無効化できる。
        useJISKeys = true,

        -- フォールバック: IMEが切り替わるまでショートカットを連打する。
        -- sourceSwitchShortcutにはmacOSの入力ソース切替ショートカット
        -- (システム設定 > キーボード > ショートカット > 入力ソース)を指定。
        useShortcutFallback = true,
        sourceSwitchShortcut = {
            mods = {"ctrl"},
            key  = "space",
            delayUS = 50000,
            interval = 0.1,
            maxPresses = 10
        },

        -- 一部のCJK入力メソッドで切替直後に英語へ戻される「バウンス」問題の
        -- ワークアラウンド: jpn→engへ一度往復させてからsourceSwitchShortcutを
        -- 押すことで確実にjpnへ着地させる。日本語切替が勝手に英語へ戻る
        -- 症状があるときだけ有効化を推奨。
        -- 有効時はjpnターゲットに対してuseShortcutFallbackの代わりに動作する。
        useCjkBounce = false,

        -- Chromium系ブラウザ(Chrome, Edge, Brave, Arcなど)がキー入力まで
        -- IME変更を反映しない問題のワークアラウンド: 切替後に無害なF19キーを
        -- ブラウザへ送る。IME表示は変わるのに入力が前のIMEのままになる
        -- 場合に有効化する。
        useChromiumNudge = false,
        extraChromiumBundleIDs = {},  -- 例: {"com.example.ChromiumFork"}

        -- 切替失敗時のリトライ設定
        retryInterval = 0.1,
        retryCount = 5,

        -- タイミング調整(上級者向け)
        applyDelay = 0.05,
        alertDelay = 0.02,
        keyTapDelay = 0.005,
        justAppliedThreshold = 1.0,
        callDedupeThreshold = 0.2   -- この秒数以内の重複applyIME呼び出しを抑制
    }
})
```

## 🔍 IMEソースIDの調べ方

`sources` の設定にはmacOSの入力ソースIDが必要です。Hammerspoonコンソール(メニューバーアイコン → Console)で以下を実行すると一覧できます:

```lua
hs.inspect(hs.keycodes.methods(true))  -- 入力メソッド(IME)
hs.inspect(hs.keycodes.layouts(true))  -- キーボードレイアウト
```

手動で切り替えてから現在のIDを確認する方法もあります:

```lua
hs.keycodes.currentSourceID()
```

よく使う例:

| 入力ソース | ソースID |
|-----------|-----------|
| ABC | `com.apple.keylayout.ABC` |
| Google日本語入力 | `com.google.inputmethod.Japanese.base` |
| macOS日本語(ひらがな) | `com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese` |

## 🔍 アプリのBundle IDの調べ方

`appRules` にはアプリのBundle Identifierが必要です。ターミナルで:

```bash
osascript -e 'id of app "Terminal"'
# => com.apple.Terminal
```

よく使う例:

| アプリ | Bundle ID |
|-----|-----------|
| Terminal | `com.apple.Terminal` |
| iTerm2 | `com.googlecode.iterm2` |
| VS Code | `com.microsoft.VSCode` |
| Xcode | `com.apple.dt.Xcode` |

## 🩺 トラブルシューティング

- **何も起きない**: Hammerspoonにアクセシビリティ権限があるか確認してください(システム設定 > プライバシーとセキュリティ > アクセシビリティ)。権限がないとキーイベントを送出できません。
- **パスワード欄や一部ターミナルでだけ切替が効かない**: macOSの「Secure Input」が有効な間は合成キーイベントがブロックされます。仕様のため回避できません。
- **起動時に「IME sourceID invalid」アラートが出る**: `sources` / `defaultIME` / `appRules` に指定したソースIDがこのMacに存在しません。[IMEソースIDの調べ方](#-imeソースidの調べ方)を参照してください。
- **日本語に切り替えた直後に英語へ戻ってしまう**: `behavior = { useCjkBounce = true }` を試してください。
- **Chromium系ブラウザでIME表示は変わるのに入力が変わらない**: `behavior = { useChromiumNudge = true }` を試してください。
- **さらに調査したい**: `behavior = { logLevel = "debug" }` にしてHammerspoonコンソールを確認するか、`debug` ホットキーで現在/最終のソースIDを表示してください。

## 🏷️ バージョン管理(開発者向け)

`version.sh` でバージョンのバンプ、zipの再生成、コミット+タグ付けを一括で行えます:

```bash
chmod +x version.sh   # 初回のみ
./version.sh patch    # パッチバンプ(デフォルト)
./version.sh minor    # マイナーバンプ
./version.sh major    # メジャーバンプ
```

その後プッシュ:

```bash
git push && git push --tags
```

## ライセンス

本ソフトウェアは **Unlicense**(パブリックドメイン)で公開されています。目的を問わず自由に使用・改変・再配布できます。
