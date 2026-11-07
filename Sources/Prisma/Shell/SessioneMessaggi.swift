import SwiftUI

// La sessione dell'app Messaggi (Mac, iPad e iPhone): l'occasione scelta, il tono e il canale (uguali per tutte le
// occasioni, come nel template), i testi già scritti per (occasione, tono, canale) e le correzioni del consulente.
// Vive quanto la finestra di Messaggi (`@StateObject` della vista): chiusa la finestra, testi e correzioni non salvati
// si liberano (8 GB di RAM). Un solo compito di scrittura alla volta: cambiare occasione, tono o canale lo interrompe.
// Le versioni già scritte restano e non si riscrivono, se non con «↻ Riscrivi».
// Prisma non spedisce mai: la sessione prepara il testo, l'apertura in Mail o in Messaggi la chiede il consulente.

/// La chiave di un testo scritto: l'occasione, il tono e il canale (il canale cambia lunghezza e oggetto).
struct ChiaveTestoMessaggio: Hashable {
    let occasione: String
    let tono: TonoMessaggio
    let canale: CanaleMessaggio
}

@MainActor
final class SessioneMessaggi: ObservableObject {
    /// L'occasione nel pannello (nil: la prima dell'elenco).
    @Published var scelta: String?
    @Published var tono: TonoMessaggio = .cordiale
    @Published var canale: CanaleMessaggio = .mail
    /// I testi pronti (di Vera o di Prisma), per chiave.
    @Published private(set) var testi: [ChiaveTestoMessaggio: TestoScrittoMessaggio] = [:]
    /// Le correzioni del consulente al testo pronto.
    @Published private(set) var correzioni: [ChiaveTestoMessaggio: String] = [:]
    /// Il testo che Vera sta scrivendo adesso, e quello arrivato fin qui.
    @Published private(set) var inScrittura: ChiaveTestoMessaggio?
    @Published private(set) var parziale = ""
    /// I testi già comparsi per intero: da qui si possono correggere.
    @Published private(set) var comparsi: Set<ChiaveTestoMessaggio> = []
    /// Quante volte un testo è stato riscritto: fa ripartire la comparsa parola per parola.
    @Published private(set) var giri: [ChiaveTestoMessaggio: Int] = [:]
    /// Un messaggio del dossier riaperto (dalla scheda Note) la cui occasione il motore non propone più.
    @Published private(set) var dalDossier: OccasioneMessaggio?
    /// L'id nel dossier del messaggio salvato o aperto per ogni testo: salvare di nuovo aggiorna lo stesso.
    private var salvati: [ChiaveTestoMessaggio: String] = [:]
    private var compito: Task<Void, Never>?
    /// Qwen si verifica una volta per sessione (e di nuovo a ogni «Riscrivi»), poi vale la disponibilità nota.
    private var verificato = false

    func chiave(_ o: OccasioneMessaggio) -> ChiaveTestoMessaggio {
        ChiaveTestoMessaggio(occasione: o.id, tono: tono, canale: canale)
    }

    // MARK: - L'occasione scelta

    /// Le occasioni da mostrare: quelle dello stato, con in testa il messaggio riaperto dal dossier (se non c'è già).
    func elenco(_ base: OccasioniMessaggi) -> OccasioniMessaggi {
        guard let d = dalDossier, base.occasione(d.id) == nil else { return base }
        return OccasioniMessaggi(festeggiare: base.festeggiare, oggi: [d] + base.oggi, settimana: base.settimana)
    }

    /// L'occasione scelta, o la prima.
    func occasione(in elenco: OccasioniMessaggi) -> OccasioneMessaggio? {
        scelta.flatMap { elenco.occasione($0) } ?? elenco.tutte.first
    }

    /// La richiesta delle altre app (CollegamentiMessaggi.swift): un messaggio del dossier, un'occasione, un cliente.
    func applica(_ r: RichiestaMessaggi, elenco base: OccasioniMessaggi, stato: StatoShell) {
        if let mid = r.messaggioId, let m = stato.dati.messaggi.first(where: { $0.id == mid }) {
            riapri(m, elenco: base, stato: stato)
            return
        }
        if r.occasioneId == nil && r.clienteId == nil {
            // Dal pannello Novità: la prima occasione
            scelta = nil
        } else if let id = r.occasioneId, base.occasione(id) != nil {
            scelta = id
        } else if let c = r.clienteId, let prima = base.tutte.first(where: { $0.clienteId == c }) {
            scelta = prima.id
        } else if r.occasioneId != nil || r.clienteId != nil {
            // L'occasione non è (più) nell'elenco: resta la prima, e l'avviso lo dice
            scelta = nil
            stato.mostraAvviso(TestiMessaggi.occasioneNonPiu)
        }
    }

