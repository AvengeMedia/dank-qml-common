pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

DankGridView {
    id: grid

    property SelectionModel selection: null
    property real iconSize: FileBrowserMetrics.gridIconSizes[1]
    property string renamingPath: ""
    property var cutSet: ({})
    property bool dragEnabled: true
    property bool dropEnabled: true
    property bool multiSelect: true

    readonly property real minimumCellWidth: iconSize + FileBrowserMetrics.gridTilePadding * 2 + FileBrowserMetrics.gridGap
    readonly property int columnsPerRow: Math.max(1, Math.floor(width / minimumCellWidth))
    readonly property real contentOrigin: (headerItem?.y ?? 0) + (headerItem?.height ?? 0)

    signal itemClicked(int index, int modifiers)
    signal itemActivated(int index)
    signal itemContextMenu(int index, real pointX, real pointY, int modifiers)
    signal itemDragStarted(int index)
    signal itemDropped(int index, var drop)
    signal renameSubmitted(string path, string name)
    signal renameCancelled

    function visibleRange() {
        const first = Math.floor((contentY - contentOrigin) / cellHeight) * columnsPerRow;
        const last = Math.floor((contentY - contentOrigin + height) / cellHeight) * columnsPerRow + columnsPerRow - 1;
        return [Math.max(0, first), Math.min(count - 1, last)];
    }

    function indicesIn(rect) {
        const firstRow = Math.max(0, Math.floor((rect.y - contentOrigin) / cellHeight));
        const lastRow = Math.floor((rect.y + rect.height - contentOrigin) / cellHeight);
        const firstColumn = Math.max(0, Math.floor(rect.x / cellWidth));
        const lastColumn = Math.min(columnsPerRow - 1, Math.floor((rect.x + rect.width) / cellWidth));

        const out = [];
        for (let row = firstRow; row <= lastRow; row++) {
            for (let column = firstColumn; column <= lastColumn; column++) {
                const index = row * columnsPerRow + column;
                if (index >= 0 && index < count)
                    out.push(index);
            }
        }
        return out;
    }

    clip: true
    keyNavigationEnabled: false
    activeFocusOnTab: false
    cellWidth: Math.floor(width / columnsPerRow)
    cellHeight: iconSize + Style.fontSizeSmall * 3 + FileBrowserMetrics.gridTilePadding * 2 + FileBrowserMetrics.gridNameSpacing * 2
    cacheBuffer: Math.max(0, height)
    currentIndex: -1
    reuseItems: true

    delegate: FileTile {
        view: grid
    }
}
