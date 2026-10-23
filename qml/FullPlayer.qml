import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// Полноэкранный плеер: выезжает снизу, фон — размытая обложка.
Item {
    id: full
    property bool compact: false

    property bool ready: false
    Component.onCompleted: Qt.callLater(function() { full.ready = true })

    y: Player.fullOpen ? 0 : height
    visible: Player.fullOpen || y < height - 1
    z: 20
    Behavior on y { enabled: full.ready; NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }

    Rectangle { anchors.fill: parent; color: Theme.bg }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.accentContainer }
            GradientStop { position: 1.0; color: Theme.bg }
        }
    }

    Image {
        id: bgImg
        anchors.fill: parent
        source: Player.current && Player.current.cover ? backend.url(Player.current.cover) : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
        sourceSize.width: 300
    }
    MultiEffect {
        anchors.fill: parent
        source: bgImg
        visible: bgImg.status === Image.Ready
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        brightness: -0.45
        saturation: 0.3
        opacity: 0.55
    }

    MouseArea { anchors.fill: parent }

    RowLayout {
        id: top
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        anchors.topMargin: 20 + platform.insetTop
        IconButton { icon: Icons.expandMore; iconSize: 30; onClicked: Player.fullOpen = false }
        Item { Layout.fillWidth: true }
        Text { text: Lang.t("Сейчас играет"); color: Theme.textDim; font.pixelSize: 14; font.bold: true }
        Item { Layout.fillWidth: true }
        IconButton {
            icon: Icons.lyrics
            color: Player.lyricsOpen ? Theme.accent : Theme.textDim
            iconSize: 23
            onClicked: {
                if (Player.lyricsOpen) {
                    Player.lyricsOpen = false
                    Player.lyricsFull = false
                } else {
                    Player.lyricsOpen = true
                    Player.lyricsFull = backend.lyricsFullscreenDefault
                }
            }
        }
    }

    GridLayout {
        id: mainGrid
        // Когда на десктопе открыта панель текста, плеер уезжает вправо и становится одной колонкой.
        readonly property real shift: (Player.lyricsOpen && !Player.lyricsFull && !full.compact) ? lyricsPanel.width + 48 : 0
        readonly property bool stacked: full.compact || shift > 0

        anchors.centerIn: parent
        anchors.verticalCenterOffset: 20
        anchors.horizontalCenterOffset: shift / 2
        Behavior on anchors.horizontalCenterOffset { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
        width: Math.min(parent.width - 64 - shift, stacked ? 520 : 1100)
        columns: stacked ? 1 : 2
        columnSpacing: 72
        rowSpacing: 24

        Item {
            Layout.alignment: Qt.AlignHCenter
            readonly property real side: mainGrid.shift > 0
                ? Math.min(220, full.height * 0.3)
                : Math.min(full.width * (full.compact ? 0.78 : 0.36), full.height * (full.compact ? 0.38 : 0.62))
            Layout.preferredWidth: side
            Layout.preferredHeight: side

            Cover {
                anchors.fill: parent
                radius: 32
                path: Player.current ? Player.current.cover : ""
                label: Player.current ? Player.current.title : ""
                scale: Player.playing ? 1 : 0.9
                Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: Player.current ? Player.current.title : Lang.t("Ничего не играет")
                        color: Theme.text
                        font.pixelSize: full.compact ? 26 : 38
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: Player.current ? Player.current.artist : ""
                        color: Theme.textDim
                        font.pixelSize: full.compact ? 16 : 20
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                IconButton {
                    icon: Player.current && Player.current.liked ? Icons.heart : Icons.heartOutline
                    color: Player.current && Player.current.liked ? Theme.accent : Theme.text
                    iconSize: 28
                    implicitWidth: 52
                    implicitHeight: 52
                    onClicked: Player.toggleLike()
                }
            }

            SeekBar {
                Layout.fillWidth: true
                Layout.topMargin: 14
                value: Player.duration > 0 ? Player.position / Player.duration : 0
                onSeeked: v => Player.seek(v)
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: Player.fmt(Player.position); color: Theme.textDim; font.pixelSize: 13 }
                Item { Layout.fillWidth: true }
                Text { text: Player.fmt(Player.duration); color: Theme.textDim; font.pixelSize: 13 }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                spacing: full.compact ? 14 : 22
                IconButton {
                    icon: Icons.shuffle
                    color: Player.shuffle ? Theme.accent : Theme.textDim
                    onClicked: Player.shuffle = !Player.shuffle
                }
                IconButton { icon: Icons.skipPrev; iconSize: 36; implicitWidth: 56; implicitHeight: 56; onClicked: Player.prev() }
                PlayPauseButton { size: 88; playing: Player.playing; onClicked: Player.toggle() }
                IconButton { icon: Icons.skipNext; iconSize: 36; implicitWidth: 56; implicitHeight: 56; onClicked: Player.next() }
                IconButton {
                    icon: Icons.repeat
                    color: Player.repeat ? Theme.accent : Theme.textDim
                    onClicked: Player.repeat = !Player.repeat
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                spacing: 12
                PillButton {
                    text: Lang.t("В плейлист")
                    icon: Icons.playlistAdd
                    outlined: true
                    enabledLook: Player.current !== null
                    onActivated: Player.pickRequested(Player.current)
                }
                IconButton {
                    visible: !platform.isMobile
                    icon: Player.volume > 0 ? Icons.volume : Icons.volumeOff
                    color: Theme.textDim
                    onClicked: Player.toggleMute()
                }
                SeekBar {
                    visible: !platform.isMobile
                    Layout.preferredWidth: 110
                    live: true
                    value: Player.volume
                    onSeeked: v => Player.volume = v
                }
            }
        }
    }

    Rectangle {
        id: lyricsPanel
        z: 30
        readonly property real coverSide: Math.min(full.width * 0.36, full.height * 0.62)
        width: full.compact ? full.width - 24 : Math.min(500, Math.max(340, coverSide))
        height: full.height - (full.compact ? 24 : 48) - platform.insetTop - platform.insetBottom
        y: (full.compact ? 12 : 24) + platform.insetTop
        x: Player.lyricsOpen ? (full.compact ? 12 : 24) : -width - 8
        visible: (Player.lyricsOpen && !Player.lyricsFull) || x > -width
        radius: full.compact ? 22 : 28
        color: backend.lyricsBgColor
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        clip: true

        Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 250 } }

        MouseArea { anchors.fill: parent }

        LyricsView {
            anchors.fill: parent
            compact: full.compact
            onCloseRequested: {
                Player.lyricsOpen = false
                Player.lyricsFull = false
            }
            onFullscreenRequested: Player.lyricsFull = true
        }
    }

    LyricsPage {
        id: lyricsPage
        anchors.fill: parent
        compact: full.compact
        z: 40
        opacity: Player.lyricsOpen && Player.lyricsFull ? 1 : 0
        visible: opacity > 0.01
        enabled: visible
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        onCloseRequested: {
            Player.lyricsFull = false
            Player.lyricsOpen = false
        }
        onPanelRequested: Player.lyricsFull = false
    }
}
