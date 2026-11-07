#if os(macOS)
import AppKit
import Combine
import Foundation

/// La mini finestra di Vera vista dallo stato di Prisma: apre, ascolta, manda la domanda nella stessa conversazione
/// dell'app Vera (il cliente del contesto o il portafoglio), segue lo streaming e porta nelle app.
/// Le risposte le scrive Qwen come nell'app Vera; le cifre sotto la risposta le calcola Prisma (`CifreMiniVera`).
extension StatoShell {
    /// Il gettone del contesto: il cliente attivo e l'app in primo piano.
    func contestoMiniVera() -> ContestoMiniVera? {
        guard let c = clienteAttivo else { return nil }
        let app = appAttiva.flatMap { $0 == .vera || $0 == .impostazioni ? nil : $0.titolo }
        return ContestoMiniVera(clienteId: c.id, nome: c.nome, iniziali: c.iniziali, tinta: c.tinta, app: app)
    }

    /// Si può chiamare Vera? Non durante la presentazione al cliente (sotto c'è solo il documento).
    var miniVeraConsentita: Bool { presentazione == nil }

    /// Apre la mini finestra in uno stato (dalla sfera nella barra, da ⌥ Spazio, dalle prove).
    func apriMiniVera(_ fase: FaseMiniVera) {
        guard miniVeraConsentita else { return }
        let mini = miniVera
        if fase == .ascolta {
            mini.apri(.ascolta, contesto: contestoMiniVera())
            ascoltaMiniVera()
        } else {
            mini.apri(fase, contesto: contestoMiniVera())
        }
    }

    /// La sfera nella barra: apre (pronta per scrivere) o chiude.
    func alternaMiniVera() {
        if miniVera.visibile { chiudiMiniVera() } else { apriMiniVera(.scrivi) }
    }

    /// Esc, la ✕, un pulsante che porta in un'app.
    func chiudiMiniVera() {
        let mini = miniVera
        guard mini.visibile else { return }
        if mini.ascoltoMio, let a = ascoltoVeraSeNato, a.ascolta { a.ferma(invia: false) }
        mini.chiudi()
        guard persistente else { return mini.riposa() }
        DispatchQueue.main.asyncAfter(deadline: .now() + Tema.Moto.MiniVera.durataUscita) {
            if !mini.visibile { mini.riposa() }
        }
    }

    /// Toglie il gettone del contesto: Vera parla di tutto il portafoglio (mai in modalità cliente).
    func togliContestoMiniVera() {
        guard !inModoCliente else { return }
        miniVera.contesto = nil
    }

    // MARK: - Ascolto

    /// Vera ascolta nella mini finestra (⌥ Spazio tenuto premuto, il microfono del campo).
    func ascoltaMiniVera() {
        let mini = miniVera
        mini.vai(.ascolta)
        mini.domanda = ""
        guard persistente else { return }
        guard !veraInCorso else {
            mini.vai(.scrivi)
            mini.nota = "Sto ancora rispondendo nell'app Vera: un attimo e ci sono."
            return
        }
        let vera = dati.impostazioni.vera
        // La dettatura di macOS scrive solo nel campo dell'app Vera: qui si scrive
        if vera.riconoscimento == .dettatura || (vera.riconoscimento == .automatico && usaDettatura) {
            mini.vai(.scrivi)
            mini.nota = "Con la dettatura del Mac scrivi qui sotto, oppure parla con Vera nella sua app (⌥⌘E)."
            return
        }
        voceVera.zitta()
        let scelta = vera.riconoscimento == .automatico
            ? (ripiegoAscolto ?? SceltaRiconoscimento.catenaAutomatica.first ?? .classico) : vera.riconoscimento
        let a = ascoltoVera
        a.azzera()
        mini.ascoltoMio = true
        a.concluso = { [weak self] frase in
            guard let self else { return }
            self.miniVera.ascoltoMio = false
            self.fraseDettaMiniVera(frase)
        }
        a.problema = { [weak self] motivo in
            guard let self else { return }
            self.miniVera.ascoltoMio = false
            guard self.miniVera.visibile else { return }
            self.miniVera.vai(.scrivi)
            self.miniVera.nota = motivo
        }
        a.avvia(scelta)
    }

