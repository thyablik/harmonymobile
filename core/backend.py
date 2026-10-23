"""Мост между Python и QML."""
import re
import threading
from pathlib import Path
from urllib.parse import unquote

from PySide6.QtCore import Property, QFile, QObject, Qt, QUrl, Signal, Slot
from PySide6.QtGui import QColor, QDesktopServices, QImage

from . import downloader, importers, lyrics as lyrics_service
from . import i18n
from .library import Library
from .platform_info import is_mobile
from .settings import DEFAULTS, SettingsStore

# Куда копируются файлы, выбранные через системный диалог Android (адреса content://).
_import_dir = None


def set_import_dir(path):
    global _import_dir
    _import_dir = Path(path)
    _import_dir.mkdir(parents=True, exist_ok=True)


def _content_name(uri: str) -> str:
    name = unquote(uri.split("?")[0]).rstrip("/")
    name = re.split(r"[/:]", name)[-1].strip()
    return re.sub(r'[<>:"|?*\\]', "_", name) or "file"


def _materialize(uri: str) -> Path:
    """Android отдаёт выбранные файлы как content://. Копируем их во внутреннее хранилище приложения."""
    if _import_dir is None:
        raise OSError("import dir is not set")
    src = QFile(uri)
    if not src.exists():
        raise OSError(f"cannot open {uri}")
    size = src.size()
    name = _content_name(uri)
    dest = _import_dir / name
    counter = 1
    while dest.exists() and dest.stat().st_size != size:
        dest = _import_dir / f"{Path(name).stem}_{counter}{Path(name).suffix}"
        counter += 1
    if not dest.exists() and not QFile.copy(uri, str(dest)):
        raise OSError(f"cannot copy {uri}")
    return dest


def _path(value) -> Path:
    s = value.toString() if isinstance(value, QUrl) else str(value)
    if s.startswith("content:"):
        return _materialize(s)
    if s.startswith("file:"):
        return Path(QUrl(s).toLocalFile())
    return Path(s)


def _color_name(value, fallback):
    try:
        color = value if isinstance(value, QColor) else QColor(str(value))
    except Exception:
        return fallback
    return color.name() if color.isValid() else fallback


