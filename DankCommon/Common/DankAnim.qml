import QtQuick
import qs.Common

NumberAnimation {
    duration: Theme.expressiveDurations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.expressiveCurves.standard
}
