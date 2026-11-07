#if os(macOS)
import AppKit
import Combine
import CryptoKit
import Foundation
import Network
import SwiftUI

// Il tavolo con l'iPad, lato Mac. Il consulente guida dal Mac; l'iPad davanti al cliente mostra solo ciò che sceglie:
// una pagina della presentazione (il PNG del foglio impaginato qui), il prospetto intero, la macchina del tempo o la
// famiglia (cifre già calcolate dai motori, minime, solo del cliente presente), un cursore da muovere (il Mac
// ricalcola e rimanda il risultato), la richiesta di presa visione. La presa visione torna con il tratto e la data:
// finisce in fondo al PDF del documento, archiviato nei Documenti del cliente.
// Il servizio ascolta in rete (NWListener, come ServerPonteVera) solo dopo «Apri il tavolo» e si spegne con «Chiudi
// il tavolo». Il codice di abbinamento è quello del ponte di Vera (Impostazioni › Vera); il protocollo è in
// ProtocolloTavolo.swift. Le viste (pulsante «Al tavolo», pannello, striscia della sala, pagina della presa visione)
// stanno in Shell/AlTavolo.swift.

/// La rete del Mac: ascolta, abbina con il codice e tiene un iPad alla volta (l'ultimo che si abbina vince).
/// Tutto sulla coda propria; gli eventi arrivano su quella coda.
final class AscoltoTavolo: @unchecked Sendable {
    enum Evento: Sendable {
        case pronto(UInt16)
        case collegato(String)
        case ricevuto(ContenutoTavolo)
        case scollegato(CanaleTavolo.Fine)
        /// Un dispositivo con un altro codice (o che non saluta) è stato respinto.
        case rifiutato
        case errore(String)
    }

    private let coda = DispatchQueue(label: "prisma.tavolo.mac")
    private let chiave: SymmetricKey
    private let tempi: ProtocolloTavolo.Tempi
    private let nomeMac: String
    private let blocco = NSLock()
    private var _porta: UInt16?
    private var ascolto: NWListener?
    private var inAttesa: [ObjectIdentifier: CanaleTavolo] = [:]
    private var collegato: CanaleTavolo?
    /// Da impostare prima di `avvia`.
    var eventi: ((Evento) -> Void)?

    init(chiave: SymmetricKey, nomeMac: String, tempi: ProtocolloTavolo.Tempi) {
        self.chiave = chiave
        self.nomeMac = nomeMac
        self.tempi = tempi
    }

    /// La porta su cui ascolta davvero (nelle prove una porta libera qualsiasi).
    var porta: UInt16? {
        blocco.lock(); defer { blocco.unlock() }
        return _porta
    }

    func avvia(porta p: UInt16, annuncia: Bool) {
        coda.async { [self] in
            guard ascolto == nil else { return }
            let parametri = NWParameters.tcp
            parametri.includePeerToPeer = false
            let punto: NWEndpoint.Port = p == 0 ? .any : (NWEndpoint.Port(rawValue: p) ?? .any)
            guard let a = try? NWListener(using: parametri, on: punto) else {
                eventi?(.errore("La porta \(p) del Mac è occupata: il tavolo non si apre."))
                return
            }
            if annuncia { a.service = NWListener.Service(name: nomeMac, type: ProtocolloTavolo.servizio) }
            a.stateUpdateHandler = { [weak self, weak a] s in
                guard let self, let a else { return }
                switch s {
                case .ready:
                    let n = a.port?.rawValue
                    self.blocco.lock()
                    self._porta = n
                    self.blocco.unlock()
                    if let n { self.eventi?(.pronto(n)) }
                case .failed(let e):
                    self.eventi?(.errore("Il tavolo si è fermato: \(e.localizedDescription)"))
                    self.spegni()
                default:
                    break
                }
            }
            a.newConnectionHandler = { [weak self] c in self?.accogli(c) }
            ascolto = a
            a.start(queue: coda)
        }
    }

    /// Spegne tutto: «fine» all'iPad collegato, chiude le connessioni in attesa e smette di ascoltare.
    func ferma() {
        coda.async { [self] in spegni() }
    }

    func manda(_ c: ContenutoTavolo) {
        coda.async { [self] in collegato?.manda(c) }
    }

    /// Le prove: la connessione con l'iPad cade di colpo.
    func interrompiPerProva() {
        coda.async { [self] in collegato?.interrompi() }
    }

    /// Le prove: il Mac tace (niente battito) finché l'iPad non si accorge che è caduto.
    func silenziaPerProva() {
        coda.async { [self] in collegato?.silenzia() }
    }

