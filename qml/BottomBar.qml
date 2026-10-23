import QtQuick
import QtQuick.Layouts

// Панель «сейчас играет». Выезжает при первом треке; на десктопе — полный набор управления.
Rectangle {
    id: bar
    property bool compact: false
    property bool showExpand: true
    property color barColor: Theme.surfaceHi

    readonly property real fullHeight: compact ? 72 : 92
    implicitHeight: Player.current ? fullHeight : 0
    visible: implicitHeight > 1
    radius: 26
    color: barColor
    opacity: Player.current ? 1 : 0
    Behavior on color { ColorAnimation { duration: 250 } }
    Behavior on opacity { NumberAnimation { duration: 300 } }
    Behavior on implicitHeight { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

    // ---------- компактный вариант ----------
    Item {
        anchors.fill: parent
        visible: bar.compact

        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Player.fullOpen = true }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Cover {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                radius: 14
                path: Player.current ? Player.current.cover : ""
                label: Player.current ? Player.current.title : ""
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: Player.current ? Player.current.title : ""; color: Theme.text; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: Player.current ? Player.current.artist : ""; color: Theme.textDim; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            PlayPauseButton {
                size: 48
                playing: Player.playing
                onClicked: Player.toggle()
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            height: 3
            width: parent.width * (Player.duration > 0 ? Player.position / Player.duration : 0)
            color: Theme.accent
        }
    }

    // ---------- десктопный вариант ----------
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 20
        visible: !bar.compact
        spacing: 16

        // слева: трек
        RowLayout {
            Layout.preferredWidth: bar.width * 0.28
            Layout.maximumWidth: bar.width * 0.28
            spacing: 14

            Item {
                Layout.preferredWidth: 62
                Layout.preferredHeight: 62
                Cover {
                    anchors.fill: parent
                    radius: 16
                    path: Player.current ? Player.current.cover : ""
                    label: Player.current ? Player.current.title : ""
                    scale: cm.containsMouse ? 1.05 : 1
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Player.fullOpen = true }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: Player.current ? Player.current.title : ""; color: Theme.text; font.pixelSize: 15; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: Player.current ? Player.current.artist : ""; color: Theme.textDim; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            IconButton {
                icon: Player.current && Player.current.liked ? Icons.heart : Icons.heartOutline
                color: Player.current && Player.current.liked ? Theme.accent : Theme.textDim
                onClicked: Player.toggleLike()
            }
        }

        // центр: управление и прогресс
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                IconButton {
                    icon: Icons.shuffle
                    color: Player.shuffle ? Theme.accent : Theme.textDim
                    onClicked: Player.shuffle = !Player.shuffle
                }
                IconButton { icon: Icons.skipPrev; iconSize: 28; onClicked: Player.prev() }
                PlayPauseButton { size: 52; playing: Player.playing; onClicked: Player.toggle() }
                IconButton { icon: Icons.skipNext; iconSize: 28; onClicked: Player.next() }
                IconButton {
                    icon: Icons.repeat
                    color: Player.repeat ? Theme.accent : Theme.textDim
                    onClicked: Player.repeat = !Player.repeat
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: Player.fmt(Player.position); color: Theme.textDim; font.pixelSize: 12; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                SeekBar {
                    Layout.fillWidth: true
                    value: Player.duration > 0 ? Player.position / Player.duration : 0
                    onSeeked: v => Player.seek(v)
                }
                Text { text: Player.fmt(Player.duration); color: Theme.textDim; font.pixelSize: 12; Layout.preferredWidth: 38 }
            }
        }

        // справа: громкость
        RowLayout {
            Layout.preferredWidth: bar.width * 0.2
            Layout.maximumWidth: bar.width * 0.2
            spacing: 6
            Item { Layout.fillWidth: true }
            IconButton {
                icon: Player.volume > 0 ? Icons.volume : Icons.volumeOff
                color: Theme.textDim
                onClicked: Player.toggleMute()
            }
            SeekBar {
                Layout.preferredWidth: 100
                live: true
                value: Player.volume
                onSeeked: v => Player.volume = v
            }
            IconButton {
                icon: Icons.expandLess
                color: Theme.textDim
                visible: bar.showExpand
                onClicked: Player.fullOpen = true
            }
        }
    }
}
