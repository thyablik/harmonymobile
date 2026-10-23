"""Загрузка аудио по ссылке или поисковому запросу через yt-dlp."""
import re
from pathlib import Path

import yt_dlp

from . import i18n

AUDIO_EXT = (".m4a", ".mp3", ".opus", ".webm", ".ogg", ".wav", ".aac", ".flac")
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


def _format_selector(audio_format: str) -> str:
    if audio_format == "mp3":
        return "bestaudio/best"
    if audio_format == "best":
        return "bestaudio/best"
    return "bestaudio[ext=m4a]/bestaudio/best"


def _postprocessors(audio_format: str):
    if audio_format == "mp3":
        return [{
            "key": "FFmpegExtractAudio",
            "preferredcodec": "mp3",
            "preferredquality": "192",
        }]
    return []


def _options(out_dir: Path, status_cb, audio_format="m4a"):
    def hook(d):
        if not status_cb:
            return
        if d.get("status") == "downloading":
            percent = ANSI_RE.sub("", str(d.get("_percent_str", ""))).strip()
            status_cb(i18n.tr("Загрузка {percent}", percent=percent).strip())
        elif d.get("status") == "finished":
            status_cb(i18n.tr("Обработка файла…"))

    opts = {
        "format": _format_selector(audio_format),
        "outtmpl": str(out_dir / "%(title)s [%(id)s].%(ext)s"),
        "quiet": True,
        "no_warnings": True,
        "noprogress": True,
        "color": "no_color",
        "noplaylist": False,
        "ignoreerrors": True,
        "windowsfilenames": True,
        "socket_timeout": 30,
        "retries": 2,
        "progress_hooks": [hook],
    }
    postprocessors = _postprocessors(audio_format)
    if postprocessors:
        opts["postprocessors"] = postprocessors
    return opts


def _entries(info):
    if not info:
        return []
    return [e for e in (info.get("entries") or [info]) if e]


def _thumbnail(entry):
    thumb = entry.get("thumbnail")
    if thumb:
        return thumb
    thumbs = entry.get("thumbnails") or []
    for item in reversed(thumbs):
        if item and item.get("url"):
            return item["url"]
    vid = entry.get("id")
    if vid and entry.get("extractor", "").lower().startswith("youtube"):
        return f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg"
    return ""


def _resolve_path(entry, ydl):
    for download in entry.get("requested_downloads") or []:
        filepath = download.get("filepath")
        if filepath and Path(filepath).exists():
            return Path(filepath)
    prepared = Path(ydl.prepare_filename(entry))
    if prepared.exists():
        return prepared
    for ext in AUDIO_EXT:
        candidate = prepared.with_suffix(ext)
        if candidate.exists():
            return candidate
    return prepared


def search(query: str, limit=6):
    """Быстрый поиск без скачивания: список треков с обложками."""
    opts = {
        "quiet": True,
        "no_warnings": True,
        "noprogress": True,
        "color": "no_color",
        "noplaylist": True,
        "extract_flat": "in_playlist",
        "skip_download": True,
        "socket_timeout": 30,
    }
    with yt_dlp.YoutubeDL(opts) as ydl:
        info = ydl.extract_info(f"ytsearch{limit}:{query}", download=False)

    results = []
    for entry in _entries(info):
        url = entry.get("webpage_url") or entry.get("url") or ""
        if not url and entry.get("id"):
            url = f"https://www.youtube.com/watch?v={entry['id']}"
        if not url:
            continue
        thumb = _thumbnail(entry)
        if not thumb and entry.get("id"):
            thumb = f"https://i.ytimg.com/vi/{entry['id']}/hqdefault.jpg"
        results.append({
            "title": entry.get("track") or entry.get("title") or i18n.tr("Без названия"),
            "artist": entry.get("artist") or entry.get("uploader") or entry.get("channel") or "",
            "duration": int(entry.get("duration") or 0),
            "thumbnail": thumb,
            "url": url,
        })
    return results


def fetch_tracks(query_or_url: str, out_dir, status_cb=None, audio_format="m4a"):
    """Скачивает трек/альбом/плейлист и возвращает метаданные и пути к файлам."""
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    entries = []
    with yt_dlp.YoutubeDL(_options(out_dir, status_cb, audio_format)) as ydl:
        info = ydl.extract_info(query_or_url, download=True)
        if not info:
            return entries
        playlist_title = info.get("title") if info.get("entries") else ""
        playlist_thumb = _thumbnail(info) if info.get("entries") else ""
        for entry in _entries(info):
            path = _resolve_path(entry, ydl)
            if not path.exists():
                continue
            entries.append({
                "path": str(path),
                "title": entry.get("track") or entry.get("title") or path.stem,
                "artist": entry.get("artist") or entry.get("creator")
                          or entry.get("uploader") or entry.get("channel") or "",
                "album": entry.get("album") or playlist_title or "",
                "duration": int(entry.get("duration") or 0),
                "thumbnail": _thumbnail(entry),
                "playlist_title": playlist_title,
                "playlist_thumbnail": playlist_thumb,
            })
    return entries


def fetch(query_or_url: str, out_dir, status_cb=None, audio_format="m4a"):
    """Совместимость: только пути к скачанным файлам."""
    return [Path(e["path"]) for e in
            fetch_tracks(query_or_url, out_dir, status_cb, audio_format)]
