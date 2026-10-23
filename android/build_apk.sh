#!/usr/bin/env bash
# Сборка Android APK для Harmony (нужен Linux, macOS или WSL2 на Windows; в облаке - GitHub Actions).
#
#   ./android/build_apk.sh              # debug APK для arm64 (большинство телефонов)
#   ARCH=x86_64 ./android/build_apk.sh  # эмулятор
#
# Что делает: копирует проект во временную папку без лишнего, встраивает чисто
# питоновские зависимости (mutagen, yt-dlp), скачивает Android-колёса PySide6
# и запускает pyside6-android-deploy.
set -euo pipefail

# Нужен именно NDK r28c: инструмент скачает его сам. Системные NDK из окружения ему мешают.
unset ANDROID_NDK_ROOT ANDROID_NDK_HOME ANDROID_NDK ANDROID_NDK_LATEST_HOME

QT_VER="${QT_VER:-6.12.0}"          # версия PySide6 на ПК и в колёсах должна совпадать
ARCH="${ARCH:-aarch64}"             # aarch64 или x86_64
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
WORK="$BUILD/app"
WHEELS="$BUILD/wheels"
BASE="https://download.qt.io/official_releases/QtForPython"
PYSIDE_WHEEL="pyside6-$QT_VER-$QT_VER-cp310-abi3-android_$ARCH.whl"
SHIBOKEN_WHEEL="shiboken6-$QT_VER-$QT_VER-cp310-abi3-android_$ARCH.whl"

PY="${PYTHON:-python3}"
[ -d "$BUILD/venv" ] || "$PY" -m venv "$BUILD/venv"
# shellcheck disable=SC1091
source "$BUILD/venv/bin/activate"
pip install -q --upgrade pip
pip install -q "PySide6==$QT_VER"
pip install -q -r "$(python -c 'import PySide6,os;print(os.path.join(os.path.dirname(PySide6.__file__),"scripts","requirements-android.txt"))')"

mkdir -p "$WHEELS"
[ -f "$WHEELS/$PYSIDE_WHEEL" ]   || curl -fL "$BASE/pyside6/$PYSIDE_WHEEL"     -o "$WHEELS/$PYSIDE_WHEEL"
[ -f "$WHEELS/$SHIBOKEN_WHEEL" ] || curl -fL "$BASE/shiboken6/$SHIBOKEN_WHEEL" -o "$WHEELS/$SHIBOKEN_WHEEL"

# чистая копия проекта: без данных пользователя, сборок и десктопных файлов
rm -rf "$WORK"; mkdir -p "$WORK"
(cd "$ROOT" && tar \
    --exclude=./build --exclude=./data --exclude=./android --exclude=./vendor \
    --exclude='__pycache__' --exclude=./run.bat --exclude=./Harmony.spec \
    -cf - .) | tar -xf - -C "$WORK"

# pyside6-android-deploy ставит в APK только python3, shiboken6 и PySide6,
# поэтому остальные (чисто питоновские) пакеты кладём прямо в проект.
# убираем BOM и CRLF из .py (файлы, сохранённые в Блокноте Windows, ломают парсер deploy)
find "$WORK" -name '*.py' -not -path "$WORK/vendor/*" -exec sed -i -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' {} +

pip install -q --no-compile --target "$WORK/vendor" mutagen yt-dlp

cp "$ROOT/android/icon.png" "$WORK/icon.png"
cat > "$WORK/pysidedeploy.spec" <<SPEC
[app]
title = Harmony
project_dir = .
input_file = main.py
exec_directory = $BUILD/out
project_file =
icon = icon.png

[python]
packages = Nuitka==4.1.1
android_packages = buildozer==1.6.0,cython==0.29.33

[qt]
qml_files =
excluded_qml_plugins =
modules =
plugins =

[android]
wheel_pyside = $WHEELS/$PYSIDE_WHEEL
wheel_shiboken = $WHEELS/$SHIBOKEN_WHEEL
plugins =

[nuitka]
macos.permissions =
mode = standalone
extra_args = --quiet --noinclude-qt-translations

[buildozer]
mode = debug
recipe_dir =
jars_dir =
ndk_path = ${HARMONY_NDK:-}
sdk_path = ${HARMONY_SDK:-}
local_libs =
arch = $ARCH
SPEC

cd "$WORK"
run_deploy() {
    pyside6-android-deploy \
        --name Harmony \
        -c pysidedeploy.spec \
        --wheel-pyside "$WHEELS/$PYSIDE_WHEEL" \
        --wheel-shiboken "$WHEELS/$SHIBOKEN_WHEEL" \
        --extra-modules=Network,Multimedia \
        --extra-ignore-dirs=vendor \
        --keep-deployment-files \
        -v \
        -f
}

find_apk() {
    find "$BUILD" "$WORK" -type f \( -name '*.apk' -o -name '*.aab' \) \
        -not -path "$BUILD/venv/*" 2>/dev/null | head -1 || true
}

run_deploy || echo "deploy завершился с ошибкой, проверяю результат..."
APK="$(find_apk)"

# Лицензии Android SDK: в CI некому нажать "y", поэтому после первого запуска
# (когда buildozer уже скачал свой SDK и создал buildozer.spec) принимаем их сами и повторяем.
if [ -z "$APK" ]; then
    SDK_DIR="$HOME/.buildozer/android/platform/android-sdk"
    SDKMGR="$(find "$SDK_DIR" -type f -name sdkmanager 2>/dev/null | head -1 || true)"
    if [ -n "$SDKMGR" ]; then
        echo ">>> Принимаю лицензии Android SDK и запускаю сборку ещё раз"
        [ -f buildozer.spec ] && sed -i 's/^#\s*android.accept_sdk_license.*/android.accept_sdk_license = True/' buildozer.spec
        (set +o pipefail; yes | "$SDKMGR" --sdk_root="$SDK_DIR" --licenses > /dev/null 2>&1) || true
        run_deploy || echo "повторный deploy завершился с ошибкой"
        APK="$(find_apk)"
    fi
fi

if [ -z "$APK" ]; then
    echo "ОШИБКА: pyside6-android-deploy завершился, но APK не найден." >&2
    exit 1
fi
mkdir -p "$BUILD/out"
case "$APK" in "$BUILD/out/"*) ;; *) cp "$APK" "$BUILD/out/" ;; esac

echo
echo "Готово. APK лежит в: $BUILD/out"
