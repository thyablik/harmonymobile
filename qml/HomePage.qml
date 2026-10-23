import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: home
    property bool compact: false
    property string genre: "all"
    readonly property real pad: compact ? 16 : 36

    function tracksFor() {
        return backend.tracks.filter(t => home.genre === "all" || t.genre === home.genre)
    }

    function genreLabel(name) {
        return name === "all" ? Lang.t("Все") : name
    }

    function greeting() {
        var h = new Date().getHours()
        if (h < 5) return Lang.t("Доброй ночи")
        if (h < 12) return Lang.t("Доброе утро")
        if (h < 18) return Lang.t("Добрый день")
        return Lang.t("Добрый вечер")
    }

    Flickable {
        id: fl
        anchors.fill: parent
        contentHeight: col.implicitHeight + home.pad * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { }

        ColumnLayout {
            id: col
            x: home.pad
            y: home.pad
            width: fl.width - home.pad * 2
            spacing: 26

            Text {
                text: home.greeting()
                color: Theme.text
                font.pixelSize: home.compact ? 30 : 38
                font.bold: true
            }

            // ----- пустое состояние -----
            ColumnLayout {
                visible: backend.tracks.length === 0
                Layout.fillWidth: true
                Layout.topMargin: 40
                spacing: 18

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 110
                    height: 110
                    radius: 36
                    color: Theme.accentContainer
                    Icon { anchors.centerIn: parent; path: Icons.music; size: 54; color: Theme.accent }
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.06; duration: 1400; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    text: Lang.t("Здесь пока пусто")
                    color: Theme.text
                    font.pixelSize: 22
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: Lang.t("Добавьте музыку из Telegram, YouTube, Spotify-плейлиста или с диска.")
                    color: Theme.textDim
                    Layout.alignment: Qt.AlignHCenter
                }
                PillButton {
                    text: Lang.t("Импортировать музыку")
                    icon: Icons.download
                    Layout.alignment: Qt.AlignHCenter
                    onActivated: Nav.go(Nav.pageImport)
                }
            }

            // ----- баннер -----
            Rectangle {
                visible: backend.tracks.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: home.compact ? 180 : 230
                radius: 32
                clip: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.accentContainer }
                    GradientStop { position: 1.0; color: Theme.surface }
                }

                Cover {
                    visible: !home.compact && backend.tracks.length > 0
                    width: 190
                    height: 190
                    radius: 28
                    rotation: 7
                    anchors.right: parent.right
                    anchors.rightMargin: 48
                    anchors.verticalCenter: parent.verticalCenter
                    path: backend.tracks.length ? backend.tracks[0].cover : ""
                    label: backend.tracks.length ? backend.tracks[0].title : ""
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: 32
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Text { text: Lang.t("ВАША МЕДИАТЕКА"); color: Theme.accent; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.5 }
                    Text { text: Lang.t("Всё в одном месте"); color: Theme.text; font.pixelSize: home.compact ? 24 : 34; font.bold: true }
                    Text { text: backend.tracks.length + Lang.t(" треков · ") + backend.playlists.length + Lang.t(" плейлистов"); color: Theme.textDim; font.pixelSize: 14 }
                    RowLayout {
                        Layout.topMargin: 12
                        spacing: 10
                        PillButton { text: Lang.t("Слушать"); icon: Icons.play; onActivated: Player.playAll(backend.tracks, false) }
                        PillButton { text: Lang.t("Вперемешку"); icon: Icons.shuffle; outlined: true; onActivated: Player.playAll(backend.tracks, true) }
                    }
                }
            }

            // ----- жанры-фильтры -----
            Flow {
                visible: backend.genres.length > 0
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: [{ name: "all" }].concat(backend.genres)
                    Rectangle {
                        readonly property bool selected: home.genre === modelData.name
                        height: 38
                        width: chipLabel.implicitWidth + 32
                        radius: selected ? 12 : 19
                        color: selected ? Theme.accent : (cm.containsMouse ? Theme.surfaceHi : Theme.surface)
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Behavior on radius { NumberAnimation { duration: 200 } }
                        scale: cm.pressed ? 0.94 : 1
                        Behavior on scale { NumberAnimation { duration: 110 } }
                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: home.genreLabel(modelData.name)
                            color: parent.selected ? Theme.onAccent : Theme.text
                            font.pixelSize: 14
                        }
                        MouseArea {
                            id: cm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: home.genre = modelData.name
                        }
                    }
                }
            }

            Shelf {
                visible: backend.tracks.length > 0
                Layout.fillWidth: true
                title: home.genre === "all" ? Lang.t("Недавно добавлено") : home.genre
                model: home.tracksFor()
                delegate: TrackCard {
                    track: modelData
                    order: index
                    onActivated: Player.play(modelData, home.tracksFor())
                }
            }

            Shelf {
                readonly property var liked: backend.tracks.filter(t => t.liked)
                visible: liked.length > 0
                Layout.fillWidth: true
                title: Lang.t("Любимое")
                model: liked
                delegate: TrackCard {
                    track: modelData
                    order: index
                    onActivated: Player.play(modelData, backend.tracks.filter(t => t.liked))
                }
            }

            Shelf {
                visible: backend.playlists.length > 0
                Layout.fillWidth: true
                title: Lang.t("Плейлисты")
                model: backend.playlists
                delegate: Item {
                    id: pl
                    width: 160
                    height: 226
                    opacity: 0
                    transform: Translate { id: ptr; y: 20 }
                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: Math.min(index, 10) * 45 }
                        ParallelAnimation {
                            NumberAnimation { target: pl; property: "opacity"; to: 1; duration: 380; easing.type: Easing.OutCubic }
                            NumberAnimation { target: ptr; property: "y"; to: 0; duration: 420; easing.type: Easing.OutCubic }
                        }
                    }
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8
                        Cover {
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 160
                            path: modelData.cover
                            label: modelData.name
                            scale: pm.containsMouse ? 1.04 : 1
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }
                        Text { text: modelData.name; color: Theme.text; font.bold: true; font.pixelSize: 14; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: modelData.count + Lang.t(" треков"); color: Theme.textDim; font.pixelSize: 12 }
                    }
                    MouseArea {
                        id: pm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Nav.openPlaylist(modelData)
                    }
                }
            }

            Shelf {
                visible: backend.genres.length > 0
                Layout.fillWidth: true
                itemHeight: 140
                title: Lang.t("Подборки по жанрам")
                model: backend.genres
                delegate: Item {
                    id: gt
                    width: 230
                    height: 130
                    opacity: 0
                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: Math.min(index, 10) * 45 }
                        NumberAnimation { target: gt; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 24
                        clip: true
                        color: Theme.genreColor(modelData.name)
                        scale: gm.containsMouse ? 1.04 : 1
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        Cover {
                            width: 90
                            height: 90
                            radius: 16
                            rotation: gm.containsMouse ? 12 : 20
                            Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                            anchors.right: parent.right
                            anchors.rightMargin: -12
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: -8
                            path: modelData.cover
                            label: modelData.name
                        }
                        Column {
                            x: 18
                            y: 18
                            spacing: 2
                            Text { text: modelData.name; color: "white"; font.pixelSize: 20; font.bold: true }
                            Text { text: modelData.count + Lang.t(" треков"); color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 12 }
                        }
                    }
                    MouseArea {
                        id: gm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            home.genre = modelData.name
                            var list = home.tracksFor()
                            if (list.length) Player.play(list[0], list)
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
