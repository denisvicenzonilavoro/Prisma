import Foundation

// MARK: - La mossa del giorno (scrivania, tema Apple §3.6)
// Il cliente su cui un'ora di lavoro vale di più oggi, con il motivo in una frase. Motore puro: niente
// SwiftUI, niente `StatoShell`, niente `Date()` nascosti (riceve `oggi`). Non inventa cifre: incrocia ciò che
// dicono gli altri motori (seguito delle proposte, riesami dovuti, scadenze delle posizioni, occasioni,
// completezza dei dati) e li pesa con `PesiMossaDelGiorno`. La Shell lo tiene da parte per un'ora
// (`StatoShell.mossaDelGiorno(oggi:)`, StatoMossaDelGiorno.swift).

/// I pesi della mossa del giorno, tutti qui. Ogni motivo dà punti; vince il cliente con più punti.
/// L'ordine voluto: una proposta ferma (lavoro già fatto che aspetta solo una telefonata) vale più di un
/// riesame scaduto, che vale più di una scadenza; le occasioni e i dati incompleti aggiungono, non decidono.
enum PesiMossaDelGiorno {
    // Proposte ferme (MotoreSeguitoProposte.inSospeso)
    /// Una proposta presentata e senza risposta, o rimandata e arrivata alla data di ripresa: l'analisi è già
    /// fatta, manca solo una telefonata. È la mossa che rende di più, quindi il peso più alto.
    static let propostaFerma = 40
    /// Un punto per ogni giorno oltre la soglia del seguito (Impostazioni › Proposte): più resta ferma, più si
    /// raffredda. Per le rimandate con una data di ripresa i giorni contano dalla ripresa.
    static let propostaPerGiorno = 1
    /// Al massimo 20 punti per i giorni: oltre, una proposta vecchia non deve schiacciare tutto il resto.
    static let propostaGiorniMassimi = 20
    /// Ferma da più del doppio della soglia (`PropostaInSospeso.urgente`, in rosso nel widget): rischia di perdersi.
    static let propostaUrgente = 10
    /// Ogni altra proposta ferma dello stesso cliente: si riprendono nella stessa telefonata.
    static let propostaAltra = 5

    // Riesame annuale (MotoreRiesame.dovuti)
    /// Riesame scaduto (un anno dall'ultimo contatto, niente in agenda): è un impegno di servizio verso il cliente.
    static let riesameScaduto = 30
    /// Due punti per ogni mese di ritardo sul riesame...
    static let riesamePerMese = 2
    /// ...fino a 10 punti (5 mesi): un ritardo lungo pesa, ma non più di una proposta ferma.
    static let riesameRitardoMassimo = 10
    /// Posizioni in essere ma nessun incontro registrato: il riesame manca del tutto, vale come uno scaduto.
    static let riesameMai = 30
    /// Riesame che scade nei prossimi mesi (`MotoreRiesame.mesiAvanti`): conviene fissarlo, ma non brucia.
    static let riesameInArrivo = 10

    // Scadenze delle posizioni in essere (entro `RiepilogoPosizioni.giorniScadenza`, 90 giorni)
    /// Una posizione in essere che scade entro 90 giorni (o è scaduta da meno di 90 e risulta ancora in essere):
    /// un capitale da destinare o una copertura da rinnovare. I debiti non contano (la fine del mutuo non chiede
    /// una telefonata).
    static let scadenza = 20
    /// Fino a 25 punti in più man mano che la scadenza si avvicina: 25 se scade oggi (o è già scaduta), 0 a 90 giorni.
    static let scadenzaVicinanza = 25
    /// Un punto ogni 5.000 € di valore della posizione...
    static let scadenzaEuroPerPunto = 5_000.0
    /// ...fino a 15 punti: un capitale grande in scadenza pesa di più, ma non decide da solo.
    static let scadenzaValoreMassimo = 15
    /// I punti della scadenza si dividono per 2 se in agenda c'è già un appuntamento collegato a quella posizione:
    /// la cosa è già avviata.
    static let divisoreGiaInAgenda = 2

