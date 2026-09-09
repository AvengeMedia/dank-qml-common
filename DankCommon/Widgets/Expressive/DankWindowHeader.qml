import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets as Base

Item {
    id: root

    required property var controls
    property string title: ""
    property string iconName: ""
    default property alias actions: extraActions.data

    signal closeRequested

    implicitHeight: Style.buttonHeightXS + Style.spacingS * 2
    height: implicitHeight
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    MouseArea {
        anchors.fill: parent
        onPressed: root.controls.tryStartMove()
        onDoubleClicked: root.controls.tryToggleMaximize()
    }

    Row {
        id: titleRow
        anchors.left: parent.left
        anchors.leftMargin: Style.spacingL
        anchors.right: buttons.left
        anchors.rightMargin: Style.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacingM

        Base.DankIcon {
            id: icon
            name: root.iconName
            size: Style.iconSize
            color: Style.primary
            visible: root.iconName !== ""
            anchors.verticalCenter: parent.verticalCenter
        }

        Base.StyledText {
            width: Math.max(0, titleRow.width - (icon.visible ? icon.width + titleRow.spacing : 0))
            text: root.title
            font.pixelSize: Style.fontSizeLarge
            font.weight: Font.Medium
            color: Style.surfaceText
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        id: buttons
        anchors.right: parent.right
        anchors.rightMargin: Style.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacingS

        Row {
            id: extraActions
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacingS
            visible: children.length > 0
        }

        DankActionButton {
            visible: root.controls.canMaximize
            buttonSize: Style.buttonHeightXS
            backgroundColor: Style.foregroundColor(Style.surfaceContainerHigh, Style.isFloatingWindow(root))
            iconName: root.controls.targetWindow.maximized ? "fullscreen_exit" : "fullscreen"
            tooltipText: root.controls.targetWindow.maximized ? I18n.tr("Restore") : I18n.tr("Maximize")
            iconSize: Style.iconSizeSmall
            iconColor: Style.surfaceText
            onClicked: root.controls.tryToggleMaximize()
        }

        DankActionButton {
            buttonSize: Style.buttonHeightXS
            backgroundColor: Style.foregroundColor(Style.surfaceContainerHigh, Style.isFloatingWindow(root))
            iconName: "close"
            tooltipText: I18n.tr("Close")
            iconSize: Style.iconSizeSmall
            iconColor: Style.surfaceText
            onClicked: root.closeRequested()
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Style.dividerWidth
        color: Style.outlineVariant
    }
}
