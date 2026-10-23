import QtQuick
import QtQuick.Controls

ScrollBar {
    id: bar
    property color indicatorColor: Theme.textDim

    policy: ScrollBar.AsNeeded
    width: 10
    padding: 2

    background: Item {}

    contentItem: Rectangle {
        implicitWidth: 4
        implicitHeight: 40
        radius: 2
        color: bar.indicatorColor
        opacity: bar.pressed ? 0.55 : 0.28
        visible: bar.size < 1.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
}
