import "../../Common/fzf.js" as Fzf
import "../ScrollConstants.js" as Scroll
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.DankCommon.Common
import qs.DankCommon.Widgets as Base

Item {
    id: root

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    function checkParentDisablesTransparency() {
        let p = parent;
        while (p) {
            if (p.disablePopupTransparency === true)
                return true;
            p = p.parent;
        }
        return false;
    }

    property string text: ""
    property string description: ""
    property string currentValue: ""
    property var options: []
    property var optionIcons: []
    property bool enableFuzzySearch: false
    property var optionIconMap: ({})
    property var optionColorMap: ({})

    function rebuildIconMap() {
        const map = {};
        for (let i = 0; i < options.length; i++) {
            if (optionIcons.length > i)
                map[options[i]] = optionIcons[i];
        }
        optionIconMap = map;
    }

    onOptionsChanged: rebuildIconMap()
    onOptionIconsChanged: rebuildIconMap()

    property int popupWidthOffset: 0
    property int maxPopupHeight: Style.menuMaxHeight
    property bool openUpwards: false
    property int popupWidth: 0
    property bool alignPopupRight: false
    property int dropdownWidth: 200
    property bool compactMode: text === "" && description === ""
    property bool showTrigger: true
    property Item popupAnchorItem: null
    property bool addHorizontalPadding: false
    property string emptyText: ""
    property bool usePopupTransparency: !checkParentDisablesTransparency()
    property color backgroundColor: usePopupTransparency ? Style.withAlpha(Style.surfaceContainer, Style.popupTransparency) : Style.surfaceContainer
    property color hoverBackgroundColor: usePopupTransparency ? Style.withAlpha(Style.surfaceContainerHigh, Style.popupTransparency) : Style.surfaceContainerHigh
    property color menuBackgroundColor: usePopupTransparency ? Style.floatingSurface : Style.surfaceContainer
    property color normalBorderColor: Style.outlineVariant
    property color focusedBorderColor: Style.primary
    property var transientSurfaceTracker: null
    property bool menuBlurEnabled: true

    signal valueChanged(string value)

    property bool menuOpen: false
    property bool menuClosing: false
    readonly property bool menuVisible: menuLoader.item?.visible ?? false

    property string searchQuery: ""
    property var fzfFinder: null
    property int selectedIndex: -1
    readonly property var filteredOptions: {
        if (!enableFuzzySearch || searchQuery.length === 0)
            return options;
        if (!fzfFinder)
            return options;
        return fzfFinder.find(searchQuery).map(r => r.item);
    }

    onMenuOpenChanged: {
        if (!menuOpen)
            transientSurfaceTracker?.setActive(root, false, null);
    }

    property int triggerHeight: Style.iconButtonSize
    readonly property int menuItemHeight: Style.menuItemHeight
    readonly property int menuPadding: Style.spacingS
    readonly property int menuSpacing: Style.spacingXXS

    readonly property int menuWidth: {
        if (root.popupWidth > 0)
            return root.popupWidth;
        return Math.max(1, dropdown.width + root.popupWidthOffset);
    }

    readonly property int menuHeight: {
        let h = root.enableFuzzySearch ? root.triggerHeight + Style.spacingXS : 0;
        if (root.options.length === 0 && root.emptyText !== "")
            h += menuItemHeight;
        else
            h += Math.min(root.filteredOptions.length, 10) * (menuItemHeight + menuSpacing);
        return Math.min(root.maxPopupHeight, h + menuPadding * 2);
    }

    function initFinder() {
        fzfFinder = new Fzf.Finder(root.options, {
            "selector": option => option,
            "limit": 50,
            "casing": "case-insensitive",
            "sort": true,
            "tiebreakers": [(a, b, selector) => selector(a.item).length - selector(b.item).length]
        });
    }

    function scrollMenuTo(index, mode) {
        const menu = menuLoader.item;
        if (!menu)
            return;
        menu.scrollTo(index, mode);
    }

    function selectNext() {
        if (filteredOptions.length === 0)
            return;
        selectedIndex = (selectedIndex + 1) % filteredOptions.length;
        scrollMenuTo(selectedIndex, ListView.Contain);
    }

    function selectPrevious() {
        if (filteredOptions.length === 0)
            return;
        selectedIndex = selectedIndex <= 0 ? filteredOptions.length - 1 : selectedIndex - 1;
        scrollMenuTo(selectedIndex, ListView.Contain);
    }

    function selectCurrent() {
        if (selectedIndex < 0 || selectedIndex >= filteredOptions.length)
            return;
        root.currentValue = filteredOptions[selectedIndex];
        root.valueChanged(filteredOptions[selectedIndex]);
        root.closeDropdownMenu();
    }

    function positionMenuInHost() {
        const menu = menuLoader.item;
        const qsWin = root.QsWindow.window;
        const anchorItem = root.popupAnchorItem || dropdown;
        if (!menu || !qsWin || !anchorItem)
            return false;

        menu.anchor.window = qsWin;
        menu.anchor.rect.x = 0;
        menu.anchor.rect.y = 0;
        menu.anchor.edges = Edges.Top | Edges.Left;
        menu.anchor.gravity = Edges.Bottom | Edges.Right;
        menu.anchor.margins.top = 0;
        menu.anchor.margins.bottom = 0;
        menu.anchor.adjustment = PopupAdjustment.None;
        menu.width = qsWin.width;
        menu.height = qsWin.height;

        const pos = root.QsWindow.itemPosition(anchorItem);
        const menuW = root.menuWidth;
        const menuH = root.menuHeight;
        const gap = Style.spacingXS;
        let x = root.alignPopupRight ? pos.x + anchorItem.width - menuW : pos.x;
        let goUp = root.openUpwards;
        if (!goUp && pos.y + anchorItem.height + menuH + gap > qsWin.height)
            goUp = true;
        if (goUp && pos.y - menuH - gap < 0)
            goUp = false;
        let y = goUp ? pos.y - menuH - gap : pos.y + anchorItem.height + gap;
        menu.menuX = Math.max(0, Math.min(qsWin.width - menuW, x));
        menu.menuY = Math.max(0, Math.min(qsWin.height - menuH, y));
        menu.opensUpwards = goUp;
        menu.anchor.updateAnchor();
        return true;
    }

    function closeDropdownMenu() {
        if (!root.menuOpen && !root.menuVisible)
            return;
        root.menuOpen = false;
        root.menuClosing = true;
        closeTimer.restart();
    }

    function showDropdownMenu() {
        if (root.options.length === 0)
            return;
        if (root.menuOpen)
            return;
        if (!root.QsWindow.window)
            return;

        root.menuOpen = true;
        const menu = menuLoader.item;
        if (!menu || !positionMenuInHost()) {
            root.menuOpen = false;
            return;
        }

        closeTimer.stop();
        root.menuClosing = false;
        menu.visible = true;
        const currentIndex = root.options.indexOf(root.currentValue);
        scrollMenuTo(currentIndex >= 0 ? currentIndex : 0, ListView.Beginning);
        root.selectedIndex = root.filteredOptions.indexOf(root.currentValue);
        transientSurfaceTracker?.setActive(root, true, menu);
    }

    function openDropdownMenu() {
        if (root.menuOpen) {
            closeDropdownMenu();
            return;
        }
        showDropdownMenu();
    }

    function resetSearch() {
        const menu = menuLoader.item;
        if (menu)
            menu.clearSearch();
        root.fzfFinder = null;
        root.searchQuery = "";
        root.selectedIndex = -1;
    }

    width: !showTrigger ? 0 : (compactMode ? dropdownWidth : parent.width)
    implicitHeight: !showTrigger ? 0 : (compactMode ? triggerHeight : Math.max(Style.listItemHeight + Style.spacingXS, labelColumn.implicitHeight + Style.spacingM))
    activeFocusOnTab: showTrigger && enabled
    Accessible.role: Accessible.ComboBox
    Accessible.name: text || currentValue
    Accessible.description: description
    Accessible.onPressAction: {
        if (enabled)
            openDropdownMenu();
    }

    Keys.onPressed: event => {
        if (!root.enabled)
            return;
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Down:
            root.showDropdownMenu();
            event.accepted = true;
            break;
        }
    }

    Component.onDestruction: {
        transientSurfaceTracker?.unregister(root);
        const menu = menuLoader.item;
        if (menu && (root.menuOpen || menu.visible))
            menu.visible = false;
    }

    Connections {
        target: root.transientSurfaceTracker
        ignoreUnknownSignals: true

        function onCloseRequested() {
            root.closeDropdownMenu();
        }
    }

    Timer {
        id: closeTimer

        interval: Style.expressiveDurations.expressiveEffects
        onTriggered: {
            const menu = menuLoader.item;
            if (menu)
                menu.visible = false;
            root.menuClosing = false;
        }
    }

    Column {
        id: labelColumn

        anchors.left: parent.left
        anchors.right: dropdown.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.addHorizontalPadding ? Style.spacingM : 0
        anchors.rightMargin: Style.spacingL
        spacing: Style.spacingXS
        visible: !root.compactMode && root.showTrigger

        Base.StyledText {
            text: root.text
            font.pixelSize: Style.fontSizeMedium
            color: Style.surfaceText
            font.weight: Font.Medium
            width: parent.width
            horizontalAlignment: Text.AlignLeft
        }

        Base.StyledText {
            text: root.description
            font.pixelSize: Style.fontSizeSmall
            color: Style.onSurfaceVariant
            visible: description.length > 0
            wrapMode: Text.WordWrap
            width: parent.width
            horizontalAlignment: Text.AlignLeft
        }
    }

    Rectangle {
        id: dropdown

        readonly property bool active: root.menuVisible || root.activeFocus

        visible: root.showTrigger
        width: root.compactMode ? parent.width : (root.popupWidth === -1 ? undefined : (root.popupWidth > 0 ? root.popupWidth : root.dropdownWidth))
        height: root.triggerHeight
        anchors.right: parent.right
        anchors.rightMargin: root.addHorizontalPadding && !root.compactMode ? Style.spacingM : 0
        anchors.verticalCenter: parent.verticalCenter
        radius: Style.cornerRadiusM
        color: !root.enabled ? Style.onSurface_12 : (dropdownArea.containsMouse || root.menuVisible ? root.hoverBackgroundColor : root.backgroundColor)
        border.color: !root.enabled ? "transparent" : (active || dropdownArea.containsMouse ? root.focusedBorderColor : root.normalBorderColor)
        border.width: active ? Style.outlineWidthFocused : Style.outlineWidth

        Behavior on color {
            enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
            DankColorAnim {
                duration: Style.expressiveDurations.expressiveEffects
                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
            }
        }

        Behavior on border.color {
            enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
            DankColorAnim {
                duration: Style.expressiveDurations.expressiveEffects
                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
            }
        }

        MouseArea {
            id: dropdownArea

            anchors.fill: parent
            enabled: root.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openDropdownMenu()
        }

        Row {
            id: contentRow

            anchors.left: parent.left
            anchors.right: expandIcon.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.spacingL
            anchors.rightMargin: Style.spacingS
            spacing: Style.spacingS

            Base.DankColorSwatch {
                id: triggerSwatch

                width: Style.iconSizeSmall
                height: Style.iconSizeSmall
                anchors.verticalCenter: parent.verticalCenter
                visible: root.optionColorMap[root.currentValue] !== undefined
                swatchColor: visible ? root.optionColorMap[root.currentValue] : "transparent"
            }

            Base.DankIcon {
                id: triggerIcon

                name: root.optionIconMap[root.currentValue] ?? ""
                size: Style.iconSizeMedium
                color: root.enabled ? Style.surfaceText : Style.onSurface_38
                anchors.verticalCenter: parent.verticalCenter
                visible: name !== ""
            }

            Base.StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentValue !== "" ? root.currentValue : root.emptyText
                font.pixelSize: Style.fontSizeMedium
                color: !root.enabled ? Style.onSurface_38 : (root.currentValue !== "" ? Style.surfaceText : Style.onSurfaceVariant)
                width: contentRow.width - (triggerSwatch.visible ? triggerSwatch.width + contentRow.spacing : 0) - (triggerIcon.visible ? triggerIcon.width + contentRow.spacing : 0)
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignLeft
            }
        }

        Base.DankIcon {
            id: expandIcon

            name: "arrow_drop_down"
            size: Style.iconSize
            color: root.enabled ? Style.onSurfaceVariant : Style.onSurface_38
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Style.spacingS
            rotation: root.menuVisible ? 180 : 0

            Behavior on rotation {
                enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DankAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.expressiveDefaultSpatial
                }
            }
        }
    }

    Loader {
        id: menuLoader

        active: root.menuOpen || root.menuClosing

        sourceComponent: PopupWindow {
            id: dropdownMenu

            grabFocus: true

            property real menuX: 0
            property real menuY: 0
            property bool opensUpwards: false

            function scrollTo(index, mode) {
                listView.positionViewAtIndex(index, mode);
            }

            function focusInput() {
                const field = searchLoader.item;
                if (root.enableFuzzySearch && field) {
                    field.forceActiveFocus();
                    return;
                }
                menuKeyHandler.forceActiveFocus();
            }

            function clearSearch() {
                const field = searchLoader.item;
                if (!field)
                    return;
                field.text = "";
            }

            color: "transparent"
            visible: false

            onVisibleChanged: {
                if (!visible && root.menuOpen)
                    root.closeDropdownMenu();
                if (!visible && root.activeFocusOnTab)
                    root.forceActiveFocus();
                if (visible)
                    Qt.callLater(focusInput);
            }

            BackgroundEffect.blurRegion: (visible && !root.menuClosing && root.menuBlurEnabled && Style.blurLayersActive) ? menuBlurRegion : null

            Region {
                id: menuBlurRegion
                x: menuContainer.x
                y: menuContainer.y
                width: menuContainer.width
                height: menuContainer.height
                radius: Style.cornerRadiusM
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                enabled: dropdownMenu.visible
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: root.closeDropdownMenu()
            }

            FocusScope {
                id: menuKeyHandler
                anchors.fill: parent
                focus: dropdownMenu.visible
                z: 0

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        root.closeDropdownMenu();
                        event.accepted = true;
                        return;
                    case Qt.Key_Down:
                        root.selectNext();
                        event.accepted = true;
                        return;
                    case Qt.Key_Up:
                        root.selectPrevious();
                        event.accepted = true;
                        return;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.selectCurrent();
                        event.accepted = true;
                        return;
                    }
                }
            }

            Item {
                id: menuContainer
                x: dropdownMenu.menuX
                y: dropdownMenu.menuY
                width: root.menuWidth
                height: root.menuHeight
                z: 1

                Rectangle {
                    id: contentSurface

                    readonly property bool shown: dropdownMenu.visible && !root.menuClosing

                    anchors.fill: parent
                    LayoutMirroring.enabled: I18n.isRtl
                    LayoutMirroring.childrenInherit: true
                    color: "transparent"
                    border.color: "transparent"
                    border.width: 0
                    radius: Style.cornerRadiusM
                    opacity: shown ? 1 : 0
                    scale: shown ? 1 : Style.popupEnterScale
                    transformOrigin: dropdownMenu.opensUpwards ? Item.Bottom : Item.Top

                    Behavior on opacity {
                        enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                        DankAnim {
                            duration: Style.expressiveDurations.expressiveEffects
                            easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                        }
                    }
                    Behavior on scale {
                        enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                        DankAnim {
                            duration: Style.expressiveDurations.expressiveFastSpatial
                            easing.bezierCurve: Style.expressiveCurves.expressiveDefaultSpatial
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        acceptedButtons: Qt.AllButtons
                        onPressed: mouse => mouse.accepted = true
                        onClicked: mouse => mouse.accepted = true
                    }

                    ElevationShadow {
                        id: shadowLayer
                        anchors.fill: parent
                        z: -1
                        level: Style.elevationLevel2
                        fallbackOffset: Style.spacingXS
                        targetRadius: contentSurface.radius
                        targetColor: root.menuBackgroundColor
                        borderColor: root.normalBorderColor
                        borderWidth: Style.outlineWidth
                        shadowEnabled: Style.elevationEnabled && Style.popoutElevationEnabled
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: root.menuPadding

                        Rectangle {
                            id: searchContainer

                            width: parent.width
                            height: root.triggerHeight
                            visible: root.enableFuzzySearch
                            radius: Style.cornerRadiusM
                            color: "transparent"

                            Loader {
                                id: searchLoader

                                anchors.fill: parent
                                active: root.enableFuzzySearch

                                sourceComponent: DankTextField {
                                    id: searchField

                                    placeholderText: I18n.tr("Search...")
                                    backgroundColor: root.backgroundColor
                                    normalBorderColor: root.normalBorderColor
                                    focusedBorderColor: root.focusedBorderColor
                                    topPadding: Style.spacingS
                                    bottomPadding: Style.spacingS
                                    Component.onCompleted: text = root.searchQuery
                                    onTextChanged: searchDebounce.restart()
                                    Keys.onDownPressed: root.selectNext()
                                    Keys.onUpPressed: root.selectPrevious()
                                    Keys.onReturnPressed: root.selectCurrent()
                                    Keys.onEnterPressed: root.selectCurrent()
                                    Keys.onEscapePressed: event => {
                                        root.closeDropdownMenu();
                                        event.accepted = true;
                                    }
                                    Keys.onPressed: event => {
                                        if (!(event.modifiers & Qt.ControlModifier))
                                            return;
                                        switch (event.key) {
                                        case Qt.Key_N:
                                        case Qt.Key_J:
                                            root.selectNext();
                                            event.accepted = true;
                                            break;
                                        case Qt.Key_P:
                                        case Qt.Key_K:
                                            root.selectPrevious();
                                            event.accepted = true;
                                            break;
                                        }
                                    }

                                    Timer {
                                        id: searchDebounce
                                        interval: 50
                                        onTriggered: {
                                            if (searchField.text === root.searchQuery)
                                                return;
                                            if (!root.fzfFinder)
                                                root.initFinder();
                                            root.searchQuery = searchField.text;
                                            root.selectedIndex = -1;
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: Style.spacingXS
                            visible: root.enableFuzzySearch
                        }

                        Item {
                            width: parent.width
                            height: root.menuItemHeight
                            visible: root.options.length === 0 && root.emptyText !== ""

                            Base.StyledText {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Style.spacingM
                                anchors.rightMargin: Style.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.emptyText
                                font.pixelSize: Style.fontSizeMedium
                                color: Style.onSurfaceVariant
                                horizontalAlignment: Text.AlignLeft
                            }
                        }

                        Base.DankListView {
                            id: listView

                            width: parent.width
                            height: parent.height - (root.enableFuzzySearch ? searchContainer.height + Style.spacingXS : 0) - (root.options.length === 0 && root.emptyText !== "" ? root.menuItemHeight : 0)
                            clip: true
                            visible: root.options.length > 0
                            model: ScriptModel {
                                values: root.filteredOptions
                            }
                            spacing: root.menuSpacing

                            interactive: true
                            flickDeceleration: Scroll.flickDeceleration
                            maximumFlickVelocity: Scroll.maximumFlickVelocity
                            boundsBehavior: Flickable.DragAndOvershootBounds
                            boundsMovement: Flickable.FollowBoundsBehavior
                            pressDelay: 0
                            flickableDirection: Flickable.VerticalFlick

                            delegate: Rectangle {
                                id: delegateRoot

                                required property var modelData
                                required property int index
                                property bool isSelected: root.selectedIndex === index
                                property bool isCurrentValue: root.currentValue === modelData
                                property string iconName: root.optionIconMap[modelData] ?? ""
                                property var swatchColor: root.optionColorMap[modelData]
                                readonly property color contentColor: isCurrentValue ? Style.onPrimaryContainer : Style.surfaceText

                                width: ListView.view.width
                                height: root.menuItemHeight
                                radius: Style.cornerRadiusS
                                color: {
                                    if (isCurrentValue)
                                        return Style.primaryContainer;
                                    if (isSelected)
                                        return Style.withAlpha(Style.onSurface, Style.stateLayerFocus);
                                    if (optionArea.containsMouse)
                                        return Style.withAlpha(Style.onSurface, Style.stateLayerHover);
                                    return Style.withAlpha(Style.onSurface, 0);
                                }

                                Behavior on color {
                                    enabled: Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                                    DankColorAnim {
                                        duration: Style.expressiveDurations.expressiveEffects
                                        easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                                    }
                                }

                                Row {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: Style.spacingM
                                    anchors.rightMargin: Style.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Style.spacingS

                                    Base.DankColorSwatch {
                                        id: optionSwatch

                                        width: Style.iconSizeSmall
                                        height: Style.iconSizeSmall
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: delegateRoot.swatchColor !== undefined
                                        swatchColor: visible ? delegateRoot.swatchColor : Style.withAlpha(delegateRoot.swatchColor, 0)
                                        ringColor: delegateRoot.isCurrentValue ? Style.primary : Style.outline
                                    }

                                    Base.DankIcon {
                                        name: delegateRoot.iconName
                                        size: Style.iconSizeMedium
                                        color: delegateRoot.contentColor
                                        visible: name !== ""
                                    }

                                    Base.StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: delegateRoot.modelData
                                        font.pixelSize: Style.fontSizeMedium
                                        color: delegateRoot.contentColor
                                        font.weight: delegateRoot.isCurrentValue ? Font.Medium : Font.Normal
                                        width: root.popupWidth > 0 ? undefined : (delegateRoot.width - parent.x - Style.spacingM * 2 - (optionSwatch.visible ? optionSwatch.width + parent.spacing : 0))
                                        elide: root.popupWidth > 0 ? Text.ElideNone : Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        horizontalAlignment: Text.AlignLeft
                                    }
                                }

                                MouseArea {
                                    id: optionArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.currentValue = delegateRoot.modelData;
                                        root.valueChanged(delegateRoot.modelData);
                                        root.closeDropdownMenu();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
