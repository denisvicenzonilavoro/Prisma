import Foundation
import Observation

// Proprietario: G3 (calcoli nei body). Giro 0 di «Prisma istantaneo», tappa 4 (Design/velocita-proposta.md, «I motori
// in cache»).

/// I motori dei singoli clienti, tenuti da parte **per cliente**: cambiando una posizione di Giulia si rifà solo Giulia.
///
/// Fino alla tappa 3 queste voci stavano in `DerivatiDati` e si azzeravano tutte a ogni cambio di `versioneCalcoli`:
/// con 200 clienti un tasto nella scheda di uno rifaceva i motori di tutti. Ora ogni cliente ha la sua voce, con una
/// chiave fatta da:
/// - `comune`: cresce con ciò che vale per tutti (catalogo dei prodotti, portafogli modello, mercato, famiglie, le
///   impostazioni dei calcoli, un archivio sostituito, i campi che non si attribuiscono a un cliente);
/// - `cliente`: cresce quando cambia qualcosa di quel cliente (la sua scheda, le sue posizioni, obiettivi, documenti,
///   Analisi 360, appuntamenti, incontri, attività…: `DatiVivi` lo calcola campo per campo, `StatoShell.datiCambiati`
///   lo segna);
/// - il giorno e la modalità cliente, come `DerivatiDati`.
///
/// Regola per chi aggiunge un motore qui: deve leggere **solo** i dati di quel cliente e i dati comuni sopra (mai le
/// posizioni o la scheda di un altro cliente), se no la sua voce resterebbe vecchia. Le prove stanno in
/// `--prova-calcoli` (ProvaCalcoliCacheClienti): cambio di un cliente = rifatto solo lui, uguale al calcolo da zero;
/// cambio delle impostazioni dei calcoli = rifatti tutti. Si usa solo dal thread principale.
///
/// Il radar, quando molti clienti sono da rifare insieme (catalogo, modelli o impostazioni cambiati, un ripristino),
/// si calcola fuori dal thread principale: la vista mostra intanto l'ultimo radar valido e poi quello nuovo
/// (`arrivi`, l'unica proprietà osservata).
@Observable final class CacheClienti {
    struct Chiave: Equatable {
        let comune: Int
        let cliente: Int
        let giorno: Date
        let modo: String?
    }

    /// Le cifre di un cliente; una classe, così i getter scrivono nella voce senza copiarla.
    final class Voce {
        let chiave: Chiave
        var riepilogo: RiepilogoPosizioni?
        var dossier: AnalisiDossier?
        var coerenza: EsitoCoerenza?
        var fisco: FiscoPolizzeCliente?
        /// `.some(nil)` = calcolato, cliente non visibile.
        var conformita: EsitoConformita??
        var completezza: CompletezzaCliente??
        var bisogni: [BisognoRilevato]?
        var analisiBozza: Analisi360?
        var andamento: AndamentoPortafoglio?
        var aree360: (ora: Int, valore: AreeAnalisi360)?
        var attenzioni: [Attenzione]?
        var radar: EsitoRadar?
        /// Gli obiettivi del cliente in ordine (priorità, scadenza) e il loro avanzamento per id.
        var obiettivi: [Obiettivo]?
        var avanzamenti: [String: AvanzamentoObiettivo]?

        init(chiave: Chiave) { self.chiave = chiave }
    }

    /// Il posto di un cliente sul radar: una voce, «senza modello» o fuori (niente da considerare o composizione vuota).
    enum EsitoRadar: Equatable {
        case voce(VoceRadar)
        case senzaModello
        case fuori
    }

    @ObservationIgnored private(set) var voci: [String: Voce] = [:]
    /// Quante volte la voce di un cliente è stata rifatta da zero (le prove: «rifatto solo lui»).
    @ObservationIgnored private(set) var rifatte: [String: Int] = [:]
    /// Cresce quando arrivano le voci del radar calcolate fuori dal thread principale: la vista del radar la legge e si
    /// ridisegna con il radar nuovo.
    private(set) var arrivi = 0
    /// L'ultimo radar mostrato: le voci da rifare in sottofondo restano intanto quelle di prima.
    @ObservationIgnored var ultimoRadar: RadarPortafoglio?
    /// Il calcolo del radar in sottofondo (nil = nessuno). Uno solo alla volta: quello nuovo annulla il vecchio.
    @ObservationIgnored var radarInCorso: Task<Void, Never>?
    /// Per le prove: il sottofondo anche con lo stato non persistente (di base solo nell'app vera).
    @ObservationIgnored var sottofondoPerProva = false
    /// Da quanti clienti da rifare insieme il radar va in sottofondo.
    static let sogliaSottofondo = 24

