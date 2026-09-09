import QtQuick
import qs.DankCommon.Common

StyledButton {
    id: root

    property bool busy: false
    property string reserveText: ""
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

    radius: Style.buttonRadius(width, height, buttonHeight, pressed, shape === "round")
    color: enabled ? backgroundColor : Style.onSurface_12
    scale: (enableScaleAnimation && pressed) ? Style.pressScale : 1.0
    Accessible.role: Accessible.Button
    Accessible.name: text

    FocusRing {
        visible: root.visualFocus
        radius: Math.max(0, parent.radius + 2 * Style.focusRingWidth)
    }

    Behavior on radius {
        enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
        DankAnim {
            duration: Style.expressiveDurations.expressiveEffects
            easing.bezierCurve: Style.expressiveCurves.standard
        }
    }

    Behavior on scale {
        enabled: enableScaleAnimation && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
        DankAnim {
            duration: Style.expressiveDurations.expressiveFastSpatial
            easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
        }
    }

    StateLayer {
        id: stateLayer
        control: root
        enabled: root.enabled
        disabled: !root.enabled
        stateColor: root.textColor
        enableRipple: root.enableRipple
        transitionDuration: Style.expressiveDurations.expressiveEffects
        transitionCurve: Style.expressiveCurves.expressiveEffects
    }

    TextMetrics {
        id: reservedLabel
        text: root.reserveText
        font.pixelSize: Style.fontSizeMedium
        font.weight: Font.Medium
        font.family: Style.fontFamily
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

        Item {
            width: root.iconSize
            height: root.iconSize
            visible: root.busy || root.iconName !== ""
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                name: root.iconName
                size: root.iconSize
                color: root.contentColor
                visible: !root.busy
            }
            Loader {
                anchors.fill: parent
                active: root.busy
                sourceComponent: DankSpinner {
                    size: root.iconSize
                    strokeWidth: Style.outlineWidthFocused
                    color: root.contentColor
                    running: root.busy && root.visible
                    Accessible.ignored: true
                }
            }
        }

        StyledText {
            width: Math.min(Math.max(implicitWidth, reservedLabel.advanceWidth), Math.max(0, root.maximumWidth - root.horizontalPadding * 2 - (root.busy || root.iconName ? root.iconSize + contentRow.spacing : 0)))
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
