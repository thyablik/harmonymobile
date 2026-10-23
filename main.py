import os
import sys
from pathlib import Path

os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")

from PySide6.QtCore import QStandardPaths, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

# В Android-сборке чисто питоновские зависимости (mutagen, yt-dlp) лежат в vendor/.
_vendor = Path(__file__).resolve().parent / "vendor"
if _vendor.is_dir():
    sys.path.insert(0, str(_vendor))

from core.backend import Backend  # noqa: E402
from core.platform_info import PlatformInfo, is_mobile  # noqa: E402


def data_directory(asset_root: Path) -> Path:
    # На телефоне пишем только во внутреннее хранилище приложения.
    if is_mobile() and "HARMONY_DATA" not in os.environ:
        base = QStandardPaths.writableLocation(QStandardPaths.StandardLocation.AppDataLocation)
        if base:
            return Path(base) / "data"
    if "HARMONY_DATA" in os.environ:
        return Path(os.environ["HARMONY_DATA"])
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent / "data"
    return asset_root / "data"


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Harmony")
    app.setOrganizationName("Harmony")

    asset_root = Path(getattr(sys, "_MEIPASS", None) or Path(__file__).resolve().parent)
    engine = QQmlApplicationEngine()
    platform = PlatformInfo()
    backend = Backend(data_directory(asset_root))
    engine.rootContext().setContextProperty("platform", platform)
    engine.rootContext().setContextProperty("backend", backend)

    engine.load(QUrl.fromLocalFile(str(asset_root / "qml" / "Main.qml")))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
