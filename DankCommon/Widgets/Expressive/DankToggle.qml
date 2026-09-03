import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets as Base

Item {
    id: toggle

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    property bool checked: false
    property bool toggling: false
    property string text: ""
    property string description: ""
    property color descriptionColor: Style.surfaceVariantText
    property bool hideText: false

    signal clicked
    signal toggled(bool checked)
    signal toggleCompleted(bool checked)

    readonly property bool showText: text && !hideText
    property bool _ready: false
    property bool _settling: false

    Component.onCompleted: {
        _ready = true;
        thumbSpring.snapTo(toggleTrack.thumbTarget);
    }

    readonly property int trackWidth: Style.switchTrackWidth
    readonly property int trackHeight: Style.switchTrackHeight
    readonly property int insetCircle: Style.switchThumbSelected

    width: showText ? parent.width : trackWidth
    height: showText ? Math.max(trackHeight, textColumn.implicitHeight + Style.spacingM * 2) : trackHeight
    activeFocusOnTab: enabled

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Return:
        case Qt.Key_Enter:
            toggle.handleClick();
            event.accepted = true;
            break;
        }
    }

    function handleClick() {
        if (!enabled)
            return;
        clicked();
        toggled(!checked);
    }

    Base.StyledRect {
        id: background
        anchors.fill: parent
        radius: showText ? Style.cornerRadiusM : 0
        color: "transparent"
        visible: showText

        Base.StateLayer {
            visible: showText
            disabled: !toggle.enabled
            stateColor: Style.primary
            cornerRadius: parent.radius
            onClicked: toggle.handleClick()
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

        readonly property bool pressed: trackStateLayer.pressed && toggle.enabled
        readonly property real thumbSize: pressed ? Style.switchThumbPressed : (toggle.checked ? Style.switchThumbSelected : Style.switchThumbUnselected)
        readonly property real edgeLeft: (trackHeight - Style.switchThumbSelected) / 2
        readonly property real edgeRight: width - Style.switchThumbSelected - edgeLeft
        readonly property real thumbTarget: toggle.checked ? edgeRight : edgeLeft

        width: showText ? trackWidth : Math.max(parent.width, trackWidth)
        height: showText ? trackHeight : Math.max(parent.height, trackHeight)
        anchors.right: parent.right
        anchors.rightMargin: showText ? Style.spacingM : 0
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2

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
            value: toggleTrack.thumbTarget
            target: toggleTrack.thumbTarget
            onRunningChanged: {
                if (running || !toggle._settling)
                    return;
                toggle._settling = false;
                toggle.toggleCompleted(toggle.checked);
            }
        }

        Base.StyledRect {
            id: thumb

            readonly property real centerX: thumbSpring.value + Style.switchThumbSelected / 2

            width: toggleTrack.thumbSize
            height: toggleTrack.thumbSize
            radius: height / 2
            x: I18n.isRtl ? toggleTrack.width - centerX - width / 2 : centerX - width / 2
            anchors.verticalCenter: parent.verticalCenter

            color: {
                if (!toggle.enabled)
                    return toggle.checked ? Style.surface : Style.onSurface_38;
                if (toggle.checked)
                    return toggleTrack.pressed ? Style.primaryContainer : Style.onPrimary;
                return toggleTrack.pressed ? Style.onSurfaceVariant : Style.outline;
            }

            Behavior on width {
                enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
                }
            }

            Behavior on height {
                enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
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
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: thumb.x + thumb.width / 2 - width / 2
            color: toggle.checked ? Style.primary : Style.onSurface
            opacity: !toggle.enabled ? 0 : (trackStateLayer.pressed ? Style.stateLayerPressed : (trackStateLayer.containsMouse ? Style.stateLayerHover : 0))

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
            disabled: !toggle.enabled
            stateColor: "transparent"
            enableRipple: false
            cornerRadius: parent.radius
            onClicked: toggle.handleClick()
        }

        Base.FocusRing {
            visible: toggle.activeFocus
        }
    }
}
