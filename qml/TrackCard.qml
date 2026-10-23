import QtQuick
import QtQuick.Layouts

// Карточка трека: каскадное появление, увеличение обложки и кнопка play при наведении.
Item {
    id: card
    property var track
    property int order: 0
    signal activated()

    width: 160
    height: 226
    opacity: 0

    transform: Translate { id: tr; y: 20 }

    SequentialAnimation {
        running: true
        PauseAnimation { duration: Math.min(card.order, 10) * 45 }
        ParallelAnimation {
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: tr; property: "y"; to: 0; duration: 420; easing.type: Easing.OutCubic }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Item {
            Layout.preferredWidth: 160
            Layout.preferredHeight: 160

            Cover {
                anchors.fill: parent
                path: card.track ? card.track.cover : ""
                label: card.track ? card.track.title : ""
                scale: ma.containsMouse ? 1.04 : 1
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: fab
                width: 48
                height: 48
                radius: 24
                color: Theme.accent
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: ma.containsMouse ? 10 : -6
                opacity: ma.containsMouse ? 1 : 0
                Behavior on anchors.bottomMargin { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Icon { anchors.centerIn: parent; path: Icons.play; size: 26; color: Theme.onAccent }
            }
        }

        Text {
            text: card.track ? card.track.title : ""
            color: Theme.text
            font.pixelSize: 14
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: card.track ? card.track.artist : ""
            color: Theme.textDim
            font.pixelSize: 12
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.activated()
    }
}