    /// Le voci del radar arrivate dal sottofondo: si scrivono solo nelle voci ancora valide (stessa chiave), poi la
    /// vista si ridisegna.
    func arrivate(_ esiti: [(voce: Voce, esito: EsitoRadar)]) {
        for (v, e) in esiti where v.radar == nil { v.radar = e }
        arrivi &+= 1
    }

    /// La voce del cliente valida per la chiave (nuova se la chiave è cambiata).
    func voce(_ id: String, chiave: Chiave) -> Voce {
        if let v = voci[id], v.chiave == chiave { return v }
        let v = Voce(chiave: chiave)
        voci[id] = v
        rifatte[id, default: 0] += 1
        return v
    }

    /// Toglie le voci dei clienti che non ci sono più (un cliente eliminato non resta in memoria).
    func tieniSolo(_ ids: Set<String>) {
        guard voci.count > ids.count else { return }
        voci = voci.filter { ids.contains($0.key) }
    }

    /// Per le prove: dimentica anche i conteggi.
    func azzeraConteggi() { rifatte = [:] }
}

extension StatoShell {
    /// La voce in cache del cliente, per lo stato di adesso. Passa da `derivatiValidi()`: chi la chiede da un body si
    /// iscrive come prima a `versioneCalcoli`, all'ora e al giorno, e la chiave ha il giorno già verificato.
    func voceCliente(_ id: String) -> CacheClienti.Voce {
        let d = derivatiValidi()
        let k = CacheClienti.Chiave(comune: versioneComuneClienti, cliente: versioneCliente(id),
                                    giorno: d.inizioGiorno, modo: modoCliente)
        return cacheClienti.voce(id, chiave: k)
    }

    /// Il radar dalle voci dei clienti: ognuno dalla sua cache, il quadro rimesso insieme nell'ordine dei clienti
    /// (lo stesso di `MotoreRadar.calcola`, che resta il calcolo da zero delle prove e di Vera). `completo` è false se
    /// alcune voci si stanno calcolando in sottofondo (al loro posto quelle dell'ultimo radar): allora non va in cache.
    func radarDaiClienti(sottofondo: Bool = false) -> (radar: RadarPortafoglio, completo: Bool) {
        let modelli = dati.portafogliModello
        let perId = Dictionary(modelli.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let tolleranza = dati.impostazioni.tolleranzaRadar
        let elenco = dati.clienti.map { ($0, voceCliente($0.id)) }
        let mancanti = elenco.filter { $0.1.radar == nil }
        let cache = cacheClienti
        // Molti clienti da rifare e un radar da mostrare intanto: si calcolano fuori dal thread principale
        if sottofondo, mancanti.count >= CacheClienti.sogliaSottofondo, let ultimo = cache.ultimoRadar {
            avviaRadarInSottofondo(mancanti, modelli: perId, tolleranza: tolleranza)
            let vecchie = Dictionary(ultimo.voci.map { ($0.clienteId, $0) }, uniquingKeysWith: { a, _ in a })
            let senzaPrima = Set(ultimo.senzaModello)
            var voci: [VoceRadar] = []
            var senza: [String] = []
            for (c, v) in elenco {
                if let e = v.radar {
                    switch e {
                    case .voce(let x): voci.append(x)
                    case .senzaModello: senza.append(c.id)
                    case .fuori: break
                    }
                } else if let x = vecchie[c.id] {
                    voci.append(x)
                } else if senzaPrima.contains(c.id) {
                    senza.append(c.id)
                }
            }
            return (RadarPortafoglio(modelli: modelli, voci: voci, senzaModello: senza, tolleranzaGenerale: tolleranza), false)
        }
        var prodotti: [String: Prodotto]?
        var voci: [VoceRadar] = []
        var senza: [String] = []
        for (c, v) in elenco {
            let esito: CacheClienti.EsitoRadar
            if let e = v.radar {
                esito = e
            } else {
                if prodotti == nil { prodotti = Dictionary(dati.prodotti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }) }
                esito = Self.esitoRadar(c, posizioni: posizioniCliente(c.id), modelli: perId, prodotti: prodotti ?? [:],
                                        tolleranza: tolleranza)
                v.radar = esito
            }
            switch esito {
            case .voce(let x): voci.append(x)
            case .senzaModello: senza.append(c.id)
            case .fuori: break
            }
        }
        return (RadarPortafoglio(modelli: modelli, voci: voci, senzaModello: senza, tolleranzaGenerale: tolleranza), true)
    }

