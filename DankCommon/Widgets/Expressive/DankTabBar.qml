import QtQuick
import "../../Common/TabNavigation.js" as TabNavigation
import qs.DankCommon.Common
import qs.DankCommon.Widgets as Base

FocusScope {
    id: tabBar

    property alias model: tabRepeater.model
    property int currentIndex: 0
    property int spacing: Style.spacingL
    property int tabHeight: Style.buttonHeightM
    property bool showIcons: true
    property bool equalWidthTabs: true
    property bool enableArrowNavigation: true
    property bool cycleOnTab: false
    property Item nextFocusTarget: null
    property Item previousFocusTarget: null

    signal tabClicked(int index)
    signal actionTriggered(int index)

    focus: false
    activeFocusOnTab: true
    implicitHeight: Math.max(tabHeight, tabRow.implicitHeight + Style.tabIndicatorHeight)
    height: implicitHeight

    Keys.onPressed: event => {
        if (!enabled)
            return;
        event.accepted = TabNavigation.handleKeyEvent(event, tabBar, tabRepeater, I18n.isRtl);
    }

    Row {
        id: tabRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: tabBar.spacing
        LayoutMirroring.enabled: false
        layoutDirection: I18n.isRtl ? Qt.RightToLeft : Qt.LeftToRight
        onLayoutDirectionChanged: indicatorUpdate.restart()

        Repeater {
            id: tabRepeater

            onItemAdded: indicatorUpdate.restart()
            onItemRemoved: indicatorUpdate.restart()

            Item {
                id: tabItem
                property bool isAction: modelData && modelData.isAction === true
                onIsActionChanged: indicatorUpdate.restart()
                property bool isActive: !isAction && tabBar.currentIndex === index
                property bool hasIcon: tabBar.showIcons && !!modelData?.icon?.length
                property bool hasText: !!modelData?.text?.length
                Accessible.role: isAction ? Accessible.Button : Accessible.PageTab
                Accessible.name: modelData?.text ?? ""
                Accessible.selected: isActive
                Accessible.onPressAction: {
                    if (!tabBar.enabled)
                        return;
                    if (isAction) {
                        tabBar.actionTriggered(index);
                        return;
                    }
                    tabBar.tabClicked(index);
                }
                readonly property real contentWidth: contentCol.implicitWidth

                width: tabBar.equalWidthTabs ? Math.max(0, tabBar.width - tabBar.spacing * Math.max(0, tabRepeater.count - 1)) / Math.max(1, tabRepeater.count) : Math.max(contentCol.implicitWidth + Style.spacingXL, Style.tabMinWidth)
                height: Math.max(tabBar.tabHeight - Style.tabIndicatorHeight, contentCol.implicitHeight + Style.spacingXS * 2)
                anchors.verticalCenter: parent.verticalCenter

                Column {
                    id: contentCol
                    onImplicitWidthChanged: indicatorUpdate.restart()
                    anchors.centerIn: parent
                    spacing: Style.spacingXS

                    Base.DankIcon {
                        name: modelData.icon || ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        size: Style.iconSize
                        color: tabItem.isActive ? Style.primary : Style.onSurfaceVariant
                        filled: tabItem.isActive
                        visible: hasIcon

                        Behavior on color {
                            enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                            DankColorAnim {
                                duration: Style.expressiveDurations.expressiveEffects
                                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                            }
                        }
                    }

                    Base.StyledText {
                        text: modelData.text || ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Style.fontSizeMedium
                        color: tabItem.isActive ? Style.primary : Style.onSurfaceVariant
                        font.weight: Font.Medium
                        visible: hasText

                        Behavior on color {
                            enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                            DankColorAnim {
                                duration: Style.expressiveDurations.expressiveEffects
                                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                            }
                        }
                    }
                }

                Base.StateLayer {
                    disabled: !tabBar.enabled
                    stateColor: Style.primary
                    cornerRadius: Style.cornerRadiusM
                    transitionDuration: Style.expressiveDurations.expressiveEffects
                    transitionCurve: Style.expressiveCurves.expressiveEffects
                    onClicked: {
                        if (tabItem.isAction) {
                            tabBar.actionTriggered(index);
                            return;
                        }
                        tabBar.tabClicked(index);
                    }
                }

                Base.FocusRing {
                    radius: Math.min(Style.cornerRadiusFull, Style.cornerRadiusM + Style.focusRingOffset)
                    visible: tabBar.activeFocus && tabItem.isActive
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: Style.dividerWidth
        anchors.bottom: parent.bottom
        color: Style.outlineVariant
    }

    Item {
        id: indicator

        property bool animationEnabled: false
        property bool initialSetupComplete: false
        property bool movingRight: true
        property real leftX: 0
        property real rightX: 0

        anchors.bottom: parent.bottom
        height: Style.tabIndicatorHeight
        x: leftX
        width: Math.max(0, rightX - leftX)
        clip: true
        visible: false

        Rectangle {
            width: parent.width
            height: parent.height * 2
            radius: Math.min(width / 2, parent.height, parent.height * Style.shapeScale)
            color: Style.primary
        }

        Behavior on leftX {
            enabled: indicator.animationEnabled && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
            DankAnim {
                duration: indicator.movingRight ? Style.expressiveDurations.expressiveDefaultSpatial : Style.expressiveDurations.expressiveFastSpatial
                easing.bezierCurve: Style.expressiveCurves.emphasized
            }
        }

        Behavior on rightX {
            enabled: indicator.animationEnabled && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
            DankAnim {
                duration: indicator.movingRight ? Style.expressiveDurations.expressiveFastSpatial : Style.expressiveDurations.expressiveDefaultSpatial
                easing.bezierCurve: Style.expressiveCurves.emphasized
            }
        }
    }

    Timer {
        id: indicatorUpdate
        interval: 0
        onTriggered: tabBar.updateIndicator()
    }

    function updateIndicator() {
        if (tabRepeater.count === 0 || currentIndex < 0 || currentIndex >= tabRepeater.count) {
            indicator.visible = false;
            indicator.initialSetupComplete = false;
            return;
        }

        const item = tabRepeater.itemAt(currentIndex);
        if (!item || item.isAction) {
            indicator.visible = false;
            indicator.initialSetupComplete = false;
            return;
        }

        tabRow.forceLayout();
        const tabPos = item.mapToItem(tabBar, 0, 0);
        const tabCenterX = tabPos.x + item.width / 2;
        const indicatorWidth = Math.max(0, Math.min(item.width, Math.max(Style.tabIndicatorMinWidth, item.contentWidth - Style.tabIndicatorInset * 2)));
        const targetLeft = tabCenterX - indicatorWidth / 2;
        const targetRight = tabCenterX + indicatorWidth / 2;

        indicator.movingRight = targetLeft >= indicator.leftX;
        if (!indicator.initialSetupComplete) {
            indicator.animationEnabled = false;
            indicator.leftX = targetLeft;
            indicator.rightX = targetRight;
            indicator.visible = true;
            indicator.initialSetupComplete = true;
            indicator.animationEnabled = true;
            return;
        }
        indicator.leftX = targetLeft;
        indicator.rightX = targetRight;
        indicator.visible = true;
    }

    function snapIndicator() {
        indicator.initialSetupComplete = false;
        updateIndicator();
    }

    onCurrentIndexChanged: {
        indicatorUpdate.restart();
    }
    onWidthChanged: indicatorUpdate.restart()
    onSpacingChanged: indicatorUpdate.restart()
    onEqualWidthTabsChanged: indicatorUpdate.restart()
    Component.onCompleted: indicatorUpdate.restart()
}
