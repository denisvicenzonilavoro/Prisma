import AVFoundation
import Observation
import Combine
import Foundation
import Speech
import SwiftUI

// Lo stato a schermo del copilota dell'incontro (Orizzonte, giro 5; Design/template-novita-specifica.md §8): la fase
// dell'ascolto, la riga che si sta riconoscendo, i livelli del microfono per l'onda, il verbale aperto e, sull'iPad, le
// schede ancora da mandare al Mac. Non si salva: le sessioni con pezzi e schede stanno in `DatiPrisma.sessioniCopilota`
// (Shell/StatoCopilota.swift), dove entrano solo passando dalla guardia del consenso.
//
// L'ascolto usa AscoltoVera e TrascrizioneVera, solo sul dispositivo (`requiresOnDeviceRecognition` e i riconoscimenti di
// macOS 26): AscoltoVera sente una frase alla volta, quindi qui riparte da solo dopo ogni frase finché il consulente non
// preme «Termina». L'audio non si salva e non lascia mai il dispositivo; sul ponte cifrato verso il Mac viaggia solo il
// testo. Si ferma da solo con il blocco di Prisma (anche il Mac a riposo) e quando la schermata scompare.

/// Il passo «Ascolto» di Incontri: il copilota o le tre domande scritte con gli appunti.
enum ModoAscoltoIncontro: Hashable {
    case copilota, appunti
}

/// I testi fissi del copilota (le cifre vengono dalla sessione).
enum TestiCopilota {
    #if os(iOS)
    static let dispositivo = "sull’iPad"
    static let nomeDispositivo = "iPad"
    #else
    static let dispositivo = "sul Mac"
    static let nomeDispositivo = "Mac"
    #endif

    static let titolo = "Il copilota dell’incontro"
    static let pronto = "Pronto ad ascoltare"
    static let prepara = "Mi preparo ad ascoltare…"
    static let indicatore = "sul dispositivo · l’audio non lascia " + (nomeDispositivo == "Mac" ? "il Mac" : "l’iPad")
    static let occhielloTrascrizione = "Quello che vi state dicendo"
    static let notaTrascrizione = "Solo testo, riconosciuto " + dispositivo + ": alla fine resta il verbale, la trascrizione solo se la conservi."
    static let vuotoTrascrizione = "Avvia il copilota: le parole compaiono qui, solo come testo."
    static let ascoltoSenzaParole = "Parla pure: le parole compaiono qui."
    static let vuotoSchede = "Le schede compaiono qui, mentre Prisma capisce."
    static let veraNonPronta = "Vera non è pronta: Prisma riconosce con le sue regole."
    static let comeFunziona = "Mentre parlate, Prisma riconosce obiettivi, polizze, timori ed eventi. Alla fine conferma tu cosa entra nel dossier."
    static let nessunIncontro = "Nessun incontro in agenda oggi."
    static let senzaAppuntamento = "Ascolta un incontro senza appuntamento"
    /// Segnaposto «dati di prova» finché l'utente non dà il testo vero del consenso (§8.6, dato 67).
    static let testoConsenso = "Il cliente acconsente all’ascolto dell’incontro: Prisma trascrive la voce " + dispositivo
        + " solo come testo, l’audio non si registra e non lascia il dispositivo. (Testo di prova: va sostituito con quello approvato.)"
    static let alleanza = "Verifica le regole di Alleanza sull’ascolto."
    static let sulMac = "Da confermare sul Mac"
    static let nienteNelDossier = "Niente da aggiungere."
    static let nienteRiconosciuto = "Prisma non ha riconosciuto obiettivi, polizze, timori o eventi."
    static let nessunaAttivita = "Nessuna attività."
    static let firmaVera = "Scritto da Vera con Qwen, con le cifre delle schede"
    static let firmaPrisma = "Composto da Prisma dalle schede"
    static let conservaTrascrizione = "Conserva la trascrizione"

    static func primoNome(_ nome: String) -> String {
        nome.split(separator: " ").first.map(String.init) ?? nome
    }