class Backend(QObject):
    libraryChanged = Signal()
    statusChanged = Signal()
    busyChanged = Signal()
    settingsChanged = Signal()
    searchResultsChanged = Signal()
    lyricsChanged = Signal()

    def __init__(self, data_dir: Path):
        super().__init__()
        self._lib = Library(data_dir)
        self._data_dir = Path(data_dir)
        self._dl_dir = self._data_dir / "downloads"
        set_import_dir(self._data_dir / "imported" / "files")
        self._settings = SettingsStore(data_dir)
        i18n.set_current(self.language)
        self._search_results = []
        self._status = ""
        self._busy = False
        self._lyrics_token = 0
        self._lyrics_memory = {}
        self._lyrics = {
            "trackId": "",
            "status": "idle",
            "synced": False,
            "lines": [],
            "plain": "",
            "source": "",
            "message": "",
        }

    # ---------- свойства для QML ----------
    @Property("QVariantList", notify=libraryChanged)
    def tracks(self):
        return sorted(self._lib.tracks, key=lambda t: t["added"], reverse=True)

    @Property("QVariantList", notify=libraryChanged)
    def playlists(self):
        out = []
        for p in self._lib.playlists:
            tracks = [t for t in self._lib.tracks if t["id"] in p["track_ids"]]
            cover = p.get("cover") or next(
                (t["cover"] for t in tracks if t.get("cover")), "")
            out.append({
                "id": p["id"],
                "name": p["name"],
                "count": len(tracks),
                "cover": cover,
            })
        return out

    @Property("QVariantList", notify=libraryChanged)
    def genres(self):
        counts = {}
        for t in self._lib.tracks:
            counts[t["genre"]] = counts.get(t["genre"], 0) + 1
        ordered = sorted(counts.items(), key=lambda x: -x[1])
        return [{"name": k, "count": v, "cover": self._genre_cover(k)} for k, v in ordered]

    def _genre_cover(self, genre):
        for t in self._lib.tracks:
            if t["genre"] == genre and t["cover"]:
                return t["cover"]
        return ""

    @Property(str, notify=statusChanged)
    def status(self):
        return self._status

    @Property(bool, notify=busyChanged)
    def busy(self):
        return self._busy

    @Property("QVariantList", notify=searchResultsChanged)
    def searchResults(self):
        return self._search_results

    @Property("QVariantMap", notify=lyricsChanged)
    def lyrics(self):
        return self._lyrics

    # ---------- настройки ----------
    @Property(str, notify=settingsChanged)
    def language(self):
        return i18n.normalize(self._settings.get("language"))

    @language.setter
    def language(self, value):
        lang = i18n.normalize(value)
        if lang == self.language:
            return
        i18n.set_current(lang)
        self._settings.set("language", lang)
        self._settings.save()
        self.settingsChanged.emit()

    @Slot(str, str, result=str)
    def translate(self, source, lang):
        return i18n.translate(source, lang or self.language)

    @Slot(str, result=str)
    def languageName(self, lang):
        return i18n.language_name(lang)

    def _t(self, source, **values):
        return i18n.translate(source).format(**values)

    @Property(bool, notify=settingsChanged)
    def deleteFiles(self):
        return bool(self._settings.get("delete_files"))

    @deleteFiles.setter
    def deleteFiles(self, value):
        self._settings.set("delete_files", bool(value))
        self._settings.save()
        self.settingsChanged.emit()

    @Property(bool, notify=settingsChanged)
    def downloadCovers(self):
        return bool(self._settings.get("download_covers"))

    @downloadCovers.setter
    def downloadCovers(self, value):
        self._settings.set("download_covers", bool(value))
        self._settings.save()
        self.settingsChanged.emit()

    @Property(bool, notify=settingsChanged)
    def dynamicTheme(self):
        return bool(self._settings.get("dynamic_theme"))

    @dynamicTheme.setter
    def dynamicTheme(self, value):
        self._settings.set("dynamic_theme", bool(value))
        self._settings.save()
        self.settingsChanged.emit()

    @Property(str, notify=settingsChanged)
    def downloadFormat(self):
        value = str(self._settings.get("download_format"))
        # Без ffmpeg конвертация в MP3 на телефоне невозможна.
        return "m4a" if is_mobile() and value == "mp3" else value

    @downloadFormat.setter
    def downloadFormat(self, value):
        if value in ("m4a", "mp3", "best"):
            self._settings.set("download_format", value)
            self._settings.save()
            self.settingsChanged.emit()

    @Property(str, notify=settingsChanged)
    def downloadDir(self):
        return str(self._settings.get("download_dir") or self._dl_dir)

    @downloadDir.setter
    def downloadDir(self, value):
        path = _path(value) if value else self._dl_dir
        try:
            path.mkdir(parents=True, exist_ok=True)
        except OSError:
            return
        self._settings.set("download_dir", str(path))
        self._settings.save()
        self.settingsChanged.emit()

    def _download_dir(self):
        path = self._settings.get("download_dir")
        return Path(path) if path else self._dl_dir

    # ---------- оформление текста ----------
    @Property(str, notify=settingsChanged)
    def lyricsTextColor(self):
        return str(self._settings.get("lyrics_text_color"))

    @lyricsTextColor.setter
    def lyricsTextColor(self, value):
        self._settings.set("lyrics_text_color", _color_name(value, DEFAULTS["lyrics_text_color"]))
        self._settings.save()
        self.settingsChanged.emit()

    @Property(str, notify=settingsChanged)
    def lyricsActiveColor(self):
        return str(self._settings.get("lyrics_active_color"))

    @lyricsActiveColor.setter
    def lyricsActiveColor(self, value):
        self._settings.set("lyrics_active_color", _color_name(value, DEFAULTS["lyrics_active_color"]))
        self._settings.save()
        self.settingsChanged.emit()

    @Property(str, notify=settingsChanged)
    def lyricsBgColor(self):
        return str(self._settings.get("lyrics_bg_color"))

    @lyricsBgColor.setter
    def lyricsBgColor(self, value):
        self._settings.set("lyrics_bg_color", _color_name(value, DEFAULTS["lyrics_bg_color"]))
        self._settings.save()
        self.settingsChanged.emit()

    @Property(int, notify=settingsChanged)
    def lyricsFontSize(self):
        try:
            return max(13, min(34, int(self._settings.get("lyrics_font_size"))))
        except (TypeError, ValueError):
            return int(DEFAULTS["lyrics_font_size"])

    @lyricsFontSize.setter
    def lyricsFontSize(self, value):
        try:
            value = max(13, min(34, int(value)))
        except (TypeError, ValueError):
            return
        self._settings.set("lyrics_font_size", value)
        self._settings.save()
        self.settingsChanged.emit()

    @Property(str, notify=settingsChanged)
    def lyricsAlign(self):
        value = str(self._settings.get("lyrics_align"))
        return value if value in ("left", "center") else "left"

    @lyricsAlign.setter
    def lyricsAlign(self, value):
        if value not in ("left", "center"):
            return
        self._settings.set("lyrics_align", value)
        self._settings.save()
        self.settingsChanged.emit()

    @Property(bool, notify=settingsChanged)
    def lyricsAutoScroll(self):
        return bool(self._settings.get("lyrics_auto_scroll"))

    @lyricsAutoScroll.setter
    def lyricsAutoScroll(self, value):
        self._settings.set("lyrics_auto_scroll", bool(value))
        self._settings.save()
        self.settingsChanged.emit()

    @Property(bool, notify=settingsChanged)
    def lyricsFullscreenDefault(self):
        return bool(self._settings.get("lyrics_fullscreen_default"))

    @lyricsFullscreenDefault.setter
    def lyricsFullscreenDefault(self, value):
        self._settings.set("lyrics_fullscreen_default", bool(value))
        self._settings.save()
        self.settingsChanged.emit()

    # ---------- служебные ----------
    def _set_status(self, text):
        self._status = text
        self.statusChanged.emit()

    def _set_busy(self, value):
        self._busy = value
        self.busyChanged.emit()

    def _run(self, job, refresh_library=True):
        def worker():
            self._set_busy(True)
            try:
                msg = job() or self._t("Готово")
                self._lib.save()
            except Exception as e:
                msg = self._t("Ошибка: {error}", error=str(e))
            self._set_status(msg)
            self._set_busy(False)
            if refresh_library:
                self.libraryChanged.emit()

        threading.Thread(target=worker, daemon=True).start()

    # ---------- импорт и загрузка ----------
    @Slot(str)
    def importTelegram(self, folder):
        self._run(lambda: importers.telegram(_path(folder), self._lib))

    @Slot(str, str)
    def importTracklist(self, file, name):
        p = _path(file)
        self._run(lambda: importers.tracklist(
            p, name or p.stem, self._lib, self._download_dir(), self._set_status,
            self._settings.get("download_covers"),
            self._settings.get("download_format"),
        ))

    @Slot(str)
    def downloadUrl(self, url):
        self._run(lambda: importers.from_url(
            url.strip(), self._download_dir(), self._lib, self._set_status,
            self._settings.get("download_covers"),
            self._settings.get("download_format"),
        ))

    @Slot(str, str, str, str)
    def downloadSearchResult(self, url, title, artist, thumbnail):
        self._run(lambda: importers.download_one(
            url, self._download_dir(), self._lib, self._set_status,
            title, artist, thumbnail,
            self._settings.get("download_covers"),
            self._settings.get("download_format"),
        ))

    @Slot(str)
    def searchTracks(self, query):
        query = (query or "").strip()
        if not query:
            return

        def job():
            self._search_results = []
            self.searchResultsChanged.emit()
            results = downloader.search(query)
            self._search_results = results
            self.searchResultsChanged.emit()
            return self._t("Найдено: {count}", count=len(results)) if results else self._t("Ничего не найдено")

        self._run(job, refresh_library=False)

    @Slot(list)
    def addLocalFiles(self, files):
        def job():
            new = 0
            for f in files:
                _, created = self._lib.add_file(_path(f), source="local")
                new += created
            return self._t("Добавлено треков: {count}", count=new)

        self._run(job)

    # ---------- плейлисты и лайки ----------
    @Slot(str, result=str)
    def createPlaylist(self, name):
        pid = self._lib.create_playlist(name)
        self._lib.save()
        self.libraryChanged.emit()
        return pid

    @Slot(str, str)
    def addToPlaylist(self, pid, tid):
        self._lib.add_to_playlist(pid, tid)
        self._lib.save()
        self.libraryChanged.emit()

    @Slot(str, str)
    def removeFromPlaylist(self, pid, tid):
        self._lib.remove_from_playlist(pid, tid)
        self._lib.save()
        self.libraryChanged.emit()

    @Slot(str, result="QVariantList")
    def playlistTracks(self, pid):
        p = next((p for p in self._lib.playlists if p["id"] == pid), None)
        if not p:
            return []
        return [t for tid in p["track_ids"] if (t := self._lib.get(tid))]

    @Slot(str)
    def toggleLike(self, tid):
        self._lib.toggle_like(tid)
        self._lib.save()
        self.libraryChanged.emit()

    # ---------- удаление ----------
    @Slot(str)
    def removeTrack(self, tid):
        delete_files = bool(self._settings.get("delete_files"))
        result = self._lib.remove_track(tid, delete_files)
        if not result:
            return
        if not result:
            return
        removed, file_deleted = result
        self._lib.save()
        self.libraryChanged.emit()
        suffix = ""
        if file_deleted:
            suffix = self._t(" вместе с файлом")
        elif delete_files:
            suffix = self._t(" (файл не удалось удалить)")
        self._set_status(self._t("Трек «{title}» удалён{suffix}", title=removed["title"], suffix=suffix))

    @Slot()
    def clearStatus(self):
        self._set_status("")

    # ---------- тексты песен ----------
    @Slot(str, bool)
    def loadLyrics(self, tid, force=False):
        track = self._lib.get(tid)
        if not track:
            self._lyrics_token += 1
            self._lyrics = {
                "trackId": "",
                "status": "idle",
                "synced": False,
                "lines": [],
                "plain": "",
                "source": "",
                "message": "",
            }
            self.lyricsChanged.emit()
            return

        if not force and tid in self._lyrics_memory:
            self._lyrics_token += 1
            self._lyrics = self._lyrics_memory[tid]
            self.lyricsChanged.emit()
            return

        if not force and self._lyrics.get("trackId") == tid and self._lyrics.get("status") == "loading":
            return

        self._lyrics_token += 1
        token = self._lyrics_token
        self._lyrics = {
            "trackId": tid,
            "status": "loading",
            "synced": False,
            "lines": [],
            "plain": "",
            "source": "",
            "message": "",
        }
        self.lyricsChanged.emit()

        def worker():
            try:
                state = lyrics_service.fetch(track, self._data_dir / "lyrics", force)
            except Exception as error:
                state = {
                    "trackId": tid,
                    "status": "error",
                    "synced": False,
                    "lines": [],
                    "plain": "",
                    "source": "",
                    "message": self._t("Ошибка загрузки текста: {error}", error=str(error)),
                }
            if token != self._lyrics_token:
                return
            if state.get("status") == "ready":
                self._lyrics_memory[tid] = state
            self._lyrics = state
            self.lyricsChanged.emit()

        threading.Thread(target=worker, daemon=True).start()

    # ---------- утилиты для интерфейса ----------
    @Slot(str, result=str)
    def url(self, path):
        return QUrl.fromLocalFile(path).toString() if path else ""

    @Slot()
    def openDataFolder(self):
        QDesktopServices.openUrl(QUrl.fromLocalFile(str(self._data_dir)))

    @Slot()
    def openDownloadFolder(self):
        QDesktopServices.openUrl(QUrl.fromLocalFile(str(self._download_dir())))

    @Slot()
    def resetSettings(self):
        self._settings.data = dict(DEFAULTS)
        self._settings.save()
        self.settingsChanged.emit()

    @Slot()
    def resetLyricsSettings(self):
        for key in (
            "lyrics_text_color",
            "lyrics_active_color",
            "lyrics_bg_color",
            "lyrics_font_size",
            "lyrics_align",
            "lyrics_auto_scroll",
            "lyrics_fullscreen_default",
        ):
            self._settings.set(key, DEFAULTS[key])
        self._settings.save()
        self.settingsChanged.emit()
        self._set_status(self._t("Оформление текста сброшено"))

    @Slot(result="QVariantMap")
    def libraryStats(self):
        total = 0
        for t in self._lib.tracks:
            try:
                total += Path(t["path"]).stat().st_size
            except OSError:
                pass
        return {
            "tracks": len(self._lib.tracks),
            "playlists": len(self._lib.playlists),
            "bytes": total,
        }

    @Slot(str, result=str)
    def dominantColor(self, path):
        """Цвет акцента берётся из обложки и делается пригодным для тёмной темы."""
        if not path:
            return "#8AB4F8"
        img = QImage(path)
        if img.isNull():
            return "#8AB4F8"
        px = img.scaled(1, 1, Qt.AspectRatioMode.IgnoreAspectRatio,
                        Qt.TransformationMode.SmoothTransformation).pixelColor(0, 0)
        hue = max(px.hsvHue(), 0)
        sat = max(px.hsvSaturation(), 110)
        val = max(px.value(), 175)
        return QColor.fromHsv(hue, sat, val).name()
