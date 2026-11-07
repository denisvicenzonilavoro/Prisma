import Combine
import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import Network
import UniformTypeIdentifiers

// Il tavolo con l'iPad: sul Mac guida il consulente, l'iPad davanti al cliente mostra solo ciò che il Mac sceglie.
// Qui il protocollo, comune al Mac (TavoloMac.swift) e all'iPad (`ClienteTavolo`, senza viste):
// - rete locale e basta: il Mac ascolta (NWListener) e si annuncia con Bonjour su «_prisma-tavolo._tcp»;
//   l'iPad lo trova (o si collega a un indirizzo dato) e apre una connessione TCP che resta aperta;
// - la stessa cifratura e lo stesso codice di abbinamento del ponte di Vera (Vera/PonteVera.swift): ChaChaPoly con la
//   chiave HKDF ricavata dal codice, con un sale proprio del tavolo (una busta di Vera non vale qui, e viceversa);
// - ogni messaggio è una cornice: 4 byte di lunghezza (big endian) e poi la scatola ChaChaPoly del JSON;
// - ogni messaggio porta la versione, la sessione (scelta dall'iPad nel saluto), un numero che cresce e l'ora:
//   un messaggio di un'altra sessione, ripetuto o vecchio chiude la connessione;
// - un battito ogni pochi secondi da tutte e due le parti: se l'altra tace troppo la connessione è caduta e l'iPad
//   torna subito alla schermata neutra (mai dati del cliente lasciati sullo schermo).
// Il Mac manda solo cifre già calcolate e minime, e solo del cliente presente: niente identificativi, niente archivio.

/// Le costanti del tavolo e le cornici cifrate.
enum ProtocolloTavolo {
    /// Il servizio Bonjour del Mac (anche in Info.plist: NSBonjourServices).
    static let servizio = "_prisma-tavolo._tcp"
    /// La porta del tavolo (quella di Vera è 47620).
    static let porta: UInt16 = 47_621
    /// La versione dei messaggi: un contenuto che questa versione non conosce si ignora, non chiude il tavolo.
    static let versione = 1
    /// Il sale della chiave del tavolo (il codice è lo stesso del ponte di Vera).
    static let sale = "Prisma · Tavolo · 1"
    /// Il messaggio più grande (un prospetto intero in PNG sta ben sotto).
    static let massimoMessaggio = 24 * 1_024 * 1_024
    /// Il PNG più grande del tratto della presa visione.
    static let massimoTratto = 2 * 1_024 * 1_024
    /// Le pagine al massimo in un solo messaggio (un prospetto lungo si manda a pagine).
    static let massimePagine = 24
    /// Un messaggio più vecchio (o più nuovo) di così non vale, come le buste del ponte di Vera.
    static let tolleranzaOrologio = PonteVera.tolleranzaOrologio
    /// La scritta esatta della presa visione, sull'iPad e nel PDF.
    static let testoPresaVisione = "Presa visione del documento: non costituisce firma contrattuale"

    /// I tempi del battito: le prove li accorciano.
    struct Tempi: Equatable, Sendable {
        /// Ogni quanto si manda il battito.
        var battito: TimeInterval = 2
        /// Dopo quanto silenzio la connessione è caduta.
        var silenzio: TimeInterval = 7
        /// Quanto si aspetta il saluto (sul Mac) o il benvenuto (sull'iPad).
        var abbinamento: TimeInterval = 6

        static let normali = Tempi()
    }

    /// La chiave del tavolo dal codice di abbinamento (lo stesso di Impostazioni › Vera), nil se il codice non vale.
    static func chiave(_ codice: String) -> SymmetricKey? {
        PonteVera.chiave(codice, sale: sale)
    }

    /// Una sessione nuova (la sceglie l'iPad a ogni collegamento).
    static func nuovaSessione() -> String { UUID().uuidString }

    /// La cornice del messaggio: lunghezza su 4 byte e scatola cifrata con le funzioni del ponte di Vera.
    static func cornice(_ m: MessaggioTavolo, chiave k: SymmetricKey) throws -> Data {
        let sigillato = try PonteVera.sigilla(JSONEncoder().encode(m), k)
        var dati = withUnsafeBytes(of: UInt32(sigillato.count).bigEndian) { Data($0) }
        dati.append(sigillato)
        return dati
    }

    /// Il messaggio in chiaro (JSON) da una scatola, nil con un'altra chiave o se è guastato.
    static func apri(_ sigillato: Data, chiave k: SymmetricKey) -> (messaggio: MessaggioTavolo, chiaro: Data)? {
        guard let chiaro = PonteVera.apri(sigillato, k),
              let m = try? JSONDecoder().decode(MessaggioTavolo.self, from: chiaro) else { return nil }
        return (m, chiaro)
    }