    /// ⌥ Spazio lasciato (o il microfono premuto di nuovo): Vera chiude la frase e risponde.
    func fineAscoltoMiniVera() {
        let mini = miniVera
        guard persistente, mini.ascoltoMio, let a = ascoltoVeraSeNato else { return }
        if a.siPrepara {
            // Il microfono non si era ancora acceso: niente da mandare, si scrive
            a.ferma(invia: false)
            mini.ascoltoMio = false
            mini.vai(.scrivi)
            mini.nota = "Non ho fatto in tempo ad ascoltarti: tieni premuto ⌥ Spazio mentre parli, oppure scrivi."
        } else if a.ascolta {
            a.ferma(invia: true)
        }
    }

    /// Il microfono del campo: ascolta, o chiude la frase se sta già ascoltando.
    func alternaAscoltoMiniVera() {
        if miniVera.ascoltoMio, ascoltoVeraSeNato?.ascolta == true { fineAscoltoMiniVera() } else { ascoltaMiniVera() }
    }

    private func fraseDettaMiniVera(_ frase: String) {
        guard miniVera.visibile else { return }
        if CongedoVera.e(frase) { return chiudiMiniVera() }
        inviaMiniVera(DomandaMiniVera(testo: frase, aVoce: true))
    }

    // MARK: - Domanda e risposta

    /// Qwen può rispondere (o la domanda è un comando, che fa Prisma da sola)?
    private func prontaPer(_ testo: String) -> Bool {
        if rispostePreparate || generativo != nil || appuntamentoInSospeso != nil { return true }
        let noti = dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        return InterpreteComandi.interpreta(testo, clienti: noti, attivo: veraPortafoglio ? nil : clienteAttivoId) != nil
    }

    /// Manda una domanda: pensa, poi risponde nella scheda. Se Qwen non è pronto la mette da parte e lo sveglia.
    func inviaMiniVera(_ d: DomandaMiniVera) {
        let mini = miniVera
        let testo = d.testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !testo.isEmpty else { return }
        guard !veraInCorso else {
            mini.vai(.scrivi)
            mini.nota = "Sto ancora rispondendo nell'app Vera: un attimo e ci sono."
            return
        }
        mini.testo = ""
        mini.nota = nil
        // Senza gettone (o con uno spunto del portafoglio) Vera parla del portafoglio; in modalità cliente mai
        let suPortafoglio = !inModoCliente && (d.portafoglio != nil || mini.contesto == nil)
        if !suPortafoglio, let c = mini.contesto, clienteAttivoId != c.clienteId { clienteAttivoId = c.clienteId }
        // La stessa conversazione dell'app Vera: la freccia la apre lì
        if veraPortafoglio != suPortafoglio { veraPortafoglio = suPortafoglio }
        mini.domanda = testo
        guard prontaPer(testo) else {
            mini.pendente = DomandaMiniVera(testo: testo, spunto: d.spunto, portafoglio: d.portafoglio, aVoce: d.aVoce)
            mini.nonPronta(motivo: nil)
            preparaQwenMiniVera()
            return
        }
        mini.pendente = nil
        let id = chiaveConversazione
        let fonte = suPortafoglio ? nil : fonteVera(id)
        let modalita = suPortafoglio ? ModalitaVera.lavoro
            : NucleoVera.modalita(domanda: testo, spunto: d.spunto, cliente: fonte?.cliente, storia: conversazione(id))
        mini.chiave = id
        mini.messaggiPrima = conversazione(id).count
        mini.pensa(testo, passi: StatoMiniVera.passi(domanda: testo, fonte: fonte, modalita: modalita))
        let cifre = CifreMiniVera.calcola(domanda: testo, fonte: fonte, modalita: modalita, app: mini.contesto?.app)
        if d.aVoce { rispostaAVoce = dati.impostazioni.vera.risposteAVoce != .mai }
        // Nella mini finestra la risposta è breve: le cifre le mostra la scheda (linea del tempo, righe, fonte)
        let partita = suPortafoglio ? chiediVeraPortafoglio(testo, spunto: d.portafoglio, breve: true)
                                    : chiediVera(testo, spunto: d.spunto, breve: true)
        guard partita else {
            rispostaAVoce = false
            mini.vai(.scrivi)
            mini.nota = "La domanda non è partita: riprova tra un attimo."
            return
        }
        seguiRispostaMiniVera(cifre)
    }

