# Prisma «Orizzonte» — specifica del template delle novità

Fonte: `Design/template-novita.html` (3 novembre 2026). Questa specifica descrive le dodici funzioni nuove della versione
«Orizzonte» e la parte che hanno in comune, e dice come portarle in Prisma.

## 0. Come leggere questa specifica

### 0.1 Il template di partenza
- `Design/template-novita.html` nasce da `Design/template-apple.html`, già descritto in `Design/template-apple-specifica.md`.
  **Per tutto ciò che qui non è detto vale quella specifica**: token (§1), barra (§3.3), dock (§3.4), finestra (§3.5),
  scrivania (§3.6), notifiche (§3.8), tastiera (§3.10), movimento (§1.8 e §2.0).
- Il file è un unico HTML/JS di circa 500 KB: va letto a pezzi (grep, sed), mai tutto insieme. I numeri di riga citati nelle
  sezioni sono quelli del file del 3 novembre 2026.
- Le schermate di riferimento (1480×940, palco 1440×900 scalato di 1,0137) sono state scattate dal template in chiaro e in
  scuro durante il lavoro sulla specifica (`orizzonte/chiaro-*.png`, `orizzonte/scuro-*.png` e le tavole in
  `orizzonte/spec/`). Non sono nel repository: chi implementa le rigenera dal template con Playwright (la copia di lavoro
  espone `window.__tema(true)` per lo scuro; il pulsante `#bNov` apre il pannello Novità, le voci sono
  `#novP .novI[data-i=N]`).

### 0.2 Le cifre sono dimostrative
Tutte le cifre, i nomi e le date del template sono **dimostrativi**. Nell'app le danno i motori di Prisma, partendo dai dati
dell'archivio. Dove un dato manca, Prisma non lo inventa: lo dice, con gli stati descritti in ogni sezione (§N.6) e
raccolti nella tabella del §14.

### 0.3 Le regole di CLAUDE.md che contano qui
- **Tema Apple**: è l'identità grafica. Ogni schermata nuova usa `Tema.Apple` (colori chiari e scuri, carta, raggi, ombre,
  superfici, misure, caratteri) e `Tema.Apple.Moto` per tempi e curve. Vetro, acqua della scrivania, logo e colori dei
  canali restano come sono.
- **Valori in DesignSystem**: colori, caratteri, misure, raggi, ombre e superfici vanno in `Sources/Prisma/DesignSystem/`,
  mai sparsi nel codice. Dove il template usa un valore che il tema non ha, la sezione propone un token nuovo con il suo nome.
- **Movimento**: numeri contati, blocchi a cascata, anelli che si riempiono, linee che si disegnano. Con «Riduci
  movimento» (`\.prismaCalmo`) tutto compare fermo con una dissolvenza di 0,15 s; nelle istantanee (`\.modoIstantanea`,
  `\.prismaStatoFinale`) tutto è disegnato nello stato finale. Niente Timer. Il template in molti punti ignora «Riduci
  movimento»: vale la regola di Prisma (vedi §15.1).
- **Canale sempre riconoscibile**: Alleanza in blu (#2563EB) con il logo, indipendente in cuoio (#B06E12) con «Denis
  Vicenzoni · Consulenza finanziaria».
- **MacBook Pro M1 con 8 GB**: codice leggero, attenzione alla memoria (ascolto lungo del copilota, microdati
  dell'indagine sulle famiglie, liste con molti clienti).
- **Target macOS 13**: le API più recenti (vetro di macOS 26, `onKeyPress` di macOS 14) vanno protette, con un ripiego.
- **Dati in locale**: i dati dei clienti restano sul Mac, niente server, niente cloud. Due funzioni toccano questa regola
  (Mercato, §12, e Prisma ovunque, §13): le loro sezioni propongono come restare dentro la regola, e il §15.1 le raccoglie.
- **Nessuna dipendenza esterna senza chiedere**.
- **«Dati di prova»**: i 5 clienti del template e i 30 fittizi caricabili da Impostazioni servono per valutare i motori.
  Ogni funzione nuova ha i suoi dati di prova in `Dati/DatiDemo.swift` e `Dati/ClientiFittizi.swift`, segnati
  nell'interfaccia con l'etichetta «dati di prova». **I dati di prova non finiscono mai nell'archivio reale**: si caricano
  solo con i clienti fittizi da Impostazioni e si tolgono con loro.
- **Ruby**: unico motore Qwen in locale. I calcoli li fa Prisma, Qwen racconta le cifre. Prompt e istruzioni nuove vanno in
  `Ruby/`.

### 0.4 Come sono numerate le sezioni
- §1 è la parte comune (barra, pannello Novità, dock, icone nuove, riquadro «Il tuo studio»).
- §2-§13 sono le dodici funzioni, nell'ordine dei giri di lavoro. La richiesta parla di «undici funzioni», ma le funzioni
  elencate sono dodici: sono tutte qui, e per questo i dati da chiedere sono al §14 e i dubbi al §15.
- Dentro ogni sezione i numeri sono quelli della sua parte, rimasti uguali: «1. Cosa si vede», «2. Misure e stile»,
  «3. Movimento», «4. Interazioni», «5. Mappa verso Prisma», «6. Dati che l'utente deve dare», «7. Istantanee».
  **Un rimando come «§5.6» dentro una sezione vale per quella sezione**; si scrive §11.5.6 quando lo si cita da fuori.
- I dubbi di ogni parte (che nelle bozze stavano in fondo a ciascuna) sono tutti al §15.

| § | Funzione | Parte di lavoro | Giro |
|---|---|---|---|
| 1 | Parte comune | 00 | 1 |
| 2 | Studio › Cruscotto | 01 | 1 |
| 3 | Studio › Parcelle e fatture | 02 | 2 |
| 4 | Studio › Track record | 03 | 2 |
| 5 | Messaggi — «Prisma scrive per te» | 05 | 3 |
| 6 | Posizioni › La prova del fuoco | 10 | 4 |
| 7 | Clienti › Dossier › La linea della vita | 11 | 4 |
| 8 | Incontri › Il copilota dell'incontro | 08 | 5 |
| 9 | Inquadra e capisci | 09 | 5 |
| 10 | Analisi 360 › Rispetto alle famiglie come la sua | 12 | 6 |
| 11 | Studio › Esame OCF | 04 | 6 |
| 12 | Mercato — «Prisma conosce il mercato» | 06 | 7 |
| 13 | Impostazioni › iPhone e iPad — «Prisma ovunque» | 07 | 8 |

Nel testo delle sezioni i rimandi a «la parte 00», «00-comune.md», «la parte 08» e simili vanno letti con questa tabella
(per esempio «parte 10» = §6).

### 0.5 Cose da decidere una volta per tutte le parti
- **Versione dell'archivio**: oggi `DatiPrisma.versioneAttuale = 25`. Tutte le parti propongono la 26 per i loro campi
  nuovi. Proposta: **una sola versione 26 per tutta Orizzonte**, con tutti i campi nuovi letti con tolleranza
  (`decodeIfPresent`), e la prova `Prisma --prova-backup` aggiornata con ogni campo nuovo. Se i giri escono separati, ogni
  giro che aggiunge campi alza la versione di uno (26, 27, …).
- **Numeri delle istantanee**: le parti hanno scelto serie che si accavallano fra loro o con quelle che esistono già.
  Proposta di numerazione senza conflitti (verificata con grep in `Sources/`):

| Parte | Serie scelta nella bozza | Conflitto | Proposta |
|---|---|---|---|
| §1 Parte comune | 500-506 | con §2 | 500-506 |
| §2 Cruscotto | 500-507 | con §1 | 570-577 |
| §3 Parcelle | 510-516 | — | 510-516 |
| §4 Track record | 520-525 | — | 520-525 |
| §5 Messaggi | 490-498 | — | 490-498 |
| §6 Prova del fuoco | 590-598 | — | 590-598 |
| §7 Linea della vita | 437-439 | con §10 | 437-439 |
| §8 Copilota | 580-589 | con §9 | 580-589 |
| §9 Inquadra | 580-589 | con §8 | 600-609 |
| §10 Famiglie | 437-441 | con §7 e con 440-441 esistenti (Analisi 360) | 445-449 |
| §11 Esame OCF | 530-537 | — | 530-537 |
| §12 Mercato | 540-549 | — | 540-549 |
| §13 Ovunque | 560-566 (Mac), 60-63 (iOS) | 60-63 esistono già (note, notifiche) | 560-566 e 610-613 |

  Nelle sezioni sono rimasti i numeri delle bozze: valgono quelli di questa tabella. A ogni giro vanno aggiornate anche la
  vetrina «400-vetrina-apple» e la pagina online delle anteprime.
- **Dati di prova**: un solo caricamento da Impostazioni › Dati di prova porta i dati di tutte le funzioni nuove, e un solo
  comando li toglie.
- **Collegamenti fra le app**: nel template molti pulsanti che portano a un'altra app aprono sempre la stessa voce di
  prova (per esempio `selM=1` in Messaggi). Nell'app ogni collegamento porta il cliente e il motivo da cui si parte
  (`StatoShell.apri(_:)` con il contesto).

---

## 1. Parte comune

*Parte 00 · titolo della bozza: «Orizzonte · 00 · Parte comune»*

Fonte: `Design/template-novita.html` (3 novembre 2026), confrontato riga per riga con `Design/template-apple.html`.
Per tutto ciò che qui non è detto vale `Design/template-apple-specifica.md`: token di §1, barra §3.3, dock §3.4,
finestra §3.5, scrivania §3.6, notifiche §3.8, tastiera §3.10.
Le cifre del template sono dimostrative: nell'app le danno i motori.

Riferimenti visivi (1480×940, palco 1440×900 scalato di 1,0137):
- `orizzonte/chiaro-01-scrivania.png`, `orizzonte/scuro-01-scrivania.png`: scrivania con il dock nuovo e «Il tuo studio» (il pannello Novità è a metà ingresso).
- `orizzonte/chiaro-02-novita.png`, `orizzonte/scuro-02-novita.png`: pannello Novità mentre entra.
- `orizzonte/spec/c-nov.png`, `orizzonte/spec/s-nov.png`: pannello Novità fermo, con la settima voce sotto il puntatore.
- `orizzonte/spec/tavola-icone.png`: Posizioni, Analisi 360, Ricerca (esistenti), poi Mercato, Studio e Messaggi (nuove), poi Prospetti e Clienti.
- `orizzonte/icone/Studio.svg`, `Messaggi.svg`, `Mercato.svg`: le tre sorgenti tolte dal `<template id="sorgenti-icone">`.

---

### 1. Cosa si vede

#### 1.1 Barra superiore

Uguale a template-apple (§3.3) con una pillola in più. A destra, in quest'ordine:

1. **«✦ Novità»** con il numero **«11»** in una pastiglia blu. È nuova.
2. «⌕ Cerca ⌘K», come prima.
3. La sfera di Ruby (24), la campanella con il badge rosso «3», il lucchetto e l'avatar «DV», come prima.

Il testo della pillola è blu accento, non nel colore dell'inchiostro sopra l'acqua. La pastiglia ha il fondo accento e la cifra bianca.

Rispetto alla barra che c'è già in Prisma (`Shell/BarraSuperiore.swift`) restano i tasti che il template non ha: guida, modalità cliente, impostazioni. La pillola Novità va subito prima di Cerca.

#### 1.2 Pannello «Le novità» (`#novP`)

È un vetro centrato sotto la barra, sopra la scrivania e le finestre. Contiene:

- **Testata:** «✦ Le novità» a sinistra; «11 funzioni da provare» a destra, in grigio.
- **11 voci**, una per riga. Ogni voce ha un pallino numerato da 1 a 11 (sfumato dall'azzurro al viola), il titolo in grassetto, la frase sotto in grigio e la freccia «›» blu a destra.

Testi esatti (numero · titolo · frase · dove porta):

| # | Titolo | Frase | Dove porta (template) |
|---|---|---|---|
| 1 | Studio | Il cruscotto del tuo lavoro: ricavi, obiettivi, proposte, incassi | Studio › Cruscotto |
| 2 | Prisma scrive per te | Ruby prepara i messaggi ai clienti, li spedisci tu | Messaggi, primo messaggio |
| 3 | Prisma conosce il mercato | Quote e tassi aggiornati, avvisi, chi è toccato | Mercato |
| 4 | Prisma ovunque | Una copia cifrata su iPhone e iPad, anche senza il Mac | Impostazioni › iPhone e iPad |
| 5 | Il copilota dell’incontro | Prisma ascolta e capisce mentre parli col cliente | Incontri |
| 6 | Inquadra e capisci | La polizza letta dalla fotocamera dell’iPhone | Posizioni › Portafoglio, poi lo scanner si apre da solo |
| 7 | La prova del fuoco | Uno scenario, tutto il portafoglio ricalcolato | Posizioni › Prova del fuoco |
| 8 | La linea della vita | Trascini gli eventi, il futuro si ricalcola | Clienti › Giulia Rossi › Linea della vita |
| 9 | Il tuo track record | Le raccomandazioni e come sono andate | Studio › Track record |
| 10 | Rispetto alle famiglie come la sua | Il cliente confrontato con chi gli somiglia | Analisi 360 › Rispetto alle famiglie come la sua |
| 11 | Allenamento OCF | Domande, ripasso e casi veri di Prisma | Studio › Esame OCF |

Gli apostrofi dei titoli 5 e 6 sono tipografici (’).

Stati: il template ha solo il pannello pieno. Non c'è uno stato vuoto, né caricamento, né errore. Proposta per Prisma, da confermare: una voce già aperta perde il pallino colorato (resta grigio) e il numero nella pillola conta solo quelle ancora da provare (vedi Dubbi).

#### 1.3 Dock

Dodici voci, in quest'ordine:

**Scrivania · Clienti · Posizioni · Analisi 360 · Incontri · Agenda · Messaggi · Prospetti · Mercato · Studio · Ruby · Impostazioni**

Rispetto a template-apple (8 voci) entrano Incontri, Messaggi, Mercato e Studio. Rispetto al dock di oggi in Prisma (`AppPrisma.delDock`: Clienti, Posizioni, Analisi 360, Incontri, Prodotti, Agenda, Note, Prospetti, Ruby, Ricerca, Impostazioni, più Scrivania) **escono Prodotti, Note e Ricerca** ed **entrano Messaggi, Mercato e Studio**. Le voci restano dodici.

L'icona Agenda mostra ancora la data («NOV» e «2»). Il pallino sotto l'app aperta e l'ingrandimento al passaggio del puntatore non cambiano.

#### 1.4 Le tre icone nuove

Sono nel `<template id="sorgenti-icone">` in fondo al file. Il commento che le accompagna dice: «Sorgenti vettoriali (512×512) delle icone nuove Studio, Messaggi e Mercato: stessa geometria e stessi effetti di Design/Icone. Da salvare in Design/Icone/ e convertire in PNG come le altre.»

**Come sono costruite.** Ho fatto il diff con `Design/Icone/Incontri.svg`: l'impianto è identico, riga per riga, a quello che produce `genera-icone.js`. Cambiano solo il titolo, le due fermate del gradiente `fondo` e il glifo:
- tela 512, piastrella 480×480 in (16, 12) con raggio 112,8 (23,5%);
- gradiente `fondo` a 165° (`x1 .342 y1 −.092 x2 .658 y2 1.092`);
- ombra esterna: `rect` 451,2 con raggio 98,4, nera al 32%, sfocata 33,6 e sfumata ai bordi con le maschere `bordoX` e `bordoY`;
- filo di luce: bianco al 55% con la maschera `luce`, spostata di 9,6;
- bordo: bianco al 22%, spesso 9,6;
- ombra interna: nera al 14%, sfocata 4,8, con la maschera `buio`;
- ombra del glifo: `dy 7.2`, sfocatura 4,8, nera al 22%;
- riflesso obliquo `riflesso`: bianco 0,36 → 0,07 → 0;
- glifo nel riquadro 64, con `translate(16 12) scale(7.5)`;
- `defs` comuni (`lgGlass`, `lgBeam`, `lgRubyOrb`) e classi `.g1 … .gws` dello stile «colori», con `.gs` bianco e `.g3` #FF3B30.

| Icona | Fondo c1 → c2 | Glifo |
|---|---|---|
| **Studio** | #7E97B3 → #3F5A78 (blu ardesia) | Valigetta. Il manico è `.g2` (bianco al 50%). Il corpo è un rettangolo `.g1` di 46×31 con raggio 7. Una fascia a y 33 alta 2,6, #3F5A78 al 22%. Una chiusura di 7×8,5 con raggio 2, #3F5A78 al 55%. |
| **Messaggi** | #F2A675 → #C8683A (terracotta) | Busta `.g1` di 48×34 con raggio 7. La «V» della busta è un tratto #C8683A al 55%, spesso 3,4, con capi tondi. In alto a destra un pallino rosso #FF3B30 (r 7,5) con una stellina bianca a quattro punte, il segno di Ruby. |
| **Mercato** | #5E6E80 → #2C3846 (grafite) | Area di un andamento in salita, `.g2`. Sopra, la linea bianca spessa 3,6 con capi tondi. Alla fine della linea un punto `.g1` (r 4,2). Sotto, la base: barretta bianca al 55%, alta 2,4. |

**Differenze rispetto alle icone esistenti:**
- I glifi di Studio e Messaggi usano colori scritti nel glifo stesso (#3F5A78, #C8683A, #FF3B30) oltre alle classi. Anche `Ruby.svg` lo fa già, quindi va bene. Però `genera-icone.js` legge colori e glifi solo da `Design/tema-liquid-glass.html` (tabelle `APPS` e `GLYPH`), dove queste tre app non ci sono. Lo script, così com'è, non le può rigenerare.
- Mercato (grafite) è molto vicino ad Analisi 360 (#4E6479 → #22323F), che nel dock gli sta a quattro posti. Il suo glifo (linea che sale con un punto in cima) somiglia a quello di Posizioni (`Analisi.svg`: barre e linea con un punto). Si vede in `tavola-icone.png`.
- Studio (#7E97B3) è vicino a Ricerca (#6E879E), che però esce dal dock.

#### 1.5 Riquadro «Il tuo studio» sulla scrivania

Prende il posto di **«☰ Da fare oggi»** (in basso a sinistra, accanto a «In scadenza entro 90 giorni»). Il clic apre Studio.

Contenuto, da sinistra:
- **Tre anelli concentrici** (116, tratto 11):
  1. esterno blu #2563EB al **82%**: Produzione Alleanza, nel template 410.000 € su 500.000 €;
  2. medio verde #30B15C al **70%**: Nuovi clienti, 7 su 10;
  3. interno cuoio #B06E12 al **77%**: Ricavi consulenza, 27.040 € su 35.000 €.

  Il significato degli anelli è scritto solo nella legenda di Studio › Cruscotto («Gli obiettivi dell’anno»). Sulla scrivania non c'è legenda.
- Testata: **«Il tuo studio · novembre»** a sinistra (il mese è quello corrente, in minuscolo); **«Apri Studio»** blu a destra.
- Tre cifre in fila, ognuna con l'etichetta sopra:
  - «Ricavi del mese» · **6.240 €**
  - «Da incassare» · **1.650 €**, in arancio
  - «Obiettivo consulenza» · **77%**

Stati: il template ha solo il riquadro pieno. Proposte per Prisma (§6):
- senza obiettivi dell'anno, anelli vuoti (solo binari) e la frase «Dai a Studio gli obiettivi dell’anno»;
- senza parcelle, «Da incassare» a 0 €;
- con le aliquote provvigionali mancanti, «Ricavi del mese» porta la nota «stima senza le tue aliquote».

#### 1.6 Finestre delle app nuove (solo la testata, il contenuto sta nelle altre parti)

| App | Titolo barra (`t`) | Titolo testata (`h`) | Occhiello (`sub`) | Comandi a destra (`act`) |
|---|---|---|---|---|
| Studio | Studio | Il tuo studio. | Il tuo lavoro, come un portafoglio | segmenti Cruscotto · Parcelle e fatture · Track record · Esame OCF |
| Messaggi | Messaggi | Prisma scrive per te. | Ruby prepara, tu spedisci | (parte Messaggi) |
| Mercato | Mercato | Prisma conosce il mercato. | Aggiornato oggi alle 18:00 · valori di prova | (parte Mercato) |
| Incontri | Incontri | Il copilota dell’incontro. | Dall’ascolto ai prossimi passi | (parte Copilota) |

In Prisma `h` corrisponde a `AppPrisma.titoloIntestazione` e `sub` a `AppPrisma.occhiello` (come «Le tue relazioni.» e «Rubrica Prisma» di Clienti).

#### 1.7 Tutte le differenze rispetto a template-apple nelle parti che esistono già

1. **Intestazione del file e `<title>`**: «Prisma · Template navigabile · le 11 novità».
2. **CSS**: nessun token di `:root`, `body` o `body.dark` cambia. Si aggiungono le classi di §2.6 (righe 186-215).
3. **Barra**: la pillola «✦ Novità 11» prima di Cerca (§1.1).
4. **Dock**: 12 voci invece di 8 (§1.3).
5. **Scrivania**: «Da fare oggi» (`data-go="agenda"`) diventa «Il tuo studio» (`data-go="studio"`, §1.5). Gli altri sette blocchi sono identici: saluto, pulsanti, mossa del giorno, agenda, portafoglio, Ruby, scadenze. Le attività di oggi restano visibili solo dentro «Prossimi incontri», per esempio «Preparare il fascicolo di Laura · Attività».
6. **Clienti**: nel dossier si aggiunge la scheda **«Linea della vita»** fra Obiettivi e Nel tempo. Ora sono cinque segmenti: Panoramica · Obiettivi · Linea della vita · Nel tempo · Famiglia. `dopoTab` chiama `montaVita` (parte Linea della vita).
7. **Posizioni**: l'app viene ridefinita (riga 954). Nella testata compaiono i segmenti **Portafoglio · Prova del fuoco** e il pulsante **«◎ Inquadra con l’iPhone»**. «Portafoglio» è la vista di prima. Si passa da una vista all'altra con `rimonta`.
8. **Analisi 360**: sopra la griglia delle quattro aree c'è il segmento **«Le quattro aree · Rispetto alle famiglie come la sua»**, con margine sotto di 12. La griglia diventa alta `calc(100% - 50px)`. Il cambio di cliente non dissolve più solo la griglia (140 ms) ma rimonta tutto il contenuto (`rimonta`, 130 ms).
9. **Impostazioni**: si aggiunge la sezione **«iPhone e iPad»** (indice 4). Nella colonna l'ordine diventa **Aspetto · iPhone e iPad · Archivio e backup · Ruby · Profilo**. `impAggancia` chiama `montaOvunque`.
10. **App nuove** nel registro `APPS`: Studio, Messaggi, Mercato, Incontri. Incontri c'è già in Prisma, ma non c'era in template-apple.
11. **Esc**: l'ordine diventa scanner aperto → pannello Novità → sala della presentazione → dettaglio → notifiche → finestra. Con lo scanner o il pannello Novità aperti, Esc chiude solo quello e si ferma.
12. **Sblocco**: alla prima apertura della sessione, 1,7 s dopo lo sblocco, il pannello Novità si apre da solo (`novVisto`).
13. **Funzioni d'appoggio nuove**:
    - `rimonta(html, dopo)`: il contenuto della finestra svanisce in 130 ms fino a scala 0,99, poi si rifà con cascata, numeri, anelli, linee e barre;
    - `vaiA(app, prep)`: chiude Novità e Notifiche, prepara la scheda e apre l'app. Se l'app è già davanti chiude il dettaglio e la rimonta senza volo.

Restano uguali: Agenda, Ruby, Prospetti, blocco, notifiche (testo e voci), toast, acqua, dettaglio, sala.

---

### 2. Misure e stile

Le misure sono in pt del palco 1440×900, prese dal CSS e dal JS.

#### 2.1 Pillola «✦ Novità»

| Cosa | Valore |
|---|---|
| Pillola | `.pill.glass` di `#bar`: padding 5×11, raggio 99, spazio interno 7, margine destro 6, 13 pt / 600 (semibold) |
| Colore testo | `var(--accent)` #007AFF (sia chiaro sia scuro) |
| Segno | «✦» (U+2726) come carattere, prima della parola |
| Pastiglia | fondo `--accent`, testo #fff, 10 pt (peso ereditato 600), padding 1×6, raggio 99 |
| Vetro | `.glass` come le altre pillole (sfocatura 16, saturazione 1,4, bordo `--glassE`) |

#### 2.2 Pannello Novità `#novP`

| Cosa | Valore |
|---|---|
| Posizione | assoluta, `left: calc(50% − 270px)`, cioè centrato nel palco; `top: 40` (6 sotto la barra da 34) |
| Larghezza | 540 |
| Altezza | quella del contenuto, al massimo 820, poi scorre (`overflow: auto`). Con 11 voci misura circa 643 |
| Raggio | 24 |
| Padding | 16 |
| Superficie | `.glass`: `--glass`, sfocatura 16, saturazione 1,4, bordo 1 `--glassE`, ombra `0 22 44 −24 rgba(8,40,60,.36)`, `0 3 10 −4 rgba(8,40,60,.12)` e filo `inset 0 1 0 rgba(255,255,255,.55)`; in scuro `0 26 52 −24 rgba(0,0,0,.7)` e filo bianco al 12% |
| Livello | z 62: sopra le notifiche (60) e sotto il blocco (90) |
| Testata | `.row`, margine sotto 6. «✦ Le novità» 16 pt bold `--ink`. «11 funzioni da provare» `.k` (12,5 pt, `--ink2`) spinta a destra |
| Voce `.novI` | flex, allineata al centro, spazio 12, padding 9×10, raggio 14, colore `--ink`, puntatore a mano. Passo fra le voci circa 53 |
| Titolo voce | `b` 14 pt bold |
| Frase voce | `.k` 12,5 pt `--ink2` |
| Pallino `.novN` | 26×26, raggio 99, `linear-gradient(135deg, #5AC8FA, #8B5CF6)`, testo #fff 12 pt / 700, centrato, non si stringe |
| Freccia | «›» `--accent`, 700 |
| Passaggio | fondo `--chip` (nero al 5% chiaro, bianco all'8% scuro) |

#### 2.3 Dock

Misure invariate (§3.4 della specifica): icona 50, voce 62, padding 8 10 5, spazio 4, raggio 26, 8 dal fondo, nome 10,5 pt / 500 `--wallInk`, pallino 4.
Con 12 voci la larghezza a riposo è 12·62 + 11·4 + 2·10 + 2 (bordo) = **810** (misurata: 821/1,0137 = 810). Il dock di template-apple, con 8 voci, era largo 546.
Ingrandimento invariato: s = 1 + 0,36·max(0, 1 − d/130) e voce larga 62·(1 + (s − 1)·0,7).

#### 2.4 Riquadro «Il tuo studio»

| Cosa | Valore |
|---|---|
| Posto | `left 44`, `top 612`, 660 × 168: stessa cella di «Da fare oggi» (`Tema.Apple.Scrivania.Disposizione.quoteRigaBassa = [660, 676]`, `rigaBassa = 168`) |
| Superficie | `.w.glass`: raggio 26, padding 18×20, colore `--ink` |
| Disposizione | flex in riga, spazio 22, allineato al centro verticale |
| Anelli | `anello(…, 116, 11)`: tratto 11, distanza fra gli anelli 11·1,22 = 13,42. Raggi 52,5 / 39,08 / 25,66. Binario dello stesso colore al 15%. Capi tondi, partenza a ore 12 (−90°) |
| Colori anelli | #2563EB, #30B15C, #B06E12, **fissi**: in scuro non diventano `--chA` / `--chI` schiariti |
| Testata | `b` 14 pt bold «Il tuo studio · novembre»; «Apri Studio» 13 pt / 600 `--accent`; `justify-content: space-between` |
| Riga cifre | margine sopra 10, spazio 30 |
| Etichette | `.k` 12,5 pt `--ink2` |
| Cifre | `--fontd` (SF Pro Display), 26 pt / 700. «Da incassare» in `--orange` #E08A00 |
| Formati | `eur`: punto delle migliaia, «€» staccato, niente decimali, meno tipografico «−». `pct`: arrotondato con «%» attaccato |
| Passaggio | sale di 3 con `--spring` in 0,45 s, come tutti i riquadri |

#### 2.5 Colori, token e curve nuove rispetto a template-apple

**Token CSS:** nessuno nuovo né cambiato. `--spring (.34,1.45,.64,1)` e `--out (.22,1,.36,1)` restano le uniche curve con nome.

**Colori nuovi della parte comune** (vanno in `Tema.Apple`):
- gradiente del numero Novità #5AC8FA → #8B5CF6 a 135°. Le due tinte ci sono già: `Tema.Apple.Colore.Investimenti.obbligazionario` (#5AC8FA) e `anello3` (#8B5CF6). Manca il gradiente;
- fondi delle icone: Studio #7E97B3 → #3F5A78, Messaggi #F2A675 → #C8683A, Mercato #5E6E80 → #2C3846. Servono solo allo script delle icone, non all'app;
- anelli di «Il tuo studio»: #2563EB (= canale Alleanza chiaro), #30B15C (= `anello1`), #B06E12 (= canale indipendente chiaro), fissi in tutti e due gli aspetti.

**Colori nuovi delle altre parti** (righe 186-215, da specificare lì, elencati per completezza):
- `.chip.on`: fondo `--red`;
- scanner: velo rgba(6,14,20,.55) con sfocatura 8; telefono #0d0f12 con filo #2a2e34 e tacca #000; fotocamera con gradiente radiale #4a423b → #1f1b18; foglio #fbfaf7 ruotato di −3° con ombra rgba(0,0,0,.5); righe #4a5560 e #1b2530; riga letta #34C759 con fondo rgba(52,199,89,.14);
- copilota: `.hl` con fondo rgba(0,122,255,.13), uguale a `selezioneVoce`;
- OCF: `.opz.giusta` #30B15C con fondo rgba(48,177,92,.1); `.opz.sbagliata` #E5484D con fondo rgba(229,72,77,.08);
- linea della vita: `.vEv.presa` con ombra 0 16 30 −10 rgba(8,40,60,.45);
- famiglie come la sua: barra `.dist` con gradiente rgba(229,72,77,.22) → rgba(224,138,0,.22) al 45% → rgba(47,163,90,.28).

**Curve nuove** (non `--spring` né `--out`), tutte delle altre parti:

| Curva | Dove | Durata |
|---|---|---|
| `(.34,1.3,.64,1)` | colonne degli incassi in Studio (`.colB`, scaleY 0 → 1, ritardo 300 + i·55); telefono dello scanner che entra (da y +60 e −4°) | 0,8 s; 0,7 s |
| `(.34,1.6,.64,1)` | punti del grafico «Il valore e il tempo» (scala 0 → 1, ritardo 400 + i·25); evento della linea della vita lasciato (scala 1,08 → 1) | 0,5 s; 0,35 s |
| `(.32,1.2,.5,1)` | righe della prova del fuoco che si riordinano (FLIP verticale) | 0,65 s |
| lineare (predefinita WAAPI) | `rimonta`: svanire a scala 0,99 | 0,13 s |

Animazioni a fotogrammi nuove: `scansiona` (linea dello scanner da top 110 a 420, 1,1 s ease-in-out, 2 volte avanti e indietro, si ferma in fondo) e `pulsa` (alone rosso 0 0 0 6 rgba(229,72,77,.18) a metà, 1,6 s, senza fine).

#### 2.6 Classi CSS nuove (righe 186-215) e parte a cui appartengono

`#novP`, `.novI`, `.novN` → comune · `.chip` → prova del fuoco · `.pt` → Studio (dispersione) · `.phone`, `#scan`, `.cam`, `.foglio`, `.fRiga`, `.linea` → Inquadra e capisci e Prisma ovunque · `.trR2`, `.hl` → copilota · `.opz` → OCF · `.vEv` → linea della vita · `.dist` → famiglie come la sua.

---

### 3. Movimento

#### 3.1 Pannello Novità

| Cosa | Da → a | Durata | Curva | Ritardo |
|---|---|---|---|---|
| Pannello che si apre | opacità 0, y −10, scala 0,97 → fermo | 0,38 s | `--spring (.34,1.45,.64,1)` | 0 |
| Voci a cascata | opacità 0, x +16 → ferme | 0,38 s | `--out (.22,1,.36,1)` | 0,06 + i·0,035 s (i = 0…10: da 0,06 a 0,41 s), `fill: backwards` |
| Passaggio su una voce | fondo trasparente → `--chip` | 0,2 s | ease | — |
| Chiusura | sparisce subito (`display: none`), senza animazione | — | — | — |
| Apertura automatica | dopo il primo sblocco della sessione | — | — | 1,7 s dopo lo sblocco |

Il centro della scala è il centro del pannello (origine CSS predefinita). Il pannello si comporta come quello delle notifiche: stessa durata, curva, spostamento e scala. Cambiano solo le voci: x +16 invece di +20, 0,38 s invece di 0,40, passo 35 ms invece di 70, partenza 60 ms invece di 80.

**Riduci movimento.** Il template, in `apriNov`, non guarda `ridotto`. In Prisma vale la regola generale: con `\.prismaCalmo` pannello e voci compaiono già fermi con una dissolvenza di 0,15 s, senza cascata. L'apertura automatica resta. Nelle istantanee (`\.modoIstantanea`) il pannello e le voci sono subito nello stato finale.

#### 3.2 Dock

Animazioni invariate: ingrandimento in 0,14 s; rimbalzo dell'icona all'apertura (−16, 0, −7, 0 in 0,7 s ease-out); pallino che compare in 0,3 s; risalita da +140 con la molla di 0,7 s, 0,2 s dopo lo sblocco. Con riduci movimento non si ingrandisce.

#### 3.3 Riquadro «Il tuo studio»

Entra nella cascata della scrivania come settimo blocco `.st` (indice 6). Ingresso: base 120 ms + 6·48 = 408 ms, 0,72 s, `--out`, da y +18, scala 0,985, sfocatura 6.

Cifre (`conteggi` sull'ordine dei `data-n` della scrivania: agenda 0, portafoglio 1, poi 2, 3 e 4 qui):
- 6.240 € conta in 1100 + 2·60 = **1,22 s**;
- 1.650 € in **1,28 s**;
- 77% in **1,34 s**.

Curva quartica 1 − (1 − t)⁴. Allo sblocco partono 0,30 s dopo.

Anelli (`accendi`, nell'ordine dei `data-fr`: i tre del portafoglio, poi i tre di qui, indici 3, 4 e 5). Si riempiono in 1,4 s con `--out`:
- dopo lo sblocco (`accendi(desk,300)` lanciato a 0,30 s): **0,99 / 1,12 / 1,25 s** (dopo i 0,60 / 0,73 / 0,86 del portafoglio);
- senza sblocco (`accendi(desk,0)`, base 200 ms): **0,59 / 0,72 / 0,85 s**.

In Prisma le costanti stanno in `Tema.Apple.Scrivania.Moto`: `ritardoAnelli` e `ritardoAnelliDopoSblocco` vanno estese da 3 a 6 tempi, oppure gli anelli di Studio partono con `+ 3·0,13`.

Passaggio del puntatore: sale di 3 con `--spring` 0,45 s.

Riduci movimento e istantanee: tutto subito fermo, come gli altri riquadri.

#### 3.4 Cambio di vista dentro un'app (`rimonta`)

Si usa per i segmenti nuovi di Studio, Posizioni e Analisi 360. Il contenuto svanisce in 0,13 s fino a scala 0,99, con curva lineare. Poi si rifà con `entrata` (cascata da 0, passo 48 ms), `conteggi`, `accendi(150)`, `linee` e `barre`. È lo stesso movimento del «cambio app con la finestra aperta» (0,15 s ease-in, scala 0,985), solo un po' più corto. In Prisma conviene **riusare** `Tema.Apple.Moto` per il cambio app: è un dubbio minore, in alternativa si aggiunge `Tema.Apple.Moto.Rimonta` (0,13, scala 0,99).

---

### 4. Interazioni

**Pillola «✦ Novità»:**
- clic: chiude le notifiche, poi apre il pannello o lo chiude se è aperto;
- il clic non arriva al palco (`stopPropagation`), quindi non chiude il pannello appena aperto.

**Pannello:**
- clic su una voce: chiude Novità e Notifiche, prepara la scheda giusta e apre l'app (`vaiA`);
  - se l'app è già quella davanti, chiude il dettaglio aperto e rimonta l'app senza il volo dall'icona;
  - altrimenti la apre come dal dock, con rimbalzo dell'icona e volo;
- voce 6 (Inquadra e capisci): dopo l'apertura di Posizioni si apre lo scanner, dopo 500 ms se Posizioni era già davanti, dopo 900 ms se no;
- clic in qualunque punto del palco fuori dal pannello e fuori dalla pillola: il pannello si chiude;
- passaggio del puntatore su una voce: fondo `--chip`. Le voci non si inclinano;
- Esc: chiude il pannello, ma solo se lo scanner non è aperto (Esc chiude prima lo scanner);
- rotella: scorre solo oltre 820 di altezza.

**Pannello e notifiche:**
- aprire Novità chiude le notifiche;
- aprire le notifiche **non** chiude Novità: la campanella ferma il clic, quindi possono stare aperti tutti e due, uno sopra l'altro. In Prisma propongo che si escludano a vicenda, come notifiche, spazi e ricerca (vedi Dubbi).

**Sblocco:** la prima volta nella sessione il pannello si apre da solo dopo 1,7 s.

**Dock:**
- clic: apre l'app;
- passaggio: ingrandimento;
- ⌥1…⌥9 per le prime nove app (`PrismaApp.swift` usa `AppPrisma.delDock.prefix(9)`). Con l'ordine nuovo: ⌥1 Clienti, ⌥2 Posizioni, ⌥3 Analisi 360, ⌥4 Incontri, ⌥5 Agenda, ⌥6 Messaggi, ⌥7 Prospetti, ⌥8 Mercato, ⌥9 Studio. Ruby e Impostazioni finiscono nel menu senza scorciatoia, mentre oggi ⌥8 è Prospetti e ⌥9 è Ruby. È un cambio visibile da annunciare.

**Riquadro «Il tuo studio»:**
- clic su un punto qualsiasi: apre Studio (scheda Cruscotto);
- «Apri Studio» è solo un'etichetta: fa lo stesso;
- passaggio: sale di 3.

**Tastiera (Esc), ordine completo:** scanner → Novità → sala → dettaglio → notifiche → finestra.

---

### 5. Mappa verso Prisma

#### 5.1 Da riusare (verificato con grep)

| Cosa | Dove |
|---|---|
| Elenco e ordine delle app, icone, titoli | `Sources/Prisma/Shell/AppPrisma.swift` (`AppPrisma`, `delDock`, `ospite`, `icona`, `titoloIntestazione`, `occhiello`, `inArrivo`) |
| App accorpate e scheda giusta all'apertura | `Shell/AppAccorpate.swift` (`preparaOspite(per:)`, `accorpataMostrata(in:)`), `Shell/StatoShellFinestre.swift` (`apri(_:da:)`) |
| Dock, ingrandimento, ⌥1…⌥9 | `Shell/Dock.swift` (`Dock`, `FilaDock`, `DisposizioneDock`), `PrismaApp.swift` (righe 104-109), `DesignSystem/Apple/Tema.Apple+DockFinestre.swift` |
| Barra superiore | `Shell/BarraSuperiore.swift` (`strumenti`, `PulsanteBarra`), token `Tema.Apple.BarraAlta` in `DesignSystem/Apple/Tema.Apple+BloccoBarraNotifiche.swift` |
| Modello per il pannello | `Shell/PannelloNotifiche.swift` (vetro, ingresso `entrataScheda`), `Tema.Apple.Moto.PannelloNotifiche` e `VoceNotifica` in `DesignSystem/Apple/TemaAppleMoto.swift`, `Tema.Apple.CentroNotifiche` |
| Stato dei pannelli | `Shell/StatoFinestre.swift` (`pannelloNotifiche`, `pannelloSpazi`, `pannelloRicerca`, `guida`), `Shell/Notifiche.swift` (`alternaNotifiche()`) |
| Scrivania e riquadro da sostituire | `Shell/ScrivaniaApple.swift` (`RiquadroDaFare`, riga 1050; `righeLarghe` e `righeStrette`), `DesignSystem/Apple/Tema.Apple+Scrivania.swift` (`quoteRigaBassa`, `Moto.ritardoAnelli…`), `DesignSystem/Apple/Tema.Apple+ScrivaniaiPad.swift` |
| Anelli e cifre che contano | `DesignSystem/Apple/AnelliApple.swift` (`AnelliConcentrici`, `VoceAnello`), `DesignSystem/Apple/CifreApple.swift` (`NumeroCheConta`) |
| Colori | `DesignSystem/Apple/TemaApple.swift` (`accento`, `arancio`, `anello1`, `anello3`, `canaleAlleanza`, `canaleIndipendente`, `chip`, `Investimenti.obbligazionario`) |
| Ricerca fuori dal dock | `stato.alternaRicerca()` e `pannelloRicerca` ci sono già: la pillola «Cerca ⌘K» resta l'ingresso |
| Dati di base per Studio | `Dati/Posizione.swift` (`canale`, `stato`, `decorrenza`, `premio`, `frequenza`, `versamentoIniziale`, `seguito`), `Dati/SeguitoProposte.swift` (esiti), `Dati/Modelli.swift` (`Cliente.creatoIl`) |
| Script delle icone | `Design/Icone/genera-icone.js`, `Design/Icone/LEGGIMI.txt`, PNG in `Sources/Prisma/Risorse/Icone/` |
| Prove | `Ruby/ProvaRuby.swift` riga 423 (`delDock.count == 11`), `iOS/ProvaDockMobile.swift`, `Motori/ProvaCalcoli.swift` |

#### 5.2 Cosa manca e cosa cambia

**`AppPrisma`:**
- nuovi casi `messaggi`, `mercato`, `studio`;
- nuovo ordine di `allCases`, per avere nel dock: `clienti, posizioni, analisi360, incontri, agenda, messaggi, presentazioni, mercato, studio, ruby, impostazioni`;
- `prodotti`, `note` e `ricerca` escono dal dock. Restano casi dell'enum, perché archivio, spazi, promemoria e iPhone li usano, ma serve un `ospite` (vedi Dubbi). Una proposta: Prodotti in Posizioni (o in Mercato), Note in Clienti (scheda `note`, che c'è già in `SchedaCliente`), Ricerca senza finestra (solo il pannello ⌘K);
- testi:
  - `titolo` / `nomeDock`: «Studio», «Messaggi», «Mercato»;
  - `titoloIntestazione`: «Il tuo studio.», «Prisma scrive per te.», «Prisma conosce il mercato.», e per Incontri «Il copilota dell’incontro.» (oggi è «Incontri»);
  - `occhiello`: «Il tuo lavoro, come un portafoglio», «Ruby prepara, tu spedisci», per Mercato «Aggiornato … · …» calcolato dal motore del mercato, per Incontri «Dall’ascolto ai prossimi passi» (oggi «Il tempo della relazione»);
  - `sottotitolo` e `inArrivo` per i tre casi nuovi;
- `icona`: «Studio», «Messaggi», «Mercato».

**Icone:**
- salvare `Design/Icone/Studio.svg`, `Messaggi.svg` e `Mercato.svg` (sono quelle in `orizzonte/icone/`);
- portare in `genera-icone.js` una tabella `ICONE_NUOVE` con c1, c2 e glifo, letta da `template-novita.html` (`<template id="sorgenti-icone">`) o scritta nello script, perché il tema Liquid Glass non le contiene;
- generare le PNG 512 in `Sources/Prisma/Risorse/Icone/`;
- aggiornare `Anteprima_icone.png` e la mappatura in `LEGGIMI.txt`.

**Barra:**
- `PulsanteBarra(forma: .pillola)` «✦ Novità» con la pastiglia, prima di Cerca, solo quando c'è qualcosa da mostrare (vedi Dubbi);
- token nuovi in `Tema.Apple.BarraAlta`: `paddingPastigliaNovita = EdgeInsets(1, 6, 1, 6)`, `pastigliaNovita = Carattere(dimensione: 10, peso: .semibold)`, colore testo `Colore.accento`.

**Pannello:**
- vista nuova `Shell/PannelloNovita.swift`, sul modello di `PannelloNotifiche`;
- `@Published var pannelloNovita = false` in `StatoFinestre`;
- `alternaNovita()` in `StatoShell`, che chiude notifiche, spazi e ricerca. Anche `alternaNotifiche()` deve chiudere Novità;
- livello: z tra notifiche (60) e blocco (90), proposto 62 come nel template;
- Esc: va gestito prima di dettaglio, notifiche e finestra.

**Token nuovi** in `DesignSystem/Apple/Tema.Apple+Novita.swift` (nome proposto):
- `Tema.Apple.Novita`: `larghezza 540`, `dallAlto 40`, `altezzaMassima 820`, `raggio 24`, `padding 16`, `spazioTestata 6`, `paddingVoce (9, 10)`, `raggioVoce 14`, `spazioVoce 12`, `numero 26`;
- caratteri: `titolo 16 bold`, `conteggio 12,5 regular inchiostro2`, `titoloVoce 14 bold`, `fraseVoce 12,5 inchiostro2`, `cifra 12 bold bianco`, `freccia bold accento`;
- `fondoPassaggio = Colore.chip`;
- `gradienteNumero [#5AC8FA, #8B5CF6]` a 135°: in `Gradienti.swift`, oppure come `Tema.Apple.Colore.numeroNovita`;
- `Tema.Apple.Moto.PannelloNovita`: uguale a `PannelloNotifiche` (0,38, y −10, scala 0,97, molla, ripiego `Molla(0.38, 0.65)`);
- `Tema.Apple.Moto.VoceNovita`: durata 0,38, spostamento 16, base 0,06, passo 0,035, curva `uscita`;
- `aperturaAutomatica = 1.7`.

**Modello delle novità:**
- `Dati/Novita.swift` (nome proposto): `enum NovitaOrizzonte: String, CaseIterable, Codable` con 11 casi: `studio, scrivePerTe, mercato, ovunque, copilota, inquadra, provaDelFuoco, lineaDellaVita, trackRecord, famiglieComeLaSua, allenamentoOCF`;
- per ogni caso: `titolo`, `frase` e `destinazione`. La destinazione è un'app e una scheda;
- schede nuove da creare nelle altre parti:
  - `SchedaStudio` (cruscotto, parcelle, track record, OCF);
  - `VistaPosizioni` (portafoglio, prova del fuoco);
  - `SchedaCliente.lineaDellaVita`;
  - `VistaAnalisi360` (aree, famiglie come la sua);
  - `SchedaImpostazioni.iPhoneiPad`;
- `StatoShell.apriNovita(_:)` imposta la scheda (come `preparaOspite`) e poi chiama `apri(_:)`. Se l'app è già davanti, cambia solo la scheda.

**Scrivania:**
- `RiquadroStudioScrivania` al posto di `RiquadroDaFare` in `righeLarghe`;
- sull'iPad in verticale (`righeStrette`, dove «Da fare oggi» sta nella riga di mezzo accanto a Ruby) va deciso se sostituirlo anche lì (vedi Dubbi);
- iPhone: `GuscioiPhone` mostra le attività di oggi e non cambia, salvo decisione diversa;
- il motore delle cose da fare (`MotoreDaFare`) resta, perché le attività compaiono già fra i «Prossimi incontri».

#### 5.3 Motori nuovi

**`Motori/MotoreStudio.swift`** (nome proposto). Funzioni pure che preparano le cifre del riquadro (e del Cruscotto, parte Studio):
- `ricaviDelMese(mese:)` = provvigioni Alleanza stimate del mese + parcelle indipendenti del mese;
  - provvigioni stimate = Σ, sulle posizioni Alleanza in essere con decorrenza o rata nel mese, di (premio o versamento × aliquota del tipo di prodotto);
  - parcelle del mese: per data di emissione o di incasso, da decidere (vedi Dubbi);
- `daIncassare()` = Σ delle parcelle in stato «Da incassare». Le bozze non contano, le pagate nemmeno. Nel template 900 + 750 = 1.650 €;
- `obiettivi(anno:)` restituisce tre `AvanzamentoObiettivo(valore, traguardo, quota)`:
  - produzione Alleanza dell'anno (410.000 / 500.000 = 82%);
  - nuovi clienti dell'anno (7 / 10 = 70%);
  - ricavi della consulenza dell'anno (27.040 / 35.000 = 77,3%, mostrato 77%);
  - la quota è limitata fra 0 e 1 solo nel disegno dell'anello: la cifra può superare il 100%;
- «Obiettivo consulenza» è la terza quota.

Le cifre restano solo sul Mac, come il resto.

#### 5.4 Campi nuovi dell'archivio (versione 26, nomi proposti)

Letti con tolleranza, come `SeguitoProposta`. Un archivio di prima si apre senza errori.

- `DatiPrisma.parcelle: [Parcella]`. Il dettaglio sta nella parte Studio › Parcelle e fatture. Per il riquadro servono `id`, `clienteId`, `numero`, `descrizione`, `importo`, `stato` (`bozza`, `daIncassare`, `pagata`), `emessaIl`, `pagataIl?`;
- `Impostazioni.studio: ImpostazioniStudio`:
  - `obiettiviAnno: [Int: ObiettiviAnno]`, con `ObiettiviAnno` = `produzioneAlleanza: Double?`, `nuoviClienti: Int?`, `ricaviConsulenza: Double?`;
  - `aliquoteProvvigioni: [String: Double]`, per tipologia di prodotto Alleanza, oppure `[AreaPosizione: Double]`;
- `Impostazioni.novitaProvate: Set<NovitaOrizzonte>`: le voci già aperte, per il numero nella pillola;
- `Impostazioni.novitaMostrateVersione: String?`, per esempio «orizzonte»: il pannello si apre da solo una volta per versione, non una volta per sessione come nel template;
- `Cliente.clienteDal: Date?`, facoltativo, per contare i «nuovi clienti» dell'anno senza basarsi su `creatoIl`, che è la data di inserimento in Prisma (vedi Dubbi).

**Backup:** parcelle e impostazioni dello studio vanno nel backup. `Prisma --prova-backup` (`Dati/ProvaBackup.swift`) deve verificare che parcelle, obiettivi e aliquote tornino uguali dopo il ripristino, e che un archivio versione 25 si apra.

#### 5.5 Prove nuove

**`Motori/ProvaCalcoliStudio.swift`**, collegata da `ProvaCalcoli.swift`, con i casi del template:
- 82%, 70% e 77% dai valori 410.000/500.000, 7/10 e 27.040/35.000;
- 1.650 € da incassare con una bozza da 450 € e due parcelle pagate escluse;
- una provvigione stimata con un'aliquota nota;
- con l'aliquota mancante la provvigione non entra e il motore lo segnala;
- un obiettivo a 0 o assente dà «nessun obiettivo», non una divisione per zero;
- un valore oltre il traguardo dà più del 100% nella cifra e l'anello pieno.

**`Shell/ProvaNovita.swift`** (o dentro `ProvaRuby`):
- 11 voci, titoli unici;
- ogni destinazione è un'app del dock;
- `apriNovita` imposta la scheda giusta;
- aprire Novità chiude le notifiche e viceversa.

**`Ruby/ProvaRuby.swift`:** riga 423 da aggiornare. Il conteggio resta 11, ma va controllato anche l'ordine nuovo, e che Prodotti, Note e Ricerca non abbiano una finestra propria sul Mac.

**`iOS/ProvaDockMobile.swift`:** il dock dell'iPhone non ripete app e contiene solo app di Prisma, anche con i tre casi nuovi.

---

### 6. Dati che l'utente deve dare

Prisma non li inventa mai. Finché mancano, l'interfaccia mostra cosa manca oppure, solo con i dati di prova caricati, i valori di prova con l'etichetta «dati di prova».

| Dato | A cosa serve | Finché manca |
|---|---|---|
| **Obiettivi dell'anno**: produzione Alleanza (in € e con quale definizione: premi annui, versamenti, capitali?), numero di nuovi clienti, ricavi della consulenza in € | i tre anelli e «Obiettivo consulenza» | anelli vuoti (solo binari); «Obiettivo consulenza» mostra «—» con la frase «Dai a Studio gli obiettivi dell’anno» |
| **Aliquote provvigionali Alleanza** per tipo di prodotto (e se diverse fra primo anno e rinnovi) | provvigioni stimate in «Ricavi del mese» | si sommano solo le parcelle; sotto la cifra «stima senza le tue aliquote» |
| **Parcelle** della consulenza indipendente (numero, cliente, importo, stato, date) | «Da incassare», ricavi della consulenza | «Da incassare» 0 € |
| **Data di inizio del rapporto** coi clienti già in archivio | «Nuovi clienti» dell'anno | si usa `creatoIl` con la nota «dalla data di inserimento in Prisma», oppure l'anello resta vuoto (da decidere) |
| Conferma dell'**ordine del dock** e di dove vanno Prodotti, Note e Ricerca | dock | — |

**Dati di prova** (i 5 clienti del template e i 30 fittizi caricabili da Impostazioni): per valutare il motore si possono caricare con loro i valori del template:
- obiettivi 500.000 € / 10 / 35.000 €;
- le cinque parcelle `FATT`: 2026/016 Bozza 450 €; 2026/015 Da incassare 900 €; 2026/014 Pagata 1.200 €; 2026/013 Pagata 1.500 €; 2026/012 Da incassare 750 €;
- aliquote di prova dichiarate tali.

Vanno in `Dati/DatiDemo.swift` e `Dati/ClientiFittizi.swift`, e non compaiono mai in un archivio vero se non le carica l'utente.

---

### 7. Istantanee da aggiungere

La serie 5xx è libera (verificato con grep). Ogni istantanea va fatta in chiaro e in scuro (suffisso `-scuro`, come per le altre).

| Nome | Scena |
|---|---|
| `500-scrivania-orizzonte` / `-scuro` | scrivania sbloccata con il dock a 12 voci e «Il tuo studio» con i dati di prova (anelli pieni, cifre complete) |
| `501-novita-pannello` / `-scuro` | pannello Novità aperto sulla scrivania, 11 voci ferme, nessuna sotto il puntatore |
| `502-novita-provate` / `-scuro` | il pannello con tre voci già aperte (pallino grigio, numero «8» nella pillola), se si accetta la proposta |
| `503-scrivania-studio-vuoto` / `-scuro` | «Il tuo studio» senza obiettivi né parcelle: binari vuoti e frase d'invito |
| `504-dock-ingrandito-orizzonte` | il dock con il puntatore su Mercato (ingrandimento con 12 voci, nome nel fumetto) |
| `505-finestre-app-nuove` / `-scuro` | finestra di Studio aperta, per controllare icona, titolo, occhiello e pallino del dock (il contenuto sta nella parte Studio) |
| `506-icone-orizzonte` | tavola delle icone del dock su fondo chiaro e scuro (come `Anteprima_icone.png`), per confrontare Mercato con Analisi 360 e Posizioni |
| `410-scrivania-apple` / `-scuro` (esistente) | da rifare: cambia il riquadro in basso a sinistra |
| `400-vetrina-apple` / `-scuro` (esistente) | aggiungere alla vetrina il pannello Novità (una voce con il passaggio) e il riquadro dello studio |

Sull'iPad: le istantanee della scrivania (orizzontale e verticale, scattate dal workflow iOS) vanno rifatte se si sostituisce «Da fare oggi» anche lì.

---

## 2. Studio › Cruscotto

*Parte 01 · titolo della bozza: «01 · Studio › Cruscotto»*

Fonte: `Design/template-novita.html`. Le righe citate sono di quel file: `NOV[0]` (731), `APPS.studio` (765-767), `studioHTML()` ramo `cruscotto` (769-785), `montaStudio()` ramo `cruscotto` (822-826), utilità comuni (255-285), CSS (17-218).
Schermate: `orizzonte/chiaro-10-studio.png`, `orizzonte/scuro-10-studio.png` (1480×940).
Per tutto ciò che qui non è detto (finestra, barra, dock, segmentato, card, cascata, numeri che si contano, anelli, linee) vale `Design/template-apple-specifica.md`.
**Le cifre del template sono dimostrative.** Nell'app arrivano tutte dai motori (§5). Se un dato manca si vede lo stato «dati di prova» o lo stato vuoto (§6), mai un numero inventato.

---

### 1. Cosa si vede

#### 1.1 L'app Studio e le sue schede
- **Studio è un'app nuova** nel dock. In `DOCK` (358) sta tra Mercato e Ruby: `['studio','Studio','Studio']`. Icona `Studio` (una valigetta in vetro); in `Design/Icone/` **non c'è ancora**.
- Finestra interna standard (`#win`, 1408×758, in alto a sinistra a 16/42):
  - barra del titolo con l'icona e la parola **«Studio»**;
  - intestazione con il titolo h1 **«Il tuo studio.»** e il sottotitolo `.sub` **«IL TUO LAVORO, COME UN PORTAFOGLIO»** (nel sorgente è «Il tuo lavoro, come un portafoglio»; il maiuscolo lo fa il CSS);
  - a destra (`#wAct`) il segmentato `.seg` con le quattro schede **«Cruscotto» · «Parcelle e fatture» · «Track record» · «Esame OCF»** (valori `cruscotto`, `fatture`, `track`, `ocf`). Si apre su Cruscotto (`let tabS='cruscotto'`, 750).
- Arrivi:
  - dal dock (icona Studio);
  - dal pannello Novità, voce 1: **«Studio»**, con la descrizione **«Il cruscotto del tuo lavoro: ricavi, obiettivi, proposte, incassi»** (`vaiA('studio',()=>{tabS='cruscotto'})`);
  - dal widget della scrivania **«Il tuo studio · novembre»** con il collegamento **«Apri Studio»** (391-394; è della parte Scrivania, ma usa gli stessi numeri: «Ricavi del mese», «Da incassare», «Obiettivo consulenza»).
- Questa parte specifica solo la scheda **Cruscotto**. Le altre tre hanno una specifica propria.

#### 1.2 La griglia del Cruscotto
L'area dei contenuti (`#wc`) è 1384×654 (12 di margine a sinistra, a destra e in basso; parte a 92 dall'alto della finestra). Le cinque card sono posizionate in modo assoluto, su due righe:

| # | Card | x | y | larghezza | altezza |
|---|------|---|---|-----------|---------|
| 1 | I tuoi ricavi 2026 | 0 | 0 | 560 | 300 |
| 2 | Gli obiettivi dell'anno | 576 | 0 | 408 | 300 |
| 3 | L'imbuto delle proposte | 1000 | 0 | fino al bordo destro (384) | 300 |
| 4 | Gli incassi dei prossimi 12 mesi | 0 | 316 | 760 | fino in fondo (338) |
| 5 | Il valore e il tempo | 776 | 316 | fino al bordo destro (608) | fino in fondo (338) |

Lo spazio tra le card è sempre **16**. Nel porting conviene una griglia proporzionale e non le misure assolute: la prima riga è 560 : 408 : 384, la seconda 760 : 608, l'altezza della prima riga è 300 su 654.

#### 1.3 Card 1 — «I TUOI RICAVI 2026»
- Etichetta `.lbl`: **«I tuoi ricavi 2026»**. L'anno è quello in corso.
- Sotto, in riga (allineata in basso, spazio 14, 10 dall'etichetta):
  - il numero grande `.bignum` **«68.420 €»** (si conta da 0), cioè i ricavi dell'anno fino a oggi;
  - accanto, in verde (`--green`, peso 600, 6 di spazio sotto), **«+18% sul 2025»**: la variazione rispetto allo **stesso periodo** dell'anno precedente. Nel template le due curve confermano il confronto «a pari data»: 68,4 contro 58 mila.
- Due tile affiancate (spazio 10, 14 dal numero, `flex:1`):
  - tile Alleanza: etichetta canale `.chA` **«Alleanza»**, valore `.v` **«41.380 €»**, didascalia `.k` **«provvigioni stimate dalle tue aliquote»**;
  - tile Indipendente: etichetta canale `.chI` **«Indipendente»**, valore **«27.040 €»**, didascalia **«parcelle della consulenza»**.
  - Le due tile sommano il numero grande (41.380 + 27.040 = 68.420).
- Grafico lineare: SVG 512×56, 12 sotto le tile, senza assi.
  - Linea **2026** piena, colore `#0A84FF` (`Tema.Apple.Colore.anello2` / `bluGrafico`), spessore 2,6.
  - Linea **2025** tratteggiata (4 e 5), colore `--ink3`, spessore 2.
  - Sono **ricavi cumulati**, 13 punti: inizio d'anno e la fine di ogni mese (`a=[2,6,11,…,68.4]`, `b=[1.6,…,58]` in migliaia). X = i/12·512; Y = 54 − v/70·52 (la scala arriva a 70 mila; nel porting il massimo è il più alto dei due valori finali + un margine).
  - Etichette in fondo a destra, 11 pt: «2026» (blu, peso 600) 6 sopra la fine della linea blu; «2025» (`--ink3`) 14 sotto la fine della linea grigia.
  - **Nota:** nel template la linea 2026 arriva al bordo destro (dicembre) anche se oggi è novembre. Nell'app la linea dell'anno in corso si ferma **a oggi**; quella dell'anno prima va fino a dicembre (vedi Dubbi).

#### 1.4 Card 2 — «GLI OBIETTIVI DELL'ANNO»
- Etichetta: **«Gli obiettivi dell'anno»**.
- In riga (spazio 18, 14 dall'etichetta): tre anelli concentrici da 170 con spessore 15 (`anello(…,170,15)`) e la legenda.
- Anelli, dall'esterno:
  1. **Produzione Alleanza**: 82%, colore `#2563EB`;
  2. **Nuovi clienti**: 70%, colore `#30B15C`;
  3. **Ricavi consulenza**: 77%, colore `#B06E12`.
- Legenda `.leg` (13 pt, interlinea 1,35), una voce per anello con il pallino del suo colore:
  - **«Produzione Alleanza»** / `.k` **«410.000 € di 500.000 €»**;
  - **«Nuovi clienti»** / **«7 su 10»**;
  - **«Ricavi consulenza»** / **«27.040 € di 35.000 €»**.
- I «Ricavi consulenza» sono gli stessi della tile Indipendente della card 1: è lo stesso numero e deve venire dallo stesso calcolo.
- Al centro degli anelli non c'è niente.

#### 1.5 Card 3 — «L'IMBUTO DELLE PROPOSTE»
- Etichetta: **«L'imbuto delle proposte»**.
- Tre righe. Ognuna ha il nome a sinistra, il numero in grassetto a destra (si conta) e sotto una barra alta 14:
  - **«Preparate»** 42, barra `#9FB3C2`, sempre piena (42/42);
  - **«Presentate»** 31, barra `#5AC8FA`, al 31/42;
  - **«Firmate»** 19, barra `#30B15C`, al 19/42.
- Sotto, due cifre (`.v` a 24 pt) con didascalia:
  - **«45%»** (si conta) / **«vanno in porto»**: firmate su preparate (19/42 = 45,2%);
  - **«23 gg»** / **«alla firma, in media»**.
- Riga finale `.k`, 8 sotto: **«Si fermano soprattutto dopo la presentazione: 12 proposte.»** Il 12 è 31 − 19, cioè le proposte presentate ma non firmate. Il motore sceglie la fase con la perdita più grande:
  - «…dopo la presentazione: N proposte.» quando la perdita più grande è tra presentate e firmate;
  - «…prima della presentazione: N proposte.» quando è tra preparate e presentate (testo nuovo, da confermare).
- Nella schermata la frase va su due righe e la parola «proposte.» finisce a capo. Va bene così.

#### 1.6 Card 4 — «GLI INCASSI DEI PROSSIMI 12 MESI»
- Intestazione in riga: etichetta **«Gli incassi dei prossimi 12 mesi»** e, a destra, il totale **«65.800 €»** (font display, 20 pt, peso 700; si conta).
- Didascalia `.k`: **«Rinnovi e premi ricorrenti Alleanza, parcelle già firmate. Stima con le tue aliquote.»**
- Istogramma a colonne impilate: 12 colonne, una per mese, **dal mese prossimo** (`MESI12` comincia da «dic» quando oggi è novembre) fino al mese corrente dell'anno dopo («nov»).
  - Ogni colonna è divisa in due parti: sotto **Alleanza** (`--chA`), sopra **Indipendente** (`--chI`, opacità 0,9).
  - L'altezza è proporzionale al mese più alto, che arriva a 190.
  - Sotto ogni colonna c'è il mese abbreviato in minuscolo, 11 pt `.k`: «dic gen feb mar apr mag giu lug ago set ott nov».
  - Niente assi, niente valori sulle colonne.
  - Il totale è la somma di tutti i mesi e di tutti e due i canali.

#### 1.7 Card 5 — «IL VALORE E IL TEMPO»
- Etichetta **«Il valore e il tempo»** e didascalia `.k`: **«Ogni punto è un cliente: ore che gli dedichi nell'anno e ricavi che genera.»**
- Grafico a dispersione alto 250, 12 sotto la didascalia:
  - **asse x**: ore nell'anno, da 0 a 30. Etichette in basso: a sinistra **«0 ore»**, a destra **«30 ore l'anno»** (11 pt, `--ink3`);
  - **asse y**: ricavi del cliente nell'anno, da 0 (in basso) a 4.600 (in alto), senza etichette;
  - **punti dei clienti in evidenza**: i 5 del template, cerchi da 28 con il gradiente dell'avatar, le iniziali bianche a 10 pt peso 700 e un'ombra `0 4px 10px rgba(0,0,0,.22)`, sopra gli altri;
  - **altri clienti**: pallini da 12, colore `--ink3`, opacità 0,55;
  - **zona evidenziata**: rettangolo dal 55% della larghezza fino al bordo destro e dal 62% dell'altezza fino a 20 dal fondo. Raggio 12, colore `rgba(229,72,77,.07)`. In basso a destra c'è la scritta rossa (`--red`, 11 pt) **«molto tempo, poco valore»**. Corrisponde a più di 16,5 ore e meno di circa 1.750 € l'anno.
- Fumetto al passaggio (`title`): **«Nome · N ore · X €»** per i clienti in evidenza e **«N ore · X €»** per gli altri.
- **Difetto del template:** le x sono calcolate su una larghezza di 330 (`W=330`) mentre la card ne offre circa 560. Così i punti stanno tutti nella metà sinistra mentre l'etichetta «30 ore l'anno» è al bordo destro. Nell'app la larghezza è quella vera del grafico.

#### 1.8 Stati
Il template non ha stati di caricamento, errore o vuoto. Per l'app:
- **Caricamento:** nessuno. I motori sono sincroni sui dati in memoria e si calcolano fuori dal `body` (cache, come `CacheMotoriPosizioni`).
- **Vuoto (nessun cliente o nessuna posizione):** ogni card mantiene il titolo e mostra una frase in `.k` al posto del contenuto, senza grafici finti:
  - Ricavi: «Ancora nessun ricavo nel {anno}. Le provvigioni arrivano dalle posizioni Alleanza in essere, le parcelle da Parcelle e fatture.»
  - Obiettivi: «Imposta gli obiettivi dell'anno» (pulsante che apre Impostazioni › Studio).
  - Imbuto: «Nessuna proposta nel {anno}.»
  - Incassi: «Nessun incasso previsto nei prossimi 12 mesi.»
  - Valore e tempo: «Servono appuntamenti con una durata per contare le ore.»
- **Dati parziali:** vedi §6. Per esempio, ci sono le provvigioni ma mancano le aliquote; c'è l'anno in corso ma manca quello prima.

---

### 2. Misure e stile

#### 2.1 Gettoni (CSS `:root`/`body`, 17-23) e corrispondenze in Prisma
| CSS | Chiaro | Scuro | Prisma |
|-----|--------|-------|--------|
| `--card` | rgba(255,255,255,.82) | rgba(255,255,255,.07) | `Tema.Apple.Colore.card` |
| `--sep` | rgba(0,0,0,.08) | rgba(255,255,255,.09) | `Colore.separatore` |
| `--shadow` | 0 24px 48px -28px rgba(8,40,60,.4), 0 2px 8px -3px rgba(8,40,60,.1) | 0 26px 52px -26px rgba(0,0,0,.8), 0 3px 10px -3px rgba(0,0,0,.35) | ombra `.card` |
| `--ink` / `--ink2` / `--ink3` | nero .87 / .55 / .34 | bianco .94 / .62 / .38 | `inchiostro`, `inchiostro2`, `inchiostro3` |
| `--track` | rgba(0,0,0,.07) | rgba(255,255,255,.1) | binario delle barre |
| `--chA` | #2563EB | #6B95FF | `Colore.canaleAlleanza` |
| `--chI` | #B06E12 | #D0954A | `Colore.canaleIndipendente` |
| `--green` | #2FA35A | uguale | `Colore.verde` |
| `--red` | #E5484D | uguale | `Colore.rosso` |
| `--r1` / `--r2` | #30B15C / #0A84FF | uguali | `anello1` / `anello2` |
| `--out` | cubic-bezier(.22,1,.36,1) | | `Moto.Curva.uscita` |
| `--spring` | cubic-bezier(.34,1.45,.64,1) | | `Moto.Curva.molla` |

Colori fissi del Cruscotto, **uguali in chiaro e in scuro** nel template:
- anelli e pallini della legenda: #2563EB, #30B15C, #B06E12;
- barre dell'imbuto: #9FB3C2, #5AC8FA, #30B15C;
- linea 2026: #0A84FF.

Tutti esistono già in `TemaApple.swift` (righe 58-60, 92-93, 128-137, 200). Vanno raccolti in un nuovo `Tema.Apple+Studio.swift` (`Tema.Apple.Studio`). Le colonne degli incassi usano invece `--chA`/`--chI`, che cambiano nello scuro (nella schermata scura il blu è #6B95FF).

#### 2.2 Superfici
- **Card** (`.card`): raggio 22, riempimento `--card`, bordo 1 `--sep`, ombra `--shadow`, padding 22 (sopra e sotto) e 24 (ai lati). In Prisma: `Superficie.card` + `Misura.padding.cardGrande` (22, 24). Le card del Cruscotto **non si inclinano** (non hanno `.tilt`).
- **Tile** (`.tile`): raggio 18, riempimento `--card`, bordo 1 `--sep`, padding 14/16. In Prisma: `Superficie.tile` + `padding.tile`.
- **Etichetta canale** `.chA` / `.chI`: capsula, 11,5 pt peso 600, padding 3/9, spazio 5, pallino da 6 nel colore del testo. Sfondo rgba(37,99,235,.13) / rgba(176,110,18,.14). In Prisma: `EtichettaCanaleApple` (`PulsantiApple.swift:137`), padding `Misura.padding.etichettaCanale`.
- Niente vetro dentro le card: il vetro è solo della finestra (`--win`, sfocatura 34, saturazione 1,3).

#### 2.3 Caratteri
| Elemento | CSS | Prisma |
|----------|-----|--------|
| Titolo finestra h1 | display 17 pt, 700 | esistente |
| Sottotitolo `.sub` | 12 pt, 500, maiuscolo, spaziatura .6, `--ink2` | esistente |
| Segmentato | 13 pt, 600, padding 6/14, pillola `--cardE` con ombra 0 1px 4px rgba(0,0,0,.14) | `SegmentatoPillola` |
| `.lbl` (titoli delle card) | 12 pt, 600, maiuscolo, spaziatura .6, `--ink2` | `Carattere.etichetta` |
| Ricavi (`.bignum` ridotto) | display **52 pt**, 700, spaziatura −2,2, cifre tabellari, interlinea 1 | **nuovo**: `numeroGrande` è a 62, serve `Tema.Apple.Studio.ricavi` a 52 |
| «+18% sul 2025» | testo 15 pt (eredita), 600, verde | nuovo gettone |
| `.v` (tile) | display 26 pt, 700, spaziatura −0,5, tabellari | `Carattere.valore` |
| Cifre imbuto (45%, 23 gg) | `.v` a 24 pt | nuovo (24) |
| Totale incassi | display 20 pt, 700 | nuovo (20) |
| Righe imbuto, legenda | 13 pt; numero imbuto in grassetto | |
| `.k` didascalie | 12,5 pt, `--ink2` | esistente |
| Mesi, assi, etichette linee | 11 pt | |
| Iniziali sui punti | 10 pt, 700, bianco | |

#### 2.4 Componenti, misura per misura
- **Linea dei ricavi**: area 512×56 (tutta la larghezza interna della card 1), 12 sopra; spessori 2,6 e 2; tratteggio [4, 5]; `overflow:visible` per le etichette.
- **Anelli**: misura 170, spessore 15. La distanza tra gli anelli è spessore × 1,22 = 18,3. Raggio dell'anello i = 170/2 − 15/2 − i·18,3. Binario nello stesso colore con opacità 0,15, estremità arrotondate, partenza a ore 12 (−90°). In Prisma: `AnelliConcentrici` (`AnelliApple.swift:28`).
- **Legenda** `.leg`: riga con spazio 12 e padding 10 sopra e sotto, filo `--sep` tra le voci (non dopo l'ultima), pallino 10×10 con raggio 9.
- **Barre dell'imbuto** (`.bar8` alta 14): raggio 8, binario `--track`. La prima riga sta 16 sotto l'etichetta, le altre 10 sotto la precedente; la barra è 4 sotto la sua riga. Le cifre finali sono 16 sotto, con spazio 18 tra loro. In Prisma: `BarraPiena` (`GraficiApple.swift:28`) con altezza 14 e raggio 8.
- **Colonne degli incassi**: contenitore alto 220, 16 sotto la didascalia, spazio 12 tra le colonne (larghezza flessibile, circa 49 a 760). Colonna piena fino a 190. Spazio 2 tra le due parti. Raggi: parte alta 6 6 2 2, parte bassa 2 2 6 6. Etichetta del mese 6 sotto. Quando un canale vale zero in un mese, la colonna è una sola parte con tutti i raggi a 6 (da decidere, vedi Dubbi). In Prisma non c'è un componente adatto: **nuovo `ColonneImpilate`** (oppure `BarraPienaSegmenti` messo in verticale).
- **Dispersione**: area 250 di altezza, larga quanto la card. Il dominio usato per disegnare è 230 (20 restano per le etichette degli assi). Punti da 28 e da 12. Zona: x ≥ 55%, y tra il 62% e il fondo, raggio 12. **Nuovo componente `DispersioneClienti`**.

---

### 3. Movimento

Tutto si avvia quando la finestra si monta (`monta`, 420-423) o quando si torna sulla scheda (`rimonta`, 728). Valori del template e corrispondenze in `Tema.Apple.Moto`:

| Cosa | Durata | Curva | Ritardo / cascata | Prisma |
|------|--------|-------|-------------------|--------|
| Contenuto della finestra | 200 ms, opacità 0→1 | lineare | — | esistente |
| Cambio di scheda (uscita) | 130 ms, opacità 1→0 e scala 0,99 | — | poi si ridisegna | `cambioPagina` |
| 5 card in cascata (`.st`) | 720 ms; da translateY 18, scala 0,985, sfocatura 6, opacità 0 | (.22,1,.36,1) | 140 + i·48 ms all'apertura; 0 + i·48 al cambio di scheda | `Moto.Cascata` (0,72 / 0,048 / baseFinestra 0,14) |
| Numeri che si contano (`data-n`) | 1100 + min(i,6)·60 ms | quartica in uscita 1−(1−t)⁴ | partono insieme; i in ordine di documento: 68.420, 41.380, 27.040, 42, 31, 19, 45%, 65.800 | `Moto.Numero` (1,10 / 0,06 / 6), `NumeroCheConta` |
| Anelli | 1,4 s su `stroke-dashoffset` | `--out` | 320 + i·130 ms (finestra); 150 + i·130 (cambio di scheda) | `Moto.Anello` (1,40 / 0,13 / ritardoFinestra 0,32 / ritardoCambio 0,15) |
| Linee 2026 e 2025 | 1500 ms | (.22,1,.36,1) | 150 + i·120 ms (prima la 2026, poi la 2025) | `Moto.Linea` (1,50 / 0,15 / 0,12), `TracciatoGrafico` |
| Barre dell'imbuto | 1,2 s su `width` | `--out` | 150 + i·90 ms | `Moto.Barra` (1,20 / 0,15 / 0,09) |
| **Colonne degli incassi** | 800 ms, scaleY 0→1 dal basso | **cubic-bezier(.34,1.3,.64,1)** (molla leggera, diversa da `--spring`) | 300 + i·55 ms, da sinistra | **nuovo** `Moto.Colonne` (0,80 / 0,30 / 0,055, curva `colonne`) |
| **Punti della dispersione** | 500 ms, scala 0→1 | **cubic-bezier(.34,1.6,.64,1)** (molla più vivace) | 400 + i·25 ms; prima i 5 in evidenza, poi gli altri | **nuovo** `Moto.Punti` (0,50 / 0,40 / 0,025, curva `punti`) |
| Pillola del segmentato | 0,5 s su left e width | `--spring` | — | `Moto.Segmentato` |

Note:
- Le curve con y > 1 (1,3 e 1,6) vanno provate con `Animation.timingCurve`. Se SwiftUI taglia il superamento, si usa una molla equivalente (specifica Apple §5, tabella delle API).
- Ci sono 29 punti: con 25 ms di passo l'ultimo parte a 1,1 s. Con molti clienti (30 fittizi + 5, fino a 200 in `--prova-carico`) il ritardo va **limitato**: per esempio passo × min(i, 24), così la cascata non supera 1 s.
- **Riduci movimento** (`ridotto`). Nel template:
  - card, numeri, linee, colonne e punti compaiono a 1 ms senza ritardo;
  - anelli e barre dell'imbuto invece si animano lo stesso (`accendi` e `barre` non guardano `ridotto`).
  Nell'app vale la regola estesa della specifica Apple §2.0: con `\.prismaCalmo` tutto compare già fermo con una dissolvenza di 0,15 s, anelli pieni e barre alla misura.
- **Istantanee** (`\.modoIstantanea` / `\.prismaStatoFinale`): tutto subito nello stato finale (numeri completi, anelli pieni, linee tracciate, colonne e punti alla misura). Niente Timer.

---

### 4. Interazioni
- **Segmentato** (clic): cambia scheda con `rimonta` (uscita 130 ms, poi cascata da 0). La pillola scorre con la molla. La scheda scelta va ricordata finché l'app è aperta (nel template è una variabile globale). Nell'app serve una chiave in `StatoShell` per la scheda di Studio, così che Novità e scrivania possano aprire la scheda giusta (come `StatoShell.apri(_:)`).
- **Card**: nel template non sono cliccabili e non si inclinano. Proposta per l'app, coerente con il principio dell'analisi e da confermare:
  - Ricavi → elenco delle posizioni e delle parcelle che li compongono;
  - Imbuto → Portafoglio con il seguito delle proposte (filtro sulla fase);
  - Incassi → il mese con le sue posizioni;
  - punto della dispersione → dossier del cliente.
  Se si aggiungono, il dettaglio nasce dalla card (`espandi`, curva `dettaglioApre`).
- **Hover sui punti**: nel template c'è solo il fumetto di sistema (`title`) e il cursore resta normale. Nell'app è meglio un fumetto del tema con nome, ore e ricavi, perché sul Mac `title` non esiste in SwiftUI (`.help` va bene come minimo).
- **Hover sulle colonne**: nessuno nel template. Proposta: fumetto con «mese · Alleanza X € · Indipendente Y €».
- **Tastiera**: nessuna nel template. Nell'app:
  - ⌘1…⌘4 per le quattro schede, se non vanno in conflitto con le scorciatoie della shell (da verificare in `ComandiShell.swift`);
  - frecce sinistra e destra sul segmentato quando ha il fuoco.
- Niente trascinamenti.

---

### 5. Mappa verso Prisma

#### 5.1 Esiste già (verificato con grep in `Sources/Prisma`)
- **App e shell**: `enum AppPrisma` (`Shell/AppPrisma.swift:15-16`). **Non c'è** un caso `studio` né un file Studio. `AltreAppApple.swift` spiega come si restilizza un'app nel tema.
- **Componenti del tema Apple**:
  - `NumeroCheConta` (`DesignSystem/Apple/CifreApple.swift:77`);
  - `AnelliConcentrici` / `VoceAnello` (`AnelliApple.swift:11,28`);
  - `TracciatoGrafico` con `tratteggio` (`GraficiApple.swift:206`);
  - `BarraPiena` e `BarraPienaSegmenti` (`GraficiApple.swift:28,131`);
  - `SegmentatoPillola` (`ControlliApple.swift:19`);
  - `EntrataApple` / cascata (`CascataApple.swift:56`);
  - `EtichettaCanaleApple` (`PulsantiApple.swift:137`);
  - `Superficie.card` / `.tile` (`TemaApple.swift:370-379`);
  - `Carattere.etichetta`, `.valore`, `.numeroGrande` (`TemaApple.swift:638-684`);
  - `Tema.Apple.Moto` (`TemaAppleMoto.swift`).
- **Proposte e seguito**:
  - `Posizione.stato` (`StatoPosizione.proposta`/`.inEssere`), `Posizione.esito` (`EsitoProposta`: bozza, presentata, accettata, rifiutata, rimandata), `Posizione.creataIl`, `Posizione.canale` (`Dati/Posizione.swift:139-189`);
  - `SeguitoProposta` con `presentataIl`, `esitoIl`, `motivo` (`Dati/SeguitoProposte.swift:30`);
  - `MotoreSeguitoProposte.statistiche(_:)` → `StatisticheEsiti.giorniMediDecisione` (`Motori/MotoreSeguitoProposte.swift:378`), cioè la media dei giorni da presentazione a esito per accettate **e** rifiutate;
  - `MotoreSeguitoProposte.applica`: l'accettata passa a `stato = .inEssere` con `esito = .accettata` e `seguito.esitoIl`. Quindi le firmate si riconoscono anche dopo il passaggio in essere.
- **Portafoglio**: `Portafoglio.esiti`, `tassoAccettazione` (accettate/decise), `scadenze` per mese (`Motori/MotorePortafoglio.swift:6-80`). È la base della card Imbuto e del mese degli incassi.
- **Premi ricorrenti**: `Posizione.premio`, `frequenza` (`Frequenza.volteAllAnno`), `premioAnnuo`, `decorrenza`, `scadenza`, `versamentoIniziale`.
- **Ore**: `Appuntamento.durataMinuti`, `inizio`, `stato` (`.concluso`), `clienteId`, `tipo` (`TipoAppuntamento`, compresa `.telefonata`), `canale` (`Dati/Modelli.swift:344`). `Incontro` (`Dati/Incontro.swift:6`) **non ha una durata**: si collega all'appuntamento con `appuntamentoId`.
- **Nuovi clienti**: `Cliente.creatoIl` (`Modelli.swift`, campo `creatoIl: Date`).
- **Impostazioni**: `struct Impostazioni` (`Dati/DatiPrisma.swift:141-180`), con `giorniSeguitoProposte` e `orari`. Non c'è nulla su aliquote provvigionali, obiettivi o parcelle.
- **Prove**: `ProvaCalcoli.esegui()` chiama le prove separate (`Motori/ProvaCalcoli.swift:1199-1230`), per esempio `ProvaCalcoliSeguito`, `ProvaStatoDelLavoro`.
- **Archivio**: `DatiPrisma.versioneAttuale = 25` (`DatiPrisma.swift:64`).

#### 5.2 Cosa manca
1. **App Studio**: `AppPrisma.studio` (nel dock tra Mercato e Ruby, se Mercato entra), la vista `Shell/AppStudio.swift`, l'icona `Design/Icone/Studio` generata con `genera-icone.js` e `Tema.Apple+Studio.swift` per gettoni e misure.
2. **Provvigioni Alleanza.** In Prisma non c'è nessun dato su quanto guadagna il consulente: niente aliquote, niente provvigioni. Senza, la tile «41.380 €», l'anello «Produzione Alleanza» (che però è in premi, non in provvigioni) e la parte Alleanza degli incassi non si possono calcolare.
3. **Parcelle.** Arrivano dalla scheda «Parcelle e fatture» (specifica propria). Il Cruscotto legge solo: importo, data, stato (Bozza / Da incassare / Pagata), cliente e canale (sempre indipendente).
4. **Obiettivi dell'anno del consulente.** Non esistono (gli `Obiettivo` di oggi sono quelli dei clienti).
5. **Storico dell'anno precedente.** Per la linea 2025 e il «+18%» servono i ricavi del 2025 mese per mese. Prisma li può ricostruire solo se le posizioni e le parcelle del 2025 sono in archivio; altrimenti li deve dare l'utente.
6. **Ore per cliente.** Si sommano le `durataMinuti` degli appuntamenti conclusi dell'anno (vanno escluse le attività senza cliente). Manca il tempo fuori agenda (preparazione, pratiche).
7. **Componenti nuovi**: `ColonneImpilate` (istogramma per canale), `DispersioneClienti` (punti, zona, fumetto).

#### 5.3 Motore nuovo: `MotoreStudio` (`Motori/MotoreStudio.swift`)
È puro, senza SwiftUI, e si chiama dalla cache della shell (`CacheMotoriStudio`, come `CacheMotoriPosizioni`). Restituisce:

```swift
struct CruscottoStudio {
    struct Ricavi { let anno: Int; let totale: Double; let alleanza: Double; let indipendente: Double
                    let cumulati: [Double]          // 13 punti: 1° gennaio, fine di ogni mese fino a oggi
                    let cumulatiAnnoPrima: [Double]? // 13 punti; nil se mancano i dati
                    let variazione: Double?          // a pari data; nil se l'anno prima a pari data è 0 o manca
                    let provvigioniStimate: Bool }   // true: almeno una aliquota mancante → «stima»
    struct Obiettivo { let voce: VoceObiettivoStudio; let fatto: Double; let traguardo: Double?; var frazione: Double? }
    struct Imbuto { let preparate: Int; let presentate: Int; let firmate: Int
                    let inPorto: Double?             // firmate / preparate
                    let giorniAllaFirma: Double?     // media presentataIl→esitoIl delle sole accettate
                    let fase: FaseImbuto?; let ferme: Int }
    struct MeseIncasso { let inizio: Date; let alleanza: Double; let indipendente: Double }
    struct PuntoCliente { let cliente: Cliente; let ore: Double; let ricavi: Double; let inZona: Bool }
    let ricavi: Ricavi; let obiettivi: [Obiettivo]; let imbuto: Imbuto
    let incassi: [MeseIncasso]; let valoreTempo: [PuntoCliente]
}
enum MotoreStudio {
    static func calcola(posizioni:, clienti:, appuntamenti:, parcelle:, impostazioni: ImpostazioniStudio, oggi: Date, cal: Calendar) -> CruscottoStudio
}
```

Regole di calcolo da confermare con l'utente (vedi Dubbi):
- **Ricavi dell'anno** = provvigioni Alleanza maturate nell'anno + parcelle dell'anno.
  - Provvigioni: per ogni posizione Alleanza in essere, le provvigioni d'acquisto (alla decorrenza) e quelle ricorrenti (a ogni premio che scade nell'anno), con le aliquote di §5.4.
  - Parcelle: per data di emissione o di incasso, secondo la scelta dell'utente (competenza o cassa).
- **Cumulati**: somma progressiva mese per mese. L'anno prima si calcola con la stessa regola sulle date di un anno prima.
- **Obiettivi**:
  - produzione Alleanza = premi annui (o premi + versamenti unici) delle posizioni Alleanza con decorrenza nell'anno;
  - nuovi clienti = clienti con `creatoIl` nell'anno, oppure con la prima posizione in essere nell'anno (da scegliere);
  - ricavi consulenza = parcelle dell'anno.
- **Imbuto** (posizioni con `creataIl` nell'anno che sono o sono state proposte):
  - preparate = tutte;
  - presentate = quelle con `seguito.presentataIl` oppure con un esito diverso da bozza;
  - firmate = `esito == .accettata`.
  - «alla firma, in media» = media dei giorni da `presentataIl` a `esitoIl` delle **sole accettate** (variante di `MotoreSeguitoProposte.statistiche`, che oggi include anche le rifiutate).
  - Fase = il passaggio con la perdita più grande.
- **Incassi dei prossimi 12 mesi**, dal 1° del mese prossimo, per mese:
  - Alleanza: provvigioni ricorrenti sulle rate dei premi delle posizioni Alleanza in essere (`premio`, `frequenza`, `decorrenza` per le date delle rate, `scadenza` come fine), più i rinnovi annuali delle coperture;
  - Indipendente: parcelle firmate non ancora incassate, per la data di pagamento prevista, più le parcelle ricorrenti (per esempio la consulenza annuale), se l'utente le segna come tali.
- **Valore e tempo**, per ogni cliente con almeno un appuntamento concluso nell'anno:
  - ore = somma di `durataMinuti`/60 degli appuntamenti conclusi;
  - ricavi = provvigioni + parcelle attribuite al cliente;
  - in zona = ore sopra la soglia e ricavi sotto la soglia (§5.4).
  - In evidenza: i clienti preferiti (`Cliente.preferito`) o quelli più lontani dalla media, al massimo 5–6 con le iniziali; gli altri pallini anonimi nel grafico, ma col nome nel fumetto (sul Mac è solo per il consulente).
  - Assi: il massimo è il valore più alto arrotondato in su (non fisso a 30 ore e 4.600 €).

#### 5.4 Campi nuovi dell'archivio (versione 26)
Tutti facoltativi e letti in modo tollerante (come `SeguitoProposta.init(from:)`). Entrano nel backup e in `Prisma --prova-backup`.
- `Impostazioni.studio: ImpostazioniStudio`
  - `aliquoteAlleanza: [AliquotaProvvigione]`, con `AliquotaProvvigione { id; area: AreaPosizione?; tipologia: String?; prodottoId: String?; acquisto: Double? /* % sul premio del primo anno o sul versamento unico */; ricorrente: Double? /* % sui premi successivi */ }`. Precedenza: prodotto, poi tipologia, poi area.
  - `obiettivi: [Int: ObiettiviAnno]` (chiave = anno), con `ObiettiviAnno { produzioneAlleanza: Double?; nuoviClienti: Int?; ricaviConsulenza: Double? }`.
  - `ricaviManuali: [RicavoMensile]` per gli anni non ricostruibili, con `RicavoMensile { anno; mese; canale: Canale; importo }`.
  - `criterioRicavi: CriterioRicavi` (`.competenza` / `.cassa`).
  - `sogliaOre: Double?`, `sogliaRicavi: Double?` per la zona «molto tempo, poco valore» (senza soglie: mediana delle ore e mediana dei ricavi).
  - `contaTelefonate: Bool` (se le telefonate entrano nelle ore).
- `Posizione.provvigione: ProvvigionePosizione?` per correggere il caso singolo, con `ProvvigionePosizione { acquisto: Double?; ricorrente: Double?; importoAcquisto: Double? }`. Vince sull'aliquota generale.
- Le parcelle (`Parcella`) sono dello schema della specifica «Parcelle e fatture»: qui servono `importo`, `data`, `stato`, `clienteId`, `pagataIl`, `scadenzaPagamento`, `ricorrente`.

#### 5.5 Prove di calcolo nuove: `ProvaCalcoliStudio` (`Motori/ProvaCalcoliStudio.swift`)
Si chiama da `ProvaCalcoli.esegui()`. Casi costruiti a mano:
1. Una posizione Alleanza mensile da 100 € con aliquota ricorrente del 3% e decorrenza a marzo: provvigioni dell'anno e rate nei 12 mesi giusti (esclusi i mesi dopo la `scadenza`).
2. Un premio unico con aliquota d'acquisto: provvigione solo nel mese di decorrenza.
3. Posizione senza aliquota: non entra nel totale e `provvigioniStimate`/«aliquota mancante» è segnalato.
4. `Posizione.provvigione` vince sull'aliquota d'area.
5. Imbuto: 4 proposte (bozza, presentata, rifiutata, accettata→in essere): preparate 4, presentate 3, firmate 1, in porto 25%, fase «dopo la presentazione: 2».
6. Giorni alla firma: solo le accettate con entrambe le date.
7. Variazione a pari data: 68.420 contro 58.000 → +18%. Con l'anno prima a 0: nil, non «+∞%».
8. Ore: appuntamenti conclusi dell'anno sommati per cliente. Esclusi i pianificati, quelli dell'anno prima e (se `contaTelefonate == false`) le telefonate.
9. Zona: un cliente sopra la soglia delle ore e sotto quella dei ricavi risulta `inZona`.
10. Incassi: 12 mesi dal 1° del mese dopo `oggi`, anche a cavallo d'anno (oggi 3 novembre → da dicembre a novembre).
11. Prestazioni: 200 clienti di `--prova-carico` in O(P + A), come `inSospeso`.

---

### 6. Dati che l'utente deve dare (mai inventarli)
1. **Aliquote provvigionali Alleanza**: d'acquisto e ricorrenti, per prodotto o almeno per area/tipologia, con la base di calcolo (premio annuo, premio di rata, versamento unico) e il momento in cui maturano.
2. **Come si pagano i rinnovi**: quali prodotti danno provvigioni ricorrenti e per quanti anni.
3. **Obiettivi dell'anno**: traguardo della produzione Alleanza (e cosa vuol dire «produzione»: premi annui, premi + versamenti unici, o la misura di Alleanza), numero di nuovi clienti, ricavi della consulenza.
4. **Ricavi dell'anno prima** mese per mese, divisi per canale, se le posizioni e le parcelle del 2025 non sono tutte in archivio.
5. **Criterio dei ricavi**: per competenza (firma/emissione) o per cassa (incasso).
6. **Soglie della zona «molto tempo, poco valore»** (oppure il via libera alla mediana automatica).
7. **Ore fuori agenda**: se contare anche preparazione, telefonate, pratiche, e come (un forfait per appuntamento? un campo a mano?).
8. **Parcelle**: dalla scheda «Parcelle e fatture» (regime fiscale, importi, date di pagamento).

Finché mancano, l'interfaccia mostra:
- **Senza aliquote**: la tile Alleanza mostra «—» e la frase «Imposta le aliquote in Impostazioni › Studio» (collegamento). La parte Alleanza degli incassi resta vuota, con la stessa frase nella didascalia. Il numero grande conta solo le parcelle e porta la nota «solo consulenza».
- **Con alcune aliquote mancanti**: le cifre ci sono, con la didascalia «stima · N posizioni senza aliquota».
- **Senza obiettivi**: niente anelli vuoti. La card mostra «Imposta gli obiettivi dell'anno» con il pulsante. Gli obiettivi impostati a metà mostrano solo gli anelli che hanno un traguardo.
- **Senza anno precedente**: niente linea tratteggiata né percentuale. Al posto di «+18% sul 2025» c'è «primo anno in Prisma» in `--ink2`.
- **Senza durate o appuntamenti**: card 5 vuota (§1.8).
- **Dati di prova**: con i 5 clienti del template e i 30 fittizi, `DatiDemo`/`ClientiFittizi` caricano anche delle aliquote di prova, degli obiettivi di prova e parcelle di prova. In tutte e cinque le card compare l'etichetta «dati di prova» (`.k` accanto al titolo), come per gli altri moduli dimostrativi. **Le aliquote di prova non devono mai finire nell'archivio reale**: si caricano solo con i dati fittizi da Impostazioni.

---

### 7. Istantanee da aggiungere
Numerazione: la serie 4xx è del tema Apple (400 vetrina, 410-415, 430-436 occupati). Proposta: una serie nuova **500** per Orizzonte/Studio, chiaro e scuro (suffisso `-scuro`, come la vetrina).
- `500-studio-cruscotto` / `500-studio-cruscotto-scuro`: dati di prova completi (le cinque card).
- `501-studio-cruscotto-vuoto` / `-scuro`: archivio senza clienti.
- `502-studio-cruscotto-senza-aliquote` / `-scuro`: parcelle sì, aliquote no (tile Alleanza «—», incassi solo indipendente).
- `503-studio-cruscotto-primo-anno` / `-scuro`: senza l'anno precedente (niente linea tratteggiata né percentuale).
- `504-studio-cruscotto-senza-obiettivi` / `-scuro`.
- `505-studio-cruscotto-fumetto-punto`: il fumetto di un punto della dispersione, se si fa del tema (solo chiaro).
- `506-impostazioni-studio` / `-scuro`: la pagina di Impostazioni con aliquote, obiettivi, criterio e soglie.
- `507-scrivania-widget-studio` / `-scuro`: il widget «Il tuo studio · novembre» (in condivisione con la parte Scrivania).

Tutte nello stato finale (`\.prismaStatoFinale`) e a 1440×900 come le altre del tema Apple.

---

## 3. Studio › Parcelle e fatture

*Parte 02 · titolo della bozza: «02 · Studio › Parcelle e fatture»*

Fonte: `Design/template-novita.html`. Le righe citate sono di quel file:
- dati `FATT` e `selF` (751-752);
- scheda nel segmentato di `APPS.studio` (766);
- `studioHTML()` ramo `fatture` (786-792);
- `fatturaHTML(f)` (813-820);
- `montaStudio()` ramo `fatture` (828-831);
- utilità comuni (255-288), CSS (17-218: `.side` 110, `.main` 111, `.rub` 112-115, `.tile` 117, `.bar8` 118-119, `.paper` 177-185, `.btn` 37-40, `#toast` 105-106).

Schermate (scattate per questa parte con Playwright su `orizzonte/t.html`, 1480×940, scala dello stadio 1,0137):
- `scratchpad/fatt/chiaro-fatture.png` e `scratchpad/fatt/scuro-fatture.png`: la scheda appena aperta (scelta la 2026/015);
- `scratchpad/fatt/chiaro-xml-carica.png`: la barra «Preparo il file…»;
- `scratchpad/fatt/chiaro-xml-pronto.png`: «✓ File XML pronto» (scelta la 2026/014);
- `scratchpad/fatt/chiaro-nuova.png`: il toast di «＋ Nuova parcella»;
- `scratchpad/fatt/chiaro-msg.png`: dopo «Manda con Messaggi».

Nella serie `orizzonte/*-10..20-*.png` questa scheda **non c'è** (il giro apre Studio su Cruscotto).

Per tutto ciò che qui non è detto (finestra, barra, segmentato, barra laterale, voci di rubrica, tile, numeri che si contano, cascata, toast, carta) vale `Design/template-apple-specifica.md`. L'app Studio, la finestra e il segmentato sono già descritti in `01-studio-cruscotto.md` §1.1.

**Le cifre del template sono dimostrative.** Nell'app importi, totali, voci fiscali e numeri delle fatture vengono dall'archivio e dai motori (§5). **Questa specifica non sceglie il regime fiscale, l'IVA, i contributi, la ritenuta o il bollo.** Elenca solo i dati da chiedere all'utente (§6).

---

### 1. Cosa si vede

#### 1.1 Dove sta
- Seconda scheda del segmentato di Studio: **«Parcelle e fatture»** (valore `fatture`).
- Dal template ci si arriva solo dal segmentato. Il pannello Novità non ha una voce per le parcelle. La tile «parcelle della consulenza» del Cruscotto non porta qui (proposta: farla portare qui, vedi Dubbi).
- Area dei contenuti `#wc`: 1384×654. Il contenuto si divide in due colonne:
  - **a sinistra la barra laterale** `.side` (larga 440, padding 16) con i totali, l'elenco e il pulsante;
  - **a destra l'anteprima** `.main` (da 456 al bordo destro, cioè 928 di larghezza): la fattura su carta al centro e la colonna delle azioni a destra.

#### 1.2 Barra laterale
Dall'alto:
1. **Due tile affiancate** (`.tile`, `flex:1`, spazio 10, 12 sopra l'elenco):
   - **«Incassato nel 2026»** (`.k`) e sotto il valore `.v` **«21.300 €»** (si conta da 0). L'anno è quello in corso.
   - **«Da incassare»** e sotto il valore **«1.650 €»** in arancio (`--orange`, si conta).
   - Nel template «Da incassare» è la somma delle due fatture «Da incassare» dell'elenco (900 + 750). «Incassato nel 2026» invece non torna con l'elenco (le pagate sommano 2.700 €): è dimostrativo, perché l'elenco mostra solo le ultime cinque.
2. **Elenco delle parcelle**: una voce `.rub` per documento, la più recente in alto (numero decrescente). Ogni voce ha padding 10:
   - avatar del cliente da 34 (gradiente del cliente, iniziali bianche, bordo 3 `--cardE`, ombra `0 4px 10px rgba(0,0,0,.25)`);
   - al centro: il nome del cliente in grassetto 14 (**«Andrea Conti»**) e sotto, in `small` 12 `--ink2`, **«{numero} · {descrizione}»** (per esempio «2026/016 · Primo check-up patrimoniale»), su una riga con i puntini (larghezza massima 220);
   - a destra, allineati a destra: l'importo in grassetto 13,5 (**«450 €»**) e sotto lo stato in `small` peso 600, colorato:
     - **«Bozza»** in `--ink3`;
     - **«Da incassare»** in `--orange`;
     - **«Pagata»** in `--green`.
   - La voce scelta ha il fondo `rgba(0,122,255,.13)` (`.rub.on`). All'apertura è scelta la seconda (`selF=1`, la 2026/015).
3. **«＋ Nuova parcella»**: pulsante principale grande (`.btn.pri.big`), largo quanto la barra (16 dai lati e dal fondo), testo centrato.

I cinque documenti del template:

| Numero | Cliente | Descrizione | Importo | Stato | Data |
|---|---|---|---|---|---|
| 2026/016 | Andrea Conti | Primo check-up patrimoniale | 450 € | Bozza | 3 nov 2026 |
| 2026/015 | Laura Moretti | Piano previdenziale | 900 € | Da incassare | 28 ott 2026 |
| 2026/014 | Giulia Rossi | Consulenza patrimoniale annuale | 1.200 € | Pagata | 14 ott 2026 |
| 2026/013 | Marco Bianchi | Revisione annuale del piano di famiglia | 1.500 € | Pagata | 2 ott 2026 |
| 2026/012 | Sofia Romano | Pianificazione della rendita | 750 € | Da incassare | 19 set 2026 |

#### 1.3 Anteprima
- Fondo `--chip` (rgba(0,0,0,.05) chiaro, rgba(255,255,255,.08) scuro), raggio 20, senza bordo né ombra. È il «tavolo» dove sta il foglio.
- **Il foglio** (`.paper`, `#fPag`): A4 verticale 600×848, mostrato a scala **0,66** (cioè 396×560) e centrato in orizzontale, 20 dall'alto. Il margine sotto è −290, per non far scorrere l'area. Il foglio è bianco anche in scuro (si vede nella schermata scura). Ombra `0 20px 50px -10px rgba(0,0,0,.25)`.
- **Colonna delle azioni**: in alto a destra (18 dal bordo destro e dall'alto), larga 220, in colonna con spazio 8. Tutti i pulsanti sono grandi e centrati:
  1. **«Prepara il file XML»**: principale (blu);
  2. **«Salva PDF»**: secondario;
  3. **«Manda con Messaggi»**: secondario;
  4. sotto, 6 più in basso, il testo `.k` (interlinea 1,45): **«Il file XML della fattura elettronica lo carichi tu sul portale dell'Agenzia delle Entrate, o lo dai al commercialista.»**
  5. sotto ancora, il riquadro dello stato del file XML (`#xmlS`): è vuoto finché non si preme «Prepara il file XML» (§1.5).

#### 1.4 La fattura su carta (`fatturaHTML`)
Il foglio ha padding 40 (sopra e sotto) e 46 (ai lati). Carattere Inter / SF. Dall'alto:
1. **Testata**: il logo di Prisma da 22 (tre spicchi `#0F2433`, opacità 1 / .66 / .38) e la scritta **«DENIS VICENZONI · CONSULENZA FINANZIARIA»** (11, spaziatura 1, `#5A6873`, peso 600). È la testata del canale indipendente, ma senza il colore cuoio (vedi Dubbi).
2. 34 più sotto, **due colonne** allineate in alto:
   - a sinistra: il sopratitolo `.pl` **«FATTURA»** (11, spaziatura 1,4, `#2563EB`, peso 700); il numero `h3` **«N. 2026/015»** (display, 32 al posto di 36, peso 700, spaziatura −1); la data `.ps` **«del 28 ott 2026»** (13, `#4A5964`);
   - a destra, allineati a destra (12, interlinea 1,6, `#33424D`): il nome del cliente in grassetto (**«Laura Moretti»**), **«Codice fiscale ••••••••••••••••»** e **«Indirizzo del cliente»**. Sono segnaposto: nell'app ci vanno i dati veri del cliente (§6).
3. 34 più sotto, **la testata della tabella**: filetto sopra 2 `#14202B`, padding 10 sopra, 11 peso 700, spaziatura .4, `#5A6873`: **«DESCRIZIONE»** a sinistra e **«IMPORTO»** a destra.
4. **La riga della prestazione** (padding 14 sopra e sotto, filetto sotto 1 `#E3E8EC`, 13,5): a sinistra la descrizione (**«Piano previdenziale»**) e sotto, in 11,5 `#5A6873`, **«Consulenza finanziaria indipendente»**; a destra l'importo in grassetto (**«900 €»**).
5. **«Voci fiscali»** (padding 12, 13, `#5A6873`): a sinistra «Voci fiscali», a destra **«secondo il regime impostato»**. È un segnaposto: nell'app ci vanno le righe vere (imponibile, contributo, IVA o natura, ritenuta, bollo), secondo i dati dell'utente.
6. **«Totale»**: filetto sopra 2 `#14202B`, padding 14, 17 peso 700. A sinistra «Totale», a destra l'importo (**«900 €»**). Nel template il totale è uguale all'importo, perché le voci fiscali non ci sono.
7. 30 più sotto, la sezione `.sec` **«PAGAMENTO»** (11,5 peso 700, spaziatura .4) e il testo `.tx` (12,5, interlinea 1,55, `#33424D`): **«Bonifico bancario · IBAN ••••••••••••••••••••••••••• · entro 30 giorni»**.
8. **Piede** `.foot` (in fondo, 26 dal bordo, 46 ai lati, 9, `#7A8790`, interlinea 1,4, filetto sopra 1 `#E3E8EC`, padding 8): **«P. IVA ••••••••••• · Le voci fiscali (IVA, contributi, bollo) seguono il regime impostato in Studio. Documento di prova.»**

#### 1.5 Stati
**Del file XML**, nel riquadro `#xmlS`:
- **Vuoto**: all'apertura della scheda. Quando si cambia fattura, nel template il riquadro resta com'è (vedi Dubbi 11).
- **In preparazione**: tile 10 sopra, con **«Preparo il file…»** (`.k`) e sotto una barra `.bar8` (alta 8, raggio 9, binario `--track`) che si riempie di `--accent`.
- **Pronto**: tile con il bordo `rgba(47,163,90,.4)`; **«✓ File XML pronto»** in grassetto `--green`; sotto, 4 più in basso, `.k` che va a capo dove capita: **«IT_2026-014.xml · formato fattura elettronica»**. Il nome del file del template non segue la regola dello SdI (vedi §5.3 e Dubbi).

**Della parcella**: Bozza, Da incassare, Pagata (§1.2).

**Della scheda**: il template non ha né vuoto, né caricamento, né errore. Per l'app:
- **Nessuna parcella**: le due tile restano, a 0 €. Al posto dell'elenco c'è il testo `.k` «Ancora nessuna parcella. Le parcelle sono della consulenza indipendente: preparane una con «Nuova parcella».» L'anteprima mostra il tavolo vuoto con il testo al centro «Qui vedrai la fattura su carta». I pulsanti delle azioni sono spenti.
- **Dati fiscali del consulente mancanti** (§6): «Prepara il file XML» è spento. Al suo posto, nel riquadro `#xmlS`, c'è una tile arancio (bordo `rgba(224,138,0,.4)`): «Per il file XML mancano: partita IVA, regime fiscale, …» e il collegamento «Completa in Impostazioni › Studio». «Salva PDF» resta acceso: il PDF porta i campi mancanti come «da completare» e la scritta «Documento di prova» nel piede.
- **Dati del cliente mancanti** (codice fiscale, indirizzo completo): la stessa tile, con «Per il file XML di {cliente} mancano: codice fiscale, CAP, comune» e il collegamento «Completa il dossier».
- **Errore nel salvataggio del file**: toast «Non sono riuscito a salvare il file: {motivo}». Nessun file a metà.
- **Caricamento**: nessuno. Il calcolo e la scrittura del file sono immediati (vedi §3.3).

---

### 2. Misure e stile

#### 2.1 Gettoni (CSS 17-23) e corrispondenze in Prisma
| CSS | Chiaro | Scuro | Prisma |
|---|---|---|---|
| `--panel` (barra laterale) | rgba(255,255,255,.72) | rgba(255,255,255,.05) | `Tema.Apple.Superficie.pannello` |
| `--card` (tile) | rgba(255,255,255,.82) | rgba(255,255,255,.07) | `Superficie.tile` |
| `--sep` (bordi) | rgba(0,0,0,.08) | rgba(255,255,255,.09) | `Colore.separatore` |
| `--chip` (tavolo dell'anteprima, voce sotto il puntatore) | rgba(0,0,0,.05) | rgba(255,255,255,.08) | `Colore.chip` |
| `--track` (binario della barra) | rgba(0,0,0,.07) | rgba(255,255,255,.1) | binario di `BarraPiena` |
| `--ink` / `--ink2` / `--ink3` | .87 / .55 / .34 nero | .94 / .62 / .38 bianco | `Colore.inchiostro`, `inchiostro2`, `inchiostro3` |
| `--accent` | #007AFF | #007AFF | `Colore.accento` |
| `--orange` | #E08A00 | uguale | `Colore.arancio` |
| `--green` | #2FA35A | uguale | `Colore.verde` |
| `.rub.on` | rgba(0,122,255,.13) | uguale | `Colore.selezioneVoce` |
| `--cardE` (pulsante secondario) | #fff | rgb(40,54,66) | fondo di `StilePulsanteApple(.secondaria)` |

Carta (sempre chiara, colori fissi): sono già tutti in `Tema.Apple.Carta` (`TemaApple.swift:184-201`):
- `#FFFFFF` → `fondo`;
- `#14202B` (testo, filetti forti) → `testo`;
- `#4A5964` (`.ps`) → `sottotitolo`;
- `#33424D` (`.tx`, dati del cliente) → `testoCorrente`;
- `#5A6873` (testata, etichette, «Voci fiscali») → `etichetta`;
- `#7A8790` (piede) → `piede`;
- `#E3E8EC` (filetti sottili) → `filetto`;
- `#2563EB` (`.pl` «FATTURA») → `sopratitolo`;
- `#0F2433` (logo) → `Tema.Colore.logoStampa`.

#### 2.2 Superfici
- Barra laterale: `Superficie.pannello`, raggio 20 (`Raggio.pannello`), bordo `--sep`.
- Tile: `Superficie.tile`, raggio 18 (`Raggio.tile`), padding 14×16, bordo `--sep`.
- Voce dell'elenco: raggio 14 (`Raggio.voce`), 2 fra le voci, senza fondo; `chip` sotto il puntatore; `selezioneVoce` se scelta.
- Tavolo dell'anteprima: `Colore.chip`, raggio 20, nessun vetro.
- Foglio: bianco opaco, nessun raggio, ombra `0 20px 50px -10px rgba(0,0,0,.25)` (la stessa del foglio dei Prospetti). **Niente vetro sul foglio.**

#### 2.3 Misure
| Elemento | Valore |
|---|---|
| Barra laterale | larga 440, padding 16 (quella dei Prospetti è 290: qui serve una misura nuova, `Tema.Apple.Studio.Parcelle.larghezzaLaterale = 440`) |
| Spazio fra barra e anteprima | 16 |
| Tile dei totali | 2 in riga, spazio 10, 12 sopra l'elenco; misurate 201×77 nello stadio |
| Voce dell'elenco | padding 10 (misurata 412×55), avatar 34, spazio 10 fra avatar e testo |
| Pulsante «Nuova parcella» | 16 dai lati e dal fondo, alto 41 (grande: padding 10×18, 13,5) |
| Foglio | 600×848 a scala 0,66, 20 dall'alto. In Prisma: `Misure.Documento.prospetto` (595×842), adattato allo spazio come nei Prospetti |
| Colonna delle azioni | larga 220, 18 dal bordo destro e dall'alto, spazio 8, pulsanti alti 39 |
| Testo sotto le azioni | 6 sopra, interlinea 1,45 |
| Tile dello stato XML | 10 sopra; barra alta 8, 8 sotto il testo |

Il foglio e la colonna delle azioni si toccano quasi: con 928 di anteprima, il foglio (396) è centrato tra 266 e 662 e la colonna parte da 690. A finestra più stretta, il foglio deve **spostarsi a sinistra** per lasciare posto alla colonna, non andarci sotto. Regola proposta: il foglio è centrato nello spazio che resta a sinistra della colonna.

#### 2.4 Caratteri
| Testo | Dimensione / peso | Prisma |
|---|---|---|
| «Incassato nel 2026», «Da incassare» | 12,5 regolare `--ink2` (`.k`) | `Carattere.secondario` |
| Valori delle tile | display 26 bold, spaziatura −0,5, cifre tabellari (`.v`) | `Carattere.valore` |
| Nome del cliente | 14 bold | come `Tema.Apple.Prospetti.Laterale.titoloVoce` |
| «numero · descrizione» | 12 regolare `--ink2`, una riga | `sottotitoloVoce` |
| Importo | 13,5 bold | nuovo `Carattere(dimensione: 13.5, peso: .bold)` |
| Stato | 12 semibold, colore dello stato | nuovo |
| Pulsanti grandi | 13,5 semibold | `StilePulsanteApple(…, grande: true)` |
| Nota sotto le azioni | 12,5 `--ink2`, interlinea 1,45 | `Carattere.secondario` |
| «✓ File XML pronto» | 14 bold `--green` (`b` dentro la tile) | nuovo |

Sulla carta (misure del foglio a grandezza piena):
| Testo | Valore |
|---|---|
| Testata | 11 semibold, spaziatura 1, maiuscolo, `etichetta` |
| «FATTURA» | 11 bold, spaziatura 1,4, `sopratitolo` |
| Numero | display 32 bold, spaziatura −1, interlinea 1,05, `testo` |
| Data | 13 regolare, `sottotitolo`, 8 sopra |
| Dati del cliente | 12, interlinea 1,6, `testoCorrente`; nome in grassetto |
| Testata della tabella | 11 bold, spaziatura .4, `etichetta` |
| Descrizione | 13,5; sottotitolo 11,5 `etichetta` |
| Voci fiscali | 13 `etichetta` |
| Totale | 17 bold |
| «PAGAMENTO» | 11,5 bold, spaziatura .4, 30 sopra |
| Testo del pagamento | 12,5, interlinea 1,55, `testoCorrente`, 6 sopra |
| Piede | 9, interlinea 1,4, `piede` |

Spazi verticali sulla carta: 34 dalla testata al numero; 34 dal blocco del numero alla tabella; filetti forti 2 e sottili 1.

---

### 3. Movimento

Valori del template e corrispondenze in `Tema.Apple.Moto`. Nessun Timer: animazioni di SwiftUI.

#### 3.1 Entrata nella scheda (`rimonta`, 728)
- Il contenuto vecchio esce in **0,13 s**: opacità 1 → 0, scala 1 → 0,99.
- Poi entrano a cascata gli elementi `.st` (`entrata`, 267): le **cinque voci dell'elenco** e **il foglio**. Ognuno impiega **0,72 s** con la curva `cubic-bezier(.22,1,.36,1)`, parte da y +18, scala 0,985 e sfocatura 6, con un ritardo di **i·0,048 s**. È la cascata standard: `EntrataApple` / `CascataApple`.
- Le tile dei totali **non** entrano a cascata (non hanno `.st`). I loro numeri **si contano** da 0 (`conteggi`, 266): **1,1 s + min(i,6)·0,06 s**, curva `1−(1−t)^4`. È `NumeroCheConta`.
- Il pulsante «Nuova parcella» e la colonna delle azioni compaiono subito.

#### 3.2 Cambio della fattura scelta (828)
- La voce scelta cambia fondo in **0,25 s** (`.rub` `transition:background .25s`).
- Il foglio **esce** in **0,16 s** (curva lineare, quella predefinita delle Web Animations): opacità 1 → 0, scala 0,66 → 0,64, y +20 (sono 20 del foglio, cioè circa 13 a schermo).
- Poi il contenuto cambia ed **entra** in **0,48 s** con `cubic-bezier(.22,1,.36,1)`: da opacità 0, scala 0,64 e y −20, fino alla posizione di riposo.
- La direzione è sempre la stessa (esce verso il basso, entra dall'alto), qualunque voce si scelga.
- In Prisma: `AnyTransition.cambioPagina(direzione:calmo:)` (`DesignSystem/Apple/PaginaApple.swift`) fa già la stessa cosa, ma con i valori dei Prospetti (0,18 / 0,52 s, 30 / 40 di spostamento, la nuova dal basso). Proposta: aggiungere `Tema.Apple.Moto.Fattura` con i valori del template (uscita 0,16 lineare, entrata 0,48 `Curva.uscita`, spostamento 20 del foglio, scala relativa 0,64/0,66 ≈ 0,97) e una transizione `.cambioFattura(calmo:)` che riusa `EffettoPaginaApple`. In alternativa si riusa `cambioPagina(direzione: -1)`, che dà la stessa direzione (vedi Dubbi).

#### 3.3 «Prepara il file XML» (829-830)
- Compare subito la tile «Preparo il file…» con la barra vuota.
- Due fotogrammi dopo, la barra va a **100%** in **1,2 s** con `cubic-bezier(.4,0,.2,1)`.
- A **1,3 s** la tile è sostituita da «✓ File XML pronto», che entra in **0,45 s** con la molla `cubic-bezier(.34,1.45,.64,1)` (`--spring`): scala 0,9 → 1, opacità 0 → 1.
- Nell'app il file si scrive in pochi millisecondi. La barra serve solo a far capire che è successo qualcosa. Proposta: tenere la barra **solo se** il file richiede più di 0,15 s (in pratica mai), altrimenti mostrare subito «✓ File XML pronto» con la molla. Il passo «salva dove vuoi» (pannello di salvataggio) viene dopo, vedi §4.

#### 3.4 Pulsanti e toast
- Pulsanti: alla pressione scala 0,95 con la molla in 0,25 s; sotto il puntatore luminosità 0,97 (`StilePulsanteApple`).
- Toast (`#toast` 105-106): entra da y −20 con opacità 0 in **0,45 s** `--spring`, resta **2,4 s**, esce allo stesso modo. Fondo `rgba(15,36,51,.92)`, testo bianco 13, padding 9×16, capsula, 44 dall'alto (`Tema.Apple.Colore.toast`, `StatoShell.mostraAvviso`).

#### 3.5 Riduci movimento e istantanee
- Nel template `ridotto` vale solo per la cascata e per i numeri (durata 1 ms). Il cambio del foglio e la barra XML si animano comunque.
- In Prisma, con `\.prismaCalmo`: niente cascata; i numeri compaiono già pieni; il foglio cambia con una dissolvenza di 0,15 s (`Tema.Moto.dissolvenzaCalma`); lo stato XML compare già pronto, senza barra né molla.
- Nelle istantanee (`\.modoIstantanea`, `\.prismaStatoFinale`): numeri completi, foglio fermo, nessuna barra.

---

### 4. Interazioni

| Dove | Azione | Template | Prisma |
|---|---|---|---|
| Voce dell'elenco | clic | sceglie la fattura e cambia il foglio (§3.2) | uguale. Anche ↑/↓ quando l'elenco ha il fuoco, come in Rubrica |
| Voce dell'elenco | puntatore sopra | fondo `--chip` in 0,25 s | uguale |
| Voce dell'elenco | clic destro | — | menu: «Segna come pagata…» (chiede la data dell'incasso), «Segna da incassare», «Duplica», «Apri il dossier del cliente», «Elimina bozza». Le parcelle emesse non si eliminano: si fa una nota di credito (vedi Dubbi) |
| «＋ Nuova parcella» | clic | toast «Nuova parcella: scegli il cliente e la consulenza» | apre il modulo della nuova parcella (§4.1). Scorciatoia ⌘N quando la scheda è aperta |
| «Prepara il file XML» | clic | barra e «✓ File XML pronto» | controlla i dati (§1.5); se ci sono, scrive l'XML (§5.3), apre il pannello di salvataggio (`NSSavePanel`, tipo `.xml`, nome proposto secondo la regola SdI) e lo registra nei Documenti del cliente. La tile pronta mostra il nome del file e il collegamento «Mostra nel Finder» |
| «Salva PDF» | clic | toast «PDF della fattura salvato, su carta bianca» | `StampaCarta.pdf` + `StampaCarta.salva` (pannello di salvataggio, «Il PDF resta dove lo salvi: Prisma non lo invia a nessuno.»), poi toast. ⌘S |
| «Manda con Messaggi» | clic | apre l'app Messaggi di Prisma sul primo messaggio (`selM=0`, il riepilogo di Giulia: **difetto del template**, non c'entra con la fattura) | apre Messaggi di Prisma con un **messaggio nuovo per il cliente della fattura**, già scritto («La fattura N. … di … €»), con il PDF allegato. Si spedisce da lì con «Apri in Messaggi» / «Apri in Mail» (`NSSharingService` `.composeMessage` / `.composeEmail`, con destinatario e allegato). Niente parte da solo |
| Foglio | doppio clic | — | apre la fattura a tutta finestra nell'anteprima dei Prospetti (stessa pagina, stesso PDF) |
| Foglio | trascinamento | — | trascina il PDF nel Finder o in Mail, come in Documenti (`AppDocumenti.swift:257`) |

#### 4.1 Modulo «Nuova parcella» (non c'è nel template, solo il toast)
Proposta, nello stile dei moduli del tema Apple (`ModuloPosizione`, `ModuloEsitoProposta`):
1. **Cliente** (tendina dei clienti, il cliente aperto già scelto). Le parcelle sono sempre del canale **indipendente**.
2. **Consulenza** (una o più righe): descrizione (proposte dalle consulenze fatte: incontri e prospetti del cliente), sottotitolo (di base «Consulenza finanziaria indipendente»), importo. Periodo facoltativo (dal / al), per le consulenze annuali.
3. **Data** del documento (di base oggi) e **scadenza del pagamento** (di base secondo la regola impostata dall'utente, §6).
4. **Ricorrente**: sì / no (per la consulenza annuale).
5. Riquadro in fondo con le **voci fiscali calcolate** dal motore secondo il regime impostato (imponibile, contributo, IVA o natura, ritenuta, bollo, totale, netto a pagare). Se il regime non è impostato: «Le voci fiscali compaiono quando imposti il regime in Impostazioni › Studio.»
6. Pulsanti: «Salva come bozza» (senza numero) e «Emetti» (assegna il numero progressivo, congela le voci fiscali, stato «Da incassare»).

---

### 5. Mappa verso Prisma

#### 5.1 Esiste già (verificato con grep in `Sources/Prisma`)
- **Carta e PDF**:
  - `struct DocumentoStampabile` (`Shell/StampaCarta.swift:12`): titolo, cliente, genere, formato, pagine (`[AnyView]`), `tipo: Documento.Tipo`. Ha già un `init` per ogni prospetto o report: serve un `init(_ t: TestiFattura)` con genere «Fattura».
  - `enum StampaCarta` (`StampaCarta.swift:164`): `pdf(_:)` disegna ogni pagina sempre in chiaro (`colorScheme .light`, `NSAppearance .aqua`), `nomeFile(_:)`, `salva(_:nome:)` (`NSSavePanel` su Mac; `fileExporter`/`ShareLink` su iPhone e iPad tramite `ModuloSalvaPDF`), `condividi(_:nome:)`.
  - `FoglioDocumento` (`DesignSystem/ComponentiDocumenti.swift:9`) e il foglio bianco del tema Apple in `ReportAnnoInsieme` (`FoglioAnno`, `IntestazioneAnno` con logo e canale, piede con le avvertenze): è il modello più vicino per la fattura.
  - `Tema.Apple.Carta` (`DesignSystem/Apple/TemaApple.swift:184`): tutti i colori della carta del template, già uguali.
  - `Misure.Documento.prospetto` = 595×842 (`DesignSystem/StileDocumenti.swift:267`).
  - `LogoPrisma(colore:)` (`DesignSystem/LogoPrisma.swift`).
- **Anteprima e movimento della pagina**: `Shell/ProspettiApple.swift` (barra laterale, `anteprimaApple`, `paginaAnteprimaApple`, `FoglioAnteprimaApple`, `barraAzioniApple`); `AnyTransition.cambioPagina` e `EffettoPaginaApple` (`DesignSystem/Apple/PaginaApple.swift`); `Tema.Apple.Moto.Pagina` (`TemaAppleMoto.swift:453`); `Tema.Apple.Prospetti.Laterale` (voce 14 bold / 12, `selezioneVoce`, fondo in 0,25 s).
- **Componenti**: `NumeroCheConta` (`CifreApple.swift`), `BarraPiena` (`GraficiApple.swift`), `StilePulsanteApple` con `.applePrimarioGrande` e `.appleGrande` (`PulsantiApple.swift`), `VoceRubricaApple` (`Shell/DossierApple.swift:226`: avatar, nome, riga sotto; per l'importo e lo stato a destra serve una variante), `AvatarCliente`, `EntrataApple` (`CascataApple.swift`), `StatoShell.mostraAvviso(_:)` (`StatoShell.swift:3010`) per i toast.
- **Dati del cliente**: `Cliente.codiceFiscale`, `Cliente.indirizzo` (una sola stringa), `email`, `telefono` (`Dati/Modelli.swift:36-47`).
- **Canale**: `enum Canale { alleanza, indipendente }` (`Modelli.swift:4`).
- **Documenti**: `Documento.Tipo` (`Dati/Documento.swift:7`: kid, polizza, estrattoConto, proposta, prospetto, report, altro) e `CategoriaDocumento`.
- **Consulente**: solo `TestiValutazione.consulente = "Denis Vicenzoni"` (costante, `Motori/TestiValutazione.swift:94`) e `Impostazioni.nomeUtente`. Nessun dato fiscale.
- **Archivio**: `DatiPrisma.versioneAttuale = 25` (`Dati/DatiPrisma.swift:64`); `Impostazioni` (`DatiPrisma.swift:140`).
- **Condivisione**: su iPhone e iPad `StampaCarta.condividi` (`UIActivityViewController`). **Sul Mac non c'è ancora** `NSSharingService` (nessun risultato per `NSSharingService`, `composeMessage`, `mailto:`).
- **XML**: nessuno scrittore XML (nessun risultato per `XMLDocument` o `XMLElement`). `XMLDocument` esiste solo su macOS: per iPhone e iPad conviene scrivere il testo a mano con l'escape dei caratteri e rileggerlo con `XMLParser` (Foundation, su tutte le piattaforme) nelle prove.

#### 5.2 Cosa manca
1. **Scheda** `Shell/StudioParcelle.swift` (dentro `AppStudio`, vedi 01 §5.2) con:
   - `BarraParcelle`: tile dei totali, elenco, pulsante;
   - `VoceParcellaApple`: come `VoceRubricaApple`, più importo e stato a destra;
   - anteprima con `FoglioFattura` e colonna delle azioni;
   - `StatoFileXML`: vuoto / pronto / dati mancanti.
2. **Gettoni** in `DesignSystem/Apple/Tema.Apple+Studio.swift`, sezione `Parcelle` (misure di §2.3, caratteri di §2.4, colori degli stati) e `Tema.Apple.Moto.Fattura` (§3.2).
3. **Foglio della fattura** `Shell/FatturaCarta.swift`: `enum FatturaCarta { static func pagine(_ t: TestiFattura) -> [AnyView] }`, A4 verticale, sempre chiaro, con `Tema.Apple.Carta`. Una pagina; se le righe sono molte, si va a capo su una seconda pagina con «segue».
4. **Modulo** `Shell/ModuloParcella.swift` (§4.1).
5. **Impostazioni › Studio › Fatturazione** (pagina nuova in `ImpostazioniPagine.swift`): i dati del consulente e del regime (§6).
6. **Dossier del cliente**: i campi fiscali che mancano (CAP, comune, provincia, nazione, codice destinatario, PEC, partita IVA se il cliente ne ha una).
7. **Condivisione sul Mac**: `StampaCarta.condividiMac(_:destinatari:servizio:)` con `NSSharingService(named: .composeMessage)` / `.composeEmail`. La usa anche l'app Messaggi (specifica a parte).
8. **Documenti**: `Documento.Tipo.fattura` (nuovo caso; i vecchi archivi si leggono uguale) per tenere PDF e XML nel dossier, nella categoria «Prospetti e report» o in una nuova «Fatture».

#### 5.3 Motori nuovi
**`MotoreParcelle`** (`Motori/MotoreParcelle.swift`). È puro, senza SwiftUI, e non sceglie nessuna regola fiscale: le prende tutte da `RegimeFatturazione` (§5.4).
```swift
struct VociFiscali: Codable, Equatable {
    let imponibile: Double                 // somma delle righe
    let contributo: Double?                // rivalsa o contributo integrativo, se impostato
    let baseIVA: Double
    let iva: Double?                       // nil quando c'è una natura (operazione senza IVA)
    let natura: String?                    // codice N… scelto dall'utente
    let ritenuta: Double?                  // se impostata
    let bollo: Double?                     // se dovuto secondo la regola impostata
    let totaleDocumento: Double
    let nettoAPagare: Double               // totale − ritenuta
}
enum MotoreParcelle {
    static func voci(righe: [RigaParcella], regime: RegimeFatturazione) -> Result<VociFiscali, DatiMancanti>
    static func totali(_ p: [Parcella], anno: Int, oggi: Date) -> (incassato: Double, daIncassare: Double, scadute: Int)
    static func prossimoNumero(_ p: [Parcella], anno: Int, numerazione: NumerazioneFatture) -> Int
    static func mancanti(parcella:, cliente:, consulente: DatiFatturazione) -> [CampoMancante]
}
```
- Tutti gli importi in centesimi interi o in `Decimal`, arrotondati a 2 decimali **riga per riga e nel riepilogo** come vuole il tracciato (con la regola di arrotondamento da confermare).
- «Incassato nel {anno}» = somma di `importoIncassato` (o `nettoAPagare`) delle parcelle pagate con `pagataIl` nell'anno. «Da incassare» = somma del `nettoAPagare` delle emesse non pagate. Le bozze non contano. (Da confermare: netto o totale; vedi Dubbi.)

**`ScrittoreFatturaPA`** (`Motori/ScrittoreFatturaPA.swift`): dalla parcella emessa, dal cliente e dai dati del consulente scrive l'XML del tracciato **FPR12** (fattura tra privati, versione 1.2.x), namespace `http://ivaservizi.agenziaentrate.gov.it/docs/xsd/fatture/v1.2`, codifica UTF-8. Regole:
- date `yyyy-MM-dd`; importi con il punto e 2 decimali (le aliquote con 2 decimali, per esempio `22.00`);
- escape di `& < > " '`; niente caratteri fuori dal set ammesso (Latin, senza emoji);
- **nome del file**: `IT` + identificativo fiscale del trasmittente (codice fiscale o partita IVA) + `_` + progressivo univoco di 5 caratteri alfanumerici + `.xml` (per esempio `IT01234567890_00001.xml`). Il nome del template, `IT_2026-014.xml`, **non è valido** per lo SdI;
- nessuna firma (per le fatture tra privati non serve; l'utente carica il file sul portale «Fatture e Corrispettivi» o lo dà al commercialista).

**`ControlloFatturaPA`**: rilegge l'XML con `XMLParser` e controlla che ci siano tutti i campi obbligatori, che le somme del riepilogo tornino con le righe e che i formati (CF 16, P. IVA 11 cifre con la cifra di controllo, CAP 5, provincia 2, codice destinatario 7) siano giusti. Restituisce l'elenco di ciò che manca, mostrato in `StatoFileXML`.

**`TestiFattura`** (`Motori/TestiFattura.swift`): tutte le stringhe del foglio (§1.4), con le voci fiscali scritte per esteso secondo il regime e la frase di legge eventualmente richiesta (testo dato dall'utente, mai inventato).

#### 5.4 Campi nuovi dell'archivio
Nella stessa versione del Cruscotto (**26**, vedi 01 §5.4), oppure 27 se i due lavori vanno in giri diversi. Tutti facoltativi e letti in modo tollerante; entrano nel backup e in `Prisma --prova-backup` (`Dati/ProvaBackup.swift`).
- **`DatiPrisma.parcelle: [Parcella]`**
  ```swift
  struct Parcella: Codable, Identifiable, Equatable {
      var id: String
      var clienteId: String
      var tipo: TipoDocumentoFattura      // .fattura (TD01), .notaCredito (TD04), .parcella (TD06): scelta dell'utente
      var stato: StatoParcella            // .bozza, .daIncassare, .pagata
      var anno: Int
      var numero: Int?                    // nil finché è bozza; assegnato all'emissione
      var data: Date                      // data del documento
      var righe: [RigaParcella]
      var causale: String?
      var voci: VociFiscali?              // congelate all'emissione (non cambiano se poi cambia il regime)
      var scadenzaPagamento: Date?
      var modalitaPagamento: String?      // codice MP… (per esempio bonifico), scelto dall'utente
      var pagataIl: Date?
      var importoIncassato: Double?
      var ricorrente: Bool
      var collegamento: String?           // id dell'incontro, del prospetto o della posizione da cui nasce
      var progressivoInvio: String?       // i 5 caratteri del nome del file XML
      var documentoPDF: String?, documentoXML: String?   // id in Documenti
      var inviataIl: Date?                // segnata a mano dall'utente (Prisma non parla con lo SdI)
      var notaCreditoDi: String?          // per le note di credito: la fattura che correggono
  }
  struct RigaParcella: Codable, Identifiable, Equatable {
      var id: String; var descrizione: String; var dettaglio: String?
      var quantita: Double?; var prezzoUnitario: Double
      var dal: Date?; var al: Date?
  }
  enum StatoParcella: String, Codable { case bozza, daIncassare, pagata }
  ```
- **`Impostazioni.studio.fatturazione: DatiFatturazione`** (in `ImpostazioniStudio` di 01 §5.4)
  ```swift
  struct DatiFatturazione: Codable, Equatable {
      var nome = "", cognome = ""         // oppure denominazione
      var denominazione: String?
      var partitaIVA = ""                 // IdFiscaleIVA (IdPaese IT + IdCodice)
      var codiceFiscale = ""
      var indirizzo = "", numeroCivico = "", cap = "", comune = "", provincia = "", nazione = "IT"
      var email: String?, telefono: String?, pec: String?
      var albo: IscrizioneAlbo?           // AlboProfessionale, ProvinciaAlbo, NumeroIscrizioneAlbo, DataIscrizioneAlbo
      var iban = "", banca: String?, beneficiario: String?
      var regime = RegimeFatturazione()
      var numerazione = NumerazioneFatture()
      var trasmittente: Trasmittente?      // se diverso dal consulente (per esempio il commercialista)
  }
  struct RegimeFatturazione: Codable, Equatable {
      var codiceRegime: String?           // RF… scelto dall'utente
      var aliquotaIVA: Double?            // nil se l'operazione è senza IVA
      var natura: String?                 // N… quando l'IVA non c'è
      var riferimentoNormativo: String?   // obbligatorio con la natura
      var esigibilitaIVA: String?         // I / D / S
      var cassa: ContributoCassa?         // TipoCassa TC…, aliquota, imponibile, se soggetto a IVA/ritenuta
      var ritenuta: RegolaRitenuta?       // tipo RT…, aliquota, base (percentuale dell'imponibile), causale
      var bollo: RegolaBollo?             // importo e soglia, chi lo paga (a carico del cliente o no)
      var frasePiede: String?             // la dicitura che l'utente vuole sul documento
  }
  struct NumerazioneFatture: Codable, Equatable {
      var formato = "{anno}/{numero:3}"   // il template mostra 2026/016
      var ultimoProgressivoInvio = 0
      var primoNumeroPerAnno: [Int: Int] = [:]   // per chi comincia a usare Prisma a metà anno
  }
  ```
- **`Cliente.fiscale: DatiFiscaliCliente?`**: `numeroCivico`, `cap`, `comune`, `provincia`, `nazione`, `partitaIVA`, `denominazione` (se fattura a una società), `codiceDestinatario` (7 caratteri; `0000000` se non c'è), `pec`. `Cliente.indirizzo` resta per l'anagrafica: il modulo lo divide in via e numero civico la prima volta, e l'utente conferma.

#### 5.5 Prove di calcolo nuove
**`ProvaCalcoliParcelle`** (`Motori/ProvaCalcoliParcelle.swift`), chiamata da `ProvaCalcoli.esegui()`. I regimi delle prove sono **finti e dichiarati come tali** (servono a provare le formule, non a scegliere):
1. Totali: 2 pagate nell'anno, 1 pagata l'anno prima, 2 da incassare, 1 bozza → incassato e da incassare giusti, bozza esclusa.
2. Senza IVA, contributo e ritenuta (regime vuoto): totale = imponibile, `nettoAPagare` = totale.
3. Con un'aliquota IVA di prova: IVA arrotondata a 2 decimali sul riepilogo.
4. Con un contributo di prova del x% soggetto a IVA: base IVA = imponibile + contributo.
5. Con una ritenuta di prova: `nettoAPagare` = totale − ritenuta; la ritenuta non entra nel totale del documento.
6. Bollo: dovuto solo sopra la soglia impostata e solo con le nature che l'utente indica.
7. Numerazione: progressiva per anno, senza buchi; la bozza non prende il numero; a gennaio si riparte da 1.
8. Voci congelate: cambiare il regime dopo l'emissione non cambia le voci di una parcella emessa.
9. Scadute: «da incassare» con `scadenzaPagamento` prima di oggi.
10. Prestazioni: 1.000 parcelle in O(n).

**`ProvaFatturaPA`** (`Motori/ProvaFatturaPA.swift`), chiamata da `ProvaCalcoli.esegui()`:
1. L'XML di una parcella completa si rilegge con `XMLParser` e ha tutti i nodi obbligatori di §6.3.
2. Escape: una descrizione con «&», «<» e l'apostrofo tipografico esce valida.
3. Formati: date, importi con il punto, aliquote `22.00` (o `0.00` con la natura).
4. Somme: `ImponibileImporto` e `Imposta` del riepilogo = somma delle righe; `ImportoTotaleDocumento` coerente.
5. Nome del file: `IT{idfiscale}_{5 caratteri}.xml`, progressivo che non si ripete.
6. Controlli: CF di 16 caratteri, P. IVA di 11 cifre con la cifra di controllo, CAP di 5 cifre, codice destinatario di 7 caratteri.
7. Dati mancanti: senza P. IVA del consulente il controllo restituisce «partita IVA» e il file non si scrive.
8. Se nel repository entra lo schema XSD ufficiale (da chiedere: è un file esterno), il workflow lo valida con `xmllint --schema` sul runner macOS.

---

### 6. Dati che l'utente deve dare (mai inventarli)

#### 6.1 Del consulente (Impostazioni › Studio › Fatturazione)
1. Nome e cognome (o denominazione) come vanno in fattura.
2. **Partita IVA** e **codice fiscale**.
3. **Sede**: indirizzo, numero civico, CAP, comune, provincia, nazione.
4. **Regime fiscale** (codice RF del tracciato).
5. **IVA**: aliquota, oppure la **natura** dell'operazione con il suo **riferimento normativo**; esigibilità.
6. **Contributo previdenziale / cassa**: se c'è, quale (tipo di cassa), aliquota, se è soggetto a IVA e a ritenuta.
7. **Ritenuta d'acconto**: se si applica (dipende anche dal cliente: privato o sostituto d'imposta), tipo, aliquota, base, causale di pagamento.
8. **Imposta di bollo**: se e quando si applica, importo, soglia, a carico di chi.
9. Iscrizione all'albo (OCF o altro), se la vuole sul documento: albo, provincia, numero, data.
10. Contatti da stampare (email, telefono, PEC).
11. **IBAN**, banca e beneficiario; modalità e termini di pagamento (per esempio «entro 30 giorni»).
12. **Numerazione**: formato del numero (il template usa `2026/016`), da che numero partire quest'anno, se c'è una serie separata per le note di credito.
13. **Trasmittente**: se il file lo carica lui (i suoi dati) o un intermediario (il commercialista: suo codice fiscale).
14. Diciture obbligatorie o volute nel piede (il testo esatto lo dà l'utente o il commercialista).
15. Se vuole il colore cuoio del canale sulla testata o la testata neutra del template.

#### 6.2 Del cliente (dossier)
1. Nome e cognome (o denominazione, se è una società).
2. **Codice fiscale** (e partita IVA, se ne ha una).
3. **Indirizzo completo**: via, numero civico, CAP, comune, provincia, nazione.
4. **Codice destinatario** (7 caratteri) o **PEC**; per i privati senza codice: `0000000`.
5. Se è un sostituto d'imposta (per la ritenuta).

#### 6.3 Il tracciato FatturaPA 1.2.x: i campi da riempire
Per ogni campo c'è la fonte. **Nessun valore fiscale è scelto qui.**

**1 · FatturaElettronicaHeader**
- **1.1 DatiTrasmissione**
  - 1.1.1 IdTrasmittente → IdPaese (`IT`), IdCodice (codice fiscale del trasmittente) — §6.1.13
  - 1.1.2 ProgressivoInvio → generato da Prisma, univoco
  - 1.1.3 FormatoTrasmissione → `FPR12` (tra privati; `FPA12` solo per la Pubblica Amministrazione)
  - 1.1.4 CodiceDestinatario → §6.2.4
  - 1.1.5 ContattiTrasmittente (facoltativo)
  - 1.1.6 PECDestinatario → solo se il codice è `0000000` e c'è la PEC
- **1.2 CedentePrestatore** (il consulente)
  - 1.2.1 DatiAnagrafici: IdFiscaleIVA (IdPaese, IdCodice = P. IVA); CodiceFiscale (facoltativo); Anagrafica (Nome + Cognome, oppure Denominazione); AlboProfessionale, ProvinciaAlbo, NumeroIscrizioneAlbo, DataIscrizioneAlbo (facoltativi); **RegimeFiscale** (obbligatorio) — §6.1.1-4, 9
  - 1.2.2 Sede: Indirizzo, NumeroCivico (facoltativo), CAP, Comune, Provincia (per l'Italia), Nazione — §6.1.3
  - 1.2.5 Contatti (facoltativo): Telefono, Email — §6.1.10
  - (1.2.4 IscrizioneREA solo per le imprese iscritte al registro: da chiedere se serve)
- **1.4 CessionarioCommittente** (il cliente)
  - 1.4.1 DatiAnagrafici: IdFiscaleIVA (se ha la P. IVA) e/o **CodiceFiscale** (almeno uno dei due); Anagrafica (Nome + Cognome o Denominazione) — §6.2.1-2
  - 1.4.2 Sede: Indirizzo, NumeroCivico, CAP, Comune, Provincia, Nazione — §6.2.3
- (1.3 RappresentanteFiscale, 1.5 TerzoIntermediario, 1.6 SoggettoEmittente: non servono, salvo che il file lo emetta un terzo)

**2 · FatturaElettronicaBody**
- **2.1.1 DatiGeneraliDocumento**
  - TipoDocumento (TD01 fattura, TD04 nota di credito, TD06 parcella…) — scelta dell'utente
  - Divisa (`EUR`), Data, Numero
  - DatiRitenuta (se c'è): TipoRitenuta, ImportoRitenuta, AliquotaRitenuta, CausalePagamento — §6.1.7
  - DatiBollo (se c'è): BolloVirtuale (`SI`), ImportoBollo — §6.1.8
  - DatiCassaPrevidenziale (se c'è): TipoCassa, AlCassa, ImportoContributoCassa, ImponibileCassa, AliquotaIVA, Ritenuta, Natura (se senza IVA) — §6.1.6
  - ImportoTotaleDocumento (facoltativo, consigliato), Arrotondamento, Causale (facoltativi)
- **2.2.1 DettaglioLinee** (una per riga): NumeroLinea, Descrizione, Quantita e UnitaMisura (facoltativi), DataInizioPeriodo / DataFinePeriodo (facoltativi), PrezzoUnitario, PrezzoTotale, **AliquotaIVA** (0.00 se senza IVA), Natura (se l'aliquota è 0), Ritenuta (`SI` se la riga è soggetta) — §6.1.5, 7
- **2.2.2 DatiRiepilogo** (uno per aliquota o natura): AliquotaIVA, Natura, ImponibileImporto, Imposta, EsigibilitaIVA (facoltativo), **RiferimentoNormativo** (obbligatorio con la natura) — §6.1.5
- **2.4 DatiPagamento** (facoltativo, ma serve per l'IBAN): CondizioniPagamento (TP01 a rate, TP02 completo, TP03 anticipo); DettaglioPagamento: ModalitaPagamento (per esempio MP05 bonifico), DataScadenzaPagamento, ImportoPagamento, IstitutoFinanziario, IBAN, Beneficiario — §6.1.11
- 2.5 Allegati (facoltativo: per esempio il PDF della fattura).

#### 6.4 Cosa mostra l'interfaccia finché mancano
- **Senza dati del consulente**: l'elenco, i totali, il modulo e il PDF funzionano. Il foglio mostra i segnaposto del template (`••••`) con la scritta «da completare» in `Tema.Apple.Carta.ambra` e, nel piede, «Documento di prova». «Prepara il file XML» è spento e la tile arancio elenca i campi mancanti (§1.5).
- **Senza regime**: la riga «Voci fiscali — secondo il regime impostato» resta com'è nel template e il totale è uguale all'imponibile, con l'etichetta «provvisorio». L'emissione chiede conferma: «Il regime fiscale non è impostato: le voci fiscali mancano.» (oppure è bloccata, vedi Dubbi).
- **Senza dati del cliente**: «Codice fiscale ••••» e «Indirizzo del cliente» come nel template, in `ambra`, e la tile «mancano per {cliente}: …».
- **Dati di prova**: con i dati fittizi (Impostazioni › Dati di prova) si caricano le cinque parcelle del template, un consulente di prova («Denis Vicenzoni», P. IVA `00000000000`) e **nessun regime**. Accanto al titolo delle tile compare «dati di prova» (`.k`). Il PDF porta «Documento di prova». L'XML dei dati di prova si può scrivere solo con un nome che comincia con `PROVA_` e con la scritta «non valido per lo SdI». **I dati fiscali di prova non devono mai finire nell'archivio reale.**

---

### 7. Istantanee da aggiungere
Serie **510** (la 500 è del Cruscotto), 1440×900, nello stato finale (`\.prismaStatoFinale`), chiaro e scuro con il suffisso `-scuro`:
- `510-studio-parcelle` / `510-studio-parcelle-scuro`: le cinque parcelle di prova, la 2026/015 scelta (come le schermate del template);
- `511-studio-parcelle-vuoto` / `-scuro`: nessuna parcella;
- `512-studio-parcelle-xml-pronto` / `-scuro`: dati completi di prova, tile «✓ File XML pronto»;
- `513-studio-parcelle-dati-mancanti` / `-scuro`: senza P. IVA e regime, tile arancio con l'elenco e «Prepara il file XML» spento;
- `514-studio-nuova-parcella` / `-scuro`: il modulo della nuova parcella;
- `515-fattura-carta`: il foglio a grandezza piena, **solo chiaro** (la carta è sempre bianca), con le voci fiscali di un regime di prova dichiarato;
- `516-impostazioni-fatturazione` / `-scuro`: la pagina di Impostazioni con i dati del consulente e del regime (campi vuoti).

---

## 4. Studio › Track record

*Parte 03 · titolo della bozza: «03 · Studio › Track record»*

Fonte: `Design/template-novita.html`. Le righe citate sono di quel file:
- voce Novità `NOV[8]` (739);
- dati `TR` (755-759);
- ramo `track` di `studioHTML()` (793-797) e di `montaStudio()` (832-840);
- `trLinee()` (810-812);
- utilità comuni: `conta`/`conteggi` (265-266), `entrata` (267), `inclina` (268-270), `disegnaLinea`/`linee` (282-283), `espandi`/`chiudiDet` (429-438), `rimonta` (727);
- CSS 17-23 (gettoni), 32-54 (riga, testi, pulsanti, card, inclinazione), 92-96 (velo e dettaglio), 117 (tile).

Schermate:
- lista: `orizzonte/chiaro-18-il-tuo-track-record.png`, `orizzonte/scuro-18-il-tuo-track-record.png`;
- dettaglio aperto sulla prima raccomandazione (scattate per questa specifica): `orizzonte/spec/track-det-chiaro.png`, `orizzonte/spec/track-det-scuro.png`.

Per ciò che qui non è detto (finestra, segmentato, card, tile, cascata, numeri che si contano, linee che si disegnano, inclinazione, dettaglio che nasce dalla scheda) vale `Design/template-apple-specifica.md`. L'app Studio, le sue quattro schede e il segmentato sono descritti in `01-studio-cruscotto.md` §1.1.
**Le cifre del template sono dimostrative.** Nell'app arrivano dai motori (§5). Se un dato manca si vede lo stato vuoto o la frase che spiega cosa serve (§6), mai un numero inventato.

---

### 1. Cosa si vede

#### 1.1 Come si arriva
- Studio › segmentato › **«Track record»** (valore `track`).
- Pannello Novità, voce 9: **«Il tuo track record»** con la frase **«Le raccomandazioni e come sono andate»** (`vaiA('studio',()=>{tabS='track'})`).
- Intestazione della finestra invariata: «Il tuo studio.» · «IL TUO LAVORO, COME UN PORTAFOGLIO».

#### 1.2 Struttura
Dall'alto in basso, nell'area contenuti (`#wc`, 1384×654):
1. **Quattro tile di cifre**, in una griglia di 4 colonne uguali.
2. **Riga del titolo**: titolo di sezione e nota a destra del titolo.
3. **Elenco delle raccomandazioni**: una card per raccomandazione, una sotto l'altra.
4. **Dettaglio** (si apre con un clic su una card): nasce dalla card e va al centro.

#### 1.3 Le quattro tile
Testi esatti (etichetta `.k` sopra, valore `.v` sotto):

| # | Etichetta | Valore nel template | Formato | Animato |
|---|---|---|---|---|
| 1 | Raccomandazioni dal 2024 | 64 | intero | sì, conta da 0 |
| 2 | Accettate | 71% | percentuale intera | sì |
| 3 | Ancora in essere dopo 12 mesi | 92% | percentuale intera | sì |
| 4 | Rispetto all’alternativa, in media | +3,1% l’anno | testo fisso, verde | no |

- Nella tile 1 l'anno («2024») è quello della prima raccomandazione in archivio.
- La tile 4 nel template **non** conta (è testo scritto). In Prisma conviene farla contare come le altre, con una cifra decimale (vedi Dubbi). Il colore è `--green` se lo scarto è positivo.
- Gli apostrofi sono tipografici (’).

#### 1.4 Riga del titolo
- Titolo `.h2`: **«Le raccomandazioni e come sono andate»**.
- Accanto, in `.k`: **«l’alternativa è ricostruita con i dati di mercato del periodo»**.
  In Prisma l'alternativa si ricostruisce con i metri di confronto (inflazione, TFR, gestioni separate, indici del consulente). Testo proposto, da confermare: «l’alternativa è ricostruita con i riferimenti del periodo».

#### 1.5 La card di una raccomandazione
Da sinistra a destra, su una riga:
1. **Avatar** del cliente, 40.
2. **Blocco testo**, largo 330:
   - titolo in grassetto 14,5: la proposta (es. **«Fondo pensione aperto da 450 € al mese»**);
   - sotto, in `.k`: «{Nome Cognome} · {mese anno} · invece di: {alternativa in minuscolo}» (es. «Marco Bianchi · settembre 2024 · invece di: nessun versamento integrativo»). Va a capo su due righe se serve.
3. **Pillola dello stato**: «Accettata», «Rimandata» o «Rifiutata».
4. **Mini-grafico** 300×44, spinto a destra (`margin-left:auto`):
   - Accettata: due linee, la proposta (verde #30B15C, spessore 2,6) e l'alternativa (grigia `--ink3`, spessore 2);
   - Rimandata o Rifiutata: solo la linea grigia dell'alternativa.
5. **Colonna destra**, larga 120, testo allineato a destra:
   - con un risultato: «+4.180 €» (`.v` a 20, verde) e sotto «rispetto all’alternativa» (`.k`);
   - Rifiutata: «il cliente ha scelto diversamente» (`.k`);
   - Rimandata: «da riproporre a gennaio» (`.k`). In Prisma il mese viene da `seguito.riprendereIl`.

Raccomandazioni del template (dimostrative):

| Cliente | Data | Proposta | Invece di | Stato | Risultato |
|---|---|---|---|---|---|
| Marco Bianchi | settembre 2024 | Fondo pensione aperto da 450 € al mese | Nessun versamento integrativo | Accettata | +4.180 € |
| Laura Moretti | gennaio 2025 | Ribilanciamento: azionario dal 62% al 44% | Restare com’era | Accettata | +2.950 € |
| Giulia Rossi | marzo 2025 | Piano di risparmio rivalutabile da 300 € al mese | Lasciare i soldi sul conto deposito | Accettata | +1.860 € |
| Sofia Romano | giugno 2025 | Rendita integrativa da 120.000 € | Prelievi liberi dal conto | Rimandata | — |
| Federico Galli (FG, non è tra i clienti) | novembre 2024 | Temporanea caso morte da 200.000 € | Nessuna copertura | Rifiutata | — |

L'ordine del template non è per data (settembre 2024, gennaio 2025, marzo 2025, giugno 2025, novembre 2024): prima le accettate, poi le altre. Proposta per Prisma: accettate per risultato decrescente, poi rimandate, poi rifiutate; dentro ogni gruppo dalla più recente (vedi Dubbi).

#### 1.6 Il dettaglio
Rettangolo finale 900×500, centrato nell'area contenuti (x = (1408 − 900)/2 = 254; y = 92 + (654 − 500)/2 = 169 dalla finestra).
- **Testata** (riga, spazio 14): avatar 54; sopra il titolo l'etichetta `.lbl` «{mese anno} · {cliente}» (in maiuscolo dal CSS: «SETTEMBRE 2024 · MARCO BIANCHI»); il titolo è la proposta, display 25 pt, peso 700, spaziatura −0,5, larghezza massima 700.
- **Corpo** in due colonne, 22 sotto la testata, spazio 28:
  - **sinistra** (flessibile), tre blocchi:
    - `.lbl` **«Perché l’avevi proposta»** (6 sotto), poi il motivo a 15 pt, interlinea 1,5. Es.: «Divario pensionistico di 1.100 € al mese e un vantaggio fiscale che restava inutilizzato.»
    - `.lbl` **«L’alternativa»** (18 sopra, 6 sotto), poi l'alternativa a 15 pt, interlinea 1,5.
    - `.lbl` **«Cosa ha scelto il cliente»** (18 sopra, 6 sotto), poi lo stato a 15 pt, peso 600.
  - **destra**, larga 420:
    - grafico 420×190: linee alte 170; sotto, a y 190, la data d'inizio a sinistra («settembre 2024») e **«oggi»** a destra, 11 pt `--ink3`;
    - legenda, 10 sotto, 12,5 pt, spazio 16: «━ la tua proposta» (segno verde #30B15C) e «┅ l’alternativa» (segno `--ink3`);
    - solo con un risultato: la cifra `.v` verde, 12 sotto, che conta da 0 («4.180 €», **senza** il segno +), e sotto in `.k` **«in più rispetto all’alternativa, stima»**.
- **Piede**, in basso a sinistra (30 dal bordo sinistro, 24 dal fondo, spazio 8):
  - pulsante grande **«Chiudi»**;
  - accanto (10 di margine) in `.k`: **«Una traccia ordinata del tuo lavoro: utile anche per la conformità»**.
- **Pulsante ✕** in alto a destra (22, 22), padding 7/11, come in tutti i dettagli.

Per Rimandata e Rifiutata il dettaglio ha lo stesso schema, senza la cifra; il grafico mostra la sola linea grigia, la legenda resta con due voci (nel template).

#### 1.7 Stati
Il template ha solo lo stato pieno. Proposti per Prisma:
- **Nessuna proposta in archivio**: niente tile a zero. Al posto delle tile e dell'elenco, una card con «Qui vedrai le tue raccomandazioni e come sono andate» e la frase «Ogni proposta che segni come presentata, accettata, rifiutata o rimandata entra qui da sola.», con il pulsante «Vai a Posizioni».
- **Proposte, ma nessuna decisa**: le tile 2-4 mostrano «—» con la didascalia «nessuna decisione ancora»; l'elenco mostra le presentate con la pillola neutra «In attesa».
- **Accettata senza misura**: la colonna destra mostra «da misurare» e sotto «serve un valore aggiornato» (`.k`). Succede se la posizione non ha almeno due valori (`controvalore` + `rilevazioni`), se lo storico è sotto i 3 mesi (`MotoreAndamento.anniGiudizio`) o se mancano gli anni del riferimento (`FattoreRiferimento.mancanti`). Nel mini-grafico c'è solo la linea che si può disegnare.
- **Riferimento da aggiornare** (`FattoreRiferimento.daAggiornare`): la cifra c'è solo se `fattore != nil`; altrimenti «da misurare» con «aggiorna i riferimenti in Impostazioni».
- **Coperture** (area protezione): non c'è un rendimento. La colonna destra mostra il capitale assicurato («200.000 € assicurati») al posto della differenza.
- **Risultato negativo**: si mostra com'è, «−1.200 €» in `--red` con «rispetto all’alternativa». Mai nasconderlo (vedi Dubbi).
- **Caricamento ed errore**: non servono, i calcoli sono locali e immediati (cache della shell, §5.3).

---

### 2. Misure e stile

#### 2.1 Gettoni
Gli stessi di `01-studio-cruscotto.md` §2.1. Quelli usati qui:

| CSS | Chiaro | Scuro | Prisma |
|---|---|---|---|
| `--card` | rgba(255,255,255,.82) | rgba(255,255,255,.07) | `Tema.Apple.Colore.card` |
| `--cardE` (dettaglio, pulsanti) | #fff | rgba(40,54,66,1) | `cardPiena` |
| `--sep` | rgba(0,0,0,.08) | rgba(255,255,255,.09) | `separatore` |
| `--ink` / `--ink2` / `--ink3` | nero .87 / .55 / .34 | bianco .94 / .62 / .38 | `inchiostro`, `inchiostro2`, `inchiostro3` |
| `--green` | #2FA35A | uguale | `Colore.verde` (`TemaApple.swift:86`) |
| `--red` | #E5484D | uguale | `Colore.rosso` (82) |
| `--orange` | #E08A00 | uguale | `Colore.arancio` (84) |
| `--shadow` | 0 24px 48px -28px rgba(8,40,60,.4), 0 2px 8px -3px rgba(8,40,60,.1) | 0 26px 52px -26px rgba(0,0,0,.8), 0 3px 10px -3px rgba(0,0,0,.35) | ombra della card |
| `--scrim` | rgba(220,232,240,.4) | rgba(5,12,18,.5) | velo del dettaglio |

Colori fissi del Track record, uguali in chiaro e in scuro:
- linea della proposta e segno in legenda: **#30B15C** (`--r1`, `Colore.anello1`);
- pillole: Accettata testo `--green` su rgba(47,163,90,.13); Rifiutata testo `--red` su rgba(229,72,77,.12); Rimandata testo `--orange` su rgba(224,138,0,.13).

Da raccogliere in `Tema.Apple+Studio.swift` (`Tema.Apple.Studio.Track`): colori delle pillole, fondo pillola con le tre opacità, colore della linea.

#### 2.2 Superfici
- **Tile** (`.tile`): raggio 18, `--card`, bordo 1 `--sep`, padding 14/16, nessuna ombra. In Prisma `Superficie.tile` + `padding.tile`.
- **Card della raccomandazione** (`.card .tilt`): raggio 22, `--card`, bordo 1 `--sep`, ombra `--shadow`, padding **14 sopra/sotto, 18 ai lati**, contenuto in riga con spazio **16**, allineato al centro. Si inclina con massimo **3** gradi (`data-max="3"`, come le schede impegno: `Moto.Inclinazione.massimoImpegni = 3`). Riflesso `.sheen` radiale 260×200.
- **Dettaglio** (`#det`): `--cardE`, bordo 1 `--sep`, ombra 0 50px 90px -30px rgba(8,40,60,.55), raggio da 22 a 28, contenuto con padding 26/30. In Prisma: `presentatoreDettaglio` (`DettaglioApple.swift`).
- **Velo** (`#scrim`): `--scrim` con sfocatura 10.
- **Pillola stato**: capsula, 12 pt peso 700, padding 4/10.

#### 2.3 Misure
- Griglia delle tile: 4 colonne uguali, spazio **12**.
- Riga del titolo: margine **18 sopra, 4 ai lati, 10 sotto**; la nota è a 8 dal titolo.
- Elenco: colonna con spazio **10** tra le card.
- Card: avatar 40; blocco testo 330; mini-grafico 300×44 con le etichette fuori dal riquadro (`overflow:visible`); colonna destra 120.
- Linee del mini-grafico e del dettaglio (`trLinee`): 14 punti equidistanti in x; la scala y è comune alle due linee, dal minimo × 0,995 al massimo × 1,005. Spessori: proposta 2,6, alternativa 2. Tratteggio dell'alternativa nel codice: [4, 4] (vedi Dubbi: in pratica si vede piena).
- Dettaglio: 900×500; testata con avatar 54 e spazio 14; corpo 22 sotto, colonne a spazio 28, destra 420; grafico 420×190 (linee in 170); legenda 10 sotto; cifra 12 sotto.

#### 2.4 Caratteri
| Elemento | CSS | Prisma |
|---|---|---|
| Etichetta tile `.k` | 12,5 pt, `--ink2` | `Carattere.didascalia` (esistente) |
| Valore tile `.v` | display 26 pt, 700, spaziatura −0,5, cifre tabellari | `Carattere.valore` (`TemaApple.swift:656`) |
| Titolo sezione `.h2` | display 21 pt, 700, spaziatura −0,4 | esistente (titolo di sezione) |
| Titolo raccomandazione | 14,5 pt, 700 (`b`) | nuovo gettone `Studio.Track.titolo` |
| Sottotitolo card `.k` | 12,5 pt `--ink2` | didascalia |
| Pillola | 12 pt, 700 | nuovo `Studio.Track.pillola` |
| Risultato card | `.v` a **20 pt**, verde | nuovo `Studio.Track.risultato` |
| Etichette `.lbl` del dettaglio | 12 pt, 600, maiuscolo, spaziatura .6, `--ink2` | `Carattere.etichetta` (684) |
| Titolo dettaglio | display 25 pt, 700, spaziatura −0,5 | nuovo `Studio.Track.titoloDettaglio` |
| Testi del dettaglio | 15 pt, interlinea 1,5; stato 15 pt 600 | nuovo |
| Date sotto il grafico | 11 pt `--ink3` | esistente (assi) |
| Legenda | 12,5 pt | |
| Cifra del dettaglio | `.v` 26 pt verde | `Carattere.valore` |
| Pulsante «Chiudi» `.btn.big` | 13,5 pt, 600, padding 10/18 | pulsante grande esistente |

---

### 3. Movimento

Valori del template e corrispondenze in `Tema.Apple.Moto`:
- **Cambio di scheda** (`rimonta`): il contenuto svanisce in 0,13 s (opacità 0, scala 0,99), poi si rimonta e partono cascata, numeri e linee. La pillola del segmentato scorre in 0,5 s con `--spring` (`Moto.Segmentato`).
- **Cascata** (`entrata`, tutti gli elementi `.st`: le 4 tile, la riga del titolo, le card): 0,72 s, curva cubic-bezier(.22,1,.36,1), da translateY 18, scala 0,985, sfocatura 6 a fermo; ritardo i × 0,048 s nell'ordine del documento (tile 0-3, titolo 4, card 5…). È `Moto.Cascata` (durata 0,72, passo 0,048).
- **Numeri che contano** (`conteggi`): da 0 al valore in 1,1 s + min(i, 6) × 0,06 s, curva 1 − (1 − t)^4. Le tile 1-3 sono i = 0, 1, 2. `Moto.Numero` (1,10 / 0,06 / 6).
- **Linee che si disegnano** (`linee`): ogni tracciato si disegna in 1,5 s con cubic-bezier(.22,1,.36,1), ritardo 0,15 + i × 0,12 s nell'ordine dei tracciati della schermata (per ogni card prima l'alternativa, poi la proposta). Con 5 card i tracciati sono 8: l'ultimo parte a 0,99 s. `Moto.Linea` (1,50 / 0,15 / 0,12), che in `TracciatoGrafico` è il parametro `indice`. Con molte card conviene fermare l'indice (per esempio al massimo 12) per non far partire le ultime linee dopo 1,5 s.
- **Inclinazione** delle card al passaggio del puntatore: perspective 900, rotateX (0,5 − y) × 3 × 0,8, rotateY (x − 0,5) × 3, translateY −5, scala 1,02; ritorno in 0,5 s con `--spring`; ombra al passaggio 0 40px 60px -30px rgba(8,40,60,.5), 0 4px 12px -4px rgba(8,40,60,.16) in 0,4 s; riflesso in 0,3 s. `SchedaInclinabileApple` con `massimo: Moto.Inclinazione.massimoImpegni`.
- **Dettaglio**:
  - apertura dalla card in 0,62 s con cubic-bezier(.32,1.22,.5,1), raggio 22 → 28; la card d'origine si nasconde;
  - a 0,17 s partono numeri (la cifra del risultato), linee del grafico grande; il contenuto compare in 0,35 s con 0,16 s di ritardo;
  - velo in 0,45 s con sfocatura 10;
  - chiusura in 0,46 s con cubic-bezier(.32,1.08,.5,1) verso la card, poi la card ricompare.
  È tutto già in `DettaglioApple.swift` (`Moto.Curva.dettaglioApre`/`dettaglioChiude`).
- **Riduci movimento** (`ridotto` nel template, `\.prismaCalmo` in Prisma): durate a 1 ms, niente cascata né inclinazione, numeri subito al valore; il dettaglio compare già al centro. In Prisma: dissolvenza di 0,15 s come da CLAUDE.md.
- **Istantanee** (`\.modoIstantanea`, `\.prismaStatoFinale`): tile complete, linee tracciate, nessuna inclinazione.

---

### 4. Interazioni
- **Clic su una card** → apre il dettaglio di quella raccomandazione (un solo dettaglio alla volta).
- **Chiusura del dettaglio**: pulsante «Chiudi», pulsante ✕, clic sul velo, tasto **Esc** (gestore globale 1074).
- **Puntatore sopra una card** → inclinazione e riflesso (solo Mac). Su iPad e iPhone la card si abbassa leggermente alla pressione (come `SchedaInclinabileApple` fuori dal Mac).
- **Segmentato** in testata: cambia scheda dello Studio.
- Nel template non ci sono trascinamenti, filtri né ordinamenti. Proposti per Prisma (da confermare):
  - nel dettaglio, un pulsante **«Apri la posizione»** che porta a Posizioni sulla posizione (`StatoShell.apri(_:)`), e per le rimandate **«Riproponi»** (riapre la proposta nel seguito);
  - nella riga del titolo, un piccolo segmentato «Tutte · Accettate · Altre» se le raccomandazioni sono molte;
  - lo scorrimento verticale dell'elenco quando le card non entrano (con 64 raccomandazioni non entrano: il template ne mostra 5).
- **Tastiera** (proposta): frecce su/giù per spostarsi tra le card, Invio per aprire il dettaglio, Esc per chiuderlo.

---

### 5. Mappa verso Prisma

#### 5.1 Esiste già (verificato con grep in `Sources/Prisma`)
- **Le raccomandazioni sono le proposte.**
  - `Posizione.stato` (`StatoPosizione`: `inEssere`, `proposta`, `chiusa`; `Dati/Posizione.swift:29-30`);
  - `Posizione.esito` (`EsitoProposta`: bozza, presentata, accettata, rifiutata, rimandata; `Posizione.swift:44-45`);
  - `Posizione.creataIl`, `canale`, `clienteId`, `area`, `nome`, `premio`, `frequenza`, `versamentoIniziale`, `capitaleAssicurato`;
  - `SeguitoProposta` con `presentataIl`, `esitoIl`, `motivo` (`MotivoEsito`), `nota`, `riprendereIl` (`Dati/SeguitoProposte.swift:30`).
  - `MotoreSeguitoProposte.applica` (`Motori/MotoreSeguitoProposte.swift:313`): l'accettata diventa `stato = .inEssere` ma tiene `esito = .accettata` e `seguito.esitoIl`. La rifiutata e la rimandata restano `proposta`. Quindi tutte le raccomandazioni si ritrovano dalle posizioni.
  - `Portafoglio.tassoAccettazione` = accettate / (accettate + rifiutate) (`Motori/MotorePortafoglio.swift:68`) e il conteggio `esiti` (146), che conta già le accettate passate in essere.
- **Perché l'avevi proposta**: `SchedaAdeguatezza.motivazione` («Perché la proposta è adatta al cliente, con le parole del consulente»; `Dati/SchedaAdeguatezza.swift`), una per posizione, che resta anche quando la proposta diventa in essere.
- **L'alternativa**, in parte: `SchedaAdeguatezza.posizioneSostituitaId` (la posizione in essere che la proposta sostituisce) e `SchedaAdeguatezza.fonte` (`FonteCapitale`: liquidità, sostituzione, nuovi risparmi, altro).
- **Valori aggiornati delle posizioni**: `Posizione.controvalore`, `dataValore`, `totaleVersato`, `rilevazioni: [Rilevazione]` (data, controvalore, versato) e `movimenti` (`Posizione.swift:128`, 163-166, 191, 219).
- **Come è andata davvero**: `MotoreAndamento.calcola(_:)` → `AndamentoPosizione` con `punti`, `rendimentoPeriodo`, `rendimentoAnnuo`, `anni`, soglie `anniMinimi` 0,95 e `anniGiudizio` 0,25 (`Motori/MotoreAndamento.swift`).
- **Riferimenti e rendimento misurato con un metro esterno** (`Dati/Riferimenti.swift`, `Motori/MotoreRiferimenti.swift`, `Motori/TestiRiferimenti.swift`):
  - `SerieRiferimento` (inflazione FOI, TFR netto, gestioni separate, fino a 3 indici del consulente), `TabellaRiferimenti`, `RiferimentiRendimento` nelle impostazioni (`Impostazioni › Rendimenti`, `Shell/ImpostazioniRiferimenti.swift`), `Posizione.riferimento` (metro scelto per la posizione);
  - `MotoreRiferimenti.serieDi(_:impostazioni:tabella:)`: il metro della posizione;
  - `MotoreRiferimenti.fattore(_:dal:al:tabella:)`: fattore del riferimento anno per anno, con `mancanti`, `stimati`, `daAggiornare`;
  - `MotoreRiferimenti.confronto(...)` → `ConfrontoRiferimento` con `punti` (valore e `atteso` al ritmo del riferimento: **sono le due linee del grafico**), `scarto`, `giudizio`;
  - `MotoreRiferimenti.versamenti(_:serie:tabella:)` → `VersamentiAlRiferimento`: **i versamenti veri fatti crescere come il riferimento** (metodo «public market equivalent»), con `valoreEffettivo`, `valoreRiferimento`, `differenza`, `tassoEffettivo`, `tassoRiferimento` (XIRR). È esattamente «+4.180 € rispetto all’alternativa» e lo scarto annuo della tile 4.
  - I flussi datati: `MotoreResoconto.flussiDatati(_:data:)` (`Motori/MotoreResoconto.swift:269`).
  - Il pannello che già lo mostra per una posizione: `Shell/PannelloRiferimento.swift`.
- **Componenti del tema Apple**:
  - `NumeroCheConta` (`DesignSystem/Apple/CifreApple.swift:77`);
  - `TracciatoGrafico` con `tratteggio` e `indice` (`GraficiApple.swift:206`);
  - `SchedaInclinabileApple` / `.inclinazione(massimo:)` (`SchedeApple.swift:40`) con `Moto.Inclinazione.massimoImpegni = 3`;
  - `presentatoreDettaglio` / `.origineDettaglio(id:)` (`DettaglioApple.swift`); misura da aggiungere in `Tema.Apple.Misura.DettaglioAperto` (`Tema.Apple+Schede.swift:20`): `track = CGSize(width: 900, height: 500)`;
  - `EntrataApple` (cascata), `SegmentatoPillola`, `Superficie.tile`/`.card`, `Carattere.valore`/`.etichetta`;
  - `AvatarCliente` (`DesignSystem/Componenti.swift:698`, usato in `DossierApple.swift:240`) con `Misura.Avatar.grande = 54`; per il 40 serve un lato nuovo (`Misura.Avatar` ha 38 e 54).
  - `PillolaStato` (`Shell/AppPosizioni.swift:612`) è del vecchio tema: per il Track record serve una pillola del tema Apple (§5.2).
- **Prove**: `ProvaCalcoli.esegui()` chiama le prove separate; c'è già `ProvaCalcoliSeguito` per il seguito delle proposte.
- **Archivio**: `DatiPrisma.versioneAttuale = 25` (`Dati/DatiPrisma.swift:64`).

#### 5.2 Cosa manca
1. **La scheda** `Track record` dentro `Shell/AppStudio.swift` (vista `TrackRecordStudio`), con la card `CardRaccomandazione` e il dettaglio `DettaglioRaccomandazione`.
2. **L'alternativa di ogni proposta.** Prisma sa quale posizione si sostituisce e da dove arrivano i soldi, ma non ha un campo «invece di» né un metro scelto per l'alternativa. Per le proposte nuove serve scriverla (campo nuovo, §5.4). Per le vecchie si ricava (regole sotto).
3. **La data di chiusura** di una posizione: `stato = .chiusa` non ha una data, quindi «ancora in essere dopo 12 mesi» non si può calcolare con esattezza (campo nuovo `chiusaIl`).
4. **Le raccomandazioni senza prodotto** («Ribilanciamento: azionario dal 62% al 44%»): oggi non sono posizioni. Prisma non ha lo storico dell'allocazione prima e dopo, quindi «restare com'era» non si ricostruisce. Proposta: nella prima versione il Track record conta solo le proposte di prodotto; i ribilanciamenti dopo, con una scelta dell'utente (vedi Dubbi).
5. **Contatti che non sono clienti** (Federico Galli): in Prisma le posizioni hanno sempre un `clienteId`. Se l'utente vuole tenerli, servono come clienti «potenziali» (vedi Dubbi).
6. **Pillola dello stato del tema Apple**: nuovo componente `PillolaEsitoApple` (Accettata, Rimandata, Rifiutata, In attesa) in `DesignSystem/Apple/`.
7. **Mini-grafico a due linee**: si compone con due `TracciatoGrafico` (nessun componente nuovo), con una funzione pura che normalizza i punti su una scala comune (`MotoreTrackRecord.normalizza`).

#### 5.3 Motore nuovo: `MotoreTrackRecord` (`Motori/MotoreTrackRecord.swift`)
Puro, senza SwiftUI; si chiama dalla cache dello Studio (`CacheMotoriStudio`, la stessa del Cruscotto), perché per ogni accettata calcola andamento e confronto.

```swift
struct TrackRecord {
    struct Cifre {
        let dal: Int?                 // anno della prima raccomandazione
        let raccomandazioni: Int
        let accettate: Double?        // accettate / (accettate + rifiutate), come Portafoglio.tassoAccettazione
        let inEssereDopo12Mesi: Double?  // tra le accettate da almeno 12 mesi, quelle non chiuse entro 12 mesi
        let scartoAnnuoMedio: Double?    // punti % all'anno, media pesata (vedi Dubbi)
    }
    enum Stato { case accettata, rimandata(riprendereIl: Date?), rifiutata, inAttesa }
    enum Risultato {
        case differenza(Double, stima: Bool)   // valoreEffettivo − valoreRiferimento
        case copertura(capitale: Double)        // area protezione
        case daMisurare(Motivo)                 // pochi valori, storico breve, riferimento mancante
        case nessuno                            // rimandata, rifiutata, in attesa
        enum Motivo { case pochiValori, storicoBreve, riferimentoMancante(anni: [Int]), riferimentoDaAggiornare }
    }
    struct Voce: Identifiable {
        let posizione: Posizione; let cliente: Cliente
        let data: Date                // presentataIl, se no esitoIl, se no creataIl
        let titolo: String            // la proposta («Fondo pensione aperto da 450 € al mese»)
        let alternativa: String       // «Nessun versamento integrativo»
        let perche: String?           // SchedaAdeguatezza.motivazione
        let stato: Stato
        let risultato: Risultato
        let proposta: [AndamentoPosizione.Punto]   // valori veri
        let alternativaPunti: [Double?]            // atteso al ritmo del metro dell'alternativa
        var id: String { posizione.id }
    }
    let cifre: Cifre
    let voci: [Voce]
}
enum MotoreTrackRecord {
    static func calcola(posizioni:, clienti:, schede: [SchedaAdeguatezza], riferimenti: RiferimentiRendimento,
                        oggi: Date, cal: Calendar) -> TrackRecord
    static func normalizza(_ a: [Double], _ b: [Double?], margine: Double = 0.005) -> (a: [CGPoint], b: [CGPoint])
}
```

Regole di calcolo (da confermare, vedi Dubbi):
- **Quali proposte entrano**: le posizioni con `esito` presentata, accettata, rifiutata o rimandata (le bozze no). Le accettate si riconoscono anche dopo il passaggio in essere (`esito == .accettata`).
- **Data della raccomandazione**: `seguito.presentataIl`, altrimenti `seguito.esitoIl`, altrimenti `creataIl`. Si scrive «mese anno» in minuscolo («settembre 2024»).
- **Titolo**: `Posizione.nome` più l'importo («da 450 € al mese» con `premio` e `frequenza`; «da 120.000 €» con `versamentoIniziale`; «da 200.000 €» con `capitaleAssicurato` per le coperture). Il testo libero di §5.4 vince.
- **Raccomandazioni dal {anno}**: il numero delle voci; l'anno è quello della voce più vecchia.
- **Accettate**: accettate / (accettate + rifiutate), come `Portafoglio.tassoAccettazione`. Le rimandate e le presentate non contano (vedi Dubbi: il template potrebbe intendere accettate / tutte).
- **Ancora in essere dopo 12 mesi**: tra le accettate con `esitoIl` (o `decorrenza`) di almeno 12 mesi fa, la quota di quelle che non sono state chiuse entro 12 mesi (`chiusaIl == nil` o `chiusaIl` dopo 12 mesi). Senza nessuna accettata di almeno 12 mesi: «—».
- **Risultato di un'accettata** (in essere o chiusa, area non protezione):
  1. andamento con `MotoreAndamento.calcola(p)`: almeno due valori e almeno `anniGiudizio` (3 mesi) di storico, altrimenti `.daMisurare(.pochiValori / .storicoBreve)`;
  2. metro dell'alternativa: quello scritto nella proposta (§5.4 `alternativa.serie`); altrimenti, se c'è una posizione sostituita, la sua famiglia (`FamigliaRiferimento.di`); altrimenti il metro della posizione stessa (`MotoreRiferimenti.serieDi`);
  3. `MotoreRiferimenti.versamenti(flussiDatati(p), serie:, tabella:)`: `differenza` = valore vero − valore che avrebbero gli stessi versamenti al ritmo dell'alternativa. Se `mancantiDal != nil` → `.daMisurare(.riferimentoMancante)`;
  4. `stima` = true se ci sono anni `stimati` o flussi ricostruiti (`FlussiDatati.reali == false`): da qui «, stima» nel dettaglio.
  5. Per «Nessun versamento integrativo» e «Lasciare i soldi sul conto» l'alternativa è «gli stessi soldi lasciati fermi o sul conto»: si usa come metro un indice del consulente (per esempio «Conto deposito») o, se l'utente lo sceglie, l'inflazione. Il risparmio fiscale dei fondi pensione **non** entra nella differenza nella prima versione (vedi Dubbi).
- **Linee**: la proposta = `AndamentoPosizione.punti[].valore`; l'alternativa = `ConfrontoRiferimento.punti[].atteso` calcolato con il metro dell'alternativa. Si normalizzano su una scala y comune (minimo × 0,995, massimo × 1,005, come il template). Per rimandate e rifiutate: nessuna linea vera da disegnare (vedi Dubbi).
- **Scarto annuo medio** (tile 4): per le accettate con `tassoEffettivo` e `tassoRiferimento`, la media di (effettivo − riferimento) pesata sul `valoreRiferimento`; si mostra con una cifra decimale e «l’anno». Con meno di una voce misurata: «—».
- **Ordine**: accettate per differenza decrescente (le «da misurare» in fondo al gruppo), poi in attesa, rimandate, rifiutate; a parità, dalla più recente.
- Prestazioni: O(P × anni) per l'andamento e il fattore; con i 200 clienti di `--prova-carico` va calcolato nella cache e non nel `body`.

#### 5.4 Campi nuovi dell'archivio
Nella stessa versione nuova dell'archivio dello Studio (26, se il Cruscotto e le Parcelle entrano insieme; altrimenti la successiva). Tutti facoltativi, letti in modo tollerante (come `SeguitoProposta.init(from:)`), compresi nel backup e in `Prisma --prova-backup`.
- `SeguitoProposta.alternativa: AlternativaProposta?`, con
  `AlternativaProposta { var testo: String /* «Nessun versamento integrativo» */; var serie: String? /* id di SerieRiferimento con cui ricostruirla */ }`.
  Va nel seguito perché il seguito resta con la posizione anche dopo l'accettazione. In alternativa si può mettere in `SchedaAdeguatezza` accanto a `posizioneSostituitaId` (vedi Dubbi).
- `SeguitoProposta.titolo: String?` per scrivere la raccomandazione con parole proprie («Ribilanciamento: azionario dal 62% al 44%»). Se manca, si compone da nome e importo.
- `Posizione.chiusaIl: Date?`: quando la posizione è stata chiusa (riscatto, disdetta, scadenza). Si scrive quando lo stato passa a `.chiusa` (e si chiede la data, con oggi come proposta). Per le posizioni già chiuse resta `nil`: contano come «chiuse in data sconosciuta» e si escludono dalla tile 3 (vedi Dubbi).
- Nessun campo per «perché l'avevi proposta»: è `SchedaAdeguatezza.motivazione`. Se una proposta non ha la scheda, il blocco mostra «Motivo non scritto» in `--ink3` con il collegamento «Scrivilo nella scheda di adeguatezza».
- Impostazioni: `RiferimentiRendimento.perAlternativa: String?` (metro predefinito dell'alternativa «lasciare i soldi sul conto»), facoltativo.

#### 5.5 Prove di calcolo nuove: `ProvaCalcoliTrackRecord` (`Motori/ProvaCalcoliTrackRecord.swift`)
Si chiama da `ProvaCalcoli.esegui()`. Casi costruiti a mano:
1. Selezione: bozza esclusa; presentata, accettata in essere, rifiutata, rimandata incluse → 4 voci.
2. Accettate: 3 accettate e 1 rifiutata (più 1 rimandata) → 75%; senza decise → nil.
3. In essere dopo 12 mesi: 4 accettate da oltre 12 mesi, una chiusa dopo 5 mesi (`chiusaIl`) → 75%; un'accettata di 6 mesi fa non entra nel calcolo.
4. Differenza: versamento unico di 10.000 € il 1° gennaio di due anni fa, valore oggi 10.800 €, metro a +1% l'anno per due anni → valore al riferimento 10.201 €, differenza +599 € (con il fattore giorno per giorno di `MotoreRiferimenti.fattore`).
5. Versamenti mensili: i versamenti crescono ciascuno dalla sua data (stesso risultato di `MotoreRiferimenti.versamenti`).
6. Riferimento mancante per un anno → `.daMisurare(.riferimentoMancante)`; anni oltre l'ultimo noto entro `anniStimabili` → `stima = true`.
7. Storico di 2 mesi → `.daMisurare(.storicoBreve)`; un solo valore → `.pochiValori`.
8. Copertura accettata → `.copertura(capitale:)`, fuori dalla media della tile 4.
9. Scarto medio pesato: due voci (+2 pt su 30.000 €, +5 pt su 10.000 €) → +2,75 pt.
10. Normalizzazione: due serie con minimo e massimo comuni, i punti tra 0 e 1, x equidistanti; serie costante → linea a metà altezza, senza divisione per zero.
11. Data della raccomandazione: presentataIl, poi esitoIl, poi creataIl.
12. Ordine: accettate per differenza decrescente, poi rimandate e rifiutate.
13. Lettura tollerante: `alternativa` e `chiusaIl` malformati diventano nil senza scartare la posizione.

---

### 6. Dati che l'utente deve dare (mai inventarli)
1. **Valori aggiornati delle posizioni accettate**: almeno un controvalore recente dopo quello alla firma (estratto conto, rilevazioni). Senza, la colonna destra mostra «da misurare · serve un valore aggiornato».
2. **L'alternativa di ogni proposta**: che cosa avrebbe fatto il cliente senza la raccomandazione, e con quale metro ricostruirla (inflazione, gestioni separate, un indice, un tasso di conto deposito).
3. **I valori annui dei riferimenti** che Prisma non porta con sé: gli indici del consulente (per esempio il rendimento del conto deposito anno per anno) e l'aggiornamento di inflazione e gestioni separate quando escono.
4. **Il motivo della proposta** (scheda di adeguatezza), se non è già scritto.
5. **Le date di chiusura** delle posizioni chiuse, almeno per quelle accettate negli ultimi anni.
6. **Le raccomandazioni senza prodotto** (ribilanciamenti, rendite non ancora sottoscritte) e i contatti che non sono clienti: se e come tenerli.

Finché mancano, l'interfaccia mostra:
- **Senza proposte**: lo stato vuoto di §1.7.
- **Accettate senza valori aggiornati**: «da misurare» con «serve un valore aggiornato»; la tile 4 mostra «—» e sotto «servono valori aggiornati».
- **Senza alternativa scritta**: l'alternativa si ricava (sostituita, altrimenti il metro della posizione) e il testo diventa «invece di: lo stesso capitale al ritmo dell’inflazione» (con il nome del metro). Nel dettaglio, sotto «L’alternativa», la frase «Ricavata da Prisma: scrivila nella proposta per renderla esatta.»
- **Senza motivo**: «Motivo non scritto» (§5.4).
- **Dati di prova**: con i 5 clienti del template e i 30 fittizi, `DatiDemo`/`ClientiFittizi` caricano proposte con esito, seguito, alternative, rilevazioni e chiusure di prova (le cinque del template come base). Accanto al titolo «Le raccomandazioni e come sono andate» compare l'etichetta «dati di prova» (`.k`), come negli altri moduli dimostrativi. I valori di prova non finiscono mai nell'archivio reale.

---

### 7. Istantanee da aggiungere
Serie 5xx di Orizzonte/Studio (500-507 sono del Cruscotto, vedi `01-studio-cruscotto.md` §7). Proposta per il Track record: **520-525**, chiaro e scuro (suffisso `-scuro`), a 1440×900, nello stato finale.
- `520-studio-track` / `520-studio-track-scuro`: dati di prova completi (4 tile, 5 card: tre accettate con risultato, una rimandata, una rifiutata).
- `521-studio-track-dettaglio` / `521-studio-track-dettaglio-scuro`: dettaglio aperto sulla prima accettata (cifra, due linee, legenda, piede).
- `522-studio-track-dettaglio-rifiutata` / `-scuro`: dettaglio di una rifiutata (senza cifra).
- `523-studio-track-vuoto` / `-scuro`: archivio senza proposte (stato vuoto).
- `524-studio-track-da-misurare` / `-scuro`: accettate senza valori aggiornati e con un riferimento mancante («da misurare», tile 4 «—»).
- `525-studio-track-negativo` / `-scuro`: una accettata con risultato negativo in rosso (per verificare che non si nasconda).

---

## 5. Messaggi — «Prisma scrive per te»

*Parte 05 · titolo della bozza: «05 · App Messaggi — «Prisma scrive per te»»*

Fonte: `Design/template-novita.html`, righe 849-888 (`selM`, `tonoM`, `canM`, `MSG`, `APPS.messaggi`, `compoHTML`, `scriviM`, `montaCompo`), voce `NOV[1]` (riga 732), dock (riga 358), icona vettoriale `data-icona="Messaggi"` (riga 1131).
Schermate: `orizzonte/chiaro-11-prisma-scrive-per-te.png`, `orizzonte/scuro-11-prisma-scrive-per-te.png`, più `orizzonte/shots05/` (a: entrata a metà, b: canale Messaggi, c: Breve + Messaggi, d: scuro su Sofia).
Per ciò che non è scritto qui (finestra interna, barra, dock, `.side`, `.rub`, `.card`, `.seg`, `.btn`, avvisi) vale `Design/template-apple-specifica.md`.
Le cifre e i testi dei messaggi del template sono dimostrativi: nell'app i fatti vengono dai motori, il testo lo scrive Qwen a partire da una bozza di Prisma.

---

### 1. Cosa si vede

#### 1.1 Come si arriva
- **Dock**: nuova icona «Messaggi» (busta arancio con un pallino rosso disegnato nel glifo), settima voce, dopo Agenda e prima di Prospetti. Ordine completo del template: Scrivania, Clienti, Posizioni, Analisi 360, Incontri, Agenda, **Messaggi**, Prospetti, Mercato, Studio, Ruby, Impostazioni.
- **Pannello Novità** (`#bNov`): seconda voce, «Prisma scrive per te» / «Ruby prepara i messaggi ai clienti, li spedisci tu». Apre Messaggi sulla prima occasione (`selM=0`).
- **Da altre app** (tutte aprono Messaggi con `selM=1`, cioè su un'occasione già scelta):
  - Studio › parcella: pulsante `#fMsg` (riga 831).
  - Mercato › «Chi è toccato oggi»: pulsante «Prepara un messaggio» (`.mkMsg`, riga 904).
  - Posizioni › La prova del fuoco: pulsante «Messaggio» (`.fM`, riga 972), accanto a «Chiama».
  Nel template portano tutte alla seconda voce di prova; nell'app devono aprire Messaggi **sul cliente e sul motivo da cui si parte** (vedi §5.3).

#### 1.2 Intestazione della finestra
- Titolo della barra: **Messaggi** (con l'icona 20×20).
- Riga grande: **«Prisma scrive per te.»** seguito dal sottotitolo maiuscolo **«RUBY PREPARA, TU SPEDISCI»**.
- Nessuna azione a destra (`act` e `right` assenti).

#### 1.3 Colonna di sinistra (elenco delle occasioni) — `.side` larga 380
Dall'alto:
1. Occhiello di gruppo **«DA MANDARE OGGI»** (`.lbl`).
2. Una voce per occasione (`.rub`): avatar 38 (iniziali su sfumatura del cliente), nome in grassetto, sotto il titolo dell'occasione su una riga (troncato con «…»). La voce scelta ha il fondo azzurro.
3. Occhiello **«QUESTA SETTIMANA»**, poi le sue voci.
4. In fondo, fissa, una scheda piatta con il testo: **«Ruby scrive, tu spedisci: niente parte da solo. Ogni messaggio resta nel dossier del cliente.»**

Voci del template (dimostrative):

| Gruppo | Cliente | Titolo dell'occasione | Perché adesso | Oggetto della mail |
|---|---|---|---|---|
| Da mandare oggi | Giulia Rossi | Il riepilogo dell’incontro di oggi | Incontro di stamattina alle 09:30 | Il riepilogo di oggi |
| Da mandare oggi | Marco Bianchi | L’Infortuni famiglia scade il 17 dicembre | Scadenza tra 45 giorni | La polizza Infortuni in scadenza |
| Da mandare oggi | Chiara Marino (non è tra i 5 clienti: `x` nel template) | Gli auguri di compleanno | Domani compie 47 anni | Buon compleanno! |
| Questa settimana | Sofia Romano | Il rinnovo del consenso privacy | Consenso scaduto il 2 settembre | Il rinnovo del consenso |
| Questa settimana | Laura Moretti | I 50 anni e la pensione | A dicembre compie 50 anni | Un buon momento per la pensione |

#### 1.4 Pannello di destra (il messaggio) — `#compo`, `.main.card`
Dall'alto:
1. **Testata**: avatar 46; sopra, piccolo, **«A: {nome} · indirizzo email del dossier»** (canale Mail) oppure **«A: {nome} · numero del dossier»** (canale Messaggi); sotto, il titolo dell'occasione grande (23 pt, grassetto). A destra la pillola azzurra **«Perché adesso: {motivo}»**.
2. **Riga dei controlli**:
   - segmentato del tono: **Cordiale · Formale · Breve** (predefinito Cordiale);
   - segmentato del canale: **Mail · Messaggi** (predefinito Mail);
   - a destra: sfera di Ruby 20×20 che respira + **«Ruby scrive con i dati del dossier»**.
3. Solo con **Mail**: riga **«Oggetto: {oggetto}»** («Oggetto:» in secondario, oggetto in grassetto) con filetto sotto.
4. **Il testo** (`#testoM`): corpo 15,5, interlinea 1,6, a capo conservati (`pre-wrap`), altezza minima 300.
   - Con **Mail** è testo libero su tutta la larghezza, come una mail.
   - Con **Messaggi** diventa una **nuvoletta blu** allineata a destra (fondo accento, testo bianco, angolo in basso a destra più stretto), larga al massimo 620, senza oggetto.
5. **Barra dei pulsanti**, fissa in fondo: **«Apri in Mail»** / **«Apri in Messaggi»** (primario, segue il canale), **«Salva nel dossier»**, **«↻ Riscrivi»**; a destra, in secondario, **«Lo controlli e lo spedisci tu»**.

Testi dei messaggi: il template ha per ogni occasione tre versioni (cordiale, formale, breve). Esempi di registro da rispettare (vanno in `Ruby/Istruzioni/messaggi.md`, non nel codice):
- Cordiale: dà del tu, apre con «Ciao {nome},» (compleanno: «Cara {nome},»), chiude con «A presto,\nDenis» o «Un caro saluto,\nDenis».
- Formale: dà del lei, apre con «Gentile {nome},», chiude con «Cordiali saluti,\nDenis Vicenzoni».
- Breve: una o due frasi, adatto a un SMS, firmato «Denis».
- Il riepilogo dell'incontro usa un elenco puntato «• …;».
- Ogni messaggio finisce con un invito concreto (vederci, una firma, «scrivimi pure»).
Il testo integrale del template è alle righe 852-871 e va copiato come esempio per le istruzioni (`Ruby/Esempi/messaggi.json`), con le cifre sostituite dai segnaposto.

#### 1.5 Avvisi (toast)
- «Apri in Mail» → **«Aperto in Mail, già compilato: lo spedisci tu»**
- «Apri in Messaggi» → **«Aperto in Messaggi: lo spedisci tu»**
- «Salva nel dossier» → **«Salvato nel dossier di {nome}»**

#### 1.6 Stati (il template non li disegna: vanno aggiunti, coerenti col tema)
- **Vuoto** (nessuna occasione oggi né in settimana): colonna con l'occhiello «DA MANDARE OGGI» e la riga secondaria «Niente da mandare oggi»; pannello di destra con il simbolo vuoto (carattere `simboloVuoto`, 34 light) e «Nessun messaggio da preparare. Quando c'è un incontro, una scadenza, un compleanno o un consenso da rinnovare, lo trovi qui.» La scheda in fondo resta.
- **Ruby sta scrivendo** (Qwen genera): al posto del testo, i tre puntini di Ruby (`.typing`, già nel tema) per il primo pezzo, poi il testo che arriva a pezzi; i pulsanti «Apri in…» e «Salva nel dossier» restano spenti finché il testo non è completo.
- **Qwen non pronto**: Prisma mostra la **bozza di Prisma** (frasi fisse con le cifre esatte) e sopra il testo una riga secondaria con la sfera ferma: «Ruby non è pronta: questa è la bozza di Prisma, con i dati del dossier.» I pulsanti funzionano. È la stessa regola di `CommentoRuby`.
- **Qwen ha cambiato una cifra** (controllo `numeriConservati` fallito): resta la bozza, con la riga «Ruby ha cambiato una cifra: tengo la bozza di Prisma.»
- **Manca il recapito**: con Mail senza `email` o con Messaggi senza `telefono`, la testata dice «A: {nome} · manca l'indirizzo email nel dossier» (o «manca il numero nel dossier»), il pulsante primario diventa «Aggiungi nel dossier» e porta alla scheda anagrafica.
- **Senza consenso commerciale** (solo per i messaggi che propongono qualcosa, §6): pillola arancio «Senza consenso commerciale» accanto a «Perché adesso» e il pulsante primario chiede conferma.
- **Già mandato**: un'occasione salvata nel dossier o aperta in Mail/Messaggi esce dall'elenco il giorno dopo; finché resta, la voce mostra una spunta verde e «Preparato alle 10:42».

---

### 2. Misure e stile

Area di lavoro: `#wc` left 12, right 12, top 92, bottom 12 dentro la finestra. A 1480×940 il contenuto misura 1401×661 (colonna 380 + gioco 16 + pannello ~1005).

#### 2.1 Colonna `.side`
- `position:absolute; left:0; top:0; bottom:0; width:380px`, `border-radius:20px`, fondo `--panel` (chiaro `rgba(255,255,255,.72)`, scuro `rgba(255,255,255,.05)`), bordo 1 `--sep` (chiaro `rgba(0,0,0,.08)`, scuro `rgba(255,255,255,.09)`), `padding:14px 12px`, `overflow:hidden`.
  Prisma: `Tema.Apple.Superficie.pannello`, `Tema.Apple.Colore.pannello`, `Colore.separatore`.
- Occhiello `.lbl`: 12 px, semibold 600, maiuscolo, tracking .6, `--ink2`. Margini: il primo `2px 4px 8px`, i successivi `14px 4px 8px`. Prisma: `Carattere.etichetta`.
- Voce `.rub`: flex, gap 10, allineata al centro, **padding 10** (il template sovrascrive i 9×8 della base), raggio 14, `margin-bottom:2px`, `transition: background .25s`. Altezza misurata 59.
  - hover: fondo `--chip` (chiaro `rgba(0,0,0,.05)`, scuro `rgba(255,255,255,.08)`) → `Colore.chip`;
  - scelta (`.on`): `rgba(0,122,255,.13)` → `Colore.selezioneVoce`;
  - avatar 38, iniziali 13 px (38×0,34) semibold bianco, cerchio, sfumatura del cliente → `AvatarCliente`;
  - nome `b`: 14 px bold → `Carattere.titoloVoce` (14 semibold; nel template è bold 700, da verificare);
  - titolo `small`: 12 px `--ink2`, una riga, ellissi, **max-width 260** (la base dice 200).
- Scheda in fondo: `.card` con `position:absolute; left:12; right:12; bottom:12; padding:12px 14px; box-shadow:none`, raggio 22, fondo `--card` (chiaro `rgba(255,255,255,.82)`, scuro `rgba(255,255,255,.07)`), bordo `--sep`. Testo `.k` 12,5 px `--ink2`, interlinea 1,45. Prisma: `Superficie.cardPiatta`, `Carattere.secondario`.

#### 2.2 Pannello `#compo`
- `.main.card`: `left:396px` (380 + 16 di gioco), `top:0; bottom:0; right:0`, `padding:22px 26px` (= `Misura.Padding.cardPortafoglio`), `box-shadow:none`, raggio 22, fondo `--card`, bordo `--sep`, `overflow:hidden`.
- Testata `.row`: gap 12; avatar 46 (iniziali 16 px).
  - «A: …»: `.k` 12,5 px `--ink2`.
  - Titolo: `--fontd` (SF Pro Display), **23 px, bold 700, tracking −0,4** → nuovo `Carattere.titoloMessaggio` (non c'è un 23: i vicini sono `titoloGruppo` 22 e `titoloMossa` 25).
  - Pillola «Perché adesso»: `margin-left:auto`, 12 px semibold 600, `padding:5px 11px`, raggio 99, fondo `rgba(0,122,255,.1)`, testo `--accent` `#007AFF` (uguale in chiaro e scuro). Nuovo `Colore.perchéAdesso` = accento al 10% (vicino a `selezioneVoce` 13%: decidere se riusarlo).
- Riga controlli: gap 10, `margin:18px 0 14px`.
  - `.seg`: inline-flex, fondo `--chip`, raggio 99, padding 3; voce 13 px semibold, `padding:6px 14px` (= `Misura.Padding.voceSegmentato`), colore `--ink2`, scelta `--ink`; pillola `i` fondo `--cardE` (chiaro `#fff`, scuro `rgb(40,54,66)`), ombra `0 1px 4px rgba(0,0,0,.14)`. Prisma: `SegmentatoPillola`.
  - Nota Ruby: `.k`, sfera 20×20 `.sfera.viva` → `SferaRuby` (RubyApple.swift).
- Riga oggetto: 14 px, `padding:10px 0`, filetto basso 1 `--sep`; «Oggetto:» in `.k`, oggetto `b`.
- Testo `#testoM`: 15,5 px, interlinea 1,6, `white-space:pre-wrap`, `margin-top:14px`, `min-height:300px`. Nuovo `Carattere.testoMessaggio` (15,5 regular, interlinea 1,6).
  - Nuvoletta (Messaggi): fondo `--accent`, testo `#fff`, `padding:14px 18px`, **raggio 22/22/6/22** (alto-sinistra, alto-destra, basso-destra, basso-sinistra: l'angolo stretto è in basso a destra), `max-width:620px`, `margin-left:auto`, `min-height:0`. È la stessa forma della bolla dell'utente nella chat di Ruby (`.msg.me`, raggio 20/20/6/20): proporre una sola forma `Tema.Apple.Raggio.nuvoletta` con due misure, o tenere 22 come dice il template.
- Barra pulsanti: `position:absolute; left:26; right:26; bottom:22`, gap 8.
  - `.btn.big`: raggio 99, `padding:10px 18px`, 13,5 px semibold, fondo `--cardE`, bordo `--sep`; primario: fondo `--accent`, testo bianco, senza bordo. Prisma: `StilePulsanteApple` varianti primaria/secondaria grande.
  - Nota a destra: `.k`.

#### 2.3 Avviso
`#toast`: in alto al centro (top 44), fondo `rgba(15,36,51,.92)`, testo bianco 13 px, `padding:9px 16px`, raggio 99; entra con `translateY(-20px)→0` e opacità in .45 s `--spring`, resta 2,4 s. Prisma: `StatoShell.mostraAvviso(_:)`.

#### 2.4 Icona
Sorgente SVG 512×512 nel template (riga 1131, «Messaggi»): busta `#C8683A` su vetro arancio, con pallino. Va salvata in `Design/Icone/` e convertita in PNG con `genera-icone.js` come le altre (Giro 1).

---

### 3. Movimento

Tutte le curve esistono già in `Tema.Apple.Moto.Curva`: `--out` = `uscita` (.22,1,.36,1), `--spring` = `molla` (.34,1.45,.64,1).

1. **Apertura dell'app** (`monta`): il contenuto entra in dissolvenza 200 ms; poi la **cascata** `entrata(wc, 140)` sugli elementi `.st`: da `translateY(18) scale(.985) blur(6)` a fermo, **720 ms**, curva `uscita`, ritardo **140 + i×48 ms**. Elementi `.st` in ordine: le 5 voci della colonna, poi testata, riga controlli, riga oggetto, testo. Prisma: `EntrataApple` con `Moto.Entrata.durata 0.72`, `passo 0.048`, `baseFinestra 0.14`. La scheda in fondo alla colonna e la barra dei pulsanti non entrano in cascata (compaiono con la finestra).
2. **Cambio di occasione** (clic su una voce): il pannello esce in **130 ms** (opacità 1→0, `translateX(10px)`, curva lineare predefinita), poi si ridisegna ed entra con la cascata `entrata(c)` (base 0, passo 48, 720 ms). La voce scelta cambia fondo in .25 s. Nuovo `Moto.CambioMessaggio.uscita = 0.13`, spostamento 10.
3. **Segmentati**: la pillola scorre su `left`/`width` in **0,5 s `molla`**; il colore del testo cambia in 0,3 s (già in `SegmentatoPillola`).
4. **Il testo compare parola per parola** (`scriviM`): il testo si divide in parole e spazi (`split(/(\s+)/)`: ogni parola e ogni spazio sono un pezzo), e ogni **22 ms** si aggiungono **2 pezzi** (cioè circa una parola). Parte **250 ms** dopo il montaggio del pannello; riparte da capo a ogni cambio di tono, di canale e a ogni «Riscrivi». Durata indicativa: riepilogo di Giulia (~110 parole) ≈ 2,4 s.
   - Nell'app: **niente Timer**. Quando il testo arriva da Qwen in flusso (`FornitoreModello.flusso`, `AsyncThrowingStream<PezzoModello>`), si mostra man mano che arriva: la comparsa «parola per parola» è il flusso stesso. Quando il testo è già pronto (bozza, tono già generato, ritorno su una voce), la comparsa si fa con un `Animatable` che rivela le parole (nuovo `TestoCheSiScrive`, progresso 0→1 con durata = parole × 0,022 s, curva lineare), come i numeri che si contano.
5. **Sfera di Ruby**: `respira` 4 s ease-in-out infinita (scala 1,045 a metà) e il riflesso `gira` 6 s lineare. Già in `SferaRuby`.
6. **Pulsanti**: premuti `scale(.95)` in .25 s `molla`; hover `brightness(.97)`.
7. **Cambio di canale**: il pannello si ridisegna **senza cascata** (cambia di colpo) e il testo riparte da capo dopo 250 ms. Proposta per l'app: passaggio morbido mail ↔ nuvoletta con `matchedGeometryEffect` sul testo (durata `Moto.Entrata.durata`, curva `molla`), da approvare.

**Riduci movimento** (`ridotto` nel template, `\.prismaCalmo` in Prisma): la cascata dura 1 ms senza ritardi; il testo compare **subito intero** (`if(ridotto){t.textContent=testo;return;}`). In Prisma: dissolvenza unica di 0,15 s, niente uscita laterale, niente inclinazioni. La sfera resta ferma.
**Istantanee** (`\.modoIstantanea` + `\.prismaStatoFinale`): testo completo, nessun cursore né puntini, pillole al loro posto.

---

### 4. Interazioni

- **Clic su una voce** della colonna: sceglie l'occasione, il pannello cambia (§3.2). Tono e canale **restano quelli scelti** (sono globali nel template, non per voce).
- **Tono** (Cordiale/Formale/Breve): riscrive il testo nel nuovo tono, da capo, parola per parola. Nell'app: la prima volta Qwen genera; le versioni già generate per quella occasione restano in memoria (non si rigenerano).
- **Canale** (Mail/Messaggi): cambia la testata («indirizzo email» / «numero»), mostra o nasconde l'oggetto, trasforma il testo in nuvoletta, cambia il pulsante primario. Il testo resta lo stesso tono (nel template non si accorcia: un SMS lungo è possibile; suggerire «Breve» quando si sceglie Messaggi è un'idea da approvare).
- **Apri in Mail**: apre Mail con destinatario (email del dossier), oggetto e corpo già compilati; **non spedisce**. Avviso «Aperto in Mail, già compilato: lo spedisci tu».
- **Apri in Messaggi**: apre Messaggi con il numero del dossier e il testo; **non spedisce**. Avviso «Aperto in Messaggi: lo spedisci tu».
- **Salva nel dossier**: salva il testo (con data, canale, tono, motivo) nel dossier del cliente; avviso «Salvato nel dossier di {nome}».
- **↻ Riscrivi**: rigenera il testo nello stesso tono (Qwen con un nuovo seme; se Qwen non c'è, la bozza riappare uguale).
- **Testo modificabile**: nel template non lo è. Nell'app conviene che il consulente possa correggere il testo prima di aprirlo in Mail (campo di testo che si sblocca a fine scrittura). Da approvare.
- **Hover** sulle voci: fondo `chip`. Le schede di questa app **non si inclinano** (nessun `.tilt`).
- **Tastiera** (proposta, il template non ne ha): ↑/↓ cambiano voce; ⌘1/⌘2/⌘3 i toni; ⌘↩ «Apri in…»; ⌘S «Salva nel dossier»; ⌘R «Riscrivi». Esc chiude la finestra come le altre app.
- Il clic su «Prepara un messaggio» (Mercato), «Messaggio» (Prova del fuoco), `#fMsg` (Studio) apre Messaggi già sul cliente e sul motivo.

---

### 5. Mappa verso Prisma

#### 5.1 Cosa c'è già (verificato con grep in `Sources/Prisma`)

| Serve per | Esiste | Dove |
|---|---|---|
| Recapiti | `Cliente.email`, `Cliente.telefono` | `Dati/Modelli.swift` r. 36-37 |
| Compleanni | `Cliente.dataNascita`, `Cliente.eta`; `MotoreNotifiche.prossimoCompleanno(_:da:cal:)` (29 febbraio compreso); promemoria `compleanni` | `Dati/Modelli.swift` r. 43; `Shell/Notifiche.swift` r. 328, 588 |
| Riepilogo incontro | `Incontro` (`appunti`, `decisioni`, `prossimaAttivita`, `prossimoIncontro`, `stato .concluso`, `data`) | `Dati/Incontro.swift` |
| Scadenze delle polizze | `Posizione.scadenza`, `scadeEntro(giorni:)` (r. 313), promemoria scadenze | `Dati/Posizione.swift`, `Shell/Notifiche.swift` |
| Occasioni | `Occasione`, `TipoOccasione` (fine blocco, senza penali, pensione vicina, maggiorenne, fine carico, limiti TCM/LTC, fisco…), `MotoreOccasioni.calcola(clienti:…)`, `ImpostazioniOccasioni.anticipoGiorni` | `Dati/Occasione.swift`, `Motori/MotoreOccasioni.swift` |
| Consensi / In regola | `Consensi` (`privacy`, `dataPrivacy`, `marketing`, `dataMarketing`), `RegoleConformita` (`mesiCommerciale` 24, `informativaAggiornataIl`), `MotoreConformita.calcola` → `VoceConformita` (`.privacy`, `.commerciale`, stati `scaduta/entro30/entro60`) | `Dati/Modelli.swift` r. 317; `Dati/Conformita.swift`; `Motori/MotoreConformita.swift`; `Shell/InRegolaCliente.swift` |
| Riesami | `MotoreRiesame.dovuti(...)` → `RiesameDovuto` (`dovutoDal`, `scaduto`) | `Motori/MotoreRiesame.swift` r. 94-125 |
| Gruppi «Oggi / Questa settimana» | `VoceDaFare.Gruppo` (`oggi`, `settimana`, `mese`, `avanti`) e `MotoreDaFare.gruppo(_:oggi:)` | `Motori/MotoreDaFare.swift` r. 28, 301 |
| Qwen | `FornitoreModello` (`flusso`, `verifica`), `FornitoriRuby.crea`, `MotoreGenerativo.genera(istruzioni:richiesta:)`, `IstruzioniRuby.testo(_:)` che legge `Ruby/Istruzioni/*.md` | `Ruby/FornitoreModello.swift`, `Ruby/MotoriRuby.swift` |
| Modello da copiare: bozza di Prisma + riscrittura di Qwen + controllo delle cifre | `CommentoRuby.bozza`, `CommentoRuby.scrivi`, `CommentoRuby.numeriConservati`, `CommentoRuby.cifre` | `Ruby/CommentoRuby.swift` |
| Firma | `Impostazioni.nomeUtente = "Denis"` | `Dati/DatiPrisma.swift` r. 141 |
| Note del dossier | `Nota` (`clienteId`, `titolo`, `testo`, `creataIl`) e `DatiPrisma.note` | `Dati/Nota.swift` |
| Avvisi | `StatoShell.mostraAvviso(_:)` | `Shell/StatoShell.swift` r. 3010 |
| Componenti | `SegmentatoPillola`, `StilePulsanteApple`, `AvatarCliente`, `SferaRuby`, `EntrataApple`, `Tema.Apple.Superficie.pannello/cardPiatta`, `Colore.selezioneVoce/chip/separatore/accento`, `Carattere.etichetta/titoloVoce/secondario` | `DesignSystem/Apple/*`, `DesignSystem/Componenti.swift` r. 698 |
| App e dock | `AppPrisma` (manca `.messaggi`), `AppPrisma.delDock`, `StatoShell.apri(_:)` | `Shell/AppPrisma.swift` |

#### 5.2 Cosa manca

1. **`AppPrisma.messaggi`** (titolo «Messaggi», nel dock dopo `.agenda`, icona PNG «Messaggi»). Su iPhone e iPad: app a sé, gerarchia di `Design/iphone.html` (in alto l'occasione principale, sotto il testo, il resto a un tocco).
2. **Motore delle occasioni di contatto** — nuovo `Motori/MotoreMessaggi.swift`, senza intelligenza artificiale, solo regole:
   ```swift
   struct OccasioneMessaggio: Identifiable, Hashable {
       enum Tipo: String, Codable, CaseIterable { case riepilogoIncontro, scadenzaPolizza, compleanno, consenso, compleannoTondo, riesame, occasione, mercato, parcella }
       let id: String              // "\(tipo)-\(clienteId)-\(soggetto)-aaaammgg", stabile
       let tipo: Tipo
       let clienteId: String
       let gruppo: VoceDaFare.Gruppo  // .oggi / .settimana (mese e avanti non entrano)
       let titolo: String           // «L’Infortuni famiglia scade il 17 dicembre»
       let perche: String           // «Scadenza tra 45 giorni»
       let oggetto: String          // «La polizza Infortuni in scadenza»
       let fatti: [FattoMessaggio]  // le cifre e i fatti esatti che Qwen può usare (etichetta, valore già formattato)
       let canale: Canale?          // Alleanza / indipendente della posizione da cui nasce (etichetta nel pannello)
       let commerciale: Bool        // propone un prodotto o un incontro di vendita → serve il consenso commerciale
       let origine: Origine         // .incontro(id) .posizione(id) .voceConformita(tipo) .occasione(id) .riesame
   }
   enum MotoreMessaggi {
       static func calcola(dati: DatiPrisma, oggi: Date, cal: Calendar) -> [OccasioneMessaggio]
       static func bozza(_ o: OccasioneMessaggio, tono: TonoMessaggio, canale: CanaleMessaggio, cliente: Cliente, firma: String) -> TestoMessaggio
   }
   ```
   Regole proposte (tutte da confermare, §6):
   - **riepilogoIncontro**: `Incontro.stato == .concluso` con `data` oggi (o ieri dopo le 18) e nessun messaggio salvato per quell'incontro → gruppo `oggi`. Perché: «Incontro di stamattina alle 09:30» / «di oggi pomeriggio» / «di ieri». Fatti: le `decisioni`, la `prossimaAttivita` e le cifre che `MotoreRiesame.calcola` e i motori delle aree danno per i temi dell'incontro (obiettivo casa, caso morte mancante, fondo pensione…). Il testo libero degli appunti **non** va nel messaggio: Qwen lo legge solo per capire, i numeri vengono dai motori.
   - **scadenzaPolizza**: posizione in essere con `scadenza` entro `ImpostazioniOccasioni.anticipoGiorni` (o una soglia propria, es. 45 giorni) → gruppo `oggi` se è il primo giorno in cui entra nella soglia, altrimenti `settimana`. Perché: «Scadenza tra 45 giorni». Fatti: nome della posizione, data, eventuali scoperture della famiglia da `MotoreProtezioneFamiglia` (nel template: «una protezione anche per Elena»).
   - **compleanno**: `prossimoCompleanno` oggi o domani → `oggi` («Domani compie 47 anni» / «Oggi compie 47 anni»). Mai commerciale.
   - **compleannoTondo**: compleanno a 30/40/50/60 anni entro 60 giorni, con un obiettivo o un'area legata (pensione, successione) → `settimana`. «A dicembre compie 50 anni». Commerciale.
   - **consenso**: `VoceConformita` `.privacy` o `.commerciale` con stato `.scaduta` o `.entro30` → `settimana` («Consenso scaduto il 2 settembre»). Nota: in Prisma il consenso al trattamento **non scade**; scade il consenso commerciale (`mesiCommerciale`) o va rifirmata l'informativa aggiornata (`informativaAggiornataIl`). Il titolo deve dire quale.
   - **riesame**: `RiesameDovuto.scaduto` → `settimana` («Un anno dall'ultimo incontro»). Commerciale.
   - **occasione**: le `Occasione` di `MotoreOccasioni` con `importanza == .alta` nei prossimi 7 giorni (fine blocco riscatto, senza penali, maggiorenne, limite età TCM…) → `settimana`. Commerciale.
   - **mercato** / **parcella**: arrivano da Mercato e Studio (parti 03 e 01): non entrano nell'elenco da sole, ma aprono Messaggi con un'occasione «su richiesta».
   - Ordine: gruppo, poi tipo (riepilogo, scadenza, compleanno, consenso, compleanno tondo, riesame, occasione), poi data. Massimo 8 per gruppo (proposta).
   - Un'occasione **esce** quando: il messaggio è salvato o aperto (fino al giorno dopo resta con la spunta), il consulente la scarta («Non serve», menu contestuale: proposta), o la condizione non vale più.
3. **Ruby che scrive** — nuovo `Ruby/MessaggiRuby.swift`, sul modello di `CommentoRuby`:
   - `static func scrivi(_ o: OccasioneMessaggio, tono:, canale:, bozza: TestoMessaggio, fornitore: FornitoreModello) -> AsyncThrowingStream<String, Error>`: manda istruzioni fisse (`Ruby/Istruzioni/messaggi.md`) e, nell'ultimo messaggio, la scheda «FATTI (usa solo questi numeri)», il tono, il canale, la lunghezza massima e la bozza.
   - A fine flusso: `CommentoRuby.numeriConservati(bozza:testo:)` contro i fatti; se fallisce si torna alla bozza (§1.6). Togliere `**`, titoli e firme diverse da quella del consulente.
   - Lunghezza: cordiale/formale ≤ 140 parole; breve ≤ 320 caratteri (un SMS lungo). Oggetto ≤ 60 caratteri, sempre da Prisma (non da Qwen).
   - Modalità **lavoro** (numeri solo da Prisma). Niente nomi di altri clienti nella scheda.
   - Il budget di 8.192 token basta: scheda corta + bozza.
4. **Nuovi file del repository Ruby/**:
   - `Ruby/Istruzioni/messaggi.md`: ruolo («scrivi a nome di Denis un messaggio a un suo cliente»), tre toni (tu/lei/breve), regole (niente cifre fuori dai fatti, niente promesse di rendimento, niente nomi di prodotti non nei fatti, una sola richiesta concreta alla fine, chiusura e firma fisse), differenza mail/SMS.
   - `Ruby/Esempi/messaggi.json`: i 5 esempi del template nelle tre versioni, con le cifre al posto giusto.
   - Aggiornare `Ruby/Istruzioni/README.md` con la voce `messaggi.md`.
5. **Aprire Mail e Messaggi** senza spedire — nuovo `Shell/SpedizioneMessaggi.swift`:
   - Mail: `NSSharingService(named: .composeEmail)` con `recipients = [email]`, `subject`, e il corpo come elemento condiviso; ripiego `mailto:` con `NSWorkspace.shared.open` (destinatario, `subject`, `body` codificati in percentuale).
   - Messaggi: `NSSharingService(named: .composeMessage)` con `recipients = [telefono]` e il testo; ripiego `sms:{numero}&body=…` (su macOS il corpo può non passare: allora copiare il testo negli appunti e dirlo nell'avviso: «Aperto in Messaggi: il testo è negli appunti, lo incolli e lo spedisci tu»).
   - iPhone/iPad: `MFMailComposeViewController` e `MFMessageComposeViewController` (MessageUI, del sistema: non è una dipendenza esterna).
   - Il numero si normalizza (spazi, prefisso +39 se manca: da confermare).
   - Nessun invio automatico, mai: è la regola «niente parte da solo».
6. **Salvare nel dossier** — archivio nuovo (versione 26, `DatiPrisma.versioneAttuale` passa da 25 a 26):
   ```swift
   struct MessaggioCliente: Identifiable, Codable, Hashable {   // Dati/MessaggioCliente.swift
       var id = "messaggio-\(UUID().uuidString.prefix(8).lowercased())"
       var clienteId: String
       var occasioneId: String          // OccasioneMessaggio.id: serve a non riproporla
       var tipo: String                 // OccasioneMessaggio.Tipo.rawValue (tollerante)
       var oggetto: String?
       var testo: String
       var tono: TonoMessaggio          // cordiale, formale, breve
       var canale: CanaleMessaggio      // mail, messaggi
       var scrittoDa: String            // "Qwen" o "Prisma" (bozza)
       var stato: Stato                 // salvato, apertoInMail, apertoInMessaggi
       var creatoIl: Date
       var apertoIl: Date?
   }
   ```
   - `DatiPrisma.messaggi: [MessaggioCliente] = []`, letto con `ElencoTollerante` come `fotografie`.
   - `Impostazioni.messaggi = ImpostazioniMessaggi()` con: `tonoPredefinito` (cordiale), `canalePredefinito` (mail), `firmaCordiale` («Denis»), `firmaFormale` («Denis Vicenzoni»), `tiPredefiniti: Bool` (dare del tu), `tipiSpenti: [String]`, `giorniScadenza` (45), `compleanniTondi: [Int]` ([30, 40, 50, 60]).
   - Per cliente, facoltativo: `Cliente.registro: RegistroCliente?` (`.tu` / `.lei`), così il tono «Cordiale» dà del lei a chi lo vuole. Nome proposto del campo: `registro`.
   - Nel dossier: i messaggi compaiono nella scheda Documenti o nella cronologia «Nel tempo» del cliente (dove? §6). `Nota` non basta: serve sapere tipo, canale e occasione.
   - **Backup**: `MessaggioCliente` entra nel backup (è nell'archivio). Aggiornare `ProvaBackup` (`Prisma --prova-backup`) con un messaggio salvato e il ripristino.
7. **Stato dell'app** — nuovo `Shell/StatoMessaggi.swift` (`@MainActor final class`): occasioni calcolate (con cache come `CacheMotoriPosizioni`), selezione, tono, canale, testi generati per (occasione, tono) in memoria e liberati alla chiusura della finestra (8 GB di RAM), compito di generazione annullabile al cambio di voce.
8. **Vista** — nuovo `Shell/AppMessaggi.swift` (colonna + pannello) e `DesignSystem/Apple/Tema.Apple+Messaggi.swift` con le misure di §2: `larghezzaColonna 380`, `gioco 16`, `avatarVoce 38`, `avatarTestata 46`, `paddingVoce 10`, `raggioVoce 14`, `larghezzaTitoloVoce 260`, `paddingPannello 22×26`, `margineControlli 18/14`, `altezzaMinimaTesto 300`, `larghezzaNuvoletta 620`, `paddingNuvoletta 14×18`, raggi nuvoletta 22/6, `pillolaPerche` 5×11, `Carattere.titoloMessaggio` 23 bold −0,4, `Carattere.testoMessaggio` 15,5 interlinea 1,6, `Moto.ParolaPerParola.passo 0.022` (2 pezzi), `ritardo 0.25`, `Moto.CambioMessaggio.uscita 0.13` spostamento 10.
9. **Componente** `TestoCheSiScrive` (`DesignSystem/Apple/`), `Animatable` su `progresso`, che rivela le parole senza Timer; rispetta `\.prismaCalmo` e `\.prismaStatoFinale`. Riusabile per Ruby.
10. **Collegamenti dalle altre app**: `StatoShell.apri(.messaggi)` con un'occasione su richiesta: `StatoShell.preparaMessaggio(clienteId:, tipo:, origine:)`. Chiamato da Agenda (occasioni e compleanni del giorno), dal dossier (In regola: «Prepara il messaggio» accanto a un consenso scaduto), dall'incontro concluso («Manda il riepilogo»), da Mercato, Prova del fuoco e Studio.
11. **Scrivania e notifiche** (proposta): una riga in «Da fare» / `MotoreDaFare` con tipo nuovo `.messaggio` («3 messaggi da mandare oggi»), e la mossa del giorno può puntare a un messaggio. Da decidere per non duplicare le occasioni già nel nastro.

#### 5.3 Prove di calcolo nuove
`Motori/ProvaCalcoliMessaggi.swift` (chiamata da `ProvaCalcoli.esegui` come le altre, numerazione «M»):
- M1 riepilogo: incontro concluso oggi alle 09:30 → un'occasione `oggi` con «Incontro di stamattina alle 09:30»; un messaggio salvato per quell'incontro la toglie.
- M2 scadenza: polizza che scade tra 45 giorni → «Scadenza tra 45 giorni», gruppo corretto; scaduta o non in essere → niente.
- M3 compleanno: nato il 3 novembre → «Oggi compie …»; il 4 → «Domani compie 47 anni»; 29 febbraio in anno non bisestile → il 28.
- M4 compleanno tondo: 50 anni a dicembre → «A dicembre compie 50 anni» nella settimana giusta; 51 anni → niente.
- M5 consenso: commerciale dato 25 mesi fa con `mesiCommerciale 24` → occasione con la data giusta; `informativaAggiornataIl` dopo la firma → «informativa da rifirmare»; privacy senza informativa aggiornata → niente (non scade).
- M6 riesame: `RiesameDovuto.scaduto` → occasione; con un appuntamento pianificato → niente.
- M7 ordine e gruppi: oggi prima di settimana, tipi nell'ordine, massimo per gruppo, id stabili tra due calcoli.
- M8 consenso commerciale: occasione `commerciale` con `marketing == false` → segnata (o esclusa, secondo la scelta dell'utente).
- M9 bozza: per ogni tipo e tono la bozza contiene solo cifre dei fatti (`CommentoRuby.cifre(bozza) ⊆ cifre(fatti)`), apre con «Ciao»/«Gentile»/nome secondo il tono e il registro, chiude con la firma delle impostazioni, breve ≤ 320 caratteri.
- M10 controllo di Qwen: un testo con una cifra in più o «55 mila» → si tiene la bozza (riuso di `numeriConservati`).
- M11 indirizzi: `mailto:` e `sms:` codificati bene (accenti, a capo, «&», «€»).
Prova di archivio: in `ProvaBackup` un `MessaggioCliente` salvato, backup, ripristino, uguaglianza; un archivio versione 25 si apre con `messaggi = []`.

---

### 6. Dati che l'utente deve dare (mai inventarli)

1. **Quali occasioni** vuole in Messaggi e **con quanto anticipo**: riepilogo incontro (lo stesso giorno?), scadenze (45 giorni come nel template, o l'anticipo delle Occasioni, 30?), compleanni (il giorno prima e il giorno stesso?), compleanni tondi (quali età), consensi, riesami, occasioni dei contratti.
2. **Firme e saluti**: «Denis» e «Denis Vicenzoni» vanno bene? Una firma diversa per Alleanza (con ruolo e agenzia) e per l'indipendente («Denis Vicenzoni · Consulenza finanziaria»)? Recapiti in calce?
3. **Tu o lei** per ciascun cliente (o una regola: tu per tutti tranne chi lo segna).
4. **Testi base** che vuole usare (o approvazione di quelli del template) per ogni tipo e tono.
5. **Consenso commerciale**: per auguri, scadenze e riepiloghi serve? Per le proposte (pensione, riesame, occasioni) si deve bloccare il messaggio senza consenso o solo avvisare?
6. **Canale per cliente**: chi preferisce la mail e chi i messaggi; WhatsApp no (non è Messaggi di Apple)?
7. **Mail di Alleanza**: per i clienti Alleanza deve usare l'indirizzo e il programma di posta aziendali (non Mail del Mac)? Ci sono regole di Alleanza sulle comunicazioni ai clienti (testi approvati, divieti)?
8. **Email e telefono** dei clienti veri (molti dossier di prova li hanno vuoti o fittizi).
9. **Chi non è cliente** (Chiara Marino nel template): Prisma deve scrivere anche a contatti senza dossier (potenziali clienti, familiari)?
10. Dove vuole **ritrovare i messaggi salvati** nel dossier (Documenti, Nel tempo, Note).

Finché mancano:
- I 5 clienti di prova e i 30 fittizi danno occasioni calcolate dai motori con i loro dati di prova. Il pannello mostra in alto la riga secondaria **«Dati di prova: testi e regole da confermare in Impostazioni › Messaggi»**.
- Tono «Cordiale» = tu, firma = `Impostazioni.nomeUtente`, formale = nome e cognome del profilo.
- Senza email o telefono: stato «Manca il recapito» (§1.6), mai un indirizzo inventato.
- Le occasioni commerciali senza consenso mostrano la pillola arancio ma non si bloccano.

---

### 7. Istantanee da aggiungere

Numerazione libera dopo le 480 di Ruby: proposta **490-…** (verificare che il Giro 1 non la usi già per Studio/Mercato).

| Nome | Cosa mostra |
|---|---|
| `490-messaggi-apple` / `490-messaggi-apple-scuro` | Prima occasione (riepilogo dell'incontro di Giulia), Cordiale, Mail, testo completo: come `chiaro-11`/`scuro-11` |
| `491-messaggi-sms` / `491-messaggi-sms-scuro` | Canale Messaggi, tono Breve: nuvoletta blu, pulsante «Apri in Messaggi» |
| `492-messaggi-formale` | Scadenza di Marco, tono Formale, Mail con oggetto |
| `493-messaggi-consenso` | Consenso di Sofia (gruppo «Questa settimana» scelto) |
| `494-messaggi-ruby-non-pronta` | Bozza di Prisma con la riga «Ruby non è pronta…» |
| `495-messaggi-recapito-mancante` | Testata «manca l'indirizzo email nel dossier», pulsante «Aggiungi nel dossier» |
| `496-messaggi-vuoto` / `496-messaggi-vuoto-scuro` | Nessuna occasione |
| `497-messaggi-iphone` / `497-messaggi-iphone-scuro` | iPhone: occasione principale in alto, testo, controlli a un tocco |
| `498-messaggi-ipad` | iPad, colonna e pannello |

Aggiornare anche la vetrina (`VetrinaApple`, «400-vetrina-apple») con la pillola «Perché adesso», la nuvoletta e `TestoCheSiScrive` nello stato finale, e la pagina online delle anteprime.

---

## 6. Posizioni › La prova del fuoco

*Parte 10 · titolo della bozza: «Orizzonte · 10 · La prova del fuoco (Posizioni)»*

Fonte: `Design/template-novita.html`, righe 942-978 (`vistaP`, `FUOCO`, `SCEN`, `impatto`, `APPS.posizioni`,
`fuocoHTML`, `fv`, `montaFuoco`, `aggR`, `ricalcola`) e voce 7 del pannello Novità (`NOV[6]`, riga 737).
CSS usato: righe 17-22 (token), 32-49 (`.row`, `.lbl`, `.k`, `.v`, `.h2`, `.btn`, `.av`, `.seg`, `.card`),
124-126 (`input[type=range]`), 191-192 (`.chip`, la sola classe nuova di questa parte).
Per ciò che qui non è detto vale `Design/template-apple-specifica.md` e la parte comune `00-comune.md`
(cambio di vista con `rimonta`, §3.4; segmenti della testata di Posizioni, §1.7 punto 7).
Le cifre del template sono dimostrative: nell'app le danno i motori.

Riferimenti visivi (1480×940):
- `orizzonte/chiaro-16-la-prova-del-fuoco.png`, `orizzonte/scuro-16-la-prova-del-fuoco.png`: scenario «Mercati −25%», stato finale dopo il riordino;
- scattate per questa parte con Playwright (`/tmp/claude-0/-home-user-Prisma/54b2dccf-1119-56ac-8826-0b9e597d1473/scratchpad/fuoco/`): `tassi.png`, `infl.png`, `c2008.png`, `c2020.png`. In `c2008.png` si vede la card senza cursore (più bassa) e la chip «Come nel 2008» sotto il puntatore, sollevata.

---

### 1. Cosa si vede

#### 1.1 Da dove si apre

- Voce 7 del pannello Novità: **«La prova del fuoco»** · «Uno scenario, tutto il portafoglio ricalcolato». Porta a Posizioni con `vistaP='fuoco'`.
- Testata di Posizioni, a destra: segmenti **«Portafoglio · Prova del fuoco»** e il pulsante **«◎ Inquadra con l’iPhone»** (parte 09). Il passaggio fra le due viste usa `rimonta` (00-comune §3.4).
- Titolo della testata: **«Il portafoglio.»**; occhiello **«35 clienti · aggiornato adesso»** (in maiuscoletto dallo stile dell'occhiello). Il numero dei clienti viene dall'archivio.

#### 1.2 Struttura della schermata

Dall'alto in basso, nel contenuto della finestra:

```
┌ card ───────────────────────────────────────────────────────────────────────────────────────────┐
│ LA PROVA DEL FUOCO · TUTTO IL PORTAFOGLIO (rosso)                │ 3                 −193.387 € │
│ [Mercati −25%] [Tassi +2 punti] [Inflazione al 5%] [Come nel 2008] [Come nel 2020]               │
│ Ribasso delle azioni  ───────────●──────────  −25%               │ clienti scendono  di patrimonio,│
│                                                                   │ di più di 10 …    su tutto il … │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
Chi chiamare, in ordine   la barra chiara è l’obiettivo oggi, quella piena dopo lo scenario
┌ riga ─────────────────────────────────────────────────────────────────────────────────────────┐
│ (EF) Elisa Ferrara       ████████████████░░░░░ ─────────────   dopo 74%   −17.232 € [Chiama] [Messaggio] │
│      Capitale in scadenza                                      oggi 90%                        │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
… (una riga per cliente; la lista scorre)
```

**A. Card dello scenario** (`.card.st`, una sola riga flessibile, tre colonne separate da un filo verticale):

1. Colonna sinistra (si allarga):
   - etichetta **«La prova del fuoco · tutto il portafoglio»** in rosso (`.lbl`, maiuscolo);
   - cinque chip, in quest'ordine, testi esatti:
     **«Mercati −25%»** · **«Tassi +2 punti»** · **«Inflazione al 5%»** · **«Come nel 2008»** · **«Come nel 2020»**.
     La chip scelta ha il fondo rosso e il testo bianco. All'apertura è scelta «Mercati −25%».
     Il testo delle chip **non** segue il cursore: resta «Mercati −25%» anche con il cursore a −40% (vedi Dubbi).
   - riga del cursore (solo per i tre scenari con valore):

     | Scenario | Etichetta a sinistra | Minimo | Massimo | Passo | Valore iniziale | Valore scritto a destra |
     |---|---|---|---|---|---|---|
     | Mercati | «Ribasso delle azioni» | 5 | 45 | 1 | 25 | «−25%» |
     | Tassi | «Rialzo dei tassi» | 0,5 | 4 | 0,5 | 2 | «+2 punti», «+2,5 punti» (virgola decimale) |
     | Inflazione | «Inflazione per 3 anni» | 2,5 | 9 | 0,5 | 5 | «5%», «5,5%» |

     Il valore scelto resta per scenario: se torno su «Mercati» ritrovo il valore lasciato.
   - per i due scenari storici, al posto del cursore, una frase sola in grigio:
     - 2008: **«Azioni −45%, titoli di Stato in rialzo: le cadute e le riprese storiche applicate a ogni portafoglio.»**
     - 2020: **«Azioni −30% in un mese, poi la ripresa: le cadute e le riprese storiche applicate a ogni portafoglio.»**
     In Prisma la prima metà della frase si compone dai valori di `CrisiStoriche` (vedi §5 e Dubbi: lì il 2008 è −37%, il 2020 −33%).
2. Filo verticale 1 px nel colore del separatore, alto quanto la card.
3. Colonna «quanti clienti» (250 di larghezza): il numero grande in rosso (nel template **3**) e sotto **«clienti scendono di più di 10 punti sui loro obiettivi»**.
4. Colonna «quanto patrimonio» (220): la cifra in rosso (nel template **−193.387 €**) e sotto **«di patrimonio, su tutto il portafoglio»**.

**B. Titolo della lista** (`.row.st`): **«Chi chiamare, in ordine»** e accanto, in grigio, **«la barra chiara è l’obiettivo oggi, quella piena dopo lo scenario»** (apostrofo tipografico).

**C. Lista** (`#fLista`): una riga per cliente, ordinata dal calo più forte. Dieci righe nel template, sette visibili; la lista scorre dentro la finestra, la card resta ferma. Ogni riga (`.card.fR`, senza ombra), da sinistra:

1. avatar 36 con le iniziali;
2. blocco di 200: nome in grassetto (**«Elisa Ferrara»**) e sotto l'obiettivo in grigio (**«Capitale in scadenza»**);
3. la barra (si allarga): binario grigio; sopra la **barra chiara** = copertura dell'obiettivo oggi; sopra ancora la **barra piena** = copertura dopo lo scenario. Colore della barra piena secondo il calo in punti:
   - più di 10 punti: rosso;
   - più di 5 punti: arancio;
   - altrimenti: blu;
4. blocco di 150, allineato a destra: **«dopo 74%»** in grassetto (rosso se il calo supera 10 punti, altrimenti nel colore del testo) e sotto **«oggi 90%»** in grigio;
5. blocco di 110, a destra: la perdita in euro in rosso, **«−17.232 €»**;
6. pulsante **«Chiama»**;
7. pulsante **«Messaggio»**.

Testi esatti delle righe del template (scenario «Mercati −25%», ordine finale):

| Cliente | Obiettivo | dopo | oggi | Perdita |
|---|---|---|---|---|
| Elisa Ferrara | Capitale in scadenza | 74% | 90% | −17.232 € |
| Martina Greco | Casa | 56% | 70% | −16.349 € |
| Andrea Conti | Fondo per gli imprevisti | 33% | 45% | −26.740 € |
| Marco Bianchi | Studi di Tommaso | 50% | 58% | −41.392 € |
| Giulia Rossi | Anticipo casa | 45% | 52% | −19.385 € |
| Laura Moretti | Pensione a 60 anni | 54% | 61% | −23.353 € |
| Federico Galli | Pensione | 34% | 40% | −14.595 € |
| Paolo Leone | Pensione | 54% | 60% | −16.450 € |
| Chiara Marino | Studi dei figli | 51% | 55% | −4.868 € |
| Sofia Romano | Rendita integrativa | 61% | 65% | −13.024 € |

Federico Galli, Chiara Marino, Elisa Ferrara, Paolo Leone e Martina Greco non esistono fra i clienti di prova di Prisma (`ClientiFittizi` ha Federica Galli, Enrico Marino, Beatrice Ferrara, Valentina Greco): nell'app la lista viene dall'archivio.

Le cifre degli altri scenari nel template (per confronto con le istantanee, non da copiare):
- Tassi +2 punti: **0** clienti, **−68.007 €**;
- Inflazione al 5%: **4** clienti, **−137.785 €**;
- Come nel 2008: **7** clienti, **−325.428 €**;
- Come nel 2020: **3** clienti, **−232.064 €**.

#### 1.3 Stati

Il template ha solo lo stato pieno. Proposte per Prisma:

| Stato | Cosa si vede |
|---|---|
| **Pieno** | come sopra |
| **Nessun cliente** | la card con le chip spente e, al posto della lista, il vuoto guidato di Posizioni («Aggiungi un cliente o carica i dati di prova da Impostazioni») |
| **Clienti senza obiettivi** | le righe ci sono, ma senza barra: al posto della barra la frase grigia «Nessun obiettivo nel dossier» e il pulsante leggero «Aggiungi un obiettivo» (apre il dossier sulla scheda Obiettivi). Contano nella perdita in euro, non nel numero dei clienti. Vanno in fondo, dopo quelli con obiettivi, ordinati per perdita |
| **Obiettivo senza posizioni collegate** | la barra c'è; se lo scenario non lo tocca (calo 0) sotto «oggi» compare «nessuna posizione collegata». Oggi è il caso di quasi tutti gli obiettivi di prova (vedi §6) |
| **Composizione stimata** | se una o più posizioni del cliente hanno quota azionaria, titoli di Stato o durata stimate, accanto a «dopo» un piccolo «≈» con l'aiuto «Composizione stimata dalla tipologia e dall'SRI»; in fondo alla lista una riga grigia «Su N posizioni la composizione è stimata: completale nella scheda della posizione» |
| **Nessuno sopra la soglia** | il numero grande è «0» e diventa verde; la frase resta uguale. È il caso dei tassi nel template |
| **Calcolo in corso** | non serve: il calcolo è sincrono e leggero (§5.3). Con molti clienti il cursore aggiorna al più 30 volte al secondo |
| **Modalità cliente** | la vista «Prova del fuoco» non c'è (si vede un solo cliente): il dossier ha già la «Prova di resistenza» (`PannelloResistenza`). Il segmento resta solo con «Portafoglio» (vedi Dubbi) |
| **Sola lettura** | tutto si vede; «Messaggio» resta, perché non scrive nell'archivio |

---

### 2. Misure e stile

Palco del template 1440×900; contenuto della finestra largo 1401 nelle misure prese con Playwright.

#### 2.1 Card dello scenario (`.card.st`)

- Superficie: `.card` → raggio **22**, fondo `--card` (chiaro `rgba(255,255,255,.82)`, scuro `rgba(255,255,255,.07)`), bordo 1 px `--sep` (chiaro `rgba(0,0,0,.08)`, scuro `rgba(255,255,255,.09)`), ombra `--shadow` (chiaro `0 24px 48px -28px rgba(8,40,60,.4), 0 2px 8px -3px rgba(8,40,60,.1)`). In Prisma: `Tema.Apple.Superficie.card`, `Raggio.card`, come la card del Portafoglio.
- Padding **20 / 24**; flex orizzontale con `gap: 24`, allineato al centro.
- Altezza misurata **148** con il cursore, circa **139** senza (scenari storici). La lista però resta a `top: 204`, quindi con gli storici sotto il titolo resta più spazio (si vede in `c2008.png`). In Prisma conviene che la lista segua il titolo (vedi Dubbi).
- Etichetta: `.lbl` 12 px, peso 600, maiuscolo, spaziatura 0,6, colore `--red` #E5484D.
- Riga delle chip: margine sopra **12**, `gap: 8`, va a capo se serve.
- **Chip** (`.chip`, nuova): pillola raggio 99, padding **7 / 14**, testo 13 px peso 600, fondo `--cardE` (chiaro #fff, scuro `rgba(40,54,66,1)`), bordo 1 px `--sep`. Accesa (`.chip.on`): fondo `--red`, testo bianco, bordo trasparente. Misura della prima: 120×32. Transizione `all .35s var(--spring)` (`cubic-bezier(.34,1.45,.64,1)`).
- Riga del cursore: margine sopra **16**, `gap: 16`.
  - etichetta `.k` 12,5 px `--ink2`, larghezza fissa **150**;
  - cursore: binario alto **6**, raggio 9, fondo `--track` (chiaro `rgba(0,0,0,.07)`, scuro `rgba(255,255,255,.1)`); pomello **28×28** bianco, ombra `0 3px 10px rgba(0,0,0,.28)`, cursore «grab». Nessun riempimento colorato a sinistra del pomello. In Prisma: `CursoreApple` (binario `Tema.Apple.Misura.binarioCursore` = 6);
  - valore: larghezza **90**, allineato a destra, carattere display 20 px grassetto (`<b>`, 700), colore del testo. Misura 91×24.
- Frase degli storici: `.k` 12,5 px `--ink2`, una riga.
- Filo verticale: 1 px, `--sep`, `align-self: stretch`.
- Colonna «clienti»: larghezza **250**. Numero `.v` portato a **40 px**, peso 700, spaziatura −0,5, cifre tabellari, colore `--red`. Sotto `.k` a **13,5 px**.
- Colonna «patrimonio»: larghezza **220**. Cifra `.v` **26 px** peso 700 `--red`. Sotto `.k` 13,5 px.

#### 2.2 Titolo della lista

- `.row.st` con margine **16 / 4 / 8** (sopra, lati, sotto).
- «Chi chiamare, in ordine»: `.h2` = display 21 px, peso 700, spaziatura −0,4.
- Frase accanto: `.k` 12,5 px `--ink2`, margine a sinistra 8 (oltre al `gap: 8` della riga).

#### 2.3 Lista e righe

- Contenitore: `position:absolute; top:204px; bottom:0; left:0; right:0; overflow:auto; padding-right:4px`. Misurato: 1401×454 a partire da y 357 sul palco.
- Riga (`.card.fR`): padding **10 / 16**, margine sotto **8**, flex con `gap: 14`, allineata al centro, **senza ombra** (`box-shadow:none`), raggio 22, fondo `--card`, bordo 1 px `--sep`. Altezza misurata **59**, passo fra le righe 67. Non si inclina (non ha `.tilt`).
- Avatar: 36×36, cerchio, iniziali bianche 12 px peso 600 (`36 × 0,34`), sfumatura del cliente. In Prisma: `AvatarCliente(lato: 36)`.
- Blocco nome: larghezza **200**; nome `<b>` 14 px; obiettivo `.k` 12,5 px.
- Barra: `flex:1`, alta **12**, raggio **8**, binario `--track`. Barra chiara: `rgba(10,132,255,.22)` (blu grafico #0A84FF al 22%, uguale in chiaro e scuro; sul binario scuro appare blu notte). Barra piena: #0A84FF, oppure #E08A00 (`--orange`) o #E5484D (`--red`). Misurata larga 600.
- Blocco «dopo/oggi»: larghezza **150**, a destra; «dopo» `<b>` 14 px; «oggi» `.k` 12,5 px.
- Blocco perdita: larghezza **110**, a destra, `<b>` 14 px `--red`.
- Pulsanti `.btn`: pillola raggio 99, padding **7 / 14**, 12,5 px peso 600, fondo `--cardE`, bordo `--sep`. «Chiama» misura 77×31.

#### 2.4 Nel tema di Prisma (nuovi token in `Tema.Apple.Posizioni.Fuoco`, nome proposto)

Tutto in `DesignSystem/Apple/Tema.Apple+Posizioni.swift`, ricavato dai token esistenti:

| Token proposto | Valore | Da |
|---|---|---|
| `Fuoco.paddingCard` | 20 / 24 | nuovo (la card del portafoglio ha il suo) |
| `Fuoco.spazioColonne` | 24 | nuovo |
| `Fuoco.larghezzaClienti` / `larghezzaPatrimonio` | 250 / 220 | nuovi |
| `Fuoco.etichettaCursore` | 150 | nuovo |
| `Fuoco.valoreCursore` | 90, display 20 bold | nuovo `Carattere` (`Carattere.valoreCursore` è 46 bold: troppo grande) |
| `Fuoco.numeroClienti` | display 40 bold | nuovo `Carattere` (fra `numeroGrande` 62 e `valore` 26) |
| `Fuoco.cifraPatrimonio` | display 26 bold | `Carattere.valore` |
| `Fuoco.coloreCifre` | `Colore.rosso` | esistente |
| `Fuoco.Chip.*` | padding 7/14, 13 semibold, raggio capsula, accesa `Colore.rosso` | nuovo componente `ChipApple` |
| `Fuoco.Riga.padding` / `spazio` / `passo` | 10/16, 14, 8 | nuovi |
| `Fuoco.Riga.nome` / `obiettivo` / `percento` / `perdita` | 200, 150, 110 | nuovi |
| `Fuoco.Barra.altezza` / `raggio` | 12 / 8 | nuovi |
| `Fuoco.Barra.oggi` | `Colore.bluGrafico.opacity(0.22)` | nuovo colore derivato |
| `Fuoco.Barra.ok` / `attenzione` / `allarme` | `bluGrafico` / `arancio` / `rosso` | esistenti |
| `Fuoco.sogliaAllarme` / `sogliaAttenzione` | 10 / 5 punti | nel motore, non nel tema (§5.3) |

---

### 3. Movimento

Valori dal template; in Prisma vanno in `Tema.Apple.Moto` (voci nuove indicate).

1. **Ingresso nella vista** (segmento o voce Novità): `rimonta` (00-comune §3.4: 0,13 s lineare verso opacità 0 e scala 0,99), poi la cascata `entrata` sui due blocchi `.st` (card e titolo della lista): 0,72 s, `cubic-bezier(.22,1,.36,1)`, ritardo `i × 48 ms`, da `translateY(18px) scale(.985)` e sfocatura 6 px. È `Tema.Apple.Moto.Cascata` (esiste). Le righe della lista **non** entrano a cascata: compaiono subito con la barra piena larga quanto quella chiara (lo stato «oggi»), «dopo» scritto come «90%» e la perdita «0 €».
2. **Primo calcolo**, 350 ms dopo il montaggio (`setTimeout(…,350)`), con riordino:
   - la barra piena si accorcia fino al valore «dopo»: `width .8s var(--out)` = 0,8 s `cubic-bezier(.22,1,.36,1)`; il colore passa a arancio o rosso in 0,5 s (curva `ease` del CSS). Voce nuova proposta: `Tema.Apple.Moto.BarraScenario` (0,80 s, curva `uscita`; colore 0,50 s, curva `ease`);
   - il numero dei clienti si conta da quello precedente al nuovo in **0,6 s**, la cifra del patrimonio in **0,7 s**, con `ease = 1 − (1 − t)^4`. In Prisma `NumeroCheConta` con durate proprie (voce nuova `Tema.Apple.Moto.NumeroScenario`: 0,60 e 0,70) o con `NumeroCambio` (0,90): vedi Dubbi;
   - «dopo X%» e la perdita in euro cambiano **di colpo**, senza contare;
   - **riordino** (FLIP): le righe vanno subito al nuovo posto e scivolano dalla posizione vecchia in **0,65 s** con `cubic-bezier(.32,1.2,.5,1)` (leggero rimbalzo). Le righe che si spostano meno di 1 px non si animano. Voce nuova: `Tema.Apple.Moto.Riordino` (0,65 s, curva nuova `Curva.riordino = (.32, 1.2, .5, 1)`; vicina ma diversa da `dettaglioApre` (.32, 1.22, .5, 1)). In SwiftUI basta cambiare l'ordine dentro `withAnimation` con identità stabili (`ForEach` per `cliente.id`).
3. **Cambio di chip**: la chip si accende (transizione 0,35 s molla); la riga del cursore si sostituisce senza animazione; poi ricalcolo con riordino come al punto 2 (barre, numeri, scivolamento). Niente `rimonta`.
4. **Trascinamento del cursore**: a ogni passo ricalcolo **senza** riordino (barre e numeri si muovono, l'ordine resta); al rilascio (`change`) ricalcolo **con** riordino. In Prisma: `CursoreApple` ha solo il trascinamento; serve un `alRilascio` (o `onEditingChanged`) nuovo.
5. **Passaggio del puntatore**: chip `translateY(-2px)` con molla 0,35 s; pulsanti luminosità 0,97 (`PulsantePremuto.luminositaSopra`, esiste); segmenti con la pillola a molla 0,5 s (`Segmentato`, esiste).
6. **Riduci movimento** (template: `ridotto`): i numeri finiscono in 1 ms e il riordino dura 1 ms; la transizione CSS della barra però resta di 0,8 s (svista del template). In Prisma (`\.prismaCalmo`): niente cascata, niente scivolamento, niente conteggio; tutto compare già fermo con la dissolvenza di 0,15 s, barre comprese.
7. **Istantanee** (`\.modoIstantanea`, `\.prismaStatoFinale`): la vista è disegnata già calcolata e riordinata, numeri completi, barre al valore «dopo», nessuna chip sotto il puntatore.

Svista del template da non copiare: i numeri della card ripartono dall'ultimo valore della sessione (`fN0`, `fP0` sono globali) anche quando la vista si rimonta e il testo è tornato a «0». In Prisma alla prima comparsa si conta da 0; ai cambi dal valore precedente.

---

### 4. Interazioni

| Dove | Azione | Effetto |
|---|---|---|
| Segmenti della testata | clic su «Prova del fuoco» / «Portafoglio» | cambia vista con `rimonta` |
| Chip | clic | sceglie lo scenario, mostra il cursore o la frase, ricalcola e riordina. Clic sulla chip già accesa: niente |
| Chip | puntatore sopra | si solleva di 2 |
| Cursore | trascinamento | ricalcolo dal vivo, ordine fermo; il valore a destra cambia subito |
| Cursore | rilascio | riordino |
| Cursore | tastiera (← → con il fuoco, VoiceOver «regola») | un passo per volta; in Prisma ogni passo da tastiera vale come rilascio (ricalcolo e riordino) |
| «Chiama» | clic | template: avviso «Chiamata: il numero è nel dossier» (2,4 s). Prisma: se c'è `Cliente.telefono`, apre `tel:` (sul Mac passa all'iPhone con Continuity) dopo conferma; se manca, avviso «Manca il telefono di <nome>: aggiungilo nel dossier» con il pulsante per aprirlo |
| «Messaggio» | clic | template: apre Messaggi sul secondo messaggio (`selM=1`). Prisma: apre Messaggi (parte 05) con una bozza per quel cliente sul tema dello scenario (motivo «prova del fuoco», scenario e cifre del cliente passate da Prisma, testo di Ruby); niente si spedisce da solo |
| Riga | clic | nel template non fa nulla. Proposta: apre il dossier del cliente sulla scheda Obiettivi, con l'obiettivo mostrato (vedi Dubbi) |
| Lista | rotella / due dita | scorre; card e titolo restano fermi |
| Esc | — | chiude la finestra come sempre (nessun pannello proprio) |

Il contenuto della prova non si salva: lo scenario scelto e i valori dei cursori restano finché l'app è aperta (in `StatoShell`, non nell'archivio).

---

### 5. Mappa verso Prisma

#### 5.1 Da riusare (verificato con grep in `Sources/Prisma`)

- `Motori/MotoreResistenza.swift`: `ProvaResistenza` (scenari mercati, inflazione, immobili per **un** cliente, giudizio sul profilo), `MotoreResistenza.quotaARischio(_:)` (gestione separata e conti non scendono, multiramo divise), `voceInflazione` (perdita di potere d'acquisto in 3 anni sotto un'inflazione alta; oggi con `inflazioneAlta = 5` e `anniInflazione = 3` fissi), `caloPerSRI`.
- `Motori/CrisiStoriche.swift`: `CrisiStorica` (2008, 2020, 2022 con variazioni per classe: azioni, titoli di Stato, societarie, liquidità, gestione separata, immobili), `ComposizionePosizione` e `MotoreResistenza.composizione(_:)` (quota azionaria indicata o stimata da tipologia/SRI, titoli di Stato indicati o metà, multiramo con il 50% in gestione separata se non indicato), `MotoreResistenza.crisi(_:profilo:)`, `metodoCrisi` (testi del metodo per prospetto e Ruby).
- `Motori/MotoreObiettivo.swift`: `EsitoObiettivo.copertura` (0…1, limitata a 1), `MotoreObiettivo.contributoPosizione(_:obiettivo:scarto:mesiProiezione:data:)`, `versamentoPrevisto`. `Motori/CurvaObiettivo.swift` per l'idea dei campioni.
- `Dati/Prodotti.swift`: `Obiettivo` (importo in euro di oggi, `scadenza`, `priorita`, `accantonato`, `posizioniCollegate`, `rendimento`, `versamentoMensile`); `DatiPrisma.obiettivi`.
- `Dati/Posizione.swift`: `sri`, `quotaAzionaria`, `quotaTitoliStato`, `rendimentoAtteso`, `gestioneSeparata`, `multiramoDivisa`.
- `Motori/ProvaCalcoliRischio.swift`: le prove K1-K7 della resistenza e delle crisi (modello per le prove nuove).
- `Shell/PannelloResistenza.swift`, `ProspettoResistenza.swift`, `ReportResistenza.swift`, `Ruby/AnalisiRuby.swift` (`resistenza`): la prova per cliente nel dossier, nel PDF e in Ruby. Restano.
- Tema: `SegmentatoPillola`, `CursoreApple`, `NumeroCheConta`, `StilePulsanteApple`, `AvatarCliente`, `EntrataApple` (cascata), `Tema.Apple.Colore.rosso` / `arancio` / `bluGrafico` / `binario`, `Tema.Apple.Superficie.card`.
- Shell: `AppPosizioni` (oggi la scelta «Cliente | Portafoglio» sta nella colonna), `PortafoglioApple` (la vista «Portafoglio» del tema Apple), `StatoPortafoglioApple.swift` + `DerivatiDati` (cache delle cifre del portafoglio), `IstantaneePosizioniApple.swift` (istantanee 420-422), `StatoShell.mostraAvviso`, `Cliente.telefono`.

#### 5.2 Cosa manca

- **Vista**: `Shell/ProvaDelFuocoApple.swift` (nome proposto) con `CardScenarioFuoco`, `RigaFuoco` (sotto-viste `Equatable`), lista in `ScrollView` + `LazyVStack`. `VistaPosizioni` (`.portafoglio`, `.provaDelFuoco`, già proposta in 00-comune §5.2) e i segmenti nella testata di Posizioni, solo in modalità Portafoglio.
- **Componenti del tema**: `ChipApple` (pillola selezionabile; servirà anche altrove) in `DesignSystem/Apple/ControlliApple.swift`; `BarraOggiDopo` (binario + barra chiara + barra piena animata) in `GraficiApple.swift`; `alRilascio` in `CursoreApple`; voci di `Tema.Apple.Moto` (`Riordino`, `BarraScenario`, `NumeroScenario`) con il ramo calmo e statico; le misure di §2.4; la vetrina `VetrinaApple` mostra chip e barra.
- **Stato**: in `StatoShell` (o in uno `StatoProvaDelFuoco` osservabile) lo scenario scelto e i valori dei tre cursori; l'esito sta in `DerivatiDati` per chiave (scenario + valore + `chiaveVista`).
- **Motore**: tutto ciò che sta in §5.3. Oggi la resistenza è per un cliente e con scenari fissi; mancano lo scenario «tassi», la quota obbligazionaria con la sua durata, il cursore sui valori e l'effetto sugli obiettivi.
- **Ruby**: una risposta «prova del fuoco» sul portafoglio (chi scende di più e perché) dalle cifre del motore, modalità lavoro; aggiornare `Ruby/chat.md` con la regola «le cifre della prova del fuoco vengono da Prisma».
- **Messaggi**: un motivo nuovo per la bozza («dopo la prova del fuoco»), nella parte 05.

#### 5.3 Motore nuovo: `Motori/MotoreProvaDelFuoco.swift` (nome proposto)

Funzioni pure, nessuna dipendenza dalla vista.

```swift
enum ScenarioFuoco: Hashable {
    case mercati(calo: Double)                 // % sulle azioni, 5…45
    case tassi(punti: Double)                  // punti percentuali, 0,5…4
    case inflazione(tasso: Double, anni: Int)  // 2,5…9, per 3 anni
    case crisi(anno: Int)                      // 2008, 2020 (da CrisiStoriche.crisiDelPassato)
}
struct RigaFuoco: Identifiable {               // un cliente
    let cliente: Cliente
    let obiettivo: Obiettivo?                  // quello che scende di più (nil = nessun obiettivo)
    let coperturaOggi: Double                  // 0…1
    let coperturaDopo: Double                  // 0…1
    var calo: Double { (coperturaOggi - coperturaDopo) * 100 }   // in punti
    let perdita: Double                        // euro, su tutte le posizioni finanziarie in essere
    let stimata: Bool                          // composizione o durata stimate
    let collegateAssenti: Bool
}
struct EsitoFuoco {
    let scenario: ScenarioFuoco
    let righe: [RigaFuoco]                     // in ordine: calo ↓, a pari calo perdita ↓; senza obiettivi in fondo
    let oltreSoglia: Int                       // righe con calo > sogliaAllarme
    let perditaTotale: Double                  // somma delle perdite di tutti i clienti
    let posizioniStimate: Int
}
enum MotoreProvaDelFuoco {
    static let sogliaAllarme = 10.0            // punti: «più di 10 punti»; 10,0 non conta
    static let sogliaAttenzione = 5.0
    static let durataPredefinita: [String: Double]   // per tipologia (vedi sotto e §6)
    static func calcola(_ s: ScenarioFuoco, clienti: [Cliente], posizioni: [Posizione], obiettivi: [Obiettivo], oggi: Date) -> EsitoFuoco
    static func variazione(_ p: Posizione, _ s: ScenarioFuoco) -> Double   // frazione del valore, negativa = calo
}
```

**Perdita di una posizione** (solo in essere, aree proiettabili e liquidità, come `MotoreResistenza.calcola`), dalla `ComposizionePosizione` esistente:
- **Mercati −x%**: `valore × azioni × x / 100`. Solo la parte azionaria (come il template: `p × eq × calo`). Gestione separata e liquidità a zero.
- **Tassi +d punti**: `valore × (governativi + societarie) × durata × d / 100` (approssimazione con la durata finanziaria). Gestione separata a zero (valore di carico, garantita); liquidità a zero. La durata viene da `Posizione.durataObbligazioni` (campo nuovo) o da `durataPredefinita` (proposta da confermare: monetari 0,5; obbligazionari breve termine 2; obbligazionari 6; bilanciati e flessibili 5; previdenza non in gestione separata 7; altrimenti 5), e allora la riga è «stimata».
- **Inflazione e% per n anni**: come `voceInflazione`, ma con `e` e `n` come parametri invece di `inflazioneAlta` e `anniInflazione` (la funzione esistente diventa un caso di quella nuova, con 5% e 3 anni, così la prova di resistenza non cambia).
- **Crisi storica**: esattamente `EsitoCrisi.Voce.perdita` di `MotoreResistenza.crisi` (stesse variazioni, stessa composizione). Il 2022 c'è già nel motore: si può aggiungere come sesta chip (vedi Dubbi).

**Copertura dopo lo scenario**, per ogni obiettivo del cliente con scadenza futura:
- oggi: `copertura` come `EsitoObiettivo` (stessi conti di `MotoreObiettivo`), ma con una funzione leggera nuova `MotoreObiettivo.coperturaAScadenza(_:posizioni:inflazione:data:)` che non calcola strade, rinvii e scenari (quelle fanno bisezioni e fino a 30 proiezioni: troppo per un cursore su 200 clienti);
- dopo: stessa funzione con le **posizioni collegate** scosse (copia della `Posizione` con `valore × (1 + variazione)`; rendimenti futuri invariati, scelta prudente), l'accantonato invariato;
- inflazione: l'obiettivo si rivaluta al tasso `e` per i primi `n` anni e poi all'inflazione di sempre (`IpotesiCalcolo.inflazione`, 2%): `importo × (1+e)^min(n, anni) × (1+i)^max(0, anni−n)`. Serve il parametro `inflazione` (oggi `MotoreObiettivo` legge la costante);
- 2020: il template aggiunge una ripresa (+8% sulla copertura «dopo»). Proposta: Prisma mostra il punto più basso (il minimo del 23 marzo), con sotto la frase del recupero di `CrisiStorica.recupero` (vedi Dubbi);
- l'obiettivo mostrato nella riga è quello con il calo più forte; a pari calo quello con priorità più alta, poi la scadenza più vicina.

**Prestazioni** (M1 8 GB, fino a 200 clienti): la composizione di ogni posizione e la copertura «oggi» si calcolano una volta (cache in `DerivatiDati` per `chiaveVista`); a ogni passo del cursore si ricalcola solo la proiezione delle posizioni collegate a scadenza (una per posizione, non le strade). Il calcolo non tocca il thread principale più di qualche millisecondo; se la prova di carico (`Shell/ProvaCarico.swift`) supera 16 ms per passo, il calcolo va su un `Task` con l'ultimo valore vincente.

#### 5.4 Campi nuovi dell'archivio (nomi proposti, letti con tolleranza)

- `Posizione.durataObbligazioni: Double?` — durata finanziaria in anni della parte obbligazionaria (dal KID o dalla scheda del fondo). Nil = stimata dalla tipologia. Va nel modulo della posizione, accanto a «Quota in titoli di Stato», e in `ImportaPosizioni` (colonna facoltativa). Nelle multiramo divise vale per la parte in fondi (`durataObbligazioniFondi: Double?`, se si vuole distinguere come per `quotaAzionariaFondi`).
- `Impostazioni.provaDelFuoco: ImpostazioniProvaDelFuoco?` (facoltativo) con `sogliaPunti: Double` (predefinita 10) e i valori iniziali dei cursori (25, 2, 5). Solo se l'utente vuole cambiarli (vedi Dati da chiedere); altrimenti restano costanti del motore.

Niente altro nell'archivio: la prova è un calcolo, non si salva. Backup: i campi sopra seguono `Posizione` e `Impostazioni`, quindi `Prisma --prova-backup` va solo esteso con un valore di `durataObbligazioni` che torni uguale dopo il ripristino, e con un archivio di prima senza il campo.

#### 5.5 Prove di calcolo nuove: `Motori/ProvaCalcoliFuoco.swift`

Chiamata da `ProvaCalcoli.swift` come `ProvaCalcoliRischio.esegui(verificaEsterna)`. Casi (cifre tonde, scelte per la prova):

- **F1 Mercati**: fondo da 100.000 € con quota azionaria 40%, mercati −25% → perdita **10.000 €**.
- **F2 Gestione separata**: Ramo I da 50.000 € → perdita **0** con mercati −45% e con tassi +4.
- **F3 Multiramo**: 100.000 € senza quota indicata (50% gestione separata), fondi tutti azionari, −20% → **10.000 €**.
- **F4 Tassi**: 60.000 € tutti obbligazionari con `durataObbligazioni = 5`, +2 punti → **6.000 €**; senza durata e tipologia «obbligazionario» → durata predefinita e riga «stimata».
- **F5 Inflazione**: la funzione nuova con 5% e 3 anni dà la stessa perdita di `voceInflazione` di oggi (tolleranza 0,01 €): la prova di resistenza non cambia.
- **F6 Inflazione sull'obiettivo**: 50.000 € di oggi fra 10 anni con 5% per 3 anni → traguardo `50.000 × 1,05³ × 1,02⁷` = **66.487,36 €** (tolleranza 0,01).
- **F7 Crisi 2008**: la perdita del cliente nella prova del fuoco è uguale a `EsitoCrisi.perdita` di `MotoreResistenza.crisi` per il 2008 e il 2020 (tolleranza 0).
- **F8 Copertura**: con calo 0 (tassi su un cliente senza obbligazioni) `coperturaDopo == coperturaOggi`; con mercati la copertura dopo non supera mai quella di oggi.
- **F9 Coerenza con il piano**: `coperturaAScadenza` senza scenario = `MotoreObiettivo.calcola(…).copertura` (tolleranza 0,0001), su un obiettivo con posizioni collegate, accantonato e versamento previsto.
- **F10 Soglia**: calo di esattamente 10,0 punti non conta; 10,01 sì; colore arancio sopra 5, rosso sopra 10.
- **F11 Ordine**: calo decrescente; a pari calo perdita decrescente; i clienti senza obiettivi in fondo per perdita; la perdita totale li comprende.
- **F12 Obiettivo scaduto o senza importo**: non entra (nessuna divisione per zero); il cliente resta con la sola perdita.
- **F13 Proposte**: le posizioni in proposta non perdono nulla (solo in essere).
- **F14 Carico**: 200 clienti fittizi, un passo del cursore sotto la soglia stabilita in `ProvaCarico` (proposta 16 ms sul runner).

---

### 6. Dati che l'utente deve dare (mai inventarli)

| Dato | A cosa serve | Finché manca |
|---|---|---|
| **Quota azionaria e quota in titoli di Stato** delle posizioni (campi che ci sono già) | perdita con mercati, tassi e crisi | stimate dalla tipologia e dall'SRI (`composizione`), con «≈» sulla riga e la nota in fondo |
| **Durata finanziaria** della parte obbligazionaria (campo nuovo) | scenario tassi | durata predefinita per tipologia, con «≈»; l'utente conferma la tabella delle durate predefinite |
| **Obiettivi dei clienti con le posizioni collegate** | barre «oggi/dopo», numero dei clienti oltre soglia | riga senza barra («Nessun obiettivo nel dossier»); con obiettivo senza posizioni collegate la barra non si muove (tranne con l'inflazione) e c'è la nota «nessuna posizione collegata» |
| **Telefono** dei clienti | «Chiama» | avviso con l'invito ad aggiungerlo |
| **Conferma della soglia** «più di 10 punti» e dei campi dei cursori (5-45, 0,5-4, 2,5-9; iniziali 25, 2, 5) | card e colori | si usano i valori del template |
| **Conferma dei valori storici**: Prisma usa 2008 azioni −37% e titoli di Stato +4%, 2020 azioni −33% (MSCI World in euro, `CrisiStoriche`); il template scrive −45% e −30% | scenari storici e frase sotto le chip | si usano quelli di `CrisiStoriche`, già documentati nel metodo |

**Dati di prova.** Con i 5 clienti del template e i 30 fittizi oggi la prova sarebbe quasi muta: in `DatiDemo.obiettivi()` ci sono 3 obiettivi (due di Giulia, uno di Marco) e solo «Anticipo per la casa» ha una posizione collegata (il conto, che non scende); gli obiettivi di `ClientiFittizi` non hanno posizioni collegate. Per valutare il motore servono, solo nei dati di prova:
- un obiettivo per ognuno dei 5 clienti del template, con le posizioni collegate e i nomi del template (Giulia «Anticipo casa», Marco «Studi di Tommaso» o l'attuale «Università di Anna», Laura «Pensione a 60 anni», Andrea «Fondo per gli imprevisti», Sofia «Rendita integrativa»);
- le posizioni collegate negli obiettivi dei fittizi;
- qualche `quotaAzionaria`, `quotaTitoliStato` e `durataObbligazioni` sulle posizioni di prova, lasciandone alcune vuote per vedere le stime.

Vanno in `Dati/DatiDemo.swift` e `Dati/ClientiFittizi.swift`, e nell'interfaccia restano riconoscibili come «dati di prova» (come oggi). In un archivio vero non compaiono se l'utente non li carica.

---

### 7. Istantanee da aggiungere

La serie 590-599 è libera (verificato con grep nelle sorgenti e nelle altre parti della specifica). Tutte con i dati di prova di §6, nello stato finale.

| Nome | Scena |
|---|---|
| `590-posizioni-fuoco` / `590-posizioni-fuoco-scuro` | Portafoglio › Prova del fuoco, «Mercati −25%», lista riordinata, chip e segmenti fermi |
| `591-posizioni-fuoco-mercati-45` | cursore a −45%: più righe rosse, numero e cifra più grandi |
| `592-posizioni-fuoco-tassi` / `-scuro` | «Tassi +2 punti»: numero «0» verde, barre quasi tutte blu, righe con «≈» per le durate stimate |
| `593-posizioni-fuoco-inflazione` | «Inflazione al 5%» |
| `594-posizioni-fuoco-2008` / `-scuro` | «Come nel 2008»: card senza cursore con la frase storica, la lista subito sotto il titolo |
| `595-posizioni-fuoco-2020` | «Come nel 2020», con la frase del recupero |
| `596-posizioni-fuoco-senza-obiettivi` | clienti senza obiettivi in fondo, con «Nessun obiettivo nel dossier» e «Aggiungi un obiettivo» |
| `597-posizioni-fuoco-vuoto` | archivio senza clienti: card spenta e vuoto guidato |
| `598-posizioni-fuoco-stretta` | finestra stretta (come `234-posizioni-finestra-stretta`): blocchi della riga che si stringono, nome e obiettivo troncati, pulsanti che restano interi |
| `420-posizioni-portafoglio` / `-scuro` (esistente) | da rifare: nella testata compaiono i segmenti «Portafoglio · Prova del fuoco» |
| `400-vetrina-apple` / `-scuro` (esistente) | aggiungere `ChipApple` (spenta, accesa) e `BarraOggiDopo` nei tre colori |

Nelle istantanee il motore usa una data fissa, come le altre, così le cifre non cambiano da un giorno all'altro.

---

## 7. Clienti › Dossier › La linea della vita

*Parte 11 · titolo della bozza: «11 · Clienti › Dossier › La linea della vita»*

Fonte: `Design/template-novita.html`. Le righe citate sono di quel file:
- voce Novità `NOV[7]` (738): «La linea della vita» · «Trascini gli eventi, il futuro si ricalcola» → `vaiA('clienti',()=>{selCli=0;tabCli='vita'})`;
- segmentato del dossier (452), `tabHTML` (455), `dopoTab` (491);
- dati `VITA` (996-1000), `proiezione()` (1002), `vitaHTML()` (1003-1005), `montaVita()` (1006-1016), `disegnaVita()` (1017-1026);
- CSS `.vEv` e `.vEv.presa` (211-212); token 17-23; `.lbl`, `.k`, `.v` (33-35); `.card` (49);
- utilità comuni: `conta` (265), `entrata` (267), `disegnaLinea`/`linee` (282-283), `ridotto` (261).

Schermate (1480×940):
- `orizzonte/chiaro-17-la-linea-della-vita.png`, `orizzonte/scuro-17-la-linea-della-vita.png`: Giulia, ferma, a disegno finito;
- scattate per questa specifica, in `orizzonte/spec/`:
  - `vita-entrata-chiaro.png` / `-scuro`: 350 ms dopo il clic sulla voce Novità, con la cascata del dossier ancora sfocata;
  - `vita-presa-chiaro.png` / `-scuro`: «Pensione» presa e portata a 58 anni (ombra della presa, punto rosso «finisce a 77 anni»);
  - `vita-pensione58-chiaro.png` / `-scuro`: lo stesso, lasciata;
  - `vita-sofia-chiaro.png` / `-scuro`: Sofia Romano, 61 anni: lo stato con il punto rosso «finisce a 81 anni» fin dall'apertura.

Per ciò che qui non è detto (finestra Clienti, rubrica, testata e tessere del dossier, segmentato a pillola, card, cascata, numeri che si contano, linee che si disegnano) vale `Design/template-apple-specifica.md` §4.2.1-4.2.4 e la parte comune `00-comune.md` (§1.7, punto 6: la scheda si aggiunge fra Obiettivi e Nel tempo).
**Le cifre del template sono dimostrative** (risparmio, prelievo, 2,5% fisso, importi degli eventi): nell'app le danno i motori (§5); se un dato manca si dice cosa manca (§6), mai un numero inventato.

---

### 1. Cosa si vede

#### 1.1 Come si arriva
- Clienti › un cliente › segmentato del dossier › **«Linea della vita»** (valore `vita`). Il segmentato ha ora cinque voci: **Panoramica · Obiettivi · Linea della vita · Nel tempo · Famiglia**.
- Pannello Novità, voce 8: apre Clienti, sceglie il primo cliente (Giulia) e la scheda Linea della vita.
- Testata del dossier e le quattro tessere (Patrimonio netto, Capitale assicurato, Premi annui, Proposte aperte) restano sopra, uguali alle altre schede.

#### 1.2 Struttura
Una sola **card** che riempie l'area della scheda (`#tabC`: da y 236 del dossier fino a 20 dal fondo; nel template 1066×394). Dall'alto:

1. **Riga del titolo**
   - a sinistra `.lbl` **«La linea della vita · da oggi a 90 anni»** (maiuscoletto per lo stile `.lbl`: nella schermata «LA LINEA DELLA VITA · DA OGGI A 90 ANNI»);
   - a destra `.k` **«Trascina gli eventi e la pensione: tutto si ricalcola»**.
2. **Tre cifre** in riga (spazio 34, margine sopra 10), ognuna con l'etichetta `.k` sopra e il valore `.v` sotto:
   | Etichetta | Valore | Note |
   |---|---|---|
   | **«A {età pensione} anni, in pensione»** (nell'HTML iniziale «A 67 anni», subito sostituita) | patrimonio all'età della pensione, «661.156 €» | si conta da 0 |
   | **«Al massimo»** | il picco della curva fino a 90 anni, «674.299 €» | si conta da 0 |
   | **«Il patrimonio basta»** | **«oltre i 90 anni»** in verde (`--green`), oppure **«fino a {N} anni»** in rosso (`--red`) | testo, non si conta |
3. **Grafico** (SVG 1040×140, area di disegno alta 130; asse x = età, da oggi a 90):
   - **zona della pensione**: rettangolo da x(età pensione) al bordo destro, alto 130, `rgba(139,92,246,.06)`; dentro, in basso a sinistra (x+8, y 122) la scritta **«in pensione»** 11 semibold viola `#8B5CF6`;
   - **area** sotto la curva con gradiente verticale viola `#8B5CF6` da opacità .28 a 0;
   - **curva** del patrimonio, viola `#8B5CF6`, spessore 2,8, giunti arrotondati; scala verticale da 0 al massimo × 1,08; i valori negativi sono schiacciati a 0 (la curva corre sul fondo dopo l'esaurimento);
   - **righe verticali degli eventi** all'età esatta, alte tutto il grafico, tratteggio 2 4, opacità .7, verdi `#30B15C` per un'entrata (importo > 0) e arancio `#E08A00` per un'uscita;
   - **punto rosso** solo se il patrimonio finisce prima dei 90: cerchio raggio 6 `#E5484D` sul fondo del grafico (x = età della fine, y 130) e sopra, centrata a y 118, la scritta **«finisce a {N} anni»** 12 bold rossa.
   - Niente griglia orizzontale, niente valori sull'asse y.
4. **Linea del tempo con gli eventi** (`#vLinea`, alta 104, margine sopra 4):
   - binario orizzontale alto 2 a y 78, colore `--track`;
   - una tacca ogni 5 anni (dal primo multiplo di 5 dopo l'età di oggi fino a 90): trattino 1×10 a y 74 in `--sep`, numero sotto a y 86, 11 regolare `--ink3`, centrato («40 45 50 … 90»);
   - **gettoni degli eventi** (capsule), uno per evento, su tre file sfalsate (y 0, 25, 50: file = indice % 3), centrati sull'età: **nome in grassetto** e **«{età} anni»** in `.k` («**Matrimonio** 38 anni»). Bordo 2 nel colore dell'evento (verde entrata, arancio uscita), fondo `--cardE`;
   - **gettone «Pensione {età} anni»** con bordo viola `#8B5CF6` e fondo `rgba(139,92,246,.12)`, nella fila `numeroEventi % 3`.
   - I gettoni sono tenuti dentro la card: il centro non va sotto x 70 né oltre larghezza − 70. Per questo «Matrimonio 38» e «Casa 40» di Giulia stanno entrambi a 70, non sotto le loro righe tratteggiate (le righe del grafico invece sono all'età vera).

#### 1.3 Dati dimostrativi del template (`VITA`, solo per riferimento)
| Cliente | Età | Risparmio l'anno | Prelievo l'anno in pensione | Pensione | Eventi |
|---|---|---|---|---|---|
| Giulia Rossi | 37 | 9.600 | 30.000 | 67 | Matrimonio 38 (−15.000), Casa 40 (−40.000), Un figlio 41 (−4.000 l'anno per 22 anni), Eredità 62 (+80.000) |
| Marco Bianchi | 45 | 15.000 | 36.000 | 67 | Università di Tommaso 54 (−9.000 l'anno per 5 anni), Casa al mare 60 (−150.000) |
| Laura Moretti | 49 | 18.000 | 34.000 | 60 | Anno sabbatico 51 (−30.000) |
| Andrea Conti | 32 | 7.000 | 22.000 | 67 | Casa 36 (−35.000) |
| Sofia Romano | 61 | 3.000 | 16.000 | 64 | Un aiuto ai nipoti 66 (−30.000) |

Esiti calcolati con la formula del template: Giulia 661.156 / 674.299 / oltre i 90; Marco 692.708 / 710.935 / oltre; Laura 413.793 / 436.871 / fino a 75; Andrea 642.873 / 648.657 / oltre; Sofia 245.235 / 254.863 / fino a 81. Servono come prova della formula (§5.5, LV1), non come numeri dell'app. Nota: Marco in Prisma ha la figlia **Anna** (`DatiDemo`), non «Tommaso».

#### 1.4 Stati
- **Pieno**: come sopra (Giulia: verde «oltre i 90 anni»).
- **Esaurimento**: «fino a {N} anni» in rosso + punto rosso + «finisce a {N} anni» (Sofia; Giulia con la pensione a 58).
- **Il template non ha** stato vuoto, caricamento o errore. Per Prisma (proposte, §6): senza data di nascita, senza eventi, con dati mancanti per risparmio o prelievo.

---

### 2. Misure e stile

Palco 1440×900 (nelle schermate scalato di 1,0137). Valori CSS del template.

#### 2.1 Card
- `.card`: raggio 22, fondo `--card` (chiaro `rgba(255,255,255,.82)`, scuro `rgba(255,255,255,.07)`), bordo 1 `--sep`, ombra `--shadow`. Padding **18 × 24** (le altre card del dossier 20 × 22/24). Altezza 100% dell'area scheda. In Prisma: `Tema.Apple.Superficie.cardPiatta` come Nel tempo.
- Larghezza interna nel template 1018; il grafico è disegnato a 1040 (`overflow:visible`), quindi sborda di 22 a destra fino al bordo della card (si vede nelle schermate: la zona viola tocca il bordo). In Prisma il grafico usa la larghezza vera (dubbio 7).

#### 2.2 Testi
| Elemento | Stile | Valori |
|---|---|---|
| titolo | `.lbl` | 12, semibold 600, maiuscolo, tracking .6, `--ink2` → `Carattere.etichetta` |
| nota a destra, etichette delle cifre | `.k` | 12,5 regolare, `--ink2` → `Carattere.secondario` |
| cifre | `.v` | SF Pro Display 26 bold, tracking −.5, cifre tabellari → `Carattere.valore` |
| «oltre i 90 anni» / «fino a N anni» | `.v` | colore `--green` `#2FA35A` / `--red` `#E5484D` (fissi, uguali in scuro) |
| «in pensione» | SVG | 11, 600, `#8B5CF6` |
| «finisce a N anni» | SVG | 12, 700, `#E5484D`, centrato |
| numeri dell'asse | | 11 regolare `--ink3` (chiaro `rgba(0,0,0,.34)`, scuro `rgba(255,255,255,.38)`) → `Carattere.asse` |
| gettone | `.vEv` | 12,5; nome `<b>` 700 `--ink`; età `.k` 12,5 `--ink2` |

#### 2.3 Gettoni (`.vEv`)
- capsula: padding 5 × 12, raggio 99, bordo **2** pieno nel colore, fondo `--cardE` (chiaro `#fff`, scuro `rgba(40,54,66,1)` → `Colore.cardPiena`), ombra `--shadow`, `white-space:nowrap`, altezza misurata 29; larghezze misurate 145 (Matrimonio 38 anni), 107 (Casa), 123 (Un figlio), 118 (Eredità), 131 (Pensione);
- centrati sull'età (`translateX(-50%)`), centro fra 70 e larghezza − 70;
- file a y 0 / 25 / 50 (passo 25, quindi i gettoni alti 29 si accavallano di 4: nella schermata si toccano);
- `cursor: grab`; preso: `cursor: grabbing`, ombra `0 16px 30px -10px rgba(8,40,60,.45)`, `z-index 5`; transizione dell'ombra .2 s;
- pensione: bordo `#8B5CF6`, fondo `rgba(139,92,246,.12)`.

#### 2.4 Colori del grafico (fissi, uguali in chiaro e scuro)
| Uso | Valore | In Prisma |
|---|---|---|
| curva, area, zona e gettone pensione | `#8B5CF6` (`--r3`) | `Colore.stima` / `anello3` |
| evento in entrata | `#30B15C` (`--r1`) | `Colore.anello1` |
| evento in uscita | `#E08A00` (`--orange`) | `Colore.arancio` |
| punto e scritta della fine, «fino a…» | `#E5484D` (`--red`) | `Colore.rosso` |
| «oltre i 90 anni» | `#2FA35A` (`--green`) | `Colore.verde` |
| binario | `--track` (chiaro `rgba(0,0,0,.07)`, scuro `rgba(255,255,255,.1)`) | `Colore.binario` |
| tacche | `--sep` | `Colore.separatore` |

#### 2.5 Geometria del grafico
- x(età) = (età − età di oggi) / (90 − età di oggi) × larghezza;
- y(v) = 130 − v / (max × 1,08) × 130;
- la curva ha un punto per anno intero (da oggi a 90 compresi).

Valori nuovi da mettere in `DesignSystem/Apple/Tema.Apple+LineaVita.swift` (`Tema.Apple.Clienti.LineaVita`): padding 18/24, spazio cifre 34, sopra cifre 10, sopra grafico 8, altezza grafico 130 (+10 per la scritta), sopra linea 4, altezza linea 104, binario y 78 alto 2, tacca y 74 1×10, numeri y 86, passo file 25, margine gettoni 70, gettone padding 5/12 bordo 2, opacità zona .06, area .28, tratteggio [2, 4] opacità .7, raggio punto 6, scala 1,08, limiti di trascinamento (§4).

---

### 3. Movimento

#### 3.1 All'apertura della scheda
- **Card**: entra nella cascata del dossier (`.st`): da opacità 0, y +18, scala .985, sfocatura 6 a fermo, **720 ms**, `cubic-bezier(.22,1,.36,1)`, passo 48 ms (`entrataDossier`). Cambio di scheda: il contenuto di prima esce in 130 ms (opacità 0, y +6), poi entra il nuovo.
- **Curva**: si disegna da sinistra (`path.draw` → `disegnaLinea`): ritardo **150 ms**, **1500 ms**, `cubic-bezier(.22,1,.36,1)` → `TracciatoGrafico` con `indice: 0`.
- **Area, zona pensione, righe degli eventi, punto rosso, gettoni**: compaiono subito, senza animazione propria (vengono con la card). Proposta per Prisma: l'area segue la dissolvenza delle aree (`fadeA`, .9 s dopo .6 s) come in Nel tempo, per non mostrare l'area piena prima della linea (dubbio 8).
- **Cifre**: «A … in pensione» e «Al massimo» si contano da 0 in **1100 ms** con `1 − (1−t)^4` (`NumeroCheConta`, `Moto.Curva.quartica`). «Il patrimonio basta» non si conta: compare già scritto.

#### 3.2 Durante il trascinamento
- Ogni movimento del puntatore ricalcola e ridisegna **senza animazione**: curva, area, zona pensione, righe, punto rosso, cifre (scritte di colpo, non contate), etichetta «A {età} anni, in pensione».
- Il gettone segue il puntatore a scatti di un anno (posizione arrotondata all'anno intero).
- Presa: ombra più ampia in .2 s.

#### 3.3 Al rilascio
- Il gettone fa un piccolo rimbalzo: scala **1,08 → 1** in **350 ms**, `cubic-bezier(.34,1.6,.64,1)` (molla con superamento; in SwiftUI la molla equivalente di `Moto`, §5.3 della specifica Apple). L'ombra torna in .2 s.
- Il ricalcolo è già fatto durante il trascinamento: al rilascio non succede altro (in Prisma: si salva, §4).

#### 3.4 Riduci movimento e istantanee
- Template: `ridotto` porta a 1 ms cascata, conteggi e linea; il rimbalzo del gettone **non** è protetto (in Prisma va tolto).
- Prisma con `\.prismaCalmo`: tutto compare fermo con la dissolvenza di 0,15 s; niente rimbalzo, il gettone si posa e basta; il ridisegno durante il trascinamento resta (è la risposta al gesto, non un'animazione).
- Istantanee (`\.modoIstantanea`, `\.prismaStatoFinale`): curva tracciata, cifre complete, gettoni fermi.

---

### 4. Interazioni

- **Trascinare un gettone di evento** (puntatore premuto, `pointer capture`): l'età diventa `round((x − sinistra)/larghezza × (90 − oggi) + oggi)`, limitata fra **età di oggi + 1** e **88**. Si aggiornano gettone, «{età} anni» e tutto il grafico.
- **Trascinare «Pensione»**: stessa regola, limitata fra **55** e **72**. Cambia anche l'etichetta della prima cifra e la zona viola.
- **Rilascio**: rimbalzo (§3.3). Nel template le modifiche si perdono cambiando scheda o cliente (`vitaS` è una copia di `VITA`).
- **Nessun clic** sui gettoni, nessun passaggio del puntatore, nessuna tastiera, nessun pulsante «ripristina» nel template.

Proposte per Prisma (da confermare, dubbi 2-5):
- **Salvataggio**: al rilascio la nuova età si scrive nel dossier (anno dell'evento = anno di nascita + età; pensione → `DatiLavoro.etaPensione` o `IpotesiPrevidenza.etaPensione`), con «Annulla» (⌘Z) come per le altre modifiche del dossier. In alternativa una prova «che succede se» non salvata con il pulsante «Salva nel dossier», come nel dettaglio dell'obiettivo.
- **Doppio clic o clic su un gettone**: apre la modifica dell'evento (tipo, nome, anno/mese, importo, una volta o per N anni, nota) nel dettaglio che nasce dal gettone (§1.8 della specifica Apple).
- **Aggiungere un evento**: pulsante «＋ Evento» nella riga del titolo, o clic sul binario vuoto all'età puntata.
- **Tastiera / accessibilità**: ogni gettone è focalizzabile; ← → spostano di un anno, ⇧← ⇧→ di cinque; VoiceOver legge «Casa, 40 anni, uscita di 40.000 euro, regolabile».
- **Passaggio del puntatore sul grafico** (proposta leggera): una riga verticale con età e patrimonio di quell'anno.
- **Modalità cliente e presentazione**: la scheda si mostra (è fatta per il cliente) ma senza note interne degli eventi.

---

### 5. Mappa verso Prisma

#### 5.1 Cosa c'è già (verificato in `Sources/Prisma`)
| Bisogno | Esiste | Dove |
|---|---|---|
| Schede del dossier | `enum SchedaCliente` (`.panoramica … .nelTempo`), `titolo` | `Shell/StatoShell.swift` r. 3070 |
| Segmentato a pillola del dossier | `SchedaCliente.delSegmentato = [.panoramica, .obiettivi, .nelTempo, .famiglia]`, `scorreNelDossier` | `Shell/DossierApple.swift` r. 23-32 |
| Contenuto delle schede | `schedaDossier(_:_:)` | `Shell/AppClienti.swift` r. 182 |
| Cascata della scheda | `entrataDossier(_:)`, `AvvioCascataDossier` | `Shell/DossierApple.swift` |
| Modello di scheda simile (grafico a tutta card) | `NelTempoDossier`, valori in `Tema.Apple.Clienti.NelTempo` | `Shell/DossierNelTempo.swift`, `DesignSystem/Apple/Tema.Apple+NelTempoFamiglia.swift` |
| Linea che si disegna, area | `TracciatoGrafico(punti:colore:spessore:area:indice:)` | `DesignSystem/Apple/GraficiApple.swift` r. 206 |
| Numeri che si contano | `NumeroCheConta`, `FormatoCifra` | `DesignSystem/Apple/CifreApple.swift` |
| Curve e molla | `Tema.Apple.Moto.Curva` (`uscita` = .22,1,.36,1; `molla`; `quartica`) | `DesignSystem/Apple/TemaAppleMoto.swift` |
| Colori | `Colore.stima`/`anello3`, `anello1`, `arancio`, `rosso`, `verde`, `separatore`, `cardPiena` | `DesignSystem/Apple/TemaApple.swift` |
| Eventi della vita | `EventoVita` (`id`, `tipo`, `anno`, `nota`), `ProfiloBisogni.eventi` | `Dati/Bisogni.swift` r. 96, 142 |
| Eventi dai colloqui | `EstrattoreIncontro` (`.evento(tipo, anno)`); `StatoShell` aggiunge `EventoVita` | `Motori/EstrattoreIncontro.swift`, `Shell/StatoShell.swift` r. 1551 |
| Età | `Cliente.dataNascita`, `Cliente.eta`, `MotorePensionePubblica.etaAl` | `Dati/Modelli.swift`, `Motori/MotorePensionePubblica.swift` r. 262 |
| Patrimonio netto di oggi e serie delle posizioni | `MotorePatrimonio.calcola` → `PatrimonioNelTempo` (`nettoOggi`, `versamentiAnnui`, `traguardi`), `serie(_:anni:)` | `Motori/MotorePatrimonio.swift` |
| Età di pensione | `DatiLavoro.etaPensione`, `IpotesiPrevidenza.etaPensione` | `Dati/Modelli.swift` r. 227, `Dati/Analisi.swift` r. 121 |
| Pensione pubblica netta | `MotorePensionePubblica.stima(cliente:previdenza:)` → `StimaPensione.nettaMensile`; `pensioneDaUsare` | `Motori/MotorePensionePubblica.swift` |
| Reddito desiderato in pensione | `IpotesiPrevidenza.redditoDesiderato` (netto mensile, euro di oggi) | `Dati/Analisi.swift` |
| Rendita integrativa | `MotorePrevidenza.calcola` → `EsitoPianoPrevidenziale` | `Motori/MotorePrevidenza.swift` |
| Inflazione e rendimento predefiniti | `IpotesiCalcolo.inflazione`, `rendimentoPredefinito`, `aliquotaPredefinita` | `Motori/Proiezione.swift` |
| Fisco | `RegoleFiscali.irpef`, `MotoreFiscale.aliquotaGuadagno`; `MotoreSuccessione` per un'eredità | `Motori/MotoreFiscale.swift`, `Motori/MotoreSuccessione.swift` |
| Obiettivi con importo e scadenza | `Obiettivo` (`importo`, `scadenza`) | `Dati/Prodotti.swift` r. 172 |

**Attenzione:** `MotorePianificazione` (`Motori/MotorePianificazione.swift`) è il motore dell'**agenda** (festività, spazi liberi, orari): non c'entra con la pianificazione patrimoniale e non va usato né esteso qui. Serve un motore nuovo con un nome diverso.

#### 5.2 Cosa manca
1. **Scheda**: `case lineaVita` in `SchedaCliente` con titolo «Linea della vita»; `delSegmentato = [.panoramica, .obiettivi, .lineaVita, .nelTempo, .famiglia]`; `scorreNelDossier` false (la card prende l'altezza che resta); ramo in `schedaDossier`; collegamento dalla voce Novità 8 (`StatoShell.apri` con cliente e scheda). Verificare che 5 segmenti stiano nella testata anche nella finestra stretta (nel template 483 di larghezza) e su iPad (`iOS/TavoloiPad.swift` gestisce già `.nelTempo`).
2. **Vista**: `Shell/DossierLineaVita.swift` (`LineaVitaDossier`): riga del titolo, tre cifre, grafico (Canvas o `Shape` con zona, area, `TracciatoGrafico`, righe, punto), linea del tempo con gettoni trascinabili (`DragGesture` con passo di un anno). Il trascinamento lavora su una copia locale e calcola **in modo sincrono e leggero** (≤ 60 passi annui per ricalcolo), niente cache asincrona durante il gesto.
3. **Componente**: `GettoneEventoApple` (capsula con bordo 2, presa, rimbalzo) in `DesignSystem/Apple/`, da mostrare anche nella `VetrinaApple`.
4. **Tema**: `DesignSystem/Apple/Tema.Apple+LineaVita.swift` (§2.5) e `Tema.Apple.Moto.LineaVita` (rimbalzo 0,35 s, scala 1,08, ombra presa 0,2 s).
5. **Motore**: `Motori/MotoreLineaVita.swift` (§5.3).
6. **Testi**: `Motori/TestiLineaVita.swift` (le frasi di §1.2 e §6).
7. **Ruby**: nel contesto del cliente (`Ruby/ContestoRuby.swift`) le cifre della linea della vita (età di esaurimento, patrimonio alla pensione), così Ruby le racconta senza ricalcolarle.

#### 5.3 Motore nuovo: `MotoreLineaVita`
Ingresso (`IngressoLineaVita`): età di oggi, età di pensione, patrimonio di partenza, risparmio annuo fino alla pensione, prelievo annuo in pensione, rendimento reale, eventi (età, importo, una volta o per N anni). Uscita (`EsitoLineaVita`): `punti: [(eta: Int, valore: Double)]` da oggi a 90, `allaPensione`, `massimo` (con `etaMassimo`), `etaEsaurimento: Int?`, `avvisi`, `ipotesi` (righe di metodo come `StimaPensione.metodo`).

Passo annuo (come il template, ma con i dati di Prisma):
`x(a) = x(a−1) × (1 + r) + (a < pensione ? risparmio : −prelievo) + eventi dell'anno a`; esaurimento = primo `a` con `x < 0`; nel grafico i valori sotto zero si mostrano a 0.

Da dove vengono i termini (proposta):
- **età di oggi**: `Cliente.dataNascita` (`MotorePensionePubblica.etaAl`); senza data di nascita la scheda non si calcola (§6);
- **età di pensione**: `DatiLavoro.etaPensione`, se no `IpotesiPrevidenza.etaPensione` dell'Analisi 360, se no `RegolePensione.etaVecchiaia` (67) segnata come ipotesi;
- **patrimonio di partenza**: `MotorePatrimonio.calcola(...).nettoOggi`, cioè le posizioni in essere (con o senza immobili: dubbio 6);
- **rendimento**: un rendimento **reale** (euro di oggi), coerente con `IpotesiPrevidenza.rendimentoReale` o con la media pesata dei rendimenti delle posizioni meno `IpotesiCalcolo.inflazione`; il 2,5% nominale fisso del template non si usa;
- **risparmio annuo fino alla pensione**: i versamenti delle posizioni (`PatrimonioNelTempo.versamentiAnnui`) più il risparmio libero dichiarato (campo nuovo);
- **prelievo annuo in pensione**: `max(0, redditoDesiderato − pensione pubblica netta − rendita integrativa) × 13` (pensione pubblica da `MotorePensionePubblica.pensioneDaUsare`, rendita da `MotorePrevidenza`; mensilità come `RegolePensione.mensilita`), in euro di oggi;
- **fisco**: i prelievi dal patrimonio pagano l'imposta sul guadagno (`IpotesiCalcolo.aliquotaPredefinita` o `MotoreFiscale.aliquotaGuadagno` media) sulla quota di rendimento; la pensione è già netta (`StimaPensione.nettaMensile`); un'eredità entra al netto dell'imposta di successione se il dato c'è (`MotoreSuccessione.regola`), altrimenti al lordo con l'avviso;
- **eventi**: da `ProfiloBisogni.eventi` con importo; in più (proposta, dubbio 3) gli **obiettivi** con scadenza (`Obiettivo.importo` come uscita all'età della scadenza, meno quanto già `accantonato`: «Casa 40 anni −40.000» di Giulia è proprio l'obiettivo «Anticipo casa»). Un obiettivo e un evento uguali non si contano due volte (stesso tipo/area e stesso anno → uno solo).
- **proposte**: come «Nel tempo», interruttore «Con le proposte · Senza» (proposta, il template non l'ha).

Il motore è puro e veloce (nessun accesso all'archivio): la vista lo chiama a ogni passo del trascinamento.

#### 5.4 Campi nuovi dell'archivio (versione 26, come le altre parti di Orizzonte; nomi proposti)
Tutti facoltativi, letti con `decodeIfPresent` (come `ProfiloBisogni`): un archivio della versione 25 si apre uguale.

| Dove | Campo | Tipo | Note |
|---|---|---|---|
| `EventoVita` | `importo` | `Double?` | € di oggi; > 0 entrata, < 0 uscita; nil = evento senza cifra (si vede sulla linea, grigio, non entra nel calcolo) |
| `EventoVita` | `perAnni` | `Int?` | nil o 1 = una volta; N = ogni anno per N anni (il figlio: 22) |
| `EventoVita` | `titolo` | `String?` | nome libero sul gettone («Un aiuto ai nipoti»); nil = `tipo.nome` |
| `EventoVita` | `mese` | `Int?` (1-12) | già proposto nella parte copilota (08), lo stesso campo |
| `ProfiloInvestitore` | `risparmioAnnuo` | `Double?` | quanto mette da parte ogni anno oltre ai versamenti delle posizioni |
| `IpotesiPrevidenza` (o `Cliente`) | `etaPianificazione` | `Int?` | fine della linea; predefinito 90 (dubbio 1) |

Gli eventi `tipo == .pensione` non servono: la pensione è il gettone viola e l'età sta in `DatiLavoro.etaPensione`. Il backup comprende già `Cliente` intero: `Prisma --prova-backup` deve verificare che un evento con `importo`, `perAnni` e `titolo` torni uguale e che un archivio 25 senza quei campi si apra.

#### 5.5 Prove di calcolo nuove: `Motori/ProvaCalcoliLineaVita.swift`
Collegata da `Motori/ProvaCalcoli.swift` come le altre (`ProvaCalcoliLineaVita.esegui(verificaEsterna)`).
- **LV1** formula del template (r = 2,5%, i cinque clienti di §1.3): Giulia 661.156 a 67 e 674.299 al massimo, nessun esaurimento; Laura esaurimento a 75; Sofia a 81 (tolleranza 1 €).
- **LV2** evento «per N anni»: −4.000 da 41 per 22 anni tocca gli anni 41…62 e non il 63.
- **LV3** trascinamento della pensione di Giulia a 58 → esaurimento a 77 e «A 58 anni» = 387.567 (con la formula del template).
- **LV4** limiti: un evento non va sotto età + 1 né oltre 88; la pensione resta fra 55 e 72.
- **LV5** prelievo: reddito desiderato 2.200, pensione netta 1.400 → prelievo 800 × 13 = 10.400 l'anno; con pensione ≥ reddito desiderato il prelievo è 0, non negativo.
- **LV6** obiettivo ed evento uguali (casa, stesso anno) → un'uscita sola.
- **LV7** dati mancanti: senza data di nascita il motore non calcola e dice perché; senza reddito desiderato il prelievo non è inventato (avviso, curva solo fino alla pensione).
- **LV8** patrimonio che resta sopra zero → «oltre i 90 anni»; patrimonio che tocca esattamente 0 non è esaurimento.

---

### 6. Dati che l'utente deve dare (mai inventarli)

| Dato | Dove si inserisce | Finché manca |
|---|---|---|
| Data di nascita | Anagrafica | la card mostra solo il titolo e la frase «Per disegnare la linea della vita serve la data di nascita di {nome}.» con «Completa l'anagrafica ›» |
| Eventi con importo e durata | Bisogni › Eventi della vita, o il gettone stesso | eventi senza importo: gettone grigio con «senza cifra», non entrano nel calcolo; nessun evento: «Nessun evento nella linea della vita. Aggiungi la casa, i figli, un'eredità: Prisma ricalcola il futuro.» |
| Risparmio annuo libero | Profilo (campo nuovo) | si usano solo i versamenti delle posizioni, con l'avviso «Risparmio libero non indicato: conto solo i versamenti delle posizioni.» |
| Reddito desiderato in pensione | Analisi 360 › Previdenza | il valore predefinito di `IpotesiPrevidenza` (2.200) **non** si usa come dato del cliente: la curva dopo la pensione è tratteggiata e c'è l'avviso «Manca il reddito desiderato in pensione: dopo i {età} anni la linea è solo indicativa.» (dubbio 9) |
| Dati del lavoro e dei contributi (o pensione pubblica a mano) | Profilo › Lavoro, o Analisi 360 | il motivo di `MotorePensionePubblica.motivoAssente`; il prelievo non si calcola |
| Età di pensione | Profilo › Lavoro | 67 con la scritta «ipotesi» sul gettone |
| Rendimento reale atteso | Analisi 360 › Previdenza (`rendimentoReale`) o Impostazioni | ipotesi di Prisma, scritta nelle righe di metodo |

**Dati di prova**: i 5 clienti del template (`DatiDemo`) e i 30 fittizi devono avere eventi con importo, durata e risparmio libero, così la scheda si vede piena; per Giulia gli eventi del template (matrimonio, casa, figlio, eredità) e per Sofia un caso che si esaurisce prima dei 90, per avere nelle istantanee lo stato rosso. Sotto la card, finché il cliente è di prova, la nota `.k` «Dati di prova.» come nelle altre schede.

---

### 7. Istantanee da aggiungere (chiaro e scuro)

Nella famiglia del dossier (430-436 esistono; 437-439 sono liberi):

| Nome | Cosa mostra |
|---|---|
| `437-clienti-linea-vita` / `437-clienti-linea-vita-scuro` | Giulia, scheda Linea della vita, stato finale: curva tracciata, cifre complete, verde «oltre i 90 anni», cinque gettoni |
| `438-clienti-linea-vita-finisce` / `438-clienti-linea-vita-finisce-scuro` | Sofia (o Giulia con la pensione a 58): «fino a {N} anni» in rosso, punto rosso e «finisce a {N} anni» |
| `438-clienti-linea-vita-presa` | un gettone preso (ombra della presa, `z-index` sopra gli altri), per controllare l'ombra che le istantanee normali non mostrano |
| `439-clienti-linea-vita-dati-mancanti` / `-scuro` | cliente senza data di nascita: la frase e il collegamento all'anagrafica |
| `439-clienti-linea-vita-senza-eventi` | cliente senza eventi: curva con la sola pensione e la frase di §6 |
| `439-clienti-linea-vita-stretta` | finestra stretta: gettoni tenuti dentro la card, cinque segmenti nella testata |
| `400-vetrina-apple` (aggiornare) | il `GettoneEventoApple` nei tre colori (entrata, uscita, pensione) |

---

## 8. Incontri › Il copilota dell'incontro

*Parte 08 · titolo della bozza: «08 · Incontri: il copilota dell'incontro»*

Fonte: `Design/template-novita.html`, righe 907-937 (`COP`, `COPC`, `APPS.incontri`, `onda`, `avviaCop`, `schedaCop`, `fineCop`), con il CSS alle righe 110-123 e 204-205.
È la quinta voce di «✦ Le novità» (`NOV[4]`): **«Il copilota dell’incontro» · «Prisma ascolta e capisce mentre parli col cliente»** → `vaiA('incontri')`.
Per tutto ciò che qui non è detto valgono `Design/template-apple-specifica.md` (token, finestra §3.5, dettaglio §2.7, avvisi) e `00-comune.md`.
Le cifre del template (40.000 €, 90 € al mese, 450/550/650 €, 18 minuti) sono dimostrative: nell'app le dà l'ascolto vero e i motori.

Riferimenti visivi (1480×940, palco 1440×900 scalato di 1,0137):
- `orizzonte/chiaro-14-il-copilota-dell-incontro.png`, `orizzonte/scuro-14-il-copilota-dell-incontro.png`: stato «Pronto ad ascoltare».
- `orizzonte/cop/chiaro-a-ascolto.png`, `orizzonte/cop/scuro-a-ascolto.png`: ascolto in corso dopo 9 secondi (4 righe, 2 schede).
- `orizzonte/cop/chiaro-b-verbale.png`, `orizzonte/cop/scuro-b-verbale.png`: il verbale finale aperto.
- `orizzonte/cop/chiaro-c-confermato.png`, `orizzonte/cop/scuro-c-confermato.png`: dopo «Conferma tutto», con l'avviso.
(La cartella `cop/` contiene anche lo script `c.js` con cui ho scattato le tre fasi.)

---

### 1. Cosa si vede

#### 1.1 Intestazione della finestra

- Titolo della finestra (barra con i semafori): **«Incontri»**, icona Incontri.
- Titolo grande: **«Il copilota dell’incontro.»**, sottotitolo maiuscoletto **«DALL’ASCOLTO AI PROSSIMI PASSI»** (il testo sorgente è «Dall’ascolto ai prossimi passi», il maiuscolo lo fa lo stile `.sub`).
- Nessun comando a destra dell'intestazione.

#### 1.2 Colonna di sinistra (`.side`, larga 300)

Dall'alto:

1. Occhiello **«OGGI»** (`.lbl`, sorgente «Oggi»).
2. Gli incontri di oggi, una riga ciascuno (`.rub`): avatar 38, nome in grassetto, sotto «ora · titolo».
   - **«Giulia Rossi»** · «09:30 · Il punto sul progetto casa» — selezionata (`.rub.on`).
   - **«Marco Bianchi»** · «11:00 · Nuovi progetti di famiglia».
3. Scheda verde del consenso: **«✓ Consenso all’ascolto»** e sotto «Giulia ha dato il consenso. Il riconoscimento della voce avviene sul Mac: l’audio non esce mai.»
4. Scheda **«COME FUNZIONA»** (`.lbl`): «Mentre parlate, Prisma riconosce obiettivi, polizze, timori ed eventi. Alla fine conferma tu cosa entra nel dossier.»

#### 1.3 Area principale (`.main`, da x 316 al bordo destro)

**Testata dell'incontro** (scheda `.card.st`, in alto, a tutta larghezza), in riga:
avatar 44 del cliente · titolo **«Il punto sul progetto casa»** con sotto lo stato (`#copStato`) · l'onda della voce (360×44, spinta a destra) · il pulsante.

Lo stato e il pulsante cambiano con la fase:

| Fase | Stato (`#copStato`) | Pulsante | Onda |
|---|---|---|---|
| Pronto | «Pronto ad ascoltare» | **«● Avvia il copilota»**, fondo rosso `--red` | 48 trattini grigi fermi alti 3 |
| Ascolto | «Ascolto · 00:09 · solo sul Mac» (minuti:secondi, ogni secondo) | **«■ Termina»**, fondo `#14202B` | barre rosse che si muovono |
| Concluso | «Incontro concluso · 18 minuti» | torna «● Avvia il copilota», rosso | ferma, grigia |

Nota: il template scrive i minuti come `0${min}` e quindi dopo 10 minuti mostrerebbe «010:00». In Prisma: sempre `mm:ss` fino a 59:59, poi `h:mm:ss`.

**Sotto la testata**, due colonne (spazio 14):

- **Sinistra (flex 1,3): la trascrizione.** Scheda con l'occhiello **«QUELLO CHE VI STATE DICENDO»** (sorgente «Quello che vi state dicendo»). Ogni frase è una riga: a sinistra chi parla (largo 56, grassetto) — il consulente in blu accento («Denis»), il cliente nel colore del suo avatar (Giulia `#C45A75`) — e a destra il testo. Le parole che Prisma ha riconosciuto sono **evidenziate** (pastiglia blu chiara, testo blu, seminegrassetto). Restano visibili al massimo **7 righe**: quando arriva l'ottava, la più vecchia sparisce in alto.
- **Destra (flex 1): le schede.** Finché non c'è niente, al centro: **«Le schede compaiono qui, mentre Prisma capisce.»** Poi, una sotto l'altra, una scheda per ogni cosa capita. Ogni scheda ha il filo colorato a sinistra (4 punti), l'occhiello nel colore del tipo, la frase in grassetto e un pulsante d'azione.

Le cinque schede del template, nell'ordine in cui compaiono (testi esatti):

| # | Occhiello | Frase | Azione | Colore | Nasce dalla frase |
|---|---|---|---|---|---|
| 0 | «Obiettivo riconosciuto» | «Casa tra tre anni · anticipo 40.000 €» | «Aggiorna l’obiettivo» | `#0A84FF` | «Vorremmo comprare **tra tre anni**, ci servono circa **40.000 euro** di anticipo.» |
| 1 | «Polizza di un’altra compagnia» | «Vita intera · circa 90 € al mese» | «Aggiungi a Posizioni» | `#B06E12` | «Sì, una **vita intera** con un’altra compagnia, pago circa **90 euro al mese**.» |
| 2 | «Profilo per questo obiettivo» | ««Non voglio rischiarli» → prudente» | «Annota nel profilo» | `#8B5CF6` | «Però i soldi della casa **non voglio rischiarli**, i mercati mi fanno un po’ paura.» |
| 3 | «Evento della vita» | «Matrimonio · giugno 2027» | «Aggiungi alla linea della vita» | `#E58BA0` | «E a **giugno del 2027** ci sposiamo, quindi qualche spesa in più.» |
| 4 | «Da fare» | «Mandare il confronto 450 / 550 / 650 €» | «Crea l’attività» | `#30B15C` | (Denis) «Perfetto, ti preparo un **confronto** con 450, 550 e 650 euro al mese.» |

Il dialogo completo del template (`COP`), in ordine; le frasi di Denis 1 e 3 non danno schede:

1. Denis: «Allora Giulia, partiamo dalla casa: come sono cambiati i tempi?»
2. Giulia: «Vorremmo comprare tra tre anni, ci servono circa 40.000 euro di anticipo.» → scheda 0
3. Denis: «Bene. Hai altre polizze oltre a quelle che seguiamo insieme?»
4. Giulia: «Sì, una vita intera con un’altra compagnia, pago circa 90 euro al mese.» → scheda 1
5. Giulia: «Però i soldi della casa non voglio rischiarli, i mercati mi fanno un po’ paura.» → scheda 2
6. Giulia: «E a giugno del 2027 ci sposiamo, quindi qualche spesa in più.» → scheda 3
7. Denis: «Perfetto, ti preparo un confronto con 450, 550 e 650 euro al mese.» → scheda 4

Premuto il pulsante d'azione di una scheda, il testo diventa **«✓ Fatto»** in verde (nel template non succede altro).

#### 1.4 Il verbale finale (dettaglio che nasce dal pulsante)

Alla fine dell'ascolto (da solo dopo l'ultima frase, o con «■ Termina») il pulsante diventa «● Avvia il copilota» e da lui nasce un dettaglio **940×520**:

- Occhiello verde: **«INCONTRO CONCLUSO · GIULIA ROSSI»** (sorgente «Incontro concluso · Giulia Rossi»).
- Titolo: **«Il punto sul progetto casa»**.
- ✕ in alto a destra.
- **Colonna sinistra** (flex 1):
  - **«IL VERBALE»**, quattro punti elenco:
    - «• L’acquisto della casa è tra tre anni, con 40.000 € di anticipo.»
    - «• Giulia ha una vita intera con un’altra compagnia, circa 90 € al mese.»
    - «• Per i soldi della casa vuole un profilo prudente.»
    - «• Matrimonio a giugno 2027.»
  - **«LE ATTIVITÀ»**, due righe con il pallino da spuntare:
    - «Mandare il confronto 450 / 550 / 650 € · entro venerdì»
    - «Chiedere la polizza vita intera per il confronto»
- **Colonna destra** (larga 380): **«COSA ENTRA NEL DOSSIER»**, quattro righe con il pallino:
  - «Obiettivo casa: tra tre anni, 40.000 €»
  - «Nuova posizione: vita intera, altra compagnia»
  - «Profilo prudente per l’obiettivo casa»
  - «Linea della vita: matrimonio a giugno 2027»
- In basso a sinistra tre pulsanti: **«Conferma tutto»** (pieno, accento) · **«Scrivi il riepilogo a Giulia»** · **«Più tardi»**.

Con «Conferma tutto» i sei pallini (prima i quattro del dossier, poi le due attività) diventano verdi con la spunta uno dopo l'altro, poi l'avviso in alto: **«Dossier di Giulia aggiornato: 4 modifiche e 2 attività»**.

Da notare: la seconda attività («Chiedere la polizza vita intera per il confronto») **non** è una scheda dell'ascolto: nasce dalla polizza di un'altra compagnia. In Prisma va generata da una regola (§5.3).

#### 1.5 Stati

Il template disegna solo: pronto (consenso già dato), ascolto, schede vuote, verbale, confermato. In Prisma servono anche (testi proposti, da approvare):

- **Consenso non ancora dato.** Scheda del consenso in arancio (`avvisoFondo`/`avvisoBordo`): «Consenso all’ascolto» · «Prima di ascoltare, chiedi a {nome} il consenso. Il riconoscimento della voce avviene sul Mac: l’audio non esce mai.» con il pulsante «Registra il consenso». Il pulsante «● Avvia il copilota» è spento.
- **Nessun incontro oggi.** Al posto delle righe di «Oggi»: «Nessun incontro in agenda oggi.» e il pulsante «Ascolta un incontro senza appuntamento» (sceglie il cliente).
- **Microfono non permesso / riconoscimento non disponibile.** Stato sotto il titolo in rosso con il motivo che dà `AscoltoRuby` (es. «La dettatura classica non conosce l'italiano su questo Mac.»); pulsante spento.
- **Preparazione.** «Mi preparo ad ascoltare…» (stato `.prepara` di `AscoltoRuby`); il pulsante diventa «Annulla».
- **Qwen non pronto.** L'ascolto funziona lo stesso: le schede vengono dalle regole di Prisma. Sotto l'occhiello delle schede, piccola nota: «Ruby non è pronta: Prisma riconosce con le sue regole.»
- **Nessuna scheda alla fine.** Il verbale mostra «Prisma non ha riconosciuto obiettivi, polizze, timori o eventi.» e in «Cosa entra nel dossier»: «Niente da aggiungere.»; resta «Scrivi il riepilogo» e si possono aggiungere attività a mano.
- **Interrotto** (Mac a riposo, blocco di Prisma, finestra chiusa): l'ascolto si ferma subito, quello che è stato capito resta, lo stato dice «Ascolto interrotto · {durata}» e il pulsante «Riprendi».

---

### 2. Misure e stile

Area contenuto della finestra (`#wc`): 1384×654 (finestra 1408×758, margini 12, sopra 92).

#### 2.1 Colonna di sinistra

- `.side`: larga **300**, alta tutta l'area, raggio **20**, fondo `--panel` (chiaro bianco 0,72 · scuro bianco 0,05), bordo 1 `--sep`, padding **14/12**.
- «Oggi»: `.lbl` (12, peso 600, spaziatura 0,6, maiuscolo, `--ink2`), margine sotto **8**.
- Riga `.rub`: flex, spazio **10**, padding **10** (il CSS base è 9/8, qui forzato a 10), raggio **14**, margine sotto 2; avatar **38** (iniziali 13, peso 600, bianche, gradiente del cliente); nome 14 grassetto; sotto 12 `--ink2` su una riga con i puntini (massimo 200).
  Selezionata: fondo `rgba(0,122,255,.13)` (= `Colore.selezioneVoce`). Al passaggio: fondo `--chip`, transizione 0,25 s.
- Scheda consenso: `.card` con margine sopra **16**, padding **14/16**, **senza ombra**, fondo `rgba(47,163,90,.08)`, bordo `rgba(47,163,90,.22)`, raggio 22. Titolo 13,5 grassetto; testo `.k` (12,5 `--ink2`) con interlinea 1,45, margine sopra 4.
- Scheda «Come funziona»: `.card` margine sopra **10**, padding **14/16**, senza ombra, fondo `--card`; testo `.k` interlinea 1,5, margine sopra 6.

#### 2.2 Testata dell'incontro

- `.card.st`, padding **16/20**, flex centrato, spazio **16**, **senza ombra**, raggio 22, fondo `--card` (chiaro bianco 0,82 · scuro bianco 0,07), bordo `--sep`. Alta circa **78** (avatar 44 + padding).
- Avatar **44** (iniziali 15).
- Titolo 16 grassetto; stato `.k` 12,5 `--ink2`.
- Onda: tela **360×44**, spinta a destra (`margin-left:auto`). **48 barre**, passo **7,5**, larghe **4,5**, raggio **2,2**, centrate a metà altezza (22). Altezza = max(3, a·40).
  - Ascolto: colore `rgba(229,72,77,.85)` (rosso 0,85), a = (0,25 + 0,75·|sin(3,1t + 0,55i)·sin(1,7t + 0,21i)|)·(0,5 + 0,5·sin(0,4i + t)).
  - Fermo: colore `rgba(120,130,140,.35)`, a = 0,08 → tutte alte 3.
- Pulsante `.btn.pri.big`: padding **10/18**, 13,5 peso 600, raggio 99, testo bianco, fondo `--red` `#E5484D` (pronto) o `#14202B` (ascolto).
  Nello scuro `#14202B` quasi sparisce sul fondo della scheda (vedi `cop/scuro-a-ascolto.png`): proposta `Colore.inchiostro` invertito o il grigio pieno `cardPiena` con bordo (dubbio §8).

#### 2.3 Le due colonne

- Contenitore: assoluto da **y 92** (= 78 della testata + 14) al fondo, flex, spazio **14**. Larghezze risultanti: trascrizione ≈ **596**, schede ≈ **458**; alte **562**.
- **Trascrizione**: `.card` padding **18/22**, senza ombra, contenuto ritagliato; occhiello `.lbl`; righe dentro `#trascr` con margine sopra **10**.
  - Riga `.trR2`: flex, spazio **12**, padding **9/0**, testo **15** interlinea **1,5**, filo sotto 1 `--sep`.
  - Chi parla `.chi`: largo **56**, fisso, **13** peso **700**, padding sopra 2. Colori: consulente `--accent` `#007AFF`; cliente = colore scuro del suo avatar (Giulia `#C45A75`, già `Tema.Apple.Colore.Impegno.giulia`).
  - Evidenza `.hl`: fondo `rgba(0,122,255,.13)`, testo `--accent`, raggio **6**, padding **0/4**, peso **600**.
- **Schede**: colonna senza fondo; il vuoto è `.k` **14**, centrato, padding **30**.
  - Scheda `.card.copC`: padding **12/16**, margine sotto **10**, filo a sinistra **4** nel colore del tipo, ombra `--shadow` (questa sì, a differenza delle altre), raggio 22, fondo `--card`.
  - Occhiello `.lbl` **11** nel colore del tipo; frase **15** peso **600**, margine sopra 2; pulsante `.btn` margine sopra **8**, padding **5/11** (12,5 peso 600, fondo `--cardE`, bordo `--sep`, raggio 99). «✓ Fatto» in `--green` `#2FA35A`.
  - Cinque schede alte circa 96 + 10 stanno nei 562 (≈530): con più di cinque la colonna deve scorrere (il template non lo prevede).

Colori dei tipi e token proposti (in `Tema.Apple+Incontri.swift` o nel file del tema di Incontri, mai sparsi):

| Tipo | Colore | Token esistente da riusare |
|---|---|---|
| Obiettivo | `#0A84FF` | `Tema.Apple.Colore.Area.investimenti` (stesso valore, `--r2`) |
| Polizza esterna | `#B06E12` | stesso valore di `canaleIndipendente` (chiaro): **dubbio**, vedi §8 |
| Profilo / timore | `#8B5CF6` | `Tema.Apple.Colore.Area.previdenza` / `stima` (`--r3`) |
| Evento della vita | `#E58BA0` | nuovo `Copilota.evento` (è il chiaro dell'avatar di Giulia) |
| Da fare | `#30B15C` | `Tema.Apple.Colore.Area.liquidita` (`--r1`) |

Meglio dare nomi propri: `Tema.Apple.Colore.Copilota.obiettivo/polizza/profilo/evento/attivita`, con i valori sopra.

#### 2.4 Verbale (dettaglio)

- Dettaglio standard (`DettaglioApple`): contenitore `cardPiena` (`#FFFFFF` / `#283642`), bordo `--sep`, ombra 0 50 90 −30 `rgba(8,40,60,.55)`, raggio 22 → **28**, misura **940×520** centrata nell'area contenuto; contenuto con padding **26/30**; ✕ `.btn` a destra 22, sopra 22, padding 7/11.
- Occhiello `.lbl` in `--green`; titolo carattere display **27**, peso **700**, spaziatura **−0,5**.
- Colonne: margine sopra **20**, spazio **26**; destra larga **380**.
- «Il verbale»: occhiello con margine sotto 6; testo **14,5** interlinea **1,65**.
- «Le attività»: occhiello con margine 16 sopra e 6 sotto. «Cosa entra nel dossier»: occhiello con margine sotto 4.
- Riga `.prep`: flex, spazio **10**, **13,5**, padding **9/0**, filo sotto `--sep`.
  Pallino: **20×20**, raggio pieno, bordo **2** `--track`; spuntato: fondo e bordo `--green`, scala **1,08**, spunta bianca 8×4 con tratti di 2 ruotata −45°. (È lo stesso componente della «Prepara il fascicolo» di template-apple: riusarlo.)
- Pulsanti: riga assoluta a sinistra **30**, in basso **24**, spazio **8**; tutti `.btn.big` (padding 10/18, 13,5); «Conferma tutto» pieno accento.
- Avviso: `Colore.toast` `rgba(15,36,51,.92)`, testo bianco 13, padding 9/16, raggio 99, a 44 dall'alto.

---

### 3. Movimento

Valori dal template; in Prisma i corrispondenti in `Tema.Apple.Moto` (nuovo gruppo `Moto.Copilota`).

| Cosa | Quando | Durata | Curva | Ritardo / passo |
|---|---|---|---|---|
| Testata (`.st`) | apertura dell'app | 0,72 s, da y +18, scala 0,985, sfocatura 6 | `(.22,1,.36,1)` | cascata standard 0,048 |
| Prima riga della trascrizione | dopo «Avvia» | — | — | 0,6 s |
| Riga nuova | entra | **0,35 s**, da y +10 e trasparente | `(.22,1,.36,1)` | — |
| Parole della riga | una alla volta | **0,11 s** per parola | — | l'evidenza compare già mentre la parola arriva |
| Pausa fra le righe | finita una riga | — | — | **0,9 s** |
| Scheda nuova | appena la frase è finita | **0,62 s**, da x +40, scala **0,92**, trasparente | molla `(.34,1.45,.64,1)` | subito dopo l'ultima parola |
| Goccia sull'acqua | con ogni scheda | — | — | goccia piccola (forza 20, raggio 2) nel punto (1200, 300) del palco, cioè sotto la colonna delle schede |
| Onda | durante l'ascolto | continua (rAF) | — | — |
| Riga più vecchia | quando le righe superano 7 | sparisce senza animazione | — | — |
| Fine automatica | dopo l'ultima riga | — | — | 1,8 s |
| Verbale | nasce dal pulsante | **0,62 s**, raggio 22 → 28 | `(.32,1.22,.5,1)` | contenuto montato a 0,17 s, visibile in 0,35 s da 0,16 s |
| Chiusura verbale | ✕, «Più tardi», velo, Esc | **0,46 s** verso il pulsante | `(.32,1.08,.5,1)` | — |
| Spunte di «Conferma tutto» | sei righe | **0,35 s** molla `(.34,1.45,.64,1)` | — | **0,15 s + k·0,26 s** (0,15 · 0,41 · 0,67 · 0,93 · 1,19 · 1,45) |
| Avviso | dopo le spunte | entra in 0,45 s molla, da y −20 | `(.34,1.45,.64,1)` | **1,8 s** dopo il clic; resta 2,4 s |
| Pulsanti | pressione | scala 0,95, 0,25 s | molla | — |

In Prisma, nell'ascolto vero:
- le parole **non** escono a tempo fisso: arrivano dal riconoscimento (risultati parziali). Si animano solo le parole nuove (dissolvenza 0,11 s); una correzione del riconoscimento sostituisce la coda della riga senza animazione;
- la riga si chiude al silenzio (`AscoltoRuby.Tempi.pausa`, 1,5 s) e solo allora parte l'estrazione e l'eventuale scheda;
- l'onda segue il microfono (`AscoltoRuby.livello`): 48 valori, l'ultimo entra a destra a ogni pezzo d'audio; niente Timer (la vista si aggiorna quando `livello` cambia). L'onda di oggi (`OndaRuby`, 24 barre fisse) non basta: serve un'onda «nastro» nuova;
- il contatore dei secondi: `TimelineView(.periodic(from:by: 1))`, solo durante l'ascolto.

**Riduci movimento** (`\.prismaCalmo`). Il template riduce solo le parole (1 ms), la cascata e il verbale; la riga e la scheda nuova restano animate. In Prisma, per la regola del tema: righe, parole e schede compaiono con la dissolvenza di 0,15 s, senza spostamento né molla; verbale già al centro in 0,15 s; spunte senza scala, tutte insieme; niente goccia (l'acqua è già ferma). L'onda resta (è un'informazione: dice che il microfono sente), ma senza interpolazione fra un valore e l'altro.

**Istantanee** (`\.modoIstantanea`, `\.prismaStatoFinale`): tutto nello stato finale: righe complete con le evidenze, schede ferme, onda con una forma fissa di esempio (la stessa a ogni scatto), contatore fisso, spunte già messe nella variante «confermato».

---

### 4. Interazioni

- **«● Avvia il copilota»**: avvia l'ascolto (prima i permessi, poi la preparazione del riconoscimento). Durante l'ascolto lo stesso pulsante è **«■ Termina»** e chiude l'incontro aprendo il verbale. Spento senza consenso.
- **Righe di «Oggi»**: un clic sceglie l'incontro (nel template non succede niente: in Prisma cambia testata, consenso e schede). Durante l'ascolto le altre righe sono spente: un solo ascolto alla volta.
- **Pulsante della scheda** («Aggiorna l’obiettivo», «Aggiungi a Posizioni», «Annota nel profilo», «Aggiungi alla linea della vita», «Crea l’attività»): nel template diventa solo «✓ Fatto». In Prisma **segna la scheda come confermata** (non scrive ancora nel dossier: si scrive tutto insieme al verbale, così un ripensamento non lascia tracce); nel verbale la voce corrispondente arriva già spuntata. Proposta: un secondo clic toglie la conferma («✓ Fatto» → testo originale).
- **Scheda, clic sulla frase** (proposta): evidenzia nella trascrizione la riga da cui nasce.
- **Scheda, menu contestuale** (proposta): «Correggi…» (apre i campi: importo, anno, premio), «Scarta».
- **Parola evidenziata, passaggio del puntatore** (proposta): illumina la scheda che ha generato.
- **Verbale**:
  - «Conferma tutto»: scrive nel dossier tutte le voci di «Cosa entra nel dossier» e crea le attività; spunte a cascata; avviso «Dossier di {nome} aggiornato: {n} modifiche e {m} attività» (singolari: «1 modifica», «1 attività»; senza attività: «… aggiornato: 4 modifiche»).
  - Clic su una riga del verbale (proposta): toglie o rimette la spunta prima di confermare, così si può confermare solo una parte («Conferma tutto» diventa «Conferma le scelte»).
  - «Scrivi il riepilogo a Giulia»: chiude il verbale **subito** (senza tornare al pulsante) e apre Messaggi sull'occasione «riepilogo dell'incontro» di quel cliente (parte 05, `selM=0`). Le voci non confermate restano in sospeso.
  - «Più tardi», ✕, clic sul velo, Esc: chiude il verbale verso il pulsante. L'incontro resta «concluso, da confermare»: un richiamo nel cruscotto («Da confermare: incontro con Giulia») riapre il verbale.
- **Tastiera** (proposta; il template non ne ha): Esc chiude il verbale (c'è già nel dettaglio); ⌘↩ = «Conferma tutto» nel verbale; nessuna scorciatoia per avviare l'ascolto (deve essere sempre un gesto voluto).
- **Hover**: righe `.rub` fondo `--chip`; pulsanti luminosità 0,97.

---

### 5. Mappa verso Prisma

#### 5.1 Cosa c'è già (verificato con grep in `Sources/Prisma`)

| Serve per | Esiste | Dove |
|---|---|---|
| Ascolto dal microfono, permessi, preparazione, livello per l'onda, stati `fermo/prepara/ascolta/capisce/nonDisponibile` | `AscoltoRuby` (`avvia(_:)`, `trascritto`, `livello`, `concluso`, `problema`, `Tempi`) | `Ruby/AscoltoRuby.swift` |
| Riconoscimento della voce sul dispositivo | protocollo `TrascrizioneRuby` (`aggiungi`, `finisci`, `annulla`), `TrascrizioneClassica` (SFSpeechRecognizer), `TrascrizioneNuova` (macOS 26), `Trascrizioni.prepara`, `SceltaRiconoscimento` | `Ruby/TrascrizioneRuby.swift` |
| Prova del riconoscimento senza microfono | `ProvaRiconoscimento` (voce sintetica → riconoscimento) | `Ruby/ProvaRiconoscimento.swift` |
| Incontro | `Incontro` (`clienteId`, `titolo`, `data`, `appuntamentoId`, `stato .preparazione/.concluso`, `appunti`, `decisioni`, `prossimaAttivita`…), `DatiPrisma.incontri` | `Dati/Incontro.swift`, `Dati/DatiPrisma.swift` r. 14 |
| App Incontri a tre passi (Preparazione · Ascolto con le tre domande scritte · Prossimi passi) | `AppIncontri`, `SchedaIncontro` (`preparazione, ascolto, passi`) | `Shell/AppIncontri.swift`, `Shell/StatoShell.swift` r. 44 |
| Estrazione dagli appunti | `EstrattoreIncontro.conRegole`, `.frasi`, `.anno(in:oggi:)`, `.daRisposta` (formato a righe per Qwen), `.unisci`; `PropostaIncontro` (`.bisogno`, `.evento`, `.attivita`, `fonte`, `origine`) | `Motori/EstrattoreIncontro.swift` |
| Obiettivi | `Obiettivo` (`area`, `importo`, `scadenza`, `priorita`, `versamentoMensile`…) | `Dati/Prodotti.swift` r. 172 |
| Posizioni | `Posizione` (`canale`, `stato .inEssere/.proposta/.chiusa`, `area`, `emittente`, `premio`, `frequenza`…) | `Dati/Posizione.swift` r. 136 |
| Eventi della vita | `EventoVita` (`tipo` con `.matrimonio`, `anno`, `nota`), `ProfiloBisogni.eventi` | `Dati/Bisogni.swift` r. 96, 142 |
| Profilo dell'investitore | `ProfiloInvestitore.Propensione` (`prudente, moderata, dinamica, aggressiva`) | `Dati/Modelli.swift` r. 283 |
| Attività | `Attivita` (`clienteId`, `titolo`, `scadenza`, `Priorita`) | `Dati/Modelli.swift` r. 416 |
| Appuntamenti di oggi | `Appuntamento` (`inizio`, `titolo`, `clienteId`, `stato`) | `Dati/Modelli.swift` r. 344 |
| Ponte cifrato iPad/iPhone ↔ Mac | `PonteRuby` (`sigilla`, `apri`, `percorsiAmmessi` = solo `api/chat`, `v1/chat/completions`), `BustaPonte`, `ServerPonteRuby` (switch sui percorsi), `FornitorePonte` | `Ruby/PonteRuby.swift`, `Ruby/ServerPonteRuby.swift` |
| Qwen | `FornitoreModello`, `FornitoriRuby.crea`, istruzioni in `Ruby/` | `Ruby/FornitoreModello.swift`, `Ruby/MotoriRuby.swift` |
| Controllo dei numeri di Qwen | `CommentoRuby.numeriConservati` | `Ruby/CommentoRuby.swift` |
| Dettaglio che nasce dall'elemento | `StatoDettaglio`, `.origineDettaglio(id:)`, misura W×H | `DesignSystem/Apple/DettaglioApple.swift` |
| Goccia sull'acqua | `RispostaAcqua.condivisa.goccia(in:peso:)` (si lascia cadere da sola con riduci movimento e nelle istantanee) | `DesignSystem/SfondoAcquaRisposta.swift` |
| Avviso | `StatoShell.mostraAvviso(_:)` | `Shell/StatoShell.swift` r. 3010 |
| Onda della voce (fissa, 24 barre) | `OndaRuby` | `Shell/AppRuby.swift` r. 913 |
| Colori | `Colore.accento/rosso/verde/selezioneVoce/toast/avvisoFondo/avvisoBordo`, `Colore.Area.*`, `Colore.Impegno.giulia` (#C45A75) | `DesignSystem/Apple/TemaApple.swift` |
| Messaggi (riepilogo dell'incontro) | parte 05: `MotoreMessaggi`, occasione `.riepilogoIncontro` | `spec/05-messaggi.md` |

#### 5.2 Dove va nell'app

Oggi Incontri lavora sul cliente attivo con tre passi. Il template mostra invece **«Oggi»** (gli incontri del giorno) e un'unica schermata d'ascolto. Proposta:

- la colonna «Oggi» viene dagli `Appuntamento` di oggi con un cliente, ordinati per ora; scegliendone uno si apre (o si crea) l'`Incontro` collegato (`appuntamentoId`);
- il passo **«Ascolto»** di `AppIncontri` diventa la schermata del copilota; le tre domande scritte e gli appunti restano raggiungibili (un segmento «Copilota · Appunti», o gli appunti sotto la trascrizione: dubbio §8);
- il verbale confermato alimenta il passo «Prossimi passi» (le attività create e le proposte già confermate risultano fatte).

#### 5.3 Cosa manca

1. **Ascolto lungo.** `AscoltoRuby` è fatto per una frase: si ferma al silenzio (1,5 s) e dopo al massimo 50 s. Per un incontro (30-90 minuti) serve una modalità continua: nuovo `Ruby/AscoltoIncontro.swift`, `final class AscoltoIncontro: ObservableObject`, che riusa `MicrofonoRuby` e `TrascrizioneRuby` ma:
   - tiene acceso il microfono per tutto l'incontro e spezza in **righe** al silenzio (stessa soglia `sogliaVoce` e `pausa`);
   - riavvia il riconoscimento a ogni riga (la dettatura classica ha un limite di circa un minuto per richiesta; `TrascrizioneNuova` regge i testi lunghi);
   - pubblica `righe: [RigaTrascrizione]`, `rigaInCorso: String`, `livelli: [Float]` (gli ultimi 48), `inizio: Date?`, `stato`;
   - si ferma da solo con il blocco di Prisma, il Mac a riposo, la chiusura della finestra (come lo sfondo).
   Memoria: solo testo, niente audio conservato; righe oltre le ultime 200 restano nell'incontro ma non nella vista.
2. **Chi parla.** Il riconoscimento di Apple non distingue le voci. Opzioni (dubbio §8): (a) un solo microfono e nessuna etichetta, o «Tu / {Cliente}» scelto a mano con un tocco sulla riga; (b) **due microfoni**: il Mac per il consulente e l'iPad (o l'iPhone) davanti al cliente, ognuno trascrive sul proprio dispositivo e l'iPad manda solo il testo al Mac sul ponte; l'etichetta viene dalla sorgente. Il template, con «Denis» e «Giulia», presuppone (b) o una separazione automatica.
3. **Ponte iPad.** Nuovi percorsi in `PonteRuby` (fuori da `percorsiAmmessi`, che resta solo per Qwen) gestiti da un nuovo `case` in `ServerPonteRuby`:
   - `copilota/riga` (iPad → Mac): `{incontroId, chi, testo, inizio, finale}` sigillato con `BustaPonte`; il Mac la aggiunge alla trascrizione e restituisce le schede nuove;
   - `copilota/stato` (Mac → iPad, a richiesta): righe e schede correnti, per mostrare il copilota anche sull'iPad.
   L'audio non passa mai sul ponte: «l’audio non esce mai» vale per ogni dispositivo. Su iPad la schermata segue `Design/tema-liquid-glass.html`; sull'iPhone (`Design/iphone.html`): in alto grande lo stato e l'onda, sotto l'ultima scheda, il resto a un tocco.
4. **Estrattore del copilota.** Nuovo `Motori/EstrattoreCopilota.swift`, che parte da `EstrattoreIncontro` ma lavora frase per frase e restituisce schede con le cifre e i punti da evidenziare:
   ```swift
   struct SchedaCopilota: Identifiable, Codable, Hashable {
       enum Tipo: String, Codable { case obiettivo, polizzaEsterna, profilo, evento, attivita }
       var id: String                  // stabile: tipo + chiave (es. "obiettivo-casa"), così la stessa cosa detta due volte aggiorna la scheda
       var tipo: Tipo
       var titolo: String              // «Casa tra tre anni · anticipo 40.000 €», costruito dall'app con frasi fisse
       var azione: String              // «Aggiorna l’obiettivo» / «Crea l’obiettivo» se il cliente non ce l'ha
       var rigaId: String              // la riga da cui nasce
       var evidenze: [Range<Int>]      // posizioni (in caratteri) delle parole da evidenziare
       var cifre: CifreScheda          // importo, anno, mese, premio, frequenza, area, propensione… (tutto opzionale)
       var origine: String             // "Regole di Prisma" o "Qwen"
       var confermata = false
   }
   enum EstrattoreCopilota {
       static func leggi(_ riga: RigaTrascrizione, contesto: ContestoCopilota, oggi: Date) -> [SchedaCopilota]
       static func verbale(_ schede: [SchedaCopilota], cliente: Cliente) -> VerbaleCopilota
   }
   ```
   Regole nuove (le cifre sempre lette dalla frase, mai inventate):
   - **importi**: «40.000 euro», «40 mila euro», «90 euro al mese», «450, 550 e 650 euro al mese» (elenchi), con la frequenza («al mese», «all'anno»);
   - **tempi**: «tra tre anni» con i numeri in lettere (oggi `anno(in:)` capisce solo le cifre), «a giugno del 2027» con il **mese**;
   - **obiettivo**: verbo d'acquisto/desiderio + parola dell'area (già in `paroleArea`) + importo o tempo → `.obiettivo`; se il cliente ha già un obiettivo di quell'area, azione «Aggiorna l’obiettivo», altrimenti «Crea l’obiettivo»;
   - **polizza esterna**: «polizza», «vita intera», «TCM», «infortuni», «fondo pensione»… + «con un'altra compagnia / con la banca / da un altro» → `.polizzaEsterna` con premio e frequenza;
   - **timore → profilo**: «non voglio rischiare», «mi fanno paura», «tranquill», «senza perdere» → propensione **prudente** legata all'obiettivo di cui si sta parlando (l'ultimo obiettivo citato nell'incontro, o l'area citata nella stessa frase: «i soldi della casa»);
   - **evento**: `paroleEvento` già esistenti, più mese e anno;
   - **attività**: anche alla prima persona e al futuro del consulente («ti preparo», «ti mando», «le invio», «preparo») oltre ai verbi all'infinito di oggi; scadenza dalla frase («entro venerdì», «la prossima settimana»), altrimenti nessuna (dubbio: nel verbale il template scrive «entro venerdì» ma la frase non lo dice);
   - **attività derivate**: ogni polizza esterna senza documento → «Chiedere la polizza {tipo} per il confronto».
   Qwen (se pronto) legge ogni riga finita in background con il formato a righe già usato da `daRisposta` (tipi nuovi: `OBIETTIVO|area|importo|anno|frase`, `POLIZZA|tipo|premio|frequenza|frase`, `PROFILO|propensione|area|frase`, `EVENTO|tipo|anno|mese|frase`, `ATTIVITA|titolo|scadenza`); l'app scarta ogni scheda di Qwen con un numero che non compare nella frase (`CommentoRuby.numeriConservati`). Se Qwen non risponde entro la riga successiva, restano le regole.
5. **Verbale.** `VerbaleCopilota { punti: [String], attivita: [VoceVerbale], dossier: [VoceVerbale] }`, con frasi fisse costruite dalle cifre (es. «L’acquisto della casa è tra {n} anni, con {importo} di anticipo.»). Qwen può solo riformulare, con il controllo dei numeri.
6. **Applicazione al dossier.** `ApplicaCopilota.applica(_ verbale:, scelte:, a dati: inout DatiPrisma) -> EsitoCopilota (modifiche: Int, attivita: Int)`:
   - obiettivo → crea o aggiorna `Obiettivo` (importo, `scadenza` = 1° gennaio… o fine dell'anno indicato: dubbio §8);
   - polizza esterna → nuova `Posizione` `stato .inEssere` con `emittente` «Altra compagnia» (o il nome detto), `premio`, `frequenza`, area dal tipo, e il segno «non seguita da me» (campo nuovo);
   - profilo → `Obiettivo.propensione` (campo nuovo) con la frase del cliente; **non** tocca il `ProfiloInvestitore` ufficiale (questionario);
   - evento → `ProfiloBisogni.eventi.append(EventoVita(tipo:, anno:, nota:))` con il mese (campo nuovo);
   - attività → `Attivita`; idempotente (una seconda conferma non duplica, grazie agli id stabili delle schede).
7. **Consenso.** Registrazione del consenso all'ascolto per incontro (data e ora, modo) prima di accendere il microfono; senza consenso il pulsante è spento.
8. **Vista.** `Shell/CopilotaIncontro.swift` (testata, trascrizione, colonna schede, verbale), `DesignSystem/Apple/OndaNastroApple.swift` (48 barre dal livello del microfono), `DesignSystem/Apple/Tema.Apple+Copilota.swift` (misure §2, colori §2.3, `Moto.Copilota` §3). Il pallino da spuntare del verbale: riusare quello di «Prepara il fascicolo» se c'è già, altrimenti `SpuntaApple`.

#### 5.4 Campi nuovi dell'archivio (versione 26 da 25; da coordinare con le altre parti di Orizzonte)

| Dove | Campo | Tipo | Note |
|---|---|---|---|
| `Incontro` | `consensoAscolto` | `ConsensoAscolto?` (`data: Date`, `modo: .aVoce/.firmato`) | obbligatorio prima dell'ascolto |
| `Incontro` | `ascoltoIniziato`, `ascoltoFinito` | `Date?` | per «Incontro concluso · 18 minuti» |
| `Incontro` | `trascrizione` | `[RigaTrascrizione]` (`id`, `chi: .consulente/.cliente/.sconosciuto`, `testo`, `inizio: Date`, `dispositivo`) | **solo se l'utente sceglie di conservarla** (dubbio §8); altrimenti si cancella alla conferma |
| `Incontro` | `schedeCopilota` | `[SchedaCopilota]` | con `confermata` |
| `Incontro` | `verbaleConfermatoIl` | `Date?` | nil = «da confermare» |
| `Obiettivo` | `propensione`, `fraseCliente` | `ProfiloInvestitore.Propensione?`, `String` | «Non voglio rischiarli» |
| `Posizione` | `altroIntermediario` | `String?` | nil = seguita dal consulente; «Altra compagnia» o il nome |
| `EventoVita` | `mese` | `Int?` (1-12) | serve anche alla Linea della vita (parte 17) |
| `ImpostazioniRuby` (o `Impostazioni`) | `copilotaConservaTrascrizione` | `Bool`, predefinito `false` | |

Tutti con `decodeIfPresent` e un valore predefinito; `Prisma --prova-backup` deve fare il giro completo con un incontro ascoltato (consenso, righe, schede, verbale confermato).

#### 5.5 Prove di calcolo nuove — `Motori/ProvaCalcoliCopilota.swift`

- **CP1** «Vorremmo comprare tra tre anni, ci servono circa 40.000 euro di anticipo.» → una scheda `.obiettivo`, area casa, importo 40.000, anno = corrente + 3 («tre» in lettere); evidenze esattamente su «tra tre anni» e «40.000 euro».
- **CP2** «Sì, una vita intera con un’altra compagnia, pago circa 90 euro al mese.» → `.polizzaEsterna`, tipo vita intera, premio 90, frequenza mensile; attività derivata «Chiedere la polizza vita intera per il confronto».
- **CP3** «Però i soldi della casa non voglio rischiarli…» dopo CP1 → `.profilo` prudente legato all'obiettivo casa.
- **CP4** «E a giugno del 2027 ci sposiamo…» → `.evento` matrimonio, anno 2027, mese 6.
- **CP5** «Perfetto, ti preparo un confronto con 450, 550 e 650 euro al mese.» → `.attivita` «Mandare il confronto 450 / 550 / 650 €», nessuna scadenza inventata.
- **CP6** Le frasi 1 e 3 del dialogo (domande del consulente) → nessuna scheda.
- **CP7** La stessa cosa detta due volte («tra tre anni… anzi tra quattro») → una sola scheda aggiornata (anno + 4).
- **CP8** Verbale dei cinque: 4 punti, 2 attività, 4 voci del dossier, con i testi esatti del §1.4.
- **CP9** `ApplicaCopilota` sul dossier di prova di Giulia → esito 4 modifiche e 2 attività; seconda applicazione → 0 e 0.
- **CP10** Risposta di Qwen con un importo che non è nella frase (`OBIETTIVO|casa|50000|…` sulla frase da 40.000) → scartata.
- **CP11** Avviso: «4 modifiche e 2 attività», «1 modifica e 1 attività», «4 modifiche» (senza attività).
- **CP12** Durata: 18 min → «18 minuti», 1 min → «1 minuto», 75 min → «1 ora e 15 minuti»; contatore 9 s → «00:09», 10 min → «10:00».
- **CP13** Senza consenso `AscoltoIncontro.avvia` non accende il microfono (microfono finto come in `ProvaRuby`).
- **CP14** Righe del ponte: una riga sigillata con il codice sbagliato è rifiutata; con quello giusto entra con `chi = .cliente`.

---

### 6. Dati che l'utente deve dare (mai inventarli)

- **Il testo esatto del consenso all'ascolto** e come va raccolto (a voce e annotato, firmato, dentro l'informativa privacy già firmata?). Finché manca: il testo del template come segnaposto, segnato «dati di prova», e il pulsante «Registra il consenso» annota solo data e ora.
- **Se la trascrizione si conserva** nel dossier o si cancella dopo il verbale, e per quanto tempo. Finché manca: non si conserva (si tiene solo il verbale confermato).
- **Come chiamare il consulente nelle righe** («Denis», «Tu», le iniziali). Finché manca: `Impostazioni.nomeUtente`.
- **Le parole dei timori e la propensione che ne segue** (quali frasi valgono «prudente», quali «moderata»…), e se è lecito annotarla per obiettivo senza rifare il questionario. Finché manca: solo «prudente» per le frasi del template, con l'etichetta «annotazione, non profilo MiFID».
- **I tipi di polizza da riconoscere** e i nomi delle compagnie più frequenti. Finché manca: l'elenco del §5.3 punto 4.
- **La scadenza dell'obiettivo** quando il cliente dice solo «tra tre anni» (fine di quell'anno? stesso giorno fra tre anni?). Finché manca: lo stesso giorno fra tre anni, segnato da confermare nel verbale.
- **Se Alleanza consente la registrazione o la trascrizione degli incontri** per i suoi clienti (regole interne del canale). Finché manca: il copilota resta disponibile, ma con la scritta «Verifica le regole di Alleanza sull'ascolto» sugli incontri di clienti Alleanza.
- Le cifre e i nomi della demo (Giulia, 40.000 €, 90 €, 450/550/650 €, 18 minuti) sono **dati di prova**: nell'app compaiono solo con i clienti del template e un dialogo dimostrativo caricato da Impostazioni («Prova il copilota con un dialogo di prova»), che riproduce le sette righe del §1.3 senza microfono.

---

### 7. Istantanee da aggiungere (chiaro e scuro)

Numerazione 58x (le parti 05-07 usano 52x-56x):

| Nome | Cosa mostra |
|---|---|
| `580-copilota-pronto` / `580-copilota-pronto-scuro` | Giulia selezionata, consenso dato, «Pronto ad ascoltare», schede vuote |
| `581-copilota-senza-consenso` | scheda del consenso in arancio, pulsante spento |
| `582-copilota-ascolto` / `582-copilota-ascolto-scuro` | dialogo di prova a metà: 4 righe, 2 schede, onda fissa, «Ascolto · 00:09 · solo sul Mac» |
| `583-copilota-tutte-le-schede` | 7 righe e le 5 schede, due con «✓ Fatto» |
| `584-copilota-verbale` / `584-copilota-verbale-scuro` | il verbale aperto, pallini vuoti |
| `585-copilota-confermato` | il verbale con le sei spunte e l'avviso |
| `586-copilota-ruby-non-pronta` | ascolto con la nota «Ruby non è pronta: Prisma riconosce con le sue regole.» |
| `587-copilota-microfono-negato` | stato in rosso con il motivo |
| `588-copilota-nessun-incontro` | «Nessun incontro in agenda oggi.» |
| `589-copilota-calmo` | come 582 con Riduci movimento |
| iPad: `ipad-580-copilota-ascolto` / `-scuro` | il copilota sul vetro dell'iPad (tema Liquid Glass) |
| iPhone: `iphone-580-copilota-ascolto` | gerarchia `iphone.html`: stato e onda in alto, ultima scheda sotto |

Le istantanee usano il dialogo di prova (righe e schede scritte nello stato finale, nessun microfono).

---

## 9. Inquadra e capisci

*Parte 09 · titolo della bozza: «09 · Inquadra e capisci»*

Voce 6 del pannello Novità: **«Inquadra e capisci» · «La polizza letta dalla fotocamera dell’iPhone»**.
Nel template: `NOV[5]` (riga 736), `apriScanner()` e `chiudiScanner()` (righe 982-993), CSS righe 194-203.
Schermate: `orizzonte/chiaro-15-inquadra-e-capisci.png` e `scuro-15-…` (a metà lettura, due campi letti),
più quelle scattate per questa parte in `orizzonte/sc09/`: `chiaro-fatto.png`, `scuro-fatto.png` (lettura finita,
con i due pulsanti) e `chiaro-confronta.png`, `scuro-confronta.png` (dopo «Confronta»).

Le cifre del template sono dimostrative. In Prisma ogni valore viene dal documento letto e dai motori.

---

### 1. Cosa si vede

#### 1.1 Da dove si apre

- **Pannello Novità, voce 6.** Porta in Posizioni sulla vista «Portafoglio». Poi lo scanner si apre da solo:
  dopo **500 ms** se Posizioni era già davanti, dopo **900 ms** se no (il tempo che la finestra si apra).
- **Testata di Posizioni.** Accanto ai segmenti «Portafoglio · Prova del fuoco» c'è il pulsante
  **«◎ Inquadra con l’iPhone»** (classe `.btn`, riga 955). Il clic apre lo scanner.

#### 1.2 La scena

Sopra tutta la finestra Prisma (barra, finestra di Posizioni e dock) scende un **velo scuro sfocato**. Su questo velo
stanno due oggetti affiancati:

1. **A sinistra, un iPhone** disegnato: cornice nera con la tacca (Dynamic Island) in alto. Nello schermo si vede
   l'inquadratura della fotocamera, un fondo marrone scuro. Al centro c'è un **foglio di carta**, leggermente ruotato,
   con le righe della polizza. Una **linea verde luminosa** scorre sul foglio (la scansione). In basso, una scritta
   bianca dice cosa sta succedendo.
2. **A destra, una scheda «Prisma sul Mac»**: la sfera di Ruby, l'etichetta, la ✕ per chiudere, un titolo grande e,
   sotto, i dati letti che compaiono uno alla volta.

Il velo e i due oggetti sono uguali in chiaro e in scuro, tranne la scheda di destra, che segue il tema
(`--cardE`: bianca in chiaro, #283642 in scuro).

#### 1.3 Il foglio (nell'iPhone)

Testi esatti, dall'alto:

- intestazione: **«COMPAGNIA ESEMPIO S.P.A.»** (piccola, maiuscola, spaziata, grigia);
- titolo: **«Polizza Vita Intera»**;
- cinque righe etichetta → valore:

| Etichetta | Valore sul foglio |
|---|---|
| Contraente | Giulia Rossi |
| Premio | 90,00 € al mese |
| Capitale assicurato | 50.000 € |
| Decorrenza | 1 marzo 2021 |
| Durata | vita intera |

- sotto, tre righe grigie finte (testo illeggibile della polizza), larghe 80 %, 60 % e 70 %.

#### 1.4 La scritta in basso nello schermo dell'iPhone

Cambia in tre passi:

1. **«Inquadra il documento»** (all'apertura);
2. **«Riconosco i dati…»** (dal primo campo letto);
3. **«✓ Fatto»** (a lettura finita).

#### 1.5 La scheda «Prisma sul Mac»

- riga in alto: sfera di Ruby viva (26 pt) · **«PRISMA SUL MAC»** (etichetta `.lbl`, maiuscola) · ✕ a destra;
- titolo: **«Sto leggendo…»**, che a lettura finita diventa **«Polizza riconosciuta»**;
- righe dei dati, una per campo, ognuna con **✓ verde**, l'etichetta in grigio (colonna di 150 pt) e il valore in
  grassetto. Testi esatti nell'ordine:

| Etichetta | Valore nella scheda |
|---|---|
| Contraente | Giulia Rossi |
| Premio | 90 € al mese |
| Capitale assicurato | 50.000 € |
| Decorrenza | marzo 2021 |
| Tipo | Vita intera · altra compagnia |

  Nota: la scheda non ripete il foglio. Riscrive i valori nella forma di Prisma: «90 € al mese» (senza decimali),
  «marzo 2021» (mese e anno), e al posto di «Durata» mette **«Tipo»**, che unisce tipologia e provenienza.
  Il foglio ha «Durata», la scheda no.

- a lettura finita compaiono **due pulsanti** affiancati:
  - **«Aggiungi a Posizioni di Giulia»** (pulsante pieno blu, `.btn.pri.big`);
  - **«Confronta»** (pulsante chiaro, `.btn.big`).

#### 1.6 Dopo «Aggiungi a Posizioni di Giulia»

Lo scanner si chiude e in alto compare il messaggio (toast):
**«Aggiunta alle posizioni di Giulia, canale: altra compagnia»**.

#### 1.7 Dopo «Confronta»

I due pulsanti **spariscono** e al loro posto entra una tabella in un riquadro (`.tile`), tre colonne:

| | **La sua vita intera** | **Una temporanea** |
|---|---|---|
| Spesa l’anno | 1.080 € | circa 190 € |
| Capitale caso morte | 50.000 € | 160.000 € |
| Valore di riscatto | sì, cresce nel tempo | no |

La prima riga (intestazioni) ha il fondo `--chip` e peso 600. La terza colonna è in blu (`--accent`) e in grassetto.
Sotto la tabella, la nota in grigio:
**«La vita intera accumula anche un valore di riscatto; la temporanea protegge di più a parità di spesa. Cifre indicative.»**

Nel template, dopo «Confronta» non si può più aggiungere la polizza: resta solo la ✕ (vedi Dubbi).

#### 1.8 Stati

Il template ha un solo percorso, sempre riuscito. Non ci sono stati vuoto, errore o «nessun dato trovato».
Per Prisma servono (proposta, testi da confermare):

| Stato | Scheda «Prisma sul Mac» | Scritta nell'iPhone |
|---|---|---|
| In attesa della foto | titolo «Aspetto il documento…», nessuna riga, frase «Sull’iPhone scegli Scansiona documenti» | «Inquadra il documento» |
| Lettura in corso | «Sto leggendo…», le righe compaiono man mano | «Riconosco i dati…» |
| Finito | «Polizza riconosciuta» (o «KID riconosciuto», «Estratto conto riconosciuto», secondo `Documento.Tipo`) | «✓ Fatto» |
| Pochi dati | «Ho letto solo una parte»: le righe trovate e, in grigio senza ✓, quelle che mancano | «✓ Fatto» |
| Illeggibile | «Non riesco a leggere il documento» e il pulsante «Riprova» | «Riprova con più luce» |
| iPhone non raggiungibile | «L’iPhone non risponde» e la frase «Avvicinalo al Mac, con Wi-Fi e Bluetooth accesi» | — |
| Cliente non riconosciuto | il pulsante diventa «Aggiungi a Posizioni di…» con la scelta del cliente | — |
| Archivio in sola lettura | pulsante «Aggiungi…» spento con l'avviso già esistente di `creaDaDocumento` | — |
| Qwen non pronto | la lettura va avanti con le sole regole di Prisma; nessun messaggio in più | — |
| Confronto senza tariffa | nella colonna «Una temporanea» compare «—» e la nota «Manca una tariffa della temporanea» | — |

---

### 2. Misure e stile

Tela del template: `#stage` 1440 × 900. Le posizioni sono assolute rispetto alla tela.

#### 2.1 Velo (`#scan`)

- `position:absolute; inset:0; z-index:97`: copre tutto, sopra il dock e le finestre, sotto il toast (95 è il toast,
  ma il toast compare solo dopo la chiusura);
- fondo `rgba(6,14,20,.55)`, `backdrop-filter: blur(8px)`;
- uguale in chiaro e in scuro.

#### 2.2 iPhone (`.phone`)

- posizione: **left 300, top 100**; misura **300 × 620**, raggio **50**;
- corpo `#0d0f12`; ombra `0 40px 80px -20px rgba(0,0,0,.55)` più filo interno `inset 0 0 0 2px #2a2e34`;
- tacca (`:before`): **92 × 26**, raggio 20, `#000`, a **22** dall'alto, centrata;
- schermo (`.scr`): rientro **11** per lato (quindi 278 × 598), raggio **40**, fondo `#1a1d21`;
- fotocamera (`.cam`): gradiente radiale `500px 400px at 40% 30%`, da `#4a423b` a `#1f1b18`.

#### 2.3 Foglio (`.foglio`)

- **left 30, right 30** dentro lo schermo (larghezza 218), **top 120**;
- fondo `#fbfaf7`, raggio **6**, padding **18 × 16**, ruotato **−3°**, ombra `0 20px 40px rgba(0,0,0,.5)`;
- intestazione: 9 px, peso 700, spaziatura lettere 1 px, `#7a8590`;
- titolo: 15 px, peso 800, margini 4 sopra e 10 sotto, `#1b2530`;
- riga (`.fRiga`): `flex` con etichetta e valore ai lati, 10,5 px, `#4a5560`, padding 5, raggio 5,
  `transition: all .4s`; valore in grassetto `#1b2530`;
- riga letta (`.fRiga.vista`): contorno `0 0 0 2px #34C759` e fondo `rgba(52,199,89,.14)`;
- righe finte: alte 5, raggio 3, `#e8ecef`, margine 12 (la prima) e 5, larghe 80 %, 60 %, 70 %.

Il foglio è sempre chiaro anche in scuro (è carta), come i documenti PDF di Prisma.

#### 2.4 Linea della scansione (`.linea`)

- **left 18, right 18**, alta **3**, parte da **top 110** dello schermo;
- `linear-gradient(90deg, transparent, #34C759, transparent)` con alone `0 0 18px #34C759`.

#### 2.5 Scritta nello schermo (`#scT`)

- in basso a **22** dal fondo, centrata, bianca, **12,5 px peso 600**.

#### 2.6 Scheda «Prisma sul Mac» (`#scMac`)

- classe `.card`: raggio **22**, bordo `1px solid var(--sep)`, ombra `var(--shadow)`; fondo **`var(--cardE)`**
  (pieno, non il `--card` semitrasparente);
- posizione **left 700, top 170**; larghezza **440**; padding **22 × 24**; l'altezza cresce col contenuto;
- riga in alto (`.row`): sfera **26 × 26** (`.sfera.viva`), etichetta `.lbl` (12 px, peso 600, maiuscola,
  spaziatura .6, `--ink2`), ✕ con `.btn` e padding **6 × 10** spinto a destra (`margin-left:auto`);
- titolo: `--fontd` (SF Pro Display), **22 px peso 700**, margine sopra 10;
- blocco righe: margine sopra 8;
- riga dei dati: padding **8 × 0**, filetto sotto `1px solid var(--sep)`, testo 14 px;
  ✓ in `--green` (#2FA35A) peso 700; etichetta `.k` (12,5 px, `--ink2`) larga **150**; valore `<b>` 14 px;
- pulsanti: riga con gap **8**, margine sopra **16**; `.btn.big` padding **10 × 18**, 13,5 px peso 600,
  raggio 99; il primo `.btn.pri` (fondo `--accent` #007AFF, testo bianco, senza bordo);
- tabella del confronto: `.tile` (raggio **18**, fondo `--card`, bordo `--sep`) con padding 0, margine sopra **14**,
  `overflow:hidden`; righe a griglia `1.1fr 1fr 1fr`, 13 px; celle padding **8 × 12**; prima colonna `--ink2`;
  terza colonna peso 700 e `--accent`; intestazione con fondo `--chip` e peso 600; le altre righe con filetto sopra
  `--sep`;
- nota sotto la tabella: `.k` (12,5 px, `--ink2`), margine sopra 8, interlinea 1,45.

#### 2.7 Toast

`#toast`: in alto al centro a 44, fondo `rgba(15,36,51,.92)`, testo bianco 13 px, padding 9 × 16, raggio 99; resta
**2,4 s**. In Prisma è il messaggio già esistente (`mostraAvviso`).

#### 2.8 Nel tema di Prisma

Tutti i valori vanno in `Sources/Prisma/DesignSystem/` (proposta `Tema.Apple.Inquadra`, file nuovo
`DesignSystem/Apple/InquadraApple.swift` o dentro `MisureApple`):

- `velo` rgba(6,14,20,.55), `sfocaturaVelo` 8;
- `telefono` (300 × 620, raggio 50, rientro 11, raggio schermo 40, tacca 92 × 26 raggio 20 a 22),
  `coloreTelefono` #0d0f12, `filoTelefono` #2a2e34, `schermo` #1a1d21, `fotocamera` [#4a423b, #1f1b18];
- `foglio` (#fbfaf7, raggio 6, padding 18 × 16, rotazione −3°, ombra 0/20/40 0,5),
  `inchiostroFoglio` #4a5560, `inchiostroFoglioForte` #1b2530, `intestazioneFoglio` #7a8590, `righeFinte` #e8ecef;
- `verdeLettura` #34C759 (già presente come verde di sistema? verificare in `ColoriApple`; il `--green` dei ✓ è
  #2FA35A, un'altra tinta), `fondoLettura` 14 %;
- `scheda` (larghezza 440, padding 22 × 24), `colonnaEtichetta` 150.

Le posizioni assolute del template (300/100, 700/170) diventano un `HStack` centrato nella finestra con
**100 pt** di spazio tra telefono e scheda e la scheda allineata **70 pt** più in basso del telefono.

---

### 3. Movimento

Tempi dall'apertura (t = 0):

| Quando | Cosa | Durata · curva |
|---|---|---|
| 0 | il velo appare (opacità 0 → 1) | 300 ms, lineare (WAAPI predefinita) |
| 0 | l'iPhone entra da **y +60** e **−4°**, opacità 0 → 1 | **700 ms**, `cubic-bezier(.34,1.3,.64,1)` (molla leggera) |
| 0 → 2,2 s | la linea scende da top 110 a **top 420** in 1,1 s e torna su in altri 1,1 s (`scansiona`, `ease-in-out`, 2 volte `alternate`, `forwards`): **si ferma in alto**, a 110 | 2 × 1,1 s |
| 1300 + i × 450 ms (i = 0…4: 1,30 · 1,75 · 2,20 · 2,65 · 3,10 s) | per il campo i: la scritta diventa «Riconosco i dati…»; la riga i del foglio si illumina (transizione CSS **400 ms**, `ease`); nella scheda entra la riga i da **x −14**, opacità 0 → 1 | riga della scheda **400 ms**, `cubic-bezier(.22,1,.36,1)` (= `Tema.Apple.Moto` uscita) |
| 1300 + 5 × 450 + 300 = **3850 ms** | scritta «✓ Fatto»; titolo «Polizza riconosciuta»; compaiono i due pulsanti | **di colpo**, senza animazione |
| clic «Confronta» | i pulsanti spariscono di colpo; la tabella entra da **y +10**, opacità 0 → 1 | **450 ms**, `cubic-bezier(.22,1,.36,1)` |
| chiusura | il velo con tutto dentro svanisce | **220 ms**, lineare |

Altro:

- la sfera di Ruby respira (`respira`, 4 s, `ease-in-out`, senza fine) e il riflesso gira (`gira`, 6 s, lineare):
  in Prisma è la sfera già esistente;
- se lo scanner si chiude a metà, i passi in attesa non fanno più nulla (ogni `setTimeout` controlla che il velo sia
  ancora aperto).

**Riduci movimento.** Il template non guarda `ridotto` nello scanner. In Prisma vale la regola generale
(`\.prismaCalmo`): velo, telefono e scheda compaiono già fermi con una dissolvenza di 0,15 s; niente linea che
scorre (resta ferma in alto, oppure non c'è); le righe compaiono senza scivolare, una alla volta come arrivano dal
motore (il ritmo lo dà la lettura vera, non un timer).

**Istantanee** (`\.modoIstantanea` + `\.prismaStatoFinale`): tutto nello stato finale, righe tutte presenti, righe
del foglio tutte illuminate, linea ferma in alto, sfera ferma.

**Ritmo in Prisma.** Nel template i 450 ms sono finti. In Prisma le righe entrano quando il dato è davvero trovato:
le regole di `EstrattoreDocumento` danno quasi tutto in un colpo, quindi la scheda le mostra a cascata con passo
**450 ms** (fermo, da `Tema.Apple.Moto`, nome proposto `Moto.Inquadra.passoCampo = 0.45`, `ritardoPrimo = 1.3`
solo se l'immagine è appena arrivata); i campi che arrivano dopo da Qwen entrano quando arrivano. Niente Timer: si
usa `withAnimation(.delay)` o una `Task` con `sleep` come già fanno le cascate del tema.

---

### 4. Interazioni

- **Clic su «◎ Inquadra con l’iPhone»** (testata di Posizioni) o sulla **voce 6** delle Novità: apre lo scanner.
- **Clic su ✕**: chiude (220 ms).
- **Esc**: chiude lo scanner. È il primo dell'ordine di Esc (scanner → Novità → sala → dettaglio → notifiche →
  finestra): con lo scanner aperto Esc chiude solo lui.
- **Clic sul velo** fuori da telefono e scheda: nel template **non fa nulla**. Proposta: lasciare così (chiudere
  per sbaglio a metà lettura sarebbe fastidioso).
- **«Aggiungi a Posizioni di Giulia»**: crea la posizione e chiude, con il toast.
- **«Confronta»**: sostituisce i pulsanti con la tabella.
- Nessun hover particolare oltre a quello dei pulsanti (`.btn`: molla al passaggio, già nel tema). Nessun
  trascinamento. La scheda non si inclina verso il puntatore.
- In Prisma: **Invio** = pulsante principale («Aggiungi…») quando è visibile; **⌘Z** dopo «Aggiungi» annulla come
  per le altre posizioni create (se l'annullamento esiste già in `StatoShell`).

---

### 5. Mappa verso Prisma

#### 5.1 Cosa c'è già (verificato con grep in `Sources/Prisma`)

| Bisogno | Già nel codice |
|---|---|
| Leggere un'immagine o un PDF scansionato sul dispositivo | `Dati/LetturaDocumenti.swift`: `LetturaDocumenti.leggi(_:)` (PDFKit, poi Vision `VNRecognizeTextRequest` accurato, it-IT ed en-US), `riconosci(_:)`, `estensioniAccettate` (pdf, png, jpg, jpeg, tif, tiff, heic). Funziona su Mac e iOS (orientamento EXIF su iOS) |
| Trovare i campi nel testo | `Motori/EstrattoreDocumento.swift`: `conRegole(_:)` → `[CampoEstratto]` con pagina e riga; regole già presenti per **contraente**, **premio** (con `qualificaPremio`), **capitaleAssicurato**, **decorrenza**, **scadenza**, **emittente**, **tipologia**, **nomeProdotto**, **numeroContratto**; `daRisposta` e `unisci` per i campi che completa Qwen; `numero(_:)`, `data(_:)`, `tipoProbabile(_:)` |
| Campi e documenti | `Dati/Documento.swift`: `Documento`, `Documento.Tipo` (`.polizza`…), `CampoDocumento`, `CampoEstratto` (`confermato`, `origine`, `estratto`) |
| Leggere in coda, uno alla volta (8 GB) | `StatoShell.leggiDocumento(_:)` (`Shell/StatoShell.swift` riga 810) con la coda `prisma.lettura-documenti` |
| Aggiungere il file al cliente | `StatoShell.aggiungiDocumenti(_:)` e `importaDocumenti` (`Shell/StatoDocumenti.swift`) |
| Creare la posizione dal documento | `StatoShell.creaDaDocumento(_:cosa:canale:area:confermaPrima:)` con `CreaDaDocumento.posizione` → `creaPosizione(da:canale:area:)` (`StatoShell.swift` riga 1319) |
| Canale e area proposti | `MotoreDocumenti.canaleEArea(_:posizione:prodotto:)` (con `capitaleAssicurato` → `.protezione`; «alleanza» nel testo → `.alleanza`, altrimenti `.indipendente`) |
| Frequenza del premio dalla riga | `MotoreConfrontoDossier.frequenzaPremio(_:)` |
| Confronto documento ↔ posizione già in Prisma | `MotoreConfrontoDossier.confronta(_:con:)` e `StatoConfrontoDossier.swift` (serve se la polizza c'è già: «Aggiorna» invece di «Aggiungi») |
| Spiegazione di Ruby | `Ruby/DocumentiRuby.swift`: `documento(_:fonte:)`, `polizza(_:)`, `confronta(_:fonte:)` |
| Costo di un capitale caso morte | `Motori/MotoreSimulatoriAnalisi.swift`: `TariffaCasoMorte` (premio ogni 1.000 €), `copertureConTariffa`, `tariffaCasoMorte(cliente:archivio:)`, `protezione(_:aggiunta:tariffa:)` |
| Fabbisogno caso morte della famiglia | `MotoreAnalisi.EsitoProtezione` (`fabbisogno`, `capitaleVita`), `Motori/MotoreProtezioneFamiglia.swift` |
| Valore di riscatto | `Motori/MotoreRiscatto.swift`: `calcola(_:prodotto:anni:data:)` → `EsitoRiscatto?` |
| Anteprima dell'immagine con la riga evidenziata | `Shell/AnteprimaDocumento.swift` (`ImmagineDocumento`, `estrattoEvidenziato`) |
| Canale e etichette | `Canale` (`Dati/Modelli.swift`), etichette in vetro dei canali nel tema |
| Ponte cifrato iPhone ↔ Mac | `Ruby/PonteRuby.swift` (`BustaPonte` con `percorso` e `corpo`, `massimoBusta` 4 MB, ChaChaPoly dal codice di abbinamento), `Ruby/ServerPonteRuby.swift` (porta 47620, Bonjour), `Tavolo/ProtocolloTavolo.swift` (porta 47621, connessione che resta aperta) |
| Info.plist dell'iPhone | `Supporto/iOS/Info.plist`: c'è `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, `NSLocalNetworkUsageDescription`; **manca `NSCameraUsageDescription`** |
| Sfera di Ruby, pulsanti, card, tile, toast | `DesignSystem/Apple/` (sfera, `Tema.Apple.Moto`, carte), `mostraAvviso` |

#### 5.2 Da dove arriva la foto: due strade

Il template mostra l'iPhone che inquadra e il Mac che legge. In Prisma la lettura resta sul Mac (o sul telefono),
sempre in locale. Due strade, senza dipendenze esterne:

**Strada A, consigliata per prima: la Fotocamera Continuity di macOS.** Il Mac chiede all'iPhone vicino
«Scansiona documenti» (macOS 10.14 e successivi, quindi va bene con macOS 13). Non serve l'app Prisma sull'iPhone.
Il documento arriva come PDF (o immagine con «Scatta foto») attraverso il sistema, senza rete di Prisma.
In codice: una piccola `NSView` nella gerarchia della scena che fa da `NSServicesMenuRequestor`
(`validRequestor(forSendType:returnType:)` per `.pdf`/`.tiff`/`.png`, `readSelection(from:)` che salva i dati in un
file e chiama `aggiungiDocumenti`). Il pulsante «Inquadra con l’iPhone» apre il menu con la voce di sistema
`NSMenuItem.importFromDeviceIdentifier` (il sistema la riempie con i dispositivi). Mentre l'iPhone scatta, lo scanner
di Prisma mostra lo stato «In attesa della foto». File nuovo: `Shell/ScannerMac.swift`.

Limite: lo schermo vero dell'iPhone mostra l'interfaccia di Apple, non il foglio con la linea verde. Il telefono
disegnato sul Mac allora mostra **l'immagine arrivata**, con la linea che scorre e le righe che si illuminano sopra
i riquadri trovati da Vision (vedi 5.3). È la stessa scena del template, ma con il documento vero.

**Strada B, in un giro successivo: Prisma per iPhone.** Nell'app dell'iPhone, in Posizioni, un pulsante
«Inquadra» apre `VNDocumentCameraViewController` (VisionKit, di sistema, iOS 13+) o, per evidenziare i campi dal
vivo come nel template, `DataScannerViewController` (iOS 16+, i riquadri del testo riconosciuto). La foto va al Mac
con il ponte cifrato:

- percorso nuovo `BustaPonte.documento = "prisma/documento"`; `corpo` = JSON `DocumentoInArrivo`
  (`clienteId?`, `nomeFile`, `dati` JPEG o PDF ≤ 3,5 MB, `quando`);
- `ServerPonteRuby` lo riceve solo se «iPhone e iPad» è attivo, lo mette in una coda `documentiInArrivo` di
  `StatoShell` e apre lo scanner sul Mac;
- l'iPhone, che oggi è una copia in sola lettura, non scrive nell'archivio: manda e basta. La posizione la crea il
  Mac;
- `Supporto/iOS/Info.plist`: aggiungere
  `NSCameraUsageDescription` = «Prisma usa la fotocamera solo per inquadrare polizze e documenti: l’immagine va al
  tuo Mac in rete locale, cifrata, e non lascia mai i tuoi dispositivi.»
  (e togliere dal commento in testa la frase superata su Ruby in rete locale, che è già arrivata).

Il Mac non ha bisogno di `NSCameraUsageDescription` per la strada A (la foto la fa l'iPhone). Da verificare sul Mac
vero alla prima prova.

#### 5.3 Cosa manca

1. **Riquadri del testo.** `LetturaDocumenti.riconosci` restituisce solo righe di testo. Per illuminare i campi sul
   foglio serve anche dove stanno. Proposta: `LetturaDocumenti.riconosciConRiquadri(_:) -> [RigaLetta]` con
   `RigaLetta { testo: String; riquadro: CGRect }` (coordinate normalizzate di Vision, `boundingBox`). Nel
   documento: `CampoEstratto.riquadro: RiquadroPagina?` (nuovo campo opzionale, `x, y, larghezza, altezza` 0…1).
   L'estrattore lo copia dalla riga da cui viene il valore. Per i PDF con testo non c'è (nil) e la scena mostra solo
   la scheda.
2. **Durata.** Non c'è `CampoDocumento.durata`. Proposta: `case durata` («Durata»), con la regola
   `durata\s*[:\-–]\s*([^\n]{3,40})`; «vita intera» → scadenza assente e tipologia «Vita intera». Va aggiunto anche
   a `nome`, `unita`, `daRisposta` e alle voci di `MotoreConfrontoDossier` se serve.
3. **Frequenza «al mese».** `frequenzaPremio` riconosce «mensil…», non **«al mese»**, «ogni mese», «all’anno»,
   «l’anno». Aggiungere `\bal mese\b|\bogni mese\b` → `.mensile` e `\ball'?anno\b|\bl'anno\b` → `.annuale`.
4. **Errore vero oggi.** `creaPosizione(da:canale:area:)` mette sempre `p.frequenza = .annuale`. Con «90,00 € al mese»
   la posizione nascerebbe con 90 € **l'anno** invece di 1.080 €. Va usata `MotoreConfrontoDossier.frequenzaPremio`
   sulla riga del premio (`campo.estratto`), con ripiego `.annuale` solo se non c'è scritto nulla (e allora la
   frequenza resta da confermare). Questo vale anche per Documenti, non solo per lo scanner.
5. **Riga «Tipo».** Un formatore nuovo: `MotoreInquadra.tipo(_ d: Documento, canale:) -> String`:
   tipologia (o durata «vita intera») + « · » + provenienza: «Alleanza» se il canale è Alleanza, altrimenti
   l'emittente letto, e se l'emittente non c'è «altra compagnia».
6. **Forma dei valori nella scheda.** Premio «90 € al mese» (`Formati` euro senza decimali se interi + frequenza in
   parole), decorrenza «marzo 2021» (mese e anno). Proposta: `MotoreInquadra.righe(_ d: Documento) -> [RigaInquadra]`
   con `RigaInquadra { campo: CampoDocumento; etichetta: String; valore: String; riquadro: RiquadroPagina? }`,
   nell'ordine fisso Contraente · Premio · Capitale assicurato · Decorrenza · Tipo per le polizze; per KID ed estratti
   l'ordine di `DocumentiRuby.attesi`.
7. **Cliente.** Il template sa già che è Giulia. In Prisma: se lo scanner si apre dal dossier o da Posizioni con un
   cliente attivo, quello (`clienteAttivoId`); altrimenti si cerca il contraente tra i clienti
   (nome uguale, senza maiuscole e accenti) e, se non c'è o ce ne sono due, il pulsante chiede di sceglierlo.
   Motore: `MotoreInquadra.clienteProbabile(contraente:clienti:) -> Cliente?`.
8. **Polizza già in Prisma.** Se `ValoriDaDocumento.posizioneProbabile` o il numero di contratto trova una posizione,
   il pulsante principale diventa «Aggiorna la posizione» e porta al confronto «Nel documento / In Prisma» già
   esistente, invece di creare un doppione.
9. **Conferma dei dati.** In Prisma nessun dato entra nel dossier senza conferma. «Aggiungi a Posizioni» vale come
   conferma dei campi mostrati (`creaDaDocumento(..., confermaPrima: true)`), come già fa Documenti. Va detto nella
   scheda? Vedi Dubbi.
10. **Confronto con una temporanea** (motore nuovo, `Motori/MotoreInquadra.swift` o meglio
    `Motori/MotoreConfrontoTemporanea.swift`):

    ```
    struct ConfrontoTemporanea: Equatable {
        struct Colonna: Equatable { spesaAnnua: Double?; capitaleCasoMorte: Double?; riscatto: Riscatto }
        enum Riscatto: Equatable { case cresce(valoreOggi: Double?), case no, case nonNoto }
        let polizza: Colonna        // la sua vita intera
        let temporanea: Colonna     // una temporanea
        let fonteTariffa: TariffaCasoMorte.Fonte?
    }
    static func confronta(_ p: Posizione, fabbisogno: Double?, tariffa: TariffaCasoMorte?, riscatto: EsitoRiscatto?) -> ConfrontoTemporanea
    ```

    - **spesa l'anno della polizza** = `p.premioAnnuo` (90 × 12 = 1.080 €);
    - **capitale caso morte della polizza** = `p.capitaleAssicurato`;
    - **riscatto della polizza**: «sì, cresce nel tempo» se è una vita intera o rivalutabile con riscatto;
      se `MotoreRiscatto.calcola` dà un valore, si può mostrare «sì, oggi circa X €» (da decidere);
    - **capitale della temporanea**: il fabbisogno caso morte della famiglia (`EsitoProtezione.fabbisogno`), arrotondato
      a 10.000 €. Il template dice 160.000 € e la nota dice «a parità di spesa»: le due cose non coincidono
      (vedi Dubbi);
    - **spesa della temporanea** = tariffa × capitale / 1.000, con «circa», arrotondata a 10 €;
    - la tariffa **non** può essere la media di `copertureConTariffa` così com'è: dentro ci sono anche le vita intera
      e le LTC, che costano molto di più per mille. Serve un filtro «solo temporanee» (tipologia che contiene
      «temporanea» o «TCM», oppure un campo nuovo, vedi 5.4) oppure una tariffa data dal consulente.
11. **Scena** (Shell): `Shell/ScannerInquadra.swift` (vista: velo, telefono, foglio, scheda, tabella),
    `Shell/StatoInquadra.swift` (estensione di `StatoShell`: `scannerAperto`, `faseScanner`
    (`.attesa`, `.lettura`, `.fatto`, `.pochiDati`, `.illeggibile`, `.irraggiungibile`), `documentoScanner`,
    `confrontoMostrato`), la voce 6 delle Novità e il pulsante nella testata di `AppPosizioni.swift`;
    l'ordine di Esc in `StatoShell`.

#### 5.4 Campi nuovi dell'archivio (nomi proposti)

| Dove | Campo | A cosa serve |
|---|---|---|
| `CampoDocumento` | `case durata` | «Durata: vita intera / 10 anni» |
| `CampoEstratto` | `riquadro: RiquadroPagina?` (`x`, `y`, `larghezza`, `altezza`, 0…1) | illuminare il campo sull'immagine |
| `Documento` | `origine: OrigineDocumento?` (`.file`, `.fotocameraMac`, `.iPhone`) | sapere che viene da una foto (e mostrarlo in Documenti) |
| `Posizione` | `tipoCopertura: TipoCopertura?` (`.temporanea`, `.vitaIntera`, `.mista`, `.ltc`, `.altro`) — oppure la sola regola sulla tipologia | escludere le vita intera dalla tariffa della temporanea |
| `Impostazioni` | `tariffeTemporanea: [TariffaTemporanea]` (`eta`, `durata`, `perMille`, `fumatore?`, `fonte`, `data`) | la spesa della temporanea, dati del consulente |

Tutti opzionali, con decodifica tollerante (archivi vecchi senza il campo). Backup: entrano da soli con
`Documento`, `Posizione` e `Impostazioni`; aggiornare `Prisma --prova-backup` con un documento che ha `riquadro` e
`durata` e con una tariffa della temporanea.

#### 5.5 Prove di calcolo nuove

`Motori/ProvaCalcoliInquadra.swift` (chiamata da `ProvaCalcoli`):

1. testo del foglio del template → `conRegole` trova contraente «Giulia Rossi», premio «90,00», capitale «50.000»,
   decorrenza 1/3/2021, durata «vita intera»;
2. `frequenzaPremio("Premio: 90,00 € al mese") == .mensile`; «90 € all’anno» → `.annuale`;
3. `creaPosizione` da quel documento → `frequenza == .mensile`, `premioAnnuo == 1.080`;
4. `MotoreInquadra.righe` → cinque righe nell'ordine giusto, «90 € al mese», «marzo 2021»,
   «Vita intera · altra compagnia» (canale indipendente, emittente assente) e «Vita intera · Alleanza» (canale
   Alleanza);
5. `clienteProbabile`: «giulia rossi» trova Giulia; due omonimi → nil;
6. confronto: tariffa 1,1875 ‰ e capitale 160.000 → spesa 190 €; senza tariffa → `spesaAnnua == nil`;
7. tariffa delle temporanee: un archivio con una temporanea (1,2 ‰) e una vita intera (21,6 ‰) → la media usa solo
   la temporanea;
8. riquadri: una riga con `boundingBox` nota passa al `CampoEstratto.riquadro`;
9. (strada B) `DocumentoInArrivo` sigillato e riaperto con lo stesso codice; con un altro codice → nil; oltre
   `massimoBusta` → rifiutato.

---

### 6. Dati che l'utente deve dare (mai inventarli)

| Dato | Per cosa | Finché manca |
|---|---|---|
| **Tariffe di una temporanea caso morte** (premio ogni 1.000 € per età, durata, fumatore/non fumatore; di quale compagnia: Alleanza o mercato) | colonna «Una temporanea», riga «Spesa l’anno» | «—» e la nota «Manca una tariffa della temporanea: la trovi in Impostazioni». Con i dati di prova: la media delle temporanee dell'archivio di prova, con la scritta «dati di prova» |
| **Come scegliere il capitale della temporanea**: il fabbisogno della famiglia, lo stesso capitale della polizza, o quello che si compra con la stessa spesa | riga «Capitale caso morte» | si usa il fabbisogno (`EsitoProtezione`) se c'è; altrimenti lo stesso capitale della polizza |
| **Condizioni di riscatto** della polizza inquadrata (penali, anni minimi, rendimento della gestione separata) | «Valore di riscatto», se si vuole una cifra | solo «sì, cresce nel tempo» (dalla tipologia), senza cifra |
| **Polizze vere di prova** (2-3 foto o PDF anonimi: una polizza vita, un KID, un estratto conto) | provare regole e riquadri su documenti reali | si prova sul foglio del template, ricostruito come immagine di prova |
| **iPhone e Mac**: modello di iPhone, stesso ID Apple sul Mac, Wi-Fi e Bluetooth accesi | strada A (Fotocamera Continuity) | lo stato «L’iPhone non risponde» |
| **Testo della richiesta della fotocamera** sull'iPhone (strada B) | `NSCameraUsageDescription` | il testo proposto in 5.2 |
| **Come chiamare il canale** di una polizza di un'altra compagnia | toast e riga «Tipo» | «altra compagnia» con l'etichetta del canale indipendente (cuoio) |

Nelle istantanee si usa il foglio del template (Giulia Rossi, Compagnia Esempio S.p.A.) come documento di prova,
dichiarato in `DatiDemo`/`DatiConfrontoDemo` e mai mischiato con i dati veri.

---

### 7. Istantanee da aggiungere

La serie 5xx è di Orizzonte; 500-566 sono già prese dalle altre parti. Proposta per questa parte: **580-589**
(da verificare con le parti 08 e 10). Tutte 1440 × 900, chiaro e scuro (suffisso `-scuro`), stato finale.

| Nome | Cosa mostra |
|---|---|
| `580-posizioni-inquadra-lettura` / `-scuro` | scanner a metà: due righe illuminate sul foglio e due righe nella scheda, «Sto leggendo…», «Riconosco i dati…» (come `chiaro-15`) |
| `581-posizioni-inquadra-fatto` / `-scuro` | lettura finita: cinque righe, «Polizza riconosciuta», i due pulsanti, «✓ Fatto» |
| `582-posizioni-inquadra-confronta` / `-scuro` | dopo «Confronta»: la tabella «La sua vita intera / Una temporanea» e la nota |
| `583-posizioni-inquadra-senza-tariffa` | confronto con «—» nella spesa della temporanea e la nota sulla tariffa mancante |
| `584-posizioni-inquadra-attesa` | stato «Aspetto il documento…» (strada A, prima che arrivi la foto) |
| `585-posizioni-inquadra-pochi-dati` | solo contraente e premio trovati, le altre righe in grigio senza ✓ |
| `586-posizioni-inquadra-illeggibile` | «Non riesco a leggere il documento» con «Riprova» |
| `587-posizioni-inquadra-gia-presente` | la polizza c'è già: pulsante «Aggiorna la posizione» |
| `588-posizioni-testata-inquadra` | testata di Posizioni con i segmenti e il pulsante «◎ Inquadra con l’iPhone» |
| `589-posizioni-inquadra-calma` | con `\.prismaCalmo`: tutto fermo, linea assente |

---

## 10. Analisi 360 › Rispetto alle famiglie come la sua

*Parte 12 · titolo della bozza: «12 · Rispetto alle famiglie come la sua (Analisi 360)»*

Fonte: `Design/template-novita.html`. Funzioni `famHTML(c)` e `montaFam(root)` (righe 1028-1038), `anHTML(c)` (riga 1059), `agganciaAn()` (riga 581), voce `NOV[9]` (riga 740), CSS `.dist` (righe 213-215).
Schermate: `orizzonte/chiaro-19-rispetto-alle-famiglie-come-la-sua.png` e `orizzonte/scuro-19-rispetto-alle-famiglie-come-la-sua.png`.
Per tutto ciò che non cambia (finestra di Analisi 360, testata con le pillole dei clienti, card, segmentato, cascata, conteggio dei numeri) vale `Design/template-apple-specifica.md` §2 e §4.3.

Le percentuali del template (`PARI`) sono dimostrative. Nell'app vengono da un motore nuovo che confronta le cifre del cliente con le tabelle dell'Indagine sui bilanci delle famiglie italiane della Banca d'Italia (in breve IBF). Queste tabelle le fornisce l'utente: Prisma non ne contiene nessuna e nessun numero va inventato.

---

### 1. Cosa si vede

#### 1.1 Come ci si arriva
- **Da Analisi 360.** Sotto la testata (titolo «Analisi 360.», le quattro aree in maiuscoletto, le pillole dei clienti) c'è un segmentato a pillola con due voci:
  - «Le quattro aree» (la griglia di oggi, vista predefinita)
  - «Rispetto alle famiglie come la sua»
- **Dal pannello Novità** (pulsante «✦ Novità» nella barra): la voce 10 (`NOV[9]`), titolo «Rispetto alle famiglie come la sua», sottotitolo «Il cliente confrontato con chi gli somiglia». Il clic apre Analisi 360 già sulla seconda voce del segmentato. Se Analisi 360 è già aperta, la schermata si rifà senza riaprire la finestra.

#### 1.2 Struttura, dall'alto
1. **Riga del segmentato** (`.row.st`, spazio sotto 12 px).
2. **Card principale** (una riga, tutta la larghezza):
   - Frase grande: «{Nome} risparmia più del **{p}%** delle famiglie della sua età e del suo reddito.» La percentuale è blu `#0A84FF` e si conta da 0. {Nome} è la prima parola del nome del cliente. La frase usa sempre la prima voce (Risparmio ogni mese).
   - Sotto: «Famiglie italiane con capofamiglia tra i {decina} e i {decina+9} anni e un reddito simile.» Nel template la decina è l'età del cliente arrotondata per difetto (37 → «tra i 30 e i 39 anni»).
3. **Griglia 2 × 2 di card**, una per voce, sempre in questo ordine:

| # | Etichetta (`.lbl`, maiuscolo) | Verbo nella frase |
|---|---|---|
| 1 | Risparmio ogni mese | «risparmia più del» |
| 2 | Patrimonio finanziario | «ha più patrimonio del» |
| 3 | Protezione della famiglia | «è più protetta del» |
| 4 | Previdenza complementare | «ha più previdenza del» |

   Ogni card contiene:
   - in alto, l'etichetta a sinistra e la percentuale a destra, che si conta da 0. Il colore dipende dal valore: verde se ≥ 60, arancio se ≥ 35, rosso sotto 35;
   - la **barra della distribuzione**: una fascia sfumata da rosso ad arancio a verde, con una tacca verticale al centro (50%). Sotto la tacca c'è la scritta «metà delle famiglie». L'avatar del cliente (30 px) fa da segnaposto e sta in corrispondenza del percentile;
   - la **frase**:
     - se p ≥ 50: «{Nome} {verbo} {p}% delle famiglie come la sua.» (es. «Giulia ha più patrimonio del 64% delle famiglie come la sua.»)
     - se p < 50: «Il {100−p}% delle famiglie come la sua fa meglio: qui c’è margine.»
4. **Nota a piè di pagina** (`.k.st`, spazio sopra 12 px), con il testo esatto del template:
   «Confronto di prova. Nell’app i dati arrivano dall’indagine della Banca d’Italia sui bilanci delle famiglie italiane, inclusi in Prisma e aggiornati a mano: niente internet.»
   Nell'app questo testo cambia secondo lo stato (vedi §6).

#### 1.3 Stati
Il template ha un solo stato, quello pieno. Nell'app ne servono altri cinque. I testi qui sotto sono proposte, da confermare con l'utente:

| Stato | Quando | Cosa si vede |
|---|---|---|
| **Pieno** | tabelle caricate e cliente con tutti i dati | come nel template; la nota cita fonte e anno dell'indagine (§6) |
| **Dati di prova** | nessuna tabella caricata | come il pieno, ma con le percentuali di prova del template, la pillola «dati di prova» accanto al segmentato e la nota «Confronto di prova…» del template |
| **Voce senza dato del cliente** | manca la cifra del cliente per una voce (es. il risparmio mensile non è indicato) | la card resta: percentuale «—» in `ink3`, barra senza avatar, frase «Manca {cosa}: indicalo nel dossier per il confronto.» e un tocco porta al campo |
| **Senza età o reddito** | il cliente non ha data di nascita o reddito familiare | niente card principale; al suo posto «Per confrontare {Nome} servono età e reddito della famiglia.» con il pulsante «Completa il dossier» |
| **Gruppo troppo piccolo** | il gruppo età × reddito ha meno famiglie della soglia (§5.4) | la percentuale ha il suffisso «circa» e sotto la frase c'è «Poche famiglie nel campione: prendilo come indicazione.» |
| **File non valido** | il file importato non rispetta il formato (§5.3) | resta in uso la tabella precedente (o i dati di prova) e Impostazioni mostra l'errore con riga e campo; questa schermata non cambia |

Non c'è uno stato di caricamento: il calcolo è locale e istantaneo.

---

### 2. Misure e stile

Variabili del template → `Tema.Apple` (Sources/Prisma/DesignSystem/Apple/TemaApple.swift).

#### 2.1 Segmentato (`.seg`, CSS righe 45-48)
- Fondo `--chip`, raggio 99, padding 3.
- Voci: 13 px semibold (600), padding 6 × 14, colore `--ink2`; la voce attiva è `--ink`; il colore passa in 0,3 s.
- Pillola: `--cardE` con ombra `0 1px 4px rgba(0,0,0,.14)`; si sposta (left e width) in 0,5 s con `--spring`.
- In Prisma esiste già: `SegmentatoPillola` (ControlliApple.swift).

#### 2.2 Card principale
- `.card`: raggio 22, fondo `--card` (chiaro `rgba(255,255,255,.82)`, scuro `rgba(255,255,255,.07)`), bordo 1 px `--sep`, ombra `--shadow`. Padding 22 × 26, margine superiore 12.
- Frase: `--fontd`, 28 px, peso 700, letter-spacing −0,6 px, larghezza massima 980 px, colore `--ink`. La percentuale è `#0A84FF` (`--r2`, in Prisma `Tema.Apple.Colore.bluGrafico`).
- Sottotitolo: `.k` a 13,5 px (il `.k` di base è 12,5), colore `--ink2`, margine superiore 4.
- Nelle schermate la card è alta circa 100 px (y 198-298 su 940).

#### 2.3 Griglia delle voci
- `grid-template-columns: 1fr 1fr`, spazio 14, margine superiore 14.
- Card: `.card.st` (con cascata, **senza** `.tilt`: queste card non si inclinano), padding 20 × 24. Nelle schermate ogni card è alta circa 165 px.
- Riga in alto (`.row`, gap 8):
  - etichetta `.lbl`: 12 px, 600, maiuscolo, letter-spacing 0,6 px, `--ink2`;
  - percentuale: `--fontd` 24 px, 700, allineata a destra (`margin-left:auto`). Colore `--green #2FA35A` se ≥ 60, `--orange #E08A00` se ≥ 35, altrimenti `--red #E5484D`.
- Barra `.dist` (riga 213):
  - altezza 26, margine superiore 20, raggio 99, posizione relativa;
  - fondo `linear-gradient(90deg, rgba(229,72,77,.22), rgba(224,138,0,.22) 45%, rgba(47,163,90,.28))`. Il gradiente è lo stesso nei due aspetti: nello scuro, su card quasi trasparente, appare più cupo;
  - tacca `.med`: larghezza 2, da −5 a +5 oltre la barra (alta 36), colore `--ink3`, a `left:50%`;
  - scritta «metà delle famiglie»: `.k` a 11 px, assoluta a `top:34px`, centrata sulla tacca (`translateX(-50%)`);
  - segnaposto `.pin`: assoluto, `top:50%`, `translate(-50%,-50%)`, `left` = percentile %; avatar 30 × 30 (iniziali a 10 px, `round(30×.34)`, gradiente del cliente), bordo 3 px `--cardE`, ombra `0 4px 10px rgba(0,0,0,.25)`.
- Frase: 14 px, peso normale, `--ink`, margine superiore 30 (lascia spazio alla scritta della tacca).

#### 2.4 Nota a piè di pagina
- `.k`: 12,5 px, `--ink2`, margine superiore 12.

#### 2.5 Gettoni da aggiungere
In un nuovo file `Sources/Prisma/DesignSystem/Apple/Tema.Apple+Famiglie.swift`, `enum Tema.Apple.Famiglie`:
- `Disposizione`: `paddingPrincipale (22, 26)`, `paddingVoce (20, 24)`, `spazioGriglia 14`, `sopraGriglia 14`, `sottoSegmentato 12`, `larghezzaFraseMax 980`, `sopraSottotitolo 4`, `sopraBarra 20`, `altezzaBarra 26`, `sporgenzaTacca 5`, `larghezzaTacca 2`, `scrittaTaccaY 34`, `latoAvatar 30`, `bordoAvatar 3`, `sopraFrase 30`, `sopraNota 12`.
- `Caratteri`: `frase` (display 28/700, tracking −0,6), `sottotitolo` (13,5), `percentuale` (display 24/700, cifre tabulari), `scrittaTacca` (11), `fraseVoce` (14).
- `Colore`: `fascia` (i tre stop con le loro opacità e la posizione 45%), `tacca = ink3`, `ombraAvatar`, `cifraPrincipale = bluGrafico`, `soglia(p)` → verde/arancio/rosso con soglie `sogliaVerde = 60` e `sogliaArancio = 35`.
- `Tempi` (§3).

---

### 3. Movimento

Riferimenti: `rimonta()` (riga 728), `entrata()` e `conteggi()` (righe 265-267), `montaFam()` (riga 1038), `.dist .pin` (riga 215).

1. **Cambio vista dal segmentato.** La pillola scivola a molla in 0,5 s. Il contenuto esce in 0,13 s (opacità 1→0, scala 0,99, lineare), poi viene sostituito e rientra.
2. **Cascata d'entrata** sugli elementi `.st`, in quest'ordine: riga del segmentato, card principale, quattro card, nota. Ogni elemento va da opacità 0, `translateY(18px) scale(.985)`, `blur(6px)` allo stato normale in 720 ms con `cubic-bezier(.22,1,.36,1)` e ritardo `i × 48 ms` (base 0 dentro l'app). In Prisma: `.entrataCascata(indice, base:)` con `Tema.Apple.Moto.Cascata` (durata 0.72, passo 0.048, spostamento 18, scala 0.985, sfocatura 6).
3. **Conteggio delle percentuali** (`data-n`, formato `pct`): da 0 al valore con curva quartica `1−(1−t)^4`. Durata `1100 + min(i,6) × 60 ms`, dove l'indice segue l'ordine nella pagina: frase principale 1100, voce 1 1160, voce 2 1220, voce 3 1280, voce 4 1340. In Prisma: `NumeroCheConta(valore, formato: .percentuale, indice: i)`.
4. **Segnaposti.** Ogni avatar parte da `left:0` (estremità rossa) e scorre fino al percentile. La transizione `left` dura 1,3 s con `--spring` = `cubic-bezier(.34,1.45,.64,1)`, che va un po' oltre e poi torna indietro. Partono uno dopo l'altro: ritardo `250 + i × 120 ms` (250, 370, 490, 610). In Prisma: `Tema.Apple.Moto.Curva.molla.animazione(1.3)`, gettoni `Tempi.ritardoSegnaposto 0.25`, `Tempi.passoSegnaposto 0.12`, `Tempi.corsaSegnaposto 1.3`.
5. **Cambio cliente** (pillole della testata): stessa uscita, rientro e cascata del §4.3 della specifica Apple. Percentuali e segnaposti ripartono da zero.
6. **Riduci movimento.** Nel template `conta` e `entrata` lo rispettano (durata 1 ms), `montaFam` no: i segnaposti scorrono comunque. Nell'app, con `\.prismaCalmo`, tutto compare già fermo con la dissolvenza di 0,15 s: segnaposti al loro posto, cifre già piene, nessuna cascata.
7. **Istantanee** (`\.modoIstantanea`, `\.prismaStatoFinale`): stato finale subito, con cifre complete e segnaposti in posizione.

Niente Timer: l'avvio ritardato dei segnaposti si fa con `withAnimation(...delay(...))` o con un `Animatable` sulla frazione, come per gli anelli.

---

### 4. Interazioni

- **Segmentato:** il clic su una voce cambia vista; il clic sulla voce attiva non fa nulla. In Prisma la vista scelta resta finché non si chiude l'app (proposta: `StatoShell.vistaAnalisi360`, non salvata nell'archivio). Da tastiera valgono le frecce sinistra/destra di `SegmentatoPillola`, se già gestite; altrimenti vanno aggiunte.
- **Pillole dei clienti:** cambiano il cliente; la vista resta «Rispetto alle famiglie come la sua».
- **Voce Novità 10:** apre Analisi 360 su questa vista e chiude il pannello.
- **Card:** nel template non reagiscono al passaggio del puntatore (niente `.tilt`, niente sheen) né al clic. Proposta per l'app: il clic su una card apre l'area collegata (Risparmio → area risparmio, Patrimonio → investimenti, Protezione → protezione, Previdenza → previdenza) con `stato.areaAnalisi`. È un'aggiunta, va confermata.
- **Segnaposto:** non si trascina e non ha suggerimenti.
- **Accessibilità:** ogni card si legge come una sola frase, per esempio «Risparmio ogni mese: 78%. Giulia risparmia più del 78% delle famiglie come la sua.»; la barra è decorativa.

---

### 5. Mappa verso Prisma

#### 5.1 Cosa c'è già (verificato in Sources/Prisma)
| Serve | Esistente |
|---|---|
| Finestra e testata di Analisi 360 con le pillole | `Shell/AppAnalisi360.swift`, `Shell/Analisi360Apple.swift` (`Analisi360Apple`, `testata`, `PilloleClienti360`, `cambiaCliente`) |
| Segmentato | `DesignSystem/Apple/ControlliApple.swift` → `SegmentatoPillola` |
| Card | `Tema.Apple.Superficie.card`, `Tema.Apple.Raggio.card = 22` (TemaApple.swift) |
| Numeri che contano | `DesignSystem/Apple/CifreApple.swift` → `NumeroCheConta`, `FormatoCifra.percentuale` |
| Cascata | `DesignSystem/Apple/CascataApple.swift` → `EntrataApple`, `Tema.Apple.Moto.Cascata` |
| Curve | `TemaAppleMoto.swift` → `Curva.molla`, `Curva.uscita` |
| Colori verde/arancio/rosso/blu | `Tema.Apple.Colore.verde`, `.arancio`, `.rosso`, `.bluGrafico` |
| Avatar | `AvatarCliente` (DesignSystem/Componenti.swift), `Gradienti.avatar` |
| Genere per i testi | `TestiAree360.femminile(_:)` (Motori/MotoreAree360.swift) |
| Età | `Cliente.eta` (Dati/Modelli.swift) |
| Reddito | `ProfiloInvestitore.redditoNettoAnnuo` / `redditoLordoAnnuo`, `Familiare.redditoNettoAnnuo` (Modelli.swift) |
| Liquidità | `MotoreLiquidita` → `liquiditaAttuale` |
| Patrimonio | `MotorePatrimonio` / `PatrimonioNelTempo.nettoOggi` |
| Protezione | `MotoreProtezioneFamiglia.calcola` → `EsitoProtezioneFamiglia` |
| Previdenza | `MotorePrevidenza.calcola` → `EsitoPianoPrevidenziale`; posizioni dell'area previdenza |
| Dati di riferimento curati dall'utente | `Dati/Riferimenti.swift`, `DatiPrisma.riferimenti` (`RiferimentiRendimento`, versione 24): stesso modello da seguire |
| Lettura di fogli | `Motori/FoglioExcel.swift`, `Motori/ImportaClienti.swift` |
| Voce Novità | da fare nel giro 1 (pannello Novità) |

#### 5.2 Cosa manca
- **Vista** `Shell/FamiglieComeLaSua.swift`: `struct FamiglieComeLaSuaApple: View`, mostrata da `Analisi360Apple` quando il segmentato è sulla seconda voce. Il segmentato va inserito tra la testata e la griglia di oggi.
- **Componente** `DesignSystem/Apple/DistribuzioneApple.swift`: `struct BarraDistribuzione` (fascia, tacca, scritta, segnaposto animato).
- **Gettoni** `Tema.Apple+Famiglie.swift` (§2.5).
- **Testi** `Motori/TestiFamiglie.swift`: frasi, verbi al femminile e al maschile («è più protetta/protetto», ma vedi i dubbi), testi degli stati.
- **Motore** `Motori/MotoreFamiglie.swift`:
  ```swift
  enum VoceFamiglie: String, CaseIterable { case risparmio, patrimonioFinanziario, protezione, previdenzaComplementare }
  struct ConfrontoVoce { let voce: VoceFamiglie; let valoreCliente: Double?; let percentile: Double?; let campioneRidotto: Bool }
  struct ConfrontoFamiglie { let gruppo: GruppoFamiglie?; let voci: [ConfrontoVoce]; let fonte: FonteFamiglie?; let diProva: Bool }
  enum MotoreFamiglie {
      static func confronta(cliente: Cliente, posizioni: [Posizione], analisi: Analisi360, tabelle: TabelleFamiglie?) -> ConfrontoFamiglie
      static func gruppo(eta: Int, reddito: Double, in t: TabelleFamiglie) -> GruppoFamiglie?
      static func percentile(_ v: Double, quantili: [Quantile]) -> Double   // interpolazione lineare
  }
  ```
  Regole:
  1. **Gruppo:** classe d'età della tabella che contiene l'età del cliente, poi la fascia di reddito (classi di reddito familiare netto annuo date dalla tabella) che contiene il reddito della famiglia (cliente più familiari conviventi con reddito).
  2. **Cifra del cliente per voce:**
     - risparmio: risparmio annuo della famiglia (campo nuovo, §5.3) confrontato con la colonna «risparmio annuo»; nella frase resta «ogni mese» come nel template;
     - patrimonio finanziario: liquidità più valore in essere delle posizioni finanziarie dei due canali (quali posizioni contano va deciso con la definizione IBF, vedi i dubbi);
     - protezione e previdenza complementare: la variabile da usare dipende da cosa misura l'IBF (dubbi 3 e 4).
  3. **Percentile:** interpolazione lineare tra i quantili adiacenti della tabella. Sotto il primo quantile si interpola da 0 a q_min; sopra l'ultimo si ferma al percentile dell'ultimo quantile (es. «più del 95%»). Arrotondamento all'intero per difetto, come `quotaEntroProfilo`.
  4. **Masse a zero:** quando più quantili valgono 0 (molte famiglie senza previdenza complementare), un cliente con valore 0 sta al percentile del primo quantile maggiore di zero meno la quota delle famiglie a zero divisa per due (punto medio della massa). Da confermare.
  5. **Soglie:** verde ≥ 60, arancio ≥ 35 (colore); frase positiva ≥ 50. Restano fisse nel tema.
- **Archivio:** il gruppo età/reddito viene dalla tabella, non serve un campo nel cliente.

#### 5.3 Campi nuovi dell'archivio (versione 26)
- `DatiPrisma.tabelleFamiglie: TabelleFamiglie?` (nil = dati di prova), decodificata con `decodeIfPresent` come `riferimenti`.
- `ProfiloInvestitore.risparmioAnnuo: Double?`: risparmio della famiglia dichiarato (reddito meno spese); nell'interfaccia si inserisce al mese e si salva all'anno. In alternativa `spesaMensileFamiglia`, se l'utente preferisce ricavare il risparmio dal reddito (vedi i dubbi).
- Eventuale `ProfiloInvestitore.redditoFamiliareNettoAnnuo: Double?` per scavalcare la somma automatica.
- **Backup:** `tabelleFamiglie` entra nel backup. `Prisma --prova-backup` deve verificare che la tabella sopravviva a backup e ripristino (aggiungere a `Dati/ProvaBackup.swift`).

**Formato proposto per il file delle tabelle** (`famiglie-bankitalia.json`, importato da Impostazioni › Riferimenti › «Famiglie italiane», con il pulsante «Importa tabelle…»). Il file lo prepara l'utente dalle tavole o dai microdati pubblicati dalla Banca d'Italia. Qui sotto c'è solo la struttura; i numeri sono segnaposto `null`, non valori.

```json
{
  "formato": "prisma-famiglie-1",
  "fonte": {
    "nome": "Indagine sui bilanci delle famiglie italiane",
    "ente": "Banca d'Italia",
    "anno": null,
    "pubblicata": null,
    "note": "unità: euro correnti dell'anno dell'indagine; valori per famiglia; pesi campionari applicati"
  },
  "unitaFamiglia": "famiglia",
  "riferimentoEta": "capofamiglia",
  "classiEta": [ { "id": "e1", "da": null, "a": null } ],
  "classiReddito": [ { "id": "r1", "da": null, "a": null } ],
  "quantili": [5, 10, 25, 50, 75, 90, 95],
  "voci": {
    "risparmio":               { "variabile": "risparmio annuo (reddito netto − consumi)", "unita": "euro/anno" },
    "patrimonioFinanziario":   { "variabile": "attività finanziarie della famiglia",       "unita": "euro" },
    "protezione":              { "variabile": "da definire (dubbio 3)",                   "unita": null },
    "previdenzaComplementare": { "variabile": "da definire (dubbio 4)",                   "unita": null }
  },
  "celle": [
    {
      "eta": "e1", "reddito": "r1", "famiglie": null,
      "risparmio":               [null, null, null, null, null, null, null],
      "patrimonioFinanziario":   [null, null, null, null, null, null, null],
      "protezione":              [null, null, null, null, null, null, null],
      "previdenzaComplementare": [null, null, null, null, null, null, null],
      "quotaZero": { "previdenzaComplementare": null, "protezione": null }
    }
  ]
}
```

Regole di validazione (errori mostrati con riga/campo):
- `formato` riconosciuto; classi d'età e di reddito senza buchi né sovrapposizioni; `quantili` crescenti tra 1 e 99;
- una cella per ogni coppia età × reddito; ogni elenco lungo quanto `quantili` e non decrescente; `famiglie` intero > 0;
- si accetta anche lo stesso contenuto in CSV, una riga per cella e voce: `eta_da;eta_a;reddito_da;reddito_a;famiglie;voce;p5;p10;p25;p50;p75;p90;p95;quota_zero`, letto con il separatore `;` e la virgola decimale italiana, come `ImportaClienti`.

**Tabelle IBF che servono** (per ogni voce, la distribuzione per classe d'età del capofamiglia incrociata con la classe di reddito familiare, con i pesi campionari):
1. Le classi di reddito familiare netto annuo (quinti o quartili) per l'anno dell'indagine, con i loro estremi in euro.
2. I quantili del **risparmio familiare annuo** per età × reddito.
3. I quantili delle **attività finanziarie** della famiglia per età × reddito.
4. Per la **protezione**: la distribuzione della variabile scelta (es. premi annui di polizze vita/infortuni/malattia, oppure possesso di polizze caso morte) per età × reddito, con la quota di famiglie a zero.
5. Per la **previdenza complementare**: la quota di famiglie iscritte a forme complementari e i quantili dei contributi annui o del montante, per età × reddito.
6. Il numero di famiglie del campione in ogni cella, per la soglia del «gruppo troppo piccolo».

Le tavole pubblicate di solito danno medie e mediane per singola caratteristica, non incroci età × reddito con i quantili. In quel caso servono i microdati, vedi il dubbio 1.

#### 5.4 Prove di calcolo nuove
`Motori/ProvaCalcoliFamiglieItaliane.swift` (`enum ProvaCalcoliFamiglieItaliane`, chiamata da `ProvaCalcoli.esegui()`). Usa **una tabella sintetica scritta nella prova**: numeri di comodo, dichiarati come tali nel commento, che non finiscono mai nell'interfaccia.
- H1 Gruppo: età sul bordo della classe (es. «da»/«a» inclusi), reddito sul bordo della fascia, età fuori da tutte le classi → nil.
- H2 Percentile: valore uguale a un quantile → quel percentile; a metà tra due quantili → la media; sotto il primo e sopra l'ultimo → i limiti del §5.2.
- H3 Massa a zero: valore 0 con quota zero nota → punto medio.
- H4 Arrotondamento per difetto e soglie di colore (59 → arancio, 60 → verde, 34 → rosso).
- H5 Frasi: p = 50 → frase positiva; p = 49 → «Il 51%…»; femminile e maschile.
- H6 Validazione del file: quantili non crescenti, cella mancante, classi sovrapposte → errore con il campo giusto.
- H7 Reddito familiare: somma del cliente e dei familiari con reddito; con il campo esplicito vale quello.
- H8 Cifra mancante → `percentile == nil`, nessun crash.
- Backup: in `ProvaBackup` va aggiunto un giro con `tabelleFamiglie` presente.

---

### 6. Dati che l'utente deve dare (mai inventarli)

1. **Le tabelle IBF** nel formato del §5.3: anno dell'indagine, classi d'età e di reddito, quantili, numero di famiglie per cella.
2. **Le definizioni** delle quattro variabili, prese dalla documentazione dell'indagine: che cosa entra in «attività finanziarie», come si misura la protezione, come si misura la previdenza complementare.
3. **La soglia** del gruppo troppo piccolo (numero minimo di famiglie per cella).
4. **Per ogni cliente:** risparmio della famiglia (o spese mensili), reddito familiare netto, età (data di nascita). Il resto viene dalle posizioni.

Finché mancano:
- **senza tabelle:** si mostrano le percentuali di prova del template (`PARI` per i 5 clienti di prova; per gli altri clienti, comprese i 30 fittizi, una percentuale di prova ricavata in modo fisso dall'id), la pillola «dati di prova» accanto al segmentato e la nota del template «Confronto di prova. Nell’app i dati arrivano…». Le cifre di prova non vanno né a Ruby né nei PDF;
- **con le tabelle:** nota «Indagine sui bilanci delle famiglie italiane, Banca d'Italia, anno {anno}. {n} famiglie nel gruppo. Tabelle caricate il {data}: niente internet.»;
- **senza i dati del cliente:** gli stati del §1.3.

---

### 7. Istantanee da aggiungere

Nomi proposti, nella serie 4xx dopo l'ultima (436); i numeri esatti si scelgono quando si scrive il codice:

| Nome | Contenuto |
|---|---|
| `437-analisi360-famiglie` / `437-analisi360-famiglie-scuro` | Giulia, dati di prova, stato finale (come le schermate 19 del template) |
| `438-analisi360-famiglie-tabelle` / `-scuro` | con una tabella sintetica della prova H1-H8 caricata: nota con fonte e anno, una voce «circa» per il campione ridotto |
| `439-analisi360-famiglie-margine` | un cliente con voci sotto 35 e sotto 50 (Andrea nel template: 39, 52, 8, 12): rosso, arancio, frase «qui c’è margine» |
| `440-analisi360-famiglie-incompleto` / `-scuro` | cliente senza risparmio indicato e uno senza età: card con «—» e stato «Completa il dossier» |
| `441-novita-famiglie` | il pannello Novità con la voce 10 in evidenza (se il giro 1 non la copre già) |

Nella vetrina `VetrinaApple` va aggiunta una `BarraDistribuzione` a 25, 50 e 90 (istantanea «400-vetrina-apple», chiara e scura).

Le istantanee si aggiornano sul branch `anteprime` e nella pagina delle anteprime.

---

## 11. Studio › Esame OCF

*Parte 04 · titolo della bozza: «04 · Studio › Esame OCF»*

Fonte: `Design/template-novita.html`. Le righe citate sono di quel file: voce `NOV[10]` (741), dati `OCF` (760) e `QUIZ` (761-763), `qI` (764), `APPS.studio` (765-767), `studioHTML()` ramo finale `ocf` (798-804), `quizHTML()` (805-809), `montaStudio()` ramo `ocf` (841), `montaQuiz()` (842-848), CSS `.opz` (206-209), utilità comuni (255-285).
Schermate: `orizzonte/chiaro-20-allenamento-ocf.png`, `orizzonte/scuro-20-allenamento-ocf.png` (domanda aperta). Scattate in più per questa parte: `orizzonte/ocfshots/sbagliata.png` (risposta C sulla prima domanda), `orizzonte/ocfshots/giusta.png` e `orizzonte/ocfshots/giusta-scuro.png` (risposta B, giusta, sulla seconda).
Per quello che qui non è detto (finestra, testata di Studio, segmentato, card, cascata, numeri che si contano, anelli, barre) vale `Design/template-apple-specifica.md`. Per l'app Studio e le sue schede vale `01-studio-cruscotto.md` §1.1.
**Le cifre e le domande del template sono dimostrative.** Le percentuali vengono dal motore (§5), le domande le importa l'utente (§5.6). Se un dato manca si vede lo stato vuoto o, solo con i dati di prova, l'etichetta «dati di prova» (§6). Mai un numero o una domanda inventati.

---

### 1. Cosa si vede

#### 1.1 Arrivi
- Studio, quarta scheda del segmentato: **«Esame OCF»** (valore `ocf`).
- Pannello Novità, voce 11: **«Allenamento OCF»**, descrizione **«Domande, ripasso e casi veri di Prisma»** (`vaiA('studio',()=>{tabS='ocf'})`).
- Testata della finestra come le altre schede di Studio: **«Studio»** nella barra del titolo, **«Il tuo studio.»** e **«IL TUO LAVORO, COME UN PORTAFOGLIO»**.

#### 1.2 Griglia
Area dei contenuti 1384×654. Due card, affiancate, alte quanto l'area:

| # | Card | x | y | larghezza | altezza | padding |
|---|------|---|---|-----------|---------|---------|
| 1 | La tua preparazione | 0 | 0 | 520 | 654 | 22 / 24 |
| 2 | La domanda (`#quiz`) | 536 | 0 | fino al bordo destro (848) | 654 | 26 / 30 |

Tra le card ci sono 16 punti. In proporzione la prima card è 520 su 1384 (37,6 %). Conviene una larghezza fissa di 520 e la seconda che prende il resto.

#### 1.3 Card 1 — «LA TUA PREPARAZIONE»
Dall'alto:
1. Etichetta `.lbl` **«LA TUA PREPARAZIONE»**.
2. Riga (gap 20, 12 sotto l'etichetta):
   - **anello** singolo da 130, spessore 14, viola `#8B5CF6`, riempito alla percentuale complessiva; al centro **«66%»** (cifra che si conta);
   - a destra, tre righe:
     - **«Esame OCF»** (titolo);
     - due righe in `.k`: **«14 domande da ripassare oggi»** e **«Il punto più debole: diritto privato e commerciale»**;
     - pulsante **«Imposta la data dell'esame»** (8 sotto). Nel template non fa niente (§4).
3. Elenco delle **sei materie** (16 sotto la riga, ogni materia 12 sotto la precedente). Per ognuna: nome a sinistra, percentuale in grassetto a destra, sotto una barra da 8 (5 sotto il testo). Il template ha questi nomi e queste cifre:

| Materia (testo esatto) | % | colore della barra |
|---|---|---|
| Mercato finanziario e intermediari | 72% | verde |
| Matematica finanziaria ed economia | 58% | arancio |
| Pianificazione finanziaria | 81% | verde |
| Previdenza e assicurazioni | 77% | verde |
| Diritto privato e commerciale | 49% | rosso |
| Diritto tributario | 61% | arancio |

   Il colore segue tre soglie: almeno **70** verde `#30B15C`, almeno **55** arancio `#E08A00`, sotto il 55 rosso `#E5484D`.
4. Nota in `.k`, 14 sotto: **«Le domande vengono dal tuo manuale: il ripasso torna sugli argomenti che sbagli.»** (va a capo dopo «che»).
5. Sotto resta circa un terzo della card vuoto (vedi Dubbi: proposta di metterci la data dell'esame e il ritmo).

Il numero al centro è la **media semplice** delle sei materie, arrotondata (`Math.round(Σ/6)`: 398/6 = 66,3 → 66). «Il punto più debole» è la materia con la percentuale più bassa, scritta in minuscolo. Nel template «14 domande» è scritto a mano.

#### 1.4 Card 2 — la domanda (`#quiz`)
Dall'alto:
1. Riga: a sinistra la **materia** in `.lbl` viola `#8B5CF6` (in maiuscolo, per esempio **«MERCATO FINANZIARIO E INTERMEDIARI»**). A destra in `.k` **«domanda 1 di 3»**.
2. **Testo della domanda**, grande (14 sopra, 18 sotto, al massimo 720 di larghezza, va a capo). Esempi: **«Che cos'è il KID?»**, **«10.000 € investiti al 3% composto annuo, dopo 2 anni valgono:»**.
3. **Quattro opzioni** (`.opz`), una sotto l'altra, ognuna con il cerchio della lettera **A B C D** e il testo.
4. Spazio della **spiegazione** (`#spieg`, 14 sotto le opzioni), vuoto e trasparente finché non si risponde.
5. Piede, fisso in basso (30 dai lati, 24 dal fondo): a sinistra in `.k` **«Ripasso a intervalli: le domande sbagliate tornano tra 1, 3 e 7 giorni»**, a destra il pulsante primario grande **«Prossima domanda ›»**.

#### 1.5 Stati della domanda
**a. Da rispondere** (schermate `*-20-allenamento-ocf.png`): quattro opzioni uguali, fondo pieno della card (`--cardE`), cerchio della lettera grigio (`--chip`).

**b. Risposta giusta** (`giusta.png`):
- l'opzione scelta diventa **verde**: bordo `#30B15C`, fondo verde al 10 %, cerchio pieno verde con la lettera bianca;
- le altre tre scendono al 50 % di opacità;
- compare la spiegazione in una `.tile` con il bordo verde al 40 %: titolo **«Giusto.»** in verde `--green`, poi il testo della spiegazione, poi il pulsante **«◎ <caso vero>»**.

**c. Risposta sbagliata** (`sbagliata.png`):
- l'opzione giusta diventa **verde** come sopra; quella scelta diventa **rossa**: bordo `#E5484D`, fondo rosso all'8 %, cerchio pieno rosso con la lettera bianca; le altre due al 50 %;
- l'opzione sbagliata **trema** in orizzontale (§3.3);
- la spiegazione ha il bordo rosso al 35 % e il titolo **«Non proprio: torna tra un giorno.»** in rosso `--red`.

Testi delle tre domande di prova (esatti):

| # | Materia | Domanda | Opzioni (la giusta in grassetto) | Spiegazione | Caso vero |
|---|---|---|---|---|---|
| 1 | Mercato finanziario e intermediari | Che cos'è il KID? | **A Il documento con le informazioni chiave dei prodotti d'investimento preassemblati (PRIIPs)** · B Il contratto quadro tra cliente e intermediario · C Il questionario di profilatura del cliente · D Il rendiconto annuale dei costi | Il KID è previsto dal regolamento PRIIPs: in poche pagine descrive rischi, scenari e costi del prodotto. | ◎ Apri il KID del piano di Giulia → Clienti, Giulia, Panoramica |
| 2 | Matematica finanziaria ed economia | 10.000 € investiti al 3% composto annuo, dopo 2 anni valgono: | A 10.600 € · **B 10.609 €** · C 10.300 € · D 10.900 € | Interesse composto: 10.000 × 1,03 × 1,03 = 10.609 €. Gli interessi del primo anno producono interessi nel secondo. | ◎ Provalo nel simulatore di Analisi 360 → Analisi 360, aree |
| 3 | Previdenza e assicurazioni | In una polizza rivalutabile con consolidamento, la rivalutazione riconosciuta ogni anno: | A si può perdere se la gestione separata va male l'anno dopo · **B resta acquisita definitivamente** · C si paga solo alla scadenza, se positiva · D segue giorno per giorno i mercati | Con il consolidamento la rivalutazione si aggiunge al capitale e non può più essere tolta. | ◎ Guarda la polizza rivalutabile di Sofia → Clienti, Sofia, Panoramica |

**Il template non ha né stato vuoto né caricamento né errore.** Le domande girano in cerchio (dopo la 3 torna la 1) e la card 1 non cambia quando si risponde. In Prisma servono gli stati del §6.

---

### 2. Misure e stile

#### 2.1 Gettoni del template usati qui
| Gettone | Chiaro | Scuro | In Prisma |
|---|---|---|---|
| `--card` (fondo card) | bianco 0,82 | bianco 0,07 | `Tema.Apple.Colore.card` |
| `--cardE` (fondo opzione) | `#FFFFFF` | `#283642` | `Colore.cardPiena` |
| `--sep` (bordi) | nero 0,08 | bianco 0,09 | `Colore.separatore` |
| `--chip` (cerchio lettera) | nero 0,05 | bianco 0,08 | `Colore.chip` |
| `--track` (binario barre) | nero 0,07 | bianco 0,10 | `Colore.binario` |
| `--ink2` (`.k`, `.lbl`) | nero 0,55 | bianco 0,62 | `Colore.inchiostro2` |
| `--green` (titolo «Giusto.») | `#2FA35A` | uguale | `Colore.verde` |
| `--red` (titolo «Non proprio…») | `#E5484D` | uguale | `Colore.rosso` |
| `--accent` (pulsante primario) | `#007AFF` | uguale | `Colore.accento` |
| viola anello e materia | `#8B5CF6` | uguale | `Colore.anello3` |
| verde opzione giusta e barre ≥ 70 | `#30B15C` | uguale | `Colore.anello1` |
| arancio barre ≥ 55 | `#E08A00` | uguale | `Colore.arancio` |
| rosso opzione sbagliata e barre < 55 | `#E5484D` | uguale | `Colore.rosso` |

Colori nuovi, da aggiungere in `Tema.Apple+Studio.swift` (proposto in 01) sotto `Tema.Apple.Studio.OCF`:
- `fondoGiusta` = rgba(48, 177, 92, 0,10); `fondoSbagliata` = rgba(229, 72, 77, 0,08);
- `bordoSpiegazioneGiusta` = rgba(47, 163, 90, 0,40); `bordoSpiegazioneSbagliata` = rgba(229, 72, 77, 0,35);
- `opacitaAttenuata` = 0,5.
Valgono uguali in chiaro e in scuro (nel template non cambiano).

#### 2.2 Card 1
- Card `.card`: raggio **22**, fondo `--card`, bordo 1 `--sep`, ombra `--shadow` (= `Tema.Apple.Superficie.card`, `Raggio.card`), padding **22 / 24** (`Misura.Padding.cardGrande`).
- `.lbl`: 12 / semibold, spaziatura 0,6, maiuscolo, `--ink2` (`Carattere.etichetta`).
- Anello: misura **130**, spessore **14**, binario dello stesso viola a opacità 0,15, estremità arrotondate, parte da ore 12 (`Anello`, in `AnelliApple.swift`).
- Centro dell'anello: carattere display **28 / bold**, cifre tabellari. In `Carattere.dimensioniCentroAnello` (`[44, 42, 36, 32, 24]`) **il 28 non c'è**: va aggiunto.
- «Esame OCF»: display **20 / bold**.
- Le due righe sotto: `.k` portato a **13,5**, interlinea **1,5**.
- Pulsante «Imposta la data dell'esame»: `.btn` normale, pillola (raggio 99), padding **7 / 14**, **12,5 / semibold**, fondo `--cardE`, bordo `--sep`, 8 sopra (`StilePulsanteApple`, variante normale).
- Materie: testo **13** regolare, percentuale **13 / bold**; barra `.bar8` alta **8**, raggio **9**, binario `--track` (`BarraPiena` in `GraficiApple.swift`).
- Nota in fondo: `.k` **12,5**, `--ink2`, 14 sopra.

#### 2.3 Card 2
- Stessa card, padding **26 / 30** (`Misura.Padding.dettaglio`).
- Riga alta: `.lbl` viola + `.k` 12,5.
- Domanda: display **26 / bold**, spaziatura −0,5, interlinea **1,25**, margini **14 sopra, 18 sotto**, al massimo **720** di larghezza.
- Opzione `.opz`: riga con spazio **14** tra gli elementi, padding **13 / 16**, raggio **16**, bordo 1 `--sep`, fondo `--cardE`, **10** sotto ognuna, testo **15** regolare, al massimo **860** di larghezza (nella card la larghezza utile è 788, quindi riempie). Altezza risultante: **58** con il testo su una riga.
- Cerchio della lettera `.ol`: **30×30**, raggio pieno, fondo `--chip`, lettera **bold** (15).
- Spiegazione: `.tile` (raggio **18**, fondo `--card`, bordo 1, padding **14 / 16**; `Superficie.tile`, `Raggio.tile`, `Misura.Padding.tile`), 14 sopra. Titolo **16 / bold** colorato; testo **14**, interlinea **1,5**, 4 sopra; pulsante caso vero `.btn` normale, 10 sopra, con il segno **◎** davanti.
- Piede: a 30 dai lati e 24 dal fondo (`Misura.piedeDettaglioLati`, `piedeDettaglioFondo`). Pulsante «Prossima domanda ›» `.btn.pri.big`: padding **10 / 18**, **13,5 / semibold**, fondo `--accent`, testo bianco.

---

### 3. Movimento
Valori in Prisma da `Tema.Apple.Moto`. Curve: `uscita` = cubic-bezier(.22,1,.36,1), `molla` = cubic-bezier(.34,1.45,.64,1), `ease` = predefinita del CSS (.25,.1,.25,1).

#### 3.1 Entrata della scheda (cambio dal segmentato o dalla voce Novità)
- Il contenuto vecchio esce in **0,13 s** (opacità a 0, scala 0,99), poi entra il nuovo (`rimonta`, `Moto.CambioApp` / regola comune di 00 §3.4).
- **Cascata** delle due card (`.st`): ognuna da y +18, scala 0,985, sfocatura 6 → fermo, **0,72 s** `uscita`, ritardo **0** e **0,048 s** (`Moto.Cascata`).
- **Anello**: si riempie in **1,4 s** `uscita` con **0,15 s** di ritardo (`Moto.Anello`, `ritardoCambio`).
- **«66%»** si conta da 0 in **1,1 s** con curva quartica (`Moto.Numero`, `NumeroCheConta`).
- **Barre delle materie**: si riempiono in **1,2 s** `uscita`, ritardo **0,15 + 0,09 × indice** (`Moto.Barra`). La sesta parte a 0,60 s.
- Le percentuali delle materie nel template sono testo fermo, non si contano. Proposta: farle contare come le altre cifre, per coerenza con il tema (Dubbio 9).

#### 3.2 Opzioni
- Al passaggio del puntatore l'opzione si sposta di **4 a destra**, con transizione **0,30 s** `ease` (`transition: all .3s`).
- Dopo la risposta i colori (bordo, fondo, cerchio) e l'opacità 0,5 delle altre cambiano con la stessa transizione di **0,30 s** `ease`.
- Nel template lo spostamento al passaggio resta anche dopo aver risposto. In Prisma va tolto: a domanda chiusa le opzioni non reagiscono più.

#### 3.3 Tremolio della risposta sbagliata
- Solo sull'opzione scelta, solo se sbagliata. Fotogrammi in x: **0 → −8 → +8 → −5 → 0**, in tutto **0,38 s**, a passo lineare (niente curva). Parte insieme al cambio di colore.
- In Prisma: nuovo `Tema.Apple.Moto.RispostaSbagliata` (`durata = 0.38`, `spostamenti: [-8, 8, -5, 0]`), con un `GeometryEffect` che anima un parametro da 0 a 1 (niente Timer).

#### 3.4 Spiegazione
- Entra da y +10 con opacità da 0 a 1, **0,45 s** `uscita`, senza ritardo, nel momento in cui si risponde.
- Nuovo `Tema.Apple.Moto.Spiegazione` (`durata = 0.45`, `spostamento = 10`).

#### 3.5 Prossima domanda
- La card esce verso sinistra: x da 0 a **−30**, opacità a 0, **0,16 s** lineare.
- Arriva la domanda nuova da destra: x da **+40** a 0, opacità da 0 a 1, **0,48 s** `uscita`.
- La card in sé non si muove: si muove il suo contenuto (in Prisma una `transition` asimmetrica sul contenuto, chiave = id della domanda).
- Nuovo `Tema.Apple.Moto.CambioDomanda` (`uscita = 0.16`, `spostamentoUscita = -30`, `entrata = 0.48`, `spostamentoEntrata = 40`).

#### 3.6 Aggiornamento della card 1 dopo una risposta (non c'è nel template, proposta)
Quando si risponde, la percentuale della materia, la sua barra, l'anello, il numero al centro e «N domande da ripassare oggi» passano al valore nuovo: barra e anello con `Moto.Barra` / `Moto.Anello` senza ritardo, cifre con `Moto.NumeroCambio` (0,90 s). Se la materia cambia fascia, il colore della barra cambia con la stessa durata.

#### 3.7 Riduci movimento e istantanee
- Il template rispetta `ridotto` solo per cascata, numeri e linee. Tremolio, spiegazione e cambio di domanda non lo guardano.
- In Prisma, con `\.prismaCalmo`: niente cascata, niente tremolio, niente spostamento al passaggio. Spiegazione e domanda nuova compaiono con una dissolvenza di **0,15 s**. Anello, barre e numeri sono già nello stato finale.
- Con `\.modoIstantanea` / `\.prismaStatoFinale`: tutto subito fermo (anello pieno, barre piene, cifre complete, spiegazione visibile se la domanda è chiusa).

---

### 4. Interazioni

**Nel template:**
- clic su un'opzione: la domanda si chiude (`fatto = true`), si colora, compare la spiegazione. Un secondo clic non fa niente;
- clic su «◎ caso vero»: porta nell'app collegata (Clienti di Giulia, Analisi 360, Clienti di Sofia);
- clic su «Prossima domanda ›»: passa alla domanda seguente, anche **senza aver risposto**;
- «Imposta la data dell'esame»: nessuna azione;
- niente tastiera, niente trascinamenti.

**Proposta per Prisma:**
- **Tastiera** (sul Mac): **A, B, C, D** (e **1-4**) scelgono l'opzione; **Invio** o **→** vanno alla prossima domanda. Con target macOS 13 `onKeyPress` non c'è (arriva con macOS 14): si usano pulsanti nascosti con `.keyboardShortcut`, come nel resto della shell.
- **«Prossima domanda ›» prima di rispondere**: la domanda conta come saltata. Non va nello storico come sbagliata, ma resta in coda per oggi (Dubbio 6).
- **«Imposta la data dell'esame»**: apre un riquadro sopra (`Moto.RiquadroSopra`) con un `DatePicker` (solo giorni da domani in poi), il pulsante **«Salva»** e, se la data c'è già, **«Togli la data»**. Una volta salvata, il pulsante diventa **«Esame il 18 febbraio 2027 · mancano 107 giorni»** (cifre dal motore) e si può cliccare per cambiarla. Facoltativo: casella «Mettilo anche in agenda», che crea un `Appuntamento`.
- **Clic su una materia** nella card 1: la sessione continua solo con le domande di quella materia. La materia scelta si evidenzia (fondo `Colore.selezioneVoce`) e sopra la domanda compare **«Solo: <materia> ✕»** per tornare a tutte. Nel template non c'è (Dubbio 7).
- **«◎ caso vero»**: usa `StatoShell.apriCliente(_:)`, `StatoShell.apriPosizione(_:)` e `StatoShell.apri(.documenti)` / `apri(.simulazioni)`, che sul Mac portano nell'ospite giusto (`AppPrisma.ospite`). In **modalità cliente** (`appConsentita`) Studio non si apre e il pulsante non compare.
- **Importa domande**: dal menu «…» della card 2 (o dallo stato vuoto) con il pannello di apertura del Mac, CSV o JSON (§5.6). Anche trascinando il file sulla card.

---

### 5. Mappa verso Prisma

#### 5.1 Da riusare (verificato con grep in `Sources/Prisma`)
| Cosa | Dove |
|---|---|
| Anello singolo con binario, riempimento e brillio | `DesignSystem/Apple/AnelliApple.swift` (`Anello(frazione:colore:misura:spessore:ritardo:…)`) |
| Cifra che si conta, formato percentuale | `DesignSystem/Apple/CifreApple.swift` (`NumeroCheConta`, `FormatoCifra`) |
| Barra che si riempie | `DesignSystem/Apple/GraficiApple.swift` (`BarraPiena`) |
| Segmentato delle schede di Studio | `DesignSystem/Apple/ControlliApple.swift` (`SegmentatoPillola`) |
| Pulsanti normale e primario | `DesignSystem/Apple/PulsantiApple.swift` (`StilePulsanteApple`, `VariantePulsanteApple`) |
| Cascata d'entrata | `DesignSystem/Apple/CascataApple.swift` (`EntrataApple`) |
| Card, tile, raggi, padding, caratteri | `DesignSystem/Apple/TemaApple.swift` (`Superficie.card`, `.tile`, `Raggio.card` 22, `.tile` 18, `.voce` 14, `Carattere.etichetta`, `.h2`, `.valore`, `centroAnello(_:)`) |
| Tempi e curve | `DesignSystem/Apple/TemaAppleMoto.swift` (`Curva.uscita`, `.molla`, `.ease`, `Cascata`, `Anello`, `Numero`, `NumeroCambio`, `Barra`, `RiquadroSopra`) |
| Riduci movimento, istantanee | `DesignSystem/Apple/AmbienteMovimento.swift` (`\.prismaCalmo`), `\.modoIstantanea`, `\.prismaStatoFinale` |
| Lettura CSV (separatore `;` `,` tab, BOM, Latin-1 di Excel) | `Motori/ImportaClienti.swift` (`ImportaClienti.testo(_:)`, `ImportaClienti.righeCSV(_:)`) |
| Navigazione verso il caso vero | `Shell/StatoShell.swift` (`apriCliente(_:)`, `apriPosizione(_:)`, `strumentoAnalisi`, `schedaSimulazioni`), `Shell/StatoShellFinestre.swift` (`apri(_:da:)` con `AppPrisma.ospite`) |
| KID dei clienti | `Dati/Documento.swift` (`Documento.tipo == .kid`, `CategoriaDocumento.kid`); nei dati di prova `DatiDemo.swift` ha «KID · Fondo pensione aperto Orizzonte» di Giulia |
| Polizze con consolidamento | `Posizione.consolidamento: Bool?`, `Posizione.gestioneSeparata` (`Dati/Posizione.swift`), `Motori/MotoreGestioneSeparata.swift` |
| Simulatore da aprire già impostato | `Dati/Analisi.swift` (`Simulazione`: `capitale`, `versamentoMensile`, `anni`, `rendimento`), `Shell/AnalisiStrumenti.swift` (`SimulatoreIpotesi`) |
| Promemoria del ripasso (facoltativo) | `Shell/PromemoriaMac.swift` (notifiche locali `UNCalendarNotificationTrigger`) |
| Archivio tollerante | `Dati/DatiPrisma.swift` (`decodeIfPresent … ?? []`, `versioneAttuale = 25`), `Dati/ElencoTollerante.swift` |

Nessun tipo OCF esiste oggi: `grep -ri "ocf" Sources/Prisma` non trova nulla.

#### 5.2 Cosa manca
- **La scheda**: `Shell/StudioEsameOCF.swift` (nome proposto), dentro l'app Studio di 01 (`AppPrisma.studio`, `Shell/AppStudio.swift`), con le viste `PreparazioneOCF` (card 1), `DomandaOCF` (card 2), `OpzioneOCF`, `SpiegazioneOCF`, `RiquadroDataEsame`.
- **Gettoni** in `Tema.Apple+Studio.swift`: `Tema.Apple.Studio.OCF` con colori (§2.1), misure (`larghezzaPreparazione = 520`, `anello = 130`, `spessoreAnello = 14`, `maxDomanda = 720`, `maxOpzione = 860`, `lettera = 30`, `paddingOpzione = (13, 16)`, `raggioOpzione = 16`, `spazioOpzioni = 10`, `spostamentoPassaggio = 4`), caratteri (`domanda` 26 bold −0,5 interlinea 1,25; `opzione` 15; `titoloEsame` 20 bold; `spiegazione` 14 interlinea 1,5; `esitoSpiegazione` 16 bold) e soglie (`sogliaVerde = 70`, `sogliaArancio = 55`). Il raggio 16 dell'opzione non è tra i raggi di `Tema.Apple.Raggio` (14, 18, 20, 22): va aggiunto come `Raggio.opzione = 16`.
- **Moto**: `RispostaSbagliata`, `Spiegazione`, `CambioDomanda`, `Opzione` (`durata = 0.30`, curva `ease`) in `TemaAppleMoto.swift`.
- **Carattere**: 28 in `dimensioniCentroAnello`.
- **Simulatore già impostato**: `SimulatoreIpotesi` oggi non riceve un'ipotesi da fuori. Serve un `StatoShell.apriSimulatore(con: Simulazione)` che lo apre con capitale, anni e rendimento della domanda, **senza salvarla** finché l'utente non lo chiede.
- **Apertura di un documento preciso**: c'è `apri(.documenti)`, ma va verificato che si possa aprire **quel** KID nel dossier del cliente. Se non si può, serve `StatoShell.apriDocumento(_ d: Documento)`.

#### 5.3 Motori nuovi
**`Motori/MotoreEsameOCF.swift`** (funzioni pure, nessuna dipendenza dalla UI):
```swift
struct PreparazioneOCF {
    let complessiva: Double?            // nil se nessuna materia ha abbastanza risposte
    let materie: [StatoMateria]         // nell'ordine di MateriaOCF.ordine
    let daRipassareOggi: Int
    let puntoDebole: MateriaOCF?        // la più bassa tra quelle con un dato
    let giorniAllEsame: Int?            // nil senza data
    let domandeDisponibili: Int
}
struct StatoMateria { let materia: MateriaOCF; let percentuale: Double?; let risposte: Int; let fascia: FasciaOCF }  // verde, arancio, rosso, nessuna
enum MotoreEsameOCF {
    static func preparazione(domande: [DomandaOCF], risposte: [RispostaOCF], esame: ImpostazioniEsameOCF, oggi: Date, cal: Calendar) -> PreparazioneOCF
    static func ripasso(di domandaId: String, risposte: [RispostaOCF], cal: Calendar) -> StatoRipasso   // passo e prossima data
    static func sessione(domande: [DomandaOCF], risposte: [RispostaOCF], materia: MateriaOCF?, oggi: Date, cal: Calendar, nuove: Int) -> [String]  // id in ordine
}
```
Regole proposte (da confermare, Dubbi 2-5):
- **Percentuale di una materia**: quota delle domande giuste **all'ultima risposta**, tra le domande di quella materia a cui si è risposto almeno una volta. Così il ripasso fatto bene alza il numero. Con meno di **5** domande risposte nella materia la percentuale è nil: si vede «—».
- **Complessiva**: media semplice delle materie con un dato, come nel template. Se l'utente indica il peso di ogni materia nell'esame (§6) diventa una media pesata.
- **Fascia**: verde da 70, arancio da 55, rosso sotto.
- **Ripasso a intervalli 1-3-7**: una risposta sbagliata mette la domanda al passo 1 (torna domani). Quando torna, se è giusta sale al passo 3 (tra 3 giorni), poi al passo 7 (tra 7 giorni); giusta anche al passo 7, la domanda è **imparata** ed esce dal ripasso. Una sbagliata, a qualunque passo, la riporta al passo 1. Una domanda giusta al primo colpo non entra nel ripasso. Il calcolo si fa per giorni di calendario (`cal.startOfDay`), non per ore.
- **Da ripassare oggi**: domande col ripasso scaduto oggi o prima.
- **Sessione**: prima le domande da ripassare (dalla più in ritardo), poi `nuove` domande mai viste, scelte dalla materia più debole e poi a rotazione. «domanda N di M» conta la sessione.
- **Giorni all'esame**: giorni di calendario da oggi alla data. Il giorno stesso dell'esame: «L'esame è oggi».

**`Motori/MotoreCasoVero.swift`**: dato un `CasoOCF` (etichetta della domanda) e i dati dell'archivio, trova il caso concreto e prepara testo e destinazione. Se non trova niente restituisce nil e il pulsante **non compare**. Il testo del pulsante lo scrive Prisma con il nome vero, non il file.
```swift
struct CasoVero { let testo: String; let destinazione: DestinazioneCaso }  // .documento(id), .posizione(id), .cliente(id), .simulatore(Simulazione)
static func caso(_ c: CasoOCF, parametri: [String: Double], dati: DatiPrisma, clienteAttivo: String?) -> CasoVero?
```
Casi minimi, quelli del template:
- `kid` → il primo KID (`Documento.tipo == .kid`) del cliente attivo, altrimenti il più recente: «Apri il KID del piano di <nome>»;
- `interesse-composto` → il simulatore con i `parametri` della domanda (`capitale`, `tasso`, `anni`): «Provalo nel simulatore di Analisi 360»;
- `rivalutabile-consolidamento` → la prima posizione con `consolidamento == true` (del cliente attivo, se c'è): «Guarda la polizza rivalutabile di <nome>».
Altri casi possibili, con dati che Prisma ha già: `questionario` (documento `CategoriaDocumento.questionario`), `tfr` (strumento TFR di Analisi 360), `multiramo` (posizione multiramo), `gestione-separata-senza-consolidamento`, `fondo-pensione` (posizione previdenziale).

**`Motori/ImportaDomandeOCF.swift`**: legge CSV e JSON (§5.6) e restituisce `ImportazioneDomandeOCF { nuove, aggiornate, uguali, scartate: [(riga: Int, motivo: String)] }`. Prima di salvare l'utente vede un riepilogo, come per `ImportaClienti`.

#### 5.4 Campi nuovi dell'archivio (stessa versione 26 di Orizzonte, nomi proposti)
Letti con tolleranza (`decodeIfPresent … ?? []`): un archivio versione 25 si apre senza errori.
- `DatiPrisma.domandeOCF: [DomandaOCF]`:
  `id: String`, `materia: MateriaOCF`, `testo: String`, `opzioni: [String]` (4), `giusta: Int` (0-3), `spiegazione: String?`, `riferimento: String?` (norma o pagina del manuale), `caso: CasoOCF?`, `parametri: [String: Double]`, `fonte: String?` (nome del file o del manuale), `importataIl: Date`.
- `DatiPrisma.risposteOCF: [RispostaOCF]`: `domandaId`, `data`, `scelta: Int?` (nil = saltata), `giusta: Bool`. Lo storico è la sola fonte: passo e prossima data del ripasso si **ricavano** dal motore, non si salvano. Meno stato e più facile da provare.
- `Impostazioni.esameOCF: ImpostazioniEsameOCF`: `dataEsame: Date?`, `pesiMaterie: [MateriaOCF: Int]?` (domande per materia nell'esame vero), `nuovePerSessione: Int` (proposta 10), `promemoriaRipasso: Bool` (proposta false), `inAgenda: String?` (id dell'appuntamento creato).
- `enum MateriaOCF: String, Codable, CaseIterable`: `mercato`, `matematica`, `pianificazione`, `previdenza`, `privato`, `tributario`. Il nome che si vede è quello del template (§1.3). Se l'utente usa nomi diversi, il nome sta nel file (Dubbio 1).
- `enum CasoOCF: String, Codable` con i casi del §5.3. Un valore sconosciuto si legge come nil (tolleranza).

**Backup:** domande, risposte e impostazioni dell'esame vanno nel backup. `Prisma --prova-backup` (`Dati/ProvaBackup.swift`) deve verificare che tornino uguali dopo il ripristino, e che un archivio senza questi campi si apra.

#### 5.5 Prove nuove
**`Motori/ProvaCalcoliEsameOCF.swift`**, collegata da `ProvaCalcoli.swift` come le altre (`ProvaCalcoliEsameOCF.esegui(verificaEsterna)`). Casi:
1. Materie 72, 58, 81, 77, 49, 61 → complessiva **66** (398 / 6 = 66,33); punto debole **Diritto privato e commerciale**; fasce verde, arancio, verde, verde, rosso, arancio.
2. Soglie esatte: 70 → verde, 69,9 → arancio, 55 → arancio, 54,9 → rosso.
3. Materia con 4 risposte → percentuale nil, esclusa dalla media e dal punto debole.
4. Ultima risposta conta: domanda sbagliata e poi giusta → giusta nella percentuale.
5. Ripasso: sbagliata il 2/11/2026 → torna il **3/11**; giusta il 3/11 → **6/11**; giusta il 6/11 → **13/11**; giusta il 13/11 → imparata. Sbagliata il 6/11 → torna il **7/11** al passo 1.
6. Giusta al primo colpo → nessun ripasso.
7. Da ripassare oggi: tre domande scadute (una di ieri, due di oggi) e una di domani → **3**; ordine della sessione: prima quella di ieri.
8. Cambio d'ora: sbagliata sabato 24/10/2026 alle 23:30 → torna domenica **25/10** (notte del cambio d'ora), non il 26.
9. Giorni all'esame: oggi 3/11/2026, esame 18/2/2027 → **107**.
10. Domanda di prova 2: 10.000 × 1,03² = **10.609** € (verifica che `parametri` e la risposta giusta coincidano: per i casi `interesse-composto` il motore controlla la risposta e segnala la domanda se non torna).
11. Caso vero: con i dati di prova `kid` → documento KID di Giulia; `rivalutabile-consolidamento` → una posizione con `consolidamento == true`; archivio vuoto → nil per tutti.
12. Importazione CSV: BOM, separatore `;`, «giusta» scritta `b` minuscola → indice 1; riga con 3 opzioni → scartata con motivo; id già presente con testo diverso → «aggiornata», storico conservato; riga uguale → «uguale».
13. Importazione JSON: `versione` sconosciuta → errore leggibile; `materia` sconosciuta → riga scartata.

#### 5.6 Formato per importare le domande (proposta)
Due formati, stesso contenuto. **Una domanda = una riga (CSV) o un oggetto (JSON).** Il file non contiene mai dati dei clienti.

**CSV** (Excel o Numbers, UTF-8 o Latin-1, separatore `;` oppure `,` oppure tab, prima riga = intestazione; l'ordine delle colonne è libero e si riconosce dal nome, come in `ImportaClienti.Colonna`):

```
id;materia;domanda;a;b;c;d;giusta;spiegazione;riferimento;caso;parametri
MF-001;mercato;Che cos'è il KID?;Il documento con le informazioni chiave dei prodotti d'investimento preassemblati (PRIIPs);Il contratto quadro tra cliente e intermediario;Il questionario di profilatura del cliente;Il rendiconto annuale dei costi;A;Il KID è previsto dal regolamento PRIIPs: in poche pagine descrive rischi, scenari e costi del prodotto.;Reg. UE 1286/2014;kid;
MAT-001;matematica;10.000 € investiti al 3% composto annuo, dopo 2 anni valgono:;10.600 €;10.609 €;10.300 €;10.900 €;B;Interesse composto: 10.000 × 1,03 × 1,03 = 10.609 €.;;interesse-composto;capitale=10000|tasso=3|anni=2
```

| Colonna | Obbligatoria | Regola |
|---|---|---|
| `id` | no | codice stabile della domanda. Se manca, Prisma lo ricava dal testo (impronta di materia + domanda), così reimportare lo stesso file non crea doppioni |
| `materia` | sì | codice (`mercato`, `matematica`, `pianificazione`, `previdenza`, `privato`, `tributario`) oppure il nome intero della materia, senza badare a maiuscole e accenti |
| `domanda` | sì | testo, anche con «;» se tra virgolette |
| `a` `b` `c` `d` | sì | le quattro opzioni |
| `giusta` | sì | `A`-`D` (anche minuscolo) oppure `1`-`4` |
| `spiegazione` | no | se manca, sotto la domanda chiusa compare solo l'esito |
| `riferimento` | no | norma, articolo o pagina del manuale, mostrato in `.k` sotto la spiegazione |
| `caso` | no | uno dei casi del §5.3; sconosciuto → ignorato, non scarta la riga |
| `parametri` | no | `chiave=valore` separati da `|`, numeri col punto o con la virgola |

**JSON**:
```json
{
  "formato": "prisma-domande-ocf",
  "versione": 1,
  "fonte": "Manuale di preparazione, edizione 2026",
  "domande": [
    {
      "id": "MAT-001",
      "materia": "matematica",
      "testo": "10.000 € investiti al 3% composto annuo, dopo 2 anni valgono:",
      "opzioni": ["10.600 €", "10.609 €", "10.300 €", "10.900 €"],
      "giusta": 1,
      "spiegazione": "Interesse composto: 10.000 × 1,03 × 1,03 = 10.609 €. Gli interessi del primo anno producono interessi nel secondo.",
      "riferimento": null,
      "caso": "interesse-composto",
      "parametri": { "capitale": 10000, "tasso": 3, "anni": 2 }
    }
  ]
}
```
In JSON `giusta` è l'indice da 0. È accettata anche la lettera (`"B"`).

**Controlli all'importazione** (riga scartata, con il motivo nel riepilogo): materia sconosciuta, domanda vuota, meno o più di quattro opzioni, due opzioni uguali, `giusta` mancante o fuori intervallo. Il riepilogo dice per esempio **«240 domande pronte · 12 aggiornate · 3 righe scartate: manca la risposta giusta (righe 12, 40, 41)»**. Si conferma con **«Importa»**, oppure si annulla.

**Modello scaricabile:** «Scarica il modello CSV», un file con l'intestazione e le tre domande del template.

**Ruby (facoltativo, dopo):** da un PDF di quesiti Ruby può proporre le righe nel formato qui sopra (`EstrattoreDocumento`). Le righe passano sempre dal riepilogo e l'utente le conferma una per una o tutte insieme. La risposta giusta non la decide mai Ruby: se nel PDF non c'è, la riga resta scartata.

#### 5.7 iPhone e iPad (proposta breve)
iPad: le due card come sul Mac. iPhone (gerarchia di `Design/iphone.html`): in alto la cosa principale, cioè la domanda con le opzioni a tutta larghezza; sopra una riga compatta con l'anello da 44 e «14 da ripassare oggi»; le materie a un tocco.

---

### 6. Dati che l'utente deve dare (mai inventarli)
1. **Le domande**, con le risposte giuste e, se ci sono, le spiegazioni: dal suo manuale o dalla banca dati che usa, nel formato del §5.6.
2. **Le materie dell'esame** e i loro nomi esatti, se diversi dai sei del template. Se vuole la media pesata, **quante domande ha ogni materia** nell'esame vero.
3. **La data dell'esame** (facoltativa).
4. Conferma delle regole: soglie 70 / 55, ripasso 1-3-7, minimo di 5 risposte per materia, 10 domande nuove per sessione.

**Cosa si vede finché mancano:**
- **Nessuna domanda importata** (stato vuoto). Card 1: anello vuoto (solo binario) con **«—»** al centro, «Esame OCF», **«Nessuna domanda ancora»**, le sei materie con il binario vuoto e **«—»**. Card 2, al centro: **«Importa le domande del tuo manuale»**, sotto in `.k` **«Un file CSV o JSON: una domanda per riga, con la risposta giusta e, se vuoi, la spiegazione.»**, pulsanti **«Importa domande…»** (primario) e **«Scarica il modello»**. Niente piede del ripasso.
- **Domande sì, risposte no**: anello vuoto e «—», **«240 domande pronte»** al posto di «da ripassare», materie a «—», card 2 con la prima domanda della sessione.
- **Materia con poche risposte**: «—» e, al passaggio del puntatore, «Ancora poche risposte (3 di 5)».
- **Ripasso di oggi finito**: nella card 2, **«Per oggi il ripasso è finito.»** e in `.k` «Le prossime tornano domani: 6 domande.» (cifra dal motore), pulsante **«Altre domande nuove ›»**.
- **Senza data dell'esame**: il pulsante «Imposta la data dell'esame», come nel template.
- **Caso vero non trovato**: il pulsante «◎ …» non compare. Niente nomi finti.
- **Errore d'importazione** (file illeggibile, JSON rotto, versione sconosciuta): riquadro con il bordo arancio (`Colore.avvisoFondo` / `avvisoBordo`): **«Non riesco a leggere il file.»** e il motivo in una riga. L'archivio resta com'era.
- **Caricamento**: non serve, l'importazione è locale e veloce. Sopra 5.000 righe, durante la lettura il pulsante diventa **«Leggo il file…»** con la barra (`Moto.TiPreparo`).
- **Dati di prova** (solo caricando i clienti di prova da Impostazioni): le tre domande del template, più uno storico di risposte di prova che dà 72, 58, 81, 77, 49, 61 e 14 domande da ripassare. Accanto a «LA TUA PREPARAZIONE» compare l'etichetta **«dati di prova»** (`.k`). Domande e storico di prova **non devono mai finire nell'archivio reale** e si tolgono insieme ai clienti di prova.

---

### 7. Istantanee da aggiungere
Numeri dopo quelli di 01 (500-507), 02 (510-…) e 03 (520-521). Tutte in chiaro e in scuro (`-scuro`), nello stato finale.

| Nome | Cosa mostra |
|---|---|
| `530-studio-ocf` / `-scuro` | dati di prova, prima domanda aperta (come `*-20-allenamento-ocf.png`) |
| `531-studio-ocf-sbagliata` / `-scuro` | prima domanda, scelta C: A verde, C rossa, B e D al 50 %, spiegazione «Non proprio: torna tra un giorno.» con «◎ Apri il KID del piano di Giulia» (come `ocfshots/sbagliata.png`) |
| `532-studio-ocf-giusta` / `-scuro` | seconda domanda, scelta B: «Giusto.» e «◎ Provalo nel simulatore di Analisi 360» (come `ocfshots/giusta.png`) |
| `533-studio-ocf-vuoto` / `-scuro` | nessuna domanda importata: anello vuoto, materie a «—», invito a importare |
| `534-studio-ocf-data-esame` / `-scuro` | data impostata: pulsante «Esame il … · mancano … giorni» e riquadro aperto con il calendario |
| `535-studio-ocf-importazione` / `-scuro` | riepilogo dell'importazione con domande pronte, aggiornate e righe scartate col motivo |
| `536-studio-ocf-ripasso-finito` / `-scuro` | «Per oggi il ripasso è finito.» |
| `537-studio-ocf-domanda-lunga` | domanda su tre righe e opzioni su due righe, per controllare a capo e altezze (solo chiaro) |
| `400-vetrina-apple` / `-scuro` (esistente) | aggiungere un'opzione nei tre stati (normale, giusta, sbagliata) e la tile della spiegazione |

Per il tremolio e il cambio di domanda le istantanee non bastano: serve uno screenshot o una registrazione dall'utente.

---

## 12. Mercato — «Prisma conosce il mercato»

*Parte 06 · titolo della bozza: «Orizzonte · 06 · Mercato («Prisma conosce il mercato»)»*

Fonte: `Design/template-novita.html`, righe 890-906 (`MKT`, `APPS.mercato`). Funzioni d'appoggio: righe 262-292 (`entrata`, `inclina`, `disegnaLinea`, `linee`, `toast`, `avatar`, `TONE`). CSS: righe 32-54, 105, 117, 127-129, 210.
Per tutto ciò che qui non è detto valgono `Design/template-apple-specifica.md` e `spec/00-comune.md`: barra, dock, finestra, icona Mercato (§1.4), testata (§1.6), voce 3 del pannello Novità.
Le cifre del template sono dimostrative. Nell'app le danno i motori e le fonti scelte dall'utente.

Riferimenti visivi (1480×940, palco 1440×900 scalato di 1,0137):
- `orizzonte/chiaro-12-prisma-conosce-il-mercato.png`, `orizzonte/scuro-12-prisma-conosce-il-mercato.png`: la finestra ferma.
- `orizzonte/mk/chiaro-isin.png`, `orizzonte/mk/scuro-isin.png` (1440×900, scattate per questa parte): ricerca dell'ISIN «IE00B4L5Y983», secondo avviso spento.
- `orizzonte/mk/chiaro-avviso.png`, `orizzonte/mk/scuro-avviso.png`: il toast di «＋ Nuovo avviso».

Il copione che le rifà sta in `orizzonte/mk/mk.js`. Si lancia con `node mk.js <percorso di t.html> <cartella>`.

---

### 1. Cosa si vede

#### 1.1 Come si arriva

- Dal dock: è la nona voce, «Mercato», fra Prospetti e Studio (00-comune §1.3).
- Dal pannello Novità: voce 3, «Prisma conosce il mercato» · «Quote e tassi aggiornati, avvisi, chi è toccato» (`vaiA('mercato')`).
- Non esiste una scheda interna: l'app è una sola vista, senza segmenti.

#### 1.2 Testata della finestra

| Parte | Testo esatto |
|---|---|
| Barra del titolo | icona Mercato · «Mercato» |
| Titolo (`h`) | «Prisma conosce il mercato.» |
| Occhiello (`sub`) | «Aggiornato oggi alle 18:00 · valori di prova». Il CSS `.sub` lo mette in maiuscolo: «AGGIORNATO OGGI ALLE 18:00 · VALORI DI PROVA» |
| Comandi a destra (`act`) | 1. campo di ricerca a pillola, con il testo d'invito «Cerca un ISIN» e il pulsante «Cerca» dentro la pillola. 2. Pulsante principale blu «＋ Nuovo avviso». Il «＋» è il carattere a larghezza piena U+FF0B |

In Prisma l'occhiello lo scrive il motore (§5.3):
- «Aggiornato oggi alle 18:00»;
- «Aggiornato ieri alle 18:00»;
- «Aggiornato il 28 ottobre»;
- «Mai aggiornato».

La parte «· valori di prova» compare solo con i dati di prova caricati.

#### 1.3 Struttura del contenuto, dall'alto

1. **Fascia della riservatezza**, su tutta la larghezza, verde chiaro. Contiene «🔒» e poi il testo: «Dal Mac escono solo gli ISIN e le richieste di dati pubblici: **nessun dato dei clienti lascia Prisma.**» (il grassetto è solo la seconda parte).
2. **Striscia del mercato**: sei tessere uguali in una griglia di 6 colonne. Ogni tessera contiene, dall'alto:
   - il nome (piccolo, grigio);
   - il valore (grande);
   - la variazione (colorata);
   - una mini linea di 9 punti.
3. **Due riquadri affiancati** fino al fondo della finestra:
   - a sinistra, più largo (flex 1,25), «Chi è toccato oggi»;
   - a destra (flex 1), «Avvisi». Il risultato della ricerca ISIN compare in fondo a questo riquadro.

#### 1.4 Le sei tessere (testi del template)

| # | Nome | Valore | Variazione | Tono | Linea (9 punti, dal più vecchio) |
|---|---|---|---|---|---|
| 1 | Azioni Italia | 34.180 | +0,6% | verde (1) | 30 · 31 · 30,5 · 32 · 31,6 · 33 · 32,4 · 33,8 · 34,18 |
| 2 | Azioni mondo | 3.712 | −1,8% | rosso (0) | 3500 · 3560 · 3610 · 3580 · 3690 · 3760 · 3790 · 3780 · 3712 |
| 3 | BTP 10 anni | 3,42% | +0,15 | rosso (0) | 3,1 · 3,2 · 3,15 · 3,3 · 3,25 · 3,2 · 3,3 · 3,27 · 3,42 |
| 4 | Euribor 3 mesi | 2,08% | −0,02 | verde (1) | 2,4 · 2,35 · 2,3 · 2,25 · 2,2 · 2,18 · 2,12 · 2,1 · 2,08 |
| 5 | Inflazione Italia | 1,6% | −0,2 | verde (1) | 2,1 · 2 · 1,9 · 1,9 · 1,8 · 1,8 · 1,7 · 1,8 · 1,6 |
| 6 | Tasso BCE | 2,00% | invariato | neutro (2) | 2,5 · 2,5 · 2,25 · 2,25 · 2 · 2 · 2 · 2 · 2 |

Come si leggono le cifre:
- **Formati**:
  - per gli indici, punto delle migliaia e nessun decimale («34.180»), variazione in percentuale con una cifra decimale e virgola («+0,6%»);
  - per tassi e inflazione, il valore in percentuale con due decimali (con uno per l'inflazione: «1,6%»), variazione in **punti** senza «%» («+0,15», «−0,02», «−0,2»);
  - «invariato» quando la variazione è zero.
  - Il meno è quello tipografico «−» (U+2212).
- **Il tono non è il segno.** Dice se la variazione è buona o cattiva per i clienti:
  - BTP in salita (+0,15) = **rosso**, perché i prezzi dei titoli scendono;
  - Euribor e inflazione in discesa = **verde**;
  - Azioni mondo in discesa = rosso;
  - Tasso BCE fermo = neutro, grigio.

  È una regola del motore (§5.3), da confermare (Dubbi).
- Il colore della mini linea segue il tono, non l'andamento: la linea del BTP sale ed è rossa, quella dell'Euribor scende ed è verde.

#### 1.5 «Chi è toccato oggi»

Etichetta in maiuscolo: «CHI È TOCCATO OGGI». Sotto ci sono tre schede (`.tile`), ognuna con un filo colorato a sinistra. Ogni scheda contiene:
- un titolo in grassetto;
- una frase grigia;
- un gruppo di avatar sovrapposti;
- il pulsante «Prepara un messaggio».

| # | Titolo | Frase | Avatar (indici `CLI`) | Tono |
|---|---|---|---|---|
| 1 | Azioni mondo −1,8% oggi | 6 clienti hanno più del 40% in azioni: il portafoglio di Marco perde circa 3.000 €. | Marco Bianchi, Andrea Conti, Laura Moretti | rosso |
| 2 | Il rendimento dei BTP sale di 0,15 punti | 3 clienti con titoli di Stato: il valore scende un po’, la cedola resta quella. | Sofia (indice 4), Giulia Rossi | arancio |
| 3 | Inflazione all’1,6% | Buona notizia per chi ha obiettivi lontani: il potere d’acquisto tiene. | Laura Moretti, Giulia Rossi, Andrea Conti | verde |

Le cifre sono coerenti con la prova del fuoco:
- nel template Marco ha 318.400 € con il 52% in azioni (`FUOCO[1]`);
- 318.400 × 0,52 × 1,8% = 2.980 €, cioè «circa 3.000 €».

Il motore deve ripetere questo calcolo (§5.5).

**Difetto del template.** Gli avatar sovrapposti non si vedono. In chiaro restano bianchi su bianco, in scuro si leggono solo le lettere accavallate «MBACLM», «SRGR» e «LMGRAC». La causa: `avatar(...).replace('class="av"', 'class="av" style="margin-left…"')` aggiunge un **secondo** attributo `style`, che il browser ignora. Così si perdono larghezza, altezza e sfumatura.

Quello che si voleva:
- avatar da 30;
- ognuno spostato di −8 sul precedente (il primo no);
- un bordo di 2 nel colore `--cardE`, che li stacca uno dall'altro.

In Prisma va fatto così.

Il titolo della scheda 1 parla di «6 clienti», ma gli avatar sono 3. Proposta: al massimo 3 avatar, poi un cerchietto «+3» (Dubbi).

#### 1.6 «Avvisi»

Etichetta in maiuscolo: «AVVISI». Sotto c'è un elenco di righe separate da un filo. Ogni riga contiene:
- un pallino del tono;
- l'avatar del cliente (30);
- il titolo in grassetto e la descrizione grigia;
- un interruttore a destra, acceso.

| # | Titolo | Descrizione | Cliente | Tono |
|---|---|---|---|---|
| 1 | Portafoglio di Marco | −6% dal massimo · soglia −5% | Marco Bianchi | rosso, il pallino **pulsa** |
| 2 | Cedola del BTP di Sofia | tra 12 giorni | Sofia | arancio |
| 3 | Andrea si allontana dal riferimento | di 4 punti in un mese | Andrea Conti | arancio |
| 4 | Fondo pensione di Laura | +2% in un mese | Laura Moretti | verde |

Il rosso vuol dire «soglia superata». L'arancio vuol dire «da guardare» o «in arrivo». Il verde è una buona notizia.

#### 1.7 Risultato della ricerca ISIN (`#isinR`)

Compare in fondo al riquadro «Avvisi», sotto l'ultima riga, come scheda `.tile`:

- prima riga: «Fondo di prova azionario globale» in grassetto a sinistra e l'ISIN cercato a destra, grigio, in maiuscolo;
- seconda riga, tre cifre con l'etichetta sopra:
  - «Quota» · **18,42 €**;
  - «Da inizio anno» · **+6,1%**, in verde;
  - «Nei portafogli» · **3 clienti**.

Con il campo vuoto il template cerca «LU0000000000», un codice che **non** supera la cifra di controllo. Il risultato è sempre lo stesso fondo, qualunque sia l'ISIN. Una nuova ricerca sostituisce la scheda precedente.

#### 1.8 Toast

«＋ Nuovo avviso» mostra il toast «Nuovo avviso: scegli il cliente, la posizione e la soglia».

#### 1.9 Stati

Il template ha solo lo stato pieno, con i valori di prova. Per Prisma propongo questi stati, tutti con il testo deciso qui e da confermare.

| Stato | Cosa si vede |
|---|---|
| **Mai aggiornato** (nessuna serie, nessun dato di prova) | Occhiello «Mai aggiornato». Al posto della striscia c'è una tessera larga con «Prisma non ha ancora i dati del mercato.» e due pulsanti, «Scarica i dati pubblici» (solo se l'utente l'ha permesso in Impostazioni) e «Importa un file» (CSV o Excel). I riquadri sotto dicono «Chi è toccato compare quando ci sono i dati del giorno.» e «Nessun avviso. Crea il primo con ＋ Nuovo avviso.» |
| **Aggiornamento in corso** | Occhiello «Aggiornamento in corso…». Le tessere già note restano con la linea ferma. Le tessere ancora senza valore mostrano il binario della linea (in `--track`) e «—» al posto del valore. Non c'è nessuna rotellina |
| **Dati vecchi** (ultimo valore più vecchio di 3 giorni lavorativi) | Occhiello «Aggiornato il 28 ottobre». Sulla tessera c'è la data dell'ultimo valore al posto della variazione del giorno. «Chi è toccato oggi» diventa «Chi è toccato dall’ultimo aggiornamento» |
| **Fonte non raggiungibile** | Toast «La BCE non risponde: restano i valori del 31 ottobre». I valori restano quelli di prima. Niente errore rosso a tutta finestra |
| **Rete non permessa** (scelta predefinita, vedi Dubbi) | Fascia della riservatezza con il testo «Nessun dato esce dal Mac: i valori arrivano dai file che importi.» La striscia mostra solo le serie importate o inserite |
| **Una serie senza valore** | La tessera resta al suo posto con il nome, «—» e la frase «Da importare» in `--ink3` |
| **Nessuno toccato** | Nel riquadro, al centro, «Oggi i movimenti del mercato non toccano in modo visibile i tuoi clienti.» |
| **ISIN non valido** (forma o cifra di controllo) | Sotto il campo, in rosso: «Questo codice non è un ISIN valido: controlla le 12 cifre.» Niente ricerca |
| **ISIN valido ma sconosciuto** | Scheda con «Nessuna quota per IE00B4L5Y983», «Nei portafogli» (il numero, anche 0) e il pulsante «Importa le quote» |
| **ISIN nei portafogli ma senza quota** | Scheda con il nome della posizione, «Quota —» e «Nei portafogli · 3 clienti» |

---

### 2. Misure e stile

Le misure sono in pt del palco 1440×900. Arrivano dal CSS, dal JS e dalle misure prese con Playwright (bordi compresi).

#### 2.1 Disposizione

| Cosa | Valore |
|---|---|
| Area del contenuto `#wc` | finestra 16, 42, 1408 × 758; contenuto da `left 12`, `right 12`, `top 92`, `bottom 12`, cioè 1384 × 654 (sul palco da x 28 a 1412 e da y 134 a 788) |
| Fascia della riservatezza | 1382 × 42 a (29, 135): inizia in cima al contenuto |
| Striscia | `margin-top 12`; griglia `repeat(6, 1fr)`, `gap 12`; tessere 220 × 139 a y 189, x = 29, 261, 494, 726, 958, 1191 |
| Riquadri in basso | `position: absolute; top 206; bottom 0; left 0; right 0`, `display flex`, `gap 14`. Misurati: sinistro 755 × 432 a (29, 355), destro 613 × 432 a (798, 355). Con `flex 1.25 / 1` la teoria dà 761 / 609: la differenza viene dal contenuto (`min-width: auto`). In Prisma vale la proporzione 1,25 : 1 |
| Comandi della testata | campo ISIN 237 × 33 a (1035, 87); «＋ Nuovo avviso» 127 × 33 a (1278, 87); spazio fra i due 6 (`#wAct gap 6`) |

In Prisma conviene un `Tema.Apple.Mercato.Disposizione` con questi valori:
- `spazioStriscia = 12`;
- `colonne = 6`;
- `altezzaTessera = 139`;
- `cimaRiquadri = 206`, che è altezza della fascia + 12 + altezza della tessera + 13. Si ricava, non si scrive;
- `spazioRiquadri = 14`;
- `proporzioneRiquadri = 1.25`.

#### 2.2 Superfici

| Superficie | Valore |
|---|---|
| `.card` (tessere e riquadri) | raggio 22, fondo `--card` (bianco all'82% in chiaro, bianco al 7% in scuro), bordo 1 `--sep`, ombra `--shadow` (chiaro `0 24 48 −28 rgba(8,40,60,.4), 0 2 8 −3 rgba(8,40,60,.1)`; scuro `0 26 52 −26 rgba(0,0,0,.8), 0 3 10 −3 rgba(0,0,0,.35)`). È la scheda del tema Apple che c'è già |
| Fascia della riservatezza | `.card` **senza ombra**, padding 10 × 16, `display flex`, `gap 10`, fondo `rgba(47,163,90,.08)`, bordo `rgba(47,163,90,.22)`, uguale in chiaro e in scuro. È lo stesso verde del «✓ Consenso all’ascolto» del copilota: un solo token, `Tema.Apple.Colore.fasciaRiservatezza` (fondo e bordo) |
| `.tile` (schede di «Chi è toccato» e risultato ISIN) | raggio 18, fondo `--card`, bordo 1 `--sep`, padding 14 × 16, nessuna ombra |
| Filo del tono sulle schede | `border-left: 4px solid` del tono. Sostituisce il bordo sinistro da 1 e si piega con il raggio 18: in alto e in basso a sinistra si vede un arco colorato (vedi le PNG) |
| Pallino dell'avviso | 10 × 10, raggio 9, tono, `flex none` |
| Riga dell'avviso | `.row`, padding 12 × 0, `gap 12`, filo sotto 1 `--sep`, anche sull'ultima riga. Passo misurato fra le righe: 60 |
| Interruttore `.sw` | 44 × 26, raggio 99, fondo `--track` (nero al 7% in chiaro, bianco al 10% in scuro); acceso #34C759 (`Tema.Apple.Colore.verdeInterruttore`). Pomello 20 × 20 bianco, ombra `0 2 5 rgba(0,0,0,.25)`, a sinistra 3, acceso a 21. È `StileInterruttoreApple` |
| Campo ISIN | pillola: fondo `--chip`, raggio 99, padding 3 3 3 14. Campo senza bordo né contorno, fondo trasparente, 13 pt, largo 150. Pulsante «Cerca» `.btn` con padding 5 × 12 |
| `.btn` | raggio 99, padding 7 × 14, 12,5 pt / 600, fondo `--cardE` (#fff in chiaro, rgba(40,54,66,1) in scuro), bordo 1 `--sep` |
| `.btn.pri` | fondo `--accent` #007AFF, testo #fff, bordo trasparente |
| Avatar | cerchio, sfumatura con i due colori del cliente, iniziali bianche 600 a `round(30 × 0,34)` = 10 pt. In «Chi è toccato» bordo 2 `--cardE` e spostamento −8 (§1.5). È `AvatarCliente` |
| Toast | fondo `rgba(15,36,51,.92)`, testo #fff 13 pt, padding 9 × 16, raggio 99, `top 44`, centrato. È il toast del tema |

#### 2.3 Caratteri

| Testo | Carattere |
|---|---|
| Nome della tessera | `.k`: 12,5 pt, `--ink2` |
| Valore della tessera | `.v` a 24 pt (la classe dice 26, la riga la porta a 24): SF Pro Display, 700, spaziatura −0,5, cifre tabellari |
| Variazione | 12,5 pt / 700, nel colore del tono: verde `--green` #2FA35A, rosso `--red` #E5484D, neutro `--ink2` |
| Etichette dei riquadri | `.lbl`: 12 pt / 600, maiuscolo, spaziatura 0,6, `--ink2` |
| Titolo della scheda di «Chi è toccato» | 14,5 pt, grassetto (700) |
| Frase della scheda | `.k` a 13 pt, interlinea 1,4, 2 sotto il titolo |
| Titolo dell'avviso | 14 pt, grassetto |
| Descrizione dell'avviso | `.k`, 12,5 pt |
| Testo della fascia | 13,5 pt, `--ink`. La parte in grassetto è 700. «🔒» a 16 pt |
| Risultato ISIN | nome in grassetto 14 pt (ereditato), ISIN `.k`; etichette `.k`; cifre `.v` a 20 pt; «Da inizio anno» in `--green` |

#### 2.4 Mini linea

| Cosa | Valore |
|---|---|
| Riquadro | SVG `viewBox 0 0 190 40`, `preserveAspectRatio none`, largo quanto la tessera meno il padding (188), alto 40, `margin-top 6`, `overflow visible` |
| Punti | X(i) = i / (n − 1) × 190; Y(v) = 38 − (v − min) / (max − min) × 34. Se max = min, il divisore è 1: la linea è piatta in fondo, a 38 |
| Tratto | 2,2, capi tondi, `vector-effect: non-scaling-stroke` (lo spessore non si stira con la tessera) |
| Colori | verde #30B15C (= `Tema.Apple.Colore.anello1`), rosso #E5484D (= `rosso`), neutro #9FB3C2 (= `Investimenti.liquidita`). **Fissi** in chiaro e in scuro. Attenzione: la cifra verde della variazione è #2FA35A, la linea verde è #30B15C. Sono due tinte quasi uguali, già presenti tutte e due nel tema |
| Riempimento | nessuno: solo la linea, senza area, senza punto finale e senza griglia |

In Prisma la mini linea è `TracciatoGrafico` (`DesignSystem/Apple/GraficiApple.swift`) con `area: false` e `puntoFinale: false`. Lo spessore 2,2 è nuovo e va in `Tema.Apple.Grafico.Tracciato.spessoreMini`. La normalizzazione dei punti la fa il motore, che restituisce punti da 0 a 1.

#### 2.5 Colori dei toni

`TONE = { r: #E5484D, o: #E08A00, g: #2FA35A }`: sono `Tema.Apple.Colore.rosso`, `.arancio` e `.verde`, uguali in chiaro e in scuro. Nessun token nuovo, tranne la fascia della riservatezza (§2.2) e lo spessore della mini linea.

#### 2.6 Scuro

Cambiano solo i token di `body.dark`:
- `--card`, `--cardE`, `--sep`, `--track`, `--chip`;
- inchiostri e ombra.

Toni, linee, fascia verde e interruttore restano uguali. Nelle PNG scure la fascia è un velo verde appena visibile sul vetro scuro.

---

### 3. Movimento

| Cosa | Da → a | Durata | Curva | Ritardo |
|---|---|---|---|---|
| Contenuto all'apertura dell'app | opacità 0 → 1 | 0,20 s | lineare | 0 |
| Cascata dei blocchi `.st` (`entrata(wc, 140)`) | opacità 0, y +18, scala 0,985, sfocatura 6 → fermi | 0,72 s | `--out (.22,1,.36,1)` | 140 + i·48 ms, con `fill: backwards` |
| Mini linee (`linee`, 6 tracciati `path.draw`) | tratto nascosto (`dashoffset` = lunghezza) → disegnato | 1,5 s | `--out` | 150 + i·120 ms: 150, 270, 390, 510, 630, 750 ms |
| Inclinazione delle tessere (`.tilt`, `data-max 6`) | prospettiva 900; rotateX (0,5 − y)·6·0,8; rotateY (x − 0,5)·6; sale di 5; scala 1,02 | 0,5 s | `--spring (.34,1.45,.64,1)` | — |
| Ombra della tessera sotto il puntatore | → `0 40 60 −30 rgba(8,40,60,.5), 0 4 12 −4 rgba(8,40,60,.16)` | 0,4 s | ease | — |
| Riflesso (`.sheen`) | radiale 260×200 sul puntatore, bianco al 60% in `soft-light` (scuro: al 16%, normale) | 0,3 s | ease | — |
| Pallino rosso dell'avviso (`pulsa`) | a metà ciclo alone `0 0 0 6 rgba(229,72,77,.18)` | 1,6 s | ease | senza fine |
| Interruttore | pomello 3 → 21; fondo `--track` → verde | 0,35 s (pomello, `--spring`); 0,3 s (fondo, ease) | — | — |
| Risultato ISIN | opacità 0, y +10 → fermo | 0,42 s | `--out` | 0 |
| Pulsanti | luminosità 0,97 al passaggio in 0,2 s; trasformazione con `--spring` in 0,25 s | — | — | — |
| Toast | da y −20 e opacità 0 | 0,45 s | `--spring` | resta 2,4 s |

Ordine della cascata, con i = 0…8:
- i = 0: fascia, a 140 ms;
- i = 1…6: le sei tessere, da 188 a 428 ms;
- i = 7: «Chi è toccato oggi», a 476 ms;
- i = 8: «Avvisi», a 524 ms.

Le schede dentro i due riquadri **non** hanno una cascata propria: entrano con il loro riquadro. Nella cascata, in Prisma, si usa `entrataCascata(i)` con `Tema.Apple.Moto.Cascata.baseFinestra` (0,14) e il `passo` (0,048).

Le mini linee usano `Tema.Apple.Moto.Linea` (1,50; 0,15; 0,12): ci sono già tutti i valori. La linea parte a 150 ms, prima che la sua tessera sia entrata del tutto (188 ms e oltre): è voluto, si vede disegnarsi mentre la tessera sale.

**Numeri.** In Mercato il template non conta le cifre: non ci sono `data-n`, i valori compaiono già scritti. La regola generale del tema Apple però dice «i numeri si contano fino al valore». Ci sono due strade:
- **proposta**: contare i sei valori della striscia con `NumeroCheConta` (1,1 s + i·0,06, curva quartica), anche quelli in percentuale con due decimali;
- in alternativa, seguire il template e lasciarli fermi.

È un dubbio (vedi Dubbi). Le cifre del risultato ISIN restano ferme come nel template: compaiono a richiesta, non all'apertura.

**Inclinazione.** Va su `.inclinazione(massimo: Tema.Apple.Moto.Inclinazione.massimoFamiliari)`, che vale già 6. I riquadri in basso, le schede e le righe degli avvisi non si inclinano.

**Riduci movimento** (`ridotto` nel template, `\.prismaCalmo` in Prisma):
- nel template la cascata e le linee durano 1 ms e non hanno ritardo; l'inclinazione **resta** (`inclina` non guarda `ridotto`) e anche `pulsa`;
- in Prisma vale la regola generale: tutto compare fermo con una dissolvenza di 0,15 s, senza inclinazione, senza cascata, senza pulsazione (il pallino resta pieno e senza alone) e senza conteggio;
- l'interruttore cambia stato senza molla.

**Istantanee** (`\.modoIstantanea` e `\.prismaStatoFinale`): linee già tracciate, numeri completi, nessun alone di `pulsa`, nessuna inclinazione.

---

### 4. Interazioni

| Dove | Gesto | Template | Prisma (proposta) |
|---|---|---|---|
| Campo ISIN | Invio o «Cerca» | `submit`: mette in maiuscolo; se il campo è vuoto usa «LU0000000000»; mostra sempre lo stesso fondo di prova | toglie spazi e trattini e mette in maiuscolo. Controlla la forma (`^[A-Z]{2}[A-Z0-9]{9}\d$`, come `EstrattoreDocumento.formaISIN`) e la cifra di controllo ISO 6166. Cerca **prima nell'archivio** (posizioni e schede prodotto con quell'ISIN), poi tra le quote importate. Con il campo vuoto non fa nulla |
| Risultato ISIN | — | nessun clic | clic su «Nei portafogli · 3 clienti»: elenco dei clienti con quella posizione, e da lì si apre la posizione in Posizioni (`StatoShell.apri(.posizioni)`) |
| «＋ Nuovo avviso» | clic | toast | apre un foglio (dettaglio del tema, che nasce dal pulsante) con tre scelte: **cliente**, **posizione** (o «tutto il portafoglio») e **soglia** (tipo e valore, §5.3). «Crea l’avviso» lo aggiunge in cima all'elenco |
| Interruttore dell'avviso | clic | accende e spegne | uguale. Salva `AvvisoMercato.attivo`. Un avviso spento non scatta e non va in Notifiche. La riga resta, con il pallino grigio (`--ink3`) |
| Riga dell'avviso | clic | niente | apre la posizione (o il portafoglio del cliente) in Posizioni. Con il clic secondario: «Modifica la soglia», «Elimina l’avviso» |
| «Prepara un messaggio» | clic | apre Messaggi sul **secondo** messaggio (Marco, Infortuni in scadenza), qualunque sia la scheda. È un segnaposto | apre Messaggi con un'occasione di tipo `mercato` per il primo cliente toccato, con il motivo (titolo della scheda) e le cifre già calcolate: `StatoShell.preparaMessaggio(clienteId:tipo: .mercato, origine:)` della parte 05. Con più clienti, scelta del cliente (vedi Dubbi) |
| Avatar in «Chi è toccato» | — | niente | passaggio: il nome del cliente nel fumetto; clic: apre il dossier |
| Tessera della striscia | passaggio | inclinazione e riflesso; il puntatore è la mano ma il clic non fa nulla | inclinazione e riflesso. Clic: il dettaglio nasce dalla tessera, con la serie lunga (12 mesi), la fonte, la data dell'ultimo valore e il pulsante «Usa come riferimento» per gli indici (vedi Dubbi) |
| Tastiera | — | Invio nel campo; Esc chiude la finestra (regola generale) | ⌘F mette il cursore nel campo ISIN; Invio cerca; Esc svuota il campo e il risultato, poi (al secondo Esc) segue l'ordine generale |

---

### 5. Mappa verso Prisma

#### 5.1 Esiste già (verificato con grep in `Sources/Prisma`)

| Cosa | Dove | Come si usa per Mercato |
|---|---|---|
| Aggiornamento dei valori in blocco | `Motori/AggiornaValori.swift` (`AggiornaValori`: `righe`, `sessione`, `abbina`, `esiti`, `applica`, `valoriFermi`, `fermoDa`, `mesiValoreFermo`, `sogliaInsolita`), `Shell/StatoAggiornaValori.swift` (`apriAggiornaValori`, `valoriDaFile`, `incollaValoriDaExcel`, `applicaValoriInBlocco`), `Shell/AggiornaValoriVista.swift`, `Motori/TestiAggiornaValori.swift`, prove in `Motori/ProvaCalcoliAggiornaValori.swift` | Le quote per ISIN importate da Mercato aggiornano il controvalore delle posizioni con **lo stesso percorso**: valore = numero di quote × quota, con abbinamento, storico (`Rilevazione`), variazione insolita oltre il 25% e riepilogo. Non serve un secondo motore di registrazione. L'abbinamento oggi va per numero di contratto o per nome: va aggiunto l'abbinamento per **ISIN** |
| Colonne dei file | `Motori/ImportaPosizioni.swift` (`ImportaPosizioni.Colonna`) | colonne nuove «ISIN», «Quota», «Numero quote», «Data» |
| Storico dei valori | `Dati/Posizione.swift` (`Rilevazione`, `Posizione.rilevazioni`, `controvalore`, `dataValore`) | «−6% dal massimo» si calcola sullo storico |
| Andamento | `Motori/MotoreAndamento.swift` (`AndamentoPosizione`, `calcola`), `Motori/MotoreAndamentoPortafoglio.swift` (`calcola`, `valore(_:al:)`) | massimo del portafoglio e variazione in un mese |
| Riferimenti | `Dati/Riferimenti.swift` (`SerieRiferimento`, `TipoSerieRiferimento.indice`, `IndiceRiferimento`, `ValoreRiferimento`, `RiferimentiRendimento`, `RiferimentiStorici.inflazione`), `Motori/MotoreRiferimenti.swift` (`TabellaRiferimenti`, `fattore`, `serieDi`, `confronto`, `ConfrontoRiferimento.Giudizio`), `Shell/ImpostazioniRiferimenti.swift`, `Shell/StatoRiferimenti.swift`, `Shell/PannelloRiferimento.swift`, prove in `Motori/ProvaCalcoliRiferimenti.swift` | l'avviso «Andrea si allontana dal riferimento di 4 punti in un mese» è `MotoreRiferimenti.confronto` calcolato su un mese. I valori **annui** dell'inflazione FOI e degli indici si possono ricavare dalle serie mensili di Mercato, proposti al consulente e mai scritti da soli (vedi §5.2) |
| Composizione per classe | `Motori/CrisiStoriche.swift` (`composizione(_:)`, `quotaAzionariaStimata(_:)`, `quotaGovernativiPredefinita`, `azioniPerSRI`) e i campi `Posizione.quotaAzionaria`, `quotaTitoliStato`, `quotaGestioneSeparata` | «Chi è toccato»: quota in azioni e quota in titoli di Stato di ogni cliente. La gestione separata non scende (stessa regola della prova delle crisi) |
| ISIN nei documenti | `Dati/Documento.swift` (`CampoDocumento.isin`, «Codice ISIN»), `Motori/EstrattoreDocumento.swift` (regola e `formaISIN`) | l'ISIN letto da KID ed estratti conto si propone come `Posizione.isin` nel confronto con il dossier (stesso flusso delle `VariazioneDossier`) |
| Notifiche | `Shell/Notifiche.swift` (`Notifica`, `MotoreNotifiche.calcola`, gruppi `daFare`, `oggi`, `prossimi`, `daSistemare`), `Shell/PannelloNotifiche.swift` | un avviso scattato diventa una notifica «Oggi», con l'apertura su Mercato o sulla posizione |
| Messaggi | parte 05: `OccasioneMessaggio.Tipo.mercato`, `StatoShell.preparaMessaggio` | «Prepara un messaggio» |
| Componenti | `DesignSystem/Apple/GraficiApple.swift` (`TracciatoGrafico`), `CifreApple.swift` (`NumeroCheConta`, `migliaia`, `unDecimale`), `CascataApple.swift` (`entrataCascata`), `SchedeApple.swift` (`inclinazione(massimo:)`), `ControlliApple.swift` (`StileInterruttoreApple`, `avvisoToast`), `PulsantiApple.swift` (`StilePulsanteApple`), `DesignSystem/Componenti.swift` (`AvatarCliente`), `DesignSystem/ComponentiAnalisi.swift` (`Pillola`), `DettaglioApple.swift` | tutto il disegno. Non serve nessun componente grafico nuovo, salvo il gruppo di avatar sovrapposti |
| Tempi | `DesignSystem/Apple/TemaAppleMoto.swift`: `Cascata` (0,72; 0,048; base 0,14), `Linea` (1,50; 0,15; 0,12), `Inclinazione` (0,50; 900; −5; 1,02; `massimoFamiliari` 6) | coincidono con il template |
| Colori | `DesignSystem/Apple/TemaApple.swift`: `Colore.rosso` #E5484D, `arancio` #E08A00, `verde` #2FA35A, `verdeInterruttore` #34C759, `anello1` #30B15C, `Investimenti.liquidita` #9FB3C2 | toni e linee |
| Rete | solo `Ruby/FornitoreOllama.swift`, `FornitoreCompatibileOpenAI.swift`, `PonteRuby.swift` e `ServerPonteRuby.swift` usano `URLSession`, e solo verso indirizzi locali | **oggi Prisma non esce mai su internet**: Mercato sarebbe la prima eccezione (Dubbio 1) |

#### 5.2 Cosa manca

1. **App**: `AppPrisma.mercato` e la finestra `Shell/AppMercato.swift`, con le viste `StrisciaMercato`, `RiquadroToccati`, `RiquadroAvvisi`, `RisultatoISIN` e `FoglioNuovoAvviso`. La testata (titolo, occhiello, icona) sta in 00-comune §5.2.
2. **Tema**: `DesignSystem/Apple/Tema.Apple+Mercato.swift` con:
   - `Disposizione` (§2.1);
   - le misure di tessera, riga e campo;
   - `Tracciato.spessoreMini = 2.2` e l'altezza 40;
   - la `fasciaRiservatezza` (fondo e bordo);
   - lo spostamento degli avatar −8 e il bordo 2;
   - `Moto.Pulsazione` (1,6 s, alone 6, rosso al 18%);
   - `Moto.RisultatoISIN` (0,42 s, y +10, curva uscita).
3. **ISIN nelle posizioni e nelle schede prodotto**: oggi l'ISIN esiste solo come dato letto dai documenti. Manca nel modulo della posizione e nella scheda prodotto. Va aggiunto come campo facoltativo, con il controllo della cifra.
4. **Numero di quote**: senza le quote non si passa dalla quota al controvalore. Va aggiunto alla posizione, facoltativo.
5. **Cedole**: Prisma non ha date né tassi delle cedole (`cedol` compare solo in testi e in `Rendimenti.swift`). Servono per l'avviso «Cedola del BTP di Sofia tra 12 giorni».
6. **Serie di mercato con date**: `RiferimentiRendimento` tiene solo valori **annui** in percentuale. Mercato ha bisogno di serie giornaliere o mensili con livelli (indici in punti, tassi in %).
7. **Fonti e scaricamento**: un `FornitoreDatiMercato` (protocollo, come `FornitoreModello`) con le implementazioni:
   - `FonteBCE` (SDMX: Euribor 3 mesi, tasso sui depositi, rendimento dei titoli di Stato italiani a 10 anni);
   - `FonteEurostat` (HICP Italia, variazione annua mensile);
   - `FonteISTAT` (FOI e NIC, limite di 5 richieste al minuto);
   - `FonteFile` (CSV o Excel importato, per gli indici azionari e per le quote per ISIN).

   Secondo la ricerca delle fonti (`orizzonte/ricerca-fonti.txt`), per le quote per ISIN, per gli indici azionari (FTSE MIB, MSCI World), per FRED, Stooq, Borsa Italiana e justETF non c'è una fonte libera utilizzabile. Quindi **l'ISIN non si manda a nessuno**: le quote arrivano dai file. La frase della fascia del template («escono solo gli ISIN») va cambiata (Dubbio 2).
8. **Avvisi**: un archivio degli avvisi e un motore che li valuta a ogni aggiornamento, quando si apre Prisma e dopo l'importazione dei valori.
9. **Aggiornamento automatico** all'ora scelta (18:00 nel template). Va fatto senza Timer: un controllo all'apertura e al risveglio del Mac (Prisma già si blocca e si sblocca al riposo), e una `NSBackgroundActivityScheduler` solo se l'utente lo permette. Con la rete spenta non c'è aggiornamento automatico.
10. **iPhone e iPad**: Mercato in sola lettura. Le serie e gli avvisi arrivano dal Mac (copia cifrata della parte «Prisma ovunque» o ponte). Il telefono non scarica nulla da solo.

#### 5.3 Motori nuovi

**`Motori/MotoreMercato.swift`** (`enum MotoreMercato`): è un motore puro. `oggi` e i dati entrano sempre come parametri.

- `tessera(_ s: SerieMercato, oggi: Date) -> TesseraMercato?` restituisce:
  - il valore;
  - la variazione: per gli indici in % sull'ultimo valore prima di oggi, per tassi e inflazione in punti;
  - il testo già formattato («34.180», «3,42%», «+0,6%», «+0,15», «invariato»);
  - il tono;
  - i punti della mini linea, normalizzati da 0 a 1 (gli ultimi 9 valori, uno per periodo; §2.4 con max = min → piatta);
  - la data dell'ultimo valore e la `freschezza` (oggi, recente o vecchia).
- **Regola del tono** (`TonoMercato`: `buono`, `cattivo`, `neutro`), per tipo di serie:
  - indice azionario: su = buono;
  - rendimento dei titoli di Stato: su = cattivo per chi li ha;
  - Euribor: giù = buono;
  - inflazione: giù = buono;
  - tasso BCE: fermo = neutro, su = cattivo, giù = buono.

  Sotto una soglia di rumore (`sogliaInvariato`: 0,05% per gli indici, 0,005 punti per i tassi) il tono è neutro e il testo «invariato».
- `toccati(serie:, posizioni:, clienti:, oggi:) -> [EventoToccati]` restituisce un evento per ogni serie che si è mossa oltre `sogliaEvento` (proposta: ±1% per le azioni, ±0,10 punti per i rendimenti, un nuovo dato per l'inflazione). Ogni evento contiene:
  - il titolo;
  - i clienti esposti, ordinati per impatto;
  - il cliente con l'impatto più grande e la cifra;
  - il tono.

  Come si calcola:
  - **Azioni**: esposti i clienti con più di `sogliaAzionaria` (40%) del portafoglio in essere in azioni, con `CrisiStoriche.composizione`. Impatto = Σ controvalore × quota azionaria × variazione. Arrotondato a «circa» con due cifre significative: 2.980 → «circa 3.000 €». Il calcolo è separato per canale, perché Alleanza e indipendente vanno distinti nel dettaglio.
  - **Rendimenti dei titoli di Stato**: esposti i clienti con `quotaTitoliStato` > 0. Senza la durata finanziaria la frase resta qualitativa («il valore scende un po’, la cedola resta quella»), come nel template. Con la durata (campo facoltativo) l'impatto è circa −durata × Δrendimento.
  - **Inflazione**: esposti i clienti con obiettivi oltre 5 anni (`Obiettivo`). La frase è qualitativa.
  - Le frasi stanno in `Motori/TestiMercato.swift`, mai nella vista.
- `cercaISIN(_ codice: String, posizioni:, prodotti:, quote:) -> RisultatoISIN` restituisce `nonValido`, `sconosciuto(nelPortafoglio: Int)` oppure `trovato(nome, quota, variazioneDaInizioAnno, clienti: [String])`. Accanto c'è `isinValido(_:)` con la cifra di controllo (algoritmo di Luhn sulle cifre ottenute dalle lettere, A = 10 … Z = 35).
- `occhiello(ultimoAggiornamento:, oggi:, datiDiProva:) -> String`.

**`Motori/MotoreAvvisi.swift`** (`enum MotoreAvvisi`):
- `valuta(_ a: AvvisoMercato, posizioni:, serie:, riferimenti:, oggi:) -> StatoAvviso`, cioè `quiete`, `vicino` (oltre l'80% della soglia, arancio), `scattato` (rosso, pulsa) o `buono` (verde). Restituisce anche la descrizione («−6% dal massimo · soglia −5%», «tra 12 giorni», «di 4 punti in un mese», «+2% in un mese»).
- Tipi di soglia (`TipoAvviso`):
  - `dalMassimo(percento)`: calo dal massimo delle `rilevazioni` negli ultimi 12 mesi;
  - `variazione(percento, giorni)`: «+2% in un mese», in su o in giù;
  - `scostamentoRiferimento(punti, giorni)`: differenza fra rendimento della posizione e metro (`MotoreRiferimenti`) nel periodo;
  - `cedola(giorniPrima)`: prossima data della cedola;
  - `valore(minimo / massimo)`: controvalore sotto o sopra una cifra.
- Un avviso già scattato non torna in Notifiche finché la condizione non rientra e poi si ripresenta (`ultimoScattoIl`).

**Collegamento con `AggiornaValori`**: un `AggiornaValori.Riga` nuovo, con `isin`, `quota` e `numeroQuote`. L'abbinamento `.isin` va prima di `.numero` quando il cliente è unico. Se lo stesso ISIN è in più posizioni, ogni posizione prende quota × le **sue** quote. Senza il numero di quote, la riga è `senzaValore` con la spiegazione «manca il numero di quote» (`TestiAggiornaValori.spiegazione`).

#### 5.4 Campi nuovi dell'archivio (versione 26, come le altre parti di Orizzonte; nomi proposti)

Tutti si leggono con tolleranza, con `ElencoTollerante` come in `RiferimentiRendimento`: un archivio della versione 25 si apre senza errori.

- `Posizione.isin: String?`;
- `Posizione.numeroQuote: Double?`;
- `Posizione.cedola: CedolaTitolo?`, con `CedolaTitolo` = `tassoAnnuo: Double`, `volteAllAnno: Int`, `prossima: Date`;
- `Posizione.durataFinanziaria: Double?`, facoltativo, in anni;
- `Prodotto.isin: String?` (scheda prodotto);
- `DatiPrisma.mercato: ArchivioMercato`, che contiene:
  - `serie: [SerieMercato]`, dove `SerieMercato` ha `id` («azioni-italia», «azioni-mondo», «btp-10», «euribor-3m», «inflazione-it», «bce-depositi», oppure «indice-…» del consulente), `nome`, `tipo` (`indiceAzionario`, `rendimentoStato`, `tassoInterbancario`, `inflazione`, `tassoUfficiale`), `unita` (`punti` o `percentuale`), `fonte`, `origine` (`scaricata`, `importata`, `consulente`, `prova`) e `punti: [PuntoMercato]` (`data`, `valore`);
  - `quote: [QuotaISIN]`: `isin`, `nome`, `valuta`, `punti: [PuntoMercato]`, `fonte`, `importataIl`;
  - `ultimoAggiornamento: Date?`;
  - `ultimoErrore: String?`, come le impostazioni di backup;
- `DatiPrisma.avvisi: [AvvisoMercato]`: `id`, `clienteId`, `posizioneId?` (nil = tutto il portafoglio), `tipo: TipoAvviso` con la soglia, `attivo: Bool`, `creatoIl`, `ultimoScattoIl: Date?`;
- `Impostazioni.mercato: ImpostazioniMercato`:
  - `datiPubblici: Bool`, predefinito **false**: senza consenso Prisma non esce mai su internet;
  - `fonti: Set<String>`;
  - `oraAggiornamento`, predefinita 18:00;
  - `serieInStriscia: [String]`, sei id nell'ordine;
  - `sogliaAzionaria`, predefinita 40.

Le serie si conservano per un tempo limitato: proposta 3 anni di dati mensili e 13 mesi di dati giornalieri (memoria e archivio leggeri, 8 GB di RAM).

**Backup.** Serie, quote, avvisi e impostazioni del mercato entrano nel backup. `Prisma --prova-backup` (`Dati/ProvaBackup.swift`) deve controllare due cose:
- che tornino uguali dopo il ripristino;
- che un archivio della versione 25, senza queste sezioni, si apra con Mercato vuoto.

#### 5.5 Prove di calcolo nuove

**`Motori/ProvaCalcoliMercato.swift`** (`ProvaCalcoliMercato.esegui(_:)`, chiamata da `ProvaCalcoli.swift` come `ProvaCalcoliAggiornaValori`). Le date sono fisse (oggi = 2 novembre 2026, ore 18).

1. **Tessere**:
   - 34.180 su 33.976 dà «+0,6%» e tono buono;
   - 3.712 su 3.780 dà «−1,8%» e tono cattivo;
   - BTP 3,27 → 3,42 dà «+0,15» e tono cattivo;
   - Euribor 2,10 → 2,08 dà «−0,02» e tono buono;
   - BCE 2,00 → 2,00 dà «invariato» e tono neutro.
2. **Mini linea**: la normalizzazione dei 9 punti di «Azioni mondo» dà min 3500 = 0 e max 3790 = 1. Una serie piatta (Tasso BCE alla fine, oppure tutti i valori uguali) non divide per zero.
3. **Formati**: «34.180», «3,42%», «1,6%», il meno tipografico, «invariato» sotto la soglia di rumore.
4. **Chi è toccato**:
   - un portafoglio di 318.400 € con il 52% in azioni e Azioni mondo a −1,8% dà un impatto di 2.980 € e il testo «circa 3.000 €»;
   - un cliente al 40% esatto non è contato (serve «più del 40%»);
   - la gestione separata non entra nell'esposizione;
   - una posizione in proposta non entra;
   - i canali restano separati.
5. **Avvisi**:
   - massimo 100.000, valore 94.000, soglia −5%: «−6% dal massimo · soglia −5%», scattato;
   - valore 96.000: vicino;
   - cedola il 14 novembre: «tra 12 giorni»;
   - scostamento di 4 punti in un mese dal metro: scattato con soglia 3;
   - un avviso spento non scatta mai;
   - un avviso già scattato non si ripete.
6. **ISIN**:
   - «IE00B4L5Y983», «IT0005439275» e «US0378331005» sono validi;
   - «LU0000000000» non lo è (cifra di controllo sbagliata);
   - « ie00 b4l5 y983 » si normalizza e diventa valido;
   - un ISIN in 3 posizioni di 3 clienti dà «3 clienti».
7. **Quote e AggiornaValori**:
   - quota 18,42 × 1.000 quote = 18.420 € registrato come valore, con il valore di prima nelle `rilevazioni`;
   - senza il numero di quote: `senzaValore`;
   - con lo stesso ISIN in due posizioni, ogni posizione usa le sue quote.
8. **Occhiello**: «Aggiornato oggi alle 18:00», «Aggiornato il 28 ottobre», «Mai aggiornato», e «· valori di prova» solo con i dati di prova.
9. **Lettura tollerante**: un `PuntoMercato` senza data si scarta; un `AvvisoMercato` illeggibile si scarta, gli altri restano.

**`Dati/ProvaBackup.swift`**: aggiungere serie, quote e avvisi alla prova di andata e ritorno.

---

### 6. Dati che l'utente deve dare (mai inventarli)

Prisma non scrive nessun valore di mercato da solo. A ogni valore sono legate una fonte e una data. Finché un dato manca, l'interfaccia lo dice («—», «Da importare», «Mai aggiornato»). I valori del template compaiono **solo** con i dati di prova caricati, e l'occhiello lo segnala («· valori di prova»).

| Dato | A cosa serve | Finché manca |
|---|---|---|
| **Consenso a scaricare dati pubblici** e quali fonti (BCE, Eurostat, ISTAT) | tessere dei tassi e dell'inflazione aggiornate da sole | nessuna connessione; la fascia dice «Nessun dato esce dal Mac»; le serie arrivano solo dai file |
| **Le sei serie della striscia** (conferma delle sei del template o altre) e, per le azioni, **quale indice** (FTSE MIB? MSCI World in euro? un ETF come termometro?) | striscia | tessera «Da importare» |
| **Da dove prendere quote e indici azionari** (estratti della piattaforma Alleanza, della banca, file della SGR, altro) e un **file di esempio** | importazione delle quote per ISIN e degli indici | ricerca ISIN solo nell'archivio, «Quota —» |
| **ISIN e numero di quote** di ogni posizione in fondi, ETF e titoli (anche dai KID e dagli estratti, che Prisma già legge) | ricerca ISIN, valore dalle quote, «Nei portafogli» | la posizione non è collegata al mercato |
| **Cedole** dei titoli (tasso, periodicità, prossima data) | avviso della cedola | avviso «cedola» non disponibile per quella posizione |
| **Durata finanziaria** dei titoli o dei fondi obbligazionari (facoltativa) | cifra dell'impatto dei tassi | frase qualitativa |
| **Soglie predefinite** degli avvisi (−5% dal massimo? quanti giorni prima della cedola? quanti punti di scostamento?) e la **soglia azionaria** di «Chi è toccato» (40%?) | avvisi e «Chi è toccato» | si usano le soglie del template, scritte come «proposte» nel foglio del nuovo avviso |
| **Ora dell'aggiornamento** (18:00?) | occhiello e aggiornamento automatico | aggiornamento solo con il pulsante |

**Dati di prova** (in `Dati/DatiDemo.swift` e `Dati/ClientiFittizi.swift`, caricati solo dall'utente):
- le sei serie del template, con `origine: .prova`;
- il fondo «Fondo di prova azionario globale», quota 18,42 € e +6,1% da inizio anno, con un ISIN valido **di prova**. «IE00B4L5Y983» è un ETF reale e non va usato come dato di prova: serve un codice con il prefisso «XS» o «ZZ» che superi il controllo, da scegliere;
- i quattro avvisi del template sui clienti di prova;
- le posizioni di Marco con il 52% in azioni (già coerenti con la prova del fuoco).

---

### 7. Istantanee da aggiungere

La serie **540-549** è libera: 500-537 sono usate dalle parti 00-04 e la parte 05 propone 490. Ogni istantanea si fa in chiaro e in scuro (suffisso `-scuro`). In tutte le istantanee le linee sono tracciate, i numeri sono completi e il pallino rosso è senza alone.

| Nome | Scena |
|---|---|
| `540-mercato` / `-scuro` | finestra Mercato con i dati di prova: striscia, «Chi è toccato oggi» con gli avatar sovrapposti visibili, quattro avvisi |
| `541-mercato-vuoto` / `-scuro` | mai aggiornato, nessun dato di prova: invito a importare o a scaricare |
| `542-mercato-isin` / `-scuro` | ricerca di un ISIN trovato, con quota, «Da inizio anno» e «Nei portafogli» |
| `543-mercato-isin-sconosciuto` / `-scuro` | ISIN valido senza quote importate, e sotto il messaggio dell'ISIN non valido (due istantanee o una con il secondo caso) |
| `544-mercato-nuovo-avviso` / `-scuro` | foglio del nuovo avviso aperto (cliente, posizione, soglia) |
| `545-mercato-dati-vecchi` / `-scuro` | ultimo aggiornamento di cinque giorni prima: occhiello con la data, «Chi è toccato dall’ultimo aggiornamento», una tessera «Da importare» |
| `546-mercato-avviso-spento` / `-scuro` | un avviso con l'interruttore spento e il pallino grigio |
| `547-mercato-tessera-dettaglio` / `-scuro` | dettaglio di una tessera con la serie di 12 mesi e la fonte (se si accetta la proposta) |
| `548-impostazioni-mercato` / `-scuro` | Impostazioni › Mercato: consenso ai dati pubblici, fonti, ora, sei serie, soglie |
| `549-notifica-avviso-mercato` / `-scuro` | pannello delle notifiche con un avviso di Mercato scattato |
| `400-vetrina-apple` / `-scuro` (esistente) | aggiungere una tessera del mercato con la mini linea e una riga d'avviso con l'interruttore |

---

## 13. Impostazioni › iPhone e iPad — «Prisma ovunque»

*Parte 07 · titolo della bozza: «07 · Impostazioni › iPhone e iPad — «Prisma ovunque»»*

Fonte: `Design/template-novita.html`, funzioni `ovunqueHTML()` e `montaOvunque()` (righe 1040-1057), con `riga()`, `impHTML()`
e `impAggancia()` (righe 706-721) e il CSS di testa (righe 17-196). Voce 4 del pannello Novità (`NOV[3]`, porta a
Impostazioni con `selI=4`).
Per ciò che qui non è detto vale `Design/template-apple-specifica.md` (§4.6 Impostazioni, token di §1) e `00-comune.md`.
Le cifre e i nomi del template («2 minuti fa», «3 modifiche», «Giulia Rossi», «204.050 €», «52%», «48%») sono
dimostrativi: nell'app vengono dall'archivio, dal registro della sincronizzazione e dai motori.

Riferimenti visivi (1480×940, palco 1440×900 scalato di 1,0137):
- `orizzonte/chiaro-13-prisma-ovunque.png`, `orizzonte/scuro-13-prisma-ovunque.png`.

---

### 1. Cosa si vede

#### 1.1 Come si arriva
- Dal pannello Novità, voce 4 «Prisma ovunque» · «Una copia cifrata su iPhone e iPad, anche senza il Mac»: apre
  Impostazioni già sulla sezione «iPhone e iPad».
- Da Impostazioni, voce laterale «iPhone e iPad».

#### 1.2 Barra laterale di Impostazioni (260)
Nel template l'ordine delle voci diventa: **Aspetto · iPhone e iPad · Archivio e backup · Ruby · Profilo**
(`[0,4,1,2,3]`). La voce scelta ha il fondo `rgba(0,122,255,.13)` (chiaro e scuro, nel template uguale).
In Prisma la barra ha molte più pagine (`SchedaImpostazioni`): vedi §5 e i dubbi.

#### 1.3 Area di destra, dall'alto
1. **Titolo** `.h2` «iPhone e iPad».
2. **Card dello schema** (larga 720):
   - disegno vettoriale 670×150 con tre oggetti in fila e due archi tratteggiati:
     - a sinistra il portatile, sotto la scritta **«Il tuo Mac»**;
     - al centro la nuvola blu con il lucchetto pieno, sotto **«iCloud Drive»** e, più piccolo in grigio,
       **«solo un file cifrato»** (nella schermata la seconda riga è tagliata dal bordo del disegno: vedi §2.2);
     - a destra il telefono, sotto **«iPhone e iPad»**;
     - su ciascun arco corrono **due pallini verdi**, uno in andata e uno in ritorno (4 in tutto).
   - sotto, una riga con a sinistra lo stato e a destra il pulsante:
     - titolo **«Sincronizzato · 2 minuti fa»**;
     - frase **«Cifrato con la tua chiave: senza, il file in iCloud è illeggibile. Nessun server.»**;
     - pulsante primario grande **«Sincronizza ora»**.
3. **Tre righe di impostazione** (larghe 720), con la forma di `riga()`:
   - **«Copia cifrata su iPhone e iPad»** · «I dati viaggiano solo come file cifrato in iCloud Drive.» · interruttore acceso;
   - **«Lavora anche con il Mac spento»** · «Dal cliente, in treno, ovunque: al ritorno le modifiche si uniscono da sole.» · interruttore acceso;
   - **«Modifiche in attesa»** · «3 dall’iPhone di stamattina: una nota e due attività.» · pulsante **«Vedi»**.
4. **Il telefono d'esempio**, a destra in alto (cornice `.phone` ridotta a 0,86), con lo schermo **sempre chiaro**
   anche nell'aspetto scuro (fondo `linear-gradient(170deg,#E9F1F5,#C9DCE6)`):
   - riga di stato: «10:41» a sinistra, a destra la pillola arancio **«Senza Mac · copia cifrata»**;
   - **«Giulia Rossi»** grande, sotto «Dal cliente · via Roma 12»;
   - tessera bianca «Patrimonio netto» · **«204.050 €»**;
   - due tessere affiancate: «Casa» **«52%»** (blu) e «Protezione» **«48%»** (rosso);
   - tessera «**Nota nuova**» · «Vuole anticipare la casa di un anno.»;
   - in fondo, centrato in grigio: **«3 modifiche si uniranno al Mac»**.

#### 1.4 Stati
Il template ne disegna due:
- **sincronizzato**: «Sincronizzato · 2 minuti fa» (al caricamento);
- **in corso**: «Sincronizzo…» per 1,8 s, poi «Sincronizzato adesso» e l'avviso
  **«Mac, iPhone e iPad allineati · 3 modifiche unite»**.

Da aggiungere in Prisma, coerenti con il tema (testi proposti, da approvare):
| Stato | Titolo | Frase | Pulsante | Schema |
|---|---|---|---|---|
| Spento (interruttore «Copia cifrata» spento) | «La copia per iPhone e iPad è spenta» | «Accendila per lavorare dal cliente anche senza il Mac.» | nascosto | pallini fermi, archi in `--ink3` |
| Mai fatta | «Nessuna copia ancora» | «La prima copia porta clienti, agenda e posizioni su iPhone e iPad, cifrati.» | «Crea la copia» | pallini fermi |
| Manca la password | «Serve la password dei backup» | testo di `ErroreBackup.passwordNonDisponibile` adattato: «Senza password la copia non si fa, per non metterla in chiaro in iCloud.» | «Scrivi la password…» (porta ad Archivio) | pallini fermi |
| iCloud Drive non raggiungibile | «iCloud Drive non risponde» | «Controlla di aver acceso iCloud Drive in Impostazioni di Sistema. I dati restano sul Mac.» | «Riprova» | nuvola in `--ink3`, pallini fermi |
| In corso | «Sincronizzo…» | invariata | disattivato | pallini veloci (§3) |
| Riuscita | «Sincronizzato adesso», poi «Sincronizzato · N minuti fa» | invariata | «Sincronizza ora» | pallini normali |
| Conflitti | «Sincronizzato · 2 modifiche da guardare» | «Lo stesso dato è cambiato sul Mac e sull'iPhone: scegli tu quale tenere.» | «Sincronizza ora» | pallini normali, «Modifiche in attesa» con pillola arancio |
| Nessuna modifica in attesa | riga «Modifiche in attesa» · «Nessuna: Mac, iPhone e iPad sono allineati.» | — | «Vedi» nascosto | — |

Il telefono d'esempio, senza dati veri, mostra i dati di prova (§6).

---

### 2. Misure e stile

Coordinate nel palco 1440×900. Finestra `#win` 1408×758 a (16,42); contenuto `#wc` con margini 12, sopra 92.
Barra laterale `.side` larga 260; `.main` da sinistra 276 (larga 1108).

#### 2.1 Titolo
`.h2`: `--fontd`, 21 px, peso 700, spaziatura −0,4 px; margini 4 sopra, 14 sotto. In Prisma: `Tema.Apple.Impostazioni…titolo` (`Carattere.h2`), `sopraTitolo 4`, `sottoTitolo 14`.

#### 2.2 Card dello schema
- `.card`: raggio 22, fondo `--card` (chiaro `rgba(255,255,255,.82)`, scuro `rgba(255,255,255,.07)`), bordo 1 `--sep`
  (`rgba(0,0,0,.08)` / `rgba(255,255,255,.09)`); qui **senza ombra** (`box-shadow:none`). Padding 20×24, larga 720,
  margine sotto 12.
- SVG 670×150 (`#syncS`), contenuto in coordinate del disegno:
  - **Mac** (`translate(40,40)`): schermo `rect` 96×62 a (0,6), raggio 8, solo contorno 3 `--ink`; base `rect` 120×8
    a (−12,70), raggio 4, pieno `--ink`; scritta a (48,108) centrata, 13 px peso 600 `--ink`.
  - **iCloud Drive** (`translate(285,40)`): nuvola `path d="M20 58h62a20 20 0 0 0 0-40 28 28 0 0 0-54-4 22 22 0 0 0-8 44z"`
    contorno 3 `#0A84FF` senza riempimento; lucchetto: corpo `rect` 22×18 a (40,28) raggio 3 pieno `#0A84FF`, arco
    `M45 28v-5a6 6 0 0 1 12 0v5` contorno 3 `#0A84FF`. Scritte: «iCloud Drive» a (50,108) 13/600 `--ink`;
    «solo un file cifrato» a (50,124) 11 px regolare `--ink2`. Con il `translate` di 40 la seconda riga cade a y=164,
    **fuori dai 150 del disegno**: nella schermata non si vede. In Prisma va mostrata (altezza del disegno 170, oppure
    scritte alzate di 16): vedi i dubbi.
  - **iPhone** (`translate(560,26)`): `rect` 52×92 raggio 12 contorno 3 `--ink`; altoparlante `rect` 16×5 a (18,6)
    raggio 2,5 pieno `--ink`; scritta a (26,122) 13/600 `--ink`.
  - **Archi**: `#sp1` `M150 80 C200 40 250 40 290 78` e `#sp2` `M395 78 C450 40 510 40 555 72`, contorno 2 `--ink3`
    (`rgba(0,0,0,.34)` / `rgba(255,255,255,.38)`), tratteggio 4 pieno · 6 vuoto.
  - **Pallini**: cerchi raggio 5, pieni `#30B15C` (`--r1`).
  - Il blu `#0A84FF` è `--r2` (in Prisma `Colore.bluGrafico` o il token di `--r2`); resta uguale nello scuro.
- Riga di stato sotto il disegno: `display:flex`, spazio 16, margine sopra 6.
  - titolo 17 px peso 700 (`<b>`) `--ink`;
  - frase `.k`: 12,5 px `--ink2`, margine sopra 3;
  - pulsante `.btn.pri.big`: capsula (raggio 99), padding 10×18, 13,5 px peso 600, fondo `--accent` `#007AFF`,
    testo bianco, nessun bordo visibile.

#### 2.3 Righe (`riga()`)
Contenitore largo 720. Ogni riga: `.card` senza ombra, padding 16×20, margine sotto 10, `flex` centrato con spazio 16.
Titolo 15 px peso 700; frase `.k` 12,5 `--ink2` con margine sopra 2; controllo a destra. È la riga che Prisma ha già
(`CardImpostazioniApple`, §4.6 della specifica Apple).
- **Interruttore** `.sw`: 44×26, capsula, fondo spento `--track` (`rgba(0,0,0,.07)` / `rgba(255,255,255,.1)`), acceso
  `#34C759` (`Colore.verdeInterruttore`); pomello 20×20 bianco a 3 dal bordo, ombra `0 2px 5px rgba(0,0,0,.25)`.
- **Pulsante «Vedi»** `.btn`: capsula, padding 7×14, 12,5 px peso 600, fondo `--cardE` (`#fff` / `rgba(40,54,66,1)`),
  bordo 1 `--sep`.

#### 2.4 Telefono d'esempio
- `.phone`: 300×620, raggio 50, fondo `#0d0f12`, ombra `0 40px 80px -20px rgba(0,0,0,.55)` più filo interno
  `inset 0 0 0 2px #2a2e34`; isola `:before` 92×26 raggio 20 nera, a 22 dall'alto, centrata.
  Posizione: `right:30px; top:0`, `transform: scale(.86)` con origine in alto a destra → occupa 258×533.
- `.scr`: margine interno 11, raggio 40, fondo `linear-gradient(170deg,#E9F1F5,#C9DCE6)`, testo `#14202B`,
  padding 52 sopra, 18 ai lati. **Colori fissi, uguali nello scuro** (la schermata scura lo conferma).
- Riga di stato: 12 px peso 600; pillola «Senza Mac · copia cifrata»: padding 3×8, capsula, fondo
  `rgba(224,138,0,.16)` (arancio `--orange` `#E08A00` al 16%), testo `#B45309`, 10,5 px.
- Nome: `--fontd` 26 px peso 700, margine sopra 18; sotto 12 px `#5A6873`.
- Tessera patrimonio: fondo `#fff`, raggio 18, padding 14, margine sopra 14, ombra `0 10px 20px -12px rgba(0,0,0,.3)`;
  etichetta 11 px `#5A6873`; cifra `--fontd` 24 px peso 700.
- Tessere affiancate: spazio 8, margine sopra 10, fondo `#fff`, raggio 16, padding 12; etichetta 10,5 px `#5A6873`;
  valore 18 px bold, «Casa» `#0A84FF`, «Protezione» `#E5484D`.
- Tessera nota: fondo `#fff`, raggio 16, padding 12, margine sopra 10, 12,5 px interlinea 1,5.
- Piede: margine sopra 14, centrato, 11,5 px `#5A6873`.
- In Prisma i valori della cornice e dello schermo stanno già in `Tema.Apple+Telefono.swift` (cornice iPhone delle
  altre schermate di Orizzonte, vedi `00-comune.md` per `.phone`): la pillola arancio è nuova
  (`Tema.Apple.Ovunque.pillolaSenzaMac`, fondo `Colore.arancio.opacity(0.16)`, testo `#B45309` → nuovo token
  `Colore.arancioTesto`).

#### 2.5 Avviso
`#toast`: in alto al centro a 44 dal palco, fondo `rgba(15,36,51,.92)`, testo bianco 13 px, padding 9×16, capsula.
È l'avviso che Prisma ha già (`StatoShell.avviso`).

---

### 3. Movimento

| Cosa | Quando | Durata · curva · ritardo |
|---|---|---|
| Cascata dei blocchi `.st` (titolo, card dello schema, 3 righe, telefono = 6 blocchi) | all'apertura della sezione e a ogni cambio di sezione | 720 ms, `cubic-bezier(.22,1,.36,1)` (`Moto.Curva.uscita`), ritardo `i × 48 ms` da 0; da opacità 0, `translateY(18px) scale(.985)`, sfocatura 6 px → fermo. È `CascataImpostazioniApple`. |
| Arrivo dal pannello Novità | `rimonta()` | uscita del contenuto 130 ms (opacità 1→0, scala .99), poi la cascata sopra |
| Pallini sugli archi | sempre, in ciclo continuo | `animateMotion` lungo il percorso, 2,4 s a giro, velocità costante (`calcMode` paced), ripetizione infinita. Partenze sfalsate: Mac→iCloud 0 s, iCloud→iPhone 0,6 s, iCloud→Mac 1,2 s, iPhone→iCloud 1,8 s. |
| «Sincronizza ora» | clic | i pallini passano a 0,8 s a giro per 1,8 s, poi tornano a 2,4 s. Nel template il cambio di `dur` fa saltare i pallini di posizione: in Prisma la velocità cambia senza salti (fase continua). |
| Titolo dello stato | clic | «Sincronizzo…» subito, «Sincronizzato adesso» dopo 1,8 s (in Prisma: alla fine vera della sincronizzazione, non a tempo) |
| Avviso | fine sincronizzazione | entra in 450 ms con `--spring` `cubic-bezier(.34,1.45,.64,1)` (da −20 px), resta 2,4 s |
| Interruttori | clic | fondo 300 ms; pomello 350 ms `--spring` |
| Pulsanti | pressione | scala 0,95, 250 ms `--spring`; passaggio del puntatore: luminosità 0,97 |

Proposte di movimento per Prisma (il template non le ha, coerenti con `Tema.Apple.Moto`):
- la cifra «N minuti fa» e il numero delle modifiche in attesa si contano fino al valore come le altre cifre;
- a fine sincronizzazione il lucchetto della nuvola fa un piccolo rimbalzo (`scale .3→1`, 500 ms, molla
  `cubic-bezier(.34,1.45,.64,1)`, come la spunta del backup).

**Riduci movimento** (`\.prismaCalmo`). Il template non ferma i pallini (`animateMotion` ignora `ridotto`). In Prisma:
pallini **fermi** a metà di ciascun arco (il verde dice «allineato»), niente accelerazione su «Sincronizza ora»; il cambio
di testo con dissolvenza di 0,15 s; nessuna cascata.

**Istantanee** (`\.modoIstantanea`, `\.prismaStatoFinale`): pallini disegnati fermi nelle posizioni della schermata
(su ciascun arco, andata al 25% e ritorno al 75% del percorso), cifre complete. Niente Timer: il moto dei pallini con
`TimelineView(.animation)` messo in pausa quando la finestra non si vede, come l'acqua, oppure `Animatable` su una fase
0…1 ripetuta; in memoria pesa poco (4 cerchi).

---

### 4. Interazioni

- **Voce laterale «iPhone e iPad»**: apre la sezione e riparte la cascata.
- **«Sincronizza ora»** (clic, `Invio` quando ha il fuoco): avvia la sincronizzazione vera (§5.3); durante il lavoro è
  disattivato e la tastiera `⌘R` (proposta) fa lo stesso dalla sezione.
- **Interruttore «Copia cifrata su iPhone e iPad»**: accende o spegne la copia. Spegnendolo Prisma chiede conferma e
  cancella da iCloud Drive il file cifrato e i diari delle modifiche già uniti («La copia in iCloud Drive viene
  cancellata. I dati restano sul Mac.»).
- **Interruttore «Lavora anche con il Mac spento»**: se acceso, iPhone e iPad possono cambiare i dati e le modifiche
  si uniscono al ritorno; se spento la copia è **di sola lettura** sui dispositivi.
- **«Vedi»** (nel template non fa nulla): apre un foglio con l'elenco delle modifiche in attesa, raggruppate per
  dispositivo e ora («iPhone · stamattina alle 9.12 · Nota nuova per Giulia Rossi»), con «Unisci ora» e, per i
  conflitti, la scelta «Tieni quella del Mac» / «Tieni quella dell'iPhone».
- **Avviso** dopo la sincronizzazione: «Mac, iPhone e iPad allineati · N modifiche unite» (con N = 0: «Mac, iPhone e
  iPad allineati»).
- Il **telefono d'esempio** non è interattivo.
- Su iPhone e iPad la pillola **«Senza Mac · copia cifrata»** sta nella barra (§5.4); toccandola si apre Impostazioni ›
  iPhone e iPad del dispositivo con l'ora della copia e le modifiche ancora da unire.

---

### 5. Mappa verso Prisma

#### 5.1 Cosa c'è già (verificato con grep in `Sources/Prisma`)
- **Cifratura**: `Dati/CifraturaBackup.swift` (PBKDF2-HMAC-SHA256 + AES-256-GCM a segmenti, file «PRISMACF»), usata da
  `GestoreBackup.crea(…, password:)` in `Dati/Backup.swift`; la password sta nel Portachiavi del Mac
  (`Dati/PortachiaviBackup.swift`, servizio «Prisma backup»). È la «tua chiave» del template.
- **Backup e ripristino**: `GestoreBackup` (crea, elenca, ruota, estrai, sostituisci, recupero dopo un ripristino
  interrotto), zip scritto e letto senza `ditto` su iOS (`ScrittoreZip.swift`, `LettoreZip.swift`).
- **iPhone e iPad oggi**: `iOS/AperturaBackup.swift` e `iOS/StatoMobile.swift` aprono un backup del Mac scelto con
  `.fileImporter` (anche da iCloud Drive: `copiaDiLavoro` usa `startAccessingSecurityScopedResource` e
  `NSFileCoordinator`, che scarica il file se non è sul dispositivo) e **sostituiscono** l'archivio;
  `preparaBackupPerMac(password:)` fa il contrario (backup «(da iPad)» da salvare in File, che sul Mac sostituisce i
  dati). `iOS/ImpostazioniMobile.swift` mostra «Su questo dispositivo» e «Rimanda al Mac».
- **Ponte di Ruby**: `Ruby/PonteRuby.swift`, `Ruby/ServerPonteRuby.swift` (Bonjour `_prisma-eve._tcp`, porta 47620, busta
  ChaChaPoly con la chiave del codice di abbinamento, `ImpostazioniPonte` in `ImpostazioniRuby.ponte`). Serve a sapere se
  il Mac è raggiungibile (→ pillola «Senza Mac»).
- **Impostazioni del Mac nel tema Apple**: `Shell/ImpostazioniAppleMac.swift` (barra laterale `gruppoLateraleApple`,
  `contenutoApple`), `DesignSystem/Apple/ImpostazioniApple.swift` (`CardImpostazioniApple`, `CascataImpostazioniApple`,
  `VoceLateraleImpostazioniApple`, `StatoRigaApple`, `AnelloBackupApple`), token in `Tema.Apple+Impostazioni.swift`;
  cornice del telefono in `Tema.Apple+Telefono.swift`.
- **Date di modifica** che servono all'unione: `Nota.aggiornataIl`, `Prospetto.aggiornatoIl`, `Incontro.aggiornatoIl`,
  `Analisi.aggiornataIl`, `Bisogni.aggiornatoIl`, `SchedaAdeguatezza.aggiornataIl`; identificativi stringa per
  `Posizione.id` e i modelli di `Modelli.swift`.
- **Segnalibri di cartella: non ci sono.** Sul Mac (Prisma non è in sandbox) la cartella dei backup è un percorso in
  chiaro (`ImpostazioniBackup.cartella: String?`); su iOS nessun `bookmarkData`.
- **Nessun contenitore iCloud**: `Supporto/iOS/Info.plist` (`local.prisma`) e `assembla.sh` non dichiarano diritti
  iCloud; l'app iOS si installa con AltStore/Sideloadly (ID Apple gratuito), che **non concede** il contenitore
  iCloud né CloudKit.

#### 5.2 Come funziona (proposta di fattibilità)
Niente server, niente CloudKit: si usano **file in una cartella di iCloud Drive**, come già per i backup.
1. Il Mac scrive in `~/Library/Mobile Documents/com~apple~CloudDocs/Prisma/Ovunque/` (proposta; la cartella si può
   cambiare) un unico file **«Prisma ovunque.zip.cifrato»**: lo zip dell'archivio, cifrato con `CifraturaBackup` e la
   password dei backup. Il Mac è **l'unico che scrive questo file**: niente conflitti di iCloud.
2. iPhone e iPad, la prima volta, scelgono quella cartella con `.fileImporter(allowedContentTypes: [.folder])`; Prisma
   ne salva il **segnalibro** (`URL.bookmarkData()`; su iOS il segnalibro di una cartella scelta dall'utente resta
   valido tra un avvio e l'altro) e la password nel Portachiavi del dispositivo. Da lì leggono la copia con
   `NSFileCoordinator` (scaricamento da iCloud incluso) e la aprono come oggi `StatoShell.ripristina`, ma in
   un'area separata («copia di lavoro»), senza buttare il diario.
3. Con «Lavora anche con il Mac spento» il dispositivo scrive **solo il proprio diario**
   «Modifiche <nome dispositivo>.cifrato» nella stessa cartella: un elenco di operazioni (aggiungi nota, cambia
   attività…) con identificativo, ora, numero progressivo e impronta del dato prima della modifica. Ogni dispositivo
   scrive solo il suo file.
4. Il Mac, a ogni apertura, ogni N minuti mentre è acceso, alla riattivazione e con «Sincronizza ora»: legge i diari,
   **unisce** le operazioni nell'archivio (copia di sicurezza prima, come il ripristino), riscrive la copia e annota
   nel file l'ultimo numero unito per ogni dispositivo; il dispositivo, alla lettura successiva, toglie dal diario le
   operazioni già unite.
5. «Sincronizzato · N minuti fa» = ora dell'ultima copia scritta (sul Mac) o letta (sul dispositivo).

Limiti da dire all'utente: su iOS la sincronizzazione avviene all'apertura, al ritorno in primo piano, prima di andare
in background (`StatoMobile.inBackground`) e con il pulsante; non in background a app chiusa. iCloud Drive impiega da
pochi secondi a qualche minuto a portare il file: Prisma lo dice («Aspetto che iCloud porti la copia…»).

#### 5.3 Cosa manca (tipi e file nuovi, nomi proposti)
- `Dati/CopiaOvunque.swift` — `enum CopiaOvunque`: `scrivi(dati:cartella:password:)` (riusa `GestoreBackup.crea` con
  destinazione fissa e senza rotazione, scrittura atomica `.parziale` → rinomina con `NSFileCoordinator`
  `forReplacing`), `leggi(cartella:password:)`, `cartellaPredefinita` (iCloud Drive del Mac), controllo «iCloud Drive
  acceso» (`FileManager.default.ubiquityIdentityToken` non si può usare senza diritti: si controlla che esista
  `~/Library/Mobile Documents/com~apple~CloudDocs`).
- `Dati/DiarioModifiche.swift` — `struct OperazioneOvunque: Codable` (`id`, `dispositivo`, `numero`, `il: Date`,
  `tipo: TipoOperazione`, `oggetto: String` (id), `prima: String?` (impronta), `dopo: Data` (JSON del dato)),
  `enum TipoOperazione { aggiungiNota, cambiaNota, aggiungiAttivita, cambiaAttivita, completaAttivita,
  aggiungiAppuntamento, cambiaAppuntamento, cambiaCliente(campo) … }`, `struct DiarioModifiche` cifrato con la stessa
  `CifraturaBackup`.
- `Motori/MotoreUnioneOvunque.swift` — **motore nuovo**: applica le operazioni all'archivio in ordine di ora; regola
  dei conflitti: se l'impronta `prima` non coincide con il dato attuale del Mac, l'operazione **non** si applica e
  diventa un conflitto da scegliere («Modifiche in attesa»); nessuna cancellazione silenziosa. Restituisce un
  `RiepilogoUnione` (unite per tipo, conflitti, scartate) che dà i testi «3 dall’iPhone di stamattina: una nota e due
  attività».
- `Motori/TestiOvunque.swift` — i testi: «Sincronizzato · N minuti fa», «N dall’iPhone di stamattina: …», l'avviso
  «Mac, iPhone e iPad allineati · N modifiche unite», i plurali (1 nota / 2 note, 1 attività / 2 attività).
- `Shell/StatoShell+Ovunque.swift` — `sincronizzaOra()`, stato pubblicato `faseOvunque` (spenta, maiFatta,
  inCorso, riuscita(Date), errore(String), conflitti(Int)), lavoro fuori dal thread principale (lo zip dell'archivio
  con i documenti può essere grande: a segmenti come i backup, mai tutto in memoria).
- `Shell/ImpostazioniOvunque.swift` (Mac) — la pagina: card con `SchemaOvunqueApple`, righe con `CardImpostazioniApple`,
  telefono con `TelefonoEsempioOvunque`; foglio «Vedi» (`FoglioModificheInAttesa`).
- `DesignSystem/Apple/SchemaOvunqueApple.swift` — il disegno Mac → iCloud → iPhone (forme `Path` con le coordinate di
  §2.2, pallini con fase continua) e `Tema.Apple+Ovunque.swift` con tutti i numeri di §2 e i tempi di §3
  (`giroPallini 2.4`, `giroVeloce 0.8`, `partenze [0, 0.6, 1.2, 1.8]`).
- `SchedaImpostazioni.ovunque` (titolo «iPhone e iPad»), nella barra laterale vicino ad «Archivio e backup».
- **iOS**: `iOS/OvunqueMobile.swift` (scelta della cartella con segnalibro, lettura della copia, scrittura del diario,
  pillola), pagina «iPhone e iPad» in `ImpostazioniMobile.swift` al posto di «Rimanda al Mac» quando la copia è
  accesa; `AperturaBackup` propone «Usa la copia di iCloud Drive» accanto ad «Apri il backup».
- **Pillola «Senza Mac · copia cifrata»** in `iOS/BarraMobile.swift`: si vede quando il Mac non risponde al ponte
  (`PonteRuby` … `stato(attesa:)` restituisce nil) e si lavora sulla copia; con il Mac raggiungibile la pillola non c'è
  (proposta).
- Riga «iPhone e iPad» della pagina Ruby: resta (è il ponte di Ruby, cosa diversa dalla copia).

#### 5.4 Campi nuovi dell'archivio (nomi proposti)
In `Impostazioni` (Mac e dispositivi), con `decodeIfPresent` e la versione dell'archivio da 25 a 26:
```swift
struct ImpostazioniOvunque: Codable, Equatable {
    var acceso = false                 // «Copia cifrata su iPhone e iPad»
    var modificheDaiDispositivi = true // «Lavora anche con il Mac spento»
    var cartella: String?              // Mac: percorso (nil = iCloud Drive › Prisma › Ovunque)
    var ultimaCopia: Date?             // Mac: ultima copia scritta
    var ultimoErrore: String?
    var unitePerDispositivo: [String: Int] = [:] // ultimo numero unito per dispositivo
}
```
Solo sul dispositivo, **fuori** dall'archivio (che finisce nella copia e nei backup): segnalibro della cartella
(`UserDefaults` «ovunque.segnalibro», `Data`), nome del dispositivo, numero progressivo del diario, ultima copia letta;
password nel Portachiavi del dispositivo («Prisma backup»). I conflitti aperti stanno nell'archivio del Mac
(`conflittiOvunque: [ConflittoOvunque]`) per sopravvivere a un riavvio.
Il backup deve comprendere `ImpostazioniOvunque` (non i diari): aggiornare `Prisma --prova-backup`.

#### 5.5 Prove nuove
- `Dati/ProvaOvunque.swift` (dentro `--prova-backup`, perché tocca archivio e cifratura):
  - copia scritta e riletta con la password giusta; password sbagliata → `ErroreBackup.passwordErrata`; file troncato →
    `backupDanneggiato`;
  - scrittura atomica: una copia interrotta lascia leggibile quella di prima;
  - diario cifrato scritto e riletto; numeri progressivi senza buchi.
- `ProvaCalcoli` (nuovo gruppo «Unione ovunque», `MotoreUnioneOvunque`):
  - una nota e due attività aggiunte sull'iPhone → 3 unite, testo «una nota e due attività»;
  - stessa attività cambiata sul Mac e sull'iPhone → 1 conflitto, nulla sovrascritto;
  - operazione già unita (numero ≤ `unitePerDispositivo`) → ignorata, l'unione ripetuta dà lo stesso archivio;
  - due dispositivi che aggiungono note diverse allo stesso cliente → entrambe;
  - cliente cancellato sul Mac e nota aggiunta sull'iPhone → conflitto, non una nota orfana;
  - testi: «Sincronizzato · 2 minuti fa», «1 dall’iPad di ieri: un appuntamento», plurali.

---

### 6. Dati che l'utente deve dare (mai inventarli)

| Dato | Dove si dà | Finché manca |
|---|---|---|
| Accensione della copia (consenso a mettere un file cifrato in iCloud Drive) | interruttore «Copia cifrata su iPhone e iPad» | stato «spenta»; nessun file scritto |
| Password dei backup (la «chiave») | Impostazioni › Archivio (esiste) | stato «Serve la password dei backup»; mai una copia in chiaro |
| Cartella in iCloud Drive (se non quella predefinita) | Mac: «Scegli…»; iPhone/iPad: scelta della cartella la prima volta | Mac: predefinita; dispositivo: «Scegli la cartella Prisma › Ovunque in iCloud Drive» |
| Password sul dispositivo | campo della prima apertura (come `AperturaBackup`) | la copia non si apre |
| Se i dispositivi possono cambiare i dati | interruttore «Lavora anche con il Mac spento» | predefinito da decidere (template: acceso) |
| Scelte sui conflitti | foglio «Vedi» | le operazioni restano in attesa, nulla si sovrascrive |

Nel template sono dimostrativi «Giulia Rossi», «via Roma 12», «204.050 €», «52%», «48%», la nota e «3 modifiche».
Nell'app il telefono d'esempio mostra il cliente dell'ultima modifica in attesa con il patrimonio netto di
`MotorePatrimonio` e due aree di `MotoreAree360`; senza dati veri mostra i dati di prova (uno dei 5 clienti del
template) con la scritta «dati di prova». Le ore («2 minuti fa», «stamattina») vengono dal registro della copia; il
«via Roma 12» viene dal luogo dell'appuntamento, se c'è, altrimenti la riga non si mostra.

---

### 7. Istantanee da aggiungere

Mac (numerazione dopo le 53x di OCF: proposta **560-…**, da verificare con gli altri giri):
| Nome | Cosa mostra |
|---|---|
| `560-impostazioni-ovunque` / `560-impostazioni-ovunque-scuro` | sezione «iPhone e iPad» sincronizzata, 3 modifiche in attesa, pallini fermi nelle posizioni di `chiaro-13`/`scuro-13` |
| `561-impostazioni-ovunque-spenta` | interruttore spento, schema fermo, nessun pulsante |
| `562-impostazioni-ovunque-in-corso` | «Sincronizzo…», pulsante disattivato |
| `563-impostazioni-ovunque-password` | «Serve la password dei backup» |
| `564-impostazioni-ovunque-icloud-assente` | «iCloud Drive non risponde», nuvola grigia |
| `565-impostazioni-ovunque-conflitti` / `565-impostazioni-ovunque-conflitti-scuro` | foglio «Vedi» con una nota, due attività e un conflitto |
| `566-impostazioni-ovunque-allineati` | «Nessuna: Mac, iPhone e iPad sono allineati.» |

iPhone e iPad (`IstantaneeMobile.swift`, numerazione dopo le 53):
| Nome | Cosa mostra |
|---|---|
| `60-ovunque-senza-mac` | barra con la pillola «Senza Mac · copia cifrata», dossier del cliente con la nota nuova e «3 modifiche si uniranno al Mac» (come il telefono d'esempio) |
| `61-ovunque-impostazioni` | Impostazioni › iPhone e iPad del dispositivo: ultima copia letta, modifiche da unire |
| `62-ovunque-scegli-cartella` | prima volta: scelta della cartella e password |
| `63-ovunque-ipad` | iPad con la pillola nella barra |

Aggiornare la vetrina (`VetrinaApple`, «400-vetrina-apple») con `SchemaOvunqueApple` nello stato finale e la pillola
«Senza Mac», e la pagina online delle anteprime.

---

## 14. Tutti i dati da chiedere all'utente

Qui sono raccolti, senza doppioni, i dati che le sezioni chiedono all'utente. Prisma non li inventa: finché mancano
mostra ciò che dice l'ultima colonna. Le righe segnate **decisione** non sono dati da inserire nell'app ma scelte da
fare una volta, prima di scrivere il motore. Dove la colonna «Finché manca» dice «proposta», il comportamento è una
proposta delle sezioni, da confermare. I dettagli stanno nel §N.6 delle sezioni citate.

### 14.1 Studio: obiettivi, provvigioni, ricavi (§1, §2)

| # | Dato | Dove si inserisce nell'app | Finché manca si vede | § |
|---|---|---|---|---|
| 1 | **Obiettivi dell'anno**: produzione Alleanza in € con la sua definizione (premi annui, premi più versamenti unici, capitali o la misura di Alleanza), numero di nuovi clienti, ricavi della consulenza in € | Impostazioni › Studio; pulsante «Imposta gli obiettivi dell'anno» nel Cruscotto | Cruscotto: al posto degli anelli «Imposta gli obiettivi dell'anno» con il pulsante; con obiettivi a metà solo gli anelli che hanno un traguardo. Scrivania: «Obiettivo consulenza» «—» con «Dai a Studio gli obiettivi dell'anno» (le due parti differiscono sugli anelli vuoti: vedi §15.1, punto 16) | 1, 2 |
| 2 | **Aliquote provvigionali Alleanza**, d'acquisto e ricorrenti, per prodotto o almeno per area/tipologia, distinte fra primo anno e rinnovi, con la base di calcolo (premio annuo, rata, versamento unico) e il momento in cui maturano | Impostazioni › Studio | Tile Alleanza «—» con «Imposta le aliquote in Impostazioni › Studio»; parte Alleanza degli incassi vuota; numero grande con la nota «solo consulenza»; «Ricavi del mese» con «stima senza le tue aliquote». Con alcune aliquote mancanti: «stima · N posizioni senza aliquota» | 1, 2 |
| 3 | **Rinnovi**: quali prodotti Alleanza danno provvigioni ricorrenti e per quanti anni | Impostazioni › Studio, con le aliquote | Come la riga 2 per la parte ricorrente | 2 |
| 4 | **Ricavi del 2025** mese per mese, divisi per canale, se posizioni e parcelle del 2025 non sono tutte in archivio | Studio › Cruscotto (inserimento a mano dell'anno precedente) | Niente linea tratteggiata né percentuale; al posto di «+18% sul 2025» la scritta «primo anno in Prisma» | 2 |
| 5 | **Criterio dei ricavi**: per competenza (firma, emissione, provvigione maturata) o per cassa (incasso); e se il mese è quello solare in corso | decisione (poi Impostazioni › Studio) | — | 1, 2 |
| 6 | **Soglie della zona «molto tempo, poco valore»** (ore e ricavi), oppure il via libera alla mediana automatica | Impostazioni › Studio (`sogliaOre`, `sogliaRicavi`) | Mediana delle ore e mediana dei ricavi dei clienti | 2 |
| 7 | **Ore fuori agenda**: se contare telefonate, preparazione e pratiche, e come (forfait per appuntamento o campo a mano) | decisione; poi Impostazioni › Studio o l'appuntamento | Si contano solo le durate degli appuntamenti in agenda; senza durate né appuntamenti la card 5 è vuota (§2.1.8) | 2 |
| 8 | **Cosa conta come «nuovo cliente»** e la **data d'inizio del rapporto** dei clienti già in archivio (`creatoIl` dice solo quando è stato inserito in Prisma) | decisione; la data nel dossier › Anagrafica (campo nuovo) | Si usa `creatoIl` con la nota «dalla data di inserimento in Prisma» (oppure l'anello resta vuoto: da decidere) | 1, 2 |
| 9 | **Ordine del dock** e posto di Prodotti, Note e Ricerca, che escono dal dock | decisione | Il dock di oggi | 1 |

### 14.2 Parcelle e fatture (§3)

| # | Dato | Dove si inserisce nell'app | Finché manca si vede | § |
|---|---|---|---|---|
| 10 | **Parcelle già emesse nel 2026**: numero, cliente, importo, stato (bozza, da incassare, pagata), data di emissione, data d'incasso, se è ricorrente | Studio › Parcelle e fatture, «Nuova parcella» | «Da incassare» 0 €; ricavi della consulenza a zero; incassi indipendenti dei prossimi 12 mesi vuoti | 1, 2, 3 |
| 11 | Consulente: **nome e cognome** (o denominazione) come in fattura, **partita IVA**, **codice fiscale**, **sede** completa (indirizzo, civico, CAP, comune, provincia, nazione) | Impostazioni › Studio › Fatturazione | Elenco, totali, modulo e PDF funzionano; sul foglio i segnaposto «••••» con «da completare» in ambra e nel piede «Documento di prova»; «Prepara il file XML» spento; tile arancio con i campi mancanti | 3 |
| 12 | Consulente: **regime fiscale** (codice RF), che Prisma non sceglie | Impostazioni › Studio › Fatturazione | Riga «Voci fiscali — secondo il regime impostato», totale uguale all'imponibile con «provvisorio»; l'emissione chiede conferma (o è bloccata: §15.4) | 3 |
| 13 | Consulente: **IVA** (aliquota, oppure natura con il riferimento normativo) ed esigibilità | Impostazioni › Studio › Fatturazione | Come la riga 12; XML spento | 3 |
| 14 | Consulente: **contributo previdenziale o cassa** (se c'è: tipo, aliquota, se va a IVA e a ritenuta) | Impostazioni › Studio › Fatturazione | Come la riga 12 | 3 |
| 15 | Consulente: **ritenuta d'acconto** (se si applica e per quali clienti, tipo, aliquota, base, causale) | Impostazioni › Studio › Fatturazione | Come la riga 12 | 3 |
| 16 | Consulente: **imposta di bollo** (se e quando, importo, soglia, a carico di chi) | Impostazioni › Studio › Fatturazione | Come la riga 12 | 3 |
| 17 | Consulente: **iscrizione all'albo** da riportare (albo, provincia, numero, data), se la vuole | Impostazioni › Studio › Fatturazione | Non si stampa (campo facoltativo) | 3 |
| 18 | Consulente: **contatti** da stampare (email, telefono, PEC) | Impostazioni › Studio › Fatturazione | Non si stampano (facoltativi) | 3 |
| 19 | Consulente: **IBAN**, banca, beneficiario, modalità e termini di pagamento | Impostazioni › Studio › Fatturazione | Segnaposto «da completare» sul foglio; nell'XML mancano i dati di pagamento | 3 |
| 20 | **Numerazione**: formato (il template usa 2026/016), numero di partenza di quest'anno, serie a parte per le note di credito | Impostazioni › Studio › Fatturazione | Proposta: progressiva per anno da 1, assegnata all'emissione (la bozza non ha numero) | 3 |
| 21 | **Trasmittente**: carica il file lui o il commercialista (in quel caso il codice fiscale del commercialista) | Impostazioni › Studio › Fatturazione | «Prepara il file XML» spento, tra i campi mancanti | 3 |
| 22 | **Diciture del piede** (testo esatto dato dall'utente o dal commercialista) | Impostazioni › Studio › Fatturazione | Piede senza diciture | 3 |
| 23 | **Testata della carta**: cuoio del canale o grigio neutro come nel template | decisione | Grigio neutro del template | 3 |
| 24 | **Tipo di documento**: fattura TD01, parcella TD06, nota di credito TD04 | decisione (poi il modulo della parcella) | — | 3 |
| 25 | **Totali**: «Da incassare» e «Incassato» sul totale del documento o sul netto a pagare | decisione | — | 3 |
| 26 | Cliente: **codice fiscale**, eventuale **partita IVA** o denominazione | Dossier › Anagrafica | «Codice fiscale ••••» in ambra e la tile «mancano per {cliente}: …» | 3 |
| 27 | Cliente: **indirizzo completo** diviso in via, civico, CAP, comune, provincia, nazione | Dossier › Anagrafica | «Indirizzo del cliente» in ambra e la tile dei campi mancanti | 3 |
| 28 | Cliente: **codice destinatario** (7 caratteri) o **PEC**; 0000000 per i privati | Dossier › Anagrafica | Tile dei campi mancanti; XML spento per quel cliente | 3 |
| 29 | Cliente: se è **sostituto d'imposta** (per la ritenuta) | Dossier › Anagrafica | Tile dei campi mancanti | 3 |

### 14.3 Track record (§4)

| # | Dato | Dove si inserisce nell'app | Finché manca si vede | § |
|---|---|---|---|---|
| 30 | **Valori aggiornati** delle posizioni nate da proposte accettate (controvalore con data, ed eventualmente versato): almeno uno dopo quello alla firma | Posizioni › la posizione (valore aggiornato, rilevazioni) o da estratto conto | «da misurare · serve un valore aggiornato»; tile 4 «—» con «servono valori aggiornati» | 4 |
| 31 | **L'alternativa di ogni proposta** («invece di») e il metro per ricostruirla (inflazione, gestioni separate, indice del consulente, tasso di un conto deposito) | La proposta (seguito della proposta o scheda di adeguatezza) | Alternativa ricavata da Prisma (posizione sostituita, altrimenti il metro della posizione): «invece di: lo stesso capitale al ritmo dell'inflazione» e nel dettaglio «Ricavata da Prisma: scrivila nella proposta per renderla esatta.» | 4 |
| 32 | **Valori annui degli indici del consulente** (per esempio il conto deposito anno per anno dal 2024) e gli aggiornamenti di inflazione e gestioni separate | Impostazioni › Rendimenti (Riferimenti, esiste) | L'indice non è fra i metri da scegliere; resta l'inflazione | 4 |
| 33 | **Date di chiusura** (riscatto, disdetta, scadenza) delle posizioni chiuse, almeno per le accettate dal 2024 | Posizioni › la posizione (`chiusaIl`) | Da decidere: escluse dalla tile «Ancora in essere dopo 12 mesi» o contate come chiuse (§15.5) | 4 |
| 34 | **Motivo** di ogni proposta | Scheda di adeguatezza, campo motivazione | «Motivo non scritto» | 4 |
| 35 | Se tenere le **raccomandazioni senza prodotto** (ribilanciamenti, rendite non sottoscritte) e i **contatti che non sono clienti**, e in che forma | decisione | Non compaiono | 4 |
| 36 | **Anno di partenza** del track record (il template dice «dal 2024») | decisione (poi Impostazioni › Studio) | Tutte le proposte in archivio | 4 |

### 14.4 Messaggi (§5)

| # | Dato | Dove si inserisce nell'app | Finché manca si vede | § |
|---|---|---|---|---|
| 37 | **Tipi di occasione** (riepilogo incontro, scadenze, compleanni, compleanni tondi, consensi, riesami, occasioni dei contratti) e **anticipo** di ciascuno (45 giorni del template o 30 delle Occasioni) | Impostazioni › Messaggi | Occasioni calcolate dai motori, con in alto «Dati di prova: testi e regole da confermare in Impostazioni › Messaggi» | 5 |
| 38 | **Firme e saluti**, distinte per Alleanza (ruolo, agenzia) e indipendente («Denis Vicenzoni · Consulenza finanziaria»), con i recapiti in calce | Impostazioni › Messaggi | Firma = `Impostazioni.nomeUtente`; nel tono formale nome e cognome del profilo | 5 |
| 39 | **Tu o lei** per ciascun cliente, o una regola generale | Dossier › Anagrafica (campo proposto `Cliente.registro`) | Tono «Cordiale» = tu | 5 |
| 40 | **Testi base** per ogni tipo e tono (Cordiale, Formale, Breve), approvati o riscritti | `Ruby/Istruzioni/messaggi.md` ed `Ruby/Esempi/messaggi.json` | I testi del template, come dati di prova | 5 |
| 41 | **Consenso commerciale**: per quali messaggi serve e se senza consenso si blocca o si avvisa | Impostazioni › Messaggi | Pillola arancio, nessun blocco | 5 |
| 42 | **Canale preferito** di ogni cliente (Mail o Messaggi; WhatsApp non è Messaggi di Apple) | Dossier › Anagrafica | Si sceglie a mano nel pannello | 5 |
| 43 | Per i clienti Alleanza: **posta aziendale** invece di Mail del Mac, e regole o testi approvati da Alleanza | decisione | Mail del Mac, senza testi Alleanza | 5 |
| 44 | **Email e telefono** veri dei clienti, con il prefisso da usare (+39 se manca?) | Dossier › Anagrafica | Messaggi: «Manca il recapito», mai un indirizzo inventato. Prova del fuoco: «Chiama» mostra l'invito ad aggiungere il numero | 5, 6 |
| 45 | Se scrivere anche a **chi non ha un dossier** (potenziali clienti, familiari) | decisione | Solo clienti con dossier | 5 |
| 46 | **Dove ritrovare i messaggi salvati** nel dossier (Documenti, Nel tempo, Note) | decisione | — | 5 |

### 14.5 Prova del fuoco (§6)

| # | Dato | Dove si inserisce nell'app | Finché manca si vede | § |
|---|---|---|---|---|
| 47 | **Quota azionaria e quota in titoli di Stato** delle posizioni dove mancano | Posizioni › la posizione (campi esistenti) | Stima dalla tipologia e dall'SRI, con «≈» sulla riga e la nota in fondo | 6 |
| 48 | **Durata finanziaria** della parte obbligazionaria (campo nuovo `Posizione.durataObbligazioni`), o la conferma delle durate predefinite: monetari 0,5; breve termine 2; obbligazionari 6; bilanciati e flessibili 5; previdenza 7; altrimenti 5 anni | Posizioni › la posizione | Prova del fuoco: durata predefinita con «≈». Mercato: frase qualitativa al posto della cifra dell'impatto dei tassi | 6, 12 |
| 49 | **Obiettivi dei clienti con le posizioni collegate** | Dossier › Obiettivi | Riga senza barra «Nessun obiettivo nel dossier»; con un obiettivo senza posizioni collegate la barra non si muove (tranne con l'inflazione) e c'è la nota «nessuna posizione collegata» | 6 |
| 50 | Conferma della **soglia** «più di 10 punti» (arancio sopra 5) e dei **cursori** (mercati 5-45 da 25, tassi 0,5-4 da 2, inflazione 2,5-9 da 5 per 3 anni) | decisione | I valori del template | 6 |
| 51 | **Valori storici**: quelli di `CrisiStoriche` (2008 azioni −37%, 2020 −33%) o quelli del template (−45%, −30%) | decisione | Quelli di `CrisiStoriche`, già documentati nel metodo | 6 |

### 14.6 Linea della vita e famiglie come la sua (§7, §10)

| # | Dato | Dove si inserisce nell'app | Finché manca si vede | § |
|---|---|---|---|---|
| 52 | **Data di nascita** di ogni cliente | Dossier › Anagrafica | Linea della vita: solo il titolo e «Per disegnare la linea della vita serve la data di nascita di {nome}.» con «Completa l'anagrafica ›». Famiglie: «Per confrontare {Nome} servono età e reddito della famiglia.» con «Completa il dossier» | 7, 10 |
| 53 | **Eventi della vita** con importo (entrata o uscita, in euro di oggi), anno e mese, una volta o ogni anno per N anni | Bisogni › Eventi della vita, o il gettone sulla linea | Evento senza importo: gettone grigio «senza cifra», fuori dal calcolo. Nessun evento: «Nessun evento nella linea della vita. Aggiungi la casa, i figli, un'eredità: Prisma ricalcola il futuro.» | 7 |
| 54 | **Risparmio annuo libero** della famiglia, oltre ai versamenti delle posizioni (o le spese mensili) | Dossier › Profilo (campo nuovo `ProfiloInvestitore.risparmioAnnuo`) | Linea della vita: «Risparmio libero non indicato: conto solo i versamenti delle posizioni.» Famiglie: voce Risparmio con «—» e «Manca {cosa}: indicalo nel dossier per il confronto.» | 7, 10 |
| 55 | **Reddito netto mensile desiderato in pensione**, confermato (non il predefinito 2.200) | Analisi 360 › Previdenza | Curva tratteggiata dopo la pensione e «Manca il reddito desiderato in pensione: dopo i {età} anni la linea è solo indicativa.» | 7 |
| 56 | **Dati del lavoro e dei contributi**, o la pensione pubblica netta a mano | Dossier › Profilo › Lavoro, o Analisi 360 | Il motivo di `MotorePensionePubblica.motivoAssente`; il prelievo in pensione non si calcola | 7 |
| 57 | **Età di pensione** (`DatiLavoro.etaPensione`) | Dossier › Profilo › Lavoro | 67, con la scritta «ipotesi» sul gettone | 7 |
| 58 | **Rendimento reale atteso** per la linea della vita | Analisi 360 › Previdenza (`rendimentoReale`) o Impostazioni | Ipotesi di Prisma, scritta nelle righe di metodo | 7 |
| 59 | Se il **patrimonio di partenza** comprende casa e altri immobili o solo il patrimonio finanziario | decisione | — | 7 |
| 60 | **Reddito familiare netto annuo** | Dossier › Profilo | Come la riga 52, seconda frase | 10 |
| 61 | **Importi degli eventi dei clienti di prova** (matrimonio, casa, figlio, eredità di Giulia; un caso che si esaurisce prima dei 90 per Sofia) | `Dati/DatiDemo.swift`, `Dati/ClientiFittizi.swift` | Scheda vuota nelle istantanee | 7 |
| 62 | **Tabelle dell'Indagine sui bilanci delle famiglie** (Banca d'Italia), nel formato JSON `prisma-famiglie-1` o CSV: anno, classi d'età del capofamiglia, classi di reddito netto con gli estremi, quantili 5-10-25-50-75-90-95 per età × reddito, numero di famiglie per cella | Impostazioni › Riferimenti (importazione del file) | Percentuali di prova del template, pillola «dati di prova» accanto al segmentato e la nota «Confronto di prova…»; le cifre di prova non vanno né a Ruby né nei PDF | 10 |
| 63 | **Quote di famiglie a zero** per previdenza complementare e protezione, per ogni cella | nello stesso file | Come la riga 62 | 10 |
| 64 | **Definizioni dell'indagine**: cosa entra in «attività finanziarie» (polizze vita, fondi pensione, liquidità?), la variabile della protezione (premi, possesso di polizze caso morte), la variabile della previdenza complementare (iscrizione, contributi, montante) | decisione, dalla documentazione dell'indagine | Come la riga 62 | 10 |
| 65 | **Soglia minima di famiglie per cella** sotto la quale il confronto è «circa» | Impostazioni › Riferimenti | Da fissare prima di mostrare dati veri; con i dati di prova non serve | 10 |
| 66 | **Classi d'età**: le decine del template (30-39) o quelle dell'indagine (fino a 34, 35-44, …) | decisione | Le classi del file | 10 |

### 14.7 Copilota dell'incontro e Inquadra e capisci (§8, §9)

| # | Dato | Dove si inserisce nell'app | Finché manca si vede | § |
|---|---|---|---|---|
| 67 | **Testo del consenso all'ascolto** e come si raccoglie (a voce e annotato, firmato, dentro l'informativa già firmata) | Impostazioni › Incontri | Il testo del template come segnaposto «dati di prova»; «Registra il consenso» annota solo data e ora | 8 |
| 68 | Se la **trascrizione** si conserva nel dossier o si cancella dopo il verbale, e per quanto tempo | Impostazioni › Incontri | Non si conserva: resta solo il verbale confermato | 8 |
| 69 | **Come chiamare il consulente** nelle righe della trascrizione («Denis», «Tu», le iniziali) | Impostazioni › Incontri | `Impostazioni.nomeUtente` | 8 |
| 70 | **Frasi di timore e propensione** che ne segue, e se è lecito annotarla per obiettivo senza rifare il questionario MiFID | `Ruby/` (istruzioni del copilota) | Solo «prudente» per le frasi del template, con «annotazione, non profilo MiFID» | 8 |
| 71 | **Tipi di polizza** da riconoscere e nomi delle **compagnie** più frequenti | `Ruby/` (istruzioni del copilota) | L'elenco del §8.5.3, punto 4 | 8 |
| 72 | **Scadenza dell'obiettivo** quando il cliente dice solo «tra tre anni» (fine di quell'anno o stesso giorno) | decisione | Lo stesso giorno fra tre anni, segnato «da confermare» nel verbale | 8 |
| 73 | **Scadenza delle attività** del verbale («entro venerdì» compare nel verbale ma nessuno lo dice nel dialogo) | decisione | Nessuna scadenza inventata: l'attività resta senza data finché non la si scrive (proposta) | 8 |
| 74 | Se **Alleanza** ha regole interne sulla registrazione o trascrizione dei colloqui | decisione | «Verifica le regole di Alleanza sull'ascolto» sugli incontri dei clienti Alleanza | 8 |
| 75 | **Canale di una polizza di un'altra compagnia** (oggi `Canale` ha solo Alleanza e indipendente) | decisione | «altra compagnia» con l'etichetta cuoio del canale indipendente | 8, 9 |
| 76 | **Tariffe di una temporanea caso morte** (premio ogni 1.000 € per età, durata, fumatore o no) e di quale compagnia (Alleanza o mercato) | Impostazioni (tariffe della temporanea) | «—» e «Manca una tariffa della temporanea: la trovi in Impostazioni»; con i dati di prova la media delle temporanee di prova, con «dati di prova» | 9 |
| 77 | **Capitale della temporanea** nel confronto: fabbisogno della famiglia, stesso capitale della polizza o stessa spesa | decisione | Il fabbisogno (`EsitoProtezione`) se c'è, altrimenti lo stesso capitale della polizza | 9 |
| 78 | **Condizioni di riscatto** della polizza inquadrata (penali, anni minimi, rendimento della gestione separata) | Posizioni › la posizione | Solo «sì, cresce nel tempo» (dalla tipologia), senza cifra | 9 |
| 79 | **2-3 documenti veri anonimi** (polizza vita, KID, estratto conto) | da dare a chi sviluppa, per le prove | Si prova sul foglio del template, come immagine di prova | 9 |
| 80 | **iPhone e Mac per la Fotocamera Continuity**: modello di iPhone, stesso ID Apple, Wi-Fi e Bluetooth | sul Mac e sull'iPhone | Stato «L'iPhone non risponde» | 9 |
| 81 | **Testo della richiesta della fotocamera** sull'iPhone (`NSCameraUsageDescription`) | Info dell'app iOS | Il testo proposto al §9.5.2 | 9 |

### 14.8 Esame OCF (§11)

| # | Dato | Dove si inserisce nell'app | Finché manca si vede | § |
|---|---|---|---|---|
| 82 | **Il file delle domande** dal manuale o dalla banca dati, con le risposte giuste e le spiegazioni, nel formato CSV/JSON del §11.5.6 | Studio › Esame OCF, «Importa domande…» | Anello vuoto con «—», «Nessuna domanda ancora»; nella card 2 «Importa le domande del tuo manuale» con «Importa domande…» e «Scarica il modello» | 11 |
| 83 | **Materie** esatte dell'esame e, per la media pesata, quante domande ha ciascuna | Studio › Esame OCF (impostazioni dell'esame) | Le sei materie del template, media semplice | 11 |
| 84 | **Data dell'esame** | Studio › Esame OCF, «Imposta la data dell'esame» | Il pulsante «Imposta la data dell'esame» | 11 |
| 85 | Conferma delle **regole**: soglie 70 / 55; ripasso a 1, 3, 7 giorni; almeno 5 risposte per materia; 10 domande nuove per sessione | decisione | I valori proposti | 11 |

### 14.9 Mercato (§12)

| # | Dato | Dove si inserisce nell'app | Finché manca si vede | § |
|---|---|---|---|---|
| 86 | **Permesso di collegare Prisma a internet** per scaricare solo dati pubblici (BCE, Eurostat, ISTAT), e quali fonti | Impostazioni › Mercato (interruttore, spento) | Nessuna connessione; la fascia dice «Nessun dato esce dal Mac»; le serie arrivano solo dai file | 12 |
| 87 | **Le sei serie** della striscia e, per le azioni, **quale indice** (FTSE MIB, MSCI World in euro, un ETF) e da dove prenderne i valori | Impostazioni › Mercato | Tessera «Da importare» | 12 |
| 88 | **Fonte delle quote dei fondi per ISIN** (piattaforma Alleanza, banca, SGR, altro) con un **file di esempio** | Mercato › importazione | Ricerca ISIN solo nell'archivio, «Quota —» | 12 |
| 89 | **ISIN e numero di quote** delle posizioni in fondi, ETF e titoli | Posizioni › la posizione (anche dai KID e dagli estratti) | La posizione non è collegata al mercato | 12 |
| 90 | **Cedole** dei titoli dei clienti: tasso, periodicità, prossima data | Posizioni › la posizione | Avviso della cedola non disponibile per quella posizione | 12 |
| 91 | **Soglie degli avvisi** (calo dal massimo, giorni prima della cedola, punti di scostamento, variazione in un mese) e **soglia azionaria** di «Chi è toccato» (40%?) | Impostazioni › Mercato; foglio del nuovo avviso | Le soglie del template, scritte come «proposte» | 12 |
| 92 | **Ora dell'aggiornamento quotidiano** (18:00?) | Impostazioni › Mercato | Aggiornamento solo con il pulsante | 12 |
| 93 | **ISIN di prova** che superi la cifra di controllo ma non esista (IE00B4L5Y983 è un ETF reale; LU0000000000 non supera il controllo) | `Dati/DatiDemo.swift` | — | 12 |

### 14.10 Prisma ovunque (§13)

| # | Dato | Dove si inserisce nell'app | Finché manca si vede | § |
|---|---|---|---|---|
| 94 | **Consenso** ad accendere la copia cifrata in iCloud Drive | Impostazioni › iPhone e iPad, interruttore «Copia cifrata su iPhone e iPad» | Stato «spenta»; nessun file scritto | 13 |
| 95 | **Password dei backup** come chiave della copia | Impostazioni › Archivio (esiste) | «Serve la password dei backup»; mai una copia in chiaro | 13 |
| 96 | **Cartella di iCloud Drive**, se non quella proposta (iCloud Drive › Prisma › Ovunque) | Mac: «Scegli…»; iPhone e iPad: selettore alla prima apertura | Mac: la cartella proposta; dispositivo: «Scegli la cartella Prisma › Ovunque in iCloud Drive» | 13 |
| 97 | **Password sul dispositivo** | Campo della prima apertura (come `AperturaBackup`) | La copia non si apre | 13 |
| 98 | Valore predefinito di **«Lavora anche con il Mac spento»** (nel template acceso): i dispositivi cambiano i dati o la copia è di sola lettura | decisione; poi l'interruttore | Da decidere | 13 |
| 99 | **Quali dati** si cambiano su iPhone e iPad nella prima versione (proposta: note, attività, appuntamenti, pochi campi anagrafici; posizioni e prospetti in lettura) | decisione | — | 13 |
| 100 | Se nella copia vanno anche i **file dei documenti** (PDF) o solo i dati | decisione | — | 13 |
| 101 | **Frequenza della sincronizzazione** del Mac (proposta: all'avvio, alla riattivazione e ogni 15 minuti) | decisione | — | 13 |
| 102 | **Scelte sui conflitti** | Foglio «Vedi» delle modifiche in attesa | Le operazioni restano in attesa, nulla si sovrascrive | 13 |

---


## 15. Dubbi e punti in cui il template va contro le regole di Prisma

### 15.1 Dove il template va contro le regole di Prisma
Ogni punto rimanda alla sezione che lo tratta. Nell'app vale sempre la regola di Prisma; dove serve una scelta
dell'utente, la domanda è nei dubbi della sezione (§15.2-§15.14).

1. **Internet (Mercato, §12).** CLAUDE.md dice «tutto resta in locale, niente server, niente cloud»: Mercato sarebbe la
   prima connessione di Prisma a internet. Proposta: un interruttore in Impostazioni, spento di serie, che apre solo
   verso fonti pubbliche e non manda nulla dei clienti. La fascia del template («Dal Mac escono solo gli ISIN») va
   cambiata: anche un elenco di ISIN descrive i portafogli dei clienti, e gli ISIN non escono mai.
2. **Cloud (Prisma ovunque, §13).** La copia per iPhone e iPad passa da iCloud Drive. Oggi iCloud Drive è ammesso solo come
   cartella dei backup scelta dall'utente. Proposta: copia sempre cifrata con la password dei backup, accesa solo con un
   consenso esplicito, niente CloudKit né server. La fattibilità con AltStore e un ID Apple gratuito va provata su un
   iPhone vero.
3. **Dati inventati e cifre fisse.** Il template ha testi fissi dove servirebbero conti (tile «Rispetto all'alternativa,
   in media» del §4; «Incassato nel 2026» del §3 che non torna con l'elenco), valori storici diversi da `CrisiStoriche`
   (§6), un ISIN reale usato come prova (§12), un capitale della temporanea che non torna con la nota «a parità di spesa»
   (§9), scadenze che nessuno ha detto («entro venerdì», §8), chi parla riconosciuto da solo (§8). Nell'app ogni cifra
   viene da un motore e ogni dato mancante si dice.
4. **«Riduci movimento» ignorato.** Anelli e barre del Cruscotto (§2), righe e schede del copilota (§8), pallini di
   Ovunque (§13), segnaposti delle famiglie (§10), barra della Prova del fuoco che anima ancora 0,8 s (§6), pallino rosso
   degli avvisi che pulsa senza fine (§12). In Prisma tutto compare fermo con una dissolvenza di 0,15 s.
5. **Animazioni a tempo finte.** La barra «Preparo il file…» di 1,2 s quando il file si scrive subito (§3), i contatori
   che ripartono dall'ultimo valore (§6). Niente Timer: animazioni di SwiftUI e `Animatable`, e solo quando c'è lavoro vero.
6. **Colori fissi uguali in chiaro e scuro, valori fuori dal tema.** Anelli di «Il tuo studio» e del Cruscotto, barre
   dell'imbuto, linea 2026 (§1, §2), grafico della linea della vita (§7): nello scuro i colori dei canali diventano
   #6B95FF e #D0954A. Caratteri e raggi che il tema non ha (titolo del messaggio a 23 pt e titolo voce bold 700 al §5,
   carattere 28 e raggio 16 al §11), pillola all'accento 10% invece di `Colore.selezioneVoce` 13% (§5), due verdi diversi
   (§9), pulsante «■ Termina» #14202B che nello scuro si confonde con la scheda (§8). Ogni valore nuovo diventa un token
   in `Sources/Prisma/DesignSystem/`.
7. **Canale non riconoscibile.** «Chi è toccato» e gli avvisi di Mercato (§12) e la lista della Prova del fuoco (§6) non
   mostrano il canale; la testata della fattura è grigia anche se il canale indipendente è cuoio (§3); la «Polizza di
   un'altra compagnia» usa #B06E12, cioè il cuoio dell'indipendente (§8), e il canale «altra compagnia» non esiste in
   `Canale` (§8, §9).
8. **Collegamenti sbagliati fra le app.** «Manda con Messaggi» delle fatture apre il riepilogo dell'incontro di Giulia
   (§3); Studio, Mercato e Prova del fuoco aprono tutti la stessa voce di prova di Messaggi (§5, §12); «Prepara un
   messaggio» apre sempre il messaggio di Marco sull'Infortuni (§12).
9. **Dipendenze esterne.** Lo schema XSD ufficiale FatturaPA per validare l'XML (§3) è un file esterno: va chiesto prima di
   metterlo nel repository.
10. **Target macOS 13.** `onKeyPress` (tastiera dell'Esame OCF, §11) richiede macOS 14: si usano pulsanti nascosti con
    `.keyboardShortcut`.
11. **M1 con 8 GB.** L'ascolto continuo del copilota (§8, proposta di durata massima 2 ore), i microdati dell'indagine sulle
    famiglie (§10), la cascata dei punti con molti clienti (§2) vanno tenuti leggeri.
12. **Privacy dei clienti.** Trascrizioni degli incontri (§8), foto dei documenti (§9), copia sui dispositivi (§13): tutto
    resta sul Mac o cifrato, con consenso e regole di conservazione da decidere. Le domande del manuale OCF finirebbero nei
    backup (§11): va verificato per i diritti sul manuale.
13. **Struttura della scrivania.** «Da fare oggi» sparisce dalla scrivania del Mac (§1) e il dock perde Prodotti, Note e
    Ricerca (§1). Posizioni resta subito dopo Clienti, come vuole il principio permanente.
14. **Difetti di disegno del template, da non copiare.** Dispersione del Cruscotto calcolata su 330 in una card larga 560
    (§2); avatar sovrapposti di «Chi è toccato» invisibili per un doppio attributo `style` (§12); scritta «solo un file
    cifrato» fuori dal disegno (§13); grafico della linea della vita largo 1040 in 1018 di contenuto, con trascinamento
    calcolato su 1016 (§7); gettoni che si accavallano (§7); linea dell'alternativa tratteggiata nel codice e piena nelle
    schermate (§4); schede del copilota che si duplicano al riavvio (§8); lista della Prova del fuoco a top fisso (§6);
    risultato ISIN tagliato con più di 4 avvisi (§12).
15. **Errore nel codice di oggi.** `StatoShell.creaPosizione(da:canale:area:)` mette sempre la frequenza `.annuale`, quindi
    «90,00 € al mese» diventerebbe 90 € l'anno; e `MotoreConfrontoDossier.frequenzaPremio` non riconosce «al mese» (§9).
16. **Parti che non si accordano fra loro.** Senza obiettivi il §1 lascia gli anelli vuoti, il §2 li toglie e mostra
    «Imposta gli obiettivi dell'anno»: proposta, vale il §2 anche per la scrivania. La linea della scansione «si ferma in
    fondo» per il §1, «torna in alto» per il §9 (come nelle schermate): vale il §9. Numeri delle istantanee e versione
    dell'archivio: §0.5.

I dubbi qui sotto sono quelli delle singole parti, così come sono stati scritti. I rimandi «§x.y» valgono dentro la
sezione indicata nel titolo.

### 15.2 Dubbi del §1 — Parte comune

*dalla sezione «Dubbi» della bozza*

1. Dove vanno Prodotti, Note e Ricerca, che escono dal dock? Proposta: Prodotti in Posizioni o in Mercato, Note in Clienti, Ricerca solo come pannello ⌘K.
2. Va bene che le scorciatoie ⌥8 e ⌥9 cambino (oggi Prospetti e Ruby, domani Mercato e Studio)?
3. «Da fare oggi» sparisce dalla scrivania del Mac. Va tolto anche sull'iPad (riga di mezzo in verticale)? E sull'iPhone?
4. Il pannello Novità resta per sempre, o la pillola sparisce quando tutte le voci sono state aperte (o dopo un certo tempo)? Il numero conta le voci ancora da provare?
5. Il pannello si apre da solo una volta per versione (proposta) o a ogni sessione, come nel template?
6. Novità e notifiche devono escludersi a vicenda? Nel template aprire le notifiche non chiude Novità.
7. «Ricavi del mese»: competenza (parcelle emesse, provvigioni maturate) o cassa (incassate)? E il mese è quello solare corrente?
8. Gli anelli di «Il tuo studio» non hanno legenda sulla scrivania. Bastano i colori o serve un suggerimento al passaggio del puntatore?
9. Mercato somiglia molto ad Analisi 360 nel colore e a Posizioni nel glifo. Si tiene così o si cambia tinta e glifo?
10. «Inquadra e capisci» dal Mac apre uno scanner che simula l'iPhone. Sul Mac deve aprire il ponte con l'iPhone (in attesa della foto) o solo spiegare come farlo?
11. Gli anelli di «Il tuo studio» nel template restano #2563EB e #B06E12 anche in scuro, mentre i colori dei canali in scuro sono più chiari (#6B95FF, #D0954A). Si tiene il colore fisso o si usa quello del canale?
12. `genera-icone.js` legge colori e glifi solo da `tema-liquid-glass.html`, dove le tre app nuove non ci sono. Si estende lo script con una tabella delle icone nuove (presa da `template-novita.html` o scritta nello script) o si salvano gli SVG a mano?

### 15.3 Dubbi del §2 — Studio › Cruscotto

*dubbi raccolti dalla bozza*

1. Nel template la linea dei ricavi 2026 arriva a dicembre anche se oggi è novembre: nell'app la si ferma a oggi? Il «+18%» va calcolato a pari data (come suggeriscono le curve, 68,4 contro 58) o sull'anno intero?
2. «Produzione Alleanza» (410.000 € di 500.000 €) è in premi, mentre la tile Alleanza è in provvigioni: confermare che sono due misure diverse e la definizione di produzione.
3. «23 gg alla firma, in media»: va bene la media da presentazione a esito delle sole accettate? Oggi `MotoreSeguitoProposte.statistiche` conta anche le rifiutate.
4. Imbuto: preparate = proposte create nell'anno? Le bozze contano? Le rimandate stanno tra le presentate? La frase per la perdita prima della presentazione è nuova e va approvata.
5. Difetto del template nella dispersione: le x usano W=330 ma la card è larga circa 560, quindi i punti stanno nella metà sinistra mentre l'etichetta «30 ore l'anno» è al bordo destro. Nell'app si usa la larghezza vera; anche gli assi (30 ore, 4.600 €) diventano dinamici?
6. Quali clienti sono in evidenza con le iniziali nella dispersione (preferiti, i più lontani dalla media, quelli nella zona rossa) e quanti al massimo?
7. Colori fissi di anelli, barre dell'imbuto e linea 2026 uguali in chiaro e in scuro, mentre le colonne degli incassi usano `--chA`/`--chI` che cambiano nello scuro: tenerli così o usare `canaleAlleanza`/`canaleIndipendente` scuri anche per anelli e legenda?
8. Colonne degli incassi quando un canale vale zero in un mese: una sola parte con tutti i raggi a 6?
9. Card cliccabili (verso il dettaglio di ricavi, Portafoglio, mese degli incassi, dossier del cliente): il template non lo prevede, da confermare.
10. Riduci movimento: nel template anelli e barre si animano lo stesso; si applica la regola estesa della specifica Apple §2.0 (tutto fermo, dissolvenza di 0,15 s).
11. Curve con superamento (.34,1.3,.64,1) per le colonne e (.34,1.6,.64,1) per i punti: verificare con `timingCurve` in SwiftUI o passare a molle equivalenti; limitare la cascata dei punti con molti clienti.
12. Posizione del dock: Studio tra Mercato e Ruby dipende dall'ingresso delle app Mercato, Messaggi e Prospetti; manca l'icona Studio in `Design/Icone`.
13. Incassi indipendenti dei prossimi 12 mesi: oltre alle parcelle firmate non incassate, servono le parcelle ricorrenti (per esempio la consulenza annuale)? Serve un campo «ricorrente» nella `Parcella`.
14. Numerazione delle istantanee: serie 500 nuova per Orizzonte, da confermare (vedi §0.5).
15. Le aliquote di prova per i dati fittizi non devono mai finire nell'archivio reale: confermare che si caricano solo con i clienti fittizi da Impostazioni.

### 15.4 Dubbi del §3 — Studio › Parcelle e fatture

*dalla sezione «Dubbi aperti» della bozza*

1. **Nome del file XML**: il template scrive `IT_2026-014.xml`. Lo SdI vuole `IT` + identificativo fiscale del trasmittente + `_` + progressivo di 5 caratteri. Nell'app si usa la regola dello SdI?
2. **«Manda con Messaggi»** nel template apre il riepilogo dell'incontro di Giulia (`selM=0`): è un difetto. Nell'app apre un messaggio nuovo per il cliente della fattura con il PDF allegato?
3. **Cosa si manda al cliente**: il PDF (copia di cortesia), l'XML o tutti e due? Per i privati senza codice destinatario può servire una frase sulla copia di cortesia: il testo lo dà il commercialista.
4. **Numero delle bozze**: nel template la bozza ha già un numero (2026/016). Per non lasciare buchi nella numerazione, il numero si assegna solo all'emissione?
5. **Parcella e fattura**: la «parcella» è il preavviso (senza valore fiscale) e la «fattura» il documento emesso, oppure sono la stessa cosa? Il foglio dice sempre «FATTURA».
6. **«Da incassare» e «Incassato»**: si contano sul totale del documento o sul netto a pagare (dopo la ritenuta)? Si aggiunge uno stato «Scaduta» (arancio più forte o rosso)?
7. **Stato SdI**: Prisma non parla con lo SdI (tutto in locale). Basta un «Segnata come inviata il…» messo a mano, o non serve?
8. **Correzioni**: una fattura emessa non si cancella. Servono le note di credito (TD04) già nella prima versione?
9. **Testata della carta**: il template usa la scritta del canale in grigio, senza il colore cuoio. CLAUDE.md vuole il canale sempre riconoscibile: colore cuoio o grigio?
10. **Barra «Preparo il file…»**: il file è immediato. Si tiene la barra da 1,2 s del template o si mostra subito «pronto»?
11. **Riquadro XML quando si cambia fattura**: nel template resta «✓ pronto» anche per la fattura nuova. Nell'app deve dipendere dalla fattura scelta (pronto solo se il suo XML esiste)?
12. **Transizione del foglio**: valori propri del template (0,16 / 0,48 s, spostamento 20) o quelli dei Prospetti (`cambioPagina`, 0,18 / 0,52 s, 30 / 40)?
13. **Schema XSD ufficiale** nel repository per validare l'XML nel workflow con `xmllint`: si può aggiungere (è un file esterno, non una dipendenza di codice)?
14. **Collegamento dal Cruscotto**: la tile «parcelle della consulenza» e il widget della scrivania portano a questa scheda?
15. **Su iPhone e iPad**: la scheda c'è (consultazione e PDF), o solo sul Mac? L'XML si prepara anche lì?

### 15.5 Dubbi del §4 — Studio › Track record

*dubbi raccolti dalla bozza*

1. Tile «Accettate»: accettate su decise (accettate + rifiutate, come `Portafoglio.tassoAccettazione`) oppure accettate su tutte le presentate (rimandate e in attesa comprese)?
2. Tile «Rispetto all'alternativa, in media»: nel template è testo fisso e non conta. Va fatta contare come le altre tile? E la media va pesata sul capitale della proposta o deve essere semplice?
3. Risultato dei fondi pensione: la differenza deve contare anche il risparmio fiscale della deduzione (il template sembra farlo: 4.180 € con «un vantaggio fiscale che restava inutilizzato»), oppure solo il rendimento contro l'alternativa?
4. Alternativa «Nessun versamento integrativo» / «Lasciare i soldi sul conto»: si ricostruisce con un tasso di conto deposito (indice del consulente), con l'inflazione o con un rendimento zero?
5. Rimandate e rifiutate: nel template hanno comunque una linea grigia dell'alternativa, che però non misura nulla di reale. Va tenuta (come sarebbe andata la proposta con il metro della sua famiglia, dichiarata come ipotesi), sostituita con un'altra cosa o tolta?
6. Linea dell'alternativa: nel codice è tratteggiata [4,4] e la legenda dice «┅», ma l'animazione del template la fa diventare piena (nelle schermate è piena). In Prisma la vogliamo tratteggiata (come la legenda) o piena (come le schermate)?
7. Testo della nota: «l'alternativa è ricostruita con i dati di mercato del periodo». Prisma usa i riferimenti (inflazione, TFR, gestioni separate, indici), non dati di mercato generici: va bene «con i riferimenti del periodo»? Oppure aspettiamo l'app Mercato (§12)?
8. Ribilanciamenti («azionario dal 62% al 44%» invece di «restare com'era»): Prisma non ha lo storico dell'allocazione, quindi l'alternativa non si ricostruisce. Li escludiamo dalla prima versione o servono un tipo nuovo di raccomandazione e un dato inserito a mano?
9. Dove salvare l'alternativa: nel seguito della proposta (`SeguitoProposta.alternativa`, che resta con la posizione) o nella scheda di adeguatezza accanto a `posizioneSostituitaId`?
10. Posizioni già chiuse senza `chiusaIl`: le escludiamo dalla tile «Ancora in essere dopo 12 mesi» o le contiamo come chiuse entro 12 mesi (la stima più prudente)?
11. Risultato negativo: proposta di mostrarlo così com'è, in rosso («−1.200 €»). Confermi? Il template mostra solo risultati positivi.
12. Ordine dell'elenco: nel template non è per data (prima le accettate, poi le altre). Va bene: accettate per risultato, poi rimandate, poi rifiutate? Con 64 raccomandazioni servono anche scorrimento e un filtro (Tutte · Accettate · Altre).
13. Nel dettaglio sono utili i pulsanti «Apri la posizione» e, per le rimandate, «Riproponi»? Il template ha solo «Chiudi».
14. Le coperture (temporanea caso morte) non hanno un rendimento: per un'accettata mostriamo il capitale assicurato al posto della differenza?
15. Il Track record va anche nel PDF (la frase «utile anche per la conformità» lo fa pensare)? Se sì, serve un prospetto su carta bianca, che il template non mostra.
16. Numerazione delle istantanee: proposta la 520-525 dopo quelle del Cruscotto (vedi §0.5).

### 15.6 Dubbi del §5 — Messaggi — «Prisma scrive per te»

*dubbi raccolti dalla bozza*

1. Nel template il consenso privacy «è scaduto il 2 settembre», ma in Prisma (`MotoreConformita`) il consenso al trattamento non scade. Scadono il consenso commerciale (`mesiCommerciale`, 24 mesi) o l'informativa aggiornata (`informativaAggiornataIl`): il titolo dell'occasione deve dire quale dei due.
2. Chiara Marino non è tra i 5 clienti né tra i 30 fittizi (nel template ha il campo `x`, cioè nessun dossier). Non si sa se Messaggi debba gestire i contatti senza dossier.
3. Le tre app che rimandano a Messaggi (Studio `#fMsg`, Mercato «Prepara un messaggio», Prova del fuoco «Messaggio») nel template aprono tutte la seconda voce di prova (`selM=1`). Nell'app devono aprire il cliente e il motivo da cui si parte: va definita un'occasione su richiesta (tipi mercato e parcella).
4. «Apri in Messaggi» su macOS: con `sms:` il testo può non passare. Si propone `NSSharingService` `.composeMessage` e, se non va, il testo copiato negli appunti con un avviso diverso. Da provare sul Mac dell'utente.
5. Il testo nel template non si può modificare. Si propone di renderlo correggibile a fine scrittura: da approvare.
6. Il cambio di canale nel template ridisegna il pannello di colpo, senza cascata. La proposta di un passaggio morbido (`matchedGeometryEffect`) tra mail e nuvoletta è da approvare.
7. La nuvoletta SMS ha raggio 22/22/6/22, la bolla della chat di Ruby 20/20/6/20: unificare le due forme o tenerle distinte?
8. Il titolo della voce nel template è bold 700, `Carattere.titoloVoce` in Prisma è semibold 14; il titolo del messaggio a 23 pt non esiste nel tema (vicini 22 e 25): serve un nuovo `Carattere.titoloMessaggio`.
9. La pillola «Perché adesso» usa l'accento al 10%, `Colore.selezioneVoce` è al 13%: riusarlo o creare un colore nuovo?
10. Il compleanno tondo con la pensione (Laura, 50 anni) non è un `TipoOccasione` esistente (`pensioneVicina` è diverso): serve un tipo nuovo `compleannoTondo` in `MotoreMessaggi`, oppure in `TipoOccasione`?
11. Possibile doppione con il nastro Da fare e la mossa del giorno (`MotoreDaFare`, `MotoreMossaDelGiorno`), che mostrano già consensi, riesami e occasioni: decidere se Messaggi è una vista di quelle stesse voci o un elenco a parte.
12. Numerazione delle istantanee 490-498: da coordinare con le altre parti (vedi §0.5).
13. L'archivio passa alla versione 26 con `DatiPrisma.messaggi` e `Impostazioni.messaggi`: va coordinato con le altre parti di Orizzonte (vedi §0.5).

### 15.7 Dubbi del §6 — Posizioni › La prova del fuoco

*dalla sezione «Dubbi» della bozza*

1. **Valori storici diversi**: il template scrive «Azioni −45%» per il 2008 e «−30% in un mese» per il 2020; `CrisiStoriche` usa −37% (MSCI World in euro, anno solare) e −33% (dal massimo al minimo). Proposta: tenere quelli di Prisma, già documentati, e comporre la frase dai dati.
2. **2020 «poi la ripresa»**: il template alza la copertura «dopo» dell'8% per la ripresa. Proposta: mostrare il punto più basso e scrivere sotto il recupero («in meno di un anno»). In alternativa una seconda barra «dopo la ripresa».
3. **Il 2022** è già nel motore (inflazione e tassi insieme): aggiungerlo come sesta chip «Come nel 2022»?
4. **Quali posizioni contano per l'obiettivo**: solo quelle collegate (come `MotoreObiettivo`), oppure tutto il patrimonio finanziario del cliente quando l'obiettivo non ne ha? La prima è coerente col piano, ma con i dati di oggi lascia quasi tutte le barre ferme.
5. **Rendimenti dopo lo shock**: proposta prudente, rendimenti futuri invariati. Con i tassi in rialzo le obbligazioni poi rendono di più e su orizzonti lunghi recuperano: va considerato (rendimento della parte obbligazionaria +d punti dopo lo shock)?
6. **Mercati solo sulle azioni**: il cursore tocca solo la quota azionaria, come il template. La prova di resistenza invece usa la tabella per SRI. Le due cifre per lo stesso cliente saranno diverse: va bene, o la chip «Mercati» deve usare la tabella SRI riscalata?
7. **Copertura limitata al 100%**: un obiettivo al 130% che scende al 105% non mostra calo. È corretto (resta raggiunto), ma si perde il «margine». Mostrare oltre 100?
8. **Chi entra nella lista**: tutti i clienti o solo quelli con obiettivi? Proposta: tutti, quelli senza obiettivi in fondo.
9. **Un obiettivo per riga**: la riga mostra quello che scende di più. Mostrare anche «+ N altri obiettivi»?
10. **Testo delle chip**: «Mercati −25%» resta fisso anche con il cursore a −40% (come il template), oppure segue il valore?
11. **Posizione della lista con gli storici**: il template lascia un vuoto (lista a `top` fisso); proposta: la lista segue il titolo.
12. **Durate del conteggio**: 0,6/0,7 s del template o `NumeroCambio` (0,9 s) già nel tema?
13. **Modalità cliente**: togliere il segmento «Prova del fuoco» o mostrarla per il solo cliente (che però ha già la «Prova di resistenza» nel dossier)?
14. **Clic sulla riga**: nel template non fa nulla; proposta: apre il dossier sulla scheda Obiettivi.
15. **«Chiama» sul Mac**: aprire `tel:` (Continuity con l'iPhone) o solo mostrare il numero, come il template?
16. **Accantonato dell'obiettivo**: oggi cresce al rendimento dell'obiettivo; nello scenario resta fermo (lo trattiamo come liquidità). Va bene?
17. **Canale**: la lista non distingue Alleanza e indipendente. Serve un filtro per canale (come nella colonna di Posizioni) o l'etichetta del canale sulle righe?

### 15.8 Dubbi del §7 — Clienti › Dossier › La linea della vita

*dalla sezione «8. Dubbi» della bozza (era il §8 della parte)*

1. **Fine a 90 anni**: fissa per tutti (come il template) o regolabile per cliente (`etaPianificazione`)? Per Sofia, 61 anni, 90 lascia 29 anni; per un cliente di 85 anni la linea è quasi vuota.
2. **Trascinare salva?** Il template non salva nulla. Salvare subito nel dossier (con Annulla) o tenere una prova «che succede se» con «Salva nel dossier»? Spostare la pensione cambia anche l'Analisi 360 e la stima INPS.
3. **Obiettivi come eventi**: gli obiettivi con scadenza diventano gettoni (la «Casa» di Giulia è l'obiettivo «Anticipo casa»)? Se sì, trascinarne uno cambia la scadenza dell'obiettivo?
4. **Importi negli eventi**: l'utente vuole indicare l'importo di ogni evento (matrimonio −15.000…) o preferisce importi suggeriti per tipo di evento? Per la regola «mai inventare», la proposta è: nessun importo suggerito, l'evento senza cifra resta grigio.
5. **Aggiungere e modificare eventi dalla scheda** (pulsante «＋ Evento», dettaglio del gettone) o solo da Bisogni?
6. **Patrimonio di partenza**: con la casa di abitazione e gli altri immobili (che non si spendono) o solo il patrimonio finanziario? Il template usa il patrimonio netto (204.050 € di Giulia).
7. **Larghezza del grafico**: il template disegna a 1040 in una card larga 1018 di contenuto (sborda) e trascina sulla larghezza di `#vLinea` (1016), quindi gettone e riga non coincidono di qualche punto. In Prisma una sola larghezza per grafico, linea e trascinamento. Va bene tenere invece lo sbordo fino al bordo della card?
8. **Area senza animazione**: nel template l'area è piena subito mentre la linea si disegna in 1,5 s. Seguire il template o far comparire l'area con la dissolvenza di «Nel tempo»?
9. **Valori predefiniti di `IpotesiPrevidenza`** (2.200 di reddito desiderato, 1.400 di pensione pubblica): oggi esistono come predefiniti; qui vanno trattati come «non indicati» finché l'Analisi 360 non è confermata (come fa già `MotoreCompletezza`)?
10. **Euro di oggi o nominali**: proposta in euro di oggi (rendimento reale), coerente con la previdenza; il template usa un 2,5% che pare nominale.
11. **Famiglia**: la linea è della persona o del nucleo (redditi e pensione del convivente, eventi dei figli)? Il template è solo del cliente.
12. **Gettoni sovrapposti**: tre file fisse (indice % 3) possono accavallare gettoni vicini (Matrimonio 38 e Casa 40 sono entrambi spinti a 70). Va bene una disposizione automatica che eviti le sovrapposizioni?
13. **Numero dell'istantanea** e versione 26: da coordinare con le altre parti (la 58x è proposta sia dal copilota sia da Inquadra).

### 15.9 Dubbi del §8 — Incontri › Il copilota dell'incontro

*dalla sezione «8. Dubbi da chiarire» della bozza (era il §8 della parte)*

1. **Chi parla**: un solo microfono (senza etichette o con l'etichetta a mano) o due dispositivi (Mac + iPad davanti al cliente)? Il template mostra «Denis» e «Giulia» come se lo sapesse da solo.
2. **Dove sta il copilota** dentro Incontri: sostituisce il passo «Ascolto» (le tre domande scritte) o gli si affianca con un segmento «Copilota · Appunti»? E la colonna «Oggi» del template prende il posto della scelta del cliente attivo?
3. **Pulsante della scheda**: scrive subito nel dossier (come fa intendere «Aggiungi a Posizioni») o segna solo la scelta, e si scrive tutto al verbale (proposta)?
4. **Colore della polizza di un'altra compagnia**: `#B06E12` è il cuoio del canale indipendente. Una polizza di un'altra compagnia non è del canale indipendente: tenere il colore (rischio di confusione con il canale) o sceglierne un altro? E con quale `Canale` si salva la `Posizione`, visto che oggi esistono solo Alleanza e indipendente?
5. **Profilo per obiettivo**: è un'annotazione o deve incidere sui calcoli e sull'adeguatezza? Non deve cambiare il profilo del questionario.
6. **«entro venerdì»** compare nel verbale ma non nel dialogo: da dove viene la scadenza dell'attività? Una regola fissa (es. entro 3 giorni lavorativi) o la sceglie l'utente nel verbale?
7. **Pulsante «■ Termina» nello scuro**: `#14202B` sparisce sulla scheda scura; quale colore?
8. **Conservazione della trascrizione** (privacy, GDPR): mai, solo fino al verbale, o per sempre nel dossier?
9. **Alleanza**: ci sono regole della compagnia sull'ascolto e la trascrizione dei colloqui con i suoi clienti?
10. **Riavvio**: nel template, riavviando il copilota le righe e le schede vecchie restano e le schede si duplicano. In Prisma: un secondo ascolto dello stesso incontro continua quello di prima (proposta) o ne apre uno nuovo?
11. **Durata massima e memoria**: per incontri lunghi (oltre 90 minuti) sul Mac con 8 GB, va bene fermarsi da soli a 2 ore con un avviso?
12. **Goccia** sull'acqua quando nasce una scheda: la finestra di Incontri copre l'acqua; la goccia si vede solo ai bordi. Tenerla?

### 15.10 Dubbi del §9 — Inquadra e capisci

*dalla sezione «Dubbi» della bozza*

1. **Il telefono disegnato sul Mac.** Con la Fotocamera Continuity l'iPhone vero mostra la schermata di Apple. Va
   bene che il telefono disegnato in Prisma mostri l'immagine arrivata, con la linea e le righe illuminate? Oppure si
   toglie il telefono e si mostra solo il foglio?
2. **Strada A o B.** Si parte dalla Fotocamera Continuity (niente app sull'iPhone, ma niente evidenziazione dal vivo)
   e si fa l'app iPhone dopo? L'iPhone oggi ha una copia in sola lettura: mandare foto al Mac è accettabile?
3. **Dopo «Confronta»** il template toglie «Aggiungi a Posizioni». In Prisma si propone di lasciare i due pulsanti
   sotto la tabella («Aggiungi a Posizioni» e «Chiudi»). Da confermare.
4. **Capitale della temporanea.** 160.000 € viene dal fabbisogno della famiglia? La nota dice «a parità di spesa»,
   ma 190 € non è la stessa spesa di 1.080 €. Scegliere: stessa spesa (capitale = 1.080 / tariffa × 1.000) o
   fabbisogno (spesa diversa), e correggere la nota di conseguenza.
5. **«canale: altra compagnia».** In Prisma i canali sono solo Alleanza e indipendente. Una polizza di un'altra
   compagnia del cliente diventa canale indipendente con l'emittente letto? Il toast dovrebbe allora dire «canale:
   indipendente, Compagnia Esempio S.p.A.».
6. **Conferma.** «Aggiungi» conferma in blocco i dati letti. Va scritto nella scheda («I dati letti entrano come
   confermati»), o si apre il dettaglio del documento per controllarli uno per uno?
7. **Il documento si tiene?** La foto della polizza va salvata tra i Documenti del cliente (consigliato: è la fonte
   dei dati) o si butta dopo la lettura?
8. **Linea della scansione.** In `00-comune.md` è scritto che la linea «si ferma in fondo». Con 2 ripetizioni
   `alternate` e `forwards` torna invece in alto (top 110), come si vede nelle schermate: correggere la parte comune.
9. **Due verdi.** Il foglio usa #34C759 (verde di sistema), i ✓ della scheda #2FA35A (`--green`). Tenere le due
   tinte come nel template?
10. **Numerazione delle istantanee** 580-589: da allineare con le parti 08 (copilota) e 10 (prova del fuoco).
11. **iPad.** Anche l'iPad ha la fotocamera: lo scanner va offerto anche lì (strada B), o solo iPhone come dice il
    titolo?

### 15.11 Dubbi del §10 — Analisi 360 › Rispetto alle famiglie come la sua

*dubbi raccolti dalla bozza*

1. Le tavole pubblicate dalla Banca d'Italia di solito danno medie e mediane per una caratteristica alla volta, senza incroci età × reddito con i quantili. Per avere i quantili per cella servono i microdati. Prisma deve leggerli e calcolare i quantili pesati in locale (con un comando tipo `--prepara-famiglie`), oppure il file aggregato lo prepara l'utente fuori dall'app?
2. Il template parla di «capofamiglia», mentre le ultime edizioni dell'indagine usano il «principale percettore di reddito» o la «persona di riferimento». Quale termine e quale definizione usiamo?
3. Il sottotitolo del template ricava la classe d'età dalle decine dell'età del cliente (37 → 30-39). Se le classi del file sono diverse, il testo va preso dalla classe della tabella: va bene?
4. Per protezione e previdenza molte famiglie stanno a zero, quindi un percentile è poco significativo. La regola proposta (punto medio della massa a zero) e una frase dedicata, tipo «come il X% delle famiglie che non ne ha», vanno confermate.
5. La frase «è più protetta del» è fissa al femminile anche per i clienti uomini: si declina con `TestiAree360.femminile`, oppure diventa «la sua famiglia è più protetta del»?
6. La frase principale usa sempre la voce Risparmio, anche quando è la voce più debole. Va bene, o deve mostrare la voce più rilevante?
7. Il risparmio dell'indagine è annuo (reddito meno consumi) ma l'etichetta dice «ogni mese». Serve un campo nuovo, il risparmio dichiarato (`ProfiloInvestitore.risparmioAnnuo`), oppure lo ricaviamo dalle spese? I versamenti dei piani in essere non sono la stessa misura.
8. Il patrimonio di Prisma contiene solo le posizioni registrate: le attività tenute altrove abbassano il percentile. Serve un campo «altre attività finanziarie» o una nota?
9. Gli euro dell'indagine sono quelli dell'anno di rilevazione: rivalutiamo i redditi del cliente all'anno dell'indagine con l'inflazione FOI già presente in Riferimenti, oppure confrontiamo i valori nominali?
10. Nel template «Riduci movimento» non ferma i segnaposti (`montaFam` ignora `ridotto`). Nell'app proponiamo di fermarli, come dice CLAUDE.md.
11. Il clic sulle card che apre l'area collegata non è nel template: è un'aggiunta da confermare.
12. Le cifre di prova per i clienti oltre i 5 del template (i 30 fittizi) non esistono: proponiamo valori fissi ricavati dall'id, sempre marcati «dati di prova».

### 15.12 Dubbi del §11 — Studio › Esame OCF

*dalla sezione «Dubbi» della bozza*

1. **Materie.** I sei nomi del template vanno bene, o vanno presi dal bando OCF / dal manuale? Le materie cambiano tra la prova per consulenti abilitati all'offerta fuori sede e quella per consulenti autonomi o società di consulenza: quale esame deve sostenere?
2. **Percentuale di una materia**: ultima risposta di ogni domanda vista (proposta), tutte le risposte, o solo gli ultimi 30 giorni?
3. **Numero al centro**: media semplice delle materie (come il template) o pesata sul numero di domande dell'esame vero?
4. **Ripasso 1-3-7**: dopo il 7 la domanda è imparata ed esce (proposta), oppure torna ancora (per esempio dopo 30 giorni, o pochi giorni prima dell'esame)? Una giusta al primo colpo deve tornare almeno una volta?
5. Il ripasso deve **stringersi** quando l'esame è vicino (per esempio, nell'ultima settimana tutte le sbagliate tornano ogni giorno)?
6. **«Prossima domanda» senza rispondere**: la domanda conta come saltata (proposta) o come sbagliata?
7. Il **clic sulla materia** per allenarsi su una sola è voluto? Nel template non c'è.
8. **Simulatore dal caso vero**: con quale cliente si apre, se la domanda non riguarda un cliente? Proposta: il cliente attivo, ipotesi non salvata.
9. Le **percentuali delle materie** si contano come le altre cifre del tema (proposta) o restano ferme come nel template?
10. Lo **spazio vuoto** in fondo alla card 1: ci va la data dell'esame con il conto alla rovescia e il ritmo della settimana (domande fatte al giorno), oppure resta vuoto?
11. **Promemoria** del ripasso con le notifiche del Mac («14 domande da ripassare oggi»): sì o no? E la data dell'esame va anche in Agenda?
12. **Diritti sulle domande**: le domande del manuale restano solo nell'archivio locale e nei backup. Va bene che finiscano nei backup (iCloud Drive o disco esterno)?
13. **Esame OCF sotto Studio** o come app a sé? È uno strumento personale del consulente, non dei clienti: in modalità cliente deve restare nascosto (proposta: sì).

### 15.13 Dubbi del §12 — Mercato — «Prisma conosce il mercato»

*dalla sezione «Dubbi» della bozza*

1. **Rete.** CLAUDE.md dice «tutto resta in locale sul Mac: niente server, niente cloud». Mercato sarebbe la prima connessione a internet di Prisma. Proposta: scelta esplicita in Impostazioni, spenta per impostazione predefinita, con richieste solo verso fonti pubbliche e senza nessun dato dei clienti. Va bene?
2. **Frase della fascia.** Il template dice «Dal Mac escono solo gli ISIN». Un elenco di ISIN però descrive i portafogli dei clienti, e comunque per gli ISIN non c'è una fonte libera. Proposta: gli ISIN non escono mai. Il testo diventa «Dal Mac escono solo le richieste di dati pubblici (BCE, Eurostat, ISTAT): nessun dato dei clienti lascia Prisma.» oppure, con la rete spenta, «Nessun dato esce dal Mac».
3. **Frequenza.** Le fonti libere danno i tassi e il BTP a 10 anni come medie **mensili** (BCE) e l'inflazione mensile. Una variazione «oggi» c'è solo per ciò che arriva dai file. Le tessere devono mostrare la variazione sull'ultimo dato, qualunque sia il periodo, e dire il periodo («a ottobre»)?
4. **Inflazione.** Nella tessera ci va l'HICP (Eurostat), il NIC o il FOI (ISTAT)? I Riferimenti oggi usano il FOI annuo per il TFR. Proposta: FOI anche qui, per coerenza.
5. **Tono e segno.** Va bene la regola «il colore dice se è buono per i clienti» (BTP in salita = rosso, Euribor in discesa = verde)? Per chi ha liquidità o un mutuo l'Euribor in discesa ha effetti opposti.
6. **Numeri.** Le cifre della striscia si contano fino al valore (regola del tema Apple) o restano ferme come nel template?
7. **Avatar.** Nel template quelli di «Chi è toccato» non si vedono (difetto del doppio `style`). Confermare il disegno voluto: 30, sovrapposti di 8, bordo 2. Con più di 3 clienti, «+N»?
8. **«Prepara un messaggio».** Con più clienti toccati (6 nella prima scheda) apre un messaggio per ognuno, una scelta del cliente o un messaggio solo al cliente più toccato? Il template apre sempre il messaggio di Marco sull'Infortuni, che non c'entra.
9. **Posto del risultato ISIN.** Nel template compare in fondo al riquadro «Avvisi», che ha `overflow: hidden`: con più di 4 avvisi verrebbe tagliato. Proposta: un riquadro che nasce dal campo di ricerca (dettaglio del tema), oppure un posto fisso sopra gli avvisi.
10. **Clic sulle tessere.** Nel template il puntatore è la mano ma il clic non fa nulla. Si aggiunge il dettaglio con la serie lunga e la fonte?
11. **Indici e Riferimenti.** Le serie degli indici azionari scaricate o importate in Mercato devono alimentare da sole i valori annui di Impostazioni › Riferimenti (`IndiceRiferimento`), o solo proporli al consulente, che li conferma?
12. **Avvisi e notifiche.** Un avviso scattato va anche nella campanella (e nelle notifiche del Mac fuori da Prisma) o resta solo in Mercato?
13. **Canale.** Nei riquadri il template non distingue Alleanza e indipendente. Nelle schede di «Chi è toccato» e negli avvisi va mostrata l'etichetta del canale della posizione (regola «canale sempre riconoscibile»)?
14. **iPhone e iPad.** Mercato va anche sul telefono, in sola lettura con i dati del Mac? Va nel dock mobile?
15. **Pallino che pulsa.** Pulsa senza fine finché l'avviso è scattato. Va bene, o si ferma dopo che il consulente ha aperto l'avviso (come le notifiche viste)?

### 15.14 Dubbi del §13 — Impostazioni › iPhone e iPad — «Prisma ovunque»

*dubbi raccolti dalla bozza*

1. Fattibilità: l'app iOS si installa con AltStore/Sideloadly e un ID Apple gratuito, che non concede il contenitore iCloud né CloudKit. Proposta: file in una cartella di iCloud Drive scelta dall'utente sul dispositivo, con un segnalibro salvato. Va provato su un iPhone vero che il segnalibro resti valido tra un avvio e l'altro e dopo la reinstallazione settimanale di AltStore.
2. Portachiavi su iOS con la firma di AltStore: il codice del Mac evita il portachiavi «data protection» per l'errore −34018. Va verificato che sull'iPhone la password si possa salvare; altrimenti va riscritta a ogni apertura.
3. Chiave: password dei backup (proposta) oppure codice di abbinamento del ponte di Ruby? Il template dice solo «la tua chiave».
4. Ordine della barra laterale: il template mette «iPhone e iPad» subito dopo Aspetto, ma Prisma ha molte più pagine in gruppi. Proposta: vicino ad «Archivio e backup».
5. Nel template la scritta «solo un file cifrato» sotto la nuvola cade fuori dal disegno (y=164 su 150) e non si vede. Proposta: mostrarla (disegno alto 170). Va confermato.
6. Il telefono d'esempio ha lo schermo sempre chiaro anche nell'aspetto scuro: va tenuto così o deve seguire lo scuro? E deve mostrare dati veri (il cliente dell'ultima modifica in attesa) o restare un'illustrazione?
7. Quando si vede la pillola «Senza Mac · copia cifrata» sull'iPhone? Proposta: solo quando il Mac non risponde al ponte; con il Mac raggiungibile si lavora comunque sulla copia, ma senza pillola.
8. Regola dei conflitti: proposta che nulla si sovrascriva in silenzio e che ogni conflitto finisca in «Modifiche in attesa» da scegliere a mano. Si può fare più semplice (vince l'ultima modifica)?
9. Il pulsante «Vedi» del template non fa nulla: il foglio con l'elenco delle modifiche e la scelta sui conflitti è una proposta.
10. Il ritmo dei pallini (2,4 s, e 0,8 s durante la sincronizzazione) nel template ignora «Riduci movimento» e salta di posizione quando cambia la durata. Proposta: pallini fermi con Riduci movimento e un cambio di velocità senza salti.
11. La numerazione delle istantanee 560-566 (Mac) e 60-63 (iOS) va verificata con gli altri giri (vedi §0.5: le 60-63 esistono già).
12. iCloud Drive non sincronizza ad app chiusa su iOS: la sincronizzazione avviene all'apertura, al ritorno in primo piano, prima di andare in background e con il pulsante. Va detto all'utente.
