#if os(macOS)
import AppKit
#endif
import Foundation
import UniformTypeIdentifiers

// «Vera su misura» nell'app (Vera/BRIEF.md, fase 5, funzione 22; logica in Vera/SuMisuraVera.swift). La pagina sopra la
// chat di Vera con le quattro tappe (raccolgo gli esempi, addestro, l'esame, installo), l'anteprima degli esempi resi
// anonimi, l'esportazione del pacchetto (dove sceglie l'utente: Prisma non invia niente), l'importazione del modello
// addestrato in Ollama (127.0.0.1), l'esame e la sostituzione solo con l'esame superato, il ritorno alla Vera di prima e
// l'eliminazione dei modelli scartati. Regola 2 del brief: esportare, usare, tornare indietro ed eliminare passano da una
// conferma nella pagina; nessuna di queste azioni parte da una frase in chat. Su misura funziona solo con Ollama, mai in
// modalità cliente, e si fa da Prisma sul Mac.

/// A che punto è «Vera su misura» (lo stato della pagina).
enum FaseSuMisura: Equatable {
    /// Il fornitore è «Compatibile OpenAI»: su misura funziona solo con Ollama.
    case soloOllama
    /// La memoria cifrata non si apre (ripristino su un altro Mac): gli esempi non si leggono.
    case memoriaBloccata
    /// Importazione o esame in corso: cosa sta facendo.
    case lavoro(String)
    case nessunEsempio
    /// Esempi pronti per l'addestramento e quanti ne mancano al minimo.
    case pochiEsempi(pronti: Int, mancano: Int)
    case pronti(Int)
    /// Pacchetto esportato, in attesa del modello addestrato.
    case inAttesaModello(Date)
    case daEsaminare(VersioneSuMisura)
    case superata(VersioneSuMisura)
    case nonSuperata(VersioneSuMisura)
    case inUso(VersioneSuMisura)
    /// Era in uso, sei tornato alla Vera di prima: la versione resta e si può riprovare.
    case ritirata(VersioneSuMisura)

    /// Il numero della tappa accesa (1-4); le precedenti sono fatte.
    var tappa: Int {
        switch self {
        case .soloOllama, .memoriaBloccata, .nessunEsempio, .pochiEsempi, .pronti: return 1
        case .inAttesaModello: return 2
        case .lavoro(let t): return t.contains("domanda") || t.contains("Carico") ? 3 : 2
        case .daEsaminare, .nonSuperata: return 3
        case .superata, .inUso, .ritirata: return 4
        }
    }
}

/// Una riga dell'anteprima: l'esempio reso anonimo, se è escluso e perché non entra (se non entra).
struct VoceAnteprimaSuMisura: Identifiable, Equatable {
    var esempio: EsempioAnonimo
    var escluso: Bool
    /// nil = entra nel pacchetto.
    var motivo: String?

    var id: String { esempio.id }
    var entra: Bool { !escluso && motivo == nil }
}

extension StatoShell {
    static let titoloSuMisura = "Vera su misura"

    // MARK: - La pagina

    func apriPaginaSuMisura() {
        guard !inModoCliente else {
            return mostraAvviso("Vera su misura legge le conversazioni di tutti i clienti: fuori dalla modalità cliente.")
        }
        memoriaVera.carica()
        paginaTagliandoAperta = false
        paginaMotoriAperta = false
        if !aperta(.vera) { apri(.vera) }
        paginaSuMisuraAperta = true
    }

    func chiudiPaginaSuMisura() {
        paginaSuMisuraAperta = false
        anteprimaSuMisuraAperta = false
    }

