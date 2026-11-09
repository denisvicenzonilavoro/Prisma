import Foundation

// «Scrive come te» nell'app (Vera/BRIEF.md, funzione 15; motore in Vera/StileVera.swift). Il profilo di stile del
// consulente sta in `Impostazioni.stileVera` (nell'archivio, nei backup e nello spazio di «Prisma ovunque»: solo regole,
// mai testi dei messaggi). Si impara da solo dai messaggi aperti in Mail o in Messaggi (statistiche del codice, nessun
// testo inventato) e il consulente lo corregge: dalle Impostazioni con le sue mani, oppure a parole in chat, e allora
// Vera prepara la scheda «Conferma» (strumento `stile_cambia`) e niente cambia prima del sì. Ogni bozza di Messaggi
// segue il profilo: le istruzioni per Qwen, i ritocchi sicuri del codice e la verifica; se il testo di Vera rompe una
// regola grave resta il testo di Prisma. Mai un invio: le bozze si aprono in Mail o in Messaggi dal consulente.

/// La scheda di «Scrive come te» sotto una risposta di Vera (`MessaggioVera.stileVera`): il profilo (letto sempre
/// aggiornato dalle impostazioni) oppure una bozza riscritta nello stile, con la versione generica accanto.
struct SchedaStileVera: Codable, Equatable {
    enum Tipo: String, Codable { case profilo, bozza }

    var tipo: Tipo
    var clienteId: String?
    var canale: CanaleMessaggio?
    /// Il testo di partenza (scritto dal consulente o il modello fisso di Prisma).
    var generica: String?
    /// Lo stesso testo nello stile del consulente.
    var inStile: String?
    /// Cosa hanno cambiato i ritocchi («Firma: «Denis»», «Tolta «Restiamo a disposizione»»).
    var modifiche: [String] = []
    /// Le regole che il testo in stile non rispetta ancora (da sistemare a mano).
    var violazioni: [String] = []
    /// Una regola grave non rispettata (tu al posto del Lei, una formula vietata): «Usa questa bozza» resta spento.
    var grave = false
    /// La riscrittura l'ha fatta Qwen (le cifre controllate); false = solo i ritocchi del codice.
    var conQwen = false

    init(tipo: Tipo, clienteId: String? = nil, canale: CanaleMessaggio? = nil, generica: String? = nil, inStile: String? = nil,
         modifiche: [String] = [], violazioni: [String] = [], grave: Bool = false, conQwen: Bool = false) {
        self.tipo = tipo
        self.clienteId = clienteId
        self.canale = canale
        self.generica = generica
        self.inStile = inStile
        self.modifiche = modifiche
        self.violazioni = violazioni
        self.grave = grave
        self.conQwen = conQwen
    }

    private enum CodingKeys: String, CodingKey { case tipo, clienteId, canale, generica, inStile, modifiche, violazioni, grave, conQwen }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tipo = (try? c.decodeIfPresent(Tipo.self, forKey: .tipo)) ?? .profilo
        clienteId = (try? c.decodeIfPresent(String.self, forKey: .clienteId)) ?? nil
        canale = (try? c.decodeIfPresent(CanaleMessaggio.self, forKey: .canale)) ?? nil
        generica = (try? c.decodeIfPresent(String.self, forKey: .generica)) ?? nil
        inStile = (try? c.decodeIfPresent(String.self, forKey: .inStile)) ?? nil
        modifiche = ((try? c.decodeIfPresent([String].self, forKey: .modifiche)) ?? nil) ?? []
        violazioni = ((try? c.decodeIfPresent([String].self, forKey: .violazioni)) ?? nil) ?? []
        grave = ((try? c.decodeIfPresent(Bool.self, forKey: .grave)) ?? nil) ?? false
        conQwen = ((try? c.decodeIfPresent(Bool.self, forKey: .conQwen)) ?? nil) ?? false
        // Una bozza senza testo non si mostra come bozza
        if tipo == .bozza, (inStile ?? "").isEmpty { tipo = .profilo }
    }
}

/// Cosa serve a «Annulla» di una scheda `stile_cambia` (in `EsitoAzioneVera.prima`, come JSON): la regola toccata,
/// l'operazione e il profilo di prima e di dopo la scheda (solo regole, mai testi dei messaggi).
struct AnnullaStileVera: Codable, Equatable {
    var regola: ChiaveRegolaStile
    var operazione: String
    var prima: ProfiloStile
    var dopo: ProfiloStile
}

// MARK: - Lo strumento della scheda

extension RegistroStrumenti {
    /// Cambia una regola del profilo di stile (scrive un valore, spegne o riaccende). Solo per Prisma: lo preparano le
    /// regole di «Scrive come te», non il modello.
    static let stileCambia = "stile_cambia"

    static var strumentoStile: StrumentoVera {
        StrumentoVera(nome: stileCambia, app: .vera,
                      descrizione: "Cambia una regola del profilo di stile del consulente (firma, tu o Lei, emoji, lunghezza delle frasi, saluti).",
                      parametri: ["type": "object", "properties": [String: Any](), "required": [String]()],
                      disponibile: true, annullabile: true, nelDossier: false, soloPrisma: true)
    }

    /// Un messaggio preparato da «Fallo tu» (`messaggi_prepara`) prende la forma del profilo: saluto, chiusura e firma
    /// del consulente, via le formule da ufficio e le emoji vietate. Le regole gravi ancora violate diventano l'avviso
    /// della riga (tu al posto del Lei: il codice non cambia le parole del testo).
    static func messaggioInStile(_ testo: String, cliente: Cliente, contesto x: ContestoStrumenti,
                                 clienteNuovo nuovo: Bool? = nil) -> (testo: String, avviso: String?) {
        let p = x.impostazioni.stileVera
        guard !p.vuoto, !testo.isEmpty else { return (testo, nil) }
        let clienteNuovo = nuovo ?? x.clientiScritti.map { !$0.contains(cliente.id) } ?? false
        let b = StileVera.applica(testo, profilo: p, cliente: cliente, oggi: x.oggi, clienteNuovo: clienteNuovo)
        let v = StileVera.verifica(b.testo, profilo: p, cliente: cliente, oggi: x.oggi, clienteNuovo: clienteNuovo)
        return (b.testo, v.first(where: \.grave).map { "Il tuo stile: \($0.spiegazione)" })
    }
}

// MARK: - La scrittura dei messaggi con lo stile