    // MARK: Dentro la coda

    private func spegni() {
        let c = collegato
        collegato = nil
        c?.chiudi()
        for a in inAttesa.values { a.interrompi() }
        inAttesa = [:]
        ascolto?.cancel()
        ascolto = nil
        blocco.lock()
        _porta = nil
        blocco.unlock()
    }

    private func accogli(_ c: NWConnection) {
        let canale = CanaleTavolo(c, chiave: chiave, sessione: nil, tempi: tempi, coda: coda)
        let id = ObjectIdentifier(canale)
        inAttesa[id] = canale
        canale.avvia(ricevuto: { [weak self, weak canale] m in
            guard let self, let canale else { return }
            self.ricevi(m, da: canale)
        }, chiusura: { [weak self, weak canale] f in
            guard let self else { return }
            self.inAttesa[id] = nil
            if let canale, canale === self.collegato {
                self.collegato = nil
                self.eventi?(.scollegato(f))
            } else if f == .rifiutato {
                self.eventi?(.rifiutato)
            }
        })
        // Chi non saluta in tempo (o con un altro codice) se ne va
        coda.asyncAfter(deadline: .now() + tempi.abbinamento) { [weak self, weak canale] in
            guard let self, let canale, self.inAttesa[id] != nil else { return }
            canale.interrompi()
        }
    }

    private func ricevi(_ m: MessaggioTavolo, da canale: CanaleTavolo) {
        guard let c = m.contenuto, c.dellIPad else { return }
        guard canale === collegato else {
            // Il primo messaggio di un iPad è il saluto: con il codice giusto diventa l'iPad del tavolo
            guard case .ciao(let s) = c else { return canale.interrompi() }
            inAttesa[ObjectIdentifier(canale)] = nil
            let vecchio = collegato
            collegato = canale
            vecchio?.chiudi()
            canale.manda(.benvenuto(SalutoTavolo(nome: nomeMac)))
            canale.avviaBattito()
            eventi?(.collegato(s.nome))
            return
        }
        switch c {
        case .valoreCursore, .presaVisione: eventi?(.ricevuto(c))
        default: break
        }
    }
}

/// Da dove si manda al tavolo: il documento mostrato (Prospetti o la sala), la pagina e il cliente presente.
struct ContestoTavolo {
    var documento: DocumentoStampabile?
    /// Da 0.
    var pagina: Int
    /// Il cliente presente (nil = il cliente attivo).
    var clienteId: String?
    /// true dalla sala della presentazione: chiudendo la sala l'iPad torna alla schermata neutra.
    var dallaSala = false
}

/// Un comando del pannello del tavolo.
struct AzioneTavolo: Identifiable {
    let id: String
    let titolo: String
    let simbolo: String
    let abilitata: Bool
    /// Spiegazione al passaggio del puntatore.
    let aiuto: String
    let azione: @MainActor () -> Void
}

/// Il tavolo con l'iPad sul Mac: lo stato per le viste e i comandi del consulente.
/// Dal thread principale (le viste); la rete lavora sulla sua coda e torna qui.
final class TavoloMac: ObservableObject {
    enum Collegamento: Equatable {
        /// Il tavolo è chiuso: niente ascolto in rete.
        case spento
        /// Il Mac ascolta, nessun iPad collegato.
        case inAttesa
        /// L'iPad (con il suo nome) è collegato.
        case collegato(String)
    }

    @Published private(set) var collegamento: Collegamento = .spento
    /// La striscia dei comandi nella sala.
    @Published var pannello = false
    /// Che cosa vede ora il cliente sull'iPad (nil = la schermata neutra).
    @Published private(set) var mostrato: String?
    /// Il cursore lasciato al cliente, con l'ultimo valore scelto e il risultato.
    @Published private(set) var cursore: CursoreTavolo?
    /// La presa visione chiesta e non ancora arrivata.
    @Published private(set) var attesaPresaVisione: RichiestaPresaVisioneTavolo?
    /// Il documento dei Documenti con l'ultima presa visione archiviata.
    @Published private(set) var ultimaPresaVisione: String?
    @Published private(set) var avviso: String?

    private weak var stato: StatoShell?
    private var ascolto: AscoltoTavolo?
    /// L'ultimo documento mandato al tavolo (per la presa visione) e di chi è.
    private var documento: DocumentoStampabile?
    private var clienteDocumento: String?
    /// Di quale cliente è ciò che l'iPad mostra.
    private var clienteMostrato: String?
    private var ricalcolo: ((Double) -> RisultatoCursoreTavolo)?
    private var dallaSala = false
    private var abbonamento: AnyCancellable?

