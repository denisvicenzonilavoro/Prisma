#!/bin/bash
# Costruisce Prisma.app sul Mac, senza GitHub: stessi passi del workflow
# (.github/workflows/build.yml), ma solo per Apple Silicon (più veloce sull'M1).
# Uso, dalla cartella del progetto:
#   bash Supporto/costruisci-mac.sh            → compila e crea Prisma.app
#   bash Supporto/costruisci-mac.sh --prove    → in più esegue le prove principali
#   bash Supporto/costruisci-mac.sh --installa → in più copia Prisma.app in Applicazioni
set -euo pipefail
cd "$(dirname "$0")/.."

PROVE=0; INSTALLA=0
for a in "$@"; do
  case "$a" in
    --prove) PROVE=1 ;;
    --installa) INSTALLA=1 ;;
    *) echo "Opzione sconosciuta: $a"; exit 2 ;;
  esac
done

echo "▸ Compilo (release, arm64)…"
swift build -c release --arch arm64
BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"

APP=Prisma.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Prisma" "$APP/Contents/MacOS/Prisma"
cp Info.plist "$APP/Contents/Info.plist"
COMMIT="$(git rev-parse --short=7 HEAD 2>/dev/null || echo locale)"
/usr/libexec/PlistBuddy -c "Add :PrismaCommit string $COMMIT" "$APP/Contents/Info.plist"

if [ -f Design/Icone/AppIcon.png ]; then
  echo "▸ Icona…"
  ICONSET="$(mktemp -d)/AppIcon.iconset"
  mkdir -p "$ICONSET"
  for s in 16 32 128 256 512; do
    sips -z $s $s Design/Icone/AppIcon.png --out "$ICONSET/icon_${s}x${s}.png" > /dev/null
    d=$((s * 2))
    sips -z $d $d Design/Icone/AppIcon.png --out "$ICONSET/icon_${s}x${s}@2x.png" > /dev/null
  done
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist"
fi

# Bundle delle risorse SwiftPM in Contents/Resources (non nella radice del .app)
for b in "$BIN_DIR"/*.bundle; do
  [ -e "$b" ] || continue
  ditto "$b" "$APP/Contents/Resources/$(basename "$b")"
done
# Istruzioni, schemi, esempi e addestramento di Vera
for cartella in Istruzioni Schemi Esempi Addestramento Valutazione; do
  if [ -d "Vera/$cartella" ]; then
    mkdir -p "$APP/Contents/Resources/Vera"
    ditto "Vera/$cartella" "$APP/Contents/Resources/Vera/$cartella"
  fi
done
codesign --force --deep --sign - "$APP"
echo "✓ Creata $(pwd)/$APP"

if [ "$PROVE" = 1 ]; then
  echo "▸ Prove…"
  "$APP/Contents/MacOS/Prisma" --verifica-risorse
  "$APP/Contents/MacOS/Prisma" --prova-backup
  "$APP/Contents/MacOS/Prisma" --prova-calcoli
  "$APP/Contents/MacOS/Prisma" --prova-vera
  "$APP/Contents/MacOS/Prisma" --prova-ovunque
  echo "✓ Prove superate"
fi

if [ "$INSTALLA" = 1 ]; then
  rm -rf "/Applications/$APP"
  ditto "$APP" "/Applications/$APP"
  echo "✓ Installata in /Applications/$APP"
fi
