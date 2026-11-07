# Vera — impostazione

Vera è l'assistente AI di Prisma: legge documenti, prospetti e dati dei clienti, li capisce e risponde in chat con spiegazioni, dati e commenti. Tutto avviene sul Mac: nessun dato esce dal computer.

## Storia
Una prima versione di Vera usava modelli Qwen verticalizzati sull'app. Funzionava, ma report e prospetti non venivano bene. Quel lavoro è andato perso: si riparte da zero, e da ora tutto ciò che riguarda Vera (istruzioni, schemi, esempi, test) vive in questa cartella, sotto controllo di versione.

## Principio guida: Vera estrae e spiega, l'app calcola e impagina
- I modelli piccoli capiscono ed estraggono bene, ma sono poco affidabili nei calcoli e nell'impaginare documenti lunghi.
- Vera quindi **non scrive il prospetto intero**: legge i documenti ed estrae i dati in forma strutturata (importi, scadenze, rendimenti, costi, coperture).
- I **numeri li calcola l'app** con i motori di calcolo di Prisma, senza errori.
- I **report li impagina l'app** con modelli grafici fissi, coerenti con il tema iOS 5. Vera aggiunge solo i testi di commento.
- Ogni dato estratto viene **confermato dall'utente** prima di essere salvato, con il riferimento alla pagina del documento da cui viene.

