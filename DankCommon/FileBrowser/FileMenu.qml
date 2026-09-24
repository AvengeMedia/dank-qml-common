pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.DankCommon.Common
import qs.DankCommon.Widgets

Popup {
    id: root

    property Item anchorItem: parent
    default property alias rows: column.children

    readonly property bool motionEnabled: FileBrowserMetrics.animationsEnabled

    function openAt(pointX, pointY) {
        const limits = anchorItem ?? parent;
        x = Math.max(0, Math.min(pointX, (limits?.width ?? width) - width));
        y = Math.max(0, Math.min(pointY, (limits?.height ?? height) - height));
        open();
    }

    width: FileBrowserMetrics.menuWidth
    padding: Style.spacingXS
    modal: true
    dim: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Item {
        ElevationShadow {
            anchors.fill: parent
            level: Style.elevationLevel2
            fallbackOffset: Style.spacingXS
            targetRadius: Style.cornerRadiusL
            targetColor: Style.surfaceContainer
            borderColor: Style.outlineMedium
            borderWidth: Style.layerOutlineWidth
            shadowEnabled: Style.elevationEnabled && Style.popoutElevationEnabled
        }
    }

    contentItem: Column {
        id: column

        spacing: 0
    }

    enter: Transition {
        enabled: root.motionEnabled

        DankAnim {
            property: "opacity"
            from: 0
            to: 1
            duration: Style.expressiveDurations.expressiveEffects
            easing.bezierCurve: Style.expressiveCurves.expressiveEffects
        }

        DankAnim {
            property: "scale"
            from: Style.popupEnterScale
            to: 1
            duration: Style.expressiveDurations.expressiveFastSpatial
            easing.bezierCurve: Style.expressiveCurves.expressiveDefaultSpatial
        }
    }

    exit: Transition {
        enabled: root.motionEnabled

        DankAnim {
            property: "opacity"
            from: 1
            to: 0
            duration: Style.shorterDuration
            easing.bezierCurve: Style.expressiveCurves.expressiveEffects
        }
    }
}
