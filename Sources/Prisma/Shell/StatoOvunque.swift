#if os(macOS)
import AppKit
import Observation
#elseif os(iOS)
import UIKit
#endif
import Combine
import Foundation
import SwiftUI

// Prisma ovunque (Design/template-novita-specifica.md §13.4-13.5, prova di fattibilità Design/ovunque-fattibilita.md,
// giro 8): lo stato della pagina Impostazioni › iPhone e iPad e i collegamenti con StatoShell.
// - Spento finché l'utente non lo accende (interruttore «Copia cifrata su iPhone e iPad» e modulo con cartella e
//   passphrase). La passphrase non resta da nessuna parte: la chiave madre va nel Portachiavi (`PortachiaviOvunque`)
//   e in memoria qui (`chiave`), mai nell'archivio.
// - Il lavoro (cifratura, lettura e scrittura coordinate) gira sulla coda `coda`, fuori dal thread principale; il
//   risultato torna all'archivio sul thread principale. Se nel frattempo l'utente ha cambiato qualcosa, sul Mac le
//   operazioni unite si riportano sull'archivio di adesso (nulla di confermato si perde), sul dispositivo le modifiche
//   nuove entrano nel giornale e si riapplicano sopra l'istantanea.
// - Mac: si unisce all'avvio, quando Prisma torna attivo, al risveglio, al ritmo dell'istantanea (al massimo ogni 10
//   minuti, `RitmoIstantanea`) e con «Sincronizza ora». FSEvents (`OsservatoreCartellaOvunque`) fa solo il controllo
//   leggero: legge i giornali e mostra le modifiche in arrivo, che si uniscono con «Sincronizza ora» o al giro dopo.
// - iPhone e iPad: il giornale nasce dal confronto dell'archivio (`RegistroOvunque.registra`, 2 s dopo l'ultima
//   modifica) e va nella cartella entro 5 s; si sincronizza all'avvio, tornando in primo piano, andando in background
//   e con il pulsante. Niente Timer: Combine e `asyncAfter`.
// Mai nelle istantanee e nelle prove (`persistente`): lì la pagina mostra solo lo stato preparato.

/// Cosa impedisce la sincronizzazione (lo stato della card).
enum ProblemaOvunque: Equatable {
    /// La chiave non c'è (Portachiavi vuoto o negato) o non vale più (passphrase cambiata sul Mac).
    case passphrase
    /// iCloud Drive non raggiungibile.
    case iCloud
    /// Il segnalibro non si risolve o l'accesso è negato: si sceglie di nuovo la cartella.
    case cartella
    /// Il file è in iCloud ma non ancora qui.
    case attesa
    case altro(String)
}

/// I moduli in linea della pagina: accendere (cartella e passphrase), riaprire con la passphrase, cambiarla (Mac).
enum ModuloOvunque: Equatable {
    case accendi
    case passphrase
    case cambia
}

@Observable final class StatoOvunque {
    /// Una sincronizzazione (o l'apertura dello spazio) sta lavorando.
    var inCorso = false
    var problema: ProblemaOvunque?
    /// Qualche file è in iCloud ma non ancora su questo apparecchio.
    var attesaICloud = false
    /// Mac: le operazioni lette nei giornali e non ancora unite (controllo leggero con FSEvents).
    var inArrivo: [OperazioneOvunque] = []
    /// I nomi dei dispositivi per id («iPhone», «iPad»).
    var nomiDispositivi: [String: String] = [:]
    /// Le operazioni unite dall'ultima sincronizzazione (Mac).
    var ultimeUnite: [OperazioneOvunque] = []
    /// Cresce a ogni sincronizzazione riuscita: il lucchetto della nuvola rimbalza.
    var giri = 0
    /// Il modulo aperto nella pagina e il suo errore.
    var modulo: ModuloOvunque?
    var erroreModulo: String?
    /// Mac: la cartella scelta nel modulo (prima dell'accensione). iPhone e iPad: quella scelta con File.
    var cartellaScelta: URL?
    /// «Vedi»: le modifiche in attesa e «Da decidere» aperte sotto la riga.
    var modificheAperte = false
    /// iPhone e iPad: il selettore di File per la cartella.
    var sceltaCartella = false

    /// La chiave madre di questa sessione (dal Portachiavi o dalla passphrase appena scritta). Mai nell'archivio.
    @ObservationIgnored var chiave: ChiaveSpazio?
    /// La cartella aperta (su iOS tiene aperto il security scope per la sessione).
    @ObservationIgnored var cartella: CartellaCondivisaFile?
    /// Dispositivo: l'archivio all'ultima registrazione del giornale (si confronta con quello di adesso).
    @ObservationIgnored var base: DatiPrisma?
    /// Mac: l'archivio visto all'ultimo controllo del ritmo (senza le impostazioni dello spazio e senza Vera).
    @ObservationIgnored var ultimiDatiVisti: DatiPrisma?
    @ObservationIgnored var ultimoTentativoIstantanea: Date?
    /// Un altro giro chiesto mentre uno lavorava.
    @ObservationIgnored var ancoraUnGiro = false
    @ObservationIgnored var ancoraForzato = false
    @ObservationIgnored var lavoroIstantanea: DispatchWorkItem?
    @ObservationIgnored var lavoroGiornale: DispatchWorkItem?
    @ObservationIgnored var lavoroControllo: DispatchWorkItem?
    @ObservationIgnored var avviato = false
    #if os(macOS)
    @ObservationIgnored var osservatore: OsservatoreCartellaOvunque?
    #endif
    /// Il lavoro con i file e la cifratura, uno alla volta.
    let coda = DispatchQueue(label: "prisma.ovunque", qos: .utility)

