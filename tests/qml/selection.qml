import QtQuick
import qs.DankCommon.Widgets
import qs.DankCommon.Common

Item {
    id: root
    width: 320
    height: 600
    property QtObject theme: QtObject {
        property int radiusStrength: 50
        property int currentAnimationSpeed: 0
    }
    property var scenarios: []
    property int scenarioIndex: 0
    property int rowHeight: 56

    DankListView {
        id: list
        anchors.fill: parent
        animateSelection: false
        spacing: Style.groupedListGap
        reuseItems: true
        delegate: DankListItem {
            required property int index
            width: list.width
            height: root.rowHeight
            firstInGroup: index === 0
            lastInGroup: index === list.count - 1
            isSelected: index === list.currentIndex
        }
    }

    DankListHighlight {
        id: detachedHighlight
        width: list.width
        height: root.rowHeight
        firstInGroup: list.currentIndex === 0
        lastInGroup: list.currentIndex === list.count - 1
    }

    function equal(actual, expected, name) {
        if (Math.abs(actual - expected) < 0.001)
            return;
        throw new Error(name + ": " + actual + " != " + expected);
    }

    function corners(item, top, bottom, name) {
        equal(item.topLeftRadius, top, name + " top left");
        equal(item.topRightRadius, top, name + " top right");
        equal(item.bottomLeftRadius, bottom, name + " bottom left");
        equal(item.bottomRightRadius, bottom, name + " bottom right");
    }

    function check() {
        try {
            const scenario = scenarios[scenarioIndex];
            const [strength, outer, inner] = scenario.shape;
            for (let index = 0; index < list.count; index++) {
                const row = list.itemAtIndex(index);
                if (!row)
                    throw new Error("Missing delegate " + index);
                const top = index === 0 ? outer : inner;
                const bottom = index === list.count - 1 ? outer : inner;
                corners(row, top, bottom, "row " + index);
                row.isHovered = true;
                corners(row, top, bottom, "hovered row " + index);
                row.isHovered = false;
            }
            const selectedTop = list.currentIndex === 0 ? outer : inner;
            const selectedBottom = list.currentIndex === list.count - 1 ? outer : inner;
            corners(detachedHighlight, selectedTop, selectedBottom, "detached highlight");
            if (scenario.external) {
                const highlight = list.highlightItem;
                if (!highlight)
                    throw new Error("Missing moving highlight");
                corners(highlight, selectedTop, selectedBottom, "moving highlight");
                equal(highlight.y, list.currentItem.y, "highlight position");
                equal(highlight.height, rowHeight, "highlight height");
                const backgrounds = [...list.contentItem.children].filter(item => item.z === -1 && item.visible);
                equal(backgrounds.length, list.count, "row backgrounds");
                for (const background of backgrounds) {
                    const index = Math.round(background.y / (rowHeight + list.spacing));
                    corners(background, index === 0 ? outer : inner, index === list.count - 1 ? outer : inner, "row background " + index);
                }
            }
            scenarioIndex++;
            Qt.callLater(advance);
        } catch (error) {
            console.error("Scenario " + scenarioIndex + ": " + error);
            Qt.exit(1);
        }
    }

    function advance() {
        if (scenarioIndex === scenarios.length) {
            console.log("PASS " + scenarioIndex + " grouped list navigation cases");
            Qt.quit();
            return;
        }
        const scenario = scenarios[scenarioIndex];
        theme.radiusStrength = scenario.shape[0];
        rowHeight = scenario.height;
        list.model = scenario.count;
        list.currentIndex = scenario.index;
        list.highlightSelection = scenario.external;
        list.forceLayout();
        Qt.callLater(check);
    }

    Component.onCompleted: {
        Style.theme = theme;
        for (const shape of [[0, 0, 0], [25, 8, 2], [50, 16, 4], [75, 29, 7], [100, 43, 11]]) {
            for (const height of [56, 100, 160]) {
                for (const external of [true, false]) {
                    for (const count of [3, 1, 2]) {
                        for (let index = 0; index < count; index++)
                            scenarios.push({
                                shape,
                                height,
                                external,
                                count,
                                index
                            });
                    }
                }
            }
        }
        Qt.callLater(advance);
    }
}
