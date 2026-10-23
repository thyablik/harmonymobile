"""Определение платформы и безопасных отступов (вырез / статус-бар) для мобильной версии."""
import os
import sys

from PySide6.QtCore import Property, QObject, Signal
from PySide6.QtGui import QGuiApplication


def is_android() -> bool:
    return sys.platform == "android" or "ANDROID_ARGUMENT" in os.environ or "ANDROID_BOOTLOGO" in os.environ


def is_mobile() -> bool:
    """Мобильный режим: Android/iOS или HARMONY_MOBILE=1 (проверка мобильного интерфейса на ПК)."""
    return is_android() or sys.platform == "ios" or os.environ.get("HARMONY_MOBILE") == "1"


class PlatformInfo(QObject):
    insetsChanged = Signal()

    def __init__(self):
        super().__init__()
        self._top = 0
        self._bottom = 0
        screen = QGuiApplication.primaryScreen()
        if screen is not None:
            screen.availableGeometryChanged.connect(self._update)
            screen.geometryChanged.connect(self._update)
        self._update()

    def _update(self, *_):
        top = bottom = 0
        if is_mobile():
            override_top = os.environ.get("HARMONY_INSET_TOP")
            override_bottom = os.environ.get("HARMONY_INSET_BOTTOM")
            if override_top is not None or override_bottom is not None:
                top = int(override_top or 0)
                bottom = int(override_bottom or 0)
            else:
                screen = QGuiApplication.primaryScreen()
                if screen is not None:
                    full, free = screen.geometry(), screen.availableGeometry()
                    top = max(0, free.top() - full.top())
                    bottom = max(0, full.bottom() - free.bottom())
        if (top, bottom) != (self._top, self._bottom):
            self._top, self._bottom = top, bottom
            self.insetsChanged.emit()

    @Property(bool, constant=True)
    def isMobile(self):
        return is_mobile()

    @Property(bool, constant=True)
    def isAndroid(self):
        return is_android()

    @Property(int, notify=insetsChanged)
    def insetTop(self):
        return self._top

    @Property(int, notify=insetsChanged)
    def insetBottom(self):
        return self._bottom
