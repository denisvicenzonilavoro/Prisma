import Foundation

/// I testi dell'allenamento OCF: riepilogo e errori dell'importazione, pulsanti del caso vero.
enum TestiOCF {
    // MARK: Caso vero

    /// Il testo del pulsante, con il nome vero del cliente.
    static func casoVero(_ c: CasoOCF, nome: String) -> String {
        let di = nome.isEmpty ? "" : " di \(nome)"
        switch c {
        case .gestioneSeparata: return "Guarda la polizza rivalutabile\(di)"
        case .multiramo: return "Guarda la multiramo\(di)"
        case .fondo: return "Guarda il fondo\(di)"
        case .previdenzaComplementare: return "Guarda il piano previdenziale\(di)"
        case .casoMorte: return "Guarda la temporanea caso morte\(di)"
        case .protezioneDanni: return "Guarda la copertura\(di)"
        case .kid: return "Apri il KID\(di)"
        }
    }

    // MARK: Riepilogo dell'importazione

    /// «7 domande nuove · 2 aggiornate · 1 uguale · 3 righe scartate: riga 4 (manca la risposta C), …».
    static func riepilogo(_ i: ImportazioneOCF) -> String {
        var parti = [i.nuove.count == 1 ? "1 domanda nuova" : "\(i.nuove.count) domande nuove",
                     i.aggiornate.count == 1 ? "1 aggiornata" : "\(i.aggiornate.count) aggiornate"]
        if i.uguali > 0 { parti.append(i.uguali == 1 ? "1 uguale" : "\(i.uguali) uguali") }
        if !i.materieNuove.isEmpty {
            parti.append((i.materieNuove.count == 1 ? "1 materia nuova: " : "\(i.materieNuove.count) materie nuove: ")
                         + i.materieNuove.map(\.nome).joined(separator: ", "))
        }
        var testo = parti.joined(separator: " · ")
        if !i.scartate.isEmpty {
            let unita = i.daCSV ? (i.scartate.count == 1 ? "riga scartata" : "righe scartate")
                                : (i.scartate.count == 1 ? "domanda scartata" : "domande scartate")
            let nome = i.daCSV ? "riga" : "domanda"
            let primi = i.scartate.prefix(5).map { "\(nome) \($0.riga) (\($0.motivo))" }.joined(separator: ", ")
            let altre = i.scartate.count > 5 ? " e altre \(i.scartate.count - 5)" : ""
            testo += " · \(i.scartate.count) \(unita): \(primi)\(altre)"
        }
        return testo
    }

    // MARK: Motivi delle righe scartate

    static let mancaMateria = "manca la materia"
    static let mancaTesto = "manca il testo della domanda"
    static func risposteNonQuattro(_ n: Int) -> String { "servono quattro risposte, ce ne sono \(n)" }
    static func mancaRisposta(_ indice: Int) -> String {
        let lettere = ["A", "B", "C", "D"]
        return "manca la risposta \(indice < lettere.count ? lettere[indice] : String(indice + 1))"
    }
    static let risposteUguali = "due risposte sono uguali"
    static func correttaNonValida(_ scritta: String, daCSV: Bool) -> String {
        let regola = daCSV ? "usa A, B, C o D (oppure 1-4)" : "usa l'indice 0-3 o la lettera A-D"
        return scritta.isEmpty ? "manca la risposta corretta" : "risposta corretta «\(scritta)» non valida: \(regola)"
    }
    static func idRipetuto(_ id: String) -> String { "l'id «\(id)» è già usato da un'altra domanda del file" }
    static let domandaIlleggibile = "non è una domanda leggibile (controlla i tipi dei campi)"

    // MARK: Errori del file

    static let fileIlleggibile = "Non riesco a leggere il file."
    static let fileVuoto = "Il file non contiene domande."
    static func mancanoColonne(_ c: [String]) -> String {
        "Nell'intestazione del CSV mancano le colonne: \(c.joined(separator: ", "))."
    }
    static let jsonRotto = "Il file non è un JSON valido."
    static let strutturaJSON = "Il JSON non ha la struttura delle domande di Prisma (servono «formato», «versione» e l'elenco «domande»)."
    static func formatoSconosciuto(_ f: String?) -> String {
        "Formato «\(f ?? "")» non riconosciuto: serve «\(ImportaOCF.formato)»."
    }
    static let versioneMancante = "Manca la versione del formato."
    static func versioneSconosciuta(_ v: Int) -> String {
        "Versione \(v) del formato non riconosciuta: Prisma legge la versione \(ImportaOCF.versione)."
    }
}
