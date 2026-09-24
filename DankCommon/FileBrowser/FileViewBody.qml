pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

FocusScope {
    id: body

    required property DirectoryModel directory
    required property SelectionModel selection

    property string viewMode: "list"
    property int gridZoom: 1
    property int listZoom: 1
    property var listColumns: ["size", "modified"]
    property var columnWidths: ({})
    property string sortKey: "name"
    property bool sortDescending: false
    property bool showHidden: false
    property bool multiSelect: true
    property bool dragEnabled: true
    property bool dropEnabled: true
    property bool showSelectionFooter: true
    property bool escapeClearsSelection: true
    property string emptyText: I18n.tr("This folder is empty", "empty directory placeholder")
    property color surfaceColor: "transparent"
    property Component header: null
    property string renamingPath: ""
    property var cutSet: ({})
    property var childCounts: ({})

    readonly property var view: viewLoader.item
    readonly property bool columnsScroll: header !== null && viewMode === "list"
    readonly property int zoom: viewMode === "grid" ? gridZoom : listZoom
    readonly property real iconSize: viewMode === "grid" ? FileBrowserMetrics.gridIconSizes[zoom] : FileBrowserMetrics.listIconSizes[zoom]
    readonly property bool listing: directory.loading && directory.count === 0
    readonly property bool empty: !directory.loading && directory.error === "" && directory.count === 0

    signal activateRequested(var entry)
    signal itemMenuRequested(int index, real pointX, real pointY, int modifiers)
    signal backgroundMenuRequested(real pointX, real pointY)
    signal columnsMenuRequested(real pointX, real pointY)
    signal itemsDropped(string dest, var drop)
    signal dragRequested(var paths)
    signal renameRequested(string path, string name)
    signal openRequested(string path)
    signal focusRequested
    signal sortRequested(string key)
    signal zoomRequested(string viewMode, int level)
    signal columnResizeRequested(string id, real width)

    function focusBody() {
        forceActiveFocus();
    }

    function entryAt(index) {
        return index >= 0 && index < directory.count ? directory.entries.get(index) : null;
    }

    function cursorIndex() {
        return selection.cursorPath === "" ? -1 : directory.indexOfPath(selection.cursorPath);
    }

    function cursorEntry() {
        return entryAt(cursorIndex());
    }

    function selectedEntries() {
        return selection.paths.map(selected => entryAt(directory.indexOfPath(selected))).filter(entry => entry !== null);
    }

    function beginRename(target) {
        renamingPath = target;
    }

    function finishRename(target, name) {
        renamingPath = "";
        focusBody();
        if (target !== "")
            renameRequested(target, name);
    }

    function forwardItemMenu(source, index, pointX, pointY, modifiers) {
        const point = source.mapToItem(body, pointX, pointY);
        itemMenuRequested(index, point.x, point.y, modifiers);
    }

    function zoomBy(step) {
        const level = Math.max(0, Math.min(FileBrowserMetrics.gridIconSizes.length - 1, zoom + step));
        if (level === zoom)
            return;
        zoomRequested(viewMode, level);
    }

    function reveal(target) {
        const index = directory.indexOfPath(target);
        if (index < 0)
            return false;
        selection.select(target);
        view?.positionViewAtIndex(index, ListView.Center);
        return true;
    }

    function activate(index) {
        const entry = entryAt(index);
        if (!entry)
            return;
        selection.select(entry.path);
        activateRequested(entry);
    }

    function click(index, modifiers) {
        focusRequested();
        const entry = entryAt(index);
        if (!entry)
            return;
        selection.keyboardCursor = false;
        if (!multiSelect) {
            selection.select(entry.path);
            return;
        }
        if ((modifiers & Qt.ShiftModifier) !== 0) {
            selection.extendTo(directory.entries, index);
            return;
        }
        if ((modifiers & Qt.ControlModifier) !== 0) {
            selection.toggle(entry.path);
            return;
        }
        selection.select(entry.path);
    }

    function moveTo(target, modifiers) {
        view?.positionViewAtIndex(target, ListView.Contain);
        selection.keyboardCursor = true;
        if (multiSelect && (modifiers & Qt.ShiftModifier) !== 0) {
            selection.extendTo(directory.entries, target);
            return;
        }
        selection.select(directory.entries.get(target).path);
    }

    function moveCursor(step, modifiers) {
        if (directory.count === 0)
            return;
        const current = cursorIndex();
        moveTo(Math.max(0, Math.min(directory.count - 1, current < 0 ? 0 : current + step)), modifiers);
    }

    function jumpTo(index, modifiers) {
        if (directory.count === 0)
            return;
        moveTo(Math.max(0, Math.min(directory.count - 1, index)), modifiers);
    }

    function pageStep() {
        if (viewMode === "grid")
            return Math.max(1, Math.floor(view.height / view.cellHeight)) * view.columnsPerRow;
        return Math.max(1, Math.floor(view.height / view.rowPitch));
    }

    function typeAhead(text) {
        const prefix = (typeAheadTimer.prefix + text).toLowerCase();
        typeAheadTimer.prefix = prefix;
        typeAheadTimer.restart();
        for (let i = 0; i < directory.count; i++) {
            if (!directory.entries.get(i).name.toLowerCase().startsWith(prefix))
                continue;
            jumpTo(i, Qt.NoModifier);
            return;
        }
    }

    function requestCounts(first, last) {
        if (viewMode !== "list" || !listColumns.includes("size"))
            return;
        const wanted = [];
        for (let i = first; i <= Math.min(last, directory.count - 1); i++) {
            const entry = entryAt(i);
            if (!entry?.isDir || childCounts[entry.path] !== undefined)
                continue;
            wanted.push(entry.path);
        }
        if (wanted.length === 0 || !directory.backend)
            return;
        directory.backend.count(wanted, showHidden, result => {
            if (result.error)
                return;
            const merged = Object.assign({}, body.childCounts);
            for (const path in result.counts || ({})) {
                const count = result.counts[path];
                merged[path] = count.code ? -1 : count.count;
            }
            body.childCounts = merged;
        });
    }

    function selectedBytes() {
        let total = 0;
        for (const entry of selectedEntries()) {
            if (entry.size < 0)
                return -1;
            total += entry.size;
        }
        return total;
    }

    function startDrag(index) {
        const entry = entryAt(index);
        if (!entry)
            return;
        if (!selection.contains(entry.path))
            selection.select(entry.path);
        dragRequested(selection.paths.slice());
    }

    onViewModeChanged: renamingPath = ""

    Connections {
        target: body.directory

        function onPathReset() {
            body.selection.clear();
            body.renamingPath = "";
            body.childCounts = ({});
            body.view?.positionViewAtBeginning();
        }

        function onListed() {
            body.selection.prune(body.directory.entries);
            settle.restart();
        }
    }

    Timer {
        id: typeAheadTimer

        property string prefix: ""

        interval: FileBrowserMetrics.typeAheadInterval
        onTriggered: prefix = ""
    }

    Timer {
        id: settle

        interval: FileBrowserMetrics.settleInterval
        onTriggered: {
            if (!body.view)
                return;
            const range = body.view.visibleRange();
            body.directory.requestThumbnails(range[0], range[1]);
            body.requestCounts(range[0], range[1]);
            if (range[1] >= body.directory.count - 1)
                body.directory.loadMore();
        }
    }

    Keys.onPressed: event => {
        const modifiers = event.modifiers;
        const columns = view?.columnsPerRow ?? 1;
        if ((modifiers & Qt.AltModifier) !== 0)
            return;
        switch (event.key) {
        case Qt.Key_Down:
            moveCursor(columns, modifiers);
            break;
        case Qt.Key_Up:
            moveCursor(-columns, modifiers);
            break;
        case Qt.Key_Right:
            moveCursor(viewMode === "grid" ? 1 : columns, modifiers);
            break;
        case Qt.Key_Left:
            moveCursor(viewMode === "grid" ? -1 : -columns, modifiers);
            break;
        case Qt.Key_Home:
            jumpTo(0, modifiers);
            break;
        case Qt.Key_End:
            jumpTo(directory.count - 1, modifiers);
            break;
        case Qt.Key_PageDown:
            moveCursor(pageStep(), modifiers);
            break;
        case Qt.Key_PageUp:
            moveCursor(-pageStep(), modifiers);
            break;
        case Qt.Key_Space:
            if (selection.cursorPath === "")
                break;
            selection.keyboardCursor = true;
            if (multiSelect) {
                selection.toggle(selection.cursorPath);
                break;
            }
            selection.select(selection.cursorPath);
            break;
        case Qt.Key_Escape:
            if (!escapeClearsSelection || selection.empty)
                return;
            selection.clear();
            break;
        case Qt.Key_Backspace:
            if (typeAheadTimer.prefix !== "") {
                typeAheadTimer.prefix = "";
                break;
            }
            openRequested("..");
            break;
        default:
            if (modifiers !== Qt.NoModifier && modifiers !== Qt.ShiftModifier)
                return;
            if (event.text === "" || event.text.charCodeAt(0) < 0x20)
                return;
            typeAhead(event.text);
        }
        event.accepted = true;
    }

    WheelHandler {
        acceptedModifiers: Qt.ControlModifier
        onWheel: event => body.zoomBy(event.angleDelta.y > 0 ? 1 : -1)
    }

    component ViewBackground: FileViewBackground {
        selection: body.selection
        onCleared: {
            body.focusRequested();
            body.selection.clear();
        }
        onContextMenuRequested: (pointX, pointY) => {
            const point = view.mapToItem(body, pointX, pointY);
            body.backgroundMenuRequested(point.x, point.y);
        }
        onDropped: drop => body.itemsDropped(body.directory.path, drop)
    }

    Component {
        id: listComponent

        FileListView {
            id: listView

            selection: body.selection
            iconSize: body.iconSize
            renamingPath: body.renamingPath
            cutSet: body.cutSet
            childCounts: body.childCounts
            columnIds: body.listColumns
            storedWidths: body.columnWidths
            multiSelect: body.multiSelect
            dragEnabled: body.dragEnabled
            dropEnabled: body.dropEnabled
            model: body.directory.entries
            header: body.columnsScroll ? scrollingHeader : body.header
            onItemClicked: (index, modifiers) => body.click(index, modifiers)
            onItemActivated: index => body.activate(index)
            onItemContextMenu: (index, pointX, pointY, modifiers) => body.forwardItemMenu(listView, index, pointX, pointY, modifiers)
            onItemDragStarted: index => body.startDrag(index)
            onItemDropped: (index, drop) => body.itemsDropped(body.entryAt(index).path, drop)
            onRenameSubmitted: (target, name) => body.finishRename(target, name)
            onRenameCancelled: body.finishRename("", "")
            onContentYChanged: settle.restart()
            onCountChanged: settle.restart()

            ViewBackground {
                view: listView
            }
        }
    }

    Component {
        id: gridComponent

        FileGridView {
            id: gridView

            selection: body.selection
            iconSize: body.iconSize
            renamingPath: body.renamingPath
            cutSet: body.cutSet
            multiSelect: body.multiSelect
            dragEnabled: body.dragEnabled
            dropEnabled: body.dropEnabled
            model: body.directory.entries
            header: body.header
            onItemClicked: (index, modifiers) => body.click(index, modifiers)
            onItemActivated: index => body.activate(index)
            onItemContextMenu: (index, pointX, pointY, modifiers) => body.forwardItemMenu(gridView, index, pointX, pointY, modifiers)
            onItemDragStarted: index => body.startDrag(index)
            onItemDropped: (index, drop) => body.itemsDropped(body.entryAt(index).path, drop)
            onRenameSubmitted: (target, name) => body.finishRename(target, name)
            onRenameCancelled: body.finishRename("", "")
            onContentYChanged: settle.restart()
            onCountChanged: settle.restart()

            ViewBackground {
                view: gridView
            }
        }
    }

    component ColumnHeader: FileColumnHeader {
        id: columns

        columnIds: body.listColumns
        widths: body.columnWidths
        sortKey: body.sortKey
        sortDescending: body.sortDescending
        nameIndent: body.iconSize + FileBrowserMetrics.listRowPadding * 2
        backgroundColor: body.surfaceColor
        onSortRequested: key => body.sortRequested(key)
        onColumnsMenuRequested: (pointX, pointY) => {
            const point = columns.mapToItem(body, pointX, pointY);
            body.columnsMenuRequested(point.x, point.y);
        }
        onColumnResized: (id, width) => body.columnResizeRequested(id, width)
    }

    Component {
        id: scrollingHeader

        Column {
            width: parent?.width ?? 0

            Loader {
                width: parent.width
                sourceComponent: body.header
            }

            ColumnHeader {
                width: parent.width
            }
        }
    }

    ColumnHeader {
        id: columnHeader

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: body.viewMode === "list" && !body.columnsScroll
        height: visible ? implicitHeight : 0
    }

    Loader {
        id: viewLoader

        anchors.top: columnHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        sourceComponent: body.viewMode === "grid" ? gridComponent : listComponent
    }

    LoadingSkeleton {
        anchors.fill: viewLoader
        anchors.topMargin: body.view?.headerItem?.height ?? 0
        visible: body.listing
        rowHeight: body.viewMode === "grid" ? FileBrowserMetrics.gridIconSizes[body.zoom] : FileBrowserMetrics.listRowHeightFor(body.iconSize)
    }

    StyledText {
        anchors.centerIn: viewLoader
        visible: body.empty && body.emptyText !== ""
        text: body.emptyText
        color: Style.surfaceVariantText
        font.pixelSize: Style.fontSizeLarge
    }

    StyledText {
        anchors.centerIn: viewLoader
        width: viewLoader.width - Style.spacingL * 2
        visible: body.directory.error !== ""
        text: FileFormat.listingError(body.directory.errorCode)
        color: Style.surfaceVariantText
        font.pixelSize: Style.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    SelectionFooter {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Style.spacingM
        visible: body.showSelectionFooter && body.selection.count > 1
        width: Math.min(implicitWidth, body.width - Style.spacingL * 2)
        count: body.selection.count
        bytes: body.selectedBytes()
        onCleared: body.selection.clear()
    }
}
