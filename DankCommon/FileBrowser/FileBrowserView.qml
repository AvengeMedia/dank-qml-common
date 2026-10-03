pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common

FocusScope {
    id: root

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    property var backend: Host.files
    property bool showSidebar: true
    property bool showNavigation: true
    property bool showHidden: false
    property var filters: []
    property string sortKey: "name"
    property bool sortDescending: false
    property string viewMode: "list"
    property int gridZoom: 1
    property int listZoom: 1
    property var listColumns: ["size", "modified"]
    property var columnWidths: ({})
    property bool multiSelect: true
    property bool dragEnabled: false
    property bool dropEnabled: false
    property bool showSelectionFooter: multiSelect
    property bool escapeClearsSelection: true
    property string emptyText: I18n.tr("This folder is empty", "empty directory placeholder")
    property Component header: null
    property var cutSet: ({})
    property string nameFilter: ""
    property bool singleClickActivates: false
    property bool typeAheadEnabled: true
    property bool countFolders: true
    property bool dirsFirst: true
    property bool thumbnailsEnabled: true
    property real thumbnailSizeLimit: -1
    property bool networkThumbnails: true
    property var pathSuggestions: []
    property color paneColor: "transparent"
    property color chipColor: Style.chipSurface
    property real paneRadius: FileBrowserMetrics.paneRadius
    property real paneMargin: FileBrowserMetrics.paneMargin
    property real paneMarginHorizontal: FileBrowserMetrics.paneMarginHorizontal
    property real paneBorderWidth: 0
    property color paneBorderColor: Style.primary
    default property alias toolbarItems: toolbarExtras.data

    readonly property alias path: history.path
    readonly property alias canGoBack: history.canGoBack
    readonly property alias canGoForward: history.canGoForward
    readonly property alias canGoUp: history.canGoUp
    readonly property alias editingPath: pathBar.editing
    readonly property bool renaming: viewBody.renamingPath !== ""
    property int sidebarBreakpoint: FileBrowserMetrics.sidebarBreakpoint
    readonly property bool sidebarShown: showSidebar && width >= sidebarBreakpoint
    readonly property string homePath: backend?.userDirs?.find(dir => dir.key === "home")?.path ?? FilePaths.home
    readonly property alias selection: selectionModel
    readonly property alias directory: directory
    readonly property alias body: viewBody
    readonly property var currentEntry: viewBody.cursorEntry()
    readonly property var selectedEntries: viewBody.selectedEntries()

    property var _pendingReveal: []
    property bool _revealStarted: false

    signal activateRequested(var entry)
    signal itemMenuRequested(int index, real pointX, real pointY, int modifiers)
    signal backgroundMenuRequested(real pointX, real pointY)
    signal columnsMenuRequested(real pointX, real pointY)
    signal itemsDropped(string dest, var drop)
    signal dragRequested(var paths)
    signal renameRequested(string target, string name)
    signal sortRequested(string key)
    signal zoomRequested(string viewMode, int level)
    signal columnResizeRequested(string id, real width)
    signal focusRequested

    function navigate(target) {
        _pendingReveal = [];
        _stamp();
        history.go(target);
    }

    function back() {
        _pendingReveal = [];
        _stamp();
        history.back();
    }

    function forward() {
        _pendingReveal = [];
        _stamp();
        history.forward();
    }

    function up() {
        _pendingReveal = [];
        _stamp();
        history.up();
    }

    function reveal(targets) {
        const paths = [].concat(targets);
        const parent = FilePaths.parentOf(paths[0] ?? "");
        if (parent === "")
            return;
        _stamp();
        _revealStarted = false;
        _pendingReveal = paths.filter(path => FilePaths.parentOf(path) === parent);
        if (parent === history.path) {
            _applyPendingReveal();
            return;
        }
        history.go(parent);
    }

    function refresh() {
        directory.refresh();
    }

    function editPath() {
        pathBar.startEditing();
    }

    function focusBody() {
        viewBody.focusBody();
    }

    function beginRename(target) {
        viewBody.beginRename(target);
    }

    function saveState() {
        _stamp();
        return history.serialize();
    }

    function restoreState(state) {
        _pendingReveal = [];
        history.restore(state);
    }

    function marker() {
        return {
            "contentY": viewBody.scrollOffset(),
            "cursor": selectionModel.cursorPath
        };
    }

    function _stamp() {
        history.marker = marker();
    }

    function _applyPendingReveal() {
        if (_pendingReveal.length === 0)
            return;
        const found = viewBody.reveal(_pendingReveal, _revealStarted);
        if (found.length === 0)
            return;
        _revealStarted = true;
        _pendingReveal = _pendingReveal.filter(path => !found.includes(path));
    }

    onShowHiddenChanged: optionsSettle.restart()
    onSortKeyChanged: optionsSettle.restart()
    onSortDescendingChanged: optionsSettle.restart()
    onFiltersChanged: optionsSettle.restart()

    Timer {
        id: optionsSettle

        interval: 0
        onTriggered: directory.repage()
    }

    DirectoryModel {
        id: directory

        backend: root.backend
        path: root.path
        includeHidden: root.showHidden
        filters: root.filters
        sortKey: root.sortKey
        sortDesc: root.sortDescending
        dirsFirst: root.dirsFirst
        nameFilter: root.nameFilter
        thumbnailsEnabled: root.thumbnailsEnabled
        thumbnailSizeLimit: root.thumbnailSizeLimit
        networkThumbnails: root.networkThumbnails
        onGone: history.up()
        onListed: root._applyPendingReveal()
    }

    SelectionModel {
        id: selectionModel
    }

    NavigationHistory {
        id: history

        onRestored: saved => {
            if (saved?.cursor)
                selectionModel.select(saved.cursor);
            restoreScroll.pending = saved?.contentY ?? 0;
            restoreScroll.restart();
        }
    }

    Timer {
        id: restoreScroll

        property real pending: 0

        interval: 0
        onTriggered: viewBody.scrollTo(pending)
    }

    FileBrowserSidebar {
        id: sidebar

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.sidebarShown ? FileBrowserMetrics.sidebarWidth : 0
        visible: root.sidebarShown
        places: root.backend?.userDirs ?? []
        currentPath: root.path
        onPlaceSelected: target => {
            root.focusRequested();
            root.navigate(target);
        }
    }

    Item {
        id: main

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: sidebar.right
        anchors.leftMargin: root.sidebarShown ? FileBrowserMetrics.contentSpacing : 0
        anchors.right: parent.right

        Item {
            id: topbar

            readonly property bool shown: root.showNavigation || toolbarExtras.children.length > 0

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: shown ? FileBrowserMetrics.controlSize : 0
            visible: shown

            NavButtonPair {
                id: navPair

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showNavigation
                backEnabled: root.canGoBack
                forwardEnabled: root.canGoForward
                onBackRequested: root.back()
                onForwardRequested: root.forward()
            }

            Row {
                id: toolbarExtras

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: FileBrowserMetrics.controlSpacing
                LayoutMirroring.enabled: I18n.isRtl
                LayoutMirroring.childrenInherit: true
            }
        }

        Rectangle {
            id: pane

            anchors.top: topbar.bottom
            anchors.topMargin: topbar.shown ? FileBrowserMetrics.contentSpacing : 0
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            radius: root.paneRadius
            color: root.paneColor
            border.width: root.paneBorderWidth
            border.color: root.paneBorderColor

            PathBar {
                id: pathBar

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: root.paneMargin
                anchors.leftMargin: root.paneMarginHorizontal
                anchors.rightMargin: root.paneMarginHorizontal
                path: root.path
                homePath: root.homePath
                chipColor: root.chipColor
                suggestions: root.pathSuggestions
                backend: root.backend
                onEditingFinished: root.focusBody()
                onNavigated: target => {
                    root.focusRequested();
                    root.navigate(target);
                }
            }

            FileViewBody {
                id: viewBody

                anchors.top: pathBar.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: root.paneMargin
                anchors.bottomMargin: root.paneMargin
                anchors.leftMargin: root.paneMarginHorizontal
                anchors.rightMargin: root.paneMarginHorizontal
                focus: true
                directory: directory
                selection: selectionModel
                viewMode: root.viewMode
                gridZoom: root.gridZoom
                listZoom: root.listZoom
                listColumns: root.listColumns
                columnWidths: root.columnWidths
                sortKey: root.sortKey
                sortDescending: root.sortDescending
                showHidden: root.showHidden
                multiSelect: root.multiSelect
                dragEnabled: root.dragEnabled
                dropEnabled: root.dropEnabled
                showSelectionFooter: root.showSelectionFooter
                escapeClearsSelection: root.escapeClearsSelection
                emptyText: root.emptyText
                surfaceColor: root.paneColor
                header: root.header
                cutSet: root.cutSet
                singleClickActivates: root.singleClickActivates
                typeAheadEnabled: root.typeAheadEnabled
                countFolders: root.countFolders
                homePath: root.homePath
                nameHighlight: root.nameFilter
                onActivateRequested: entry => root.activateRequested(entry)
                onItemMenuRequested: (index, pointX, pointY, modifiers) => {
                    root.focusRequested();
                    const point = mapToItem(root, pointX, pointY);
                    root.itemMenuRequested(index, point.x, point.y, modifiers);
                }
                onBackgroundMenuRequested: (pointX, pointY) => {
                    root.focusRequested();
                    const point = mapToItem(root, pointX, pointY);
                    root.backgroundMenuRequested(point.x, point.y);
                }
                onColumnsMenuRequested: (pointX, pointY) => {
                    const point = mapToItem(root, pointX, pointY);
                    root.columnsMenuRequested(point.x, point.y);
                }
                onItemsDropped: (dest, drop) => root.itemsDropped(dest, drop)
                onDragRequested: paths => root.dragRequested(paths)
                onRenameRequested: (target, name) => root.renameRequested(target, name)
                onSortRequested: key => root.sortRequested(key)
                onZoomRequested: (mode, level) => root.zoomRequested(mode, level)
                onColumnResizeRequested: (id, width) => root.columnResizeRequested(id, width)
                onFocusRequested: root.focusRequested()
                onRevealRequested: target => {
                    root.focusRequested();
                    root.reveal(target);
                }
                onOpenRequested: target => {
                    root.focusRequested();
                    if (target === "..") {
                        root.up();
                        return;
                    }
                    root.navigate(target);
                }
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onTapped: (point, button) => {
            root.focusRequested();
            if (button === Qt.BackButton) {
                root.back();
                return;
            }
            root.forward();
        }
    }
}
