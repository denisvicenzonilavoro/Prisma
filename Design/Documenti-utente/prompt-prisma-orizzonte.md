Prepariamo la prossima versione di Prisma, che chiamiamo «Orizzonte». Contiene undici novità. Fino a oggi Prisma lavora per i clienti; con questa versione lavora anche per me, per il mio studio, ed entra davvero negli incontri.

1. **Studio:** il cruscotto del mio lavoro.
2. **Parcelle e fatture**, con il file XML della fattura elettronica.
3. **Track record:** le mie raccomandazioni e come sono andate.
4. **Prisma scrive per te:** Eve prepara i messaggi ai clienti, li spedisco io.
5. **La prova del fuoco:** uno scenario applicato a tutto il portafoglio.
6. **La linea della vita:** gli eventi trascinabili e il futuro che si ricalcola.
7. **Il copilota dell'incontro:** Prisma ascolta e capisce in diretta.
8. **Inquadra e capisci:** la polizza letta dalla fotocamera dell'iPhone.
9. **Rispetto alle famiglie come la sua.**
10. **Allenamento OCF.**
11. **Prisma conosce il mercato** e **Prisma ovunque:** la copia cifrata su iPhone e iPad.

Prima di cominciare:
- Rileggi CLAUDE.md. Le regole restano vincolanti: niente Xcode, build solo su GitHub Actions con macos-15-intel, tema Apple, valori grafici solo in `Sources/Prisma/DesignSystem/`, Mac M1 con 8 GB, italiano ovunque, dati dei clienti sempre sul Mac.
- Apri `Design/template-novita.html` in un browser headless (Playwright c'è) e percorrilo tutto. Il pulsante «✦ Novità» nella barra porta a ognuna delle undici funzioni. Guarda il codice per misure, tempi e animazioni: è la specifica.
  - Il template parte da `Design/template-apple.html`: per tutto ciò che c'era già, vale ancora quello.
  - Le cifre del template sono dimostrative. Nell'app i numeri vengono sempre dai motori di Prisma.
- Se il file non è nel repository, fermati e chiedimelo.

## Come lavorare
- Crea il branch di versione `versione-orizzonte` da main. Ogni giro è un branch a parte con una pull request verso `versione-orizzonte`, unita solo con la build verde.
- Main non si tocca fino alla fine: quando tutti i giri sono uniti e verdi, apri l'ultima pull request da `versione-orizzonte` verso main. Così io installo una volta sola.
- Dopo ogni push controlla la build (`gh run list`, `gh run view --log-failed`) e correggi finché non è verde.
- A ogni giro guarda le istantanee sul branch `anteprime` e confrontale con il template. Aggiungi le istantanee nuove, in chiaro e in scuro, e aggiorna la pagina online delle anteprime.
- Nessuna dipendenza esterna senza chiedere prima.
- Tutto ciò che è nuovo entra nell'archivio e nel backup. I vecchi archivi e i vecchi backup devono aprirsi lo stesso, e `Prisma --prova-backup` va aggiornata.
- Ogni motore nuovo ha la sua prova di calcolo nel workflow, come quelli che ci sono già (`ProvaCalcoli…`).
- **Non inventare mai regole o dati che non conosci**: aliquote delle provvigioni, regole fiscali della fattura, statistiche sulle famiglie, fonti di mercato. Prepara la struttura, mettimi i campi da compilare e chiedimi. Finché un dato vero manca, l'interfaccia scrive chiaramente «dati di prova».
- Il repository è pubblico: niente dati veri dei clienti e niente testi copiati da libri o manuali.
- Se una scelta grafica non è coperta dal template, fai la soluzione più sobria e coerente e scrivimela alla fine del giro.

## Giro 1 — Le app nuove e il cruscotto di Studio
**Icone e dock.**
- Le icone di Studio, Messaggi e Mercato sono nel template, come SVG dentro `<template id="sorgenti-icone">`, con la stessa geometria delle altre. Salvale in `Design/Icone/`, aggiorna `genera-icone.js` e generane i PNG.
- Il dock diventa quello del template: Scrivania, Clienti, Posizioni, Analisi 360, Incontri, Agenda, Messaggi, Prospetti, Mercato, Studio, Eve, Impostazioni.
- Su iPhone e iPad le app nuove entrano con la gerarchia approvata.

**Novità.** Dopo l'aggiornamento, al primo ingresso si apre una volta il pannello «Novità» del template. Resta raggiungibile dalla Guida.

**Scrivania.** Il riquadro «Il tuo studio» del template: ricavi del mese, da incassare e i tre anelli degli obiettivi.

**Studio, Cruscotto**, come nel template.
- **I ricavi dell'anno** con la linea contro l'anno precedente, divisi per canale:
  - Alleanza: provvigioni stimate;
  - indipendente: parcelle della consulenza.
- **Le provvigioni Alleanza** si calcolano dalle aliquote che inserisco io in Impostazioni › Studio, per tipo di prodotto: nuova produzione, ricorrenti, rinnovi. Senza aliquote, il canale Alleanza mostra «inserisci le tue aliquote» e nessuna cifra inventata.
- **Gli obiettivi dell'anno** con gli anelli: produzione Alleanza, nuovi clienti, ricavi della consulenza. Gli obiettivi li imposto io.
- **L'imbuto delle proposte**, ricavato dal seguito delle proposte che esiste già: preparate, presentate, firmate, tasso di chiusura, giorni medi alla firma e dove si fermano.
- **Gli incassi dei prossimi 12 mesi**, mese per mese e per canale: premi ricorrenti e rinnovi Alleanza dalle posizioni, parcelle già emesse o firmate.
- **Il valore e il tempo:** ogni cliente è un punto, con le ore dell'anno (dagli impegni in Agenda e dagli incontri) e i ricavi che genera. La zona «molto tempo, poco valore» è evidenziata, e toccando un punto si apre il cliente.

## Giro 2 — Parcelle e fatture, track record
**Parcelle e fatture**, come nel template.
- L'elenco con lo stato (bozza, da incassare, pagata), i totali incassati e da incassare, e «Nuova parcella» partendo dal cliente e dalla consulenza.
- **La fattura su carta bianca**, come tutti i PDF di Prisma, sempre con l'intestazione del canale indipendente.
- **Il file XML** nel formato della fattura elettronica italiana (FatturaPA). Prisma lo **prepara** e basta: lo carico io sul portale dell'Agenzia delle Entrate o lo do al commercialista. Nessun invio al Sistema di Interscambio.
- **Le voci fiscali** (regime, IVA, contributo previdenziale, ritenuta, bollo) seguono un regime che imposto io in Impostazioni › Studio, con i miei dati: partita IVA, codice fiscale, IBAN. Non scegliere tu il regime e non mettere aliquote di default: chiedimelo.
- Il file XML va controllato nel workflow contro lo schema ufficiale, con una prova automatica su una fattura di esempio.
- «Manda con Messaggi» apre il messaggio già pronto, con la fattura allegata (vedi giro 3).

**Track record**, come nel template.
- Ogni raccomandazione si registra da sola quando una proposta viene presentata. Contiene cosa ho proposto, perché (le cifre dei motori in quel momento), l'alternativa, la scelta del cliente e la data.
- Dopo, Prisma confronta la mia proposta con l'alternativa nel tempo. Usa i riferimenti e i valori aggiornati delle posizioni che esistono già, ed è sempre etichettato come stima.
- In alto le cifre del template: quante raccomandazioni, quante accettate, quante ancora in essere dopo 12 mesi, lo scarto medio rispetto all'alternativa. Toccando una riga si apre il dettaglio.
- È anche una traccia per la conformità: le raccomandazioni registrate non si modificano, si aggiungono solo note.

## Giro 3 — Prisma scrive per te
Come l'app Messaggi del template.
- **Le occasioni da scrivere**, divise in «Da mandare oggi» e «Questa settimana», con il «Perché adesso». Vengono da riepiloghi dopo gli incontri, scadenze, compleanni, consensi da rinnovare, riesami, occasioni dell'Agenda e avvisi di Mercato.
- **Il testo.** Eve (Qwen, lo stesso nucleo e lo stesso `FornitoreModello` di oggi) scrive il testo con i dati del dossier:
  - i numeri li prende solo dai motori, mai inventati;
  - tre toni: cordiale, formale, breve;
  - due canali: Mail e Messaggi.

  Il testo compare parola per parola come nel template e resta modificabile.
- **Le istruzioni** vanno in `Eve/Istruzioni/messaggi.md`. Le prove nel workflow controllano che ogni cifra del testo sia una cifra dei motori.
- **Lo invio io.** «Apri in Mail» e «Apri in Messaggi» aprono le app del Mac con il messaggio già compilato (NSSharingService o URL `mailto:` e `sms:`). Prisma non spedisce mai niente da solo.
- Ogni messaggio aperto o salvato resta nel dossier del cliente, con la data.
- Se Qwen non è pronto, Eve lo dice e propone un modello di testo fisso già compilato con i dati.

## Giro 4 — La prova del fuoco e la linea della vita
**La prova del fuoco**, in Posizioni accanto al portafoglio, come nel template.
- **Gli scenari:** mercati in calo (cursore), tassi in rialzo, inflazione, «Come nel 2008», «Come nel 2020». Le crisi storiche vengono da `CrisiStoriche`.
- **Il calcolo:** tutti i clienti si ricalcolano insieme con il motore della prova di resistenza che esiste già, applicato alle posizioni vere di ciascuno, e poi con gli obiettivi.
- **Il risultato:** in alto quanti clienti scendono di più di 10 punti sui loro obiettivi e quanto patrimonio si perde in tutto. Sotto, la lista «Chi chiamare, in ordine», con la barra dell'obiettivo oggi e dopo lo scenario.
- Quando lo scenario cambia, le righe scorrono al loro nuovo posto. «Chiama» e «Messaggio» aprono il giro 3.
- Il calcolo resta fluido sul M1 anche con 35 clienti: fallo fuori dal thread principale e ricalcola mentre trascino.

**La linea della vita**, nuova scheda del dossier come nel template.
- **La linea:** il patrimonio da oggi a 90 anni, con la pensione e gli eventi (matrimonio, casa, figli, studi, eredità, anno sabbatico…) come etichette trascinabili sull'età.
- **Il ricalcolo:** a ogni trascinamento si aggiornano il patrimonio alla pensione, il massimo e l'età a cui il patrimonio basta. Se finisce prima dei 90 anni, il punto si accende in rosso.
- **I motori:** il calcolo vero usa quelli che esistono già (pianificazione, patrimonio, pensione pubblica, fiscale), non la formula semplificata del template.
- Gli eventi si salvano nel dossier, si aggiungono, si tolgono, e possono arrivare dal copilota (giro 5).
- Funziona anche in modalità cliente, in presentazione e sul tavolo con l'iPad.

## Giro 5 — Il copilota dell'incontro e «Inquadra e capisci»
**Il copilota**, nell'app Incontri come nel template.
- **Prima di tutto il consenso del cliente.** Senza consenso registrato nel dossier il copilota non parte.
- **L'ascolto** usa il riconoscimento vocale **sul dispositivo** (quello che Prisma usa già in `AscoltoEve` e `TrascrizioneEve`, solo locale). L'audio non lascia mai il Mac e non viene salvato, a meno che io non lo chieda.
- **Mentre si parla:**
  - la trascrizione scorre con le parole importanti evidenziate;
  - Eve riconosce a pezzi quattro tipi di cose: obiettivi (con tempi e cifre), polizze e posizioni di altre compagnie, timori e preferenze di rischio, eventi della vita;
  - per ognuna compare a destra una scheda con l'azione: aggiorna l'obiettivo, aggiungi a Posizioni, annota nel profilo, aggiungi alla linea della vita, crea l'attività.
- **Alla fine** il verbale, le attività e «Cosa entra nel dossier», da confermare tutto insieme o voce per voce. Niente entra nel dossier senza la mia conferma.
- Le istruzioni vanno in `Eve/Istruzioni/copilota.md`, con prove su conversazioni di esempio e le schede attese.
- Funziona anche sull'iPad, con il riconoscimento sull'iPad stesso e le schede inviate al Mac attraverso il ponte.

**Inquadra e capisci**, come nel template.
- Da Posizioni («Inquadra con l'iPhone») e dall'iPhone stesso: la fotocamera legge il documento dal vivo con VisionKit, il riquadro dei documenti e il riconoscimento del testo.
- I campi riconosciuti si illuminano sul foglio, uno alla volta.
- Il testo letto arriva al Mac attraverso il ponte cifrato. Lì `LetturaDocumenti` ed `EstrattoreDocumento` ne ricavano i dati della posizione: contraente, premio, capitale, decorrenza, tipo, compagnia.
- Poi «Aggiungi a Posizioni» del cliente e «Confronta» con una soluzione, usando il confronto che esiste già.
- Va aggiunta la descrizione d'uso della fotocamera in `Supporto/iOS/Info.plist`.
- Sul Mac senza iPhone collegato, il pulsante propone di trascinare una foto o un PDF.

## Giro 6 — Rispetto alle famiglie come la sua, allenamento OCF
**Rispetto alle famiglie come la sua**, in Analisi 360 come nel template.
- Il cliente confrontato con le famiglie della sua età e del suo reddito su quattro voci: risparmio, patrimonio finanziario, protezione, previdenza complementare. Ogni voce ha la barra della distribuzione e la frase in chiaro.
- **I dati** vengono dall'Indagine sui bilanci delle famiglie italiane della Banca d'Italia: tabelle aggregate per età e reddito, incluse nell'app come file e aggiornabili da Impostazioni. Niente internet.
- **Non inventare statistiche.** Prepara il formato del file e il caricamento, poi dimmi quali tabelle servono e da dove scaricarle: le preparo io o le recuperi tu, se puoi raggiungere il sito. Finché mancano, la vista dice «dati di prova».

**Allenamento OCF**, in Studio come nel template.
- **La preparazione:** l'anello complessivo, le materie con la percentuale e la data dell'esame.
- **Le domande** con la correzione animata e la spiegazione. Il ripasso torna sugli argomenti sbagliati a intervalli: 1, 3 e 7 giorni, poi di più.
- **Il caso vero:** per ogni domanda Prisma può proporre un caso dei miei clienti. Per esempio, una domanda sulla gestione separata apre una polizza rivalutabile di un cliente.
- **Da dove vengono le domande:**
  - le scrivo io, o le prepara Eve dai miei appunti, e le importo da un file CSV o JSON di cui mi dai il formato;
  - nel repository metti solo poche domande di esempio scritte da te, mai testi copiati dal manuale;
  - tutto il resto sta nel mio archivio locale.

## Giro 7 — Prisma conosce il mercato
È l'unica funzione che esce su internet. Per questo:
- **Un interruttore** «Dati di mercato» in Impostazioni, **spento di base**.
- **Escono solo** gli ISIN e le richieste di dati pubblici: mai nomi, importi, portafogli o altri dati dei clienti. Nessun servizio con account o chiave. Usa URLSession, niente librerie.
- **CLAUDE.md** va aggiornato con questa eccezione, scritta in modo stretto: solo dati di mercato pubblici, solo con l'interruttore acceso.
- **Le fonti:** prima di collegarne una, proponimi le fonti gratuite che pensi di usare per indici, tassi, inflazione e quote dei fondi per ISIN, con pregi e limiti, e aspetta la mia scelta. Per ogni dato serve anche l'inserimento a mano e l'importazione da CSV, per quando una fonte non c'è o smette di funzionare.

L'app Mercato, come nel template:
- la striscia di indici e tassi con le mini linee;
- la ricerca per ISIN, con «nei portafogli di N clienti»;
- «Chi è toccato oggi»: gli eventi di mercato incrociati con le posizioni vere dei clienti, con «Prepara un messaggio»;
- gli avvisi con le soglie decise da me: calo dal massimo, distanza dal riferimento, cedola in arrivo;
- i valori aggiornati entrano nell'aggiornamento delle posizioni che esiste già, sempre con la data e la fonte.

## Giro 8 — Prisma ovunque
iPhone e iPad con una copia propria e cifrata dei dati, per lavorare anche con il Mac spento.
- **Prima una prova di fattibilità**, e scrivimi l'esito prima di andare avanti. Senza Xcode e con la firma ad-hoc non ci sono contenitori iCloud propri. La strada è un file cifrato in una cartella di iCloud Drive scelta da me, come già per i backup: sul Mac con un segnalibro di sicurezza, su iPhone e iPad con il selettore dei documenti.
- **Il contenuto** è cifrato con una chiave mia, come i backup protetti. Senza la chiave, il file in iCloud è illeggibile. Nessun server.
- **Le modifiche** fatte su iPhone o iPad senza il Mac (note, attività, dati raccolti, schede del copilota, posizioni inquadrate) si registrano come elenco di modifiche e si uniscono sul Mac al ritorno. Se la stessa cosa è cambiata in due posti, me lo chiede invece di decidere da solo.
- **Impostazioni › iPhone e iPad**, come nel template: lo schema animato Mac → iCloud Drive → iPhone, «Sincronizza ora», le modifiche in attesa. Sull'iPhone, l'etichetta «Senza Mac · copia cifrata».
- Aggiungi una prova nel workflow: due copie che modificano cose diverse e la stessa cosa, poi l'unione.

## Giro 9 — Controllo finale
- Percorri tutte le istantanee nuove, in chiaro e in scuro, su Mac, iPhone e iPad, e confrontale con il template.
- Misura la fluidità con la prova già presente: non deve peggiorare rispetto ad «Acqua viva».
- Controlla che backup e ripristino comprendano tutti i dati nuovi: parcelle, raccomandazioni, messaggi, eventi della vita, domande OCF, impostazioni di Studio e di Mercato.

## Alla fine
Quando tutti i giri sono uniti e verdi, apri la pull request verso main con il riepilogo della versione e uniscila quando è verde. Poi scrivimi, senza raccontare i passaggi:
- cosa c'è di nuovo, in poche righe per giro;
- tutto quello che aspetta un dato da me (aliquote, regime fiscale, tabelle della Banca d'Italia, fonti di mercato, domande OCF) e dove lo inserisco;
- dove ti sei allontanato dal template e perché;
- la lista di cosa devo provare io: il copilota in un incontro vero, la fotocamera dell'iPhone, la sincronizzazione con il Mac spento, il file XML con il commercialista.
