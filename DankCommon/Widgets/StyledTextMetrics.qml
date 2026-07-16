import QtQuick
import qs.Common
import qs.DankCommon.Common

TextMetrics {
    property bool isMonospace: false

    readonly property string resolvedFontFamily: isMonospace ? Theme.monoFontFamily : Theme.fontFamily

    font.pixelSize: Appearance.fontSize.normal
    font.family: resolvedFontFamily
    font.weight: Theme.fontWeight
}
