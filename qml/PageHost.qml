import QtQuick

// Контейнер страницы: плавное появление/скрытие со сдвигом при переключении.
Item {
    id: host
    property int index: 0
    default property alias content: inner.data
    readonly property bool shown: Nav.page === index

    anchors.fill: parent
    opacity: shown ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    Item {
        id: inner
        width: parent.width
        height: parent.height
        y: host.shown ? 0 : 24
        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    }
}
