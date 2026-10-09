pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common

Item {
    id: background

    required property Item view
    required property SelectionModel selection

    readonly property real scrollMargin: Math.min(Style.spacingXL, view.height / 2)
    readonly property real scrollDirection: {
        if (!area.banding || !band.past)
            return 0;
        if (area.pointerPosition.y < scrollMargin)
            return -1;
        return area.pointerPosition.y > view.height - scrollMargin ? 1 : 0;
    }

    signal cleared
    signal contextMenuRequested(real pointX, real pointY)
    signal dropped(var drop)

    parent: view.contentItem
    z: -1
    y: view.originY
    width: view.width
    height: Math.max(view.contentHeight, view.height)

    MouseArea {
        id: area

        property var kept: []
        property bool banding: false
        property point pointerPosition: Qt.point(0, 0)

        parent: background.view.contentItem
        x: background.x
        y: background.y
        width: background.width
        height: background.height
        z: 2
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true

        onPressed: mouse => {
            const contentY = mouse.y + background.y;
            const index = background.view.indexAt(mouse.x, contentY);
            const item = background.view.itemAtIndex(index);
            const point = item ? mapToItem(item, mouse.x, mouse.y) : null;
            if (contentY < background.view.contentOrigin || (item && item.containsContent(point.x, point.y))) {
                mouse.accepted = false;
                return;
            }
            if (mouse.button === Qt.RightButton)
                return;
            if (!background.view.multiSelect) {
                background.cleared();
                return;
            }
            kept = (mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) !== 0 ? background.selection.paths.slice() : [];
            background.selection.keyboardCursor = false;
            if (kept.length === 0)
                background.cleared();
            background.view.stopMomentum();
            pointerPosition = mapToItem(background.view, mouse.x, mouse.y);
            band.originX = mouse.x;
            band.originY = mouse.y;
            band.pointX = mouse.x;
            band.pointY = mouse.y;
            banding = true;
        }

        onPositionChanged: mouse => {
            if (!banding)
                return;
            pointerPosition = mapToItem(background.view, mouse.x, mouse.y);
            background.updateSelection();
        }

        onReleased: banding = false
        onCanceled: banding = false

        onClicked: mouse => {
            if (mouse.button !== Qt.RightButton)
                return;
            const point = mapToItem(background.view, mouse.x, mouse.y);
            background.contextMenuRequested(point.x, point.y);
        }
    }

    function updateSelection() {
        const point = mapFromItem(view, area.pointerPosition.x, area.pointerPosition.y);
        band.pointX = point.x;
        band.pointY = point.y;
        if (!band.past)
            return;
        const rect = Qt.rect(band.x, band.y, band.width, band.height);
        const paths = view.indicesIn(rect).map(index => view.model.get(index).path);
        selection.paths = area.kept.concat(paths.filter(path => !area.kept.includes(path)));
    }

    RubberBand {
        id: band

        parent: background.view.contentItem
        y: background.y + Math.min(originY, pointY)
        z: 3
        visible: area.banding && past
    }

    FrameAnimation {
        running: area.banding && band.past && background.scrollDirection !== 0

        onTriggered: {
            const view = background.view;
            const maximum = view.originY + Math.max(0, view.contentHeight - view.height);
            const next = Math.max(view.originY, Math.min(maximum, view.contentY + background.scrollDirection * FileBrowserMetrics.listRowHeight * 12 * frameTime));
            if (next === view.contentY)
                return;
            view.contentY = next;
            background.updateSelection();
        }
    }

    DropArea {
        anchors.fill: parent
        enabled: background.view.dropEnabled === true
        onDropped: drop => background.dropped(drop)
    }
}
