pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

FocusScope {
    id: bar

    property string path: ""
    property string homePath: FilePaths.home
    property color chipColor: Style.chipSurface
    property bool editing: false
    property var suggestions: []
    property var backend: null

    property var completions: []
    property string completionKey: ""
    property int completionRequest: 0

    readonly property bool canComplete: typeof backend?.list === "function"
    readonly property string typedPath: {
        const typed = field.text.trim();
        if (typed === "" || !(typed.startsWith("/") || typed.startsWith("~")))
            return "";
        const expanded = FilePaths.expandTilde(typed);
        return expanded === path ? expanded + "/" : expanded;
    }
    readonly property string completionDir: {
        if (typedPath === "")
            return "";
        if (typedPath.endsWith("/"))
            return typedPath.length > 1 ? typedPath.replace(/\/+$/, "") : "/";
        return FilePaths.parentOf(typedPath);
    }
    readonly property string completionPrefix: typedPath.endsWith("/") ? "" : FilePaths.baseName(typedPath).toLowerCase()

    readonly property var matchingSuggestions: {
        if (!editing)
            return [];
        if (typedPath !== "" && canComplete)
            return completions.filter(entry => entry.name.toLowerCase().startsWith(completionPrefix)).slice(0, FileBrowserMetrics.suggestionRows).map(entry => entry.path);
        const typed = field.text.trim().toLowerCase();
        const out = [];
        for (const candidate of suggestions) {
            if (candidate === "" || candidate.toLowerCase() === typed || (typed !== "" && !candidate.toLowerCase().includes(typed)))
                continue;
            out.push(candidate);
            if (out.length >= FileBrowserMetrics.suggestionRows)
                break;
        }
        return out;
    }

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
        suggestionPopup.highlightIndex = -1;
        field.forceActiveFocus();
        field.selectAll();
        fetchCompletions();
    }

    function fetchCompletions() {
        if (!editing || !canComplete || completionDir === "") {
            completions = [];
            completionKey = "";
            return;
        }
        const hidden = completionPrefix.startsWith(".");
        const key = completionDir + (hidden ? "\u0000." : "");
        if (key === completionKey)
            return;
        completionKey = key;
        const request = ++completionRequest;
        backend.list(completionDir, {
            "limit": FileBrowserMetrics.completionLimit,
            "includeHidden": hidden,
            "dirsFirst": true,
            "sortKey": "name"
        }, result => {
            if (request !== bar.completionRequest)
                return;
            bar.completions = result.error ? [] : (result.entries || []).filter(entry => entry.isDir);
        });
    }

    function completeHighlighted() {
        const picked = suggestionPopup.highlightedPath() !== "" ? suggestionPopup.highlightedPath() : (matchingSuggestions.length === 1 ? matchingSuggestions[0] : "");
        if (picked === "")
            return false;
        field.text = picked + "/";
        field.cursorPosition = field.text.length;
        suggestionPopup.highlightIndex = -1;
        return true;
    }

    function stopEditing() {
        editing = false;
        suggestionPopup.highlightIndex = -1;
        completions = [];
        completionKey = "";
        editingFinished();
    }

    onCompletionDirChanged: fetchCompletions()
    onCompletionPrefixChanged: {
        if (completionPrefix.startsWith(".") !== completionKey.endsWith("."))
            fetchCompletions();
    }

    function acceptTyped() {
        const picked = suggestionPopup.highlightedPath();
        const target = picked !== "" ? picked : FilePaths.expandTilde(field.text.trim());
        stopEditing();
        if (target.startsWith("/"))
            navigated(target);
    }

    implicitHeight: FileBrowserMetrics.pathPillHeight

    Keys.onEscapePressed: event => {
        if (!editing) {
            event.accepted = false;
            return;
        }
        stopEditing();
    }

    Keys.onPressed: event => {
        if (!editing || matchingSuggestions.length === 0)
            return;
        switch (event.key) {
        case Qt.Key_Down:
            suggestionPopup.move(1);
            break;
        case Qt.Key_Up:
            suggestionPopup.move(-1);
            break;
        case Qt.Key_Tab:
            if (!completeHighlighted())
                return;
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    PathSuggestions {
        id: suggestionPopup

        anchorItem: field
        paths: bar.matchingSuggestions
        visible: bar.editing && bar.matchingSuggestions.length > 0
        onChosen: target => {
            bar.stopEditing();
            bar.navigated(target);
        }
    }

    DFlickable {
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

    DTextField {
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
        onAccepted: bar.acceptTyped()
        onTextChanged: suggestionPopup.highlightIndex = -1
        onFocusStateChanged: hasFocus => {
            if (hasFocus || !bar.editing)
                return;
            bar.editing = false;
            suggestionPopup.highlightIndex = -1;
        }
    }
}
