import Foundation

// Il motore di «Stanotte Prisma ha lavorato» («Luce» giro 14, §6.1, decisioni 30, 31, 101): quando la notte può
// lavorare, cosa preparare (uno per carta, nell'ordine fisso dei tipi: prima quelli senza Qwen), le carte con i loro testi
// e id stabili, le carte di ieri ancora valide, la pila di un'apertura e la potatura delle notti. Puro: niente `Date()`,
// niente SwiftUI, niente rete. I dati arrivano dallo stato già filtrati.

/// Perché adesso la notte non lavora (nil = si può). Niente «in pausa»: lo schermo spento non ferma la notte.
enum AttesaNotte: Equatable {
    case spento, fuoriFinestra, giaFatta, senzaCorrente, alimentazioneSconosciuta, caldo, risparmioEnergetico, backupInCorso
    case solaLettura, modoCliente, prismaInUso
}

/// Le condizioni di adesso (decisione 30).
struct CondizioniNotte {
    var adesso: Date
    var impostazioni: ImpostazioniNotte
    /// true alla corrente, false a batteria, nil se macOS non lo dice.
    var allaCorrente: Bool?
    var caldo: Bool
    var risparmio: Bool
    var backupInCorso: Bool
    var solaLettura: Bool
    var modoClienteOPresentazione: Bool
    /// Prisma in primo piano e sbloccato: l'utente lavora.
    var prismaInUso: Bool
    var notti: [NotteDiLavoro]
    /// «Prepara adesso»: lo chiede l'utente, quindi non contano accensione, finestra, notte già fatta, corrente, caldo,
    /// risparmio energetico e «in uso».
    var manuale = false
}

/// I dati che servono al testo di una carta.
enum DettagliNotte: Equatable {
    case ricalcolo(portafogli: Int, nuovi: [String], chiavi: [String])
    case documento(scadenza: Date, scaduto: Bool, documento: String, bozza: MessaggioCliente?)
    case riesame(dovutoDal: Date?, fuoriModello: Double?)
    case domani(appuntamenti: [String], righe: [String], daPortare: Int, km: Double?, partenza: Date?)
    case fascicolo(appuntamento: String, ora: Date, prospetti: [String], soloResoconto: Bool)
    case moduli(posizione: String, nomeProposta: String, modelli: [String], campi: Int, mancanti: [String])
    case campagna(gruppo: String, tipo: TipoGruppoCampagna, titolo: String, inclusi: [String])
    /// La bozza c'è solo dopo la scrittura di Vera (fase 2); prima è il compito.
    case messaggio(occasione: String, titolo: String, perche: String, bozza: MessaggioCliente?, firma: Bool)
    case daFinire(bozze: Int, motivo: MotivoStopNotte?)
}

/// Cosa preparare (uno per carta), già con i dati che servono al testo.
struct PreparativoNotte: Equatable {
    let tipo: TipoCartaNotte
    let clienteId: String?
    let riferimento: String
    let dettagli: DettagliNotte
}

enum MotoreNotte {
    // MARK: - Quando

    /// Il giorno servito: dall'ora di inizio a mezzanotte il giorno dopo, dopo mezzanotte (e di giorno) oggi.
    static func giornoServito(_ adesso: Date, inizio: Int, cal: Calendar = .current) -> Date {
        let oggi = cal.startOfDay(for: adesso)
        guard cal.component(.hour, from: adesso) >= inizio else { return oggi }
        return cal.date(byAdding: .day, value: 1, to: oggi) ?? oggi
    }

    /// Dentro la finestra: ora ≥ inizio oppure ora < 6.
    static func nellaFinestra(_ adesso: Date, inizio: Int, cal: Calendar = .current) -> Bool {
        let h = cal.component(.hour, from: adesso)
        return h >= inizio || h < ImpostazioniNotte.fineFinestra
    }

