pragma Singleton
import QtQuick

// Material 3-подобная тёмная схема. Акцент плавно меняется по обложке трека.
QtObject {
    property color accent: "#8AB4F8"
    Behavior on accent { ColorAnimation { duration: 700; easing.type: Easing.OutCubic } }

    readonly property color onAccent: (accent.r * 0.3 + accent.g * 0.59 + accent.b * 0.11) > 0.55 ? "#101418" : "#FFFFFF"
    readonly property color accentContainer: Qt.rgba(accent.r * 0.30 + 0.03, accent.g * 0.30 + 0.03, accent.b * 0.30 + 0.04, 1)
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.14)

    readonly property color bg: "#0E1115"
    readonly property color surface: "#161A20"
    readonly property color surfaceHi: "#222830"
    readonly property color text: "#E6EAF0"
    readonly property color textDim: "#9AA4B2"
    readonly property color error: "#F28B82"

    function setAccent(hex) { accent = hex }

    function genreColor(name) {
        var h = 0
        for (var i = 0; i < name.length; i++)
            h = (h * 31 + name.charCodeAt(i)) % 360
        return Qt.hsla(h / 360, 0.5, 0.33, 1)
    }
}
