import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets.Expressive as Expressive

Expressive.DankActionButton {
    radius: Style.buttonRadius(width, height, buttonSize, pressed, circular)
    shapeDuration: LockMetrics.effectsDuration
    shapeCurve: Style.expressiveCurves.expressiveEffects
    stateDuration: LockMetrics.effectsDuration
    stateCurve: Style.expressiveCurves.expressiveEffects
}
