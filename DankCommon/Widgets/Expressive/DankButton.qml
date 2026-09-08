import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets as Base

StyledButton {
    id: root

    property string shape: "round"
    property real maximumWidth: Infinity
    property bool wrapText: false
    property string iconName: ""
    property int iconSize: root.buttonHeight <= Style.buttonHeightS ? Style.iconSizeMedium : Style.iconSize
    property color backgroundColor: Style.buttonBg
    property color textColor: Style.buttonText
    property int buttonHeight: Style.buttonHeightS
    horizontalPadding: {
        if (buttonHeight <= Style.buttonHeightXS)
            return Style.spacingM;
        if (buttonHeight <= Style.buttonHeightS)
            return Style.spacingL;
        return Style.spacingXL;
    }
    property bool enableScaleAnimation: false
    property bool enableRipple: Style.enableRippleEffects
    property real minimumWidth: Style.buttonMinWidth

    implicitWidth: Math.min(maximumWidth, Math.max(contentRow.implicitWidth + horizontalPadding * 2, minimumWidth))
    implicitHeight: wrapText ? Math.max(buttonHeight, contentRow.implicitHeight + Style.spacingS * 2) : buttonHeight
    readonly property color contentColor: enabled ? textColor : Style.onSurface_38

    radius: {
        if (pressed)
            return buttonHeight >= Style.buttonHeightM ? Style.cornerRadiusM : Style.cornerRadiusS;
        if (shape === "round")
            return Math.min(Style.cornerRadiusFull, height / 2);
        if (buttonHeight <= Style.buttonHeightS)
            return Style.spacingM;
        if (buttonHeight <= Style.buttonHeightM)
            return Style.spacingL;
        return Style.spacingXL + Style.spacingXS;
    }
    color: enabled ? backgroundColor : Style.onSurface_12
    scale: (enableScaleAnimation && pressed) ? Style.pressScale : 1.0
    Accessible.role: Accessible.Button
    Accessible.name: text

    Base.FocusRing {
        visible: root.visualFocus
        radius: Math.max(0, parent.radius + 2 * Style.focusRingWidth)
    }

    Behavior on radius {
        enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
        DankAnim {
            duration: Style.expressiveDurations.expressiveEffects
            easing.bezierCurve: Style.expressiveCurves.standard
        }
    }

    Behavior on scale {
        enabled: enableScaleAnimation && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
        DankAnim {
            duration: Style.expressiveDurations.expressiveFastSpatial
            easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
        }
    }

    Base.StateLayer {
        id: stateLayer
        control: root
        enabled: root.enabled
        disabled: !root.enabled
        stateColor: root.textColor
        enableRipple: root.enableRipple
        transitionDuration: Style.expressiveDurations.expressiveEffects
        transitionCurve: Style.expressiveCurves.expressiveEffects
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: {
            if (buttonHeight <= Style.buttonHeightXS) {
                return Style.spacingXS;
            } else if (buttonHeight <= Style.buttonHeightM) {
                return Style.spacingS;
            } else {
                return Style.spacingM;
            }
        }

        Base.DankIcon {
            name: root.iconName
            size: root.iconSize
            color: root.contentColor
            visible: root.iconName !== ""
            anchors.verticalCenter: parent.verticalCenter
        }

        Base.StyledText {
            width: Math.min(implicitWidth, Math.max(0, root.maximumWidth - root.horizontalPadding * 2 - (root.iconName ? root.iconSize + contentRow.spacing : 0)))
            wrapMode: root.wrapText ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap
            elide: root.wrapText ? Text.ElideNone : Text.ElideRight
            text: root.text
            font.pixelSize: Style.fontSizeMedium
            font.weight: Font.Medium
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
