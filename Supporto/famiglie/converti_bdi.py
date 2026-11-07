#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Converte le tavole pubblicate della Banca d'Italia nel file delle tabelle delle famiglie di Prisma.

Fonte: Banca d'Italia, «Indagine sui bilanci delle famiglie italiane», edizione 2022, tavole cross-section
pubblicate (file Excel «tavole_cross_section.xlsx», aggiornamento ottobre 2025), scaricate a mano dal sito della
Banca d'Italia. Gli xlsx NON stanno nel repository: si scaricano, si passa il percorso a questo script e si
mette nel repository solo il JSON che esce.

Uso (Python 3 con openpyxl; -I isola l'interprete dalla cartella dei file scaricati):

    python3 -I Supporto/famiglie/converti_bdi.py percorso/tavole_cross_section.xlsx \
        Sources/Prisma/Risorse/famiglie-bdi-2022.json

Il risultato è un file «prisma-famiglie» versione 2 (Design/famiglie-formato.md): tavole a una dimensione, perché
le tavole pubblicate danno le cifre per una caratteristica del capofamiglia alla volta, non incrociate età × reddito.

Che cosa prende, e da dove (righe «Età» e «Quinti di famiglie rispetto al reddito netto familiare»):
- T4  «Reddito e consumi familiari medi»: reddito medio, consumi medi e propensione al consumo (%). Il tasso di
      risparmio del gruppo è 100 − propensione al consumo: è un RAPPORTO TRA MEDIE (risparmio medio del gruppo
      diviso reddito medio del gruppo), non la media dei tassi delle singole famiglie → statistica «rapportoTraMedie».
- T17 «Valori mediani della ricchezza familiare»: mediana delle attività finanziarie e della ricchezza netta
      → statistica «mediana».
- T23 «Forme assicurative e pensioni integrative possedute dalle famiglie»: % di famiglie con polizze vita e con
      pensioni integrative → statistica «quota». Le tavole non hanno le polizze danni.
- T7  «Quinti di famiglie rispetto al reddito familiare»: i valori di ripartizione dei quinti (euro del 2022), che
      diventano gli estremi delle classi di reddito.
- T15 «Quinti e decimi di famiglie rispetto alla ricchezza netta familiare»: i valori di ripartizione dei decimi,
      cioè i quantili p10…p90 della ricchezza netta di TUTTE le famiglie (non per età né per reddito) → gruppo
      «tutte», statistica «quantili».
- T29 «Contatti per le interviste effettuate»: il numero di famiglie intervistate in ogni classe (colonna
      «Famiglie»), per la soglia del campione piccolo.

Le caratteristiche sono quelle del capofamiglia, che per l'indagine è il maggior percettore di reddito della
famiglia. Lo script controlla i titoli delle tavole e delle colonne: se la Banca d'Italia cambia l'impaginazione
si ferma con un errore invece di scrivere cifre sbagliate. Non scarica nulla e non esegue nulla dai file: li legge.
"""

import json
import sys

try:
    import openpyxl
except ImportError:  # pragma: no cover
    sys.exit("Serve openpyxl: pip install openpyxl")

FONTE = ("Banca d'Italia, Indagine sui bilanci delle famiglie italiane, edizione 2022 "
         "(tavole pubblicate, aggiornamento ottobre 2025)")
EDIZIONE = 2022
AGGIORNAMENTO = "ottobre 2025"

# Le classi d'età delle tavole (anni compiuti del capofamiglia, estremi inclusi)
ETA = [
    ("fino a 34 anni", "eta-1", "fino a 34 anni", None, 34),
    ("da 35 a 44 anni", "eta-2", "35-44 anni", 35, 44),
    ("da 45 a 54 anni", "eta-3", "45-54 anni", 45, 54),
    ("da 55 a 64 anni", "eta-4", "55-64 anni", 55, 64),
    ("oltre 64 anni", "eta-5", "65 anni e più", 65, None),
]
QUINTI = ["1 quinto", "2 quinto", "3 quinto", "4 quinto", "5 quinto"]
SEZIONE_ETA = "Età"
SEZIONE_QUINTI = "Quinti di famiglie rispetto al reddito netto familiare"


class ErroreTavola(Exception):
    pass


def testo(c):
    """Il testo di una cella, senza spazi duri né spazi ai lati."""
    return "" if c is None else str(c).replace("\xa0", " ").strip()


def righe(wb, nome):
    if nome not in wb.sheetnames:
        raise ErroreTavola(f"manca il foglio «{nome}»")
    return [list(r) for r in wb[nome].iter_rows(values_only=True)]


def controlla_titolo(rr, foglio, atteso):
    titolo = testo(rr[0][0]) if rr and rr[0] else ""
    if atteso.lower() not in titolo.lower():
        raise ErroreTavola(f"{foglio}: titolo «{titolo}», atteso «{atteso}»")


def colonna(rr, foglio, intestazione):
    """L'indice della colonna con questa intestazione (nelle prime righe della tavola)."""
    for r in rr[:5]:
        for i, c in enumerate(r):
            if testo(c).lower().startswith(intestazione.lower()):
                return i
    raise ErroreTavola(f"{foglio}: manca la colonna «{intestazione}»")


def numero(v, dove):
    if isinstance(v, bool) or not isinstance(v, (int, float)):
        raise ErroreTavola(f"{dove}: «{v}» non è un numero")
    return float(v)


def sezione(rr, foglio, titolo_sezione, etichette, colonne):
    """Le righe di una sezione («Età», «Quinti…»): {etichetta: [valori delle colonne]}, nell'ordine dato."""
    inizio = None
    for i, r in enumerate(rr):
        if testo(r[0]).startswith(titolo_sezione):
            inizio = i
            break
    if inizio is None:
        raise ErroreTavola(f"{foglio}: manca la sezione «{titolo_sezione}»")
    trovate = {}
    for r in rr[inizio + 1: inizio + 1 + len(etichette)]:
        trovate[testo(r[0])] = r
    esito = {}
    for e in etichette:
        if e not in trovate:
            raise ErroreTavola(f"{foglio}, sezione «{titolo_sezione}»: manca la riga «{e}»")
        esito[e] = [numero(trovate[e][c], f"{foglio}, «{e}»") for c in colonne]
    return esito


def riga_totale(rr, foglio, colonne):
    for r in rr:
        if testo(r[0]) == "Totale":
            return [numero(r[c], f"{foglio}, «Totale»") for c in colonne]
    raise ErroreTavola(f"{foglio}: manca la riga «Totale»")


def ripartizione(rr, foglio, titolo_sezione, quante):
    """I valori di ripartizione (euro) di una sezione di quinti o decimi: le prime `quante` righe dopo il titolo."""
    inizio = None
    for i, r in enumerate(rr):
        if testo(r[0]).startswith(titolo_sezione):
            inizio = i
            break
    if inizio is None:
        raise ErroreTavola(f"{foglio}: manca la sezione «{titolo_sezione}»")
    valori = []
    for r in rr[inizio + 1: inizio + 1 + quante]:
        valori.append(numero(r[1], f"{foglio}, «{testo(r[0])}»"))
    if any(b <= a for a, b in zip(valori, valori[1:])):
        raise ErroreTavola(f"{foglio}: i valori di ripartizione non crescono")
    return valori


def intero(v):
    return int(round(v))


def euro(v):
    """«37.121» (punto delle migliaia, come le tavole)."""
    return f"{intero(v):,}".replace(",", ".")


def decimale(v):
    """«71,3»"""
    return f"{v:.1f}".replace(".", ",")


def converti(percorso):
    wb = openpyxl.load_workbook(percorso, read_only=True, data_only=True)
    indice = righe(wb, "Indice")
    titolo = testo(indice[0][0]) if indice and indice[0] else ""
    if "Edizione 2022" not in titolo or "ottobre 2025" not in titolo:
        raise ErroreTavola(f"Indice: «{titolo}», attesa l'edizione 2022 aggiornata a ottobre 2025")

    # T4: reddito medio, consumi medi, propensione al consumo
    t4 = righe(wb, "tav.T4")
    controlla_titolo(t4, "T4", "Reddito e consumi familiari medi")
    c4 = [colonna(t4, "T4", "Reddito familiare"), colonna(t4, "T4", "Consumi familiari"),
          colonna(t4, "T4", "Propensione al consumo")]
    t4_eta = sezione(t4, "T4", SEZIONE_ETA, [e[0] for e in ETA], c4)
    t4_quinti = sezione(t4, "T4", SEZIONE_QUINTI, QUINTI, c4)

    # T17: mediane delle attività finanziarie e della ricchezza netta
    t17 = righe(wb, "tav.T17")
    controlla_titolo(t17, "T17", "Valori mediani della ricchezza familiare")
    c17 = [colonna(t17, "T17", "Attività finanziarie"), colonna(t17, "T17", "Ricchezza netta")]
    t17_eta = sezione(t17, "T17", SEZIONE_ETA, [e[0] for e in ETA], c17)
    t17_quinti = sezione(t17, "T17", SEZIONE_QUINTI, QUINTI, c17)

    # T23: % di famiglie con polizze vita e pensioni integrative
    t23 = righe(wb, "tav.T23")
    controlla_titolo(t23, "T23", "Forme assicurative e pensioni integrative")
    c23 = [colonna(t23, "T23", "Polizze vita"), colonna(t23, "T23", "Pensioni integrative")]
    t23_eta = sezione(t23, "T23", SEZIONE_ETA, [e[0] for e in ETA], c23)
    t23_quinti = sezione(t23, "T23", SEZIONE_QUINTI, QUINTI, c23)

    # T29: famiglie intervistate per classe
    t29 = righe(wb, "tav.T29")
    controlla_titolo(t29, "T29", "Contatti per le interviste")
    c29 = [colonna(t29, "T29", "Famiglie")]
    t29_eta = sezione(t29, "T29", SEZIONE_ETA, [e[0] for e in ETA], c29)
    t29_quinti = sezione(t29, "T29", SEZIONE_QUINTI, QUINTI, c29)
    t29_totale = riga_totale(t29, "T29", c29)[0]

    # T7: valori di ripartizione dei quinti di reddito (euro del 2022)
    t7 = righe(wb, "tav.T7")
    controlla_titolo(t7, "T7", "Quinti di famiglie rispetto al reddito familiare")
    soglie = ripartizione(t7, "T7", "Quinti di famiglie rispetto al reddito netto familiare", 4)

    # T15: valori di ripartizione dei decimi della ricchezza netta (tutte le famiglie)
    t15 = righe(wb, "tav.T15")
    controlla_titolo(t15, "T15", "Quinti di famiglie rispetto alla ricchezza familiare netta")
    decimi = ripartizione(t15, "T15", "Decimi di famiglie rispetto alla ricchezza netta", 9)

    def voci(r4, r17, r23):
        reddito, consumi, propensione = r4
        finanziarie, netta = r17
        vita, integrative = r23
        risparmio = round(100 - propensione, 1)
        if not -100 <= risparmio <= 100:
            raise ErroreTavola(f"T4: tasso di risparmio {risparmio} fuori scala")
        return {
            "tassoRisparmio": {
                "statistica": "rapportoTraMedie", "valore": risparmio, "tavola": "T4",
                "nota": (f"100 − propensione al consumo ({decimale(propensione)}%): reddito medio {euro(reddito)} €, "
                         f"consumi medi {euro(consumi)} €"),
            },
            "ricchezzaFinanziaria": {"statistica": "mediana", "valore": intero(finanziarie), "tavola": "T17"},
            "ricchezzaNetta": {"statistica": "mediana", "valore": intero(netta), "tavola": "T17"},
            "protezione": {"statistica": "quota", "valore": vita, "tavola": "T23",
                           "nota": "famiglie con polizze vita (le tavole non hanno le polizze danni)"},
            "previdenzaComplementare": {"statistica": "quota", "valore": integrative, "tavola": "T23",
                                        "nota": "famiglie con pensioni integrative"},
        }

    classi_eta = []
    for etichetta, ident, nome, da, a in ETA:
        c = {"id": ident, "nome": nome}
        if da is not None:
            c["da"] = da
        if a is not None:
            c["a"] = a
        c["famiglie"] = intero(t29_eta[etichetta][0])
        c["voci"] = voci(t4_eta[etichetta], t17_eta[etichetta], t23_eta[etichetta])
        classi_eta.append(c)

    classi_reddito = []
    for i, etichetta in enumerate(QUINTI):
        c = {"id": f"quinto-{i + 1}", "nome": f"{i + 1}° quinto"}
        if i > 0:
            c["da"] = intero(soglie[i - 1])
        if i < 4:
            c["a"] = intero(soglie[i])
        c["famiglie"] = intero(t29_quinti[etichetta][0])
        c["voci"] = voci(t4_quinti[etichetta], t17_quinti[etichetta], t23_quinti[etichetta])
        classi_reddito.append(c)

    quantili = {f"p{(k + 1) * 10}": intero(v) for k, v in enumerate(decimi)}

    return {
        "formato": "prisma-famiglie",
        "versione": 2,
        "diProva": False,
        "fonte": FONTE,
        "edizione": EDIZIONE,
        "aggiornamento": AGGIORNAMENTO,
        "licenza": ("Dati pubblicati dalla Banca d'Italia sul suo sito, ripresi citando la fonte. Le cifre sono "
                    "quelle delle tavole, tranne il tasso di risparmio, calcolato come 100 − propensione al "
                    "consumo (T4)."),
        "note": ("Tavole pubblicate, una caratteristica del capofamiglia alla volta (età oppure quinto di reddito), "
                 "non incrociate. Il capofamiglia è il maggior percettore di reddito della famiglia. Redditi, consumi "
                 "e ricchezza in euro dell'anno 2022, non rivalutati; reddito familiare netto. Famiglie: quelle "
                 "intervistate in ogni classe (tavola T29). Convertite con Supporto/famiglie/converti_bdi.py."),
        "sogliaFamiglie": 30,
        "descrizioni": {
            "tassoRisparmio": ("risparmio in % del reddito familiare netto: 100 − propensione al consumo (T4), cioè "
                               "il rapporto tra il risparmio medio e il reddito medio del gruppo"),
            "ricchezzaFinanziaria": ("mediana delle attività finanziarie della famiglia (depositi, titoli di Stato, "
                                     "azioni, ecc.), euro (T17)"),
            "ricchezzaNetta": ("ricchezza netta: attività reali e finanziarie meno i debiti, euro; mediana per "
                               "gruppo (T17) e decimi di tutte le famiglie (T15)"),
            "protezione": "% di famiglie con polizze vita (T23); le tavole non hanno le polizze danni",
            "previdenzaComplementare": "% di famiglie con pensioni integrative (T23)",
        },
        "gruppi": [
            {"id": "eta", "dimensione": "eta", "nome": "Età del capofamiglia",
             "nota": "Classi d'età delle tavole T4, T17, T23 e T29.", "classi": classi_eta},
            {"id": "reddito", "dimensione": "reddito", "nome": "Quinti di reddito familiare netto",
             "nota": ("Estremi dei quinti: valori di ripartizione della tavola T7 (euro del 2022, da incluso, "
                      "a escluso)."),
             "classi": classi_reddito},
            {"id": "tutte", "dimensione": "tutte", "nome": "Tutte le famiglie italiane",
             "nota": ("Solo la ricchezza netta: decimi di tutte le famiglie (tavola T15), non per età né per "
                      "reddito."),
             "classi": [{"id": "tutte", "nome": "tutte le famiglie", "famiglie": intero(t29_totale),
                         "voci": {"ricchezzaNetta": {
                             "statistica": "quantili", "quantili": quantili, "tavola": "T15",
                             "nota": "valori di ripartizione dei decimi di famiglie rispetto alla ricchezza netta"}}}]},
        ],
    }


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    try:
        tabelle = converti(argv[1])
    except ErroreTavola as e:
        print(f"Tavole non riconosciute: {e}", file=sys.stderr)
        return 1
    with open(argv[2], "w", encoding="utf-8") as f:
        json.dump(tabelle, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(f"Scritto {argv[2]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
