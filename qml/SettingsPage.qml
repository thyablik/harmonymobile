import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: page
    property bool compact: false
    readonly property real pad: compact ? 16 : 36
    readonly property var stats: {
        backend.tracks
        backend.playlists
        return backend.libraryStats()
    }

    function fmtBytes(n) {
        if (n >= 1073741824)
            return (n / 1073741824).toFixed(1) + Lang.t(" ГБ")
        if (n >= 1048576)
            return (n / 1048576).toFixed(1) + Lang.t(" МБ")
        if (n >= 1024)
            return Math.round(n / 1024) + Lang.t(" КБ")
        return Lang.t("0 КБ")
    }

    FolderDialog {
        id: dirDialog
        title: Lang.t("Папка для скачивания")
        onAccepted: backend.downloadDir = selectedFolder.toString()
    }

    ColorDialog {
        id: colorDialog
        property string target: ""
        selectedColor: "#ffffff"

        function pick(targetName, current, heading) {
            target = targetName
            title = heading
            selectedColor = current
            open()
        }

        onAccepted: {
            if (target === "text")
                backend.lyricsTextColor = selectedColor
            else if (target === "active")
                backend.lyricsActiveColor = selectedColor
            else if (target === "background")
                backend.lyricsBgColor = selectedColor
        }
    }

    component Card: Rectangle {
        id: card
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + 36
        radius: 26
        color: Theme.surface
        default property alias content: body.data

        ColumnLayout {
            id: body
            x: 18
            y: 18
            width: card.width - 36
            spacing: 4
        }
    }

    component RowItem: Item {
        id: row
        property string heading: ""
        property string details: ""
        default property alias control: controls.data
        Layout.fillWidth: true
        implicitHeight: Math.max(labels.implicitHeight, controls.implicitHeight) + 18

        ColumnLayout {
            id: labels
            anchors.left: parent.left
            anchors.right: controls.left
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                text: row.heading
                color: Theme.text
                font.pixelSize: 15
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: row.details
                visible: row.details !== ""
                color: Theme.textDim
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
        RowLayout {
            id: controls
            width: implicitWidth
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
        }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.surfaceHi
        Layout.topMargin: 6
        Layout.bottomMargin: 6
    }

    component ColorSwatch: Rectangle {
        id: swatch
        property color value
        signal picked()
        implicitWidth: 34
        implicitHeight: 34
        radius: 10
        color: value
        border.width: 1
        border.color: Theme.textDim
        Behavior on color { ColorAnimation { duration: 160 } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: swatch.picked()
        }
    }

    component ChoiceChip: Rectangle {
        id: chip
        property string label: ""
        property bool selected: false
        signal clicked()
        implicitWidth: chipText.implicitWidth + 28
        implicitHeight: 34
        radius: 17
        color: selected ? Theme.accent : Theme.surfaceHi
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.selected ? Theme.onAccent : Theme.text
            font.pixelSize: 13
            font.bold: chip.selected
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    component Toggle: Item {
        id: tg
        property bool checked: false
        signal toggled(bool value)
        implicitWidth: 52
        implicitHeight: 30

        Rectangle {
            anchors.fill: parent
            radius: 15
            color: tg.checked ? Theme.accent : Theme.surfaceHi
            border.width: 1
            border.color: tg.checked ? "transparent" : Theme.textDim
            Behavior on color { ColorAnimation { duration: 160 } }

            Rectangle {
                width: 22
                height: 22
                radius: 11
                y: 4
                x: tg.checked ? parent.width - width - 4 : 4
                color: tg.checked ? Theme.onAccent : Theme.textDim
                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tg.toggled(!tg.checked)
        }
    }

    Flickable {
        id: fl
        anchors.fill: parent
        contentHeight: col.implicitHeight + page.pad * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: SlimScrollBar { }

        ColumnLayout {
            id: col
            x: page.pad
            y: page.pad
            width: fl.width - page.pad * 2
            spacing: 14

            Text {
                text: Lang.t("Настройки")
                color: Theme.text
                font.pixelSize: page.compact ? 30 : 38
                font.bold: true
            }
            Text {
                text: Lang.t("Оформление, хранение файлов и параметры загрузок.")
                color: Theme.textDim
                font.pixelSize: 15
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Text {
                text: Lang.t("Язык")
                color: Theme.text
                font.pixelSize: 18
                font.bold: true
                Layout.topMargin: 10
            }

            Card {
                RowItem {
                    heading: Lang.t("Язык")
                    details: Lang.t("Язык интерфейса приложения.")
                    Row {
                        spacing: 8
                        Repeater {
                            model: [
                                { key: "uk", label: backend.languageName("uk") },
                                { key: "ru", label: backend.languageName("ru") },
                                { key: "en", label: backend.languageName("en") }
                            ]
                            delegate: ChoiceChip {
                                label: modelData.label
                                selected: backend.language === modelData.key
                                onClicked: backend.language = modelData.key
                            }
                        }
                    }
                }
            }

            Text {
                text: Lang.t("Внешний вид")
                color: Theme.text
                font.pixelSize: 18
                font.bold: true
                Layout.topMargin: 10
            }

            Card {
                RowItem {
                    heading: Lang.t("Акцент по обложке")
                    details: Lang.t("Цвет интерфейса подстраивается под обложку текущего трека.")
                    Toggle {
                        checked: backend.dynamicTheme
                        onToggled: function(v) {
                            backend.dynamicTheme = v
                            if (v && Player.current && Player.current.cover)
                                Theme.setAccent(backend.dominantColor(Player.current.cover))
                        }
                    }
                }
            }

            Text {
                text: Lang.t("Текст песен")
                color: Theme.text
                font.pixelSize: 18
                font.bold: true
                Layout.topMargin: 10
            }

            Card {
                RowItem {
                    heading: Lang.t("Цвет текста")
                    details: Lang.t("Строки, заголовок и элементы панели текста.")
                    ColorSwatch {
                        value: backend.lyricsTextColor
                        onPicked: colorDialog.pick("text", backend.lyricsTextColor, Lang.t("Цвет текста"))
                    }
                    Text {
                        text: backend.lyricsTextColor.toString().toUpperCase()
                        color: Theme.textDim
                        font.pixelSize: 12
                        font.family: "Consolas"
                    }
                }
                Divider {}
                RowItem {
                    heading: Lang.t("Цвет активной строки")
                    details: Lang.t("Строка, которая звучит прямо сейчас.")
                    ColorSwatch {
                        value: backend.lyricsActiveColor
                        onPicked: colorDialog.pick("active", backend.lyricsActiveColor, Lang.t("Цвет активной строки"))
                    }
                    Text {
                        text: backend.lyricsActiveColor.toString().toUpperCase()
                        color: Theme.textDim
                        font.pixelSize: 12
                        font.family: "Consolas"
                    }
                }
                Divider {}
                RowItem {
                    heading: Lang.t("Фон текста")
                    details: Lang.t("Панель рядом с обложкой и полноэкранный режим.")
                    ColorSwatch {
                        value: backend.lyricsBgColor
                        onPicked: colorDialog.pick("background", backend.lyricsBgColor, Lang.t("Фон текста"))
                    }
                    Text {
                        text: backend.lyricsBgColor.toString().toUpperCase()
                        color: Theme.textDim
                        font.pixelSize: 12
                        font.family: "Consolas"
                    }
                }
                Divider {}
                RowItem {
                    heading: Lang.t("Размер текста")
                    details: Lang.t("От 13 до 34 px.")
                    IconButton {
                        icon: Icons.minus
                        color: Theme.textDim
                        iconSize: 19
                        implicitWidth: 34
                        implicitHeight: 34
                        enabled: backend.lyricsFontSize > 13
                        opacity: enabled ? 1 : 0.3
                        onClicked: backend.lyricsFontSize = Math.max(13, backend.lyricsFontSize - 1)
                    }
                    Text {
                        text: backend.lyricsFontSize
                        color: Theme.text
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.preferredWidth: 28
                    }
                    IconButton {
                        icon: Icons.plus
                        color: Theme.textDim
                        iconSize: 19
                        implicitWidth: 34
                        implicitHeight: 34
                        enabled: backend.lyricsFontSize < 34
                        opacity: enabled ? 1 : 0.3
                        onClicked: backend.lyricsFontSize = Math.min(34, backend.lyricsFontSize + 1)
                    }
                }
                Divider {}
                RowItem {
                    heading: Lang.t("Выравнивание")
                    details: Lang.t("Как располагать строки в панели и на весь экран.")
                    ChoiceChip {
                        label: Lang.t("Слева")
                        selected: backend.lyricsAlign === "left"
                        onClicked: backend.lyricsAlign = "left"
                    }
                    ChoiceChip {
                        label: Lang.t("По центру")
                        selected: backend.lyricsAlign === "center"
                        onClicked: backend.lyricsAlign = "center"
                    }
                }
                Divider {}
                RowItem {
                    heading: Lang.t("Автопрокрутка")
                    details: Lang.t("Держать текущую строку по центру.")
                    Toggle {
                        checked: backend.lyricsAutoScroll
                        onToggled: function(v) { backend.lyricsAutoScroll = v }
                    }
                }
                Divider {}
                RowItem {
                    heading: Lang.t("Сразу на весь экран")
                    details: Lang.t("Открывать текст песен в полноэкранном режиме вместо панели.")
                    Toggle {
                        checked: backend.lyricsFullscreenDefault
                        onToggled: function(v) { backend.lyricsFullscreenDefault = v }
                    }
                }
                Divider {}
                Text {
                    text: Lang.t("Предпросмотр")
                    color: Theme.textDim
                    font.pixelSize: 12
                    Layout.topMargin: 4
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    implicitHeight: preview.implicitHeight + 36
                    radius: 18
                    color: backend.lyricsBgColor
                    border.width: 1
                    border.color: Theme.surfaceHi
                    clip: true
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Column {
                        id: preview
                        x: 18
                        y: 18
                        width: parent.width - 36
                        spacing: 6

                        Text {
                            width: parent.width
                            text: Lang.t("Не спеши, останься здесь")
                            color: backend.lyricsTextColor
                            font.pixelSize: Math.max(13, backend.lyricsFontSize - 2)
                            horizontalAlignment: backend.lyricsAlign === "center" ? Text.AlignHCenter : Text.AlignLeft
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: Lang.t("Активная строка песни")
                            color: backend.lyricsActiveColor
                            font.pixelSize: backend.lyricsFontSize + 4
                            font.bold: true
                            horizontalAlignment: backend.lyricsAlign === "center" ? Text.AlignHCenter : Text.AlignLeft
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: Lang.t("И время не спешит")
                            color: backend.lyricsTextColor
                            font.pixelSize: Math.max(13, backend.lyricsFontSize - 2)
                            horizontalAlignment: backend.lyricsAlign === "center" ? Text.AlignHCenter : Text.AlignLeft
                            elide: Text.ElideRight
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Item { Layout.fillWidth: true }
                    PillButton {
                        text: Lang.t("Сбросить оформление")
                        outlined: true
                        onActivated: backend.resetLyricsSettings()
                    }
                }
            }

            Text {
                text: Lang.t("Библиотека")
                color: Theme.text
                font.pixelSize: 18
                font.bold: true
                Layout.topMargin: 10
            }

            Card {
                RowItem {
                    heading: Lang.t("Удалять файлы с диска")
                    details: Lang.t("При удалении трека стирать и сам аудиофайл. Если выключено, файл останется на диске.")
                    Toggle {
                        checked: backend.deleteFiles
                        onToggled: function(v) { backend.deleteFiles = v }
                    }
                }
                Divider {}
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: page.stats.tracks + Lang.t(" треков · ") + page.stats.playlists + Lang.t(" плейлистов")
                            color: Theme.text
                            font.pixelSize: 15
                        }
                        Text {
                            text: Lang.t("Занято музыкой: ") + page.fmtBytes(page.stats.bytes)
                            color: Theme.textDim
                            font.pixelSize: 12
                        }
                    }
                    PillButton {
                        text: Lang.t("Открыть папку")
                        icon: Icons.folder
                        outlined: true
                        onActivated: backend.openDataFolder()
                    }
                }
            }

            Text {
                text: Lang.t("Загрузки")
                color: Theme.text
                font.pixelSize: 18
                font.bold: true
                Layout.topMargin: 10
            }

            Card {
                RowLayout {
                    visible: !platform.isMobile
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: Lang.t("Папка загрузок"); color: Theme.text; font.pixelSize: 15 }
                        Text {
                            text: backend.downloadDir
                            color: Theme.textDim
                            font.pixelSize: 12
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }
                    PillButton {
                        text: Lang.t("Изменить")
                        icon: Icons.folder
                        outlined: true
                        onActivated: dirDialog.open()
                    }
                    IconButton {
                        icon: Icons.download
                        color: Theme.textDim
                        onClicked: backend.openDownloadFolder()
                    }
                }
                Divider { visible: !platform.isMobile }
                RowItem {
                    heading: Lang.t("Скачивать обложки")
                    details: Lang.t("Сохранять обложки из плейлистов Spotify, CSV и превью видео при импорте.")
                    Toggle {
                        checked: backend.downloadCovers
                        onToggled: function(v) { backend.downloadCovers = v }
                    }
                }
                Divider {}
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8
                    Text { text: Lang.t("Формат аудио"); color: Theme.text; font.pixelSize: 15 }
                    RowLayout {
                        spacing: 8
                        Repeater {
                            model: [
                                { key: "m4a", label: "M4A (AAC)" },
                                { key: "mp3", label: "MP3", desktopOnly: true },
                                { key: "best", label: Lang.t("Лучший") }
                            ]
                            Rectangle {
                                visible: !(modelData.desktopOnly && platform.isMobile)
                                readonly property bool selected: backend.downloadFormat === modelData.key
                                height: 34
                                width: chipText.implicitWidth + 26
                                radius: 17
                                color: selected ? Theme.accent : Theme.surfaceHi
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: parent.selected ? Theme.onAccent : Theme.text
                                    font.pixelSize: 13
                                    font.bold: parent.selected
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.downloadFormat = modelData.key
                                }
                            }
                        }
                    }
                    Text {
                        text: Lang.t("M4A скачивается без конвертации. Для MP3 нужен установленный ffmpeg.")
                        color: Theme.textDim
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            Text {
                text: Lang.t("О приложении")
                color: Theme.text
                font.pixelSize: 18
                font.bold: true
                Layout.topMargin: 10
            }

            Card {
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    spacing: 16
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Harmony 1.0"; color: Theme.text; font.pixelSize: 15; font.bold: true }
                        Text {
                            text: Lang.t("Локальный музыкальный плеер. Все файлы хранятся на устройстве.")
                            color: Theme.textDim
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                    PillButton {
                        text: Lang.t("Сбросить настройки")
                        outlined: true
                        onActivated: backend.resetSettings()
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
