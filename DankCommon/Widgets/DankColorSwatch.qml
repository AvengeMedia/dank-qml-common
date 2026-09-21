import QtQuick
import qs.DankCommon.Common

ShaderEffect {
    id: root

    property color swatchColor: "transparent"
    property color ringColor: Style.outline
    property real minPreviewAlpha: 0.4
    readonly property bool translucent: swatchColor.a < 1
    readonly property color displayColor: translucent && swatchColor.a > 0 ? Style.withAlpha(swatchColor, Math.max(swatchColor.a, minPreviewAlpha)) : swatchColor

    readonly property real widthPx: width
    readonly property real heightPx: height
    readonly property real ringWidthPx: Style.outlineWidth
    readonly property real checkerPx: Math.max(Style.spacingXXS, Math.round(width / 4))
    readonly property real showChecker: translucent ? 1 : 0
    readonly property color fillColor: displayColor
    readonly property color checkerLight: Style.surfaceContainerLowest
    readonly property color checkerDark: Style.surfaceContainerHighest

    blending: true
    fragmentShader: Qt.resolvedUrl("../Shaders/qsb/color_swatch.frag.qsb")
}