    /// Lo stato di adesso.
    var faseSuMisura: FaseSuMisura {
        let vera = dati.impostazioni.vera
        guard vera.fornitore == .ollama else { return .soloOllama }
        if let l = lavoroSuMisura { return .lavoro(l) }
        let s = vera.suMisura
        if let v = s.inUso { return .inUso(v) }
        if let v = s.versioni.last(where: { $0.stato != .eliminata }) {
            switch v.stato {
            case .importata: return .daEsaminare(v)
            case .superata: return .superata(v)
            case .nonSuperata where (s.ultimoPacchetto ?? .distantPast) <= v.creataIl: return .nonSuperata(v)
            case .ritirata where (s.ultimoPacchetto ?? .distantPast) <= v.creataIl: return .ritirata(v)
            default: break
            }
        }
        if let p = s.ultimoPacchetto, s.versioni.allSatisfy({ $0.creataIl < p }) { return .inAttesaModello(p) }
        if memoriaVera.bloccata { return .memoriaBloccata }
        let pronti = divisioneSuMisura().addestramento.count
        if SuMisuraVera.candidati(memoriaVera.esempi).isEmpty { return .nessunEsempio }
        if pronti < SuMisuraVera.minimoEsempi { return .pochiEsempi(pronti: pronti, mancano: SuMisuraVera.minimoEsempi - pronti) }
        return .pronti(pronti)
    }

    /// «Impara dalle correzioni» o la memoria spenti: niente esempi nuovi (quelli che ci sono restano).
    var esempiSuMisuraFermi: Bool {
        !dati.impostazioni.vera.imparaDalleCorrezioni || !dati.impostazioni.vera.memoriaAttiva
    }

    /// Lo stato in una riga, per la chat e per Impostazioni › Vera.
    var statoSuMisuraInBreve: String {
        switch faseSuMisura {
        case .soloOllama: return "Vera su misura funziona solo con Ollama: in Impostazioni › Vera il fornitore è «Compatibile OpenAI»."
        case .memoriaBloccata: return "La memoria di Vera è bloccata: aprila con la password dei backup per leggere gli esempi."
        case .lavoro(let l): return "Vera su misura: \(l)"
        case .nessunEsempio: return "Nessun esempio approvato: segna con 👍 le risposte che ti piacciono e diventano esempi."
        case .pochiEsempi(let p, let m): return "Vera su misura: \(p) esempi pronti, ne mancano \(m) per il primo addestramento."
        case .pronti(let n): return "Vera su misura: \(n) esempi pronti. Guarda l'anteprima e prepara il pacchetto."
        case .inAttesaModello(let d): return "Pacchetto preparato il \(Formati.dataLunga.string(from: d)): in attesa del modello addestrato."
        case .daEsaminare: return "Il modello addestrato è in Ollama: manca l'esame."
        case .superata(let v): return "Esame superato (\(v.esame?.percentualeAttuale ?? 0)% → \(v.esame?.percentualeNuova ?? 0)%): puoi usare la Vera su misura."
        case .nonSuperata(let v): return "Esame non superato (\(v.esame?.percentualeAttuale ?? 0)% → \(v.esame?.percentualeNuova ?? 0)%): resta la Vera di oggi."
        case .inUso(let v): return "In uso: \(SuMisuraVera.nomeVersione(v)). Puoi sempre tornare alla Vera di prima."
        case .ritirata: return "Sei tornato alla Vera di prima: la versione su misura resta e si può riprovare."
        }
    }

    /// La pillola di Impostazioni › Vera.
    var pillolaSuMisura: String {
        switch faseSuMisura {
        case .soloOllama: return "Solo con Ollama"
        case .memoriaBloccata: return "Memoria bloccata"
        case .lavoro: return "In corso"
        case .nessunEsempio, .pochiEsempi: return "Raccolgo esempi"
        case .pronti: return "Pronta da preparare"
        case .inAttesaModello: return "In attesa del modello"
        case .daEsaminare: return "Da esaminare"
        case .superata: return "Esame superato"
        case .nonSuperata: return "Esame non superato"
        case .inUso: return "In uso"
        case .ritirata: return "Vera di prima"
        }
    }

    // MARK: - Esempi e anteprima

    var identificativiSuMisura: IdentificativiClienti {
        IdentificativiClienti(clienti: dati.clienti, consulente: dati.impostazioni.nomeUtente)
    }

    /// La divisione di adesso tra addestramento ed esame.
    func divisioneSuMisura() -> (addestramento: [EsempioVera], esame: [EsempioVera]) {
        let s = dati.impostazioni.vera.suMisura
        return SuMisuraVera.dividi(memoriaVera.esempi, esameGia: s.esame, usati: s.usati)
    }

