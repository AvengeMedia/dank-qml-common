import QtQuick
import qs.DankCommon.Widgets
import qs.DankCommon.Common

Item {
    id: root
    property QtObject theme: QtObject {
        property int radiusStrength: 50
        property int currentAnimationSpeed: 0
    }
    Component {
        id: clockFactory
        DankAnalogClock {
            width: 200
            height: 200
        }
    }
    function equal(actual, expected, name) {
        if (actual === expected || (typeof actual === "number" && Math.abs(actual - expected) < 0.001))
            return;
        throw new Error(name + ": " + actual + " != " + expected);
    }
    function run() {
        let cases = 0;
        try {
            for (const [hours, minutes, seconds, hourAngle, minuteAngle, position] of [[0, 0, 0, 0, 0, "bottom"], [3, 0, 0, 90, 0, "bottom"], [15, 0, 0, 90, 0, "bottom"], [1, 10, 0, 35, 60, "bottom"], [4, 25, 0, 132.5, 150, "top"], [10, 35, 0, 317.5, 210, "right"], [2, 20, 30, 70, 123, "left"]]) {
                const clock = clockFactory.createObject(root, {
                    hours: hours,
                    minutes: minutes,
                    seconds: seconds
                });
                equal(clock.hourAngle, hourAngle, "hour angle " + hours + ":" + minutes);
                equal(clock.minuteAngle, minuteAngle, "minute angle " + minutes + ":" + seconds);
                equal(clock.datePosition, position, "date position " + hours + ":" + minutes);
                clock.destroy();
                cases++;
            }
            const clock = clockFactory.createObject(root, {
                facePadding: 12
            });
            equal(clock.clockSize, 176, "clock size after padding");
            equal(clock.faceRadius, 76, "face radius");
            clock.showNumbers = true;
            equal(clock.dialSize, 200, "inside numbers keep the dial");
            clock.numbersOutside = true;
            equal(clock.dialSize, 200 - (Style.fontSizeSmall + Style.spacingXS) * 2, "outside numbers shrink the dial");
            equal(clock.clockSize, clock.dialSize - 24, "face follows the dial");
            clock.numbersOutside = false;
            clock.width = 10;
            clock.height = 10;
            equal(clock.faceRadius, 0, "face radius floors at zero");
            clock.destroy();
            cases++;
            console.log("PASS " + cases + " analog clock cases");
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
