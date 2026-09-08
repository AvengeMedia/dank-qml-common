import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets as Base

FocusScope {
    id: toggle

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    property bool checked: false
    property bool toggling: false
    property string text: ""
    property string description: ""
    property color descriptionColor: Style.surfaceVariantText
    property bool hideText: false
    property string checkedIcon: "check"
    property string uncheckedIcon: ""
    readonly property string thumbIcon: checked ? checkedIcon : uncheckedIcon

    signal clicked
    signal toggled(bool checked)
    signal toggleCompleted(bool checked)

    readonly property bool showText: text && !hideText
    property bool _ready: false
    property bool _settling: false

    Component.onCompleted: {
        _ready = true;
        thumbSpring.snapTo(toggleTrack.thumbTarget);
        sizeSpring.snapTo(toggleTrack.thumbSize);
    }

    readonly property int trackWidth: Style.switchTrackWidth
    readonly property int trackHeight: Style.switchTrackHeight
    readonly property int insetCircle: Style.switchThumbSelected

    width: showText ? parent.width : trackWidth
    height: showText ? Math.max(trackHeight, textColumn.implicitHeight + Style.spacingM * 2) : trackHeight
    activeFocusOnTab: enabled
    readonly property Item focusTarget: input
    readonly property var focusTargets: [input]

    StyledButton {
        id: input
        focus: true
        focusPolicy: Qt.ClickFocus
        Accessible.ignored: toggle.Accessible.ignored
        anchors.fill: parent
        enabled: toggle.enabled && !toggle.toggling
        checkable: true
        checked: toggle.checked
        Accessible.role: Accessible.CheckBox
        Accessible.name: toggle.Accessible.name || toggle.text
        Accessible.description: toggle.Accessible.description || toggle.description
        onClicked: toggle.handleClick()
    }

    function handleClick() {
        if (!enabled || toggling)
            return;
        clicked();
        toggled(!checked);
    }

    Loader {
        id: rowLoader
        anchors.fill: parent
        active: toggle.showText
        sourceComponent: Base.StyledRect {
            radius: Style.cornerRadiusM
            color: "transparent"

            Base.StateLayer {
                control: input
                disabled: !toggle.enabled || toggle.toggling
                stateColor: Style.primary
                cornerRadius: parent.radius
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.right: toggleTrack.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.spacingM
        anchors.rightMargin: Style.spacingM
        spacing: Style.spacingXS
        visible: showText

        Column {
            id: textColumn
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacingXS

            Base.StyledText {
                text: toggle.text
                font.pixelSize: Style.fontSizeMedium
                font.weight: Font.Medium
                color: toggle.enabled ? Style.surfaceText : Style.onSurface_38
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
            }

            Base.StyledText {
                text: toggle.description
                font.pixelSize: Style.fontSizeSmall
                color: toggle.enabled ? toggle.descriptionColor : Style.onSurface_38
                wrapMode: Text.WordWrap
                width: parent.width
                visible: toggle.description.length > 0
                horizontalAlignment: Text.AlignLeft
            }
        }
    }

    Base.StyledRect {
        id: toggleTrack

        readonly property bool pressed: input.pressed
        readonly property real thumbSize: pressed ? Style.switchThumbPressed : (toggle.checked || toggle.thumbIcon ? Style.switchThumbSelected : Style.switchThumbUnselected)
        readonly property real edgeLeft: (trackHeight - Style.switchThumbSelected) / 2
        readonly property real edgeRight: width - Style.switchThumbSelected - edgeLeft
        readonly property real thumbTarget: toggle.checked ? edgeRight : edgeLeft

        width: trackWidth
        height: trackHeight
        anchors.right: parent.right
        anchors.rightMargin: showText ? Style.spacingM : 0
        anchors.verticalCenter: parent.verticalCenter
        radius: Math.min(Style.cornerRadiusFull, height / 2)

        color: {
            if (!toggle.enabled)
                return toggle.checked ? Style.onSurface_12 : Style.withAlpha(Style.surfaceContainerHighest, 0.12);
            return toggle.checked ? Style.primary : Style.surfaceContainerHighest;
        }
        border.width: toggle.checked ? 0 : Style.switchOutlineWidth
        border.color: toggle.enabled ? Style.outline : Style.onSurface_12
        opacity: toggle.toggling ? Style.pendingOpacity : 1

        Behavior on color {
            enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
            DankColorAnim {
                duration: Style.expressiveDurations.expressiveEffects
                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
            }
        }

        onThumbTargetChanged: {
            if (!toggle._ready)
                return;
            thumbSpring.retarget(thumbTarget);
            if (thumbSpring.running) {
                toggle._settling = true;
                return;
            }
            toggle.toggleCompleted(toggle.checked);
        }
        onWidthChanged: {
            if (!toggle._ready)
                return;
            thumbSpring.snapTo(thumbTarget);
        }

        SpringMotion {
            id: thumbSpring
            enabled: !Style.springMotionDisabled
            stiffness: Style.springPreset("fast", Style.expressiveDurations.expressiveFastSpatial).stiffness
            damping: Style.springPreset("fast", Style.expressiveDurations.expressiveFastSpatial).damping
            onRunningChanged: {
                if (running || !toggle._settling)
                    return;
                toggle._settling = false;
                toggle.toggleCompleted(toggle.checked);
            }
        }

        onThumbSizeChanged: {
            if (!toggle._ready)
                return;
            if (pressed) {
                sizeSpring.snapTo(thumbSize);
                return;
            }
            sizeSpring.retarget(thumbSize);
        }

        SpringMotion {
            id: sizeSpring
            enabled: !Style.springMotionDisabled
            stiffness: thumbSpring.stiffness
            damping: thumbSpring.damping
        }

        Rectangle {
            id: thumb

            readonly property real centerX: thumbSpring.value + Style.switchThumbSelected / 2

            width: sizeSpring.value
            height: width
            radius: Math.min(Style.cornerRadiusFull, height / 2)
            x: input.mirrored ? toggleTrack.width - centerX - width / 2 : centerX - width / 2
            anchors.verticalCenter: parent.verticalCenter

            color: {
                if (!toggle.enabled)
                    return toggle.checked ? Style.surface : Style.onSurface_38;
                if (toggle.checked)
                    return toggleTrack.pressed ? Style.primaryContainer : Style.onPrimary;
                return toggleTrack.pressed ? Style.onSurfaceVariant : Style.outline;
            }

            Base.DankIcon {
                anchors.centerIn: parent
                name: toggle.thumbIcon
                size: Style.iconSizeSmall
                visible: name !== ""
                color: {
                    if (!toggle.enabled)
                        return toggle.checked ? Style.onSurface_38 : Style.surfaceContainerHighest;
                    return toggle.checked ? Style.onPrimaryContainer : Style.surfaceContainerHighest;
                }
            }

            Behavior on color {
                enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankColorAnim {
                    duration: Style.expressiveDurations.expressiveEffects
                    easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                }
            }
        }

        Rectangle {
            width: Style.iconButtonSize
            height: Style.iconButtonSize
            radius: Math.min(Style.cornerRadiusFull, width / 2)
            anchors.verticalCenter: parent.verticalCenter
            x: thumb.x + thumb.width / 2 - width / 2
            color: toggle.checked ? Style.primary : Style.onSurface
            opacity: !toggle.enabled ? 0 : (input.down ? Style.stateLayerPressed : (trackStateLayer.containsMouse ? Style.stateLayerHover : 0))

            Behavior on opacity {
                enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveEffects
                    easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                }
            }
        }

        Base.StateLayer {
            id: trackStateLayer
            control: input
            disabled: !toggle.enabled || toggle.toggling
            stateColor: "transparent"
            enableRipple: false
            cornerRadius: parent.radius
        }

        Base.FocusRing {
            visible: input.visualFocus
        }
    }
}
