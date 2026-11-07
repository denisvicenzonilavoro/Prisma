# Acqua viva · diario dei giri

Note interne per il riepilogo finale: esiti dei controlli d'insieme e scelte non coperte dal template.

## Giro 2
**Controllo d'insieme del Giro 2: nessun conflitto tra le cinque parti e nessuna correzione necessaria.** Qui non c'è il compilatore, quindi niente è compilato: il primo vero controllo resta la build su GitHub Actions. Nessun commit. Le uniche modifiche non salvate nell'albero sono le correzioni dei revisori, sopra il commit `9ce6f86`.

## Esito dei controlli
- **File condivisi tra le parti.** Le modifiche si sommano senza sovrapporsi.
  - `StatoShell.swift`: `eventiShell` e `ricalcolaNotifiche`, che chiama `annunciaNotificheNuove` (esiste in `EventiShell.swift`).
  - `Istantanee.swift`: solo le scene 410–415 e `propostaFermaGiulia`. Tutti i simboli che usa esistono: `ValoriDaDocumento.mezzogiorno`, `SeguitoProposta()`, `.presentata`, l'id del PIP di Giulia.
  - Impostazioni: solo la parte acqua tocca `DatiPrisma.swift`, `AppImpostazioni.swift` e `DerivatiDati.swift`.
  - `ShellView` e `StatoShellFinestre`: blocco e volo delle finestre non si toccano.
  - `allaSblocco()` è chiamato solo da `sblocca`. L'acqua risponde allo sblocco solo attraverso `OsservatoreAcqua`, quindi niente gocce doppie.
- **Graffe e parentesi.** Con un controllo automatico che salta stringhe, interpolazioni e commenti, tutti i 46 file toccati sono bilanciati.
- **Nomi duplicati.**
  - I tipi nuovi che hanno un omonimo sono tutti annidati (`Tema.Apple.Scrivania.Moto/Ruby/Agenda/Portafoglio`, `MossaDelGiorno.Tipo`, `FisicaAcqua.Vibrazione`). Dentro `Tema.Apple.Scrivania` i riferimenti a `Tema.Apple.Moto` sono scritti per intero, quindi `Scrivania.Moto` non li nasconde.
  - Le funzioni nuove delle estensioni non hanno doppioni nello stesso tipo.
  - Nessuna dichiarazione tolta è ancora usata altrove.
- **Compilazione iOS e macOS 13.**
  - Tutto ciò che è solo AppKit nei file toccati sta dentro `#if os(macOS)`.
  - Nessun `onChange` a due parametri, nessuna API di macOS 14 o successivi.
  - Il ramo iOS di `chiudi` (`let volo = false`) dà solo avvisi, non errori.
- **Scene.** I 241 nomi sono unici. La 415 finisce in `-schermo-basso`, quindi si disegna a 1280×760.
- **ProvaFluidita.**
  - Usa `StatoShell(persistente: false)`: chiusura e riduzione restano immediate, `aperta` e `appAttiva` si verificano come prima, e il percorso del volo (0,48 s) non entra nella misura.
  - Nessuna animazione nuova gira in continuo a riposo: niente `repeatForever`, solo `TimelineView(.everyMinute)`.
  - La luce del pulsante di blocco (30 fps) gira solo con Prisma bloccata e si ferma con `prismaStatoFinale`. Il benvenuto di prima aveva già lo stesso luccichio, quindi non è un peggioramento.
  - Il volo delle finestre e l'ingrandimento del dock si muovono solo durante l'azione. Il registro delle icone del dock non è pubblicato e cambia solo se le cornici cambiano.
  - Nessun nuovo ciclo di riferimenti su `StatoShell`: `[weak self]` nelle chiusure rimandate, e gli `EventiShell` non tengono chiusure.
- **Archivio e `--prova-backup`.** Sono coerenti.
  - `acquaDellaScrivania` è letta con tolleranza (`?? true`) e compare nelle `CodingKeys`. La versione dell'archivio non cambia.
  - La prova controlla tre casi: il valore spento torna spento dal backup, l'archivio della versione 1 si apre con l'acqua accesa, e un archivio di oggi senza la chiave si apre uguale con l'acqua accesa.
  - In `stessiCalcoli` il campo è copiato, quindi non fa ricalcolare niente.

## Note rimaste aperte
- **«Riduci movimento» scelto dentro Prisma.** In Prisma oggi non c'è ancora un interruttore per «Riduci movimento» (nessun `.prismaCalmo(_:)` è applicato). `\.prismaCalmo` e `Movimenti.calmo` seguono quindi entrambi solo l'impostazione del sistema, e i due punti segnalati dai revisori (barra e uscita del blocco) per ora si comportano uguale.
- **Finestra minima di 720.** Le righe della scrivania sforano di circa 16 punti nel margine sopra il dock. Va guardato in uno screenshot.
- **Doppia chiusura veloce.** Se si chiude, si riapre e si richiude la stessa app entro 0,48 s, il secondo volo si interrompe. È un taglio d'animazione, non un crash.