    /// Segue la risposta: le parole che arrivano (FlussoVera) e il messaggio finale nella conversazione.
    private func seguiRispostaMiniVera(_ cifre: CifreMiniVera) {
        let mini = miniVera
        mini.abbonamenti.removeAll()
        if concludiMiniVera(cifre) { return }
        flussoVera.$testo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] t in
                guard let self, self.veraInCorso, !t.isEmpty, mini.fase == .pensa || mini.fase == .risponde else { return }
                mini.rispondi(testo: t.trimmingCharacters(in: .whitespacesAndNewlines), titolo: nil, cifre: cifre, inArrivo: true)
            }
            .store(in: &mini.abbonamenti)
        // Al giro dopo: conQwen spegne e riaccende `veraInCorso` nello stesso momento
        $veraInCorso
            .removeDuplicates()
            .filter { !$0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in _ = self?.concludiMiniVera(cifre) }
            .store(in: &mini.abbonamenti)
    }

    /// La risposta è nella conversazione: la scheda mostra il testo finale. false se non è ancora arrivata.
    @discardableResult
    func concludiMiniVera(_ cifre: CifreMiniVera) -> Bool {
        let mini = miniVera
        let elenco = conversazione(mini.chiave)
        guard !veraInCorso, elenco.count > mini.messaggiPrima, let m = elenco.last, m.autore == .vera else { return false }
        mini.abbonamenti.removeAll()
        if m.titolo == "Qwen non è pronto" {
            mini.pendente = DomandaMiniVera(testo: mini.domanda)
            mini.nonPronta(motivo: disponibilitaLocale.motivo)
            return true
        }
        var c = cifre
        if let s = m.scenario {
            // Lo scenario «E se…?»: la tabella prima/dopo di Prisma e i due pulsanti della scheda
            c = CifreMiniVera()
            c.scenario = s
            c.fonte = "Cifre dai calcoli di Prisma, con le ipotesi di \(s.nomeCliente)"
            c.azioni = [AzioneMiniVera(titolo: s.salvata ? "Nel dossier" : "Salva nel dossier", simbolo: s.salvata ? "checkmark" : "tray.and.arrow.down",
                                      tipo: .salvaScenario(m.id), primaria: !s.salvata),
                        AzioneMiniVera(titolo: s.simulazione == nil ? "Apri in Analisi 360" : "Apri in Simulazioni", simbolo: "arrow.up.forward",
                                      tipo: .apriScenario(m.id))]
        } else if let a = m.azione {
            // Vera ha fatto qualcosa (un appuntamento, un promemoria): il pulsante lo apre
            c = CifreMiniVera()
            c.azioni = [AzioneMiniVera(titolo: Self.titoloAzione(a), simbolo: "arrow.up.forward", tipo: .azioneVera(a), primaria: true)]
        } else if m.titolo == "Vera non ha potuto rispondere" || m.motore == StatoShell.motoreAzioni {
            c = CifreMiniVera()
        }
        mini.rispondi(testo: NucleoVera.pulisci(m.testo), titolo: m.titolo, cifre: c, inArrivo: false)
        return true
    }

    private static func titoloAzione(_ a: AzioneVera) -> String {
        switch a.tipo {
        case .appuntamento: return "Apri in Agenda"
        // Attività è accorpata nell'Agenda: l'attività si apre nel giorno della sua scadenza
        case .attivita: return "Apri in Agenda"
        case .nota: return "Apri la nota"
        }
    }

    // MARK: - Qwen non pronto

    /// «Mi sto svegliando…»: apre Ollama se serve e carica il modello; poi manda la domanda rimasta da parte.
    func preparaQwenMiniVera() {
        let mini = miniVera
        guard persistente, !mini.preparazioneInCorso else { return }
        mini.preparazioneInCorso = true
        mini.motivoNonPronta = nil
        let vera = dati.impostazioni.vera
        Task.detached(priority: .userInitiated) {
            let d = await AvvioModello.prepara(vera)
            await MainActor.run {
                if self.disponibilitaLocale != d { self.disponibilitaLocale = d }
                mini.preparazioneInCorso = false
                guard mini.visibile, mini.fase == .nonPronta else { return }
                if d.pronto {
                    if let p = mini.pendente { self.inviaMiniVera(p) } else { mini.vai(.scrivi) }
                } else {
                    mini.motivoNonPronta = d.motivo
                }
            }
        }
    }

    /// «Riprova» nello stato non pronta.
    func riprovaMiniVera() {
        if let p = miniVera.pendente, prontaPer(p.testo) { return inviaMiniVera(p) }
        preparaQwenMiniVera()
    }

    // MARK: - Verso le app

    /// Un pulsante della risposta: porta Prisma davanti, apre l'app e chiude la mini finestra.
    func eseguiMiniVera(_ a: AzioneMiniVera) {
        let id = miniVera.contesto?.clienteId
        let nome = id.flatMap { cliente($0)?.nome }
        portaDavantiPrisma()
        if let id, clienteAttivoId != id { clienteAttivoId = id }
        let commiato: String
        switch a.tipo {
        case .posizioni:
            apri(.posizioni)
            commiato = "Ti porto in Posizioni" + (nome.map { " · \($0)" } ?? "")
        case .agenda:
            if let id { filtroClienteAgenda = id }
            apri(.agenda)
            commiato = "Ti porto in Agenda" + (nome.map { " · \($0)" } ?? "")
        case .prospetto(let s):
            apriProspetto(s)
            commiato = "Il prospetto è pronto in Prospetti e report"
        case .azioneVera(let e):
            apriAzioneVera(e)
            commiato = a.titolo
        case .salvaScenario(let messaggio):
            // Il salvataggio ha già il suo avviso («Scenario salvato nel dossier di…»): niente commiato
            if let s = schedaScenario(messaggio: messaggio, chiave: miniVera.chiave) { salvaScenarioVera(s, messaggio: messaggio) }
            chiudiMiniVera()
            return
        case .apriScenario(let messaggio):
            if let s = schedaScenario(messaggio: messaggio, chiave: miniVera.chiave) { apriScenarioVera(s) }
            commiato = a.titolo.hasSuffix("Simulazioni") ? "Ti porto nel simulatore con lo scenario" : "Ti porto in Analisi 360"
        }
        chiudiMiniVera()
        // Il commiato (.toast del template): Vera si ritira verso la sua sfera e dice dove ti ha portato
        mostraAvviso(commiato, daVera: true)
    }

    /// La freccia: la stessa conversazione nell'app Vera completa.
    func apriInVeraDaMiniVera() {
        let mini = miniVera
        portaDavantiPrisma()
        if !inModoCliente { veraPortafoglio = mini.contesto == nil && mini.chiave == VeraPortafoglio.chiave }
        if let c = mini.contesto, clienteAttivoId != c.clienteId { clienteAttivoId = c.clienteId }
        apri(.vera)
        chiudiMiniVera()
    }

    /// Prisma in primo piano (la mini finestra non la attiva), senza la schermata di benvenuto davanti.
    private func portaDavantiPrisma() {
        guard persistente else { return }
        NSApp.activate(ignoringOtherApps: true)
        if let f = PannelloMiniVera.finestraPrisma() {
            if f.isMiniaturized { f.deminiaturize(nil) }
            f.makeKeyAndOrderFront(nil)
        }
        if bloccato { sblocca() }
    }

    /// Le ultime domande fatte a Vera (da tutte le conversazioni), le più recenti prima.
    func recentiMiniVera(_ quante: Int = 2) -> [MessaggioVera] {
        guard !inModoCliente else { return [] }
        let tutte = dati.impostazioni.vera.conservaConversazioni ? dati.conversazioni : conversazioniTemporanee
        var visti = Set<String>()
        return tutte.values.joined()
            .filter { $0.autore == .utente }
            .sorted { $0.data > $1.data }
            .filter { visti.insert($0.testo).inserted }
            .prefix(quante)
            .map { $0 }
    }
}
#endif