    // Occasioni (MotoreOccasioni, entro l'anticipo delle notifiche: Impostazioni › Occasioni)
    /// Un'occasione importante (caso morte sotto il debito, pensione vicina, scadenza fiscale…): da sola basta
    /// a superare la soglia, perché chiede un'azione con una data.
    static let occasioneAlta = 15
    /// Un'occasione di media importanza: conta, ma da sola non basta.
    static let occasioneMedia = 6
    /// Un'occasione minore (una ricorrenza): aggiunge poco.
    static let occasioneBassa = 2
    /// Le occasioni di un cliente si sommano fino a 30 punti: tante date piccole non valgono una proposta ferma.
    static let occasioniMassimo = 30

    // Completezza dei dati (MotoreCompletezza): conta solo per chi ha già un altro motivo
    /// Dati scarsi per l'analisi: nello stesso incontro si completano, quindi l'ora vale di più.
    static let datiScarsi = 8
    /// Dati parziali: aggiungono poco.
    static let datiParziali = 3

    // Insieme
    /// Due motivi diversi (proposta, riesame, scadenza, occasione) sullo stesso cliente: con un solo incontro
    /// chiudi due cose.
    static let dueMotivi = 10
    /// Sotto questa soglia non c'è una mossa: la scrivania mostra la frase calma. Un'occasione media con i dati
    /// scarsi (6 + 8 = 14) resta sotto; un'occasione importante (15) o una scadenza vicina la superano.
    static let sogliaMinima = 15

    /// Tutti i pesi con il loro perché (per la prova e per chi vuole capire il punteggio).
    static let tabella: [(nome: String, peso: Double, perche: String)] = [
        ("propostaFerma", Double(propostaFerma), "Una proposta ferma aspetta solo una telefonata: il lavoro che rende di più."),
        ("propostaPerGiorno", Double(propostaPerGiorno), "Ogni giorno oltre la soglia del seguito la proposta si raffredda."),
        ("propostaGiorniMassimi", Double(propostaGiorniMassimi), "Una proposta vecchia non schiaccia tutto il resto."),
        ("propostaUrgente", Double(propostaUrgente), "Oltre il doppio della soglia rischia di perdersi."),
        ("propostaAltra", Double(propostaAltra), "Più proposte dello stesso cliente si riprendono insieme."),
        ("riesameScaduto", Double(riesameScaduto), "Il riesame annuale è un impegno di servizio verso il cliente."),
        ("riesamePerMese", Double(riesamePerMese), "Ogni mese di ritardo sul riesame pesa un po' di più."),
        ("riesameRitardoMassimo", Double(riesameRitardoMassimo), "Il ritardo non vale più di una proposta ferma."),
        ("riesameMai", Double(riesameMai), "Posizioni in essere senza nessun incontro: il riesame manca del tutto."),
        ("riesameInArrivo", Double(riesameInArrivo), "Un riesame vicino conviene fissarlo, ma non brucia."),
        ("scadenza", Double(scadenza), "Un capitale da destinare o una copertura da rinnovare entro 90 giorni."),
        ("scadenzaVicinanza", Double(scadenzaVicinanza), "Più la scadenza è vicina, più è urgente."),
        ("scadenzaEuroPerPunto", scadenzaEuroPerPunto, "Un punto ogni 5.000 € di valore in scadenza."),
        ("scadenzaValoreMassimo", Double(scadenzaValoreMassimo), "Il valore conta, ma non decide da solo."),
        ("divisoreGiaInAgenda", Double(divisoreGiaInAgenda), "Con un appuntamento già fissato sulla posizione la cosa è avviata."),
        ("occasioneAlta", Double(occasioneAlta), "Un'occasione importante chiede un'azione con una data."),
        ("occasioneMedia", Double(occasioneMedia), "Un'occasione media conta, ma da sola non basta."),
        ("occasioneBassa", Double(occasioneBassa), "Un'occasione minore aggiunge poco."),
        ("occasioniMassimo", Double(occasioniMassimo), "Tante date piccole non valgono una proposta ferma."),
        ("datiScarsi", Double(datiScarsi), "Con i dati scarsi lo stesso incontro serve anche a completarli."),
        ("datiParziali", Double(datiParziali), "Con i dati parziali l'incontro vale appena di più."),
        ("dueMotivi", Double(dueMotivi), "Con un solo incontro si chiudono due cose."),
        ("sogliaMinima", Double(sogliaMinima), "Sotto questa soglia non c'è niente di urgente."),
    ]
}

