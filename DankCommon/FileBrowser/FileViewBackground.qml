pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common

Item {
    id: background

    required property Item view
    required property SelectionModel selection

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

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton)
                return;
            if (!background.view.multiSelect) {
                background.cleared();
                return;
            }
            kept = (mouse.modifiers & Qt.ControlModifier) !== 0 ? background.selection.paths.slice() : [];
            background.selection.keyboardCursor = false;
            if (kept.length === 0)
                background.cleared();
            band.originX = mouse.x;
            band.originY = mouse.y;
            band.pointX = mouse.x;
            band.pointY = mouse.y;
            banding = true;
        }

        onPositionChanged: mouse => {
            if (!banding)
                return;
            band.pointX = mouse.x;
            band.pointY = mouse.y;
            if (!band.past)
                return;
            background.selection.paths = kept.concat(background.pathsUnder(Qt.rect(band.x, band.y, band.width, band.height)).filter(path => !kept.includes(path)));
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

    function pathsUnder(rect) {
        const model = view.model;
        return view.indicesIn(Qt.rect(rect.x, rect.y + y, rect.width, rect.height)).map(index => model.get(index).path);
    }

    RubberBand {
        id: band

        visible: area.banding && past
    }

    DropArea {
        anchors.fill: parent
        enabled: background.view.dropEnabled === true
        onDropped: drop => background.dropped(drop)
    }
}