    /// «nov 2023» sotto il grafico della macchina del tempo, come nel dossier.
    private static let meseAsse = Formati.formato("MMM yyyy")

    init(stato: StatoShell) {
        self.stato = stato
    }

    var acceso: Bool { collegamento != .spento }

    var collegato: Bool {
        if case .collegato = collegamento { return true }
        return false
    }

    /// La porta su cui ascolta (nil a tavolo chiuso).
    var porta: UInt16? { ascolto?.porta }

    /// «iPad collegato», «iPad non collegato», «Tavolo chiuso».
    var descrizione: String {
        switch collegamento {
        case .spento: return "Tavolo chiuso"
        case .inAttesa: return "iPad non collegato"
        case .collegato(let nome): return "iPad collegato · \(nome)"
        }
    }

    /// Si può chiedere la presa visione: l'iPad è collegato e ha visto un documento di questo cliente.
    func puoChiederePresaVisione(_ cliente: String) -> Bool {
        collegato && documento != nil && clienteDocumento == cliente && attesaPresaVisione == nil
    }

    // MARK: Aprire e chiudere

    /// «Apri il tavolo»: ascolta in rete locale (e si annuncia con Bonjour). Senza codice ne crea uno, lo stesso
    /// che usa Vera su iPhone e iPad (Impostazioni › Vera).
    func avvia(porta: UInt16 = ProtocolloTavolo.porta, annuncia: Bool = true, tempi: ProtocolloTavolo.Tempi = .normali) {
        guard ascolto == nil, let s = stato else { return }
        if PonteVera.normalizza(s.dati.impostazioni.vera.ponte.codice) == nil {
            s.dati.impostazioni.vera.ponte.codice = PonteVera.nuovoCodice()
        }
        guard let k = ProtocolloTavolo.chiave(s.dati.impostazioni.vera.ponte.codice) else { return }
        let a = AscoltoTavolo(chiave: k, nomeMac: ServerPonteVera.condiviso.nomeMac, tempi: tempi)
        a.eventi = { [weak self] e in
            DispatchQueue.main.async { [weak self] in self?.evento(e) }
        }
        ascolto = a
        azzera()
        avviso = nil
        collegamento = .inAttesa
        // Un altro cliente aperto sul Mac: l'iPad torna subito alla schermata neutra
        abbonamento = s.$dati.map(\.clienteAttivoId).removeDuplicates().dropFirst()
            .sink { [weak self] id in
                DispatchQueue.main.async { [weak self] in self?.clienteCambiato(id) }
            }
        a.avvia(porta: porta, annuncia: annuncia)
    }

    /// «Chiudi il tavolo»: schermata neutra, «fine» all'iPad e niente più ascolto.
    func chiudi() {
        guard let a = ascolto else { return }
        a.manda(.neutra)
        a.ferma()
        ascolto = nil
        abbonamento = nil
        azzera()
        collegamento = .spento
        pannello = false
    }

    /// «Schermata neutra»: l'iPad non mostra più niente del cliente.
    func schermataNeutra() {
        guard acceso else { return }
        cursore = nil
        ricalcolo = nil
        attesaPresaVisione = nil
        mostrato = nil
        clienteMostrato = nil
        dallaSala = false
        ascolto?.manda(.neutra)
    }

    /// La sala della presentazione si chiude: se l'iPad mostrava una sua pagina torna alla schermata neutra.
    func salaChiusa() {
        guard dallaSala else { return }
        dallaSala = false
        if mostrato != nil || cursore != nil || attesaPresaVisione != nil { schermataNeutra() }
    }

    // MARK: I comandi

    /// «Manda questa pagina»: il PNG della pagina mostrata, impaginata come sulla carta.
    @MainActor
    func mandaPagina(_ c: ContestoTavolo) {
        guard collegato, let d = c.documento, !d.pagine.isEmpty, let cliente = clientePresente(c) else { return }
        let i = min(max(c.pagina, 0), d.pagine.count - 1)
        guard let pagina = Self.pagina(d, indice: i) else {
            avviso = "Non riesco a preparare la pagina per l'iPad."
            return
        }
        let m = MostraTavolo(id: UUID().uuidString, genere: .pagina, titolo: d.titolo, cliente: d.cliente, pagine: [pagina])
        mostra(m, cliente: cliente, descrizione: "Pagina \(i + 1) di \(d.pagine.count) · \(d.titolo)", sala: c.dallaSala)
        documento = d
        clienteDocumento = cliente
    }

