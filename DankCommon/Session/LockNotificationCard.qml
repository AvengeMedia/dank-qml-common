import QtQuick
import qs.DankCommon.Common

Rectangle {
    property bool firstInGroup: true
    property bool lastInGroup: true

    color: Style.surfaceContainerHigh
    radius: Style.groupedListInnerRadius
    topLeftRadius: firstInGroup ? Style.groupedListOuterRadius : radius
    topRightRadius: topLeftRadius
    bottomLeftRadius: lastInGroup ? Style.groupedListOuterRadius : radius
    bottomRightRadius: bottomLeftRadius
    Accessible.role: Accessible.ListItem
}
