import CoreGraphics
import Foundation
import Observation

// Territorio · «Il tuo territorio» («Luce» giro 11, §5.1): lo stato della finestra (tabella dei comuni in memoria solo
// mentre Territorio è aperto, luce puntata, filtri, anno della crescita, giorno del giro, modalità «Sposta») e, su
// StatoShell, i calcoli con le loro cache e le azioni che scrivono l'archivio. Niente rete: tabella e confini vengono
// dalle risorse (decisione 20).

@Observable final class StatoTerritorio {
    /// Osservata (non `@ObservationIgnored`): la vista la legge nel `body` e deve ridisegnarsi quando `apri` la carica dopo
    /// la prima comparsa. Liberata alla chiusura (Mac da 8 GB, §5.4).
    private(set) var tabella: TabellaComuni?
    /// La tabella non si legge dalle risorse (non deve succedere: lo controlla `--verifica-risorse`).
    private(set) var tabellaNonLeggibile = false
    /// I confini delle province, caricati in `apri` (mai nel `body`). Osservati per la stessa ragione di `tabella`.
    private(set) var confini: [String: ConfiniProvincia] = [:]
    var lucePuntata: String?
    /// Il nome della zona filtrata (le altre luci attenuate).
    var filtroZona: String?
    /// «Con qualcosa da fare»: solo gli anelli e l'elenco nel pannello.
    var soloDaFare = false
    /// nil = l'ultimo anno.
    var annoCrescita: Int?
    var crescitaInCorso = false
    /// nil = domani (il primo giorno di lavoro da domani).
    var giornoGiro: Date?
    var elencoSenzaLuogo = false
    /// Modalità «Sposta» (posizione a mano): il cliente da mettere sulla mappa.
    var spostaClienteId: String?
    /// L'appuntamento appena aggiunto al giro (riga evidenziata).
    var rigaNuovaId: String?
    /// Zoom e spostamento della mappa (doppio clic: torna a vedere tutti).
    var zoom: CGFloat = 1
    var spostamento: CGSize = .zero
    @ObservationIgnored var avvioCrescitaFatto = false
    @ObservationIgnored private var lavoroCrescita: Task<Void, Never>?

    /// Carica la tabella (se serve) e i confini delle province date. Chiamata da `StatoShell.apriTabellaTerritorio()`.
    func apri(province: Set<String>) {
        caricaSeServe()
        for p in province where confini[p] == nil {
            if let c = TabellaTerritorio.caricaConfini(provincia: p) { confini[p] = c }
        }
    }

    /// La tabella al primo uso (anche per la riga del dossier), fuori dal `body`.
    func caricaSeServe() {
        guard tabella == nil else { return }
        tabella = TabellaTerritorio.caricaComuni()
        tabellaNonLeggibile = tabella == nil
    }

    /// «▶︎ Guarda la crescita»: un anno ogni `passo` secondi con un `Task` che dorme (niente Timer), dopo `attesa`.
    /// Cancellato al cambio di vista, alla chiusura e al blocco.
    func avviaCrescita(primo: Int, ultimo: Int, attesa: Double, passo: Double) {
        fermaCrescita()
        guard primo <= ultimo else { return }
        crescitaInCorso = true
        lavoroCrescita = Task { @MainActor [weak self] in
            if attesa > 0 { try? await Task.sleep(nanoseconds: UInt64(attesa * 1_000_000_000)) }
            var anno = primo
            while anno <= ultimo {
                if Task.isCancelled { return }
                guard let stato = self else { return }
                stato.annoCrescita = anno
                if anno == ultimo { break }
                try? await Task.sleep(nanoseconds: UInt64(passo * 1_000_000_000))
                anno += 1
            }
            if !Task.isCancelled { self?.crescitaInCorso = false }
        }
    }

    func fermaCrescita() {
        lavoroCrescita?.cancel()
        lavoroCrescita = nil
        if crescitaInCorso { crescitaInCorso = false }
    }

    /// Esc: chiude il fumetto, poi l'elenco, poi il filtro, poi la modalità «Sposta». Vero se ha chiuso qualcosa.
    @discardableResult
    func chiudiUno() -> Bool {
        if lucePuntata != nil { lucePuntata = nil; return true }
        if elencoSenzaLuogo { elencoSenzaLuogo = false; return true }
        if soloDaFare { soloDaFare = false; return true }
        if filtroZona != nil { filtroZona = nil; return true }
        if spostaClienteId != nil { spostaClienteId = nil; return true }
        return false
    }

    /// Territorio si chiude: si libera la tabella e si ferma la crescita.
    func chiudi() {
        fermaCrescita()
        tabella = nil
        tabellaNonLeggibile = false
        confini = [:]
        lucePuntata = nil
        filtroZona = nil
        soloDaFare = false
        spostaClienteId = nil
        elencoSenzaLuogo = false
        rigaNuovaId = nil
        zoom = 1
        spostamento = .zero
        avvioCrescitaFatto = false
    }
}