    /// Perché adesso no (nil = si può lavorare).
    static func attesa(_ c: CondizioniNotte, cal: Calendar = .current) -> AttesaNotte? {
        let imp = c.impostazioni
        if !c.manuale && !imp.attivo { return .spento }
        if c.solaLettura { return .solaLettura }
        if c.modoClienteOPresentazione { return .modoCliente }
        if c.backupInCorso { return .backupInCorso }
        if c.manuale { return nil }
        if !nellaFinestra(c.adesso, inizio: imp.inizio, cal: cal) { return .fuoriFinestra }
        let giorno = giornoServito(c.adesso, inizio: imp.inizio, cal: cal)
        if let n = notte(per: giorno, in: c.notti, cal: cal), n.esito == .fatta { return .giaFatta }
        if imp.soloConCorrente {
            guard let corrente = c.allaCorrente else { return .alimentazioneSconosciuta }
            if !corrente { return .senzaCorrente }
        }
        if c.caldo { return .caldo }
        if c.risparmio { return .risparmioEnergetico }
        if c.prismaInUso { return .prismaInUso }
        return nil
    }

    /// La notte del giorno servito (nil se non c'è).
    static func notte(per giorno: Date, in notti: [NotteDiLavoro], cal: Calendar = .current) -> NotteDiLavoro? {
        let chiave = NotteDiLavoro.chiave(giorno, cal: cal)
        return notti.first { $0.giornoChiave == chiave }
    }

    // MARK: - Cosa preparare

