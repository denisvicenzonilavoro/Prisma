import Foundation

// Le schede del copilota nel dossier (Orizzonte, giro 5; specifica §8.5.3 punti 5-6): solo quelle confermate dal
// consulente, una alla volta o tutte insieme. Ogni azione scrive un elemento con un id stabile (sessione + scheda),
// così una seconda conferma non duplica niente; una scheda già applicata non si riapplica. Il profilo del
// questionario (MiFID) non si tocca mai: il timore diventa una nota del taccuino, «annotazione, non profilo MiFID».

/// Quante cose sono entrate nel dossier.
struct EsitoCopilota: Equatable {
    /// Obiettivi, posizioni, note del profilo, eventi della linea della vita.
    var modifiche = 0
    var attivita = 0

    init(modifiche: Int = 0, attivita: Int = 0) {
        self.modifiche = modifiche
        self.attivita = attivita
    }

    var vuoto: Bool { modifiche == 0 && attivita == 0 }
}

enum ApplicaCopilota {
    /// Una nota sul profilo nata da una frase del cliente: mai il profilo del questionario.
    static let annotazione = "Annotazione dal copilota dell’incontro, non profilo MiFID: il questionario resta quello firmato."
    static let scadenzaDaConfermare = "Scadenza da confermare."

    /// Applica al dossier le schede proposte della sessione con gli id dati (nil = tutte le proposte). Le schede
    /// scartate e quelle già confermate restano come sono.
    static func applica(_ ids: Set<String>?, sessione s: inout SessioneCopilota, a dati: inout DatiPrisma, oggi: Date = Date()) -> EsitoCopilota {
        var esito = EsitoCopilota()
        for i in s.schede.indices {
            let x = s.schede[i]
            guard x.stato == .proposta, ids.map({ $0.contains(x.id) }) ?? true else { continue }
            let elemento: String?
            switch x.azione {
            case .creaObiettivo, .aggiornaObiettivo:
                elemento = obiettivo(x, sessione: s, dati: &dati, oggi: oggi)
            case .aggiungiPosizione:
                elemento = posizione(x, sessione: s, dati: &dati, oggi: oggi)
            case .annotaProfilo:
                elemento = nota(x, sessione: s, dati: &dati, oggi: oggi)
            case .aggiungiLineaVita:
                elemento = evento(x, sessione: s, dati: &dati, oggi: oggi)
            case .creaAttivita:
                elemento = attivita(x, sessione: s, dati: &dati, oggi: oggi)
            }
            guard let e = elemento else { continue }
            s.schede[i].stato = .confermata
            s.schede[i].applicataIl = oggi
            s.schede[i].elementoId = e
            if x.azione == .creaAttivita {
                esito.attivita += 1
                if !s.attivitaCreate.contains(e) { s.attivitaCreate.append(e) }
            } else {
                esito.modifiche += 1
            }
        }
        return esito
    }

    /// La scheda non entra nel dossier (e una nuova menzione della stessa cosa non la riapre).
    static func scarta(_ id: String, sessione s: inout SessioneCopilota) {
        guard let i = s.schede.firstIndex(where: { $0.id == id }), s.schede[i].stato == .proposta else { return }
        s.schede[i].stato = .scartata
    }

    // MARK: - Le azioni

    private static func idElemento(_ prefisso: String, _ s: SessioneCopilota, _ x: SchedaCopilota) -> String {
        "\(prefisso)-\(s.id)-\(RiconoscitoreCopilota.chiave(x.id))"
    }

    private static func dataIncontro(_ s: SessioneCopilota) -> String { Formati.dataEstesa.string(from: s.data) }

    /// La scadenza dell'obiettivo dalle cifre: «tra 3 anni» = lo stesso giorno fra tre anni (da confermare, come dice
    /// la specifica finché il consulente non sceglie), «giugno 2027» = il 1° giugno, «nel 2030» = lo stesso giorno di
    /// quell'anno. nil se la frase non dice quando.
    static func scadenza(_ c: CifreCopilota, oggi: Date) -> (data: Date, daConfermare: Bool)? {
        let cal = Calendar(identifier: .gregorian)
        if let n = c.anniDaOggi, let d = cal.date(byAdding: .year, value: n, to: oggi) { return (d, true) }
        if let a = c.anno, let m = c.mese, let d = cal.date(from: DateComponents(year: a, month: m, day: 1, hour: 12)) { return (d, false) }
        if let a = c.anno {
            var k = cal.dateComponents([.month, .day], from: oggi)
            k.year = a
            k.hour = 12
            if let d = cal.date(from: k) { return (d, true) }
        }
        return nil
    }

