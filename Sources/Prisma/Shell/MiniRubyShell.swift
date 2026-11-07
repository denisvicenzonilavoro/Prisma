#if os(macOS)
import AppKit
import Combine
import Foundation

/// La mini finestra di Ruby vista dallo stato di Prisma: apre, ascolta, manda la domanda nella stessa conversazione
/// dell'app Ruby (il cliente del contesto o il portafoglio), segue lo streaming e porta nelle app.
/// Le risposte le scrive Qwen come nell'app Ruby; le cifre sotto la risposta le calcola Prisma (`CifreMiniRuby`).
extension StatoShell {
    /// Il gettone del contesto: il cliente attivo e l'app in primo piano.
    func contestoMiniRuby() -> ContestoMiniRuby? {
        guard let c = clienteAttivo else { return nil }
        let app = appAttiva.flatMap { $0 == .ruby || $0 == .impostazioni ? nil : $0.titolo }
        return ContestoMiniRuby(clienteId: c.id, nome: c.nome, iniziali: c.iniziali, tinta: c.tinta, app: app)
    }

    /// Si può chiamare Ruby? Non durante la presentazione al cliente (sotto c'è solo il documento).
    var miniRubyConsentita: Bool { presentazione == nil }

    /// Apre la mini finestra in uno stato (dalla sfera nella barra, da ⌥ Spazio, dalle prove).
    func apriMiniRuby(_ fase: FaseMiniRuby) {
        guard miniRubyConsentita else { return }
        let mini = miniRuby
        if fase == .ascolta {
            mini.apri(.ascolta, contesto: contestoMiniRuby())
            ascoltaMiniRuby()
        } else {
            mini.apri(fase, contesto: contestoMiniRuby())
        }
    }

    /// La sfera nella barra: apre (pronta per scrivere) o chiude.
    func alternaMiniRuby() {
        if miniRuby.visibile { chiudiMiniRuby() } else { apriMiniRuby(.scrivi) }
    }

    /// Esc, la ✕, un pulsante che porta in un'app.
    func chiudiMiniRuby() {
        let mini = miniRuby
        guard mini.visibile else { return }
        if mini.ascoltoMio, let a = ascoltoRubySeNato, a.ascolta { a.ferma(invia: false) }
        mini.chiudi()
        guard persistente else { return mini.riposa() }
        DispatchQueue.main.asyncAfter(deadline: .now() + Tema.Moto.MiniRuby.durataUscita) {
            if !mini.visibile { mini.riposa() }
        }
    }

    /// Toglie il gettone del contesto: Ruby parla di tutto il portafoglio (mai in modalità cliente).
    func togliContestoMiniRuby() {
        guard !inModoCliente else { return }
        miniRuby.contesto = nil
    }

    // MARK: - Ascolto

    /// Ruby ascolta nella mini finestra (⌥ Spazio tenuto premuto, il microfono del campo).
    func ascoltaMiniRuby() {
        let mini = miniRuby
        mini.vai(.ascolta)
        mini.domanda = ""
        guard persistente else { return }
        guard !rubyInCorso else {
            mini.vai(.scrivi)
            mini.nota = "Sto ancora rispondendo nell'app Ruby: un attimo e ci sono."
            return
        }
        let ruby = dati.impostazioni.ruby
        // La dettatura di macOS scrive solo nel campo dell'app Ruby: qui si scrive
        if ruby.riconoscimento == .dettatura || (ruby.riconoscimento == .automatico && usaDettatura) {
            mini.vai(.scrivi)
            mini.nota = "Con la dettatura del Mac scrivi qui sotto, oppure parla con Ruby nella sua app (⌥⌘E)."
            return
        }
        voceRuby.zitta()
        let scelta = ruby.riconoscimento == .automatico
            ? (ripiegoAscolto ?? SceltaRiconoscimento.catenaAutomatica.first ?? .classico) : ruby.riconoscimento
        let a = ascoltoRuby
        a.azzera()
        mini.ascoltoMio = true
        a.concluso = { [weak self] frase in
            guard let self else { return }
            self.miniRuby.ascoltoMio = false
            self.fraseDettaMiniRuby(frase)
        }
        a.problema = { [weak self] motivo in
            guard let self else { return }
            self.miniRuby.ascoltoMio = false
            guard self.miniRuby.visibile else { return }
            self.miniRuby.vai(.scrivi)
            self.miniRuby.nota = motivo
        }
        a.avvia(scelta)
    }

