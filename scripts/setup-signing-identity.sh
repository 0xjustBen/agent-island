#!/bin/zsh
# Create a stable self-signed code-signing identity so AX/Automation
# permission grants survive every rebuild.
#
# macOS PKCS12 import has weird key/cert pairing failures across LibreSSL
# versions, so the reliable path is Apple's own Certificate Assistant GUI.
# Five clicks, one time, then forever.
set -e

IDENTITY="VibeClone Self-Signed"

if security find-identity -v -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
    echo "Identity '$IDENTITY' already present in the login keychain. Done."
    exit 0
fi

cat <<INSTRUCTIONS

VibeClone needs a stable code-signing identity in your login keychain so
macOS Accessibility/Automation permissions survive rebuilds. Apple's
Certificate Assistant is the most reliable way to create one.

  1. Opening Keychain Access for you now…
  2. Menu bar:  Keychain Access  →  Certificate Assistant
                                  →  Create a Certificate…
  3. Name:                  $IDENTITY
     Identity Type:         Self Signed Root
     Certificate Type:      Code Signing
  4. Click  Continue → Continue → Done.

When the new cert appears in your login keychain, rerun:

  ./scripts/build-app.sh debug

build-app.sh auto-detects '$IDENTITY' and signs with it. Add the rebuilt
.app once to System Settings → Privacy & Security → Accessibility and
the grant will persist across every future build.

INSTRUCTIONS

open -a "Keychain Access"
