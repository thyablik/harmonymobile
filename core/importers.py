"""Импорт музыки: экспорт Telegram, CSV/TXT плейлисты, ссылки."""
import csv
import json
import shutil
import urllib.request
import zipfile
from pathlib import Path

from . import downloader
from . import i18n

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Harmony/1.0"


def _image_ext(data: bytes) -> str:
    if data.startswith(b"\xff\xd8\xff"):
        return ".jpg"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return ".png"
    if data.startswith(b"GIF8"):
        return ".gif"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return ".webp"
    return ""


def _download_image(url: str, lib, name: str) -> str:
    if not url:
        return ""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=25) as resp:
            data = resp.read(10 * 1024 * 1024)
        ext = _image_ext(data)
        if not data or not ext:
            return ""
        dest = lib.covers / (Path(name).stem + ext)
        dest.write_bytes(data)
        return str(dest)
    except Exception:
        return ""


def _set_cover(track, url: str, lib, force=False) -> bool:
    """Скачивает обложку по ссылке и привязывает её к треку."""
    if not url or (track.get("cover") and not force):
        return False
    path = _download_image(url, lib, f"{track['id']}.jpg")
    if not path:
        return False
    track["cover"] = path
    return True


def _apply_metadata(track, entry):
    if entry.get("title"):
        track["title"] = entry["title"]
    if entry.get("artist") and track.get("artist") in ("", "Unknown artist"):
        track["artist"] = entry["artist"]
    if entry.get("album") and not track.get("album"):
        track["album"] = entry["album"]
    if entry.get("duration") and not track.get("duration"):
        track["duration"] = entry["duration"]


def telegram(folder, lib):
    """Экспорт Telegram Desktop: папка с result.json, сам result.json или ZIP-архив такой папки."""
    folder = Path(folder)
    extracted = None
    if folder.suffix.lower() == ".zip":
        extracted = lib.dir / "imported" / "_telegram_zip"
        shutil.rmtree(extracted, ignore_errors=True)
        with zipfile.ZipFile(folder) as archive:
            archive.extractall(extracted)  # zipfile сам отбрасывает «..» и абсолютные пути
        result = next(extracted.rglob("result.json"), None)
        if result is None:
            shutil.rmtree(extracted, ignore_errors=True)
            raise FileNotFoundError("result.json")
        folder = result.parent
    elif folder.is_file():
        folder = folder.parent
    try:
        return _telegram_folder(folder, lib)
    finally:
        if extracted is not None:
            shutil.rmtree(extracted, ignore_errors=True)


def _telegram_folder(folder, lib):
    data = json.loads((folder / "result.json").read_text(encoding="utf-8"))
    dest = lib.dir / "imported" / "telegram"
    dest.mkdir(parents=True, exist_ok=True)

    added = 0
    for m in data.get("messages", []):
        if m.get("media_type") not in ("audio_file", "voice_message"):
            continue
        rel = m.get("file")
        if not isinstance(rel, str):
            continue
        src = folder / rel
        if not src.is_file():
            continue
        dst = dest / src.name
        if not dst.exists():
            shutil.copy2(src, dst)
        track, created = lib.add_file(dst, source="telegram")
        if m.get("performer"):
            track["artist"] = m["performer"]
        if m.get("title"):
            track["title"] = m["title"]
        if created:
            added += 1
    lib.save()
    return i18n.tr("Из Telegram добавлено: {count}", count=added)


def _row_get(row, *names):
    keys = {str(k).strip().lower(): v for k, v in row.items() if k}
    for name in names:
        value = keys.get(name.lower())
        if value:
            return str(value).strip()
    return ""


def read_rows(path: Path):
    """CSV (Exportify/Spotify и похожие) или TXT со строками «Исполнитель - Название»."""
    rows = []
    if path.suffix.lower() == ".csv":
        with path.open(encoding="utf-8-sig", newline="") as f:
            for r in csv.DictReader(f):
                title = _row_get(r, "Track Name", "Title", "title", "Название")
                artist = _row_get(r, "Artist Name(s)", "Artist Name", "Artist",
                                  "Исполнитель")
                artist = artist.split(",")[0].strip()
                if title:
                    rows.append({
                        "title": title,
                        "artist": artist,
                        "album": _row_get(r, "Album Name", "Album", "Альбом"),
                        "genre": _row_get(r, "Genres", "Genre", "Жанр").split(",")[0].strip(),
                        "cover_url": _row_get(
                            r, "Album Image URL", "Track Image URL", "Image URL",
                            "Cover URL", "Cover", "Artwork URL", "Album Cover URL",
                        ),
                    })
        return rows

    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        artist, sep, title = line.partition(" - ")
        if sep:
            rows.append({"title": title.strip(), "artist": artist.strip(),
                         "album": "", "genre": "", "cover_url": ""})
        else:
            rows.append({"title": line, "artist": "", "album": "",
                         "genre": "", "cover_url": ""})
    return rows


