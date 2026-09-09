import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets.Expressive as E

Item {
    id: root
    width: 640
    height: 200

    property QtObject theme: QtObject {
        property int radiusStrength: 50
        property int currentAnimationSpeed: Style.AnimationSpeed.Short
    }
    property QtObject locale: QtObject {
        property bool isRtl: false
    }
    property QtObject settings: QtObject {
        property bool reduceMotion: false
    }
    property var group: null
    property var segments: []
    property var before: []
    property int scenario: 0
    property int samples: 0
    property bool shapeChanged: false

    Component {
        id: factory
        E.DankButtonGroup {
            model: ["Power save", "Balanced", "Performance"]
            currentIndex: 1
            anchors.horizontalCenter: parent.horizontalCenter
            scale: Math.min(1, 360 / implicitWidth)
        }
    }

    function equal(actual, expected, label) {
        if (Math.abs(actual - expected) < 0.001)
            return;
        throw new Error(label + ": " + actual + " != " + expected);
    }

    function geometry(item) {
        const point = item.mapToItem(root, 0, 0);
        return [point.x, point.y, item.width, item.height, item.scale];
    }

    function content(item) {
        const result = [];
        for (const child of item.children ?? []) {
            if (child.name === "check" || child.text === "Balanced")
                result.push(child);
            result.push(...content(child));
        }
        return result;
    }

    function advance() {
        if (scenario === 8) {
            console.log("PASS 8 button group press and release scenarios");
            Qt.quit();
            return;
        }
        locale.isRtl = (scenario & 1) !== 0;
        settings.reduceMotion = (scenario & 2) !== 0;
        const fill = (scenario & 4) !== 0;
        group = factory.createObject(root, fill ? {
            fillWidth: true,
            width: 600
        } : {});
        Qt.callLater(start);
    }

    function start() {
        try {
            segments = [...group.children].filter(item => item.selected !== undefined);
            equal(segments.length, 3, "segment count");
            const items = [group, ...segments, ...content(segments[1])];
            before = items.map(item => ({
                        item: item,
                        geometry: geometry(item)
                    }));
            samples = 0;
            shapeChanged = false;
            segments[1].animateClick();
            sampler.start();
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    }

    Timer {
        id: sampler
        interval: 16
        repeat: true
        onTriggered: {
            try {
                for (const entry of root.before) {
                    const actual = root.geometry(entry.item);
                    for (let i = 0; i < actual.length; i++)
                        root.equal(actual[i], entry.geometry[i], "stable content geometry " + i);
                }
                const selected = root.segments[1];
                if (selected.topLeftRadius < root.group.outerRadius - 0.01)
                    root.shapeChanged = true;
                if (++root.samples < 36)
                    return;
                stop();
                if (!root.shapeChanged)
                    throw new Error("Selected button did not change shape when pressed");
                root.equal(selected.topLeftRadius, root.group.outerRadius, "released shape");
                root.equal(root.group.currentIndex, 1, "selection after repeated click");
                root.group.destroy();
                root.scenario++;
                Qt.callLater(root.advance);
            } catch (error) {
                stop();
                console.error("Scenario " + root.scenario + ": " + error);
                Qt.exit(1);
            }
        }
    }

    Component.onCompleted: {
        Style.theme = theme;
        Style.settings = settings;
        I18n.backend = locale;
        Qt.callLater(advance);
    }
}
