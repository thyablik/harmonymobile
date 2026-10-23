"""Тексты песен: локальные .lrc/.txt и синхронизированные тексты из LRCLIB."""
import html
import json
import re
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from . import i18n

API = "https://lrclib.net/api"
USER_AGENT = "Harmony/1.0 (local music player)"
TIME_RE = re.compile(r"\[(\d+):(\d{1,2})(?:[.:](\d{1,3}))?\]")
OFFSET_RE = re.compile(r"\[offset:\s*([+-]?\d+)\s*\]", re.IGNORECASE)
TITLE_NOISE = re.compile(
    r"\s*[\(\[](?:official|lyrics?|audio|video|visualizer|hd|hq|mv|m/v)[^\)\]]*[\)\]]",
    re.IGNORECASE,
)
VIDEO_ID = re.compile(r"\s*\[[A-Za-z0-9_-]{11}\]\s*$")


def _state(track, status, synced=False, lines=None, plain="", source="", message=""):
    return {
        "trackId": track.get("id", ""),
        "status": status,
        "synced": bool(synced),
        "lines": lines or [],
        "plain": plain or "",
        "source": source,
        "message": message,
    }


def _plain_text(text):
    if not text:
        return ""
    text = html.unescape(text).replace("\r\n", "\n").replace("\r", "\n").strip()
    out = []
    blank = False
    for line in text.split("\n"):
        line = line.strip()
        if line:
            out.append(line)
            blank = False
        elif not blank:
            out.append("")
            blank = True
    return "\n".join(out).strip()


def parse_lrc(text):
    """Разбирает LRC в список строк с временем в секундах."""
    if not text:
        return []
    offset = 0.0
    match = OFFSET_RE.search(text)
    if match:
        offset = int(match.group(1)) / 1000.0

    lines = []
    for raw in text.splitlines():
        stamps = list(TIME_RE.finditer(raw))
        if not stamps:
            continue
        content = html.unescape(raw[stamps[-1].end():]).strip()
        if not content:
            continue
        for stamp in stamps:
            minutes = int(stamp.group(1))
            seconds = int(stamp.group(2))
            fraction = stamp.group(3) or ""
            fraction_seconds = int(fraction) / (10 ** len(fraction)) if fraction else 0.0
            time = minutes * 60 + seconds + fraction_seconds + offset
            lines.append({"time": max(0.0, round(time, 3)), "text": content})
    lines.sort(key=lambda item: item["time"])
    return lines


def _read_text(path):
    data = path.read_bytes()
    if data.startswith((b"\xff\xfe", b"\xfe\xff")):
        try:
            return data.decode("utf-16")
        except UnicodeDecodeError:
            pass
    try:
        return data.decode("utf-8-sig")
    except UnicodeDecodeError:
        return data.decode("cp1251", errors="replace")


def _sidecar(track):
    path = Path(track.get("path", ""))
    if not path.is_file():
        return None
    lrc = path.with_suffix(".lrc")
    if lrc.is_file():
        try:
            text = _read_text(lrc)
        except OSError:
            text = ""
        lines = parse_lrc(text)
        if lines:
            return _state(track, "ready", True, lines, _plain_text(text), "файл .lrc")
        plain = _plain_text(text)
        if plain:
            return _state(track, "ready", False, [], plain, "файл .lrc")
    txt = path.with_suffix(".txt")
    if txt.is_file():
        try:
            plain = _plain_text(_read_text(txt))
        except OSError:
            plain = ""
        if plain:
            return _state(track, "ready", False, [], plain, "файл .txt")
    return None


def _request_json(url):
    request = urllib.request.Request(url, headers={
        "User-Agent": USER_AGENT,
        "Accept": "application/json",
    })
    with urllib.request.urlopen(request, timeout=15) as response:
        return json.loads(response.read().decode("utf-8"))


def _has_lyrics(record):
    return bool(record and (record.get("syncedLyrics") or record.get("plainLyrics")))


