Prepariamo la prossima versione di Prisma, che chiamiamo «Luce». Parte da «Orizzonte», che è già in main, e porta 29 novità in due gruppi:
- **15 davanti al cliente**, per fargli vedere e sentire il suo piano;
- **14 per il mio lavoro**, per togliermi lavoro ripetitivo con lo stesso effetto «wow».

Prisma resta prima di tutto un'app di analisi: ogni novità mostra o usa i numeri dei motori che esistono già, non ne inventa di nuovi.

C'è un terzo obiettivo, che vale quanto le funzioni: **Prisma deve diventare istantaneo**. Voglio lavorare in modo molto più fluido e veloce, con tempi di attesa quasi zero: ogni tocco risponde subito, ogni app si apre già piena, Eve comincia a rispondere prima che io me ne accorga. Per questo c'è un giro zero, prima di tutte le funzioni, e la sezione «Velocità» vale per ogni giro.

**Davanti al cliente**
1. **La Sala:** l'app che raccoglie le esperienze da vivere con il cliente.
2. **Il Prisma del cliente:** la sua app personale, in un file.
3. **Il prisma di luce:** il patrimonio che si scompone in raggi.
4. **La lettera dal futuro:** il cliente che scrive a sé stesso a 67 anni.
5. **Il film del piano:** un minuto da mandare dopo l'incontro.
6. **Disegna il tuo futuro:** lo scarabocchio che diventa un piano.
7. **Il gioco del rischio:** il profilo vissuto, non dichiarato.
8. **Una giornata della pensione:** il divario che diventa una vita concreta.
9. **Lancia l'anno:** due vite affiancate, con e senza piano.
10. **Quanto vale avermi accanto:** il mio lavoro, in cifre.
11. **La capsula del tempo:** un messaggio sigillato fino al traguardo.
12. **La realtà aumentata:** il patrimonio sul tavolo, dall'iPhone.
13. **Il Territorio:** i clienti come luci, la crescita, il giro di domani.
14. **La tua settimana, il tuo anno:** trenta secondi ogni lunedì.
15. **La palestra della trattativa** (Eve fa il cliente difficile) e **i traguardi festeggiati**.

**Per il mio lavoro**
1. **Stanotte Prisma ha lavorato:** la mattina trovo tutto pronto da approvare.
2. **La proposta si costruisce da sola:** dal bisogno alla proposta in un minuto.
3. **Compila da solo:** i miei moduli si riempiono con i dati del dossier.
4. **Le pratiche dopo la firma:** cosa manca, pratica per pratica.
5. **Il sinistro come una spedizione.**
6. **Trova la pagina:** la risposta dai miei documenti, con la frase evidenziata.
7. **Lo smontaggio:** i costi nascosti cerchiati sul documento del concorrente.
8. **Il radar del portafoglio:** chi si è allontanato dal suo modello.
9. **Le campagne:** lo stesso bisogno, tanti clienti, un tocco.
10. **Nuovo cliente in 10 secondi:** la carta d'identità compila l'anagrafica.
11. **Potenziali clienti e l'albero del passaparola.**
12. **I clienti imprenditori:** l'azienda accanto al titolare.
13. **La nota vocale dall'iPhone.**
14. **Chilometri, spese e scadenze**, per me e per il commercialista.

Prima di cominciare:
- Rileggi CLAUDE.md. Le regole restano vincolanti:
  - niente Xcode, build solo su GitHub Actions con macos-15-intel;
  - tema Apple, valori grafici solo in `Sources/Prisma/DesignSystem/`;
  - Mac M1 con 8 GB, italiano ovunque;
  - dati dei clienti sempre sul Mac, con le sole eccezioni già scritte (Mercato e Prisma ovunque).
