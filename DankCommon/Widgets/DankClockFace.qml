import QtQuick
import qs.DankCommon.Common

Item {
    id: root

    property string hours: "00"
    property string minutes: "00"
    property string seconds: ""
    property string dateText: ""
    property bool stacked: false
    property color color: Style.primary
    property color supportingColor: Style.onSurfaceVariant

    readonly property bool tall: height > Style.buttonHeightM * 2
    readonly property bool vertical: tall && (stacked || height > width * 0.6)
    readonly property string supportText: [dateText, vertical ? seconds : ""].filter(s => s !== "").join(" · ")
    readonly property bool hasSupport: supportText !== ""
    readonly property real supportLine: Style.fontSizeMedium * 1.5
    readonly property real supportNatural: hasSupport ? supportMetrics.advanceWidth + Style.spacingS : 0
    readonly property bool sideFits: hasSupport && width - supportNatural >= Style.fontSizeDisplay * 3
    readonly property bool sideSupport: sideFits && (vertical ? width >= height * 1.1 : !tall)
    readonly property bool belowSupport: hasSupport && !sideSupport
    readonly property real supportHeight: belowSupport ? supportLine + Style.spacingS : 0
    readonly property real sideWidth: sideSupport ? supportNatural : 0
    readonly property real digitsWidth: width - sideWidth
    readonly property real digitsHeight: height - supportHeight
    readonly property bool inlineSeconds: seconds !== "" && !vertical && digitsWidth >= Style.fontSizeDisplay * 5
    readonly property string timeText: hours + ":" + minutes + (inlineSeconds ? ":" + seconds : "")
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

    StyledText {
        id: support
        visible: root.hasSupport
        x: root.sideSupport ? root.digitsWidth + Style.spacingS : 0
        y: root.sideSupport ? (root.height - height) / 2 : root.digitsHeight + Style.spacingS
        width: root.sideSupport ? root.sideWidth - Style.spacingS : root.width
        height: root.supportLine
        text: root.supportText
        color: root.supportingColor
        font.pixelSize: Style.fontSizeMedium
        font.weight: Style.fontWeightMedium
        minimumPixelSize: Style.fontSizeSmall
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: root.sideSupport ? Text.AlignLeft : Text.AlignHCenter
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
    }

    TextMetrics {
        id: supportMetrics
        font: support.font
        text: root.supportText
    }

    component Digits: StyledText {
        width: parent.width
        height: root.rowHeight
        color: root.color
        font.pixelSize: root.displaySize
        // only Normal resolves to the variable face, other weights pick axis-less static instances
        font.weight: Font.Normal
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
}