extension StatoShell {
    // MARK: Tabella e luoghi

    /// Carica tabella e confini delle province dei clienti sulla mappa e della partenza. Da `onAppear` (mai nel `body`).
    func apriTabellaTerritorio() {
        territorio.caricaSeServe()
        guard let t = territorio.tabella else { return }
        var province = Set(luoghiTerritorio().luoghi.values.compactMap { $0.comune?.provincia })
        if let p = MotoreTerritorio.partenzaGiro(impostazioni: dati.impostazioni, tabella: t),
           let c = MotoreTerritorio.comuneVicino(p.coordinata, tabella: t) {
            province.insert(c.provincia)
        }
        territorio.apri(province: province)
    }

    /// Le posizioni dei clienti visibili (cache: dati dei calcoli e impostazioni del Territorio nella chiave).
    func luoghiTerritorio() -> (luoghi: [String: LuogoCliente], senzaLuogo: [ClienteSenzaLuogo]) {
        guard let t = territorio.tabella else {
            return ([:], clienti.map { ClienteSenzaLuogo(cliente: $0, motivo: .tabellaMancante) })
        }
        let imp = dati.impostazioni.territorio
        let d = derivatiValidi()
        if let c = d.luoghiTerritorio, c.imp == imp { return c.valore }
        let v = MotoreTerritorio.luoghi(clienti: clienti, tabella: t, zone: imp.zone)
        d.luoghiTerritorio = (imp, v)
        return v
    }

    /// Tutte le voci di MotoreDaFare (senza il limite del nastro) e le attenzioni, con la cache oraria.
    func vociDaFareTutte() -> (voci: [VoceDaFare], attenzioni: [Attenzione]) {
        let d = derivatiValidi()
        let ora = DerivatiDati.ora()
        if let c = d.vociDaFare, c.ora == ora { return (c.valore, c.attenzioni) }
        let x = ingressiDaFare(adesso: Date())
        let v = MotoreDaFare.voci(x)
        d.vociDaFare = (ora, v, x.attenzioni)
        return (v, x.attenzioni)
    }

    /// «Qualcosa da fare» per cliente (decisione 99).
    func daFareTerritorio() -> [String: DaFareCliente] {
        let tutte = vociDaFareTutte()
        return MotoreTerritorio.daFare(tutte.voci, attenzioni: tutte.attenzioni,
                                       attenzioniAlte: Set(dati.impostazioni.territorio.attenzioniAlte))
    }

    // MARK: Le tre viste

    func territorioOggi() -> TerritorioOggi {
        guard territorio.tabella != nil else { return .vuoto }
        let imp = dati.impostazioni.territorio
        let d = derivatiValidi()
        let ora = DerivatiDati.ora()
        if let c = d.territorioOggi, c.ora == ora, c.imp == imp { return c.valore }
        let l = luoghiTerritorio()
        let v = MotoreTerritorio.oggi(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti, luoghi: l.luoghi,
                                      senzaLuogo: l.senzaLuogo, daFare: daFareTerritorio(), oggi: Date())
        d.territorioOggi = (ora, imp, v)
        return v
    }

    func crescitaTerritorio() -> CrescitaTerritorio {
        guard territorio.tabella != nil else { return .vuota }
        let d = derivatiValidi()
        if let c = d.crescitaTerritorio { return c }
        let v = MotoreTerritorio.crescita(luci: territorioOggi().luci, posizioni: posizioni, oggi: Date())
        d.crescitaTerritorio = v
        return v
    }

    /// La partenza del giro e da dove viene (nil = studio senza indirizzo).
    func partenzaTerritorio() -> PartenzaGiro? {
        guard let t = territorio.tabella else { return nil }
        return MotoreTerritorio.partenzaGiro(impostazioni: dati.impostazioni, tabella: t)
    }

    /// Il giorno del giro mostrato: quello scelto con le frecce, altrimenti il primo giorno di lavoro da domani.
    func giornoGiroTerritorio() -> Date {
        if let g = territorio.giornoGiro { return Calendar.current.startOfDay(for: g) }
        let cal = Calendar.current
        let domani = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
        return MotoreTerritorio.giornoLavorativo(da: domani, orari: dati.impostazioni.orari, calendario: cal)
    }

    func giroTerritorio(_ giorno: Date) -> GiroGiorno {
        let inizio = Calendar.current.startOfDay(for: giorno)
        guard territorio.tabella != nil else {
            return GiroGiorno(giorno: inizio, partenza: nil, tappe: [], km: 0, minuti: 0, suggerimenti: [], senzaLuogo: [],
                              luogoDaIndicare: [], altrove: 0, prossimoGiorno: nil)
        }
        let imp = dati.impostazioni.territorio
        let partenza = partenzaTerritorio()?.coordinata
        let d = derivatiValidi()
        let ora = DerivatiDati.ora()
        if let c = d.giriTerritorio[inizio], c.ora == ora, c.imp == imp, c.partenza == partenza { return c.valore }
        let v = MotoreTerritorio.giro(giorno: inizio, appuntamenti: appuntamenti, clienti: clienti, luoghi: luoghiTerritorio().luoghi,
                                      partenza: partenza, daFare: daFareTerritorio(), impostazioni: imp, orari: dati.impostazioni.orari)
        if d.giriTerritorio.count >= 7 { d.giriTerritorio = [:] }
        d.giriTerritorio[inizio] = (ora, imp, partenza, v)
        return v
    }

