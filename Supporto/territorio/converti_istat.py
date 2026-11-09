#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Prepara le tabelle del Territorio di Prisma («Luce» giro 11): comuni con coordinate e confini semplificati.

Due usi (Python 3, solo libreria standard; -I isola l'interprete dalla cartella dei file scaricati):

1) La tabella vera, dai file ISTAT scaricati A MANO da istat.it (licenza CC BY 4.0):
   - «Elenco dei codici e delle denominazioni delle unità territoriali» (CSV, separatore «;»);
   - «Confini delle unità amministrative a fini statistici», versione generalizzata (zip con Com…_g_WGS84.shp/.dbf).

       python3 -I Supporto/territorio/converti_istat.py \
           --elenco percorso/Elenco-comuni-italiani.csv \
           --confini percorso/Com01012025_g_WGS84.shp \
           Sources/Prisma/Risorse/Territorio/

   Facoltativi: --province BO,MO,FI (solo queste sigle), --tolleranza 150 (metri, Douglas-Peucker),
   --campo-codice PRO_COM_T (il campo del codice del comune nel .dbf).

2) La tabella ridotta DI PROVA (32 comuni con coordinate approssimate a mano, confini a ottagono irregolare):

       python3 -I Supporto/territorio/converti_istat.py --tabella-di-prova Sources/Prisma/Risorse/Territorio/

   È riproducibile (stesso risultato a ogni esecuzione) e dichiarata «diProva»: Prisma mostra «dati di prova».

Controllo delle formule UTM → lat/lon su punti noti: python3 -I Supporto/territorio/converti_istat.py --verifica

Regole (decisione 70 e scelte dell'utente dell'8 novembre 2026):
- NIENTE CAP e NIENTE codice catastale: la colonna del codice catastale dell'elenco si ignora.
- Il codice di un comune è «<SIGLA>-<nome normalizzato>» (per esempio «BO-bologna»), lo stesso nella tabella di prova
  e in quella vera, perché zone e partenza dell'utente non si perdano al cambio di tabella. Il codice ISTAT va in una
  settima colonna facoltativa «istat», solo informativa.