    /// Il posto di un cliente sul radar, come in `MotoreRadar.calcola` (senza stato: si può chiamare in sottofondo).
    nonisolated static func esitoRadar(_ c: Cliente, posizioni mie: [Posizione], modelli: [String: PortafoglioModello],
                                       prodotti: [String: Prodotto], tolleranza: Double?) -> CacheClienti.EsitoRadar {
        let sue = MotoreRadar.considerate(mie)
        guard !sue.isEmpty else { return .fuori }
        guard let id = c.modelloId, let m = modelli[id] else { return .senzaModello }
        let bozza = mie.contains { $0.riequilibrio != nil && $0.stato == .proposta && ($0.esito ?? .bozza) == .bozza }
        return MotoreRadar.voce(cliente: c, modello: m, posizioni: sue, prodotti: prodotti,
                                tolleranzaGenerale: tolleranza, bozzaPronta: bozza).map { .voce($0) } ?? .fuori
    }

    /// Le voci mancanti del radar, fuori dal thread principale (annulla il calcolo di prima). Al ritorno si scrivono
    /// solo nelle voci ancora valide: se nel frattempo un cliente è cambiato, la sua voce nuova si rifà alla richiesta.
    private func avviaRadarInSottofondo(_ mancanti: [(Cliente, CacheClienti.Voce)], modelli: [String: PortafoglioModello],
                                        tolleranza: Double?) {
        let cache = cacheClienti
        cache.radarInCorso?.cancel()
        let lavori = mancanti.map { (cliente: $0.0, posizioni: posizioniCliente($0.0.id), voce: $0.1) }
        let ingressi = lavori.map { ($0.cliente, $0.posizioni) }
        let prodotti = Dictionary(dati.prodotti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let voci = lavori.map(\.voce)
        cache.radarInCorso = Task { @MainActor [weak cache] in
            let calcolo = Task.detached(priority: .userInitiated) { () -> [CacheClienti.EsitoRadar]? in
                var esiti: [CacheClienti.EsitoRadar] = []
                for (c, p) in ingressi {
                    if Task.isCancelled { return nil }
                    esiti.append(StatoShell.esitoRadar(c, posizioni: p, modelli: modelli, prodotti: prodotti, tolleranza: tolleranza))
                }
                return esiti
            }
            let esiti = await withTaskCancellationHandler { await calcolo.value } onCancel: { calcolo.cancel() }
            guard let cache, !Task.isCancelled, let esiti else { return }
            cache.radarInCorso = nil
            cache.arrivate(Array(zip(voci, esiti)).map { (voce: $0.0, esito: $0.1) })
        }
    }

    /// L'avanzamento degli obiettivi di un cliente, per id dell'obiettivo (dalla sua cache: si rifà solo quando
    /// cambiano i suoi obiettivi o le sue posizioni, o il giorno).
    func avanzamentiObiettivi(_ id: String) -> [String: AvanzamentoObiettivo] {
        let v = voceCliente(id)
        if let a = v.avanzamenti { return a }
        let mie = posizioniCliente(id)
        var a: [String: AvanzamentoObiettivo] = [:]
        for o in obiettiviCliente(id) { a[o.id] = AvanzamentoObiettivo(o, posizioni: mie) }
        v.avanzamenti = a
        return a
    }

    /// L'avanzamento di un obiettivo dalla cache del suo cliente (calcolato al momento se l'obiettivo non è salvato).
    func avanzamento(_ o: Obiettivo) -> AvanzamentoObiettivo {
        if let a = avanzamentiObiettivi(o.clienteId)[o.id],
           obiettiviCliente(o.clienteId).first(where: { $0.id == o.id }) == o {
            return a
        }
        return AvanzamentoObiettivo(o, posizioni: posizioniCliente(o.clienteId))
    }

    /// Le cose da sistemare nei dossier di tutti i clienti visibili: ognuno dalla sua cache, poi lo stesso ordine di
    /// `MotoreAttenzioni.calcola`.
    func attenzioniDaiClienti() -> [Attenzione] {
        clienti.flatMap { c -> [Attenzione] in
            let v = voceCliente(c.id)
            if let a = v.attenzioni { return a }
            let a = MotoreAttenzioni.calcola(cliente: c, posizioni: posizioniCliente(c.id))
            v.attenzioni = a
            return a
        }
        .sorted { ($0.tipo.rawValue, $0.cliente.nome) < ($1.tipo.rawValue, $1.cliente.nome) }
    }
}