    /// L'anteprima: tutti gli esempi approvati fuori dall'esame, resi anonimi, con quelli esclusi e il motivo di chi non entra.
    func anteprimaSuMisura() -> [VoceAnteprimaSuMisura] {
        let id = identificativiSuMisura
        let d = divisioneSuMisura()
        let esame = Set(d.esame.map(\.id))
        let usati = Set(dati.impostazioni.vera.suMisura.usati)
        return memoriaVera.esempi.filter { !esame.contains($0.id) }.reversed().map { e in
            let a = AnonimizzatoreVera.anonimizza(e, identificativi: id)
            var motivo: String?
            if !a.pulito {
                motivo = "Resta qualcosa che fa riconoscere un cliente: non entra."
            } else if !SuMisuraVera.addestrabile(e) {
                motivo = "Ha cifre che non vengono dalla domanda: non entra (Vera imparerebbe a scrivere numeri senza fonte)."
            } else if usati.contains(e.id) {
                motivo = "Già in un pacchetto di prima."
            }
            return VoceAnteprimaSuMisura(esempio: a, escluso: e.escluso, motivo: motivo)
        }
    }

    func escludiEsempioSuMisura(_ id: String, _ escluso: Bool) {
        guard !inModoCliente else { return }
        memoriaVera.escludiEsempio(id, escluso)
    }

    /// Gli esempi che entrano nel prossimo pacchetto (anonimi e puliti, mai già usati).
    func esempiPerPacchettoSuMisura() -> [EsempioAnonimo] {
        let id = identificativiSuMisura
        let usati = Set(dati.impostazioni.vera.suMisura.usati)
        return divisioneSuMisura().addestramento.filter { !usati.contains($0.id) }
            .map { AnonimizzatoreVera.anonimizza($0, identificativi: id) }.filter(\.pulito)
    }

    /// Le lezioni attive, rese anonime (quelle con residui restano fuori).
    func lezioniPerPacchettoSuMisura() -> [String] {
        let id = identificativiSuMisura
        return memoriaVera.lezioni.filter(\.attiva).compactMap { l in
            let t = AnonimizzatoreVera.anonimizza(l.testo, identificativi: id).testo
            return AnonimizzatoreVera.residui(t, identificativi: id).isEmpty ? t : nil
        }
    }

    // MARK: - Il pacchetto

