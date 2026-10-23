import QtQuick
import QtQuick.Shapes

// Векторная иконка из SVG-пути (сетка 24x24), масштабируется до size.
Item {
    id: ic
    property string path: ""
    property color color: Theme.text
    property real size: 24

    width: size
    height: size
    layer.enabled: true
    layer.smooth: true

    Behavior on color { ColorAnimation { duration: 180 } }

    Shape {
        width: 24
        height: 24
        scale: ic.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: ic.color
            strokeColor: "transparent"
            PathSvg { path: ic.path }
        }
    }
}
