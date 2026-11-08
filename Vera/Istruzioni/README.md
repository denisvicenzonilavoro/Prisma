# Istruzioni di Vera

L'assistente si chiama Vera (prima si chiamava Ruby, e prima ancora Eve). Le istruzioni in cui parla in prima persona (`chat.md`, `conversazione.md`, `commento.md`, `messaggi.md`, `verbale-copilota.md`) dicono anche che, se il consulente la chiama ancora Ruby o Eve, sta parlando con lei, e che non si presenta mai con il nome del modello (Qwen) né dice chi l'ha addestrata. Le altre (`copilota.md`, `documenti.md`, `estrazione.md`, `scenari.md`, `mini.md`) chiedono solo dati o una forma di risposta.

- `chat.md`: istruzioni di sistema della modalità lavoro (domande sul cliente). L'app le legge da `Prisma.app/Contents/Resources/Vera/Istruzioni/` (il workflow le copia lì); la scheda compatta del cliente preparata da Prisma (`ContestoVera`) arriva nell'ultimo messaggio, così le istruzioni restano fisse e Ollama le tiene in cache.

- `conversazione.md`: istruzioni di sistema della modalità conversazione (uso generale: ragionare, spiegare, scrivere, riassumere), senza scheda del cliente.

- `mini.md`: come rispondere nella mini finestra di Vera (⌥ Spazio): poche frasi, senza elenchi, perché le cifre nel dettaglio le mostra la scheda sotto la risposta. Si aggiunge all'ultimo messaggio solo per le domande fatte lì.

- `estrazione.md`: istruzioni per leggere gli appunti degli Incontri e proporre bisogni, eventi di vita e attività in un formato a righe che l'app controlla (`EstrattoreIncontro`). Le proposte vanno sempre confermate dal consulente.

- `commento.md`: istruzioni per scrivere il commento del consulente che apre i report per il cliente (pagina «Due parole per te»). Il modello riscrive la bozza composta da Prisma con le cifre del report; se compare una cifra che non è nella bozza, l'app tiene la bozza (`CommentoVera`). Il consulente rilegge e salva.

- `documenti.md`: istruzioni per leggere una pagina di KID, polizza o estratto conto e completare i campi che le regole di Prisma (`EstrattoreDocumento`) non hanno trovato. Ogni dato va confermato dal consulente, con la pagina di riferimento.

- `scenari.md`: istruzioni per riconoscere uno scenario «E se…?» su un cliente («e se Marco va in pensione a 63 anni e smette di versare?») ed estrarne i parametri in JSON con lo schema fisso `Vera/Schemi/scenario.json` (passato a Ollama in «format»). Le cifre scritte nella frase le rilegge anche l'app con le sue regole e vincono; i conti li fa `MotoreScenari`, poi Qwen racconta la scheda prima/dopo con la modalità lavoro (`chat.md`).

- `messaggi.md`: istruzioni per scrivere, a nome del consulente, i messaggi ai clienti dell'app Messaggi («Prisma scrive per te»): tre toni (cordiale con il tu, formale con il lei, breve), mail o messaggio sul telefono, solo le cifre della scheda dell'occasione, niente promesse di rendimento, niente chiusura né firma (le aggiunge Prisma dai dati del consulente). Qwen riscrive la bozza fissa di Prisma (`ModelliMessaggi`); se compare un numero che non è nella scheda, o il testo non rispetta le regole, l'app tiene la bozza (`MessaggiVera`). Il consulente rilegge e spedisce lui: Prisma apre Mail o Messaggi già compilati, non invia mai.

- `copilota.md`: istruzioni per il copilota dell'incontro: leggere un pezzo della trascrizione (solo testo, riconosciuto sul dispositivo) e restituire in JSON, con lo schema fisso `Vera/Schemi/copilota.json`, le schede di obiettivi, polizze di altre compagnie, timori sul rischio, eventi della vita e attività, con la frase esatta da cui vengono. L'app scarta ogni scheda con una cifra che non è nella frase; sulle stesse cose vincono le regole di Prisma (`RiconoscitoreCopilota`). Niente entra nel dossier senza la conferma del consulente.

- `verbale-copilota.md`: istruzioni per riscrivere in poche frasi il verbale dell'incontro ascoltato dal copilota, a partire dai punti fissi che Prisma compone dalle schede (`ApplicaCopilota.punto`). Se compare un numero che non è nei punti, l'app tiene il verbale di Prisma (`CommentoVera.numeriConservati`). Se Qwen non è pronto il verbale è quello di Prisma; il consulente conferma comunque voce per voce cosa entra nel dossier.

- `palestra.md`: istruzioni della palestra della trattativa (Studio › Palestra): Vera recita un cliente, con la scheda che Prisma prepara (`PalestraVera.scheda`: chi è, timori, obiettivo e le cifre dei motori), un'obiezione alla volta, e risponde in JSON con lo schema fisso `Vera/Schemi/palestra.json` (giudizio, motivo, replica, convinzione, prossima obiezione, tre risposte suggerite, strumento di Prisma). La difficoltà (Facile, Realistica, Difficile) arriva nell'ultimo messaggio. Una replica o un'obiezione con una cifra che non è nella scheda si scarta e si richiede una volta; una suggerita con una cifra inventata si toglie; sul giudizio vincono le regole di Prisma (pressione, promesse di rendimento, critiche: sempre «debole»). Gli esempi in `Vera/Esempi/palestra.json` sono frasi anonime di prova, da far approvare all'utente.

