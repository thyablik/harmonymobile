import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: page
    property bool compact: false
    readonly property real pad: compact ? 16 : 36

    FolderDialog {
        id: tgDlg
        title: Lang.t("Папка экспорта Telegram (с result.json)")
        onAccepted: backend.importTelegram(selectedFolder.toString())
    }
    FileDialog {
        id: tgZipDlg
        title: Lang.t("ZIP-архив экспорта Telegram")
        nameFilters: [Lang.t("ZIP-архивы (*.zip)")]
        onAccepted: backend.importTelegram(selectedFile.toString())
    }
    FileDialog {
        id: csvDlg
        title: Lang.t("Плейлист: CSV или TXT")
        nameFilters: [Lang.t("Плейлисты (*.csv *.txt)")]
        onAccepted: backend.importTracklist(selectedFile.toString(), plName.text)
    }
    FileDialog {
        id: localDlg
        title: Lang.t("Аудиофайлы")
        fileMode: FileDialog.OpenFiles
        nameFilters: [Lang.t("Аудио (*.mp3 *.m4a *.flac *.ogg *.opus *.wav *.aac)")]
        onAccepted: backend.addLocalFiles(selectedFiles.map(u => u.toString()))
    }

    component Field: TextField {
        Layout.fillWidth: true
        implicitHeight: 46
        color: Theme.text
        placeholderTextColor: Theme.textDim
        leftPadding: 16
        background: Rectangle {
            radius: 16
            color: Theme.bg
            border.width: 2
            border.color: parent.activeFocus ? Theme.accent : "transparent"
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }
    }

    Flickable {
        id: fl
        anchors.fill: parent
        contentHeight: col.implicitHeight + page.pad * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { }

        ColumnLayout {
            id: col
            x: page.pad
            y: page.pad
            width: fl.width - page.pad * 2
            spacing: 20

            Text { text: Lang.t("Импорт"); color: Theme.text; font.pixelSize: page.compact ? 30 : 38; font.bold: true }
            Text {
                text: Lang.t("Переносите музыку из других сервисов. Всё сохраняется на устройстве и доступно офлайн.")
                color: Theme.textDim
                font.pixelSize: 15
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            // статус
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: busyRow.implicitHeight + 28
                radius: 20
                color: Theme.accentContainer
                visible: opacity > 0.01
                opacity: backend.busy || backend.status !== "" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }

                RowLayout {
                    id: busyRow
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12
                    BusyIndicator {
                        running: backend.busy
                        visible: backend.busy
                        implicitWidth: 28
                        implicitHeight: 28
                    }
                    Text { text: backend.status; color: Theme.text; wrapMode: Text.Wrap; Layout.fillWidth: true; font.pixelSize: 14 }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    height: 3
                    radius: 1.5
                    color: Theme.accent
                    visible: backend.busy
                    width: 90
                    SequentialAnimation on x {
                        running: backend.busy
                        loops: Animation.Infinite
                        NumberAnimation { from: 0; to: 600; duration: 1300; easing.type: Easing.InOutCubic }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: page.compact || page.width < 980 ? 1 : 2
                columnSpacing: 20
                rowSpacing: 20

                ImportCard {
                    order: 0
                    icon: Icons.telegram
                    heading: "Telegram"
                    details: platform.isMobile
                        ? Lang.t("Экспорт чата в Telegram Desktop (JSON с медиа). Заархивируйте папку экспорта в ZIP и выберите архив.")
                        : Lang.t("Экспорт чата в Telegram Desktop (формат JSON с медиа). Выберите папку, где лежит result.json.")
                    actionText: platform.isMobile ? Lang.t("Выбрать ZIP") : Lang.t("Выбрать папку")
                    actionIcon: platform.isMobile ? Icons.file : Icons.folder
                    onAction: platform.isMobile ? tgZipDlg.open() : tgDlg.open()
                }

                ImportCard {
                    order: 1
                    icon: Icons.link
                    heading: Lang.t("Ссылка")
                    details: Lang.t("Трек, альбом или плейлист YouTube, SoundCloud и других сайтов, которые понимает yt-dlp. Плейлисты сохраняются отдельно с обложкой.")
                    actionText: Lang.t("Скачать")
                    actionIcon: Icons.download
                    actionEnabled: urlField.text.trim() !== "" && !backend.busy
                    onAction: { backend.downloadUrl(urlField.text); urlField.text = "" }
                    Field { id: urlField; placeholderText: "https://..." }
                }

                ImportCard {
                    order: 2
                    icon: Icons.list
                    heading: Lang.t("Плейлист из CSV / TXT")
                    details: Lang.t("Spotify — через экспорт Exportify (CSV). Apple Music, Яндекс Музыка и другие — TXT со строками «Исполнитель - Название». Треки и обложки скачиваются автоматически.")
                    actionText: Lang.t("Выбрать файл")
                    actionIcon: Icons.file
                    onAction: csvDlg.open()
                    Field { id: plName; placeholderText: Lang.t("Название плейлиста") }
                }

                ImportCard {
                    order: 3
                    icon: Icons.file
                    heading: Lang.t("Локальные файлы")
                    details: Lang.t("Добавить аудио, которое уже лежит на устройстве. Обложки и теги читаются автоматически.")
                    actionText: Lang.t("Выбрать файлы")
                    actionIcon: Icons.add
                    onAction: localDlg.open()
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
