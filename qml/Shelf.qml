import QtQuick
import QtQuick.Layouts

// Горизонтальная полка со стрелками и плавной прокруткой.
ColumnLayout {
    id: shelf
    property string title: ""
    property alias model: lv.model
    property Component delegate
    property real itemHeight: 230

    spacing: 10

    function scroll(dir) {
        var target = Math.max(0, Math.min(lv.contentWidth - lv.width, lv.contentX + dir * lv.width * 0.8))
        sa.from = lv.contentX
        sa.to = target
        sa.restart()
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: shelf.title
            color: Theme.text
            font.pixelSize: 22
            font.bold: true
            Layout.fillWidth: true
        }
        IconButton { visible: !platform.isMobile; icon: Icons.chevronLeft; implicitWidth: 38; implicitHeight: 38; onClicked: shelf.scroll(-1) }
        IconButton { visible: !platform.isMobile; icon: Icons.chevronRight; implicitWidth: 38; implicitHeight: 38; onClicked: shelf.scroll(1) }
    }

    ListView {
        id: lv
        Layout.fillWidth: true
        Layout.preferredHeight: shelf.itemHeight
        orientation: ListView.Horizontal
        spacing: 18
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        delegate: shelf.delegate

        NumberAnimation { id: sa; target: lv; property: "contentX"; duration: 380; easing.type: Easing.OutCubic }
    }
}