def tracklist(path, name, lib, dl_dir, status, download_covers=True, audio_format="m4a"):
    """Создаёт плейлист и ищет/скачивает каждый трек через yt-dlp."""
    rows = read_rows(Path(path))
    if not rows:
        return i18n.tr("В файле не найдено треков")
    pid = lib.create_playlist(name)
    p = lib.get_playlist(pid)
    ok = 0
    for i, r in enumerate(rows, 1):
        label = f"{r['artist']} — {r['title']}".strip(" —")
        status(f"[{i}/{len(rows)}] {label}")
        try:
            entries = downloader.fetch_tracks(
                f"ytsearch1:{r['artist']} {r['title']} audio".strip(),
                dl_dir, None, audio_format,
            )
        except Exception:
            continue
        if not entries:
            continue
        entry = entries[0]
        track, _ = lib.add_file(entry["path"], source="playlist")
        track["title"] = r["title"] or track["title"]
        if r["artist"]:
            track["artist"] = r["artist"]
        if r["album"]:
            track["album"] = r["album"]
        if r["genre"]:
            track["genre"] = r["genre"]
        if download_covers:
            if r["cover_url"]:
                _set_cover(track, r["cover_url"], lib, force=True)
            if not track.get("cover") and entry.get("thumbnail"):
                _set_cover(track, entry["thumbnail"], lib)
        lib.add_to_playlist(pid, track["id"])
        if p and not p.get("cover") and track.get("cover"):
            p["cover"] = track["cover"]
        ok += 1
        lib.save()
    lib.save()
    return i18n.tr("Плейлист «{name}»: найдено {count} из {total}", name=name, count=ok, total=len(rows))


def from_url(url, dl_dir, lib, status, download_covers=True, audio_format="m4a"):
    """Трек, альбом или плейлист по ссылке (всё, что поддерживает yt-dlp)."""
    entries = downloader.fetch_tracks(url, dl_dir, status, audio_format)
    if not entries:
        return i18n.tr("Не удалось скачать трек по ссылке")

    playlist_title = (entries[0].get("playlist_title") or "").strip()
    pid = None
    playlist = None
    if len(entries) > 1:
        playlist = next((p for p in lib.playlists
                         if playlist_title and p["name"] == playlist_title), None)
        pid = playlist["id"] if playlist else lib.create_playlist(
            playlist_title or "Загруженный плейлист")
        playlist = lib.get_playlist(pid)
        if download_covers and playlist and not playlist.get("cover"):
            cover_url = entries[0].get("playlist_thumbnail") or entries[0].get("thumbnail")
            playlist["cover"] = _download_image(cover_url, lib, f"pl_{pid}.jpg")

    new = 0
    for entry in entries:
        track, created = lib.add_file(entry["path"], source="url")
        _apply_metadata(track, entry)
        if download_covers and not track.get("cover"):
            _set_cover(track, entry.get("thumbnail", ""), lib)
        if pid:
            lib.add_to_playlist(pid, track["id"])
        new += created
    lib.save()
    if playlist_title:
        return i18n.tr("Загружено треков: {count} в плейлист «{name}»", count=new, name=playlist_title)
    return i18n.tr("Загружено треков: {count}", count=new)


def download_one(url, dl_dir, lib, status, title="", artist="", thumbnail="",
                 download_covers=True, audio_format="m4a"):
    """Скачивает один выбранный результат поиска."""
    entries = downloader.fetch_tracks(url, dl_dir, status, audio_format)
    if not entries:
        return i18n.tr("Не удалось скачать трек")
    entry = entries[0]
    track, _ = lib.add_file(entry["path"], source="download")
    track["title"] = title or entry.get("title") or track["title"]
    if artist:
        track["artist"] = artist
    elif track.get("artist") == "Unknown artist" and entry.get("artist"):
        track["artist"] = entry["artist"]
    if download_covers:
        _set_cover(track, thumbnail or entry.get("thumbnail", ""), lib)
    lib.save()
    return i18n.tr("Скачано: {title}", title=track['title'])
