import QtQuick
import QtQuick.Controls as Controls
import qs.DankCommon.Common
import qs.DankCommon.Widgets as Base

Controls.Control {
    id: slider

    function checkParentDisablesTransparency() {
        let p = parent;
        while (p) {
            if (p.disablePopupTransparency === true)
                return true;
            p = p.parent;
        }
        return false;
    }

    focusPolicy: enabled ? wheelEnabled ? Qt.WheelFocus : Qt.StrongFocus : Qt.NoFocus
    wheelEnabled: true

    property int value: 50
    property int minimum: 0
    property int maximum: 100
    property int step: 1
    property string leftIcon: ""
    property string rightIcon: ""
    property string insetIcon: ""
    property string insetIconPosition: "start"
    property bool insetIconClickable: false
    property string insetIconTooltip: ""
    property string unit: "%"
    property bool showValue: true
    property bool isDragging: false
    property bool centerMinimum: false
    property real valueOverride: -1
    property int decimals: 0
    property bool alwaysShowValue: false
    property string size: "xs"
    readonly property bool containsMouse: sliderMouseArea.containsMouse
    readonly property var focusTargets: insetAction.enabled ? [insetAction, slider] : [slider]

    property color thumbOutlineColor: Style.surfaceContainer
    property color fillColor: Style.primary
    property color fillTextColor: Style.onPrimary
    property color trackColor: Style.secondaryContainer
    property color trackTextColor: Style.onSecondaryContainer
    property bool usePopupTransparency: !checkParentDisablesTransparency()
    property real trackOpacity: usePopupTransparency ? Style.popupTransparency : 1.0

    signal insetIconClicked
    signal sliderValueChanged(int newValue)
    signal sliderDragFinished(int finalValue)

    function formatValue(v) {
        if (decimals <= 0)
            return Math.round(v) + unit;
        return (v / Math.pow(10, decimals)).toFixed(decimals) + unit;
    }

    function ratioForValue(v) {
        const range = maximum - minimum;
        const raw = range === 0 ? 0 : (v - minimum) / range;
        const clamped = Math.max(0, Math.min(1, raw));
        return centerMinimum ? (0.5 + clamped * 0.5) : clamped;
    }

    readonly property real ratio: ratioForValue(value)
    readonly property bool isMirrored: I18n.isRtl
    readonly property real trackHeight: {
        switch (size) {
        case "s":
            return Style.sliderTrackHeightS;
        case "m":
            return Style.sliderTrackHeightM;
        case "l":
            return Style.sliderTrackHeightL;
        case "xl":
            return Style.sliderTrackHeightXL;
        default:
            return Style.sliderTrackHeight;
        }
    }
    readonly property real handleHeight: {
        switch (size) {
        case "s":
            return Style.sliderHandleHeightS;
        case "m":
            return Style.sliderHandleHeightM;
        case "l":
            return Style.sliderHandleHeightL;
        case "xl":
            return Style.sliderHandleHeightXL;
        default:
            return Style.sliderHandleHeight;
        }
    }
    readonly property real cornerScale: Math.max(0, Style.cornerRadius / 12)
    readonly property real trackCornerRadius: {
        switch (size) {
        case "s":
            return Style.sliderTrackCornerRadiusS;
        case "m":
            return Style.sliderTrackCornerRadiusM;
        case "l":
            return Style.sliderTrackCornerRadiusL;
        case "xl":
            return Style.sliderTrackCornerRadiusXL;
        default:
            return Style.sliderTrackCornerRadius;
        }
    }
    readonly property real outsideCorner: Math.min(trackHeight / 2, trackCornerRadius * cornerScale)
    readonly property real insideCorner: Math.min(trackHeight / 2, Style.sliderTrackInsideCornerRadius * cornerScale)
    readonly property real visualRatio: isMirrored ? 1 - ratio : ratio
    readonly property int tickCount: {
        if (step <= 1)
            return 0;
        const steps = Math.ceil((maximum - minimum) / step);
        return steps >= 2 && steps <= 12 ? steps + 1 : 0;
    }
    readonly property int keyStep: step > 1 ? step : Math.max(1, Math.round((maximum - minimum) / 100))
    readonly property int pageSteps: Math.max(1, Math.min(10, Math.round((maximum - minimum) / keyStep / 10)))

    height: handleHeight + Style.spacingXS
    activeFocusOnTab: enabled
    readonly property int minimumValue: minimum
    readonly property int maximumValue: maximum
    readonly property int stepSize: keyStep
    Accessible.role: Accessible.Slider
    Accessible.focusable: enabled
    Accessible.onIncreaseAction: {
        if (enabled)
            stepBy(1);
    }
    Accessible.onDecreaseAction: {
        if (enabled)
            stepBy(-1);
    }

    function commit(newValue) {
        const clamped = Math.max(minimum, Math.min(maximum, newValue));
        if (clamped === value)
            return;
        value = clamped;
        sliderValueChanged(clamped);
    }

    function stepBy(direction) {
        let next = value + direction * keyStep;
        if (step > 1)
            next = minimum + Math.round((next - minimum) / step) * step;
        commit(Math.round(next));
        sliderDragFinished(value);
    }

    function updateValueFromPosition(x) {
        if (sliderTrack.width <= sliderHandle.width)
            return;
        let ratio = Math.max(0, Math.min(1, (x - sliderHandle.width / 2) / (sliderTrack.width - sliderHandle.width)));
        if (isMirrored)
            ratio = 1 - ratio;
        if (centerMinimum)
            ratio = Math.max(0, (ratio - 0.5) * 2);
        let rawValue = minimum + ratio * (maximum - minimum);
        let newValue = step > 1 ? minimum + Math.round((rawValue - minimum) / step) * step : Math.round(rawValue);
        commit(newValue);
    }

    Keys.onPressed: event => {
        if (!enabled)
            return;
        const upKey = isMirrored ? Qt.Key_Left : Qt.Key_Right;
        const downKey = isMirrored ? Qt.Key_Right : Qt.Key_Left;
        switch (event.key) {
        case upKey:
        case Qt.Key_Up:
            stepBy(1);
            event.accepted = true;
            break;
        case downKey:
        case Qt.Key_Down:
            stepBy(-1);
            event.accepted = true;
            break;
        case Qt.Key_PageUp:
            stepBy(pageSteps);
            event.accepted = true;
            break;
        case Qt.Key_PageDown:
            stepBy(-pageSteps);
            event.accepted = true;
            break;
        case Qt.Key_Home:
            commit(minimum);
            sliderDragFinished(value);
            event.accepted = true;
            break;
        case Qt.Key_End:
            commit(maximum);
            sliderDragFinished(value);
            event.accepted = true;
            break;
        }
    }

    contentItem: Row {
        anchors.centerIn: parent
        width: parent.width
        spacing: Style.spacingM
        LayoutMirroring.enabled: slider.isMirrored

        Base.DankIcon {
            name: slider.leftIcon
            size: Style.iconSize
            color: slider.enabled ? Style.surfaceText : Style.onSurface_38
            anchors.verticalCenter: parent.verticalCenter
            visible: slider.leftIcon.length > 0
        }

        Item {
            id: sliderTrack

            property int leftIconWidth: slider.leftIcon.length > 0 ? Style.iconSize : 0
            property int rightIconWidth: slider.rightIcon.length > 0 ? Style.iconSize : 0
            readonly property real travel: width - sliderHandle.width
            readonly property real handleLeft: Math.max(0, Math.min(travel, travel * slider.visualRatio))
            readonly property real gap: Style.sliderHandleGap
            readonly property real filledStart: slider.isMirrored ? sliderHandle.x + sliderHandle.width + gap : 0
            readonly property real filledEnd: slider.isMirrored ? width : sliderHandle.x - gap
            readonly property real emptyStart: slider.isMirrored ? 0 : sliderHandle.x + sliderHandle.width + gap
            readonly property real emptyEnd: slider.isMirrored ? sliderHandle.x - gap : width
            readonly property bool insetIconVisible: slider.insetIcon.length > 0 && ["m", "l", "xl"].indexOf(slider.size) !== -1 && !slider.centerMinimum
            readonly property bool insetIconLeftAligned: (!slider.isMirrored && slider.insetIconPosition === "start") || (slider.isMirrored && slider.insetIconPosition === "end")
            readonly property bool insetIconBehindHandle: {
                if (insetIconLeftAligned) {
                    return sliderHandle.x <= (Style.iconSizeLarge + Style.spacingS);
                } else {
                    return (width - sliderHandle.x) <= Style.iconSizeLarge + Style.spacingS;
                }
            }

            width: parent.width - (leftIconWidth + rightIconWidth + (slider.leftIcon.length > 0 ? Style.spacingM : 0) + (slider.rightIcon.length > 0 ? Style.spacingM : 0))
            height: slider.handleHeight
            anchors.verticalCenter: parent.verticalCenter

            Base.StyledRect {
                id: activeTrack
                x: sliderTrack.filledStart
                width: Math.max(0, sliderTrack.filledEnd - sliderTrack.filledStart)
                height: slider.trackHeight
                anchors.verticalCenter: parent.verticalCenter
                topLeftRadius: slider.isMirrored ? slider.insideCorner : slider.outsideCorner
                bottomLeftRadius: topLeftRadius
                topRightRadius: slider.isMirrored ? slider.outsideCorner : slider.insideCorner
                bottomRightRadius: topRightRadius
                color: slider.enabled ? slider.fillColor : Style.onSurface_38
                visible: width > 0
            }

            Base.StyledRect {
                id: inactiveTrack
                x: sliderTrack.emptyStart
                width: Math.max(0, sliderTrack.emptyEnd - sliderTrack.emptyStart)
                height: slider.trackHeight
                anchors.verticalCenter: parent.verticalCenter
                topLeftRadius: slider.isMirrored ? slider.outsideCorner : slider.insideCorner
                bottomLeftRadius: topLeftRadius
                topRightRadius: slider.isMirrored ? slider.insideCorner : slider.outsideCorner
                bottomRightRadius: topRightRadius
                color: slider.enabled ? Style.withAlpha(slider.trackColor, slider.trackOpacity) : Style.onSurface_12
                visible: width > 0

                Base.StyledRect {
                    width: Style.sliderStopSize
                    height: Style.sliderStopSize
                    radius: Math.min(1, slider.cornerScale) * width / 2
                    x: slider.isMirrored ? Style.sliderHandleGap : parent.width - Style.sliderHandleGap - width
                    anchors.verticalCenter: parent.verticalCenter
                    color: slider.enabled ? slider.fillColor : Style.onSurface_38
                    visible: (sliderTrack.insetIconVisible && slider.insetIconPosition === "end") ? false : parent.width > Style.sliderHandleGap * 2 + width
                }
            }

            Repeater {
                model: slider.tickCount

                Base.StyledRect {
                    required property int index
                    readonly property real tickRatio: slider.ratioForValue(slider.minimum + index * slider.step)
                    readonly property real tickX: sliderHandle.width / 2 + sliderTrack.travel * (slider.isMirrored ? 1 - tickRatio : tickRatio)
                    readonly property bool onFilled: slider.isMirrored ? tickX > sliderHandle.x + sliderHandle.width : tickX < sliderHandle.x
                    width: Style.sliderTickSize
                    height: width
                    radius: Math.min(1, slider.cornerScale) * width / 2
                    x: tickX - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: onFilled ? slider.fillTextColor : Style.onSurfaceVariant
                    visible: index !== 0 && index !== slider.tickCount - 1 && Math.abs(tickX - sliderHandle.x - sliderHandle.width / 2) > Style.sliderHandleGap * 2
                }
            }

            Base.StyledRect {
                id: sliderHandle

                width: sliderMouseArea.pressed ? Style.sliderHandleWidth / 2 : Style.sliderHandleWidth
                height: slider.handleHeight
                radius: Math.min(1, slider.cornerScale) * width / 2
                x: sliderTrack.handleLeft
                anchors.verticalCenter: parent.verticalCenter
                color: slider.enabled ? slider.fillColor : Style.onSurface_38
                border.width: 0
                border.color: slider.thumbOutlineColor

                Behavior on width {
                    enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                    DankAnim {
                        duration: Style.expressiveDurations.expressiveEffects
                        easing.bezierCurve: Style.expressiveCurves.standard
                    }
                }

                Base.FocusRing {
                    visible: slider.visualFocus
                }
            }

            Base.DankIcon {
                id: movingInsetIcon
                name: slider.insetIcon
                size: slider.size === "xl" ? Style.iconSizeLarge : Style.iconSize
                color: slider.enabled ? (slider.insetIconPosition === "start" ? slider.trackTextColor : slider.fillTextColor) : Style.onSurface_38
                anchors.verticalCenter: parent.verticalCenter
                x: sliderTrack.insetIconLeftAligned ? sliderHandle.x + sliderHandle.width + Style.spacingS : sliderHandle.x - width - Style.spacingS
                opacity: sliderTrack.insetIconBehindHandle ? 1 : 0
                visible: sliderTrack.insetIconVisible

                Behavior on opacity {
                    enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                    DankAnim {
                        duration: Style.shorterDuration
                        easing.bezierCurve: Style.expressiveCurves.standard
                    }
                }
            }

            Base.DankIcon {
                name: slider.insetIcon
                size: slider.size === "xl" ? Style.iconSizeLarge : Style.iconSize
                color: slider.enabled ? (slider.insetIconPosition === "start" ? slider.fillTextColor : slider.trackTextColor) : Style.onSurface_38
                anchors.verticalCenter: parent.verticalCenter
                x: sliderTrack.insetIconLeftAligned ? Style.spacingXS : sliderTrack.width - width - Style.spacingXS
                opacity: sliderTrack.insetIconBehindHandle ? 0 : 1
                visible: sliderTrack.insetIconVisible

                Behavior on opacity {
                    enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                    DankAnim {
                        duration: Style.shorterDuration
                        easing.bezierCurve: Style.expressiveCurves.standard
                    }
                }
            }

            Item {
                id: insetAction

                readonly property bool hovered: sliderMouseArea.containsMouse && containsPosition(sliderMouseArea.mouseX, sliderMouseArea.mouseY)
                readonly property real iconX: sliderTrack.insetIconBehindHandle ? movingInsetIcon.x : (sliderTrack.insetIconLeftAligned ? Style.spacingXS : sliderTrack.width - movingInsetIcon.width - Style.spacingXS)
                x: Math.max(0, Math.min(sliderTrack.width - width, iconX + (movingInsetIcon.width - width) / 2))
                width: Math.min(sliderTrack.width, Style.iconButtonSize)
                height: slider.trackHeight
                anchors.verticalCenter: parent.verticalCenter
                visible: sliderTrack.insetIconVisible && slider.insetIconClickable
                enabled: slider.enabled && visible
                activeFocusOnTab: enabled
                Accessible.role: Accessible.Button
                Accessible.name: slider.insetIconTooltip
                Accessible.onPressAction: activate()

                function activate() {
                    if (enabled)
                        slider.insetIconClicked();
                }

                function containsPosition(px, py) {
                    if (!enabled || px < x || px > x + width || py < y || py > y + height)
                        return false;
                    return px < sliderHandle.x - sliderTrack.gap || px > sliderHandle.x + sliderHandle.width + sliderTrack.gap;
                }

                function syncTooltip() {
                    if (!hovered || !visible || !slider.visible || slider.isDragging || slider.insetIconTooltip.length === 0) {
                        actionTooltip.hide();
                        return;
                    }
                    actionTooltip.show(slider.insetIconTooltip, insetAction, 0, 0, "top");
                }

                onHoveredChanged: syncTooltip()
                onVisibleChanged: syncTooltip()
                Component.onDestruction: actionTooltip.hide()

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Space:
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        activate();
                        event.accepted = true;
                    }
                }

                Base.FocusRing {
                    radius: Style.cornerRadiusFull
                }
                DankTooltipV2 {
                    id: actionTooltip
                }
            }

            Connections {
                target: slider
                function onInsetIconTooltipChanged() {
                    insetAction.syncTooltip();
                }
                function onIsDraggingChanged() {
                    insetAction.syncTooltip();
                }
                function onVisibleChanged() {
                    insetAction.syncTooltip();
                }
            }

            MouseArea {
                id: sliderMouseArea

                property bool pressedInsetIcon: false
                property real pressX: 0
                property real pressY: 0

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: slider.enabled
                preventStealing: true
                acceptedButtons: Qt.LeftButton
                onWheel: wheelEvent => {
                    if (!slider.wheelEnabled) {
                        wheelEvent.accepted = false;
                        return;
                    }
                    slider.stepBy(wheelEvent.angleDelta.y > 0 ? 1 : -1);
                    wheelEvent.accepted = true;
                }
                onPressed: mouse => {
                    pressX = mouse.x;
                    pressY = mouse.y;
                    pressedInsetIcon = insetAction.containsPosition(mouse.x, mouse.y);
                    if (pressedInsetIcon)
                        return;
                    slider.forceActiveFocus();
                    slider.isDragging = true;
                    updateValueFromPosition(mouse.x);
                }
                onReleased: {
                    if (pressedInsetIcon && !slider.isDragging)
                        insetAction.activate();
                    if (slider.isDragging)
                        slider.sliderDragFinished(slider.value);
                    slider.isDragging = false;
                    pressedInsetIcon = false;
                }
                onCanceled: {
                    slider.isDragging = false;
                    pressedInsetIcon = false;
                }
                onPositionChanged: mouse => {
                    if (!pressed || !slider.enabled)
                        return;
                    if (pressedInsetIcon && !slider.isDragging && Math.hypot(mouse.x - pressX, mouse.y - pressY) < Qt.styleHints.startDragDistance)
                        return;
                    slider.forceActiveFocus();
                    slider.isDragging = true;
                    updateValueFromPosition(mouse.x);
                }
            }

            Controls.ToolTip {
                id: valueTooltip

                width: tooltipText.reservedWidth + Style.spacingL * 2
                height: tooltipText.contentHeight + Style.spacingM * 2
                padding: 0
                horizontalPadding: 0
                margins: Style.spacingXS
                x: Math.max(0, Math.min(sliderTrack.width - width, sliderHandle.x + sliderHandle.width / 2 - width / 2))
                y: -height - Style.spacingXS
                visible: slider.visible && slider.enabled && slider.showValue && (slider.alwaysShowValue || (sliderMouseArea.containsMouse && !insetAction.hovered) || slider.isDragging)
                closePolicy: Controls.Popup.NoAutoClose
                modal: false
                dim: false
                focus: false

                Binding {
                    target: valueTooltip.contentItem?.parent ?? null
                    property: "containmentMask"
                    value: QtObject {
                        function contains(position: point): bool {
                            return false;
                        }
                    }
                }

                background: Base.StyledRect {
                    radius: Math.min(1, slider.cornerScale) * height / 2
                    color: slider.fillColor
                }

                contentItem: Base.NumericText {
                    id: tooltipText

                    text: slider.formatValue(slider.valueOverride >= 0 ? slider.valueOverride : slider.value)
                    reserveText: {
                        let widest = "";
                        const samples = [slider.minimum, slider.maximum];
                        if (slider.valueOverride >= 0)
                            samples.push(slider.valueOverride);
                        for (let i = 0; i < samples.length; i++) {
                            const candidate = slider.formatValue(samples[i]);
                            if (candidate.length > widest.length)
                                widest = candidate;
                        }
                        return widest;
                    }
                    font.pixelSize: Style.fontSizeSmall
                    color: slider.fillTextColor
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.hintingPreference: Font.PreferFullHinting
                }

                enter: Transition {
                    enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                    DankAnim {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Style.expressiveDurations.expressiveEffects
                        easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                    }
                    DankAnim {
                        property: "scale"
                        from: Style.popupEnterScale
                        to: 1
                        duration: Style.expressiveDurations.expressiveFastSpatial
                        easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
                    }
                }

                exit: Transition {
                    enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                    DankAnim {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Style.expressiveDurations.expressiveEffects
                        easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                    }
                }
            }
        }

        Base.DankIcon {
            name: slider.rightIcon
            size: Style.iconSize
            color: slider.enabled ? Style.surfaceText : Style.onSurface_38
            anchors.verticalCenter: parent.verticalCenter
            visible: slider.rightIcon.length > 0
        }
    }
}