/// La scrittura di un messaggio di Messaggi come MessaggiVera.scrivi, con il profilo di stile: le istruzioni di stile
/// accodate a quelle fisse per Qwen, poi i ritocchi sicuri del codice e la verifica. Una regola grave non rispettata
/// (tu al posto del Lei, una formula vietata, un'emoji vietata) fa restare il testo di Prisma, ritoccato, con l'avviso.
/// Fuori dal thread principale come MessaggiVera.scrivi.
enum ScritturaStileVera {
    static func scrivi(_ o: OccasioneMessaggio, cliente: Cliente, tono: TonoMessaggio, canale: CanaleMessaggio, firma: String?,
                       profilo: ProfiloStile, clienteNuovo: Bool, oggi: Date, motore: MotoreLocale?, vera: ImpostazioniVera,
                       aggiorna: ((String) -> Void)? = nil) async -> TestoScrittoMessaggio {
        let bozza = ModelliMessaggi.testo(o, tono: tono, canale: canale, cliente: cliente, firma: firma)
        // Il testo di Prisma con i ritocchi del profilo (nessuna parola nuova nel corpo, nessuna cifra)
        func fisso(_ avviso: String?) -> TestoScrittoMessaggio {
            var t = MessaggiVera.fisso(bozza, avviso: avviso)
            t.testo = StileVera.applica(t.testo, profilo: profilo, cliente: cliente, oggi: oggi, clienteNuovo: clienteNuovo).testo
            return t
        }
        guard let motore else { return fisso(MessaggiVera.avvisoNonPronta(nil)) }
        guard motore.disponibilita.pronto else { return fisso(MessaggiVera.avvisoNonPronta(motore.disponibilita.motivo)) }
        var p = MessaggiVera.piano(o, cliente: cliente, tono: tono, canale: canale, bozza: bozza, vera: vera)
        p.messaggi = StileVera.conStile(p.messaggi, profilo: profilo, cliente: cliente, oggi: oggi, clienteNuovo: clienteNuovo)
        do {
            var suPezzo: ((ParzialeVera) -> Void)?
            if let aggiorna {
                let fatti = MessaggiVera.ammessi(o, cliente: cliente, bozza: bozza)
                suPezzo = { parziale in
                    let t = MessaggiVera.pulisci(parziale.testo, firma: firma)
                    if MessaggiVera.mostrabile(t, fatti: fatti) { aggiorna(t) }
                }
            }
            let r = try await motore.scrivi(p, aggiorna: suPezzo)
            let pulito = MessaggiVera.pulisci(r.testo, firma: firma)
            if let motivo = MessaggiVera.controlla(pulito, occasione: o, cliente: cliente, tono: tono, bozza: bozza) {
                return fisso(maiuscola(motivo) + ": resta il testo di Prisma, con le cifre esatte.")
            }
            let ritoccato = StileVera.applica(pulito + bozza.chiusura, profilo: profilo, cliente: cliente, oggi: oggi, clienteNuovo: clienteNuovo)
            let violazioni = StileVera.verifica(ritoccato.testo, profilo: profilo, cliente: cliente, oggi: oggi, clienteNuovo: clienteNuovo)
            if let motivo = StileVera.motivoScarto(violazioni) {
                return fisso(maiuscola(motivo) + ": resta il testo di Prisma, con le cifre esatte.")
            }
            return TestoScrittoMessaggio(oggetto: bozza.oggetto, testo: ritoccato.testo, autore: .vera, modello: motore.modello, avviso: nil)
        } catch is CancellationError {
            return fisso("Riscrittura interrotta: resta il testo di Prisma.")
        } catch {
            let m = (error as? ErroreVera)?.messaggio ?? error.localizedDescription
            return fisso("Vera non ha potuto scrivere il messaggio (\(m)). Resta il testo di Prisma.")
        }
    }

    static func maiuscola(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return primo.uppercased() + s.dropFirst()
    }

    /// Le istruzioni della riscrittura di un testo del consulente (Vera/Istruzioni/stile-riscrivi.md, con un ripiego).
    static var istruzioniRiscrivi: String {
        IstruzioniVera.testo("stile-riscrivi") ?? "Riscrivi in italiano il messaggio del consulente a un suo cliente, nella forma del suo profilo di stile. Non aggiungere né togliere fatti, numeri, date, ore o promesse. Scrivi solo il testo del messaggio, dal saluto all'ultima frase, senza firma e senza commenti."
    }

    /// Con un valore nuovo una regola diventa «scritta da te»; senza valore (regola tolta) resta nel profilo, spenta,
    /// così l'apprendimento non la riaccende. Un valore uguale a quello di prima riaccende la regola e basta.
    static func metti<V>(_ k: WritableKeyPath<ProfiloStile, RegolaStile<V>?>, attiva: Bool, valore: V?, in p: inout ProfiloStile) {
        guard attiva, let valore else {
            p[keyPath: k]?.attiva = false
            return
        }
        if let r = p[keyPath: k] {
            if r.valore == valore { p[keyPath: k]?.attiva = true } else { p[keyPath: k]?.scrivi(valore) }
        } else {
            p[keyPath: k] = .scritta(valore)
        }
    }

    /// Uguali nelle regole (la data dell'ultimo apprendimento non conta).
    static func stesseRegole(_ a: ProfiloStile, _ b: ProfiloStile) -> Bool {
        var x = a
        x.aggiornatoIl = b.aggiornatoIl
        return x == b
    }

    static func json<T: Encodable>(_ p: T) -> String? {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return (try? e.encode(p)).flatMap { String(data: $0, encoding: .utf8) }
    }

    static func daJSON(_ s: String?) -> ProfiloStile? {
        guard let d = s?.data(using: .utf8) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(ProfiloStile.self, from: d)
    }

    static func annullaDaJSON(_ s: String?) -> AnnullaStileVera? {
        guard let d = s?.data(using: .utf8) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(AnnullaStileVera.self, from: d)
    }

    /// Il profilo dopo «Annulla» di una scheda `stile_cambia`: solo la regola della scheda torna com'era. nil se la regola
    /// è cambiata dopo la scheda (niente si tocca) o se il salvataggio non si legge. Le schede salvate prima (con il
    /// profilo intero in `prima`) rimettono solo la regola indicata da `oggetto`.
    static func annulla(_ salvato: String?, oggetto: String?, su attuale: ProfiloStile) -> ProfiloStile? {
        var p = attuale
        if let u = annullaDaJSON(salvato) {
            let k = u.regola
            if u.operazione == "spegni" || u.operazione == "accendi" {
                // Solo l'interruttore: il valore può averlo aggiornato l'apprendimento, e resta
                guard attiva(k, attuale) == attiva(k, u.dopo), let era = attiva(k, u.prima) else { return nil }
                p.imposta(k, attiva: era)
            } else {
                guard stessaRegola(k, attuale, u.dopo) else { return nil }
                rimetti(k, da: u.prima, in: &p)
            }
            return p
        }
        guard let prima = daJSON(salvato), let k = ChiaveRegolaStile(rawValue: oggetto ?? "") else { return nil }
        rimetti(k, da: prima, in: &p)
        return p
    }

    /// La regola k è la stessa nei due profili (valore, origine e interruttore; il numero di messaggi non conta).
    static func stessaRegola(_ k: ChiaveRegolaStile, _ a: ProfiloStile, _ b: ProfiloStile) -> Bool {
        func uguali<V>(_ kp: KeyPath<ProfiloStile, RegolaStile<V>?>) -> Bool {
            let x = a[keyPath: kp], y = b[keyPath: kp]
            return x?.valore == y?.valore && x?.origine == y?.origine && x?.attiva == y?.attiva
        }
        switch k {
        case .cortesia: return uguali(\.cortesia)
        case .lunghezzaFrasi: return uguali(\.lunghezzaFrasi)
        case .unaCosaPerRiga: return uguali(\.unaCosaPerRiga)
        case .primaGiornoEOra: return uguali(\.primaGiornoEOra)
        case .firma: return uguali(\.firma)
        case .formuleVietate: return uguali(\.formuleVietate)
        case .emoji: return uguali(\.emoji)
        case .aperture: return uguali(\.aperture)
        case .chiusure: return uguali(\.chiusure)
        }
    }

    /// L'interruttore della regola k (nil se la regola non c'è).
    static func attiva(_ k: ChiaveRegolaStile, _ p: ProfiloStile) -> Bool? {
        switch k {
        case .cortesia: return p.cortesia?.attiva
        case .lunghezzaFrasi: return p.lunghezzaFrasi?.attiva
        case .unaCosaPerRiga: return p.unaCosaPerRiga?.attiva
        case .primaGiornoEOra: return p.primaGiornoEOra?.attiva
        case .firma: return p.firma?.attiva
        case .formuleVietate: return p.formuleVietate?.attiva
        case .emoji: return p.emoji?.attiva
        case .aperture: return p.aperture?.attiva
        case .chiusure: return p.chiusure?.attiva
        }
    }

