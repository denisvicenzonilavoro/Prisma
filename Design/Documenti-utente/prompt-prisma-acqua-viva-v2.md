Prepariamo la prossima versione di Prisma, che chiamiamo «Acqua viva». Contiene due cose:
1. **Una nuova identità grafica e di movimento per tutta la piattaforma**, in stile Apple, presa dal template navigabile `Design/template-apple.html`.
2. **Le novità di funzione**: l'acqua che risponde, il portafoglio, la macchina del tempo, la famiglia, la mossa del giorno, «Un anno insieme», gli scenari «E se…?» con Eve e il tavolo con l'iPad.

Prima di cominciare:
- Rileggi CLAUDE.md. Le regole restano vincolanti: niente Xcode, build solo su GitHub Actions con macos-15-intel, tutto in locale, valori grafici solo in `Sources/Prisma/DesignSystem/`, Mac M1 con 8 GB, italiano ovunque.
- Apri `Design/template-apple.html` in un browser headless (Playwright c'è) e percorrilo tutto: blocco, scrivania, ogni app del dock, i dettagli che si espandono, i cursori, Eve, la presentazione, chiaro e scuro. Guarda il codice per tempi, curve e misure: è la specifica. Se il file non è nel repository, fermati e chiedimelo.

## La nuova grafica: cosa cambia e cosa resta
Resta tutto ciò che è già identità di Prisma: l'unica finestra con barra superiore, scrivania, dock e finestre interne in vetro; l'acqua animata in Metal; il logo; i colori dei canali (Alleanza blu #2563EB, indipendente cuoio #B06E12); i PDF su carta bianca; chiaro, scuro e automatico.

Cambia il linguaggio: meno decorazione, più gerarchia e soprattutto **movimento che spiega**. Le regole, ricavate dal template:

- **Numeri che si contano.** Ogni cifra importante, quando compare o cambia, si conta dal valore vecchio al nuovo: circa 1,1 s, ease-out quartica, cifre tabellari. Su macOS 14 e successivi puoi usare `.contentTransition(.numericText())`, con un ripiego animabile per macOS 13.
- **Entrata a cascata.** All'apertura di una schermata gli elementi arrivano uno dopo l'altro: opacità da 0 a 1, spostamento verticale di 18 pt, sfocatura da 6 a 0, scala da 0,985 a 1, 720 ms con curva (0.22, 1, 0.36, 1), 48 ms tra un elemento e il successivo.
- **Anelli in stile Fitness.** Estremità arrotondate, traccia al 15% del colore, riempimento in 1,4 s. Servono per completezza, obiettivi, aree dell'Analisi 360 e stato del lavoro.
- **Grafici che si disegnano.** La linea si traccia in circa 1,5 s, poi l'area sotto compare in dissolvenza. Passando da «In essere» a «Con le proposte», il grafico si allarga e mostra la stima tratteggiata con la sua fascia di incertezza.
- **Schede che si inclinano.** Al passaggio del puntatore (`onContinuousHover`) la scheda ruota verso il cursore, al massimo di 10°, si alza di 5 pt e cresce del 2%. Un riflesso di luce radiale segue il puntatore. All'uscita torna a posto con una molla. Su iPhone e iPad lo stesso effetto si ottiene alla pressione.
- **Il dettaglio nasce dalla scheda.** Toccando una scheda, la scheda stessa si espande fino al pannello di dettaglio (`matchedGeometryEffect` con molla) e il resto si sfoca dietro. Il contenuto compare dopo circa 160 ms. Alla chiusura il pannello torna nella scheda.
- **Controlli segmentati** con la pillola che scivola a molla sotto la voce scelta.
- **Completamento.** «Segna come fatto» disegna una spunta verde. Poi la scheda si chiude, le altre scorrono a riempire il posto e l'anello corrispondente avanza e si illumina per un attimo.
- **«Ti preparo».** I report o i punti da preparare si spuntano uno alla volta, a circa 360 ms l'uno dall'altro.
- **Finestre e dock.** Le app si aprono uscendo dalla loro icona del dock e vi rientrano alla chiusura. Le icone del dock si ingrandiscono al passaggio del mouse, come su macOS.
- **Blocco.** Ora grande e sottile e «Tocca per entrare». All'ingresso cade una goccia sull'acqua e la scrivania compare a cascata.
- **Riduci movimento.** Animazioni brevissime, niente inclinazioni né cascate, acqua più calma.
- **Istantanee.** In `--istantanee` ogni schermata va disegnata nello stato finale, con numeri completi, anelli pieni e linee tracciate. Niente fotogrammi a metà animazione.

Misure, raggi, ombre, colori chiari e scuri, dimensioni dei caratteri e tempi vanno centralizzati in DesignSystem come «tema Apple». Lascia `Design/tema-liquid-glass.html` come storico. Aggiorna la sezione «Grafica» di CLAUDE.md: la fonte ufficiale per struttura, componenti e movimento diventa `Design/template-apple.html`, mentre vetro, acqua, logo e canali restano come sono.

Prestazioni sul M1 con 8 GB:
- Sfocature solo dove servono, mai annidate.
- L'inclinazione è attiva solo sulla scheda sotto il puntatore.
- Niente timer per le animazioni sul thread principale oltre a quelle di SwiftUI.
- Misura la fluidità con la prova già presente: non deve peggiorare rispetto a oggi.

## Come lavorare
- Crea il branch di versione `versione-acqua-viva` da main. Ogni giro è un branch a parte con una pull request verso `versione-acqua-viva`, unita solo con la build verde.
- Main non si tocca fino alla fine: quando tutti i giri sono uniti e verdi, apri l'ultima pull request da `versione-acqua-viva` verso main e uniscila. Così la release «ultima» si aggiorna una volta sola e io installo una volta sola.
- Dopo ogni push controlla la build (`gh run list`, `gh run view --log-failed`) e correggi finché non è verde.
- A ogni giro guarda le istantanee sul branch `anteprime` e confrontale con il template. Aggiungi le istantanee nuove, in chiaro e in scuro, e aggiorna la pagina online delle anteprime.
- Nessuna dipendenza esterna. Niente internet, niente servizi esterni.
- Se tocchi l'archivio (dati nuovi nel dossier), i vecchi archivi e i vecchi backup devono aprirsi lo stesso, e `Prisma --prova-backup` va aggiornata.
- Prisma resta un'app di analisi: ogni novità deve far capire meglio clienti e posizioni.
- Se una scelta grafica non è coperta dal template, fai la soluzione più sobria e coerente e scrivimela alla fine del giro.

## Giro 1 — Le fondamenta del nuovo stile
- Il tema Apple in DesignSystem: colori chiari e scuri del template, superfici, schede, ombre, raggi e tipografia (SF Pro Display per titoli e cifre).
- Questi componenti riutilizzabili:
  - numero che si conta;
  - entrata a cascata;
  - anello singolo e anelli concentrici;
  - grafico a linea che si disegna, con area e fascia di stima;
  - scheda inclinabile con riflesso;
  - dettaglio che nasce dalla scheda;
  - controllo segmentato a pillola;
  - spunta che si disegna;
  - lista «Ti preparo»;
  - interruttore e cursore nello stile del template.
- Ognuno rispetta «Riduci movimento» e le istantanee.
- Aggiorna CLAUDE.md come scritto sopra.

## Giro 2 — Shell e acqua che risponde
- **Blocco, barra, dock, finestre e notifiche** come nel template: le finestre escono dall'icona, le icone del dock si ingrandiscono, le notifiche scendono dalla campanella a molla, una dopo l'altra.
- **Scrivania** con i riquadri del template: la mossa del giorno, l'agenda di oggi, il portafoglio con i tre anelli, Eve con i suggerimenti, le cose da fare, le scadenze.
- **La mossa del giorno.** È il cliente su cui un'ora di lavoro vale di più oggi, con il motivo in una frase. Incrocia occasioni, seguito delle proposte, scadenze, riesami e completezza, con i pesi in un solo punto e spiegati. «Preparami l'incontro» compone il fascicolo con i report adatti. Se non c'è niente di urgente lo dice con calma.
- **L'acqua risponde**, con lo stesso shader e la stessa fisica di oggi:
  - un clic o un tocco su una zona libera fa cadere una goccia;
  - una notifica nuova arriva come una goccia sulla campanella;
  - quando Eve parla, l'acqua vibra piano intorno alla sfera;
  - allo sblocco una goccia apre la scrivania.

  In Impostazioni c'è l'interruttore «L'acqua della scrivania», acceso di base. Stessa resa su Mac, iPhone e iPad.

## Giro 3 — Posizioni e Clienti
**Posizioni: il portafoglio**, come nel template.
- Il totale che si conta, il controllo «In essere / Con le proposte» con il grafico che si allarga sulla stima, la barra dei canali.
- I tre anelli dello stato del lavoro: clienti in regola, riesami dell'anno, proposte concluse.
- Il nastro «Da fare, in ordine di tempo» con i gruppi Oggi, Questa settimana, Questo mese, Più avanti. Le schede si inclinano e si espandono nel dettaglio con «Preparami l'incontro», «Segna come fatto» e «Apri il dossier». Completando, l'anello giusto avanza.
- Tutti i dati vengono dai motori esistenti: attenzioni, occasioni, seguito delle proposte, conformità, riesami.

**Clienti: il dossier**, come nel template.
- La rubrica con la ricerca. Cambiando cliente, il contenuto scorre e le cifre si ricontano.
- Le quattro cifre in alto e le schede del dossier, con il controllo a pillola. Le schede che già esistono (Bisogni, Documenti, In regola, Riesami…) restano e passano al nuovo stile.
- **Panoramica:** l'anello della completezza con le voci da completare, «Da ricordare» e il prossimo incontro.
- **Obiettivi:** un anello per obiettivo. Toccandolo, si espande con il cursore del versamento e la data di arrivo ricalcolata dal vivo, e «Salva nel dossier».
- **Nel tempo**, che diventa la macchina del tempo: il grafico del template (tre anni indietro, due avanti, con e senza proposte) più un cursore. A sinistra mostra patrimonio, posizioni e note ai riesami passati, presi dalle fotografie dei riesami. A destra mostra il ventaglio Monte Carlo, sempre etichettato come stima. Funziona anche in modalità cliente e in presentazione.
- **Famiglia:** le schede delle persone con lo stato della protezione e le scoperture accese (chi non è protetto, beneficiari da aggiornare, successione da sistemare). Ogni scopertura porta alla scheda dove si risolve. Usa i motori di protezione della famiglia e di passaggio generazionale.

## Giro 4 — Analisi 360 e Agenda
**Analisi 360**, come nel template.
- La scelta del cliente con le pillole e le quattro aree con l'anello: previdenza, protezione, investimenti, risparmio e liquidità.
- **Previdenza e Protezione** si espandono in un simulatore. Il cursore aggiorna dal vivo l'anello, la rendita, il capitale, il risparmio fiscale o il premio stimato. Le cifre vengono dai motori di previdenza, fiscale e di protezione, non dalle formule semplificate del template. Le ipotesi vanno sempre scritte sotto.
- **Investimenti e Liquidità** si espandono nel dettaglio: barra di composizione che si riempie, mesi di spese da parte.
- «Salva come proposta» e «Chiedi a Eve di spiegarlo».
- Simulazioni e Confronti, ospitati in Analisi 360, passano allo stesso stile.

**Agenda**, come nel template.
- Il mese a sinistra con i puntini, la settimana a pillola, la giornata con gli impegni che entrano da destra e la linea rossa dell'ora.
- Toccando un impegno si apre la traccia con «Punti da toccare», «Preparami l'incontro», «Apri il dossier» e «Presenta al cliente».
- Attività e riesami restano dove sono, nel nuovo stile.

## Giro 5 — Prospetti, Un anno insieme, Impostazioni e le altre app
**Prospetti**, come nel template.
- L'elenco dei report del cliente e l'anteprima su carta che cambia scorrendo.
- «Presenta all'incontro» a tutto schermo, con le pagine che scorrono con le frecce. «Salva PDF» e il fascicolo restano come oggi.

**Un anno insieme**, il nuovo report per il cliente, su carta bianca come tutti i PDF.
- Contenuto: cosa è successo nell'anno, gli obiettivi avvicinati, la protezione, i versamenti, gli eventi di mercato attraversati (le crisi storiche dove serve) e cosa ci aspetta. La pagina di riferimento è nel template.
- Il canale è sempre riconoscibile. Il tono è attento alla conformità: niente promesse, i rendimenti passati presentati come tali, con le avvertenze del caso.
- Si apre da Prospetti, dal dossier e dal fascicolo dell'incontro.

**Impostazioni** come nel template:
- Aspetto (chiaro, scuro, automatico), l'acqua, «Riduci movimento», la dimensione del testo.
- Archivio e backup con l'anello che si riempie durante il backup.
- Eve e Profilo.

**Le altre app**: Incontri, Prodotti, Note, Ricerca (anche Spotlight), Documenti e Attività. Non sono nel template, ma vanno portate nello stesso stile, con gli stessi componenti e movimenti. Nessuna resta nel vecchio aspetto.

## Giro 6 — Eve e gli scenari «E se…?»
- **Eve nel nuovo stile**, come nel template: la sfera grande che respira, lo stato di Qwen, i suggerimenti, la risposta che compare parola per parola e le schede dei calcoli che entrano dopo il testo. Mini Eve e la sfera nella barra seguono lo stesso linguaggio.
- **«E se…?»** Chiedo uno scenario su un cliente, per esempio: «e se Marco va in pensione a 63 anni e smette di versare?».
  - Qwen (lo stesso nucleo e lo stesso `FornitoreModello` di oggi) riconosce che è uno scenario e ne estrae i parametri in uno schema fisso. Se manca qualcosa, Eve lo chiede.
  - I numeri li calcolano i motori di Prisma, mai Qwen. Compare una scheda prima/dopo e Eve la racconta usando solo quelle cifre.
  - Lo scenario si salva nel dossier o si apre in Simulazioni.
  - Istruzioni in `Eve/Istruzioni/scenari.md`, con prove nel workflow: frasi di esempio e parametri attesi.
  - Funziona anche da mini Eve e dall'iPhone attraverso il ponte. Se Qwen non è pronto, Eve lo dice.

## Giro 7 — iPhone, iPad e il tavolo
**iPhone e iPad** adottano lo stesso tema e gli stessi componenti. Sull'iPhone resta la gerarchia approvata in `Design/iphone.html`.

**Il tavolo con l'iPad.** Sul Mac guido io, mentre l'iPad davanti al cliente mostra solo ciò che scelgo.
- Collegamento in rete locale con la stessa cifratura e lo stesso codice di abbinamento del ponte di Eve. Mai internet.
- Sull'iPad è una modalità «Tavolo» a tutto schermo, senza dock né altre app, che si esce solo dal Mac.
- Dal Mac mando una pagina della presentazione, un prospetto, la macchina del tempo o la famiglia. Sul tavolo vanno solo i dati del cliente presente.
- Posso lasciare al cliente un solo cursore con i limiti decisi da me (per esempio il versamento mensile), e i numeri si aggiornano con i motori di Prisma.
- Alla fine il cliente può firmare con il dito o con la Pencil una **presa visione**, che finisce nel PDF e nel dossier con la data e la scritta «Presa visione del documento: non costituisce firma contrattuale». Non chiamarla mai firma elettronica.
- Se la connessione cade, l'iPad mostra una schermata neutra e non lascia dati in vista.
- Aggiungi una prova a circuito chiuso (Mac e iPad simulati nello stesso processo) e alla fine scrivimi cosa devo provare io sui dispositivi veri.

## Alla fine
Quando tutti i giri sono uniti e verdi, apri la pull request verso main con il riepilogo della versione e uniscila quando è verde. Poi scrivimi, senza raccontare i passaggi:
- cosa c'è di nuovo, in poche righe per giro;
- dove ti sei dovuto allontanare dal template e perché;
- le scelte grafiche che hai fatto da solo;
- la lista di cosa devo provare io, soprattutto la fluidità sul mio M1, Eve con Qwen e il tavolo con l'iPad.
