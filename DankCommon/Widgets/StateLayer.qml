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
    property real topLeftRadius: parent && parent.topLeftRadius !== undefined ? parent.topLeftRadius : cornerRadius
    property real topRightRadius: parent && parent.topRightRadius !== undefined ? parent.topRightRadius : cornerRadius
    property real bottomLeftRadius: parent && parent.bottomLeftRadius !== undefined ? parent.bottomLeftRadius : cornerRadius
    property real bottomRightRadius: parent && parent.bottomRightRadius !== undefined ? parent.bottomRightRadius : cornerRadius
    property var tooltipText: null
    property string tooltipSide: "bottom"
    property bool enableRipple: Style.enableRippleEffects
    property int transitionDuration: Style.shorterDuration
    property var transitionCurve: Style.expressiveCurves.standardDecel

    readonly property real stateOpacity: disabled ? 0 : (control ? control.down : pressed) ? Style.stateLayerPressed : hovered ? Style.stateLayerHover : 0
    readonly property bool controlPressed: control ? control.pressed : false

    anchors.fill: parent
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    hoverEnabled: true
    acceptedButtons: control ? Qt.NoButton : Qt.LeftButton

    readonly property bool controlFocused: control ? control.visualFocus : false

    function showTooltip() {
        tooltipLoader.item?.showNow();
    }

    onPressed: mouse => {
        if (!disabled && enableRipple) {
            rippleLayer.trigger(mouse.x, mouse.y);
        }
    }

    onControlPressedChanged: {
        if (!controlPressed || disabled || !enableRipple)
            return;
        const point = mapFromItem(control, control.pressX, control.pressY);
        rippleLayer.trigger(point.x, point.y);
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

    onExited: {
        if (!controlFocused)
            tooltipLoader.item?.dismiss();
    }

    onControlFocusedChanged: {
        if (controlFocused) {
            tooltipLoader.item?.showNow();
            return;
        }
        if (!containsMouse)
            tooltipLoader.item?.dismiss();
    }

    Loader {
        id: tooltipLoader
        active: !!root.tooltipText
        sourceComponent: DankTooltipHost {
            text: root.tooltipText
            target: root
            side: root.tooltipSide
            enabled: !root.disabled
        }
    }
}