    /// Una cifra che si può scrivere in JSON (NaN e infinito diventano 0).
    static func cifra(_ x: Double) -> Double { x.isFinite ? x : 0 }

    static func cifre(_ x: [Double]) -> [Double] { x.map(cifra) }

    // MARK: Immagini (pagine e tratto)

    /// Il PNG di un'immagine (ImageIO: uguale sul Mac e sull'iPad).
    static func png(_ immagine: CGImage) -> Data? {
        let dati = NSMutableData()
        guard let destinazione = CGImageDestinationCreateWithData(dati as CFMutableData, UTType.png.identifier as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(destinazione, immagine, nil)
        guard CGImageDestinationFinalize(destinazione) else { return nil }
        return dati as Data
    }

    /// L'immagine di un PNG (nil se non è un'immagine).
    static func immagine(_ png: Data) -> CGImage? {
        guard !png.isEmpty, let sorgente = CGImageSourceCreateWithData(png as CFData, nil),
              CGImageSourceGetCount(sorgente) > 0 else { return nil }
        return CGImageSourceCreateImageAtIndex(sorgente, 0, nil)
    }
}

// MARK: - I messaggi

/// Un messaggio del tavolo, in chiaro dentro la scatola cifrata.
struct MessaggioTavolo: Codable, Equatable, Sendable {
    var versione: Int
    /// La sessione scelta dall'iPad nel saluto: vale per tutta la connessione.
    var sessione: String
    /// Cresce a ogni messaggio della stessa parte: un messaggio ripetuto non passa.
    var numero: Int
    /// Secondi dal 1970.
    var quando: Double
    /// nil: un contenuto di una versione più nuova, che questa non conosce (si ignora).
    var contenuto: ContenutoTavolo?

    init(sessione: String, numero: Int, contenuto: ContenutoTavolo, quando: Date = Date()) {
        versione = ProtocolloTavolo.versione
        self.sessione = sessione
        self.numero = numero
        self.quando = quando.timeIntervalSince1970
        self.contenuto = contenuto
    }

    enum CodingKeys: String, CodingKey {
        case versione, sessione, numero, quando, contenuto
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        versione = try c.decode(Int.self, forKey: .versione)
        sessione = try c.decode(String.self, forKey: .sessione)
        numero = try c.decode(Int.self, forKey: .numero)
        quando = try c.decode(Double.self, forKey: .quando)
        // Un contenuto sconosciuto (versione più nuova) non rompe il messaggio: resta nil
        contenuto = try? c.decodeIfPresent(ContenutoTavolo.self, forKey: .contenuto)
    }
}

/// Che cosa dice un messaggio. Dal Mac: benvenuto, mostra, cursore, richiesta di presa visione, neutra.
/// Dall'iPad: saluto, valore del cursore, presa visione. Da tutte e due: battito e fine.
enum ContenutoTavolo: Codable, Equatable, Sendable {
    /// iPad → Mac, il primo messaggio: il nome dell'iPad.
    case ciao(SalutoTavolo)
    /// Mac → iPad, la risposta al saluto: il nome del Mac.
    case benvenuto(SalutoTavolo)
    /// Mac → iPad: una pagina, un prospetto, la macchina del tempo o la famiglia del cliente presente.
    case mostra(MostraTavolo)
    /// Mac → iPad: un cursore da muovere (anche di nuovo, con il risultato ricalcolato).
    case cursore(CursoreTavolo)
    /// iPad → Mac: il valore scelto dal cliente.
    case valoreCursore(ValoreCursoreTavolo)
    /// Mac → iPad: la richiesta di presa visione del documento.
    case richiestaPresaVisione(RichiestaPresaVisioneTavolo)
    /// iPad → Mac: la presa visione, con il tratto e la data.
    case presaVisione(PresaVisioneTavolo)
    /// Mac → iPad: la schermata neutra (niente dati).
    case neutra
    /// Il tavolo si chiude (da tutte e due le parti).
    case fine
    /// Ci sono ancora.
    case battito

    /// I contenuti che solo il Mac può mandare.
    var delMac: Bool {
        switch self {
        case .benvenuto, .mostra, .cursore, .richiestaPresaVisione, .neutra, .fine, .battito: return true
        case .ciao, .valoreCursore, .presaVisione: return false
        }
    }

