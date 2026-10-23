"""Локальная библиотека: треки, обложки, жанры и плейлисты (хранятся в JSON)."""
import json
import time
import uuid
from pathlib import Path

from mutagen import File as MFile

from . import i18n

DEFAULT_GENRE = "Other"
AUDIO_EXT = {".mp3", ".m4a", ".mp4", ".flac", ".ogg", ".opus", ".wav", ".aac", ".webm"}


def read_meta(path: Path) -> dict:
    meta = {"title": path.stem, "artist": "Unknown artist", "album": "",
            "genre": DEFAULT_GENRE, "duration": 0}
    try:
        f = MFile(str(path), easy=True)
        if f is None:
            return meta
        info = getattr(f, "info", None)
        if info is not None:
            meta["duration"] = int(getattr(info, "length", 0) or 0)
        tags = f.tags or {}

        def first(key):
            v = tags.get(key)
            return str(v[0]) if v else None

        meta["title"] = first("title") or meta["title"]
        meta["artist"] = first("artist") or meta["artist"]
        meta["album"] = first("album") or ""
        meta["genre"] = first("genre") or DEFAULT_GENRE
    except Exception:
        pass
    return meta


def extract_cover(path: Path, out: Path):
    """Достаёт встроенную обложку (ID3 APIC / MP4 covr / FLAC picture)."""
    try:
        f = MFile(str(path))
        if f is None:
            return None
        data = None
        pictures = getattr(f, "pictures", None)
        if pictures:
            data = pictures[0].data
        elif f.tags:
            for key in f.tags.keys():
                if str(key).startswith("APIC"):
                    data = f.tags[key].data
                    break
            if data is None and "covr" in f.tags:
                data = bytes(f.tags["covr"][0])
        if data:
            out.write_bytes(data)
            return out
    except Exception:
        pass
    return None


class Library:
    def __init__(self, data_dir: Path):
        self.dir = Path(data_dir)
        self.dir.mkdir(parents=True, exist_ok=True)
        self.covers = self.dir / "covers"
        self.covers.mkdir(exist_ok=True)
        self.db = self.dir / "library.json"
        self.tracks = []
        self.playlists = []
        if self.db.exists():
            d = json.loads(self.db.read_text(encoding="utf-8"))
            self.tracks = d.get("tracks", [])
            self.playlists = d.get("playlists", [])

    def save(self):
        payload = {"tracks": self.tracks, "playlists": self.playlists}
        self.db.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    def get(self, tid):
        return next((t for t in self.tracks if t["id"] == tid), None)

    def by_path(self, path):
        return next((t for t in self.tracks if t["path"] == str(path)), None)

    def add_file(self, path, source="local"):
        """Возвращает (track, created). Уже известные файлы не дублируются."""
        path = Path(path)
        existing = self.by_path(path)
        if existing:
            return existing, False
        meta = read_meta(path)
        tid = uuid.uuid4().hex[:12]
        cover = extract_cover(path, self.covers / f"{tid}.jpg")
        track = {
            "id": tid,
            "path": str(path),
            "title": meta["title"],
            "artist": meta["artist"],
            "album": meta["album"],
            "genre": meta["genre"],
            "duration": meta["duration"],
            "cover": str(cover) if cover else "",
            "source": source,
            "added": time.time(),
            "liked": False,
        }
        self.tracks.append(track)
        return track, True

    def toggle_like(self, tid):
        t = self.get(tid)
        if t:
            t["liked"] = not t["liked"]

    def create_playlist(self, name):
        pid = uuid.uuid4().hex[:8]
        self.playlists.append({"id": pid, "name": name or i18n.tr("Плейлист"), "track_ids": [], "cover": ""})
        return pid

    def get_playlist(self, pid):
        return next((p for p in self.playlists if p["id"] == pid), None)

    def add_to_playlist(self, pid, tid):
        p = self.get_playlist(pid)
        if not p or tid in p["track_ids"]:
            return
        p["track_ids"].append(tid)
        if not p.get("cover"):
            t = self.get(tid)
            if t and t.get("cover"):
                p["cover"] = t["cover"]

    def remove_from_playlist(self, pid, tid):
        p = self.get_playlist(pid)
        if p and tid in p["track_ids"]:
            p["track_ids"].remove(tid)

    def remove_track(self, tid, delete_file=False):
        """Убирает трек из библиотеки и плейлистов. Возвращает (трек, файл удалён)."""
        track = self.get(tid)
        if not track:
            return None
        self.tracks.remove(track)
        for p in self.playlists:
            if tid in p["track_ids"]:
                p["track_ids"].remove(tid)
        file_deleted = False
        if delete_file:
            for attempt in range(3):
                try:
                    Path(track["path"]).unlink(missing_ok=True)
                    file_deleted = True
                    break
                except OSError:
                    if attempt == 2:
                        break
                    time.sleep(0.12)
        self._cleanup_cover(track.get("cover", ""))
        return track, file_deleted

    def _cleanup_cover(self, cover):
        if not cover:
            return
        used = any(t.get("cover") == cover for t in self.tracks)
        used = used or any(p.get("cover") == cover for p in self.playlists)
        if not used:
            try:
                Path(cover).unlink(missing_ok=True)
            except OSError:
                pass
