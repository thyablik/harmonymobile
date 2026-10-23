pragma Singleton
import QtQuick
import QtMultimedia

// Общее состояние плеера для всего интерфейса.
QtObject {
    id: root

    property var current: null
    property var queue: []
    property int index: -1
    property bool fullOpen: false
    property bool lyricsOpen: false
    property bool lyricsFull: false
    property bool shuffle: false
    property bool repeat: false
    property real volume: 0.8
    property real lastVolume: 0.8

    readonly property bool playing: mp.playbackState === MediaPlayer.PlayingState
    readonly property real position: mp.position
    readonly property real duration: mp.duration

    signal pickRequested(var track)

    property AudioOutput out: AudioOutput { volume: root.volume }

    property MediaPlayer mp: MediaPlayer {
        audioOutput: root.out
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia)
                root.next()
        }
    }

    function play(track, q) {
        queue = (q && q.length) ? q : [track]
        index = Math.max(0, queue.findIndex(t => t.id === track.id))
        current = queue[index]
        mp.source = backend.url(current.path)
        mp.play()
        if (backend.dynamicTheme)
            Theme.setAccent(current.cover ? backend.dominantColor(current.cover) : "#8AB4F8")
    }

    function playAll(list, shuf) {
        if (!list || !list.length)
            return
        var l = list.slice()
        if (shuf) {
            for (var i = l.length - 1; i > 0; i--) {
                var j = Math.floor(Math.random() * (i + 1))
                var t = l[i]; l[i] = l[j]; l[j] = t
            }
        }
        play(l[0], l)
    }

    function toggle() {
        if (!current)
            return
        if (playing)
            mp.pause()
        else
            mp.play()
    }

    function next() {
        if (queue.length === 0)
            return
        if (shuffle && queue.length > 1) {
            var n = index
            while (n === index)
                n = Math.floor(Math.random() * queue.length)
            play(queue[n], queue)
        } else if (index + 1 < queue.length) {
            play(queue[index + 1], queue)
        } else if (repeat) {
            play(queue[0], queue)
        } else {
            mp.stop()
        }
    }

    function prev() {
        if (mp.position > 3000 || index <= 0)
            mp.position = 0
        else
            play(queue[index - 1], queue)
    }

    function seek(fraction) {
        mp.position = Math.round(fraction * mp.duration)
    }

    function seekTo(seconds) {
        if (!current || !isFinite(seconds))
            return
        mp.position = Math.max(0, Math.round(seconds * 1000))
    }

    function toggleMute() {
        if (volume > 0) { lastVolume = volume; volume = 0 }
        else volume = lastVolume > 0 ? lastVolume : 0.8
    }

    function toggleLike() {
        if (!current)
            return
        backend.toggleLike(current.id)
        var c = Object.assign({}, current)
        c.liked = !c.liked
        current = c
    }

    function clear() {
        mp.stop()
        mp.source = ""
        current = null
        queue = []
        index = -1
        lyricsOpen = false
        lyricsFull = false
    }

    function removeTrack(tid) {
        var wasCurrent = current !== null && current.id === tid
        queue = queue.filter(t => t.id !== tid)
        if (wasCurrent) {
            if (queue.length > 0) {
                var n = Math.max(0, Math.min(index, queue.length - 1))
                play(queue[n], queue)
            } else {
                clear()
            }
        } else if (current) {
            index = queue.findIndex(t => t.id === current.id)
        }
    }

    function fmt(ms) {
        var s = Math.floor((ms || 0) / 1000)
        return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2)
    }
}