    /// I contenuti che solo l'iPad può mandare.
    var dellIPad: Bool {
        switch self {
        case .ciao, .valoreCursore, .presaVisione, .fine, .battito: return true
        case .benvenuto, .mostra, .cursore, .richiestaPresaVisione, .neutra: return false
        }
    }
}

/// Il nome di chi si collega: «iPad di Denis», «MacBook Pro di Denis».
struct SalutoTavolo: Codable, Equatable, Sendable {
    var nome: String
}

/// Ciò che l'iPad mostra al cliente. Sempre e solo del cliente presente, con il suo nome e niente identificativi.
struct MostraTavolo: Codable, Equatable, Sendable {
    enum Genere: String, Codable, Sendable {
        /// Una pagina della presentazione (un PNG del foglio impaginato dal Mac).
        case pagina
        /// Un prospetto o un report intero (tutte le pagine in PNG).
        case prospetto
        /// La macchina del tempo: il patrimonio tre anni indietro e due avanti, già calcolato.
        case nelTempo
        /// La famiglia: le persone del nucleo con le loro scoperture.
        case famiglia
        /// La linea della vita: il patrimonio da oggi a 90 anni con gli eventi e la pensione (giro 4).
        case lineaVita
    }

    var id: String
    var genere: Genere
    /// «Il check-up», «Il patrimonio nel tempo», «La famiglia».
    var titolo: String
    /// Il nome del cliente presente («Giulia Rossi»).
    var cliente: String
    /// Il canale, quando il contenuto è di un canale solo (le pagine portano già le loro etichette).
    var canale: Canale?
    var pagine: [PaginaTavolo] = []
    var nelTempo: NelTempoTavolo?
    var famiglia: FamigliaTavolo?
    var lineaVita: LineaVitaTavolo?
}

/// Una pagina già impaginata sul Mac: il PNG del foglio (sempre chiaro, su carta bianca).
struct PaginaTavolo: Codable, Equatable, Sendable {
    /// Da 1.
    var numero: Int
    var totale: Int
    /// La misura del foglio in punti (A4: 595×842 o 842×595); il PNG è più fitto.
    var larghezza: Double
    var altezza: Double
    var png: Data
}

/// La macchina del tempo del cliente, già calcolata dal Mac (MotoreNelTempo): il passato mese per mese e la stima.
struct NelTempoTavolo: Codable, Equatable, Sendable {
    /// Da −36 mesi a oggi (37 punti): il patrimonio netto; l'ultimo è oggi.
    var passato: [Double]
    /// Da oggi a +24 mesi (25 punti): la stima centrale e i bordi della fascia (1 caso su 10 sotto e sopra).
    var centrale: [Double]
    var alta: [Double]
    var bassa: [Double]
    /// true se qualcosa oscilla con i mercati (altrimenti la fascia è chiusa sulla linea).
    var esposta: Bool
    /// La stima centrale con le proposte aperte (nil se non ce ne sono).
    var centraleConProposte: [Double]?
    /// I riesami sulla linea del passato: il mese (da −36 a −1) e il patrimonio netto di quel giorno.
    var fotografie: [PuntoFotografiaTavolo]
    var nettoOggi: Double
    /// Le date sotto il grafico, già scritte: «nov 2023», «oggi», «nov 2028».
    var inizio: String
    var oggi: String
    var fine: String
    /// «È una stima, non una previsione…»
    var nota: String
}

struct PuntoFotografiaTavolo: Codable, Equatable, Sendable {
    var mese: Int
    var valore: Double
}

/// La linea della vita del cliente, già calcolata dal Mac (MotoreLineaVita): il patrimonio anno per anno in euro di
/// oggi, la pensione e gli eventi (senza le note interne). L'iPad la mostra ferma: i gettoni si spostano sul Mac.
struct LineaVitaTavolo: Codable, Equatable, Sendable {
    var etaOggi: Int
    var etaPensione: Int
    var etaFine: Int
    /// Da oggi a `etaFine`, un valore per anno (sotto zero il grafico lo mostra sul fondo).
    var valori: [Double]
    var allaPensione: Double
    var massimo: Double
    var etaMassimo: Int
    /// nil = il patrimonio basta oltre `etaFine`.
    var etaEsaurimento: Int?
    /// nil = prelievo non calcolato: dopo la pensione la linea è solo indicativa.
    var prelievoAnnuo: Double?
    var eventi: [EventoLineaVitaTavolo]
    /// «Valori in euro di oggi…»
    var nota: String

