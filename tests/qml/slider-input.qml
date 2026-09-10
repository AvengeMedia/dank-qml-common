import QtQuick
import QtTest
import Quickshell
import qs.DankCommon.Widgets
import qs.DankCommon.Common

ShellRoot {
    id: root

    property QtObject locale: QtObject {
        property bool isRtl: false
        function tr(text, context) {
            return text;
        }
    }
    property var values: []
    property var finished: []

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        I18n.backend = locale;
    }

    TestCase {
        id: input
        when: false
        name: "slider"
    }

    FloatingWindow {
        visible: true
        implicitWidth: 600
        implicitHeight: 300

        DankSlider {
            id: slider
            x: 20
            y: 60
            width: 560
            startIcon: "remove"
            endIcon: "add"
            showValue: false
            onSliderValueChanged: value => root.values.push(value)
            onSliderDragFinished: value => root.finished.push(value)
        }
    }

    function equal(actual, expected, label) {
        if (actual === expected)
            return;
        throw new Error(label + ": " + actual + " != " + expected);
    }

    function click(item) {
        input.mouseClick(item, item.width / 2, item.height / 2);
    }

    function run() {
        try {
            const start = slider.contentItem.children[0];
            const end = slider.contentItem.children[2];
            equal(slider.iconsClickable, false, "decorative icons by default");
            click(start);
            click(end);
            equal(slider.value, 50, "decorative icons do not change value");
            equal(values.length, 0, "decorative icons do not emit changes");
            equal(slider.focusTargets.length, 1, "decorative icons are not focus targets");
            slider.leftIcon = "volume_down";
            slider.rightIcon = "volume_up";
            equal(slider.startIcon, "volume_down", "legacy start alias");
            equal(slider.endIcon, "volume_up", "legacy end alias");
            slider.startIcon = "remove";
            slider.endIcon = "add";
            equal(slider.leftIcon, "remove", "start alias follows new property");
            equal(slider.rightIcon, "add", "end alias follows new property");
            slider.iconsClickable = true;
            for (const rtl of [false, true]) {
                locale.isRtl = rtl;
                for (const [minimum, maximum, step, value, decremented] of [[0, 100, 1, 50, 49], [5, 95, 10, 45, 35], [0, 10000, 1, 5000, 4900]]) {
                    slider.minimum = minimum;
                    slider.maximum = maximum;
                    slider.step = step;
                    slider.value = value;
                    input.wait(20);
                    equal(start.x > end.x, rtl, "logical icon positions");
                    equal(slider.focusTargets[0], start.item, "start icon keyboard order");
                    equal(slider.focusTargets[2], end.item, "end icon keyboard order");
                    values = [];
                    finished = [];
                    click(start);
                    equal(slider.value, decremented, "start icon decreases");
                    click(end);
                    equal(slider.value, value, "end icon increases");
                    equal(values.join(","), [decremented, value].join(","), "value change signals");
                    equal(finished.join(","), values.join(","), "finished signals");
                    end.item.forceActiveFocus(Qt.TabFocusReason);
                    input.keyClick(Qt.Key_Space);
                    equal(slider.value, value + value - decremented, "keyboard icon activation");
                    slider.value = minimum;
                    equal(start.item.enabled, false, "decrease disabled at minimum");
                    click(start);
                    equal(slider.value, minimum, "minimum bound");
                    slider.value = maximum;
                    equal(end.item.enabled, false, "increase disabled at maximum");
                    click(end);
                    equal(slider.value, maximum, "maximum bound");
                    slider.value = value;
                    slider.enabled = false;
                    click(start);
                    click(end);
                    equal(slider.value, value, "disabled slider ignores icons");
                    slider.enabled = true;
                }
            }
            slider.startIcon = "";
            input.wait(20);
            equal(start.item, null, "missing icon has no control");
            equal(slider.focusTargets.length, 2, "missing icon is not a focus target");
            slider.iconsClickable = false;
            input.wait(20);
            equal(slider.focusTargets.length, 1, "disabling icon actions restores focus targets");
            const track = slider.contentItem.children[1];
            const trackWidth = track.width;
            slider.visible = false;
            equal(track.width, trackWidth, "hidden slider preserves track geometry");
            console.log("PASS slider icon input, RTL, aliases, bounds, steps, signals and keyboard activation");
            Qt.quit();
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    }

    Timer {
        interval: 300
        running: true
        onTriggered: root.run()
    }
}
