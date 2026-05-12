#!/bin/bash
# Generate / refresh bundled 8-bit sounds in Resources/Sounds/.
# Run before bundling the app (or whenever Resources/Sounds is empty).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/Resources/Sounds"
mkdir -p "$DIR"

if command -v sox >/dev/null 2>&1; then
    echo "==> sox available, generating chiptune tones"
    sox -n -r 22050 -c 1 "$DIR/permission.aiff" synth 0.18 square 880 vol 0.5
    sox -n -r 22050 -c 1 "$DIR/notification.aiff" synth 0.12 square 660 vol 0.5
    sox -n -r 22050 -c 1 "$DIR/idle.aiff" synth 0.25 square 440 vol 0.3
else
    echo "==> sox not installed, falling back to system sounds"
    cp /System/Library/Sounds/Tink.aiff "$DIR/permission.aiff"
    cp /System/Library/Sounds/Pop.aiff "$DIR/notification.aiff"
    cp /System/Library/Sounds/Bottle.aiff "$DIR/idle.aiff"
fi

echo "==> generated:"
ls -la "$DIR"
