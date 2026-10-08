import QtQuick
import QtQuick.Window
import qs.DCommon.Common
import "../Common/Surface.js" as Surface

// Fading edges for a vertical Flickable, drawn as gradients in the color of the nearest painted
// ancestor surface. Each strip ramps in with scroll distance like Android's View fading edge.
Item {
    id: root

    required property Flickable target
    property real length: Style.spacingXL
    property real radius: Style.groupedListOuterRadius

    readonly property var surfaceHost: resolveSurfaceHost()
    readonly property color color: {
        const host = surfaceHost;
        if (!host)
            return Surface.isFloatingWindow(target) ? Style.floatingWindowSurface : Style.hostSurface;
        if (host.surfaceColor !== undefined)
            return host.surfaceColor;
        if (host.backgroundColor !== undefined)
            return host.backgroundColor;
        return host.color;
    }
    readonly property color clear: Style.withAlpha(color, 0)
    // Over an opaque surface the strip is the surface itself; over a translucent one it reads as a shadow, so it takes the row shape
    readonly property real cornerRadius: color.a < 1 ? radius : 0
    readonly property real topStrength: Math.min(1, Math.max(0, (target.contentY - target.originY) / length))
    readonly property real bottomStrength: Math.min(1, Math.max(0, (target.originY + target.contentHeight - target.height - target.contentY) / length))

    function resolveSurfaceHost() {
        for (let current = target.parent; current; current = current.parent) {
            if (current.surfaceColor !== undefined || current.backgroundColor !== undefined)
                return current;
            if (current instanceof Rectangle && current.color.a >= 0.5)
                return current;
        }
        const window = root.Window.window;
        if (window && (window.surfaceColor !== undefined || window.backgroundColor !== undefined))
            return window;
        return null;
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.length
        topLeftRadius: root.cornerRadius
        topRightRadius: root.cornerRadius
        opacity: root.topStrength
        visible: opacity > 0
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.color
            }
            GradientStop {
                position: 1
                color: root.clear
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.length
        bottomLeftRadius: root.cornerRadius
        bottomRightRadius: root.cornerRadius
        opacity: root.bottomStrength
        visible: opacity > 0
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.clear
            }
            GradientStop {
                position: 1
                color: root.color
            }
        }
    }
}
