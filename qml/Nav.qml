pragma Singleton
import QtQuick

// Навигация по страницам приложения.
QtObject {
    readonly property int pageHome: 0
    readonly property int pageLibrary: 1
    readonly property int pageDownloads: 2
    readonly property int pageImport: 3
    readonly property int pagePlaylist: 4
    readonly property int pageSettings: 5

    property int page: pageHome
    property var playlist: null

    signal deleteRequested(var track)

    function go(i) { page = i }
    function openPlaylist(p) { playlist = p; page = pagePlaylist }
    function askDelete(track) { if (track) deleteRequested(track) }
}
