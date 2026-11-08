import Foundation

// La lettera dal futuro (Design/template-luce-specifica.md §3.1, «Luce» giro 8): il cliente legge una lettera che «lui
// stesso», all'età della pensione, gli scrive dal futuro. Motore puro, senza SwiftUI: prepara la SCHEDA DEI FATTI con le
// cifre dei motori di Prisma e la lettera fissa (quella delle istantanee e il ripiego quando Vera non è pronta). Vera
// (Vera/LetteraVera.swift) la racconta con Qwen usando solo queste cifre.
// Regole (decisioni 75-77 e 80):
// - la pensione viene da `PensioneEsperienze` (MotorePrevidenza con le ipotesi CONFERMATE in Analisi 360): senza, la
//   lettera non parla di pensione e le tile dicono «—»;
// - «il piano» = le posizioni in proposta più i versamenti previsti degli obiettivi; «con il piano» la pensione conta
//   anche le proposte di previdenza (`conPiano`), «senza» = pubblica + piani in essere;
// - l'obiettivo principale = priorità più alta con scadenza futura (a parità, la scadenza più vicina); la data di arrivo
//   viene da `CurvaObiettivo` (rendimento, inflazione e posizioni collegate), con e senza il versamento previsto;
// - l'anno del traguardo è quello in cui il cliente compie l'età della pensione, dalla data di nascita;
// - la frase sul fondo entra SOLO se c'è una posizione previdenziale in proposta;
// - «Senza il piano» dice le cifre e basta: niente scenari negativi oltre le cifre (decisione 80);
// - saluto sempre «{nome},» (decisione 80);
// - chi scrive sta nell'anno del traguardo: un obiettivo raggiunto entro quell'anno si racconta al passato, uno che
//   arriva dopo al futuro («lo raggiungeremo a …»), mai un fatto futuro raccontato come già accaduto.

/// Le due versioni della lettera.
enum VersioneLettera: String, Codable, CaseIterable, Identifiable {
    case conPiano, senzaPiano

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .conPiano: return "Con il piano"
        case .senzaPiano: return "Senza il piano"
        }
    }
}

/// La scheda dei fatti della lettera: tutte e sole le cifre che possono comparire.
struct SchedaLettera: Equatable {
    /// Il nome di battesimo.
    let nome: String
    /// Il genere dal codice fiscale (nil se non si sa); il saluto resta «{nome},» (decisione 80).
    let femminile: Bool?
    let etaTraguardo: Int
    /// L'età della pensione non viene dalle ipotesi del cliente: 67, «età di pensione ipotizzata».
    let etaIpotizzata: Bool
    let annoTraguardo: Int
    /// «novembre 2026»: il mese di oggi.
    let meseIncontro: String
    let etaOggi: Int
    /// L'obiettivo principale.
    let obiettivo: String?
    /// Data di arrivo con il versamento previsto e senza (nil = oltre 30 anni dalla scadenza).
    let arrivoConPiano: Date?
    let arrivoSenzaPiano: Date?
    /// Il versamento mensile previsto per l'obiettivo (nil se non c'è).
    let versamentoMensile: Double?
    /// Pubblica + piani in essere + proposte; nil senza proposte di previdenza o senza ipotesi confermate.
    let pensioneConPiano: Double?
    /// Pubblica + piani in essere; nil senza ipotesi confermate.
    let pensioneSenzaPiano: Double?
    /// C'è una posizione previdenziale in proposta.
    let fondoNelPiano: Bool
    /// C'è un piano: una proposta o un versamento previsto per un obiettivo.
    let pianoPresente: Bool
    /// Ciò che manca, per le note sotto il segmentato.
    let mancanti: [MancanteLettera]
}

/// Ciò che manca alla lettera (§3.1.6).
enum MancanteLettera: Equatable {
    case dataNascita
    case previdenza
    case obiettivo
    case piano
}

enum MotoreLettera {
    /// L'età della pensione quando non viene dalle ipotesi del cliente (con la nota «età di pensione ipotizzata»).
    static let etaPensioneIpotizzata = 67
    /// Le pensioni si raccontano arrotondate a 10 €, come nel template.
    static let arrotondamento = 10.0

