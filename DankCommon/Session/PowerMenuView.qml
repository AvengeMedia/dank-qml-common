pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.DankCommon.Common
import qs.DankCommon.Widgets as Base

Rectangle {
    id: root

    property var actions: []
    property var actionProvider: null
    property bool gridLayout: false
    property int gridColumns: 1
    property int selectedIndex: 0
    property int holdActionIndex: -1
    property real holdProgress: 0
    property bool showHint: false
    property bool hintWarning: false
    property string hintText: ""
    property string hintIcon: "touch_app"
    readonly property real desiredWidth: gridLayout ? Math.min(LockMetrics.powerGridWidth, Math.max(1, gridColumns) * LockMetrics.powerGridColumnWidth + Style.spacingS * (Math.max(1, gridColumns) - 1) + Style.spacingL * 2) : LockMetrics.powerMenuWidth

    signal actionPressed(int index)
    signal actionReleased
    signal actionCanceled

    implicitWidth: desiredWidth
    implicitHeight: buttons.implicitHeight + Style.spacingL * 2 + (showHint ? hint.implicitHeight + Style.spacingM : 0)
    color: Style.surfaceContainerHigh
    radius: Style.windowRadius
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    Grid {
        id: buttons
        x: Style.spacingL
        y: Style.spacingL
        width: parent.width - Style.spacingL * 2
        columns: root.gridLayout ? Math.max(1, root.gridColumns) : 1
        spacing: Style.spacingS

        Repeater {
            model: root.actions

            Rectangle {
                id: button
                required property int index
                required property string modelData
                readonly property var actionData: root.actionProvider ? root.actionProvider(modelData) : ({})
                readonly property bool selected: root.selectedIndex === index
                readonly property bool holding: root.holdActionIndex === index && root.holdProgress > 0
                readonly property bool warningAction: modelData === "reboot" || modelData === "softreboot" || modelData === "poweroff"
                readonly property color contentColor: warningAction && (stateLayer.containsMouse || holding) ? (modelData === "poweroff" ? Style.error : Style.warning) : selected ? Style.onPrimaryContainer : Style.onSecondaryContainer
                width: (buttons.width - buttons.spacing * (buttons.columns - 1)) / buttons.columns
                height: root.gridLayout ? Math.max(LockMetrics.powerGridButtonHeight, label.implicitHeight + icon.height + keycap.height + Style.spacingS * 4) : Math.max(LockMetrics.powerButtonHeight, label.implicitHeight + Style.spacingM * 2)
                radius: stateLayer.pressed || holding ? Style.cornerRadiusM : root.gridLayout ? Style.cornerRadiusXL : Style.fullRadius(width, height)
                color: selected ? Style.primaryContainer : Style.secondaryContainer
                border.width: selected ? Style.focusRingWidth : 0
                border.color: Style.focusRingColor
                Accessible.role: Accessible.Button
                Accessible.name: actionData.label || ""
                Accessible.focused: selected && root.visible

                Behavior on radius {
                    NumberAnimation {
                        duration: LockMetrics.effectsDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                    }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: button.radius
                    color: "transparent"
                    visible: button.holding

                    Rectangle {
                        anchors.left: parent.left
                        height: parent.height
                        width: parent.width * root.holdProgress
                        color: Style.withAlpha(button.contentColor, Style.stateLayerPressed)
                    }
                }

                Base.DankIcon {
                    id: icon
                    x: root.gridLayout ? (parent.width - width) / 2 : I18n.isRtl ? parent.width - width - Style.spacingM : Style.spacingM
                    y: root.gridLayout ? Style.spacingS : (parent.height - height) / 2
                    name: button.actionData.icon || ""
                    size: Style.iconSizeMedium
                    color: button.contentColor
                }

                Base.StyledText {
                    id: label
                    x: root.gridLayout ? Style.spacingS : I18n.isRtl ? keycap.x + keycap.width + Style.spacingM : icon.x + icon.width + Style.spacingM
                    y: root.gridLayout ? icon.y + icon.height + Style.spacingS : (parent.height - height) / 2
                    width: root.gridLayout ? parent.width - Style.spacingS * 2 : parent.width - icon.width - keycap.width - Style.spacingM * 4
                    text: button.actionData.label || ""
                    textFormat: Text.PlainText
                    font.pixelSize: Style.fontSizeMedium
                    font.weight: Font.Medium
                    color: button.contentColor
                    horizontalAlignment: root.gridLayout ? Text.AlignHCenter : I18n.isRtl ? Text.AlignRight : Text.AlignLeft
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    id: keycap
                    x: root.gridLayout ? (parent.width - width) / 2 : I18n.isRtl ? Style.spacingM : parent.width - width - Style.spacingM
                    y: root.gridLayout ? label.y + label.height + Style.spacingS : (parent.height - height) / 2
                    width: keyText.implicitWidth + Style.spacingS * 2
                    height: visible ? keyText.implicitHeight + Style.spacingXXS * 2 : 0
                    radius: Style.cornerRadiusXS
                    color: Style.withAlpha(button.contentColor, Style.stateLayerPressed)
                    visible: !!button.actionData.key

                    Base.StyledText {
                        id: keyText
                        anchors.centerIn: parent
                        text: button.actionData.key || ""
                        font.pixelSize: Style.fontSizeSmall
                        color: button.contentColor
                    }
                }

                Base.StateLayer {
                    id: stateLayer
                    stateColor: button.contentColor
                    cornerRadius: button.radius
                    transitionDuration: LockMetrics.effectsDuration
                    transitionCurve: Style.expressiveCurves.expressiveEffects
                    onPressed: root.actionPressed(button.index)
                    onReleased: root.actionReleased()
                    onCanceled: root.actionCanceled()
                }
            }
        }
    }

    Row {
        id: hint
        anchors.top: buttons.bottom
        anchors.topMargin: Style.spacingM
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - Style.spacingL * 2, hintLabel.implicitWidth + hintSymbol.width + spacing)
        spacing: Style.spacingXS
        visible: root.showHint

        Base.DankIcon {
            id: hintSymbol
            name: root.hintIcon
            size: Style.iconSizeSmall
            color: root.hintWarning ? Style.warning : Style.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        Base.StyledText {
            id: hintLabel
            width: parent.width - hintSymbol.width - parent.spacing
            text: root.hintText
            font.pixelSize: Style.fontSizeSmall
            color: root.hintWarning ? Style.warning : Style.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
            wrapMode: Text.WordWrap
        }
    }
}
