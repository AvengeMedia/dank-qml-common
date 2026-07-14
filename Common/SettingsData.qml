pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    enum AnimationSpeed {
        None,
        Short,
        Medium,
        Long,
        Custom
    }

    enum TextRenderType {
        Qt,
        Native,
        Curve
    }

    enum TextRenderQuality {
        Default,
        Low,
        Normal,
        High,
        VeryHigh
    }

    property int animationSpeed: SettingsData.AnimationSpeed.Short
    property bool enableRippleEffects: true
    property bool popoutElevationEnabled: true
    property int textRenderType: SettingsData.TextRenderType.Qt
    property int textRenderQuality: SettingsData.TextRenderQuality.Default
}
