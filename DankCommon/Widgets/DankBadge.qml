import QtQuick
import qs.DankCommon.Common

Rectangle {
    id: root

    property alias text: label.text
    property alias textColor: label.color
    property real maximumWidth: Infinity

    implicitWidth: text ? Math.min(maximumWidth, Math.max(implicitHeight, Math.ceil(label.implicitWidth) + Style.spacingXS * 2)) : implicitHeight
    implicitHeight: text ? Math.max(Style.spacingL, Math.ceil(labelMetrics.tightBoundingRect.height) + Style.spacingXXS * 2) : Style.spacingXS + Style.spacingXXS
    baselineOffset: label.y + label.baselineOffset
    radius: height / 2
    color: Style.primary
    Accessible.role: Accessible.StaticText
    Accessible.name: text

    StyledTextMetrics {
        id: labelMetrics
        font: label.font
        text: label.text
        renderType: label.renderType
    }

    StyledText {
        id: label
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round((root.height - labelMetrics.tightBoundingRect.height) / 2 - baselineOffset - labelMetrics.tightBoundingRect.y)
        width: Math.max(0, root.width - Style.spacingXS * 2)
        font.pixelSize: Style.fontSizeSmall
        font.weight: Style.fontWeightMedium
        color: Style.onPrimary
        wrapMode: Text.NoWrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignTop
        visible: text !== ""
    }
}
