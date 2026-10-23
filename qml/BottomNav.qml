import QtQuick

// Нижняя навигация для узкого окна: пилюля-индикатор плавно переезжает между пунктами.
Rectangle {
    id: bar
    height: 68
    color: Theme.surface

    readonly property var items: [
        { name: Lang.t("Главная"), icon: Icons.home, page: Nav.pageHome },
        { name: Lang.t("Библиотека"), icon: Icons.library, page: Nav.pageLibrary },
        { name: Lang.t("Загрузки"), icon: Icons.download, page: Nav.pageDownloads },
        { name: Lang.t("Импорт"), icon: Icons.upload, page: Nav.pageImport },
        { name: Lang.t("Настройки"), icon: Icons.settings, page: Nav.pageSettings }
    ]
    readonly property real cell: width / items.length
    readonly property int selectedIndex: {
        for (var i = 0; i < items.length; ++i)
            if (items[i].page === Nav.page)
                return i
        return -1
    }

    Rectangle {
        width: 64
        height: 32
        radius: 16
        y: 10
        color: Theme.accentContainer
        x: (Math.max(0, bar.selectedIndex) + 0.5) * bar.cell - width / 2
        opacity: bar.selectedIndex >= 0 ? 1 : 0
        Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Repeater {
        model: bar.items
        Item {
            x: index * bar.cell
            width: bar.cell
            height: bar.height
            readonly property bool selected: Nav.page === modelData.page

            Icon {
                x: (parent.width - width) / 2
                y: 15
                size: 22
                path: modelData.icon
                color: parent.selected ? Theme.accent : Theme.textDim
                scale: parent.selected ? 1.1 : 1
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
            }
            Text {
                x: (parent.width - width) / 2
                y: 44
                text: modelData.name
                font.pixelSize: 11
                color: parent.selected ? Theme.text : Theme.textDim
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Nav.go(modelData.page)
            }
        }
    }
}
