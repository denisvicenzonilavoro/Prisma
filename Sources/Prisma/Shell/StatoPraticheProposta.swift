import Foundation
import Observation
import SwiftUI

/// Lo stato della scheda Proposta di Pratiche («Luce» giro 3, Design/template-luce-specifica.md §7.1): il bisogno
/// scelto, la sequenza che accende le cinque tappe, le scelte di prodotto e le proposte costruite nella sessione.
/// Un oggetto a parte, come lo smontaggio: la sequenza non pubblica StatoShell. Non si salva (la bozza costruita sì,
/// in Posizioni, con la sua scheda di adeguatezza).
@Observable final class StatoPraticheProposta {
    /// Il bisogno scelto nella barra laterale (nil = il primo).
    var scelto: String?
    /// Le tappe accese per il bisogno `accesiDi` (0…5) e il riquadro finale; per gli altri bisogni valgono quelle
    /// calcolate (spente, o tutte accese se la proposta è già costruita).
    fileprivate(set) var accesi = 0
    fileprivate(set) var pronta = false
    fileprivate(set) var accesiDi: String?
    /// La sequenza di accensione è in corso («Costruisco…»).
    fileprivate(set) var inCorso = false
    /// Il prodotto scelto dal consulente fra più prodotti adatti, per bisogno.
    var sceltaProdotto: [String: String] = [:]
    /// Le proposte costruite nella sessione: bisogno → posizione.
    fileprivate(set) var costruite: [String: String] = [:]
    /// L'ultimo prodotto usato per area e rischio (va in testa alla scelta), finché Prisma è aperta.
    fileprivate(set) var ultimoProdotto: [String: String] = [:]

    @ObservationIgnored fileprivate var sequenza: Task<Void, Never>?
    @ObservationIgnored fileprivate var cacheBisogni: (versione: Int, valore: [BisognoScoperto])?
    @ObservationIgnored fileprivate var cacheCostruite: (versione: Int, valore: [String: PropostaCostruita]) = (-1, [:])

    /// Ferma la sequenza in corso (cambio di bisogno o di scheda).
    func fermaSequenza() {
        sequenza?.cancel()
        sequenza = nil
        inCorso = false
    }

    /// Torna allo stato calcolato per tutti i bisogni (le tappe come le dicono i dati).
    func azzera() {
        fermaSequenza()
        accesiDi = nil
        accesi = 0
        pronta = false
    }

    fileprivate func imposta(_ bisogno: String, accesi: Int, pronta: Bool) {
        accesiDi = bisogno
        self.accesi = accesi
        self.pronta = pronta
    }

    fileprivate func ricorda(bisogno: String, posizione: String, chiaveProdotto: String, prodotto: String?) {
        costruite[bisogno] = posizione
        if let prodotto { ultimoProdotto[chiaveProdotto] = prodotto }
    }

    static func chiaveProdotto(_ b: BisognoScoperto) -> String {
        b.area.rawValue + (b.rischio.map { "·" + $0.rawValue } ?? "")
    }
}

/// Quello che la colonna mostra per il bisogno scelto: le tappe accese, il riquadro finale, la bozza.
struct VistaProposta {
    let bisogno: BisognoScoperto
    /// nil = la proposta non è ancora stata costruita (tappe spente).
    let costruita: PropostaCostruita?
    let accesi: Int
    let pronta: Bool
    let inCorso: Bool
    /// La bozza salvata in Posizioni (dopo «Costruisci», o ritrovata).
    let bozza: Posizione?
}

extension StatoShell {
    // MARK: - Bisogni

    /// Le bozze aperte di un cliente (proposte con esito bozza).
    func bozzeAperteProposta(_ clienteId: String) -> [Posizione] {
        posizioniCliente(clienteId).filter { $0.stato == .proposta && $0.esito == .bozza }
    }

    /// Ciò che serve al motore della proposta, per un cliente: le sue posizioni SENZA le bozze aperte (il bisogno già
    /// costruito resta visibile), l'analisi, gli obiettivi e il catalogo. Più leggera di `fonteVera`.
    func fonteProposta(_ clienteId: String, oggi: Date = Date()) -> FonteVera? {
        guard let c = cliente(clienteId) else { return nil }
        let posizioni = posizioniCliente(clienteId).filter { !($0.stato == .proposta && $0.esito == .bozza) }
        return FonteVera(oggi: oggi, nomeUtente: nomeUtente, cliente: c, posizioni: posizioni, appuntamenti: [],
                         attivita: [], analisi: analisi360(clienteId), analisiSalvata: analisiSalvata(clienteId),
                         simulazioni: [], obiettivi: obiettiviCliente(clienteId), prodotti: dati.prodotti)
    }