    /// «Manda tutto il documento»: tutte le pagine (al massimo `ProtocolloTavolo.massimePagine`).
    @MainActor
    func mandaDocumento(_ c: ContestoTavolo) {
        guard collegato, let d = c.documento, !d.pagine.isEmpty, let cliente = clientePresente(c) else { return }
        let n = min(d.pagine.count, ProtocolloTavolo.massimePagine)
        var pagine: [PaginaTavolo] = []
        for i in 0..<n {
            // Un pool per pagina: bitmap e PNG di ogni foglio si liberano subito (il Mac ha 8 GB)
            guard let p = autoreleasepool(invoking: { Self.pagina(d, indice: i) }) else {
                avviso = "Non riesco a preparare il documento per l'iPad."
                return
            }
            pagine.append(p)
        }
        let m = MostraTavolo(id: UUID().uuidString, genere: .prospetto, titolo: d.titolo, cliente: d.cliente, pagine: pagine)
        mostra(m, cliente: cliente, descrizione: "\(d.genere) · \(d.titolo) · \(n) \(n == 1 ? "pagina" : "pagine")", sala: c.dallaSala)
        documento = d
        clienteDocumento = cliente
    }

    /// «Manda la macchina del tempo»: il patrimonio tre anni indietro e due avanti (MotoreNelTempo), già calcolato.
    func mandaNelTempo(_ c: ContestoTavolo) {
        guard collegato, let s = stato, let id = clientePresente(c), let cliente = s.cliente(id) else { return }
        let storia = CacheNelTempo.storia(cliente: id, posizioni: s.posizioniCliente(id), fotografie: s.fotografieCliente(id),
                                          patrimonio: { s.analisiDossier(id).patrimonio })
        let stima = storia.senzaProposte
        let dati = NelTempoTavolo(
            passato: ProtocolloTavolo.cifre(storia.passato),
            centrale: ProtocolloTavolo.cifre(stima.centrale),
            alta: ProtocolloTavolo.cifre(stima.alta),
            bassa: ProtocolloTavolo.cifre(stima.bassa),
            esposta: stima.esposta,
            centraleConProposte: storia.conProposte.map { ProtocolloTavolo.cifre($0.centrale) },
            fotografie: storia.fotografieNelGrafico.map {
                PuntoFotografiaTavolo(mese: $0.mese, valore: ProtocolloTavolo.cifra($0.foto.patrimonioNetto))
            },
            nettoOggi: ProtocolloTavolo.cifra(storia.nettoOggi),
            inizio: Self.meseAsse.string(from: storia.giorno(-StoriaNelTempo.mesiIndietro)),
            oggi: "oggi",
            fine: Self.meseAsse.string(from: storia.giorno(StoriaNelTempo.mesiAvanti)),
            nota: "Il passato viene dai valori registrati; la stima dei prossimi due anni non è una previsione: la fascia va da 1 caso su 10 sotto a 1 su 10 sopra.")
        let m = MostraTavolo(id: UUID().uuidString, genere: .nelTempo, titolo: "Il patrimonio nel tempo", cliente: cliente.nome,
                             nelTempo: dati)
        mostra(m, cliente: id, descrizione: "La macchina del tempo", sala: c.dallaSala)
    }

    /// «Manda la famiglia»: le persone del nucleo con le scoperture (MotoreFamigliaDossier).
    func mandaFamiglia(_ c: ContestoTavolo) {
        guard collegato, let s = stato, let id = clientePresente(c), let cliente = s.cliente(id) else { return }
        let posizioni = s.posizioniCliente(id)
        let protezione = CacheFamigliaDossier.protezione(cliente: cliente, posizioni: posizioni,
                                                         ipotesi: s.analisi360(id).protezione)
        let persone = MotoreFamigliaDossier.persone(cliente: cliente, protezione: protezione,
                                                    successione: s.analisiDossier(id).successione)
        let famiglia = FamigliaTavolo(persone: persone.map(Self.persona),
                                      nota: "Le capsule vengono dalla protezione persona per persona e dal passaggio generazionale.")
        let m = MostraTavolo(id: UUID().uuidString, genere: .famiglia, titolo: "La famiglia", cliente: cliente.nome, famiglia: famiglia)
        mostra(m, cliente: id, descrizione: "La famiglia", sala: c.dallaSala)
    }

