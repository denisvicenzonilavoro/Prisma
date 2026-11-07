import Foundation

// Le occasioni per scrivere a un cliente (Messaggi, «Prisma scrive per te», Design/template-novita-specifica.md §5.5.2):
// solo regole, nessuna intelligenza artificiale. Le fonti sono quelle che Prisma calcola già: gli incontri conclusi
// di recente, le scadenze delle posizioni in essere, i compleanni (MotoreNotifiche.prossimoCompleanno), i consensi da
// rinnovare («In regola», MotoreConformita), i riesami dovuti (MotoreRiesame.dovuti), le occasioni importanti
// dell'Agenda (MotoreOccasioni), le parcelle da mandare o scadute (MotoreParcelle) e, dal giro 7, gli avvisi di
// Mercato nati con le soglie dell'utente (MotoreMercato.avvisi, `DatiPrisma.mercato.avvisi`).
// Motore puro: riceve i dati, `oggi` e il calendario; niente StatoShell. La Shell tiene il risultato in cache
// (DerivatiDati, StatoMessaggi.swift). Le cifre di ogni occasione sono le sole che il messaggio potrà citare.

/// Le soglie dei messaggi, tutte in un punto.
enum RegoleMessaggi {
    /// Una scadenza entra tra i messaggi tanti giorni prima (si cambia in Impostazioni › Messaggi).
    static let giorniScadenzaPredefiniti = 45
    /// Sotto questi giorni una scadenza va in «Da mandare oggi» anche se non è il primo giorno della soglia.
    static let giorniScadenzaVicina = 7
    /// Sotto questi giorni una scadenza ha la priorità alta.
    static let giorniScadenzaUrgente = 15
    /// Prima di quest'ora un incontro di oggi è «di stamattina».
    static let oraPomeriggio = 13
    /// Il riepilogo di un incontro concluso si propone per tanti giorni (oggi e ieri in «Da mandare oggi»).
    static let giorniRiepilogo = 6
    static let giorniRiepilogoOggi = 1
    /// «Questa settimana»: i prossimi sette giorni (oggi compreso).
    static let giorniSettimana = 7
    /// Una parcella emessa da al massimo tanti giorni è «da mandare» (oggi e ieri in «Da mandare oggi»).
    static let giorniParcellaDaMandare = 7
    /// Un messaggio aperto o salvato copre la sua occasione per tanti giorni.
    static let giorniCopertura = 90
    /// Al massimo tante occasioni per gruppo.
    static let massimoPerGruppo = 8
    /// Lunghezze: cordiale e formale al massimo 140 parole (Qwen può arrivare a 160), breve al massimo 320 caratteri
    /// con la firma, oggetto al massimo 60 caratteri.
    static let parole = 140
    static let paroleTollerate = 160
    static let caratteriBreve = 320
    static let caratteriOggetto = 60
    /// Nel tono breve lo spazio tenuto per il saluto e la firma quando si sceglie una frase più lunga.
    static let riservaBreve = 60
    /// Le decisioni dell'incontro nella scheda: al massimo tanti caratteri.
    static let caratteriDecisioni = 400
    /// Il prossimo passo dell'incontro nella scheda: al massimo tanti caratteri.
    static let caratteriPasso = 200
}

/// In quale gruppo dell'elenco di Messaggi cade un'occasione.
enum GruppoMessaggio: Int, Comparable, CaseIterable {
    case oggi, settimana

    static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }

    var titolo: String {
        switch self {
        case .oggi: return "Da mandare oggi"
        case .settimana: return "Questa settimana"
        }
    }
}

enum PrioritaMessaggio: Int, Comparable, CaseIterable {
    case alta, media, bassa

    static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
}

