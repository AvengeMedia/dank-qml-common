import QtQuick
import qs.DankCommon.Common

Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: parent.radius + 4
    color: "transparent"
    border.width: 2
    border.color: Style.primary
    visible: parent.activeFocus
}
