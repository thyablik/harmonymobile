import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: dlg
    property string heading: ""
    property string message: ""
    property string confirmText: Lang.t("Подтвердить")
    property bool danger: false
    signal confirmed()

    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    modal: true
    focus: true
    width: Math.min(420, Overlay.overlay ? Overlay.overlay.width - 32 : 420)
    padding: 24
    closePolicy: Popup.CloseOnEscape

    Overlay.modal: Rectangle { color: "#99000000" }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 260; easing.type: Easing.OutBack }
        }
    }
    exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 120 } }

    background: Rectangle { color: Theme.surfaceHi; radius: 28 }

    ColumnLayout {
        width: parent.width
        spacing: 16

        RowLayout {
            spacing: 14
            Rectangle {
                width: 48
                height: 48
                radius: 24
                color: dlg.danger ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16)
                                  : Theme.accentContainer
                Icon {
                    anchors.centerIn: parent
                    path: dlg.danger ? Icons.warning : Icons.check
                    size: 24
                    color: dlg.danger ? Theme.error : Theme.accent
                }
            }
            Text {
                text: dlg.heading
                color: Theme.text
                font.pixelSize: 20
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Text {
            text: dlg.message
            color: Theme.textDim
            font.pixelSize: 14
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10
            PillButton {
                text: Lang.t("Отмена")
                outlined: true
                onActivated: dlg.close()
            }
            PillButton {
                text: dlg.confirmText
                onActivated: {
                    dlg.confirmed()
                    dlg.close()
                }
            }
        }
    }
}