    /// «00:09», «10:00», «1:05:12»: minuti e secondi fino a 59:59, poi le ore.
    static func contatore(_ secondi: Int) -> String {
        let s = max(0, secondi)
        if s >= 3600 { return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60) }
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    /// «meno di un minuto», «1 minuto», «18 minuti», «1 ora», «1 ora e 15 minuti», «2 ore e 5 minuti».
    static func durata(_ secondi: Int) -> String {
        let minuti = max(0, secondi) / 60
        guard minuti > 0 else { return "meno di un minuto" }
        let ore = minuti / 60, resto = minuti % 60
        let m = resto == 1 ? "1 minuto" : "\(resto) minuti"
        guard ore > 0 else { return m }
        let o = ore == 1 ? "1 ora" : "\(ore) ore"
        return resto == 0 ? o : "\(o) e \(m)"
    }

    static func ascolto(_ secondi: Int) -> String { "Ascolto · \(contatore(secondi)) · solo \(dispositivo)" }
    static func concluso(_ secondi: Int) -> String { "Incontro concluso · \(durata(secondi))" }
    static func interrotto(_ secondi: Int) -> String { "Ascolto interrotto · \(durata(secondi))" }
    static func daConfermare(_ schede: Int) -> String {
        "Incontro da confermare · " + (schede == 1 ? "1 scheda" : "\(schede) schede")
    }

    static func consensoDato(_ nome: String, _ c: ConsensoCopilota) -> String {
        "\(primoNome(nome)) ha dato il consenso il \(Formati.dataBreve.string(from: c.data)) (\(c.modo.nome.lowercased())). "
            + "Il riconoscimento della voce avviene \(dispositivo): l’audio non esce mai."
    }

    static func consensoMancante(_ nome: String) -> String {
        "Prima di ascoltare, chiedi a \(primoNome(nome)) il consenso. Il riconoscimento della voce avviene \(dispositivo): l’audio non esce mai."
    }

    /// L'iPad senza il Mac: le schede restano qui.
    static func inAttesa(_ n: Int, motivo: String?) -> String {
        let quante = n == 1 ? "1 scheda resta" : "\(n) schede restano"
        return "\(quante) sull’iPad in attesa del Mac" + (motivo.map { ": \($0)" } ?? ".")
    }

    /// Come si chiama chi parla nella riga.
    static func chi(_ p: PezzoTrascrizione, consulente: String, cliente: String) -> String {
        switch p.chi {
        case .consulente: return primoNome(consulente).isEmpty ? "Tu" : primoNome(consulente)
        case .cliente: return primoNome(cliente)
        case .sconosciuto: return p.dispositivo ?? "Voce"
        }
    }
}

/// I permessi del microfono e del riconoscimento per il copilota: sul Mac quelli di Vera; sull'iPad si chiedono qui (Vera
/// sull'iPad non ascolta ancora) e si prepara la sessione audio per la sola registrazione.
enum PermessiCopilota {
    static func chiedi(_ esito: @escaping (String?) -> Void) {
        #if os(macOS)
        AscoltoVera.permessi(esito)
        #elseif os(iOS)
        SFSpeechRecognizer.requestAuthorization { parlato in
            guard parlato == .authorized else {
                DispatchQueue.main.async {
                    esito("Prisma non ha il permesso di riconoscere la voce: concedilo in Impostazioni › Privacy e sicurezza › Riconoscimento vocale.")
                }
                return
            }
            AVAudioApplication.requestRecordPermission { concesso in
                DispatchQueue.main.async {
                    guard concesso else {
                        esito("Prisma non ha il permesso di usare il microfono: concedilo in Impostazioni › Privacy e sicurezza › Microfono.")
                        return
                    }
                    do {
                        let s = AVAudioSession.sharedInstance()
                        try s.setCategory(.record, mode: .measurement, options: [])
                        try s.setActive(true, options: [])
                        esito(nil)
                    } catch {
                        esito("Il microfono non si è avviato: \(error.localizedDescription)")
                    }
                }
            }
        }
        #endif
    }

    /// Finito l'ascolto, l'iPad lascia la sessione audio alle altre app.
    static func rilascia() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}

/// Le istantanee del copilota dichiarano il contatore e se Qwen è pronto (lo stato vero non c'è senza microfono).
struct ScenaIstantaneaCopilota: Equatable {
    var secondi: Int
    var qwenPronto: Bool
}

