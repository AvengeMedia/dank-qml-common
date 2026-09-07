import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets.Expressive as Expressive

Expressive.DankActionButton {
    radius: Style.shapeScale > 0 ? (pressed ? Style.cornerRadiusS : circular ? Math.min(Style.cornerRadiusFull, height / 2) : Style.cornerRadiusM) : 0
    shapeDuration: LockMetrics.effectsDuration
    shapeCurve: Style.expressiveCurves.expressiveEffects
    stateDuration: LockMetrics.effectsDuration
    stateCurve: Style.expressiveCurves.expressiveEffects
}
