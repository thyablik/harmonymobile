import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: lib
    property bool compact: false
    readonly property real pad: compact ? 16 : 36

    function filtered() {
        const q = search.text.trim().toLowerCase()
        return backend.tracks.filter(t =>
            !q || (t.title + " " + t.artist + " " + t.genre + " " + t.album).toLowerCase().indexOf(q) >= 0)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: lib.pad
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Text { text: Lang.t("Библиотека"); color: Theme.text; font.pixelSize: compact ? 30 : 38; font.bold: true; Layout.fillWidth: true }
            Text { text: list.count + Lang.t(" треков"); color: Theme.textDim; font.pixelSize: 14 }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.maximumWidth: 640
            height: 54
            radius: 27
            color: Theme.surface
            border.width: 2
            border.color: search.activeFocus ? Theme.accent : "transparent"
            Behavior on border.color { ColorAnimation { duration: 160 } }

            Icon {
                id: sIcon
                x: 18
                anchors.verticalCenter: parent.verticalCenter
                path: Icons.search
                color: search.activeFocus ? Theme.accent : Theme.textDim
            }
            TextInput {
                id: search
                anchors.left: sIcon.right
                anchors.leftMargin: 12
                anchors.right: clearBtn.left
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                font.pixelSize: 16
                clip: true
                selectByMouse: true
                selectionColor: Theme.accent
                Text {
                    visible: !search.text && !search.activeFocus
                    text: Lang.t("Название, артист, жанр, альбом")
                    color: Theme.textDim
                    font.pixelSize: 16
                }
            }
            IconButton {
                id: clearBtn
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 38
                implicitHeight: 38
                icon: Icons.close
                iconSize: 20
                color: Theme.textDim
                scale: search.text ? 1 : 0
                visible: scale > 0.01
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                onClicked: search.text = ""
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: lib.filtered()
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { }

            delegate: TrackRow {
                width: list.width
                track: modelData
                order: index
                showAlbum: !lib.compact && list.width > 760
                onActivated: Player.play(modelData, list.model)
                onMoreRequested: Player.pickRequested(modelData)
                onDeleteRequested: Nav.askDelete(modelData)
            }

            Column {
                anchors.centerIn: parent
                visible: list.count === 0
                spacing: 12
                Icon { anchors.horizontalCenter: parent.horizontalCenter; path: Icons.search; size: 48; color: Theme.textDim }
                Text { text: Lang.t("Ничего не найдено"); color: Theme.textDim; font.pixelSize: 16 }
            }
        }
    }
}
