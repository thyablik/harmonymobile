import QtQuick
import QtQuick.Shapes

// Кнопка play/pause как на YouTube: треугольник плавно «перетекает» в две полоски,
// а круг превращается в скруглённый квадрат (Material 3).
Item {
    id: root
    property bool playing: false
    property real size: 56
    property color color: Theme.accent
    property color iconColor: Theme.onAccent
    signal clicked()

    width: size
    height: size

    property real p: playing ? 1 : 0
    Behavior on p { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    function lerp(a, b, t) { return a + (b - a) * t }

    // play/pause — массивы x,y,x,y,... одинаковой длины
    function poly(play, pause) {
        var r = []
        for (var i = 0; i < play.length; i += 2)
            r.push(Qt.point(lerp(play[i], pause[i], p), lerp(play[i + 1], pause[i + 1], p)))
        r.push(r[0])
        return r
    }

    scale: ma.pressed ? 0.90 : (ma.containsMouse ? 1.06 : 1)
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

    Rectangle {
        anchors.fill: parent
        color: root.color
        radius: root.size / 2 - root.size * 0.20 * root.p
    }

    Item {
        id: glyph
        anchors.centerIn: parent
        width: root.size * 0.56
        height: width
        layer.enabled: true
        layer.smooth: true

        Shape {
            width: 24
            height: 24
            scale: glyph.width / 24
            transformOrigin: Item.TopLeft
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.iconColor
                strokeColor: "transparent"
                PathPolyline {
                    path: root.poly([8, 5, 12.5, 7.9, 12.5, 16.1, 8, 19],
                                    [6, 5, 10, 5, 10, 19, 6, 19])
                }
            }
            ShapePath {
                fillColor: root.iconColor
                strokeColor: "transparent"
                PathPolyline {
                    path: root.poly([12.5, 7.9, 19, 12, 19, 12, 12.5, 16.1],
                                    [14, 5, 18, 5, 18, 19, 14, 19])
                }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
