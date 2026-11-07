import Foundation

// I testi di «La tua settimana, il tuo anno» (versione «Luce», giro 5, Design/template-luce-specifica.md §5.2.1):
// le frasi fisse e quelle composte da ciò che c'è (MotoreStorie).

/// I testi delle storie. NESSUN paragone dei chilometri: la tabella delle distanze la deve approvare l'utente
/// (decisione 72); finché non c'è, la pagina dei chilometri non ha paragoni.
enum TestiStorie {
    static let tranquilla = "Una settimana tranquilla: niente in agenda per ora."
    static let buonaSettimana = "Buona settimana."
    static let prontaAnche = "Prisma è pronta, tu anche."
    static let guardaAnno = "Guarda anche «Il tuo anno»"
    static let questaSettimana = "Questa settimana"
    static let inArrivo = "In arrivo"
    static let daChiamare = "Da chiamare per primo"
    static let unTraguardo = "Un traguardo da festeggiare"
    static let festeggialo = "Festeggialo ›"
    static let annoSottotitolo = "Il tuo anno da consulente, in un minuto."
    static let protetto = "Quest’anno hai protetto"
    static let segui = "Segui"
    static let primoAnno = "Da quest’anno in Prisma"
    static let momento = "Il momento dell’anno"
    static let grazie = "Grazie per il lavoro che fai."
    static let percorso = "Per andarli a trovare hai fatto"
    static let datiDiProva = "dati di prova"
    static let invito = "La tua settimana è pronta"
    static let apri = "Apri ›"
    /// La tabella dei paragoni dei chilometri: vuota finché l'utente non approva le distanze (decisione 72).
    static let paragoniKm: [(luogo: String, km: Double)] = []

    /// «Buongiorno, Denis.» o «Buongiorno.» senza nome.
    static func buongiorno(_ nome: String) -> String { nome.isEmpty ? "Buongiorno." : "Buongiorno, \(nome)." }

    /// «Ecco la tua settimana · 2 – 8 novembre» (a cavallo di mese: «30 novembre – 6 dicembre»).
    static func eccoSettimana(_ settimana: DateInterval, cal: Calendar = .current) -> String {
        "Ecco la tua settimana · " + periodo(settimana, cal: cal)
    }

    static func periodo(_ p: DateInterval, cal: Calendar = .current) -> String {
        let ultimo = cal.date(byAdding: .day, value: -1, to: p.end) ?? p.end
        let stessoMese = cal.component(.month, from: p.start) == cal.component(.month, from: ultimo)
        let primo = stessoMese ? String(cal.component(.day, from: p.start)) : Formati.giornoMese.string(from: p.start)
        return "\(primo) – " + Formati.giornoMese.string(from: ultimo)
    }

    /// «7 incontri», «1 incontro».
    static func incontri(_ n: Int) -> String { n == 1 ? "incontro" : "incontri" }

    /// «Il più importante: giovedì alle 16:00, la firma di Giulia.»
    static func principale(_ a: Appuntamento, cliente: Cliente, numero: Int) -> String {
        let nome = TestiTraguardi.primoNome(cliente.nome)
        let giorno = Formati.giornoSettimana.string(from: a.inizio).lowercased()
        let ora = Formati.ora.string(from: a.inizio)
        let cosa: String
        switch a.tipo {
        case .firma: cosa = "la firma di \(nome)"
        case .proposta: cosa = "la proposta a \(nome)"
        case .primoIncontro: cosa = "il primo incontro con \(nome)"
        default: cosa = "«\(a.titolo)» con \(nome)"
        }
        let apertura = numero == 1 ? "L’incontro" : (a.tipo == .firma || a.tipo == .proposta ? "Il più importante" : "Il primo")
        return "\(apertura): \(giorno) alle \(ora), \(cosa)."
    }

    /// «Rinnovi Alleanza e due parcelle» (composta da ciò che c'è); senza aliquote lo dice.
    static func didascaliaInArrivo(tipi: Set<MotoreStudio.TipoProvvigione>, parcelle: Int, parziale: Bool) -> String {
        var parti: [String] = []
        for t in MotoreStudio.TipoProvvigione.allCases where tipi.contains(t) {
            switch t {
            case .nuovaProduzione: parti.append("nuova produzione Alleanza")
            case .ricorrente: parti.append("ricorrenti Alleanza")
            case .rinnovo: parti.append("rinnovi Alleanza")
            }
        }
        if parcelle > 0 { parti.append(numeroParcelle(parcelle)) }
        var testo = parti.isEmpty ? "" : parti.count == 1 ? parti[0]
            : parti.dropLast().joined(separator: ", ") + " e " + (parti.last ?? "")
        testo = TestiTraguardi.maiuscola(testo)
        if parziale { testo += testo.isEmpty ? "Solo parcelle: mancano le aliquote" : " · solo parcelle: mancano le aliquote" }
        return testo
    }

    static func numeroParcelle(_ n: Int) -> String {
        let parole = [1: "una parcella", 2: "due parcelle", 3: "tre parcelle", 4: "quattro parcelle", 5: "cinque parcelle"]
        return parole[n] ?? "\(n) parcelle"
    }

    /// «23 famiglie», «1 famiglia».
    static func famiglie(_ n: Int) -> String { n == 1 ? "famiglia" : "famiglie" }

    /// «con 4.800.000 € di capitale, se succede qualcosa».
    static func capitale(_ v: Double) -> String { "con \(FormatoCifra.euro.testo(v)) di capitale, se succede qualcosa" }

    /// «+18% da inizio anno» (meno tipografico se scende, «stabile» a zero).
    static func variazione(_ v: Double) -> String {
        let p = (v * 100).rounded()
        if p == 0 { return "Stabile da inizio anno" }
        return (p > 0 ? "+" : Formati.meno) + FormatoCifra.migliaia(abs(p)) + "% da inizio anno"
    }

    /// «12 clienti nuovi», «1 cliente nuovo».
    static func nuoviClienti(_ n: Int) -> String { n == 1 ? "1 cliente nuovo" : "\(n) clienti nuovi" }

    /// «7 sono arrivati dal passaparola» (solo con il dato, che oggi non c'è).
    static func passaparola(_ n: Int) -> String { n == 1 ? "1 è arrivato dal passaparola" : "\(n) sono arrivati dal passaparola" }

    /// L'abbreviazione del giorno sotto le colonne: «lun», «mar»…
    static func giornoBreve(_ d: Date) -> String {
        String(Formati.giornoSettimana.string(from: d).lowercased().prefix(3))
    }
}
