#!/usr/bin/env bash
# Assembla a mano Prisma.app per il simulatore iOS (niente .xcodeproj, niente asset catalog).
#
# Uso: Supporto/iOS/assembla.sh <cartella prodotti> <Prisma.app da creare> [simulatore|dispositivo]
#   Il terzo argomento (predefinito: simulatore) sceglie la piattaforma: «dispositivo» prepara il .app
#   per iPhone e iPad veri, da installare con AltStore o Sideloadly (che lo firmano con l'ID Apple).
#   <cartella prodotti>: dove xcodebuild (o swift build --triple …-ios…-simulator) ha messo
#   l'eseguibile Prisma e il bundle delle risorse Prisma_Prisma.bundle
#   (di solito build/ios/Build/Products/Release-iphonesimulator).
#
# Su iOS il bundle è piatto (niente Contents/): eseguibile, Info.plist, Prisma_Prisma.bundle,
# Ruby/Istruzioni e icone stanno nella radice del .app. Bundle.main.resourceURL è la radice
# del .app, quindi Risorse.bundle e MotoriRuby trovano tutto senza modifiche al codice.
set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "Uso: $0 <cartella prodotti> <Prisma.app> [simulatore|dispositivo]" >&2
    exit 2
fi

PROD="$1"
APP="$2"
DESTINAZIONE="${3:-simulatore}"
case "$DESTINAZIONE" in
    simulatore) ATTESA="IOSSIMULATOR"; NUMERO=7; PIATTAFORMA_PLIST="iPhoneSimulator" ;;
    dispositivo) ATTESA="IOS"; NUMERO=2; PIATTAFORMA_PLIST="iPhoneOS" ;;
    *) echo "Destinazione sconosciuta: $DESTINAZIONE" >&2; exit 2 ;;
esac
RADICE="$(cd "$(dirname "$0")/../.." && pwd)"
PLIST_ORIGINE="$RADICE/Supporto/iOS/Info.plist"

errore() { echo "::error::$*" >&2; exit 1; }

echo "Prodotti in $PROD:"
find "$PROD" -maxdepth 2 | head -40 || true

ESEGUIBILE="$PROD/Prisma"
[ -f "$ESEGUIBILE" ] && [ -x "$ESEGUIBILE" ] || errore "Eseguibile Prisma non trovato in $PROD"

# Deve essere un binario iOS della piattaforma scelta (simulatore o dispositivo), non per il Mac
if PIATTAFORMA="$(xcrun vtool -show-build "$ESEGUIBILE" 2>/dev/null)"; then
    echo "$PIATTAFORMA"
    grep -Eq "platform $ATTESA\$|platform $ATTESA[[:space:]]" <<< "$PIATTAFORMA" || errore "Prisma non è compilato per: $DESTINAZIONE"
else
    PIATTAFORMA="$(otool -l "$ESEGUIBILE" | grep -A4 LC_BUILD_VERSION || true)"
    echo "$PIATTAFORMA"
    # In LC_BUILD_VERSION la piattaforma 2 è iOS, la 7 il simulatore iOS
    grep -Eq "platform ($NUMERO|$ATTESA)\$|platform ($NUMERO|$ATTESA)[[:space:]]" <<< "$PIATTAFORMA" || errore "Prisma non è compilato per: $DESTINAZIONE"
fi

rm -rf "$APP"
mkdir -p "$APP"

# Eseguibile e Info.plist
cp "$ESEGUIBILE" "$APP/Prisma"
cp "$PLIST_ORIGINE" "$APP/Info.plist"
if [ -n "${GITHUB_SHA:-}" ]; then
    # Il commit nella diagnostica, come sul Mac
    /usr/libexec/PlistBuddy -c "Add :PrismaCommit string ${GITHUB_SHA:0:7}" "$APP/Info.plist"
fi
# La piattaforma del pacchetto: simulatore o iPhone/iPad veri
/usr/libexec/PlistBuddy -c "Set :CFBundleSupportedPlatforms:0 $PIATTAFORMA_PLIST" "$APP/Info.plist"
# Formato binario, come quello prodotto da Xcode
plutil -convert binary1 "$APP/Info.plist"