    /// Scrive il pacchetto nello zip scelto dall'utente e ricorda quali esempi sono usciti (mai più nell'esame) e quali
    /// restano per l'esame (mai nel pacchetto). Nessuna richiesta di rete.
    @discardableResult
    func esportaPacchettoSuMisura(a zip: URL, oggi: Date = Date()) throws -> ManifestoSuMisura {
        guard !inModoCliente, !solaLettura, dati.impostazioni.vera.fornitore == .ollama else {
            throw ErroreVera(messaggio: "Il pacchetto si prepara da Prisma sul Mac, con Ollama e fuori dalla modalità cliente.")
        }
        let esempi = esempiPerPacchettoSuMisura()
        guard esempi.count >= SuMisuraVera.minimoEsempi else {
            throw ErroreVera(messaggio: "Servono almeno \(SuMisuraVera.minimoEsempi) esempi pronti: ne mancano \(SuMisuraVera.minimoEsempi - esempi.count).")
        }
        let fm = FileManager.default
        let cartella = fm.temporaryDirectory.appendingPathComponent("Prisma-pacchetto-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: cartella) }
        let dentro = cartella.appendingPathComponent("vera-su-misura")
        let m = try PacchettoSuMisura.scrivi(esempi, lezioni: lezioniPerPacchettoSuMisura(), in: dentro, oggi: oggi,
                                             modelloDiPartenza: modelloDiPartenzaSuMisura)
        try PacchettoSuMisura.zippa(dentro, a: zip)
        let esame = divisioneSuMisura().esame.map(\.id)
        var vera = dati.impostazioni.vera
        vera.suMisura.esame = esame
        vera.suMisura.usati = Array((vera.suMisura.usati + esempi.map(\.id)).suffix(MemoriaVera.massimoEsempi))
        vera.suMisura.ultimoPacchetto = oggi
        vera.suMisura.esempiNelPacchetto = m.esempi
        dati.impostazioni.vera = vera
        return m
    }

    /// Il modello da cui parte l'addestramento: quello di oggi, o quello di prima se oggi è in uso una Vera su misura.
    var modelloDiPartenzaSuMisura: String {
        let vera = dati.impostazioni.vera
        guard SuMisuraVera.eSuMisura(vera.modelloLocale) else { return vera.modelloLocale }
        return vera.suMisura.modelloPrecedente ?? MotoreLocale.modelloPredefinito
    }

    #if os(macOS)
    /// «Esporta questi N esempi», dopo la conferma: lo zip va dove scegli tu.
    func scegliDoveEsportareSuMisura() {
        let p = NSSavePanel()
        p.nameFieldStringValue = SuMisuraVera.nomeModello(Date()).replacingOccurrences(of: ":", with: "-") + ".zip"
        p.allowedContentTypes = [.zip]
        p.canCreateDirectories = true
        p.message = "Il pacchetto contiene solo esempi resi anonimi che hai approvato. Prisma non lo invia: lo porti tu all'addestramento."
        guard p.runModal() == .OK, let url = p.url else { return }
        do {
            let m = try esportaPacchettoSuMisura(a: url)
            mostraAvviso("Pacchetto pronto: \(m.esempi) esempi anonimi")
        } catch {
            mostraAvviso(error.localizedDescription)
        }
    }

    /// «Importa il modello addestrato»: lo zip scaricato dall'addestramento, il file .gguf o la sua cartella.
    func scegliModelloDaImportare() {
        let p = NSOpenPanel()
        var tipi: [UTType] = [.zip, .folder]
        if let gguf = UTType(filenameExtension: "gguf") { tipi.append(gguf) }
        p.allowedContentTypes = tipi
        p.canChooseDirectories = true
        p.allowsMultipleSelection = false
        p.prompt = "Importa"
        p.message = "Lo zip scaricato dall'addestramento (con il file .gguf e rapporto.json). Entra solo in Ollama sul Mac."
        guard p.runModal() == .OK, let url = p.url else { return }
        importaSuMisura(da: url)
    }
    #endif

    // MARK: - Importazione ed esame

    /// Il fornitore Ollama delle impostazioni (solo indirizzi locali).
    var ollamaSuMisura: FornitoreOllama {
        let v = dati.impostazioni.vera
        return FornitoreOllama(indirizzo: v.indirizzoLocale, modello: v.modelloLocale, sessione: .shared)
    }

    /// Un nome libero per la versione di oggi («vera-su-misura:2026-11-08», poi «…-2»).
    func nomeNuovaVersioneSuMisura(_ oggi: Date = Date()) -> String {
        let base = SuMisuraVera.nomeModello(oggi)
        let presi = Set(dati.impostazioni.vera.suMisura.versioni.filter { $0.stato != .eliminata }.map(\.id))
        guard presi.contains(base) else { return base }
        var n = 2
        while presi.contains("\(base)-\(n)") { n += 1 }
        return "\(base)-\(n)"
    }

    /// Copia il modello addestrato in Ollama (127.0.0.1) e lo mette in attesa dell'esame.
    func importaSuMisura(da url: URL) {
        guard lavoroSuMisura == nil, !inModoCliente, dati.impostazioni.vera.fornitore == .ollama else { return }
        let nome = nomeNuovaVersioneSuMisura()
        let partenza = modelloDiPartenzaSuMisura
        let fornitore = ollamaSuMisura
        let esempi = dati.impostazioni.vera.suMisura.esempiNelPacchetto
        lavoroSuMisura = "Controllo il file…"
        compitoSuMisura = Task { @MainActor in
            let fm = FileManager.default
            var temporanea: URL?
            do {
                let trovato = try ImportaSuMisura.trova(in: url)
                if trovato.gguf.path.hasPrefix(fm.temporaryDirectory.path), !url.path.hasPrefix(fm.temporaryDirectory.path) {
                    temporanea = trovato.gguf.deletingLastPathComponent()
                }
                let curva = trovato.rapporto.flatMap { try? Data(contentsOf: $0) }.flatMap { SuMisuraVera.curva(daRapporto: $0) }
                try await ImportaSuMisura.importa(gguf: trovato.gguf, nome: nome, partenza: partenza, fornitore: fornitore) { t in
                    DispatchQueue.main.async { if self.lavoroSuMisura != nil { self.lavoroSuMisura = t } }
                }
                var v = VersioneSuMisura(id: nome, creataIl: Date(), modelloDiPartenza: partenza, esempi: esempi, stato: .importata)
                v.curva = curva
                var vera = self.dati.impostazioni.vera
                SuMisuraVera.aggiungi(v, in: &vera)
                self.dati.impostazioni.vera = vera
                self.mostraAvviso("La Vera su misura è in Ollama: manca l'esame")
            } catch {
                self.mostraAvviso(error.localizedDescription)
            }
            if let t = temporanea { try? fm.removeItem(at: Self.radiceTemporanea(t)) }
            self.lavoroSuMisura = nil
            self.compitoSuMisura = nil
        }
    }

    /// La cartella temporanea in cui è stato aperto lo zip (Prisma-su-misura-…), per cancellarla tutta.
    static func radiceTemporanea(_ url: URL) -> URL {
        var u = url
        while u.pathComponents.count > 1, !u.lastPathComponent.hasPrefix("Prisma-su-misura-") { u = u.deletingLastPathComponent() }
        return u.lastPathComponent.hasPrefix("Prisma-su-misura-") ? u : url
    }

    /// Le domande dell'esame: gli esempi tenuti da parte, resi anonimi come quelli dell'addestramento.
    func domandeEsameSuMisura() -> [DomandaEsame] {
        let id = identificativiSuMisura
        return EsameSuMisura.domande(divisioneSuMisura().esame.map { AnonimizzatoreVera.anonimizza($0, identificativi: id) }.filter(\.pulito))
    }

    /// L'esame: la Vera di oggi e quella nuova sulle stesse domande, un modello alla volta. Intanto la chat aspetta.
    func esaminaSuMisura(_ id: String, domande scelte: [DomandaEsame]? = nil, sessione: URLSession = .shared) {
        guard lavoroSuMisura == nil, !inModoCliente, !veraInCorso, dati.impostazioni.vera.fornitore == .ollama,
              dati.impostazioni.vera.suMisura.versioni.contains(where: { $0.id == id && $0.stato != .eliminata && $0.stato != .inUso }) else { return }
        let domande = scelte ?? domandeEsameSuMisura()
        guard domande.count >= SuMisuraVera.minimoEsame else {
            return mostraAvviso("Per l'esame servono almeno \(SuMisuraVera.minimoEsame) domande tenute da parte.")
        }
        let attuale = modelloDiPartenzaSuMisura
        let vera = dati.impostazioni.vera
        lavoroSuMisura = "Carico la Vera di oggi…"
        esameSuMisuraInCorso = true
        compitoSuMisura = Task { @MainActor in
            let esito = await EsameSuMisura.esegui(domande, attuale: attuale, nuovo: id, vera: vera, sessione: sessione) { t in
                DispatchQueue.main.async { if self.esameSuMisuraInCorso { self.lavoroSuMisura = t } }
            }
            self.esitoEsameSuMisura = esito
            var v = self.dati.impostazioni.vera
            SuMisuraVera.registraEsame(esito.breve, per: id, in: &v)
            self.dati.impostazioni.vera = v
            self.esameSuMisuraInCorso = false
            self.lavoroSuMisura = nil
            self.compitoSuMisura = nil
            self.mostraAvviso(esito.superato ? "Esame superato: puoi usare la Vera su misura" : "Esame non superato: resta la Vera di oggi")
            // Il modello di oggi torna pronto per la chat
            self.verificaMotoreLocale()
        }
    }

    /// Ferma l'importazione o l'esame in corso.
    func fermaSuMisura() {
        compitoSuMisura?.cancel()
    }

    // MARK: - Sostituzione, ritorno, eliminazione (dopo la conferma nella pagina)

    /// «Usa la Vera su misura»: solo con l'esame superato.
    @discardableResult
    func installaSuMisura(_ id: String) -> Bool {
        guard !inModoCliente, !solaLettura, lavoroSuMisura == nil else { return false }
        var vera = dati.impostazioni.vera
        guard SuMisuraVera.sostituisci(id, in: &vera) else { return false }
        dati.impostazioni.vera = vera
        verificaMotoreLocale()
        mostraAvviso("La Vera su misura è in uso")
        return true
    }

    /// «Torna alla Vera di prima»: la versione su misura resta in Ollama e si può riprovare.
    @discardableResult
    func tornaAllaVeraDiPrima() -> Bool {
        guard !inModoCliente, !solaLettura, lavoroSuMisura == nil else { return false }
        var vera = dati.impostazioni.vera
        guard SuMisuraVera.tornaIndietro(in: &vera) else { return false }
        dati.impostazioni.vera = vera
        verificaMotoreLocale()
        mostraAvviso("Sei tornato alla Vera di prima")
        return true
    }

    /// «Elimina il modello»: libera circa 3 GB in Ollama. Mai la versione in uso.
    func eliminaSuMisura(_ id: String) {
        guard !inModoCliente, !solaLettura, lavoroSuMisura == nil,
              dati.impostazioni.vera.suMisura.versioni.contains(where: { $0.id == id && $0.stato != .inUso }) else { return }
        let fornitore = ollamaSuMisura
        Task { @MainActor in
            let fatto = await ImportaSuMisura.elimina(id, fornitore: fornitore)
            var vera = self.dati.impostazioni.vera
            if fatto || !self.persistente { SuMisuraVera.segnaEliminata(id, in: &vera) }
            self.dati.impostazioni.vera = vera
            self.mostraAvviso(fatto ? "Modello eliminato: spazio liberato" : "Ollama non ha eliminato il modello: riprova con Ollama aperto")
        }
    }

    /// Dopo un ripristino su un altro Mac la versione in uso può non essere in Ollama: la pagina lo dice.
    var suMisuraMancaInOllama: Bool {
        guard case .inUso = faseSuMisura else { return false }
        return !disponibilitaLocale.pronto && (disponibilitaLocale.motivo ?? "").contains("manca il modello")
    }

    // MARK: - Le frasi in chat

    /// «Vera, …» in testa la toglie già `InterpreteComandi.pulisci`: «Vera su misura» arriva come «su misura».
    static let frasiSuMisura = #"^(?:apri |mostra(?:mi)? )?(?:(?:la )?vera )?su misura$|^(?:(?:ri)?addestra|allena) vera\b|\bprepara(?:mi)? il pacchetto(?: di addestramento)?\b|\bcom'e andato l'esame\b|\btorna alla vera di prima\b"#

    /// «Vera su misura», «addestra Vera», «prepara il pacchetto di addestramento», «com'è andato l'esame?», «torna alla
    /// Vera di prima»: apre la pagina (sul Mac) e risponde con lo stato in una riga. Nessuna azione da sola.
    func chiediSuMisura(_ testo: String, chiave: String) -> Bool {
        let t = NucleoVera.semplice(InterpreteComandi.pulisci(testo))
        guard DateItaliane.cerca(Self.frasiSuMisura, t) != nil else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        let risposta: String
        if inModoCliente {
            risposta = "In modalità cliente la pagina di Vera su misura non si apre: legge le conversazioni di tutti i clienti."
        } else {
            #if os(macOS)
            apriPaginaSuMisura()
            risposta = statoSuMisuraInBreve + (t.contains("torna alla vera di prima") ? " Per tornare indietro usa il pulsante nella pagina." : "")
            #else
            risposta = "Vera su misura si fa da Prisma sul Mac."
            #endif
        }
        aggiungiMessaggio(MessaggioVera(autore: .vera, testo: risposta, titolo: Self.titoloSuMisura, motore: MotoriVera.sintesi.nome), cliente: chiave)
        return true
    }

    /// Il messaggio della chat mentre l'esame usa il modello (un modello alla volta sul Mac da 8 GB).
    func esameSuMisuraInPausa(cliente id: String) {
        aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "Sto facendo l'esame della Vera su misura: rispondo appena finisce.",
                                       titolo: Self.titoloSuMisura, motore: "Prisma"), cliente: id)
    }
}