    /// Rimette in p la sola regola k com'era in `prima` (anche nil: la regola non c'era).
    static func rimetti(_ k: ChiaveRegolaStile, da prima: ProfiloStile, in p: inout ProfiloStile) {
        switch k {
        case .cortesia: p.cortesia = prima.cortesia
        case .lunghezzaFrasi: p.lunghezzaFrasi = prima.lunghezzaFrasi
        case .unaCosaPerRiga: p.unaCosaPerRiga = prima.unaCosaPerRiga
        case .primaGiornoEOra: p.primaGiornoEOra = prima.primaGiornoEOra
        case .firma: p.firma = prima.firma
        case .formuleVietate: p.formuleVietate = prima.formuleVietate
        case .emoji: p.emoji = prima.emoji
        case .aperture: p.aperture = prima.aperture
        case .chiusure: p.chiusure = prima.chiusure
        }
    }

    /// Un elenco scritto una voce per riga (o separato da «·»).
    static func elenco(_ s: String) -> [String] {
        s.components(separatedBy: CharacterSet(charactersIn: "\n·"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// La regola di cui parla una frase («la regola della firma», «delle emoji», «del tu e del Lei»).
    static func regola(_ s: String) -> ChiaveRegolaStile? {
        let t = s.lowercased()
        if t.contains("firma") { return .firma }
        if t.contains("emoji") { return .emoji }
        if t.contains("chiusur") || t.contains("saluto finale") || t.contains("saluti finali") { return .chiusure }
        if t.contains("apertur") || t.contains("saluto") || t.contains("saluti") { return .aperture }
        if t.contains("formul") || t.contains("ufficio") { return .formuleVietate }
        if t.contains("riga") { return .unaCosaPerRiga }
        if t.contains("giorno") || t.contains(" ora") { return .primaGiornoEOra }
        if t.contains("frasi") || t.contains("lunghezza") || t.contains("parole") { return .lunghezzaFrasi }
        if t.contains("tu") || t.contains("lei") || t.contains("cortesia") { return .cortesia }
        return nil
    }
}

// MARK: - Lo stato

extension StatoShell {
    /// Le bozze di una scheda «Conferma» (messaggi_prepara) prendono la forma del profilo di stile, come in «Fallo tu»:
    /// saluto, chiusura, firma, via emoji e formule vietate; una regola grave ancora violata diventa l'avviso della riga.
    func inStile(_ scheda: SchedaConfermaVera?) -> SchedaConfermaVera? {
        guard var s = scheda, !dati.impostazioni.stileVera.vuoto,
              s.azioni.contains(where: { $0.strumento == RegistroStrumenti.messaggiPrepara }) else { return scheda }
        Self.bozzeMercatoInStile(&s, clienti: dati.clienti, contesto: contestoStrumenti)
        return s
    }

    /// L'ancora del gruppo «Il tuo stile» in Impostazioni › Vera.
    static let ancoraStileVera = "impostazioni-stile-vera"

    /// Il profilo di stile del consulente.
    var profiloStileVera: ProfiloStile { dati.impostazioni.stileVera }

    // MARK: Il profilo

    /// Impara di nuovo dai messaggi aperti in Mail o in Messaggi, tenendo le regole scritte e quelle spente dal
    /// consulente. Si salva solo se una regola è cambiata (la data da sola non riscrive l'archivio).
    @discardableResult
    func aggiornaStileVera(oggi: Date = Date()) -> ProfiloStile {
        let attuale = dati.impostazioni.stileVera
        let nuovo = StileVera.aggiorna(attuale, messaggi: dati.messaggi, clienti: dati.clienti, oggi: oggi)
        guard !solaLettura else { return attuale }
        if !ScritturaStileVera.stesseRegole(nuovo, attuale) || nuovo.messaggiLetti != attuale.messaggiLetti || nuovo.mailLette != attuale.mailLette {
            dati.impostazioni.stileVera = nuovo
        }
        return dati.impostazioni.stileVera
    }

    /// Impara solo se da allora sono usciti messaggi nuovi (all'apertura della scheda «Il tuo stile»).
    func aggiornaStileVeraSeServe(oggi: Date = Date()) {
        let usciti = StileVera.inviati(dati.messaggi)
        let p = dati.impostazioni.stileVera
        guard usciti.count != p.messaggiLetti + p.mailLette else { return }
        aggiornaStileVera(oggi: oggi)
    }

    /// L'interruttore di una regola nella scheda «Il tuo stile» (lo tocca il consulente: niente scheda di conferma).
    func accendiRegolaStile(_ k: ChiaveRegolaStile, attiva: Bool) {
        guard !solaLettura, !inModoCliente else { return }
        dati.impostazioni.stileVera.imposta(k, attiva: attiva)
    }

    /// Le regole scritte dal consulente nel foglio «Modifica lo stile».
    func scriviProfiloStileVera(_ cambia: (inout ProfiloStile) -> Void) {
        guard !solaLettura, !inModoCliente else { return }
        var p = dati.impostazioni.stileVera
        cambia(&p)
        if p != dati.impostazioni.stileVera { dati.impostazioni.stileVera = p }
    }

    /// Toglie l'eccezione del tu o del Lei di un cliente: cambia solo le eccezioni, la regola resta accesa o spenta
    /// com'era e non diventa «scritta da te» (l'eccezione è del consulente, la regola di base può restare imparata).
    func togliEccezioneStile(_ clienteId: String) {
        guard !solaLettura, !inModoCliente, var r = dati.impostazioni.stileVera.cortesia,
              r.valore.perCliente[clienteId] != nil else { return }
        r.valore.perCliente[clienteId] = nil
        dati.impostazioni.stileVera.cortesia = r
    }

    /// Apre la scheda «Il tuo stile» in Impostazioni › Vera.
    func apriStileVera() {
        schedaImpostazioni = .vera
        ancoraImpostazioni = Self.ancoraStileVera
        apri(.impostazioni)
    }

    // MARK: Le bozze

    func clienteNuovoStile(_ id: String) -> Bool { StileVera.clienteNuovo(id, messaggi: dati.messaggi) }

    /// Le regole del profilo che un testo per questo cliente non rispetta.
    func violazioniStile(_ testo: String, clienteId: String?, oggi: Date = Date()) -> [ViolazioneStile] {
        let p = dati.impostazioni.stileVera
        guard !p.vuoto, !testo.isEmpty else { return [] }
        let c = clienteId.flatMap { cliente($0) }
        return StileVera.verifica(testo, profilo: p, cliente: c, oggi: oggi, clienteNuovo: clienteId.map(clienteNuovoStile) ?? false)
    }

    /// Un testo nello stile del consulente, con i soli ritocchi del codice, e cosa resta da sistemare.
    func schedaBozzaStile(_ testo: String, clienteId: String?, oggi: Date = Date()) -> SchedaStileVera {
        let p = dati.impostazioni.stileVera
        let c = clienteId.flatMap { cliente($0) }
        let nuovo = clienteId.map(clienteNuovoStile) ?? false
        let b = StileVera.applica(testo, profilo: p, cliente: c, oggi: oggi, clienteNuovo: nuovo)
        let v = StileVera.verifica(b.testo, profilo: p, cliente: c, oggi: oggi, clienteNuovo: nuovo)
        return SchedaStileVera(tipo: .bozza, clienteId: c?.id, canale: c.map(Self.canaleStile), generica: testo, inStile: b.testo,
                               modifiche: b.modifiche, violazioni: v.map(\.spiegazione), grave: v.contains(where: \.grave))
    }

    static func canaleStile(_ c: Cliente) -> CanaleMessaggio {
        c.telefono.filter(\.isNumber).count >= 6 ? .messaggi : .mail
    }

    /// L'esempio della scheda «Il tuo stile»: la prima occasione dei Messaggi di oggi, scritta dal modello generico di
    /// Prisma (formale, firma di sempre) e poi come la scrive il consulente. nil senza occasioni o senza regole.
    func esempioStileVera(oggi: Date = Date()) -> SchedaStileVera? {
        let p = dati.impostazioni.stileVera
        guard !p.vuoto, let o = occasioniMessaggi(oggi: oggi).tutte.first(where: { cliente($0.clienteId) != nil }),
              let c = cliente(o.clienteId) else { return nil }
        let canale = Self.canaleStile(c)
        let generica = ModelliMessaggi.testo(o, tono: .formale, canale: canale, cliente: c, firma: firmaMessaggio(o.canale, tono: .formale)).completo
        let tono = StileVera.tono(p, cliente: c, oggi: oggi, richiesto: .cordiale)
        let firma = StileVera.firma(p) ?? firmaMessaggio(o.canale, tono: tono)
        let base = ModelliMessaggi.testo(o, tono: tono, canale: canale, cliente: c, firma: firma).completo
        let nuovo = clienteNuovoStile(c.id)
        let b = StileVera.applica(base, profilo: p, cliente: c, oggi: oggi, clienteNuovo: nuovo)
        let v = StileVera.verifica(b.testo, profilo: p, cliente: c, oggi: oggi, clienteNuovo: nuovo)
        return SchedaStileVera(tipo: .bozza, clienteId: c.id, canale: canale, generica: generica, inStile: b.testo,
                               modifiche: b.modifiche, violazioni: v.map(\.spiegazione), grave: v.contains(where: \.grave))
    }

    /// Il testo di un messaggio di Messaggi nello stile del consulente (prende il posto del corpo di `scriviMessaggio`):
    /// il tu o Lei del profilo decide il tono, la firma del profilo quella del messaggio. Senza regole, com'era prima.
    @MainActor
    func scriviMessaggioInStile(_ o: OccasioneMessaggio, tono richiesto: TonoMessaggio, canale: CanaleMessaggio,
                                aggiorna: ((String) -> Void)? = nil) async -> TestoScrittoMessaggio? {
        guard let c = dati.clienti.first(where: { $0.id == o.clienteId }) else { return nil }
        let vera = dati.impostazioni.vera
        let profilo = dati.impostazioni.stileVera
        let motore = MotoriVera.qwen(vera, locale: disponibilitaLocale)
        guard !profilo.vuoto else {
            return await MessaggiVera.scrivi(o, cliente: c, tono: richiesto, canale: canale, firma: firmaMessaggio(o.canale, tono: richiesto),
                                            motore: motore, vera: vera, aggiorna: aggiorna)
        }
        let oggi = Date()
        let tono = StileVera.tono(profilo, cliente: c, oggi: oggi, richiesto: richiesto)
        let firma = StileVera.firma(profilo) ?? firmaMessaggio(o.canale, tono: tono)
        var scritto = await ScritturaStileVera.scrivi(o, cliente: c, tono: tono, canale: canale, firma: firma, profilo: profilo,
                                                      clienteNuovo: clienteNuovoStile(c.id), oggi: oggi, motore: motore, vera: vera, aggiorna: aggiorna)
        // Il messaggio salvato porta il tono con cui è scritto davvero (il profilo può aver cambiato quello chiesto)
        if tono != richiesto { scritto.tono = tono }
        return scritto
    }

    /// «Usa questa bozza»: la scheda «Conferma» con la bozza da preparare in Messaggi (mai un invio).
    @discardableResult
    func proponiBozzaStile(_ s: SchedaStileVera, chiave: String? = nil) -> MessaggioVera? {
        // La scheda della chat è quella di quando è stata scritta: il profilo può essere cambiato da allora (il Lei al posto
        // del tu, una formula vietata). Si rifanno ritocchi e verifica con il profilo di adesso, e vale quel risultato.
        guard let id = s.clienteId, let c = cliente(id), let scritta = s.inStile, !scritta.isEmpty else {
            mostraAvviso("Sistema prima la bozza: non segue ancora il tuo stile")
            return nil
        }
        let adesso = schedaBozzaStile(scritta, clienteId: c.id)
        guard !adesso.grave, let testo = adesso.inStile, !testo.isEmpty else {
            mostraAvviso("Sistema prima la bozza: non segue ancora il tuo stile")
            return nil
        }
        let canale = s.canale ?? Self.canaleStile(c)
        let a = AzioneConferma(strumento: RegistroStrumenti.messaggiPrepara, app: .messaggi, titolo: "Preparo un messaggio per \(c.nome)",
                               dettaglio: RegistroStrumenti.dettaglioMessaggio(testo, canale: canale),
                               argomenti: ["cliente": c.id, "scopo": "altro", "testo": testo, "canale": canale.rawValue,
                                           // Il tu o Lei del profilo (come in schedaBozza): con il tu cordiale, con il Lei formale
                                           "tono": StileVera.tono(dati.impostazioni.stileVera, cliente: c, oggi: Date(), richiesto: .cordiale).rawValue])
        let k = chiave ?? (veraPortafoglio ? VeraPortafoglio.chiave : c.id)
        var m = MessaggioVera(autore: .vera, testo: "Ti preparo la bozza nel tuo stile: la trovi in Messaggi solo dopo «Conferma», e la spedisci tu.",
                              motore: Self.motoreAzioni)
        // Come tutte le bozze `messaggi_prepara`: passa da `inStile` (una violazione rimasta diventa l'avviso della riga)
        let scheda = SchedaConfermaVera(richiesta: "Usa la bozza nel mio stile per \(c.nome)", azioni: [a], origine: .regole)
        m.conferma = inStile(scheda) ?? scheda
        aggiungiMessaggio(m, cliente: k)
        if chiave == nil {
            if !inModoCliente, !veraPortafoglio { clienteAttivoId = c.id }
            apri(.vera)
        }
        return m
    }

    // MARK: In chat

    static let richiestaProfiloStile = #"\b(?:il mio stile|mio modo di scrivere|profilo di stile|scrivi come me|scrive come me|regole (?:del|di) stile|che stile ho|il tuo stile)\b|^(?:(?:dimmi|mostrami|spiegami|fammi vedere)\s+)?come scrivo(?: io)?(?: di solito)?(?: (?:ai|coi|con i) (?:miei )?clienti| i (?:miei )?messaggi)?$"#
    /// Una richiesta di scrivere qualcosa a qualcuno («mi scrivi la mail per Sofia con il mio stile», «puoi scrivere a
    /// Giulia con il mio stile che…»): va a «Fallo tu» e alla chat, non alla scheda del profilo.
    static let richiestaScritturaStile = #"\b(?:scriv\w*|mail|e-mail|email|messaggio|sms|whatsapp|bozza)\b.*(?:\b(?:a|ad|per)\s+\w+|\bche\b)"#

    /// Due righe del profilo dicono la stessa regola (la provenienza «imparata da N messaggi» non conta).
    static func stessaVoceStile(_ a: VoceStile?, _ b: VoceStile?) -> Bool {
        a?.testo == b?.testo && a?.attiva == b?.attiva && a?.dettaglio == b?.dettaglio
    }

    /// La frase chiede di vedere il profilo di stile (e non di scrivere un messaggio).
    static func chiedeProfiloStile(_ t: String) -> Bool {
        DateItaliane.cerca(richiestaProfiloStile, t) != nil
            && DateItaliane.cerca(verboAzione, t) == nil
            && DateItaliane.cerca(richiestaScritturaStile, t) == nil
    }
    static let richiestaImparaStile = #"^(?:impara|reimpara|aggiorna|rileggi|ricalcola)\b.{0,40}\b(?:stile|modo di scrivere)\b"#
    static let richiestaRiscriviStile = #"^\s*(?:(?:ehi|ok|senti|ciao|vera|ruby|eve|per favore)[,\s]+)*(?:mi\s+)?(?:riscrivi(?:lo|la|mi)?|scrivi(?:lo|la)?|rifai|sistema|metti)\b[^:\n]{0,80}?(?:nel mio stile|con il mio stile|come (?:lo |la )?(?:scrivo|scriverei|scriveresti) io|come (?:lo |la )?scriverei|come me)\b[^:\n]{0,60}:\s*"#
    static let prefissoDaOra = #"(?:da ora|d'ora in (?:poi|avanti)|da adesso|da oggi)(?: in poi)?[,:]?\s+"#

    /// Le richieste di «Scrive come te»: il profilo, imparare di nuovo, riscrivere un testo nello stile e cambiare una
    /// regola (con la scheda «Conferma»). true se la frase era per lo stile.
    func chiediStileVera(_ testo: String, chiave: String, oggi: Date = Date()) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        // 1. «Riscrivi nel mio stile: …» (il testo dopo i due punti può contenere di tutto)
        if let r = testo.range(of: Self.richiestaRiscriviStile, options: [.regularExpression, .caseInsensitive]) {
            let daScrivere = String(testo[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard daScrivere.count >= 10 else { return false }
            apriRichiestaStile(testo, chiave: chiave)
            let prefisso = String(testo[..<r.upperBound])
            riscriviNelloStile(daScrivere, clienteId: clienteDellaRichiesta(prefisso, chiave: chiave), chiave: chiave, oggi: oggi)
            return true
        }
        // 2. Cambiare una regola: solo con la scheda «Conferma»
        if let cambio = cambioStile(testo, chiave: chiave) {
            apriRichiestaStile(testo, chiave: chiave)
            if inModoCliente {
                rispostaStile("Il tuo stile si cambia fuori dalla modalità cliente: qui resto sul dossier di \(clienteAttivo?.nome ?? "questo cliente").", chiave: chiave)
                return true
            }
            switch cambio {
            case .azione(let a):
                var m = MessaggioVera(autore: .vera, testo: "Cambio il tuo stile appena confermi: da lì in poi le bozze lo seguono.", motore: Self.motoreAzioni)
                m.conferma = SchedaConfermaVera(richiesta: testo, azioni: [a], origine: .regole)
                aggiungiMessaggio(m, cliente: chiave)
            case .domanda(let d), .impossibile(let d):
                rispostaStile(d, chiave: chiave)
            }
            return true
        }
        // 3. «Impara di nuovo il mio stile»
        if DateItaliane.cerca(Self.richiestaImparaStile, t) != nil {
            apriRichiestaStile(testo, chiave: chiave)
            let prima = dati.impostazioni.stileVera
            let p = aggiornaStileVera(oggi: oggi)
            let vociPrima = StileVera.voci(prima, clienti: dati.clienti)
            let vociOra = StileVera.voci(p, clienti: dati.clienti)
            let cambiate = ChiaveRegolaStile.allCases.filter { k in
                let a = vociPrima.first(where: { $0.id == k }), b = vociOra.first(where: { $0.id == k })
                return !Self.stessaVoceStile(a, b)
            }.count
            let detto = cambiate == 0 ? "Riletti i messaggi: il tuo stile è lo stesso." :
                (cambiate == 1 ? "Riletti i messaggi: una regola è cambiata." : "Riletti i messaggi: \(cambiate) regole sono cambiate.")
            rispostaStile(detto + " " + StileVera.intestazione(p), chiave: chiave, scheda: SchedaStileVera(tipo: .profilo))
            return true
        }
        // 4. «Mostrami il mio stile», «come scrivo ai clienti?»
        if Self.chiedeProfiloStile(t) {
            apriRichiestaStile(testo, chiave: chiave)
            let p = dati.impostazioni.stileVera
            let n = StileVera.voci(p, clienti: dati.clienti).filter(\.attiva).count
            let detto = p.vuoto ? StileVera.intestazione(p) :
                StileVera.intestazione(p) + (n == 1 ? " Una regola accesa." : " \(n) regole accese.") + " Le bozze dei messaggi le seguono tutte."
            rispostaStile(detto, chiave: chiave, scheda: SchedaStileVera(tipo: .profilo))
            return true
        }
        return false
    }

    private func apriRichiestaStile(_ testo: String, chiave: String) {
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
    }

    @discardableResult
    private func rispostaStile(_ testo: String, chiave: String, scheda: SchedaStileVera? = nil, motore: String? = nil) -> MessaggioVera {
        var m = MessaggioVera(autore: .vera, testo: testo, titolo: scheda == nil ? nil : "Il tuo stile", motore: motore ?? MotoriVera.sintesi.nome)
        m.stileVera = scheda
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    /// Riscrive un testo nello stile: Qwen (se è pronto) con le istruzioni di stile, poi sempre i ritocchi del codice e la
    /// verifica. Il testo di Qwen vale solo con le stesse cifre e nessuna promessa; altrimenti restano i ritocchi.
    func riscriviNelloStile(_ testo: String, clienteId: String?, chiave: String, oggi: Date = Date()) {
        let p = dati.impostazioni.stileVera
        guard !p.vuoto else {
            rispostaStile("Non ho ancora regole di stile: le imparo dai messaggi che apri da Prisma in Mail o in Messaggi, oppure le scrivi tu in Impostazioni › Vera › Il tuo stile.",
                          chiave: chiave, scheda: SchedaStileVera(tipo: .profilo))
            return
        }
        let codice = schedaBozzaStile(testo, clienteId: clienteId, oggi: oggi)
        let c = clienteId.flatMap { cliente($0) }
        func rispondi(_ s: SchedaStileVera, motore: String) {
            var detto: String
            if s.modifiche.isEmpty && !s.conQwen {
                detto = "Il testo segue già la forma del tuo stile."
            } else {
                detto = s.conQwen ? "Ecco il testo come lo scrivi tu: l'ha riscritto Qwen con le stesse cifre." :
                    (s.modifiche.count == 1 ? "Ecco il testo come lo scrivi tu: un ritocco." : "Ecco il testo come lo scrivi tu: \(s.modifiche.count) ritocchi.")
            }
            if s.grave { detto += " Una regola importante non è ancora rispettata: va sistemata prima di usarlo." }
            else if !s.violazioni.isEmpty { detto += s.violazioni.count == 1 ? " Resta una cosa da guardare." : " Restano \(s.violazioni.count) cose da guardare." }
            if c == nil { detto += " Dimmi il cliente per il tu o il Lei e la bozza in Messaggi." }
            rispostaStile(detto, chiave: chiave, scheda: s, motore: motore)
        }
        guard generativo != nil, !rispostePreparate else {
            rispondi(codice, motore: MotoriVera.sintesi.nome)
            return
        }
        let motore = qwen
        let nuovo = clienteId.map(clienteNuovoStile) ?? false
        let messaggi = [MessaggioModello(ruolo: .sistema, testo: ScritturaStileVera.istruzioniRiscrivi + "\n\n" +
                                            StileVera.istruzioni(p, cliente: c, oggi: oggi, clienteNuovo: nuovo)),
                        MessaggioModello(ruolo: .utente, testo: testo)]
        var o = OpzioniModello()
        o.temperatura = 0.3
        o.contesto = NucleoVera.finestra
        o.massimoToken = 450
        o.restaInMemoria = dati.impostazioni.vera.restaInMemoria
        o.conLezioni = false
        veraInCorso = true
        compitoVera = Task { @MainActor in
            var finale = codice
            if let r = try? await motore.scrivi(messaggi, opzioni: o).testo.trimmingCharacters(in: .whitespacesAndNewlines), !r.isEmpty,
               Self.fattiConservatiStile(bozza: testo, riscritto: r, cliente: c), DateItaliane.cerca(MessaggiVera.promesse, r.lowercased()) == nil {
                let firma = StileVera.firma(p)
                var s = self.schedaBozzaStile(MessaggiVera.pulisci(r, firma: firma), clienteId: clienteId, oggi: oggi)
                // La versione di Qwen vale solo se non rompe più regole gravi di quella del codice
                if !s.grave || codice.grave {
                    s.generica = testo
                    s.conQwen = true
                    finale = s
                }
            }
            guard !Task.isCancelled else { return }
            rispondi(finale, motore: finale.conQwen ? motore.nome : MotoriVera.sintesi.nome)
            self.veraInCorso = false
            self.compitoVera = nil
        }
    }

    /// I mesi, i giorni della settimana e i giorni vicini che una riscrittura non deve perdere.
    private static let paroleDateStile = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto",
                                          "settembre", "ottobre", "novembre", "dicembre", "lunedi", "martedi", "mercoledi",
                                          "giovedi", "venerdi", "sabato", "domenica", "oggi", "domani", "dopodomani", "stasera"]

    /// La riscrittura di Qwen tiene gli stessi fatti della bozza (stile-riscrivi.md: «non aggiungere e non togliere»):
    /// le stesse cifre nei due sensi (niente cifre nuove, nessuna ora, data o importo perso), gli stessi mesi e giorni
    /// della settimana e il nome o il cognome del cliente, se la bozza lo diceva. `numeriConservati` resta com'è (per gli
    /// altri chiamanti è un controllo di sottoinsieme sui fatti ammessi).
    static func fattiConservatiStile(bozza: String, riscritto r: String, cliente: Cliente?) -> Bool {
        guard CommentoVera.numeriConservati(bozza: bozza, testo: r),
              CommentoVera.cifre(bozza).isSubset(of: CommentoVera.cifre(r)) else { return false }
        let piana = { (s: String) in
            s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT")).replacingOccurrences(of: "’", with: "'")
        }
        let b = piana(bozza), t = piana(r)
        for p in paroleDateStile {
            let regola = "\\b\(p)\\b"
            if DateItaliane.cerca(regola, b) != nil, DateItaliane.cerca(regola, t) == nil { return false }
        }
        if let cliente {
            let (nome, cognome) = StileVera.nomeECognome(cliente)
            let nomi = [nome, cognome].map { piana($0).trimmingCharacters(in: .whitespaces) }.filter { $0.count >= 2 }
            // Il saluto può passare da «Ciao Giulia» a «Gentile Sig.ra Rossi»: basta uno dei due
            if nomi.contains(where: { b.contains($0) }), !nomi.contains(where: { t.contains($0) }) { return false }
        }
        return true
    }

    /// Una richiesta di cambiare il profilo, già pronta per la scheda; nil se la frase non è per lo stile.
    func cambioStile(_ testo: String, chiave: String) -> PreparazioneAzione? {
        // Senza saluti e richiami davanti («Vera, da ora firma…»), con le maiuscole della frase (la firma le tiene)
        let s = testo.replacingOccurrences(of: #"^\s*(?:(?:ehi|ok|senti|ciao|vera|ruby|eve|per favore|allora)[,\s]+)*"#, with: "",
                                           options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let p = dati.impostazioni.stileVera
        let da = Self.prefissoDaOra
        let virgolette = #"[«"“']?([^«»"“”\n]{1,60}?)[»"”']?\s*$"#

        // La firma: «da ora firma Denis V.», «la mia firma è «Denis»», «cambia la firma in …»
        if let (_, g) = DateItaliane.cerca("^" + da + #"(?:nei messaggi[,]?\s+|nelle mail[,]?\s+)?(?:firma(?:mi)?|firmi|firmo)\s+(?:solo\s+|sempre\s+|con\s+)?"# + virgolette, s)
            ?? DateItaliane.cerca(#"^(?:la mia firma (?:è|e'|sarà)|cambia la firma in|usa (?:la firma|come firma)|firma (?:i messaggi|le mail) (?:con|come))\s*:?\s*"# + virgolette, s) {
            var f = g[1].trimmingCharacters(in: .whitespaces)
            if f.hasSuffix("!") { f.removeLast() }
            // Il punto finale della frase va via; quello di un'iniziale («Denis V.») resta
            if f.hasSuffix("."), let ultima = f.dropLast().split(separator: " ").last, ultima.count > 2 { f.removeLast() }
            f = f.trimmingCharacters(in: .whitespaces)
            guard !f.isEmpty else { return .domanda("Come firmi i messaggi?") }
            return .azione(azioneStile(.firma, titolo: "Firmi «\(f)»", argomenti: ["valore": f]))
        }
        // Spegnere o riaccendere una regola: «spegni la regola della firma», «riaccendi la regola delle emoji»
        if let (_, g) = DateItaliane.cerca(#"^(spegni|togli|cancella|disattiva|ignora|elimina|riaccendi|accendi|riattiva|attiva|rimetti)\s+la regola\s+(.{2,40}?)\s*[.!]?$"#, s) {
            guard let k = ScritturaStileVera.regola(g[2]) else { return .domanda("Quale regola del tuo stile? Firma, tu o Lei, emoji, frasi, saluti…") }
            guard p.ha(k) else { return .impossibile("Nel tuo stile non c'è ancora la regola «\(k.nome)».") }
            let spegni = ["spegni", "togli", "cancella", "disattiva", "ignora", "elimina"].contains(g[1].lowercased())
            return .azione(azioneStile(k, titolo: (spegni ? "Spengo «" : "Riaccendo «") + k.nome + "»", operazione: spegni ? "spegni" : "accendi"))
        }
        // Tu o Lei: «dai del tu a Giulia», «dai del Lei a tutti», «del tu ai clienti sotto i 40 anni»
        if let (_, g) = DateItaliane.cerca("^(?:" + da + #")?(?:dai|da'|dà|do|dare)\s+del\s+(tu|lei)\s+(.{2,60}?)\s*[.!]?$"#, s) {
            let a: Allocuzione = g[1].lowercased() == "tu" ? .tu : .lei
            let resto = g[2].lowercased()
            if let (_, e) = DateItaliane.cerca(#"\bsotto i (\d{2}) anni\b"#, resto), let soglia = Int(e[1]), (14...110).contains(soglia) {
                return .azione(azioneStile(.cortesia, titolo: "Del tu sotto i \(soglia) anni, del Lei agli altri",
                                           argomenti: ["allocuzione": Allocuzione.lei.rawValue, "soglia": String(soglia)]))
            }
            if DateItaliane.cerca(#"^(?:a tutti|ai clienti|sempre|a tutti i clienti)\b"#, resto) != nil {
                return .azione(azioneStile(.cortesia, titolo: "Del \(a.nome) a tutti i clienti", argomenti: ["allocuzione": a.rawValue, "soglia": ""]))
            }
            let nome = resto.replacingOccurrences(of: #"^(?:a|ad)\s+"#, with: "", options: .regularExpression)
            let noti = clientiAttivi.map { ClienteNoto(id: $0.id, nome: $0.nome) }
            let trovati = InterpreteComandi.clientiNominati(InterpreteComandi.pulisci(nome), noti)
            guard trovati.count == 1, let c = cliente(trovati[0].id) else {
                return .domanda(trovati.isEmpty ? "A quale cliente dai del \(a.nome)?" : "Quale di questi clienti? " + trovati.map(\.nome).joined(separator: ", "))
            }
            // Solo l'eccezione per quel cliente. Se la regola «Tu o Lei» non c'è o è spenta, l'eccezione non varrebbe da
            // sola: la scheda dice chiaramente che la regola nasce (del Lei agli altri) o si riaccende.
            var argomenti = ["allocuzione": a.rawValue, "cliente": c.id]
            var titolo = "Del \(a.nome) a \(c.nome)"
            if let r = p.cortesia {
                if !r.attiva {
                    argomenti["riaccendi"] = "si"
                    let altri = r.valore.sogliaEta.map { "del tu sotto i \($0) anni, del Lei agli altri" } ?? "agli altri del \(r.valore.predefinita.nome)"
                    titolo += " · riaccendo la regola «\(ChiaveRegolaStile.cortesia.nome)» (\(altri))"
                }
            } else {
                titolo += " · agli altri clienti del Lei"
            }
            var azione = azioneStile(.cortesia, titolo: titolo, argomenti: argomenti)
            azione.dettaglio = p.cortesia == nil
                ? "Nel tuo stile nasce la regola «\(ChiaveRegolaStile.cortesia.nome)», scritta da te: del \(a.nome) a \(c.nome), del Lei a tutti gli altri clienti"
                : "Cambia solo l'eccezione per \(c.nome): il resto della regola resta com'è"
            return .azione(azione)
        }
        // Le emoji: «niente emoji», «mai emoji con i clienti nuovi», «emoji quando servono»
        if s.count <= 80, DateItaliane.cerca("^(?:" + da + #")?(?:niente|mai|nessuna|zero|no)\s+emoji\b"#, s) != nil {
            let v: UsoEmoji = DateItaliane.cerca(#"\bnuov"#, s) != nil ? .soloClientiNoti : .mai
            return .azione(azioneStile(.emoji, titolo: v == .mai ? "Mai emoji" : "Mai emoji con i clienti nuovi", argomenti: ["valore": v.rawValue]))
        }
        if s.count <= 80, DateItaliane.cerca("^(?:" + da + #")?(?:usa |puoi usare )?(?:le )?emoji\b.{0,30}\b(?:libere|quando servono|vanno bene|va bene|sempre)\b"#, s) != nil {
            return .azione(azioneStile(.emoji, titolo: "Emoji quando servono", argomenti: ["valore": UsoEmoji.libere.rawValue]))
        }
        // La lunghezza delle frasi: «frasi di al massimo 12 parole»
        if s.count <= 80, let (_, g) = DateItaliane.cerca("^(?:" + da + #")?(?:scrivi |usa )?frasi\b[^0-9\n]{0,30}?(\d{1,2})\s+parole\b"#, s), let n = Int(g[1]) {
            let v = min(60, max(4, n))
            return .azione(azioneStile(.lunghezzaFrasi, titolo: "Frasi di al massimo \(v) parole", argomenti: ["valore": String(v)]))
        }
        // Una cosa per riga, prima il giorno e l'ora
        if s.count <= 60, let (_, g) = DateItaliane.cerca("^(?:" + da + #")?(basta |niente |non serve )?(?:scrivi |metti )?una cosa per riga\b"#, s) {
            let si = g[1].isEmpty
            return .azione(azioneStile(.unaCosaPerRiga, titolo: si ? "Una cosa per riga" : "Niente regola «una cosa per riga»", argomenti: ["valore": si ? "true" : "false"]))
        }
        if s.count <= 70, DateItaliane.cerca("^(?:" + da + #")?(?:scrivi |metti )?prima (?:il )?giorno e (?:l')?ora\b"#, s) != nil {
            return .azione(azioneStile(.primaGiornoEOra, titolo: "Prima il giorno e l'ora, poi il resto", argomenti: ["valore": "true"]))
        }
        // I saluti di chiusura: «chiudi con «A presto!»»
        if let (_, g) = DateItaliane.cerca("^(?:" + da + #")?(?:chiudi|finisci|saluta)\s+(?:sempre\s+)?con\s+[«"“]([^«»"“”\n]{1,40})[»"”]\s*[.!]?$"#, s) {
            let v = g[1].trimmingCharacters(in: .whitespaces)
            return .azione(azioneStile(.chiusure, titolo: "Chiudi con «\(v)»", argomenti: ["valore": v]))
        }
        // Una formula da non usare: «non usare mai «cordiali saluti»»
        if let (_, g) = DateItaliane.cerca(#"^(?:"# + da + #")?non (?:usare|scrivere) (?:mai )?[«"“]([^«»"“”\n]{2,60})[»"”]\s*[.!]?$"#, s) {
            let v = g[1].trimmingCharacters(in: .whitespaces)
            return .azione(azioneStile(.formuleVietate, titolo: "Mai «\(v)»", argomenti: ["valore": v, "aggiungi": "si"]))
        }
        return nil
    }

    /// L'azione della scheda per una regola del profilo.
    func azioneStile(_ k: ChiaveRegolaStile, titolo: String, operazione: String = "scrivi", argomenti: [String: String] = [:]) -> AzioneConferma {
        var arg = argomenti
        arg["regola"] = k.rawValue
        arg["operazione"] = operazione
        let dettaglio: String
        switch operazione {
        case "spegni": dettaglio = "La regola resta nel profilo, spenta: le bozze non la seguono e l'apprendimento non la riaccende"
        case "accendi": dettaglio = "Le bozze tornano a seguirla"
        default: dettaglio = "Nel tuo stile come «scritta da te»: l'apprendimento non la cambia più"
        }
        return AzioneConferma(strumento: RegistroStrumenti.stileCambia, app: .vera, titolo: "Il tuo stile · \(titolo)", dettaglio: dettaglio, argomenti: arg)
    }

    // MARK: Esecuzione dopo «Conferma»

    /// Esegue `stile_cambia` (dal caso in `eseguiAzioneVera`). `prima` conserva la regola toccata, com'era e come la
    /// scheda l'ha scritta (`AnnullaStileVera`), per «Annulla».
    func eseguiStileVera(_ a: AzioneConferma) -> EsitoAzioneVera {
        let no = { (m: String) in EsitoAzioneVera(fatta: false, messaggio: m) }
        guard !solaLettura else { return no("Prisma è in sola lettura: non ho cambiato niente.") }
        guard !inModoCliente else { return no("In modalità cliente non cambio il tuo stile.") }
        let arg = a.argomenti
        guard let k = ChiaveRegolaStile(rawValue: arg["regola"] ?? "") else { return no("Non so quale regola del tuo stile cambiare.") }
        let prima = dati.impostazioni.stileVera
        var p = prima
        switch arg["operazione"] ?? "scrivi" {
        case "spegni", "accendi":
            guard p.ha(k) else { return no("Nel tuo stile non c'è ancora la regola «\(k.nome)».") }
            p.imposta(k, attiva: arg["operazione"] == "accendi")
        default:
            guard Self.scriviRegolaStile(k, argomenti: arg, in: &p) else { return no("Non ho capito il nuovo valore della regola «\(k.nome)».") }
        }
        let salvato = ScritturaStileVera.json(AnnullaStileVera(regola: k, operazione: arg["operazione"] ?? "scrivi", prima: prima, dopo: p))
        guard p != prima else { return EsitoAzioneVera(fatta: true, messaggio: "Il tuo stile era già così.", oggetto: k.rawValue, prima: salvato) }
        dati.impostazioni.stileVera = p
        let voce = StileVera.voci(p, clienti: dati.clienti).first { $0.id == k }
        let detto: String
        if arg["operazione"] == "spegni" { detto = "La regola «\(k.nome)» è spenta: le bozze non la seguono più." }
        else if let voce { detto = "Il tuo stile ora dice: «\(voce.testo)»." }
        else { detto = "Il tuo stile è aggiornato." }
        return EsitoAzioneVera(fatta: true, messaggio: detto, oggetto: k.rawValue, prima: salvato)
    }

    /// «Annulla»: torna com'era solo la regola della scheda; le altre regole, i contatori e ciò che l'apprendimento ha
    /// imparato dopo restano. Se intanto quella regola è cambiata (un'altra scheda, il foglio, l'interruttore) non si
    /// tocca niente e la scheda dice che le cose sono già cambiate.
    func disfaStileVera(_ a: AzioneConferma) -> Bool {
        guard let e = a.esito, e.fatta, !solaLettura else { return false }
        guard let p = ScritturaStileVera.annulla(e.prima, oggetto: e.oggetto ?? a.argomenti["regola"], su: dati.impostazioni.stileVera) else { return false }
        if p != dati.impostazioni.stileVera { dati.impostazioni.stileVera = p }
        return true
    }

    /// Scrive il valore di una regola dagli argomenti della scheda; false se il valore non si capisce.
    static func scriviRegolaStile(_ k: ChiaveRegolaStile, argomenti arg: [String: String], in p: inout ProfiloStile) -> Bool {
        let valore = (arg["valore"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        switch k {
        case .firma:
            guard !valore.isEmpty, valore.count <= 80 else { return false }
            ScritturaStileVera.metti(\.firma, attiva: true, valore: valore, in: &p)
        case .lunghezzaFrasi:
            guard let n = Int(valore), (3...80).contains(n) else { return false }
            ScritturaStileVera.metti(\.lunghezzaFrasi, attiva: true, valore: n, in: &p)
        case .unaCosaPerRiga, .primaGiornoEOra:
            guard let b = Bool(valore) else { return false }
            let kp: WritableKeyPath<ProfiloStile, RegolaStile<Bool>?> = k == .unaCosaPerRiga ? \.unaCosaPerRiga : \.primaGiornoEOra
            ScritturaStileVera.metti(kp, attiva: true, valore: b, in: &p)
        case .emoji:
            guard let e = UsoEmoji(rawValue: valore) else { return false }
            ScritturaStileVera.metti(\.emoji, attiva: true, valore: e, in: &p)
        case .formuleVietate:
            let nuove = ScritturaStileVera.elenco(valore)
            guard !nuove.isEmpty else { return false }
            var elenco = arg["aggiungi"] == "si" ? (p.formuleVietate?.valore ?? []) : []
            for f in nuove where !elenco.contains(where: { StileVera.normale($0) == StileVera.normale(f) }) { elenco.append(f) }
            ScritturaStileVera.metti(\.formuleVietate, attiva: true, valore: elenco, in: &p)
        case .aperture, .chiusure:
            let elenco = ScritturaStileVera.elenco(valore)
            guard !elenco.isEmpty else { return false }
            let kp: WritableKeyPath<ProfiloStile, RegolaStile<[String]>?> = k == .aperture ? \.aperture : \.chiusure
            ScritturaStileVera.metti(kp, attiva: true, valore: elenco, in: &p)
        case .cortesia:
            guard let a = Allocuzione(rawValue: arg["allocuzione"] ?? "") else { return false }
            if let id = arg["cliente"], !id.isEmpty {
                // L'eccezione per un cliente: cambia solo `perCliente`, la regola tiene origine e stato. Si riaccende
                // solo se la scheda lo diceva («riaccendi»); senza regola nasce scritta, del Lei agli altri (come dice
                // la scheda).
                if var r = p.cortesia {
                    r.valore.perCliente[id] = a
                    if arg["riaccendi"] == "si" { r.attiva = true }
                    p.cortesia = r
                } else {
                    p.cortesia = .scritta(CortesiaStile(predefinita: .lei, perCliente: [id: a]))
                }
                return true
            }
            var c = p.cortesia?.valore ?? CortesiaStile(predefinita: .lei)
            c.predefinita = a
            if let s = arg["soglia"] {
                c.sogliaEta = Int(s).flatMap { (14...110).contains($0) ? $0 : nil }
            }
            ScritturaStileVera.metti(\.cortesia, attiva: true, valore: c, in: &p)
        }
        return true
    }
}

// MARK: - Prova delle correzioni del collegamento (da chiamare dentro `Prisma --prova-vera`)

extension StatoShell {
    /// L'eccezione «tu o Lei» per un cliente non cambia la regola degli altri; la riscrittura di Qwen non perde cifre,
    /// date né il nome del cliente. Senza Qwen e senza disco.
    static func provaCollegamentoStileCorrezioni(_ controlla: (Bool, String) -> Void) {
        let giulia = "giulia-prova-stile"
        // Regola accesa e imparata: cambia solo l'eccezione, origine e stato restano
        var p = ProfiloStile()
        p.cortesia = .imparata(CortesiaStile(predefinita: .tu), da: 12)
        let ok = scriviRegolaStile(.cortesia, argomenti: ["regola": ChiaveRegolaStile.cortesia.rawValue, "allocuzione": Allocuzione.lei.rawValue,
                                                          "cliente": giulia], in: &p)
        controlla(ok && p.cortesia?.valore.perCliente[giulia] == .lei && p.cortesia?.valore.predefinita == .tu
                  && p.cortesia?.origine == .imparata && p.cortesia?.attiva == true,
                  "Stile nell'app: «dai del Lei a Giulia» cambia solo l'eccezione, la regola degli altri resta com'era")
        // Regola spenta: resta spenta se la scheda non diceva di riaccenderla
        var spenta = ProfiloStile()
        spenta.cortesia = RegolaStile(valore: CortesiaStile(predefinita: .lei), origine: .imparata, messaggi: 5, attiva: false)
        _ = scriviRegolaStile(.cortesia, argomenti: ["allocuzione": Allocuzione.tu.rawValue, "cliente": giulia], in: &spenta)
        controlla(spenta.cortesia?.attiva == false && spenta.cortesia?.valore.perCliente[giulia] == .tu,
                  "Stile nell'app: una regola «tu o Lei» spenta non si riaccende di nascosto")
        _ = scriviRegolaStile(.cortesia, argomenti: ["allocuzione": Allocuzione.tu.rawValue, "cliente": giulia, "riaccendi": "si"], in: &spenta)
        controlla(spenta.cortesia?.attiva == true && spenta.cortesia?.origine == .imparata,
                  "Stile nell'app: si riaccende solo quando la scheda lo dice")
        // La riscrittura: stesse cifre nei due sensi, stessi mesi e giorni, il nome del cliente
        let c = Cliente(id: giulia, nome: "Giulia Rossi", iniziali: "GR", tinta: .rosa, tema: "", email: "", telefono: "",
                        preferito: false, nota: "", creatoIl: Date(timeIntervalSinceReferenceDate: 800_000_000))
        let bozza = "Ciao Giulia, ci vediamo giovedì 5 novembre alle ore 16:00 in studio."
        controlla(fattiConservatiStile(bozza: bozza, riscritto: "Giulia, giovedì 5 novembre alle 16:00 ti aspetto in studio.", cliente: c),
                  "Stile nell'app: una riscrittura con gli stessi fatti vale")
        controlla(!fattiConservatiStile(bozza: bozza, riscritto: "Giulia, giovedì 5 novembre ti aspetto in studio.", cliente: c),
                  "Stile nell'app: una riscrittura che perde l'ora non vale")
        controlla(!fattiConservatiStile(bozza: bozza, riscritto: "Giulia, il 5 alle 16:00 ti aspetto in studio, giovedì.", cliente: c),
                  "Stile nell'app: una riscrittura che perde il mese non vale")
        controlla(!fattiConservatiStile(bozza: bozza, riscritto: "Ci vediamo giovedì 5 novembre alle 16:00 in studio.", cliente: c),
                  "Stile nell'app: una riscrittura che perde il nome del cliente non vale")
        controlla(fattiConservatiStile(bozza: bozza, riscritto: "Gentile Sig.ra Rossi, la aspetto giovedì 5 novembre alle 16:00 in studio.", cliente: c),
                  "Stile nell'app: il cognome al posto del nome va bene (il saluto cambia con il Lei)")
    }
}
