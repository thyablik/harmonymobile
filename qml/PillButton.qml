import QtQuick

Rectangle {
    id: pill
    property string text: ""
    property string icon: ""
    property bool enabledLook: true
    property bool outlined: false
    signal activated()

    implicitHeight: 46
    implicitWidth: row.implicitWidth + 44
    width: implicitWidth
    height: implicitHeight

    radius: ma.containsMouse && enabledLook ? 14 : height / 2
    Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    color: outlined ? "transparent" : (enabledLook ? Theme.accent : Theme.surfaceHi)
    border.width: outlined ? 1.5 : 0
    border.color: Theme.accent

    scale: ma.pressed && enabledLook ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 180 } }

    readonly property color fg: outlined ? Theme.accent : (enabledLook ? Theme.onAccent : Theme.textDim)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon {
            visible: pill.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            path: pill.icon
            size: 20
            color: pill.fg
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: pill.text
            color: pill.fg
            font.bold: true
            font.pixelSize: 15
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: pill.enabledLook ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (pill.enabledLook) pill.activated()
    }
}
