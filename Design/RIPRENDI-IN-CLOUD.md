# Riprendere il lavoro su Prisma nel cloud

Documento per chi riprende il lavoro (Claude Code nel cloud su GitHub, o un'altra chat di Claude) dopo la fase in
locale sul Mac del 7-8 novembre 2026. Le regole vincolanti restano in `CLAUDE.md`: leggile per prime.

## Come si lavora nel cloud

- Il contenitore del cloud è Linux, senza Xcode: **non si può compilare Prisma lì** (SwiftUI e AppKit esistono solo
  su macOS). Si scrive il codice, si fa push del branch e la verifica la fa il workflow
  `.github/workflows/build.yml` su un runner macOS (macos-15-intel): build di release, `--verifica-risorse`,
  `--prova-backup`, `--prova-calcoli`, `--prova-vera`, `--prova-tavolo`, `--prova-prospetti`, `--prova-carico`,
  `--prova-fluidita`, `--prova-ovunque`, le istantanee del Mac, iPhone e iPad, e la release «ultima».
- Si legge l'esito delle build e i log degli errori su GitHub (Actions) e si corregge sul branch finché è verde.
  Le istantanee arrivano come artefatti (`anteprime-mac`, `anteprime-ios`) e sul branch `anteprime`: vanno guardate
  prima di chiedere screenshot all'utente.
- Un branch per lavoro; in `main` solo con la build verde. Le parti che riguardano Vera si uniscono in `main` solo con
  il via esplicito dell'utente.
- Dopo la fase in locale il workflow non è più stato provato: alla prima build potrebbe servire qualche ritocco
  (per esempio il minimo ora è macOS 14 con Observation, e ci sono file e prove nuove). Prima di tutto, quindi:
  push di `main` e una build verde.
- Sul Mac dell'utente (MacBook Pro M1, 8 GB, macOS 27) si compila con `bash Supporto/costruisci-mac.sh --prove` e si
  installa con `--installa`: l'utente lo fa dopo un'unione in `main`.

## Documenti

| Dove | Cosa |
|---|---|
| `CLAUDE.md` | le regole del progetto (grafica, privacy, backup, Vera, lingua) |
| `Design/template-luce-specifica.md` | la specifica delle 29 novità di «Luce»: sezioni, decisioni (§0.5), «Piano dei giri» in fondo |
| `Design/template-luce.html` | il template navigabile di Luce (la grafica di riferimento) |
| `Design/template-apple.html`, `Design/template-apple-specifica.md` | il tema Apple, l'identità grafica |
| `Design/velocita-proposta.md` | il giro 0 «Prisma istantaneo» con le misure |
| `Vera/BRIEF.md` | il brief delle 25 funzioni di Vera, in 5 fasi |
| `Design/Documenti-utente/` | i documenti originali dell'utente: i prompt di Luce, Orizzonte e Acqua viva, il brief di Vera in PDF e il template «le 25 novità» (scritti quando l'assistente si chiamava Ruby) |

## Stato ad oggi

### In `main` (la versione installata sul Mac dell'utente)

- **Luce, giri 1-7** (14 delle 29 novità): pannello Novità, le app Territorio, Pratiche, Sala e Biblioteca nel dock;
  radar del portafoglio e smontaggio; proposta che si costruisce da sola e pratiche dopo la firma; prisma di luce,
  disegna il tuo futuro, giornata della pensione, gioco del rischio; la tua settimana e il tuo anno, palestra della
  trattativa, traguardi festeggiati; Trova la pagina (Biblioteca); clienti imprenditori.
- **Vera, fasi 1-3** del brief (`Vera/BRIEF.md`): 14 delle 25 funzioni.
- **Giro 0 «Prisma istantaneo»** (`Design/velocita-proposta.md`): macOS 14 con Observation, motori in cache per
  cliente, archivio in una cartella a pezzi. Aprire Posizioni con 200 clienti: da 411 a 131 ms.

### Fatto ma non ancora in `main`

