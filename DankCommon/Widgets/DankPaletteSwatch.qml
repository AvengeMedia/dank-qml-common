import QtQuick
import QtQuick.Shapes
import qs.DankCommon.Common

Item {
    id: root

    property color primaryColor: Style.primary
    property color secondaryColor: primaryColor
    property color tertiaryColor: secondaryColor

    readonly property real radius: Math.min(width, height) / 2

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.primaryColor
            strokeWidth: -1
            startX: root.width / 2 + root.radius
            startY: root.height / 2

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            fillColor: root.secondaryColor
            strokeWidth: -1
            startX: root.width / 2
            startY: root.height / 2

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: 90
                sweepAngle: 90
            }

            PathLine {
                x: root.width / 2
                y: root.height / 2
            }
        }

        ShapePath {
            fillColor: root.tertiaryColor
            strokeWidth: -1
            startX: root.width / 2
            startY: root.height / 2

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: 0
                sweepAngle: 90
            }

            PathLine {
                x: root.width / 2
                y: root.height / 2
            }
        }
    }
}
