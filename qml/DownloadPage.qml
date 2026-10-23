import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property bool compact: false
    readonly property real pad: compact ? 16 : 36

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

            Text {
                text: Lang.t("Загрузки")
                color: Theme.text
                font.pixelSize: page.compact ? 30 : 38
                font.bold: true
            }
            Text {
                text: Lang.t("Найдите песню по названию или вставьте ссылку — Harmony скачает трек, обложку и добавит всё в библиотеку.")
                color: Theme.textDim
                font.pixelSize: 15
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

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
                    Text {
                        text: backend.status
                        color: Theme.text
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        font.pixelSize: 14
                    }
                    IconButton {
                        visible: !backend.busy
                        icon: Icons.close
                        iconSize: 20
                        implicitWidth: 34
                        implicitHeight: 34
                        color: Theme.textDim
                        onClicked: backend.clearStatus()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: searchCol.implicitHeight + 40
                radius: 28
                color: Theme.surface

                ColumnLayout {
                    id: searchCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        spacing: 14
                        Rectangle {
                            width: 52
                            height: 52
                            radius: 16
                            color: Theme.accentContainer
                            Icon { anchors.centerIn: parent; path: Icons.search; size: 26; color: Theme.accent }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: Lang.t("Поиск и скачивание"); color: Theme.text; font.pixelSize: 20; font.bold: true }
                            Text { text: Lang.t("Достаточно названия песни или исполнителя"); color: Theme.textDim; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Field {
                            id: query
                            placeholderText: Lang.t("Исполнитель — название песни")
                            onAccepted: if (query.text.trim() && !backend.busy) backend.searchTracks(query.text)
                        }
                        PillButton {
                            text: Lang.t("Найти")
                            icon: Icons.search
                            enabledLook: query.text.trim() !== "" && !backend.busy
                            onActivated: backend.searchTracks(query.text)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        height: 1
                        color: Theme.surfaceHi
                    }

                    Text { text: Lang.t("Или прямая ссылка"); color: Theme.textDim; font.pixelSize: 13; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Field {
                            id: urlField
                            placeholderText: "https://..."
                            onAccepted: if (urlField.text.trim() && !backend.busy) {
                                backend.downloadUrl(urlField.text)
                                urlField.text = ""
                            }
                        }
                        PillButton {
                            text: Lang.t("Скачать")
                            icon: Icons.download
                            enabledLook: urlField.text.trim() !== "" && !backend.busy
                            onActivated: {
                                backend.downloadUrl(urlField.text)
                                urlField.text = ""
                            }
                        }
                    }
                    Text {
                        text: Lang.t("Поддерживаются YouTube, SoundCloud, Bandcamp и другие сайты, с которыми работает yt-dlp.")
                        color: Theme.textDim
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            Text {
                visible: backend.searchResults.length > 0
                text: Lang.t("Результаты поиска")
                color: Theme.text
                font.pixelSize: 22
                font.bold: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: backend.searchResults
                    Rectangle {
                        id: result
                        Layout.fillWidth: true
                        implicitHeight: 78
                        radius: 18
                        color: rh.hovered ? Theme.surfaceHi : Theme.surface
                        Behavior on color { ColorAnimation { duration: 150 } }

                        HoverHandler { id: rh }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 14

                            Cover {
                                Layout.preferredWidth: 54
                                Layout.preferredHeight: 54
                                radius: 12
                                path: modelData.thumbnail
                                label: modelData.title
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: modelData.title
                                    color: Theme.text
                                    font.pixelSize: 15
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.artist
                                    color: Theme.textDim
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                            Text {
                                text: Player.fmt(modelData.duration * 1000)
                                color: Theme.textDim
                                font.pixelSize: 13
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                            }
                            IconButton {
                                icon: Icons.download
                                filled: true
                                iconSize: 22
                                implicitWidth: 42
                                implicitHeight: 42
                                opacity: backend.busy ? 0.45 : 1
                                onClicked: {
                                    if (!backend.busy)
                                        backend.downloadSearchResult(modelData.url, modelData.title,
                                                                     modelData.artist, modelData.thumbnail)
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: backend.searchResults.length === 0 && backend.status === Lang.t("Ничего не найдено")
                text: Lang.t("Ничего не найдено. Попробуйте изменить запрос.")
                color: Theme.textDim
                font.pixelSize: 14
                Layout.fillWidth: true
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