    private static func obiettivo(_ x: SchedaCopilota, sessione s: SessioneCopilota, dati: inout DatiPrisma, oggi: Date) -> String? {
        guard let area = x.cifre.area else { return nil }
        let mensile = x.cifre.frequenza == .mensile
        let quando = scadenza(x.cifre, oggi: oggi)
        let nota = "Dal copilota dell’incontro del \(dataIncontro(s))." + ((quando?.daConfermare ?? true) ? " " + scadenzaDaConfermare : "")
        // Aggiorna: l'obiettivo indicato, se c'è ancora; poi quello creato da questa sessione
        let id = x.obiettivoId.flatMap { o in dati.obiettivi.contains { $0.id == o } ? o : nil } ?? idElemento("obiettivo", s, x)
        if let i = dati.obiettivi.firstIndex(where: { $0.id == id }) {
            if let v = x.cifre.importo {
                if mensile { dati.obiettivi[i].versamentoMensile = v } else { dati.obiettivi[i].importo = v }
            }
            if let q = quando { dati.obiettivi[i].scadenza = q.data }
            if !dati.obiettivi[i].note.contains(nota) {
                dati.obiettivi[i].note = [dati.obiettivi[i].note, nota].filter { !$0.isEmpty }.joined(separator: "\n")
            }
            return id
        }
        let senzaData = Calendar(identifier: .gregorian).date(byAdding: .year, value: 10, to: oggi) ?? oggi
        var o = Obiettivo(clienteId: s.clienteId, titolo: RiconoscitoreCopilota.nomeArea(area), area: area,
                          importo: mensile ? 0 : (x.cifre.importo ?? 0), scadenza: quando?.data ?? senzaData)
        o.id = id
        if mensile, let v = x.cifre.importo { o.versamentoMensile = v }
        o.note = nota
        o.creatoIl = oggi
        dati.obiettivi.append(o)
        return id
    }

    /// L'area della posizione dal tipo di copertura.
    static func areaPosizione(_ tipo: String?) -> AreaPosizione {
        let t = RiconoscitoreCopilota.semplice(tipo ?? "")
        if t.contains("pension") || t == "pip" { return .previdenza }
        if t.contains("unit") || t.contains("multiramo") { return .investimento }
        if t.contains("rivalutabile") || t == "polizza vita" { return .risparmio }
        return .protezione
    }

    private static func posizione(_ x: SchedaCopilota, sessione s: SessioneCopilota, dati: inout DatiPrisma, oggi: Date) -> String? {
        let id = idElemento("posizione", s, x)
        let tipo = x.cifre.tipoPolizza ?? "polizza"
        let compagnia = x.cifre.compagnia ?? "Altra compagnia"
        var p = dati.posizioni.first { $0.id == id }
            ?? Posizione(clienteId: s.clienteId, canale: .indipendente, stato: .inEssere, area: areaPosizione(x.cifre.tipoPolizza),
                         nome: tipo.prefix(1).uppercased() + tipo.dropFirst() + " · " + compagnia)
        p.id = id
        p.emittente = compagnia
        p.tipologia = tipo.prefix(1).uppercased() + tipo.dropFirst()
        var note = "Polizza di un’altra compagnia, non seguita dal consulente: dal copilota dell’incontro del \(dataIncontro(s)). Da completare con il documento."
        if let v = x.cifre.importo {
            if x.cifre.frequenza == .unica {
                p.versamentoIniziale = v
                p.premio = 0
                p.frequenza = .unica
            } else {
                p.premio = v
                p.frequenza = x.cifre.frequenza ?? .annuale
                if x.cifre.frequenza == nil { note += " Il cliente non ha detto ogni quanto paga: annuale, da confermare." }
            }
        }
        p.note = note
        if let i = dati.posizioni.firstIndex(where: { $0.id == id }) {
            dati.posizioni[i] = p
        } else {
            p.creataIl = oggi
            dati.posizioni.append(p)
        }
        return id
    }

    private static func nota(_ x: SchedaCopilota, sessione s: SessioneCopilota, dati: inout DatiPrisma, oggi: Date) -> String? {
        let id = idElemento("nota", s, x)
        let testo = "\(x.titolo) (incontro del \(dataIncontro(s))).\n\(annotazione)"
        if let i = dati.note.firstIndex(where: { $0.id == id }) {
            dati.note[i].testo = testo
            dati.note[i].aggiornataIl = oggi
            return id
        }
        var n = Nota(clienteId: s.clienteId, titolo: "Dal copilota: \(x.titolo)", testo: testo)
        n.id = id
        n.creataIl = oggi
        n.aggiornataIl = oggi
        dati.note.append(n)
        return id
    }

