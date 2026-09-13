# dank-qml-common

Common QML assets for DMS, Dank Calendar, and the rest of the Dank Linux Suite.

The library lives in `DankCommon/` and is consumed through Quickshell's `qs.` namespace:

```qml
import qs.DankCommon.Widgets
import qs.DankCommon.Common
import qs.DankCommon.Modals.FileBrowser
import qs.DankCommon.Session
```

`DankCommon/Session/` holds the components shared between the DMS lock screen and [dms-greeter](https://github.com/AvengeMedia/dank-greeter): the power menu (`LockPowerMenu`) and the on-screen keyboard (`Keyboard`, `KeyboardController`, `CustomButtonKeyboard`). `LockMetrics`, `LockActionButton`, and `LockNotificationCard` provide reusable lock-screen geometry and surfaces. `PowerMenuView` supplies the shared grid/list controls for the shell and lock power menus. `KeyboardController.expressive` and `LockPowerMenu.expressive` opt into Expressive styling; both default to `false`.

`DankCommon/Common/LayoutCodes.js` (keyboard layout name → short code) is imported by relative path.

## Consuming from an app

Add this repo as a git submodule at the app repo root, then symlink it into the quickshell config root:

```sh
git submodule add https://github.com/AvengeMedia/dank-qml-common.git dank-qml-common
ln -s ../dank-qml-common/DankCommon quickshell/DankCommon
```

Anything that copies the quickshell tree for packaging must dereference the symlink (`cp -rL`) - `go:embed` and most packaging flows reject symlinks.

## Standalone development

The repo root is a runnable Quickshell config with stub singletons and a widget gallery:

```sh
qs -p /path/to/dank-qml-common
```

For qmlls completion, create an empty `.qmlls.ini` at the repo root once (`touch .qmlls.ini`, gitignored) - quickshell replaces it with a generated config on the next launch, and every file in the repo gets language-server support. The stubs in `Common/` and `Services/` double as the executable contract below - if a shared widget needs a new singleton property, add it to the stub in the same change.

## Widgets

`DankDialog` provides a title, supporting text, scrollable content and trailing actions. Use it as content inside a window, or set `embedded: false` for its scrim, elevated surface and entry motion. Handle `accepted` and `rejected`; use `acceptEnabled` and `closeEnabled` for pending actions.

`DankWindowHeader` provides floating-window titles, optional subtitles, and minimize, maximize, and close buttons. Set `controls` to the window's `FloatingWindowControls`, provide `title` and `iconName`, and handle `closeRequested`. Add toolbar actions as children. Use `closeEnabled` and `closeTooltipText` when closing depends on dialog state. Set `controls: null` for an embedded surface with only a close button. The component owns title typography, button styling, spacing, and dragging; size the content below it from the header's height.

`DankReorderList` lays out a model with variable-height delegates and emits `reordered(indices)` for persistence. Pair it with `DankDragHandle`, which extends `DankActionButton`: connect `started`, `moved`, `finished`, `dragCanceled`, and `moveRequested` to the list's `begin(index, position)`, `dragTo(position)`, `finish()`, `cancel()`, and `move(index, delta)`. Set `coordinateItem` to the list and bind `dragging` to `list.draggingIndex === index`. Set `flickable` for edge scrolling. Delegates can gate position transitions on `animateLayout` and implement `focusHandle(reason)` to restore focus after a move.

`DankReorderGroup` coordinates transfers between lists. Set each list's `group`, `groupKey`, and `dropArea`, and set the group's `coordinateItem` to their common ancestor. Handle `transferred(sourceList, sourceIndex, targetList, targetIndex)` to persist a transfer. Bind a preview to `sourceItem` and `position`; the group manages insertion gaps and cancellation across its lists.

`DankCommon/Widgets/` (`qs.DankCommon.Widgets`) holds Material 3 Expressive controls (toggle, slider, buttons, button group, chips, tabs, dropdown, text fields, stepper, collapsible section, location search, refresh button, tooltip) plus `DankCard` (tonal surfaces with shared content colors, focus and pressed states), `DankListRow` (passive grouped rows with separate child controls), `DankClockFace` (responsive digital and stacked time layouts), `DankAnalogClock` (hands, hour numbers, orbiting second dot and a date label that avoids the hands, on a `DankOrganicBlob` lobed background), `DankTimePicker`, `DankMonthGrid` (a month calendar grid with day cells, event dots, week numbers, optional weekend tint and a `dayClicked` signal), `DankMaterialShape` (M3 expressive shapes such as cookie, sunny, burst, clover, gem and diamond drawn with QtQuick.Shapes) and `DankSparkline` (a smoothed trend line with area fill for one or two series). All widgets use this module. DMS re-exports them through `quickshell/Widgets/`; DMS consumers import `qs.Widgets`. Expressive widgets read the shape scale, state layer, spring and on-role tokens listed below.

`DankSlider.startIcon` and `endIcon` follow RTL. Set `iconsClickable: true` to decrease and increase the value using the slider's keyboard step. Both actions use `sliderValueChanged` and `sliderDragFinished`. The old `leftIcon` and `rightIcon` names remain aliases.

`DankSlider.handleVariant` accepts `"desktop"` (default, 6 px handle, 4 px pressed) or `"standard"` (4 px, 2 px pressed). Desktop handles are 32 px tall on xs and s sliders; larger sizes retain their handle height. Both keep the selected size's track. Desktop metrics use `sliderHandleWidthDesktop`, `sliderHandleWidthDesktopPressed` and `sliderHandleHeightDesktop` theme tokens.

`DankSlider.centerMinimum` places `minimum` halfway along the track and fills the track up to the handle. The remaining half covers `minimum` through `maximum`; positions before the midpoint select `minimum`. For a 100–200 range, 100 is at the centre, 150 at three-quarters, and 200 at the end. RTL reverses the direction.

`DankSlider.insetIcon` places an icon inside medium and larger standard sliders. `insetIconPosition` accepts `"start"` or `"end"` and follows RTL. Set `insetIconClickable` and `insetIconTooltip` for an action, and handle `insetIconClicked`. Clicking activates the icon; dragging from it adjusts the slider. `focusTargets` exposes the icon action and slider for explicit keyboard traversal. `fillTextColor` and `trackTextColor` control icon contrast on their respective track segments. Value bubbles render above clipped content.


`DankSparkline.edgeExtension` extends the strokes past the end samples using their neighbouring slopes, bounded by the vertical insets. It does not add sample dots.

`WindowCaptureGuard.prepare()` sets `active` and waits for a rendered frame before emitting `ready`. Bind the transparent window's content and blur visibility to `!active`; hide the window and start capture on `ready`. Call `cancel()` when restoring or abandoning the capture.

`DankDialog.popout` drops the header and uses compact popout spacing. `headerActions` adds buttons before the shared window controls.

`DankSlider.trackGradient` paints a continuous gradient across both track segments and follows RTL. The normal handle, gap, input and disabled behavior are preserved.

`DankSaturationValuePicker` edits saturation and value for a given hue. Bind its three values and handle `colorChanged(saturation, value)`. Arrow keys adjust by 1%, Shift adjusts by 10%, Home/End set saturation, and PageUp/PageDown adjust value.

`DankColorButton` displays `swatchColor` with a selection check and emits `clicked`. Set `selected` to reflect the current color. `DankColorSwatch.minPreviewAlpha: 0` displays the exact alpha over a checkerboard.

## The contract

Shared code never imports app singletons. The app injects them once at startup (`DC.Style.theme = Theme`, `DC.Style.settings = SettingsData`, `DC.I18n.backend = I18n`, `DC.Paths.backend = Paths`, `DC.Log.backend = Log`, `DC.Host.session = SessionService`, `DC.Host.cache = CacheData`, with `import qs.DankCommon.Common as DC`), and `Style` reads every token through `theme?.x ?? fallback`. The gallery's `shell.qml` does the same with the stubs in `Common/` and `Services/`. Every consuming app must provide these singletons with at least the properties the library reads:

### `qs.Common` → Theme

Colors: `primary`, `primaryText`, `primaryContainer`, `primaryHover`, `primaryHoverLight`, `primaryPressed`, `primarySelected`, `secondary`, `surface`, `surfaceText`, `surfaceTextHover`, `surfaceTextMedium`, `surfaceTextSecondary`, `surfaceVariant`, `surfaceVariantText`, `surfaceVariantAlpha`, `surfaceHover`, `surfacePressed`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceTint`, `surfaceLight`, `background`, `outline`, `outlineButton`, `outlineMedium`, `outlineStrong`, `outlineHeavy`, `error`, `errorHover`, `errorSelected`, `warning`, `shadowStrong`, `buttonBg`, `buttonText`, `buttonHover`, `buttonPressed`, `floatingSurface`, `nestedSurface`, `floatingWindowSurface`, `floatingWindowNestedSurface`, `floatingWindowFieldColor`, `floatingWindowFieldBorderColor`, `floatingWindowFieldFocusedBorderColor`, `popupFieldColor`, `popupFieldBorderColor`, `popupFieldFocusedBorderColor`, `widgetBaseHoverColor`, `onPrimary`, `onSurface`, `onSurface_12`, `onSurface_38`, `contrastDark`, `contrastLight`.
 Widgets also read `tertiary`, `surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainerHighest`, `surfaceBright`, `surfaceDim`, `outlineVariant`, `secondaryContainer`, `tertiaryContainer`, `onSurfaceVariant`, `onSurfaceVariant_30`, `onPrimaryContainer`, `onSecondaryContainer`, `onTertiaryContainer`, `onErrorContainer`, `inverseSurface`, `inverseOnSurface`, `tonalTintAlpha`.

Metrics: `spacingXXS`..`spacingXL`, `fontSizeSmall`..`fontSizeXLarge`, `iconSizeSmall`/`iconSize`/`iconSizeLarge`, `cornerRadius`.
 Expressive: `fontSizeXXLarge`, the shape scale `shapeScale`, `cornerRadiusXS`..`cornerRadiusXXL`, `cornerRadiusLIncreased`, `cornerRadiusXLIncreased`, `cornerRadiusFull` (compatibility sentinel; `cornerRadiusSmall`/`cornerRadiusLarge` alias S/L), `groupedListGap`, `groupedListInnerRadius`, `groupedListOuterRadius`, `iconButtonSize`, `minimumTouchTargetSize`, `listItemHeight`, `listItemTwoLineHeight`, `avatarSize`, `sliderTrackHeight`, `sliderHandleWidth`, `sliderHandleHeight`, `sliderHandleGap`, `sliderTrackHeightS/M/L/XL`, `sliderHandleHeightS/M/L/XL`, `switchTrackWidth`, `switchTrackHeight`, `switchOutlineWidth`, `switchThumbUnselected`, `switchThumbSelected`, `switchThumbPressed`, `sliderStopSize`, `sliderTickSize`, `menuItemHeight`, `iconSizeMedium`, `outlineWidth`, `outlineWidthFocused`, `dividerWidth`, `focusRingWidth`, `focusRingOffset`, `focusRingColor`, `scrimAlpha`, `smallBreakpoint`, `mediumBreakpoint`, `fontSizeDisplay`, `fontSizeDisplayLarge`, `buttonHeightXS/S/M`, `buttonMinWidth`, `pressScale`, `iconEnterScale`, `popupEnterScale`, `osdHeight`, `dialogMaxWidth`, `pendingOpacity`, `spinnerStrokeWidth`, `tabMinWidth`, `tabIndicatorHeight`, `tabIndicatorMinWidth`, `tabIndicatorInset`, `fieldDefaultWidth`, `fieldHeight`, `fieldHeightLarge`, `outlinedFieldLabelLineHeight`, `textFieldSpatialStiffness`, `textFieldSpatialDampingRatio`, `textFieldFastEffectsStiffness`, `textFieldSlowEffectsStiffness`, `textEditHeight`, `tooltipMaxWidth`, `menuMaxHeight`, `clockFaceSize`, `clockOuterRingRatio`, `clockInnerRingRatio`, `clockHandWidth`, `clockHandleSize`, `clockCenterSize`, `clockSwitchDelay`, `chipIconSize`, `buttonGroupExpandRatio`.

[Shapes](SHAPES.md) documents `radiusStrength`, the component baselines and the radius helpers.

`DankSplitButton` supports `xs`, `s`, `m`, `l`, and `xl` sizes and `filled`, `tonal`, `outlined`, and `elevated` variants. Handle `clicked` for the main action and `menuClicked` for the menu. Set `menuOnly: true` to open the menu from either half. Bind `expanded` to the menu's visibility and use `trailingButton` as its anchor and focus return target. The gallery includes both interaction modes.

`DankLayer` groups content for opacity effects and sizes its texture in physical pixels using the window's device pixel ratio.

Google Sans Flex is bundled under the [SIL Open Font License](DankCommon/assets/fonts/google-sans-flex/OFL.txt), from [Google Fonts](https://fonts.google.com/specimen/Google+Sans+Flex).

Typography: `fontFamily`, `monoFontFamily`, `defaultFontFamily`, `defaultMonoFontFamily`, `fontWeight`. The library bundles and registers its own fonts (Google Sans Flex, FiraCode Nerd Font, Material Symbols - `DankCommon/assets/fonts/`) through the `Fonts` singleton in `qs.DankCommon.Common`; apps typically bind `defaultFontFamily: Fonts.sans` and `defaultMonoFontFamily: Fonts.mono` rather than shipping font files of their own.

Animation: `shorterDuration`, `shortDuration`, `mediumDuration`, `standardEasing`, `emphasizedEasing`, `currentAnimationSpeed`, `expressiveCurves`, `expressiveDurations`.
 Expressive: `stateLayerHover`, `stateLayerFocus`, `stateLayerPressed`, `stateLayerDrag`, `springSpecs`, `springDampingScales`, `springMotionDisabled`, `springPreset(name, baseDuration)` returning `{stiffness, damping, mass}`, `elevationLevel1`, `elevationLevel3`.

Misc: `isLightMode`, `popupTransparency`, `floatingWindowTransparency`, `blurLayersActive`, `connectedSurfaceBlurEnabled`, `elevationEnabled`, `elevationLevel2` (`{blurPx, offsetX, offsetY, spreadPx, alpha}`), `currentAnimationBaseDuration`, `withAlpha(color, alpha)` - which must tolerate an undefined color and return transparent - and `blendAlpha(color, alpha)` with the same tolerance.

Optional (used by `ElevationShadow` when present, static fallbacks otherwise): `elevationLightDirection`, `elevationOffsetXFor()`, `elevationOffsetYFor()`, `elevationShadowColor()`, `elevationAmbient()`.

### `qs.Common` → SettingsData

Enums `AnimationSpeed`, `TextRenderType`, `TextRenderQuality`; properties `animationSpeed`, `enableRippleEffects`, `popoutElevationEnabled`, `textRenderType`, `textRenderQuality`.
 Expressive motion: `reduceMotion`, `springBounce`. Blur border (FileBrowser): `blurBorderEnabled`, `blurBorderOpacity`, `blurBorderColor`, `blurBorderCustomColor`.

Lock surfaces: `lockScreenContentColor`, `lockScreenScrimAlpha`, `lockScreenBlur`, `lockScreenBlurMax`, `screenOffColor`.

Power menu (Session components): `powerActionConfirm`, `powerActionHoldDuration`, `powerMenuActions`, `powerMenuDefaultAction`, `powerMenuGridLayout`.

### `qs.Common` → Anims, Paths, CacheData, I18n

- Anims: `durShort`, `standard`, `emphasized` (bezier arrays)
- Paths: `xdgCache`, `imagecache` (urls), `strip(url)`, `stringify(url)`, `resolveIconPath(iconName)` (return `""` when the app has no icon-theme resolution), `trashPath(path, callback)` (callback receives a success bool), `copyPathToClipboard(path)`; the app must create `imagecache`. The stub defaults use `gio trash` and `Quickshell.clipboardText` - apps route these through their own trash and clipboard machinery so the library itself imposes no runtime dependency
- CacheData: `fileBrowserSettings` (var), `wallpaperLastPath`, `profileLastPath`, `saveCache()`
- I18n: `tr(term, context)`, `isRtl`

### `qs.Services` → Log

`scoped(module)` returning `{debug, info, warn, error}`.

### `qs.Services` → SessionService

Used by `LockPowerMenu`: `hibernateSupported` plus `logout()`, `suspend()`, `hibernate()`, `reboot()`, `poweroff()`. Apps where an action makes no sense (logout in a greeter) provide it as a no-op.

## Translations

Widget strings are owned here, not by the consuming apps. `translations/extract_translations.py` scrapes `I18n.tr()` from `DankCommon/` into `translations/en.json`; the DMS POEditor project is the source of truth for translating those terms, and its sync writes the per-locale exports into `DankCommon/translations/poexports/`. Because that directory lives inside `DankCommon/`, translations ship to every consumer with the submodule pointer like any other file.

Consuming apps keep their own POEditor projects app-only (their extractors must not descend into `DankCommon/`) and merge both sources at runtime in their `I18n` singleton - app terms win on collision.

## Making changes

Run `node tests/run.mjs` for the shape, foreground and QML widget regressions. Requires Node.js and Quickshell with its Qt QML modules. The widget tests run offscreen, two at a time, with separate Quickshell processes and temporary settings. `prek run common-tests --all-files` runs the same suite through the repository hook; GitHub Actions runs it on pushes and pull requests.

The submodule is a real worktree; edit it in place inside whichever app you are working on and the running app picks changes up live. Land the library PR first, then bump the pointer in the app (`make update-common` keeps the submodule and nix flake input in lockstep; app CI re-syncs flake.lock automatically if they drift). If a change reads a new app-singleton property, add it to the root stubs and the contract above in the same PR; the gallery won't run without it. Other consumers upgrade whenever they bump the pointer - no lockstep.

## Notes

- `Common/Proc.qml` exposes `dmsBin` (`DMS_EXECUTABLE` env override) as a DMS convenience; it is inert elsewhere.
- Log stays app-owned so each app keeps its own env-var prefix (`DMS_LOG_LEVEL`, `DANKCAL_LOG_LEVEL`, ...).

Launcher metrics: `launcherTileSize`, `launcherImageRatio`, `launcherMaxVisibleRows`, `launcherWidthMicro`, `launcherWidthDefault`, `launcherWidthWide`, `launcherWidthLarge`, `launcherHeightDefault`, `launcherScreenMargin`. Rows use a uniform `listItemHeight`, `avatarSize` and the grouped list tokens. Modal dimming uses `scrimColor` with `scrimAlpha`.

At `radiusStrength: 50`, the Expressive shape scale is 4, 8, 12, 16, 20, 28, 32 and 48 for XS, S, M, L, LIncreased, XL, XLIncreased and XXL. Zero removes configurable rounding. See [Shapes](SHAPES.md) for component baselines and legacy compatibility.

`Style.foregroundColor(baseColor, floatingWindow)` applies the host's foreground toggle and opacity to a raw surface color. Cards, list items, fields and button groups use it for their background fills. Pass raw colors to field `backgroundColor`; any alpha in that color multiplies the foreground opacity. Text, icons and interaction states retain their own opacity.

Mark a window's content root with `isFloatingWindowSurface: true` to use floating window preferences. A nested root with `isFloatingWindowSurface: false` uses global preferences. `Style.isFloatingWindow(item)` reads the nearest marker and supports the older `disablePopupTransparency: true` marker. Outer window and menu surfaces use window opacity separately from foreground fills.

`DankMaterialShape` uses normalized cubic paths exported from [AndroidX MaterialShapes](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MaterialShapes.kt) with AndroidX graphics-shapes 1.0.1. `shape` selects a lower-camel-case catalog name, including `cookie4`, `cookie6`, `cookie7`, `cookie9`, `cookie12`, `triangle`, `sunny`, `verySunny`, `flower`, `arch` and `heart`. `rotationScale` gives a scale that keeps the rotated outline inside its original inscribed circle. `rotationScaleForAspectRatio(width / height)` accounts for stretched artwork; multiply the available circle diameter by that scale for the artwork height, then by the aspect ratio for its width. `color` sets the fill. `fillProgress` (0–1) fills the shape from the bottom, with `trackColor` above the fill. Shapes become square when the theme radius is zero; set `respectThemeShape: false` for illustrations that must retain their geometry. See `MaterialShapes.NOTICE` beside the path data for licensing.
