# Prisma istantaneo: come stiamo e che cosa propongo

*Giro 0 di «Prisma istantaneo», 7 novembre 2026. Questo documento non cambia nulla: serve a decidere. Le domande per te sono in fondo.*

## In breve

- Prisma oggi è lenta in alcuni punti per **due motivi di costruzione**, non per un singolo calcolo sbagliato: tutta l'app guarda **un solo grande oggetto** con dentro tutti i dati, e l'archivio è **un solo file** che si legge e si riscrive intero.
- Ho misurato su un'app di prova che cosa cambia dividendo lo stato: una modifica a una riga su 200 fa ridisegnare **280 viste** come oggi, **1 vista** con lo stato diviso. Vale sia con la strada nuova di Apple (macOS 14) sia con quella vecchia (macOS 13).
- Ti chiedo due sì o no: **passare a macOS 14** (proposta A) e **cambiare il formato dell'archivio** (lettura e salvataggio a pezzi).

## Come misurare sul tuo Mac

In **Impostazioni › Strumenti › Velocità** ci sono due pulsanti nuovi:

- **Misura la velocità su questo Mac**: fa girare la stessa prova della fluidità della build, con i clienti di prova (5 e poi 200), in un processo a parte. Il tuo archivio non si tocca: per tutta la prova Prisma guarda in una cartella vuota al posto della sua, e alla fine controlla che sia rimasta vuota. Dura alcuni minuti (sul mio giro circa 6), intanto puoi lavorare. Alla fine mostra la tabella (azione, tempo del lavoro di Prisma sul thread principale, prima volta) e «Copia» copia la tabella completa.
- **Misura Vera**: libera e ricarica Qwen, poi gli fa due volte la stessa domanda generica (nessun dato dei clienti). Dice quanto ci mette a **caricarsi**, a dire la **prima parola** (appena caricato e già pronto) e quante **parole al secondo** scrive. Se Ollama non è aperto, o manca il modello, lo dice.

La prova della fluidità ha anche le azioni nuove di Luce: aprire la Sala, il prisma di luce, Pratiche, il radar e la Biblioteca.

## Come stiamo

Numeri presi sul tuo Mac (M1, 8 GB) con **la versione installata** (release, commit cec9d4c), il 7 novembre 2026 sera, con il Mac occupato anche da un'altra sessione. «Aggiornamento» è il lavoro di Prisma sul thread principale per un'azione (stato, ricalcolo delle viste, impaginazione), mediana di più giri. Sono quasi uguali a quelli della versione di sviluppo: il tempo se ne va nella struttura, non nel compilatore.

| Azione | 5 clienti | 200 clienti | Limite a cui puntiamo |
|---|---:|---:|---:|
| Un tasto in una nota | 23 ms | 70 ms | 16 ms |
| Aprire Posizioni | 211 ms | 411 ms | 100 ms |
| Aspetto scuro | 372 ms | 698 ms | — |
| Avvio (stato, dati, prima impaginazione) | 265 ms | 469 ms | 1 s fino alla scrivania |
| Ricerca ⌘K (apertura) | 68 ms | 107 ms | 30 ms per tasto |
| Aprire la Sala | 106 ms | 97 ms | 100 ms |
| Aprire il prisma di luce | 94 ms | 147 ms | 100 ms |
| Aprire Pratiche | 51 ms | 88 ms | 100 ms |
| Aprire il radar | 79 ms | 331 ms | 100 ms |
| Tornare dal radar | 185 ms | 491 ms | 100 ms |
| Aprire la Biblioteca | 34 ms | 77 ms | 100 ms |

Memoria alla fine della prova con 200 clienti: **339 MB** di impronta (266 MB residenti), sotto l'obiettivo di 400 MB.

I punti peggiori sono quelli che toccano tutti i clienti: aprire Posizioni, il radar e il ritorno dal radar con 200 clienti, e il cambio d'aspetto. Il radar migliora già con i motori in cache (sezione più sotto), senza aspettare la scelta A o B.

L'archivio con 200 clienti (prova di carico, versione di sviluppo): **2,6 MB** di JSON, **0,52 s** per scriverlo e **0,51 s** per leggerlo.

### Il motivo principale