    /// La lettura dei problemi dagli errori dello spazio.
    static func problemaDa(_ errore: Error) -> ProblemaOvunque {
        guard let e = errore as? ErroreOvunque else { return .altro(errore.localizedDescription) }
        switch e {
        case .cartellaNonRaggiungibile: return .iCloud
        case .accessoNegato, .spazioMancante: return .cartella
        case .passphraseErrata, .generazioneCambiata: return .passphrase
        case .inAttesaDiICloud: return .attesa
        default: return .altro(e.localizedDescription)
        }
    }

    /// Il nome di questo apparecchio nello spazio.
    static var nomeApparecchio: String {
        #if os(macOS)
        return "Mac"
        #elseif os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        #endif
    }

    static var ruoloApparecchio: RuoloOvunque { RuoloOvunque.predefinito }
}

/// Il risultato di un giro, sul Mac o sul dispositivo.
private enum EsitoGiroOvunque {
    case mac(EsitoSincroniaMac)
    case dispositivo(EsitoSincroniaDispositivo)
}

extension StatoShell {
    // MARK: - Stato per la pagina

    /// Lo stato della card dello schema.
    var statoVistaOvunque: StatoVistaOvunque {
        let o = dati.impostazioni.ovunque
        if ovunque.inCorso { return .inCorso }
        guard o.acceso else { return .spenta }
        if let p = ovunque.problema {
            switch p {
            case .passphrase: return .passphrase
            case .iCloud: return .iCloud
            case .cartella: return .cartella
            case .attesa: return .attesaICloud
            case .altro(let m): return .errore(m)
            }
        }
        if o.ruolo == .mac {
            if o.generazione == 0 { return .maiFatta(mac: true) }
            let n = dati.conflittiOvunque.count
            if n > 0 { return .conflitti(n) }
        } else {
            if o.ultimaIstantanea == nil { return ovunque.attesaICloud ? .attesaICloud : .maiFatta(mac: false) }
            if ovunque.attesaICloud { return .attesaICloud }
        }
        return .riuscita(o.ultimoControllo ?? o.ultimaIstantanea)
    }

    /// Su iPhone e iPad: si lavora sulla copia cifrata e il Mac non risponde al ponte (pillola «Senza Mac»).
    var senzaMacOvunque: Bool {
        let o = dati.impostazioni.ovunque
        return o.acceso && o.ruolo == .dispositivo && !disponibilitaLocale.pronto
    }

    /// Le modifiche ancora in attesa: sul Mac quelle arrivate nei giornali e non unite, sul dispositivo il giornale.
    var modificheInAttesaOvunque: [OperazioneOvunque] {
        dati.impostazioni.ovunque.ruolo == .mac ? ovunque.inArrivo : dati.giornaleOvunque
    }

    /// Il nome di un dispositivo per l'utente.
    func nomeDispositivoOvunque(_ id: String) -> String {
        if id == dati.impostazioni.ovunque.idDispositivo { return dati.impostazioni.ovunque.nomeDispositivo ?? StatoOvunque.nomeApparecchio }
        if let n = ovunque.nomiDispositivi[id] { return n }
        if let c = dati.conflittiOvunque.first(where: { $0.operazione.dispositivo == id }) { return c.nomeDispositivo }
        if let a = dati.arriviOvunque.last(where: { $0.dispositivo == id }) { return a.nomeDispositivo }
        return "iPhone"
    }

    /// Il cliente di un'operazione (dal valore nuovo o dall'oggetto sull'archivio), per «Nota nuova per Giulia Rossi».
    func clienteOperazioneOvunque(_ op: OperazioneOvunque) -> Cliente? {
        let id: String?
        if op.entita == .bisogni {
            id = op.entitaId
        } else if let c = JSONOvunque.oggetto(op.dopo)?["clienteId"] as? String {
            id = c
        } else if let c = JSONOvunque.oggetto(op.prima)?["clienteId"] as? String {
            id = c
        } else {
            id = clienteIdOvunque(op.entita, id: op.entitaId)
        }
        guard let id else { return nil }
        return dati.clienti.first { $0.id == id }
    }