@Observable final class StatoCopilotaIncontro {
    enum Fase: Equatable {
        case pronto
        /// I permessi e la preparazione del riconoscimento: il microfono non è ancora acceso.
        case prepara
        case ascolto
        /// Fermato da solo (blocco di Prisma, Mac a riposo, schermata chiusa): quello che è stato capito resta.
        case interrotto
        /// «Termina»: il verbale si apre dal pulsante.
        case concluso
    }

    /// L'id del dettaglio del verbale, che nasce dal pulsante della testata.
    static let idVerbale = "copilota-verbale"
    /// Quanti livelli del microfono tiene l'onda.
    static let livelliTenuti = Tema.Apple.Copilota.Onda.barre
    /// Una frase senza voce né parole fa ripartire l'ascolto; dopo tante di fila lo si dice (il microfono è muto?).
    static let silenziDaSegnalare = 3
    /// Un errore del riconoscimento fa ripartire l'ascolto, al massimo tante volte di fila.
    static let erroriDaRiprovare = 2

    var modo = ModoAscoltoIncontro.copilota
    private(set) var fase = Fase.pronto
    /// La sessione dell'ascolto in corso o appena concluso (in `DatiPrisma.sessioniCopilota`).
    private(set) var sessioneId: String?
    /// Il motivo per cui non si ascolta (microfono, riconoscimento, consenso): in rosso sotto il titolo.
    private(set) var problema: String?
    /// La frase che il riconoscimento sta ancora scrivendo.
    private(set) var rigaInCorso = ""
    private(set) var livelli: [Float] = []
    /// Secondi d'ascolto delle riprese già finite; `inizio` quella in corso.
    private(set) var secondiPrima: TimeInterval = 0
    private(set) var inizio: Date?
    /// «Conserva la trascrizione» del verbale: spento di base.
    var conservaTrascrizione = false
    /// Le voci del verbale da confermare (nil = tutte le proposte).
    var scelteVerbale: Set<String>?
    /// Il verbale riformulato da Vera con Qwen (le cifre controllate), per la sessione `verbaleVeraPer`.
    private(set) var verbaleVera: String?
    private(set) var verbaleVeraInCorso = false
    @ObservationIgnored private var verbaleVeraPer: String?
    /// La riga da cui nasce la scheda toccata.
    var indicata: String?
    /// iPad: le schede non ancora arrivate al Mac e perché.
    private(set) var inAttesaPonte = 0
    private(set) var motivoPonte: String?
    private(set) var invioInCorso = false
    /// Le istantanee: contatore e Qwen dichiarati.
    private(set) var scena: ScenaIstantaneaCopilota?
    /// Il dettaglio del verbale (già aperto nelle istantanee che lo mostrano).
    @ObservationIgnored private(set) var dettaglio = StatoDettaglio()

    @ObservationIgnored private var ascolto: AscoltoVera?
    @ObservationIgnored private var abbonamenti = Set<AnyCancellable>()
    @ObservationIgnored private var bloccoOsservato = false
    @ObservationIgnored private var scelta = SceltaRiconoscimento.classico
    @ObservationIgnored private var ripieghi: [SceltaRiconoscimento] = []
    @ObservationIgnored private var silenziDiFila = 0
    @ObservationIgnored private var erroriDiFila = 0
    /// «Termina» con una frase a metà: arriva ancora, poi basta.
    @ObservationIgnored private var ultimaInArrivo = false
    @ObservationIgnored private weak var stato: StatoShell?
    /// iPad: l'ultima versione di ogni scheda e i pezzi già arrivati al Mac.
    @ObservationIgnored private var schedeInviate: [String: String] = [:]
    @ObservationIgnored private var pezziInviati: Set<String> = []
    @ObservationIgnored private var invioDaRifare = false

    init() {}

    var ascolta: Bool { fase == .prepara || fase == .ascolto }

    /// I secondi d'ascolto fino a `adesso` (fissi nelle istantanee).
    func secondi(_ adesso: Date = Date()) -> Int {
        if let s = scena { return s.secondi }
        return Int(secondiPrima + (inizio.map { adesso.timeIntervalSince($0) } ?? 0))
    }

