#!/bin/bash
# Installa sul Mac l'ultima Prisma per Apple Silicon fatta da GitHub (release «ultima», build verde di main).
# Dal 20 novembre 2026 (scelta dell'utente) build e prove si fanno solo su GitHub: sul Mac si installa e basta.
# Uso: bash Supporto/installa-ultima.sh   (chiudi Prisma prima; i dati in ~/Library/Application Support/Prisma non si toccano)
set -euo pipefail
URL="https://github.com/denisvicenzonilavoro/Prisma/releases/download/ultima/Prisma.zip"
if pgrep -x Prisma > /dev/null; then echo "✗ Prisma è aperta: chiudila e rilancia"; exit 1; fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "▸ Scarico l'ultima Prisma…"
curl -fL --progress-bar -o "$TMP/Prisma.zip" "$URL"
ditto -x -k "$TMP/Prisma.zip" "$TMP"
codesign --verify --deep --strict "$TMP/Prisma.app"
COMMIT=$(/usr/libexec/PlistBuddy -c 'Print :PrismaCommit' "$TMP/Prisma.app/Contents/Info.plist" 2>/dev/null || echo "?")
rm -rf /Applications/Prisma.app
ditto "$TMP/Prisma.app" /Applications/Prisma.app
echo "✓ Installata in /Applications/Prisma.app (commit $COMMIT)"
