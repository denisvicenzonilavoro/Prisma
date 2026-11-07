# Prisma «Luce» — specifica del template delle 29 novità

Fonte: `Design/template-luce.html` (template navigabile della versione «Luce», 5 novembre 2026, 2297 righe, circa 820 KB).
Specifica scritta il 6 novembre 2026. Per tutto ciò che qui non è detto valgono `Design/template-novita-specifica.md`
(«Orizzonte») e, sotto, `Design/template-apple-specifica.md` (tema Apple).

## 0. Come leggere questa specifica

### 0.1 Il template di partenza
- `Design/template-luce.html` nasce da `Design/template-novita.html` («Orizzonte»), già descritto in
  `Design/template-novita-specifica.md`, che a sua volta parte da `Design/template-apple.html`
  (`Design/template-apple-specifica.md`). **Per tutto ciò che qui non è detto vale Orizzonte, e sotto Orizzonte il tema
  Apple**: token (§1 del tema Apple), barra (§3.3), dock (§3.4), finestra (§3.5), scrivania (§3.6), notifiche (§3.8),
  tastiera (§3.10), movimento (§1.8 e §2.0).
- Il commento in testa al file elenca le 29 novità: 15 «davanti al cliente» (lista `NOV15`, righe 1778-1780) e 14 «per il
  lavoro» (lista `NOVL`, righe 2064-2066). Ogni voce dice come si apre (`apriEsp`, `vaiA`, `apriStoria`, `apriNotte`,
  `apriNuovo`, `apriNota`).
- Il file è un unico HTML/JS: va letto **a pezzi** (grep, sed, intervalli di caratteri), mai tutto insieme. La riga 474 è la
  tabella `ICONE` delle PNG in base64 (circa 380 KB) e non va mai stampata. I numeri di riga citati sono quelli del file
  del 5 novembre 2026.
- Il prisma di luce e la realtà aumentata sono disegnati nel template con shader WebGL (`FS_LUCE`, `FS_AR`): sono la
  **specifica della resa**, da portare in Metal (prisma, §2.2) e in RealityKit (realtà aumentata, §2.3).
- Le schermate di riferimento (1480×940, palco 1440×900 scalato di 1,0137, in chiaro e in scuro) sono state scattate con
  Playwright durante il lavoro (`luce/img/*.png`). **Non sono nel repository**: chi implementa le rigenera dal template
  (copia di lavoro che espone le funzioni del template su `window`, Google Fonts bloccato, `chromium.launch()`,
  `deviceScaleFactor: 1`). Gli script citati nelle sezioni (`luce/script/shot01.js`, `shot03.js`, `shot04.js`…) erano
  strumenti di lavoro e vanno riscritti allo stesso modo.

### 0.2 Le cifre sono dimostrative
Tutte le cifre, i nomi, le date, i documenti, i moduli e i testi di condizioni del template sono **dimostrativi**
(fac-simile scritti apposta). Nell'app le cifre le danno i motori di Prisma partendo dall'archivio; dove un dato manca
Prisma **non lo inventa**: lo dice, con gli stati descritti in ogni novità (sottosezione 6). Testi normativi, avvertenze,
tariffe, probabilità, moduli e regole fiscali li dà l'utente (vedi §0.5). In più punti il template fa calcoli
semplificati (un 3% fisso per la pensione, quote inventate, totali che non tornano): le sezioni li segnalano e dicono
quale motore di Prisma li sostituisce.

### 0.3 Le regole di CLAUDE.md che contano qui
- **Analisi prima di tutto**: Posizioni resta il fulcro. Le esperienze della Sala, Ruby e le app nuove servono l'analisi
  delle posizioni e dei bisogni, mai il contrario.
- **Tema Apple**: ogni schermata nuova usa `Tema.Apple` (colori chiari e scuri, carta, raggi, ombre, superfici, misure,
  caratteri) e `Tema.Apple.Moto` per tempi e curve. Vetro, acqua della scrivania, logo e colori dei canali restano come
  sono. Dove il template usa un valore che il tema non ha, la sezione propone **un token nuovo con il suo nome**, in un file
  `DesignSystem/Apple/Tema.Apple+<Parte>.swift`.
- **Movimento**: numeri contati, blocchi a cascata, anelli che si riempiono, linee che si disegnano, schede che si
  inclinano, dettaglio che nasce dalla scheda. Con «Riduci movimento» (`\.prismaCalmo`) tutto compare fermo con una
  dissolvenza di 0,15 s; nelle istantanee (`\.modoIstantanea`, `\.prismaStatoFinale`) tutto è disegnato nello stato
  finale. **Niente Timer**: animazioni di SwiftUI, `Animatable`, `TimelineView`, `Task.sleep` dentro `.task`. Il template
  in molti punti ignora `ridotto`: vale la regola di Prisma.
- **Canale sempre riconoscibile**: Alleanza in blu (#2563EB) con il logo Alleanza, indipendente in cuoio (#B06E12) con
  «Denis Vicenzoni · Consulenza finanziaria».
- **Dati in locale**: niente server, niente cloud, nessun dato dei clienti inviato a servizi esterni. Le uniche eccezioni
  già approvate sono Mercato (solo BCE ed Eurostat, interruttore spento di base) e lo spazio cifrato di «Prisma ovunque».
  **Molte novità di Luce toccano questa regola** (file e video dati al cliente, WhatsApp, mappe, fotocamera, notifiche,
  lavoro di notte, nota vocale): nessuna si costruisce prima della decisione dell'utente al §0.5.
- **Ruby** (prima Eve): unico motore Qwen in locale (Ollama su 127.0.0.1). I calcoli li fa Prisma, Qwen racconta e
  spiega. Prompt, istruzioni e schemi nuovi vanno in `Ruby/` (`Ruby/Istruzioni/`, `Ruby/Schemi/`, `Ruby/Esempi/`).
  iPhone e iPad usano Qwen del Mac solo dal ponte cifrato in rete locale.
- **MacBook Pro M1 con 8 GB**: codice leggero (Qwen occupa 3-3,5 GB; video, shader, indici e lavoro di notte vanno
  pensati per la memoria).
- **Target macOS 13** (iOS 17 per il pacchetto): le API più recenti si proteggono con `#available` e un ripiego; il vetro
  di macOS 26 con `#if compiler(>=6.2)`. Shader solo compilati a runtime (`makeLibrary(source:)`), niente file `.metal`.
- **Nessuna dipendenza esterna senza chiedere**: nessuna novità ne chiede una. Playwright serve solo nell'ambiente di
  sviluppo (icone) e Node solo nel workflow (prova del lettore del Prisma del cliente), se approvati.
- **Build e prove**: una build verde per ogni push; `Prisma --istantanee`, `--prova-backup` e `--prova-ovunque` vanno
  aggiornate con ogni campo nuovo dell'archivio. Le istantanee nuove vanno aggiunte alla pagina online delle anteprime.
- **Dati di prova**: i 5 clienti del template e i 30 fittizi caricabili da Impostazioni. Ogni novità ha i suoi dati di
  prova in `Dati/DatiDemo.swift` e `Dati/ClientiFittizi.swift`, segnati con «dati di prova», mai nell'archivio reale.

### 0.4 Come sono numerate le sezioni
- §1 è la parte comune di Luce (pannello Novità, app nuove e dock, la Sala, componenti condivisi).
- §2-§9 sono le parti di lavoro, nell'ordine in cui sono state scritte. Dentro ogni sezione le novità sono numerate
  §N.1, §N.2… e le otto sottosezioni sono sempre le stesse: «1. Cosa si vede», «2. Misure e stile», «3. Movimento»,
  «4. Interazioni», «5. Mappa verso Prisma», «6. Dati che l'utente deve dare e stati vuoti», «7. Istantanee da
  aggiungere», «8. Regole di CLAUDE.md toccate e decisioni» (per esempio §5.1.5 è la mappa verso Prisma del Territorio).
- **Un rimando come «§4.8» scritto dentro una sezione vale per quella sezione** (nelle bozze ogni parte era numerata da
  sola); da fuori si scrive con il numero della sezione davanti (per esempio §1.4.8). Anche le sigle locali delle
  decisioni (D2, D-C10, D4.1, D-P1, «Decisione 7 della notte») valgono dentro la loro sezione; il numero unico di ogni
  decisione è quello della tabella del §0.5.
- Nel testo delle sezioni i rimandi ai file di lavoro vanno letti con questa tabella: «la parte comune» o `01-comune.md` =
  §1, «la parte 02» o `02-sala-luce.md` = §2, e così via fino a «la parte 09» = §9.

| § | File di lavoro | Parte |
|---|---|---|
| 1 | 01-comune | Parte comune della versione Luce |
| 2 | 02-sala-luce | Sala: il Prisma del cliente, il prisma di luce, la realtà aumentata |
| 3 | 03-sala-racconti | Sala: lettera dal futuro, film del piano, disegna il tuo futuro, capsula del tempo |
| 4 | 04-sala-giochi | Sala: gioco del rischio, giornata della pensione, lancia l'anno, quanto vale avermi accanto |
| 5 | 05-relazione | Territorio, la tua settimana e il tuo anno, la palestra della trattativa, i traguardi festeggiati |
| 6 | 06-notte-voce-spese | Stanotte Prisma ha lavorato, la nota vocale, chilometri spese e scadenze |
| 7 | 07-pratiche | App Pratiche: proposta, moduli, dopo la firma, sinistri |
| 8 | 08-biblioteca-analisi | Biblioteca, lo smontaggio, il radar del portafoglio |
| 9 | 09-clienti-campagne | Clienti: nuovo cliente, potenziali e passaparola, imprenditori; Messaggi: campagne |

**Le 29 novità e dove sono** (controllate una per una con `NOV15` e `NOVL` del template: ci sono tutte).

Davanti al cliente · 15 (`NOV15`)

| # | Novità | Come si apre nel template | Sezione |
|---|---|---|---|
| 1 | Il Prisma del cliente | `apriEsp('prisma')` | §2.1 |
| 2 | Il tuo territorio | `vaiA('territorio')`, vista Oggi | §5.1 |
| 3 | La lettera dal futuro | `apriEsp('lettera')` | §3.1 |
| 4 | Il film del piano | `apriEsp('film')` | §3.2 |
| 5 | Disegna il tuo futuro | `apriEsp('disegna')` | §3.3 |
| 6 | La tua settimana, il tuo anno | `apriStoria('settimana')` | §5.2 |
| 7 | La palestra della trattativa | `vaiA('studio')`, scheda Palestra | §5.3 |
| 8 | Il prisma di luce | `apriEsp('luce')` | §2.2 |
| 9 | La capsula del tempo | `apriEsp('capsula')` | §3.4 |
| 10 | I traguardi festeggiati | `vaiA('messaggi')`, primo traguardo | §5.4 |
| 11 | Il gioco del rischio | `apriEsp('rischio')` | §4.1 |
| 12 | Una giornata della pensione | `apriEsp('giornata')` | §4.2 |
| 13 | Lancia l'anno | `apriEsp('dadi')` | §4.3 |
| 14 | Quanto vale avermi accanto | `apriEsp('valore')` | §4.4 |
| 15 | La realtà aumentata | `apriEsp('ar')` | §2.3 |

Per il tuo lavoro · 14 (`NOVL`)

| # | Novità | Come si apre nel template | Sezione |
|---|---|---|---|
| 1 | Stanotte Prisma ha lavorato | `apriNotte()` | §6.1 |
| 2 | La proposta si costruisce da sola | `vaiA('pratiche')`, scheda Proposta | §7.1 (parte comune dell'app in §7.0) |
| 3 | Compila da solo | `vaiA('pratiche')`, scheda Moduli | §7.2 |
| 4 | Le pratiche dopo la firma | `vaiA('pratiche')`, scheda Dopo la firma | §7.3 |
| 5 | Il sinistro come una spedizione | `vaiA('pratiche')`, scheda Sinistri | §7.4 |
| 6 | Trova la pagina | `vaiA('biblioteca')` | §8.1 |
| 7 | Lo smontaggio | `vaiA('posizioni')`, vista Smontaggio | §8.2 |
| 8 | Il radar del portafoglio | `vaiA('posizioni')`, vista Radar | §8.3 |
| 9 | Le campagne | `vaiA('messaggi')`, vista Campagne | §9.4 |
| 10 | Nuovo cliente in 10 secondi | `vaiA('clienti')` poi `apriNuovo()` | §9.1 |
| 11 | Potenziali clienti e passaparola | `vaiA('clienti')`, vista Passaparola | §9.2 |
| 12 | I clienti imprenditori | `vaiA('clienti')`, dossier › L'azienda | §9.3 |
| 13 | La nota vocale | `vaiA('incontri')` poi `apriNota()` | §6.2 |
| 14 | Chilometri, spese e scadenze | `vaiA('studio')`, scheda Spese | §6.3 |

In più, la parte comune (§1) descrive quattro «novità comuni» che le 29 presuppongono: il pannello «✦ Novità» a due
gruppi (§1.1), le quattro app nuove Territorio, Pratiche, Sala e Biblioteca nel dock e sulla scrivania (§1.2), la Sala
come cornice delle 11 esperienze (§1.3) e i componenti riusati (§1.4).

### 0.5 Decisioni per l'utente
Tutte le domande delle sezioni sono raccolte qui in una tabella unica, senza doppioni (dove due sezioni facevano la
stessa domanda c'è una riga sola con tutte e due le sezioni). Sono in ordine di importanza: prima ciò che esce dal Mac o
tocca la privacy, poi i testi e i dati che Prisma non può inventare, poi le regole di calcolo, poi architettura, prove e
grafica. La colonna «Proposta» è la raccomandazione: dove l'utente non dice altro, si procede così. Il dettaglio di ogni
decisione resta nella sottosezione 8 della novità indicata.

**A. Ciò che esce dal Mac verso il cliente o verso terzi**

| N. | Tema | Domanda | Proposta | § |
|---|---|---|---|---|
| 1 | Regola generale degli invii | Video, biglietti, file e messaggi per il cliente possono partire verso WhatsApp, Mail, Messaggi, AirDrop? | Prisma non spedisce mai da solo: prepara il contenuto e apre il foglio di condivisione del sistema (sul Mac `NSSharingServicePicker`, da aggiungere); sceglie e spedisce il consulente. Niente numero passato a WhatsApp, niente `wa.me`. Messaggi, Mail e AirDrop sono le vie normali; WhatsApp solo dal foglio di condivisione, con un avviso alla prima volta e il consenso del cliente per WhatsApp segnato nel dossier | §2.1, §3.2, §5.4, §7.4, §9.4 |
| 2 | Il Prisma del cliente esce dal Mac | Un file cifrato con obiettivi, linea della vita, lettera, film ed eventualmente posizioni esce dal Mac perché lo spedisce il consulente: si approva come eccezione? | Sì, alle condizioni dei PDF protetti già in Prisma: cifrato, password non conservata, spedizione fatta dal consulente, traccia nel dossier. Nuova riga in CLAUDE.md (Dati e privacy) | §2.1 |
| 3 | Il Prisma del cliente: formato | Quick Look dell'iPhone quasi certamente non esegue JavaScript negli allegati HTML, e WebCrypto c'è solo in un contesto sicuro (molti visori di Mail, WhatsApp e Android non lo danno). HTML, PDF protetto o tutti e due? | Prima una prova su iPhone e Android veri. PDF protetto sempre (con una tabella al posto del cursore); l'HTML in più solo se la prova passa, con il lettore che si accorge del limite e dice «Apri questo file con Safari o Chrome» | §2.1 |
| 4 | Il Prisma del cliente: password | Il file si può provare offline senza limite: quale regola per la password? Va nello stesso messaggio? | Tre parole e un numero (circa 8×10¹¹ combinazioni), minimo 12 caratteri se scritta a mano, mai ricavata dai dati del cliente, mai conservata, mai nello stesso messaggio del file | §2.1 |
| 5 | Il Prisma del cliente: nome del file | «Il-Prisma-di-Giulia.html» lascia il nome di battesimo in chiaro (anteprime, Download, iCloud del cliente). Va bene? | Tenerlo, perché il cliente riconosce il file; in alternativa «Il-tuo-Prisma.html» | §2.1 |
| 6 | Il Prisma del cliente: copia, backup, scadenza, aspetto | Si conserva nel dossier una copia leggibile di ciò che il cliente ha ricevuto (nei backup è cifrata solo se la protezione dei backup è accesa)? La scadenza «si può aprire fino al» si tiene, anche se in un file offline non si può imporre? File chiaro o segue il telefono? | Copia nel dossier (mai la password), con un promemoria nel palco quando la protezione dei backup è spenta; scadenza tenuta come invito con una frase onesta; file sempre chiaro come i documenti | §2.1 |
| 7 | Contenuti della Sala nel file del cliente | Che cosa può entrare nel file del cliente da «Aggiungi al Prisma di …» (lettera, film, prisma di luce, disegno, giornata della pensione)? La cornice della Sala manda qualcosa? | La cornice non manda nulla, prepara soltanto. Lettera solo nella versione «Con il piano»; prisma di luce come immagine ferma; giornata solo nelle due modalità ferme con le cifre di oggi e la nota approvata, senza importi delle scene che il cliente non ha scritto con il consulente | §1.3, §2.2, §3.1, §4.2 |
| 8 | Il film del piano esce dal Mac | Il video ha il nome del cliente e le cifre del suo piano. Si approva come contenuto dato al cliente? Dove resta? | Sì, con il foglio di condivisione (decisione 1), pulsante «Condividi il video…». Il video si conserva come Documento del cliente (circa 10 MB, nei backup) | §3.2 |
| 9 | Biglietto dei traguardi | Il biglietto con il nome (e forse una cifra del patrimonio) può partire, e dove nasce il file? | Lo spedisce il consulente dal foglio di condivisione; interruttore «Mostra la cifra» spento di base; il PNG nasce in una cartella temporanea dell'app e si cancella dopo la condivisione o alla chiusura, mai in Download; «Salva su file» solo se lo sceglie il consulente | §5.4 |
| 10 | Sinistri: lo stato «in tempo reale» per il cliente | Uno stato che si aggiorna da solo sul telefono del cliente richiede un server: come lo vede il cliente? | Niente tempo reale: un messaggio preparato da Prisma e mandato dal consulente, oppure, se acceso per quel cliente, un blocco «Il tuo sinistro» nel file «Il Prisma di …». «Così lo vede …» resta un'anteprima sul Mac. La frase della voce Novità cambia di conseguenza | §7.4 |
| 11 | Sinistri: cosa c'è nell'aggiornamento al cliente | Che cosa contiene il messaggio (iMessage, SMS, Mail)? | Titolo senza dati sanitari, fase, ultimo fatto riletto dal consulente, data e nome del consulente; niente referti, diagnosi, numero di polizza né importi se non scelti | §7.4 |
| 12 | Sollecito alla compagnia | Una mail con i dati del sinistro alla compagnia è un invio a terzi: si fa? | Bozza in Mail all'indirizzo scritto dall'utente, con solo numero di polizza, numero di sinistro e assicurato; dove la compagnia vuole il portale, solo un'attività promemoria | §7.4 |
| 13 | Modulo compilato dato al cliente | Come esce dal Mac il modulo compilato? | Con la password dei PDF per il cliente (`ImpostazioniPDF`, `ModuloSalvaPDF`), come gli altri documenti | §7.2 |
| 14 | Pacchetto per il commercialista | Lo zip esce dal Mac per mano dell'utente: deve contenere i nomi dei clienti visitati? | No: solo date, km e numero di visite (`nomiNelPacchetto` spento di base); si salva con `NSSavePanel`, senza nessun invio | §6.3 |
| 15 | Campagne: come escono i messaggi | «Avvia la campagna» apre una bozza di Mail per ogni cliente? Il canale Messaggi passa da iMessage o dall'operatore: va bene? | Le bozze nascono in Prisma (in Messaggi) e si aprono una alla volta («Apri la prossima»; «Apri tutte» chiede conferma oltre 5). Spedisce sempre l'utente, un messaggio per persona, da Mail o dall'app Messaggi. Niente WhatsApp né altri servizi in questo giro | §9.4 |
| 16 | Campagne e consenso commerciale | Chi non ha il consenso commerciale valido riceve il messaggio della campagna? | No: resta visibile nel gruppo con la pillola arancio ma non entra nell'invio; si include a mano solo con la conferma, come in Messaggi oggi | §9.4 |
| 17 | Passaparola: il momento giusto per chiedere | Con quale regola Prisma propone di chiedere una presentazione? | Un traguardo o una firma negli ultimi 7 giorni, consenso commerciale valido, nessuna richiesta negli ultimi 180 giorni; messaggio commerciale che scrive il fatto, mai uno stato d'animo | §9.2 |
| 18 | «Quanto vale avermi accanto»: dove va | Resta nel prospetto del riesame per il consulente, o diventa una pagina PDF data al cliente? | Solo nel prospetto per il consulente; «Metti nel riesame» facoltativo, mai un invio automatico | §4.4 |
| 19 | Frasi del pannello Novità | Le frasi «da mandare su WhatsApp», «anche per il cliente», «in un file», «dall'iPhone», «la mattina trovi tutto pronto» promettono uscite che le decisioni potrebbero escludere | Ogni frase (`NovitaLuce.frase`) segue la decisione presa nella sua sezione: mai una promessa che Prisma non mantiene (per esempio «Un minuto da mostrare dopo l'incontro» se WhatsApp non è accettato) | §1.1 |

**B. Fotocamera, microfono, posizione, mappe, servizi Apple, notifiche e lavoro in background**

| N. | Tema | Domanda | Proposta | § |
|---|---|---|---|---|
| 20 | Territorio: mappa e geocodifica | Come si mettono i clienti sulla mappa senza far uscire gli indirizzi? | Tutto in locale: tabelle di comuni e CAP con le coordinate dentro Prisma (`Risorse/Territorio`), clienti dello stesso comune distribuiti in modo deterministico, posizione a mano per la via, fondo disegnato in Canvas con i soli nomi. Nessuna richiesta di rete. Esclusa la geocodifica di Apple (gli indirizzi escono); MapKit solo come sfondo sarebbe un'eccezione a parte | §5.1 |
| 21 | Mappe e posizione del dispositivo | Si potrà aprire il giro in Mappe (Apple o Google) o usare CoreLocation sull'iPhone? | No nel primo giro: aprire Mappe consegna gli indirizzi all'app e ai suoi server; CoreLocation è un servizio Apple con permesso. Solo posizione a mano. Nella nota vocale niente posizione, CoreMotion o CarPlay | §5.1, §6.2 |
| 22 | Distanze, minuti e km senza servizi di percorso | Bastano km stimati (linea d'aria × 1,3, velocità medie) per il giro, la partenza consigliata della notte e Studio › Spese? | Sì: stima dichiarata con fattore e velocità modificabili; km andata e ritorno per cliente scritti una volta dall'utente e correggibili giro per giro per il rimborso. Niente MapKit/MKDirections: senza una scelta esplicita la carta della notte non mostra né ora di partenza né km | §5.1, §6.1, §6.3 |
| 23 | Fotocamera e microfono della scena del telefono | Nuovo cliente (carta d'identità) e Nota vocale catturano sull'iPhone e mandano al Mac: con quale canale? | Lo stesso ponte cifrato in rete locale di Ruby e Inquadra, con i permessi dell'iPhone; nessuna immagine del documento salvata, nessun audio registrato né fuori dalla rete locale; trascrizione e lettura sul dispositivo (Vision, riconoscimento vocale) | §1.4, §6.2, §9.1 |
| 24 | Nuovo cliente: dove si legge la carta | Solo iPhone con il ponte, anche foto e PDF trascinati sul Mac, o Continuity Camera? | iPhone e iPad con il ponte, più foto e PDF trascinati sul Mac (Vision in locale). Niente Continuity Camera in questo giro | §9.1 |
| 25 | Nuovo cliente: avviso sul Mac | Quando arriva una carta d'identità con la scena chiusa, che avviso dà il Mac? | Solo un avviso interno a Prisma senza il nome della persona; la carta resta solo in memoria e si scarta quando Prisma si blocca o il Mac va a riposo | §9.1 |
| 26 | Realtà aumentata: fotocamera e permesso | Si approva la fotocamera davanti al cliente, cambiando `NSCameraUsageDescription` (oggi «solo per inquadrare polizze e documenti»)? | Sì, immagini solo in memoria sul dispositivo; testo nuovo del permesso e commento in testa a `Supporto/iOS/Info.plist` aggiornati | §2.3 |
| 27 | Realtà aumentata: lo scatto | Lo scatto riprende la stanza del cliente: cosa si salva e come arriva al Mac? Anche dal giornale di Prisma ovunque? | Di base solo il cristallo su fondo neutro; foto completa solo con conferma; mai nel Rullino; al Mac solo con la rete locale del tavolo, mai dal giornale di Prisma ovunque (sarebbe un dato nuovo su iCloud: decisione a parte con `--prova-ovunque`) | §2.3 |
| 28 | Realtà aumentata: RealityKit e ARKit | RealityKit sul telefono richiede ARKit e la fotocamera, solo su iOS. Si accetta? | Sì: sono framework di sistema, nessuna dipendenza esterna; `ARView` in `UIViewRepresentable` (iOS 17, niente `RealityView`), ripiego `.nonAR` con tavolo virtuale | §1.4, §2.3 |
| 29 | Notifiche del Mac | Capsula pronta, traguardo, pratica ferma, carte della notte, storia del lunedì: solo nel pannello Notifiche di Prisma o anche come notifiche di macOS (`PromemoriaMac`), che compaiono sullo schermo bloccato? | Di base solo il pannello interno di Prisma. Le notifiche di sistema solo con un interruttore spento di base per ciascuna funzione, con un testo generico senza nomi né cifre («Una capsula del tempo è pronta», «Stanotte ho preparato 8 cose», «La tua settimana è pronta») | §3.4, §5.2, §5.4, §6.1, §7.3 |
| 30 | Stanotte: quando gira | Il MacBook di notte dorme e Prisma non può svegliarlo: come si fa il lavoro della notte? E se non si accetta, cosa diventa il pulsante «☾ Stanotte»? | Lavoro nella finestra serale (22-6) solo con il Mac acceso, alla corrente e Prisma aperto (`NSBackgroundActivityScheduler`); se la notte salta, al mattino «Prepara adesso». Niente `pmset` né `SMAppService` salvo scelta dell'utente. Se il lavoro notturno non è accettato il pulsante diventa «Stamattina» (carte preparate all'apertura) o sparisce | §1.2, §6.1 |
| 31 | Stanotte: cosa fa «Approva» | Approvare una carta può mandare qualcosa al cliente o entrare nel dossier? La notte va in rete? | Non manda mai nulla: le bozze restano in Messaggi, il fascicolo va nei Documenti, ogni approvazione si annulla. Le carte si aprono da sole una volta al mattino, mai in modalità cliente. La notte non va mai in rete, nemmeno per Mercato | §6.1 |
| 32 | Nota vocale: audio e modelli della voce | Si conserva l'audio? Il riconoscimento sul dispositivo scarica l'italiano dai server Apple (`AssetInventory`): va bene? | Audio mai registrato né salvato, riconoscimento solo sul dispositivo; lo scaricamento del modello come oggi per Ruby e il copilota, ma detto nella schermata («Scarico il riconoscimento dell'italiano da Apple») | §6.2 |
| 33 | Nota vocale: servizi Apple e background | Siri, App Intents o tasto Azione? Consegna in background? | Solo un'azione rapida dall'icona (`UIApplicationShortcutItem`); niente audio in background (con lo schermo bloccato l'ascolto si ferma), niente `BGTaskScheduler` | §6.2 |
| 34 | Scontrini dall'iPhone | Il ponte porta solo testo: come arriva l'immagine dello scontrino? Si usa la Fotocamera Continuity di macOS? | In questo giro solo foto o PDF trascinati sul Mac, letti con Vision. Immagini sul ponte e Continuity Camera sarebbero eccezioni da approvare a parte | §6.3 |
| 35 | Capsula: dettatura | Nel campo della capsula la dettatura del sistema (servizio Apple) resta attiva? | Sì, lasciata attiva e detta nell'aiuto | §3.4 |

**C. Dati sensibili, cosa si conserva, backup e «Prisma ovunque»**

| N. | Tema | Domanda | Proposta | § |
|---|---|---|---|---|
| 36 | Dati sanitari | Questionari sanitari e sinistri da infortunio sono dati sulla salute (art. 9 GDPR) in un archivio JSON in chiaro (protetto da FileVault). Come trattarli? | Nei sinistri solo testi brevi e generici (fase, date, documenti ricevuti); referti solo come file nei Documenti | §7.4 |
| 37 | Nota vocale lontano dal Mac | Il ponte funziona solo in rete locale: la nota si tiene sull'iPhone o passa dal giornale cifrato di Prisma ovunque (testo dettato su un cliente su iCloud Drive)? | Coda cifrata sull'iPhone (chiave `ThisDeviceOnly`, protezione `completeUntilFirstUserAuthentication`, esclusa dal backup di iCloud, tolta appena il Mac risponde «accettata») e invio quando il Mac è raggiungibile. Il giornale di Prisma ovunque solo con un sì esplicito. In alternativa si detta solo con il Mac raggiungibile | §6.2 |
| 38 | Nuovo cliente: copia del documento | Prisma conserva la copia del documento d'identità per l'adeguata verifica? | Di base no (come Inquadra). Un interruttore spento la salva nei Documenti del cliente; gli obblighi li indica l'utente | §9.1 |
| 39 | Potenziali: dati di terzi | Nome, recapiti e stima del patrimonio di persone presentate che non sono clienti (art. 14 GDPR)? | Campo «informativa data il»; finché manca, segno «informativa da dare» e Messaggi non scrive a quella persona. Stima facoltativa. Tempi di conservazione e cancellazione dei «non interessati» li decide l'utente | §9.2 |
| 40 | IBAN | Si conserva l'IBAN del cliente nel dossier? | Solo con un interruttore acceso dall'utente: mascherato, controllo mod 97, nei backup, mai in Prisma ovunque né nei messaggi | §7.2 |
| 41 | Capsula: chi può leggerla | «Nemmeno Denis»: chiave nel Portachiavi del Mac, parola scelta dal cliente o tutte e due? | Chiave nel Portachiavi (`PortachiaviCapsule`) e frase onesta: «Prisma la sigilla e la cifra: non si può leggere fino al giorno giusto». Una cassaforte a tempo vera richiederebbe un servizio esterno | §3.4 |
| 42 | Capsula: la chiave nei backup | Mettere la chiave delle capsule nel backup è un'eccezione nuova, simile alla regola che tiene fuori la chiave di Prisma ovunque | Chiave a parte, mai quella di Prisma ovunque né una sua derivata; nel backup solo se il backup è protetto da password, con approvazione esplicita e una riga nuova in CLAUDE.md. Senza backup protetto, avviso in Impostazioni › Backup che le capsule si riaprono solo da questo Mac | §3.4 |
| 43 | Capsula: riservatezza e consegna | L'elenco della Sala nel template mostra capsule di altri clienti davanti al cliente. Il PDF della capsula si condivide oltre la stampa? Serve una riga nell'informativa privacy? | Nella Sala solo le capsule del cliente scelto (elenco completo nel dossier); condivisione del PDF solo se l'utente la approva; il testo dell'informativa lo dà l'utente | §3.4 |
| 44 | Cosa entra in «Prisma ovunque» | Con lo spazio cifrato acceso, quali dati nuovi entrano in `istantanea.cifrato` e nei giornali? | Entrano: pratiche, aziende, campagne, `Cliente.luogo` (cifrato come il resto), al massimo il numero di carte della notte. Entrano limitati: sinistri (titolo, fase, eventi, documenti senza file, se la decisione 36 lo permette); potenziali solo con un interruttore apposito spento di base. Restano fuori: capsule, lettere, partite del gioco del rischio, moduli, IBAN, foto della realtà aumentata, note vocali (salvo decisione 37). `--prova-ovunque` aggiornata | §3.4, §4.1, §5.1, §6.1, §7.3, §7.4, §9.2, §9.4 |
| 45 | Biblioteca nei backup | Circolari e manuali interni di Alleanza possono stare in un backup su iCloud Drive con 8 copie in rotazione? E il peso dei PDF? | La Biblioteca entra nel backup di base, con l'interruttore «Escludi la Biblioteca dal backup» e la misura della cartella in Impostazioni › Backup | §8.1 |
| 46 | Elenco del backup in CLAUDE.md | I nuovi dati (notti, note in arrivo, spese, scadenze, corsi, scontrini e attestati, moduli, biblioteca, capsule, pratiche, potenziali…) entrano nel backup: si aggiorna l'elenco scritto in CLAUDE.md? | Sì, a ogni giro che li aggiunge, insieme a `--prova-backup` | §6, §7, §8, §9 |
| 47 | Smontaggio: immagine dell'estratto | Si tiene la foto dell'estratto conto di un'altra banca? | Solo con «Conserva l'immagine»; altrimenti foglio ricostruito, come Inquadra | §8.2 |
| 48 | Tavolo a doppio senso | Oggi l'iPad del tavolo mostra solo ciò che sceglie il Mac. Si accetta che dall'iPad arrivino al Mac le scelte e i tempi del cliente (gioco del rischio, Lancia l'anno), il disegno, il testo della capsula o lo scatto della realtà aumentata? | Sì, solo in rete locale cifrata (ChaChaPoly, `_prisma-tavolo._tcp`) e senza nulla salvato sull'iPad, con messaggi nuovi in `ProtocolloTavolo`; in seconda fase. Ripiego: solo l'immagine e il consulente tocca la risposta | §2.3, §3.3, §3.4, §4.1, §4.3 |
| 49 | Cifre del cliente sul tavolo | Pensione, spese, patrimonio del cliente possono andare sull'iPad anche con altre persone presenti? | Sì, in rete locale cifrata, senza nulla salvato sull'iPad, con la conferma del consulente; lo scenario 1 del gioco del rischio resta neutro (100.000 €) salvo scelta | §4.1, §4.2 |
| 50 | Modalità cliente | Quali app e viste nuove sono riservate? | Riservate: Territorio, Pratiche, e anche Messaggi (le campagne mostrano nomi e bisogni di tutti). Consentite: Sala (con il solo cliente presente nelle pillole) e Biblioteca. Il segmento Radar di Posizioni sparisce in modalità cliente (regola nuova per vista, oggi `appRiservate` è per app). L'idea regalo dei traguardi è nascosta | §1.2, §5.4, §7.0, §8.3, §9.4 |
| 51 | Palestra: cosa si salva e su quali dati | Si salvano le conversazioni di allenamento? Ruby recita clienti veri? Cosa può stare in `Ruby/Esempi/palestra.json`? Sull'iPhone il profilo passa dal ponte? | Si salvano solo data, difficoltà e punteggio (al massimo 50 voci), fuori dal dossier. Cliente attivo, di prova o profilo inventato, tutto su Qwen locale. Negli esempi del repository mai dati veri, solo frasi anonime o dei clienti di prova. Sul ponte come le altre domande a Ruby | §5.3 |
| 52 | Gioco del rischio: partite | Le partite si salvano? | Solo con «Salva nel dossier» | §4.1 |
| 53 | Blocco e riposo del Mac | Nel template il blocco non chiude storia e carte della notte | In Prisma il blocco e il riposo del Mac chiudono tutte le sovrapposizioni | §1.4 |
| 54 | Moduli: Qwen legge le etichette | Si può mandare a Qwen (in locale) il testo delle etichette dei moduli vuoti? | Sì, solo il testo del modulo vuoto, nessun dato del cliente, sempre da confermare; senza Qwen regole e mano | §7.2 |
| 55 | Nota vocale: consenso e sicurezza | Serve il consenso del cliente? E la nota «in macchina»? | Niente consenso del copilota (parla solo il consulente), ma la schermata avverte di usare il copilota se il cliente è presente; sul telefono si mostra solo l'ora | §6.2 |

**D. Testi normativi, marchio, prodotti e fonti che Prisma non può inventare**

| N. | Tema | Domanda | Proposta | § |
|---|---|---|---|---|
| 56 | Avvertenze sulle proiezioni | La nota «non è una previsione né una promessa», «Stime basate su ipotesi…» e le avvertenze di lettera, film, Lancia l'anno e di ogni esperienza che proietta cifre: chi le scrive? Servono testi IDD/MiFID nel file del cliente? | Le scrive o le approva l'utente; Prisma non le inventa. Nel frattempo solo «Stime basate su ipotesi, non garanzie di risultato.» come segnaposto dichiarato | §1.3, §2.1, §3.1, §3.2, §4.3 |
| 57 | Logo Alleanza nei materiali per il cliente | Si può usare il logo Alleanza in un file o in un video dato al cliente, fuori dai materiali della compagnia? La chiusura del film firma sempre come indipendente | Firma secondo i canali del cliente, con nome e colore del canale e senza logo Alleanza finché Alleanza non approva | §2.1, §3.2 |
| 58 | «Quanto vale avermi accanto»: regole | «Il nostro lavoro vale X €» e «per ogni euro Y euro» sono comunicazioni sui risultati della consulenza: con quali testi e regole (OCF, Alleanza)? Cosa si attribuisce al consulente? | Testo e avvertenza dati o approvati dall'utente; contano solo le posizioni nate da raccomandazioni accettate dopo l'inizio del rapporto (`Cliente.clienteDal`) | §4.4 |
| 59 | Gioco del rischio: normativa | «Prepara il questionario, non lo sostituisce» e «il profilo ufficiale resta quello firmato» vanno fatti rivedere? Il gioco può proporre una propensione? | Il gioco non scrive mai `Cliente.profilo.propensione`; il pulsante apre il Profilo del dossier con un avviso. Testi e scenari approvati dall'utente, con l'etichetta «testi di prova» fino ad allora | §4.1 |
| 60 | Moduli Alleanza in Prisma | Si possono compilare in Prisma i PDF dei moduli Alleanza, e la compagnia li accetta? | Da chiedere ad Alleanza prima di costruire quella parte; intanto la funzione vale per i moduli del canale indipendente | §7.2 |
| 61 | Moduli veri | Proposta di polizza, privacy, mandato, questionario, adeguata verifica del template (e i moduli del nuovo cliente) sono fac-simile: chi li fornisce? | L'utente carica i PDF veri per canale e controlla una volta la mappa dei campi; senza modelli la scheda mostra «Moduli da preparare» | §7.2, §9.1 |
| 62 | Questionario e antiriciclaggio | Prisma riempie da solo profilo, titolare effettivo, PEP, origine dei fondi? | No: solo anagrafica e documento; le risposte le dà il cliente ogni volta, nei riesami le vecchie si mostrano accanto «da confermare» | §7.2 |
| 63 | Firme | Prisma deve fare la firma elettronica? | No (servirebbe un fornitore): solo caselle evidenziate per la firma a penna o con gli strumenti della compagnia | §7.2 |
| 64 | Prodotti e premi | Il template sceglie da solo il prodotto e mostra «circa 31 € al mese» senza tariffe | Prisma propone solo prodotti del catalogo dell'utente adatti al bisogno (Alleanza solo prodotti Alleanza, con più prodotti chiede al consulente); premio «da chiedere alla compagnia» o scritto a mano, tabelle di tariffe solo se fornite | §7.1 |
| 65 | Passi e fasi delle pratiche | Quali passi dopo la firma per l'indipendente? Fasi del sinistro per tipo, fase «Respinto»? Date ed emissioni da portali della compagnia? | Indipendente: Moduli · Documenti informativi · Documento d'identità · Primo versamento · Conferma dell'investimento · Consegnata; soglia «ferma» 7 giorni modificabile. Sì a «Respinto», fasi per tipo dall'utente. Nessun collegamento ai portali: segna il consulente o un documento letto in locale | §7.3, §7.4 |
| 66 | Spese: dati fiscali | Scadenze fiscali, deducibilità, IVA, €/km, ore di aggiornamento IVASS/OCF nel codice? | No: le inserisce tutte l'utente; al massimo promemoria suggeriti da accendere uno per uno con «verifica con il tuo commercialista» | §6.3 |
| 67 | Imprenditori: testi fiscali e civilistici | Regole o calcoli su TFM, welfare aziendale, patto di famiglia? | No senza testi e parametri verificati dall'utente o dal commercialista; niente simulatore del TFM in questo giro: dati, stato e «da valutare con il commercialista» | §9.3 |
| 68 | Biblioteca: testi normativi | Prisma porta con sé condizioni o testi normativi? Che fa se una citazione contraddice un parametro dei motori (5.164,57 € contro 5.300 € di `MotoreFiscale`)? | Solo PDF dell'utente (nei dati di prova fac-simile scritti apposta), con l'edizione in ogni citazione. Se la cifra non coincide, avviso sotto la risposta («Prisma usa 5.300 € dal 2026; il documento potrebbe essere superato»); il parametro non cambia | §8.1 |
| 69 | Lancia l'anno: probabilità ed eventi | Da quali fonti (ISTAT, INAIL, INPS) probabilità e importi degli eventi? Si scaricano? | Li dà l'utente con la fonte, in Impostazioni › Sala o da file; non si scaricano (l'unica rete è Mercato). Fino ad allora anni di mercato dal Monte Carlo, eventi del cliente dalla linea della vita e carte giocate a mano | §4.3 |
| 70 | Tabelle geografiche nelle risorse | Coordinate di comuni e CAP (Territorio) e codici catastali dei comuni (codice fiscale): da quali fonti e licenze? | Comuni e confini ISTAT (CC BY), scaricati una volta a mano durante lo sviluppo e citati in Impostazioni; codici catastali da Agenzia delle Entrate o ISTAT se l'utente approva, altrimenti «coerente (comune non controllato)»; per i CAP una fonte aperta da scegliere, altrimenti solo il comune | §5.1, §9.1 |
| 71 | Territorio: dati demografici | La tile «Dove ancora non ci sei» dice «tante famiglie giovani» | La frase si toglie, salvo dati ISTAT importati a mano dall'utente | §5.1 |
| 72 | Storie: paragoni dei km | «Due volte fino a Lisbona»: con quali paragoni? | Solo da una tabella di distanze approvata dall'utente, altrimenti niente paragone | §5.2 |
| 73 | Palestra: obiezioni e giudizio | Quali criteri per ottima/buona/debole? Chi scrive obiezioni ed esempi? | Niente pressione né promesse di rendimento, uso delle cifre e degli strumenti di Prisma, coerenza con l'adeguatezza; obiezioni ed esempi scritti o approvati dall'utente | §5.3 |
| 74 | Imprenditori: prodotti | Da dove vengono i prodotti key man e welfare? | Dall'archivio prodotti dell'utente; senza, «nessun prodotto adatto in archivio» | §9.3 |

**E. Regole di calcolo e onestà delle cifre**

| N. | Tema | Domanda | Proposta | § |
|---|---|---|---|---|
| 75 | Calcolo della pensione | Il template usa un 3% fisso (`fattore`, `pensCon`, `versPens`) | Le esperienze chiedono le cifre a `MotorePrevidenza` (adattatore `PensioneEsperienze`) con le ipotesi del cliente; dati mancanti dichiarati | §1.4, §4.2 |
| 76 | Ipotesi di previdenza non confermate | Lettera, film, giornata, dadi possono usare i valori predefiniti di `IpotesiPrevidenza` (1.400 / 2.200 / 67 anni / 1,5%) che nessuno ha inserito? | No: solo ipotesi confermate (`Analisi360.confermate` contiene `.previdenza`), altrimenti «ipotesi da confermare in Analisi 360 › Previdenza» | §1.4, §4.2 |
| 77 | Che cos'è «il piano» | Quali posizioni contano come «il piano» (lettera, giornata, Lancia l'anno)? | Il piano = posizioni in proposta più versamenti previsti degli obiettivi; «con il piano» nella giornata solo con proposte vere (`renditaProposte`), in alternativa un'ipotesi da `versamentoMancante` segnata «ipotesi»; «senza» = pubblica + `renditaInEssere` | §3.1, §4.2, §4.3 |
| 78 | Lancia l'anno: confronto onesto | Il template confronta 11.640 € l'anno di risparmio con il piano contro 3.600 senza | No: stesso risparmio totale nelle due vite, «senza piano» = posizioni in essere di oggi senza le proposte | §4.3 |
| 79 | Lancia l'anno: indennizzi e durata | Come si stimano gli indennizzi delle polizze? Quanto dura la partita? | Campo nuovo `Posizione.indennizzoStimato` scritto dalle condizioni (senza: nessuna cifra); durata a scelta, 12 anni o fino alla pensione | §4.3 |
| 80 | Lettera: tono della versione «senza» | La versione «Senza il piano» fa leva sul timore: si tiene? Saluto e carattere? | Solo davanti al cliente, con istruzioni a Ruby che vietano scenari negativi oltre le cifre; saluto «{nome},», carattere New York (`Font.Design.serif`) | §3.1 |
| 81 | Prisma del cliente: cosa misura l'anello | Il già da parte rispetto al traguardo (`disponibileOggi / importo`) o la copertura proiettata (`EsitoObiettivo.copertura`)? | Il già da parte, che non dipende da ipotesi di rendimento, con la frase sotto che dice quale dei due è | §2.1 |
| 82 | Prisma di luce: totale e ripartizione | «Il patrimonio» del template è il netto, ma i raggi sono classi d'investimento; negli anni le fasce restano quelle di oggi? | Patrimonio finanziario (`ComposizioneInvestimenti360.totale`) con «IL PATRIMONIO FINANZIARIO DI …»; ripartizione di oggi dichiarata nel pannello, proiezione per posizione in una seconda fase | §2.2 |
| 83 | Giornata della pensione: spese e ordine | Precompilare le spese dal fabbisogno di oggi? Le scene si pagano in ordine di giornata o per priorità? | Precompilazione solo con «da confermare»; priorità scelta con il cliente trascinando le scene | §4.2 |
| 84 | Gioco del rischio: soglie e stile | Quali soglie del punteggio 0-6? Nomi e colori dei profili? La risposta scelta resta verde come «giusta»? Si mostrano i secondi? | Le quattro propensioni di Prisma (0-1 prudente, 2-3 moderata, 4-5 dinamica, 6 aggressiva) con i colori del template (verde, blu, viola, arancio); accento neutro, nessuna risposta giusta; secondi visibili, nascondibili dal consulente | §4.1 |
| 85 | Quanto vale: compenso, canale, periodo | Confronto solo con le parcelle o con parcelle + provvigioni + costi? Clienti solo Alleanza? Periodo e capitale protetto? Rete? | Compenso completo diviso per canale; per i clienti solo Alleanza «Valore e costi», rapporto mostrato anche se basso; periodo dall'inizio del rapporto; solo capitale caso morte; nessuna richiesta di rete (solo riferimenti già in archivio) | §4.4 |
| 86 | Capsula: quando un obiettivo è raggiunto | «Raggiunto» lo decide il calcolo o il consulente? Il cliente scrive sul Mac o sull'iPad? | Il calcolo (`disponibileOggi ≥ importo`) propone, il consulente conferma, come nei traguardi; prima sul Mac, poi l'iPad | §3.4 |
| 87 | Traguardi: tipi e anniversari | Serve uno stato «in erogazione»? Quali traguardi si festeggiano? L'idea regalo? | Per ora «obiettivo raggiunto» con `Obiettivo.raggiuntoIl`; anniversari a 1, 5, 10, 15 e 20 anni, finestra di 7 giorni; nessuna proposta commerciale nella frase; idea regalo solo da note e memoria del dossier | §5.4 |
| 88 | Disegna: l'obiettivo salvato | Come si salva il disegno come obiettivo? | Area pensione, importo = il disegno alla pensione in euro di oggi, scadenza = data della pensione, versamento = quanto serve in più al mese, tutto da un modulo e mai in silenzio | §3.3 |
| 89 | Smontaggio: conto a dieci anni | Il template confronta solo i costi correnti con un rendimento del 5% | `MotoreSostituzione` con penale, ingresso e tasse, ipotesi di Prisma (3%, 10 anni) scritte nella didascalia; la cifra «solo costi» eventualmente accanto e chiamata così | §8.2 |
| 90 | Smontaggio: performance e posizione | Senza l'importo addebitato si stima la performance? L'estratto non registrato va registrato? Quale proposta prima? | Nessuna stima: ellisse tratteggiata e «cifra non calcolabile»; posizione provvisoria in memoria, mai salvata; prima la proposta con il costo più basso, con il canale ben visibile | §8.2 |
| 91 | Radar: modelli e «Riequilibra» | I modelli sono separati dalla propensione MiFID? I punti tornano al centro? Previdenza inclusa? Spostamenti fra canali? | Modelli assegnati dall'utente, con avviso se superano il rischio del profilo (`MotoreCoerenza.sriMassimo`); i punti restano dove sono con «proposta pronta»; previdenza esclusa di base; nessuno spostamento fra Alleanza e indipendente salvo interruttore caso per caso | §8.3 |
| 92 | Proposta: cosa crea «Costruisci» e il tempo | La costruzione salva qualcosa? «Pronta in 52 secondi»? | Una bozza in Posizioni e la scheda di adeguatezza, annullabili; prospetto e moduli diventano file solo quando si presentano; «Proposta pronta» senza secondi o con il tempo vero | §7.1 |
| 93 | Biblioteca: ricerca e risposte | Solo parole (BM25) o anche significato? «Ho letto 38 pagine»? Dati del cliente nella risposta? | BM25 in questo giro (NLEmbedding più avanti, senza dipendenze); «ho cercato in 38 pagine»; solo il nome se è nella domanda, eventuale riga calcolata da Prisma sotto la risposta | §8.1 |
| 94 | Potenziali: probabilità e archivio | Valori predefiniti per fase? Cosa conta «Probabile entro fine anno»? Elenco a sé o clienti «potenziali»? | Probabilità e data le scrive l'utente; la tile conta solo chi ha stima, probabilità e data entro il 31 dicembre; elenco separato `DatiPrisma.potenziali`, diventa Cliente solo con conferma | §9.2 |
| 95 | Passaparola: albero e ambasciatori | Quanti livelli? Clienti e potenziali sommati? | Tre generazioni, poi «+ N»; due cifre separate, «portato» e «in arrivo» | §9.2 |
| 96 | Imprenditori: anelli e scheda | Come si calcolano persona chiave, TFM, welfare, passaggio? Quando compare la scheda? Più aziende? | Persona chiave = coperture key man / (fatturato × mesi a rischio scritti dall'utente); TFM sì/no; welfare e continuità da checklist dell'utente; scheda quando c'è almeno un'azienda (`Cliente.aziende`), più aziende con la scelta in testa | §9.3 |
| 97 | Campagne: gruppi, soglie, frequenza | Quali bisogni diventano campagna e con quali soglie? Un cliente in più gruppi? | Solo bisogni già calcolati dai motori, soglie in `RegoleCampagne` approvate dall'utente; un pallino per gruppo con «anche in: …»; al più una campagna ogni 30 giorni per cliente | §9.4 |
| 98 | Campagne: Ruby e appuntamenti | Qwen riscrive tutti i messaggi? Gli orari proposti si bloccano in Agenda? | Modello fisso subito pronto; riscrittura di Ruby facoltativa, uno alla volta e interrompibile; orari dagli spazi liberi veri, solo come testo, senza bloccarli | §9.4 |
| 99 | Territorio: criterio del giro e «Aggiungila al giro» | Chi entra nell'anello arancio e in «Lungo la strada»? Il pulsante crea subito l'appuntamento? | Voci aperte di `MotoreDaFare`, attenzioni alte o consenso scaduto; il pulsante crea un appuntamento da confermare nello spazio libero fra due visite | §5.1 |
| 100 | Spese: canale e luogo delle visite | Spese e corsi divisi per canale? Come si sa se la visita era dal cliente? | Campo canale facoltativo; campo `Appuntamento.presso` (cliente, studio, altro) chiesto quando manca, visite senza luogo fra quelle «senza km» | §6.3 |
| 101 | Stanotte: memoria e Qwen | Di notte Qwen scrive le bozze occupando 3-3,5 GB su 8? Le carte vanno anche sul telefono? | Prima i lavori senza Qwen, poi al massimo 10 bozze una alla volta liberando subito il modello; al primo avviso di memoria si ferma e resta «Da finire». Niente carte su iPhone/iPad in questo giro | §6.1 |
| 102 | Nota vocale: conferma | Il template salva nota e attività senza chiedere | Tutto proposto e confermato sul Mac (Conferma, Scarta, Conferma tutto), come il copilota | §6.2 |

**F. Architettura, compatibilità, prove e numerazione**

| N. | Tema | Domanda | Proposta | § |
|---|---|---|---|---|
| 103 | Versione dell'archivio | Oggi `DatiPrisma.versioneAttuale = 26`; tutte le parti propongono campi nuovi | Una sola versione 27 per tutta Luce, campi nuovi letti con tolleranza (`decodeIfPresent`), `--prova-backup` aggiornata con ogni campo. Se i giri escono separati, ogni giro che aggiunge campi alza la versione di uno | tutte |
| 104 | Compatibilità delle app nuove | `AppPrisma` è salvata negli spazi di lavoro: un Prisma più vecchio (iPhone con Prisma ovunque) non decodifica le app nuove | `FinestraSpazio` letta con tolleranza, prova in `--prova-backup` e `--prova-ovunque` | §1.2 |
| 105 | Numeri delle istantanee | Biblioteca e analisi (§8) e Pratiche (§7) usano tutte e due 800-827 | Pratiche resta 800-839; nel §8 i numeri sono già stati spostati a 870-897 (vedi §0.6) | §0.6 |
| 106 | Shader: MTKView o CAMetalLayer | Prisma di luce (e anteprima AR) con MetalKit o con lo schema dell'acqua? | Lo schema dell'acqua (`CAMetalLayer` con `CVDisplayLink`/`CADisplayLink`), sorgente compilata a runtime, niente `.metal`; 30 fps (20 in risparmio), 60 solo in trascinamenti | §1.4, §2.2 |
| 107 | Realtà aumentata: anteprima, scala, occlusione | Anteprima sul Mac con RealityKit `.nonAR` o `FS_AR` in Metal? Scala? Occlusione delle persone? Dove si apre? | RealityKit `.nonAR` (un solo codice); 1 unità = 16 cm da provare; occlusione spenta; dal tavolo e da iPhone/iPad da soli, con i dati che il dispositivo ha già | §2.3 |
| 108 | Film: formato, durata, prova | «Un minuto» o 20 secondi? Formato? Se sul runner macos-15-intel manca il codificatore H.264 la build diventa rossa? | 20 secondi, cambiando il testo della scheda; MP4 H.264 1920×1080, 30 fps, circa 4 Mbit/s, niente audio né metadati; `--prova-film` scrive «codificatore non disponibile» e l'utente sceglie se in quel caso la build resta verde. Il video resta animato anche con Riduci movimento, l'anteprima no | §3.2 |
| 109 | Node nel workflow | Prova del lettore del Prisma del cliente con Node del runner e 600.000 iterazioni PBKDF2 (circa 1 s sul telefono)? | Sì: Node solo nel workflow e mai nell'app, script senza dipendenze | §2.1 |
| 110 | Icone con genera-icone.js | Generare le quattro icone nuove con lo script e Playwright, fondi fuori da `Tema.Apple`? | Sì: nessuna dipendenza nuova, Playwright non entra nell'app né nel workflow, le PNG si committano | §1.2 |
| 111 | Mostra sul tavolo | Cosa va all'iPad del tavolo da un'esperienza (luce, film, giornata…)? | Prima fase un'immagine del palco (genere `pagina` esistente), senza cambiare il protocollo; scene vive con un genere nuovo dopo | §1.3, §2.2, §3.2 |
| 112 | Palestra: ruolo di Ruby | Un terzo caso di `ModalitaRuby` o un percorso a parte? | `PalestraRuby` a parte, con `Ruby/Istruzioni/palestra.md` e uno schema JSON, sullo stesso Qwen locale; `ModalitaRuby` resta lavoro e conversazione | §5.3 |
| 113 | Disegna e iPad | Il disegno con il dito sull'iPad del tavolo? Il confronto guarda solo l'età di pensione | iPad in seconda fase con punti normalizzati (vedi 48); una frase in più sul dopo pensione | §3.3 |
| 114 | Biblioteca su iPhone e iPad | La Biblioteca va sui dispositivi? | No in questo giro; più avanti dal ponte di Ruby (Prisma ovunque non porta i documenti) | §8.1 |
| 115 | Biglietto animato | Video MP4 o immagine PNG? | PNG con `ImageRenderer` nel primo giro, video con `AVAssetWriter` dopo | §5.4 |

**G. Grafica, interazione e movimento**

| N. | Tema | Domanda | Proposta | § |
|---|---|---|---|---|
| 116 | Pannello Novità: voci di Orizzonte | Le 11 voci di Orizzonte spariscono dal pannello? | Sì: solo le 29 di Luce, versione «luce» in `Impostazioni.novitaViste` | §1.1 |
| 117 | Pannello Novità: larghezza | Il pannello largo 1180 non sta nella finestra minima di 1100 | Tre colonne fino a 3×300, poi due colonne con lo scorrimento | §1.1 |
| 118 | Colori dei tasselli e dei canali | «Quanto vale avermi accanto» (#2563EB) e «Lancia l'anno» (#B06E12) hanno i colori dei canali; il prisma di luce e le luci del Territorio usano blu e arancio diversi dal tema | Tasselli tenuti (non sono etichette di canale; in alternativa #3B6FD8 e #A8742C). Dove un colore indica il canale, le varianti scure del tema (#6B95FF, #D0954A) più l'etichetta a parole | §1.1, §2.2, §5.1 |
| 119 | Colori delle classi d'investimento | Prisma di luce, realtà aumentata e radar usano colori delle classi diversi da `Colore.Composizione` di Analisi 360 | Prisma di luce e realtà aumentata: la tavolozza del template come `Tema.Apple.Luce.Raggi`, condivisa; radar: i colori di Analisi 360, salvo scelta contraria | §2.2, §8.3 |
| 120 | Dock: quattro app nuove e ordine | Le app nuove sono quattro (anche Sala) e cambia l'ordine: Mercato e Studio perdono ⌥8 e ⌥9 | Ordine del template, annunciato nella Guida; in alternativa ⌥0 per la decima | §1.2 |
| 121 | Dock dell'iPad | Con 17 elementi le icone diventano piccole | Nel dock dell'iPad solo le app fino a Prospetti più Sala e Ruby, il resto in «Tutte le app» | §1.2 |
| 122 | Icone simili | Pratiche quasi uguale a Incontri, Biblioteca a Clienti, Sala vicina a Ruby | Sorgenti del template, decisione guardando la tavola `617-icone-luce` (§1.2.7) | §1.2 |
| 123 | Sala: presentazione al cliente | Il template non ha una presentazione delle esperienze | Pulsante «▶︎ Presenta» con la sala opaca e la modalità cliente; l'acqua si ferma sotto il velo (`scrivaniaCoperta` esteso) | §1.3 |
| 124 | Sala: palco ed Esc | Come nasce il palco e cosa fa Esc? | `matchedGeometryEffect` dalla scheda; Esc torna alla griglia prima di chiudere la finestra | §1.3 |
| 125 | Glifi | Tracciati vettoriali fedeli o SF Symbols simili? | Tracciati vettoriali (`GlifiLuce.swift`), aspetto originale | §1.4 |
| 126 | Testo che si scrive | Una lettera per volta (template) o una parola (`TestoProgressivo` di Ruby)? | Una parola per volta riusando `TestoProgressivo` | §1.4 |
| 127 | Territorio: zone e Riduci movimento | Zone = comuni, frazioni o disegnate? Con Riduci movimento «Guarda la crescita» scorre gli anni? | Zone uguali ai comuni (o zone dell'utente); un anno ogni 0,9 s con la sola dissolvenza di 0,15 s | §5.1 |
| 128 | Storie: lunedì, ritmo e contrasto | La storia della settimana si apre da sola? Con Riduci movimento il passaggio automatico resta? Testo bianco all'82% sui fondi chiari? | Invito sulla scrivania al primo sblocco del lunedì, senza aprirla da sola; passaggio automatico a 5,2 s anche con Riduci movimento; testo secondario al 90% o gradiente più scuro | §5.2 |
| 129 | Radar: aspetto | Il radar resta scuro anche nell'aspetto chiaro? | Come il template, da confermare | §8.3 |
| 130 | Nuovo cliente: pulsante | «Nuovo cliente» apre solo la fotocamera, togliendo Importa e Incolla da Excel? | Apre la scena con «Scrivi a mano» sempre visibile; Importa e Incolla da Excel in un menu «…» accanto al segmentato | §9.1 |

### 0.6 Numeri delle istantanee
In `Sources/` le istantanee del Mac arrivano oggi a 613 e quelle iOS a 53. Le parti hanno scelto serie quasi tutte libere;
l'unico conflitto è fra §7 e §8, risolto spostando il §8 (nel testo del §8 i numeri sono **già quelli nuovi**).

| § | Parte | Serie della bozza | Conflitto | Serie finale |
|---|---|---|---|---|
| 1 | Parte comune | 614-619, 690-695; iOS 54-55 | — | 614-619, 690-695; iOS 54-55 |
| 2 | Prisma del cliente, prisma di luce, realtà aumentata | 620-632; iOS 70-74 | — | 620-632; iOS 70-74 |
| 3 | Lettera, film, disegna, capsula | 640-657 | — | 640-657 |
| 4 | Rischio, giornata, Lancia l'anno, quanto vale | 660-678 | — | 660-678 |
| 5 | Territorio, storie, palestra, traguardi | 700-736 (736 sull'iPhone) | — | 700-736 |
| 6 | Notte, nota vocale, spese | 760-789 (775 sull'iPhone) | — | 760-789 |
| 7 | Pratiche | 800-836 (824 sull'iPhone) | con §8 | 800-839 |
| 8 | Biblioteca, smontaggio, radar | 800-807, 810-816, 820-827 | con §7 | 870-877, 880-886, 890-897 |
| 9 | Nuovo cliente, potenziali, imprenditori, campagne | 840-869; iOS 75-77 | — | 840-869; iOS 75-77 |

Esistenti da rifare: `400-vetrina-apple`, `410-scrivania-apple`, `500-scrivania-orizzonte`,
`501-novita-pannello`, `470-tavolo-sala`, `600-609` (Inquadra, dopo l'estrazione di `TelefonoDisegnato`), `490-498`
(Messaggi, dopo il segmentato delle campagne). A ogni giro vanno aggiornate anche la vetrina «400-vetrina-apple» e la
pagina online delle anteprime.

### 0.7 Cose che valgono per tutte le parti
- **Dati di prova**: un solo caricamento da Impostazioni › Dati di prova porta i dati di tutte le novità di Luce, e un solo
  comando li toglie.
- **Collegamenti fra le app**: nel template molti pulsanti aprono sempre la stessa voce di prova (`selM=0`, `selCli=1`,
  `apriEsp(…, 0)`). Nell'app ogni collegamento porta il cliente e il motivo da cui si parte (`StatoShell.apri(_:)` con il
  contesto).
- **Voci che arrivano dopo**: le voci del pannello Novità di un giro non ancora fatto restano nel pannello e portano
  all'app che le ospiterà con l'avviso «arriva con un prossimo aggiornamento» (come `NovitaOrizzonte.avvisoInArrivo`).

---

## 1. Parte comune della versione Luce

Fonte: `Design/template-luce.html` (5 novembre 2026, «Luce», 29 novità), letto a pezzi e confrontato con
`Design/template-novita.html` («Orizzonte»). **Per tutto ciò che qui non è detto vale `Design/template-novita-specifica.md`**
(§0 e §1, parte comune di Orizzonte) e, sotto, `Design/template-apple-specifica.md` (token §1, barra §3.3, dock §3.4,
finestra §3.5, scrivania §3.6, notifiche §3.8, tastiera §3.10, movimento §1.8).

I numeri di riga citati sono quelli del file del 5 novembre 2026 (2297 righe; la riga 474 è la tabella `ICONE` delle PNG
in base64, circa 380 KB: non va mai stampata). Le cifre, i nomi e le date del template sono **dimostrativi**: nell'app li
danno i motori e l'archivio; dove un dato manca Prisma lo dice.

Riferimenti visivi, scattati con Playwright (1480×940, palco 1440×900 scalato di 1,0137; non sono nel repository, chi
implementa li rigenera con lo script descritto in fondo, §4.8):
- `luce/img/01-c-scrivania.png`, `01-s-scrivania.png`: scrivania con i pulsanti nuovi e il dock a 16 voci;
- `luce/img/01-c-novita.png`, `01-s-novita.png`, `01-c-novita-hover.png`: pannello «✦ Le novità» a due gruppi (fermo e
  con il puntatore su «Le pratiche dopo la firma»);
- `luce/img/01-c-sala.png`, `01-s-sala.png`: la Sala, griglia delle 11 esperienze;
- `luce/img/01-c-palco-lettera.png`, `01-c-palco-prisma.png`: la cornice di un'esperienza aperta («palco»);
- `luce/img/01-c-territorio.png`, `01-c-pratiche.png`, `01-c-biblioteca.png`: le testate delle tre app di lavoro;
- `luce/img/01-c-dock.png`, `01-s-dock.png`: il dock con il puntatore su Pratiche.

Questa parte contiene quattro «novità comuni», ognuna con le otto sottosezioni:

| N. | Cosa | Parti del template |
|---|---|---|
| 1 | Il pannello «✦ Novità» a due gruppi (15 + 14) | barra 352; CSS 197-200, 284-285; `NOV15` 1778-1780; `NOVL` 2064-2066; `apriNov` 2067-2071 |
| 2 | Le app nuove nel dock e sulla scrivania (Territorio, Pratiche, Sala, Biblioteca), le icone e la scrivania | `ICONE` 474; `DOCK` 475; dock 476-482; scrivania 487; `APPS.territorio` 1661, `APPS.pratiche` 1848, `APPS.sala` 1208, `APPS.biblioteca` 1913; `<template id="sorgenti-icone">` 2114-2296 |
| 3 | La Sala: la cornice comune delle esperienze (`apriEsp`, griglia, palco, tavolo, «Aggiungi al Prisma», presentazione al cliente) | 1180-1225 |
| 4 | I componenti riusati da più novità | 1183-1186, 435, 1201-1206, 1423-1436, 1786-1794, 1101-1112, 1701-1727, 1805-1811, 845-846, 2073-2110 |

---

### 1.1 Il pannello «✦ Novità» a due gruppi

#### 1.1.1 Cosa si vede

**Pillola della barra** (riga 352): «✦ Novità» blu accento con la pastiglia **«29»** (prima «11»). Tutto il resto della
pillola è come in Orizzonte (§1.1 e §2.1 della specifica di Orizzonte).

**Pannello** `#novP` (righe 197 e 284; contenuto da `apriNov`, 2067-2071). Un vetro largo **1180** (era 540), centrato
sotto la barra, a 40 dall'alto, alto quanto il contenuto (**572** misurati) e al massimo 820, poi scorre. Dall'alto:

1. **Testata**: «✦ Le novità» (16 bold, inchiostro) a sinistra; «29 funzioni da provare» (`.k`, grigio) a destra.
2. **Etichetta di gruppo** «DAVANTI AL CLIENTE · 15» (`.lbl`, maiuscolo spaziato, grigio).
3. **Griglia a tre colonne** (`.novG`) con le 15 voci di `NOV15`, **riga per riga** (prima riga: voci 1, 2, 3; seconda: 4,
   5, 6…): 5 righe piene.
4. **Etichetta di gruppo** «PER IL TUO LAVORO · 14».
5. **Griglia a tre colonne** con le 14 voci di `NOVL`: 4 righe piene e una con due voci (colonne 1 e 2).

Ogni voce (`.novI` dentro `.novG`): a sinistra un **tassello colorato** 30×30 a raggio 9 con il glifo bianco (componente
§4.1); a destra il **titolo** in grassetto e sotto la **frase** in grigio, tutte e due su una riga sola con i puntini se
non ci stanno. **Non ci sono più** il pallino numerato sfumato (`.novN`) né la freccia «›» di Orizzonte.

Testi esatti, colore del tassello, glifo e dove porta (template):

**Davanti al cliente · 15** (`NOV15`, righe 1778-1780)

| # | Titolo | Frase | Glifo | Tassello | Dove porta nel template |
|---|---|---|---|---|---|
| 1 | Il Prisma del cliente | La sua app personale, in un file | `prisma` | #0A84FF | `apriEsp('prisma',0)`: Sala › Il Prisma del cliente, cliente 0 |
| 2 | Il tuo territorio | I clienti come luci, la crescita, il giro | `mappa` | #2A6FA0 | `vaiA('territorio', terM='oggi')`: Territorio › Oggi |
| 3 | La lettera dal futuro | Da sé stesso a 67 anni | `lettera` | #C45A75 | `apriEsp('lettera',0)` |
| 4 | Il film del piano | Un minuto da mandare su WhatsApp | `film` | #E08A00 | `apriEsp('film',0)` |
| 5 | Disegna il tuo futuro | Lo scarabocchio diventa un piano | `disegna` | #30B15C | `apriEsp('disegna',0)` |
| 6 | La tua settimana, il tuo anno | Trenta secondi ogni lunedì | `storia` | #1F5F99 | `apriStoria('settimana')`: la storia a tutto palco |
| 7 | La palestra della trattativa | Ruby fa il cliente difficile | `palestra` | #3F5A78 | `vaiA('studio', tabS='palestra')` |
| 8 | Il prisma di luce | Il patrimonio in raggi di luce | `luce` | #5B4BC8 | `apriEsp('luce',0)` |
| 9 | La capsula del tempo | Un messaggio sigillato fino al traguardo | `capsula` | #9B6FB5 | `apriEsp('capsula',0)` |
| 10 | I traguardi festeggiati | Il momento giusto, già pronto | `festa` | #E5484D | `vaiA('messaggi', selM=0)`: il primo traguardo |
| 11 | Il gioco del rischio | Il profilo vissuto, non dichiarato | `rischio` | #E5484D | `apriEsp('rischio',0)` |
| 12 | Una giornata della pensione | Il divario diventa una vita | `giornata` | #2A9BC8 | `apriEsp('giornata',0)` |
| 13 | Lancia l’anno | Due vite affiancate | `dadi` | #B06E12 | `apriEsp('dadi',0)` |
| 14 | Quanto vale avermi accanto | Il tuo lavoro, in cifre | `valore` | #2563EB | `apriEsp('valore',0)` |
| 15 | La realtà aumentata | Il patrimonio sul tavolo | `ar` | #1E9E6A | `apriEsp('ar',0)` |

**Per il tuo lavoro · 14** (`NOVL`, righe 2064-2066)

| # | Titolo | Frase | Glifo | Tassello | Dove porta nel template |
|---|---|---|---|---|---|
| 1 | Stanotte Prisma ha lavorato | La mattina trovi tutto pronto | `notte` | #1F3A5F | `apriNotte()`: le carte della notte a tutto palco |
| 2 | La proposta si costruisce da sola | Dal bisogno alla proposta in un minuto | `proposta` | #3E7D69 | `vaiA('pratiche', tabP='proposta')` |
| 3 | Compila da solo | I moduli si riempiono da soli | `modulo` | #30B15C | `vaiA('pratiche', tabP='moduli')` |
| 4 | Le pratiche dopo la firma | Cosa manca, pratica per pratica | `cartella` | #0A84FF | `vaiA('pratiche', tabP='dopo')` |
| 5 | Il sinistro come una spedizione | Lo stato in tempo reale, anche per il cliente | `sinistro` | #E08A00 | `vaiA('pratiche', tabP='sinistri')` |
| 6 | Trova la pagina | La risposta, con la frase evidenziata | `libro` | #8A5A35 | `vaiA('biblioteca')` |
| 7 | Lo smontaggio | I costi nascosti cerchiati sul documento | `lente` | #E5484D | `vaiA('posizioni', vistaP='smonta')` |
| 8 | Il radar del portafoglio | Chi si è allontanato dal suo modello | `radar` | #1E9E6A | `vaiA('posizioni', vistaP='radar')` |
| 9 | Le campagne | Lo stesso bisogno, tanti clienti, un tocco | `campagna` | #C45A75 | `vaiA('messaggi', vistaM='camp')` |
| 10 | Nuovo cliente in 10 secondi | La carta d’identità compila l’anagrafica | `scan` | #5B4BC8 | `vaiA('clienti', vistaC='rub')`, poi `apriNuovo()` dopo 400 ms (Clienti già davanti) o 900 ms |
| 11 | Potenziali clienti e passaparola | Il percorso e l’albero di chi presenta chi | `albero` | #2F7A4A | `vaiA('clienti', vistaC='pass')` |
| 12 | I clienti imprenditori | L’azienda accanto al titolare | `azienda` | #3F5A78 | `vaiA('clienti', vistaC='rub', selCli=1, tabCli='azienda')` |
| 13 | La nota vocale | Tra una visita e l’altra, dall’iPhone | `voce` | #E5484D | `vaiA('incontri')`, poi `apriNota()` dopo 400 ms o 900 ms |
| 14 | Chilometri, spese e scadenze | Per te e per il commercialista | `auto` | #5A6873 | `vaiA('studio', tabS='spese')` |

Gli apostrofi e le virgolette dei titoli sono tipografici (’). Il pannello di Orizzonte (11 voci numerate) non c'è più:
in Luce si vedono solo le 29 novità.

**Stati.** Il template ha solo il pannello pieno, senza vuoto, caricamento o errore. In Prisma (§1.6): le voci che arrivano
in un giro successivo restano nel pannello e, aperte, portano all'app che le ospiterà con l'avviso «arriva con un prossimo
aggiornamento» (`NovitaOrizzonte.avvisoInArrivo`, già così in `Shell/StatoNovita.swift`).

#### 1.1.2 Misure e stile

Misure in pt del palco 1440×900, dal CSS e dal JS (e confermate a schermo, `luce/script/misura01.js`).

| Cosa | Valore (template) | Token in Prisma |
|---|---|---|
| Pillola | come Orizzonte; pastiglia «29» | `Tema.Apple.BarraAlta.*Novita` (esistono, `Tema.Apple+Novita.swift`) |
| Pannello | `left: calc(50% − 590px)`, `top 40`, **largo 1180**, alto quanto il contenuto (572), max 820 poi scorre, raggio 24, padding 16, `.glass`, z 62 | `Tema.Apple.Novita.dallAlto`, `altezzaMassima`, `raggio`, `padding`, `bordo`, `basso` (esistono); **nuovo** `Tema.Apple.Novita.larghezzaDueGruppi = 1180` |
| Testata | `.row`, margine sotto **4** (era 6) | **nuovo** `spazioTestataDueGruppi = 4` |
| Etichetta gruppo | `.lbl`: 12 semibold, spaziatura 0,6, maiuscolo, `--ink2`; margine sopra **10** (primo) e **14** (secondo), sotto 4 | `Tema.Apple.Carattere.etichetta` (esiste); **nuovi** `sopraPrimoGruppo = 10`, `sopraSecondoGruppo = 14`, `sottoGruppo = 4` |
| Griglia | 3 colonne uguali, spazio verticale 2 e orizzontale 6 (`.novG`, riga 285); colonna 378,7 | **nuovi** `colonne = 3`, `spazioColonne = 6`; `spazioVoci = 2` (esiste) |
| Voce | flex, padding **7×8**, spazio **10**, raggio 14 (`.novI`), alta 44, passo 46 | **nuovi** `paddingVoceGriglia = EdgeInsets(7, 8, 7, 8)`, `spazioVoceGriglia = 10`; `raggioVoce = Raggio.voce` (esiste) |
| Tassello | 30×30, raggio **9** (= 0,3 del lato), colore della voce, ombra `inset 0 1 0 rgba(255,255,255,.35)` e `0 6 14 −6 rgba(0,0,0,.35)` | componente `TasselloGlifo` (§4.1) con `lato 30` |
| Glifo | SVG 24×24 bianco, tratto 2, capi e giunti tondi, disegnato a **15** | `TasselloGlifo` (§4.1) |
| Titolo | `b` 13 bold, una riga, puntini | **nuovo** `titoloVoceGriglia = Carattere(dimensione: 13, peso: .bold)` |
| Frase | `.k` a **11,5**, `--ink2`, una riga, puntini | **nuovo** `fraseVoceGriglia = Carattere(dimensione: 11.5, peso: .regular)` |
| Passaggio | fondo `--chip` in 0,2 s | `fondoPassaggio` (esiste) |
| Colori dei tasselli | 21 tinte (tabelle sopra) | **nuovo** `Tema.Apple.Colore.Glifi` (§4.1), una costante per glifo |

Il pannello è più largo della finestra minima di Prisma (`ShellView`: `minWidth 1100`, quindi al più 1068 con i bordi da
16). Proposta: **tre colonne da 1180 in giù fino a 3 × 300**, poi **due colonne**, con la stessa altezza massima e lo
scorrimento (`ViewThatFits` come oggi). Token **nuovo** `larghezzaMinimaColonna = 300`.

In scuro (`01-s-novita.png`) cambiano solo vetro, inchiostro e `--chip`; i tasselli hanno gli **stessi colori** in chiaro e
in scuro (il template non li cambia).

#### 1.1.3 Movimento

| Cosa | Da → a | Durata | Curva | Ritardo |
|---|---|---|---|---|
| Pannello che si apre | opacità 0, y −10, scala 0,97 → fermo | 0,38 s | `molla` (.34,1.45,.64,1) | 0 |
| Voci a cascata (tutte e 29 in fila, etichette escluse) | opacità 0, **y +8** → ferme | **0,36 s** | `uscita` (.22,1,.36,1) | **0,04 + i·0,014 s** (i = 0…28: da 0,04 a 0,432 s), `fill: backwards` |
| Passaggio su una voce | fondo trasparente → `chip` | 0,2 s | ease | — |
| Chiusura | sparisce subito, senza animazione | — | — | — |
| Apertura automatica | dopo il primo sblocco della sessione (`novVisto`, riga 2103) | — | — | 1,7 s |

Rispetto a Orizzonte cambiano solo le voci: in verticale (y +8) invece che da destra (x +16), più brevi e molto più fitte.
Token **nuovi** in `TemaAppleMoto`/`Tema.Apple+Novita.swift`: `Tema.Apple.Moto.VoceNovitaGriglia` (`durata 0.36`,
`spostamento 8`, `ritardoBase 0.04`, `passo 0.014`, curva `uscita`) e lo `StileEntrata.voceNovitaGriglia` (spostamentoX 0,
spostamentoY 8, scala 1, sfocatura 0), accanto a quelli di Orizzonte che restano per eventuali altri usi.

**Riduci movimento** (`\.prismaCalmo`): pannello e voci compaiono fermi con la dissolvenza di 0,15 s, senza cascata (il
template non guarda `ridotto` in `apriNov`: vale la regola di Prisma). **Istantanee** (`\.modoIstantanea`,
`\.prismaStatoFinale`): tutto subito nello stato finale.

#### 1.1.4 Interazioni

Mac:
- pillola: chiude le notifiche e apre/chiude il pannello (come Orizzonte; il clic non arriva al palco);
- clic su una voce: chiude Novità e Notifiche e fa ciò che dice la colonna «Dove porta» (`vaiA`, `apriEsp`, `apriStoria`,
  `apriNotte`, riga 2071). Con l'app già davanti chiude il dettaglio e la rimonta senza volo (`vaiA`, riga 846);
- voci 10 e 13 del lavoro: aprono prima l'app e poi la scena del telefono (§4.2) dopo **0,4 s** se l'app era già davanti,
  **0,9 s** se no (il tempo del volo della finestra);
- clic fuori dal pannello e fuori dalla pillola: si chiude (riga 864);
- Esc: chiude il pannello (ordine completo di Esc al §4.6);
- passaggio: fondo `chip`; le voci non si inclinano;
- le voci «davanti al cliente» aprono **sempre il cliente 0** (`apriEsp(k,0)` → `selSa=0`). In Prisma aprono la Sala sul
  **cliente attivo** (`StatoShell.clienteAttivoId`), e se non ce n'è uno sulla griglia con lo stato «Scegli il cliente»
  (§3.6).

iPhone e iPad: il template non mostra il pannello sui dispositivi. Oggi in Prisma il pannello è solo del Mac
(`proponiNovitaDopoSblocco` è `#if os(macOS)`): resta così, salvo decisione (§1.8).

#### 1.1.5 Mappa verso Prisma

**Esiste già (verificato con grep):**

| Cosa | Dove |
|---|---|
| Pannello, testata, voci, Esc, clic fuori | `Shell/PannelloNovita.swift` (`PannelloNovita`, `RigaNovita`) |
| Modello delle voci e destinazioni | `Shell/StatoNovita.swift` (`enum NovitaOrizzonte`, `apriVoceNovita(_:)`, `segnaNovitaViste()`, `proponiNovitaDopoSblocco()`, `apriNovita()`, `apriNovitaDaMenu()`) |
| Gettoni del pannello e della pillola | `DesignSystem/Apple/Tema.Apple+Novita.swift` (`Tema.Apple.Novita`, `Tema.Apple.Moto.PannelloNovita`, `VoceNovita`, `StileEntrata.voceNovita`) |
| Cascata delle voci | `DesignSystem/Apple/CascataApple.swift` (`entrataVoceNovita(_:)`) |
| Pillola nella barra | `Shell/BarraSuperiore.swift` |
| Versione vista | `Dati/DatiPrisma.swift` (`Impostazioni.novitaViste`, riga 269, letta con `decodeIfPresent`); `Dati/ProvaBackup.swift` riga 121 la imposta a «orizzonte» |
| Istantanee del pannello | `Istantanee.swift` righe 1408-1409 (`501-novita-pannello`) |

**Cosa cambia o va creato:**
- **`enum NovitaLuce: String, CaseIterable, Identifiable`** (in `Shell/StatoNovita.swift` o in un file nuovo
  `Shell/NovitaLuce.swift`), 29 casi nell'ordine del pannello:
  `prismaCliente, territorio, lettera, film, disegna, settimanaAnno, palestra, prismaLuce, capsula, traguardi, giocoRischio,
  giornataPensione, lanciaAnno, valoreConsulente, realtaAumentata` (gruppo `.davantiAlCliente`) e
  `stanotte, propostaDaSola, compilaDaSolo, dopoLaFirma, sinistro, trovaLaPagina, smontaggio, radar, campagne, nuovoCliente,
  passaparola, imprenditori, notaVocale, speseScadenze` (gruppo `.lavoro`);
  per ogni caso `titolo`, `frase`, `gruppo`, `glifo: GlifoLuce` (§4.1), `colore` (dal glifo, `Tema.Apple.Colore.Glifi`),
  `app: AppPrisma`, `dove` (per avviso e VoiceOver), `disponibile`, `avvisoInArrivo`; `static let versione = "luce"`;
- `NovitaOrizzonte` resta nel codice (le sue destinazioni servono alla Guida di Prisma e al menu Aiuto?) oppure si toglie:
  vedi decisioni;
- **`PannelloNovita`** diventa a due gruppi: testata «✦ Le novità» + «\(NovitaLuce.allCases.count) funzioni da provare»;
  per ogni gruppo l'etichetta («Davanti al cliente · 15», «Per il tuo lavoro · 14», con il numero contato) e una
  `LazyVGrid` a 3 (o 2) colonne di `RigaNovitaGriglia` (tassello, titolo, frase; niente numero, niente freccia);
- **`StatoShell.apriVoceNovita(_ voce: NovitaLuce)`**: stesso schema di oggi, con le destinazioni nuove:
  - esperienze della Sala → `apriEsperienza(_:)` (§3.5);
  - Territorio, Pratiche (con la scheda), Biblioteca → `apri(_:)` con la scheda preparata;
  - «La tua settimana, il tuo anno» → la storia (§4.5, sezione della novità);
  - «Stanotte Prisma ha lavorato» → le carte della notte (§4.5, sezione della novità);
  - «Nuovo cliente in 10 secondi», «La nota vocale» → l'app e poi la scena del telefono (§4.2), con l'attesa
    `Tema.Apple.Moto.PannelloNovita.attesaScena` (**nuovo**: 0,4 s con l'app già davanti, 0,9 s se no; in Prisma meglio
    «a volo finito», cioè al termine di `VoloDallIcona`, se lo stato lo sa dire);
  - le viste nuove delle app esistenti (Posizioni › Radar/Smontaggio, Messaggi › Campagne, Clienti › Passaparola e
    Azienda, Studio › Palestra/Spese) → la scheda o la vista nuova delle rispettive sezioni (nomi proposti lì);
- `Impostazioni.novitaViste` passa a «luce»: il pannello si riapre da solo **una volta** dopo l'aggiornamento (come per
  Orizzonte); `ProvaBackup` riga 121 va aggiornata;
- la prova del pannello **esiste già** in `Ruby/ProvaRuby.swift` (righe 432-434: `NovitaOrizzonte.allCases.count == 11`,
  titoli unici, app del dock, `numero` da 1 a 11): va riscritta per `NovitaLuce` (29 voci, 15 + 14 per gruppo, titoli
  unici, ogni `app` è in `AppPrisma.delDock` e consentita fuori dal modo cliente; il controllo su `numero` sparisce,
  perché le voci di Luce non hanno numero).

#### 1.1.6 Dati che l'utente deve dare e stati vuoti

Il pannello non mostra dati dei clienti: nessun dato da chiedere. Stati:
- voce di una funzione non ancora fatta: apre l'app che la ospiterà con l'avviso «arriva con un prossimo aggiornamento»;
- un'app che non si apre in modalità cliente (§2.5, `appRiservate`): il pannello non si apre affatto in modalità cliente
  (regola di oggi, `apriNovita`).

#### 1.1.7 Istantanee da aggiungere

Numeri: in `Sources/` le istantanee del Mac arrivano a **613**; le sezioni delle novità di Luce usano **620-668** e **700-836** (verificato con grep sui file della cartella `luce/`). La parte comune prende quindi **614-619** (Novità, scrivania, icone, app nuove, glifi) e **690-695** (Sala), liberi in tutti e due. In chiaro e in scuro dove
indicato (suffisso `-scuro`).

| Nome | Scena |
|---|---|
| `614-novita-luce` / `-scuro` | pannello aperto sulla scrivania, 29 voci ferme, due gruppi, tre colonne |
| `615-novita-luce-stretta` | finestra di Prisma alla larghezza minima (1100): due colonne, scorrimento |
| `501-novita-pannello` (esistente) | da togliere o da rifare come `614` (stesso scatto) |
| `400-vetrina-apple` / `-scuro` (esistente) | aggiungere una voce della griglia con il tassello e il passaggio |

#### 1.1.8 Regole di CLAUDE.md toccate e decisioni

Regole: tema Apple e valori in `DesignSystem` (token nuovi sopra); movimento con «Riduci movimento» e istantanee; nessuna
uscita dal Mac (il pannello non tocca dati né rete).

**Decisioni per l'utente:**
1. **Voci di Orizzonte**: in Luce il pannello mostra solo le 29 novità di Luce. Le 11 di Orizzonte spariscono dal pannello
   (restano raggiungibili dalle app e dalla Guida). Proposta: sì.
2. **Due colonne sotto 1180**: il template non lo prevede (palco fisso 1440). Proposta: 3 → 2 colonne.
3. **Colori dei tasselli uguali ai colori dei canali**: «Quanto vale avermi accanto» usa #2563EB (= canale Alleanza) e
   «Lancia l’anno» #B06E12 (= canale indipendente). CLAUDE.md vuole il canale sempre riconoscibile: un tassello blu o cuoio
   non è un'etichetta di canale, ma accanto alle etichette può confondere. Proposta: tenere i colori del template (sono
   tasselli con un glifo, non pillole con un pallino); in alternativa #3B6FD8 e #A8742C. Anche «I traguardi festeggiati» e
   «Il gioco del rischio» hanno lo stesso rosso #E5484D (e «La nota vocale» e «Lo smontaggio» pure).
4. **Pannello su iPad**: oggi no; con 29 voci sull'iPad orizzontale entrerebbe a due colonne. Proposta: restare solo Mac.
5. **Frasi del pannello che promettono un'uscita dal Mac**: «Un minuto da mandare su WhatsApp» (film), «Lo stato in tempo
   reale, anche per il cliente» (sinistro), «La sua app personale, in un file» (Prisma del cliente), «Tra una visita e
   l’altra, dall’iPhone» (nota vocale), «La carta d’identità compila l’anagrafica» (fotocamera), «La mattina trovi tutto
   pronto» (lavoro notturno, in background). Il pannello non manda nulla, ma le frasi dipendono dalle decisioni di privacy
   prese nelle sezioni di quelle novità (invio a WhatsApp o a terzi, file dato al cliente, notifiche al cliente,
   fotocamera, microfono, lavoro in background). Proposta: `NovitaLuce.frase` segue la decisione presa (per esempio «Un
   minuto da mostrare dopo l’incontro» se l'invio a WhatsApp non è accettato), mai una promessa che Prisma non mantiene.

---

### 1.2 Le app nuove nel dock e sulla scrivania

#### 1.2.1 Cosa si vede

**Dock** (`DOCK`, riga 475; disegno 476-482): **16 voci** (Orizzonte ne aveva 12), in quest'ordine:

**Scrivania · Clienti · Posizioni · Analisi 360 · Incontri · Agenda · Territorio · Messaggi · Pratiche · Prospetti · Sala ·
Biblioteca · Mercato · Studio · Ruby · Impostazioni**

Entrano **Territorio** (dopo Agenda), **Pratiche** (dopo Messaggi), **Sala** (dopo Prospetti) e **Biblioteca** (dopo Sala).
La richiesta parla di tre app nuove (Pratiche, Biblioteca, Territorio): nel template le app nuove sono **quattro**, perché
anche **Sala**, la casa delle 11 esperienze, ha la sua icona e la sua finestra. L'Agenda mostra ancora «NOV» e «2»;
ingrandimento, pallino e rimbalzo non cambiano.

**Le quattro icone nuove** (`<template id="sorgenti-icone">`, righe 2114-2296, una `<div data-icona="…">` per icona:
Sala 2115, Territorio 2160, Pratiche 2205, Biblioteca 2250). Ho confrontato ogni SVG con `Design/Icone/Studio.svg`
(prodotta da `genera-icone.js`) togliendo titolo, fermate del fondo e glifo: **il resto è identico carattere per
carattere** (4517 caratteri). Cambiano solo:

| Icona | Fondo c1 → c2 | Glifo (riquadro 64, dentro `translate(16 12) scale(7.5)`) |
|---|---|---|
| **Sala** | #8E7CF4 → #4B3BB8 (viola) | schermo `.g1` 48×32 raggio 6,5 in (8,12) con il triangolo «play» #5B4BC8 (`M28 21.5v13.5l11.5-6.75z`); piede `.g2` 22×4,2 raggio 2,1 in (21; 48,5); stellina `.g1` a quattro punte in alto a destra (centro 51; 10) |
| **Territorio** | #5BB8DE → #2A6FA0 (azzurro mare) | mappa piegata `.g2` (`M7 18.5l15-5.5 20 6 15-5.5v34l-15 5.5-20-6-15 5.5z`) con le due pieghe bianche al 55% spesse 1,6; spillo `.g1` con il foro #2A6FA0 (r 4,8 in 32; 21,8) |
| **Pratiche** | #7FB8A4 → #3E7D69 (verde salvia) | due fogli sovrapposti (dietro `.g2`, davanti `.g1` con l'orecchia); due spunte #3E7D69 spesse 2,6 con capi tondi e due righe #3E7D69 al 50% 10×2,6 |
| **Biblioteca** | #C89B6D → #8A5A35 (cuoio chiaro) | quattro dorsi: `.g1` 9×38, `.g2` 8×34, `.g1` 9×40, e un quarto `.g2` inclinato (`M44 17.5l7.6-2 8 33.4-7.6 2z`); due etichette #8A5A35 al 50% 4×2,4 |

**Finestre delle app nuove** (testata; il contenuto sta nelle sezioni delle novità):

| App | Barra (`t`) | Testata (`h`) | Occhiello (`sub`) | Comandi a destra (`act`) | Riga |
|---|---|---|---|---|---|
| Territorio | Territorio | Il tuo territorio. | I clienti nella tua zona | segmenti **Oggi · La crescita · Il giro di domani** | 1661-1662 |
| Pratiche | Pratiche | Le pratiche. | Dalla proposta al sinistro | segmenti **Proposta · Moduli · Dopo la firma · Sinistri** | 1848-1849 |
| Sala | Sala | La sala. | Le esperienze da vivere con il cliente | segmenti dei **clienti** con l'avatar 24 e il nome (§3) | 1208-1209 |
| Biblioteca | Biblioteca | La tua biblioteca. | Condizioni, circolari e normativa | nessuno | 1913 |

**Scrivania** (riga 487): in alto a destra i pulsanti di vetro diventano **«☾ Stanotte» · «▶︎ La tua settimana» ·
«⌕ Cerca ovunque»** (in Orizzonte: «◫ Nuovo cliente» · «⌕ Cerca ovunque»). «Nuovo cliente» si sposta nella testata di
Clienti («Nuovo cliente» blu con il glifo `scan`, riga 2078). Il resto della scrivania è identico a Orizzonte (mossa del
giorno, agenda, portafoglio, Ruby, «Il tuo studio», scadenze).

**Le altre app esistenti** ricevono nella testata i comandi delle novità (righe 2073-2088; il contenuto sta nelle
sezioni delle novità):

| App | Comandi nuovi nella testata |
|---|---|
| Messaggi | segmenti **Messaggi · Campagne** |
| Clienti | segmenti **Rubrica · Potenziali · Passaparola** e il pulsante blu **«Nuovo cliente»** (glifo `scan`); nel dossier la scheda **Azienda** |
| Posizioni | segmenti **Portafoglio · Radar · Prova del fuoco · Smontaggio** e «◎ Inquadra con l’iPhone» |
| Studio | **«▶︎ Il tuo anno»** e segmenti **Cruscotto · Parcelle · Track record · OCF · Palestra · Spese** (i titoli «Parcelle e fatture» ed «Esame OCF» si accorciano in «Parcelle» e «OCF» per farci stare sei voci) |
| Incontri | pulsante **«Nota dall’iPhone»** (glifo `voce`) |

**Stati.** Il template non ha stati vuoti delle finestre nuove: sono nelle sezioni delle novità. In Prisma una finestra
nuova il cui contenuto arriva in un giro successivo mostra la testata e il messaggio sobrio `AppPrisma.inArrivo` (come le
app «in arrivo» di Orizzonte).

#### 1.2.2 Misure e stile

| Cosa | Valore |
|---|---|
| Dock del template | invariato per voce (icona 50, voce 62, spazio 4, padding 8 10 5, raggio 26); con 16 voci è largo **16·62 + 15·4 + 20 + 2 = 1074** (misurato 1074) |
| Dock di Prisma | `DisposizioneDock.disposizione(icone:)`: icona 50, spazio 6, margine laterale 19, divisore dopo la Scrivania. Con 16 icone circa **936** a riposo: sta nella finestra minima (1100). L'ingrandimento (fino a 1,36) resta dentro |
| Icone | PNG 512 in `Sources/Prisma/Risorse/Icone/` (`Sala.png`, `Territorio.png`, `Pratiche.png`, `Biblioteca.png`), SVG in `Design/Icone/` |
| Testate | come le altre finestre (`Tema.Apple.Misura.Finestra`, `Carattere.titoloFinestra` 17 bold, occhiello `Carattere.sottotitolo` 12 medium maiuscolo) |
| Pulsanti della scrivania | `.btn.glass`: come «Nuovo cliente» oggi (`.buttonStyle(.appleVetro)`, `Tema.Apple.Scrivania.Saluto.spazioPulsanti`); i segni «☾» e «▶︎» si rendono con i simboli `moon` e `play.fill` o con i caratteri del template |

Colori nuovi: i fondi delle quattro icone servono **solo** allo script delle icone, non all'app.

#### 1.2.3 Movimento

Nessun movimento nuovo: le app nuove si aprono come le altre (volo dall'icona 0,6 s `(.3,1.12,.5,1)`, rimbalzo
dell'icona, cascata del contenuto 0,72 s con passo 48 ms, base 140 ms; `monta`, righe 528-540). Cambiare segmento in una
testata usa `rimonta` (§4.7). Riduci movimento e istantanee come oggi (`VoloDallIcona` già fermo).

#### 1.2.4 Interazioni

Mac:
- clic sull'icona: apre l'app; passaggio: ingrandimento; ⌥1…⌥9 per le prime nove (`PrismaApp.swift` riga 122,
  `AppPrisma.delDock.prefix(9)`; lo stesso elenco è mostrato in Impostazioni, `Shell/AppImpostazioni.swift` riga 511, che
  si aggiorna da solo ma va riguardato nelle istantanee di Impostazioni). Con l'ordine nuovo: ⌥1 Clienti, ⌥2 Posizioni, ⌥3 Analisi 360, ⌥4 Incontri, ⌥5 Agenda,
  **⌥6 Territorio, ⌥7 Messaggi, ⌥8 Pratiche, ⌥9 Prospetti**. Oggi ⌥6 è Messaggi, ⌥7 Prospetti, ⌥8 Mercato, ⌥9 Studio:
  **Mercato e Studio perdono la scorciatoia**. È un cambio visibile da annunciare (vedi decisioni);
- «☾ Stanotte» apre le carte della notte (`apriNotte`), «▶︎ La tua settimana» la storia della settimana
  (`apriStoria('settimana')`), «⌕ Cerca ovunque» la ricerca (oggi un toast nel template; in Prisma `cercaOvunque()`).

iPhone e iPad: sull'iPad il dock contiene **tutte** le app del dock del Mac più «Tutte le app» (`DockMobile.swift`,
`DisposizioneDockMobile.app(.iPad, …) = AppPrisma.delDock`), e il lato si riduce con `fitDock` fino al minimo. Con 15 app +
Scrivania + Tutte le app = **17 elementi** il lato scende molto sull'iPad verticale. Sull'iPhone il dock resta di quattro
app (`appTelefono`) e le app nuove compaiono in «Tutte le app».

#### 1.2.5 Mappa verso Prisma

**`Shell/AppPrisma.swift`** (`enum AppPrisma: String, CaseIterable, Identifiable, Codable`):
- casi nuovi **`territorio`, `pratiche`, `sala`, `biblioteca`** (raw value uguale al nome);
- nuovo ordine di `allCases` per avere `delDock` = `clienti, posizioni, analisi360, incontri, agenda, territorio, messaggi,
  pratiche, presentazioni, sala, biblioteca, mercato, studio, ruby, impostazioni` (le app accorpate e quelle fuori dal dock
  restano dove sono: l'ordine conta solo per `delDock` e `altreApp`);
- `titolo` / `nomeDock`: «Territorio», «Pratiche», «Sala», «Biblioteca»;
- `titoloIntestazione`: «Il tuo territorio.», «Le pratiche.», «La sala.», «La tua biblioteca.»;
- `occhiello`: «I clienti nella tua zona», «Dalla proposta al sinistro», «Le esperienze da vivere con il cliente»,
  «Condizioni, circolari e normativa»;
- `sottotitolo` (proposta, il template non li ha): Territorio «Dove sono i tuoi clienti», Pratiche «Dalla proposta al
  sinistro», Sala «Da vivere insieme al cliente», Biblioteca «La pagina giusta, subito»;
- `icona`: «Territorio», «Pratiche», «Sala», «Biblioteca»;
- `inArrivo` per i quattro casi (frase sobria per i giri in cui il contenuto non c'è ancora).

**Viste nuove** (contenuto nelle sezioni delle novità; qui solo l'aggancio): `Shell/AppTerritorio.swift`,
`Shell/AppPratiche.swift`, `Shell/AppSala.swift` (§3), `Shell/AppBiblioteca.swift`, registrate dove la shell sceglie la
vista di ogni app (`Shell/ContenutoApp.swift`). Schede nuove: `enum VistaTerritorio { oggi, crescita, giro }`,
`enum SchedaPratiche { proposta, moduli, dopoLaFirma, sinistri }` (nomi proposti).

**Modalità cliente** (`Shell/ModoCliente.swift`, `StatoShell.appRiservate = [.note, .ricerca, .impostazioni]`):
- **Territorio** mostra tutti i clienti sulla mappa → **riservata**;
- **Pratiche** elenca bisogni e pratiche di più clienti → **riservata**;
- **Biblioteca** non mostra dati dei clienti (documenti di prodotto e normativa) → consentita (ma le domande d'esempio
  citano clienti: in modalità cliente niente suggerimenti con nomi);
- **Sala** è fatta per il cliente → consentita, con le pillole ridotte al solo cliente presente (§3.5).
Proposta: `appRiservate = [.note, .ricerca, .impostazioni, .territorio, .pratiche]`. Attenzione: anche Studio, Messaggi
e Mercato oggi non sono riservate, ma il pannello Novità che porta lì non si apre in modalità cliente: da rivedere
insieme (decisione).

**Scrivania**: `Shell/ScrivaniaApple.swift`, `pulsanti` (righe 318-338): «Nuovo cliente» lascia il posto a «Stanotte» e
«La tua settimana», «Cerca ovunque» resta. «Nuovo cliente» va nella testata di Clienti (sezione «Nuovo cliente in 10
secondi»; `richiestaNuovoCliente` resta). Il commento in testa al file (riga 5) va aggiornato.

**Archivio e compatibilità**: `AppPrisma` è salvata negli spazi di lavoro (`Dati/SpaziLavoro.swift`,
`FinestraSpazio.app`, decodifica non tollerante) e quindi nei backup e nell'istantanea di «Prisma ovunque». Un Prisma più
vecchio (per esempio l'iPhone non ancora aggiornato) che legge uno spazio con `sala` non lo decodifica. Proposta:
`FinestraSpazio` letta con tolleranza (una finestra di un'app sconosciuta si salta) e la prova in `--prova-backup`
(`Dati/ProvaBackup.swift`) e `--prova-ovunque` con uno spazio che contiene le quattro app nuove.

**Icone: come generarle con `Design/Icone/genera-icone.js`.** Oggi lo script legge le icone nuove solo da
`Design/template-novita.html` (`NOVITA`, riga 42; `ICONE_NUOVE = ['Studio','Messaggi','Mercato']`, riga 63;
`leggiNovita()`, righe 180-210, che cerca `<template id="sorgenti-icone">`, poi per ogni nome
`<div data-icona="Nome">`, le due fermate di `<linearGradient id="fondo">` e il glifo dentro
`<g transform="translate(16 12) scale(7.5)">`). Le quattro icone di Luce hanno **esattamente la stessa forma** (verificato),
quindi basta generalizzare la sorgente:
1. aggiungere `const LUCE = path.join(RADICE, 'Design', 'template-luce.html');`;
2. sostituire `ICONE_NUOVE` con un elenco di sorgenti:
   `const SORGENTI_NUOVE = [[NOVITA, ['Studio', 'Messaggi', 'Mercato']], [LUCE, ['Sala', 'Territorio', 'Pratiche', 'Biblioteca']]];`
   e far leggere a `leggiNovita(file, nomi)` il file giusto (il corpo della funzione non cambia), con un ciclo
   `for (const [file, nomi] of SORGENTI_NUOVE) for (const n of leggiNovita(file, nomi)) { … }` al passo «2b»;
3. il messaggio finale e `--solo-nuove` contano tutte e sette le icone nuove;
4. eseguire, senza toccare le PNG esistenti (Chromium su Linux non le rifà identiche byte per byte):
   `NODE_PATH=$(npm root -g) node Design/Icone/genera-icone.js --solo-nuove`
   (prova prima con `--uscita /tmp/prova`); escono `Design/Icone/{Sala,Territorio,Pratiche,Biblioteca}.svg`, le PNG 512
   in `Sources/Prisma/Risorse/Icone/` e la tavola `Design/Icone/Anteprima_icone.png`, dove le icone vanno anche
   nell'ordine del dock (`voci.splice(8, …)` mette l'Agenda: va spostato se l'ordine cambia);
5. aggiornare `Design/Icone/LEGGIMI.txt`: «Da dove vengono» (`template-luce.html`), la mappatura (Sala → Sala,
   Territorio → Territorio, Pratiche → Pratiche, Biblioteca → Biblioteca) e una tabella «Icone nuove di Luce» con fondo e
   glifo come quella di Orizzonte;
6. il workflow non rigenera le icone: le PNG vanno committate.

**Prove da aggiornare**: `Ruby/ProvaRuby.swift` riga 425 (`AppPrisma.delDock.count == 11` → **15**, e l'ordine nuovo);
`iOS/ProvaDockMobile.swift` righe 26, 54, 65 (il dock dell'iPad conta `delDock.count + 2`; in modalità cliente le
riservate nuove non ci sono).

#### 1.2.6 Dati che l'utente deve dare e stati vuoti

Nessun dato per il dock e le icone. Da confermare (vedi decisioni): **l'ordine del dock** e quali app restano senza
scorciatoia. Gli stati vuoti delle quattro finestre stanno nelle sezioni delle novità (per esempio Territorio senza
indirizzi o comuni dei clienti, Biblioteca senza documenti caricati, Pratiche senza bisogni scoperti, Sala senza cliente,
§3.6).

#### 1.2.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `616-scrivania-luce` / `-scuro` | scrivania sbloccata: dock a 16 voci, pulsanti «Stanotte», «La tua settimana», «Cerca ovunque» |
| `617-icone-luce` | tavola delle icone nell'ordine del dock su fondo chiaro e scuro, per confrontare Pratiche con Incontri, Biblioteca con Clienti, Sala con Ruby |
| `618-app-nuove-territorio`, `618-app-nuove-pratiche-scuro`, `618-app-nuove-sala`, `618-app-nuove-biblioteca-scuro` | le quattro finestre aperte (icona, titolo, occhiello, comandi, pallino del dock), come `505-app-nuove-*` |
| `410-scrivania-apple` / `500-scrivania-orizzonte` (esistenti) | da rifare: cambiano dock e pulsanti |
| iOS `54-tutte-le-app-luce` | «Tutte le app» sull'iPhone con le quattro app nuove |
| iOS `55-dock-ipad-luce` | dock dell'iPad verticale con 17 elementi (per decidere se va ridotto) |

#### 1.2.8 Regole di CLAUDE.md toccate e decisioni

Regole: «Struttura: un'unica finestra… dock»; «Le icone vanno convertite in PNG… mantenendo l'aspetto originale»
(`genera-icone.js`); «Principio permanente: il fulcro è Posizioni, subito dopo Clienti nel dock» (rispettato: l'ordine
dei primi tre non cambia); modalità cliente; nessuna dipendenza nuova (lo script usa Playwright già presente).

**Decisioni per l'utente:**
1. **Quattro app nuove, non tre**: anche Sala entra nel dock con la sua icona. Proposta: sì, come nel template.
2. **Ordine del dock e scorciatoie**: con 15 app Mercato (⌥8) e Studio (⌥9) perdono la scorciatoia. Proposta: tenere
   l'ordine del template e annunciarlo nella Guida; in alternativa ⌥0 per la decima app.
3. **Dock dell'iPad** con 17 elementi: proposta di tenere nel dock dell'iPad solo le app del Mac fino a Prospetti, più
   Sala e Ruby (Sala è quella che serve davanti al cliente), il resto in «Tutte le app».
4. **Colori delle icone troppo vicini**: Pratiche (#7FB8A4 → #3E7D69) è quasi uguale a Incontri (#6FAE98 → #3A7563);
   Biblioteca (#C89B6D → #8A5A35) quasi uguale a Clienti (#C9A584 → #8C6849); Sala (#8E7CF4 → #4B3BB8) vicina a Ruby
   (#B9A3F2 → #6862C9). I glifi sono diversi, ma nel dock piccolo conta il colore. Proposta: tenerli (sono le sorgenti del
   template, la grafica la decide l'utente) e guardare insieme la tavola `617-icone-luce`.
5. **Modalità cliente**: Territorio e Pratiche riservate; Biblioteca e Sala consentite (proposta).
6. **«Nuovo cliente» lascia la scrivania** e va nella testata di Clienti. Proposta: sì, come nel template.
7. **«☾ Stanotte» sulla scrivania** presuppone il lavoro notturno di Prisma (lavoro in background, con il Mac a riposo
   o con l'app chiusa): è una decisione della sezione «Stanotte Prisma ha lavorato». Se il lavoro in background non è
   accettato, il pulsante diventa «Stamattina» (le stesse carte preparate all'apertura) o sparisce. Proposta: il pulsante
   segue quella decisione.
8. **Le quattro icone** sono di Luce e passano da `genera-icone.js` senza cambiare aspetto; i fondi sono fuori da
   `Tema.Apple` (servono solo allo script), come per Studio, Messaggi e Mercato. Nessuna dipendenza nuova: lo script usa
   Playwright già usato per le icone di Orizzonte, che **non** entra nell'app né nel workflow.

---

### 1.3 La Sala: la cornice comune delle esperienze

#### 1.3.1 Cosa si vede

La **Sala** (`APPS.sala`, righe 1208-1225) è l'app che ospita le 11 esperienze «davanti al cliente»: Il Prisma del cliente,
Il prisma di luce, La lettera dal futuro, Il film del piano, Disegna il tuo futuro, Il gioco del rischio, Una giornata della
pensione, Lancia l’anno, Quanto vale avermi accanto, La capsula del tempo, La realtà aumentata (`ESP`, righe 1189-1200,
in quest'ordine). Il contenuto di ogni esperienza (`ESPH[k]`, `ESPM[k]`) sta nella sua sezione; qui la **cornice**.

**Testata della finestra** (riga 1209): «La sala.» + «LE ESPERIENZE DA VIVERE CON IL CLIENTE»; a destra un **segmentato a
pillola dei clienti**: per ognuno l'avatar 24 (iniziali bianche sul gradiente del cliente) e il nome di battesimo
(«Giulia», «Marco», «Laura», «Andrea», «Sofia»).

**Griglia** (`salaHTML`, righe 1212-1216; `01-c-sala.png`): occupa tutto il contenuto della finestra (1384×654), **6 colonne
e 2 righe**:
- **prima colonna (1,35 fr), alta due righe**: la scheda grande **«Il Prisma del cliente»**: tassello 60 con il glifo
  `prisma`; sotto, a 26, **«Ciao Giulia.»** (38 bold), «Il tuo piano, sempre con te.» (14 grigio), e una fila di **tre
  anelli** da 70 (tratto 8) con i primi tre obiettivi del cliente (percentuale `cur/target`, colore dell'obiettivo) e il
  nome sotto (11, al più 76 di larghezza); in fondo il titolo «Il Prisma del cliente» (26 bold) e la frase «La sua app
  personale, in un file da mandargli» (14);
- **le altre dieci, 5 per riga**: tassello 44 con il glifo, e in fondo il titolo (17 bold) e la frase (12,5 grigio, due
  righe al più): riga 1 prisma di luce, lettera, film, disegna, rischio; riga 2 giornata, dadi, valore, capsula, AR.

Frasi delle schede (`ESP[].d`, diverse da quelle del pannello Novità):

| Esperienza | Frase nella scheda | Tassello |
|---|---|---|
| Il Prisma del cliente | La sua app personale, in un file da mandargli | #0A84FF |
| Il prisma di luce | Il patrimonio che si scompone in raggi | #5B4BC8 |
| La lettera dal futuro | Scritta da sé stesso a 67 anni | #C45A75 |
| Il film del piano | Un minuto da mandare dopo l’incontro | #E08A00 |
| Disegna il tuo futuro | Lo scarabocchio diventa un piano | #30B15C |
| Il gioco del rischio | Il profilo vissuto, non dichiarato | #E5484D |
| Una giornata della pensione | Il divario diventa una vita concreta | #2A9BC8 |
| Lancia l’anno | Due vite affiancate, con e senza piano | #B06E12 |
| Quanto vale avermi accanto | Il tuo lavoro, in cifre | #2563EB |
| La capsula del tempo | Un messaggio sigillato fino al traguardo | #9B6FB5 |
| La realtà aumentata | Il patrimonio sul tavolo, dall’iPhone | #1E9E6A |

**Palco** (`palcoHTML`, righe 1217-1220; `01-c-palco-lettera.png`): aprendo una scheda, la griglia lascia il posto a:
- una **riga di testata alta 40**: pulsante «‹ Sala», tassello 32 (raggio 10, glifo 17), il **nome dell'esperienza**
  (`.h2`, 21 bold) e «· Giulia Rossi» (14 grigio); a destra, secondo l'esperienza:
  - **«▣ Mostra sul tavolo»** in tutte **tranne** Il Prisma del cliente, Quanto vale avermi accanto e La capsula del tempo;
  - **«✦ Aggiungi al Prisma di Giulia»** solo in La lettera dal futuro, Il film del piano, Il prisma di luce, Una giornata
    della pensione e Disegna il tuo futuro;
- sotto, a 52 dall'alto, la **card del palco** (`#palco`, `.card`, raggio 22, `top 52; bottom 0`: occupa il resto del contenuto, **602** nella finestra del template, contenuto ritagliato) con
  l'esperienza.
La pillola dei clienti resta nella testata della finestra: cambiare cliente rifà l'esperienza per lui.

**Presentazione al cliente e sala opaca.** Il template **non ha** una presentazione a tutto schermo delle esperienze:
l'esperienza si mostra nella finestra (la Sala è pensata per lo schermo girato verso il cliente) oppure «sul tavolo», cioè
sull'iPad davanti al cliente (oggi solo un toast: «Sull’iPad del tavolo: «Il film del piano»», riga 1223). La sola sala
opaca del template resta quella dei Prospetti (`#show`, righe 281 e 815-820: velo rgba(6,14,20,.92), z 96). Le storie
(«La tua settimana», «Il tuo anno») e le carte della notte usano velature proprie a tutto palco (§4.5). Prisma deve
decidere come «presentare al cliente» un'esperienza: vedi §3.4 e decisioni.

**Stati** (il template ha solo il pieno; proposte per Prisma, §3.6): nessun cliente in archivio; cliente scelto senza
obiettivi (gli anelli della scheda grande); esperienza non ancora fatta in questo giro; tavolo chiuso.

#### 1.3.2 Misure e stile

| Cosa | Valore (template) | Token in Prisma |
|---|---|---|
| Griglia | `grid-template-columns: 1.35fr repeat(5,1fr)`, 2 righe uguali, spazio 12, alta il 100% del contenuto | **nuovo** `Tema.Apple.SalaEsperienze.Griglia`: `quotaPrima = 1.35`, `colonne = 5`, `spazio = 12` (= `Misura.Spazio` a 12 se c'è) |
| Scheda | `.card`: raggio 22, `--card`, filo `--sep`, ombra `--shadow`; padding **24** (grande) e **16** (piccole); contenuto ritagliato | `Superficie.card`, `Raggio.card`; **nuovi** `paddingGrande = 24`, `paddingPiccola = 16` |
| Inclinazione | `.tilt`, massimo **4°** per la grande e **7°** per le piccole (`data-max`), prospettiva 900, sale di 5, scala 1,02, riflesso | `.inclinazione(massimo:)` (`SchedeApple.swift`); **nuovi** `Tema.Apple.Moto.Inclinazione.massimoSalaGrande = 4`, `massimoSala = 7` |
| Tassello | 60 (grande, glifo 30) e 44 (piccole, glifo 22), raggio **14** fisso (`.espI`) | `TasselloGlifo` (§4.1) con `raggio: Raggio.voce` |
| Saluto | «Ciao Giulia.» 38 bold, spaziatura −1, a 26 sotto il tassello | `Carattere.saluto` (38 bold −1,2: differenza di 0,2 trascurabile, proposta: riusare) |
| Sottotitolo | 14 `--ink2` | `Carattere.corpo` + `inchiostro2` |
| Anelli | 70, tratto 8, spazio 10, binario al 15%; etichetta 11 grigia, larga al più 76, a 4 | `Anello` (`AnelliApple.swift`); **nuovi** `anello = 70`, `trattoAnello = 8`, `etichettaAnello = Carattere(dimensione: 11, peso: .regular)` |
| Titolo scheda | 26 (grande) / 17 (piccole) bold, spaziatura −0,3, interlinea 1,2 | **nuovi** `titoloGrande = Carattere(dimensione: 26, peso: .bold, tracking: -0.3, interlinea: 1.2)`, `titolo = Carattere(dimensione: 17, peso: .bold, tracking: -0.3, interlinea: 1.2)` |
| Frase scheda | 14 / 12,5 `--ink2`, a 4, interlinea 1,35 | `Carattere.corpo` / `Carattere.secondario` |
| Pillole dei clienti | `.seg` con voci padding 4 12 4 4, avatar 24, spazio 6 | `SegmentatoPillola` con `icona` (come `PilloleClienti360`, `Tema.Apple.Aree360.Testata.avatar`, `pilloleMassime = 5`) |
| Testata del palco | riga alta 40, spazio 12; «‹ Sala» `.btn`; tassello 32 raggio 10, glifo 17; nome `.h2` 21 bold −0,4; cliente 14 `--ink2`; pulsanti a destra spazio 6 | `Carattere.h2`, `StilePulsanteApple`; **nuovi** `Palco.altezzaTestata = 40`, `Palco.tassello = 32`, `Palco.raggioTassello = 10` |
| Card del palco | a **52** dall'alto, piena larghezza, fino in fondo al contenuto (602 nel template), `.card` | **nuovo** `Palco.dallAlto = 52` |

Nome dei token: **`Tema.Apple.SalaEsperienze`**, non `Tema.Apple.Sala`, perché `Tema.Apple.Prospetti.Sala` e
`Tema.Apple.Moto.Sala` esistono già e sono la sala della presentazione dei Prospetti. File nuovo
`DesignSystem/Apple/Tema.Apple+SalaEsperienze.swift`.

Scuro (`01-s-sala.png`): cambiano solo card, inchiostri e binari degli anelli; i tasselli restano uguali.

#### 1.3.3 Movimento

| Cosa | Da → a | Durata | Curva | Ritardo |
|---|---|---|---|---|
| Apertura della Sala | come ogni app (volo, cascata delle schede `.st`) | 0,6 s / 0,72 s | `(.3,1.12,.5,1)` / `uscita` | base 0,14 + i·0,048 |
| Anelli della scheda grande | si riempiono | 1,4 s | `uscita` | `accendi(wc,320)`: 0,32 + i·0,13 s |
| Inclinazione | verso il puntatore | 0,5 s | `molla` | — |
| Tassello al passaggio | scala 1 → 1,06 | 0,4 s | `molla` | — |
| Clic su una scheda | la scheda va a scala 1,05 e opacità 0,4 | 0,18 s | ease-in | 0 |
| Cambio griglia → palco | `rimonta`: il contenuto svanisce a scala 0,99 (0,13 s), poi la testata del palco entra in cascata | 0,13 s + 0,72 s | lineare + `uscita` | parte 0,12 s dopo il clic |
| Card del palco | opacità 0, scala 0,98 → ferma | **0,52 s** | `uscita` | insieme alla cascata |
| «‹ Sala» o cambio cliente | `rimonta` della griglia o del palco (anelli con `accendi(wc,150)`: 0,15 + i·0,13 s, riga 845) | come sopra | — | — |

**Proposta di movimento più vicino al tema Apple**: «il dettaglio nasce dalla scheda toccata e ci torna» (CLAUDE.md). Il
template fa solo un ingrandimento della scheda e una dissolvenza; in Prisma il palco può **crescere dalla scheda**
(`matchedGeometryEffect` della card sulla card del palco, che c'è da macOS 11) e tornarci con «‹ Sala». Da confermare.

Token **nuovi**: `Tema.Apple.Moto.SalaEsperienze`: `sceltaScheda (durata 0.18, scala 1.05, opacità 0.4)`,
`ritardoRimonta 0.12`, `palco (durata 0.52, scala 0.98, curva uscita)`; per `rimonta` si riusano
`Tema.Apple.Studio.Moto.durataRimonta`/`scalaRimonta` (esistono).

**Riduci movimento**: niente inclinazione, niente ingrandimento della scheda, griglia e palco compaiono con la
dissolvenza di 0,15 s; le esperienze con tele animate restano ferme sul loro stato finale (§4.3). **Istantanee**: griglia
con gli anelli pieni; palco già entrato.

#### 1.3.4 Interazioni

Mac:
- **aprire**: dal dock (griglia), dal pannello Novità o da altri punti (`apriEsp(k, sel)`, riga 1225:
  `vaiA('sala', () => { selSa = sel; espSa = k })`), che apre la Sala direttamente sul palco dell'esperienza `k` e, se
  `sel` è dato, sul cliente `sel`. Usi nel template: pannello Novità (cliente 0), «Apri la capsula» nei traguardi
  festeggiati (`apriEsp('capsula',4)`, riga 1775), le voci della palestra (riga 1756);
- **sfogliare**: clic su una scheda della griglia → palco; nel palco **non** ci sono frecce per passare all'esperienza
  successiva: si torna con «‹ Sala» e se ne sceglie un'altra. Il cambio di cliente con le pillole rifà il palco (o la
  griglia, che cambia «Ciao Giulia.» e gli anelli);
- **chiudere**: «‹ Sala» torna alla griglia; il semaforo rosso o il «‑» chiudono la finestra. **Esc** nel template chiude
  la finestra anche dal palco (non c'è un gestore proprio). Proposta per Prisma: **Esc dal palco torna alla griglia**, Esc
  dalla griglia chiude la finestra (come il dettaglio, `chiudiDet`);
- **«▣ Mostra sul tavolo»**: nel template un toast. In Prisma il tavolo con l'iPad esiste (`Tavolo/TavoloMac.swift`,
  `Shell/AlTavolo.swift`): se il tavolo è aperto e c'è un iPad collegato, l'esperienza va sull'iPad (§3.5); se no il
  pulsante apre il pannello «Al tavolo» come in Prospetti (o dice «Apri il tavolo in Prospetti per mostrarlo sull’iPad»);
- **«✦ Aggiungi al Prisma di Giulia»**: nel template un toast «Aggiunta al Prisma di Giulia». Aggiunge il contenuto
  dell'esperienza (lettera, film, prisma di luce, giornata, disegno) al file personale del cliente (sezione «Il Prisma del
  cliente»); in Prisma il pulsante diventa «✓ Nel Prisma di Giulia» quando è già dentro;
- **presentare al cliente** (proposta, il template non ce l'ha): un pulsante **«▶︎ Presenta»** nella testata del palco
  porta l'esperienza a tutta finestra sopra la **sala opaca** (`Tema.Apple.Colore.sala`, il velo della presentazione dei
  Prospetti), con «Chiudi» bianco in basso come in `VistaPresentazione`; accende la modalità cliente se non è già accesa
  (come `presenta(_:delCliente:)`), e sotto il velo l'acqua si ferma (`scrivaniaCoperta`). In alternativa: niente
  presentazione propria, si usa la modalità cliente con la Sala in finestra (decisione).

iPhone e iPad: il template non mostra la Sala sui dispositivi (solo l'AR dall'iPhone/iPad, sezione propria). L'iPad
mostra già il tavolo; la Sala sull'iPad come app a sé è una decisione.

#### 1.3.5 Mappa verso Prisma

**Esiste già (verificato con grep):**

| Cosa | Dove |
|---|---|
| Scelta del cliente con avatar e varianti 5/4/3 | `Shell/Analisi360Apple.swift` (`PilloleClienti360`, `variantiPillole`, righe 322-337 e 540-590) |
| Avatar | `DesignSystem/Componenti.swift` (`AvatarCliente`) |
| Segmentato | `DesignSystem/Apple/ControlliApple.swift` (`SegmentatoPillola` con `icona:`) |
| Schede inclinabili | `DesignSystem/Apple/SchedeApple.swift` (`inclinazione(massimo:)`) |
| Cascata | `DesignSystem/Apple/CascataApple.swift` (`entrataCascata`) |
| Anelli | `DesignSystem/Apple/AnelliApple.swift` (`Anello`, `AnelliConcentrici`) |
| Avanzamento di un obiettivo | `Motori/MotoreObiettivo.swift` (`MotoreObiettivo.calcola`) |
| Sala opaca della presentazione | `Shell/Presentazione.swift` (`Presentazione`, `presenta(_:delCliente:daPagina:)`, `VistaPresentazione`), `Tema.Apple.Prospetti.Sala`, `Tema.Apple.Moto.Sala`, `Tema.Apple.Colore.sala`; `StatoShell.scrivaniaCoperta` (`Shell/StatoShellFinestre.swift` riga 59) |
| Modalità cliente | `Shell/ModoCliente.swift` (`entraModoCliente(avviso:)`, `inModoCliente`, `appConsentita`) |
| Tavolo con l'iPad | `Tavolo/TavoloMac.swift`, `Tavolo/ProtocolloTavolo.swift` (`MostraTavolo.Genere`: `pagina, prospetto, nelTempo, famiglia, lineaVita`), `Shell/AlTavolo.swift` (`PuntinoTavolo`, pannello, striscia della sala), `iOS/SchermiTavoloiPad.swift`, `Tema.Apple+Tavolo.swift` |
| Rimonta di una vista | `Tema.Apple.Studio.Moto.durataRimonta`, `scalaRimonta`, `uscitaRimonta` |

**Nomi: attenzione a «Esperienza».** In Prisma «esperienza» vuol dire già l'esperienza del cliente in prodotti finanziari
(profilo MiFID): `Cliente.Esperienza` (`Dati/Modelli.swift` riga 303), `EsperienzaCliente` (`Shell/EsperienzaCliente.swift`),
`EsperienzaProdotti`, `DesignSystem/ComponentiEsperienza.swift`, `Motori/ProvaCalcoliEsperienza.swift`. Ogni tipo nuovo della
Sala porta quindi **«Sala»** nel nome (`EsperienzaSala`, `Tema.Apple.SalaEsperienze`) e i nomi generici proposti sotto si
leggono così: `MostraTavolo.Genere.esperienzaSala`, `EsperienzaSalaTavolo`, `VistaPresentazioneSala`, `apriEsperienza(_:)`
solo con un argomento `EsperienzaSala`.

**Da creare:**
- `enum EsperienzaSala: String, CaseIterable, Identifiable` (file `Shell/StatoSala.swift`), nell'ordine di `ESP`:
  `prismaCliente, prismaLuce, lettera, film, disegna, giocoRischio, giornataPensione, lanciaAnno, valoreConsulente,
  capsula, realtaAumentata`; per ogni caso `titolo`, `frase` (della scheda), `glifo: GlifoLuce`, `colore`,
  `mostraSulTavolo: Bool` (falso per `prismaCliente`, `valoreConsulente`, `capsula`), `aggiungeAlPrisma: Bool` (vero per
  `lettera`, `film`, `prismaLuce`, `giornataPensione`, `disegna`), `disponibile` (per i giri), `novita: NovitaLuce`;
- in `StatoShell` (o in uno stato proprio `StatoSala`, per non far ridisegnare la shell): `esperienzaAperta:
  EsperienzaSala?` (nil = griglia); `func apriEsperienza(_ e: EsperienzaSala, cliente id: String? = nil)` che imposta il
  cliente attivo (se dato), l'esperienza e apre `.sala` (= `apriEsp`); `func tornaAllaSala()`;
- `Shell/AppSala.swift`: `AppSala` (griglia o palco), `SchedaEsperienza` (grande e piccola), `TestataPalco`,
  `PalcoEsperienza` (la card che contiene la vista dell'esperienza, scelta con uno `switch` su `EsperienzaSala`; finché
  un'esperienza non c'è, il palco mostra lo stato «in arrivo»);
- la pillola dei clienti: estrarre `PilloleClienti360` in `DesignSystem/Apple/PilloleClienti.swift` (nome proposto) e
  usarla in Analisi 360 e in Sala (stesso comportamento: preferiti prima, il cliente attivo c'è sempre, 5/4/3);
- «Mostra sul tavolo»: nuovo `MostraTavolo.Genere.esperienza` con un `EsperienzaTavolo` (titolo, cliente, e o un'immagine
  PNG del palco disegnata sul Mac, come `PaginaTavolo`, o i dati minimi dell'esperienza); proposta minima: **un'immagine
  del palco** (genere `pagina`, nessun cambio di protocollo); l'iPad non riceve mai altro che ciò che si vede;
- «Aggiungi al Prisma»: l'elenco dei contenuti scelti per il file del cliente sta nella sezione «Il Prisma del cliente»
  (nome proposto lì); qui solo il pulsante, che chiama quel modello;
- la presentazione (se accettata): `presentaEsperienza(_:)` che riusa la sala opaca: o un genere nuovo in `Presentazione`
  (oggi porta `pagine: [AnyView]` di un `DocumentoStampabile`: un'esperienza animata non è una pagina), o una vista
  sorella `VistaPresentazioneEsperienza` con lo stesso velo, la stessa barra in basso («Chiudi») e la stessa regola
  `scrivaniaCoperta` (da estendere: `presentazione != nil || esperienzaPresentata != nil`).

#### 1.3.6 Dati che l'utente deve dare e stati vuoti

La cornice usa solo dati già in archivio: nome del cliente, iniziali e colore dell'avatar, i primi tre obiettivi con
`importoAttuale`/`traguardo` (per gli anelli della scheda grande). Ogni esperienza chiede i suoi dati nella sua sezione.

Stati proposti:
- **nessun cliente** in archivio: la griglia c'è, la scheda grande dice «Ciao.» e «Scegli un cliente per iniziare», le
  schede sono spente (opacità 0,55) e un clic porta a Clienti;
- **cliente senza obiettivi**: al posto dei tre anelli la frase «Nessun obiettivo ancora: aggiungilo nel dossier» (mai
  anelli inventati);
- **meno di tre obiettivi**: tanti anelli quanti sono gli obiettivi;
- **esperienza non ancora fatta in questo giro**: la scheda c'è (come nel pannello Novità) e il palco dice «Arriva con un
  prossimo aggiornamento»;
- **tavolo chiuso o iPad non collegato**: «Mostra sul tavolo» apre il pannello del tavolo (o lo dice);
- **dati di prova**: con i clienti fittizi caricati le esperienze mostrano l'etichetta «dati di prova» come altrove.

#### 1.3.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `690-sala-griglia` / `-scuro` | Sala sul primo cliente di prova: scheda grande con «Ciao Giulia.» e tre anelli pieni, dieci schede |
| `691-sala-palco` / `-scuro` | il palco di un'esperienza (la prima fatta; per la cornice basta lo stato «in arrivo»): testata con «‹ Sala», tassello, nome, cliente, «Mostra sul tavolo» e «Aggiungi al Prisma di …» |
| `692-sala-senza-cliente` | archivio vuoto: stato «Scegli un cliente per iniziare» |
| `693-sala-modo-cliente` | modalità cliente accesa: la pillola mostra solo il cliente presente |
| `694-sala-presenta` / `-scuro` | l'esperienza sulla sala opaca (se la presentazione è accettata); in scuro identica, la sala è sempre scura |
| `470-tavolo-sala` (esistente) | da affiancare con `695-sala-tavolo` se «Mostra sul tavolo» manda un'immagine del palco |

#### 1.3.8 Regole di CLAUDE.md toccate e decisioni

Regole: tema Apple (schede inclinate, cascata, dettaglio che nasce dalla scheda); «Riduci movimento» e istantanee;
«Sotto la sala opaca della presentazione l'acqua si ferma»; modalità cliente; dati in locale (il tavolo usa la rete
locale cifrata già approvata, `ProtocolloTavolo.swift`); canale sempre riconoscibile (dentro le esperienze, quando
mostrano prodotti, sezioni proprie).

**Decisioni per l'utente:**
1. **Presentare un'esperienza al cliente**: (a) pulsante «▶︎ Presenta» con la sala opaca e la modalità cliente
   (proposta); (b) solo la Sala in finestra con la modalità cliente; (c) solo il tavolo con l'iPad.
2. **Pillole dei clienti davanti al cliente**: nel template la testata mostra i nomi di altri cinque clienti anche mentre
   lo schermo è girato verso Giulia. Proposta: in modalità cliente (e nella presentazione) solo il cliente presente;
   fuori dalla modalità cliente le pillole come in Analisi 360.
3. **«Mostra sul tavolo»** manda all'iPad un'immagine del palco (proposta minima, nessun cambio di protocollo) o
   l'esperienza viva (protocollo nuovo, più lavoro, più dati sull'iPad).
4. **Il palco nasce dalla scheda** (`matchedGeometryEffect`) invece della dissolvenza del template. Proposta: sì.
5. **Esc dal palco** torna alla griglia invece di chiudere la finestra. Proposta: sì.
6. **«Aggiungi al Prisma di …»** prepara un contenuto che **esce dal Mac** nel file dato al cliente (sezione «Il Prisma del
   cliente»): la cornice non manda nulla da sola; l'invio resta un gesto del consulente.

---

### 1.4 I componenti riusati da più novità

Pezzi del template che servono a più sezioni. Le sezioni delle novità li citano con questi nomi.

#### 1.4.1 Cosa si vede

**4.1 Tassello con glifo** (`glifo`, riga 1206; `ic`, riga 1793; `GL`, righe 1201-1205 e 1787-1792; `.espI`, 227).
Un quadrato arrotondato a tinta piena con un glifo bianco a tratto (SVG 24×24, tratto 2, capi e giunti tondi). Misure
usate: 30 (pannello Novità, raggio 9), 32 (testata del palco, raggio 10; Biblioteca, raggio 0,3·32), 36 (predefinito di
`ic`, raggio 11), 44 e 60 (Sala, raggio 14). Glifo a metà del lato (15, 17, 18, 22, 30). `glifoC` (riga 2074) è lo stesso
glifo con il tratto `currentColor`, nei pulsanti delle testate («Nuovo cliente», «Nota dall’iPhone»). I 29 glifi:

| Chiave | SVG (viewBox 0 0 24 24, tratto bianco 2 salvo dove c'è `fill`) |
|---|---|
| prisma | `<rect x="7" y="2.5" width="10" height="19" rx="2.5"/><path d="M10.5 18.5h3"/>` |
| luce | `<path d="M11 4.5l6.5 12.5H4.5z"/><path d="M1 13.5h4.5M17.5 10.5l5-2.5M17.5 13l5.5 0M17.5 15.5l5 2.5"/>` |
| lettera | `<rect x="3" y="5.5" width="18" height="13" rx="2"/><path d="M3.5 7l8.5 6 8.5-6"/>` |
| film | `<rect x="2.5" y="5" width="19" height="14" rx="3"/><path d="M10 9.2v5.6l4.8-2.8z" fill="#fff"/>` |
| disegna | `<path d="M3 17c3-1 4-6 7-6s2 5 5 5 3-6 6-8"/><path d="M17.5 3.5l3 3"/>` |
| rischio | `<path d="M3 6l5 5 4-3 5 7 4-2"/><path d="M17 15h4v-4"/>` |
| giornata | `<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.2 5.2l1.8 1.8M17 17l1.8 1.8M5.2 18.8L7 17M17 7l1.8-1.8"/>` |
| dadi | `<rect x="4" y="4" width="16" height="16" rx="3.5"/>` + quattro `<circle r="1.3" fill="#fff"/>` in (9,9), (15,15), (15,9), (9,15) |
| valore | `<path d="M12 3l2.6 5.6 6 .7-4.5 4.1 1.2 6L12 16.4 6.7 19.4l1.2-6L3.4 9.3l6-.7z"/>` |
| capsula | `<path d="M7 3h10M7 21h10M8 3v3l4 6-4 6v3M16 3v3l-4 6 4 6v3"/>` |
| ar | `<path d="M12 3l8 4.5v9L12 21l-8-4.5v-9z"/><path d="M12 12l8-4.5M12 12v9M12 12L4 7.5"/>` |
| mappa | `<path d="M3 6.5l6-2.5 6 2.5 6-2.5v13.5l-6 2.5-6-2.5-6 2.5z"/><path d="M9 4v13.5M15 6.5V20"/>` |
| storia | `<rect x="5" y="2.5" width="14" height="19" rx="3"/><path d="M8 6h8"/>` |
| palestra | `<path d="M4 6h10a3 3 0 0 1 3 3v2H9l-5 4z"/><path d="M20 11v4l-3-2h-5"/>` |
| festa | `<path d="M4 20l5-14 9 9z"/><path d="M14 4l1 2M19 5l-2 2M20 10l-2-.5"/>` |
| notte | `<path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z"/>` |
| proposta | tre `<rect width="8" height="8" rx="2"/>` in (3,3), (13,3), (3,13) e `<path d="M17 13v8M13 17h8"/>` |
| modulo | `<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M8.5 8h7M8.5 12h7M8.5 16h4"/>` |
| cartella | `<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M8.5 13l2.5 2.5 4.5-5"/>` |
| sinistro | `<path d="M3 18l5-5 4 3 6-7 3 3"/><circle cx="8" cy="13" r="1.6"/><circle cx="18" cy="9" r="1.6"/>` |
| libro | `<path d="M5 4.5A1.5 1.5 0 0 1 6.5 3H19v15H6.5A1.5 1.5 0 0 0 5 19.5z"/><path d="M5 19.5A1.5 1.5 0 0 0 6.5 21H19"/>` |
| lente | `<circle cx="10.5" cy="10.5" r="6.5"/><path d="M15.5 15.5L21 21"/>` |
| radar | `<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="4.5"/><path d="M12 12l6-6"/>` |
| campagna | `<path d="M3 10v4h3l7 4V6L6 10z"/><path d="M17 9a4 4 0 0 1 0 6"/>` |
| scan | `<path d="M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3"/><rect x="7.5" y="8.5" width="9" height="7" rx="1.2"/>` |
| albero | quattro `<circle r="2"/>` in (12,5), (6,19), (18,19), (12,19) e `<path d="M12 7v5M6 17v-3h12v3M12 12v5"/>` |
| azienda | `<path d="M4 21V9l6-3v3l6-3v15z"/><path d="M8 13h1M12 13h1M8 17h1M12 17h1M16 21V10h4v11"/>` |
| voce | `<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21"/>` |
| auto | `<path d="M4 16v-4l2-5h12l2 5v4z"/><circle cx="8" cy="16.5" r="1.8"/><circle cx="16" cy="16.5" r="1.8"/>` |

**4.2 Il telefono disegnato e il velo della scena** (`.phone`, righe 204-206; `#scan`, 207 e 1101-1112). Un iPhone
300×620 (raggio 50, corpo #0d0f12, filo #2a2e34, tacca 92×26 a 22 dall'alto, schermo rientrato di 11 con raggio 40),
usato in quattro novità: **Il Prisma del cliente** (riga 1228, dentro il palco, scala 0,92), **Il sinistro come una
spedizione** (riga 1872, il telefono del cliente, scala 0,82), **Nuovo cliente in 10 secondi** (riga 2000) e **La nota
vocale** (riga 2040). Le ultime due lo mostrano **dentro il velo `#scan`** (tutto palco, rgba(6,14,20,.55) con
sfocatura 8, z 97), lo stesso di «Inquadra e capisci» di Orizzonte: il telefono entra da y +60 ruotato di −4° in 0,7 s
`(.34,1.3,.64,1)`, il velo in 0,3 s, e si chiude in 0,22 s.

**4.3 La tela animata** (`anima`, riga 1183; `tela`, 1184). Un ciclo a ogni fotogramma che disegna su una tela finché
l'elemento è nella pagina, con la risoluzione al più ×2. Usata da 6 punti (righe 1294, 1539, 1641, 1774, 2045 e il territorio): il film, il prisma di luce e la realtà aumentata
(che ci fanno girare lo shader), i coriandoli dei traguardi, l'onda della nota vocale e l'automobile che percorre il giro
di domani nel Territorio (su SVG, non su tela). Disegna il tuo futuro usa una tela (`tela`, riga 1303) con un suo ciclo
`requestAnimationFrame` per la trasformazione (riga 1318); la lettera dal futuro **non** usa `anima`: scrive a parole
con un `setInterval` (riga 1269).

**4.4 Lo shader a schermo intero** (`glTela`, righe 1423-1435; `NOGL`, 1436). Una tela WebGL con un solo fragment shader
(`FS_LUCE` per il prisma di luce, `FS_AR` per la realtà aumentata), uniform per tempo e parametri, e un messaggio di
ripiego «Questa vista ha bisogno della grafica accelerata (WebGL).». Il commento di testa (riga 16) dice che sono «la
specifica della resa, da portare in Metal (prisma) e RealityKit (AR)».

**4.5 Le sovrapposizioni a tutto palco** (stato dei pannelli): `#storia` (righe 240-256, 1701-1727; z 98, «La tua
settimana», «Il tuo anno»), `#notte` (riga 287, 1805-1811; z 95, «Stanotte Prisma ha lavorato»), `#scan` (§4.2, z 97),
`#show` (sala dei Prospetti, z 96). Il contenuto sta nelle sezioni; qui l'ordine e le regole comuni (§4.4).

**4.6 Il testo che si scrive** (`scrive`, riga 1794, con `setInterval`): una lettera ogni `ms` (28 se non è dato), con
`ridotto` subito tutto. Nessuno usa il valore predefinito: Compila da solo **16** ms per i campi e **20** per l'IBAN
(righe 1897 e 1902), Trova la pagina **18** ms (risposta, riga 1930), La nota vocale **45** ms (riga 2046). La lettera
dal futuro scrive **a parole** con un suo `setInterval` (`scriviLet`, riga 1269).

**4.7 Funzioni d'appoggio della shell**: `rimonta(html, dopo)` (riga 845) e `vaiA(app, prep)` (riga 846), come in
Orizzonte; `toast` (riga 401, z 95, 2,4 s); la **sfera di Ruby** viva (`.sfera.viva`) nelle risposte di Pratiche,
Biblioteca, Nuovo cliente e Nota vocale.

**4.8 Il calcolo condiviso della pensione** (`fattore`, riga 435; `pensCon`, `versPens`, righe 1185-1186):
`fattore(n) = 12·((1,03ⁿ − 1)/0,03)/300` (rendita mensile per ogni euro versato al mese per n anni al 3%),
`pensCon(c) = arrotonda10(pensione + max(0,95·divario, versamento·fattore(anni)))`,
`versPens(c) = max(50, arrotonda10(divario / fattore(anni)))`. Lo usano La lettera dal futuro (righe 1258, 1262), Il film
del piano (1283), Una giornata della pensione (1361) e Lancia l’anno (1379).

#### 1.4.2 Misure e stile

| Componente | Valori | Token in Prisma |
|---|---|---|
| Tassello | lato L ∈ {30, 32, 36, 44, 60}; raggio 0,3·L (pannello, `ic`) o 14 fisso (Sala) o 10 (palco); ombre `inset 0 1 0 rgba(255,255,255,.35)` e `0 6 14 −6 rgba(0,0,0,.35)`; glifo L/2, tratto 2/24 del glifo | **nuovo** `Tema.Apple.Tassello`: `quotaRaggio = 0.3`, `filoLuce = Color.white.opacity(0.35)`, `ombra = Color.black.opacity(0.35)` raggio 14 y 6 rientro 6, `quotaGlifo = 0.5`, `trattoGlifo = 2/24` |
| Tinte dei glifi | prisma #0A84FF, mappa #2A6FA0, lettera #C45A75, film #E08A00, disegna #30B15C, storia #1F5F99, palestra #3F5A78, luce #5B4BC8, capsula #9B6FB5, festa #E5484D, rischio #E5484D, giornata #2A9BC8, dadi #B06E12, valore #2563EB, ar #1E9E6A, notte #1F3A5F, proposta #3E7D69, modulo #30B15C, cartella #0A84FF, sinistro #E08A00, libro #8A5A35, lente #E5484D, radar #1E9E6A, campagna #C45A75, scan #5B4BC8, albero #2F7A4A, azienda #3F5A78, voce #E5484D, auto #5A6873 | **nuovo** `Tema.Apple.Colore.Glifi` (una costante per chiave; dove la tinta c'è già si riusa: #0A84FF = `anello2`, #E5484D = `rosso`, #E08A00 = `arancio`, #30B15C = `anello1`, #2563EB è la tinta chiara di `canaleAlleanza` ma va fissa (in scuro `canaleAlleanza` diventa #6B95FF): esiste già fissa come `Colore.Composizione.gestioneSeparata`, ma per significato meglio una costante propria, #C45A75 = `Colore.Impegno.giulia`) |
| Telefono | 300×620, raggio 50, corpo #0D0F12, filo #2A2E34 da 2, tacca 92×26 r 20 a 22, schermo rientrato 11 r 40, ombra 0 40 80 −20 nera al 55% | `Tema.Apple.Inquadra.Apparecchio` (esiste, valori identici): da spostare in **`Tema.Apple.Apparecchio`** comune |
| Velo della scena | rgba(6,14,20,.55), sfocatura 8 | `Tema.Apple.Inquadra.Velo` (esiste) → **`Tema.Apple.VeloScena`** comune |
| Toast | rgba(15,36,51,.92), 13, padding 9×16, a 44 dall'alto | `Tema.Apple.Colore.toast`, `avvisoToast` (esistono) |

#### 1.4.3 Movimento

| Componente | Movimento | Token |
|---|---|---|
| Tassello | al passaggio, nella Sala, scala 1,06 in 0,4 s `molla` | **nuovo** `Tema.Apple.Moto.Tassello.passaggio` |
| Telefono nella scena | velo 0,3 s; telefono da y +60, −4°, opacità 0 in 0,7 s `(.34,1.3,.64,1)`; chiusura 0,22 s | come «Inquadra e capisci» (`Tema.Apple+Inquadra.swift`, curva `(.34,1.3,.64,1)` già prevista nella specifica di Orizzonte §2.5) |
| Tela animata | un fotogramma per volta, finché la vista c'è | **niente Timer**: `TimelineView(.animation(paused:))` con `Canvas`; `paused` vero con `\.prismaCalmo`, `\.modoIstantanea`, finestra non visibile, Mac a riposo, app non davanti (come l'acqua) |
| Shader | come la tela, ma in Metal | `MTKView` con disegno a richiesta (o, come l'acqua, un `CAMetalLayer` con `CVDisplayLink` sul Mac e `CADisplayLink` su iOS), fuori dal thread principale, ritmo 30/20 fps in risparmio energetico; con Riduci movimento e nelle istantanee un solo fotogramma, quello finale |
| Testo che si scrive | una lettera ogni 16-45 ms secondo il punto (§4.6) | `TestoProgressivo` (`DesignSystem/Apple/RubyApple.swift`) scrive **una parola** per passo (`Tema.Apple.Moto.Testo.parola`): proposta di riusarlo così (più leggibile) o di aggiungere un passo per lettera `Tema.Apple.Moto.Testo.lettera` (0,016 / 0,018 / 0,045 secondo l'uso, o un valore unico da decidere) |
| Rimonta | 0,13 s a scala 0,99, poi cascata | `Tema.Apple.Studio.Moto.durataRimonta`/`scalaRimonta` (esistono) |

**Riduci movimento**: tele e shader disegnano **un solo fotogramma**, quello finale (il template in molti punti usa
`ridotto ? 99 : t` per saltare alla fine: è la regola giusta); testi già scritti; telefono e velo con la dissolvenza di
0,15 s. **Istantanee**: stato finale, nessun ciclo avviato.

#### 1.4.4 Interazioni

**Ordine di Esc** (righe 1784, 2089, 2105): storia aperta → la chiude (e ← → sfogliano); carte della notte → le chiude
(← → decidono); scena del telefono (`#scan`: scanner, nuovo cliente, nota vocale) → la chiude; pannello Novità → lo chiude;
sala della presentazione → la chiude; dettaglio → lo chiude; notifiche → le chiude; finestra → la chiude. In Prisma, con la
Sala: … dettaglio → **palco della Sala → griglia** → notifiche → finestra.

**Blocco** (riga 2100): `blocca()` chiude dettaglio e sala dei Prospetti, ma **non** la storia (z 98) né le carte della
notte (z 95), che restano sopra la schermata di benvenuto (z 90). In Prisma il blocco (anche quando il Mac va a riposo,
CLAUDE.md) **chiude tutte le sovrapposizioni**: storia, notte, scena del telefono, presentazione dell'esperienza.

**Un pannello alla volta**: aprire la storia o la notte chiude Novità e notifiche (`apriStoria`, `apriNotte`); in Prisma
anche spazi, ricerca, guida, come `apriNovita()`.

#### 1.4.5 Mappa verso Prisma

| Componente | Esiste | Da fare |
|---|---|---|
| Tassello con glifo | `DesignSystem/LogoPrisma.swift` mostra come disegnare in vettoriale con `Shape` | **nuovo** `DesignSystem/Apple/GlifiLuce.swift`: `enum GlifoLuce: String, CaseIterable` con le 29 chiavi e per ognuna i tracciati come `Path` (convertiti a mano dagli SVG della tabella, o con un piccolo lettore di `d` SVG per `M L H V C S A Z` e `rect`/`circle`), disegnati con `StrokeStyle(lineWidth:, lineCap: .round, lineJoin: .round)` e i pezzi `fill`; **`TasselloGlifo(glifo:, lato:, raggio:)`**; colori in `Tema.Apple.Colore.Glifi`. Niente SF Symbols: non hanno lo stesso aspetto (CLAUDE.md: mantenere l'aspetto originale) |
| Telefono e velo | `Shell/ScenaInquadra.swift` (`StratoInquadra`, `ScenaInquadra`, il telefono con la tacca), `Shell/StatoInquadra.swift`, `Tema.Apple+Inquadra.swift` (`Apparecchio`, `Velo`) | estrarre **`TelefonoDisegnato`** (corpo, tacca, schermo con contenuto) e **`StratoScena`** (velo, entrata, Esc, ✕) in `DesignSystem/Apple/ScenaTelefono.swift`; Inquadra, Nuovo cliente e Nota vocale diventano tre contenuti dello stesso strato (`enum ScenaTelefono { inquadra, cartaIdentita, notaVocale }`, uno alla volta) |
| Tela animata | l'acqua (`DesignSystem/SfondoAcqua.swift`) ha già le regole di pausa; `TimelineView` è da macOS 12 | **nuovo** `DesignSystem/Apple/TelaAnimata.swift`: `TelaAnimata { contesto, tempo in }` = `TimelineView(.animation(paused:))` + `Canvas`, con la pausa centralizzata (calmo, istantanea, finestra nascosta, riposo, app non davanti) e lo stato finale |
| Shader | `SfondoAcqua` in Metal: `TelaAcqua` (NSView con `CAMetalLayer`, `CVDisplayLink`, coda propria, `DesignSystem/SfondoAcqua.swift`), `iOS/SfondoAcquaMobile.swift` (`CAMetalLayer` e `CADisplayLink`); lo shader è **testo Swift compilato all'avvio** con `device.makeLibrary(source: ShaderAcqua.sorgente, …)` (`DesignSystem/SfondoAcquaShader.swift`, `SfondoAcqua.swift` riga 297): niente file `.metal` né `.metallib`, che senza Xcode non si compilano | **nuovo** `DesignSystem/Apple/TelaShader.swift`: una `MTKView` (MetalKit, framework di sistema, macOS 13 e iOS) o lo stesso `CAMetalLayer` dell'acqua, con un fragment shader a schermo intero, uniform tempo e parametri; le sorgenti `ShaderLuce.sorgente` e `ShaderRealtaAumentata.sorgente` (nomi proposti) come stringhe Swift compilate con `makeLibrary(source:)`, come l'acqua; ripiego statico se Metal manca. **Non** `colorEffect`/`layerEffect` di SwiftUI (macOS 14+) |
| Testo che si scrive | `TestoProgressivo` | riusarlo; se serve il passo per lettera, un parametro `unita: .parola / .lettera` |
| Sovrapposizioni | `StatoFinestre` (`pannelloNotifiche`, `pannelloSpazi`, `pannelloRicerca`, `guida`, `pannelloNovita`), `Shell/ShellView.swift` | un solo `enum SovrapposizioneLuce { storia(TipoStoria), notte, scena(ScenaTelefono), presentazioneEsperienza(EsperienzaSala) }` in `StatoFinestre` (una alla volta), chiuso da `blocca()` e dal riposo del Mac (`Shell/RipresaSistema.swift`) |
| Rimonta e vaiA | `StatoShell.apri(_:)` (`Shell/StatoShellFinestre.swift` riga 90), `preparaOspite`, rimonta di Studio | nessuno: le sezioni usano questi |
| Calcolo della pensione | `Motori/MotorePrevidenza.swift` (`MotorePrevidenza.calcola`), `Motori/MotorePensionePubblica.swift`, `Motori/MotoreObiettivo.swift` (`nettoDiUnEuroAlMese`) | **non** riscrivere `fattore` col 3% fisso: le quattro esperienze chiedono a `MotorePrevidenza` la pensione con e senza piano e il versamento che chiude il divario, con le ipotesi del cliente (rendimento e anni dalle sue ipotesi). Un adattatore comune `Motori/PensioneEsperienze.swift` (nome proposto): `pensioneConPiano(cliente)`, `versamentoPerDivario(cliente)`, con la prova in `ProvaCalcoli` (stessi numeri per lettera, film, giornata e dadi) |

#### 1.4.6 Dati che l'utente deve dare e stati vuoti

- Tassello, telefono, tela, shader: nessun dato.
- Calcolo della pensione: servono **pensione pubblica stimata**, **pensione desiderata**, **anni alla pensione** e le
  **ipotesi di rendimento** del cliente (oggi in Analisi 360 › Previdenza). Se mancano, le esperienze che lo usano
  mostrano «Per questa esperienza servono la pensione stimata e quella desiderata di Giulia» con il collegamento ad Analisi
  360, mai cifre di ripiego. Il 3% del template è dimostrativo.
  **Attenzione, verificato nel codice**: le ipotesi stanno in `Analisi360.previdenza` (`IpotesiPrevidenza`,
  `Dati/Analisi.swift` righe 121-132: `eta`, `etaPensione`, `redditoDesiderato`, `pensionePubblica`, `capitale`,
  `versamentoMensile`, `rendimentoReale`, `anniIntegrazione`) e **hanno valori predefiniti** (pensione pubblica 1.400,
  reddito desiderato 2.200, età 40, pensione a 67, rendimento reale 1,5%). Un cliente mai analizzato ha quindi delle
  cifre che nessuno ha dato: «manca» non si può riconoscere da un valore vuoto. Proposta: le esperienze usano le ipotesi
  solo se l'area è confermata con il cliente (`Analisi360.confermate.contains(.previdenza)`), altrimenti mostrano lo
  stato «ipotesi da confermare in Analisi 360 › Previdenza» invece delle cifre (decisione 5).
  Il template stesso firma i racconti con «Lettera immaginata a partire dalle stime di Prisma (pensione pubblica,
  obiettivi, fondo pensione). Non è una previsione né una promessa.» (riga 1268): una nota del genere va su ogni
  esperienza che proietta la pensione, e il suo testo è dell'utente (decisione 5).
- Shader senza Metal (mai sui Mac supportati, ma possibile nel simulatore): immagine ferma e la frase del template
  adattata («Questa vista ha bisogno della grafica accelerata»).

#### 1.4.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `400-vetrina-apple` / `-scuro` (esistente) | aggiungere: tasselli 30/44/60 con quattro glifi, il telefono disegnato vuoto, una `TelaAnimata` e una `TelaShader` di prova ferme sullo stato finale |
| `619-glifi-luce` | tavola dei 29 glifi nei loro tasselli (per confrontarli con il template a colpo d'occhio) |
| `609-inquadra-iphone`, `600-609` (esistenti) | da rifare dopo l'estrazione di `TelefonoDisegnato` e `StratoScena`: devono restare identiche |

Lo script che ho usato per le schermate (da tenere fuori dal repository):

```js
// NODE_PATH=$(npm root -g) node shot01.js
const { chromium } = require('playwright');
const URL = 'file:///home/user/Prisma/Design/template-luce.html';
(async () => {
  const b = await chromium.launch();
  for (const scuro of [false, true]) {
    const p = await b.newPage({ viewport: { width: 1480, height: 940 }, deviceScaleFactor: 1 });
    await p.goto(URL + '#impostazioni'); await p.waitForTimeout(1500);           // l'hash apre l'app senza blocco
    if (scuro) { await p.click('#impC .seg[data-k="tema"] span[data-v="scuro"]'); await p.waitForTimeout(400); }
    await p.click('#wClose'); await p.waitForTimeout(1200);                       // scrivania
    await p.click('#bNov'); await p.waitForTimeout(1600);                         // pannello Novità
    // voci: '#novP .novI[data-s="c"|"l"][data-i=N]'; app: '#dock [data-app="sala"]'; schede: '.espC[data-e="lettera"]'
    await p.close();
  }
  await b.close();
})();
```

#### 1.4.8 Regole di CLAUDE.md toccate e decisioni

Regole: «Niente Timer: animazioni di SwiftUI e `Animatable`» (tele con `TimelineView`, shader con `MTKView`); «disegno
fuori dal thread principale» (shader come l'acqua); MacBook M1 8 GB (una sola tela o shader vivo per volta, liberati
uscendo dal palco); target macOS 13 (niente `colorEffect`/`layerEffect`/`visualEffect` di macOS 14, niente
`onKeyPress` di macOS 14 senza protezione); blocco e riposo del Mac; icone e glifi in vettoriale con l'aspetto originale;
nessuna dipendenza esterna (lettore SVG scritto in casa o tracciati convertiti a mano).

**Decisioni per l'utente:**
1. **Glifi**: tracciati vettoriali fedeli (proposta) oppure SF Symbols simili (più rapido, aspetto diverso).
2. **Testo che si scrive**: una parola per volta come Ruby (proposta, già in Prisma) o una lettera per volta come il
   template.
3. **Calcolo della pensione delle esperienze**: dai motori di Prisma con le ipotesi del cliente (proposta), non con il 3%
   fisso del template.
4. **Blocco**: chiude storia e carte della notte (proposta), al contrario del template.
5. **Ipotesi di previdenza non confermate e nota sotto le proiezioni**: le esperienze usano solo le ipotesi confermate con
   il cliente (proposta) o anche quelle predefinite con l'etichetta «ipotesi»; il testo della nota («non è una previsione
   né una promessa») lo scrive o lo approva l'utente: è una dichiarazione verso il cliente, non va inventata.
6. **La scena del telefono è solo un disegno sul Mac**: per Nuovo cliente e Nota vocale la cattura vera avviene
   sull'iPhone, con la **fotocamera** (carta d'identità: dati personali e documento d'identità) e il **microfono** (nota
   vocale), e arriva al Mac dal ponte cifrato in rete locale già approvato per Ruby e per Inquadra
   (`Ruby/PonteRuby.swift`, `Ruby/ServerPonteRuby.swift`, `iOS/InquadraTelefono.swift`; oggi la foto di Inquadra vive solo in memoria,
   `Shell/StatoInquadra.swift`). Servono i permessi di fotocamera e microfono dell'iPhone e la regola: nessuna immagine
   del documento si salva, nessun audio esce dalla rete locale, la trascrizione la fa il dispositivo o Qwen sul Mac. Le
   sezioni delle due novità decidono i dettagli; qui la proposta comune: stesso ponte, niente servizi esterni.
7. **Realtà aumentata**: il commento del template (riga 16) chiede **RealityKit** per l'AR (con ARKit e la fotocamera
   dell'iPhone/iPad): framework di sistema, non dipendenze esterne, ma con la fotocamera e solo su iOS (ARKit non c'è sul
   Mac; RealityKit sì, da macOS 10.15, senza tracciamento del tavolo). Da decidere nella sezione della realtà aumentata;
   qui solo il vincolo: `TelaShader` serve al prisma di luce, l'AR vero non passa da lì.
8. **Shader**: `MTKView` (MetalKit) oppure lo stesso `CAMetalLayer` dell'acqua. In tutti e due i casi sorgente compilata
   a runtime con `makeLibrary(source:)` (niente Xcode). Proposta: lo schema dell'acqua, già provato sul Mac dell'utente.

---

## 2. Sala: il Prisma del cliente, il prisma di luce, la realtà aumentata

Fonte: `Design/template-luce.html` (5 novembre 2026). Le righe citate sono di quel file. Per tutto ciò che qui non è detto
vale `Design/template-novita-specifica.md` («Orizzonte») e, sotto, `Design/template-apple-specifica.md` (token, finestra,
segmentato, card, tile, interruttori, cascata, numeri che si contano).

Righe del template usate in questa parte:

| Cosa | Righe |
|---|---|
| CSS: `.phone` e `.phone .scr` (cornice del telefono) | 204-206 |
| CSS: `.espI`, `.miniC`, `.ondaM` e `@keyframes ondaM` | 227-231 |
| CSS: `.segScuro`, `.lLab`, `.lN`, `.lV` (prisma di luce) | 259-264 |
| CSS: `.ipad`, `.ipadS`, `.arTop`, `.arPill`, `.arCoach`, `.arCq` e `@keyframes arCq`, `.arBar`, `.arTog`, `.arShut`, `.arTag`, `.arStr` (realtà aumentata) | 265-280 |
| `ridotto` (Riduci movimento), `conta` (numeri che si contano), `anello` | 377, 381, 392 |
| Dati di prova: `VITA`, `proiezione` (la linea della vita del template) | 1115-1121 |
| Sala: `ESP` (le 11 esperienze), `APPS.sala`, `salaHTML`, `palcoHTML`, `montaSala`, `apriEsp` | 1189-1225 |
| 1 · Il Prisma del cliente: `ESPH.prisma`, `miniLinea`, `ESPM.prisma` | 1227-1253 |
| Motore WebGL comune: `glTela`, `rgb`, `lerp`/`clamp01`/`eio`, `NOGL` | 1423-1436 |
| 8 · Il prisma di luce: `FS_LUCE`, `luceDati`, `ESPH.luce`, `ESPM.luce` | 1438-1550 |
| 15 · La realtà aumentata: `FS_AR`, `ESPH.ar`, `ESPM.ar` | 1552-1650 |
| Pannello Novità: `NOV15` voci 0 (prisma), 7 (luce), 14 (ar) | 1778-1781 |

Schermate di lavoro (non nel repository, si rigenerano dal template con Playwright: il file è un'unica funzione
anonima, per pilotarlo bisogna farne una copia che esponga `window.__api={apriEsp,tema,SEGH}` prima della `})();` finale
e bloccare il foglio di Google Fonts, che altrimenti ferma lo script): `luce/img/sala-prisma-chiaro.png`,
`sala-prisma-scuro.png`, `sala-prisma-file.png`, `sala-luce-chiaro.png`, `sala-luce-scuro.png`, `sala-luce-hover.png`,
`sala-luce-canale.png`, `sala-ar-chiaro.png`, `sala-ar-scuro.png`, `sala-ar-esploso.png` (1480×940, palco 1440×900).

**Le cifre e i nomi del template sono dimostrativi.** Nell'app arrivano dai motori di Prisma (§N.5) e, dove manca un dato,
Prisma lo dice (§N.6): mai un numero inventato.

### 2.0 Parte comune alle tre esperienze: la Sala e il palco

La Sala (app nuova, specificata nella sua parte) mostra le 11 esperienze in una griglia (`salaHTML`, 1212-1216); il
cliente si sceglie nel segmentato con gli avatar in alto a destra (`APPS.sala.act`, 1209). Toccando una card l'esperienza
si apre nel **palco** (`palcoHTML`, 1217-1220):

- riga alta 40: pulsante «‹ Sala» (torna alla griglia), icona dell'esperienza 32×32 raggio 10 nel suo colore, titolo `.h2`
  (21 pt, 700, −0,4), «· Giulia Rossi» (14 pt, `--ink2`);
- a destra, secondo l'esperienza: «▣ Mostra sul tavolo» (tutte tranne `prisma`, `valore`, `capsula`) e «✦ Aggiungi al
  Prisma di Giulia» (solo `lettera`, `film`, `luce`, `giornata`, `disegna`);
- sotto, a 52 dall'alto, il palco: una `.card` assoluta fino in fondo, `overflow:hidden`, dentro cui si monta l'esperienza.
  Entra con opacità 0→1 e scala 0,98→1 in 520 ms, curva (.22,1,.36,1) (`montaSala`, 1224), cioè `Moto.Curva.uscita`.
- La card della griglia toccata fa un breve «lancio» (scala 1,05 e opacità 0,4 in 180 ms, ease-in) e dopo 120 ms si
  monta il palco (1222).

Colori delle tre esperienze (icone `.espI` e voci del pannello Novità, `ESP` 1189-1207 e `NOV15` 1778-1780):

| Esperienza | `k` | Colore | Glifo (`GL`, 1201-1205) | Voce Novità |
|---|---|---|---|---|
| Il Prisma del cliente | `prisma` | #0A84FF | telefono (rettangolo 10×19 r 2,5 e trattino) | «La sua app personale, in un file» → `apriEsp('prisma',0)` |
| Il prisma di luce | `luce` | #5B4BC8 | triangolo con un raggio a sinistra e tre a destra | «Il patrimonio in raggi di luce» → `apriEsp('luce',0)` |
| La realtà aumentata | `ar` | #1E9E6A | cubo isometrico | «Il patrimonio sul tavolo» → `apriEsp('ar',0)` |

Le tre icone seguono la parte comune (`01-comune.md` §4.1 e §5): glifi vettoriali `GlifoLuce.prisma`, `.luce`, `.ar`
(`DesignSystem/Apple/GlifiLuce.swift`, da creare) dentro `TasselloGlifo`, tinte in `Tema.Apple.Colore.Glifi`; **niente SF
Symbols** (non hanno l'aspetto del template). **Non** `Tema.Apple.Sala`: quel nome esiste già ed è la sala della
presentazione dei Prospetti (`Tema.Apple+Prospetti.swift:147`, `TemaAppleMoto.swift:465`); i token della Sala nuova sono
`Tema.Apple.SalaEsperienze`. Nell'app `apriEsp(k, sel)` diventa `StatoShell.apriEsperienza(.prismaCliente |
.prismaLuce | .realtaAumentata, cliente:)` (da creare, parte comune), che apre il caso nuovo `AppPrisma.sala`, come chiede
§0.5 di Orizzonte.

Nomi: le viste di questa parte si chiamano `PalcoPrismaCliente`, `PalcoLuce`, `PalcoRealtaAumentata` e **non**
`Esperienza…`, perché «Esperienza» in Prisma è già l'esperienza finanziaria del profilo MiFID (`Cliente.Esperienza` in
`Dati/Modelli.swift:303`, `EsperienzaCliente`, `EsperienzaProdotti`, `Tema.Apple…Esperienza` in
`DesignSystem/ComponentiEsperienza.swift`).

---

### 2.1 Il Prisma del cliente

*Novità 1 di 15 «davanti al cliente» · voce `NOV15[0]` · `ESPH.prisma` / `ESPM.prisma` (1227-1253)*

Il consulente prepara per il cliente **un file unico** che il cliente apre sul suo telefono con una password: dentro ci
sono i suoi obiettivi, la linea della vita da esplorare, la lettera dal futuro e il film del piano (e, se il consulente lo
sceglie, le posizioni nel dettaglio). Nessun server: il file lo crea il Mac, lo manda il consulente, e resta del cliente.

**Che cosa è, in concreto (proposta da confermare, vedi §1.8):** un file `Il-Prisma-di-<Nome>.html` autonomo: un
involucro HTML con un piccolo programma JavaScript scritto da Prisma (niente librerie) e, dentro, **un solo blocco di dati
cifrato** (AES-256-GCM, chiave PBKDF2-HMAC-SHA256 dalla password, gli stessi algoritmi di `CifraturaBackup`). In chiaro nel
file ci sono solo: il titolo generico «Il Prisma», il logo, il campo della password e i parametri della cifratura (sale,
iterazioni, nonce). Il nome del cliente, le cifre, la lettera e il film stanno solo nel blocco cifrato. Il telefono del
cliente decifra con la password usando la crittografia del browser (WebCrypto) e disegna la mini-app. Il file arriva al
cliente **solo** perché il consulente lo spedisce lui (Messaggi, Mail, AirDrop, a mano); la password va data **a voce o
di persona**, mai nello stesso messaggio.

#### 2.1.1 Cosa si vede

**Nella griglia della Sala** (`salaHTML`, 1213-1215) il Prisma del cliente è la card grande della prima colonna (due righe,
padding 24): icona 60×60, «Ciao Giulia.» (38 pt), «Il tuo piano, sempre con te.» (14 pt), tre anelli da 70 (spessore 8)
con il nome dell'obiettivo sotto (11 pt, larghezza massima 76), e in fondo «Il Prisma del cliente» (26 pt) con «La sua app
personale, in un file da mandargli» (14 pt). La card della griglia è della parte della Sala; qui interessa che gli anelli
sono gli stessi della mini-app (§1.5).

**Nel palco** (schermata `sala-prisma-chiaro.png`), due zone.

*A sinistra: l'anteprima sul telefono* (1228-1237). Una cornice di iPhone (`.phone`, 204-206, con la tacca nera 92×26
raggio 20 a 22 dall'alto, `.phone:before` 205, che copre la testata della mini-app) scalata a 0,92 dall'angolo in
alto a sinistra, a x 44 e y −8 (il bordo alto del telefono esce un poco dal palco: è voluto, «il telefono è appoggiato»).
Lo schermo (`#mini`) scorre in verticale e ha colori **fissi e chiari** (fondo #F2F6F9, testo #14202B) anche quando Prisma è
scuro (`sala-prisma-scuro.png`): è l'aspetto della mini-app del cliente, non dell'interfaccia di Prisma. Dall'alto:

1. **Testata** alta 210, gradiente a 165° da #E3EFF5 a #9DC2D6. Tre onde d'acqua (`.ondaM`): cerchi da 60 con bordo 2 bianco
   a 0,8, centrati a (60, 80), (190, 60), (120, 140), che si allargano e svaniscono a turno. Logo di Prisma da 22 (i tre
   spicchi #0F2433 con opacità 1 / 0,66 / 0,38) a (20, 58). In basso a sinistra (20 dal bordo, 18 dal fondo):
   «IL PRISMA DI» (11 pt, 700, spaziatura 1, opacità 0,6) e sotto il **nome di battesimo** (34 pt display, 700, −0,8),
   che si scrive una lettera alla volta.
2. **Card «I TUOI OBIETTIVI»** (`.miniC`): occhiello 11 pt 700 #5A6873 spaziatura 0,5; tre anelli da 60 (spessore 7), ciascuno
   nel colore dell'obiettivo, con il nome sotto (10 pt, #5A6873, interlinea 1,2, larghezza 72). Il valore dell'anello è
   `pctObi` (439) = `cur / target`: **ciò che è già da parte oggi** rispetto al traguardo, non la copertura proiettata
   (vedi §1.5 e D13).
3. **Card «E SE VADO IN PENSIONE A…»**: l'età grande «67 anni» (24 pt display, grassetto), un cursore da 58 a 70, sotto un
   grafico 232×60 del patrimonio da oggi a 90 anni (area viola rgba(139,92,246,.15), linea #8B5CF6 spessa 2,2, filo
   tratteggiato [2 3] all'età della pensione) e una frase (11,5 pt): in verde #2F7A4A, peso 600, «I risparmi bastano oltre i
   90 anni», oppure in rosso #E5484D «I risparmi bastano fino a N anni».
4. **Card «Una lettera da te»**: quadrato 38 raggio 10 color #C45A75 con il glifo della busta, «Una lettera da te» (13 pt
   grassetto), «scritta a 67 anni» (11 pt #5A6873), freccia «›» #0A84FF a destra.
5. **Card scura «Il film del tuo piano»**: fondo #0F1C26, testo bianco; cerchio 38 bianco a 0,15 con «▶︎», «Il film del tuo
   piano» (13 pt grassetto), «un minuto» (11 pt, opacità 0,65).
6. **Piede** (10 pt, #7A8790, centrato, margini 14/6/24): «Denis Vicenzoni · il tuo consulente» e a capo «Stime basate su
   ipotesi, non garanzie di risultato.»

*A destra: la preparazione del file* (1241-1245), da x 400 al bordo destro meno 30, da 30 dall'alto a 24 dal fondo, in due
colonne con 26 di spazio:

- colonna larga:
  - titolo «La sua app personale, in un file.» (30 pt display, 700, −0,7);
  - testo (14,5 pt, interlinea 1,55, larghezza massima 540, `--ink2`): «Un file unico che Giulia apre sul telefono con la
    password. Dentro ci sono i suoi obiettivi, il futuro da esplorare, la lettera e il film. Nessun server: lo mandi tu, e
    resta suo.»;
  - `.lbl` «COSA C'È DENTRO» (22 sopra, 4 sotto);
  - cinque righe (padding 10/0, filo `--sep` sotto, 14,5 pt) con un interruttore `.sw` a destra: «Gli obiettivi con gli
    anelli» (acceso), «La linea della vita da esplorare» (acceso), «La lettera dal futuro» (acceso), «Il film del piano»
    (acceso), «Le posizioni nel dettaglio» (**spento**).
- colonna stretta, larga 290, elementi a 10 di distanza:
  - tile «Password» con «••••••••» (18 pt grassetto, spaziatura 2) e il pulsante «Mostra» (padding 4/10), che diventa
    «Nascondi» e mostra la password in chiaro («Lago-Vela-27» nel template);
  - tile «Si può aprire fino al» con «5 novembre 2027» (16 pt grassetto);
  - pulsante primario grande «Prepara il file» (`.btn.pri.big`, centrato);
  - pulsante grande «Manda con Messaggi»;
  - zona di stato `#pfS` (vuota all'inizio, §1.3);
  - in fondo (margine alto automatico), `.k` interlinea 1,45: «Il contenuto è quello dei prospetti approvati, con le stesse
    avvertenze. Il file è cifrato con la password.»

**Stati** (`sala-prisma-file.png`):

| Stato | Cosa si vede |
|---|---|
| Iniziale | Zona di stato vuota. |
| Preparazione | Tile «Preparo il file…» con una barra `.bar8` che si riempie (blu `--accent`). |
| File pronto | Tile con bordo verde rgba(47,163,90,.4): «✓ Il-Prisma-di-Giulia.html» (verde `--green`, grassetto) e sotto «1,4 MB · protetto con la password» (`.k`). |
| Mandato | Avviso (toast) «Aperto in Messaggi con il file allegato: lo spedisci tu». |
| Password mostrata | La password in chiaro e il pulsante «Nascondi». |

Stati che il template non ha e che servono nell'app (§1.6): cliente senza obiettivi, senza data di nascita (niente linea
della vita), senza lettera o film ancora preparati, senza recapito per Messaggi, e «file già dato» (con la data).

#### 2.1.2 Misure e stile

Corrispondenze con il tema (le misure senza nome nel tema vanno nel nuovo `Tema.Apple+PrismaCliente.swift`,
`Tema.Apple.PrismaCliente`):

| Elemento (template) | Valore | In Prisma |
|---|---|---|
| Titolo del palco `.h2` | display 21, 700, −0,4 | `Carattere.h2` |
| Titolo «La sua app personale, in un file.» | display 30, 700, −0,7 | **nuovo** `PrismaCliente.titolo` |
| Testo introduttivo | 14,5, interlinea 1,55, `--ink2`, max 540 | **nuovo** `PrismaCliente.introduzione`, `larghezzaTesto = 540` |
| `.lbl` | 12, 600, maiuscolo, .6 | `Carattere.etichetta` |
| Righe dei contenuti | 14,5, padding 10/0, filo `--sep` | `Carattere.corpo` è 14 (`TemaApple.swift:672`): **nuovo** `PrismaCliente.riga` a 14,5; filo `Colore.separatore` |
| Interruttore `.sw` | 44×26, acceso #34C759 | `StileInterruttoreApple`, `Colore.verdeInterruttore` |
| Tile | raggio 18, `--card`, bordo `--sep`, padding 14/16 | `Superficie.tile`, `Raggio.tile`, `Misura.Padding.tile` |
| Password nascosta | 18, grassetto, spaziatura 2 | **nuovo** `PrismaCliente.password` (tabellare, monospazio per le cifre) |
| Data di scadenza | 16, grassetto | `Carattere.titoloRiga` è 15 (`TemaApple.swift:669`): **nuovo** `PrismaCliente.scadenza` a 16 |
| Pulsanti grandi | `.btn.big`: padding 10/18, 13,5 | `StilePulsanteApple` grande (`Misura.Padding.pulsanteGrande`, `Carattere.pulsanteGrande`) |
| Barra di preparazione `.bar8` | alta 8, raggio 9, binario `--track` | `BarraPiena` (altezza 8) |
| Bordo del «file pronto» | rgba(47,163,90,.4) | **nuovo** `PrismaCliente.bordoPronto` = `Colore.verde.opacity(0.4)` |
| Colonna stretta | 290 di larghezza, spazio 10 | **nuovo** `PrismaCliente.larghezzaColonna = 290`, `spazioColonna = 10` |
| Spazio fra le colonne | 26 | **nuovo** `PrismaCliente.spazioColonne = 26` |
| Margini della zona destra | sinistra 400, destra 30, alto 30, basso 24 | in SwiftUI meglio: telefono a larghezza fissa + `HStack`; margini `PrismaCliente.margine` (30, 30, 24) |

**La cornice del telefono** (`.phone`, 204-206): **i suoi valori esistono già** nel tema, identici, in
`Tema.Apple.Inquadra.Apparecchio` (`DesignSystem/Apple/Tema.Apple+Inquadra.swift:42-66`: `larghezza` 300, `altezza` 620,
`raggio` 50, `corpo` #0D0F12, `filo` #2A2E34 da 2, `ombra` nero 0,55 raggio 40 y 40, `tacca` 92×26 raggio 20 a 22,
`rientro` 11, `raggioSchermo` 40). Come propone la parte comune (`01-comune.md` §4.2), si spostano in un
**`Tema.Apple.Apparecchio`** comune (Inquadra lo richiama) e **non** si crea un secondo insieme di gettoni. La vista è
nuova: `CorniceTelefono` (`DesignSystem/Apple/CorniceTelefonoApple.swift`, nessuna vista la disegna ancora), con il
contenuto dello schermo come parametro (qui la mini-app su fondo #F2F6F9, non lo `schermo` #1A1D21 di Inquadra);
riusata da altre parti di Luce (scanner, sinistro, nuovo cliente, nota vocale: righe 1102, 1872, 2000, 2040). Di nuovo
qui c'è solo il posto nel palco:

| Gettone nuovo (`Tema.Apple.PrismaCliente`) | Valore |
|---|---|
| `scalaTelefono` | 0,92, ancorata in alto a sinistra |
| `posizioneTelefono` | (44, −8) nel palco |

**La mini-app del cliente** (dentro il telefono e nel file) ha una tavolozza propria, fissa e chiara, come i documenti su
carta: va in `Tema.Apple.PrismaCliente.Mini` e la stessa tavolozza va scritta nel CSS del file (generato da Swift a
partire dagli stessi valori, così non si separano).

| Gettone `PrismaCliente.Mini` | Valore |
|---|---|
| `fondo` | #F2F6F9 |
| `testo` | #14202B |
| `testo2` | #5A6873 |
| `piede` | #7A8790 |
| `testataDa` / `testataA` | #E3EFF5 → #9DC2D6, angolo 165° |
| `altezzaTestata` | 210 |
| `card` | bianco, raggio 16, padding 12/14, spazio 10, ombra 0 8 18 −12 rgba(0,0,0,.25) |
| `occhiello` | 11, 700, spaziatura 0,5, `testo2` |
| `nome` | display 34, 700, −0,8 |
| `sopraNome` | 11, 700, spaziatura 1, opacità 0,6 |
| `anello` | 60, spessore 7 (nella card della Sala: 70 e 8) |
| `etichettaAnello` | 10, interlinea 1,2, larghezza 72 |
| `eta` | display 24, grassetto |
| `linea` | #8B5CF6 (= `Colore.Area.previdenza`), spessore 2,2; area alla stessa tinta con opacità 0,15; tratteggio [2, 3] |
| `basta` / `nonBasta` | #2F7A4A / #E5484D (`Colore.rosso`) |
| `lettera` | #C45A75 (colore dell'esperienza «lettera») |
| `cardFilm` | #0F1C26, cerchio bianco a 0,15 |
| `freccia` | #0A84FF |
| `onda` | cerchio 60, bordo 2 bianco a 0,8 |
| `logo` | 22, i tre spicchi #0F2433 **fisso** con opacità 1 / 0,66 / 0,38: è `LogoPrisma`, non un'immagine. Non `Colore.logo`, che in scuro diventa bianco (`TemaApple.swift:66`): la mini-app resta chiara |

Gli anelli usano `Anello` / `AnelliConcentrici` (`DesignSystem/Apple/AnelliApple.swift:104,28`). Il colore di ogni obiettivo
si ricava dalla sua area con `Tema.Apple.Clienti.Obiettivi.colore(_:)` (`Tema.Apple+Dossier.swift:146`, dentro
`extension Tema.Apple.Clienti` › `enum Obiettivi`), non da colori nuovi: sono colori fissi (`anello1/2/3`,
`TemaApple.swift:92-94`, e i colori delle aree), quindi valgono uguali nella mini-app chiara e nel CSS del file.

#### 2.1.3 Movimento

| Cosa | Template | In Prisma |
|---|---|---|
| Entrata del palco | 520 ms, opacità 0→1, scala 0,98→1, (.22,1,.36,1) | `Moto.Curva.uscita`; gettone del palco nella parte della Sala |
| Nome che si scrive | una lettera ogni 110 ms (`setInterval`, 1249) | Come la parte comune (`01-comune.md` §4.6 e Movimento): il testo progressivo esiste già, `TestoProgressivo` (`DesignSystem/Apple/RubyApple.swift:174`, una **parola** per passo, `Moto.Testo.parola` 0,038); qui serve il passo **per lettera**: gettone **nuovo** `Moto.Testo.lettera`, con il valore di questo punto `nomeMini = 0.11` (non un `Moto.Digitazione` a parte). Niente Timer: una vista `Animatable` con il numero di lettere come valore animato (lineare, durata = lettere × 0,11) |
| Onde della testata | 3,3 s, ease-out, scala 0,2→2,6, opacità 0,9→0, ripetute; ritardi 0 / 1,1 / 2,2 s | **nuovo** `Moto.OndaMini` (`durata 3.3`, `scalaDa 0.2`, `scalaA 2.6`, `opacitaDa 0.9`, `sfasamento 1.1`), `repeatForever` di SwiftUI |
| Anelli | `anello()` (392): come gli anelli del tema | `Moto.Anello` |
| Linea della pensione | ridisegnata subito a ogni passo del cursore | come la linea della vita: `TracciatoGrafico` senza animazione durante il trascinamento |
| Barra «Preparo il file…» | larghezza 0→100% in 1,3 s, cubic-bezier(.4,0,.2,1) | **la barra deve seguire il lavoro vero** (cifratura e scrittura), non un tempo fisso. Curva **nuova** `Moto.Curva.standard = (0.4, 0, 0.2, 1)` solo per l'ultimo tratto |
| Tile «file pronto» | 420 ms, scala 0,9→1 e opacità 0→1, `--spring` | `Moto.Curva.molla`, **nuovo** `Moto.FilePronto` (`durata 0.42`, `scala 0.9`) |
| Interruttori | `.sw` del template | `Moto.Interruttore` |

- **Riduci movimento** (`\.prismaCalmo`): il nome compare intero, le onde sono ferme (tre cerchi immobili con opacità 0,35),
  anelli pieni, la tile del file pronto compare con la dissolvenza di 0,15 s. Il template su questo punto riduce solo il
  passo del nome a 1 ms (1249): vale la regola di Prisma.
- **Istantanee** (`\.modoIstantanea` / `\.prismaStatoFinale`): nome intero, onde ferme a metà del loro giro, anelli pieni,
  linea tracciata, interruttori nella posizione dei dati. Niente Timer.

#### 2.1.4 Interazioni

Mac (il palco):
- **Interruttori di «Cosa c'è dentro»**: cambiano il contenuto del file **e l'anteprima nel telefono** (nel template
  l'anteprima non cambia: nell'app sì, le card spente spariscono dal telefono con la cascata inversa). Una voce si può
  accendere solo se il dato c'è (§1.6): altrimenti è spenta, non attivabile, con la ragione sotto in `.k` («La lettera non è
  ancora pronta: preparala nella Sala ›»). «Le posizioni nel dettaglio» parte spento.
- **Cursore dell'anteprima** «E se vado in pensione a…»: si prova come lo proverà il cliente, la linea si ridisegna
  (`miniLinea`, 1246-1248). Valori ammessi 58-70 nel template; nell'app quelli di `MotoreLineaVita.etaPensioneMinima/Massima`
  (55-72) ristretti a 58-70 per il file, da confermare.
- **Password**: «Mostra» / «Nascondi». Prisma propone una password nuova a ogni file (tre parti: parola-parola-numero, come
  «Lago-Vela-27»), con il pulsante «Un'altra» (non nel template) e la possibilità di scriverla a mano. **Non** basta la
  regola dei PDF (`ImpostazioniPDF.lunghezzaMinima = 6`, `DatiPrisma.swift:446`, né le regole «data di nascita» o «codice
  fiscale», che chi trova il file può indovinare): il file gira offline e si può attaccare per tentativi senza limite,
  quindi serve una password più robusta (D12). **Prisma non conserva la password** (come per i PDF protetti,
  `ModuloSalvaPDF.swift:14-15`).
- **«Si può aprire fino al»**: un selettore di data (proposta: un anno da oggi). Vedi §1.8 per che cosa vale davvero.
- **«Prepara il file»**: crea il file nella cartella dei documenti del cliente (vedi §1.5), lo registra nella scheda
  Documenti del dossier e mostra la tile «file pronto»; un clic sulla tile lo mostra nel Finder.
- **«Manda con Messaggi»**: apre Messaggi con il file allegato e il destinatario del dossier, **senza la password nel
  testo**, attraverso `AperturaMessaggi.apri(testo:oggetto:canale:cliente:allegati:)` (`Shell/CollegamentiMessaggi.swift:147`,
  estensione di `enum AperturaMessaggi` di `Shell/AperturaMessaggi.swift:35`):
  Prisma non spedisce mai, la spedizione la fa il consulente. Se il file non è ancora pronto, il pulsante lo prepara prima.
  Proposta: accanto, un menu «Altro» con Mail e AirDrop (servizio di condivisione del sistema).
- Dalle altre esperienze, «✦ Aggiungi al Prisma di Giulia» (palco, 1219) accende la voce corrispondente e la segna «nuova
  dall'ultimo file» (§1.5).

Cliente (il file, sul suo telefono):
- Apre il file → schermata con il logo e il campo «Password» e il pulsante «Apri». Password sbagliata: «La password non è
  giusta» (nessun conteggio di tentativi: non si può imporre in un file). Dopo la data di scadenza (§1.8): «Questo Prisma
  era valido fino al 5 novembre 2027. Chiedi a Denis una copia aggiornata.»
- Dentro: scorre in verticale; il cursore della pensione funziona; «Una lettera da te ›» apre la lettera a tutta pagina;
  «Il film del tuo piano» riproduce il video (elemento `<video>` del browser, con i comandi di sistema).
- Nessun collegamento esterno, nessuna risorsa caricata da internet (niente Google Fonts: il carattere è quello di sistema
  del telefono, `-apple-system`), nessun modulo che invii qualcosa.

iPhone e iPad (di Prisma): il template non prevede la preparazione del file fuori dal Mac. Proposta: solo sul Mac (è lì
che stanno archivio, motori e documenti).

#### 2.1.5 Mappa verso Prisma

**Esiste già (verificato con grep in `Sources/Prisma`):**
- Obiettivi del cliente: `struct Obiettivo` (`Dati/Prodotti.swift:172`, campi `titolo`, `area`, `importo`, `scadenza`,
  `accantonato`, `posizioniCollegate`); `StatoShell.obiettiviCliente(_:)` (`Shell/StatoShell.swift:1507`);
  `MotoreObiettivo.calcola(_:posizioni:data:)` → `EsitoObiettivo` (`Motori/MotoreObiettivo.swift:27-42,65`), con
  `disponibileOggi` (accantonato + posizioni collegate) e `copertura` (0…1, **proiezione** alla scadenza / importo alla
  scadenza). L'anello del template (`pctObi` = già da parte / traguardo) corrisponde a `disponibileOggi / importo`, non a
  `copertura`: quale mostrare al cliente è la D13.
- Linea della vita: `MotoreLineaVita.prepara(cliente:posizioni:obiettivi:eventi:analisi:...)` e `calcola(_:)`
  (`Motori/MotoreLineaVita.swift:150,109`), con `IngressoLineaVita.etaPensione`, `EsitoLineaVita.etaEsaurimento` e `basta`.
  `prepara` dà già il motivo quando manca la data di nascita («Per disegnare la linea della vita serve la data di nascita
  di …»).
- Cifratura: `CifraturaBackup` (`Dati/CifraturaBackup.swift`): PBKDF2-HMAC-SHA256 con CommonCrypto
  (`iterazioniPredefinite = 600_000`, riga 34; password normalizzata con `precomposedStringWithCanonicalMapping`, cioè
  NFC, riga 311), sale di 16 byte (`lunghezzaSale`, 36), AES-256-GCM con CryptoKit, `casuali(_:)` (348, interna). La
  funzione `derivaChiave` è `private` (310), **ma è già esposta** da `chiaveSpazio(passphrase:sale:iterazioni:)` (174,
  interna, nata per Prisma ovunque): il file del cliente la riusa (o un gemello `chiaveFileCliente` con lo stesso corpo),
  senza toccare la visibilità. I backup usano anche una sottochiave HKDF (`sottochiave`, 336, privata): per il file si
  sceglie se fare lo stesso (WebCrypto ha HKDF) o usare direttamente la chiave PBKDF2; il formato va scritto e
  versionato nell'intestazione.
- Apertura di Messaggi con allegati: `AperturaMessaggi.apri(testo:oggetto:canale:cliente:allegati:)`
  (`Shell/CollegamentiMessaggi.swift:147`), con il ripiego che mostra il file nel Finder; senza recapito l'esito è
  `.mancaRecapito` (`Shell/AperturaMessaggi.swift:20`).
- Password dei PDF per il cliente: `ImpostazioniPDF` (`Dati/DatiPrisma.swift:407-447`, regole `dataNascita`,
  `codiceFiscale`, `aMano`) e `ModuloSalvaPDF` (`Shell/ModuloSalvaPDF.swift`), che non conserva la password.
- Documenti del dossier: `Documento` con `Tipo` (`Dati/Documento.swift:7`: `kid`, `polizza`, `estrattoConto`, `proposta`,
  `prospetto`, `report`, `altro`).
- Avvertenze dei documenti per il cliente: `TestiIpotesiStimate` (`Shell/ProspettoIpotesiStimate.swift`) e le pagine dei
  report.
- Logo vettoriale: `LogoPrisma`.
- Componenti: `Anello`, `TracciatoGrafico` (`GraficiApple.swift:206`), `StileInterruttoreApple` (`ControlliApple.swift:128`),
  `CursoreApple` (`ControlliApple.swift:215`), `BarraPiena`, `StilePulsanteApple`, `Superficie.tile`.

**Cosa manca:**
1. **`PalcoPrismaCliente`** (`Shell/SalaPrismaCliente.swift`): la vista del palco (anteprima nel telefono + colonna di
   preparazione). Dentro, la mini-app è una vista SwiftUI **`MiniPrisma`** che disegna gli stessi blocchi del file a
   partire dallo stesso modello (`ContenutoPrismaCliente`), così anteprima e file non divergono.
2. **Modello `ContenutoPrismaCliente`** (`Dati/PrismaCliente.swift`), `Codable`, **solo ciò che il cliente vedrà**:
   - `nomeBattesimo`, `consulente` («Denis Vicenzoni · il tuo consulente», dalle Impostazioni del profilo), `creatoIl`,
     `validoFinoAl`;
   - `obiettivi: [ObiettivoMini]` (`titolo`, `quota` 0…1 secondo la D13, `coloreArea`), al massimo 3 come nel template (proposta: i 3
     con priorità più alta), solo se la voce è accesa;
   - `lineaVita: LineaVitaMini?`: età di oggi, età di pensione proposta, e **le serie già calcolate da Prisma** per ogni età
     di pensione del cursore (58…70 → 13 serie di punti annui fino a 90, circa 13×60 numeri), con `etaEsaurimento` per
     ciascuna. Così **il file non contiene nessun motore di calcolo**: il cursore sceglie una serie, le cifre restano
     quelle di Prisma;
   - `lettera: String?` (testo della «Lettera dal futuro», altra parte di Luce), `film: Data?` (video MP4 del «Film del
     piano», altra parte), `luce: Data?` (immagine PNG del prisma di luce, §2.4, se aggiunta);
   - `posizioni: [PosizioneMini]?` solo se la voce è accesa: nome del prodotto, **canale**, valore, data; niente numeri di
     polizza, IBAN, codici fiscali;
   - `avvertenze: [String]` (§1.6 e §1.8).
3. **Motore `CompositorePrismaCliente`** (`Motori/CompositorePrismaCliente.swift`): dai dati del cliente e dalle scelte
   costruisce `ContenutoPrismaCliente` (chiama `MotoreObiettivo`, `MotoreLineaVita.prepara` una volta e `calcola` 13 volte).
4. **`FilePrismaCliente`** (`Dati/FilePrismaCliente.swift`): scrive l'HTML.
   - Cifra il JSON di `ContenutoPrismaCliente` (con il video in base64 dentro) con AES-256-GCM; chiave = PBKDF2-HMAC-SHA256
     (password in forma Unicode normalizzata NFC, come `derivaChiave`; nel lettore `password.normalize('NFC')`; sale casuale 16 byte, iterazioni da decidere, §1.8), nonce 12 byte,
     dati associati = intestazione (versione, sale, iterazioni, data di scadenza in chiaro).
   - Inserisce nell'HTML il blocco in base64 e il programma di lettura (`Risorse/PrismaCliente/lettore.js` e
     `lettore.css`, scritti a mano, niente librerie; i colori del CSS li scrive Swift da `PrismaCliente.Mini`).
   - Nome del file: «Il-Prisma-di-<Nome>.html» (solo il nome di battesimo, come nel template).
   - Dimensione: senza film poche decine di KB; con il film quanto il video (il template dice 1,4 MB).
5. **Password**: `GeneratorePassword` (`Dati/GeneratorePassword.swift`) con un elenco di parole italiane semplici in
   `Risorse/PrismaCliente/parole.txt` e `SecRandomCopyBytes` (`CifraturaBackup.casuali`).
6. **Traccia di ciò che il cliente ha ricevuto**: un `Documento` nel dossier, tipo `.report` (o un tipo nuovo
   `.prismaCliente`, da decidere), con data, contenuti accesi e scadenza, e **una copia leggibile dal consulente** (il
   PDF della stessa mini-app, oppure il JSON in chiaro dentro l'archivio). Attenzione: i backup sono cifrati **solo se**
   la protezione è accesa (`protetto`, facoltativa, `DatiPrisma.swift:605-610`): altrimenti la copia sta in chiaro come il
   resto dell'archivio. Mai la password.
7. **Campi nuovi dell'archivio** (versione dopo la 26 attuale, `DatiPrisma.versioneAttuale = 26`, `DatiPrisma.swift:113`):
   `Cliente.prismaCliente: StatoPrismaCliente?` con `ultimoFile: Date?`, `validoFinoAl: Date?`, `contenuti: Set<String>`,
   `aggiunteDopoUltimoFile: Set<String>` (per «nuova dall'ultimo file»). Letti con `decodeIfPresent`; `--prova-backup`
   aggiornato.
8. **Prove**:
   - `ProvaFilePrismaCliente` (in `ProvaCalcoli`): il JSON in chiaro **non contiene** i campi delle voci spente (cerca nomi
     dei prodotti, importi delle posizioni, codice fiscale, email, telefono del cliente); il file in chiaro (fuori dal
     blocco cifrato) non contiene il nome del cliente né cifre; cifratura e decifratura tornano uguali; password sbagliata
     → errore.
   - **Prova del lettore JavaScript** nel workflow: `Prisma --prova-file-cliente <cartella>` scrive un file di prova; un
     piccolo script Node senza dipendenze (`Supporto/prova-file-cliente.mjs`, usa `globalThis.crypto.subtle` di Node)
     estrae il blocco e lo decifra con la password di prova. Node c'è già sui runner macOS di GitHub: **non è una
     dipendenza dell'app**, ma va confermato (§1.8).
9. **Collegamenti**: «✦ Aggiungi al Prisma di …» dalle esperienze `lettera`, `film`, `luce`, `giornata`, `disegna`
   (`palcoHTML`, 1219) scrive in `aggiunteDopoUltimoFile`. Le parti di quelle esperienze dicono che cosa esportano (testo,
   video, immagine).

#### 2.1.6 Dati che l'utente deve dare e stati vuoti

| Dato | Da dove | Se manca |
|---|---|---|
| Nome di battesimo | `Cliente.nome` (prima parola) | Sempre presente. |
| Obiettivi | `Obiettivo` del dossier | Voce spenta e non attivabile: «Giulia non ha ancora obiettivi nel dossier › Aggiungi un obiettivo». La card sparisce dal telefono. |
| Copertura degli obiettivi | `MotoreObiettivo` | Se un obiettivo non ha importo o scadenza validi, non entra (mai un anello inventato). |
| Linea della vita | `MotoreLineaVita.prepara` (data di nascita, posizioni, Analisi 360) | Senza data di nascita: voce spenta con il motivo di `prepara` e «Completa l'anagrafica ›». Senza reddito desiderato in pensione la linea dopo la pensione è solo indicativa (`dopoPensioneIndicativa`): nel file la frase verde/rossa **non si scrive** e al suo posto «Dopo la pensione la linea è indicativa: ne parliamo insieme». |
| Lettera dal futuro | esperienza «lettera» (altra parte) | Voce spenta: «La lettera non è ancora pronta › Apri la lettera». |
| Film del piano | esperienza «film» (altra parte) | Voce spenta: «Il film non è ancora pronto › Apri il film». |
| Posizioni | posizioni in essere del cliente | Voce spenta se non ce ne sono. |
| Nome del consulente nel piede | Impostazioni › profilo | Se manca, il piede dice solo «Il tuo consulente». |
| Recapito per Messaggi | `Cliente.telefono` o `email` | «Manda con Messaggi» resta attivo ma l'esito è `.mancaRecapito` e il pulsante lo dice; il file resta preparato. |
| Avvertenze | **l'utente** (vedi §1.8) | Senza testo approvato dall'utente il file si prepara con la sola frase del template «Stime basate su ipotesi, non garanzie di risultato.» e un avviso nel palco: «Le avvertenze del file non sono ancora scelte › Impostazioni». |

Se tutte le voci sono spente, «Prepara il file» è disattivo: «Accendi almeno una voce».

Dati di prova: i 5 clienti del template con lettera e film di prova (segnati «dati di prova»), caricati solo con i clienti
fittizi.

#### 2.1.7 Istantanee da aggiungere

Numeri proposti (liberi oggi in `Sources/`: l'ultima serie usata sul Mac è 613; da riconciliare con le altre parti di
Luce nella tabella dei numeri):

| Nome | Scena |
|---|---|
| `620-sala-prisma-cliente` (+ `-scuro`) | Giulia, tutte le voci del template, stato iniziale |
| `621-sala-prisma-cliente-file-pronto` (+ `-scuro`) | Dopo «Prepara il file»: tile verde |
| `622-sala-prisma-cliente-dati-mancanti` (+ `-scuro`) | Andrea senza data di nascita e senza lettera né film: voci spente con i motivi |
| `623-sala-prisma-cliente-password` | Password mostrata e scadenza scelta |

La pagina del file stesso (HTML) non si fotografa con le istantanee di SwiftUI: la sua resa si controlla nella prova
Node (§1.5.8) e, a vista, aprendo il file di prova in un browser. Aggiornare la vetrina «400-vetrina-apple» con la
`CorniceTelefono` e la pagina online delle anteprime.

#### 2.1.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole toccate: «Tutto resta in locale sul Mac: niente server, niente cloud»; «I dati dei clienti… restano sul Mac, mai
inviati a servizi esterni»; canale sempre riconoscibile; nessuna dipendenza esterna; valori centralizzati nel tema.

**Questa funzione fa uscire dati del cliente dal Mac**: un file con i suoi obiettivi, la sua linea della vita (cifre
patrimoniali), la lettera, il film e, se acceso, le posizioni. Esce perché lo spedisce il consulente, cifrato, ma esce.
È lo stesso principio dei PDF protetti già in Prisma (`ModuloSalvaPDF` + Messaggi), con più contenuto. Decisioni:

1. **D1 · Approvare l'uscita del file.** Il file cifrato con password, creato sul Mac e spedito dal consulente, è
   un'eccezione alla regola «niente esce»? Proposta: sì, alle stesse condizioni dei PDF per il cliente (cifrato, password
   non conservata, spedizione fatta dal consulente, traccia nel dossier).
2. **D2 · Il formato: HTML o PDF.** **Punto critico da verificare su un iPhone vero prima di costruire:** quando il cliente
   tocca un allegato `.html` in Messaggi o in Mail, l'iPhone lo mostra con l'anteprima rapida (Quick Look), che **con ogni
   probabilità non esegue JavaScript**: il file si vedrebbe vuoto (solo la richiesta di password, che non funziona). Su
   Android dipende dall'app che lo apre. Strade:
   - (a) HTML come nel template, con un messaggio di ripiego in chiaro («Se non vedi il campo della password, apri il
     file con Safari o con Chrome»), **solo se la prova su iPhone e Android passa**;
   - (b) **PDF protetto da password** (Quick Look lo apre e chiede la password da sé): obiettivi e lettera uguali; al posto
     del cursore una tabella «Se vai in pensione a 60 / 62 / 64 / 67 / 70 anni → i risparmi bastano fino a …»; il film
     come file separato o link a nulla (si perde dentro il PDF);
   - (c) tutti e due: il PDF sempre, l'HTML in più per chi lo apre nel browser.
   Proposta: (c), con (b) come base sicura.
   Altro limite tecnico della strada (a): la decifratura usa `crypto.subtle` (WebCrypto), che i browser danno **solo in
   un contesto sicuro**. Un file aperto da `file://` in Safari o Chrome di solito lo è, ma i visori integrati (anteprima
   di Mail, di WhatsApp, `content://` di alcune app Android) possono non esporlo: il lettore deve accorgersene e dire
   «Apri questo file con Safari o Chrome», mai fallire in silenzio. Da includere nella prova sui telefoni veri.
3. **D3 · Come arriva al cliente.** «Manda con Messaggi» passa da iMessage (servizio Apple, cifrato da capo a capo) o da
   SMS/MMS (non cifrato, ma il file sì). Approvare Messaggi, Mail e AirDrop come vie; **WhatsApp** solo tramite il foglio di
   condivisione del sistema, se l'utente lo vuole (servizio di terzi). La password **mai** nello stesso messaggio: Prisma lo
   impone (il testo del messaggio non la contiene) e lo ricorda nel palco.
4. **D4 · Cifratura e numero di iterazioni.** Nel browser di un telefono 600.000 iterazioni PBKDF2 (quelle dei backup)
   richiedono circa un secondo: accettabile? Proposta: 600.000, come i backup. Formato con versione nell'intestazione.
5. **D5 · «Si può aprire fino al».** In un file offline la scadenza **non si può imporre**: il programma guarda la data del
   telefono, che il cliente può cambiare; la data sta anche dentro il blocco cifrato e autenticato, ma resta un invito. Va
   detto così nel palco («Dopo questa data il file invita a chiedere una copia aggiornata») oppure tolta. Proposta: tenerla
   con la frase onesta.
6. **D6 · Testi normativi.** Il template dice «Il contenuto è quello dei prospetti approvati, con le stesse avvertenze».
   Le avvertenze di un documento dato al cliente con proiezioni (informativa, materiale promozionale, regole IDD/MiFID per
   i prodotti Alleanza, eventuale approvazione di Alleanza per materiale con il suo marchio) **non si possono inventare**:
   le deve dare l'utente (testo e, se serve, l'approvazione della compagnia). Nel frattempo vale solo «Stime basate su
   ipotesi, non garanzie di risultato.» del template.
7. **D7 · Il canale nel file.** Il piede del template è neutro («Denis Vicenzoni · il tuo consulente»). Se nel file entrano
   le posizioni, ogni posizione porta l'etichetta del suo canale (Alleanza in blu con il logo, indipendente in cuoio con
   «Denis Vicenzoni · Consulenza finanziaria»). Si può usare il **logo Alleanza** in un file dato al cliente fuori dai
   materiali della compagnia? Da decidere con Alleanza; proposta: nelle versioni compatte solo il colore e la parola
   «Alleanza», senza logo, finché l'utente non conferma.
8. **D8 · Chiaro o scuro nel file.** Il template è sempre chiaro. Proposta: il file segue l'aspetto del telefono del
   cliente (`prefers-color-scheme`), con la tavolozza chiara del template come base e una scura da approvare; oppure
   sempre chiaro come i documenti. Proposta di default: sempre chiaro.
9. **D9 · Copia per il consulente.** Conservare nel dossier una copia leggibile di ciò che il cliente ha ricevuto (per
   ricordare che cosa gli si è dato e quando). Proposta: sì, come documento del dossier. Nei backup è cifrata solo se
   la protezione dei backup è accesa (oggi facoltativa): proposta, ricordarlo nel palco quando è spenta.
10. **D10 · Prova con Node nel workflow.** Usare Node del runner solo per la prova del lettore (nessuna dipendenza
    nell'app). Oggi il workflow non usa Node (`.github/workflows/build.yml`): è un passo nuovo. Da approvare.
11. **D11 · Il nome del cliente nel nome del file.** «Il-Prisma-di-Giulia.html» mette il nome di battesimo **in chiaro**
    fuori dalla cifratura: si vede nell'anteprima di Messaggi o Mail, nella cartella Download del cliente, in iCloud. È
    poco (solo il nome), ma è un dato personale che esce non cifrato. Proposta: tenerlo (il cliente riconosce il file);
    in alternativa «Il-tuo-Prisma.html».
12. **D12 · Robustezza della password.** Il file può essere copiato e provato per tentativi senza limite, offline. Una
    password «parola-parola-due cifre» da un elenco di qualche migliaio di parole ha circa 2.000×2.000×100 = 4×10⁸
    combinazioni: con 600.000 iterazioni PBKDF2 resiste, ma non molto, a chi ha schede grafiche dedicate. Le regole dei PDF
    (data di nascita, codice fiscale, minimo 6 caratteri) **non vanno bene** qui. Proposta: tre parole e un numero
    («Lago-Vela-Pino-27», circa 8×10¹¹), minimo 12 caratteri se scritta a mano, niente regole ricavate dai dati del
    cliente. Da scegliere con l'utente (più sicura = più scomoda da dettare a voce).
13. **D13 · Che cosa misura l'anello.** Il template mostra il già da parte rispetto al traguardo (`pctObi`, riga 439);
    Prisma calcola anche la copertura **proiettata** alla scadenza (`EsitoObiettivo.copertura`). Al cliente si mostra
    l'una o l'altra, con la frase che dice quale («Hai già messo da parte il 40%» oppure «Al ritmo attuale arrivi
    all'85%»). Proposta: il già da parte, come il template, che non dipende da ipotesi di rendimento.

Nessuna API sopra macOS 13 è necessaria (CryptoKit dal 10.15, CommonCrypto, `NSSharingService`).

---

### 2.2 Il prisma di luce

*Novità 8 di 15 «davanti al cliente» · voce `NOV15[7]` · `FS_LUCE` (1439-1508), `luceDati` (1510-1512), `ESPH.luce`
(1513-1517), `ESPM.luce` (1518-1550); motore WebGL comune `glTela` (1423-1436)*

Il patrimonio del cliente diventa un raggio di luce bianca che entra in un cristallo a forma del logo di Prisma e ne esce
scomposto in un ventaglio di colori: ogni colore è una parte del patrimonio, lo spessore è il suo peso. Si può guardare
per investimento, per obiettivo o per canale, girare il cristallo e far scorrere gli anni.

#### 2.2.1 Cosa si vede

Schermate `sala-luce-chiaro.png`, `sala-luce-hover.png`, `sala-luce-canale.png`. **Il palco è sempre scuro**, anche con
Prisma chiaro: fondo #05090D (`ESPM.luce`, 1519) e sopra la tela disegnata dallo shader. In scuro (`sala-luce-scuro.png`)
cambia solo la finestra intorno.

Sopra la tela, in bianco:

- **In alto a sinistra** (30, 26): occhiello «IL PATRIMONIO DI GIULIA ROSSI» (11,5 pt, 700, spaziatura 1,6, opacità 0,55;
  nome intero in maiuscolo); sotto, in riga allineata sulla base, il **totale** «204.050 €» (display 44, 700, −1,2,
  cifre tabellari), che si conta da 0, e accanto «oggi» o «nel 2034» (15 pt, opacità 0,6).
- **In alto a destra** (26, 24): segmentato scuro `.segScuro` (259) con «Per investimento» · «Per obiettivo» · «Per
  canale». Fondo bianco a 0,1, pillola bianca a 0,22 senza ombra, testo bianco a 0,65, scelto bianco pieno.
- **La scena** (lo shader, §2.2-bis):
  - fondo blu notte con un alone più chiaro in alto a sinistra e un'ombra ai bordi;
  - da sinistra entra un **raggio di luce bianca calda**, quasi orizzontale (sale leggermente verso destra), con un
    pulviscolo luminoso che scorre lungo il raggio;
  - il raggio colpisce il **cristallo**: un triangolo di vetro con gli spigoli arrotondati, centrato al 43% della
    larghezza e al 47% dell'altezza, diviso in **tre facce come il logo** (le tre linee dal punto interno ai tre vertici);
    bordi luminosi, facce con luminosità diverse, un riflesso che scorre lento;
  - dentro il vetro la luce attraversa il cristallo e comincia a colorarsi;
  - dal lato destro esce il **ventaglio**: una fascia per ogni parte del patrimonio, con la larghezza proporzionale al
    peso; vicino al cristallo le fasce sono bianche e unite, allontanandosi prendono colore e si separano con un filo
    scuro; una sottile trama a righe le rende «di seta»;
  - sotto il cristallo, a 100 punti dalla base, un **pavimento lucido**: la scena si riflette capovolta, tenue, con una
    leggera ondulazione, e un filo d'orizzonte appena visibile.
- **Etichette in fondo ai raggi** (`.lLab`, 261-264): per ogni fascia, poco oltre la sua punta, il nome (15 pt, 600) con un
  pallino da 8 del colore della fascia e un alone dello stesso colore, e sotto «38% · 77.539 €» (12,5 pt, opacità 0,62,
  tabellari, rientrato di 16). Le etichette si scostano in verticale per stare almeno a 44 punti l'una dall'altra.
- **In basso a sinistra** (30, 26) il **pannello del dettaglio**, largo 300, padding 16/18, raggio 18, fondo bianco a
  0,07, bordo bianco a 0,12, sfocatura 18:
  - senza raggio scelto: «PASSA SUI RAGGI» (12 pt, 600, opacità 0,55, spaziatura 0,4) e «Ogni raggio è una parte del
    patrimonio: lo spessore è il suo peso. Trascina il cristallo per ruotarlo.» (14 pt, opacità 0,85, interlinea 1,45);
  - con un raggio sotto il puntatore: pallino 10 con alone, nome (16 pt grassetto), la cifra (display 32, 700, −0,8) e
    «38% del patrimonio oggi» (o «… nel 2034»; 13,5 pt, opacità 0,7).
- **In basso a destra** (30, 26), largo 340: «OGGI» e «FRA VENT'ANNI» ai due capi (12 pt, opacità 0,6, 600, spaziatura
  0,4) e sotto il cursore degli anni da 2026 a 2046 (binario bianco a 0,15).

**Le tre viste** (`luceDati`, 1510-1512):

| Vista | Fasce | Colori del template |
|---|---|---|
| Per investimento | Azionario, Obbligazionario, Gestione separata, Liquidità (solo quelle > 0) | #3B82F6, #5AC8FA, #A78BFA, #34D399 |
| Per obiettivo | Un raggio per obiettivo (quanto vi è già destinato) + «Liquidità e altro» | colore di ogni obiettivo; «Liquidità e altro» #CBD5E1 |
| Per canale | Alleanza, Indipendente (solo quelle > 0) | #4F7DFF, #E3A04A |

Nel template la vista «per obiettivo» tiene per «Liquidità e altro» **almeno il 20%** del patrimonio
(`Math.max(c.pn-tot, c.pn*.2)`, 1510) e la vista «per canale» di un cliente con tutti e due i canali usa un 47% fisso:
**sono numeri inventati del template, in Prisma no** (§2.5).

**Stati:**

| Stato | Cosa si vede |
|---|---|
| Apertura | Il raggio entra, poi il vetro appare, poi il ventaglio si apre, poi le etichette (§2.3). |
| Riposo | Il cristallo oscilla appena (±2°), il pulviscolo scorre, la luce «respira». |
| Raggio scelto | La fascia sotto il puntatore si accende (peso 1,75), le altre si spengono (0,22); le etichette delle altre scendono a opacità 0,22; il pannello mostra la cifra. |
| Cambio di vista | Le fasce si trasformano in 850 ms (bordi e colori interpolati); le etichette svaniscono e ricompaiono a cascata. |
| Anno diverso da oggi | Il totale si conta fino al valore dell'anno, il ventaglio si allunga (più patrimonio, raggi più lunghi), «nel 2034». |
| Senza grafica accelerata | Nel template `NOGL`: «Questa vista ha bisogno della grafica accelerata (WebGL).» In Prisma: il fermo-immagine (§2.5). |

#### 2.2.2 Misure e stile

**Gettoni nuovi, `Tema.Apple.Luce`** (file `DesignSystem/Apple/Tema.Apple+Luce.swift`):

| Gettone | Valore | Nota |
|---|---|---|
| `fondoPalco` | #05090D | sempre, chiaro e scuro |
| `testo` | bianco; `testo2` bianco 0,6; `testo3` bianco 0,55 | |
| `occhiello` | 11,5, 700, spaziatura 1,6 | |
| `totale` | display 44, 700, −1,2, tabellari | |
| `anno` | 15, regular | |
| `margine` | 30 a sinistra/destra, 26 in alto/in basso (24 per il segmentato) | |
| `Segmentato.fondo` / `.pillola` / `.testo` / `.testoScelto` | bianco 0,10 / 0,22 / 0,65 / 1 | variante scura di `SegmentatoPillola` |
| `Dettaglio.larghezza` | 300 | |
| `Dettaglio.superficie` | bianco 0,07, bordo bianco 0,12, sfocatura 18, raggio 18, padding 16/18 | `Superficie` nuova `.vetroNotte` |
| `Dettaglio.cifra` | display 32, 700, −0,8 | |
| `Etichetta.nome` | 15, 600, −0,1; pallino 8, alone 12 | |
| `Etichetta.valore` | 12,5, opacità 0,62, rientro 16, tabellari | |
| `Etichetta.distanzaMinima` | 44 | |
| `Etichetta.oltreLaPunta` | 16 | distanza dalla punta del raggio |
| `Etichetta.attenuata` | 0,22 | |
| `Cursore.larghezza` | 340; binario bianco 0,15 | |
| `Raggi.investimento` | #3B82F6, #5AC8FA, #A78BFA, #34D399 | **diversi** da `Colore.Composizione` (#0A84FF, #5AC8FA, #2563EB, #9FB3C2): sono più chiari per il fondo notte; vedi D4 |
| `Raggi.altro` | #CBD5E1 | «Liquidità e altro» |
| `Raggi.alleanza` / `.indipendente` | #4F7DFF / #E3A04A | **da decidere** (D3): proposta usare le varianti scure dei canali già nel tema, #6B95FF e #D0954A |
| `Raggi.massimo` | 6 | limite dello shader |
| `scalaRisoluzione` | 1,6 | come `glTela(...,1.6)`: la tela non va oltre 1,6 pixel per punto |

**Geometria della scena** (in punti del palco, misure del template in `ESPM.luce` 1519-1521):

| Cosa | Valore |
|---|---|
| Centro del cristallo `C` | (0,43 × larghezza, 0,47 × altezza) |
| Raggio del triangolo `R` | min(150, 0,25 × altezza) |
| Vertici (prima della rotazione) | P0 = C + (0, −R) in alto; P1 = C + (−0,866R, 0,5R); P2 = C + (0,866R, 0,5R) |
| Punto interno del logo `Q` | C + (0, 0,2R) |
| Punto d'entrata `E` | sul lato P0→P1 al 57% |
| Punto d'uscita `X` | sul lato P0→P2 al 60% |
| Direzione del raggio | normalize(1, −0,085) |
| Apertura del ventaglio | 0,5 rad; direzione centrale 0,08 + 1,55 × rotazione |
| Lunghezza del ventaglio | min(larghezza − X.x − 250, 560) × (0,72 + 0,28 × √(valore dell'anno / massimo dei 20 anni)) |
| Pavimento | y = C.y + 0,5R + 100 |
| Rotazione massima | ±0,22 rad |

##### 2.2.2-bis Lo shader `FS_LUCE`, in dettaglio (1439-1508)

Un solo fragment shader a schermo intero (un triangolo grande, `glTela` 1424-1433). Coordinate `p` in **punti** con
l'origine in alto a sinistra: `p = (gl_FragCoord.x, u_res.y − gl_FragCoord.y) / u_d`.

**Uniform:**

| Uniform | Tipo | Significato | Valori |
|---|---|---|---|
| `u_res` | vec2 | dimensione della tela in pixel | |
| `u_d` | float | pixel per punto | min(1,6, scala dello schermo) |
| `u_C` | vec2 | centro del cristallo (punti) | |
| `u_R` | float | raggio del cristallo (punti) | ≤ 150 |
| `u_t` | float | tempo in secondi | |
| `u_rot` | float | rotazione del cristallo (rad) | −0,22…0,22 |
| `u_beam` | float | quanto il raggio d'entrata è arrivato | 0→1 |
| `u_glass` | float | quanto il vetro è visibile | 0→1 |
| `u_fan` | float | quanto il ventaglio è aperto | 0→1 |
| `u_len` | float | lunghezza del ventaglio (punti) | |
| `u_n` | float | numero di fasce | 1…6 |
| `u_lum` | float | respiro della luce | 0,9 + 0,1 × sin(1,3 t) |
| `u_e[7]` | float | bordi cumulati delle fasce, da 0 a 1 (`e[0]=0`, `e[n]=1`, i successivi a 1) | |
| `u_w[6]` | float | peso di ogni fascia (evidenza) | 1; scelta 1,75, altre 0,22 |
| `u_c[6]` | vec3 | colore di ogni fascia (0…1) | |

**Funzioni d'appoggio:** `h21` (rumore da una coppia di numeri), `rot` (rotazione 2D), `sdSeg` (distanza da un segmento),
`sdTri` (distanza con segno da un triangolo).

**`luce(p)`, la luce in un punto, somma di sei parti:**

1. **Il raggio che entra.** Segmento da `S0 = E − dIn·1500` a `S0 + dIn·1500·u_beam` (cresce fino a toccare `E`).
   Intensità `exp(−d²/1,6)·2,2 + exp(−d/7)·0,42 + exp(−d/34)·0,13` (nucleo sottile, alone medio, alone largo), colore
   (1, 0,985, 0,96) × `u_lum`.
2. **Il pulviscolo.** Lungo il raggio, celle di 22 punti che scorrono a 26 punti al secondo; in ogni cella un granello
   spostato di ±17 punti di lato (`h21`), gaussiano (`exp(−(ss²+(pe−jit)²)/1,3)`), che brilla con `0,4 + 0,6·sin(2t + cella)`
   e svanisce lontano dal raggio (`exp(−|pe|/14)`); bianco × 0,9; solo dove il raggio è già arrivato.
3. **Il vetro, tre spicchi come il logo.** Triangolo con gli angoli arrotondati (vertici rientrati di 2·9 punti verso il
   baricentro e distanza −9): maschera `m = 1 − smoothstep(−0,8, 0,8, sd)`. Le tre facce (Q-P0-P1 a sinistra, Q-P0-P2 a
   destra, Q-P1-P2 in basso) hanno luminosità 0,20 / 0,13 / 0,075, tinta (0,80, 0,90, 1). Le tre linee interne da Q ai
   vertici: filo chiaro `exp(−dl/0,9)·0,55` (0,85, 0,93, 1) con un solco scuro −0,06 accanto. Bordo esterno
   `exp(−|sd|/1)·1,25 + exp(−|sd|/7)·0,16` (0,9, 0,95, 1). Luce interna verso i bordi `exp(sd/16)·0,22` (0,75, 0,88, 1).
   Un **riflesso** diagonale (direzione (1, 1,25)) largo 14 punti, intensità 0,38, la cui posizione segue la rotazione
   (`u_rot·260`) e oscilla lenta (`sin(0,27 t)·24 − 30`). Tutto × `u_glass`.
4. **La luce dentro il vetro.** Segmento E→X: il colore va dal bianco (a E) alla media dei colori delle fasce pesata
   sulla loro larghezza ×1,4 (a X); la fascia si allarga (`exp(−di²/(2 + 30·ti))·1,1 + exp(−di/12)·0,25`); solo dentro il
   vetro (`m`) e dopo che il vetro è comparso (`smoothstep(0, 0,2, u_glass)`); × `u_lum`.
5. **Il ventaglio.** Coordinate polari intorno a X: `f = (angolo − aO + 0,25)/0,5` va da 0 a 1 attraverso il ventaglio.
   Lunghezza `Lf = u_len·u_fan`, sfumata fra 0,78·Lf e Lf; solo a destra di X − 40. Bordi del ventaglio sfumati.
   La **separazione** cresce con la distanza (`sep = smoothstep(20, 380, r)`): fra due fasce un filo largo `0,007·sep` e
   una sfumatura che va da 0,07 a 0,0035. Ogni fascia: il suo colore × la sua maschera × `u_w[i]`; fasce più sottili di
   0,0005 saltate. Vicino a X il colore è bianco caldo (1, 0,97, 0,93)·1,05 e diventa il colore delle fasce entro 210
   punti. Trama: `0,94 + 0,06·sin(70 f + 0,4 t)`. Intensità `bordi·lunghezza·trama·(0,42 + 1,05·exp(−r/430))`. Fuori dal
   ventaglio un alone `exp(−fuori·0,5·r/22)·0,12`, colore fra (0,75, 0,8, 1) e quello delle fasce.
6. **Due punti caldi**: a X `exp(−|p−X|/9)·0,9·u_fan` (1, 0,97, 0,92) e a E `exp(−|p−E|/8)·0,7·u_beam` (bianco).

**`main`:**
- fondo: gradiente radiale dal blu (0,10, 0,15, 0,21) al quasi nero (0,022, 0,036, 0,054), centrato al 38% / 32% del
  palco, misurato sull'altezza (raggio 1,05); vignettatura × (1 − 0,35·smoothstep(0,5, 1,3, distanza dal centro));
- sotto il pavimento `Fy`: niente luce diretta, solo **il riflesso** di `luce()` nel punto speculare
  (`2Fy − y`) con un'ondulazione orizzontale `sin(0,08 y + t)·1,2`, attenuato `exp(−(y−Fy)/120)·0,22`; fondo × 0,82; un
  filo d'orizzonte (0,5, 0,6, 0,75)·0,05 largo un punto, che svanisce verso i lati;
- **tonemapping** morbido: `colore = fondo + (1 − exp(−L·1,15))`;
- **grana**: ±0,009 di rumore che cambia a ogni fotogramma (`h21(fragCoord + fract(t)·91)`).

**Colori e luci, riassunto:** bianco caldo del raggio (1, 0,985, 0,96), azzurro del vetro (0,80-0,90, 0,88-0,95, 1),
bianco caldo all'uscita (1, 0,97, 0,93), colori delle fasce dai dati, fondo blu notte. Nessun colore dipende dal tema
chiaro o scuro.

##### 2.2.2-ter Come entra nella pipeline Metal dell'acqua

L'acqua è già fatta così (verificato): sorgente MSL in una stringa (`ShaderAcqua.sorgente`,
`DesignSystem/SfondoAcquaShader.swift`), compilata a runtime con `makeLibrary(source:options:)` fuori dal thread
principale (`ProgrammaAcqua`, `SfondoAcqua.swift:254-310`, perché SwiftPM da riga di comando non compila i `.metal`);
uniform impacchettate in `float4` (`ShaderAcqua.Strato`) e passate con `setFragmentBytes`; un `CAMetalLayer` in una
`NSView` (`TelaAcqua`, 320) mossa da `RendererAcqua` (422) con `CVDisplayLink` e coda di disegno propria
(«prisma.acqua.disegno»), che si ferma con la finestra nascosta, il Mac a riposo e «Riduci movimento», e rallenta in
risparmio energetico; su iOS `SfondoAcquaMobile.swift` con `CADisplayLink`; sotto c'è sempre il fermo-immagine in
SwiftUI (`SfondoAcquaFermo`, 174), che vale anche per le istantanee.

Il prisma di luce segue **lo stesso schema, con file propri** (non si tocca l'acqua):

| File nuovo | Contenuto |
|---|---|
| `DesignSystem/LuceShader.swift` | `enum ShaderLuce` con `sorgente` (MSL) e `Strato` (disposizione delle uniform) |
| `DesignSystem/TelaLuce.swift` | `ProgrammaLuce` (compilazione condivisa, come `ProgrammaAcqua`), `TelaLuce: NSView` con `CAMetalLayer`, `RendererLuce` (battito con `CVDisplayLink` sul Mac, `CADisplayLink` su iOS), `TelaLuceMetal: NSViewRepresentable` / `UIViewRepresentable` |
| `DesignSystem/LuceFermo.swift` | `PrismaDiLuceFermo`: il fermo-immagine in SwiftUI (§2.5) |
| `Shell/SalaLuce.swift` | `PalcoLuce`: la vista del palco (tela + occhiello, totale, segmentato, etichette, pannello, cursore) e lo stato dell'animazione |
| `Motori/MotoreLuce.swift` | le fasce per vista e per anno (§2.5) |

**Traduzione GLSL → MSL** (punti da non sbagliare):
- vertex: lo stesso triangolo grande dell'acqua (`vs_luce`, tre vertici (−1,−1), (3,−1), (−1,3)); fragment `fs_luce`
  con `float4 pos [[position]]`;
- **l'origine di `[[position]]` in Metal è già in alto a sinistra**: `p = pos.xy / d` (niente `u_res.y − y` come in WebGL);
- `atan(y, x)` → `atan2(y, x)`; `fract`, `mix`, `smoothstep`, `clamp`, `step`, `exp`, `normalize` uguali; `vec2/3` →
  `float2/3`; `const float` → `constant float`;
- i cicli con `break` su `u_n` restano (al massimo 6 giri);
- uniform in un'unica struct di `float4` come `ShaderAcqua.Uniformi`, senza riempimenti:

```
struct UniformiLuce {          // proposta di ShaderLuce.Strato, in float
  float4 tela;    // 0:  larghezza px, altezza px, punti per pixel, tempo
  float4 cristallo; // 4: C.x, C.y, R, rotazione
  float4 fasi;    // 8:  beam, glass, fan, lunghezza
  float4 varie;   // 12: n, lum, -, -
  float4 bordi[2];  // 16: e[0..6] (8 posti, l'ottavo = 1)
  float4 pesi[2];   // 24: w[0..5]
  float4 colori[6]; // 32: c[i].rgb, -
};                  // totale 56 float = 224 byte → setFragmentBytes
```
- formato del colore `.bgra8Unorm` come l'acqua (non `_srgb`): i colori delle fasce si passano come nel template, cioè
  i valori sRGB 0…1 così come sono (`rgb()`, 1434), senza linearizzarli, e il tonemapping lavora su quei valori; con un
  formato `_srgb` la scena verrebbe più chiara e slavata. La tela è **opaca** (lo shader disegna anche il fondo);
- la grana usa il tempo: nelle istantanee e con «Riduci movimento» il tempo è fisso, quindi la grana è ferma.

**Battito e risparmio:**
- 30 fotogrammi al secondo come l'acqua (20 in risparmio energetico); proposta: **60 durante il trascinamento del
  cristallo e nelle transizioni** (apertura, cambio di vista), poi di nuovo 30. Da confermare (D6).
- La tela si ferma (e tiene l'ultima immagine) quando il palco non si vede: altra esperienza aperta, finestra di Prisma
  nascosta o coperta, Mac a riposo, schermata di blocco; con «Riduci movimento» si disegna **un solo fotogramma** a ogni
  cambio (dati, vista, anno, scelta del raggio, rotazione a mano).
- Memoria: la tela è grande quanto il palco (circa 1384×600 punti) × 1,6 → circa 2200×960 pixel, tre drawable ≈ 25 MB.
  Sul Mac da 8 GB va bene, ma la tela si **distrugge** quando si esce dall'esperienza (non resta in memoria nascosta).
- L'acqua della scrivania continua sotto la finestra (regola di CLAUDE.md): due tele Metal insieme. Da misurare con
  `MisuratoreFluidita` e `--prova-fluidita`.

**Le etichette, il pannello, il totale e il segmentato non sono nello shader**: sono viste SwiftUI sopra la tela. Le
posizioni delle etichette le calcola Swift con la stessa geometria (punto X ruotato, angolo `aO − 0,25 + metà fascia ·
0,5`, distanza lunghezza·fan + 16, poi 4 giri di separazione verticale a 44, `ESPM.luce` 1545-1547).

#### 2.2.3 Movimento

Tempi dell'apertura (`ESPM.luce`, 1540-1549; `T` = secondi dall'apertura; `eio` = cubica dentro-fuori):

| Cosa | Template | In Prisma (`Tema.Apple.Moto.Luce`, nuovo) |
|---|---|---|
| Raggio che entra (`u_beam`) | 0 → 1,1 s, eio | `raggio = Fase(inizio: 0, durata: 1.1)`, curva **nuova** `Moto.Curva.dentroFuoriCubica ≈ (0.65, 0, 0.35, 1)` |
| Vetro che appare (`u_glass`) | 0,7 → 1,6 s, eio | `vetro = Fase(inizio: 0.7, durata: 0.9)` |
| Ventaglio che si apre (`u_fan`) | 1,15 → 2,45 s, eio | `ventaglio = Fase(inizio: 1.15, durata: 1.3)` |
| Totale che si conta | da 0 al valore di oggi in 1,6 s, dopo 0,5 s (`conta`, 1544) | `NumeroCheConta` con `totaleRitardo 0.5`, `totaleDurata 1.6` |
| Etichette | quando il ventaglio è oltre 0,95: 600 ms ciascuna, da x −10, ritardo i·90 ms, (.22,1,.36,1) | `etichette = Cascata(durata 0.6, passo 0.09, spostamento 10)`, `Moto.Curva.uscita` |
| Oscillazione a riposo | rotazione obiettivo → sin(0,22 t)·0,035, inseguita con smorzamento 0,6/s | `oscillazione (ampiezza 0.035, pulsazione 0.22, inseguimento 0.6)` |
| Rotazione | segue l'obiettivo con smorzamento esponenziale 7/s | `inseguimentoRotazione 7` |
| Trascinamento | 520 punti di trascinamento = 1 rad, limitato a ±0,22 | `puntiPerRadiante 520`, `rotazioneMassima 0.22` |
| Raggio scelto | pesi verso 1,75 / 0,22 con smorzamento 7/s; etichette delle altre a opacità 0,22 in 0,35 s | `evidenza (scelto 1.75, altri 0.22, inseguimento 7, durataEtichette 0.35)` |
| Cambio di vista | bordi e colori interpolati in 850 ms, eio; etichette spente, ricostruite dopo 650 ms con cascata 500 ms, passo 70 ms, da x −8 | `cambioVista (durata 0.85, ritardoEtichette 0.65, durataEtichette 0.5, passo 0.07, spostamento 8)` |
| Cambio d'anno | totale contato in 500 ms; lunghezza del ventaglio subito | `NumeroCheConta` con `Moto.NumeroCambio` (0,90) → **da 0,5** se si vuole come il template |
| Respiro | `u_lum = 0,9 + 0,1·sin(1,3 t)` | `respiro (base 0.9, ampiezza 0.1, pulsazione 1.3)` |
| Pulviscolo | 26 punti/s | `polvere 26` |

Tutte le inseguite «esponenziali» (`x += (obiettivo − x)·(1 − e^(−dt·k))`) si calcolano nel renderer a ogni battito con
il `dt` vero dell'orologio dello schermo (come fa l'acqua): **non sono Timer**. Le animazioni delle viste SwiftUI
(etichette, numeri, pannello) usano le animazioni di SwiftUI.

- **Riduci movimento** (`\.prismaCalmo`): tutto compare **già fermo**, con la dissolvenza di 0,15 s: raggio, vetro e
  ventaglio completi, nessuna oscillazione, pulviscolo e respiro fermi, grana ferma, etichette e totale già al loro
  posto. Il cambio di vista è una dissolvenza di 0,15 s; il raggio scelto si accende subito. Il trascinamento continua a
  ruotare il cristallo (è un gesto, non un'animazione). Nel template `ridotto` porta solo `T = 99` (1541) e lascia
  muoversi pulviscolo e respiro: vale la regola di Prisma.
- **Istantanee** (`\.modoIstantanea`, `\.prismaStatoFinale`): fermo-immagine nello stato finale (raggio, vetro e ventaglio
  completi, rotazione 0, etichette e totale completi). Niente Metal (i runner Intel di GitHub non hanno una GPU utile e
  l'acqua fa già così).

#### 2.2.4 Interazioni

Mac:
- **Puntatore sul ventaglio** (`onpointermove`, 1533-1534): se il punto è fra 70 punti da X e la lunghezza del ventaglio
  + 60 e dentro l'apertura, la fascia sotto il puntatore diventa la scelta (pesi, etichette, pannello). Uscendo dalla tela
  la scelta si toglie (1535). In SwiftUI: `onContinuousHover` (macOS 13) sulla tela, con la stessa geometria in Swift.
- **Trascinamento** del cristallo (ovunque sulla tela, cursore «mano» / «mano chiusa»): ruota il cristallo, e con lui la
  direzione del ventaglio. `DragGesture` + `NSCursor.openHand/closedHand`.
- **Segmentato** «Per investimento / Per obiettivo / Per canale»: cambio di vista (§2.3). Nella vista «Per canale» le
  etichette portano anche l'etichetta del canale (`EtichettaCanaleApple`, versione compatta sul fondo notte): il canale
  resta riconoscibile per parola, non solo per colore.
- **Cursore degli anni** (2026-2046): totale, cifre delle etichette e del pannello, e lunghezza del ventaglio passano
  all'anno scelto; l'occhiello accanto al totale dice «nel 2034».
- **Clic su un raggio** (non nel template, proposta): tiene ferma la scelta (per parlarne con il cliente) finché non si
  clicca altrove; con il tasto Esc si toglie.
- **Tastiera** (proposta): frecce su/giù scorrono le fasce, sinistra/destra gli anni; VoiceOver legge le fasce come un
  elenco «Azionario, 38%, 77.539 €».
- **«▣ Mostra sul tavolo»** (palco): manda all'iPad del tavolo la stessa scena (§2.5, punto 5). Sull'iPad il cliente può
  ruotare il cristallo con il dito e scegliere un raggio toccandolo; gli anni e la vista li sceglie il Mac.
- **«✦ Aggiungi al Prisma di Giulia»** (palco): mette nel Prisma del cliente un'immagine del prisma di luce nello stato
  attuale (vista e anno), vedi §1.5 e D5.

iPhone e iPad: oltre al tavolo, il template non lo prevede. Proposta: sull'iPad nella vista del tavolo (stesso shader,
stesso `RendererLuce` con `CADisplayLink`); sull'iPhone no.

#### 2.2.5 Mappa verso Prisma

**Esiste già (verificato):**
- Composizione per classe e per canale: `ComposizioneInvestimenti360` (`Motori/MotoreAree360.swift:36`), con le **stesse
  quattro classi del template** (`azionario`, `obbligazionario`, `gestioneSeparata`, `liquidita`), i loro nomi, `valore` e
  `quota` di ogni `Pezzo`, `perCanale: [Canale: Double]` per pezzo e in totale, `totale`, `stimata` (composizione stimata
  dalla tipologia o dall'SRI). Si calcola con `MotoreAree360.composizione(_:cliente:)` (riga 208).
- Obiettivi: `Obiettivo` con `area`, `MotoreObiettivo.calcola` → `EsitoObiettivo.disponibileOggi` (già da parte oggi:
  accantonato e posizioni collegate) — è la misura giusta del raggio «per obiettivo».
- Patrimonio negli anni: `MotoreLineaVita.prepara` / `calcola` (punti annui in euro di oggi); `MotorePatrimonio.calcola` /
  `serie` (`Motori/MotorePatrimonio.swift:41,77`) per le posizioni.
- Canale: `enum Canale` (`Dati/Modelli.swift:4`), colori `Colore.canaleAlleanza` / `canaleIndipendente` (con le varianti
  scure #6B95FF / #D0954A), `EtichettaCanaleApple`.
- Pipeline Metal dell'acqua (§2.2-ter), `NumeroCheConta`, `SegmentatoPillola`, `CursoreApple`, `Moto.Curva.uscita`.
- Tavolo con l'iPad: `MostraTavolo.Genere` (`Tavolo/ProtocolloTavolo.swift:188-199`: `pagina`, `prospetto`, `nelTempo`,
  `famiglia`, `lineaVita`), cifrato, solo cifre del cliente presente.

**Cosa manca:**
1. **`MotoreLuce`** (`Motori/MotoreLuce.swift`), puro, con `ProvaCalcoliLuce`:
   - `fasce(vista:cliente:posizioni:obiettivi:) -> [FasciaLuce]` (`nome`, `valore`, `quota`, `colore`, `canale?`), al
     massimo 6, quote che sommano a 1;
   - **per investimento**: i pezzi di `ComposizioneInvestimenti360` con valore > 0, nell'ordine delle classi; se
     `stimata`, una nota nel pannello «Composizione in parte stimata»;
   - **per obiettivo**: `disponibileOggi` di ogni obiettivo (fino a 5; se sono di più, i più piccoli si uniscono in «Altri
     obiettivi»), più «Liquidità e altro» = totale − somma degli obiettivi, **senza il minimo del 20% del template**; se la
     somma degli obiettivi supera il totale (posizioni contate su più obiettivi), le quote si riportano al totale degli
     obiettivi e il pannello lo dice;
   - **per canale**: `perCanale` della composizione, mai una quota fissa;
   - `totale(anno:)`: oggi `ComposizioneInvestimenti360.totale`; negli anni il patrimonio di `MotoreLineaVita.calcola`
     all'età corrispondente. **La ripartizione negli anni resta quella di oggi** (il motore della linea della vita dà solo
     il totale): il pannello lo dice («ripartizione di oggi») — vedi D2;
   - `massimo` sui 20 anni per la lunghezza del ventaglio.
2. **`ShaderLuce`, `ProgrammaLuce`, `TelaLuce`, `RendererLuce`** (§2.2-ter), con il ripiego `PrismaDiLuceFermo`.
3. **`PrismaDiLuceFermo`** (SwiftUI, niente Metal e niente `Canvas` come `SfondoAcquaFermo`): fondo con
   `RadialGradient`, raggio d'entrata (rettangolo sottile con `blur`), triangolo arrotondato con tre `Path` per le facce
   (opacità 0,20 / 0,13 / 0,075) e bordi chiari, ventaglio come sei spicchi `Path` con `LinearGradient` dal bianco al
   colore e `blur(2)`, riflesso capovolto a opacità 0,22. Usato nelle istantanee, senza Metal e come immagine per «Aggiungi
   al Prisma» (con `ImageRenderer`, macOS 13). Attenzione: sul server le istantanee si disegnano con `cacheDisplay`
   in una finestra fuori schermo (metodo «finestra», `Istantanee.swift:1603-1606`, «I PNG non catturano i materiali di
   sistema»): i filtri di livello come `blur` possono non uscire. Gli aloni del fermo-immagine vanno quindi fatti con
   gradienti (`RadialGradient`/`LinearGradient` che sfumano a trasparente), e il `blur` usato solo come rifinitura;
   controllare la prima PNG sul branch `anteprime`.
4. **`PalcoLuce`** (`Shell/SalaLuce.swift`) e lo stato `StatoLuce` (vista, anno, fascia scelta, rotazione).
5. **Tavolo**: `MostraTavolo.Genere.luce` e un contenuto `LuceTavolo` (titolo, nome del cliente, fasce con nome, quota,
   colore, valore; totale; anno), versione dei messaggi invariata: un contenuto che l'iPad non conosce si ignora senza
   chiudere il tavolo (`ProtocolloTavolo.swift:28` e 135: `contenuto` decodificato con `try?` resta nil, provato in
   `Tavolo/ProvaTavolo.swift:58`). Vista `LuceTavoloiPad` in `iOS/SchermiTavoloiPad.swift`. Da riconciliare con la parte
   comune (`01-comune.md` §5), che per «Mostra sul tavolo» propone come minimo un'**immagine del palco** (genere
   `pagina`, nessun cambio di protocollo) e, se servono dati, un solo genere `esperienzaSala`: la scena viva e girabile col
   dito di questa sezione chiede i dati (genere proprio o caso di `esperienzaSala`); l'immagine ferma no. Proposta: prima
   l'immagine, la scena viva sull'iPad dopo (decisione D7).
6. **Gettoni** `Tema.Apple.Luce` e `Moto.Luce` (§2.2, §2.3).

#### 2.2.6 Dati che l'utente deve dare e stati vuoti

| Caso | Cosa si vede |
|---|---|
| Nessuna posizione finanziaria in essere (`ComposizioneInvestimenti360.vuota`) | Palco notte con il cristallo spento (solo vetro, niente raggio) e al centro: «Giulia non ha ancora posizioni in essere: il prisma si accende con il suo patrimonio › Aggiungi una posizione». |
| Composizione stimata | Fasce disegnate, nota nel pannello: «Composizione in parte stimata dalla tipologia dei prodotti». |
| Vista «per obiettivo» senza obiettivi | Segmento disattivo con il fumetto «Nessun obiettivo nel dossier». |
| Vista «per canale» con un canale solo | Un solo raggio, pieno: va bene così (è un'informazione). |
| Senza data di nascita (niente `MotoreLineaVita`) | Il cursore degli anni non c'è; al suo posto «Per vedere il patrimonio negli anni serve la data di nascita › Completa l'anagrafica». |
| Più di 20 anni oltre i 90 | Il cursore si ferma all'anno dei 90 anni del cliente. |
| Metal non disponibile o shader non compilato | `PrismaDiLuceFermo` con le stesse viste sopra (etichette, pannello): l'esperienza funziona, solo senza movimento. |

Nessun dato nuovo da chiedere: tutto viene da posizioni, obiettivi e anagrafica che ci sono già.

#### 2.2.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `624-sala-luce` (+ `-scuro`) | Giulia, per investimento, oggi, stato finale |
| `625-sala-luce-obiettivi` | Giulia, per obiettivo |
| `626-sala-luce-canale` | un cliente con tutti e due i canali, per canale (con le etichette del canale) |
| `627-sala-luce-raggio-scelto` | Azionario scelto: pannello con la cifra, altre etichette attenuate |
| `628-sala-luce-fra-vent-anni` | anno all'estremo destro del cursore |
| `629-sala-luce-vuota` | cliente senza posizioni in essere |

Tutte con `PrismaDiLuceFermo`. iOS (tavolo): `74-tavolo-luce` (iPad, numero libero nelle istantanee iOS, oggi fino a 53
nella serie bassa). Aggiungere il fermo-immagine alla vetrina «400-vetrina-apple».

#### 2.2.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole toccate: grafica (tema Apple, valori in DesignSystem, movimento e «Riduci movimento», istantanee nello stato
finale, niente Timer), memoria del Mac da 8 GB, canale sempre riconoscibile, Metal fuori dal thread principale. **Nessun
dato esce dal Mac** (il tavolo usa la rete locale cifrata che c'è già). Nessuna dipendenza esterna. Nessuna API sopra
macOS 13 (`CAMetalLayer`, `CVDisplayLink`, `onContinuousHover`, `ImageRenderer` sono tutte di macOS 13 o prima).

Decisioni:
1. **D1 · Patrimonio o patrimonio finanziario.** Il template scrive «IL PATRIMONIO DI …» con il patrimonio netto, ma i
   raggi sono le classi d'investimento. In Prisma il totale coerente con i raggi è quello finanziario (posizioni in
   essere, `ComposizioneInvestimenti360.totale`). Proposta: «IL PATRIMONIO FINANZIARIO DI …».
2. **D2 · Ripartizione negli anni.** Il motore della linea della vita dà il totale, non le classi. Proposta: totale
   proiettato con la ripartizione di oggi, dichiarata nel pannello; in alternativa proiettare ogni posizione con
   `MotorePatrimonio.andamento` e la sua composizione (più lavoro, più vero). Coerenza del punto di partenza: nel
   template il totale «oggi» è il primo punto della proiezione (`out[0]`, 1536), mentre la colonna dell'AR parte dal
   patrimonio netto (`c.pn`, 1625): due fonti diverse. In Prisma «oggi» deve essere **lo stesso numero** nelle due
   fonti: `ComposizioneInvestimenti360.totale` e il primo punto di `MotoreLineaVita` filtrano le stesse posizioni
   (`MotoreAree360.swift:210`, `MotoreLineaVita.swift:167-168`), ma il secondo passa da `MotorePatrimonio.calcola`;
   `ProvaCalcoliLuce` controlla che coincidano (o il motore riporta la serie al totale di oggi).
3. **D3 · Colori dei canali sul fondo notte.** Il template usa #4F7DFF / #E3A04A, che non sono i colori dei canali. Proposta:
   le varianti scure già nel tema (#6B95FF / #D0954A) più l'etichetta del canale a parole.
4. **D4 · Colori delle classi.** Il template usa una tavolozza più chiara di `Colore.Composizione`. Proposta: tenerla come
   `Tema.Apple.Luce.Raggi` (solo per il fondo notte), perché quelli del tema (#2563EB per la gestione separata, #9FB3C2 per
   la liquidità) sul nero si leggono male. La realtà aumentata (§3) usa la stessa tavolozza del template.
5. **D5 · Cosa entra nel Prisma del cliente.** Un'immagine ferma (proposta) o la scena viva in WebGL dentro il file HTML
   (lo shader del template è già WebGL: si potrebbe riusare, ma il file diventa più complesso e su iPhone vale il dubbio
   del §1.8 D2).
6. **D6 · Fotogrammi.** 30 al secondo come l'acqua, 60 solo durante trascinamenti e transizioni (proposta).
7. **D7 · Sul tavolo: immagine o scena viva.** L'immagine ferma del palco (genere `pagina` che esiste già, nessun
   protocollo nuovo) oppure la scena viva sull'iPad con i dati delle fasce (genere nuovo, il cliente gira il cristallo
   col dito). In tutti e due i casi escono verso l'iPad solo le cifre del cliente presente, sulla rete locale cifrata.
   Proposta: l'immagine per prima.

---

### 2.3 La realtà aumentata

*Novità 15 di 15 «davanti al cliente» · voce `NOV15[14]` · `FS_AR` (1553-1615), `ESPH.ar` (1617-1627), `ESPM.ar`
(1628-1650); CSS 265-280*

Sull'iPad (o sull'iPhone) del consulente, con la fotocamera, il patrimonio del cliente diventa un **cristallo di vetro a
strati** posato sul tavolo vero: ogni strato è una classe d'investimento, l'altezza è il patrimonio, gli anni lo fanno
crescere, «Esploso» separa gli strati. Ci si gira intorno. Sul Mac il palco mostra un'**anteprima simulata** su un tavolo
di legno disegnato.

#### 2.3.1 Cosa si vede

**Nel palco del Mac** (`sala-ar-chiaro.png`, `sala-ar-esploso.png`; in scuro `sala-ar-scuro.png`):

- fondo del palco: gradiente radiale 900×600 al 40%/40% da #EEF2F5 a #D9E1E7 (chiaro **anche** con Prisma scuro);
- a sinistra la **cornice di un iPad** (`.ipad`, 265-267): a (28, 22), 944×560, raggio 42, gradiente a 145° da #2A2D31 a
  #0B0C0E (40%), padding 15, ombra 0 50 90 −30 rgba(8,30,50,.55) e filo interno bianco a 0,08; la fotocamera frontale è un
  puntino da 5 sul lato sinistro; schermo con raggio 28 e fondo nero. Dentro lo schermo:
  - la **scena** (shader `FS_AR`, §3.2-bis): una stanza calda sfocata con luci a bolle, un **tavolo di legno**, e sopra il
    **cristallo** di quattro strati triangolari di vetro colorato (azzurro, celeste, lilla, verde dal basso in alto), con il
    **logo inciso** sulla faccia alta; l'ombra sul tavolo è colorata dalla luce che attraversa gli strati;
  - in alto a sinistra la pillola «◉ Prisma · AR», a destra la pillola di stato «Cerco una superficie…» → «✓ Tavolo
    trovato» (`.arTop`, `.arPill`: fondo nero a 0,38, sfocatura 16 saturazione 1,4, bianco, 12,5 pt 600, padding 7/13);
  - al centro, all'inizio, la **guida** (`.arCoach`, `.arCq`): due quadrati arrotondati da 64 (bordo 3 bianco, raggio 16)
    che ruotano in prospettiva e la frase «Muovi l'iPad per trovare il tavolo» (15 pt, 600, 14 sotto);
  - sopra il cristallo la **targhetta** (`.arTag`): fondo bianco a 0,8 sfocato 14, raggio 14, padding 9/14, ombra; cifra
    «204.050 €» (display 19, −0,4, tabellari) e «Giulia · 2026» (11,5 pt, #5A6873); sotto, un'asta bianca di 1,5×14 che
    scende verso il cristallo;
  - con «Esploso», accanto a ogni strato una **pillola** (`.arStr`): fondo bianco a 0,82 sfocato 12, pallino 9 del colore
    dello strato, nome in grassetto e valore (12 pt, valore in #5A6873, tabellari);
  - in basso al centro la **barra** (`.arBar`, fondo nero a 0,38 sfocato 18, a 16 dal fondo, padding 8/10/8/18, spazio 14):
    l'anno (12 pt, opacità 0,75, largo 42), il cursore degli anni largo 220 (da oggi all'anno della pensione), il
    pulsante «Esploso» (`.arTog`: 12,5 pt 600, padding 7/13, fondo bianco a 0,14; acceso: fondo bianco e testo #14202B),
    e lo **scatto** (`.arShut`: cerchio bianco da 42 con un anello scuro di 3 e uno bianco di 5).
- a destra (da x 1000 al bordo meno 30), una colonna di spiegazione:
  - `.lbl` «SUL TAVOLO, DAVANTI A GIULIA»;
  - titolo «Il patrimonio diventa un cristallo che si può guardare da ogni lato.» (display 28, 700, −0,6, interlinea
    1,15);
  - testo (14 pt, interlinea 1,55): «Ogni strato di vetro è un tipo di investimento. Fai scorrere gli anni e il
    cristallo cresce; «Esploso» separa gli strati e mostra quanto vale ciascuno. La luce che li attraversa colora il
    tavolo.»;
  - tile «Patrimonio nel 2026» con la cifra (`.v` a 30 pt), contata quando cambia l'anno;
  - le quattro classi in righe (13,5 pt, padding 7/0, filo `--sep`): quadratino 12×12 raggio 4 del colore, nome,
    percentuale in grassetto;
  - in fondo, `.k`: «Anteprima simulata. Sull'iPad e sull'iPhone veri il cristallo si posa sul tavolo con la fotocamera,
    e si guarda girandoci intorno.»
- In testa al palco: «▣ Mostra sul tavolo» (§3.4).

**Sull'iPad e sull'iPhone veri** (descritto dal testo del template, non disegnato): la stessa interfaccia dello schermo
dell'iPad del palco (pillole, guida, targhetta, pillole degli strati, barra), ma al posto della stanza e del tavolo
disegnati c'è **l'immagine della fotocamera**, e il cristallo è ancorato al piano del tavolo vero.

**Stati:**

| Stato | Cosa si vede |
|---|---|
| Ricerca del piano | Guida al centro, pillola «Cerco una superficie…», puntini bianchi sul piano trovato. |
| Tavolo trovato | La guida svanisce, pillola «✓ Tavolo trovato»; i puntini restano ancora un attimo. |
| Posa | Un anello bianco si allarga sul tavolo e svanisce; il cristallo cresce dal tavolo con un piccolo rimbalzo. |
| Cristallo | Targhetta con il valore; rotazione lenta automatica (solo anteprima, §3.3). |
| Esploso | Strati separati, pillole con nomi e valori. |
| Scatto | Lampo bianco, avviso «Foto salvata nel dossier di Giulia Rossi». |
| AR non disponibile (simulatore, dispositivo senza AR, fotocamera negata) | Ripiego: la scena con il tavolo virtuale, come l'anteprima (§3.5). |

#### 2.3.2 Misure e stile

**Gettoni nuovi, `Tema.Apple.RealtaAumentata`** (`DesignSystem/Apple/Tema.Apple+RealtaAumentata.swift`):

| Gettone | Valore |
|---|---|
| `fondoPalco` | gradiente radiale #EEF2F5 → #D9E1E7, 900×600 al 40%/40% |
| `CorniceiPad.dimensione` / `raggio` / `margine` / `raggioSchermo` | 944×560 / 42 / 15 / 28 |
| `CorniceiPad.fondo` | gradiente 145° #2A2D31 → #0B0C0E al 40% |
| `CorniceiPad.ombra` | 0 50 90 −30 rgba(8,30,50,.55) + filo interno bianco 0,08 |
| `Pillola.superficie` | nero 0,38 (rgba(20,20,22,.38)), sfocatura 16, saturazione 1,4; testo bianco 12,5/600, padding 7/13 |
| `Barra.superficie` | come la pillola, sfocatura 18; distanza dal fondo 16; padding 8/10/8/18; spazio 14 |
| `Barra.larghezzaCursore` | 220; binario bianco 0,3 |
| `Interruttore` («Esploso») | spento: bianco 0,14; acceso: bianco con testo #14202B |
| `Scatto` | 42, bianco, anello 3 nero 0,4 + anello 5 bianco 0,85; premuto scala 0,9 |
| `Targhetta` | bianco 0,8, sfocatura 14, raggio 14, padding 9/14, ombra 0 10 24 −10 rgba(0,0,0,.35); cifra display 19 −0,4; nome 11,5 #5A6873; asta 1,5×14 bianco 0,85; distanza minima dal bordo alto 96 |
| `Strato` (pillola) | bianco 0,82, sfocatura 12, padding 6/11, pallino 9, 12 pt, valore #5A6873; scostamento (18, −12) dal punto dello strato |
| `Guida` | due quadrati 64, bordo 3, raggio 16; testo 15/600 con ombra 0 1 8 nero 0,4 |
| `Colonna` | titolo display 28/700/−0,6/1,15; testo 14/1,55; quadratino 12 raggio 4 |
| `Strati.colori` | #3B82F6, #5AC8FA, #A78BFA, #34D399 (= `Tema.Apple.Luce.Raggi.investimento`) |

I colori delle quattro classi sono gli stessi del prisma di luce (D4 del §2.8).

##### 2.3.2-bis Lo shader `FS_AR`, in dettaglio (1553-1615)

È un **ray marcher** a schermo intero: disegna stanza, tavolo e cristallo calcolando per ogni pixel il raggio della
camera. Nell'app **non va portato com'è** (RealityKit disegna da sé il modello 3D e l'immagine della fotocamera): è la
**specifica della resa** del cristallo, dei materiali e della luce.

**Uniform:**

| Uniform | Significato | Valori nel template |
|---|---|---|
| `u_res` | risoluzione (pixel) | tela × 1,25 al massimo |
| `u_D`, `u_ty` | distanza della camera e altezza del punto guardato | D = 2,9 + 0,75 H + 1,6 esploso; ty = 0,3 + 0,42 H + 0,42 esploso |
| `u_az`, `u_el` | azimut ed elevazione della camera (rad) | az da −1,25; el 0,42 (0,18…0,85) |
| `u_t` | tempo | |
| `u_H` | altezza del cristallo (unità) | 0,85 + 1,35 × patrimonio dell'anno / massimo fino alla pensione |
| `u_grow` | crescita (scala del cristallo) | 0→1 con rimbalzo |
| `u_expl` | esploso | 0→1 |
| `u_plane` | puntini del riconoscimento del piano | 0→1→0 |
| `u_ring` | anello di posa | 0→1 |
| `u_flash` | lampo dello scatto | 1 → 0 |
| `u_sel` | strato in evidenza (−1 nessuno) | sempre −1 nel template |
| `u_y[5]` | bordi cumulati degli strati (0…1) | dall'allocazione |
| `u_c[4]` | colori degli strati | §3.2 |

**Geometria** (`mapT`, 1563-1568): un **prisma triangolare equilatero** a spigoli arrotondati (funzione `sdEqTri` con
raggio `RT = 0,42`, arrotondamento 0,05 in pianta e 0,012 sugli spigoli), con il vertice rivolto verso −z, diviso in
**quattro strati** in altezza: lo strato i va da `y[i]·H` a `y[i+1]·H` (0,008 di fessura sopra e sotto). Esploso: ogni
strato sale di `0,2·i`. Il tutto scalato da `u_grow` intorno alla base. L'ordine dal basso: Azionario, Obbligazionario,
Gestione separata, Liquidità (l'ordine di `alloc`).

**Vetro** (main, 1600-1608):
- Fresnel `0,04 + 0,96·(1 − cos)^5` (Schlick, indice 1,5);
- riflesso dell'**ambiente** (`ambiente`, 1572): pavimento caldo (0,30, 0,27, 0,24) → cielo (0,95, 0,93, 0,9), due
  softbox (una forte verso (−0,4, 0,8, 0,5), una più debole verso (0,7, 0,55, −0,3));
- **rifrazione** (`refract`, 1/1,5): dietro il vetro si vede il legno (0,62, 0,50, 0,38) o la stanza leggermente spostata;
- corpo = (dietro·0,72 + 0,30) × mix(bianco, colore dello strato, 0,58) × (0,84 + 0,3 × altezza relativa): più chiaro in
  alto; la faccia superiore (normale y > 0,9) schiarita verso (0,96, 0,97, 0,98) al 45%;
- speculare `pow(·,110)·1,6` dalla luce `LD = (−0,4566, 0,7887, 0,3487)`; bordo luminoso `pow(1 − |cos|, 2,4)·0,55`
  colorato; leggere fasce verticali sulle facce (0,12);
- **il logo inciso** sulla faccia alta dello strato più alto (id 3): tre linee bianche dal punto (0, −0,06) ai tre vertici
  del triangolo, `exp(−d/0,006)·0,55`. Nel template il logo sta sempre sull'id 3 (Liquidità): se quella classe è a zero
  lo strato non c'è (salto `y1−y0 < 0,002`, 1565) e il logo sparisce. In Prisma il logo va sulla faccia alta dell'**ultimo
  strato presente**, qualunque sia.

**Tavolo** (`tavolo`, 1580-1589): piano y = 0 grande 5,2×3,1 unità, legno procedurale (`legno` con `fbm`, venature lungo x,
colori (0,50, 0,37, 0,25) → (0,68, 0,53, 0,37)); **ombra morbida** verso `LD` (`ombra`, 36 passi) **colorata** dallo strato
che la proietta (`mix(colore·1,35, bianco, ombra)`): «la luce che li attraversa colora il tavolo»; scurimento di contatto
intorno alla base; riflesso Fresnel dell'ambiente sul legno (0,55); bordo del tavolo chiaro; il tavolo sfuma nella stanza
con la distanza. **Puntini del piano**: griglia di 0,11 unità, punti bianchi entro 1,4 unità dal centro, × `u_plane`.
**Anello di posa**: cerchio bianco sottile di raggio `1,3·u_ring` che svanisce mentre si allarga.

**Stanza** (`sfondo`, 1574): grigio caldo (0,66, 0,64, 0,60) → (0,90, 0,89, 0,86) verso l'alto, una finestra luminosa in
alto a sinistra, 7 luci sfocate a bolla. **Finale**: lampo `mix(col, bianco, u_flash)`, vignettatura `1 − 0,28·|v|²·1,6`,
gamma 0,95, grana ±0,011.

**Camera** (main, 1590-1592): orbita intorno a (0, ty, 0) a distanza D, con un piccolo tremolio «a mano»
(az + sin(1,3 t)·0,004 + sin(2,3 t)·0,0025, el + sin(1,7 t)·0,003), focale 1,6.

##### 2.3.2-ter Dallo shader a RealityKit

| Nel template | In RealityKit (iPhone e iPad) |
|---|---|
| Stanza e tavolo disegnati | L'immagine della fotocamera (`ARView`, `cameraMode = .ar`) e il piano orizzontale vero (`ARWorldTrackingConfiguration`, `planeDetection = [.horizontal]`, `AnchorEntity(plane: .horizontal, minimumBounds: [0.3, 0.3])`) |
| Prisma a strati (`mapT`) | Quattro `ModelEntity` con una mesh di prisma triangolare a spigoli smussati generata in Swift (`MeshDescriptor` con posizioni, normali e triangoli: base triangolare con angoli arrotondati estrusa; `MeshResource.generate(from:)`), una per strato, figlie di un'entità «cristallo» |
| Vetro (Fresnel, riflesso, rifrazione, tinta) | `PhysicallyBasedMaterial`: `baseColor` = colore dello strato schiarito (mix 0,58 verso il bianco), `roughness` 0,05, `metallic` 0, `clearcoat` 1 con `clearcoatRoughness` 0,02, `blending = .transparent(opacity: 0,55-0,7)`, `faceCulling = .none` per vedere le facce interne. RealityKit **non fa la vera rifrazione**: l'effetto «vetro» viene da trasparenza, clearcoat e riflessi dell'ambiente (`environmentTexturing = .automatic` della sessione AR, che illumina con la stanza vera) |
| Faccia alta più chiara, bordi luminosi | Seconda mesh sottile sulla faccia alta con materiale più chiaro; gli spigoli smussati prendono da sé il riflesso |
| Logo inciso | Una texture con il logo (generata da `LogoPrisma` con `ImageRenderer`) come `UnlitMaterial` con trasparenza su un piano a 0,5 mm sopra la faccia alta dello strato più alto |
| Ombra colorata sul tavolo | Un piano sotto il cristallo con un'**ombra dipinta** (texture generata in Swift: la pianta del triangolo sfumata, divisa nei colori degli strati, spostata nella direzione della luce), `UnlitMaterial` trasparente; si aggiorna quando cambiano anno ed esploso. In più l'ombra grigia di RealityKit (`ARView.renderOptions` senza `.disableGroundingShadows`) |
| Puntini del piano e anello di posa | Entità proprie sul piano (griglia di dischi bianchi; anello come mesh piatta con opacità animata) |
| Tremolio della camera, orbita automatica | Non servono: la camera è l'iPad in mano |
| Lampo, vignettatura, grana | Lampo in SwiftUI sopra la vista; niente vignettatura né grana sull'immagine vera |
| Etichette (targhetta, pillole degli strati) | Viste SwiftUI sopra l'`ARView`, posizionate a ogni fotogramma con `arView.project(_:)` del punto 3D (iscrizione a `SceneEvents.Update`, non un Timer) |

**Misure reali proposte** (il template è in unità astratte): 1 unità = **0,16 m** (`Tema.Apple.RealtaAumentata.metriPerUnita`):
lato del triangolo ≈ 0,84 unità → 13 cm; altezza da 0,85 a 2,2 unità → da 14 a 35 cm. Da provare su un tavolo vero (D5).

**Requisiti:**
- iOS 17 (minimo del pacchetto: `Package.swift`, `.iOS(.v17)`): `ARView` (RealityKit, iOS 13), `PhysicallyBasedMaterial`
  (iOS 15), `MeshDescriptor` (iOS 15), `ARWorldTrackingConfiguration.isSupported`. **`RealityView` (iOS 18) non si usa**,
  così non serve proteggere nulla: si usa `ARView` dentro `UIViewRepresentable`.
- Fotocamera: chiave `NSCameraUsageDescription` già presente in `Supporto/iOS/Info.plist` (riga 125), ma il testo dice
  «solo per inquadrare polizze e documenti»: **va cambiato** (D2), e va aggiornato anche il commento in testa al file
  (riga 11).
- Nessun LiDAR richiesto; l'occlusione delle persone (`.personSegmentationWithDepth`, chip A12 e successivi) è facoltativa
  (D6).
- Il simulatore iOS non ha AR: nelle istantanee e nel simulatore si usa il ripiego.
- Si controlla a ogni apertura `ARWorldTrackingConfiguration.isSupported`; **non** si aggiunge `arkit` a
  `UIRequiredDeviceCapabilities` in `Supporto/iOS/Info.plist` (renderebbe Prisma non installabile sui dispositivi senza
  AR, che invece usano il ripiego).
- I gesti di RealityKit (`installGestures`) vogliono entità con forma di collisione (`HasCollision`): al cristallo
  serve `generateCollisionShapes(recursive:)` o una `CollisionComponent` a prisma.
- Memoria: `ARView` con la sessione AR e i materiali trasparenti pesa; si crea all'apertura e si distrugge all'uscita
  (`session.pause()` e rimozione della vista), come la tela del prisma di luce.

**Sul Mac (anteprima simulata):** due strade (D4):
- (a) **RealityKit anche sul Mac**: `ARView` esiste su macOS dalla 10.15, ma **senza** `cameraMode` né ARKit (sul Mac
  la vista è sempre virtuale): si aggiunge una `PerspectiveCamera` su un'`AnchorEntity(world:)` che orbita come la
  camera del template, una `DirectionalLight` con `DirectionalLightComponent.Shadow` per l'ombra, la luce d'ambiente da
  `arView.environment.lighting.resource` (un `EnvironmentResource` della stanza, generato o in `Risorse/`, perché
  l'`environmentTexturing` di ARKit sul Mac non c'è) e il fondo `arView.environment.background = .color(…)` del palco;
  stessa scena dell'iPad più un tavolo virtuale (piano con una texture di legno generata in Swift): un solo codice del
  cristallo per Mac, iPad e iPhone (sull'iPad il ripiego usa invece `cameraMode = .nonAR`, che lì esiste); la resa del
  vetro è quella di RealityKit. API usate tutte entro macOS 12 (`PhysicallyBasedMaterial`, `MeshDescriptor`): nessuna
  protezione oltre `#if canImport(RealityKit)`. La vista si ferma (e si distrugge) quando il palco non si vede, come
  l'acqua e la tela della luce;
- (b) portare `FS_AR` in Metal come il prisma di luce (resa identica al template, ma ray marching a 72 passi + 36 per
  l'ombra su ~1150×700 pixel: pesante per un M1 con 8 GB se resta acceso, e due motori diversi per lo stesso oggetto).
Proposta: (a).

#### 2.3.3 Movimento

Tempi dell'anteprima (`ESPM.ar`, 1640-1649; `T` in secondi):

| Cosa | Template | In Prisma (`Tema.Apple.Moto.RealtaAumentata`, nuovo) |
|---|---|---|
| Giro iniziale della camera | az da −1,25 a −0,55 rad in 2,2 s, eio | `panoramica (durata 2.2, da −1.25, a −0.55)` (solo anteprima e ripiego) |
| Puntini del piano | compaiono fra 1,2 e 1,8 s, restano fino a 2,6, svaniscono in 0,5 s | `puntini (inizio 1.2, entrata 0.6, fine 2.6, uscita 0.5)`; sull'iPad partono quando ARKit trova il piano |
| Guida e «✓ Tavolo trovato» | a 1,6 s la guida svanisce in 500 ms e la pillola cambia | `guidaUscita 0.5`; sull'iPad al primo `ARPlaneAnchor` |
| Guida (i due quadrati) | 2 s, ease-in-out, ripetuta: rotateX 60°, rotateZ 0→45°→90°, y 10→−6→10; il secondo sfasato di −1 s e opacità 0,55 | `guida (durata 2.0, inclinazione 60°, giro 90°, salto 16)` con `repeatForever` |
| Anello di posa | da 2,6 s per 1,1 s, raggio 0→1,3 unità, opacità 1→0 | `anelloPosa (durata 1.1, raggio 1.3)` |
| Crescita del cristallo | da 2,6 s per 1 s: `1 − e^(−6t)·cos(9t)` (rimbalzo) | `crescita`: molla con pulsazione propria ≈ 10,8 rad/s e smorzamento ≈ 0,56, cioè `Molla(risposta: 0.58, smorzamento: 0.56)` |
| Targhetta | dopo 3,4 s, dissolvenza 0,6 s | `targhetta (ritardo 3.4 dall'apertura o 0.8 dopo la posa, durata 0.6)` |
| Orbita automatica | dopo 4 s, se non si trascina: 0,05 rad/s | `orbita 0.05` (solo anteprima e ripiego) |
| Camera, altezza, esploso | inseguimento esponenziale 5/s (camera), 6/s (altezza ed esploso) | `inseguimentoCamera 5`, `inseguimentoForma 6` |
| Pillole degli strati | dissolvenza 0,4 s con «Esploso» | `pilloleStrati 0.4` |
| Lampo dello scatto | da 1 a 0 con `e^(−9t)` | `lampo (decadimento 9)` |
| Cifra della colonna | contata in 500 ms al cambio d'anno | `NumeroCheConta` |
| Pressione dello scatto | scala 0,9 in 0,2 s | `Moto.PulsantePremuto` con scala 0,9 |

In RealityKit le animazioni del cristallo usano `Entity.move(to:relativeTo:duration:timingFunction:)` o un
`AnimationResource`; la molla della crescita si ottiene con una curva di tempo (`AnimationTimingFunction.cubicBezier`) che
approssima il rimbalzo, oppure con un piccolo sistema (`System` di RealityKit) che applica la formula a ogni
aggiornamento della scena — **non un Timer**.

- **Riduci movimento**: niente panoramica, niente orbita, niente rimbalzo: il cristallo compare già intero con una
  dissolvenza di 0,15 s appena il piano è trovato; esploso e anni cambiano senza movimento (dissolvenza 0,15 s); guida
  ferma (i due quadrati immobili). Nel template `ridotto` porta tutto a `T = 99` (1641): stessa idea.
- **Istantanee**: fermo-immagine nello stato finale (cristallo intero, targhetta visibile, guida assente, «✓ Tavolo
  trovato»), disegnato in SwiftUI (§3.5): RealityKit e la fotocamera non ci sono nei runner di GitHub né nel simulatore.

#### 2.3.4 Interazioni

iPad e iPhone (AR vera):
- **Apertura**: dal dossier del cliente (scheda «Al tavolo» o pulsante «In realtà aumentata», da decidere con la parte
  della Sala) oppure dal Mac con «▣ Mostra sul tavolo» quando l'iPad è collegato al tavolo (§3.5 punto 4).
- **Trovare il piano**: guida finché ARKit non trova un piano orizzontale; poi il cristallo si posa **dove punta il
  centro dello schermo** (raycast `arView.raycast(from:allowing:alignment:)` sul piano). Proposta: un tocco sul piano
  sposta il cristallo lì; due dita lo ruotano (`installGestures([.rotation])`); niente ridimensionamento (la scala
  è il patrimonio).
- **Cursore degli anni**: da oggi all'anno della pensione del cliente (max = 2026 + età di pensione − età, 1621): altezza
  del cristallo e cifre all'anno scelto.
- **«Esploso»**: separa gli strati e mostra le pillole con nome e valore; di nuovo per richiuderli.
- **Toccare uno strato** (non nel template; `u_sel` c'è nello shader ma resta −1): proposta, lo strato si evidenzia
  (gli altri più trasparenti) e la targhetta mostra il suo valore.
- **Scatto**: lampo e salvataggio dell'immagine (vedi D3: **che cosa** si salva).
- **Uscita**: pulsante «Fine» (non nel template) che chiude la sessione AR e spegne la fotocamera; la sessione si mette in
  pausa anche quando l'app va in secondo piano.

Mac (anteprima):
- **Trascinamento** sulla scena: orizzontale ruota la camera (220 punti = 1 rad), verticale cambia l'elevazione (320
  punti = 1 rad, fra 0,18 e 0,85) (`ESPM.ar`, 1635-1636);
- cursore degli anni, «Esploso», scatto (nell'anteprima salva l'immagine della scena virtuale);
- «▣ Mostra sul tavolo»: avvia l'AR sull'iPad collegato.

#### 2.3.5 Mappa verso Prisma

**Esiste già (verificato):**
- `ComposizioneInvestimenti360` (§2.5) per le quattro classi e i loro valori.
- `MotoreLineaVita` per il patrimonio fino alla pensione (`IngressoLineaVita.etaPensione`).
- Tavolo Mac ↔ iPad: `ProtocolloTavolo`, `MostraTavolo` (`Tavolo/ProtocolloTavolo.swift`), rete locale, ChaChaPoly con il
  codice di abbinamento; l'iPad torna alla schermata neutra se la connessione cade. Oggi dall'iPad al Mac vanno solo
  `ciao`, `valoreCursore`, `presaVisione` (righe 175-176), con `massimoTratto` 2 MB per l'immagine della firma.
- iOS: `iOS/TavoloiPad.swift`, `iOS/SchermiTavoloiPad.swift`, `iOS/IstantaneeTavoloiPad.swift`; Prisma ovunque per i dati
  sull'iPhone e sull'iPad senza Mac (`ModelliOvunque.swift`, `SpazioOvunque.swift`).
- Fotocamera già usata su iPhone da Inquadra (`iOS/InquadraTelefono.swift`), con la regola «l'immagine resta sul
  telefono e non si salva».
- Documenti del dossier: `Documento` (`Dati/Documento.swift`).

**Cosa manca:**
1. **`MotoreRealtaAumentata`** (`Motori/MotoreRealtaAumentata.swift`), puro e provato in `ProvaCalcoliLuce` o in una prova
   sua: strati (`nome`, `quota`, `valore`, `colore`) dalla composizione; bordi cumulati; altezza per anno
   `0,85 + 1,35 × patrimonio / massimo` (in unità, poi metri); anni ammessi. Le classi a zero **non** fanno uno strato.
2. **`CristalloRealta`** (`Shell/CristalloRealta.swift`, comune a Mac e iOS, solo `#if canImport(RealityKit)`): la
   costruzione delle entità (mesh, materiali, logo, ombra dipinta, puntini, anello) e il loro aggiornamento per anno ed
   esploso.
3. **`PalcoRealtaAumentata`** (palco del Mac: cornice iPad + `ARView` `.nonAR` + colonna) in `Shell/SalaRealta.swift`, e
   **`RealtaAumentataMobile`** (`iOS/RealtaAumentataMobile.swift`: `ARView` `.ar`, guida, pillole, barra, targhetta,
   scatto, ripiego `.nonAR`).
4. **Tavolo**: `MostraTavolo.Genere.realtaAumentata` con `RealtaTavolo` (nome di battesimo, strati con nome, quota, colore e
   valori per anno fino alla pensione): l'iPad non riceve nient'altro. Qui l'immagine ferma della parte comune non
   basta (l'iPad deve costruire il cristallo da sé): è il caso in cui serve davvero un genere con i dati (proprio, o un
   caso di `esperienzaSala` se si sceglie quello della parte comune). Se lo scatto deve arrivare al Mac, serve un
   contenuto nuovo **dall'iPad al Mac** `fotoRealta` (PNG/JPEG entro un limite come `massimoTratto`), da aggiungere a
   `ContenutoTavolo` e alle regole di direzione (righe 165-176).
5. **`CristalloFermo`** (SwiftUI): il fermo-immagine per istantanee e simulatore — prisma triangolare in assonometria con
   quattro strati (`Path` con i colori degli strati, facce laterali più scure, faccia alta chiara col logo), ombra
   colorata ovale sotto, fondo del palco o tavolo di legno disegnato con un gradiente.
6. **Gettoni** `Tema.Apple.RealtaAumentata` e `Moto.RealtaAumentata`; la cornice dell'iPad come componente
   `CorniceiPad` accanto a `CorniceTelefono` (§1.2).
7. **Info.plist iOS**: testo nuovo di `NSCameraUsageDescription` (D2).

#### 2.3.6 Dati che l'utente deve dare e stati vuoti

| Caso | Cosa si vede |
|---|---|
| Nessuna posizione in essere | Niente cristallo: «Giulia non ha ancora posizioni in essere: il cristallo nasce dal suo patrimonio». Il pulsante per aprire l'AR è disattivo. |
| Composizione stimata | Nota sotto le classi (colonna del Mac e pillole): «Composizione in parte stimata». |
| Senza data di nascita o età di pensione | Cursore degli anni assente: si vede solo «oggi», con «Per far crescere il cristallo negli anni serve la data di nascita». |
| AR non supportata, fotocamera negata, simulatore | Ripiego `.nonAR` con il tavolo virtuale e la frase «La fotocamera non è disponibile: il cristallo resta sul tavolo virtuale» (con «Consenti in Impostazioni» se è negata). |
| Luce scarsa / tracciamento limitato (`ARCamera.TrackingState.limited`) | Pillola di stato «Serve più luce» / «Muovi l'iPad più lentamente». |
| iPad del tavolo scollegato | Come oggi: schermata neutra, la sessione AR si chiude. |

Nessun dato nuovo da chiedere al consulente.

#### 2.3.7 Istantanee da aggiungere

Mac (con `CristalloFermo`):

| Nome | Scena |
|---|---|
| `630-sala-realta-aumentata` (+ `-scuro`) | Giulia, 2026, cristallo chiuso, targhetta |
| `631-sala-realta-aumentata-esploso` | Esploso con le pillole degli strati |
| `632-sala-realta-aumentata-vuota` | cliente senza posizioni |

iOS (simulatore, `IstantaneeMobile.swift` / `IstantaneeTavoloiPad.swift`, ripiego disegnato):

| Nome | Scena |
|---|---|
| `70-ar-ipad` | iPad: cristallo sul tavolo virtuale, barra, targhetta |
| `71-ar-ipad-esploso` | iPad esploso |
| `72-ar-iphone` | iPhone, verticale |
| `73-ar-non-disponibile` | il messaggio del ripiego |

#### 2.3.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole toccate: dati e privacy (fotocamera), grafica (tema, movimento, istantanee nello stato finale), iPhone e iPad
fedeli al tema, memoria, dipendenze (RealityKit e ARKit sono framework Apple del sistema, non dipendenze esterne).

Decisioni:
1. **D1 · La fotocamera davanti al cliente.** L'AR riprende la stanza del cliente (casa o ufficio, a volte persone). Le
   immagini della fotocamera **restano sull'iPad, in memoria**, e non si salvano né escono (ARKit le elabora sul
   dispositivo; anche le mappe d'ambiente che `environmentTexturing = .automatic` ricava dalla fotocamera per i riflessi
   del vetro restano in memoria e spariscono a fine sessione; nessuna mappa del mondo `ARWorldMap` si salva).
   Approvare l'uso della fotocamera per questa funzione.
2. **D2 · Testo del permesso.** Oggi `NSCameraUsageDescription` dice «solo per inquadrare polizze e documenti». Proposta:
   «Prisma usa la fotocamera per inquadrare polizze e documenti e per mostrare il patrimonio sul tavolo in realtà
   aumentata. Le immagini restano sul dispositivo e non si salvano, tranne la foto che scatti tu.» (e il commento di
   riga 11 del file).
3. **D3 · Lo scatto: che cosa si salva e dove.** Il template dice «Foto salvata nel dossier di Giulia Rossi». Con la
   fotocamera vera la foto contiene la stanza del cliente (dato personale, forse volti). Proposte, da scegliere:
   (a) si salva **solo il cristallo** su fondo neutro (rendering senza fotocamera) — nessun dato della stanza. Nota
   tecnica: `ARView.snapshot(saveToHDR:completion:)` include sempre l'immagine della fotocamera; per (a) serve un secondo
   disegno del solo cristallo (una vista RealityKit fuori schermo `.nonAR` con le stesse entità, o `CristalloFermo` con
   `ImageRenderer`);
   (b) foto completa, con una conferma «La foto comprende la stanza: la salvo nel dossier?»;
   (c) niente scatto.
   Proposta: (a) di base, (b) solo se l'utente lo vuole. In ogni caso la foto **non va nel Rullino** dell'iPad e arriva
   al Mac solo per la rete locale cifrata del tavolo, mai per altri servizi. Farla passare dal giornale cifrato di
   «Prisma ovunque» **non è possibile oggi**: il giornale porta solo operazioni sulle entità di `EntitaOvunque`
   (`Dati/ModelliOvunque.swift:99-114`: nota, attività, appuntamento, bisogni, evento, copilota, inquadratura), niente
   immagini né documenti. Aggiungerle sarebbe un dato nuovo che passa (cifrato) da iCloud: decisione a parte, e la prova
   `--prova-ovunque` andrebbe aggiornata.
4. **D4 · Anteprima sul Mac.** RealityKit `.nonAR` (proposta, un solo codice) oppure `FS_AR` portato in Metal (identico al
   template, più pesante).
5. **D5 · Scala reale.** 1 unità = 16 cm (cristallo da 13 cm di lato, alto da 14 a 35 cm): da provare su un tavolo vero.
6. **D6 · Occlusione delle persone.** Le mani del cliente che passano davanti al cristallo lo coprono (più realistico,
   più lavoro per l'iPad). Proposta: spenta all'inizio.
7. **D7 · Dove si apre.** Solo dal tavolo (iPad collegato al Mac, dati minimi del cliente presente) oppure anche
   dall'iPhone/iPad da soli con i dati di Prisma ovunque. Proposta: tutte e due, come il template («sull'iPad e
   sull'iPhone veri»), con i dati che il dispositivo ha già.
8. **D8 · Lavoro in background.** Nessuno: la sessione AR si ferma quando l'app non è in primo piano.

Nessuna API sopra iOS 17 o macOS 13 (si evita `RealityView` e `GroundingShadowComponent`, che sono di iOS 18). Se in
futuro si usassero, vanno protette con `if #available(iOS 18.0, *)` e un ripiego.

---

### Riepilogo dei file nuovi di questa parte

| File | Novità |
|---|---|
| `DesignSystem/Apple/Tema.Apple+PrismaCliente.swift`, `CorniceTelefonoApple.swift` | 1 |
| `Dati/PrismaCliente.swift`, `Dati/FilePrismaCliente.swift`, `Dati/GeneratorePassword.swift`, `Motori/CompositorePrismaCliente.swift`, `Risorse/PrismaCliente/lettore.js`, `lettore.css`, `parole.txt`, `Shell/SalaPrismaCliente.swift`, `Supporto/prova-file-cliente.mjs` | 1 |
| `DesignSystem/Apple/Tema.Apple+Luce.swift`, `DesignSystem/LuceShader.swift`, `DesignSystem/TelaLuce.swift`, `DesignSystem/LuceFermo.swift`, `Motori/MotoreLuce.swift`, `Motori/ProvaCalcoliLuce.swift`, `Shell/SalaLuce.swift` | 2 |
| `DesignSystem/Apple/Tema.Apple+RealtaAumentata.swift`, `Motori/MotoreRealtaAumentata.swift`, `Shell/CristalloRealta.swift`, `Shell/SalaRealta.swift`, `iOS/RealtaAumentataMobile.swift` | 3 |
| Modifiche: `Tavolo/ProtocolloTavolo.swift` (generi `luce`, `realtaAumentata`; eventuale `fotoRealta`), `iOS/SchermiTavoloiPad.swift`, `Supporto/iOS/Info.plist` (testo della fotocamera), `Dati/DatiPrisma.swift` (versione e `StatoPrismaCliente`), `DesignSystem/Apple/Tema.Apple+Inquadra.swift` (`Apparecchio` spostato in `Tema.Apple.Apparecchio` comune, con la parte comune), `DesignSystem/Apple/TemaAppleMoto.swift` (curve `standard` e `dentroFuoriCubica`, `Moto.Luce`, `Moto.RealtaAumentata`, `Moto.Testo.lettera`, `Moto.OndaMini`, `Moto.FilePronto`), le istantanee e la vetrina. `Dati/CifraturaBackup.swift` **non** cambia: la derivazione della chiave si usa da `chiaveSpazio(passphrase:sale:iterazioni:)`, già interna | 1-3 |

---

## 3. Sala: lettera dal futuro, film del piano, disegna il tuo futuro, capsula del tempo

Fonte: `Design/template-luce.html` (5 novembre 2026). Le righe citate sono di quel file. Per tutto ciò che qui non è detto
vale `Design/template-novita-specifica.md` («Orizzonte») e, sotto, `Design/template-apple-specifica.md` (token, finestra,
segmentato, card, tile, pulsanti, cascata, numeri che si contano, anelli, linee). La cornice comune della Sala (griglia,
palco, testata del palco, «Mostra sul tavolo», «Aggiungi al Prisma di …», `EsperienzaSala`, `Tema.Apple.SalaEsperienze`)
è descritta nella parte comune di Luce e qui non si ripete. **Le cifre e i nomi del template sono dimostrativi.**

Righe del template usate in questa parte:

| Cosa | Righe |
|---|---|
| CSS: `.lbl`, `.k`, `.v`, `.h2`, `.btn`, `.btn.pri`, `.btn.big` | 43-50 |
| CSS: `#toast` | 115-116 |
| CSS: `.tile`, `.bar8` | 127-129 |
| CSS: `.chip`, `.chip.on2` (viola della capsula), `@keyframes pulsa2` | 201-202, 236-237 |
| `ridotto` (Riduci movimento), `mig`/`eur`, `ease` (quartica), `conta`, `conteggi`, `entrata` | 377-383 |
| `anello`, `accendi`, `disegnaLinea`, `linee`, `toast` | 392-401 |
| `fattore` (rendita per € versato), `pctObi`, `quandoObi` | 435, 439-440 |
| `rimonta` (uscita 130 ms, poi cascata, numeri, anelli, linee) | 845 |
| Dati di prova: `CLI` (clienti, obiettivi, `an.prev`) | 405-433 |
| Dati di prova: `VITA`, `proiezione` (linea della vita del template, 2,5% nominale) | 1115-1121 |
| `nm`, `GEN` (genere dei 5 clienti), `anima`, `tela`, `pensCon`, `versPens` | 1181-1186 |
| Sala: `ESP`, glifi `GL`, `palcoHTML`, `montaSala`, `apriEsp` | 1189-1225 |
| 3 · La lettera dal futuro: `letM`, `lettera`, `ESPH.lettera`, `scriviLet`, `ESPM.lettera` | 1255-1270 |
| 4 · Il film del piano: `SCENE`, `SCENEC`, `ESPH.film`, `scenaFilm`, `ESPM.film` | 1272-1296 |
| 5 · Disegna il tuo futuro: `ESPH.disegna`, `ESPM.disegna` | 1298-1322 |
| 9 · La capsula del tempo: `CAPS`, `ESPH.capsula`, `busta`, `ESPM.capsula` | 1397-1421 |
| I traguardi festeggiati: il riquadro «La capsula del tempo di Sofia è pronta» e `fCap` | 1760, 1771, 1775 |
| Il Prisma del cliente: le voci «Una lettera da te» e «Il film del tuo piano» nella mini-app; «Cosa c'è dentro» | 1235-1236; 1241 |
| Pannello Novità: `NOV15` voci 2 (lettera), 3 (film), 4 (disegna), 8 (capsula) | 1778-1780 |

Schermate di riferimento scattate dal template (1480×940, palco 1440×900 scalato di 1,0137; in chiaro e in scuro):
`luce/img/03-lettera-{scrive,con,senza}-{chiaro,scuro}.png`, `03-film-{1800,3600,4200,4400,4600}-*.png`,
`03-film-esporta-*.png`, `03-film-esportato-*.png`, `03-film-wa-*.png`, `03-film-tavola.png`,
`03-disegna-{vuoto,tratto,morph,risultato}-*.png`, `03-disegna-tavola.png`, `03-capsula-*.png`,
`03-capsula-tavola.png`. Non sono nel repository: chi implementa le rigenera con `luce/script/shot03.js` (Playwright,
`chromium.launch()`, `deviceScaleFactor: 1`; apre Impostazioni, sceglie lo scuro, chiude, apre Sala dal dock e tocca le
schede `.espC[data-e=…]`). Le misure dei pezzi del palco sono state prese con `luce/script/misura03.js`.

**Il palco.** Tutte e quattro le esperienze vivono nella card del palco (parte comune): a 52 dall'alto, larga tutto il
contenuto della finestra (circa **1382**), alta **600**, `overflow:hidden`. Le coordinate citate qui sono dentro il palco,
in punti del template (= punti di Prisma). Il palco entra con opacità 0→1 e scala 0,98→1 in 520 ms, curva
`Moto.Curva.uscita` (`montaSala`, 1224); la riga della testata è `.st` ed entra in cascata (`rimonta`, 845).

**Chi fa cosa, in breve.** È la regola di Ruby (CLAUDE.md): Prisma calcola, Qwen racconta.

| Esperienza | Cosa calcolano i motori di Prisma | Cosa scrive Ruby (Qwen sul Mac) |
|---|---|---|
| La lettera dal futuro | età e anno del traguardo, pensione con e senza il piano, data di arrivo dell'obiettivo principale, versamento mensile, età di apertura del fondo | **la lettera** (in streaming, controllata a fine flusso); se Qwen non è pronto resta la lettera fissa di Prisma e Ruby lo dice |
| Il film del piano | tutto: percentuali degli obiettivi, versamenti, curva del patrimonio, data di arrivo, valore alla pensione; disegno dei fotogrammi e codifica del video | niente (sottotitoli fissi di Prisma). Facoltativo, da decidere: il testo breve che accompagna il video nel messaggio |
| Disegna il tuo futuro | lettura del tratto, curva del piano di oggi, confronto alla pensione, versamento in più, obiettivo da salvare | niente |
| La capsula del tempo | sigillo (cifratura), condizione di apertura, quando è «pronta», PDF su carta | **niente, mai**: il testo della capsula non passa da Qwen |

**Dipendenze dalle altre parti di Luce.** Sala e palco (parte comune: `EsperienzaSala` con i casi `lettera`, `film`,
`disegna`, `capsula`; `TestataPalco`; `PalcoEsperienza`; `Tema.Apple.SalaEsperienze`); «Aggiungi al Prisma di …» (parte
«Il Prisma del cliente»: il file del cliente contiene la lettera e il film); «I traguardi festeggiati» (riconosce
l'obiettivo raggiunto e apre la capsula, 1771/1775); «Mostra sul tavolo» (parte comune: proposta minima, un'immagine del
palco con `MostraTavolo.Genere.pagina`).

---

### 3.1 La lettera dal futuro

*Davanti al cliente · voce `NOV15[2]` «La lettera dal futuro» · «Da sé stesso a 67 anni» → `apriEsp('lettera',0)` ·
scheda della Sala `ESP[2]` «Scritta da sé stesso a 67 anni», colore #C45A75, glifo busta (`GL.lettera`, 1201) ·
`ESPH.lettera` / `ESPM.lettera` (1255-1270)*

Il cliente legge una lettera che «lui stesso», a 67 anni, gli scrive dal futuro. Due versioni: con il piano (gli obiettivi
raggiunti, una pensione più alta) e senza il piano (tutto più tardi e più stretto). Ruby la scrive con le cifre dei motori
di Prisma; il cliente la vede su un foglio di carta che resta chiaro anche nello scuro.

#### 3.1.1 Cosa si vede

**Colonna di sinistra** (assoluta a 30/30, larga 300; 1260-1264):
- il segmentato `letM` con **«Con il piano»** e **«Senza il piano»**; si apre su «Con il piano» (`let letM='con'`, 1256),
  e la scelta resta finché si torna all'esperienza (variabile globale);
- 14 sotto, in `.k` a 13,5 pt con interlinea 1,5: **«Ruby scrive la lettera con le cifre dei motori di Prisma: pensione,
  obiettivi, versamenti.»**;
- 16 sotto, una `.tile` con **«Pensione stimata con il piano»** (`.k`) e la cifra `.v` in verde (`--green`), che si conta
  da 0 (esempio: **2.160 €**);
- 10 sotto, una `.tile` con **«Senza il piano»** e la cifra `.v` nel colore del testo (esempio: **1.400 €**);
- 16 sotto, il pulsante `.btn.big` **«↻ Riscrivi»**.
- Le due tile **non cambiano** con il segmentato: mostrano sempre tutte e due le pensioni, una sotto l'altra (10 di spazio).

**Il foglio** (`#letP`, 1265-1268): assoluto da 380 a sinistra fino a 40 da destra, 22 sopra e 22 sotto (circa 962×556 nel
palco da 1382×600):
- fondo **#FFFDF8** (carta calda), testo **#2A2622**, raggio 6, ombra `0 22px 50px -18px rgba(40,30,20,.35)`, margini
  interni 40 sopra e sotto, 56 ai lati, `overflow:hidden`;
- in alto il sopratitolo **«UNA LETTERA DAL FUTURO»**: 11 pt, peso 700, spaziatura 1,6, colore #A08C78;
- 16 sotto, il testo (`#letT`): serif (Georgia nel template), 17 pt, interlinea 1,72, a capo come scritto (`pre-wrap`);
- il piede, assoluto a 56 dai lati e a 18 dal fondo, con un filetto sopra da 1 (#EDE6DC) e 8 di spazio: **«Lettera
  immaginata a partire dalle stime di Prisma (pensione pubblica, obiettivi, fondo pensione). Non è una previsione né una
  promessa.»** a 10,5 pt, colore #9A8F84.
- Nello scuro la colonna di sinistra diventa scura (tile `--card`, segmentato `--chip`), **il foglio resta chiaro** e
  identico (`03-lettera-senza-scuro.png`).

**Il testo** (`lettera(c,i,con)`, 1257-1259). I segnaposto sono tra graffe; `{Cara|Caro}` dipende dal genere (`GEN`,
1182). Le due versioni, testuali:

> **Con il piano**
> {Cara|Caro} {nome},
>
> ti scrivo dal {anno}. Ho {età} anni e stamattina ho ripensato a quella sera di novembre del 2026, con tutti i numeri sul
> tavolo. L'obiettivo «{obiettivo}» l'abbiamo raggiunto a {mese anno di arrivo}, proprio come avevamo previsto. Non è
> stato sempre facile mettere da parte {versamento} euro al mese, ma abbiamo tenuto la rotta.
>
> Oggi la pensione arriva a circa {pensione con il piano} euro al mese, contando anche il fondo che abbiamo aperto a {età
> di oggi} anni. Possiamo permetterci quello che conta: un viaggio all'anno, una mano a chi amiamo, nessuna paura del
> mese dopo.
>
> Grazie per aver cominciato quando era il momento.
>
> {nome}, {età} anni

> **Senza il piano**
> {Cara|Caro} {nome},
>
> ti scrivo dal {anno}. Ho {età} anni. L'obiettivo «{obiettivo}» alla fine l'abbiamo raggiunto, ma molto più tardi e con
> più fatica di quanto speravamo.
>
> La pensione è di circa {pensione senza il piano} euro al mese. Ce la facciamo, ma i viaggi li abbiamo lasciati perdere e
> a chi amiamo diamo una mano quando possiamo, non quando vorremmo. Ogni tanto ripenso a quella sera di novembre del 2026
> in cui avevamo tutti i numeri davanti.
>
> Non è una vita brutta. È solo più stretta di quella che potevamo avere.
>
> {nome}, {età} anni

Come il template ricava le cifre (solo per capire; nell'app valgono i motori del §1.5):
- `{età}` = età di pensione della linea della vita (`VITA[i].pens`, 67); `{anno}` = 2026 + (età − età di oggi);
- `{obiettivo}` = il primo obiettivo del cliente (`c.obi[0]`); `{mese anno di arrivo}` = `quandoObi(o, o.v)`: mesi =
  ⌈(traguardo − accumulato) / versamento⌉ da novembre 2026, **senza rendimento**;
- `{versamento}` = il versamento mensile dell'obiettivo (`o.v`);
- `{pensione con il piano}` = `pensCon(c)` = pensione pubblica + max(divario × 0,95, versamento previdenziale × `fattore`)
  arrotondata a 10 (1185); `{pensione senza il piano}` = la sola pensione pubblica (`c.an.prev.pens`).

**Testata del palco**: «‹ Sala», tassello #C45A75 con la busta, **«La lettera dal futuro»**, «· Giulia Rossi»; a destra
**«▣ Mostra sul tavolo»** e **«✦ Aggiungi al Prisma di Giulia»** (1219).

**Stati del template**: solo «sta scrivendo» (il testo compare due parole alla volta) e «scritta». Nessun errore, nessun
vuoto. Per l'app: §1.6.

**Difetti e scelte del template da non copiare:**
- l'anno è calcolato con l'età intera; nell'app si usa la data di nascita (anno in cui compie l'età di pensione);
- la data di arrivo ignora rendimento, inflazione e posizioni collegate; nell'app viene da `CurvaObiettivo` (§1.5);
- «contando anche il fondo che abbiamo aperto a {età} anni» compare anche se nel piano non c'è nessun fondo pensione:
  nell'app la frase entra **solo** se fra le proposte (o in essere) c'è una posizione previdenziale;
- «↻ Riscrivi» riscrive lo stesso testo: nell'app chiede a Qwen una nuova stesura;
- «Senza il piano» nel template è la sola pensione pubblica e ignora le posizioni previdenziali già in essere.

#### 3.1.2 Misure e stile

Token esistenti (`DesignSystem/Apple/TemaApple.swift`):

| Template | Valore | Prisma |
|---|---|---|
| segmentato `.seg` | 13 pt 600, padding 6/14, pillola `--cardE` | `SegmentatoPillola` (`ControlliApple.swift:19`) |
| `.k` 13,5 / interlinea 1,5 | | `Carattere.voceLista` (13,5) con interlinea 1,5 → **nuovo** `SalaRacconti.Lettera.spiegazione` |
| `.tile` | raggio 18, `--card`, bordo `--sep`, padding 14/16 | `Superficie.tile`, `Raggio.tile`, `Misura.padding` della tile |
| `.k` nella tile / `.v` | 12,5 regular / 26 bold −0,5 tabellare | `Carattere.secondario` / `Carattere.valore` |
| verde della pensione | #2FA35A | `Colore.verde` |
| `.btn.big` | 13,5 600, padding 10/18 | `StilePulsanteApple` grande, `Carattere.pulsanteGrande` |

Token **nuovi**, in un file nuovo `DesignSystem/Apple/Tema.Apple+SalaRacconti.swift`, `enum Tema.Apple.SalaRacconti`
(nessun conflitto di nomi in `Sources/`, verificato con grep), sotto-enum `Lettera`:

| Nome proposto | Valore | Note |
|---|---|---|
| `Lettera.larghezzaColonna` | 300 | colonna di sinistra |
| `Lettera.margineColonna` | 30 | sopra e a sinistra |
| `Lettera.foglioSinistra` / `foglioDestra` / `foglioSopraSotto` | 380 / 40 / 22 | |
| `Lettera.carta` | #FFFDF8 | **fisso**, uguale in chiaro e in scuro |
| `Lettera.inchiostro` | #2A2622 | |
| `Lettera.sopratitolo` | #A08C78 | |
| `Lettera.piede` | #9A8F84 | |
| `Lettera.filetto` | #EDE6DC | |
| `Lettera.raggio` | 6 | = `Raggio.bollaPiccola` (6): si riusa |
| `Lettera.ombra` | 0 22 50 −18 rgba(40,30,20,.35) | nuova voce di `Tema.Apple.Ombra` (`.foglioLettera`) |
| `Lettera.margini` | 40 sopra/sotto, 56 ai lati | `Misura.padding(40, 56)` |
| `Lettera.carattereSopratitolo` | 11, 700, spaziatura 1,6, maiuscolo | `Carattere(dimensione: 11, peso: .bold, tracking: 1.6, maiuscolo: true)` |
| `Lettera.testo` | serif 17, interlinea 1,72 | **serve un campo nuovo** in `Carattere`: oggi `font` usa sempre `Font.Design.default` (`TemaApple.swift:622-626`). Proposta: `var disegno: Font.Design = .default` e `Carattere(dimensione: 17, peso: .regular, interlinea: 1.72, disegno: .serif)`. `.serif` è New York, il serif di sistema (macOS 13 sì). Georgia del template c'è su macOS ma non è del tema: da decidere (§1.8, D-L7) |
| `Lettera.spazioSopraTesto` | 16 | |
| `Lettera.caratterePiede` | 10,5 regular | |
| `Lettera.spaziPiede` | 56 ai lati, 18 dal fondo, 8 sopra il filetto | |

Nel **PDF** (stampa e «Aggiungi al Prisma») la lettera va su `Tema.Apple.Carta` (`TemaApple.swift:184-201`): fondo
`Carta.fondo` #FFFFFF (CLAUDE.md: «I documenti PDF restano sempre su carta bianca»), testo `Carta.testoCorrente`, piede
`Carta.piede`, filetto `Carta.filetto`. Il #FFFDF8 vale solo sullo schermo.

#### 3.1.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Palco | 520 ms, opacità e scala 0,98, (.22,1,.36,1) | parte comune (`Moto.Curva.uscita`) |
| Testata e colonna | cascata `.st` (720 ms, passo 48 ms) | `Moto.Cascata` |
| Cifre delle tile | contate da 0 in 1100 + i·60 ms, quartica | `NumeroCheConta`, `Moto.Numero` |
| Prima scrittura | parte 350 ms dopo il montaggio (1270) | **nuovo** `Moto.Lettera.ritardoAvvio = 0.35` |
| Scrittura | `split(/(\s+)/)` separa parole e spazi, `i+=2` ogni 26 ms: **una parola (con il suo spazio) ogni 26 ms** (`setInterval`, 1269) | con Ruby: il testo arriva **in streaming** da Qwen e si mostra man mano (come `MessaggiRuby`, con `mostrabile`); con la lettera fissa di Prisma: **nuovo** `Moto.Lettera.passoParola = 0.026` s (una parola ogni 26 ms) con `TimelineView`/`Animatable` sul numero di parole mostrate, **niente Timer** |
| Cambio di versione | il testo sfuma 1→0 in 200 ms, poi riparte la scrittura (1270) | **nuovo** `Moto.Lettera.dissolvenzaCambio = 0.20` |
| «↻ Riscrivi» | riparte la scrittura senza dissolvenza | stessa dissolvenza del cambio, poi nuova stesura |

- **Riduci movimento** (`\.prismaCalmo`): il template mostra subito tutto il testo (1269). Nell'app: niente parola per
  parola; il testo compare intero, con una dissolvenza di 0,15 s, appena è pronto (con Qwen: quando il flusso è finito e
  controllato, con la frase «Ruby sta scrivendo…» in `.k` nel frattempo).
- **Istantanee** (`\.modoIstantanea`, `\.prismaStatoFinale`): la lettera fissa di Prisma, intera, le cifre complete. Mai
  Qwen nelle istantanee (il runner non ha Ollama).

#### 3.1.4 Interazioni

- **Segmentato** «Con il piano» / «Senza il piano»: cambia la versione; con Ruby parte una nuova richiesta a Qwen per la
  versione scelta (le due stesure si tengono in memoria finché il palco è aperto: tornare indietro non richiede di nuovo).
- **«↻ Riscrivi»**: nuova stesura della versione mostrata (con Qwen; con la lettera fissa non fa niente e il pulsante è
  spento con l'aiuto «Ruby non è pronta: la lettera è quella di Prisma»).
- **Durante lo streaming**: il segmentato e «Riscrivi» restano attivi; cambiare versione ferma il flusso in corso.
- **«▣ Mostra sul tavolo»**: manda all'iPad del tavolo l'immagine del **foglio** (non della colonna di sinistra), come
  pagina (`MostraTavolo.Genere.pagina`, nessun cambio di protocollo). Solo a lettera finita.
- **«✦ Aggiungi al Prisma di Giulia»**: conserva la lettera (§1.5, `LetteraFuturo`) e la aggiunge ai contenuti del file del
  cliente (parte «Il Prisma del cliente»). Si aggiunge la versione **mostrata**; proposta: si possono aggiungere tutte e
  due, ma la «senza il piano» solo insieme alla «con il piano» (vedi D-L4).
- **Proposta nuova, non nel template**: «Stampa» nel menu contestuale del foglio (e ⌘P con il palco a fuoco) → PDF su
  carta con `StampaCarta`.
- **Tastiera**: ⌘R = Riscrivi (grep di `keyboardShortcut` in `Sources/Prisma`: ⌘R non è usato; resta da controllare che `ComandiShell.swift` non lo intercetti con un monitor di eventi); frecce sul segmentato. ⌘P va confrontato con la voce «Stampa…» del menu di sistema.
- **iPhone e iPad**: il template non ha la Sala sui dispositivi. Il cliente vede la lettera sull'iPad del tavolo (immagine)
  e, se il consulente la aggiunge, nel suo «Prisma» (voce «Una lettera da te · scritta a 67 anni», 1235).

#### 3.1.5 Mappa verso Prisma

**Esiste già (verificato con grep in `Sources/Prisma`):**
- **Ruby che scrive con le cifre di Prisma**: `Ruby/MessaggiRuby.swift` è il modello da copiare: scheda dei fatti, bozza
  fissa, Qwen in streaming con `FornitoreModello` (`Ruby/FornitoreModello.swift:80`), controllo a fine flusso con
  `CommentoRuby.numeriConservati` (`Ruby/CommentoRuby.swift:47`), `MessaggiRuby.promesse` (regex delle promesse,
  `MessaggiRuby.swift:101`), `mostrabile` (pezzi del flusso con cifre verificate), `pulisci`, ripiego `fisso(_:avviso:)` e
  `avvisoNonPronta(_:)`. Le istruzioni stanno in `Ruby/Istruzioni/*.md` (oggi: `messaggi.md`, `commento.md`, …).
- **Autore del testo**: `AutoreMessaggio` (`Dati/MessaggioCliente.swift:157`: `.ruby` = «eve», `.modelloFisso`).
- **Genere per «Cara/Caro»**: `MotoreAree360.femminile(_:)` (`Motori/MotoreAree360.swift:320`), dal codice fiscale
  (giorno > 40), nil se manca. `Cliente` non ha un campo genere (`Dati/Modelli.swift:32-66`).
- **Età di pensione, reddito desiderato, pensione pubblica**: `IpotesiPrevidenza` (`Dati/Analisi.swift:122-131`:
  `etaPensione`, `redditoDesiderato`, `pensionePubblica`, …) nell'Analisi 360 **salvata**; stima contributiva
  `MotorePensionePubblica.stima(cliente:previdenza:)` (`Motori/MotorePensionePubblica.swift:225`).
- **Pensione con e senza il piano**: `MotorePrevidenza.calcola(_:cliente:analisi:)` (`Motori/MotorePrevidenza.swift:94`)
  → `EsitoPianoPrevidenziale` con `pensionePubblica`, `renditaInEssere`, `renditaProposte`, `inEssere`, `proposte`.
- **Data di arrivo di un obiettivo**: `CurvaObiettivo.curva(_:posizioni:)` e `arrivo(versamento:) -> Date?`
  (`Motori/CurvaObiettivo.swift:88,131`); `MotoreObiettivo.calcola` (`Motori/MotoreObiettivo.swift:65`) con
  `versamentiAttivi`, `versamentoNecessario`; `Obiettivo.versamentoMensile`, `priorita`, `scadenza`
  (`Dati/Prodotti.swift:172-191`).
- **Data di nascita**: `Cliente.dataNascita`; età con `MotorePensionePubblica.etaAl(_:_:)` (`:262`).
- **Carta e PDF**: `Tema.Apple.Carta`, `StampaCarta.pdf(_:)` / `DocumentoStampabile` (`Shell/StampaCarta.swift:12,166`).
- **Tavolo**: `MostraTavolo.Genere.pagina` (`Tavolo/ProtocolloTavolo.swift:186-198`).

**Da creare:**
1. `Shell/SalaLettera.swift`: `LetteraDalFuturo` (vista del palco: colonna, foglio, piede), `FoglioLettera` (riusato dal
   PDF con la tavolozza `Carta`).
2. `Motori/MotoreLettera.swift`, puro, senza SwiftUI: prepara la **scheda dei fatti** e la lettera fissa.

   ```swift
   enum VersioneLettera: String, Codable { case conPiano, senzaPiano }
   struct SchedaLettera: Equatable {
       let nome: String                 // il nome di battesimo
       let femminile: Bool?             // nil: «Cara/Caro» si evita («Ciao Giulia,» o solo il nome, D-L6)
       let etaTraguardo: Int; let annoTraguardo: Int
       let meseIncontro: String         // «novembre 2026»: il mese di oggi, non fisso
       let etaOggi: Int
       let obiettivo: String?           // titolo dell'obiettivo principale
       let arrivoConPiano: Date?        // CurvaObiettivo.arrivo(versamento: previsto)
       let arrivoSenzaPiano: Date?      // CurvaObiettivo.arrivo(versamento: 0); nil = oltre 30 anni
       let versamentoMensile: Double?   // Obiettivo.versamentoMensile + premi delle collegate
       let pensioneConPiano: Double?    // pubblica + rendita in essere + rendita delle proposte
       let pensioneSenzaPiano: Double?  // pubblica + rendita in essere
       let fondoNelPiano: Bool          // c'è una posizione previdenziale in proposta (o aperta dopo il primo incontro)
       let mancanti: [String]           // ciò che manca, per lo stato vuoto (§1.6)
   }
   enum MotoreLettera {
       static func scheda(cliente:, posizioni:, obiettivi:, analisi: IpotesiPrevidenza?, oggi: Date) -> SchedaLettera
       static func fissa(_ s: SchedaLettera, _ v: VersioneLettera) -> String   // il testo del template, con le frasi condizionate
       static func ammessi(_ s: SchedaLettera, _ v: VersioneLettera) -> String  // le cifre che Qwen può usare
   }
   ```
   Regole: **obiettivo principale** = quello con priorità più alta e scadenza futura (a parità, la scadenza più vicina);
   **«il piano»** = le posizioni in proposta del cliente più i versamenti previsti degli obiettivi (`versamentoMensile`)
   (definizione da confermare, D-L2); **anno del traguardo** = anno in cui il cliente compie l'età di pensione dalla data
   di nascita; **le cifre in euro di oggi**, arrotondate a 10 € come nel template.
3. `Ruby/LetteraRuby.swift`: come `MessaggiRuby` (`istruzioni`, `opzioni`, `controlla`, `scrivi` con streaming). Controlli
   a fine flusso, se uno fallisce resta la lettera fissa con l'avviso:
   - ogni cifra (euro, anni, mesi, percentuali) sta nella scheda (`CommentoRuby.numeriConservati` su `ammessi`);
   - niente promesse (`MessaggiRuby.promesse`), niente prodotti o compagnie nominati, niente segnaposto;
   - prima persona singolare, scritta dal cliente a sé stesso; lunghezza 120-220 parole (da tarare);
   - la firma «{nome}, {età} anni» la aggiunge Prisma; il piede del foglio è fisso, non lo scrive Ruby.
4. `Ruby/Istruzioni/lettera.md` (nuovo, nel repository come vuole CLAUDE.md; il workflow copia già tutta la cartella nel
   pacchetto, `build.yml:87-90`, e si legge con `IstruzioniRuby.testo("lettera")`, `Ruby/MotoriRuby.swift:7`): tono, struttura (saluto, l'anno e l'età, gli
   obiettivi, la pensione, una chiusura), divieti (promesse, cifre fuori scheda, paura, giudizi sul cliente), la differenza
   fra le due versioni, un esempio per versione. Il «Senza il piano» va scritto **senza drammatizzare** (vedi D-L3).
5. Dati: `Dati/LetteraFuturo.swift`, solo quando il consulente la conserva («Aggiungi al Prisma», «Stampa»):

   ```swift
   struct LetteraFuturo: Identifiable, Codable, Equatable {
       var id = "lettera-\(UUID().uuidString.prefix(8).lowercased())"
       var clienteId: String
       var scrittaIl: Date
       var versione: VersioneLettera
       var testo: String                // con la firma
       var autore: AutoreMessaggio      // .ruby o .modelloFisso
       var modello: String?             // «qwen3.5:4b»
       var cifre: [String: String]      // la scheda usata, per rileggere da dove vengono i numeri
   }
   ```
   `DatiPrisma.lettere: [LetteraFuturo] = []`, letto con `decodeIfPresent` (versione dell'archivio di Luce, §0), nel
   backup, nella prova `Prisma --prova-backup` (`Dati/ProvaBackup.swift`, nuova `ProvaBackupRacconti`). Proposta: **non**
   nell'istantanea di «Prisma ovunque» (è un testo personale come le conversazioni di Ruby), da decidere (D-L8).
6. Prove: `Motori/ProvaCalcoliLettera.swift` (chiamata da `ProvaCalcoli.esegui()`): anno del traguardo dalla data di
   nascita; senza Analisi 360 salvata → `pensione* = nil` e la frase sulla pensione sparisce; `fondoNelPiano` falso → nessuna
   frase sul fondo; arrivo senza versamento oltre 30 anni → «molto più tardi» senza data; femminile nil → nessun «Cara/Caro»;
   la lettera fissa non contiene segnaposto `{`. `Ruby/ProvaLetteraRuby.swift` (come `ProvaMessaggiRuby`): istruzioni nel
   pacchetto, controllo che respinge una cifra inventata e una promessa.

#### 3.1.6 Dati che l'utente deve dare e stati vuoti

Dati del cliente che servono (mai inventati):
- **data di nascita** (età e anno del traguardo);
- **Analisi 360 › Previdenza salvata**: età di pensione, pensione pubblica (o i dati del lavoro per la stima), reddito
  desiderato;
- **almeno un obiettivo** con scadenza futura e il versamento previsto;
- **codice fiscale** per «Cara/Caro» (altrimenti saluto neutro).

Stati:
- **Manca la data di nascita**: niente lettera. Al posto del foglio, in `.k`: «Per scrivere la lettera serve la data di
  nascita di Giulia.» con «Completa l'anagrafica ›» (apre il dossier).
- **Manca l'Analisi 360 › Previdenza**: la lettera si scrive senza la frase sulla pensione; le due tile mostrano «—» e
  «Imposta la previdenza in Analisi 360 ›». L'età del traguardo è 67 con la nota «età di pensione ipotizzata» sotto il
  segmentato.
- **Nessun obiettivo**: la lettera si scrive senza la frase sull'obiettivo; nota «Aggiungi un obiettivo per raccontarlo».
- **Nessuna proposta e nessun versamento previsto**: «Con il piano» e «Senza il piano» coincidono. Il segmentato è spento
  sulla seconda voce con l'aiuto «Per confrontare serve un piano: una proposta o un versamento per un obiettivo».
- **Ruby non pronta** (Qwen spento, modello assente): resta la lettera fissa di Prisma; sotto il segmentato, in `.k`
  arancio: «Ruby non è pronta: la lettera è quella di Prisma» (testo di `MessaggiRuby.avvisoNonPronta`).
- **Ruby ha scritto una cifra fuori scheda o una promessa**: resta la lettera fissa con il motivo («una cifra non era
  nelle stime di Prisma»).
- **Dati di prova**: etichetta «dati di prova» accanto al titolo quando il cliente è dei 5 del template o dei 30 fittizi.

#### 3.1.7 Istantanee da aggiungere

Serie proposta **640-643** (libera in `Sources/`: l'ultima serie usata sul Mac è 613; da riconciliare con le altre parti di
Luce), file `Shell/IstantaneeSalaRacconti.swift` sul modello di `Shell/IstantaneeLineaVita.swift`, chiare e scure, tutte
nello stato finale con la lettera fissa di Prisma:

| Nome | Scena |
|---|---|
| `640-sala-lettera` (+ `-scuro`) | Giulia, «Con il piano», lettera intera, tile contate |
| `641-sala-lettera-senza-piano` (+ `-scuro`) | Giulia, «Senza il piano» |
| `642-sala-lettera-ruby-non-pronta` | avviso arancio sotto il segmentato |
| `643-sala-lettera-dati-mancanti` (+ `-scuro`) | Andrea senza data di nascita: lo stato vuoto con «Completa l'anagrafica ›» |

Più una pagina PDF della lettera nella prova dei prospetti (`Shell/ProvaProspetti.swift`) per vedere la carta bianca.

#### 3.1.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole toccate: Ruby (Qwen locale, «i calcoli di Prisma preparano le cifre esatte che Qwen racconta», istruzioni in
`Ruby/`); «I documenti PDF restano sempre su carta bianca»; valori nel tema; dati che restano sul Mac (la lettera esce solo
se il consulente la mette nel file del cliente o la stampa).

- **D-L1 · Uscita della lettera.** Sul Mac e sull'iPad del tavolo resta in locale. Esce dal Mac solo dentro il «Prisma del
  cliente» o stampata: valgono le decisioni di quella parte (file cifrato, spedito dal consulente).
- **D-L2 · Che cos'è «il piano».** Proposta: le posizioni **in proposta** del cliente più i versamenti previsti per gli
  obiettivi. Alternativa: solo le proposte di un incontro scelto. Serve una definizione, perché decide le due pensioni.
- **D-L3 · La versione «Senza il piano» (comunicazione al cliente).** Il testo del template è emotivo («i viaggi li
  abbiamo lasciati perdere», «È solo più stretta di quella che potevamo avere»). Per un intermediario assicurativo
  (Alleanza, regole IVASS sulla correttezza delle comunicazioni) e per la consulenza indipendente, un testo che fa leva sul
  timore per vendere può essere contestato. Proposta: tenerla, ma con le istruzioni di Ruby che vietano scenari negativi
  oltre le cifre (dire solo «la pensione è di circa X»), e farla approvare all'utente; in alternativa toglierla e lasciare
  solo «Con il piano». **Il testo del piede** («Lettera immaginata… Non è una previsione né una promessa.») è un'avvertenza:
  va confermata dall'utente (o da Alleanza per i clienti del canale Alleanza), non si inventa altro.
- **D-L4 · «Aggiungi al Prisma» della versione «Senza il piano».** Mandare al cliente una lettera «senza il piano» è
  delicato. Proposta: si aggiunge solo la «Con il piano»; la «Senza» resta davanti al cliente.
- **D-L5 · Canale.** La lettera non nomina prodotti né compagnie: nessuna etichetta di canale sul foglio. Se l'utente
  vuole la firma del consulente sul PDF, vale la regola dei canali (cuoio «Denis Vicenzoni · Consulenza finanziaria» o
  blu Alleanza con il logo), da decidere per i clienti con tutti e due i canali.
- **D-L6 · Saluto senza genere.** Senza codice fiscale: «Ciao Giulia,»? «Giulia,»? Proposta: «{nome},».
- **D-L7 · Carattere serif.** New York (`Font.Design.serif`, di sistema e coerente con Apple) o Georgia (come il template)?
  Proposta: New York; è un campo nuovo di `Carattere` (`disegno`).
- **D-L8 · «Prisma ovunque».** Le lettere conservate vanno nell'istantanea cifrata per iPhone/iPad? Proposta: no.
- Nessuna API sopra macOS 13 (`Font.Design.serif` da macOS 10.15, `TimelineView` da macOS 12). Nessuna dipendenza esterna.

---

### 3.2 Il film del piano

*Davanti al cliente · voce `NOV15[3]` «Il film del piano» · «Un minuto da mandare su WhatsApp» → `apriEsp('film',0)` ·
scheda della Sala `ESP[3]` «Un minuto da mandare dopo l'incontro», colore #E08A00, glifo schermo con il triangolo di
riproduzione (`GL.film`, 1202) · `SCENE`, `SCENEC`, `ESPH.film`, `scenaFilm`, `ESPM.film` (1272-1296)*

Un breve video del piano del cliente: il titolo, gli obiettivi di oggi, il versamento di ogni mese, la curva del futuro e
una chiusura. Si guarda nel palco, si esporta in MP4 e il consulente lo manda al cliente (nel template: «Manda su
WhatsApp»). Il video lo disegna e lo codifica Prisma sul Mac, **senza dipendenze esterne**, con AVFoundation.

#### 3.2.1 Cosa si vede

**Lo schermo del film** (`#film`, 1274-1275): centrato, a 22 dall'alto, **880×495** (16:9), raggio 18, `overflow:hidden`,
fondo `radial-gradient(700px 400px at 50% 40%, #1D3447, #0A121A)`, ombra `0 30px 60px -20px rgba(0,0,0,.5)`, testo
bianco. È **sempre scuro**, in chiaro e in scuro (`03-film-esportato-scuro.png`). Dentro: la scena (`#scena`, tutta l'area)
e il sottotitolo (`#sott`), centrato a 22 dal fondo, 17 pt peso 500, ombra del testo `0 2px 8px rgba(0,0,0,.6)`.

**Le cinque scene** (`scenaFilm`, 1279-1288), durate `SCENE = [3.4, 4.2, 4.2, 4.8, 3.6]` s (**20,2 s in tutto**),
sottotitoli `SCENEC`:

| # | Durata | Contenuto | Sottotitolo |
|---|---|---|---|
| 0 | 3,4 s | Al centro il **logo di Prisma** bianco 84×84; 26 sotto **«Il piano di Giulia»** (display 52, 700, −1,5); 6 sotto **«novembre 2026»** (18, opacità 0,6) | — |
| 1 | 4,2 s | **«OGGI»** (14, 700, spaziatura 2, opacità 0,6); 22 sotto i primi **3 obiettivi** affiancati (spazio 46): anello 150 spessore 15 nel colore dell'obiettivo, al centro la percentuale (display 32, 700); 10 sotto il nome (16, opacità 0,85) | **«Ecco dove sei oggi.»** |
| 2 | 4,2 s | **«OGNI MESE»**; 8 sotto la cifra **«550 €»** contata (display **110**, 700, −4, interlinea 1,05); **«per «Anticipo casa»»** (20, opacità 0,8); 26 sotto **«+ 420 € per la pensione»** (display 34, 700, #C4B5FD) | **«Un passo ogni mese.»** |
| 3 | 4,8 s | **«IL TUO FUTURO»** in alto a sinistra (60/46); la **curva del patrimonio** da oggi all'età di pensione (#C4B5FD, spessore 4, estremi arrotondati), area 760×300 da x 60, y 80-380; un punto bianco r 8 sul mese in cui si raggiunge l'obiettivo, con **«ottobre 2029 · Anticipo casa»** (17, 700) 20 sopra; un punto #C4B5FD r 8 alla fine con **«a 67 anni: 661.156 €»** (22, 700, allineato a destra, 14 a sinistra del punto) | **«E dove ti porta.»** |
| 4 | 3,6 s | **«Ce la facciamo insieme.»** (display 56, 700, −1,5); 14 sotto **«Denis Vicenzoni · Consulenza finanziaria»** (18, opacità 0,75); 40 sotto l'avvertenza **«Stime basate su ipotesi: non sono promesse né garanzie di risultato. Il dettaglio è nei prospetti consegnati.»** (12, opacità 0,5, larga al più 560, interlinea 1,5) | — |

Le percentuali della scena 1 sono `pctObi` = accumulato / traguardo (oggi). La cifra della scena 2 è il versamento del
primo obiettivo (`o.v`), la pensione è `versPens(c)` (versamento che coprirebbe il divario, 1186). La curva della scena 3
è `proiezione(c, VITA)` (2,5% nominale, 1121), tagliata all'età di pensione.

**I comandi** (1276-1277), una riga 10 sotto lo schermo, larga come lo schermo, spazio 12:
- pulsante tondo 38×38 **«❚❚»** / **«▶︎»** (pausa e riproduzione);
- barra di avanzamento alta 6, raggio 9, binario `--track`, riempimento `--accent` (#007AFF);
- il tempo **«0:05 / 0:20»** (`.k`, cifre tabellari, largo 84);
- **«⇩ Esporta il video»** (`.btn`) e **«Manda su WhatsApp»** (`.btn.pri`, blu).

**Esportazione** (1295): in alto a destra (a 30 dal bordo, 22 dall'alto, larga 240) compare una tile su `--cardE` con
**«Esporto il video · 1080p»** e una barra `.bar8` che si riempie in 1,8 s; poi la tile diventa **«✓ Il-piano-di-Giulia.mp4»**
(verde, grassetto) con **«20 secondi · senza voce · pronto»** e bordo `rgba(47,163,90,.4)`.
**«Manda su WhatsApp»** mostra solo il toast **«Il video è pronto da condividere su WhatsApp: lo mandi tu»** (1296).

Il film parte da solo all'apertura e si ferma alla fine; «▶︎» a fine film riparte da capo (1293-1294).

**Testata del palco**: tassello #E08A00, **«Il film del piano»**, «· Giulia Rossi», **«▣ Mostra sul tavolo»** e **«✦ Aggiungi
al Prisma di Giulia»**.

**Difetti del template da non copiare:**
- la scheda e il pannello Novità dicono **«un minuto»**, il film dura **20 secondi** (e la tile dice «20 secondi»): D-F1;
- la tile dell'esportazione (a destra, larga 240) **copre l'angolo** dello schermo del film (`03-film-esportato-*.png`);
  nell'app va sotto i comandi o al posto dei pulsanti;
- l'etichetta dell'obiettivo nella scena 3 esce a sinistra quando il traguardo è vicino («ottobre 2029 · Anticipo casa»
  tocca il bordo, `03-film-4200-chiaro.png`): va tenuta dentro l'area (allineata a sinistra sotto x 140);
- la cifra finale è in euro **nominali** al 2,5%: nell'app viene da `MotoreLineaVita` in **euro di oggi**, e la scritta lo
  dice («a 67 anni, in euro di oggi: …»);
- la firma è sempre quella del canale indipendente, anche per un cliente solo Alleanza (D-F5);
- il tempo «0:20» è troncato (20,2 s).

#### 3.2.2 Misure e stile

Token esistenti: `Colore.accento` (#007AFF, barra), `Colore.binario` (`--track`), `Carattere.pulsante`,
`StilePulsanteApple` (normale e primario), `Superficie.tile`, `Colore.verde`, `LogoPrisma` / `GeometriaLogo.tracciato`
(`DesignSystem/LogoPrisma.swift:54`, il logo in vettoriale, bianco sugli sfondi scuri come vuole CLAUDE.md), colori degli
obiettivi (`Colore.anello1/2/3`, `TemaApple.swift:92-94`), `Colore.stima` (#8B5CF6).

Token **nuovi** in `Tema.Apple.SalaRacconti.Film` (valori in punti del film a 880×495; nel video si moltiplicano per
1920/880 = 2,1818, così il video è identico all'anteprima):

| Nome proposto | Valore |
|---|---|
| `Film.formatoAnteprima` | 880×495, raggio 18, a 22 dall'alto |
| `Film.fondoCentro` / `fondoBordo` | #1D3447 / #0A121A, radiale 700×400 al 50%/40% |
| `Film.ombra` | 0 30 60 −20 rgba(0,0,0,.5) (nuova voce di `Tema.Apple.Ombra`, `.film`) |
| `Film.testo` | bianco |
| `Film.lavanda` | #C4B5FD (curva, pensione, punto finale) |
| `Film.titolo` | display 52, 700, −1,5 |
| `Film.data` | 18 regular, opacità 0,6 |
| `Film.occhiello` | 14, 700, spaziatura 2, maiuscolo, opacità 0,6 |
| `Film.percentuale` | display 32, 700 |
| `Film.nomeObiettivo` | 16, opacità 0,85 |
| `Film.anello` | 150, spessore 15, spazio fra gli anelli 46 |
| `Film.cifraMese` | display 110, 700, −4, interlinea 1,05, tabellare |
| `Film.perObiettivo` | 20, opacità 0,8 |
| `Film.pensione` | display 34, 700 |
| `Film.curva` | spessore 4, area 760×300, x 60-820, y 80-380 (nel riquadro 880×440 a y 30), margine sopra il massimo 12% |
| `Film.puntoCurva` | r 8 |
| `Film.etichettaPunto` / `etichettaFine` | 17, 700 / 22, 700 |
| `Film.chiusura` | display 56, 700, −1,5 |
| `Film.firma` | 18, opacità 0,75 |
| `Film.avvertenza` | 12, opacità 0,5, larghezza massima 560, interlinea 1,5 |
| `Film.sottotitolo` | 17, 500, a 22 dal fondo, ombra 0 2 8 rgba(0,0,0,.6) |
| `Film.comandi` | 10 sotto lo schermo, spazio 12; pulsante tondo 38; barra alta 6 raggio 9; tempo largo 84 |
| `Film.tileEsporta` | larga 240, su `Colore.cardPiena`; bordo verde `rgba(47,163,90,.4)` quando è pronto |

**Formato del video (proposta, D-F2):**
- contenitore **MP4** (`AVFileType.mp4`), video **H.264** (`AVVideoCodecType.h264`, profilo High,
  `AVVideoProfileLevelH264HighAutoLevel`), **1920×1080**, **30 fotogrammi al secondo**, circa **4 Mbit/s** (`AVVideoAverageBitRateKey`):
  20 s ≈ 10 MB, sotto i 16 MB (il limite storico di WhatsApp per i video, da verificare: WhatsApp comprime comunque ciò che riceve); con un minuto ≈ 30 MB, e allora
  2,5 Mbit/s o 1280×720;
- **senza audio** (come dice il template: «senza voce»);
- `shouldOptimizeForNetworkUse = true` (indice all'inizio del file: parte subito sul telefono);
- **nessun metadato** (`writer.metadata = []`): né nome dell'autore, né luogo, né programma;
- spazio colore sRGB / Rec.709 (`AVVideoColorPropertiesKey` con `ITU_R_709_2`);
- nome del file: «Il piano di Giulia.mp4» (spazi ammessi; il template usa i trattini).
- Variante da decidere: **quadrato 1080×1080** o **verticale 1080×1920**, più comodi sul telefono del cliente; il template
  è 16:9.

#### 3.2.3 Movimento

Dentro ogni scena (1287-1288; i tempi partono all'inizio della scena):

| Cosa | Template | Prisma |
|---|---|---|
| Elementi principali (`.fA`) | 900 ms; da opacità 0, y +24, scala 0,97, sfocatura 8; passo 220 ms; (.22,1,.36,1) | **nuovo** `Moto.Film.elemento` (durata 0,90, passo 0,22, spostamento 24, scala 0,97, sfocatura 8, `Curva.uscita`) |
| Secondo tempo (`.fB`) | opacità 0→1 in 700 ms, a 1,5 s | `Moto.Film.secondo` (0,70 / 1,50) |
| Terzo tempo (`.fC`) | opacità 0→1 in 700 ms, a 2,3 s | `Moto.Film.terzo` (0,70 / 2,30) |
| Cifra della scena 2 | contata da 0 in 1100 ms, quartica | `Moto.Numero` (quartica = `Moto.Curva.quartica`) |
| Anelli della scena 1 | 1,4 s, a 350 + i·130 ms | `Moto.Anello` con ritardo base 0,35 |
| Curva della scena 3 | si disegna in 1500 ms dopo 150 ms | `Moto.Linea` |
| Sottotitolo | opacità 0→1 in 600 ms, a 400 ms | `Moto.Film.sottotitolo` (0,60 / 0,40) |
| Cambio di scena | netto (la scena nuova sostituisce la vecchia) | uguale; proposta: dissolvenza incrociata di 0,30 s (D-F3) |
| Durate delle scene | 3,4 / 4,2 / 4,2 / 4,8 / 3,6 s | `Moto.Film.durate` |
| Barra dell'esportazione (template) | 1,8 s, (.4,0,.2,1) | nell'app la barra segue **l'avanzamento vero** della codifica, con `Moto.Curva.backup` (.4,0,.2,1) solo per ammorbidire |

**Un solo disegno per anteprima, video e istantanee.** Il film non si anima con le animazioni di SwiftUI ma con una
funzione pura del tempo: `DisegnoFilm.disegna(in: CGContext, dimensione:, scena:, t:, dati: DatiFilm)` che disegna il
fotogramma all'istante `t` (con le curve del tema calcolate a mano: quartica, `Curva.uscita` valutata con la sua
bezier). Così:
- **anteprima nel palco**: `TimelineView(.animation(paused: !inRiproduzione))` + `Canvas { contesto, _ in
  contesto.withCGContext { DisegnoFilm.disegna(...) } }` (macOS 12+; non è un Timer: è il ritmo del display di SwiftUI);
- **video**: lo stesso disegno, fotogramma per fotogramma (§2.5);
- **istantanee**: `t` = fine di ogni scena (stato finale: cifre complete, anelli pieni, curva tracciata).

**Riduci movimento** (`\.prismaCalmo`): nell'anteprima ogni scena compare già ferma nel suo stato finale, con una
dissolvenza di 0,15 s fra le scene; il film va avanti con le stesse durate. **Il video esportato resta animato**: è un
contenuto per il cliente, non l'interfaccia del consulente (D-F3).
**Istantanee**: anteprima ferma sulla scena scelta, nello stato finale; comandi con il tempo «0:20 / 0:20» e la tile
«pronto» se la scena lo chiede.

#### 3.2.4 Interazioni

- **Apertura**: il film parte da solo (nel template sì). Proposta: parte da solo **solo se** il palco è stato aperto con un
  clic (non al ritorno da un'altra app), e mai in modalità «Riduci movimento» (lì parte fermo sulla prima scena).
- **❚❚ / ▶︎**: pausa e riproduzione; a fine film ▶︎ riparte da capo. **Spazio** fa lo stesso quando il palco è a fuoco.
- **Barra**: nel template non si tocca. Proposta: clic e trascinamento per andare a un punto (←/→ di una scena).
- **«⇩ Esporta il video»**: crea il file (§2.5). Mentre esporta il pulsante diventa «Annulla»; alla fine «Mostra nel
  Finder». Il file si conserva nel dossier (D-F6).
- **«Manda su WhatsApp»** (nel template un toast). Nell'app Prisma **non manda niente**: esporta se serve e apre il
  **foglio di condivisione del sistema** con il file (sul Mac `NSSharingServicePicker`, sull'iPad
  `UIActivityViewController` come `StampaCarta.condividi`); il consulente sceglie WhatsApp (se l'app c'è e offre la
  condivisione), Messaggi, Mail o AirDrop, e il contatto. La prima volta (per cliente) un avviso: «Il video contiene il nome
  di Giulia e le cifre del suo piano. Esce dal Mac con l'app che scegli: lo mandi tu.» Proposta: il pulsante si chiama
  **«Condividi il video…»**, e WhatsApp è una delle scelte (D-F4).
- **«▣ Mostra sul tavolo»**: l'iPad del tavolo riceve oggi solo pagine PNG; proposta minima: la **scena ferma** mostrata in
  quel momento come pagina; il film intero sull'iPad richiede un genere nuovo (`MostraTavolo.Genere.film` con il file
  MP4 cifrato sulla connessione del tavolo), da decidere (D-F7).
- **«✦ Aggiungi al Prisma di Giulia»**: aggiunge il video esportato al file del cliente (parte «Il Prisma del cliente»).
- **Tastiera**: spazio, ←/→, ⌘E esporta (da verificare in `ComandiShell.swift`).

#### 3.2.5 Mappa verso Prisma

**Esiste già:**
- AVFoundation è già usato (Ruby: `Ruby/VoceRuby.swift`, `AscoltoRuby.swift`, `TrascrizioneRuby.swift`;
  `Shell/StatoCopilotaIncontro.swift`): è del sistema, **non è una dipendenza esterna**. Nessun `AVAssetWriter` oggi.
- Logo vettoriale: `GeometriaLogo.tracciato(_:in:)` restituisce un `Path` di SwiftUI, da cui `cgPath` per Core Graphics;
  spicchi `sinistra`, `destra`, `base` (`DesignSystem/LogoPrisma.swift:32-54`).
- Cifre: `MotoreObiettivo.calcola` (`disponibileOggi`, `importoOggi`, `versamentiAttivi`), `Obiettivo.versamentoMensile`,
  `CurvaObiettivo.arrivo(versamento:)`; `MotorePrevidenza.calcola` → `EsitoPianoPrevidenziale.versamentoMancante`,
  `contributiProposte`; `MotoreLineaVita.prepara(...)` + `calcola(_:)` → `EsitoLineaVita.punti`, `allaPensione`
  (`Motori/MotoreLineaVita.swift:109,150`), in euro di oggi.
- Formati: `Formati.euro(_:)` (`Motori/Formati.swift:72`), date italiane in `Ruby/DateItaliane.swift`.
- Condivisione: `AperturaMessaggi.apri(testo:oggetto:canale:cliente:allegati:)` (`Shell/CollegamentiMessaggi.swift:146`)
  apre Mail o Messaggi con l'allegato (Mac: `NSSharingService .composeEmail/.composeMessage`); iOS
  `StampaCarta.condividi(_:nome:)` (`Shell/StampaCarta.swift:262`). Sul Mac **non c'è** ancora un
  `NSSharingServicePicker` (verificato con grep).
- Documenti del cliente: `Documento` (`Dati/Documento.swift`, tipo `.report` = creato da Prisma), cartella
  `Archivio.cartellaDocumenti` (`Dati/Archivio.swift:16`), nel backup.

**Da creare:**
1. `Motori/MotoreFilm.swift` (puro): `DatiFilm` dai motori, con tutto già scritto in testo:
   ```swift
   struct DatiFilm: Equatable, Sendable {
       let titolo: String                       // «Il piano di Giulia»
       let data: String                         // «novembre 2026» (oggi)
       let obiettivi: [(nome: String, quota: Double, colore: ColoreFilm)]   // fino a 3, quota = disponibileOggi/importo, 0…1
       let versamento: (cifra: Double, obiettivo: String)?                 // obiettivo principale
       let pensione: Double?                    // + X € per la pensione (contributi delle proposte /12 o versamento mancante, D-F8)
       let curva: [Double]                      // EsitoLineaVita.punti fino all'età di pensione, euro di oggi
       let arrivo: (indice: Int, testo: String)?            // «ottobre 2029 · Anticipo casa»
       let fine: (eta: Int, valore: Double)?
       let firma: String                        // secondo il canale (D-F5)
       let avvertenza: String                   // testo approvato (D-F9)
       let durate: [Double]                     // Moto.Film.durate, senza le scene vuote
   }
   enum MotoreFilm { static func dati(cliente:, posizioni:, obiettivi:, analisi:, eventi:, oggi:) -> DatiFilm? }
   ```
   Una scena senza dati **si salta** (niente anelli finti, niente cifre a zero): §2.6.
2. `Shell/DisegnoFilm.swift` (senza SwiftUI, solo Core Graphics e Core Text, quindi **utilizzabile fuori dal thread
   principale**): `disegna(in:dimensione:scena:t:dati:)`. Testo con `CTLine`/`CTFramesetter` e il carattere di sistema
   (`CTFontCreateUIFontForLanguage` o `NSFont.systemFont`/`UIFont.systemFont` con i pesi del tema); anelli con `addArc`;
   curva con il tracciato tagliato alla lunghezza (calcolata una volta per scena); sfocatura d'entrata: nel video un
   `CGContext` non sfoca, quindi si approssima con opacità e scala (nell'anteprima uguale, per restare identica).
3. `Shell/RegistaFilm.swift`: la codifica, **senza dipendenze esterne**:
   - `AVAssetWriter(outputURL:fileType: .mp4)`; `AVAssetWriterInput(mediaType: .video, outputSettings: [codec H.264,
     1920×1080, bitrate, profilo, colore])`, `expectsMediaDataInRealTime = false`;
   - `AVAssetWriterInputPixelBufferAdaptor` con `kCVPixelFormatType_32BGRA`, 1920×1080; un **solo pool** di
     `CVPixelBuffer` (`adaptor.pixelBufferPool`), per ogni fotogramma: `CVPixelBufferLockBaseAddress`, un `CGContext`
     sul buffer (sRGB, `premultipliedFirst | byteOrder32Little`), `DisegnoFilm.disegna` con la scala 2,1818, sblocco,
     `append(_:withPresentationTime: CMTime(value: i, timescale: 30))`;
   - il ciclo gira in un `Task.detached(priority: .utility)` con `autoreleasepool` a ogni fotogramma e
     `requestMediaDataWhenReady(on:)` su una coda propria: niente lavoro sul thread principale, memoria costante (un
     fotogramma 1920×1080 BGRA = 8 MB, il pool ne tiene pochi); 20,2 s × 30 = 606 fotogrammi;
   - avanzamento pubblicato sul `MainActor` ogni 10 fotogrammi (per la barra), annullabile (`cancelWriting()` e file tolto);
   - `finishWriting` → file in una cartella temporanea dell'app, poi spostato come `Documento` del cliente (D-F6);
   - con «Risparmio energetico» la codifica va avanti con priorità `.background` (più lenta, nessun problema).
   - Tempi attesi su M1: il disegno Core Graphics di una scena così è di pochi millisecondi, la codifica H.264 è
     hardware: **pochi secondi**. Sul runner Intel di GitHub (senza codificatore hardware) VideoToolbox usa quello
     software: più lento ma funziona.
4. `Shell/SalaFilm.swift`: `FilmDelPiano` (palco), `SchermoFilm` (`TimelineView` + `Canvas`), `ComandiFilm`,
   `TileEsportazione`.
5. Condivisione sul Mac: `AperturaMessaggi.condividi(file:)` (nome proposto) con `NSSharingServicePicker(items: [url])`
   mostrato dal pulsante; nessun indirizzo `whatsapp://` né `wa.me` (vedi D-F4).
6. Testi fissi: `Motori/TestiFilm.swift` (titolo, sottotitoli, occhielli, firma, avvertenza).
7. Prova nuova `Prisma --prova-film` (nel workflow, come `--prova-backup`): crea un video di prova dai dati di Giulia,
   lo rilegge con `AVURLAsset` e controlla durata (20,2 s ± 1 fotogramma), dimensioni 1920×1080, codec `avc1`, 30 fps,
   nessuna traccia audio, nessun metadato, dimensione sotto 16 MB; salva 5 PNG (un fotogramma finale per scena) accanto
   alle istantanee, così si vede **il video vero** nelle anteprime. Va aggiunta una riga `"$APP/Contents/MacOS/Prisma"
   --prova-film` in `.github/workflows/build.yml` accanto a `--prova-backup` (riga 127). Rischio da segnalare: il runner
   `macos-15-intel` è una macchina virtuale; se VideoToolbox non offre il codificatore H.264, la prova deve dire «codificatore
   non disponibile» in chiaro (non un errore muto), e si decide se in quel caso la build resta verde. `Motori/ProvaCalcoliFilm.swift`: scene saltate senza
   obiettivi, quote limitate a 0…1, curva in euro di oggi, etichetta dell'arrivo dentro l'area.

#### 3.2.6 Dati che l'utente deve dare e stati vuoti

Dati del cliente (mai inventati): almeno un obiettivo (scene 1 e 2), data di nascita e Analisi 360 › Previdenza (scena 3
e pensione della scena 2), proposte o versamenti previsti (scena 2).

- **Nessun obiettivo**: si saltano le scene 1 e 2; il film va dal titolo alla curva. Sotto i comandi: «Senza obiettivi il
  film mostra solo il futuro del patrimonio».
- **Manca la data di nascita o la previdenza**: si salta la scena 3; nota «Completa l'anagrafica e la previdenza per la
  curva del futuro».
- **Restano solo titolo e chiusura**: niente film. Al posto dello schermo: «Per il film servono almeno un obiettivo o la
  linea della vita di Giulia.» con i collegamenti al dossier.
- **Nessun versamento previsto**: nella scena 2 resta solo la pensione (se c'è); se manca anche quella la scena si salta.
- **Esportazione non riuscita** (disco pieno, codificatore non disponibile): la tile diventa rossa con il motivo e
  «Riprova».
- **Il film cambia se cambiano i dati**: un video già esportato porta la data; se i dati sono cambiati dopo, la tile dice
  «Il piano è cambiato dopo il 5 novembre: esporta di nuovo».
- **Dati di prova**: etichetta «dati di prova» sotto lo schermo; un video dei dati di prova porta la scritta «DATI DI
  PROVA» in un angolo del video stesso.

#### 3.2.7 Istantanee da aggiungere

Serie proposta **644-648** (da riconciliare con le altre parti di Luce), tutte con l'anteprima ferma nello stato finale:

| Nome | Scena |
|---|---|
| `644-sala-film-titolo` (+ `-scuro`) | scena 0 e comandi a «0:00 / 0:20» |
| `645-sala-film-oggi` (+ `-scuro`) | scena 1, anelli pieni, sottotitolo |
| `646-sala-film-ogni-mese` | scena 2, cifra completa |
| `647-sala-film-futuro` (+ `-scuro`) | scena 3, curva tracciata, etichette dentro l'area |
| `648-sala-film-esportato` (+ `-scuro`) | scena 4 e tile «✓ Il piano di Giulia.mp4 · 20 secondi · senza voce · pronto» |
| `648-sala-film-vuoto` | Andrea senza obiettivi né data di nascita: lo stato vuoto (stesso numero di `648-sala-film-esportato`, come già `609-inquadra-iphone` e `609-posizioni-inquadra-calma`; se si vogliono numeri unici, va spostata nel primo numero libero dopo la serie di Luce) |

Più i 5 fotogrammi del **video vero** da `--prova-film` (`film-1.png` … `film-5.png`), pubblicati con le anteprime.
Aggiornare la vetrina «400-vetrina-apple» se nasce un componente riusabile (comandi del film) e la pagina online delle
anteprime.

#### 3.2.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole toccate: «Tutto resta in locale sul Mac: niente server, niente cloud»; «I dati dei clienti… mai inviati a servizi
esterni»; «Nessuna dipendenza esterna senza chiedere»; canale sempre riconoscibile; logo (bianco sugli scuri); valori nel
tema; movimento (niente Timer); memoria (8 GB).

**Questa funzione fa uscire dati del cliente dal Mac**: un video con il nome, le percentuali degli obiettivi, i versamenti
e il patrimonio futuro, mandato con **WhatsApp**, un servizio di terzi (Meta). WhatsApp cifra i messaggi da capo a capo, ma
il video resta nel telefono del cliente, nei backup della chat (iCloud o Google Drive, non sempre cifrati) e può essere
inoltrato. Decisioni:

- **D-F1 · Durata.** «Un minuto» (scheda, Novità) o 20 secondi (scene)? Proposta: **20 secondi** e il testo della scheda
  diventa «Venti secondi da mandare dopo l'incontro»; un minuto chiederebbe scene in più che il template non disegna.
- **D-F2 · Formato.** 16:9 1920×1080 H.264 30 fps 4 Mbit/s senza audio (proposta), oppure quadrato o verticale per il
  telefono.
- **D-F3 · Movimento.** Il video esportato resta animato anche con «Riduci movimento» acceso sul Mac? Proposta: sì.
  Dissolvenza incrociata di 0,30 s fra le scene invece del taglio netto?
- **D-F4 · WhatsApp e invio.** Prisma non spedisce mai (come Messaggi, `AperturaMessaggi`): apre il foglio di condivisione
  e il consulente sceglie l'app e il contatto. Da approvare: (a) WhatsApp fra le vie possibili, **solo tramite il foglio di
  condivisione** (nessun numero del cliente passato da Prisma a WhatsApp, nessun indirizzo `wa.me`, che passerebbe da
  internet); (b) il nome del pulsante («Manda su WhatsApp» del template o «Condividi il video…»); (c) l'avviso alla prima
  condivisione; (d) se serve il **consenso del cliente** a ricevere comunicazioni su WhatsApp (oggi `Consensi` ha solo
  `privacy` e `marketing`, `Dati/Modelli.swift:333-337`): proposta, una casella «accetta comunicazioni con WhatsApp» nel
  dossier, e il pulsante avvisa se manca. Orizzonte aveva escluso WhatsApp dai canali dei messaggi
  (`template-novita-specifica.md` §5, righe 2097 e 5244): qui va riaperta la scelta.
- **D-F5 · Firma e canale.** La chiusura del template firma sempre «Denis Vicenzoni · Consulenza finanziaria» (cuoio,
  indipendente). Per un cliente con prodotti Alleanza la regola del canale chiede l'etichetta Alleanza con il logo: ma un
  video con il **logo Alleanza** mandato al cliente è materiale promozionale che probabilmente Alleanza deve approvare.
  Proposta: firma secondo i canali del cliente (`Cliente.canali`), con il solo nome e il colore del canale finché l'utente
  non conferma l'uso del logo.
- **D-F6 · Dove resta il video.** Proposta: come `Documento` del cliente (tipo `.report`, «Il film del piano · novembre
  2026»), così si sa che cosa ha ricevuto e quando; entra nei backup (circa 10 MB a video: con 8 copie di rotazione pesa).
  Alternativa: file temporaneo cancellato dopo la condivisione.
- **D-F7 · Il film sull'iPad del tavolo.** Solo la scena ferma (nessun cambio di protocollo) o il video intero (genere
  nuovo del protocollo del tavolo)?
- **D-F8 · «+ X € per la pensione».** Nel template è il versamento che coprirebbe il divario (`versPens`). Proposta: i
  contributi delle **proposte** previdenziali al mese (`contributiProposte / 12`); se non ci sono proposte, la riga non
  c'è (non si mostra un consiglio come se fosse il piano).
- **D-F9 · Avvertenza.** «Stime basate su ipotesi: non sono promesse né garanzie di risultato. Il dettaglio è nei
  prospetti consegnati.» è un testo normativo-commerciale: lo deve confermare l'utente (e Alleanza per i clienti del canale);
  un video «promozionale» per i prodotti assicurativi può richiedere avvertenze in più che **non si possono inventare**.
- **D-F10 · Carattere nel video.** Il video usa il carattere di sistema (SF), come già i PDF di Prisma. Da confermare che va
  bene in un file dato al cliente.
- **Nessun Ruby nel film** (proposta): sottotitoli fissi di Prisma. Se l'utente vuole un testo d'accompagnamento per il
  messaggio, lo scrive Ruby come i messaggi di «Prisma scrive per te» (`MessaggiRuby`), con le stesse regole.
- **API**: `AVAssetWriter`, `AVAssetWriterInputPixelBufferAdaptor`, `NSSharingServicePicker`, `TimelineView`, `Canvas`
  ci sono tutte su macOS 13 (e iOS 16): **nessuna protezione `#available` necessaria**. Nessuna dipendenza esterna.
  Niente voce (la voce clonata di `~/EveVoce` non si tocca e non si usa).

---

### 3.3 Disegna il tuo futuro

*Davanti al cliente · voce `NOV15[4]` «Disegna il tuo futuro» · «Lo scarabocchio diventa un piano» →
`apriEsp('disegna',0)` · scheda della Sala `ESP[4]`, colore #30B15C, glifo curva con matita (`GL.disegna`, 1202) ·
`ESPH.disegna` / `ESPM.disegna` (1298-1322)*

Il cliente disegna con il dito (sull'iPad) o con il mouse (sul Mac) come vorrebbe che crescesse il suo patrimonio, da oggi
a 90 anni. Al rilascio Prisma trasforma il disegno nella curva del piano di oggi, poi confronta le due alla pensione e dice
quanto servirebbe in più al mese. Il disegno si può salvare come obiettivo.

#### 3.3.1 Cosa si vede

**La tela** (`#disC`, 1299): a 24/22 nel palco, **900×520**, raggio 16, fondo `--chip`, cursore a croce,
`touch-action:none` (il dito non scorre la pagina). Dentro (disegnato su canvas, 1302-1304):
- margini: 60 a sinistra (`L`), 40 in basso (`B`), 20 a destra e in alto;
- **assi**: righe verticali ogni 10 anni (da 40 a 90) con **«40 anni»**, **«50 anni»** … sotto, e 5 righe orizzontali
  (0, ¼, ½, ¾, massimo) con le cifre in migliaia a sinistra (**«0k»**, **«354k»**, **«708k»**, **«1062k»**, **«1416k»**);
  testo 12 pt peso 500 `--ink3`, righe `--sep`. Il massimo dell'asse y è **2,1 volte** il massimo della curva possibile;
- il **punto di partenza**: cerchio viola (#8B5CF6) r 6 all'età di oggi e al patrimonio di oggi;
- **vuota**: la scritta **«Disegna qui, partendo dal punto viola →»** (18 pt, 600, `--ink3`), 20 a destra e 24 sopra il
  punto.

**Mentre disegna** (`stato='disegno'`): il tratto viola #8B5CF6, spessore 4, estremi e giunzioni arrotondati. Si accettano
solo punti che vanno **verso destra** (un punto più a sinistra di 2 rispetto all'ultimo si scarta, 1316).

**Al rilascio** (`stato='morph'`, 1317-1318): il disegno resta come **fantasma** (viola al 45%, spessore 3, tratteggio 7/7);
una curva **verde** (#30B15C, spessore 4,5) parte dal disegno e in 1,3 s **si trasforma** nella curva del piano di oggi
(«feasible», la `proiezione` della linea della vita, 1300); un punto verde r 6 sull'età di pensione segue la curva.
Il disegno vale da oggi fino a 90 anni: prima del primo punto vale il primo punto, dopo l'ultimo l'ultimo (`disegnata`, 1309).
Nota sul fantasma: il template lo traccia due volte (1312), pieno e poi tratteggiato 7/7, entrambi viola al 45%: a schermo sembra una linea continua con trattini più scuri. Nell'app: solo tratteggiato (`Disegno.fantasma`), da confermare guardando `03-disegna-risultato-*.png`.

**La colonna di destra** (da 950 a 28 dal bordo, 26 sopra, 24 sotto):
- **«Disegna come vorresti che crescesse il tuo patrimonio.»** (display 26, 700, −0,5, interlinea 1,2);
- 8 sotto, `.k` a 14 con interlinea 1,5: **«Con il dito sull'iPad, o con il mouse qui, da sinistra a destra. Prisma lo
  trasforma nel piano che si può fare davvero.»**;
- 18 sotto, il risultato (`#disR`, 1318-1320), dopo la trasformazione:
  - tile **«Il tuo disegno, a 67 anni»** con la cifra `.v` viola (#8B5CF6) contata;
  - tile **«Il piano di oggi, a 67 anni»** con la cifra `.v` verde contata (10 sopra);
  - 14 sotto, display 20 700 interlinea 1,3: **«Per arrivare al tuo disegno servono circa 230 € in più al mese.»** oppure
    **«Il tuo disegno è già alla portata del piano di oggi.»**;
  - 6 sotto, `.k`: **«Stima con un rendimento del 2,5% l'anno, non garantito.»**;
- in fondo, spazio 8: **«↻ Ricomincia»** (`.btn.big`) e **«Salva come obiettivo»** (`.btn.pri.big`).

Il calcolo del template (`risultato`, 1319): `extra = max(0, round((disegno − piano) / (12 × ((1,025ⁿ − 1)/0,025)) / 10) × 10)`, con n = anni
fino alla pensione: il versamento mensile costante che, al 2,5% annuo, accumula la differenza.

**Testata del palco**: tassello #30B15C, **«Disegna il tuo futuro»**, «· Giulia Rossi», **«▣ Mostra sul tavolo»** e **«✦
Aggiungi al Prisma di Giulia»**.

**Stati del template**: vuota → disegno → trasformazione → risultato. Un tratto di meno di 4 punti torna «vuota» (1317).
«Ricomincia» torna a vuota. «Salva come obiettivo» fa un toast **«Nuovo obiettivo salvato nel dossier di Giulia Rossi»**.

**Difetti del template da non copiare:**
- il confronto guarda **solo l'età di pensione**: un disegno più alto dopo la pensione (`03-disegna-risultato-scuro.png`:
  il tratto sale fino a 90 anni) risulta «già alla portata» se a 67 anni è sotto il piano. Nell'app: si confronta alla
  pensione, ma se il disegno dopo la pensione sta sopra la curva del piano si aggiunge la frase «Dopo la pensione il tuo
  disegno chiede più di quanto il piano lascia: ne parliamo» (nessuna cifra in più);
- l'asse y in «k» non è italiano: nell'app «0 €», «350 mila», «1,4 milioni» (`Formati.euroBreve`);
- l'asse arriva sempre a 2,1 volte il possibile: chi vuole disegnare più in alto non può. Proposta: 2,1 volte, ma il
  massimo cresce di un gradino se il tratto tocca il bordo alto;
- il rendimento è fisso al 2,5% nominale; nell'app è il **rendimento reale** della linea della vita (`IngressoLineaVita.rendimentoReale`,
  dall'Analisi 360; 1,5 è solo il valore iniziale di `IpotesiPrevidenza.rendimentoReale`) e la frase lo dice con la cifra vera
  («Stima in euro di oggi con un rendimento reale del {rendimentoReale}% l'anno, non garantito»);
- il colore della curva possibile è un verde diverso (#30B15C) da `--green` (#2FA35A): è `Colore.anello1`.

#### 3.3.2 Misure e stile

Token esistenti: `Colore.chip` (fondo della tela), `Colore.inchiostro3` (scritte), `Colore.separatore` (righe),
`Colore.stima` (#8B5CF6, disegno e punto di partenza), `Colore.anello1` (#30B15C, curva possibile), `Carattere.valore`,
`Carattere.secondario`, `Superficie.tile`, `StilePulsanteApple`, `Tema.Apple.Grafico.Tracciato` (spessori e tratteggi
della linea della vita, `Tema.Apple+LineaVita.swift:52-57`).

Token **nuovi** in `Tema.Apple.SalaRacconti.Disegno`:

| Nome proposto | Valore |
|---|---|
| `Disegno.tela` | 900×520 a 24/22, raggio 16 |
| `Disegno.margini` | sinistra 60, basso 40, destra 20, alto 20 |
| `Disegno.scalaMassimo` | 2,1 |
| `Disegno.passoAnni` | 10; `righeOrizzontali` 5 |
| `Disegno.scrittaAssi` | 12, 500 |
| `Disegno.invito` | 18, 600; scostamento 20/−24 dal punto |
| `Disegno.puntoPartenza` / `puntoPensione` | r 6 |
| `Disegno.tratto` | 4, estremi e giunzioni tondi |
| `Disegno.fantasma` | opacità 0,45, spessore 3, tratteggio [7, 7] |
| `Disegno.curvaPossibile` | spessore 4,5 |
| `Disegno.colonna` | da x 950, 28 dal bordo destro, 26 sopra, 24 sotto |
| `Disegno.titolo` | display 26, 700, −0,5, interlinea 1,2 |
| `Disegno.spiegazione` | 14, interlinea 1,5 |
| `Disegno.frase` | display 20, 700, interlinea 1,3 (= `Carattere.meseAgenda` 20 bold + interlinea) |
| `Disegno.scartoIndietro` | 2 (punti più a sinistra scartati) |
| `Disegno.puntiMinimi` | 4 |

#### 3.3.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Tratto | segue il puntatore, ridisegno a ogni movimento | `Canvas` con i punti in `@State`; nessuna animazione |
| Trasformazione | 1,3 s, quartica (`ease`), la curva verde passa dal disegno al piano | **nuovo** `Moto.Disegno.trasformazione = 1.30` con `Moto.Curva.quartica`; la curva è uno `Shape` `Animatable` con `animatableData` = avanzamento 0…1 (interpolazione punto per punto fra le due serie): niente Timer, niente `requestAnimationFrame` |
| Risultato | cascata `.st` e numeri contati (`entrata`, `conteggi`, 1320) | `Moto.Cascata` (base 0), `Moto.Numero` |
| Ricomincia | tutto sparisce subito | uguale |

- **Riduci movimento**: il template trasforma lo stesso (la trasformazione non guarda `ridotto`). Nell'app: la curva del
  piano compare subito, con il fantasma, in dissolvenza di 0,15 s; il risultato compare fermo.
- **Istantanee**: un tratto di prova fisso (§3.6) e lo stato finale (fantasma, curva verde, punto, risultato completo).

#### 3.3.4 Interazioni

- **Mac**: trascinamento con il mouse o il trackpad sulla tela (`DragGesture(minimumDistance: 0)` in coordinate della
  tela); il cursore a croce (`NSCursor.crosshair` con `.onHover`).
- **iPad del tavolo**: il template dice «con il dito sull'iPad». Oggi il protocollo del tavolo va dall'iPad al Mac solo con
  `ciao`, `valoreCursore` e `presaVisione` (`Tavolo/ProtocolloTavolo.swift:144-176`). Per disegnare sull'iPad serve un
  messaggio nuovo `tratto(TrattoTavolo)` con i punti **normalizzati** (0…1, nessun dato del cliente) e un genere nuovo
  `MostraTavolo.Genere.disegno` (assi e punto di partenza già scalati); il Mac calcola e rimanda l'immagine del risultato.
  Proposta: **prima fase solo sul Mac** (anche girando lo schermo, con la modalità cliente); l'iPad in una seconda fase (D-D3).
- **Rilascio**: con meno di 4 punti torna vuota; altrimenti trasformazione e risultato.
- **Un secondo tratto** sopra il risultato riparte da capo (nel template il `pointerdown` cancella il risultato, 1315).
- **«↻ Ricomincia»**: torna vuota.
- **«Salva come obiettivo»**: apre il piccolo modulo dell'obiettivo già compilato (non salva in silenzio): titolo
  **«Il patrimonio che ho disegnato»** (modificabile), area `pensione`, importo = il disegno all'età di pensione (euro di
  oggi), scadenza = il giorno in cui compie l'età di pensione, versamento mensile = il «in più al mese» (modificabile);
  «Salva» lo aggiunge al dossier con il toast «Nuovo obiettivo nel dossier di Giulia». Se un obiettivo con lo stesso
  titolo c'è già, propone di aggiornarlo.
- **«▣ Mostra sul tavolo»**: l'immagine della tela e del risultato.
- **«✦ Aggiungi al Prisma di Giulia»**: il disegno e la curva del piano, fermi, nel file del cliente.
- **Tastiera**: ⌫ = Ricomincia; ⏎ = Salva come obiettivo (con il modulo).
- **VoiceOver**: la tela ha un'etichetta («Tela per disegnare il patrimonio da 37 a 90 anni»), e il risultato si legge
  come testo; chi non può disegnare usa la linea della vita del dossier.

#### 3.3.5 Mappa verso Prisma

**Esiste già:**
- Curva possibile: `MotoreLineaVita.prepara(cliente:posizioni:obiettivi:eventi:...)` → `PreparazioneLineaVita.ingresso`
  e `MotoreLineaVita.calcola(_:)` → `EsitoLineaVita.punti` da oggi a `etaFine` (90), in euro di oggi, `etaPensione`,
  `allaPensione` (`Motori/MotoreLineaVita.swift:26-150`); `rendimentoReale` in `IngressoLineaVita`. Eventi del cliente:
  `EventoLineaVita` (`Dati/EventoLineaVita.swift`, `DatiPrisma.eventiVita`). Stato già esistente:
  `Shell/StatoLineaVita.swift`, vista `Shell/DossierLineaVita.swift`, token `Tema.Apple+LineaVita.swift`.
- Obiettivo: `Obiettivo(clienteId:titolo:area:importo:scadenza:)`, `versamentoMensile`, `note`
  (`Dati/Prodotti.swift:172-199`); `AreaBisogno.pensione` (`Dati/Bisogni.swift:5`); `AppObiettivi`, `ClienteObiettivi`,
  `DossierObiettivi` per il modulo.
- Formati: `Formati.euroBreve(_:)` (`Motori/Formati.swift:93`).

**Da creare:**
1. `Motori/MotoreDisegno.swift`, puro:
   ```swift
   struct TrattoDisegno: Equatable { var punti: [CGPoint] }           // in coordinate della tela
   struct AssiDisegno: Equatable { let etaOggi, etaFine: Int; let massimo: Double; let area: CGRect }
   struct EsitoDisegno: Equatable {
       let disegno: [Double]          // un valore per età, da etaOggi a etaFine (interpolazione lineare del tratto)
       let possibile: [Double]        // EsitoLineaVita.punti
       let etaPensione: Int
       let alDisegno: Double; let alPiano: Double
       let versamentoInPiu: Double?   // nil se il disegno è alla portata; arrotondato a 10 €
       let sopraDopoPensione: Bool    // il disegno dopo la pensione sta sopra la curva possibile
   }
   enum MotoreDisegno {
       static func assi(_ esito: EsitoLineaVita, area: CGRect) -> AssiDisegno
       static func valori(_ t: TrattoDisegno, assi: AssiDisegno) -> [Double]
       static func esito(_ t: TrattoDisegno, ingresso: IngressoLineaVita, assi: AssiDisegno) -> EsitoDisegno
   }
   ```
   **Versamento in più**: siccome `calcola` è lineare nel risparmio annuo, Δ al mese = (disegno − piano alla pensione) /
   (valore alla pensione di 1 € l'anno versato da oggi, con `rendimentoReale`) / 12; si **verifica** ricalcolando
   `calcola` con `risparmioAnnuo + 12·Δ` usando il Δ **non arrotondato** (deve arrivare al disegno entro 1 €; il calcolo è
   affine nel risparmio: `x = x·(1+r) + risparmioAnnuo` solo per `eta < etaPensione`, `MotoreLineaVita.swift:132`). Si mostra
   poi Δ arrotondato a 10 €: con l'arrotondamento il valore alla pensione può scostarsi di qualche centinaio di euro, e la
   prova non deve confrontare quello. Il prelievo in pensione non cambia (`prelievoAnnuo` non dipende dal risparmio).
2. `Shell/SalaDisegna.swift`: `DisegnaIlFuturo` (palco), `TelaDisegno` (`Canvas` + gesto), `CurvaTrasformata`
   (`Shape` + `Animatable`), `RisultatoDisegno`.
3. Opzionale (D-D2): `Obiettivo.disegno: [Double]?` per ridisegnare il fantasma nel dossier.
4. Prove: `Motori/ProvaCalcoliDisegno.swift`: tratto orizzontale (patrimonio fermo) → «alla portata» se il piano cresce;
   tratto altissimo → versamento > 0 e ricalcolo che arriva al disegno; tratto con 3 punti → vuoto; punti all'indietro
   scartati; tratto che non arriva a 90 → l'ultimo valore resta fino a 90.

#### 3.3.6 Dati che l'utente deve dare e stati vuoti

Servono: **data di nascita** (età di oggi), **patrimonio in essere** (punto di partenza), e per la curva possibile i dati
della linea della vita (risparmio, rendimento; il prelievo in pensione viene dall'Analisi 360 se salvata).

- **Manca la data di nascita**: la tela non si apre; al suo posto «Per disegnare il futuro serve la data di nascita di
  Giulia» con «Completa l'anagrafica ›».
- **Nessuna posizione in essere**: si parte da 0 € (il punto viola sull'asse), e sotto il titolo una nota «Il punto di
  partenza è 0 €: Giulia non ha ancora posizioni in essere».
- **La linea della vita non si può calcolare** (`PreparazioneLineaVita.motivoAssente`): si può disegnare, ma al rilascio
  il disegno resta (niente trasformazione) e il risultato dice il motivo di `motivoAssente`.
- **Senza Analisi 360 salvata**: dopo la pensione la curva possibile è solo indicativa (tratteggiata, come nella linea
  della vita: `dopoPensioneIndicativa`).
- **Istantanee e dati di prova**: un tratto fisso per Giulia in `Dati/DatiDemo.swift` (o in `DatiDemoLineaVita.swift`),
  segnato «dati di prova».

#### 3.3.7 Istantanee da aggiungere

Serie proposta **649-652**:

| Nome | Scena |
|---|---|
| `649-sala-disegna-vuota` (+ `-scuro`) | tela vuota con l'invito e il punto viola |
| `650-sala-disegna-risultato` (+ `-scuro`) | tratto di prova sopra il piano: fantasma, curva verde, «servono circa … € in più al mese» |
| `651-sala-disegna-alla-portata` | tratto sotto il piano: «Il tuo disegno è già alla portata del piano di oggi.» |
| `652-sala-disegna-dati-mancanti` | Andrea senza data di nascita |

#### 3.3.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole toccate: principio dell'analisi (questa esperienza è analisi: confronta un desiderio con il piano); valori nel tema;
movimento (`Animatable`, niente Timer). Nessun dato esce dal Mac (salvo «Aggiungi al Prisma» e il tavolo, in rete locale).

- **D-D1 · Che cosa si confronta.** Proposta: il valore alla pensione (come il template) più la frase qualitativa sul dopo
  pensione. Alternativa: confrontare anche il patrimonio a 80 anni.
- **D-D2 · «Salva come obiettivo».** Area `pensione`, importo e scadenza come al §3.4, versamento mensile proposto =
  il «in più al mese»? Conservare il disegno nell'obiettivo (`Obiettivo.disegno`)?
- **D-D3 · iPad del tavolo.** Disegno con il dito sull'iPad (messaggio nuovo nel protocollo del tavolo, punti
  normalizzati, nessun dato del cliente dall'iPad) in una seconda fase?
- **D-D4 · Frase del rendimento.** «Stima in euro di oggi con un rendimento reale dell'X% l'anno, non garantito»: va bene
  come avvertenza davanti al cliente?
- Nessuna API sopra macOS 13 (`Canvas`, `DragGesture`, `Animatable`). Nessuna dipendenza esterna. Ruby non interviene.

---

### 3.4 La capsula del tempo

*Davanti al cliente · voce `NOV15[8]` «La capsula del tempo» · «Un messaggio sigillato fino al traguardo» →
`apriEsp('capsula',0)` · scheda della Sala `ESP[9]`, colore **#9B6FB5**, glifo clessidra (`GL.capsula`, 1204) ·
`CAPS`, `ESPH.capsula`, `busta`, `ESPM.capsula` (1397-1421) · legata ai traguardi festeggiati (1760, 1771, 1775)*

Il cliente scrive un messaggio a sé stesso per il giorno in cui avrà raggiunto un obiettivo. Prisma lo sigilla in una busta
e lo tiene chiuso; quando l'obiettivo è raggiunto, la capsula è «pronta» e il consulente la apre e la consegna, anche
stampata su carta.

#### 3.4.1 Cosa si vede

**Colonna di sinistra** (a 28/24, larga 560, fino a 24 dal fondo; 1399-1403):
- **«Scrivi alla te stessa del giorno in cui ce l'avrai fatta.»** (al maschile **«al te stesso»**, da `GEN`), display 26,
  700, −0,5;
- 6 sotto, `.k` 14: **«Prisma lo sigilla e lo cifra: nessuno lo legge, nemmeno Denis, fino al giorno giusto.»**;
- 14 sotto, il campo di testo (`#capT`): alto al più 230, raggio 16, bordo `--sep`, fondo `--cardE`, padding 16, serif 17
  con interlinea 1,6, senza ridimensionamento; segnaposto **«Perché lo stai facendo? Cosa vuoi ricordarti quel giorno?»**;
- 14 sotto, `.lbl` **«SI APRE QUANDO»**, 8 sotto i **chip** degli obiettivi del cliente (`.chip`, spazio 8, a capo se
  servono); il primo è scelto (`.on2`: fondo #9B6FB5, testo bianco);
- 16 sotto, **«✉︎ Sigilla la capsula»** (`.btn.pri.big`).

**Colonna di destra** (da 620 a 28 dal bordo; 1405-1407):
- `.lbl` **«LE CAPSULE SIGILLATE»** (10 sotto);
- una **tile «pronta»** (`#capPronta`): bordo `rgba(224,138,0,.45)`, fondo `rgba(224,138,0,.08)`, avatar 44 di Sofia,
  **«Sofia Romano · Rendita integrativa»** (15, grassetto), **«Obiettivo raggiunto ieri: è il momento di consegnarla»**
  (13, 600, #B45309), pulsante **«Apri e consegna»** (`.btn.pri`). La tile **pulsa** (`pulsa2`, 2,2 s: un alone di 6 px
  `rgba(224,138,0,.15)` a metà);
- l'elenco (`#capLista`): righe con padding 12/4, filetto `--sep`, spazio 12: avatar 36, **«Giulia Rossi · Anticipo
  casa»** (14, grassetto), sotto in `.k` **«si apre quando l'anticipo è pronto · sigillata a novembre 2025»**, a destra il
  lucchetto 🔒 (18). Esempi del template (`CAPS`, 1398): «si apre a settembre 2036 · sigillata a marzo 2025», «si apre nel
  2037 · sigillata a gennaio 2026».

**Sigillare** («✉︎ Sigilla la capsula», 1410-1414):
1. se il campo è vuoto il template mette un testo di prova (nell'app no: il pulsante è spento finché il campo è vuoto);
2. il testo **vola** dentro la busta (0,8 s, verso +100/+140, scala 0,25, opacità 0) e il campo si nasconde;
3. compare la **busta** (300×200: rettangolo #F6EFE4 bordo #D9CBB6 raggio 10, lembo #EFE4D3) a 130/150;
4. il **lembo si chiude** (ruota sull'asse orizzontale da 180° a 0°);
5. il **sigillo** viola r 26 con il logo di Prisma bianco **si imprime** (da scala 2,2 a 0,9 a 1);
6. la busta **vola via** verso l'elenco (+640/+120, scala 0,15, opacità 0);
7. in cima all'elenco compare la riga nuova **«Giulia Rossi · {obiettivo}» / «si apre quando l'obiettivo è raggiunto ·
   sigillata adesso»** con un lampo viola di fondo; il campo si svuota e torna; toast **«Capsula sigillata e cifrata»**.

**Aprire e consegnare** («Apri e consegna», 1416-1421; anche da «Apri la capsula» nei traguardi festeggiati, 1771/1775):
- un **velo** su tutto il palco (`--scrim` e sfocatura 10) con al centro, in 520×460, la busta arancio (sigillo #E08A00);
- il sigillo si rompe (scala 1→1,3, opacità 0), il lembo si apre, la **lettera sale** dalla busta (foglio 400 largo, alto
  almeno 230, fondo #FFFDF8, testo #2A2622, raggio 6, padding 26/30, ombra `0 20px 40px -14px rgba(0,0,0,.35)`), la busta
  sparisce;
- sul foglio, il sopratitolo **«SIGILLATA A GIUGNO 2025»** (11, 700, spaziatura 1,4, #A08C78) e il testo che si scrive
  due parole alla volta, in serif 17 interlinea 1,6: *«Sofia, lo stai facendo per goderti i nipoti senza pensare ai soldi.
  Se stai leggendo, ce l'hai fatta: adesso goditeli davvero. — Sofia, giugno 2025»*;
- in basso (a 40 dal fondo), **«Stampala su carta per Sofia»** (`.btn.pri.big`) e **«Chiudi»** (`.btn.big`); stampa → toast
  «Capsula stampata su carta, pronta da consegnare».

**Testata del palco**: tassello #9B6FB5, **«La capsula del tempo»**, «· Giulia Rossi»; **né «Mostra sul tavolo» né
«Aggiungi al Prisma»** (1219: la capsula non va né sul tavolo né nel file del cliente).

**Nello scuro**: colonne scure, campo `--cardE` scuro; la busta e il foglio della capsula aperta restano chiari
(`03-capsula-aperta-scuro.png`).

**Difetti del template da non copiare (importanti):**
- **davanti al cliente l'elenco mostra le capsule di altri clienti** (Giulia, Marco, Laura) e la tile «pronta» di Sofia
  anche quando il cliente scelto è Giulia (`CLI[4]` fisso, 1406): è un problema di riservatezza. Nell'app, nella Sala,
  l'elenco mostra **solo le capsule del cliente scelto**; l'elenco di tutte le capsule sta altrove, per il consulente
  (§4.4);
- «nemmeno Denis» è una promessa che dipende da come si cifra (§4.8, D-C1);
- la riga nuova dice sempre «si apre quando l'obiettivo è raggiunto» anche se l'obiettivo ha una data;
- il testo di prova inserito quando il campo è vuoto;
- **«Apri e consegna» apre la capsula di Sofia nel palco di Giulia** (testata «· Giulia Rossi», `03-capsula-aperta-scuro.png`):
  il testo privato di un cliente compare davanti a un altro. Nell'app «Apri e consegna» c'è solo per le capsule del cliente
  scelto, e aprire una capsula di un altro cliente (dai traguardi festeggiati) cambia prima il cliente della Sala.

#### 3.4.2 Misure e stile

Token esistenti: `Colore.cardPiena` (`--cardE`), `Colore.separatore`, `Colore.arancio` (#E08A00), `Carta.ambra` (#B45309,
per «Obiettivo raggiunto ieri»), `Colore.velo` (`--scrim`), `Carattere.etichetta` (`.lbl`), `Carattere.h2`,
`StilePulsanteApple`, avatar (`Misura.Avatar`), `GeometriaLogo` per il sigillo, `SimboloPrisma`.

Token **nuovi** in `Tema.Apple.SalaRacconti.Capsula`:

| Nome proposto | Valore |
|---|---|
| `Capsula.colore` | #9B6FB5 (chip scelto, sigillo, lampo della riga nuova) |
| `Capsula.colonnaSinistra` | a 28/24, larga 560; colonna destra da 620 a 28 dal bordo |
| `Capsula.titolo` | display 26, 700, −0,5 |
| `Capsula.campo` | alto al più 230, raggio 16, padding 16, serif 17 interlinea 1,6 (`Carattere` con `disegno: .serif`, vedi §1.2) |
| `Capsula.chipScelto` | fondo `colore`, testo bianco, bordo trasparente (`.chip.on2`) |
| `Capsula.busta` | 300×200; carta #F6EFE4, bordo #D9CBB6 spessore 2, lembo #EFE4D3, raggio 10 |
| `Capsula.sigillo` | r 26; logo a scala 0,047 della sua geometria (circa 32 di lato), bianco con spicchi a 1 / 0,7 / 0,45 |
| `Capsula.coloreSigilloPronta` | #E08A00 (`Colore.arancio`) |
| `Capsula.pronta` | bordo arancio a 0,45, fondo arancio a 0,08, alone 6 a 0,15 |
| `Capsula.riga` | padding 12/4, spazio 12, avatar 36, lucchetto 18 (SF Symbol `lock.fill` al posto dell'emoji 🔒) |
| `Capsula.foglio` | largo 400, alto almeno 230, padding 26/30, raggio 6, ombra 0 20 40 −14 rgba(0,0,0,.35) (caso nuovo `Tema.Apple.Ombra.foglioCapsula`); sopratitolo 11, 700, spaziatura 1,4 e 10 sopra il testo; colori della lettera (`Lettera.carta`, `Lettera.inchiostro`, `Lettera.sopratitolo`) |
| `Capsula.palcoApertura` | 520×460 al centro |

Nel **PDF** della capsula («Stampala su carta»): `Tema.Apple.Carta`, carta bianca (CLAUDE.md), testo serif,
sopratitolo «SIGILLATA A GIUGNO 2025» in `Carta.etichetta`, il nome del cliente e, in piede, «Aperta il … · Prisma».

#### 3.4.3 Movimento

Sigillare (tempi dal clic; 1410-1414):

| Passo | Template | Prisma (`Moto.Capsula`, nuovo) |
|---|---|---|
| Il testo vola nella busta | 0 → 0,80 s, verso (+100, +140), scala 0,25, opacità 0; (.5,0,.3,1) | `voloTesto = 0.80`, curva `Moto.Curva.finestraChiude` (è proprio (.5,0,.3,1), `TemaAppleMoto.swift:43`) |
| Compare la busta | a 0,50 s, 0,40 s, scala 0,8→1, opacità 0→1 | `entrataBusta = 0.40`, `ritardoBusta = 0.50` |
| Il lembo si chiude | a 0,90 s, 0,60 s, rotazione X 180°→0°; (.4,0,.2,1) | `lembo = 0.60`, `ritardoLembo = 0.90`, `Moto.Curva.backup` (.4,0,.2,1) |
| Il sigillo si imprime | a 1,50 s, 0,52 s, scala 2,2 → 0,9 → 1, opacità 0→1; (.34,1.6,.64,1) | `sigillo = 0.52`, `ritardoSigillo = 1.50`, `scalaSigillo = 2.2`; la stessa bezier del template è già resa in Prisma con `Moto.molla` (.34,1.45,.64,1: `Moto.LineaVita.rimbalzo` la usa per il (.34,1.6,.64,1) del gettone). Il tema dice che dove una bezier con y > 1 non va bene si usa `Moto.Molla` (`TemaAppleMoto.swift:54`, §5.3): proposta **`Moto.Capsula.sigilloMolla = Molla(risposta: 0.52, smorzamento: 0.55)`**, da tarare guardando il template; niente `Curva` nuova con y 1,6 |
| La busta vola via | a 2,30 s, 0,70 s, verso (+640, +120), scala 0,15, opacità 0; (.5,0,.3,1) | `voloBusta = 0.70`, `ritardoVolo = 2.30` |
| Riga nuova | a 2,95 s, 0,90 s, da y −16 e opacità 0, lampo viola a 0,25 che svanisce; `Curva.uscita` | `rigaNuova = 0.90`, `ritardoRiga = 2.95` |
| Toast | «Capsula sigillata e cifrata» | `Moto.Toast` |

Aprire (1416-1420; tempi dal clic: tutto ciò che segue il velo è dentro un `setTimeout` di 400 ms): velo 0,30 s; a 0,40 s il
sigillo si rompe (0,40 s, scala 1→1,3, opacità 0); a 0,70 s il lembo si apre (0,60 s, `Curva.backup`); a 1,20 s la lettera
sale (0,90 s, da y +60 e opacità 0 a y −120; `Curva.uscita`); a 1,70 s la busta svanisce (0,60 s); a **2,10 s** il testo si
scrive (`split(/(\s+)/)` e `i+=2` ogni 40 ms: **una parola ogni 40 ms**, `Moto.Capsula.passoParola = 0.04` s, con
`TimelineView`/`Animatable`, niente Timer). Chiudere: dissolvenza 0,25 s (nuovo `Moto.Capsula.chiusura = 0.25`; lo stesso
valore di `Moto.Sala.durataChiusura`, che però è della Sala della **presentazione** (`TemaAppleMoto.swift:465`): non va
riusato per nome, per non legare le due Sale).
La tile «pronta» pulsa in 2,2 s all'infinito (`repeatForever` di SwiftUI su ombra e alone: `Moto.Capsula.pulsazione = 2.2`).

- **Riduci movimento** (il template riduce a 1 ms quasi tutti i passi, 1411-1414): nell'app sigillare = il campo si
  svuota e la riga nuova compare in dissolvenza di 0,15 s, con il toast; aprire = il foglio compare già aperto con il
  testo intero, in 0,15 s; niente pulsazione (la tile «pronta» resta con il bordo arancio).
- **Istantanee**: elenco fermo; capsula aperta già con il foglio fuori e il testo intero; nessuna pulsazione.

#### 3.4.4 Interazioni

- **Scrivere**: il cliente scrive sul Mac del consulente (nel template; la capsula non va sul tavolo). Proposta da
  decidere (D-C4): scrivere sull'**iPad del tavolo**, dove il consulente non vede lo schermo, con un messaggio nuovo del
  protocollo del tavolo (il testo viaggia cifrato in rete locale e si sigilla sul Mac). La **dettatura** del sistema
  resta possibile nel campo: va detto (§4.8).
- **Si apre quando**: i chip degli obiettivi del cliente (uno solo); proposta: anche **«In una data…»** (un selettore di
  data), perché il template elenca capsule «si apre nel 2037». Senza obiettivi c'è solo la data.
- **«✉︎ Sigilla la capsula»**: spento con il campo vuoto. Prima di sigillare una conferma breve: «Dopo il sigillo il
  messaggio non si può rileggere né correggere fino al giorno giusto.» (Sigilla / Annulla).
- **Riga dell'elenco**: nessuna azione nel template. Proposta: menu contestuale «Cambia quando si apre» (l'obiettivo può
  sparire o cambiare) e «Elimina la capsula» (con conferma; il testo si distrugge senza essere letto).
- **«Apri e consegna»**: solo per le capsule **pronte**. Apre l'animazione; il testo si decifra in quel momento. La capsula
  passa da «pronta» ad «aperta il …».
- **«Stampala su carta per {nome}»**: PDF su carta bianca (`StampaCarta`), stampa o salva; la capsula diventa
  «consegnata il …». Proposta in più: «Condividi…» con il foglio di condivisione (il PDF al cliente, se lo vuole).
- **«Chiudi»**: chiude il velo. **Esc** fa lo stesso.
- **Dai traguardi festeggiati**: «Apri la capsula» porta qui con il cliente giusto (`apriEsp('capsula', 4)`, 1775) e apre
  direttamente la consegna.
- **Fuori dalla Sala** (proposta, per il consulente e non davanti al cliente): nel dossier del cliente, scheda Obiettivi,
  ogni obiettivo con una capsula mostra il lucchetto e lo stato («sigillata a novembre 2025»); in Notifiche, «La capsula di
  Sofia è pronta». Il testo non si vede mai lì.
- **Modalità cliente**: la Sala mostra solo il cliente in modalità; nessun nome di altri clienti.

#### 3.4.5 Mappa verso Prisma

**Esiste già:**
- Cifratura: `CifraturaBackup` (`Dati/CifraturaBackup.swift`) con AES-256-GCM a segmenti e PBKDF2 (algoritmo 1, password
  del backup) e HKDF per una chiave per uso (algoritmo 2, «Prisma ovunque»: `chiaveSpazio`, `cifra(_:chiave:uso:)`,
  `decifra(_:chiave:uso:)`, `casuali(_:)`, righe 52-348); Portachiavi: `PortachiaviBackup`, `PortachiaviOvunque`
  (`Dati/PortachiaviBackup.swift`, `Dati/PortachiaviOvunque.swift`). CryptoKit è del sistema.
- Obiettivi e avanzamento: `Obiettivo` (`Dati/Prodotti.swift:172`), `MotoreObiettivo.calcola` → `disponibileOggi`,
  `importoOggi`, `copertura` (`Motori/MotoreObiettivo.swift:27-60`).
- Genere per «alla te stessa / al te stesso»: `MotoreAree360.femminile(_:)`.
- Notifiche: `Notifica` e `MotoreNotifiche.calcola(_:oggi:)` (`Shell/Notifiche.swift:5,42`); `apriNotifica(_:)`.
- Stampa su carta: `StampaCarta.pdf(_:)`, `DocumentoStampabile`, `StampaCarta.stampa(_:formato:)`.
- Archivio e backup: `DatiPrisma` (`versioneAttuale = 26`, `Dati/DatiPrisma.swift:113`), `Backup.swift`, prove
  `Dati/ProvaBackup*.swift`; «Prisma ovunque»: l'istantanea esclude già documenti, conversazioni di Ruby e trascrizioni.

**Da creare:**
1. `Dati/CapsulaTempo.swift`:
   ```swift
   struct CapsulaTempo: Identifiable, Codable, Equatable {
       enum Apertura: Codable, Equatable { case obiettivo(id: String); case data(Date) }
       enum Stato: String, Codable { case sigillata, aperta, consegnata }   // «pronta» si calcola, non si salva
       var id = "capsula-\(UUID().uuidString.prefix(8).lowercased())"
       var clienteId: String
       var apertura: Apertura
       var titoloObiettivo: String       // copia del titolo al sigillo: se l'obiettivo sparisce, la capsula resta leggibile nell'elenco
       var sigillataIl: Date
       var sigillo: Data                 // il testo cifrato (AES-256-GCM), mai in chiaro nell'archivio
       var schemaSigillo = 1             // versione del formato
       var stato = Stato.sigillata
       var apertaIl: Date?
       var consegnataIl: Date?
   }
   ```
   `DatiPrisma.capsule: [CapsulaTempo] = []` con `decodeIfPresent`.
2. `Dati/SigilloCapsule.swift` (cifratura, scelta da confermare, D-C1). Proposta: **una chiave delle capsule** casuale da
   256 bit, creata alla prima capsula, nel **Portachiavi del Mac** (`PortachiaviCapsule`, sul modello di
   `PortachiaviOvunque`); ogni capsula si cifra con una sottochiave HKDF (`uso = "capsula:" + id`), AES-256-GCM, con l'id del
   cliente e della capsula come dati associati (una capsula non si sposta su un altro cliente). Il testo non è mai scritto
   in chiaro su disco, non va nei log, non passa da Qwen, non entra nella ricerca (`Ricerca.swift`, Spotlight).
   **Backup**: il testo cifrato è nell'archivio, quindi nel backup; la chiave **no** (sta nel Portachiavi): per non perdere
   le capsule con un Mac nuovo, la chiave entra nel backup **solo se il backup è protetto da password** (cifrata insieme a
   tutto), altrimenti Prisma avvisa in Impostazioni › Backup «Le capsule del tempo si possono riaprire solo da questo Mac:
   proteggi i backup con una password». Da decidere.
3. `Motori/MotoreCapsule.swift`, puro: `pronte(capsule:obiettivi:posizioni:oggi:) -> [String]`. Una capsula è **pronta**
   se: `.data(d)` e `oggi ≥ d`; oppure `.obiettivo(id)` e l'obiettivo è **raggiunto** (D-C3: proposta,
   `disponibileOggi ≥ importoOggi` con i valori aggiornati delle posizioni, oppure il segno «raggiunto» del consulente
   della parte «I traguardi festeggiati»); un obiettivo eliminato rende la capsula «da decidere» (riga con «Scegli quando si
   apre»).
4. `Shell/SalaCapsula.swift`: `CapsulaDelTempo` (palco), `BustaCapsula` (`Shape`/vista con lembo e sigillo, `rotation3DEffect`
   sull'asse X per il lembo), `RigaCapsula`, `AperturaCapsula` (velo e foglio).
5. Notifica interna «La capsula di Sofia è pronta» in `MotoreNotifiche` (mai al cliente, **mai a Ruby**: né il testo né lo
   stato delle capsule entrano in `FonteRuby` (`Ruby/ModelliRuby.swift:169`) o nella scheda di Qwen; la prova di Ruby lo
   controlla). Se diventa anche una notifica di sistema con `PromemoriaMac` (`Shell/PromemoriaMac.swift`,
   `UNUserNotificationCenter`), vedi D-C10.
6. Prove: `Motori/ProvaCalcoliCapsule.swift` (pronta per data e per obiettivo; obiettivo eliminato; nessuna capsula di
   altri clienti nell'elenco della Sala), `Dati/ProvaBackupRacconti.swift` (la stessa delle lettere, §1.5) dentro
   `--prova-backup`, **senza il Portachiavi vero** (la chiave si passa alla prova, come fa già `ProvaBackup.swift:500` con
   la password: sul runner di GitHub il Portachiavi non si usa) (la capsula torna dopo il
   ripristino, il sigillo resta cifrato nell'archivio: nel JSON non compare il testo; con backup protetto si riapre;
   senza la chiave non si apre e lo dice), e in `--prova-ovunque` (se esclusa, l'istantanea non contiene `capsule`).

#### 3.4.6 Dati che l'utente deve dare e stati vuoti

- **Il testo lo scrive il cliente**, mai Prisma, mai Ruby: nessun testo di prova nell'app (il template ne inserisce uno).
- **Nessun obiettivo**: i chip non ci sono; resta «In una data…». Nota: «Giulia non ha ancora obiettivi: la capsula si apre
  in una data».
- **Nessuna capsula del cliente**: a destra, al posto dell'elenco, `.k`: «Nessuna capsula sigillata per Giulia.»
- **Capsula pronta**: la tile arancio con «Obiettivo raggiunto il 4 novembre: è il momento di consegnarla» (data vera).
- **Chiave mancante** (Mac nuovo, backup in chiaro): la riga mostra «Non si può aprire su questo Mac» e l'aiuto spiega
  perché; mai un testo inventato.
- **Obiettivo eliminato o cambiato**: la riga dice «L'obiettivo non c'è più: scegli quando si apre».
- **Dati di prova**: le capsule di `CAPS` e quella di Sofia (con il testo del template) si caricano solo con i clienti di
  prova, cifrate come le vere, ed escono con loro.

#### 3.4.7 Istantanee da aggiungere

Serie proposta **653-657**:

| Nome | Scena |
|---|---|
| `653-sala-capsula` (+ `-scuro`) | Giulia: campo vuoto, chip, elenco **solo di Giulia** |
| `654-sala-capsula-pronta` (+ `-scuro`) | Sofia: tile arancio ferma (senza pulsazione) |
| `655-sala-capsula-aperta` (+ `-scuro`) | Sofia: velo, foglio fuori dalla busta, testo intero, «Stampala su carta per Sofia» |
| `656-sala-capsula-vuota` | Andrea: nessun obiettivo, nessuna capsula |
| `657-sala-capsula-chiave-mancante` | riga «Non si può aprire su questo Mac» |

Più la pagina PDF della capsula nella prova dei prospetti (carta bianca).

#### 3.4.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole toccate: dati in locale (il testo del cliente resta sul Mac, cifrato); backup («comprende clienti, agenda,
posizioni, documenti, …»: le capsule ci vanno, `--prova-backup` va aggiornata); «Prisma ovunque» (che cosa entra
nell'istantanea); Ruby (non legge le capsule); PDF su carta bianca; logo (sigillo).

- **D-C1 · «Nessuno lo legge, nemmeno Denis».** Sul Mac del consulente una promessa così è vera solo se la chiave non la
  ha il consulente. Strade:
  - (a) **chiave nel Portachiavi del Mac** (proposta): Prisma non mostra mai il testo prima del giorno giusto e non ha un
    comando per farlo, ma tecnicamente il proprietario del Mac potrebbe. Allora la frase diventa onesta: **«Prisma la
    sigilla e la cifra: non si può leggere fino al giorno giusto.»**;
  - (b) **chiave dal cliente**: una parola scelta dal cliente (PBKDF2, come i backup) che serve per aprire; davvero nessuno
    la legge, ma **se il cliente la dimentica la capsula è persa** per sempre;
  - (c) tutte e due: chiave del Mac per la consegna, più una parola facoltativa del cliente.
  Una «cassaforte a tempo» vera (che si apra da sola a una data) **non si può fare** senza un servizio esterno: la data del
  Mac si può cambiare. Va detto così.
- **D-C2 · Backup e Mac nuovo.** La chiave nel backup solo se il backup è protetto (proposta), oppure sempre (le capsule si
  salvano ma il sigillo vale meno), oppure mai (le capsule si perdono cambiando Mac)?
- **D-C3 · Quando un obiettivo è «raggiunto».** Dal calcolo (`disponibileOggi ≥ importoOggi`), dal segno del consulente,
  o tutte e due (il calcolo propone, il consulente conferma)? Deve coincidere con «I traguardi festeggiati».
- **D-C4 · Dove scrive il cliente.** Sul Mac (template) o sull'iPad del tavolo (riservatezza migliore; protocollo del
  tavolo da estendere, sempre in rete locale e cifrato)?
- **D-C5 · Dettatura.** Il campo accetta la dettatura del sistema; sui Mac Apple Silicon l'italiano si detta sul
  dispositivo, ma la dettatura resta un **servizio Apple** e Prisma non la controlla. Proposta: lasciarla, e dirlo
  nell'aiuto del campo; oppure disattivarla nel campo (non è garantito che si possa).
- **D-C6 · «Prisma ovunque».** Proposta: le capsule **non** entrano nell'istantanea per iPhone/iPad (sono testi
  personali, come le conversazioni di Ruby); entra solo lo stato («sigillata», «pronta») se serve all'iPhone.
- **D-C7 · Consegna fuori dal Mac.** Il PDF stampato esce come carta (consegnato a mano). «Condividi…» con il PDF (Mail,
  Messaggi, AirDrop) fa uscire il testo del cliente: approvarlo o no.
- **D-C8 · Il consenso del cliente.** Il testo è scritto dal cliente e conservato dal consulente: è un dato personale
  con un fine nuovo; serve una riga nell'informativa privacy? (testo che **deve dare l'utente**, non si inventa).
- **D-C9 · Elenco di tutte le capsule.** Nella Sala solo il cliente scelto (proposta, contro il template); l'elenco
  completo nel dossier o in Studio?
- **D-C10 · Notifica di sistema.** «La capsula di Sofia è pronta» solo nel pannello Notifiche di Prisma (proposta) o anche
  come notifica del Mac (`PromemoriaMac`)? Quella del Mac compare sullo schermo bloccato e nel Centro notifiche con il nome
  del cliente, anche davanti a un altro cliente: proposta, se sì, senza nome («Una capsula del tempo è pronta»).
- **D-C11 · Chiave delle capsule e regola di «Prisma ovunque».** CLAUDE.md vieta che la passphrase e la chiave di «Prisma
  ovunque» vadano nell'archivio, nelle impostazioni o nei backup. La chiave delle capsule è un'altra (`PortachiaviCapsule`,
  mai la chiave di `PortachiaviOvunque` né una sua derivata), ma metterla nel backup protetto (D-C2) è un'eccezione nuova
  della stessa natura: va approvata in modo esplicito e scritta in CLAUDE.md (Dati e privacy).
- Nessuna API sopra macOS 13 (CryptoKit, Portachiavi, `rotation3DEffect`). Nessuna dipendenza esterna. Nessuna notifica al
  cliente: Prisma avvisa solo il consulente.

---

### Riepilogo dei file e dei campi nuovi di questa parte

| File nuovo | Contenuto |
|---|---|
| `DesignSystem/Apple/Tema.Apple+SalaRacconti.swift` | `Tema.Apple.SalaRacconti.{Lettera, Film, Disegno, Capsula}` e `Tema.Apple.Moto.{Lettera, Film, Disegno, Capsula}`; casi nuovi di `Tema.Apple.Ombra` (`.foglioLettera`, `.film`, `.foglioCapsula`; l'enum è `CaseIterable` con `strati(scuro:)`, `TemaApple.swift:236`); `Moto.Capsula.sigilloMolla` (`Moto.Molla`) |
| `DesignSystem/Apple/TemaApple.swift` (modifica) | `Carattere.disegno: Font.Design = .default` per il serif |
| `Motori/MotoreLettera.swift`, `Ruby/LetteraRuby.swift`, `Ruby/Istruzioni/lettera.md` | lettera: scheda dei fatti, lettera fissa, Qwen |
| `Motori/MotoreFilm.swift`, `Motori/TestiFilm.swift`, `Shell/DisegnoFilm.swift`, `Shell/RegistaFilm.swift` | film: dati, disegno Core Graphics, codifica AVFoundation |
| `Motori/MotoreDisegno.swift` | disegno: tratto → valori, confronto, versamento in più |
| `Dati/CapsulaTempo.swift`, `Dati/SigilloCapsule.swift`, `Dati/PortachiaviCapsule.swift`, `Motori/MotoreCapsule.swift` | capsula: modello, cifratura, chiave, «pronta» |
| `Dati/LetteraFuturo.swift` | lettera conservata |
| `Shell/SalaLettera.swift`, `Shell/SalaFilm.swift`, `Shell/SalaDisegna.swift`, `Shell/SalaCapsula.swift` | le viste del palco |
| `Shell/IstantaneeSalaRacconti.swift` | istantanee 640-657 |
| Prove | `ProvaCalcoliLettera`, `ProvaLetteraRuby`, `ProvaCalcoliFilm`, `--prova-film`, `ProvaCalcoliDisegno`, `ProvaCalcoliCapsule`, `ProvaBackupRacconti` (lettere e capsule) |

Campi nuovi dell'archivio (versione di Luce, da decidere nel §0; tutti con `decodeIfPresent`, nel backup e in
`--prova-backup`): `DatiPrisma.lettere: [LetteraFuturo]`, `DatiPrisma.capsule: [CapsulaTempo]`; facoltativo
`Obiettivo.disegno: [Double]?`; il video del film come `Documento` del cliente (nessun campo nuovo). Proposta per «Prisma
ovunque»: lettere e capsule escluse dall'istantanea, come le conversazioni di Ruby.

Ordine di lavoro suggerito (dal meno al più delicato): Disegna il tuo futuro (solo motori esistenti, niente esce) → La
lettera dal futuro (Ruby, come i messaggi) → Il film del piano (AVFoundation, decisione sull'invio) → La capsula del tempo
(cifratura e backup, decisioni D-C1/D-C2 prima di scrivere codice).

---

## 4. Sala: gioco del rischio, una giornata della pensione, lancia l'anno, quanto vale avermi accanto

Fonte: `Design/template-luce.html` (5 novembre 2026, 2297 righe; la riga 474 è la tabella delle icone in base64: non va
stampata). Le righe citate sono quelle di quel file. Per tutto ciò che qui non è detto valgono, nell'ordine:
- la parte comune della versione Luce (`01-comune.md`): §3 **la Sala** (griglia, palco, «‹ Sala», pillole dei clienti,
  «▣ Mostra sul tavolo», «✦ Aggiungi al Prisma di …», presentazione al cliente), §4 **i componenti riusati** (tassello con
  glifo `TasselloGlifo`/`GlifoLuce`, `Tema.Apple.Colore.Glifi`, tela animata, rimonta, calcolo condiviso della pensione
  §4.8 con l'adattatore proposto `Motori/PensioneEsperienze.swift`);
- `Design/template-novita-specifica.md` (Orizzonte) e sotto `Design/template-apple-specifica.md` (token §1, movimento §1.8
  e §2.0).

Pezzi del template usati da queste quattro esperienze:

| Cosa | Righe |
|---|---|
| Elenco delle esperienze `ESP` (chiavi `rischio`, `giornata`, `dadi`, `valore`) | 1189-1200 (1195-1198) |
| Glifi `GL.rischio`, `GL.giornata`, `GL.dadi`, `GL.valore` | 1201-1205 |
| Cornice del palco (`palcoHTML`, quali pulsanti compaiono) e montaggio (`montaSala`) | 1217-1224 |
| Voci del pannello Novità (`NOV15`) | 1780 |
| Il gioco del rischio (`RIS`, `risRound`, `risFine`, `ESPM.rischio`) | 1324-1347 |
| Una giornata della pensione (`giorM`, `SCN`, `ESPH.giornata`, `giorAgg`, `ESPM.giornata`) | 1349-1366 |
| Lancia l'anno (`EVD`, `dd`, `ESPH.dadi`, `dadiDraw`, `dadiPasso`, `ESPM.dadi`) | 1368-1385 |
| Quanto vale avermi accanto (`ESPH.valore`; non ha `ESPM`) | 1387-1395 |
| Calcolo condiviso della pensione (`fattore`, `pensCon`, `versPens`) | 435, 1185-1186 |
| Dati di prova dei clienti (`CLI`: `pn`, `ass`, `eta`, `obi`, `an.prev`) e `VITA` (età di pensione) | 411-434, 1115-1119 |
| Utilità: `ridotto` 377, `mig`/`eur` 378, `ease` 380, `conta` 381, `conteggi` 382, `entrata` 383, `anello` 392-395, `accendi` 396, `disegnaLinea` 398, `linee` 399, `barre` 400, `toast` 401, `TONE` 405, `rimonta` 845 | |
| CSS: `.lbl` 43, `.k` 44, `.v` 45, `.h2` 46, `.btn` 47-50, `.seg` 55-58, `.card` 59, `.tile` 127, `.bar8` 128-129, `.prep` 130-133, `.bignum` 141, `.opz` 216-219, `.scena` 232-233, `.scI` 234, `.evC` 235 | |

Schermate di riferimento (1480×940, palco 1440×900 scalato di 1,0137; **non nel repository**, si rigenerano con
`luce/script/shot04.js`, stesso schema di `shot01.js` della parte comune):
`luce/img/04-c-rischio-1.png`, `04-c-rischio-2.png`, `04-c-rischio-3.png`, `04-c-rischio-fine.png`,
`04-c-giornata-senza.png`, `04-c-giornata-con.png`, `04-c-giornata-andrea.png`, `04-c-dadi-inizio.png`,
`04-c-dadi-1.png`, `04-c-dadi-fine.png`, `04-c-valore.png`, `04-c-valore-andrea.png` e le stesse in scuro (`04-s-…`).

**Le cifre del template sono dimostrative, e qui più che altrove sono finte**: il gioco del rischio usa scenari scritti a
mano, la giornata scala cinque spese inventate sul reddito desiderato, Lancia l'anno usa dodici eventi in ordine fisso
(non c'è nessun caso), Quanto vale moltiplica tre cifre fisse per il patrimonio. In Prisma ogni cifra viene dai motori e
dall'archivio; dove manca un dato l'esperienza lo dice e non mostra numeri di ripiego.

Nomi in Prisma, coerenti con la parte comune (`EsperienzaSala`, `01-comune.md` §3.5): `giocoRischio`,
`giornataPensione`, `lanciaAnno`, `valoreConsulente`. Token in un file nuovo
`DesignSystem/Apple/Tema.Apple+SalaGiochi.swift`, dentro lo spazio `Tema.Apple.SalaEsperienze` proposto dalla parte comune:
`Tema.Apple.SalaEsperienze.Rischio`, `.Giornata`, `.Lancia`, `.Valore`; il movimento in `Tema.Apple.Moto.SalaEsperienze`
con gli stessi quattro sottospazi.

---

### 4.1 Il gioco del rischio

*«Il profilo vissuto, non dichiarato».* Chiave del template `rischio`, tassello #E5484D, glifo `rischio` (una linea che
scende e risale con la freccia). Voce Novità: «Il gioco del rischio» · «Il profilo vissuto, non dichiarato» →
`apriEsp('rischio',0)` (riga 1780). Nella griglia della Sala la frase è la stessa (riga 1195).

#### 4.1.1 Cosa si vede

La testata del palco (cornice comune, righe 1217-1218) mostra «‹ Sala», il tassello rosso 32, **«Il gioco del rischio»**,
«· Giulia Rossi» e a destra **solo «▣ Mostra sul tavolo»** (il gioco non ha «Aggiungi al Prisma»). Dentro il palco una sola
scatola `#risBox` a tutta card, con padding 26 sopra e sotto e 30 ai lati (riga 1329). Il gioco ha **quattro schermate**:
tre scenari e il risultato.

**Scenari** (`RIS`, righe 1325-1327; `risRound`, righe 1330-1339; `04-c-rischio-1.png`, `-3.png`):

1. riga di testa: a sinistra l'etichetta `.lbl` in rosso **«SCENARIO 1 DI 3»**; a destra, in `.k`, **«Il gioco prepara il
   questionario di adeguatezza, non lo sostituisce»** (sempre visibile, in tutti e tre gli scenari);
2. la domanda, grande (27 bold), larga al più 900:
   - scenario 1: **«Il tuo portafoglio di 100.000 € scende del 20% in tre mesi.»**
   - scenario 2: **«Un anno dopo è risalito: +12% rispetto all’inizio.»**
   - scenario 3: **«Due strade per i prossimi dieci anni: un rendimento sicuro del 2% l’anno, o un portafoglio misto che
     rende in media il 5% ma un anno su cinque perde.»** (va su tre righe);
3. sotto, a sinistra, il **grafico** e a destra la **colonna delle risposte** (larga 380):
   - scenari 1 e 2: sopra il grafico il **numero** in `.v` a 44 che si conta da «100.000 €» al valore finale
     («80.000 €» in rosso nello scenario 1, «112.000 €» in verde nello scenario 2; nello scenario 2 il conteggio parte
     da **80.000 €**, vedi sotto); il grafico è un'**area con la linea** di
     11 punti (`d` dello scenario: 100 → 80 e 80 → 112), linea rossa se finisce sotto l'inizio, verde se sopra, con l'area
     dello stesso colore al 10%, e una **linea tratteggiata** orizzontale a quota 100 con a destra «100.000 €» (11, grigio
     chiaro). Nota (revisione, riga 1335): l'HTML scrive «100.000 €» come testo iniziale, ma `conta(…, a[0]*1000, …)` lo
     sovrascrive subito e conta **da `a[0]`·1000**: 100.000 → 80.000 nello scenario 1, **80.000 → 112.000** nello
     scenario 2 (la linea parte da 80, il riferimento tratteggiato resta a 100.000 € = l'inizio della frase «+12% rispetto
     all'inizio»). Il colore (rosso/verde) confronta l'ultimo punto con il **primo della linea**, non con 100;
   - scenario 3: niente numero; **due linee** su dieci anni, «sicuro 2%» in #0A84FF (dritta, ×1,02 ogni anno) e «misto 5%»
     in #8B5CF6 (con la sequenza fissa +9, +7, −6, +10, +5, −4, +8, +6, −7, +9 %), con il nome in fondo a destra di ognuna
     (13 bold, nel colore della linea);
   - le **tre risposte** `.opz` (righe 216-219): pillola chiara con la lettera **A / B / C** in un cerchio e il testo:
     - scenario 1: «Vendo tutto, non voglio perdere altro» · «Aspetto: è già successo e poi è risalito» · «Compro ancora:
       adesso costa meno»;
     - scenario 2: «Incasso il guadagno e mi fermo» · «Lascio tutto com’è» · «Aumento la parte in azioni»;
     - scenario 3: «Il 2% sicuro» · «Metà e metà» · «Il portafoglio misto».
   Le risposte sono **invisibili e non cliccabili** finché il grafico non è finito (2,4 s negli scenari 1-2, 1,7 s nel 3),
   poi entrano da destra una dopo l'altra. Toccata una risposta, si colora (bordo e fondo verdi, lettera bianca su verde),
   le altre non si toccano più, e dopo 0,65 s arriva lo scenario seguente.

**Risultato** (`risFine`, righe 1340-1346; `04-c-rischio-fine.png`): due colonne centrate in verticale, spazio 40.
- A sinistra (larga 340, centrata): un **anello** da 220 (tratto 22) riempito al `punteggio/6`, nel colore del profilo,
  con al centro «Il profilo che emerge» (`.k`) e il **nome del profilo** (34 bold, nel colore). Profili e colori:
  punteggio 0-1 **«Prudente»** #30B15C, 2-3 **«Moderato»** #0A84FF, 4 **«Equilibrato»** #8B5CF6, 5-6 **«Dinamico»**
  #E08A00. Il punteggio è la somma degli indici delle risposte (A = 0, B = 1, C = 2).
- A destra: **«Come ha reagito Giulia»** (28 bold); tre righe `.prep` con il pallino pieno nel colore del profilo e
  «**Davanti al calo:** aspetto: è già successo e poi è risalito», «**Quando è risalito:** lascio tutto com’è»,
  «**Tra sicurezza e rendimento:** il portafoglio misto» (la risposta in minuscolo), e a destra di ognuna in `.k`
  «ha deciso in 1,0 s» (secondi da quando le risposte sono comparse, una cifra decimale, virgola italiana).
- Sotto, in `.k` 13,5 interlinea 1,5: **«Le decisioni rapide davanti al calo dicono più di qualsiasi risposta su carta. Il
  profilo ufficiale resta quello del questionario di adeguatezza firmato: questo gioco lo prepara e lo rende
  comprensibile.»**
- Due pulsanti grandi: **«↻ Rifai il gioco»** e, pieno in blu, **«Apri la scheda di adeguatezza»** (nel template un toast:
  «Scheda di adeguatezza di Giulia Rossi con il profilo «Equilibrato» da confermare»).

**Difetti del template da non copiare** (visibili in `04-c-rischio-fine.png`):
- «Equilibrato» a 34 pt **esce dall'anello** da 220 (il testo è più largo del foro): in Prisma il nome usa
  `Tema.Apple.Carattere.centroAnello(_:)` con le misure `dimensioniCentroAnello` (44, 42, 36, 32, 24) e si rimpicciolisce
  fino a stare nel foro (`minimumScaleFactor`);
- la risposta scelta prende lo stile **«giusta»** (verde) dell'Esame OCF: qui non c'è una risposta giusta, e il verde
  suggerisce che la prudenza o il coraggio siano «corretti». In Prisma la scelta usa l'accento neutro (vedi §1.2);
- il risultato è centrato in verticale e lascia vuota metà del palco: va bene, ma in Prisma la colonna destra ha anche il
  confronto con il profilo dichiarato (§1.5), che riempie lo spazio.

**Stati** (il template ha solo il pieno; proposte per Prisma, §1.6):
- **gioco mai fatto** (stato iniziale): parte subito lo scenario 1, come nel template;
- **gioco già fatto per questo cliente**: prima dello scenario 1 un riquadro «L'ultima volta, il 12 marzo 2026: Moderata»
  con «Rifai il gioco» e «Vedi il risultato»;
- **profilo dichiarato presente** (`Cliente.profilo.propensione`): nel risultato una riga in più «Dichiarato nel
  questionario: Moderata · Emerso dal gioco: Dinamica», in arancio se diversi (nomi di `ProfiloInvestitore.Propensione.nome`:
  Prudente, Moderata, Dinamica, Aggressiva; data d'esempio, dimostrativa);
- **modalità cliente**: niente nomi di altri clienti; il risultato non mostra i secondi se il consulente lo sceglie
  (decisione §1.8).

#### 4.1.2 Misure e stile

| Cosa | Template | Prisma |
|---|---|---|
| Scatola del gioco | padding 26 / 30 (riga 1329) | **nuovo** `Tema.Apple.SalaEsperienze.Rischio.padding = EdgeInsets(26, 30, 26, 30)` |
| «SCENARIO 1 DI 3» | `.lbl` (12, 600, maiuscolo, spaziatura .6) in `--red` | `Carattere.etichetta` + `Colore.rosso` (è il colore del tassello, #E5484D) |
| Avvertenza in alto a destra | `.k` 12,5 `--ink2` | `Carattere.secondario` + `inchiostro2` |
| Domanda | display 27, 700, spaziatura −0,5, interlinea 1,25, margine 12 sopra e 10 sotto, larga al più 900 | **nuovo** `Rischio.domanda = Carattere(dimensione: 27, peso: .bold, tracking: -0.5, interlinea: 1.25)`, `larghezzaDomanda = 900` |
| Numero dello scenario | `.v` a **44** (display 700, −0,5, tabellare), rosso o verde | `Carattere.valoreCursoreAnalisi` (44, bold, −1,5): differenza di spaziatura trascurabile, **riusare**; colore `Colore.rosso` / `Colore.verde` |
| Grafico scenari 1-2 | SVG 760×300; dominio y 74-116 su 270 punti (`Y = 280 − (v − 74)/42·270`); linea 3,5 a giunti tondi; area colore al 10% **piatta**; riferimento a 100 tratteggio 4 5 in `--ink3` con etichetta 11 | `TracciatoGrafico` (`GraficiApple.swift:206`) con `area: true`, `opacitaArea: 0.10`, `spessore: 3.5` (attenzione: in Prisma l'area è un **gradiente** dal colore a trasparente, non un fondo piatto: va bene così, coerente col tema); riferimento con `GrigliaGrafico` o una `Path` tratteggiata [4, 5]; **nuovi** `Rischio.grafico = CGSize(760, 300)`, `spessoreLinea = 3.5`, `opacitaArea = 0.10`, `tratteggioRiferimento: [CGFloat] = [4, 5]`; etichetta `Carattere.asse` (11) |
| Colori della linea | rossa #E5484D se finisce sotto, verde **#30B15C** se sopra; il numero verde è `--green` #2FA35A | `Colore.rosso`, `Colore.anello1` (linea) e `Colore.verde` (numero): come nel template, due verdi diversi |
| Grafico scenario 3 | SVG 760×330; x = i/10·720; dominio y 90-170 su 290; due linee 3,5; etichette 13 bold a x 726 | `TracciatoGrafico` ×2 (`indice` 0 e 1); colori `Colore.anello2` (#0A84FF) e `Colore.anello3` (#8B5CF6); **nuovo** `Rischio.graficoStrade = CGSize(760, 330)`, etichetta `Carattere(dimensione: 13, peso: .bold)` |
| Colonna risposte | larga 380, 60 sopra (30 nello scenario 3) | **nuovi** `Rischio.larghezzaRisposte = 380`, `sopraRisposte = 60`, `sopraRisposteStrade = 30`, spazio dal grafico 28 |
| Risposta `.opz` | padding 13 / 16, raggio **16**, filo `--sep`, fondo `--cardE`, 10 tra una e l'altra, testo 15, spazio 14, larga al più 860 | esiste già come `OpzioneOCFVista` (`Shell/StudioEsameOCF.swift:1023`, privata, con `enum Esito { aperta, giusta, sbagliata, attenuata }` e il modificatore privato `TremolioOCF`, riga 1102) con i token **`Tema.Apple.Studio.OCF`** (`Opzione`: raggio, padding, lettera, spostamento al passaggio; `Colore`: `bordoGiusta`, `fondoGiusta`, `letteraPiena`…; `DesignSystem/Apple/Tema.Apple+OCF.swift`): **estrarla** in `DesignSystem/Apple/OpzioneLettera.swift` (`OpzioneLettera(lettera:, testo:, esito: .aperta/.scelta/.giusta/.sbagliata/.attenuata)`, con `TremolioOCF` reso interno), usata da Esame OCF, Gioco del rischio e Palestra della trattativa; i token passano in uno spazio comune (proposta `Tema.Apple.OpzioneLettera`) e `Studio.OCF.Opzione` li riprende. Le scorciatoie A/B/C non stanno nella vista: le aggiunge chi la usa |
| Lettera | cerchio 30, `--chip`, 700 | idem, dentro `OpzioneLettera` |
| Risposta scelta | template: verde (`.giusta`: bordo #30B15C, fondo rgba(48,177,92,.1)) | **proposta**: stato `.scelta` con bordo `Colore.accento` e fondo `Colore.selezioneVoce` (rgba(0,122,255,.13)), lettera bianca su `accento`; **nuovi** `Tema.Apple.SalaEsperienze.Rischio.bordoScelta`, `fondoScelta` (decisione §1.8) |
| Anello del risultato | 220, tratto 22 (spazio tra anelli 22·1,22, qui uno solo), binario nel colore al 15% | `Anello` (`AnelliApple.swift:104`) con `misura: 220`, `spessore: 22`; **nuovi** `Rischio.anello = 220`, `spessoreAnello = 22` |
| Centro dell'anello | «Il profilo che emerge» `.k`; nome 34 bold nel colore | `Carattere.secondario`; nome `Carattere.centroAnello(34)` con riduzione fino a 24 |
| Colori dei profili | #30B15C, #0A84FF, #8B5CF6, #E08A00 | `Colore.anello1`, `anello2`, `anello3`, `arancio`; raccolti in **nuovo** `Rischio.colore(_ profilo: ProfiloInvestitore.Propensione) -> Color` |
| Titolo del risultato | display 28, 700, −0,5 | **nuovo** `Rischio.titoloRisultato = Carattere(dimensione: 28, peso: .bold, tracking: -0.5)` (`Carattere.nomeDossier` è 27: riusarlo è accettabile, da decidere in implementazione) |
| Righe `.prep` | 13,5, padding 12 sopra e sotto (il CSS ne dà 9, qui sovrascritto), filo `--sep` sotto, pallino 20 pieno | `Carattere.voceLista` (13,5); **nuovo** `Rischio.rigaReazione = 12`, `pallino = 20` |
| Testo d'avvertenza finale | `.k` 13,5, interlinea 1,5, 14 sopra | `Carattere.voceLista` con interlinea 1,5 (**nuovo** `Rischio.avvertenza = Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.5)`) |
| Pulsanti | `.btn.big` padding 10 / 18, 13,5 semibold; il secondo `.pri` (fondo #007AFF, testo bianco) | `StilePulsanteApple` grande e primario (`Misura.Padding.pulsanteGrande`, `Carattere.pulsanteGrande`) |
| Colonne del risultato | sinistra 340, spazio 40, centrate in verticale | **nuovi** `Rischio.colonnaAnello = 340`, `spazioRisultato = 40` |

Scuro (`04-s-rischio-*.png`): cambiano solo card, inchiostri, fondo delle risposte (`--cardE` → #283642, cioè
`Colore.cardPiena`) e binario dell'anello; linee, numeri e colori dei profili restano uguali.

#### 4.1.3 Movimento

| Cosa | Da → a | Durata | Curva | Ritardo | Token |
|---|---|---|---|---|---|
| Ingresso del gioco | il palco entra (cornice comune); il primo scenario parte | — | — | **0,2 s** dopo il montaggio (`ESPM.rischio`, riga 1347) | **nuovo** `Moto.SalaEsperienze.Rischio.attesaInizio = 0.2` |
| Linea scenari 1-2 | si disegna da sinistra | **2,2 s** | `(.22,1,.36,1)` = `Curva.uscita` | 0 | **nuovo** `Rischio.durataLinea = 2.2`. `TracciatoGrafico` oggi **non ha** un parametro di durata (usa sempre `Moto.Linea`, 1,5 s, con ritardo 0,15 + indice·0,12): serve un parametro nuovo `durata: Double? = nil` (e ritardo 0 per questa linea), senza cambiare gli usi esistenti |
| Area sotto la linea | opacità 0 → 1 | 0,9 s | lineare | 0,6 s | `Moto.Area` (0,90 / 0,60), esiste |
| Numero | si conta dal valore iniziale al finale | **2,2 s**, insieme alla linea | quartica in uscita | 0 | `NumeroCheConta(durata: 2.2)` |
| Linee scenario 3 | si disegnano | 1,5 s | `uscita` | 0,15 + i·0,12 s | `Moto.Linea`, esiste |
| Risposte | da x +20, opacità 0 → ferme | **0,45 s** | `uscita` | compaiono **0,2 s dopo** la fine del grafico (2,4 s o 1,7 s), poi i·0,09 s | **nuovi** `Rischio.attesaRisposte = 0.2`, `durataRisposta = 0.45`, `passoRisposte = 0.09`, `spostamentoRisposta: CGFloat = 20` |
| Risposta al passaggio | x +4 | 0,3 s | ease | — | **nuovo** `Rischio.spostamentoPassaggio: CGFloat = 4` |
| Scelta | colore della scelta | 0,3 s | ease | — | — |
| Scenario seguente | la scatola si riscrive (nel template senza transizione) | — | — | **0,65 s** dopo la scelta | **nuovo** `Rischio.pausaDopoScelta = 0.65`; proposta: uscita a dissolvenza 0,13 s come `rimonta` (`Tema.Apple.Studio.Moto.durataRimonta`) e cascata del nuovo scenario |
| Risultato | cascata dei blocchi `.st` (le tre righe) | 0,72 s | `uscita` | i·0,048 s | `Moto.Cascata` |
| Anello del risultato | si riempie | 1,4 s | `uscita` | **0,2 s** (`accendi(b, 200)`) | `Moto.Anello` con `ritardoPredefinito` (0,20), esiste |

**Riduci movimento** (`\.prismaCalmo`): nel template `ridotto` mostra subito le risposte (attesa 10 ms) e disegna la linea in
1 ms. In Prisma: grafico già tracciato, numero già al valore finale, risposte già presenti, scenario seguente con la
dissolvenza di 0,15 s, anello pieno. **Il tempo di decisione** si misura comunque da quando le risposte compaiono.
**Istantanee** (`\.modoIstantanea`, `\.prismaStatoFinale`): ogni scenario nello stato finale (linea tracciata, numero
finale, tre risposte visibili, nessuna scelta); il risultato con l'anello pieno.

#### 4.1.4 Interazioni

Mac:
- **rispondere**: clic su una risposta, solo dopo che sono comparse. **Tastiera** (proposta, il template non ce l'ha):
  `A`, `B`, `C` (e `1`, `2`, `3`) scelgono, con `.keyboardShortcut(KeyEquivalent("a"), modifiers: [])` sui tre pulsanti
  (macOS 11, nessuna protezione), attivi solo quando le risposte sono visibili;
- **tempo di decisione**: misurato da quando le risposte diventano cliccabili al clic (`performance.now()` nel template; in
  Prisma `Date()` o `ContinuousClock` di Swift 5.7, disponibile da macOS 13). Va in archivio solo se il consulente salva il
  risultato (§1.5);
- **«↻ Rifai il gioco»**: riparte dallo scenario 1 senza rimontare il palco;
- **«Apri la scheda di adeguatezza»**: nel template un toast. In Prisma il profilo di rischio del cliente **non** sta nella
  scheda di adeguatezza (che in Prisma è per proposta, `SchedaAdeguatezza`), ma nel dossier: Clienti › dossier ›
  **Profilo** (`SchedaCliente.profilo`, `Shell/StatoShell.swift:3172`; il menu «Propensione al rischio» è in
  `Shell/ModuloCliente.swift:529`). Il pulsante diventa **«Apri il profilo di Giulia»** e apre il dossier su quella scheda
  con un avviso «Dal gioco del rischio è emerso: Dinamica. Il profilo si cambia solo con il questionario firmato.» Il
  gioco **non scrive mai** `Cliente.profilo.propensione` da solo (decisione §1.8);
- **«▣ Mostra sul tavolo»**: l'iPad del tavolo mostra lo scenario in corso (cornice comune, §3.4 della parte comune).
  Proposta: il cliente **risponde dall'iPad** (tocco su A/B/C), che è il senso del «profilo vissuto»; serve un messaggio
  nuovo nel protocollo del tavolo (§1.5). Proposta minima senza protocollo nuovo: l'iPad mostra l'immagine dello scenario e
  il consulente tocca la risposta che il cliente dice. Attenzione: oggi il tavolo è **a senso unico** (commento in testa a
  `Tavolo/ProtocolloTavolo.swift`: «l'iPad davanti al cliente mostra solo ciò che il Mac sceglie»; dall'iPad arrivano solo
  saluto e battito). Far rispondere il cliente dall'iPad **inverte** questa regola: è una decisione (§1.8, punto 7);
- **cambio di cliente** con le pillole: il gioco riparte da capo per l'altro cliente (le risposte a metà si perdono, con una
  conferma se ci sono già risposte);
- **Esc**: dal palco torna alla griglia (cornice comune); a metà gioco chiede conferma.

iPhone e iPad: il template non mostra il gioco sui dispositivi. Sull'iPad del tavolo, vedi sopra.

#### 4.1.5 Mappa verso Prisma

**Esiste già (verificato con grep in `Sources/Prisma`):**

| Cosa | Dove |
|---|---|
| Profilo di rischio del cliente: `ProfiloInvestitore.propensione` (`prudente`, `moderata`, `dinamica`, `aggressiva`), `orizzonteAnni`, `esperienza`, `aggiornatoIl` | `Dati/Modelli.swift:296-330` |
| Esperienza per tipo di prodotto e **capacità di sostenere perdite** (`CapacitaPerdite`: nessuna, limitata, media, elevata) | `Dati/EsperienzaProdotti.swift:112, 157` |
| Il controllo «rischio» dell'adeguatezza: SRI della proposta contro il massimo del profilo (`MotoreCoerenza.sriMassimo(_:)`) | `Motori/MotoreAdeguatezza.swift:279` (`controlloRischio`), `Motori/MotoreCoerenza.swift:105` |
| La perdita che ogni profilo sopporta (5, 10, 20, 30 % del patrimonio finanziario) | `Motori/MotoreResistenza.swift:110` (`sopportabile(_:)`) |
| Le crisi del passato sul portafoglio del cliente | `Motori/CrisiStoriche.swift:110, 210` (`MotoreResistenza.crisi(_:profilo:)`) |
| Scheda Profilo del dossier e modulo del cliente | `SchedaCliente.profilo` (`Shell/StatoShell.swift`), `Shell/ModuloCliente.swift:529`, riga «Propensione al rischio» in `Shell/AppClienti.swift:251` |
| Risposta con lettera (stile, tremolio, scorciatoie) | `Shell/StudioEsameOCF.swift:1023` (`OpzioneOCFVista`, privata), `Tema.Apple+OCF.swift` |
| Anello, tracciato, numero | `Anello` (`AnelliApple.swift:104`), `TracciatoGrafico` (`GraficiApple.swift:206`), `NumeroCheConta` (`CifreApple.swift:77`) |
| Tavolo con l'iPad | `Tavolo/ProtocolloTavolo.swift` (`ContenutoTavolo`, `MostraTavolo.Genere`), `Tavolo/TavoloMac.swift`, `iOS/SchermiTavoloiPad.swift` |

**Motori di calcolo che servono e cosa manca:**
- **Nessun motore esistente calcola un profilo da scenari.** Serve un motore nuovo, puro e piccolo:
  `Motori/MotoreGiocoRischio.swift`:
  ```swift
  struct ScenarioRischio: Codable, Identifiable { let id: String; let domanda: String
      let andamento: [Double]?          // punti del grafico (100 = inizio); nil = due strade
      let strade: [StradaRischio]?       // scenario 3: nome, rendimento, sequenza
      let risposte: [String]             // tre testi, dalla più prudente alla più audace
      let etichetta: String }            // «Davanti al calo», «Quando è risalito», …
  struct RispostaRischio: Codable, Equatable { let scenario: String; let scelta: Int; let secondi: Double }
  struct PartitaRischio: Codable, Identifiable { var id: String; var clienteId: String; var data: Date
      var versioneScenari: String; var risposte: [RispostaRischio]
      var punteggio: Int { risposte.reduce(0) { $0 + $1.scelta } }
      var vistaDalConsulenteIl: Date? }
  enum MotoreGiocoRischio {
      static func profilo(punteggio: Int, massimo: Int, soglie: SoglieGiocoRischio) -> ProfiloInvestitore.Propensione
      static func confronto(_ p: PartitaRischio, dichiarato: ProfiloInvestitore?) -> ConfrontoProfilo   // uguale, più prudente, più audace
      static func perditaSopportata(_ p: ProfiloInvestitore.Propensione) -> Double  // = MotoreResistenza.sopportabile
  }
  ```
  Il profilo emerso **usa le quattro propensioni di Prisma**, non i quattro nomi del template (che non coincidono: il
  template ha «Equilibrato» e non ha «Aggressivo»). Proposta di soglie su un punteggio 0-6: 0-1 prudente, 2-3 moderata,
  4-5 dinamica, 6 aggressiva (da decidere, §1.8). Il colore e il nome mostrati vengono da `ProfiloInvestitore.Propensione`.
- **Scenario 1 con le cifre del cliente (facoltativo):** oggi il calo è «100.000 € −20%» fisso. Proposta: con il
  consenso del consulente, lo scenario 1 usa il **patrimonio finanziario del cliente arrotondato** (posizioni in essere,
  come `MotoreResistenza.calcola`) e il **calo della crisi del passato più vicina** al suo portafoglio
  (`MotoreResistenza.crisi(_:profilo:)`, `EsitoCrisi`), con la frase «Nel 2008 un portafoglio come il tuo ha perso il
  23%». Senza dati resta la versione neutra da 100.000 €.
- **Testi degli scenari**: non nel codice ma in una risorsa versionata, **nuova** `Sources/Prisma/Risorse/Sala/gioco-rischio.json`
  (scenari, risposte, etichette, soglie, versione), così l'utente li può far rivedere senza toccare il codice. Ogni
  partita salva la `versioneScenari`.
- **Tavolo** (se il cliente risponde dall'iPad): `ContenutoTavolo` riceve due casi nuovi, `scenarioRischio(ScenarioRischioTavolo)`
  (dal Mac: testo, punti del grafico, risposte; nessun nome né cifra del cliente se lo scenario è neutro) e
  `rispostaRischio(RispostaRischioTavolo)` (dall'iPad: indice e secondi), con la loro prova in `Tavolo/ProvaTavolo.swift`.

**Da creare:**
- `Shell/SalaGiocoRischio.swift`: `GiocoRischioVista` (scenari, risultato), `GraficoScenarioRischio`,
  `RisultatoGiocoRischio`; stato locale della partita in `@State` (non in `StatoShell`: si azzera uscendo);
- `DesignSystem/Apple/OpzioneLettera.swift` (estratta da `OpzioneOCFVista`, §1.2);
- token in `Tema.Apple+SalaGiochi.swift` (`SalaEsperienze.Rischio`, `Moto.SalaEsperienze.Rischio`);
- in archivio (versione dopo la 26, la stessa delle altre novità Luce): **`DatiPrisma.partiteRischio: [PartitaRischio]`**
  letto con `decodeIfPresent`, nel backup e in `Prisma --prova-backup` (nuovo `Dati/ProvaBackupSala.swift` o un caso in
  `ProvaBackup.swift`). Si salva **solo** con «Salva nel dossier» (pulsante nuovo nel risultato), mai da solo;
- nel dossier, scheda Profilo: una riga «Gioco del rischio: Dinamica (12 marzo 2026)» accanto alla propensione dichiarata;
- prova di calcolo **`Motori/ProvaCalcoliSala.swift`** (una per le quattro esperienze), chiamata da `ProvaCalcoli.esegui()`:
  1. punteggi 0…6 → le quattro propensioni con le soglie scelte; 2. confronto con il dichiarato (uguale, più prudente,
  più audace, nessun dichiarato); 3. una partita incompleta non dà profilo; 4. la versione degli scenari letta dalla
  risorsa entra nella partita; 5. lo scenario 1 «con le cifre del cliente» arrotonda il patrimonio a migliaia e usa il
  calo di `MotoreResistenza.crisi`.

#### 4.1.6 Dati che l'utente deve dare e stati vuoti

- **Testi degli scenari e delle risposte** e **soglie del punteggio**: quelli del template sono un fac-simile. L'utente li
  approva (o li fa approvare) prima dell'uso con i clienti; fino ad allora l'esperienza mostra l'etichetta «testi di prova».
- **Nessun dato del cliente è necessario** per la versione neutra. Per lo scenario «con le sue cifre» servono le posizioni
  in essere con il valore; se mancano resta la versione neutra, senza dirlo al cliente.
- **Profilo dichiarato assente**: il risultato non mostra il confronto, ma la frase «Il profilo di rischio di Giulia non è
  ancora stato raccolto con il questionario.»
- **Dati di prova**: con i clienti fittizi, una partita già fatta per due di loro (in `Dati/DatiDemo.swift` /
  `Dati/ClientiFittizi.swift`), mai nell'archivio reale.

#### 4.1.7 Istantanee da aggiungere

Numeri liberi verificati con grep in `Sources/` (esistono 600-613) e nelle altre sezioni di Luce: `03-sala-racconti.md`
usa già **649-657** (disegna 649-652, capsula 653-657) e la parte comune 614-619 e 690-695. Revisione: le serie di questa
sezione passano da 650/655/660/665 a **660-663** (rischio), **665-668** (giornata), **670-673** (lancia l'anno) e
**675-678** (valore), libere in tutte le parti. Qui la serie **660-663**.

| Nome | Scena |
|---|---|
| `660-sala-rischio-scenario` / `-scuro` | Giulia, scenario 1 nello stato finale: «80.000 €» rosso, linea e area tracciate, riferimento a 100.000 €, le tre risposte visibili, nessuna scelta |
| `661-sala-rischio-strade` | scenario 3: le due linee «sicuro 2%» e «misto 5%» tracciate, risposte visibili, la risposta B nello stato «scelta» |
| `662-sala-rischio-profilo` / `-scuro` | risultato con anello pieno (profilo «Dinamica», nome dentro l'anello senza uscire), tre reazioni con i secondi, confronto «Dichiarato: Moderata · Emerso: Dinamica» in arancio |
| `663-sala-rischio-senza-dichiarato` | risultato per un cliente senza propensione: la frase al posto del confronto |

#### 4.1.8 Regole di CLAUDE.md toccate e decisioni

Regole toccate: principio dell'**analisi** (il gioco serve a capire il cliente, non a vendere: la propensione resta un
dato del questionario); tema Apple (anelli che si riempiono, linee che si disegnano, cascata, «Riduci movimento»,
istantanee nello stato finale); **dati in locale** (le partite restano nell'archivio sul Mac e nei backup); il tavolo usa
la rete locale cifrata già approvata; nessuna dipendenza esterna; target macOS 13 (nessuna API nuova: `keyboardShortcut` è
di macOS 11, `ContinuousClock` di macOS 13).

**Decisioni per l'utente:**
1. **Normativa e adeguatezza**: il gioco **non è** il questionario di adeguatezza (né quello di Alleanza né quello
   dell'attività indipendente) e non deve sembrarlo. Proposta: il profilo emerso non cambia mai da solo la propensione del
   cliente; il pulsante apre il Profilo con un avviso. Va confermato che i testi «Il gioco prepara il questionario di
   adeguatezza, non lo sostituisce» e «Il profilo ufficiale resta quello del questionario di adeguatezza firmato» vanno
   bene così o vanno fatti rivedere (OCF, Alleanza). **Prisma non può inventarli.**
2. **Scenari e soglie**: approvare i testi delle tre domande e delle nove risposte, e le soglie (proposta 0-1, 2-3, 4-5, 6
   sulle quattro propensioni di Prisma, oppure i quattro nomi del template come «tendenza» separata dalla propensione).
3. **Stile della scelta**: accento neutro (proposta) o verde come nel template.
4. **Tempo di decisione**: mostrarlo al cliente (come il template), mostrarlo solo al consulente, o non misurarlo. La frase
   «Le decisioni rapide davanti al calo dicono più di qualsiasi risposta su carta» è un'affermazione di metodo: confermarla o
   toglierla.
5. **Salvare le partite** nel dossier (dato personale sul comportamento del cliente): proposta sì, solo con «Salva nel
   dossier». Da decidere se entrano nella copia di «Prisma ovunque» (`istantanea.cifrato`): proposta **no** (come le
   conversazioni di Ruby).
6. **Scenario 1 con le cifre del cliente** (patrimonio e crisi storica) o sempre neutro. Con il tavolo acceso, le cifre del
   cliente vanno sull'iPad.
7. **Risposta dall'iPad del tavolo**: protocollo nuovo (proposta, più fedele allo spirito) o solo immagine. Il protocollo
   nuovo cambia la regola di oggi del tavolo (l'iPad mostra e basta): dall'iPad arriverebbero al Mac le scelte e i tempi
   del cliente (sempre in rete locale cifrata ChaChaPoly, `_prisma-tavolo._tcp`, mai fuori). Vale anche per Lancia l'anno
   (§3.8, punto 7).
8. **Nomi dei profili davanti al cliente**: le quattro propensioni di Prisma al femminile («Dinamica») o una parola del
   gioco separata (il template dice «Equilibrato», che in Prisma non esiste). Il colore di ogni propensione è nuovo (in
   Prisma oggi la propensione non ha colori): proposta verde, blu, viola, arancio come il template.

---

### 4.2 Una giornata della pensione

*«Il divario diventa una vita concreta».* Chiave `giornata`, tassello #2A9BC8, glifo `giornata` (un sole). Voce Novità:
«Una giornata della pensione» · «Il divario diventa una vita» → `apriEsp('giornata',0)` (riga 1780).

#### 4.2.1 Cosa si vede

Testata del palco: «‹ Sala», tassello azzurro, **«Una giornata della pensione»**, «· Giulia Rossi», e a destra **«▣ Mostra
sul tavolo»** e **«✦ Aggiungi al Prisma di Giulia»** (la giornata è una delle cinque esperienze che vanno nel file del
cliente, riga 1218). Contenuto (`ESPH.giornata`, righe 1356-1359; `04-c-giornata-senza.png`, `04-c-giornata-con.png`),
padding 24 / 30:

1. **in alto a sinistra**: «Giulia, a 67 anni · la pensione al mese» (14, grigio) e sotto la **cifra grande**
   «1.400 €» (`.bignum` a 58) che si conta fino alla pensione mensile. L'età viene dalla linea della vita (`VITA[sel].pens`,
   riga 1115: 67, 67, 60, 67, 64);
2. **in alto a destra**: il segmentato **«Senza piano» · «Con il piano»** (si apre su «Senza piano», `giorM='senza'`,
   riga 1350, e ricorda la scelta tra un'apertura e l'altra);
3. **cinque scene** in fila (griglia a 5 colonne uguali, spazio 14, 20 sotto la testa), ognuna una scheda chiara alta
   almeno 270 con, dall'alto: l'**ora** («07:30», «10:00», «16:30», «20:30», «Agosto»; grigia, bold); un **tassello
   64** colorato con il glifo bianco (tazza, casa, due persone, posate, aereo); il **titolo** (19 bold); la **frase**
   (grigia); in fondo la **cifra** («60 € al mese», 15 bold) e l'**esito** in verde «✓ ci sta» (o «✓ coperte» per la
   scena fissa) oppure in rosso «✕ non ci sta». Le scene (`SCN`, righe 1351-1355):

   | Ora | Titolo | Frase | Importo base | Tassello |
   |---|---|---|---|---|
   | 07:30 | La colazione al bar | con gli amici di sempre | 60 | #B06E12 |
   | 10:00 | La casa e la spesa | le spese di tutti i mesi | **fissa** (57% del reddito desiderato) | #5A6873 |
   | 16:30 | I nipoti | il nuoto, la merenda, un regalo | 150 | #E58BA0 |
   | 20:30 | La cena fuori | una volta a settimana | 160 | #8B5CF6 |
   | Agosto | Il viaggio dell’estate | due settimane, una volta l’anno | 250 | #0A84FF |

   Una scena che **non ci sta** si spegne: opacità 0,55 e grigio all'85% (`.scena.ko`), tassello compreso;
4. sotto, una **striscia** (`.tile`, 18 sotto): una barra alta 14 con due parti, **grigio-azzurra** (#9FB3C2) per le spese
   fisse e **verde** per le scene che ci stanno, sul binario; a destra (larga 340) «Restano **90 €** al mese» (cifra in
   verde) o «Mancano 120 € al mese»;
5. in fondo la nota `.k`: **«Stime in euro di oggi, dalla pensione pubblica stimata e dal fondo pensione del piano. Non sono
   garanzie.»**

**Come decide il template** (`giorAgg`, righe 1361-1365): pensione «senza» = pensione pubblica del cliente; «con» =
`pensCon` (pubblica + il più grande tra il 95% del divario e il versamento × `fattore`, §4.8 della parte comune). Le spese
fisse sono il **57% del reddito desiderato** arrotondato a 10; gli importi delle scene sono quelli base × reddito
desiderato / 2.200, arrotondati a 10. Le scene si pagano **nell'ordine della giornata**: ognuna ci sta se il resto basta,
e se ci sta si toglie dal resto. Così il viaggio è sempre il primo a saltare e una scena cara a metà giornata fa saltare
quelle dopo anche se una più piccola ci starebbe. Con i dati di Giulia: senza piano 1.400 − 1.250 = 150 → colazione sì
(resta 90), nipoti, cena e viaggio no; con il piano 2.160 → tutto ci sta, restano 290.

**Difetti del template da non copiare**: la barra della striscia occupa circa due terzi della larghezza (la cifra a destra
è larga 340 fissi) e lascia un buco; in Prisma la barra si allarga fino alla cifra. Le spese fisse al 57% e gli importi
delle scene sono **inventati**: in Prisma li dà l'utente (§2.6). Il «Con il piano» del template non guarda le proposte vere.

**Stati** (proposte per Prisma):
- **pieno**, come sopra;
- **«Con il piano» senza proposte di previdenza**: la voce del segmentato c'è ma porta allo stato «Nessun piano per la
  pensione in proposta per Giulia: preparalo in Posizioni» con il pulsante; oppure, se il consulente lo sceglie, «Con un
  piano da 420 € al mese» calcolato dal versamento mancante (`versamentoMancante`) e segnato come **ipotesi**;
- **dati della pensione mancanti** (pensione pubblica o reddito desiderato): al posto della cifra grande la frase «Per
  questa esperienza servono la pensione stimata e quella desiderata di Giulia» con «Apri Analisi 360 › Previdenza»;
- **giornata non ancora compilata** (spese fisse e scene senza importi): le cinque scene compaiono vuote con «Scrivi con
  Giulia quanto costa» e un campo per l'importo; nessuna cifra di ripiego;
- **tutto ci sta già senza piano**: la striscia dice «Restano 350 € al mese» e «Con il piano» mostra di quanto cresce il
  resto (va bene: è una buona notizia, non si nasconde);
- **mancano soldi anche per le spese fisse**: la scena fissa diventa rossa «✕ non coperte» e la striscia «Mancano 180 € al
  mese solo per la casa e la spesa».

#### 4.2.2 Misure e stile

| Cosa | Template | Prisma |
|---|---|---|
| Contenuto | padding 24 / 30 | **nuovo** `Tema.Apple.SalaEsperienze.Giornata.padding = EdgeInsets(24, 30, 24, 30)` |
| Frase in alto | 14 `--ink2` | `Carattere.corpo` + `inchiostro2` |
| Cifra grande | `.bignum` a **58**: display 700, −2,2, tabellare, interlinea 1 | `numeroGrande` è a 62: **nuovo** `Giornata.pensione = Carattere(dimensione: 58, peso: .bold, tracking: -2.2, interlinea: 1, tabellare: true)` |
| Segmentato | `.seg`, 10 sopra il fondo della testa | `SegmentatoPillola` (`ControlliApple.swift:19`) |
| Griglia | 5 colonne uguali, spazio 14, 20 sotto la testa | **nuovi** `Giornata.colonne = 5`, `spazioScene = 14`, `sottoTesta = 20` |
| Scena `.scena` | raggio **20**, fondo `--cardE` (bianco / #283642), filo `--sep`, padding 16, alta almeno 270, spazio interno 6 | `Colore.cardPiena`, `Colore.separatore`, `Raggio.pannello` (20); **nuovi** `Giornata.paddingScena = 16`, `altezzaScena = 270`, `spazioScena = 6` |
| Ora | `.k`, 700, spaziatura .5 | **nuovo** `Giornata.ora = Carattere(dimensione: 12.5, peso: .bold, tracking: 0.5)` |
| Tassello della scena | 64, raggio 20, glifo 34 a tratto **1,8** bianco, ombra 0 10 20 −10 nera al 40%, 6 sopra e 8 sotto | `TasselloGlifo` della parte comune con raggio 20 (non 0,3·64 = 19,2: differenza trascurabile, si può usare la regola comune); **nuovi** `Giornata.tassello = 64`, `glifo = 34`, `trattoGlifo = 1.8`; ombra: **nuovo caso** `.tasselloScena` di `Tema.Apple.Ombra` (`TemaApple.swift:236`) (nero 0,40, y 10, sfocatura 20, espansione −10) |
| Colori dei tasselli | #B06E12, #5A6873, #E58BA0, #8B5CF6, #0A84FF | **nuovi** in `Tema.Apple.Colore.Glifi`: `colazione` (#B06E12, è anche la tinta chiara del canale indipendente ma qui fissa), `casa` (#5A6873, = `Carta.etichetta`), `nipoti` (#E58BA0), `cena` (= `anello3`), `viaggio` (= `anello2`) |
| Glifi delle scene | SVG in `SCN[].ic` (righe 1351-1355), viewBox 24 | **nuovi** casi di `GlifoLuce` (parte comune §4.1): `scenaColazione`, `scenaCasa`, `scenaNipoti`, `scenaCena`, `scenaViaggio`, con i tracciati SVG copiati dal template |
| Titolo scena | display 19, 700, interlinea 1,2 | `Carattere.perche` (19 bold −0,3 interlinea 1,22): **riusare** |
| Frase scena | `.k` 12,5, 3 sopra | `Carattere.secondario` |
| Cifra della scena | 15, 700, in fondo | `Carattere.titoloRiga` (15 bold) |
| Esito | 700 nel testo; verde `--green` #2FA35A o rosso `--red` | `Colore.verde`, `Colore.rosso` |
| Scena spenta | opacità 0,55, grigio 0,85, transizione 0,5 s | **nuovi** `Giornata.opacitaSpenta = 0.55`, `grigioSpenta = 0.85` (`.grayscale(0.85)`, macOS 10.15) |
| Striscia | `.tile` (raggio 18, padding 14 / 16), 18 sopra, spazio 20 | `Superficie.tile`, `Misura.Padding.tile` |
| Barra | alta 14, raggio 8; fisse #9FB3C2 (raggio 8 solo a sinistra), scene `--green` | `BarraPienaSegmenti` (`GraficiApple.swift:131`) con `PezzoBarraPiena`; colori `Colore.Composizione.liquidita` (#9FB3C2, esiste in `TemaApple.swift:137`) e `Colore.verde`; **nuovi** `Giornata.altezzaBarra = 14`, `raggioBarra = 8` |
| Cifra della striscia | 16 bold, larga 340, a destra | **nuovo** `Giornata.resto = Carattere(dimensione: 16, peso: .bold)`; larghezza libera (non 340 fissi) |
| Nota | `.k`, 10 sopra | `Carattere.secondario` + `inchiostro2` |

Scuro (`04-s-giornata-senza.png`): le scene prendono `--cardE` scuro (#283642); i tasselli e i colori degli esiti restano
uguali; le scene spente diventano quasi invisibili sul fondo scuro (opacità 0,55 su un grigio): in Prisma si verifica il
contrasto dell'esito «✕ non ci sta» (rosso pieno, non spento: proposta di **non** spegnere la riga dell'esito).

#### 4.2.3 Movimento

| Cosa | Da → a | Durata | Curva | Ritardo | Token |
|---|---|---|---|---|---|
| Entrata | cascata delle cinque scene e della striscia (`.st`) | 0,72 s | `uscita` | i·0,048 s (la rimonta del palco) | `Moto.Cascata` |
| Cifra grande | si conta da 0 alla pensione la prima volta, poi dal valore di prima al nuovo | **0,9 s** | quartica in uscita | 0 | `Moto.NumeroCambio` (0,90): **riusare** per entrambi i casi |
| Barra | si allarga | 1,2 s | `uscita` | 0 | `Moto.Barra` |
| Cambio di esito di una scena | la scheda gira su sé stessa: rotazione Y 0 → 90° → 0, prospettiva 800 | **0,62 s** | **(.4,0,.2,1)** | i·0,08 s, da sinistra | **nuovi** `Moto.SalaEsperienze.Giornata.giro = 0.62`, `passoGiro = 0.08`, `prospettiva: CGFloat = 800`, curva **nuova** `Moto.Curva.giro = Curva(x1: 0.4, y1: 0, x2: 0.2, y2: 1)`; in SwiftUI `rotation3DEffect(.degrees(…), axis: (0, 1, 0), perspective:)` (macOS 10.15) con il contenuto che cambia a metà giro |
| Spegnimento della scena | opacità e grigio | 0,5 s | ease | insieme al giro | **nuovo** `Giornata.durataSpegnimento = 0.5` |
| Segmentato | pillola che scorre | 0,5 s | `molla` | — | `Moto.Segmentato` |

Gira **solo** la scena il cui esito cambia (non tutte). **Riduci movimento**: niente giro, la scena cambia con la
dissolvenza di 0,15 s, cifra e barra già al valore. **Istantanee**: stato finale della modalità scelta, cifra completa,
barra alla misura, scene già spente o accese.

#### 4.2.4 Interazioni

Mac:
- **«Senza piano» / «Con il piano»**: il segmentato rifà il calcolo e anima solo ciò che cambia. Tastiera (proposta):
  ← → quando il segmentato ha il fuoco. **`SegmentatoPillola` oggi non lo fa** (in `ControlliApple.swift` solo il cursore
  ha `.focusable()` + `.onMoveCommand`, `TastieraCursoreApple`, riga 354): va aggiunto allo stesso modo (API di macOS
  10.15-12, nessuna protezione);
- **scene** (proposta, nel template non sono toccabili): un clic su una scena apre un piccolo dettaglio (nasce dalla scena,
  `OrigineDettaglioApple` / `PresentatoreDettaglio` in `DesignSystem/Apple/DettaglioApple.swift`) per **scrivere l'importo con il cliente** e cambiare la **priorità**; si possono aggiungere scene
  (fino a 6) e toglierne. La scena fissa «La casa e la spesa» non si toglie;
- **trascinare** le scene per cambiare l'ordine di priorità (proposta; al posto dell'ordine dell'orologio del template):
  con `onDrag`/`onDrop` (macOS 11);
- **«▣ Mostra sul tavolo»**: l'iPad mostra la giornata ferma nella modalità scelta (cornice comune);
- **«✦ Aggiungi al Prisma di Giulia»**: mette la giornata (le due modalità, con le cifre di oggi) nel file del cliente
  (sezione «Il Prisma del cliente», `02-sala-luce.md`), poi diventa «✓ Nel Prisma di Giulia»;
- **cambio di cliente**: si rifà per l'altro cliente con le sue scene.

iPhone e iPad: non nel template. Il file del cliente (Il Prisma del cliente) mostra la giornata ferma, nelle due modalità.

#### 4.2.5 Mappa verso Prisma

**Esiste già (verificato con grep):**

| Cosa | Dove |
|---|---|
| Ipotesi di previdenza del cliente: età, età di pensione, **reddito desiderato**, **pensione pubblica**, capitale, versamento, rendimento reale, anni di integrazione | `IpotesiPrevidenza` (`Dati/Analisi.swift:121`), dentro `Analisi360.previdenza` (`Dati/Analisi.swift:187`), in `DatiPrisma.analisi: [String: Analisi360]` (`DatiPrisma.swift:13`); `Analisi360.confermate: [AreaAnalisi]` dice se l'area è confermata con il cliente |
| Il piano previdenziale: divario, rendite dei piani **in essere** e **in proposta**, versamento mancante, fisco | `MotorePrevidenza.calcola(_:cliente:analisi:data:)` → `EsitoPianoPrevidenziale` (`Motori/MotorePrevidenza.swift:34, 94`): `pensionePubblica`, `redditoDesiderato`, `divario`, `renditaInEssere`, `renditaProposte`, `divarioResiduo`, `divarioConProposte`, `versamentoMancante`, `etaPensione` |
| La pensione pubblica stimata col contributivo | `MotorePensionePubblica.stima(cliente:previdenza:data:)` → `StimaPensione.nettaMensile`, `divario(obiettivo:)`; `pensioneDaUsare(_:stima:inseritaAMano:)` (`Motori/MotorePensionePubblica.swift:138, 225, 256`) |
| Età di pensione del cliente | `DatiLavoro.etaPensione` (`Dati/Modelli.swift:253`), altrimenti `IpotesiPrevidenza.etaPensione` |
| Fabbisogno mensile di oggi della famiglia | `IpotesiProtezione.fabbisognoMensile` (`Dati/Analisi.swift:136`) |
| Barra a segmenti, segmentato, numero | `BarraPienaSegmenti`, `SegmentatoPillola`, `NumeroCheConta` |

**Motori che servono e cosa manca:**
- **La pensione «senza piano»** = pensione pubblica (`EsitoPianoPrevidenziale.pensionePubblica`, o la stima contributiva
  se la pubblica non è stata scritta a mano, con `pensioneDaUsare`) **+ `renditaInEssere`** (i fondi pensione che il cliente
  ha già). Il template conta solo la pubblica: in Prisma sarebbe sbagliato ignorare ciò che il cliente ha già.
- **La pensione «con il piano»** = la stessa + **`renditaProposte`** (le proposte di previdenza aperte del cliente). Niente
  `pensCon` del template (95% del divario o `fattore` al 3%): lo vieta anche la parte comune (§4.8, decisione 3). Se non ci
  sono proposte, vedi gli stati (§2.1) e la decisione §2.8.
- Le due cifre passano dall'adattatore comune **`Motori/PensioneEsperienze.swift`** proposto dalla parte comune (§4.8),
  che restituisce per un cliente: `etaPensione`, `senzaPiano`, `conPiano?`, `versamentoPerDivario?`, `daConfermare: Bool`
  (area Previdenza non in `confermate`), `mancante: [DatoPensioneMancante]`. Così lettera, film, giornata e Lancia l'anno
  usano gli stessi numeri. (Nella parte comune l'adattatore è descritto al §4.8 e nella mappa del §5 con le funzioni
  `pensioneConPiano(cliente)` e `versamentoPerDivario(cliente)`: i campi qui sopra vanno riallineati con quelli.)
- **Manca il motore della giornata**: nuovo **`Motori/MotoreGiornataPensione.swift`**, puro:
  ```swift
  struct VoceGiornata: Codable, Identifiable, Hashable { var id: String; var quando: String; var titolo: String
      var frase: String; var importoMensile: Double?; var fissa: Bool; var glifo: String /* GlifoLuce.rawValue */
      var priorita: Int }
  struct GiornataPensione: Codable, Equatable { var voci: [VoceGiornata]; var aggiornataIl: Date? }
  struct EsitoGiornata { struct Scena { let voce: VoceGiornata; let ciSta: Bool }
      let pensione: Double; let fisse: Double; let scene: [Scena]
      let usate: Double; let resto: Double /* < 0 = mancano */ ; let fisseCoperte: Bool }
  enum MotoreGiornataPensione {
      enum Regola { case ordineDellaGiornata, priorita }       // il template: ordine della giornata
      static func calcola(_ g: GiornataPensione, pensione: Double, regola: Regola) -> EsitoGiornata
  }
  ```
  Regola: prima le voci fisse (se non bastano, `fisseCoperte = false` e tutte le altre «non ci stanno»), poi le altre
  nell'ordine scelto, ognuna ci sta se il resto basta (come il template). Voci senza importo: escluse e segnalate.
- **Dove stanno le voci**: nuovo campo **`Analisi360.giornata: GiornataPensione?`** (accanto alle ipotesi di previdenza,
  stessa vita: si conferma con il cliente), letto con `decodeIfPresent`, nel backup e in `--prova-backup`.
- **Euro di oggi**: la pensione del motore previdenziale è in euro di oggi; anche le voci si scrivono in euro di oggi (lo
  dice la nota del template). Nessuna rivalutazione da fare.

**Da creare:**
- `Shell/SalaGiornataPensione.swift`: `GiornataPensioneVista`, `SchedaScena`, `StrisciaResto`, il dettaglio per scrivere
  l'importo;
- token in `Tema.Apple+SalaGiochi.swift` (`SalaEsperienze.Giornata`, `Moto.SalaEsperienze.Giornata`, `Curva.giro`), i
  cinque glifi delle scene in `GlifoLuce` e le cinque tinte in `Colore.Glifi`;
- in `ProvaCalcoliSala.swift`: 1. pensione 1.400, fisse 1.250, voci 60/150/160/250 → resto 90, una sola scena accesa (i
  numeri del template come caso di prova); 2. stessa giornata con 2.160 → tutte accese, resto 290; 3. fisse non coperte →
  nessuna scena accesa e resto negativo; 4. regola «priorità» contro «ordine della giornata» (una scena piccola dopo una
  grande che salta); 5. voce senza importo esclusa; 6. «senza piano» = pubblica + rendita in essere, «con il piano» = +
  rendita delle proposte (dai casi di `MotorePrevidenza` già provati);
- l'aggiunta al Prisma del cliente: un tipo di contenuto `giornata` nel modello del file del cliente (sezione «Il Prisma del
  cliente»).

#### 4.2.6 Dati che l'utente deve dare e stati vuoti

- **Pensione pubblica** (scritta in Analisi 360 › Previdenza o stimata dai dati del lavoro: `DatiLavoro`, estratto conto
  INPS) e **reddito desiderato**. Attenzione: `IpotesiPrevidenza` ha valori **predefiniti** (2.200 e 1.400, `Analisi.swift:124-125`)
  che non sono dati del cliente. Proposta: la giornata usa le ipotesi solo se l'area Previdenza è in
  `Analisi360.confermate`, oppure le mostra con l'etichetta «da confermare»; se l'Analisi 360 del cliente non esiste, stato
  «servono la pensione stimata e quella desiderata».
- **Età di pensione**: `DatiLavoro.etaPensione` o l'ipotesi; mai il 67 di ripiego senza dirlo.
- **Spese fisse in pensione** («La casa e la spesa») e **importi delle scene**: li scrive il consulente **con il cliente**.
  Il template li inventa (57% e importi base): Prisma no. Proposta di aiuto, da decidere: precompilare le spese fisse con
  `IpotesiProtezione.fabbisognoMensile` (il fabbisogno di oggi) con l'etichetta «da confermare».
- **Proposte di previdenza**: senza proposte «Con il piano» è vuoto (o ipotesi, decisione).
- **Dati di prova**: le cinque scene del template con i loro importi per i clienti fittizi, segnate «dati di prova».

#### 4.2.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `665-sala-giornata-senza` / `-scuro` | Giulia senza piano: «1.400 €», colazione e casa accese, nipoti, cena e viaggio spenti, «Restano 90 € al mese» |
| `666-sala-giornata-con` | Giulia con il piano: cifra più alta, tutte le scene accese, «Restano … € al mese» |
| `667-sala-giornata-da-compilare` | giornata senza importi: le cinque scene vuote con «Scrivi con Giulia quanto costa» |
| `668-sala-giornata-dati-mancanti` | cliente senza ipotesi di previdenza: la frase e il pulsante verso Analisi 360 |

#### 4.2.8 Regole di CLAUDE.md toccate e decisioni

Regole toccate: **principio dell'analisi** (la giornata racconta il divario calcolato da `MotorePrevidenza`, non un numero
nuovo); dati in locale; tema Apple (numeri contati, cascata, dettaglio che nasce dalla scheda); «Riduci movimento» e
istantanee; il **file dato al cliente** («Aggiungi al Prisma di Giulia»: il contenuto esce dal Mac quando il consulente
manda il file, vedi la sezione del Prisma del cliente); nessuna API sopra macOS 13 (`rotation3DEffect`, `grayscale`,
`onDrag`/`onDrop` ci sono).

**Decisioni per l'utente:**
1. **«Con il piano»**: solo con proposte vere di previdenza (proposta) o anche con un piano ipotetico dal versamento
   mancante, segnato «ipotesi».
2. **«Senza piano»** = pubblica + rendita dei piani in essere (proposta) o solo pubblica come nel template.
3. **Ordine delle scene**: ordine della giornata (template) o priorità scelta con il cliente (proposta).
4. **Spese fisse precompilate** dal fabbisogno di oggi con «da confermare», o sempre vuote.
5. **Testo della nota** «Stime in euro di oggi… Non sono garanzie.»: va bene così o va rivisto per il file dato al cliente
   (è un testo che esce dal Mac).
6. **Ipotesi non confermate**: mostrare la giornata con «da confermare» o non mostrarla finché l'area Previdenza non è
   confermata.
7. **La giornata nel file del cliente** («✦ Aggiungi al Prisma di Giulia»): la pensione stimata, le spese della sua vita
   in pensione e ciò che «non ci sta» sono dati personali e patrimoniali che **escono dal Mac** quando il consulente
   consegna il file. Proposta: solo le due modalità ferme con le cifre di oggi e la nota approvata; niente importi delle
   scene se il cliente non li ha scritti con il consulente. Da confermare insieme alle regole del file del cliente
   (`02-sala-luce.md`).
8. **«Mostra sul tavolo»**: la pensione e le spese del cliente vanno sull'iPad (rete locale cifrata, nessun dato salvato
   sull'iPad); da confermare che va bene anche con persone presenti oltre al cliente.

---

### 4.3 Lancia l'anno

*«Due vite affiancate, con e senza piano».* Chiave `dadi`, tassello #B06E12, glifo `dadi` (un dado con quattro punti).
Voce Novità: «Lancia l’anno» · «Due vite affiancate» → `apriEsp('dadi',0)` (riga 1780).

#### 4.3.1 Cosa si vede

Testata del palco: «‹ Sala», tassello color cuoio, **«Lancia l’anno»**, «· Giulia Rossi», a destra **«▣ Mostra sul
tavolo»**. Contenuto (`ESPH.dadi`, righe 1373-1376; `04-c-dadi-inizio.png`, `04-c-dadi-1.png`, `04-c-dadi-fine.png`),
padding 22 / 28:

1. **testa**: «L’anno» (`.k`) e sotto l'anno grande **«2026»** (`.bignum` a 46); accanto, in basso, l'età **«37 anni»**
   (15, grigio); a destra tre pulsanti grandi: **«🎲 Lancia l’anno»** (pieno, blu), **«Lancia 10 anni»**, **«↻»**;
2. **due riquadri affiancati** (`.tile`, spazio 16, padding 16 / 20):
   - a sinistra **«Con il piano»** (15 bold, verde) e a destra nel riquadro la cifra **«204.050 €»** (`.v` a 28, verde);
   - a destra **«Senza piano»** (15 bold, grigio) e la cifra (`.v` a 28, inchiostro);
   - sotto, in ognuno, un **grafico ad area** 600×190: linea 3 nel colore (#30B15C con il piano, #9FB3C2 senza), area
     al 14%, **pallino finale** da 5,5 con il filo bianco 2. Le due scale sono **uguali** (massimo comune × 1,08, minimo 0)
     e l'asse x è sempre di **12 anni** (la linea si allunga a ogni lancio). All'inizio c'è solo il pallino;
3. **le carte dell'anno** (alte 150, 14 sotto): all'inizio la frase centrata «Premi «Lancia l’anno»: ogni anno capita
   qualcosa, con probabilità realistiche.» (15 grigio). A ogni lancio arriva una **carta** (`.tile` con il filo sinistro
   di 5 nel colore del tono: rosso #E5484D, arancio #E08A00, verde #2FA35A):
   - titolo «**2027 · Un anno brutto dei mercati**» (17 bold);
   - sotto, se l'evento ha effetti diversi: in verde semibold «Con il piano: Il piano tiene: si continua a versare» e in
     grigio «Senza: I risparmi sul conto non calano, ma non crescono» (14, spazio 30);
   - se è solo un anno di mercato: «I mercati fanno il loro: +4%» (grigio).
   Ogni anno ha **anche** un rendimento di mercato, pure quelli con un evento (la promozione +5%, la caldaia +4%, la
   perdita del lavoro +3%…): la carta lo mostra solo negli anni senza evento.
   La carta di prima scende di 80 e resta a opacità 0,4 sotto la nuova (`04-c-dadi-fine.png`); le più vecchie spariscono.

**Gli eventi del template** (`EVD`, righe 1369-1371) sono **dodici, sempre nello stesso ordine** (nessun caso, nonostante
la frase «con probabilità realistiche»): un anno normale (+4%), un anno brutto (−15%), una promozione (+4.000 €), la
caldaia e il tetto (−9.000 €), sei mesi di malattia (con il piano −5.000 €, senza −21.000 €), un anno forte (+17%), nasce
un bambino (−5.000 €), perdita del lavoro per otto mesi (−9.000 / −24.000 €), un'eredità (+30.000 €), un anno normale
(+5%), un infortunio (+3.000 / −12.000 €), un anno brutto (−11%). Premendo ancora «Lancia l'anno» **dopo** il dodicesimo
(cioè al tredicesimo clic) un toast: «Fine della partita: dodici anni giocati»; «Lancia 10 anni» si ferma da solo in
silenzio. Dopo «↻» la frase iniziale torna **più corta**: «Premi «Lancia l’anno»: ogni anno capita qualcosa.» (senza «con
probabilità realistiche», riga 1385).

**Come calcola il template** (`dadiPasso`, righe 1379-1383):
- con il piano: valore × (1 + rendimento dell'anno) + **(versamento del primo obiettivo + `versPens`) × 12** + effetto «con»;
- senza piano: valore × (1 + max(−2%, rendimento × 0,25)) + **300 × 12** + effetto «senza»;
- partenza per entrambi da `c.pn` (il patrimonio netto, 204.050 € per Giulia).

**Difetti e problemi del template da non copiare:**
- **non c'è caso**: gli eventi sono in fila; «Lancia l'anno» non lancia niente;
- **il confronto non è onesto**: con il piano si mettono da parte (550 + 420) × 12 = 11.640 € l'anno, senza piano 3.600.
  Gran parte della differenza tra le due vite viene dal **risparmio diverso**, non dal piano. Davanti a un cliente è una
  rappresentazione fuorviante (§3.8);
- «Senza piano» prende un quarto del mercato con un pavimento al −2%: è un'ipotesi di comodo, non un conto deposito vero;
- le cifre degli eventi (caldaia 9.000, malattia 21.000…) e gli indennizzi delle polizze («La polizza copre il reddito:
  −5.000 €») sono inventati;
- l'età e l'anno partono da 2026 fisso.

**Stati** (proposte per Prisma): inizio (solo pallini e la frase); partita in corso; **fine della partita** (dopo N anni,
proposta: fino alla pensione o 12 come nel template, con un riquadro finale «In 12 anni: con il piano … €, senza … €»
(cifre dal motore; con le regole del template Giulia arriverebbe a 421.901 € e 229.916 €, che il template non mostra mai) e
«↻ Un'altra partita»); **senza proposte** («Con il piano» vuoto: «Nessuna proposta aperta per Giulia: le due
vite sarebbero uguali»); **dati mancanti** (patrimonio o risparmio, §3.6).

#### 4.3.2 Misure e stile

| Cosa | Template | Prisma |
|---|---|---|
| Contenuto | padding 22 / 28 | **nuovo** `Tema.Apple.SalaEsperienze.Lancia.padding = EdgeInsets(22, 28, 22, 28)` |
| Anno | `.bignum` a **46** | `Carattere.valoreCursore` (46 bold −1,5 tabellare): **riusare** (spaziatura −1,5 invece di −2,2, trascurabile) |
| Età | 15 `--ink2`, 22 sopra | `Carattere(dimensione: 15, peso: .regular)` → **nuovo** `Lancia.eta`; `inchiostro2` |
| Pulsanti | `.btn.big`, il primo `.pri`, spazio 8; «🎲» è un'emoji | `StilePulsanteApple` grande; al posto dell'emoji il glifo `dadi` (`GlifoLuce.dadi`) in bianco, 15 (proposta: le emoji non sono nel tema) |
| Riquadri | `.tile` padding 16 / 20, spazio 16, 14 sotto la testa | `Superficie.tile`; **nuovi** `Lancia.paddingRiquadro = EdgeInsets(16, 20, 16, 20)`, `spazioRiquadri = 16` |
| Titolo del riquadro | 15 bold; verde `--green` o `--ink2` | `Carattere.titoloRiga`; `Colore.verde` / `inchiostro2` |
| Cifra del riquadro | `.v` a **28**, verde con il piano | **nuovo** `Lancia.cifra = Carattere(dimensione: 28, peso: .bold, tracking: -0.5, tabellare: true)` |
| Grafico | 600×190, 6 sopra; x = i/12 · 580; y su 170; linea 3 a giunti tondi; area 14%; pallino 5,5 con filo bianco 2 | `TracciatoGrafico` con `area: true`, `opacitaArea: 0.14`, `puntoFinale: true`, `spessore: 3`; il punto finale di `TracciatoGrafico` è già raggio 5 con bordo bianco 2,5 (`GraficiApple.swift:227`): **riusarlo** (differenza trascurabile) invece di token nuovi. `TracciatoGrafico` vuole i punti normalizzati 0…1: la scala comune alle due vite (massimo × 1,08) la calcola la vista. **Nuovi** `Lancia.altezzaGrafico = 190`, `anniAsse = 12` (o fino alla pensione, §3.8) |
| Colori | con il piano #30B15C, senza #9FB3C2 | `Colore.anello1`, `Colore.Composizione.liquidita` |
| Area delle carte | alta 150, 14 sopra | **nuovo** `Lancia.altezzaCarte = 150` |
| Carta | `.tile` con fondo `--cardE`, filo sinistro 5 nel tono | `Colore.cardPiena`; **nuovo** `Lancia.filoCarta = 5`; toni `Colore.rosso`, `Colore.arancio`, `Colore.verde` (`TONE`, riga 405) |
| Titolo della carta | 17 bold | `Carattere(dimensione: 17, peso: .bold)` = `Carattere.titoloFinestra`: **riusare** |
| Effetti | 14; verde semibold e grigio; spazio 30; 6 sopra | `Carattere.corpo`; **nuovo** `Lancia.spazioEffetti = 30` |
| Frase iniziale | 15 `--ink2`, centrata, 40 sopra | `Carattere(dimensione: 15)` + `inchiostro2` |

Scuro (`04-s-dadi-*.png`): cambiano riquadri, carte (#283642) e inchiostri; linee, aree e toni restano uguali.

#### 4.3.3 Movimento

| Cosa | Da → a | Durata | Curva | Ritardo | Token |
|---|---|---|---|---|---|
| Cifre dei riquadri | si contano dal valore di prima al nuovo | **0,7 s** | quartica in uscita | 0 | **nuovo** `Moto.SalaEsperienze.Lancia.numero = 0.7` (`NumeroCheConta(durata:)`) |
| Anno ed età | cambiano subito (nessuna animazione nel template) | — | — | — | proposta: `NumeroCheConta` con formato intero e durata 0,3 s |
| Linea e area | nel template si ridisegnano di colpo a ogni lancio | — | — | — | proposta: il nuovo tratto si disegna da dove finiva (0,7 s, `uscita`), con il pallino che scivola; la scala comune che cambia si anima insieme. `TracciatoGrafico` oggi ridisegna **da zero** quando compare: serve un modo «prolunga» (forma `Animatable` sui punti, o un parametro `da: CGFloat` per la frazione già tracciata), da aggiungere senza cambiare gli usi esistenti |
| Carta nuova | da y −40, rotazione −2°, scala 1,05, opacità 0 → ferma | **0,56 s** | **molla** `(.34,1.45,.64,1)` | 0 | **nuovi** `Lancia.durataCarta = 0.56`, `spostamentoCarta: CGFloat = -40`, `rotazioneCarta = -2`, `scalaCarta: CGFloat = 1.05`; curva `Moto.Curva.molla` |
| Carte di prima | scendono di 80 per posizione, scala 0,97; la prima resta a opacità 0,4, le altre a 0 e spariscono | 0,5 s | `uscita` | — | **nuovi** `Lancia.passoStorico: CGFloat = 80`, `scalaStorico: CGFloat = 0.97`, `opacitaStorico = 0.4`, `durataStorico = 0.5` |
| «Lancia 10 anni» | dieci lanci uno dopo l'altro | ogni **0,7 s** (60 ms con `ridotto`) | — | — | **nuovo** `Lancia.intervalloDieci = 0.7` |
| Dado (proposta, il template non lo ha) | il glifo del pulsante gira di 360° al clic | 0,45 s | `molla` | — | **nuovo** `Lancia.giroDado = 0.45` |

**Niente Timer** (CLAUDE.md): i dieci lanci si fanno con un `Task` legato alla vista (`.task(id:)`, macOS 12) che aspetta
`Task.sleep` tra un passo e l'altro e si annulla uscendo dal palco o con «↻». **Riduci movimento**: «Lancia 10 anni» fa i
dieci anni in un colpo e mostra lo stato finale (cifre, linee, ultima carta) con la dissolvenza di 0,15 s; le carte
entrano senza molla. **Istantanee**: una partita a seme fisso già giocata per dieci anni (cifre finali, linee tracciate,
ultima carta e quella di prima a 0,4).

#### 4.3.4 Interazioni

Mac:
- **«Lancia l’anno»** (e **Spazio**, proposta: `.keyboardShortcut(.space, modifiers: [])`, macOS 11): un anno in più;
  alla fine della partita il pulsante si spegne e compare il riquadro finale;
- **«Lancia 10 anni»**: dieci anni di fila (il primo dopo 0,7 s, come `setInterval` del template); «↻» la ferma. Proposta
  (nel template no: lì «Lancia l'anno» resta attivo e aggiunge anni alla corsa): mentre corre «Lancia l'anno» e «Lancia 10
  anni» si spengono;
- **«↻»**: nuova partita (**nuovo seme**: la partita successiva è diversa; la stessa partita si può rivedere con «↻» tenuto
  premuto o con un menu «Rigioca la stessa», proposta);
- **passaggio sulla linea** (proposta): fumetto «2031 · 41 anni · con il piano 312.400 € · senza 210.800 €»;
- **«▣ Mostra sul tavolo»**: l'iPad mostra le due vite; proposta: il **cliente lancia dall'iPad** (un tocco = un anno),
  stesso protocollo del gioco del rischio (§1.5), oppure solo l'immagine;
- **cambio di cliente**: partita nuova per l'altro cliente.

iPhone e iPad: non nel template (vedi il tavolo).

#### 4.3.5 Mappa verso Prisma

**Esiste già (verificato con grep):**

| Cosa | Dove |
|---|---|
| **Simulazione stocastica** con seme fisso: generatore SplitMix64 con normale di Box-Muller, rendimenti lognormali annui con μ = ln(1 + r) − σ²/2, volatilità per SRI e per composizione, imposte e costi come `MotoreProiezione` | `GeneratoreSeme` (`Motori/MotoreMonteCarlo.swift:5`), `LineaMonteCarlo` (44), `EsitoMonteCarlo` (100), `MotoreMonteCarlo.volatilita(_:)` (152), `linea(_:rendimentoPredefinito:mesi:data:)` (175), `seme(_:)` (212), `simula(_:mesi:traguardo:traiettorie:seme:)` (252) |
| Patrimonio da oggi alla pensione con risparmio annuo, rendimento reale, eventi della vita per età | `MotoreLineaVita` (`Motori/MotoreLineaVita.swift:99`), `IngressoLineaVita` (26: `patrimonioIniziale`, `risparmioAnnuo`, `rendimentoReale`, `movimenti`), `prepara(cliente:posizioni:obiettivi:eventi:…)` (150), `EventoLineaVita` (`Dati/EventoLineaVita.swift`) |
| Risparmio libero del cliente | `ProfiloInvestitore.risparmioAnnuo` (`Dati/Modelli.swift:326`) |
| Reddito netto | `ProfiloInvestitore.redditoNettoAnnuo` (`Modelli.swift:318`) |
| Coperture per rischio (vita, invalidità, salute, LTC, infortuni…) con capitale | `RischioCoperto` (`Dati/Posizione.swift:79`), `Posizione.rischio`, `capitaleAssicurato`, `garanzie` (testo libero) (`Posizione.swift:166-182`); `MotoreProtezioneFamiglia.calcola` → `TutelaRischio` con `coperture`, `proposte`, `stato` (`Motori/MotoreProtezioneFamiglia.swift:17, 90`) |
| Riserva per gli imprevisti | `MotoreLiquidita.calcola` → `EsitoLiquidita.riservaNecessaria`, `liquiditaAttuale`, `mesiRiserva` (`Motori/MotoreLiquidita.swift:44, 72`); rendimento del conto `IpotesiLiquidita.conto` (0,5) |
| Proposte aperte | `Posizione.stato == .proposta`, `MotoreCoerenza.proposteAperte(_:)` (`MotoreCoerenza.swift:171`) |
| Pensione con e senza proposte | `EsitoPianoPrevidenziale.serieInEssere`, `serieConProposte` |

**Motori che servono e cosa manca:**
- **Il mercato dell'anno** viene dal Monte Carlo: per ogni lancio una sola estrazione normale `z` dal `GeneratoreSeme`
  (seme = `MotoreMonteCarlo.seme(clienteId + numero partita)`), e ogni posizione cresce di exp(μ + σ·z) come in
  `simula` (stesso fattore comune, stessa prudenza: correlazione piena). Il «+4%» della carta è il rendimento del
  portafoglio di quell'anno. Così la carta «Un anno brutto dei mercati» compare quando z è basso, non per decreto.
- **Le due vite** (proposta, da decidere §3.8):
  - **senza piano** = le posizioni **in essere** di oggi, con i loro versamenti, più il **risparmio libero** del cliente
    (`risparmioAnnuo`) che resta sul conto al rendimento del conto;
  - **con il piano** = in essere **più le proposte aperte** (investimento, previdenza, protezione), con lo **stesso
    risparmio totale**: i versamenti delle proposte si tolgono dal risparmio libero (se lo superano, l'esperienza lo dice:
    «Il piano chiede 970 € al mese, Giulia ne mette da parte 600»).
  Così la differenza viene dal piano, non da un risparmio diverso.
- **Gli eventi della vita** con le probabilità: **non esistono in Prisma** e **non si possono inventare**. Servono una
  tabella degli eventi con la **probabilità annua e la fonte** (ISTAT, INAIL, INPS…), gli **importi** (o la regola: mesi
  di reddito persi × reddito netto) e quale **rischio coperto** li tocca. Proposta: risorsa **nuova**
  `Sources/Prisma/Risorse/Sala/eventi-anno.json` con le voci (nome, probabilità annua, fonte, effetto: `spesa(importo)` /
  `mancatoReddito(mesi)` / `entrata(importo)`, `rischio: RischioCoperto?`, tono, età minima e massima), **vuota di
  probabilità** finché l'utente non le dà; le voci senza probabilità non escono a caso. Fino ad allora la partita ha:
  - gli **anni di mercato** (dal Monte Carlo);
  - gli **eventi del cliente** già nella Linea della vita (`EventoLineaVita`: matrimonio, casa, figli, eredità all'età
    indicata), che arrivano nell'anno giusto, senza caso;
  - le **carte a mano**: il consulente sceglie un evento dalla tabella e lo «gioca» (proposta).
- **Gli effetti con e senza piano** (le due righe della carta):
  - **evento coperto** (`rischio` dell'evento con una `TutelaRischio` coperta **con il piano**, cioè da una posizione in
    essere o in proposta): l'importo dell'indennizzo **non si può calcolare** dai dati di oggi (`capitaleAssicurato` è il
    capitale caso morte/invalidità; per malattia e infortuni la diaria o l'indennità non sono campi). Proposta: un campo
    nuovo facoltativo **`Posizione.indennizzoStimato: Double?`** (per evento, scritto dal consulente dalle condizioni);
    senza, la carta dice «Coperto dalla polizza Infortuni: l'indennizzo dipende dalle condizioni» senza cifra;
  - **spesa imprevista**: con il piano viene dal **fondo per gli imprevisti** se c'è (obiettivo collegato o riserva di
    `MotoreLiquidita`), senza piano dai risparmi; l'effetto sulla linea è lo stesso importo ma la carta dice da dove viene;
  - **mancato reddito**: mesi × `redditoNettoAnnuo`/12, meno l'eventuale indennizzo.
- **Manca il motore della partita**: nuovo **`Motori/MotoreLanciaAnno.swift`**, puro e leggero (una traiettoria, non
  mille: nessun peso sulla memoria):
  ```swift
  struct VitaLanciaAnno { var valore: Double; var serie: [Double] }
  struct AnnoLanciato { let anno: Int; let eta: Int; let rendimento: Double; let evento: EventoAnno?
      let effettoCon: EffettoAnno; let effettoSenza: EffettoAnno; let tono: TonoAnno }
  struct PartitaLanciaAnno { let seme: UInt64; var generatore: GeneratoreSeme; var anno: Int; var eta: Int
      var con: VitaLanciaAnno; var senza: VitaLanciaAnno; var anni: [AnnoLanciato]; let anniMassimi: Int }
  enum MotoreLanciaAnno {
      static func prepara(cliente: Cliente, posizioni: [Posizione], analisi: Analisi360?, eventiCliente: [EventoLineaVita],
                          tabella: [EventoAnno], oggi: Date, seme: UInt64) -> Result<PartitaLanciaAnno, DatoLanciaMancante>
      static func lancia(_ p: inout PartitaLanciaAnno, cartaAMano: EventoAnno? = nil) -> AnnoLanciato?
  }
  ```
  Riusa `MotoreMonteCarlo.linea(_:…)` per μ e σ di ogni posizione e `GeneratoreSeme` per le estrazioni (normale per il
  mercato, uniforme per gli eventi). Stesso seme → stessa partita (le prove e le istantanee sono ripetibili).
- **Euro**: nominali, come il template (le cifre crescono); la carta finale dice anche il valore in euro di oggi con
  `IpotesiCalcolo.inflazione`.

**Da creare:**
- `Shell/SalaLanciaAnno.swift`: `LanciaAnnoVista`, `RiquadroVita`, `CartaAnno`, `MazzoCarte`, riquadro finale;
- token in `Tema.Apple+SalaGiochi.swift` (`SalaEsperienze.Lancia`, `Moto.SalaEsperienze.Lancia`);
- `Risorse/Sala/eventi-anno.json` (solo struttura e voci senza probabilità) e la sua lettura tollerante;
- in archivio (versione dopo la 26): **`Impostazioni.sala: ImpostazioniSala`** con `eventiAnno: [EventoAnno]` modificati
  dall'utente (probabilità, fonte, importi) e `anniPartita: Int?`; **`Posizione.indennizzoStimato: Double?`**. Entrambi con
  `decodeIfPresent`, nel backup e in `--prova-backup`. Le partite **non** si salvano;
- pagina **Impostazioni › Sala** (nuovo caso `SchedaImpostazioni.sala`, `Shell/StatoShell.swift:3121`) per la tabella degli
  eventi e i testi d'avvertenza delle quattro esperienze;
- in `ProvaCalcoliSala.swift`: 1. stesso seme → stessa partita, semi diversi → partite diverse; 2. con z = 0 e nessun
  evento le due vite crescono del rendimento medio; 3. **stesso risparmio totale** nelle due vite (la differenza a z = 0 è
  solo nel rendimento e nei costi); 4. evento coperto con indennizzo stimato: effetto «con» = −spesa + indennizzo; senza
  indennizzo: nessuna cifra; 5. evento della Linea della vita all'età giusta; 6. un evento senza probabilità non esce mai
  a caso; 7. fine della partita all'anno massimo; 8. nessuna proposta → le due vite coincidono e lo stato lo dice.

#### 4.3.6 Dati che l'utente deve dare e stati vuoti

- **Probabilità degli eventi con la fonte**, **importi** (o regole) e **rischi coperti**: dati che Prisma non ha e non può
  inventare. Senza, la partita ha solo mercato, eventi del cliente e carte a mano; la frase iniziale dice «Ogni anno i
  mercati fanno la loro parte; gli imprevisti li scegli tu» invece di «con probabilità realistiche».
- **Indennizzo delle polizze** per evento (`indennizzoStimato`), dalle condizioni di polizza: senza, la carta non mostra
  cifre per la parte coperta.
- **Patrimonio** (posizioni in essere con valore), **risparmio libero** (`risparmioAnnuo`) e **reddito netto**: se mancano,
  stato «Per giocare servono il patrimonio e quanto Giulia mette da parte ogni anno» con il collegamento al dossier.
- **Proposte aperte**: senza, le due vite coincidono (stato dedicato).
- **Età**: da `Cliente.eta`; senza data di nascita l'età non compare (solo l'anno).
- **Dati di prova**: i dodici eventi del template come carte con probabilità **segnate «di prova»**, solo con i clienti
  fittizi.

#### 4.3.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `670-sala-lancia-inizio` | Giulia all'inizio: «2026», età, due riquadri con la stessa cifra e il solo pallino, la frase iniziale |
| `671-sala-lancia-partita` / `-scuro` | dieci anni giocati con un seme fisso: cifre finali, linee e aree tracciate, l'ultima carta (un evento coperto) e quella di prima a opacità 0,4 |
| `672-sala-lancia-fine` | riquadro di fine partita con le due cifre e il valore in euro di oggi |
| `673-sala-lancia-senza-proposte` | cliente senza proposte aperte: lo stato «le due vite sarebbero uguali» |

#### 4.3.8 Regole di CLAUDE.md toccate e decisioni

Regole toccate: **principio dell'analisi** (la partita mostra l'effetto del piano calcolato dai motori, non un racconto);
**niente Timer** (i dieci lanci con `Task.sleep` in `.task`); **MacBook M1 8 GB** (una sola traiettoria; il Monte Carlo
da mille traiettorie non serve qui e non va chiamato); dati in locale; tema Apple (numeri contati, linee che si
disegnano, «Riduci movimento», istantanee con seme fisso); canale riconoscibile (le carte che citano una polizza mostrano
l'etichetta del canale, Alleanza o indipendente, `EtichettaCanaleApple`); nessuna API sopra macOS 13 (`.task(id:)` è di
macOS 12).

**Decisioni per l'utente:**
1. **Confronto onesto**: stesso risparmio totale nelle due vite (proposta) invece dei 3.600 € fissi del template. Il
   template, così com'è, fa sembrare il piano molto più utile di quanto sia: davanti al cliente è un rischio di
   comunicazione fuorviante.
2. **Probabilità degli eventi**: servono le fonti (ISTAT, INAIL, INPS o altre) che l'utente sceglie; **Prisma non le
   inventa**. Fino ad allora: solo mercato, eventi del cliente e carte a mano (proposta) oppure eventi del template segnati
   «di prova» anche con i clienti veri (sconsigliato). Le tabelle (ISTAT, INAIL, INPS) **non si scaricano**: l'unica rete
   ammessa è quella di Mercato (solo BCE ed Eurostat, `ClienteMercato.richiesta`); l'utente le scrive in Impostazioni ›
   Sala o le importa da file.
3. **Che cos'è «senza piano»**: la situazione di oggi senza le proposte (proposta) o un conto deposito.
4. **Indennizzi delle polizze**: campo nuovo `indennizzoStimato` scritto dal consulente (proposta) o nessuna cifra.
5. **Durata della partita**: 12 anni (template), fino alla pensione, o scelta.
6. **Testo d'avvertenza** (il template non ne ha uno qui): proposta «Un gioco con anni possibili, non una previsione. I
   mercati veri possono andare meglio o peggio.»; da approvare.
7. **Il cliente lancia dall'iPad** del tavolo (protocollo nuovo) o solo l'immagine.

---

### 4.4 Quanto vale avermi accanto

*«Il tuo lavoro, in cifre».* Chiave `valore`, tassello #2563EB, glifo `valore` (una stella). Voce Novità: «Quanto vale
avermi accanto» · «Il tuo lavoro, in cifre» → `apriEsp('valore',0)` (riga 1780).

#### 4.4.1 Cosa si vede

Testata del palco: «‹ Sala», tassello blu, **«Quanto vale avermi accanto»**, «· Giulia Rossi», e **nessun pulsante a
destra**: niente «Mostra sul tavolo» e niente «Aggiungi al Prisma» (riga 1218: `valore` è escluso da entrambi).
Contenuto (`ESPH.valore`, righe 1388-1395; `04-c-valore.png`, `04-c-valore-andrea.png`), padding 28 / 34:

1. etichetta `.lbl` **«IL RIESAME DI NOVEMBRE · TRE ANNI INSIEME»**;
2. il titolo grande (36 bold, 6 sopra, sotto l'etichetta): **«In tre anni il nostro lavoro vale circa 9.030 €.»** con la cifra in blu
   (`--accent`) che si conta;
3. **quattro riquadri** (`.tile`, griglia a 4 colonne, spazio 14, 22 sotto): etichetta (`.k`), cifra (`.v` a 30, contata),
   spiegazione (`.k`, interlinea 1,4):
   - **«Tasse risparmiate»** · 4.860 € · «con le deduzioni del fondo pensione e delle polizze»;
   - **«Costi tagliati»** · 2.310 € · «fondi più cari sostituiti, commissioni ridotte»;
   - **«Rispetto all’alternativa»** · 1.860 € · «le scelte fatte insieme, dal track record»;
   - **«E in più, protetto»** · 150.000 € · «di capitale per la famiglia, se succede qualcosa» (non entra nel totale);
4. sotto (26 sotto, allineati in basso, spazio 30):
   - a sinistra **«VALORE E PARCELLE, A CONFRONTO»** (`.lbl`) e due righe: «Il valore portato» con una barra blu piena
     (alta 26) e «9.030 €»; «Le parcelle pagate» con una barra grigio-azzurra (#9FB3C2) lunga parcelle/valore e «3.600 €».
     Etichetta larga 150 (14), cifra larga 110 a destra (bold);
   - a destra un riquadro largo 330 con il fondo azzurrino: **«Per ogni euro di parcella, circa 2,5 euro di valore.»**
     (24 bold, interlinea 1,25);
5. in fondo la nota `.k`, 18 sotto: **«Stime ricavate dai motori di Prisma e dal track record; il confronto con
   l’alternativa usa i dati di mercato del periodo. Non sono garanzie di risultati futuri.»**

**Come calcola il template** (riga 1388): tre cifre fisse (4.860, 2.310, 1.860) moltiplicate per patrimonio / 204.050,
arrotondate a 10; parcelle 3.600 × min(1,4, lo stesso fattore) arrotondate a 100; protetto = `c.ass`. **Sono numeri
finti**: nessun motore. Si vede bene con Andrea (`04-c-valore-andrea.png`): «Il nostro primo incontro» è mercoledì, ma
la schermata dice «tre anni insieme», 3.640 € di tasse risparmiate «con le deduzioni del fondo pensione e delle polizze»
che Andrea non ha, e «0 €» protetti.

**Altri difetti**: la frase «Per ogni euro di parcella…» quasi non cambia (valore e parcelle scalano insieme: 2,5 per
Giulia, Laura, Andrea e Sofia; solo oltre 1,4 volte il patrimonio di Giulia le parcelle smettono di crescere, e Marco
arriva a 2,8); l'etichetta dice «tre anni insieme» per tutti, ma lo stesso template, riga 1761, dice che il primo
incontro con Giulia «fu il 5 novembre 2025» (un anno); «Le parcelle pagate» ignora che per i clienti **Alleanza** il consulente non è pagato a parcella ma con le
**provvigioni** dentro i costi dei prodotti: per Giulia (canale «ai», entrambi) il confronto è incompleto e per un cliente
solo Alleanza non avrebbe senso (§4.8).

**Stati** (proposte per Prisma):
- **pieno**, con le voci che hanno dati;
- **voce senza dati**: il riquadro resta con l'etichetta e una frase al posto della cifra («Nessuna deduzione: Giulia non
  ha versamenti deducibili»; «Nessuna sostituzione fatta insieme»; «Il track record non ha ancora misure per Giulia»);
  la voce non entra nel totale e il titolo lo dice («vale almeno …»);
- **rapporto troppo giovane** (meno di 12 mesi, o nessuna raccomandazione accettata): niente totale, la frase «Ne
  parleremo al primo riesame: oggi è presto per misurare» e solo «E in più, protetto» se c'è;
- **nessuna parcella e solo canale Alleanza**: la parte «Valore e parcelle» diventa «Valore e costi pagati» (provvigioni
  e costi dei prodotti, §4.5) o si toglie (decisione);
- **valore minore del compenso**: si mostra lo stesso, senza abbellire («Per ogni euro di parcella, circa 0,8 euro di
  valore misurabile»): è il senso del principio di analisi.

#### 4.4.2 Misure e stile

| Cosa | Template | Prisma |
|---|---|---|
| Contenuto | padding 28 / 34 | **nuovo** `Tema.Apple.SalaEsperienze.Valore.padding = EdgeInsets(28, 34, 28, 34)` |
| Etichetta | `.lbl` | `Carattere.etichetta` + `inchiostro2` |
| Titolo | display 36, 700, −1, 6 sopra; cifra in `--accent` | `Carattere.titoloCarta` è 36 bold −1 con interlinea 1,05: **nuovo** `Valore.titolo = Carattere(dimensione: 36, peso: .bold, tracking: -1)`; cifra `Colore.accento` |
| Riquadri | 4 colonne, spazio 14, 22 sopra; `.tile` | `Superficie.tile`, `Misura.Padding.tile`; **nuovi** `Valore.colonne = 4`, `spazioRiquadri = 14` |
| Cifra dei riquadri | `.v` a **30** | **nuovo** `Valore.cifra = Carattere(dimensione: 30, peso: .bold, tracking: -0.5, tabellare: true)` |
| Spiegazione | `.k`, interlinea 1,4, 4 sopra | `Carattere.secondario` con interlinea 1,4 |
| Barre | `.bar8` alta **26**, raggio **9**; valore `--accent`, parcelle #9FB3C2 | `BarraPiena` (`GraficiApple.swift:28`) alta 26 raggio 9 (`Raggio.barra` = 9, esiste); colori `Colore.accento`, `Colore.Composizione.liquidita`; **nuovi** `Valore.altezzaBarra = 26` |
| Etichetta della barra | larga 150, 14 | `Carattere.corpo`; **nuovo** `Valore.larghezzaEtichetta = 150` |
| Cifra della barra | larga 110, bold, a destra | `Carattere(dimensione: 14, peso: .bold)`; **nuovo** `Valore.larghezzaCifra = 110` |
| Riquadro del rapporto | largo 330; fondo rgba(0,122,255,.08); filo rgba(0,122,255,.2); 24 bold interlinea 1,25 | **nuovi** `Valore.fondoRapporto = Color(r: 0, g: 122, b: 255, a: 0.08)`, `filoRapporto = Color(r: 0, g: 122, b: 255, a: 0.20)`, `larghezzaRapporto = 330`, `rapporto = Carattere(dimensione: 24, peso: .bold, interlinea: 1.25)` |
| Nota | `.k`, 18 sopra | `Carattere.secondario` |

Scuro (`04-s-valore.png`): riquadri e inchiostri del tema; la cifra blu e il riquadro azzurrino restano uguali (rgba
fisse: nello scuro il fondo all'8% è appena visibile, va bene).

**Canale** (proposta, CLAUDE.md: «va sempre distinto il canale»): ogni riquadro con cifre di prodotti mostra, sotto la
spiegazione, le parti per canale con `EtichettaCanaleApple` («Alleanza 2.900 € · Indipendente 1.960 €»), e la barra del
compenso è a due segmenti nei colori dei canali (`BarraPienaSegmenti` con `Colore.canaleAlleanza` e
`Colore.canaleIndipendente`).

#### 4.4.3 Movimento

| Cosa | Da → a | Durata | Curva | Ritardo | Token |
|---|---|---|---|---|---|
| Entrata | cascata dei quattro riquadri `.st` | 0,72 s | `uscita` | i·0,048 s | `Moto.Cascata` |
| Cifre (`data-n`) | si contano da 0: titolo, poi le quattro dei riquadri, in ordine | 1,1 s + min(i, 6)·0,06 s | quartica in uscita | partono insieme | `Moto.Numero` con `indice` (esiste: 1,10 / 0,06 / 6) |
| Barre | si allungano | 1,2 s | `uscita` | 0,15 + i·0,09 s | `Moto.Barra` (esiste) |

Nient'altro si muove (la stella non ha animazione). **Riduci movimento**: tutto fermo con la dissolvenza di 0,15 s.
**Istantanee**: cifre complete, barre alla misura.

#### 4.4.4 Interazioni

Il template non ha interazioni dentro l'esperienza (solo «‹ Sala» e il cambio di cliente). Proposte per Prisma, coerenti
con il principio dell'analisi:
- **clic su un riquadro**: apre il dettaglio (nasce dal riquadro, `OrigineDettaglioApple` / `PresentatoreDettaglio`) con le voci che compongono la cifra:
  per «Tasse risparmiate» gli anni e le posizioni (deduzione, aliquota, risparmio); per «Costi tagliati» le sostituzioni
  (prima, dopo, differenza annua, anni); per «Rispetto all'alternativa» le raccomandazioni misurate (rimanda a Studio ›
  Track record); per «Protetto» le coperture;
- **periodo**: un segmentato «Dall'inizio · Ultimi 12 mesi» (proposta) al posto di «tre anni» fisso;
- **niente «Mostra sul tavolo»** (come il template): l'esperienza si mostra sullo schermo girato o nella presentazione
  (cornice comune);
- **niente «Aggiungi al Prisma»** (come il template). Proposta, da decidere: «Metti nel riesame» che la porta nel
  prospetto del riesame annuale (`CompositoreProspetti.riesame`, `Motori/ProspettoRiesame.swift`), con le stesse cifre e la
  stessa nota; oggi quel prospetto è per il consulente, non per il cliente;
- **cambio di cliente**: rifà il calcolo.

Da dove si apre, oltre alla Sala (proposta): dal **riesame** (Agenda, appuntamento di tipo riesame, `MotoreRiesame`) con
«Quanto vale avermi accanto», perché l'etichetta del template è «Il riesame di novembre».

#### 4.4.5 Mappa verso Prisma

**Esiste già (verificato con grep):**

| Voce | Motori e dati che la danno |
|---|---|
| **Tasse risparmiate · previdenza** | `RegoleFiscali.risparmioDeduzione(reddito:deduzione:)`, `limiteDeducibilita` (5.300 € dal 2026), scaglioni IRPEF (`Motori/MotoreFiscale.swift:7-80`); `EsitoPianoPrevidenziale.deducibiliOggi`, `risparmioOggi` (solo **anno in corso**, `MotorePrevidenza.swift`); reddito da `ProfiloInvestitore.redditoLordoAnnuo` |
| **Tasse risparmiate · polizze** | `RegoleFiscali.premiDetraibili(_:)` (19% su caso morte, invalidità, infortuni fino a 530 €, LTC fino a 1.291,14 €; `MotoreFiscale.swift:48`), `detrazionePremi` |
| **Costi tagliati** | `MotoreCosti` (`Motori/MotoreCosti.swift`): `CostiPosizione` (euro l'anno per posizione), `perso(_:anni:)`, `alternativa(_:prodotti:cliente:)`; `MotoreSostituzione.calcola(attuale:alternativa:…)` (`Motori/MotoreSostituzione.swift:82`); la sostituzione registrata: `SchedaAdeguatezza.posizioneSostituitaId` (`Dati/SchedaAdeguatezza.swift:55`) e, nella raccomandazione, `Raccomandazione.alternativa?.posizioneSostituitaId` (il campo sta in `AlternativaRaccomandazione`, `Dati/Raccomandazione.swift:46, 62`, non direttamente in `Raccomandazione`); `Posizione.costoComplessivo` (calcolata, `Dati/Posizione.swift:331`) |
| **Rispetto all'alternativa** | `MotoreTrackRecord.calcola(raccomandazioni:posizioni:tabella:oggi:)` → `TrackRecord.differenzaTotale`, `scartoMedioAnnuo`, `misurate`, voci con `Misura` (`Motori/MotoreTrackRecord.swift:18-97`), con i riferimenti di Impostazioni › Rendimenti di confronto e di Mercato; filtrato sulle raccomandazioni del cliente (`Raccomandazione.clienteId`) |
| **E in più, protetto** | `MotoreProtezioneFamiglia.calcola` → `TutelaRischio.capitale` per rischio (`Motori/MotoreProtezioneFamiglia.swift:17-31`); `Posizione.capitaleAssicurato`, `rischio` |
| **Parcelle pagate** | `Parcella` (`clienteId`, `stato`, `data`, `incassataIl`, `annullataIl`; `Dati/Parcella.swift:80-110`), `MotoreParcelle.importo(_:)` (`Motori/MotoreParcelle.swift:46`), `ricaviConsulenza(_:)` (158) |
| **Provvigioni Alleanza** del cliente (per il confronto onesto) | `MotoreStudio.eventi(_:studio:da:a:cal:)` (`Motori/MotoreStudio.swift:289`) con le aliquote di `ImpostazioniStudio.aliquote` (`Dati/ImpostazioniStudio.swift:95`) |
| **Costi dei prodotti pagati** dal cliente | `MotoreCosti.calcola(_:prodotti:cliente:)` → `AnalisiCosti.perCanale(_:)` (`MotoreCosti.swift:69, 123`) |
| **Inizio del rapporto** | `Cliente.creatoIl` (`Dati/Modelli.swift:40`: è la data della **scheda**, può essere quella dell'importazione); la prima raccomandazione accettata (`Raccomandazione`, `MotoreTrackRecord.scelta`) |
| Riesame | `MotoreRiesame` (`Motori/MotoreRiesame.swift:105`); il prospetto del riesame è `CompositoreProspetti.riesame(_:conformita:occasioni:memoria:)` in `Motori/ProspettoRiesame.swift` (non esiste un tipo `ProspettoRiesame`), ed è un prospetto **per il consulente** («per te, da portare all'incontro di revisione») |

**Cosa manca:**
- **Tasse risparmiate negli anni passati**: oggi i motori calcolano il risparmio dell'anno in corso, non quello di ogni anno
  del rapporto. Serve sommare anno per anno i contributi deducibili versati (da `decorrenza`, `premio`, `frequenza` delle
  posizioni di previdenza **entrate con il consulente**, o dal loro storico versamenti se c'è) e i premi detraibili delle
  coperture attive. Il reddito degli anni passati non c'è: si usa quello di oggi con l'etichetta «stima».
  **Attribuzione**: contano solo le posizioni nate da una raccomandazione accettata (o collocate dal consulente) dopo
  l'inizio del rapporto, non quelle che il cliente aveva già (decisione §4.8).
- **Costi tagliati negli anni passati**: per ogni raccomandazione accettata con `alternativa?.posizioneSostituitaId` (o scheda
  di adeguatezza con `posizioneSostituitaId`):
  (costo % della sostituita − costo % della nuova) × valore medio × anni dalla firma, con `Posizione.costoComplessivo` di
  entrambe (la sostituita può essere chiusa: il costo resta in archivio). Se manca un costo, la voce non si conta e lo si
  dice. Nessuna formula esistente lo fa per il passato.
- **Compenso del consulente per canale**: parcelle pagate (indipendente) e provvigioni stimate (Alleanza, se ci sono le
  aliquote); senza aliquote la parte Alleanza resta «non stimata».
- **Motore nuovo** **`Motori/MotoreValoreConsulente.swift`**, puro, che compone i motori esistenti:
  ```swift
  struct ValoreConsulente {
      struct Voce { let tipo: TipoVoceValore /* tasse, costi, alternativa */; let totale: Double?
          let perCanale: [Canale: Double]; let dettagli: [DettaglioValore]; let stima: Bool; let motivoAssente: String? }
      let dal: Date; let al: Date; let anni: Double
      let voci: [Voce]; var totale: Double? /* somma delle voci con dati; nil se nessuna */
      let protetto: Double?                   // capitale caso morte (o per rischio, decisione)
      let parcellePagate: Double; let provvigioniStimate: Double?; let costiProdotti: Double?
      var rapporto: Double? /* totale / compenso, nil se compenso 0 */ }
  enum MotoreValoreConsulente {
      static func calcola(cliente: Cliente, posizioni: [Posizione], raccomandazioni: [Raccomandazione],
                          schede: [SchedaAdeguatezza], parcelle: [Parcella], studio: ImpostazioniStudio,
                          riferimenti: TabellaRiferimenti, dal: Date, oggi: Date, cal: Calendar) -> ValoreConsulente
  }
  ```
  Si calcola fuori dal `body`, in cache (come `CacheMotoriPosizioni`), perché il track record ricostruisce i versamenti.
- **Inizio del rapporto**: campo nuovo facoltativo **`Cliente.clienteDal: Date?`** (data in cui è iniziata la consulenza);
  senza, si usa la prima raccomandazione accettata, e solo in ultimo `creatoIl` con l'etichetta «dalla scheda».

**Da creare:**
- `Shell/SalaValoreConsulente.swift`: `ValoreConsulenteVista`, `RiquadroValore`, `ConfrontoCompenso`, i dettagli;
- token in `Tema.Apple+SalaGiochi.swift` (`SalaEsperienze.Valore`);
- in archivio (versione dopo la 26): `Cliente.clienteDal: Date?`; `Impostazioni.sala.avvertenzaValore: String?` (il testo
  approvato, §4.8); con `decodeIfPresent`, backup e `--prova-backup`;
- in `ProvaCalcoliSala.swift`: 1. un fondo pensione accettato tre anni fa con 2.000 €/anno e reddito 40.000 → tre anni
  di `risparmioDeduzione` (con l'aliquota del 33%); 2. una posizione che il cliente aveva già **non** conta; 3. una
  sostituzione dal 2,1% all'1,3% su 50.000 € per due anni → 800 €; senza costo della sostituita → voce assente con il
  motivo; 4. il track record del cliente: `differenzaTotale` delle sole sue raccomandazioni; 5. parcelle annullate e in
  bozza escluse; 6. rapporto nil con compenso 0; 7. canale: le cifre per canale sommano al totale; 8. meno di 12 mesi →
  stato «presto per misurare».

#### 4.4.6 Dati che l'utente deve dare e stati vuoti

- **Inizio del rapporto** (`clienteDal`) per ogni cliente: senza, la data viene dalla prima raccomandazione accettata.
- **Reddito lordo** del cliente (`redditoLordoAnnuo`) per le deduzioni; **costi** (`costoComplessivo`) delle posizioni
  sostituite e nuove; **raccomandazioni registrate** con l'esito (Studio › Track record); **riferimenti di rendimento**
  (Impostazioni › Rendimenti di confronto, Mercato); **parcelle** registrate; **aliquote provvigionali** Alleanza
  (Impostazioni › Studio) se si vuole il confronto completo.
- **Testo della nota e del titolo**: è una comunicazione al cliente sul valore del proprio lavoro (vedi §4.8): l'utente
  deve dare o approvare il testo; Prisma non lo inventa.
- Ogni voce senza dati ha la sua frase (§4.1); senza nessuna voce, lo stato «presto per misurare».
- **Dati di prova**: valori costruiti dai dati fittizi (raccomandazioni, sostituzioni, parcelle) segnati «dati di prova».

#### 4.4.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `675-sala-valore` / `-scuro` | Giulia con tutte le voci: titolo con la cifra, quattro riquadri con le parti per canale, barre del valore e del compenso a due canali, riquadro del rapporto, nota |
| `676-sala-valore-parziale` | un cliente con solo deduzioni e protezione: «Costi tagliati» e «Rispetto all'alternativa» con la frase al posto della cifra, titolo «vale almeno …» |
| `677-sala-valore-presto` | cliente nuovo (Andrea): «Ne parleremo al primo riesame» e solo «E in più, protetto» se c'è |
| `678-sala-valore-dettaglio` | il dettaglio aperto da «Costi tagliati» con le sostituzioni |

#### 4.4.8 Regole di CLAUDE.md toccate e decisioni

Regole toccate: **principio dell'analisi** (è un'analisi del lavoro fatto, con i motori; non una pubblicità);
**canale sempre distinto** (Alleanza e indipendente separati nelle cifre e nel compenso); dati in locale (nessun invio:
il template non lo fa uscire né sul tavolo né nel file del cliente); tema Apple (numeri contati, barre, cascata).
Nessuna API sopra macOS 13; nessuna dipendenza esterna.

**Decisioni per l'utente:**
1. **Comunicazione sul valore del consulente**: mostrare al cliente «il nostro lavoro vale circa X €» e «per ogni euro di
   parcella, Y euro di valore» è una comunicazione sui risultati della consulenza. Va verificata con le regole che valgono
   per l'utente (OCF per l'attività indipendente, Alleanza per l'attività da agente) e il testo della nota va dato o
   approvato dall'utente. **Prisma non può inventare** né il testo né l'avvertenza.
2. **Attribuzione**: contano solo le posizioni nate da raccomandazioni accettate dopo l'inizio del rapporto (proposta)
   oppure anche ciò che il cliente aveva già. Le deduzioni del fondo pensione il cliente le avrebbe avute anche da solo:
   si contano come «valore» solo se il fondo è nato dal consiglio (proposta).
3. **Compenso a confronto**: solo le parcelle (template) o parcelle + provvigioni stimate + costi dei prodotti, per canale
   (proposta). Per un cliente solo Alleanza, «Valore e parcelle» va tolto o diventa «Valore e costi».
4. **Rapporto «per ogni euro»**: tenerlo (con il valore vero anche quando è basso) o toglierlo.
5. **«E in più, protetto»**: solo il capitale caso morte (proposta) o la somma di più rischi (che non si sommano davvero).
6. **Periodo**: dall'inizio del rapporto (proposta, con `clienteDal`) o «tre anni» fissi.
7. **«Metti nel riesame»**: oggi il prospetto del riesame (`CompositoreProspetti.riesame`) è **per il consulente**; metterci
   «Quanto vale avermi accanto» va bene così. Se invece il prospetto (o una pagina sola) va **dato al cliente** come PDF,
   esce dal Mac quando il consulente lo consegna ed è una comunicazione al cliente (punto 1): da decidere; proposta: solo
   nel prospetto per il consulente, come il template che non lo fa uscire.
8. **Reddito degli anni passati** non c'è: stima con il reddito di oggi segnata «stima» (proposta) o chiederlo anno per
   anno.
9. **Riferimenti del confronto con l'alternativa**: vengono da Impostazioni › Rendimenti di confronto e dalle serie di
   Mercato già in archivio; nessuna richiesta di rete nasce da questa esperienza e nessun dato del cliente esce
   (`ClienteMercato.richiesta` resta l'unica porta, con l'interruttore spento di base).

---

### Riepilogo per chi implementa

**Motori esistenti usati** (nomi verificati con grep in `Sources/Prisma`): `MotorePrevidenza.calcola` /
`EsitoPianoPrevidenziale`; `MotorePensionePubblica.stima` / `pensioneDaUsare`; `MotoreMonteCarlo` (`GeneratoreSeme`,
`linea`, `volatilita`, `seme`) e la regola di `simula`; `MotoreLineaVita` / `EventoLineaVita`; `MotoreProtezioneFamiglia`
/ `TutelaRischio`; `MotoreLiquidita`; `MotoreResistenza.sopportabile` e `.crisi`; `MotoreCoerenza.sriMassimo`;
`MotoreAdeguatezza` (controllo rischio, solo per riferimento: il gioco non lo cambia); `RegoleFiscali`
(`risparmioDeduzione`, `premiDetraibili`); `MotoreCosti`; `MotoreSostituzione`; `MotoreTrackRecord`; `MotoreParcelle`;
`MotoreStudio.eventi`.

**Motori nuovi**: `MotoreGiocoRischio`, `MotoreGiornataPensione`, `MotoreLanciaAnno`, `MotoreValoreConsulente`, più
l'adattatore comune `PensioneEsperienze` (parte comune §4.8). Prova unica `Motori/ProvaCalcoliSala.swift`.

**Campi nuovi dell'archivio** (versione dopo la 26, una sola per tutta Luce, letti con `decodeIfPresent`, nel backup e in
`Prisma --prova-backup`): `DatiPrisma.partiteRischio`, `Analisi360.giornata`, `Impostazioni.sala` (`eventiAnno`,
`anniPartita`, `avvertenzaValore`, testi approvati), `Posizione.indennizzoStimato`, `Cliente.clienteDal`.

**Risorse nuove**: `Sources/Prisma/Risorse/Sala/gioco-rischio.json`, `Sources/Prisma/Risorse/Sala/eventi-anno.json`.

**Viste nuove**: `Shell/SalaGiocoRischio.swift`, `Shell/SalaGiornataPensione.swift`, `Shell/SalaLanciaAnno.swift`,
`Shell/SalaValoreConsulente.swift`; componente estratto `DesignSystem/Apple/OpzioneLettera.swift`; token in
`DesignSystem/Apple/Tema.Apple+SalaGiochi.swift`; pagina Impostazioni › Sala.

**Componenti esistenti da estendere** (revisione, senza cambiare gli usi di oggi): `TracciatoGrafico` riceve `durata:`
(la linea da 2,2 s del gioco del rischio) e un modo per prolungare la linea da dove finiva (Lancia l'anno);
`SegmentatoPillola` riceve ← → con `.focusable()` e `.onMoveCommand` come `TastieraCursoreApple`; `OpzioneOCFVista` e
`TremolioOCF` escono da `Shell/StudioEsameOCF.swift` come `OpzioneLettera`. Il file dei token
`Tema.Apple+SalaGiochi.swift` è un'estensione dello spazio `Tema.Apple.SalaEsperienze` che la parte comune mette in
`Tema.Apple+SalaEsperienze.swift`.

**Istantanee**: 660-663 (rischio), 665-668 (giornata), 670-673 (lancia l'anno), 675-678 (valore): da riallineare nella
tabella generale delle serie di Luce insieme alle altre parti.

---

## 5. Territorio, la tua settimana e il tuo anno, la palestra della trattativa, i traguardi festeggiati

*Parte 05 · quattro novità del gruppo «Davanti al cliente» (pannello Novità, `NOV15` riga 1778-1779: voci 2, 6, 7 e 10)*

Fonte: `Design/template-luce.html` (5 novembre 2026). Le righe citate sono di quel file. Per tutto ciò che qui non è detto
valgono `Design/template-novita-specifica.md` («Orizzonte»), `Design/template-apple-specifica.md` e la parte comune di Luce
(`luce/01-comune.md`: dock, icone, glifi, `TelaAnimata`, sovrapposizioni a tutto palco, `NovitaLuce`, `appRiservate`).
**Le cifre e i nomi del template sono dimostrativi**: nell'app vengono dai motori di Prisma e dai dati dell'archivio; dove
un dato manca Prisma lo dice, non lo inventa.

Schermate di lavoro (non nel repository, si rigenerano con `luce/script/shot05.js`, Playwright, 1480×940, palco 1440×900):
`luce/img/05-{c,s}-ter-oggi.png`, `-ter-crescita-inizio.png`, `-ter-crescita-fine.png`, `-ter-giro.png`,
`-ter-giro-con.png`, `-sett-0…5.png`, `-anno-0…6.png` (tavola: `05-tavola-storie.png`), `-pal-1.png`, `-pal-2.png`,
`-pal-fine.png`, `-fest-0.png`, `-fest-0-fermo.png`, `-fest-1.png` (`c` chiaro, `s` scuro).

Funzioni d'appoggio del template usate in tutte e quattro (righe 378-402, 1183-1184): `conta`/`conteggi` (numeri contati,
quartica in uscita, 1100 + min(i,6)·60 ms), `entrata` (cascata `.st`, 720 ms, passo 48), `anello` + `accendi` (anelli,
1,4 s, passo 130), `disegnaLinea`/`linee` (1500 ms, `uscita`), `segmenti` (pillola), `toast` (2,4 s), `anima` (un
`requestAnimationFrame` finché l'elemento esiste), `tela` (canvas a ×2 al più). In Prisma corrispondono a
`NumeroCheConta` (`DesignSystem/Apple/CifreApple.swift:77`), `EntrataApple` (`CascataApple.swift:69`),
`AnelliConcentrici` (`AnelliApple.swift:28`), `TracciatoGrafico` (`GraficiApple.swift:206`), `SegmentatoPillola`
(`ControlliApple.swift:19`), al toast della shell e alla `TelaAnimata` proposta nella parte comune (§4 «Tela animata»).

Numerazione delle istantanee di questa parte: serie **700-739** (verificato con grep: in `Sources/` i numeri arrivano a
613; la parte comune usa 620-629, le Sale 650-668). 700-709 Territorio, 710-719 storie, 720-729 palestra, 730-739
traguardi. Tutte nello stato finale (`\.modoIstantanea` + `\.prismaStatoFinale`), 1440×900, chiaro e `-scuro` dove detto.

Archivio: oggi `DatiPrisma.versioneAttuale = 26` (`Dati/DatiPrisma.swift:113`). I campi nuovi di questa parte vanno nella
versione unica di Luce (27, da decidere una volta sola con le altre parti), tutti facoltativi e letti con
`decodeIfPresent`, nel backup e in `Prisma --prova-backup` (nuova `Dati/ProvaBackupLuceRelazione.swift`, nome proposto, o
dentro la prova comune di Luce).

---

### 5.1 Il tuo territorio

*Nuova app **Territorio** nel dock (dopo Agenda, parte comune §2). Voce Novità 2: «Il tuo territorio · I clienti come
luci, la crescita, il giro», glifo `mappa` #2A6FA0, `vaiA('territorio',()=>{terM='oggi'})` (riga 1778). Codice: righe
1651-1698; CSS `.todoR` 238-239; icona `Territorio` riga 2160.*

#### 5.1.1 Cosa si vede

**1.1 La finestra.** Finestra interna standard. Barra del titolo «Territorio» con l'icona; testata h1 **«Il tuo
territorio.»**, occhiello **«I CLIENTI NELLA TUA ZONA»** (sorgente «I clienti nella tua zona», riga 1661); a destra il
segmentato a pillola **«Oggi» · «La crescita» · «Il giro di domani»** (valori `oggi`, `crescita`, `giro`; si apre su Oggi,
`let terM='oggi'`, riga 1652; la voce Novità forza Oggi).

Il contenuto è tutto una **mappa**: una card (`.card`, raggio 22) che riempie l'area (1384×654 nel palco), con dentro un
SVG di pari misura (riga 1662). Sopra la mappa, a sinistra, un **pannello** opaco (`#terP`, `.glass` ma con
`background:var(--cardE)`: in pratica una card piena) a 16 dai bordi, largo 340, alto tutta l'area meno 32, raggio 22,
padding 20/22. Il contenuto del pannello cambia con la vista.

**1.2 La mappa di base** (`terBase`, riga 1665-1671). **È sempre scura, anche nel tema chiaro** (`const d=true`):
- fondo #0C1720 con una vignettatura radiale (centro 60%/50%, raggio 70%, da #1A3044 a #0A121A);
- un fiume: curva larga 26, colore #18344A, estremità tonde, che attraversa da sinistra in basso a destra;
- quattro strade principali (bianco al 11%, spessore 7) e una trama di strade minori (bianco al 4,5%, spessore 3);
- i nomi di sette **zone** in maiuscolo (13 pt, 600, spaziatura 0,5, bianco al 38%, centrati): «Centro storico»,
  «Borgo Nuovo», «San Michele», «Le Fornaci», «Colle Alto», «Ponte Vecchio», «Lungofiume» (`ZONE`, riga 1653).
- La mappa è **inventata**: il template non ha una cartografia vera (vedi §5 e §8, la decisione più importante di questa
  novità).

**1.3 Le luci** (`luce`, riga 1672-1674). Ogni cliente è un punto luminoso nella sua posizione:
- raggio r = 4 + √(patrimonio / 60.000) · 3,2 (Giulia, 410.000 € → circa 12; un cliente da 40.000 € → circa 6,6);
- **alone** colorato: cerchio di raggio 3,2·r, opacità 0,35, sfocatura gaussiana 7. Colore per canale: Alleanza
  #5B8CFF, Indipendente #E0A040, entrambi i canali #FFFFFF;
- **nucleo**: cerchio di raggio r con un gradiente radiale bianco → #FFE7A8 (35%) → #FFB547 trasparente;
- **centro**: cerchio bianco pieno di raggio 0,45·r;
- **anello arancio** per i clienti «con qualcosa da fare» (`todo`): cerchio vuoto di raggio r+6, tratto #FF9F0A da 2,
  che pulsa (`.todoR`, riga 238: 1,8 s, a metà scala 1,35 e opacità 0,35, all'infinito);
- **nome** accanto alla luce solo per i cinque clienti «veri» del template: 12,5 pt, 700, bianco, con un contorno #0C1720
  da 3 sotto il testo (`paint-order:stroke`), a r+8 a destra e 4 sotto il centro. Gli altri 30 punti sono anonimi.

Dati del template (`TER`, riga 1654-1657): i 5 clienti più 30 punti generati a caso intorno a sei centri; anno di inizio,
patrimonio, canale; 3-5 punti hanno `todo`.

**1.4 Vista «Oggi»** (riga 1677-1682). Tutte le luci accese. Pannello:
- etichetta `.lbl` **«OGGI»**;
- **«35 clienti»** (display 30 pt, 700, spaziatura −0,6, 6 sotto; il numero si conta);
- **«5.121.062 € seguiti nella tua zona»** (`.k` a 14 pt; la cifra si conta);
- tre tile (`.tile`, 16 sopra la prima, 10 fra le altre), ciascuna con una riga `.k` e un valore in grassetto 16 pt:
  1. «Il quartiere con più patrimonio» → **«Centro storico»**;
  2. «Dove ancora non ci sei» → **«Le Fornaci»** + «un solo cliente, tante famiglie giovani»;
  3. «Con qualcosa da fare» → **«5 clienti»** in #C25E00 + «sono i punti con l’anello arancio»; bordo della tile
     rgba(255,159,10,.4);
- in fondo al pannello (22 dai lati, 18 dal fondo, 12 pt `.k`, interlinea 1,5) la legenda «● Alleanza ● Indipendente ○
  entrambi» (pallini nei colori delle luci) e la frase **«La luce cresce con il patrimonio. Le posizioni vengono dalle
  coordinate dei comuni e dei CAP incluse in Prisma: gli indirizzi non escono.»** — è la soluzione di privacy che il
  template stesso propone (vedi §8).

**1.5 Vista «La crescita»** (riga 1683-1689). Le luci partono spente (opacità 0) e si accendono anno per anno.
Pannello:
- `.lbl` **«LA CRESCITA»**;
- l'anno in numero grande (`.bignum` a 72 pt, 700, spaziatura −2,2): **«2016»** → «2026»;
- due valori `.v` affiancati (spazio 24): **clienti** e **«… € seguiti»**, contati a ogni cambio d'anno;
- un cursore (`input type=range`, 2016-2026, 22 sopra, 10 sotto);
- pulsante primario grande a tutta larghezza **«▶︎ Guarda la crescita»**;
- `.k` **«Dieci anni di lavoro in dieci secondi: ogni luce che si accende è una famiglia che ha cominciato con te.»**
- A ogni anno, ogni cliente nuovo «nasce»: la luce scala 0 → 1,4 → 1 e un'**onda** (cerchio vuoto #FFB547 da 2) si
  allarga da raggio 6 a 46 svanendo.
- Il patrimonio «seguito» negli anni passati nel template è finto: `patrimonio · 0,93^(2026−anno)` (riga 1685). Nell'app
  viene dallo storico (§5.3).

**1.6 Vista «Il giro di domani»** (riga 1690-1697). Sulla mappa:
- tutte le luci attenuate a opacità 0,28, tranne quelle dei clienti del giro;
- il **percorso**: tratto #0A84FF da 5, estremità e giunti tondi, fatto di curve quadratiche fra le tappe (il punto di
  controllo è spostato di ±40/±30 a tappe alterne: una curva «di fantasia», non la strada vera);
- le **tappe**: cerchi di raggio 13 pieni #0A84FF con bordo bianco da 3; dentro il numero (12 pt, 800, bianco) o «⌂» per lo
  studio, alla partenza e al rientro (che nel template si sovrappongono: stesso punto);
- un'**auto**: cerchio bianco di raggio 7 con bordo #0A84FF da 3 che corre lungo il percorso;
- il **suggerimento**: attorno al cliente da aggiungere, un anello #FF9F0A da 2,5 di raggio 22 che pulsa.

Pannello:
- `.lbl` **«IL GIRO DI DOMANI · MARTEDÌ 3»**;
- **«3 tappe · 34 km»** (display 26 pt, 700) e `.k` **«1 h 09 in auto»**;
- l'elenco delle tappe, una riga ciascuna (padding 9, filo `--sep` sotto, spazio 10): ora (grassetto, 46 di larghezza,
  cifre tabellari), avatar 28 del cliente o «⌂», nome (13,5 pt grassetto) e sotto il motivo (12 pt `.k`: «partenza»,
  «Un progetto tutto suo», «Il nostro primo incontro», «rientro»), a destra il tempo fino alla tappa dopo («12 min ›»,
  11,5 pt `.k`), non sull'ultima;
- la tile **«Lungo la strada»** (bordo rgba(255,159,10,.45), fondo rgba(255,159,10,.07); titolo #B45309 grassetto):
  «**Sofia Romano** è a 6 minuti tra Laura e Andrea: ha il consenso privacy da rinnovare.» e il pulsante primario
  **«＋ Aggiungila al giro»**.
- Dopo il clic (`giroCon=true`, riga 1697): il giro si ridisegna con Sofia alle 11:15 fra Laura e Andrea (la sua riga ha
  il fondo rgba(255,159,10,.08) e raggio 10), il titolo diventa **«4 tappe · 41 km»** e **«1 h 12 in auto»**, la tile
  sparisce, toast **«Sofia aggiunta al giro alle 11:15»**.

**1.7 Incoerenze del template da non copiare**
- «3 tappe» conta studio-Laura-Andrea-studio come tre tratti; «4 tappe» dopo l'aggiunta. Nell'app le **tappe sono le
  visite** (2, poi 3) e i tratti si vedono nell'elenco: «2 visite · 34 km».
- I tempi dei tratti (12 + 19 + 18 = 49 min) non fanno «1 h 09»: nell'app il totale è la somma dei tratti.
- Partenza e rientro allo studio sono due cerchi sovrapposti: nell'app un solo cerchio «⌂».
- Il percorso disegnato con curve inventate sembra una strada ma non lo è (vedi §5.4: nell'app linee rette o
  leggermente curve dichiarate «in linea d'aria»).

**1.8 Stati** (il template non ne ha):
- **Nessun cliente con un luogo**: la mappa (vuota, solo la base) e nel pannello «Nessun cliente ha ancora un indirizzo
  che Prisma sa mettere sulla mappa.» con il pulsante «Completa gli indirizzi» (elenco dei clienti senza posizione, §6).
- **Alcuni clienti senza posizione**: in fondo al pannello «N clienti non sono sulla mappa» (collegamento all'elenco).
- **Crescita senza storico**: se mancano le date d'inizio, l'anno del cliente è quello di `creatoIl` con la nota «anno di
  inserimento in Prisma» (§6).
- **Giro senza appuntamenti fuori studio domani**: «Domani non hai visite fuori studio.» e, se c'è, il primo giorno con
  visite («Il prossimo giro: giovedì 5»), con il segmentato che resta «Il giro di domani».
- **Studio senza indirizzo**: il giro parte dalla prima visita, con l'avviso «Aggiungi l'indirizzo dello studio per
  contare anche l'andata e il ritorno» (Impostazioni › Studio › Fatturazione, `sede`).

#### 5.1.2 Misure e stile

Token nuovi in **`DesignSystem/Apple/Tema.Apple+Territorio.swift`** (`enum Tema.Apple.Territorio`):

| Template | Valore | Token proposto |
|---|---|---|
| fondo mappa | #0C1720 | `Mappa.terra` (uguale in chiaro e scuro) |
| vignettatura | radiale 60%/50% r 70%, #1A3044 → #0A121A | `Mappa.vignettaCentro`, `vignettaBordo`, `centroVignetta = UnitPoint(x: 0.6, y: 0.5)`, `raggioVignetta = 0.7` |
| fiume / acqua | #18344A, 26 | `Mappa.acqua`, `spessoreAcqua = 26` |
| strade | bianco .11 da 7; bianco .045 da 3 | `Mappa.strada`, `spessoreStrada = 7`, `Mappa.stradina`, `spessoreStradina = 3` |
| nomi delle zone | 13, 600, maiuscolo, spaziatura .5, bianco .38 | `Mappa.zona = Carattere(dimensione: 13, peso: .semibold, tracking: 0.5, maiuscolo: true)`, `coloreZona` |
| luce Alleanza / Indipendente / entrambi | #5B8CFF / #E0A040 / #FFFFFF | `Luce.alleanza`, `Luce.indipendente`, `Luce.entrambi` (**non** `canaleAlleanza`/`canaleIndipendente`: sono più chiari per stare sul fondo scuro; vedi §8 decisione 6) |
| nucleo | #FFFFFF → #FFE7A8 (0,35) → #FFB547 (0) | `Luce.nucleo: [Gradient.Stop]` |
| raggio | 4 + √(p/60.000)·3,2 | `Luce.raggioBase = 4`, `Luce.passo = 3.2`, `Luce.patrimonioUnita = 60_000`, più un `raggioMassimo = 22` (nuovo: con patrimoni grandi il template non ha limite) |
| alone | 3,2·r, opacità .35, sfocatura 7 | `Luce.quotaAlone = 3.2`, `opacitaAlone = 0.35`, `sfocaturaAlone = 7` |
| centro | 0,45·r bianco | `Luce.quotaCentro = 0.45` |
| anello «da fare» | #FF9F0A, 2, r+6 | `Luce.daFare` (= `Colore.arancio`? No: `arancio` è #E08A00; #FF9F0A è l'arancio di sistema, nuovo `Colore.aranciSistema` o `Luce.daFare`), `spessoreDaFare = 2`, `distanzaDaFare = 6` |
| nome sulla mappa | 12,5, 700, bianco, contorno #0C1720 da 3 | `Luce.nome`, `contornoNome = 3`, `distanzaNome = 8` |
| pannello | 340 di larghezza, 16 dai bordi, raggio 22, padding 20/22, riempimento `--cardE` | `Pannello.larghezza = 340`, `margine = 16`, `Raggio.card`, `Misura.padding(20, 22)`, `Superficie` piena su `Colore.cardPiena` |
| «35 clienti» | display 30, 700, −0,6 | `Pannello.totale = Carattere(dimensione: 30, peso: .bold, tracking: -0.6, tabellare: true)` |
| anno della crescita | 72, 700, −2,2 | `Pannello.anno` (variante di `Carattere.numeroGrande` a 72) |
| titolo del giro | display 26, 700 | `Carattere.valore` esiste a 26 (−0,5): **riusarlo** |
| tile «da fare» | testo #C25E00, bordo rgba(255,159,10,.4) | `Pannello.testoDaFare`, `bordoDaFare` |
| tile «Lungo la strada» | bordo rgba(255,159,10,.45), fondo .07, titolo #B45309 | `Giro.bordoSuggerimento`, `fondoSuggerimento`, `titoloSuggerimento` |
| riga suggerita | fondo rgba(255,159,10,.08), raggio 10 | `Giro.fondoRigaNuova`, `raggioRigaNuova = 10` |
| percorso | #0A84FF da 5 | `Colore.anello2` (#0A84FF, esiste) + `Giro.spessorePercorso = 5` |
| tappa | r 13, bordo bianco 3, numero 12/800 | `Giro.raggioTappa = 13`, `bordoTappa = 3`, `numeroTappa = Carattere(dimensione: 12, peso: .heavy)` |
| auto | r 7, bordo #0A84FF 3 | `Giro.raggioAuto = 7`, `bordoAuto = 3` |
| anello del suggerimento | r 22, #FF9F0A da 2,5 | `Giro.raggioSuggerimento = 22`, `spessoreSuggerimento = 2.5` |
| luci fuori dal giro | opacità .28 | `Giro.opacitaFuori = 0.28` |
| onda della crescita | #FFB547 da 2, r 6 → 46 | `Crescita.onda`, `ondaDa = 6`, `ondaA = 46` |
| righe del giro | ora 46 di larghezza, avatar 28, nome 13,5 grassetto, motivo 12, tempo 11,5 | `Giro.larghezzaOra = 46`, `Misura.Avatar.minimo`… (28 non esiste: **nuovo** `Giro.avatar = 28`), `Carattere.voceLista` 13,5 in grassetto |

Esistono già e si riusano: `Carattere.etichetta` (`.lbl`), `Carattere.secondario` (`.k`), `Superficie.tile` + `Misura.Padding.tile`
(14/16), `Raggio.tile` 18, pulsante primario grande (`Carattere.pulsanteGrande` 13,5), `Colore.accento`.

Nel **tema scuro** cambiano solo il pannello e le tile (le superfici del tema); la mappa resta identica
(`05-s-ter-crescita-fine.png`).

#### 5.1.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Entrata delle luci (Oggi) | scala 0 → 1, opacità 0 → 1, 650 ms, `cubic-bezier(.34,1.6,.64,1)`, ritardo i·22 ms (35 punti: l'ultimo a 0,75 s) | **nuovo** `Tema.Apple.Moto.Territorio.Luce` (durata 0,65, passo 0,022, curva = `Tema.Apple.Studio.Moto.curvaPunti`, già in `Tema.Apple+Studio.swift:314`); passo × min(i, 40) così con 200 clienti la cascata resta sotto 1 s |
| Pannello | cascata `.st` e numeri contati (`entrata(P)`, `conteggi(P)`, riga 1698) | `Moto.Cascata`, `Moto.Numero` |
| Cambio di vista | il template ridisegna tutto l'SVG | il pannello cambia con `rimonta` (0,13 s, scala 0,99, poi cascata); la base della mappa **resta** (niente lampo) |
| Crescita: partenza automatica | 700 ms dopo l'entrata nella vista (solo la prima volta) | `Crescita.attesaAvvio = 0.7` |
| Crescita: un anno | ogni 900 ms con `setInterval` (con `ridotto` 100 ms) | `Crescita.passoAnno = 0.9`, con un `Task` che dorme fra un anno e l'altro (cancellato al cambio di vista, alla chiusura e al blocco): **niente Timer** (CLAUDE.md); con calmo all'apertura si mostra subito l'ultimo anno |
| Luce che nasce | 0 → 1,4 → 1 in 700 ms, curva `punti` | `Crescita.nascita = 0.7`, `scalaPicco = 1.4` (in SwiftUI due fasi: 0 → 1,4 in 0,35 s, 1,4 → 1 in 0,35 s, o `keyframeAnimator` solo da macOS 14 con ripiego) |
| Onda | r 6 → 46, opacità 0,9 → 0, 1100 ms `ease-out` | `Crescita.onda = 1.1`, `Curva.easeOut` |
| Contatori (clienti, seguiti) | 600 ms da valore a valore | `Moto.NumeroCambio` (0,90) **o** nuovo `Crescita.conteggio = 0.6`: proposta 0,6 per stare dentro il passo di 0,9 |
| Percorso del giro | si disegna in 2000 ms (`uscita`) | `Giro.tracciato = 2.0`, `Curva.uscita` (come `TracciatoGrafico`) |
| Tappe | scala 0 → 1 in 500 ms, curva `punti`, ritardo 300 + i·450 ms | `Giro.tappa = 0.5`, `ritardoTappa = 0.3`, `passoTappa = 0.45` |
| Auto | parte a 2 s, percorre tutto in 6 s, poi ricomincia ogni 6 s, all'infinito | `Giro.partenzaAuto = 2`, `giroAuto = 6`; **in Prisma** l'auto fa **un solo giro** e si ferma all'arrivo (un ciclo infinito su una finestra aperta consuma senza dire niente di nuovo; vedi §8 decisione 7). `TelaAnimata` o `TimelineView(.animation(paused:))` con `paused` quando ha finito |
| Anelli arancio | pulsazione 1,8 s infinita | `Luce.pulsazione = 1.8`, `scalaPulsazione = 1.35`; con molti clienti al massimo 12 pulsano, gli altri restano fermi (memoria/CPU sul Mac da 8 GB) |

**Riduci movimento** (`\.prismaCalmo`): luci, pannello, percorso e tappe compaiono già al loro posto con la dissolvenza di
0,15 s; nessuna pulsazione; l'auto è ferma all'arrivo; la crescita mostra subito l'ultimo anno (il cursore resta usabile
e cambia l'anno senza animazione; «Guarda la crescita» **non** scorre gli anni a 0,1 s come nel template, perché dieci
cambi in un secondo sono un lampeggio, il contrario di «Riduci movimento»: proposta di farlo passare un anno alla volta al
passo normale di 0,9 s, ogni anno con la sola dissolvenza di 0,15 s, senza nascita, onda né conteggio; vedi decisione 7).
**Istantanee**: Oggi con tutte le luci, la crescita all'ultimo anno, il giro tracciato con l'auto all'arrivo; anelli
arancio fermi alla scala 1.

La mappa è disegnata con `Canvas` (una sola vista, non 35+ `Circle` con `blur`: lo sfocato di ogni alone costerebbe troppo
con 200 clienti). Proposta: gli aloni si disegnano una volta in una `CGImage` di cache (alone per colore e raggio
arrotondato) e si compongono; si ridisegna solo quando cambiano i dati o la misura.

#### 5.1.4 Interazioni

Nel template:
- segmentato Oggi / La crescita / Il giro di domani (riga 1664);
- crescita: cursore (anno), «Guarda la crescita» (ricomincia dal 2016 se è alla fine);
- giro: «＋ Aggiungila al giro» (riga 1697).
Niente clic sulle luci, niente zoom, niente trascinamento.

Proposta per Prisma (coerente col principio dell'analisi, da confermare):
- **Puntatore su una luce**: fumetto del tema con nome, canale (etichetta compatta), patrimonio seguito e, se c'è, la cosa
  da fare. Per i punti senza nome è l'unico modo di sapere chi sono.
- **Clic su una luce**: apre il dossier del cliente (`StatoShell.apri(.clienti)` con il cliente attivo); con ⌥ clic la
  posizione (Posizioni).
- **Clic su una tile di Oggi**: «Il quartiere con più patrimonio» filtra le luci di quella zona; «Con qualcosa da fare»
  mostra solo gli anelli arancio con l'elenco nel pannello.
- **Zoom e spostamento**: pizzico sul trackpad e trascinamento (sul Mac `MagnificationGesture`/`DragGesture`; da macOS 14
  esiste `MagnifyGesture`, va protetto). Doppio clic: torna a vedere tutti.
- **Giro**: clic su una riga → l'appuntamento in Agenda; «＋ Aggiungila al giro» **non** sposta niente da solo: crea un
  appuntamento **proposto** («Visita · Sofia Romano · 11:15, da confermare») nell'orario libero fra le due visite e lo
  mostra con la spunta «Conferma in Agenda» (toast «Sofia nel giro alle 11:15: confermala in Agenda»). Se il cliente va
  avvisato, c'è il collegamento a Messaggi con il motivo (consenso da rinnovare).
- **Giro di un altro giorno**: frecce ‹ › accanto alla data nel titolo del pannello (il template ha solo «domani»).
- **Tastiera**: ⌘1…⌘3 sulle viste se non vanno in conflitto con `ComandiShell.swift`; Esc chiude il fumetto.
- **iPhone/iPad**: il template non li mostra. Proposta minima: su iPhone la vista «Il giro di domani» come elenco con la
  mappa piccola in alto (cosa principale grande in alto, Design/iphone.html), stessa mappa locale.
- **Modalità cliente**: Territorio è **riservata** (mostra tutti i clienti): `appRiservate` della parte comune.

#### 5.1.5 Mappa verso Prisma

**5.1 Esiste già (verificato con grep in `Sources/Prisma`)**
- `Cliente.indirizzo: String` (testo libero, `Dati/Modelli.swift:47`), `Cliente.canali: [Canale]`, `Cliente.creatoIl`.
- `DatiFiscaliCliente.sede: SedeFiscale` con **`cap`, `comune`, `provincia`, `indirizzo`, `numeroCivico`, `nazione`**
  (`Dati/DatiFatturazione.swift:234-243`, 539): i campi strutturati per i clienti con dati di fattura.
- `DatiFatturazione.sede` del consulente (`Impostazioni.studio.fatturazione.sede`, `DatiFatturazione.swift:476`): è
  l'indirizzo dello studio, partenza e rientro del giro.
- `Appuntamento` con `inizio`, `durataMinuti`, `luogo: String` («In studio», «Videochiamata»…), `clienteId`, `tipo`
  (`TipoAppuntamento`: primoIncontro, analisi, proposta, firma, revisione, telefonata, altro), `stato`
  (`Dati/Modelli.swift:341-400`).
- Patrimonio seguito: `Posizione.valore` (calcolato, `Dati/Posizione.swift:309`, da `controvalore`, riga 163, che per i
  debiti è il debito residuo) e lo storico `MotoreAndamentoPortafoglio.valore(_:al:)`
  (`Motori/MotoreAndamentoPortafoglio.swift:115`), lo stesso che usa «Un anno insieme».
- «Qualcosa da fare»: `MotoreDaFare.calcola` (`Motori/MotoreDaFare.swift:152`), `MotoreAttenzioni.calcola(clienti:posizioni:)`
  (`Motori/MotoreAttenzioni.swift:82`), conformità (`MotoreConformita`, consenso scaduto) e occasioni (`MotoreOccasioni`).
- Orari di lavoro per trovare uno spazio libero: `Dati/OrariLavoro.swift`, `Impostazioni.orari`.
- Nessun uso di MapKit, CoreLocation o `CLGeocoder` nel codice (grep vuoto): oggi Prisma non ha né mappe né geocodifica.

**5.2 Da creare**
- `AppPrisma.territorio` (parte comune), vista **`Shell/AppTerritorio.swift`** con `enum VistaTerritorio { oggi, crescita,
  giro }` e `@Published var vistaTerritorio` in `StatoShell` (come `schedaStudio`).
- **`Shell/MappaTerritorio.swift`**: la mappa disegnata (`Canvas`), con proiezione, zoom, luci, nomi, percorso, tappe, auto.
- **`Shell/PannelloTerritorio.swift`**: i tre pannelli.
- **`Motori/MotoreTerritorio.swift`** (puro, senza SwiftUI, con `oggi` passato), tenuto in cache come gli altri
  (`DerivatiDati`):

```swift
struct LuogoCliente { let clienteId: String; let coordinata: Coordinata; let precisione: PrecisioneLuogo; let zona: String? }
enum PrecisioneLuogo { case manuale, cap, comune }          // dalla più alla meno precisa
struct Coordinata: Codable, Hashable { var lat: Double; var lon: Double }
struct LuceCliente { let cliente: Cliente; let luogo: LuogoCliente; let patrimonio: Double; let canale: CanaleLuce
                     let daFare: String?; let annoInizio: Int; let annoStimato: Bool }
enum CanaleLuce { case alleanza, indipendente, entrambi }
struct TerritorioOggi { let luci: [LuceCliente]; let totale: Double; let senzaLuogo: [Cliente]
                        let zonaPiuRicca: (nome: String, patrimonio: Double)?; let zoneScoperte: [ZonaScoperta]
                        let conQualcosaDaFare: Int }
struct AnnoCrescita { let anno: Int; let clienti: Int; let patrimonio: Double?; let nuovi: [String] }
struct GiroGiorno { let giorno: Date; let partenza: Coordinata?; let tappe: [TappaGiro]; let km: Double; let minuti: Int
                    let suggerimenti: [SuggerimentoGiro]; let stima: Bool }
struct TappaGiro { let appuntamento: Appuntamento?; let cliente: Cliente?; let coordinata: Coordinata; let kmDaPrima: Double; let minutiDaPrima: Int }
struct SuggerimentoGiro { let cliente: Cliente; let motivo: String; let deviazioneMinuti: Int; let fraTappe: (Int, Int); let ora: Date }
enum MotoreTerritorio {
    static func oggi(dati: DatiPrisma, luoghi: [String: LuogoCliente], oggi: Date) -> TerritorioOggi
    static func crescita(dati: DatiPrisma, luoghi: [String: LuogoCliente], oggi: Date) -> [AnnoCrescita]
    static func giro(dati: DatiPrisma, luoghi: [String: LuogoCliente], giorno: Date, impostazioni: ImpostazioniTerritorio) -> GiroGiorno
}
```

**5.3 Regole di calcolo (da confermare)**
- **Patrimonio della luce**: somma di `Posizione.valore` delle posizioni **in essere** del cliente, esclusi i debiti
  (`AreaPosizione.debiti`). Se il consulente preferisce, solo ciò che segue lui (le posizioni con un canale) — decisione 5.
- **Canale della luce**: dalle posizioni in essere (`Posizione.canale`): solo Alleanza, solo indipendente, entrambi; senza
  posizioni, da `Cliente.canali`.
- **Totale «seguiti nella tua zona»**: somma dei patrimoni delle luci **sulla mappa** (i clienti senza luogo sono contati a
  parte: «N non sulla mappa»).
- **Zona con più patrimonio**: somma per zona (§5.4), la più alta. Mai una zona con un solo cliente se si mostra la cifra
  (la cifra non si mostra comunque: solo il nome, come nel template).
- **«Dove ancora non ci sei»**: richiede dati sulla popolazione per zona (quante famiglie, che età). Prisma non li ha.
  Proposta: o si toglie la tile, o la si sostituisce con un dato che Prisma ha («La zona con un solo cliente», senza «tante
  famiglie giovani»), o si importano a mano i dati ISTAT della popolazione per comune (pubblici) — decisione 4. Mai la
  frase «tante famiglie giovani» senza un dato.
- **«Con qualcosa da fare»**: clienti con almeno una voce di `MotoreDaFare` aperta o una `Attenzione` alta o un consenso
  scaduto. L'anello arancio è lo stesso criterio.
- **Anno d'inizio** (crescita): il primo fra la `decorrenza` più vecchia delle posizioni in essere o chiuse, la data del
  primo appuntamento concluso, `Cliente.creatoIl`. Se è solo `creatoIl` (data d'inserimento in Prisma), l'anno è
  `annoStimato` e la crescita lo dice (§6).
- **Patrimonio negli anni** (crescita): per ogni anno, la somma di `MotoreAndamentoPortafoglio.valore(p, al: 31/12)` delle
  posizioni del cliente in essere a quella data. Dove lo storico non c'è (nessuna rilevazione né decorrenza) il valore è
  nil e il pannello mostra solo i clienti, con «patrimonio di quell'anno non disponibile» (mai lo 0,93 del template).
- **Primo anno della crescita**: il più vecchio fra gli anni d'inizio (non fisso al 2016); l'ultimo è l'anno in corso.
- **Giro**: gli appuntamenti del giorno con un cliente, non telefonate, non «Videochiamata», non «In studio» (riconoscere
  `luogo`: proposta di un campo nuovo `Appuntamento.doveAvviene: DoveAppuntamento? { studio, dalCliente, altrove(String),
  aDistanza }`, perché il testo libero è fragile). La tappa sta nel luogo del cliente (o in quello scritto
  nell'appuntamento, se Prisma lo sa mettere sulla mappa). Ordine: per ora. Partenza e rientro: la sede dello studio.
- **Chilometri e minuti**: senza un servizio di percorsi (che vorrebbe dire rete) Prisma può solo **stimare**: distanza in
  linea d'aria (formula dell'emisenoverso) × un **fattore strada** (proposta 1,3) e una **velocità media** (proposta 40
  km/h in città, 70 fuori) con un minimo di 5 minuti a tratto. Tutto dichiarato: «circa 34 km · stima in linea d'aria».
  Fattore e velocità in `ImpostazioniTerritorio` (l'utente li corregge). Vedi §8 per le alternative.
- **Suggerimento «lungo la strada»**: clienti con qualcosa da fare (stesso criterio), non già nel giro, per i quali la
  deviazione stimata fra due tappe consecutive (A→C→B meno A→B) è sotto una soglia (proposta 10 minuti) **e** c'è uno
  spazio libero in agenda fra le due tappe che basta per tragitto + una visita breve (proposta 30 minuti). Si propone il
  migliore (deviazione più piccola, priorità più alta); al massimo 3, il primo in evidenza.
- **Chilometri per Studio › Spese** (riga 2052, «I chilometri di ottobre · dal Territorio, da soli»): il giro di ogni
  giorno passato con visite concluse dà i km del mese. È la stessa stima: la sezione «Chilometri, spese e scadenze» deve
  dire «stima» o lasciare correggere i km giorno per giorno (coordinare con quella parte; per il rimborso chilometrico i
  km stimati non bastano: decisione 3).

**5.4 La mappa, tutta in locale (proposta)**
- **Dove sta un cliente**: una tabella **dei comuni italiani con le coordinate** (centroide) e una **dei CAP con le
  coordinate**, dentro Prisma, in `Sources/Prisma/Risorse/Territorio/comuni.json` e `cap.json` (nomi proposti), come già
  fanno `famiglie-bdi-2022.json` e `Mercato/serie-mercato.json`. Prisma legge `SedeFiscale.cap`/`comune` se ci sono,
  altrimenti cerca CAP (5 cifre) e comune nel testo di `Cliente.indirizzo` (con la provincia per i nomi doppi). **Nessun
  indirizzo esce dal Mac**: è la frase del template stesso.
  - Peso: circa 7.900 comuni × (codice ISTAT, nome, sigla della provincia, lat, lon) ≈ 400 KB in JSON (meno in un formato
    compatto a colonne); i CAP circa 4.600 righe ≈ 150 KB. Si caricano solo all'apertura di Territorio e si liberano alla
    chiusura (Mac da 8 GB).
  - Precisione: il comune o il CAP, **non** la via. Due clienti dello stesso comune finirebbero sullo stesso punto: si
    distribuiscono con uno **sparpaglio deterministico** (una spirale attorno al centroide, ordinata per id del cliente,
    raggio proporzionale all'estensione del comune) e il fumetto dice «posizione del comune». Il raggio è piccolo e la
    posizione non finge di essere la casa.
  - **Posizione a mano**: nel dossier (o trascinando la luce in modalità «Sposta», proposta) il consulente può mettere il
    cliente nel punto giusto: `Cliente.luogo: LuogoManuale?` (§5.6). È la sola strada per la precisione della via senza
    servizi esterni.
- **Cosa si disegna sotto le luci**: una cartografia vera locale non c'è. Tre livelli possibili, tutti locali:
  1. **Solo i nomi dei comuni** (o delle zone) sul fondo scuro, con le luci: è ciò che il template mostra davvero (strade e
     fiume sono decorativi e inventati). Leggero, nessun dato in più. **Proposta per il primo giro.**
  2. **I confini dei comuni** della zona del consulente (ISTAT pubblica i confini amministrativi; versione generalizzata,
     solo le province scelte): tratti sottili come le «strade» del template. Qualche centinaio di KB per provincia; da
     convertire una volta in un formato semplice (lista di poligoni) con uno script nel repository, niente dipendenze.
  3. **Strade e fiumi veri** da un estratto OpenStreetMap della provincia: molto più pesante (decine di MB), licenza ODbL da
     citare, un lettore da scrivere. Sconsigliato per il Mac da 8 GB.
- **Le zone** («Centro storico», «Borgo Nuovo»): i quartieri non sono un dato pubblico uniforme. Proposta: la zona è il
  **comune** (o la frazione, se il consulente lavora in una sola città); in alternativa il consulente disegna o nomina le
  sue zone (`ImpostazioniTerritorio.zone: [ZonaTerritorio]` con nome, centro e raggio) — decisione 4.
- **Proiezione**: equirettangolare locale (x = lon·cos(lat medio), y = lat), adatta alla zona dei clienti con un margine;
  basta per una provincia o una regione. I clienti di prova sono sparsi fra Bologna, Torino, Verona, Padova e Trento
  (`Dati/DatiDemo.swift:63-157`): la mappa di prova sarà regionale, non di quartiere, e le «zone» saranno comuni.

**5.5 Alternative con servizi esterni (escono dal Mac: solo con il via dell'utente)**
- **MapKit (mappe Apple) per il fondo**: le tessere della mappa arrivano dai server Apple; le luci si disegnano in locale,
  quindi **i dati dei clienti non escono**, ma Apple vede quali zone si guardano (e l'IP). È internet, contro la regola
  «niente internet». Su macOS 13 `Map` di SwiftUI esiste (con annotazioni limitate); l'API ricca è da macOS 14 (da
  proteggere).
- **Geocodifica con `CLGeocoder` / MapKit**: manda **l'indirizzo del cliente** ad Apple. È un dato personale che esce: da
  escludere, salvo un via esplicito dell'utente, cliente per cliente, e mai di base.
- **Percorsi stradali veri (`MKDirections`)**: mandano partenza e arrivo (quindi gli indirizzi) ad Apple. Stesso giudizio.
- **Servizi OpenStreetMap (Nominatim, OSRM)**: stessi problemi, più termini d'uso da rispettare.
- **«Apri il giro in Mappe»** (richiesta prevedibile, il template non la ha): aprire Mappe di Apple o Google Maps con le
  tappe (`maps://`, `MKMapItem.openMaps`) consegna **gli indirizzi dei clienti** all'app di mappe e ai suoi server. Se mai
  si fa, solo su clic, tappa per tappa, con l'avviso; non nel primo giro.
- **Posizione del dispositivo** (`CoreLocation`, per esempio «metti qui il cliente» sull'iPhone durante la visita, o il giro
  che parte da dove sei): chiede il permesso di localizzazione ed è un servizio Apple; il template non lo prevede. Proposta:
  no, solo posizione a mano.
Proposta: nessuna di queste nel primo giro; la stima locale dichiarata.

**5.6 Campi nuovi dell'archivio (versione di Luce)**
- `Cliente.luogo: LuogoManuale?` = `{ coordinata: Coordinata; nota: String }`: la posizione messa a mano. nil = dal
  comune/CAP.
- `Appuntamento.doveAvviene: DoveAppuntamento?` (vedi §5.3), con lettura tollerante: nil = si prova a capire da `luogo`.
- `Impostazioni.territorio: ImpostazioniTerritorio` = `{ fattoreStrada = 1.3; velocitaCitta = 40; velocitaFuori = 70;
  deviazioneMassima = 10; durataVisitaBreve = 30; zone: [ZonaTerritorio] = []; partenza: LuogoManuale? }` (`partenza` se
  lo studio non è la sede fiscale).
- Le tabelle dei comuni e dei CAP sono risorse, non archivio: non vanno nel backup.

**5.7 Prove**
- `Motori/ProvaCalcoliTerritorio.swift` (chiamata da `ProvaCalcoli.esegui()`, `Motori/ProvaCalcoli.swift:6`):
  1. CAP e comune letti da `SedeFiscale` e dal testo libero («Via dei Mille 12, 40121 Bologna» → CAP 40121; «Via Roma 210,
     Padova» → comune Padova); nome ambiguo senza provincia → nessuna posizione e cliente in «senza luogo».
  2. Sparpaglio deterministico: due esecuzioni danno gli stessi punti; tre clienti dello stesso comune non si sovrappongono.
  3. Distanza: Bologna-Padova in linea d'aria ≈ 110 km fra i due centri (il valore atteso si calcola con le coordinate della tabella; tolleranza 2%), × 1,3; minuti con la velocità.
  4. Giro: telefonate, videochiamate e appuntamenti in studio esclusi; ordine per ora; totale = somma dei tratti.
  5. Suggerimento: un cliente con consenso scaduto a metà strada entra, uno a 30 minuti di deviazione no; senza spazio in
     agenda no.
  6. Crescita: anno d'inizio dalla decorrenza più vecchia; patrimonio nil senza storico (mai stimato con un fattore).
  7. Prestazioni: 200 clienti di `--prova-carico` in un tempo lineare; le tabelle si caricano una volta.
- **Prova di privacy** (come `ProvaCalcoliMercato`): Territorio non fa richieste di rete (nessun `URLSession` nel motore e
  nella vista; prova statica come quella di Mercato).

#### 5.1.6 Dati che l'utente deve dare (mai inventarli) e stati vuoti

1. **Dove sono i clienti**: CAP e comune (oppure l'indirizzo con il CAP) per ogni cliente; dove serve, la posizione a mano.
   Senza: il cliente non è sulla mappa e finisce nell'elenco «Non sulla mappa» con il pulsante «Aggiungi il CAP».
2. **Dove è lo studio**: la sede in Impostazioni › Studio › Fatturazione o una partenza diversa. Senza: il giro parte dalla
   prima visita (stato in §1.8).
3. **Dove avvengono gli appuntamenti**: «dal cliente», «in studio», «altrove» (campo nuovo); senza, Prisma prova a capire
   dal testo e, se non capisce, la visita non entra nel giro e la riga dice «luogo da indicare».
4. **Fattore strada e velocità** (oppure il via ai valori proposti, dichiarati «stima»).
5. **Le zone**, se si vogliono i quartieri (altrimenti i comuni).
6. **Dati sulla popolazione** per «Dove ancora non ci sei», se si tiene quella frase (decisione 4).
7. **Anni d'inizio** dei clienti di vecchia data inseriti di recente: senza, la crescita usa l'anno d'inserimento e lo
   dice: «8 clienti hanno l'anno d'inserimento in Prisma, non quello d'inizio».

Stati vuoti: §1.8. **Dati di prova**: i clienti di prova hanno già indirizzo con città; si aggiungono CAP coerenti in
`DatiDemo`/`ClientiFittizi` e un giro di prova per domani; etichetta «dati di prova» nel pannello. Mai nell'archivio reale.

#### 5.1.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `700-territorio-oggi` / `-scuro` | dati di prova, vista Oggi, tutte le luci, tre tile, legenda |
| `701-territorio-crescita` / `-scuro` | crescita all'ultimo anno (stato finale), cursore a destra |
| `702-territorio-crescita-anno` | crescita ferma a un anno intermedio (cursore a metà) |
| `703-territorio-giro` / `-scuro` | giro di domani con 2 visite, il suggerimento e la tile «Lungo la strada» |
| `704-territorio-giro-aggiunto` | dopo «Aggiungila al giro»: 3 visite, la riga proposta in evidenza |
| `705-territorio-vuoto` / `-scuro` | archivio senza clienti con un luogo |
| `706-territorio-senza-luogo` | alcuni clienti fuori mappa: avviso in fondo al pannello ed elenco aperto |
| `707-territorio-giro-vuoto` | domani nessuna visita fuori studio, con il prossimo giorno di giro |
| `708-territorio-fumetto` | il fumetto di una luce (solo chiaro) |
| `709-impostazioni-territorio` / `-scuro` | fattore strada, velocità, zone, partenza |

#### 5.1.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole toccate: **dati in locale** (mappa e geocodifica: il punto decisivo), tema Apple e valori in `DesignSystem`
(una superficie scura fissa nel tema chiaro), movimento con calmo e istantanee, Mac da 8 GB (molti punti sfocati, tabelle
dei comuni), target macOS 13 (`MagnifyGesture` e la `Map` ricca di macOS 14 da proteggere), dipendenze esterne (nessuna
nella proposta), modalità cliente (Territorio riservata).

**Decisioni:**
1. **Mappa e geocodifica (privacy).** Proposta: tutto locale — tabelle di comuni e CAP dentro Prisma, posizione a mano per
   la precisione, fondo senza cartografia (solo nomi, livello 1 di §5.4), nessuna richiesta di rete. Alternative: (a)
   confini ISTAT dei comuni (livello 2, locale); (b) MapKit solo per il fondo (internet: Apple vede le zone, non i
   clienti); (c) geocodifica Apple degli indirizzi (gli indirizzi escono: da escludere). **Serve il via esplicito.**
2. **Fonte e licenza delle tabelle**: elenco dei comuni e coordinate (ISTAT pubblica l'elenco dei comuni e i confini con
   licenza CC BY; le coordinate dei centroidi si ricavano dai confini) e coordinate dei CAP (non pubblicate da Poste in
   forma aperta: servono una fonte aperta da scegliere o il ripiego sul comune). Da scaricare **una volta, a mano, durante
   lo sviluppo**, non dall'app; la licenza va citata in Impostazioni › Informazioni.
3. **Chilometri stimati**: vanno bene «in linea d'aria × fattore» per il giro e per Studio › Spese? Per un rimborso
   chilometrico o per il commercialista servono i km veri: proposta di lasciarli correggere a mano giorno per giorno.
4. **«Dove ancora non ci sei · tante famiglie giovani»**: togliere la seconda frase, importare a mano i dati ISTAT della
   popolazione per comune, o lasciare solo «la zona con un solo cliente»? E le zone: comuni, frazioni o zone disegnate dal
   consulente?
5. **Che patrimonio fa la luce**: tutte le posizioni in essere del cliente o solo quelle che il consulente segue?
6. **Colori delle luci**: #5B8CFF e #E0A040 non sono i colori dei canali (#2563EB, #B06E12) ma le loro versioni chiare
   per il fondo scuro (come `canaleAlleanza` nello scuro, #6B95FF). Va bene che il canale si riconosca da una tinta
   diversa da quella dell'etichetta? (CLAUDE.md: canale sempre riconoscibile.) Proposta: usare le tinte scure del tema
   (#6B95FF e #D0954A) per coerenza.
7. **L'auto che gira all'infinito** e gli anelli che pulsano: proposta di un solo giro e di pulsazioni limitate. E con
   «Riduci movimento»: «Guarda la crescita» a un anno ogni 0,9 s con la sola dissolvenza (proposta) o subito l'ultimo anno?
8. **«Aggiungila al giro»**: crea un appuntamento da confermare (proposta) o lo inserisce subito?
9. **Mappa sempre scura nel tema chiaro**: il template la vuole così (luci su notte). Confermare che non serve una
   versione chiara.
10. **Posizione del dispositivo e «Apri in Mappe»** (§5.5): niente `CoreLocation` e niente apertura del giro in Mappe
    (gli indirizzi uscirebbero verso Apple o Google): confermare, o dire per quali casi dare il via.
11. **«Prisma ovunque»**: `Cliente.luogo` (coordinate messe a mano, più precise del comune) sta nell'archivio, quindi nei
    backup e, se lo spazio è acceso, nell'`istantanea.cifrato` (cifrata, come il resto). Nessuna regola nuova, ma è un
    dato di posizione in più che viaggia cifrato: confermare che va bene o tenerlo fuori dall'istantanea.
12. **Fonte dell'anello arancio e del suggerimento**: il template mostra un consenso privacy da rinnovare come motivo per
    passare dal cliente; il criterio («qualcosa da fare») è di Prisma (§5.3) e va confermato, perché decide chi entra nel
    giro proposto.

---

### 5.2 La tua settimana, il tuo anno

*Voce Novità 6: «La tua settimana, il tuo anno · Trenta secondi ogni lunedì», glifo `storia` #1F5F99,
`apriStoria('settimana')` (riga 1779). Altri ingressi: pulsante «▶︎ La tua settimana» sulla scrivania (`#dSett`, riga 487 e
522) e «▶︎ Il tuo anno» nella testata di Studio (`#stAnno`, righe 883, 939, 2085, 2087). Codice: righe 1700-1727 e 1784;
CSS 240-255.*

#### 5.2.1 Cosa si vede

**1.1 La sovrapposizione.** Una storia a tutto palco (`#storia`, `position:absolute; inset:0; z-index:98`), sopra la
finestra, la barra e il dock, **testo bianco**, nello stile delle storie dei social: una pagina alla volta.
- **Fondo**: gradiente radiale 1200×800 centrato al 30%/20%, dal colore chiaro della pagina al suo colore scuro (coppie
  `bg` di ogni pagina). **Uguale in chiaro e in scuro** (le schermate `05-c-` e `05-s-` coincidono).
- **Barre di avanzamento** in alto: a 30 da sinistra e 80 da destra, 22 dall'alto, una per pagina, spazio 6, alte 4,
  raggio 9, binario bianco al 30%; le pagine viste sono piene, quella in corso si riempie in 5,2 s.
- **Chiudi** «✕»: tondo da 36, a 26 da destra e 12 dall'alto, fondo bianco al 18%, testo 15.
- **Contenuto** centrato (60 dall'alto e dal basso, 80 ai lati), in colonna.
- **Zone di tocco**: metà sinistra (pagina prima) e metà destra (pagina dopo), da 60 in giù.

**1.2 Caratteri delle pagine**: `.sT` titolo 58 pt display, 700, spaziatura −1,8, interlinea 1,05; `.sN` numero 110 pt,
700, spaziatura −4, cifre tabellari; `.sS` testo 22 pt, opacità 0,82, 10 sopra.

**1.3 «La tua settimana»** (`SLIDE.settimana`, righe 1703-1708), sei pagine:

| # | Fondo (chiaro → scuro) | Contenuto |
|---|---|---|
| 1 | #1F5F99 → #0F2433 | logo di Prisma bianco 64×64 (i tre spicchi al 100%, 66%, 38%); «**Buongiorno, Denis.**» (`.sT`, 30 sopra); «Ecco la tua settimana · 2 – 8 novembre» |
| 2 | #5B4BC8 → #26164F | «Questa settimana»; «**7 incontri**» (`.sN`, numero contato); fila di avatar da 74 sovrapposti di 16, bordo bianco 4 al 90%, che «saltano» uno dopo l'altro; «Il più importante: giovedì alle 16, la firma di Giulia.» |
| 3 | #1E9E6A → #0B3B2E | «In arrivo»; «**4.300 €**» (contato); cinque colonne bianche all'85% (lun-ven), larghe 54, alte valore/1500·160, raggio 10 10 4 4, che crescono dal basso; sotto ogni colonna il giorno (opacità .75); «Rinnovi Alleanza e due parcelle» |
| 4 | #C2363B → #4A1420 | «Da chiamare per primo»; avatar 120 di Marco (bordo bianco 5, iniziali 40); «**Marco Bianchi**» (`.sT`); «L’Infortuni famiglia scade il 17 dicembre ed Elena non è protetta.» (max 640) |
| 5 | #E08A00 → #3D2A07 | «Un traguardo da festeggiare»; anello bianco pieno 190/18 con «✓» 58; «**Sofia ha raggiunto la rendita.**»; pulsante bianco «**Festeggialo ›**» (testo #14202B, 15 pt, padding 12/22) → chiude la storia e apre Messaggi sul traguardo (§4 di questa parte) |
| 6 | #2A6FA0 → #0F2433 | «**Buona settimana.**»; «Prisma è pronta, tu anche.»; pulsante vetro «▶︎ Guarda anche «Il tuo anno»» (fondo bianco 18%, bordo bianco 30%) → passa alla storia dell'anno |

Sei pagine × 5,2 s = 31 s: i «trenta secondi» del sottotitolo.

**1.4 «Il tuo anno»** (`SLIDE.anno`, righe 1709-1716), sette pagine:

| # | Fondo | Contenuto |
|---|---|---|
| 1 | #5B4BC8 → #0F2433 | «Denis Vicenzoni»; «**2026**» (`.sN` a **150**); «Il tuo anno da consulente, in un minuto.» |
| 2 | #E5484D → #4A1420 | «Quest’anno hai protetto»; «**23 famiglie**» (contato); «con **4.800.000 €** di capitale, se succede qualcosa» |
| 3 | #0A84FF → #0B2A4A | «Segui»; «**1.124.350 €**» (contato); una linea bianca da 5 (560×120) che si disegna; «+18% in un anno» |
| 4 | #30B15C → #0B3B2E | «**12 clienti nuovi**»; 12 pallini da 34 (7 bianchi pieni, 5 al 35%) che saltano uno dopo l'altro (max 560, spazio 10); «7 sono arrivati dal passaparola» |
| 5 | #B06E12 → #3D2A07 | «Per andarli a trovare hai fatto»; «**8.400 km**»; «più o meno due volte andata e ritorno fino a Lisbona» |
| 6 | #8B5CF6 → #26164F | «Il momento dell’anno»; «**Il 14 marzo Marco ha messo al sicuro gli studi di Tommaso.**» (`.sT`, max 760, interlinea 1,2) |
| 7 | #1F5F99 → #0F2433 | logo; «**Grazie per il lavoro che fai.**» |

**1.5 Comportamento**: le pagine avanzano da sole ogni 5,2 s; sull'ultima la barra si riempie e la storia **resta** ferma
(non si chiude da sola: `avantiSlide`, riga 1726). Esc chiude; ← → sfogliano (riga 1784).

**1.6 Stati** (il template non ne ha): ogni pagina compare solo se ha i suoi dati (§5.3, §6). Se una settimana non ha
niente (nessun incontro, nessun incasso, nessuna cosa da fare, nessun traguardo) restano la prima e l'ultima, con «Una
settimana tranquilla: niente in agenda per ora.» Se l'anno è il primo in Prisma, la pagina del patrimonio dice «Da
quest'anno in Prisma» al posto della percentuale.

#### 5.2.2 Misure e stile

Token nuovi in **`DesignSystem/Apple/Tema.Apple+Storie.swift`** (`enum Tema.Apple.Storia`):

| Template | Valore | Token |
|---|---|---|
| fondo | radiale 1200×800 a 30%/20% | `fondo(chiaro:scuro:)` → `RadialGradient` con `centro = UnitPoint(x: 0.3, y: 0.2)`, `raggio = 1200` (proporzionale alla larghezza: 1200/1440) |
| coppie di colori | vedi tabelle (13 coppie; molte ripetute) | `Storia.Tinta` con casi nominati: `blu` (#1F5F99/#0F2433), `viola` (#5B4BC8/#26164F), `verde` (#1E9E6A/#0B3B2E), `rosso` (#C2363B/#4A1420), `ambra` (#E08A00/#3D2A07), `mare` (#2A6FA0/#0F2433), `notte` (#5B4BC8/#0F2433), `corallo` (#E5484D/#4A1420), `cielo` (#0A84FF/#0B2A4A), `prato` (#30B15C/#0B3B2E), `cuoio` (#B06E12/#3D2A07), `lavanda` (#8B5CF6/#26164F). Dove il colore chiaro esiste già si riusa (`Colore.anello2` #0A84FF, `Colore.rosso` #E5484D, `Colore.arancio` #E08A00, `anello1` #30B15C, `anello3` #8B5CF6, il cuoio #B06E12) |
| barre | 30/80 dai lati, 22 dall'alto, alte 4, raggio 9, spazio 6, binario bianco .3 | `Barre.margineSinistro = 30`, `margineDestro = 80`, `alto = 22`, `altezza = 4`, `raggio = Raggio.barra` (9), `spazio = 6`, `binario = Color.white.opacity(0.3)` |
| chiudi | 36, a 26/12, bianco .18 | `Chiudi.lato = 36`, `Chiudi.fondo` |
| contenuto | inset 60/80 | `Contenuto.margini = EdgeInsets(top: 60, leading: 80, bottom: 60, trailing: 80)` |
| `.sT` | 58, 700, −1,8, 1,05 | `Storia.titolo = Carattere(dimensione: 58, peso: .bold, tracking: -1.8, interlinea: 1.05)` |
| `.sN` | 110, 700, −4, tabellare | `Storia.numero`; variante `Storia.anno` a 150 |
| `.sS` | 22, opacità .82 | `Storia.testo`, `opacitaTesto = 0.82` |
| avatar | 74 sovrapposti −16, bordo 4 bianco .9; grande 120 bordo 5, iniziali 40 | `Storia.avatar = 74`, `sovrapposizione = 16`, `bordoAvatar = 4`, `avatarGrande = 120`, `bordoAvatarGrande = 5` |
| colonne | 54 di larghezza, max 160, raggio 10/4, bianco .85, spazio 22, contenitore 180 | `Colonne.larghezza = 54`, `altezzaMassima = 160`, `raggioAlto = 10`, `raggioBasso = 4`, `spazio = 22` |
| pallini | 34, spazio 10, bianco / bianco .35 | `Pallini.lato = 34`, `spazio = 10`, `spento = 0.35` |
| anello | 190 / 18, bianco pieno, «✓» 58 | `AnelliConcentrici` con un solo anello, `Storia.anello = 190`, `spessoreAnello = 18` |
| linea | 560×120, bianco 5 | `TracciatoGrafico` con `Storia.spessoreLinea = 5` |
| pulsanti | bianco pieno con testo #14202B, 15 pt, 12/22; vetro bianco .18 con bordo .3 | `Storia.pulsantePieno`, `Storia.pulsanteVetro` (#14202B non c'è nel tema: `Colore.testoToast` è bianco; costante nuova condivisa con il fondo del biglietto dei traguardi, `Tema.Apple.Colore.notteProfonda` proposta) |
| logo | 64×64 bianco, spicchi 1 / .66 / .38 | `LogoPrisma` (vettoriale) in bianco, opacità degli spicchi del logo per i fondi scuri |

Il testo è **sempre bianco** e i fondi sono fissi nei due temi: va bene (è una «sala» come la presentazione), ma il
contrasto del testo `.sS` (bianco all'82%) sui colori chiari (#E08A00, #30B15C, #0A84FF) va verificato (vedi §8).

#### 5.2.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Apertura | opacità 0 → 1 in 350 ms (riga 1717) | **nuovo** `Tema.Apple.Moto.Storia.apre = 0.35`, `Curva.ease` |
| Chiusura | opacità 1 → 0 in 300 ms (riga 1727) | `Storia.chiude = 0.30` |
| Barra in corso | larghezza 0 → 100% lineare in 5,2 s (con `ridotto` 2,5 s) | `Storia.durataPagina = 5.2`; con calmo **5,2 lo stesso** (proposta: il tempo serve per leggere, non è movimento) e barra a scatti di secondo o piena subito; la pagina dura comunque 5,2 s |
| Elementi `.sA` in cascata | da y +30, scala 0,96, sfocatura 10, opacità 0 → fermi in 850 ms, `uscita`, ritardo 120 + i·170 ms | `Storia.Entrata` (0,85 / 0,12 / 0,17, spostamento 30, scala 0,96, sfocatura 10) come nuovo `StileEntrata.storia` (lo schema c'è già: `Tema.Apple.Moto.StileEntrata`, `DesignSystem/Apple/Tema.Apple+Sequenze.swift:59`; un esempio di
variante è `StileEntrata.voceNovita` in `Tema.Apple+Novita.swift:94`) |
| Numeri | `conteggi` (1100 + i·60 ms) | `NumeroCheConta` |
| Salto (`.sP`) | scala 0 → 1 in 600 ms, `(.34,1.6,.64,1)`; avatar con ritardo 0,5 + i·0,15 s; pallini 0,5 + i·0,08 s | `Storia.salto = 0.6`, curva `Tema.Apple.Studio.Moto.curvaPunti` |
| Colonne (`.sB`) | scaleY 0 → 1 dal basso in 800 ms, `(.34,1.3,.64,1)`, ritardo 0,6 + i·0,12 s | come `Moto.Colonne` del Cruscotto (`Tema.Apple.Studio.Moto.curvaColonne`), ritardo proprio `Storia.ritardoColonne = 0.6`, `passoColonne = 0.12` |
| Anello | `accendi(…, 500)`: 1,4 s dopo 0,5 s | `Moto.Anello` con ritardo 0,5 |
| Linea | `linee`: 1,5 s dopo 0,15 s | `Moto.Linea` |

**Riduci movimento**: niente cascata, salti, colonne che crescono né sfocatura: ogni pagina compare ferma con la
dissolvenza di 0,15 s; i numeri sono già completi. Il passaggio automatico resta (il template lo accorcia a 2,5 s: troppo
poco per leggere; proposta 5,2 s anche qui, o niente passaggio automatico con calmo: decisione 4).
**Istantanee**: la pagina scelta ferma nello stato finale; barre: le precedenti piene, quella corrente piena a metà
(scelta fissa per l'istantanea), nessun passaggio automatico.

Nessun Timer: il passaggio automatico si fa con un `Task` che dorme 5,2 s (cancellato a ogni cambio di pagina, alla
chiusura, al blocco) o con `TimelineView(.periodic(from:by:))`; la barra con un'animazione lineare di 5,2 s.

#### 5.2.4 Interazioni

- **Aprire**: voce Novità 6 (settimana), pulsante «▶︎ La tua settimana» della scrivania, «▶︎ Il tuo anno» in Studio
  (in tutte le schede di Studio, anche Spese: riga 2087), pulsante dell'ultima pagina della settimana.
- **Sfogliare**: clic sulla metà destra = avanti; sulla sinistra = indietro (non sulla prima); ← → da tastiera; Esc o «✕»
  chiudono (riga 1784). Su macOS 13 i tasti si prendono come nella presentazione dei prospetti
  (`.keyboardShortcut(.leftArrow, modifiers: [])`, `Shell/Presentazione.swift:291`) o con il monitor dei tasti di
  `Shell/AppRicerca.swift:213`; **non** con `onKeyPress`, che c'è solo da macOS 14 / iOS 17 (in Prisma è usato solo sotto
  `#if os(iOS)`). **Proposta in più**: tenere premuto (clic lungo o barra spaziatrice) mette in pausa, come nelle
  storie; il puntatore non mette in pausa.
- **Pulsanti dentro le pagine**: «Festeggialo ›» → chiude e apre Messaggi sul traguardo di quel cliente (nell'app con il
  cliente e il traguardo giusti, non `selM=0`); «▶︎ Guarda anche «Il tuo anno»» → storia dell'anno da pagina 1. Proposta:
  anche le altre pagine portano dove nasce la cifra con un pulsante discreto «Apri ›» (incontri → Agenda della settimana;
  in arrivo → Studio › Cruscotto; da chiamare → dossier; famiglie protette → Posizioni filtrate).
- **Un pannello alla volta** (parte comune §4.5): aprire la storia chiude Novità, notifiche, spazi, ricerca, guida; il
  blocco e il riposo del Mac la chiudono.
- **«Ogni lunedì»** (sottotitolo della voce): il template non la apre da sola. Proposta: il primo sblocco del lunedì
  propone la storia (il pulsante della scrivania pulsa una volta o compare un invito «La tua settimana è pronta»), senza
  aprirla da sola; e a dicembre, dal 15, «Il tuo anno» è proposto allo stesso modo. Opzionale: un promemoria locale del
  Mac il lunedì alle 8:30 (`PromemoriaMac.swift` usa già le notifiche locali): **solo sul Mac, niente esce**.
- **Modalità cliente**: le storie sono del consulente (provvigioni, km, clienti): non si aprono in modalità cliente (come
  Studio, `TestiStudio.testoRiservato`).
- **iPhone/iPad**: il template non le mostra. Le storie verticali sono naturali sull'iPhone: proposta di un secondo giro
  con la stessa vista a tutto schermo (i dati arrivano dall'istantanea di «Prisma ovunque» se accesa).

#### 5.2.5 Mappa verso Prisma

**5.1 Esiste già**
- Sovrapposizioni: oggi `StatoFinestre` (`Shell/StatoFinestre.swift`) ha solo i pannelli (notifiche, spazi, ricerca,
  guida, Novità); `enum SovrapposizioneLuce { storia(TipoStoria), … }` **non esiste ancora**: è proposto dalla parte comune
  (§4) e va creato lì, chiuso da `blocca(animato:)` (`Shell/StatoShellFinestre.swift:455`) e da
  `bloccaPerRiposo()` (`Shell/RipresaSistema.swift:51`).
- Pulsanti della scrivania: `Shell/ScrivaniaApple.swift`; Studio e la sua testata: `Shell/StudioApp.swift` (segmentato con
  `SchedaStudio`, `StatoShell.schedaStudio`, `StatoShell.swift:96`).
- Fonti delle cifre:
  - incontri della settimana: `Appuntamento` nella settimana, con un cliente (`Appuntamento.Stato` ha solo
    `pianificato` e `concluso`: non esiste un appuntamento «annullato», quindi si contano tutti; telefonate escluse o no:
    da decidere con la decisione 2); «il più importante»: `tipo
    == .firma`, poi `.proposta`, poi il primo;
  - in arrivo: `MotoreStudio` (`Motori/MotoreStudio.swift`, incassi previsti per mese: `CruscottoStudio.MeseIncasso`) e le
    parcelle (`MotoreParcelle`, `Dati/Parcella.swift`): servono **per giorno** (§5.2);
  - da chiamare: la prima voce di `MotoreDaFare` (o la «mossa del giorno», `Motori/MotoreMossaDelGiorno.swift`);
  - traguardo: il motore dei traguardi di questa parte (§4.5);
  - anno: «famiglie protette» e capitale da `MotoreProtezioneFamiglia` e dalle posizioni di protezione accettate
    nell'anno (`Posizione.esito == .accettata`, `SeguitoProposta.esitoIl`); patrimonio seguito e variazione da
    `MotoreAndamentoPortafoglio` (lo stesso di «Un anno insieme», `Motori/MotoreAnnoInsieme.swift`); clienti nuovi da
    `Cliente.creatoIl` (o dall'anno d'inizio di §1.5.3); passaparola: campo della parte «Potenziali clienti e
    passaparola» (oggi non c'è: grep `passaparola`/`presentatoDa` vuoto); km: Territorio/Studio › Spese (§1.5.3);
    il momento dell'anno: il traguardo più importante dell'anno (§4.5).
- Numeri, anelli, linee, colonne: componenti del tema (vedi testa della parte); logo: `LogoPrisma`.

**5.2 Da creare**
- **`Motori/MotoreStorie.swift`** (puro, con `oggi`):

```swift
enum TipoStoria { case settimana, anno }
enum PaginaStoria: Equatable {
    case saluto(nome: String, periodo: DateInterval)
    case incontri(numero: Int, clienti: [String], principale: String?)            // max 6 avatar
    case inArrivo(totale: Double, perGiorno: [(giorno: Date, importo: Double)], didascalia: String)
    case daChiamare(clienteId: String, motivo: String)
    case traguardo(clienteId: String, titolo: String, traguardoId: String)
    case finaleSettimana
    case annoTitolo(anno: Int, consulente: String)
    case protette(famiglie: Int, capitale: Double)
    case patrimonio(valore: Double, serie: [Double], variazione: Double?)
    case nuoviClienti(numero: Int, daPassaparola: Int?)
    case chilometri(km: Double, paragone: String?, stima: Bool)
    case momento(data: Date, frase: String, clienteId: String)
    case grazie
}
enum MotoreStorie {
    static func settimana(dati: DatiPrisma, oggi: Date, cal: Calendar) -> [PaginaStoria]
    static func anno(dati: DatiPrisma, anno: Int, oggi: Date, cal: Calendar) -> [PaginaStoria]
}
```

  Regole: una pagina c'è solo se il suo dato c'è e non è zero (niente «0 incontri»); prima e ultima sempre. «Settimana» =
  da lunedì a domenica della settimana di `oggi` (il template: «2 – 8 novembre», lunedì 2). «In arrivo» = provvigioni
  ricorrenti previste e parcelle con scadenza di pagamento in quei giorni, per giorno lavorativo; la didascalia la compone
  Prisma da ciò che c'è («Rinnovi Alleanza e due parcelle»). «Il tuo anno» = 1° gennaio → oggi.
- **Paragone dei km** («due volte andata e ritorno fino a Lisbona»): una tabella fissa di distanze fra città in
  `Motori/TestiStorie.swift` (le distanze vanno prese da una fonte e approvate dall'utente: nessuna cifra scritta qui, **non inventarle**); se
  il paragone non è sicuro, niente paragone. Proposta più semplice: «come andare da … a … N volte» solo da una tabella che
  l'utente approva, altrimenti «in media N km a settimana».
- **Frase del momento dell'anno**: composta da Prisma con un modello fisso («Il {giorno} {nome} ha {fatto}.» dal tipo del
  traguardo); Ruby (Qwen) può renderla più naturale con le regole di `messaggi.md`/`commento.md` (se compare una cifra non
  presente nella scheda, si tiene la frase di Prisma, come `CommentoRuby`). Se Qwen non è pronto: la frase di Prisma.
- **Viste**: `Shell/StoriaLuce.swift` (sovrapposizione, barre, zone di tocco, chiusura, tastiera) e
  `Shell/PagineStoria.swift` (una vista per caso di `PaginaStoria`). Componenti: `NumeroCheConta`, `AnelliConcentrici`,
  `TracciatoGrafico`, `AvatarCliente` (`DesignSystem/Componenti.swift:698`), `LogoPrisma`.
- **Ingressi**: pulsanti nella scrivania e in Studio (`StudioApp.swift`, azioni della testata), voce `NovitaLuce.settimanaAnno`.
- **Prova**: `Motori/ProvaCalcoliStorie.swift`: pagine assenti con dati vuoti; settimana lun-dom anche a cavallo di mese e
  d'anno; «il più importante» = la firma; in arrivo per giorno = somma uguale al totale; famiglie protette contate una
  volta per nucleo; variazione nil al primo anno; clienti nuovi dell'anno; frase del momento senza cifre inventate.

**5.3 Campi nuovi dell'archivio**: `Impostazioni.storie: ImpostazioniStorie? = { propostaLunedi: Bool = true;
promemoriaLunedi: Bool = false; ultimaSettimanaVista: Date?; ultimoAnnoVisto: Int? }` (per non riproporla più di una
volta).

#### 5.2.6 Dati che l'utente deve dare (mai inventarli) e stati vuoti

1. Il **nome del consulente** per «Buongiorno, Denis» (`DatiFatturazione.nome`, o un nome in Impostazioni: senza,
   «Buongiorno.»).
2. Le **aliquote provvigionali** (Studio, specifica Orizzonte §2.6) per «In arrivo»: senza, la pagina conta solo le
   parcelle e lo dice («solo parcelle: mancano le aliquote»), o sparisce se zero.
3. Il **passaparola** (chi ha presentato chi): senza, la riga «7 sono arrivati dal passaparola» non c'è.
4. I **chilometri**: dal Territorio (stima) o dalle spese; senza, niente pagina.
5. Lo **storico dei valori** per «Segui … +18%»: senza l'anno prima, niente percentuale.
6. Il **paragone dei km**: da una tabella approvata (decisione 3).
Stati vuoti: §1.6. Dati di prova: la settimana e l'anno di prova escono dai dati di prova; etichetta «dati di prova» in
piccolo sulla prima pagina.

#### 5.2.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `710-storia-settimana-saluto` | pagina 1 della settimana (stato finale) |
| `711-storia-settimana-incontri` | pagina 2 con gli avatar |
| `712-storia-settimana-in-arrivo` | pagina 3 con le colonne |
| `713-storia-settimana-traguardo` | pagina 5 con l'anello e «Festeggialo ›» |
| `714-storia-settimana-vuota` | settimana senza dati: saluto e «Una settimana tranquilla» |
| `715-storia-anno-titolo` | pagina 1 dell'anno («2026» a 150) |
| `716-storia-anno-patrimonio` | pagina 3 con la linea tracciata |
| `717-storia-anno-nuovi-clienti` | pagina 4 con i pallini |
| `718-storia-anno-primo-anno` | pagina del patrimonio senza percentuale |
| `719-scrivania-invito-settimana` / `-scuro` | la scrivania di lunedì con l'invito «La tua settimana è pronta» |

Le storie sono uguali in chiaro e in scuro: niente `-scuro` tranne la 719.

#### 5.2.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole: tema Apple (fondi colorati fissi e testo bianco: una «sala» come la presentazione dei prospetti), valori in
`DesignSystem`, movimento con calmo e istantanee, niente Timer, blocco e riposo chiudono la storia. Nessuna uscita dal
Mac: le storie non si condividono (il template non lo prevede). Il promemoria del lunedì è una notifica **locale**.

**Decisioni:**
1. **Ogni lunedì**: proporla al primo sblocco del lunedì (invito sulla scrivania), aprirla da sola, o solo dal pulsante?
   Notifica locale del Mac il lunedì mattina: sì o no? Se sì, con un testo **generico** («La tua settimana è pronta»),
   senza nomi di clienti né cifre, perché le notifiche si vedono anche sullo schermo bloccato e nel Centro notifiche.
2. **Cosa entra nella settimana**: le sei pagine del template, o anche altre (scadenze di conformità, proposte in attesa)?
   Ordine e massimo (proposta: al massimo 7 pagine, sempre sotto un minuto).
3. **Paragone dei km** («fino a Lisbona»): tabella di paragoni da approvare, o niente paragone.
4. **Riduci movimento**: il passaggio automatico resta a 5,2 s (proposta) o si toglie?
5. **Contrasto**: testo bianco all'82% su #E08A00, #30B15C, #0A84FF può non bastare per la leggibilità: proposta di
   scurire il centro del gradiente del 10% o di portare `.sS` al 90%.
6. **«Il momento dell'anno»**: frase fissa di Prisma o riscritta da Ruby (con il controllo delle cifre)?
7. **Condivisione**: il template non la prevede; confermare che le storie restano solo del consulente (contengono dati
   dei clienti e delle provvigioni).

---

### 5.3 La palestra della trattativa

*Voce Novità 7: «La palestra della trattativa · Ruby fa il cliente difficile», glifo `palestra` #3F5A78,
`vaiA('studio',()=>{tabS='palestra'})` (riga 1779). Nuova scheda **Palestra** di Studio (segmentato, righe 883 e 2085).
Codice: righe 1729-1757; CSS `.pB`, `.pFb` 256-258, `.opz` 216-219, `.typing` 182-183.*

#### 5.3.1 Cosa si vede

**1.1 Dove sta.** Studio, testata «Il tuo studio. · IL TUO LAVORO, COME UN PORTAFOGLIO», a destra il pulsante «▶︎ Il tuo
anno» e il segmentato **Cruscotto · Parcelle · Track record · OCF · Palestra · Spese** (con Luce i titoli «Parcelle e
fatture» ed «Esame OCF» si accorciano: riga 2085; la parte comune lo descrive). Scheda **Palestra**.

**1.2 Colonna sinistra** (card `.st`, larga 380, alta tutta l'area, padding 22/24; riga 1738-1743):
- `.lbl` **«LA PALESTRA DELLA TRATTATIVA»**;
- 14 sotto: avatar 56 della cliente, **«Giulia Rossi»** (17 pt grassetto) e `.k` **«Ruby nei panni di Giulia»**;
- tile (16 sopra, 13,5 pt, interlinea 1,55): **«Chi è:** 37 anni, architetta, prudente. Decide insieme a Luca.»
  **«I suoi timori:** i soldi bloccati, il rischio dei mercati.» **«L’obiettivo:** la casa tra tre anni.»;
- `.lbl` **«DIFFICOLTÀ»** (16 sopra, 8 sotto) e il segmentato **Facile · Realistica · Difficile** (scelta: Realistica);
- `.k` **«Obiezione 1 di 3»** (16 sopra) e la barra `.bar8` (alta 8) d'avanzamento in `--accent`, che cresce di un terzo a
  ogni obiezione superata;
- in fondo (24 dai lati, 20 dal fondo, `.k`, interlinea 1,45): **«Ruby recita il cliente con il suo profilo vero. Le
  risposte suggerite sono esempi: puoi anche scrivere le tue.»**

**1.3 Colonna destra** (card a 396 da sinistra fino al bordo; padding 20/26; riga 1744):
- la **conversazione** (`#paChat`: 26 dai lati, da 18 in alto fino a 236 dal fondo, scorre, scorrimento morbido);
- in basso (`#paOpz`, 18 dal fondo) le **risposte**: `.lbl` «RISPONDI», tre opzioni `.opz` (padding 10/14, 14 pt, raggio
  16, bordo `--sep`, fondo `--cardE`, 8 fra l'una e l'altra) con la lettera **A/B/C** in un tondo da 26 (`--chip`), e sotto
  il campo **«Oppure rispondi a parole tue…»** in una pillola `--chip` con il pulsante primario «↑».

**1.4 Le bolle** (riga 1745, CSS 256-258):
- **cliente** (a sinistra): avatar 34, sopra la bolla la riga 11,5 pt `.k` **«Giulia · recitata da Ruby»**; bolla `--chip`,
  padding 11/15, raggio 18 18 18 6, 15 pt, interlinea 1,5; larghezza massima 720;
- **consulente** (a destra): bolla `--accent` con testo bianco, raggio 18 18 6 18; sotto, a destra, il **giudizio**
  (`.pFb`, 12,5 pt grassetto, 5 sopra):
  - **«✓ Ottima: hai usato Prisma per farglielo vedere»** in `--green` (punteggio 3);
  - **«○ Buona: chiara e corretta»** in `--accent` (2);
  - **«△ Debole: generica o di pressione»** in `--red` (0);
- **Ruby scrive**: bolla della cliente con i tre puntini (`.typing`, pallini da 7 `--ink3` che saltano) per 1,1 s.

**1.5 Il giro di un allenamento** (righe 1747-1752): tre obiezioni (`OBJ`, righe 1730-1735):
1. «Mi piace l’idea, ma se tra due anni mi servono i soldi per la casa? Restano bloccati?» — A «Il piano prevede riscatti
   parziali dopo il primo anno, e per la casa teniamo un conto a parte.» (2), B «Non si preoccupi, è un ottimo
   prodotto.» (0), C «Guardiamo insieme la linea della vita: anche ritirando 15.000 € nel 2028, la casa arriva lo
   stesso.» (3);
2. «La banca mi propone un conto al 3% senza rischi. Perché dovrei fare altro?» — A sul netto (2,2%) e l'inflazione (2),
   B «Le banche pensano solo a loro.» (0), C «Va benissimo per una parte…» (3);
3. «Ci devo pensare. Ne parlo con Luca stasera.» — A «Le preparo il film del piano da guardare insieme a Luca stasera.»
   (3), B «La proposta vale solo fino a venerdì.» (0), C «Fissiamo già il prossimo incontro con tutti e due?» (2).
Ogni risposta: la bolla del consulente, il giudizio, Ruby scrive, la replica della cliente (una per opzione), poi
l'obiezione dopo. **Difetti del template**: la replica è presa con `ob.re[[1,0,2][i]]` (riga 1749), così A riceve la replica
pensata per B e viceversa (nello scatto `05-s-pal-fine.png` alla risposta «Ottima» del film la cliente dice «Così mi mette
fretta, però…»); la risposta scritta a mano vale sempre 2 e riceve sempre la prima replica (riga 1750); il segmentato
della difficoltà non fa niente (`SEGH.paD=()=>{}`, riga 1757).

**1.6 La fine** (`paFine`, riga 1753-1756): nella conversazione una tile (fondo `--cardE`) con:
- un anello 120/12 con il **punteggio** al centro (display 28, 700): somma dei punti / 9 · 100, arrotondata; colore
  #30B15C da 70 in su, #0A84FF da 45, altrimenti #E08A00;
- titolo 17 grassetto: da 70 **«Giulia ha detto: «Ne parlo con Luca, ma mi convince».»**, sotto **«Giulia resta
  incerta.»**;
- `.k`: «**Cosa ha funzionato:** N risposte che le hanno fatto vedere i numeri.» e «**Cosa potevi usare:** la linea della
  vita, «Lancia l’anno», il film del piano.»;
- tre pulsanti: «Linea della vita» (`vaiA('clienti',…tabCli='vita')` → dossier, in Prisma `SchedaCliente.lineaVita`,
  `Shell/StatoShell.swift:3178`), «Lancia l’anno» (`apriEsp('dadi',0)`: nel template la chiave è `dadi`, in Prisma il caso
  proposto dalla parte comune è `EsperienzaSala.lanciaAnno`), «Il film del piano» (`apriEsp('film',0)`, `EsperienzaSala.film`);
  tutti e tre aprono sempre il cliente 0 del template, non quello dell'allenamento;
- al posto delle risposte, il pulsante primario grande **«↻ Rifai l’allenamento»** (ricomincia da capo, conversazione
  vuota).

**1.7 Stati** (il template non ne ha):
- **Qwen non pronto**: la colonna destra mostra lo stato di Ruby non pronta (come `494-messaggi-ruby-non-pronta`): «Ruby non
  è pronta: la palestra ha bisogno di Qwen sul Mac.» con il collegamento a Impostazioni › Ruby. Nessuna obiezione finta.
- **Nessun cliente**: «Scegli un cliente per allenarti» (oppure un cliente di prova: decisione 2).
- **Profilo scarno** (senza obiettivi, timori, età): Ruby lo dice nella tile («Di Giulia Prisma sa poco: l'allenamento sarà
  generico») e la palestra resta usabile.
- **Ruby sta pensando** più di 20 s: «Ruby ci sta mettendo un po'…» con «Annulla».

#### 5.3.2 Misure e stile

Token in **`DesignSystem/Apple/Tema.Apple+Palestra.swift`** (`enum Tema.Apple.Palestra`) o dentro `Tema.Apple.Studio`:

| Template | Valore | Token |
|---|---|---|
| colonna sinistra | 380, padding 22/24 | `Colonna.larghezza = 380` (= `Tema.Apple.Messaggi.Disposizione.larghezzaColonna`, riusare il valore), `Misura.padding(22, 24)` |
| spazio fra colonne | 16 (396 − 380) | `Disposizione.gioco = 16` (esiste in Messaggi) |
| avatar del profilo | 56 | `Misura.Avatar.dossier` (56) |
| nome | 17 grassetto | `Carattere.titoloFinestra` (17, bold) |
| tile del profilo | 13,5, interlinea 1,55 | `Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.55)` nuovo `Palestra.profilo` |
| barra | `.bar8` alta 8, `--accent` | `BarraPiena` con altezza 8 (`GraficiApple.swift:28`), `Colore.accento` |
| bolla cliente | `--chip`, 11/15, raggio 18/18/18/6, 15 pt, 1,5 | `Bolla.fondoCliente = Colore.chip`, `Bolla.padding = Misura.padding(11, 15)`, `Bolla.raggio = 18`, `raggioPunta = 6`, `Bolla.testo = Carattere(dimensione: 15, peso: .regular, interlinea: 1.5)` (le bolle di Ruby in `AppRuby.swift` hanno misure proprie: confrontarle e unificare se possibile) |
| bolla consulente | `--accent`, testo bianco, raggio 18/18/6/18 | `Bolla.fondoConsulente = Colore.accento` |
| riga «recitata da Ruby» | 11,5 `.k` | `Carattere(dimensione: 11.5)`, `Colore.inchiostro2` |
| avatar nella conversazione | 34 | `Misura.Avatar.voce` (34) |
| larghezza massima bolla | 720 | `Bolla.larghezzaMassima = 720` |
| giudizio | 12,5 grassetto; verde / accento / rosso | `Palestra.giudizio = Carattere(dimensione: 12.5, peso: .bold)`; `Colore.verde`, `Colore.accento`, `Colore.rosso` |
| opzione | `.opz` padding 10/14, raggio 16, 14 pt; tondo 26 | `Opzione.padding = Misura.padding(10, 14)`, `Opzione.raggio = 16`, `Opzione.lettera = 26`; (le opzioni esistono nell'Esame OCF: `Tema.Apple.OCF.Opzione`, `Tema.Apple+OCF.swift:147`, riusare le stesse misure dove coincidono) |
| campo libero | pillola `--chip`, padding 4/4/4/16, 14 pt | `Campo.padding`, `Raggio.pillola` |
| puntini | 7, `--ink3` | `PuntiniScrittura` (`RubyApple.swift:124`) |
| anello finale | 120/12; soglie 70 / 45; #30B15C / #0A84FF / #E08A00 | `AnelliConcentrici`, `Palestra.anelloFinale = 120`, `spessoreFinale = 12`, `sogliaBuona = 70`, `sogliaMedia = 45`; `Colore.anello1`, `anello2`, `arancio` |
| punteggio | display 28, 700 | `Palestra.punteggio = Carattere(dimensione: 28, peso: .bold, tabellare: true)` |

Nel tema scuro (`05-s-pal-fine.png`) le card e le tile sono quelle del tema; le bolle del consulente restano blu.

#### 5.3.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Entrata delle card | cascata `.st` | `Moto.Cascata` (rimonta di Studio) |
| Prima obiezione | dopo 350 ms (riga 1757) | `Palestra.attesaInizio = 0.35` |
| Ruby scrive | puntini per 1,1 s (`ridotto` 0,05) | nell'app i puntini durano **quanto Qwen** (con lo streaming si vede la risposta che si scrive con `TestoProgressivo`); niente attesa finta |
| Bolla che entra | da y +14, scala 0,97, opacità 0, 420 ms, `molla` (.34,1.45,.64,1) | **nuovo** `Tema.Apple.Moto.Bolla` (0,42, spostamento 14, scala 0,97, `Curva.molla`) |
| Opzioni | da y +10, 380 ms, `uscita`, ritardo i·70 ms | `Palestra.Opzione` (0,38 / passo 0,07) come `StileEntrata` |
| Giudizio | scala 0,8 → 1, 400 ms, ritardo 300 ms, curva `punti` (.34,1.6,.64,1) | `Palestra.giudizio = 0.4`, `ritardoGiudizio = 0.3`, curva `curvaPunti` |
| Barra d'avanzamento | larghezza in 0,6 s `uscita` | `Moto.Barra` con durata 0,6 (nuovo `Palestra.avanzamento = 0.6`) |
| Replica | 700 ms dopo la risposta comincia a scrivere; 900 ms dopo la replica, l'obiezione dopo | con Qwen la replica parte subito; tra replica e obiezione dopo una pausa `Palestra.pausaTurno = 0.9` |
| Tile finale | da y +16, 500 ms, `uscita`; anello 1,4 s dopo 100 ms | `Moto.Cascata` + `Moto.Anello` |
| Scorrimento | `scroll-behavior:smooth` all'ultima bolla | `ScrollViewReader.scrollTo(_, anchor: .bottom)` con animazione `Curva.uscita` |

**Riduci movimento**: bolle, opzioni e giudizio compaiono fermi con la dissolvenza di 0,15 s; testo di Ruby già intero
(niente scrittura progressiva); anello pieno. **Istantanee**: conversazione costruita con frasi di prova scritte nel codice
dell'istantanea (non da Qwen), stato finale.

#### 5.3.4 Interazioni

- **Scegliere il cliente** (il template usa sempre Giulia): proposta di un selettore accanto al nome («Allenati con…»),
  che parte dal cliente attivo della shell. Proposta di poter usare anche un **cliente di prova** o un **profilo
  inventato** (solo età, lavoro, timori): decisione 2.
- **Difficoltà**: Facile / Realistica / Difficile cambia il comportamento di Ruby (quanto è convinta all'inizio, quante
  volte torna sulla stessa obiezione, quanto spesso cede a una buona risposta): parametro nelle istruzioni (§5.3). Si
  sceglie prima di cominciare; durante l'allenamento è bloccata (o ricomincia: con una conferma).
- **Rispondere**: clic su A/B/C (o tasti 1/2/3, A/B/C, con `.keyboardShortcut` che c'è da macOS 11; non `onKeyPress`,
  da macOS 14), oppure scrivere e Invio. Mentre Ruby scrive, le risposte sono
  disattivate.
- **Numero delle obiezioni**: 3 come nel template (proposta), poi la fine.
- **Fine**: «Rifai l’allenamento»; i tre pulsanti «Cosa potevi usare» portano agli strumenti veri di Prisma **per quel
  cliente** (`StatoShell.apri` con il contesto; `apriEsperienza(_:cliente:)` della parte comune per «Lancia l'anno» e «Il
  film del piano»; dossier › Linea della vita).
- **Esc**: interrompe Ruby se scrive; altrimenti niente (l'allenamento resta).
- **Modalità cliente**: la Palestra **non** si mostra davanti al cliente (recita il cliente stesso!): Studio è già
  riservato (`TestiStudio.testoRiservato`).
- **iPhone/iPad**: il template non la prevede (sull'iPhone Ruby passa per il ponte con il Mac: possibile in un secondo
  giro).

#### 5.3.5 Mappa verso Prisma

**5.1 Esiste già**
- Studio: `SchedaStudio` (`Shell/StudioApp.swift:17`, casi `cruscotto, fatture, track, ocf`), `StatoShell.schedaStudio`,
  `apriStudio(_:)` (`StudioApp.swift:112`); l'Esame OCF ha già domande a scelta con opzioni (`Shell/StudioEsameOCF.swift`,
  `Tema.Apple+OCF.swift`).
- Ruby: `ModalitaRuby { lavoro, conversazione }` e `NucleoRuby` (`Ruby/NucleoRuby.swift:11`, finestra 8.192 token),
  `FornitoreModello` con `OpzioniModello.formato` per lo schema JSON (`Ruby/FornitoreModello.swift:31-43`), `ContestoRuby`
  (la scheda compatta del cliente), `FlussoRuby` (streaming), `AvvioModello` (Qwen pronto o no), `CommentoRuby` (controllo
  delle cifre), `PuntiniScrittura`, `TestoProgressivo`, `SferaRuby` (`DesignSystem/Apple/RubyApple.swift`).
- Istruzioni in `Ruby/Istruzioni/*.md`, schemi in `Ruby/Schemi/*.json`, esempi in `Ruby/Esempi/*.json` (copiati nel
  pacchetto dal workflow).
- Dati del profilo: `Cliente` (età da `dataNascita`, `professione`, `statoCivile`, `famiglia`, `profilo:
  ProfiloInvestitore`, `bisogni: ProfiloBisogni`), `Obiettivo` (`Dati/Prodotti.swift:172`), posizioni e proposte,
  note degli incontri (`Incontro`), memoria (`MotoreMemoria`).
- Le cifre per le buone risposte: `MotoreLineaVita` (ritiro e casa), `MotoreProvaFuoco`, `MotoreFiscale`/`FiscoPolizze`
  (netto di un rendimento), `MotoreRiscatto` (riscatti), condizioni dei prodotti (`Prodotto.condizioni:
  CondizioniContratto?`, `Dati/Prodotti.swift:25`; `ModuloCondizioni` è solo la vista che le modifica, in
  `Shell/AppProdotti.swift`).

**5.2 Da creare**
- `SchedaStudio.palestra` (e `.spese` dall'altra parte), titolo «Palestra»; vista **`Shell/StudioPalestra.swift`**.
- **Stato**: `Shell/StatoPalestra.swift` (`@MainActor final class StatoPalestra: ObservableObject`, fuori da `StatoShell`
  per non ridisegnare la shell a ogni parola): cliente, difficoltà, turni, punteggi, fase (`attesa`, `rubyScrive`,
  `tuoTurno`, `fine`), task di Qwen cancellabile.
- **Motore Ruby**: `Ruby/PalestraRuby.swift`:
  - **non** un terzo caso di `ModalitaRuby` (che è salvato nei messaggi di Ruby: `MessaggioRuby` lo registra, e la scelta
    automatica di `NucleoRuby.scegli` non deve mai finire in palestra), ma un **ruolo** a parte che usa lo stesso fornitore
    e lo stesso budget: `enum RuoloRuby { assistente, clienteSimulato }` o semplicemente un percorso dedicato in
    `PalestraRuby` (proposta);
  - **una sola chiamata per turno** a Qwen con lo schema `Ruby/Schemi/palestra.json`:
    `{ "replica": string, "convinta": 0-100, "prossimaObiezione": string|null, "giudizio": "ottima"|"buona"|"debole",
    "motivo": string, "strumento": "lineaVita"|"lanciaAnno"|"film"|"provaFuoco"|null }` — la replica della cliente al
    turno del consulente, il giudizio sulla risposta e la prossima obiezione;
  - **le tre risposte suggerite** A/B/C: una seconda chiamata (o nella stessa, campo `suggerite: [string]` di 3) con le
    cifre **solo dalla scheda** che Prisma prepara (come `chat.md`); se una suggerita contiene una cifra che non è nella
    scheda, si scarta (`CommentoRuby.numeriConservati`);
  - **giudizio**: misto, per non lasciare tutto a un modello da 4B: regole di Prisma prima (pressione: «vale solo fino a»,
    «ultimi giorni», promesse di rendimento, «garantito»; genericità: niente riferimento all'obiettivo né a un numero → al
    massimo «debole»/«buona»), poi Qwen; il giudizio finale è il più prudente dei due. Il motivo si mostra al passaggio del
    puntatore sul giudizio;
  - **punteggio**: come il template (3/2/0, somma / (3·N) · 100) ma con la **convinzione** della cliente (`convinta`) che
    decide la frase finale; il punteggio è dichiarato «indicativo».
- **Istruzioni**: `Ruby/Istruzioni/palestra.md` (nuovo; aggiornare `Ruby/Istruzioni/README.md`): Ruby recita il cliente
  in prima persona, con la scheda che Prisma prepara (età, lavoro, famiglia, obiettivi, timori dal profilo di rischio, le
  proposte in corso), in italiano parlato, frasi brevi; non inventa cifre del cliente né del prodotto; non dà consigli; non
  esce dal ruolo se non quando il consulente scrive «/stop» o chiude; regole per la difficoltà; regole per il giudizio
  (chiarezza, ascolto del timore, uso di cifre e strumenti di Prisma, assenza di pressione, coerenza con l'adeguatezza).
  Esempi in `Ruby/Esempi/palestra.json` (obiezioni tipiche: soldi bloccati, il conto della banca, «ci devo pensare», costi,
  «ho già la banca», «i mercati scendono»), **scritti o approvati dall'utente**.
- **Scheda per la recita**: `ContestoRuby` ha già la scheda compatta del cliente; serve una variante `schedaRecita` con i
  timori in parole (dal profilo di rischio e dalle note) e **senza** dati che il cliente non saprebbe (provvigioni,
  giudizi interni del consulente). Budget: istruzioni + scheda + 3 turni stanno negli 8.192 token.
- **Prova**: `Ruby/ProvaPalestraRuby.swift` (come `ProvaMessaggiRuby`): con un fornitore finto, lo schema si legge, una
  suggerita con una cifra inventata si scarta, una risposta di pressione è sempre «debole» qualunque cosa dica Qwen, il
  punteggio è 0-100, Qwen non pronto → nessun turno; e una valutazione manuale in `Ruby/Valutazione/` (cartella che c'è,
  vuota) con 10 casi.

**5.3 Difficoltà** (proposta per `palestra.md`): Facile = convinzione iniziale 60, cede a una risposta buona; Realistica =
40, serve una risposta ottima o due buone; Difficile = 20, torna sulle obiezioni, chiede numeri, può chiudere con un «no».
Temperatura di Qwen 0,5 (più alta della lavoro 0,3) per varietà, sempre senza ragionamento lungo (`pensa = false`) per la
velocità sul Mac da 8 GB.

**5.4 Archivio**: proposta di **non salvare** le conversazioni della palestra nel dossier (sono prove, non fatti del
cliente). Si salva solo un registro leggero per vedere i progressi: `Impostazioni.palestra: ImpostazioniPalestra? =
{ allenamenti: [EsitoPalestra] }` con `EsitoPalestra { data; clienteId?; difficolta; punteggio }` (al massimo 50, i più
vecchi si tolgono) — decisione 3.

#### 5.3.6 Dati che l'utente deve dare (mai inventarli) e stati vuoti

1. **Le obiezioni tipiche e le buone risposte di esempio** (per gli esempi di Ruby): le scrive o le approva l'utente; il
   template ne ha tre solo dimostrative.
2. **I criteri del giudizio** («ottima», «buona», «debole»): il template premia chi «usa Prisma per farlo vedere»;
   l'utente conferma la griglia (decisione 4).
3. **Dati di prodotto** citati nelle risposte (riscatti parziali «dopo il primo anno», penali, costi): vengono solo dalle
   condizioni dei prodotti in archivio (`Prodotto.condizioni`); senza, Ruby non li cita e la suggerita dice «come
   prevedono le condizioni del prodotto».
4. **Aliquote fiscali** per il «netto» (2,2% dal 3% lordo): dal motore fiscale di Prisma (26% o 12,5% secondo
   l'attività), mai da Qwen.
Stati vuoti: §1.7.

#### 5.3.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `720-studio-palestra` / `-scuro` | prima obiezione con le tre risposte e il campo libero |
| `721-studio-palestra-turno` / `-scuro` | dopo una risposta: bolla, giudizio «Ottima», replica |
| `722-studio-palestra-fine` / `-scuro` | tile finale con anello, frase, pulsanti, «Rifai» |
| `723-studio-palestra-ruby-non-pronta` | Qwen non pronto |
| `724-studio-palestra-ruby-scrive` | puntini e prima riga che si scrive (stato fermo) |
| `725-studio-palestra-profilo-scarno` | cliente con pochi dati |

Testi delle istantanee scritti nel codice (come le istantanee di Messaggi), mai chiesti a Qwen nel workflow.

#### 5.3.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole: **Ruby** (unico motore Qwen locale; prompt in `Ruby/`; Prisma prepara le cifre, Qwen racconta; se Qwen non è
pronto Ruby lo dice e non risponde), **dati in locale** (il profilo del cliente va solo a Qwen su 127.0.0.1: nessuna
uscita), principio dell'**analisi** (la palestra allena a spiegare con gli strumenti di analisi di Prisma), tema e
movimento.

**Decisioni:**
1. **Ruolo nuovo di Ruby**: un percorso dedicato `PalestraRuby` con le sue istruzioni (proposta) invece di un terzo caso di
   `ModalitaRuby`. Va bene?
2. **Con quale cliente**: con i clienti veri (il template: «il suo profilo vero»), solo con quelli di prova, o anche con
   profili inventati? Recitare un cliente vero resta sul Mac, ma è una scelta di stile e di riservatezza.
3. **Salvare gli allenamenti**: niente, solo il punteggio (proposta), o tutta la conversazione?
4. **Griglia del giudizio** e **testi normativi**: la palestra non deve insegnare a forzare; serve la conferma che i criteri
   (niente pressione, niente promesse di rendimento, coerenza con adeguatezza e IDD/MiFID) sono quelli giusti. Nessun testo
   normativo va inventato: se si vuole citarne uno, lo fornisce l'utente.
5. **Obiezioni e risposte di esempio**: le scrive l'utente o le propone Ruby da approvare? In ogni caso
   `Ruby/Esempi/palestra.json` sta nel repository: **mai dati veri di clienti** (regola di `Ruby/README.md`), solo frasi
   anonime o dei clienti di prova.
7. **iPhone e iPad** (secondo giro): la palestra passerebbe dal ponte cifrato con il Mac (`PonteRuby`), quindi il profilo
   del cliente viaggia in rete locale, cifrato, come le altre domande a Ruby: nessuna regola nuova, ma va confermato.
6. **Numero delle obiezioni** (3) e difficoltà (tre livelli come sopra).

---

### 5.4 I traguardi festeggiati

*Voce Novità 10: «I traguardi festeggiati · Il momento giusto, già pronto», glifo `festa` #E5484D,
`vaiA('messaggi',()=>{selM=0})` (riga 1779). In **Messaggi**, nuovo gruppo **«Da festeggiare»** in cima. Anche dalla storia
della settimana (pagina 5, «Festeggialo ›», riga 1724). Codice: `FEST` righe 1759-1761, `festHTML` 1762-1772, `montaFest`
1773-1775; inserimento `MSG.unshift(...FEST)` riga 2091; `compoHTML` riga 998 (ramo `m.fest`) e `montaCompo` 1006.*

#### 5.4.1 Cosa si vede

**1.1 La colonna dei messaggi** (Messaggi, riga 994): sopra i gruppi di Orizzonte («Da mandare oggi», «Questa
settimana») c'è il gruppo **«DA FESTEGGIARE»** con una voce per traguardo: avatar 38, nome, titolo del traguardo («Ha
raggiunto la rendita integrativa», «Un anno insieme»). È il primo elemento della lista: aprendo Messaggi dalla voce Novità si
vede il primo traguardo. La testata di Messaggi in Luce ha anche il segmentato «Messaggi · Campagne» (dell'altra parte).

**1.2 Il pannello del traguardo** (`festHTML`, riga 1762-1772) al posto del compositore:
- **testata** (riga 1762): avatar 46; sopra `.k` **«Da festeggiare · Obiettivo raggiunto ieri»** (il «perché»); titolo
  display 23, 700, −0,4 **«Sofia Romano: ha raggiunto la rendita integrativa»** (nome + titolo con l'iniziale minuscola);
- sotto (18), due colonne con spazio 24:
  - **il biglietto** (560×420, raggio 24, testo bianco, overflow nascosto): fondo radiale 700×500 al 30%/20% dal colore del
    traguardo (#E08A00 per la rendita, #0A84FF per l'anno insieme) a #14202B; ombra 0 30 60 −24 nera al 45%;
    **coriandoli** su una tela; contenuto a 36 dai lati e 34 dall'alto:
    - anello bianco pieno 96/10 con «✓» 34;
    - **«Ce l’hai fatta, Sofia.»** (display 42, 700, −1,2; 16 sopra);
    - **«120.000 €»** (display 34, 700, contato) + **«messi al sicuro in 5 anni e mezzo»** (17, 500, opacità .8);
    - la frase (15, interlinea 1,55, opacità .9, 14 sopra): «La rendita integrativa che avevamo progettato è partita: da
      questo mese arriva ogni mese, per sempre. Grazie per la fiducia di questi anni.»;
    - **«— Denis»** (14, opacità .75);
  - **a destra** (flessibile): `.lbl` **«IL MOMENTO, GIÀ PRONTO»** e tre righe (padding 13, filo `--sep` sotto, spazio 12):
    titolo 14,5 grassetto, sotto `.k`, a destra un pulsante:
    1. **«Il biglietto animato»** · «da mandare su WhatsApp o in Mail» · **«Manda»** → toast «Biglietto animato pronto: lo
       mandi tu»;
    2. **«Una telefonata»** · «domani alle 10:30, in agenda» · **«Aggiungi»** → il pulsante diventa «✓ In agenda», toast
       «Telefonata in agenda: domani alle 10:30»;
    3. **«L’idea per un regalo»** · «Una guida della città dove vuole portare i nipoti» · **«Annota»** → «✓ Annotata»;
  - se il cliente ha una **capsula del tempo** sigillata per questo traguardo: tile viola (bordo rgba(155,111,181,.45),
    fondo .08) **«La capsula del tempo di Sofia è pronta»** · «l’aveva sigillata a giugno 2025, per questo giorno» ·
    pulsante primario **«Apri la capsula»** → esperienza `capsula` della Sala (parte delle Sale);
  - in fondo `.k` (interlinea 1,45): **«Prisma si accorge da solo dei traguardi: obiettivi raggiunti, anniversari, un mutuo
    estinto, un figlio all’università con il piano pronto.»**
- Secondo traguardo (`05-s-fest-1.png`): Giulia, «Un anno insieme», «Il primo incontro fu il 5 novembre 2025», «17.150 € di
  patrimonio in più in un anno», frase dell'anniversario, regalo «Una pianta per il balcone della casa che verrà», niente
  capsula.

**1.3 Stati** (il template non ne ha):
- **Nessun traguardo**: il gruppo «Da festeggiare» non c'è (non un gruppo vuoto).
- **Traguardo già festeggiato** (biglietto mandato, telefonata messa): resta nella lista fino al giorno dopo con la spunta,
  come i messaggi preparati di Orizzonte (`OccasioneMessaggio.preparatoIl`).
- **Senza recapito** (per «Manda»): come `495-messaggi-recapito-mancante`.
- **Qwen non pronto**: la frase è quella fissa di Prisma (§5.3), con la nota «scritta da Prisma: Ruby non è pronta».
- **Senza idea per il regalo**: la riga dice «Nessuna idea dalle note» con «Annota» che apre un campo per scriverla.

#### 5.4.2 Misure e stile

Token in **`DesignSystem/Apple/Tema.Apple+Messaggi.swift`** (esiste: `Tema.Apple.Messaggi`) con un nuovo blocco
`Tema.Apple.Messaggi.Traguardo`:

| Template | Valore | Token |
|---|---|---|
| testata | avatar 46, titolo 23/700/−0,4 | esistono: `Tema.Apple.Messaggi.Pannello.avatar = 46`, `Pannello.titolo` (23, bold, −0,4) |
| biglietto | 560×420, raggio 24, ombra 0 30 60 −24 nero .45 | `Traguardo.biglietto = CGSize(width: 560, height: 420)`, `raggio = Raggio.finestra` (24), `ombra` nuova |
| fondo del biglietto | radiale 700×500 a 30%/20%, colore → #14202B | `Traguardo.fondo(colore:)`, `scuroFondo = #14202B` (lo stesso testo scuro dei pulsanti della storia: una costante sola, `Tema.Apple.Colore.notteProfonda` proposta) |
| colori dei traguardi | rendita #E08A00, anniversario #0A84FF | `Traguardo.Tinta` per tipo: obiettivo = `Colore.arancio`, anniversario = `Colore.anello2`, mutuo estinto = `Colore.anello1` (proposta), figlio all'università = `anello3` (proposta) |
| margini | 36 ai lati, 34 in alto | `Traguardo.padding = EdgeInsets(top: 34, leading: 36, bottom: 34, trailing: 36)` |
| anello | 96/10 con ✓ 34 | `AnelliConcentrici` con `Traguardo.anello = 96`, `spessore = 10` |
| «Ce l’hai fatta» | display 42, 700, −1,2 | `Traguardo.titolo` |
| cifra | 34 / 700; didascalia 17 / 500 / .8 | `Traguardo.cifra`, `Traguardo.didascalia` |
| frase | 15, interlinea 1,55, .9 | `Traguardo.frase` |
| firma | 14, .75 | `Traguardo.firma` |
| colonna destra | righe padding 13, titolo 14,5 grassetto, `.k`, pulsante | `Carattere.corpoGrande` (14,5) in grassetto, `Carattere.secondario` |
| tile della capsula | bordo #9B6FB5 al 45%, fondo all'8% | tinta `capsula` della parte comune (`Tema.Apple.Colore.Glifi.capsula` #9B6FB5) |
| coriandoli | 70 rettangoli w 3-8 (w × w/2), colori #FFF #FFD60A #5AC8FA #FF9F0A #C4B5FD | `Traguardo.Coriandoli.numero = 70`, `lato = 3...8`, `colori` (nuovi: #FFD60A, #5AC8FA, #FF9F0A, #C4B5FD) |

Il biglietto ha colori fissi nei due temi (`05-c-fest-0` e `05-s-fest-1`), come un oggetto da mandare; la colonna destra
segue il tema.

#### 5.4.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Cambio di voce | uscita 130 ms (opacità 0, x +10), poi cascata `.st` (riga 997) | come il cambio di voce di Messaggi oggi (`Tema.Apple.Messaggi.Moto`) |
| Cifra | `conteggi` | `NumeroCheConta` |
| Anello | `accendi(…, 200)` | `Moto.Anello` con ritardo 0,2 |
| Coriandoli | 70 pezzi che cadono a 40-100 px/s, ondeggiano (sin(2t)·0,4 px) e ruotano (2 rad/s); rientrano dall'alto fino a 6 s; dissolvenza da 5 s a 8 s; a canvas | **nuovo** `Tema.Apple.Moto.Coriandoli` (`durataPioggia = 6`, `inizioDissolvenza = 5`, `fine = 8`, `velocita = 40...100`, `rotazione = 2`), disegnati in `TelaAnimata` (parte comune) che si **ferma** a 8 s (`paused`): niente ciclo infinito. Il template usa `Math.random()`: nell'app un generatore con seme fisso per traguardo (stesso disegno a ogni apertura e nelle istantanee) |
| Pulsanti | «Aggiungi» → «✓ In agenda», «Annota» → «✓ Annotata» | `Moto.Spunta` (esiste) sul pulsante |

**Riduci movimento**: niente coriandoli (come nel template: `if(ridotto)return`), cifra completa, anello pieno, dissolvenza
0,15 s. **Istantanee**: biglietto fermo, **senza** coriandoli (o con i coriandoli in una posizione fissa del seme: proposta
senza, per un'immagine pulita), pulsanti nello stato iniziale.

#### 5.4.4 Interazioni

- **Aprire**: voce Novità 10 → Messaggi con il primo traguardo; «Festeggialo ›» della storia → il traguardo di quel cliente;
  dal dossier del cliente (proposta: una riga «Da festeggiare» nella panoramica); dalla notifica (proposta: una notifica
  interna di Prisma «Sofia ha raggiunto la rendita», solo nel pannello delle notifiche, `Shell/Notifiche.swift`).
- **«Manda» il biglietto**: nel template è solo un toast. Proposta (vedi §8): Prisma prepara **un'immagine** (PNG su carta
  del biglietto, senza animazione) o un **breve video** (MP4 di pochi secondi, con l'anello che si riempie e i coriandoli)
  e lo passa al **foglio di condivisione del Mac** (`NSSharingServicePicker`: Mail, Messaggi, WhatsApp se installato, salva
  su file); il consulente sceglie e spedisce lui. Come in Messaggi oggi (`Shell/AperturaMessaggi.swift`: Prisma apre, non
  spedisce mai). Il testo del biglietto si può modificare prima.
- **«Aggiungi» la telefonata**: crea un `Appuntamento` `tipo: .telefonata` con il cliente, al primo spazio libero di domani
  negli orari di lavoro (`OrariLavoro`; il template dice 10:30), con il titolo «Telefonata: {traguardo}»; il pulsante
  diventa «✓ In agenda» e il clic successivo apre l'appuntamento. Se domani non c'è spazio, il primo giorno utile.
- **«Annota» il regalo**: salva l'idea in una nota del cliente (`Dati/Nota.swift`) o nel campo `Cliente.nota` (proposta:
  una `Nota` del cliente con titolo «Idea per un regalo»: `Nota` ha `clienteId`, `titolo`, `testo`, `fissata`, ma **non
  ha etichette**, quindi niente «tag» senza un campo nuovo); «✓ Annotata».
- **Testo del biglietto**: un clic sulla frase la rende modificabile (proposta), con «Riscrivi con Ruby» (tre toni come
  Messaggi).
- **«Apri la capsula»**: `apriEsperienza(.capsula, cliente:)` (parte comune) — solo se il cliente ne ha una e la data è
  arrivata.
- **Segna come festeggiato** / **Non è un traguardo**: dal menu contestuale della voce (proposta), per togliere un
  traguardo che il consulente non vuole festeggiare (per esempio un anniversario in un momento difficile).
- **Modalità cliente**: Messaggi in modalità cliente mostra solo le occasioni di quel cliente (`OccasioniMessaggi.soloCliente`):
  il biglietto si può mostrare al cliente (è fatto per lui), la colonna destra (regalo!) **no**: proposta di nasconderla
  in modalità cliente.
- **iPhone/iPad**: Messaggi c'è sull'iPhone (`iOS/MessaggiTelefono.swift`): il gruppo «Da festeggiare» appare anche lì
  (stesso motore); il biglietto in alto, le tre azioni sotto (gerarchia di Design/iphone.html).

#### 5.4.5 Mappa verso Prisma

**5.1 Esiste già**
- Messaggi: `Shell/AppMessaggi.swift` (vista), `Shell/StatoMessaggi.swift`, `Shell/PannelloMessaggio.swift`,
  `Shell/SessioneMessaggi.swift`, `Shell/CollegamentiMessaggi.swift`; motore `Motori/MotoreOccasioniMessaggi.swift` con
  `GruppoMessaggio { oggi, settimana }` (riga 48), `OccasioneMessaggio` (riga 68, con `perche`, `cifre`, `priorita`, `data`,
  `preparatoIl`), `OccasioniMessaggi` (riga 125); tipi in `Dati/MessaggioCliente.swift:11` (`TipoOccasioneMessaggio`:
  riepilogoIncontro, scadenzaPosizione, compleanno, consenso, riesame, occasioneAgenda, parcella, avvisoMercato,
  provaFuoco); testi fissi in `Motori/ModelliMessaggi.swift`; Ruby in `Ruby/MessaggiRuby.swift` con `Ruby/Istruzioni/messaggi.md`;
  apertura di Mail/Messaggi in `Shell/AperturaMessaggi.swift`; gettoni in `Tema.Apple+Messaggi.swift`; istantanee
  490-496 in `Shell/IstantaneeMessaggi.swift`.
- Obiettivi: `Obiettivo` (`Dati/Prodotti.swift:172`: importo, scadenza, posizioni collegate, accantonato) e
  `AvanzamentoObiettivo` (`Prodotti.swift:233`: `quota` 0-1). **Non c'è** una data di raggiungimento salvata.
- Anniversari: `Cliente.creatoIl`, primo appuntamento concluso, decorrenza della prima posizione.
- Mutuo: posizioni `AreaPosizione.debiti` con debito residuo (`Posizione.valore`, `Dati/Posizione.swift:162`) e scadenza.
- Figli: `Cliente.famiglia: [Familiare]` (età), obiettivi `AreaBisogno` di studio.
- Patrimonio in più in un anno: `MotoreAnnoInsieme` / `MotoreAndamentoPortafoglio`.
- Agenda: `Appuntamento`, `TipoAppuntamento.telefonata`, `OrariLavoro`. Note: `Dati/Nota.swift`.
- Notifiche interne: `Shell/Notifiche.swift`, `Shell/PannelloNotifiche.swift`.

**5.2 Da creare**
- **`Motori/MotoreTraguardi.swift`** (puro, con `oggi`):

```swift
enum TipoTraguardo: String, Codable { case obiettivoRaggiunto, anniversario, mutuoEstinto, studiFigli, rendita }
struct Traguardo: Identifiable, Hashable {
    let id: String            // "\(tipo)-\(clienteId)-\(riferimento)", stabile
    let tipo: TipoTraguardo; let clienteId: String; let data: Date
    let titolo: String        // «Ha raggiunto la rendita integrativa»
    let perche: String        // «Obiettivo raggiunto ieri»
    let cifra: Double?; let didascaliaCifra: String?   // «120.000 €» «messi al sicuro in 5 anni e mezzo»
    let frase: String         // la frase fissa di Prisma (Ruby può riscriverla)
    let ideaRegalo: String?   // solo da note e memoria del cliente
    let capsulaId: String?
}
enum MotoreTraguardi {
    static func calcola(dati: DatiPrisma, oggi: Date, finestraGiorni: Int) -> [Traguardo]
}
```

  Regole (da confermare):
  - **obiettivo raggiunto**: `AvanzamentoObiettivo.quota >= 1` per un obiettivo che ieri non lo era. Poiché lo storico
    giornaliero non c'è, serve un campo `Obiettivo.raggiuntoIl: Date?` scritto **la prima volta** che il calcolo lo trova
    raggiunto (lo scrive lo stato, non il motore puro); la cifra è l'importo dell'obiettivo, la didascalia «messi al sicuro
    in {anni da `creatoIl`}»;
  - **rendita partita** (il caso di Sofia): una posizione di previdenza che passa in erogazione (oggi non c'è uno stato
    «in erogazione»: decisione 2) — fino ad allora il caso rientra in «obiettivo raggiunto»;
  - **anniversario**: 1, 5, 10, 15… anni dal primo incontro (primo appuntamento concluso, altrimenti `creatoIl` con
    l'avviso «dalla data d'inserimento»); cifra = patrimonio in più nell'anno (`MotoreAnnoInsieme`), solo se c'è lo storico;
  - **mutuo estinto**: una posizione `debiti` con debito residuo che arriva a 0 o con `scadenza` passata;
  - **studi del figlio**: un familiare a carico che compie 18/19 anni con un obiettivo «studi» raggiunto o avviato;
  - finestra: i traguardi degli ultimi 7 giorni (proposta), non già festeggiati né scartati.
- **Messaggi**: nuovo `GruppoMessaggio.festeggiare` (prima di `oggi`, titolo «Da festeggiare»; `GruppoMessaggio` è un
  `Int` non salvato, quindi spostare i valori grezzi non tocca l'archivio). Attenzione: `OccasioniMessaggi`
  (`MotoreOccasioniMessaggi.swift:125`) oggi ha **solo** `oggi` e `settimana`: serve un terzo elenco `festeggiare`
  (anche in `vuote` e in `soloCliente(_:)`, riga 137); la colonna del Mac elenca i due gruppi a mano
  (`Shell/AppMessaggi.swift:208-212`) e va aggiornata, mentre l'iPhone li prende da `GruppoMessaggio.allCases`
  (`iOS/MessaggiTelefono.swift:64`). E nuovo
  `TipoOccasioneMessaggio.traguardo` (i messaggi sono letti con `ElencoTollerante<MessaggioCliente>`, `Dati/DatiPrisma.swift:198`: una versione
  **vecchia** di Prisma che legge un archivio o un backup nuovo **salta** i messaggi con il tipo `traguardo`, senza
  perdere gli altri; nessun problema nel verso opposto). `MotoreOccasioniMessaggi.calcola` aggiunge le occasioni dai traguardi.
  Il pannello: `Shell/PannelloTraguardo.swift` (biglietto + colonna destra), scelto da `PannelloMessaggio` quando
  l'occasione è un traguardo.
- **Biglietto**: `Shell/BigliettoTraguardo.swift` (vista); per il file da mandare `Shell/EsportaBiglietto.swift`:
  `ImageRenderer` (macOS 13) per il PNG; per il video `AVAssetWriter` con i fotogrammi del `Canvas` (pochi secondi a 30
  fps, 1120×840) — più lavoro: decisione 3.
- **Frase**: modello fisso in `Motori/ModelliMessaggi.swift` (per tipo di traguardo, tre toni) e riscrittura di Ruby con
  `messaggi.md` (stesse regole: solo le cifre della scheda, niente promesse; nessuna cifra nuova o si tiene la bozza).
- **Idea per il regalo**: Ruby la propone **solo** da ciò che il dossier dice (note, memoria degli incontri: «vuole portare
  i nipoti a …»), con la frase da cui viene; se il dossier non dice niente, nessuna idea. Istruzione nuova breve in
  `messaggi.md` o `Ruby/Istruzioni/regalo.md`.
- **Coriandoli**: `DesignSystem/Apple/CoriandoliApple.swift` su `TelaAnimata`.
- **Prova**: `Motori/ProvaCalcoliTraguardi.swift`: obiettivo che supera la quota → traguardo una sola volta; anniversario a
  1 anno esatto e non a 2 (salvo 5, 10…); mutuo a 0; nessuna cifra senza storico; un traguardo festeggiato non torna; un
  messaggio con un tipo sconosciuto si salta senza far fallire la lettura degli altri (`ElencoTollerante`).

**5.3 Campi nuovi dell'archivio (versione di Luce)**
- `Obiettivo.raggiuntoIl: Date?`.
- `Impostazioni.traguardi: ImpostazioniTraguardi? = { tipiSpenti: [TipoTraguardo] = []; anniversari: [Int] = [1, 5, 10,
  15, 20]; festeggiati: [String: Date] = [:] /* id → quando */; scartati: [String] = [] }` (oppure dentro
  `MessaggioCliente` come per le altre occasioni: il messaggio salvato marca l'occasione come fatta).
- La telefonata è un `Appuntamento`; l'idea è una `Nota`: niente di nuovo.

#### 5.4.6 Dati che l'utente deve dare (mai inventarli) e stati vuoti

1. **Quali traguardi** festeggiare (tipi e anniversari) — proposta in §5.3, l'utente conferma.
2. **La data del primo incontro** per gli anniversari dei clienti inseriti dopo (senza, «dalla data d'inserimento»).
3. **Le idee per il regalo**: solo dal dossier; se non c'è niente, nessuna idea (mai «una guida della città» inventata).
4. **Quando una rendita «parte»**: serve lo stato di erogazione della posizione o la data d'inizio della rendita
   (decisione 2).
5. **Il nome con cui firmare** («— Denis»): dai dati del consulente (`DatiFatturazione.nome`), come la firma dei messaggi.
6. **La capsula**: dall'esperienza della capsula (altra parte); senza, la tile non c'è.
Stati vuoti: §1.3. Dati di prova: due traguardi (Sofia e Giulia) nei dati di prova, etichetta «dati di prova».

#### 5.4.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `730-messaggi-traguardo` / `-scuro` | Messaggi con il gruppo «Da festeggiare», primo traguardo (obiettivo raggiunto) con la capsula |
| `731-messaggi-traguardo-anniversario` / `-scuro` | «Un anno insieme», senza capsula |
| `732-messaggi-traguardo-fatto` | telefonata «✓ In agenda» e regalo «✓ Annotata» |
| `733-messaggi-traguardo-senza-regalo` | nessuna idea dal dossier; Qwen non pronto (frase di Prisma) |
| `734-messaggi-traguardo-modo-cliente` | modalità cliente: solo il biglietto |
| `735-biglietto-traguardo` | il PNG del biglietto da mandare (come `515-fattura-carta`) |
| `736-messaggi-traguardo-iphone` | iPhone, Messaggi con il traguardo (in `iOS/IstantaneeMobile.swift`; nome come `609-inquadra-iphone`) |

#### 5.4.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente

Regole: **dati in locale** (il biglietto è un **file dato al cliente** con il nome e una cifra del suo patrimonio, e
passa da WhatsApp o Mail: esce dal Mac per mano del consulente), Ruby (frase e idea del regalo solo dal dossier, cifre di
Prisma), tema e movimento (coriandoli: niente ciclo infinito, calmo, istantanee), modalità cliente, iPhone (Messaggi
telefono).

**Decisioni:**
1. **Il biglietto esce dal Mac** (WhatsApp, Mail): il consulente lo spedisce lui dal foglio di condivisione (proposta), come
   i messaggi di oggi. **WhatsApp** non ha un'API: si passa dal foglio di condivisione del Mac (se WhatsApp è installato) o
   dall'indirizzo `whatsapp://send?text=` (solo testo). Va bene? E **la cifra** («120.000 €») sul biglietto: dato
   patrimoniale che finisce sui server di WhatsApp/Mail. Proposta: interruttore «Mostra la cifra sul biglietto» spento di
   base.
2. **Rendita «partita»**: serve un dato nuovo sulla posizione (in erogazione, dal …) o resta «obiettivo raggiunto»?
3. **Biglietto animato**: video (MP4, più lavoro, `AVAssetWriter`) o immagine ferma (PNG, `ImageRenderer`)? Proposta: PNG
   nel primo giro, video dopo.
4. **Consenso**: un biglietto di auguri non è commerciale, ma se la frase propone qualcosa lo diventa (`commerciale` di
   `TipoOccasioneMessaggio`): proposta di tenere i traguardi **non commerciali** e di vietare proposte nella frase
   (`messaggi.md`).
5. **Quali traguardi e quali anniversari** (§6.1); finestra di 7 giorni.
6. **Telefonata alle 10:30**: primo spazio libero di domani negli orari di lavoro (proposta) o ora fissa scelta
   dall'utente?
7. **Idea per il regalo**: tenerla (solo dal dossier) o toglierla? È una nota privata del consulente: in modalità cliente
   va nascosta.
8. **Il file del biglietto sul Mac**: il PNG (o MP4) da passare al foglio di condivisione contiene nome e, se acceso, una
   cifra del patrimonio. Proposta: crearlo in una cartella temporanea dell'app e cancellarlo dopo la condivisione (o alla
   chiusura), mai nella cartella Download né accanto all'archivio; «Salva su file» solo se il consulente lo sceglie.
9. **Promemoria del traguardo**: la proposta di una notifica è **interna** a Prisma (pannello delle notifiche). Se la si
   vuole anche come notifica del Mac (`PromemoriaMac`), testo generico senza cifre, come per la storia del lunedì.

---

### Riepilogo per chi implementa

| Novità | File nuovi (nomi proposti) | File esistenti da toccare | Istantanee |
|---|---|---|---|
| Territorio | `Shell/AppTerritorio.swift`, `Shell/MappaTerritorio.swift`, `Shell/PannelloTerritorio.swift`, `Motori/MotoreTerritorio.swift`, `Motori/ProvaCalcoliTerritorio.swift`, `DesignSystem/Apple/Tema.Apple+Territorio.swift`, `Risorse/Territorio/comuni.json`, `cap.json` | `AppPrisma.swift` (parte comune), `StatoShell.swift` (`vistaTerritorio`), `Dati/Modelli.swift` (`Cliente.luogo`, `Appuntamento.doveAvviene`), `Dati/DatiPrisma.swift` (`Impostazioni.territorio`, versione), `DatiDemo.swift`, `ClientiFittizi.swift`, `ProvaCalcoli.swift`, `ProvaBackup*` | 700-709 |
| Settimana e anno | `Motori/MotoreStorie.swift`, `Motori/TestiStorie.swift`, `Motori/ProvaCalcoliStorie.swift`, `Shell/StoriaLuce.swift`, `Shell/PagineStoria.swift`, `DesignSystem/Apple/Tema.Apple+Storie.swift` | `StatoFinestre.swift` (`SovrapposizioneLuce.storia`), `ScrivaniaApple.swift`, `StudioApp.swift`, `RipresaSistema.swift`, `PromemoriaMac.swift` (se il promemoria), `DatiPrisma.swift` (`Impostazioni.storie`) | 710-719 |
| Palestra | `Shell/StudioPalestra.swift`, `Shell/StatoPalestra.swift`, `Ruby/PalestraRuby.swift`, `Ruby/ProvaPalestraRuby.swift`, `Ruby/Istruzioni/palestra.md`, `Ruby/Schemi/palestra.json`, `Ruby/Esempi/palestra.json`, `DesignSystem/Apple/Tema.Apple+Palestra.swift` | `StudioApp.swift` (`SchedaStudio.palestra`), `Ruby/ContestoRuby.swift` (scheda per la recita), `Ruby/Istruzioni/README.md`, `DatiPrisma.swift` (`Impostazioni.palestra`) | 720-725 |
| Traguardi | `Motori/MotoreTraguardi.swift`, `Motori/ProvaCalcoliTraguardi.swift`, `Shell/PannelloTraguardo.swift`, `Shell/BigliettoTraguardo.swift`, `Shell/EsportaBiglietto.swift`, `DesignSystem/Apple/CoriandoliApple.swift` | `MotoreOccasioniMessaggi.swift` (`GruppoMessaggio.festeggiare`, `OccasioniMessaggi.festeggiare`), `Dati/MessaggioCliente.swift` (`.traguardo`), `ModelliMessaggi.swift`, `AppMessaggi.swift` (colonna a tre gruppi), `PannelloMessaggio.swift`, `Ruby/Istruzioni/messaggi.md`, `Tema.Apple+Messaggi.swift`, `Dati/Prodotti.swift` (`Obiettivo.raggiuntoIl`), `iOS/MessaggiTelefono.swift`, `IstantaneeMessaggi.swift` | 730-736 |

---

## 6. Stanotte Prisma ha lavorato, la nota vocale, chilometri spese e scadenze

Fonte: `Design/template-luce.html` (5 novembre 2026, 2297 righe; la riga 474 è la tabella `ICONE` in base64 e non va
mai stampata). Per tutto ciò che qui non è detto vale `Design/template-novita-specifica.md` («Orizzonte», §0, §1, §2
Studio › Cruscotto, §8 Copilota, §9 Inquadra e capisci, §13 Prisma ovunque) e, sotto, `Design/template-apple-specifica.md`.
La parte comune di Luce (`luce/01-comune.md`) definisce le cose usate qui: il pannello Novità (voci `stanotte`,
`notaVocale`, `speseScadenze`), la sovrapposizione unica `SovrapposizioneLuce`, il telefono disegnato e il velo
(`TelefonoDisegnato`, `StratoScena` in `DesignSystem/Apple/ScenaTelefono.swift`), la `TelaAnimata`, `GlifoLuce` e il
tassello (`Tema.Apple.Tassello`). Qui si usano con quei nomi.

**Le cifre, i nomi, le ore e le date del template sono dimostrativi.** Nell'app arrivano dai motori e dall'archivio;
dove un dato manca Prisma lo dice, con gli stati del punto 6 di ogni novità.

Riferimenti visivi (scattati con `luce/script/shot06.js`, 1480×940, palco 1440×900 scalato di 1,0137; non sono nel
repository, chi implementa li rigenera con lo script):
- `luce/img/06-notte-{chiaro,scuro}.png` (carte appena aperte), `06-notte-trascina-chiaro.png` (carta trascinata di 90
  verso destra, timbro «APPROVA» a metà), `06-notte-registro-{chiaro,scuro}.png` (dopo un sì e un più tardi),
  `06-notte-fine-{chiaro,scuro}.png` (tutte decise);
- `06-incontri-testata-{chiaro,scuro}.png` (il pulsante «Nota dall'iPhone»), `06-nota-ascolto-{chiaro,scuro}.png`
  (telefono in ascolto, Mac in attesa), `06-nota-arrivata-{chiaro,scuro}.png` (nota arrivata e capita);
- `06-spese-{chiaro,scuro}.png` (Studio › Spese), `06-spese-pacchetto-{chiaro,scuro}.png` (dopo «Inquadra lo
  scontrino» e «Prepara il pacchetto»).

| N. | Novità | Righe del template |
|---|---|---|
| 1 | Stanotte Prisma ha lavorato | CSS 287-296; dati `NOTTE` 1796-1804; `apriNotte` 1805-1810; `chiudiNotte` 1811; `carta` 1812-1815; `pila` 1816-1824; `decidi` 1825-1828 (riga del registro 1828); tastiera 2089; pulsante della scrivania 487 e 522; Novità `NOVL[0]` 2064 |
| 2 | La nota vocale | CSS del telefono 204-207, `.vnRec`/`.vnI` 331-333; `apriNota` 2038-2048; pulsante di Incontri 2088; Novità `NOVL[12]` 2066 |
| 3 | Chilometri, spese e scadenze | `speseHTML` 2050-2059; `montaSpese` 2060-2061; segmentato di Studio 2085-2087; Novità `NOVL[13]` 2066 |

Le utilità comuni del template citate: `anello` 392-395, `accendi` 396, `conteggi` 382, `barre` 400, `rimonta` 845,
`vaiA` 846, `monta` 537-540, `anima`/`tela` 1183-1184, `scrive` 1794, `ridotto` 377.

**Numeri delle istantanee.** In `Sources/` oggi la serie più alta è 613; la parte comune di Luce usa 620-629 e le
parti della Sala 630-668. Qui propongo **760-767** (Stanotte), **770-777** (Nota vocale, Mac e iPhone) e **780-789**
(Spese), da riconciliare con le altre parti nella tabella finale come in Orizzonte §0.5.

---

### 6.1 Stanotte Prisma ha lavorato

Il lavoro della notte: Prisma, da solo e sul Mac, prepara le cose che servono per la giornata (fascicoli, bozze, ricalcoli,
richieste, riesami, la borsa di domani) e la mattina le presenta una per volta, come carte da approvare con un gesto.
Nulla parte e nulla entra nel dossier finché il consulente non approva.

#### 6.1.1 Cosa si vede

**1.1 Come ci si arriva**
- Dalla scrivania: pulsante di vetro **«☾ Stanotte»** in alto a destra, primo dei tre (`#dNotte`, riga 487; poi
  «▶︎ La tua settimana» e «⌕ Cerca ovunque»). Handler a riga 522.
- Dal pannello Novità, gruppo «Per il tuo lavoro», voce 1: **«Stanotte Prisma ha lavorato»** / **«La mattina trovi tutto
  pronto»**, glifo `notte` (luna, riga 1787) su tassello **#1F3A5F** (`NOVL[0]`, riga 2064).
- `apriNotte()` chiude Novità e notifiche, azzera i contatori e mostra la sovrapposizione (riga 1806).
- Proposta per l'app (il template non lo fa): alla prima apertura di Prisma dopo il lavoro della notte (allo sblocco
  dalla schermata di benvenuto) le carte si aprono **da sole una volta** se ci sono carte nuove; poi restano dietro
  al pulsante, che porta il numero delle carte da decidere (pallino come le notifiche). Vedi Decisioni.

**1.2 La sovrapposizione `#notte`** (CSS 287-288, z 95: sopra finestre e dock, sotto la scena del telefono)
- Copre tutto il palco. Sfondo `.nBg`: un alone viola in alto (`radial-gradient` 1000×520 centrato al 50% e a −12%,
  rgba(91,75,200,.24) che sfuma a trasparente al 70%) sopra il velo `--scrim`, con sfocatura 28 e saturazione 1,25.
  Sotto si vedono, sfocati, scrivania, barra e dock (schermate `06-notte-*`).

**1.3 Testata `.nTop`** (riga 289 e 1807): a 120 dai lati, a 70 dall'alto, in riga con spazio 20, centrata in verticale.
- Tassello `notte` #1F3A5F da 52.
- Titolo **«Stanotte ho lavorato per te.»** (display 34, 700, spaziatura −0,8). Parla Prisma in prima persona.
- Sottotitolo `.k` 15: **«Tra le 2:10 e le 2:14 ho preparato 8 cose. Approvale con un gesto: a destra sì, a sinistra
  più tardi.»**, con «8 cose» in grassetto `--ink`. Nell'app le ore sono quelle **vere** di inizio e fine del lavoro
  (vedi §5.3) e il numero è quello delle carte; con una sola carta: «ho preparato 1 cosa».
- A destra (`margin-left:auto`) il pulsante **«Chiudi»** (`.btn`).

**1.4 La pila delle carte** (`.nStack`, riga 290: x 300, y 200, 600×370; `pila`, 1816-1824)
- Si vedono al massimo **tre carte**: la prima davanti, le altre due dietro, spostate in basso di 16 e 32 e rimpicciolite
  a 0,955 e 0,91; la terza ha opacità 0,55. Ordine z 10, 9, 8.
- **Carta** `.nCard` (riga 291): riempie la pila (600×370), raggio **30**, fondo `--cardE`, bordo 1 `--sep`, ombra
  `0 44px 90px -34px rgba(8,30,60,.5), 0 4px 14px -6px rgba(8,30,60,.15)`, padding 28, testo non selezionabile.
  Contenuto (`carta`, 1812-1815):
  - riga (spazio 12): tassello del tipo da 44 con il suo glifo; occhiello `.lbl` nel colore del tipo (per esempio
    «FASCICOLO» blu); a destra, se la carta riguarda un cliente, avatar 34 e nome in grassetto 13,5;
  - titolo (display 27, 700, −0,6, interlinea 1,2), 22 sotto la riga;
  - descrizione `.k` 15,5 interlinea 1,55, 10 sotto;
  - piede a 22 dal fondo e 28 dai lati, 12,5: a sinistra `.k` **«Preparato alle 2:10 · in locale sul Mac»**, a destra
    **«Apri ›»** in `--accent` 600.
- **Timbri** `.nSt` (righe 292-293), nascosti finché non si trascina: **«APPROVA»** verde a sinistra (26 dal bordo,
  ruotato −12°) e **«PIÙ TARDI»** arancio a destra (ruotato +12°); a 30 dall'alto, 21 pt, 800, spaziatura 2, padding
  5×14, bordo 3 nel colore, raggio 10, fondo `--cardE`.

**1.5 I comandi** (`.nCmd`, riga 294: x 300, larghi 600, y 640; centrati, spazio 30)
- Pulsante **✕** arancio (fumetto «Più tardi»), contatore **«1 di 8»** (largo 120, 600, centrato), pulsante **✓** verde
  (fumetto «Approva»). Pulsanti `.nB` (riga 295): tondi da 66, fondo `--cardE`, bordo `--sep`, ombra `--shadow`,
  glifo 25 bold; al passaggio scala 1,08.

**1.6 Il registro «Fatto adesso»** (`.nLog`, riga 296: x 960, y 200, 360×440; raggio 24, fondo `--panel`, bordo `--sep`,
padding 18×20)
- Occhiello `.lbl` **«FATTO ADESSO»**, poi una riga per decisione, la più recente in cima (`decidi`, riga 1828):
  padding 9 sopra e sotto, filo `--sep` sotto, spazio 10, 13,5 pt:
  - approvata: **✓** verde 700 (largo 16) e il testo di conferma della carta (per esempio «Fascicolo approvato»);
  - più tardi: **↺** arancio e «‹titolo della carta› · più tardi».
- Vuoto all'apertura (solo l'occhiello). Nel template non scorre: con 8 righe ci sta; nell'app scorre.

**1.7 La fine** (`pila`, riga 1817): quando non restano carte, al posto della pila una carta centrata con
- anello da 120 spessore 12, verde #30B15C pieno al 100%, con al centro **✓** verde da 46;
- **«Tutto fatto.»** (display 30, 700), 18 sotto;
- `.k` 15: **«7 approvate, 1 per più tardi. Buona giornata, Denis.»** (i numeri sono i conteggi veri; il nome è quello
  del profilo, `DatiFatturazione.nome` o il nome del profilo in Impostazioni);
- pulsante principale grande **«Vai alla scrivania»** (chiude). I comandi `.nCmd` spariscono (opacità 0).

**1.8 Le otto carte del template** (`NOTTE`, righe 1797-1804). Nell'app sono **tipi di carta**; il testo si compone dai
dati veri.

| # | Tipo (occhiello) | Glifo e colore | Cliente | Titolo | Descrizione | Conferma nel registro |
|---|---|---|---|---|---|---|
| 1 | Fascicolo | `cartella` #0A84FF | Giulia | «Il fascicolo di Giulia è pronto» | «Per l'incontro delle 09:30: tre report, sei pagine, con la data di oggi.» | «Fascicolo approvato» |
| 2 | Messaggio | `lettera` #E08A00 | Marco | «Bozza per Marco: il rinnovo dell'Infortuni» | «Scade il 17 dicembre. Tono cordiale, con la proposta per Elena.» | «Bozza pronta in Messaggi» |
| 3 | Ricalcolo | `rischio` #30B15C | — | «35 portafogli ricalcolati» | «Con i valori di ieri sera. Due clienti sono scesi sotto la soglia di attenzione.» | «Ricalcolo visto» |
| 4 | Documento | `scan` #E5484D | Sofia | «La carta d'identità di Sofia scade il 30 novembre» | «Ho preparato la richiesta del documento nuovo, da mandarle quando vuoi.» | «Richiesta pronta» |
| 5 | Moduli | `modulo` #5B4BC8 | Giulia | «I moduli della proposta casa sono compilati» | «Tre moduli, 48 campi. Manca solo l'IBAN per l'addebito.» | «Moduli approvati» |
| 6 | Riesame | `radar` #1E9E6A | Federico Galli | «Il riesame di Federico è pronto» | «Prospetto delle variazioni dell'anno e scheda di adeguatezza da firmare.» | «Riesame approvato» |
| 7 | Campagna | `campagna` #C45A75 | — | «7 clienti senza protezione per il coniuge» | «Sette messaggi personalizzati, da rivedere uno per uno prima di mandarli.» | «Campagna pronta» |
| 8 | Domani | `auto` #2A9BC8 | — | «La borsa di domani» | «2 incontri, 4 documenti da portare, 34 km. Partenza consigliata alle 09:15.» | «Lista della borsa pronta» |

Nota: il glifo `scan` della carta 4 è rosso (#E5484D), ma lo stesso glifo nel pannello Novità («Nuovo cliente in 10
secondi», riga 2065) è viola #5B4BC8; la carta 5 «Moduli» usa proprio quel viola #5B4BC8, mentre il suo glifo `modulo` in
Novità («Compila da solo», riga 2064) è verde #30B15C. `radar` #1E9E6A e `campagna` #C45A75 invece coincidono con
Novità. Nell'app il colore lo dà il **tipo di carta** (tabella §2.3), non il glifo.

**1.9 Stati (proposta per l'app; il template non li ha)**
- **Carte da decidere**: come sopra.
- **Notte senza lavoro** (il Mac era spento, a riposo o Prisma chiuso): la sovrapposizione mostra, al posto della pila,
  una carta con il tassello `notte` spento (opacità 0,45) e il testo **«Stanotte il Mac dormiva.»** / **«Preparo adesso
  le cose di oggi? Ci vogliono pochi minuti.»** con il pulsante **«Prepara adesso»** (lancia lo stesso lavoro, §5.3) e
  «Chiudi». Il pulsante della scrivania non ha il pallino.
- **Lavoro in corso** (dopo «Prepara adesso», o se si apre mentre il lavoro gira): la pila mostra le carte man mano che
  nascono; il sottotitolo dice **«Sto preparando… 3 di 8»**; il contatore dei comandi resta su quelle pronte.
- **Niente da preparare**: carta con l'anello verde pieno e **«Oggi non c'era niente da preparare.»** / «Nessun incontro,
  nessuna scadenza nei prossimi 30 giorni, nessun riesame dovuto.»
- **Qwen non pronto** durante la notte: le carte che hanno bisogno di Qwen (le bozze di testo) non nascono; al loro posto
  **una** carta del tipo «Da finire» con «Ruby non era pronta: 2 bozze da scrivere quando vuoi.» e «Apri ›» che porta a
  Messaggi con le occasioni già scelte. Le cifre e i documenti di Prisma ci sono comunque.
- **Carte di ieri rimandate**: le «più tardi» non decise restano in fondo alla pila del giorno dopo con l'occhiello
  «DA IERI» (proposta) e spariscono quando non hanno più senso (incontro passato, scadenza superata).
- **Modalità cliente** (con un cliente davanti): il pulsante «☾ Stanotte» non si vede e le carte non si aprono da sole
  (contengono altri clienti). Con la presentazione o la sala opaca aperte, idem.

#### 6.1.2 Misure e stile

**2.1 Token che esistono già**

| CSS del template | Valore | Prisma |
|---|---|---|
| `--cardE` | #FFF / rgba(40,54,66,1) | `Tema.Apple.Colore.cardPiena` (#FFFFFF / #283642) |
| `--sep` | nero .08 / bianco .09 | `Colore.separatore` |
| `--panel` | bianco .72 / bianco .05 | `Colore.pannello` |
| `--scrim` | rgba(220,232,240,.4) / rgba(5,12,18,.5) | `Colore.velo` |
| `--green` / `--orange` / `--accent` | #2FA35A / #E08A00 / #007AFF | `Colore.verde` / `.arancio` / `.accento` |
| `--ink`, `--ink2` (.k) | | `inchiostro`, `inchiostro2` |
| `.lbl` | 12, 600, maiuscolo, .6 | `Carattere.etichetta` |
| `.btn`, `.btn.pri.big` | | pulsanti di `PulsantiApple.swift` (capsula, principale grande) |
| `--shadow` (pulsanti tondi) | | ombra `.card` di `Superficie.card` |
| `.nLog` raggio 24 | | `Raggio.finestra` (24) |
| Anello finale 120/12 | | `AnelliConcentrici` (`AnelliApple.swift:28`) con una voce; verde `Colore.anello1` (#30B15C) |
| Tassello 52 e 44 | | `Tema.Apple.Tassello` e `GlifoLuce.notte` (parte comune §4.1) |

**2.2 Token nuovi: `Tema.Apple.Notte`** (file nuovo `DesignSystem/Apple/Tema.Apple+Notte.swift`)

| Nome proposto | Valore | Da |
|---|---|---|
| `Notte.alone` | `RadialGradient` rgba(91,75,200,.24) → trasparente, ellisse 1000×520 al centro (0,5; −0,12), fine al 70% | `.nBg` |
| `Notte.sfocatura` / `.saturazione` | 28 / 1,25 (materiale: `.ultraThinMaterial` sopra `Colore.velo` come ripiego su macOS 13) | `.nBg` |
| `Notte.Testata.margine` / `.dallAlto` / `.spazio` | 120 / 70 / 20 | `.nTop` |
| `Notte.Testata.titolo` | `Carattere(dimensione: 34, peso: .bold, tracking: -0.8)` display | 1807 |
| `Notte.Testata.sottotitolo` | `Carattere(dimensione: 15, peso: .regular)`, `inchiostro2`, numero in grassetto `inchiostro` | 1807 |
| `Notte.Pila.dimensione` | 600×370; posizione relativa: centro della pila a x 600 del palco (fra margine sinistro 300 e il registro) | `.nStack` |
| `Notte.Pila.scarto` / `.riduzione` / `.opacitaTerza` / `.visibili` | 16 / 0,045 / 0,55 / 3 | `pila` 1819 |
| `Notte.Carta.raggio` | **30** (nuovo: `Raggio.dettaglioAperto` è 28, `Raggio.riquadro` 26) | `.nCard` |
| `Notte.Carta.ombra` | due ombre: nero-blu rgba(8,30,60,.5) raggio 90 y 44 rientro −34; rgba(8,30,60,.15) raggio 14 y 4 rientro −6 (`OmbraPrecalcolata` per la prima, come le schede grandi) | `.nCard` |
| `Notte.Carta.padding` | 28 | |
| `Notte.Carta.tassello` / `.avatar` | 44 / 34 (`Misura.Avatar.voce` = 34, esiste) | 1813 |
| `Notte.Carta.titolo` | display 27, 700, −0,6, interlinea 1,2 | 1814 |
| `Notte.Carta.descrizione` | 15,5, interlinea 1,55, `inchiostro2` | 1814 |
| `Notte.Carta.piede` | 12,5; «Apri ›» 600 `accento`; a 22 dal fondo | 1815 |
| `Notte.Timbro` | 21, peso 800 (`.heavy`), spaziatura 2, padding 5×14, bordo 3, raggio 10, rotazione ∓12°, a 30 dall'alto e 26 dal lato; colori `verde` e `arancio` | 292-293 |
| `Notte.Comandi.pulsante` / `.glifo` / `.spazio` / `.contatore` | 66 / 25 bold / 30 / 120 di larghezza, 600 | 294-295 |
| `Notte.Comandi.dallAlto` | 640 (cioè 70 sotto la pila) | 294 |
| `Notte.Registro.dimensione` / `.raggio` / `.padding` | 360×440 / 24 / 18×20; a 60 dalla pila (x 960) | 296 |
| `Notte.Registro.riga` | 13,5; padding 9; segno largo 16, 700 | 1827 |
| `Notte.Fine.anello` / `.spessore` / `.segno` | 120 / 12 / 46 | 1817 |
| `Notte.Fine.titolo` | display 30, 700 | 1817 |

**2.3 Colori dei tipi di carta** (`Tema.Apple.Notte.Tipo`, uguali in chiaro e scuro come nel template)

| Tipo (`TipoCartaNotte`) | Colore | Glifo | Token esistente da riusare |
|---|---|---|---|
| `fascicolo` | #0A84FF | `cartella` | `Colore.Area.investimenti` / `anello2` |
| `messaggio` | #E08A00 | `lettera` | `Colore.arancio` |
| `ricalcolo` | #30B15C | `rischio` | `Colore.anello1` |
| `documento` | #E5484D | `scan` | `Colore.rosso` |
| `moduli` | #5B4BC8 | `modulo` | nuovo (stesso viola della tinta `luce` della parte comune e di «Nuovo cliente» in Novità; il glifo `modulo` in Novità è verde) |
| `riesame` | #1E9E6A | `radar` | nuovo (stesso del glifo `radar` comune) |
| `campagna` | #C45A75 | `campagna` | `Colore.Avatar.giulia` ha lo stesso valore: **non** riusarlo (è un avatar); token nuovo |
| `domani` | #2A9BC8 | `auto` | nuovo |
| `daFinire` (stato §1.9) | `inchiostro2` | `notte` | — |

Il glifo è disegnato nel tassello come nella parte comune (§4.1): bianco su sfumatura del colore.

**2.4 Larghezze.** Il template è a misura fissa sul palco 1440×900. Nell'app la sovrapposizione è centrata: pila 600 e
registro 360 con 60 fra loro, il tutto centrato in orizzontale; sotto 1100 di larghezza il registro va **sotto** i
comandi, largo quanto la pila e alto al massimo 200. La testata segue i margini (120, che scendono a 40 sotto 1100).

#### 6.1.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Apertura della sovrapposizione | opacità 0→1 in 400 ms (1810) | `Tema.Apple.Notte.Moto.apertura = 0.40`, lineare |
| Entrata delle carte (solo la prima volta) | da y +120+k·16 e scala 0,9, opacità 0; 700 ms; ritardo 200 + k·90 ms; curva (.34,1.3,.64,1) (1820) | `Notte.Moto.entrata = 0.70`, `ritardo = 0.20`, `passo = 0.09`, `spostamento = 120`; curva **(.34,1.3,.64,1)**: è la stessa del telefono della scena e delle colonne di Studio (`Tema.Apple.Studio.Moto.curvaColonne`); proposta di spostarla in `Tema.Apple.Moto.Curva.mollaLeggera` e usarla da lì |
| Trascinamento | la carta segue il puntatore: x = dx, rotazione dx/24 gradi; timbri con opacità dx/110 (1823) | `Notte.Moto.rotazionePerPunto = 1/24` (gradi per punto), `soglia = 110` |
| Rilascio sotto soglia | torna a 0 in 0,45 s con curva (.34,1.45,.64,1) (1824) | `Moto.Curva.molla`, 0,45 s (`Notte.Moto.ritorno`) |
| Decisione (gesto o pulsante) | la carta vola a x ±760, rotazione ±26°, opacità 0 in 460 ms, curva (.4,0,.2,1); il timbro della scelta è a opacità 1; intanto la pila sale di un posto senza animazione (1825-1827) | `Notte.Moto.volo = 0.46`, `distanzaVolo = 760`, `rotazioneVolo = 26`, curva `Moto.Curva.backup` (.4,0,.2,1). **Nell'app la pila sale con la molla** (0,45 s), le due carte dietro scorrono di 16 e crescono: nel template saltano |
| Riga del registro | da x +20, opacità 0, 400 ms, curva (.22,1,.36,1) (1828) | `Moto.CascataLaterale` (0,60/30) no: valori propri `Notte.Moto.riga = 0.40`, `spostamentoRiga = 20`, `Curva.uscita` |
| Anello della fine | si riempie da 100 ms (`accendi(st,100)`), 1,4 s | `Moto.Anello` (1,40), ritardo 0,10 |
| Chiusura | opacità 1→0 in 250 ms (1811) | `Notte.Moto.chiusura = 0.25` |
| Pulsanti tondi | scala 1,08 al passaggio, molla 0,25 s | `Moto.PulsantePremuto` con scala sopra 1,08 (token `Notte.Comandi.scalaSopra`) |

- **Riduci movimento** (`\.prismaCalmo`): nel template solo il volo si accorcia (1 ms). In Prisma: la sovrapposizione e
  le carte compaiono ferme con la dissolvenza di 0,15 s; la decisione toglie la carta con la dissolvenza di 0,15 s
  (niente volo né rotazione), il trascinamento sposta la carta **senza ruotarla** e i timbri compaiono lo stesso (servono a
  capire la scelta); anello già pieno.
- **Istantanee** (`\.modoIstantanea`, `\.prismaStatoFinale`): pila già al suo posto, timbri nascosti (tranne
  nell'istantanea del trascinamento, che fissa dx = 90), registro già scritto, anello pieno. Niente Timer: il
  trascinamento è un `DragGesture`, tutto il resto animazioni di SwiftUI.

#### 6.1.4 Interazioni

**Mac**
- **Trascinare la carta** con clic e trascina (`DragGesture`, minimo 1): oltre 110 a destra approva, oltre 110 a sinistra
  «più tardi», sotto soglia torna al centro. Solo la carta davanti si muove; il cursore è la mano aperta e, mentre si
  trascina, la mano chiusa (`NSCursor.openHand`/`closedHand`).
- **Scorrimento orizzontale a due dita** sul trackpad: un `DragGesture` non lo riceve. Proposta: lo stesso monitor locale di
  `Shell/GestoRubyScrivania.swift` (scorrimento a due dita della scrivania, riga 66) o di `AreaScorrimentoAnteprima` in
  `Shell/ProspettiApple.swift` (monitor `.scrollWheel`, riga 760), attivo solo
  mentre la sovrapposizione è aperta e col puntatore sulla pila: lo scorrimento sposta la carta, la fine dello
  scorrimento decide come il rilascio.
- **Pulsanti** ✕ / ✓; **tastiera**: → approva, ← più tardi, Esc chiude (riga 2089, catturata prima di ogni altro Esc). Il
  template non ha Invio: proposta Invio = «Apri ›» della carta davanti. Sul Mac `onKeyPress` è da macOS 14: si usa un
  monitor locale `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` attivo solo con la sovrapposizione aperta (come
  `Shell/GestoRubyScrivania.swift` riga 66, Esc = `keyCode` 53, frecce 123/124, e `Shell/RicercaSpotlight.swift` riga 607),
  oppure `.keyboardShortcut(.cancelAction)` per Esc come `Shell/PannelloNovita.swift` riga 32. (`Shell/ComandiShell.swift`
  **non** è la tastiera: sono i comandi a voce di Ruby.)
- **«Apri ›»**: nel template è solo testo. Nell'app apre la cosa preparata **senza decidere**: il fascicolo nell'anteprima
  dei Prospetti, la bozza in Messaggi, il riesame nel dossier, i moduli in Pratiche, la borsa nell'Agenda del giorno dopo
  (`StatoShell.apri(_:)` con il contesto, come chiede Orizzonte §0.5). Chiude la sovrapposizione; la carta resta da
  decidere e il pulsante «☾ Stanotte» la ritrova.
- **Che cosa fa «Approva»** per tipo (proposta; il template mostra solo la conferma):
  - fascicolo → archiviato nei Documenti del cliente (come oggi l'archiviazione dei report, `fascicoloArchiviato(per:)`)
    e segnato pronto sull'appuntamento;
  - messaggio → la bozza resta in Messaggi con `StatoMessaggio.bozza` e la conferma «Bozza pronta in Messaggi»: **non si
    manda nulla**, mandarlo resta un gesto in Messaggi;
  - ricalcolo → segnato visto (le attenzioni restano dove sono);
  - documento → la richiesta diventa una bozza in Messaggi e un'attività «Chiedere il documento nuovo» con scadenza alla
    data del documento;
  - moduli → i moduli restano in Pratiche come «compilati, da controllare» (sezione Pratiche);
  - riesame → il prospetto entra nei Documenti, la scheda di adeguatezza resta da firmare;
  - campagna → la campagna resta in Messaggi › Campagne con i messaggi in bozza, da rivedere uno per uno;
  - domani → la lista della borsa diventa una nota dell'appuntamento (o attività) del giorno dopo.
- **«Più tardi»**: la carta resta nel lavoro della notte (stato `rimandata`) e torna alla prossima apertura.
- **Annullare**: nel template non si può. Proposta: ⌘Z o un clic sulla riga del registro rimette la carta in cima e
  annulla l'effetto di «Approva» (che per questo non deve mai fare cose irreversibili, vedi sopra).
- Un clic fuori dalla pila non chiude (come la scena del telefono).
- Blocco e riposo del Mac chiudono la sovrapposizione (parte comune §4, «Blocco»); le decisioni già prese restano.

**iPhone e iPad**: il template non le prevede. Proposta: nessuna sovrapposizione sul telefono in questo giro; se «Prisma
ovunque» è acceso, l'istantanea del Mac porta il numero delle carte da decidere e la scrivania del telefono mostra
«Stanotte ho preparato 8 cose: le trovi sul Mac» (solo testo). Da decidere.

#### 6.1.5 Mappa verso Prisma

**5.1 Esiste già (verificato con grep in `Sources/Prisma`)**
- **Lavori a tempo sul Mac**: `NSBackgroundActivityScheduler` del backup automatico (`Shell/StatoShell.swift`
  3040-3066, `avviaBackupAutomatico`, identificatore `local.prisma.backup-automatico`, `qualityOfService = .utility`,
  rinvio con `.deferred` se `lavoriInPausa`); `sospendiLavoriATempo()` e `riprendiLavoriATempo(dopo:)` (2538-2560) chiamati
  da `Shell/RipresaSistema.swift` (`avviaRipresa`: riposo e risveglio, schermo bloccato).
- **Qwen**: `StatoShell.qwen` (`StatoShell.swift:1770`, `MotoriRuby.qwen(...)`), `disponibilitaLocale.pronto`,
  `FornitoreOllama.precarica(restaInMemoria:)` e `libera()` (`Ruby/FornitoreOllama.swift` 84-88: `keep_alive: 0` toglie
  il modello dalla memoria), `OpzioniModello.restaInMemoria`.
- **Fascicolo**: `Shell/Fascicolo.swift` (`TipoProspetto.perIncontro(_:posizione:)`, `documentoFascicolo()`,
  `titoloFascicolo(_:conOra:)`, `preparaFascicolo(per:)`, `fascicoloArchiviato(per:)`); `StampaCarta.pdf(_:)`
  (`Shell/StampaCarta.swift:166`). **Attenzione**: `documentoFascicolo()` legge lo stato dell'interfaccia
  (`clienteAttivo`, `sceltaFascicolo`, `fascicoloAppuntamento`): per la notte serve una variante che riceve cliente,
  appuntamento e scelta e non tocca l'interfaccia.
- **Messaggi**: `MotoreOccasioniMessaggi` / `OccasioniMessaggi` (`Motori/MotoreOccasioniMessaggi.swift`),
  `StatoShell.occasioniMessaggi(oggi:)`, `scriviMessaggio(_:tono:canale:aggiorna:)` (con Qwen, `MessaggiRuby.scrivi`),
  `salvaMessaggio(...)` (`Shell/StatoMessaggi.swift` 11-71), `StatoMessaggio.bozza` (`Dati/MessaggioCliente.swift:141`).
- **Ricalcolo e soglie**: `MotoreAttenzioni.calcola(clienti:posizioni:)` (`Motori/MotoreAttenzioni.swift:82`),
  `CacheMotoriPosizioni`, `DerivatiDati`; aggiornamento dei valori `AggiornaValori` (import da file: la notte **non**
  scarica valori, vedi Decisioni).
- **Documenti d'identità**: `DocumentoIdentita` con `scadenza` (`Dati/Conformita.swift:40`), `MotoreConformita`.
- **Riesami**: `MotoreRiesame.dovuti(clienti:posizioni:appuntamenti:incontri:...)` (`Motori/MotoreRiesame.swift:113`),
  `StatoShell.riesamiDovuti()` (`Shell/DerivatiDati.swift:357`), `TipoProspetto.riesame` («Riesame annuale», `Dati/Prospetto.swift` righe 40 e 69), `FotografiaRiesame`
  (`Dati/FotografiaRiesame.swift`), `SchedaAdeguatezza` (`Dati/SchedaAdeguatezza.swift`). (Un tipo `ProspettoRiesame` non
  esiste.)
- **Agenda di domani**: `Appuntamento` (`inizio`, `luogo`, `tipo`, `posizioneId`; `Dati/Modelli.swift:359`),
  `MotoreDaFare`, `MotoreMossaDelGiorno`.
- **Notifiche del Mac**: `Shell/PromemoriaMac.swift` (`UNUserNotificationCenter`).

**5.2 Dipende da altre novità di Luce**: «Moduli» (Pratiche › Compila da solo), «Campagna» (Messaggi › Le campagne),
«Riesame» con il radar (Posizioni › Il radar), «Domani» con i km (Territorio › Il giro di domani). Finché quelle non ci
sono, i loro tipi di carta **non nascono**: il motore della notte ha un elenco di «preparatori» e ognuno si aggiunge con
la sua novità.

**5.3 Quando gira e come (lavoro in background sul Mac, memoria con 8 GB)**
Il template dice «tra le 2:10 e le 2:14». Su un MacBook con il coperchio chiuso il Mac **dorme** e Prisma non può
lavorare; `NSBackgroundActivityScheduler` non sveglia il Mac. Proposta (vedi Decisioni):
1. **Finestra della notte**: un'ora di inizio scelta dall'utente (proposta 22:00) fino alle 6:00. Un
   `NSBackgroundActivityScheduler` (`local.prisma.notte`, `interval` 1 ora, `tolerance` 15 minuti,
   `qualityOfService = .background`) controlla: è nella finestra, il lavoro di oggi non è fatto, il Mac è **collegato
   alla corrente** (IOKit `IOPSCopyPowerSourcesInfo`, framework di sistema), `thermalState` nominale o discreto, non
   in risparmio energetico, nessun backup in corso, archivio non in sola lettura. Se manca qualcosa: `.deferred`.
2. **Se la notte salta** (Mac a riposo): alla prima apertura del giorno, dopo lo sblocco, la carta «Stanotte il Mac
   dormiva» propone «Prepara adesso» (§1.9). Mai partire da soli mentre l'utente lavora.
3. Mentre lavora: `ProcessInfo.beginActivity(options: [.background, .idleSystemSleepDisabled], reason:)` per non far
   dormire il Mac **a metà** (solo per la durata del lavoro, al massimo 20 minuti, poi si ferma comunque). Impedisce solo
   il riposo per inattività: con il coperchio chiuso (senza schermo esterno) il Mac dorme lo stesso e vale il punto 6.
4. **Ordine fisso, uno per volta**: prima i preparatori **senza Qwen** (ricalcolo, scadenze dei documenti, riesami dovuti,
   borsa di domani, fascicoli), poi quelli con Qwen (bozze dei messaggi, campagne). Mai due cose insieme.
5. **Memoria (8 GB)**: Qwen 3.5 4B in Ollama occupa alcuni GB (ordine di grandezza 3 GB con la quantizzazione di base:
   **stima, da misurare sul Mac dell'utente** con `ollama ps`, non un valore da scrivere nel codice). Si carica una sola volta con
   `precarica(restaInMemoria:)` breve, si scrivono le bozze una dopo l'altra (al massimo `ImpostazioniNotte.massimoBozze`,
   proposta 10), poi `libera()` subito. Un `DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical])`
   ferma il lavoro di Qwen al primo avviso e libera il modello; le carte già pronte restano, le altre diventano la carta
   «Da finire». I PDF dei fascicoli si generano uno per volta e si scrivono subito sul disco (niente PDF tenuti in
   memoria); con molti incontri l'indomani, al massimo 6 fascicoli (proposta).
6. **Stop del Mac a metà**: `sospendiLavoriATempo()` ferma il lavoro della notte (le carte fatte restano, il resto riprende
   alla prossima finestra o con «Prepara adesso»). Il blocco (schermata di benvenuto) **non** ferma il lavoro: Prisma
   di notte è bloccato.
7. **Prisma deve essere aperto**: se l'utente lo chiude la sera non succede nulla. Aprire Prisma all'accesso (`SMAppService`,
   macOS 13) è una decisione dell'utente.

**5.4 Cosa va creato**
- `Dati/LavoroNotte.swift`: `struct NotteDiLavoro: Codable { var giorno: Date; var inizio: Date?; var fine: Date?;
  var carte: [CartaNotte]; var esito: EsitoNotte /* fatta, saltata, interrotta, inCorso */ }`;
  `struct CartaNotte: Codable, Identifiable { id; tipo: TipoCartaNotte; clienteId: String?; riferimento: String /* id
  dell'oggetto preparato: appuntamento, messaggio, documento, riesame… */; titolo; descrizione; conferma; preparataIl: Date;
  stato: StatoCartaNotte /* daDecidere, approvata, rimandata, scaduta */; decisaIl: Date? }`;
  `enum TipoCartaNotte: String, Codable, CaseIterable { fascicolo, messaggio, ricalcolo, documento, moduli, riesame,
  campagna, domani, daFinire }`. Gli id delle carte sono stabili (tipo + riferimento + giorno) così rifare il lavoro non
  duplica nulla.
- `Motori/MotoreNotte.swift` (puro, niente `Date()` dentro): `static func preparativi(clienti:posizioni:appuntamenti:
  incontri:documenti:messaggi:impostazioni:oggi:) -> [Preparativo]` che decide **cosa** preparare (appuntamenti di domani
  con cliente → fascicolo e borsa; documenti d'identità che scadono entro `giorniDocumenti` (proposta 30) → richiesta;
  riesami dovuti entro 14 giorni → riesame; occasioni di messaggio con priorità alta → bozza; attenzioni nuove rispetto
  a ieri → ricalcolo), e `testi(_:)` che compone titolo, descrizione e conferma con le cifre vere. I testi in
  `Motori/TestiNotte.swift` (come gli altri `Testi*.swift`).
- `Shell/StatoNotte.swift`: l'esecutore (scheduler, condizioni, ordine, memoria, `beginActivity`, interruzione), le
  decisioni (`approva(_:)`, `rimanda(_:)`, `annulla(_:)`) e il collegamento con `apri(_:)`.
- `Shell/CarteNotte.swift`: la vista (testata, pila con il gesto, comandi, registro, fine, stati) come caso `.notte` di
  `SovrapposizioneLuce` (parte comune).
- Pulsante «☾ Stanotte» della scrivania (`Shell/ScrivaniaApple.swift`, accanto agli altri pulsanti di vetro della parte
  comune), con il pallino delle carte da decidere.
- `DesignSystem/Apple/Tema.Apple+Notte.swift` (§2).
- Notifica del mattino (proposta, spenta di base): con `PromemoriaMac`, «Stanotte ho preparato 8 cose» all'ora di inizio
  del lavoro dell'utente (`Impostazioni.orari`).

**5.5 Campi nuovi dell'archivio** (nella versione di Luce dopo la 26, letti con `decodeIfPresent`; entrano nel backup e in
`Prisma --prova-backup`)
- `DatiPrisma.notti: [NotteDiLavoro]` (solo le ultime 14: si potano a ogni lavoro).
- `Impostazioni.notte: ImpostazioniNotte { attivo: Bool = false; inizio: Int = 22 /* ora */; soloConCorrente = true;
  usaQwen = true; massimoBozze = 10; massimoFascicoli = 6; giorniDocumenti = 30; apriAlMattino = true;
  notificaAlMattino = false; preparatori: Set<TipoCartaNotte> /* quali tipi preparare */ }`.
- I fascicoli preparati sono `Documento` del cliente (esiste); le bozze `MessaggioCliente` (esiste).

**5.6 Prove nuove**
- `Motori/ProvaCalcoliNotte.swift` (chiamata da `ProvaCalcoli.esegui()`): un appuntamento domani → una carta fascicolo e
  una «domani»; un documento che scade fra 20 giorni → carta documento, fra 40 no; un riesame dovuto → carta riesame;
  nessun dato → nessun preparativo; ids stabili (due esecuzioni → stesse carte); carte rimandate di un appuntamento
  passato → `scaduta`; titolo al singolare con una sola carta.
- `Prisma --prova-backup`: `notti` e `Impostazioni.notte` vanno e tornano (in `ProvaBackupStudio` o una
  `ProvaBackupNotte`).
- Prova di memoria (nella prova guidata esistente, `Shell/ProvaGuidata.swift`): un avviso di memoria finto ferma il lavoro
  di Qwen e chiama `libera()`.

#### 6.1.6 Dati che l'utente deve dare e stati vuoti
- **Accendere il lavoro della notte** e l'ora di inizio (Impostazioni › Ruby o una pagina «La notte»; proposta: spento
  di base, acceso dall'utente). Senza: il pulsante della scrivania apre la carta «Prepara adesso».
- Quali tipi di carta preparare (tutti di base).
- I report da mettere nei fascicoli: Prisma usa `TipoProspetto.perIncontro` (esiste); se l'appuntamento non ha tipo né
  posizione, il fascicolo ha solo il resoconto e la carta lo dice.
- Le bozze: tono e firma sono quelli di Messaggi (`firmaMessaggio`); se mancano i dati della firma, la carta lo dice
  («Manca la tua firma: la bozza è senza saluto»).
- La «partenza consigliata» e i km della borsa vengono da Territorio: senza il punto di partenza e le distanze (vedi
  novità 3, §6) la carta dice «2 incontri, 4 documenti da portare» **senza km e senza orario di partenza**.
- Il nome nel saluto finale: dal profilo; senza, «Buona giornata.».
- Mai inventare: se il calcolo di un riesame non ha i dati, la carta non nasce (al suo posto nulla, oppure un'attività
  «Completare i dati di X» se l'utente lo vuole).

#### 6.1.7 Istantanee da aggiungere (Mac, `Shell/IstantaneeNotte.swift`, chiaro e scuro)

| Nome | Cosa |
|---|---|
| `760-notte-carte` / `-scuro` | otto carte dei dati di prova, la prima davanti, registro vuoto |
| `761-notte-trascina` | la prima carta trascinata di 90 a destra (timbro «APPROVA» a 0,82) |
| `762-notte-registro` / `-scuro` | dopo un sì e un più tardi: «3 di 8», due righe nel registro |
| `763-notte-fine` / `-scuro` | tutte decise: anello pieno, «Tutto fatto.», registro con 8 righe |
| `764-notte-saltata` | «Stanotte il Mac dormiva.» con «Prepara adesso» |
| `765-notte-da-finire` | Qwen non pronto: carta «Da finire» in fondo alla pila |
| `766-notte-stretta` | finestra stretta: registro sotto i comandi |
| `767-scrivania-stanotte` | la scrivania con «☾ Stanotte» e il pallino «8» |

Ferme nello stato finale (`\.modoIstantanea`). Aggiornare la vetrina `400-vetrina-apple` con una carta della notte e i
due timbri.

#### 6.1.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente
- **Lavoro in background** (regola «lavori a tempo» e Mac a riposo): il Mac dorme di notte; Prisma non può svegliarlo
  senza cambiare le impostazioni di energia (`pmset repeat wake`, che chiede la password di amministratore) e non deve
  farlo da solo. **Decisione 1**: (a) lavoro solo se il Mac è acceso e alla corrente nella finestra della notte, altrimenti
  «Prepara adesso» al mattino (proposta); (b) l'utente imposta da sé il risveglio programmato del Mac; (c) niente notte:
  solo «Prepara adesso».
- **Decisione 2**: aprire Prisma all'accesso al Mac (`SMAppService.mainApp`, macOS 13) perché il lavoro trovi Prisma
  aperto? Proposta: no, si dice nelle Impostazioni.
- **Memoria (M1, 8 GB)**: Qwen di notte occupa 3-3,5 GB; con altre app aperte macOS può comprimere o scrivere su disco.
  **Decisione 3**: bozze di Qwen di notte sì (con i limiti di §5.3) o solo carte senza Qwen?
- **Le carte si aprono da sole al mattino?** (Decisione 4; proposta sì, una volta, mai in modalità cliente.)
- **Che cosa fa «Approva»** per ogni tipo (§4): nessuna approvazione manda qualcosa a un cliente; mandare resta un gesto in
  Messaggi. Da confermare tipo per tipo, in particolare «documento» (crea anche un'attività?) e «domani» (nota o
  attività?).
- **Valori di mercato di notte**: il testo «con i valori di ieri sera» suggerisce un aggiornamento automatico. Prisma
  ricalcola **solo con i valori già in archivio**; se Mercato è acceso (eccezione BCE/Eurostat, `ImpostazioniMercato.attivo`)
  il lavoro della notte può aggiornare le serie pubbliche? **Decisione 5** (proposta: no, la notte non va mai in rete).
- **Testi**: «Buona giornata, Denis.» usa il nome del profilo; la carta «7 clienti senza protezione per il coniuge» è una
  campagna (Messaggi): nessun testo normativo.
- **Notifica al mattino** (`UNUserNotificationCenter`, già usato): solo sul Mac, spenta di base. Il testo compare anche
  sulla schermata bloccata e nel Centro notifiche: **solo il numero** («Stanotte ho preparato 8 cose»), mai nomi di
  clienti, titoli delle carte o cifre (**Decisione 7**: confermare il testo senza nomi).
- **«Partenza consigliata alle 09:15»** (carta «Domani»): servono i tempi di viaggio, cioè percorsi e traffico. Con
  MapKit (`MKDirections`) gli indirizzi dei clienti vanno ai server di Apple: è la stessa domanda della Decisione 1 di
  «Chilometri, spese e scadenze» e di Territorio, e la notte **non** deve andare in rete da sola. Proposta: senza una
  scelta esplicita dell'utente la carta non dice né l'ora di partenza né i km (§6).
- **Archivio e backup**: `notti` e `Impostazioni.notte` entrano nell'archivio e nel backup; l'elenco di CLAUDE.md («Il
  backup comprende clienti, agenda, posizioni…») va aggiornato con il lavoro della notte quando lo si implementa.
- iPhone/iPad: nulla in questo giro (§4), salvo il conteggio nell'istantanea di «Prisma ovunque» se acceso: **Decisione 6**.
- Nessuna dipendenza esterna; IOKit e `DispatchSource` sono di sistema. Nessuna API sopra macOS 13.

---

### 6.2 La nota vocale

Tra una visita e l'altra il consulente detta una nota all'iPhone. La voce diventa testo **sull'iPhone**, il testo va al
Mac sul ponte cifrato e lì Prisma capisce di quale cliente si parla e propone cosa farne: la nota nel dossier,
un'attività, un messaggio, un obiettivo da aggiornare.

#### 6.2.1 Cosa si vede

**1.1 Come ci si arriva**
- **Incontri** (Mac): nella testata, a destra, il pulsante **«🎙 Nota dall'iPhone»** (`.btn` con il glifo `voce` da 14,
  riga 2088; schermata `06-incontri-testata-*`). Apre la scena del telefono (`apriNota`, riga 2039).
- Dal pannello Novità, gruppo «Per il tuo lavoro», voce 13: **«La nota vocale»** / **«Tra una visita e l'altra,
  dall'iPhone»**, glifo `voce` (microfono) su #E5484D (`NOVL[12]`, riga 2066): apre Incontri e poi la scena dopo 400 ms
  (Incontri già davanti) o 900 ms.
- Nel template la scena sul Mac **racconta** cosa succede sui due apparecchi: a sinistra il telefono disegnato, a destra
  la scheda del Mac. Nell'app sono **due cose distinte**: la schermata vera dell'iPhone (§1.3) e, sul Mac, la scheda
  «Arriva sul Mac» (§1.4) che compare quando la nota arriva. La scena col telefono disegnato resta solo come
  spiegazione («Come funziona», come per Inquadra) e per le istantanee.

**1.2 La scena sul Mac (template)** (`#scan`, riga 207; telefono a x 300 y 100; scheda a x 700 y 150, larga 470)
- Velo della scena (parte comune §4.2): rgba(6,14,20,.55) con sfocatura 8, sopra tutto.
- **Telefono disegnato** 300×620 (righe 204-206). Schermo (riga 2040-2042): sfumatura a 170° da #141B22 a #0B1015,
  testo bianco, padding 58 sopra e 22 ai lati:
  - riga 12, opacità 0,6, ai due lati: **«In macchina · 11:42»** e **«Prisma»**;
  - titolo **«Una nota veloce»** (display 24, 700), 28 sotto;
  - sottotitolo **«Dopo la visita da Giulia»** 13, opacità 0,55, 4 sotto;
  - il testo dettato, 16 interlinea 1,5, alto almeno 140, 22 sotto: si scrive lettera per lettera (in ascolto);
  - l'**onda**: tela 234×50, 10 sotto il testo, 39 barre larghe 3,6, passo 6, raggio 1,8, colore rgba(255,69,58,.9),
    altezza max(3, a·44) centrata (riga 2045);
  - il **pulsante di registrazione** `.vnRec` (righe 331-332): cerchio da 68, bordo 4 bianco all'85%, a 62 dal fondo;
    dentro un quadrato rosso #FF453A da 28 con raggio 8 che «respira» (1,6 s). Finita la nota: bordo verde #30D158 e
    dentro un cerchio pieno verde da 50 (`.stop`);
  - sotto, a 34 dal fondo, 12, opacità 0,6: **«Ascolto · sull'iPhone»**, che diventa **«✓ Nota mandata al Mac»**.
- **Scheda del Mac** (`.card`, riga 2043): 470 di larghezza, padding 22×24, fondo `--cardE`.
  - Testata: sfera di Ruby viva da 26, occhiello **«ARRIVA SUL MAC»**, a destra il pulsante ✕ (padding 6×10).
  - Prima della nota: `.k` **«Aspetto la nota…»** (padding 20 sopra e sotto).
  - Arrivata la nota (riga 2047): una riga con avatar 40, `.k` **«Prisma ha capito che si parla di»** e il nome in
    grassetto 16 **«Giulia Rossi»**, con filo sotto (padding 6 sopra, 12 sotto); poi **quattro voci** `.vnI` (riga 333:
    padding 10×14, 10 sopra, raggio 12, fondo `--chip`, filo sinistro da 3 nel colore della voce), ciascuna con titolo
    grassetto 13,5 e riga `.k` 13:
    | Voce | Colore | Titolo | Riga |
    |---|---|---|---|
    | nota | #0A84FF | «Nota salvata nel dossier» | ««Giulia vuole anticipare la casa di un anno.»» (la prima frase, fra virgolette basse) |
    | attività | #30B15C | «Attività creata» | «Risentire Giulia per il mutuo · gennaio» |
    | messaggio | #E08A00 | «Messaggio pronto» | «Il confronto con 650 € al mese» |
    | obiettivo | #8B5CF6 | «Obiettivo da aggiornare» | «Casa: un anno prima · da confermare» |
- Il testo dettato del template: «Giulia vuole anticipare la casa di un anno. Risentirla a gennaio per il mutuo, e
  mandarle il confronto con 650 euro al mese.» (riga 2039).

**1.3 L'iPhone (nell'app)** — segue `Design/iphone.html` (una cosa principale grande in alto, il resto a un tocco) e lo
schermo disegnato del template, ma **nel tema dell'iPhone** (barra, acqua, finestre di vetro), non in nero fisso:
- Dove: in **Incontri** sull'iPhone, pulsante grande **«Nota veloce»** in alto (glifo `voce`), e — proposta — un'azione
  rapida dall'icona di Prisma (Quick Action «Nota veloce», `UIApplicationShortcutItem`, iOS 13+). Vedi Decisioni per
  Siri e il tasto Azione.
- Schermata della nota (un foglio a tutto schermo): in alto l'ora (non «In macchina»: Prisma non sa dove sei, vedi
  Decisioni) e «Prisma»; titolo **«Una nota veloce»**; sottotitolo **«Dopo la visita da ‹Nome›»** se nell'agenda c'è un
  appuntamento con un cliente finito da meno di 3 ore (dati dell'iPhone: solo con «Prisma ovunque» acceso), altrimenti
  **«Di chi parli? Dillo nella nota»**; il testo che si scrive mentre parli; l'onda; il pulsante tondo; la riga di stato.
- **Stati della riga di stato** (testi proposti):
  - «Ascolto · sull'iPhone» (in ascolto);
  - «Pronta. Tocca ✓ per mandarla al Mac» (fermata: il testo si può correggere a mano prima di mandarla);
  - «✓ Nota mandata al Mac» (il Mac ha risposto `accettata`);
  - «Il Mac non è raggiungibile: la nota parte quando sarai in rete con il Mac» (in coda, vedi §4);
  - «Nota mandata con Prisma ovunque» (se il ponte non c'è ma lo spazio cifrato è acceso, vedi Decisioni);
  - «Prisma non ha il permesso di usare il microfono…» / «…di riconoscere la voce…» (testi di `PermessiCopilota`).
- La nota resta sull'iPhone in **«Note in partenza»** (elenco sotto il pulsante) finché il Mac non la riceve.

**1.4 Il Mac (nell'app)**
- Quando una nota arriva, compare **la scheda «Arriva sul Mac»** come avviso di Prisma (non come velo a tutto schermo:
  il consulente può essere al lavoro su altro). Proposta: la scheda sta in alto a destra sotto la barra, larga 470, come
  le notifiche; se Prisma è bloccato, arriva nelle notifiche (campanella) e si apre dopo lo sblocco.
- Contenuto come nel template (§1.2, scheda), con queste differenze:
  - sotto il nome del cliente, se Prisma **non è sicuro**, la riga dice **«Di chi si parla?»** con i 2-3 clienti
    possibili come pulsanti, o «Scegli il cliente» (vedi §5.3, riconoscimento del cliente);
  - le quattro voci sono **proposte**, ciascuna con «Conferma» e «Scarta» (come le schede del copilota), più
    **«Conferma tutto»** in fondo; i titoli diventano: «Nota per il dossier», «Attività da creare», «Messaggio da
    preparare», «Obiettivo da aggiornare» (vedi Decisione 2). Dopo la conferma il titolo passa al passato («Nota salvata
    nel dossier», «Attività creata»…), come nel template;
  - una riga `.k` in fondo: «Capito con le regole di Prisma» oppure «Capito con Qwen» (come `PropostaIncontro`).
- Le note arrivate e non ancora guardate stanno anche in **Incontri**, nella colonna «Oggi» (`ColonnaOggiCopilota`),
  come voce «Nota dall'iPhone · 11:42» con il pallino.

**1.5 Stati**
- Mac in attesa (template): «Aspetto la nota…». Nell'app la scheda non esiste finché non arriva una nota; il pulsante
  «Nota dall'iPhone» di Incontri apre invece «Come funziona» e l'elenco delle ultime note arrivate.
- Nessuna proposta trovata: solo la voce «Nota per il dossier».
- Cliente non riconosciuto: «Non ho capito di chi si parla» con «Scegli il cliente».
- iPhone non abbinato: «Collega l'iPhone al Mac: sul Mac, in Impostazioni › Ruby, attiva «iPhone e iPad»…» (testo di
  `PonteRuby.manda`).
- Mac di prima (404): testo `PonteRuby.macDaAggiornare`.
- Archivio del Mac in sola lettura: testo di `riceviDalPonte` («L'archivio del Mac è in sola lettura…»).

#### 6.2.2 Misure e stile

**2.1 Esistenti da riusare**
- Telefono disegnato e velo: `Tema.Apple.Inquadra.Apparecchio` e `.Velo` → `Tema.Apple.Apparecchio` / `VeloScena`
  (parte comune §2), solo per «Come funziona» e le istantanee.
- Onda della voce: `Tema.Apple.Copilota.Onda` (`Tema.Apple+Copilota.swift:169`): 48 barre, passo 7,5, larghe 4,5, raggio
  2,2, altezza max(3, a·40), rosso rgba(229,72,77,.85) in ascolto, grigio .35 da ferma, `durataPasso` 0,10. Il template
  della nota usa 39 barre, passo 6, larghe 3,6, raggio 1,8, max(3, a·44), rosso rgba(255,69,58,.9) e da ferma barre
  alte 3 nello **stesso rosso**: proposta di usare `Copilota.Onda` con una variante `Onda.telefono` (larghezza 234,
  altezza 50, 39 barre, passo 6, larghezza barra 3,6, raggio 1,8, scala 44, colore #FF453A al 90% = rosso di sistema
  scuro), perché lo schermo del telefono è più stretto.
- Sfera di Ruby viva: `SferaRuby` (`DesignSystem/Apple/RubyApple.swift:21`), 26.
- Card, chip, separatore, `Carattere.etichetta`.
- Colori delle voci: nota #0A84FF = `Colore.Area.investimenti`; attività #30B15C = `Colore.anello1`
  (`Tema.Apple.Copilota.attivita` è già `Colore.Area.liquidita` #30B15C); messaggio #E08A00 = `Colore.arancio`;
  obiettivo #8B5CF6 = `Colore.stima` (per il copilota l'obiettivo è `Copilota.obiettivo` = blu: **attenzione**, il
  template della nota usa viola per l'obiettivo e blu per la nota; tenere i colori della nota distinti, token propri).

**2.2 Token nuovi: `Tema.Apple.NotaVocale`** (file `DesignSystem/Apple/Tema.Apple+NotaVocale.swift`)

| Nome proposto | Valore | Da |
|---|---|---|
| `NotaVocale.Scheda.larghezza` / `.padding` | 470 / 22×24 | 2043 |
| `NotaVocale.Scheda.sfera` | 26 | 2043 |
| `NotaVocale.Scheda.attesa` | `.k` con padding 20 verticale | 2043 |
| `NotaVocale.Cliente.avatar` / `.didascalia` / `.nome` | 40 (nuovo: `Misura.Avatar` ha 38 e 54) / 12,5 `inchiostro2` / 16 bold | 2047 |
| `NotaVocale.Voce.padding` / `.sopra` / `.raggio` / `.filo` | 10×14 / 10 / 12 / 3 | `.vnI` 333 |
| `NotaVocale.Voce.titolo` / `.riga` | 13,5 bold / 13 `inchiostro2` | 2047 |
| `NotaVocale.Voce.nota` / `.attivita` / `.messaggio` / `.obiettivo` | #0A84FF / #30B15C / #E08A00 / #8B5CF6 | 2047 |
| `NotaVocale.Telefono.fondo` | sfumatura 170° #141B22 → #0B1015 (solo nel telefono disegnato) | 2040 |
| `NotaVocale.Telefono.titolo` / `.sottotitolo` / `.testo` / `.stato` | display 24 700 / 13 al 55% / 16 interlinea 1,5 / 12 al 60% | 2040-2042 |
| `NotaVocale.Registra.diametro` / `.bordo` / `.dalFondo` | 68 / 4 bianco 85% / 62 | `.vnRec` 331 |
| `NotaVocale.Registra.quadrato` / `.raggioQuadrato` / `.rosso` | 28 / 8 / #FF453A | 332 |
| `NotaVocale.Registra.fatto` / `.verde` | cerchio 50 / #30D158 (verde di sistema scuro) | 332 |

Sull'iPhone vero i colori del pulsante restano quelli (rosso e verde di sistema); fondo e testi seguono il tema
dell'iPhone (`Tema.Apple+Telefono.swift`), in chiaro e scuro.

#### 6.2.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Velo della scena | 300 ms (2044) | parte comune (`StratoScena`) |
| Telefono disegnato | **nessuna entrata** (a differenza di Inquadra e Nuovo cliente, righe 1107 e 2007) | stessa entrata delle altre scene (da y +60, −4°, 0,7 s, curva (.34,1.3,.64,1)) per coerenza |
| Testo che si scrive | una lettera ogni 45 ms, da 700 ms (2046) | sull'iPhone vero il testo arriva dal riconoscimento (parole), **non** si anima; nella scena dimostrativa `TestoProgressivo` a parole |
| Onda | ciclo continuo: a = .2 + .8·\|sin(4t + .5i)·sin(1,7t + .2i)\| (2045) | sull'iPhone l'onda segue il **livello vero** del microfono (`AscoltoRuby` dà il picco di ogni pezzo), come il copilota; nella scena dimostrativa la formula del template con `TelaAnimata` |
| Quadrato che respira | 1,6 s avanti e indietro (`respira`) | `NotaVocale.Moto.respiro = 1.6`, `repeatForever(autoreverses:)` di SwiftUI (niente Timer) |
| Fine della nota | bordo verde in 0,4 s; quadrato → cerchio verde in 0,5 s con `--spring` (332) | `Moto.Curva.molla`, 0,5 s |
| Voci sul Mac | da x +30, opacità 0, 500 ms, ritardo i·260 ms, curva (.34,1.4,.64,1) (2048) | `NotaVocale.Moto.voce = 0.50`, `passo = 0.26`, `spostamento = 30`, curva nuova `Curva(x1: .34, y1: 1.4, x2: .64, y2: 1)` (fra `molla` 1,45 e la molla leggera 1,3: proposta di usare `Moto.Curva.molla`) |
| Scheda del Mac (avviso) | — | entra come le notifiche (`Moto.PannelloNotifiche`) |

- **Riduci movimento**: niente respiro (quadrato fermo), onda che mostra il livello senza scorrere (barre ferme a 3 se
  si preferisce: proposta come il copilota, `opacitaSpento`), voci con dissolvenza 0,15 s, nessuna entrata del telefono.
- **Istantanee**: testo intero, onda nella forma del template al secondo 2 (`Copilota.Onda.tempoIstantanea`), voci
  tutte presenti, pulsante nello stato voluto (in ascolto o fatto).

#### 6.2.4 Interazioni

**iPhone**
- **Tocca il pulsante** per iniziare (chiede i permessi la prima volta: microfono e riconoscimento vocale, con
  `PermessiCopilota.chiedi`), **tocca di nuovo** per fermare. Proposta: anche «tieni premuto per parlare».
- Dopo lo stop il testo si può **correggere** (campo di testo) e poi **«Manda al Mac»** (✓). Proposta: mandare da sola
  dopo 3 secondi se non tocchi nulla, con «Annulla» (da decidere: il template manda subito).
- **Durata massima**: 3 minuti (proposta), poi si ferma da sola con «Nota lunga: fermata a 3 minuti».
- **Schermo bloccato o app in background mentre detti**: l'ascolto si ferma e il testo fin lì resta (nessuna modalità
  audio in background, vedi Decisioni).
- **Coda**: se il Mac non risponde (il ponte funziona solo **sulla stessa rete locale**: «in macchina» non ci sei), la
  nota resta in «Note in partenza» (cifrata sul telefono, vedi §5) e parte da sola quando il Mac torna raggiungibile
  (all'apertura di Prisma, al ritorno in primo piano e quando Bonjour trova il Mac). Si può cancellare dalla coda.
- **iPad**: stessa cosa (stessa vista), meno utile; nessuna differenza.

**Mac**
- Nella scheda «Arriva sul Mac»: «Conferma» / «Scarta» su ogni voce, «Conferma tutto», scelta del cliente se dubbio,
  clic sul nome per aprire il dossier, ✕ per chiudere (la nota resta in Incontri › Oggi da decidere).
- Ogni voce si può **modificare** prima di confermare (testo dell'attività e data; per il messaggio si apre Messaggi con
  l'occasione; per l'obiettivo si apre il dossier sulla scheda Obiettivi con la modifica proposta evidenziata).
- Esc chiude la scheda. Nessuna scorciatoia nuova.

#### 6.2.5 Mappa verso Prisma

**5.1 Esiste già (verificato con grep)**
- **Trascrizione sul dispositivo**: `Ruby/TrascrizioneRuby.swift`: `TrascrizioneClassica` (`SFSpeechRecognizer` con
  `requiresOnDeviceRecognition = true`, riga 108, e controllo `supportsOnDeviceRecognition`, riga 100) e
  `TrascrizioneNuova` (`SpeechTranscriber` / `DictationTranscriber`, `@available(macOS 26.0, iOS 26.0, *)`, righe
  135-141); `Trascrizioni.prepara(_:avviso:)`, `SceltaRiconoscimento` (`automatico`, `nuovo`, `dettaturaSistema`,
  `classico`). Funziona anche su iOS (il copilota dell'iPad la usa).
- **Microfono e permessi**: `Ruby/AscoltoRuby.swift` (`AscoltoRuby`, `MicrofonoReale`, `AscoltoRuby.permessi`, ramo iOS
  riga 366); `PermessiCopilota.chiedi` (`Shell/StatoCopilotaIncontro.swift:113`, ramo iOS con
  `SFSpeechRecognizer.requestAuthorization`). `Supporto/iOS/Info.plist` ha già `NSMicrophoneUsageDescription` e
  `NSSpeechRecognitionUsageDescription` (righe 123-128) — **i testi vanno aggiornati** (oggi parlano solo di Ruby e del
  copilota).
- **Ponte cifrato**: `Ruby/PonteRuby.swift` (`FornitorePonte.manda(_:attesa:)`, riga 243; `PonteRuby.manda(_:ruby:)`,
  riga 311), `Ruby/MessaggiPonte.swift` (`ArrivoPonte` con `.schedeCopilota` e `.inquadratura`, `BustaPonte.copilota` /
  `.inquadra`, limiti `massimoPezzi` 400 e `massimoTestoPezzo` 4.000; versione 2 del protocollo, 404 dai Mac di prima),
  `Ruby/ServerPonteRuby.swift` (`consegnaArrivi`), `StatoShell.riceviDalPonte(_:)` (`Shell/StatoCopilota.swift:184`).
- **Capire il testo**: `Motori/RiconoscitoreCopilota.swift` (regole locali: obiettivi con tempi e cifre, attività
  «ti preparo un confronto», scadenze «a gennaio», importi; e il ramo Qwen `messaggi`/`leggiJSON`/`conQwen`),
  `Motori/EstrattoreIncontro.swift` (`PropostaIncontro`, `conRegole`, `daRisposta`, `unisci`),
  `StatoShell.riconosciConQwenCopilota` (esempio di Qwen in background che si unisce alle regole).
- **Applicare con conferma**: `Motori/ApplicaCopilota.swift` (`applica(_:sessione:a:oggi:)`, id stabili, nessun doppione;
  il profilo MiFID non si tocca mai), `SchedaCopilota` con `Tipo` e `Azione` (`aggiornaObiettivo`, `creaObiettivo`,
  `creaAttivita`, …) e `Stato` (`proposta`, `confermata`, `scartata`) in `Dati/SessioneCopilota.swift:259`.
- **Modelli di destinazione**: `Nota` (`Dati/Nota.swift`: `clienteId`, `titolo`, `testo`, `creataIl`), `Attivita`
  (`Dati/Modelli.swift:431`: `titolo`, `scadenza`, `priorita`, `note`, `appuntamentoId`), `Obiettivo`, `MessaggioCliente`
  (`StatoMessaggio.bozza`), `OccasioneMessaggio`.
- **Prisma ovunque**: `OperazioneOvunque` sa già creare `nota` e `attivita` dal dispositivo (`Dati/ModelliOvunque.swift`,
  righe 102-125), con i conflitti in «Da decidere».
- **iPhone**: `iOS/InquadraTelefono.swift` (un esempio completo di «leggi sul telefono, manda testo al Mac»:
  `PonteRuby.manda(.inquadratura(x), ruby:)`, riga 470), `iOS/GuscioiPhone.swift`, Incontri su iPhone (istantanea
  `13-incontri`).

**5.2 Cosa va creato**
1. **Messaggio nuovo del ponte** «prisma/nota» (`BustaPonte.nota`), caso `ArrivoPonte.notaVocale(NotaVocalePonte)`:
   `struct NotaVocalePonte: Codable, Equatable { id: String; testo: String /* ≤ 4.000 caratteri */; quando: Date;
   durata: Double; dispositivo: String; clienteId: String? /* se l'iPhone lo sa */; appuntamentoId: String?;
   riconoscimento: String /* «sul dispositivo» */ }` con `valido`. **Solo testo**: l'audio non lascia mai l'iPhone
   (regola già scritta in `MessaggiPonte.swift`). Un Mac di prima risponde 404 → `macDaAggiornare`.
2. **Sul Mac**: `StatoShell.riceviDalPonte` gestisce `.notaVocale`: la nota entra in `DatiPrisma.noteInArrivo:
   [NotaInArrivo]` (id stabile = id della nota: ricevere due volte non duplica), poi parte il riconoscimento.
3. `Motori/MotoreNotaVocale.swift` (puro):
   - `cliente(in testo:, clienti:, appuntamenti:, quando:) -> RiconoscimentoCliente` (`.sicuro(id)`, `.dubbio([id])`,
     `.nessuno`): nome e cognome o nome solo se unico (normalizzati con `MotoreDocumenti.normale`), nome dei familiari
     (`Cliente.famiglia`), l'appuntamento concluso più vicino prima di `quando` come indizio; mai una scelta silenziosa se
     due clienti hanno lo stesso nome;
   - `proposte(testo:, cliente:, oggi:) -> [PropostaNota]`: la nota (sempre: prima frase come titolo, tutto il testo come
     corpo), più le schede di `RiconoscitoreCopilota.leggi` convertite (attività con scadenza, obiettivo da aggiornare con
     la differenza di tempi o cifre, «mandarle il confronto…» → messaggio da preparare). Qwen (se pronto) aggiunge e le
     regole vincono sulle stesse cose (come `conQwen`).
4. `Motori/ApplicaNotaVocale.swift`: conferma per voce, con id stabili (nota + voce); nota → `Nota` del cliente; attività
   → `Attivita`; messaggio → occasione aperta in Messaggi (nessun messaggio scritto da solo, o bozza con Qwen se
   confermato); obiettivo → modifica proposta all'`Obiettivo` esistente con conferma esplicita.
5. **Vista Mac**: `Shell/NotaVocaleArrivo.swift` (la scheda «Arriva sul Mac»), voce in `ColonnaOggiCopilota`, pulsante
   «Nota dall'iPhone» nelle azioni di Incontri (`ContenutoApp.azioni`: oggi `case .incontri` non ha azioni → aggiungere
   `AzioniIncontri`), «Come funziona» con la scena del telefono disegnato (`StratoScena` + `TelefonoDisegnato`).
6. **Vista iPhone**: `iOS/NotaVocaleTelefono.swift` (foglio della nota, coda «Note in partenza»), pulsante in Incontri
   dell'iPhone, Quick Action.
7. **Coda sull'iPhone**: `iOS/CodaNoteVocali.swift`: le note non consegnate in un file **cifrato** nella cartella
   dell'app (chiave nel Portachiavi del telefono, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), mai in chiaro;
   al massimo 20 note; consegna con ritentativi (all'apertura, al ritorno in primo piano, quando il ponte trova il Mac).
   Con «Prisma ovunque» acceso e il Mac lontano: proposta di consegnarle come operazione `crea nota` nel giornale del
   dispositivo (`giornale-<dispositivo>.cifrato`) — il Mac poi le passa a `noteInArrivo` invece di metterle direttamente
   nel dossier (Decisione 4).
8. `Tema.Apple+NotaVocale.swift` (§2.2).

**5.3 Campi nuovi dell'archivio** (versione di Luce; `decodeIfPresent`; backup e `--prova-backup`)
- `DatiPrisma.noteInArrivo: [NotaInArrivo]` con `NotaInArrivo { id; testo; quando; durata; dispositivo; clienteId:
  String?; candidati: [String]; proposte: [PropostaNota]; stato: .daGuardare / .confermata / .scartata; arrivataIl }`.
  Le confermate e le scartate si tolgono dopo 30 giorni. Entrano nell'istantanea di «Prisma ovunque»? **No** (sono testo
  dettato, come le trascrizioni del copilota, che l'istantanea esclude).
- Nessun campo sull'iPhone nell'archivio: la coda è fuori dall'archivio.

**5.4 Prove**
- `Ruby/ProvaNotaVocale.swift` (dentro `--prova-ruby`, come `ProvaCopilota`): busta «prisma/nota» sigillata e aperta;
  troppo lunga → rifiutata; ricevuta due volte → una sola nota; cliente riconosciuto nel testo del template («Giulia vuole
  anticipare la casa di un anno…» → Giulia Rossi, attività «Risentire Giulia per il mutuo» a gennaio dell'anno dopo se oggi
  è dopo gennaio, messaggio «confronto con 650 € al mese», obiettivo casa un anno prima); due clienti «Marco» → dubbio;
  nessun nome e nessun appuntamento → nessuno; Qwen assente → solo regole.
- `Prisma --prova-backup`: `noteInArrivo` va e torna.
- `--prova-ovunque` (se si sceglie la consegna col giornale): una nota dal giornale finisce in `noteInArrivo`, non nel
  dossier.

#### 6.2.6 Dati che l'utente deve dare e stati vuoti
- **Abbinare l'iPhone** al Mac (codice del ponte, esiste) e concedere microfono e riconoscimento vocale sull'iPhone.
- **Lingua del riconoscimento sul dispositivo**: italiano scaricato sull'iPhone (`supportsOnDeviceRecognition`); se manca,
  Prisma lo dice e **non** usa il riconoscimento in rete di Apple (oggi `TrascrizioneClassica` rifiuta: resta così).
- Il cliente, se Prisma non lo capisce: lo sceglie l'utente.
- Date relative («a gennaio»): l'anno lo calcola Prisma (`RiconoscitoreCopilota.scadenza`); se ambiguo, l'attività resta
  «da confermare» con la data evidenziata.
- Le cifre (650 € al mese) vengono solo dal testo dettato; Prisma non aggiunge nulla.
- Stato vuoto in Incontri: «Nessuna nota dall'iPhone. Dettane una dopo la prossima visita: arriva qui.»

#### 6.2.7 Istantanee da aggiungere

| Nome | Dove | Cosa |
|---|---|---|
| `770-incontri-nota-pulsante` / `-scuro` | Mac | testata di Incontri con «Nota dall'iPhone» |
| `771-nota-arrivata` / `-scuro` | Mac | scheda «Arriva sul Mac» con il cliente e le quattro proposte (dati di prova del template) |
| `772-nota-confermata` | Mac | dopo «Conferma tutto»: titoli al passato |
| `773-nota-cliente-dubbio` | Mac | «Di chi si parla?» con due clienti |
| `774-nota-come-funziona` / `-scuro` | Mac | scena dimostrativa: telefono disegnato in ascolto + scheda «Aspetto la nota…» |
| `775-nota-iphone-ascolto` | iPhone (`iOS/IstantaneeMobile.swift`) | foglio della nota in ascolto, testo a metà, onda |
| `776-nota-iphone-pronta` | iPhone | nota fermata, «Pronta. Tocca ✓ per mandarla al Mac» |
| `777-nota-iphone-in-coda` | iPhone | «Il Mac non è raggiungibile…» e «Note in partenza» con 2 note |

#### 6.2.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente
- **Microfono e trascrizione**: sull'iPhone, **solo sul dispositivo** (`requiresOnDeviceRecognition`, o `SpeechTranscriber`
  su iOS 26, protetto con `#available(iOS 26.0, *)` come oggi). L'audio **non si registra e non si salva**: si trascrive
  mentre parli (è ciò che dice già `NSMicrophoneUsageDescription`). **Decisione 1**: confermare «niente file audio»
  (proposta); un file audio da riascoltare cambierebbe i testi di Info.plist, la coda e la privacy.
- **Rete**: la nota viaggia **solo** sul ponte cifrato in rete locale (nessun internet). Il caso «in macchina» del
  template non ha il Mac raggiungibile: la nota aspetta in coda, cifrata, sul telefono. **Decisione 4**: con «Prisma
  ovunque» acceso, consegnarla anche attraverso il giornale cifrato su iCloud Drive (eccezione già approvata, ma qui
  esce del **testo dettato su un cliente**, oggi escluso dall'istantanea: va approvato esplicitamente) — oppure solo ponte.
- **Niente entra nel dossier senza conferma** (regola del copilota, `ApplicaCopilota`). Il template dice «Nota salvata»
  e «Attività creata» subito. **Decisione 2**: (a) tutto proposto e confermato sul Mac (proposta); (b) la sola nota
  salvata subito (è il consulente che parla di sé, non il cliente), il resto proposto.
- **Consenso del cliente**: il copilota chiede il consenso all'ascolto perché registra la voce del cliente; la nota
  vocale è la voce del consulente, **senza il cliente**: proposta di **non** chiedere il consenso del copilota
  (`GuardiaCopilota`) ma di avvertire nella schermata: «Detta solo tu: se il cliente è con te, usa il copilota». Da
  confermare (**Decisione 3**).
- **Lavoro in background sull'iPhone**: niente `UIBackgroundModes audio`: a schermo bloccato l'ascolto si ferma
  (proposta). La consegna in coda avviene solo con l'app aperta (niente `BGTaskScheduler`); **Decisione 5** se si vuole
  la consegna in background (BGAppRefreshTask, iOS 13+).
- **«In macchina»**: per saperlo servirebbero posizione o CoreMotion (attività «in auto») o CarPlay: **non** si fa;
  il telefono mostra solo l'ora. Uso alla guida: dettare guidando è un tema di sicurezza stradale; proposta di non
  proporre la nota «in macchina» e nessuna integrazione CarPlay (**Decisione 6**).
- **Servizi Apple**: Siri / Comandi rapidi / tasto Azione (App Intents, iOS 16+, `AppShortcutsProvider`) per avviare la
  nota senza aprire Prisma: utile, ma il testo resta sul dispositivo solo se il riconoscimento è di Prisma; con «Ehi
  Siri, nota a Prisma» la dettatura la fa Siri (che può usare server Apple). **Decisione 7**: solo Quick Action
  dall'icona (proposta) oppure anche App Intents.
- Testi di `Supporto/iOS/Info.plist` (`NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`) da
  aggiornare per citare la nota vocale; anche `Info.plist` del Mac se la scena dimostrativa resta senza microfono (sì:
  sul Mac non serve).
- **Modelli della voce scaricati da Apple**: il riconoscimento sul dispositivo richiede che l'italiano sia scaricato
  sull'iPhone; con `SpeechTranscriber`/`DictationTranscriber` (iOS 26) Prisma lo chiede con
  `AssetInventory.assetInstallationRequest` (`Ruby/TrascrizioneRuby.swift` riga 183): è una connessione ai server di Apple
  **per scaricare il modello**, senza alcun dato dell'utente o dei clienti. Esiste già per Ruby e il copilota; va solo
  detto nella schermata («Scarico il riconoscimento dell'italiano da Apple») e confermato (**Decisione 8**).
- **Testo dei clienti sull'iPhone anche senza «Prisma ovunque»**: la coda «Note in partenza» tiene sul telefono testo
  dettato che parla di un cliente. Cifrato con la chiave del Portachiavi `ThisDeviceOnly`, con protezione dei file
  (`FileProtectionType.completeUntilFirstUserAuthentication`) e **escluso dal backup dell'iPhone su iCloud**
  (`URLResourceValues.isExcludedFromBackup = true`, altrimenti finirebbe nei backup di iCloud, anche se cifrato); tolto
  dalla coda appena il Mac risponde `accettata`. **Decisione 9**: va bene (proposta) oppure la nota si detta solo con il
  Mac raggiungibile.
- **Archivio e backup**: `noteInArrivo` entra nell'archivio e nel backup; aggiornare l'elenco del backup di CLAUDE.md.
- Nessuna dipendenza esterna. Nessuna API sopra macOS 13 sul Mac. Sull'iPhone le API nuove del riconoscimento restano
  protette come oggi in `Ruby/TrascrizioneRuby.swift`: `#if canImport(FoundationModels)` (la guardia di compilazione usata
  oggi al posto di `#if compiler(>=6.2)`) più `if #available(macOS 26.0, iOS 26.0, *)`, con il ripiego su
  `TrascrizioneClassica`. La Quick Action (`UIApplicationShortcutItem`) è da iOS 13, sotto il minimo dell'iPhone.

---

### 6.3 Chilometri, spese e scadenze

Una scheda nuova di Studio per le cose del consulente come professionista: i chilometri fatti per i clienti, le spese
con gli scontrini, le scadenze fiscali e professionali, e il pacchetto da dare al commercialista.

#### 6.3.1 Cosa si vede

**1.1 Come ci si arriva**
- **Studio**, segmentato della testata: le schede diventano **«Cruscotto · Parcelle · Track record · OCF · Palestra ·
  Spese»** (riga 2085; «Parcelle e fatture» ed «Esame OCF» si accorciano, parte comune §2); valore `spese`.
- Pannello Novità, gruppo «Per il tuo lavoro», voce 14: **«Chilometri, spese e scadenze»** / **«Per te e per il
  commercialista»**, glifo `auto` su #5A6873 (`NOVL[13]`, riga 2066): `vaiA('studio', tabS='spese')`.
- A sinistra del segmentato resta **«▶︎ Il tuo anno»** (apre la storia dell'anno, altra novità; righe 2085, 2087).

**1.2 La griglia** (riga 2051): tre colonne **1,1fr · 1fr · 1fr**, spazio 14, alte quanto l'area (schermata: 486 ·
442 · 442 circa su 1384). Tre card `.card .st` con padding 20×22 e **senza ombra** (`box-shadow:none`, diversamente
dal Cruscotto). Non si inclinano.

**1.3 Card 1 — «I CHILOMETRI DI OTTOBRE»** (righe 2052-2054)
- Riga: `.lbl` **«I chilometri di ottobre»** e a destra `.k` **«dal Territorio, da soli»**.
- Numero grande `.bignum` a **50** pt **«412»** (si conta, intero) e **«km»** 18, 600, 6 sopra la base; 8 sotto la riga.
- `.k` **«22 visite · 14 clienti»**.
- Elenco dei giri (14 sotto): righe con padding 9, filo sotto, 13,5, spazio 12: data in grassetto larga 44 («3 ott»),
  clienti visitati («Giulia Rossi · Laura Moretti»), km in grassetto a destra («28 km»). Cinque righe, poi `.k`
  **«+ altre 17 visite»** (8 sopra).
  | Data | Clienti | km |
  |---|---|---|
  | 3 ott | Giulia Rossi · Laura Moretti | 28 |
  | 8 ott | Marco Bianchi | 41 |
  | 14 ott | Sofia Romano · Federico Galli | 36 |
  | 21 ott | Andrea Conti | 22 |
  | 28 ott | Chiara Marino · Paolo Leone | 47 |
- `.lbl` **«Chilometri per mese»** (22 sopra), poi 10 colonne in un'area alta 110 (spazio 8, 10 sopra): altezza
  v/412·86, raggio 5 5 2 2, colore `--track` tranne l'ultima (il mese mostrato) in `--accent`; sotto l'iniziale del mese
  10,5 `.k` («G F M A M G L A S O»). Valori: 288, 342, 365, 301, 398, 356, 190, 120, 377, 412. Niente assi né valori.
- Nota: è un **giro** di una giornata (più clienti nello stesso giorno), non una visita. **Secondo difetto del template**:
  i 5 giri mostrati contano **8 visite** (tre giri hanno due clienti), quindi delle 22 visite ne restano **14**, non
  «+ altre 17» (il template conta i giri come visite). Nell'app la riga dice il numero vero: «+ altre ‹N› visite» o, se
  si elencano giri, «+ altri ‹N› giri».

**1.4 Card 2 — «LE SPESE»** (righe 2055-2056)
- Riga: `.lbl` **«Le spese»** e a destra il pulsante **«◎ Inquadra lo scontrino»** (`.btn`, padding 5×11).
- `.v` **«386 €»** (si conta), 10 sopra; `.k` **«a ottobre, con gli scontrini»**.
- Elenco (12 sopra): righe con padding 9, filo, 13,5, spazio 10: miniatura dello scontrino 26×32 (raggio 4, `--chip`,
  bordo `--sep`), descrizione con sotto la data `.k` 12, importo in grassetto a destra.
  | Voce | Data | Importo |
  |---|---|---|
  | Carburante | 2 ott | 92,40 € |
  | Pranzo con cliente | 8 ott | 48,00 € |
  | Parcheggio | 14 ott | 6,50 € |
  | Cancelleria | 17 ott | 31,90 € |
  | Corso di aggiornamento | 24 ott | 180,00 € |
- **Difetto del template**: le cinque voci sommano **358,80 €**, il totale dice 386 €; e dopo «Inquadra lo scontrino» il
  totale non cambia. Nell'app il totale è la **somma vera** delle spese del mese, e si aggiorna.
- «Inquadra lo scontrino» (template, riga 2060): in cima all'elenco compare una riga evidenziata (fondo
  rgba(0,122,255,.08), raggio 8) **«Pranzo con cliente» / «oggi · letto dallo scontrino» / «36,00 €»**.

**1.5 Card 3 — «LE TUE SCADENZE»** (righe 2057-2059; colonna con il pulsante in fondo)
- `.lbl` **«Le tue scadenze»**, poi quattro righe (padding 10, filo, spazio 12): blocco data largo 44 centrato con il
  mese in maiuscolo 10, 700, nel colore della scadenza, e il giorno 20, 600; a destra titolo grassetto 14 e riga `.k` 12.
  | Data | Titolo | Riga | Colore |
  |---|---|---|---|
  | 16 nov | F24 del mese | come impostato con il commercialista | #E08A00 |
  | 30 nov | Acconto delle imposte | importo dal commercialista | #E08A00 |
  | 31 dic | Polizza RC professionale | rinnovo da confermare | #0A84FF |
  | 31 dic | Aggiornamento professionale | 22 ore su 30 | #8B5CF6 |
- Sotto (12 sopra, spazio 14): anello da 70 spessore 8, viola #8B5CF6 al 73%, con al centro **«22/30»** 13, 700; a destra
  `.k` 12,5 interlinea 1,45 **«Ore di aggiornamento IVASS dell'anno. Gli attestati sono nei Documenti.»**
- In fondo (`margin-top:auto`) il pulsante principale grande, largo quanto la card, **«Prepara il pacchetto per il
  commercialista»**; sotto lo spazio dello stato (`#spS`).
- Dopo il clic (riga 2061): una barra `.bar8` (alta 8) che si riempie in 1,4 s, poi una tile con bordo verde
  rgba(47,163,90,.4): **«✓ Ottobre-2026.zip»** verde grassetto e `.k` **«chilometri, spese e 6 scontrini, in CSV e PDF»**.

**1.6 Il mese.** Il template (oggi 2 novembre) mostra **ottobre**: il mese chiuso. Proposta: nei primi 10 giorni del mese
Studio › Spese mostra il mese precedente (quello da chiudere col commercialista), poi il mese in corso; un selettore
del mese (frecce ‹ › accanto all'occhiello «I chilometri di …») permette di cambiare. Tutte e tre le card seguono il
mese scelto, tranne le scadenze, che guardano **avanti** da oggi (prossime 4, entro 90 giorni).

**1.7 Stati (proposta)**
- **Nessun chilometro**: «Nessuna visita con i chilometri a ottobre.» e, se manca il punto di partenza, il pulsante
  «Imposta da dove parti» (Impostazioni › Studio).
- **Visite senza km** (cliente senza distanza): la riga mostra «— km» e in fondo `.k` arancio «3 visite senza
  chilometri: aggiungili» (il totale dice «almeno 412 km»).
- **Nessuna spesa**: «Nessuna spesa a ottobre. Inquadra uno scontrino o aggiungila a mano.» con «+ Aggiungi».
- **Scontrino letto ma incerto** (importo o data non trovati): la riga è evidenziata in arancio «da controllare».
- **Nessuna scadenza**: «Aggiungi le tue scadenze: F24, acconti, polizza RC, aggiornamento.» con «+ Aggiungi» (niente
  scadenze inventate).
- **Ore di aggiornamento senza obiettivo**: niente anello, «Imposta le ore richieste per l'anno».
- **Pacchetto**: in preparazione (barra), pronto (tile con «Mostra nel Finder»), errore («Il pacchetto non è stato
  creato: …»).
- **Modalità cliente**: la scheda Spese non si vede (contiene i nomi di altri clienti e dati personali del consulente).

#### 6.3.2 Misure e stile

**2.1 Esistenti**
- Card `Superficie.card` (raggio 22) **senza ombra** → `Tema.Apple.Studio.Card` ha già la superficie; serve
  `Studio.Spese.senzaOmbra = true` (o una `Superficie.cardPiatta`, che esiste per la trascrizione del copilota:
  `Tema.Apple.Copilota.Trascrizione.superficie = Superficie.cardPiatta`).
- `Carattere.etichetta` (`.lbl`), `.valore` (26, `.v`), `Colore.inchiostro2` (`.k`), `separatore`, `binario`
  (`--track`), `accento`, `chip`, `arancio`, `stima` (#8B5CF6), `Colore.Area.investimenti` (#0A84FF), `verde`.
- `NumeroCheConta`, `BarraPiena` (`GraficiApple.swift:28`, per la barra del pacchetto), `AnelliConcentrici` con una voce.
- `SegmentatoPillola` con sei voci (parte comune).
- Colonne: `ColonneIncassiStudio` (`Shell/StudioGrafici.swift:16`) è a due parti impilate; qui una sola serie: estrarre
  una `ColonneSemplici` o dare a quella un caso a una parte.

**2.2 Token nuovi: `Tema.Apple.Studio.Spese`** (in `Tema.Apple+Studio.swift`, accanto a `Ricavi`, `Obiettivi`…)

| Nome proposto | Valore | Da |
|---|---|---|
| `Spese.Disposizione.quote` | [1.1, 1, 1] | 2051 |
| `Spese.Disposizione.spazio` | 14 (il Cruscotto usa 16) | 2051 |
| `Spese.Card.padding` | 20×22 (il Cruscotto 22×24) | 2052 |
| `Spese.Km.numero` | `Carattere(dimensione: 50, peso: .bold, tracking: -2.2, interlinea: 1, tabellare: true)` | 2052 |
| `Spese.Km.unita` | 18, 600; 6 sopra la base | 2052 |
| `Spese.Riga.testo` / `.padding` / `.spazio` | 13,5 / 9 / 12 (10 nelle spese) | 2053, 2056 |
| `Spese.Riga.data` | larga 44, grassetto | 2053 |
| `Spese.Colonne.altezza` / `.massima` / `.spazio` / `.raggioSopra` / `.raggioSotto` | 110 / 86 / 8 / 5 / 2 | 2054 |
| `Spese.Colonne.etichetta` | 10,5 `inchiostro2`, 4 sopra | 2054 |
| `Spese.Colonne.mese` / `.altri` | `accento` / `binario` | 2054 |
| `Spese.Scontrino.miniatura` / `.raggio` | 26×32 / 4 | 2056 |
| `Spese.Scontrino.nuovo` | rgba(0,122,255,.08) = `Colore.selezioneVoce` a .08 (esiste a .13: token nuovo `evidenzaNuovo`) | 2060 |
| `Spese.Scadenza.blocco` / `.mese` / `.giorno` | larga 44 / 10, 700 / 20, 600 | 2057 |
| `Spese.Scadenza.titolo` / `.riga` | 14 bold / 12 `inchiostro2` | 2057 |
| `Spese.Scadenza.fiscale` / `.polizza` / `.aggiornamento` / `.altra` | #E08A00 (`arancio`) / #0A84FF / #8B5CF6 (`stima`) / `inchiostro2` | 2057 |
| `Spese.Ore.anello` / `.spessore` / `.centro` | 70 / 8 / 13, 700 | 2058 |
| `Spese.Pacchetto.barra` | 8 di altezza (`BarraPiena` alta 8, raggio 9) | 2061 |
| `Spese.Pacchetto.bordoFatto` | rgba(47,163,90,.4) = `Colore.verde` al 40% | 2061 |

#### 6.3.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Card in cascata | `.st` (come Studio) | `entrataCascata(i, base: Moto.Cascata.baseDentroApp)` al cambio di scheda, `baseFinestra` all'apertura |
| Numeri (412, 386) | `conteggi`: 1,1 s + min(i,6)·60 ms | `NumeroCheConta`, `Moto.Numero` |
| Colonne dei km | scaleY 0→1 dal basso, 0,9 s, curva (.34,1.3,.64,1), ritardo 0,2 + i·0,05 s (2054, 2060) | `Tema.Apple.Studio.Spese.Moto.colonne = 0.90`, `ritardo = 0.20`, `passo = 0.05`, curva `Studio.Moto.curvaColonne` (esiste) |
| Anello delle ore | `accendi(wc,150)` dopo la rimonta: 1,4 s, `--out`, da 150 ms (320 all'apertura della finestra) | `Moto.Anello` (`ritardoCambio` 0,15 / `ritardoFinestra` 0,32) |
| Riga dello scontrino nuovo | da y −14 e scala 0,96, opacità 0, 500 ms, curva (.34,1.4,.64,1) (2060) | `Spese.Moto.scontrino = 0.50`, `spostamento = -14`, `scala = 0.96`, `Moto.Curva.molla` |
| Totale delle spese | — (non cambia) | `NumeroCheConta` dal vecchio al nuovo valore, `Moto.NumeroCambio` (0,9 s) |
| Barra del pacchetto | larghezza 0→100% in 1,4 s, curva (.4,0,.2,1), poi la tile | **la barra segue il lavoro vero** (righe scritte / totale) con `Moto.Barra`; la tile entra con dissolvenza e `Moto.Cascata` |
| Cambio di scheda | `rimonta`: 130 ms a scala 0,99, poi cascata | `Tema.Apple.Studio.Moto.durataRimonta`/`scalaRimonta` (esistono) |

- **Riduci movimento**: numeri completi, colonne alla misura, anello pieno, riga nuova e tile con la dissolvenza di 0,15 s.
  Nel template le colonne usano una transizione CSS che ignora `ridotto`: vale la regola di Prisma.
- **Istantanee**: tutto nello stato finale; nell'istantanea del pacchetto, la tile «pronto».

#### 6.3.4 Interazioni

**Mac**
- **Segmentato**: scheda `spese` (ricordata in `StatoShell` come le altre schede di Studio).
- **Riga di un giro** (clic): apre l'Agenda del giorno (`apri(.agenda)` con la data); al passaggio, fumetto con le visite
  e il percorso «Sede → Giulia Rossi → Laura Moretti → Sede · 28 km». Doppio clic sui km: correzione a mano
  (`kmCorretti`), con l'indicazione «corretto a mano».
- **«+ altre 17 visite»**: apre l'elenco completo del mese (foglio con tutte le visite e i km, esportabile).
- **Colonna di un mese**: sceglie quel mese per tutta la scheda.
- **«Inquadra lo scontrino»** sul Mac: non c'è fotocamera. Apre la scena di Inquadra (`StratoInquadra`) in modalità
  «scontrino»: si **trascina** la foto o il PDF dello scontrino, o si sceglie un file, o arriva dall'iPhone (vedi
  Decisioni). Prisma legge data, importo, esercente, IVA se c'è (Vision, `LetturaDocumenti`) e propone la spesa da
  confermare (categoria da scegliere). Anche **«+ Aggiungi»** a mano.
- **Riga di una spesa**: clic → dettaglio (scontrino ingrandito, campi modificabili, categoria, «legata al cliente»
  facoltativo, elimina). Trascinare un'immagine sulla card = inquadrare.
- **Scadenza**: clic → modifica (data, ricorrenza, nota, «fatto»); spunta per segnarla fatta (sparisce e nasce la
  prossima se ricorrente). «+ Aggiungi scadenza».
- **Anello delle ore**: clic → elenco dei corsi dell'anno con ore e attestato (apre il file).
- **«Prepara il pacchetto per il commercialista»**: chiede **dove salvarlo** (`NSSavePanel`, nome proposto
  «Ottobre-2026.zip»), poi crea lo zip; a fine lavoro «Mostra nel Finder». Niente invio: il file lo consegna l'utente.
- Tastiera: nessuna nuova (le schede di Studio seguono la parte comune).

**iPhone**: il template non lo mostra, ma «Inquadra lo scontrino» è naturale sull'iPhone (fotocamera). Proposta: in
Studio dell'iPhone (o come azione di «Inquadra») la modalità «scontrino»: legge sul telefono e manda al Mac **il testo
letto e i campi**, come Inquadra. L'**immagine** dello scontrino servirebbe al pacchetto: vedi Decisione 5.

#### 6.3.5 Mappa verso Prisma

**5.1 Esiste già (verificato con grep)**
- **Studio**: `Shell/StudioApp.swift` (`enum SchedaStudio { cruscotto, fatture, track, ocf }` riga 17, titoli 22-28,
  `AzioniStudio` 161, `AppStudio` 173), `Shell/StatoStudio.swift`, `Shell/StudioGrafici.swift`
  (`ColonneIncassiStudio`, `DispersioneClientiStudio`), `Shell/StudioImpostazioni.swift`,
  `Dati/ImpostazioniStudio.swift` (`ImpostazioniStudio`: `aliquote`, `obiettivi`, `fatturazione`),
  `DesignSystem/Apple/Tema.Apple+Studio.swift`, `Shell/IstantaneeStudio.swift`, `Dati/ProvaBackupStudio.swift`,
  `Motori/MotoreStudio.swift`, `Motori/ProvaCalcoliStudio.swift`.
- **Dati fiscali del consulente**: `DatiFatturazione` (`Dati/DatiFatturazione.swift`: nome, partita IVA, codice fiscale,
  sede, PEC, IBAN; `CodiceRegimeFiscale` con RF19 forfettario; `RegimeFatturazione`, riga 354). Il commento in testa
  (riga 4) dice già: «Prisma NON sceglie il regime fiscale, l'IVA…»: vale anche qui.
- **Visite**: `Appuntamento` (`inizio`, `durataMinuti`, `luogo: String`, `stato` `.concluso`, `tipo`, `clienteId`;
  `Dati/Modelli.swift:359`), `Cliente.indirizzo: String` (`Modelli.swift:47`). **Non c'è** nessuna coordinata né
  distanza.
- **Lettura di scontrini**: `Dati/LetturaDocumenti.swift` (Vision, foto e PDF, sul Mac e su iOS),
  `Motori/MotoreInquadra.swift` (oggi riconosce campi di polizza: `campiPosizione`), `Shell/ScenaInquadra.swift`
  (trascina una foto o un PDF sul Mac), `iOS/InquadraTelefono.swift` (fotocamera, testo al Mac).
- **Esportazione**: `Dati/ScrittoreZip.swift` (`ScrittoreZip`), `Motori/FoglioExcel.swift` (`FoglioExcel`),
  `Shell/StampaCarta.swift` (`StampaCarta.pdf`), e l'esempio dei file delle fatture (`Shell/StudioParcelleFile.swift`).
- **Ricorrenze e promemoria**: `Shell/PromemoriaMac.swift`; agenda mensile `AgendaMese.swift`.

**5.2 Cosa va creato**
1. `SchedaStudio.spese` (titolo «Spese»), vista `Shell/StudioSpese.swift` (tre card), stato `Shell/StatoSpese.swift`.
   Oggi `SchedaStudio` ha solo `cruscotto, fatture, track, ocf`: anche `palestra` è da creare, ma appartiene a un'altra
   novità (La palestra della trattativa); i titoli corti «Parcelle» e «OCF» sono della parte comune.
2. **Modelli** `Dati/SpeseStudio.swift`:
   - `struct SpesaStudio: Codable, Identifiable { id; data: Date; descrizione: String; esercente: String?; importo: Double;
     iva: Double?; categoria: CategoriaSpesa; pagamento: String?; clienteId: String?; scontrino: String? /* nome del
     file nella cartella Studio/Scontrini */; letta: Bool /* dallo scontrino */; daControllare: Bool; nota: String }`;
   - `enum CategoriaSpesa: String, Codable, CaseIterable { carburante, pedaggi, parcheggio, pasti, viaggio, cancelleria,
     telefono, formazione, abbonamenti, altro }` (proposta: nomi descrittivi, **nessuna percentuale di deducibilità**);
   - `struct ScadenzaStudio: Codable, Identifiable { id; titolo; data: Date; ricorrenza: Ricorrenza? /* mensile al giorno
     N, annuale */; tipo: TipoScadenza /* fiscale, polizza, aggiornamento, altra */; nota: String; fattaIl: Date? }`;
   - `struct CorsoAggiornamento: Codable, Identifiable { id; titolo; ente; data; ore: Double; attestato: String?; canale:
     Canale? }`;
   - `struct VisitaKm` (calcolata, non salvata): appuntamento, km, origine del dato (`.tabella`, `.manuale`, `.territorio`).
3. **Chilometri**: `Motori/MotoreChilometri.swift` (puro): i giri del mese = appuntamenti con `stato == .concluso`, un
   `clienteId` e `tipo != .telefonata` (`TipoAppuntamento`, `Dati/Modelli.swift:341`), raggruppati per giorno. **Attenzione**:
   `Appuntamento.luogo` è testo libero e oggi non dice se l'incontro era dal cliente o in studio; Prisma non deve
   indovinarlo dal testo. Proposta: campo nuovo facoltativo `Appuntamento.presso: LuogoIncontro? { cliente, studio, altro }`
   (nil = da chiedere: la visita va fra quelle «senza km» con «Dove eri?»); km del giro = somma delle distanze
   **date dall'utente** o dal Territorio (vedi Decisioni) secondo il percorso sede → visite in ordine d'orario → sede;
   correzioni manuali per giro (`kmCorretti[giorno]`) che vincono; totale del mese; serie dei 12 mesi; visite senza km.
4. **Spese**: lettura dello scontrino `Motori/LettoreScontrino.swift` (data, totale, esercente, partita IVA dell'esercente
   se stampata) sul testo di `LetturaDocumenti`; totale per mese e per categoria.
5. **Scadenze e ore**: elenco ordinato delle prossime; ricorrenze; ore dell'anno = somma dei corsi; obiettivo di ore
   dall'utente.
6. **Pacchetto** `Motori/PacchettoCommercialista.swift`: crea, fuori dal thread principale, uno zip (`ScrittoreZip`) con
   `chilometri-AAAA-MM.csv`, `spese-AAAA-MM.csv` (separatore `;`, decimali con la virgola, UTF-8 con BOM per Excel),
   `riepilogo-AAAA-MM.pdf` (carta bianca, `StampaCarta`, come i documenti PDF di Prisma) e la cartella `scontrini/`
   con i file. Nome «Ottobre-2026.zip». Nessun dato dei clienti oltre a quanto deciso (Decisione 3).
7. Pulsante «Inquadra lo scontrino» → `StratoInquadra` in modalità scontrino (`FaseInquadra` ha già le fasi; aggiungere il
   tipo di documento atteso).
8. `Tema.Apple.Studio.Spese` (§2.2).

**5.3 Campi nuovi dell'archivio** (versione di Luce; `decodeIfPresent`; backup e `--prova-backup`)
- `ImpostazioniStudio.spese: ImpostazioniSpese { partenza: String /* descrizione del punto di partenza, nessuna
  coordinata */; kmAndataRitornoPerCliente: [String: Double] /* clienteId → km sede-cliente-sede, dati dall'utente */;
  kmCorretti: [String: Double] /* "aaaa-mm-gg" → km del giro */; contaVisiteSenzaCliente: Bool; oreAggiornamentoAnno:
  [Int: Double] /* anno → ore richieste */; giornoCambioMese: Int = 10; nomiNelPacchetto: Bool = false }`.
- `DatiPrisma.spese: [SpesaStudio]`, `DatiPrisma.scadenzeStudio: [ScadenzaStudio]`, `DatiPrisma.corsi:
  [CorsoAggiornamento]`.
- File: `~/Library/Application Support/Prisma/Studio/Scontrini/` e `Studio/Attestati/`; nel backup come i documenti.
  Fuori dall'istantanea di «Prisma ovunque» (come i documenti).

**5.4 Prove**
- `Motori/ProvaCalcoliSpese.swift` (da `ProvaCalcoli.esegui()`): giro di due visite con distanze 14+14 e 18+18 → regole
  del percorso (con la tabella andata-ritorno per cliente: 28 e 36; da decidere se il giro sede→A→B→sede usa una tabella
  fra clienti); correzione manuale che vince; telefonate escluse; appuntamento pianificato escluso; visite senza km
  contate a parte; totale spese = somma (358,80 sui dati del template, **non** 386); mese mostrato il 2 novembre =
  ottobre, l'11 novembre = novembre; ricorrenza mensile al 16 → prossima dopo «fatta»; ore 22/30 → 73%.
- Lettore dello scontrino: tre testi finti (totale con «TOTALE EURO», data in formato gg/mm/aa, importo con virgola).
- Pacchetto: lo zip si rilegge con `LettoreZip` (esiste, `Dati/LettoreZip.swift`), CSV con le righe giuste, nessun nome di
  cliente con `nomiNelPacchetto == false`.
- `Prisma --prova-backup`: spese, scadenze, corsi, impostazioni e file degli scontrini vanno e tornano.

#### 6.3.6 Dati che l'utente deve dare (mai inventati) e stati vuoti
- **Chilometri**: il punto di partenza e, per ogni cliente, i km andata e ritorno (o il permesso a calcolarli col
  Territorio, Decisione 1). Senza: «— km». I km del template sono dimostrativi.
- **Rimborso o costo per km**: Prisma **non** mostra euro per i km (il template non lo fa); se l'utente lo vuole nel
  pacchetto, il valore €/km lo scrive lui (le tabelle ACI o gli accordi con Alleanza non si inventano).
- **Spese**: importi e date dagli scontrini o a mano; la **categoria** la sceglie l'utente (Prisma propone, non decide).
  **Deducibilità, IVA detraibile, percentuali** (pasti, auto, telefono): **non** le calcola Prisma; nel regime forfettario
  (RF19, già tra i codici di `DatiFatturazione`) le spese non si deducono una per una, in altri regimi sì con limiti:
  lo decide il commercialista. Il pacchetto riporta solo i fatti.
- **Scadenze**: tutte dall'utente (o dal commercialista): date, ricorrenze, importi («importo dal commercialista»).
  Prisma **non** contiene un calendario fiscale; proposta (Decisione 4): un elenco di **promemoria suggeriti** («F24 il 16
  di ogni mese», «acconto di novembre») che l'utente accende uno per uno, con la frase «verifica le date con il tuo
  commercialista».
- **Aggiornamento professionale**: le ore richieste per l'anno e i corsi con ore e attestato li dà l'utente. Il template
  scrive «IVASS» e 30 ore: il requisito (IVASS per l'intermediazione assicurativa, OCF per la consulenza finanziaria,
  ognuno con le sue regole e periodi) **non** va scritto nel codice come numero fisso; l'utente imposta il suo obiettivo,
  e la riga dice «Ore di aggiornamento dell'anno» con l'ente scelto dall'utente.
- **Polizza RC professionale**: data di scadenza e compagnia dall'utente.
- **Attestati**: «Gli attestati sono nei Documenti» — oggi i `Documento` sono **del cliente** (`clienteId`): gli attestati
  vanno nella cartella `Studio/Attestati` legata ai corsi, non nei Documenti dei clienti. Il testo diventa «Gli attestati
  sono nei tuoi corsi».
- Stati vuoti: §1.7.

#### 6.3.7 Istantanee da aggiungere (Mac, in `Shell/IstantaneeStudio.swift`, chiaro e scuro)

| Nome | Cosa |
|---|---|
| `780-studio-spese` / `-scuro` | la scheda con i dati di prova (con il totale vero delle spese) |
| `781-studio-spese-vuoto` / `-scuro` | nessun km, nessuna spesa, nessuna scadenza: i tre stati vuoti con i pulsanti |
| `782-studio-spese-km-mancanti` | visite senza km: «almeno … km» e la riga arancio |
| `783-studio-spese-scontrino-nuovo` | dopo l'inquadratura: riga evidenziata in cima e totale aggiornato |
| `784-studio-spese-scontrino-da-controllare` | scontrino letto senza importo: riga arancio |
| `785-studio-spese-pacchetto` / `-scuro` | tile «✓ Ottobre-2026.zip» |
| `786-studio-spese-dettaglio-spesa` | dettaglio di una spesa con lo scontrino |
| `787-impostazioni-studio-spese` | Impostazioni › Studio: partenza, km per cliente, ore di aggiornamento, nomi nel pacchetto |
| `788-studio-spese-stretta` | finestra stretta: le tre card in colonna |
| `789-inquadra-scontrino-iphone` | iPhone, se si sceglie (Decisione 5): scontrino inquadrato e campi letti |

#### 6.3.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente
- **Mappe e geocodifica** (dati in locale): «dal Territorio, da soli» vuol dire calcolare i km dagli indirizzi dei clienti.
  Con MapKit (`CLGeocoder`, `MKDirections`) gli **indirizzi dei clienti vanno ai server di Apple**: esce un dato personale
  del cliente dal Mac. **Decisione 1**: (a) km dati dall'utente una volta per cliente (andata e ritorno) e corretti per
  giro (proposta, nessuna rete); (b) geocodifica e percorsi Apple con un interruttore spento di base, come Mercato, e solo
  sull'indirizzo (mai il nome); (c) mappe offline (dipendenza esterna, da chiedere). Va deciso insieme a Territorio
  (stessa domanda per la mappa dei clienti).
- **File dato al commercialista** (esce dal Mac per mano dell'utente): lo zip contiene i km con le date e, nel template,
  **i nomi dei clienti visitati** («Giulia Rossi · Laura Moretti»). **Decisione 3**: nel pacchetto (a) nessun nome
  (solo data, km, numero di visite: proposta, `nomiNelPacchetto = false`), (b) le iniziali, (c) i nomi. Le spese «Pranzo
  con cliente» non portano il nome se non lo scrive l'utente.
- **Fotocamera e immagini sul ponte**: oggi il ponte porta **solo testo** (regola scritta in `MessaggiPonte.swift`).
  Lo scontrino serve come **immagine** nel pacchetto. **Decisione 5**: (a) sull'iPhone si legge il testo e al Mac va solo
  il testo (lo scontrino vero si conserva a parte: l'utente lo fotografa e lo trascina sul Mac); (b) eccezione: l'immagine
  di uno scontrino (dato del consulente, non del cliente) può passare sul ponte cifrato, con un limite di dimensione;
  (c) niente iPhone, solo trascinamento sul Mac (proposta per questo giro); (d) la **Fotocamera Continuity** di macOS
  (voce «Importa da iPhone o iPad › Scatta foto/Scansiona documenti», `NSServicesMenuRequestor`, macOS 13): la foto
  arriva dall'iPhone al Mac con un servizio di Apple, senza il ponte e senza Prisma sull'iPhone; è un servizio Apple
  (Bluetooth/Wi-Fi e stesso Apple Account) da approvare come tale.
- **Testi e dati fiscali che non si possono inventare**: date e importi di F24 e acconti, percentuali di deducibilità,
  detraibilità IVA, costo chilometrico, requisito di ore IVASS/OCF, scadenza della RC professionale. **Decisione 4**:
  calendario solo dall'utente (proposta) o promemoria suggeriti da accendere uno per uno, con la frase di verifica col
  commercialista. Il canale (Alleanza / indipendente) di una spesa o di un corso: **Decisione 6** se le spese vanno divise
  per canale (il consulente lavora per Alleanza e come indipendente: il commercialista può volerle separate); proposta:
  campo `canale` facoltativo, con l'etichetta del canale nel dettaglio.
- **Privacy della scheda**: dati personali del consulente (spese, scadenze) e nomi dei clienti: niente modalità cliente,
  niente Ruby di default (Ruby può leggere i totali solo se l'utente lo chiede in modalità lavoro).
- **Notifiche delle scadenze** sul Mac (`PromemoriaMac`): proposta sì, 3 giorni prima, spente per le ricorrenti mensili
  se l'utente lo sceglie. Nessuna notifica a terzi.
- **Salvataggio del pacchetto**: `NSSavePanel` (macOS 13 ok). Nessun invio diretto (mail, WhatsApp, cloud): se si volesse
  «Manda al commercialista», sarebbe un invio a terzi da approvare.
- **Archivio e backup**: spese, scadenze, corsi, impostazioni e i file `Studio/Scontrini` e `Studio/Attestati` entrano nel
  backup; aggiornare l'elenco del backup di CLAUDE.md (oggi non cita i dati dello Studio del consulente).
- Nessuna dipendenza esterna (zip, CSV, PDF e Vision ci sono già). Nessuna API sopra macOS 13.

---

## 7. App Pratiche: proposta, moduli, dopo la firma, sinistri

*Parte 07 · le quattro novità «per il lavoro» della nuova app Pratiche (voci 2-5 di `NOVL`)*

Fonte: `Design/template-luce.html` (5 novembre 2026). Le righe citate sono di quel file:
- stato e dati dimostrativi: `tabP`, `bisI`, `modI`, `modC`, `sinI` (1831); `BIS` (1832-1835); `MODULI` (1836); `ANAG`
  (1837); `CAMPI` (1838); `PRAT` (1839-1842); `PASSI` (1843); `SIN` (1844-1846); `FASI` (1847);
- l'app: `APPS.pratiche` (1848-1850); `pratHTML()` con i rami `proposta` (1852-1855), `moduli` (1856-1860), `dopo`
  (1861-1864) e `sinistri` (1865-1874); `moduloHTML()` (1875-1878); `montaPrat()` (1879-1884); `costruisci()`
  (1885-1894); `compila()` (1895-1902);
- CSS proprio: 297-317 (`.stg`, `.stN`, `.miniPg`, `.fGrid`, `.fld`, `.trkS`, `.trk`, `.tBar`, `.tN`); CSS comune usato:
  `.side`/`.main`/`.rub` 120-125, `.tile` 127, `.prep` 130-133, `.paper` 187-195, `.chip` 201-202 e `.on3` 286,
  `.phone` 204-206, `@keyframes respira` 76;
- utilità: `entrata` 383, `conteggi` 382, `anello` 392-395, `accendi` 396, `linee` 399, `toast` 401, `rimonta` 845,
  `vaiA` 846, `scrive` 1794, `ridotto` 377;
- arrivi: `NOVL` (2064: voci «La proposta si costruisce da sola», «Compila da solo», «Le pratiche dopo la firma», «Il
  sinistro come una spedizione»); dock `DOCK` (475, `['pratiche','Pratiche','Pratiche']` tra Messaggi e Prospetti);
  lo smontaggio di Posizioni (`#smProp`, 1972 e 1976: «Crea la proposta di sostituzione» apre Pratiche › Proposta sul
  quarto bisogno); la carta 5 di «Stanotte» (`NOTTE`, 1801: «I moduli della proposta casa sono compilati»);
- icona `Pratiche` nel `<template id="sorgenti-icone">` (2205 e seguenti).

Schermate di riferimento (1480×940, palco 1440×900 scalato di 1,0137; script `luce/script/shot07.js`), in
`luce/img/`: `07-proposta-{chiaro,scuro}.png` (scheda appena aperta), `07-proposta-costruisce-*.png` (a metà della
costruzione), `07-proposta-pronta-*.png`, `07-moduli-*.png`, `07-moduli-compila-*.png` (a metà), `07-moduli-fatto-*.png`,
`07-moduli-iban-*.png` («Lo scrivo io»), `07-dopo-*.png`, `07-sinistri-*.png` (Tommaso, perizia),
`07-sinistri-pagato-*.png` (Sofia, pagato). Le testate dell'app in `01-c-pratiche.png` / `01-s-pratiche.png` (parte
comune).

Per tutto ciò che qui non è detto vale la parte comune di Luce (`01-comune.md`: casi nuovi di `AppPrisma`, dock, icona,
tasselli con glifo `TasselloGlifo`/`GlifoLuce`, telefono disegnato `TelefonoDisegnato`, testo che si scrive
`TestoProgressivo`) e, sotto, la specifica di Orizzonte (`Design/template-novita-specifica.md`) e quella del tema Apple
(`Design/template-apple-specifica.md`).

**Le cifre, i nomi, i moduli e i testi del template sono dimostrativi.** I moduli del template sono **fac-simile** scritti
apposta (lo dice il piede di `moduloHTML`, 1878): i moduli veri (proposta di polizza, informativa privacy, mandato,
questionario di adeguatezza, adeguata verifica antiriciclaggio) **li carica l'utente**. Dove un dato manca Prisma lo dice
(§N.6), mai un numero o un testo inventato.

**Numeri delle istantanee.** In `Sources/` oggi la serie più alta è 613; la parte comune di Luce usa 620-629, la Sala
630-668, la relazione 700-736, notte/voce/spese 760-789. Qui propongo **800-809** (Proposta), **810-819** (Moduli),
**820-829** (Dopo la firma), **830-839** (Sinistri), da riconciliare nella tabella finale come in Orizzonte §0.5.
**Attenzione, collisione:** la parte 08 (Biblioteca e analisi) propone anch'essa **800-807, 810-816 e 820-827**, e la
parte 09 scrive «800-836 (Pratiche, Biblioteca, analisi)» come se fossero una serie sola. Nella tabella finale una delle
due parti va spostata (proposta: Pratiche resta 800-839, Biblioteca e analisi vanno in una serie libera, per esempio
870-899, dopo le 840-869 della parte 09). Le istantanee iOS di questa parte seguono lo stile di `IstantaneeMobile.swift`
(«609-inquadra-iphone»): `824-pratiche-iphone`, `836-sinistri-iphone`.

**Archivio.** Oggi `DatiPrisma.versioneAttuale = 26` (`Dati/DatiPrisma.swift:113`). I campi nuovi di questa parte entrano
nella versione unica di Luce (27, da decidere una volta sola con le altre parti), tutti facoltativi, letti con
`decodeIfPresent` e con elenchi tolleranti (`ElencoTollerante`, `Dati/ElencoTollerante.swift`), nel backup e in
`Prisma --prova-backup` (nuova `Dati/ProvaBackupPratiche.swift`, come `ProvaBackupParcelle.swift`).

---

### 7.0 Parte comune dell'app Pratiche

#### 7.0.1 Cosa si vede
- Finestra interna standard (come Studio): icona `Pratiche` nella barra del titolo e la parola **«Pratiche»**;
  intestazione h1 **«Le pratiche.»** e occhiello `.sub` **«DALLA PROPOSTA AL SINISTRO»** (sorgente «Dalla proposta al
  sinistro», maiuscolo dal CSS; 1848).
- A destra (`#wAct`) il segmentato `.seg` con quattro voci: **«Proposta» · «Moduli» · «Dopo la firma» · «Sinistri»**
  (valori `proposta`, `moduli`, `dopo`, `sinistri`; 1849). Si apre su Proposta (`tabP='proposta'`, 1831).
- Area dei contenuti `#wc` come Studio (1384×654 nel palco). Tre schede su quattro usano lo schema **barra laterale +
  colonna principale**: `.side` a sinistra (larga 300, o 290 in Moduli), `.main` a 16 dalla barra (`left:316`/`306`).
  «Dopo la firma» usa tutta la larghezza.
- Arrivi: dock (icona Pratiche, tra Messaggi e Prospetti); pannello «✦ Novità», gruppo «Per il tuo lavoro», voci 2-5
  (`vaiA('pratiche',()=>{tabP=…})`); smontaggio di Posizioni («Crea la proposta di sostituzione»); carta «Moduli» di
  Stanotte (parte 06: «Apri ›» porta qui).

#### 7.0.2 Misure e stile
- Finestra, intestazione, segmentato: come Studio (`SegmentatoPillola`, `ControlliApple.swift:19`).
- Barra laterale `.side` (120): raggio 20 (`Raggio.pannello`), fondo `--panel` (`Colore.pannello`), bordo 1 `--sep`,
  padding 14/12 (`Misura.Padding.barraLaterale`). Titolo `.lbl` con 8 sotto.
- Voce della barra `.rub` (122-125): padding 10 (il template sovrascrive i 9/8), raggio 14 (`Raggio.voce`), spazio 10;
  selezionata `rgba(0,122,255,.13)` (`Colore.selezioneVoce`); titolo `b` 14 grassetto; riga sotto `small` 12 `--ink2`
  (nel ramo Proposta va a capo, larga al più 200). Esiste `VoceRubricaApple` (`Shell/DossierApple.swift:227`): va
  generalizzata (avatar o tassello a sinistra, titolo, sottotitolo su una o più righe).
- File di token nuovo: **`DesignSystem/Apple/Tema.Apple+Pratiche.swift`** con `enum Tema.Apple.Pratiche` e i
  sottospazi `Proposta`, `Moduli`, `Passi`, `Spedizione`, `TelefonoCliente`, `Moto` (dettagli nelle sezioni). Larghezze:
  `laterale = 300`, `lateraleModuli = 290`, `spazioLaterale = 16`.

#### 7.0.3 Movimento
- Cambio di scheda: `rimonta` (845): uscita 130 ms a scala 0,99, poi cascata `.st` (`entrata`, 383: 720 ms da
  translateY 18, scala 0,985, sfocatura 6; passo 48 ms, base 0 dentro l'app). In Prisma: `Tema.Apple.Studio.Moto.uscitaRimonta`
  (esiste; proposta: spostarlo in un `Tema.Apple.Moto.Rimonta` comune) + `entrataCascata(_:base:)`
  (`CascataApple.swift:28`) con `Moto.Cascata.baseDentroApp`.
- Cambio di voce nella barra laterale: nel template **rimonta tutta la scheda** (1880-1883). Proposta per l'app: cambia
  solo la colonna principale con `Moto.CambioCliente` (esiste).

#### 7.0.4 Interazioni
- Segmentato: cambia scheda; la scheda va in **`StatoShell.schedaPratiche: SchedaPratiche`** (come `schedaStudio`,
  `Shell/StatoShell.swift:96`), così Novità, smontaggio e Stanotte aprono la scheda giusta con `StatoShell.apri(_:)`.
  `enum SchedaPratiche: String, CaseIterable { proposta, moduli, dopoLaFirma, sinistri }` (nome della parte comune).
- Contesto d'apertura: `StatoShell.preparaPratiche(scheda:clienteId:bisognoId:modelloId:praticaId:sinistroId:)`
  (proposta), sul modello di `preparaMessaggio` (`Shell/CollegamentiMessaggi.swift`): una richiesta presa una volta sola
  dall'app (`prendiRichiestaPratiche()`).
- Tastiera (proposta, come Studio §2.4): ⌘1…⌘4 per le schede se non urtano `ComandiShell.swift`; ↑↓ nella barra
  laterale.
- **Modalità cliente**: la parte comune propone Pratiche **riservata** (`appRiservate` in `Shell/ModoCliente.swift:8`),
  perché elenca bisogni, pratiche e sinistri di più clienti. Qui si conferma: il cliente vede solo ciò che il consulente
  gli mostra dalla Sala o dal Tavolo.

#### 7.0.5 Mappa verso Prisma (comune)
- `AppPrisma.pratiche` (parte comune), vista `Shell/AppPratiche.swift` con le quattro schede in file propri:
  `Shell/PraticheProposta.swift`, `Shell/PraticheModuli.swift`, `Shell/PraticheDopoFirma.swift`,
  `Shell/PraticheSinistri.swift`; stato `Shell/StatoPratiche.swift` (estensione di `StatoShell`, come
  `Shell/StatoStudio.swift`); cache dei motori `CachePratiche` (come `CacheMotoriPosizioni`) ricalcolata solo quando
  cambiano posizioni, schede di adeguatezza, documenti, pratiche o sinistri.
- Modelli nuovi (§1.5, §2.5, §3.5, §4.5): `ModelloModulo`, `CompilazioneModulo`, `Pratica`, `Sinistro`, e i campi
  anagrafici che mancano (§2.5).

#### 7.0.6 Stati comuni
- Archivio senza clienti: ogni scheda mostra al centro il tassello del suo glifo (`proposta`, `modulo`, `cartella`,
  `sinistro`), una frase e il pulsante giusto (dettagli in §N.6).
- **Dati di prova**: con i 5 clienti del template e i 30 fittizi, `DatiDemo`/`ClientiFittizi` caricano anche modelli di
  modulo **fac-simile** (generati da Prisma, con la scritta «FAC-SIMILE»), pratiche e sinistri di prova, con l'etichetta
  «dati di prova» accanto al titolo di ogni scheda. Non finiscono mai nell'archivio reale (Orizzonte §0.3).

#### 7.0.7 Istantanee comuni
- `800-pratiche-vuota` / `-scuro`: archivio senza clienti, scheda Proposta con lo stato vuoto.

#### 7.0.8 Regole e decisioni comuni
- **D-P0 · Pratiche riservata in modalità cliente**: proposta sì (vedi parte comune).
- **D-P1 · Dati sanitari.** Questionario sanitario (BIS[0], 1832) e sinistri da infortunio (referti, visite mediche) sono
  **dati relativi alla salute** (categorie particolari, art. 9 GDPR). L'archivio di Prisma oggi è JSON in chiaro su disco
  (`Archivio`), protetto da FileVault e dai backup cifrati se l'utente mette la password. Proposta: i testi sanitari dei
  sinistri restano brevi e generici (fase, documenti ricevuti, date), mai il contenuto dei referti; i referti come file
  stanno nei Documenti del cliente come ogni altro documento. Da confermare con l'utente (e, se vuole, con il suo DPO o la
  compagnia).

---

### 7.1 La proposta si costruisce da sola

*Voce 2 di `NOVL`: «La proposta si costruisce da sola» · «Dal bisogno alla proposta in un minuto», glifo `proposta`,
tassello #3E7D69, `vaiA('pratiche',()=>{tabP='proposta'})` (2064).*

#### 7.1.1 Cosa si vede
Schermate `07-proposta-*.png`, `07-proposta-costruisce-*.png`, `07-proposta-pronta-*.png`.

**Barra laterale** (`.side` larga 300, 1852): titolo `.lbl` **«BISOGNI SCOPERTI DALL'ANALISI»** e una voce `.rub` per
bisogno, padding 10, allineata in alto: avatar 36 del cliente, titolo in grassetto (es. **«La protezione di Elena»**) e
sotto la frase del motivo su più righe (larga al più 200), es. «Reddito di 1.900 € al mese senza nessuna copertura.».
Nel template quattro bisogni (`BIS`, 1832-1835): la protezione di Elena (cliente Marco), la pensione integrativa di
Giulia, la pensione a 60 anni di Laura, «Il fondo di Giulia, con costi più bassi» (sostituzione). Il primo è selezionato.

**Colonna principale** (`left:316`, 1853-1855):
- **Testata** (`.row.st`, spazio 12): avatar 46; sopra `.k` **«Per Marco Bianchi»** (il cliente del dossier, non la
  persona del bisogno: Elena è la moglie di Marco), sotto il titolo del bisogno in display 24 grassetto, spaziatura −0,5;
  a destra (`margin-left:auto`) il pulsante primario grande **«✦ Costruisci la proposta»**.
- **La linea dei cinque passi** (`#pcLine`, 22 sotto la testata, flex con spazio 16): cinque riquadri uguali `.stg`
  (altezza 320) con, in alto a sinistra, il numero in un tondo (1-5) e l'etichetta `.lbl`:
  **«IL PRODOTTO» · «L'IMPORTO» · «IL PROSPETTO» · «L'ADEGUATEZZA» · «I MODULI»**. Da spenti sono **tratteggiati**
  (bordo 1,5 `--ink3`), vuoti, all'opacità 0,7.
- **`#pcEnd`** vuoto, 20 sotto la linea.

**Mentre costruisce** (`costruisci`, 1885-1894): il pulsante si spegne e dice **«Costruisco…»**; i riquadri si accendono
uno dopo l'altro (diventano card piene `--cardE` con bordo `--sep` e ombra; il tondo del numero diventa verde con la cifra
bianca e cresce a 1,1) e si riempiono:
1. **Il prodotto**: tassello `proposta` 40 (#3E7D69); il nome del prodotto in display 19 grassetto, interlinea 1,2 (es.
   «Temporanea caso morte»); sotto l'etichetta del canale (`canali(b.ch)`: «Alleanza» blu o «Indipendente» cuoio).
2. **L'importo**: numero display 30 grassetto, spaziatura −0,8, che si conta da 0 (es. **«300.000 €»**; per Giulia
   «420 €»); sotto `.k` la spiegazione («capitale per 20 anni», «al mese, deducibili», «al mese per 11 anni», «trasferiti
   dal fondo attuale»); sotto ancora, 13 semigrassetto, 10 di spazio, il premio o la cifra di contorno («circa 31 € al
   mese», «fino a 5.164,57 € l'anno di deduzione», «costo medio 0,9% l'anno», «costi da 2.410 a 760 € l'anno»).
3. **Il prospetto**: miniatura di pagina bianca `.miniPg` (150 di larghezza, raggio 6, padding 12, ombra) con quattro
   righe grigie (larghe 60%, 85%, 70%, 45%) e in mezzo una linea blu #0A84FF che sale e **si disegna**; sotto `.k`
   **«4 pagine · su carta bianca»**.
4. **L'adeguatezza**: anello pieno verde (#30B15C, misura 100, spessore 11) con al centro **«✓»** verde 30; sotto
   **«Adeguata»** (13 semigrassetto) e `.k` 12 «coerente con profilo, obiettivo e orizzonte».
5. **I moduli**: elenco `.prep` (pallino 20 con la spunta) dei moduli del prodotto, ognuno col nome (13) e sotto `.k`
   11,5 **«18 campi compilati»**; le spunte diventano verdi una dopo l'altra (moduli di `BIS[i].moduli`: per Elena
   «Proposta di polizza · 18», «Informativa privacy · 6», «Questionario sanitario · 22»).

**Alla fine** (1,1 s dopo il quinto riquadro) in `#pcEnd` entra un **riquadro verde** (`.tile` con bordo
rgba(47,163,90,.4) e fondo rgba(47,163,90,.07), riga con spazio 18): «✓» verde 34; titolo display 22 grassetto
**«Proposta pronta in 52 secondi»**; sotto `.k` «Per Marco Bianchi: prodotto, importo, prospetto, adeguatezza e 3 moduli
compilati. Controlla e firma.»; a destra **«Presenta a Marco»** (primario grande) e **«Nel fascicolo»** (grande). Il
pulsante della testata diventa **«✓ Fatto»** (blu, attivo all'aspetto ma senza azione).

Stranezze del template da **non** copiare:
- «52 secondi» è scritto fisso: la costruzione dura in realtà circa 3,6 s di animazione (`t0` è calcolato e mai usato).
- Il numero dell'importo si ricava togliendo le non-cifre dal testo (`parseInt(b.imp.replace(/\D/g,''))`): con decimali
  sbaglierebbe.
- Il premio «circa 31 € al mese» è scritto a mano: Prisma non ha tariffe (vedi §1.6).

#### 7.1.2 Misure e stile
| Elemento | Template | Prisma |
|---|---|---|
| Barra laterale | 300, `.side`, voci `.rub` padding 10 allineate in alto | `Tema.Apple.Pratiche.laterale = 300`; `Misura.Padding.barraLaterale` |
| Avatar | 36 (barra), 46 (testata) | `AvatarCliente` (`DesignSystem/Componenti.swift:698`); `Misura.Avatar` (`TemaApple.swift:583`) ha 24, 30, 34, 38, 54, 56, 64, 70: servono **nuovi** `Pratiche.avatarVoce = 36`, `avatarTestata = 46`, `avatarPratica = 40`, `avatarChip = 22` (oppure riusare 34/38/54/24, da vedere sullo schermo) |
| «Per Marco Bianchi» | `.k` 12,5 `--ink2` | `Carattere.secondario`, `Colore.inchiostro2` |
| Titolo del bisogno | display 24, 700, −0,5 | **nuovo** `Tema.Apple.Pratiche.titolo = Carattere(dimensione: 24, peso: .bold, tracking: -0.5)` (fra `titoloGruppo` 22 e `nomeDossier` 27) |
| Pulsante | `.btn.pri.big`: padding 10/18, 13,5 semigrassetto, `--accent` | `StilePulsanteApple` primario grande (`PulsantiApple.swift:31`), `Misura.Padding.pulsanteGrande`, `Carattere.pulsanteGrande` |
| Linea dei passi | 22 sotto la testata, spazio 16, 5 colonne uguali | `Pratiche.Proposta.spazioPassi = 16`, `distanzaLinea = 22` |
| Riquadro spento `.stg` (297) | altezza 320, raggio 20, bordo **tratteggiato** 1,5 `--ink3`, padding 16, opacità 0,7 | **nuovo** `Pratiche.Proposta.altezzaPasso = 320`, raggio `Raggio.pannello` (20), `trattoSpento = 1.5`, `tratteggio = [5, 4]` (il CSS `dashed` non ha misura: proposta da vedere sullo schermo), `opacitaSpento = 0.7`, colore `Colore.inchiostro3` |
| Riquadro acceso `.stg.on` (298) | fondo `--cardE`, bordo 1 `--sep`, ombra `--shadow`, opacità 1 | `Colore.cardPiena`, `Colore.separatore`, `Ombra` della card |
| Numero `.stN` (299) | tondo 26, fondo `--chip`, 12,5 grassetto; acceso: `--green`, bianco, scala 1,1 | `Pratiche.Proposta.numero = 26`, `Colore.chip`, `Colore.verde`, `scalaNumeroAcceso = 1.1` |
| Contenuto del passo | `.stC`… nel template c'è solo l'HTML in linea | — |
| Tassello del prodotto | 40, #3E7D69 | `TasselloGlifo(glifo: .proposta, lato: 40)` (parte comune) |
| Nome del prodotto | display 19, 700, interlinea 1,2 | `Carattere.perche` (19, grassetto, −0,3, 1,22): stesso gradino, si riusa |
| Importo | display 30, 700, −0,8, tabellare | **nuovo** `Pratiche.Proposta.importo = Carattere(dimensione: 30, peso: .bold, tracking: -0.8, tabellare: true)` |
| Riga del premio | 13, 600, 10 sopra | `Carattere.barra` (13 semigrassetto) |
| Miniatura `.miniPg` (300) | 150 di larghezza, fondo bianco, raggio 6, padding 12, ombra 0 8 20 −10 rgba(0,0,0,.35); righe alte 5, raggio 3, #E3E8EC, 6 di spazio; grafico 120×44, tratto 2,4 #0A84FF | **nuovo** `Pratiche.Proposta.Miniatura`: `larghezza 150`, raggio `Raggio.bollaPiccola` (6), `riga 5`, colore righe `Carta.filetto` (#E3E8EC), linea `Carta.bluGrafico` (#0A84FF), `tratto 2.4`; sempre su carta bianca anche in scuro (regola dei documenti) |
| Anello dell'adeguatezza | 100, spessore 11, #30B15C, «✓» 30 verde | `Anello` (`AnelliApple.swift:104`), colore dal semaforo di `MotoreAdeguatezza` (verde `Colore.anello1`; giallo/rosso vedi §1.6); `SpuntaDisegnata` (`CompletamentoApple.swift:14`) al centro |
| Elenco dei moduli | `.prep` (130-133): riga 13, pallino 20 con bordo 2 `--track`, acceso `--green` scala 1,08 con spunta bianca | `ListaTiPreparo` / `SpuntaPiccolaApple` (`CompletamentoApple.swift:128, 261`) |
| Riquadro finale | `.tile` con bordo rgba(47,163,90,.4), fondo rgba(47,163,90,.07), spazio 18; «✓» 34; titolo 22 | **nuovo** `Pratiche.Proposta.fondoPronta = Colore.verde.opacity(0.07)`, `bordoPronta = Colore.verde.opacity(0.4)`; titolo `Carattere.titoloGruppo` (22) |

Nello scuro (`07-proposta-costruisce-scuro.png`): riquadri accesi `#283642` (`cardPiena` scura), tratteggio bianco al
38%, miniatura sempre bianca, etichetta del canale con `canaleAlleanza` scuro (#6B95FF).

#### 7.1.3 Movimento
| Cosa | Template | Prisma |
|---|---|---|
| Entrata della scheda | cascata `.st` (720 ms, passo 48) | `entrataCascata` |
| Accensione di un riquadro | a `300 + i·620` ms (1891); classe `on` con transizione 0,5 s `--out` (bordo, fondo, ombra, opacità); il riquadro sale da translateY 12, scala 0,97 in 520 ms molla (.34,1.45,.64,1) | **nuovo** `Tema.Apple.Pratiche.Moto.Passo`: `base = 0.30`, `passo = 0.62`, `durataAccensione = 0.50` (curva `Moto.Curva.uscita`), `durataSalita = 0.52` (`Moto.Curva.molla`), `spostamento = 12`, `scala = 0.97` |
| Numero del passo | tondo verde, scala 1,1 in 0,4 s molla | `Moto.Curva.molla.animazione(0.4)` |
| Importo | conta da 0 (`conteggi`: 1100 ms quartica) | `NumeroCheConta` (`CifreApple.swift:77`) con `Moto.Numero` |
| Anello | si riempie (`accendi(s,80)`: ritardo 80 ms, 1,4 s `--out`) | `Moto.Anello` con ritardo 0,08 |
| Linea della miniatura | si disegna (`linee`: 150 ms poi 1,5 s) | `TracciatoGrafico` (`GraficiApple.swift:206`) con `Moto.Linea` |
| Spunte dei moduli | `250 + k·260` ms dopo l'accensione del quinto | **nuovo** `Pratiche.Moto.Spunte`: `base = 0.25`, `passo = 0.26`, animazione della spunta `Moto.Spunta` |
| Riquadro finale | 1100 ms dopo il quinto; da translateY 14, opacità 0, in 500 ms `--out` | `Pratiche.Moto.Pronta`: `ritardo = 1.10`, `durata = 0.50`, `spostamento = 14` |
| Testo del pulsante | «Costruisco…» → «✓ Fatto» | cambio di testo senza animazione |

**Riduci movimento** (`\.prismaCalmo`): nel template tutti i riquadri a ritardo 0 (riga 1894: `ridotto?0:…`), ma il
riquadro finale arriva lo stesso dopo 1,1 s. In Prisma: tutto compare già fermo e insieme, con la dissolvenza di 0,15 s;
numero completo, anello pieno, linea tracciata, spunte accese, riquadro finale subito.
**Istantanee** (`\.modoIstantanea` + `\.prismaStatoFinale`): stato costruito completo (i cinque riquadri e il riquadro
finale), oppure stato spento per `800-…`: nessun ciclo avviato. Niente Timer: la sequenza si fa con un `Task` che attende
(`try await Task.sleep`) o con animazioni con `delay`, interrotta se si cambia bisogno o scheda (nel template il controllo
`s.isConnected` lo fa per i nodi tolti).

#### 7.1.4 Interazioni
- **Clic su un bisogno**: diventa il bisogno scelto; la colonna principale torna allo stato spento (nel template
  rimonta tutto, 1880). Se per quel bisogno esiste già una proposta costruita (una `Posizione` collegata, §1.5), la
  colonna si apre **già costruita**, senza animazione, con il riquadro finale.
- **«✦ Costruisci la proposta»**: avvia `MotoreProposta.costruisci` (§1.5). Mentre l'animazione scorre il pulsante è
  spento; i numeri sono già pronti prima che parta (l'animazione mostra, non calcola).
- **Passo bloccato** (proposta; il template non lo ha): se un passo non si può fare (nessun prodotto in catalogo, dato
  mancante, adeguatezza rossa), quel riquadro si accende **in arancio o rosso** con la frase del motivo e un pulsante che
  porta dove si rimedia; i passi dopo restano spenti; il riquadro finale non compare. Vedi §1.6.
- **Scelta del prodotto** (proposta): quando nel catalogo ci sono più prodotti adatti, il riquadro 1 si ferma con
  l'elenco (al più 4, con l'etichetta del canale) e la costruzione riprende dopo la scelta. Clic sul riquadro 1 a
  costruzione finita = cambiare prodotto (ricostruisce dal passo 2).
- **Clic sugli altri riquadri a costruzione finita** (proposta): 2 → la proposta in Posizioni (`apriPosizione`,
  `Shell/StatoShell.swift:762`) sul campo importo; 3 → anteprima del prospetto (Prospetti: il prospetto della
  posizione, `CompositoreProspetti.posizione(_:dati:)` / `TipoProspetto.posizione`, o `SceltaProspetto.sostituzione`
  per il quarto bisogno; `SceltaProspetto` **non** ha un caso per la singola posizione); 4 → la scheda di adeguatezza (`PannelloAdeguatezza`); 5 → la scheda Moduli con il primo modulo della
  proposta (§2). Il dettaglio nasce dal riquadro toccato (curva `dettaglioApre`), come nel resto del tema.
- **«Presenta a Marco»**: nel template un toast «Proposta sul tavolo con l'iPad» (1894). In Prisma: se il Tavolo è
  collegato (`TavoloMac`, `Tavolo/TavoloMac.swift`: `mandaDocumento`) manda il prospetto della proposta all'iPad;
  altrimenti apre la presentazione in sala (`Shell/Presentazione.swift`). Presentare segna `SeguitoProposta.presentataIl`
  e registra la raccomandazione del track record (`StatoShell.registra`, `Shell/StatoTrackRecord.swift:24`) come oggi
  quando una proposta viene presentata.
- **«Nel fascicolo»**: toast «Aggiunta al fascicolo del prossimo incontro». In Prisma: aggiunge il prospetto della
  posizione al fascicolo del prossimo appuntamento del cliente (`TipoProspetto.perIncontro`, `Shell/Fascicolo.swift`);
  senza appuntamento futuro, propone di fissarne uno di tipo `.proposta` (`TipoAppuntamento`, `Dati/Modelli.swift:341`).
- **«✓ Fatto»**: proposta: diventa **«Apri in Posizioni»** (il fulcro resta Posizioni).
- **Annullare**: la costruzione crea una bozza (§1.5); il toast di conferma ha «Annulla» (toglie la bozza e la scheda di
  adeguatezza creata), come per le altre creazioni rapide.
- iPhone/iPad: il template non le mostra. Proposta: iPad come il Mac (finestra); iPhone senza questa scheda (la
  costruzione ha bisogno di catalogo, motori e moduli che stanno sul Mac; `istantanea.cifrato` di «Prisma ovunque» non
  porta i documenti).

#### 7.1.5 Mappa verso Prisma

**Esiste già (verificato con grep in `Sources/Prisma`):**
- **Bisogni scoperti**: `MotoreSintesi.calcolaProposte(_ f: FonteRuby) -> [PropostaRuby]` (`Ruby/ProposteRuby.swift:24`):
  dalle analisi di Prisma (protezione, liquidità, previdenza, obiettivi, scadenze) dà le azioni in ordine di urgenza,
  ognuna con `titolo`, `perche` (con le cifre dei motori), `area`, `rischio`, `capitale`, `versamentoMensile`, `importo`,
  e già **salta le aree con una proposta aperta**. `PropostaRuby` (`Ruby/ModelliRuby.swift:62`), `FonteRuby`
  (`ModelliRuby.swift:169`). È esattamente l'elenco «Bisogni scoperti dall'analisi». Inoltre `MotoreBisogni.rileva`
  (`Motori/MotoreBisogni.swift:17`) con `BisognoRilevato` (id stabile, area, titolo, motivo, importanza) e
  `ProfiloBisogni.esiti` (confermati/scartati dal consulente).
- **Bozza di proposta**: `StatoShell.posizioneDaProposta(_:messaggio:)` (`Shell/StatoShell.swift:2169`) crea già una
  `Posizione` con `stato = .proposta`, `esito = .bozza`, area, rischio, capitale, premio mensile, versamento, e la nota
  «Scegli prodotto e canale e completa i dati». Oggi sceglie **Alleanza per difetto** se il cliente ha quel canale: qui va
  sostituito dalla scelta del prodotto (il canale viene dal prodotto).
- **Importo, con le cifre dei motori**: `MotoreProtezioneFamiglia.calcola` (fabbisogno caso morte e divario,
  `Motori/MotoreProtezioneFamiglia.swift:90`), `MotorePrevidenza.calcola` (divario e versamento,
  `Motori/MotorePrevidenza.swift:94`), `MotoreObiettivo.calcola` e `versamentoPrevisto` (`Motori/MotoreObiettivo.swift:65,186`),
  `MotoreCosti.calcola` e `MotoreSostituzione.calcola(attuale:alternativa:prodotti:…)` (`Motori/MotoreCosti.swift:123`,
  `Motori/MotoreSostituzione.swift:82`) per il quarto bisogno («costi da 2.410 a 760 € l'anno»). `MotoreFiscale` /
  `FiscoPolizze` per la deduzione dei contributi previdenziali.
- **Catalogo dei prodotti**: `Prodotto` (`Dati/Prodotti.swift:5`: `nome`, `canale`, `area`, `tipologia`, costi, `sri`,
  `condizioni`, `fonte`, `verificatoIl`), app Prodotti.
- **Prospetto**: `CompositoreProspetti.posizione(_:dati:)` (`Motori/CompositoreProspetti.swift:42`) e
  `TipoProspetto.posizione` / `.sostituzione` (`Dati/Prospetto.swift`), pagine su carta (`PaginaCarta`,
  `DesignSystem/ComponentiCarta.swift:192`).
- **Adeguatezza**: `MotoreAdeguatezza.calcola(_ i: IngressoAdeguatezza) -> EsitoAdeguatezza`
  (`Motori/MotoreAdeguatezza.swift:217`; `complessivo: Semaforo`, `controlli`, `documenti`, `pronta`) e
  `SchedaAdeguatezza` (`Dati/SchedaAdeguatezza.swift:47`: `posizioneId`, `bisognoRilevatoId`, `areaBisogno`,
  `obiettivoId`, `posizioneSostituitaId`, `motivazione`, `consegne`, `firmataIl`).
- **Seguito e track record**: `SeguitoProposta` (`Dati/SeguitoProposte.swift:30`), `Raccomandazione`
  (`Dati/Raccomandazione.swift`), imbuto del Cruscotto di Studio (`MotoreStudio`).
- **Tavolo e fascicolo**: `TavoloMac.mandaDocumento(_:)` (`Tavolo/TavoloMac.swift:333`), `Shell/Fascicolo.swift`.

**Cosa manca:**
1. **`Motori/MotoreProposta.swift`** (puro, senza SwiftUI): da un bisogno a una proposta in cinque passi.
   ```swift
   struct BisognoScoperto: Identifiable, Hashable {   // dall'unione di PropostaRuby e BisognoRilevato confermati
       let id: String; let clienteId: String; let titolo: String; let motivo: String
       let area: AreaPosizione?; let rischio: RischioCoperto?
       let capitale: Double?; let versamentoMensile: Double?; let importo: Double?
       let posizioneSostituitaId: String?           // per «costi più bassi» (smontaggio, MotoreSostituzione)
       let propostaId: String?                       // la Posizione già costruita, se c'è
   }
   enum EsitoPasso<T> { case fatto(T), daScegliere([Prodotto]), manca(String, rimedio: RimedioPasso), bloccato(String) }
   struct PropostaCostruita {
       let prodotto: EsitoPasso<Prodotto>
       let importo: EsitoPasso<ImportoProposta>     // cifra principale, spiegazione, riga del premio (o «da chiedere»)
       let prospetto: EsitoPasso<ProspettoProposta>  // TipoProspetto.posizione o SceltaProspetto.sostituzione, con le pagine
       let adeguatezza: EsitoPasso<EsitoAdeguatezza>
       let moduli: EsitoPasso<[AnteprimaCompilazione]>   // dal §2: modelli del canale/prodotto e campi compilabili
   }
   enum MotoreProposta {
       static func bisogni(fonte: FonteRuby, profilo: ProfiloBisogni) -> [BisognoScoperto]
       static func prodottiAdatti(_ b: BisognoScoperto, catalogo: [Prodotto], canaliCliente: [Canale]) -> [Prodotto]
       static func costruisci(_ b: BisognoScoperto, prodotto: Prodotto?, dati: DatiPrisma, oggi: Date) -> PropostaCostruita
   }
   ```
   Regole:
   - **Prodotto**: `prodottiAdatti` filtra il catalogo per `area` (e `rischio` per la protezione, `tipologia` per
     previdenza) e per i canali del cliente (`Cliente.canali`); **Alleanza colloca solo prodotti Alleanza** (il canale è
     quello del prodotto, mai scelto a parte). 0 prodotti → `manca("Nessun prodotto di protezione caso morte nel
     catalogo", rimedio: .apriProdotti)`; 1 → scelto; più di 1 → `daScegliere`, con quello usato l'ultima volta per lo
     stesso bisogno in testa (proposta: si ricorda per area/rischio in `ImpostazioniPratiche.ultimoProdotto`).
   - **Importo**: dai motori sopra, mai riscritto qui; la spiegazione è una frase fissa per area con le cifre del motore
     («capitale per 20 anni» = durata dalla scadenza o dagli anni al più piccolo dei figli maggiorenne, come il motore di
     protezione). **Premio della copertura**: Prisma non ha le tariffe (§1.6): `ImportoProposta.premio` è `nil` e la riga
     dice «premio: da chiedere alla compagnia» (o il premio scritto a mano nella proposta, se c'è).
   - **Prospetto**: `ProspettoProposta` (nuovo, piccolo: `enum { posizione(String), sostituzione(attuale: String,
     proposta: String) }`) che rimanda a `CompositoreProspetti.posizione(_:dati:)` (`TipoProspetto.posizione`) o a
     `CompositoreProspetti.componi(.sostituzione(…), …)` (`SceltaProspetto.sostituzione`, `Dati/Prospetto.swift:10`);
     numero di pagine dall'impaginazione (`ContenutoProspetto`, `Dati/Prospetto.swift:121`), calcolato senza generare il
     PDF.
   - **Bisogni di tutti i clienti**: `calcolaProposte` lavora su **un** cliente (`FonteRuby`); la barra laterale li vuole
     tutti. `MotoreProposta.bisogni` va chiamato per cliente dentro `CachePratiche` (ricalcolo solo del cliente
     cambiato), mai per tutti i 200 clienti di `--prova-carico` a ogni apertura della scheda; la prova lo misura.
   - **Bozza**: `posizioneDaProposta` oggi usa `clienteAttivoId` e il messaggio di Ruby: per Pratiche serve una
     variante con `clienteId` esplicito e senza messaggio (o il refactoring di quella esistente).
   - **Adeguatezza**: `MotoreAdeguatezza.calcola` con `IngressoAdeguatezza` della bozza (bisogni da `MotoreBisogni`, voci
     di consegna da `impostazioni.consegna.voci`). Verde → «Adeguata»; giallo → «Da motivare» con il controllo che manca;
     rosso → «Non adeguata»: il passo 5 non parte e il riquadro finale non compare. Grigio (dati mancanti) → `manca`.
   - **Moduli**: §2.5, `CompilatoreModuli.anteprima` sui modelli associati al canale o al prodotto: per ognuno quanti campi
     si compilano e quanti mancano («18 campi compilati · 1 da chiedere»).
2. **Persistenza**: «Costruisci» crea (o aggiorna) la bozza con la stessa strada di `posizioneDaProposta`, ma con
   `prodottoId`, `canale` del prodotto, nome del prodotto, importi; crea la `SchedaAdeguatezza` con `bisognoRilevatoId` /
   `areaBisogno` / `posizioneSostituitaId`; segna `PropostaRuby.posizioneId` dove la proposta viene da Ruby. Prospetto e
   moduli **non** si salvano come file finché il consulente non li presenta, li mette nel fascicolo o li salva (leggerezza
   su 8 GB: nessun PDF generato a vuoto).
3. **Vista** `Shell/PraticheProposta.swift`: `ColonnaBisogni`, `LineaPassiProposta` (5 `RiquadroPasso` con stato
   `.spento/.acceso/.bloccato`), `RiquadroPropostaPronta`; componenti piccoli in `DesignSystem/Apple/PassiApple.swift`
   (nome proposto) riusati da §3 e §4.
4. **Collegamenti in arrivo**: smontaggio di Posizioni (altra parte di Luce: «Crea la proposta di sostituzione» →
   `preparaPratiche(scheda: .proposta, bisognoId: "sostituzione-<posizioneId>")`); Ruby (le «proposte» dello spunto
   `SpuntoRuby.proposte` possono aprire Pratiche invece di creare subito la bozza: da decidere, §1.8); Stanotte (parte 06).
5. **Prova** `Motori/ProvaCalcoliProposta.swift` (chiamata da `ProvaCalcoli.esegui()`): (a) un cliente Alleanza+
   indipendente con un bisogno di protezione e due prodotti di protezione in catalogo, uno per canale → `daScegliere`; (b)
   catalogo vuoto → `manca` con il rimedio; (c) l'importo coincide con `MotoreProtezioneFamiglia` (stessa cifra al
   centesimo); (d) adeguatezza rossa → moduli non costruiti; (e) un bisogno con proposta già aperta non compare
   (come `calcolaProposte`); (f) la bozza creata ha `canale == prodotto.canale`.

#### 7.1.6 Dati che l'utente deve dare e stati vuoti
Dati (mai inventarli):
1. **Il catalogo dei prodotti** per area (in Prodotti): senza prodotti adatti la proposta si ferma al passo 1.
2. **Le tariffe o il premio** delle coperture (TCM, infortuni, LTC): Prisma non sa calcolare un premio. Finché l'utente non
   lo scrive nella proposta (o non dà una tabella di tariffe, §1.8), la riga dice «premio: da chiedere alla compagnia».
3. **Le ipotesi dell'Analisi 360** del cliente (protezione, previdenza, obiettivi): senza, `MotoreSintesi` non trova
   bisogni o li trova senza cifre.
4. **I moduli** di ogni canale e prodotto (§2.6).
5. **Le voci da consegnare** prima della firma (Impostazioni › Proposte, `VoceDocumento`): già esistono.

Stati:
- **Nessun bisogno scoperto**: barra laterale con la frase di `proposte()` («Per … le analisi non mostrano scoperture…»,
  `ProposteRuby.swift:12`) adattata a tutti i clienti: «Nessun bisogno scoperto. Le analisi dei clienti sono in ordine o
  hanno già una proposta aperta.»; colonna principale vuota con il tassello `proposta`.
- **Archivio senza clienti**: «Aggiungi un cliente per iniziare» con il pulsante che apre Clienti.
- **Analisi 360 non salvata** per il cliente: il bisogno compare con il motivo «da confermare» (come le ipotesi non
  confermate di `IngressoAdeguatezza.ipotesiConfermate`) e il passo 4 si ferma su «Conferma le ipotesi dell'Analisi 360».
- **Passo bloccato**: riquadro arancio (`Colore.arancio`, fondo `avvisoFondo`, bordo `avvisoBordo`) con la frase e il
  pulsante «Rimedia» (Prodotti, Analisi 360, Posizioni, Impostazioni › Moduli).
- **Adeguatezza rossa**: riquadro 4 con l'anello rosso (`Colore.rosso`) e «Non adeguata: <controllo>»; niente riquadro
  finale; il pulsante della testata dice «Rivedi la proposta».
- **Dati di prova**: i quattro bisogni del template ricostruiti dai motori sui 5 clienti di prova, con un catalogo di prova
  e premi scritti a mano nelle posizioni di prova, etichetta «dati di prova».

#### 7.1.7 Istantanee da aggiungere
Tutte 1440×900, stato finale.
- `801-pratiche-proposta` / `-scuro`: scheda appena aperta (passi spenti tratteggiati).
- `802-pratiche-proposta-pronta` / `-scuro`: proposta costruita, cinque riquadri e riquadro finale.
- `803-pratiche-proposta-scegli-prodotto`: passo 1 fermo con due prodotti (uno per canale).
- `804-pratiche-proposta-bloccata`: catalogo vuoto, passo 1 arancio con «Rimedia».
- `805-pratiche-proposta-non-adeguata`: anello rosso, niente riquadro finale.
- `806-pratiche-proposta-sostituzione` / `-scuro`: il bisogno «costi più bassi» (prospetto di sostituzione).
- `807-pratiche-proposta-vuota`: nessun bisogno scoperto.
- `400-vetrina-apple` / `-scuro` (esistente): aggiungere un `RiquadroPasso` spento e acceso.

#### 7.1.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente
Regole toccate: principio dell'analisi (la proposta nasce dall'analisi e va in Posizioni, il fulcro); canale sempre
riconoscibile (il canale viene dal prodotto; Alleanza colloca solo prodotti Alleanza); calcoli e impaginazione fatti
dall'app; Ruby non inventa cifre; tutto in locale (nessun dato esce: la proposta resta sul Mac finché il consulente non la
presenta o la manda); valori nel tema; target macOS 13 (nessuna API nuova: `Task.sleep`, `ContinuousClock` da macOS 13).

Decisioni:
1. **D1.1 · Chi sceglie il prodotto.** Il template lo sceglie da solo. Proposta: Prisma propone solo prodotti del catalogo
   dell'utente adatti al bisogno; con più di uno chiede; mai un prodotto che non è nel catalogo.
2. **D1.2 · Premi delle coperture.** Prisma non ha tariffe. Strade: (a) premio sempre «da chiedere» o scritto a mano;
   (b) l'utente carica una tabella di tariffe per prodotto (età, durata, capitale) in Prodotti. Proposta: (a) ora, (b) solo
   se l'utente fornisce le tabelle (che **non si possono inventare** e per Alleanza vanno chieste alla compagnia).
3. **D1.3 · «Proposta pronta in N secondi».** Il tempo del template è finto. Proposta: titolo «Proposta pronta» senza
   secondi (o il tempo vero misurato, che sarebbe meno di un secondo).
4. **D1.4 · Che cosa crea «Costruisci».** Proposta: una bozza in Posizioni + la scheda di adeguatezza, annullabile; niente
   file finché non si presenta.
5. **D1.5 · Testi normativi del prospetto di proposta.** Le avvertenze dei documenti di proposta (IDD per Alleanza,
   MiFID/consulenza per l'indipendente) restano quelle già in Prisma; ogni testo nuovo lo deve dare l'utente.
6. **D1.6 · Ruby e Pratiche.** Lo spunto «Cosa proporre al cliente?» di Ruby crea oggi subito una bozza. Proposta: il
   pulsante della risposta diventa «Costruisci in Pratiche» e porta qui sul bisogno.
7. **D1.7 · «Presenta a …» senza Tavolo.** Proposta: presentazione in sala sul Mac; da confermare.

---

### 7.2 Compila da solo

*Voce 3 di `NOVL`: «Compila da solo» · «I moduli si riempiono da soli», glifo `modulo`, tassello #30B15C,
`vaiA('pratiche',()=>{tabP='moduli'})` (2064).*

#### 7.2.1 Cosa si vede
Schermate `07-moduli-*.png`, `07-moduli-compila-*.png`, `07-moduli-fatto-*.png`, `07-moduli-iban-*.png`.

**Barra laterale** (`.side` larga 290, 1856-1857): titolo **«I TUOI MODULI»**; una voce per modulo caricato
(`MODULI`, 1836): **«Proposta di polizza» · «Informativa privacy» · «Mandato di consulenza» · «Questionario di
adeguatezza» · «Adeguata verifica (antiriciclaggio)»**. Ogni voce: tassello `modulo` 32 (blu #0A84FF se scelto, grigio
#9FB3C2 se no), nome 13,5 grassetto, sotto `small` **«PDF caricato da te»**. In fondo alla barra (14 dai bordi), `.k` con
interlinea 1,45: **«Carichi una volta i moduli che usi: Prisma riconosce i campi e li compila con i dati del dossier.»**

**Colonna centrale** (`.main` a 306, flex con spazio 18; 1858): un piano grigio (`--chip`, raggio 20, 14 di margine in
alto, contenuto centrato e tagliato) con **la pagina del modulo** (`.paper` 600×848 bianca, scalata a 0,74 dall'alto;
altezza fissata a 820). La pagina (`moduloHTML`, 1875-1878):
- in alto a sinistra l'occhiello **«PROPOSTA DI POLIZZA · FAC-SIMILE»** (11, 700, spaziatura 1,4, #5A6873) e il titolo
  **«Proposta di polizza»** (display 26 grassetto); in alto a destra 10 #7A8790 **«Modulo caricato da Denis / pagina 1
  di 3»**;
- sezione **«IL CONTRAENTE»** (11, 700, spaziatura .6, #33424D; 20 sopra, 8 sotto) con una griglia di 4 colonne
  (`.fGrid`, spazi 9/10) di 15 campi (`CAMPI`, 1838), ognuno con l'etichetta maiuscola 9 (#7A8790) e una casella alta 31
  (bordo #D5DCE2, raggio 5): Cognome (2 colonne), Nome (2), Codice fiscale (2), Data di nascita (1), Luogo di nascita (1),
  Indirizzo (2), CAP (1), Comune (1), Telefono (2), Email (2), Professione (2), Beneficiari (2), Premio (2), Decorrenza
  (2), IBAN per l'addebito (4);
- sezione **«FIRME»** (22 sopra) con due caselle alte 56: «Firma del contraente», «Firma del consulente»;
- piede `.foot` 9 #7A8790 con filo sopra: **«Fac-simile di prova. Prisma compila i moduli che carichi tu: i dati restano
  sul Mac.»**

**Colonna destra** (larga 300, colonna con spazio 10; 1859-1860): `.lbl` **«COMPILA PER»**; i cinque clienti come chip
(avatar 22 + nome di battesimo; scelto in blu pieno `.on3`); pulsante primario grande centrato **«✦ Compila con i dati di
Giulia»**; sotto `#modS` vuoto.

**Durante la compilazione** (`compila`, 1895-1902): compare la tile **«Campi compilati»** con il numero grande che sale
**«0 di 15»** → «14 di 15»; i campi si riempiono **uno alla volta**, la casella diventa verde chiara (fondo
rgba(48,177,92,.08), bordo rgba(48,177,92,.55)) e il valore **si scrive lettera per lettera** (es. «Rossi», «Giulia»,
«RSSGLI89E52F205Z», «12/05/1989», «Milano (MI)», «Via Vigevano 12», «20144», «Milano», «+39 3•• ••• •218»,
«giulia.rossi@esempio.it», «Architetta», «Gli eredi legittimi», «550,00 € al mese», «01/12/2026»). Il campo senza dato
(**IBAN**) diventa **rosso** (fondo rgba(229,72,77,.08), bordo #E5484D, anello rgba(229,72,77,.15) da 3) con **«?»**
rosso grassetto.

**Alla fine**:
- le due caselle delle firme diventano **gialle** (fondo rgba(255,204,0,.16), bordo #E0B000, anello rgba(255,204,0,.25)
  da 3) e **respirano** (2,4 s);
- in `#modS` entrano, a cascata:
  - una tile con bordo rosato (rgba(229,72,77,.35)): la sfera di Ruby viva 22 e **«Ruby»** (13,5 grassetto); il testo 14
    interlinea 1,5 **«Manca l'IBAN per l'addebito. Lo chiedo a Giulia con un messaggio?»**; due pulsanti **«Sì,
    chiediglielo»** (primario) e **«Lo scrivo io»**;
  - una tile gialla (bordo rgba(255,204,0,.5), fondo rgba(255,204,0,.08)): **«2 firme da raccogliere»** (13,5
    grassetto) e `.k` **«Le caselle gialle: all'incontro di giovedì.»**;
  - una riga `.k` centrata **«14 campi in 3,2 secondi»**.
- «Sì, chiediglielo» → toast «Messaggio a Giulia pronto in Messaggi». «Lo scrivo io» → il campo IBAN diventa verde e vi
  si scrive «IT•• •••• •••• •••• 4417» (20 ms a lettera).

Stranezze del template da non copiare:
- **Tutti e cinque i moduli hanno gli stessi campi** (`CAMPI`): privacy, mandato, questionario e adeguata verifica nella
  realtà hanno campi diversi (consensi, profilo, titolare effettivo, PEP…). Il template mostra una sola pagina tipo.
- Beneficiari, premio e decorrenza sono fissi; telefono ed email sono inventati (l'email è costruita dal nome).
- «14 campi» è `CAMPI.length - 1` scritto fisso, non il conteggio vero; dopo «Lo scrivo io» il contatore resta a 14.
- Le firme «respirano» con `@keyframes respira` della sfera di Ruby (76), che porta con sé un **alone blu**
  (`box-shadow … rgba(90,140,255,.7)`) visibile sotto le caselle gialle: è un effetto della riutilizzazione, non voluto.
- Il riquadro di Ruby ha il bordo rosa come un errore: va bene per «manca», ma è l'unico bordo colorato di Ruby nel tema.

#### 7.2.2 Misure e stile
| Elemento | Template | Prisma |
|---|---|---|
| Barra laterale | 290; voce con tassello 32 (#0A84FF / #9FB3C2) | `Pratiche.lateraleModuli = 290`; `TasselloGlifo(.modulo, lato: 32)`, tinta scelto `Colore.anello2`, spento **nuovo** `Pratiche.Moduli.tasselloSpento = #9FB3C2` (= `Colore.Composizione.liquidita`, si riusa) |
| Frase in fondo | `.k`, interlinea 1,45, 14 dai bordi | `Carattere.secondario`, `Colore.inchiostro2` |
| Piano della pagina | `--chip`, raggio 20, 14 sopra | `Colore.chip`, `Raggio.pannello` |
| Pagina | `.paper` 600×848, padding 40/46, scala 0,74, ombra 0 20 50 −10 rgba(0,0,0,.25) | `PaginaCarta` (`ComponentiCarta.swift:192`) e `Tema.Apple.Carta`; **nuovo** `Pratiche.Moduli.scalaPagina = 0.74`. Nell'app la pagina mostrata è **il PDF vero** dell'utente (`PDFKit`), con le caselle disegnate sopra (§2.5) |
| Occhiello, titolo | 11/700/1,4 #5A6873; display 26 | `Carta.etichetta`; **nuovo** `Carattere` 26 su carta (`titoloCarta` è 36: serve `Pratiche.Moduli.titoloPagina = 26`) — solo nel fac-simile di prova, il PDF vero ha i suoi caratteri |
| Etichetta del campo | 9, maiuscolo, spaziatura .5, 600, #7A8790 | `Carta.piede` (#7A8790); **nuovo** `Pratiche.Moduli.etichettaCampo = Carattere(dimensione: 9, peso: .semibold, tracking: 0.5, maiuscolo: true)` |
| Casella | alta 31, bordo 1 #D5DCE2, raggio 5, padding 7/8, 12,5 #14202B | **nuovo** `Tema.Apple.Carta.bordoCampo = #D5DCE2`; `Carta.testo`; `Pratiche.Moduli.altezzaCampo = 31`, `raggioCampo = 5` |
| Casella piena | fondo verde .08, bordo .55 (#30B15C) | **nuovo** `Pratiche.Moduli.campoPieno = Colore.anello1.opacity(0.08)`, `bordoPieno = Colore.anello1.opacity(0.55)` |
| Casella che manca | fondo #E5484D .08, bordo #E5484D, anello .15 da 3, testo rosso grassetto | `Pratiche.Moduli.campoManca = Colore.rosso.opacity(0.08)`, `anelloManca = Colore.rosso.opacity(0.15)`, `spessoreAnello = 3` |
| Casella della firma | alta 56; gialla: fondo rgba(255,204,0,.16), bordo #E0B000, anello rgba(255,204,0,.25) da 3 | **nuovo** `Pratiche.Moduli.firmaFondo = #FFCC00 .16`, `firmaBordo = #E0B000`, `firmaAnello = #FFCC00 .25`, `altezzaFirma = 56` (colori fissi: stanno sulla carta, uguali in scuro) |
| Chip dei clienti | `.chip` padding 7/14, 13 semigrassetto, avatar 22; scelto `--accent` pieno | `ChipApple` (`ChipBarraApple.swift:16`) con lo stato pieno blu (`Colore.accento`) |
| Tile «Campi compilati» | `.tile` + `.v` 26 | `Superficie.tile`, `Carattere.valore`; «di 15» 14 `--ink2` |
| Tile di Ruby | bordo rgba(229,72,77,.35), sfera 22, testo 14/1,5 | `SferaRuby` (`RubyApple.swift:21`) a 22; **nuovo** `Pratiche.Moduli.bordoRuby = Colore.rosso.opacity(0.35)`; testo `Carattere.corpo` con interlinea 1,5 |
| Tile delle firme | bordo rgba(255,204,0,.5), fondo .08 | `Pratiche.Moduli.tileFirme` (giallo .5 / .08) |

Scuro (`07-moduli-*-scuro.png`): la pagina resta bianca con i colori fissi (regola dei documenti), piano e tile scuri.

#### 7.2.3 Movimento
| Cosa | Template | Prisma |
|---|---|---|
| Un campo | a `200 + i·190` ms (1897); transizione di fondo, bordo e anello 0,4 s; testo 16 ms a lettera (`scrive`, 1794) | **nuovo** `Pratiche.Moto.Campo`: `base = 0.20`, `passo = 0.19`, `durataColore = 0.40`; testo con `TestoProgressivo` (`RubyApple.swift:174`) a passo per lettera: **nuovo** `Pratiche.Moto.Campo.lettera = 0.016` (oggi `Moto.Testo` ha solo `parola`; la parte comune, §4.6, propone il parametro `unita: .parola / .lettera` e `Moto.Testo.lettera` con un valore ancora da decidere, 0,016 / 0,018 / 0,045 secondo l'uso: qui 0,016 come nel template) |
| Contatore | sale di 1 a ogni campo (senza conteggio animato) | testo che cambia; con `NumeroCheConta` andrebbe a scatti: proposta `contentTransition(.numericText())` solo da macOS 14, protetta con `if #available(macOS 14.0, *)` (e iOS 17), ripiego testo semplice su macOS 13 |
| Firme | `respira` 2,4 s, scala 1,045 | **nuovo** `Pratiche.Moto.RespiroFirma`: `periodo = 2.4`, `scala = 1.03` **senza alone blu** (proposta: scala più piccola, perché su un campo largo 1,045 si vede molto) |
| Tile finali | a `300 + 15·190` ms; dalla seconda: da translateY 10, opacità 0, 450 ms `--out`, ritardo k·120 | `Pratiche.Moto.TileFinali`: `durata = 0.45`, `passo = 0.12`, `spostamento = 10` |
| «Lo scrivo io» | IBAN scritto a 20 ms per lettera | `TestoProgressivo` a 0,020 |

Con **Riduci movimento**: nel template i campi vanno a ritardo 0 ma il testo si scrive tutto subito (`scrive` guarda
`ridotto`) e le tile arrivano a 50 ms; le firme respirano lo stesso. In Prisma: tutti i campi pieni subito, dissolvenza
0,15 s, firme ferme gialle senza respiro. **Istantanee**: modulo già compilato, IBAN rosso, firme gialle ferme, tile
finali presenti.

Il respiro delle firme è un'animazione continua: si ferma quando la finestra non si vede, con il Mac a riposo e con
`\.prismaCalmo` (come la sfera di Ruby). Niente Timer: `.repeatForever` con `phaseAnimator` è da macOS 14, quindi
`withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true))` su un `@State`.

#### 7.2.4 Interazioni
- **Clic su un modulo** della barra: mostra quel modulo (pagina 1) non compilato. Proposta: frecce o miniature per le
  pagine («pagina 1 di 3» nel template è solo testo).
- **Clic su un cliente**: cambia il cliente da compilare (nel template 5 chip fissi). Nell'app: il cliente viene dal
  contesto (la proposta del §1, la pratica del §3, il dossier); il campo «Compila per» è un selettore con ricerca (tutti
  i clienti possono essere centinaia) con i clienti recenti come chip.
- **«✦ Compila con i dati di …»**: compila tutti i campi che Prisma sa riempire; mostra quelli che mancano e le firme.
  La compilazione è **un'anteprima**: il PDF compilato si salva solo con **«Salva nel dossier»** (proposta, il template
  non lo ha) come `Documento` del cliente (§2.5).
- **Clic su una casella** (proposta): la si corregge a mano; la correzione vale solo per questo modulo compilato e non
  cambia il dossier, a meno che si scelga «Aggiorna anche il dossier».
- **«Sì, chiediglielo»**: prepara la bozza in Messaggi con la richiesta del dato (§2.5): non si manda nulla da solo.
- **«Lo scrivo io»**: mette il fuoco sulla casella IBAN per scriverlo (nel template lo scrive da solo un IBAN finto).
- **«2 firme da raccogliere» / «all'incontro di giovedì»**: il giorno è quello del prossimo appuntamento del cliente
  (`Appuntamento`, preferendo `tipo == .firma`); senza appuntamenti: «Fissa l'incontro per la firma».
- **Caricare un modulo** (non c'è nel template, ma la frase in fondo lo dice): trascinare un PDF sulla barra o pulsante
  «Aggiungi un modulo» → Prisma riconosce i campi (§2.5) e mostra una pagina di **revisione della mappa**: ogni casella
  riconosciuta con il dato del dossier che le ha associato, da confermare o cambiare; caselle non riconosciute da
  associare a mano (o lasciare vuote). Si fa una volta per modello.
- iPhone/iPad: proposta: solo Mac (i modelli PDF e i documenti non sono nell'istantanea di «Prisma ovunque»).

#### 7.2.5 Mappa verso Prisma

**Esiste già:**
- **Lettura dei PDF tutta sul dispositivo**: `LetturaDocumenti` (`Dati/LetturaDocumenti.swift:15`: PDFKit pagina per
  pagina, Vision per le scansioni, una pagina alla volta per la memoria).
- **Estrazione di campi**: `EstrattoreDocumento.conRegole(_:)` e `daRisposta(_:pagina:)` (`Motori/EstrattoreDocumento.swift:97,184`),
  `CampoDocumento` (`Dati/Documento.swift:196`) con `codiceFiscale`, `numeroDocumento`, `intestatario`, `dataRilascio`,
  `profiloRischio`, `orizzonte`, `premio`, `decorrenza`, `beneficiari`… (servono al contrario: qui si scrive, non si legge).
- **Dati del cliente**: `Cliente` (`Dati/Modelli.swift`: `nome` (una stringa sola), `dataNascita`, `codiceFiscale`,
  `professione`, `indirizzo` (una stringa sola), `email`, `telefono`, `statoCivile`, `famiglia`, `profilo`, `consensi`,
  `conformita`, `fiscale`); `DatiFiscaliCliente` (`Dati/DatiFatturazione.swift:529`: `nome`, `cognome`, `sede:
  SedeFiscale` con `indirizzo`, `numeroCivico`, `cap`, `comune`, `provincia`, `nazione`); `ConformitaCliente`
  (`Dati/Conformita.swift:89`: questionari e adeguate verifiche per canale, `DocumentoIdentita` con tipo, numero,
  rilascio, scadenza; `RischioRiciclaggio`); `Consensi` (`privacy`, `dataPrivacy`, `marketing`, `dataMarketing`).
- **Dati della proposta**: `Posizione` (`beneficiari`, `premio`, `frequenza`, `decorrenza`, `contraente`, `assicurato`,
  `capitaleAssicurato`, `canale`, `prodottoId`).
- **Documenti del dossier**: `Documento` (`Dati/Documento.swift:6`), cartella `Archivio.cartellaDocumenti`,
  `StatoShell.importaDocumenti(_:)` (`Shell/StatoShell.swift:830`).
- **Messaggi**: `StatoShell.preparaMessaggio(clienteId:occasioneId:occasione:messaggioId:allegati:)`
  (`Shell/CollegamentiMessaggi.swift`), `TipoOccasioneMessaggio` (`Dati/MessaggioCliente.swift:11`), `ModelliMessaggi`.
- **Ruby**: `FornitoreModello` / Qwen locale, istruzioni in `Ruby/Istruzioni/` (`estrazione.md`, `documenti.md`).

**Cosa manca:**
1. **Modello di modulo** (`Dati/ModelliModulo.swift`, nome proposto):
   ```swift
   struct ModelloModulo: Identifiable, Codable, Hashable {
       var id: String
       var titolo: String                 // «Proposta di polizza»
       var tipo: TipoModulo               // propostaPolizza, privacy, mandato, questionarioAdeguatezza, adeguataVerifica, altro
       var canale: Canale?                // nil = tutti e due
       var prodottoIds: [String]          // vuoto = tutti i prodotti del canale
       var file: String                   // PDF vuoto in <archivio>/Moduli/<id>.pdf
       var pagine: Int
       var campi: [CampoModulo]
       var caricatoIl: Date; var versione: String?   // la versione stampata sul modulo, se c'è
   }
   struct CampoModulo: Identifiable, Codable, Hashable {
       var id: String
       var pagina: Int
       var riquadro: CGRect               // in punti PDF
       var nomeAcroForm: String?          // se il PDF ha campi compilabili
       var etichetta: String              // il testo vicino, come letto
       var dato: DatoModulo?              // a cosa è associato; nil = da lasciare vuoto
       var tipo: TipoCampoModulo          // testo, data, casella (✓), firma
   }
   enum DatoModulo: String, Codable, CaseIterable {   // ciò che Prisma sa scrivere, con la sua fonte
       case cognome, nome, codiceFiscale, dataNascita, luogoNascita, indirizzo, cap, comune, provincia,
            telefono, email, professione, statoCivile, documentoTipo, documentoNumero, documentoRilascio,
            documentoScadenza, beneficiari, premio, frequenza, decorrenza, scadenza, capitale, prodotto,
            numeroContratto, iban, luogoData, consulente
   }
   ```
   Le **risposte del questionario di adeguatezza** e le **dichiarazioni dell'adeguata verifica** (titolare effettivo,
   persona politicamente esposta, scopo del rapporto, origine dei fondi) **non** sono in `DatoModulo`: le dà il cliente
   ogni volta (§2.8, D2.3).
2. **Riconoscimento dei campi** (`Motori/RiconoscitoreModulo.swift`): (a) se il PDF ha campi AcroForm, PDFKit li dà con
   nome e riquadro (`PDFAnnotation` di tipo widget, `fieldName`); (b) se è piatto, si cercano le etichette con il testo
   della pagina (`PDFPage.string` e `PDFPage.selection(for:)` per i riquadri) e le caselle vicine con regole semplici
   (riga sotto o a destra dell'etichetta); (c) **Ruby (Qwen in locale)**, se pronto, propone l'associazione
   etichetta → `DatoModulo` per le etichette che le regole non riconoscono (istruzioni nuove in
   `Ruby/Istruzioni/moduli.md`, schema `Ruby/Schemi/modulo.json`), sempre da confermare nella pagina di revisione. Senza
   Qwen si fa a mano. Nessun testo esce dal Mac.
3. **Compilazione** (`Motori/CompilatoreModuli.swift`): `anteprima(modello:cliente:posizione:dati:) ->
   AnteprimaCompilazione` (valori per campo, `mancanti`, `firme`) e `scrivi(…) -> URL` che produce il PDF compilato:
   AcroForm → `PDFAnnotation.widgetStringValue` / stato delle caselle; piatto → testo disegnato sulla pagina
   (`PDFAnnotation` di tipo testo libero «appiattita» o disegno in un nuovo `PDFPage` con `draw(with:to:)`). Pagina per
   pagina, con `autoreleasepool`, come `LetturaDocumenti`. Formati italiani (`Motori/Formati.swift`): date gg/mm/aaaa,
   euro con la virgola.
4. **Compilazione salvata**: un `Documento` del cliente (nuovo `Documento.Tipo.modulo`, oppure `.proposta`; da
   decidere), con `posizioneId`, e `CompilazioneModulo { modelloId; documentoId; compilatoIl; mancanti: [DatoModulo];
   firmeRaccolte: Bool }` in `DatiPrisma.compilazioni` (o dentro la `Pratica` del §3).
5. **Campi anagrafici che mancano** (versione 27, tutti facoltativi): `Cliente.luogoNascita: String?`,
   `Cliente.cittadinanza: String?`, e l'uso di `DatiFiscaliCliente.nome/cognome/sede` come fonte strutturata (oggi
   `Cliente.nome` e `Cliente.indirizzo` sono stringhe uniche: **non** si spezzano a indovinare; se la sede fiscale manca,
   cognome/CAP/comune risultano mancanti). **IBAN**: `Cliente.iban: String?` (o per posizione, `Posizione.ibanAddebito`),
   con il controllo del codice di controllo IBAN (mod 97) in `Formati` e la visualizzazione mascherata come nel template;
   decisione D2.4.
6. **Richiesta del dato mancante**: nuovo `TipoOccasioneMessaggio.datiMancanti` (non commerciale) con `riferimento =
   "<compilazioneId>"` e le cifre ammesse (`CifraMessaggio`): solo il nome del dato, mai il dato stesso; testo da
   `ModelliMessaggi` e, se l'utente vuole, raccontato da Qwen (istruzioni in `Ruby/Istruzioni/messaggi.md`).
7. **Archivio e backup**: cartella `<archivio>/Moduli/` con i PDF dei modelli; entra nel backup e nel ripristino
   (`Dati/Backup.swift`), prova in `--prova-backup` (`ProvaBackupPratiche`: un modello con due campi, una compilazione,
   ripristino e confronto). **Fuori** dall'istantanea di «Prisma ovunque» (come i documenti).
8. **Viste**: `Shell/PraticheModuli.swift` (`BarraModuli`, `PaginaModulo` con `PDFView` incapsulato o pagina disegnata
   da `PDFPage.thumbnail`/`draw` in un `Canvas`, sovrapposizione delle caselle `SovrapposizioneCampi`,
   `ColonnaCompila`), `Shell/RevisioneModulo.swift` (mappa dei campi), `Impostazioni › Moduli` (elenco dei modelli,
   canale, prodotti, versione).
9. **Prova** `Motori/ProvaCalcoliModuli.swift`: un PDF AcroForm costruito in memoria con 4 campi → anteprima con 3 pieni
   e 1 mancante; scrittura e rilettura dei valori; data e premio nel formato italiano; IBAN non valido rifiutato; nessun
   dato del questionario compilato da solo.
10. **Stanotte** (parte 06): il preparatore «moduli» chiama `CompilatoreModuli.anteprima` per le proposte con un
    appuntamento di firma il giorno dopo; «Approva» lascia i moduli «compilati, da controllare» qui.

#### 7.2.6 Dati che l'utente deve dare e stati vuoti
Dati (mai inventarli):
1. **I moduli veri**, in PDF, per canale: proposta di polizza (per Alleanza i moduli della compagnia, se e come la
   compagnia permette di usarli fuori dai suoi strumenti: D2.1), informativa privacy (la sua, del consulente
   indipendente, e quella della compagnia), mandato di consulenza (indipendente), questionario di adeguatezza (per canale),
   adeguata verifica antiriciclaggio. I testi del template sono fac-simile.
2. **La revisione della mappa** dei campi di ogni modulo, una volta.
3. **I dati anagrafici che mancano** nel dossier: luogo di nascita, cognome e nome separati e sede (dalla scheda fiscale),
   documento d'identità, IBAN (se si decide di conservarlo).
4. **Le risposte del cliente** al questionario e alle dichiarazioni antiriciclaggio: le dà il cliente, a voce o per iscritto,
   ogni volta.

Stati:
- **Nessun modulo caricato**: barra vuota con il tassello `modulo` e la frase del template come invito, pulsante
  «Aggiungi un modulo»; la colonna centrale mostra un riquadro tratteggiato «Trascina qui il PDF di un modulo».
- **PDF illeggibile o protetto**: «Non riesco a leggere questo PDF» (come `Documento.Lettura.illeggibile`).
- **Nessun campo riconosciuto**: la pagina di revisione si apre con «Nessun campo riconosciuto: segna tu le caselle».
- **Dato mancante**: casella rossa con «?» e, nella colonna destra, l'elenco di ciò che manca con «Chiedilo a …» e «Lo
  scrivo io» (uno per dato; il template ne mostra uno solo).
- **Ruby non pronto**: il riquadro di Ruby diventa una tile senza sfera con lo stesso testo e gli stessi pulsanti (il
  messaggio si prepara con i modelli fissi); il riconoscimento usa solo le regole.
- **Nessun cliente scelto**: pulsante spento «Scegli un cliente».

#### 7.2.7 Istantanee da aggiungere
- `810-pratiche-moduli` / `-scuro`: modulo fac-simile di prova non compilato.
- `811-pratiche-moduli-compilato` / `-scuro`: compilato, IBAN rosso, firme gialle, tile di Ruby e delle firme.
- `812-pratiche-moduli-vuoto`: nessun modulo caricato.
- `813-pratiche-moduli-revisione` / `-scuro`: la pagina di revisione della mappa dei campi.
- `814-pratiche-moduli-senza-ruby`: Qwen non pronto (tile senza sfera).
- `815-impostazioni-moduli`: Impostazioni › Moduli.

#### 7.2.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente
Regole toccate: dati dei clienti in locale (la compilazione, il riconoscimento e Ruby lavorano sul Mac; nessun dato esce);
Ruby estrae e spiega, l'app compila e impagina; documenti su carta bianca; backup che comprende tutto; nessuna dipendenza
esterna (solo PDFKit e Vision di sistema, già usati); macOS 13 (PDFKit e Vision ci sono; `phaseAnimator` e
`contentTransition(.numericText())` no: ripiego).

Decisioni:
1. **D2.1 · Moduli di Alleanza fuori dagli strumenti della compagnia.** Le proposte Alleanza si fanno di norma con gli
   strumenti della compagnia (anche con firma elettronica sui suoi dispositivi). Compilare in Prisma un PDF della
   compagnia è ammesso? Il modulo compilato così è accettato? **Da chiedere ad Alleanza** prima di costruire la parte
   Alleanza; nel frattempo la funzione vale per i moduli del canale indipendente e come promemoria dei dati per Alleanza.
2. **D2.2 · Firme.** Il template evidenzia solo dove firmare. Prisma **non** fa firme elettroniche (la firma elettronica
   avanzata o qualificata richiede un fornitore e procedure dedicate). Proposta: solo caselle evidenziate per la firma a
   penna o con gli strumenti della compagnia; confermare.
3. **D2.3 · Questionario di adeguatezza e adeguata verifica.** Le risposte devono essere del cliente: Prisma **non** le
   compila dal profilo che ha in archivio. Proposta: compila solo l'anagrafica e i dati del documento; le risposte restano
   vuote (o, in un riesame, si mostrano le risposte precedenti accanto, «da confermare con il cliente», mai scritte sul
   modulo da sole). Da confermare, anche con la compagnia per il canale Alleanza.
4. **D2.4 · Conservare l'IBAN.** È un dato bancario del cliente. Proposta: si conserva nel dossier solo se l'utente lo
   decide (interruttore in Impostazioni › Pratiche), mostrato mascherato, nei backup (cifrati se c'è la password) e **mai**
   nell'istantanea di «Prisma ovunque» né nei messaggi.
5. **D2.5 · Ruby che riconosce i campi.** Mandare a Qwen (locale) il testo delle etichette dei moduli: va bene? (Nessun dato
   del cliente, solo il testo del modulo vuoto.) Proposta: sì.
6. **D2.6 · Chiedere il dato al cliente.** «Sì, chiediglielo» prepara un messaggio in Messaggi (Mail o Messaggi di Apple):
   l'invio resta un gesto del consulente; il dato richiesto (IBAN) torna per una via scelta dal cliente. Proposta: nel
   testo nessun dato già in archivio, solo il nome del dato che manca. WhatsApp solo dal foglio di condivisione del sistema
   (servizio di terzi), come deciso nella Sala.
7. **D2.7 · Copia del modulo compilato al cliente.** Se il consulente manda il PDF compilato al cliente, il file **esce dal
   Mac**: proposta: con la password dei PDF per il cliente (`ImpostazioniPDF`, `ModuloSalvaPDF`), come gli altri
   documenti.
8. **D2.8 · Tipo del documento compilato**: `Documento.Tipo.modulo` nuovo (più chiaro nei Documenti) o `.proposta`.
   Proposta: nuovo, con la lettura tollerante dei tipi sconosciuti.

---

### 7.3 Le pratiche dopo la firma

*Voce 4 di `NOVL`: «Le pratiche dopo la firma» · «Cosa manca, pratica per pratica», glifo `cartella`, tassello #0A84FF,
`vaiA('pratiche',()=>{tabP='dopo'})` (2064).*

#### 7.3.1 Cosa si vede
Schermate `07-dopo-chiaro.png`, `07-dopo-scuro.png`.

Scheda a tutta larghezza (1861-1864):
- **Tre tile** in riga (spazio 12, 14 sotto): **«Pratiche aperte» 3**, **«Ferme da più di 7 giorni» 1** (numero in
  rosso), **«Concluse a ottobre» 5**. Numeri `.v` 26 che si contano da 0.
- **Una card per pratica** (padding 16/20, 10 tra le card, **senza ombra**). La pratica ferma ha il bordo
  rgba(229,72,77,.4) e il fondo rgba(229,72,77,.05). Dentro, una riga (spazio 12):
  - avatar 40; nome del cliente 15 grassetto e sotto `.k` il prodotto («Piano di risparmio rivalutabile», «Infortuni
    famiglia · rinnovo», «Fondo pensione aperto», «Rendita integrativa»), colonna larga 260;
  - l'etichetta del canale (colonna 130): «Alleanza» o «Indipendente»;
  - **la linea dei sei passi** (`.trkS`, flex 1, 20 di margine ai lati), da `PASSI` (1843): **«Moduli completi» ·
    «Documenti informativi» · «Documento d'identità» · «Primo premio» · «Polizza emessa» · «Consegnata al cliente»**. Ogni
    passo: pallino 14 sopra l'etichetta (10,5, interlinea 1,25, centrata), collegato al precedente da un filo di 2. Fatto:
    pallino verde pieno, filo verde, etichetta `--ink2`. **Il passo di adesso** (il primo non fatto): bordo blu
    `--accent` con alone rgba(0,122,255,.18) da 4, etichetta blu semigrassetto. **Bloccato** (passo di adesso di una
    pratica ferma): pallino rosso pieno con alone rgba(229,72,77,.2), etichetta rossa grassetto. Futuri: grigi `--ink3`;
  - a destra (colonna 210, allineata a destra): lo stato 13,5 grassetto (**«4 di 6»**, rosso **«3 di 6»** se ferma,
    verde **«✓ Completata»** se 6 di 6), sotto `.k` 12 la nota («Emissione in corso presso la compagnia», «Fermo da 9
    giorni: manca il primo premio», «Da consegnare: contratto e certificato», «Completata il 28 ottobre») e, solo se ferma,
    il pulsante primario piccolo **«Sollecita»** (padding 5/12).
- «Sollecita» → diventa «✓ Sollecito pronto» e toast «Messaggio di sollecito pronto in Messaggi» (1882).

Stranezze del template: le tre tile sono numeri fissi (3, 1, 5), non contati da `PRAT`; «Concluse a ottobre» con oggi
2 novembre vuol dire «il mese scorso»; la pratica di Sofia è completata ma resta nell'elenco con le aperte.

#### 7.3.2 Misure e stile
| Elemento | Template | Prisma |
|---|---|---|
| Tile | `.tile` (raggio 18, padding 14/16), `.k` + `.v` 26 | `Superficie.tile`, `Carattere.secondario`, `Carattere.valore`; rosso `Colore.rosso` |
| Card della pratica | raggio 22, `--card`, bordo `--sep`, **senza ombra**, padding 16/20 | `Superficie.cardPiatta` (esiste, `TemaApple.swift:374`); **nuovo** `Pratiche.Passi.paddingCard = Misura.padding(16, 20)`, spazio fra le card 10 |
| Pratica ferma | bordo rosso .4, fondo rosso .05 | **nuovo** `Pratiche.Passi.bordoFerma = Colore.rosso.opacity(0.4)`, `fondoFerma = Colore.rosso.opacity(0.05)` |
| Colonne | nome 260, canale 130, stato 210 | `Pratiche.Passi.colonnaNome = 260`, `colonnaCanale = 130`, `colonnaStato = 210`; sotto 1100 di larghezza il canale va sotto il nome (proposta) |
| Nome | 15 grassetto | `Carattere.titoloRiga` (15, grassetto) |
| Etichetta canale | `.chA`/`.chI` | `EtichettaCanaleApple` (`PulsantiApple.swift:137`) |
| Passo `.trkS .ps` (307-312) | pallino 14, bordo 2 `--track`, fondo `--cardE`; filo 2 a 6 dall'alto; etichetta 10,5/1,25 `--ink3` | **nuovo** `Pratiche.Passi.pallino = 14`, `bordo = 2`, `filo = 2`, `etichetta = Carattere(dimensione: 10.5, peso: .regular, interlinea: 1.25)`; colori `Colore.binario`, `Colore.cardPiena`, `inchiostro3` |
| Fatto | verde `--green` pieno, filo verde, etichetta `--ink2` | `Colore.verde` |
| Adesso | bordo `--accent`, alone 4 rgba(0,122,255,.18), etichetta blu 600 | `Colore.accento`; **nuovo** `Pratiche.Passi.aloneAdesso = Colore.accento.opacity(0.18)`, `spessoreAlone = 4` |
| Bloccato | rosso pieno, alone 4 rgba(229,72,77,.2), etichetta rossa 700; filo verde | `Colore.rosso`; `Pratiche.Passi.aloneBloccato = Colore.rosso.opacity(0.2)` |
| Stato a destra | 13,5 grassetto (rosso / verde / `--ink`), nota `.k` 12 | `Carattere.voceLista` in grassetto; nota `Carattere.secondario` a 12 (**nuovo** `Pratiche.Passi.nota = 12`) |
| «Sollecita» | primario, padding 5/12 | `StilePulsanteApple` primario piccolo; **nuovo** `Misura.Padding.pulsantePiccolo = Misura.padding(5, 12)` (oggi non esiste: ci sono `pulsante` 7/14 e `pulsanteGrande` 10/18) |

Componente nuovo: **`LineaPassi`** (`DesignSystem/Apple/PassiApple.swift`): N passi con stato `.fatto/.adesso/.bloccato/
.futuro`, etichette su due righe, usato qui e (in una variante più grande) nei sinistri (§4).

#### 7.3.3 Movimento
| Cosa | Template | Prisma |
|---|---|---|
| Tile e card | cascata `.st` | `entrataCascata` |
| Numeri delle tile | si contano (`conteggi`) | `NumeroCheConta`, `Moto.Numero` |
| Passi | ognuno da translateY 6, opacità 0, 400 ms `--out`, ritardo `200 + i·25` ms con i su **tutti** i passi della pagina (24) (1882) | **nuovo** `Pratiche.Moto.Passi`: `base = 0.20`, `passo = 0.025`, `durata = 0.40`, `spostamento = 6`; i limitato (`min(i, 36)`), così con molte pratiche la cascata non supera 1,1 s |
| «Sollecita» | cambio di testo | — |

Nessuna animazione continua. **Riduci movimento**: tutto fermo con la dissolvenza (nel template i passi si animano lo
stesso). **Istantanee**: stato finale.

#### 7.3.4 Interazioni
- **Clic sulla card** (proposta; nel template non fa nulla): apre il dettaglio della pratica (nasce dalla card,
  `dettaglioApre`): i sei passi con la data di ciascuno, chi l'ha segnato (Prisma da solo o a mano), i documenti
  collegati, le note, «Apri in Posizioni», «Apri i moduli».
- **Clic su un passo** (proposta): segna o toglie il passo a mano, con la data di oggi modificabile; i passi che Prisma
  riconosce da solo (§3.5) mostrano «riconosciuto da …» e si possono correggere.
- **«Sollecita»**: prepara in Messaggi il sollecito **al cliente** per ciò che manca (nel template il primo premio):
  `preparaMessaggio(clienteId:occasione:)` con una `OccasioneMessaggio` (`Motori/MotoreOccasioniMessaggi.swift:68`) di
  origine `OrigineMessaggio(tipo: .pratica, riferimento: …)` (il parametro `occasione` è un'`OccasioneMessaggio`, non un
  `TipoOccasioneMessaggio`); il pulsante diventa «✓ Sollecito pronto» finché il messaggio è in bozza;
  niente parte da solo. Se ciò che manca dipende dalla compagnia (emissione), il pulsante dice «Sollecita la compagnia»
  (§4.4, stessa decisione D4.3).
- **Tile** (proposta): clic su «Ferme da più di 7 giorni» filtra le ferme; su «Concluse a …» mostra le concluse del mese
  scorso (in fondo all'elenco o in una sezione a parte).
- **Ordine**: ferme in testa, poi per passo di adesso dal più indietro, poi le concluse (proposta; il template è in ordine
  di dato).
- **Notifiche**: una pratica che diventa ferma entra nel centro notifiche (gruppo «DA SISTEMARE», `Shell/Notifiche.swift`,
  come le `SchedaDaCompletare` di `MotoreAdeguatezza`) e nella mossa del giorno se l'utente lo vuole.
- iPhone/iPad (proposta, il template non le ha): sull'iPhone «Dopo la firma» è la vista principale di Pratiche (una cosa
  grande in alto: le ferme; poi le aperte; il dettaglio a un tocco), in sola lettura più «segna il passo»; sull'iPad come
  il Mac. Segnare un passo dall'iPhone passa dal giornale di «Prisma ovunque» (`giornale-<dispositivo>.cifrato`), che il
  Mac unisce (conflitti in «Da decidere»).

#### 7.3.5 Mappa verso Prisma

**Esiste già** (i passi si possono in gran parte **riconoscere dai dati che Prisma ha**):
| Passo | Da dove lo riconosce Prisma |
|---|---|
| Moduli completi | `CompilazioneModulo` (§2.5) con `mancanti` vuoto e firme raccolte, per tutti i modelli del canale/prodotto |
| Documenti informativi | `EsitoAdeguatezza.documentiCompleti` / `SchedaAdeguatezza.consegne` (`ConsegnaDocumento`, `Dati/SchedaAdeguatezza.swift:29`) con le `VoceDocumento` del canale |
| Documento d'identità | `ConformitaCliente.documento` (`DocumentoIdentita` con `scadenza` futura) o un `Documento` di categoria `.identita` |
| Primo premio | un `Movimento` positivo sulla posizione (`Posizione.movimenti`, `Dati/Posizione.swift:491`) dopo la firma, oppure a mano |
| Polizza emessa | `Posizione.numeroContratto` non vuoto oppure un `Documento` di tipo `.polizza` con `posizioneId` |
| Consegnata al cliente | a mano (data), oppure il documento di polizza consegnato al Tavolo con la presa visione (`TavoloMac.puoChiederePresaVisione`) |

- La firma: `Posizione.esito == .accettata` e `SeguitoProposta.esitoIl` (`MotoreSeguitoProposte.applica` porta la
  posizione a `.inEssere`); `SchedaAdeguatezza.firmataIl`.
- Notifiche: `Shell/Notifiche.swift` (gruppi `daFare`, `oggi`, `prossimi`, `daSistemare`).
- Messaggi: `preparaMessaggio`, `TipoOccasioneMessaggio`, `OrigineMessaggio(tipo:riferimento:)`.
- Studio: `MotoreStudio` (l'imbuto delle proposte) può contare anche «firmate ma non emesse» (proposta).

**Cosa manca:**
1. **Modello** `Dati/Pratica.swift` (versione 27, in `DatiPrisma.pratiche`):
   ```swift
   enum PassoPratica: String, Codable, CaseIterable {
       case moduli, documentiInformativi, documentoIdentita, primoPremio, polizzaEmessa, consegnata
   }
   struct SegnoPasso: Codable, Hashable { var fattoIl: Date; var aMano: Bool; var nota: String? }
   struct Pratica: Identifiable, Codable, Hashable {
       var id: String
       var posizioneId: String            // la posizione firmata (canale, cliente, prodotto vengono da lì)
       var apertaIl: Date                 // = esitoIl della proposta accettata
       var passi: [String: SegnoPasso]    // chiave PassoPratica.rawValue (no dizionari con chiave enum, come ConformitaCliente)
       var nonPertinenti: [String]?       // passi che per questa pratica non servono (es. primo premio già versato)
       var note: [NotaPratica]?           // con data, come le note del track record
       var conclusaIl: Date?
       var sollecitoMessaggioId: String?
   }
   ```
   La pratica **nasce da sola** quando una proposta diventa accettata (`MotoreSeguitoProposte.applica`); chi la crea è
   `StatoShell` (non il motore, che è puro).
2. **Motore** `Motori/MotorePratiche.swift`: `stato(_ p: Pratica, dati: DatiPrisma, oggi: Date) -> StatoPratica` con
   `passi: [(PassoPratica, StatoPasso)]` (`.fatto(data, riconosciuto: Bool)`, `.adesso`, `.bloccato`, `.futuro`,
   `.nonPertinente`), `fatti`, `totale`, `ferma: Bool` (passo di adesso fermo da più di
   `ImpostazioniPratiche.giorniFerma`, 7 di base), `giorniFerma`, `nota: String` (frase dal passo e dai giorni, come
   «Fermo da 9 giorni: manca il primo premio»), e `riepilogo(pratiche:) -> (aperte, ferme, concluseMeseScorso)`. I
   riconoscimenti automatici della tabella sopra vincono solo se il passo non è stato segnato a mano.
3. **Passi per canale** (proposta): `ImpostazioniPratiche.passi: [Canale: …]` — no, niente dizionari con chiave `Canale`:
   `passiAlleanza: [PassoPratica]`, `passiIndipendente: [PassoPratica]`. Per il canale indipendente di solito non c'è una
   «polizza emessa» (un piano di accumulo ha la conferma dell'ordine): etichette per tipo di prodotto da decidere (D3.1).
4. **Messaggi**: nuovo `TipoOccasioneMessaggio.pratica` (non commerciale), riferimento `"<praticaId>-<passo>"`, testo da
   `ModelliMessaggi`.
5. **Viste**: `Shell/PraticheDopoFirma.swift` (`TilePratiche`, `CardPratica`, `DettaglioPratica`), `LineaPassi` comune.
6. **Prova** `Motori/ProvaCalcoliPratiche.swift`: riconoscimento di ogni passo dai dati; passo a mano che vince; ferma a
   8 giorni con soglia 7 e non a 7; concluse del mese scorso a cavallo d'anno (oggi 3 gennaio → dicembre); 200 clienti di
   `--prova-carico` in tempo lineare.
7. **Backup**: `DatiPrisma.pratiche` nel backup e in `ProvaBackupPratiche`; nell'istantanea di «Prisma ovunque» sì (sono
   dati di lavoro senza documenti), da confermare con D-P1 solo per le note.

#### 7.3.6 Dati che l'utente deve dare e stati vuoti
Dati:
1. **I passi di ogni canale** e il loro nome (il template ne dà sei, pensati per una polizza Alleanza).
2. **La soglia della pratica ferma** (7 giorni nel template).
3. **Le date** dei passi che Prisma non può sapere: primo premio incassato dalla compagnia, emissione, consegna.

Stati:
- **Nessuna pratica**: tile a 0 e, al posto delle card, «Nessuna pratica aperta. Una pratica nasce quando una proposta
  viene firmata.» con «Vai alle proposte» (Posizioni, filtro proposte).
- **Solo concluse**: «Tutto in ordine» in verde e l'elenco delle concluse del mese.
- **Dati di prova**: le quattro pratiche del template su Giulia, Marco, Laura e Sofia, con l'etichetta.

#### 7.3.7 Istantanee da aggiungere
- `820-pratiche-dopo` / `-scuro`: le quattro pratiche di prova (una ferma, una completata).
- `821-pratiche-dopo-vuota`: nessuna pratica.
- `822-pratiche-dopo-dettaglio` / `-scuro`: il dettaglio di una pratica con passi riconosciuti e a mano.
- `823-pratiche-dopo-sollecito`: «✓ Sollecito pronto» sulla pratica ferma.
- iOS (in `iOS/IstantaneeMobile.swift`): `824-pratiche-iphone` / `-scuro`: «Dopo la firma» sull'iPhone.

#### 7.3.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente
Regole toccate: tutto in locale; canale sempre riconoscibile (etichetta in ogni card); Posizioni resta il fulcro (la
pratica è la coda di una posizione, non un dato a parte); «Prisma ovunque» (se la pratica entra nell'istantanea e nei
giornali); notifiche locali del Mac (`Shell/PromemoriaMac.swift`, `UNUserNotificationCenter`) se le ferme diventano
promemoria.

Decisioni:
1. **D3.1 · Passi per il canale indipendente.** Proposta: per l'indipendente «Moduli completi · Documenti informativi ·
   Documento d'identità · Primo versamento · Conferma dell'investimento · Consegnata»; da confermare.
2. **D3.2 · Soglia «ferma»**: 7 giorni come nel template, modificabile in Impostazioni › Pratiche.
3. **D3.3 · Sollecito al cliente**: messaggio in bozza in Messaggi, mai inviato da solo (come gli altri messaggi).
4. **D3.4 · Pratiche sull'iPhone** tramite «Prisma ovunque» (lettura + segna il passo): proposta sì, dentro le regole già
   approvate dello spazio cifrato.
5. **D3.5 · Notifiche di sistema delle pratiche ferme.** Il centro notifiche interno («DA SISTEMARE») è dentro l'app; una
   notifica di macOS (`PromemoriaMac`, `UNUserNotificationCenter`) chiede il permesso del sistema, compare anche con Prisma
   bloccata o in secondo piano e mostra il nome del cliente sullo schermo (anche in presenza del cliente o in
   condivisione dello schermo). Proposta: solo il centro interno di base; la notifica di sistema con un interruttore in
   Impostazioni › Pratiche, spento, e con un testo senza nome («Una pratica è ferma da 8 giorni»). Nessun lavoro in
   background apposta: il controllo gira quando Prisma è aperta (o con il preparatore notturno della parte 06, se
   acceso). Da confermare.
6. **D3.6 · Date e conferme della compagnia.** Emissione, incasso del primo premio e numero di polizza li sa la
   compagnia: Prisma non si collega a portali o servizi (nessuna rete); li segna il consulente o arrivano da un documento
   letto in locale (lettera di emissione, quietanza). Confermare che non si vuole alcun collegamento.

---

### 7.4 Il sinistro come una spedizione

*Voce 5 di `NOVL`: «Il sinistro come una spedizione» · «Lo stato in tempo reale, anche per il cliente», glifo
`sinistro`, tassello #E08A00, `vaiA('pratiche',()=>{tabP='sinistri'})` (2064).*

#### 7.4.1 Cosa si vede
Schermate `07-sinistri-chiaro.png`, `07-sinistri-scuro.png`, `07-sinistri-pagato-*.png`.

**Barra laterale** (`.side` larga 300, 1865): titolo **«SINISTRI APERTI E RECENTI»**; una voce per sinistro (`SIN`,
1844-1846): avatar 36, nome del cliente, sotto **«titolo · fase»** («Infortunio di Tommaso · Perizia», «Danni da acqua in
cucina · Pagato», «Furto della bicicletta · Documenti»).

**Colonna principale** (`left:316`, `right:330`; 1866-1871):
- **Testata**: tassello `sinistro` 44 (#E08A00); titolo display 24 grassetto **«Infortunio di Tommaso»**; sotto `.k`
  13,5 **«Marco Bianchi · Frattura del polso giocando a calcio · polizza Infortuni famiglia»**.
- **La card della spedizione** (padding 24/26, 16 sotto, senza ombra):
  - **la linea delle cinque fasi** (`FASI`, 1847): **«Denuncia» · «Documenti» · «Perizia» · «Liquidazione» ·
    «Pagato»**, nodi a distanza uguale (`.trk`, 34 di margine ai lati, alta 44). Una barra sottile (4, raggio 4, binario
    `--track`) li unisce; il riempimento è un **gradiente dal verde all'arancio** (#2FA35A → #E08A00) che arriva fino
    alla fase di adesso. Nodi da 20 con bordo 3: fatti verdi pieni; **fase di adesso** con bordo arancio, alone
    rgba(224,138,0,.2) da 6 e **respiro** (2 s); futuri con il bordo `--track`. Etichette 12,5 semigrassetto sotto (8):
    fatte `--ink2`, adesso arancio, future `--ink3`;
  - 46 sotto, tre cifre in riga (spazio 24): **Stato** «Perizia», **Indennizzo** «tra 1.200 e 1.800 €» (o «pagati
    3.400 €»), **Aperto da** «18 giorni» (17 grassetto, con `.k` sopra).
- **Due card affiancate** (spazio 14, 14 sotto): **«COSA È SUCCESSO»** (flex 1,2): righe con la data in grassetto
  (larga 52: «14 ott») e il fatto («Denuncia inviata alla compagnia», «Ricevuti i documenti: pronto soccorso e
  radiografie», «Visita del medico fiduciario fissata per il 6 novembre»); **«DOCUMENTI»** (flex 1): elenco `.prep` con
  la spunta verde per i ricevuti («Denuncia firmata», «Referto del pronto soccorso») e il cerchio vuoto per i mancanti
  («Certificato di guarigione»).
- **Pulsanti** (14 sotto, spazio 8): **«Aggiorna Marco»** (primario grande) e **«Sollecita la compagnia»** (grande).
  Toast: «Aggiornamento per Marco pronto: lo vede anche nel suo Prisma» e «Sollecito alla compagnia pronto da mandare»
  (1884).

**Colonna destra «Così lo vede Marco»** (larga 310, a destra, centrata; 1872-1874): `.lbl` **«COSÌ LO VEDE MARCO»** e
il **telefono disegnato** (`.phone`, scala 0,82 dall'alto) con lo schermo **sempre chiaro** (#F2F6F9, testo #14202B):
- a 56 dall'alto, 18 ai lati: occhiello 11, 700, spaziatura 1 #5A6873 **«IL PRISMA DI MARCO»**; titolo 23 grassetto,
  interlinea 1,15, **«Infortunio di Tommaso»**;
- una card bianca (raggio 18, padding 16, 14 sopra, ombra 0 8 18 −12 rgba(0,0,0,.3)) con le cinque fasi in colonna (riga
  con spazio 10, padding 6): cerchio 16 verde #30B15C (fatte), arancio #E08A00 con alone 4 rgba(224,138,0,.2) (adesso),
  vuoto con bordo 2 #D5DCE2 (future); testo 13, semigrassetto per fatte e adesso, #9AA6B0 per le future;
- sotto (12 #5A6873, interlinea 1,45) l'ultimo fatto con il punto: «Visita del medico fiduciario fissata per il 6
  novembre.»; e (11 #7A8790) **«Aggiornato da Denis · 29 ott»**.

Con il sinistro pagato (`07-sinistri-pagato-*.png`): tutti i nodi verdi, la barra piena (ma il gradiente finisce
comunque arancio), «Pagato», «pagati 3.400 €», sul telefono cinque cerchi verdi e «Pagati 3.400 €.».

Stranezze del template: «Aperto da» è il numero di eventi × 6 (`s.ev.length*6`), non una data; la barra piena del
pagato finisce arancio come una fase in corso; nell'ultimo stato il nodo «Pagato» non ha la classe «adesso» (giusto) ma
la barra non lo distingue.

#### 7.4.2 Misure e stile
| Elemento | Template | Prisma |
|---|---|---|
| Colonne | barra 300, principale da 316 a 330 dal bordo destro, colonna del telefono 310 | `Pratiche.laterale`, **nuovo** `Pratiche.Spedizione.colonnaTelefono = 310`, spazio 20 |
| Tassello | 44, #E08A00 | `TasselloGlifo(.sinistro, lato: 44)`, tinta `Colore.arancio` |
| Titolo | display 24 grassetto −0,5 | `Pratiche.titolo` (§1.2) |
| Sottotitolo | `.k` 13,5 | `Carattere.voceLista` (13,5) in `inchiostro2` |
| Card della spedizione | padding 24/26, senza ombra | `Superficie.cardPiatta`; **nuovo** `Pratiche.Spedizione.padding = Misura.padding(24, 26)` |
| Linea `.trk` (313-317) | alta 44, margini 34; barra 4 a 8 dall'alto, raggio 4; nodi 20, bordo 3; alone 6; etichette 12,5/600, 8 sotto | **nuovo** `Pratiche.Spedizione`: `margine = 34`, `altezza = 44`, `barra = 4`, `nodo = 20`, `bordoNodo = 3`, `alone = 6`, `etichetta = Carattere.pulsante` (12,5 semigrassetto) |
| Gradiente della barra | `--green` → #E08A00 | **nuovo** `Pratiche.Spedizione.gradiente = [Colore.verde, Colore.arancio]`; a pagato tutto verde (proposta) |
| Nodo adesso | bordo #E08A00, alone .2 | `Colore.arancio`, `alone = Colore.arancio.opacity(0.2)` |
| Cifre | `.k` + 17 grassetto, 46 sotto la linea, spazio 24 | **nuovo** `Pratiche.Spedizione.cifra = Carattere(dimensione: 17, peso: .bold)` (come `titoloFinestra`, si riusa) |
| Card «Cosa è successo» / «Documenti» | padding 18/20, flex 1,2 / 1; data larga 52, riga 13,5, padding 7 | `Misura.Padding.cardPiccola` (18, 20); `Pratiche.Spedizione.colonnaData = 52`; `ListaTiPreparo`/`SpuntaPiccolaApple` per i documenti |
| Telefono | `.phone` 300×620 scala 0,82 | `TelefonoDisegnato` (parte comune), **nuovo** `Pratiche.TelefonoCliente.scala = 0.82` |
| Schermo del cliente | fondo #F2F6F9, testo #14202B, occhiello #5A6873, futuro #9AA6B0, cerchio vuoto #D5DCE2, piede #7A8790, card bianca raggio 18 | **nuovo** `Tema.Apple.Pratiche.TelefonoCliente`: `fondo = #F2F6F9`, testo `Carta.testo`, occhiello `Carta.etichetta`, `futuro = #9AA6B0`, `cerchioVuoto = Carta.bordoCampo` (#D5DCE2, §2.2), piede `Carta.piede`, card raggio `Raggio.tile` (18); colori **fissi** (lo schermo del cliente è sempre chiaro, come la mini-app «Il Prisma del cliente» della Sala) |
| Caratteri dello schermo | 11/700/spaz. 1; 23/700/1,15; 13; 12/1,45; 11 | coerenti con `PrismaCliente.Mini` della parte Sala (stessa mini-app): riusare quei gettoni |

Scuro (`07-sinistri-scuro.png`): card scure; il telefono resta chiaro.

#### 7.4.3 Movimento
| Cosa | Template | Prisma |
|---|---|---|
| Entrata | cascata `.st` | `entrataCascata` |
| Barra della spedizione | larghezza da 0 alla fase, 1,4 s `--out`, dopo 250 ms (1883) | **nuovo** `Pratiche.Moto.Spedizione`: `ritardo = 0.25`, `durata = 1.40`, curva `Moto.Curva.uscita` (stessi valori di `Moto.Anello`: si può riusare `Moto.Anello.durata`) |
| Nodo adesso | respiro 2 s (`respira`, scala 1,045 con alone blu della sfera) | `Pratiche.Moto.RespiroNodo`: `periodo = 2.0`, `scala = 1.045`, **senza alone blu** (l'alone è quello arancio del nodo) |
| Nodi e colori | transizione 0,4 s | `Moto.Curva.ease` 0,4 |
| Cambio di sinistro | rimonta tutta la scheda | proposta: solo colonna principale e telefono, `Moto.CambioCliente` |

**Riduci movimento**: barra già alla fase, nessun respiro, dissolvenza 0,15 s (nel template la barra si muove lo stesso e
il nodo respira). **Istantanee**: barra alla fase, nodo fermo con l'alone. Il respiro si ferma con la finestra nascosta e
il Mac a riposo.

#### 7.4.4 Interazioni
- **Clic su un sinistro** della barra: lo mostra.
- **Nuovo sinistro** (non c'è nel template, serve): pulsante «+ Nuovo sinistro» in testa alla barra: cliente, polizza
  (solo posizioni in essere dell'area protezione, con il canale), data, cosa è successo (testo breve), stima o nulla.
  Anche dal dossier del cliente e dalla posizione (`DettaglioPosizione`).
- **Avanzare di fase**: clic su un nodo (proposta): porta il sinistro a quella fase con la data di oggi modificabile e
  aggiunge l'evento corrispondente in «Cosa è successo» («Perizia», «Liquidazione approvata», «Pagati 3.400 €»).
  «Pagato» chiede l'importo pagato.
- **Aggiungere un fatto**: «+ Aggiungi» in fondo a «Cosa è successo» (data e testo).
- **Documenti**: clic sul cerchio = ricevuto oggi; trascinare un file = lo aggiunge ai Documenti del cliente collegato al
  sinistro e lo segna ricevuto. L'elenco dei documenti richiesti per tipo di sinistro lo dà l'utente (§4.6).
- **«Aggiorna Marco»**: prepara in Messaggi un aggiornamento per il cliente con la fase e l'ultimo fatto
  (`preparaMessaggio(clienteId:occasione:)` con un'`OccasioneMessaggio` di tipo `.sinistro`), in bozza; e, se l'utente lo ha acceso (D4.1), segna l'aggiornamento come
  da includere nel prossimo file «Il Prisma di Marco» (parte Sala). **Non è «in tempo reale»**: il cliente vede lo stato
  quando riceve il messaggio o il file nuovo (§4.8).
- **«Sollecita la compagnia»**: prepara una mail (Mail, `CanaleMessaggio.mail`) all'indirizzo dei sinistri della
  compagnia **scritto dall'utente** in Impostazioni › Pratiche, con il numero di polizza e di sinistro; in bozza.
- **Agenda** (proposta): un fatto con una data futura («visita del medico fiduciario fissata per il 6 novembre») può
  diventare un'attività o un appuntamento del cliente con un clic.
- iPhone/iPad (proposta): sull'iPhone una lista dei sinistri aperti con la linea delle fasi in alto e «segna la fase» /
  «aggiungi un fatto», tramite il giornale di «Prisma ovunque»; nessuna foto o documento dall'iPhone in questa parte
  (Inquadra e capisci esiste già per leggere un documento con la fotocamera, ma qui sarebbero documenti sanitari: D-P1).

#### 7.4.5 Mappa verso Prisma

**Esiste già:**
- Polizze del cliente: `Posizione` (`area == .protezione`, `rischio: RischioCoperto`, `numeroContratto`, `emittente`,
  `canale`, `assicurato`, `assicuratoId`).
- Documenti: `Documento` con `posizioneId`, `CategoriaDocumento`, `StatoShell.importaDocumenti`.
- Messaggi: `preparaMessaggio`, `TipoOccasioneMessaggio`, `CanaleMessaggio` (`mail`, `messaggi`), `AperturaMessaggi`
  (apre Mail o Messaggi di Apple con il testo; l'invio è dell'utente).
- Agenda: `Attivita.nuova(clienteId:scadenza:)`, `Appuntamento`.
- Telefono disegnato e mini-app del cliente: parte comune (`TelefonoDisegnato`) e parte Sala (`MiniPrisma`,
  `ContenutoPrismaCliente`, `FilePrismaCliente`).
- Notifiche: `Shell/Notifiche.swift`.

**Cosa manca:**
1. **Modello** `Dati/Sinistro.swift` (versione 27, `DatiPrisma.sinistri`):
   ```swift
   enum FaseSinistro: String, Codable, CaseIterable { case denuncia, documenti, perizia, liquidazione, pagato, respinto }
   struct EventoSinistro: Identifiable, Codable, Hashable { var id: String; var data: Date; var testo: String; var fase: FaseSinistro? }
   struct DocumentoSinistro: Identifiable, Codable, Hashable { var id: String; var titolo: String; var ricevutoIl: Date?; var documentoId: String? }
   struct Sinistro: Identifiable, Codable, Hashable {
       var id: String
       var clienteId: String
       var posizioneId: String?           // la polizza; il canale viene da lì
       var titolo: String                 // «Infortunio di Tommaso»
       var descrizione: String            // breve, senza dettagli sanitari (D-P1)
       var accadutoIl: Date?
       var apertoIl: Date                 // data della denuncia: «Aperto da» = giorni da qui
       var numeroSinistro: String?
       var fase: FaseSinistro
       var eventi: [EventoSinistro]
       var documenti: [DocumentoSinistro]
       var stimaMinima: Double?; var stimaMassima: Double?; var pagato: Double?
       var chiusoIl: Date?
       var mostraAlCliente: Bool?          // D4.1
       var ultimoAggiornamentoCliente: Date?
   }
   ```
   `respinto` non è nel template ma serve (un sinistro può non essere indennizzato): fase finale in rosso, da confermare
   (D4.4).
2. **Motore** `Motori/MotoreSinistri.swift`: `giorniAperto`, `prossimaFase`, `documentiMancanti`, `indennizzo:
   String` («tra 1.200 e 1.800 €», «fino a 1.500 €», «pagati 3.400 €», «da stimare»), `fermo` (nessun evento da più di N
   giorni, con soglia in `ImpostazioniPratiche.giorniSinistroFermo`), ordinamento (aperti prima, poi chiusi degli ultimi
   90 giorni = «recenti»). Prova `ProvaCalcoliSinistri` (giorni, stime, fermo, ordinamento).
3. **Aggiornamento per il cliente**: `ContenutoSinistroCliente` (titolo, fasi con stato, ultimo fatto, data, nome del
   consulente da `Impostazioni`): lo usano il telefono «Così lo vede …» e, se acceso, il file «Il Prisma di …» (parte Sala:
   un blocco in più in `ContenutoPrismaCliente`, `sinistri: [SinistroMini]?`). **Solo** fase, titolo e ultimo fatto
   scritti dal consulente: niente importi se l'utente non li accende, niente documenti, niente referti.
4. **Messaggi**: `TipoOccasioneMessaggio.sinistro` (non commerciale), riferimento `"<sinistroId>-<fase>"`;
   `TipoOccasioneMessaggio.sollecitoCompagnia` o un'occasione senza cliente destinatario (la mail va alla compagnia): da
   vedere con l'app Messaggi (oggi le occasioni sono verso il cliente).
5. **Impostazioni › Pratiche** (`ImpostazioniPratiche` in `Impostazioni`): `giorniFerma`, `giorniSinistroFermo`,
   `passiAlleanza`, `passiIndipendente`, `indirizziSinistri: [IndirizzoCompagnia]` (nome della compagnia, email scritta
   dall'utente), `documentiPerSinistro: [TipoSinistroDocumenti]` (elenchi dati dall'utente), `conservaIBAN`,
   `sinistriNelPrismaCliente` (D4.1), `ultimoProdotto` (§1.5).
6. **Viste**: `Shell/PraticheSinistri.swift` (`BarraSinistri`, `SpedizioneSinistro` con `LineaPassi` in variante grande
   e barra a gradiente, `CardEventi`, `CardDocumentiSinistro`, `AnteprimaTelefonoSinistro` che disegna con gli stessi
   blocchi della `MiniPrisma`), `Shell/ModuloSinistro.swift` (nuovo sinistro, sul modello di `ModuloPosizione`).
7. **Backup e Ovunque**: `DatiPrisma.sinistri` nel backup e in `ProvaBackupPratiche`; nell'istantanea di «Prisma
   ovunque» solo se D-P1 lo permette (sono dati sanitari).
8. **Dossier**: i sinistri del cliente nella panoramica del dossier e nella linea della vita (`EventoLineaVita`) come
   eventi (proposta).

#### 7.4.6 Dati che l'utente deve dare e stati vuoti
Dati (mai inventarli):
1. **Lo stato del sinistro**: Prisma non è collegato alla compagnia (nessuna rete, nessun portale): ogni fase, data e
   importo li segna il consulente (o arrivano da un documento letto, per esempio la lettera di liquidazione, con la
   lettura dei documenti già in Prisma).
2. **Le stime dell'indennizzo**: solo se il consulente le scrive (la compagnia le comunica); altrimenti «da stimare».
3. **I documenti richiesti** per tipo di sinistro e compagnia (elenco dato dall'utente).
4. **L'indirizzo dei sinistri** di ogni compagnia, per «Sollecita la compagnia».
5. **Il consenso del cliente** a ricevere gli aggiornamenti per messaggio o nel suo file (D4.1).

Stati:
- **Nessun sinistro**: barra con «Nessun sinistro aperto» e il pulsante «+ Nuovo sinistro»; colonna principale con il
  tassello `sinistro` e la frase «Quando un cliente ha un sinistro, lo segui qui come una spedizione.».
- **Sinistro senza polizza collegata**: sottotitolo «polizza da collegare» in arancio; niente etichetta di canale.
- **Nessuna stima**: «Indennizzo · da stimare».
- **Cliente che non vuole aggiornamenti**: colonna del telefono con «Gli aggiornamenti per … sono spenti» al posto
  dell'anteprima; «Aggiorna …» spento.
- **Respinto**: linea fino alla fase raggiunta, poi un nodo rosso «Respinto» (proposta).
- **Dati di prova**: i tre sinistri del template, con l'etichetta.

#### 7.4.7 Istantanee da aggiungere
- `830-pratiche-sinistri` / `-scuro`: Tommaso in perizia (nodo arancio fermo), telefono del cliente.
- `831-pratiche-sinistri-pagato` / `-scuro`: Sofia, pagato (barra tutta verde).
- `832-pratiche-sinistri-vuoto`: nessun sinistro.
- `833-pratiche-sinistri-nuovo`: il modulo «Nuovo sinistro».
- `834-pratiche-sinistri-senza-aggiornamenti`: il cliente non riceve aggiornamenti (colonna del telefono spenta).
- `835-pratiche-sinistri-respinto`: fase finale rossa (se D4.4 è sì).
- iOS: `836-sinistri-iphone` / `-scuro`: elenco dei sinistri sull'iPhone.

#### 7.4.8 Regole di CLAUDE.md toccate e DECISIONI per l'utente
Regole toccate: **«Tutto resta in locale sul Mac: niente server, niente cloud»**; **«I dati dei clienti … mai inviati a
servizi esterni»**; l'unica eccezione cloud approvata («Prisma ovunque») vale **solo per i dispositivi dell'utente**, non
per i clienti; dati sanitari (D-P1); canale riconoscibile; nessuna dipendenza esterna.

**Punto di privacy principale: «lo stato in tempo reale, anche per il cliente» non si può fare dentro le regole di
Prisma.** Uno stato che il cliente vede aggiornarsi da solo sul suo telefono richiede un server o uno spazio in cloud
condiviso con il cliente, cioè proprio ciò che CLAUDE.md esclude. Decisioni:
1. **D4.1 · Come il cliente vede il sinistro.** Strade:
   - (a) **messaggio** preparato da Prisma e mandato dal consulente (Mail o Messaggi) a ogni cambio di fase: il cliente
     vede lo stato quando lo riceve;
   - (b) **blocco «Il tuo sinistro»** nel file «Il Prisma di …» della Sala (cifrato con password, mandato dal
     consulente): il cliente vede lo stato dell'ultimo file ricevuto;
   - (c) tempo reale vero con un servizio in rete: **fuori dalle regole**, non proposto.
   Proposta: (a) sempre, (b) se l'utente lo accende per quel cliente; la frase del template «in tempo reale» diventa
   «aggiornato da Denis · data» (che il template già mostra sul telefono), e il toast «lo vede anche nel suo Prisma» si
   mostra solo con (b) e solo dopo aver rifatto il file. Il telefono «Così lo vede …» è **un'anteprima sul Mac**, nulla
   parte da lì.
2. **D4.2 · Che cosa esce dal Mac nell'aggiornamento.** Proposta: titolo, fase, ultimo fatto (scritto o riletto dal
   consulente prima di mandarlo), data e nome del consulente; **niente** referti, diagnosi, importi (salvo scelta), numero
   di polizza. Il titolo non deve contenere dati sanitari («Infortunio di Tommaso» va bene; «Frattura del polso» resta solo
   sul Mac). I messaggi passano da iMessage/SMS/Mail, servizi di Apple o del provider: va detto all'utente; WhatsApp solo
   dal foglio di condivisione, come per la Sala.
3. **D4.3 · «Sollecita la compagnia».** Una mail con i dati del sinistro alla compagnia è un invio a terzi (la compagnia è
   titolare del sinistro, ma la mail passa dal provider di posta dell'utente). Proposta: bozza in Mail all'indirizzo
   scritto dall'utente, con solo numero di polizza, numero di sinistro e nome dell'assicurato; per Alleanza, se i
   solleciti si fanno solo dal portale della compagnia, il pulsante diventa «Promemoria: sollecita dal portale»
   (un'attività), senza mail. **Da chiedere all'utente** come lavora con ogni compagnia.
4. **D4.4 · Fase «Respinto»** (o «Chiuso senza seguito»): non c'è nel template; proposta sì.
5. **D4.5 · Fasi per tipo di sinistro.** Le cinque fasi del template valgono per i danni e gli infortuni; per un sinistro
   vita (decesso) o una malattia le fasi possono essere diverse: elenco da dare dall'utente, con le cinque come base.
6. **D4.6 · Sinistri nell'istantanea di «Prisma ovunque»** (per vederli e aggiornarli dall'iPhone): proposta sì per
   titolo, fase, eventi e documenti senza file; da confermare con D-P1.
7. **D4.7 · Consenso del cliente** agli aggiornamenti: proposta un interruttore per cliente (`Sinistro.mostraAlCliente`
   e i consensi del dossier, `Consensi.privacy`), spento finché il consulente non lo accende.

Nessuna API sopra macOS 13 è necessaria (Mail e Messaggi si aprono come oggi con `AperturaMessaggi`; il telefono è una
vista SwiftUI).

---

### 7.5 Riepilogo per chi implementa

**File nuovi** (nomi proposti): `Shell/AppPratiche.swift`, `Shell/StatoPratiche.swift`, `Shell/PraticheProposta.swift`,
`Shell/PraticheModuli.swift`, `Shell/RevisioneModulo.swift`, `Shell/PraticheDopoFirma.swift`,
`Shell/PraticheSinistri.swift`, `Shell/ModuloSinistro.swift`, `Shell/ImpostazioniPratiche.swift` (vista);
`Dati/ModelliModulo.swift`, `Dati/Pratica.swift`, `Dati/Sinistro.swift`, `Dati/ImpostazioniPratiche.swift`,
`Dati/ProvaBackupPratiche.swift`; `Motori/MotoreProposta.swift`, `Motori/RiconoscitoreModulo.swift`,
`Motori/CompilatoreModuli.swift`, `Motori/MotorePratiche.swift`, `Motori/MotoreSinistri.swift` con le prove
`ProvaCalcoliProposta`, `ProvaCalcoliModuli`, `ProvaCalcoliPratiche`, `ProvaCalcoliSinistri`;
`DesignSystem/Apple/Tema.Apple+Pratiche.swift`, `DesignSystem/Apple/PassiApple.swift` (`RiquadroPasso`, `LineaPassi`);
`Ruby/Istruzioni/moduli.md`, `Ruby/Schemi/modulo.json` (cartella `Ruby/` alla radice del repository, accanto a
`estrazione.md`, `documenti.md`, `messaggi.md` e a `Schemi/copilota.json`); istantanee in `Shell/IstantaneePratiche.swift` e
`iOS/IstantaneeMobile.swift`.

**File toccati**: `Shell/StatoShell.swift` (`schedaPratiche`, `posizioneDaProposta` con il canale del prodotto),
`Shell/CollegamentiMessaggi.swift` (`preparaPratiche`), `Dati/MessaggioCliente.swift` (casi `datiMancanti`, `pratica`,
`sinistro`, con `nome` e la loro voce in `Motori/MotoreOccasioniMessaggi.swift`, `Motori/ModelliMessaggi.swift`), `Dati/Modelli.swift` (`Cliente.luogoNascita`, `cittadinanza`, eventualmente `iban`),
`Dati/Documento.swift` (`Tipo.modulo`), `Dati/DatiPrisma.swift` (`moduli`, `compilazioni`, `pratiche`, `sinistri`,
`impostazioni.pratiche`, versione 27), `Dati/Backup.swift` (cartella `Moduli/`), `Dati/Archivio.swift`
(`cartellaModuli`), `Shell/Notifiche.swift`, `Shell/PromemoriaMac.swift` (solo se D3.5), `Shell/ModoCliente.swift`, `Motori/ProvaCalcoli.swift` (`esegui()` chiama le prove nuove),
`Ruby/ProposteRuby.swift` (pulsante verso Pratiche), parte Sala (`ContenutoPrismaCliente.sinistri`), parte 06
(preparatore «moduli»).

**Ordine di lavoro proposto**: 1) Dopo la firma (dati quasi tutti già in Prisma, nessuna decisione bloccante oltre a
D3.1); 2) Proposta (dipende da D1.1-D1.4); 3) Sinistri con il solo messaggio (D4.1 a), poi il blocco nel file del cliente
quando la Sala c'è; 4) Moduli, **dopo** la risposta di Alleanza (D2.1) e sulle firme (D2.2), partendo dal canale
indipendente.

**Decisioni raccolte**: D-P0, D-P1, D1.1-D1.7, D2.1-D2.8, D3.1-D3.6, D4.1-D4.7 (sopra, ognuna con la proposta).

---

## 8. Biblioteca, lo smontaggio, il radar del portafoglio

*Parte 08 · tre novità «per il lavoro» della versione «Luce»: la sesta, la settima e l'ottava voce di `NOVL`.*

Fonte: `Design/template-luce.html` (5 novembre 2026). Le righe citate sono di quel file:

| Cosa | Righe |
|---|---|
| Voci del pannello Novità (`NOVL`, sesta, settima e ottava voce) | 2065 |
| Dock con Biblioteca dopo Sala (`DOCK`) | 475 |
| Biblioteca: documenti di prova `DOCS`, domande e risposte `QA`, `qaI` | 1905-1912 |
| Biblioteca: `APPS.biblioteca` (render e mount) | 1913-1919 |
| Biblioteca: `chiediLib` (risposta, foglio, giro delle pagine) | 1920-1932 |
| Radar: `MODELLI`, `RAD`, `radFatto`, `radC` | 1934-1937 |
| Radar: `radarHTML` (colonna destra) | 1938-1943 |
| Radar: `montaRadar` (SVG, punti, dettaglio, «Riequilibra») | 1944-1961 |
| Smontaggio: `SMN`, `smontaHTML`, `montaSmonta` | 1962-1976 |
| Posizioni con quattro viste (`V`, segmentato `vistaP`) | 2082-2084 |
| CSS nuovo: evidenziatore `.hlS`, `.sweep`, `.rPul`, `.smNota` | 318-322 |
| Utilità usate: `conta` 381, `conteggi` 382, `entrata` 383, `accendi` 396, `linee` 399, `barre` 400, `toast` 401, `espandi` 546-551, `chiudiDet` 552, `rimonta` 845, `apriScanner` 1102, `eio` 1435, `scrive` 1794 | |
| CSS esistenti usati: `.side` 120, `.main` 121, `.rub` 122-125, `.tile` 127, `.bar8` 128-129, `.sugg` 184-185, `.paper` 187-195, `.chip` 201, `.sfera` 72-76 | |

Per tutto ciò che qui non è detto vale `Design/template-novita-specifica.md` (Orizzonte), e sotto di essa
`Design/template-apple-specifica.md`: finestra, barra, dock, segmentato, card, cascata, numeri contati, dettaglio che nasce
dalla scheda. La parte comune di Luce (`01-comune.md`) descrive il caso `AppPrisma.biblioteca`, l'icona, il dock, la
testata della finestra e il pannello Novità: qui non si ripetono.

Schermate di riferimento (1480×940, palco 1440×900; non sono nel repository, si rigenerano con
`luce/script/shot08.js` e `shot08b.js`):
- `luce/img/08-bib-vuota-chiaro.png`: Biblioteca appena aperta, sei documenti, nessuna domanda;
- `luce/img/08-bib-gira-chiaro.png`: il foglio mentre le pagine girano;
- `luce/img/08-bib-risposta-chiaro.png`: risposta di Ruby, pagina 14 con la frase evidenziata;
- `luce/img/08-smonta-inizio-*.png`, `08-smonta-*.png`: lo smontaggio a metà e finito, chiaro e scuro;
- `luce/img/08-radar-*.png`: il radar, chiaro e scuro (è scuro in tutti e due gli aspetti);
- `luce/img/08-radar-dettaglio-*.png`, `08-radar-dettaglio-dentro-*.png`: il dettaglio di un cliente fuori e dentro la tolleranza;
- `luce/img/08-radar-riequilibra-*.png`, `08-radar-fatto-*.png`: «Riequilibra» in corso e finito.

**Le cifre, i nomi, i documenti e i testi del template sono dimostrativi** (il template stesso scrive «fac-simile» e
«Testi di esempio»). Nell'app i numeri li danno i motori di Prisma, i testi i documenti dell'utente; dove un dato manca
Prisma lo dice (sottosezione 6 di ogni novità).

**Istantanee.** In `Sources/` la serie più alta è 613; la parte comune di Luce usa 620-629, la Sala 630-668, la
relazione 700-739, la notte, la voce e le spese 760-789. Qui propongo **870-877** (Biblioteca), **880-886**
(Smontaggio) e **890-897** (Radar), da riconciliare nella tabella finale come in Orizzonte §0.5.

**Archivio.** Oggi `DatiPrisma.versioneAttuale = 26` (`Dati/DatiPrisma.swift:113`). I campi nuovi di questa parte vanno
nella versione dell'archivio di Luce (una sola per tutte le parti, come in Orizzonte §0.5), letti con `decodeIfPresent`.

---

### 8.1 Biblioteca · «Trova la pagina»

Voce del pannello Novità: **«Trova la pagina»**, frase **«La risposta, con la frase evidenziata»**, glifo `libro`,
colore #8A5A35, azione `vaiA('biblioteca')` (2065). Biblioteca è un'**app nuova** nel dock, tra Sala e Mercato (475).

#### 8.1.1 Cosa si vede

##### 8.1.1.1 La finestra
Finestra interna standard (in `luce/img/08-bib-vuota-chiaro.png` è a 26/56, 1427×768): titolo **«Biblioteca»**, h1
**«La tua biblioteca.»**, sottotitolo **«CONDIZIONI, CIRCOLARI E NORMATIVA»** (nel sorgente minuscolo, il maiuscolo lo
fa il CSS). Nessun comando nella testata (`#wAct` vuoto).

Il contenuto ha due colonne:
- a sinistra la **barra laterale** `.side`, larga 310 (1914);
- a destra la **colonna principale** `.main`, da 326 al bordo destro (1916).

##### 8.1.1.2 Barra laterale «I documenti»
- Etichetta `.lbl` **«I DOCUMENTI»** e, allineato a destra, il numero dei documenti (**«6»**).
- Una riga `.rub` per documento (padding 10, allineata in alto), nell'ordine di `DOCS` (1905):
  - a sinistra un tassello con il glifo `libro` (32, `ic`), colorato per canale:
    - **blu #2563EB** per i documenti Alleanza (`d[3]==='a'`);
    - **cuoio #B06E12** per quelli della consulenza indipendente (`'i'`);
    - **grigio #5A6873** per normativa e circolari, che non sono di un canale (`''`);
  - il titolo in grassetto 13 pt, interlinea 1,3, **su più righe** (`white-space:normal`), per esempio **«Piano
    rivalutabile · Condizioni di assicurazione»**;
  - sotto, `small` 12 pt `--ink2`: **genere · N pagine** (**«Condizioni · 38 pagine»**).
- I sei documenti di prova: due condizioni Alleanza (38 e 24 pagine), una nota informativa e un KID indipendenti (52 e
  3 pagine), una circolare (12) e una normativa (64).
- In fondo, fissa a 14 dai bordi, la didascalia `.k` (interlinea 1,45): **«Trascina qui i PDF che usi. Ruby li legge sul
  Mac e risponde citando documento e pagina. Testi di esempio.»** (1915).
- Il documento della risposta si accende con `.rub.on` (fondo `rgba(0,122,255,.13)`: CSS 124, acceso da `chiediLib` 1920).

##### 8.1.1.3 Colonna principale: la domanda
- **Barra della domanda** `#libF` (1916), una pillola: fondo `--cardE`, bordo `--sep`, raggio 99, padding 6 6 6 18,
  ombra `--shadow`. Dentro:
  - la **sfera di Ruby** viva da 24, 10 di spazio a destra;
  - il campo **«Chiedi qualcosa ai tuoi documenti…»** (15 pt, senza bordo);
  - il pulsante blu **«Cerca»** (`.btn.pri`).
- 12 sotto, i **suggerimenti** `.sugg` (spazio 8, vanno a capo): **«Il riscatto nei primi anni ha penali?»**, **«Quanto si
  deduce del fondo pensione?»**, **«Se Marco non paga la temporanea?»** (1917).
- Sotto, la **zona della risposta** `#libR`, da 112 al fondo. Vuota mostra al centro (120 dall'alto, 15 pt `.k`):
  **«Fai una domanda: la risposta arriva con la pagina giusta, aperta e illuminata.»** (1918).

##### 8.1.1.4 Colonna principale: la risposta (`chiediLib`, 1920-1932)
Due colonne con spazio 18 (`luce/img/08-bib-risposta-chiaro.png`):

**A sinistra (380):**
- Una tile (padding 18/20) con:
  - la riga: sfera viva 22, **«Ruby»** in grassetto e, a destra in `.k`, **«ho letto 38 pagine»** (le pagine del
    documento trovato);
  - la **risposta** a 16 pt, interlinea 1,55, minimo 96 di altezza, che si scrive lettera per lettera. Esempio: **«Sì.
    Dopo il primo anno Giulia può riscattare, ma fino al quinto anno paga una penale dell'1% per ogni anno che manca al
    quinto.»**;
  - due chip (12 sotto, spazio 6):
    - la chip del documento: glifo `libro` #8A5A35 da 20 e la prima parte del titolo (**«Piano rivalutabile»**);
    - la chip gialla della pagina: fondo `rgba(255,204,0,.18)`, bordo `rgba(200,150,0,.3)`, testo **«Pagina 14 · Art. 9 ·
      Riscatto»**.
- Sotto la tile, due pulsanti grandi (spazio 8): **«Mostra al cliente»** (blu) e **«Copia la citazione»**.
- Poi la nota `.k`: **«La risposta viene solo dal documento: se il testo non dice una cosa, Ruby lo scrive.»**

**A destra (il resto):** un vassoio (fondo `--chip`, raggio 20) con:
- in alto, centrata, la chip del contatore **«pagina 14 di 38»** (cifre tabellari, 12 pt, padding 4/12);
- il **foglio** `.paper` (carta bianca 600×848 scalata a 0,78 dall'alto, 46 sotto il bordo, alto 760, tagliato dal
  vassoio):
  - intestazione 10 pt #7A8790 con filetto #E3E8EC: **«Piano rivalutabile · Condizioni di assicurazione · fac-simile»** a
    sinistra, **«pagina 14»** a destra;
  - il titolo dell'articolo 15 pt grassetto #14202B (**«Art. 9 · Riscatto»**);
  - quattro paragrafi 13,5 pt, interlinea 1,7, #33424D. Il paragrafo della risposta (`hl`) è **evidenziato in giallo**
    (`.hlS`);
  - sette righe finte (alte 6, raggio 3, #EEF1F4, larghe dal 60 al 97%).

Le altre due domande di prova portano alla circolare (pagina 3, **«Paragrafo 2 · Limiti di deducibilità»**) e alle
condizioni della temporanea (pagina 9, **«Art. 6 · Mancato pagamento del premio»**).

##### 8.1.1.5 Stati
| Stato | Cosa si vede |
|---|---|
| Biblioteca vuota (il template non lo mostra) | barra laterale con la sola zona di rilascio; al centro: «Trascina qui le condizioni, i KID e le circolari che usi: Prisma li legge sul Mac.» e il pulsante «Scegli i PDF…» |
| Documenti in lettura (il template non lo mostra) | la riga del documento ha un anello di avanzamento e «Leggo… 12 di 38 pagine»; la domanda funziona sui documenti già letti |
| Pronta, nessuna domanda | come 1.3 |
| Ricerca in corso | foglio che gira, contatore che corre, sfera di Ruby «pensa» (`PuntiniScrittura`) |
| Risposta trovata | come 1.4 |
| Risposta non trovata (il template lo promette nella nota, non lo mostra) | tile di Ruby: «Nei tuoi documenti non ho trovato una risposta a questa domanda.»; niente chip, niente foglio; sotto, le tre pagine più vicine come chip («Condizioni Piano rivalutabile · p. 15») |
| Ruby non pronto (Qwen spento) | la ricerca funziona lo stesso: si apre la pagina più pertinente con i passi trovati evidenziati; la tile dice «Ruby non è pronto: ti mostro la pagina più vicina alla domanda, senza risposta scritta.» |

#### 8.1.2 Misure e stile

##### 8.1.2.1 Gettoni del CSS e corrispondenze
| Elemento | Template | Prisma |
|---|---|---|
| Barra laterale | `.side`: raggio 20, `--panel`, bordo `--sep`, padding 14/12 | `Superficie.pannello`, `Raggio.pannello` (20), `Misura.Padding.barraLaterale` (14, 12) |
| Riga documento | `.rub`: raggio 14, padding 10, spazio 10 | `Raggio.voce` (14); selezione `Colore.selezioneVoce` |
| Titolo riga | 13 pt grassetto, interlinea 1,3, più righe | **nuovo** `Tema.Apple.Biblioteca.titoloDocumento` |
| Dettaglio riga | 12 pt `--ink2`, una riga sola con i puntini (`.rub small`, 125) | `Carattere.secondario` è 12,5 (`TemaApple.swift:682`): per i 12 esatti **nuovo** `Tema.Apple.Biblioteca.dettaglioDocumento` (12), colore `Colore.inchiostro2` |
| Tassello del glifo | `ic('libro',colore,32)`: raggio 0,3·32 | tassello della parte comune (`01-comune.md` §4.1) |
| Barra della domanda | pillola `--cardE`, bordo `--sep`, padding 6 6 6 18, `--shadow` | `Colore.cardPiena`, `Raggio.pillola`; **nuovo** `Tema.Apple.Biblioteca.paddingDomanda` |
| Testo del campo | 15 pt | **nuovo** `Tema.Apple.Biblioteca.campoDomanda` |
| Sfera | 24 nella barra, 22 nella tile | `SferaRuby` (`RubyApple.swift:21`) con le due misure in `Tema.Apple.Biblioteca` |
| Suggerimenti | `.sugg`: pillola, padding 8/14, 13 pt 500, `--card`, bordo | stile dei suggerimenti di Ruby (`Tema.Apple+Ruby.swift`) |
| Tile della risposta | `.tile` padding 18/20 | `Superficie.tile`, padding **nuovo** (18, 20) = `Misura.Padding.cardPiccola` |
| Testo della risposta | 16 pt, interlinea 1,55 | **nuovo** `Tema.Apple.Biblioteca.risposta` |
| Chip | `.chip`: padding 7/14 (la chip del contatore 4/12), 13 pt 600 | chip del tema (`ChipBarraApple.swift`) |
| Chip della pagina | fondo `rgba(255,204,0,.18)`, bordo `rgba(200,150,0,.3)` | **nuovi** `Tema.Apple.Biblioteca.fondoPagina`, `bordoPagina` |
| Vassoio del foglio | `--chip`, raggio 20 | `Colore.chip`, `Raggio.pannello` |
| Foglio | `.paper` 600×848, ombra `0 20px 50px -10px rgba(0,0,0,.25)`, scala 0,78 | `Superficie.carta`; **nuovo** `Tema.Apple.Biblioteca.scalaFoglio = 0.78` |
| Testi sul foglio | intestazione 10 pt #7A8790, titolo 15 pt #14202B, paragrafi 13,5 pt #33424D interlinea 1,7, filetto #E3E8EC, righe finte #EEF1F4 | `Tema.Apple.Carta.piede`, `.testo`, `.testoCorrente`, `.filetto`; righe finte **nuovo** `Carta.righeFinte` (#EEF1F4) |
| Evidenziatore | `rgba(255,214,10,.55)`, raggio 3, testo #14202B | **nuovo** `Tema.Apple.Biblioteca.evidenzia`. Oggi i PDF di Documenti evidenziano in blu (`Tema.Colore.Documenti.evidenziaPDF`, `TemaAppDocumenti.swift:158`): la Biblioteca usa il giallo del template, Documenti resta com'è |
| Colori dei tasselli | #2563EB / #B06E12 / #5A6873 | `Colore.canaleAlleanza` e `canaleIndipendente` **nella versione chiara fissa** (il template non li cambia nello scuro); grigio = `Carta.etichetta` (#5A6873). Nuovo `Tema.Apple.Biblioteca.tassello(canale:)` |

Il foglio resta **carta bianca in tutti e due gli aspetti** (regola dei documenti su carta): niente vetro, colori fissi.

##### 8.1.2.2 Misure di posizione (palco 1440)
- Barra laterale 310, spazio 16, colonna principale il resto (1082 a finestra piena).
- Barra della domanda alta 46; suggerimenti alti 34, 12 sotto; zona della risposta da 112.
- Colonna della risposta 380, spazio 18; pulsanti 12 sotto la tile; nota 12 sotto i pulsanti.
- Contatore a 12 dall'alto del vassoio; foglio a 46.
- Nel porting le misure diventano proporzioni: la barra laterale resta 310 fino alla larghezza minima della finestra
  (1100), la colonna della risposta 380; il foglio si scala per stare nel vassoio (mai sotto 0,6).

##### 8.1.2.3 Token nuovi (`DesignSystem/Apple/Tema.Apple+Biblioteca.swift`, `enum Tema.Apple.Biblioteca`)
`larghezzaLaterale = 310`, `larghezzaRisposta = 380`, `spazioColonne = 18`, `paddingDomanda`, `campoDomanda`
(15), `titoloDocumento` (13 grassetto, interlinea 1,3), `risposta` (16, interlinea 1,55), `minimoRisposta = 96`,
`sferaDomanda = 24`, `sferaRisposta = 22`, `fondoPagina`, `bordoPagina`, `evidenzia`, `raggioEvidenzia = 3`,
`scalaFoglio = 0.78`, `margineFoglio = 46`, `tassello(canale:)`, `Moto` (sotto).

#### 8.1.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Apertura della finestra | cascata `.st` (barra della domanda, suggerimenti) | `Moto.Cascata` (esistente) |
| Selezione del documento | `.rub.on` cambia fondo (transizione `.25s`) | come le altre barre laterali |
| Contatore delle pagine | da 1 alla pagina trovata in **900 ms**, curva `eio` (cubica entra-esci) (1928) | **nuovo** `Tema.Apple.Moto.GiroPagine` (durata 0,90, curva `Curva(x1: 0.65, y1: 0, x2: 0.35, y2: 1)`, l'equivalente della cubica entra-esci), su un intero `Animatable` come `NumeroCheConta` (`CifreApple.swift:77`) |
| Foglio che «sfoglia» | mentre il contatore corre il foglio oscilla in verticale di ±4 (seno di 30·t, circa 5 oscillazioni) (1929) | `Animatable` con l'avanzamento 0…1 che dà lo spostamento `sin(30·t)·4` (niente `keyframeAnimator`, che è di macOS 14); ampiezza **nuovo** `GiroPagine.oscillazione = 4` |
| Arrivo sulla pagina | il foglio passa da opacità 0,4 a 1 in 300 ms (1930) | `GiroPagine.durataArrivo = 0.30` |
| Evidenziatore | si stende da sinistra a destra in **1,3 s**, curva `--out` (318) | **nuovo** `Tema.Apple.Moto.Evidenzia` (1,30, `Curva.uscita`): ogni riga della frase si stende dopo la precedente, con la durata divisa per le righe |
| Risposta | lettera per lettera, 18 ms a lettera (`scrive`, 1794; con `setInterval`) | `TestoProgressivo` (`RubyApple.swift:174`) con il flusso di Qwen, ritmo `Moto.Testo` (esistente). Niente Timer |
| Pulsanti, suggerimenti | `--spring` al tocco, `.sugg` sale di 2 al passaggio | `StilePulsanteApple`, `Moto.SuggerimentoSopra` |

**Riduci movimento.** Nel template il giro dura 1 ms e la risposta compare intera (1928, 1794); l'evidenziatore invece si
stende lo stesso (la transizione CSS non guarda `ridotto`). Nell'app, con `\.prismaCalmo`, tutto compare fermo con la
dissolvenza di 0,15 s: pagina già girata, evidenziatore già steso, niente oscillazione. Il testo di Qwen arriva comunque
a pezzi (è il flusso del modello, non un'animazione).

**Istantanee** (`\.modoIstantanea`, `\.prismaStatoFinale`): contatore sulla pagina finale, foglio fermo, evidenziatore
pieno, risposta completa.

#### 8.1.4 Interazioni

**Mac (template):**
- Clic su un suggerimento: la domanda va nel campo e parte la ricerca (`chiediLib`, 1919).
- «Cerca» o Invio: nel template una scelta per parole chiave fra le tre risposte di prova (1919). Nell'app è la ricerca
  vera (sottosezione 5).
- «Mostra al cliente»: nel template un avviso **«Pagina 14 a tutto schermo, con la frase evidenziata»** (1932).
- «Copia la citazione»: nel template un avviso **«Citazione copiata: «Piano rivalutabile · Condizioni di
  assicurazione», pagina 14»** (1932).
- Tornando nella Biblioteca, l'ultima risposta si ridisegna subito, senza giro (`qaI`, `subito`, 1919).

**Mac (nell'app, oltre il template):**
- **Trascinare PDF** sulla barra laterale (la didascalia lo promette) o «Aggiungi…» dal menu: entrano nella Biblioteca e
  si leggono. Si accettano gli stessi tipi di `LetturaDocumenti.estensioniAccettate` (PDF e immagini).
- **Clic su un documento** della barra laterale (nel template non fa nulla): apre il documento intero nel vassoio, alla
  prima pagina, con le frecce delle pagine (`BarraPagineDocumento`, `AnteprimaDocumento.swift:146`).
- **Menu contestuale** di un documento: «Collega a un prodotto…» (scheda di Prodotti), «Canale», «Genere», «Mostra nel
  Finder», «Togli dalla Biblioteca» (con conferma).
- **Clic sulla chip della pagina**: riporta il foglio alla frase; **clic sulla chip del documento**: apre il documento.
- **Mostra al cliente**: apre la pagina a tutto schermo nella presentazione (`Presentazione`, `VistaPresentazione`,
  `Shell/Presentazione.swift:10,183`), carta bianca, frase evidenziata, senza la risposta di Ruby (la frase del documento
  parla da sola). Esc chiude.
- **Copia la citazione**: mette negli appunti `«Titolo del documento», pagina N, Art. …: "frase evidenziata"`; avviso del
  tema (`Moto.Toast`).
- **Tastiera**: ⌘F porta nel campo della domanda; Invio cerca; frecce su/giù scorrono i suggerimenti; ⌘C con il foglio
  attivo copia la citazione.

**iPhone e iPad:** il template non li prevede. Proposta: nessuna Biblioteca sui dispositivi in questo giro (vedi decisioni).

#### 8.1.5 Mappa verso Prisma

##### 8.1.5.1 Esiste già (verificato con grep in `Sources/Prisma`)
- **Lettura dei PDF sul dispositivo**: `LetturaDocumenti.leggi(_:)` (`Dati/LetturaDocumenti.swift:27`): PDFKit pagina per
  pagina, Vision per le pagine scansionate (soglia 40 caratteri), una pagina alla volta dentro `autoreleasepool`.
  `riconosciConRiquadri` (`:95`, `:105`) dà le righe con il loro riquadro (`RigaLetta`, `RiquadroPagina`,
  `Motori/MotoreInquadra.swift:11,47`). `numeroPagine` (`:126`), `anteprima` (`:131`).
- **Testo accanto al file**: `Documento` tiene il testo in `<id>.txt` con `LetturaDocumenti.separatorePagine` (`\u{0C}`);
  `MemoriaTesti` (`Dati/Documento.swift:307`) tiene in memoria al massimo 4 milioni di caratteri e dimentica i meno
  recenti; `StatoShell.testoDocumento(_:memorizza:)` (`Shell/StatoShell.swift:807`).
- **Vista di un PDF con evidenziazione**: `VistaPDF` (`Shell/AnteprimaDocumento.swift:312`) con
  `Coordinatore.mostra(_:evidenzia:in:)` (`:346`), che cerca i primi 40 caratteri dell'estratto con `findString` e li
  evidenzia. `PaginaTestoDocumento` (`:244`) per le pagine senza PDF, con `evidenziata(_:estratto:)` (`:297`). `FoglioRicostruito`
  (`:107`) e `BarraPagineDocumento` (`:146`) oggi sono `private`: per riusarli nella Biblioteca e nello Smontaggio vanno
  resi interni (senza cambiarne l'aspetto).
- **Ricerca nel testo delle pagine**: `Ricerca` (`Shell/Ricerca.swift`), candidati con `pagine` (`:209-246`), estratto
  attorno alla parola (`riga(_:attorno:)`). È una ricerca per parole che devono esserci tutte: va bene per «Cerca
  ovunque», non per una domanda in italiano.
- **Ruby**: `FornitoreModello` (`Ruby/FornitoreModello.swift:80`), `NucleoRuby.finestra = 8_192` token
  (`Ruby/NucleoRuby.swift:44`), istruzioni in `Ruby/Istruzioni/` (`chat.md`, `documenti.md`, …). `Ruby/DocumentiRuby.swift`
  (un'estensione di `MotoreSintesi`, non un tipo `DocumentiRuby`) spiega i documenti **del cliente** (campi estratti con
  la pagina, `pagina(_:)` privata a `:188`).
- **Componenti**: `SferaRuby`, `PuntiniScrittura`, `TestoProgressivo` (`RubyApple.swift:21,124,174`),
  `StilePulsanteApple`, chip del tema, `Superficie.carta`, `Tema.Apple.Carta`.
- **Prodotti**: `Prodotto.fonte`, `verificatoIl`, `condizioni: CondizioniContratto?` (`Dati/Prodotti.swift:5-29`). La
  scheda di un prodotto oggi dice «da quale documento» vengono i dati, ma il documento non è in Prisma.
- **Archivio**: `Archivio.cartellaDocumenti` (`Dati/Archivio.swift:16`), creata con `cartellaRuby` (`:49`).
- **Trascinamento**: `ImportaDocumenti`, `GestioneDocumenti` (`Shell/RicezioneDocumenti.swift:17,42`).
- **Modalità cliente**: `appRiservate` (`Shell/ModoCliente.swift:8`).

##### 8.1.5.2 Cosa manca
1. **I documenti della Biblioteca non sono documenti di un cliente.** `Documento.clienteId` è obbligatorio
   (`Dati/Documento.swift:44`). Serve un modello a parte, `DocumentoBiblioteca` (`Dati/Biblioteca.swift`, nomi proposti):
   - `id` («bib-…»), `titolo`, `genere: GenereBiblioteca` (`condizioni`, `notaInformativa`, `kid`, `setInformativo`,
     `circolare`, `normativa`, `altro`; nome per l'interfaccia: «Condizioni», «Nota informativa», «KID», «Set
     informativo», «Circolare», «Normativa», «Altro»);
   - `canale: Canale?` (nil = di riferimento, tassello grigio);
   - `file` (percorso dentro la cartella nuova `Biblioteca/` accanto a `Documenti/`), `pagine`, `pagineOCR`,
     `dimensione`, `importatoIl`, `lettura` (riusa `Documento.Lettura`);
   - `edizione: String` (scritta dall'utente o letta: «ed. 03/2026»), `prodottoId: String?` (scheda di Prodotti);
   - testo in `Biblioteca/<id>.txt` con lo stesso separatore.
   - `DatiPrisma.biblioteca: [DocumentoBiblioteca] = []`, letto con `decodeIfPresent`.
   - Cartella `Archivio.cartellaBiblioteca`, creata con le altre.
2. **Indice locale** — `MotoreBiblioteca` (`Motori/MotoreBiblioteca.swift`):
   - **Passi**: ogni pagina si divide in passi (paragrafi separati da righe vuote; se la pagina non ne ha, finestre di
     circa 120 parole che si sovrappongono di 20). Ogni `PassoBiblioteca` ha `documentoId`, `pagina`, `numero`,
     `testo`, `intestazione` (l'ultimo titolo visto sopra: righe che iniziano con «Art.», «Articolo», «Paragrafo»,
     «Sezione» o un numero romano), `inizio` (posizione del passo nel testo della pagina).
   - **Ricerca**: BM25 su parole normalizzate (minuscole, senza accenti, parole vuote italiane tolte, radice corta:
     «riscatto», «riscattare» → «riscatt»), più un premio se la parola è nell'intestazione. Restituisce i primi 6 passi.
     Niente modelli di vettori, niente dipendenze.
   - L'indice è **derivato**: si costruisce dai `.txt` all'avvio della Biblioteca, fuori dal thread principale (coda
     propria, priorità bassa), e si tiene in memoria finché la Biblioteca è aperta (con la stessa logica di
     `MemoriaTesti`). Non va nell'archivio né nei backup.
   - Misura: 200 documenti da 50 pagine ≈ 10.000 pagine ≈ 30 MB di testo; l'indice delle parole ≈ 10-15 MB. Oltre una
     soglia (proposta: 60 MB in tutto) si indicizzano i documenti più usati e si dice «Indice parziale: 140 di 200
     documenti».
3. **Ruby che risponde dai passi** — `BibliotecaRuby` (`Ruby/BibliotecaRuby.swift`, nome nuovo) e istruzioni nuove
   `Ruby/Istruzioni/biblioteca.md` con lo schema `Ruby/Schemi/biblioteca.json`:
   - Prisma manda a Qwen la domanda e i 6 passi, ciascuno con un'etichetta (`[P1] «Titolo», pagina 14, Art. 9 · Riscatto:
     …`). Con la finestra di 8.192 token restano circa 5.000 token di passi: 6 passi da 120-250 parole ci stanno.
   - Qwen risponde in JSON: `{"trovato": true, "passo": "P2", "frase": "…", "risposta": "…"}` oppure `{"trovato":
     false}`. Modalità **lavoro** (come `chat.md`): solo ciò che c'è nei passi, niente conoscenza generale, niente cifre
     calcolate.
   - **Prisma verifica la frase**: deve stare, parola per parola (spazi, a capo e sillabazioni normalizzati), dentro il
     passo indicato. Se non c'è, la risposta non si mostra come citazione: si mostra la pagina del passo con «Ruby non
     ha trovato una frase che lo dica esattamente: guarda il passo evidenziato».
   - Se la risposta contiene numeri, devono comparire nel passo (stessa regola dei numeri «solo da Prisma e dalla scheda»
     della modalità lavoro). Un numero che non c'è fa cadere la risposta.
   - La domanda può nominare un cliente («Se Marco non paga…»): il nome resta nella frase di Ruby, ma **non si mandano a
     Qwen i dati del cliente** in questa funzione (non servono).
4. **Il foglio con l'evidenziatore che si stende.** `VistaPDF` evidenzia con `highlightedSelections` (senza
   animazione) e solo i primi 40 caratteri. Proposta: nel vassoio la pagina si disegna come **immagine** della pagina
   (`PDFPage.thumbnail`, una pagina alla volta, circa 4 MB) e sopra si disegnano i rettangoli della frase in SwiftUI:
   - per i PDF con testo, la frase si trova nel `string` della pagina (stessa normalizzazione), si prende la
     `PDFSelection` dell'intervallo (`page.selection(for: NSRange)`), poi `selectionsByLine()` e `bounds(for:)` di ogni
     riga, riportati in `RiquadroPagina` (0…1, origine in alto);
   - per le pagine scansionate, le righe di `riconosciConRiquadri` che contengono la frase.
   Così l'evidenziatore si anima riga per riga (`Moto.Evidenzia`) e la stessa vista serve alla presentazione. Il
   documento intero (clic sulla riga) usa invece `VistaPDF`, con l'evidenziazione estesa alla frase intera.
5. **Vista e stato**: `Shell/AppBiblioteca.swift` (nome della parte comune), `Shell/StatoBiblioteca.swift`
   (`ObservableObject` a parte, come `StatoInquadra`, così la ricerca non ridisegna le altre app): domanda, risultato,
   fase (`vuota`, `lettura`, `cerca`, `risposta`, `nonTrovata`, `senzaRuby`), documento aperto, pagina.
6. **Collegamenti**:
   - Prodotti: nella scheda di un prodotto, «Condizioni nella Biblioteca» apre il documento collegato
     (`prodottoId`).
   - Ruby (app e scrivania): una domanda su condizioni o normativa può proporre «Cerca nella Biblioteca» (stessa
     ricerca, risposta con il collegamento alla pagina).
   - «Cerca ovunque» (⌘K): un gruppo nuovo «Biblioteca» in `GruppoRicerca` (`Shell/Ricerca.swift:8`) che cerca nei titoli
     e nel testo con la regola di oggi.
7. **Backup**: la cartella `Biblioteca/` (PDF e `.txt`) entra nel backup come `Documenti/`; `Prisma --prova-backup` va
   aggiornata (un documento della Biblioteca con il suo testo torna uguale dopo il ripristino; un archivio senza
   Biblioteca si legge).
8. **Dati di prova**: sei documenti fac-simile scritti apposta (come quelli del template, mai testi copiati da
   condizioni vere), in `Sources/Prisma/Risorse/Biblioteca/` come testo (non PDF: il foglio si disegna con
   `PaginaTestoDocumento`), caricati solo con i clienti fittizi da Impostazioni e tolti con loro.
9. **Prove nuove**:
   - `ProvaCalcoliBiblioteca` (`Motori/`): divisione in passi, intestazioni, normalizzazione, BM25 sui sei fac-simile (le
     tre domande del template trovano la pagina giusta al primo posto);
   - `ProvaRuby` estesa: la verifica della frase (una frase inventata viene rifiutata; un numero che non è nel passo fa
     cadere la risposta).

#### 8.1.6 Dati che l'utente deve dare (mai inventarli) e stati vuoti
1. **I documenti**: condizioni di assicurazione, set informativi, KID, note informative, circolari, normativa. Prisma non
   ne porta nessuno (sono testi della compagnia o dello Stato); li trascina l'utente.
2. **Canale e genere** di ogni documento: Prisma li propone (parole come «Alleanza» nel testo, «Condizioni di
   assicurazione», «Documento contenente le informazioni chiave») e l'utente conferma; finché non conferma la riga dice
   «genere da confermare».
3. **Edizione** del documento e collegamento al prodotto: facoltativi. Se due documenti hanno lo stesso prodotto e
   edizioni diverse, la risposta cita sempre l'edizione («ed. 03/2026») e avvisa «c'è anche un'edizione più vecchia».
4. Stati vuoti: vedi 1.5. Un PDF illeggibile (immagine senza testo riconosciuto) resta nella barra laterale con
   «illeggibile: non posso cercarci dentro».

#### 8.1.7 Istantanee da aggiungere
| Nome | Scena |
|---|---|
| `870-biblioteca` / `-scuro` | i sei documenti di prova, nessuna domanda (come `08-bib-vuota`) |
| `871-biblioteca-risposta` / `-scuro` | domanda sul riscatto: risposta completa, pagina 14, frase evidenziata, documento acceso |
| `872-biblioteca-vuota` / `-scuro` | archivio senza documenti: zona di rilascio |
| `873-biblioteca-lettura` | tre documenti in lettura con l'avanzamento |
| `874-biblioteca-non-trovata` | risposta non trovata con le tre pagine vicine |
| `875-biblioteca-senza-ruby` | Qwen non pronto: pagina con i passi evidenziati, nessuna risposta scritta |
| `876-biblioteca-cliente` | «Mostra al cliente»: pagina a tutto schermo con la frase |
| `877-biblioteca-stretta` | finestra alla larghezza minima (1100) |

Tutte nello stato finale, 1440×900 come le altre del tema Apple. La vetrina «400-vetrina-apple» prende l'evidenziatore e
la chip della pagina.

#### 8.1.8 Regole di CLAUDE.md toccate e decisioni per l'utente
Regole: tema Apple e valori in `DesignSystem` (token sopra); documenti su carta bianca; movimento con «Riduci movimento»
e istantanee; Ruby solo con Qwen locale, i numeri dal documento e non dal modello; prompt nuovi in `Ruby/`; backup
aggiornato con la prova; nessuna dipendenza esterna; codice leggero (una pagina alla volta, indice con un tetto).

**Uscite dal Mac e privacy:** nessuna. I PDF si leggono con PDFKit e Vision sul Mac, l'indice è in memoria, Qwen è su
127.0.0.1. «Copia la citazione» mette il testo negli appunti: con gli Appunti condivisi di Apple il testo può arrivare
sull'iPhone dell'utente (è testo del documento, non del cliente).

Decisioni:
1. **Ricerca solo per parole (BM25) o anche per significato?** La proposta è BM25, senza dipendenze, che basta con domande
   che usano le parole del documento. Per domande con parole diverse («penali» contro «costi di uscita») servirebbe un
   modello di vettori: o `NLEmbedding` di Apple (sul Mac, nessuna rete, da verificare la qualità in italiano) o un
   secondo modello in Ollama (da scaricare, più memoria sugli 8 GB). Da decidere.
2. **«ho letto 38 pagine»**: Qwen non legge 38 pagine, legge 6 passi scelti da Prisma. Proposta di testo onesto: «ho
   cercato in 38 pagine».
3. **Documenti di Alleanza**: possono stare nella Biblioteca solo se l'utente li ha e li trascina. Prisma non li scarica
   da nessuna parte.
4. **iPhone e iPad**: il template non li prevede. Proposta: niente Biblioteca sui dispositivi in questo giro. Più avanti
   potrebbe passare dal ponte di Ruby: la domanda va al Mac, che risponde con la frase e un'immagine della pagina.
   «Prisma ovunque» non porta i documenti (l'istantanea li esclude), quindi senza il Mac non ci sarebbe.
5. **Modalità cliente**: la Biblioteca non mostra dati dei clienti e si può aprire davanti al cliente (come propone
   `01-comune.md`), ma le domande di prova nominano clienti: in modalità cliente i suggerimenti vanno senza nomi.
6. **Personalizzare la risposta** («Giulia può riscattare»): il template mette il nome del cliente nella risposta.
   Proposta: solo se il nome è nella domanda; Prisma non aggiunge da solo dati della posizione (decorrenza, anni già
   passati). Se l'utente lo vuole, la riga «Giulia ha questo prodotto dal 2021: oggi è al 5° anno» la calcola Prisma
   da `Posizione.decorrenza`, sotto la risposta, mai dentro la frase di Qwen.
7. **Testi normativi**: Prisma non ne contiene e non li aggiorna. Una circolare superata resta finché l'utente non la
   toglie: proposta di mostrare «edizione del …» e l'età del documento in ogni citazione. Il template stesso ne dà
   l'esempio: la risposta di prova sulla deducibilità dice **«Fino a 5.164,57 € l'anno»** (1908), mentre Prisma usa già
   **5.300 € dal 2026** (`Motori/MotoreFiscale.swift:32`). Proposta: quando una citazione contiene una cifra che Prisma
   ha come parametro dei suoi motori (deducibilità, aliquote, bollo) e le due cifre non coincidono, sotto la risposta
   compare «Attenzione: Prisma usa 5.300 € (dal 2026); il documento potrebbe essere superato». Il parametro resta quello
   di Prisma; la Biblioteca non lo cambia mai. Da confermare.
9. **Backup e documenti riservati della compagnia**: la cartella `Biblioteca/` entra nei backup (5.2.7), che vanno
   nella cartella scelta dall'utente (anche iCloud Drive). Circolari e manuali interni di Alleanza possono essere
   riservati: l'utente deve decidere se possono stare in un backup su iCloud Drive. Proposta: Biblioteca nel backup di
   base, con un interruttore «Escludi la Biblioteca dal backup» e la misura della cartella mostrata in Impostazioni ›
   Backup (i PDF pesano: 200 documenti possono fare centinaia di MB, che si moltiplicano per le 8 copie della rotazione).
8. **API**: PDFKit e Vision ci sono da macOS 13 (già usate). Nessuna API sopra macOS 13 è necessaria.

---

### 8.2 Lo smontaggio

Voce del pannello Novità: **«Lo smontaggio»**, frase **«I costi nascosti cerchiati sul documento»**, glifo `lente`,
colore #E5484D, azione `vaiA('posizioni',()=>{vistaP='smonta'})` (2065). È la quarta vista di Posizioni.

#### 8.2.1 Cosa si vede

##### 8.2.1.1 Posizioni con quattro viste
La testata di Posizioni (2083) ha ora il segmentato **«Portafoglio · Radar · Prova del fuoco · Smontaggio»** (valori
`port`, `radar`, `fuoco`, `smonta`) e accanto il pulsante **«◎ Inquadra con l'iPhone»**. Il titolo resta **«Il
portafoglio.»** con **«35 CLIENTI · AGGIORNATO ADESSO»**. Il cambio di vista usa `rimonta` (845).

##### 8.2.1.2 Il documento (sinistra)
Un vassoio (`flex:1`, fondo `--chip`, raggio 20, 14 sopra) con il **foglio** `.paper` scalato a 0,8 e alto 780 (1963).
Sul foglio (fac-simile):
- in alto a sinistra: `.pl` **«BANCA ESEMPIO · FAC-SIMILE»** (#7A8790, invece del blu predefinito), titolo 24 pt
  **«Fondo Esempio Globale»**, sottotitolo **«Estratto annuale 2025 · Giulia Rossi»**;
- in alto a destra: **«Valore al 31/12»** (11 pt #7A8790) e **«90.000 €»** (20 pt grassetto #14202B);
- la **tabella dei costi**, 22 sotto, con filo superiore di 2 #14202B: cinque righe (padding 13, filetto #E3E8EC, 13 pt
  #33424D, valore in grassetto #14202B a destra) (1964):

| Voce | Valore scritto | Cifra di Prisma | Nota |
|---|---|---|---|
| Commissione di gestione | 2,10% l'anno | 1.890 € nel 2025 | «La voce più pesante: da sola fa il 78% dei costi.» |
| Commissione di performance | 20% oltre l'indice | 420 € nel 2025 | «Pagata anche in un anno in cui il fondo ha reso meno dell'inflazione.» |
| Diritti fissi | 25 € a trimestre | 100 € l'anno | nessuna |
| Costi di ingresso | 2,50% (pagati nel 2021) | 1.950 € già persi | «Soldi che non hanno mai lavorato per Giulia.» |
| Penale di rimborso | 3% fino al 2027 | fino a 2.700 € se esce ora | «Da considerare nel momento del cambio: forse conviene aspettare.» |

- sotto, sei righe finte (#EEF1F4).
- **Le annotazioni** (SVG `#smA`, 508×700, sopra il foglio, 1965 e 1973-1974): ogni valore viene **cerchiato a mano** con
  un'ellisse rossa (#E5484D, spessore 2,4, larga quanto il valore più 16 per lato, alta 34, ruotata di −2°). Le voci con
  una nota hanno, fuori dal foglio, una **nota rossa** (12,5 pt, interlinea 1,4, #D93036; nello scuro #FF7A7A; prima riga
  in grassetto con la cifra) collegata all'ellisse da una linea tratteggiata (3 4, spessore 1,4). Le note si alternano:
  pari a destra del foglio (allineate a sinistra), dispari a sinistra (allineate a destra), larghe 190.

##### 8.2.1.3 Le card (destra, larga 520)
**Card 1** (padding 20/22, senza ombra, 1966-1967):
- avatar del cliente 40, **«L'estratto conto di Giulia, inquadrato con l'iPhone»** (`.k`) e **«Fondo Esempio Globale ·
  90.000 €»** (16 pt grassetto);
- due cifre `.v` (spazio 24, 16 sotto): **«Costi l'anno, oggi»** **2.410 €** in rosso; **«Con la tua proposta»** **760 €**
  in verde.

**Card 2** (`flex:1`, 1968-1970):
- `.lbl` **«IN DIECI ANNI, A PARITÀ DI MERCATO»**;
- **«+22.100 €»** in verde, 44 pt grassetto, spaziatura −1,4;
- `.k` **«per Giulia, solo per i costi più bassi. Stima con rendimento lordo del 5% l'anno.»**;
- grafico 470×170, 14 sotto: linea rossa **«oggi»** (#E5484D, 2,6), linea verde **«con te»** (#30B15C, 2,8), area verde fra
  le due (opacità 0,14), etichette 11,5 pt grassetto a destra delle linee. Le due curve sono
  `90.000 × (1 + 5% − costi/valore)^anno` per 10 anni (2,68% e 0,84%).
- in fondo due pulsanti grandi: **«Crea la proposta di sostituzione»** (blu) e **«Inquadra un altro documento»**.

Le cifre del template tornano fra loro: 1.890 + 420 + 100 = 2.410; 1.890 / 2.410 = 78%; 2.410 / 90.000 = 2,68%; 760 /
90.000 = 0,84%; differenza a 10 anni 90.000 × (1,0416¹⁰ − 1,0232¹⁰) ≈ 22.085, scritta 22.100. I 1.950 € di costi
d'ingresso (2,50%) presuppongono un versato di 78.000 €, che il template non scrive da nessuna parte (sul foglio c'è solo
il valore al 31/12): nell'app senza versato quella cifra non c'è (sottosezione 6).

##### 8.2.1.4 Stati
| Stato | Cosa si vede |
|---|---|
| Nessun documento scelto (il template mostra sempre Giulia) | vassoio con «Inquadra con l'iPhone o trascina qui un estratto conto, un rendiconto o un KID: Prisma cerchia i costi.» e i pulsanti «Inquadra con l'iPhone» e «Scegli un documento di un cliente…» |
| Lettura in corso | il foglio appare e le ellissi aspettano; card con i numeri a «—» |
| Costi trovati, senza proposta | card 1 con la sola cifra «oggi»; card 2: «Scegli un prodotto da confrontare» con il menu dei prodotti e delle proposte del cliente; niente grafico |
| Costi trovati, con proposta | come 1.3 |
| Una voce senza cifra in euro | ellisse tratteggiata invece che piena; nota «cifra non calcolabile: serve l'importo addebitato» |
| Nessun costo trovato | il foglio senza ellissi; «Non ho trovato voci di costo in questo documento. Se ci sono, segnale tu: clic sulla riga.» |

#### 8.2.2 Misure e stile

| Elemento | Template | Prisma |
|---|---|---|
| Vassoio | `--chip`, raggio 20, padding sopra 14 | `Colore.chip`, `Raggio.pannello` |
| Foglio | `.paper` 600×848, scala 0,8, alto 780 | `Superficie.carta`; **nuovo** `Tema.Apple.Posizioni.Smontaggio.scalaFoglio = 0.8` |
| Testi del foglio | `.pl` 11 pt spaziatura 1,4 #7A8790; h3 24 pt; `.ps` 13 pt #4A5964; tabella 13 pt #33424D, valori #14202B; filetti #E3E8EC; filo 2 #14202B | `Carta.piede`, `Carta.testo`, `Carta.sottotitolo`, `Carta.testoCorrente`, `Carta.filetto`; filo **nuovo** `Smontaggio.filoTabella = 2` |
| Ellisse | #E5484D, 2,4, ry 17, rx = mezza larghezza del valore + 16, rotazione −2° | `Carta.rosso` (fisso, è sulla carta); **nuovi** `Smontaggio.spessoreCerchio = 2.4`, `margineCerchio = 16`, `altezzaCerchio = 34`, `rotazioneCerchio = -2` |
| Nota | 12,5 pt, interlinea 1,4, peso 500, #D93036 (scuro #FF7A7A), larga 190 | **nuovi** `Smontaggio.nota` (carattere), `coloreNota = d(#D93036, #FF7A7A)`, `larghezzaNota = 190` |
| Linea di richiamo | tratteggio 3 4, spessore 1,4, #E5484D | **nuovi** `Smontaggio.tratteggioRichiamo`, `spessoreRichiamo` |
| Card | `.card` senza ombra, padding 20/22 | `Superficie.cardPiatta`, `Misura.Padding.cardMedia` (20, 22) |
| Cifre della card 1 | `.v` 26 pt, rosso `--red`, verde `--green` | `Carattere.valore`, `Colore.rosso`, `Colore.verde` |
| Guadagno a 10 anni | 44 pt 700, spaziatura −1,4, verde | `Carattere.valoreCursoreAnalisi` (44, −1,5) va bene; altrimenti **nuovo** `Smontaggio.guadagno` |
| Grafico | 470×170; rosso #E5484D 2,6, verde #30B15C 2,8, area #30B15C 0,14; etichette 11,5 pt 700 | `TracciatoGrafico`, `FasciaGrafico` (`GraficiApple.swift:206,293`); `Colore.rosso`, `Colore.Area.liquidita` (#30B15C) |
| Colonna destra | 520, spazio 18 | **nuovo** `Smontaggio.larghezzaColonna = 520` |

Il foglio e le annotazioni sono **sulla carta**: colori fissi in chiaro e in scuro, tranne la nota, che sta fuori dal
foglio (sul vassoio) e nel template si schiarisce nello scuro (`body.dark .smNota`, 322).

Token nuovi in `Tema.Apple+Posizioni.swift`, `enum Tema.Apple.Posizioni.Smontaggio` (accanto a `Posizioni.Fuoco`, che
sta in `Tema.Apple+ProvaFuoco.swift`).

#### 8.2.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Entrata della vista | `rimonta` (uscita 130 ms, poi cascata `.st` delle due card) | come la prova del fuoco (`ProvaDelFuocoApple.swift`, `cambia(_:)`), `Moto.Cascata` |
| Ellissi | una alla volta: partenza **500 ms + i·650 ms**; il tratto si disegna in **700 ms**, curva **(.4, 0, .2, 1)** (1975) | **nuovo** `Tema.Apple.Moto.Cerchio` (durata 0,70, ritardo 0,50, passo 0,65, curva `Curva(x1: 0.4, y1: 0, x2: 0.2, y2: 1)`), con `trim(from:to:)` su un'ellisse |
| Note | 400 ms dopo l'inizio della propria ellisse, da 6 più in basso e trasparenti, in 500 ms (1975) | `Cerchio.ritardoNota = 0.40`, `durataNota = 0.50`; le linee di richiamo compaiono con la nota |
| Numeri | 0 → valore (`data-n`): 2.410, 760, 22.100 | `NumeroCheConta`, `Moto.Numero` |
| Linee del grafico | si disegnano (150 + i·120 ms, 1,5 s) | `Moto.Linea` |
| Area fra le linee | opacità 0 → 1 in 0,9 s dopo 0,6 s | `Moto.Area` (0,90 / 0,60) |

Con cinque voci l'ultima ellisse parte a 3,1 s e finisce a 3,8 s: il passo di 650 ms resta (è il «disegno a mano»), ma
oltre 6 voci il passo si riduce perché tutto finisca entro 4 s (`passo × min(i, 5)` più un passo corto per le altre).

**Riduci movimento**: nel template le ellissi compaiono subito (`ridotto ? 0`, durata 1), ma le note restano animate
(500 ms dopo 400 ms: l'animazione delle note non guarda `ridotto`, 1975), come le card (`entrata`) e le linee. Nell'app
tutto fermo con la dissolvenza di 0,15 s. **Istantanee**: ellissi chiuse, note visibili, numeri completi, linee tracciate.

#### 8.2.4 Interazioni

**Mac (template):**
- **«Crea la proposta di sostituzione»** porta a Pratiche › Proposta (`vaiA('pratiche',()=>{tabP='proposta';bisI=3})`,
  1976).
- **«Inquadra un altro documento»** apre la scena di Inquadra (`apriScanner`, 1102). Nel template la scena mostra la
  «Polizza Vita Intera» di Orizzonte, non un estratto conto: è un **difetto del template** (riusa la scena vecchia).
  Nell'app la scena di Inquadra, aperta dallo Smontaggio, dice «Inquadra l'estratto conto o il rendiconto» e passa le
  righe a `MotoreSmontaggio`.
- **«◎ Inquadra con l'iPhone»** nella testata fa lo stesso.

**Mac (nell'app):**
- La vista si apre sul documento scelto: l'ultimo inquadrato o trascinato, oppure quello scelto dal menu della card 1
  («Altro documento di Giulia…», con gli estratti conto, i rendiconti e i KID del dossier).
- **Trascinare** un PDF o una foto sul vassoio: si legge sul Mac (`LetturaDocumenti`), come nella scena di Inquadra.
- **Clic su un'ellisse o su una nota**: fumetto con la riga letta, il conto («2,10% × 90.000 € = 1.890 €») e la fonte
  («scritto nel documento» oppure «calcolato da Prisma»). Da lì «Non è un costo» toglie la voce.
- **Clic su una riga del foglio non cerchiata**: «Segna come costo…» con il tipo (menu) e il valore; si aggiunge
  un'ellisse.
- **Menu della card 2** «Confronta con…»: le proposte del cliente (`Posizione.stato == .proposta`) e le schede di
  Prodotti dello stesso tipo; la scelta ricalcola cifre e grafico.
- **«Crea la proposta di sostituzione»**: apre la proposta già impostata (prodotto scelto, capitale = valore, cliente)
  in Pratiche, se c'è (parte di Pratiche di Luce), altrimenti nel modulo della posizione (`ModuloPosizione`) con
  `stato = .proposta`; il prospetto di sostituzione esiste già (`ProspettoSostituzione`).
- **Aggiungere il documento al dossier**: come in Inquadra, niente entra senza conferma.

**iPhone:** l'inquadratura passa dall'iPhone al Mac con il ponte di Inquadra (`InquadraTelefono`,
`InquadraturaPonte` con le righe e i loro riquadri, `Ruby/MessaggiPonte.swift:65-83`). Sull'iPhone non cambia nulla
rispetto a Orizzonte §9; il Mac, se la vista attiva è lo Smontaggio, legge le righe con `MotoreSmontaggio` invece che con
`MotoreInquadra`.

#### 8.2.5 Mappa verso Prisma

##### 8.2.5.1 Esiste già (verificato con grep)
- `VistaPosizioni` con `portafoglio` e `provaDelFuoco` (`Shell/StatoProvaFuoco.swift:9-18`); la testata
  `TestataVistePortafoglio` con `SegmentatoPillola` e `PulsanteInquadra` (`Shell/ProvaDelFuocoApple.swift:136-157`); il
  cambio di vista `cambia(_:)` (`:83-104`).
- Inquadra: `StatoInquadra` e `FaseInquadra` (`Shell/StatoInquadra.swift:24,38`), `ScenaInquadra` e `PulsanteInquadra`
  (`Shell/ScenaInquadra.swift:51,551`), `MotoreInquadra` con `RiquadroPagina`, `RigaLetta`, `CampoInquadrato`
  (`Motori/MotoreInquadra.swift`). La foto vive solo in memoria.
- Lettura: `LetturaDocumenti.riconosciConRiquadri`, `EstrattoreDocumento` (numeri e date).
- Campi dei documenti: `CampoDocumento` ha `costoIngresso`, `costoUscita`, `costoAnnuo`, `incidenzaCosti`,
  `controvalore`, `totaleVersato`, `dataValore` (`Dati/Documento.swift:196-202`). Non ha la commissione di
  performance, i diritti fissi, il bollo né la penale con la sua data.
- Costi: `MotoreCosti.calcola`, `voce`, `alternativa(_:prodotti:cliente:)`, `serie(_:durata:)`, `incidenzaKID`
  (`Motori/MotoreCosti.swift:123-317`); `PannelloCosti`, `ProspettoCosti`, `ReportCosti`.
- Sostituzione: `MotoreSostituzione.calcola(attuale:alternativa:prodotti:…)` con penali, costi d'ingresso e tasse
  (`Motori/MotoreSostituzione.swift:81-260`); `ProspettoSostituzione`, `ReportSostituzione`.
- Riscatto e penali: `CondizioniContratto.penali`, `penale(anno:)` (`Dati/Valutazione.swift:88-126`), `MotoreRiscatto`.
- Inflazione: `SerieRiferimento.idInflazione` e `MotoreRiferimenti` (per la nota «ha reso meno dell'inflazione»).
- Grafici: `TracciatoGrafico`, `FasciaGrafico`; numeri: `NumeroCheConta`.

##### 8.2.5.2 Cosa manca
1. `VistaPosizioni.smontaggio` (titolo «Smontaggio») e `.radar` (novità 3), nell'ordine del template: Portafoglio, Radar,
   Prova del fuoco, Smontaggio. `StatoProvaFuoco.swift` ospita l'enum: conviene spostarlo in un file proprio
   (`Shell/VistePosizioni.swift`).
2. **Motore** `MotoreSmontaggio` (`Motori/MotoreSmontaggio.swift`, nomi proposti):
   - entrata: le righe lette (`[RigaLetta]`, con riquadri per le foto e le scansioni; per i PDF con testo i riquadri
     vengono da `PDFSelection` come nella Biblioteca), il valore della posizione (`controvalore` letto o `Posizione.valore`),
     il versato (`totaleVersato`), la data del documento;
   - uscita: `SmontaggioCosti` con `voci: [VoceCostoTrovata]`, `costoAnnuo: Double?` (somma delle voci annue con cifra),
     `quotaAnnua: Double?` (costo annuo / valore), `giaPagati: Double?` (costi d'ingresso), `uscitaOggi: Double?`
     (penale), `mancanti: [TipoCosto]`;
   - `VoceCostoTrovata`: `tipo: TipoCosto` (`gestione`, `performance`, `dirittiFissi`, `ingresso`, `uscita`, `bollo`,
     `altro`), `etichetta` (come scritta), `valoreScritto` («2,10% l'anno»), `euroAnno: Double?`, `euroUnaVolta:
     Double?`, `finoAl: Date?`, `fonte` (`.scritta` se l'importo in euro è nel documento, `.calcolata` se Prisma lo
     calcola, `.mancante`), `riga: Int`, `pagina: Int`, `riquadro: RiquadroPagina?`, `nota: String?`, `confermata: Bool`;
   - regole:
     - gestione: se il documento scrive l'importo addebitato si usa quello, altrimenti percentuale × valore, segnato
       «stima»;
     - performance: **solo l'importo scritto** (la percentuale «oltre l'indice» non basta senza l'indice e il
       rendimento dell'anno);
     - diritti fissi: importo × volte l'anno (trimestre = 4, semestre = 2, mese = 12);
     - ingresso: percentuale × versato, «già persi»;
     - penale: percentuale × valore, «se esce ora», con la data fino a cui vale; se la posizione ha le condizioni, vince
       `CondizioniContratto.penale(anno:)`;
   - le **note** sono frasi di Prisma con le sue cifre (`TestiSmontaggio`), non di Qwen:
     - la voce più pesante («da sola fa il N% dei costi», se supera il 50%);
     - la performance pagata in un anno sotto l'inflazione (solo se c'è il rendimento dell'anno nel documento e
       l'inflazione dell'anno in `MotoreRiferimenti`);
     - i costi d'ingresso («Soldi che non hanno mai lavorato per …»);
     - la penale («fino a … se esce ora»; «forse conviene aspettare» solo se `MotoreSostituzione` dice che aspettare la
       fine della penale rende di più).
3. **Il confronto**: «Con la tua proposta» e «In dieci anni» li dà `MotoreSostituzione.calcola` (con penale, costi
   d'ingresso e tasse), non la formula semplificata del template. `calcola(attuale:alternativa:…)` vuole due `Posizione`:
   se l'estratto è di una posizione già in Prisma si usa quella (con `costoAnnuo`, `totaleVersato`, `condizioni`
   aggiornati solo dopo conferma); se non c'è (estratto di un'altra banca mai registrato), Prisma costruisce una
   `Posizione` **provvisoria, in memoria e mai salvata** dai campi letti (valore, versato, costo annuo = somma delle voci
   annue, penale), e la card lo dice («posizione non registrata: crea la posizione per salvarla»). Il rendimento lordo e
   l'orizzonte sono quelli delle ipotesi di Prisma (`IpotesiCalcolo.rendimentoPredefinito` = 3% e
   `orizzontePredefinito` = 10 anni, `Motori/Proiezione.swift`), non il 5% del template: le cifre quindi cambiano, e la
   didascalia scrive il rendimento usato. Se si vuole il conto «solo costi, a parità di
   mercato» del template, va scritto così e senza penale: vedi decisioni.
4. **Vista**: `Shell/SmontaggioApple.swift` (`SmontaggioApple`), `Shell/StatoSmontaggio.swift` (documento, righe,
   immagine in memoria, risultato, alternativa scelta). Componenti nuovi: `CerchioAMano` (ellisse con `trim` e
   rotazione), `NotaRichiamo` (nota con la linea), `FoglioAnnotato` (immagine o foglio ricostruito con le annotazioni
   sopra, riusabile nella Biblioteca e nella presentazione).
5. **Campi nuovi dell'archivio** (solo se il documento si conserva): `Documento.costiTrovati: [VoceCostoTrovata]?`,
   letto con `decodeIfPresent`. Nella prova del backup: un documento con due voci torna uguale.
6. **Ponte**: nessun messaggio nuovo; `InquadraturaPonte` va bene. Va solo deciso sul Mac quale motore legge le righe
   (dipende dalla vista attiva o da una scelta sull'iPhone: «Polizza» o «Costi»).
7. **Prove**: `ProvaCalcoliSmontaggio` (`Motori/`): le cinque righe del template, con valore 90.000 e un versato di
   78.000 dato dalla prova (il template non lo scrive), danno 1.890, 100, 1.950, 2.700 e la performance «mancante» se
   manca l'importo; senza versato i costi d'ingresso restano senza cifra; costo annuo 2.410 quando la performance è scritta (420); voce più pesante
   78%; diritti fissi a trimestre ×4; una riga senza numero non diventa un costo.

#### 8.2.6 Dati che l'utente deve dare (mai inventarli) e stati vuoti
1. **Il documento** del cliente (estratto, rendiconto annuale, KID, «costi e oneri» della MiFID): inquadrato o trascinato.
2. **Il valore della posizione** a una data: dal documento o dalla posizione in Prisma. Senza, le percentuali restano
   percentuali («2,10% l'anno · cifra non calcolabile senza il valore»).
3. **Il versato**: per i costi d'ingresso già pagati. Senza: «costi d'ingresso: 2,50% del versato · versato non
   indicato».
4. **Gli importi addebitati** della performance (e, se ci sono, della gestione): solo dal documento.
5. **L'alternativa**: una proposta del cliente o una scheda di Prodotti con i costi (`costoAnnuo`, `costoIngresso`).
   Senza, la card 2 chiede di sceglierla e il pulsante «Crea la proposta di sostituzione» è spento.
6. **Il rendimento lordo** dell'ipotesi: quello delle ipotesi di Prisma, che l'utente vede e può cambiare.
7. Stati vuoti: vedi 1.4.

#### 8.2.7 Istantanee da aggiungere
| Nome | Scena |
|---|---|
| `880-posizioni-smontaggio` / `-scuro` | documento di prova di Giulia con le cinque ellissi e le quattro note, card con proposta (come `08-smonta-*`) |
| `881-posizioni-smontaggio-vuoto` / `-scuro` | nessun documento: invito a inquadrare o trascinare |
| `882-posizioni-smontaggio-senza-proposta` | costi trovati, card 2 con «Scegli un prodotto da confrontare» |
| `883-posizioni-smontaggio-mancanti` | performance senza importo (ellisse tratteggiata), versato mancante |
| `884-posizioni-smontaggio-fumetto` | fumetto del conto su un'ellisse |
| `885-posizioni-testata-quattro-viste` / `-scuro` | testata con i quattro segmenti e «Inquadra con l'iPhone» (sostituisce lo scatto della testata in `600-posizioni-testata-inquadra`) |
| `886-posizioni-smontaggio-stretta` | finestra alla larghezza minima |

#### 8.2.8 Regole di CLAUDE.md toccate e decisioni per l'utente
Regole: Posizioni fulcro dell'analisi (lo smontaggio è analisi dei costi); il canale va mostrato (la posizione
analizzata e la proposta portano l'etichetta del canale nella card 1 e nella card 2: il template non la mostra); documenti
su carta; valori in `DesignSystem`; movimento e istantanee; i calcoli li fa Prisma.

**Uscite dal Mac e privacy:**
- **Fotocamera dell'iPhone** (già in Orizzonte §9): la foto dell'estratto del cliente (di un'altra banca) resta in
  memoria; le righe passano sul ponte cifrato della rete locale. Niente esce dalla rete di casa o dello studio.
- **Conservare il documento**: se l'estratto entra nel dossier, entra senza foto (regola di Inquadra), quindi riaprendo
  lo smontaggio il foglio è il «foglio ricostruito» (`FoglioRicostruito`, `AnteprimaDocumento.swift:107`), non la foto.

Decisioni:
1. **Tenere la foto dell'estratto?** Per rivedere le ellissi sul documento vero servirebbe tenere l'immagine nella
   cartella Documenti (dato patrimoniale di un'altra banca). Proposta: si tiene solo se l'utente lo chiede («Conserva
   l'immagine»), altrimenti foglio ricostruito.
2. **Il conto a dieci anni**: il template confronta solo i costi correnti (ignora penale di uscita, costo d'ingresso del
   nuovo prodotto e tasse). Proposta: usare `MotoreSostituzione`, che li conta, e scrivere «con la penale, i costi
   d'ingresso e le tasse». Se l'utente vuole anche la cifra «solo costi» del template, va accanto e chiamata così.
3. **«Pagata anche in un anno in cui il fondo ha reso meno dell'inflazione»** richiede il rendimento dell'anno (dal
   documento) e l'inflazione dell'anno (serie FOI in Prisma, già presente, o Mercato). Senza uno dei due la nota non
   compare.
4. **Commissione di performance**: senza l'importo addebitato Prisma non la stima (non conosce l'indice né il suo
   andamento). Va bene così?
5. **Canale della proposta**: se la posizione smontata è di un'altra banca e la proposta è Alleanza, la card 2 lo dice
   con l'etichetta blu; se la proposta è indipendente, con quella cuoio. Va scelto quale proposta mostrare per prima
   quando ce ne sono di tutti e due i canali (proposta: quella con il costo più basso, con il canale ben visibile).
6. **Testi normativi**: nessuno. Le definizioni dei costi (ex ante / ex post MiFID) non si inventano: le etichette sono
   quelle del documento.
7. **API**: tutte già usate (Vision, PDFKit, `trim`). Nessuna sopra macOS 13.

---

### 8.3 Il radar del portafoglio

Voce del pannello Novità: **«Il radar del portafoglio»**, frase **«Chi si è allontanato dal suo modello»**, glifo
`radar`, colore #1E9E6A, azione `vaiA('posizioni',()=>{vistaP='radar'})` (2065). È la seconda vista di Posizioni.

#### 8.3.1 Cosa si vede

##### 8.3.1.1 Il radar (sinistra)
Una card larga 820 (a finestra piena, `luce/img/08-radar-scuro.png`: 831×661), senza padding, con fondo **scuro fisso
anche nell'aspetto chiaro**: gradiente radiale 600×420 al 50%/52% da #11283A a #081521, bordo `rgba(255,255,255,.06)`
(1939). Dentro, un SVG 820×654 (1944-1952):
- centro (410, 327), raggio **R = 260** per **15 punti** di distanza;
- **cerchi** a 10 e 15 punti (bianco 0,08) con le scritte **«10 punti»** e **«15 punti»** (11 pt, bianco 0,4) sopra il
  cerchio, a destra dell'asse;
- il **cerchio della tolleranza** a 5 punti: riempito verde (#34D399 al 6%), bordo #34D399 al 60% tratteggiato 4 6, con
  la scritta **«5 · tolleranza»** (11 pt, #34D399 all'85%);
- **tre settori**, uno per modello, divisi da tre raggi (bianco 0,08) che partono da ore 12 e ogni 120°; il nome del
  modello in maiuscolo, 13 pt grassetto, nel suo colore, a metà del settore, 24 fuori dal cerchio grande:
  - **PRUDENTE** (#30B15C) in alto a destra;
  - **EQUILIBRATO** (#0A84FF) in basso;
  - **DINAMICO** (#8B5CF6) a sinistra;
- il **fascio** che gira: uno spicchio di 0,55 radianti (circa 31°) con gradiente da #34D399 trasparente a #34D399 al
  28%, e il suo bordo (#34D399 al 70%, 1,5);
- un **punto per cliente** nel settore del suo modello, a una distanza dal centro proporzionale alla distanza dal modello
  (oltre 15 punti resta sul bordo). L'angolo dentro il settore è sparso in modo fisso (in radianti: `0,25 + ((k·0,37) mod 1)·(2π/3 − 0,5)` dall'inizio del
  settore, 1953):
  - i clienti con nome (i 5 del template) sono **avatar da 30** (raggio 15) con le iniziali (11 pt grassetto, bianco),
    bordo bianco 70% da 2, e il nome sotto (11,5 pt 600, bianco 85%);
  - gli altri (fittizi) sono **pallini da 14** grigio-azzurri (#9FB3C2 → #6B8199), bordo 1;
  - chi è **fuori tolleranza** (oltre 5 punti) ha un **anello arancio** (#FF9F0A, 2) che pulsa attorno (raggio 22 o 14).

##### 8.3.1.2 La colonna destra (da 836 al bordo, 1940-1942)
**Card «I TUOI PORTAFOGLI MODELLO»** (padding 20/22, senza ombra):
- per ogni modello: il nome in grassetto nel suo colore (13,5 pt) e a destra i pesi `.k` **«20 · 55 · 20 · 5»**; sotto
  (5) una barra alta 9, raggio 6, spazio 2, divisa in quattro pezzi: azioni #3B82F6, obbligazioni #5AC8FA, gestione
  separata #A78BFA, liquidità #34D399 (un pezzo a zero non si disegna: Dinamico non ha gestione separata);
- in fondo `.k` 12 pt: **«Azioni · obbligazioni · gestione separata · liquidità»**.

I modelli del template: Prudente 20/55/20/5, Equilibrato 40/40/12/8, Dinamico 65/25/0/10 (1934).

**Card del conteggio**:
- a sinistra **«9»** (`.v` a 40 pt, arancio) e **«clienti fuori tolleranza (oltre 5 punti)»**;
- a destra **«18»** (`.v` 22 pt) e **«sul radar»**;
- pulsante blu grande a tutta larghezza **«Riequilibra i 9 clienti»** (16 sotto);
- `.k`: **«Prepara le proposte di riequilibrio, una per cliente, con i costi e le tasse di ogni spostamento.»**

**Card «I PIÙ LONTANI DAL MODELLO»**: i tre clienti più lontani, una riga ciascuno (padding 8, filetto):
- avatar 28, nome 13,5 pt e **« · Dinamico»** in `.k`;
- barra arancio alta 6, larga 110, piena per distanza/15;
- distanza in grassetto, larga 62, a destra (**«12,4»**).

In fondo alla colonna, `.k`: **«Più un cliente è lontano dal centro, più il suo portafoglio si è allontanato dal modello
scelto. Tocca un punto per il dettaglio.»** (1943).

##### 8.3.1.3 Il dettaglio di un cliente (`espandi`, 880×470, 1954-1959)
Nasce dal punto toccato (`luce/img/08-radar-dettaglio-chiaro.png`):
- riga di testa:
  - avatar 54;
  - **«MODELLO EQUILIBRATO»** (`.lbl` nel colore del modello);
  - il nome a 26 pt grassetto;
  - a destra, 56 dal bordo per lasciare il ✕, **«9,5 punti»** (`.v`, arancio se oltre 5, verde se entro) e **«di
    distanza dal modello»**;
- quattro righe (24 sotto, spazio 12):
  - nome della classe (150 di larghezza, 14 pt);
  - binario alto 16, raggio 8, `--track`, con la barra della quota di oggi nel colore della classe e una **linea verticale
    di 2** (`--ink`, 4 più alta del binario sopra e sotto) dove sta il modello;
  - a destra **«50% / 40%»** (oggi in grassetto, modello in `.k`);
- `.k` **«La barra è oggi, la linea è il modello.»**;
- tile **«Il riequilibrio proposto»**: **«Spostare circa 20.000 € dalle azioni alle obbligazioni, con un costo stimato di
  81 €. Le tasse sulle eventuali plusvalenze le calcola il motore fiscale, quota per quota, prima che tu decida.»**;
- pulsante blu **«Prepara la proposta»** (nel template chiude soltanto).

Nel template la quota di oggi è inventata a partire dal modello e dalla distanza (azioni + d, obbligazioni − 0,7·d,
liquidità − 0,3·d, poi riportata a 100). La distanza così risulta **metà della somma degli scarti assoluti**: per Laura,
(9,5 + 6,65 + 0 + 2,85) / 2 = 9,5. È la misura proposta per Prisma (sottosezione 5): dice quanta parte del portafoglio va
spostata per tornare al modello. Anche lo «spostare circa 20.000 €» del template è distanza × patrimonio, arrotondato
alle migliaia.

##### 8.3.1.4 «Riequilibra i 9 clienti» (1960-1961)
- Il pulsante diventa **«Riequilibro…»**.
- I punti fuori tolleranza **scivolano verso il centro**, a una distanza fra 1,3 e 4,5 punti, in 1,6 s con una molla
  (`cubic-bezier(.34,1.2,.5,1)`).
- I loro anelli si spengono (900 ms, dopo 900 ms) e i nomi svaniscono (0,6 s).
- Il 9 conta all'indietro fino a **0** in 1,6 s.
- Dopo 1,7 s:
  - il pulsante dice **«✓ Proposte pronte»**;
  - lo 0 diventa verde;
  - l'avviso **«Proposte di riequilibrio pronte per i clienti fuori tolleranza»** (`luce/img/08-radar-fatto-chiaro.png`).

##### 8.3.1.5 Stati
| Stato | Cosa si vede |
|---|---|
| Nessun modello definito | il radar vuoto (solo i cerchi) con «Definisci i tuoi portafogli modello per vedere chi se ne allontana.» e il pulsante «Imposta i modelli» (Impostazioni › Portafogli modello) |
| Modelli sì, nessun cliente assegnato | radar con i settori e nessun punto; «Assegna un modello ai clienti» con l'elenco dei clienti che hanno investimenti |
| Clienti senza dati di composizione | punto vuoto (solo il bordo) e «composizione stimata» nel dettaglio, come `ComposizioneInvestimenti360.stimata` |
| Nessuno fuori tolleranza | il numero «0» verde, pulsante spento «Tutti entro la tolleranza» |
| Proposte pronte | vedi 1.4 e decisione 2 (i punti non si spostano finché la proposta non è eseguita) |
| Modalità cliente | la vista Radar non c'è (mostra tutti i clienti) |

#### 8.3.2 Misure e stile

| Elemento | Template | Prisma (token nuovi in `Tema.Apple+Posizioni.swift`, `enum Tema.Apple.Posizioni.Radar`) |
|---|---|---|
| Fondo del radar | radiale 600×420 al 50%/52%, #11283A → #081521, bordo bianco 6%; **uguale in chiaro e scuro** | `fondoCentro`, `fondoBordo`, `bordo` (fissi, come la sala della presentazione `Colore.sala`) |
| Geometria | R 260 su 654 di altezza (≈ 0,4 dell'altezza); scala 15 punti; cerchi 10 e 15; tolleranza 5 | `scalaPunti = 15`, `quotaRaggio = 0.40`, `anelli = [10, 15]` |
| Cerchi e raggi | bianco 8% | `filo = Color.white.opacity(0.08)` |
| Scritte dei cerchi | 11 pt, bianco 40% | `scrittaCerchio` |
| Tolleranza | #34D399: riempimento 6%, bordo 60% tratteggio 4 6, scritta 85% | **nuovo colore** `verdeRadar = #34D399` (non c'è in `TemaApple.swift`) |
| Fascio | spicchio 0,55 rad, gradiente #34D399 0 → 0,28, bordo 0,7 da 1,5 | `ampiezzaFascio = 0.55`, `fascio` |
| Nomi dei modelli | 13 pt 700 maiuscolo, colore del modello, a R + 24 | `nomeModello`, `distanzaNome = 24` |
| Punti | con nome raggio 15 (bordo 2, iniziali 11 pt 700, nome 11,5 pt 600 bianco 85% 32 sotto); senza nome raggio 7 (bordo 1), #9FB3C2 → #6B8199 | `puntoGrande = 15`, `puntoPiccolo = 7`; gradienti degli avatar esistenti |
| Anello fuori tolleranza | #FF9F0A, 2, raggio 22 / 14 | **nuovo colore** `arancioRadar = #FF9F0A` (diverso da `Colore.arancio` #E08A00: va bene sul fondo scuro) |
| Colori dei modelli | #30B15C, #0A84FF, #8B5CF6 | `Colore.Area.liquidita`, `Colore.Area.investimenti`, `Colore.stima` (esistono); nell'app il colore lo sceglie l'utente fra questi e altri del tema |
| Colori delle classi | azioni #3B82F6, obbligazioni #5AC8FA, gestione separata #A78BFA, liquidità #34D399 | **nuovi** `classeAzioni`, `classeObbligazioni`, `classeGestione`, `classeLiquidita`. Attenzione: `Colore.Composizione` di Analisi 360 usa altri colori (#0A84FF, #5AC8FA, #2563EB, #9FB3C2): vedi decisione 5 |
| Barre dei modelli | alte 9, raggio 6, spazio 2 | `BarraPienaSegmenti` (`GraficiApple.swift:131`) con altezza 9 |
| Cifra «9» | `.v` a 40 pt, arancio (`--orange` #E08A00) | `Carattere(dimensione: 40, …)` **nuovo** `Radar.fuori`; `Colore.arancio` |
| Cifra «18» | `.v` a 22 pt | **nuovo** `Radar.totale` |
| Barre dei più lontani | 110×6, arancio | `BarraPiena` alta 6 |
| Dettaglio | 880×470; binario 16 raggio 8; linea del modello 2, 4 oltre il binario; colonna valori 110 | `PresentatoreDettaglio` (`DettaglioApple.swift:255`); **nuovi** `Radar.Dettaglio.binario = 16`, `lineaModello = 2`, `sporgenza = 4` |
| Colonna destra | da 836 (radar 820 + 16) | proporzione 820 : 604 a finestra piena; il radar resta quadrato nel suo spazio (lato = altezza disponibile) |

#### 8.3.3 Movimento

| Cosa | Template | Prisma |
|---|---|---|
| Entrata delle card | `rimonta` + cascata `.st` | `Moto.Cascata` |
| Punti | compaiono in 500 ms, ritardo 200 + k·45 ms (1953) | **nuovo** `Tema.Apple.Moto.PuntiRadar` (0,50 / 0,20 / 0,045). Con molti clienti il passo si limita: `passo × min(k, 24)` (come in Orizzonte §2.3, dispersione) |
| Fascio | gira in 4,5 s, lineare, all'infinito (`.sweep`, 319) | `rotationEffect` con `Animation.linear(duration: 4.5).repeatForever(autoreverses: false)`, **nuovo** `Moto.FascioRadar.giro = 4.5`. Niente Timer |
| Anelli che pulsano | 1,9 s, ease-out, da scala 0,75 opacità 0,95 a scala 1,7 opacità 0, all'infinito (`.rPul`, 320) | `repeatForever`, **nuovo** `Moto.PulsoRadar` (1,90, scala 0,75 → 1,7) |
| Barre (modelli, più lontani, dettaglio) | `barre`: 1,2 s, 150 + i·90 ms | `Moto.Barra` |
| Numeri | `conteggi` | `Moto.Numero` |
| Dettaglio | `espandi`: 620 ms, `cubic-bezier(.32,1.22,.5,1)` | `Moto.DettaglioApre` (0,62, `Curva.dettaglioApre`) |
| «Riequilibra»: punti | verso il centro in 1,6 s, `cubic-bezier(.34,1.2,.5,1)` | **nuovo** `Moto.Riequilibrio` (1,60, curva `Curva(x1: 0.34, y1: 1.2, x2: 0.5, y2: 1)`; il superamento oltre 1 si fa già con `Curva.dettaglioApre`, y1 1,22) |
| «Riequilibra»: anelli e nomi | anelli 900 ms dopo 900 ms; nomi 0,6 s | `Riequilibrio.ritardoAnelli = 0.9`, `durataAnelli = 0.9`, `durataNomi = 0.6` |
| «Riequilibra»: contatore | 9 → 0 in 1,6 s (`conta`, 1961); verde, testo e avviso a 1,7 s | `NumeroCheConta` all'indietro; `Riequilibrio.esito = 1.7`; `Moto.Toast` |

**Riduci movimento.** Nel template il fascio si ferma (1944), ma gli anelli continuano a pulsare e le transizioni dei
punti restano. Nell'app con `\.prismaCalmo`:
- fascio fermo (o nascosto);
- anelli fermi, pieni e senza pulsazione;
- punti già al loro posto, numeri già al valore;
- dissolvenza di 0,15 s.

**Istantanee**: fascio fermo a un angolo fisso (proposta: −30°, sopra Prudente), anelli fermi al loro raggio di riposo,
punti e numeri nello stato finale.

**Consumo:** il fascio e le pulsazioni sono animazioni continue. Si fermano quando la vista Radar non è quella mostrata,
quando la finestra di Prisma non si vede (come l'acqua) e con «Riduci movimento». Con 200 clienti (`--prova-carico`) i
punti si disegnano in un solo `Canvas`; nomi e anelli solo per i punti fuori tolleranza e per quello sotto il puntatore.

#### 8.3.4 Interazioni

**Mac (template):**
- **Clic su un punto**: il dettaglio nasce dal punto (`espandi`), ✕ o clic fuori lo richiudono. Nel template, richiuso il
  dettaglio, il punto ricompare nell'angolo in alto a sinistra: `espandi` azzera il `transform` dell'elemento (546), che
  per i punti SVG è la loro posizione (si vede in `luce/img/08-radar-fatto-chiaro.png`, «fia» in alto a sinistra). È un
  difetto del template: nell'app il punto torna al suo posto.
- **«Riequilibra i N clienti»**: vedi 1.4; un secondo clic non fa nulla (`radFatto`).
- **«Prepara la proposta»** nel dettaglio: nel template chiude soltanto.

**Mac (nell'app):**
- **Passaggio sul punto**: fumetto con nome, modello e distanza; il punto cresce leggermente (`Moto.SuggerimentoSopra`).
- **Clic sul punto** → dettaglio (sopra). **Clic su una riga dei più lontani** → stesso dettaglio.
- **«Prepara la proposta»** (dettaglio): crea una bozza di riequilibrio per quel cliente (sottosezione 5) e la apre
  (Pratiche › Proposta, se c'è; altrimenti il dossier del cliente su Posizioni con le proposte).
- **«Riequilibra i N clienti»**: prepara una bozza per ciascun cliente fuori tolleranza; mostra l'avanzamento («3 di 9»)
  e alla fine «N bozze pronte · le trovi in …». Niente si esegue da solo.
- **Clic sul nome di un modello** (radar o card): Impostazioni › Portafogli modello, su quel modello.
- **Doppio clic sul punto**: dossier del cliente.
- **Tastiera**: Tab scorre i punti fuori tolleranza dal più lontano; Invio apre il dettaglio; Esc lo chiude.
- **VoiceOver**: ogni punto è un elemento («Laura Moretti, modello Equilibrato, 9,5 punti, fuori tolleranza»).

**iPhone e iPad:** il template non li prevede. Proposta: niente radar sui dispositivi in questo giro; se servirà, sarà un
elenco «I più lontani dal modello» (stessa card) con lo stesso motore.

#### 8.3.5 Mappa verso Prisma

##### 8.3.5.1 Esiste già (verificato con grep)
- **Composizione per classe** con le stesse quattro classi del template: `ComposizioneInvestimenti360.Classe`
  (`azionario`, `obbligazionario`, `gestioneSeparata`, `liquidita`) e `MotoreAree360.composizione(_:cliente:)`
  (`Motori/MotoreAree360.swift:36-79, 208-254`). Usa le posizioni in essere, finanziarie (`area.proiettabile` o
  liquidità), con `MotoreResistenza.composizione(_:)` (`Motori/CrisiStoriche.swift:148`):
  - quota azionaria della posizione o stimata dall'SRI;
  - multiramo diviso in fondi e gestione separata;
  - monetari come liquidità.
  Dà anche `perCanale` e `stimata`.
- **Profilo del cliente**: `ProfiloInvestitore.Propensione` (`prudente`, `moderata`, `dinamica`, `aggressiva`,
  `Dati/Modelli.swift:296-301`). Sono quattro, i modelli del template tre: non coincidono.
- **Fiscale**: `MotoreFiscale.calcola(_:prodotto:data:)`, `aliquotaGuadagno`, `bolloAnnuo`
  (`Motori/MotoreFiscale.swift:228-256`). Penali: `CondizioniContratto`, `MotoreRiscatto`. Costi d'ingresso:
  `Prodotto.costoIngresso`.
- **Proposte**: `Posizione.stato = .proposta`, `esito` (`EsitoProposta`, con `bozza`), `SeguitoProposte`.
- **Vista**: `VistaPosizioni`, `TestataVistePortafoglio`, `cambia(_:)` (vedi novità 2).
- **Componenti**: `BarraPienaSegmenti`, `BarraPiena`, `NumeroCheConta`, `PresentatoreDettaglio`, avatar dei clienti.
- **Modalità cliente**: `appRiservate` (`Shell/ModoCliente.swift:8`) è per app, non per vista.

##### 8.3.5.2 Cosa manca
1. **Portafogli modello** (nuovo modello, `Dati/PortafogliModello.swift`):
   - `PortafoglioModello`:
     - `id`, `nome`, `colore` (un nome di colore del tema, non un esadecimale libero);
     - `pesi: [ComposizioneInvestimenti360.Classe: Double]` (somma 100);
     - `tolleranza: Double?` (nil = quella generale);
     - `note`.
   - `DatiPrisma.portafogliModello: [PortafoglioModello] = []` e `Impostazioni.tolleranzaRadar: Double?` (nessun valore
     predefinito inventato: vedi dati).
   - `Cliente.modelloId: String?` (`Dati/Modelli.swift`, letto con `decodeIfPresent`).
   - Tutto con `decodeIfPresent` e nella prova del backup.
2. **Motore** `MotoreRadar` (`Motori/MotoreRadar.swift`):
   - per ogni cliente con un modello: `composizione = MotoreAree360.composizione(posizioni, cliente:)`;
   - **distanza** = ½ · Σ |quota_i − peso_i| sulle quattro classi, in punti percentuali (0…100);
   - `fuori` = distanza > tolleranza;
   - `daSpostare` = distanza / 100 × totale;
   - `stimata` dalla composizione;
   - `perCanale` delle classi.
   - **Spostamenti**: dalle classi in eccesso a quelle in difetto, con l'importo di ciascuno («circa 20.000 € dalle azioni
     alle obbligazioni»), arrotondati alle migliaia solo nella frase.
   - **Costo di uno spostamento**: per le posizioni che si vendono, penale (`MotoreRiscatto`) e tasse sulla plusvalenza
     (`MotoreFiscale`, quota per quota); per quelle in cui si entra, il costo d'ingresso del prodotto scelto. Se non è
     scelto il prodotto di arrivo, il costo d'ingresso non c'è e la frase lo dice («costo di ingresso: dipende dal
     prodotto che scegli»). **Mai una percentuale fissa** come lo 0,4% del template.
   - Esito: `RadarPortafoglio` con `voci: [VoceRadar]` (cliente, modello, distanza, fuori, quote, spostamenti, stimata),
     `fuori`, `totale`, `senzaModello` (clienti con investimenti ma senza modello).
   - Posizione sul radar: settore del modello (N modelli → N settori uguali; con 1 modello il cerchio intero); angolo
     dentro il settore fisso per cliente (da un numero calcolato dall'`id`, non casuale) con un passo che allontana i punti
     sovrapposti; raggio = min(distanza, scala) / scala.
3. **Bozze di riequilibrio**: una proposta per cliente con le posizioni da ridurre e quelle da aumentare (o da aprire),
   `stato = .proposta`, `esito = .bozza`, con un `motivo` «Riequilibrio verso il modello Equilibrato» (campo nuovo
   `Posizione.origine` o la nota: da allineare con la parte di Pratiche). Il canale di ogni posizione resta il suo: un
   prodotto Alleanza si ribilancia con prodotti Alleanza o con le sue linee (`MotoreMultiramo`), mai spostando denaro da
   un canale all'altro senza che l'utente lo scelga.
4. **Viste**: `VistaPosizioni.radar`; `Shell/RadarPortafoglio.swift` (radar in `Canvas` + colonna destra + dettaglio),
   `Shell/StatoRadar.swift` (selezione, avanzamento delle bozze). Componenti nuovi: `RadarModelli` (fondo, settori,
   cerchi, fascio, punti) e `BarraConModello` (binario con la barra di oggi e la linea del modello).
5. **Impostazioni**: pagina nuova «Portafogli modello» in Impostazioni:
   - elenco dei modelli con i quattro pesi (cursori o campi; la somma deve fare 100, altrimenti «mancano 5 punti»);
   - tolleranza generale;
   - per ogni modello, i clienti assegnati.
   Nel dossier del cliente (scheda del profilo): «Portafoglio modello» con il menu dei modelli.
6. **Prove**: `ProvaCalcoliRadar` (`Motori/`):
   - la distanza di Laura (50/33/12/5 contro 40/40/12/8) è 9,5;
   - un cliente uguale al modello è a 0;
   - classi a zero escluse correttamente;
   - gli spostamenti sommano a `daSpostare`;
   - nessun cliente senza modello finisce sul radar;
   - con la composizione stimata la voce è segnata «stimata».

#### 8.3.6 Dati che l'utente deve dare (mai inventarli) e stati vuoti
1. **I portafogli modello**: nomi e pesi delle quattro classi. Quelli del template (20/55/20/5, 40/40/12/8, 65/25/0/10)
   sono dimostrativi e possono stare solo nei dati di prova.
2. **La tolleranza** (il template usa 5 punti): generale ed eventualmente per modello.
3. **Il modello di ogni cliente**: lo assegna l'utente. Prisma può proporre un abbinamento fra propensione e modello
   (una tabella che l'utente compila una volta: «Prudente → Prudente, Moderata → Equilibrato, …»), mai in silenzio.
4. **Le composizioni delle posizioni**: quota azionaria, titoli di Stato, quota in gestione separata dei multiramo. Senza,
   Prisma le stima come oggi e lo dice («composizione stimata dall'SRI»).
5. **Quali aree contano**: vedi decisione 3.
6. **Il prodotto di arrivo** di ogni spostamento, per il costo d'ingresso.
7. Stati vuoti: vedi 1.5. Il numero «sul radar» conta solo i clienti con un modello e degli investimenti; accanto,
   «12 clienti senza modello» porta all'elenco per assegnarlo.

#### 8.3.7 Istantanee da aggiungere
| Nome | Scena |
|---|---|
| `890-posizioni-radar` / `-scuro` | dati di prova: tre modelli, 18 clienti, 9 fuori tolleranza, fascio fermo (come `08-radar-*`) |
| `891-posizioni-radar-dettaglio` / `-scuro` | dettaglio di Laura (9,5 punti, barre e linee del modello, riequilibrio) |
| `892-posizioni-radar-dentro` | dettaglio di un cliente entro la tolleranza (cifra verde) |
| `893-posizioni-radar-senza-modelli` / `-scuro` | nessun modello: radar vuoto e invito |
| `894-posizioni-radar-bozze` | dopo «Riequilibra»: bozze pronte, punti al loro posto con il segno della proposta (decisione 2) |
| `895-posizioni-radar-carico` | 200 clienti (`--prova-carico`): leggibilità e tempo di disegno |
| `896-impostazioni-modelli` / `-scuro` | Impostazioni › Portafogli modello |
| `897-posizioni-radar-stretta` | finestra alla larghezza minima |

#### 8.3.8 Regole di CLAUDE.md toccate e decisioni per l'utente
Regole:
- Posizioni fulcro dell'analisi: il radar è analisi del portafoglio di tutti i clienti.
- Canale sempre riconoscibile: il template non mostra il canale. Nell'app ogni barra di classe nel dettaglio si divide per
  canale come in Analisi 360 (`perCanale`), e la bozza dice per ogni spostamento il canale.
- Valori in `DesignSystem`; movimento, «Riduci movimento» e istantanee.
- Memoria: `Canvas` e animazioni continue fermate quando non si vedono.
- Backup e prova aggiornati con i campi nuovi.

**Uscite dal Mac e privacy:** nessuna (tutto calcolato sul Mac). Il radar mostra **tutti i clienti con i nomi**: non deve
comparire davanti a un cliente.

Decisioni:
1. **Modalità cliente**: proposta di nascondere la vista Radar (il segmento non c'è) quando la modalità cliente è accesa.
   Oggi `appRiservate` lavora per app: serve una regola per vista.
2. **Che cosa fa «Riequilibra»**: nel template i punti tornano al centro come se il portafoglio fosse già
   riequilibrato. Nella realtà Prisma prepara solo delle bozze di proposta. Proposta:
   - i punti restano dove sono;
   - un segno (anello tratteggiato verde attorno al punto) dice «proposta pronta»;
   - un trattino mostra dove andrebbe il punto con la proposta;
   - il contatore resta 9, con la scritta «9 bozze pronte».
   I punti si spostano solo quando le posizioni cambiano davvero. Da confermare.
3. **Quali posizioni contano**: investimento, risparmio, previdenza e liquidità in essere (come
   `MotoreAree360.composizione`)? Un fondo pensione non si ribilancia come un fondo: proposta di escludere la previdenza
   dal radar, o di darle un interruttore per modello.
4. **Modelli e propensione**: i modelli del template (tre) non coincidono con le propensioni di Prisma (quattro). Il
   modello è un dato del consulente, separato dal profilo MiFID del cliente? Proposta: sì, con il controllo che il modello
   assegnato non superi il rischio del profilo (`MotoreCoerenza.sriMassimo`): se lo supera, avviso nel dettaglio.
5. **Colori delle classi**: il template usa per le classi colori diversi da quelli della composizione di Analisi 360
   (`Colore.Composizione`). Proposta: usare gli stessi di Analisi 360, perché la stessa classe abbia lo stesso colore in
   tutta Prisma. In alternativa si cambiano quelli di Analisi 360 con quelli del template. Attenzione: la stessa
   tavolozza del radar (#3B82F6, #5AC8FA, #A78BFA, #34D399) torna in un'altra novità di Luce, la composizione della Sala
   (`luceDati`, 1512, parte 02): la scelta va fatta una volta per tutte e due.
6. **Radar scuro anche nell'aspetto chiaro**: il template lo vuole così (come la sala). Da confermare, perché è l'unica
   card scura in una finestra chiara.
7. **Testi sulla tassazione**: «le tasse … le calcola il motore fiscale, quota per quota» va bene solo dove
   `MotoreFiscale` ha i dati (prezzo di carico o versato). Dove mancano, la frase diventa «tasse da calcolare: manca il
   versato di …». Nessuna aliquota nuova da inventare.
8. **Ribilanciamento fra canali**: si può proporre di spostare denaro da un prodotto indipendente a uno Alleanza (o al
   contrario) nella stessa bozza? Proposta: no di base; la bozza resta dentro il canale di ogni posizione e un
   interruttore lo permette caso per caso, con l'etichetta del canale ben visibile.
9. **API**: `Canvas` è di macOS 12, `repeatForever` e `rotationEffect` di sempre: nessuna API sopra macOS 13.

---

### Difetti del template (da non copiare)

| Novità | Difetto | Righe | Nell'app |
|---|---|---|---|
| Biblioteca | Risponde per parole chiave: «deduc» o «fondo» → deducibilità, «temporanea» o «pag» → temporanea (anche «pagina» o «pagare»), tutto il resto → riscatto. Qualsiasi domanda ha una risposta, anche se i documenti non ne parlano | 1919 | Ricerca vera (`MotoreBiblioteca`) e stato «non trovata» (1.5) |
| Biblioteca | Le righe dei documenti nella barra laterale non sono cliccabili (`mount` collega solo i suggerimenti e il modulo) | 1919 | Clic apre il documento intero (sottosezione 4) |
| Biblioteca | Con Riduci movimento l'evidenziatore si stende lo stesso in 1,3 s (transizione CSS di `.hlS`) | 318, 1930 | Già steso, dissolvenza 0,15 s |
| Biblioteca | «ho letto 38 pagine»: Ruby legge solo i passi scelti | 1920 | Decisione 2 della Biblioteca |
| Biblioteca | La cifra di prova della deducibilità (5.164,57 €) è superata rispetto a Prisma (5.300 € dal 2026) | 1908 | Decisione 7 della Biblioteca |
| Smontaggio | «Inquadra un altro documento» e «◎ Inquadra con l'iPhone» aprono la scena di Orizzonte con la «Polizza Vita Intera», non un estratto conto | 1102, 1976, 2084 | Scena di Inquadra con le righe a `MotoreSmontaggio` |
| Smontaggio | Il conto a dieci anni ignora penale, ingresso del nuovo prodotto e tasse; il 5% lordo è fisso | 1968-1969 | `MotoreSostituzione`, ipotesi di Prisma (decisione 2) |
| Smontaggio | Con Riduci movimento le note restano animate | 1975 | Tutto fermo |
| Radar | `espandi` azzera il `transform` dell'elemento toccato: per i punti SVG è la posizione, e il punto finisce in alto a sinistra quando il dettaglio si chiude | 546, 1954 | Il punto resta al suo posto |
| Radar | Con Riduci movimento si ferma solo il fascio: anelli che pulsano, comparsa dei punti e scivolata di «Riequilibra» restano animati | 320, 1944, 1953, 1960 | Tutto fermo |
| Radar | «Riequilibra» sposta i punti verso il centro come se i portafogli fossero già riequilibrati; il costo è lo 0,4% fisso dello spostamento; la quota di oggi è ricavata dal modello e dalla distanza | 1955-1960 | Bozze, costi dai motori, composizione vera (decisione 2, sottosezione 5) |
| Radar | «Prepara la proposta» nel dettaglio chiude soltanto | 1959 | Crea la bozza |

---

### Riepilogo per chi implementa

| | Biblioteca | Smontaggio | Radar |
|---|---|---|---|
| Vista | `AppBiblioteca` (app nuova) | `VistaPosizioni.smontaggio` | `VistaPosizioni.radar` |
| Motore | `MotoreBiblioteca` (passi, BM25) + `BibliotecaRuby` (Qwen, verifica della frase) | `MotoreSmontaggio` + `MotoreSostituzione` | `MotoreRadar` su `MotoreAree360.composizione` |
| Dati nuovi | `DocumentoBiblioteca`, `DatiPrisma.biblioteca`, cartella `Biblioteca/` | `Documento.costiTrovati` (facoltativo) | `PortafoglioModello`, `DatiPrisma.portafogliModello`, `Cliente.modelloId`, tolleranza |
| Ruby | `Ruby/Istruzioni/biblioteca.md`, `Ruby/Schemi/biblioteca.json` | nessuno (note di Prisma) | nessuno |
| Token | `Tema.Apple.Biblioteca`, `Moto.GiroPagine`, `Moto.Evidenzia` | `Tema.Apple.Posizioni.Smontaggio`, `Moto.Cerchio` | `Tema.Apple.Posizioni.Radar`, `Moto.PuntiRadar`, `Moto.FascioRadar`, `Moto.PulsoRadar`, `Moto.Riequilibrio` |
| Prove | `ProvaCalcoliBiblioteca`, `ProvaRuby`, `--prova-backup` | `ProvaCalcoliSmontaggio`, `--prova-backup` | `ProvaCalcoliRadar`, `--prova-backup`, `--prova-carico` |
| Istantanee | 870-877 | 880-886 | 890-897 |
| Esce dal Mac | niente | righe dall'iPhone sul ponte locale (già in Orizzonte) | niente |

---

## 9. Clienti: nuovo cliente in 10 secondi, potenziali e passaparola, imprenditori; Messaggi: campagne

*Parte 09 · quattro novità «per il tuo lavoro» (pannello Novità, `NOVL` righe 2064-2066: voci 9, 10, 11 e 12, cioè
`NOVL[8]` Le campagne, `NOVL[9]` Nuovo cliente in 10 secondi, `NOVL[10]` Potenziali clienti e passaparola, `NOVL[11]` I
clienti imprenditori).*

Fonte: `Design/template-luce.html` (5 novembre 2026). Le righe citate sono di quel file. Per tutto ciò che qui non è detto
valgono `Design/template-novita-specifica.md` («Orizzonte»: §5 Messaggi, §7 Linea della vita, §9 Inquadra e capisci),
`Design/template-apple-specifica.md` e la parte comune di Luce (`luce/01-comune.md`: glifi `scan`, `albero`, `azienda`,
`campagna` §4.1; telefono disegnato e velo della scena §4.2; sovrapposizioni §4.5; `NovitaLuce` e `apriVoceNovita`;
testate delle app con i segmentati). **Le cifre e i nomi del template sono dimostrativi**: nell'app vengono dai motori di
Prisma e dai dati dell'archivio; dove un dato manca Prisma lo dice, non lo inventa.

**Schermate di lavoro** (non nel repository, si rigenerano con `luce/script/shot09.js`, Playwright, 1480×940, palco
1440×900 scalato di 1,0137, `c` chiaro e `s` scuro): `luce/img/09-{c,s}-nuovo-0.png` (0,5 s: «Leggo il documento»),
`-nuovo-1.png` (a metà della cascata), `-nuovo-fine.png`, `-nuovo-toast.png`, `-rubrica.png`, `-pot.png`,
`-pot-sposta.png` (una scheda in volo), `-pot-cliente.png` (Sara Villa arrivata in «Cliente»), `-pass-inizio.png`,
`-pass.png`, `-pass-chiedi.png`, `-azienda.png`, `-camp-inizio.png`, `-camp.png`, `-camp-btp.png`, `-camp-avviata.png`.
Nel template un clic sul gruppo «BTP in scadenza» cade sui pallini dei clienti, che stanno sopra il cerchio e catturano il
clic (lo script lo forza con `{force:true}`): in Prisma tutta l'area del gruppo, pallini compresi, sceglie il gruppo (§4.4).

**Funzioni d'appoggio del template** usate qui (righe 382-401, 845-846, 1181): `conteggi` (numeri contati, 1100 + min(i,6)·60
ms), `entrata` (cascata `.st`), `inclina` (schede che si inclinano, `data-max`), `anello` (anello SVG), `barre` (`.bar8 i`
che si allungano: 1,2 s `--out`, ritardo 150 + i·90), `toast` (2,4 s), `rimonta` (cambio di vista: 0,13 s di uscita, poi
entrata e conteggi), `vaiA` (apre un'app con uno stato preparato), `nm` (il nome di battesimo), `avatar`, `eur`. In Prisma
corrispondono a `NumeroCheConta` (`DesignSystem/Apple/CifreApple.swift:77`), `EntrataApple`
(`DesignSystem/Apple/CascataApple.swift:69`), `SchedaInclinabileApple` (`DesignSystem/Apple/SchedeApple.swift:40`),
`Anello`/`AnelliConcentrici` (`DesignSystem/Apple/AnelliApple.swift:104`, `:28`), `BarraPiena`
(`DesignSystem/Apple/GraficiApple.swift:28`), `SegmentatoPillola` (`DesignSystem/Apple/ControlliApple.swift:19`),
`AvatarCliente` (`DesignSystem/Componenti.swift:698`), al toast della shell (`Tema.Apple.Moto.Toast`) e a
`StatoShell.apri(_:)` (`Shell/StatoShellFinestre.swift:90`).

**Numeri delle istantanee.** In `Sources/` la serie più alta è 613; le altre parti di Luce usano 620-632 (comune), 640-668
(Sala), 700-736 (relazione), 760-789 (notte, voce, spese), 800-836 (Pratiche, Biblioteca, analisi). Qui: **840-849**
nuovo cliente, **850-857** potenziali e passaparola, **858-861** azienda, **862-869** campagne. iOS: **75-77** (le parti
di Luce arrivano a 74). Tutte nello stato finale (`\.modoIstantanea` + `\.prismaStatoFinale`), 1440×900, chiaro e
`-scuro` dove detto.

**Archivio.** Oggi `DatiPrisma.versioneAttuale = 26` (`Dati/DatiPrisma.swift:113`). I campi nuovi di questa parte vanno
nella versione unica di Luce (27, decisa una volta sola con le altre parti), tutti facoltativi e letti con
`decodeIfPresent` (o `try?` come `conformita`, `fiscale`, `consensoCopilota` in `Dati/Modelli.swift:130-138`), nel backup
e in `Prisma --prova-backup` con una prova nuova `Dati/ProvaBackupLuceClienti.swift` (nome proposto; stile di
`Dati/ProvaBackupMessaggi.swift`). `Cliente.luogoNascita` è già proposto dalla parte 07 (Pratiche, §2.5 punto 5): qui si
usa lo stesso campo, non se ne crea un secondo.

**Testate delle app in Luce** (parte comune, tabella delle testate): Clienti ha il segmentato **Rubrica · Potenziali ·
Passaparola** e il pulsante blu **«Nuovo cliente»** con il glifo `scan` (righe 2078-2080); Messaggi ha il segmentato
**Messaggi · Campagne** (righe 2075-2077). In Prisma le azioni della testata stanno in `ContenutoApp.azioni`
(`Shell/ContenutoApp.swift:68-80`): `case .clienti: AzioneNuovoCliente()` (riga 70) cambia, `case .messaggi` oggi non
c'è e va aggiunto (`AzioniMessaggi`, come `AzioniStudio` in `Shell/StudioApp.swift:161`).

---

### 9.1 Nuovo cliente in 10 secondi

*Voce Novità 10 (gruppo «Per il tuo lavoro»): «Nuovo cliente in 10 secondi · La carta d'identità compila l'anagrafica»,
glifo `scan` su #5B4BC8 (`NOVL[9]`, riga 2065): `vaiA('clienti', vistaC='rub')`, poi `apriNuovo()` dopo 400 ms se Clienti
era già davanti, 900 ms se no. Pulsante «Nuovo cliente» della testata di Clienti (riga 2079, `#bNuovo`, `onclick =
apriNuovo`, riga 2080). Codice: righe 2000-2014; CSS `.phone` 204-206, `#scan` 207, `.cam` 208, `.linea` 212 e
`@keyframes scansiona` 213, `.cie` 326, `.ciF` 327, `.ciR` 328-329, `.mrz` 330, `.tile` 127, `.prep` 130-133, `.sfera`
72-74; chiusura `chiudiScanner` 1112.*

#### 9.1.1 Cosa si vede

**1.1 La scena.** Si apre sopra tutto il palco il velo della scena (`#scan`: rgba(6,14,20,.55) con sfocatura 8, z 97,
parte comune §4.2), con **due oggetti**: a sinistra l'iPhone disegnato, a destra la scheda «Prisma sul Mac». È la stessa
scena di «Inquadra e capisci» (Orizzonte §9) e della nota vocale (parte 06): cambia il contenuto.

**1.2 L'iPhone** (riga 2000-2003). Telefono 300×620 a sinistra 280, in alto 100 nel palco. Lo schermo (#1a1d21) è la
fotocamera (`.cam`: radiale 500×400 a 40%/30%, da #4a423b a #1f1b18). Dentro, una **carta d'identità fac-simile**
(`.cie`): a 20 dai lati, 150 dall'alto dello schermo, sfumatura 135° #EDF1F4 → #D2DDE5, raggio 10, padding 12, ruotata
di +2°, ombra 0 20 40 nero .5, testo #1b2530:
- riga di testa: **«CARTA D'IDENTITÀ»** (8,5, grassetto, spaziatura 0,8) a sinistra e **«FAC-SIMILE»** (7, spaziatura
  0,5) a destra;
- sotto (8 di spazio), la **foto** (`.ciF`, 62×80, raggio 6, sagoma grigia disegnata con due gradienti radiali su
  #BCC9D2) e, a destra, cinque campi impilati (`.ciR`: etichetta 6,5 maiuscola #5a6873 sopra, valore 10 grassetto
  #1b2530, padding 2/4, raggio 4): **COGNOME** «MARCHI», **NOME** «ELENA», **NATA IL** «03.04.1990», **A** «BOLOGNA (BO)»,
  **SCADENZA** «03.04.2031»;
- sotto, a tutta larghezza (6 sopra), **CODICE FISCALE** «MRCLNE90D43A944S»;
- la **zona a lettura ottica** (`.mrz`, monospazio 7,5, spaziatura 0,8, #33424D, interlinea 1,4): «C<ITACA00000AA0<<<<<<»
  / «MARCHI<<ELENA<<<<<<<<».

Sopra la carta scorre la **linea verde** di scansione (`.linea`: alta 3, a 18 dai lati, sfumatura orizzontale
trasparente → #34C759 → trasparente, alone 18 #34C759; scende da 110 a 420 in 1,1 s ease-in-out e torna su, due corse,
poi resta in alto). In basso, a 22 dal fondo, centrata, la scritta di stato (12,5, 600, bianca): **«Inquadra il
documento»** → **«Riconosco i dati…»** (dal primo campo) → **«✓ Fatto»**. Ogni campo riconosciuto si accende sulla carta
(`.ciR.vista`: anello verde #34C759 da 1,5 e fondo verde .14, transizione 0,4 s).

**1.3 La scheda «Prisma sul Mac»** (`#ncMac`, righe 2004-2006). Card piena (`--cardE`) a sinistra 680, in alto 130,
larga 480, padding 22/24, raggio 22 (`.card`):
- **testata**: la sfera di Ruby «viva» (26) + etichetta `.lbl` **«NUOVO CLIENTE · PRISMA SUL MAC»** + a destra il
  pulsante **«✕»** (`.btn`, padding 6/10);
- **riga del cliente** (14 sopra, spazio 14): avatar 56 con le iniziali (19, bianche) su sfumatura verde #9ED3C0 →
  #4E9C83, all'inizio **opaco al 25%**; accanto il **nome** (display 24, 700), all'inizio **«…»**, e sotto il
  sottotitolo `.k` **«Leggo il documento»**; a destra, allineati a destra, `.k` **«secondi»** e il **contatore** (display
  24, 700, cifre tabellari) che parte da «0,0» e sale di un decimo alla volta (riga 2008);
- **righe lette** (`#ncR`, 12 sopra): compaiono una alla volta, ciascuna padding 8/0, filo in basso, 14 pt, spazio 10:
  **«✓»** verde grassetto, etichetta `.k` larga 140, valore in grassetto. Le cinque righe del template (riga 2009):
  1. «Nome e cognome» → **«Elena Marchi»**;
  2. «Nata il» → **«3 aprile 1990, a Bologna»**;
  3. «Codice fiscale» → **«MRCLNE90D43A944S · ✓ coerente»**;
  4. «Documento» → **«carta d'identità · scade nel 2031»**;
  5. «Età» → **«36 anni»**.
  Con la prima riga il nome diventa «Elena Marchi» e l'avatar si accende (opacità 1).
- **a lettura finita** (riga 2013): il contatore si ferma (nella schermata **«3,6»**), il sottotitolo diventa
  **«Anagrafica completa»**, il telefono dice «✓ Fatto», e sotto le righe entra (`#ncAz`):
  - una tile (`.tile`, 12 sopra) con il titolo **«Moduli già pronti da firmare»** (13,5 grassetto) e due voci `.prep ok`
    (cerchio verde pieno con la spunta, padding 6/0): **«Informativa privacy»**, **«Adeguata verifica (antiriciclaggio)»**;
  - 14 sotto, il pulsante blu grande **«Crea il dossier di Elena»** (`.btn.pri.big`).
- **dopo «Crea»**: la scena si chiude (0,22 s) e il toast dice **«Dossier di Elena Marchi creato, con i moduli da
  firmare»** (riga 2014).

Nota sul template: le righe accendono sulla carta i campi `ci0`…`ci4` nell'ordine, quindi «Codice fiscale» accende «NATA
IL» e «Età» accende «SCADENZA» più il codice fiscale (riga 2010). È un artificio della dimostrazione: in Prisma ogni riga
accende **il riquadro vero** da cui viene il dato (`CampoInquadrato.riquadro`, `Motori/MotoreInquadra.swift:59-64`).

**1.4 Stati che il template non disegna** (vanno aggiunti, coerenti con la scena di Inquadra, `FaseInquadra` in
`Shell/StatoInquadra.swift:24-…`):
- **In attesa dell'iPhone** (ponte acceso, nessun documento ancora): telefono con la fotocamera vuota e «Inquadra il
  documento»; scheda con l'avatar spento, nome «…», sottotitolo **«Inquadra la carta d'identità con l'iPhone: qui
  arrivano solo i dati letti»**, contatore fermo a «0,0», e la zona tratteggiata **«oppure trascina qui una foto o un PDF
  del documento»** (come `ZonaInquadra`, `Shell/ScenaInquadra.swift:521`).
- **Ponte spento** (Impostazioni › Ruby › iPhone e iPad): solo la zona per trascinare, con «Per usare l'iPhone accendi il
  collegamento in Impostazioni › Ruby › iPhone e iPad».
- **Lettura parziale**: le righe che mancano restano con il segno grigio «—» al posto della spunta e il valore
  `coloreMancante` «non letto: lo scrivi tu» (es. scadenza coperta da un riflesso); il sottotitolo dice **«Mancano 2
  dati»**; il pulsante diventa **«Completa e crea il dossier»** e apre il modulo del cliente con i campi letti già scritti.
- **Codice fiscale non coerente** con nome, cognome, data e sesso letti: riga 3 con il segno arancio «!» e **«non torna
  con la data di nascita: controllalo»** (mai «corretto» da solo).
- **Documento scaduto**: riga 4 in arancio **«carta d'identità · scaduta il 3 aprile 2026»** e la nota «Per
  l'identificazione serve un documento valido».
- **Cliente già in Prisma** (stesso codice fiscale; o stesso nome e data di nascita): al posto dei moduli, **«Elena
  Marchi è già in Prisma»** con **«Apri il suo dossier»** e **«Aggiorna il documento»** (aggiorna solo
  `conformita.documento`).
- **È un potenziale cliente** (stesso nome tra i potenziali, §2): **«Elena Marchi è tra i potenziali, presentata da
  Sofia»** e il pulsante diventa **«Crea il dossier di Elena»** che porta con sé chi l'ha presentata (§2.5).
- **Illeggibile**: «Non riesco a leggere il documento: avvicinalo e cerca una luce senza riflessi» (telefono) e, sul Mac,
  «Nessun dato letto» con **«Scrivi a mano»**.
- **Moduli non disponibili** (modelli non caricati in Pratiche, parte 07): la tile dice **«Moduli da preparare»** con le
  due voci grigie e la frase «Carica i modelli dei moduli in Pratiche › Moduli: Prisma li compila con questi dati»; mai
  un modulo inventato.

#### 9.1.2 Misure e stile

Tutto in un file nuovo `DesignSystem/Apple/Tema.Apple+NuovoCliente.swift` (`Tema.Apple.NuovoCliente`), che **riusa** i
valori di `Tema.Apple.Inquadra` dove coincidono (`DesignSystem/Apple/Tema.Apple+Inquadra.swift`).

| Elemento | Template | Token |
|---|---|---|
| velo | rgba(6,14,20,.55), sfocatura 8 | `Tema.Apple.Inquadra.Velo.colore` (esiste, riga 22), `materiale` |
| telefono | 300×620, raggio 50, corpo #0d0f12, filo #2a2e34, tacca 92×26 a 22, rientro 11, schermo #1a1d21 | `Tema.Apple.Inquadra.Apparecchio` (esiste, righe 42-74); dopo l'estrazione della parte comune: `TelefonoDisegnato` |
| fotocamera | radiale #4a423b → #1f1b18 a 40%/30% | `Apparecchio.fotocamera`, `centroFotocamera`, `raggioFotocamera` (esistono) |
| posizione | telefono a x 280, scheda a x 680 (400 di scarto), y 100 / 130 | `Tema.Apple.Inquadra.Disposizione` (spazio 100, scarto 70: **diversi** da Inquadra, che ha telefono a 300 e scheda a 700/150) → `NuovoCliente.Disposizione.scartoScheda = 30` (nuovo), `spazio = 100` |
| linea di scansione | 3, lati 18, 110 → 420, #34C759, alone 18 | `Tema.Apple.Inquadra.Linea` (esiste, righe 122-128: alone 9 = metà di 18) |
| carta | lati 20, 150 dall'alto, raggio 10, padding 12, +2°, sfumatura #EDF1F4 → #D2DDE5 | **nuovi** `NuovoCliente.Carta.lati = 20`, `dallAlto = 150`, `raggio = 10`, `padding = 12`, `rotazione = 2`, `fondo = [Color(hex:"#EDF1F4"), Color(hex:"#D2DDE5")]`, `ombra` = `Inquadra.Foglio.ombra/ombraRaggio/ombraY` (nero .5, 20, 20: esistono) |
| inchiostri della carta | #1b2530, #5a6873, #33424D | `Inquadra.Foglio.inchiostroForte` (#1B2530, esiste), `Tema.Apple.Carta.etichetta` (#5A6873, esiste), `Tema.Apple.Carta.testoCorrente` (#33424D, esiste) |
| testa della carta | 8,5 grassetto sp. 0,8; 7 sp. 0,5 | **nuovi** `Carta.intestazione = C(dimensione: 8.5, peso: .bold, tracking: 0.8, maiuscolo: true)`, `Carta.facSimile = C(dimensione: 7, peso: .regular, tracking: 0.5, maiuscolo: true)` |
| foto | 62×80, raggio 6, #BCC9D2 con sagoma #7E909D | **nuovi** `Carta.foto = CGSize(62, 80)`, `raggioFoto = 6`, `fondoFoto = #BCC9D2`, `sagoma = #7E909D` |
| campo | etichetta 6,5 sp. 0,4; valore 10 grassetto sp. 0,3; padding 2/4; raggio 4 | **nuovi** `Carta.etichettaCampo`, `Carta.valoreCampo`, `paddingCampo = padding(2, 4)`, `raggioCampo = 4` |
| campo letto | anello 1,5 #34C759, fondo verde .14 | `Inquadra.verdeLettura` (esiste), `Inquadra.Foglio.fondoLetto` (esiste); **nuovo** `Carta.contornoLetto = 1.5` (Inquadra usa 2) |
| zona ottica | monospazio 7,5, sp. 0,8, interlinea 1,4 | **nuovo** `Carta.mrz = C(dimensione: 7.5, peso: .regular, tracking: 0.8, interlinea: 1.4, monospazio: true)` (se `Carattere` non ha `monospazio`, aggiungerlo: `.monospaced` è da macOS 13 come `Font.monospaced()`) |
| scritta del telefono | 12,5 600 bianca a 22 dal fondo | `Apparecchio.scritta`, `scrittaDalFondo` (esistono) |
| scheda Mac | larga 480, padding 22/24, piena | `Tema.Apple.Inquadra.Scheda` (larghezza 440 → **`NuovoCliente.Scheda.larghezza = 480`**, nuovo), `padding`, `superficie`, `sfera = 26`, `etichetta`, `paddingChiudi` (esistono) |
| avatar | 56, iniziali 19 bianche, opacità .25 → 1 | `Tema.Apple.Misura.Avatar.dossier` (56, già usato dal dossier: `Tema.Apple.Clienti.Testata.avatar`); **nuovo** `Scheda.avatarSpento = 0.25` |
| nome | display 24, 700 | **nuovo** `Scheda.nome = C(dimensione: 24, peso: .bold, tracking: -0.4)` (Inquadra ha `titolo` 22) |
| contatore | display 24, 700, tabellare | **nuovo** `Scheda.secondi = C(dimensione: 24, peso: .bold, tabellare: true)`; etichetta `Carattere.secondario` |
| righe | padding 8, 14 pt, spunta verde, etichetta 140 | `Inquadra.Scheda.paddingRiga`, `spunta`, `coloreSpunta`, `valore`, `filo` (esistono); `larghezzaEtichetta` 150 → **`NuovoCliente.Scheda.larghezzaEtichetta = 140`** |
| riga da guardare | — (non c'è) | `Colore.arancio` per «!» e testo, `coloreMancante` per «—» |
| tile dei moduli | `.tile`, titolo 13,5 grassetto, `.prep ok` padding 6 | `Tema.Apple.Superficie.tile`, `Misura.Padding.tile`; la voce con la spunta piena = `SpuntaDisegnata` / `ListaTiPreparo` (`DesignSystem/Apple/CompletamentoApple.swift:14`, `:128`) con **nuovo** `Scheda.paddingVoceModulo = 6` |
| pulsante | `.btn.pri.big` | `StilePulsanteApple` blu grande (esiste) |
| pulsante «Nuovo cliente» della testata | `.btn.pri` con il glifo `scan` 14 | `StilePulsanteApple` blu + `TasselloGlifo`/glifo `scan` (parte comune §4.1, `GlifoLuce.scan`) al posto di `person.badge.plus` |

#### 9.1.3 Movimento

Riusa `Tema.Apple.Moto.Inquadra` (`Tema.Apple+Inquadra.swift:268-300`) e aggiunge `Tema.Apple.Moto.NuovoCliente`.

| Momento | Template | Prisma |
|---|---|---|
| velo | 0,3 s lineare (riga 2007) | `Moto.Inquadra.velo` (esiste) |
| telefono | da y +60 e −4°, opacità 0, 0,7 s `(.34,1.3,.64,1)` | `Moto.Inquadra.telefono`, `spostamentoTelefono`, `rotazioneTelefono` (esistono) |
| linea | 1,1 s su e giù, due corse | `Moto.Inquadra.linea` (esiste) |
| contatore | +0,1 s ogni 100 ms (`setInterval`, riga 2008) | **niente Timer**: `TimelineView(.periodic(from: inizio, by: 0.1))` (SwiftUI, macOS 12) che mostra `Date().timeIntervalSince(inizio)` finché la fase è `lettura`; poi il valore fermo (`secondiImpiegati`). Il tempo è **quello vero** della lettura, non un numero da copione |
| primo campo | a 1,2 s | **nuovo** `Moto.NuovoCliente.ritardoPrimo = 1.20` (Inquadra: 1,30) |
| campi seguenti | uno ogni 0,42 s | **nuovo** `Moto.NuovoCliente.passoCampo = 0.42` (Inquadra: 0,45). In alternativa si riusano i valori di Inquadra: la differenza non si vede. Decisione minore, proposta: riusare quelli di Inquadra |
| riga della scheda | da x −14, 0,4 s `uscita` | `Tema.Apple.Moto.StileEntrata.rigaInquadra` (esiste) |
| campo sulla carta | accensione 0,4 s | `Moto.Inquadra.accensione` (esiste) |
| avatar | opacità .25 → 1 in 0,5 s | **nuovo** `Moto.NuovoCliente.avatar = Curva.ease.animazione(0.5)` |
| «✓ Fatto» e moduli | 0,3 s dopo l'ultimo campo; la tile entra da y +10 in 0,45 s `uscita` | `Moto.Inquadra.codaFatto`, `StileEntrata.tabellaInquadra` (esistono) |
| chiusura | 0,22 s | `Moto.Inquadra.chiusura` (esiste) |
| toast | 2,4 s | `Moto.Toast` (esiste) |
| dal pannello Novità | 0,4 s con Clienti già davanti, 0,9 s se no | `Moto.PannelloNovita.attesaScena` della parte comune (o «a volo finito»); Inquadra oggi usa 0,5/0,9 (`aperturaDaNovita`) |

I passi della cascata sono legati al «giro» della scena come in `StatoInquadra` (`asyncAfter` con un numero di giro:
chiudendo a metà, i passi in attesa non fanno nulla). **I campi compaiono quando arrivano davvero**: se la lettura
finisce prima del ritmo, la cascata rispetta il ritmo; se arriva dopo, la riga compare appena c'è.

**Riduci movimento** (`\.prismaCalmo`): niente telefono che entra né linea che scorre, niente cascata; le righe, la tile e
il pulsante compaiono insieme con la dissolvenza di 0,15 s; il contatore non scorre: compare il valore finale. Il
template (`ridotto`) mette le righe a 0 e la fine a 60 ms: stessa idea.

**Istantanee**: stato finale (tutte le righe, campi accesi sulla carta, linea ferma in alto, contatore fermo, tile e
pulsante visibili); il contatore mostra un valore fisso della scena di prova («3,6»).

#### 9.1.4 Interazioni

**Mac**
- **Apertura**: pulsante blu «Nuovo cliente» della testata di Clienti, voce 10 del pannello Novità
  (`NovitaLuce.nuovoCliente`), e (proposta) ⌘N dentro Clienti: oggi
  `Shell/ComandiShell.swift` non ha una scorciatoia per il cliente nuovo (grep), quindi è nuova e va solo in Clienti. In modalità cliente non si apre (scena di lavoro con dati
  personali di una persona nuova).
- **Chiusura**: «✕», Esc, clic sul velo fuori dagli oggetti, blocco di Prisma e riposo del Mac (parte comune §4.5).
  Chiudere scarta tutto ciò che è stato letto: niente resta in memoria né nell'archivio.
- **Trascinare** una foto (JPEG, PNG, HEIC) o un PDF del documento sulla scheda: lettura sul Mac con
  `LetturaDocumenti.riconosciConRiquadri` (`Dati/LetturaDocumenti.swift:95-105`, Vision sul dispositivo). Fronte e retro
  si possono trascinare uno dopo l'altro (la carta d'identità elettronica ha il codice fiscale e la zona ottica sul
  retro): i campi si sommano, il secondo documento non cancella il primo.
- **Clic su una riga letta**: diventa modificabile sul posto (campo di testo con il valore, Invio conferma, Esc annulla);
  la spunta diventa una matita grigia «scritto da te». Il codice fiscale si ricontrolla a ogni modifica.
- **«Crea il dossier di Elena»**: crea il cliente (§5.3) e apre il suo dossier su «Panoramica»; il toast dice cosa è
  stato creato. Se i modelli dei moduli ci sono, il toast è quello del template e le due compilazioni nascono in Pratiche
  (parte 07, «Compila da solo»); se non ci sono: «Dossier di Elena Marchi creato. I moduli si preparano quando carichi i
  modelli in Pratiche».
- **«Scrivi a mano»** (link piccolo sotto il pulsante, sempre presente): apre `ModuloCliente` (`Shell/ModuloCliente.swift`)
  con i dati letti fin lì; è anche la strada per chi non vuole usare la fotocamera.
- **Tastiera**: Tab percorre righe e pulsanti; Invio sul pulsante principale; VoiceOver legge «Nome e cognome, Elena
  Marchi, letto dal documento».

**iPhone** (la fotocamera vera, come «Inquadra e capisci» strada B, `iOS/InquadraTelefono.swift`)
- In Clienti sull'iPhone, in alto, il pulsante grande **«Nuovo cliente»** con il glifo `scan` (gerarchia di
  `Design/iphone.html`: una cosa principale in alto). Apre la fotocamera dal vivo (`DataScannerViewController` di
  VisionKit, iOS 16, già usato; ripiego `VNDocumentCameraViewController`): il testo riconosciuto si evidenzia, lo scatto
  legge la foto con Vision sul telefono.
- Il telefono mostra i campi trovati (la stessa cascata del Mac, nel tema dell'iPhone: barra, acqua, finestre di vetro)
  e **«Manda al Mac»**: va **solo il testo** (righe con riquadro e campi), cifrato sul ponte locale; **l'immagine non
  lascia il telefono e non si salva**. Senza ponte o con il Mac spento: «Il Mac non risponde: il documento resta qui
  finché chiudi questa schermata» (niente coda nascosta).
- Il Mac, ricevuto il testo, apre la scena (se Clienti è davanti) o mostra la notifica «Una carta d'identità
  dall'iPhone: crea il cliente» che la apre. L'iPhone non crea il cliente: l'archivio lo scrive solo il Mac (come per
  Inquadra: «L'iPhone non scrive nell'archivio (è una copia)»).
- **iPad**: stessa schermata dell'iPhone (fotocamera posteriore), nella finestra di Clienti.

#### 9.1.5 Mappa verso Prisma

**5.1 Esiste già (verificato con grep in `Sources/Prisma`)**

| Cosa | Dove |
|---|---|
| Modello del cliente | `Cliente` (`Dati/Modelli.swift:30-…`): `nome`, `iniziali` (`Cliente.iniziali(di:)`), `tinta: TintaAvatar` (`blu, rosa, verde, viola, oro`), `dataNascita`, `codiceFiscale`, `professione`, `indirizzo`, `canali`, `consensi: Consensi` (`privacy`, `dataPrivacy`, `marketing`, `dataMarketing`, riga 332), `conformita: ConformitaCliente?`, `eta` (calcolata), `Cliente.nuovo(tinta:)` |
| Documento d'identità | `DocumentoIdentita` (`Dati/Conformita.swift`: `tipo: TipoDocumentoIdentita?` con `cartaIdentita, passaporto, patente, altro`, `numero`, `rilasciatoIl`, `scadenza`), dentro `ConformitaCliente.documento`; `AdeguataVerifica`, `RischioRiciclaggio`, `RegoleConformita` |
| Scadenze di conformità | `Motori/MotoreConformita.swift`, `Shell/InRegolaCliente.swift`, `Shell/ModuloConformita.swift` |
| Lettura con Vision | `Dati/LetturaDocumenti.swift` (`import Vision`, `VNRecognizeTextRequest`, `riconosciConRiquadri` → `[RigaLetta]`), Mac e iOS |
| Campi con riquadro | `Motori/MotoreInquadra.swift` (`RiquadroPagina` 11, `RigaLetta` 47, `CampoInquadrato` 59); `IntervalloTesto` è in `Dati/SessioneCopilota.swift:75`; `CampoDocumento`/`CampoEstratto` usati in `Motori/EstrattoreDocumento.swift` |
| Forma del codice fiscale | `EstrattoreDocumento.formaCodiceFiscaleValida(_:)` (`Motori/EstrattoreDocumento.swift:92`); `MotoreFattura.codiceFiscaleValido(_:)` (`Motori/MotoreFattura.swift:448`, solo lunghezza e caratteri) |
| Doppioni | `ImportaPosizioni.abbina(nome:codiceFiscale:clienti:)` (`Motori/ImportaPosizioni.swift:269`) |
| Scena, telefono, velo | `Shell/ScenaInquadra.swift` (`StratoInquadra` 28, `ScenaInquadra` 51, `TelefonoInquadra` 127, `LineaScansione` 222, `SchedaInquadraMac` 260, `ZonaInquadra` 521), `Shell/StatoInquadra.swift` (`FaseInquadra`), token in `Tema.Apple+Inquadra.swift`; la parte comune estrae `TelefonoDisegnato` e `StratoScena` con `enum ScenaTelefono { inquadra, cartaIdentita, notaVocale }` |
| iPhone | `iOS/InquadraTelefono.swift` (DataScanner, ripiego, invio), `Supporto/iOS/Info.plist` (`NSCameraUsageDescription`, riga 125: «Prisma usa la fotocamera solo per inquadrare polizze e documenti: il testo letto va al tuo Mac in rete locale, cifrato. L'immagine resta sul telefono e non si salva.»; il commento in testa, riga 11, dice «serve solo a Inquadra e capisci»; il file è nella radice del repository, non in `Sources/Prisma`) |
| Ponte | `Ruby/PonteRuby.swift` (`manda`, righe 243 e 311; `versioneProtocollo`), `Ruby/MessaggiPonte.swift` (`InquadraturaPonte` 65, `ArrivoPonte` 109 con `.schedeCopilota`, `.inquadratura`; `BustaPonte`) |
| Creazione del cliente oggi | `StatoShell.richiestaNuovoCliente` (`Shell/StatoShell.swift:148`), `AppClienti.controllaRichiesta` (`Shell/AppClienti.swift:116`), `ModuloCliente(bozza:nuovo:salva:elimina:)` (`Shell/AppClienti.swift:19-26`), `stato.salvaCliente` |
| Pulsante di oggi | `AzioneNuovoCliente` (`Shell/ContenutoApp.swift:83-105`): «Importa…», «Incolla da Excel», «Nuovo cliente» (`person.badge.plus`); anche `Shell/ScrivaniaApple.swift:321` e `Shell/ProvaDelFuocoApple.swift:410` alzano `richiestaNuovoCliente` |
| Moduli | parte 07 (Pratiche): `ModelloModulo`, `CompilazioneModulo` (nomi proposti lì) |

**5.2 Cosa va creato**

1. **`Motori/MotoreCartaIdentita.swift`** (puro, con prova): `static func leggi(_ righe: [RigaLetta]) ->
   LetturaCartaIdentita`.
   - `struct LetturaCartaIdentita: Equatable { var tipo: TipoDocumentoIdentita?; var cognome, nome: CampoLetto?; var
     dataNascita: CampoLetto?; var luogoNascita: CampoLetto?; var sesso: CampoLetto?; var codiceFiscale: CampoLetto?; var
     numero: CampoLetto?; var rilasciatoIl, scadenza: CampoLetto?; var cittadinanza: CampoLetto? }` con
     `struct CampoLetto: Equatable { var valore: String; var riquadro: RiquadroPagina?; var fonte: FonteCampo /* .fronte,
     .zonaOttica, .aMano */ }`.
   - Regole del fronte: le etichette stampate dei documenti italiani («COGNOME», «NOME», «LUOGO E DATA DI NASCITA», «NATA
     IL», «SESSO», «SCADENZA», «EMISSIONE», «CODICE FISCALE»), il valore è la riga sotto o accanto (per riquadro); date
     «03.04.1990» e «03 04 1990».
   - **Zona a lettura ottica** (formato TD1 a tre righe da 30 caratteri della carta d'identità elettronica, ICAO 9303;
     TD3 a due righe da 44 del passaporto): numero del documento, data di nascita, sesso, scadenza, cittadinanza, cognome e
     nome, **con le cifre di controllo** (pesi 7-3-1). Dove la zona ottica c'è e le cifre di controllo tornano, **vince
     sul fronte**; dove non tornano, il campo resta da guardare.
   - Mai un campo indovinato: se una regola non trova il dato, il campo è `nil` e la scheda lo mostra «non letto».
2. **`Motori/CodiceFiscale.swift`** (puro, con prova): `static func carattereDiControlloValido(_:) -> Bool` (l'algoritmo
   pubblico dei caratteri pari e dispari, D.M. 23 dicembre 1976), `static func coerenza(_ cf: String, cognome: String,
   nome: String, nascita: Date?, sesso: Sesso?) -> CoerenzaCodiceFiscale` con `enum CoerenzaCodiceFiscale { coerente,
   coerenteSenzaComune, diverso([ParteCodiceFiscale]), nonVerificabile }`. Le parti controllabili senza tabelle: tre
   lettere del cognome, tre del nome, anno, mese, giorno (+40 per le donne), carattere di controllo; **il codice del
   comune** (es. A944) si controlla solo con la tabella dei codici catastali (**Decisione 1.3**). Il template scrive
   «✓ coerente»: Prisma scrive «✓ coerente» solo se tutto torna, «✓ coerente (comune non controllato)» se manca la
   tabella. Le omocodie (lettere al posto delle cifre) si accettano.
3. **Ponte**: busta nuova «prisma/carta» (`BustaPonte.carta`), caso `ArrivoPonte.cartaIdentita(CartaIdentitaPonte)`:
   `struct CartaIdentitaPonte: Codable, Equatable, Identifiable { id; dispositivo; quando; righe: [RigaLetta];
   campi: [CampoInquadrato]; facce: Int }` con `valido` (stessi limiti di `InquadraturaPonte.valido`: `massimoRighe`,
   `massimoTestoRiga`, `massimoCampi`). Solo testo. `PonteRuby.versioneProtocollo` +1; un Mac di prima risponde 404 →
   «Aggiorna Prisma sul Mac». In alternativa (meno codice) si riusa `.inquadratura` con un campo nuovo
   `InquadraturaPonte.scopo: ScopoInquadratura? /* .posizione (nil), .cartaIdentita */`: **proposta** la busta nuova,
   come la nota vocale della parte 06 (`ArrivoPonte.notaVocale`), così i due flussi non si confondono.
4. **Stato della scena**: `Shell/StatoNuovoCliente.swift`, `final class StatoNuovoCliente: ObservableObject` (come
   `StatoInquadra`): `fase: FaseNuovoCliente` (`attesa`, `trascina`, `lettura`, `letto`, `giaCliente(String)`,
   `potenziale(String)`, `illeggibile`), `inizio: Date?`, `secondiImpiegati: Double?`, `lettura: LetturaCartaIdentita`,
   `giro: Int`, `correzioni: [CampoCarta: String]`. **Solo in memoria**: nessun campo di `DatiPrisma`; chiudendo si
   svuota. La carta arrivata dal ponte mentre la scena è chiusa resta in memoria fino a «Crea» o «Scarta» (non entra
   nell'archivio né nel backup): Prisma chiuso = la si rimanda dall'iPhone.
5. **Vista**: `Shell/ScenaNuovoCliente.swift`: il contenuto `ScenaTelefono.cartaIdentita` dello `StratoScena` comune, con
   `CartaIdentitaDisegnata` (la carta fac-simile del template, usata nella spiegazione «Come funziona» e nelle
   istantanee: dati di prova dichiarati, scritta «FAC-SIMILE») e `SchedaNuovoClienteMac` (testata, riga del cliente con
   il contatore, righe, tile dei moduli, pulsanti). Il documento vero non si disegna mai: sul telefono disegnato si mostra
   sempre la carta fac-simile, o la zona vuota.
6. **Creazione** (`StatoShell.creaClienteDaCarta(_:)`, in un file nuovo `Shell/CreaClienteDaCarta.swift`):
   `Cliente.nuovo(tinta:)` con la tinta successiva (come oggi per il cliente nuovo), poi `nome = "Nome Cognome"` (con le
   maiuscole iniziali: dalla carta arrivano in maiuscolo), `iniziali`, `dataNascita`, `codiceFiscale`, `luogoNascita`
   e `cittadinanza` (campi della parte 07, §2.5 punto 5: oggi in `Cliente` non esistono, grep vuoto), `conformita.documento = DocumentoIdentita(tipo:numero:rilasciatoIl:scadenza:)`; **non**
   `canali`, `consensi`, `email`, `telefono`, `professione`: restano vuoti e la completezza del dossier (`VoceCompletezza`)
   li chiede. Se il potenziale corrisponde (§2), porta `presentatoDa` e collega `PotenzialeCliente.clienteId`.
   Poi `stato.salvaCliente`, `stato.clienteAttivoId = id`, `stato.schedaCliente = .panoramica`, e (se ci sono i modelli)
   la richiesta a Pratiche di compilare l'informativa privacy e l'adeguata verifica del canale (parte 07).
7. **Testata di Clienti**: `AzioneNuovoCliente` diventa `AzioniClienti`: `SegmentatoPillola(selezione:
   $stato.vistaClienti, valori: VistaClienti.allCases)` (**nuovo** `enum VistaClienti: String, CaseIterable { rubrica,
   potenziali, passaparola }` e `@Published var vistaClienti` in `StatoShell`) + il pulsante blu «Nuovo cliente» (glifo
   `scan`) che apre la scena; «Importa…» e «Incolla da Excel» vanno in un menu «…» accanto (**Decisione 1.4**).
   `richiestaNuovoCliente` resta per i punti che oggi la usano, ma apre la scena.
8. **iPhone**: `iOS/CartaIdentitaTelefono.swift` (riusa `InquadraTelefono` e il DataScanner, cambia solo le regole e il
   foglio dei risultati); `Info.plist`: il testo di `NSCameraUsageDescription` si allarga («serve a Inquadra e capisci e a
   leggere la carta d'identità di un cliente nuovo: al Mac va il testo letto, mai l'immagine»).
9. **Prove**: `Motori/ProvaCalcoliCartaIdentita.swift` (nuova, in `Prisma --prova-calcoli`): codice fiscale di prova
   coerente e no (mese, giorno +40, carattere di controllo, omocodia), zona ottica TD1 con cifre di controllo giuste e
   sbagliate, fronte senza zona ottica, campi mancanti = `nil` e mai inventati, doppione per codice fiscale; nella prova
   del ponte (`Ruby/ProvaMessaggiRuby.swift` o la prova del ponte esistente) la busta «prisma/carta» con un limite
   superato rifiutata.

#### 9.1.6 Dati che l'utente deve dare e stati vuoti

- **Il documento** (la carta d'identità del cliente, inquadrata o trascinata): tutto il resto viene da lì. Niente di
  ciò che la carta non dice si scrive da solo: email, telefono, canali, professione, consensi restano vuoti e la
  completezza li chiede.
- **I modelli dei moduli** (informativa privacy e adeguata verifica, per Alleanza e per l'attività indipendente): li dà
  l'utente in Pratiche (parte 07). Senza, «Moduli da preparare» e nessun modulo scritto da Prisma (§1.4).
- **La tabella dei codici catastali dei comuni**, se si vuole il controllo completo del codice fiscale (**Decisione
  1.3**). Senza, il comune non si controlla e la scheda lo dice.
- **Il canale** del cliente nuovo (Alleanza, indipendente, entrambi): la scheda non lo sceglie; nella testata del
  dossier appare «Canale da scegliere» finché l'utente non lo indica (le etichette dei canali sono obbligatorie ovunque).
- Stati vuoti e di errore: §1.4.

#### 9.1.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `840-clienti-nuovo-attesa` / `-scuro` | scena aperta, ponte acceso: telefono vuoto «Inquadra il documento», scheda in attesa con la zona per trascinare |
| `841-clienti-nuovo-letto` / `-scuro` | stato finale del template: carta fac-simile con i campi accesi, cinque righe, «3,6», tile dei moduli, «Crea il dossier di Elena» |
| `842-clienti-nuovo-parziale` | scadenza non letta e codice fiscale «non torna»: righe grigia e arancio, «Completa e crea il dossier» |
| `843-clienti-nuovo-gia-cliente` | il codice fiscale è di un cliente in archivio: «… è già in Prisma» con i due pulsanti |
| `844-clienti-nuovo-senza-moduli` | modelli dei moduli assenti: «Moduli da preparare» |
| `845-clienti-nuovo-ponte-spento` | solo la zona per trascinare, con l'indicazione delle Impostazioni |
| `846-clienti-nuovo-calmo` | «Riduci movimento»: stesso stato finale, linea assente |
| `847-clienti-testata-luce` | testata di Clienti con «Rubrica · Potenziali · Passaparola», «…» e «Nuovo cliente» col glifo |
| iOS `75-nuovo-cliente-iphone` | iPhone: il foglio dei campi trovati sulla carta fac-simile e «Manda al Mac» (nelle istantanee la fotocamera non c'è, come `FoglioInquadraDiProva`) |

Dati della scena: «Elena Marchi» fac-simile (i dati del template, dichiarati di prova, solo nello stato della scena).

#### 9.1.8 Regole di CLAUDE.md toccate e decisioni per l'utente

Regole toccate: dati dei clienti solo sul Mac (la carta è un dato personale forte); fotocamera dell'iPhone; ponte locale
cifrato; target macOS 13; niente Timer (contatore); tema e token centralizzati; dati di prova solo dichiarati.

- **Fotocamera e Vision (privacy)**: la fotocamera è dell'iPhone/iPad, la lettura è con Vision **sul dispositivo**
  (nessun servizio esterno, nessun invio a Apple: `VNRecognizeTextRequest` e DataScanner lavorano in locale). Al Mac va
  solo il testo, cifrato sul ponte con il codice di abbinamento. Nessuna rete esterna.
- **Decisione 1.1 — Dove si legge la carta.** Proposta: iPhone/iPad con il ponte (come il template) **e** foto o PDF
  trascinati sul Mac. In più si potrebbe offrire «Importa dall'iPhone» di macOS (Continuity Camera, menu
  `NSMenuItem.importFromDeviceIdentifier`, da macOS 10.14: la foto passa dal telefono al Mac in locale, è un servizio
  Apple del sistema): proposta **no** in questo giro, per non avere una foto del documento sul Mac.
- **Decisione 1.2 — La copia del documento.** Per l'adeguata verifica antiriciclaggio può servire **conservare la copia
  del documento** (obblighi di conservazione dei dati e documenti dell'adeguata verifica, D.Lgs. 231/2007; e le procedure
  di Alleanza). Il template non salva nulla. Proposta: di base **la foto non si salva** (come Inquadra); un interruttore
  esplicito nella scheda, spento, «Salva la copia del documento nei Documenti di Elena» la salva cifrata dentro
  l'archivio del Mac (Documenti del cliente, nel backup). Quale sia l'obbligo e per quale canale lo dice l'utente: Prisma
  non scrive regole antiriciclaggio da solo.
- **Decisione 1.3 — Codici catastali.** Per «✓ coerente» pieno serve la tabella dei codici dei comuni (dato pubblico,
  Agenzia delle Entrate/ISTAT, alcune migliaia di righe, ~200 KB): includerla nelle risorse (`Risorse/Comuni/`, senza
  rete, da aggiornare a mano con gli aggiornamenti di Prisma) o fare a meno del controllo del comune. Proposta:
  includerla, se l'utente fornisce o approva la fonte; altrimenti «comune non controllato». Non è una dipendenza di
  codice, ma è un dato esterno: va approvato.
- **Decisione 1.4 — Il pulsante «Nuovo cliente».** Nel template apre solo la fotocamera e «Importa…»/«Incolla da Excel»
  spariscono dalla testata. Proposta: «Nuovo cliente» apre la scena con «Scrivi a mano» sempre visibile; «Importa…» e
  «Incolla da Excel» in un menu «…» accanto al segmentato (non si perdono).
- **Decisione 1.5 — Testi dei moduli.** «Informativa privacy» e «Adeguata verifica» sono testi normativi e di prodotto
  dei due canali: li fornisce l'utente (parte 07). Prisma non ne scrive.
- **Decisione 1.6 — Il «10 secondi».** Il titolo promette un tempo; il contatore mostra il tempo vero. Proposta: tenere il
  contatore (onesto) e il titolo della novità solo nel pannello Novità.
- **Decisione 1.7 — L'avviso sul Mac quando arriva una carta.** Se la scena è chiusa, il Mac mostra «Una carta
  d'identità dall'iPhone: crea il cliente». Proposta: avviso **interno a Prisma** (pannello delle notifiche della shell),
  **senza il nome** della persona nel testo, e nessuna notifica di sistema del Mac (resterebbe nel Centro notifiche e
  sullo schermo bloccato). La carta in attesa vive solo in memoria e si scarta al blocco di Prisma e al riposo del Mac,
  come la scena (parte comune §4.5): da confermare che si perda anche lì.
- **API**: DataScanner (VisionKit) è iOS 16, sotto il minimo del pacchetto (`.iOS(.v17)` in `Package.swift`): nessuna
  protezione di versione, solo `isSupported`/`isAvailable` come in `iOS/InquadraTelefono.swift`; sul Mac `TimelineView` (macOS 12), `.dropDestination`
  (macOS 13) o `onDrop` (macOS 11): nessuna API sopra macOS 13. Nessuna dipendenza esterna.

---

### 9.2 Potenziali clienti e passaparola

*Voce Novità 11: «Potenziali clienti e passaparola · Il percorso e l'albero di chi presenta chi», glifo `albero` su
#2F7A4A (`NOVL[10]`, riga 2066): `vaiA('clienti', vistaC='pass')`. Il segmentato della testata di Clienti (riga 2079) ha
tre viste: **Rubrica** (`rub`, il Clienti di oggi), **Potenziali** (`pot`), **Passaparola** (`pass`); il cambio usa
`rimonta` (riga 2080). Codice: `POT` 2015, `potHTML` 2016-2018, `montaPot` 2019, `PASS` 2020, `passHTML` 2021-2025,
`montaPass` 2026-2033; CSS `.kan`/`.kCol` 323, `.kCard` 324, `.psN` 325, `.tile` 127, `.bar8` 128-129.*

#### 9.2.1 Cosa si vede

**1.1 Vista «Potenziali»** (`potHTML`, schermata `09-c-pot.png`). Nell'area della finestra (1384×654):

- **Quattro tile** in riga (`.tile`, spazio 12, 14 sotto; ognuna `.k` + valore `.v` contato):
  1. «Potenziali clienti» → **«8»** (intero: tutti i potenziali delle prime quattro colonne);
  2. «Patrimonio stimato» → **«1.225.000 €»** (somma delle stime);
  3. «Dal passaparola» → **«6»** (quanti sono «presentato/a da …»);
  4. «Probabile entro fine anno» → **«503.000 €»** (somma di stima × probabilità).
- **Il percorso** (`.kan`, alto 466, spazio 12): **cinque colonne** (`.kCol`: fondo `--panel`, filo `--sep`, raggio 20,
  padding 14), ciascuna con il titolo (14 grassetto) e a destra il numero (`.k`): **«Da contattare»** 3, **«Primo
  incontro»** 2, **«Analisi»** 2, **«Proposta»** 1, **«Cliente»** 1.
- **Le schede** (`.kCard`: fondo pieno, filo, raggio 14, padding 12, 8 di spazio, ombra 0 6 14 −10 nero .3; al
  passaggio ombra 0 12 24 −12 nero .35 in 0,25 s): **nome** (14 grassetto), **fonte** (`.k` 12: «presentato da Marco»,
  «dal sito dello studio», «evento in Comune»), riga (8 sopra, 12,5) con la **stima** a sinistra («180.000 €») e la
  **probabilità** a destra (`.k`, «20%»), sotto una **barra** (`.bar8` alta 5, 5 sopra) lunga quanto la probabilità,
  colorata: ≥ 70% verde (`--green`), ≥ 40% blu (`--accent`), sotto grigio (`--ink3`).
  Dati del template (riga 2015): Da contattare: Paolo Ferretti (presentato da Marco, 180.000, 20%), Anna Galli (dal sito,
  60.000, 15%), Roberto Neri (presentato da Sofia, 240.000, 25%); Primo incontro: Chiara Fontana (Giulia, 90.000, 40%),
  Davide Sala (Marco, 320.000, 45%); Analisi: Marta Conti (Andrea, 75.000, 60%), Luca Ricci (evento in Comune, 110.000,
  55%); Proposta: Sara Villa (Marco, 150.000, 75%); Cliente: Elena Marchi (Sofia, 140.000, 100%).
- Sotto (10 sopra, `.k`): **«Tocca una scheda per farla avanzare. Prisma ricorda chi l'ha presentata: quando diventa
  cliente, compare nell'albero del passaparola.»**

Note sul template: le colonne hanno altezza fissa e `overflow:hidden`: con molti potenziali le schede si tagliano
(in Prisma ogni colonna scorre, §4). La colonna «Cliente» non entra nei totali delle tile (`POT.slice(0,4)`).

**1.2 Vista «Passaparola»** (`passHTML` + `montaPass`, schermata `09-c-pass.png`).

*A sinistra, l'albero*: card larga 900 (tutta l'altezza), con l'etichetta `.lbl` **«CHI TI HA PRESENTATO CHI · DAL
2016»** (a 22/18) e un disegno 900×654:
- **«Tu»** (90, 327): cerchio di raggio 30 con sfumatura verticale #7FA5D9 → #2563EB, «Tu» 14 grassetto bianco.
- **Primo livello**: i cinque clienti, x = 330, y = 80 + i·120. Cerchio di raggio **14 + √(patrimonio / 1.000) · 0,9**
  (Marco, 318.400 € → circa 30) nel colore del cliente, bordo bianco 3, iniziali 12 grassetto bianche; sotto (r + 16) il
  nome 12,5 / 600. Ogni cliente è legato a «Tu» con una curva (Bézier da (120, 327) con controlli a +140 e −140 in x),
  grigia (`--ink3`) da 1,6.
- **Secondo livello**: le persone presentate da ciascuno, x = 640 o 696 (alternate, per non sovrapporre le etichette),
  una ogni 52 in y, centrate sul presentatore ma mai sopra la precedente (`fondo + 64`) né sopra 36. Cerchio di raggio
  **8 + √(migliaia) · 0,8**:
  - **già cliente**: pieno verde #30B15C, bordo bianco 2; legame verde (#30B15C .7) **pieno** da 2;
  - **ancora potenziale**: pieno `--chip`, bordo `--ink3` 2; legame grigio .45 **tratteggiato** 4/5 da 1,4.
  Accanto (rr + 8) il nome (12, `--ink`) e sotto (+18) la cifra (10,5, `--ink3`): «320.000 € · potenziale» o «65.000 €».
  Dati (riga 2020): Marco → Davide Sala, Sara Villa, Paolo Ferretti (potenziali), Chiara Marino (cliente); Sofia → Elena
  Marchi, Paola Leone (clienti), Roberto Neri (potenziale); Giulia → Chiara Fontana (potenziale); Andrea → Marta Conti
  (potenziale); Laura → nessuno.

*A destra* (da x 916, colonna con spazio 12):
1. **«I TUOI AMBASCIATORI»** (card, padding 20/22, senza ombra): una riga per chi ha presentato **più di una persona**:
   avatar 38, nome grassetto, «4 persone presentate» (`.k`), a destra in grassetto 15 la somma («715.000 €»; nel
   template somma anche i potenziali). Sotto (8 sopra, `.k`): **«Il 41% del patrimonio nuovo degli ultimi tre anni è
   nato dal passaparola.»**
2. **«IL MOMENTO GIUSTO PER CHIEDERE»** (card con filo arancio rgba(224,138,0,.4) e fondo arancio .06; etichetta in
   #B45309): avatar 40, **«Sofia Romano»**, «ha raggiunto la rendita ieri: è contenta» (`.k`), pulsante blu **«Prepara la
   richiesta»** (12 sopra).
3. **«NUOVI CLIENTI DAL PASSAPAROLA»** (card, padding 18/22): cinque colonne 2022-2026, alte 96: il numero sopra
   (12,5 grassetto), la barra alta n·11 (raggio 6 6 3 3; l'ultima verde, le altre `--track`), l'anno sotto (`.k`
   11,5). Dati: 2, 3, 5, 4, 6.
4. In fondo (`margin-top:auto`, `.k`): **«La grandezza di ogni cerchio è il patrimonio. Le persone in grigio sono ancora
   potenziali clienti.»**

**1.3 Stati da aggiungere** (il template non li ha):
- **Nessun potenziale**: le colonne vuote con al centro della prima «Aggiungi un potenziale cliente» (pulsante) e la
  frase «Qui segui le persone che potrebbero diventare clienti, da chi ti ha presentato alla firma.»
- **Potenziale senza stima o senza probabilità**: «stima da inserire» / «—» al posto della cifra e della percentuale,
  barra vuota; non entra nei totali e la tile lo dice in piccolo («2 senza stima»).
- **Nessun passaparola registrato**: l'albero mostra solo «Tu» e i clienti, senza legami, e la frase «Quando un cliente
  ti presenta qualcuno, scrivilo nel potenziale o nel dossier: qui nasce l'albero». Ambasciatori: «Nessuno ancora».
- **Nessun momento giusto**: la card arancio non c'è (non si inventa un motivo).
- **Tanti clienti** (200 con i fittizi): l'albero mostra al primo livello solo chi ha presentato qualcuno (gli altri in
  una riga «+ 34 clienti senza presentazioni»); con più di 8 presentati per persona, «+ N» che apre l'elenco.
- **Generazioni successive** (un presentato che presenta a sua volta): il template ha due livelli; vedi **Decisione 2.4**.

#### 9.2.2 Misure e stile

File nuovo `DesignSystem/Apple/Tema.Apple+Potenziali.swift` (`Tema.Apple.Potenziali`, `Tema.Apple.Passaparola`).

| Elemento | Template | Token |
|---|---|---|
| tile | `.tile` raggio 18, padding 14/16; `.k` 12,5; `.v` 26 / 700 | `Superficie.tile`, `Misura.Padding.tile`, `Carattere.secondario`, `Carattere.valore` (esistono); `Tema.Apple.Clienti.Tessere` per l'altezza (76) e lo spazio (12) |
| colonna | fondo `--panel`, filo, raggio 20, padding 14 | `Colore.pannello`, `Colore.separatore`, `Raggio.pannello` (esistono); **nuovo** `Potenziali.paddingColonna = 14` |
| titolo colonna | 14 grassetto + numero `.k` | `Carattere.titoloRiga` (15) è più grande: **nuovo** `Potenziali.titoloColonna = C(dimensione: 14, peso: .bold)` |
| scheda | fondo pieno, raggio 14, padding 12, spazio 8 | `Colore.cardPiena`, `Raggio.voce` (14), **nuovi** `Potenziali.paddingScheda = 12`, `spazioSchede = 8` |
| ombra scheda | 0 6 14 −10 nero .3; al passaggio 0 12 24 −12 nero .35 | **nuovi** `Potenziali.ombra = Ombra(colore: nero .30, raggio: 14, y: 6, allargamento: -10)`, `ombraSopra = (… .35, 24, 12, -12)` (se `Tema.Apple.Ombra` ha già una forma con allargamento negativo, usarla) |
| nome / fonte | 14 grassetto / 12 | `Tema.Apple.Clienti.Rubrica.nome` (14 bold) e `.motto` (12): esistono, si riusano |
| cifra / percentuale | 12,5 / `.k` | `Carattere.secondario` |
| barra | alta 5, binario `--track` | `BarraPiena` con **nuovo** `Potenziali.altezzaBarra = 5`; colori: `Colore.verde`, `Colore.accento`, `Colore.inchiostro3`; soglie **nuove** `Potenziali.sogliaAlta = 70`, `sogliaMedia = 40` |
| colonne del percorso | alte 466, spazio 12 | in Prisma l'altezza è quella che resta (niente 466 fisso); `Potenziali.spazioColonne = 12` |
| albero | card 900; «Tu» r 30 a (90, 327), sfumatura #7FA5D9 → #2563EB | **nuovi** `Passaparola.larghezzaAlbero = 900` (minima 640, poi si stringe), `raggioTu = 30`, `xTu = 90`; colori: `Colore.avatarDVAlto` (#7FA5D9, esiste) e `Colore.canaleAlleanza` chiaro #2563EB? No: è il blu dell'utente, non del canale → **nuovo** `Colore.avatarTuBasso = #2563EB` (o si usa `avatarDVBasso` #4B79B8 dell'avatar «DV» della barra: **proposta**, così «Tu» è lo stesso avatar dell'utente) |
| primo livello | x 330, passo 120, r = 14 + √(k€)·0,9, bordo bianco 3 | **nuovi** `Passaparola.xPrimo = 330`, `passoPrimo = 120`, `raggioBase = 14`, `fattoreRaggio = 0.9`, `bordoPrimo = 3`; colore = la tinta del cliente (`TintaAvatar` → colore dell'avatar, come `AvatarCliente`) |
| secondo livello | x 640/696, passo 52, r = 8 + √(k€)·0,8 | **nuovi** `xSecondo = 640`, `scartoAlterno = 56`, `passoSecondo = 52`, `raggioBaseSecondo = 8`, `fattoreSecondo = 0.8`, `margineSopra = 36`, `distanzaGruppi = 64` |
| cliente presentato | #30B15C, legame .7 da 2 | `Colore.Anello`/grafici: **#30B15C** è `Tema.Apple.Colore` dei grafici «liquidità» delle aree di Analisi 360 (`Tema.Apple.Colore.Area.liquidita`, `DesignSystem/Apple/TemaApple.swift:129`, stesso valore): **nuovo** alias `Passaparola.cliente = #30B15C` (non `Colore.verde` #2FA35A, che è un altro verde) |
| potenziale | `--chip`, bordo `--ink3` 2, legame .45 tratteggio 4/5 da 1,4 | `Colore.chip`, `Colore.inchiostro3`; **nuovi** `tratteggio = [4, 5]`, `spessorePotenziale = 1.4`, `opacitaPotenziale = 0.45` |
| legami da «Tu» | `--ink3` da 1,6 | **nuovo** `spessoreTronco = 1.6` |
| etichette | nome 12,5/600 (primo), 12 (secondo); cifra 10,5 `--ink3` | **nuovi** `Passaparola.nomePrimo = C(12.5, .semibold)`, `nomeSecondo = C(12, .regular)`, `cifra = C(10.5, .regular)` |
| colonna destra | da 916 (spazio 16), card padding 20/22, senza ombra | `Superficie.cardPiatta`, `Misura.Padding.cardMedia` (se 20/22), `Tema.Apple.Clienti.spazioRubrica` (16) |
| ambasciatori | avatar 38, somma 15 grassetto | `Misura.Avatar.medio` (verificare che sia 38), `Carattere.delta` (15 semibold) o **nuovo** `Passaparola.somma = C(15, .bold, tabellare)` |
| momento giusto | filo arancio .4, fondo arancio .06, etichetta #B45309 | `Colore.avvisoBordo` è .25 e `avvisoFondo` .10: **nuovi** `Passaparola.bordoMomento = arancio .40`, `fondoMomento = arancio .06`; l'etichetta #B45309 = `Tema.Apple.Carta.ambra` (esiste, stesso valore) |
| barre degli anni | alte n·11 su 96, raggio 6/3, ultima verde | `BarraPiena` verticale o il grafico a colonne di Studio; **nuovi** `Passaparola.altezzaColonne = 96`, `unitaColonna = 11` (in Prisma: altezza proporzionale al massimo, non 11 fisso), `raggioColonnaAlto = 6`, `raggioColonnaBasso = 3`; colore ultima `Colore.verde` |

Nel tema scuro (schermata `09-s-pass.png`) l'albero resta su card scura, i nodi potenziali su `--chip` scuro; i colori
dei clienti e il verde non cambiano.

#### 9.2.3 Movimento

| Momento | Template | Prisma |
|---|---|---|
| cambio di vista | `rimonta`: 0,13 s di uscita, poi cascata | `Tema.Apple.Moto.CambioScheda` (esiste) + `EntrataApple` |
| tile | numeri contati (1100 + i·60 ms) | `NumeroCheConta` con `Moto.Numero.durata(indice:)` (esiste) |
| barre delle schede | 1,2 s `--out`, ritardo 150 + i·90 | `BarraPiena` con `Moto.Barra` (esiste: 1,2 s, 0,15 + i·0,09) |
| scheda che avanza | FLIP: dalla vecchia posizione alla nuova in 650 ms `(.34,1.3,.64,1)` | `matchedGeometryEffect` sull'id del potenziale fra le colonne (macOS 11) con **nuovo** `Moto.Potenziali.avanza = Curva.mollaLeggera.animazione(0.65)`; **nuova** curva comune `Tema.Apple.Moto.Curva.mollaLeggera = (0.34, 1.3, 0.64, 1)` (oggi vive solo come `Moto.Inquadra.curvaTelefono`: spostarla lì e farla usare anche al telefono) |
| arrivo in «Cliente» | toast «Nuovo cliente: benvenuta nel passaparola» | toast + scena del nuovo cliente (§4) |
| legami pieni | si disegnano in 900 ms `uscita`, ritardo 200 + i·60 | `TracciatoGrafico`/`trim` con `Moto.Linea` o **nuovo** `Moto.Passaparola.legame = Curva.uscita.animazione(0.9)`, `ritardoLegame(i) = 0.2 + i·0.06` |
| legami tratteggiati | compaiono in 600 ms, ritardo 200 + i·60 | **nuovo** `Moto.Passaparola.tratteggio = 0.6` (dissolvenza) |
| nodi | da scala .6 e opacità 0 in 500 ms `(.34,1.5,.64,1)`, ritardo 300 + i·55 | `Curva.molla` (.34,1.45: differenza invisibile) con **nuovi** `Moto.Passaparola.nodo = 0.5`, `ritardoNodo(i) = 0.3 + i·0.055`, `scalaNodo = 0.6` |
| colonne degli anni | da scaleY 0 in 0,9 s `(.34,1.3,.64,1)`, ritardo 0,3 + i·0,08 | `Curva.mollaLeggera.animazione(0.9)`; **nuovi** `Moto.Passaparola.ritardoColonna(i) = 0.3 + i·0.08` |
| «Prepara la richiesta» | il testo diventa «✓ Messaggio pronto» + toast | `Moto.Spunta` per la spunta, `Moto.Toast` |

Con molti nodi i ritardi si fermano a un massimo (come `Moto.Numero.indiceMassimo`): **nuovo**
`Moto.Passaparola.indiceMassimo = 12`, così l'albero di 200 clienti non impiega dieci secondi a comparire.

**Riduci movimento**: niente volo delle schede (cambiano colonna con la dissolvenza di 0,15 s), legami e nodi già
disegnati, colonne già alte, numeri completi. Il template salta solo i ritardi (`ridotto?1:…`).

**Istantanee**: stato finale: numeri completi, barre piene, legami tracciati, nodi a scala 1, colonne alte.

#### 9.2.4 Interazioni

**Vista Potenziali (Mac)**
- **Avanzare**: clic sulla scheda = un passo avanti (come il template). In più, perché il clic da solo è facile da
  sbagliare: **trascinare** la scheda in un'altra colonna (`.draggable` / `.dropDestination`, macOS 13), e il menu
  contestuale «Avanti», «Indietro», «Modifica…», «Non interessato», «Elimina». Il clic sul nome apre il dettaglio.
- **Dettaglio del potenziale** (nasce dalla scheda e ci torna, `DettaglioApple`): nome, recapiti, fonte (cliente che l'ha
  presentato, scelto dalla rubrica, o testo libero: «sito dello studio», «evento in Comune»), stima del patrimonio,
  probabilità, chiusura prevista, nota, data dell'informativa privacy data, storia dei passaggi di fase con le date, e i
  pulsanti «Fissa il primo incontro» (Agenda, `TipoAppuntamento.primoIncontro`), «Scrivigli» (Messaggi, solo se ha dato
  il consenso), «Diventa cliente».
- **Aggiungere**: pulsante «+ Potenziale» nella colonna «Da contattare» e ⌘N quando la vista è Potenziali.
- **Arrivo in «Cliente»**: la scheda non diventa cliente da sola. Si apre la scena del nuovo cliente (§1) con il nome
  già scritto e «presentato da …», oppure «Scrivi a mano»; solo quando il dossier è creato la scheda resta in «Cliente»
  (collegata al dossier: clic = apre il dossier) e compare nell'albero. Annullando, la scheda torna in «Proposta».
- **Colonna «Cliente»**: mostra i potenziali diventati clienti negli ultimi 12 mesi; i più vecchi restano solo
  nell'albero.
- **Tastiera**: frecce tra le schede, ⌘→/⌘← avanti/indietro, Invio apre il dettaglio, Canc chiede conferma.

**Vista Passaparola (Mac)**
- Passaggio su un nodo: suggerimento con nome, fase (se potenziale), patrimonio o stima, data della presentazione.
- Clic su un **cliente**: apre il dossier (Rubrica, Panoramica). Clic su un **potenziale**: il suo dettaglio.
- Clic su un **ambasciatore**: l'albero mette in evidenza i suoi rami (gli altri al 30%).
- **«Prepara la richiesta»**: apre Messaggi sull'occasione nuova `richiestaPresentazione` del cliente (§5.2.6): il
  testo lo prepara Prisma (modello fisso) e, se pronta, Ruby; lo spedisce l'utente. Il pulsante diventa «✓ Messaggio
  pronto» solo quando il messaggio esiste (aperto o salvato), e il toast è quello del template («Per Sofia: un grazie
  sincero e una richiesta leggera, senza pressione. Lo trovi in Messaggi»).
- Le colonne degli anni: passaggio = «2026: 6 clienti nuovi dal passaparola su 11».

**iPhone/iPad**: il template non ne parla. Proposta: su iPad il segmentato e le due viste ci sono, **in sola lettura**
(l'iPad è una copia; i passaggi di fase si fanno sul Mac, o con «Prisma ovunque» attraverso il giornale, se acceso);
sull'iPhone, in Clienti, la vista «Potenziali» come elenco per fase (una cosa grande in alto: «8 potenziali · 503.000 €
probabili»), senza albero.

#### 9.2.5 Mappa verso Prisma

**5.1 Esiste già**

| Cosa | Dove |
|---|---|
| App Clienti, rubrica e dossier | `Shell/AppClienti.swift` (`AppClienti`, `dossierERubrica`, `rubrica`), `Shell/DossierApple.swift` |
| Testata | `Shell/ContenutoApp.swift` (`AzioneNuovoCliente`, `IntestazioneApp`); titolo «Le tue relazioni.» in `Shell/AppPrisma.swift:150` |
| Patrimonio del cliente | `RiepilogoPosizioni(_:)` (`Motori/Riepilogo.swift:4`, `patrimonioNetto`) |
| Appuntamenti di primo incontro | `TipoAppuntamento.primoIncontro` (`Dati/Modelli.swift:341-…`) |
| Proposte e loro seguito | `Posizione.esito`, `Posizione.seguito: SeguitoProposta?` (`Dati/Posizione.swift:184-186`), `Dati/SeguitoProposte.swift`; l'imbuto delle proposte di Studio (`MotoreStudio.Imbuto`, `Motori/MotoreStudio.swift:131`) |
| Messaggi e consenso | `TipoOccasioneMessaggio` (`Dati/MessaggioCliente.swift:11-…`, con `commerciale`), `stato.consensoCommercialeValido(_:)` (usato in `Shell/PannelloMessaggio.swift:149`), `CollegamentiMessaggi` (`Shell/CollegamentiMessaggi.swift`) |
| Traguardi | parte 05 (`Motori/MotoreTraguardi.swift`, nome proposto lì): «ha raggiunto la rendita» nasce da lì |
| Dettaglio che nasce dalla scheda | `DesignSystem/Apple/DettaglioApple.swift`, `PresentatoreDettaglioDossier` |

`grep -ri passaparola Sources/Prisma` non trova nulla: modello, motore e viste sono tutti da fare.

**5.2 Cosa va creato**

1. **Modello** `Dati/PotenzialeCliente.swift` (versione 27, `DatiPrisma.potenziali: [PotenzialeCliente] = []`, nel backup):
   ```swift
   enum FasePotenziale: String, Codable, CaseIterable { daContattare, primoIncontro, analisi, proposta, cliente, nonInteressato }
   struct CambioFase: Codable, Hashable { var fase: FasePotenziale; var il: Date }
   struct PotenzialeCliente: Identifiable, Codable, Hashable {
       var id: String                  // "pot-<uuid8>"
       var nome: String
       var email = "", telefono = ""
       var presentatoDa: String?       // id del cliente che l'ha presentato
       var fonte: String?              // testo libero se non è un cliente: «sito dello studio», «evento in Comune»
       var patrimonioStimato: Double?  // nil = non stimato (mai 0 di ripiego)
       var probabilita: Int?           // 0…100, scritta dall'utente; nil = non indicata
       var chiusuraPrevista: Date?
       var fase: FasePotenziale = .daContattare
       var storia: [CambioFase] = []
       var informativaIl: Date?        // quando ha ricevuto l'informativa privacy (vedi Decisione 2.2)
       var consensoContatto: Bool?     // vedi Decisione 2.2
       var clienteId: String?          // quando è diventato cliente
       var nota = ""
       var creatoIl: Date
   }
   ```
   Lettura tollerante (`try?` per ogni campo nuovo, fase sconosciuta → `daContattare`).
2. **Campo del cliente** (versione 27): `Cliente.presentatoDa: String?` (id di un altro cliente) e `Cliente.presentatoIl:
   Date?`, scritti a mano nel modulo del cliente («Presentato da», scelta dalla rubrica) o portati dal potenziale. Lo
   stesso campo serve alla parte 05 («7 sono arrivati dal passaparola»), che oggi lo cerca e non lo trova. Un cliente
   eliminato lascia `presentatoDa` orfano: si ignora (nell'albero diventa «un cliente non più in archivio»).
3. **Motore** `Motori/MotorePassaparola.swift` (puro, con `oggi`):
   - `static func percorso(_ potenziali:) -> [FasePotenziale: [PotenzialeCliente]]` e `totali(…) -> TotaliPotenziali
     { conteggio, patrimonioStimato, senzaStima, dalPassaparola, probabileEntro(anno) }`. **Probabile entro fine anno** =
     Σ stima × probabilità **dei soli potenziali con chiusura prevista entro il 31 dicembre** (Decisione 2.3); chi non ha
     stima, probabilità o data non entra e si conta a parte.
   - `static func albero(clienti:, potenziali:, posizioni:) -> AlberoPassaparola` con nodi `NodoPassaparola { id, nome,
     tipo: .cliente(id) / .potenziale(id), patrimonio: Double? /* netto per i clienti, stima per i potenziali */,
     figli: [NodoPassaparola], presentatoIl: Date? }`, primo livello = i clienti senza `presentatoDa` (o con un
     presentatore non più in archivio), poi i presentati. Cicli (A presenta B, B presenta A per errore) interrotti e
     segnalati.
   - `ambasciatori(…, minimo: 2)` con `portato` (patrimonio netto dei presentati **diventati clienti**) e `inArrivo`
     (stime dei potenziali) **separati**: il template li somma, Prisma no (sono cose diverse).
   - `quotaPassaparola(anni: 3)`: patrimonio netto dei clienti creati negli ultimi tre anni con `presentatoDa`, diviso
     il patrimonio di tutti i clienti creati negli ultimi tre anni (da `Cliente.creatoIl`). Se mancano dati («creatoIl»
     dei clienti importati coincide con l'importazione) la frase lo dice: «calcolato sui clienti con la data d'inizio».
   - `nuoviPerAnno(anni: 5)`: clienti creati per anno con `presentatoDa`.
   - `momentoGiusto(…, giorni: 7) -> [MomentoPerChiedere]`: un cliente con un **traguardo** recente (parte 05: obiettivo
     raggiunto, rendita avviata, mutuo estinto…) o una proposta firmata negli ultimi 7 giorni, **con consenso
     commerciale valido**, che non ha avuto una richiesta di presentazione negli ultimi 180 giorni. Il motivo è il fatto
     («ha raggiunto la rendita ieri»), **mai uno stato d'animo**: «è contenta» del template non si scrive (Decisione
     2.5).
4. **Viste**: `Shell/ClientiPotenziali.swift` (`VistaPotenziali`: tile, colonne con `ScrollView` verticale ciascuna,
   `SchedaPotenziale`, `DettaglioPotenziale`, `ModuloPotenziale`), `Shell/ClientiPassaparola.swift` (`VistaPassaparola`:
   `AlberoPassaparola` disegnato con `Canvas` per i legami e viste per i nodi, o tutto con `Path` + `Text`; colonna
   destra con `AmbasciatoriCard`, `MomentoGiustoCard`, `ColonneAnniPassaparola`). In `AppClienti.body` lo scambio fra le
   tre viste con `stato.vistaClienti` (`VistaClienti` del §1.5.2 punto 7).
5. **Modulo del cliente**: in `Shell/ModuloCliente.swift` la riga «Presentato da» (menu con la rubrica, «Nessuno») e la
   data.
6. **Messaggi**: `TipoOccasioneMessaggio.richiestaPresentazione` (nuovo caso, **commerciale = true**, `ordine` dopo
   `provaFuoco`), con il riferimento al traguardo; testo fisso in `Motori/ModelliMessaggi.swift` per i tre toni (un
   grazie per il traguardo + una richiesta leggera, senza cifre di nessun altro cliente) e le istruzioni per Ruby in
   `Ruby/Istruzioni/messaggi.md` (sezione nuova: «mai nomi di altri clienti, mai pressione, mai incentivi»).
7. **Pannello Novità**: `NovitaLuce.passaparola` → `stato.vistaClienti = .passaparola`, `apri(.clienti)`.
8. **Dati di prova**: i potenziali e i `presentatoDa` del template (riga 2015 e 2020) in `Dati/DatiDemo.swift`, solo
   insieme ai clienti di prova; per i 30 fittizi (`Dati/ClientiFittizi.swift`) qualche `presentatoDa` fra loro.
   Etichetta «dati di prova» dove si vedono.
9. **Prove**: `Motori/ProvaCalcoliPassaparola.swift` (totali con e senza stima/probabilità/data; albero con ciclo;
   ambasciatori con `portato` e `inArrivo` separati; potenziale → cliente porta `presentatoDa`; `momentoGiusto` senza
   consenso = nessuno); `Dati/ProvaBackupLuceClienti.swift`: un potenziale completo e uno minimo, `presentatoDa` di un
   cliente, salvataggio, backup, ripristino, uguali; un archivio della versione 26 si legge con `potenziali` vuoto.

#### 9.2.6 Dati che l'utente deve dare e stati vuoti

- Per ogni potenziale: **nome**, **fonte** (chi l'ha presentato o da dove arriva), la **stima del patrimonio** (se la
  conosce), la **probabilità** che diventi cliente e la **chiusura prevista**: sono valutazioni del consulente, Prisma non
  le stima. Il template mette probabilità diverse per ogni scheda: in Prisma **non c'è una probabilità predefinita per
  fase** (Decisione 2.3).
- Per i clienti di oggi: **chi li ha presentati** (`presentatoDa`): senza, l'albero è vuoto. Si può inserire dal modulo
  del cliente; un'importazione dei vecchi passaparola (colonna «Presentato da» nel CSV di `Motori/ImportaClienti.swift`)
  è una possibilità, da chiedere.
- L'anno da cui parte l'albero («dal 2016») = la data della presentazione più vecchia registrata; senza date, l'etichetta
  è solo «Chi ti ha presentato chi».
- Stati vuoti: §1.3.

#### 9.2.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `850-clienti-potenziali` / `-scuro` | il percorso del template con le quattro tile complete e le barre piene |
| `851-clienti-potenziali-vuoto` | nessun potenziale: colonne vuote e «Aggiungi un potenziale cliente» |
| `852-clienti-potenziali-senza-stime` | due schede senza stima/probabilità: «stima da inserire», tile con «2 senza stima» |
| `853-clienti-potenziale-dettaglio` | il dettaglio di Davide Sala aperto dalla scheda |
| `854-clienti-passaparola` / `-scuro` | l'albero del template, ambasciatori, momento giusto, colonne degli anni |
| `855-clienti-passaparola-vuoto` | nessun `presentatoDa`: «Tu» e i clienti senza legami, ambasciatori «Nessuno ancora», niente card arancio |
| `856-clienti-passaparola-fittizi` | con i 30 clienti fittizi: primo livello ridotto e «+ N clienti senza presentazioni» |
| `857-clienti-passaparola-calmo` | «Riduci movimento»: identica a 854 (controllo che non manchi nulla) |
| iOS `76-potenziali-iphone` | iPhone: Clienti › Potenziali come elenco per fase |

#### 9.2.8 Regole di CLAUDE.md toccate e decisioni per l'utente

Regole toccate: dati personali (anche di **persone che non sono clienti**); principio di analisi (il percorso serve a
capire il lavoro, non a vendere: Prisma non suggerisce pressioni); Ruby solo con Qwen locale e numeri da Prisma; dati di
prova dichiarati; memoria (albero con molti nodi); macOS 13 (`.draggable`, `.dropDestination`, `matchedGeometryEffect`:
tutte disponibili).

- **Decisione 2.1 — Potenziali separati o clienti con uno stato.** Proposta: **elenco separato**
  (`DatiPrisma.potenziali`), perché tutti i motori di oggi (Messaggi, Analisi, Agenda, Mercato, Territorio) contano
  `clienti` come clienti veri; un potenziale diventa `Cliente` solo con la conferma. Alternativa: `Cliente.stato`
  (cliente/potenziale) con un filtro in ogni motore.
- **Decisione 2.2 — Privacy dei potenziali (dati di terzi).** I potenziali presentati da un cliente sono persone che non
  hanno ancora dato nulla a Prisma: nome, telefono e una stima del loro patrimonio sono dati personali raccolti presso
  terzi (informativa da dare, art. 14 GDPR). Proposta: campo «informativa data il» e, finché manca, nessun messaggio da
  Messaggi verso il potenziale e un segno grigio «informativa da dare» sulla scheda; la stima del patrimonio è facoltativa.
  Le regole precise (tempi, cancellazione dei potenziali «non interessati» dopo N mesi) le decide l'utente.
- **Decisione 2.3 — Probabilità ed «entro fine anno».** Il template mette una probabilità per scheda e somma tutto come
  «entro fine anno» senza una data. Proposta: probabilità scritta dall'utente (nessuna predefinita), data di chiusura
  prevista facoltativa, e la tile conta solo chi ha tutte e tre; se l'utente preferisce, la tile si chiama «Valore pesato
  del percorso» e non parla di anno.
- **Decisione 2.4 — Profondità dell'albero.** Il template ha due livelli. Proposta: fino a tre generazioni visibili
  (Tu → cliente → presentato → presentato dal presentato), oltre «+ N» che apre il ramo.
- **Decisione 2.5 — «Il momento giusto per chiedere».** Serve una regola (proposta: traguardo o firma negli ultimi 7
  giorni, consenso commerciale valido, nessuna richiesta negli ultimi 180 giorni) e la richiesta di presentazione va
  trattata come **messaggio commerciale** (serve il consenso). Il testo non attribuisce emozioni al cliente («è contenta»
  diventa il fatto: «ha raggiunto la rendita ieri»).
- **Decisione 2.6 — Ambasciatori.** Il template somma clienti e potenziali presentati. Proposta: due cifre («portato»
  e «in arrivo»).
- **Decisione 2.7 — Potenziali, aziende e campagne in «Prisma ovunque».** Se lo spazio cifrato è acceso, l'istantanea
  `istantanea.cifrato` porta oggi l'archivio senza documenti, conversazioni e trascrizioni: con la versione 27 porterebbe
  anche `DatiPrisma.potenziali` (dati di **persone che non sono clienti** e non hanno dato nulla a Prisma),
  `Cliente.aziende` (dentro il cliente) e `DatiPrisma.campagne`. Proposta: aziende e campagne sì (sono dati del cliente
  già nello spazio); i potenziali solo se l'utente lo sceglie (interruttore in Impostazioni › Prisma ovunque, spento),
  così l'iPad in sola lettura del §2.4 li mostra solo con quel consenso. Va aggiornata `Prisma --prova-ovunque`.
- Nessuna rete, nessuna dipendenza. Nessun testo normativo da scrivere oltre a quelli della Decisione 2.2.

---

### 9.3 I clienti imprenditori

*Voce Novità 12: «I clienti imprenditori · L'azienda accanto al titolare», glifo `azienda` su #3F5A78 (`NOVL[11]`, riga
2066): `vaiA('clienti', vistaC='rub', selCli=1, tabCli='azienda')` (Marco Bianchi). Nel dossier il segmentato delle
schede aggiunge **«L'azienda»** solo per chi è «Imprenditore» (riga 569; riga 561: passando a un cliente non imprenditore
la scheda torna a «Panoramica»). Codice: `aziendaHTML` righe 2034-2036, aggancio riga 2081; dopo il cambio di scheda
`dopoTab` (riga 608): `inclina`, `entrata`, `conteggi`, `accendi` (anelli), `linee`, `barre`.*

#### 9.3.1 Cosa si vede

Schermata `09-c-azienda.png`. Nel dossier di Marco Bianchi, sotto le quattro tessere, il segmentato **Panoramica ·
Obiettivi · Linea della vita · Nel tempo · Famiglia · L'azienda** con «L'azienda» scelta. Il contenuto (area 1081×399
nel dossier):

**1.1 Testata dell'azienda** (card piatta, padding 18/22, in riga con spazio 16):
- il tassello del glifo `azienda` (48, #3F5A78);
- **«Bianchi Serramenti S.r.l.»** (display 21, 700) e sotto `.k`: **«Azienda di prova · 14 dipendenti · Marco Bianchi
  socio al 70% e amministratore»**;
- a destra, allineati a destra: `.k` **«Fatturato 2025»** e **«2,1 mln €»** (20 grassetto).

**1.2 Quattro schede** (griglia a 4 colonne, spazio 12, 12 sopra; ogni scheda `.card.tilt` con inclinazione massima 5,
padding 18, senza ombra, in colonna):
- in alto a sinistra un **anello** di 76 con spessore 9 (un solo valore, nel colore della scheda) e al centro la
  percentuale (15 grassetto);
- il **titolo** (15 grassetto, 12 sopra);
- il **testo** (`.k` 12,5, interlinea 1,45, 4 sopra, riempie lo spazio);
- in fondo il **collegamento** (blu `--accent`, 13 / 600, 10 sopra) con «›».

| Scheda | % | Colore | Testo | Collegamento |
|---|---|---|---|---|
| **Persona chiave** | 0 | #E5484D | «Se Marco si ferma, l'azienda perde circa sei mesi di fatturato. Oggi nessuna copertura.» | «Proponi una key man ›» |
| **TFM degli amministratori** | 0 | #E08A00 | «Nessun trattamento di fine mandato accantonato: un'occasione da valutare con il commercialista.» | «Simula il TFM ›» |
| **Welfare aziendale** | 35 | #0A84FF | «Solo buoni pasto. Premi di risultato e previdenza per i dipendenti sono da valutare.» | «Proponi un piano ›» |
| **Passaggio dell'impresa** | 10 | #8B5CF6 | «Figli di 9 e 1 anno: nessun piano di continuità, né patto di famiglia.» | «Apri la pianificazione ›» |

**1.3 Piede** (`.k`, 12 sopra): **«Dati aziendali di prova. Le valutazioni fiscali vanno sempre verificate con il
commercialista dell'azienda.»**

Nel template i collegamenti sono solo testo (nessuna azione) e le percentuali sono scritte a mano: in Prisma vanno
definite (§5.2.3, Decisione 3.2).

**1.4 Stati da aggiungere**
- **Cliente senza azienda registrata**: la scheda «L'azienda» non è nel segmentato; nel menu «Altro» delle schede c'è
  «Azienda» con «Aggiungi l'azienda di Marco» (così si registra anche per chi non ha «imprenditore» nella professione).
- **Azienda registrata ma con pochi dati**: la testata mostra solo il nome; le cifre mancanti dicono «fatturato da
  inserire», «dipendenti da inserire»; le schede la cui valutazione dipende da un dato mancante mostrano l'anello vuoto
  grigio con «—» e il testo «Per valutarla servono il fatturato e il reddito che Marco ne ricava» con «Inserisci i dati».
- **Più aziende** (socio di due società): segmentato piccolo con i nomi sopra la testata, o una scheda per azienda; vedi
  Decisione 3.4.
- **Area valutata come non pertinente** (es. nessun dipendente → welfare): scheda in grigio con «Non pertinente» (riusa
  `Cliente.datiNonPertinenti` della versione 21, `Dati/Modelli.swift:56-58`, con chiave «azienda:welfare»).

#### 9.3.2 Misure e stile

Token nuovi in `DesignSystem/Apple/Tema.Apple+Dossier.swift` (esiste) o in un file nuovo `Tema.Apple+Azienda.swift`
(`Tema.Apple.Azienda`):

| Elemento | Template | Token |
|---|---|---|
| testata | card piatta, padding 18/22, spazio 16 | `Superficie.cardPiatta`, **nuovi** `Azienda.paddingTestata = padding(18, 22)`, `spazioTestata = 16` |
| tassello | 48, glifo `azienda` #3F5A78 | `TasselloGlifo(glifo: .azienda, lato: 48)` (parte comune), colore `Tema.Apple.Colore.Glifi.azienda` |
| nome | display 21, 700 | **nuovo** `Azienda.nome = C(dimensione: 21, peso: .bold, tracking: -0.4)` (come `.h2` del template) |
| riga sotto | `.k` | `Carattere.secondario`, `Colore.inchiostro2` |
| fatturato | 20 grassetto | `Carattere.meseAgenda` è 20 bold ma ha un altro senso: **nuovo** `Azienda.fatturato = C(dimensione: 20, peso: .bold, tabellare: true)` |
| griglia | 4 colonne, spazio 12 | **nuovo** `Azienda.spazioSchede = 12`, `colonne = 4` (2 sotto `larghezzaMinimaDossier` 560: `Tema.Apple.Clienti.larghezzaMinimaDossier`) |
| scheda | padding 18, raggio 22, senza ombra, inclinazione 5 | `Superficie.cardPiatta`, `SchedaInclinabileApple` con **nuovo** `Azienda.inclinazioneMassima = 5` |
| anello | 76 / 9, un valore | `Anello` (`AnelliApple.swift:104`) con **nuovi** `Azienda.anello = 76`, `spessoreAnello = 9`; percentuale 15 grassetto: **nuovo** `Azienda.percentuale = C(15, .bold, tabellare)` |
| colori | #E5484D, #E08A00, #0A84FF, #8B5CF6 | `Colore.rosso` (o `Colore.Area.protezione`, #E5484D), `Colore.arancio`, `Colore.Area.investimenti` (#0A84FF), `Colore.stima`/`Colore.Area.previdenza` (#8B5CF6): esistono tutti (`TemaApple.swift:82-129`; non esiste un `Colore.Grafico`: `Tema.Apple.Grafico` sono le misure di anelli e grafici); **nuovo** `Azienda.Tinta` che li mappa per area |
| titolo / testo | 15 grassetto / 12,5 interlinea 1,45 | `Carattere.titoloRiga` (15 bold), **nuovo** `Azienda.testo = C(dimensione: 12.5, peso: .regular, interlinea: 1.45)` |
| collegamento | 13 / 600 blu | **nuovo** `Azienda.collegamento = C(dimensione: 13, peso: .semibold)`, `Colore.accento` |
| piede | `.k` 12 sopra | `Carattere.secondario` |

#### 9.3.3 Movimento

Come le altre schede del dossier (`Tema.Apple.Clienti.Moto`, `Tema.Apple.Moto.CambioScheda`):
- cambio di scheda: uscita 0,13 s, poi cascata `EntrataApple` (base `Clienti.Moto.baseCambio`);
- numeri della testata (dipendenti, quota, fatturato) contati con `NumeroCheConta`;
- **anelli** che si riempiono: `Moto.Anello` (1,4 s, passo 0,13) con il ritardo `Clienti.Moto.ritardoAnelli` (0,15, come
  `accendi(t,150)` del template);
- schede che si inclinano verso il puntatore (max 5°, `Moto.Inclinazione`).

**Riduci movimento**: niente inclinazione né cascata; anelli già pieni, numeri completi, dissolvenza 0,15 s.
**Istantanee**: anelli pieni al valore, numeri completi.

#### 9.3.4 Interazioni

- Scheda «L'azienda» nel segmentato del dossier (solo se il cliente ha un'azienda registrata); dal pannello Novità apre il
  primo cliente con un'azienda (nel template Marco: in Prisma il primo per nome con `aziende` non vuoto; se nessuno, apre
  Clienti con l'avviso «Nessun cliente ha un'azienda registrata: aggiungila dal dossier»).
- **Clic sulla testata** o «Modifica» (⌘E): `ModuloAzienda` (foglio, come `ModuloFamiliare`): ragione sociale, forma
  (S.r.l., S.p.A., S.n.c., S.a.s., ditta individuale, altro), partita IVA (controllata con
  `MotoreFattura.partitaIVAValida`), settore, dipendenti, fatturato dell'ultimo anno (e l'anno), utile, ruolo del cliente
  (socio con quota %, amministratore, titolare), reddito che il cliente ne ricava, e per ogni area i dati del §5.2.3.
- **Le quattro schede**: clic sulla scheda = dettaglio che nasce dalla scheda (`DettaglioApple`) con il calcolo spiegato
  (la cifra, da dove viene, cosa manca) e i dati da completare; il **collegamento** in fondo porta al lavoro vero:
  - «Proponi una key man ›» → Pratiche › «La proposta si costruisce da sola» (parte 07) con il bisogno «persona chiave»
    e il capitale suggerito (§5.2.3), canale scelto dall'utente;
  - «Simula il TFM ›» → **non esiste un simulatore del TFM** (c'è quello del TFR, `Motori/MotoreTFR.swift`, che è un'altra
    cosa): Decisione 3.3. Proposta: in questo giro il collegamento apre il dettaglio con i dati e la nota «da valutare con
    il commercialista», senza calcoli fiscali;
  - «Proponi un piano ›» → Pratiche › proposta, bisogno «welfare per i dipendenti» (o previdenza collettiva);
  - «Apri la pianificazione ›» → Analisi 360 › area del patrimonio/successione (il bisogno `successione` esiste già in
    `MotoreBisogni`, `Motori/MotoreBisogni.swift:84`).
- In modalità cliente la scheda si vede (è analisi del cliente presente), ma senza i collegamenti che portano a
  Pratiche.
- **iPad**: la scheda c'è nel dossier (sola lettura). **iPhone**: nel dossier, una riga «L'azienda» con nome e fatturato
  che apre le quattro aree come elenco.

#### 9.3.5 Mappa verso Prisma

**5.1 Esiste già**

| Cosa | Dove |
|---|---|
| Schede del dossier | `enum SchedaCliente` (`Shell/StatoShell.swift:3168-3196`); `SchedaCliente.delSegmentato` e `dellAltro` (`Shell/DossierApple.swift:24-26`); `AppClienti.schedaDossier(_:_:)` (`Shell/AppClienti.swift:182-200`); segmentato `SegmentatoPillola(... SchedaCliente.delSegmentato ...)` (`DossierApple.swift:701`) |
| Professione | `Cliente.professione` (stringa libera; nei dati di prova Marco è «Ingegnere», `Dati/DatiDemo.swift:93`; tra i fittizi c'è «Imprenditore edile», `Dati/ClientiFittizi.swift:511`) |
| Famiglia | `Cliente.famiglia: [Familiare]` con `Relazione` e età (per «figli di 9 e 1 anno») |
| Bisogni | `MotoreBisogni.rileva` (`Motori/MotoreBisogni.swift:17`): `protezione-famiglia`, `successione`, eventi `avvioAttivita` |
| Dati non pertinenti | `Cliente.datiNonPertinenti` (`Dati/Modelli.swift:56-58`) |
| Partita IVA | `MotoreFattura.partitaIVAValida` (`Motori/MotoreFattura.swift:430`) |
| Posizioni del cliente | `Posizione` (`Dati/Posizione.swift`) con `area`, `capitaleAssicurato`, `rischio: RischioCoperto?` |
| Anelli e schede | `Anello`, `SchedaInclinabileApple`, `DettaglioApple` |

**5.2 Cosa va creato**

1. **Modello** `Dati/AziendaCliente.swift` (versione 27, `Cliente.aziende: [AziendaCliente]?`, letto con `try?`):
   ```swift
   enum FormaAzienda: String, Codable, CaseIterable { srl, spa, snc, sas, ditta, altro }
   struct AziendaCliente: Identifiable, Codable, Hashable {
       var id: String
       var ragioneSociale: String
       var forma: FormaAzienda?
       var partitaIVA: String?
       var settore: String?
       var dipendenti: Int?
       var fatturato: Double?; var annoFatturato: Int?
       var utile: Double?
       var quota: Double?            // % del cliente
       var amministratore: Bool?
       var redditoDalCliente: Double? // compensi + utili che il cliente ne ricava all'anno
       var personaChiave: PersonaChiave?      // mesi di fatturato a rischio, scritti dall'utente
       var tfm: StatoTFM?                     // accantonato sì/no, importo, nota
       var welfare: StatoWelfare?             // voci presenti (buoni pasto, premi di risultato, previdenza…)
       var continuita: StatoContinuita?       // piano, patto di famiglia, successori indicati
       var nota: String = ""
   }
   ```
   Un campo per area, tutti facoltativi; nessuna cifra predefinita.
2. **Scheda** `SchedaCliente.azienda` (titolo «L'azienda»): in `delSegmentato` **solo se** `cliente.aziende` non è
   vuoto (oggi `delSegmentato` è statico: diventa `static func delSegmentato(per: Cliente)`), altrimenti in `dellAltro`
   come «Azienda» (aggiungere). `schedaDossier` → `AziendaDossier(cliente:)` in un file nuovo `Shell/DossierAzienda.swift`.
   Il ritorno a «Panoramica» quando si cambia cliente (riga 561 del template) c'è già in Prisma per le schede che non
   esistono per il cliente nuovo? Da verificare in `cambiaScheda` (`DossierApple.swift:456`): se no, aggiungerlo.
3. **Motore** `Motori/MotoreAzienda.swift` (puro, con prova `ProvaCalcoliAzienda`): per ogni area un
   `ValutazioneArea { percentuale: Double?; frase: String; mancano: [String]; azione: AzioneArea }`. **Le percentuali vanno
   definite** (Decisione 3.2); proposta:
   - **Persona chiave** = capitale delle coperture «key man» in essere intestate all'azienda o al cliente con beneficiaria
     l'azienda ÷ fabbisogno, dove il fabbisogno = fatturato × mesi a rischio ÷ 12 (i **mesi a rischio li scrive
     l'utente**: «circa sei mesi» del template è una valutazione, non un calcolo). Senza fatturato o senza mesi: `nil`.
   - **TFM** = 0% o 100% (accantonato sì/no, con l'importo se c'è): nessun calcolo fiscale in Prisma (Decisione 3.3).
   - **Welfare** = voci attive ÷ voci considerate dall'utente (checklist: buoni pasto, premi di risultato, previdenza
     complementare per i dipendenti, assistenza sanitaria, altro). Il 35% del template non corrisponde a nessuna frazione
     semplice («solo buoni pasto» sarebbe 1 voce su 5 = 20%, o 1 su 3 = 33%): è una cifra dimostrativa, non va riprodotta.
   - **Passaggio dell'impresa** = passi fatti ÷ passi della checklist (successore indicato, piano di continuità, patto di
     famiglia valutato, coperture per i soci, statuto/clausole valutati): con questi cinque passi il minimo non nullo è
     20%, quindi il 10% del template (dimostrativo) non si ottiene; **la lista dei passi la decide l'utente**.
   La frase della scheda è un modello fisso con i dati veri (`TestiAzienda`), mai una frase inventata; «Figli di 9 e 1
   anno» viene da `Cliente.famiglia`.
4. **Modulo** `Shell/ModuloAzienda.swift` (foglio) e la voce «Aggiungi l'azienda» nel menu «Altro» del dossier.
5. **Bisogni**: `MotoreBisogni.rileva` può aggiungere i bisogni «persona chiave» e «continuità dell'impresa» quando
   l'azienda c'è e la valutazione è bassa (con il motivo, come gli altri bisogni), così entrano nel profilo dei bisogni e
   nelle campagne (§4).
6. **Pannello Novità**: `NovitaLuce.imprenditori` → `vistaClienti = .rubrica`, cliente = primo con azienda,
   `schedaCliente = .azienda`.
7. **Ruby**: il contesto del cliente (`Ruby/ContestoRuby.swift`) aggiunge l'azienda (ragione sociale, fatturato, quota,
   valutazioni) solo in modalità lavoro; istruzione in `Ruby/Istruzioni/chat.md`: «per le questioni fiscali dell'azienda
   rimanda sempre al commercialista».
8. **Dati di prova**: l'azienda del template («Bianchi Serramenti S.r.l.», 14 dipendenti, 70%, amministratore, 2,1 mln €
   nel 2025) sul cliente di prova Marco Bianchi in `DatiDemo` (dichiarata «di prova»), e una per «Francesco Moretti,
   Imprenditore edile» tra i fittizi. La professione di Marco nei dati di prova resta quella di oggi; la scheda dipende
   dall'azienda, non dalla parola «Imprenditore».
9. **Backup**: `Cliente.aziende` dentro il cliente; prova in `ProvaBackupLuceClienti` (un'azienda completa e una con il
   solo nome).

#### 9.3.6 Dati che l'utente deve dare e stati vuoti

Tutti i dati dell'azienda: **ragione sociale, forma, partita IVA, dipendenti, fatturato e anno, quota e ruolo del
cliente, reddito che il cliente ne ricava**; per le aree: **mesi di fatturato a rischio** se il titolare si ferma,
**TFM accantonato** (sì/no, importo), **voci di welfare attive**, **passi della continuità**. Nessuna fonte esterna
(nessuna visura online: Prisma non va in rete). Senza un dato, l'anello è grigio «—» e la scheda dice cosa manca (§1.4).
Il piede «Le valutazioni fiscali vanno sempre verificate con il commercialista» resta sempre; «Dati aziendali di prova»
solo sui dati di prova.

#### 9.3.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `858-dossier-azienda` / `-scuro` | Marco Bianchi con l'azienda di prova: testata e quattro schede con gli anelli pieni (0, 0, 35, 10) |
| `859-dossier-azienda-da-completare` | azienda con il solo nome: «fatturato da inserire», anelli grigi «—» e «Inserisci i dati» |
| `860-dossier-azienda-modulo` | il foglio `ModuloAzienda` aperto |
| `861-dossier-azienda-stretta` | finestra stretta: griglia a 2 colonne |
| iOS `77-azienda-ipad` | iPad, dossier di Marco, scheda «L'azienda» |

#### 9.3.8 Regole di CLAUDE.md toccate e decisioni per l'utente

Regole toccate: principio di analisi (la scheda analizza i bisogni del titolare legati all'azienda: in linea);
canale sempre riconoscibile (le proposte che nascono dai collegamenti portano il canale); dati personali e patrimoniali
(anche dell'azienda) solo sul Mac; nessun testo normativo inventato.

- **Decisione 3.1 — Quando compare la scheda.** Il template la lega alla professione «Imprenditore». Proposta: compare
  quando il cliente ha **almeno un'azienda registrata**; si aggiunge da «Altro › Azienda» per chiunque.
- **Decisione 3.2 — Cosa misurano le percentuali.** Il template non lo dice. Proposta del §5.2.3 (copertura della
  persona chiave, sì/no del TFM, checklist del welfare e della continuità con le voci scelte dall'utente). Da approvare,
  o da sostituire con un semplice «stato» (da valutare / in corso / fatto) senza anello.
- **Decisione 3.3 — TFM, welfare, patto di famiglia: testi normativi.** Le frasi del template toccano regole fiscali e
  civilistiche (deducibilità e tassazione del trattamento di fine mandato; regime dei premi di risultato e del welfare
  aziendale; patto di famiglia, artt. 768-bis e seguenti c.c.). Prisma **non** scrive regole né calcoli fiscali su questi
  temi senza testi e parametri forniti e verificati dall'utente (o dal commercialista). Proposta: nessun simulatore del
  TFM in questo giro; solo dati, stato e la frase «da valutare con il commercialista».
- **Decisione 3.4 — Più aziende per cliente.** Proposta: sì (array), con una scelta in testa alla scheda.
- **Decisione 3.5 — Prodotti «key man» e welfare.** Le proposte nascono in Pratiche con i prodotti dell'archivio; le
  caratteristiche dei prodotti Alleanza e indipendenti per l'azienda (key man, previdenza collettiva) sono **dati di
  prodotto** che l'utente deve inserire: senza, la proposta dice «nessun prodotto adatto in archivio».
- Nessuna rete, nessuna dipendenza, nessuna API sopra macOS 13.

---

### 9.4 Le campagne

*Voce Novità 9: «Le campagne · Lo stesso bisogno, tanti clienti, un tocco», glifo `campagna` su #C45A75 (`NOVL[8]`, riga
2065): `vaiA('messaggi', vistaM='camp')`. In Messaggi la testata ha il segmentato **Messaggi · Campagne** (`vistaM`,
righe 2075-2077); «Messaggi» è «Prisma scrive per te» di Orizzonte (§5 della specifica di Orizzonte), «Campagne» è la
vista nuova. Codice: `CAMP` riga 1980, `campHTML` 1981-1982, `montaCamp` 1983-1989, `campDett` 1990-1996.*

#### 9.4.1 Cosa si vede

Schermate `09-c-camp.png`, `09-s-camp.png`, `09-c-camp-btp.png`, `09-c-camp-avviata.png`. Testata: «Prisma scrive per
te.» con l'occhiello «RUBY PREPARA, TU SPEDISCI» e a destra il segmentato **Messaggi · Campagne** (Campagne scelta).

**1.1 La mappa dei bisogni** (a sinistra, card larga 860 a tutta altezza, fondo radiale 700×500 al 50%/45% da `--cardE`
a `--card`):
- etichetta `.lbl` (a 22/18): **«35 CLIENTI · 4 GRUPPI CON LO STESSO BISOGNO»**;
- **35 pallini**, uno per cliente, partono sparsi a caso e **si radunano** nei gruppi;
- **quattro gruppi** (riga 1980), ciascuno un cerchio tratteggiato (fondo del colore al 7%, tratto del colore al 35%,
  tratteggio 3/6) di raggio **46 + n·7**, con sotto il **nome** (14 grassetto, nel colore) e **«n clienti»** (12,5,
  `--ink2`):

| Gruppo | n | Colore | Centro | Clienti veri nel gruppo |
|---|---|---|---|---|
| «Nessuna protezione per il coniuge» | 7 | #E5484D | (300, 200) | Marco, Giulia |
| «BTP in scadenza a marzo» | 5 | #0A84FF | (620, 180) | Sofia, Laura |
| «Compiono 50 anni nel 2027» | 4 | #8B5CF6 | (280, 470) | Laura |
| «Fondo pensione fermo da un anno» | 6 | #E08A00 | (620, 470) | Giulia, Sofia, Marco |

- i **clienti veri** sono avatar di 26 (cerchio di raggio 13 nel loro colore, bordo bianco 2, iniziali 9,5 grassetto
  bianche) messi in cerchio a 24 dal centro; gli **altri membri** del gruppo sono pallini di raggio 6 nel colore del gruppo
  (opacità .85) sparsi a 50-61 dal centro; i clienti **senza gruppo** restano pallini grigi di raggio 4 (`--ink3` al
  40%) dove sono capitati;
- lo stesso cliente può stare in **più gruppi** (Marco è in «coniuge» e in «fondo pensione»): nel template compare due
  volte.
- Il **gruppo scelto** ha il tratto del cerchio al 90%, gli altri al 25%.

**1.2 Il pannello della campagna** (a destra, da x 876 a tutta larghezza, card senza ombra, padding 20/22):
- `.lbl` nel colore del gruppo: **«CAMPAGNA»**;
- il **nome** (display 23, 700, spaziatura −0,4, interlinea 1,2, 4 sopra): «Nessuna protezione per il coniuge»;
- `.k` (4 sopra): **«7 clienti · Marco, Giulia e altri 5, tra i clienti di prova»**;
- una tile (14 sopra, 13,5, interlinea 1,55): `.k` **«Anteprima per Marco»** e il testo: **«Ciao Marco, guardando il tuo
  piano ho notato una cosa che vale la pena sistemare insieme: oggi in famiglia c'è un reddito senza protezione. Ti va di
  vederci 30 minuti?»** (la frase centrale cambia per gruppo: «a marzo si libera il capitale del tuo BTP», «il prossimo
  anno compi 50 anni, il momento giusto per la pensione», «il fondo pensione è fermo da un anno»);
- `.lbl` (14 sopra, 6 sotto) **«APPUNTAMENTI DA PROPORRE»** e quattro chip (`.chip`, non cliccabili): «mar 10 · 10:00»,
  «mer 11 · 15:30», «gio 12 · 11:00», «ven 13 · 17:00»;
- l'**elenco** (14 sopra): per ogni cliente vero una riga (padding 7/0, filo, spazio 10): avatar 28, nome (13,5), a
  destra lo stato `.k` **«da preparare»**; sotto `.k` **«+ 5 clienti di prova»**;
- in fondo (22 dai lati, 20 dal fondo) il pulsante blu grande a tutta larghezza **«Avvia la campagna»**.

**1.3 Dopo «Avvia la campagna»** (riga 1996): il pulsante si disattiva; riga per riga (300 + k·420 ms) lo stato diventa
**«✓ bozza aperta in Mail»** in verde e la riga lampeggia di verde (.12 → trasparente in 900 ms); alla fine il pulsante
dice **«✓ 7 messaggi pronti · li spedisci tu»**.

**1.4 Stati da aggiungere**
- **Nessun gruppo** (nessun bisogno condiviso da almeno 2 clienti): la mappa con i pallini grigi sparsi e al centro
  «Oggi nessun bisogno riguarda più clienti insieme. Le occasioni del singolo cliente sono in Messaggi.»
- **Clienti senza consenso commerciale** in un gruppo: restano nel gruppo (il bisogno c'è) ma nell'elenco hanno la
  pillola arancio **«senza consenso commerciale»** e non ricevono il messaggio; il pannello lo dice sopra il pulsante
  («5 messaggi: 2 clienti senza consenso commerciale restano fuori»), come Messaggi oggi
  (`Shell/PannelloMessaggio.swift:20`, `:149`).
- **Recapito mancante**: «manca l'indirizzo email nel dossier» (`AperturaMessaggi.mancante(_:)`), la riga è esclusa
  finché non si completa.
- **Già contattato** per lo stesso bisogno negli ultimi 90 giorni (`RegoleMessaggi.giorniCopertura`): «già scritto il 2
  ottobre», escluso di base, includibile a mano.
- **Ruby non è pronta**: i messaggi si preparano con il modello fisso di Prisma (come «Ruby non è pronta» di Messaggi,
  istantanea `494-messaggi-ruby-non-pronta`), con l'avviso.
- **Agenda piena**: «Nessuno spazio libero nelle prossime due settimane» al posto dei chip.
- **Dati di prova**: «tra i clienti di prova» compare solo con i clienti fittizi caricati.

#### 9.4.2 Misure e stile

Token nuovi in `DesignSystem/Apple/Tema.Apple+Messaggi.swift` (esiste: `Disposizione`, `Colonna`, `Voce`, `Pannello`,
`Testo`, `Cifre`, `Barra`, `Vuoto`, `Telefono`, `Moto`), sezione **`Tema.Apple.Messaggi.Campagne`**:

| Elemento | Template | Token |
|---|---|---|
| mappa | card 860, fondo radiale 700×500 a 50%/45% `--cardE` → `--card` | **nuovi** `Campagne.larghezzaMappa = 860` (quota 0,62 se la finestra è più stretta), `fondoMappa = RadialGradient(cardPiena → card, centro (0.5, 0.45), raggio 600)`; raggio `Raggio.card` |
| etichetta | `.lbl` a 22/18 | `Carattere.etichetta`, **nuovo** `Campagne.etichettaMargine = (22, 18)` |
| cerchio del gruppo | r = 46 + n·7, fondo .07, tratto .35 (.9 scelto, .25 gli altri), tratteggio 3/6 | **nuovi** `Campagne.raggioBase = 46`, `raggioPerCliente = 7` (con un massimo: `raggioMassimo = 120`, per i gruppi da 40 clienti), `fondoGruppo = 0.07`, `tratto = 0.35`, `trattoScelto = 0.9`, `trattoAltri = 0.25`, `tratteggio = [3, 6]` |
| nome del gruppo | 14 grassetto nel colore; «n clienti» 12,5 `--ink2` | **nuovi** `Campagne.nomeGruppo = C(14, .bold)`, `contoGruppo = C(12.5, .regular)`; distanze 66 e 84 sotto il centro + n·7 → `sottoCerchio = 20`, `sottoNome = 18` |
| colori dei gruppi | #E5484D, #0A84FF, #8B5CF6, #E08A00 | dal **tipo di bisogno**, non a caso: `Colore.rosso`/`Colore.Area.protezione` (protezione), `Colore.Area.investimenti` #0A84FF (scadenze), `Colore.stima` #8B5CF6 (età/pensione), `Colore.arancio` (previdenza ferma); **nuovo** `Campagne.tinta(per: TipoGruppoCampagna)` |
| avatar nella mappa | r 13, bordo bianco 2, iniziali 9,5 | `AvatarCliente` a 26 con **nuovo** `Campagne.avatar = 26`, `bordoAvatar = 2`; iniziali 9,5 grassetto |
| altri membri | r 6, opacità .85 | **nuovi** `Campagne.pallino = 6`, `opacitaPallino = 0.85`, distanza 50-61 |
| senza gruppo | r 4, `--ink3` .4, colore #9FB3C2 | **nuovi** `Campagne.pallinoLibero = 4`, `opacitaLibero = 0.4`, colore `Colore.inchiostro3` (#9FB3C2 = `Colore.Composizione.liquidita` del portafoglio, `TemaApple.swift:137`, ma nel template il colore scritto è poi sostituito da `--ink3`) |
| pannello | da 876 (spazio 16), padding 20/22, senza ombra | `Superficie.cardPiatta`, `Tema.Apple.Messaggi.Disposizione.gioco` (16, esiste), `Misura.Padding.cardMedia` |
| titolo | display 23, 700, −0,4, interlinea 1,2 | **nuovo** `Campagne.titolo = C(dimensione: 23, peso: .bold, tracking: -0.4, interlinea: 1.2)` (fra `titoloGruppo` 22 e `nomeDossier` 27) |
| anteprima | tile, 13,5, interlinea 1,55 | `Superficie.tile`, `Tema.Apple.Messaggi.Testo` (il corpo del messaggio: verificare il carattere; se diverso **nuovo** `Campagne.anteprima = C(13.5, .regular, interlinea: 1.55)`) |
| chip degli appuntamenti | `.chip` (padding 7/14, 13 / 600, fondo pieno, filo) | `ChipBarraApple`/chip del tema (`DesignSystem/Apple/ChipBarraApple.swift`) o **nuovo** `Campagne.chip` con `Misura.padding(7, 14)`, `Carattere.barra` (13 semibold) |
| righe dei clienti | padding 7, avatar 28, 13,5 | **nuovi** `Campagne.paddingRiga = 7`, `avatarRiga = 28`; `Carattere.voceLista` (13,5) |
| stato «bozza aperta» | verde, lampo verde .12 in 0,9 s | `Colore.verde`; **nuovo** `Campagne.lampo = Colore.verde.opacity(0.12)` |
| pulsante | blu grande a tutta larghezza, a 22/20 dai bordi | `StilePulsanteApple` grande; **nuovo** `Campagne.marginePulsante = (22, 20)` |

#### 9.4.3 Movimento

| Momento | Template | Prisma |
|---|---|---|
| entrata della vista | `rimonta` + cascata | `Moto.CambioScheda` + `EntrataApple` |
| pallini | partono in posizioni casuali; dopo 700 ms vanno al gruppo in **1,6 s** `(.34,1.15,.5,1)` | posizioni di partenza **deterministiche** (seme fisso dall'id del cliente: nelle istantanee e tra un'apertura e l'altra non cambiano); **nuovi** `Moto.Campagne.attesa = 0.7`, `raduno = Curva.raduno.animazione(1.6)`, **nuova** curva `Curva.raduno = (0.34, 1.15, 0.5, 1)`. Un solo `withAnimation` su uno stato `radunati: Bool` (posizioni come funzione dello stato), niente `Timer` |
| cerchi dei gruppi | da opacità 0 a 1 in 0,8 s, insieme al raduno | **nuovo** `Moto.Campagne.gruppi = Curva.ease.animazione(0.8)` |
| cambio di gruppo | tratto 0,9/0,25 senza transizione; pannello con `entrata` | tratto con `Moto.Campagne.scelta = 0.25` (`easeOut`); pannello: uscita 0,13 s e cascata, come il cambio di occasione in Messaggi (`Tema.Apple.Messaggi.Moto`) |
| avvio | per ogni riga a 300 + k·420 ms: stato verde e lampo 0,9 s; pulsante a 400 + n·420 ms | le righe cambiano **quando la bozza esiste davvero** (preparazione con il modello fisso: immediata; con Ruby: al ritmo di Qwen), con il ritmo minimo `Moto.TiPreparo` (esiste: 0,22 + i·0,36) e il lampo **nuovo** `Moto.Campagne.lampo = 0.9`; la spunta con `Moto.Spunta` |
| toast | — | `Moto.Toast` («7 bozze pronte in Messaggi: le spedisci tu») |

Con molti clienti (200 fittizi): i pallini senza gruppo non si animano (compaiono fermi), si animano solo i membri dei
gruppi, al più 120 (oltre, i pallini dei gruppi grandi diventano un numero «+ 34» dentro il cerchio): un solo `Canvas` per
i pallini (non 200 viste), per la memoria e la fluidità dell'M1 con 8 GB.

**Riduci movimento**: pallini già al loro posto, cerchi già visibili, righe che cambiano stato senza lampo (dissolvenza
0,15 s). **Istantanee**: tutto radunato, gruppo 1 scelto, tratti come nello stato finale; nella scena «avviata» tutte le
righe in verde e il pulsante finale.

#### 9.4.4 Interazioni

**Mac**
- **Scegliere un gruppo**: clic su qualunque punto del gruppo (cerchio, nome, pallini, avatar: tutto è area del gruppo),
  oppure frecce ↑↓ con il fuoco sulla mappa; il pannello cambia. Passaggio su un pallino: il nome del cliente e «anche
  in: Fondo pensione fermo» se è in più gruppi.
- **Clic su un avatar** con ⌘: apre il dossier del cliente.
- **L'elenco** del pannello mostra **tutti** i membri (non solo i «veri»): ogni riga ha una casella per includerlo o no
  (di base inclusi quelli con consenso e recapito), lo stato, e al passaggio «Vedi il messaggio» (apre l'anteprima di
  quel cliente). L'anteprima in alto si cambia scegliendo un'altra riga.
- **Appuntamenti da proporre**: i chip sono gli spazi liberi veri dell'Agenda nei prossimi 14 giorni lavorativi, dentro
  gli orari di lavoro (`OrariLavoro`), lunghi quanto un primo incontro (30 minuti, come il testo: «Ti va di vederci 30
  minuti?»), al più quattro, uno per giorno. Clic su un chip lo toglie dalla proposta (si possono lasciare da 0 a 4); il
  testo del messaggio li elenca (Decisione 4.5).
- **Tono e canale**: gli stessi controlli di Messaggi (Cordiale · Formale · Breve; Mail · Messaggi), sopra l'anteprima:
  valgono per tutta la campagna.
- **«Avvia la campagna»** (**Decisione 4.3**): Prisma prepara **una bozza per ogni cliente incluso** (`MessaggioCliente`
  con lo stato `bozza`, `origine.tipo = .campagna`, il testo del modello fisso con le cifre di quel cliente e, se Ruby è
  pronta, riscritto da Qwen uno alla volta), le salva in Messaggi e mostra le righe «✓ bozza pronta». **Non apre N
  finestre di Mail da sola**: ogni riga ha «Apri in Mail» (o in Messaggi), e in fondo «Apri la prossima» che le apre una
  alla volta. Il pulsante finale: «✓ 7 messaggi pronti · li spedisci tu». Niente parte da solo, mai.
- **Annulla**: finché nessuna bozza è stata aperta, «Annulla la campagna» toglie le bozze.
- **Storico**: la campagna avviata resta nell'elenco «Campagne avviate» (sotto la mappa o in un menu) con data, gruppo,
  messaggi aperti/da aprire: serve a non riscrivere agli stessi clienti.
- **Collegamento con «Prisma scrive per te»**: le bozze della campagna compaiono anche nella vista Messaggi, nel gruppo
  «Da mandare oggi», con il motivo «Campagna: Nessuna protezione per il coniuge»; aprendo una bozza da lì si può
  modificarla come ogni messaggio (tono, Riscrivi, Salva nel dossier: `PannelloMessaggio`).
- In **modalità cliente** Messaggi non si apre: oggi `StatoShell.appRiservate` (`Shell/ModoCliente.swift:8`) contiene solo
  `.note, .ricerca, .impostazioni`, quindi `.messaggi` va aggiunta (Decisione 4.7).

**iPhone/iPad**: il template non ne parla. Proposta: su iPad la vista Campagne si vede (sola lettura: la mappa e i
gruppi); l'avvio solo sul Mac. Sull'iPhone le bozze già pronte compaiono in Messaggi (`iOS/MessaggiTelefono.swift`) e
si aprono una alla volta come oggi.

#### 9.4.5 Mappa verso Prisma

**5.1 Esiste già**

| Cosa | Dove |
|---|---|
| App Messaggi | `Shell/AppMessaggi.swift` (impianto descritto in testa al file), `Shell/StatoMessaggi.swift`, `Shell/SessioneMessaggi.swift`, `Shell/PannelloMessaggio.swift`, `Shell/AperturaMessaggi.swift` (`mailto:`/`sms:`, `NSSharingService` `.composeEmail`/`.composeMessage`, `email(_:)`, `telefono(_:)`, `recapito`, `mancante`), `Shell/CollegamentiMessaggi.swift` (richieste dalle altre app) |
| Occasioni e regole | `Motori/MotoreOccasioniMessaggi.swift` (`RegoleMessaggi`: `giorniCopertura = 90`, `massimoPerGruppo`, lunghezze; `OccasioneMessaggio` con `commerciale`; `calcola(dati:oggi:)`, `scadenze`, `compleanni`, `consensi`, `riesami`, `occasioniAgenda`, `canaleComune`) |
| Modello del messaggio | `Dati/MessaggioCliente.swift` (`TipoOccasioneMessaggio` con `commerciale`, `OrigineMessaggio`, `TonoMessaggio`, `CanaleMessaggio`, `CifraMessaggio`/`VoceCifraMessaggio`, `StatoMessaggio` `bozza, apertoInMail, apertoInMessaggi, salvato`, `AutoreMessaggio` `ruby = "eve", modelloFisso`, `MessaggioCliente`, `ImpostazioniMessaggi` con le firme per canale) |
| Testi fissi e Ruby | `Motori/ModelliMessaggi.swift`, `Ruby/MessaggiRuby.swift`, `Ruby/Istruzioni/messaggi.md` |
| Consenso commerciale | `stato.consensoCommercialeValido(_:)`, `Consensi.marketing/dataMarketing`, `RegoleConformita.mesiCommerciale` |
| Bisogni | `MotoreBisogni.rileva(cliente:posizioni:analisi:oggi:)` (`Motori/MotoreBisogni.swift:17`): `protezione-famiglia` (riga 38, con «un partner» e il divario delle coperture caso morte), `previdenza-assente`, `previdenza-divario`, `liquidita-ferma`, `successione`, `tutela-mutuo`…; `ProfiloBisogni.esiti` (confermato/scartato) |
| Occasioni del calendario | `Motori/MotoreOccasioni.swift` (`capitaleSottoDebito`, `pensioneVicina`, `aliquotaPrevidenza`, `fineBloccoRiscatto`…, `Dati/Occasione.swift`) |
| Scadenze delle posizioni | `Posizione.scadenza`, `MotoreOccasioniMessaggi.scadenze` |
| Movimenti dei fondi | `Posizione.movimenti: [Movimento]?` (`Dati/Posizione.swift:219`) |
| Spazi liberi | `MotorePianificazione.primoSpazio(durata:da:appuntamenti:orari:…)` (`Motori/MotorePianificazione.swift:128`), `SpazioLibero`, `OrariLavoro` (`Dati/OrariLavoro.swift`) |
| Segmentato in testata | modello `AzioniStudio` (`Shell/StudioApp.swift:161`) |

`grep -ri campagn Sources/Prisma` non trova nulla: modello, motore e vista sono da fare.

**5.2 Cosa va creato**

1. **Vista della testata**: `enum VistaMessaggi: String, CaseIterable { messaggi, campagne }`, `@Published var
   vistaMessaggi` in `StatoShell`, `AzioniMessaggi` in `ContenutoApp.azioni` (`case .messaggi: AzioniMessaggi()`).
   `AppMessaggi.body` sceglie fra la vista di oggi e `VistaCampagne`.
2. **Motore** `Motori/MotoreCampagne.swift` (puro, con `oggi`), che **non inventa bisogni**: raccoglie quelli che i
   motori di oggi già calcolano, per tutti i clienti, e li raggruppa:
   ```swift
   enum TipoGruppoCampagna: String, Codable, CaseIterable {
       case protezioneFamiglia      // BisognoRilevato "protezione-famiglia" non scartato (coniuge/partner, a carico, debiti)
       case scadenzaNelMese         // posizioni in essere con scadenza nello stesso mese, entro 6 mesi (area e titolo comuni: «BTP in scadenza a marzo» solo se il titolo/tipo lo dice)
       case etaTonda                // clienti che compiono 40/50/60 anni l'anno prossimo (soglie in RegoleCampagne)
       case previdenzaFerma         // posizioni di previdenza in essere senza Movimento di versamento da 12 mesi (movimenti noti)
       case previdenzaAssente       // BisognoRilevato "previdenza-assente"
       case liquiditaFerma          // BisognoRilevato "liquidita-ferma"
       // altri dai bisogni esistenti, uno per id stabile
   }
   struct GruppoCampagna: Identifiable { let id: String; let tipo: TipoGruppoCampagna; let titolo: String; let membri: [MembroCampagna] }
   struct MembroCampagna: Identifiable { let clienteId: String; let motivo: String; let cifre: [CifraMessaggio]; let consenso: Bool; let recapito: Bool; let giaContattato: Date? }
   enum MotoreCampagne { static func gruppi(dati: DatiPrisma, oggi: Date, minimo: Int = 2) -> [GruppoCampagna] }
   ```
   Un gruppo esiste solo con almeno 2 membri; i titoli sono modelli fissi (`TestiCampagne`) con i dati veri («BTP in
   scadenza a marzo» richiede che le posizioni siano titoli di Stato: se il motore non lo sa, il titolo è «Posizioni in
   scadenza a marzo»). Dove un dato manca (movimenti assenti) il cliente **non** entra nel gruppo e la nota del gruppo
   lo dice («3 fondi pensione senza movimenti registrati: non valutati»). Le soglie in `enum RegoleCampagne` (come
   `RegoleMessaggi`).
3. **Modello**: `TipoOccasioneMessaggio.campagna` (nuovo caso, `commerciale = true`, nome «Campagna») e un riferimento
   alla campagna in `OrigineMessaggio` (es. `riferimento = "<campagnaId>"`); `struct Campagna: Identifiable, Codable {
   id; gruppoTipo: TipoGruppoCampagna; titolo; avviataIl: Date; tono; canale; clienti: [String]; appuntamenti: [Date];
   messaggi: [String] /* id dei MessaggioCliente */ }` in `DatiPrisma.campagne: [Campagna]` (versione 27, nel backup).
   I messaggi restano `MessaggioCliente` come oggi (`DatiPrisma.messaggi`): una campagna non duplica i testi.
4. **Testo**: `ModelliMessaggi` aggiunge un modello per ogni `TipoGruppoCampagna` × tono, con le cifre del cliente
   (`CifraMessaggio`: il divario di copertura, la scadenza e il capitale, l'età, da quando il fondo è fermo) e gli
   appuntamenti proposti; **mai** nomi o cifre di altri clienti. `Ruby/Istruzioni/messaggi.md`: sezione «Campagna» («ogni
   messaggio è per una persona sola: niente frasi da circolare, niente "abbiamo scritto a tutti"»). Qwen riscrive **uno
   alla volta** (memoria), si può fermare; se non è pronta resta il modello fisso con l'avviso.
5. **Vista** `Shell/MessaggiCampagne.swift`: `VistaCampagne` (mappa + pannello), `MappaCampagne` (un `Canvas` per pallini
   e cerchi, viste sopra solo per gli avatar dei clienti dei gruppi e per l'accessibilità), `PannelloCampagna`
   (titolo, anteprima, chip degli appuntamenti, elenco con le caselle, pulsante), `StoricoCampagne`. Posizioni dei
   gruppi: disposte dal motore di layout (fino a 6 gruppi in griglia 2×3; oltre, i più piccoli in «Altri bisogni»).
6. **Avvio** `StatoShell.avviaCampagna(_:)` in `Shell/CampagneMessaggi.swift`: crea le bozze (`MessaggioCliente`,
   `stato = .bozza`, `autore = .modelloFisso` o `.ruby`), la `Campagna`, e richiede a Messaggi di mostrarle
   (`CollegamentiMessaggi`); l'apertura in Mail usa `AperturaMessaggi` com'è oggi. La conferma di «Apri tutte» oltre 5
   messaggi.
7. **Spazi liberi**: `MotorePianificazione.spazi(durata: 30, giorni: 14, quanti: 4, unoPerGiorno: true, …)` (nuovo,
   costruito su `primoSpazio`), con prova in `Motori/ProvaCalcoliAgenda.swift`.
8. **Collegamento dal radar** (parte 08) e da Analisi 360: «Scrivi a tutti quelli con lo stesso bisogno» apre Campagne
   sul gruppo (`stato.richiestaCampagna = TipoGruppoCampagna`).
9. **Prove**: `Motori/ProvaCalcoliCampagne.swift` (un gruppo nasce solo con ≥ 2 membri; cliente senza consenso escluso
   dall'invio ma visibile; recapito mancante; già contattato entro 90 giorni; previdenza con movimenti assenti = non
   valutata; nessun testo con il nome di un altro cliente; le bozze sono `bozza` e nessuna è aperta da sola);
   `ProvaBackupLuceClienti` (o `ProvaBackupMessaggi` estesa): una campagna con due bozze sopravvive a backup e
   ripristino.
10. **Dati di prova**: nelle scene i quattro gruppi del template con i clienti di prova; nell'archivio solo con i
    fittizi.

#### 9.4.6 Dati che l'utente deve dare e stati vuoti

- Nessun dato nuovo apposta: i gruppi vengono dai dati che ci sono (famiglia, coperture, scadenze, date di nascita,
  movimenti dei fondi, bisogni confermati). Dove mancano, il cliente non entra e il gruppo lo dice.
- Servono: **consenso commerciale** aggiornato (per chi riceve), **email o telefono** nel dossier, **orari di lavoro** in
  Impostazioni (per gli appuntamenti), le **firme** dei due canali in Impostazioni › Messaggi (esistono:
  `ImpostazioniMessaggi.firma(_:)`). Il canale del messaggio è quello comune delle posizioni del cliente
  (`MotoreOccasioniMessaggi.canaleComune`): con canali misti, il pannello chiede quale firma usare.
- Stati vuoti: §1.4.

#### 9.4.7 Istantanee da aggiungere

| Nome | Scena |
|---|---|
| `862-messaggi-campagne` / `-scuro` | la mappa del template radunata, gruppo 1 scelto, pannello con anteprima, chip e elenco |
| `863-messaggi-campagne-btp` | secondo gruppo scelto (controllo del cambio di tinta) |
| `864-messaggi-campagne-avviata` / `-scuro` | dopo l'avvio: righe «✓ bozza pronta», pulsante «✓ 7 messaggi pronti · li spedisci tu» |
| `865-messaggi-campagne-consenso` | due membri senza consenso commerciale: pillole arancio e nota sopra il pulsante |
| `866-messaggi-campagne-vuoto` | nessun bisogno condiviso |
| `867-messaggi-campagne-ruby-non-pronta` | modello fisso con l'avviso «Ruby non è pronta» |
| `868-messaggi-campagne-fittizi` | con i 30 clienti fittizi: gruppi più grandi, «+ N» nei cerchi |
| `869-messaggi-testata-campagne` | testata di Messaggi con «Messaggi · Campagne» (vista Messaggi scelta) |

Le istantanee esistenti `490-498` (Messaggi) vanno rifatte: cambia la testata (il segmentato).

#### 9.4.8 Regole di CLAUDE.md toccate e decisioni per l'utente

Regole toccate: «Prisma non spedisce mai» (Messaggi di Orizzonte: apre Mail o Messaggi già compilati); dati dei clienti
mai fuori dal Mac (Mail è un'app del Mac: il messaggio esce solo quando l'utente preme Invia in Mail, con il server di
posta dell'utente); Ruby solo Qwen locale, numeri da Prisma; memoria con molti clienti; principio di analisi (la
campagna nasce da un'analisi dei bisogni, non da un elenco di vendita).

- **Decisione 4.1 — Quali gruppi.** Proposta: solo bisogni già calcolati dai motori (elenco del §5.2.2), con le soglie
  scritte in `RegoleCampagne` (età tonde 40/50/60, scadenze entro 6 mesi, fondo fermo da 12 mesi). L'utente approva
  l'elenco e le soglie; nessun gruppo «di marketing» libero in questo giro (eventualmente in seguito: un gruppo da una
  ricerca salvata, `RicercaSalvata`).
- **Decisione 4.2 — Consenso commerciale.** Proposta: la campagna è **sempre commerciale**; chi non ha il consenso valido
  resta escluso dall'invio (visibile nel gruppo con la pillola arancio). Si può includere a mano solo con la conferma,
  come in Messaggi oggi.
- **Decisione 4.3 — Apertura dei messaggi.** Il template apre «una bozza in Mail» per ogni cliente in un colpo solo.
  Proposta: le bozze nascono in Prisma (in Messaggi), e si aprono in Mail **una alla volta** («Apri la prossima»), con
  «Apri tutte» confermato oltre 5. È l'utente che spedisce, sempre. Nessun invio automatico, nessuna spedizione «in
  copia nascosta» a tanti destinatari (ogni messaggio è personale).
- **Decisione 4.4 — Ruby per ogni messaggio.** Con 20 clienti, 20 risposte di Qwen in fila (qualche minuto sull'M1 con 8
  GB). Proposta: il modello fisso subito per tutti, e «Fai riscrivere a Ruby» facoltativo, uno alla volta, interrompibile.
- **Decisione 4.5 — Appuntamenti proposti.** Proposta: gli spazi liberi veri dell'Agenda, solo come testo nel messaggio;
  **non** si bloccano in Agenda (se due clienti scelgono lo stesso orario, l'utente lo vede rispondendo). Alternativa:
  appuntamenti «in attesa» tenuti per 7 giorni.
- **Decisione 4.6 — Un cliente in più gruppi.** Il template lo disegna due volte. Proposta: un pallino per ogni gruppo di
  cui fa parte (il gruppo è il bisogno), con «anche in: …» al passaggio; e una regola: lo stesso cliente non riceve due
  campagne in 30 giorni (soglia da approvare).
- **Testi**: frasi come «Ti va di vederci 30 minuti?» sono commerciali ma non normative; **non** servono testi di
  prodotto. Se un gruppo dovesse nominare un prodotto (es. una TCM Alleanza), il nome e le caratteristiche vengono dai
  prodotti in archivio, mai inventati.
- **Decisione 4.7 — Messaggi in modalità cliente.** Oggi Messaggi non è tra le app riservate
  (`StatoShell.appRiservate = [.note, .ricerca, .impostazioni]`, `Shell/ModoCliente.swift:8`): la mappa delle campagne
  mostra nomi e bisogni di tutti i clienti. Proposta: aggiungere `.messaggi` alle riservate (cambia anche il dock
  dell'iPad in modalità cliente: `iOS/ProvaDockMobile.swift`, da tenere aggiornata).
- **Decisione 4.8 — Il canale «Messaggi» (SMS/iMessage).** Con il canale Messaggi la bozza si apre nell'app Messaggi del
  Mac (`sms:`/`NSSharingService.composeMessage`): l'invio passa per un servizio Apple (iMessage) o per l'operatore
  dell'iPhone, e lo fa l'utente premendo Invia, come per Mail. Nessun invio a WhatsApp o ad altri servizi in questo giro
  (il template non lo chiede); se l'utente lo volesse servirebbe un'altra decisione.
- Nessuna rete, nessuna dipendenza; `NSSharingService` è già usato; `Canvas` (macOS 12): nessuna API sopra macOS 13.

---

### Riepilogo delle decisioni di questa parte

| # | Tema | Proposta |
|---|---|---|
| 1.1 | Dove si legge la carta d'identità | iPhone/iPad col ponte + foto/PDF trascinati sul Mac; niente «Importa dall'iPhone» di macOS |
| 1.2 | Copia del documento (antiriciclaggio) | di base non si salva; interruttore esplicito per salvarla nei Documenti del cliente; obblighi decisi dall'utente |
| 1.3 | Tabella dei codici catastali | includerla in `Risorse/Comuni/` se l'utente approva la fonte; altrimenti «comune non controllato» |
| 1.4 | Pulsante «Nuovo cliente» | apre la scena con «Scrivi a mano»; Importa/Incolla in un menu «…» |
| 1.5 | Testi dei moduli privacy e adeguata verifica | li fornisce l'utente (parte 07) |
| 1.6 | «10 secondi» | contatore del tempo vero |
| 1.7 | Avviso della carta arrivata | avviso interno a Prisma senza nome, nessuna notifica di sistema |
| 2.1 | Potenziali | elenco separato `DatiPrisma.potenziali` |
| 2.2 | Privacy dei potenziali | data dell'informativa; niente messaggi finché manca; tempi di cancellazione dall'utente |
| 2.3 | Probabilità ed «entro fine anno» | probabilità e data scritte dall'utente; nessun valore predefinito |
| 2.4 | Profondità dell'albero | tre generazioni, poi «+ N» |
| 2.5 | Il momento giusto per chiedere | regola sui traguardi, consenso commerciale, niente emozioni attribuite |
| 2.6 | Ambasciatori | «portato» e «in arrivo» separati |
| 2.7 | Potenziali in «Prisma ovunque» | aziende e campagne sì; potenziali solo con un interruttore apposito, spento |
| 3.1 | Quando compare «L'azienda» | se il cliente ha un'azienda registrata |
| 3.2 | Percentuali delle quattro aree | definizioni del §3.5.2.3 o stato senza anello |
| 3.3 | TFM, welfare, patto di famiglia | nessun calcolo fiscale senza testi verificati; «da valutare con il commercialista» |
| 3.4 | Più aziende | sì |
| 3.5 | Prodotti per l'azienda | dati di prodotto dall'utente |
| 4.1 | Gruppi delle campagne | solo bisogni già calcolati, soglie in `RegoleCampagne` |
| 4.2 | Consenso commerciale | campagna sempre commerciale; esclusi senza consenso |
| 4.3 | Apertura in Mail | bozze in Prisma, aperte una alla volta |
| 4.4 | Ruby nelle campagne | modello fisso subito, Ruby facoltativa e in fila |
| 4.5 | Appuntamenti proposti | spazi liberi veri, non bloccati |
| 4.6 | Cliente in più gruppi | un pallino per gruppo; una campagna ogni 30 giorni per cliente |
| 4.7 | Messaggi in modalità cliente | `.messaggi` tra le app riservate |
| 4.8 | Canale SMS/iMessage | l'utente spedisce dall'app Messaggi; niente WhatsApp né altri servizi |

---

## Piano dei giri

Come per Orizzonte: si lavora su un **branch di versione `luce`** aperto da `main`; ogni giro è un branch
`luce/giro-N-…` con una pull request verso `luce`, che si unisce solo con la build verde (macos-15-intel) e dopo aver
guardato le istantanee sul branch `anteprime`. Alla fine `luce` va in `main` con un'ultima PR verde. Ogni giro:
- aggiunge i suoi campi all'archivio nella versione 27 (decisione 103) con `decodeIfPresent` e aggiorna
  `Prisma --prova-backup` (e `--prova-ovunque` se i dati entrano nello spazio cifrato, decisione 44);
- aggiunge i dati di prova in `Dati/DatiDemo.swift` e `Dati/ClientiFittizi.swift`, con l'etichetta «dati di prova»;
- aggiunge le istantanee della sua serie (§0.6) in chiaro e in scuro, aggiorna la vetrina `400-vetrina-apple` dove
  servono componenti nuovi e la pagina online delle anteprime;
- accende nel pannello Novità le voci che completa (le altre restano con «arriva con un prossimo aggiornamento»);
- aggiorna l'elenco del backup in CLAUDE.md quando aggiunge dati che vanno nel backup (decisione 46).

L'ordine segue dipendenze e valore: **prima i giri che non escono dal Mac e non aspettano decisioni**, con Posizioni (il
fulcro) il prima possibile; poi i giri che aspettano decisioni di contenuto (testi, moduli, fonti); per ultimi quelli che
toccano la privacy, i servizi esterni o il lavoro in background.

### Giri senza decisioni bloccanti (si parte subito, con le proposte del §0.5)

| Giro | Novità | File principali (nuovi e toccati) | Prove | Istantanee |
|---|---|---|---|---|
| 1 · Fondamenta di Luce | §1.1 pannello Novità a due gruppi; §1.2 Territorio, Pratiche, Sala, Biblioteca nel dock (testate e stati vuoti), icone, pulsanti della scrivania (Stanotte resta nascosto finché non c'è il giro 13); §1.3 la Sala con griglia, palco, pillole, Esc, presentazione (senza esperienze); §1.4 componenti condivisi: `GlifiLuce`/`TasselloGlifo`, `TelaAnimata`, `TelaShader` (schema dell'acqua), `SovrapposizioneLuce` con l'ordine di Esc e il blocco, estrazione di `TelefonoDisegnato`/`StratoScena` da Inquadra, adattatore `PensioneEsperienze` su `MotorePrevidenza`; versione 27 dell'archivio | `Shell/StatoNovita.swift`, `Shell/PannelloNovita.swift`, `Tema.Apple+Novita.swift`, `Shell/AppPrisma.swift` (casi nuovi, `delDock`), `Dati/SpaziLavoro.swift` (tolleranza), `Shell/Analisi360Apple.swift` (pillole estratte), `Shell/ScenaInquadra.swift`, `Tema.Apple+Inquadra.swift`, `Shell/Presentazione.swift`, `StatoShell.scrivaniaCoperta`, `Design/Icone/` con `genera-icone.js` | `ProvaRuby` (dock), `iOS/ProvaDockMobile`, `--prova-backup` (spazi con app nuove), `--prova-ovunque` | 614-619, 690-695, iOS 54-55; rifare 400, 410, 500, 501, 600-609 |
| 2 · Posizioni: radar e smontaggio | §8.3 il radar del portafoglio (modelli, tolleranza, «Riequilibra» come bozze); §8.2 lo smontaggio (costi cerchiati, confronto con `MotoreSostituzione`) | `VistaPosizioni` a quattro viste, `PortafoglioModello`, `Cliente.modelloId`, `MotoreRadar` su `MotoreAree360.composizione`, `MotoreSmontaggio`, `Tema.Apple.Posizioni.Radar/Smontaggio`, Impostazioni › Modelli; riuso di `InquadraturaPonte` | `ProvaCalcoliRadar`, `ProvaCalcoliSmontaggio`, `--prova-backup`, `--prova-carico` | 880-886, 890-897 |
| 3 · Pratiche: proposta e dopo la firma | §7.0 app Pratiche; §7.1 la proposta si costruisce da sola (catalogo dell'utente, premio «da chiedere»); §7.3 le pratiche dopo la firma (passi riconosciuti dai dati esistenti, notifiche solo interne) | `Tema.Apple+Pratiche.swift`, `StatoShell.schedaPratiche`, `MotoreProposta` su `MotoreSintesi.calcolaProposte`/`MotoreAdeguatezza`/`CompositoreProspetti`, `Dati/Pratica.swift`, `MotorePratiche`, `TipoOccasioneMessaggio.pratica` | `ProvaCalcoliPratiche`, `ProvaBackupPratiche` in `--prova-backup` | 800-807, 820-824 (824 sull'iPhone) |
| 4 · Sala: le esperienze di analisi | §2.2 il prisma di luce (shader Metal, `MotoreLuce`, fermo-immagine); §3.3 disegna il tuo futuro (solo Mac); §4.2 una giornata della pensione; §4.1 il gioco del rischio senza tavolo a doppio senso, testi segnati «testi di prova» | `ShaderLuce`, `ProgrammaLuce`, `TelaLuce`, `RendererLuce`, `PrismaDiLuceFermo`, `MotoreLuce`, `Tema.Apple.Luce`, `MotoreGiornataPensione`, `Analisi360.giornata`, `MotoreGiocoRischio`, `OpzioneLettera` (da `OpzioneOCFVista`), `Risorse/Sala/gioco-rischio.json`, `Tema.Apple+SalaGiochi.swift` | `ProvaCalcoliLuce`, `ProvaCalcoliDisegno`, `ProvaCalcoliSala`, `--prova-backup` | 624-629, 649-652, 660-668, iOS 74 |
| 5 · Studio e relazione | §5.2 la tua settimana e il tuo anno (`MotoreStorie`, `PaginaStoria`, niente paragoni dei km senza tabella); §5.3 la palestra della trattativa (`PalestraRuby`, Qwen locale); §5.4 i traguardi festeggiati **dentro Prisma** (gruppo «Da festeggiare», `MotoreTraguardi`, `Obiettivo.raggiuntoIl`; il biglietto si vede ma non si condivide ancora) | `Tema.Apple.Storia`, `SovrapposizioneLuce.storia`, `Ruby/Istruzioni/palestra.md`, `Ruby/Schemi/palestra.json`, `GruppoMessaggio.festeggiare`, `TipoOccasioneMessaggio.traguardo` | `ProvaRuby` (palestra), `ProvaCalcoliStorie`, `ProvaCalcoliTraguardi`, `--prova-backup` | 710-736 |
| 6 · Biblioteca | §8.1 trova la pagina (BM25 in memoria fuori dal thread principale, risposta di Qwen verificata sul passo, avviso sui parametri superati) | `DocumentoBiblioteca`, cartella `Biblioteca/`, `MotoreBiblioteca`, `BibliotecaRuby`, `Ruby/Istruzioni/biblioteca.md`, `Tema.Apple.Biblioteca`, `Backup.swift` (interruttore «Escludi la Biblioteca») | `ProvaCalcoliBiblioteca`, `ProvaRuby`, `--prova-backup` | 870-877 |
| 7 · Clienti imprenditori | §9.3 la scheda «L'azienda» (dati, stato e anelli solo dove l'utente ha dato i parametri; niente simulatore del TFM) | `Dati/AziendaCliente.swift`, `Cliente.aziende`, `SchedaCliente.azienda`, `MotoreAzienda`, `ModuloAzienda` | `ProvaCalcoliAzienda`, `--prova-backup`, `--prova-ovunque` | 858-861, iOS 77 |

### Giri che aspettano una decisione di contenuto (testi, fonti, dati dell'utente)

| Giro | Novità | Aspetta | File principali | Prove | Istantanee |
|---|---|---|---|---|---|
| 8 · Sala: racconti senza uscita | §3.1 la lettera dal futuro (Qwen in streaming, controllo dei numeri, PDF su carta); §4.3 Lancia l'anno (Monte Carlo, stesso risparmio, carte a mano); §4.4 Quanto vale avermi accanto (solo nel prospetto per il consulente) | 56 (avvertenze), 58 (comunicazione sul valore), 69 (fonti delle probabilità), 77, 80 | `MotoreLettera`, `LetteraFuturo`, `Ruby/Istruzioni/lettera.md`, `Carattere.disegno`, `MotoreLanciaAnno`, `Risorse/Sala/eventi-anno.json`, `Posizione.indennizzoStimato`, `MotoreValoreConsulente`, `Cliente.clienteDal`, Impostazioni › Sala | `ProvaRuby` (lettera), `ProvaCalcoliSala`, `--prova-backup` | 640-643, 670-678 |
| 9 · Spese e scadenze | §6.3 chilometri, spese e scadenze con km scritti dall'utente, scontrini trascinati sul Mac, pacchetto zip senza nomi | 66 (dati fiscali), 14, 22, 100 | `SchedaStudio.spese`, `SpesaStudio`, `ScadenzaStudio`, `CorsoAggiornamento`, `MotoreChilometri`, `LettoreScontrino`, `PacchettoCommercialista`, `ImpostazioniSpese`, `Appuntamento.presso`, `Tema.Apple.Studio.Spese` | `ProvaCalcoliSpese`, `--prova-backup` | 780-789 |
| 10 · Pratiche: moduli | §7.2 compila da solo, solo con i PDF veri caricati dall'utente e prima per il canale indipendente | 60 (Alleanza), 61, 62, 63, 40 (IBAN), 54, 13 | `ModelloModulo`, `CampoModulo`, `DatoModulo`, `RiconoscitoreModulo`, `CompilatoreModuli`, cartella `Moduli/` nel backup, `Cliente.luogoNascita` | `ProvaCalcoliModuli`, `ProvaBackupPratiche` | 810-815 |

### Giri che toccano la privacy, i servizi esterni o il lavoro in background (aspettano il sì dell'utente)

| Giro | Novità | Aspetta | File principali | Prove | Istantanee |
|---|---|---|---|---|---|
| 11 · Territorio | §5.1 il tuo territorio (mappa in Canvas, tabelle locali, giro con stime dichiarate) | 20, 21, 22, 70, 71, 44 (`Cliente.luogo`) | `MotoreTerritorio`, `Risorse/Territorio/`, `Cliente.luogo`, `Appuntamento.doveAvviene`, `Impostazioni.territorio` | `ProvaCalcoliTerritorio`, `--prova-backup`, `--prova-ovunque` | 700-709 |
| 12 · Clienti: potenziali, passaparola, campagne | §9.2 potenziali e passaparola; §9.4 le campagne (bozze in Messaggi una alla volta, consenso commerciale); Messaggi fra le app riservate | 39, 15, 16, 17, 44, 50, 94, 95, 97 | `PotenzialeCliente`, `DatiPrisma.potenziali`, `Cliente.presentatoDa`, `MotorePassaparola`, `MotoreCampagne`, `RegoleCampagne`, `DatiPrisma.campagne`, `TipoOccasioneMessaggio.campagna`, `Curva.mollaLeggera` | `ProvaCalcoliCampagne`, `--prova-backup`, `--prova-ovunque`, `iOS/ProvaDockMobile` | 850-857, 862-869, iOS 76; rifare 490-498 |
| 13 · Dall'iPhone al Mac | §9.1 nuovo cliente in 10 secondi; §6.2 la nota vocale (messaggi nuovi del ponte, coda cifrata sull'iPhone, conferma sul Mac) | 23, 24, 25, 32, 33, 37, 38, 55, 102, 70 (codici catastali) | `MotoreCartaIdentita`, `CodiceFiscale`, `ArrivoPonte.cartaIdentita` e `.notaVocale`, `StatoNuovoCliente`, `ScenaTelefono.cartaIdentita`, `MotoreNotaVocale`, `ApplicaNotaVocale`, `noteInArrivo`, `MessaggiPonte` (versione del protocollo +1) | `ProvaCalcoliCartaIdentita`, prova del ponte, `--prova-backup` | 840-847, 770-777, iOS 75 |
| 14 · Stanotte | §6.1 Stanotte Prisma ha lavorato, con i tipi di carta delle novità già fatte (Moduli, Campagna, Riesame, Domani) | 30, 31, 101, 29 | `MotoreNotte`, `StatoNotte`, `CarteNotte`, `LavoroNotte`, `Tema.Apple+Notte`, `SovrapposizioneLuce.notte` | `ProvaCalcoliNotte` (memoria e ordine dei lavori), `--prova-backup` | 760-767 |
| 15 · Cose date al cliente | §2.1 il Prisma del cliente (PDF protetto sempre, HTML se la prova sui telefoni passa); §3.2 il film del piano (`AVAssetWriter`, foglio di condivisione); §3.4 la capsula del tempo (cifratura, Portachiavi); condivisione del biglietto dei traguardi (§5.4); §7.4 il sinistro come una spedizione con l'aggiornamento al cliente | 1-12, 36, 41, 42, 43, 56, 57, 81, 108, 109 | `ContenutoPrismaCliente`, `CompositorePrismaCliente`, `FilePrismaCliente`, `GeneratorePassword`, lettore JavaScript, `DisegnoFilm`, `RegistaFilm`, `NSSharingServicePicker`, `CapsulaTempo`, `MotoreCapsule`, `PortachiaviCapsule`, `Dati/Sinistro.swift`, `MotoreSinistri` | prova del lettore con Node nel workflow, `--prova-film`, `--prova-backup` (capsule, sinistri), `--prova-ovunque` | 620-623, 644-648, 653-657, 830-836 |
| 16 · Realtà aumentata e tavolo a doppio senso | §2.3 la realtà aumentata (RealityKit, ripiego `.nonAR`, anteprima del Mac); messaggi nuovi del tavolo per rischio, Lancia l'anno, disegno, capsula, scatto | 26, 27, 28, 48, 49, 107, 113 | `ARView` in `UIViewRepresentable`, mesh con `MeshDescriptor`, `Moto.RealtaAumentata`, `ProtocolloTavolo` (generi e messaggi nuovi), `SchermiTavoloiPad` | prove del protocollo del tavolo, `--prova-backup` | 630-632, iOS 70-73 |

Alla fine dei giri: controllo finale come in Orizzonte (pagina delle anteprime completa, voci del pannello Novità tutte
accese o tolte secondo le decisioni, CLAUDE.md aggiornato con le eccezioni approvate) e PR di `luce` verso `main`.