/// La mossa del giorno: il cliente, il punteggio, il motivo in una frase e ciò che serve per prepararsi.
struct MossaDelGiorno: Equatable {
    /// Da dove viene un motivo.
    enum Tipo: String, Equatable {
        case propostaFerma, riesame, scadenza, occasione, datiIncompleti

        /// A parità di punti, l'ordine dei motivi nella frase (lo stesso dei pesi).
        var ordine: Int {
            switch self {
            case .propostaFerma: return 0
            case .riesame: return 1
            case .scadenza: return 2
            case .occasione: return 3
            case .datiIncompleti: return 4
            }
        }
    }

    /// Un motivo per chiamare il cliente, con i suoi punti e la frase (in minuscolo: si compone nel motivo).
    struct Segnale: Equatable {
        let tipo: Tipo
        let punti: Int
        let frase: String
        /// La posizione di cui si parla (proposta, scadenza, occasione di un contratto).
        var posizione: Posizione? = nil
        /// Il canale del motivo (della posizione o dell'occasione), nil se non c'è.
        var canale: Canale? = nil
        /// Il gruppo dell'occasione (per il tipo d'incontro della bozza).
        var gruppoOccasione: GruppoOccasione? = nil
    }

    let cliente: Cliente
    let punteggio: Int
    /// Una frase breve in italiano con il dato concreto, che finisce con il punto.
    let motivo: String
    /// Il canale del motivo principale (o quello comune delle posizioni del cliente); nil: neutro, senza etichetta.
    let canale: Canale?
    /// I motivi, dal più forte.
    let segnali: [Segnale]
    /// L'appuntamento per «Preparami l'incontro»: il prossimo in agenda del cliente o una bozza (non salvata).
    let appuntamento: Appuntamento
    /// true se `appuntamento` è davvero in agenda.
    let appuntamentoInAgenda: Bool
    /// I report adatti all'incontro, scelti come il fascicolo dell'Agenda (`TipoProspetto.perIncontro`).
    let report: Set<TipoProspetto>

    /// I report nell'ordine del fascicolo.
    var reportOrdinati: [TipoProspetto] { TipoProspetto.inFascicolo.filter { report.contains($0) } }

    /// «Chiama Marco Bianchi»; con l'incontro già oggi in agenda «Prepara l'incontro con Marco Bianchi».
    func titolo(oggi: Date) -> String {
        if appuntamentoInAgenda && Calendar.current.isDate(appuntamento.inizio, inSameDayAs: oggi) {
            return "Prepara l'incontro con \(cliente.nome)"
        }
        return "Chiama \(cliente.nome)"
    }
}

/// Ciò che mostra la scrivania: una mossa, o niente di urgente con una frase calma.
enum EsitoMossaDelGiorno: Equatable {
    case mossa(MossaDelGiorno)
    case calma(titolo: String, frase: String)

    var mossa: MossaDelGiorno? {
        if case .mossa(let m) = self { return m }
        return nil
    }
}

enum MotoreMossaDelGiorno {
    /// Le frasi calme.
    static let titoloCalma = "Niente di urgente oggi"
    static let fraseCalma = "Proposte, riesami e scadenze sono in ordine: è un buon giorno per guardare con calma le posizioni dei clienti."
    static let fraseVuota = "Quando aggiungi clienti e posizioni, qui trovi ogni giorno il cliente da cui partire."

