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
# Vera lavora con Ministral 3 (dal 20 novembre 2026): se Ollama c'è e il modello manca, lo scarica (solo il modello, nessun dato)
if command -v ollama > /dev/null && ! ollama list 2>/dev/null | grep -q "^ministral-3:3b"; then
  echo "▸ Scarico Ministral 3 per Vera (circa 3 GB)…"
  ollama pull ministral-3:3b || echo "✗ Ministral 3 non scaricato: riprova con «ollama pull ministral-3:3b»"
fi
