pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

FileItemSurface {
    id: tile

    required property string name
    required property bool isSymlink
    required property bool symlinkBroken
    required property real size
    required property string iconName
    required property string thumbnail
    required property string mime
    required property string displayName
    required property bool untrusted
    required property bool unreadable
    required property bool hidden

    width: view?.cellWidth ?? 0
    height: view?.cellHeight ?? 0
    contentRadius: FileBrowserMetrics.gridTileRadius
    selected: view?.selection?.contains(path) ?? false
    cursor: view?.selection?.showsCursor(path) ?? false
    cut: view?.cutSet?.[path] === true
    renaming: (view?.renamingPath ?? "") === path

    Column {
        anchors.top: parent.top
        anchors.topMargin: FileBrowserMetrics.gridTilePadding
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - FileBrowserMetrics.gridTilePadding * 2
        spacing: FileBrowserMetrics.gridNameSpacing

        FileItemVisual {
            anchors.horizontalCenter: parent.horizontalCenter
            iconSize: tile.view?.iconSize ?? FileBrowserMetrics.gridIconSizes[1]
            iconName: tile.iconName
            thumbnail: tile.thumbnail
            path: tile.path
            mime: tile.mime
            isDir: tile.isDir
            isSymlink: tile.isSymlink
            symlinkBroken: tile.symlinkBroken
            untrusted: tile.untrusted
            unreadable: tile.unreadable
            hidden: tile.hidden
            cut: tile.cut
            selected: tile.selected
            tint: tile.contentColor
        }

        StyledText {
            width: parent.width
            visible: !tile.renaming
            opacity: tile.cut ? Style.pendingOpacity : 1
            text: tile.displayName !== "" ? tile.displayName : tile.name
            color: tile.contentColor
            font.pixelSize: Style.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            maximumLineCount: 2
            wrapMode: Text.Wrap
        }

        StyledText {
            width: parent.width
            visible: !tile.renaming && !tile.isDir && tile.size >= 0
            text: FileFormat.size(tile.size)
            color: tile.supportingColor
            font.pixelSize: Style.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Loader {
            width: parent.width
            active: tile.renaming
            sourceComponent: InlineRename {
                width: parent.width
                name: tile.name
                onCommitted: name => tile.view.renameSubmitted(tile.path, name)
                onCancelled: tile.view.renameCancelled()
                Component.onCompleted: begin()
            }
        }
    }
}