    /// «Manda la linea della vita»: il patrimonio da oggi a 90 anni (MotoreLineaVita), già calcolato, con gli eventi e
    /// la pensione e senza le note interne. Senza data di nascita non c'è niente da mandare: lo dice l'avviso.
    func mandaLineaVita(_ c: ContestoTavolo) {
        guard collegato, let s = stato, let id = clientePresente(c), let cliente = s.cliente(id) else { return }
        let eventi = s.eventiVitaCliente(id)
        let prep = CacheLineaVita.preparazione(cliente: cliente, posizioni: s.posizioniCliente(id),
                                               obiettivi: s.dati.obiettivi.filter { $0.clienteId == id },
                                               eventi: eventi, analisi: s.dati.analisi[id])
        guard let ingresso = prep.ingresso else {
            avviso = prep.motivoAssente ?? "La linea della vita di questo cliente non si può ancora disegnare."
            return
        }
        let esito = MotoreLineaVita.calcola(ingresso)
        let anno = Calendar.current.component(.year, from: Date())
        var voci: [EventoLineaVitaTavolo] = eventi.compactMap { e in
            e.etaEvento(etaOggi: ingresso.etaOggi, annoOggi: anno).map {
                EventoLineaVitaTavolo(nome: e.nome, eta: $0, importo: e.importo.map(ProtocolloTavolo.cifra))
            }
        }
        for m in ingresso.movimenti where m.daObiettivo {
            let titolo = s.dati.obiettivi.first { $0.id == m.id }?.titolo ?? "Obiettivo"
            voci.append(EventoLineaVitaTavolo(nome: titolo, eta: m.eta, importo: ProtocolloTavolo.cifra(m.importo)))
        }
        let dati = LineaVitaTavolo(
            etaOggi: ingresso.etaOggi, etaPensione: esito.etaPensione, etaFine: esito.etaFine,
            valori: ProtocolloTavolo.cifre(esito.punti.map(\.valore)),
            allaPensione: ProtocolloTavolo.cifra(esito.allaPensione), massimo: ProtocolloTavolo.cifra(esito.massimo),
            etaMassimo: esito.etaMassimo, etaEsaurimento: esito.etaEsaurimento,
            prelievoAnnuo: esito.prelievoAnnuo.map(ProtocolloTavolo.cifra), eventi: voci,
            nota: "Valori in euro di oggi, anno per anno: una stima con le ipotesi di Prisma, non una previsione.")
        let m = MostraTavolo(id: UUID().uuidString, genere: .lineaVita, titolo: "La linea della vita", cliente: cliente.nome,
                             lineaVita: dati)
        mostra(m, cliente: id, descrizione: "La linea della vita", sala: c.dallaSala)
    }

    /// «Lascia un cursore al cliente»: il versamento mensile della proposta aperta (o di un piano di accumulo),
    /// fra `minimo` e `massimo`. Il cliente lo muove sull'iPad; il Mac ricalcola con MotoreProiezione.
    func lasciaCursore(_ c: ContestoTavolo, minimo: Double = 50, massimo: Double = 1_000, passo: Double = 25) {
        guard collegato, let s = stato, let id = clientePresente(c), s.cliente(id) != nil else { return }
        let posizione = Self.posizioneCursore(s.posizioniCliente(id))
        let base = Self.parametriCursore(posizione)
        let basso = max(0, min(minimo, massimo))
        let alto = max(basso, max(minimo, massimo))
        var x = CursoreTavolo(id: UUID().uuidString, titolo: "Versamento mensile", unita: "€ al mese", valore: basso,
                              minimo: basso, massimo: alto, passo: max(0, passo),
                              posizione: posizione?.nome ?? "Un piano di accumulo", canale: posizione?.canale, risultato: nil)
        let iniziale = (posizione?.frequenza == .mensile ? posizione?.premio : nil) ?? (basso + alto) / 2
        x.valore = x.valido(iniziale)
        let calcola: (Double) -> RisultatoCursoreTavolo = { v in Self.risultato(base, versamento: v) }
        x.risultato = calcola(x.valore)
        if clienteMostrato != id { documento = nil; clienteDocumento = nil }
        clienteMostrato = id
        attesaPresaVisione = nil
        ricalcolo = calcola
        cursore = x
        mostrato = "Cursore · versamento mensile"
        dallaSala = dallaSala || c.dallaSala
        ascolto?.manda(.cursore(x))
    }

