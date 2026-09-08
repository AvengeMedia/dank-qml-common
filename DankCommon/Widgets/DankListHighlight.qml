import QtQuick
import qs.DankCommon.Common

Rectangle {
    property bool animate: true
    color: Style.primaryContainer
    radius: Style.groupedListOuterRadius

    Behavior on x {
        enabled: parent && parent.visible && animate && !Style.reduceMotion && !Style.springMotionDisabled
        NumberAnimation {
            duration: Style.shorterDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
        }
    }
    Behavior on y {
        enabled: parent && parent.visible && animate && !Style.reduceMotion && !Style.springMotionDisabled
        NumberAnimation {
            duration: Style.shorterDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
        }
    }
}