    /// Un messaggio salvato torna nel pannello con il suo tono, il suo canale e il suo testo.
    private func riapri(_ m: MessaggioCliente, elenco base: OccasioniMessaggi, stato: StatoShell) {
        let daOrigine = OccasioneMessaggio.id(tipo: m.origine.tipo, clienteId: m.clienteId, riferimento: m.origine.riferimento)
        let occasione: String
        if let o = base.occasione(m.occasioneId) ?? base.occasione(daOrigine) {
            occasione = o.id
        } else {
            let d = TestiMessaggi.occasioneDalDossier(m)
            dalDossier = d
            occasione = d.id
        }
        tono = m.tono
        canale = m.canale
        let k = ChiaveTestoMessaggio(occasione: occasione, tono: m.tono, canale: m.canale)
        testi[k] = TestoScrittoMessaggio(oggetto: m.oggetto, testo: m.testo, autore: m.autore, modello: m.modello, avviso: nil)
        correzioni[k] = nil
        comparsi.insert(k)
        salvati[k] = m.id
        scelta = occasione
    }

    // MARK: - Il testo

    /// Il testo da mostrare (con le correzioni), nil se non è ancora pronto.
    func testo(_ k: ChiaveTestoMessaggio) -> String? {
        correzioni[k] ?? testi[k]?.testo
    }

    /// Il testo pronto con le correzioni, come si salva e si apre.
    func scritto(_ k: ChiaveTestoMessaggio) -> TestoScrittoMessaggio? {
        guard var s = testi[k] else { return nil }
        if let c = correzioni[k] { s.testo = c }
        return s
    }

    func correggi(_ k: ChiaveTestoMessaggio, _ testo: String) {
        guard testi[k] != nil else { return }
        correzioni[k] = testo == testi[k]?.testo ? nil : testo
    }

    func comparso(_ k: ChiaveTestoMessaggio) {
        guard testi[k] != nil, inScrittura != k else { return }
        comparsi.insert(k)
    }

    /// Scrive il testo dell'occasione se non c'è già (né è in scrittura).
    func prepara(_ o: OccasioneMessaggio, stato: StatoShell) {
        let k = chiave(o)
        guard testi[k] == nil, inScrittura != k else { return }
        scrivi(o, chiave: k, stato: stato)
    }

    /// «↻ Riscrivi»: toglie testo e correzioni e scrive di nuovo (Qwen si verifica di nuovo; senza Qwen torna il
    /// testo di Prisma, uguale).
    func riscrivi(_ o: OccasioneMessaggio, stato: StatoShell) {
        let k = chiave(o)
        testi[k] = nil
        correzioni[k] = nil
        comparsi.remove(k)
        giri[k, default: 0] += 1
        verificato = false
        scrivi(o, chiave: k, stato: stato)
    }

    /// Interrompe la scrittura (la finestra si chiude): il testo a metà non resta.
    func ferma() {
        compito?.cancel()
        compito = nil
        inScrittura = nil
        parziale = ""
    }

    private func scrivi(_ o: OccasioneMessaggio, chiave k: ChiaveTestoMessaggio, stato: StatoShell) {
        compito?.cancel()
        inScrittura = k
        parziale = ""
        let tono = k.tono
        let canale = k.canale
        let verifica = !verificato && !stato.disponibilitaLocale.pronto
        verificato = true
        compito = Task { @MainActor [weak self] in
            if verifica {
                let d = await MotoreLocale.verificaDispositivo(stato.dati.impostazioni.vera)
                if stato.disponibilitaLocale != d { stato.disponibilitaLocale = d }
            }
            guard !Task.isCancelled else { return }
            let r = await stato.scriviMessaggio(o, tono: tono, canale: canale) { testo in
                Task { @MainActor [weak self] in
                    guard let self, self.inScrittura == k else { return }
                    self.parziale = testo
                }
            }
            guard let self, !Task.isCancelled else { return }
            if let r { self.testi[k] = r }
            // Il testo arrivato in flusso è già comparso parola per parola: diventa subito correggibile (la comparsa
            // non riparte da capo). Il testo di Prisma arrivato tutto insieme compare prima parola per parola.
            if r != nil, self.inScrittura == k, !self.parziale.isEmpty { self.comparsi.insert(k) }
            if self.inScrittura == k {
                self.inScrittura = nil
                self.parziale = ""
                self.compito = nil
            }
        }
    }

    /// Un testo già pronto (le istantanee, nello stato finale).
    func imposta(_ s: TestoScrittoMessaggio, per k: ChiaveTestoMessaggio) {
        testi[k] = s
        comparsi.insert(k)
    }

    // MARK: - Nel dossier

    func idSalvato(_ k: ChiaveTestoMessaggio) -> String? { salvati[k] }

    func ricordaSalvato(_ k: ChiaveTestoMessaggio, id: String?) {
        guard let id else { return }
        salvati[k] = id
    }
}

// MARK: - Testi