    /// Ciò che il motore incrocia, già calcolato dagli altri motori (la Shell lo prende dalle sue cache).
    struct Ingressi {
        let clienti: [Cliente]
        let posizioni: [Posizione]
        let appuntamenti: [Appuntamento]
        /// MotoreSeguitoProposte.inSospeso
        let proposte: [PropostaInSospeso]
        /// La soglia del seguito usata per `proposte` (Impostazioni › Proposte).
        let sogliaSeguito: Int
        /// MotoreRiesame.dovuti
        let riesami: [RiesameDovuto]
        /// MotoreOccasioni.calcola da oggi a oggi + anticipo (come le notifiche).
        let occasioni: [Occasione]
        /// MotoreCompletezza per un cliente (si chiede solo per chi ha già un altro motivo).
        let completezza: (Cliente) -> CompletezzaCliente?
        let oggi: Date
    }

    // MARK: - Dai dati grezzi

    /// La mossa del giorno calcolando tutto dai dati (prove, giorni diversi da oggi).
    static func calcola(clienti: [Cliente], posizioni: [Posizione], appuntamenti: [Appuntamento], attivita: [Attivita],
                        incontri: [Incontro], prodotti: [Prodotto], analisi: [String: Analisi360],
                        regoleOccasioni: ImpostazioniOccasioni = ImpostazioniOccasioni(),
                        sogliaSeguito: Int = Impostazioni.giorniSeguitoPredefiniti, oggi: Date) -> EsitoMossaDelGiorno {
        let cal = Calendar.current
        let inizio = cal.startOfDay(for: oggi)
        let fine = cal.date(byAdding: .day, value: regoleOccasioni.anticipoGiorni + 1, to: inizio) ?? inizio
        let proposte = MotoreSeguitoProposte.inSospeso(posizioni: posizioni, clienti: clienti, appuntamenti: appuntamenti,
                                                       attivita: attivita, adesso: oggi, soglia: sogliaSeguito)
        let riesami = MotoreRiesame.dovuti(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti,
                                           incontri: incontri, oggi: oggi)
        let occasioni = MotoreOccasioni.calcola(clienti: clienti, posizioni: posizioni, prodotti: prodotti, da: inizio, a: fine,
                                                regole: regoleOccasioni, oggi: oggi)
        let perCliente = Dictionary(grouping: posizioni, by: \.clienteId)
        let ingressi = Ingressi(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti, proposte: proposte,
                                sogliaSeguito: sogliaSeguito, riesami: riesami, occasioni: occasioni,
                                completezza: { c in
                                    MotoreCompletezza.calcola(cliente: c, posizioni: perCliente[c.id] ?? [], analisi: analisi[c.id], oggi: inizio)
                                },
                                oggi: oggi)
        return scegli(ingressi)
    }

    // MARK: - La scelta

