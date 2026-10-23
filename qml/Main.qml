import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: win
    visible: true
    width: 1280
    height: 800
    minimumWidth: platform.isMobile ? 0 : 380
    minimumHeight: platform.isMobile ? 0 : 600
    title: "Harmony"
    color: Theme.bg

    readonly property bool compact: platform.isMobile || width < 820

    // Кнопка «Назад» на Android закрывает верхний слой, а не приложение.
    onClosing: function(close) {
        if (!platform.isAndroid)
            return
        if (Player.lyricsFull) {
            Player.lyricsFull = false
            close.accepted = false
        } else if (Player.lyricsOpen) {
            Player.lyricsOpen = false
            close.accepted = false
        } else if (Player.fullOpen) {
            Player.fullOpen = false
            close.accepted = false
        } else if (Nav.page !== Nav.pageHome) {
            Nav.go(Nav.pageHome)
            close.accepted = false
        }
    }

    Connections {
        target: Player
        function onPickRequested(t) {
            picker.track = t
            picker.open()
        }
    }

    Connections {
        target: Nav
        function onDeleteRequested(track) {
            delDlg.track = track
            delDlg.open()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: platform.insetTop
        spacing: 0

        Sidebar {
            visible: !win.compact
            Layout.fillHeight: true
            Layout.preferredWidth: 256
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                PageHost { index: Nav.pageHome; HomePage { anchors.fill: parent; compact: win.compact } }
                PageHost { index: Nav.pageLibrary; LibraryPage { anchors.fill: parent; compact: win.compact } }
                PageHost { index: Nav.pageDownloads; DownloadPage { anchors.fill: parent; compact: win.compact } }
                PageHost { index: Nav.pageImport; ImportPage { anchors.fill: parent; compact: win.compact } }
                PageHost { index: Nav.pagePlaylist; PlaylistPage { anchors.fill: parent; compact: win.compact } }
                PageHost { index: Nav.pageSettings; SettingsPage { anchors.fill: parent; compact: win.compact } }
            }

            BottomBar {
                Layout.fillWidth: true
                Layout.leftMargin: win.compact ? 8 : 16
                Layout.rightMargin: win.compact ? 8 : 16
                Layout.bottomMargin: Player.current ? (win.compact ? 6 : 16) : 0
                compact: win.compact
            }

            BottomNav {
                visible: win.compact
                Layout.fillWidth: true
                Layout.preferredHeight: 68 + platform.insetBottom
            }
        }
    }

    FullPlayer {
        x: 0
        width: parent.width
        height: parent.height
        compact: win.compact
    }

    PlaylistPicker { id: picker }

    ConfirmDialog {
        id: delDlg
        property var track: null
        heading: Lang.t("Удалить трек?")
        message: delDlg.track
            ? Lang.t("Трек «") + delDlg.track.title + Lang.t("» будет удалён из библиотеки.")
              + (backend.deleteFiles ? Lang.t(" Файл также будет удалён с диска.") : Lang.t(" Файл останется на диске."))
            : ""
        confirmText: Lang.t("Удалить")
        danger: true
        onConfirmed: {
            if (delDlg.track) {
                var tid = delDlg.track.id
                Player.removeTrack(tid)
                backend.removeTrack(tid)
            }
        }
    }
}