    /// I bisogni scoperti dall'analisi di tutti i clienti: prima il più urgente di ognuno, poi il secondo, e così via
    /// (nell'ordine della rubrica). Ricalcolati solo quando cambiano i dati.
    func bisogniProposta() -> [BisognoScoperto] {
        let p = praticheProposta
        if let c = p.cacheBisogni, c.versione == versioneDati { return c.valore }
        let oggi = Date()
        var perCliente: [[BisognoScoperto]] = []
        for c in dati.clienti {
            guard let fonte = fonteProposta(c.id, oggi: oggi) else { continue }
            let elenco = MotoreProposta.bisogni(fonte: fonte, bozze: bozzeAperteProposta(c.id)).map { b -> BisognoScoperto in
                // La proposta costruita in questa sessione, se il motore non la ritrova da solo
                guard b.propostaId == nil, let id = p.costruite[b.id], dati.posizioni.contains(where: { $0.id == id }) else { return b }
                return BisognoScoperto(id: b.id, clienteId: b.clienteId, origine: b.origine, titolo: b.titolo, motivo: b.motivo,
                                       area: b.area, rischio: b.rischio, capitale: b.capitale,
                                       versamentoMensile: b.versamentoMensile, importo: b.importo, obiettivoId: b.obiettivoId,
                                       bisognoRilevatoId: b.bisognoRilevatoId, areaBisogno: b.areaBisogno,
                                       confermato: b.confermato, daConfermare: b.daConfermare, propostaId: id)
            }
            if !elenco.isEmpty { perCliente.append(elenco) }
        }
        var tutti: [BisognoScoperto] = []
        var rango = 0
        while true {
            let giro = perCliente.compactMap { rango < $0.count ? $0[rango] : nil }
            if giro.isEmpty { break }
            tutti += giro
            rango += 1
        }
        p.cacheBisogni = (versioneDati, tutti)
        return tutti
    }

    /// La proposta costruita per un bisogno (con la scelta di prodotto della sessione), tenuta da parte finché i dati
    /// non cambiano: il prospetto si impagina una volta sola.
    func propostaCostruita(_ b: BisognoScoperto) -> PropostaCostruita? {
        let p = praticheProposta
        if p.cacheCostruite.versione != versioneDati { p.cacheCostruite = (versioneDati, [:]) }
        let chiave = b.id + "|" + (p.sceltaProdotto[b.id] ?? "")
        if let r = p.cacheCostruite.valore[chiave] { return r }
        guard let fonte = fonteProposta(b.clienteId) else { return nil }
        let bozza = b.propostaId.flatMap { id in dati.posizioni.first { $0.id == id } }
        let r = MotoreProposta.costruisci(b, fonte: fonte, dati: dati.istantanea, bozzaEsistente: bozza,
                                          prodottoScelto: p.sceltaProdotto[b.id],
                                          ultimo: p.ultimoProdotto[StatoPraticheProposta.chiaveProdotto(b)],
                                          contaPagine: { ImpaginatoreProspetto.pagine($0).count })
        p.cacheCostruite.valore[chiave] = r
        return r
    }

    /// Il bisogno mostrato nella colonna: quello scelto, o il primo.
    func bisognoSceltoProposta(_ elenco: [BisognoScoperto]) -> BisognoScoperto? {
        elenco.first { $0.id == praticheProposta.scelto } ?? elenco.first
    }

    /// Cosa mostra la colonna per un bisogno: la sequenza in corso, o lo stato calcolato (già costruita con la bozza
    /// collegata: tutte le tappe accese, senza animazione).
    func vistaProposta(_ b: BisognoScoperto) -> VistaProposta {
        let p = praticheProposta
        let bozza = b.propostaId.flatMap { id in dati.posizioni.first { $0.id == id } }
        let giaCostruita = bozza?.prodottoId != nil
        if p.accesiDi == b.id {
            return VistaProposta(bisogno: b, costruita: propostaCostruita(b), accesi: p.accesi, pronta: p.pronta,
                                 inCorso: p.inCorso, bozza: bozza)
        }
        guard giaCostruita, let r = propostaCostruita(b) else {
            return VistaProposta(bisogno: b, costruita: nil, accesi: 0, pronta: false, inCorso: false, bozza: bozza)
        }
        return VistaProposta(bisogno: b, costruita: r, accesi: r.raggiunti, pronta: r.pronta, inCorso: false, bozza: bozza)
    }

    // MARK: - Azioni

    /// Clic su un bisogno della barra laterale: la colonna torna allo stato calcolato del bisogno.
    func scegliBisognoProposta(_ id: String) {
        guard praticheProposta.scelto != id else { return }
        praticheProposta.azzera()
        praticheProposta.scelto = id
    }

