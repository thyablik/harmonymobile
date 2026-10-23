import QtQuick

// Круглая кнопка-иконка: подсветка при наведении, сжатие при нажатии, круговая волна.
Item {
    id: btn
    property string icon: ""
    property color color: Theme.text
    property real iconSize: 24
    property bool filled: false
    property color fillColor: Theme.accent
    property string tip: ""
    signal clicked()

    implicitWidth: 44
    implicitHeight: 44
    width: implicitWidth
    height: implicitHeight

    scale: ma.pressed ? 0.86 : 1
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: btn.filled ? btn.fillColor : btn.color
        opacity: btn.filled ? 1 : (ma.pressed ? 0.20 : (ma.containsMouse ? 0.10 : 0))
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Rectangle {
        id: rip
        anchors.centerIn: parent
        width: 0
        height: width
        radius: width / 2
        color: btn.filled ? Theme.onAccent : btn.color
        opacity: 0
    }

    ParallelAnimation {
        id: ripAnim
        NumberAnimation { target: rip; property: "width"; from: 0; to: btn.width * 1.3; duration: 420; easing.type: Easing.OutCubic }
        NumberAnimation { target: rip; property: "opacity"; from: 0.25; to: 0; duration: 420 }
    }

    Icon {
        anchors.centerIn: parent
        path: btn.icon
        size: btn.iconSize
        color: btn.filled ? Theme.onAccent : btn.color
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            ripAnim.restart()
            btn.clicked()
        }
    }
}