    /// La scheda dei fatti; nil se manca la data di nascita (niente lettera: §3.1.6).
    static func scheda(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], analisi: Analisi360?, oggi: Date,
                       cal: Calendar = .current) -> SchedaLettera? {
        guard let nascita = cliente.dataNascita, let etaOggi = cal.dateComponents([.year], from: nascita, to: oggi).year else {
            return nil
        }
        let mie = posizioni.filter { $0.clienteId == cliente.id }
        var mancanti: [MancanteLettera] = []
        let pensione = PensioneEsperienze.calcola(cliente: cliente, posizioni: mie, analisi: analisi, data: oggi)
        var cifre: CifrePensioneEsperienze?
        if case .pronto(let c) = pensione { cifre = c } else { mancanti.append(.previdenza) }
        let etaPensione = cifre?.etaPensione ?? cliente.profilo.lavoro?.etaPensione
        let etaTraguardo = max(etaOggi + 1, etaPensione ?? etaPensioneIpotizzata)
        let annoNascita = cal.component(.year, from: nascita)

        let principale = obiettivoPrincipale(obiettivi.filter { $0.clienteId == cliente.id }, oggi: oggi)
        if principale == nil { mancanti.append(.obiettivo) }
        var arrivoCon: Date?
        var arrivoSenza: Date?
        if let o = principale {
            let curva = CurvaObiettivo(o, posizioni: mie, data: oggi)
            arrivoCon = curva.arrivo(versamento: o.versamentoMensile)
            arrivoSenza = curva.arrivo(versamento: 0)
        }
        let proposte = mie.filter { $0.stato == .proposta }
        let versamento = principale.flatMap { $0.versamentoMensile > 0 ? $0.versamentoMensile : nil }
        let conVersamenti = obiettivi.contains { $0.clienteId == cliente.id && $0.versamentoMensile > 0 && $0.raggiuntoIl == nil }
        let piano = !proposte.isEmpty || conVersamenti
        if !piano { mancanti.append(.piano) }
        return SchedaLettera(
            nome: ModelliMessaggi.primoNome(cliente.nome),
            femminile: TestiAree360.femminile(cliente),
            etaTraguardo: etaTraguardo,
            etaIpotizzata: etaPensione == nil,
            annoTraguardo: annoNascita + etaTraguardo,
            meseIncontro: Formati.meseAnno.string(from: oggi),
            etaOggi: etaOggi,
            obiettivo: principale?.titolo,
            arrivoConPiano: arrivoCon,
            arrivoSenzaPiano: arrivoSenza,
            versamentoMensile: versamento,
            pensioneConPiano: cifre?.conPiano.map(arrotonda),
            pensioneSenzaPiano: cifre.map { arrotonda($0.senzaPiano) },
            fondoNelPiano: proposte.contains { $0.area == .previdenza },
            pianoPresente: piano,
            mancanti: mancanti)
    }

    /// L'obiettivo principale: priorità più alta con scadenza futura, a parità la scadenza più vicina.
    static func obiettivoPrincipale(_ obiettivi: [Obiettivo], oggi: Date) -> Obiettivo? {
        obiettivi.filter { $0.scadenza > oggi && $0.raggiuntoIl == nil }
            .min { a, b in a.priorita != b.priorita ? a.priorita > b.priorita : a.scadenza < b.scadenza }
    }

    static func arrotonda(_ v: Double) -> Double { (v / arrotondamento).rounded() * arrotondamento }

    /// La pensione della versione (con il piano senza proposte di previdenza: quella senza).
    static func pensione(_ s: SchedaLettera, _ v: VersioneLettera) -> Double? {
        v == .conPiano ? (s.pensioneConPiano ?? s.pensioneSenzaPiano) : s.pensioneSenzaPiano
    }

    // MARK: - Testi

    /// «Giulia,»: il saluto della decisione 80, uguale per tutti.
    static func saluto(_ s: SchedaLettera) -> String { "\(s.nome)," }

    /// L'arrivo cade entro l'anno da cui scrive la lettera (si racconta al passato).
    static func giaArrivato(_ arrivo: Date, _ s: SchedaLettera, cal: Calendar = .current) -> Bool {
        cal.component(.year, from: arrivo) <= s.annoTraguardo
    }

    /// La firma, che aggiunge sempre Prisma: «Giulia, 67 anni».
    static func firma(_ s: SchedaLettera) -> String { "\(s.nome), \(s.etaTraguardo) anni" }

    static func cifra(_ v: Double) -> String {
        Formati.numeroFormatter.string(from: NSNumber(value: v.rounded())) ?? "\(Int(v.rounded()))"
    }

    static func data(_ d: Date) -> String { Formati.meseAnno.string(from: d) }

    /// La lettera fissa di Prisma, senza la firma.
    static func fissa(_ s: SchedaLettera, _ v: VersioneLettera) -> String {
        var paragrafi = [saluto(s)]
        switch v {
        case .conPiano:
            var primo = "ti scrivo dal \(s.annoTraguardo). Ho \(s.etaTraguardo) anni e stamattina ho ripensato a quella sera di \(s.meseIncontro), con tutti i numeri sul tavolo."
            if let o = s.obiettivo {
                if let a = s.arrivoConPiano, giaArrivato(a, s) {
                    primo += " L’obiettivo «\(o)» l’abbiamo raggiunto a \(data(a)), come avevamo previsto."
                } else if let a = s.arrivoConPiano {
                    primo += " L’obiettivo «\(o)» lo raggiungeremo a \(data(a)), come avevamo previsto."
                } else {
                    primo += " L’obiettivo «\(o)» è rimasto la nostra strada."
                }
            }
            if let m = s.versamentoMensile {
                primo += " Non è stato sempre facile mettere da parte \(cifra(m)) euro al mese, ma abbiamo tenuto la rotta."
            }
            paragrafi.append(primo)
            if let p = pensione(s, .conPiano) {
                var secondo = "Oggi la pensione arriva a circa \(cifra(p)) euro al mese"
                secondo += s.fondoNelPiano ? ", contando anche il fondo che abbiamo aperto a \(s.etaOggi) anni." : "."
                secondo += " Possiamo dedicarci a quello che conta per noi."
                paragrafi.append(secondo)
            }
            paragrafi.append("Grazie per aver cominciato quando era il momento.")
        case .senzaPiano:
            var primo = "ti scrivo dal \(s.annoTraguardo). Ho \(s.etaTraguardo) anni."
            if let o = s.obiettivo {
                if let a = s.arrivoSenzaPiano, giaArrivato(a, s) {
                    primo += " L’obiettivo «\(o)» l’abbiamo raggiunto a \(data(a))."
                } else if let a = s.arrivoSenzaPiano {
                    primo += " L’obiettivo «\(o)» lo raggiungeremo a \(data(a))."
                } else {
                    primo += " L’obiettivo «\(o)» è rimasto più lontano di quanto speravamo."
                }
            }
            paragrafi.append(primo)
            var secondo = ""
            if let p = s.pensioneSenzaPiano { secondo = "La pensione è di circa \(cifra(p)) euro al mese. " }
            secondo += "Ogni tanto ripenso a quella sera di \(s.meseIncontro) in cui avevamo tutti i numeri davanti."
            paragrafi.append(secondo)
        }
        return paragrafi.joined(separator: "\n\n")
    }

    /// La lettera con la firma.
    static func conFirma(_ testo: String, _ s: SchedaLettera) -> String { testo + "\n\n" + firma(s) }

    /// Le cifre che Qwen può usare (come testo: `CommentoVera.numeriConservati` le confronta con la lettera).
    static func ammessi(_ s: SchedaLettera, _ v: VersioneLettera) -> String {
        var r = fatti(s, v)
        r.append(fissa(s, v))
        r.append(firma(s))
        return r.joined(separator: "\n")
    }

    /// I fatti della scheda, una riga per fatto (vanno a Qwen).
    static func fatti(_ s: SchedaLettera, _ v: VersioneLettera) -> [String] {
        var r = ["Chi scrive: \(s.nome), a \(s.etaTraguardo) anni, nel \(s.annoTraguardo)",
                 "A chi scrive: a sé stesso di oggi, che ha \(s.etaOggi) anni",
                 "La sera dei numeri sul tavolo: \(s.meseIncontro)",
                 "Saluto: \(saluto(s))"]
        if let o = s.obiettivo {
            r.append("L'obiettivo: «\(o)»")
            let arrivo = v == .conPiano ? s.arrivoConPiano : s.arrivoSenzaPiano
            r.append("Arrivo dell'obiettivo: " + (arrivo.map { a in
                data(a) + (giaArrivato(a, s) ? " (già raggiunto quando scrivi: raccontalo al passato)"
                                              : " (dopo l'anno da cui scrivi: raccontalo al futuro, non è ancora successo)")
            } ?? "molto più tardi, senza una data"))
            if v == .conPiano, let m = s.versamentoMensile { r.append("Versamento mensile: \(cifra(m)) euro") }
        }
        if let p = pensione(s, v) { r.append("Pensione al mese: circa \(cifra(p)) euro") }
        if v == .conPiano, s.fondoNelPiano { r.append("Fondo pensione aperto a \(s.etaOggi) anni") }
        return r
    }
}
