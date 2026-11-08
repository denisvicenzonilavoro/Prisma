import Foundation

/// Una domanda dell'esame: la domanda e la risposta che il consulente aveva approvato.
struct DomandaEsame: Equatable {
    var id: String
    var domanda: String
    var attesa: String
    var modalita: ModalitaVera
}

/// Il punteggio di una risposta all'esame, calcolato dal codice.
struct PunteggioDomanda: Equatable {
    var passata: Bool
    var cifreInventate: [String]
    var paroleARischio: [String]
    var somiglianza: Double
}

/// L'esito dell'esame: la Vera di oggi e quella nuova, sulle stesse domande.
struct EsitoEsame: Equatable {
    var attuale: String
    var nuovo: String
    var domande: Int
    /// Per modello, nell'ordine delle domande.
    var punteggi: [String: [PunteggioDomanda]] = [:]
    /// Modello → motivo (non pronto, errore del server): con un errore l'esame non è superato.
    var errori: [String: String] = [:]
    var fattoIl = Date()

    func percentuale(_ modello: String) -> Int {
        guard domande > 0, let p = punteggi[modello] else { return 0 }
        return Int((Double(p.filter(\.passata).count) * 100 / Double(domande)).rounded())
    }

    func cifreInventate(_ modello: String) -> Int {
        (punteggi[modello] ?? []).reduce(0) { $0 + $1.cifreInventate.count }
    }

    var superato: Bool {
        guard errori.isEmpty, domande > 0, punteggi[attuale]?.count == domande, punteggi[nuovo]?.count == domande else { return false }
        return EsameSuMisura.superato(attuale: (percentuale(attuale), cifreInventate(attuale)), nuovo: (percentuale(nuovo), cifreInventate(nuovo)))
    }

    var breve: EsitoEsameBreve {
        EsitoEsameBreve(domande: domande, percentualeAttuale: percentuale(attuale), percentualeNuova: percentuale(nuovo),
                        cifreInventateAttuale: cifreInventate(attuale), cifreInventateNuova: cifreInventate(nuovo), fattoIl: fattoIl, superato: superato)
    }
}

/// L'esame di «Vera su misura»: le domande tenute da parte (mai uscite dal Mac) poste alla Vera di oggi e a quella nuova,
/// un modello alla volta. Prima il codice: una cifra che non è nella domanda né nella risposta approvata, o una parola
/// a rischio («garantito», «senza rischi») che la risposta approvata non aveva, valgono 0; altrimenti la risposta passa
/// se somiglia abbastanza a quella approvata (F1 delle parole significative).
enum EsameSuMisura {
    /// Valori di avvio, da confermare con l'utente.
    static let sogliaSomiglianza = 0.35
    static let sogliaMinima = 70
    static let margine = 2

    static func domande(_ esame: [EsempioAnonimo]) -> [DomandaEsame] {
        esame.map { DomandaEsame(id: $0.id, domanda: $0.domanda, attesa: $0.risposta, modalita: $0.modalita) }
    }

    /// Le domande fac-simile di Vera/Esempi/esame-di-prova.json (dati di prova, per le prove).
    static func domandeDiProva() -> [DomandaEsame] {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Esempi/esame-di-prova.json"),
              let d = try? Data(contentsOf: url),
              let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let elenco = j["domande"] as? [[String: Any]] else { return [] }
        return elenco.compactMap { e in
            guard let id = e["id"] as? String, let q = e["domanda"] as? String, let a = e["attesa"] as? String else { return nil }
            return DomandaEsame(id: id, domanda: q, attesa: a, modalita: ModalitaVera(rawValue: e["modalita"] as? String ?? "") ?? .lavoro)
        }
    }

    /// F1 delle parole significative (RicercaVera.parole) tra risposta e risposta approvata.
    static func somiglianza(_ a: String, _ b: String) -> Double {
        let pa = Set(RicercaVera.parole(a)), pb = Set(RicercaVera.parole(b))
        guard !pa.isEmpty, !pb.isEmpty else { return 0 }
        let comuni = Double(pa.intersection(pb).count)
        guard comuni > 0 else { return 0 }
        let precisione = comuni / Double(pa.count), richiamo = comuni / Double(pb.count)
        return 2 * precisione * richiamo / (precisione + richiamo)
    }

