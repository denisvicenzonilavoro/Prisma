import Foundation

// La fase 3 di Vera nell'app (Vera/BRIEF.md): le promesse fatte ai clienti (8), la seconda lettura prima che un testo
// esca (10), il confronto tra due documenti (11), cosa non copre una polizza (12) e il resoconto dell'incontro (16).
// Sempre prima il codice di Prisma (regole, cifre, articoli); Qwen, se è pronto, scrive meglio e ogni sua riga passa
// il controllo (frase nella fonte, articolo citato, cifre conservate). Niente parte senza «Conferma» o «Firma».
extension StatoShell {
    static func primoNome(_ nome: String) -> String { nome.split(separator: " ").first.map(String.init) ?? nome }

    /// Il cliente di una richiesta in chat: quello nominato, altrimenti quello del dossier aperto (in modalità cliente
    /// sempre e solo quello davanti a te). nil se nel portafoglio non si capisce di chi.
    func clienteDellaRichiesta(_ testo: String, chiave: String) -> String? {
        if inModoCliente { return cliente(clienteAttivoId) == nil ? nil : clienteAttivoId }
        let noti = clientiAttivi.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let nominati = InterpreteComandi.clientiNominati(InterpreteComandi.pulisci(testo), noti)
        if nominati.count == 1 { return nominati[0].id }
        let aperto = chiave != VeraPortafoglio.chiave && cliente(chiave) != nil ? chiave : nil
        // Più clienti nominati: vale il dossier aperto solo se è tra loro, altrimenti Vera chiede di chi si parla
        if nominati.count > 1 { return aperto.flatMap { a in nominati.contains { $0.id == a } ? a : nil } }
        return aperto
    }

    /// In modalità cliente le schede della fase 3 mostrano solo il cliente davanti a te (le conversazioni salvate prima
    /// possono parlare di altri).
    func visibileAlCliente(_ clienteId: String) -> Bool {
        !inModoCliente || clienteId == clienteAttivoId
    }

    /// Apre un documento del cliente (il PDF del resoconto firmato) in Documenti.
    func apriDocumentoVera(_ id: String) {
        guard dati.documenti.contains(where: { $0.id == id }) else { return mostraAvviso("Il documento non è più in Prisma.") }
        documentoSelezionato = id
        apri(.documenti)
    }