    /// «Chiedi la presa visione» del documento mandato al tavolo.
    func chiediPresaVisione(_ c: ContestoTavolo) {
        guard collegato, let d = documento, let cliente = clienteDocumento, clientePresente(c) == cliente else { return }
        let r = RichiestaPresaVisioneTavolo(id: UUID().uuidString, titolo: "\(d.genere) · \(d.titolo)", cliente: d.cliente,
                                            pagine: d.pagine.count, testo: ProtocolloTavolo.testoPresaVisione)
        cursore = nil
        ricalcolo = nil
        attesaPresaVisione = r
        mostrato = "Presa visione · \(d.titolo)"
        ascolto?.manda(.richiestaPresaVisione(r))
    }

    /// I comandi del pannello, per il documento e il cliente di `c`.
    func azioni(_ c: ContestoTavolo) -> [AzioneTavolo] {
        let cliente = clientePresente(c) ?? ""
        let pronto = collegato
        let conDocumento = pronto && c.documento != nil
        return [
            AzioneTavolo(id: "pagina", titolo: "Manda questa pagina", simbolo: "doc.richtext", abilitata: conDocumento,
                         aiuto: "L'iPad mostra la pagina che vedi, impaginata come sulla carta") { [weak self] in self?.mandaPagina(c) },
            AzioneTavolo(id: "documento", titolo: "Manda tutto il documento", simbolo: "doc.on.doc", abilitata: conDocumento,
                         aiuto: "Il cliente sfoglia sull'iPad tutte le pagine del documento") { [weak self] in self?.mandaDocumento(c) },
            AzioneTavolo(id: "neltempo", titolo: "Manda la macchina del tempo", simbolo: "clock.arrow.circlepath", abilitata: pronto,
                         aiuto: "Il patrimonio tre anni indietro e due avanti, già calcolato") { [weak self] in self?.mandaNelTempo(c) },
            AzioneTavolo(id: "famiglia", titolo: "Manda la famiglia", simbolo: "person.3", abilitata: pronto,
                         aiuto: "Le persone del nucleo con le loro scoperture") { [weak self] in self?.mandaFamiglia(c) },
            AzioneTavolo(id: "lineavita", titolo: "Manda la linea della vita", simbolo: "chart.line.uptrend.xyaxis", abilitata: pronto,
                         aiuto: "Il patrimonio da oggi a 90 anni con gli eventi e la pensione, già calcolato") { [weak self] in self?.mandaLineaVita(c) },
            AzioneTavolo(id: "cursore", titolo: "Lascia un cursore al cliente", simbolo: "slider.horizontal.3", abilitata: pronto,
                         aiuto: "Il cliente sceglie il versamento mensile entro i limiti; Prisma ricalcola sul Mac") { [weak self] in self?.lasciaCursore(c) },
            AzioneTavolo(id: "presavisione", titolo: "Chiedi la presa visione", simbolo: "hand.draw",
                         abilitata: puoChiederePresaVisione(cliente),
                         aiuto: "Il cliente traccia un segno sull'iPad: finisce in fondo al PDF, nei Documenti del cliente") { [weak self] in self?.chiediPresaVisione(c) },
            AzioneTavolo(id: "neutra", titolo: "Schermata neutra", simbolo: "eye.slash", abilitata: pronto,
                         aiuto: "L'iPad non mostra più niente") { [weak self] in self?.schermataNeutra() },
        ]
    }

    // MARK: Le prove e le istantanee

    /// Le prove: la connessione con l'iPad cade di colpo.
    func interrompiPerProva() { ascolto?.interrompiPerProva() }

    /// Le prove: il Mac tace finché l'iPad non si accorge che è caduto.
    func silenziaPerProva() { ascolto?.silenziaPerProva() }

    /// Le istantanee: il tavolo come se l'iPad fosse collegato, senza rete.
    func mostraPerIstantanea(iPad nome: String, mostrato m: String?, pannello p: Bool) {
        collegamento = .collegato(nome)
        mostrato = m
        pannello = p
    }

    // MARK: Dalla rete

    private func evento(_ e: AscoltoTavolo.Evento) {
        guard ascolto != nil else { return }
        switch e {
        case .pronto:
            break
        case .collegato(let nome):
            azzera()
            avviso = nil
            collegamento = .collegato(nome)
        case .scollegato(let f):
            azzera()
            collegamento = .inAttesa
            if f != .chiuso { avviso = "L'iPad si è scollegato: sul suo schermo è tornata la schermata neutra." }
        case .rifiutato:
            avviso = "Un dispositivo ha provato a collegarsi con un codice diverso: respinto."
        case .errore(let testo):
            avviso = testo
            ascolto?.ferma()
            ascolto = nil
            abbonamento = nil
            azzera()
            collegamento = .spento
        case .ricevuto(let c):
            ricevuto(c)
        }
    }

