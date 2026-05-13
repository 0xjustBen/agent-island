#!/bin/zsh
# Builds AgentIsland.app bundle from SwiftPM artifacts.
# Result: ./build/AgentIsland.app
#
# Usage: ./scripts/build-app.sh [debug|release]
set -euo pipefail

CONFIG="${1:-debug}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Build each product separately. Combined --product flags occasionally
# leave one artifact missing in the apple/Products tree under universal arch.
echo "==> swift build agentisland-bridge ($CONFIG, universal)"
swift build --configuration "$CONFIG" --arch arm64 --arch x86_64 --product agentisland-bridge

echo "==> swift build agentisland ($CONFIG, universal)"
swift build --configuration "$CONFIG" --arch arm64 --arch x86_64 --product agentisland

BIN_DIR="$ROOT/.build/apple/Products/$(echo "${CONFIG:0:1}" | tr a-z A-Z)${CONFIG:1}"
if [ ! -x "$BIN_DIR/agentisland" ] || [ ! -x "$BIN_DIR/agentisland-bridge" ]; then
    echo "FATAL: missing binaries in $BIN_DIR" >&2
    ls "$BIN_DIR" >&2 || true
    exit 1
fi

APP="$ROOT/build/AgentIsland.app"
echo "==> assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Helpers" "$APP/Contents/Resources"

cp "$BIN_DIR/agentisland" "$APP/Contents/MacOS/agentisland"
cp "$BIN_DIR/agentisland-bridge" "$APP/Contents/Helpers/agentisland-bridge"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

# Ensure bundled sounds exist, generate if missing.
if [ ! -f "$ROOT/Resources/Sounds/permission.aiff" ]; then
    bash "$ROOT/scripts/gen-sounds.sh"
fi
cp -R "$ROOT/Resources/Sounds" "$APP/Contents/Resources/Sounds"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

# Localizations
for lproj in "$ROOT/Resources/Localizations"/*.lproj; do
    [ -d "$lproj" ] || continue
    cp -R "$lproj" "$APP/Contents/Resources/$(basename "$lproj")"
done

chmod +x "$APP/Contents/MacOS/agentisland" "$APP/Contents/Helpers/agentisland-bridge"

# Use a stable self-signed identity (from scripts/setup-signing-identity.sh)
# when present — that keeps the bundle hash steady across rebuilds so macOS
# permission grants (Accessibility, Automation) survive. Falls back to
# ad-hoc "-" otherwise — at the cost of re-granting AX every build.
IDENTITY="AgentIsland Self-Signed"
# `find-identity -p codesigning` filters by trust which self-signed certs
# usually lack. Match by name on the untrusted list — codesign itself
# happily signs with it, that's what matters here.
if security find-identity 2>/dev/null | grep -q "$IDENTITY"; then
    SIGN_ARG="$IDENTITY"
    echo "==> codesign (stable identity: $IDENTITY)"
else
    SIGN_ARG="-"
    echo "==> codesign (ad-hoc — run scripts/setup-signing-identity.sh for persistent AX permission)"
fi
codesign --force --sign "$SIGN_ARG" --timestamp=none "$APP/Contents/Helpers/agentisland-bridge"
codesign --force --sign "$SIGN_ARG" --timestamp=none "$APP/Contents/MacOS/agentisland"
codesign --force --sign "$SIGN_ARG" --timestamp=none "$APP"

# Verify.
codesign --verify --deep --strict "$APP" && echo "==> codesign verify OK"

echo "==> ok: $APP"
ls -la "$APP/Contents" "$APP/Contents/MacOS" "$APP/Contents/Helpers"
