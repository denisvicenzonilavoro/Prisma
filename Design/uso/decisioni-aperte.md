# Migliorie d'uso · Mac — decisioni aperte e controlli a occhio

Raccolti il 15 novembre 2026 da Design/uso/resta-da-fare.md, dopo i 12 giri e il primo giro di rifinitura.
Le decisioni sono dell'utente; i controlli si fanno sulle istantanee o sul Mac vero.

## Decisioni confermate dall'utente il 15 novembre 2026

- Colori nuovi (testi piccoli, totale) solo sul Mac; iPhone e iPad con il loro aggiornamento.
- Etichetta sotto le risposte di Vera: resta «Qwen» (regola bloccata del cervello grande).
- Nessun campo nuovo in Prodotto: le frasi «È per / Non è per» le scrive il codice.
- Il fascicolo scelto resta in memoria.

## Migliorie 1-10

### Decisioni
- Miglioria 1, il blocco e la vista pulita: la specifica (gruppo-01 righe 251-252) dice che il blocco non chiude la vista «come oggi non chiude la modalità cliente», ma il codice lo smentisce. `blocca()` (StatoShellFinestre.swift:528, 538) toglie sempre `modoCliente`, e la prova di Vera lo richiede. Va deciso se allo sblocco si torna nella vista pulita (il blocco terrebbe la modalità cliente: cambia una garanzia di privacy) o se resta com'è.
- Miglioria 1, «Un prospetto» del pannello: oggi apre sempre il report del check-up (`.checkUp(report: true)`, MostraAlCliente.swift:193). Va deciso se aprire l'ultimo prospetto aperto in Prospetti nella versione «Per il cliente» (miglioria 22, già pronta) o proporre una scelta fra i prospetti.
- Miglioria 1, il menu dell'avatar nella vista pulita: oggi è una scheda disegnata e non un menu del Mac. Va scelto se tenerla così.
- Miglioria 1, «Gli obiettivi»: oggi dice «traguardo a <mese anno>» (la data dell'obiettivo). Va deciso se serve una data d'arrivo stimata, che chiede un calcolo nuovo; `ArrivoObiettivo` della miglioria 13 ha già i mesi e potrebbe darla.
- Miglioria 2, Agenda e Attività: oggi le filtra solo una scelta fatta con `scegliCliente`, non le scelte silenziose `clienteAttivoId = …`. Va deciso se farle diventare letture del cliente della barra; le prove che contano tutti gli impegni e tutte le note andrebbero riscritte.
- Miglioria 9, l'etichetta del motore sotto le risposte («Sul Mac · Qwen…», `EtichettaMotore.per`): resta finché l'utente non approva la proposta di 9.6, perché è una regola bloccata del cervello grande.
- Miglioria 10, tre usi di «Prepara l'incontro» da decidere guardando le istantanee: il titolo della mossa del giorno «Prepara l'incontro con …» (`MossaDelGiorno.titolo`), il pulsante «Prepara l'incontro» del dettaglio dell'Agenda e il nome della routine di Vera «Prepara l'incontro». Tutti hanno le loro prove.
- Miglioria 4 e 12, le azioni della riga in testa: nelle app diverse dal dossier passano ancora alla sola icona quando manca lo spazio. Va deciso se estendere a tutte le app la regola «sempre con il nome» con «Altro ⌄».
- Miglioria 7, il tema di prima: `Tema.Colore.arancio` (#FF9500), `scadenzaVicina` e i token simili non sono stati scuriti, perché la specifica parla solo del tema Apple. Va deciso se allinearli.
- Miglioria 5: va deciso se riportare in Prisma il giro guidato del template «Il dossier parte dal quadro» (`indica('#quadroC')`).

### Controlli a occhio
- Istantanee da rigenerare sul Mac e guardare chiare e scure, poi aggiornare la pagina delle anteprime. Miglioria 1: 1010-1019, 70, 693 (quadro con testo «Grande» e riquadri alti 548, colonna delle posizioni, grafico «Nel tempo»). Miglioria 2: 1020-1027 e le scene con portafoglio = true (65, 64, 420, 116), Analisi 360 e Sala senza pillole; il pannello allineato alla pillola, il nome lungo tagliato entro 230. Miglioria 3: 412, 410, 616, 118, 117, 133, 153, 738 e 1030-1035. Miglioria 4: tutte le scene con una finestra aperta, per prime 413, 430, 420 e le «finestra-stretta» 234-238. Miglioria 5: 430, 431, 152, 1050-1052 (la colonna di destra non deve allungare troppo la griglia). Miglioria 6: 420, 600, 225, 226, 410, 616, 1060. Miglioria 7: tutte, prima 400, 410, Agenda, Studio › Parcelle e scadenze. Miglioria 8: 420, 421, 434, 435, 298 (in chiaro la linea del totale non si confonde con il testo). Miglioria 9: 410, 296, 297, 244, 251 e le scene di Vera e Messaggi («Apri Impostazioni › Vera» accanto a «Verifica» nella colonna stretta). Miglioria 10: Analisi 360 (occhiello più lungo non troncato) e la guida col glossario.
- Miglioria 1, capitolo «La Sala» nella vista pulita: controllare se la barra dei capitoli copre il fondo della finestra della Sala (istantanea 693 o screenshot).
- Miglioria 4, sul Mac vero: controllare che Esc dentro dettagli, schede, palco della Sala e presentazione faccia scattare prima i `.keyboardShortcut(.cancelAction)` (`performKeyEquivalent`) e solo dopo chiuda la finestra. Se non lo fa, aggiungere le condizioni a `nienteSopra` o togliere «(esc)» dall'aiuto.
- Miglioria 4: le tele fisse (Territorio, Radar, Campagne, Passaparola) con circa 26 punti in più di altezza; il dettaglio aperto centrato a 92 dall'alto (se sembra basso, portarlo a 60 + 12); il passaggio sulla chiusura rossa (serve uno screenshot).
- Miglioria 6: il menu «Aggiungi» aperto è un NSMenu e non si vede nelle istantanee. Serve uno screenshot per la posizione (sotto il puntatore e non sotto il pulsante), la larghezza di almeno 236 e le voci alte 36.
- Miglioria 3: il passaggio sul cerchio e l'uscita della riga del «Da fare» (serve uno screenshot).
- Miglioria 7: i segni con `inchiostro3` (assi, tratteggi, maniglia) più scuri. Se un tratteggio pesa troppo nelle istantanee, serve un token a parte per i segni.
- CI (log di build.yml): le prove che scrivono portafoglio/veraPortafoglio = true ora cambiano il cliente attivo (miglioria 2). In `--prova-fluidita` controllare il pannello «Da fare», i passaggi del portafoglio, il trascinamento e il ridimensionamento con `TestaFinestra`. In `--prova-carico` controllare il pannello del cliente e il nastro del «Da fare» con 200 clienti; il Territorio ora conta anche scadenze e compleanni.

### Lavori lasciati per dopo (poco valore, rischiosi o grandi)
- Le notifiche rimaste passano nel nastro del «Da fare» (medio/alto/L)
- I promemoria del Mac leggono il nastro del «Da fare» (basso/medio/M)
- Le parole rimaste: «Cerca ovunque» e «Check-up completo» sul Mac (basso/basso/S)
- Controllo statico delle parole che spariscono nel workflow (basso/medio/S)
- Pulsante diviso «Nuovo cliente | ⌄» con la forma del template (basso/basso/S)
- Token arancio da dividere fra segno e testo (Vera non pronta) (basso/basso/S)
- Prospetti con «Tutti i clienti»: il prospetto del portafoglio (basso/medio/S)
- Movimento del pannello «Mostra al cliente»: l'ombra al passaggio (basso/basso/S)
- --prova-fluidita: misura del cambio di capitolo (basso/basso/S)
- Il dettaglio dell'area di Analisi 360 nasce dalla card (basso/basso/S)
- Annullare un riesame toglie anche le promesse (basso/basso/S)

## Migliorie 11-17

### Decisioni
- 12 e 14: la quarta tessera dice «· x €» e «per x €» perché `RiepilogoPosizioni.valoreProposte` è il versamento iniziale più un anno di premi, non un valore annuo. Due strade: scegliere una parola diversa da «l'anno» del template, oppure chiedere un motore che dia il premio annuo delle proposte.
- 13: aggiungere nel dettaglio dell'obiettivo la riga facoltativa «Alla scadenza copre il 78%» (13.6)?
- 12: le azioni della riga in testa delle altre app (TestaFinestra in FinestraInterna.swift, quarta variante `soloIcona: true`) passano ancora alla sola icona quando lo spazio manca. Estendere a tutte le app la regola «sempre con il nome, il resto in Altro ⌄» del dossier?
- 12: le varianti `compatti` con le icone di `TestataDossierApple` restano per l'iPad. Si tolgono con il giro dell'iPad: quando farlo?
- 15: per gli immobili si vede «Debiti residui» e «Al netto dei debiti», perché Posizione non distingue il mutuo. Per avere «Mutuo residuo» servirebbe un campo nuovo dell'archivio, con la prova del backup da aggiornare. Lo si vuole?
- 15: la pillola «Scade tra {n} gg» e «Debito» al posto di «In essere» sono solo sul Mac. La specifica di gruppo le voleva anche su iPhone e iPad: portarle ora o con il loro giro?
- 17: la scheda Bisogni usa ancora i caratteri di Rubrica (`Tipo` e `Colori.Rubrica`, circa 38 usi). Portarla nel tema Apple, riprendendo capsula e nota da `BisogniCliente.prioritaVista)`? È un lavoro da guardare sulle istantanee.
- ~~Già fatte, da togliere dal resta-da-fare~~: tolte il 15 novembre 2026 (numero degli Obiettivi nell'indice, «Aggiungi un'azienda…» e «Nuovo cliente», gruppi 07 e 08; la voce 15 su `fuocoModulo` era già corretta).

### Controlli a occhio
- 13: rigenerare sul Mac le istantanee 432, 433, 282, 283, 98 e 1023 (chiare e scure). Nella 1023 l'anticipo casa deve risultare «In ritardo»: il versamento è il 75% del necessario, e se il conto collegato basta resta verde.
- 13: `--prova-carico` per vedere che le curve dei molti obiettivi non svuotino di continuo la memoria di 24 curve.
- 17: rigenerare 440 (chiara e scura), 99, 300, 301 e 1032/1075. Le capsule «Priorità n» non devono andare a capo accanto al collegamento, nella colonna vicino alla ruota.
- 11: rigenerare 430 (anche scura), 431-clienti-panoramica-apple, 431-clienti-dossier-in-regola, 432-434, 1023, 1075, 1050-1052 e 1028-1029. Il nome lungo si taglia nella testa dell'indice, e con la finestra stretta compare «Sezione: … ⌄».
- 11: `--prova-fluidita`: guardare i corpi di `IndiceDossierApple` nel passo di Clienti.
- 11 (dopo il lavoro sezT): controllare sulle istantanee, sezione per sezione, dove la testata serve e dove fa doppione.
- 12: rigenerare le scene del dossier (430-434, 1023, 1028-1029, 1075, 1050-1052) e 1036-1037. Nella versione stretta deve comparire «Altro ⌄» con le azioni intere, e il titolo lungo non deve spingere fuori «Prospetti». `--prova-fluidita` sui corpi di `RigaTestaDossier`.
- 16: rigenerare 440 (anche scura), 443, 444, 17-analisi360, 111-analisi360-ipotesi-stimate, 1050, 1038 e 1039. In una finestra stretta la capsula «Stime in uso» non deve andare a capo accanto all'etichetta «di prova».
- 14: rigenerare 2, 9, 10, 71, 74, 76, 79, 95-97 e 1040-1043. Misurare un cliente con 40 posizioni (l'elenco nella card) e `--prova-fluidita` con 200 clienti. Controllare che `ProvaDelFuocoApple` e `ProvaSeguito` (ancora «seguito») restino verdi.
- 14: guardando le istantanee, valutare se servono le altezze fisse 92 delle tessere e 304 della ripartizione, oggi assenti (tessere alte quanto il contenuto, colonna destra che scorre), e se serve il titolo grande 21 bold delle analisi (`PannelloAnalisi` tiene il 17).
- 15: sul Mac vero, Esc nella scheda della posizione deve fare un passo indietro con il fuoco fuori dalla scheda, e non deve scattare con un foglio aperto (alert di «Elimina», modulo).
- 15: rigenerare 8, 10, 91-94, 106, 119, 121, 235, le scene con le ancore «dettaglio-…» e 1072-1074, poi aggiornare la pagina delle anteprime.
- Dopo i lavori 1-8: rigenerare le istantanee toccate (indice, rubrica senza cliente, analisi vuote, scheda della posizione) e aggiornare la pagina delle anteprime.

### Lavori lasciati per dopo (poco valore, rischiosi o grandi)
- Sfumatura in fondo all'indice del dossier (11) (basso/basso/S)
- Rientro animato al cambio di scheda della posizione (15) (basso/basso/S)
- Testata della scheda della posizione come nel template (15) (basso/basso/S)
- Grafico piccolo in «Come sta andando» (15) (basso/basso/S)
- Avviso «Dato completato: una stima in meno» (16) (basso/medio/M)
- Testata `sezT` sulle sezioni del dossier senza titolo proprio (11) (basso/medio/M)

## Migliorie 18-24

### Decisioni
- 21: toccare in «Tutti i clienti» la riga di un altro cliente non cambia il cliente della barra (scelta del template, contraria a 21.3 punto 3): confermare che va bene così (il lavoro 2 sistema comunque «Analisi»)
- 21: sul Mac non c'è più «Ascolta un incontro senza appuntamento»: confermare che basti «Nuovo incontro» e poi «Inizia l'ascolto»
- 21: gli incontri in preparazione con la data passata e senza appuntamento non compaiono in nessun gruppo: serve un quarto caso, per esempio «Da riprendere»?
- 20: «Fissa il prossimo» apre il modulo dell'appuntamento fra 30 giorni alle 10 («Seguito · …»): va bene così, o meglio aprire l'Agenda con il cliente scelto?
- 10/18/19: «Prepara l'incontro» del dettaglio dell'Agenda, il titolo della mossa del giorno e la routine di Vera «Prepara l'incontro»: la 10 li lascia da decidere. Rinominarli tutti in «Preparami l'incontro»?
- 18: la scala al passaggio (1,03) nella settimana non è stata messa, perché basta l'inclinazione: confermare
- 23: la scheda della «i» non ha gli elenchi puntati di cosa contiene ogni documento (prospetto e report): servono? Se sì, TipoProspetto.contenuto(versione:)
- 23: la colonna dei Prospetti resta larga Misura.Laterale.prospetti e non 300 come nel template: cambiare il token?
- 23: sul Mac, sotto la voce scelta, non ci sono più i collegamenti «Apri l'Analisi 360» e «Apri il Portafoglio in Posizioni» né l'elenco dei punti del riesame: confermare
- 22: la 463-prospetti-solo-per-il-cliente non è stata aggiunta perché la 460 mostra già l'etichetta «Solo per il cliente»: confermare
- 24: il tavolo con l'iPad dai Prospetti: tenere «Altro › Al tavolo…» con PannelloAlTavolo, o passare tutto dalla vista pulita della 58 (che oggi a tutto schermo copre l'etichetta del luogo)?
- 24: il puntino dello stato del tavolo non c'è più nella barra dei Prospetti (il Menu di sistema non lo disegna): basta lo stato nel pannello, o va rimesso, per esempio con un menu disegnato o un segno accanto ad «Altro»?

### Controlli a occhio
- 18: rigenerare sul Mac le istantanee 450 (chiara e scura), 451, 452, 453, 455, 11-agenda, 11b-agenda-giorno, 130/131 e 1027-agenda-solo-cliente, e aggiornare la pagina delle anteprime
- 18: il popover «Occasioni» (454) e il passaggio del puntatore sull'intestazione e la cascata della settimana non si vedono nelle istantanee: serve uno screenshot dall'utente
- 18: le corsie della settimana (CorsieImpegni con l'altezza minima della giornata): guardare con i 30 clienti fittizi se con tre corsie strette l'impegno mostra solo il nome
- 18: nel log di --prova-fluidita in CI controllare che l'Agenda, che ora parte sulla settimana, non faccia crescere i corpi rifatti con 30/200 clienti (TimelineView della riga dell'ora e degli impegni nella colonna di oggi)
- 19: rigenerare 452, 456 (chiara e scura), 457, 11-agenda e 11b-agenda-giorno; il menu «Altro ⌄» e i passi dell'accettazione aperti nella scheda chiedono uno screenshot
- 20: rigenerare 21, 22, 105, 215, 476, 477, 580-589 e le nuove 472-475; il foglio del consenso, l'avviso «Fermare l'ascolto?» e la spunta al passaggio chiedono uno screenshot
- 20: la testata dei momenti con titoli lunghi e la finestra stretta (sotto i 900 punti della parte destra): guardare se il titolo troncato e i momenti ci stanno
- 21: guardare 476 e 477 e, con i dati veri, se esistono incontri in preparazione con la data passata e senza appuntamento, che oggi non compaiono in nessun gruppo
- 22: controllare a occhio, su 466 e sulle scene «…-prospetto», che il timbro «SOLO PER TE» non copra logo, data o etichetta del canale su nessuna prima pagina, e che la frase dell'ultima pagina di FoglioProspetto stia nei 22 punti sotto il piede
- 22: sul Mac, se l'avviso «Al cliente si mostra la versione per il cliente» resta visibile sopra la sala della presentazione (altrimenti la presentazione va ritardata di un tempo del tema)
- 22/23: rigenerare 460 (chiara e scura), 461, 464, 466 (chiara e scura), 236, 81, 82 e le scene dei prospetti (27-44, 66, 69, 101, 102, 112, 211, 212); aggiornare la pagina delle anteprime
- 23: il popover «A cosa serve» della «i» (465) non entra nelle istantanee: screenshot dall'utente
- 24: lanciare a mano --prova-tavolo sul Mac; il menu «Altro ⌄» aperto dei Prospetti e il ripiego ViewThatFits («Salva PDF + Altro» nelle finestre strette) chiedono uno screenshot

### Lavori lasciati per dopo (poco valore, rischiosi o grandi)
- Incontri: uscita del contenuto al cambio di momento (20) (basso/basso/S)
- Tondo del numero delle domande con il token del tema Apple (20) (basso/basso/S)
- La traccia aperta si rifà quando l'impegno finisce (19) (basso/basso/S)
- Coda del check-up nella frase dell'ultima pagina per te (22) (basso/basso/S)
- «Al tavolo…» dei Prospetti passa dalla vista pulita della 58; togliere PulsanteAlTavolo (24) (basso/medio/M)
- --prova-fluidita: Incontri con il copilota che ascolta (21) (basso/basso/M)

## Migliorie 25-31

### Decisioni
- 31: «Lasciali spenti» per i promemoria (§31.6). Richiede un campo nuovo in Impostazioni, quindi archivio, backup e ProvaBackup. Oggi i promemoria spenti contano come cosa da sistemare, come nel template: decidere se l'utente vuole poterli spostare in «A posto».
- 31 e 39: in «Prisma ovunque», con lo spazio spento, le righe sono nascoste (transizioni in ImpostazioniOvunque.swift), mentre §31.3 punto 6 le vorrebbe attenuate. Decidere se tenerle nascoste, come nel collegamento unico della 39, o mostrarle attenuate.
- 25: un messaggio aperto ieri e segnato spedito oggi deve comparire in «Mandati oggi»? Oggi sparisce, come prima della miglioria (vedi il lavoro 4).
- 25: barra a tre stati, «Mandati oggi» e il segno «spedito» su iPhone e iPad. Portare speditoIl nel giornale di «Prisma ovunque» allarga ciò che viaggia nello spazio cifrato (EntitaOvunque) e serve l'approvazione dell'utente.
- 27: passo della cascata degli esempi, 0,048 s del tema o 0,07 s del template (vedi il lavoro 12).
- 29: frase con la quota in azioni («ha il 38% in azioni»). Con le posizioni senza quotaAzionaria la quota sarebbe stimata dall'SRI: decidere se dirlo comunque, magari con «circa», o solo quando la quota è scritta.
- 30: se nelle istantanee l'occhiello a 13/4 stringe troppo la colonna, tornare a 16/8 nei token.
- 29: TestiAppMercato.silenziato va cambiato solo se una miglioria futura porterà gli avvisi .nuovo nel «Da fare». Verificato: oggi MotoreDaFare non legge Mercato, quindi per ora non serve nessuna modifica.

### Controlli a occhio
- 26: rigenerare 490-495 (chiare e scure) e guardare la 1044: nella 494 deve restare l'avviso del testo di Prisma e la fila «Tono / Invia con / Vera ha usato N dati» non deve andare a capo nella finestra normale. La coordinazione con la 25 e la 49 è già risolta nel codice: TestiMessaggi.tono e inviaCon sono usati in PannelloMessaggio.
- 25: rigenerare 490-496 (numeri accanto agli occhielli), 1040-1043 e 730, poi aggiornare la pagina delle anteprime. Nella 1040 verificare se Giulia mostra lo spedito invece di altre occasioni; nella 1043 controllare che Elena Fabbri non abbia davvero occasioni (traguardi o consensi).
- 27: rigenerare 480-487, 19-vera, 46-vera-pensione e 47-vera-checkup; guardare la 1045 e la 1046 (colonna stretta a metà schermo, griglia degli esempi nella finestra piccola).
- 28: rigenerare 510-514 e guardare 1047-1050: altezza della colonna delle azioni nelle finestre basse (la scheda «A che punto è» aggiunge circa 110 punti) e il filtro nella barra stretta a 300. Con la 52, già fatta, guardare la riga in testa di Studio con «＋ Nuova parcella» nella finestra al minimo.
- 29: rigenerare 540-547 e guardare 1051-1053: Marco potrebbe non avere eventi né avvisi (allora la 1051 mostra solo i due vuoti con il nome); controllare la larghezza della riga degli avvisi con due pulsanti nelle finestre strette.
- 30: rigenerare 470 (e scura), 471, 3, 90, 126, 134, 144, 85, 251, 516 e 548, e guardare 1054-1055: l'occhiello a 13/4 non deve stringere troppo la colonna.
- 30, sul Mac vero: il campo «Cerca nelle impostazioni» non deve prendere il fuoco da solo all'apertura, e ⌘F non deve disturbare la Biblioteca aperta dietro.
- 31: rigenerare 470/471, 1054/1055, 250-impostazioni-panoramica e 1056-1058: l'etichetta più lunga («sullo stesso Mac», «non aggiornato») non deve stringere troppo il titolo delle voci della colonna. Dopo il lavoro 1, guardare anche che le righe attenuate di Mercato e Notte siano leggibili, in chiaro e in scuro.

### Lavori lasciati per dopo (poco valore, rischiosi o grandi)
- 25: «Mandati oggi» anche per un messaggio aperto ieri e segnato spedito oggi (basso/basso/S)
- 25 e 28: controlli scritti in --prova-fluidita (basso/basso/S)
- 25: Agenda «Occasioni» con NumeroOcchielloApple e token comuni (basso/basso/S)
- 31: «N su M» dei dati per le fatture (basso/basso/S)
- 27 e 31: la riga del tagliando in «Da sistemare» sparisce dopo una correzione (basso/medio/S)
- 29: variante piccola del pulsante del tema (6×12) (basso/basso/S)
- 27: passo della cascata degli esempi a 0,07 s come nel template (basso/basso/S)
- 30: ancore per singola riga nella ricerca delle impostazioni (basso/basso/M)

## Migliorie 32-39

### Decisioni
- 35 · Collegare i fac-simile della Biblioteca ai prodotti di prova con lo stesso nome in caricaEsempiBiblioteca (proposta §35.6)? Senza il collegamento, il gruppo «Dei prodotti di <Nome>» con i soli dati di prova non si vede mai.
- 35 · «Cerca in tutti i documenti» solo sotto la tile del documento aperto, o anche accanto al campo (§35.6)?
- 36 · CLAUDE.md: riscrivere la frase sull'ordine del dock («Nel dock dopo Agenda, Messaggi e Prospetti…») con i gruppi nuovi quando la miglioria entra in main. CLAUDE.md lo aggiorna l'utente, o lo approva. La nota su ProvaFluidita che apre le app nell'ordine di delDock non chiede lavoro: lì l'ordine non conta.
- 37 · scritteProva deve tacere anche in modalità cliente, come propone la specifica? Cambierebbe le istantanee della Sala in modalità cliente.
- 38 · Regola del canale in CLAUDE.md (§38.6.1): con un nome scelto l'etichetta perde il logo Alleanza e mostra il nome, sempre nel colore del canale. Va riscritta dall'utente.
- 38 · «Come funziona» della guida (§38.6.3): resta come scheda in più nel «?», o va tolta sul Mac lasciando che il menu Aiuto e Impostazioni › Aspetto aprano PrimoAvvio?
- 38 · Scritte fisse rimaste che nominano la compagnia («Le percentuali che Alleanza ti riconosce…», le note di Studio sulle posizioni Alleanza, coerenza e adeguatezza «nel canale Alleanza», le firme «Consulente Alleanza Assicurazioni» nei PDF, glossario, guida, copilota): vanno decise una per una, perché molte parlano davvero della compagnia e non del canale.
- 38/39 · Il giro di iPhone e iPad: nomi dei canali scelti sul telefono e nome vero del dispositivo nelle chiamate al modello (campo facoltativo dispositivo in BustaPonte, compatibile con il protocollo 3). Quando farlo?
- 39 · Il codice breve che scade (decisione 2): richiede un abbinamento nuovo su Mac, iPhone e iPad, quindi un cambio del protocollo del ponte. Si fa?

### Controlli a occhio
- 32 · Sul Mac le istantanee 1100-1103 (chiare e scure): se con i 35 clienti di prova Giulia ha vicini; la posizione della SchedaLuce vicino al bordo (l'altezza stimata è 170); se la riga patrimonio con due canali sta nella scheda.
- 33 · 801 e 1105: se la riga dei passi spenti (anticipo) si legge con l'opacità 0,7 del riquadro, altrimenti va portata fuori da quell'opacità; 1106: se nessun cliente di prova è senza bisogni, la scena mostra davvero VuotoClientePratiche.
- 34 · 692 e 693: in modalità cliente nessuna etichetta di momento, durata o consiglio; 1115-uso-sala-momenti-stretta: se l'etichetta verde «Consigliata per …» toglie troppo spazio a titolo e frase nelle schede piccole basse; 618 e 690 con le etichette nuove.
- 35 · 1121: se «Cerca in tutti i documenti» sotto la tile basta o serve anche accanto al campo; sul Mac, se le «Domande su questo documento» devono sollevarsi al passaggio come le pillole.
- 36 · Rigenerare 410-415, 616, 617, la scrivania di «Prisma istantaneo» e la pagina Scorciatoie; a 1440 e in 415-scrivania-apple-schermo-basso controllare che il dock con i quattro fili (circa 28 pt in più) e le icone ingrandite stia nella finestra (altrimenti Tema.Misura.Shell.divisoreGruppiMargine); su un Mac vero l'effetto genio di una finestra ridotta verso l'icona giusta.
- 37 · Rigenerare 85, 86 (chiara e scura), le pagine Vera, Promemoria e Archivio, la rubrica vuota e il suo piede senza «+ 30 clienti di prova»; guardare 1060-1063; controllare che le scene di Studio, Messaggi e Sala con «dati di prova» non cambino (e di nuovo dopo il lavoro 2).
- 38 · Rigenerare 252 e le scene con le etichette dei canali; guardare 1064-1068 chiare e scure (la pagina dei nomi deve stare in 640 con l'etichetta accanto al campo); su un Mac vero: che Invio nel campo del nome non faccia anche «Avanti» e che il fuoco perso salvi il nome cliccando fuori.
- 39 · Rigenerare 560-566 (nuovo ordine della pagina), 251 (riga che rimanda), le scene di Inquadra senza ponte e «Come funziona» della nota («Collega l'iPhone»); guardare 1069-1071 chiare e scure.
- Dopo tutti i controlli a occhio: aggiornare la pagina online delle anteprime (artifact EauRU1ohEGjHj4zvTomDvb).

### Lavori lasciati per dopo (poco valore, rischiosi o grandi)
- 34 · Prova «in modalità cliente nessuna indicazione della Sala» (basso/basso/S)
- 34 · Analisi 360 usa prioritaAree360 (un solo punto di calcolo) (basso/basso/S)
- 33 · Togliere i token inutilizzati dei chip di «Compila per» (basso/basso/S)
- 39 · Testi del ponte su iPhone e iPad che rimandano a «Impostazioni › Vera» (basso/basso/S)
- 39 · Prova: una nota rifiutata dal Mac («Nota a voce» spenta) resta nella coda (basso/basso/S)
- 37 · «Riapri ora» durante la dimostrazione (basso/basso/S)
- 32 · Riquadri del pannello del Territorio: sollevamento e anello al passaggio (basso/basso/S)
- 32 · Luci spente che si attenuano in 0,4 s invece che di colpo (basso/medio/M)

## Migliorie 40-51

### Decisioni
- 40 · Nome sotto i punti piccoli al passaggio (`.rNm2` del template): non aggiunto, perché il fumetto mostra già nome e distanza. Va bene così?
- 41/42/43/44/45/46/47/48 · Radar, prova del fuoco, Inquadra, Smontaggio (con i token delle note ancora usati dall'iPad), Aggiorna valori, simulatori, famiglie e passaparola di iPhone e iPad restano come prima fino al loro giro: va confermato quando farlo.
- 42 · Decisione 42.6: un documento conservato con il valore scritto ma senza voci né posizione collegata si riapre senza valore («Con la tua proposta» e il confronto restano «—»), perché il testo non si conserva. Va bene, o si conserva qualcosa in più?
- 44 · Nella scena 180 le righe da decidere sono 3, non 2: anche «Paolo Neri», che non è fra i clienti, ha la sua domanda. Va bene?
- 44 · Proposta 44.6, l'annullamento della registrazione dei valori dopo aver chiuso il pannello: oggi c'è solo il backup fatto prima di registrare. Va fatto?
- 45 · Aliquote da scegliere 23 | 33 | 43 (scaglioni IRPEF 2026) invece di «23 | 35 | 43» del template: da confermare.
- 45 · «Sono stime, non garanzie.» del piede dei simulatori e la capsula «Stime in uso» della miglioria 16: un testo solo condiviso, o restano due avvisi distinti?
- 46-a · Frasi senza percentile: con la quota si usa il nome («… ce l'ha, Giulia no.») invece di «lui no». Da approvare.
- 46 · Con la quota una voce è «sotto la metà» solo se più di metà delle famiglie ha la cosa e il cliente no, una scelta diversa da `sopra == false` della specifica. Inoltre le voci con un percentile vengono prima di quelle con la sola mediana, media o quota. Da confermare.
- 47 · Nota della tile del patrimonio: deve prevalere il probabile entro fine anno o «N senza stima»?
- 47 · Dati di prova: sette potenziali su otto sono fermi da più di 14 giorni. Si avvicinano le date per avere un quadro più vario?
- 47-c · Dopo «Chiama» su un potenziale, Prisma deve chiedere com'è andata? Oggi questa funzione non c'è.
- 48-b · Il testo del grazie nei tre toni (cordiale, formale con il lei, breve) va fatto vedere all'utente e approvato prima dell'unione. Va bene anche che la bozza nasca sempre cordiale, con il canale ricavato dal telefono?
- 49 · Il pulsante della campagna salta lo stato «Preparo…» perché l'avvio è sincrono: va bene così?
- 51 · Nel giro la borsa conta solo i fascicoli già nei Documenti, non quelli che la notte preparerebbe: va bene? E la vista del giro sull'iPhone (che cambierà la frase sotto il pulsante): quando farla?

### Controlli a occhio
- 40 · Istantanee 890, 895 e 897: la card «chi» occupa l'altezza, l'elenco lungo scorre dentro e nella finestra stretta si allunga nella pagina. Sul Mac: passare sulle righe accende il punto senza rifare la tela (il passaggio del puntatore non si simula in --prova-fluidita).
- 41 · Istantanee 590-598, soprattutto 598 (finestra stretta: la legenda può troncarsi) e 596 (quarto gruppo «Senza obiettivo»), più 599 (dettaglio). Sul Mac: riordino a gruppi e testate con 200 clienti durante il trascinamento del cursore.
- 43 · Istantanee 604, 605, 606, 608, 609, 841-849 e 1160-1163 (titolo, «Di chi è», righe in più, riga in fondo). Sul Mac: Esc con due significati (prima chiude la modifica, poi la scena) e Invio nel campo con il pulsante principale accanto.
- 42 · Istantanee 880-886, soprattutto 886 (finestra stretta) e la card delle voci con la colonna bassa, più 887-889. Screenshot sul Mac dell'accensione voce↔ellisse al passaggio (oggi cambia subito, senza animazione: decidere a occhio se serve).
- 44 · Istantanee 180-185: altezza dei riquadri dei dubbi e colonna «prima → dopo» con importi a sei cifre.
- 45 · Istantanee 1140-1143 e 441-444, più finestra bassa su un 13": altezze nuove (previdenza 560, investimenti 536, liquidità 496), frase a tre righe e riga delle ipotesi senza reddito (si riduce all'80% e poi si tronca). Guardare anche se la frase deve entrare a cascata o le basta comparire col contenuto.
- 46 · Istantanee 1144 e 1145. Sul Mac: l'attesa di 650 ms tra il ritorno alle quattro aree e l'apertura del dettaglio.
- 47 · Istantanee 1146, 1147 e 850-853. Sul Mac: il volo dopo «Passa a…» parte a dettaglio chiuso, con la molla di sempre.
- 48 · Istantanee 1148 e 1149. Sul Mac: ramo al 20%, entrata della card «Il ramo di» e ⌘-clic che apre il dossier.
- 49 · Istantanee 1150 e 1151. Sul Mac: il lampo «✓ pronto in Messaggi» riga dopo riga e «Mostra tutti» aperto, che le istantanee non mostrano.
- 50 · Istantanee 1152-1154 (e 12, 124, 132, 238) da rigenerare e pagina delle anteprime da aggiornare. Sul Mac: pillole tagliate con il testo grande o una finestra 13" bassa (righe stimate a 18 punti), ritardo del clic singolo dovuto al doppio clic, entrata della colonna, celle che non si rifanno al passaggio del puntatore (--prova-fluidita con i 30 clienti fittizi).
- 51 · Istantanee 1155-1157 (e 701-704, 707) da rigenerare e pagina delle anteprime da aggiornare. Screenshot del tocco sulla tappa e del pulsante «Manda all'iPhone» con «Prisma ovunque» acceso, controllando anche quando compare la «✓» se una sincronizzazione era già in corso.

### Lavori lasciati per dopo (poco valore, rischiosi o grandi)
- 41 · Passo di --prova-carico per i gruppi della prova del fuoco con 200 clienti (basso/basso/S)
- 51 · Il puntatore a mano sulle tappe toccabili (aiuto comune) (basso/basso/S)
- 51 · La data di mezzo sotto la manopola del suo anno (basso/basso/S)
- 47 · «Indietro» dal menu si annulla come «Passa a…» (basso/basso/S)
- 46 · «Apri l'area» e «Completa» raggiungibili da VoiceOver nelle card delle voci (basso/basso/S)
- 44 · Pulsante «Aggiorna valori» della barra di Posizioni nel tema Apple (basso/basso/S)
- 44 · Righe della griglia dei valori fermi nei caratteri del tema Apple (solo Mac) (basso/basso/S)
- 43 · La riga «Tipo» si corregge in due campi (tipologia e compagnia) (basso/medio/M)
- 43 · Variante piccola del pulsante per «Va bene» e «Cambia» (basso/basso/S)

## Migliorie 52-60

### Decisioni
- 60 · CLAUDE.md: aggiungere all'elenco di ciò che il backup comprende «da «Migliorie d'uso» le esperienze della Sala fatte con il cliente: data ed esperienza, mai il contenuto». Il campo esperienzeFatte è già nel file del cliente e nei backup; manca solo la riga, che decide l'utente.
- 60-a · Il riquadro «In Sala» c'è solo nella Panoramica del dossier sul Mac: va messa una riga anche nella cronologia degli incontri o nei Documenti (le alternative non fatte)?
- 60-b · Lettera e giornata con «✦ Aggiungi al Prisma di …» non segnano da sole l'esperienza come fatta: confermare che resti così.
- 58-e · Per la presa visione sul Mac basta un tratto fatto col trackpad o col mouse? E serve il tratto che si disegna da solo del template, che la specifica ha tolto?
- 58 · Il prospetto a tutto schermo dentro la vista del cliente: va trasformato in un capitolo della vista come nel template (lavoro grande, con rischio alto, che rende di nuovo raggiungibile l'etichetta del luogo), o si accetta com'è?
- 58 · Il menu del luogo è disegnato (come quello dell'avatar) e non è un menu nativo del Mac: confermare.
- 56 · Su iPhone e iPad la palestra tiene la regola di difficoltà di prima: niente `migliore` in Facile e niente insistenza in Difficile (DifficoltaPalestra.regola dentro #if os(macOS)). Va estesa anche lì?
- 59/56 · Le migliorie 53-56 sono «solo sul Mac» (iPhone e iPad tengono titoli, track record e quiz di prima): portarle anche su iPhone e iPad?
- 53 · A dicembre «Il più indietro» dice sempre «entro fine anno» (i mesi alla fine sono arrotondati per eccesso, TestiStudio.inMesi): va bene così o serve «in N giorni»?
- 54 · «Riproponi» non c'è nel dettaglio della card (il template non lo chiede; VoiceOver lo trova fra le azioni): va aggiunto?
- 55 · Il bilancio del quiz entra senza la cascata delle righe (il template non la chiede): va bene così?

### Controlli a occhio
- 52 · Istantanea 1090: altezza del filo rispetto al template (riga del carattere × 1,2 più il padding, meno 12), la pillola che scivola sopra il filo, la finestra di Studio al minimo con la riga in testa più larga.
- 53 · Istantanee 570 e 1091: la card degli obiettivi (alta 300) tiene la legenda con gli avvisi e la frase di due righe senza tagliare il fondo (se non ci sta, anelli più piccoli o frase su una riga); luceSopra 0,06 in chiaro e in scuro; le domande più lunghe alla larghezza minima della card accanto a «dati di prova»; rigenerare 570, 571, 572 e 574.
- 54 · Istantanee 1092, 520, 524 e 525: i quattro chip accanto al titolo lungo alla larghezza minima della finestra, «Riproponi» dentro i 132.
- 55 · Istantanee 1093: il piede del bilancio («Ripassa il punto debole», «Ricomincia», «Punto debole: …») su una riga alla larghezza minima della card; se va a capo, il punto debole va sopra i pulsanti. Rigenerare 530, 531 e 532.
- 56 · Istantanee 720-722, 726 e 1094: se «Cambia» (pulsante .apple 7×14 dentro .menuStyle(.button)) è troppo grande accanto al nome, serve una variante piccola di StilePulsanteApple. Con un Qwen vero (qwen3.5:4b) controllare che in Facile `migliore` arrivi e che la risposta non si allunghi troppo.
- 57 · Rigenerare 780, 781, 782 (con «almeno … km» nella tessera), 785 e 788 in colonna (la tessera del pacchetto non deve tagliarsi), e 1095; il passaggio sulle colonne dei mesi chiede uno screenshot.
- 58 · Generare 680-683: la posizione del menu sotto l'etichetta del luogo (rientroMenu), la riga ConfermaCifreLuogo sotto la barra, la scheda della presa visione. Rigenerare 470, 471, 691, 620-678, 633-635 e 695 senza «▣ Mostra sul tavolo» né «▶︎ Presenta».
- 58 · Su un iPad vero: le immagini dei capitoli sono fisse a 1280×800 e un capitolo lungo (il quadro con testo «Grande», molte posizioni) si taglia in basso; da qui si decide se servono più pagine. Per il Prisma del cliente sull'iPad (58-f): dal codice l'immagine mandata usa ContenutoPalco(inSala: true), cioè solo il telefono senza la tessera della password, ma va confermato a occhio che la password non compaia.
- 58 · A mano sul Mac: il prospetto a tutto schermo dentro la vista del cliente copre la barra, quindi l'etichetta del luogo non si raggiunge finché la presentazione è aperta. Controllare che la pagina segua sull'iPad.
- 59 · Rigenerare 684, 685 e 691; controllare che 693-sala-modo-cliente non mostri «Cosa dire»; 681 con il cliente sull'iPad (i pulsanti del consulente sono visibili, consulenteVede è già esteso). L'entrata a molla del copione chiede uno screenshot. Con il lavoro 4 (ViewThatFits), guardare 618-app-nuove-sala e una scena stretta del palco.
- 60 · Generare 686-688: «✓ Fatta oggi» sulla scheda grande non copre il saluto, la testata con «Prossima: … ›» non taglia il nome alla larghezza minima. Rigenerare 690 e 691 (ora con «Segna come fatta»).
- Per tutte (52-60): aggiornare la pagina delle anteprime online dopo le istantanee generate sul Mac.

### Lavori lasciati per dopo (poco valore, rischiosi o grandi)
- 58 · Sostituire l'istantanea 694-sala-presenta (basso/basso/S)
- 58 · Il puntino del collegamento nel menu del luogo (basso/basso/S)
- 53/54/60 · Casi nuovi in --prova-fluidita (basso/basso/S)
- 58 · Prove che mancano su modalità cliente e realtà (basso/basso/S)
- 52 · Un segmentato con il filo nella vetrina (basso/basso/S)
- 56 · `migliore` negli esempi della palestra (basso/basso/S)

## Migliorie 61-70

### Decisioni
- 61: tetto unico di 40 risultati (taglierebbe gruppi interi come la Biblioteca) o le 5 righe per gruppo di oggi?
- 61: il velo sfocato del template va contro la regola della fluidità «niente sfocature» (vale per entrate, velo del dettaglio e uscita dal blocco): si fa o resta senza sfocatura?
- 62: il collegamento mancante, quando c'è un suggerimento, deve contare come dubbio e fermare «Fatto»?
- 62: «Aggiorna il valore» come differenza «Valore» del passo 3 o resta nel menu «⋯»? «Vedi chi» del nuovo KID come riga propria o dentro «Apri il confronto completo»?
- 63: salita di 8 punti con dissolvenza al cambio di scheda: con il ritmo 0,6 della fluidità serve davvero o basta la cascata?
- 64: prospetto PDF con una strada sola (scheda, ipotesi o conto): un caso nuovo di SceltaProspetto o il confronto con il conto?
- 64: il conto rende 0% (decisione 64-b) o un tasso scelto in Impostazioni › Analisi?
- 64: cambiando cliente e tornando, si ritrovano strade e ipotesi lasciate (in memoria) o si riparte da capo?
- 64: la capsula «Stime in uso · N dati da completare» (miglioria 16) deve entrare in Simula e confronta? Serve un presentatore di dettaglio nella vista
- 65: le note di Giulia e Marco nei dati di prova restano fissate (in evidenza) o si parte da «Da ricordare» come nel template? Aggiungere le note di partenza del template ai dati di prova?
- 66: la scheda della parola è ancorata al paragrafo, non alla parola, e manca il colore al passaggio del mouse (decisione 66.6, limite di SwiftUI su macOS 14): va bene così?
- 68: le parole sotto ✕ e ✓ spariscono con la pila senza la dissolvenza di 0,4 s; il tremolio dell'esame OCF resta a sé: va bene così?
- 69-c: i nomi lunghi delle strade del TFR anche in prospetto, report e iPhone/iPad, o solo sullo schermo del Mac? Da decidere guardando 205-206
- 69-e: il dipendente pubblico (TFS) entra nel TFR o resta fuori?
- 69: il nome del fondo non si vede più sullo schermo del Mac (resta nei PDF): va bene?
- Migliorie 62-65 e 69-70: quando portarle su iPhone e iPad (lettore, scheda prodotto, Simula e confronta, note, TFR)

### Controlli a occhio
- 61: rigenerare e guardare 53 (e scura), 54, 103, 104, 154, 879 e 1300-1303; in 1303 la prima riga deve essere la parola «Interesse composto»; aggiornare la pagina delle anteprime
- 61: --prova-carico e --prova-fluidita sul Mac, tempi di apertura della ricerca con i 30 clienti
- 62: rigenerare 1304-1307 e le scene di prima della scheda Documenti (26, 68, 161-166, 190-194, 237, 281, 290, 903): controllare che dicano ancora quello che il nome promette (163 testo dal menu, 165 confronto d'identità nel passo 3, 191 e 194 col confronto completo chiuso); se serve, aprire il confronto completo in RichiestaIstantaneaLettore o togliere documentoSelezionato dalle scene che devono mostrare solo l'elenco
- 63: guardare 23, 32, 4, 192, 878, 1400-1402 chiare e scure: la griglia delle cifre (costi più due tessere da 170) deve stare a 1100 e il piede non deve tagliare i pulsanti
- 64: guardare 14, 15, 16, 233, 239 e 1403-1404: la finestra stretta (ViewThatFits) e la lunghezza della fila dei pulsanti
- 65: guardare 60, 61, 64 (Note senza finestra), le Panoramiche di Giulia e Marco (ora con la nota fissata) e 1405-1407
- 66: la tinta della parola collegata (resta del colore del paragrafo o diventa azzurra?), 227 e 228 con la frase nuova, il filo delle etichette in Prodotti, Rubrica e 106-posizioni-multiramo, 1308-1309
- 67: 57-spazio-analisi con Posizioni al 42%, si legge? (decisione 67.6); 1310-1312
- 68: 771 (due righe in arancione) e l'altezza della carta finale di 763 con la frase delle rimandate; 1313-1315
- 69: guardare 204, 207, 208, 1408-1410 chiare e scure
- 70: guardare 81, 81-scuro, 82, 460, 1411, 1412: l'indice sulla copertina, le misure e se 8 voci entrano davvero; la card di Prospetti dopo la chiusura della scheda aperta dall'Agenda
- 70: su M1, sentire se la prima apertura della scheda del fascicolo è lenta (impagina tutti i report per contare le pagine)
- Aggiornare la pagina online delle anteprime con tutte le istantanee nuove 1300-1415

### Lavori lasciati per dopo (poco valore, rischiosi o grandi)
- 68.3 punto 3: Inquadra e Aggiorna valori con i componenti comuni delle conferme (medio/medio/L)
- 69-f: lo spunto vero di Vera per il TFR (medio/medio/L)
- 66: le parole spiegate nelle altre viste (medio/medio/L)
- 61: velo sfocato ed entrata del template (basso/medio/S)
- 61: avatar e tessere 30 con raggio 10 (basso/basso/S)
- 64/69: barre comuni e cifra della frase che si conta (basso/medio/M)
- 64: nomi vecchi «Simulatore» e «Confronto» nei collegamenti del Mac (basso/basso/S)
- 70: ⌥↑/⌥↓ sulla riga a fuoco del fascicolo (basso/basso/S)
- 70: istantanea 1413 «un solo report» con dati costruiti (basso/basso/S)
- 62: menu e collegamenti del lettore in un tipo comune (basso/basso/M)
- 62: altri collegamenti esterni che riaprono l'ultimo documento (basso/basso/S)