    private func ricevuto(_ c: ContenutoTavolo) {
        switch c {
        case .valoreCursore(let v):
            guard var x = cursore, x.id == v.id, let calcola = ricalcolo else { return }
            x.valore = x.valido(v.valore)
            x.risultato = calcola(x.valore)
            cursore = x
            ascolto?.manda(.cursore(x))
        case .presaVisione(let p):
            guard let r = attesaPresaVisione, r.id == p.id else { return }
            Task { @MainActor [weak self] in self?.archiviaPresaVisione(p, richiesta: r) }
        default:
            break
        }
    }

    /// Il PDF del documento con la pagina della presa visione in fondo, archiviato nei Documenti del cliente.
    @MainActor
    private func archiviaPresaVisione(_ p: PresaVisioneTavolo, richiesta r: RichiestaPresaVisioneTavolo) {
        guard attesaPresaVisione?.id == r.id, let s = stato, let d = documento, let cliente = clienteDocumento else { return }
        attesaPresaVisione = nil
        mostrato = nil
        defer { ascolto?.manda(.neutra) }
        guard p.tratto.count <= ProtocolloTavolo.massimoTratto, let tratto = ProtocolloTavolo.immagine(p.tratto) else {
            avviso = "La presa visione è arrivata guasta: chiedila di nuovo."
            return
        }
        // La data dell'iPad, se l'orologio è d'accordo con quello del Mac; altrimenti quella del Mac
        let adesso = Date()
        let data = Date(timeIntervalSince1970: p.data)
        let quando = abs(data.timeIntervalSince(adesso)) <= ProtocolloTavolo.tolleranzaOrologio ? data : adesso
        let completo = Self.documentoConPresaVisione(d, tratto: tratto, data: quando)
        guard let pdf = StampaCarta.pdf(completo) else {
            avviso = "Non sono riuscito a creare il PDF della presa visione."
            return
        }
        ultimaPresaVisione = s.archiviaProspetto(pdf, documento: completo, cliente: cliente)
    }

    // MARK: Aiuti

    private func clientePresente(_ c: ContestoTavolo) -> String? {
        guard let s = stato else { return nil }
        let id = c.clienteId ?? s.clienteAttivoId
        return id.isEmpty ? nil : id
    }

    private func mostra(_ m: MostraTavolo, cliente: String, descrizione: String, sala: Bool) {
        if clienteMostrato != cliente {
            documento = nil
            clienteDocumento = nil
        }
        clienteMostrato = cliente
        cursore = nil
        ricalcolo = nil
        attesaPresaVisione = nil
        mostrato = descrizione
        dallaSala = sala
        ascolto?.manda(.mostra(m))
    }

    private func clienteCambiato(_ id: String) {
        guard let m = clienteMostrato, m != id else { return }
        schermataNeutra()
        documento = nil
        clienteDocumento = nil
    }

    private func azzera() {
        mostrato = nil
        cursore = nil
        ricalcolo = nil
        attesaPresaVisione = nil
        documento = nil
        clienteDocumento = nil
        clienteMostrato = nil
        dallaSala = false
    }

    /// La pagina `indice` del documento in PNG, sempre in chiaro come sulla carta.
    @MainActor
    static func pagina(_ d: DocumentoStampabile, indice i: Int) -> PaginaTavolo? {
        guard i >= 0, i < d.pagine.count,
              let dati = Self.png(d.pagine[i], formato: d.formato, scala: Tema.Apple.Tavolo.scalaPagina) else { return nil }
        return PaginaTavolo(numero: i + 1, totale: d.pagine.count, larghezza: Double(d.formato.width),
                            altezza: Double(d.formato.height), png: dati)
    }

    /// Il foglio in una bitmap, con lo stesso disegno del PDF (StampaCarta): niente Metal, niente finestra.
    @MainActor
    static func png(_ pagina: AnyView, formato: CGSize, scala: CGFloat) -> Data? {
        let w = Int((formato.width * scala).rounded())
        let h = Int((formato.height * scala).rounded())
        guard w > 0, h > 0, let spazio = CGColorSpace(name: CGColorSpace.sRGB),
              let contesto = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: spazio,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        contesto.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        contesto.fill(CGRect(x: 0, y: 0, width: w, height: h))
        contesto.scaleBy(x: scala, y: scala)
        let renderer = ImageRenderer(content: pagina.frame(width: formato.width, height: formato.height)
            .environment(\.etichetteStampa, true)
            .environment(\.colorScheme, .light))
        renderer.proposedSize = ProposedViewSize(formato)
        if let chiaro = NSAppearance(named: .aqua) {
            chiaro.performAsCurrentDrawingAppearance { renderer.render { _, disegna in disegna(contesto) } }
        } else {
            renderer.render { _, disegna in disegna(contesto) }
        }
        guard let immagine = contesto.makeImage() else { return nil }
        return ProtocolloTavolo.png(immagine)
    }

