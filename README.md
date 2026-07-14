# dank-qml-common

Common QML assets for DMS, Dank Calendar, and the rest of the Dank Linux Suite.

The library lives in `DankCommon/` and is consumed through Quickshell's `qs.` namespace:

```qml
import qs.DankCommon.Widgets
import qs.DankCommon.Common
import qs.DankCommon.Modals.FileBrowser
```

## Consuming from an app

Add this repo as a git submodule at the app repo root, then symlink it into the quickshell config root:

```sh
git submodule add https://github.com/AvengeMedia/dank-qml-common.git dank-qml-common
ln -s ../dank-qml-common/DankCommon quickshell/DankCommon
```

Anything that copies the quickshell tree for packaging must dereference the symlink (`cp -rL`) — `go:embed` and most packaging flows reject symlinks.

## Standalone development

The repo root is a runnable Quickshell config with stub singletons and a widget gallery:

```sh
qs -c /path/to/dank-qml-common
```

For qmlls completion, create an empty `.qmlls.ini` at the repo root once (`touch .qmlls.ini`, gitignored) — quickshell replaces it with a generated config on the next launch, and every file in the repo gets language-server support. The stubs in `Common/` and `Services/` double as the executable contract below — if a shared widget needs a new singleton property, add it to the stub in the same change.

## The contract

Shared code never imports app singletons by path — it imports `qs.Common` and `qs.Services`, which resolve to the consuming app at runtime. Every consuming app must provide these singletons with at least the properties the library reads:

### `qs.Common` → Theme

Colors: `primary`, `primaryText`, `primaryContainer`, `primaryHover`, `primaryHoverLight`, `secondary`, `surface`, `surfaceText`, `surfaceTextHover`, `surfaceTextMedium`, `surfaceVariant`, `surfaceVariantText`, `surfaceVariantAlpha`, `surfacePressed`, `surfaceContainer`, `surfaceContainerHigh`, `background`, `outline`, `outlineButton`, `outlineMedium`, `outlineStrong`, `outlineHeavy`, `error`, `errorHover`, `shadowStrong`, `buttonBg`, `buttonText`, `buttonHover`, `buttonPressed`, `floatingSurface`, `nestedSurface`, `widgetBaseHoverColor`.

Metrics: `spacingXXS`..`spacingL`, `fontSizeSmall`..`fontSizeXLarge`, `iconSizeSmall`/`iconSize`/`iconSizeLarge`, `cornerRadius`.

Typography: `fontFamily`, `monoFontFamily`, `defaultFontFamily`, `defaultMonoFontFamily`, `iconFontFamily`, `nerdFontFamily`, `fontWeight`. The app owns font files and their FontLoaders; these properties must name families that are already registered (`iconFontFamily` is a Material Symbols variant, `nerdFontFamily` a Nerd Font for file-type glyphs).

Animation: `shorterDuration`, `shortDuration`, `standardEasing`, `emphasizedEasing`, `currentAnimationSpeed`, `expressiveCurves`, `expressiveDurations`.

Misc: `isLightMode`, `popupTransparency`, `elevationEnabled`, `elevationLevel2` (`{blurPx, offsetX, offsetY, spreadPx, alpha}`), `currentAnimationBaseDuration`, `withAlpha(color, alpha)` — which must tolerate an undefined color and return transparent.

Optional (used by `ElevationShadow` when present, static fallbacks otherwise): `elevationLightDirection`, `elevationOffsetXFor()`, `elevationOffsetYFor()`, `elevationShadowColor()`, `elevationAmbient()`.

### `qs.Common` → SettingsData

Enums `AnimationSpeed`, `TextRenderType`, `TextRenderQuality`; properties `animationSpeed`, `enableRippleEffects`, `popoutElevationEnabled`, `textRenderType`, `textRenderQuality`.

### `qs.Common` → Anims, Paths, CacheData, I18n

- Anims: `durShort`, `standard`, `emphasized` (bezier arrays)
- Paths: `xdgCache`, `imagecache` (urls), `strip(url)`, `stringify(url)`; the app must create `imagecache`
- CacheData: `fileBrowserSettings` (var), `wallpaperLastPath`, `profileLastPath`, `saveCache()`
- I18n: `tr(term, context)`, `isRtl`

### `qs.Services` → Log

`scoped(module)` returning `{debug, info, warn, error}`.

## Translations

Widget strings are owned here, not by the consuming apps. `translations/extract_translations.py` scrapes `I18n.tr()` from `DankCommon/` into `translations/en.json`; the DMS POEditor project is the source of truth for translating those terms, and its sync writes the per-locale exports into `DankCommon/translations/poexports/`. Because that directory lives inside `DankCommon/`, translations ship to every consumer with the submodule pointer like any other file.

Consuming apps keep their own POEditor projects app-only (their extractors must not descend into `DankCommon/`) and merge both sources at runtime in their `I18n` singleton — app terms win on collision.

## Making changes

The submodule is a real worktree; edit it in place inside whichever app you are working on and the running app picks changes up live. Land the library PR first, then bump the pointer in the app (`make update-common` keeps the submodule and nix flake input in lockstep — CI fails if they drift). If a change reads a new app-singleton property, add it to the root stubs and the contract above in the same PR; the gallery won't run without it. Other consumers upgrade whenever they bump the pointer — no lockstep.

## Notes

- `Common/Proc.qml` exposes `dmsBin` (`DMS_EXECUTABLE` env override) as a DMS convenience; it is inert elsewhere.
- Log stays app-owned so each app keeps its own env-var prefix (`DMS_LOG_LEVEL`, `DANKCAL_LOG_LEVEL`, ...).
