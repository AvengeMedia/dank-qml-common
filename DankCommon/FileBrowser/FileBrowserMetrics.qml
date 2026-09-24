pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.DankCommon.Common

Singleton {
    readonly property real headerHeight: Style.buttonHeightS
    readonly property real contentMargin: Style.spacingL
    readonly property real contentSpacing: Style.spacingM
    readonly property real controlSize: Style.buttonHeightS + Style.spacingXS
    readonly property real controlSpacing: Style.spacingS
    readonly property real navPairSegmentWidth: controlSize + Style.spacingS
    readonly property real navPairInnerRadius: Style.cornerRadiusS
    readonly property real navPairGap: Style.spacingXXS

    readonly property real pathBarSpacing: Style.spacingXS
    readonly property real pathPillHeight: Style.buttonHeightXS
    readonly property real pathPillRadius: Style.cornerRadiusS
    readonly property real pathPillPadding: Style.spacingS
    readonly property real pathPillSpacing: Style.spacingXS
    readonly property real pathIconSize: Style.iconSizeSmall

    readonly property var gridIconSizes: [Style.iconSizeLarge * 2, Style.iconSizeLarge * 3, Style.iconSizeLarge * 4, Style.iconSizeLarge * 6]
    readonly property var listIconSizes: [Style.iconSizeMedium, Style.iconSize, Style.iconSizeLarge, Style.iconSizeLarge * 1.5]
    readonly property real gridTilePadding: Style.spacingM
    readonly property real gridTileRadius: Style.cornerRadiusL
    readonly property real gridGap: Style.spacingS
    readonly property real gridNameSpacing: Style.spacingXS
    readonly property real quickTileSize: gridIconSizes[1] + gridTilePadding * 2
    readonly property real quickTileIconSize: gridIconSizes[0]

    readonly property real listRowHeight: Style.listItemHeight
    readonly property real listRowPadding: Style.spacingM

    function listRowHeightFor(iconSize) {
        return Math.max(listRowHeight, iconSize + listRowPadding * 2);
    }
    readonly property real columnHeaderHeight: Style.buttonHeightXS
    readonly property real columnHeaderPadding: Style.spacingS
    readonly property real columnGap: Style.spacingM
    readonly property real columnMinWidth: Style.spacingXL * 3
    readonly property real sizeColumnWidth: Style.spacingXL * 4
    readonly property real modifiedColumnWidth: Style.spacingXL * 6
    readonly property real typeColumnWidth: Style.spacingXL * 5
    readonly property real ownerColumnWidth: Style.spacingXL * 4
    readonly property real permissionsColumnWidth: Style.spacingXL * 4

    readonly property real selectionFooterHeight: Style.buttonHeightS
    readonly property real emblemMinSize: Style.iconSizeSmall
    readonly property real emblemRatio: 0.3
    readonly property real hiddenOpacity: Style.pendingOpacity
    readonly property real skeletonOpacity: Style.pendingOpacity
    readonly property real rubberBandMinimum: Style.spacingS

    readonly property real sidebarWidth: Style.sidebarWidth
    readonly property int sidebarBreakpoint: Style.mediumBreakpoint
    readonly property real sidebarPadding: Style.spacingM
    readonly property real sidebarIconSize: Style.avatarSize
    readonly property real sidebarRowHeight: sidebarIconSize + Style.spacingL
    readonly property real sidebarRowRadius: Style.cornerRadiusM
    readonly property real sidebarGlyphSize: Style.iconSizeMedium
    readonly property real usageWarnRatio: 0.9
    readonly property real paneRadius: Style.windowRadius
    readonly property real paneMargin: Style.spacingM
    readonly property real menuWidth: Style.spacingXL * 9
    readonly property real pickerWidth: Style.launcherWidthLarge
    readonly property real pickerHeight: Style.launcherHeightDefault + Style.spacingXL
    readonly property real pickerMinWidth: Style.launcherWidthMicro
    readonly property real pickerMinHeight: Style.smallBreakpoint
    readonly property real pickerScreenFraction: 0.9
    readonly property int settleInterval: 150
    readonly property int typeAheadInterval: 1000

    readonly property bool animationsEnabled: !Style.reduceMotion && Style.currentAnimationBaseDuration > 0
}
