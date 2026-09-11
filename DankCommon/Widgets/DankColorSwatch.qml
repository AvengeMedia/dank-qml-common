import QtQuick
import qs.DankCommon.Common

Item {
    id: root

    property color swatchColor: "transparent"
    property color ringColor: Style.outline
    property real minPreviewAlpha: 0.4
    readonly property bool translucent: swatchColor.a < 1
    readonly property color displayColor: translucent && swatchColor.a > 0 ? Style.withAlpha(swatchColor, Math.max(swatchColor.a, minPreviewAlpha)) : swatchColor

    Loader {
        anchors.fill: parent
        active: root.translucent
        sourceComponent: Component {
            Canvas {
                id: checkerboard

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, Math.min(width, height) / 2, 0, 2 * Math.PI);
                    ctx.clip();
                    const s = Math.max(Style.spacingXXS, Math.round(width / 4));
                    for (let y = 0; y < height; y += s) {
                        for (let x = 0; x < width; x += s) {
                            ctx.fillStyle = (((x / s) + (y / s)) % 2 === 0) ? Style.surfaceContainerLowest : Style.surfaceContainerHighest;
                            ctx.fillRect(x, y, s, s);
                        }
                    }
                }
                onVisibleChanged: if (visible)
                    requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Connections {
                    target: Style
                    function onSurfaceContainerLowestChanged() {
                        checkerboard.requestPaint();
                    }
                    function onSurfaceContainerHighestChanged() {
                        checkerboard.requestPaint();
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: root.displayColor
        border.color: root.ringColor
        border.width: Style.outlineWidth
    }
}