    /// Le parole a rischio della seconda lettura presenti nella risposta e assenti dalla risposta approvata.
    static func paroleARischio(_ risposta: String, attesa: String) -> [String] {
        let r = risposta.lowercased(), a = attesa.lowercased()
        return SecondaLetturaVera.parole.filter { p in
            r.range(of: p.schema, options: .regularExpression) != nil && a.range(of: p.schema, options: .regularExpression) == nil
        }.map(\.titolo)
    }

    static func punteggio(risposta: String, domanda: DomandaEsame) -> PunteggioDomanda {
        let cifre = SuMisuraVera.cifreSenzaFonte(risposta, fonte: domanda.domanda + "\n" + domanda.attesa)
        let rischio = paroleARischio(risposta, attesa: domanda.attesa)
        let s = somiglianza(risposta, domanda.attesa)
        return PunteggioDomanda(passata: cifre.isEmpty && rischio.isEmpty && s >= sogliaSomiglianza, cifreInventate: cifre, paroleARischio: rischio, somiglianza: s)
    }

    /// Superato: almeno `sogliaMinima`%, almeno `margine` punti sopra la Vera di oggi e non più cifre inventate di lei.
    static func superato(attuale: (Int, Int), nuovo: (Int, Int)) -> Bool {
        nuovo.0 >= sogliaMinima && nuovo.0 >= attuale.0 + margine && nuovo.1 <= attuale.1
    }

    /// I messaggi di una domanda: le istruzioni della sua modalità e la domanda, niente scheda né lezioni.
    static func messaggi(_ d: DomandaEsame) -> [MessaggioModello] {
        [MessaggioModello(ruolo: .sistema, testo: d.modalita == .lavoro ? IstruzioniVera.chat : IstruzioniVera.conversazione),
         MessaggioModello(ruolo: .utente, testo: d.domanda)]
    }

    /// Le opzioni dell'esame: temperatura 0, senza ragionamento, senza lezioni.
    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0
        o.pensa = false
        o.conLezioni = false
        o.contesto = NucleoVera.finestra
        o.restaInMemoria = vera.restaInMemoria
        return o
    }

    /// Un modello alla volta, come ConfrontoModelli: verifica, precarica, domande, poi libera la memoria prima del secondo
    /// (sul Mac da 8 GB due modelli insieme non stanno).
    static func esegui(_ domande: [DomandaEsame], attuale: String, nuovo: String, vera: ImpostazioniVera,
                       sessione: URLSession = .shared, avanzamento: @escaping (String) -> Void = { _ in }) async -> EsitoEsame {
        var esito = EsitoEsame(attuale: attuale, nuovo: nuovo, domande: domande.count)
        guard !domande.isEmpty else {
            esito.errori[nuovo] = "Nessuna domanda per l'esame."
            return esito
        }
        for (indice, modello) in [attuale, nuovo].enumerated() {
            var impostazioni = vera
            impostazioni.fornitore = .ollama
            impostazioni.modelloLocale = modello
            let motore = MotoreLocale(impostazioni, disponibilita: .pronto, sessione: sessione)
            let chi = indice == 0 ? "Vera di oggi" : "Vera su misura"
            avanzamento("Carico la \(chi)…")
            if let motivo = await motore.fornitore.verifica().motivo {
                esito.errori[modello] = motivo
                continue
            }
            _ = await motore.fornitore.precarica(restaInMemoria: impostazioni.restaInMemoria)
            var punteggi: [PunteggioDomanda] = []
            for (i, d) in domande.enumerated() {
                if Task.isCancelled { break }
                avanzamento("domanda \(i + 1) di \(domande.count) · \(chi)")
                do {
                    let r = try await motore.scrivi(messaggi(d), opzioni: opzioni(impostazioni))
                    punteggi.append(punteggio(risposta: r.testo, domanda: d))
                } catch {
                    // Una risposta mancata vale 0
                    punteggi.append(PunteggioDomanda(passata: false, cifreInventate: [], paroleARischio: [], somiglianza: 0))
                }
            }
            esito.punteggi[modello] = punteggi
            // La memoria torna libera prima del modello successivo
            await motore.fornitore.libera()
        }
        if Task.isCancelled { esito.errori[nuovo] = "Esame interrotto." }
        esito.fattoIl = Date()
        avanzamento("Esame finito")
        return esito
    }
}
