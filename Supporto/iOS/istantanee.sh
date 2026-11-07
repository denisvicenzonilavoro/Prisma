#!/usr/bin/env bash
# Istantanee di Prisma nel simulatore iOS con `simctl io screenshot` (fedele: vetro, ombre, barre).
#
# Uso: Supporto/iOS/istantanee.sh <udid> <cartella uscita> [elenco scene]
#   Crea <cartella uscita>/chiaro/*.png e <cartella uscita>/scuro/*.png.
#   [elenco scene]: facoltativo, nomi separati da virgole passati all'app così come sono.
#
# Sincronizzazione a file tra app e script (un solo avvio per aspetto, nessun riavvio per scena):
#   1. lo script avvia Prisma con --istantanee-ios [elenco];
#   2. per ogni scena l'app la mostra, aspetta che il disegno nuovo sia fermo e scrive (in modo atomico)
#      Documents/scena-pronta.txt: nella prima riga il nome della scena (es. «1-benvenuto»), poi
#      «richiesto=verticale|orizzontale», «disegno=diritto|girato», «fascia-alta=<pixel>» e
#      «uguale-alla-precedente=si|no»;
#   3. lo script legge il nome, cancella scena-pronta.txt, scatta <nome>.png e crea
#      Documents/scatto-fatto.txt;
#   4. l'app aspetta scatto-fatto.txt, lo cancella e passa alla scena successiva;
#   5. alla fine l'app scrive Documents/esito-istantanee-ios.txt («OK» o «ERRORE …») ed esce.
# Prisma resta sull'aspetto «automatico»: chiaro e scuro li sceglie `simctl ui appearance`.
#
# Le scene orizzontali dell'iPad: il simulatore resta in verticale (in iPadOS 26 la rotazione chiesta dall'app
# rimpicciolisce la finestra invece di girare lo schermo, e UIRequiresFullScreen è ignorato). L'app dispone Prisma
# in un riquadro orizzontale sotto la barra di stato e lo disegna girato di 90° in senso antiorario
# (RadiceRuotataIstantanea in Sources/Prisma/iOS/IstantaneeMobile.swift, «disegno=girato»): qui si toglie la fascia
# alta della barra di stato («fascia-alta», in pixel) e si gira la PNG di 90° in senso orario.
set -o pipefail

if [ $# -lt 2 ]; then
    echo "Uso: $0 <udid> <cartella uscita> [elenco scene]" >&2
    exit 2
fi

UDID="$1"
USCITA="$2"
ELENCO="${3:-}"
BID="${PRISMA_BID:-local.prisma}"
ATTESA_PRIMA="${PRISMA_ATTESA_PRIMA:-180}"   # secondi per la prima scena (primo avvio, dati di prova)
# Secondi per ciascuna delle altre. Non 60: la prima schermata pesante disegnata a freddo (sull'iPad «3-clienti»,
# nel primo aspetto) sul simulatore della build richiede da 36 a oltre 60 s (6 s nel secondo aspetto, a caldo);
# con 60 s lo script smetteva di aspettare mentre l'app stava ancora disegnando e l'aspetto falliva.
ATTESA_SCENA="${PRISMA_ATTESA_SCENA:-150}"
MAX_SCENE=200

DATI="$(xcrun simctl get_app_container "$UDID" "$BID" data)" || {
    echo "::error::Contenitore dati di $BID non trovato: l'app è installata?"
    exit 1
}
DOC="$DATI/Documents"
mkdir -p "$DOC"

# Barra di stato fissa: le istantanee di due build si confrontano senza differenze inutili
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 || true

ERRORI=0

# dimensioni <png>: «larghezza altezza» in pixel (sips c'è su ogni Mac)
dimensioni() {
    sips -g pixelWidth -g pixelHeight "$1" 2>/dev/null | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w+0, h+0}'
}

# controlla_scatto <aspetto> <nome> <png> <richiesto> <disegno> <fascia>: raddrizza la PNG di una scena disegnata
# girata (toglie la fascia della barra di stato in alto e gira di 90° in senso orario) e segnala (avvisi, non
# errori) le scene orizzontali rimaste verticali e le PNG uguali alla precedente (PRECEDENTE: «impronta nome»).
PRECEDENTE=""
controlla_scatto() {
    local aspetto="$1" nome="$2" png="$3" richiesto="$4" disegno="$5" fascia="${6:-0}" w h
    read -r w h <<< "$(dimensioni "$png")"
    if [ "$disegno" = girato ] && [ "${w:-0}" -gt 0 ] && [ "$w" -lt "$h" ]; then
        case "$fascia" in ''|*[!0-9]*) fascia=0 ;; esac
        if [ "$fascia" -gt 0 ] && [ "$fascia" -lt "$h" ]; then
            # Via la barra di stato: resta solo il disegno di Prisma (dall'alto in giù, larghezza intera)
            if sips -c $((h - fascia)) "$w" --cropOffset "$fascia" 0 "$png" > /dev/null 2>&1; then
                read -r w h <<< "$(dimensioni "$png")"
            else
                echo "::warning::Istantanea $aspetto/$nome: fascia della barra di stato non tolta (sips --cropOffset)"
            fi
        fi
        # Il lato alto della scena è a sinistra: sips gira in senso orario
        sips -r 90 "$png" > /dev/null 2>&1 && read -r w h <<< "$(dimensioni "$png")"
    fi
    if [ "$richiesto" = orizzontale ] && ! [ "${w:-0}" -gt "${h:-0}" ]; then
        echo "::warning::Istantanea $aspetto/$nome: chiesta in orizzontale ma è ${w}×${h} (disegno: ${disegno:-sconosciuto})"
    fi
    local impronta
    impronta="$(shasum -a 256 "$png" 2>/dev/null | cut -d' ' -f1)"
    if [ -n "$impronta" ] && [ "$impronta" = "${PRECEDENTE%% *}" ]; then
        echo "::warning::Istantanea $aspetto/$nome identica alla precedente (${PRECEDENTE#* }): la scena non è cambiata sullo schermo"
    fi
    PRECEDENTE="$impronta $nome"
}

