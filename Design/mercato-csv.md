# Mercato · il formato dei file CSV

Mercato scarica da solo, e solo con l'interruttore «Dati di mercato» acceso, le serie pubbliche della **BCE** (Data Portal, SDMX) e di **Eurostat** (dissemination API, JSON-stat). Tutto il resto entra da un file CSV o si scrive a mano:

- le **quote dei fondi, ETF e titoli per ISIN** (nessuna fonte libera le dà: estratti della piattaforma Alleanza, della banca, file della SGR…);
- gli **indici** e le serie che non vengono da BCE o Eurostat (FTSE MIB, MSCI World in euro…).

Gli ISIN non escono mai dal Mac. Ogni valore importato porta la data e la fonte scritta dal consulente al momento dell'importazione («Fonte: Estratto Alleanza (file importato)»). Lettore: `LettoreMercato.importaCSV` (`Sources/Prisma/Motori/LettoreMercato.swift`).

## Le due forme

**Una serie** (indice, tasso): due colonne, `data;valore`.

```
data;valore
2026-09-30;34180,5
2026-10-31;33976,2
```

**Quote per ISIN**: tre colonne, `data;isin;valore`.

```
data;isin;valore
2026-10-30;IE00B4L5Y983;18,42
2026-10-31;IE00B4L5Y983;18,50
2026-10-31;LU0000000000;10,00
```

## Regole

| Cosa | Regola |
|---|---|
| Intestazione | Facoltativa. È la prima riga se la sua prima cella non è una data. Nomi riconosciuti: `data` (o `date`, `giorno`, `periodo`), `isin` (o `codice isin`), `valore` (o `quota`, `prezzo`, `nav`, `value`, `close`, `chiusura`, `livello`, `tasso`); maiuscole e accenti non contano. Con i nomi le colonne possono essere in qualunque ordine e ce ne possono essere altre; senza intestazione contano le posizioni (2 colonne = serie, 3 = quote). |
| Separatore | `;` (Excel italiano) oppure `,`. Si riconosce dalla prima riga: se c'è un `;` vale il `;`. Si accetta anche la tabulazione. |
| Decimali | Con il `;` il decimale può essere la virgola o il punto (`18,42` o `18.42`). Con la `,` come separatore il decimale è solo il punto. **Niente separatore delle migliaia**: `1.234,5` è un errore. Si accettano il meno tipografico (`−0,25`), `€` e `%`. |
| Date | `aaaa-mm-gg`, `gg/mm/aaaa`, `gg.mm.aaaa`, `gg-mm-aaaa`; `aaaa-mm` vale il primo del mese (dati mensili). Una data futura è un errore. |
| ISIN | 12 caratteri con la cifra di controllo giusta; spazi e minuscole si sistemano da soli (` ie00 b4l5 y983 ` diventa `IE00B4L5Y983`). |
| Quote | Maggiori di zero. |
| Ripetute | La stessa data (per lo stesso ISIN) due volte: vale la prima, la seconda è un errore. |
| Righe vuote | Si saltano. |

Una riga sbagliata non ferma il file: finisce nell'elenco degli errori con il suo numero (contando dall'1, intestazione compresa) e il motivo; le altre si importano. Una riga con più colonne del previsto è un errore (di solito un decimale con la virgola in un file separato da virgole: `18,4` diventerebbe `18`).

## A mano

Un valore si può scrivere a mano con le stesse regole dei numeri e delle date (`LettoreMercato.valoreAMano`, `dataAMano`): resta segnato «Inserito a mano».

## Dopo l'importazione

Le quote per ISIN aggiornano il valore delle posizioni con lo stesso percorso di «Aggiorna valori» (`MotoreMercato.valoriDaQuote` → `AggiornaValori.esiti`): valore = numero di quote della posizione × quota, con la data della quota e la fonte; il valore di prima va nello storico. Senza il numero di quote la riga resta «senza valore» con la spiegazione «manca il numero di quote».
