import QtQuick
import qs.DankCommon.Common

DankColorSwatch {
    property color primaryColor: Style.primary

    swatchColor: primaryColor
    secondaryColor: primaryColor
    tertiaryColor: secondaryColor
    ringWidth: 0
}