    /// L'esito come lo disegna il dossier.
    var esito: EsitoLineaVita {
        EsitoLineaVita(punti: valori.enumerated().map { PuntoLineaVita(eta: etaOggi + $0.offset, valore: $0.element) },
                       etaPensione: etaPensione, etaFine: etaFine, allaPensione: allaPensione, massimo: massimo,
                       etaMassimo: etaMassimo, etaEsaurimento: etaEsaurimento, prelievoAnnuo: prelievoAnnuo)
    }
}

/// Un evento sulla linea della vita mandata all'iPad: il nome, l'età e l'importo (nil = senza cifra).
struct EventoLineaVitaTavolo: Codable, Equatable, Sendable {
    var nome: String
    var eta: Int
    var importo: Double?
}

/// La famiglia del cliente: il titolare e i familiari, con le scoperture (MotoreFamigliaDossier).
struct FamigliaTavolo: Codable, Equatable, Sendable {
    var persone: [PersonaTavolo]
    /// Da dove vengono le capsule.
    var nota: String
}

struct PersonaTavolo: Codable, Equatable, Sendable {
    var nome: String
    var iniziali: String
    var titolare: Bool
    /// «45 anni · titolare del dossier», «Coniuge · 43 anni».
    var descrizione: String
    var scoperture: [ScoperturaTavolo]
}

struct ScoperturaTavolo: Codable, Equatable, Sendable {
    var testo: String
    var tono: TonoTavolo
}

/// Il tono di una capsula: rosso, arancio o verde del tema.
enum TonoTavolo: String, Codable, Sendable {
    case rosso, arancio, verde
}

/// Un cursore lasciato al cliente: titolo, valore e limiti li decide il Mac; il valore torna dal cliente e il Mac
/// ricalcola con i motori di Prisma, poi rimanda il cursore con il risultato.
struct CursoreTavolo: Codable, Equatable, Sendable {
    var id: String
    /// «Versamento mensile».
    var titolo: String
    /// «€ al mese».
    var unita: String
    var valore: Double
    var minimo: Double
    var massimo: Double
    var passo: Double
    /// Di quale posizione si parla («Piano Futuro Sereno») e il suo canale.
    var posizione: String
    var canale: Canale?
    /// nil finché il Mac non ha calcolato; con `risultato.valore != valore` il Mac sta ricalcolando.
    var risultato: RisultatoCursoreTavolo?

    /// Il valore dentro i limiti e sul passo (lo stesso sul Mac e sull'iPad).
    func valido(_ v: Double) -> Double {
        guard v.isFinite, massimo >= minimo else { return minimo }
        let dentro = min(max(v, minimo), massimo)
        guard passo > 0 else { return dentro }
        let gradini = ((dentro - minimo) / passo).rounded()
        return min(massimo, minimo + gradini * passo)
    }
}

/// Il risultato del ricalcolo per un valore del cursore.
struct RisultatoCursoreTavolo: Codable, Equatable, Sendable {
    /// Il valore del cursore con cui è stato calcolato.
    var valore: Double
    /// «Fra 10 anni, al netto di costi e imposte».
    var titolo: String
    /// La cifra principale (euro).
    var cifra: Double
    var righe: [RigaRisultatoTavolo]
    /// «Una stima con il rendimento ipotizzato…»
    var nota: String
}

struct RigaRisultatoTavolo: Codable, Equatable, Sendable {
    var etichetta: String
    /// Euro.
    var cifra: Double
}

/// Il valore scelto dal cliente.
struct ValoreCursoreTavolo: Codable, Equatable, Sendable {
    var id: String
    var valore: Double
}

/// La richiesta di presa visione del documento mostrato al tavolo.
struct RichiestaPresaVisioneTavolo: Codable, Equatable, Sendable {
    var id: String
    /// «Report · Il check-up».
    var titolo: String
    var cliente: String
    var pagine: Int
    /// Sempre `ProtocolloTavolo.testoPresaVisione`.
    var testo: String
}

/// La presa visione: il tratto del cliente (PNG, sfondo trasparente o bianco) e la data.
struct PresaVisioneTavolo: Codable, Equatable, Sendable {
    /// L'id della richiesta.
    var id: String
    var tratto: Data
    /// Secondi dal 1970.
    var data: Double
}

// MARK: - Il canale cifrato (comune al Mac e all'iPad)

/// Una connessione del tavolo: cornici cifrate su TCP, controllo di sessione, numero e ora, battito.
/// Tutto sulla coda data (seriale): anche le chiamate di ritorno (`ricevuto`, `chiusura`) arrivano lì.
final class CanaleTavolo: @unchecked Sendable {
    /// Come è finita la connessione.
    enum Fine: Equatable, Sendable {
        /// L'altra parte ha chiuso il tavolo (o l'abbiamo chiuso noi).
        case chiuso
        /// La connessione si è interrotta o l'altra parte tace da troppo.
        case caduto
        /// Un messaggio che non si apre (codice diverso), di un'altra sessione, ripetuto o troppo grande.
        case rifiutato
        /// Non ci si è mai collegati.
        case irraggiungibile
    }

