#!/bin/bash
# I controlli che prima faceva solo il workflow di GitHub (.github/workflows/build.yml), ora sul Mac.
# Dal 16 novembre 2026 il lavoro è solo in locale (decisione dell'utente): li lancia `costruisci-mac.sh --prove`.
# Restano fuori le prove di iPhone e iPad (si lanciano a parte quando servono) e il controllo informativo di Mercato.
# Uso, dalla cartella del progetto, dopo aver creato Prisma.app:
#   bash Supporto/controlli-locali.sh
set -euo pipefail
cd "$(dirname "$0")/.."
APP=Prisma.app

errore() { echo "✗ $1"; exit 1; }

echo "▸ Controlli statici della privacy…"

# Privacy del Territorio («Luce» giro 11, decisioni 20 e 21): niente rete, geocodifica, percorsi, MapKit o CoreLocation
if grep -nE 'URLSession|URLRequest|NWConnection|CLGeocoder|MKDirections|import MapKit|import CoreLocation' \
    Sources/Prisma/Motori/MotoreTerritorio.swift Sources/Prisma/Motori/TabellaTerritorio.swift \
    Sources/Prisma/Shell/*Territorio*.swift Sources/Prisma/Dati/Territorio.swift; then
  errore "Il Territorio non deve usare la rete, servizi di mappe o la posizione del dispositivo"
fi

# Privacy della notte («Luce» giro 14, decisioni 30, 31, 101)
if grep -nE 'URLSession|URLRequest|NWConnection|ClienteMercato|aggiornaMercato|SMAppService|pmset|\bTimer\b' \
    Sources/Prisma/Motori/MotoreNotte.swift Sources/Prisma/Motori/TestiNotte.swift \
    Sources/Prisma/Motori/EsecutoreBozzeNotte.swift Sources/Prisma/Dati/LavoroNotte.swift \
    Sources/Prisma/Shell/*Notte*.swift Sources/Prisma/Shell/AlimentazioneMac.swift; then
  errore "Il lavoro della notte non deve usare la rete, Timer, SMAppService o pmset"
fi

# Privacy delle cose date al cliente («Luce» giro 15, decisione 1)
if grep -rnE 'wa\.me|whatsapp://|api\.whatsapp' Sources/Prisma; then
  errore "Niente indirizzi di WhatsApp nel codice: si condivide solo dal foglio di sistema"
fi
FILE_USCITE=$(ls Sources/Prisma/Shell/FoglioCondivisione.swift Sources/Prisma/Shell/UsciteCliente.swift \
    Sources/Prisma/Dati/FilePrismaCliente.swift Sources/Prisma/Shell/*Film*.swift Sources/Prisma/Dati/*Capsul*.swift \
    Sources/Prisma/Dati/Sinistro.swift Sources/Prisma/Dati/*PrismaCliente*.swift Sources/Prisma/Motori/*PrismaCliente*.swift \
    Sources/Prisma/Shell/*PrismaCliente*.swift Sources/Prisma/Motori/*Film*.swift Sources/Prisma/Motori/*Capsul*.swift \
    Sources/Prisma/Shell/*Capsul*.swift Sources/Prisma/Motori/*Sinistr*.swift Sources/Prisma/Shell/*Sinistr*.swift \
    Sources/Prisma/iOS/*Sinistr*.swift Sources/Prisma/Shell/EsportaBiglietto.swift 2>/dev/null || true)
if [ -n "$FILE_USCITE" ] && grep -nE 'URLSession|URLRequest|NWConnection' $FILE_USCITE; then
  errore "Le cose date al cliente non devono usare la rete"
fi

# Il lettore del Prisma del cliente (decisioni 3 e 109) non usa la rete
if grep -nE 'fetch\(|XMLHttpRequest|WebSocket|sendBeacon|import\(|https?://' Sources/Prisma/Risorse/PrismaCliente/lettore.js; then
  errore "Il lettore del Prisma del cliente non deve usare la rete"
fi

# Privacy della realtà aumentata («Luce» giro 16, decisioni 26 e 27)
if grep -nE 'UIImageWriteToSavedPhotosAlbum|PHPhotoLibrary|import Photos|ARWorldMap|getCurrentWorldMap|URLSession|URLRequest' \
    Sources/Prisma/Motori/MotoreRealtaAumentata.swift Sources/Prisma/Shell/*Realta*.swift \
    Sources/Prisma/iOS/RealtaAumentataMobile.swift Sources/Prisma/DesignSystem/CristalloFermo.swift; then
  errore "La realtà aumentata non deve salvare nel Rullino, salvare mappe del mondo o usare la rete"
fi
if grep -rnE 'UIImageWriteToSavedPhotosAlbum|PHPhotoLibrary|import Photos|PHAssetChangeRequest' Sources/Prisma; then
  errore "Prisma non salva nel Rullino"
fi
if grep -n 'NSPhotoLibraryAddUsageDescription\|NSPhotoLibraryUsageDescription' Supporto/iOS/Info.plist; then
  errore "Prisma non chiede l'accesso al Rullino"
fi
echo "✓ Privacy: nessun uso vietato"

echo "▸ Prisma.app e risorse…"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist")" = Prisma || errore "CFBundleExecutable"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")" = local.prisma || errore "CFBundleIdentifier"
if [ -d Sources/Prisma/Risorse ]; then
  BUNDLE="$APP/Contents/Resources/Prisma_Prisma.bundle"
  RIS="$BUNDLE/Contents/Resources/Risorse"
  [ -d "$RIS" ] || RIS="$BUNDLE/Risorse"
  [ -d "$RIS" ] || errore "Struttura inattesa del bundle delle risorse"
  MANCANTI=$( (cd Sources/Prisma/Risorse && find . -type f ! -name '.*') | while read -r f; do
    [ -f "$RIS/$f" ] || echo "$f"; done)
  [ -z "$MANCANTI" ] || { echo "$MANCANTI"; errore "Mancano risorse nel .app"; }
fi
for f in Istruzioni/chat.md Istruzioni/commento.md Istruzioni/conversazione.md Istruzioni/mini.md Istruzioni/scenari.md \
    Istruzioni/messaggi.md Schemi/scenario.json Esempi/scenari.json Istruzioni/copilota.md Schemi/copilota.json \
    Esempi/copilota.json Istruzioni/verbale-copilota.md Istruzioni/palestra.md Schemi/palestra.json Esempi/palestra.json \
    Valutazione/palestra.json Addestramento/vera-su-misura.ipynb Addestramento/addestra.py Esempi/esame-di-prova.json; do
  test -f "$APP/Contents/Resources/Vera/$f" || errore "Manca Vera/$f nel .app"
done
codesign --verify --deep --strict "$APP" || errore "Firma di Prisma.app non valida"
echo "✓ Prisma.app completa"

# Il file del Prisma del cliente aperto con il lettore vero: serve Node, che sul Mac non c'è sempre
# Node installato da nodejs.org nella cartella utente (~/.local/node), senza Homebrew né modifiche al terminale
[ -x "$HOME/.local/node/bin/node" ] && PATH="$HOME/.local/node/bin:$PATH"
if command -v node > /dev/null; then
  echo "▸ Prisma del cliente: lettore del file (Node)…"
  CARTELLA_FILE="$(mktemp -d)/file-cliente"
  "$APP/Contents/MacOS/Prisma" --prova-file-cliente "$CARTELLA_FILE"
  node Supporto/prova-file-cliente.mjs "$CARTELLA_FILE"
else
  echo "· Prova del lettore del Prisma del cliente saltata: Node non è installato (il file HTML cifrato resta spento)"
fi

# Le fatture di esempio (dati fittizi, nessun invio allo SdI) contro lo schema ufficiale FatturaPA 1.2.2.
# Gli schemi pubblici si scaricano una volta (fatturapa.gov.it e w3.org) e restano nella cache: niente validazione finta.
echo "▸ Fattura elettronica: XML contro lo schema ufficiale…"
CACHE="$HOME/Library/Caches/Prisma-prove/schemi-fatturapa"
mkdir -p "$CACHE"
XSD_FATTURA="$CACHE/Schema_del_file_xml_FatturaPA_v1.2.2.xsd"
XSD_FIRMA="$CACHE/xmldsig-core-schema.xsd"
scarica() {
  [ -s "$2" ] && grep -q '<[A-Za-z]*:\{0,1\}schema' "$2" && return 0
  curl -fsSL --connect-timeout 20 --max-time 120 -o "$2" "$1" && grep -q '<[A-Za-z]*:\{0,1\}schema' "$2"
}
scarica "https://www.fatturapa.gov.it/export/documenti/fatturapa/v1.2.2/Schema_del_file_xml_FatturaPA_v1.2.2.xsd" "$XSD_FATTURA" \
  || { rm -f "$XSD_FATTURA"; errore "Schema FatturaPA non scaricato (serve la rete la prima volta): XML non verificato"; }
scarica "https://www.w3.org/TR/2002/REC-xmldsig-core-20020212/xmldsig-core-schema.xsd" "$XSD_FIRMA" \
  || { rm -f "$XSD_FIRMA"; errore "Schema delle firme non scaricato (serve la rete la prima volta): XML non verificato"; }
sed -E \
  -e '/<[A-Za-z]*:?import[^>]*xmldsig#/ s|[[:space:]]+schemaLocation="[^"]*"||' \
  -e 's|(<[A-Za-z]*:?import[^>]*namespace="http://www.w3.org/2000/09/xmldsig#")|\1 schemaLocation="xmldsig-core-schema.xsd"|' \
  "$XSD_FATTURA" > "$CACHE/fatturapa-locale.xsd"
grep -q 'schemaLocation="xmldsig-core-schema.xsd"' "$CACHE/fatturapa-locale.xsd" \
  || errore "Import di xmldsig non trovato nello schema FatturaPA"
FATTURE="$(mktemp -d)/fattura"
"$APP/Contents/MacOS/Prisma" --prova-fattura "$FATTURE"
shopt -s nullglob
FILE_XML=("$FATTURE"/*.xml)
[ "${#FILE_XML[@]}" -gt 0 ] || errore "--prova-fattura non ha prodotto file XML"
for f in "${FILE_XML[@]}"; do
  xmllint --noout --nonet --schema "$CACHE/fatturapa-locale.xsd" "$f" || errore "$(basename "$f") non rispetta lo schema FatturaPA 1.2.2"
done
echo "✓ Fatture di esempio valide (${#FILE_XML[@]} file)"

echo "✓ Controlli locali superati"
