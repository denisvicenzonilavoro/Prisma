import Foundation

// «Tre livelli» nell'app (Vera/BRIEF.md, funzione 17; template «// 17 · TRE LIVELLI»): la stessa spiegazione per il
// consulente (tecnica), per il cliente (semplice, con il tu) e in una pagina da consegnare, con gli STESSI numeri.
// Prima il codice di Prisma (TreLivelliVera.bozza: le cifre dei motori, già scritte); poi Qwen, se è pronto, riscrive i
// tre livelli e ogni livello che non passa il controllo delle cifre resta quello di Prisma. La spiegazione si salva
// nell'archivio (DatiPrisma.spiegazioniTreLivelli, per cliente) e la scheda in chat la legge per id. Il PDF della pagina
// e il messaggio al cliente passano sempre dalla scheda «Conferma»: Vera non salva e non manda niente da sola.
extension StatoShell {
    /// Lo strumento della scheda «Conferma» che salva la pagina come PDF nei Documenti del cliente (non è nel registro
    /// di Qwen: lo propone solo il pulsante della scheda).
    static let trelivelliStrumentoPagina = "trelivelli_salva_pagina"

    /// Le spiegazioni conservate per cliente (le più vecchie vanno via): poche, l'archivio resta leggero.
    static let trelivelliMassimoPerCliente = 20

    /// Le richieste che vanno alle norme della biblioteca («spiegami l'articolo 8 sul fondo pensione») e non qui.
    static let trelivelliNorme = #"\b(?:articol\w*|art\.?\s*\d+|comm[ai]|decret\w*|d\.?\s?lgs|legge|norm[ae]|tuir)\b"#

    /// Le azioni per «Fallo tu» («scrivi a Marco perché il fondo pensione conviene»): «prepara» resta qui («preparami
    /// la pagina del fondo pensione di Marco»).
    static let trelivelliAzioni = #"^(?:scrivi|manda|invia|spedisci|inoltra|gira|fissa|chiama|telefona|sposta|aggiungi|crea)(?:mi|gli|le|ci|lo|la|li|glielo|gliela|glieli)?\b"#

    /// Qwen si usa solo se è pronto (e non nelle prove e nelle istantanee con le risposte preparate).
    private var qwenPerTreLivelli: MotoreLocale? { generativo != nil && !rispostePreparate ? qwen : nil }

    // MARK: - Lettura

    /// Una spiegazione salvata (nil se non c'è più o se in modalità cliente è di un altro cliente).
    func trelivelliSpiegazione(_ id: String?) -> SpiegazioneTreLivelli? {
        guard let id, let s = dati.spiegazioniTreLivelli.first(where: { $0.id == id }), visibileAlCliente(s.clienteId) else { return nil }
        return s
    }

    /// Le spiegazioni di un cliente, dalla più recente.
    func trelivelliSpiegazioni(cliente id: String) -> [SpiegazioneTreLivelli] {
        dati.spiegazioniTreLivelli.filter { $0.clienteId == id }.reversed()
    }

    // MARK: - Salvataggio

    /// Salva (o sostituisce) una spiegazione; per ogni cliente restano le ultime `trelivelliMassimoPerCliente`.
    func trelivelliSalva(_ s: SpiegazioneTreLivelli) {
        guard !solaLettura, cliente(s.clienteId) != nil else { return }
        var x = s
        // Al minuto, come i messaggi: la copia riletta dall'archivio è uguale a quella in memoria
        x.creataIl = Appuntamento.alMinuto(s.creataIl)
        var elenco = dati.spiegazioniTreLivelli
        elenco.removeAll { $0.id == x.id }
        elenco.append(x)
        let mie = elenco.filter { $0.clienteId == x.clienteId }
        if mie.count > Self.trelivelliMassimoPerCliente {
            let via = Set(mie.prefix(mie.count - Self.trelivelliMassimoPerCliente).map(\.id))
            elenco.removeAll { via.contains($0.id) }
        }
        dati.spiegazioniTreLivelli = elenco
    }

    /// Toglie una spiegazione (dalla scheda, «Togli»): la risposta in chat resta, senza la scheda.
    func trelivelliTogli(_ id: String) {
        guard !solaLettura else { return }
        dati.spiegazioniTreLivelli.removeAll { $0.id == id }
    }

