import QtQuick
import QtQuick.Layouts

Item {
    id: page
    property bool compact: false
    signal closeRequested()
    signal panelRequested()

    Rectangle {
        anchors.fill: parent
        color: backend.lyricsBgColor
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.16) }
            GradientStop { position: 0.4; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.30) }
        }
    }

    MouseArea { anchors.fill: parent }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: page.compact ? 14 : 28
        anchors.topMargin: (page.compact ? 14 : 28) + platform.insetTop
        anchors.bottomMargin: (page.compact ? 14 : 28) + platform.insetBottom
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            IconButton {
                icon: Icons.chevronLeft
                color: backend.lyricsTextColor
                iconSize: 26
                onClicked: page.closeRequested()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: Player.current ? Player.current.title : Lang.t("Текст песни")
                    color: backend.lyricsTextColor
                    font.pixelSize: page.compact ? 16 : 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: Player.current ? Player.current.artist : ""
                    color: backend.lyricsTextColor
                    opacity: 0.6
                    font.pixelSize: page.compact ? 11 : 13
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            IconButton {
                icon: Icons.fullscreenExit
                color: backend.lyricsTextColor
                iconSize: 22
                onClicked: page.panelRequested()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            LyricsView {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(parent.width, page.compact ? parent.width : 1100)
                height: parent.height
                compact: page.compact
                fullscreen: true
            }
        }

        BottomBar {
            Layout.fillWidth: true
            compact: page.compact
            showExpand: false
            barColor: Qt.rgba(0, 0, 0, 0.38)
        }
    }
}