/// Un'occasione per scrivere a un cliente. Non si salva: si ricalcola dai dati (il messaggio scritto sì).
struct OccasioneMessaggio: Identifiable, Hashable {
    /// Stabile tra un calcolo e l'altro: "\(tipo)-\(clienteId)-\(riferimento)".
    let id: String
    let origine: OrigineMessaggio
    let clienteId: String
    /// Il canale di lavoro (Alleanza o indipendente) quando l'occasione ne ha uno; nil = etichetta neutra.
    let canale: Canale?
    let gruppo: GruppoMessaggio
    /// «"Infortuni famiglia" scade il 17 dicembre».
    let titolo: String
    /// «Perché adesso»: «Scadenza tra 45 giorni».
    let perche: String
    /// L'oggetto proposto per la mail (al massimo 60 caratteri).
    let oggetto: String
    /// Le cifre e i fatti dei motori che il messaggio può citare.
    let cifre: [CifraMessaggio]
    let priorita: PrioritaMessaggio
    /// Il giorno dell'evento (incontro, scadenza, compleanno, occasione, parcella): ordina a parità di tutto il resto.
    let data: Date
    /// Scaduto o in ritardo (consenso scaduto, parcella scaduta, riesame dovuto): cambia le parole del modello fisso.
    let inRitardo: Bool
    /// Un messaggio per questa occasione è stato aperto o salvato oggi: resta nell'elenco con la spunta fino a domani.
    var preparatoIl: Date?

    init(origine: OrigineMessaggio, clienteId: String, canale: Canale?, gruppo: GruppoMessaggio, titolo: String,
         perche: String, oggetto: String, cifre: [CifraMessaggio], priorita: PrioritaMessaggio, data: Date,
         inRitardo: Bool = false, preparatoIl: Date? = nil) {
        self.id = OccasioneMessaggio.id(tipo: origine.tipo, clienteId: clienteId, riferimento: origine.riferimento)
        self.origine = origine
        self.clienteId = clienteId
        self.canale = canale
        self.gruppo = gruppo
        self.titolo = titolo
        self.perche = perche
        self.oggetto = String(oggetto.prefix(RegoleMessaggi.caratteriOggetto))
        self.cifre = cifre
        self.priorita = priorita
        self.data = data
        self.inRitardo = inRitardo
        self.preparatoIl = preparatoIl
    }

    var tipo: TipoOccasioneMessaggio { origine.tipo }
    /// Propone qualcosa: serve il consenso commerciale.
    var commerciale: Bool { origine.tipo.commerciale }

    static func id(tipo: TipoOccasioneMessaggio, clienteId: String, riferimento: String) -> String {
        "\(tipo.rawValue)-\(clienteId)-\(riferimento)"
    }

    /// Il valore di una cifra (nil se l'occasione non ce l'ha).
    func valore(_ v: VoceCifraMessaggio) -> String? {
        cifre.first { $0.etichetta == v.rawValue }?.valore
    }
}

/// Le occasioni divise nei due gruppi di Messaggi, già ordinate.
struct OccasioniMessaggi: Equatable {
    let oggi: [OccasioneMessaggio]
    let settimana: [OccasioneMessaggio]

    static let vuote = OccasioniMessaggi(oggi: [], settimana: [])

    var tutte: [OccasioneMessaggio] { oggi + settimana }
    var nessuna: Bool { oggi.isEmpty && settimana.isEmpty }

    func occasione(_ id: String) -> OccasioneMessaggio? { tutte.first { $0.id == id } }

    /// Solo quelle di un cliente (modalità cliente).
    func soloCliente(_ id: String) -> OccasioniMessaggi {
        OccasioniMessaggi(oggi: oggi.filter { $0.clienteId == id }, settimana: settimana.filter { $0.clienteId == id })
    }
}

enum MotoreOccasioniMessaggi {
    // MARK: - Calcolo

    /// Le occasioni di oggi e della settimana per tutti i clienti dei dati, senza quelle già coperte da un messaggio
    /// aperto o salvato negli ultimi `RegoleMessaggi.giorniCopertura` giorni (quelle coperte oggi restano con
    /// `preparatoIl`). Ordine: gruppo, priorità, tipo, giorno, nome del cliente. Al massimo 8 per gruppo.
    static func calcola(dati: DatiPrisma, oggi: Date, cal: Calendar = .current) -> OccasioniMessaggi {
        let inizio = cal.startOfDay(for: oggi)
        var clienti: [String: Cliente] = [:]
        for c in dati.clienti where clienti[c.id] == nil { clienti[c.id] = c }
        let posizioni = Dictionary(grouping: dati.posizioni, by: \.clienteId)
        var elenco: [OccasioneMessaggio] = []
        elenco += riepiloghi(dati.incontri, clienti: clienti, posizioni: posizioni, oggi: oggi, cal: cal)
        elenco += scadenze(dati.posizioni, clienti: clienti, soglia: dati.impostazioni.messaggi.giorniScadenza, oggi: oggi, cal: cal)
        elenco += compleanni(dati.clienti, posizioni: posizioni, inizio: inizio, cal: cal)
        elenco += consensi(dati, oggi: oggi, cal: cal)
        elenco += riesami(dati, posizioni: posizioni, oggi: oggi, cal: cal)
        elenco += occasioniAgenda(dati, clienti: clienti, inizio: inizio, oggi: oggi, cal: cal)
        elenco += parcelle(dati.parcelle, clienti: clienti, oggi: oggi, cal: cal)
        elenco += avvisiMercato(dati.mercato.avvisi, clienti: clienti, posizioni: posizioni, oggi: oggi, cal: cal)
        return dividi(elenco, messaggi: dati.messaggi, clienti: clienti, oggi: oggi, cal: cal)
    }

