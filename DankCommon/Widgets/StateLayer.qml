import QtQuick
import qs.DankCommon.Common

MouseArea {
    id: root

    property bool disabled: false
    property color stateColor: Style.surfaceText
    property real cornerRadius: parent && parent.radius !== undefined ? parent.radius : Style.cornerRadius
    property real topLeftRadius: cornerRadius
    property real topRightRadius: cornerRadius
    property real bottomLeftRadius: cornerRadius
    property real bottomRightRadius: cornerRadius
    property var tooltipText: null
    property string tooltipSide: "bottom"
    property bool enableRipple: Style.enableRippleEffects
    property int transitionDuration: Style.shorterDuration
    property var transitionCurve: Style.expressiveCurves.standardDecel

    readonly property real stateOpacity: disabled ? 0 : pressed ? Style.stateLayerPressed : containsMouse ? Style.stateLayerHover : 0

    anchors.fill: parent
    cursorShape: disabled ? undefined : Qt.PointingHandCursor
    hoverEnabled: true

    onPressed: mouse => {
        if (!disabled && enableRipple) {
            rippleLayer.trigger(mouse.x, mouse.y);
        }
    }

    Rectangle {
        id: stateRect
        anchors.fill: parent
        radius: root.cornerRadius
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        color: Style.withAlpha(stateColor, stateOpacity)

        Behavior on color {
            enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
            DankColorAnim {
                duration: root.transitionDuration
                easing.bezierCurve: root.transitionCurve
            }
        }
    }

    DankRipple {
        id: rippleLayer
        anchors.fill: parent
        rippleColor: root.stateColor
        cornerRadius: root.cornerRadius
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        enableRipple: root.enableRipple
    }

    onEntered: tooltipLoader.item?.schedule()
    onExited: tooltipLoader.item?.dismiss()

    onVisibleChanged: {
        if (!visible)
            tooltipLoader.item?.dismiss();
    }

    onTooltipTextChanged: {
        if (!tooltipText)
            tooltipLoader.item?.dismiss();
    }

    onDisabledChanged: {
        if (disabled)
            tooltipLoader.item?.dismiss();
    }

    Component.onDestruction: tooltipLoader.item?.dismiss()

    Loader {
        id: tooltipLoader
        active: !!root.tooltipText
        sourceComponent: DankTooltipV2 {
            id: tooltip

            function schedule() {
                hoverDelay.restart();
            }

            function dismiss() {
                hoverDelay.stop();
                hide();
            }

            Timer {
                id: hoverDelay
                interval: 400
                onTriggered: tooltip.show(root.tooltipText, root, 0, 0, root.tooltipSide)
            }
        }
    }
}
