# Formato delle tabelle delle famiglie («prisma-famiglie», versioni 1 e 2)

Il confronto **Analisi 360 › Rispetto alle famiglie come la sua** mette le cifre del cliente accanto a quelle delle famiglie italiane. Le cifre vengono **solo dalle tavole pubblicate dalla Banca d'Italia** (scelta dell'utente, novembre 2026): nessuna elaborazione dei microdati, nessuna altra fonte.

- **Tabelle predefinite:** `Sources/Prisma/Risorse/famiglie-bdi-2022.json` (versione 2), con fonte «Banca d'Italia, Indagine sui bilanci delle famiglie italiane, edizione 2022 (tavole pubblicate, aggiornamento ottobre 2025)» e `"diProva": false`. Si rifà dagli xlsx con lo script `Supporto/famiglie/converti_bdi.py` (vedi sotto). Gli xlsx **non** stanno nel repository.
- **File caricato:** da **Impostazioni › Rendimenti di confronto › Famiglie italiane › «Carica tabelle…»** si può caricare un file aggiornato (versione 1 o 2). Il file si controlla: se è valido viene copiato nell'archivio locale (`~/Library/Application Support/Prisma/archivio.json`, campo `famiglie`), entra nel backup e prevale sulle tavole incluse; se non è valido restano le tabelle di prima e Impostazioni mostra il campo e il motivo dell'errore. «Usa le tavole incluse» toglie il file caricato.
- **File di prova:** `Sources/Prisma/Risorse/famiglie-di-prova.json` (versione 1, `"diProva": true`, valori segnaposto tondi) serve **solo** alle prove dei calcoli e all'istantanea 446. Se un file di prova viene caricato, la vista lo scrive in chiaro («Dati di prova…»).

