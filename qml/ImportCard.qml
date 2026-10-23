import QtQuick
import QtQuick.Layouts

// Карточка способа импорта: поднимается при наведении, иконка слегка поворачивается.
Rectangle {
    id: card
    property string heading: ""
    property string details: ""
    property string actionText: ""
    property string actionIcon: ""
    property string icon: ""
    property bool actionEnabled: true
    property int order: 0
    default property alias extra: extraCol.data
    signal action()

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop
    implicitHeight: content.implicitHeight + 40
    radius: 28
    color: hv.containsMouse ? Theme.surfaceHi : Theme.surface
    Behavior on color { ColorAnimation { duration: 200 } }

    opacity: 0
    transform: Translate { id: tr; y: 24 }
    SequentialAnimation {
        running: true
        PauseAnimation { duration: card.order * 70 }
        ParallelAnimation {
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
            NumberAnimation { target: tr; property: "y"; to: 0; duration: 450; easing.type: Easing.OutCubic }
        }
    }

    HoverHandler { id: hv }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        RowLayout {
            spacing: 14
            Rectangle {
                width: 52
                height: 52
                radius: hv.hovered ? 16 : 26
                Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                color: Theme.accentContainer
                Icon {
                    anchors.centerIn: parent
                    path: card.icon
                    size: 26
                    color: Theme.accent
                    rotation: hv.hovered ? -10 : 0
                    Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                }
            }
            Text { text: card.heading; color: Theme.text; font.pixelSize: 20; font.bold: true; Layout.fillWidth: true }
        }

        Text {
            text: card.details
            color: Theme.textDim
            font.pixelSize: 13
            lineHeight: 1.15
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        ColumnLayout {
            id: extraCol
            Layout.fillWidth: true
            spacing: 10
        }

        PillButton {
            text: card.actionText
            icon: card.actionIcon
            enabledLook: card.actionEnabled
            Layout.alignment: Qt.AlignRight
            onActivated: card.action()
        }
    }
}
