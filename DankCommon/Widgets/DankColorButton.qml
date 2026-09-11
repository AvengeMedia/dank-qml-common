import QtQuick
import qs.DankCommon.Common

StyledButton {
    id: root

    property color swatchColor: "transparent"
    property bool selected: false

    implicitWidth: Style.iconButtonSize
    implicitHeight: implicitWidth
    radius: Style.fullRadius(width, height)
    Accessible.name: swatchColor.toString()
    Accessible.role: Accessible.RadioButton
    Accessible.checkable: true
    Accessible.checked: selected
    Accessible.onToggleAction: {
        if (enabled)
            click();
    }

    DankColorSwatch {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height) - Style.spacingS
        height: width
        swatchColor: root.swatchColor
        minPreviewAlpha: 0
        ringColor: Style.outlineVariant
        visible: root.enabled
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height) - Style.spacingS
        height: width
        radius: Style.fullRadius(width, height)
        color: Style.onSurface_12
        visible: !root.enabled
    }

    Rectangle {
        anchors.centerIn: parent
        width: Style.iconSizeSmall + Style.outlineWidthFocused * 2
        height: width
        radius: Style.fullRadius(width, height)
        color: root.enabled ? Style.primaryContainer : "transparent"
        visible: root.selected

        DankIcon {
            anchors.centerIn: parent
            name: "check"
            size: Style.iconSizeSmall
            color: root.enabled ? Style.onPrimaryContainer : Style.onSurface_38
        }
    }

    StateLayer {
        control: root
        disabled: !root.enabled
        stateColor: Style.onSurface
        tooltipText: root.swatchColor.toString()
    }

    FocusRing {
        visible: root.visualFocus
    }
}