    /// Il documento con la pagina della presa visione in fondo (stesso formato delle altre pagine).
    static func documentoConPresaVisione(_ d: DocumentoStampabile, tratto: CGImage, data: Date) -> DocumentoStampabile {
        let finale = AnyView(PaginaPresaVisione(titolo: d.titolo, genere: d.genere, cliente: d.cliente, pagine: d.pagine.count,
                                                formato: d.formato, tratto: tratto, data: data))
        return DocumentoStampabile(titolo: "Presa visione · \(d.titolo)", cliente: d.cliente, genere: d.genere, formato: d.formato,
                                   pagine: d.pagine + [finale], tipo: d.tipo)
    }

    private static func persona(_ p: PersonaFamiglia) -> PersonaTavolo {
        PersonaTavolo(nome: p.nome, iniziali: p.iniziali, titolare: p.titolare, descrizione: p.descrizione,
                      scoperture: p.scoperture.map { s in
                          let tono: TonoTavolo
                          switch s.tono {
                          case .rosso: tono = .rosso
                          case .arancio: tono = .arancio
                          case .verde: tono = .verde
                          }
                          return ScoperturaTavolo(testo: s.testo, tono: tono)
                      })
    }

    /// La posizione del cursore: la prima proposta aperta con versamenti (o la prima aperta), altrimenti il primo
    /// piano in essere con versamenti mensili. nil: un piano di accumulo con le ipotesi predefinite.
    static func posizioneCursore(_ posizioni: [Posizione]) -> Posizione? {
        let aperte = posizioni.filter {
            $0.stato == .proposta && $0.esito != .rifiutata && $0.esito != .accettata && $0.area.proiettabile
        }
        if let p = aperte.first(where: { $0.frequenza != .unica }) ?? aperte.first { return p }
        return posizioni.first { $0.stato == .inEssere && $0.area.proiettabile && $0.frequenza == .mensile }
    }

    /// I parametri della proiezione del cursore (versamenti mensili).
    static func parametriCursore(_ p: Posizione?) -> ParametriProiezione {
        var q = p.map { ParametriProiezione(posizione: $0) }
            ?? ParametriProiezione(capitaleIniziale: 0, versamento: 0, frequenza: .mensile,
                                   anni: IpotesiCalcolo.orizzontePredefinito, rendimento: IpotesiCalcolo.rendimentoPredefinito)
        q.frequenza = .mensile
        if q.anni <= 0, q.mesiEsatti == nil { q.anni = IpotesiCalcolo.orizzontePredefinito }
        return q
    }

    /// Il ricalcolo per un versamento: il netto finale con MotoreProiezione, il versato e il guadagno.
    static func risultato(_ base: ParametriProiezione, versamento v: Double) -> RisultatoCursoreTavolo {
        var q = base
        q.versamento = max(0, v)
        q.frequenza = .mensile
        let e = MotoreProiezione.calcola(q)
        let anni = q.anni == 1 ? "1 anno" : "\(q.anni) anni"
        return RisultatoCursoreTavolo(
            valore: v, titolo: "Fra \(anni), al netto di costi e imposte", cifra: ProtocolloTavolo.cifra(e.netto),
            righe: [RigaRisultatoTavolo(etichetta: "Versato in tutto", cifra: ProtocolloTavolo.cifra(e.versato)),
                    RigaRisultatoTavolo(etichetta: "Guadagno netto", cifra: ProtocolloTavolo.cifra(e.guadagnoNetto)),
                    RigaRisultatoTavolo(etichetta: "In euro di oggi", cifra: ProtocolloTavolo.cifra(e.reale))],
            nota: "Una stima con un rendimento del \(Formati.percentuale(q.rendimento)) l'anno: non è una previsione né una garanzia.")
    }
}

extension DocumentoStampabile {
    /// Un documento già impaginato, di qualsiasi formato (la presa visione del tavolo).
    init(titolo: String, cliente: String, genere: String, formato: CGSize, pagine: [AnyView], tipo: Documento.Tipo) {
        self.titolo = titolo
        self.cliente = cliente
        self.genere = genere
        self.formato = formato
        self.pagine = pagine
        self.tipo = tipo
    }
}
#endif