## Scelte grafiche non coperte dal template
1. **L'acqua che risponde**: una goccia al clic sul fondo libero, una alla notifica nuova sulla campanella, una grande allo sblocco, e l'acqua vibra intorno alla sfera di Ruby mentre risponde. Si spegne con l'interruttore nuovo «L'acqua della scrivania» in Impostazioni › Aspetto. Usa lo shader e la fisica di oggi, non il modello d'onda del template.
2. **Scrivania in proporzione**: margine al 3% della larghezza (fra 16 e 44), larghezza massima 1600, righe divise secondo lo spazio che c'è, con minimi di 200 e 104 al posto del palco fisso 1440×900.
3. **Testi che si riducono**: saluto fino al 70%, titolo della mossa fino all'80%, totale del portafoglio e giorno dell'agenda fino al 60%.
4. **Schermi bassi**: gli anelli del portafoglio si stringono da 118 a 48 con lo spessore in proporzione, la frase di Ruby cede righe (al massimo 4), e Da fare e In scadenza mostrano sempre almeno una riga.
5. **Mossa del giorno**: etichetta del canale accanto a «La mossa del giorno» e, sotto gli anelli, i canali con pallino e quota. Nel caso calmo («niente di urgente») la sfera mostra una spunta al posto delle iniziali.
6. **Finestre senza icona nel dock**: compaiono al loro posto da una scala di 0,94. Durante il volo il dock resta in vista anche quando è nascosto.
7. **Pallino delle app aperte nel dock**: compare e scompare in 0,3 s.
8. **Pannello notifiche**: il numero «N nuove» è quello del momento in cui il pannello si apre.
9. **Schermata di blocco**:
   - si entra anche trascinando: la schermata segue il gesto al 35% ed entra oltre una soglia o con un colpo rapido;
   - il pulsante non ha sfocatura propria: si sfoca la schermata intera solo durante l'uscita.
## Giro 3
## Esito del controllo d'insieme del Giro 3

Non ho trovato errori di compilazione per macOS 13 né per iOS 17, e le quattro parti non vanno in conflitto fra loro. Ho fatto una sola correzione piccola: cinque spaziature scritte a numero che non stavano nel tema. Qui non c'è Swift, quindi la prova vera resta la build di GitHub Actions, con `--prova-calcoli`, `--prova-backup` e le istantanee 420–436. Non ho fatto commit.

Mentre lavoravo è comparso nel branch il commit `ec2a8cf` («salvataggio intermedio [skip ci]»), che non è mio e contiene tutto il lavoro delle quattro parti. Ho quindi confrontato il Giro 3 intero con il Giro 2 (`222305a..HEAD`). Le mie correzioni sono le uniche modifiche non salvate.

**Cosa ho controllato**
- **File condivisi:**
  - `StatoShell.swift`: il caso `.nelTempo` di `SchedaCliente` è coperto in `titolo` e nell'unico `switch` di AppClienti.
  - `Istantanee.swift`: la riga `scene + … + scenePosizioniApple + sceneDossierApple` tiene insieme le scene di tutte e due le parti.
  - `AppClienti.swift`: `conDettaglio` e `dossierERubrica` stanno con il `#if` giusto. Su iPad il vetro è fuori dal presentatore, e `PresentatoreDettaglioDossier` non è chiuso in un `#if`, quindi esiste anche su iOS.
  - `DerivatiDati.swift`: le cache nuove (`nastroDaFare`, `andamentoPortafoglio`, `andamentiCliente`) si azzerano in `invalida`.
- **Nomi doppi:** nessuno nel modulo. Le omonimie che si vedono (`Tono`, `Colore`, `Carattere`, `DettaglioObiettivo` dentro `Tema.Apple.Clienti`) sono tipi annidati o `typealias` in spazi diversi. `RichiestaIstantaneaNelTempo` e `RichiestaIstantaneaDossier` sono due classi distinte.
- **Graffe e direttive:** graffe, parentesi tonde e quadre sono bilanciate, e così `#if` ed `#endif`, in tutti i file del giro. Non ci sono resti di conflitti di unione.
- **Compilazione iOS:**
  - AppKit (`NSMenu`, `NSEvent`) compare solo in `DossierApple.swift`, dentro `#if os(macOS)`.
  - Nessuna API più recenti di macOS 13 e iOS 17: niente `scrollTargetBehavior`, `onChange` a due parametri, `phaseAnimator`, `numericText` e simili.
  - Nessun Timer, `TimelineView`, sfocatura o `Material` nuovi.
- **Nomi delle scene:** tutti unici, dalla 420 alla 422 e dalla 430 alla 436.
- **ProvaFluidita:** non cambia, perché non scorre `SchedaCliente`. I calcoli pesanti stanno in cache: `CacheNelTempo`, `CacheFamigliaDossier` e la cache del dettaglio dell'obiettivo.
- **Archivio e `--prova-backup`:** sono coerenti.
  - Il campo nuovo `versamentoMensile` si legge con `decodeIfPresent` e vale 0 negli archivi di prima.
  - `ProvaBackup` controlla i 350 € che tornano dal backup e un obiettivo vecchio senza il campo.
  - `EsitoObiettivo` si costruisce in un punto solo; `LineaMonteCarlo` e `ParametriProiezione` sono usati con le firme che esistono.
- **Prove:** `ProvaAndamentoPortafoglio` e `ProvaDaFare` partono una volta sola, e le prove nuove del punto 24 usano firme che esistono.

**Cosa ho corretto (solo spaziature, in token nuovi)**
- `Tema.Apple.Clienti.Rubrica`: `spazioTitolo` (4) e `fraRighePiede` (2).
- `Tema.Apple.Clienti.Testata`: `spazioRighe` (1).
- `Tema.Apple.Posizioni.Scheda`: `spazioNomePatrimonio` (1).
- `Tema.Apple.SuperficiAnalisi`: `spazioNota` (5).

Li usano `Shell/DossierApple.swift`, `Shell/PortafoglioApple.swift` e `DesignSystem/ComponentiAnalisi.swift`. Ho controllato con grep che nessuno dei nomi esistesse già nel suo spazio.

**Cose lasciate com'erano, da sapere**
- La scena `436-clienti-famiglia-apple` è identica a `6-clienti-famiglia`: si può togliere.
- Le frecce del nastro con `ScrollViewReader` potrebbero spostare un po' la pagina in verticale: va guardato sul Mac.
- «Proposte concluse» non è filtrato sull'anno.
- La ricerca porta alla scheda Obiettivi ma non apre più il dettaglio dell'obiettivo.
- Nell'istantanea 434, «Oggi» prende il netto da `MotorePatrimonio` e le righe per canale dal riepilogo delle posizioni: se due cifre non tornano, il motivo è questo.

## Scelte grafiche non coperte dal template