    // MARK: - In chat

    /// «Perché il fondo pensione conviene a Marco?», «la protezione di Giulia in tre livelli», «la liquidità di Sofia in
    /// una pagina». Serve un cliente (nominato o del dossier aperto): senza, la frase va alla chat di sempre.
    func chiediTreLivelli(_ testo: String, chiave: String) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        let frase = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        // Gli spunti pronti («Spiegami il piano pensione») restano alla chat di sempre, con il loro quadro
        guard !SpuntoVera.allCases.contains(where: { $0.domanda.caseInsensitiveCompare(frase) == .orderedSame }),
              TreLivelliVera.eUnaRichiesta(testo),
              DateItaliane.cerca(Self.trelivelliAzioni, t) == nil,
              DateItaliane.cerca(Self.trelivelliNorme, t) == nil,
              let argomento = TreLivelliVera.argomento(testo),
              let id = clienteDellaRichiesta(testo, chiave: chiave), cliente(id) != nil else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        trelivelliSpiega(argomento, cliente: id, domanda: testo, livello: TreLivelliVera.livelloChiesto(testo), chiave: chiave)
        return true
    }

    /// La bozza di Prisma, riscritta da Qwen se è pronto (livelli controllati uno per uno), salvata e mostrata in chat.
    func trelivelliSpiega(_ argomento: ArgomentoTreLivelli, cliente id: String, domanda: String, livello: LivelloTreLivelli, chiave: String) {
        guard let f = fonteVera(id) else { return }
        let bozza = TreLivelliVera.bozza(argomento, TreLivelliVera.fonte(f), domanda: domanda)
        guard let motore = qwenPerTreLivelli else {
            trelivelliRispondi(bozza, livello: livello, chiave: chiave, motore: MotoriVera.sintesi.nome)
            return
        }
        let vera = dati.impostazioni.vera
        veraInCorso = true
        compitoVera = Task { @MainActor in
            let json = try? await motore.scrivi(TreLivelliVera.messaggi(bozza), opzioni: TreLivelliVera.opzioni(vera)).testo
            let finale = json.map { TreLivelliVera.leggi($0, bozza: bozza) } ?? bozza
            guard !Task.isCancelled else { return }
            // Il cliente può essere stato tolto mentre Qwen scriveva
            if self.cliente(id) != nil {
                self.trelivelliRispondi(finale, livello: livello, chiave: chiave, motore: finale.conQwen ? motore.nome : MotoriVera.sintesi.nome)
            }
            self.veraInCorso = false
            self.compitoVera = nil
        }
    }

    /// La risposta in chat con la scheda dei tre livelli (aperta sul livello chiesto). In sola lettura la spiegazione non
    /// si salva: la risposta porta il testo del livello chiesto, senza scheda.
    @discardableResult
    func trelivelliRispondi(_ s: SpiegazioneTreLivelli, livello: LivelloTreLivelli, chiave: String, motore: String) -> MessaggioVera {
        let r = TreLivelliVera.risposta(s, livello: livello)
        let nome = Self.primoNome(s.nomeCliente)
        guard !solaLettura else {
            let m = MessaggioVera(autore: .vera, testo: r.testo, titolo: r.titolo, motore: motore)
            aggiungiMessaggio(m, cliente: chiave)
            return m
        }
        trelivelliSalva(s)
        var testo = "La stessa spiegazione in tre versioni: per te, per \(nome) e in una pagina da consegnare. I numeri sono di Prisma, uguali in tutte e tre."
        if !TreLivelliVera.stessiNumeri(s) {
            testo += " Attenzione: le cifre dei tre livelli non tornano, rileggi prima di usarle."
        }
        var m = MessaggioVera(autore: .vera, testo: testo, titolo: r.titolo, motore: motore)
        m.treLivelli = s.id
        m.treLivelliLivello = livello
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    // MARK: - Manda al cliente (scheda «Conferma»)

    /// «Manda a Marco»: la bozza del messaggio con la versione semplice, da confermare (resta una bozza in Messaggi).
    @discardableResult
    func trelivelliProponiManda(_ id: String, chiave: String) -> MessaggioVera? {
        guard !inModoCliente, let s = trelivelliSpiegazione(id), let c = cliente(s.clienteId) else { return nil }
        let a = TreLivelliVera.azioneManda(s, cliente: c)
        var m = MessaggioVera(autore: .vera, testo: "Ecco il messaggio per \(c.nome) con la versione semplice: con «Conferma» diventa una bozza in Messaggi, la spedisci tu.",
                              motore: Self.motoreAzioni)
        m.conferma = SchedaConfermaVera(richiesta: "Manda a \(c.nome) la spiegazione semplice: \(s.argomento.nome.lowercased())", azioni: [a], origine: .regole)
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    // MARK: - La pagina in PDF (scheda «Conferma»)

    /// «Salva nei Documenti»: la scheda «Conferma» con il PDF della pagina su carta bianca.
    @discardableResult
    func trelivelliProponiPagina(_ id: String, chiave: String) -> MessaggioVera? {
        guard let s = trelivelliSpiegazione(id), let c = cliente(s.clienteId) else { return nil }
        let a = AzioneConferma(strumento: Self.trelivelliStrumentoPagina, app: .documenti,
                               titolo: "Salvo la pagina nei Documenti di \(c.nome)",
                               dettaglio: "«\(s.pagina.titolo)» · PDF su carta bianca, con l'avvertenza in fondo",
                               argomenti: ["cliente": c.id, "spiegazione": s.id],
                               avviso: TreLivelliVera.stessiNumeri(s) ? nil : "Le cifre dei tre livelli non tornano: rileggi prima di salvare.")
        var m = MessaggioVera(autore: .vera, testo: "Preparo il PDF della pagina per \(c.nome): va nei suoi Documenti solo con «Conferma».",
                              motore: Self.motoreAzioni)
        m.conferma = SchedaConfermaVera(richiesta: "Salva «\(s.pagina.titolo)» nei Documenti di \(c.nome)", azioni: [a], origine: .regole)
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    /// Dopo «Conferma» (da `eseguiAzioneVera`): il PDF della pagina nei Documenti del cliente.
    func trelivelliEseguiPagina(_ a: AzioneConferma) -> EsitoAzioneVera {
        let no = { (m: String) in EsitoAzioneVera(fatta: false, messaggio: m) }
        guard !solaLettura else { return no("Prisma è in sola lettura: non ho salvato niente.") }
        guard let id = a.argomenti["spiegazione"], let s = trelivelliSpiegazione(id), let c = cliente(s.clienteId) else {
            return no("La spiegazione non è più in Prisma: chiedila di nuovo a Vera.")
        }
        if inModoCliente, c.id != clienteAttivoId { return no("In modalità cliente resto sul dossier di \(clienteAttivo?.nome ?? "questo cliente").") }
        let documento = DocumentoStampabile(TreLivelliVera.contenuto(s))
        // Si conferma dal pulsante e dalle prove, sempre sul thread principale (il PDF si disegna con SwiftUI)
        guard let pdf = MainActor.assumeIsolated({ StampaCarta.pdf(documento) }) else {
            return no("Non sono riuscita a creare il PDF della pagina: riprova.")
        }
        guard let documentoId = archiviaProspetto(pdf, documento: documento, cliente: c.id) else {
            return no("Non sono riuscita a salvare il PDF nei Documenti di \(c.nome).")
        }
        return EsitoAzioneVera(fatta: true, messaggio: "«\(s.pagina.titolo)» è nei Documenti di \(c.nome).", oggetto: documentoId)
    }

    /// «Annulla» (da `disfaAzioneVera`): il PDF salvato va via. true se c'era ancora.
    func trelivelliDisfaPagina(_ a: AzioneConferma) -> Bool {
        guard let id = a.esito?.oggetto, dati.documenti.contains(where: { $0.id == id }) else { return false }
        eliminaDocumento(id)
        return true
    }

    /// Il PDF salvato da una scheda «Conferma» di questa spiegazione (il più recente), se c'è ancora.
    func trelivelliDocumento(_ id: String) -> String? {
        guard let s = trelivelliSpiegazione(id) else { return nil }
        let titolo = "Prospetto · \(s.pagina.titolo)"
        return dati.documenti.filter { $0.clienteId == s.clienteId && $0.titolo == titolo }.max { $0.importatoIl < $1.importatoIl }?.id
    }
}
