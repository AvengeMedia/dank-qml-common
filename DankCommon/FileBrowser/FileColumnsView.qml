pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

Item {
    id: columns

    required property var body

    readonly property var activeList: activeColumn.list
    readonly property int columnsPerRow: 1
    readonly property real rowPitch: activeList.rowPitch
    readonly property real originY: activeList.originY
    readonly property real contentY: activeList.contentY
    readonly property real contentHeight: activeList.contentHeight
    readonly property var headerItem: null
    readonly property string activePath: body.directory.path
    readonly property string rootPath: {
        const home = body.homePath;
        if (home !== "" && (activePath === home || activePath.startsWith(home + "/")))
            return home;
        return "/";
    }
    readonly property var ancestors: {
        const out = [];
        let current = FilePaths.parentOf(activePath);
        while (current !== "" && current.length >= rootPath.length) {
            out.unshift(current);
            if (current === rootPath)
                break;
            current = FilePaths.parentOf(current);
        }
        return out;
    }
    readonly property var picked: body.selectedEntries()
    readonly property var pickedEntry: picked.length === 1 ? picked[0] : null
    readonly property string lookaheadPath: pickedEntry?.isDir ? pickedEntry.path : ""

    signal viewportChanged

    function positionViewAtIndex(index, mode) {
        activeList.positionViewAtIndex(index, mode);
    }

    function positionViewAtBeginning() {
        activeList.positionViewAtBeginning();
    }

    function itemAtIndex(index) {
        return activeList.itemAtIndex(index);
    }

    function visibleRange() {
        return activeList.visibleRange();
    }

    function syncAncestors() {
        const wanted = ancestors;
        let common = 0;
        while (common < wanted.length && common < ancestorModel.count && ancestorModel.get(common).dirPath === wanted[common])
            common++;
        while (ancestorModel.count > common)
            ancestorModel.remove(ancestorModel.count - 1);
        for (let i = common; i < wanted.length; i++)
            ancestorModel.append({
                "dirPath": wanted[i]
            });
    }

    function entryOf(model, index) {
        return index >= 0 && index < model.count ? model.entries.get(index) : null;
    }

    onAncestorsChanged: syncAncestors()
    Component.onCompleted: syncAncestors()

    ListModel {
        id: ancestorModel
    }

    component ColumnFrame: Item {
        id: frame

        property real paneWidth: FileBrowserMetrics.columnPaneWidth

        width: paneWidth
        height: strip.height

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Style.dividerWidth
            color: Style.outlineVariant
        }
    }

    component DirColumn: ColumnFrame {
        id: column

        required property string dirPath
        property string childPath: ""

        readonly property DirectoryModel model: DirectoryModel {
            backend: columns.body.directory.backend
            path: column.dirPath
            includeHidden: columns.body.directory.includeHidden
            filters: columns.body.directory.filters
            sortKey: columns.body.directory.sortKey
            sortDesc: columns.body.directory.sortDesc
            dirsFirst: columns.body.directory.dirsFirst
            thumbnailsEnabled: columns.body.directory.thumbnailsEnabled
            thumbnailSizeLimit: columns.body.directory.thumbnailSizeLimit
            networkThumbnails: columns.body.directory.networkThumbnails
            onListed: column.syncChild()
        }
        readonly property SelectionModel selection: SelectionModel {}

        function syncChild() {
            if (childPath === "") {
                selection.clear();
                return;
            }
            selection.select(childPath);
        }

        onChildPathChanged: syncChild()

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: columns.body.openRequested(column.dirPath)
        }

        DropArea {
            anchors.fill: parent
            enabled: columns.body.dropEnabled
            onDropped: drop => columns.body.itemsDropped(column.dirPath, drop)
        }

        FileListView {
            id: list

            anchors.fill: parent
            anchors.rightMargin: Style.dividerWidth
            selection: column.selection
            iconSize: columns.body.iconSize
            cutSet: columns.body.cutSet
            columnIds: []
            chevrons: true
            multiSelect: false
            dragEnabled: false
            dropEnabled: columns.body.dropEnabled
            singleClickActivates: false
            model: column.model.entries
            onItemClicked: index => columns.body.revealRequested(columns.entryOf(column.model, index).path)
            onItemActivated: index => {
                const entry = columns.entryOf(column.model, index);
                if (!entry)
                    return;
                if (entry.isDir) {
                    columns.body.openRequested(entry.path);
                    return;
                }
                columns.body.activateRequested(entry);
            }
            onItemContextMenu: (index, pointX, pointY, modifiers) => {
                const entry = columns.entryOf(column.model, index);
                if (!entry)
                    return;
                columns.body.revealRequested(entry.path);
                const point = list.mapToItem(columns.body, pointX, pointY);
                columns.body.itemMenuRequested(index, point.x, point.y, modifiers);
            }
            onItemDropped: (index, drop) => columns.body.itemsDropped(columns.entryOf(column.model, index).path, drop)
            onContentYChanged: settle.restart()
            onCountChanged: settle.restart()
        }

        Timer {
            id: settle

            interval: FileBrowserMetrics.settleInterval
            onTriggered: {
                const range = list.visibleRange();
                column.model.requestThumbnails(range[0], range[1]);
                if (range[1] >= column.model.count - 1)
                    column.model.loadMore();
            }
        }

        LoadingSkeleton {
            anchors.fill: list
            visible: column.model.loading && column.model.count === 0
            rowHeight: list.rowHeight
        }

        StyledText {
            anchors.centerIn: parent
            width: parent.width - Style.spacingL * 2
            visible: !column.model.loading && column.model.count === 0
            text: column.model.error !== "" ? FileFormat.listingError(column.model.errorCode) : I18n.tr("This folder is empty", "empty directory placeholder")
            color: Style.surfaceVariantText
            font.pixelSize: Style.fontSizeMedium
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }

    DankFlickable {
        id: strip

        anchors.fill: parent
        contentWidth: row.width
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        clip: true
        onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
        onWidthChanged: contentX = Math.max(0, contentWidth - width)

        Row {
            id: row

            height: strip.height

            Repeater {
                model: ancestorModel

                DirColumn {
                    required property int index

                    childPath: index + 1 < columns.ancestors.length ? columns.ancestors[index + 1] : columns.activePath
                }
            }

            ColumnFrame {
                id: activeColumn

                readonly property alias list: activeList

                FileListView {
                    id: activeList

                    anchors.fill: parent
                    anchors.rightMargin: Style.dividerWidth
                    selection: columns.body.selection
                    iconSize: columns.body.iconSize
                    renamingPath: columns.body.renamingPath
                    cutSet: columns.body.cutSet
                    columnIds: []
                    chevrons: true
                    singleClickActivates: columns.body.singleClickActivates
                    nameHighlight: columns.body.nameHighlight
                    multiSelect: columns.body.multiSelect
                    dragEnabled: columns.body.dragEnabled
                    dropEnabled: columns.body.dropEnabled
                    model: columns.body.directory.entries
                    onItemClicked: (index, modifiers) => columns.body.click(index, modifiers)
                    onItemActivated: index => columns.body.activate(index)
                    onItemContextMenu: (index, pointX, pointY, modifiers) => columns.body.forwardItemMenu(activeList, index, pointX, pointY, modifiers)
                    onItemDragStarted: index => columns.body.startDrag(index)
                    onItemDropped: (index, drop) => columns.body.itemsDropped(columns.body.entryAt(index).path, drop)
                    onRenameSubmitted: (target, name) => columns.body.finishRename(target, name)
                    onRenameCancelled: columns.body.finishRename("", "")
                    onContentYChanged: columns.viewportChanged()
                    onCountChanged: columns.viewportChanged()

                    FileViewBackground {
                        view: activeList
                        selection: columns.body.selection
                        onCleared: {
                            columns.body.focusRequested();
                            columns.body.selection.clear();
                        }
                        onContextMenuRequested: (pointX, pointY) => {
                            const point = activeList.mapToItem(columns.body, pointX, pointY);
                            columns.body.backgroundMenuRequested(point.x, point.y);
                        }
                        onDropped: drop => columns.body.itemsDropped(columns.body.directory.path, drop)
                    }
                }

                LoadingSkeleton {
                    anchors.fill: activeList
                    visible: columns.body.listing
                    rowHeight: activeList.rowHeight
                }

                StyledText {
                    anchors.centerIn: parent
                    width: parent.width - Style.spacingL * 2
                    visible: columns.body.empty
                    text: I18n.tr("This folder is empty", "empty directory placeholder")
                    color: Style.surfaceVariantText
                    font.pixelSize: Style.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
            }

            Loader {
                active: columns.lookaheadPath !== ""
                visible: active
                sourceComponent: DirColumn {
                    dirPath: columns.lookaheadPath
                }
            }

            Loader {
                active: columns.pickedEntry !== null && !columns.pickedEntry.isDir
                visible: active
                sourceComponent: ColumnFrame {
                    paneWidth: FileBrowserMetrics.previewPaneWidth

                    FilePreviewPane {
                        anchors.fill: parent
                        anchors.rightMargin: Style.dividerWidth
                        entry: columns.pickedEntry
                        backend: columns.body.directory.backend
                        imageSizeLimit: columns.body.directory.thumbnailSizeLimit
                    }
                }
            }

            Loader {
                active: columns.picked.length > 1
                visible: active
                sourceComponent: ColumnFrame {
                    paneWidth: FileBrowserMetrics.previewPaneWidth

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - Style.spacingL * 2
                        spacing: Style.spacingXS

                        StyledText {
                            width: parent.width
                            text: I18n.tr("%1 selected", "preview column header for a multiple selection").arg(FileFormat.count(columns.picked.length))
                            color: Style.surfaceText
                            font.pixelSize: Style.fontSizeLarge
                            font.weight: Style.fontWeightMedium
                            horizontalAlignment: Text.AlignHCenter
                        }

                        StyledText {
                            width: parent.width
                            visible: columns.body.selectedBytes() >= 0
                            text: FileFormat.size(columns.body.selectedBytes())
                            color: Style.surfaceVariantText
                            font.pixelSize: Style.fontSizeMedium
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