    /// Qwen pronto (nelle istantanee quello dichiarato).
    func qwenPronto(_ stato: StatoShell) -> Bool {
        scena?.qwenPronto ?? stato.disponibilitaLocale.pronto
    }

    /// La sessione da mostrare per il cliente: quella di questo ascolto, se è sua; altrimenti quella aperta.
    func sessione(per clienteId: String, in stato: StatoShell) -> SessioneCopilota? {
        if let id = sessioneId, let s = stato.sessioneCopilota(id), s.clienteId == clienteId { return s }
        return stato.sessioneCopilotaAperta(clienteId: clienteId)
    }

    // MARK: - Ascolto

    /// Avvia (o riprende) l'ascolto dell'incontro: solo con il consenso del cliente (`avviaSessioneCopilota` passa
    /// dalla guardia e altrimenti dice perché).
    func avvia(_ stato: StatoShell, clienteId: String, incontroId: String?) {
        guard !ascolta else { return }
        guard let sid = stato.avviaSessioneCopilota(clienteId: clienteId, incontroId: incontroId) else {
            problema = GuardiaCopilota.motivoBlocco(stato.cliente(clienteId))
            return
        }
        self.stato = stato
        osservaBlocco(stato)
        if sid != sessioneId {
            secondiPrima = 0
            verbaleVera = nil
            verbaleVeraPer = nil
            scelteVerbale = nil
        }
        sessioneId = sid
        problema = nil
        rigaInCorso = ""
        livelli = []
        silenziDiFila = 0
        erroriDiFila = 0
        ultimaInArrivo = false
        let r = stato.dati.impostazioni.vera.riconoscimento
        // La dettatura di macOS scrive in un campo: qui vale l'automatico
        ripieghi = (r == .automatico || r == .dettatura) ? SceltaRiconoscimento.catenaAutomatica : [r]
        scelta = ripieghi.isEmpty ? .classico : ripieghi.removeFirst()
        fase = .prepara
        ascoltaFrase()
    }

    /// «■ Termina»: si ferma il microfono, la frase a metà arriva ancora, poi il verbale.
    func termina() {
        guard ascolta else { return }
        let aMeta = fase == .ascolto && !rigaInCorso.trimmingCharacters(in: .whitespaces).isEmpty
        chiudiRipresa()
        fase = .concluso
        ultimaInArrivo = aMeta
        ascolto?.ferma(invia: aMeta)
        if !aMeta { PermessiCopilota.rilascia() }
        if let stato { mandaAlMacSeServe(stato) }
    }

    /// «Annulla» durante la preparazione.
    func annulla() {
        guard fase == .prepara else { return }
        ascolto?.ferma(invia: false)
        PermessiCopilota.rilascia()
        fase = (secondiPrima > 0) ? .interrotto : .pronto
    }

    /// Fermato da fuori (blocco, schermata chiusa): quello che è stato capito resta, il resto si lascia perdere.
    func interrompi() {
        guard ascolta else { return }
        chiudiRipresa()
        ultimaInArrivo = false
        ascolto?.ferma(invia: false)
        PermessiCopilota.rilascia()
        rigaInCorso = ""
        fase = .interrotto
    }

    /// Dopo il verbale confermato (o un cambio di cliente): pronto per un altro ascolto.
    func azzera() {
        if ascolta { interrompi() }
        fase = .pronto
        sessioneId = nil
        problema = nil
        secondiPrima = 0
        inizio = nil
        livelli = []
        rigaInCorso = ""
        scelteVerbale = nil
        verbaleVera = nil
        verbaleVeraPer = nil
        verbaleVeraInCorso = false
        conservaTrascrizione = false
        indicata = nil
    }

    private func chiudiRipresa() {
        if let i = inizio { secondiPrima += Date().timeIntervalSince(i) }
        inizio = nil
        livelli = []
    }

    private func motore() -> AscoltoVera {
        if let a = ascolto { return a }
        let a = AscoltoVera(permessi: PermessiCopilota.chiedi)
        // Un incontro ha lunghi silenzi: la frase si chiude alla pausa, ma senza voce si aspetta di più prima di ripartire
        a.tempi.attesaMassima = 45
        a.$stato
            .sink { [weak self] s in self?.cambio(s) }
            .store(in: &abbonamenti)
        a.$trascritto
            .removeDuplicates()
            .sink { [weak self] t in
                guard let self, self.fase == .ascolto else { return }
                withAnimation(Movimenti.calmo ? nil : Tema.Apple.Moto.Copilota.parola) { self.rigaInCorso = t }
            }
            .store(in: &abbonamenti)
        a.$livello
            .sink { [weak self] l in self?.livello(l) }
            .store(in: &abbonamenti)
        ascolto = a
        return a
    }