- Apri `Design/template-luce.html` in un browser headless (Playwright c'è) e percorrilo tutto.
  - Il pulsante «✦ Novità» porta a ognuna delle 29 funzioni.
  - Guarda il codice per misure, tempi, testi e animazioni: è la specifica.
  - Per tutto ciò che c'era già vale ancora `Design/template-novita.html`.
  - Le cifre del template sono dimostrative. Nell'app i numeri vengono sempre dai motori di Prisma.
- Come per «Orizzonte», ricava dal template una specifica in `Design/template-luce-specifica.md` (misure, tempi, colori, testi, comportamenti) e tienila aggiornata giro per giro.
- Se il template non è nel repository, fermati e chiedimelo.

## Come lavorare
- Crea il branch di versione `versione-luce` da main. Ogni giro è un branch a parte, con una pull request verso `versione-luce` unita solo con la build verde.
- Main non si tocca fino alla fine: quando tutti i giri sono uniti e verdi, apri l'ultima pull request da `versione-luce` verso main. Così io installo una volta sola.
- Dopo ogni push controlla la build (`gh run list`, `gh run view --log-failed`) e correggi finché non è verde.
- A ogni giro:
  - guarda le istantanee sul branch `anteprime` e confrontale con il template;
  - aggiungi le istantanee nuove, in chiaro e in scuro, su Mac e dove serve su iPhone e iPad;
  - aggiorna la pagina online delle anteprime.
- Nessuna dipendenza esterna senza chiedere prima. Tutto con i framework di Apple: Metal, RealityKit/ARKit, AVFoundation, PDFKit, Vision e VisionKit, Speech.
- **Archivio e backup.** Tutto ciò che è nuovo entra nell'archivio e nel backup. I vecchi archivi e i vecchi backup devono aprirsi lo stesso, e `Prisma --prova-backup` va aggiornata a ogni giro che tocca i dati.
- **Prove.** Ogni motore nuovo ha la sua prova di calcolo nel workflow, come quelli che ci sono già (`ProvaCalcoli…`).
- **Il movimento** segue `Tema.Apple.Moto`. Con «Riduci movimento» tutto compare fermo. Nelle istantanee ogni componente è già nello stato finale. Niente Timer.
- **Memoria e calcolo.** Shader, video e realtà aumentata sono le parti più pesanti: misurale sul profilo di un M1 con 8 GB e liberale appena non si vedono più.
- **Non inventare mai regole o dati che non conosci.** Valgono per esempio:
  - pesi dei portafogli modello e tolleranze;
  - rimborsi chilometrici e regole fiscali;
  - probabilità degli eventi della vita;
  - coordinate dei comuni;
  - testi delle condizioni di polizza e campi dei moduli.

  Prepara la struttura, mettimi i campi da compilare e chiedimi. Finché un dato vero manca, l'interfaccia scrive chiaramente «dati di prova».
- **Il repository è pubblico.** Niente dati veri dei clienti. Niente testi copiati da manuali, condizioni o moduli veri: solo fac-simile scritti da te, come nel template. I miei moduli e i miei documenti veri stanno solo nel mio archivio locale.
- **Eve scrive e io approvo.** Niente parte, si firma o entra nel dossier senza la mia conferma: messaggi, campagne, moduli, note, obiettivi.
- **Scelte grafiche fuori dal template.** Se una non è coperta, fai la soluzione più sobria e coerente e scrivimela alla fine del giro.
- **Velocità.** Ogni giro rispetta la sezione «Velocità» qui sotto. Un giro che rende Prisma più lento non è finito, anche con la build verde.

## Velocità: attese quasi zero (vale per tutti i giri)
**Come stiamo oggi.** La prova della fluidità che c'è già (`Prisma --prova-fluidita`, tabella `fluidita.md` sul branch `anteprime`) misura il lavoro del thread principale sul runner Intel. Gli ultimi numeri dicono dove si aspetta:
- un tasto in una nota costa 74 ms con 5 clienti e 105 ms con 200, e fa ricalcolare tutta l'app;
- aprire Posizioni costa 268 ms (433 ms con 200 clienti);
- la prima apertura di quattro app pesanti costa 1,4 s;
- cambiare aspetto chiaro o scuro costa 360-480 ms;
- l'avvio costa 223 ms (468 ms con 200 clienti).

**Il motivo principale** è nel codice: `StatoShell` è un solo oggetto osservabile, con `@Published var dati` che contiene tutto l'archivio, e lo osservano circa 280 viste. Ogni modifica, anche un tasto, rivaluta tutte le app aperte e i widget. In più l'archivio è un solo JSON che si legge tutto all'avvio e si riscrive tutto a ogni salvataggio (in background, ma sempre intero).

**I limiti**, sul mio Mac (MacBook Pro M1, 8 GB, schermo a 60 Hz):
- **Ogni tocco, tasto, trascinamento o scorrimento** sta dentro un fotogramma: meno di 16 ms, e nessun fotogramma perso durante le animazioni.
- **Aprire un'app, cambiare cliente, cambiare scheda:** il primo fotogramma, già con il contenuto vero, entro 100 ms.
- **La ricerca ⌘K:** i risultati cambiano a ogni tasto, entro 30 ms.
- **Lo sblocco** riporta tutto com'era entro 150 ms. L'avvio da zero arriva alla scrivania utilizzabile entro 1 s, con 200 clienti.
- **Eve con Qwen già caricato:** le cifre dei motori compaiono subito, la prima parola di Qwen entro 1 s. Qwen non deve mai caricarsi da zero mentre aspetto, se si poteva prevedere (vedi giro zero).
- **Prospetti, video, moduli e documenti** si preparano in background: l'anteprima compare subito, il file finito arriva con un avviso. Mai una finestra che blocca.
- **La memoria di Prisma** (senza Ollama) resta sotto i 400 MB di impronta con 200 clienti.

**Le regole per scrivere codice veloce:**
- **Niente calcoli pesanti sul thread principale.** I motori lavorano fuori dal thread principale, con risultati in cache legati alla generazione dei dati (il contatore c'è già). Le viste leggono i risultati pronti.
- **Mai uno schermo vuoto.**
  - Quando un risultato si sta aggiornando, si vede l'ultimo valore valido e poi il nuovo, con l'animazione del numero.
  - Sotto i 300 ms niente indicatore di attesa.
  - Oltre, un'indicazione che dice cosa sta succedendo («Leggo 38 pagine…»), mai una rotellina muta.
- **Le animazioni non bloccano mai.** Posso cliccare, scrivere e cambiare app durante qualunque animazione. Nel template alcune animazioni ignorano i clic finché non finiscono (`busy`): nell'app no. Le animazioni «wow» (la proposta che si compone, i campi che si riempiono) mostrano risultati già calcolati e durano al massimo un paio di secondi.
- **Prima di quando serve.** Prisma prepara ciò che probabilmente aprirò:
  - il dossier su cui passo il puntatore o che è selezionato;
  - il cliente del prossimo appuntamento in Agenda (dossier, prospetti, contesto di Eve), mezz'ora prima;
  - il lavoro del giorno dopo, di notte (giro 12).
- **Le mie azioni sono subito fatte, con «Annulla».** Spostare, completare, archiviare non chiedono conferma: si fanno e si annullano con ⌘Z o con il pulsante nell'avviso. La conferma resta per ciò che propone Eve (niente entra nel dossier senza di me) e per ciò che non si può annullare.
- **Liste lunghe pigre** (`LazyVStack`, `LazyVGrid`), immagini ridotte alla misura in cui si vedono, shader e video liberati appena non si vedono.

**Le prove.** La prova della fluidità diventa un controllo vero.
- **Limiti nuovi nel workflow.** Oggi fallisce solo oltre i 3 s per azione: abbassa i limiti dell'«aggiornamento» per avvicinarli a quelli qui sopra, tenendo conto che il runner Intel è più lento del mio M1.
- **Contro i peggioramenti.** La prova fallisce se un'azione peggiora più del 15% rispetto a main.
- **Le funzioni nuove.** Aggiungi alla prova le azioni nuove di ogni giro: aprire la Sala, il prisma di luce, Pratiche, la Biblioteca, il radar, la pila di Stanotte.

## Giro 0 — Prisma istantaneo
Prima delle funzioni, perché tutte nascano già sulla struttura veloce.

**Misurare sul mio Mac.**
- In Impostazioni, nella sezione delle informazioni, un pulsante «Misura la velocità su questo Mac». Fa girare la stessa prova della fluidità con i clienti di prova, senza toccare il mio archivio, e mostra la tabella con un pulsante per copiarla. Così misuri sul mio M1 vero e non solo sul runner.
- Prepara anche la misura dei tempi di Eve: caricamento di Qwen, prima parola, parole al secondo.

**Lo stato a pezzi.** Dividi `StatoShell` in modo che ogni vista osservi solo i dati che mostra: un tasto in una nota deve aggiornare quella nota e basta.
- **La strada migliore** è il framework Observation (`@Observable`), che richiede macOS 14. Il mio Mac ha macOS 27 e iOS è già a 17. Proponimelo con le misure prima e dopo su un'app di prova. Se ti dico sì, alza il minimo a macOS 14 e aggiorna CLAUDE.md.
- **Se ti dico no,** dividi lo stato in oggetti osservabili piccoli, per argomento: clienti, agenda, posizioni, documenti, impostazioni, finestre.
- **In entrambi i casi** le viste ricevono solo i valori che usano, e i risultati dei motori vengono dalla cache.

**L'archivio.**
- L'avvio legge subito solo ciò che serve alla scrivania e il resto dopo, senza bloccare.
- Il salvataggio scrive solo ciò che è cambiato, o almeno smette di riscrivere tutto a ogni tasto (accorpando le modifiche ravvicinate).
- **Prima di cambiare il formato, proponimelo con le misure.** I vecchi archivi e i vecchi backup devono aprirsi lo stesso, e `--prova-backup` va aggiornata.

**I motori in cache.** I motori più usati (portafoglio, Analisi 360, obiettivi, attenzioni, mossa del giorno, posizioni) calcolano fuori dal thread principale e ricordano il risultato finché i dati del cliente non cambiano. Quando cambia un cliente, si ricalcola solo lui.

**Eve senza attese.**
- **Il modello già pronto.** Qwen si precarica quando probabilmente servirà: all'apertura di Eve, del copilota o della Biblioteca, prima di un appuntamento, quando comincio a scrivere una domanda.
- **La memoria.** Se il Mac è sotto pressione di memoria, Qwen si libera da solo (avviso di pressione del sistema) e si ricarica quando torna utile.
- **Le stesse opzioni a ogni chiamata.** Se cambiano, per esempio la finestra di contesto, Ollama ricarica il modello.
- **Il riuso del contesto.** La parte fissa (istruzioni, dati stabili del dossier) va all'inizio e la domanda alla fine, così Ollama riusa il contesto già letto.
- **Prima le cifre, poi il racconto.** Le schede con i numeri dei motori compaiono subito, il testo di Qwen arriva a seguire.

**Il risultato del giro:** la tabella prima e dopo, sul runner e sul mio Mac, nella pagina delle anteprime.

## Giro 1 — Le fondamenta: icone, dock, Novità, la Sala e il Territorio
**Icone e dock.**
- Le icone di Territorio, Sala, Pratiche e Biblioteca sono nel template, come SVG dentro `<template id="sorgenti-icone">`, con la stessa geometria delle altre. Salvale in `Design/Icone/`, aggiorna `genera-icone.js` e generane i PNG.
- Il dock diventa quello del template: Scrivania, Clienti, Posizioni, Analisi 360, Incontri, Agenda, Territorio, Messaggi, Pratiche, Prospetti, Sala, Biblioteca, Mercato, Studio, Eve, Impostazioni.
- Controlla che con 16 icone il dock resti leggibile anche sugli schermi più stretti. Su iPhone e iPad le app nuove entrano con la gerarchia approvata.

**Novità.** Dopo l'aggiornamento, al primo ingresso si apre una volta il pannello «Novità» del template: le 29 voci in due gruppi, «Davanti al cliente · 15» e «Per il tuo lavoro · 14». Resta raggiungibile dalla Guida.

**La Sala**, come nel template.
- In alto la scelta del cliente. Sotto, le esperienze come schede da aprire, che arrivano nei giri 2-6.
- Ogni esperienza ha sempre:
  - «Mostra sul tavolo», con l'iPad al tavolo che esiste già (`Tavolo/`);
  - quando ha senso, «Aggiungi al Prisma di …» (giro 2).
- Funziona anche in presentazione.

**Il Territorio**, come nel template, con tre viste.
- **Oggi.** I clienti sono luci sulla mappa:
  - colore del canale (Alleanza, indipendente, entrambi);
  - grandezza secondo il patrimonio;
  - a lato il quartiere con più patrimonio, dove ancora non ci sono clienti, con chi c'è qualcosa da fare.
- **La crescita:** le luci si accendono anno per anno, dalla data di inizio del rapporto.
- **Il giro di domani:** gli appuntamenti del giorno dopo in Agenda in ordine sensato, con km e tempi stimati. Vanno anche nel giro 11 (chilometri).
- **Niente mappe da internet.** MapKit scarica le tessere dalla rete, quindi qui non si usa. La mappa la disegna Prisma, scura e stilizzata come nel template, da un file di confini e coordinate dei comuni e dei CAP incluso nell'app.
  - Proponimi la fonte (per esempio i dati aperti dell'ISTAT), con licenza e dimensione, e aspetta il mio sì.
  - Finché il file manca, la vista lavora sui CAP dei clienti di prova e lo dice.
- Gli indirizzi dei clienti ci sono già nell'anagrafica: la posizione si ricava dal CAP e dal comune, senza geocodifica online.

## Giro 2 — Il Prisma del cliente, la lettera dal futuro, la capsula del tempo
**Il Prisma del cliente**, come nel template: la sua app personale, in un file.
- **Prima una prova di fattibilità, e scrivimi l'esito.** La strada che propongo:
  - un solo file HTML autonomo, con il contenuto cifrato (AES-GCM, chiave da password con PBKDF2) e decifrato nel browser del cliente con WebCrypto;
  - nessun server: il file glielo mando io con Messaggi o con Mail, e si apre in Safari anche senza rete.
- **Dentro** c'è quello che scelgo con gli interruttori: gli obiettivi con gli anelli, la linea della vita da esplorare, la lettera dal futuro, il film del piano, le posizioni nel dettaglio (spente di base).
- **Il contenuto** è quello dei prospetti approvati, con le stesse avvertenze, e porta l'etichetta del canale.
- **Password e data:**
  - la password la sceglie Prisma e la mostro io al cliente, a voce o a parte;
  - la data «si può aprire fino al…» la imposto io.
- **Ogni versione mandata** resta nel dossier, con data e contenuto.
- **Aggiornare** vuol dire mandare un file nuovo: niente si aggiorna da solo, e scrivilo chiaramente nell'interfaccia.

**La lettera dal futuro**, come nel template.
- Eve scrive la lettera del cliente a sé stesso a 67 anni (o all'età della pensione del piano), con «Con il piano» e «Senza il piano».
- Le cifre vengono solo dai motori: pensione stimata, obiettivi raggiunti, età. Le istruzioni vanno in `Eve/Istruzioni/lettera.md`, con prove che ogni cifra del testo sia una cifra dei motori.
- In fondo, sempre: lettera immaginaria scritta a partire dalle cifre di Prisma, non una previsione.
- La carta è chiara e sobria, anche in modalità scura, come i PDF. «Riscrivi» ne prepara un'altra.

**La capsula del tempo**, come nel template.
- Il cliente scrive, anche sull'iPad al tavolo, un messaggio a sé stesso per il giorno in cui raggiungerà un obiettivo. Prisma lo sigilla.
- **Il testo non compare in nessuna schermata finché l'obiettivo non è raggiunto, nemmeno a me.** In archivio e nei backup è cifrato.
- Quando il motore degli obiettivi segna il traguardo, la capsula passa ai traguardi festeggiati (giro 3) con «Apri la capsula», da aprire insieme.
- L'elenco delle capsule sigillate mostra solo cliente, obiettivo e data di chiusura.

## Giro 3 — Il film del piano, la tua settimana e il tuo anno, i traguardi festeggiati
**Il film del piano**, come nel template: un minuto da mandare dopo l'incontro.
- **Le scene** con gli anelli che si riempiono, le linee che si disegnano e le frasi brevi, tutte dai motori.
- **L'esportazione:** un video MP4 verticale e orizzontale. Disegna le scene fotogramma per fotogramma con `ImageRenderer` e AVFoundation (`AVAssetWriter`), fuori dal thread principale e senza tenere i fotogrammi in memoria.
- **«Manda su WhatsApp»** apre la condivisione del Mac con il video già pronto: lo mando io.
- Le cifre portano la stessa avvertenza dei prospetti, nell'ultima scena.

**La tua settimana, il tuo anno**, come nel template.
- Racconti a tutto schermo, da toccare o da far scorrere con le frecce:
  - il lunedì, la settimana: incontri, scadenze, proposte, la mossa del giorno;
  - a dicembre, l'anno: produzione, nuovi clienti, ricavi, obiettivi di Studio, i momenti migliori.
- I dati vengono da `MotoreStatoDelLavoro`, `MotoreStudio`, Agenda e dal seguito delle proposte.
- Il lunedì il racconto si apre una volta da solo dopo lo sblocco. Si spegne in Impostazioni.

**I traguardi festeggiati**, in Messaggi come nel template, nella sezione «Da festeggiare».
- **Prisma si accorge da solo dei traguardi:**
  - obiettivi raggiunti;
  - anniversari del rapporto;
  - un mutuo estinto;
  - un figlio che arriva all'università con il piano pronto.
- **Per ogni traguardo,** «Il momento, già pronto»:
  - il biglietto animato da mandare (un video breve, con la stessa tecnica del film);
  - la telefonata in Agenda;
  - l'idea per un regalo, solo se c'è nelle note del dossier;
  - la capsula del tempo, se c'è.

## Giro 4 — Il prisma di luce e la realtà aumentata
Sono le due esperienze più spettacolari. Nel template sono disegnate con due shader WebGL, `FS_LUCE` e `FS_AR`, che sono la specifica esatta della resa: luce, vetro, dispersione, legno, ombre e tempi. Non semplificarle.

**Il prisma di luce**, come nel template.
- Porta `FS_LUCE` in Metal, con la stessa tecnica dello sfondo d'acqua: `MTKView` o `CAMetalLayer`, disegno fuori dal thread principale, ritmo ridotto in risparmio energetico, fermo quando non si vede.
- Il patrimonio entra come raggio di luce bianca e si scompone in raggi colorati con spessore proporzionale al peso, in tre modi:
  - per investimento: azionario, obbligazioni, gestione separata, liquidità;
  - per obiettivo;
  - per canale.
- Passando su un raggio, compare il nome con l'importo. Il cursore «oggi → fra vent'anni» fa crescere i raggi con le proiezioni del motore.
- Su Mac e su iPad al tavolo. Nelle istantanee, il fotogramma finale.

**La realtà aumentata**, come nel template.
- Sull'iPhone, con RealityKit e ARKit:
  - il piano del tavolo si riconosce, il patrimonio compare come colonne di vetro sul legno e cresce con gli anni;
  - con «Esplodi», le colonne si dividono nelle posizioni.
- `FS_AR` è la specifica di materiali, luce e camera.
- I dati arrivano dal Mac attraverso il ponte cifrato che esiste già. Senza Mac, dalla copia di Prisma ovunque, se accesa.
- Aggiungi la descrizione d'uso della fotocamera, se manca. Sul Mac, al posto della realtà aumentata, la stessa scena in 3D da ruotare con il trackpad.
- Prima una prova di fattibilità: RealityKit con il pacchetto Swift e la firma ad-hoc, senza Xcode. Scrivimi l'esito prima di andare avanti.

## Giro 5 — Le esperienze dei numeri
Tutte nella Sala, come nel template, con «Mostra sul tavolo».

**Disegna il tuo futuro.**
- Il cliente disegna con il dito sull'iPad, o con il mouse, come vorrebbe che crescesse il suo patrimonio da oggi a 90 anni.
- Prisma trasforma il disegno nel piano che ci si avvicina di più (`CurvaObiettivo`, `MotorePianificazione`): versamenti, tempi, ed eventuali scarti da spiegare.
- «Salva come obiettivo» lo porta nel dossier, con la mia conferma.

**Il gioco del rischio.**
- Tre scenari raccontati uno alla volta, con il valore che scende in diretta e tre risposte possibili.
- Alla fine, il «profilo vissuto» accanto a quello dichiarato.
- **Il gioco prepara il questionario di adeguatezza, non lo sostituisce:** non modifica mai il profilo ufficiale. Il risultato entra nel dossier come nota.

**Una giornata della pensione.**
- La pensione mensile stimata (`MotorePensionePubblica` più la previdenza complementare del piano) diventa una giornata: la colazione al bar, la casa, i nipoti, la cena fuori, il viaggio.
- Le voci e i loro costi li sceglie il cliente con me. Prisma mostra cosa ci sta e cosa no, con e senza il piano, e quanto manca al mese.
- Le cifre sono in euro di oggi.

**Lancia l'anno.**
- Due vite affiancate, con e senza il piano. A ogni lancio passa un anno:
  - i mercati vengono da `MotoreMonteCarlo`;
  - gli imprevisti della vita (infortunio, malattia, perdita del lavoro) colpiscono una vita sola o entrambe, ma solo la vita con il piano è protetta.
- **Le probabilità degli imprevisti non le inventi tu.** Prepara il file con le probabilità e chiedimele. Finché mancano, «dati di prova».
- «Lancia 10 anni» fa correre la sequenza.

**Quanto vale avermi accanto.**
- Al riesame (o ogni tre anni di rapporto), il valore del mio lavoro in cifre:
  - tasse risparmiate (deduzioni del fondo pensione e delle polizze, dal motore fiscale);
  - costi tagliati (`MotoreCosti`, sostituzioni fatte);
  - risultato rispetto all'alternativa (track record);
  - capitale protetto.
- Il tutto a confronto con le parcelle pagate.
- Sempre etichettato come stima, con il dettaglio di ogni voce.

## Giro 6 — La palestra della trattativa
In Studio, come nel template.
- **Eve recita il cliente** con il suo profilo vero dal dossier, o con un cliente fittizio, e le sue obiezioni probabili:
  - tre livelli di difficoltà (facile, realistica, difficile);
  - un'obiezione alla volta.
- **Rispondo io:** scegliendo una delle tre risposte suggerite, o a parole mie (anche a voce, con il riconoscimento sul Mac).
- **Alla fine,** il resoconto: cosa ha funzionato, cosa no, quale numero del piano avrebbe aiutato.
- Le istruzioni vanno in `Eve/Istruzioni/palestra.md`, con conversazioni di prova nel workflow. È la modalità conversazione di Eve, ma i numeri citati vengono solo dai motori.
- Tutto resta sul Mac, con Qwen locale come sempre.

## Giro 7 — L'app Pratiche
Nuova app, come nel template, con quattro schede: Proposta, Moduli, Dopo la firma, Sinistri.

**La proposta si costruisce da sola.**
- A sinistra i bisogni scoperti dall'analisi (`MotoreBisogni`, `MotoreSostituzione`). Con «Costruisci la proposta», le cinque tappe si compongono una dopo l'altra:
  1. il prodotto, dal catalogo dei prodotti, con il canale;
  2. l'importo, dai motori;
  3. il prospetto, da `CompositoreProspetti`, su carta bianca;
  4. l'adeguatezza, da `MotoreAdeguatezza`;
  5. i moduli, da «Compila da solo».
- **Se l'adeguatezza non è verificata, la costruzione si ferma e spiega perché.** Mai una proposta non adeguata pronta da firmare.
- **Il tempo mostrato** («Proposta pronta in 52 secondi») è quello vero.
- La proposta entra nel seguito delle proposte che esiste già. «Presenta» la porta sul tavolo, «Nel fascicolo» nel fascicolo del prossimo incontro.

**Compila da solo.**
- **I moduli sono i miei**, Alleanza e della consulenza: li carico una volta come PDF. Restano solo nel mio archivio, mai nel repository.
- **Il riconoscimento dei campi:**
  - se il PDF ha già i campi compilabili, Prisma li usa con PDFKit;
  - se è un PDF piatto, Prisma propone dove sono i campi (Vision trova le etichette) e io confermo o correggo una volta sola, poi se lo ricorda per quel modulo.
- **La compilazione:** con i dati del dossier, campo per campo come nel template.
  - Ciò che manca si accende in rosso, ed Eve propone di chiederlo al cliente con un messaggio.
  - Le caselle delle firme si accendono in giallo.
- **Il PDF compilato** va nei Documenti del cliente. Nel repository solo un modulo fac-simile scritto da te, per le prove.

**Le pratiche dopo la firma.**
- Per ogni pratica i passi, uguali alla lista del template ma modificabili per canale e per tipo di prodotto:
  - moduli completi;
  - documenti informativi consegnati;
  - documento d'identità;
  - primo premio;
  - polizza emessa;
  - consegnata al cliente.
- Le pratiche ferme da più giorni di una soglia che imposto io si accendono in rosso. «Sollecita» prepara il messaggio (Messaggi, giro 3 di «Orizzonte»).
- In alto: aperte, ferme, concluse nel mese.

**Il sinistro come una spedizione.**
- Le fasi sono denuncia, documenti, perizia, liquidazione, pagato, con la cronologia e i documenti arrivati o mancanti. Le aggiorno io: Prisma non parla con le compagnie.
- **«Così lo vede il cliente»**: la stessa pagina semplice entra nel Prisma del cliente (giro 2).
- «Aggiorna il cliente» prepara un messaggio, o un file nuovo del suo Prisma, con lo stato. Niente si aggiorna da solo dal telefono del cliente, perché non c'è un server.

## Giro 8 — La Biblioteca: trova la pagina
Nuova app, come nel template.
- **I documenti.** Ci trascino i PDF che uso: condizioni di assicurazione, note informative, KID, circolari, normativa. Prisma li legge sul Mac (PDFKit, e Vision per i PDF scansionati) e li indicizza in locale.
- **Le risposte.** Faccio una domanda a parole mie ed Eve risponde **solo dal testo dei documenti**:
  - la risposta è breve;
  - porta il documento, la pagina e l'articolo;
  - la pagina si apre con il contatore che scorre e la frase evidenziata che si accende.
  - Se il testo non dice una cosa, Eve lo scrive e non completa con altro.
- **Il metodo.** Ricerca locale (indice delle parole e, se regge sugli 8 GB, vettori calcolati con Qwen) e poi Qwen per la risposta con la citazione. Le istruzioni vanno in `Eve/Istruzioni/biblioteca.md`.
- **Le prove** nel workflow usano solo documenti fac-simile scritti da te. Controllano che ogni risposta citi una pagina che contiene davvero la frase.
- «Mostra al cliente» porta la pagina evidenziata a tutto schermo o sul tavolo. «Copia la citazione» copia documento, pagina e frase.
- I miei documenti veri restano solo nel mio archivio. Nel backup ci sono già, come gli altri documenti.

## Giro 9 — Il radar del portafoglio, lo smontaggio, le campagne
**Il radar**, in Posizioni accanto a Portafoglio e Prova del fuoco, come nel template.
- **I portafogli modello** (es. Prudente, Equilibrato, Dinamico) e la tolleranza li imposto io in Impostazioni, con i pesi per classe: azioni, obbligazioni, gestione separata, liquidità. Niente modelli inventati da te. A ogni cliente assegno il suo modello.
- **La distanza** di ogni cliente dal suo modello è la metà della somma degli scostamenti assoluti tra pesi veri e pesi del modello, in punti. Più è lontano, più il punto è lontano dal centro.
- **L'anello della tolleranza** è al centro, e chi è fuori pulsa. Il raggio gira lento.
- **«Riequilibra»** prepara una proposta per ogni cliente fuori tolleranza:
  - cosa spostare;
  - costi;
  - tasse sulle eventuali plusvalenze, calcolate dal motore fiscale quota per quota.

  I punti tornano verso il centro come nel template. Non si muove nulla senza di me: sono proposte.
- Toccando un punto si apre il dettaglio con le barre di oggi e la linea del modello.

**Lo smontaggio**, in Posizioni, come nel template.
- **Il documento.** Un estratto conto o un KID di un'altra banca, inquadrato con l'iPhone («Inquadra e capisci» c'è già) o trascinato come PDF.
- **Le voci di costo**, che Prisma trova con `EstrattoreDocumento` e Eve:
  - commissione di gestione;
  - performance;
  - diritti fissi;
  - ingresso;
  - penali di uscita.

  Si cerchiano in rosso sul documento, una alla volta, con la nota a lato.
- **I conti** li fa `MotoreCosti`: costi l'anno oggi e con la mia proposta, e la differenza in dieci anni a parità di rendimento lordo, con il rendimento scritto. È sempre etichettato come stima.
- Se c'è una penale di uscita, Prisma calcola da quando conviene cambiare.
- «Crea la proposta di sostituzione» apre la proposta nel giro 7.

**Le campagne**, in Messaggi accanto ai messaggi, come nel template.
- Prisma raggruppa i clienti con lo stesso bisogno: nessuna protezione per il coniuge, titoli in scadenza, compleanni importanti, fondo pensione fermo, e gli altri bisogni che i motori sanno già trovare.
- **La costellazione:** i punti dei clienti si raccolgono nei gruppi. Toccando un gruppo:
  - l'anteprima del messaggio personalizzato per ognuno, scritto da Eve con le cifre dei motori;
  - gli appuntamenti liberi da proporre, presi dall'Agenda e dai miei orari di lavoro.
- **«Avvia la campagna»** prepara tutte le bozze e le apre in Mail o in Messaggi **una per una**: le spedisco io. Ogni messaggio resta nel dossier.
- Le istruzioni vanno in `Eve/Istruzioni/messaggi.md`, con le prove sulle cifre che ci sono già.

## Giro 10 — Clienti: nuovo cliente, potenziali, passaparola, imprenditori
**Nuovo cliente in 10 secondi**, come nel template («＋ Nuovo cliente» in Clienti, e sull'iPhone).
- **La lettura.** L'iPhone inquadra la carta d'identità con VisionKit e Vision, compresa la riga MRZ della carta elettronica. I campi si illuminano uno alla volta e arrivano al Mac attraverso il ponte cifrato.
- **Il codice fiscale** si controlla con il carattere di controllo e la coerenza con nome, data e luogo di nascita.
- **Il dossier** si crea con l'anagrafica compilata, la copia del documento nei Documenti (serve all'adeguata verifica) e i moduli della privacy e dell'antiriciclaggio già compilati dai miei modelli (giro 7).
- Il contatore dei secondi è vero. Niente entra nel dossier senza la mia conferma.

**Potenziali clienti**, nuova vista in Clienti.
- Le colonne sono da contattare, primo incontro, analisi, proposta, cliente. Ogni scheda ha il patrimonio stimato, la probabilità e chi l'ha presentato.
- In alto: quanti sono, il patrimonio stimato, quanti vengono dal passaparola, il probabile entro fine anno.
- La scheda avanza con un tocco o trascinandola. Quando diventa cliente, il dossier nasce con i dati già raccolti.
- **I potenziali clienti hanno un consenso privacy minimo**: segnalalo e chiedimi quali dati tenere.

**L'albero del passaparola.**
- Chi mi ha presentato chi, dal primo cliente: io al centro, i clienti, le persone che hanno presentato. Clienti in verde, potenziali tratteggiati, grandezza secondo il patrimonio.
- **I miei ambasciatori**, con il patrimonio nato da loro, e la quota di patrimonio nuovo che viene dal passaparola.
- **«Il momento giusto per chiedere»**: un cliente appena arrivato a un traguardo (giro 3). «Prepara la richiesta» scrive un messaggio di ringraziamento e una richiesta leggera, da mandare io.
- Il campo «presentato da» si aggiunge all'anagrafica e si compila anche per i clienti di oggi.

**I clienti imprenditori**, nuova scheda «L'azienda» nel dossier, solo per chi ha un'azienda.
- L'azienda con la quota, il ruolo, i dipendenti e il fatturato, che inserisco io.
- **Quattro temi con l'anello di copertura:**
  - persona chiave;
  - trattamento di fine mandato degli amministratori;
  - welfare aziendale;
  - passaggio dell'impresa.

  Ognuno ha l'azione, collegata ai motori che esistono (protezione, successione, simulatori).
- **Le valutazioni fiscali le scrivi sempre come «da verificare con il commercialista».** Non mettere regole fiscali sul TFM o sul welfare che non conosci: chiedimele.

## Giro 11 — La nota vocale dall'iPhone, chilometri, spese e scadenze
**La nota vocale**, come nel template (in Incontri «Nota dall'iPhone», e sull'iPhone un pulsante grande).
- **La registrazione.** Tra una visita e l'altra parlo all'iPhone. Il riconoscimento è **sul dispositivo**: Speech con `requiresOnDeviceRecognition`, l'audio non esce e non si salva.
- **Il viaggio verso il Mac.** Il testo arriva attraverso il ponte. Se il Mac è spento, arriva con il giornale di Prisma ovunque, se acceso, e si unisce al ritorno.
- **Sul Mac**, Eve capisce di quale cliente si parla e prepara le schede, come il copilota:
  - la nota nel dossier;
  - l'attività;
  - il messaggio pronto;
  - l'obiettivo da aggiornare.

  Confermo tutto insieme o una voce alla volta. Usa `EstrattoreIncontro` e le istruzioni del copilota, aggiungendo `Eve/Istruzioni/nota-vocale.md`.

**Chilometri, spese e scadenze**, nuova scheda «Spese» in Studio. Le schede di Studio diventano: Cruscotto, Parcelle, Track record, OCF, Palestra, Spese.
- **I chilometri** del mese vengono da soli dalle visite in Agenda e dal Territorio, con il dettaglio per giorno e il grafico per mese. Le distanze sono stime e le posso correggere.
- **Il rimborso o la deduzione dei chilometri non li calcoli tu**: niente tabelle ACI o regole inventate. Prepara il campo per la tariffa che mi dà il commercialista.
- **Le spese:** «Inquadra lo scontrino» (iPhone o foto trascinata). Vision legge importo, data ed esercente, e la categoria la propone Eve e la confermo io.
- **Le scadenze:** F24, acconti, polizza RC professionale, ore di aggiornamento professionale con l'anello.
  - Le date e gli importi fiscali li inserisco io o vengono dal commercialista: Prisma non li calcola.
  - Le ore richieste dall'aggiornamento le imposto io. Gli attestati sono nei Documenti.
  - Le scadenze compaiono anche in Agenda.
- **«Prepara il pacchetto per il commercialista»** crea un archivio del mese: chilometri e spese in CSV e PDF, con le foto degli scontrini. Lo mando io.

## Giro 12 — Stanotte Prisma ha lavorato
Arriva dopo le altre funzioni perché raccoglie il lavoro di tutte.
- **Di notte**, con `NSBackgroundActivityScheduler` come il backup automatico, e solo se il Mac è acceso e collegato alla corrente, Prisma prepara il lavoro del giorno dopo:
  - il fascicolo degli incontri;
  - le bozze dei messaggi per le scadenze;
  - il ricalcolo dei portafogli e del radar;
  - i documenti dei clienti in scadenza;
  - i moduli delle proposte aperte;
  - i riesami;
  - le campagne;
  - la borsa del giorno dopo: incontri, documenti da portare, chilometri, ora di partenza;
  - le cache del giorno dopo: dossier, prospetti in PDF e contesto di Eve dei clienti in Agenda, già pronti al mattino.
- **Se il Mac dormiva,** lo fa al primo sblocco del mattino, prima di mostrare la pila.
- **Le risorse.** Qwen lavora un compito alla volta e si chiude alla fine. Se mi metto al Mac, tutto si ferma e riprende dopo. Niente supera la memoria di un M1 con 8 GB.
- **Al primo sblocco del mattino**, la pila di carte del template:
  - «Stanotte ho lavorato per te», con l'ora vera;
  - una carta per ogni cosa preparata;
  - a destra approvo, a sinistra «più tardi», con le frecce o trascinando;
  - il registro «Fatto adesso» e la carta finale «Tutto fatto».
- **Approvare non spedisce niente**: rende pronte le cose nelle loro app (Messaggi, Pratiche, Incontri).
- Anche sull'iPhone, con la gerarchia approvata: la pila di carte è fatta per il pollice.
- Si accende, si spegne e si sceglie cosa preparare in Impostazioni. Il pulsante «☾ Stanotte» sulla scrivania la riapre durante il giorno.

## Giro 13 — Fai tutto da tastiera
Per lavorare veloce, oltre che su un'app veloce.
- **⌘K fa qualsiasi cosa, non solo cercare.** Mentre scrivo compaiono clienti, documenti e pagine della Biblioteca, insieme alle azioni:
  - «nota per Giulia»;
  - «nuova proposta per Marco»;
  - «messaggio a Sofia»;
  - «apri il radar»;
  - «spese di ottobre»;
  - «chi scade questo mese».

  Invio esegue, Tab completa. Le frasi più comuni le capisce Prisma da solo, senza Eve, entro 30 ms. Eve interviene solo per le richieste libere. Le azioni recenti e frequenti salgono in cima.
- **Le scorciatoie:**
  - ⌘1…⌘9 per le app del dock;
  - ⌘N per il nuovo elemento dell'app aperta;
  - ⌘⇧N per la nota veloce da qualunque punto, che capisce il cliente come la nota vocale;
  - frecce e Invio in tutte le liste, Esc per chiudere, ⌘Z per annullare ovunque.

  Il foglio «Scorciatoie» (⌘/) le mostra tutte.
- **Azioni in blocco.** Selezione multipla nelle liste (clienti, attività, pratiche, messaggi) con le azioni comuni.
- **Riprendi da dove eri.** Allo sblocco e al riavvio, le app, i clienti e le schede aperte tornano come li avevo lasciati.
- Su iPad, le stesse scorciatoie con la tastiera collegata.

## Giro 14 — Controllo finale
- Percorri tutte le istantanee nuove, in chiaro e in scuro, su Mac, iPhone e iPad, e confrontale con il template.
- **La velocità:** la tabella della fluidità e i tempi di Eve, prima di «Luce» e adesso, sul runner e sul mio Mac. Ogni riga deve rispettare i limiti della sezione «Velocità», anche con il prisma di luce aperto e 200 clienti. Dove non ci arrivi, scrivimi perché e cosa servirebbe.
- Controlla che backup e ripristino comprendano tutti i dati nuovi:
  - file del Prisma del cliente mandati;
  - lettere e capsule (cifrate);
  - portafogli modello;
  - moduli e loro mappe dei campi;
  - pratiche e sinistri;
  - biblioteca e indice;
  - potenziali clienti e «presentato da»;
  - aziende;
  - note vocali;
  - chilometri, spese e scadenze;
  - impostazioni di Stanotte.
- Controlla che nessuna funzione nuova esca su internet. Le sole eccezioni restano Mercato e Prisma ovunque, come scritto in CLAUDE.md.

## Alla fine
Quando tutti i giri sono uniti e verdi, apri la pull request verso main con il riepilogo della versione e uniscila quando è verde. Poi scrivimi, senza raccontare i passaggi:
- cosa c'è di nuovo, in poche righe per giro;
- la velocità prima e dopo: le azioni principali, sul mio Mac, in una tabella corta;
- tutto quello che aspetta un dato da me, e dove lo inserisco: per esempio
  - portafogli modello e tolleranza;
  - probabilità degli imprevisti;
  - file dei comuni;
  - moduli e loro campi;
  - tariffa chilometrica;
  - scadenze fiscali;
  - ore di aggiornamento;
  - regole su TFM e welfare;
  - il passaggio a macOS 14, se me lo proponi nel giro zero;
- l'esito delle prove di fattibilità (il file del Prisma del cliente, RealityKit senza Xcode);
- dove ti sei allontanato dal template e perché;
- la lista di cosa devo provare io:
  - il file del Prisma del cliente aperto sull'iPhone di qualcuno;
  - la realtà aumentata su un tavolo vero;
  - i miei moduli veri;
  - la Biblioteca con le condizioni vere;
  - la carta d'identità;
  - la nota vocale con il Mac spento;
  - una notte di Stanotte;
  - «Misura la velocità su questo Mac», prima e dopo l'aggiornamento.
