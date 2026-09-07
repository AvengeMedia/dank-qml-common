import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets as Base

Rectangle {
    id: root

    property string text: ""
    property real maximumWidth: Infinity
    property bool wrapText: false
    property string iconName: ""
    property int iconSize: Style.iconSizeMedium
    property bool hovered: stateLayer.containsMouse
    property bool pressed: stateLayer.pressed
    property color backgroundColor: Style.buttonBg
    property color textColor: Style.buttonText
    property int buttonHeight: Style.buttonHeightS
    property int horizontalPadding: buttonHeight >= Style.buttonHeightM ? Style.spacingXL : Style.spacingL
    property bool enableScaleAnimation: false
    property bool enableRipple: Style.enableRippleEffects
    property real minimumWidth: Style.buttonMinWidth

    signal clicked

    width: Math.min(maximumWidth, Math.max(contentRow.implicitWidth + horizontalPadding * 2, minimumWidth))
    height: wrapText ? Math.max(buttonHeight, contentRow.implicitHeight + Style.spacingS * 2) : buttonHeight
    readonly property color contentColor: enabled ? textColor : Style.onSurface_38
    readonly property real pressedRadius: buttonHeight >= Style.buttonHeightM ? Style.cornerRadiusM : Style.cornerRadiusS

    radius: pressed ? pressedRadius : height / 2
    color: enabled ? backgroundColor : Style.onSurface_12
    scale: (enableScaleAnimation && pressed) ? Style.pressScale : 1.0
    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: {
        if (enabled)
            clicked();
    }

    Keys.onPressed: event => {
        if (!root.enabled)
            return;
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.clicked();
            event.accepted = true;
            break;
        }
    }

    Base.FocusRing {
        anchors.margins: Style.focusRingWidth / 2
        radius: Math.max(0, parent.radius - Style.focusRingWidth / 2)
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
        enabled: root.enabled
        disabled: !root.enabled
        stateColor: root.textColor
        enableRipple: root.enableRipple
        transitionDuration: Style.expressiveDurations.expressiveEffects
        transitionCurve: Style.expressiveCurves.expressiveEffects
        onClicked: root.clicked()
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Style.spacingS

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
