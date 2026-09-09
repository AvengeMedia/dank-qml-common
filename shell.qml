//@ pragma UseQApplication

import QtQuick
import qs.DankCommon.Widgets
import Quickshell
import qs.Common
import qs.Common as App
import qs.Services as AppServices
import qs.DankCommon.Common
import qs.DankCommon.Common as DC
import qs.DankCommon.Modals.FileBrowser
import qs.Services

ShellRoot {
    readonly property var log: Log.scoped("Gallery")

    Component.onCompleted: {
        DC.Style.theme = App.Theme;
        DC.Style.settings = App.SettingsData;
        DC.I18n.backend = App.I18n;
        DC.Paths.backend = App.Paths;
        DC.Log.backend = AppServices.Log;
        DC.Host.session = AppServices.SessionService;
        DC.Host.cache = App.CacheData;
    }

    FloatingWindow {
        id: window

        readonly property var widthPresets: [
            {
                "label": "360",
                "value": 360
            },
            {
                "label": "480",
                "value": 480
            },
            {
                "label": "768",
                "value": 768
            },
            {
                "label": "Wide",
                "value": 1000
            }
        ]

        property int widthPresetIndex: 3

        readonly property int presetWidth: widthPresets[widthPresetIndex].value
        readonly property string layoutClass: width < Style.smallBreakpoint ? "small" : width < Style.mediumBreakpoint ? "medium" : "large"

        title: "DankCommon Gallery"
        implicitWidth: presetWidth
        implicitHeight: 800
        minimumSize: Qt.size(360, 400)
        color: Theme.surface
        visible: true

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledRect {
                id: inspector

                width: parent.width
                height: inspectorContent.implicitHeight + Theme.spacingM * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Flow {
                    id: inspectorContent

                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    DankButton {
                        text: I18n.tr("Text fields")
                        onClicked: galleryFlickable.contentY = widgetExamples.y
                    }

                    Column {
                        width: Theme.fieldDefaultWidth
                        spacing: Theme.spacingXS

                        StyledText {
                            text: I18n.tr("Radius scale")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        DankSlider {
                            width: parent.width
                            Accessible.name: I18n.tr("Radius scale")
                            value: Theme.radiusStrength
                            minimum: 0
                            maximum: 100
                            onSliderValueChanged: value => Theme.radiusStrength = value
                        }
                    }

                    Column {
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Window width"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        DankButtonGroup {
                            model: window.widthPresets.map(p => p.label)
                            currentIndex: window.widthPresetIndex
                            onSelectionChanged: (index, selected) => {
                                if (selected)
                                    window.widthPresetIndex = index;
                            }
                        }
                    }

                    Column {
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Window"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: `${window.width}x${window.height} · ${window.layoutClass}`
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }
                    }
                }
            }

            StyledRect {
                id: frame

                width: parent.width
                height: parent.height - inspector.height - Theme.spacingM
                radius: Theme.cornerRadius
                color: Theme.surface
                border.color: Theme.outline
                border.width: 1
                clip: true

                DankFlickable {
                    id: galleryFlickable
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    contentHeight: gallery.height
                    clip: true

                    Column {
                        id: gallery

                        width: parent.width
                        spacing: Theme.spacingL

                        Section {
                            text: I18n.tr("Buttons")
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankButton {
                                property int clicks: 0

                                text: clicks > 0 ? `Clicked ${clicks}x` : "Filled"
                                iconName: "ads_click"
                                onClicked: clicks++
                            }

                            DankButton {
                                text: "Tonal"
                                backgroundColor: Theme.secondaryContainer
                                textColor: Theme.onSecondaryContainer
                            }

                            DankButton {
                                text: "Large"
                                buttonHeight: 56
                                iconName: "schedule"
                                onClicked: timePicker.open()
                            }

                            DankButton {
                                text: "Square button"
                                buttonHeight: 56
                                shape: "square"
                                iconName: "schedule"
                                onClicked: timePicker.open()
                            }

                            DankActionButton {
                                iconName: "info"
                                buttonSize: Theme.iconButtonSize
                                tooltipText: I18n.tr("Icon button")
                            }

                            DankRefreshButton {
                                property bool spin: false
                                busy: spin
                                onClicked: spin = !spin
                            }
                        }

                        DankButtonGroup {
                            model: ["List", "Grid", "Tree"]
                            currentIndex: 0
                            onSelectionChanged: (index, selected) => {
                                if (selected)
                                    currentIndex = index;
                            }
                        }

                        DankButtonGroup {
                            model: ["Mon", "Tue", "Wed", "Thu", "Fri"]
                            selectionMode: "multi"
                            initialSelection: ["Mon", "Fri"]
                        }

                        Section {
                            text: I18n.tr("Selection")
                        }

                        DankToggle {
                            id: featureToggle

                            text: I18n.tr("Toggle")
                            description: "Spring thumb, M3 switch metrics"
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

                        DankFilterChips {
                            width: Math.min(340, gallery.width)
                            model: ["All", "Active", "Muted"]
                        }

                        DankTabBar {
                            width: Math.min(340, gallery.width)
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
                            onTabClicked: index => currentIndex = index
                        }

                        Section {
                            text: I18n.tr("Sliders")
                        }

                        DankSlider {
                            width: Math.min(340, gallery.width)
                            value: 50
                            step: 25
                            unit: ""
                            onSliderValueChanged: newValue => value = newValue
                        }

                        DankSlider {
                            width: Math.min(340, gallery.width)
                            value: 30
                            enabled: false
                        }

                        DankSlider {
                            width: Math.min(340, gallery.width)
                            value: 65
                            size: "m"
                            onSliderValueChanged: newValue => value = newValue
                        }

                        DankSlider {
                            width: Math.min(340, gallery.width)
                            value: 65
                            size: "m"
                            onSliderValueChanged: newValue => value = newValue
                            insetIcon: "brightness_high"
                            insetIconPosition: "end"
                        }

                        DankSlider {
                            width: Math.min(340, gallery.width)
                            value: 45
                            size: "xl"
                            leftIcon: "brightness_low"
                            rightIcon: "brightness_high"
                            onSliderValueChanged: newValue => value = newValue
                        }

                        Section {
                            text: I18n.tr("Text fields")
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankTextField {
                                width: Math.min(300, gallery.width)
                                leftIconName: "search"
                                placeholderText: "Search settings"
                                cornerRadius: Theme.fullRadius(width, height)
                                showClearButton: true
                            }

                            DankTextField {
                                width: Math.min(300, gallery.width)
                                labelText: "Password"
                                outlined: true
                                leftIconName: "lock"
                                placeholderText: "Reveal with the eye"
                                echoMode: TextInput.Password
                                showPasswordToggle: true
                            }
                        }

                        WidgetGallery {
                            id: widgetExamples
                            width: parent.width
                            flickable: galleryFlickable
                        }

                        DankTextEdit {
                            width: parent.width
                            leftIconName: "edit"
                            placeholderText: "Multi-line notes..."
                        }

                        DankDropdown {
                            width: Math.min(320, gallery.width)
                            text: "Fruit"
                            description: "Fuzzy search enabled"
                            enableFuzzySearch: true
                            options: ["Apple", "Banana", "Cherry", "Dragonfruit", "Elderberry", "Fig", "Grape"]
                            currentValue: "Apple"
                            onValueChanged: value => currentValue = value
                        }

                        DankCollapsibleSection {
                            width: Math.min(340, gallery.width)
                            title: "Details"
                            description: "Grouped header, expands below"
                            showBackground: true

                            StyledText {
                                text: "Collapsible content"
                            }
                        }

                        DankNumberStepper {
                            property int count: 5

                            text: count
                            onIncrement: () => count++
                            onDecrement: () => count--
                        }

                        DankTimePicker {
                            id: timePicker
                            parent: window.contentItem
                            hour: 7
                            minute: 0
                            onAccepted: (h, m) => log.info("time:", h, m)
                        }

                        Section {
                            text: I18n.tr("File browser")
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankButton {
                                text: I18n.tr("Pick a file")
                                iconName: "folder_open"
                                onClicked: fileBrowser.open()
                            }

                            DankButton {
                                text: I18n.tr("Pick a folder")
                                iconName: "folder"
                                onClicked: folderBrowser.open()
                            }
                        }

                        Section {
                            text: "Icons"
                        }

                        Flow {
                            width: parent.width
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
                            }

                            DankColorSwatch {
                                swatchColor: Theme.withAlpha(Theme.secondary, 0.5)
                            }

                            DankSpinner {
                                size: Theme.iconSizeLarge
                            }
                        }

                        Section {
                            text: "List view"
                        }

                        StyledRect {
                            width: Math.min(340, gallery.width)
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
                            width: Math.min(340, gallery.width)
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

                            width: Math.min(340, gallery.width)
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
                                wrapMode: Text.WordWrap
                            }

                            StateLayer {
                                cornerRadius: card.radius
                                onClicked: log.info("card clicked")
                            }
                        }

                        Section {
                            text: I18n.tr("Progress")
                        }

                        DankSlider {
                            width: Math.min(340, gallery.width)
                            value: 40
                            leftIcon: "volume_down"
                            rightIcon: "volume_up"
                            onSliderValueChanged: newValue => log.info("slider:", newValue)
                        }

                        M3WaveProgress {
                            width: Math.min(340, gallery.width)
                            height: 24
                            value: 0.6
                            isPlaying: true
                        }

                        Section {
                            text: "Avatars and logos"
                        }

                        Flow {
                            width: parent.width
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
                            width: Math.min(340, gallery.width)
                            onLocationSelected: (displayName, coordinates) => log.info("location:", displayName, coordinates)
                        }

                        Section {
                            text: "Cursor and blink"
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingL

                            StyledText {
                                id: blinkTarget

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
            }
        }
    }

    component Section: StyledText {
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.primary
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