1. **Rubrica:** filtro «Tutti · ★ Preferiti» sotto la ricerca, stella dei preferiti nel color cuoio (in rubrica e in testata), piede «+ 30 clienti di prova».
2. **Dossier:** menu «Altro ▾» con le schede che il template non ha (Bisogni, Documenti, In regola, Riesami, Anagrafica, Profilo, Note). Su iPad stretto i comandi della testata scendono sotto il nome.
3. **Portafoglio:**
   - prima riga alta 310 invece di 296, perché il totale a 62 pt non sia coperto dal grafico;
   - lo stato del lavoro ha una larghezza minima e gli anelli scendono fino a 120;
   - sotto il nastro restano i pannelli di Prisma (`PannelloAnalisi` e `KPI` nello stile Apple, con `.superficiApple()`);
   - un colore per ogni cliente (avatar e grafico del dettaglio), dai toni dell'Agenda.
4. **Panoramica:**
   - la croce «non pertinente» accanto a «Completa», con «Mostra tutte» e «Ripristina» nel piede;
   - sotto la griglia restano riesame, In regola e «Il dossier collegato»;
   - sotto una certa larghezza le due colonne vanno una sotto l'altra.
5. **Obiettivi:**
   - colori delle aree che il template non ha, presi da Analisi 360;
   - il posto libero compare solo sotto una soglia di obiettivi, poi c'è «Nuovo obiettivo»;
   - sotto la griglia, gli obiettivi del profilo e i suggerimenti dagli eventi di vita;
   - nel dettaglio, «Il dettaglio completo» (probabilità, traiettoria, posizioni collegate, azioni) e «Salva nel dossier» con la nota sul rendimento.
6. **Nel tempo:**
   - il cursore del momento con la sua riga verticale e il punto;
   - una colonna del momento da 300 accanto al grafico, che sotto 760 va sotto;
   - righe del riesame (canali, debiti, proposte, posizioni di allora) con note accorciate;
   - senza proposte la stima è tratteggiata nel blu del passato;
   - il grafico ha un'altezza minima e poi riempie la card.
7. **Famiglia:**
   - la freccia «›» nelle capsule delle scoperture porta alla scheda dove si risolve;
   - la card «Aggiungi un familiare» è tratteggiata, come il posto libero degli obiettivi;
   - una spiegazione sotto la griglia dice da dove vengono le capsule;
   - la griglia ha al massimo 4 colonne, poi va a capo.
8. **iPad:** su iPad le schede Clienti e Posizioni restano nella finestra di vetro di Prisma, con il dettaglio fuori dalla sfocatura del vetro.

File toccati in questo controllo:
- `/home/user/Prisma/Sources/Prisma/DesignSystem/Apple/Tema.Apple+Clienti.swift`
- `/home/user/Prisma/Sources/Prisma/DesignSystem/Apple/Tema.Apple+Posizioni.swift`
- `/home/user/Prisma/Sources/Prisma/DesignSystem/Apple/SuperficiApple.swift`
- `/home/user/Prisma/Sources/Prisma/DesignSystem/ComponentiAnalisi.swift`
- `/home/user/Prisma/Sources/Prisma/Shell/DossierApple.swift`
- `/home/user/Prisma/Sources/Prisma/Shell/PortafoglioApple.swift`
## Giro 4
Ho fatto il controllo d'insieme del Giro 4 e ho corretto quattro punti con modifiche piccole, in tre file. Non ho fatto commit e qui non posso compilare: la prova vera resta la build su GitHub Actions dopo il push.

Mentre lavoravo un altro processo ha salvato le parti agenda e analisi in un commit intermedio (`81dda47`). Le mie modifiche sono solo quelle elencate qui sotto e non sono ancora in un commit.

**Correzioni**
1. `/home/user/Prisma/Sources/Prisma/Shell/AppAnalisi360.swift`: i quattro pannelli delle aree, già approvati, non erano ancora passati al nuovo stile. Nessuna delle quattro parti li aveva toccati. Ho aggiunto `.superficiApple()` alla vista dell'area, come in `AppPosizioni`: card piatte, caratteri del tema ed etichetta del canale `.chA` / `.chI`. Contenuti e cifre non cambiano.
2. `/home/user/Prisma/Sources/Prisma/DesignSystem/Apple/Tema.Apple+Aree360.swift`: ho tolto `Dettaglio.misuraPrevidenzaProtezione`. Era un doppione che nessuno usava: la misura dei simulatori sta già in `Tema.Apple.SimulatoriAnalisi.misura`.
3. `/home/user/Prisma/Sources/Prisma/Istantanee.swift`, scene `11-agenda`, `130-agenda-occasioni` e `130-agenda-occasioni-scuro`: chiedevano la vista Settimana con un appuntamento o un'occasione scelti. Nel nuovo stile la settimana non ha più la colonna del dettaglio, quindi quel dettaglio (approvato) non si sarebbe visto. Ora le tre scene usano la vista Giorno, che mostra il dettaglio di sempre. La traccia dell'impegno resta nella scena 452.

