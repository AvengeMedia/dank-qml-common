import QtQuick
import qs.DankCommon.Common

Item {
    id: root

    property string hours: "00"
    property string minutes: "00"
    property string seconds: ""
    property string dateText: ""
    property string dayText: ""
    property bool stacked: false
    property color color: Style.primary
    property color supportingColor: Style.onSurfaceVariant

    readonly property bool tall: height > Style.buttonHeightM * 2
    readonly property bool vertical: tall && (stacked || height > width * 0.6)
    readonly property bool inlineSeconds: seconds !== "" && !vertical && width >= Style.fontSizeDisplay * 5
    readonly property string timeText: hours + ":" + minutes + (inlineSeconds ? ":" + seconds : "")
    readonly property string dayLine: [dayText, vertical ? seconds : ""].filter(s => s !== "").join(" · ")
    readonly property bool hasSupport: dateText !== "" || dayLine !== ""
    readonly property bool sideSupport: vertical && hasSupport && width >= height * 1.1
    readonly property bool belowSupport: hasSupport && tall && !sideSupport
    readonly property real supportLine: Style.fontSizeMedium * 1.5
    readonly property real supportHeight: belowSupport ? (dateText !== "" ? supportLine : 0) + (dayLine !== "" ? supportLine : 0) + Style.spacingS : 0
    readonly property real sideWidth: sideSupport ? Math.max(Style.fontSizeMedium * 6, width * 0.4) : 0
    readonly property real digitsWidth: width - sideWidth
    readonly property real digitsHeight: height - supportHeight
    readonly property real rowHeight: vertical ? (digitsHeight + Style.spacingS) / 2 : digitsHeight
    readonly property real displaySize: rowHeight / 1.05

    implicitWidth: Style.fontSizeDisplay * 6
    implicitHeight: Style.fontSizeDisplay * 4

    Column {
        y: (root.digitsHeight - height) / 2
        width: root.digitsWidth
        spacing: -Style.spacingS

        Digits {
            text: root.vertical ? root.hours : root.timeText
        }

        Digits {
            text: root.minutes
            visible: root.vertical
        }
    }

    Column {
        visible: root.sideSupport || root.belowSupport
        x: root.sideSupport ? root.digitsWidth + Style.spacingS : 0
        y: root.sideSupport ? (root.height - height) / 2 : root.digitsHeight + Style.spacingS
        width: root.sideSupport ? root.sideWidth - Style.spacingS : root.width
        spacing: 0

        Support {
            text: root.dateText
        }

        Support {
            text: root.dayLine
        }
    }

    component Digits: StyledText {
        width: parent.width
        height: root.rowHeight
        color: root.color
        font.pixelSize: root.displaySize
        font.weight: Font.Bold
        font.features: ({
                "tnum": 1
            })
        font.variableAxes: ({
                "ROND": 100,
                "wght": 750,
                "opsz": root.displaySize
            })
        minimumPixelSize: Style.fontSizeLarge
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.NoWrap
        elide: Text.ElideNone
        LayoutMirroring.enabled: false
    }

    component Support: StyledText {
        width: parent.width
        height: root.supportLine
        color: root.supportingColor
        font.pixelSize: Style.fontSizeMedium
        font.weight: Font.Medium
        horizontalAlignment: root.sideSupport ? Text.AlignLeft : Text.AlignHCenter
        elide: Text.ElideRight
        visible: text !== ""
    }
}
