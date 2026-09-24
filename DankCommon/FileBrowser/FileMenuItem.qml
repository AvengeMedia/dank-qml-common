pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

StyledButton {
    id: root

    property string iconName: ""
    property bool submenu: false
    property bool danger: false

    readonly property color contentColor: {
        if (!enabled)
            return Style.onSurface_38;
        return danger ? Style.error : Style.surfaceText;
    }
    readonly property color iconColor: {
        if (!enabled)
            return Style.onSurface_38;
        return danger ? Style.error : Style.surfaceVariantText;
    }

    signal entered

    width: parent?.width ?? 0
    implicitHeight: Style.menuItemHeight
    radius: Style.cornerRadiusS
    color: "transparent"
    onHoveredChanged: {
        if (hovered)
            root.entered();
    }

    StateLayer {
        control: root
        disabled: !root.enabled
        hovered: root.hovered
        stateColor: root.contentColor
    }

    FocusRing {
        visible: root.visualFocus
        anchors.margins: Style.focusRingWidth / 2
        radius: Math.max(0, root.radius - Style.focusRingWidth / 2)
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Style.spacingM
        anchors.rightMargin: Style.spacingM
        spacing: Style.spacingM

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.iconName !== ""
            name: root.iconName
            size: Style.iconSizeMedium
            color: root.iconColor
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (root.iconName !== "" ? Style.iconSizeMedium + parent.spacing : 0) - (root.submenu || root.checked ? Style.iconSizeMedium + Style.spacingM : 0)
            text: root.text
            color: root.contentColor
            font.pixelSize: Style.fontSizeMedium
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
        }
    }

    DankIcon {
        anchors.right: parent.right
        anchors.rightMargin: Style.spacingM
        anchors.verticalCenter: parent.verticalCenter
        visible: root.submenu || root.checked
        name: root.submenu ? "chevron_right" : "check"
        size: Style.iconSizeMedium
        color: root.submenu ? Style.surfaceVariantText : Style.primary
    }
}