1. **Un solo oggetto osservato da tutti.** `StatoShell` tiene tutto: i dati dell'archivio (`dati`, un unico valore con clienti, posizioni, agenda, note, impostazioni…) e altre 89 proprietà pubblicate (app aperte, schede, pannelli…). Nel codice ci sono **324 viste** che lo osservano. In SwiftUI, quando un oggetto di questo tipo (`ObservableObject`) cambia anche in un solo campo, **tutte** le viste che lo osservano si rivalutano. Un tasto in una nota rivaluta così tutte le app aperte e i widget, anche quelli che la nota non la mostrano.
2. **Un solo file per l'archivio.** All'avvio si legge tutto `archivio.json` prima di mostrare i dati; a ogni salvataggio si riscrive tutto. Il salvataggio è già in background e già accorpato (parte 0,8 s dopo l'ultima modifica), quindi non blocca i tasti, ma con 200 clienti ogni salvataggio codifica e scrive 2,6 MB anche per una virgola.
3. **Le cache dei motori si azzerano per tutti.** Le cache dei calcoli (`DerivatiDati`, portafoglio, Posizioni, Analisi 360) ci sono già, ma sono legate a un unico contatore: quando cambia un cliente, si ricalcolano tutti.

## La misura vera: un'app di prova

Fuori dal repository (`/private/tmp/claude-501/prova-observation/`) ho scritto un piccolo programma per il Mac che imita la situazione di Prisma: **280 viste**, cioè 200 righe (ognuna mostra nome, un importo e una data) e 80 «widget» che mostrano un altro campo. Poi cambio **un campo di una sola riga** (come un tasto in una nota), 200 volte, e conto quante viste rivalutano il corpo e quanto tempo passa (modifica + impaginazione, versione di sviluppo, macOS 27, il tuo M1).

| Variante | Viste rivalutate per modifica | Tempo, mediana (3 giri) |
|---|---:|---:|
| 1. Un solo `ObservableObject` (come oggi) | **280** | 2,3 · 2,5 · 5,0 ms |
| 2. `@Observable` (macOS 14), ma i dati restano un solo valore | **200** | 2,5 · 4,4 · 7,0 ms |
| 3. `@Observable` a pezzi: ogni riga è un oggetto (proposta A) | **1** | 1,8 · 1,9 · 4,9 ms |
| 4. `ObservableObject` a pezzi: oggetti piccoli (proposta B) | **1** | 1,8 · 2,1 · 4,9 ms |
| 5. Un solo `ObservableObject`, ma le viste ricevono solo i valori | **2** | 2,2 · 4,3 · 7,7 ms |

Che cosa dicono:

- **Il numero che conta è quello delle viste**, e non lascia dubbi: da 280 a 1. I tempi dell'app di prova sono piccoli perché le sue viste sono semplicissime, e oscillano perché il Mac era occupato da altri lavori; in Prisma ogni vista fa molto di più (lo dice il tasto nella nota: 50-69 ms), quindi è lì che 280 → 1 si sente.
- **Passare a `@Observable` da solo non basta** (variante 2: 200 viste). Se i dati restano un unico valore, ogni modifica tocca quel valore e tutte le viste che lo leggono si rivalutano. Serve **dividere i dati** in pezzi, con qualunque strada.
- **Le due strade divise si equivalgono nella misura** (varianti 3 e 4: 1 vista). La differenza sta nel lavoro per arrivarci e in quanto è facile sbagliare dopo.
- La variante 5 è un passo intermedio possibile anche subito: le viste ricevono solo i valori che mostrano, e SwiftUI salta quelle che non cambiano.

## Proposta A: il framework Observation (macOS 14)

**Che cosa vuol dire.** `StatoShell` e i dati diventano oggetti `@Observable`, divisi per argomento (clienti, agenda, posizioni, documenti, impostazioni, finestre) e, dove serve, per singolo cliente o singola nota. Ogni vista si aggiorna solo per le proprietà che legge davvero, senza doverlo dichiarare.

- **A favore.** È la strada di Apple per il futuro; il tracciamento è automatico (una vista che legge `cliente.nome` si aggiorna solo per quello), quindi è più difficile sbagliare in seguito. Il tuo Mac ha macOS 27 e iPhone e iPad sono già a iOS 17, che lo supporta.
- **Contro.** Il minimo sale da macOS 13 a **macOS 14**: Prisma non si aprirebbe più su un Mac con macOS 13. Il tuo non è un problema; conta solo se un giorno volessi usarla su un Mac vecchio.
- **Rischi.** È un cambiamento grande: tocca quasi tutte le viste (`@EnvironmentObject` → `@Environment`, `$stato.x` → `@Bindable`). Il formato dell'archivio **non** cambia per questo (i dati si salvano allo stesso modo); cambia come sono tenuti in memoria. Va fatto a tappe, con la prova della fluidità e le istantanee a ogni tappa.

## Proposta B: lo stato diviso in oggetti piccoli (resta macOS 13)

**Che cosa vuol dire.** Resta `ObservableObject`, ma `StatoShell` si divide in oggetti piccoli per argomento (lo stesso elenco della A), e ogni vista osserva solo quello che le serve. Le viste più usate ricevono solo i valori (variante 5) invece dell'oggetto intero.

- **A favore.** Nessun cambio del minimo; nella prova vale quanto la A (1 vista). Prisma ha già cominciato così: `StatoFinestre`, `StatoSala`, `StatoProvaFuoco` e altri sono già oggetti piccoli a sé.
- **Contro.** Le dipendenze vanno scritte a mano: ogni vista deve dichiarare che cosa osserva, e un errore (una vista che osserva l'oggetto sbagliato o quello grande) riporta il problema senza che nessuno se ne accorga. Per i singoli clienti o le singole note servono oggetti a parte, con più codice di collegamento.
- **Rischi.** Simili alla A per dimensione del lavoro; un po' più di codice da mantenere dopo.

**La mia raccomandazione: la A**, perché a parità di risultato misurato è meno fragile nel tempo e il costo (macOS 14) per te è nullo. In tutti e due i casi il lavoro comincia dalle parti che si vedono di più: le note (il tasto), Posizioni, la scrivania e i widget, il radar.

## L'archivio: lettura a pezzi e salvataggio per parti

**Oggi:** un file `archivio.json`, letto tutto all'avvio e riscritto tutto (in background, accorpato) a ogni modifica.

**Proposta.** Una cartella con un file per parte, accanto all'attuale:

- un piccolo **indice** (versione, impostazioni, elenco dei clienti con i dati della scrivania);
- un file per **ogni cliente** (anagrafica, posizioni, documenti collegati, note del cliente);
- file a sé per **agenda**, **attività**, **conversazioni di Vera** e le altre parti grandi.

All'avvio si legge subito l'indice e quello che serve alla scrivania; il resto arriva dopo in background, senza bloccare. Il salvataggio scrive **solo i file cambiati** (una nota di un cliente = un file piccolo), sempre accorpando le modifiche ravvicinate.

- **Compatibilità.** I vecchi archivi e i vecchi backup si aprono come oggi: Prisma riconosce `archivio.json` e lo converte la prima volta, tenendone una copia. I backup comprendono la cartella intera. `--prova-backup` va aggiornata per provare vecchio → nuovo, nuovo → backup → ripristino, e un archivio a metà (un file mancante o rovinato non deve far perdere gli altri).
- **Rischi.** È la parte più delicata: tocca i dati veri. Serve scrivere i file in modo atomico e tenere coerente l'indice con i file dei clienti; «Prisma ovunque» (l'istantanea cifrata) va adattato.
- **Si può fare prima un passo piccolo**, senza cambiare formato: la lettura in background all'avvio c'è già (`AvvioArchivio`); si può già smettere di riscrivere quando cambia solo lo stato dell'interfaccia (lo fa già il contatore dei dati) e allungare l'accorpamento durante la scrittura continua.

## I motori in cache

Oggi le cache esistono ma hanno un solo contatore per tutto l'archivio. **Proposta:** un contatore **per cliente**; i motori più usati (portafoglio, Analisi 360, obiettivi, attenzioni, mossa del giorno, posizioni, radar) calcolano fuori dal thread principale e ricordano il risultato del cliente finché i suoi dati non cambiano. Quando cambia un cliente, si ricalcola solo lui; le viste mostrano l'ultimo valore valido e poi il nuovo, con l'animazione del numero. Questo lavoro non dipende dalla scelta A o B e non cambia l'archivio. Rischio principale: una cache che non si azzera quando dovrebbe (numeri vecchi): va provata in `--prova-calcoli` cliente per cliente.

## Vera senza attese (da verificare con «Misura Vera»)

Leggendo il codice ho notato una cosa da verificare con il pulsante nuovo: il **precaricamento** di Qwen manda a Ollama solo il nome del modello, mentre le risposte di Vera chiedono una finestra di 32.768 token. Se Ollama ricarica il modello quando cambia la finestra, la prima domanda dopo il precaricamento lo ricarica da capo. «Misura Vera» lo mostra: se la «prima parola, appena caricato» è molto più lenta della «prima parola, già pronto», è così, e la correzione è mandare le stesse opzioni anche nel precaricamento. Non l'ho cambiato in questo giro: un'altra sessione sta lavorando su Vera.

## La stima del lavoro

| Lavoro | Dimensione | Note |
|---|---|---|
| Stato diviso, proposta A | grande: 3-4 giri | a tappe: note e scrivania, Posizioni e radar, le altre app, iPhone e iPad |
| Stato diviso, proposta B | grande: 3-4 giri | come la A, più codice di collegamento |
| Archivio a pezzi | medio-grande: 2 giri | più la prova di backup e la conversione |
| Motori in cache per cliente | medio: 1 giro | indipendente dalle altre scelte |
| Precaricamento di Vera con le stesse opzioni | piccolo | dopo «Misura Vera» e d'accordo con la sessione di Vera |

Ogni tappa si chiude con la tabella prima e dopo (prova della fluidità sul runner e sul tuo Mac).

## Le domande per te

1. **Passiamo a macOS 14 e usiamo il framework Observation (proposta A)?** Sì / No. *(Con il no si fa la proposta B, restando su macOS 13.)*
2. **Cambiamo il formato dell'archivio in una cartella a pezzi, con la conversione automatica dei vecchi archivi e dei vecchi backup?** Sì / No. *(Con il no si resta su un file unico, migliorando solo lettura e salvataggio dove si può.)*

## Tappa 1 della proposta A (8 novembre 2026, branch giro-0-observation)

Fatto: minimo macOS 14; `StatoShell` è `@Observable`; `stato.dati` è un `DatiVivi` (un campo osservato per ogni campo di
`DatiPrisma`, `istantanea` per le copie, `carica` per sostituire tutto); ogni modifica passa da `datiCambiati` (contatori
delle cache con la regola di `stessiCalcoli`, Vera, il segnale `modificheDati` per salvataggio, notifiche, promemoria e
Prisma ovunque). Il formato dell'archivio non cambia. La prova della fluidità conta ora i **body rivalutati**
(`ContaCorpi`) al posto degli `objectWillChange` di StatoShell.

Prova della fluidità, build di sviluppo, stesso Mac, «aggiornamento» (mediana). Il Mac era molto carico da altre
sessioni (carico medio 15-28): i tempi oltre il tasto nella nota oscillano più della differenza e vanno rimisurati a Mac
fermo.

| Azione | 5 clienti prima → dopo | 200 clienti prima → dopo | Corpi rivalutati (dopo) |
|---|---:|---:|---:|
| Un tasto in una nota | 31 → **3 ms** | 59 → **28 ms** | 0 (5) · 2 (200) |
| Aprire Posizioni | 462 → 218 ms | 484 → 781 ms | 15 · 12 |
| Aspetto scuro | 465 → 384 ms | 663 → 1.410 ms | 7 · 9 |
| Avvio | 868 → 322 ms | 706 → 811 ms | — |
| Aprire il radar | 93 → 172 ms | 1.577 → 564 ms | 3 · 0 |
| Tornare dal radar | 182 → 270 ms | 2.023 → 1.855 ms | 8 · 0 |

Dopo le correzioni della revisione (l'ora e il giorno osservati per le viste dei dati ricavati, le impostazioni dei
calcoli lette senza iscriversi a tutte le impostazioni, l'elenco dei confronti dai soli clienti, posizioni e
simulazioni), stessa prova l'8 novembre, aggiornamento 5 · 200 clienti: tasto in una nota 3 · 24 ms, aprire Posizioni
283 · 420 ms, aspetto scuro 348 · 517 ms, avvio 356 · 663 ms, aprire il radar 90 · 181 ms, tornare dal radar
165 · 330 ms.

Prima, ogni azione mandava 1-3 avvisi a StatoShell, e ognuno rivalutava **tutte** le viste che lo osservano (circa 300):
ora un tasto in una nota rivaluta 0-2 corpi. Resta da fare (tappa 2): dividere ancora i dati per cliente e per nota, e
guardare le viste che leggono l'archivio intero con `istantanea` nel body (Confronti, Esame OCF).


## Dopo la tappa 1 (8 novembre 2026, versione installata)

macOS 14, StatoShell con Observation, dati osservati a pezzi. «Aggiornamento», mediana, prima (7 novembre, cec9d4c) → dopo:

| Azione | 5 clienti | 200 clienti |
|---|---:|---:|
| Tasto in una nota | 23 → 3 ms | 70 → 21 ms |
| Aprire il radar | 79 → 87 ms | 331 → 184 ms |
| Tornare dal radar | 185 → 177 ms | 491 → 389 ms |
| Aspetto scuro | 372 → 355 ms | 698 → 545 ms |
| Aprire il prisma di luce | 94 → 78 ms | 147 → 95 ms |
| Aprire Posizioni | 211 → 216 ms | 411 → 403 ms |
| Avvio | 265 → 280 ms | 469 → 479 ms |

Memoria con 200 clienti: 337 MB di impronta. Aprire Posizioni e l'avvio aspettano le tappe successive (motori in cache per cliente, archivio a pezzi).
