import QtQuick

// Полоса прогресса/громкости: утолщается и показывает ползунок при наведении.
Item {
    id: bar
    property real value: 0
    property color color: Theme.accent
    property bool live: false
    signal seeked(real v)

    implicitHeight: 20
    height: implicitHeight

    readonly property real shown: ma.pressed ? Math.max(0, Math.min(1, ma.mouseX / width)) : Math.max(0, Math.min(1, value))
    readonly property bool active: ma.containsMouse || ma.pressed

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: bar.active ? 7 : 4
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.14)
        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Rectangle {
            width: parent.width * bar.shown
            height: parent.height
            radius: parent.radius
            color: bar.color
        }
    }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        color: bar.color
        x: track.width * bar.shown - 8
        anchors.verticalCenter: parent.verticalCenter
        scale: bar.active ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: if (bar.live) bar.seeked(Math.max(0, Math.min(1, mouseX / width)))
        onPositionChanged: if (pressed && bar.live) bar.seeked(Math.max(0, Math.min(1, mouseX / width)))
        onReleased: if (!bar.live) bar.seeked(Math.max(0, Math.min(1, mouseX / width)))
    }
}
