"""Настройки приложения, сохраняются в data/settings.json."""
import json
from pathlib import Path

DEFAULTS = {
    "language": "ru",
    "delete_files": False,
    "download_covers": True,
    "dynamic_theme": True,
    "download_dir": "",
    "download_format": "m4a",
    "lyrics_text_color": "#A7B1BF",
    "lyrics_active_color": "#8AB4F8",
    "lyrics_bg_color": "#161A20",
    "lyrics_font_size": 18,
    "lyrics_align": "left",
    "lyrics_auto_scroll": True,
    "lyrics_fullscreen_default": False,
}


class SettingsStore:
    def __init__(self, data_dir: Path):
        self.dir = Path(data_dir)
        self.db = self.dir / "settings.json"
        self.data = dict(DEFAULTS)
        if self.db.exists():
            try:
                loaded = json.loads(self.db.read_text(encoding="utf-8"))
                if isinstance(loaded, dict):
                    for key in DEFAULTS:
                        if key in loaded:
                            self.data[key] = loaded[key]
            except Exception:
                pass

    def get(self, key, default=None):
        return self.data.get(key, DEFAULTS.get(key, default))

    def set(self, key, value):
        self.data[key] = value

    def save(self):
        self.dir.mkdir(parents=True, exist_ok=True)
        self.db.write_text(
            json.dumps(self.data, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
