import QtQuick
import QtQuick.Window
import Quickshell
import qs.DankCommon.Common

Row {
    id: root

    property var model: []
    property int currentIndex: -1
    property string selectionMode: "single"
    property bool multiSelect: selectionMode === "multi"
    property var initialSelection: []
    property var currentSelection: initialSelection
    property bool checkEnabled: true
    property string size: "medium"
    property int buttonHeight: size === "small" ? Style.buttonHeightXS : Style.buttonHeightS
    property bool compactLayout: root.Window.window ? root.Window.window.width < Style.smallBreakpoint : false
    property int minButtonWidth: size === "small" ? (compactLayout ? 40 : 56) : (compactLayout ? 44 : 64)
    property int buttonPadding: (size === "small" || compactLayout) ? Style.spacingM : Style.spacingL
    property int checkIconSize: Style.iconSizeSmall
    property int textSize: size === "small" ? Style.fontSizeSmall : Style.fontSizeMedium
    property bool userInteracted: false
    property bool interactionStarted: false
    property bool usePopupTransparency: !Style.isFloatingWindow(root)
    property real maximumWidth: -1
    property bool fillWidth: false
    readonly property real _segmentCap: {
        const count = model?.length ?? 0;
        if (maximumWidth <= 0 || count === 0)
            return -1;
        return (maximumWidth - spacing * (count - 1)) / count - Style.spacingXS;
    }
    readonly property real outerRadius: Style.fullRadius(buttonHeight, buttonHeight)
    readonly property real innerRadius: Math.min(Style.cornerRadiusS, outerRadius)
    readonly property real pressedInnerRadius: Math.min(Style.cornerRadiusXS, outerRadius)

    signal selectionChanged(int index, bool selected)
    signal animationCompleted

    spacing: Style.groupedListGap
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    Timer {
        id: animationTimer
        interval: Style.shortDuration
        onTriggered: {
            root.userInteracted = false;
            root.animationCompleted();
        }
    }

    property int focusedIndex: currentIndex
    readonly property int focusIndex: Math.max(0, Math.min(focusedIndex, (model?.length ?? 0) - 1))
    onCurrentIndexChanged: focusedIndex = currentIndex

    function requestFocus(backwards) {
        repeater.itemAt(focusIndex)?.forceActiveFocus(backwards ? Qt.BacktabFocusReason : Qt.TabFocusReason);
    }

    Keys.onPressed: event => {
        if (!enabled || (model?.length ?? 0) === 0)
            return;
        const count = model.length;
        const forwardKey = I18n.isRtl ? Qt.Key_Left : Qt.Key_Right;
        const backwardKey = I18n.isRtl ? Qt.Key_Right : Qt.Key_Left;
        if (event.key === forwardKey) {
            focusSegment((focusIndex + 1) % count);
            event.accepted = true;
            return;
        }
        if (event.key === backwardKey) {
            focusSegment((focusIndex - 1 + count) % count);
            event.accepted = true;
        }
    }

    function focusSegment(index) {
        focusedIndex = index;
        repeater.itemAt(index)?.forceActiveFocus(Qt.TabFocusReason);
        if (!multiSelect)
            selectItem(index);
    }

    function isSelected(index) {
        if (multiSelect)
            return repeater.itemAt(index)?.selected || false;
        return index === currentIndex;
    }

    function selectItem(index) {
        interactionStarted = true;
        userInteracted = true;
        if (multiSelect) {
            const modelValue = model[index];
            let newSelection = [...currentSelection];
            const isCurrentlySelected = newSelection.includes(modelValue);

            if (isCurrentlySelected) {
                newSelection = newSelection.filter(item => item !== modelValue);
            } else {
                newSelection.push(modelValue);
            }

            currentSelection = newSelection;
            selectionChanged(index, !isCurrentlySelected);
            animationTimer.restart();
        } else {
            const oldIndex = currentIndex;
            selectionChanged(index, true);
            if (oldIndex !== index && oldIndex >= 0) {
                selectionChanged(oldIndex, false);
            }
            animationTimer.restart();
        }
    }

    Repeater {
        id: repeater
        model: ScriptModel {
            values: root.model
        }

        delegate: StyledButton {
            id: segment

            focusPolicy: activeFocus || index === root.focusIndex ? Qt.StrongFocus : Qt.ClickFocus
            onActiveFocusChanged: {
                if (activeFocus)
                    root.focusedIndex = index;
            }
            onClicked: root.selectItem(index)
            onPressedChanged: {
                if (pressed)
                    root.interactionStarted = true;
            }

            Accessible.role: root.multiSelect ? Accessible.CheckBox : Accessible.RadioButton
            Accessible.name: buttonText.text
            checkable: true
            checked: selected
            property bool selected: multiSelect ? root.currentSelection.includes(modelData) : (index === root.currentIndex)
            property bool visualFirst: index === 0
            property bool visualLast: index === repeater.count - 1
            property bool prevSelected: index > 0 ? root.isSelected(index - 1) : false
            property bool nextSelected: index < repeater.count - 1 ? root.isSelected(index + 1) : false
            readonly property real leftRadius: visualFirst ? root.outerRadius : (pressed ? root.pressedInnerRadius : (selected ? root.outerRadius : root.innerRadius))
            readonly property real rightRadius: visualLast ? root.outerRadius : (pressed ? root.pressedInnerRadius : (selected ? root.outerRadius : root.innerRadius))
            readonly property color contentColor: !root.enabled ? Style.onSurface_38 : (selected ? Style.buttonText : Style.onSecondaryContainer)

            readonly property real contentNaturalWidth: (checkIcon.visible ? checkIcon.width + contentRow.spacing : 0) + buttonText.implicitWidth

            readonly property real baseWidth: {
                if (root.fillWidth)
                    return Math.max(0, (root.width - root.spacing * (repeater.count - 1)) / Math.max(1, repeater.count));
                const natural = Math.max(contentNaturalWidth + root.buttonPadding * 2, root.minButtonWidth);
                return root._segmentCap > 0 ? Math.min(natural, Math.max(root._segmentCap, root.minButtonWidth)) : natural;
            }

            width: baseWidth
            height: root.buttonHeight

            color: !root.enabled ? Style.onSurface_12 : (selected ? Style.buttonBg : Style.foregroundColor(Style.secondaryContainer, !root.usePopupTransparency))
            border.color: "transparent"
            border.width: 0

            topLeftRadius: mirrored ? rightRadius : leftRadius
            bottomLeftRadius: mirrored ? rightRadius : leftRadius
            topRightRadius: mirrored ? leftRadius : rightRadius
            bottomRightRadius: mirrored ? leftRadius : rightRadius

            Behavior on topLeftRadius {
                enabled: root.interactionStarted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.standard
                }
            }

            Behavior on topRightRadius {
                enabled: root.interactionStarted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.standard
                }
            }

            Behavior on bottomLeftRadius {
                enabled: root.interactionStarted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.standard
                }
            }

            Behavior on bottomRightRadius {
                enabled: root.interactionStarted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.standard
                }
            }

            Behavior on color {
                enabled: root.userInteracted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankColorAnim {
                    duration: Style.expressiveDurations.expressiveEffects
                    easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                }
            }

            StateLayer {
                id: stateLayer
                control: segment
                enabled: root.enabled
                disabled: !root.enabled
                stateColor: segment.contentColor
                cornerRadius: root.outerRadius
                topLeftRadius: segment.topLeftRadius
                bottomLeftRadius: segment.bottomLeftRadius
                topRightRadius: segment.topRightRadius
                bottomRightRadius: segment.bottomRightRadius
                transitionDuration: Style.expressiveDurations.expressiveEffects
                transitionCurve: Style.expressiveCurves.expressiveEffects
            }

            FocusRing {
                radius: Math.min(Style.fullRadius(width, height), root.outerRadius + Style.focusRingOffset)
                visible: segment.visualFocus
            }

            Item {
                id: contentItem
                anchors.centerIn: parent
                implicitWidth: contentRow.implicitWidth
                implicitHeight: contentRow.implicitHeight

                Row {
                    id: contentRow
                    spacing: Style.spacingS

                    DankIcon {
                        id: checkIcon
                        name: "check"
                        size: root.checkIconSize
                        color: segment.contentColor
                        visible: root.checkEnabled && segment.selected
                        opacity: segment.selected ? 1 : 0
                        scale: segment.selected ? 1 : Style.iconEnterScale
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on opacity {
                            enabled: root.userInteracted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                            DankAnim {
                                duration: Style.expressiveDurations.expressiveEffects
                                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                            }
                        }

                        Behavior on scale {
                            enabled: root.userInteracted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                            DankAnim {
                                duration: Style.expressiveDurations.expressiveFastSpatial
                                easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
                            }
                        }
                    }

                    StyledText {
                        id: buttonText

                        readonly property real capAvailable: {
                            if (root._segmentCap <= 0)
                                return -1;
                            const cap = Math.max(root._segmentCap, root.minButtonWidth);
                            return Math.max(0, cap - root.buttonPadding * 2 - (checkIcon.visible ? checkIcon.width + contentRow.spacing : 0));
                        }

                        text: typeof modelData === "string" ? modelData : modelData.text || ""
                        font.pixelSize: root.textSize
                        font.weight: segment.selected ? Font.Medium : Font.Normal
                        color: segment.contentColor
                        anchors.verticalCenter: parent.verticalCenter
                        width: capAvailable < 0 ? implicitWidth : Math.min(implicitWidth, capAvailable)
                        maximumLineCount: 1
                    }
                }
            }
        }
    }
}