    /// Pesa i motivi di ogni cliente e sceglie quello con più punti (a parità, per nome).
    static func scegli(_ x: Ingressi) -> EsitoMossaDelGiorno {
        guard !x.clienti.isEmpty else { return .calma(titolo: titoloCalma, frase: fraseVuota) }
        let cal = Calendar.current
        let inizio = cal.startOfDay(for: x.oggi)
        var visibili = Set<String>()
        for c in x.clienti { visibili.insert(c.id) }

        // Gli appuntamenti futuri in agenda: per cliente (il prossimo) e per posizione (scadenza già avviata)
        var prossimoPer: [String: Appuntamento] = [:]
        var posizioniInAgenda = Set<String>()
        for a in x.appuntamenti where a.stato == .pianificato && a.inizio >= inizio {
            if let pid = a.posizioneId { posizioniInAgenda.insert(pid) }
            if let attuale = prossimoPer[a.clienteId], attuale.inizio <= a.inizio { continue }
            prossimoPer[a.clienteId] = a
        }

        var segnali: [String: [MossaDelGiorno.Segnale]] = [:]
        aggiungiProposte(x, visibili: visibili, a: &segnali)
        aggiungiRiesami(x, visibili: visibili, a: &segnali)
        aggiungiScadenze(x, visibili: visibili, inAgenda: posizioniInAgenda, a: &segnali)
        aggiungiOccasioni(x, visibili: visibili, a: &segnali)

        // Il punteggio di ogni cliente con almeno un motivo, più i dati incompleti e i due motivi
        var migliore: (cliente: Cliente, punti: Int, segnali: [MossaDelGiorno.Segnale])?
        var visti = Set<String>()
        for c in x.clienti where visti.insert(c.id).inserted {
            guard var suoi = segnali[c.id], !suoi.isEmpty else { continue }
            let tipi = Set(suoi.map(\.tipo))
            if let dati = segnaleDati(x.completezza(c)) { suoi.append(dati) }
            var punti = suoi.reduce(0) { $0 + $1.punti }
            if tipi.count >= 2 { punti += PesiMossaDelGiorno.dueMotivi }
            suoi.sort { $0.punti != $1.punti ? $0.punti > $1.punti : $0.tipo.ordine < $1.tipo.ordine }
            if let m = migliore {
                if punti < m.punti { continue }
                if punti == m.punti && c.nome.localizedCompare(m.cliente.nome) != .orderedAscending { continue }
            }
            migliore = (cliente: c, punti: punti, segnali: suoi)
        }
        guard let m = migliore, m.punti >= PesiMossaDelGiorno.sogliaMinima, let primo = m.segnali.first else {
            return .calma(titolo: titoloCalma, frase: fraseCalma)
        }

        let prossimo = prossimoPer[m.cliente.id]
        let appuntamento = prossimo ?? bozza(m.cliente, principale: primo, oggi: x.oggi)
        // Il fascicolo come dall'Agenda: dal tipo d'incontro e dalla posizione di cui si parla
        let posizione = appuntamento.posizioneId.flatMap { id in x.posizioni.first { $0.id == id } } ?? primo.posizione
        let report = TipoProspetto.perIncontro(appuntamento, posizione: posizione, oggi: x.oggi)
        let canale = primo.canale ?? m.segnali.lazy.compactMap(\.canale).first ?? canaleComune(m.cliente.id, x.posizioni)
        return .mossa(MossaDelGiorno(cliente: m.cliente, punteggio: m.punti, motivo: frase(m.segnali), canale: canale,
                                     segnali: m.segnali, appuntamento: appuntamento, appuntamentoInAgenda: prossimo != nil,
                                     report: report))
    }

    // MARK: - I motivi

    private static func aggiungiProposte(_ x: Ingressi, visibili: Set<String>, a segnali: inout [String: [MossaDelGiorno.Segnale]]) {
        typealias P = PesiMossaDelGiorno
        // `inSospeso` è già dalla più ferma: la prima di ogni cliente pesa per intero, le altre poco
        for s in x.proposte where visibili.contains(s.cliente.id) {
            let id = s.cliente.id
            if segnali[id]?.contains(where: { $0.tipo == .propostaFerma }) == true {
                segnali[id, default: []].append(MossaDelGiorno.Segnale(tipo: .propostaFerma, punti: P.propostaAltra,
                                                                       frase: "c'è un'altra proposta ferma",
                                                                       posizione: s.posizione, canale: s.posizione.canale))
                continue
            }
            let oltre = s.fonte == .ripresa ? s.giorni : s.giorni - x.sogliaSeguito
            let perGiorni = min(max(0, oltre) * P.propostaPerGiorno, P.propostaGiorniMassimi)
            let punti = P.propostaFerma + perGiorni + (s.urgente ? P.propostaUrgente : 0)
            segnali[id, default: []].append(MossaDelGiorno.Segnale(tipo: .propostaFerma, punti: punti, frase: fraseProposta(s),
                                                                   posizione: s.posizione, canale: s.posizione.canale))
        }
    }

    private static func aggiungiRiesami(_ x: Ingressi, visibili: Set<String>, a segnali: inout [String: [MossaDelGiorno.Segnale]]) {
        typealias P = PesiMossaDelGiorno
        let cal = Calendar.current
        for r in x.riesami where visibili.contains(r.cliente.id) {
            guard segnali[r.cliente.id]?.contains(where: { $0.tipo == .riesame }) != true else { continue }
            let punti: Int
            let testo: String
            if r.ultimoContatto == nil {
                punti = P.riesameMai
                testo = "non c'è ancora stato un incontro di riesame"
            } else if r.scaduto(x.oggi), let dal = r.dovutoDal {
                let mesi = max(0, cal.dateComponents([.month], from: dal, to: x.oggi).month ?? 0)
                punti = P.riesameScaduto + min(mesi * P.riesamePerMese, P.riesameRitardoMassimo)
                testo = mesi >= 1 ? "il riesame annuale è scaduto da \(mesi == 1 ? "un mese" : "\(mesi) mesi")"
                                  : "il riesame annuale è scaduto"
            } else if let dal = r.dovutoDal {
                punti = P.riesameInArrivo
                testo = "il riesame annuale scade il \(Formati.giornoMese.string(from: dal))"
            } else {
                continue
            }
            segnali[r.cliente.id, default: []].append(MossaDelGiorno.Segnale(tipo: .riesame, punti: punti, frase: testo))
        }
    }

