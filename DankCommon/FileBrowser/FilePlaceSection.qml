pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

Column {
    id: section

    property string title: ""
    property string emptyText: ""
    property bool showEmpty: false

    default property alias rows: body.data

    spacing: Style.spacingXXS

    StyledText {
        text: section.title
        color: Style.primary
        font.pixelSize: Style.fontSizeMedium
        font.weight: Style.fontWeightMedium
        leftPadding: Style.spacingM
        bottomPadding: Style.spacingXXS
    }

    Column {
        id: body

        width: section.width
        spacing: Style.spacingXXS
    }

    StyledText {
        width: section.width
        visible: section.showEmpty && section.emptyText !== ""
        text: section.emptyText
        color: Style.surfaceVariantText
        font.pixelSize: Style.fontSizeSmall
        leftPadding: Style.spacingM
        rightPadding: Style.spacingM
        wrapMode: Text.Wrap
    }
}
