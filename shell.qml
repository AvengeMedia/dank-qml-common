//@ pragma UseQApplication

import QtQuick
import Quickshell
import qs.Common
import qs.DankCommon.Common
import qs.DankCommon.Modals.FileBrowser
import qs.DankCommon.Widgets
import qs.Services

ShellRoot {
    readonly property var log: Log.scoped("Gallery")

    FloatingWindow {
        id: window

        title: "DankCommon Gallery"
        implicitWidth: 760
        implicitHeight: 720
        color: Theme.surface
        visible: true

        component Section: StyledText {
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Medium
            color: Theme.primary
        }

        DankFlickable {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            contentHeight: gallery.height
            clip: true

            Column {
                id: gallery

                width: parent.width
                spacing: Theme.spacingL

                Section {
                    text: "Buttons"
                }

                Row {
                    spacing: Theme.spacingM

                    DankButton {
                        id: clickButton

                        property int clicks: 0

                        text: clicks > 0 ? `Clicked ${clicks}x` : "Click me"
                        iconName: "ads_click"
                        onClicked: clicks++
                    }

                    DankButton {
                        text: "Pick a file"
                        iconName: "folder_open"
                        backgroundColor: Theme.surfaceVariant
                        textColor: Theme.surfaceText
                        onClicked: fileBrowser.open()
                    }

                    DankButton {
                        text: "Pick a folder"
                        iconName: "folder"
                        backgroundColor: Theme.surfaceVariant
                        textColor: Theme.surfaceText
                        onClicked: folderBrowser.open()
                    }

                    DankActionButton {
                        id: tooltipButton

                        iconName: "info"
                        onEntered: tooltip.show("Action buttons are circular icon buttons", tooltipButton, 0, 0, "bottom")
                        onExited: tooltip.hide()
                    }
                }

                Section {
                    text: "Button groups"
                }

                DankButtonGroup {
                    id: viewGroup

                    model: ["List", "Grid", "Tree"]
                    currentIndex: 0
                    onSelectionChanged: (index, selected) => {
                        if (selected)
                            currentIndex = index;
                    }
                }

                DankButtonGroup {
                    id: daysGroup

                    model: ["Mon", "Tue", "Wed", "Thu", "Fri"]
                    selectionMode: "multi"
                    initialSelection: ["Mon", "Fri"]
                }

                Section {
                    text: "Toggles"
                }

                DankToggle {
                    id: featureToggle

                    text: "Interactive toggle"
                    description: "Owns its state through onToggled"
                    checked: true
                    onToggled: checked => featureToggle.checked = checked
                }

                DankToggle {
                    id: gatedToggle

                    text: "Gated toggle"
                    description: featureToggle.checked ? "Enabled by the one above" : "Disabled by the one above"
                    enabled: featureToggle.checked
                    onToggled: checked => gatedToggle.checked = checked
                }

                Section {
                    text: "Text fields"
                }

                Row {
                    spacing: Theme.spacingM

                    DankTextField {
                        width: 300
                        labelText: "Name"
                        leftIconName: "badge"
                        placeholderText: "Type, then clear..."
                        showClearButton: true
                    }

                    DankTextField {
                        width: 300
                        labelText: "Password"
                        leftIconName: "lock"
                        placeholderText: "Reveal with the eye"
                        echoMode: TextInput.Password
                        showPasswordToggle: true
                    }
                }

                Section {
                    text: "Dropdown"
                }

                DankDropdown {
                    id: fruitDropdown

                    width: 320
                    text: "Fruit"
                    description: "Fuzzy search enabled"
                    enableFuzzySearch: true
                    options: ["Apple", "Banana", "Cherry", "Dragonfruit", "Elderberry", "Fig", "Grape"]
                    currentValue: "Apple"
                    onValueChanged: value => currentValue = value
                }

                Section {
                    text: "Icons"
                }

                Row {
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "palette"
                        color: Theme.primary
                    }

                    DankIcon {
                        name: "favorite"
                        filled: true
                        color: Theme.error
                    }

                    DankNFIcon {
                        name: "arch"
                        size: Theme.iconSizeLarge
                    }

                    DankNFIcon {
                        name: "file"
                        size: Theme.iconSizeLarge
                    }

                    DankColorSwatch {
                        swatchColor: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DankColorSwatch {
                        swatchColor: Theme.withAlpha(Theme.secondary, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DankSpinner {
                        size: Theme.iconSizeLarge
                    }
                }

                Section {
                    text: "List view"
                }

                StyledRect {
                    width: 340
                    height: 180
                    color: Theme.surfaceContainer
                    radius: Theme.cornerRadius

                    DankListView {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        clip: true
                        model: 20
                        spacing: Theme.spacingXXS

                        delegate: StyledRect {
                            required property int index

                            width: parent ? parent.width : 0
                            height: 36
                            radius: Theme.cornerRadius
                            color: rowLayer.containsMouse ? Theme.surfacePressed : "transparent"

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                text: `Row ${index + 1}`
                            }

                            StateLayer {
                                id: rowLayer

                                cornerRadius: Theme.cornerRadius
                                onClicked: log.info("row clicked:", index + 1)
                            }
                        }
                    }
                }

                Section {
                    text: "Grid view"
                }

                StyledRect {
                    width: 340
                    height: 180
                    color: Theme.surfaceContainer
                    radius: Theme.cornerRadius

                    DankGridView {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        clip: true
                        model: 40
                        cellWidth: 64
                        cellHeight: 64

                        delegate: Item {
                            required property int index

                            width: 64
                            height: 64

                            StyledRect {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingXS
                                radius: Theme.cornerRadius
                                color: Theme.withAlpha(Theme.primary, 0.1 + (index % 8) * 0.1)

                                StyledText {
                                    anchors.centerIn: parent
                                    text: index + 1
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                            }
                        }
                    }
                }

                Section {
                    text: "Surfaces and elevation"
                }

                StyledRect {
                    id: card

                    width: 340
                    height: 100
                    color: Theme.surfaceContainerHigh
                    radius: Theme.cornerRadius

                    ElevationShadow {
                        anchors.fill: parent
                        z: -1
                        targetRadius: card.radius
                        targetColor: card.color
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: "StyledRect + ElevationShadow + StateLayer"
                        width: parent.width - Theme.spacingL * 2
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StateLayer {
                        cornerRadius: card.radius
                        onClicked: log.info("card clicked")
                    }
                }

                Section {
                    text: "Sliders and progress"
                }

                DankSlider {
                    width: 340
                    value: 40
                    leftIcon: "volume_down"
                    rightIcon: "volume_up"
                    onSliderValueChanged: newValue => log.info("slider:", newValue)
                }

                M3WaveProgress {
                    width: 340
                    height: 24
                    value: 0.6
                    isPlaying: true
                }

                Section {
                    text: "Tabs"
                }

                DankTabBar {
                    width: 340
                    model: [
                        {
                            "icon": "home",
                            "text": "Home"
                        },
                        {
                            "icon": "palette",
                            "text": "Theme"
                        },
                        {
                            "icon": "info",
                            "text": "About"
                        }
                    ]
                    onTabClicked: index => log.info("tab:", index)
                }

                Section {
                    text: "Filter chips"
                }

                DankFilterChips {
                    width: 340
                    model: ["All", "Active", "Muted"]
                    onSelectionChanged: index => log.info("chip:", index)
                }

                Section {
                    text: "Collapsible section"
                }

                DankCollapsibleSection {
                    width: 340
                    title: "Details"
                    description: "Expands and collapses"
                    showBackground: true
                    onToggleRequested: expanded = !expanded

                    StyledText {
                        text: "Collapsible content"
                    }
                }

                Section {
                    text: "Number stepper"
                }

                DankNumberStepper {
                    property int count: 5

                    text: count
                    onIncrement: () => count++
                    onDecrement: () => count--
                }

                Section {
                    text: "Avatars and logos"
                }

                Row {
                    spacing: Theme.spacingL

                    DankCircularImage {
                        width: 48
                        height: 48
                        fallbackIcon: "person"
                        fallbackText: "DK"
                    }

                    SystemLogo {
                        width: 48
                        height: 48
                    }
                }

                Section {
                    text: "Numeric text"
                }

                NumericText {
                    text: "1234.56"
                    reserveText: "8888.88"
                    font.pixelSize: Theme.fontSizeXLarge
                }

                Section {
                    text: "Icon picker"
                }

                DankIconPicker {
                    onIconSelected: (iconName, iconType) => log.info("icon:", iconName, iconType)
                }

                Section {
                    text: "Location search"
                }

                DankLocationSearch {
                    width: 340
                    onLocationSelected: (displayName, coordinates) => log.info("location:", displayName, coordinates)
                }

                Section {
                    text: "Cursor and blink"
                }

                Row {
                    spacing: Theme.spacingL

                    StyledText {
                        id: blinkTarget

                        anchors.verticalCenter: parent.verticalCenter
                        text: "DankBlink target"
                    }

                    DankBlink {
                        target: blinkTarget
                    }

                    DankTextCursor {
                        height: 20
                    }
                }

                Item {
                    width: 1
                    height: Theme.spacingL
                }
            }
        }

        DankTooltipV2 {
            id: tooltip
        }
    }

    FileBrowserModal {
        id: fileBrowser

        browserTitle: "Pick a file"
        onFileSelected: path => log.info("file selected:", path)
    }

    FileBrowserModal {
        id: folderBrowser

        browserTitle: "Pick a folder"
        browserIcon: "folder"
        folderMode: true
        onFileSelected: path => log.info("folder selected:", path)
    }
}