    private static func aggiungiScadenze(_ x: Ingressi, visibili: Set<String>, inAgenda: Set<String>,
                                         a segnali: inout [String: [MossaDelGiorno.Segnale]]) {
        typealias P = PesiMossaDelGiorno
        let limite = RiepilogoPosizioni.giorniScadenza
        // La scadenza più pesante di ogni cliente
        var migliori: [String: MossaDelGiorno.Segnale] = [:]
        for p in x.posizioni where p.stato == .inEssere && !p.area.passivo && visibili.contains(p.clienteId) {
            guard let s = p.scadenza else { continue }
            let giorni = MotoreSeguitoProposte.giorni(da: x.oggi, a: s)
            guard giorni <= limite, giorni >= -limite else { continue }
            let vicinanza = Double(P.scadenzaVicinanza) * Double(limite - max(0, giorni)) / Double(limite)
            let perValore = min(Int((max(0, p.valore) / P.scadenzaEuroPerPunto).rounded(.down)), P.scadenzaValoreMassimo)
            var punti = P.scadenza + Int(vicinanza.rounded()) + perValore
            if inAgenda.contains(p.id) { punti /= P.divisoreGiaInAgenda }
            if let attuale = migliori[p.clienteId], attuale.punti >= punti { continue }
            migliori[p.clienteId] = MossaDelGiorno.Segnale(tipo: .scadenza, punti: punti, frase: fraseScadenza(p, giorni: giorni),
                                                           posizione: p, canale: p.canale)
        }
        for (id, s) in migliori { segnali[id, default: []].append(s) }
    }

    private static func aggiungiOccasioni(_ x: Ingressi, visibili: Set<String>, a segnali: inout [String: [MossaDelGiorno.Segnale]]) {
        typealias P = PesiMossaDelGiorno
        let inizio = Calendar.current.startOfDay(for: x.oggi)
        var perCliente: [String: [Occasione]] = [:]
        for o in x.occasioni where visibili.contains(o.clienteId) && o.data >= inizio {
            perCliente[o.clienteId, default: []].append(o)
        }
        for (id, elenco) in perCliente {
            let somma = elenco.reduce(0) { (t: Int, o: Occasione) -> Int in
                switch o.importanza {
                case .alta: return t + P.occasioneAlta
                case .media: return t + P.occasioneMedia
                case .bassa: return t + P.occasioneBassa
                }
            }
            // La frase dice la più importante, la più vicina a parità
            let ordinate = elenco.sorted { a, b in a.importanza != b.importanza ? a.importanza < b.importanza : a.data < b.data }
            guard let prima = ordinate.first else { continue }
            let posizione = prima.posizioneId.flatMap { pid in x.posizioni.first { $0.id == pid } }
            let testo = "il \(Formati.giornoMese.string(from: prima.data)): \(prima.titolo)"
            segnali[id, default: []].append(MossaDelGiorno.Segnale(tipo: .occasione, punti: min(somma, P.occasioniMassimo),
                                                                   frase: testo, posizione: posizione, canale: prima.canale,
                                                                   gruppoOccasione: prima.tipo.gruppo))
        }
    }

