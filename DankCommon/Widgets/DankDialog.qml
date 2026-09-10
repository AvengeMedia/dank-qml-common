import QtQuick
import QtQuick.Window
import qs.DankCommon.Common

FocusScope {
    id: root

    property string title: ""
    property string iconName: ""
    property string supportingText: ""
    property var windowControls: null
    property bool closeEnabled: true
    property bool acceptEnabled: true
    property bool embedded: true
    property bool opened: true
    readonly property bool nativeWindow: windowControls !== null
    readonly property real contentSpacing: nativeWindow ? Style.spacingM : Style.spacingL
    property real padding: nativeWindow ? Style.spacingL : Style.spacingXL
    property real maximumWidth: Style.dialogMaxWidth
    property real maximumHeight: Infinity
    property color surfaceColor: Style.surfaceContainerHigh
    default property alias content: body.data
    property alias actions: actionFlow.data
    readonly property alias contentItem: body
    readonly property real actionWidth: surface.width - padding * 2
    readonly property real contentHeight: scrollBody.implicitHeight
    readonly property real focusPadding: Style.focusRingOffset + Style.focusRingWidth
    readonly property real availableContentHeight: Math.max(0, scroll.height - focusPadding * 2)

    signal accepted
    signal rejected

    implicitWidth: maximumWidth
    implicitHeight: header.implicitHeight + scrollBody.implicitHeight + actionFlow.implicitHeight + padding * (nativeWindow ? 1 : 2) + contentSpacing * (actionFlow.implicitHeight > 0 ? 2 : 1)
    focus: true
    Accessible.role: Accessible.Dialog
    Accessible.name: title
    Accessible.description: supportingText
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    Keys.onPressed: event => {
        if (event.isAutoRepeat || (!root.embedded && !root.opened))
            return;
        switch (event.key) {
        case Qt.Key_Escape:
            if (!root.closeEnabled)
                return;
            root.rejected();
            event.accepted = true;
            return;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (!root.acceptEnabled)
                return;
            root.accepted();
            event.accepted = true;
            return;
        }
    }

    function revealFocus() {
        const item = root.Window.window?.activeFocusItem;
        if (!item || !root.visible)
            return;
        let target = item;
        let ancestor = item;
        while (ancestor && ancestor !== body) {
            if (typeof ancestor.getActiveFocus === "function")
                target = ancestor;
            ancestor = ancestor.parent;
        }
        if (!ancestor)
            return;
        const point = target.mapToItem(scroll.contentItem, 0, 0);
        const top = point.y - root.focusPadding;
        const bottom = point.y + target.height + root.focusPadding;
        if (top < scroll.contentY)
            scroll.contentY = Math.max(0, top);
        else if (bottom > scroll.contentY + scroll.height)
            scroll.contentY = Math.max(0, Math.min(scroll.contentHeight - scroll.height, bottom - scroll.height));
    }

    data: [
        Connections {
            target: root.Window.window
            function onActiveFocusItemChanged() {
                root.revealFocus();
            }
        },
        Rectangle {
            anchors.fill: parent
            visible: !root.embedded && (root.opened || opacity > 0)
            color: Style.scrimColor
            opacity: root.opened ? Style.scrimAlpha : 0

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (root.closeEnabled)
                        root.rejected();
                }
            }

            Behavior on opacity {
                enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveEffects
                    easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                }
            }
        },
        Item {
            id: surface

            anchors.centerIn: parent
            width: root.embedded ? parent.width : Math.max(0, Math.min(root.maximumWidth, parent.width - root.padding * 2))
            height: root.embedded ? parent.height : Math.max(0, Math.min(root.implicitHeight, root.maximumHeight, parent.height - root.padding * 2))
            visible: root.embedded || root.opened || opacity > 0
            enabled: root.embedded || root.opened
            property real entryScale: root.embedded || root.opened ? 1 : Style.popupEnterScale
            scale: Math.min(1, entryScale)
            opacity: root.embedded || root.opened ? 1 : 0

            Behavior on entryScale {
                enabled: !root.embedded && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveDefaultSpatial
                    easing.bezierCurve: Style.expressiveCurves.expressiveDefaultSpatial
                }
            }
            Behavior on opacity {
                enabled: !root.embedded && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveEffects
                    easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                }
            }

            ElevationShadow {
                anchors.fill: parent
                visible: !root.embedded
                level: Style.elevationLevel3
                targetRadius: Style.cornerRadiusXL
                targetColor: root.surfaceColor
                shadowEnabled: Style.elevationEnabled
            }

            MouseArea {
                anchors.fill: parent
                enabled: !root.embedded
            }

            DankWindowHeader {
                id: header

                x: root.nativeWindow ? 0 : root.padding
                y: root.nativeWindow ? 0 : root.padding
                width: parent.width - (root.nativeWindow ? 0 : root.padding * 2)
                controls: root.windowControls
                title: root.title
                iconName: root.iconName
                titleFontSize: root.nativeWindow ? Style.fontSizeLarge : Style.fontSizeXLarge
                wrapTitle: !root.nativeWindow
                horizontalPadding: root.nativeWindow ? -1 : 0
                showDivider: root.nativeWindow
                closeEnabled: root.closeEnabled
                onCloseRequested: root.rejected()
            }

            DankFlickable {
                id: scroll

                x: root.padding - root.focusPadding
                y: header.y + header.height + root.contentSpacing - root.focusPadding
                width: parent.width - root.padding * 2 + root.focusPadding * 2
                height: Math.max(0, actionFlow.y - y - (actionFlow.height > 0 ? root.contentSpacing : 0) + root.focusPadding)
                contentWidth: width
                contentHeight: scrollBody.implicitHeight + root.focusPadding * 2
                clip: true

                Column {
                    id: scrollBody
                    x: root.focusPadding
                    y: root.focusPadding
                    width: scroll.width - root.focusPadding * 2
                    spacing: root.contentSpacing

                    StyledText {
                        width: parent.width
                        text: root.supportingText
                        color: Style.onSurfaceVariant
                        font.pixelSize: Style.fontSizeMedium
                        wrapMode: Text.Wrap
                        visible: text.length > 0
                    }

                    Column {
                        id: body
                        width: parent.width
                        spacing: Style.spacingM
                    }
                }
            }

            Flow {
                id: actionFlow

                readonly property real naturalWidth: children.reduce((total, item) => total + (item.visible ? item.width + spacing : 0), -spacing)
                width: Math.min(Math.max(0, naturalWidth), parent.width - root.padding * 2)
                anchors.right: parent.right
                anchors.rightMargin: root.padding
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.padding
                spacing: Style.spacingS
            }
        }
    ]
}