Codice: `Dati/TabelleFamiglie.swift` (modello e validazione), `Motori/MotoreFamiglie.swift` (confronto), `Motori/TestiFamiglie.swift` e `Motori/TestiFamiglieVista.swift` (frasi ed errori), `Shell/ImpostazioniFamiglie.swift` (caricamento: NSOpenPanel sul Mac, selettore dei file su iPhone e iPad), `Shell/FamiglieComeLaSua.swift` (la vista in Analisi 360, con `DesignSystem/Apple/DistribuzioneApple.swift` e i gettoni in `DesignSystem/Apple/Tema.Apple+Famiglie.swift`). Istantanee 445-449 (`Shell/IstantaneeFamiglie.swift`). Prove: `Motori/ProvaCalcoliFamiglie.swift` (`Prisma --prova-calcoli`: F1-F11 versione 1, B1-B10 tavole della Banca d'Italia) e `Dati/ProvaBackupFamiglieOCF.swift` (`Prisma --prova-backup`).

## Che cosa danno davvero le tavole

Le tavole pubblicate danno le cifre **per una caratteristica del capofamiglia alla volta** (età **oppure** quinto di reddito), **non incrociate** età × reddito. Per questo il confronto è doppio: con le famiglie della sua età e con quelle del suo quinto di reddito. Il capofamiglia, per l'indagine, è il maggior percettore di reddito della famiglia; Prisma prende il cliente come capofamiglia e lo dice nella nota.

| Tavola | Che cosa | Voce di Prisma | Statistica |
|---|---|---|---|
| T4 «Reddito e consumi familiari medi» | reddito medio, consumi medi, propensione al consumo (%) | `tassoRisparmio` = 100 − propensione | `rapportoTraMedie`: risparmio medio ÷ reddito medio del gruppo, **non** la media dei tassi delle singole famiglie |
| T17 «Valori mediani della ricchezza familiare» | mediana delle attività finanziarie e della ricchezza netta | `ricchezzaFinanziaria`, `ricchezzaNetta` | `mediana` |
| T23 «Forme assicurative e pensioni integrative» | % di famiglie con polizze vita e con pensioni integrative | `protezione` (solo polizze vita: **le tavole non hanno i danni**), `previdenzaComplementare` | `quota` |
| T7 «Quinti di famiglie rispetto al reddito familiare» | valori di ripartizione dei quinti (17.809 · 26.005 · 35.594 · 51.543 €, redditi 2022) | estremi delle classi di reddito | — |
| T15 «Quinti e decimi di famiglie rispetto alla ricchezza netta» | valori di ripartizione dei decimi | `ricchezzaNetta` del gruppo «tutte» | `quantili` p10…p90, **di tutte le famiglie** (non per età né per reddito) |
| T29 «Contatti per le interviste effettuate» | famiglie intervistate per classe | `famiglie` di ogni classe | — |

Le cifre sono in euro del 2022, **non rivalutati**: le soglie dei quinti valgono per i redditi di allora (la nota lo dice).

## Versione 2 (tavole a una dimensione)

```json
{
  "formato": "prisma-famiglie",
  "versione": 2,
  "diProva": false,
  "fonte": "Nome dell'indagine e dell'ente, edizione",
  "edizione": 2022,
  "aggiornamento": "ottobre 2025",
  "licenza": "Condizioni d'uso dei dati",
  "note": "Unità, definizioni, come sono state ricavate le cifre",
  "sogliaFamiglie": 30,
  "descrizioni": { "tassoRisparmio": "che cosa misura, con l'unità" },
  "gruppi": [
    {
      "id": "eta", "dimensione": "eta", "nome": "Età del capofamiglia", "nota": "…",
      "classi": [
        { "id": "eta-1", "nome": "fino a 34 anni", "a": 34, "famiglie": 1,
          "voci": {
            "tassoRisparmio":          { "statistica": "rapportoTraMedie", "valore": 0, "tavola": "T4", "nota": "…" },
            "ricchezzaFinanziaria":    { "statistica": "mediana", "valore": 0, "tavola": "T17" },
            "ricchezzaNetta":          { "statistica": "mediana", "valore": 0, "tavola": "T17" },
            "protezione":              { "statistica": "quota", "valore": 0, "tavola": "T23" },
            "previdenzaComplementare": { "statistica": "quota", "valore": 0, "tavola": "T23" }
          } }
      ]
    },
    { "id": "reddito", "dimensione": "reddito", "classi": [ { "id": "quinto-1", "nome": "1° quinto", "a": 17809, "famiglie": 1, "voci": {} } ] },
    { "id": "tutte", "dimensione": "tutte", "classi": [ { "id": "tutte", "famiglie": 1,
        "voci": { "ricchezzaNetta": { "statistica": "quantili", "quantili": { "p10": 0, "p20": 0, "p90": 0 }, "tavola": "T15" } } } ] }
  ]
}
```

I numeri dell'esempio sono **solo segnaposto per mostrare la forma**; le cifre vere sono nel file incluso.

### Campi della radice

| Campo | Obbligatorio | Regola |
|---|---|---|
| `formato` | sì | sempre `"prisma-famiglie"` |
| `versione` | sì | `1` (celle età × reddito) o `2` (gruppi a una dimensione) |
| `diProva` | sì | `true` solo per file di prova: la vista scrive «dati di prova» |
| `fonte` | sì | testo non vuoto: indagine, ente, edizione |
| `edizione` | no | anno dell'indagine (1900-2200); se la fonte non lo dice già, la nota lo aggiunge |
| `aggiornamento` | no | data della pubblicazione, in chiaro |
| `licenza`, `note` | no | testo libero |
| `sogliaFamiglie` | no | sotto questo numero di famiglie nel gruppo il confronto è «solo indicativo»; senza, 30 (da confermare) |
| `descrizioni` | no | che cosa misura ogni voce, con l'unità |
| `gruppi` | sì (v2) | vedi sotto |
| `classiEta`, `classiReddito`, `celle` | sì (v1) | vedi «Versione 1» |

### Gruppi e classi

- `dimensione`: `eta` (età del capofamiglia, anni compiuti, **estremi inclusi**), `reddito` (reddito familiare netto annuo in euro, `da` **incluso**, `a` **escluso**) o `tutte` (tutte le famiglie: **una sola classe, senza estremi**). Al più un gruppo per dimensione, `id` unici.
- Classi come nella versione 1: solo la prima può non avere `da`, solo l'ultima `a`; niente buchi né sovrapposizioni (età: la classe dopo comincia l'anno successivo; reddito: dove finisce la precedente).
- `famiglie`: famiglie del campione nella classe, intero > 0; se manca, il confronto è «solo indicativo».
- `voci`: un oggetto con le voci che la classe ha (anche solo alcune). Le chiavi sono `tassoRisparmio`, `ricchezzaFinanziaria`, `ricchezzaNetta`, `protezione`, `previdenzaComplementare`; una chiave diversa è un errore.

### Voci

| Campo | Regola |
|---|---|
| `statistica` | `rapportoTraMedie`, `media`, `mediana`, `quota` o `quantili` |
| `valore` | obbligatorio tranne che con `quantili`; % per il tasso di risparmio (tra −100 e 100) e per la quota (0-100), euro per la ricchezza |
| `quantili` | con `quantili`: almeno due tra `p10`, `p20`, `p25`, `p30`, `p40`, `p50`, `p60`, `p70`, `p75`, `p80`, `p90`, che crescono o restano uguali |
| `tavola`, `nota` | da dove viene la cifra (per esempio «T4») e come è stata ricavata |

La `quota` vale solo per `protezione` e `previdenzaComplementare`. Nella versione 2 `protezione` è **la quota di famiglie con polizze vita**.

## Versione 1 (celle età × reddito, resta leggibile)

Classi `classiEta` e `classiReddito` (come sopra) e una cella per **ogni** coppia età × reddito, nessuna doppia: `{ "eta", "reddito", "famiglie", "tassoRisparmio", "ricchezzaFinanziaria", "ricchezzaNetta", "protezione", "previdenzaComplementare" }`. Ogni voce è una distribuzione con campi tutti facoltativi: i quantili (`p10` … `p90` come sopra), `media`, `quota` (0-100). Nella versione 1 `protezione` è la quota di famiglie con polizze vita **o danni** (o i quantili dei premi annui in euro), `previdenzaComplementare` la quota di chi aderisce (o i quantili dei contributi).

## Come confronta Prisma