    let coda: DispatchQueue
    private let connessione: NWConnection
    private let chiave: SymmetricKey
    private let tempi: ProtocolloTavolo.Tempi
    private var sessione: String?
    private var buffer = Data()
    private var uscita = 0
    private var entrata = -1
    private var ultimoArrivo = Date()
    private var pronta = false
    private var finito = false
    /// Le prove: questa parte smette di parlare (niente battito, niente messaggi), come se si fosse bloccata.
    private var muta = false
    private var battito: DispatchSourceTimer?
    private var ricevuto: ((MessaggioTavolo) -> Void)?
    private var chiusura: ((Fine) -> Void)?
    /// Le prove: ogni messaggio aperto, in chiaro (JSON). Da impostare prima di `avvia`.
    var registro: ((Data) -> Void)?

    /// `sessione` nil: la prende dal primo messaggio (il Mac, dal saluto dell'iPad).
    init(_ c: NWConnection, chiave: SymmetricKey, sessione: String?, tempi: ProtocolloTavolo.Tempi, coda: DispatchQueue) {
        connessione = c
        self.chiave = chiave
        self.sessione = sessione
        self.tempi = tempi
        self.coda = coda
    }

    deinit {
        // Mai una connessione lasciata aperta: se nessuno tiene più il canale, si chiude
        battito?.cancel()
        connessione.cancel()
    }

    func avvia(ricevuto: @escaping (MessaggioTavolo) -> Void, chiusura: @escaping (Fine) -> Void) {
        coda.async { [self] in
            self.ricevuto = ricevuto
            self.chiusura = chiusura
            connessione.stateUpdateHandler = { [weak self] s in self?.cambia(s) }
            connessione.start(queue: coda)
            leggi()
        }
    }

    /// Il battito parte dopo l'abbinamento.
    func avviaBattito() {
        coda.async { [self] in
            guard !finito, battito == nil else { return }
            ultimoArrivo = Date()
            let t = DispatchSource.makeTimerSource(queue: coda)
            t.schedule(deadline: .now() + tempi.battito, repeating: tempi.battito)
            t.setEventHandler { [weak self] in self?.pulsa() }
            battito = t
            t.resume()
        }
    }

    func manda(_ c: ContenutoTavolo) {
        coda.async { [self] in invia(c, poi: nil) }
    }

    /// Chiude con garbo: manda «fine» e poi chiude.
    func chiudi() {
        coda.async { [self] in
            guard !finito else { return }
            guard sessione != nil, !muta else { return termina(.chiuso) }
            invia(.fine) { [weak self] in self?.termina(.chiuso) }
        }
    }

    /// Le prove: la connessione si interrompe di colpo, senza «fine» (come un iPad che esce dal Wi‑Fi).
    func interrompi() {
        coda.async { [self] in
            guard !finito else { return }
            connessione.forceCancel()
            termina(.caduto)
        }
    }

    /// Le prove: questa parte tace (né battito né messaggi) finché la connessione non cade.
    func silenzia() {
        coda.async { [self] in muta = true }
    }

    // MARK: Dentro la coda

    private func cambia(_ s: NWConnection.State) {
        switch s {
        case .ready:
            pronta = true
            ultimoArrivo = Date()
        case .waiting:
            // Il Mac non c'è (porta chiusa, rete diversa): si smette subito di riprovare
            if !pronta { termina(.irraggiungibile) }
        case .failed, .cancelled:
            termina(pronta ? .caduto : .irraggiungibile)
        default:
            break
        }
    }

    private func pulsa() {
        guard !finito else { return }
        if Date().timeIntervalSince(ultimoArrivo) > tempi.silenzio { return termina(.caduto) }
        invia(.battito, poi: nil)
    }

    private func invia(_ c: ContenutoTavolo, poi: (() -> Void)?) {
        guard !finito, !muta, let s = sessione else { return }
        uscita += 1
        guard let dati = try? ProtocolloTavolo.cornice(MessaggioTavolo(sessione: s, numero: uscita, contenuto: c), chiave: chiave)
        else { return }
        // Il canale resta vivo finché il messaggio non è partito: «fine» esce e la connessione si chiude davvero
        // anche quando chi lo teneva (l'iPad o il Mac) l'ha già lasciato
        connessione.send(content: dati, completion: .contentProcessed { errore in
            if errore != nil { return self.termina(.caduto) }
            poi?()
        })
    }

