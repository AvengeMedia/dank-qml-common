pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

StyledButton {
    id: pill

    property string label: ""
    property string iconName: ""
    property bool current: false
    property color chipColor: Style.chipSurface

    readonly property color contentColor: current ? Style.onPrimaryContainer : Style.surfaceText

    implicitWidth: row.implicitWidth + FileBrowserMetrics.pathPillPadding * 2
    implicitHeight: FileBrowserMetrics.pathPillHeight
    radius: FileBrowserMetrics.pathPillRadius
    color: current ? Style.primaryContainer : chipColor
    Accessible.name: label

    StateLayer {
        control: pill
        stateColor: pill.contentColor
    }

    FocusRing {
        anchors.margins: 0
        radius: pill.radius
        visible: pill.visualFocus
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: FileBrowserMetrics.pathPillSpacing

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: pill.iconName !== ""
            name: pill.iconName
            size: FileBrowserMetrics.pathIconSize
            color: pill.current ? pill.contentColor : Style.primary
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: pill.label !== ""
            text: pill.label
            color: pill.contentColor
            font.pixelSize: Style.fontSizeMedium
            font.weight: Style.fontWeightMedium
        }
    }
}