1. **Gruppi.** Versione 2: la classe d'età che contiene l'età del cliente **e**, a parte, il quinto che contiene il reddito familiare netto (reddito netto del cliente più quello dei familiari); più il gruppo «tutte». Manca l'età: resta il confronto col quinto, e viceversa (la nota lo dice); senza tutti e due nessun confronto. Versione 1: la cella età × reddito.
2. **Cifre del cliente** (`MotoreFamiglie.dati`):
   - risparmio = risparmio libero del profilo più i versamenti annui delle posizioni in essere; il tasso è risparmio ÷ reddito × 100;
   - attività finanziarie = liquidità più investimenti, risparmio e previdenza in essere dei due canali;
   - ricchezza netta = tutte le posizioni in essere tranne le coperture (immobili compresi), debiti tolti;
   - polizze vita = una copertura caso morte o una polizza vita di investimento o risparmio in essere; protezione (v1) = coperture in essere (`MotoreProtezioneFamiglia`);
   - previdenza complementare = piani in essere (`MotorePrevidenza`).
3. **Quantili → percentile** (con almeno due quantili: i decimi della ricchezza netta):
   - interpolazione lineare tra i quantili vicini;
   - sotto il primo quantile si va da 0 (se il primo quantile è positivo e il valore non è negativo), altrimenti 0;
   - sopra l'ultimo ci si ferma al suo percentile (per esempio 90);
   - un valore uguale a più quantili (una «massa», per esempio molte famiglie a zero) sta a metà della massa;
   - il risultato si arrotonda per difetto.
4. **Mediana, media, rapporto tra medie:** si dice sopra o sotto, **senza percentile**. La barra è in valori (`MotoreFamiglie.scalaValori`): la tacca è il valore del gruppo, l'avatar la cifra del cliente; la scala va da min(0, gruppo, cliente) a max(2 × gruppo − basso, cliente + 15%, basso + 1), con un margine del 10% a sinistra se il basso è negativo. Con la mediana la frase dice «sta sopra / sotto almeno metà delle famiglie …».
5. **Quota** (polizze vita, pensioni integrative): «ha / non ha» con la percentuale esatta («come il 20,0% delle famiglie della sua età»). Sulla barra la tacca è il confine fra chi non ha la cosa (a sinistra) e chi l'ha; l'avatar sta a metà della sua parte. Per la protezione la frase aggiunge «Le tavole non contano le polizze danni.»
6. **Frasi:**
   - frase grande: «Le famiglie con capofamiglia della sua età risparmiano in media il 28,7% del reddito; Giulia il 15,0%.» (con i quantili, «Giulia risparmia più del N% delle famiglie …»);
   - con i quantili: da 50 in su «… più di circa N famiglie su 10 …» (N = percentile ÷ 10, per difetto); sotto 50 «… meno di circa M famiglie su 10 …», con M = (100 − percentile) ÷ 10; il gruppo «tutte» dice «in Italia».
7. **Cautele:**
   - poche famiglie nel gruppo, o numero non dichiarato;
   - rapporto tra medie (risparmio), sola mediana, sola media;
   - distribuzione di tutte le famiglie, non per gruppo (ricchezza netta, decimi);
   - risparmio ricavato solo dai versamenti; reddito ricavato solo dai familiari;
   - protezione, previdenza e ricchezza netta contano solo ciò che è registrato in Prisma;
   - quinti di reddito dell'anno dell'indagine, non rivalutati; il cliente preso come capofamiglia.

## Rifare il file dalle tavole

1. Scaricare dal sito della Banca d'Italia le tavole dell'Indagine sui bilanci delle famiglie italiane (file «tavole_cross_section.xlsx»), fuori dal repository.
2. `python3 -I Supporto/famiglie/converti_bdi.py percorso/tavole_cross_section.xlsx Sources/Prisma/Risorse/famiglie-bdi-2022.json` (serve openpyxl).
3. Lo script controlla l'edizione nell'indice, i titoli delle tavole e delle colonne e le righe «Età» e «Quinti …»: se l'impaginazione cambia si ferma con un errore invece di scrivere cifre sbagliate.
4. Controllare a mano alcune cifre e lanciare `Prisma --prova-calcoli` (prove B1-B10). Per una nuova edizione aggiornare `FONTE`, `EDIZIONE` e `AGGIORNAMENTO` nello script, il nome del file e le cifre attese delle prove.

## Errori

L'errore dice il campo, come nel file, e il motivo. Esempi:
- `gruppi[0].classi[1].voci.protezione.valore: la quota deve stare tra 0 e 100.`
- `gruppi[1].classi[2].voci.polizzeDanni: voce «polizzeDanni» non riconosciuta: …`
- `gruppi[1].dimensione: c'è già un gruppo per la dimensione «eta».`
- `gruppi[2].classi: il gruppo di tutte le famiglie ha una sola classe, senza «da» né «a».`
- `celle[3].tassoRisparmio.p25: i quantili devono crescere (o restare uguali) da p10 a p90.`
- `classiEta[1].da: si sovrappone alla classe precedente.`
- `versione: versione 3 non riconosciuta: Prisma legge le versioni 1 e 2.`