    private func leggi() {
        connessione.receive(minimumIncompleteLength: 1, maximumLength: 262_144) { [weak self] dati, _, completo, errore in
            guard let self, !self.finito else { return }
            if let dati, !dati.isEmpty { self.accoda(dati) }
            guard !self.finito else { return }
            // Chiusa senza «fine»: è caduta
            if completo || errore != nil { return self.termina(.caduto) }
            self.leggi()
        }
    }

    private func accoda(_ dati: Data) {
        buffer.append(dati)
        while buffer.count >= 4 {
            let testa = [UInt8](buffer.prefix(4))
            let n = Int(testa[0]) << 24 | Int(testa[1]) << 16 | Int(testa[2]) << 8 | Int(testa[3])
            guard n > 0, n <= ProtocolloTavolo.massimoMessaggio + 4_096 else { return termina(.rifiutato) }
            guard buffer.count >= 4 + n else { return }
            let inizio = buffer.startIndex + 4
            let pezzo = buffer.subdata(in: inizio..<(inizio + n))
            buffer = Data(buffer.dropFirst(4 + n))
            apri(pezzo)
            if finito { return }
        }
    }

    private func apri(_ pezzo: Data) {
        // Un altro codice: la scatola non si apre e la connessione si chiude
        guard let aperto = ProtocolloTavolo.apri(pezzo, chiave: chiave) else { return termina(.rifiutato) }
        let m = aperto.messaggio
        if let s = sessione {
            guard m.sessione == s else { return termina(.rifiutato) }
        } else {
            guard !m.sessione.isEmpty else { return termina(.rifiutato) }
            sessione = m.sessione
        }
        // Niente messaggi ripetuti o vecchi
        guard m.numero > entrata,
              abs(Date().timeIntervalSince1970 - m.quando) <= ProtocolloTavolo.tolleranzaOrologio else { return termina(.rifiutato) }
        entrata = m.numero
        ultimoArrivo = Date()
        registro?(aperto.chiaro)
        guard let c = m.contenuto else { return }
        switch c {
        case .fine: termina(.chiuso)
        case .battito: break
        default: ricevuto?(m)
        }
    }

    private func termina(_ f: Fine) {
        guard !finito else { return }
        finito = true
        battito?.cancel()
        battito = nil
        connessione.stateUpdateHandler = nil
        connessione.cancel()
        buffer = Data()
        let c = chiusura
        chiusura = nil
        ricevuto = nil
        c?(f)
    }
}

// MARK: - Il lato iPad (senza viste)

/// L'iPad al tavolo, senza viste: si collega al Mac, tiene lo schermo da mostrare e rimanda le scelte del cliente.
/// Le viste dell'iPad osservano `OsservatoreTavolo`. Tutto il lavoro di rete sta su una coda propria;
/// `collegamento` e `schermo` si leggono da qualsiasi thread.
///
///     let tavolo = ClienteTavolo(nome: "iPad di Denis")
///     tavolo.cerca(codice: impostazioni.vera.ponte.codice)          // Bonjour, oppure:
///     tavolo.collega(codice: codice, host: "192.168.1.20", porta: ProtocolloTavolo.porta)
///     tavolo.mandaValore(350, cursore: cursore.id)
///     tavolo.mandaPresaVisione(richiesta: richiesta.id, tratto: png)
///     tavolo.chiudi()
final class ClienteTavolo: @unchecked Sendable {
    enum Collegamento: Equatable, Sendable {
        case scollegato
        /// Cerca il Mac con Bonjour.
        case cerca
        /// Collegato in rete, aspetta il benvenuto del Mac.
        case abbinamento
        case collegato(mac: String)
        /// Il Mac ha chiuso subito: il codice è diverso.
        case rifiutato
        /// La connessione è caduta (rete, Mac addormentato, Prisma chiusa).
        case caduto
        /// Il Mac non si trova.
        case irraggiungibile
    }

    /// Che cosa c'è sullo schermo del cliente.
    enum Schermo: Equatable, Sendable {
        /// Nessun dato: il logo e basta.
        case neutra
        case mostra(MostraTavolo)
        case cursore(CursoreTavolo)
        case presaVisione(RichiestaPresaVisioneTavolo)
    }

    let nome: String
    private let tempi: ProtocolloTavolo.Tempi
    private let coda = DispatchQueue(label: "prisma.tavolo.ipad")
    private let blocco = NSLock()
    private var _collegamento: Collegamento = .scollegato
    private var _schermo: Schermo = .neutra
    private var _registro: [Data] = []
    private var canale: CanaleTavolo?
    private var ricerca: NWBrowser?
    private var generazione = 0
    private var scaduto = false
    /// Le prove: tiene ogni messaggio ricevuto, in chiaro. Da impostare prima di collegarsi.
    var registra = false
    /// Chiamata a ogni cambiamento, sulla coda del tavolo (l'interfaccia passa al thread principale).
    var aggiornato: ((Collegamento, Schermo) -> Void)?