    /// «Mostrami le promesse di Marco», «apri cosa non copre la polizza di Laura»: non sono «apri il dossier», sono la fase 3.
    func richiestaFaseTre(_ testo: String) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        return CoperturaVera.eUnaRichiesta(testo) || DifferenzeVera.eUnaRichiesta(testo)
            || DateItaliane.cerca(Self.richiestaPromesse, t) != nil || Self.eUnResoconto(t)
    }

    @discardableResult
    private func rispostaFaseTre(_ testo: String, titolo: String? = nil, chiave: String, motore: String? = nil,
                                 _ completa: (inout MessaggioVera) -> Void = { _ in }) -> MessaggioVera {
        var m = MessaggioVera(autore: .vera, testo: testo, titolo: titolo, motore: motore ?? MotoriVera.sintesi.nome)
        completa(&m)
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    private func opzioniBrevi(_ token: Int) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0.2
        o.contesto = NucleoVera.finestra
        o.massimoToken = token
        o.restaInMemoria = dati.impostazioni.vera.restaInMemoria
        return o
    }

    /// Qwen si usa solo se è pronto (e non nelle prove con le risposte preparate).
    private var qwenPerFaseTre: MotoreLocale? { generativo != nil && !rispostePreparate ? qwen : nil }

    // MARK: - 8 · Le promesse

    /// Le promesse da mantenere (aperte e rimandate), dalla più urgente; di un cliente o di tutti.
    func promesseAperte(cliente id: String? = nil) -> [PromessaCliente] {
        dati.promesse.filter { ($0.stato == .aperta || $0.stato == .rimandata) && (id == nil || $0.clienteId == id) }
            .sorted { ($0.scadenzaAttuale ?? .distantFuture, $0.creataIl) < ($1.scadenzaAttuale ?? .distantFuture, $1.creataIl) }
    }

    func fontiPromesse(_ id: String) -> [FontePromesse] {
        PromesseVera.fonti(cliente: id, note: noteCliente(id), incontri: incontriCliente(id), messaggi: dati.messaggi)
    }

    /// Le promesse trovate con le regole nelle fonti del cliente (sempre, senza Qwen): le nuove entrano nell'elenco.
    @discardableResult
    func raccogliPromesse(cliente id: String) -> [PromessaCliente] {
        guard !solaLettura, let c = cliente(id) else { return [] }
        let nome = Self.primoNome(c.nome)
        let trovate = fontiPromesse(id).flatMap { PromesseVera.conRegole($0, nome: nome) }
        let nuove = PromesseVera.nuove(trovate, esistenti: dati.promesse)
        if !nuove.isEmpty { dati.promesse += nuove }
        return nuove
    }

    /// Con Qwen: le fonti più recenti (al massimo sei), una alla volta; una promessa vale solo se la frase è nella fonte.
    func cercaPromesseConQwen(cliente id: String, motore: MotoreLocale) async -> [PromessaCliente] {
        guard let c = cliente(id) else { return [] }
        let nome = Self.primoNome(c.nome)
        var trovate: [PromessaCliente] = []
        for f in fontiPromesse(id).sorted(by: { $0.data > $1.data }).prefix(6) {
            guard !Task.isCancelled else { break }
            if let json = try? await motore.scrivi(PromesseVera.messaggi(f, nome: nome), opzioni: PromesseVera.opzioni(dati.impostazioni.vera)).testo,
               let p = PromesseVera.leggi(json, fonte: f) {
                trovate += p
            }
        }
        // Il cliente può essere stato tolto mentre Qwen leggeva
        guard !Task.isCancelled, cliente(id) != nil else { return [] }
        let nuove = PromesseVera.nuove(trovate, esistenti: dati.promesse)
        if !nuove.isEmpty, !solaLettura { dati.promesse += nuove }
        return nuove
    }

    func segnaPromessa(_ id: String, _ nuovo: PromessaCliente.Stato, oggi: Date = Date()) {
        guard !solaLettura, let i = dati.promesse.firstIndex(where: { $0.id == id }) else { return }
        dati.promesse[i].stato = nuovo
        dati.promesse[i].fattaIl = nuovo == .fatta ? oggi : nil
    }

    /// «Rimanda»: una settimana in più dalla scadenza (o da oggi, se è già passata).
    func rimandaPromessa(_ id: String, giorni: Int = 7, oggi: Date = Date()) {
        guard !solaLettura, let i = dati.promesse.firstIndex(where: { $0.id == id }) else { return }
        let base = max(Calendar.current.startOfDay(for: oggi), dati.promesse[i].scadenzaAttuale ?? oggi)
        dati.promesse[i].rimandataAl = Calendar.current.date(byAdding: .day, value: giorni, to: base)
        dati.promesse[i].stato = .rimandata
    }

    /// Il promemoria di una promessa: una scheda «Conferma» con l'attività per il giorno della scadenza.
    @discardableResult
    func promemoriaPromessa(_ id: String, chiave: String, oggi: Date = Date()) -> MessaggioVera? {
        guard let p = dati.promesse.first(where: { $0.id == id }), let c = cliente(p.clienteId) else { return nil }
        let quando = p.scadenzaAttuale ?? Calendar.current.startOfDay(for: oggi)
        let a = AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita, titolo: "Promemoria della promessa a \(c.nome)",
                               dettaglio: "«\(p.testo)» · entro il \(Formati.dataEstesa.string(from: quando))",
                               argomenti: ["cliente": c.id, "titolo": p.testo, "scadenza": RegistroStrumenti.isoData(quando)])
        return rispostaFaseTre("Ti preparo il promemoria: lo segno tra le attività solo con «Conferma».", chiave: chiave, motore: Self.motoreAzioni) {
            $0.conferma = SchedaConfermaVera(richiesta: "Promemoria: \(p.testo)", azioni: [a], origine: .regole)
        }
    }

    static let richiestaPromesse = #"\b(?:promess[ae]|cosa ho promesso|impegni presi|cosa devo (?:mandare|portare) a)\b"#

    /// Una frase che comincia con un verbo d'azione (anche con il pronome attaccato: «scrivigli», «mandagli») è per «Fallo tu».
    static let verboAzione = #"^(?:scrivi|manda|invia|spedisci|inoltra|gira|prepara|fissa|chiama|telefona|sposta|aggiungi|crea)(?:mi|gli|le|ci|lo|la|li|glielo|gliela|glieli)?\b"#

    /// «Le mie promesse», «promesse di Marco», «cerca le promesse di Sofia» (con Qwen).
    func chiediPromesse(_ testo: String, chiave: String) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        guard DateItaliane.cerca(Self.richiestaPromesse, t) != nil, DateItaliane.cerca(#"rendiment|garantit"#, t) == nil,
              // «Scrivi a Marco che manterrò la promessa» è un'azione per «Fallo tu», non l'elenco
              DateItaliane.cerca(Self.verboAzione, t) == nil else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        // «Le mie promesse» nel dossier sono comunque quelle con il cliente aperto; «tutte» le mostra tutte
        let tutte = !inModoCliente && DateItaliane.cerca(#"\btutte\b"#, t) != nil
        let id = tutte ? nil : clienteDellaRichiesta(testo, chiave: chiave)
        let clienti = id.map { [$0] } ?? dati.clienti.map(\.id)
        let nuove = clienti.flatMap { raccogliPromesse(cliente: $0) }.count
        if let id, DateItaliane.cerca(#"^(?:cerca|trova|rileggi|scova)"#, t) != nil, let motore = qwenPerFaseTre {
            veraInCorso = true
            compitoVera = Task { @MainActor in
                let altre = await self.cercaPromesseConQwen(cliente: id, motore: motore).count
                guard !Task.isCancelled else { return }
                self.rispondiPromesse(cliente: id, nuove: nuove + altre, chiave: chiave, motore: altre > 0 ? motore.nome : MotoriVera.sintesi.nome)
                self.veraInCorso = false
                self.compitoVera = nil
            }
        } else {
            rispondiPromesse(cliente: id, nuove: nuove, chiave: chiave, motore: MotoriVera.sintesi.nome)
        }
        return true
    }

    @discardableResult
    func rispondiPromesse(cliente id: String?, nuove: Int, chiave: String, motore: String, oggi: Date = Date()) -> MessaggioVera {
        let elenco = promesseAperte(cliente: id)
        let chi = id.flatMap { cliente($0)?.nome }
        var testo: String
        if elenco.isEmpty {
            testo = chi.map { "Non hai promesse aperte con \($0)." } ?? "Non hai promesse aperte."
        } else {
            let ritardo = elenco.filter { PromesseVera.semaforo($0, oggi: oggi) == .inRitardo }.count
            testo = (elenco.count == 1 ? "Una promessa aperta" : "\(elenco.count) promesse aperte") + (chi.map { " con \($0)" } ?? "")
            if ritardo > 0 { testo += ritardo == 1 ? ", una in ritardo" : ", \(ritardo) in ritardo" }
            testo += "."
        }
        if nuove > 0 {
            testo += nuove == 1 ? " Una l'ho appena trovata nelle note, negli incontri o nei messaggi." : " \(nuove) le ho appena trovate nelle note, negli incontri e nei messaggi."
        }
        return rispostaFaseTre(testo, titolo: "Le promesse", chiave: chiave, motore: motore) { $0.promesse = elenco.map(\.id) }
    }

    // MARK: - 10 · La seconda lettura

    /// Rilegge un testo con le fonti di Prisma: la scheda del cliente e il testo `fonti` con le cifre ammesse.
    func secondaLettura(_ testo: String, oggetto: String, cliente id: String?, fonti: String,
                        allegatiMancanti: [String] = [], controlli: [ControlloAdeguatezza] = []) -> EsitoSecondaLettura {
        SecondaLetturaVera.rileggi(testo, oggetto: oggetto, fonti: fonti, fonteCliente: id.flatMap { fonteVera($0) },
                                   allegatiMancanti: allegatiMancanti, controlli: controlli)
    }

    /// Un messaggio prima di aprirlo in Mail o in Messaggi: le cifre ammesse sono quelle dell'occasione e della scheda.
    func secondaLetturaMessaggio(_ o: OccasioneMessaggio, testo: String) -> EsitoSecondaLettura {
        let fonti = ([o.titolo, o.perche] + o.cifre.map { "\($0.etichetta): \($0.valore)" }).joined(separator: "\n")
        return secondaLettura(testo, oggetto: "Il messaggio per \(cliente(o.clienteId)?.nome ?? "il cliente")", cliente: o.clienteId, fonti: fonti)
    }

    /// Un prospetto o un report prima del PDF: le cifre le ha calcolate Prisma, si guardano le parole e il profilo.
    func secondaLetturaProspetto(_ testo: String, titolo: String, cliente id: String?) -> EsitoSecondaLettura {
        secondaLettura(testo, oggetto: titolo, cliente: id, fonti: testo)
    }

    /// La scheda di adeguatezza: la motivazione scritta, i controlli del profilo e i documenti da consegnare.
    func secondaLetturaAdeguatezza(_ p: Posizione) -> EsitoSecondaLettura? {
        guard let e = esitoAdeguatezza(p), let c = cliente(p.clienteId) else { return nil }
        let testo = schedaAdeguatezza(p.id)?.motivazione ?? ""
        return secondaLettura(testo, oggetto: "La scheda di adeguatezza di «\(p.nome)»", cliente: p.clienteId,
                              fonti: SecondaLetturaVera.bozzaMotivazione(e, cliente: c), allegatiMancanti: SecondaLetturaVera.mancanti(e),
                              controlli: e.controlli)
    }

    /// La bozza della motivazione: quella di Prisma, riscritta da Qwen se è pronto (stesse cifre, nessuna promessa).
    func bozzaMotivazione(_ p: Posizione) async -> (testo: String, conQwen: Bool)? {
        guard let e = esitoAdeguatezza(p), let c = cliente(p.clienteId) else { return nil }
        let bozza = SecondaLetturaVera.bozzaMotivazione(e, cliente: c)
        guard !bozza.isEmpty else { return nil }
        guard let motore = qwenPerFaseTre else { return (bozza, false) }
        if let r = try? await motore.scrivi(SecondaLetturaVera.messaggiMotivazione(bozza, cliente: c.nome), opzioni: opzioniBrevi(400)).testo
            .trimmingCharacters(in: .whitespacesAndNewlines), !r.isEmpty,
           CommentoVera.numeriConservati(bozza: bozza, testo: r), DateItaliane.cerca(MessaggiVera.promesse, r.lowercased()) == nil {
            return (r, true)
        }
        return (bozza, false)
    }

    /// «Rileggi: …» in chat (anche un testo scritto a mano): gli avvisi, la decisione resta tua.
    func chiediSecondaLettura(_ testo: String, chiave: String) -> Bool {
        guard let r = testo.range(of: #"^\s*(?:(?:ehi|ok|senti|ciao|vera|ruby|eve|per favore)[,\s]+)*(?:mi )?(?:rileggi|ricontrolla|seconda lettura(?: di| su)?)(?: (?:questo|questa|il|la|lo))?(?: (?:testo|messaggio|mail|e-mail|bozza|proposta|lettera))?\s*:\s*"#,
                                  options: [.regularExpression, .caseInsensitive]) else { return false }
        let daLeggere = String(testo[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard daLeggere.count >= 10 else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        let id = chiave != VeraPortafoglio.chiave && cliente(chiave) != nil ? chiave : nil
        let e = secondaLettura(daLeggere, oggetto: "Il testo", cliente: id, fonti: "")
        let n = e.daGuardare.count
        rispostaFaseTre(e.pulito ? "Riletto: nessuna frase a rischio e le cifre tornano con Prisma." :
                            "Riletto: \(n == 1 ? "una cosa da guardare" : "\(n) cose da guardare"). Ti propongo le correzioni, decidi tu.",
                        titolo: "La seconda lettura", chiave: chiave) { $0.lettura = e }
        return true
    }

    // MARK: - 11 · Trova le differenze

    func confrontaDocumenti(_ a: Documento, _ b: Documento, oggi: Date = Date()) -> ConfrontoDocumenti {
        let polizze: Set<Documento.Tipo> = [.polizza, .proposta]
        // Le coperture del confronto sempre con le sole regole, uguali per i due documenti (le voci riscritte da Qwen
        // per «Cosa non copre» farebbero sembrare diverse due clausole identiche)
        func regole(_ d: Documento) -> CoperturaPolizza? {
            guard polizze.contains(d.tipo) else { return nil }
            let pagine = testoDocumento(d)
            guard !pagine.joined().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return CoperturaVera.copertura(d, pagine: pagine)
        }
        let ca = regole(a), cb = regole(b)
        let righe = DifferenzeVera.righe(prima: a, ora: b, coperturePrima: ca, copertureOra: cb)
        let nome = Self.primoNome(cliente(a.clienteId)?.nome ?? "il cliente")
        return ConfrontoDocumenti(clienteId: a.clienteId, primaId: a.id, oraId: b.id, titoloPrima: a.titolo, titoloOra: b.titolo, righe: righe,
                                  sintesi: DifferenzeVera.sintesi(righe, cliente: nome), creatoIl: oggi)
    }

    /// Salva il confronto (lo stesso paio sostituisce quello di prima).
    func salvaConfronto(_ c: ConfrontoDocumenti) {
        guard !solaLettura, cliente(c.clienteId) != nil,
              dati.documenti.contains(where: { $0.id == c.primaId }), dati.documenti.contains(where: { $0.id == c.oraId }) else { return }
        dati.confrontiDocumenti.removeAll { $0.primaId == c.primaId && $0.oraId == c.oraId }
        dati.confrontiDocumenti.append(c)
    }

    func confronto(_ id: String?) -> ConfrontoDocumenti? {
        guard let id else { return nil }
        return dati.confrontiDocumenti.first { $0.id == id }
    }

    /// «Confronta il KID nuovo con il vecchio», «trova le differenze tra la polizza e la proposta di Marco».
    func chiediDifferenze(_ testo: String, chiave: String) -> Bool {
        guard DifferenzeVera.eUnaRichiesta(testo) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        guard let id = clienteDellaRichiesta(testo, chiave: chiave), let c = cliente(id) else {
            rispostaFaseTre("Di quale cliente confronto i documenti? Dimmi il nome, o apri il suo dossier.", chiave: chiave)
            return true
        }
        guard let (a, b) = DifferenzeVera.coppia(documentiCliente(id), frase: testo) else {
            rispostaFaseTre("Per confrontare servono due documenti letti dello stesso tipo nei Documenti di \(c.nome): due KID, oppure la polizza e la proposta.",
                            titolo: "Trova le differenze", chiave: chiave)
            return true
        }
        let confronto = confrontaDocumenti(a, b)
        func rispondi(_ x: ConfrontoDocumenti, motore: String) {
            salvaConfronto(x)
            rispostaFaseTre(x.sintesi, titolo: "«\(x.titoloPrima)» e «\(x.titoloOra)»", chiave: chiave, motore: motore) { $0.confronto = x.id }
        }
        guard !confronto.cambiate.isEmpty, let motore = qwenPerFaseTre else {
            rispondi(confronto, motore: MotoriVera.sintesi.nome)
            return true
        }
        veraInCorso = true
        compitoVera = Task { @MainActor in
            let tabella = confronto.righe.map { "\($0.voce): \($0.prima) → \($0.ora)" }.joined(separator: "\n") + "\n" + confronto.sintesi
            var finale = confronto
            if let r = try? await motore.scrivi(DifferenzeVera.messaggi(confronto.righe, sintesi: confronto.sintesi, cliente: Self.primoNome(c.nome)),
                                                opzioni: self.opzioniBrevi(300)).testo.trimmingCharacters(in: .whitespacesAndNewlines),
               !r.isEmpty, CommentoVera.numeriConservati(bozza: tabella, testo: r) {
                finale.sintesi = r
            }
            guard !Task.isCancelled else { return }
            rispondi(finale, motore: finale.sintesi == confronto.sintesi ? MotoriVera.sintesi.nome : motore.nome)
            self.veraInCorso = false
            self.compitoVera = nil
        }
        return true
    }

    // MARK: - 12 · Cosa non copre

    /// Le coperture di una polizza con le regole (salvate la prima volta). nil se il documento non ha testo.
    @discardableResult
    func coperturaPolizza(_ d: Documento) -> CoperturaPolizza? {
        if let c = dati.coperture.first(where: { $0.documentoId == d.id }) { return c }
        let pagine = testoDocumento(d)
        guard !pagine.joined().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let c = CoperturaVera.copertura(d, pagine: pagine)
        if c.articoliLetti > 0 { salvaCopertura(c) }
        return c
    }

    func salvaCopertura(_ c: CoperturaPolizza) {
        guard !solaLettura, cliente(c.clienteId) != nil, dati.documenti.contains(where: { $0.id == c.documentoId }) else { return }
        dati.coperture.removeAll { $0.documentoId == c.documentoId }
        dati.coperture.append(c)
    }

    func copertura(_ documentoId: String?) -> CoperturaPolizza? {
        guard let documentoId else { return nil }
        return dati.coperture.first { $0.documentoId == documentoId }
    }

    /// La polizza di una richiesta: quella con una parola del titolo nella frase, altrimenti l'ultima del cliente.
    func polizzaDellaRichiesta(_ testo: String, cliente id: String) -> Documento? {
        let polizze = documentiCliente(id).filter { $0.tipo == .polizza || $0.tipo == .proposta }.sorted { $0.importatoIl > $1.importatoIl }
        // Le parole del titolo che distinguono (non «polizza», «proposta», «condizioni»…): vince quella con più parole in comune
        let generiche: Set<String> = ["polizza", "polizze", "proposta", "condizioni", "contratto", "assicurazione", "simile", "facsimile", "generali"]
        let frase = Set(DifferenzeVera.normale(testo).split(separator: " ").map(String.init))
        let punteggi = polizze.map { d in
            (d, Set(DifferenzeVera.normale(d.titolo).split(separator: " ").map(String.init)).filter { $0.count >= 4 && !generiche.contains($0) }.intersection(frase).count)
        }
        let migliore = punteggi.max { $0.1 < $1.1 }
        if let m = migliore, m.1 > 0 { return punteggi.first { $0.1 == m.1 }?.0 }
        return polizze.first(where: { $0.tipo == .polizza }) ?? polizze.first
    }

    /// «Cosa non copre la polizza di Marco?», «esclusioni e franchigie dell'Infortuni famiglia».
    func chiediCopertura(_ testo: String, chiave: String) -> Bool {
        // «Scrivi a Laura cosa non copre la polizza» è un messaggio per «Fallo tu»
        guard CoperturaVera.eUnaRichiesta(testo), DateItaliane.cerca(Self.verboAzione, InterpreteComandi.pulisci(testo)) == nil else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        guard let id = clienteDellaRichiesta(testo, chiave: chiave), let c = cliente(id) else {
            rispostaFaseTre("Di quale cliente leggo la polizza? Dimmi il nome, o apri il suo dossier.", chiave: chiave)
            return true
        }
        guard let d = polizzaDellaRichiesta(testo, cliente: id) else {
            rispostaFaseTre("Nei Documenti di \(c.nome) non c'è una polizza o una proposta da leggere: trascinala su Vera e la archivio.",
                            titolo: "Cosa non copre", chiave: chiave)
            return true
        }
        let pagine = testoDocumento(d)
        guard !pagine.joined().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            rispostaFaseTre("«\(d.titolo)» non ha testo da leggere (forse è una scansione senza testo): non ti dico cosa non copre senza leggerlo.",
                            titolo: "Cosa non copre", chiave: chiave)
            return true
        }
        let base = CoperturaVera.copertura(d, pagine: pagine)
        guard base.articoliLetti > 0 else {
            rispostaFaseTre("In «\(d.titolo)» non trovo articoli numerati: Vera cita ogni limite con il suo articolo, quindi qui non risponde.",
                            titolo: "Cosa non copre", chiave: chiave)
            return true
        }
        func rispondi(_ x: CoperturaPolizza, motore: String) {
            salvaCopertura(x)
            let n = x.voci.count
            let testo = n == 0 ? "In «\(x.titolo)» non trovo esclusioni, carenze, franchigie o massimali negli \(x.articoliLetti) articoli letti."
                : "«\(x.titolo)»: \(n == 1 ? "un limite" : "\(n) limiti") negli \(x.articoliLetti) articoli letti, ognuno con il suo articolo."
            rispostaFaseTre(testo, titolo: "Cosa non copre", chiave: chiave, motore: motore) { $0.copertura = x.documentoId }
        }
        guard let motore = qwenPerFaseTre else {
            rispondi(base, motore: MotoriVera.sintesi.nome)
            return true
        }
        let articoli = CoperturaVera.articoliConLimiti(NormeVera.articoli(pagine, testoId: d.id).filter { !$0.numero.hasPrefix("pag.") })
        guard !articoli.isEmpty else {
            rispondi(base, motore: MotoriVera.sintesi.nome)
            return true
        }
        veraInCorso = true
        compitoVera = Task { @MainActor in
            let json = try? await motore.scrivi(CoperturaVera.messaggi(articoli, cliente: c.nome, polizza: d.titolo),
                                                opzioni: CoperturaVera.opzioni(self.dati.impostazioni.vera)).testo
            let voci = json.flatMap { CoperturaVera.leggi($0, articoli: articoli) }
            let finale = CoperturaVera.copertura(d, pagine: pagine, voci: voci)
            guard !Task.isCancelled else { return }
            rispondi(finale, motore: finale.conQwen ? motore.nome : MotoriVera.sintesi.nome)
            self.veraInCorso = false
            self.compitoVera = nil
        }
        return true
    }

    /// «Spiegalo al cliente»: la bozza del messaggio con le sue parole, da confermare (resta una bozza in Messaggi).
    @discardableResult
    func spiegaCoperturaAlCliente(_ documentoId: String, chiave: String) -> MessaggioVera? {
        guard let x = copertura(documentoId), !x.voci.isEmpty, let c = cliente(x.clienteId) else { return nil }
        let testo = CoperturaVera.messaggioCliente(x, nome: c.nome)
        let canale: CanaleMessaggio = c.email.isEmpty ? .messaggi : .mail
        let a = AzioneConferma(strumento: RegistroStrumenti.messaggiPrepara, app: .messaggi, titolo: "Preparo un messaggio per \(c.nome)",
                               dettaglio: RegistroStrumenti.dettaglioMessaggio(testo, canale: canale),
                               argomenti: ["cliente": c.id, "scopo": "copertura", "testo": testo, "canale": canale.rawValue])
        return rispostaFaseTre("Ecco il messaggio per \(c.nome), con l'articolo di ogni limite: con «Conferma» diventa una bozza in Messaggi.",
                               chiave: chiave, motore: Self.motoreAzioni) {
            $0.conferma = self.inStile(SchedaConfermaVera(richiesta: "Spiega a \(c.nome) cosa non copre «\(x.titolo)»", azioni: [a], origine: .regole))
        }
    }

    // MARK: - 16 · Il resoconto dell'incontro

    /// L'incontro di cui scrivere il resoconto: l'ultimo già avvenuto con qualcosa da raccontare, altrimenti l'ultimo
    /// avvenuto (o il più vicino, se nessuno è passato).
    func incontroPerResoconto(cliente id: String, oggi: Date = Date()) -> Incontro? {
        let tutti = incontriCliente(id)
        let passati = tutti.filter { $0.data <= oggi }
        // Prima un incontro con qualcosa da raccontare (concluso, con appunti, con il copilota o già un resoconto)
        let conContenuto = passati.first { i in
            i.stato == .concluso || !i.vuoto || i.resoconto != nil || dati.sessioniCopilota.contains { $0.incontroId == i.id }
        }
        return conContenuto ?? passati.first ?? tutti.last
    }

    /// L'incontro di una nota vocale: il più recente già cominciato (anche di oggi), senza saltare quelli senza appunti.
    func incontroPerNota(cliente id: String, oggi: Date = Date()) -> Incontro? {
        let tutti = incontriCliente(id)
        return tutti.first { $0.data <= oggi } ?? tutti.last
    }

    func preparaResoconto(_ incontroId: String, trascrizione: String? = nil, consenso: ConsensoCopilota? = nil) -> ResocontoIncontro? {
        guard let i = incontro(incontroId), let c = cliente(i.clienteId) else { return nil }
        let verbale = dati.sessioniCopilota.last(where: { $0.incontroId == i.id })?.verbale
        var r = ResocontoVera.componi(i, cliente: c, consulente: nomeUtente, verbale: verbale, trascrizione: trascrizione,
                                      analisiSalvata: dati.analisi[c.id] != nil)
        r.consenso = consenso
        return r
    }

    func salvaResoconto(_ r: ResocontoIncontro, incontro id: String) {
        // Un resoconto firmato nel frattempo non si sovrascrive
        guard !solaLettura, var i = incontro(id), i.resoconto?.firmato != true else { return }
        i.resoconto = r
        salvaIncontro(i)
    }

    /// «Breve» o «Completo»: cambia solo come si mostra e come va nel PDF.
    func formatoResoconto(_ id: String, _ f: ResocontoIncontro.Formato) {
        guard var r = incontro(id)?.resoconto, !r.firmato else { return }
        r.formato = f
        salvaResoconto(r, incontro: id)
    }

    /// Togli una riga prima della firma (✕): quello che non va nel resoconto non ci va.
    func togliRigaResoconto(_ id: String, sezione: Int, riga: Int) {
        guard var r = incontro(id)?.resoconto, !r.firmato, r.sezioni.indices.contains(sezione), r.sezioni[sezione].righe.indices.contains(riga) else { return }
        let tolta = r.sezioni[sezione].righe.remove(at: riga)
        // Anche dal «Breve», che prende le stesse righe: quello che hai tolto non torna nel PDF
        r.breve.removeAll { $0 == tolta || $0.hasPrefix(tolta) }
        salvaResoconto(r, incontro: id)
    }

    /// Il resoconto di un incontro (con la parola dell'incontro), non quello delle posizioni («dammi il resoconto delle
    /// posizioni di Marco»), e non un'azione per «Fallo tu» («manda a Marco il resoconto», «scrivi una mail con il resoconto»).
    static func eUnResoconto(_ t: String) -> Bool {
        DateItaliane.cerca(#"\bresocont[oi]\b"#, t) != nil
            && DateItaliane.cerca(#"\b(?:incontr\w*|appuntament\w*|colloqui\w*|riunion\w*|visita|chiacchierata)\b"#, t) != nil
            && DateItaliane.cerca(verboAzione, t) == nil
            && DateItaliane.cerca(#"\b(?:messaggio|mail|e-mail|email|sms|whatsapp)\b"#, t) == nil
            && DateItaliane.cerca(#"\bresocont[oi] (?:delle|dei|del|degli|di) (?:posizion|portafogl|rendiment|andament|patrimon|investiment)\w*"#, t) == nil
    }

    /// «Il resoconto dell'incontro con Marco», «scrivi il resoconto».
    func chiediResoconto(_ testo: String, chiave: String) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        guard Self.eUnResoconto(t) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        guard let id = clienteDellaRichiesta(testo, chiave: chiave), let c = cliente(id) else {
            rispostaFaseTre("Di quale cliente scrivo il resoconto? Dimmi il nome, o apri il suo dossier.", chiave: chiave)
            return true
        }
        guard let i = incontroPerResoconto(cliente: id) else {
            rispostaFaseTre("Con \(c.nome) non c'è ancora un incontro in Prisma: il resoconto parte dagli appunti dell'incontro, dal copilota o da una nota vocale.",
                            titolo: "Il resoconto", chiave: chiave)
            return true
        }
        if let r = i.resoconto, r.firmato {
            rispostaFaseTre("Il resoconto di «\(i.titolo)» è già firmato\(r.firmatoIl.map { " il \(Formati.dataEstesa.string(from: $0))" } ?? ""): il PDF è nei Documenti di \(c.nome).",
                            titolo: "Il resoconto", chiave: chiave) { $0.resoconto = i.id }
            return true
        }
        // Un resoconto già pronto (magari rivisto con ✕) si mostra com'è: non si ricompone sopra le tue modifiche
        if i.resoconto != nil {
            rispostaFaseTre("Ecco il resoconto di «\(i.titolo)», com'è adesso: con «Firma» diventa un PDF nei Documenti di \(c.nome).",
                            titolo: "Il resoconto", chiave: chiave) { $0.resoconto = i.id }
            return true
        }
        componiResoconto(i.id, trascrizione: nil, consenso: nil, chiave: chiave)
        return true
    }

    /// Compone il resoconto (Prisma), lo fa riscrivere a Qwen se è pronto (cifre controllate) e lo mostra in chat.
    func componiResoconto(_ incontroId: String, trascrizione: String?, consenso: ConsensoCopilota?, chiave: String) {
        guard let r = preparaResoconto(incontroId, trascrizione: trascrizione, consenso: consenso), let i = incontro(incontroId),
              let c = cliente(i.clienteId) else { return }
        func rispondi(_ x: ResocontoIncontro, motore: String) {
            salvaResoconto(x, incontro: incontroId)
            rispostaFaseTre("Il resoconto di «\(i.titolo)» è pronto: rivedilo, togli quello che non va e con «Firma» diventa un PDF nei Documenti di \(c.nome).",
                            titolo: "Il resoconto", chiave: chiave, motore: motore) { $0.resoconto = incontroId }
        }
        guard let motore = qwenPerFaseTre else {
            rispondi(r, motore: MotoriVera.sintesi.nome)
            return
        }
        veraInCorso = true
        compitoVera = Task { @MainActor in
            let json = try? await motore.scrivi(ResocontoVera.messaggi(r, cliente: c.nome), opzioni: ResocontoVera.opzioni(self.dati.impostazioni.vera)).testo
            let finale = json.map { ResocontoVera.applica($0, a: r) } ?? r
            guard !Task.isCancelled else { return }
            rispondi(finale, motore: finale.conQwen ? motore.nome : MotoriVera.sintesi.nome)
            self.veraInCorso = false
            self.compitoVera = nil
        }
    }

    /// «Manda una sintesi a …» (template «Il resoconto dell'incontro»): la sintesi per il cliente (decisioni e prossimi
    /// passi del resoconto) come bozza in Messaggi, nello stile del consulente, dalla scheda «Conferma». Niente parte da
    /// sola; mai in modalità cliente.
    @discardableResult
    func mandaSintesiResoconto(_ incontroId: String, chiave: String) -> MessaggioVera? {
        guard !inModoCliente, let i = incontro(incontroId), let r = i.resoconto, let c = cliente(i.clienteId),
              let testo = ResocontoVera.sintesiCliente(r, incontro: i, nome: c.nome) else { return nil }
        let canale: CanaleMessaggio = c.email.isEmpty ? .messaggi : .mail
        let a = AzioneConferma(strumento: RegistroStrumenti.messaggiPrepara, app: .messaggi, titolo: "Preparo la sintesi per \(c.nome)",
                               dettaglio: RegistroStrumenti.dettaglioMessaggio(testo, canale: canale),
                               argomenti: ["cliente": c.id, "scopo": "resoconto", "testo": testo, "canale": canale.rawValue])
        return rispostaFaseTre("Ecco la sintesi di «\(i.titolo)» per \(c.nome), con le decisioni e i prossimi passi del resoconto: con «Conferma» diventa una bozza in Messaggi, nel tuo stile.",
                               chiave: chiave, motore: Self.motoreAzioni) {
            $0.conferma = self.inStile(SchedaConfermaVera(richiesta: "Manda a \(c.nome) una sintesi dell'incontro", azioni: [a], origine: .regole))
        }
    }

    /// «Firma»: nome e data, il PDF nei Documenti del cliente, le promesse raccolte. La trascrizione non resta.
    @discardableResult
    func firmaResoconto(_ incontroId: String, oggi: Date = Date()) -> String? {
        guard !solaLettura, var i = incontro(incontroId), var r = i.resoconto, !r.firmato, let c = cliente(i.clienteId) else { return nil }
        r.firmatoIl = oggi
        r.firmatoDa = nomeUtente
        let documento = DocumentoStampabile(ResocontoVera.contenuto(r, incontro: i, cliente: c.nome))
        // Si firma dal pulsante e dalle prove, sempre sul thread principale (il PDF si disegna con SwiftUI)
        guard let pdf = MainActor.assumeIsolated({ StampaCarta.pdf(documento) }) else {
            mostraAvviso("Non sono riuscita a creare il PDF del resoconto: riprova.")
            return nil
        }
        guard let documentoId = archiviaProspetto(pdf, documento: documento, cliente: c.id) else { return nil }
        r.documentoId = documentoId
        // Le promesse dette nella nota vocale, prima che la trascrizione vada via
        if let t = r.trascrizione, !t.isEmpty {
            let f = FontePromesse(clienteId: c.id, tipo: .resoconto, id: i.id + "-resoconto", etichetta: "dalla nota vocale del \(Formati.giornoMese.string(from: i.data))",
                                  data: i.data, testo: t)
            dati.promesse += PromesseVera.nuove(PromesseVera.conRegole(f, nome: Self.primoNome(c.nome)), esistenti: dati.promesse)
        }
        r.trascrizione = nil
        i.resoconto = r
        salvaIncontro(i)
        raccogliPromesse(cliente: c.id)
        return r.documentoId
    }

    /// Dopo la firma: i prossimi passi come attività, da confermare (al massimo quattro).
    @discardableResult
    func proponiPassiResoconto(_ incontroId: String, chiave: String, oggi: Date = Date()) -> MessaggioVera? {
        guard let i = incontro(incontroId), let r = i.resoconto, let c = cliente(i.clienteId),
              let passi = r.sezioni.first(where: { $0.titolo == ResocontoVera.titoliSezioni[3] })?.righe, !passi.isEmpty else { return nil }
        let entro = i.scadenzaAttivita ?? Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfDay(for: oggi)) ?? oggi
        let azioni = passi.filter { !$0.hasPrefix("Prossimo incontro") }.prefix(4).map { p in
            AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita, titolo: "Segno un'attività per \(c.nome)",
                           dettaglio: "«\(p)» · entro il \(Formati.dataEstesa.string(from: entro))",
                           argomenti: ["cliente": c.id, "titolo": String(p.prefix(120)), "scadenza": RegistroStrumenti.isoData(entro)])
        }
        guard !azioni.isEmpty else { return nil }
        return rispostaFaseTre("Firmato: il PDF è nei Documenti di \(c.nome). Segno anche i prossimi passi tra le attività?", chiave: chiave, motore: Self.motoreAzioni) {
            $0.conferma = SchedaConfermaVera(richiesta: "I prossimi passi di «\(i.titolo)»", azioni: Array(azioni), origine: .regole)
        }
    }

    /// Una nota vocale trascinata su Vera (m4a, mp3, wav, fino a 60 minuti): con il consenso del cliente alla
    /// registrazione, si trascrive sul Mac e diventa il resoconto del suo ultimo incontro. L'audio non si salva.
    func notaVocale(_ url: URL, chiave: String) {
        guard !veraInCorso else { return mostraAvviso("Vera sta ancora rispondendo: trascina la nota vocale tra poco.") }
        if !aperta(.vera) { apri(.vera) }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "🎙 \(url.lastPathComponent)"), cliente: chiave, parla: false)
        guard let id = chiave != VeraPortafoglio.chiave && cliente(chiave) != nil ? chiave : nil, let c = cliente(id) else {
            rispostaFaseTre("Apri prima il dossier del cliente: la nota vocale diventa il resoconto di un suo incontro.", titolo: "La nota vocale", chiave: chiave)
            return
        }
        if let motivo = GuardiaCopilota.motivoBlocco(c) {
            rispostaFaseTre(motivo.replacingOccurrences(of: "accendere il copilota", with: "trascrivere la nota vocale")
                                .replacingOccurrences(of: "all’ascolto", with: "alla registrazione"),
                            titolo: "La nota vocale", chiave: chiave)
            return
        }
        guard let i = incontroPerNota(cliente: id) else {
            rispostaFaseTre("Con \(c.nome) non c'è ancora un incontro: crealo in Incontri, poi trascina di nuovo la nota vocale.", titolo: "La nota vocale", chiave: chiave)
            return
        }
        if i.resoconto?.firmato == true {
            rispostaFaseTre("Il resoconto di «\(i.titolo)» è già firmato: la nota vocale non lo cambia.", titolo: "La nota vocale", chiave: chiave)
            return
        }
        veraInCorso = true
        compitoVera = Task { @MainActor in
            do {
                let testo = try await TrascrizioneFile.trascrivi(url)
                guard !Task.isCancelled else { return }
                self.veraInCorso = false
                self.compitoVera = nil
                guard !testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    self.rispostaFaseTre("Nella nota vocale non ho sentito parole: controlla il file.", titolo: "La nota vocale", chiave: chiave)
                    return
                }
                if i.resoconto != nil {
                    self.rispostaFaseTre("Riscrivo il resoconto di «\(i.titolo)» con la nota vocale: rivedilo di nuovo prima di firmare.", chiave: chiave)
                }
                self.componiResoconto(i.id, trascrizione: testo, consenso: c.consensoCopilota, chiave: chiave)
            } catch is CancellationError {
            } catch {
                self.veraInCorso = false
                self.compitoVera = nil
                self.rispostaFaseTre(error.localizedDescription, titolo: "La nota vocale", chiave: chiave)
            }
        }
    }
}