# Bundle delle risorse SwiftPM nella radice del .app
trovati=0
for b in "$PROD"/*.bundle; do
    [ -e "$b" ] || continue
    echo "Copio $(basename "$b")"
    ditto "$b" "$APP/$(basename "$b")"
    trovati=1
done
[ "$trovati" = 1 ] || errore "Nessun bundle di risorse in $PROD"

# Istruzioni di Ruby (si leggono da Bundle.main.resourceURL/Ruby/Istruzioni)
if [ -d "$RADICE/Ruby/Istruzioni" ]; then
    mkdir -p "$APP/Ruby"
    ditto "$RADICE/Ruby/Istruzioni" "$APP/Ruby/Istruzioni"
fi
# Schemi (scenari «E se…?») ed esempi per --prova-ruby, accanto alle istruzioni
for cartella in Schemi Esempi; do
    if [ -d "$RADICE/Ruby/$cartella" ]; then
        mkdir -p "$APP/Ruby"
        ditto "$RADICE/Ruby/$cartella" "$APP/Ruby/$cartella"
    fi
done

# Icone senza asset catalog: i nomi coincidono con CFBundleIconFiles di Info.plist
ICONA="$RADICE/Design/Icone/AppIcon.png"
if [ -f "$ICONA" ]; then
    icona() { sips -s format png -z "$1" "$1" "$ICONA" --out "$APP/$2" > /dev/null; }
    icona 120 "AppIcon60x60@2x.png"
    icona 180 "AppIcon60x60@3x.png"
    icona 152 "AppIcon76x76@2x~ipad.png"
    icona 167 "AppIcon83.5x83.5@2x~ipad.png"
else
    echo "Design/Icone/AppIcon.png assente: nessuna icona"
fi

# Firma ad-hoc: il simulatore la accetta; sul dispositivo AltStore o Sideloadly la sostituiscono con l'ID Apple
codesign --force --sign - --timestamp=none "$APP"

# ---- Verifica ----
plutil -lint "$APP/Info.plist"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Info.plist")" = Prisma \
    || errore "CFBundleExecutable diverso da Prisma"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")" = local.prisma \
    || errore "CFBundleIdentifier diverso da local.prisma"
test -x "$APP/Prisma" || errore "Eseguibile mancante nel .app"

if [ -d "$RADICE/Sources/Prisma/Risorse" ]; then
    BUNDLE="$APP/Prisma_Prisma.bundle"
    test -d "$BUNDLE" || errore "Prisma_Prisma.bundle mancante nel .app"
    # Xcode per iOS fa un bundle piatto; swift build potrebbe usare Contents/Resources: vanno bene entrambi
    RIS="$BUNDLE/Risorse"
    [ -d "$RIS" ] || RIS="$BUNDLE/Contents/Resources/Risorse"
    if [ ! -d "$RIS" ]; then
        echo "Struttura inattesa del bundle:"
        find "$BUNDLE" | head -40 || true
        errore "Cartella Risorse non trovata in Prisma_Prisma.bundle"
    fi
    mancanti=0
    while read -r f; do
        if [ ! -f "$RIS/$f" ]; then
            echo "Manca Risorse/$f nel .app"
            mancanti=$((mancanti + 1))
        fi
    done < <(cd "$RADICE/Sources/Prisma/Risorse" && find . -type f ! -name '.*')
    [ "$mancanti" = 0 ] || errore "$mancanti risorse mancanti nel .app"
fi

if [ -d "$RADICE/Ruby/Istruzioni" ]; then
    test -f "$APP/Ruby/Istruzioni/chat.md" || errore "Ruby/Istruzioni/chat.md mancante"
    test -f "$APP/Ruby/Istruzioni/commento.md" || errore "Ruby/Istruzioni/commento.md mancante"
    test -f "$APP/Ruby/Istruzioni/conversazione.md" || errore "Ruby/Istruzioni/conversazione.md mancante"
    test -f "$APP/Ruby/Istruzioni/mini.md" || errore "Ruby/Istruzioni/mini.md mancante"
    test -f "$APP/Ruby/Istruzioni/scenari.md" || errore "Ruby/Istruzioni/scenari.md mancante"
    test -f "$APP/Ruby/Istruzioni/messaggi.md" || errore "Ruby/Istruzioni/messaggi.md mancante"
    test -f "$APP/Ruby/Schemi/scenario.json" || errore "Ruby/Schemi/scenario.json mancante"
    test -f "$APP/Ruby/Istruzioni/copilota.md" || errore "Ruby/Istruzioni/copilota.md mancante"
    test -f "$APP/Ruby/Schemi/copilota.json" || errore "Ruby/Schemi/copilota.json mancante"
    test -f "$APP/Ruby/Istruzioni/verbale-copilota.md" || errore "Ruby/Istruzioni/verbale-copilota.md mancante"
fi

codesign --verify --strict --verbose=2 "$APP"
du -sh "$APP"
echo "Prisma.app per iOS ($DESTINAZIONE) assemblata e verificata"