    init(nome: String, tempi: ProtocolloTavolo.Tempi = .normali) {
        self.nome = nome
        self.tempi = tempi
    }

    var collegamento: Collegamento {
        blocco.lock(); defer { blocco.unlock() }
        return _collegamento
    }

    var schermo: Schermo {
        blocco.lock(); defer { blocco.unlock() }
        return _schermo
    }

    /// Le prove: i messaggi ricevuti dal Mac, in chiaro (JSON).
    var registro: [Data] {
        blocco.lock(); defer { blocco.unlock() }
        return _registro
    }

    var collegato: Bool {
        if case .collegato = collegamento { return true }
        return false
    }

    /// Si collega al Mac a un indirizzo noto (le prove usano 127.0.0.1).
    func collega(codice: String, host: String, porta: UInt16) {
        guard let p = NWEndpoint.Port(rawValue: porta) else { return }
        collega(codice: codice, a: .hostPort(host: NWEndpoint.Host(host), port: p))
    }

    /// Si collega a un servizio trovato (per esempio da una ricerca Bonjour fatta altrove).
    func collega(codice: String, a punto: NWEndpoint) {
        coda.async { [self] in
            guard let k = ProtocolloTavolo.chiave(codice) else { return imposta(.rifiutato, .neutra) }
            apri(punto, chiave: k)
        }
    }

    /// Cerca il Mac con Bonjour («_prisma-tavolo._tcp») e si collega al primo che risponde.
    func cerca(codice: String) {
        coda.async { [self] in
            guard let k = ProtocolloTavolo.chiave(codice) else { return imposta(.rifiutato, .neutra) }
            ferma()
            generazione += 1
            let g = generazione
            let parametri = NWParameters.tcp
            parametri.includePeerToPeer = false
            let b = NWBrowser(for: .bonjour(type: ProtocolloTavolo.servizio, domain: nil), using: parametri)
            ricerca = b
            b.browseResultsChangedHandler = { [weak self] risultati, _ in
                guard let self, self.generazione == g, case .cerca = self._collegamento,
                      let primo = risultati.first else { return }
                self.ricerca?.cancel()
                self.ricerca = nil
                self.apri(primo.endpoint, chiave: k)
            }
            b.stateUpdateHandler = { [weak self] s in
                guard let self, self.generazione == g else { return }
                if case .failed = s { self.imposta(.irraggiungibile, .neutra) }
            }
            imposta(.cerca, .neutra)
            b.start(queue: coda)
            coda.asyncAfter(deadline: .now() + tempi.abbinamento) { [weak self] in
                guard let self, self.generazione == g, case .cerca = self._collegamento else { return }
                self.ricerca?.cancel()
                self.ricerca = nil
                self.imposta(.irraggiungibile, .neutra)
            }
        }
    }

    /// Il cliente ha mosso il cursore: il valore (nei limiti) va al Mac, che ricalcola e rimanda il risultato.
    func mandaValore(_ valore: Double, cursore id: String) {
        coda.async { [self] in
            guard case .collegato = _collegamento, case .cursore(var x) = _schermo, x.id == id else { return }
            x.valore = x.valido(valore)
            imposta(_collegamento, .cursore(x))
            canale?.manda(.valoreCursore(ValoreCursoreTavolo(id: id, valore: x.valore)))
        }
    }

    /// Il cliente ha preso visione: il tratto (PNG) e la data vanno al Mac, che li mette nel PDF.
    func mandaPresaVisione(richiesta id: String, tratto: Data, data: Date = Date()) {
        coda.async { [self] in
            guard case .collegato = _collegamento, case .presaVisione(let r) = _schermo, r.id == id,
                  !tratto.isEmpty, tratto.count <= ProtocolloTavolo.massimoTratto else { return }
            canale?.manda(.presaVisione(PresaVisioneTavolo(id: id, tratto: tratto, data: data.timeIntervalSince1970)))
        }
    }

    /// Chiude il tavolo da questa parte: «fine» al Mac e schermata neutra.
    func chiudi() {
        coda.async { [self] in
            ferma()
            imposta(.scollegato, .neutra)
        }
    }

    /// Le prove: la connessione cade di colpo, senza «fine».
    func interrompiPerProva() {
        coda.async { [self] in canale?.interrompi() }
    }

    // MARK: Dentro la coda

    private func ferma() {
        generazione += 1
        ricerca?.cancel()
        ricerca = nil
        canale?.chiudi()
        canale = nil
    }