**Controllato, senza bisogno di correzioni**
- **File condivisi tra le parti:** in `AppAnalisi360.swift` la griglia nuova prende il posto della panoramica e non restano riferimenti ai pezzi tolti. In `Istantanee.swift` c'è una sola riga di ciclo, che contiene già le scene Simulatori, Aree e Agenda. `StatoShell.swift` non è stato toccato da nessuna parte.
- **Firme dei simulatori:** quelle chiamate dalla griglia delle aree coincidono con quelle dichiarate. Vale per `SimulatoriAnalisiApple` (`idPrevidenza`, `idProtezione`, `misura`, `area(id:)`, `dettaglioIniziale(_:)`), per `DettaglioSimulatoreAnalisiApple(id:)` e per `StatoDettaglio()` / `init(aperto:misura:)`.
- **Segnaposto e nomi:** non ci sono segnaposto doppi né provvisori, a parte quello del punto 2. Nessun nome nuovo è già dichiarato nel modulo: tipi, membri di `Tema.Apple` ed estensioni di `Istantanee`. `Tema.Apple.Agenda` non copre altri `Agenda`.
- **Graffe e parentesi:** sono bilanciate in tutti i 34 file toccati, controllati con uno script che salta stringhe e commenti.
- **iOS / iPad:** nessuna API AppKit fuori da `#if os(macOS)`. Sono usati solo `.help`, `.onHover`, `TimelineView(.everyMinute)` e `ViewThatFits`, tutti disponibili su macOS 13 e iOS 17. Niente `onChange` a due parametri. `StatoShell.apri(_:da:)` esiste su tutte e due le piattaforme. Le classi `RichiestaIstantanea*` compilano anche su iOS; le scene sono solo per il Mac.
- **Scene:** i nomi sono unici (440, 441, 442, 443, 444, 450, 451, 452, con le varianti «-scuro»), e l'evento `event-giulia` esiste nei dati di prova.
- **ProvaFluidita:** l'Agenda si apre ancora sul Mese. Ci sono solo una card senza sfocatura e il presentatore del dettaglio, nessuna sfocatura dentro un'altra. Niente Timer. Analisi 360 non fa parte degli scenari della prova.
- **Prove:** `ProvaCalcoliSimulatoriAnalisi` e `ProvaCalcoliAree360` sono registrate. Il calcolo `MotoreAnalisi.previdenza` ora passa dagli aiuti `parametriPrevidenza` e `mesiDiIntegrazione`, ma dà gli stessi valori di prima. L'archivio non è toccato, quindi `--prova-backup` resta com'è.

