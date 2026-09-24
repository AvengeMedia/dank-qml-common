pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

StyledButton {
    id: surface

    required property int index
    required property string path
    required property bool isDir

    property Item view: null
    property bool selected: false
    property bool cursor: false
    property bool cut: false
    property bool renaming: false
    property real contentRadius: Style.groupedListInnerRadius

    readonly property bool dropTarget: isDir && !renaming && dropZone.containsDrag
    readonly property color contentColor: selected ? Style.onSelectedContainer : dropTarget ? Style.onPrimaryContainer : Style.surfaceText
    readonly property color supportingColor: selected ? Style.onSelectedContainer : Style.surfaceVariantText

    default property alias content: holder.data

    focusPolicy: Qt.NoFocus
    radius: contentRadius
    color: selected ? Style.selectedContainer : dropTarget ? Style.primaryContainer : "transparent"
    Accessible.name: path.substring(path.lastIndexOf("/") + 1)
    Accessible.selected: selected

    // Inset, not outset: the views clip, so an outset ring loses its side strokes.
    Rectangle {
        anchors.fill: parent
        anchors.margins: Style.focusRingOffset
        visible: surface.cursor && !surface.renaming
        radius: Math.max(0, parent.radius - Style.focusRingOffset)
        color: "transparent"
        border.width: Style.focusRingWidth
        border.color: Style.focusRingColor
    }

    StateLayer {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        enabled: !surface.renaming
        hovered: surface.hovered
        stateColor: surface.contentColor
        cornerRadius: surface.radius

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                const point = mapToItem(surface.view, mouse.x, mouse.y);
                surface.view.itemContextMenu(surface.index, point.x, point.y, mouse.modifiers);
                return;
            }
            surface.view.itemClicked(surface.index, mouse.modifiers);
        }

        onDoubleClicked: mouse => {
            if (mouse.button !== Qt.LeftButton)
                return;
            surface.view.itemActivated(surface.index);
        }
    }

    DragHandler {
        target: null
        enabled: !surface.renaming && surface.view?.dragEnabled === true
        onActiveChanged: {
            if (!active)
                return;
            surface.view.itemDragStarted(surface.index);
        }
    }

    DropArea {
        id: dropZone

        anchors.fill: parent
        enabled: surface.isDir && !surface.renaming && surface.view?.dropEnabled === true
        onDropped: drop => surface.view.itemDropped(surface.index, drop)
    }

    Item {
        id: holder

        anchors.fill: parent
    }
}