    /// I dati incompleti contano solo accanto a un altro motivo (la Shell li chiede solo allora).
    private static func segnaleDati(_ c: CompletezzaCliente?) -> MossaDelGiorno.Segnale? {
        guard let c else { return nil }
        switch c.livello {
        case .completo:
            return nil
        case .parziale:
            return MossaDelGiorno.Segnale(tipo: .datiIncompleti, punti: PesiMossaDelGiorno.datiParziali,
                                          frase: "i dati per l'analisi sono completi al \(c.percentuale)%")
        case .scarso:
            return MossaDelGiorno.Segnale(tipo: .datiIncompleti, punti: PesiMossaDelGiorno.datiScarsi,
                                          frase: "i dati per l'analisi sono completi solo al \(c.percentuale)%")
        }
    }

    // MARK: - Le frasi

    private static func giorni(_ n: Int) -> String { n == 1 ? "un giorno" : "\(n) giorni" }

    private static func fraseProposta(_ s: PropostaInSospeso) -> String {
        let nome = "la proposta «\(s.posizione.nome)»"
        switch s.motivo {
        case .senzaRisposta:
            return "\(nome) è ferma da \(giorni(s.giorni))"
        case .daRiprendere:
            if s.fonte == .ripresa {
                return s.giorni <= 0 ? "\(nome) rimandata va ripresa oggi" : "\(nome) rimandata andava ripresa da \(giorni(s.giorni))"
            }
            return "\(nome) rimandata è ferma da \(giorni(s.giorni))"
        }
    }

    private static func fraseScadenza(_ p: Posizione, giorni n: Int) -> String {
        let quando = Formati.giornoMese.string(from: p.scadenza ?? Date.distantPast)
        if n < 0 { return "«\(p.nome)» è scaduta il \(quando) e risulta ancora in essere" }
        let verbo = n == 0 ? "scade oggi" : "scade il \(quando)"
        if p.area == .protezione { return "«\(p.nome)» \(verbo): la copertura va rinnovata" }
        if p.valore >= 1 { return "«\(p.nome)» \(verbo), con \(Formati.euro(p.valore)) da destinare" }
        return "«\(p.nome)» \(verbo)"
    }

    /// I due motivi più forti di tipo diverso, uniti da «e», con la maiuscola e il punto.
    static func frase(_ segnali: [MossaDelGiorno.Segnale]) -> String {
        var scelte: [String] = []
        var tipi = Set<MossaDelGiorno.Tipo>()
        for s in segnali where scelte.count < 2 && tipi.insert(s.tipo).inserted {
            scelte.append(s.frase)
        }
        return maiuscola(scelte.joined(separator: " e ")) + "."
    }

    /// La prima lettera in maiuscolo (salta le virgolette «).
    static func maiuscola(_ s: String) -> String {
        guard let i = s.firstIndex(where: { $0.isLetter }) else { return s }
        return s.replacingCharacters(in: i...i, with: String(s[i]).uppercased())
    }

    // MARK: - L'incontro da preparare

    /// Senza un appuntamento in agenda: una bozza (non salvata) con il tipo d'incontro adatto al motivo principale.
    private static func bozza(_ c: Cliente, principale s: MossaDelGiorno.Segnale, oggi: Date) -> Appuntamento {
        let tipo: TipoAppuntamento
        switch s.tipo {
        case .propostaFerma: tipo = .proposta
        case .riesame, .scadenza: tipo = .revisione
        case .occasione: tipo = s.gruppoOccasione == .contratti ? .analisi : .revisione
        case .datiIncompleti: tipo = .analisi
        }
        let cal = Calendar.current
        let inizio = cal.date(bySettingHour: 9, minute: 30, second: 0, of: oggi) ?? oggi
        return Appuntamento(id: "mossa-\(c.id)", clienteId: c.id, titolo: maiuscola(s.frase), inizio: inizio, durataMinuti: 45,
                            luogo: "", note: "", stato: .pianificato, tipo: tipo, canale: s.canale, posizioneId: s.posizione?.id)
    }

    /// Il canale di tutte le posizioni aperte del cliente, se è uno solo.
    private static func canaleComune(_ id: String, _ posizioni: [Posizione]) -> Canale? {
        let canali = Set(posizioni.filter { $0.clienteId == id && $0.stato != .chiusa }.map(\.canale))
        return canali.count == 1 ? canali.first : nil
    }
}