- `fallo-tu.md`: istruzioni di «Fallo tu» (Vera/BRIEF.md, funzione 1): con la chiamata di strumenti di Ollama («tools») Qwen sceglie le azioni del registro (`RegistroStrumenti`: agenda, attività, note, clienti, messaggi, posizioni, simulatore; Pratiche e i chilometri di Studio sono registrati ma «in attesa»). Prisma risolve gli argomenti e mostra la scheda di conferma: niente si esegue prima di «Conferma».

- `clientela.md`: istruzioni di «Chiedi alla tua clientela» (funzione 2): la domanda su tutti i clienti diventa filtri JSON con lo schema fisso `Vera/Schemi/clientela.json` (in «format» di Ollama). A Qwen va solo la domanda; le regole di Prisma rileggono numeri e mesi della frase e vincono, la ricerca la fa `ClientelaVera` sui dati.

- `filo.md`: il riassunto progressivo di «Il filo lungo» (funzione 24): le battute uscite dalla finestra si riassumono in poche righe, che tornano a Qwen come «IL FILO DELLA CONVERSAZIONE». Senza Qwen resta il riassunto di Prisma (le battute accorciate, prima l'inizio).

- `trenta.md`: «Il cliente in 30 secondi» (funzione 6): Qwen rende scorrevoli le cinque sezioni preparate da Prisma (JSON, schema in `TrentaSecondiVera`); una cifra cambiata o aggiunta fa restare il testo di Prisma.

- `norme.md`: «Il codice in tasca» (funzione 13): risposte solo dagli articoli trovati nella biblioteca delle norme, in JSON con gli id degli articoli; senza articolo o con una cifra che non è nell'articolo la risposta si scarta e Vera dice che la norma non risponde.

- `biblioteca.md`: Biblioteca · «Trova la pagina» («Luce», giro 6): risposte solo dai 6 passi che Prisma trova con BM25 nei documenti della Biblioteca (condizioni, KID, circolari, normativa), in JSON con lo schema fisso `Vera/Schemi/biblioteca.json` (trovato, passo, frase, risposta). Prisma verifica che la frase stia parola per parola nel passo e che le cifre della risposta siano nel passo: altrimenti mostra la pagina senza citazione. A Qwen non vanno mai dati dei clienti.

- `promesse.md`: «Le promesse» (funzione 8): gli impegni del consulente in note, appunti, resoconti e messaggi aperti, in JSON (frase, cosa, quando). Le regole di Prisma li trovano sempre (`PromesseVera.conRegole`); Qwen li cerca solo su richiesta («cerca le promesse di Marco») e una promessa vale solo se la frase è nella fonte.

- `motivazione.md`: la bozza della motivazione di adeguatezza della «seconda lettura» (funzione 10), dalla bozza di Prisma con i controlli della scheda. Una cifra cambiata o una parola a rischio fanno restare la bozza di Prisma; entra nella scheda solo con «Inserisci» e mai se la scheda è firmata.

- `differenze.md`: «Trova le differenze» (funzione 11): la sintesi di due frasi della tabella del confronto (fatta da `DifferenzeVera` con i dati letti dai documenti); una cifra cambiata fa restare la sintesi di Prisma.

- `coperture.md`: «Cosa non copre» (funzione 12): esclusioni, carenze, franchigie e massimali di una polizza, in JSON, ognuna con l'articolo e la frase copiata. L'app scarta le voci senza articolo, con una frase che non è nell'articolo o con cifre che non sono nell'articolo; senza Qwen restano le voci delle regole.

- `resoconto.md`: «Il resoconto dell'incontro» (funzione 16): le sezioni del formato del consulente (presenti, di cosa abbiamo parlato, cosa abbiamo deciso, prossimi passi, da raccogliere) e la versione breve, in JSON. Le sezioni con una cifra nuova restano quelle di Prisma; il resoconto va nei Documenti del cliente come PDF solo con «Firma».

Modificare qui il testo cambia il comportamento di Vera alla build successiva, senza toccare il codice.
Tenere il testo ragionevolmente corto: la finestra di Qwen sul Mac è di 8.192 token per istruzioni, scheda, storia e risposta.

- `lettera.md`: «La lettera dal futuro» della Sala («Luce», giro 8): il cliente, all'età della pensione, scrive a sé stesso di oggi. Qwen riscrive in streaming la lettera fissa di Prisma con le sole cifre della scheda (`MotoreLettera.fatti`: anno ed età al traguardo, obiettivo con la data di arrivo, versamento, pensione con o senza il piano). A fine flusso `LetteraVera.controlla`: una cifra fuori scheda, una promessa, un prodotto o una compagnia nominati, un segnaposto o, nella versione «senza il piano», uno scenario negativo oltre le cifre (decisione 80) fanno restare la lettera di Prisma. Saluto, firma («nome, età anni») e piede li mette Prisma; la lettera resta sul Mac.