    /// Cosa preparare, nell'ordine fisso dei tipi (`TipoCartaNotte.allCases`), senza i tipi spenti. Dati già filtrati dallo
    /// stato. `giro`: quello del Territorio per il giorno (nil = niente km né partenza). `riesamiConDati`: i clienti per cui
    /// Prisma ha i dati del prospetto (gli altri non nascono). `modelli`: i modelli di modulo compilabili e con la mappa
    /// confermata. `occasioni`: quelle di Messaggi del giorno (le alte, senza le campagne, diventano compiti di Vera).
    static func preparativi(dati: DatiPrisma, giorno g: Date, impostazioni imp: ImpostazioniNotte, precedente: NotteDiLavoro?,
                            giro: GiroGiorno?, riesamiConDati: Set<String>, modelli: [ModelloModulo],
                            occasioni: [OccasioneMessaggio], cal: Calendar = .current) -> [PreparativoNotte] {
        let giorno = cal.startOfDay(for: g)
        let domani = cal.date(byAdding: .day, value: 1, to: giorno) ?? giorno
        var clienti: [String: Cliente] = [:]
        for c in dati.clienti where clienti[c.id] == nil { clienti[c.id] = c }
        var perTipo: [TipoCartaNotte: [PreparativoNotte]] = [:]

        // Ricalcolo: solo le attenzioni nuove rispetto alla fotografia della notte prima
        if imp.prepara(.ricalcolo), let prima = precedente {
            let chiavi = attenzioni(dati: dati)
            let vecchie = Set(prima.attenzioni)
            var nuovi: [String] = []
            for k in chiavi where !vecchie.contains(k) {
                let id = String(k.split(separator: "·", maxSplits: 1).first ?? "")
                if !id.isEmpty, clienti[id] != nil, !nuovi.contains(id) { nuovi.append(id) }
            }
            if !nuovi.isEmpty {
                let portafogli = Set(dati.posizioni.filter { $0.stato == .inEssere && clienti[$0.clienteId] != nil }.map(\.clienteId)).count
                perTipo[.ricalcolo] = [PreparativoNotte(tipo: .ricalcolo, clienteId: nuovi.count == 1 ? nuovi[0] : nil,
                                                        riferimento: "attenzioni",
                                                        dettagli: .ricalcolo(portafogli: portafogli, nuovi: nuovi, chiavi: chiavi))]
            }
        }

        // Documento d'identità: vale solo la scadenza scritta, entro `giorniDocumenti` (o già scaduto)
        var conDocumento = Set<String>()
        if imp.prepara(.documento) {
            let limite = cal.date(byAdding: .day, value: imp.giorniDocumenti, to: giorno) ?? giorno
            let esiti = MotoreConformita.calcola(clienti: dati.clienti, posizioni: dati.posizioni, regole: dati.impostazioni.conformita,
                                                 oggi: giorno, calendario: cal)
            var elenco: [PreparativoNotte] = []
            for e in esiti {
                guard let v = e.voci.first(where: { $0.tipo == .documento }), v.stato != .nonRichiesta,
                      let s = v.scadenza, s <= limite else { continue }
                let riferimento = "\(e.cliente.id)·\(NotteDiLavoro.chiave(s, cal: cal))"
                let occasione = OccasioneMessaggio.id(tipo: .documentoIdentita, clienteId: e.cliente.id, riferimento: riferimento)
                // Una richiesta già salvata in Messaggi (anche da una notte prima): niente carta nuova
                guard !dati.messaggi.contains(where: { $0.occasioneId == occasione }) else { continue }
                let nomeDoc = e.cliente.conformita?.documento?.tipo?.nome ?? "Il documento d'identità"
                let scaduto = s < giorno
                let bozza = bozzaDocumento(e.cliente, scadenza: s, scaduto: scaduto, documento: nomeDoc, riferimento: riferimento,
                                           giorno: giorno, impostazioni: dati.impostazioni, cal: cal)
                elenco.append(PreparativoNotte(tipo: .documento, clienteId: e.cliente.id, riferimento: riferimento,
                                               dettagli: .documento(scadenza: s, scaduto: scaduto, documento: nomeDoc, bozza: bozza)))
                conDocumento.insert(e.cliente.id)
            }
            perTipo[.documento] = elenco
        }

        // Riesame: dovuto entro `giorniRiesami`, solo con i dati del prospetto, al più `massimoRiesami`
        if imp.prepara(.riesame), imp.massimoRiesami > 0 {
            let limite = cal.date(byAdding: .day, value: imp.giorniRiesami, to: giorno) ?? giorno
            let radar = MotoreRadar.calcola(dati)
            let dovuti = MotoreRiesame.dovuti(clienti: dati.clienti, posizioni: dati.posizioni, appuntamenti: dati.appuntamenti,
                                              incontri: dati.incontri, oggi: giorno)
            perTipo[.riesame] = dovuti.filter { r in (r.dovutoDal.map { $0 <= limite } ?? true) && riesamiConDati.contains(r.cliente.id) }
                .prefix(imp.massimoRiesami)
                .map { r in
                    let voce = radar.voci.first { $0.clienteId == r.cliente.id && $0.fuori }
                    let fuori = voce.flatMap { v in v.tolleranza.map { v.distanza - $0 } }
                    return PreparativoNotte(tipo: .riesame, clienteId: r.cliente.id, riferimento: r.cliente.id,
                                            dettagli: .riesame(dovutoDal: r.dovutoDal, fuoriModello: fuori))
                }
        }

        // Gli appuntamenti del giorno servito (con un cliente vero, confermati)
        let delGiorno = dati.appuntamenti.filter {
            $0.stato == .pianificato && $0.tipo != .nonDisponibile && $0.daConfermare != true
                && $0.inizio >= giorno && $0.inizio < domani && clienti[$0.clienteId] != nil
        }.sorted { ($0.inizio, $0.id) < ($1.inizio, $1.id) }

        // Fascicolo: i report adatti a ogni incontro, al più `massimoFascicoli`; non se è già nei Documenti
        var conFascicolo = Set<String>()
        if imp.prepara(.fascicolo), imp.massimoFascicoli > 0 {
            var elenco: [PreparativoNotte] = []
            for a in delGiorno where elenco.count < imp.massimoFascicoli {
                let titolo = "Report · " + StatoShell.titoloFascicolo(a.inizio)
                guard !dati.documenti.contains(where: { $0.clienteId == a.clienteId && $0.titolo == titolo }) else { continue }
                let posizione = a.posizioneId.flatMap { id in dati.posizioni.first { $0.id == id } }
                let scelta = TipoProspetto.perIncontro(a, posizione: posizione, oggi: giorno)
                let prospetti = TipoProspetto.inFascicolo.filter { scelta.contains($0) }.map(\.rawValue)
                guard !prospetti.isEmpty else { continue }
                elenco.append(PreparativoNotte(tipo: .fascicolo, clienteId: a.clienteId, riferimento: a.id,
                                               dettagli: .fascicolo(appuntamento: a.id, ora: a.inizio, prospetti: prospetti,
                                                                    soloResoconto: scelta == [.resoconto])))
                conFascicolo.insert(a.id)
            }
            perTipo[.fascicolo] = elenco
        }

        // Moduli: le proposte aperte con un appuntamento entro 7 giorni (preferendo quello di firma) e i modelli compatibili
        var moduliPerCliente: [String: Int] = [:]
        if imp.prepara(.moduli), !modelli.isEmpty {
            let entro = cal.date(byAdding: .day, value: 7, to: giorno) ?? giorno
            let f = dati.impostazioni.studio.fatturazione
            let consulente = [f.nome, f.cognome].map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: " ")
            var elenco: [PreparativoNotte] = []
            let proposte = dati.posizioni.filter { $0.stato == .proposta && $0.esito != .rifiutata && clienti[$0.clienteId] != nil }
                .sorted { ($0.clienteId, $0.creataIl) < ($1.clienteId, $1.creataIl) }
            for p in proposte {
                guard let c = clienti[p.clienteId] else { continue }
                let futuri = dati.appuntamenti.filter { $0.clienteId == c.id && $0.stato == .pianificato && $0.inizio >= giorno && $0.inizio < entro }
                guard !futuri.isEmpty else { continue }
                let compatibili = modelli.filter { m in
                    m.compilabile && m.mappaConfermata && (m.canale == nil || m.canale == p.canale)
                        && (m.prodottoIds.isEmpty || p.prodottoId.map { m.prodottoIds.contains($0) } == true)
                }
                guard !compatibili.isEmpty else { continue }
                let fonte = FonteCompilazione(cliente: c, posizione: p,
                                              prodotto: p.prodottoId.flatMap { id in dati.prodotti.first { $0.id == id } },
                                              consulente: consulente, comuneConsulente: f.sede.comune, oggi: giorno,
                                              conservaIban: dati.impostazioni.pratiche.ibanConservato)
                var campi = 0
                var mancanti: [String] = []
                for m in compatibili {
                    let a = CompilatoreModuli.anteprima(m, fonte: fonte)
                    campi += a.compilati
                    for d in a.datiMancanti where !mancanti.contains(d.nome) { mancanti.append(d.nome) }
                }
                elenco.append(PreparativoNotte(tipo: .moduli, clienteId: c.id, riferimento: p.id,
                                               dettagli: .moduli(posizione: p.id, nomeProposta: p.nome, modelli: compatibili.map(\.id),
                                                                 campi: campi, mancanti: mancanti)))
                moduliPerCliente[c.id, default: 0] += compatibili.count
            }
            perTipo[.moduli] = elenco
        }

