import QtQuick
import qs.Common
import qs.DankCommon.Widgets
import qs.DankCommon.Widgets.Expressive as X

Column {
    id: root

    property var flickable: null
    spacing: Theme.spacingL

    component Section: StyledText {
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.primary
    }

    Section {
        text: I18n.tr("Text fields")
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingL

        X.DankTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Name")
            placeholderText: I18n.tr("Full name")
        }

        X.DankTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Username")
            text: "alice"
            leftIconName: "person"
            showClearButton: true
        }

        X.DankTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Password")
            placeholderText: I18n.tr("Password")
            echoMode: TextInput.Password
            showPasswordToggle: true
        }

        X.DankTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Confirm password")
            text: "password"
            echoMode: TextInput.Password
            showPasswordToggle: true
            isError: true
            supportingText: I18n.tr("Passwords do not match")
        }

        X.DankTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Disabled")
            text: "alice"
            leftIconName: "person"
            enabled: false
        }

        X.DankTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Read only")
            text: "/home/alice"
            readOnly: true
            showClearButton: true
        }

        X.DankTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            placeholderText: I18n.tr("Command")
        }

        X.DankDropdown {
            dropdownWidth: Math.min(Theme.fieldDefaultWidth, root.width)
            options: [I18n.tr("Default"), I18n.tr("Custom")]
            currentValue: options[0]
            onValueChanged: value => currentValue = value
        }
    }

    Section {
        text: I18n.tr("Keyboard")
    }

    Row {
        spacing: Theme.spacingS
        Repeater {
            model: ["Ctrl", "Shift", "K"]
            DankKeycap {
                required property string modelData
                text: modelData
            }
        }
    }

    Section {
        text: I18n.tr("Icons")
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingM

        Repeater {
            model: ["standard", "filled", "tonal", "outlined"]
            X.DankIconButton {
                required property string modelData
                variant: modelData
                iconName: "favorite"
                checkable: true
                Accessible.name: I18n.tr("Favorite")
            }
        }

        X.DankIconButton {
            size: "m"
            widthMode: "wide"
            variant: "tonal"
            iconName: "play_arrow"
            Accessible.name: I18n.tr("Play")
        }

        X.StyledButton {
            id: tooltipButton
            width: Theme.buttonHeightM
            height: Theme.buttonHeightS
            color: Theme.secondaryContainer
            radius: Theme.fullRadius(width, height)
            Accessible.name: I18n.tr("Help")
            onHoveredChanged: {
                if (hovered) {
                    tooltip.show(I18n.tr("Help"), tooltipButton, 0, 0, "top");
                    return;
                }
                tooltip.hide();
            }
            onVisibleChanged: {
                if (!visible)
                    tooltip.hide();
            }
            DankIcon {
                anchors.centerIn: parent
                name: "help"
                size: Theme.iconSize
                color: Theme.onSecondaryContainer
            }
        }
    }

    X.DankTooltipV2 {
        id: tooltip
    }

    Section {
        text: I18n.tr("Appearance")
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingM

        Repeater {
            model: ["primary", "secondary", "tertiary"]
            X.DankCard {
                id: previewCard
                required property string modelData
                width: Math.min(Theme.fieldDefaultWidth, root.width)
                height: Theme.listItemTwoLineHeight
                tone: modelData
                clickable: true
                StyledText {
                    anchors.centerIn: parent
                    text: I18n.tr("Preview")
                    color: previewCard.contentColor
                }
            }
        }

        Repeater {
            model: ["cookie4", "cookie9", "heart", "clover4"]
            X.DankMaterialShape {
                required property string modelData
                width: Theme.buttonHeightM
                height: width
                shape: modelData
            }
        }
    }

    Section {
        text: I18n.tr("Widgets")
    }

    X.DankReorderGroup {
        id: reorderGroup
        coordinateItem: reorderArea
        onTransferred: (source, sourceIndex, target, targetIndex) => {
            const from = source.entries.slice();
            const to = target.entries.slice();
            to.splice(targetIndex, 0, from.splice(sourceIndex, 1)[0]);
            source.entries = from;
            target.entries = to;
        }
    }

    Column {
        id: reorderArea
        width: parent.width
        spacing: Theme.spacingL

        Repeater {
            model: 2
            X.DankReorderList {
                id: reorderList
                required property int index
                property var entries: index === 0 ? [I18n.tr("Clock"), I18n.tr("Weather")] : [I18n.tr("CPU"), I18n.tr("Memory")]
                width: parent.width
                model: entries
                group: reorderGroup
                groupKey: index.toString()
                flickable: root.flickable
                onReordered: indices => {
                    entries = indices.map(i => entries[i]);
                }

                delegate: X.DankListItem {
                    id: entry
                    required property int index
                    required property string modelData
                    firstInGroup: reorderList.order.indexOf(index) === 0
                    lastInGroup: reorderList.order.indexOf(index) === reorderList.count - 1
                    z: handle.dragging ? 1 : 0
                    Accessible.name: modelData

                    function focusHandle(reason) {
                        handle.forceActiveFocus(reason);
                    }

                    X.DankDragHandle {
                        id: handle
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        coordinateItem: reorderList
                        label: entry.modelData
                        dragging: reorderList.draggingIndex === entry.index
                        canMoveUp: reorderList.order.indexOf(entry.index) > 0
                        canMoveDown: reorderList.order.indexOf(entry.index) < reorderList.count - 1
                        onStarted: position => reorderList.begin(entry.index, position)
                        onMoved: position => reorderList.dragTo(position)
                        onFinished: reorderList.finish()
                        onDragCanceled: reorderList.cancel()
                        onMoveRequested: delta => reorderList.move(entry.index, delta)
                    }

                    StyledText {
                        anchors.left: handle.right
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData
                        color: entry.contentColor
                    }
                }
            }
        }
    }

    Section {
        text: I18n.tr("Date & time")
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingL

        X.DankMonthGrid {
            width: Math.min(Theme.clockFaceSize, root.width)
            height: width
            onDayClicked: date => selectedDate = date
        }

        X.DankClockFace {
            width: Math.min(Theme.clockFaceSize, root.width)
            height: width
            hours: "10"
            minutes: "08"
            dateText: Qt.formatDate(new Date(), Qt.DefaultLocaleShortDate)
        }
    }

    Section {
        text: I18n.tr("System monitor")
    }

    X.DankSparkline {
        width: parent.width
        height: Theme.listItemTwoLineHeight
        maximum: 100
        values: [18, 24, 22, 46, 38, 64, 52, 48, 32, 36]
        secondaryValues: [42, 40, 46, 48, 48, 54, 50, 46, 42, 40]
    }

    Section {
        text: I18n.tr("Location")
    }

    X.DankLocationSearch {
        width: parent.width
        currentLocation: "New York"
    }
}