- I file ISTAT NON entrano nel repository: solo i JSON prodotti. Lo script non scarica nulla: legge i file che gli dai.
"""

import argparse
import csv
import io
import json
import math
import os
import struct
import sys
import unicodedata
import zlib

COLONNE = ["codice", "nome", "provincia", "lat", "lon", "raggioKm"]

# DATI DI PROVA: coordinate approssimate a mano e arrotondate al centesimo di grado, raggi indicativi. Non ISTAT.
COMUNI_DI_PROVA = [
    ("Bologna", "BO", 44.49, 11.34, 7), ("Torino", "TO", 45.07, 7.69, 6), ("Verona", "VR", 45.44, 10.99, 8),
    ("Padova", "PD", 45.41, 11.88, 5), ("Trento", "TN", 46.07, 11.12, 8), ("Milano", "MI", 45.46, 9.19, 7),
    ("Vicenza", "VI", 45.55, 11.55, 5), ("Trieste", "TS", 45.65, 13.78, 5), ("Treviso", "TV", 45.67, 12.24, 4),
    ("Siena", "SI", 43.32, 11.33, 6), ("Salerno", "SA", 40.68, 14.77, 4), ("Roma", "RM", 41.90, 12.50, 20),
    ("Rimini", "RN", 44.06, 12.57, 6), ("Pescara", "PE", 42.46, 14.21, 4), ("Perugia", "PG", 43.11, 12.39, 11),
    ("Palermo", "PA", 38.12, 13.36, 7), ("Napoli", "NA", 40.85, 14.27, 6), ("Modena", "MO", 44.65, 10.93, 7),
    ("Lecco", "LC", 45.85, 9.39, 3), ("Lecce", "LE", 40.35, 18.17, 9), ("Latina", "LT", 41.47, 12.90, 9),
    ("Genova", "GE", 44.41, 8.93, 9), ("Firenze", "FI", 43.77, 11.26, 5), ("Cuneo", "CN", 44.38, 7.54, 6),
    ("Como", "CO", 45.81, 9.09, 3), ("Catania", "CT", 37.50, 15.09, 7), ("Brescia", "BS", 45.54, 10.22, 5),
    ("Bergamo", "BG", 45.70, 9.67, 3), ("Bari", "BA", 41.12, 16.87, 6), ("Asti", "AT", 44.90, 8.21, 7),
    ("Samone", "TO", 45.45, 7.84, 1.5), ("Samone", "TN", 46.08, 11.52, 2),
]

NOTA_DI_PROVA = ("DATI DI PROVA: 32 comuni con coordinate approssimate a mano, arrotondate al centesimo di grado, e raggi "
                 "indicativi; non vengono da ISTAT. I confini sono ottagoni irregolari semplificati di prova. La tabella vera "
                 "si genera con Supporto/territorio/converti_istat.py dai file ISTAT scaricati a mano (CC BY 4.0).")


def normalizza(testo):
    """«Sant'Ilario d'Enza» → «santilariodenza»: minuscole, senza accenti, solo lettere e cifre (come
    `TabellaTerritorio.normalizza` in Swift)."""
    scomposto = unicodedata.normalize("NFKD", testo)
    senza_accenti = "".join(ch for ch in scomposto if not unicodedata.combining(ch)).lower()
    return "".join(ch for ch in senza_accenti if ch.isalnum())


def codice_comune(nome, sigla):
    return "%s-%s" % (sigla.upper(), normalizza(nome))


def km_in_gradi(lat, dlat_km, dlon_km):
    return dlat_km / 111.32, dlon_km / (111.32 * max(0.01, math.cos(math.radians(lat))))


def ottagono_di_prova(nome, sigla, lat, lon, raggio_km):
    """Un ottagono irregolare attorno al centro: raggi fra 0,8 e 1,2 × raggio, irregolarità deterministica dal nome."""
    seme = zlib.crc32(("%s|%s" % (sigla, nome)).encode("utf-8"))
    anello = []
    for k in range(8):
        seme = (seme * 1103515245 + 12345) & 0x7FFFFFFF
        fattore = 0.8 + 0.4 * (seme / 0x7FFFFFFF)
        angolo = 2 * math.pi * k / 8 + math.pi / 8
        dlat, dlon = km_in_gradi(lat, raggio_km * fattore * math.sin(angolo), raggio_km * fattore * math.cos(angolo))
        anello += [round(lat + dlat, 4), round(lon + dlon, 4)]
    anello += anello[:2]  # anello chiuso
    return anello


def scrivi_json(percorso, oggetto):
    os.makedirs(os.path.dirname(percorso), exist_ok=True)
    with open(percorso, "w", encoding="utf-8") as f:
        json.dump(oggetto, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")
    return os.path.getsize(percorso)


def tabella_di_prova(uscita):
    righe = [[codice_comune(n, s), n, s, lat, lon, r] for (n, s, lat, lon, r) in COMUNI_DI_PROVA]
    comuni = {"formato": "prisma-comuni", "versione": 1, "diProva": True,
              "fonte": "Dati di prova: 32 comuni con coordinate approssimate a mano (non ISTAT)",
              "licenza": "", "edizione": "prova-2026-11", "nota": NOTA_DI_PROVA,
              "colonne": COLONNE, "comuni": righe}
    peso = scrivi_json(os.path.join(uscita, "comuni.json"), comuni)
    province = {}
    for (n, s, lat, lon, r) in COMUNI_DI_PROVA:
        province.setdefault(s, {})[codice_comune(n, s)] = [ottagono_di_prova(n, s, lat, lon, r)]
    for sigla in sorted(province):
        peso += scrivi_json(os.path.join(uscita, "confini", "%s.json" % sigla),
                            {"provincia": sigla, "diProva": True, "nota": "confini semplificati di prova",
                             "comuni": province[sigla]})
    print("Tabella di prova: %d comuni, %d province, %d byte" % (len(righe), len(province), peso))


# MARK: - UTM 32N (EPSG:32632) ↔ lat/lon, serie di Krüger (precisione sub-millimetrica nella zona)

A_ELL = 6378137.0
F_ELL = 1 / 298.257223563
K0 = 0.9996
E0 = 500000.0
N_ELL = F_ELL / (2 - F_ELL)
A_RETT = A_ELL / (1 + N_ELL) * (1 + N_ELL ** 2 / 4 + N_ELL ** 4 / 64)
ALFA = [N_ELL / 2 - 2 * N_ELL ** 2 / 3 + 5 * N_ELL ** 3 / 16, 13 * N_ELL ** 2 / 48 - 3 * N_ELL ** 3 / 5, 61 * N_ELL ** 3 / 240]
BETA = [N_ELL / 2 - 2 * N_ELL ** 2 / 3 + 37 * N_ELL ** 3 / 96, N_ELL ** 2 / 48 + N_ELL ** 3 / 15, 17 * N_ELL ** 3 / 480]
DELTA = [2 * N_ELL - 2 * N_ELL ** 2 / 3 - 2 * N_ELL ** 3, 7 * N_ELL ** 2 / 3 - 8 * N_ELL ** 3 / 5, 56 * N_ELL ** 3 / 15]


def utm_in_latlon(est, nord, zona=32):
    lon0 = math.radians(zona * 6 - 183)
    xi = nord / (K0 * A_RETT)
    eta = (est - E0) / (K0 * A_RETT)
    xi1 = xi - sum(BETA[j] * math.sin(2 * (j + 1) * xi) * math.cosh(2 * (j + 1) * eta) for j in range(3))
    eta1 = eta - sum(BETA[j] * math.cos(2 * (j + 1) * xi) * math.sinh(2 * (j + 1) * eta) for j in range(3))
    chi = math.asin(math.sin(xi1) / math.cosh(eta1))
    lat = chi + sum(DELTA[j] * math.sin(2 * (j + 1) * chi) for j in range(3))
    lon = lon0 + math.atan2(math.sinh(eta1), math.cos(xi1))
    return math.degrees(lat), math.degrees(lon)


def latlon_in_utm(lat, lon, zona=32):
    lon0 = math.radians(zona * 6 - 183)
    phi = math.radians(lat)
    lam = math.radians(lon) - lon0
    c = 2 * math.sqrt(N_ELL) / (1 + N_ELL)
    t = math.sinh(math.atanh(math.sin(phi)) - c * math.atanh(c * math.sin(phi)))
    xi1 = math.atan2(t, math.cos(lam))
    eta1 = math.atanh(math.sin(lam) / math.sqrt(1 + t * t))
    est = E0 + K0 * A_RETT * (eta1 + sum(ALFA[j] * math.cos(2 * (j + 1) * xi1) * math.sinh(2 * (j + 1) * eta1) for j in range(3)))
    nord = K0 * A_RETT * (xi1 + sum(ALFA[j] * math.sin(2 * (j + 1) * xi1) * math.cosh(2 * (j + 1) * eta1) for j in range(3)))
    return est, nord


def verifica():
    """Tre punti noti: il meridiano centrale all'equatore e a 45°N (valori di riferimento della proiezione), e un
    andata e ritorno su Bologna. Esce con errore se una formula sbaglia di più di 1 cm (o 1e-7 gradi)."""
    errori = []
    e, n = latlon_in_utm(0.0, 9.0)
    if abs(e - 500000.0) > 0.01 or abs(n) > 0.01:
        errori.append("equatore: %.3f %.3f" % (e, n))
    e, n = latlon_in_utm(45.0, 9.0)
    if abs(e - 500000.0) > 0.01 or abs(n - 4982950.400) > 0.01:
        errori.append("45°N: %.3f %.3f (atteso 500000,000 4982950,400)" % (e, n))
    lat, lon = utm_in_latlon(*latlon_in_utm(44.4949, 11.3426))
    if abs(lat - 44.4949) > 1e-7 or abs(lon - 11.3426) > 1e-7:
        errori.append("andata e ritorno su Bologna: %.8f %.8f" % (lat, lon))
    if errori:
        print("ERRORE nelle formule UTM: " + "; ".join(errori))
        return 1
    print("Formule UTM verificate su 3 punti")
    return 0


# MARK: - Lettura di .shp e .dbf (poligoni, tipo 5)

def leggi_dbf(percorso):
    with open(percorso, "rb") as f:
        dati = f.read()
    numero = struct.unpack("<I", dati[4:8])[0]
    lung_testata, lung_record = struct.unpack("<HH", dati[8:12])
    campi = []
    pos = 32
    while dati[pos] != 0x0D:
        nome = dati[pos:pos + 11].split(b"\x00")[0].decode("latin-1")
        lunghezza = dati[pos + 16]
        campi.append((nome, lunghezza))
        pos += 32
    record = []
    for i in range(numero):
        inizio = lung_testata + i * lung_record
        r = dati[inizio:inizio + lung_record]
        if not r or r[0:1] == b"*":
            record.append(None)
            continue
        valori, p = {}, 1
        for nome, lunghezza in campi:
            grezzo = r[p:p + lunghezza]
            try:
                valori[nome] = grezzo.decode("utf-8").strip()
            except UnicodeDecodeError:
                valori[nome] = grezzo.decode("latin-1").strip()
            p += lunghezza
        record.append(valori)
    return record


def leggi_shp(percorso):
    """Restituisce, per record, la lista degli anelli (liste di (x, y) in metri UTM)."""
    with open(percorso, "rb") as f:
        dati = f.read()
    if struct.unpack(">i", dati[0:4])[0] != 9994:
        raise SystemExit("ERRORE: %s non è un shapefile" % percorso)
    pos, forme = 100, []
    while pos + 8 <= len(dati):
        _, lunghezza = struct.unpack(">ii", dati[pos:pos + 8])
        contenuto = dati[pos + 8:pos + 8 + lunghezza * 2]
        pos += 8 + lunghezza * 2
        tipo = struct.unpack("<i", contenuto[0:4])[0]
        if tipo == 0:
            forme.append([])
            continue
        if tipo not in (5, 15, 25):
            raise SystemExit("ERRORE: forma di tipo %d (attesi poligoni)" % tipo)
        n_parti, n_punti = struct.unpack("<ii", contenuto[36:44])
        parti = list(struct.unpack("<%di" % n_parti, contenuto[44:44 + 4 * n_parti]))
        base = 44 + 4 * n_parti
        punti = [struct.unpack("<dd", contenuto[base + 16 * k:base + 16 * k + 16]) for k in range(n_punti)]
        parti.append(n_punti)
        forme.append([punti[parti[k]:parti[k + 1]] for k in range(n_parti)])
    return forme


def area_firmata(anello):
    s = 0.0
    for (x1, y1), (x2, y2) in zip(anello, anello[1:] + anello[:1]):
        s += x1 * y2 - x2 * y1
    return s / 2


def baricentro(anello):
    a = area_firmata(anello)
    if abs(a) < 1e-9:
        xs = [p[0] for p in anello]
        ys = [p[1] for p in anello]
        return sum(xs) / len(xs), sum(ys) / len(ys)
    cx = cy = 0.0
    for (x1, y1), (x2, y2) in zip(anello, anello[1:] + anello[:1]):
        k = x1 * y2 - x2 * y1
        cx += (x1 + x2) * k
        cy += (y1 + y2) * k
    return cx / (6 * a), cy / (6 * a)


def douglas_peucker(punti, tolleranza):
    if len(punti) < 3:
        return punti
    tieni = [False] * len(punti)
    tieni[0] = tieni[-1] = True
    pila = [(0, len(punti) - 1)]
    while pila:
        i, j = pila.pop()
        (x1, y1), (x2, y2) = punti[i], punti[j]
        dx, dy = x2 - x1, y2 - y1
        lung = math.hypot(dx, dy)
        massima, indice = 0.0, -1
        for k in range(i + 1, j):
            px, py = punti[k]
            d = abs(dy * px - dx * py + x2 * y1 - y2 * x1) / lung if lung > 0 else math.hypot(px - x1, py - y1)
            if d > massima:
                massima, indice = d, k
        if indice >= 0 and massima > tolleranza:
            tieni[indice] = True
            pila += [(i, indice), (indice, j)]
    return [p for p, t in zip(punti, tieni) if t]


def leggi_elenco(percorso):
    grezzo = open(percorso, "rb").read()
    for codifica in ("utf-8-sig", "cp1252", "latin-1"):
        try:
            testo = grezzo.decode(codifica)
            break
        except UnicodeDecodeError:
            continue
    lettore = csv.reader(io.StringIO(testo), delimiter=";")
    testata = [h.strip().lower() for h in next(lettore)]

    def colonna(*parole):
        for i, h in enumerate(testata):
            if all(p in h for p in parole):
                return i
        raise SystemExit("ERRORE: nell'elenco manca la colonna con %s" % " ".join(parole))

    i_codice = colonna("codice comune", "alfanumerico")
    i_nome = colonna("denominazione", "italian")
    i_sigla = colonna("sigla automobilistica")
    # La colonna del codice catastale NON si legge (decisione 70)
    elenco = {}
    for riga in lettore:
        if len(riga) <= max(i_codice, i_nome, i_sigla):
            continue
        codice = riga[i_codice].strip()
        if codice:
            elenco[codice] = (riga[i_nome].strip(), riga[i_sigla].strip().upper())
    return elenco


def tabella_istat(args):
    elenco = leggi_elenco(args.elenco)
    base = os.path.splitext(args.confini)[0]
    forme = leggi_shp(base + ".shp")
    record = leggi_dbf(base + ".dbf")
    if len(forme) != len(record):
        raise SystemExit("ERRORE: .shp e .dbf non hanno lo stesso numero di record")
    province_scelte = set(s.strip().upper() for s in args.province.split(",")) if args.province else None
    nome_file = os.path.basename(base)
    edizione = nome_file[3:11] if nome_file.lower().startswith("com") and nome_file[3:11].isdigit() else nome_file
    if len(edizione) == 8 and edizione.isdigit():
        edizione = "%s/%s/%s" % (edizione[0:2], edizione[2:4], edizione[4:8])
    righe, confini, scartati = [], {}, 0
    for anelli, campi in zip(forme, record):
        if not anelli or campi is None:
            continue
        codice_istat = campi.get(args.campo_codice, "").strip()
        if codice_istat not in elenco:
            scartati += 1
            continue
        nome, sigla = elenco[codice_istat]
        if province_scelte is not None and sigla not in province_scelte:
            continue
        area_totale = abs(sum(area_firmata(a) for a in anelli))
        esterno = max(anelli, key=lambda a: abs(area_firmata(a)))
        cx, cy = baricentro(esterno)
        lat, lon = utm_in_latlon(cx, cy)
        raggio = math.sqrt(area_totale / math.pi) / 1000
        codice = codice_comune(nome, sigla)
        righe.append([codice, nome, sigla, round(lat, 5), round(lon, 5), round(raggio, 2), codice_istat])
        semplici = []
        for a in anelli:
            ridotto = douglas_peucker(a, args.tolleranza)
            if len(ridotto) < 4:
                continue
            piatto = []
            for (x, y) in ridotto:
                la, lo = utm_in_latlon(x, y)
                piatto += [round(la, 4), round(lo, 4)]
            semplici.append(piatto)
        confini.setdefault(sigla, {})[codice] = semplici
    righe.sort(key=lambda r: r[0])
    codici = [r[0] for r in righe]
    if len(set(codici)) != len(codici):
        raise SystemExit("ERRORE: due comuni con lo stesso codice <SIGLA>-<nome>")
    tabella = {"formato": "prisma-comuni", "versione": 1, "diProva": False,
               "fonte": "ISTAT, Elenco dei comuni e Confini delle unità amministrative a fini statistici (versione generalizzata)",
               "licenza": "CC BY 4.0", "edizione": edizione,
               "nota": "Coordinate: baricentro del comune; raggioKm = radice di area/pi. Niente CAP, niente codici catastali.",
               "colonne": COLONNE + ["istat"], "comuni": righe}
    peso = scrivi_json(os.path.join(args.uscita, "comuni.json"), tabella)
    for sigla in sorted(confini):
        peso += scrivi_json(os.path.join(args.uscita, "confini", "%s.json" % sigla),
                            {"provincia": sigla, "diProva": False, "comuni": confini[sigla]})
    print("Tabella ISTAT: %d comuni, %d province, %d record senza riscontro nell'elenco, %d byte in tutto"
          % (len(righe), len(confini), scartati, peso))


def main():
    p = argparse.ArgumentParser(description="Tabelle del Territorio di Prisma (comuni e confini)")
    p.add_argument("uscita", nargs="?", help="cartella Sources/Prisma/Risorse/Territorio/")
    p.add_argument("--tabella-di-prova", action="store_true", help="scrive la tabella ridotta di prova")
    p.add_argument("--verifica", action="store_true", help="controlla le formule UTM su punti noti")
    p.add_argument("--elenco", help="CSV dell'elenco dei comuni ISTAT")
    p.add_argument("--confini", help=".shp dei confini ISTAT generalizzati (WGS84 UTM 32N)")
    p.add_argument("--province", help="solo queste sigle, separate da virgole")
    p.add_argument("--tolleranza", type=float, default=150.0, help="metri per la semplificazione (Douglas-Peucker)")
    p.add_argument("--campo-codice", default="PRO_COM_T", help="campo del codice del comune nel .dbf")
    args = p.parse_args()
    if args.verifica:
        return verifica()
    if not args.uscita:
        p.error("manca la cartella di uscita")
    if args.tabella_di_prova:
        tabella_di_prova(args.uscita)
        return 0
    if not args.elenco or not args.confini:
        p.error("servono --elenco e --confini (oppure --tabella-di-prova)")
    if verifica() != 0:
        return 1
    tabella_istat(args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
