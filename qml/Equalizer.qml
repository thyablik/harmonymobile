import QtQuick

// Анимированный эквалайзер «сейчас играет».
Item {
    id: eq
    property bool running: true
    property color color: Theme.accent
    width: 18
    height: 18

    Repeater {
        model: 3
        Rectangle {
            x: index * 6
            width: 4
            radius: 2
            color: eq.color
            height: 6
            anchors.bottom: eq.bottom

            SequentialAnimation on height {
                running: eq.running
                loops: Animation.Infinite
                NumberAnimation { to: 17; duration: 320 + index * 110; easing.type: Easing.InOutSine }
                NumberAnimation { to: 4; duration: 380 + index * 90; easing.type: Easing.InOutSine }
            }
        }
    }
}
