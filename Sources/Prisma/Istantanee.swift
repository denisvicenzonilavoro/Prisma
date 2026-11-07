#if os(macOS)
import AppKit
#endif
import SwiftUI

/// Modalità istantanea (`Prisma --istantanee <cartella>`): disegna le schermate principali
/// in PNG senza aprire finestre e senza toccare l'archivio. La usa il workflow di build
/// per pubblicare le anteprime a ogni modifica.
@MainActor
enum Istantanee {
    static let dimensione = CGSize(width: 1440, height: 900)
    /// Schermo più basso (MacBook con il dock di macOS e la barra dei menu): le scene che finiscono
    /// con "-schermo-basso" si disegnano a questa misura.
    static let dimensioneBassa = CGSize(width: 1280, height: 760)

    static let scene: [(nome: String, prepara: (StatoShell) -> Void)] = [
        ("1-scrivania", { _ in }),
        ("2-posizioni", { $0.apri(.posizioni) }),
        ("3-impostazioni-archivio", { s in
            s.apri(.impostazioni)
            s.schedaImpostazioni = .archivio
        }),
        ("4-finestra-non-ingrandita", { s in
            s.apri(.prodotti)
            s.alternaIngrandimento(.prodotti)
        }),
        ("5-clienti-panoramica", { $0.apri(.clienti) }),
        ("6-clienti-famiglia", { s in
            s.clienteAttivoId = "marco"
            s.schedaCliente = .famiglia
            s.apri(.clienti)
        }),
        ("7-clienti-profilo", { s in
            s.clienteAttivoId = "sofia"
            s.schedaCliente = .profilo
            s.apri(.clienti)
        }),
        ("8-posizioni-dettaglio", { s in
            s.posizioneInDettaglio = "pos-giulia-etf-azionario-globale"
            s.apri(.posizioni)
        }),
        ("9-posizioni-marco", { s in
            s.clienteAttivoId = "marco"
            s.apri(.posizioni)
        }),
        ("10-posizioni-copertura", { s in
            s.clienteAttivoId = "marco"
            s.posizioneInDettaglio = "pos-marco-infortuni-famiglia"
            s.apri(.posizioni)
        }),
        ("11-agenda", { s in
            // Il giorno con il dettaglio dell'appuntamento (la vista predefinita è il mese; nel tema Apple la
            // settimana non ha più la colonna del dettaglio: la traccia dell'impegno è la scena 452)
            s.vistaAgenda = .giorno
            s.appuntamentoSelezionato = "event-marco"
            s.apri(.agenda)
        }),
        // L'Agenda a vista mensile con Attività accorpata: la griglia, le pillole, la giornata di oggi a destra
        ("11a-agenda-mese", { s in
            Istantanee.attivitaRimastaIndietro(s)
            s.apri(.agenda)
        }),
        ("11b-agenda-giorno", { s in
            // Il giorno: appuntamenti e cose da fare, con il dettaglio dell'attività
            Istantanee.attivitaRimastaIndietro(s)
            s.vistaAgenda = .giorno
            s.scegliAttivitaInAgenda("task-casa")
            s.apri(.agenda)
        }),
        ("11c-agenda-mese-stretta", { s in
            s.apri(.agenda)
            s.alternaIngrandimento(.agenda)
            s.ridimensiona(.agenda, dimensione: CGSize(width: 860, height: 640))
        }),
        ("12-agenda-mese-scadenza", { s in
            if let d = s.posizioni.first(where: { $0.id == "pos-marco-infortuni-famiglia" })?.scadenza {
                s.giornoAgenda = Calendar.current.startOfDay(for: d)
            }
            s.vistaAgenda = .mese
            s.apri(.agenda)
        }),
        ("13-agenda-attivita", { s in
            // Attività è accorpata nell'Agenda: l'attività si apre nel mese, nel giorno della scadenza
            s.mostraAttivitaInAgenda("task-casa")
        }),
        // Gli strumenti di Analisi 360 (le ex app Simulazioni e Confronti): rail di Analisi 360, testata compatta
        ("14-analisi360-simulatore", { s in
            if let p = s.posizioni.first(where: { $0.id == "pos-giulia-etf-azionario-globale" }) { s.simula(p) }
        }),
        ("15-analisi360-scenari", { s in
            s.scegliStrumentoAnalisi(.scenari)
            s.apri(.analisi360)
        }),
        ("16-analisi360-confronto", { s in
            s.clienteAttivoId = "marco"
            s.scegliStrumentoAnalisi(.confronto)
            s.apri(.analisi360)
        }),
        ("17-analisi360", { $0.apri(.analisi360) }),
        ("20-clienti-bisogni", { s in
            s.clienteAttivoId = "marco"
            s.schedaCliente = .bisogni
            s.apri(.clienti)
        }),
        ("21-incontri-ascolto", { s in
            s.clienteAttivoId = "giulia"
            s.incontroAperto = "incontro-giulia-analisi"
            s.schedaIncontro = .ascolto
            // Le tre domande scritte e gli appunti (il copilota ha le sue scene, 580-589)
            s.copilota.modo = .appunti
            s.apri(.incontri)
        }),
        ("22-incontri-passi", { s in
            s.clienteAttivoId = "giulia"
            if var i = s.incontro("incontro-giulia-analisi") {
                // Si riapre l'incontro di prova per mostrare le proposte ricavate dagli appunti
                i.stato = .preparazione
                s.salvaIncontro(i)
                s.estraiProposte(i)
            }
            s.incontroAperto = "incontro-giulia-analisi"
            s.schedaIncontro = .passi
            s.apri(.incontri)
        }),
        ("23-prodotti", { s in
            s.prodottoSelezionato = "prodotto-previdenza-pip"
            s.apri(.prodotti)
        }),
        ("24-clienti-obiettivi", { s in
            s.clienteAttivoId = "giulia"
            s.obiettivoSelezionato = "obiettivo-giulia-casa"
            s.apri(.obiettivi)
        }),
        // Clienti · Documenti e Obiettivi dentro la scheda del cliente (280–283)
        ("280-clienti-documenti-gruppi", { s in
            // Giulia: personali, dei prodotti (una posizione per gruppo, con il canale), da Prisma, da collegare;
            // l'elenco aperto con il suo pulsante (con un documento aperto resta stretto da solo)
            Istantanee.documentiRicchi(s)
            s.documentoSelezionato = "doc-giulia-estratto"
            s.vistaDocumenti.elenco = true
            s.apri(.documenti)
        }),
        ("281-clienti-documenti-da-leggere", { s in
            // La tessera «Da leggere» fa da filtro
            Istantanee.documentiRicchi(s)
            s.vistaDocumenti.raccolta = .daLeggere
            s.apri(.documenti)
        }),
        ("282-clienti-obiettivi-quadro", { s in
            // Giulia con tre obiettivi: l'anello della quota coperta, le tessere e la pensione scelta
            s.clienteAttivoId = "giulia"
            var pensione = Obiettivo(clienteId: "giulia", titolo: "Pensione a 62 anni", area: .pensione, importo: 120_000,
                                     scadenza: Calendar.current.date(byAdding: .year, value: 22, to: Date()) ?? Date())
            pensione.id = "obiettivo-demo-pensione"
            pensione.posizioniCollegate = ["pos-giulia-etf-azionario-globale"]
            pensione.rendimento = 3
            s.dati.obiettivi.append(pensione)
            s.obiettivoSelezionato = "obiettivo-demo-pensione"
            s.apri(.obiettivi)
        }),
        ("283-clienti-obiettivi-stretta", { s in
            s.clienteAttivoId = "giulia"
            s.obiettivoSelezionato = "obiettivo-giulia-casa"
            s.apri(.obiettivi)
            s.alternaIngrandimento(.clienti)
            s.ridimensiona(.clienti, dimensione: CGSize(width: 820, height: 680))
        }),
        ("27-prospetto-proposta", { s in
            s.clienteAttivoId = "giulia"
            s.apriProspetto(.posizione("pos-giulia-piano-previdenziale-integrativo"))
        }),
        ("28-resoconto-prospetto", { s in
            s.clienteAttivoId = "giulia"
            s.apriProspetto(.resoconto(report: false))
        }),
        ("33-resoconto-report", { s in
            s.clienteAttivoId = "giulia"
            s.apriProspetto(.resoconto(report: true))
        }),
        ("29-prospetto-confronto", { s in
            s.clienteAttivoId = "marco"
            if let c = s.confrontoPredefinito() { s.apriProspetto(c) }
        }),
        ("32-prodotti-condizioni", { s in
            s.prodottoSelezionato = "prodotto-orizzonte-valore"
            s.apri(.prodotti)
        }),
        ("30-valutazione-prospetto", { s in
            s.clienteAttivoId = "marco"
            s.apriProspetto(.valutazione("val-marco-orizzonte", report: false))
        }),
        ("31-valutazione-report", { s in
            s.clienteAttivoId = "marco"
            s.apriProspetto(.valutazione("val-marco-orizzonte", report: true))
        }),
        ("34-sostituzione-prospetto", { s in
            s.clienteAttivoId = "sofia"
            s.apriProspetto(.sostituzione("", "", report: false))
        }),
        ("35-sostituzione-report", { s in
            s.clienteAttivoId = "sofia"
            s.apriProspetto(.sostituzione("", "", report: true))
        }),
        ("36-previdenza-prospetto", { s in
            s.clienteAttivoId = "marco"
            s.apriProspetto(.previdenza(report: false))
        }),
        ("37-previdenza-report", { s in
            s.clienteAttivoId = "giulia"
            s.apriProspetto(.previdenza(report: true))
        }),
        ("38-protezione-prospetto", { s in
            s.clienteAttivoId = "marco"
            s.apriProspetto(.protezione(report: false))
        }),
        ("39-protezione-report", { s in
            s.clienteAttivoId = "marco"
            s.apriProspetto(.protezione(report: true))
        }),
        ("40-obiettivo-prospetto", { s in
            s.clienteAttivoId = "giulia"
            s.apriProspetto(.obiettivo("obiettivo-giulia-casa", report: false))
        }),
        ("41-obiettivo-report", { s in
            s.clienteAttivoId = "giulia"
            s.apriProspetto(.obiettivo("obiettivo-giulia-casa", report: true))
        }),
        ("42-liquidita-prospetto", { s in
            s.clienteAttivoId = "sofia"
            s.apriProspetto(.liquidita(report: false))
        }),
        ("43-liquidita-report", { s in
            s.clienteAttivoId = "sofia"
            s.apriProspetto(.liquidita(report: true))
        }),
        ("44-checkup-prospetto", { s in
            s.clienteAttivoId = "andrea"
            s.apriProspetto(.checkUp(report: false))
        }),
        ("45-checkup-report", { s in
            s.clienteAttivoId = "andrea"
            s.apriProspetto(.checkUp(report: true))
        }),
        ("25-clienti-documenti-kid", { s in
            s.clienteAttivoId = "giulia"
            s.documentoSelezionato = "doc-giulia-kid"
            s.apri(.documenti)
        }),
        ("71-posizioni-resistenza", { s in
            // Marco, profilo moderato: la prova di resistenza sotto la ripartizione
            s.clienteAttivoId = "marco"
            s.apri(.posizioni)
        }),
        ("72-vera-resistenza", { s in
            s.clienteAttivoId = "marco"
            s.rispostePreparate = true
            s.chiediVera(SpuntoVera.resistenza.domanda, spunto: .resistenza)
            s.apri(.vera)
        }),
        ("73-resistenza-report", { s in
            s.clienteAttivoId = "marco"
            s.apriProspetto(.resistenza(report: true))
        }),
        ("74-posizioni-costi", { s in
            // Giulia: il dossier scorre fino al pannello dei costi
            s.clienteAttivoId = "giulia"
            s.apri(.posizioni)
            s.ancoraPosizioni = "costi"
        }),
        ("75-costi-report", { s in
            s.clienteAttivoId = "marco"
            s.apriProspetto(.costi(report: true))
        }),
        ("76-posizioni-successione", { s in
            // Giulia: convivente senza tutele e polizza agli «eredi legittimi»
            s.clienteAttivoId = "giulia"
            s.apri(.posizioni)
            s.ancoraPosizioni = "successione"
        }),
        ("77-successione-report", { s in
            s.clienteAttivoId = "marco"
            s.apriProspetto(.successione(report: true))
        }),
        ("78-portafoglio-da-sistemare", { s in
            s.portafoglio = true
            s.apri(.posizioni)
            s.ancoraPosizioni = "attenzioni"
        }),
        ("79-posizioni-patrimonio", { s in
            // Marco: il patrimonio nel tempo, com'è oggi e con la proposta aperta
            s.clienteAttivoId = "marco"
            s.apri(.posizioni)
            s.ancoraPosizioni = "patrimonio"
        }),
        ("80-patrimonio-report", { s in
            s.clienteAttivoId = "marco"
            s.apriProspetto(.patrimonio(report: true))
        }),
        ("81-fascicolo", { s in
            s.clienteAttivoId = "marco"
            s.apriProspetto(.fascicolo)
        }),
        ("82-agenda-fascicolo", { s in
            // Dall'appuntamento di Marco: il fascicolo con i report adatti alla revisione
            if let a = s.appuntamenti.first(where: { $0.clienteId == "marco" && $0.stato == .pianificato }) { s.preparaFascicolo(per: a) }
        }),
        ("83-presentazione", { s in
            // Il patrimonio di Marco mostrato all'incontro: seconda pagina, a tutta finestra
            s.clienteAttivoId = "marco"
            if let d = s.documentoProspetto(.patrimonio(report: true)) {
                s.presenta(d)
                s.paginaSeguente()
            }
        }),
        ("84-vera-ascolta", { s in
            // Una conversazione a voce: Vera ha risposto e ora ascolta la frase successiva
            s.rispostePreparate = true
            s.clienteAttivoId = "marco"
            s.chiediVera(SpuntoVera.resistenza.domanda, spunto: .resistenza)
            s.conversazioneAVoce = true
            s.voceIstantanea = StatoVoce(ascolta: true, trascritto: "Va bene, e quanto pesano i costi del suo piano pensione", livello: 0.6)
            s.apri(.vera)
        }),
        ("86-vera-comandi", { s in
            // Vera fa le cose: un appuntamento, un promemoria e l'agenda di domani, dalla conversazione
            s.rispostePreparate = true
            s.clienteAttivoId = "marco"
            s.chiediVera("Fissa una telefonata con Marco domani alle 15")
            s.chiediVera("Ricordami di mandargli il KID del PIP venerdì")
            s.chiediVera("Cosa ho domani?")
            s.apri(.vera)
        }),
        ("87-clienti-fittizi", { s in
            // I 35 clienti di prova completi: rubrica piena e un cliente inventato aperto
            s.dati = ClientiFittizi.completi()
            s.clienteAttivoId = ClientiFittizi.prefisso + "ferraro"
            s.apri(.clienti)
        }),
        ("88-portafoglio-fittizi", { s in
            s.dati = ClientiFittizi.completi()
            s.portafoglio = true
            s.apri(.posizioni)
        }),
        ("85-impostazioni-strumenti", { s in
            // Strumenti, in fondo alla barra laterale: dati di prova, confronto dei modelli, prove
            s.schedaImpostazioni = .strumenti
            s.apri(.impostazioni)
        }),
        ("70-modo-cliente", { s in
            // Lo schermo girato verso Marco: solo il suo dossier, niente degli altri clienti
            s.clienteAttivoId = "marco"
            s.entraModoCliente()
            s.apri(.posizioni)
        }),
        ("69-riesame-prospetto", { s in
            s.clienteAttivoId = "giulia"
            s.apriProspetto(.riesame)
        }),
        ("68-clienti-documenti-estratto", { s in
            // Estratto conto confermato: il valore pronto per lo storico del piano di risparmio
            s.clienteAttivoId = "giulia"
            s.documentoSelezionato = "doc-giulia-estratto"
            if let d = s.documento("doc-giulia-estratto") { for c in d.campi { s.confermaCampo(d.id, c.chiave, true) } }
            s.apri(.documenti)
        }),
        ("26-clienti-documenti-polizza", { s in
            s.clienteAttivoId = "marco"
            s.documentoSelezionato = "doc-marco-polizza"
            s.apri(.documenti)
        }),
        ("19-vera", { s in
            s.rispostePreparate = true
            s.clienteAttivoId = "giulia"
            s.chiediVera(SpuntoVera.incontro.domanda, spunto: .incontro)
            s.apri(.vera)
        }),
        // La risposta di Vera mentre arriva (streaming): la bolla cresce con il testo
        ("240-vera-risposta-in-arrivo", { s in
            s.clienteAttivoId = "giulia"
            s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "Cos'è l'inflazione, in parole semplici?"), cliente: "giulia", parla: false)
            s.veraInCorso = true
            let g = s.flussoVera.inizia(SceltaVera(modalita: .conversazione, pensa: false), motore: "Qwen sul Mac")
            s.flussoVera.aggiorna(ParzialeVera(testo: "L'inflazione è l'aumento generale dei prezzi nel tempo: con gli stessi soldi, domani compri un po' meno di oggi. Per i risparmi vuol dire che", pensa: false), generazione: g)
            s.apri(.vera)
        }),
        ("48-report-commento", { s in
            s.rispostePreparate = true
            s.clienteAttivoId = "giulia"
            s.prospetto = .checkUp(report: true)
            s.scriviCommentoConVera(.checkUp(report: true))
            s.apri(.presentazioni)
        }),
        ("50-vera-proposte", { s in
            s.rispostePreparate = true
            s.clienteAttivoId = "giulia"
            s.chiediVera(SpuntoVera.proposte.domanda, spunto: .proposte)
            s.apri(.vera)
        }),
        ("49-vera-documento", { s in
            s.rispostePreparate = true
            s.spiegaDocumentoConVera("doc-marco-polizza")
        }),
        ("46-vera-pensione", { s in
            s.rispostePreparate = true
            s.clienteAttivoId = "marco"
            s.prospetto = .previdenza(report: false)
            s.chiediVeraDelDocumento(.previdenza(report: false))
        }),
        ("47-vera-checkup", { s in
            s.rispostePreparate = true
            s.clienteAttivoId = "giulia"
            s.chiediVera(SpuntoVera.checkUp.domanda, spunto: .checkUp)
            s.apri(.vera)
        }),
        ("53-ricerca", { s in
            s.testoRicerca = "marco"
            s.cercaOvunque()
        }),
        ("54-ricerca-documento", { s in
            // Il pannello ⌘K sopra un'app aperta (non sulla scrivania vuota)
            s.clienteAttivoId = "marco"
            s.apri(.clienti)
            s.testoRicerca = "scopo investimento"
            s.cercaOvunque()
        }),
        ("55-spazio-incontro", { s in
            s.area = ShellView.area(per: dimensione, dockNascosto: false)
            s.clienteAttivoId = "marco"
            s.apriSpazio(SpazioLavoro.predefiniti[0])
        }),
        ("57-spazio-analisi", { s in
            s.area = ShellView.area(per: dimensione, dockNascosto: false)
            s.clienteAttivoId = "marco"
            s.apriSpazio(SpazioLavoro.predefiniti[1])
        }),
        ("58-spazio-giornata", { s in
            s.area = ShellView.area(per: dimensione, dockNascosto: false)
            s.apriSpazio(SpazioLavoro.predefiniti[2])
        }),
        ("56-spazi", { s in
            s.area = ShellView.area(per: dimensione, dockNascosto: false)
            s.dati.spazi = [SpazioLavoro(nome: "Revisione annuale", finestre: [.destra(.documenti), .sinistra(.posizioni)])]
            s.apri(.agenda)
            s.pannelloSpazi = true
        }),
        ("60-note", { s in
            s.scegliNota("nota-giulia")
            s.apri(.note)
        }),
        ("61-clienti-note", { s in
            s.clienteAttivoId = "marco"
            s.schedaCliente = .note
            s.apri(.clienti)
        }),
        ("62-notifiche", { s in
            if let i = s.dati.posizioni.firstIndex(where: { $0.stato == .inEssere && $0.canale == .alleanza }) {
                s.dati.posizioni[i].scadenza = Calendar.current.date(byAdding: .day, value: 12, to: Calendar.current.startOfDay(for: Date()))
            }
            s.alternaNotifiche()
        }),
        ("63-benvenuto", { s in
            // Come dopo il primo avvio (introduzione già vista), con una finestra aperta sotto il blocco
            s.dati.impostazioni.introduzioneVista = true
            s.apri(.clienti)
            s.blocca()
        }),
        ("64-app-aperte", { s in
            // Ogni scheda con il suo contesto: Agenda filtrata su Marco, Note su Sofia, Posizioni sul
            // portafoglio, Prodotti senza cliente, Clienti sul cliente attivo
            s.filtroClienteAgenda = "marco"
            s.filtroClienteNote = "sofia"
            s.apri(.agenda)
            s.apri(.note)
            s.portafoglio = true
            s.apri(.posizioni)
            s.apri(.prodotti)
            s.apri(.clienti)
            s.riduci(.agenda)
            s.pannelloAppAperte = true
        }),
        ("65-portafoglio", { s in
            s.portafoglio = true
            s.apri(.posizioni)
        }),
        ("66-prospetto-portafoglio", { s in
            s.apriProspetto(.portafoglio)
        }),
        ("67-vera-portafoglio", { s in
            s.rispostePreparate = true
            s.veraPortafoglio = true
            s.chiediVeraPortafoglio(SpuntoPortafoglio.quadro.domanda, spunto: .quadro)
            s.chiediVeraPortafoglio(SpuntoPortafoglio.settimana.domanda, spunto: .settimana)
            s.apri(.vera)
        }),
        ("51-scrivania-schermo-basso", { _ in }),
        ("52-vera-schermo-basso", { s in
            s.clienteAttivoId = "giulia"
            s.apri(.vera)
        }),
        ("18-analisi360-protezione", { s in
            s.clienteAttivoId = "marco"
            s.areaAnalisi = .protezione
            s.apri(.analisi360)
        }),
        // Le impostazioni di aspetto (chiaro, scuro, sfondo, pioggia)
        ("90-impostazioni-aspetto", { s in
            s.apri(.impostazioni)
            s.schedaImpostazioni = .aspetto
        }),
        // Le analisi nuove dei motori: Posizioni (dettaglio, crisi, coerenza) e le schermate degli altri temi
        ("91-posizioni-rendimento-versamenti", { s in
            // Giulia, ETF: il rendimento dei suoi versamenti accanto a quello del prodotto
            s.clienteAttivoId = "giulia"
            s.posizioneInDettaglio = "pos-giulia-etf-azionario-globale"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-andamento"
        }),
        ("92-posizioni-gestione-separata", { s in
            // Giulia, piano rivalutabile: gestione separata, costi come nel KID, quota azionaria
            s.clienteAttivoId = "giulia"
            s.posizioneInDettaglio = "pos-giulia-piano-di-risparmio-rivalutabile"
            s.apri(.posizioni)
        }),
        ("93-posizioni-riscatto-penali", { s in
            // Andrea, proposta con penali e 12 mesi di blocco: il riscatto anno per anno
            s.clienteAttivoId = "andrea"
            s.posizioneInDettaglio = "pos-andrea-piano-di-risparmio-rivalutabile"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-riscatto"
        }),
        ("94-posizioni-kid-proposta", { s in
            // Sofia, proposta obbligazionaria: costi calcolati come nel KID contro il RIY dichiarato
            s.clienteAttivoId = "sofia"
            s.posizioneInDettaglio = "pos-sofia-obbligazionario-a-scadenza-2030"
            s.apri(.posizioni)
        }),
        ("95-posizioni-crisi", { s in
            // Giulia: le crisi del 2008, 2020 e 2022 nella prova di resistenza
            s.clienteAttivoId = "giulia"
            s.apri(.posizioni)
            s.ancoraPosizioni = "resistenza"
        }),
        ("96-posizioni-coerenza", { s in
            // Marco: tutto su Alleanza, la concentrazione nel pannello della coerenza con il profilo
            s.clienteAttivoId = "marco"
            s.apri(.posizioni)
            s.ancoraPosizioni = "coerenza"
        }),
        ("97-posizioni-coerenza-giulia", { s in
            // Giulia: le crisi vere oltre il profilo e le proposte aperte
            s.clienteAttivoId = "giulia"
            s.apri(.posizioni)
            s.ancoraPosizioni = "coerenza"
        }),
        ("98-clienti-obiettivi-probabilita", { s in
            // Marco, gli studi di Anna: la probabilità di arrivarci (scenari con le probabilità). Solo per la scena
            // la polizza multiramo lavora per l'obiettivo: senza una posizione che oscilla non ci sono probabilità
            s.clienteAttivoId = "marco"
            if let i = s.dati.obiettivi.firstIndex(where: { $0.id == "obiettivo-marco-studi" }) {
                s.dati.obiettivi[i].posizioniCollegate = ["pos-marco-polizza-multiramo"]
            }
            s.obiettivoSelezionato = "obiettivo-marco-studi"
            s.apri(.obiettivi)
        }),
        ("99-analisi360-pensione", { s in
            // Marco: la pensione pubblica stimata con il contributivo
            s.clienteAttivoId = "marco"
            s.areaAnalisi = .previdenza
            s.apri(.analisi360)
        }),
        ("100-analisi360-protezione-persone", { s in
            // Giulia e Luca: la protezione persona per persona
            s.clienteAttivoId = "giulia"
            s.areaAnalisi = .protezione
            s.apri(.analisi360)
        }),
        ("101-resistenza-prospetto", { s in
            // Giulia: il prospetto della prova di resistenza, seconda pagina (le crisi del passato), a tutta finestra
            s.clienteAttivoId = "giulia"
            if let d = s.documentoProspetto(.resistenza(report: false)) {
                s.presenta(d)
                s.paginaSeguente()
            }
        }),
        ("102-costi-prospetto", { s in
            // Giulia: il prospetto dei costi, seconda pagina (l'incidenza come nel KID), a tutta finestra
            s.clienteAttivoId = "giulia"
            if let d = s.documentoProspetto(.costi(report: false)) {
                s.presenta(d)
                s.paginaSeguente()
            }
        }),
        ("103-ricerca-filtri", { s in
            // Ricerca per criterio: filtri riconosciuti, totali per canale e anteprima della prima posizione
            s.testoRicerca = "sri>3 canale:alleanza"
            s.cercaOvunque()
        }),
        ("104-ricerca-salvate", { s in
            // Pannello vuoto: le ricerche salvate e i filtri da provare
            s.dati.impostazioni.ricercheSalvate = [RicercaSalvata(nome: "Proposte aperte", testo: "stato:proposta"),
                                                   RicercaSalvata(nome: "Senza previdenza", testo: "senza:previdenza"),
                                                   RicercaSalvata(nome: "Scadenze Alleanza 2027", testo: "scade:2027 canale:alleanza")]
            s.testoRicerca = ""
            s.cercaOvunque()
        }),
        ("105-incontri-preparazione", { s in
            // La preparazione dell'incontro di oggi (le quattro schede, le priorità del cliente e «L'ultima volta»)
            s.clienteAttivoId = "giulia"
            s.incontroAperto = "incontro-giulia-casa"
            s.schedaIncontro = .preparazione
            s.apri(.incontri)
        }),
        ("106-posizioni-multiramo", { s in
            // Marco: la multiramo a due parti, la composizione, la parte in gestione separata e i fondi
            s.clienteAttivoId = "marco"
            s.posizioneInDettaglio = "pos-marco-polizza-multiramo"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-composizione"
        }),
        // Giro 3 · completezza dei dati per l'analisi (specifica 7)
        ("110-clienti-completezza", { s in
            // Andrea (primo incontro): dati per l'analisi al 77%, l'orizzonte manca, fabbisogno e pensione stimati
            s.clienteAttivoId = "andrea"
            s.schedaCliente = .panoramica
            s.apri(.clienti)
        }),
        ("111-analisi360-ipotesi-stimate", { s in
            // La pensione pubblica evidenziata, «stimato» accanto alle ipotesi predefinite
            s.clienteAttivoId = "andrea"
            s.fuocoAnalisi = FuocoAnalisi(area: .previdenza, campo: TestiCompletezza.campoPensionePubblica)
            s.areaAnalisi = .previdenza
            s.apri(.analisi360)
        }),
        ("300-analisi360-investimenti", { s in
            // Sofia: il portafoglio di fondi in essere (indipendente) e la proposta di reinvestimento
            s.clienteAttivoId = "sofia"
            s.areaAnalisi = .investimenti
            s.apri(.analisi360)
        }),
        ("301-analisi360-risparmio", { s in
            // Marco: la polizza rivalutabile in essere (Alleanza) e il piano proposto per gli studi di Anna
            s.clienteAttivoId = "marco"
            s.areaAnalisi = .risparmio
            s.apri(.analisi360)
        }),
        ("112-prospetto-ipotesi-stimate", { s in
            // Check-up di Andrea: l'ultima pagina, i dati mancanti e le ipotesi stimate
            s.clienteAttivoId = "andrea"
            // `0..<max(0, n − 1)`: con `1..<n` un documento vuoto farebbe un intervallo non valido
            if let d = s.documentoProspetto(.checkUp(report: false)) {
                s.presenta(d)
                for _ in 0..<max(0, d.pagine.count - 1) { s.paginaSeguente() }
            }
        }),
        ("113-report-ipotesi-stimate", { s in
            // Report del check-up: la slide «Le ipotesi da confermare insieme» (prima della sintesi)
            s.clienteAttivoId = "andrea"
            if let d = s.documentoProspetto(.checkUp(report: true)) {
                s.presenta(d)
                for _ in 0..<max(0, d.pagine.count - 2) { s.paginaSeguente() }
            }
        }),
        // Giro 3 · seguito delle proposte (specifica 5)
        ("114-agenda-esito-proposta", { s in
            // Laura: la proposta presentata ieri, il riquadro «Com'è andata…» con le quattro scelte
            Istantanee.concludiIeri(s, "event-laura", ore: 10)
            s.apri(.agenda)
        }),
        ("115-agenda-firma-decorrenza", { s in
            // Giulia: la firma del PIP ieri, il passo «Accettata» con decorrenza, versato e primo valore
            if let i = s.dati.appuntamenti.firstIndex(where: { $0.id == "event-giulia-previdenza" }) {
                s.dati.appuntamenti[i].tipo = .firma
            }
            Istantanee.concludiIeri(s, "event-giulia-previdenza", ore: 18)
            s.apri(.agenda)
        }),
        ("116-portafoglio-seguito", { s in
            // «Proposte da riprendere»: Sofia 34 giorni, Giulia 25, Andrea da riprendere; motivi e tempo medio
            Istantanee.preparaSeguito(s)
            s.portafoglio = true
            s.ancoraPosizioni = "seguito"
            s.apri(.posizioni)
        }),
        ("117-notifiche-seguito", { s in
            // «3 proposte aspettano una risposta» in DA RECUPERARE
            Istantanee.preparaSeguito(s)
            s.alternaNotifiche()
        }),
        ("118-scrivania-seguito", { s in
            // La riga «3 proposte aspettano una risposta» nel giorno del widget Agenda
            Istantanee.preparaSeguito(s)
        }),
        ("119-posizioni-esito-rimandata", { s in
            // Andrea: «Esito della proposta: Rimandata · da riprendere il …» e i pulsanti dell'esito
            Istantanee.preparaSeguito(s)
            s.clienteAttivoId = "andrea"
            s.posizioneInDettaglio = "pos-andrea-piano-di-risparmio-rivalutabile"
            s.apri(.posizioni)
        }),
        // Giro 3 · esperienza per tipo di prodotto (specifica 2)
        ("120-clienti-esperienza", { s in
            // Giulia: la griglia per tipo, la capacità «fino al 10%», il suggerimento sui fondi e l'esperienza suggerita
            s.clienteAttivoId = "giulia"
            s.schedaCliente = .profilo
            s.apri(.clienti)
        }),
        ("121-posizioni-proposta-esperienza", { s in
            // Andrea: la proposta di Ramo I che non conosce, con la pillola «Esperienza» e l'etichetta blu Alleanza
            s.clienteAttivoId = "andrea"
            s.posizioneInDettaglio = "pos-andrea-piano-di-risparmio-rivalutabile"
            s.apri(.posizioni)
        }),
        ("122-posizioni-coerenza-esperienza", { s in
            // Giulia: «Coerenza con il profilo» con l'esperienza sul PIP tra i punti da rivedere
            s.clienteAttivoId = "giulia"
            s.apri(.posizioni)
            s.ancoraPosizioni = "coerenza"
        }),
        // Giro 3 · riesami del mese in Agenda (specifica 6)
        ("124-agenda-riesami-mese", { s in
            // La striscia «Riesami del mese»: Sofia mai incontrata, Laura e Marco scaduti
            ProvaRiesamiAgenda.prepara(s)
            s.apri(.agenda)
        }),
        ("125-agenda-riesame-pianificato", { s in
            // «Pianifica» per Laura: il riesame nel primo spazio libero, con canale e ordine del giorno
            ProvaRiesamiAgenda.prepara(s)
            if let p = s.pianificaRiesame("laura") { s.salvaAppuntamento(p.appuntamento) }
            s.apri(.agenda)
        }),
        ("126-impostazioni-orari", { s in
            // La pagina «Agenda e lavoro»: orari, festività, seguito delle proposte
            s.schedaImpostazioni = .lavoro
            s.apri(.impostazioni)
        }),
        ("127-agenda-riesami-schermo-basso", { s in
            // Finestra bassa (1280×760): fascia e striscia compatte su una riga
            ProvaRiesamiAgenda.prepara(s)
            s.apri(.agenda)
        }),
        // Giro 4 · calendario delle occasioni (specifica 4)
        ("130-agenda-occasioni", { s in
            // Martedì con le occasioni; la polizza di Marco senza più penali nel dettaglio (vista Giorno: nel tema
            // Apple la settimana non ha più la colonna del dettaglio)
            Istantanee.preparaOccasioni(s)
            s.vistaAgenda = .giorno
            if let martedi = Istantanee.questaSettimana(1, anni: 0) { s.giornoAgenda = Calendar.current.startOfDay(for: martedi) }
            s.occasioneSelezionata = s.occasioniDelGiorno(s.giornoAgenda).first { $0.tipo == .senzaPenali }
            s.apri(.agenda)
        }),
        ("131-agenda-occasioni-elenco", { s in
            // La vista «Occasioni»: 12 mesi da questo mese, con il dettaglio della prima occasione importante
            Istantanee.preparaOccasioni(s)
            s.vistaAgenda = .occasioni
            s.giornoAgenda = Calendar.current.startOfDay(for: Date())
            let elenco = s.elencoOccasioniAgenda
            s.occasioneSelezionata = elenco.first { $0.importanza == .alta } ?? elenco.first
            s.apri(.agenda)
        }),
        ("133-notifiche-occasioni", { s in
            // «5 anni alla pensione di Sofia Romano» e «Anna Bianchi diventa maggiorenne» in NEI PROSSIMI GIORNI
            let cal = Calendar.current
            let oggi = cal.startOfDay(for: Date())
            if let c = s.dati.clienti.firstIndex(where: { $0.id == "marco" }),
               let f = s.dati.clienti[c].famiglia.firstIndex(where: { $0.nome == "Anna Bianchi" }) {
                s.dati.clienti[c].famiglia[f].dataNascita = cal.date(byAdding: .day, value: 12, to: oggi).flatMap { cal.date(byAdding: .year, value: -18, to: $0) }
            }
            if let c = s.dati.clienti.firstIndex(where: { $0.id == "sofia" }) {
                s.dati.clienti[c].dataNascita = cal.date(byAdding: .day, value: 20, to: oggi).flatMap { cal.date(byAdding: .year, value: -62, to: $0) }
            }
            s.alternaNotifiche()
        }),
        ("134-impostazioni-occasioni", { s in
            // Il gruppo «Occasioni» della pagina «Promemoria e occasioni», portato in vista dall'ancora
            s.schedaImpostazioni = .promemoria
            s.ancoraImpostazioni = "impostazioni-occasioni"
            s.apri(.impostazioni)
        }),
        // Giro 4 · scheda di adeguatezza della proposta (specifica 1)
        ("140-posizioni-adeguatezza", { s in
            // Sofia: la scheda della proposta obbligazionaria (indipendente, etichetta cuoio), sostituzione gialla
            // per le garanzie della polizza in scadenza, quattro documenti spuntati su sette
            ProvaAdeguatezza.prepara(s)
            s.clienteAttivoId = "sofia"
            s.posizioneInDettaglio = "pos-sofia-obbligazionario-a-scadenza-2030"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-adeguatezza"
        }),
        ("141-posizioni-adeguatezza-rossa", { s in
            // Andrea: Ramo I che non conosce (rosso), SRI stimato, orizzonte e bisogno da completare, etichetta blu Alleanza
            s.clienteAttivoId = "andrea"
            s.posizioneInDettaglio = "pos-andrea-piano-di-risparmio-rivalutabile"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-adeguatezza"
        }),
        ("142-adeguatezza-pdf", { s in
            // Sofia: la prima pagina del PDF (controlli e riferimenti), a tutta finestra
            ProvaAdeguatezza.prepara(s)
            s.clienteAttivoId = "sofia"
            if let p = s.dati.posizioni.first(where: { $0.id == "pos-sofia-obbligazionario-a-scadenza-2030" }),
               let d = s.documentoAdeguatezza(p) { s.presenta(d) }
        }),
        ("143-adeguatezza-pdf-firme", { s in
            // Sofia: la seconda pagina (esperienza, documenti con le caselle, dichiarazioni, firme)
            ProvaAdeguatezza.prepara(s)
            s.clienteAttivoId = "sofia"
            if let p = s.dati.posizioni.first(where: { $0.id == "pos-sofia-obbligazionario-a-scadenza-2030" }),
               let d = s.documentoAdeguatezza(p) {
                s.presenta(d)
                s.paginaSeguente()
            }
        }),
        ("144-impostazioni-proposte", { s in
            // L'elenco dei documenti da consegnare per canale, con le etichette blu e cuoio
            s.schedaImpostazioni = .proposte
            s.apri(.impostazioni)
        }),
        // Giro 4 · scadenze di conformità «In regola» (specifica 3)
        ("150-clienti-in-regola", { s in
            // Giulia: tessere, blocco Alleanza con il questionario in scadenza, documento e consenso commerciale
            s.clienteAttivoId = "giulia"
            s.schedaCliente = .inRegola
            s.apri(.clienti)
        }),
        ("151-clienti-in-regola-andrea", { s in
            // Andrea: tre voci «Da raccogliere», solo il blocco Alleanza
            s.clienteAttivoId = "andrea"
            s.schedaCliente = .inRegola
            s.apri(.clienti)
        }),
        ("152-clienti-panoramica-in-regola", { s in
            // Marco: il riquadro «In regola» nella Panoramica, con la pillola rossa
            s.clienteAttivoId = "marco"
            s.schedaCliente = .panoramica
            s.apri(.clienti)
        }),
        ("153-notifiche-conformita", { s in
            // Le scadenze di conformità in DA RECUPERARE, NEI PROSSIMI GIORNI e DA SISTEMARE
            s.alternaNotifiche()
        }),
        ("154-ricerca-conformita", { s in
            // Il filtro «Conformità scaduta» nel pannello ⌘K: i clienti con l'estratto delle voci
            s.testoRicerca = "conformita:scaduta"
            s.cercaOvunque()
        }),
        ("155-impostazioni-conformita", { s in
            // La pagina «Conformità»: questionari per canale, adeguata verifica in griglia, consenso e privacy
            s.schedaImpostazioni = .conformita
            s.apri(.impostazioni)
        }),
        // Giro 5 · Documenti rifatti (160–166)
        ("160-clienti-documenti-vuoto", { s in
            // Laura non ha documenti: il vuoto che spiega cosa fare
            s.clienteAttivoId = "laura"
            s.apri(.documenti)
        }),
        ("161-clienti-documenti-cosa-non-torna", { s in
            // La raccolta «Cosa non torna»: la polizza di Marco, con il banner delle differenze nella scheda Dati
            s.clienteAttivoId = "marco"
            s.vistaDocumenti.raccolta = .conDifferenze
            s.documentoSelezionato = "doc-marco-polizza"
            s.apri(.documenti)
        }),
        ("162-clienti-documenti-fonte-pagina", { s in
            // La fonte di una cifra: «p. 2» porta l'anteprima alla pagina e ne illumina la riga
            s.clienteAttivoId = "giulia"
            s.documentoSelezionato = "doc-giulia-kid"
            s.vistaDocumenti.pagina = 2
            s.vistaDocumenti.evidenzia = .sri
            s.apri(.documenti)
        }),
        ("163-clienti-documenti-testo", { s in
            s.clienteAttivoId = "giulia"
            s.documentoSelezionato = "doc-giulia-kid"
            s.vistaDocumenti.scheda = .testo
            s.vistaDocumenti.pagina = 3
            s.apri(.documenti)
        }),
        ("164-clienti-documenti-schermo-basso", { s in
            // Schermo più basso: il foglio resta protagonista, il pannello dei dati accanto; «Aggiorna il valore»
            s.clienteAttivoId = "giulia"
            s.documentoSelezionato = "doc-giulia-estratto"
            if let d = s.documento("doc-giulia-estratto") { for c in d.campi { s.confermaCampo(d.id, c.chiave, true) } }
            s.apri(.documenti)
        }),
        ("165-clienti-documenti-identita-in-regola", { s in
            // Il documento d'identità di Giulia contro il dossier e «In regola» (giro 4)
            s.clienteAttivoId = "giulia"
            let d = ProvaCalcoliDocumenti.documento("doc-demo-identita", cliente: "giulia", titolo: "Carta d'identità di Giulia Rossi",
                                                    tipo: .altro, pagine: ProvaCalcoliDocumenti.identita)
            s.dati.documenti.append(d)
            s.memorizzaTesto(d.id, ProvaCalcoliDocumenti.identita)
            s.documentoSelezionato = d.id
            s.vistaDocumenti.scheda = .confronto
            s.apri(.documenti)
        }),
        ("166-clienti-documenti-kid-categorie", { s in
            // Barra laterale con più tipi: il KID nuovo della multiramo di Marco, collegato alla scheda
            s.clienteAttivoId = "marco"
            var d = ProvaCalcoliDocumenti.documento("doc-demo-kid-multiramo", cliente: "marco", titolo: "KID 2026 · Polizza multiramo",
                                                    tipo: .kid, pagine: ProvaCalcoliDocumenti.kidMultiramo)
            d.prodottoId = "prodotto-multiramo"
            s.dati.documenti.append(d)
            s.memorizzaTesto(d.id, ProvaCalcoliDocumenti.kidMultiramo)
            s.documentoSelezionato = d.id
            s.apri(.documenti)
        }),
        // Giro 5 · aggiornamento dei valori in blocco (180–183)
        ("180-posizioni-aggiorna-elenco", { s in
            // «Aggiorna i valori» sull'elenco della compagnia: indicatori, righe per canale, tutte le pillole
            s.portafoglio = true
            s.aggiornaValori = AggiornaValori.sessione(tabella: ImportaClienti.righeCSV(DatiAggiornaValoriDemo.elenco(oggi: Date())),
                                                       file: "Valori Alleanza e indipendenti.xlsx", dataComune: Date())
            s.apri(.posizioni)
        }),
        ("181-posizioni-valori-fermi", { s in
            // La griglia dei valori fermi da più di 12 mesi, con due righe già scritte
            DatiAggiornaValoriDemo.invecchia(s)
            s.portafoglio = true
            s.aggiornaValori = AggiornaValori.Sessione(scheda: .griglia, bozze: DatiAggiornaValoriDemo.bozze())
            s.apri(.posizioni)
        }),
        ("182-posizioni-aggiorna-registrati", { s in
            // Il riepilogo dopo «Registra»: prima e dopo, righe per canale, elenco delle posizioni
            s.portafoglio = true
            s.aggiornaValori = AggiornaValori.sessione(tabella: ImportaClienti.righeCSV(DatiAggiornaValoriDemo.elenco(oggi: Date())),
                                                       file: "Valori Alleanza e indipendenti.xlsx", dataComune: Date())
            if let sessione = s.aggiornaValori {
                let e = AggiornaValori.esiti(sessione.righe, posizioni: s.posizioni, clienti: s.clienti,
                                             dataComune: sessione.dataComune, oggi: Date())
                s.applicaValoriInBlocco(e, esclusi: AggiornaValori.esclusiIniziali(e))
            }
            s.apri(.posizioni)
        }),
        ("183-posizioni-multiramo-aggiornata", { s in
            // Il dettaglio della multiramo di Marco dopo l'aggiornamento: valore, quota della gestione, andamento
            s.aggiornaValori = AggiornaValori.sessione(tabella: ImportaClienti.righeCSV(DatiAggiornaValoriDemo.elenco(oggi: Date())),
                                                       file: "Valori Alleanza e indipendenti.xlsx", dataComune: Date())
            if let sessione = s.aggiornaValori {
                let e = AggiornaValori.esiti(sessione.righe, posizioni: s.posizioni, clienti: s.clienti,
                                             dataComune: sessione.dataComune, oggi: Date())
                s.applicaValoriInBlocco(e, esclusi: AggiornaValori.esclusiIniziali(e))
            }
            s.aggiornaValori = nil
            s.clienteAttivoId = "marco"
            s.portafoglio = false
            s.posizioneInDettaglio = "pos-marco-polizza-multiramo"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-andamento"
        }),
        // Giro 5 · documento contro dossier (190–194)
        ("190-clienti-documenti-confronto-polizza", { s in
            // Marco: la polizza Infortuni famiglia contro la posizione. Capitale 150.000 contro 200.000 (scende, in rosso),
            // scadenza diversa, beneficiari nuovi (non scelti), premio uguale; etichetta Alleanza
            s.clienteAttivoId = "marco"
            s.documentoSelezionato = "doc-marco-polizza"
            s.vistaDocumenti.scheda = .confronto
            s.apri(.documenti)
        }),
        ("191-clienti-documenti-confronto-kid-impatto", { s in
            // Giulia: il nuovo KID dell'ETF contro la scheda. SRI 4→5, costi 0,20→0,25%, incidenza 0,20→0,25%;
            // impatto su Giulia (oltre il profilo) e Laura, collegate per nome; etichetta indipendente
            s.clienteAttivoId = "giulia"
            s.dati.documenti.append(DatiConfrontoDemo.kidETF())
            s.memorizzaTesto(DatiConfrontoDemo.idKIDETF, DatiConfrontoDemo.pagineKIDETF)
            s.documentoSelezionato = DatiConfrontoDemo.idKIDETF
            s.vistaDocumenti.scheda = .confronto
            s.apri(.documenti)
        }),
        ("192-prodotti-avviso-nuovo-kid", { s in
            // La scheda dell'ETF dopo l'aggiornamento: avviso «Nuovo KID» in alto con i due clienti
            s.clienteAttivoId = "giulia"
            let d = DatiConfrontoDemo.kidETF()
            s.dati.documenti.append(d)
            s.memorizzaTesto(d.id, DatiConfrontoDemo.pagineKIDETF)
            if let c = s.confronto(d, .prodotto("prodotto-etf-globale")) {
                s.aggiornaDalDocumento(d.id, bersaglio: .prodotto("prodotto-etf-globale"), voci: c.preselezione, ancheProposte: true)
            }
            s.prodottoSelezionato = "prodotto-etf-globale"
            s.apri(.prodotti)
        }),
        ("193-clienti-documenti-appendice-da-collegare", { s in
            // Giulia: un'appendice non collegata; Prisma suggerisce il piano di risparmio dal numero di polizza
            s.clienteAttivoId = "giulia"
            let scadenza = s.dati.posizioni.first { $0.id == "pos-giulia-piano-di-risparmio-rivalutabile" }?.scadenza ?? Date()
            s.dati.documenti.append(DatiConfrontoDemo.appendice(scadenza: scadenza))
            s.memorizzaTesto(DatiConfrontoDemo.idAppendice, DatiConfrontoDemo.pagineAppendice(scadenza: scadenza))
            s.documentoSelezionato = DatiConfrontoDemo.idAppendice
            s.vistaDocumenti.scheda = .confronto
            s.apri(.documenti)
        }),
        ("194-clienti-documenti-confronto-storico", { s in
            // Marco: capitale aggiornato dalla polizza; la riga è uguale e lo storico mostra 200.000 → 150.000 con «Ripristina»
            s.clienteAttivoId = "marco"
            s.aggiornaDalDocumento("doc-marco-polizza", bersaglio: .posizione("pos-marco-infortuni-famiglia"),
                                   voci: [.capitaleAssicurato], ancheProposte: false)
            s.documentoSelezionato = "doc-marco-polizza"
            s.vistaDocumenti.scheda = .confronto
            s.apri(.documenti)
        }),
        // Giro 6 · rendimento contro un riferimento e «TFR in azienda o nel fondo» (200–206)
        ("200-posizioni-riferimento-tfr", { s in
            // Il PIP di Marco contro la rivalutazione del TFR: gettoni «inserito da te» e «stimato», linea verde-acqua
            s.clienteAttivoId = "marco"
            Istantanee.riferimentiDiProva(s)
            s.posizioneInDettaglio = "pos-marco-piano-individuale-pensionistico"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-riferimento"
        }),
        ("201-posizioni-riferimento-inflazione", { s in
            // L'ETF di Giulia contro l'inflazione (FOI): rendimento reale e pillola
            s.clienteAttivoId = "giulia"
            Istantanee.riferimentiDiProva(s)
            s.posizioneInDettaglio = "pos-giulia-etf-azionario-globale"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-riferimento"
        }),
        ("202-posizioni-riferimento-da-aggiornare", { s in
            // Senza valori dal 2024: avviso «arrivano al 2023» e «Apri i riferimenti»
            s.clienteAttivoId = "giulia"
            s.posizioneInDettaglio = "pos-giulia-etf-azionario-globale"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-riferimento"
        }),
        ("203-impostazioni-rendimenti", { s in
            Istantanee.riferimentiDiProva(s)
            s.schedaImpostazioni = .rendimenti
            s.apri(.impostazioni)
        }),
        // Impostazioni a pagine: la Panoramica con le tessere di stato, Vera, il Profilo con i canali
        ("250-impostazioni-panoramica", { s in
            s.schedaImpostazioni = .panoramica
            s.apri(.impostazioni)
        }),
        ("251-impostazioni-vera", { s in
            s.schedaImpostazioni = .vera
            s.apri(.impostazioni)
        }),
        ("252-impostazioni-profilo", { s in
            s.schedaImpostazioni = .profilo
            s.apri(.impostazioni)
        }),
        ("253-impostazioni-promemoria", { s in
            s.schedaImpostazioni = .promemoria
            s.apri(.impostazioni)
        }),
        ("204-analisi360-tfr", { s in
            Istantanee.preparaTFR(s)
            s.scegliStrumentoAnalisi(.tfr)
            s.apri(.analisi360)
        }),
        ("205-tfr-prospetto", { s in
            Istantanee.preparaTFR(s)
            if let d = s.documentoTFR(report: false) { s.presenta(d) }
        }),
        ("206-tfr-report", { s in
            // La slide «Due strade per lo stesso TFR»
            Istantanee.preparaTFR(s)
            if let d = s.documentoTFR(report: true) {
                s.presenta(d)
                s.paginaSeguente()
            }
        }),
        // Revisione del TFR: contributi alti (il fondo metà in capitale e metà in rendita) e cliente non dipendente
        ("207-analisi360-tfr-rendita", { s in
            Istantanee.preparaTFR(s)
            var i = s.ipotesiTFR("marco")
            i.contributoLavoratore = 3
            i.contributoDatore = 2
            i.anniServizio = 8
            s.salvaIpotesiTFR("marco", i)
            s.scegliStrumentoAnalisi(.tfr)
            s.apri(.analisi360)
        }),
        ("208-analisi360-tfr-autonomo", { s in
            s.clienteAttivoId = "marco"
            if let k = s.dati.clienti.firstIndex(where: { $0.id == "marco" }) {
                var lavoro = s.dati.clienti[k].profilo.lavoro ?? DatiLavoro()
                lavoro.tipo = .autonomo
                s.dati.clienti[k].profilo.lavoro = lavoro
            }
            s.scegliStrumentoAnalisi(.tfr)
            s.apri(.analisi360)
        }),
        // Giro 6 · riesame con memoria (210–215)
        ("210-clienti-riesami", { s in
            DatiMemoriaDemo.prepara(s)
            s.clienteAttivoId = "giulia"
            s.schedaCliente = .riesami
            s.apri(.clienti)
        }),
        ("211-riesame-prospetto-variazioni", { s in
            // Prima pagina: sottotitolo con il riesame precedente e tabella «Cosa è cambiato»
            DatiMemoriaDemo.prepara(s)
            s.clienteAttivoId = "giulia"
            if let d = s.documentoProspetto(.riesame) { s.presenta(d) }
        }),
        ("212-riesame-prospetto-cronologia", { s in
            // Ultima pagina: «Cronologia dei riesami» con la riga «Oggi» e le domande nuove
            DatiMemoriaDemo.prepara(s)
            s.clienteAttivoId = "giulia"
            if let d = s.documentoProspetto(.riesame) {
                s.presenta(d)
                for _ in 0..<max(0, d.pagine.count - 1) { s.paginaSeguente() }
            }
        }),
        ("213-agenda-riesame-memoria", { s in
            // Le note dell'appuntamento si aprono con «Cosa è cambiato dal riesame del …»
            DatiMemoriaDemo.prepara(s)
            if let a = s.bozzaRiesame("giulia") { s.salvaAppuntamento(a) }
            s.apri(.agenda)
        }),
        ("214-clienti-riesami-primo", { s in
            // Marco non ha fotografie: stato vuoto
            s.clienteAttivoId = "marco"
            s.schedaCliente = .riesami
            s.apri(.clienti)
        }),
        ("215-incontri-cambiato", { s in
            DatiMemoriaDemo.prepara(s)
            s.clienteAttivoId = "giulia"
            s.incontroAperto = "incontro-giulia-casa"
            s.schedaIncontro = .preparazione
            s.apri(.incontri)
        }),
        // Avvio sulla schermata di benvenuto e guida di Prisma (G7). Il genio non si vede: è Core Animation
        // sul Mac vero (le prove dei suoi conti stanno in --prova-fluidita)
        ("220-avvio-benvenuto", { s in
            // Il primo avvio: Prisma si apre sul blocco, nessuna app aperta. Solo data, ora, logo e cursore:
            // l'introduzione parte da sola dopo lo sblocco, senza invito sul blocco
            s.dati.impostazioni.introduzioneVista = false
            s.blocca()
        }),
        ("221-avvio-benvenuto-schermo-basso", { s in
            s.dati.impostazioni.introduzioneVista = false
            s.blocca()
        }),
        ("222-introduzione", { s in s.apriGuida(.introduzione(0)) }),
        ("223-introduzione-app", { s in s.apriGuida(.introduzione(2)) }),
        ("224-introduzione-percorso", { s in s.apriGuida(.introduzione(4)) }),
        ("225-guida-posizioni", { s in
            s.apri(.posizioni)
            s.apriGuida(.app(.posizioni))
        }),
        ("226-guida-clienti", { s in
            s.apri(.clienti)
            s.apriGuida(.app(.clienti))
        }),
        ("227-glossario", { s in s.apriGuida(.glossario(nil)) }),
        ("228-glossario-sri", { s in s.apriGuida(.glossario(.sri)) }),
        ("229-introduzione-schermo-basso", { s in s.apriGuida(.introduzione(0)) }),
        // I vuoti guidati: che cosa fare quando un'app non ha ancora dati
        ("230-vuoto-posizioni", { s in
            s.dati.posizioni.removeAll { $0.clienteId == "sofia" }
            s.clienteAttivoId = "sofia"
            s.apri(.posizioni)
        }),
        ("231-vuoto-clienti", { s in
            s.dati.clienti.removeAll()
            s.dati.posizioni.removeAll()
            s.dati.simulazioni.removeAll()
            s.dati.obiettivi.removeAll()
            s.apri(.clienti)
        }),
        ("232-clienti-obiettivi-vuoto", { s in
            s.dati.obiettivi.removeAll { $0.clienteId == "sofia" }
            s.clienteAttivoId = "sofia"
            s.apri(.obiettivi)
        }),
        ("233-vuoto-analisi360-scenari", { s in
            s.dati.simulazioni.removeAll { $0.clienteId == "sofia" }
            s.clienteAttivoId = "sofia"
            s.scegliStrumentoAnalisi(.scenari)
            s.apri(.analisi360)
        }),
        // I pulsanti nuovi nelle finestre strette: l'intestazione e le barre passano alle sole icone
        ("234-posizioni-finestra-stretta", { s in
            s.apri(.posizioni)
            s.alternaIngrandimento(.posizioni)
            s.ridimensiona(.posizioni, dimensione: CGSize(width: 760, height: 640))
        }),
        ("235-posizioni-dettaglio-stretta", { s in
            s.posizioneInDettaglio = "pos-giulia-etf-azionario-globale"
            s.apri(.posizioni)
            s.alternaIngrandimento(.posizioni)
            s.ridimensiona(.posizioni, dimensione: CGSize(width: 820, height: 680))
        }),
        ("236-prospetti-finestra-stretta", { s in
            s.clienteAttivoId = "giulia"
            s.prospetto = .checkUp(report: false)
            s.apri(.presentazioni)
            s.alternaIngrandimento(.presentazioni)
            s.ridimensiona(.presentazioni, dimensione: CGSize(width: 820, height: 680))
        }),
        ("237-clienti-documenti-stretta", { s in
            // Documenti è accorpata: la finestra è quella di Clienti, sulla scheda Documenti
            s.apri(.documenti)
            s.alternaIngrandimento(.clienti)
            s.ridimensiona(.clienti, dimensione: CGSize(width: 820, height: 680))
        }),
        ("290-clienti-documenti-stretta-dati", { s in
            // Finestra stretta: il foglio resta intero, il pannello dei dati non ci sta accanto e va in un cassetto sotto la pagina
            s.clienteAttivoId = "giulia"
            s.documentoSelezionato = "doc-giulia-kid"
            s.vistaDocumenti.pannelloDati = true
            s.apri(.documenti)
            s.alternaIngrandimento(.clienti)
            s.ridimensiona(.clienti, dimensione: CGSize(width: 820, height: 680))
        }),
        ("238-agenda-finestra-stretta", { s in
            s.apri(.agenda)
            s.alternaIngrandimento(.agenda)
            s.ridimensiona(.agenda, dimensione: CGSize(width: 820, height: 680))
        }),
        // Gli strumenti di Analisi 360 in una finestra stretta: la testata passa alle sole icone
        ("239-analisi360-confronto-stretta", { s in
            s.clienteAttivoId = "marco"
            s.scegliStrumentoAnalisi(.confronto)
            s.apri(.analisi360)
            s.alternaIngrandimento(.analisi360)
            s.ridimensiona(.analisi360, dimensione: CGSize(width: 900, height: 680))
        }),
        // Le scene in aspetto scuro: il suffisso "-scuro" le disegna così (vedi genera)
        ("53-ricerca-scuro", { s in
            s.apri(.posizioni)
            s.testoRicerca = "marco"
            s.cercaOvunque()
        }),
        ("92-posizioni-gestione-separata-scuro", { s in
            s.clienteAttivoId = "giulia"
            s.posizioneInDettaglio = "pos-giulia-piano-di-risparmio-rivalutabile"
            s.apri(.posizioni)
        }),
        ("106-posizioni-multiramo-scuro", { s in
            // La stessa scena della multiramo di Marco, in aspetto scuro (vetro delle due parti)
            s.clienteAttivoId = "marco"
            s.posizioneInDettaglio = "pos-marco-polizza-multiramo"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-composizione"
        }),
        ("110-clienti-completezza-scuro", { s in
            s.clienteAttivoId = "andrea"
            s.schedaCliente = .panoramica
            s.apri(.clienti)
        }),
        ("11a-agenda-mese-scuro", { s in
            Istantanee.attivitaRimastaIndietro(s)
            s.apri(.agenda)
        }),
        ("114-agenda-esito-proposta-scuro", { s in
            Istantanee.concludiIeri(s, "event-laura", ore: 10)
            s.apri(.agenda)
        }),
        ("116-portafoglio-seguito-scuro", { s in
            Istantanee.preparaSeguito(s)
            s.portafoglio = true
            s.ancoraPosizioni = "seguito"
            s.apri(.posizioni)
        }),
        ("300-analisi360-investimenti-scuro", { s in
            // La sintesi degli investimenti di Sofia in aspetto scuro (scala del rischio, cascata, canale)
            s.clienteAttivoId = "sofia"
            s.areaAnalisi = .investimenti
            s.apri(.analisi360)
        }),
        ("120-clienti-esperienza-scuro", { s in
            s.clienteAttivoId = "giulia"
            s.schedaCliente = .profilo
            s.apri(.clienti)
        }),
        ("124-agenda-riesami-mese-scuro", { s in
            ProvaRiesamiAgenda.prepara(s)
            s.apri(.agenda)
        }),
        ("130-agenda-occasioni-scuro", { s in
            Istantanee.preparaOccasioni(s)
            s.vistaAgenda = .giorno
            if let martedi = Istantanee.questaSettimana(1, anni: 0) { s.giornoAgenda = Calendar.current.startOfDay(for: martedi) }
            s.occasioneSelezionata = s.occasioniDelGiorno(s.giornoAgenda).first { $0.tipo == .senzaPenali }
            s.apri(.agenda)
        }),
        ("132-agenda-occasioni-mese-scuro", { s in
            // Il mese in vetro scuro con gli anelli dei due canali e la nota «· N occasioni» della settimana
            Istantanee.preparaOccasioni(s)
            s.vistaAgenda = .mese
            s.apri(.agenda)
        }),
        ("140-posizioni-adeguatezza-scuro", { s in
            ProvaAdeguatezza.prepara(s)
            s.clienteAttivoId = "sofia"
            s.posizioneInDettaglio = "pos-sofia-obbligazionario-a-scadenza-2030"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-adeguatezza"
        }),
        ("150-clienti-in-regola-scuro", { s in
            s.clienteAttivoId = "giulia"
            s.schedaCliente = .inRegola
            s.apri(.clienti)
        }),
        ("153-notifiche-conformita-scuro", { s in
            s.alternaNotifiche()
        }),
        ("161-clienti-documenti-cosa-non-torna-scuro", { s in
            // Vetro scuro, foglio dell'anteprima sempre bianco
            s.clienteAttivoId = "marco"
            s.vistaDocumenti.raccolta = .conDifferenze
            s.documentoSelezionato = "doc-marco-polizza"
            s.apri(.documenti)
        }),
        ("180-posizioni-aggiorna-elenco-scuro", { s in
            s.portafoglio = true
            s.aggiornaValori = AggiornaValori.sessione(tabella: ImportaClienti.righeCSV(DatiAggiornaValoriDemo.elenco(oggi: Date())),
                                                       file: "Valori Alleanza e indipendenti.xlsx", dataComune: Date())
            s.apri(.posizioni)
        }),
        ("191-clienti-documenti-confronto-kid-impatto-scuro", { s in
            s.clienteAttivoId = "giulia"
            s.dati.documenti.append(DatiConfrontoDemo.kidETF())
            s.memorizzaTesto(DatiConfrontoDemo.idKIDETF, DatiConfrontoDemo.pagineKIDETF)
            s.documentoSelezionato = DatiConfrontoDemo.idKIDETF
            s.vistaDocumenti.scheda = .confronto
            s.apri(.documenti)
        }),
        ("200-posizioni-riferimento-tfr-scuro", { s in
            s.clienteAttivoId = "marco"
            Istantanee.riferimentiDiProva(s)
            s.posizioneInDettaglio = "pos-marco-piano-individuale-pensionistico"
            s.apri(.posizioni)
            s.ancoraPosizioni = "dettaglio-riferimento"
        }),
        ("204-analisi360-tfr-scuro", { s in
            Istantanee.preparaTFR(s)
            s.scegliStrumentoAnalisi(.tfr)
            s.apri(.analisi360)
        }),
        ("210-clienti-riesami-scuro", { s in
            DatiMemoriaDemo.prepara(s)
            s.clienteAttivoId = "giulia"
            s.schedaCliente = .riesami
            s.apri(.clienti)
        }),
        ("1-scrivania-scuro", { _ in }),
        ("2-posizioni-scuro", { $0.apri(.posizioni) }),
        ("4-finestra-non-ingrandita-scuro", { s in
            s.apri(.clienti)
            s.alternaIngrandimento(.clienti)
        }),
        ("5-clienti-panoramica-scuro", { $0.apri(.clienti) }),
        ("63-benvenuto-scuro", { s in
            s.dati.impostazioni.introduzioneVista = true
            s.apri(.clienti)
            s.blocca()
        }),
        ("64-app-aperte-scuro", { s in
            s.filtroClienteAgenda = "marco"
            s.apri(.agenda)
            s.apri(.clienti)
            s.pannelloAppAperte = true
        }),
        ("90-impostazioni-aspetto-scuro", { s in
            s.apri(.impostazioni)
            s.schedaImpostazioni = .aspetto
        }),
        ("250-impostazioni-panoramica-scuro", { s in
            s.schedaImpostazioni = .panoramica
            s.apri(.impostazioni)
        }),
        ("220-avvio-benvenuto-scuro", { s in
            s.dati.impostazioni.introduzioneVista = false
            s.blocca()
        }),
        ("222-introduzione-scuro", { s in s.apriGuida(.introduzione(0)) }),
        ("225-guida-posizioni-scuro", { s in
            s.apri(.posizioni)
            s.apriGuida(.app(.posizioni))
        }),
        ("228-glossario-sri-scuro", { s in s.apriGuida(.glossario(.sri)) }),
        ("230-vuoto-posizioni-scuro", { s in
            s.dati.posizioni.removeAll { $0.clienteId == "sofia" }
            s.clienteAttivoId = "sofia"
            s.apri(.posizioni)
        }),
        // Tema Apple (Design/template-apple.html): la vetrina dei componenti nello stato finale, chiara e scura.
        // Al posto della shell si disegna VetrinaApple (vedi `sceneVetrina`)
        ("400-vetrina-apple", { _ in }),
        ("400-vetrina-apple-scuro", { _ in }),
        // Tema Apple, la scrivania (§3.6): la mossa del giorno su una proposta ferma (il PIP di Giulia presentato
        // 50 giorni fa), l'agenda di oggi, i tre anelli, Vera con le domande, da fare e scadenze
        ("410-scrivania-apple", { s in propostaFermaGiulia(s) }),
        ("410-scrivania-apple-scuro", { s in propostaFermaGiulia(s) }),
        // La stessa scrivania sotto il blocco, con il centro notifiche aperto e con una finestra davanti (al 25%)
        ("411-scrivania-apple-blocco", { s in
            s.dati.impostazioni.introduzioneVista = true
            s.blocca()
        }),
        ("412-scrivania-apple-notifiche", { s in s.alternaNotifiche() }),
        ("413-scrivania-apple-finestra", { s in
            s.apri(.agenda)
            s.alternaIngrandimento(.agenda)
        }),
        // Niente di urgente: senza posizioni non ci sono proposte, riesami né scadenze, e la mossa lascia la frase calma
        ("414-scrivania-apple-calma", { s in s.dati.posizioni.removeAll() }),
        // Su uno schermo più basso le righe si accorciano in proporzione
        ("415-scrivania-apple-schermo-basso", { s in propostaFermaGiulia(s) }),
        // «Orizzonte», parte comune: Messaggi con i dati di prova veri dei motori (dal giro 3, senza Qwen: il testo di
        // Prisma) e Mercato (dal giro 7 l'app vera: senza dati di prova, mai aggiornato e con «Dati di mercato» spento).
        // Il pannello «Le novità» di Orizzonte (501) non c'è più: con «Luce» è il 614 (IstantaneeLuce.swift)
        ("505-app-nuove-messaggi", { s in s.apri(.messaggi) }),
        ("505-app-nuove-mercato-scuro", { s in s.apri(.mercato) }),
        // Tema Apple, Clienti (§4.2.1): rubrica con la ricerca a capsula, dossier di Giulia con le quattro tessere,
        // il segmentato delle schede del template e «Altro ▾»; poi una scheda di Prisma aperta da «Altro»
        ("430-clienti-dossier", { s in
            s.clienteAttivoId = "giulia"
            s.schedaCliente = .panoramica
            s.apri(.clienti)
        }),
        ("430-clienti-dossier-scuro", { s in
            s.clienteAttivoId = "giulia"
            s.schedaCliente = .panoramica
            s.apri(.clienti)
        }),
        ("431-clienti-dossier-altro", { s in
            s.clienteAttivoId = "marco"
            s.schedaCliente = .inRegola
            s.apri(.clienti)
        }),
        // Tema Apple, Clienti › Nel tempo (§4.2.4): il patrimonio di Giulia tre anni indietro e due avanti, con le
        // due fotografie dei riesami sulla linea e il cursore a oggi; poi il cursore sul riesame di 19 mesi fa
        ("434-clienti-nel-tempo", { s in
            DatiMemoriaDemo.prepara(s)
            s.clienteAttivoId = "giulia"
            s.schedaCliente = .nelTempo
            s.apri(.clienti)
        }),
        ("435-clienti-nel-tempo-passato", { s in
            DatiMemoriaDemo.prepara(s)
            RichiestaIstantaneaNelTempo.chiedi(s, mese: -19)
            s.clienteAttivoId = "giulia"
            s.schedaCliente = .nelTempo
            s.apri(.clienti)
        }),
        // Clienti › Famiglia (§4.2.5): Marco con Elena e i figli, le capsule della protezione e dei beneficiari
        ("436-clienti-famiglia-apple", { s in
            s.clienteAttivoId = "marco"
            s.schedaCliente = .famiglia
            s.apri(.clienti)
        }),
    ]

    /// Le scene che disegnano la vetrina del tema Apple invece della shell.
    static let sceneVetrina: Set<String> = ["400-vetrina-apple", "400-vetrina-apple-scuro"]

    /// La scrivania del tema Apple (scene 410 e 415): il piano previdenziale di Giulia presentato 50 giorni fa e
    /// ancora senza risposta, una proposta ferma per la mossa del giorno (date relative a oggi).
    nonisolated private static func propostaFermaGiulia(_ s: StatoShell) {
        let cal = Calendar.current
        let oggi = cal.startOfDay(for: Date())
        guard let i = s.dati.posizioni.firstIndex(where: { $0.id == "pos-giulia-piano-previdenziale-integrativo" }) else { return }
        var seguito = s.dati.posizioni[i].seguito ?? SeguitoProposta()
        seguito.presentataIl = ValoriDaDocumento.mezzogiorno(cal.date(byAdding: .day, value: -50, to: oggi) ?? oggi)
        s.dati.posizioni[i].esito = .presentata
        s.dati.posizioni[i].seguito = seguito
    }

    /// Seguito delle proposte (scene 114 e 115): l'appuntamento spostato a ieri all'ora data e concluso, come
    /// dall'agenda; il giorno e l'appuntamento restano aperti nel dettaglio.
    nonisolated private static func concludiIeri(_ s: StatoShell, _ id: String, ore: Int) {
        let cal = Calendar.current
        let ieri = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: Date())) ?? Date()
        guard let i = s.dati.appuntamenti.firstIndex(where: { $0.id == id }) else { return }
        s.dati.appuntamenti[i].inizio = cal.date(bySettingHour: ore, minute: 0, second: 0, of: ieri) ?? ieri
        s.dati.appuntamenti[i].stato = .pianificato
        s.alternaConcluso(id)
        s.giornoAgenda = ieri
        s.appuntamentoSelezionato = id
    }

    /// Seguito delle proposte (scene 116–119): proposte ferme, una rimandata, una rifiutata e una accettata,
    /// con date relative a oggi (riproducibili a qualunque ora del server).
    nonisolated private static func preparaSeguito(_ s: StatoShell) {
        let cal = Calendar.current
        let oggi = cal.startOfDay(for: Date())
        func g(_ n: Int) -> Date { ValoriDaDocumento.mezzogiorno(cal.date(byAdding: .day, value: n, to: oggi) ?? oggi) }
        var d = s.dati
        // Nessun appuntamento futuro di Giulia, Sofia e Andrea: le loro proposte sono ferme
        let clienti: Set<String> = ["giulia", "sofia", "andrea"]
        d.appuntamenti.removeAll { clienti.contains($0.clienteId) && $0.inizio >= oggi }
        func cambia(_ id: String, _ modifica: (inout Posizione, inout SeguitoProposta) -> Void) {
            guard let i = d.posizioni.firstIndex(where: { $0.id == id }) else { return }
            var seguito = d.posizioni[i].seguito ?? SeguitoProposta()
            modifica(&d.posizioni[i], &seguito)
            d.posizioni[i].seguito = seguito
        }
        cambia("pos-sofia-obbligazionario-a-scadenza-2030") { _, sg in sg.presentataIl = g(-34) }
        cambia("pos-giulia-piano-previdenziale-integrativo") { _, sg in sg.presentataIl = g(-25) }
        cambia("pos-andrea-piano-di-risparmio-rivalutabile") { p, sg in
            p.esito = .rimandata
            sg.esitoIl = g(-95)
            sg.riprendereIl = g(-5)
            sg.motivo = .liquidita
        }
        cambia("pos-andrea-temporanea-caso-morte") { p, sg in
            p.esito = .rifiutata
            sg.motivo = .costo
            sg.presentataIl = g(-30)
            sg.esitoIl = g(-10)
        }
        cambia("pos-giulia-etf-azionario-globale") { p, sg in
            p.esito = .accettata
            sg.presentataIl = g(-60)
            sg.esitoIl = g(-40)
        }
        s.dati = d
    }

    /// Una data di questa settimana spostata indietro di `anni` (lunedì + `giorno`), per mettere le occasioni
    /// nella settimana mostrata (scene 130–132).
    /// Un'attività di Marco scaduta l'altro ieri: nella giornata di oggi compare in «Rimaste indietro».
    nonisolated static func attivitaRimastaIndietro(_ s: StatoShell) {
        let cal = Calendar.current
        let scadenza = cal.date(byAdding: .day, value: -2, to: cal.startOfDay(for: Date())) ?? Date()
        s.dati.attivita.append(Attivita(id: "task-demo-indietro", clienteId: "marco",
                                        titolo: "Richiamare per i documenti della polizza",
                                        scadenza: scadenza, priorita: .alta, completata: false))
    }

    nonisolated private static func questaSettimana(_ giorno: Int, anni: Int) -> Date? {
        let lunedi = CalendarioAgenda.giorni(settimanaDi: Date()).first ?? Date()
        return Calendar.current.date(byAdding: .day, value: giorno, to: lunedi).flatMap { Calendar.current.date(byAdding: .year, value: -anni, to: $0) }
    }

    /// Occasioni (scene 130–132): penali finite per Marco (martedì), periodo raccomandato dei fondi di Sofia
    /// (mercoledì), Anna Bianchi maggiorenne (giovedì).
    nonisolated private static func preparaOccasioni(_ s: StatoShell) {
        if let i = s.dati.posizioni.firstIndex(where: { $0.id == "pos-marco-polizza-rivalutabile-a-premio-unico" }) {
            s.dati.posizioni[i].penali = [2, 1]
            s.dati.posizioni[i].decorrenza = questaSettimana(1, anni: 3)
        }
        if let i = s.dati.posizioni.firstIndex(where: { $0.id == "pos-sofia-portafoglio-di-fondi" }) {
            s.dati.posizioni[i].periodoRaccomandato = 5
            s.dati.posizioni[i].decorrenza = questaSettimana(2, anni: 5)
        }
        if let c = s.dati.clienti.firstIndex(where: { $0.id == "marco" }),
           let f = s.dati.clienti[c].famiglia.firstIndex(where: { $0.nome == "Anna Bianchi" }) {
            s.dati.clienti[c].famiglia[f].dataNascita = questaSettimana(3, anni: 18)
        }
    }

    /// Valori di prova per le istantanee (non sono statistiche ufficiali): l'inflazione del 2024 e del 2025, così il
    /// confronto copre lo storico di prova degli ultimi 12 mesi, e un indice con due anni.
    nonisolated static func riferimentiDiProva(_ s: StatoShell) {
        s.dati.impostazioni.riferimenti.valori = [
            ValoreRiferimento(serie: SerieRiferimento.idInflazione, anno: 2024, valore: 1.0),
            ValoreRiferimento(serie: SerieRiferimento.idInflazione, anno: 2025, valore: 2.0),
            ValoreRiferimento(serie: "indice-prova", anno: 2024, valore: 20.0),
            ValoreRiferimento(serie: "indice-prova", anno: 2025, valore: 8.0),
        ]
        s.dati.impostazioni.riferimenti.indici = [IndiceRiferimento(id: "indice-prova", nome: "Azionario globale", fonte: "Valori di prova")]
    }

    /// I documenti di Giulia in tutte le cartelle della scheda (scene 280–281): la carta d'identità (personali),
    /// l'estratto conto sul piano di risparmio Alleanza e il KID sul piano previdenziale (dei prodotti), un prospetto
    /// (da Prisma) e un preventivo senza collegamento (da collegare).
    nonisolated static func documentiRicchi(_ s: StatoShell) {
        s.clienteAttivoId = "giulia"
        let identita = ProvaCalcoliDocumenti.documento("doc-demo-identita", cliente: "giulia", titolo: "Carta d'identità di Giulia Rossi",
                                                       tipo: .altro, pagine: ProvaCalcoliDocumenti.identita)
        s.dati.documenti.append(identita)
        s.memorizzaTesto(identita.id, ProvaCalcoliDocumenti.identita)
        if let i = s.dati.documenti.firstIndex(where: { $0.id == "doc-giulia-estratto" }) {
            s.dati.documenti[i].posizioneId = "pos-giulia-piano-di-risparmio-rivalutabile"
        }
        if let i = s.dati.documenti.firstIndex(where: { $0.id == "doc-giulia-kid" }) {
            s.dati.documenti[i].posizioneId = "pos-giulia-piano-previdenziale-integrativo"
        }
        var prospetto = Documento(clienteId: "giulia", titolo: "Prospetto · Piano previdenziale integrativo", tipo: .prospetto)
        prospetto.id = "doc-demo-prospetto"
        prospetto.lettura = .letto
        s.dati.documenti.append(prospetto)
        var preventivo = Documento(clienteId: "giulia", titolo: "Preventivo del mutuo per la casa", tipo: .altro)
        preventivo.id = "doc-demo-preventivo"
        s.dati.documenti.append(preventivo)
    }

    /// Il confronto del TFR di Marco (scene 204–206): contributi del lavoratore e del datore in un fondo negoziale.
    nonisolated private static func preparaTFR(_ s: StatoShell) {
        s.clienteAttivoId = "marco"
        var i = s.ipotesiTFR("marco")
        i.contributoLavoratore = 1.2
        i.contributoDatore = 1.6
        i.canale = .indipendente
        i.nomeFondo = "Fondo negoziale di categoria"
        s.salvaIpotesiTFR("marco", i)
    }

    // MARK: - Disegno (solo Mac)
    // Su iPhone e iPad le scene si scattano nel simulatore (iOS/IstantaneeMobile.swift); qui restano comuni
    // solo l'elenco delle scene e la loro preparazione.

    #if os(macOS)
    /// Metodi di disegno, in ordine di preferenza sul server di build:
    /// - "finestra": NSHostingView in una finestra fuori schermo + cacheDisplay (senza Metal)
    /// - "livello": come sopra, ma con CALayer.render(in:)
    /// - "renderer": ImageRenderer di SwiftUI (richiede Metal)
    static func genera(in cartella: URL, metodo: String, solo: Set<String>? = nil) -> Int32 {
        _ = NSApplication.shared
        // I PNG non catturano i materiali di sistema né il vetro di macOS 26: vetro disegnato, più coprente
        Vetro.semplificato = true
        do {
            try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        } catch {
            print("ERRORE: cartella delle istantanee non creata: \(error.localizedDescription)")
            return 1
        }
        // Le scene comuni e quelle della mini finestra di Vera (solo Mac: IstantaneeMiniVera.swift)
        // Unite una per volta: una catena lunga di `+` mette in difficoltà il controllo dei tipi
        var tutteLeScene = scene
        tutteLeScene += sceneMiniVera
        tutteLeScene += sceneVeraScrivania
        tutteLeScene += sceneVeraApple
        tutteLeScene += sceneScenariVera
        tutteLeScene += scenePosizioniApple
        tutteLeScene += sceneDossierApple
        tutteLeScene += sceneSimulatoriApple
        tutteLeScene += sceneAnalisi360Apple
        tutteLeScene += sceneAgendaApple
        tutteLeScene += sceneProspettiApple
        tutteLeScene += sceneAnnoInsieme
        tutteLeScene += sceneTavolo
        tutteLeScene += sceneImpostazioniApple
        // «Orizzonte», giro 1: scrivania con «Il tuo studio», Novità, Studio › Cruscotto, Impostazioni › Studio
        tutteLeScene += sceneStudio
        // «Orizzonte», giro 2: Studio › Parcelle e fatture e Impostazioni › Studio › Dati per le fatture (IstantaneeParcelle.swift)
        tutteLeScene += sceneParcelle
        // «Orizzonte», giro 2: Studio › Track record (IstantaneeTrackRecord.swift)
        tutteLeScene += sceneTrackRecord
        // «Orizzonte», giro 3: Messaggi, «Prisma scrive per te» (IstantaneeMessaggi.swift)
        tutteLeScene += sceneMessaggi
        // «Orizzonte», giro 4: Posizioni › Prova del fuoco (IstantaneeProvaFuoco.swift)
        tutteLeScene += sceneProvaFuoco
        // «Orizzonte», giro 4: Clienti › Dossier › La linea della vita (Shell/IstantaneeLineaVita.swift)
        tutteLeScene += sceneLineaVita
        // «Orizzonte», giro 5: Inquadra e capisci, la scena del Mac (Shell/IstantaneeInquadra.swift)
        tutteLeScene += sceneInquadra
        // «Orizzonte», giro 5: Incontri › Il copilota dell'incontro (Shell/IstantaneeCopilota.swift)
        tutteLeScene += sceneCopilota
        // «Orizzonte», giro 8: Impostazioni › iPhone e iPad, «Prisma ovunque» (Shell/IstantaneeOvunque.swift)
        tutteLeScene += sceneOvunque
        // «Orizzonte», giro 7: Mercato, «Prisma conosce il mercato» (Shell/IstantaneeMercato.swift)
        tutteLeScene += sceneMercato
        // «Orizzonte», giro 6: Analisi 360 › Rispetto alle famiglie come la sua (Shell/IstantaneeFamiglie.swift)
        tutteLeScene += sceneFamiglie
        // «Orizzonte», giro 6: Studio › Esame OCF (Shell/IstantaneeEsameOCF.swift)
        tutteLeScene += sceneEsameOCF
        // «Luce», giro 1: Novità a due gruppi, scrivania, icone, app nuove, glifi, la Sala (Shell/IstantaneeLuce.swift)
        tutteLeScene += sceneLuce
        // «Luce», giro 2: Posizioni › Radar e Impostazioni › Portafogli modello (Shell/IstantaneeRadar.swift)
        tutteLeScene += sceneRadar
        // «Luce», giro 2: Posizioni › Smontaggio (Shell/IstantaneeSmontaggio.swift)
        tutteLeScene += sceneSmontaggio
        // «Luce», giro 3: Pratiche › Dopo la firma (Shell/IstantaneePraticheDopo.swift)
        tutteLeScene += scenePraticheDopo
        // «Luce», giro 3: Pratiche › Proposta, la proposta si costruisce da sola (Shell/IstantaneePraticheProposta.swift)
        tutteLeScene += scenePraticheProposta
        for scena in tutteLeScene where solo?.contains(scena.nome) ?? true {
            // Un pool per scena: senza il ciclo degli eventi (si esce in PrismaApp.init) niente lo svuoterebbe,
            // e stato, finestra e bitmap di ogni scena resterebbero in memoria fino all'ultima istantanea
            let riuscita: Bool = autoreleasepool { () -> Bool in
                let stato = StatoShell(persistente: false)
                let misura = misuraLuce(scena.nome) ?? (scena.nome.hasSuffix("-schermo-basso") ? dimensioneBassa : dimensione)
                // Le scene "-scuro" in aspetto scuro: finestra, ambiente SwiftUI e impostazione
                let scuro = scena.nome.hasSuffix("-scuro")
                if scuro { stato.dati.impostazioni.aspetto = .scuro }
                scena.prepara(stato)
                stato.area = ShellView.area(per: misura, dockNascosto: !stato.finestreVisibili.isEmpty)
                // La mini finestra di Vera è un pannello a parte: qui si disegna sopra la shell, dove compare
                let vetrina = sceneVetrina.contains(scena.nome)
                // Il foglio della fattura a grandezza piena (515): solo la carta, sempre chiara
                let carta = cartaIstantanea(scena.nome, stato) ?? tavolaLuce(scena.nome)
                let vista = ZStack(alignment: .topTrailing) {
                    if vetrina {
                        VetrinaApple(intensita: stato.dati.impostazioni.pioggia.forza)
                    } else if let carta {
                        carta
                    } else {
                        ShellView()
                        if stato.miniVera.aperta {
                            VistaMiniVera()
                                .padding(.top, Tema.Misura.barra + Tema.Misura.MiniVera.distanzaBarra - Tema.Misura.MiniVera.margineOmbraSopra)
                                .padding(.trailing, Tema.Misura.MiniVera.distanzaDestra - Tema.Misura.MiniVera.margineOmbraLati)
                        }
                    }
                }
                    .environmentObject(stato)
                    .environmentObject(stato.miniVera)
                    .environment(\.modoIstantanea, true)
                    .environment(\.colorScheme, scuro ? .dark : .light)
                    .frame(width: misura.width, height: misura.height)
                let aspetto = NSAppearance(named: scuro ? .darkAqua : .aqua)
                let png: Data?
                switch metodo {
                case "renderer": png = conRenderer(vista, aspetto: aspetto)
                case "livello": png = conFinestra(vista, livello: true, misura: misura, aspetto: aspetto)
                default: png = conFinestra(vista, livello: false, misura: misura, aspetto: aspetto)
                }
                guard let png else {
                    print("ERRORE: istantanea \(scena.nome) non disegnata (metodo \(metodo))")
                    return false
                }
                do {
                    try png.write(to: cartella.appendingPathComponent("\(scena.nome).png"))
                    print("OK: \(scena.nome).png (metodo \(metodo))")
                } catch {
                    print("ERRORE: \(scena.nome).png non salvata: \(error.localizedDescription)")
                    return false
                }
                return true
            }
            guard riuscita else { return 1 }
        }
        return 0
    }

    /// Disegna con l'aspetto dato (chiaro o scuro): i colori dinamici del tema si risolvono così.
    private static func conAspetto(_ aspetto: NSAppearance?, _ disegna: () -> Void) {
        if let aspetto {
            aspetto.performAsCurrentDrawingAppearance(disegna)
        } else {
            disegna()
        }
    }

    private static func conRenderer<V: View>(_ vista: V, aspetto: NSAppearance?) -> Data? {
        let renderer = ImageRenderer(content: vista)
        renderer.scale = 2
        var immagine: CGImage?
        conAspetto(aspetto) { immagine = renderer.cgImage }
        guard let cg = immagine else { return nil }
        return pngVerificato(NSBitmapImageRep(cgImage: cg))
    }

    private static func conFinestra<V: View>(_ vista: V, livello: Bool, misura: CGSize, aspetto: NSAppearance?) -> Data? {
        let host = NSHostingView(rootView: vista)
        host.frame = NSRect(origin: .zero, size: misura)
        host.appearance = aspetto
        let finestra = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        finestra.appearance = aspetto
        finestra.contentView = host
        finestra.setFrameOrigin(NSPoint(x: -20000, y: -20000))
        finestra.orderFront(nil)
        host.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        defer {
            finestra.orderOut(nil)
            // Il contenuto (e con lui lo stato della scena) si libera con la scena, dopo il disegno
            finestra.contentView = nil
        }

        if livello {
            let scala: CGFloat = 2
            guard let strato = host.layer,
                  let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                             pixelsWide: Int(misura.width * scala), pixelsHigh: Int(misura.height * scala),
                                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                             colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
                  let contesto = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
            let cg = contesto.cgContext
            cg.scaleBy(x: scala, y: scala)
            if host.isFlipped {
                cg.translateBy(x: 0, y: misura.height)
                cg.scaleBy(x: 1, y: -1)
            }
            conAspetto(aspetto) { strato.render(in: cg) }
            return pngVerificato(rep)
        }
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return nil }
        conAspetto(aspetto) { host.cacheDisplay(in: host.bounds, to: rep) }
        return pngVerificato(rep)
    }

    /// Scarta le immagini vuote (tutte dello stesso colore): vuol dire che il metodo non disegna.
    private static func pngVerificato(_ rep: NSBitmapImageRep) -> Data? {
        let campioni = [(0.1, 0.1), (0.5, 0.5), (0.9, 0.2), (0.3, 0.8), (0.7, 0.95), (0.5, 0.02)]
        let colori = campioni.compactMap { c in
            rep.colorAt(x: Int(Double(rep.pixelsWide) * c.0), y: Int(Double(rep.pixelsHigh) * c.1))?.usingColorSpace(.deviceRGB)
        }
        let diversi = Set(colori.map { "\(Int($0.redComponent * 255))-\(Int($0.greenComponent * 255))-\(Int($0.blueComponent * 255))" })
        guard diversi.count > 1 else {
            print("ATTENZIONE: immagine vuota")
            return nil
        }
        return rep.representation(using: .png, properties: [:])
    }
    #endif
}

/// L'ora ferma delle istantanee: oggi alle 10:24 (`Tema.Apple.Agenda.Giornata.oraIstantanea`). La usano
/// l'orologio della barra, quello del blocco e la linea rossa dell'Agenda, così che dicano tutti la stessa ora.
enum OraIstantanee {
    /// `data` alle 10:24 dello stesso giorno.
    static func data(_ data: Date = Date()) -> Date {
        let ora = Tema.Apple.Agenda.Giornata.oraIstantanea
        let ore = Int(ora)
        let minuti = Int(((ora - Double(ore)) * 60).rounded())
        return Calendar.current.date(bySettingHour: ore, minute: minuti, second: 0, of: data) ?? data
    }

    /// L'ora da mostrare: quella vera o, nelle istantanee, quella ferma.
    static func mostrata(_ data: Date, istantanea: Bool) -> Date {
        istantanea ? Self.data(data) : data
    }
}

private struct ChiaveModoIstantanea: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// true quando la vista viene disegnata per un'istantanea (niente viste AppKit).
    var modoIstantanea: Bool {
        get { self[ChiaveModoIstantanea.self] }
        set { self[ChiaveModoIstantanea.self] = newValue }
    }
}