    /// «✦ Costruisci la proposta»: calcola tutto, salva la bozza (se prodotto e importo ci sono) con la scheda di
    /// adeguatezza collegata al bisogno, mostra dove trovarla e accende le tappe una alla volta (subito se `animato` è
    /// falso: «Riduci movimento», istantanee).
    func costruisciProposta(_ b: BisognoScoperto, animato: Bool, da inizio: Int = 0) {
        let p = praticheProposta
        p.fermaSequenza()
        guard let r = propostaCostruita(b) else { return }
        if let bozza = salvaBozzaProposta(r) {
            // Ora la bozza c'è: la colonna la ritrova anche dopo il ricalcolo dei bisogni
            let ricostruita = propostaCostruita(BisognoScoperto(
                id: b.id, clienteId: b.clienteId, origine: b.origine, titolo: b.titolo, motivo: b.motivo, area: b.area,
                rischio: b.rischio, capitale: b.capitale, versamentoMensile: b.versamentoMensile, importo: b.importo,
                obiettivoId: b.obiettivoId, bisognoRilevatoId: b.bisognoRilevatoId, areaBisogno: b.areaBisogno,
                confermato: b.confermato, daConfermare: b.daConfermare, propostaId: bozza.id)) ?? r
            accendi(b.id, da: inizio, a: ricostruita.raggiunti, pronta: ricostruita.pronta, animato: animato)
        } else {
            accendi(b.id, da: inizio, a: r.raggiunti, pronta: r.pronta, animato: animato)
        }
    }

    /// Il consulente sceglie fra più prodotti adatti: la costruzione riprende dalla tappa 2.
    func scegliProdottoProposta(_ b: BisognoScoperto, prodotto: String, animato: Bool) {
        praticheProposta.sceltaProdotto[b.id] = prodotto
        costruisciProposta(b, animato: animato, da: 1)
    }

    /// Salva la bozza costruita (nuova o aggiornata) e la sua scheda di adeguatezza; nil se la costruzione si è fermata
    /// prima dell'importo.
    @discardableResult
    func salvaBozzaProposta(_ r: PropostaCostruita) -> Posizione? {
        guard let bozza = r.bozza, let scheda = r.scheda else { return nil }
        let nuova = !dati.posizioni.contains { $0.id == bozza.id }
        salvaPosizione(bozza)
        modificaScheda(bozza) { s in
            s.collegamento = scheda.collegamento
            if s.posizioneSostituitaId == nil { s.posizioneSostituitaId = scheda.posizioneSostituitaId }
        }
        praticheProposta.ricorda(bisogno: r.bisogno.id, posizione: bozza.id,
                                 chiaveProdotto: StatoPraticheProposta.chiaveProdotto(r.bisogno), prodotto: bozza.prodottoId)
        let chi = cliente(bozza.clienteId)?.nome ?? "il cliente"
        mostraAvviso(nuova ? "Bozza «\(bozza.nome)» salvata in Posizioni, tra le proposte di \(chi)."
                           : "Bozza «\(bozza.nome)» aggiornata in Posizioni, tra le proposte di \(chi).")
        return bozza
    }

    /// Accende le tappe da `inizio` a `fine` una alla volta (Tema.Apple.Pratiche.Moto), poi il riquadro finale.
    private func accendi(_ bisogno: String, da inizio: Int, a fine: Int, pronta: Bool, animato: Bool) {
        let p = praticheProposta
        guard animato, fine > inizio else {
            p.imposta(bisogno, accesi: fine, pronta: pronta)
            return
        }
        p.imposta(bisogno, accesi: inizio, pronta: false)
        p.inCorso = true
        p.sequenza = Task { @MainActor [weak p] in
            typealias M = Tema.Apple.Pratiche.Moto
            var trascorso = 0.0
            for i in inizio..<fine {
                let attesa = max(0, M.Passo.ritardo(i - inizio) - trascorso)
                try? await Task.sleep(nanoseconds: UInt64(attesa * 1_000_000_000))
                guard let p, !Task.isCancelled else { return }
                trascorso += attesa
                p.imposta(bisogno, accesi: i + 1, pronta: false)
            }
            if pronta {
                try? await Task.sleep(nanoseconds: UInt64(M.Pronta.ritardo * 1_000_000_000))
                guard let p, !Task.isCancelled else { return }
                p.imposta(bisogno, accesi: fine, pronta: true)
            }
            p?.inCorso = false
        }
    }

    /// «Rimedia»: dove si sistema il dato che manca.
    func rimediaProposta(_ r: RimedioPasso, bisogno b: BisognoScoperto, bozza: Posizione?) {
        switch r {
        case .prodotti:
            apri(.prodotti)
        case .analisi360:
            clienteAttivoId = b.clienteId
            apri(.analisi360)
        case .posizione:
            if let bozza { apriPosizione(bozza) } else { clienteAttivoId = b.clienteId; apri(.posizioni) }
        }
    }
}