    // MARK: Azioni

    /// «＋ Aggiungi … al giro»: un appuntamento da confermare nello spazio libero fra le due visite (decisione 99).
    /// Funziona anche sull'iPad: l'appuntamento è un'entità creabile e `daConfermare` è sincronizzato.
    func aggiungiAlGiro(_ s: SuggerimentoGiro) {
        guard !solaLettura else { return }
        let id = "event-\(UUID().uuidString.prefix(8).lowercased())"
        let a = Appuntamento(id: id, clienteId: s.cliente.id, titolo: "Visita · \(s.cliente.nome)", inizio: s.ora,
                             durataMinuti: dati.impostazioni.territorio.durataVisitaBreve, luogo: "",
                             note: "Proposto dal Territorio: \(s.motivo)", stato: .pianificato, tipo: .revisione,
                             presso: .cliente, daConfermare: true)
        salvaAppuntamento(a)
        territorio.rigaNuovaId = id
        let cal = Calendar.current
        let minuti = cal.component(.hour, from: s.ora) * 60 + cal.component(.minute, from: s.ora)
        mostraAvviso("\(MotoreTerritorio.nomeBattesimo(s.cliente)) nel giro alle \(OrariLavoro.testoOra(minuti)): conferma in Agenda")
    }

    /// Conferma un appuntamento proposto dal Territorio (Agenda).
    func confermaAppuntamento(_ id: String) {
        guard !solaLettura, let i = dati.appuntamenti.firstIndex(where: { $0.id == id }), dati.appuntamenti[i].daConfermare != nil else { return }
        dati.appuntamenti[i].daConfermare = nil
    }

    /// Apre l'Agenda sul giorno dell'appuntamento, con l'appuntamento selezionato (riga del giro).
    func apriAppuntamentoInAgenda(_ a: Appuntamento) {
        giornoAgenda = Calendar.current.startOfDay(for: a.inizio)
        appuntamentoSelezionato = a.id
        occasioneSelezionata = nil
        if vistaAgenda == .occasioni { vistaAgenda = .mese }
        apri(.agenda)
    }

    /// La posizione a mano di un cliente (nil = torna al comune). Solo sul Mac: `Cliente.luogo` non è un campo
    /// sincronizzato di «Prisma ovunque», e una modifica sull'iPad si perderebbe alla prossima istantanea.
    func impostaLuogoManuale(_ clienteId: String, _ luogo: LuogoManuale?) {
        #if os(iOS)
        mostraAvviso(StatoShell.soloSulMacPerOra)
        #else
        guard !solaLettura, let i = dati.clienti.firstIndex(where: { $0.id == clienteId }) else { return }
        guard dati.clienti[i].luogo != luogo else { return }
        dati.clienti[i].luogo = luogo
        #endif
    }

    /// Impostazioni › Territorio. Solo sul Mac (non sono campi sincronizzati).
    func impostaTerritorio(_ modifica: (inout ImpostazioniTerritorio) -> Void) {
        #if os(iOS)
        mostraAvviso(StatoShell.soloSulMacPerOra)
        #else
        guard !solaLettura else { return }
        var t = dati.impostazioni.territorio
        modifica(&t)
        if t != dati.impostazioni.territorio { dati.impostazioni.territorio = t }
        #endif
    }

    /// «Mettila a mano»: apre Territorio in modalità «Sposta» con il cliente scelto. Solo sul Mac.
    func apriTerritorioSposta(_ clienteId: String) {
        #if os(iOS)
        mostraAvviso(StatoShell.soloSulMacPerOra)
        #else
        territorio.lucePuntata = nil
        territorio.filtroZona = nil
        territorio.soloDaFare = false
        territorio.spostaClienteId = clienteId
        apriTerritorio(.oggi)
        #endif
    }

    /// Il clic sulla mappa in modalità «Sposta»: fissa il punto e torna al dossier.
    func fissaPosizione(_ c: Coordinata) {
        guard let id = territorio.spostaClienteId, c.valida else { return }
        impostaLuogoManuale(id, LuogoManuale(coordinata: c))
        territorio.spostaClienteId = nil
        let nome = dati.clienti.first { $0.id == id }.map(MotoreTerritorio.nomeBattesimo) ?? "Il cliente"
        mostraAvviso("\(nome): posizione messa a mano")
    }
}
