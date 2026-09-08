import QtQuick
import QtQuick.Templates as T
import qs.DankCommon.Common

MouseArea {
    id: root

    property bool disabled: false
    property bool hovered: control ? control.hovered : containsMouse
    property T.AbstractButton control: null
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

    readonly property real stateOpacity: disabled ? 0 : (control ? control.down : pressed) ? Style.stateLayerPressed : hovered ? Style.stateLayerHover : 0

    anchors.fill: parent
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    hoverEnabled: true
    acceptedButtons: control ? Qt.NoButton : Qt.LeftButton

    function showTooltip() {
        tooltipLoader.item?.showNow();
    }

    onPressed: mouse => {
        if (!disabled && enableRipple) {
            rippleLayer.trigger(mouse.x, mouse.y);
        }
    }

    Connections {
        target: root.control
        function onPressedChanged() {
            if (!root.control.pressed || root.disabled || !root.enableRipple)
                return;
            const point = root.mapFromItem(root.control, root.control.pressX, root.control.pressY);
            rippleLayer.trigger(point.x, point.y);
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
            enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
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
        if (!tooltipText) {
            tooltipLoader.item?.dismiss();
            return;
        }
        tooltipLoader.item?.refresh();
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

            property bool shown: false

            function showNow() {
                if (root.disabled || !root.visible || !root.tooltipText)
                    return;
                hoverDelay.stop();
                show(root.tooltipText, root, 0, 0, root.tooltipSide);
                shown = true;
            }

            function refresh() {
                if (shown)
                    showNow();
            }

            function schedule() {
                hoverDelay.restart();
            }

            function dismiss() {
                hoverDelay.stop();
                hide();
                shown = false;
            }

            Timer {
                id: hoverDelay
                interval: 400
                onTriggered: tooltip.showNow()
            }
        }
    }
}