    private func osservaBlocco(_ stato: StatoShell) {
        guard !bloccoOsservato else { return }
        bloccoOsservato = true
        // Il blocco di Prisma (anche con il Mac a riposo o lo schermo spento) ferma subito l'ascolto
        stato.sistema.bloccatoCambiera
            .removeDuplicates()
            .sink { [weak self] bloccato in if bloccato { self?.interrompi() } }
            .store(in: &abbonamenti)
    }

    private func ascoltaFrase() {
        let a = motore()
        a.concluso = { [weak self] frase in self?.fraseFinita(frase) }
        a.problema = { [weak self] motivo in self?.problemaAscolto(motivo) }
        a.azzera()
        a.avvia(scelta)
    }

    private func riprendi() {
        Movimenti.dopo(Tema.Apple.Moto.Copilota.ripresaAscolto) { [weak self] in
            guard let self, self.ascolta else { return }
            self.ascoltaFrase()
        }
    }

    private func cambio(_ s: AscoltoVera.Stato) {
        // La prima volta che il microfono si accende parte il contatore; le riprese fra una frase e l'altra no
        if s == .ascolta, fase == .prepara {
            fase = .ascolto
            if inizio == nil { inizio = Date() }
        }
    }

    private func livello(_ l: Float) {
        guard fase == .ascolto else { return }
        var x = livelli
        x.append(l)
        if x.count > Self.livelliTenuti { x.removeFirst(x.count - Self.livelliTenuti) }
        livelli = x
    }

    /// Una frase finita: le regole di Prisma la leggono subito (schede proposte), Qwen dopo se è pronto; sull'iPad
    /// parte verso il Mac. Poi si torna ad ascoltare.
    private func fraseFinita(_ frase: String) {
        let ultima = ultimaInArrivo
        ultimaInArrivo = false
        guard ascolta || ultima, let stato, let sid = sessioneId else { return }
        silenziDiFila = 0
        erroriDiFila = 0
        if problema != nil { problema = nil }
        let clienteId = stato.sessioneCopilota(sid)?.clienteId
        // L'ultimo pezzo prima e dopo (non il numero: oltre `massimoPezziCopilota` i più vecchi escono e il conto resta fermo)
        let prima = stato.sessioneCopilota(sid)?.trascrizione.last?.id
        stato.ascoltaPezzoCopilota(frase, sessione: sid, dispositivo: StatoCopilotaIncontro.dispositivoLocale)
        rigaInCorso = ""
        guard let dopo = stato.sessioneCopilota(sid), let pezzo = dopo.trascrizione.last, pezzo.id != prima else {
            // Niente è entrato: il consenso non c'è più o la sessione è chiusa
            interrompi()
            problema = GuardiaCopilota.motivoBlocco(clienteId.flatMap { stato.cliente($0) })
                ?? "La sessione d’ascolto è chiusa: avvia di nuovo il copilota."
            return
        }
        stato.riconosciConQwenCopilota(pezzo: pezzo.id, sessione: sid)
        mandaAlMacSeServe(stato)
        if ultima {
            PermessiCopilota.rilascia()
        } else {
            riprendi()
        }
    }

    private func problemaAscolto(_ motivo: String) {
        if ultimaInArrivo {
            ultimaInArrivo = false
            PermessiCopilota.rilascia()
            return
        }
        guard ascolta else { return }
        switch ascolto?.fallimento {
        case .senzaParole?, .senzaSuono?:
            // Silenzio o rumore: si continua; dopo tante volte di fila si dice (il microfono potrebbe essere muto)
            silenziDiFila += 1
            if silenziDiFila >= Self.silenziDaSegnalare { problema = motivo }
            riprendi()
            return
        case .nonPartito?, .nonPronto?:
            if !ripieghi.isEmpty {
                scelta = ripieghi.removeFirst()
                riprendi()
                return
            }
        case .errore?:
            if erroriDiFila < Self.erroriDaRiprovare {
                erroriDiFila += 1
                riprendi()
                return
            }
        default:
            break
        }
        chiudiRipresa()
        PermessiCopilota.rilascia()
        rigaInCorso = ""
        fase = secondiPrima > 0 ? .interrotto : .pronto
        problema = motivo
    }