        // Campagna: una per notte, il gruppo con più inclusi di base (almeno 2), con il modello fisso
        if imp.prepara(.campagna) {
            let gruppi = MotoreCampagne.gruppi(dati: dati, oggi: giorno, cal: cal)
            let scelto = gruppi.map { g in (g, g.membri.filter(\.inclusoDiBase).map(\.clienteId)) }
                .filter { $0.1.count >= RegoleCampagne.minimoMembri }
                .max { ($0.1.count, $1.0.id) < ($1.1.count, $0.0.id) }
            if let s = scelto {
                let g = s.0
                let inclusi = s.1
                perTipo[.campagna] = [PreparativoNotte(tipo: .campagna, clienteId: nil, riferimento: g.id,
                                                       dettagli: .campagna(gruppo: g.id, tipo: g.tipo, titolo: g.titolo, inclusi: inclusi))]
            }
        }

        // Domani: la borsa, una riga per incontro con quello che c'è da portare
        if imp.prepara(.domani), !delGiorno.isEmpty {
            var righe: [String] = []
            var daPortare = 0
            for a in delGiorno {
                var cose: [String] = []
                if conFascicolo.contains(a.id) { cose.append(TestiNotte.borsaFascicolo) }
                if let n = moduliPerCliente[a.clienteId], n > 0 { cose.append(TestiNotte.borsaModuli(n)) }
                if conDocumento.contains(a.clienteId) { cose.append(TestiNotte.borsaDocumento) }
                daPortare += cose.count
                righe.append(TestiNotte.rigaBorsa(ora: a.inizio, nome: clienti[a.clienteId]?.nome, cose: cose))
            }
            var km: Double?
            var partenza: Date?
            if let giro, !giro.vuoto, giro.partenza != nil {
                km = giro.km
                if let t = giro.tappe.first(where: { $0.genere == .visita }), let a = t.appuntamento {
                    partenza = arrotondaGiu(a.inizio.addingTimeInterval(-Double(t.minutiDaPrima) * 60))
                }
            }
            perTipo[.domani] = [PreparativoNotte(tipo: .domani, clienteId: nil, riferimento: "borsa",
                                                 dettagli: .domani(appuntamenti: delGiorno.map(\.id), righe: righe, daPortare: daPortare,
                                                                   km: km, partenza: partenza))]
        }

