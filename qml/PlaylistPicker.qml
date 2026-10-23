import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: pop
    property var track: null

    modal: true
    focus: true
    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    width: Math.min(380, Overlay.overlay ? Overlay.overlay.width - 32 : 380)
    height: Math.min(500, Overlay.overlay ? Overlay.overlay.height - 64 : 500)
    padding: 18

    Overlay.modal: Rectangle { color: "#99000000" }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 280; easing.type: Easing.OutBack }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 140 }
            NumberAnimation { property: "scale"; to: 0.95; duration: 140 }
        }
    }

    background: Rectangle { color: Theme.surfaceHi; radius: 28 }

    function create() {
        var name = newName.text.trim()
        if (name && pop.track) {
            var id = backend.createPlaylist(name)
            backend.addToPlaylist(id, pop.track.id)
            newName.text = ""
            pop.close()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text { text: Lang.t("Добавить в плейлист"); color: Theme.text; font.pixelSize: 20; font.bold: true }

        ListView {
            id: lv
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: backend.playlists

            Text {
                anchors.centerIn: parent
                visible: lv.count === 0
                text: Lang.t("Плейлистов пока нет")
                color: Theme.textDim
            }

            delegate: Rectangle {
                width: lv.width
                height: 54
                radius: 16
                color: dm.containsMouse ? Theme.surface : "transparent"
                Behavior on color { ColorAnimation { duration: 140 } }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 14
                    spacing: 12
                    Cover { Layout.preferredWidth: 38; Layout.preferredHeight: 38; radius: 10; path: modelData.cover; label: modelData.name }
                    Text { text: modelData.name; color: Theme.text; font.pixelSize: 15; Layout.fillWidth: true; elide: Text.ElideRight }
                    Text { text: modelData.count; color: Theme.textDim; font.pixelSize: 13 }
                }
                MouseArea {
                    id: dm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (pop.track)
                            backend.addToPlaylist(modelData.id, pop.track.id)
                        pop.close()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: newName
                Layout.fillWidth: true
                implicitHeight: 46
                placeholderText: Lang.t("Новый плейлист")
                color: Theme.text
                placeholderTextColor: Theme.textDim
                leftPadding: 16
                background: Rectangle {
                    radius: 16
                    color: Theme.surface
                    border.width: 2
                    border.color: newName.activeFocus ? Theme.accent : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
                onAccepted: pop.create()
            }
            IconButton {
                icon: Icons.add
                filled: true
                onClicked: pop.create()
            }
        }
    }
}
