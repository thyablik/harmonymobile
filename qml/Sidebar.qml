import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: side
    color: Theme.surface

    readonly property var items: [
        { name: Lang.t("Главная"), icon: Icons.home, page: Nav.pageHome },
        { name: Lang.t("Библиотека"), icon: Icons.library, page: Nav.pageLibrary },
        { name: Lang.t("Загрузки"), icon: Icons.download, page: Nav.pageDownloads },
        { name: Lang.t("Импорт"), icon: Icons.upload, page: Nav.pageImport },
        { name: Lang.t("Настройки"), icon: Icons.settings, page: Nav.pageSettings }
    ]

    readonly property int selectedIndex: {
        for (var i = 0; i < items.length; ++i)
            if (items[i].page === Nav.page)
                return i
        return -1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            spacing: 12
            Layout.bottomMargin: 14
            Rectangle {
                width: 42
                height: 42
                radius: 14
                color: Theme.accentContainer
                Icon { anchors.centerIn: parent; path: Icons.music; size: 24; color: Theme.accent }
            }
            Text { text: "Harmony"; color: Theme.text; font.pixelSize: 22; font.bold: true }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: side.items.length * 52

            Rectangle {
                width: parent.width
                height: 48
                radius: 24
                color: Theme.accentContainer
                y: Math.max(0, side.selectedIndex) * 52
                opacity: side.selectedIndex >= 0 ? 1 : 0
                Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            Column {
                width: parent.width
                spacing: 4
                Repeater {
                    model: side.items
                    Item {
                        width: parent.width
                        height: 48
                        readonly property bool selected: Nav.page === modelData.page

                        Rectangle {
                            anchors.fill: parent
                            radius: 24
                            color: Theme.surfaceHi
                            opacity: !parent.selected && nav.containsMouse ? 0.8 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 18
                            spacing: 14
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                path: modelData.icon
                                size: 24
                                color: parent.parent.selected ? Theme.accent : Theme.textDim
                                scale: nav.containsMouse ? 1.12 : 1
                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                font.pixelSize: 15
                                font.bold: parent.parent.selected
                                color: parent.parent.selected ? Theme.text : Theme.textDim
                            }
                        }
                        MouseArea {
                            id: nav
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Nav.go(modelData.page)
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceHi; Layout.topMargin: 6 }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: Lang.t("Плейлисты")
                color: Theme.textDim
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
                leftPadding: 6
            }
            IconButton {
                icon: Icons.add
                iconSize: 22
                implicitWidth: 36
                implicitHeight: 36
                onClicked: { createName.text = ""; createPop.open() }
            }
        }

        ListView {
            id: plList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: backend.playlists
            boundsBehavior: Flickable.StopAtBounds

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 }
            }

            delegate: Rectangle {
                width: plList.width
                height: 52
                radius: 16
                readonly property bool selected: Nav.page === Nav.pagePlaylist && Nav.playlist !== null && Nav.playlist.id === modelData.id
                color: selected ? Theme.accentContainer : (pm.containsMouse ? Theme.surfaceHi : "transparent")
                Behavior on color { ColorAnimation { duration: 160 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 12
                    Cover {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 10
                        path: modelData.cover
                        label: modelData.name
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { text: modelData.name; color: Theme.text; font.pixelSize: 14; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: modelData.count + Lang.t(" треков"); color: Theme.textDim; font.pixelSize: 11 }
                    }
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
    }

    Popup {
        id: createPop
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        modal: true
        width: 340
        padding: 20
        background: Rectangle { color: Theme.surfaceHi; radius: 28 }
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
                NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 260; easing.type: Easing.OutBack }
            }
        }
        exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 120 } }

        function submit() {
            var n = createName.text.trim()
            if (n) { backend.createPlaylist(n); createPop.close() }
        }

        ColumnLayout {
            width: parent.width
            spacing: 14
            Text { text: Lang.t("Новый плейлист"); color: Theme.text; font.pixelSize: 20; font.bold: true }
            TextField {
                id: createName
                Layout.fillWidth: true
                placeholderText: Lang.t("Название")
                color: Theme.text
                placeholderTextColor: Theme.textDim
                leftPadding: 16
                implicitHeight: 48
                background: Rectangle {
                    radius: 16
                    color: Theme.surface
                    border.width: 2
                    border.color: createName.activeFocus ? Theme.accent : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
                onAccepted: createPop.submit()
            }
            PillButton {
                text: Lang.t("Создать")
                icon: Icons.add
                Layout.alignment: Qt.AlignRight
                onActivated: createPop.submit()
            }
        }
        onOpened: createName.forceActiveFocus()
    }
}
