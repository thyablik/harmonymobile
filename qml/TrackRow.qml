import QtQuick
import QtQuick.Layouts

Rectangle {
    id: row
    property var track
    property int order: 0
    property bool showAlbum: false
    signal activated()
    signal moreRequested()
    signal deleteRequested()

    readonly property bool isCurrent: Player.current !== null && track !== undefined && track !== null && Player.current.id === track.id
    readonly property bool hovered: ma.containsMouse || likeBtn.hovered
    readonly property bool touch: platform.isMobile

    height: 64
    radius: 16
    color: ma.containsMouse ? Theme.surfaceHi : (isCurrent ? Theme.accentSoft : "transparent")
    Behavior on color { ColorAnimation { duration: 150 } }

    opacity: 0
    transform: Translate { id: tr; y: 14 }
    SequentialAnimation {
        running: true
        PauseAnimation { duration: Math.min(row.order, 14) * 30 }
        ParallelAnimation {
            NumberAnimation { target: row; property: "opacity"; to: 1; duration: 320; easing.type: Easing.OutCubic }
            NumberAnimation { target: tr; property: "y"; to: 0; duration: 360; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: !row.touch
        cursorShape: Qt.PointingHandCursor
        onClicked: row.activated()
        // долгое нажатие: удалить трек (на ПК для этого есть кнопка-корзина)
        onPressAndHold: if (row.touch) row.deleteRequested()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 12
        spacing: 14

        Item {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48

            Cover {
                anchors.fill: parent
                radius: 12
                path: row.track ? row.track.cover : ""
                label: row.track ? row.track.title : ""
            }
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Qt.rgba(0, 0, 0, 0.5)
                opacity: row.hovered || row.isCurrent ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }
            Equalizer {
                anchors.centerIn: parent
                visible: row.isCurrent && Player.playing
                color: "white"
            }
            Icon {
                anchors.centerIn: parent
                visible: !(row.isCurrent && Player.playing)
                path: Icons.play
                size: 26
                color: "white"
                opacity: row.hovered || row.isCurrent ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: row.track ? row.track.title : ""
                color: row.isCurrent ? Theme.accent : Theme.text
                font.pixelSize: 15
                font.bold: row.isCurrent
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: row.track ? (row.track.artist + (row.track.genre ? "  ·  " + row.track.genre : "")) : ""
                color: Theme.textDim
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Text {
            visible: row.showAlbum
            text: row.track ? row.track.album : ""
            color: Theme.textDim
            font.pixelSize: 13
            elide: Text.ElideRight
            Layout.preferredWidth: 200
        }

        IconButton {
            id: likeBtn
            readonly property bool hovered: ma2.containsMouse
            icon: row.track && row.track.liked ? Icons.heart : Icons.heartOutline
            color: row.track && row.track.liked ? Theme.accent : Theme.textDim
            iconSize: 22
            implicitWidth: 38
            implicitHeight: 38
            onClicked: backend.toggleLike(row.track.id)
            MouseArea { id: ma2; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
        }

        IconButton {
            icon: Icons.playlistAdd
            color: Theme.textDim
            iconSize: 22
            implicitWidth: 38
            implicitHeight: 38
            opacity: row.hovered || row.touch ? 1 : 0
            enabled: row.hovered || row.touch
            Behavior on opacity { NumberAnimation { duration: 160 } }
            onClicked: row.moreRequested()
        }

        IconButton {
            icon: Icons.trash
            color: Theme.error
            iconSize: 22
            implicitWidth: 38
            implicitHeight: 38
            visible: !row.touch
            opacity: row.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            onClicked: row.deleteRequested()
        }

        Text {
            visible: !row.touch
            text: row.track ? Player.fmt(row.track.duration * 1000) : ""
            color: Theme.textDim
            font.pixelSize: 13
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
        }
    }
}