def _pick(records, duration):
    records = [r for r in records if isinstance(r, dict) and _has_lyrics(r)]
    if not records:
        return None

    def score(record):
        synced_rank = 0 if record.get("syncedLyrics") else 1
        track_duration = float(record.get("duration") or 0)
        if duration and track_duration:
            difference = abs(track_duration - duration)
        else:
            difference = 10_000
        return synced_rank, difference

    return min(records, key=score)


def _norm(value):
    return "".join(ch for ch in (value or "").casefold() if ch.isalnum())


def _query_title(title, artist):
    if not artist:
        return title
    for separator in (" — ", " – ", " - "):
        if separator not in title:
            continue
        left, right = title.split(separator, 1)
        left_norm = _norm(left)
        artist_norm = _norm(artist)
        if right.strip() and left_norm and (
            left_norm in artist_norm or artist_norm in left_norm
        ):
            return right.strip()
    return title


def _record_state(track, record):
    if not record:
        return None
    if record.get("instrumental"):
        return _state(track, "empty", message=i18n.tr("Это инструментальная композиция."))
    lines = parse_lrc(record.get("syncedLyrics") or "")
    if lines:
        return _state(track, "ready", True, lines,
                      _plain_text(record.get("plainLyrics") or ""), "LRCLIB")
    plain = _plain_text(record.get("plainLyrics") or "")
    if plain:
        return _state(track, "ready", False, [], plain, "LRCLIB")
    return None


def _online(track):
    title = TITLE_NOISE.sub("", (track.get("title") or "").strip())
    title = VIDEO_ID.sub("", title).strip()
    artist = (track.get("artist") or "").strip()
    if artist == "Unknown artist":
        artist = ""
    title = _query_title(title, artist)
    album = (track.get("album") or "").strip()
    duration = int(track.get("duration") or 0)
    if not title:
        return _state(track, "empty", message=i18n.tr("У трека нет названия для поиска."))

    record = None
    network_error = False
    network_ok = False

    if artist:
        params = {"track_name": title, "artist_name": artist}
        if album:
            params["album_name"] = album
        if duration:
            params["duration"] = duration
        try:
            data = _request_json(f"{API}/get?{urllib.parse.urlencode(params)}")
            network_ok = True
            if isinstance(data, dict):
                record = data
        except urllib.error.HTTPError as error:
            if error.code == 404:
                network_ok = True
            else:
                network_error = True
        except Exception:
            network_error = True

    if not _has_lyrics(record):
        params = {"track_name": title}
        if artist:
            params["artist_name"] = artist
        try:
            data = _request_json(f"{API}/search?{urllib.parse.urlencode(params)}")
            network_ok = True
            if isinstance(data, list):
                record = _pick(data, duration) or record
        except Exception:
            network_error = True

    if not _has_lyrics(record):
        query = f"{artist} {title}".strip()
        try:
            data = _request_json(f"{API}/search?{urllib.parse.urlencode({'q': query})}")
            network_ok = True
            if isinstance(data, list):
                record = _pick(data, duration) or record
        except Exception:
            network_error = True

    state = _record_state(track, record)
    if state:
        return state
    if network_error and not network_ok:
        return _state(track, "error", message=i18n.tr("Не удалось связаться с LRCLIB. Проверьте подключение к интернету."))
    return _state(track, "empty", message=i18n.tr("Текст этой песни не найден в LRCLIB."))


def fetch(track, cache_dir, force=False):
    """Ищет локальный текст, затем кэш, затем LRCLIB."""
    local = _sidecar(track)
    if local:
        return local

    cache_dir = Path(cache_dir)
    cache_file = cache_dir / f"{track['id']}.json"
    if cache_file.is_file() and not force:
        try:
            cached = json.loads(cache_file.read_text(encoding="utf-8"))
            if cached.get("trackId") == track["id"] and cached.get("status") == "ready":
                return cached
        except Exception:
            pass

    state = _online(track)
    if state.get("status") == "ready":
        try:
            cache_dir.mkdir(parents=True, exist_ok=True)
            cache_file.write_text(json.dumps(state, ensure_ascii=False), encoding="utf-8")
        except OSError:
            pass
    return state
