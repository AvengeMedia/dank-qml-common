import QtQuick
import QtTest
import Quickshell
import qs.DankCommon.Widgets
import qs.DankCommon.Common

ShellRoot {
    id: root

    property int closeRequests: 0
    property int actionRequests: 0
    property QtObject locale: QtObject {
        property bool isRtl: false

        function tr(text, context) {
            return text;
        }
    }
    property QtObject theme: QtObject {
        property real fontSizeLarge: 16
        property real fontSizeSmall: 12
    }
    property QtObject settings: QtObject {
        property bool reduceMotion: true
    }
    property QtObject controls: QtObject {
        property bool canMinimize: true
        property bool canMaximize: true
        property int moveRequests: 0
        property QtObject targetWindow: QtObject {
            property bool maximized: false
            property bool minimized: false
        }

        function tryStartMove() {
            moveRequests++;
        }

        function tryToggleMaximize() {
            targetWindow.maximized = !targetWindow.maximized;
        }

        function tryMinimize() {
            targetWindow.minimized = true;
        }
    }

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        I18n.backend = locale;
        Style.theme = theme;
        Style.settings = settings;
    }

    TestCase {
        id: input
        when: false
        name: "window-header"
    }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 800
        implicitHeight: 300

        DankWindowHeader {
            id: header
            x: 20
            y: 20
            width: 600
            title: "A long window title that must leave room for every window action"
            iconName: "settings"
            controls: root.controls
            onCloseRequested: root.closeRequests++

            DankActionButton {
                id: action
                iconName: "refresh"
                onClicked: root.actionRequests++
            }
        }

        DankWindowHeader {
            id: plainHeader
            x: 20
            y: 150
            width: header.width
            title: header.title
            iconName: header.iconName
            controls: header.controls
        }
    }

    function equal(actual, expected, label) {
        if (actual === expected)
            return;
        throw new Error(label + ": " + actual + " != " + expected);
    }

    function descendants(item) {
        let result = [];
        for (const child of item.children) {
            result.push(child);
            result = result.concat(descendants(child));
        }
        return result;
    }

    function buttons(item) {
        return descendants(item).filter(child => child.visible && child.buttonSize !== undefined && child.iconName !== undefined).sort((a, b) => a.mapToItem(item, 0, 0).x - b.mapToItem(item, 0, 0).x);
    }

    function checkGeometry(item, count) {
        const visibleButtons = buttons(item);
        equal(visibleButtons.length, count, "visible button count");
        const title = descendants(item).find(child => child.text === item.title && child.font !== undefined);
        equal(title.width >= 0, true, "nonnegative title width");
        const titleX = title.mapToItem(item, 0, 0).x;
        const first = visibleButtons[0];
        const last = visibleButtons[visibleButtons.length - 1];
        const firstX = first.mapToItem(item, 0, 0).x;
        const lastRight = last.mapToItem(item, last.width, 0).x;
        equal(locale.isRtl ? titleX >= lastRight : titleX + title.width <= firstX, true, "title does not overlap buttons");
    }

    function click(iconName) {
        const button = buttons(header).find(child => child.iconName === iconName);
        input.mouseClick(button, button.width / 2, button.height / 2);
    }

    function run() {
        try {
            if (!input.waitForRendering(header, 2000))
                throw new Error("window did not render before input");
            input.waitForPolish(header.Window.window);
            for (const rtl of [false, true]) {
                locale.isRtl = rtl;
                for (const scale of [1, 1.5]) {
                    theme.fontSizeLarge = 16 * scale;
                    theme.fontSizeSmall = 12 * scale;
                    for (const width of [600, 360]) {
                        header.width = width;
                        for (const minimize of [false, true]) {
                            controls.canMinimize = minimize;
                            for (const maximize of [false, true]) {
                                controls.canMaximize = maximize;
                                for (const showAction of [false, true]) {
                                    action.visible = showAction;
                                    input.waitForPolish(header.Window.window);
                                    checkGeometry(header, 1 + Number(minimize) + Number(maximize) + Number(showAction));
                                    checkGeometry(plainHeader, 1 + Number(minimize) + Number(maximize));
                                    equal(header.height, plainHeader.height, "shared header height");
                                    if (showAction)
                                        continue;
                                    const withHiddenAction = buttons(header);
                                    const withoutActions = buttons(plainHeader);
                                    equal(withHiddenAction[0].mapToItem(header, 0, 0).x, withoutActions[0].mapToItem(plainHeader, 0, 0).x, "hidden action leaves no gap");
                                }
                            }
                        }
                    }
                }
                click("minimize");
                equal(controls.targetWindow.minimized, true, "minimize action");
                controls.targetWindow.minimized = false;
                click("fullscreen");
                equal(controls.targetWindow.maximized, true, "maximize action");
                input.waitForPolish(header.Window.window);
                click("fullscreen_exit");
                equal(controls.targetWindow.maximized, false, "restore action");
                const closed = closeRequests;
                header.closeEnabled = false;
                click("close");
                equal(closeRequests, closed, "disabled close action");
                header.closeEnabled = true;
                click("close");
                equal(closeRequests, closed + 1, "close action");
                const refreshed = actionRequests;
                click("refresh");
                equal(actionRequests, refreshed + 1, "extra action");
                equal(controls.moveRequests, 0, "buttons do not drag window");
                header.controls = null;
                input.waitForPolish(header.Window.window);
                checkGeometry(header, 2);
                checkGeometry(plainHeader, 1);
                header.controls = controls;
                header.subtitle = "Additional window information";
                input.waitForPolish(header.Window.window);
                input.tryVerify(() => header.height > plainHeader.height, 1000, "subtitle height");
                header.subtitle = "";
            }
            console.log("PASS window header spacing, scaling, RTL, hidden actions and window controls");
            Qt.quit();
        } catch (error) {
            console.error(error, error.stack);
            Qt.exit(1);
        }
    }

    Timer {
        interval: 0
        running: true
        onTriggered: root.run()
    }
}
