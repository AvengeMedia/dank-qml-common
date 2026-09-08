import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets as Base

StyledButton {
    id: root

    property string iconName: ""
    property int iconSize: Style.iconSizeMedium
    property color iconColor: Style.onSurfaceVariant
    property color backgroundColor: "transparent"
    property color stateColor: iconColor
    property bool circular: true
    property int buttonSize: Style.buttonHeightXS
    property var tooltipText: null
    property string tooltipSide: "bottom"
    property int shapeDuration: Style.expressiveDurations.expressiveEffects
    property var shapeCurve: Style.expressiveCurves.standard
    property int stateDuration: Style.shorterDuration
    property var stateCurve: Style.expressiveCurves.standardDecel

    signal entered
    signal exited

    function showTooltip() {
        stateLayer.showTooltip();
    }

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    radius: pressed ? Math.min(Style.cornerRadiusS, height / 2) : (circular ? Math.min(Style.cornerRadiusFull, height / 2) : Style.cornerRadiusM)
    color: backgroundColor
    Accessible.role: Accessible.Button
    Accessible.name: tooltipText || iconName

    Behavior on radius {
        enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
        DankAnim {
            duration: root.shapeDuration
            easing.bezierCurve: root.shapeCurve
        }
    }

    Base.FocusRing {
        visible: root.visualFocus
        anchors.margins: Style.focusRingWidth / 2
        radius: Math.max(0, parent.radius - Style.focusRingWidth / 2)
    }

    Base.DankIcon {
        anchors.centerIn: parent
        name: root.iconName
        size: root.iconSize
        color: root.enabled ? root.iconColor : Style.onSurface_38
    }

    Base.StateLayer {
        id: stateLayer
        control: root
        disabled: !root.enabled
        stateColor: root.stateColor
        cornerRadius: root.radius
        transitionDuration: root.stateDuration
        transitionCurve: root.stateCurve
        onEntered: root.entered()
        onExited: root.exited()
        tooltipText: root.tooltipText
        tooltipSide: root.tooltipSide
    }
}
