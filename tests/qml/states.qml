import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets as B
import qs.DankCommon.Widgets.Expressive as E

Item {
    id: root
    property QtObject theme: QtObject {
        property int radiusStrength: 50
        property int currentAnimationSpeed: 0
    }
    Component {
        id: rowFactory
        E.DankListItem {
            width: 300
        }
    }
    Component {
        id: chipFactory
        E.DankFilterChips {
            model: ["One", "Two"]
            width: 400
        }
    }
    Component {
        id: highlightFactory
        B.DankListHighlight {
            width: 300
            height: 56
        }
    }
    function equal(actual, expected, name) {
        if (Math.abs(actual - expected) < 0.001)
            return;
        throw new Error(name + ": " + actual + " != " + expected);
    }
    function run() {
        let cases = 0;
        try {
            for (const [strength, outer, inner, chipRadius] of [[0, 0, 0, 0], [25, 8, 2, 4], [50, 16, 4, 8], [100, 43, 11, 21]]) {
                theme.radiusStrength = strength;
                const highlight = highlightFactory.createObject(root);
                equal(highlight.topLeftRadius, outer, "standalone highlight top radius");
                equal(highlight.bottomLeftRadius, outer, "standalone highlight bottom radius");
                highlight.destroy();
                for (const first of [false, true]) {
                    for (const last of [false, true]) {
                        for (const selected of [false, true]) {
                            for (const hovered of [false, true]) {
                                const row = rowFactory.createObject(root, {
                                    firstInGroup: first,
                                    lastInGroup: last,
                                    isSelected: selected,
                                    isHovered: hovered
                                });
                                equal(row.topLeftRadius, first ? outer : inner, "row top left");
                                equal(row.topRightRadius, first ? outer : inner, "row top right");
                                equal(row.bottomLeftRadius, last ? outer : inner, "row bottom left");
                                equal(row.bottomRightRadius, last ? outer : inner, "row bottom right");
                                row.destroy();
                                cases++;
                            }
                        }
                    }
                }
                const chips = chipFactory.createObject(root);
                const delegates = [...chips.children].filter(item => typeof item.selected === "boolean");
                equal(delegates.length, 2, "chip delegates");
                for (const chip of delegates)
                    equal(chip.radius, chipRadius, "chip initial radius");
                chips.currentIndex = 1;
                for (const chip of delegates)
                    equal(chip.radius, chipRadius, "chip radius after selection");
                chips.destroy();
                cases++;
            }
            console.log("PASS " + cases + " list and chip state cases");
            Qt.quit();
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    }
    Component.onCompleted: {
        Style.theme = theme;
        Qt.callLater(run);
    }
}