**Scelte grafiche che il template non copre** (da far confermare all'utente)
1. **Strumenti in Analisi 360:** una riga «Strumenti» sotto la griglia (Simulatore, Scenari, Confronto, TFR) invece di una quinta card. La specifica §4.3.1 lascia la scelta all'utente.
2. **Card delle aree:** in più del template hanno la stella «★ Priorità» dalla ruota dei bisogni, la riga sulla completezza dei dati e lo stato «Dati confermati / Ipotesi da verificare».
3. **Canale negli Investimenti:** il canale si vede nelle quattro tile, con gli euro di ciascun canale nel suo colore. Non c'è una sottobarra nella barra di composizione (la specifica §4.3.4 lascia aperte le due strade).
4. **Proposte:** nel piede dei dettagli c'è la scelta del canale per «Salva come proposta». In Protezione c'è anche «Chiedi a Ruby di spiegarlo».
5. **«Apri l'analisi completa»:** dai dettagli porta ai pannelli di sempre.
6. **Pannelli delle quattro aree nel nuovo stile:** passano al tema Apple come in Posizioni (mia correzione 1).
7. **Strumenti:** Simulatore, Scenari, Confronto e TFR non sono nel template. Ora hanno la console con `CursoreApple`, le schede a pillola, la spia verde nella testata e le tabelle su tile e card piatte. Lo stesso stile vale anche su iPhone e iPad.
8. **Agenda:** il template ha solo la settimana con la barra laterale. In Prisma restano il Mese come vista predefinita (approvato), il Giorno con la colonna del dettaglio di sempre e le Occasioni, ora dentro card piatte. In testa c'è una barra con frecce, «Oggi», il periodo, il riepilogo delle cose da fare, le viste a pillola, i clienti, «Attività» e «Nuovo impegno». La striscia dei riesami del mese resta.
9. **Fascia «Da fare e da ricordare»:** sopra le ore della giornata, con attività, scadenze e occasioni. La specifica la suggerisce soltanto, senza disegnarla.
10. **Traccia dell'impegno:** ha il collegamento «Tutti i dettagli», che porta alla vista Giorno. Le istantanee mostrano la linea dell'ora ferma alle 10:24.

Dopo il push vanno guardate le scene 11, 130 e 130-scuro (ora in vista Giorno), e la 99, la 18, la 300 e la 301 (pannelli delle aree nel nuovo stile).

File modificati:
- /home/user/Prisma/Sources/Prisma/Shell/AppAnalisi360.swift
- /home/user/Prisma/Sources/Prisma/DesignSystem/Apple/Tema.Apple+Aree360.swift
- /home/user/Prisma/Sources/Prisma/Istantanee.swift
## Giro 5
Ho fatto il controllo d'insieme del Giro 5. Ho trovato **nessun errore di compilazione e nessun conflitto tra le parti**, e ho fatto **una sola modifica**: tolto tre istantanee doppie. Senza compilatore qui, la conferma vera arriva solo dalla build su GitHub Actions. Nessun commit.

## Modifica
`/home/user/Prisma/Sources/Prisma/Shell/IstantaneeAnnoInsieme.swift`: ho tolto `462-un-anno-insieme-prospetto`, `462-un-anno-insieme-prospetto-scuro` e `462-un-anno-insieme-pdf`. Mostravano esattamente quello che mostrano già `460-prospetti-apple` (chiara e scura) e `461-prospetti-sala` (Giulia con «Un anno insieme», poi la sala). Resta solo `462-un-anno-insieme-pdf-anno`, che parte già ferma sulla seconda pagina con `presenta(d, daPagina: 1)`. Ho aggiornato il commento. Nessun altro file e nessun workflow cita i nomi tolti. Il giro delle istantanee si accorcia di tre scene.

## Verificato, senza problemi
- **File toccati da più parti:**
  - `AppProspetti` ha voce, `scegli`, intestazione e `contenutoScelta` con `.annoInsieme`. Sul Mac c'è `corpoProspettiApple`, su iOS la cornice di prima. Le modifiche della parte «prospetti» e di «anno-insieme» non si pestano.
  - `Prospetto.swift` dichiara il caso una volta sola in entrambi gli enum.
  - `Istantanee.swift` unisce le 11 liste una alla volta, tutte esistenti e dello stesso tipo, tutte dentro `#if os(macOS)`.
  - `DatiPrisma`, Impostazioni e `ShellView` sono coerenti tra loro.
- **Switch:** tutti quelli su `TipoProspetto` e `SceltaProspetto` hanno `.annoInsieme` o `default`. Ho controllato con uno script tutto `Sources`: i `.riesame` rimasti senza il caso nuovo sono di altri enum (MossaDelGiorno, FiltriRicerca, VoceDaFare).
- **Nomi:** nessun tipo dichiarato due volte a livello di modulo. I doppioni che compaiono o sono `private` al file (`K`, `F`, `M`, `R`, `SSP`…) o c'erano già prima, divisi per piattaforma (`ColorePiattaforma`, `ScorrimentoEditor`). Gli enum annidati nuovi (`Impostazioni`, `AltreApp`, `Prospetti`, `CartaAnno`, `Laterale`, `Disposizione`) stanno in tipi diversi.
- **Graffe, parentesi e `#if`:** bilanciati in tutti i file cambiati e nuovi (controllo con script).
- **iOS:** il codice solo Mac è dentro `#if os(macOS)` (`ImpostazioniAppleMac`, `ProspettiApple` da riga 120, istantanee, `NSOpenPanel`). Non c'è nessun `onChange` a due parametri. `onHover` e `.help` esistono su iOS 17.
- **Firme:** esistono tutti i simboli che ho cercato, tra cui:
  - `prismaCalmo(_:)`, `prismaScalaTesto(_:)`, `Movimenti.sceltaCalmo`, `Tipo.fattore`;
  - `Tema.Apple.Moto.Sala.scalaApertura` (in `PaginaApple.swift`), `GiroPagina.entrata`;
  - `presenta(_:delCliente:daPagina:)`, `testiAnnoInsieme(_:oggi:)`, `DocumentoStampabile(_ t: TestiAnnoInsieme)`;
  - `SegmentatoPillola(selezione:voci:)`, `.appleSenzaEtichetta`, `NumeroCheConta(_:formato:)`, `superficieApple(_:raggio:)`, `fontLeggibile`.
- **`TemaDossierCliente.swift`:** è tornato normale (15 KB, una sola `TesseraFiltroDocumenti`).
- **Istantanee:** i nomi delle scene 450-471 sono unici; quelle che finiscono in `-scuro` vengono scattate in scuro.
- **ProvaFluidita:**
  - non ho trovato nuovi `.blur`, `.compositingGroup`, `.drawingGroup` o `Material`;
  - `superficieApple` sfoca solo se `sfocatura > 0` e mai nelle istantanee;
  - le opacità della sala valgono solo durante apertura e cambio pagina, come la vecchia `.transition(.opacity)`;
  - `riduciMovimento` non fa più ricalcolare i motori (`stessiCalcoli`).
- **Archivio e `--prova-backup`:** `riduciMovimento` è nelle chiavi di lettura e scrittura e viene letto con tolleranza, senza alzare la versione. La prova lo controlla in tre modi: torna uguale dal backup, è spento negli archivi della versione 1, manca negli archivi salvati prima del campo. `senzaCampo` esiste già. `TipoProspetto` non si salva da nessuna parte.
- **Prove:** `ProvaAnnoInsieme` è chiamata da `ProvaProspetti`. I nuovi controlli di `ProvaRuby` sulla presentazione sono coerenti con `presenta` e `paginaPrecedente`. Nessuna prova dipende dal numero dei `TipoProspetto` o dai fattori 1,12 e 1,25.

## Scelte grafiche non coperte dal template
1. **Prospetti, barra laterale:** le scelte del documento (prospetto o report, voci, posizioni, commento) stanno sotto la voce scelta. Usano `StileScelteProspetto` e `StileAzioneSceltaProspetto`, ricavati dal tema; il template non le ha.
2. **Prospetti, anteprima:**
   - frecce e «2 di 5» sotto la carta, con la freccia spenta più trasparente;
   - si cambia pagina scorrendo (60 pt di trackpad o un giro di rotella per pagina, poi 0,35 s di pausa);
   - lo stato vuoto è una riga `.k` centrata;
   - la carta non supera la misura vera.
3. **Sala della presentazione:** il titolo del documento è in alto a sinistra, discreto. Ci sono il pulsante «Annota» (capsula come le frecce), la riga dell'annotazione su bianco al 12% e i tasti Spazio/Invio per andare avanti, come in Keynote.
4. **Carta in schermo:** anteprima, sala e colonna dei fogli restano a scala 1 con «Dimensione del testo» (`.prismaScalaTesto(1)`).
5. **«Un anno insieme», pagine interne:** il template disegna solo la prima. Sono di Prisma:
   - le pagine interne: Cosa è successo, obiettivi, protezione, mercati, cosa ci aspetta;
   - le misure ridotte, la colonna destra e lo spazio per il piede di avvertenze in 9 pt;
   - la barra «al 1° gennaio» in `#B1D8FF` pieno invece del blu al 32%;
   - l'intestazione del canale spaziata 0,8 invece di 1.
6. **Impostazioni:** l'organizzazione della barra laterale in tre gruppi (principali, lavoro, prove) con le 12 sezioni di Prisma; la cascata delle righe; le voci delle sezioni del template restilizzate; la card Profilo con l'avatar e le etichette dei canali.
7. **Dimensione del testo:** fattori 1,0 / 1,12 / 1,25, validi anche per i caratteri di sempre (cambiano riaprendo Prisma). Mini Ruby resta a scala 1.
8. **Altre app** (Incontri, Prodotti, Note, Ricerca, Documenti, Attività), restilizzate con i token Apple secondo §5.1:
   - card piatte senza ombra, inclinazione 3° per le schede grandi e 5° per le altre;
   - voce scelta e passaggio del puntatore;
   - fondo verde chiaro al 14% per i passi fatti;
   - spunta delle attività come cerchio vuoto con la spunta verde disegnata;
   - tessere filtro dei documenti con il numero che conta;
   - barra di stato con la spia verde;
   - menu a tendina come capsula secondaria.
9. **Ricerca ⌘K:** il pannello è di vetro con raggio 22, nel vetro della finestra, più coprente. Larghezza, distanza dall'alto e colonna dell'anteprima restano quelle di Prisma, perché il template non ha l'anteprima.
10. **Documenti:** la barra delle pagine galleggia sopra il foglio. Il banner d'errore è rosso con la stessa alfa del verde (il nome `alfaFondoVerde` non è adatto, il risultato sì).

Restano tre piccole pulizie, che non bloccano la build: `StileCuoioNote.evidenziato` e `Colori.Spotlight.fondo` non sono più usati, e `alfaFondoVerde` va rinominato.
## Giro 6
Ho fatto il controllo d'insieme sulle due parti del Giro 6 rispetto a 8abc375 (git status, git diff, i file già entrati in 91c6ae3 e il nuovo `IstantaneeScenariRuby.swift`). Non ho trovato conflitti né errori di compilazione evidenti e ho fatto una sola correzione piccola. Niente è stato compilato, perché qui manca Swift: la conferma arriverà dalla build, da `--prova-ruby` e dalle istantanee. Non ho fatto commit.

**Correzione**
- In `/home/user/Prisma/Sources/Prisma/Shell/StatoShell.swift`, quando cambia il cliente attivo ora si cancella anche lo scenario rimasto a metà (`scenarioInSospeso = nil`, nello stesso punto dove già si azzera `fascicoloAppuntamento`). Lo scenario in sospeso è uno solo per tutta l'app: prima, se cambiavi cliente con Ruby in attesa di un dato, una domanda breve (8 parole o meno) sull'altro cliente veniva presa come risposta allo scenario vecchio. Le prove di `ProvaScenariRuby` non cambiano cliente a metà di uno scenario, quindi restano valide.

**Controllato, senza bisogno di correzioni**
- **Conflitti tra le parti:**
  - **AppRuby:** `NuvolaRuby` mostra sia la scheda dei calcoli sia la scheda dello scenario; `quadroRuby` non disegna un secondo quadro sotto uno scenario. La Ruby della scrivania e l'iPhone usano la stessa `NuvolaRuby`.
  - **Istantanee:** in `Istantanee.swift` ci sono sia le scene di Ruby sia quelle degli scenari.
  - **ProvaRuby:** chiama `ProvaScenariRuby` fuori dalla parte solo Mac.
  - **Modalità:** la scelta «Lavoro / Conversazione» della testata vale solo per le domande libere, non per gli spunti né per gli scenari.
- **Nomi duplicati:** nessuno, né tra i tipi nuovi né tra le funzioni aggiunte a `StatoShell`. I nomi ripetuti (`Sfera`, `Puntini`, `Testata`, `Colonna`) sono annidati in tipi diversi.
- **Graffe e parentesi:** bilanciate in tutti i file Swift toccati. Ho controllato con uno script che tiene conto delle stringhe e delle interpolazioni.
- **iOS:**
  - `AppRuby.swift` e `StatoShell.swift` hanno `#if os(macOS)` solo attorno agli import, quindi compilano anche su iPhone e iPad.
  - Mini Ruby, `AppKit` e istantanee restano solo sul Mac.
  - `RubyTelefono` usa la sfera con la firma nuova, e `SchedaScenarioRubyVista` trova `StatoShell` tra gli oggetti dell'ambiente su iOS.
  - Il ponte inoltra il corpo della richiesta così com'è, schema compreso.
  - Le prove usano un server finto con una sessione propria, quindi passano dal fornitore delle impostazioni e non dal ponte.
  - `assembla.sh` copia `Ruby/Schemi` ed `Ruby/Esempi` anche su iOS.
- **Scene:** i nomi sono unici in tutto il modulo (480-484); le varianti «-scuro» seguono la convenzione del suffisso.
- **ProvaFluidita:** gira con `\.modoIstantanea`, quindi la sfera è ferma sia lì sia nelle istantanee. Con «Riduci movimento» la sfera è ferma.
- **Prove ancora valide:**
  - Le funzioni usate esistono con le firme giuste.
  - La scatola generica per l'attesa è fuori dalla funzione, dove Swift la accetta.
  - Su iPhone si salta solo la prova «Qwen non è pronto».
  - Nessuna frase delle altre prove apre per errore uno scenario.

**Scelte che il template non copre (da decidere tu)**
1. **Ritmo della sfera:** la sfera si muove con un `TimelineView` a 30 fotogrammi, fermo quando non serve, invece di un'animazione SwiftUI ripetuta come chiedeva la regola. Non è un Timer.
2. **Quando respira:**
   - Sulla scrivania solo se non ci sono finestre aperte (`SferaScrivaniaScoperta`).
   - Nella barra solo con la mini finestra aperta.
   - Nell'app Ruby e nella Ruby della scrivania sempre, finché la vista è sullo schermo.
3. **Scenari e modalità:** uno scenario si calcola e si racconta sempre in modalità lavoro, anche con «Conversazione» scelta nella testata.
4. **Numeri inventati da Qwen:** se Qwen mette un numero che nella frase non c'è (per esempio un rendimento), Prisma lo usa. Le regole dell'app vincono solo sulle cifre scritte nella frase.
5. **Risposte brevi:** mentre Ruby aspetta un dato, una frase di 8 parole o meno viene presa come risposta allo scenario, e «lascia stare» lo chiude.
6. **Numero delle scene:** le scene degli scenari sono 484 (`484-ruby-scenario`, `484-ruby-scenario-scuro`, `484-ruby-mini-scenario`).
7. **Dove si aprono gli scenari salvati:** l'avviso dice «Analisi 360 › Scenari» sul Mac e «Simulazioni › Scenari» su iPhone e iPad. In protezione «Salva nel dossier» scrive una nota del taccuino e il pulsante diventa «Apri in Analisi 360».
8. **Mini finestra:** la tabella prima/dopo compare sotto la risposta breve, con «Salva nel dossier» e «Apri in…». Il salvataggio non mostra il messaggio di saluto, perché ha già il suo avviso.
## Giro 7
**Esito del controllo d'insieme sul Giro 7.** Non ho trovato conflitti tra le quattro parti e non ho trovato errori di compilazione. Ho fatto una sola correzione: i nomi delle scene del tavolo sull'iPad. Qui manca il compilatore, quindi i controlli li ho fatti a mano e con grep: la conferma arriverà solo dalla prima build su GitHub Actions. Nessun commit.

## Correzione

- **Nomi delle scene del tavolo sull'iPad.** In `/home/user/Prisma/Sources/Prisma/iOS/IstantaneeMobile.swift` le quattro scene si chiamavano `ipad-490…493`. Così si sarebbero salvate come `ios/ipad/…/ipad-490-….png`, diverse da tutte le altre PNG dell'iPad, che non hanno il prefisso. Le ho rinominate `50-tavolo-pagina`, `51-tavolo-cursore`, `52-tavolo-presa-visione` e `53-tavolo-neutro`: sull'iPad i numeri 50-53 erano liberi. Nessuno script o workflow usava i nomi vecchi. Ho aggiornato anche il commento in `/home/user/Prisma/Sources/Prisma/iOS/IstantaneeTavoloiPad.swift`.

## Controllato, senza bisogno di modifiche

- **File toccati da più parti:**
  - `IstantaneeMobile`: nella stessa lista convivono i commenti della parte iPad (attese) e le scene del tavolo, senza sovrapposizioni.
  - `StatoMobile`: `tavolo`, `alTavolo` e `acquaCoperta` sono inizializzati prima dei `sink`, e gli abbonamenti non si pestano con `elencoCambiato`.
  - `PrismaAppMobile`: la radice osserva `mobile` con `@ObservedObject`, quindi `alTavolo` e `acquaCoperta` la ridisegnano. `AspettoEAvvisoMobile(nascondiAvviso:)` resta coerente.
  - `ImpostazioniPagine`: `GruppoTavoloiPad()` sta nel ramo `#if os(iOS)` (righe 286-325), quindi il Mac non lo compila.
  - `ImpostazioniMobile` non è stato toccato.
  - `PonteRuby.chiave(_:sale:)` ha il sale predefinito, quindi chi lo chiamava già non cambia.
  - `build.yml` ha una sola aggiunta (`--prova-tavolo`). `Package.swift` non è cambiato.
- **Nomi doppi:** nessuno nel modulo, né tra i tipi pubblici né tra quelli `private` dei file nuovi. `Tema.Apple.Tavolo` e `Tema.Apple.Tavolo.iPad` sono dichiarati una volta sola.
- **Parentesi e `#if`:** le graffe, le parentesi e le stringhe sono bilanciate in tutti i 40 file cambiati e nei 4 file nuovi (controllo automatico che salta commenti e stringhe), e ogni `#if` ha il suo `#endif`.
- **Mac e iOS:**
  - `ProtocolloTavolo` usa solo Network, CryptoKit, ImageIO, UTType e CoreGraphics, che esistono su tutti e due.
  - `TavoloMac`, `ProvaTavolo`, `AlTavolo` e `IstantaneeTavolo` sono chiusi in `#if os(macOS)`; il codice iPad del tavolo in `#if os(iOS)`.
  - I file del tema non usano né AppKit né UIKit.
  - `@Sendable [weak self]` in `OsservatoreTavolo` è scritto correttamente.
  - L'`onChange` di `CursoreTavoloiPad` ha un solo parametro.
- **Nomi delle scene:**
  - Mac: `470-tavolo-sala` e `471-tavolo-presa-visione` sono unici. L'unico «440» doppio è `440-analisi360-apple` con la sua variante `-scuro`, che c'era già.
  - iOS: i nomi sono unici sia nella lista dell'iPad sia in quella dell'iPhone. Ogni scena parte da uno `StatoMobile` nuovo, quindi il tavolo non resta acceso nelle scene successive.
- **Prova del tavolo:**
  - `PrismaApp` riconosce `--prova-tavolo`, e il workflow la lancia dopo `--prova-ruby`.
  - Gira su 127.0.0.1 con la porta 0, senza annuncio Bonjour. Gli eventi passano dalla coda principale, che la prova fa girare con `RunLoop.main.run`, quindi non si blocca.
- **ProvaFluidita sul Mac:** non peggiora.
  - Sulla scrivania si legge solo una chiave d'ambiente in più (`istantaneaSchermo`).
  - `TavoloMac` è `lazy` e si crea senza aprire nessuna connessione: si mette in ascolto solo con «Apri il tavolo». Tiene `StatoShell` con un riferimento debole, quindi non trattiene la memoria.
  - Nota: `.onDisappear` della sala lo crea alla prima chiusura della presentazione (costo trascurabile).
- **Archivio e `--prova-backup`:** nessun cambiamento ai modelli dei dati né all'archivio. La presa visione finisce nei Documenti, che il backup già comprende, quindi la prova resta valida.

## Scelte non coperte dal template

Il tavolo non compare né in `template-apple-specifica.md` né in `iphone.html`: tutto il tavolo è una scelta nostra, fatta coerente con il tema.

- **L'iPad al tavolo:** occupa tutto lo schermo, senza dock, senza barra di stato, senza indicatore della Home e con lo schermo sempre acceso.
- **La schermata neutra:** il logo sull'acqua con la riga «In attesa del Mac…» oppure «Mi collego al Mac…». L'acqua si ferma solo quando il foglio copre davvero lo schermo, come sotto la sala del Mac.
- **Da dove si entra:** da Impostazioni › Ruby, nel gruppo «Tavolo con il Mac», e dalla schermata d'apertura anche senza backup.
- **Il codice:** è lo stesso del ponte di Ruby, ma la chiave usa un sale proprio del tavolo.
- **I valori di rete:**
  - porta 47621 e servizio Bonjour `_prisma-tavolo._tcp`, senza collegamento diretto tra dispositivi;
  - battito ogni 2 s, connessione caduta dopo 7 s di silenzio, 6 s per abbinarsi;
  - dopo una caduta l'iPad riprova ogni 2 s; se il codice viene respinto 3 volte di fila il tavolo si chiude;
  - un iPad alla volta: l'ultimo che si abbina sostituisce il precedente.
- **La presa visione:**
  - si disegna in un Canvas di SwiftUI con DragGesture, non con PencilKit;
  - il tratto si manda come PNG trasparente con un inchiostro fisso;
  - la scritta è «Presa visione del documento: non costituisce firma contrattuale».
- **Le pagine:** si mandano in PNG a 2×, sempre su carta bianca e chiara, al massimo 24 per messaggio.
- **Il nome dell'iPad:** viene da `UIDevice.current.name`. Da iPadOS 16 questo restituisce di solito solo «iPad», quindi sul Mac si leggerà «iPad collegato · iPad».
- **Le istantanee dell'iPad:** quattro scene del tavolo (50-53), scattate in verticale.

## Da provare sui dispositivi veri

**Abbinamento**
1. Sul Mac apri Prospetti, scegli un prospetto di un cliente e premi «Al tavolo», poi «Apri il tavolo». Al primo avvio macOS deve chiedere il permesso per la rete locale: accettalo.
2. Sull'iPad apri Impostazioni › Ruby › «Tavolo con il Mac», controlla che il codice sia quello del Mac e premi «Al tavolo con il Mac». Al primo uso iPadOS deve chiedere l'accesso alla rete locale.
3. Durante «Cerco il Mac…» premi «Annulla»: l'iPad deve tornare normale.
4. Riprova: l'iPad deve entrare a tutto schermo e il Mac deve mostrare «iPad collegato».
5. Prova con un codice sbagliato: deve comparire «Il Mac non riconosce questo codice…» e l'iPad non deve mostrare niente.
6. Prova anche dalla schermata d'apertura di un iPad senza backup: campo del codice, poi «Al tavolo con il Mac».
7. Collega un secondo iPad, se ne hai uno: il primo deve uscire con «Il Mac ha chiuso il tavolo».

**Rete**
8. Mac e iPad sulla stessa Wi‑Fi di casa e poi su quella dello studio: il Mac va trovato senza scrivere indirizzi.
9. Su una rete ospiti o con «isolamento dei dispositivi» il Mac non si trova: entro circa 6 s deve comparire «Non trovo il Mac…».
10. Mostra una pagina, un prospetto intero di molte pagine, la macchina del tempo e la famiglia. Guarda quanto ci mettono ad arrivare e se si leggono bene sull'iPad, in verticale e in orizzontale.
11. Apri un altro cliente sul Mac mentre l'iPad mostra qualcosa: l'iPad deve tornare subito alla schermata neutra.
12. Lascia un cursore al cliente: muovilo sull'iPad e controlla che il risultato ricalcolato dal Mac torni in pochi istanti.

**Presa visione con il dito e con la Pencil**
13. Dal Mac chiedi la presa visione. Sull'iPad controlla la scritta esatta: «Presa visione del documento: non costituisce firma contrattuale».
14. Traccia con il dito, poi «Annulla»: l'area deve svuotarsi. Traccia con la Pencil e premi «Conferma».
15. Con la Pencil appoggia il palmo sullo schermo. Il Canvas non riconosce il palmo: guarda se lascia segni non voluti e dimmelo.
16. Guarda se il tratto della Pencil segue la punta senza ritardo e se i tratti veloci restano lisci.
17. Sul Mac controlla l'ultima pagina del PDF: tratto, data e scritta, su carta bianca. Il PDF deve comparire nei Documenti del cliente.

**Caduta della rete**
18. Con un foglio sull'iPad spegni la Wi‑Fi dell'iPad: entro circa 7 s deve comparire la schermata neutra, con il solo logo e nessun dato.
19. Riaccendi la Wi‑Fi: l'iPad deve ricollegarsi da solo e restare neutro finché il Mac non manda di nuovo qualcosa.
20. Ripeti spegnendo la Wi‑Fi del Mac, poi chiudendo il coperchio del Mac (riposo), poi chiudendo Prisma sul Mac. In tutti e tre i casi l'iPad deve restare neutro e riprovare.
21. Manda l'app dell'iPad in background e riaprila, sia durante il tavolo sia dopo un minuto di schermo spento: non deve mai ricomparire una pagina vecchia.

**Uscita solo dal Mac**
22. Al tavolo, sull'iPad: nessun pulsante né gesto deve uscire, né lo scorrimento dai bordi né i tocchi lunghi. La barra della Home e il Centro di Controllo restano comunque al sistema: guarda che cosa resta visibile.
23. Nota che l'iPad, per sua natura, si può sempre chiudere con il gesto della Home. Se vuoi che il cliente non possa uscire, usa Accesso guidato (Impostazioni dell'iPad › Accessibilità).
24. Sul Mac premi «Schermata neutra»: l'iPad torna al logo. Poi «Chiudi il tavolo»: l'iPad deve uscire con «Il Mac ha chiuso il tavolo» e tornare al Prisma normale.
25. Chiudi la presentazione sul Mac mentre l'iPad mostra una pagina: l'iPad deve tornare neutro.
26. Controlla che lo schermo dell'iPad non si spenga mai al tavolo e che torni a spegnersi normalmente dopo l'uscita.

File toccati in questo controllo:
- `/home/user/Prisma/Sources/Prisma/iOS/IstantaneeMobile.swift`
- `/home/user/Prisma/Sources/Prisma/iOS/IstantaneeTavoloiPad.swift`