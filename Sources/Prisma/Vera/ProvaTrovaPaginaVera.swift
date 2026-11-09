import Foundation

/// Prove della Biblioteca · «Trova la pagina» con Vera (Design/template-luce-specifica.md §8.1.5.2 punti 3 e 9, «Luce»
/// giro 6): la frase deve stare nel passo indicato (una risposta che cita una pagina che non contiene la frase si
/// rifiuta), una cifra che non è nel passo fa cadere la risposta, un nome di cliente aggiunto pure, «non trovata» quando
/// nessun passo risponde; con il Qwen finto (ServerFintoScenari) la richiesta porta i passi con l'etichetta, lo schema e
/// nessun dato dei clienti. Poi lo stato della Biblioteca: ricerca, risposta, senza Vera, citazione, fac-simile caricati
/// e tolti con i clienti di prova, la voce del pannello Novità. Chiamata da `ProvaVera.esegui()`.
enum ProvaTrovaPaginaVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.caricaEsempiBiblioteca()
        let documenti = s.biblioteca.tutti
        controlla(documenti.count == 6 && documenti.allSatisfy { $0.diProva == true && $0.testo != nil },
                  "Biblioteca: i sei fac-simile caricati con i clienti di prova (\(documenti.count))")
        let domanda = "Il riscatto nei primi anni ha penali?"
        var trovati: [PassoTrovato] = []
        s.trovaPagina.cerca(domanda) { t, _ in trovati = t }
        let passi = TrovaPaginaVera.passi(trovati, documenti: documenti)
        guard let p1 = passi.first, p1.passo.pagina == 14 else {
            return controlla(false, "Biblioteca: la ricerca sul riscatto trova la pagina 14 (\(passi.first?.passo.pagina ?? 0))")
        }
        let frase = "Fino al quinto anno di contratto si applica una penale dell'1% per ogni anno che manca al quinto."
        let buona = #"{"trovato":true,"passo":"P1","frase":"\#(frase)","risposta":"Sì: fino al quinto anno si paga una penale dell'1% per ogni anno che manca al quinto."}"#
        controlla(TrovaPaginaVera.leggi(buona, passi: passi, domanda: domanda) == .risposta(passo: p1.passo, frase: frase,
                  testo: "Sì: fino al quinto anno si paga una penale dell'1% per ogni anno che manca al quinto."),
                  "Biblioteca: la risposta con la frase del passo si mostra come citazione")
        // Una risposta che cita una pagina che non contiene la frase: rifiutata
        if let altro = passi.first(where: { MotoreBiblioteca.intervallo(frase, in: $0.passo.testo) == nil }) {
            let sbagliata = #"{"trovato":true,"passo":"\#(altro.etichetta)","frase":"\#(frase)","risposta":"Sì, c'è una penale."}"#
            if case .nonVerificata(let p, _)? = TrovaPaginaVera.leggi(sbagliata, passi: passi, domanda: domanda) {
                controlla(p == altro.passo, "Biblioteca: una risposta che cita una pagina senza la frase è rifiutata (si mostra il passo)")
            } else {
                controlla(false, "Biblioteca: una risposta che cita una pagina senza la frase è rifiutata")
            }
        }
        let inventata = #"{"trovato":true,"passo":"P1","frase":"Dal quinto anno in poi il riscatto non ha penali e paga il 3% in più.","risposta":"Dopo il quinto anno niente penali."}"#
        controlla(isNonVerificata(TrovaPaginaVera.leggi(inventata, passi: passi, domanda: domanda)),
                  "Biblioteca: una frase che il passo non dice è rifiutata")
        let cifra = #"{"trovato":true,"passo":"P1","frase":"\#(frase)","risposta":"Sì, una penale del 2% l'anno."}"#
        controlla(isNonVerificata(TrovaPaginaVera.leggi(cifra, passi: passi, domanda: domanda)),
                  "Biblioteca: una cifra che non è nel passo fa cadere la risposta")
        let nomi = s.dati.clienti.map(\.nome)
        let nome = #"{"trovato":true,"passo":"P1","frase":"\#(frase)","risposta":"Giulia paga una penale dell'1% per ogni anno che manca al quinto."}"#
        controlla(isNonVerificata(TrovaPaginaVera.leggi(nome, passi: passi, domanda: domanda, nomiClienti: nomi)),
                  "Biblioteca: un nome di cliente che non è nella domanda fa cadere la risposta")
        controlla(!isNonVerificata(TrovaPaginaVera.leggi(nome, passi: passi, domanda: "Giulia ha penali sul riscatto nei primi anni?", nomiClienti: nomi)),
                  "Biblioteca: il nome del cliente resta se è nella domanda")
        controlla(TrovaPaginaVera.leggi(#"{"trovato":false,"passo":"","frase":"","risposta":""}"#, passi: passi, domanda: domanda) == .nonTrovata,
                  "Biblioteca: «trovato: false» è lo stato «non trovata»")
        controlla(isNonVerificata(TrovaPaginaVera.leggi(#"{"trovato":true,"passo":"P9","frase":"\#(frase)","risposta":"Sì."}"#, passi: passi, domanda: domanda)),
                  "Biblioteca: un passo che Prisma non ha dato non vale")
        controlla(TrovaPaginaVera.leggi("niente JSON", passi: passi, domanda: domanda) == nil, "Biblioteca: un JSON guasto si scarta")

        qwenFinto(passi: passi, frase: frase, controlla)
        collegamenti(s, controlla)
        stato(s, frase: frase, controlla)
    }

    /// §8.1.5.2 punto 6: «Cerca nella Biblioteca» da Vera, il gruppo «Biblioteca» di «Cerca ovunque» e «Condizioni nella
    /// Biblioteca» dalla scheda del prodotto (con i sei fac-simile già caricati).
    private static func collegamenti(_ s: StatoShell, _ controlla: (Bool, String) -> Void) {
        let noti = s.dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let condizioni = ["Il riscatto nei primi anni ha penali?", "Quanto si deduce del fondo pensione?",
                          "Se Marco non paga la temporanea?", "Cosa dice la norma sul recesso?", "Ci sono carenze nella temporanea?"]
        let altre = ["Quanto ha Marco?", "Fammi un riepilogo del cliente", "Prepara il prossimo incontro",
                     "Il riscatto della polizza di Marco"]
        controlla(condizioni.allSatisfy { TrovaPaginaVera.proponeBiblioteca($0, clienti: noti) }
                    && !altre.contains { TrovaPaginaVera.proponeBiblioteca($0, clienti: noti) },
                  "Biblioteca: Vera propone «Cerca nella Biblioteca» solo per le domande su condizioni o normativa")
        #if os(macOS)
        let domanda = MessaggioVera(autore: .utente, testo: "Il riscatto nei primi anni ha penali?")
        let risposta = MessaggioVera(autore: .vera, testo: "Risposta di prova.")
        controlla(s.domandaPerBiblioteca(in: [domanda, risposta]) == domanda.testo
                    && s.domandaPerBiblioteca(in: [domanda]) == nil
                    && s.domandaPerBiblioteca(in: [MessaggioVera(autore: .utente, testo: "Quanto ha Marco?"), risposta]) == nil,
                  "Biblioteca: la proposta va sotto l'ultima risposta di Vera, con la domanda dell'utente")
        let vuota = StatoShell(persistente: false)
        controlla(vuota.domandaPerBiblioteca(in: [domanda, risposta]) == nil,
                  "Biblioteca: senza documenti nella Biblioteca Vera non propone di cercarci")
        s.cercaNellaBiblioteca(domanda.testo, subito: true)
        controlla(s.appAttiva == .biblioteca && s.trovaPagina.risultato?.passo?.pagina == 14,
                  "Biblioteca: «Cerca nella Biblioteca» apre la Biblioteca con la stessa ricerca (pagina 14)")

        // «Cerca ovunque»: il gruppo Biblioteca nei titoli e nel testo, aperto sulla pagina trovata
        let sezioni = MotoreRicerca.cerca("riscatto penali", in: s)
        let gruppo = sezioni.first { $0.gruppo == .biblioteca }
        if let primo = gruppo?.risultati.first, case .biblioteca(let id, let pagina) = primo.destinazione {
            controlla(pagina >= 1 && primo.estratto?.hasPrefix("pag. \(pagina):") == true,
                      "Cerca ovunque: il gruppo «Biblioteca» trova il testo delle pagine e ricorda la pagina (\(pagina))")
            s.vai(a: primo.destinazione)
            controlla(s.appAttiva == .biblioteca && s.trovaPagina.aperta == PaginaAperta(documentoId: id, pagina: pagina),
                      "Cerca ovunque: il risultato della Biblioteca apre il documento a quella pagina")
        } else {
            controlla(false, "Cerca ovunque: il gruppo «Biblioteca» trova «riscatto penali» nei fac-simile")
        }
        let titolo = MotoreRicerca.cerca("temporanea caso morte", in: s).first { $0.gruppo == .biblioteca }?.risultati.first
        controlla(titolo?.destinazione == DestinazioneRicerca.biblioteca(s.biblioteca.tutti.first(where: { $0.titolo.hasPrefix("Temporanea") })?.id ?? "", pagina: 1),
                  "Cerca ovunque: un titolo della Biblioteca si apre alla prima pagina")

        // «Condizioni nella Biblioteca» dalla scheda del prodotto collegato
        if let prodotto = s.dati.prodotti.first, let doc = s.biblioteca.tutti.first(where: { $0.titolo.hasPrefix("Piano rivalutabile") }) {
            controlla(s.condizioniInBiblioteca(prodotto.id) == nil, "Prodotti: senza documento collegato niente «Condizioni nella Biblioteca»")
            s.collegaProdottoBiblioteca(doc.id, prodotto: prodotto.id)
            s.apri(.prodotti)
            s.apriCondizioniInBiblioteca(prodotto.id)
            controlla(s.condizioniInBiblioteca(prodotto.id)?.id == doc.id && s.appAttiva == .biblioteca
                        && s.trovaPagina.aperta == PaginaAperta(documentoId: doc.id, pagina: 1),
                      "Prodotti: «Condizioni nella Biblioteca» apre il documento collegato")
            s.collegaProdottoBiblioteca(doc.id, prodotto: nil)
        } else {
            controlla(false, "Prodotti: servono un prodotto e il fac-simile del piano rivalutabile")
        }
        s.tornaAllaRisposta()
        #endif
    }

    private static func isNonVerificata(_ e: EsitoTrovaPagina?) -> Bool {
        if case .nonVerificata? = e { return true }
        return false
    }

    /// Il Qwen finto: la richiesta e la verifica sulla risposta vera del modello.
    private static func qwenFinto(passi: [PassoPerVera], frase: String, _ controlla: (Bool, String) -> Void) {
        let vera = ImpostazioniVera()
        let motore = MotoreLocale(vera, disponibilita: .pronto, sessione: ProvaPalestraVera.sessioneFinta())
        guard let altro = passi.first(where: { MotoreBiblioteca.intervallo(frase, in: $0.passo.testo) == nil }) else {
            return controlla(false, "Biblioteca, Qwen finto: serve un passo senza la frase")
        }
        let domanda = "Se Marco riscatta nei primi anni ha penali?"
        // Qwen cita una pagina che non contiene la frase: Prisma la rifiuta
        ServerFintoScenari.prepara([#"{"trovato":true,"passo":"\#(altro.etichetta)","frase":"\#(frase)","risposta":"Sì, c'è una penale."}"#])
        let esito = aspetta { try? await TrovaPaginaVera.chiedi(motore: motore, vera: vera, domanda: domanda, passi: passi, nomiClienti: ["Marco Bianchi"]) }
        let ricevuto = ServerFintoScenari.ultimo
        let utente = ((ricevuto["messages"] as? [[String: Any]])?.last?["content"] as? String) ?? ""
        let sistema = ((ricevuto["messages"] as? [[String: Any]])?.first?["content"] as? String) ?? ""
        if case .nonVerificata(let p, _)?? = esito {
            controlla(p == altro.passo, "Biblioteca, Qwen finto: la risposta che cita una pagina senza la frase è rifiutata")
        } else {
            controlla(false, "Biblioteca, Qwen finto: la risposta che cita una pagina senza la frase è rifiutata (\(String(describing: esito)))")
        }
        controlla(ricevuto["format"] != nil && utente.contains("PASSI TROVATI DA PRISMA") && utente.contains("[P1] «Piano rivalutabile")
                  && utente.contains("pagina 14") && utente.contains(domanda) && sistema.contains("parola per parola"),
                  "Biblioteca, Qwen finto: la richiesta porta i passi con etichetta, pagina e articolo, la domanda e lo schema")
        controlla(!utente.contains("Bianchi") && !utente.contains("codice fiscale"),
                  "Biblioteca, Qwen finto: a Qwen non va nessun dato del cliente (solo il nome scritto nella domanda)")
        // Un JSON guasto si richiede una volta; la seconda risposta buona passa
        ServerFintoScenari.prepara(["Certo, ecco la risposta.", #"{"trovato":true,"passo":"P1","frase":"\#(frase)","risposta":"Sì, fino al quinto anno."}"#])
        let seconda = aspetta { try? await TrovaPaginaVera.chiedi(motore: motore, vera: vera, domanda: domanda, passi: passi, nomiClienti: []) }
        if case .risposta(_, let f, _)?? = seconda {
            controlla(f == frase, "Biblioteca, Qwen finto: un JSON guasto si richiede una volta, poi la risposta verificata")
        } else {
            controlla(false, "Biblioteca, Qwen finto: un JSON guasto si richiede una volta (\(String(describing: seconda)))")
        }
    }

    /// Lo stato della Biblioteca nell'app: ricerca, risposta, senza Vera, non trovata, citazione, fac-simile, Novità.
    private static func stato(_ s: StatoShell, frase: String, _ controlla: (Bool, String) -> Void) {
        s.chiediBiblioteca("Il riscatto nei primi anni ha penali?", subito: true)
        let r = s.trovaPagina.risultato
        controlla(r?.stato == .cerca && r?.passo?.pagina == 14 && r?.pagineCercate == 193,
                  "Biblioteca: la domanda apre subito la pagina più vicina e conta le pagine cercate (\(r?.pagineCercate ?? 0))")
        let giro = s.trovaPagina.giro
        if let p = r?.passo {
            s.applicaEsitoBiblioteca(.risposta(passo: p, frase: frase, testo: "Sì, fino al quinto anno."))
        }
        controlla(s.trovaPagina.risultato?.stato == .risposta && s.trovaPagina.giro == giro,
                  "Biblioteca: la risposta sulla stessa pagina non rifà il giro")
        let c = s.citazioneBiblioteca() ?? ""
        controlla(c.hasPrefix("«Piano rivalutabile · Condizioni di assicurazione»") && c.contains("pagina 14, Art. 9 · Riscatto: \"\(frase)\""),
                  "Biblioteca: «Copia la citazione» con documento, edizione, pagina, articolo e frase")
        s.senzaVeraBiblioteca()
        controlla(s.trovaPagina.risultato?.stato == .senzaVera && s.trovaPagina.risultato?.passiEvidenziati.isEmpty == false,
                  "Biblioteca: senza Vera resta la pagina con i passi trovati evidenziati")
        s.chiediBiblioteca("Quanto si deduce del fondo pensione?", subito: true)
        if let p = s.trovaPagina.risultato?.passo {
            s.applicaEsitoBiblioteca(.risposta(passo: p, frase: "sono deducibili dal reddito complessivo fino a 5.164,57 euro l'anno", testo: "Fino a 5.164,57 euro l'anno."))
        }
        controlla(s.trovaPagina.risultato?.avviso?.contains("superato") == true,
                  "Biblioteca: la cifra della circolare diversa dal parametro di Prisma fa comparire l'avviso")
        s.chiediBiblioteca("Qual è la ricetta della torta di mele?", subito: true)
        controlla(s.trovaPagina.risultato?.stato == .nonTrovata && s.trovaPagina.risultato?.passo == nil,
                  "Biblioteca: una domanda fuori dai documenti è «non trovata»")
        s.chiediBiblioteca("Riscatto del fondo pensione online?", subito: true)
        s.applicaEsitoBiblioteca(.nonTrovata)
        controlla(s.trovaPagina.risultato?.stato == .nonTrovata && (1...3).contains(s.trovaPagina.risultato?.vicini.count ?? 0),
                  "Biblioteca: quando Vera dice che i passi non rispondono, le pagine più vicine (al più tre)")
        // Un documento letto: genere e canale proposti, da confermare; diventato normativa ha gli articoli
        let pagine = ["CONDIZIONI DI ASSICURAZIONE\nAlleanza · prodotto di prova\nEdizione 03/2026", "Art. 1 – Oggetto\n\nTesto di prova dell'articolo uno, abbastanza lungo da cercare."]
        if let d = s.aggiungiLettoInBiblioteca(titolo: "Prova", file: "prova.pdf", pagine: pagine, pagineOCR: 0, dimensione: 10) {
            controlla(d.genere == .condizioni && d.canale == .alleanza && d.daConfermare && d.edizione == "Edizione 03/2026" && d.articoli.isEmpty,
                      "Biblioteca: un PDF letto ha genere, canale ed edizione proposti, da confermare")
            s.classificaBiblioteca(d.id, genere: .normativa)
            let n = s.documentoBiblioteca(d.id)
            controlla(n?.confermato == true && n?.canale == nil && n?.articoli.first?.numero == "1",
                      "Biblioteca: diventato normativa non ha canale e ha gli articoli per «Il codice in tasca»")
            s.togliDallaBiblioteca(d.id)
        }
        let illeggibile = s.aggiungiLettoInBiblioteca(titolo: "Scansione", file: "x.pdf", pagine: [""], pagineOCR: 0, dimensione: nil)
        controlla(illeggibile?.illeggibile == true, "Biblioteca: un PDF senza testo resta, «illeggibile»")
        s.togliEsempiBiblioteca()
        controlla(!s.biblioteca.tutti.contains { $0.diProva == true } && s.trovaPagina.risultato == nil,
                  "Biblioteca: i fac-simile si tolgono con i clienti di prova")
        #if os(macOS)
        let n = StatoShell(persistente: false)
        n.apriVoceNovita(NovitaLuce.trovaLaPagina)
        controlla(NovitaLuce.trovaLaPagina.disponibile && n.appAttiva == .biblioteca, "Novità: «Trova la pagina» apre la Biblioteca")
        #endif
    }

    private static func aspetta<T>(_ lavoro: @escaping () async -> T) -> T {
        let scatola = ScatolaTrovaPagina<T>()
        let fatto = DispatchSemaphore(value: 0)
        Task.detached {
            scatola.valore = await lavoro()
            fatto.signal()
        }
        fatto.wait()
        return scatola.valore!
    }
}

private final class ScatolaTrovaPagina<T>: @unchecked Sendable {
    var valore: T?
}