    static var dispositivoLocale: String? {
        #if os(iOS)
        return "iPad"
        #else
        return nil
        #endif
    }

    // MARK: - Il verbale

    /// Le schede del verbale che si possono ancora confermare e che sono scelte.
    func scelte(_ s: SessioneCopilota) -> Set<String> {
        let proposte = Set(s.proposte.map(\.id))
        return scelteVerbale.map { $0.intersection(proposte) } ?? proposte
    }

    func alterna(_ schedaId: String, in s: SessioneCopilota) {
        var x = scelte(s)
        if x.contains(schedaId) { x.remove(schedaId) } else { x.insert(schedaId) }
        scelteVerbale = x
    }

    /// Conferma le voci scelte (scrive nel dossier), chiude la sessione con la scelta sulla trascrizione e il verbale.
    func confermaVerbale(_ stato: StatoShell, sessione s: SessioneCopilota) {
        let ids = scelte(s)
        if !ids.isEmpty {
            stato.confermaSchedeCopilota(ids, sessione: s.id)
        }
        stato.chiudiSessioneCopilota(s.id, conservaTrascrizione: conservaTrascrizione)
        stato.confermaVerbaleCopilota(s.id)
        scelteVerbale = nil
    }

    /// Vera riformula i punti del verbale con Qwen (se è pronto); si tiene solo un testo con le stesse cifre.
    func scriviVerbaleConVera(_ stato: StatoShell, sessione s: SessioneCopilota, punti: [String], cliente: String) {
        // Una richiesta per sessione e numero di punti: una frase arrivata dopo «Termina» ne fa scrivere un'altra
        let chiave = "\(s.id)#\(punti.count)"
        guard scena == nil, stato.disponibilitaLocale.pronto, !punti.isEmpty, !verbaleVeraInCorso,
              verbaleVeraPer != chiave else { return }
        verbaleVeraPer = chiave
        verbaleVera = nil
        verbaleVeraInCorso = true
        let bozza = punti.joined(separator: "\n")
        let messaggi = [MessaggioModello(ruolo: .sistema, testo: IstruzioniVerbaleCopilota.testo),
                        MessaggioModello(ruolo: .utente, testo: "Cliente: \(cliente)\n\nPUNTI DEL VERBALE\n" + bozza)]
        var o = OpzioniModello()
        o.temperatura = 0.2
        o.pensa = false
        o.contesto = NucleoVera.finestra
        o.massimoToken = 400
        o.restaInMemoria = stato.dati.impostazioni.vera.restaInMemoria
        // Una costante per il Task: una `var` catturata in un codice che gira in concorrenza non compila
        let opzioni = o
        let motore = stato.qwen
        Task { @MainActor [weak self] in
            let r = try? await motore.scrivi(messaggi, opzioni: opzioni)
            guard let self, self.verbaleVeraPer == chiave else { return }
            self.verbaleVeraInCorso = false
            let t = (r?.testo ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            // Una cifra che i punti non dicono: si tiene il verbale di Prisma
            if !t.isEmpty, CommentoVera.numeriConservati(bozza: bozza, testo: t) { self.verbaleVera = t }
        }
    }

    // MARK: - iPad → Mac

    private static func firma(_ x: SchedaCopilota) -> String {
        "\(x.tipo.rawValue)|\(x.titolo)|\(x.azione.rawValue)"
    }

    /// Sull'iPad manda al Mac le schede e i pezzi nuovi (solo testo, sul ponte cifrato). Se il Mac non c'è restano qui
    /// in attesa, e si dice; si riprova alla frase dopo o con «Manda al Mac». Sul Mac non fa niente.
    func mandaAlMacSeServe(_ stato: StatoShell) {
        #if os(iOS)
        mandaAlMac(stato)
        #endif
    }

    func mandaAlMac(_ stato: StatoShell) {
        guard scena == nil, let sid = sessioneId, let s = stato.sessioneCopilota(sid) else { return }
        let schede = s.schede.filter { $0.stato != .scartata && schedeInviate[$0.id] != StatoCopilotaIncontro.firma($0) }
        let pezzi = s.trascrizione.filter { !pezziInviati.contains($0.id) }
        inAttesaPonte = schede.count
        guard !schede.isEmpty || !pezzi.isEmpty else {
            motivoPonte = nil
            return
        }
        guard !invioInCorso else {
            invioDaRifare = true
            return
        }
        invioInCorso = true
        let daMandare = Array(schede.prefix(PonteVera.massimoSchede))
        let righe = Array(pezzi.suffix(PonteVera.massimoPezzi))
        let messaggio = SchedeCopilotaPonte(clienteId: s.clienteId, dispositivo: TestiCopilota.nomeDispositivo,
                                            pezzi: righe, schede: daMandare)
        let vera = stato.dati.impostazioni.vera
        Task { @MainActor [weak self] in
            let r = await PonteVera.manda(.schedeCopilota(messaggio), vera: vera)
            guard let self else { return }
            self.invioInCorso = false
            if r.accettato {
                for x in daMandare { self.schedeInviate[x.id] = StatoCopilotaIncontro.firma(x) }
                for p in righe { self.pezziInviati.insert(p.id) }
                self.motivoPonte = nil
            } else {
                self.motivoPonte = r.motivo ?? PonteVera.macNonTrovato
            }
            let ora = stato.sessioneCopilota(sid)?.schede ?? []
            self.inAttesaPonte = ora.filter { $0.stato != .scartata && self.schedeInviate[$0.id] != StatoCopilotaIncontro.firma($0) }.count
            if self.invioDaRifare {
                self.invioDaRifare = false
                if r.accettato { self.mandaAlMac(stato) }
            }
        }
    }

    // MARK: - Istantanee

    /// Solo per le istantanee: la fase, la sessione, il contatore, Qwen e il problema dichiarati, il verbale aperto.
    func mostraPerIstantanea(fase f: Fase, sessione: String?, secondi: Int, qwenPronto: Bool, problema p: String? = nil,
                             verbale: Bool = false, attesaPonte: Int = 0, motivoPonte m: String? = nil) {
        fase = f
        sessioneId = sessione
        scena = ScenaIstantaneaCopilota(secondi: secondi, qwenPronto: qwenPronto)
        problema = p
        inAttesaPonte = attesaPonte
        motivoPonte = m
        if verbale {
            dettaglio = StatoDettaglio(aperto: Self.idVerbale, misura: Tema.Apple.Copilota.Verbale.misura)
        }
    }
}

/// Le istruzioni del verbale riformulato da Vera (Vera/Istruzioni/verbale-copilota.md, con un ripiego minimo).
enum IstruzioniVerbaleCopilota {
    static var testo: String {
        IstruzioniVera.testo("verbale-copilota")
            ?? "Riscrivi in italiano, in poche frasi chiare e cordiali, i punti del verbale di un incontro fra un consulente finanziario e il suo cliente. Usa solo le cifre dei punti, tutte e così come sono: niente cifre nuove, niente conti, niente consigli. Rispondi solo con il testo del verbale."
    }
}

extension StatoShell {
    /// Chi parla in una riga: un solo microfono non distingue le voci, quindi la si sceglie toccando il nome
    /// (consulente → cliente → non indicato). Solo il testo dell'etichetta cambia.
    func cambiaChiCopilota(_ pezzoId: String, sessione id: String) {
        guard let i = dati.sessioniCopilota.firstIndex(where: { $0.id == id }),
              let k = dati.sessioniCopilota[i].trascrizione.firstIndex(where: { $0.id == pezzoId }) else { return }
        let ora = dati.sessioniCopilota[i].trascrizione[k].chi
        let dopo: PezzoTrascrizione.Chi
        switch ora {
        case .consulente: dopo = .cliente
        case .cliente: dopo = .sconosciuto
        case .sconosciuto: dopo = .consulente
        }
        dati.sessioniCopilota[i].trascrizione[k].chi = dopo
    }
}
