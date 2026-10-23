import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: pg
    property bool compact: false
    readonly property real pad: compact ? 16 : 36

    // зависимость от backend.playlists обновляет список после изменений
    readonly property var tracks: {
        backend.playlists
        return Nav.playlist ? backend.playlistTracks(Nav.playlist.id) : []
    }

    Flickable {
        id: fl
        anchors.fill: parent
        contentHeight: col.implicitHeight + pg.pad * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { }

        ColumnLayout {
            id: col
            x: pg.pad
            y: pg.pad
            width: fl.width - pg.pad * 2
            spacing: 20

            RowLayout {
                spacing: 8
                IconButton { icon: Icons.chevronLeft; onClicked: Nav.go(0) }
                Text { text: Lang.t("На главную"); color: Theme.textDim; font.pixelSize: 14 }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: heroRow.implicitHeight + 48
                radius: 32
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.accentContainer }
                    GradientStop { position: 1.0; color: Theme.surface }
                }

                RowLayout {
                    id: heroRow
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 28

                    Cover {
                        Layout.preferredWidth: pg.compact ? 110 : 190
                        Layout.preferredHeight: pg.compact ? 110 : 190
                        radius: 24
                        path: Nav.playlist ? Nav.playlist.cover : ""
                        label: Nav.playlist ? Nav.playlist.name : ""
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text { text: Lang.t("ПЛЕЙЛИСТ"); color: Theme.accent; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.5 }
                        Text {
                            text: Nav.playlist ? Nav.playlist.name : ""
                            color: Theme.text
                            font.pixelSize: pg.compact ? 26 : 46
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text { text: pg.tracks.length + Lang.t(" треков"); color: Theme.textDim; font.pixelSize: 14 }
                        RowLayout {
                            Layout.topMargin: 12
                            spacing: 10
                            PillButton { text: Lang.t("Слушать"); icon: Icons.play; onActivated: Player.playAll(pg.tracks, false) }
                            PillButton { text: Lang.t("Вперемешку"); icon: Icons.shuffle; outlined: true; visible: !pg.compact; onActivated: Player.playAll(pg.tracks, true) }
                        }
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: pg.tracks
                    TrackRow {
                        width: parent.width
                        track: modelData
                        order: index
                        showAlbum: !pg.compact && width > 760
                        onActivated: Player.play(modelData, pg.tracks)
                        onMoreRequested: Player.pickRequested(modelData)
                        onDeleteRequested: Nav.askDelete(modelData)
                    }
                }
            }

            Text {
                visible: pg.tracks.length === 0
                text: Lang.t("В плейлисте пока нет треков. Добавьте их кнопкой «в плейлист» у любого трека.")
                color: Theme.textDim
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
