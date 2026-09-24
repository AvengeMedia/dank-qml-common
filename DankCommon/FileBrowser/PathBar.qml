pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

FocusScope {
    id: bar

    property string path: ""
    property string homePath: FilePaths.home
    property color chipColor: Style.chipSurface
    property bool editing: false

    signal navigated(string target)
    signal editingFinished

    readonly property var segments: bar.segmentsFor(path, homePath)

    function segmentsFor(path, home) {
        if (path === "")
            return [];

        const rooted = home !== "" && (path === home || path.startsWith(home + "/"));
        const head = rooted ? {
            "label": "",
            "iconName": "home",
            "path": home
        } : {
            "label": "",
            "iconName": "hard_drive",
            "path": "/"
        };

        const rest = rooted ? path.substring(home.length) : path;
        const out = [head];
        let walked = head.path === "/" ? "" : head.path;
        for (const name of rest.split("/")) {
            if (name === "")
                continue;
            walked = walked + "/" + name;
            out.push({
                "label": name,
                "iconName": "",
                "path": walked
            });
        }
        return out;
    }

    function startEditing() {
        editing = true;
        field.text = path;
        field.forceActiveFocus();
        field.selectAll();
    }

    function stopEditing() {
        editing = false;
        editingFinished();
    }

    implicitHeight: FileBrowserMetrics.pathPillHeight

    Keys.onEscapePressed: event => {
        if (!editing) {
            event.accepted = false;
            return;
        }
        stopEditing();
    }

    DankFlickable {
        id: strip

        readonly property bool mirrored: LayoutMirroring.enabled
        readonly property real overflow: Math.max(0, contentWidth - width)

        function scrollToCurrent() {
            contentX = mirrored ? 0 : overflow;
        }

        anchors.fill: parent
        visible: !bar.editing
        wheelEnabled: false
        clip: true
        flickableDirection: Flickable.HorizontalFlick
        contentWidth: Math.max(width, pills.width)
        contentHeight: height

        onContentWidthChanged: scrollToCurrent()
        onWidthChanged: scrollToCurrent()

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                strip.contentX = Math.max(0, Math.min(strip.contentWidth - strip.width, strip.contentX - delta));
            }
        }

        MouseArea {
            width: Math.max(strip.width, pills.width)
            height: strip.height
            cursorShape: Qt.PointingHandCursor
            onClicked: bar.startEditing()
        }

        Row {
            id: pills

            x: strip.mirrored ? strip.contentWidth - width : 0
            height: strip.height
            spacing: FileBrowserMetrics.pathBarSpacing

            Repeater {
                model: bar.segments

                Row {
                    id: segment

                    required property int index
                    required property var modelData

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: FileBrowserMetrics.pathBarSpacing

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: segment.index > 0
                        text: "/"
                        color: Style.outline
                        font.pixelSize: Style.fontSizeMedium
                    }

                    PathPill {
                        label: segment.modelData.iconName === "home" ? I18n.tr("Home", "file browser quick access location") : segment.modelData.label
                        iconName: segment.modelData.iconName
                        chipColor: bar.chipColor
                        current: segment.index === bar.segments.length - 1
                        onClicked: bar.navigated(segment.modelData.path)
                    }
                }
            }
        }
    }

    DankTextField {
        id: field

        anchors.fill: parent
        visible: bar.editing
        cornerRadius: FileBrowserMetrics.pathPillRadius
        controlHeight: bar.height
        backgroundColor: bar.chipColor
        leftIconName: "edit_location"
        leftIconSize: FileBrowserMetrics.pathIconSize
        font.pixelSize: Style.fontSizeMedium
        keyForwardTargets: [bar]
        Keys.onReturnPressed: event => event.accepted = true
        Keys.onEnterPressed: event => event.accepted = true
        onAccepted: {
            const target = FilePaths.expandTilde(text.trim());
            bar.stopEditing();
            if (target.startsWith("/"))
                bar.navigated(target);
        }
        onFocusStateChanged: hasFocus => {
            if (!hasFocus && bar.editing)
                bar.editing = false;
        }
    }
}
