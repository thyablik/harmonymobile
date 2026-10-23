pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Панель текста: синхронизированные строки LRCLIB или локальный .lrc/.txt.
Item {
    id: view
    property bool compact: false
    property bool fullscreen: false
    signal closeRequested()
    signal fullscreenRequested()

    readonly property var lyricsData: backend.lyrics
    readonly property var lines: view.lyricsData.lines ? view.lyricsData.lines : []
    readonly property bool hasTrack: Player.current !== null
    readonly property bool matchesCurrent: hasTrack && view.lyricsData.trackId === Player.current.id
    readonly property bool synced: matchesCurrent && view.lyricsData.synced === true && lines.length > 0
    readonly property bool plainReady: matchesCurrent && view.lyricsData.synced !== true && view.lyricsData.plain !== ""
    readonly property bool loading: hasTrack && (!matchesCurrent || view.lyricsData.status === "loading")
    readonly property bool ready: matchesCurrent && view.lyricsData.status === "ready"
    readonly property int baseSize: backend.lyricsFontSize + (fullscreen ? 5 : 0)
    readonly property int activeSize: baseSize + 4

    readonly property int currentIndex: {
        if (!synced)
            return -1
        var position = Player.position / 1000
        var found = -1
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].time <= position + 0.12)
                found = i
            else
                break
        }
        return found
    }

    function scrollToCurrent() {
        if (!backend.lyricsAutoScroll || !synced || lv.count === 0)
            return
        lv.positionViewAtIndex(Math.max(0, currentIndex), ListView.Center)
    }

    onCurrentIndexChanged: Qt.callLater(function() { view.scrollToCurrent() })
    onSyncedChanged: Qt.callLater(function() { view.scrollToCurrent() })
    onVisibleChanged: if (visible) Qt.callLater(function() { view.scrollToCurrent() })

    Connections {
        target: Player
        function onCurrentChanged() {
            if (Player.lyricsOpen && Player.current)
                backend.loadLyrics(Player.current.id, false)
        }
        function onLyricsOpenChanged() {
            if (Player.lyricsOpen && Player.current)
                backend.loadLyrics(Player.current.id, false)
        }
    }

    Component.onCompleted: {
        if (Player.lyricsOpen && Player.current)
            backend.loadLyrics(Player.current.id, false)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: view.fullscreen ? 0 : (view.compact ? 18 : 24)
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: !view.fullscreen

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: Lang.t("Текст песни")
                    color: backend.lyricsTextColor
                    font.pixelSize: view.compact ? 19 : 22
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: Player.current
                          ? Player.current.title + (Player.current.artist ? "  ·  " + Player.current.artist : "")
                          : ""
                    color: backend.lyricsTextColor
                    opacity: 0.65
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            IconButton {
                icon: Icons.fullscreen
                color: backend.lyricsTextColor
                iconSize: 20
                implicitWidth: 38
                implicitHeight: 38
                onClicked: view.fullscreenRequested()
            }
            IconButton {
                readonly property bool canRefresh: Player.current !== null && view.lyricsData.status !== "loading"
                icon: Icons.refresh
                color: backend.lyricsTextColor
                iconSize: 21
                implicitWidth: 38
                implicitHeight: 38
                opacity: canRefresh ? 0.85 : 0.35
                onClicked: if (canRefresh) backend.loadLyrics(Player.current.id, true)
            }
            IconButton {
                icon: Icons.close
                color: backend.lyricsTextColor
                iconSize: 22
                implicitWidth: 38
                implicitHeight: 38
                onClicked: view.closeRequested()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: !view.fullscreen && view.ready && view.lyricsData.source !== ""

            Rectangle {
                Layout.topMargin: 1
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: backend.lyricsActiveColor
                opacity: 0.8
            }
            Text {
                Layout.fillWidth: true
                text: view.lyricsData.source + (view.lyricsData.synced ? Lang.t("  ·  синхронизировано") : "")
                color: backend.lyricsTextColor
                opacity: 0.6
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: lv
                anchors.fill: parent
                visible: view.synced
                model: view.synced ? view.lines : []
                clip: true
                spacing: view.fullscreen ? 4 : 2
                boundsBehavior: Flickable.StopAtBounds
                topMargin: view.fullscreen ? 12 : 8
                bottomMargin: view.fullscreen ? 24 : (view.compact ? 56 : 80)
                ScrollBar.vertical: SlimScrollBar { indicatorColor: backend.lyricsTextColor }

                delegate: Item {
                    id: lineItem
                    required property int index
                    required property var modelData
                    width: lv.width
                    height: Math.max(view.fullscreen ? 52 : 38, lineText.implicitHeight + (view.fullscreen ? 24 : 16))

                    readonly property bool active: index === view.currentIndex

                    Text {
                        id: lineText
                        anchors.verticalCenter: parent.verticalCenter
                        x: 6
                        width: lineItem.width - 12
                        text: lineItem.modelData.text
                        color: lineItem.active ? backend.lyricsActiveColor : backend.lyricsTextColor
                        font.pixelSize: lineItem.active ? view.activeSize : view.baseSize
                        font.bold: lineItem.active
                        horizontalAlignment: backend.lyricsAlign === "center" ? Text.AlignHCenter : Text.AlignLeft
                        wrapMode: Text.Wrap
                        Behavior on color { ColorAnimation { duration: 220 } }
                        Behavior on font.pixelSize { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Player.seekTo(lineItem.modelData.time)
                    }
                }
            }

            Flickable {
                anchors.fill: parent
                visible: view.plainReady
                clip: true
                contentWidth: width
                contentHeight: plainText.implicitHeight + 24
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: SlimScrollBar { indicatorColor: backend.lyricsTextColor }

                Text {
                    id: plainText
                    x: 6
                    y: 8
                    width: parent.width - 12
                    text: view.plainReady ? view.lyricsData.plain : ""
                    color: backend.lyricsTextColor
                    font.pixelSize: view.baseSize
                    horizontalAlignment: backend.lyricsAlign === "center" ? Text.AlignHCenter : Text.AlignLeft
                    lineHeight: 1.35
                    wrapMode: Text.Wrap
                }
            }

            Column {
                anchors.centerIn: parent
                width: Math.min(parent.width, 360)
                spacing: 12
                visible: !view.loading && !view.synced && !view.plainReady

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    path: view.hasTrack ? Icons.lyrics : Icons.music
                    size: 34
                    color: backend.lyricsTextColor
                    opacity: 0.55
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: !view.hasTrack ? Lang.t("Включите трек")
                          : (view.lyricsData.status === "error" ? Lang.t("Не удалось загрузить текст")
                                                     : Lang.t("Текст не найден"))
                    color: backend.lyricsTextColor
                    font.pixelSize: 16
                    font.bold: true
                    wrapMode: Text.Wrap
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: text !== ""
                    text: !view.hasTrack ? Lang.t("Строки песни появятся здесь.") : (view.lyricsData.message || "")
                    color: backend.lyricsTextColor
                    opacity: 0.7
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: view.hasTrack && view.lyricsData.status !== "error"
                    text: Lang.t("Можно положить .lrc-файл с тем же именем рядом с аудиофайлом.")
                    color: backend.lyricsTextColor
                    font.pixelSize: 12
                    opacity: 0.55
                    wrapMode: Text.Wrap
                }
                PillButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Lang.t("Попробовать снова")
                    outlined: true
                    visible: view.hasTrack && view.lyricsData.status === "error"
                    onActivated: if (Player.current) backend.loadLyrics(Player.current.id, true)
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                visible: view.loading
                running: view.loading
                width: 44
                height: 44
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: 30
                visible: view.loading
                text: Lang.t("Ищем текст…")
                color: backend.lyricsTextColor
                opacity: 0.65
                font.pixelSize: 13
            }
        }
    }
}