## Il nucleo (fase a: chat testuale)
Codice in `Sources/Prisma/Vera/`: `FornitoreModello.swift`, `FornitoreOllama.swift`, `FornitoreCompatibileOpenAI.swift`, `NucleoVera.swift`, `MotoreLocale.swift`, `AvvioModello.swift`, `ConfrontoModelli.swift`.
- **Fornitore intercambiabile** (`FornitoreModello`): costruisce la richiesta in streaming e legge i pezzi della risposta. Due implementazioni: Ollama (`/api/chat`, `stream`, `think`, `tools`, `keep_alive`) e server compatibile OpenAI (`/v1/chat/completions` in SSE: MLX, llama.cpp, LM Studio). Per ora solo indirizzi del Mac (`IndirizzoLocale`). Il resto di Vera non sa quale fornitore c'è: un domani il cloud si aggiunge come terzo fornitore, con un'impostazione.
- **Modello**: `qwen3.5:4b` con Ollama (circa 3,5 GB di memoria mentre risponde, keep_alive 10 minuti). Si cambia in Impostazioni › Vera.
- **Due modalità**, scelte dalla domanda (`NucleoVera.modalita`): *lavoro* (domande sul cliente e sui temi di Prisma: scheda, bozze e calcoli di Prisma, temperatura 0,3, istruzioni `chat.md`) e *conversazione* (uso generale: ragionare, spiegare, scrivere, riassumere; temperatura 0,7, niente scheda, istruzioni `conversazione.md`). Una domanda breve di seguito resta nella modalità di prima.
- **Ragionamento** (`think`): per le domande difficili o se dici «pensaci bene»; in Impostazioni si può forzare (sempre/mai). Il ragionamento non entra mai nel testo mostrato.
- **Contesto a strati**: istruzioni fisse in testa (Ollama le tiene in cache), poi la storia della conversazione (fino a 40 battute, entro un budget di token della finestra da 8.192), poi l'ultimo messaggio con la riga di contesto (data, app aperte, cliente attivo), la scheda del cliente solo in lavoro, le cifre di Prisma e la domanda.
- **Streaming**: la risposta compare mentre arriva (`FlussoVera`, bolla in arrivo in `AppVera.swift`).
- **Pronta all'avvio** (solo Mac): se Ollama non risponde Prisma lo apre (`open -a Ollama`, altrimenti `ollama serve`) e precarica il modello.
- **Confronto tra modelli**: Impostazioni › Vera › «Confronta» oppure `Prisma --confronta-modelli qwen3.5:4b,qwen3:8b,gemma4:e4b`: stesse domande di prova (sui clienti fittizi) a ogni modello, uno alla volta, con risposte e tempi affiancati in una pagina HTML.
- **Comandi chiari** («fissa un incontro…», «apri l'agenda») restano una via rapida a regole (`ComandiVera.swift`), prima del modello.
- **Prove**: `--prova-vera` (`ProvaNucleoVera.swift`) collauda corpi delle richieste, lettura dello streaming dei due fornitori, modalità, contesto e storia, indirizzi non locali rifiutati, impostazioni di prima, con un server Ollama finto dentro il processo.
- Fasi successive (da aggiungere senza riscrivere il nucleo): documenti con ricerca locale, azioni con tool calling (`OpzioniModello.strumenti`, `PezzoModello.strumento`), voce, memoria persistente.

## Lettura dei documenti (strumenti nativi, nessuna dipendenza)
- PDF con testo: PDFKit.
- PDF scansionati e immagini: riconoscimento del testo di Vision, sul dispositivo.
- Documenti tipici: KID, set informativi e prospetti, polizze, estratti conto, proposte Alleanza e di altre compagnie.

## Strumenti che Vera può usare
Vera non calcola da sola: chiede all'app. Esempi:
- cercare un cliente e leggerne la scheda
- elencare le posizioni (in essere e non in essere) con il canale Alleanza / indipendente
- leggere scadenze e appuntamenti
- lanciare un calcolo dei motori di Prisma (proiezioni, gap previdenziale, gap di protezione, confronti) e commentarne il risultato

## Vera e i documenti di analisi
Gli spunti di Vera (check-up, resoconto, pensione, protezione, liquidità, obiettivi, restare o cambiare) usano gli stessi motori dei prospetti e dei report (`Sources/Prisma/Vera/AnalisiVera.swift`): le cifre in chat e sui documenti coincidono. Da Prospetti e report il pulsante «Chiedi a Vera» apre la spiegazione del documento aperto. A Qwen le cifre arrivano come bozza (spunti) o come calcoli pertinenti (domande libere riconosciute dalle parole chiave); se nella risposta cambia una cifra, restano le cifre di Prisma.

## Vera e i documenti del cliente
Da Documenti, «Chiedi a Vera» spiega un KID, una polizza o un estratto conto (`Sources/Prisma/Vera/DocumentiVera.swift`): i dati trovati con la pagina, il rischio e il periodo raccomandato letti con il profilo del cliente, i costi, cosa non torna con la posizione collegata, i dati ancora da confermare e quelli da verificare nelle condizioni. Lo spunto «Cosa dicono i documenti?» riassume tutti i documenti del cliente. Qwen rende la spiegazione discorsiva, sulle stesse cifre.

## Le proposte di Vera
Lo spunto «Cosa proporre al cliente?» (`Sources/Prisma/Vera/ProposteVera.swift`) ricava dalle analisi le azioni da fare, in ordine di urgenza: copertura caso morte, tutela per invalidità, riserva di emergenza, piano previdenziale (con il risparmio IRPEF), piani di accumulo per gli obiettivi, capitale da far lavorare, capitali in scadenza. Salta ciò che ha già una proposta aperta. Ogni azione diventa, con un tocco, un'attività o una bozza di proposta in Posizioni con area e cifre: prodotto e canale li sceglie il consulente.

## Gli scenari «E se…?»
«E se Marco va in pensione a 63 anni e smette di versare?», «cosa succede se Laura mette altri 20.000 € negli investimenti per 10 anni al 4%?» (`Sources/Prisma/Vera/ScenariVera.swift`, `Sources/Prisma/Motori/MotoreScenari.swift`, `Sources/Prisma/Shell/ScenariVeraShell.swift`).
- **Riconoscere**: l'app vede le parole d'apertura («e se», «cosa succede se», «ipotizziamo», «scenario») e almeno una cosa che cambia; gli spunti pronti restano spunti.
- **Estrarre**: Qwen risponde solo con il JSON dello schema `Schemi/scenario.json` (istruzioni `Istruzioni/scenari.md`, schema in «format» di Ollama, temperatura 0, senza ragionamento): cliente, area (previdenza, investimenti, risparmio, protezione), età di pensione, versamento al mese (nuovo valore, variazione o «smette»), capitale in più o in meno, rendimento, durata, campi mancanti. Le regole dell'app rileggono le cifre scritte nella frase: dove le trovano vincono. Se per Qwen non è uno scenario e le regole non trovano niente, la frase diventa una domanda come le altre.
- **Chiedere**: se manca un dato indispensabile (il cliente, l'area, cosa cambia, un'età plausibile) Vera fa una domanda breve; la frase dopo completa lo scenario, «lascia stare» lo chiude.
- **Calcolare**: i numeri li fa `MotoreScenari` con le ipotesi del cliente (Analisi 360 e posizioni) e gli stessi motori dei prospetti: previdenza con `MotorePrevidenza` (rendita dei piani, divario, risparmio IRPEF) e la pensione pubblica riproporzionata con la stima contributiva di `MotorePensionePubblica` (con l'avviso sui requisiti); investimenti e risparmio con `MotoreAnalisi`/`MotoreProiezione`; protezione con `MotoreProtezioneFamiglia`. Mai Qwen.
- **Raccontare**: sotto la risposta la scheda prima/dopo (voce, oggi, con lo scenario in viola); Qwen la racconta con le sole cifre di Prisma, e se ne cambia una resta il racconto di Prisma.
- **Salvare e aprire**: «Salva nel dossier» la mette tra gli scenari del cliente (Analisi 360 › Scenari; in protezione una nota del taccuino), «Apri in Simulazioni» apre il simulatore con i parametri (in protezione l'area di Analisi 360). La scheda resta nella conversazione del dossier.
- **Ovunque**: app Vera, Vera della scrivania, mini finestra (la tabella sotto la risposta breve), iPhone e iPad: al Mac, attraverso il ponte, vanno solo le richieste di testo per Qwen; la scheda la calcola il dispositivo con i suoi dati. Se Qwen non è pronto Vera lo dice e non risponde.
- **Prove**: `--prova-vera` (`ProvaScenariVera.swift`) con le frasi di `Esempi/scenari.json`, un Qwen finto che risponde con il JSON e i clienti di prova (Marco a 63 anni senza versamenti: rendita più bassa e divario più alto di oggi).

## Parlare con Vera
Vera ascolta e risponde a voce (`Sources/Prisma/Vera/VoceVera.swift`, `AscoltoVera.swift`, `Sources/Prisma/Shell/VoceShell.swift`).
- **Ascolto**: solo sul dispositivo, l'audio non esce mai dal Mac. In automatico Vera prova in ordine il riconoscimento nuovo di Apple (SpeechTranscriber), i modelli della dettatura di sistema (DictationTranscriber), la dettatura classica (SFSpeechRecognizer) e infine la dettatura di macOS nel suo campo; il riconoscimento ha una scadenza di preparazione, la frase si chiude al silenzio e il testo definitivo si aspetta prima di mandarla. Ascolto, microfono e permessi sono iniettabili (`--prova-vera` li collauda con finti). Impostazioni › Parlare con Vera: «Prova il microfono», «Prova il riconoscimento», «Mostra i passaggi dell'ascolto» e «Copia» della diagnostica (ambiente, permessi, impostazioni, passaggi con i secondi). Su macOS 26 e successivi il riconoscimento vocale nuovo di Apple (SpeechAnalyzer con SpeechTranscriber; la prima volta il Mac scarica l'italiano); altrimenti, o se quello non parte, la dettatura classica (`requiresOnDeviceRecognition`). Se Vera non riesce ad ascoltare o a capire lo scrive nella conversazione con cosa fare, e mentre ascolta l'onda segue il microfono.
- **Voce**: sintesi vocale di macOS, la migliore voce femminile italiana installata (le «Premium» e «Avanzate» sono le più naturali), scelta e velocità nelle impostazioni. Non si imita la voce di una persona o di un personaggio reale: si sceglie tra le voci di sistema.
- **Conversazione**: pulsante del microfono o ⌥⌘E. La frase finisce da sola dopo una breve pausa e segue la stessa strada delle domande scritte. La risposta resta scritta; a voce Vera ne dice l'inizio (o tutta, se si sceglie). A conversazione continua, finita la risposta Vera torna ad ascoltare finché non le si dice «basta così».
- Permessi: microfono e riconoscimento vocale (testi in `Info.plist`).

## Vera fa le cose
Quando le chiedi qualcosa da fare, a voce o per scritto, Vera lo fa e te lo conferma («Va bene, te lo preparo»). I comandi li riconosce l'app con regole sulle parole (`Sources/Prisma/Vera/ComandiVera.swift`, giorni e orari in `DateItaliane.swift`), così funzionano con ogni motore e anche senza modello; li esegue `Sources/Prisma/Shell/ComandiShell.swift`.
- **Documenti**: «preparami il report della prova di resistenza di Marco», «fammi il prospetto dei costi», «il fascicolo per l'incontro con Laura» (con il prossimo appuntamento del cliente, i report adatti già scelti). «Prospetto» = per te, altrimenti il report per il cliente.
- **Appuntamenti**: «fissa un incontro con Giulia giovedì alle 15», «una telefonata con Laura domani alle tre e mezza». Se manca il giorno o l'ora Vera lo chiede e la frase dopo completa l'appuntamento; avvisa se a quell'ora c'è già un impegno.
- **Promemoria**: «ricordami di chiamare Laura venerdì» → un'attività del cliente.
- **Note**: «prendi nota che Marco vuole cambiare casa nel 2028» → una nota nel taccuino del cliente.
- **Agenda**: «cosa ho domani?».
- **Aprire**: «apri l'agenda», «vai alle posizioni», «passa a Sofia», «apri Marco Bianchi».
Quello che Vera crea si apre o si annulla dalla risposta. Le domande («quanto pesano i costi?») restano domande. In modalità cliente Vera non esce dal dossier del cliente davanti a te. Il solo cognome vale come cliente dopo «con», «per», «di»… («i conti correnti» non è Andrea Conti).

## Contenuto della cartella
- `Istruzioni/` — istruzioni di sistema e prompt per ogni compito (chat, estrazione, commento ai report).
- `Schemi/` — schemi dei dati da estrarre (es. polizza, KID, estratto conto, proposta); `scenario.json` è lo schema degli scenari «E se…?».
- `Esempi/` — esempi per verticalizzare Vera, con documenti anonimizzati: mai dati veri di clienti; `scenari.json` sono le frasi di prova degli scenari, sui clienti di prova.
- `Valutazione/` — casi di prova con il risultato atteso, per misurare la qualità dell'estrazione e confrontare i motori.

## Build
- Il framework FoundationModels si compila solo con l'SDK di macOS 26.
- Verificato il 21/10/2026: il runner `macos-15-intel` ha installati anche Xcode 26.0–26.3 (il predefinito è 16.4). Quando si arriva a Vera basta selezionare Xcode 26.3 nel workflow con `DEVELOPER_DIR`, senza cambiare runner. Riguarda solo il server di build, non il Mac dell'utente.
- Il codice che usa FoundationModels va protetto con `#if canImport(FoundationModels)` e `@available(macOS 26, *)`, così l'app resta compatibile con macOS 13.

## Il copilota dell'incontro
Mentre il consulente parla con il cliente, Prisma riconosce obiettivi, polizze di altre compagnie, timori sul rischio, eventi della vita e attività (`Sources/Prisma/Motori/RiconoscitoreCopilota.swift`, `ApplicaCopilota.swift`, `Sources/Prisma/Shell/StatoCopilota.swift`).
- **Consenso**: senza il consenso del cliente all'ascolto, registrato nel dossier (data, a voce o per iscritto, nota), il copilota non parte (`GuardiaCopilota`).
- **Solo testo**: il riconoscimento della voce è sul dispositivo, l'audio non si salva e non esce mai. La trascrizione si scrive nell'archivio solo con «Conserva la trascrizione»; altrimenti resta il verbale.
- **Due livelli**: le regole di Prisma (parole, cifre, anni, anche in lettere) funzionano sempre; Qwen, se è pronto, legge il pezzo con `Istruzioni/copilota.md` e lo schema `Schemi/copilota.json`. Una scheda di Qwen con una cifra che non è nella frase si scarta.
- **Conferma**: ogni scheda propone un'azione (aggiorna l'obiettivo, aggiungi a Posizioni, annota nel profilo, aggiungi alla linea della vita, crea l'attività) e si applica solo con la conferma, una o tutte insieme. Il profilo del questionario non cambia mai.
- **iPad**: le schede riconosciute sull'iPad arrivano al Mac sul ponte cifrato (`prisma/copilota`), come proposte.
- **Prove**: `--prova-vera` (`ProvaCopilota.swift`) con le conversazioni inventate di `Esempi/copilota.json`, un Qwen finto con il JSON dello schema e il ponte vero su 127.0.0.1.
