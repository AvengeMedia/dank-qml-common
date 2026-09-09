import QtQuick
import qs.DankCommon.Widgets
import qs.DankCommon.Common

DankActionButton {
    radius: Style.buttonRadius(width, height, buttonSize, pressed, circular)
    shapeDuration: LockMetrics.effectsDuration
    shapeCurve: Style.expressiveCurves.expressiveEffects
    stateDuration: LockMetrics.effectsDuration
    stateCurve: Style.expressiveCurves.expressiveEffects
}