    // MARK: - Fonti (pubbliche per le prove)

    /// Gli incontri conclusi da al massimo `giorniRiepilogo` giorni: il riepilogo da mandare.
    static func riepiloghi(_ incontri: [Incontro], clienti: [String: Cliente], posizioni: [String: [Posizione]],
                           oggi: Date, cal: Calendar) -> [OccasioneMessaggio] {
        incontri.compactMap { i -> OccasioneMessaggio? in
            guard i.stato == .concluso, i.data <= oggi, let c = clienti[i.clienteId] else { return nil }
            let g = giorni(da: i.data, a: oggi, cal: cal)
            guard g >= 0, g <= RegoleMessaggi.giorniRiepilogo else { return nil }
            let ora = Formati.ora.string(from: i.data)
            let quando: String
            let perche: String
            switch g {
            case 0:
                quando = "di oggi"
                perche = cal.component(.hour, from: i.data) < RegoleMessaggi.oraPomeriggio ? "Incontro di stamattina alle \(ora)" : "Incontro di oggi pomeriggio alle \(ora)"
            case 1:
                quando = "di ieri"
                perche = "Incontro di ieri alle \(ora)"
            default:
                quando = delGiorno(i.data)
                perche = "Incontro \(quando) alle \(ora)"
            }
            var cifre = [CifraMessaggio(.dataIncontro, Formati.dataEstesa.string(from: i.data)), CifraMessaggio(.oraIncontro, ora)]
            let decisioni = pulito(i.decisioni)
            if !decisioni.isEmpty { cifre.append(CifraMessaggio(.decisioni, String(decisioni.prefix(RegoleMessaggi.caratteriDecisioni)))) }
            let passo = pulito(i.prossimaAttivita)
            if !passo.isEmpty {
                let entro = i.scadenzaAttivita.map { " entro " + ModelliMessaggi.il(Formati.dataEstesa.string(from: $0)) } ?? ""
                cifre.append(CifraMessaggio(.prossimoPasso, String(passo.prefix(RegoleMessaggi.caratteriPasso)) + entro))
            }
            if let p = i.prossimoIncontro, p >= cal.startOfDay(for: oggi) {
                cifre.append(CifraMessaggio(.prossimoIncontro, Formati.dataEstesa.string(from: p)))
            }
            return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .riepilogoIncontro, riferimento: i.id), clienteId: c.id,
                                      canale: canaleComune(c, posizioni[c.id] ?? []),
                                      gruppo: g <= RegoleMessaggi.giorniRiepilogoOggi ? .oggi : .settimana,
                                      titolo: "Il riepilogo dell'incontro \(quando)", perche: perche,
                                      oggetto: "Il riepilogo del nostro incontro", cifre: cifre,
                                      priorita: g <= RegoleMessaggi.giorniRiepilogoOggi ? .alta : .media, data: i.data)
        }
    }

    /// Le posizioni in essere che scadono entro `soglia` giorni (oggi compreso). In «Da mandare oggi» il primo giorno
    /// in cui entrano nella soglia e nell'ultima settimana; negli altri giorni in «Questa settimana».
    static func scadenze(_ posizioni: [Posizione], clienti: [String: Cliente], soglia: Int, oggi: Date,
                         cal: Calendar) -> [OccasioneMessaggio] {
        posizioni.compactMap { p -> OccasioneMessaggio? in
            guard p.stato == .inEssere, let s = p.scadenza, let c = clienti[p.clienteId] else { return nil }
            let g = giorni(da: oggi, a: s, cal: cal)
            guard g >= 0, g <= soglia else { return nil }
            let nome = p.nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? p.area.nome : p.nome
            let perche: String
            switch g {
            case 0: perche = "Scade oggi"
            case 1: perche = "Scade domani"
            default: perche = "Scadenza tra \(g) giorni"
            }
            var cifre = [CifraMessaggio(.posizione, nome), CifraMessaggio(.scadenza, Formati.dataEstesa.string(from: s)),
                         CifraMessaggio(.giorniAllaScadenza, "\(g)"), CifraMessaggio(.canale, p.canale.nomeBreve)]
            if let k = p.capitaleAssicurato, k > 0 { cifre.append(CifraMessaggio(.capitaleAssicurato, Formati.euro(k))) }
            if p.premio > 0 {
                let ritmo = p.frequenza == .unica ? "premio unico" : p.frequenza.nome.lowercased()
                cifre.append(CifraMessaggio(.premio, "\(Formati.euro(p.premio)) · \(ritmo)"))
            }
            return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .scadenzaPosizione, riferimento: "\(p.id)-\(timbro(s, cal: cal))"),
                                      clienteId: c.id, canale: p.canale,
                                      gruppo: (g == soglia || g <= RegoleMessaggi.giorniScadenzaVicina) ? .oggi : .settimana,
                                      titolo: g == 0 ? "«\(nome)» scade oggi" : "«\(nome)» scade \(alGiorno(s))",
                                      perche: perche, oggetto: "«\(nome)» in scadenza", cifre: cifre,
                                      priorita: g <= RegoleMessaggi.giorniScadenzaUrgente ? .alta : .media, data: s)
        }
    }

    /// I compleanni dei prossimi sette giorni: oggi e domani in «Da mandare oggi». Mai commerciali.
    static func compleanni(_ clienti: [Cliente], posizioni: [String: [Posizione]], inizio: Date,
                           cal: Calendar) -> [OccasioneMessaggio] {
        var visti = Set<String>()
        return clienti.compactMap { c -> OccasioneMessaggio? in
            guard visti.insert(c.id).inserted, let n = c.dataNascita,
                  let d = MotoreNotifiche.prossimoCompleanno(n, da: inizio, cal: cal) else { return nil }
            let g = giorni(da: inizio, a: d, cal: cal)
            let anni = cal.component(.year, from: d) - cal.component(.year, from: n)
            guard g >= 0, g < RegoleMessaggi.giorniSettimana, anni > 0 else { return nil }
            let perche: String
            switch g {
            case 0: perche = "Oggi compie \(anni) anni"
            case 1: perche = "Domani compie \(anni) anni"
            default: perche = maiuscola(alGiorno(d)) + " compie \(anni) anni"
            }
            return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .compleanno, riferimento: "\(cal.component(.year, from: d))"),
                                      clienteId: c.id, canale: canaleComune(c, posizioni[c.id] ?? []),
                                      gruppo: g <= 1 ? .oggi : .settimana, titolo: "Gli auguri di compleanno", perche: perche,
                                      oggetto: "Buon compleanno!",
                                      cifre: [CifraMessaggio(.compleanno, Formati.giornoMese.string(from: d)), CifraMessaggio(.eta, "\(anni) anni")],
                                      priorita: g <= 1 ? .alta : .bassa, data: d)
        }
    }

    /// Il consenso commerciale scaduto o in scadenza entro 30 giorni e l'informativa privacy da firmare di nuovo
    /// («In regola», MotoreConformita). Il consenso al trattamento non scade: senza informativa aggiornata niente.
    static func consensi(_ dati: DatiPrisma, oggi: Date, cal: Calendar) -> [OccasioneMessaggio] {
        let esiti = MotoreConformita.calcola(clienti: dati.clienti, posizioni: dati.posizioni, regole: dati.impostazioni.conformita,
                                             oggi: oggi, calendario: cal)
        var visti = Set<String>()
        return esiti.flatMap { e -> [OccasioneMessaggio] in
            guard visti.insert(e.cliente.id).inserted else { return [] }
            return e.voci.compactMap { v -> OccasioneMessaggio? in
                guard v.tipo == .privacy || v.tipo == .commerciale, v.stato == .scaduta || v.stato == .entro30,
                      let s = v.scadenza else { return nil }
                let scaduta = v.stato == .scaduta
                let commerciale = v.tipo == .commerciale
                let data = Formati.dataEstesa.string(from: s)
                var cifre = [CifraMessaggio(.consenso, commerciale ? "Consenso commerciale" : "Informativa privacy")]
                if commerciale {
                    cifre.append(CifraMessaggio(.scadenza, data))
                } else {
                    cifre.append(CifraMessaggio(.informativaAggiornata, data))
                }
                if let f = v.data { cifre.append(CifraMessaggio(.firmatoIl, Formati.dataEstesa.string(from: f))) }
                let perche = commerciale ? (scaduta ? "Consenso scaduto " : "Il consenso scade ") + ModelliMessaggi.il(data)
                                         : "Informativa aggiornata " + ModelliMessaggi.il(data)
                return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .consenso, riferimento: "\(v.tipo.rawValue)-\(timbro(s, cal: cal))"),
                                          clienteId: e.cliente.id, canale: nil, gruppo: .settimana,
                                          titolo: commerciale ? "Il consenso commerciale da rinnovare" : "L'informativa privacy da firmare di nuovo",
                                          perche: perche,
                                          oggetto: commerciale ? "Il rinnovo del consenso" : "La nuova informativa sulla privacy",
                                          cifre: cifre, priorita: scaduta ? .media : .bassa, data: s, inRitardo: scaduta)
            }
        }
    }

    /// I riesami già dovuti (un anno dall'ultimo contatto, o mai incontrati) senza appuntamenti in agenda.
    static func riesami(_ dati: DatiPrisma, posizioni: [String: [Posizione]], oggi: Date, cal: Calendar) -> [OccasioneMessaggio] {
        MotoreRiesame.dovuti(clienti: dati.clienti, posizioni: dati.posizioni, appuntamenti: dati.appuntamenti,
                             incontri: dati.incontri, oggi: oggi)
            .filter { $0.scaduto(oggi) }
            .map { r -> OccasioneMessaggio in
                var cifre: [CifraMessaggio] = []
                if let u = r.ultimoContatto { cifre.append(CifraMessaggio(.ultimoContatto, Formati.dataEstesa.string(from: u))) }
                if let d = r.dovutoDal { cifre.append(CifraMessaggio(.riesameDovutoDal, Formati.dataEstesa.string(from: d))) }
                let perche = r.ultimoContatto.map { "Più di un anno dall'ultimo incontro, " + ModelliMessaggi.il(Formati.dataEstesa.string(from: $0)) }
                    ?? "Nessun incontro registrato"
                return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .riesame, riferimento: r.dovutoDal.map { timbro($0, cal: cal) } ?? "mai"),
                                          clienteId: r.cliente.id, canale: canaleComune(r.cliente, posizioni[r.cliente.id] ?? []),
                                          gruppo: .settimana, titolo: "Il punto dell'anno insieme", perche: perche,
                                          oggetto: "Facciamo il punto insieme?", cifre: cifre, priorita: .media,
                                          data: r.dovutoDal ?? oggi, inRitardo: true)
            }
    }

    /// Le occasioni importanti dell'Agenda (MotoreOccasioni, importanza alta) dei prossimi sette giorni.
    static func occasioniAgenda(_ dati: DatiPrisma, clienti: [String: Cliente], inizio: Date, oggi: Date,
                                cal: Calendar) -> [OccasioneMessaggio] {
        let fine = cal.date(byAdding: .day, value: RegoleMessaggi.giorniSettimana, to: inizio) ?? inizio
        let elenco = MotoreOccasioni.calcola(clienti: dati.clienti, posizioni: dati.posizioni, prodotti: dati.prodotti,
                                             da: inizio, a: fine, regole: dati.impostazioni.occasioni, oggi: oggi, cal: cal)
        return elenco.compactMap { o -> OccasioneMessaggio? in
            guard o.importanza == .alta, clienti[o.clienteId] != nil else { return nil }
            let g = giorni(da: inizio, a: o.data, cal: cal)
            let perche: String
            switch g {
            case 0: perche = "Oggi"
            case 1: perche = "Domani"
            default: perche = maiuscola(alGiorno(o.data)) + ", tra \(g) giorni"
            }
            var cifre = [CifraMessaggio(.occasione, o.titolo), CifraMessaggio(.dataOccasione, Formati.dataEstesa.string(from: o.data)),
                         CifraMessaggio(.cosaCambia, o.dettaglio)]
            if let k = o.canale { cifre.append(CifraMessaggio(.canale, k.nomeBreve)) }
            return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .occasioneAgenda, riferimento: o.id), clienteId: o.clienteId,
                                      canale: o.canale, gruppo: g == 0 ? .oggi : .settimana, titolo: o.titolo, perche: perche,
                                      oggetto: o.titolo, cifre: cifre, priorita: .media, data: o.data)
        }
    }

    /// Le parcelle emesse da mandare (emesse da al massimo sette giorni) e quelle scadute (un promemoria gentile).
    static func parcelle(_ parcelle: [Parcella], clienti: [String: Cliente], oggi: Date, cal: Calendar) -> [OccasioneMessaggio] {
        parcelle.compactMap { p -> OccasioneMessaggio? in
            guard p.stato == .emessa, clienti[p.clienteId] != nil else { return nil }
            let numero = (p.numero ?? "").trimmingCharacters(in: .whitespaces)
            let nomeParcella = numero.isEmpty ? "la parcella" : "la parcella n. \(numero)"
            var cifre: [CifraMessaggio] = []
            if !numero.isEmpty { cifre.append(CifraMessaggio(.parcella, "n. \(numero)")) }
            cifre.append(CifraMessaggio(.importo, Formati.euroDecimali(MotoreParcelle.importo(p))))
            if MotoreParcelle.scaduta(p, oggi: oggi, cal: cal), let s = p.scadenza {
                cifre.append(CifraMessaggio(.scadenza, Formati.dataEstesa.string(from: s)))
                return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .parcella, riferimento: "\(p.id)-sollecito"), clienteId: p.clienteId,
                                          canale: .indipendente, gruppo: .settimana, titolo: maiuscola(nomeParcella) + " da saldare",
                                          perche: "Scaduta " + ModelliMessaggi.il(Formati.dataEstesa.string(from: s)),
                                          oggetto: numero.isEmpty ? "Promemoria della parcella" : "Promemoria: parcella n. \(numero)",
                                          cifre: cifre, priorita: .media, data: s, inRitardo: true)
            }
            let g = giorni(da: p.data, a: oggi, cal: cal)
            guard g >= 0, g <= RegoleMessaggi.giorniParcellaDaMandare else { return nil }
            cifre.append(CifraMessaggio(.emessaIl, Formati.dataEstesa.string(from: p.data)))
            if let s = p.scadenza { cifre.append(CifraMessaggio(.scadenza, Formati.dataEstesa.string(from: s))) }
            let perche: String
            switch g {
            case 0: perche = "Emessa oggi"
            case 1: perche = "Emessa ieri"
            default: perche = "Emessa " + alGiorno(p.data)
            }
            return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .parcella, riferimento: "\(p.id)-invio"), clienteId: p.clienteId,
                                      canale: .indipendente, gruppo: g <= 1 ? .oggi : .settimana,
                                      titolo: maiuscola(nomeParcella) + " da mandare", perche: perche,
                                      oggetto: numero.isEmpty ? "La parcella della consulenza" : "La parcella n. \(numero)",
                                      cifre: cifre, priorita: .alta, data: p.data)
        }
    }

    /// Gli avvisi di Mercato (giro 7) nati da al massimo `RegoleMercato.giorniMessaggio` giorni: un messaggio al
    /// cliente toccato, con la frase dell'avviso come sola cifra da citare (e la posizione e il canale se uno solo).
    /// Quelli di oggi e di ieri vanno in «Da mandare oggi».
    static func avvisiMercato(_ avvisi: [AvvisoMercato], clienti: [String: Cliente], posizioni: [String: [Posizione]],
                              oggi: Date, cal: Calendar) -> [OccasioneMessaggio] {
        avvisi.compactMap { a -> OccasioneMessaggio? in
            guard clienti[a.clienteId] != nil else { return nil }
            let g = giorni(da: a.creatoIl, a: oggi, cal: cal)
            guard g >= 0, g <= RegoleMercato.giorniMessaggio else { return nil }
            var cifre = [CifraMessaggio(.avviso, a.titolo)]
            if a.posizioni.count == 1, let p = (posizioni[a.clienteId] ?? []).first(where: { $0.id == a.posizioni[0] }) {
                cifre.append(CifraMessaggio(.posizione, p.nome))
            }
            if let k = a.canale { cifre.append(CifraMessaggio(.canale, k.nomeBreve)) }
            return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .avvisoMercato, riferimento: a.id), clienteId: a.clienteId,
                                      canale: a.canale, gruppo: g <= 1 ? .oggi : .settimana, titolo: a.titolo,
                                      perche: a.tipo.nome, oggetto: TestiMercato.oggettoMessaggio(a.tipo), cifre: cifre,
                                      priorita: a.stato == .nuovo ? .media : .bassa, data: a.dataDato)
        }
    }

    // MARK: - Divisione e ordine

    /// Toglie i doppioni e le occasioni coperte da un messaggio aperto o salvato (quelle coperte oggi restano con
    /// `preparatoIl`), ordina e divide nei due gruppi.
    static func dividi(_ elenco: [OccasioneMessaggio], messaggi: [MessaggioCliente], clienti: [String: Cliente],
                       oggi: Date, cal: Calendar) -> OccasioniMessaggi {
        let inizio = cal.startOfDay(for: oggi)
        let limite = cal.date(byAdding: .day, value: -RegoleMessaggi.giorniCopertura, to: inizio) ?? inizio
        // Per ogni occasione coperta, il momento più recente in cui un messaggio l'ha coperta
        var coperte: [String: Date] = [:]
        for m in messaggi where m.stato.copreOccasione && m.dataMostrata >= limite {
            for chiave in [m.occasioneId, OccasioneMessaggio.id(tipo: m.origine.tipo, clienteId: m.clienteId, riferimento: m.origine.riferimento)] {
                coperte[chiave] = max(coperte[chiave] ?? .distantPast, m.dataMostrata)
            }
        }
        var visti = Set<String>()
        var tenute: [OccasioneMessaggio] = []
        for var o in elenco where visti.insert(o.id).inserted {
            if let quando = coperte[o.id] {
                guard quando >= inizio else { continue }
                o.preparatoIl = quando
            }
            tenute.append(o)
        }
        let ordinate = tenute.sorted { a, b in
            if a.gruppo != b.gruppo { return a.gruppo < b.gruppo }
            if a.priorita != b.priorita { return a.priorita < b.priorita }
            if a.tipo.ordine != b.tipo.ordine { return a.tipo.ordine < b.tipo.ordine }
            if a.data != b.data { return a.data < b.data }
            let na = clienti[a.clienteId]?.nome ?? "", nb = clienti[b.clienteId]?.nome ?? ""
            if na != nb { return na.localizedCompare(nb) == .orderedAscending }
            return a.id < b.id
        }
        return OccasioniMessaggi(oggi: Array(ordinate.filter { $0.gruppo == .oggi }.prefix(RegoleMessaggi.massimoPerGruppo)),
                                 settimana: Array(ordinate.filter { $0.gruppo == .settimana }.prefix(RegoleMessaggi.massimoPerGruppo)))
    }

    // MARK: - Aiuti

    /// Il canale del cliente quando è uno solo: quello delle posizioni in essere, altrimenti quello della scheda.
    static func canaleComune(_ c: Cliente, _ posizioni: [Posizione]) -> Canale? {
        let inEssere = Set(posizioni.filter { $0.stato == .inEssere }.map(\.canale))
        if inEssere.count == 1 { return inEssere.first }
        if inEssere.isEmpty, Set(c.canali).count == 1 { return c.canali.first }
        return nil
    }

    /// Giorni dall'inizio del giorno di `da` all'inizio del giorno di `a` (negativi se `a` è prima).
    static func giorni(da: Date, a: Date, cal: Calendar) -> Int {
        cal.dateComponents([.day], from: cal.startOfDay(for: da), to: cal.startOfDay(for: a)).day ?? 0
    }

    /// «aaaammgg» del giorno: entra negli id stabili.
    static func timbro(_ d: Date, cal: Calendar) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// «il 17 dicembre», «l'8 novembre», «l'11 marzo», «l'1 dicembre».
    static func alGiorno(_ d: Date) -> String {
        let testo = Formati.giornoMese.string(from: d)
        return conApostrofo(testo) ? "l'\(testo)" : "il \(testo)"
    }

    /// «del 17 dicembre», «dell'8 novembre».
    static func delGiorno(_ d: Date) -> String {
        let testo = Formati.giornoMese.string(from: d)
        return conApostrofo(testo) ? "dell'\(testo)" : "del \(testo)"
    }

    private static func conApostrofo(_ giornoMese: String) -> Bool {
        ["1 ", "8 ", "11 "].contains { giornoMese.hasPrefix($0) }
    }

    private static func maiuscola(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return primo.uppercased() + s.dropFirst()
    }

    /// Spazi in fondo tolti e righe vuote ridotte.
    private static func pulito(_ s: String) -> String {
        s.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            .joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
