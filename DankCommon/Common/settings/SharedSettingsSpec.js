.pragma library
.import "./SpecUtil.js" as Util
.import "../Shape.js" as Shape

function lockWidgetDefaults() {
    const common = {
        displayPreferences: ["all"],
        syncPositionAcrossScreens: true
    };
    const entry = (id, widgetType, enabled, config) => ({
                id: id,
                widgetType: widgetType,
                enabled: enabled,
                config: Object.assign({}, common, config)
            });
    const tint = {
        colorMode: "default",
        customColor: "#ffffff"
    };
    return [entry("lock_clock", "lockClock", true, Object.assign({
            style: "expressive",
            weight: 0,
            twoTone: true,
            autoPosition: true,
            showAnalogNumbers: false,
            showAnalogSeconds: true
        }, tint)), entry("lock_date", "lockDate", true, Object.assign({
            format: "short"
        }, tint)), entry("lock_auth", "lockAuth", true, {
            style: "expressive",
            profileVisibility: "typing",
            passwordVisibility: "typing"
        }), entry("lock_notifications", "lockNotifications", false, {
            mode: 1
        }), entry("lock_status", "lockStatus", true, {
            showMediaPlayer: true,
            showWeather: true,
            background: false
        }), entry("lock_power", "lockPower", false, {
            shape: "round"
        })];
}

var SPEC = {
    lockScreenWidgetInstances: {
        def: lockWidgetDefaults()
    },
    displayNameMode: {
        def: "system"
    },
    currentThemeName: {
        def: "purple",
        onChange: "applyStoredTheme"
    },
    customThemeFile: {
        def: ""
    },
    registryThemeVariants: {
        def: {}
    },
    radiusStrength: {
        def: 50,
        coerce: Shape.normalizeStrength,
        onChange: "updateCompositorLayout"
    },
    radiusMode: {
        def: "scale",
        onChange: "updateCompositorLayout"
    },
    fixedRadius: {
        def: 12,
        coerce: Shape.normalizeFixedRadius,
        onChange: "updateCompositorLayout"
    },
    clockFormat: {
        def: "auto",
        onChange: "markGreeterSyncPending"
    },
    showSeconds: {
        def: false,
        onChange: "markGreeterSyncPending"
    },
    padHours12Hour: {
        def: false,
        onChange: "markGreeterSyncPending"
    },
    useFahrenheit: {
        def: false
    },
    animationDuration: {
        def: 250
    },
    enableRippleEffects: {
        def: true
    },
    popoutElevationEnabled: {
        def: true
    },
    scrollbarsEnabled: {
        def: true
    },
    blurBorderEnabled: {
        def: false
    },
    blurBorderColor: {
        def: "outline"
    },
    blurBorderCustomColor: {
        def: "#ffffff"
    },
    blurBorderOpacity: {
        def: 0.35,
        coerce: Util.percentToUnit
    },
    wallpaperFillMode: {
        def: "Fill"
    },
    wallpaperBackgroundColorMode: {
        def: "black"
    },
    wallpaperBackgroundCustomColor: {
        def: "#000000"
    },
    lockDateFormat: {
        def: ""
    },
    greeterRememberLastSession: {
        def: true,
        onChange: "markGreeterSyncPending"
    },
    greeterRememberLastUser: {
        def: true,
        onChange: "markGreeterSyncPending"
    },
    greeterEnableFprint: {
        def: false,
        onChange: "markGreeterSyncPending"
    },
    greeterEnableU2f: {
        def: false,
        onChange: "markGreeterSyncPending"
    },
    useAutoLocation: {
        def: false
    },
    weatherEnabled: {
        def: true
    },
    fontFamily: {
        def: "Google Sans Flex"
    },
    monoFontFamily: {
        def: "Fira Code"
    },
    displayFontFamily: {
        def: "DM Serif Display"
    },
    fontWeight: {
        def: 400
    },
    fontScale: {
        def: 1.0
    },
    textRenderType: {
        def: 0
    },
    textRenderQuality: {
        def: 0
    },
    lockScreenShowPowerActions: {
        def: false
    },
    lockScreenShowProfileImage: {
        def: true
    },
    lockScreenShowWeather: {
        def: true
    },
    lockScreenWallpaperPath: {
        def: ""
    },
    lockScreenWallpaperFillMode: {
        def: ""
    },
    lockScreenFontFamily: {
        def: ""
    },
    powerActionConfirm: {
        def: true
    },
    powerActionHoldDuration: {
        def: 0.5
    },
    powerMenuActions: {
        def: ["reboot", "logout", "poweroff", "lock", "suspend", "restart"]
    },
    powerMenuDefaultAction: {
        def: "logout"
    },
    powerMenuGridLayout: {
        def: false
    }
};
