#!/bin/zsh
# Builds VibeClone.app bundle from SwiftPM artifacts.
# Result: ./build/VibeClone.app
#
# Usage: ./scripts/build-app.sh [debug|release]
set -euo pipefail

CONFIG="${1:-debug}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> swift build --configuration $CONFIG"
swift build --configuration "$CONFIG" --arch arm64 --arch x86_64 \
    --product vibeclone --product vibeclone-bridge

BIN_DIR="$(swift build --configuration "$CONFIG" --arch arm64 --arch x86_64 --show-bin-path)"
APP="$ROOT/build/VibeClone.app"

echo "==> assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Helpers" "$APP/Contents/Resources"

cp "$BIN_DIR/vibeclone" "$APP/Contents/MacOS/vibeclone"
cp "$BIN_DIR/vibeclone-bridge" "$APP/Contents/Helpers/vibeclone-bridge"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

chmod +x "$APP/Contents/MacOS/vibeclone" "$APP/Contents/Helpers/vibeclone-bridge"

# Ad-hoc sign so Gatekeeper won't refuse on first launch in dev.
codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "==> ok: $APP"
ls -la "$APP/Contents" "$APP/Contents/MacOS" "$APP/Contents/Helpers"
