import QtQuick
import qs.DankCommon.Common

Item {
    id: root

    required property var controls
    property string title: ""
    property real titleFontSize: Style.fontSizeLarge
    property bool wrapTitle: false
    property real horizontalPadding: -1
    property real verticalPadding: Style.spacingS
    property bool showDivider: true
    property string subtitle: ""
    property string iconName: ""
    property bool closeEnabled: true
    property string closeTooltipText: I18n.tr("Close")
    default property alias actions: extraActions.data

    signal closeRequested

    implicitHeight: Math.max(Style.buttonHeightXS, titleColumn.implicitHeight) + verticalPadding * 2
    height: implicitHeight
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    component WindowButton: DankActionButton {
        buttonSize: Style.buttonHeightXS
        backgroundColor: Style.foregroundColor(Style.surfaceContainerHigh, Style.isFloatingWindow(root))
        iconSize: Style.iconSizeSmall
        iconColor: Style.surfaceText
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: buttons.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: Style.spacingM
        enabled: root.controls !== null
        onPressed: root.controls.tryStartMove()
        onDoubleClicked: root.controls.tryToggleMaximize()
    }

    Row {
        id: titleRow
        anchors.left: parent.left
        anchors.leftMargin: root.horizontalPadding >= 0 ? root.horizontalPadding : root.verticalPadding
        anchors.right: buttons.left
        anchors.rightMargin: root.horizontalPadding >= 0 ? root.horizontalPadding : Style.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacingM

        DankIcon {
            id: icon
            name: root.iconName
            size: Style.iconSize
            color: Style.primary
            visible: root.iconName !== ""
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            id: titleColumn
            width: Math.max(0, titleRow.width - (icon.visible ? icon.width + titleRow.spacing : 0))
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacingXS

            StyledText {
                width: parent.width
                text: root.title
                font.pixelSize: root.titleFontSize
                font.weight: Font.Medium
                color: Style.surfaceText
                horizontalAlignment: Text.AlignLeft
                elide: root.wrapTitle ? Text.ElideNone : Text.ElideRight
                wrapMode: root.wrapTitle ? Text.Wrap : Text.NoWrap
            }

            StyledText {
                width: parent.width
                text: root.subtitle
                font.pixelSize: Style.fontSizeSmall
                color: Style.surfaceTextMedium
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                visible: text !== ""
            }
        }
    }

    Row {
        id: buttons
        anchors.right: parent.right
        anchors.rightMargin: root.horizontalPadding >= 0 ? root.horizontalPadding : root.verticalPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacingS

        Row {
            id: extraActions
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacingS
        }

        WindowButton {
            visible: root.controls?.canMinimize ?? false
            iconName: "minimize"
            tooltipText: I18n.tr("Minimize")
            onClicked: root.controls.tryMinimize()
        }

        WindowButton {
            visible: root.controls?.canMaximize ?? false
            iconName: root.controls?.targetWindow?.maximized ? "fullscreen_exit" : "fullscreen"
            tooltipText: root.controls?.targetWindow?.maximized ? I18n.tr("Restore") : I18n.tr("Maximize")
            onClicked: root.controls.tryToggleMaximize()
        }

        WindowButton {
            enabled: root.closeEnabled
            iconName: "close"
            tooltipText: root.closeTooltipText
            onClicked: root.closeRequested()
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.showDivider
        height: Style.dividerWidth
        color: Style.outlineVariant
    }
}