    /// Il cliente dell'oggetto sull'archivio (nil se non c'è): legge solo il campo di quell'entità, così una vista che lo
    /// chiede non si iscrive a tutto l'archivio (come faceva `CampiOvunque.oggetto` sull'istantanea).
    func clienteIdOvunque(_ e: EntitaOvunque, id: String) -> String? {
        switch e {
        case .nota: return dati.note.first { $0.id == id }?.clienteId
        case .attivita: return dati.attivita.first { $0.id == id }?.clienteId
        case .appuntamento: return dati.appuntamenti.first { $0.id == id }?.clienteId
        case .eventoVita: return dati.eventiVita.first { $0.id == id }?.clienteId
        case .sessioneCopilota: return dati.sessioniCopilota.first { $0.id == id }?.clienteId
        case .inquadratura: return dati.inquadratureDaConfermare.first { $0.id == id }?.clienteId
        case .bisogni: return dati.clienti.first { $0.id == id }?.id
        }
    }

    // MARK: - Avvio e collegamenti

    /// All'avvio, con l'archivio sul disco (mai nelle istantanee e nelle prove): i collegamenti e, se lo spazio è
    /// acceso, la chiave dal Portachiavi e un primo giro.
    func avviaOvunque() {
        guard persistente, !ovunque.avviato else { return }
        ovunque.avviato = true
        #if os(macOS)
        // Il ritmo dell'istantanea: 5 s dopo l'ultima modifica, al massimo ogni 10 minuti
        // (`prepend`: come faceva `$dati`, la prima consegna arriva anche senza modifiche e fa da linea di base)
        modificheDati.prepend(()).debounce(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.archivioCambiatoOvunque(self.dati.istantanea)
            }
            .store(in: &abbonamenti)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tornatoAttivoOvunque() }
            .store(in: &abbonamenti)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sincronizzaOvunque(automatica: true) }
            .store(in: &abbonamenti)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + StatoShell.attesaDopoRisveglio) {
                    self?.sincronizzaOvunque(automatica: true)
                }
            }
            .store(in: &abbonamenti)
        #elseif os(iOS)
        // Il giornale: 2 s dopo l'ultima modifica si confronta l'archivio
        modificheDati.prepend(()).debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.registraOvunqueOra() }
            .store(in: &abbonamenti)
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sincronizzaOvunque(automatica: true) }
            .store(in: &abbonamenti)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + StatoShell.attesaRitornoPrimoPiano) {
                    self?.sincronizzaOvunque(automatica: true)
                }
            }
            .store(in: &abbonamenti)
        #endif
        guard dati.impostazioni.ovunque.acceso else { return }
        ovunque.base = dati.istantanea
        apriSpazioOvunque(sincronizza: true)
    }

    /// Apre lo spazio con la chiave del Portachiavi (fuori dal thread principale) e, se `sincronizza`, fa un giro.
    func apriSpazioOvunque(sincronizza: Bool) {
        guard persistente else { return }
        guard let c = cartellaOvunque() else {
            ovunque.problema = .cartella
            return
        }
        ovunque.coda.async { [weak self] in
            guard let byte = PortachiaviOvunque.leggi() else {
                DispatchQueue.main.async { self?.ovunque.problema = .passphrase }
                return
            }
            do {
                let k = try SpazioOvunque.apri(in: c, chiave: byte)
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.ovunque.chiave = k
                    self.ovunque.problema = nil
                    self.avviaOsservatoreOvunque()
                    if sincronizza { self.sincronizzaOvunque(automatica: true) }
                }
            } catch {
                DispatchQueue.main.async { self?.ovunque.problema = StatoOvunque.problemaDa(error) }
            }
        }
    }

    /// La cartella dello spazio (dal segnalibro, rigenerato se scaduto), tenuta aperta per la sessione.
    func cartellaOvunque() -> CartellaCondivisaFile? {
        if let c = ovunque.cartella { return c }
        var o = dati.impostazioni.ovunque
        let c = o.cartella()
        if o != dati.impostazioni.ovunque { dati.impostazioni.ovunque = o }
        ovunque.cartella = c
        return c
    }

    /// Mac: FSEvents sulla cartella. A ogni gruppo di eventi, il controllo leggero (2 s dopo l'ultimo).
    func avviaOsservatoreOvunque() {
        #if os(macOS)
        guard persistente, ovunque.osservatore == nil, dati.impostazioni.ovunque.ruolo == .mac,
              let c = ovunque.cartella else { return }
        let o = OsservatoreCartellaOvunque(cartella: c.url) { [weak self] in
            DispatchQueue.main.async { self?.programmaControlloOvunque() }
        }
        if o.avvia() { ovunque.osservatore = o }
        #endif
    }

    private func fermaOsservatoreOvunque() {
        #if os(macOS)
        ovunque.osservatore?.ferma()
        ovunque.osservatore = nil
        #endif
    }

    #if os(macOS)
    /// Mac: l'archivio è cambiato (5 s dopo l'ultima modifica). Se è cambiato qualcosa che va nell'istantanea, la
    /// prossima si scrive al ritmo di `RitmoIstantanea`.
    private func archivioCambiatoOvunque(_ d: DatiPrisma) {
        let o = d.impostazioni.ovunque
        guard o.acceso, o.ruolo == .mac, ovunque.chiave != nil else { return }
        var senza = d
        senza.impostazioni.ovunque = ImpostazioniOvunque()
        senza.conversazioni = [:]
        guard senza != ovunque.ultimiDatiVisti else { return }
        let primaVolta = ovunque.ultimiDatiVisti == nil
        ovunque.ultimiDatiVisti = senza
        guard !primaVolta else { return }
        programmaIstantaneaOvunque()
    }

    /// Prisma torna in primo piano: un giro se l'ultimo controllo è di più di un minuto fa.
    private func tornatoAttivoOvunque() {
        let o = dati.impostazioni.ovunque
        guard o.acceso, ovunque.chiave != nil else { return }
        if let u = o.ultimoControllo, Date().timeIntervalSince(u) < StatoShell.intervalloControlloOvunque { return }
        sincronizzaOvunque(automatica: true)
    }
    #endif

    /// Fra un controllo all'attivazione e l'altro.
    static let intervalloControlloOvunque: TimeInterval = 60
    /// FSEvents: il controllo leggero parte 2 s dopo l'ultimo evento; il giornale va nella cartella entro 5 s.
    static let attesaControlloOvunque: TimeInterval = 2
    static let attesaGiornaleOvunque: TimeInterval = 5

    /// Mac: la prossima istantanea al ritmo (al massimo una ogni 10 minuti per le modifiche fatte sul Mac).
    func programmaIstantaneaOvunque() {
        let o = dati.impostazioni.ovunque
        guard persistente, o.acceso, o.ruolo == .mac, ovunque.lavoroIstantanea == nil else { return }
        let ultima = [o.ultimaIstantanea, ovunque.ultimoTentativoIstantanea].compactMap { $0 }.max()
        let attesa = RitmoIstantanea.attesa(ultima: ultima)
        let lavoro = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.ovunque.lavoroIstantanea = nil
            self.ovunque.ultimoTentativoIstantanea = Date()
            self.sincronizzaOvunque(automatica: true)
        }
        ovunque.lavoroIstantanea = lavoro
        DispatchQueue.main.asyncAfter(deadline: .now() + attesa, execute: lavoro)
    }

    private func programmaControlloOvunque() {
        ovunque.lavoroControllo?.cancel()
        let lavoro = DispatchWorkItem { [weak self] in
            self?.ovunque.lavoroControllo = nil
            self?.controllaOvunque()
        }
        ovunque.lavoroControllo = lavoro
        DispatchQueue.main.asyncAfter(deadline: .now() + StatoShell.attesaControlloOvunque, execute: lavoro)
    }

    /// Mac: il controllo leggero. Legge i giornali senza unirli e mostra le modifiche in arrivo.
    func controllaOvunque() {
        let o = dati.impostazioni.ovunque
        guard persistente, o.acceso, o.ruolo == .mac, !ovunque.inCorso, let chiave = ovunque.chiave,
              let c = cartellaOvunque() else { return }
        let visto = o.vistoFinoA
        let inCoda = Set(dati.conflittiOvunque.map(\.id))
        let mac = o.idDispositivo
        ovunque.coda.async { [weak self] in
            guard let lettura = try? SpazioOvunque.leggiGiornali(chiave: chiave, in: c, escluso: mac) else { return }
            var operazioni: [OperazioneOvunque] = []
            var nomi: [String: String] = [:]
            var viste = Set<String>()
            for g in lettura.giornali {
                nomi[g.dispositivo] = g.nomeDispositivo
                for op in g.operazioni where op.dispositivo == g.dispositivo && op.seq > (visto[op.dispositivo] ?? 0)
                    && !inCoda.contains(op.id) && viste.insert(op.id).inserted {
                    operazioni.append(op)
                }
            }
            operazioni.sort { ($0.data, $0.seq) < ($1.data, $1.seq) }
            DispatchQueue.main.async {
                guard let self, !self.ovunque.inCorso else { return }
                self.ovunque.inArrivo = operazioni
                self.ovunque.nomiDispositivi.merge(nomi) { _, nuovo in nuovo }
                self.ovunque.attesaICloud = !lettura.inAttesa.isEmpty
            }
        }
    }

    #if os(iOS)
    /// Dispositivo: le modifiche dall'ultima registrazione entrano nel giornale; poi il giornale va nella cartella.
    func registraOvunqueOra() {
        let o = dati.impostazioni.ovunque
        guard o.scriveGiornale else {
            ovunque.base = nil
            return
        }
        guard let base = ovunque.base else {
            ovunque.base = dati.istantanea
            return
        }
        var d = dati.istantanea
        let n = RegistroOvunque.registra(prima: base, dopo: &d)
        if n > 0 { dati.carica(d) }
        ovunque.base = dati.istantanea
        if n > 0 { programmaGiornaleOvunque() }
    }

    private func programmaGiornaleOvunque() {
        guard ovunque.lavoroGiornale == nil else { return }
        let lavoro = DispatchWorkItem { [weak self] in
            self?.ovunque.lavoroGiornale = nil
            self?.sincronizzaOvunque(automatica: true)
        }
        ovunque.lavoroGiornale = lavoro
        DispatchQueue.main.asyncAfter(deadline: .now() + StatoShell.attesaGiornaleOvunque, execute: lavoro)
    }
    #endif

    // MARK: - Sincronizzare

    /// Un giro: sul Mac unisce i giornali e riscrive l'istantanea se serve (`forza`: sempre); sul dispositivo scrive
    /// il giornale e legge l'istantanea. `automatica`: niente avviso se non è cambiato nulla, niente errori a schermo.
    func sincronizzaOvunque(forza: Bool = false, automatica: Bool = false) {
        guard persistente, !solaLettura else { return }
        let o = dati.impostazioni.ovunque
        guard o.acceso else { return }
        if ovunque.inCorso {
            ovunque.ancoraUnGiro = true
            ovunque.ancoraForzato = ovunque.ancoraForzato || forza
            return
        }
        #if os(iOS)
        registraOvunqueOra()
        #endif
        guard let chiave = ovunque.chiave else {
            if ovunque.problema == nil { apriSpazioOvunque(sincronizza: true) }
            return
        }
        guard let c = cartellaOvunque() else {
            ovunque.problema = .cartella
            return
        }
        let partenza = dati.istantanea
        let versione = versioneDati
        let inizio = Date()
        ovunque.inCorso = true
        #if os(iOS)
        // Il giornale va scritto anche se l'app sta andando in background
        let compito = UIApplication.shared.beginBackgroundTask(withName: "Prisma ovunque", expirationHandler: nil)
        #endif
        ovunque.coda.async { [weak self] in
            let risultato: Result<EsitoGiroOvunque, Error>
            do {
                if partenza.impostazioni.ovunque.ruolo == .mac {
                    let e = try SincroniaOvunque.sincronizzaMac(partenza, chiave: chiave, cartella: c, forza: forza)
                    risultato = .success(.mac(e))
                } else {
                    let e = try SincroniaOvunque.sincronizzaDispositivo(partenza, chiave: chiave, cartella: c)
                    risultato = .success(.dispositivo(e))
                }
            } catch {
                risultato = .failure(error)
            }
            // «Sincronizzo…» resta almeno 1,8 s dopo il pulsante (i pallini veloci), poi la fine vera
            let minimo = automatica ? 0 : Tema.Apple.Ovunque.Moto.durataVeloce
            let attesa = max(0, minimo - Date().timeIntervalSince(inizio))
            DispatchQueue.main.asyncAfter(deadline: .now() + attesa) {
                #if os(iOS)
                if compito != .invalid { UIApplication.shared.endBackgroundTask(compito) }
                #endif
                guard let self else { return }
                self.concludiGiroOvunque(risultato, partenza: partenza, versione: versione, automatica: automatica)
            }
        }
    }

    private func concludiGiroOvunque(_ risultato: Result<EsitoGiroOvunque, Error>, partenza: DatiPrisma, versione: Int,
                                     automatica: Bool) {
        ovunque.inCorso = false
        // Spento mentre lavorava: il risultato non serve più
        guard dati.impostazioni.ovunque.acceso else { return }
        switch risultato {
        case .success(.mac(let e)):
            dati.carica(versioneDati == versione ? e.dati : StatoShell.riportaOvunque(e, su: dati.istantanea))
            ovunque.problema = nil
            ovunque.attesaICloud = !e.inAttesa.isEmpty
            ovunque.inArrivo = []
            if !e.unite.isEmpty { ovunque.ultimeUnite = e.unite }
            ovunque.giri += 1
            if !automatica || !e.unite.isEmpty || !e.conflitti.isEmpty {
                mostraAvviso(TestiOvunque.avviso(unite: e.unite.count, conflitti: e.conflitti.count))
            }
        case .success(.dispositivo(let e)):
            dati.carica(accogliGiroOvunque(e, partenza: partenza, versione: versione))
            ovunque.base = dati.istantanea
            ovunque.problema = nil
            ovunque.attesaICloud = e.inAttesaDiICloud
            ovunque.giri += 1
            if !automatica { mostraAvviso(TestiOvunque.avviso(unite: e.confermate, conflitti: 0)) }
        case .failure(let errore):
            let p = StatoOvunque.problemaDa(errore)
            if p == .attesa {
                ovunque.attesaICloud = true
            } else {
                ovunque.problema = p
                dati.impostazioni.ovunque.ultimoErrore = errore.localizedDescription
                if !automatica { mostraAvviso("Sincronizzazione non riuscita: \(errore.localizedDescription)") }
            }
            if p == .passphrase { ovunque.chiave = nil }
            if p == .cartella || p == .iCloud { ovunque.cartella = nil }
        }
        if ovunque.ancoraUnGiro {
            let forza = ovunque.ancoraForzato
            ovunque.ancoraUnGiro = false
            ovunque.ancoraForzato = false
            DispatchQueue.main.async { [weak self] in self?.sincronizzaOvunque(forza: forza, automatica: true) }
        }
    }

    /// Mac: l'archivio è cambiato mentre il giro lavorava. Le operazioni unite si riportano sull'archivio di adesso
    /// (una che ora fa conflitto va in «Da decidere»), con la ricevuta e le impostazioni dello spazio del giro.
    static func riportaOvunque(_ e: EsitoSincroniaMac, su attuale: DatiPrisma) -> DatiPrisma {
        var d = attuale
        let adesso = RegistroOvunque.alSecondo(Date())
        for op in e.unite {
            if case .conflitto(let motivo, let valoreMac) = MotoreUnioneOvunque.applica(op, a: &d),
               !d.conflittiOvunque.contains(where: { $0.id == op.id }) {
                let nome = e.dati.arriviOvunque.last(where: { $0.dispositivo == op.dispositivo })?.nomeDispositivo ?? op.dispositivo
                d.conflittiOvunque.append(ConflittoOvunque(operazione: op, motivo: motivo, valoreMac: valoreMac,
                                                           nomeDispositivo: nome, arrivatoIl: adesso))
            }
        }
        for c in e.conflitti where !d.conflittiOvunque.contains(where: { $0.id == c.id }) {
            d.conflittiOvunque.append(c)
        }
        for a in e.dati.arriviOvunque where !d.arriviOvunque.contains(a) {
            d.arriviOvunque.append(a)
        }
        var o = e.dati.impostazioni.ovunque
        o.acceso = attuale.impostazioni.ovunque.acceso
        o.modificheDaiDispositivi = attuale.impostazioni.ovunque.modificheDaiDispositivi
        d.impostazioni.ovunque = o
        return d
    }

    /// Dispositivo: l'esito del giro sull'archivio di adesso. Le modifiche fatte mentre il giro lavorava entrano nel
    /// giornale e, se è arrivata un'istantanea nuova, si riapplicano sopra.
    private func accogliGiroOvunque(_ e: EsitoSincroniaDispositivo, partenza: DatiPrisma, versione: Int) -> DatiPrisma {
        var corrente = dati.istantanea
        if versioneDati != versione, let b = ovunque.base {
            RegistroOvunque.registra(prima: b, dopo: &corrente)
        }
        guard e.istantaneaNuova else {
            corrente.impostazioni.ovunque.ultimoControllo = e.dati.impostazioni.ovunque.ultimoControllo
            corrente.impostazioni.ovunque.ultimoErrore = nil
            corrente.impostazioni.ovunque.impronteCartella = e.dati.impostazioni.ovunque.impronteCartella
            return corrente
        }
        var nuovo = e.dati
        let ultimoSeq = partenza.giornaleOvunque.map(\.seq).max() ?? 0
        let nuove = corrente.giornaleOvunque.filter { $0.seq > ultimoSeq }
        for op in nuove { MotoreUnioneOvunque.applicaForzata(op, a: &nuovo) }
        nuovo.giornaleOvunque.append(contentsOf: nuove)
        nuovo.impostazioni.ovunque.prossimoSeq = max(nuovo.impostazioni.ovunque.prossimoSeq, corrente.impostazioni.ovunque.prossimoSeq)
        nuovo.impostazioni.ovunque.lamport = max(nuovo.impostazioni.ovunque.lamport, corrente.impostazioni.ovunque.lamport)
        return nuovo
    }

    // MARK: - Accendere, riaprire, spegnere

    /// La cartella proposta sul Mac: iCloud Drive › Prisma ovunque (si crea all'accensione). nil senza iCloud Drive.
    var cartellaPropostaOvunque: URL? {
        #if os(macOS)
        guard SceltaCartellaOvunque.iCloudDriveAcceso else { return nil }
        return SceltaCartellaOvunque.iCloudDrive.appendingPathComponent("Prisma ovunque", isDirectory: true)
        #else
        return nil
        #endif
    }

    /// L'interruttore «Copia cifrata su iPhone e iPad». Accendendo: se lo spazio c'era già (chiave e cartella) si
    /// riaccende subito, altrimenti si apre il modulo con la cartella e la passphrase. Spegnendo chiede conferma la vista.
    func chiediAccensioneOvunque() {
        let o = dati.impostazioni.ovunque
        guard !o.acceso else { return }
        if o.idDispositivo != nil, o.segnalibro != nil || o.percorso != nil, ovunque.chiave != nil {
            dati.impostazioni.ovunque.acceso = true
            ovunque.base = dati.istantanea
            avviaOsservatoreOvunque()
            sincronizzaOvunque(forza: true)
            return
        }
        ovunque.erroreModulo = nil
        if ovunque.cartellaScelta == nil { ovunque.cartellaScelta = cartellaPropostaOvunque }
        ovunque.modulo = .accendi
    }

    #if os(macOS)
    /// Mac: «Scegli…» del modulo (NSOpenPanel).
    func scegliCartellaOvunque() {
        guard let url = SceltaCartellaOvunque.scegli() else { return }
        ovunque.cartellaScelta = url
        ovunque.erroreModulo = ImpostazioniOvunque.motivoRifiuto(url, cartellaBackup: cartellaBackup)
    }
    #endif

    /// Accende lo spazio con la cartella e la passphrase del modulo. Mac: crea lo spazio (o lo riapre se c'è già e la
    /// passphrase lo apre); iPhone e iPad: apre lo spazio del Mac. Poi la chiave va nel Portachiavi e parte il primo giro.
    func accendiOvunque(cartella url: URL, passphrase: String) {
        guard persistente, !ovunque.inCorso else { return }
        let ruolo = StatoOvunque.ruoloApparecchio
        #if os(macOS)
        let backup: URL? = cartellaBackup
        #else
        let backup: URL? = nil
        #endif
        if let motivo = ImpostazioniOvunque.motivoRifiuto(url, cartellaBackup: backup) {
            ovunque.erroreModulo = motivo
            return
        }
        let idDiPrima = dati.impostazioni.ovunque.idDispositivo
        let id = idDiPrima ?? ImpostazioniOvunque.nuovoId(ruolo)
        ovunque.erroreModulo = nil
        ovunque.inCorso = true
        ovunque.coda.async { [weak self] in
            do {
                if ruolo == .mac {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                }
                let c = CartellaCondivisaFile(url: url, ambitoProtetto: ruolo == .dispositivo)
                let chiave: ChiaveSpazio
                if ruolo == .mac {
                    do {
                        chiave = try SpazioOvunque.creaSpazio(in: c, passphrase: passphrase, mac: id)
                    } catch ErroreOvunque.spazioGiaPresente {
                        // Lo spazio di questo stesso Mac (stesso id: spazio spento e riacceso): la passphrase lo riapre.
                        // Uno spazio creato da un altro Mac, o da questo prima di reinstallare Prisma, non si adotta:
                        // il Mac lo riscriverebbe con il suo archivio sopra quello del proprietario, senza chiedere.
                        chiave = try SpazioOvunque.apri(in: c, passphrase: passphrase)
                        guard chiave.descrittore.proprietario == id else { throw ErroreOvunque.spazioDiAltroMac }
                    }
                } else {
                    chiave = try SpazioOvunque.apri(in: c, passphrase: passphrase)
                }
                let pronta = chiave
                let idFinale = id
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.ovunque.inCorso = false
                    var o = self.dati.impostazioni.ovunque
                    o.ruolo = ruolo
                    do {
                        try o.ricorda(url)
                    } catch {
                        self.ovunque.erroreModulo = ErroreOvunque.accessoNegato(url.path).localizedDescription
                        return
                    }
                    o.accendi(ruolo: ruolo, id: idFinale, nome: StatoOvunque.nomeApparecchio, chiave: pronta)
                    self.dati.impostazioni.ovunque = o
                    if !PortachiaviOvunque.salva(pronta.byte) {
                        self.mostraAvviso("La chiave non è entrata nel Portachiavi: al prossimo avvio Prisma ti chiederà la passphrase.")
                    }
                    self.ovunque.chiave = pronta
                    self.ovunque.cartella = c
                    self.ovunque.problema = nil
                    self.ovunque.cartellaScelta = nil
                    self.ovunque.base = self.dati.istantanea
                    self.ovunque.modulo = nil
                    self.avviaOsservatoreOvunque()
                    self.sincronizzaOvunque(forza: true)
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.ovunque.inCorso = false
                    self.ovunque.erroreModulo = error.localizedDescription
                }
            }
        }
    }

    /// «Scrivi la passphrase…»: riapre lo spazio (chiave persa, passphrase cambiata sul Mac) e fa un giro.
    func sbloccaOvunque(passphrase: String) {
        guard persistente, !ovunque.inCorso else { return }
        guard let c = cartellaOvunque() else {
            ovunque.erroreModulo = ErroreOvunque.cartellaNonRaggiungibile.localizedDescription
            return
        }
        ovunque.erroreModulo = nil
        ovunque.inCorso = true
        ovunque.coda.async { [weak self] in
            do {
                let k = try SpazioOvunque.apri(in: c, passphrase: passphrase)
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.ovunque.inCorso = false
                    if !PortachiaviOvunque.salva(k.byte) {
                        self.mostraAvviso("La chiave non è entrata nel Portachiavi: al prossimo avvio Prisma ti chiederà la passphrase.")
                    }
                    self.ovunque.chiave = k
                    self.ovunque.problema = nil
                    self.dati.impostazioni.ovunque.generazioneChiave = k.descrittore.generazioneChiave
                    self.ovunque.modulo = nil
                    self.avviaOsservatoreOvunque()
                    self.sincronizzaOvunque(forza: self.dati.impostazioni.ovunque.ruolo == .mac)
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.ovunque.inCorso = false
                    self.ovunque.erroreModulo = error.localizedDescription
                }
            }
        }
    }

    /// Mac: passphrase nuova. Prima si uniscono i giornali con la chiave di adesso, poi sale nuovo e istantanea nuova;
    /// iPhone e iPad chiederanno la passphrase nuova.
    func cambiaPassphraseOvunque(nuova: String) {
        let o = dati.impostazioni.ovunque
        guard persistente, o.acceso, o.ruolo == .mac, !ovunque.inCorso, let attuale = ovunque.chiave,
              let c = cartellaOvunque() else { return }
        let partenza = dati.istantanea
        let versione = versioneDati
        ovunque.erroreModulo = nil
        ovunque.inCorso = true
        ovunque.coda.async { [weak self] in
            do {
                let prima = try SincroniaOvunque.sincronizzaMac(partenza, chiave: attuale, cartella: c)
                let k = try SpazioOvunque.cambiaPassphrase(in: c, attuale: attuale, nuova: nuova)
                var dopo = try SincroniaOvunque.sincronizzaMac(prima.dati, chiave: k, cartella: c, forza: true)
                dopo.unite = prima.unite + dopo.unite
                dopo.conflitti = prima.conflitti + dopo.conflitti
                let esito = dopo
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.ovunque.inCorso = false
                    self.dati.carica(self.versioneDati == versione ? esito.dati : StatoShell.riportaOvunque(esito, su: self.dati.istantanea))
                    self.dati.impostazioni.ovunque.generazioneChiave = k.descrittore.generazioneChiave
                    if !PortachiaviOvunque.salva(k.byte) {
                        self.mostraAvviso("La chiave nuova non è entrata nel Portachiavi: al prossimo avvio Prisma ti chiederà la passphrase.")
                    }
                    self.ovunque.chiave = k
                    self.ovunque.giri += 1
                    self.ovunque.modulo = nil
                    self.mostraAvviso("Passphrase cambiata: su iPhone e iPad scrivi quella nuova.")
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.ovunque.inCorso = false
                    self.ovunque.erroreModulo = error.localizedDescription
                }
            }
        }
    }

    /// Spegne lo spazio (dopo la conferma della vista). Mac: cancella l'istantanea da iCloud Drive, i dati restano sul
    /// Mac. Dispositivo: smette di leggere la copia. La chiave resta nel Portachiavi: riaccendendo non serve riscriverla.
    func spegniOvunque() {
        let o = dati.impostazioni.ovunque
        guard o.acceso else { return }
        ovunque.lavoroIstantanea?.cancel()
        ovunque.lavoroIstantanea = nil
        ovunque.lavoroGiornale?.cancel()
        ovunque.lavoroGiornale = nil
        fermaOsservatoreOvunque()
        if persistente, o.ruolo == .mac, let c = cartellaOvunque() {
            ovunque.coda.async { try? SpazioOvunque.cancellaIstantanea(in: c) }
        }
        dati.impostazioni.ovunque.spegni()
        ovunque.problema = nil
        ovunque.inArrivo = []
        ovunque.attesaICloud = false
        ovunque.modulo = nil
        ovunque.modificheAperte = false
        mostraAvviso(o.ruolo == .mac ? "Copia per iPhone e iPad spenta: il file in iCloud Drive è cancellato, i dati restano sul Mac."
                                     : "Copia del Mac spenta su questo dispositivo.")
    }

    /// «Lavora anche con il Mac spento» (Mac): l'istantanea nuova lo porta a iPhone e iPad.
    func impostaModificheDaiDispositiviOvunque(_ ammesse: Bool) {
        guard dati.impostazioni.ovunque.modificheDaiDispositivi != ammesse else { return }
        dati.impostazioni.ovunque.modificheDaiDispositivi = ammesse
        sincronizzaOvunque(forza: true, automatica: true)
    }

    /// La scelta su un conflitto di «Da decidere». L'istantanea dopo la porta a iPhone e iPad.
    func decidiOvunque(_ id: String, scelta: SceltaConflitto) {
        var d = dati.istantanea
        guard MotoreUnioneOvunque.decidi(id, scelta: scelta, in: &d) else {
            mostraAvviso("Questa modifica non si può tenere: il cliente non c’è più sul Mac.")
            return
        }
        dati.carica(d)
        programmaIstantaneaOvunque()
    }

    /// iPhone e iPad: la cartella scelta con File (il segnalibro si crea all'accensione).
    func cartellaSceltaOvunque(_ esito: Result<URL, Error>) {
        switch esito {
        case .success(let url):
            ovunque.cartellaScelta = url
            ovunque.erroreModulo = nil
        case .failure(let errore):
            ovunque.erroreModulo = errore.localizedDescription
        }
    }
}
