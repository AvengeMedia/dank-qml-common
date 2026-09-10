import QtQuick
import QtTest
import Quickshell
import qs.DankCommon.Common
import qs.DankCommon.Widgets

ShellRoot {
    id: root

    property int actions: 0
    property int menus: 0
    property QtObject theme: QtObject {
        property int radiusStrength: 50
    }
    property QtObject settings: QtObject {
        property bool reduceMotion: true
    }
    property QtObject locale: QtObject {
        property bool isRtl: false
        function tr(text, context) {
            return text;
        }
    }

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        Style.theme = theme;
        Style.settings = settings;
        I18n.backend = locale;
    }

    TestCase {
        id: input
        when: false
        name: "split-button"
    }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 800
        implicitHeight: 400

        DankSplitButton {
            id: button
            x: 20
            y: 20
            text: "Sort"
            iconName: "sort"
            menuTooltipText: "Sort by"
            maximumWidth: window.width - 40
            onClicked: root.actions++
            onMenuClicked: root.menus++
        }
    }

    function equal(actual, expected, label) {
        if (actual === expected || typeof actual === "number" && Math.abs(actual - expected) < 0.001)
            return;
        throw new Error(label + ": " + actual + " != " + expected);
    }

    function click(control) {
        input.mouseClick(control, control.width / 2, control.height / 2);
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            try {
                const sizes = [
                    {
                        name: "xs",
                        height: 32,
                        menuWidth: 48,
                        inner: 4,
                        pressed: 8
                    },
                    {
                        name: "s",
                        height: 40,
                        menuWidth: 48,
                        inner: 4,
                        pressed: 12
                    },
                    {
                        name: "m",
                        height: 56,
                        menuWidth: 56,
                        inner: 4,
                        pressed: 12
                    },
                    {
                        name: "l",
                        height: 96,
                        menuWidth: 96,
                        inner: 8,
                        pressed: 20
                    },
                    {
                        name: "xl",
                        height: 136,
                        menuWidth: 136,
                        inner: 12,
                        pressed: 20
                    }
                ];
                for (const spec of sizes) {
                    button.size = spec.name;
                    input.wait(20);
                    equal(button.visualHeight, spec.height, "container height " + spec.name);
                    equal(button.height, Math.max(48, spec.height), "touch height " + spec.name);
                    equal(button.trailingButton.width, spec.menuWidth, "menu width " + spec.name);
                    equal(button.trailingButton.x - button.leadingButton.width, 2, "gap " + spec.name);
                    for (const segment of [button.leadingButton, button.trailingButton]) {
                        equal(segment.innerRadius, spec.inner, "rest corners " + spec.name);
                        equal(segment.outerRadius, spec.height / 2, "outer corners " + spec.name);
                        input.mouseMove(segment, segment.width / 2, segment.height / 2);
                        input.wait(20);
                        equal(segment.innerRadius, spec.inner, "hover retains corners " + spec.name);
                        const width = button.width;
                        const height = button.height;
                        input.mousePress(segment, segment.width / 2, segment.height / 2);
                        input.wait(20);
                        equal(segment.innerRadius, spec.pressed, "pressed corners " + spec.name);
                        equal(button.width, width, "press preserves width");
                        equal(button.height, height, "press preserves height");
                        input.mouseRelease(segment, segment.width / 2, segment.height / 2);
                        equal(segment.innerRadius, spec.inner, "released corners " + spec.name);
                    }
                    button.expanded = true;
                    input.wait(20);
                    equal(button.trailingButton.innerRadius, spec.height / 2, "expanded corners " + spec.name);
                    equal(button.trailingButton.Accessible.checked, true, "expanded accessibility");
                    button.expanded = false;
                }
                button.size = "xs";
                button.text = "Sort by: Author";
                input.wait(20);
                equal(button.visualHeight, 32, "natural label width does not wrap");
                button.size = "s";
                for (const strength of [0, 25, 50, 100]) {
                    root.theme.radiusStrength = strength;
                    input.wait(20);
                    equal(button.trailingButton.innerRadius, strength === 100 ? 11 : 4 * strength / 50, "inner strength " + strength);
                    equal(button.trailingButton.outerRadius, 20 * Math.min(1, strength / 50), "outer strength " + strength);
                }
                root.theme.radiusStrength = 50;
                root.locale.isRtl = true;
                input.wait(20);
                equal(button.trailingButton.x, 0, "RTL menu position");
                equal(button.leadingButton.x, button.trailingButton.width + 2, "RTL action position");
                equal(button.leadingButton.topLeftRadius, 4, "RTL inner corner");
                equal(button.leadingButton.topRightRadius, 20, "RTL outer corner");
                root.locale.isRtl = false;
                input.wait(20);
                const actions = root.actions;
                const menus = root.menus;
                click(button.leadingButton);
                equal(root.actions, actions + 1, "main action");
                click(button.trailingButton);
                equal(root.menus, menus + 1, "menu action");
                button.menuOnly = true;
                click(button.leadingButton);
                equal(root.actions, actions + 1, "menu-only skips main action");
                equal(root.menus, menus + 2, "menu-only main action opens menu");
                button.trailingButton.forceActiveFocus(Qt.TabFocusReason);
                input.keyClick(Qt.Key_Return);
                equal(root.menus, menus + 3, "keyboard menu action");
                button.enabled = false;
                click(button.leadingButton);
                click(button.trailingButton);
                equal(root.actions, actions + 1, "disabled main action");
                equal(root.menus, menus + 3, "disabled menu action");
                console.log("PASS split button sizes, shapes, hover, scaling, RTL, independent actions and keyboard input");
                Qt.quit();
            } catch (error) {
                console.error(error);
                Qt.exit(1);
            }
        }
    }
}