    /// ⌥ Spazio lasciato (o il microfono premuto di nuovo): Ruby chiude la frase e risponde.
    func fineAscoltoMiniRuby() {
        let mini = miniRuby
        guard persistente, mini.ascoltoMio, let a = ascoltoRubySeNato else { return }
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
    func alternaAscoltoMiniRuby() {
        if miniRuby.ascoltoMio, ascoltoRubySeNato?.ascolta == true { fineAscoltoMiniRuby() } else { ascoltaMiniRuby() }
    }

    private func fraseDettaMiniRuby(_ frase: String) {
        guard miniRuby.visibile else { return }
        if CongedoRuby.e(frase) { return chiudiMiniRuby() }
        inviaMiniRuby(DomandaMiniRuby(testo: frase, aVoce: true))
    }

    // MARK: - Domanda e risposta

    /// Qwen può rispondere (o la domanda è un comando, che fa Prisma da sola)?
    private func prontaPer(_ testo: String) -> Bool {
        if rispostePreparate || generativo != nil || appuntamentoInSospeso != nil { return true }
        let noti = dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        return InterpreteComandi.interpreta(testo, clienti: noti, attivo: rubyPortafoglio ? nil : clienteAttivoId) != nil
    }

    /// Manda una domanda: pensa, poi risponde nella scheda. Se Qwen non è pronto la mette da parte e lo sveglia.
    func inviaMiniRuby(_ d: DomandaMiniRuby) {
        let mini = miniRuby
        let testo = d.testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !testo.isEmpty else { return }
        guard !rubyInCorso else {
            mini.vai(.scrivi)
            mini.nota = "Sto ancora rispondendo nell'app Ruby: un attimo e ci sono."
            return
        }
        mini.testo = ""
        mini.nota = nil
        // Senza gettone (o con uno spunto del portafoglio) Ruby parla del portafoglio; in modalità cliente mai
        let suPortafoglio = !inModoCliente && (d.portafoglio != nil || mini.contesto == nil)
        if !suPortafoglio, let c = mini.contesto, clienteAttivoId != c.clienteId { clienteAttivoId = c.clienteId }
        // La stessa conversazione dell'app Ruby: la freccia la apre lì
        if rubyPortafoglio != suPortafoglio { rubyPortafoglio = suPortafoglio }
        mini.domanda = testo
        guard prontaPer(testo) else {
            mini.pendente = DomandaMiniRuby(testo: testo, spunto: d.spunto, portafoglio: d.portafoglio, aVoce: d.aVoce)
            mini.nonPronta(motivo: nil)
            preparaQwenMiniRuby()
            return
        }
        mini.pendente = nil
        let id = chiaveConversazione
        let fonte = suPortafoglio ? nil : fonteRuby(id)
        let modalita = suPortafoglio ? ModalitaRuby.lavoro
            : NucleoRuby.modalita(domanda: testo, spunto: d.spunto, cliente: fonte?.cliente, storia: conversazione(id))
        mini.chiave = id
        mini.messaggiPrima = conversazione(id).count
        mini.pensa(testo, passi: StatoMiniRuby.passi(domanda: testo, fonte: fonte, modalita: modalita))
        let cifre = CifreMiniRuby.calcola(domanda: testo, fonte: fonte, modalita: modalita, app: mini.contesto?.app)
        if d.aVoce { rispostaAVoce = dati.impostazioni.ruby.risposteAVoce != .mai }
        // Nella mini finestra la risposta è breve: le cifre le mostra la scheda (linea del tempo, righe, fonte)
        let partita = suPortafoglio ? chiediRubyPortafoglio(testo, spunto: d.portafoglio, breve: true)
                                    : chiediRuby(testo, spunto: d.spunto, breve: true)
        guard partita else {
            rispostaAVoce = false
            mini.vai(.scrivi)
            mini.nota = "La domanda non è partita: riprova tra un attimo."
            return
        }
        seguiRispostaMiniRuby(cifre)
    }

    /// Segue la risposta: le parole che arrivano (FlussoRuby) e il messaggio finale nella conversazione.
    private func seguiRispostaMiniRuby(_ cifre: CifreMiniRuby) {
        let mini = miniRuby
        mini.abbonamenti.removeAll()
        if concludiMiniRuby(cifre) { return }
        flussoRuby.$testo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] t in
                guard let self, self.rubyInCorso, !t.isEmpty, mini.fase == .pensa || mini.fase == .risponde else { return }
                mini.rispondi(testo: t.trimmingCharacters(in: .whitespacesAndNewlines), titolo: nil, cifre: cifre, inArrivo: true)
            }
            .store(in: &mini.abbonamenti)
        // Al giro dopo: conQwen spegne e riaccende `rubyInCorso` nello stesso momento
        $rubyInCorso
            .removeDuplicates()
            .filter { !$0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in _ = self?.concludiMiniRuby(cifre) }
            .store(in: &mini.abbonamenti)
    }

    /// La risposta è nella conversazione: la scheda mostra il testo finale. false se non è ancora arrivata.
    @discardableResult
    func concludiMiniRuby(_ cifre: CifreMiniRuby) -> Bool {
        let mini = miniRuby
        let elenco = conversazione(mini.chiave)
        guard !rubyInCorso, elenco.count > mini.messaggiPrima, let m = elenco.last, m.autore == .ruby else { return false }
        mini.abbonamenti.removeAll()
        if m.titolo == "Qwen non è pronto" {
            mini.pendente = DomandaMiniRuby(testo: mini.domanda)
            mini.nonPronta(motivo: disponibilitaLocale.motivo)
            return true
        }
        var c = cifre
        if let s = m.scenario {
            // Lo scenario «E se…?»: la tabella prima/dopo di Prisma e i due pulsanti della scheda
            c = CifreMiniRuby()
            c.scenario = s
            c.fonte = "Cifre dai calcoli di Prisma, con le ipotesi di \(s.nomeCliente)"
            c.azioni = [AzioneMiniRuby(titolo: s.salvata ? "Nel dossier" : "Salva nel dossier", simbolo: s.salvata ? "checkmark" : "tray.and.arrow.down",
                                      tipo: .salvaScenario(m.id), primaria: !s.salvata),
                        AzioneMiniRuby(titolo: s.simulazione == nil ? "Apri in Analisi 360" : "Apri in Simulazioni", simbolo: "arrow.up.forward",
                                      tipo: .apriScenario(m.id))]
        } else if let a = m.azione {
            // Ruby ha fatto qualcosa (un appuntamento, un promemoria): il pulsante lo apre
            c = CifreMiniRuby()
            c.azioni = [AzioneMiniRuby(titolo: Self.titoloAzione(a), simbolo: "arrow.up.forward", tipo: .azioneRuby(a), primaria: true)]
        } else if m.titolo == "Ruby non ha potuto rispondere" || m.motore == StatoShell.motoreAzioni {
            c = CifreMiniRuby()
        }
        mini.rispondi(testo: NucleoRuby.pulisci(m.testo), titolo: m.titolo, cifre: c, inArrivo: false)
        return true
    }

    private static func titoloAzione(_ a: AzioneRuby) -> String {
        switch a.tipo {
        case .appuntamento: return "Apri in Agenda"
        // Attività è accorpata nell'Agenda: l'attività si apre nel giorno della sua scadenza
        case .attivita: return "Apri in Agenda"
        case .nota: return "Apri la nota"
        }
    }

    // MARK: - Qwen non pronto

    /// «Mi sto svegliando…»: apre Ollama se serve e carica il modello; poi manda la domanda rimasta da parte.
    func preparaQwenMiniRuby() {
        let mini = miniRuby
        guard persistente, !mini.preparazioneInCorso else { return }
        mini.preparazioneInCorso = true
        mini.motivoNonPronta = nil
        let ruby = dati.impostazioni.ruby
        Task.detached(priority: .userInitiated) {
            let d = await AvvioModello.prepara(ruby)
            await MainActor.run {
                if self.disponibilitaLocale != d { self.disponibilitaLocale = d }
                mini.preparazioneInCorso = false
                guard mini.visibile, mini.fase == .nonPronta else { return }
                if d.pronto {
                    if let p = mini.pendente { self.inviaMiniRuby(p) } else { mini.vai(.scrivi) }
                } else {
                    mini.motivoNonPronta = d.motivo
                }
            }
        }
    }

    /// «Riprova» nello stato non pronta.
    func riprovaMiniRuby() {
        if let p = miniRuby.pendente, prontaPer(p.testo) { return inviaMiniRuby(p) }
        preparaQwenMiniRuby()
    }

    // MARK: - Verso le app

    /// Un pulsante della risposta: porta Prisma davanti, apre l'app e chiude la mini finestra.
    func eseguiMiniRuby(_ a: AzioneMiniRuby) {
        let id = miniRuby.contesto?.clienteId
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
        case .azioneRuby(let e):
            apriAzioneRuby(e)
            commiato = a.titolo
        case .salvaScenario(let messaggio):
            // Il salvataggio ha già il suo avviso («Scenario salvato nel dossier di…»): niente commiato
            if let s = schedaScenario(messaggio: messaggio, chiave: miniRuby.chiave) { salvaScenarioRuby(s, messaggio: messaggio) }
            chiudiMiniRuby()
            return
        case .apriScenario(let messaggio):
            if let s = schedaScenario(messaggio: messaggio, chiave: miniRuby.chiave) { apriScenarioRuby(s) }
            commiato = a.titolo.hasSuffix("Simulazioni") ? "Ti porto nel simulatore con lo scenario" : "Ti porto in Analisi 360"
        }
        chiudiMiniRuby()
        // Il commiato (.toast del template): Ruby si ritira verso la sua sfera e dice dove ti ha portato
        mostraAvviso(commiato, daRuby: true)
    }

    /// La freccia: la stessa conversazione nell'app Ruby completa.
    func apriInRubyDaMiniRuby() {
        let mini = miniRuby
        portaDavantiPrisma()
        if !inModoCliente { rubyPortafoglio = mini.contesto == nil && mini.chiave == RubyPortafoglio.chiave }
        if let c = mini.contesto, clienteAttivoId != c.clienteId { clienteAttivoId = c.clienteId }
        apri(.ruby)
        chiudiMiniRuby()
    }

    /// Prisma in primo piano (la mini finestra non la attiva), senza la schermata di benvenuto davanti.
    private func portaDavantiPrisma() {
        guard persistente else { return }
        NSApp.activate(ignoringOtherApps: true)
        if let f = PannelloMiniRuby.finestraPrisma() {
            if f.isMiniaturized { f.deminiaturize(nil) }
            f.makeKeyAndOrderFront(nil)
        }
        if bloccato { sblocca() }
    }

    /// Le ultime domande fatte a Ruby (da tutte le conversazioni), le più recenti prima.
    func recentiMiniRuby(_ quante: Int = 2) -> [MessaggioRuby] {
        guard !inModoCliente else { return [] }
        let tutte = dati.impostazioni.ruby.conservaConversazioni ? dati.conversazioni : conversazioniTemporanee
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
