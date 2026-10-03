pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.DankCommon.Common
import qs.DankCommon.Widgets

// A non-modal list under a text field: typing keeps the field's focus, the
// arrows move the highlight, Enter or a click picks a row.
Popup {
    id: root

    property Item anchorItem: null
    property var paths: []
    property int highlightIndex: -1
    property string homePath: FilePaths.home

    signal chosen(string path)

    function move(delta) {
        const count = paths.length;
        if (count === 0)
            return;
        let next = highlightIndex + delta;
        if (next >= count)
            next = -1;
        if (next < -1)
            next = count - 1;
        highlightIndex = next;
    }

    function highlightedPath() {
        return highlightIndex >= 0 && highlightIndex < paths.length ? paths[highlightIndex] : "";
    }

    function labelFor(path) {
        if (homePath !== "" && (path === homePath || path.startsWith(homePath + "/")))
            return "~" + path.substring(homePath.length);
        return path;
    }

    parent: anchorItem
    x: 0
    y: (anchorItem?.height ?? 0) + Style.spacingXS
    width: Math.max(anchorItem?.width ?? 0, Style.launcherWidthMicro * 0.6)
    padding: Style.spacingXS
    modal: false
    dim: false
    focus: false
    closePolicy: Popup.NoAutoClose
    onPathsChanged: {
        if (highlightIndex >= paths.length)
            highlightIndex = -1;
    }

    background: Item {
        ElevationShadow {
            anchors.fill: parent
            level: Style.elevationLevel2
            fallbackOffset: Style.spacingXS
            targetRadius: Style.cornerRadiusL
            targetColor: Style.surfaceContainer
            borderColor: Style.outlineMedium
            borderWidth: Style.layerOutlineWidth
            shadowEnabled: Style.elevationEnabled && Style.popoutElevationEnabled
        }
    }

    contentItem: Column {
        spacing: 0

        Repeater {
            model: root.paths

            FileMenuItem {
                required property string modelData
                required property int index

                text: root.labelFor(modelData)
                iconName: "folder"
                focusPolicy: Qt.NoFocus
                highlighted: index === root.highlightIndex
                onClicked: root.chosen(modelData)
            }
        }
    }
}