| Branch | Cosa | Stato |
|---|---|---|
| `luce/unione-8-10` | Luce giri 8-10: Sala (lettera dal futuro, Lancia l'anno, Quanto vale avermi accanto), Studio › Spese (chilometri, spese e scadenze), Pratiche › Moduli (compila da solo); ognuno con revisione avversaria e correzioni | compila in debug sul Mac e le prove dei singoli giri erano verdi; manca la build completa con tutte le prove (la fa il workflow al primo push) |
| `vera/completa` | Vera, le lacune del controllo di completezza: «Le 25 novità di Vera» (pannello del template), fase 4 documentata, il cliente in 30 secondi a voce e dalla scheda, lascia cadere qui verso Posizioni e anagrafica, sintesi del resoconto, istantanee di memoria, pollici e filo lungo, ragiona a passi su altre richieste, valutazione manuale della palestra (`Vera/Valutazione/`) | sintassi controllata nel cloud; manca la build completa con le prove (al primo push) |
| `vera/fase-4` | Vera, fase 4: funzioni 3, 4, 5, 7, 14, 15, 17, 20, collegate a chat, viste e archivio | due giri di revisione con correzioni, prove verdi in debug sul Mac (db982bc); contiene già `main` con il giro 0; si unisce in main solo con build verde e il via dell'utente |


## Operazioni per finire

### 1. Giri 8-10 in `main`

1. I tre giri sono già uniti in `luce/unione-8-10` (fd98bfb) e la build di debug riesce. I conflitti erano elenchi in
   cui ogni giro aggiunge le sue righe, risolti tenendo entrambe le parti.
2. Push del branch: il workflow build.yml compila e lancia tutte le prove (anche carico, tavolo, prospetti,
   fluidità, iPhone e iPad). Se qualcosa è rosso si corregge sul branch.
3. Con la build verde, unire in `main` (pull request). L'utente installa sul Mac con
   `bash Supporto/costruisci-mac.sh --installa`.

### 2. Vera fase 4, poi fase 5

1. Push del branch `vera/fase-4` e build verde (se `main` è andato avanti, unirlo prima nel branch); poi, con il via
   dell'utente, unire in `main`. Nella prova della palestra va bene la cifra inventata del branch (7,85%).
2. Fase 5 del brief: funzioni 22, 23 e 25 (`Vera/BRIEF.md`).

### 3. Luce, giri 11-16

La specifica è `Design/template-luce-specifica.md` (sezione «Piano dei giri» in fondo, decisioni nel §0.5). Dove il
§0.5 ha una «Proposta» si segue senza chiedere. L'utente ha già approvato, l'8 novembre 2026:

- **Uscite verso il cliente** (giri 13-16: Prisma del cliente, film del piano, capsula del tempo, biglietto dei
  traguardi, aggiornamento del sinistro): come proposto. File cifrato; password mai conservata né nello stesso
  messaggio; foglio di condivisione del sistema; spedisce il consulente; traccia nel dossier; eccezione da scrivere in
  `CLAUDE.md` (Dati e privacy). PDF protetto sempre, HTML solo se la prova su iPhone e Android veri passa.
- **Territorio** (giro 11): tabelle dei comuni e dei confini ISTAT (CC BY), scaricate una volta a mano durante lo
  sviluppo e citate in Impostazioni. Niente CAP (solo il comune). Codice fiscale «coerente (comune non controllato)»
  finché l'utente non approva i codici catastali.
- **Stanotte** (giro 14): lavoro nella finestra serale 22-6 solo con il Mac acceso, alla corrente e Prisma aperto; se
  salta, al mattino «Prepara adesso». Al massimo 10 bozze di Qwen una alla volta; mai in rete; «Approva» non manda nulla.
- **Realtà aumentata e tavolo a doppio senso** (giro 16): sì, dopo una prova di fattibilità di RealityKit senza
  dipendenze esterne. Immagini solo in memoria, mai nel Rullino.

Ordine consigliato: giri 11, 12 e 13, poi 14, 15 e 16 (il 14 usa le carte delle novità già
fatte, il 15 la lettera del giro 8). Per ogni giro: un branch, dati nuovi nella versione 27 dell'archivio con
`decodeIfPresent` e la prova del backup, istantanee chiare e scure guardate, voce accesa nel pannello Novità, elenco
del backup in `CLAUDE.md`, revisione avversaria, correzioni, unione solo con build e prove verdi.

### 4. Alla fine

- iPhone e iPad delle novità di Luce, vetrina `400-vetrina-apple`, pagina online delle anteprime
  (https://claude.ai/artifact/EauRU1ohEGjHj4zvTomDvb).
- «Misura Vera» con Ollama vero.
- Controllo finale: tutte le voci del pannello Novità accese, `CLAUDE.md` aggiornato con le eccezioni approvate.

## Dati che servono dall'utente

Le funzioni sono pronte, ma per usarle con i clienti servono testi e dati che solo l'utente può dare (Prisma non li
inventa):

- **Impostazioni › Sala:** testi definitivi delle avvertenze (oggi il segnaposto «Stime basate su ipotesi, non
  garanzie di risultato.»); testo e titolo di «Quanto vale avermi accanto»; imprevisti di Lancia l'anno con
  probabilità, fonte e importi.
- **Per ogni cliente:** «Cliente dal», indennizzo stimato per evento delle polizze di protezione.
- **Impostazioni › Studio:** aliquote delle provvigioni Alleanza.
- **Spese:** km di andata e ritorno per cliente, dati fiscali, €/km e scadenze (da verificare con il commercialista).
- **Moduli:** i PDF veri dei moduli del canale indipendente; per Alleanza serve prima l'approvazione della compagnia.

## Regole da non dimenticare

- Il repository è pubblico: niente dati veri dei clienti, niente testi copiati da manuali, condizioni o moduli veri,
  solo fac-simile segnati come tali.
- Non inventare regole, dati fiscali, probabilità o testi legali: struttura, dati di prova dichiarati e chiedere.
- Vera scrive, l'utente approva: nulla parte, si firma o entra nel dossier senza conferma.
- Nessuna dipendenza esterna senza chiedere. Valori grafici solo in `Sources/Prisma/DesignSystem/`. Niente Timer.
- Valori già salvati con il nome «eve» restano così (vedi `CLAUDE.md`, sezione Vera).
- Commit in italiano.
