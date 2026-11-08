#if os(macOS)
import Foundation

/// Le istantanee della fase 4 di Vera (Vera/BRIEF.md, Design/template-vera.html), chiare e scure, senza Qwen (risposte
/// preparate: bozze e cifre di Prisma): le routine (3), l'agenda che si organizza (4), il tagliando dei dati (5), il
/// sussurro (7), il mercato per i tuoi clienti (14), scrive come te (15), tre livelli (17) e ragiona a passi (20).
/// I numeri sono quelli liberi tra 499 e 553 (497, 498, 500, 503, 505 e 510-516 sono già di altre schermate).
extension Istantanee {
    nonisolated static var sceneFaseQuattroVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        // Unite una per volta, come in Istantanee.genera: una catena lunga di `+` mette in difficoltà il controllo dei tipi
        var scene = sceneRoutineVera
        scene += sceneAgendaOrganizzaVera
        scene += sceneTagliandoVera
        scene += sceneSussurroVera
        scene += sceneMercatoClientiVera
        scene += sceneStileVera
        scene += sceneTreLivelliVera
        scene += scenePassiVera
        return scene
    }

    // MARK: - Le routine (funzione 3)

    /// «Prepara l'incontro» lanciata in chat per Marco (passi spuntati, scaletta con i minuti, scheda «Conferma» con
    /// l'ordine del giorno) e la pagina delle routine con l'elenco e l'ultimo lancio. Giorno fisso: oggi alle 8:00 (i
    /// dati di prova partono da oggi), con l'incontro di Marco alle 11:00 in videochiamata come nel template.
    nonisolated static var sceneRoutineVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("499-vera-routine", { s in preparaRoutineIncontro(s) }),
            ("499-vera-routine-scuro", { s in preparaRoutineIncontro(s) }),
            ("501-vera-routine-pagina", { s in preparaPaginaRoutine(s) }),
            ("501-vera-routine-pagina-scuro", { s in preparaPaginaRoutine(s) }),
        ]
    }

    nonisolated private static var oggiRoutine: Date {
        let cal = Calendar.current
        return cal.date(byAdding: .hour, value: 8, to: cal.startOfDay(for: Date())) ?? Date()
    }

    nonisolated private static func baseRoutine(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "marco"
        s.veraPortafoglio = false
        if let inizio = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: oggiRoutine) {
            s.dati.appuntamenti.append(Appuntamento(id: "event-routine-marco", clienteId: "marco", titolo: "Nuovi progetti di famiglia", inizio: inizio,
                                                    durataMinuti: 45, luogo: "Videochiamata", note: "", stato: .pianificato, tipo: .altro))
        }
    }

    nonisolated private static func lanciaPreparaMarco(_ s: StatoShell) {
        let frase = "Vera, prepara l'incontro con Marco"
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: frase), cliente: "marco", parla: false)
        if let r = s.routineVera(RoutineVera.idPrepara) {
            s.lanciaRoutine(r, richiesta: frase, clienteId: "marco", chiave: "marco", oggi: oggiRoutine, parla: false)
        }
    }

    nonisolated static func preparaRoutineIncontro(_ s: StatoShell) {
        baseRoutine(s)
        lanciaPreparaMarco(s)
        s.apri(.vera)
    }

    nonisolated static func preparaPaginaRoutine(_ s: StatoShell) {
        baseRoutine(s)
        lanciaPreparaMarco(s)
        // «Il mio lunedì» già lanciato sul portafoglio: nell'elenco «Usata una volta» accanto alla programmazione
        if let r = s.routineVera(RoutineVera.idLunedi) {
            s.lanciaRoutine(r, richiesta: "Vera, com'è la settimana?", clienteId: nil, chiave: VeraPortafoglio.chiave, oggi: oggiRoutine, parla: false)
        }
        s.apriPaginaRoutine(RoutineVera.idPrepara)
    }

    // MARK: - L'agenda che si organizza (funzione 4)

    /// A data fissa: la settimana del template (lunedì 2 – venerdì 6 novembre 2026, oggi lunedì 2 alle 8:00; Marco al
    /// posto di Federico) con i due orari proposti per il riesame di Marco e la bozza da confermare, la scelta «Marco ha
    /// scelto martedì» con la scheda che sposta il riesame, e lo spostamento in blocco «Libera giovedì, sposta tutto a venerdì».
    nonisolated static var sceneAgendaOrganizzaVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("502-vera-agenda-orari", { s in preparaAgendaOrari(s) }),
            ("502-vera-agenda-orari-scuro", { s in preparaAgendaOrari(s) }),
            ("504-vera-agenda-scelta", { s in preparaAgendaScelta(s) }),
            ("504-vera-agenda-scelta-scuro", { s in preparaAgendaScelta(s) }),
            ("506-vera-agenda-blocco", { s in preparaAgendaBlocco(s) }),
            ("506-vera-agenda-blocco-scuro", { s in preparaAgendaBlocco(s) }),
        ]
    }

    nonisolated private static func oraAgendaOrganizza(_ giorno: Int, _ ora: Int, _ minuti: Int = 0) -> Date {
        MotorePianificazione.calendario.date(from: DateComponents(year: 2026, month: 11, day: giorno, hour: ora, minute: minuti))
            ?? Date(timeIntervalSince1970: 0)
    }

    nonisolated private static var oggiAgendaOrganizza: Date { oraAgendaOrganizza(2, 8) }

    /// La settimana del template al posto degli impegni di quei giorni, gli orari di lavoro di sempre, il portafoglio di Vera.
    nonisolated private static func settimanaAgendaOrganizza(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.veraPortafoglio = true
        s.dati.impostazioni.orari = OrariLavoro()
        func app(_ id: String, _ cliente: String, _ titolo: String, _ inizio: Date, _ minuti: Int, _ luogo: String, _ tipo: TipoAppuntamento) -> Appuntamento {
            Appuntamento(id: id, clienteId: cliente, titolo: titolo, inizio: inizio, durataMinuti: minuti, luogo: luogo, note: "",
                         stato: .pianificato, tipo: tipo)
        }
        let dal = oraAgendaOrganizza(2, 0), al = oraAgendaOrganizza(7, 0)
        s.dati.appuntamenti.removeAll { $0.inizio >= dal && $0.inizio < al }
        s.dati.appuntamenti += [
            app("ist-giulia-lun", "giulia", "Il punto sul progetto casa", oraAgendaOrganizza(2, 9, 30), 45, "In studio", .analisi),
            app("ist-marco-lun", "marco", "Nuovi progetti di famiglia", oraAgendaOrganizza(2, 11), 60, "Videochiamata", .altro),
            app("ist-sofia-lun", "sofia", "Rinnovo del consenso", oraAgendaOrganizza(2, 15), 30, "Telefonata", .telefonata),
            app("ist-laura-mar", "laura", "Un progetto tutto suo", oraAgendaOrganizza(3, 10), 45, "In studio", .proposta),
            app("ist-formazione", "", "Formazione Alleanza", oraAgendaOrganizza(3, 14, 30), 60, "Online", .altro),
            app("ist-andrea-mer", "andrea", "Il nostro primo incontro", oraAgendaOrganizza(4, 15), 60, "In studio", .primoIncontro),
            app("ist-sofia-gio", "sofia", "Uno sguardo ai prossimi mesi", oraAgendaOrganizza(5, 11, 30), 30, "Telefonata", .telefonata),
            app("ist-giulia-gio", "giulia", "Firma del piano casa", oraAgendaOrganizza(5, 16), 60, "In studio", .firma),
            app("ist-marco-ven", "marco", "Riesame con Marco", oraAgendaOrganizza(6, 9), 60, "In studio", .revisione),
        ]
    }

    nonisolated static func preparaAgendaOrari(_ s: StatoShell) {
        settimanaAgendaOrganizza(s)
        _ = s.chiediAgendaOrganizza("Trovami un'ora per il riesame di Marco entro giovedì, attaccata a un altro incontro in studio",
                                    chiave: VeraPortafoglio.chiave, oggi: oggiAgendaOrganizza)
        s.apri(.vera)
    }

    nonisolated static func preparaAgendaScelta(_ s: StatoShell) {
        settimanaAgendaOrganizza(s)
        _ = s.chiediAgendaOrganizza("Trovami un'ora per il riesame di Marco entro giovedì, attaccata a un altro incontro in studio",
                                    chiave: VeraPortafoglio.chiave, oggi: oggiAgendaOrganizza)
        _ = s.sceltaDettaAgenda("Marco ha scelto martedì", chiave: VeraPortafoglio.chiave, oggi: oggiAgendaOrganizza)
        s.apri(.vera)
    }

    nonisolated static func preparaAgendaBlocco(_ s: StatoShell) {
        settimanaAgendaOrganizza(s)
        _ = s.chiediAgendaOrganizza("Libera giovedì, sposta tutto a venerdì", chiave: VeraPortafoglio.chiave, oggi: oggiAgendaOrganizza)
        s.apri(.vera)
    }

    // MARK: - Il tagliando dei dati (funzione 5)

    /// La pagina sopra la chat di Vera (anello della salute, «Controllate stanotte alle 2:10», voci a semaforo, «Sistema
    /// tutto») e la risposta in chat con la scheda. Come nel template: la scheda doppia «M. Bianchi» di Marco (stesso
    /// telefono) e il consenso privacy di Sofia mancante. Il controllo è di oggi alle 2:10, sui dati di prova costruiti
    /// attorno a oggi: le voci e il punteggio sono sempre gli stessi.
    nonisolated static var sceneTagliandoVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("507-vera-tagliando", { s in preparaTagliando(s, pagina: true) }),
            ("507-vera-tagliando-scuro", { s in preparaTagliando(s, pagina: true) }),
            ("508-vera-tagliando-chat", { s in preparaTagliando(s, pagina: false) }),
            ("508-vera-tagliando-chat-scuro", { s in preparaTagliando(s, pagina: false) }),
        ]
    }

    nonisolated static func preparaTagliando(_ s: StatoShell, pagina: Bool) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "marco"
        s.veraPortafoglio = true
        let cal = Calendar.current
        let stanotte = cal.date(bySettingHour: 2, minute: 10, second: 0, of: Date()) ?? Date()
        if let m = s.dati.clienti.firstIndex(where: { $0.id == "marco" }) {
            s.dati.clienti[m].telefono = "+39 333 000 1002"
            let doppia = Cliente(id: "m-bianchi-istantanea", nome: "M. Bianchi", iniziali: "MB", tinta: .blu, tema: "", email: "",
                                 telefono: "333 000 1002", preferito: false, nota: "",
                                 creatoIl: cal.date(byAdding: .day, value: -3, to: stanotte) ?? stanotte)
            s.dati.clienti.append(doppia)
        }
        if let i = s.dati.clienti.firstIndex(where: { $0.id == "sofia" }) {
            s.dati.clienti[i].consensi.privacy = false
            s.dati.clienti[i].consensi.dataPrivacy = nil
        }
        s.eseguiTagliando(adesso: stanotte)
        if pagina {
            s.apriPaginaTagliando()
        } else {
            _ = s.chiediTagliando("Fai il tagliando dell'archivio", chiave: VeraPortafoglio.chiave)
            s.apri(.vera)
        }
    }

    // MARK: - Il sussurro (funzione 7)

    /// La Panoramica del dossier di Sofia con «Vera ti sussurra» (consenso privacy mancante in rosso, la rivalutabile
    /// che scade con l'incontro «in scaletta», «Decide sempre insieme a Paolo» con «Invita Paolo») e la risposta in chat
    /// a «Cosa devo sapere su Sofia?» con la scheda «Conferma». Le date sono relative a oggi, come nella fase 3, perché
    /// la vista del dossier calcola con la data del giorno.
    nonisolated static var sceneSussurroVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("509-vera-sussurro-dossier", { s in preparaSussurroDossier(s) }),
            ("509-vera-sussurro-dossier-scuro", { s in preparaSussurroDossier(s) }),
            ("517-vera-sussurro-chat", { s in preparaSussurroChat(s) }),
            ("517-vera-sussurro-chat-scuro", { s in preparaSussurroChat(s) }),
        ]
    }

    /// I dati della scena del template su Sofia: consenso privacy mancante, la rivalutabile che scade fra 70 giorni con
    /// la revisione fra 4 giorni, il ricordo «Decide sempre insieme a Paolo».
    nonisolated static func datiSussurro(_ s: StatoShell) {
        let cal = Calendar.current
        let oggi = Date()
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        if let i = s.dati.clienti.firstIndex(where: { $0.id == "sofia" }) {
            s.dati.clienti[i].consensi = Consensi()
        }
        var p = Posizione(clienteId: "sofia", canale: .alleanza, stato: .inEssere, area: .risparmio, nome: "Polizza rivalutabile")
        p.id = "pos-sofia-sussurro"
        p.scadenza = cal.date(byAdding: .day, value: 70, to: oggi)
        p.controvalore = 48_000
        s.dati.posizioni.append(p)
        let giorno = cal.date(byAdding: .day, value: 4, to: cal.startOfDay(for: oggi)) ?? oggi
        let inizio = cal.date(bySettingHour: 10, minute: 0, second: 0, of: giorno) ?? giorno
        s.dati.appuntamenti.append(Appuntamento(id: "app-sofia-sussurro", clienteId: "sofia", titolo: "Revisione con Sofia", inizio: inizio,
                                                durataMinuti: 45, luogo: "In studio", note: "", stato: .pianificato, tipo: .revisione))
        _ = s.memoriaVera.ricorda("Decide sempre insieme a Paolo", cliente: "sofia", fonte: "in chat")
    }

    nonisolated static func preparaSussurroDossier(_ s: StatoShell) {
        datiSussurro(s)
        s.clienteAttivoId = "sofia"
        s.schedaCliente = .panoramica
        s.apri(.clienti)
    }

    nonisolated static func preparaSussurroChat(_ s: StatoShell) {
        datiSussurro(s)
        s.clienteAttivoId = "sofia"
        s.veraPortafoglio = false
        _ = s.chiediSussurro("Cosa devo sapere su Sofia?", chiave: "sofia")
        s.apri(.vera)
    }

    // MARK: - Il mercato per i tuoi clienti (funzione 14)

    /// Le borse −8% in una settimana dette a Vera sui dati del template con l'elenco dei clienti toccati; le bozze pronte
    /// nella scheda «Conferma» (quelle fisse di Prisma, con l'avviso: è il comportamento onesto senza Qwen); la scena di
    /// Mercato con l'esempio delle borse −8%.
    nonisolated static var sceneMercatoClientiVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("518-vera-mercato-clienti", { s in preparaMercatoClientiChat(s) }),
            ("518-vera-mercato-clienti-scuro", { s in preparaMercatoClientiChat(s) }),
            ("519-vera-mercato-bozze", { s in preparaMercatoClientiBozze(s) }),
            ("519-vera-mercato-bozze-scuro", { s in preparaMercatoClientiBozze(s) }),
            ("526-mercato-per-i-clienti", { s in preparaScenaMercatoClienti(s) }),
            ("526-mercato-per-i-clienti-scuro", { s in preparaScenaMercatoClienti(s) }),
        ]
    }

    nonisolated private static func baseMercatoClienti(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "marco"
        s.veraPortafoglio = true
    }

    nonisolated static func preparaMercatoClientiChat(_ s: StatoShell) {
        baseMercatoClienti(s)
        _ = s.chiediMercatoClienti("Le borse hanno perso l'8% in una settimana", chiave: VeraPortafoglio.chiave)
        s.apri(.vera)
    }

    nonisolated static func preparaMercatoClientiBozze(_ s: StatoShell) {
        baseMercatoClienti(s)
        _ = s.chiediMercatoClienti("La BCE taglia i tassi di 25 punti base", chiave: VeraPortafoglio.chiave)
        if let id = s.conversazione(VeraPortafoglio.chiave).last(where: { $0.mercatoClienti != nil })?.id {
            s.preparaBozzeMercatoClienti(messaggio: id)
        }
        s.apri(.vera)
    }

    nonisolated static func preparaScenaMercatoClienti(_ s: StatoShell) {
        baseMercatoClienti(s)
        s.veraPortafoglio = false
        s.apriMercatoClientiVera(scelta: SceltaMercatoClientiVera.idBorse)
    }

    // MARK: - Scrive come te (funzione 15)

    /// A data fissa (8 novembre 2026): il profilo del template in chat («Mostrami il mio stile») e la bozza generica
    /// del template riscritta nello stile per Giulia (37 anni: il tu), con i ritocchi e le regole da sistemare a mano.
    nonisolated static var sceneStileVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("527-vera-il-tuo-stile", { s in preparaStileProfilo(s) }),
            ("527-vera-il-tuo-stile-scuro", { s in preparaStileProfilo(s) }),
            ("528-vera-scrive-come-te", { s in preparaStileBozza(s) }),
            ("528-vera-scrive-come-te-scuro", { s in preparaStileBozza(s) }),
        ]
    }

    nonisolated static var giornoStile: Date {
        DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: .current, year: 2026, month: 11, day: 8, hour: 12).date ?? Date()
    }

    /// Il profilo del template: «Dai del tu ai clienti sotto i 40 anni», «Frasi brevi, una cosa per riga», «Prima il
    /// giorno e l'ora», «Firmi solo «Denis»», «Niente formule da ufficio», «Mai emoji con i clienti nuovi».
    nonisolated static func profiloStileDiProva() -> ProfiloStile {
        var p = ProfiloStile()
        p.cortesia = .imparata(CortesiaStile(predefinita: .lei, sogliaEta: 40), da: 214)
        p.lunghezzaFrasi = .imparata(14, da: 252)
        p.unaCosaPerRiga = .imparata(true, da: 188)
        p.primaGiornoEOra = .imparata(true, da: 96)
        p.firma = .scritta("Denis")
        p.formuleVietate = .imparata(["con la presente", "restiamo a disposizione", "per qualsiasi chiarimento", "cordiali saluti", "la preghiamo"], da: 252)
        p.emoji = .imparata(.soloClientiNoti, da: 252)
        p.aperture = .imparata(["Ciao ‹nome›,", "Gentile ‹nome›,"], da: 201)
        p.chiusure = .imparata(["A presto!", "A giovedì!"], da: 143)
        p.messaggiLetti = 214
        p.mailLette = 38
        p.aggiornatoIl = giornoStile
        return p
    }

    nonisolated private static func baseStile(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "giulia"
        s.veraPortafoglio = false
        s.dati.impostazioni.stileVera = profiloStileDiProva()
    }

    nonisolated static func preparaStileProfilo(_ s: StatoShell) {
        baseStile(s)
        _ = s.chiediStileVera("Mostrami il mio stile", chiave: "giulia", oggi: giornoStile)
        s.apri(.vera)
    }

    nonisolated static func preparaStileBozza(_ s: StatoShell) {
        baseStile(s)
        _ = s.chiediStileVera("Riscrivi nel mio stile per Giulia: Gentile Sig.ra Rossi,\ncon la presente Le ricordiamo l'appuntamento fissato per giovedì 5 novembre alle ore 16:00 presso il nostro ufficio, finalizzato alla sottoscrizione del piano.\nLa preghiamo di presentarsi munita di un documento di identità in corso di validità.\nRestiamo a disposizione per qualsiasi chiarimento.\nCordiali saluti.",
                              chiave: "giulia", oggi: giornoStile)
        s.apri(.vera)
    }

    // MARK: - Tre livelli (funzione 17)

    /// La domanda su Marco aperta sulla versione per te, sulla versione semplice per Marco e sulla pagina su carta bianca
    /// con le barre e l'avvertenza (bozza di Prisma, cifre dei motori).
    nonisolated static var sceneTreLivelliVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("529-vera-tre-livelli", { s in preparaTreLivelli(s, "Perché il fondo pensione conviene a Marco?") }),
            ("529-vera-tre-livelli-scuro", { s in preparaTreLivelli(s, "Perché il fondo pensione conviene a Marco?") }),
            ("550-vera-tre-livelli-cliente", { s in preparaTreLivelli(s, "Spiegalo in parole semplici a Marco: perché il fondo pensione conviene?") }),
            ("550-vera-tre-livelli-cliente-scuro", { s in preparaTreLivelli(s, "Spiegalo in parole semplici a Marco: perché il fondo pensione conviene?") }),
            ("551-vera-tre-livelli-pagina", { s in preparaTreLivelli(s, "Il fondo pensione di Marco in una pagina") }),
            ("551-vera-tre-livelli-pagina-scuro", { s in preparaTreLivelli(s, "Il fondo pensione di Marco in una pagina") }),
        ]
    }

    /// Marco nel dossier, Qwen «pronto» ma con le risposte preparate (quindi la bozza di Prisma), la domanda in chat.
    nonisolated static func preparaTreLivelli(_ s: StatoShell, _ domanda: String) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "marco"
        s.veraPortafoglio = false
        _ = s.chiediTreLivelli(domanda, chiave: "marco")
        s.apri(.vera)
    }

    // MARK: - Ragiona a passi (funzione 20)

    /// La frase del template sui dati di Marco (400 € al mese, protezione per Elena e studi), con il piano e la regola
    /// («Mostra il ragionamento» acceso) e senza (solo le tre divisioni, la spiegazione e la scheda «Conferma»). I dati
    /// di prova vivono intorno a oggi (l'Infortuni famiglia scade fra 45 giorni), come le istantanee della fase 3.
    nonisolated static var scenePassiVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("552-vera-ragiona-a-passi", { s in preparaPassi(s, ragionamento: true) }),
            ("552-vera-ragiona-a-passi-scuro", { s in preparaPassi(s, ragionamento: true) }),
            ("553-vera-passi-senza-ragionamento", { s in preparaPassi(s, ragionamento: false) }),
            ("553-vera-passi-senza-ragionamento-scuro", { s in preparaPassi(s, ragionamento: false) }),
        ]
    }

    nonisolated static let frasePassiIstantanea = "Marco ha 400 € al mese: vuole proteggere Elena e continuare con gli studi di Tommaso. Come li divido?"

    nonisolated static func preparaPassi(_ s: StatoShell, ragionamento: Bool) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "marco"
        s.veraPortafoglio = false
        s.dati.impostazioni.vera.passi.mostraRagionamento = ragionamento
        _ = s.chiediPassi(frasePassiIstantanea, chiave: "marco")
        s.apri(.vera)
    }
}
#endif
