import QtQuick
import QtQuick.Effects

// Обложка со скруглением: плавное появление картинки, запасной градиент с первой буквой.
Rectangle {
    id: cover
    property string path: ""
    property string label: ""

    radius: 16
    gradient: Gradient {
        GradientStop { position: 0.0; color: label ? Theme.genreColor(label) : Theme.accentContainer }
        GradientStop { position: 1.0; color: Theme.surfaceHi }
    }

    Text {
        anchors.centerIn: parent
        visible: cover.path === ""
        text: cover.label ? cover.label.charAt(0).toUpperCase() : "\u266a"
        color: Qt.rgba(1, 1, 1, 0.75)
        font.pixelSize: Math.max(12, cover.width * 0.4)
        font.bold: true
    }

    Image {
        id: img
        anchors.fill: parent
        source: cover.path ? (cover.path.indexOf("http") === 0 ? cover.path : backend.url(cover.path)) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 400
        visible: false
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: cover.radius
        layer.enabled: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: mask
        opacity: img.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 350 } }
    }
}
