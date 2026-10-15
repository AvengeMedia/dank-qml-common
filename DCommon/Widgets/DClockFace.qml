import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property string hours: "00"
    property string minutes: "00"
    property string seconds: ""
    property string dateText: ""
    property bool stacked: false
    property color color: Style.primary
    property color minutesColor: color
    property color secondsColor: minutesColor
    property color supportingColor: Style.onSurfaceVariant
    property string fontFamily: ""
    property int weight: 0
    property bool rounded: true

    readonly property bool variableFont: fontFamily === "" || fontFamily === Style.defaultFontFamily
    readonly property int digitWeight: weight > 0 ? weight : 750
    readonly property real padding: Style.spacingS

    readonly property bool tall: height > Style.buttonHeightM * 2
    readonly property bool vertical: tall && (stacked || height > width * 0.6)
    readonly property string supportText: [dateText, vertical ? seconds : ""].filter(s => s !== "").join(" · ")
    readonly property bool hasSupport: supportText !== ""
    readonly property real supportHeight: supportText.height
    readonly property real digitsWidth: width
    readonly property real digitsHeight: height - (hasSupport ? supportHeight : 0)
    readonly property bool inlineSeconds: seconds !== "" && !vertical && digitsWidth >= Style.fontSizeDisplay * 5
    readonly property string timeText: hours + ":" + minutes + (inlineSeconds ? ":" + seconds : "")
    readonly property real rowHeight: vertical ? (digitsHeight + Style.spacingS) / 2 : digitsHeight
    readonly property real displaySize: rowHeight
    readonly property real supportDisplaySize: rowHeight / 5

    implicitWidth: Style.fontSizeDisplay * 6
    implicitHeight: root.padding + hoursRowDigits.height + (minutesRow.visible ? minutesRowDigits.height : 0) + (support.visible ? supportText.height : 0)

    function escapedDigits(text) {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    Item {
        id: hoursRow
        width: parent.width
        height: hoursRowDigits.height
        y: root.padding
        baselineOffset: hoursRowDigits.baselineOffset
        Digits {
            id: hoursRowDigits
            readonly property bool accented: !root.vertical && root.minutesColor !== root.color
            textFormat: accented ? Text.StyledText : Text.PlainText
            text: {
                if (root.vertical)
                    return root.hours;
                if (!accented)
                    return root.timeText;
                return `${root.escapedDigits(root.hours + ":")}<font color="${root.minutesColor}">${root.escapedDigits(root.minutes)}</font>${root.inlineSeconds ? `<font color="${root.secondsColor}">:${root.escapedDigits(root.seconds)}</font>` : ""}`;
            }
        }
    }

    Item {
        id: minutesRow
        width: parent.width
        y: hoursRow.y + hoursRow.baselineOffset
        baselineOffset: minutesRowDigits.baselineOffset
        visible: root.vertical

        Digits {
            id: minutesRowDigits
            text: root.minutes
            color: root.minutesColor
        }
    }

    Item {
        id: support
        width: parent.width
        y: (minutesRow.visible ? minutesRow.y + minutesRow.baselineOffset : hoursRow.y + hoursRow.baselineOffset) + supportText.height / 3
        visible: root.hasSupport

        StyledText {
            id: supportText
            width: root.width
            text: root.supportText
            color: root.supportingColor
            font.pixelSize: root.supportDisplaySize
            font.weight: Style.fontWeightMedium
            minimumPixelSize: Style.fontSizeSmall
            fontSizeMode: Text.HorizontalFit
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
    }

    component Digits: StyledText {
        width: parent.width
        height: root.rowHeight
        color: root.color
        font.pixelSize: root.displaySize
        font.family: root.fontFamily || resolvedFontFamily
        // only Normal resolves to the variable face, other weights pick axis-less static instances
        font.weight: root.variableFont ? Font.Normal : Math.min(Font.Black, root.digitWeight)
        font.features: ({
                "tnum": 1
            })
        font.variableAxes: root.variableFont ? {
            "ROND": root.rounded ? 100 : 20,
            "wght": root.digitWeight,
            "opsz": root.displaySize
        } : {}
        minimumPixelSize: Style.fontSizeLarge
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.NoWrap
        elide: Text.ElideNone
        LayoutMirroring.enabled: false
    }
}
