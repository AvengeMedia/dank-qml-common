import "MaterialShapes.js" as Shapes
import QtQuick
import QtQuick.Shapes
import qs.DankCommon.Common

Item {
    id: root

    property string shape: "cookie4"
    property color color: Style.primary
    property int samplesPerLobe: 14

    readonly property var catalog: Shapes.catalog
    readonly property string pathData: Shapes.buildPath(shape, width, height, samplesPerLobe)

    implicitWidth: Style.iconButtonSize
    implicitHeight: Style.iconButtonSize

    function radiusAt(spec, theta) {
        return Shapes.radiusAt(spec, theta);
    }

    function buildPath(kind, w, h) {
        return Shapes.buildPath(kind, w, h, samplesPerLobe);
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: root.color

            PathSvg {
                path: root.pathData
            }
        }
    }
}