        // Messaggi: le occasioni alte del giorno (non le campagne, non quelle già preparate), compiti di Vera
        if imp.prepara(.messaggio), imp.usaQwen, imp.massimoBozze > 0 {
            perTipo[.messaggio] = compitiMessaggi(occasioni, dati: dati, massimo: imp.massimoBozze).map { o in
                PreparativoNotte(tipo: .messaggio, clienteId: o.clienteId, riferimento: o.id,
                                 dettagli: .messaggio(occasione: o.id, titolo: o.titolo, perche: o.perche, bozza: nil, firma: true))
            }
        }

        return TipoCartaNotte.allCases.flatMap { perTipo[$0] ?? [] }
    }

    /// Le occasioni che Vera scrive di notte: alte, non campagne, non già preparate, senza una bozza già in Messaggi.
    static func compitiMessaggi(_ occasioni: [OccasioneMessaggio], dati: DatiPrisma, massimo: Int) -> [OccasioneMessaggio] {
        let conBozza = Set(dati.messaggi.map(\.occasioneId))
        return Array(occasioni.filter { $0.priorita == .alta && $0.tipo != .campagna && $0.preparatoIl == nil && !conBozza.contains($0.id) }
            .prefix(max(0, min(ImpostazioniNotte.tettoBozze, massimo))))
    }

    /// La partenza arrotondata ai 5 minuti per difetto (si parte un po' prima, mai dopo).
    static func arrotondaGiu(_ d: Date) -> Date {
        let passo = 300.0
        return Date(timeIntervalSinceReferenceDate: (d.timeIntervalSinceReferenceDate / passo).rounded(.down) * passo)
    }

    /// L'occasione della richiesta del documento (la bozza della notte e il campionario della prova dei messaggi).
    static func occasioneDocumento(_ c: Cliente, scadenza: Date, scaduto: Bool, documento: String,
                                   riferimento: String) -> OccasioneMessaggio {
        let cifre = [CifraMessaggio(.documento, documento), CifraMessaggio(.scadenza, Formati.giornoMese.string(from: scadenza))]
        return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .documentoIdentita, riferimento: riferimento), clienteId: c.id,
                                  canale: nil, gruppo: .settimana, titolo: TestiNotte.titoloDocumento(nome: c.nome, documento: documento,
                                                                                                      scadenza: scadenza, scaduto: scaduto),
                                  perche: TestiNotte.descrizioneDocumento, oggetto: "Il documento d'identità nuovo", cifre: cifre,
                                  priorita: .media, data: scadenza, inRitardo: scaduto)
    }

    /// La bozza della richiesta del documento, con il modello fisso (niente Qwen sulle richieste: sono brevi e uguali).
    static func bozzaDocumento(_ c: Cliente, scadenza: Date, scaduto: Bool, documento: String, riferimento: String, giorno: Date,
                               impostazioni: Impostazioni, cal: Calendar = .current) -> MessaggioCliente {
        let o = occasioneDocumento(c, scadenza: scadenza, scaduto: scaduto, documento: documento, riferimento: riferimento)
        let cifre = o.cifre
        let firma = ModelliMessaggi.firma(nil, tono: .cordiale, impostazioni: impostazioni)
        let t = ModelliMessaggi.testo(o, tono: .cordiale, canale: .mail, cliente: c, firma: firma)
        var m = MessaggioCliente(clienteId: c.id, occasioneId: o.id, origine: o.origine, canaleLavoro: nil, tono: .cordiale,
                                 canale: .mail, oggetto: t.oggetto, testo: t.completo, cifre: cifre, autore: .modelloFisso, modello: nil,
                                 creatoIl: giorno)
        m.id = "messaggio-notte-\(NotteDiLavoro.chiave(giorno, cal: cal))-documento-\(c.id)"
        return m
    }

    /// La fotografia delle attenzioni di oggi («clienteId·tipo» di MotoreAttenzioni e «clienteId·radar» dei fuori modello).
    /// Mai titoli né cifre.
    static func attenzioni(dati: DatiPrisma) -> [String] {
        var chiavi = Set(MotoreAttenzioni.calcola(clienti: dati.clienti, posizioni: dati.posizioni).map { "\($0.cliente.id)·\($0.tipo.rawValue)" })
        for v in MotoreRadar.calcola(dati).fuori { chiavi.insert("\(v.clienteId)·radar") }
        return chiavi.sorted()
    }

    // MARK: - Le carte

    static func idCarta(tipo: TipoCartaNotte, riferimento: String, giorno: Date, cal: Calendar = .current) -> String {
        "\(tipo.rawValue)-\(riferimento)-\(NotteDiLavoro.chiave(cal.startOfDay(for: giorno), cal: cal))"
    }

    /// La carta di un preparativo (testi da TestiNotte, id stabile). `nomi`: clienteId → nome.
    static func carta(_ p: PreparativoNotte, giorno g: Date, adesso: Date, nomi: [String: String], cal: Calendar = .current) -> CartaNotte {
        let giorno = cal.startOfDay(for: g)
        let nome = p.clienteId.flatMap { nomi[$0] } ?? ""
        let alle = NotaInArrivo.alSecondo(adesso)
        func nuova(_ titolo: String, _ descrizione: String, _ conferma: String) -> CartaNotte {
            CartaNotte(id: idCarta(tipo: p.tipo, riferimento: p.riferimento, giorno: giorno, cal: cal), tipo: p.tipo,
                       clienteId: p.clienteId, riferimento: p.riferimento, titolo: titolo, descrizione: descrizione,
                       conferma: conferma, preparataIl: alle, perIl: giorno)
        }
        switch p.dettagli {
        case let .ricalcolo(portafogli, nuovi, _):
            var c = nuova(TestiNotte.titoloRicalcolo(portafogli: portafogli), TestiNotte.descrizioneRicalcolo(nuovi: nuovi.count),
                          TestiNotte.confermaRicalcolo)
            c.clienti = nuovi
            return c
        case let .documento(scadenza, scaduto, documento, bozza):
            var c = nuova(TestiNotte.titoloDocumento(nome: nome, documento: documento, scadenza: scadenza, scaduto: scaduto),
                          TestiNotte.descrizioneDocumento, TestiNotte.confermaDocumento)
            c.bozze = bozza.map { [$0] } ?? []
            return c
        case let .riesame(dovutoDal, fuori):
            var c = nuova(TestiNotte.titoloRiesame(nome: nome), TestiNotte.descrizioneRiesame(dovutoDal: dovutoDal, oggi: giorno, fuoriModello: fuori),
                          TestiNotte.confermaRiesame)
            c.prospetti = [TipoProspetto.riesame.rawValue]
            return c
        case let .domani(appuntamenti, righe, daPortare, km, partenza):
            var c = nuova(TestiNotte.titoloDomani,
                          TestiNotte.descrizioneDomani(incontri: appuntamenti.count, daPortare: daPortare, km: km, partenza: partenza),
                          TestiNotte.confermaDomani)
            c.appuntamenti = appuntamenti
            c.righe = righe
            return c
        case let .fascicolo(_, ora, prospetti, _):
            var c = nuova(TestiNotte.titoloFascicolo(nome: nome), TestiNotte.descrizioneFascicolo(ora: ora, prospetti: prospetti),
                          TestiNotte.confermaFascicolo)
            c.prospetti = prospetti
            return c
        case let .moduli(_, nomeProposta, modelli, campi, mancanti):
            var c = nuova(TestiNotte.titoloModuli(proposta: nomeProposta, quanti: modelli.count),
                          TestiNotte.descrizioneModuli(quanti: modelli.count, campi: campi, mancanti: mancanti), TestiNotte.confermaModuli)
            c.modelli = modelli
            return c
        case let .campagna(_, _, titolo, inclusi):
            var c = nuova(TestiNotte.titoloCampagna(titolo: titolo, inclusi: inclusi.count), TestiNotte.descrizioneCampagna(inclusi: inclusi.count),
                          TestiNotte.confermaCampagna)
            c.clienti = inclusi
            return c
        case let .messaggio(_, titolo, perche, bozza, firma):
            var c = nuova(TestiNotte.titoloMessaggio(nome: nome, occasione: titolo), TestiNotte.descrizioneMessaggio(perche: perche, firma: firma),
                          TestiNotte.confermaMessaggio)
            c.bozze = bozza.map { [$0] } ?? []
            return c
        case let .daFinire(bozze, motivo):
            var c = nuova(TestiNotte.titoloDaFinire(bozze, motivo: motivo), TestiNotte.daFinireTesto, TestiNotte.daFinireConferma)
            c.daFinire = bozze
            return c
        }
    }

    // MARK: - Le carte di ieri e la pila

    /// La carta ha ancora senso? (al più 7 giorni; incontro non passato, documento ancora con la stessa scadenza, occasione
    /// ancora proposta, riesame ancora dovuto, proposta ancora aperta, gruppo ancora presente; ricalcolo, borsa e «da finire»
    /// solo il loro giorno). `oggi`: adesso.
    static func ancoraValida(_ c: CartaNotte, dati: DatiPrisma, oggi: Date, occasioni: [String], gruppi: [String],
                             cal: Calendar = .current) -> Bool {
        let inizio = cal.startOfDay(for: oggi)
        let limite = cal.date(byAdding: .day, value: -ImpostazioniNotte.giorniDaIeri, to: inizio) ?? inizio
        guard c.perIl >= limite else { return false }
        if let id = c.clienteId, !dati.clienti.contains(where: { $0.id == id }) { return false }
        switch c.tipo {
        case .ricalcolo, .domani, .daFinire:
            return cal.isDate(c.perIl, inSameDayAs: oggi)
        case .fascicolo:
            return dati.appuntamenti.contains { $0.id == c.riferimento && $0.stato == .pianificato && $0.inizio > oggi }
        case .documento:
            guard let id = c.clienteId, let cl = dati.clienti.first(where: { $0.id == id }),
                  let s = cl.conformita?.documento?.scadenza else { return false }
            return c.riferimento == "\(id)·\(NotteDiLavoro.chiave(s, cal: cal))"
                && !dati.messaggi.contains { m in m.clienteId == id && m.origine.tipo == .documentoIdentita && m.origine.riferimento == c.riferimento }
        case .riesame:
            guard let id = c.clienteId else { return false }
            return MotoreRiesame.dovuti(clienti: dati.clienti.filter { $0.id == id }, posizioni: dati.posizioni.filter { $0.clienteId == id },
                                        appuntamenti: dati.appuntamenti.filter { $0.clienteId == id },
                                        incontri: dati.incontri.filter { $0.clienteId == id }, oggi: inizio).contains { $0.cliente.id == id }
        case .moduli:
            return dati.posizioni.contains { $0.id == c.riferimento && $0.stato == .proposta && $0.esito != .rifiutata }
        case .campagna:
            return gruppi.contains(c.riferimento)
        case .messaggio:
            return occasioni.contains(c.riferimento) && !dati.messaggi.contains { $0.occasioneId == c.riferimento }
        }
    }

    /// Le rimandate (e le non decise) delle notti prima, ancora valide, da mettere in fondo alla notte nuova (stesso id).
    static func daIeri(_ notti: [NotteDiLavoro], giorno g: Date, valida: (CartaNotte) -> Bool, cal: Calendar = .current) -> [CartaNotte] {
        let giorno = cal.startOfDay(for: g)
        let limite = cal.date(byAdding: .day, value: -ImpostazioniNotte.giorniDaIeri, to: giorno) ?? giorno
        var visti = Set<String>()
        var elenco: [CartaNotte] = []
        // Dalla notte più recente: una carta passata da una notte all'altra c'è più volte, vale l'ultima
        for n in notti.sorted(by: { $0.giorno > $1.giorno }) where n.giorno < giorno {
            for c in n.carte where c.perIl >= limite && !visti.contains(c.id) {
                visti.insert(c.id)
                if !c.decisa && valida(c) { elenco.append(c) }
            }
        }
        return elenco.sorted { ($0.perIl, $0.preparataIl, $0.id) < ($1.perIl, $1.preparataIl, $1.id) }
    }

    /// La pila di un'apertura: da decidere del giorno, poi rimandate del giorno, poi DA IERI.
    static func pila(_ n: NotteDiLavoro, cal: Calendar = .current) -> [CartaNotte] {
        let giorno = cal.startOfDay(for: n.giorno)
        let aperte = n.carte.filter { !$0.decisa }
        let diOggi = aperte.filter { $0.perIl >= giorno }
        return diOggi.filter { $0.stato == .daDecidere } + diOggi.filter { $0.stato == .rimandata } + aperte.filter { $0.perIl < giorno }
    }

    /// La carta è «DA IERI» nella notte data.
    static func daIeri(_ c: CartaNotte, in n: NotteDiLavoro, cal: Calendar = .current) -> Bool {
        c.perIl < cal.startOfDay(for: n.giorno)
    }

    /// Ultime 14; le «inCorso» lasciate da un'uscita a metà diventano «interrotta» (tranne quella che sta lavorando adesso,
    /// `inCorsoAdesso`).
    static func pota(_ notti: [NotteDiLavoro], adesso: Date, inCorsoAdesso: String? = nil) -> [NotteDiLavoro] {
        var elenco = Array(notti.sorted { $0.giorno > $1.giorno }.prefix(ImpostazioniNotte.massimoNotti))
        for i in elenco.indices where elenco[i].esito == .inCorso && elenco[i].giornoChiave != inCorsoAdesso {
            elenco[i].esito = .interrotta
            if elenco[i].motivoStop == nil { elenco[i].motivoStop = .chiusura }
        }
        return elenco
    }

    /// Le carte da decidere di una notte (per il pallino e la notifica).
    static func daDecidere(_ n: NotteDiLavoro?, cal: Calendar = .current) -> Int {
        guard let n else { return 0 }
        return pila(n, cal: cal).filter { $0.stato == .daDecidere || $0.stato == .rimandata }.count
    }
}
