import QtQuick
import qs.DankCommon.Widgets
import qs.DankCommon.Common

Item {
    id: root
    width: 600
    height: 600

    property QtObject theme: QtObject {
        property int radiusStrength: 50
        property int currentAnimationSpeed: 0
    }
    property QtObject locale: QtObject {
        property bool isRtl: false
    }
    Component {
        id: factory
        DankSlider {
            width: 400
            showValue: false
        }
    }

    function equal(actual, expected, label) {
        if (Math.abs(actual - expected) < 0.00001)
            return;
        throw new Error(label + ": got " + actual + ", expected " + expected);
    }

    function run() {
        let cases = 0;
        const sizes = ["xs", "s", "m", "l", "xl"];
        const radii = [8, 8, 12, 16, 28];
        const tracks = [16, 24, 40, 56, 96];
        const handles = [32, 32, 44, 68, 108];
        try {
            for (const [strength, scale] of [[0, 0], [25, 0.5], [50, 1], [60, 4 / 3], [100, 8 / 3]]) {
                theme.radiusStrength = strength;
                for (let i = 0; i < sizes.length; i++) {
                    for (const rtl of [false, true]) {
                        locale.isRtl = rtl;
                        for (const center of [false, true]) {
                            for (const value of [0, 1, 50, 99, 100]) {
                                const slider = factory.createObject(root, {
                                    size: sizes[i],
                                    centerMinimum: center,
                                    value: value
                                });
                                const track = slider.children[0].children[1];
                                const active = track.children[0];
                                const inactive = track.children[1];
                                const outer = Math.min(slider.trackHeight / 2, radii[i] * scale);
                                const inner = Math.min(slider.trackHeight / 2, 2 * scale);
                                equal(slider.trackHeight, tracks[i], "track height");
                                equal(slider.handleHeight, handles[i], "handle height");
                                equal(active.topLeftRadius, rtl ? inner : outer, "active left");
                                equal(active.topRightRadius, rtl ? outer : inner, "active right");
                                equal(inactive.topLeftRadius, rtl ? outer : inner, "inactive left");
                                equal(inactive.topRightRadius, rtl ? inner : outer, "inactive right");
                                equal(active.bottomLeftRadius, active.topLeftRadius, "active bottom left");
                                equal(active.bottomRightRadius, active.topRightRadius, "active bottom right");
                                equal(inactive.bottomLeftRadius, inactive.topLeftRadius, "inactive bottom left");
                                equal(inactive.bottomRightRadius, inactive.topRightRadius, "inactive bottom right");
                                equal(inactive.children[0].radius, Math.min(1, scale) * 2, "stop radius");
                                if (active.width < 0 || inactive.width < 0)
                                    throw new Error("negative track width");
                                slider.destroy();
                                cases++;
                            }
                        }
                    }
                }
            }
            const formatter = factory.createObject(root, {
                unit: ""
            });
            if (formatter.formatValue(5) !== "5")
                throw new Error("column counts must not show a percentage");
            formatter.decimals = 1;
            formatter.unit = "×";
            if (formatter.formatValue(15) !== "1.5×")
                throw new Error("scroll factors must show their decimal multiplier");
            formatter.unit = "";
            if (formatter.formatValue(-10) !== "-1.0")
                throw new Error("pointer speed must show its signed decimal value");
            formatter.decimals = 0;
            formatter.unit = "px";
            if (formatter.formatValue(-12) !== "-12px")
                throw new Error("size offsets must show pixels");
            formatter.destroy();
            console.log("PASS: " + cases + " slider geometry cases and value formatting");
            Qt.quit();
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    }

    Component.onCompleted: {
        Style.theme = theme;
        I18n.backend = locale;
        Qt.callLater(run);
    }
}
