import QtQuick
import qs.DankCommon.Common

DankTextField {
    cornerRadius: Style.fullRadius(width, height)
    normalBorderColor: Style.outlineVariant
    focusedBorderColor: Style.focusRingColor
    borderWidth: Style.outlineWidth
    focusedBorderWidth: Math.max(Style.outlineWidth, Style.focusRingWidth)
    placeholderColor: Style.surfaceTextSecondary
    leftIconName: "search"
    hidePlaceholderOnFocus: false
    showClearButton: true
}