# aspetta_file <file> <secondi> <pid>: 0 se il file compare, 1 se scade il tempo o l'app esce
aspetta_file() {
    local file="$1" limite="$2" pid="$3" inizio=$SECONDS
    while [ $((SECONDS - inizio)) -lt "$limite" ]; do
        [ -s "$file" ] && return 0
        # L'app ha finito (o si è chiusa): il file non arriverà più
        [ -f "$DOC/esito-istantanee-ios.txt" ] && return 1
        kill -0 "$pid" 2>/dev/null || { [ -s "$file" ] && return 0; return 1; }
        sleep 0.3
    done
    return 1
}

scatta_aspetto() {
    local aspetto="$1" cartella="$2"
    # Il registro dell'app resta fuori dalle anteprime pubblicate
    local registro="${RUNNER_TEMP:-/tmp}/istantanee-$UDID-$aspetto.log"
    mkdir -p "$cartella"
    rm -f "$DOC/scena-pronta.txt" "$DOC/scatto-fatto.txt" "$DOC/esito-istantanee-ios.txt"

    xcrun simctl ui "$UDID" appearance "$aspetto"
    sleep 1

    local argomenti=(--istantanee-ios)
    [ -n "$ELENCO" ] && argomenti+=("$ELENCO")

    # In background con la console: l'uscita dell'app finisce nel registro (utile se si chiude)
    xcrun simctl launch --console-pty --terminate-running-process "$UDID" "$BID" "${argomenti[@]}" \
        < /dev/null > "$registro" 2>&1 &
    local pid=$!

    local n=0 attesa="$ATTESA_PRIMA"
    PRECEDENTE=""
    while [ "$n" -lt "$MAX_SCENE" ]; do
        if ! aspetta_file "$DOC/scena-pronta.txt" "$attesa" "$pid"; then
            break
        fi
        local nome contenuto richiesto disegno fascia
        contenuto="$(tr -d '\r' < "$DOC/scena-pronta.txt")"
        nome="$(printf '%s\n' "$contenuto" | head -1 | tr -c 'A-Za-z0-9._-' '_' | sed 's/_*$//')"
        richiesto="$(printf '%s\n' "$contenuto" | sed -n 's/^richiesto=//p' | head -1)"
        disegno="$(printf '%s\n' "$contenuto" | sed -n 's/^disegno=//p' | head -1)"
        fascia="$(printf '%s\n' "$contenuto" | sed -n 's/^fascia-alta=//p' | head -1)"
        rm -f "$DOC/scena-pronta.txt"
        [ -n "$nome" ] || nome="scena-$n"
        if xcrun simctl io "$UDID" screenshot --type=png "$cartella/$nome.png" > /dev/null 2>&1; then
            echo "  $aspetto/$nome.png"
            controlla_scatto "$aspetto" "$nome" "$cartella/$nome.png" "$richiesto" "$disegno" "$fascia"
        else
            echo "::warning::Scatto non riuscito: $aspetto/$nome"
            ERRORI=$((ERRORI + 1))
        fi
        echo "$nome" > "$DOC/scatto-fatto.txt"
        n=$((n + 1))
        attesa="$ATTESA_SCENA"
    done

    # L'app scrive l'esito ed esce; se resta appesa la si chiude
    local inizio=$SECONDS
    while kill -0 "$pid" 2>/dev/null && [ $((SECONDS - inizio)) -lt 30 ]; do sleep 0.5; done
    if kill -0 "$pid" 2>/dev/null; then
        xcrun simctl terminate "$UDID" "$BID" 2>/dev/null || true
        kill "$pid" 2>/dev/null || true
    fi
    wait "$pid" 2>/dev/null

    local esito="$DOC/esito-istantanee-ios.txt"
    if [ "$n" -gt 0 ] && [ -f "$esito" ] && head -1 "$esito" | grep -q '^OK'; then
        echo "Istantanee $aspetto: $n scene"
    else
        echo "::error::Istantanee $aspetto non riuscite ($n scene scattate): $(head -c 400 "$esito" 2>/dev/null || echo 'nessun esito scritto')"
        echo "Ultime righe dell'app:"
        tail -40 "$registro" || true
        ERRORI=$((ERRORI + 1))
    fi
}

mkdir -p "$USCITA"
scatta_aspetto light "$USCITA/chiaro"
scatta_aspetto dark "$USCITA/scuro"
xcrun simctl ui "$UDID" appearance light || true
xcrun simctl status_bar "$UDID" clear || true

ls -la "$USCITA" "$USCITA/chiaro" "$USCITA/scuro" 2>/dev/null || true
[ "$ERRORI" = 0 ] || exit 1