    private static func evento(_ x: SchedaCopilota, sessione s: SessioneCopilota, dati: inout DatiPrisma, oggi: Date) -> String? {
        let id = idElemento("vita", s, x)
        let annoOggi = Calendar(identifier: .gregorian).component(.year, from: oggi)
        let anno = x.cifre.anno ?? x.cifre.anniDaOggi.map { annoOggi + $0 }
        let mese = x.cifre.mese.flatMap { (1...12).contains($0) ? RiconoscitoreCopilota.mesi[$0 - 1] : nil }
        var e = EventoLineaVita(clienteId: s.clienteId, tipo: x.cifre.evento ?? .altro, anno: anno,
                                nota: [mese.map { m in anno.map { "\(m) \($0)" } ?? m }, "Dal copilota dell’incontro del \(dataIncontro(s))."]
                                    .compactMap { $0 }.joined(separator: " · "),
                                origine: .copilota)
        e.id = id
        if let i = dati.eventiVita.firstIndex(where: { $0.id == id }) {
            // L'età e l'importo scritti dal consulente restano
            e.eta = dati.eventiVita[i].eta
            e.importo = dati.eventiVita[i].importo
            e.durataAnni = dati.eventiVita[i].durataAnni
            dati.eventiVita[i] = e
        } else {
            dati.eventiVita.append(e)
        }
        return id
    }

    private static func attivita(_ x: SchedaCopilota, sessione s: SessioneCopilota, dati: inout DatiPrisma, oggi: Date) -> String? {
        let id = idElemento("attivita", s, x)
        // Nessuna scadenza inventata: senza una data detta, oggi e la nota «da scegliere»
        let a = Attivita(id: id, clienteId: s.clienteId, titolo: x.titolo, scadenza: x.cifre.scadenza ?? oggi, priorita: .normale,
                         completata: false,
                         note: "Dal copilota dell’incontro del \(dataIncontro(s))." + (x.cifre.scadenza == nil ? " Scadenza da scegliere." : ""))
        if let i = dati.attivita.firstIndex(where: { $0.id == id }) {
            var b = a
            b.completata = dati.attivita[i].completata
            dati.attivita[i] = b
        } else {
            dati.attivita.append(a)
        }
        return id
    }

    // MARK: - Il verbale

    /// Il verbale con frasi fisse dalle cifre delle schede non scartate: cosa è emerso, le attività, cosa cambia nel
    /// dossier. Qwen può solo riformularlo, con il controllo dei numeri.
    static func verbale(_ s: SessioneCopilota) -> VerbaleCopilota {
        let valide = s.schede.filter { $0.stato != .scartata }
        let punti = valide.filter { $0.tipo != .attivita }.map { punto($0) }
        let attivita = valide.filter { $0.tipo == .attivita }.map(\.titolo)
        let dossier = valide.filter { $0.tipo != .attivita }.map { "\($0.azione.nome): \($0.titolo)" }
        return VerbaleCopilota(punti: punti, attivita: attivita, dossier: dossier,
                               confermatoIl: s.verbale?.confermatoIl)
    }

    /// Una riga del verbale.
    static func punto(_ x: SchedaCopilota) -> String {
        let c = x.cifre
        let importo = c.importo.map { RiconoscitoreCopilota.cifra($0) + " €" + RiconoscitoreCopilota.dopoImporto(c.frequenza) }
        let quando = RiconoscitoreCopilota.quando(c)
        switch x.tipo {
        case .obiettivo:
            let area = c.area.map { RiconoscitoreCopilota.nomeArea($0).lowercased() } ?? "nuovo"
            let parti = [quando.isEmpty ? nil : quando, importo.map { "con \($0)" }].compactMap { $0 }
            return "Obiettivo \(area)" + (parti.isEmpty ? "" : ": " + parti.joined(separator: ", ")) + "."
        case .polizzaEsterna:
            let presso = c.compagnia.map { "con \($0)" } ?? "con un’altra compagnia"
            return "Ha una polizza \(c.tipoPolizza ?? "assicurativa") \(presso)" + (importo.map { ", \($0)" } ?? "") + "."
        case .profilo:
            return "Sui soldi " + (c.area.map(RiconoscitoreCopilota.soldiDi) ?? "di cui si è parlato") + " preferisce non rischiare (annotazione, non profilo MiFID)."
        case .evento:
            return (c.evento?.nome ?? "Un evento") + (quando.isEmpty ? "" : " " + quando) + "."
        case .attivita:
            return x.titolo + "."
        }
    }

    /// «4 modifiche e 2 attività», «1 modifica e 1 attività», «4 modifiche», «2 attività».
    static func avviso(_ e: EsitoCopilota) -> String {
        let m = e.modifiche == 1 ? "1 modifica" : "\(e.modifiche) modifiche"
        let a = "\(e.attivita) attività"
        if e.modifiche > 0 && e.attivita > 0 { return "\(m) e \(a)" }
        if e.attivita > 0 { return a }
        return m
    }
}
