#!/bin/zsh
# Builds VibeClone.app bundle from SwiftPM artifacts.
# Result: ./build/VibeClone.app
#
# Usage: ./scripts/build-app.sh [debug|release]
set -euo pipefail

CONFIG="${1:-debug}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Build each product separately. Combined --product flags occasionally
# leave one artifact missing in the apple/Products tree under universal arch.
echo "==> swift build vibeclone-bridge ($CONFIG, universal)"
swift build --configuration "$CONFIG" --arch arm64 --arch x86_64 --product vibeclone-bridge

echo "==> swift build vibeclone ($CONFIG, universal)"
swift build --configuration "$CONFIG" --arch arm64 --arch x86_64 --product vibeclone

BIN_DIR="$ROOT/.build/apple/Products/$(echo "${CONFIG:0:1}" | tr a-z A-Z)${CONFIG:1}"
if [ ! -x "$BIN_DIR/vibeclone" ] || [ ! -x "$BIN_DIR/vibeclone-bridge" ]; then
    echo "FATAL: missing binaries in $BIN_DIR" >&2
    ls "$BIN_DIR" >&2 || true
    exit 1
fi

APP="$ROOT/build/VibeClone.app"
echo "==> assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Helpers" "$APP/Contents/Resources"

cp "$BIN_DIR/vibeclone" "$APP/Contents/MacOS/vibeclone"
cp "$BIN_DIR/vibeclone-bridge" "$APP/Contents/Helpers/vibeclone-bridge"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

chmod +x "$APP/Contents/MacOS/vibeclone" "$APP/Contents/Helpers/vibeclone-bridge"

# Sign nested executable FIRST, then bundle. --deep is deprecated; sign explicitly.
echo "==> codesign (ad-hoc, dev only)"
codesign --force --sign - --timestamp=none "$APP/Contents/Helpers/vibeclone-bridge"
codesign --force --sign - --timestamp=none "$APP/Contents/MacOS/vibeclone"
codesign --force --sign - --timestamp=none "$APP"

# Verify.
codesign --verify --deep --strict "$APP" && echo "==> codesign verify OK"

echo "==> ok: $APP"
ls -la "$APP/Contents" "$APP/Contents/MacOS" "$APP/Contents/Helpers"
