import Foundation

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
final class CacheClienti {
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

        init(chiave: Chiave) { self.chiave = chiave }
    }

    /// Il posto di un cliente sul radar: una voce, «senza modello» o fuori (niente da considerare o composizione vuota).
    enum EsitoRadar: Equatable {
        case voce(VoceRadar)
        case senzaModello
        case fuori
    }

    private(set) var voci: [String: Voce] = [:]
    /// Quante volte la voce di un cliente è stata rifatta da zero (le prove: «rifatto solo lui»).
    private(set) var rifatte: [String: Int] = [:]

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
    /// (lo stesso di `MotoreRadar.calcola`, che resta il calcolo da zero delle prove e di Vera).
    func radarDaiClienti() -> RadarPortafoglio {
        let modelli = dati.portafogliModello
        let perId = Dictionary(modelli.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let tolleranza = dati.impostazioni.tolleranzaRadar
        var prodotti: [String: Prodotto]?
        var voci: [VoceRadar] = []
        var senza: [String] = []
        for c in dati.clienti {
            let v = voceCliente(c.id)
            let esito: CacheClienti.EsitoRadar
            if let e = v.radar {
                esito = e
            } else {
                let mie = posizioniCliente(c.id)
                let sue = MotoreRadar.considerate(mie)
                if sue.isEmpty {
                    esito = .fuori
                } else if let id = c.modelloId, let m = perId[id] {
                    let bozza = mie.contains { $0.riequilibrio != nil && $0.stato == .proposta && ($0.esito ?? .bozza) == .bozza }
                    if prodotti == nil { prodotti = Dictionary(dati.prodotti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }) }
                    esito = MotoreRadar.voce(cliente: c, modello: m, posizioni: sue, prodotti: prodotti ?? [:],
                                             tolleranzaGenerale: tolleranza, bozzaPronta: bozza).map { .voce($0) } ?? .fuori
                } else {
                    esito = .senzaModello
                }
                v.radar = esito
            }
            switch esito {
            case .voce(let x): voci.append(x)
            case .senzaModello: senza.append(c.id)
            case .fuori: break
            }
        }
        return RadarPortafoglio(modelli: modelli, voci: voci, senzaModello: senza, tolleranzaGenerale: tolleranza)
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
