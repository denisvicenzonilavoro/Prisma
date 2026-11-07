# Istruzioni di Ruby

L'assistente si chiama Ruby (prima si chiamava Eve). Le istruzioni in cui parla in prima persona (`chat.md`, `conversazione.md`, `commento.md`, `messaggi.md`, `verbale-copilota.md`) dicono anche che, se il consulente la chiama ancora Eve, sta parlando con lei, e che non si presenta mai con il nome del modello (Qwen) né dice chi l'ha addestrata. Le altre (`copilota.md`, `documenti.md`, `estrazione.md`, `scenari.md`, `mini.md`) chiedono solo dati o una forma di risposta.

- `chat.md`: istruzioni di sistema della modalità lavoro (domande sul cliente). L'app le legge da `Prisma.app/Contents/Resources/Ruby/Istruzioni/` (il workflow le copia lì); la scheda compatta del cliente preparata da Prisma (`ContestoRuby`) arriva nell'ultimo messaggio, così le istruzioni restano fisse e Ollama le tiene in cache.

- `conversazione.md`: istruzioni di sistema della modalità conversazione (uso generale: ragionare, spiegare, scrivere, riassumere), senza scheda del cliente.

- `mini.md`: come rispondere nella mini finestra di Ruby (⌥ Spazio): poche frasi, senza elenchi, perché le cifre nel dettaglio le mostra la scheda sotto la risposta. Si aggiunge all'ultimo messaggio solo per le domande fatte lì.

- `estrazione.md`: istruzioni per leggere gli appunti degli Incontri e proporre bisogni, eventi di vita e attività in un formato a righe che l'app controlla (`EstrattoreIncontro`). Le proposte vanno sempre confermate dal consulente.

- `commento.md`: istruzioni per scrivere il commento del consulente che apre i report per il cliente (pagina «Due parole per te»). Il modello riscrive la bozza composta da Prisma con le cifre del report; se compare una cifra che non è nella bozza, l'app tiene la bozza (`CommentoRuby`). Il consulente rilegge e salva.

- `documenti.md`: istruzioni per leggere una pagina di KID, polizza o estratto conto e completare i campi che le regole di Prisma (`EstrattoreDocumento`) non hanno trovato. Ogni dato va confermato dal consulente, con la pagina di riferimento.

- `scenari.md`: istruzioni per riconoscere uno scenario «E se…?» su un cliente («e se Marco va in pensione a 63 anni e smette di versare?») ed estrarne i parametri in JSON con lo schema fisso `Ruby/Schemi/scenario.json` (passato a Ollama in «format»). Le cifre scritte nella frase le rilegge anche l'app con le sue regole e vincono; i conti li fa `MotoreScenari`, poi Qwen racconta la scheda prima/dopo con la modalità lavoro (`chat.md`).

- `messaggi.md`: istruzioni per scrivere, a nome del consulente, i messaggi ai clienti dell'app Messaggi («Prisma scrive per te»): tre toni (cordiale con il tu, formale con il lei, breve), mail o messaggio sul telefono, solo le cifre della scheda dell'occasione, niente promesse di rendimento, niente chiusura né firma (le aggiunge Prisma dai dati del consulente). Qwen riscrive la bozza fissa di Prisma (`ModelliMessaggi`); se compare un numero che non è nella scheda, o il testo non rispetta le regole, l'app tiene la bozza (`MessaggiRuby`). Il consulente rilegge e spedisce lui: Prisma apre Mail o Messaggi già compilati, non invia mai.

- `copilota.md`: istruzioni per il copilota dell'incontro: leggere un pezzo della trascrizione (solo testo, riconosciuto sul dispositivo) e restituire in JSON, con lo schema fisso `Ruby/Schemi/copilota.json`, le schede di obiettivi, polizze di altre compagnie, timori sul rischio, eventi della vita e attività, con la frase esatta da cui vengono. L'app scarta ogni scheda con una cifra che non è nella frase; sulle stesse cose vincono le regole di Prisma (`RiconoscitoreCopilota`). Niente entra nel dossier senza la conferma del consulente.

- `verbale-copilota.md`: istruzioni per riscrivere in poche frasi il verbale dell'incontro ascoltato dal copilota, a partire dai punti fissi che Prisma compone dalle schede (`ApplicaCopilota.punto`). Se compare un numero che non è nei punti, l'app tiene il verbale di Prisma (`CommentoRuby.numeriConservati`). Se Qwen non è pronto il verbale è quello di Prisma; il consulente conferma comunque voce per voce cosa entra nel dossier.

Modificare qui il testo cambia il comportamento di Ruby alla build successiva, senza toccare il codice.
Tenere il testo ragionevolmente corto: la finestra di Qwen sul Mac è di 8.192 token per istruzioni, scheda, storia e risposta.