/// I testi dell'app Messaggi (Design/template-novita-specifica.md §5.1 e §5.1.6).
enum TestiMessaggi {
    static let notaColonna = "Vera scrive, tu spedisci: niente parte da solo. Ogni messaggio resta nel dossier del cliente."
    static let nienteOggi = "Niente da mandare oggi"
    static let vuoto = "Nessun messaggio da preparare. Quando c'è un incontro, una scadenza, un compleanno o un consenso da "
        + "rinnovare, lo trovi qui."
    static let veraScrive = "Vera scrive con i dati del dossier"
    static let veraStaScrivendo = "Vera sta scrivendo con i dati del dossier"
    static let testoPrisma = "Testo di Prisma, con i dati del dossier"
    static let cifreDaPrisma = "Le cifre vengono da Prisma"
    static let spedisciTu = "Lo controlli e lo spedisci tu"
    static let salva = "Salva nel dossier"
    static let riscrivi = "↻ Riscrivi"
    static let aggiungiNelDossier = "Aggiungi nel dossier"
    static let senzaConsenso = "Senza consenso commerciale"
    static let occasioneNonPiu = "Quell'occasione non è più tra quelle da mandare: ecco le altre"
    static let occasioni = "Occasioni"
    /// Sui clienti di prova: le cifre sono dei motori, i testi dei modelli e le soglie sono da confermare.
    static let datiDiProva = "Dati di prova: testi dei modelli e soglie da confermare"
    static let confermaConsensoTitolo = "Manca il consenso commerciale"
    static let confermaConsensoApri = "Apri lo stesso"
    static let confermaConsensoNo = "Non ora"

    /// «Perché adesso: Scadenza tra 45 giorni».
    static func perche(_ o: OccasioneMessaggio) -> String { "Perché adesso: \(o.perche)" }

    /// «A: Giulia Rossi · giulia.rossi@example.com» o «A: Giulia Rossi · manca l'indirizzo email nel dossier».
    static func destinatario(_ c: Cliente, canale: CanaleMessaggio) -> (testo: String, manca: Bool) {
        if let r = AperturaMessaggi.recapito(c, canale: canale) {
            return ("A: \(c.nome) · \(canale == .mail ? r : c.telefono.trimmingCharacters(in: .whitespacesAndNewlines))", false)
        }
        return ("A: \(c.nome) · " + (canale == .mail ? "manca l'indirizzo email nel dossier" : "manca il numero nel dossier"), true)
    }

    /// «Apri in Mail» / «Apri in Messaggi».
    static func apri(_ canale: CanaleMessaggio) -> String { "Apri in \(canale.nome)" }

    /// «✓ Preparato alle 10:42».
    static func preparato(_ d: Date) -> String { "✓ Preparato alle \(Formati.ora.string(from: d))" }

    /// «Salvato nel dossier di Giulia Rossi».
    static func salvato(_ nome: String) -> String { "Salvato nel dossier di \(nome)" }

    /// Chi ha scritto il testo, accanto alla nota sulle cifre.
    static func autore(_ s: TestoScrittoMessaggio) -> String {
        switch s.autore {
        case .vera: return "Scritto da Vera" + (s.modello.map { " con \($0)" } ?? "")
        case .modelloFisso: return "Testo di Prisma"
        }
    }

    static func confermaConsenso(_ nome: String) -> String {
        "Questo messaggio propone un incontro o un prodotto e \(nome) non ha un consenso commerciale valido. "
            + "Controlla «In regola» nel dossier prima di spedirlo."
    }

    /// L'occasione di un messaggio salvato che il motore non propone più (riaperto dal dossier): le cifre sono quelle
    /// salvate con il messaggio.
    static func occasioneDalDossier(_ m: MessaggioCliente) -> OccasioneMessaggio {
        var o = OccasioneMessaggio(origine: m.origine, clienteId: m.clienteId, canale: m.canaleLavoro, gruppo: .oggi,
                                   titolo: m.oggetto ?? m.origine.tipo.nome,
                                   perche: "\(m.stato.nome) " + ModelliMessaggi.il(Formati.dataEstesa.string(from: m.dataMostrata)),
                                   oggetto: m.oggetto ?? m.origine.tipo.nome, cifre: m.cifre, priorita: .media,
                                   data: m.dataMostrata)
        o.preparatoIl = m.dataMostrata
        return o
    }
}

extension StatoShell {
    /// Il consenso commerciale del cliente vale oggi (In regola, MotoreConformita). Se il consulente non lo segue
    /// (impostazioni) non si segnala niente.
    func consensoCommercialeValido(_ c: Cliente, oggi: Date = Date()) -> Bool {
        let esito = MotoreConformita.calcola(cliente: c, posizioni: [], regole: dati.impostazioni.conformita, oggi: oggi)
        guard let v = esito.voci.first(where: { $0.tipo == .commerciale }) else { return true }
        switch v.stato {
        case .inRegola, .entro30, .entro60: return true
        case .nonRichiesta: return v.motivo != .consensoNonDato
        case .scaduta, .mancante: return false
        }
    }

    /// Apre il dossier del cliente sull'anagrafica (per aggiungere email o telefono).
    func apriAnagraficaMessaggio(_ clienteId: String) {
        clienteAttivoId = clienteId
        schedaCliente = .anagrafica
        apri(.clienti)
    }
}
