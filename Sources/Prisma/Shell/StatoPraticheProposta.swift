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
    /// I bisogni chiesti da fuori, finché Prisma è aperta: la sostituzione dello Smontaggio («Crea la proposta di
    /// sostituzione»), la persona chiave e il welfare dal dossier dell'azienda. Stanno in cima alla barra.
    fileprivate(set) var richieste: [BisognoScoperto] = []

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

    fileprivate func dimentica(bisogno: String) {
        costruite[bisogno] = nil
        // Una richiesta collegata alla bozza tolta torna da costruire
        if let i = richieste.firstIndex(where: { $0.id == bisogno }) { richieste[i].propostaId = nil }
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

    /// Un bisogno chiesto da fuori (Smontaggio, dossier dell'azienda) diventa il bisogno scelto della scheda.
    func richiediBisognoProposta(_ b: BisognoScoperto) {
        let p = praticheProposta
        p.richieste.removeAll { $0.id == b.id }
        p.richieste.insert(b, at: 0)
        p.cacheBisogni = nil
        p.azzera()
        p.scelto = b.id
    }

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
        let schede = Dictionary(grouping: dati.schedeAdeguatezza, by: \.clienteId)
        // La proposta costruita in questa sessione, se il motore non la ritrova da solo
        func collega(_ b: BisognoScoperto) -> BisognoScoperto {
            guard b.propostaId == nil, let id = p.costruite[b.id], dati.posizioni.contains(where: { $0.id == id }) else { return b }
            var c = b
            c.propostaId = id
            return c
        }
        let richieste = p.richieste.filter { r in dati.clienti.contains { $0.id == r.clienteId } }.map(collega)
        let chieste = Set(richieste.map(\.id))
        for c in dati.clienti {
            guard let fonte = fonteProposta(c.id, oggi: oggi) else { continue }
            let elenco = MotoreProposta.bisogni(fonte: fonte, bozze: bozzeAperteProposta(c.id), schede: schede[c.id] ?? [])
                .filter { !chieste.contains($0.id) }
                .map(collega)
            if !elenco.isEmpty { perCliente.append(elenco) }
        }
        var tutti: [BisognoScoperto] = richieste
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
        // I modelli di Pratiche › Moduli (letti con `moduli.carica()` all'apertura della scheda): cambiati, si ricostruisce
        let modelli = moduli.tutti
        let chiave = b.id + "|" + (b.propostaId ?? "") + "|" + (p.sceltaProdotto[b.id] ?? "") + "|"
            + modelli.map { $0.id + ($0.mappaConfermata ? "+" : "-") }.joined(separator: ",")
        if let r = p.cacheCostruite.valore[chiave] { return r }
        guard let fonte = fonteProposta(b.clienteId) else { return nil }
        let bozza = b.propostaId.flatMap { id in dati.posizioni.first { $0.id == id } }
        // La chiave è `versioneDati` (già letta qui sopra, quindi osservata): l'archivio si legge senza iscrivere la
        // vista a ogni campo
        let r = MotoreProposta.costruisci(b, fonte: fonte, dati: dati.istantaneaNonOsservata, bozzaEsistente: bozza,
                                          prodottoScelto: p.sceltaProdotto[b.id],
                                          ultimo: p.ultimoProdotto[StatoPraticheProposta.chiaveProdotto(b)],
                                          modelli: modelli,
                                          contaPagine: { ImpaginatoreProspetto.pagine($0).count },
                                          contaSostituzione: { e, c in
                                              DocumentoStampabile(TestiSostituzione(e, cliente: c), report: false).pagine.count
                                          })
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
        moduli.carica()
        guard let r = propostaCostruita(b) else { return }
        if let bozza = salvaBozzaProposta(r) {
            // Ora la bozza c'è: la colonna la ritrova anche dopo il ricalcolo dei bisogni
            var collegato = b
            collegato.propostaId = bozza.id
            let ricostruita = propostaCostruita(collegato) ?? r
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
        let primaPosizione = dati.posizioni.first { $0.id == bozza.id }
        let primaScheda = schedaAdeguatezza(bozza.id)
        salvaPosizione(bozza)
        modificaScheda(bozza) { s in
            s.collegamento = scheda.collegamento
            if s.posizioneSostituitaId == nil { s.posizioneSostituitaId = scheda.posizioneSostituitaId }
        }
        praticheProposta.ricorda(bisogno: r.bisogno.id, posizione: bozza.id,
                                 chiaveProdotto: StatoPraticheProposta.chiaveProdotto(r.bisogno), prodotto: bozza.prodottoId)
        let chi = cliente(bozza.clienteId)?.nome ?? "il cliente"
        // «Annulla»: toglie la bozza nuova e la sua scheda, o rimette com'erano quella aggiornata e la sua scheda
        let annulla = AzioneAvviso(titolo: "Annulla") { [weak self] in
            self?.annullaBozzaProposta(bozza.id, bisogno: r.bisogno.id, prima: primaPosizione, schedaPrima: primaScheda)
        }
        mostraAvviso(primaPosizione == nil ? "Bozza «\(bozza.nome)» salvata in Posizioni, tra le proposte di \(chi)."
                                           : "Bozza «\(bozza.nome)» aggiornata in Posizioni, tra le proposte di \(chi).",
                     azione: solaLettura ? nil : annulla)
        return bozza
    }

    /// «Annulla» del toast della bozza: la creazione rapida torna indietro (bozza e scheda di adeguatezza).
    func annullaBozzaProposta(_ id: String, bisogno: String, prima: Posizione?, schedaPrima: SchedaAdeguatezza?) {
        guard !solaLettura else { return }
        let p = praticheProposta
        p.fermaSequenza()
        if let prima, let i = dati.posizioni.firstIndex(where: { $0.id == id }) {
            dati.posizioni[i] = prima
            dati.schedeAdeguatezza.removeAll { $0.posizioneId == id }
            if let schedaPrima { dati.schedeAdeguatezza.append(schedaPrima) }
        } else {
            eliminaPosizione(id)
            p.dimentica(bisogno: bisogno)
        }
        if p.accesiDi == bisogno { p.azzera() }
        mostraAvviso("Bozza tolta: la proposta torna da costruire.")
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
        case .azienda:
            clienteAttivoId = b.clienteId
            schedaCliente = .azienda
            apri(.clienti)
        }
    }

    // MARK: - I riquadri a costruzione finita

    /// Riquadro 4: la scheda di adeguatezza della proposta, nel dettaglio della posizione.
    func apriAdeguatezzaProposta(_ bozza: Posizione) {
        apriPosizione(bozza)
        DispatchQueue.main.async { self.ancoraPosizioni = "dettaglio-adeguatezza" }
    }

    /// Riquadro 3: il prospetto della proposta (quello di sostituzione per «costi più bassi»).
    func apriProspettoProposta(_ bozza: Posizione, prospetto: ProspettoProposta?) {
        clienteAttivoId = bozza.clienteId
        if let a = prospetto?.attualeId {
            apriProspetto(.sostituzione(a, bozza.id, report: false))
        } else {
            apriProspetto(.posizione(bozza.id))
        }
    }

    /// Riquadro 5: Pratiche › Moduli sul primo modulo della proposta, per il cliente e la proposta giusti.
    func apriModuliProposta(_ bozza: Posizione, modulo: String?) {
        moduli.carica()
        moduli.clienteId = bozza.clienteId
        moduli.posizioneId = bozza.id
        if let modulo, moduli.modello(modulo) != nil {
            moduli.scelto = modulo
            moduli.pagina = 0
        }
        moduli.azzeraCompilazione()
        apriPratiche(.moduli)
    }

    // MARK: - «Presenta a …»

    /// Il documento della proposta: il prospetto di sostituzione o quello della posizione.
    func documentoProposta(_ bozza: Posizione, prospetto: ProspettoProposta?) -> DocumentoStampabile? {
        if let a = prospetto?.attualeId { return testiSostituzione(a, bozza.id).map { DocumentoStampabile($0, report: false) } }
        return DocumentoStampabile(CompositoreProspetti.posizione(bozza, dati: dati.istantanea))
    }

    /// «Presenta a …»: con l'iPad collegato al tavolo il prospetto va sull'iPad, altrimenti si apre la presentazione in
    /// sala sul Mac (decisione D1.7). Presentare segna la proposta «presentata»: `salvaPosizione` scrive la data
    /// (`SeguitoProposta.presentataIl`) e registra la raccomandazione del track record, come per ogni proposta presentata.
    @MainActor
    func presentaProposta(_ bozza: Posizione, prospetto: ProspettoProposta?) {
        guard !solaLettura else {
            mostraAvviso(TestiSeguito.solaLettura)
            return
        }
        guard let attuale = dati.posizioni.first(where: { $0.id == bozza.id }) else { return }
        clienteAttivoId = attuale.clienteId
        let documento = documentoProposta(attuale, prospetto: prospetto)
        var presentata = attuale
        if presentata.esito == nil || presentata.esito == .bozza { presentata.esito = .presentata }
        salvaPosizione(presentata)
        praticheProposta.azzera()
        let nome = cliente(attuale.clienteId).map { MotoreProposta.primoNome($0.nome) } ?? "il cliente"
        #if os(macOS)
        if tavolo.collegato, let d = documento {
            tavolo.mandaDocumento(ContestoTavolo(documento: d, pagina: 0, clienteId: attuale.clienteId))
            mostraAvviso("Proposta sul tavolo con l'iPad: \(nome) la sfoglia lì.")
            return
        }
        #endif
        if let d = documento {
            presenta(d)
        } else {
            apriPosizione(presentata)
            mostraAvviso("Proposta segnata come presentata a \(nome).")
        }
    }
}