    private func apri(_ punto: NWEndpoint, chiave k: SymmetricKey) {
        ferma()
        let g = generazione
        scaduto = false
        let parametri = NWParameters.tcp
        parametri.includePeerToPeer = false
        let c = CanaleTavolo(NWConnection(to: punto, using: parametri), chiave: k,
                             sessione: ProtocolloTavolo.nuovaSessione(), tempi: tempi, coda: coda)
        if registra { c.registro = { [weak self] d in self?.annota(d) } }
        canale = c
        imposta(.abbinamento, .neutra)
        c.avvia(ricevuto: { [weak self] m in self?.ricevi(m, g) },
                chiusura: { [weak self] f in self?.finito(f, g) })
        c.manda(.ciao(SalutoTavolo(nome: nome)))
        coda.asyncAfter(deadline: .now() + tempi.abbinamento) { [weak self] in
            guard let self, self.generazione == g, case .abbinamento = self._collegamento else { return }
            self.scaduto = true
            self.canale?.interrompi()
        }
    }

    private func ricevi(_ m: MessaggioTavolo, _ g: Int) {
        guard g == generazione, let c = m.contenuto, c.delMac else { return }
        if case .benvenuto(let s) = c {
            guard case .abbinamento = _collegamento else { return }
            canale?.avviaBattito()
            return imposta(.collegato(mac: s.nome), .neutra)
        }
        // Prima del benvenuto non si mostra niente
        guard case .collegato = _collegamento else { return }
        switch c {
        case .mostra(let x): imposta(_collegamento, .mostra(x))
        case .cursore(let x): imposta(_collegamento, .cursore(x))
        case .richiestaPresaVisione(let r): imposta(_collegamento, .presaVisione(r))
        case .neutra: imposta(_collegamento, .neutra)
        default: break
        }
    }

    private func finito(_ f: CanaleTavolo.Fine, _ g: Int) {
        guard g == generazione else { return }
        canale = nil
        let nuovo: Collegamento
        switch _collegamento {
        case .abbinamento:
            // Il Mac chiude prima del benvenuto: il codice non è lo stesso
            nuovo = (f == .irraggiungibile || scaduto) ? .irraggiungibile : .rifiutato
        case .collegato:
            nuovo = f == .chiuso ? .scollegato : .caduto
        default:
            nuovo = _collegamento
        }
        // Qualunque cosa succeda, sullo schermo del cliente non resta niente
        imposta(nuovo, .neutra)
    }

    private func annota(_ d: Data) {
        blocco.lock()
        _registro.append(d)
        blocco.unlock()
    }

    private func imposta(_ c: Collegamento, _ s: Schermo) {
        blocco.lock()
        _collegamento = c
        _schermo = s
        blocco.unlock()
        aggiornato?(c, s)
    }
}

/// Le viste dell'iPad osservano il tavolo da qui, sul thread principale.
///
///     @StateObject private var tavolo = OsservatoreTavolo(ClienteTavolo(nome: "iPad"))
///     switch tavolo.schermo { case .neutra: … case .mostra(let m): … }
@MainActor
final class OsservatoreTavolo: ObservableObject {
    @Published private(set) var collegamento: ClienteTavolo.Collegamento = .scollegato
    @Published private(set) var schermo: ClienteTavolo.Schermo = .neutra
    let cliente: ClienteTavolo
    /// Gli aggiornamenti arrivano in ordine: uno più vecchio dell'ultimo applicato non conta.
    private var ultimo = 0

    init(_ cliente: ClienteTavolo) {
        self.cliente = cliente
        collegamento = cliente.collegamento
        schermo = cliente.schermo
        let contatore = ContatoreTavolo()
        // @Sendable: la chiamata arriva dalla coda del tavolo, non dal thread principale
        cliente.aggiornato = { @Sendable [weak self] c, s in
            let n = contatore.prossimo()
            guard let osservatore = self else { return }
            Task { @MainActor in osservatore.applica(n, c, s) }
        }
    }

    private func applica(_ n: Int, _ c: ClienteTavolo.Collegamento, _ s: ClienteTavolo.Schermo) {
        guard n > ultimo else { return }
        ultimo = n
        if collegamento != c { collegamento = c }
        if schermo != s { schermo = s }
    }
}

/// Un contatore da qualsiasi thread (gli aggiornamenti del tavolo arrivano dalla sua coda).
private final class ContatoreTavolo: @unchecked Sendable {
    private let blocco = NSLock()
    private var n = 0

    func prossimo() -> Int {
        blocco.lock(); defer { blocco.unlock() }
        n += 1
        return n
    }
}
