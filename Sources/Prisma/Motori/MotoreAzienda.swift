import Foundation

// La scheda «L'azienda» dei clienti imprenditori (Design/template-luce-specifica.md §9.3, «Luce» giro 7; decisioni 67 e 96).
// Motore puro: dai dati che l'utente ha scritto nell'azienda (`AziendaCliente`) e dalle posizioni del cliente, per ognuna
// delle quattro aree la percentuale dell'anello, la frase della scheda (modelli fissi con i dati veri, `TestiAzienda`),
// che cosa manca e le righe del dettaglio.
// - Persona chiave = capitale delle posizioni in essere che l'utente ha collegato come coperture «key man» ÷ fabbisogno,
//   con fabbisogno = fatturato × mesi a rischio ÷ 12 (i mesi li scrive l'utente: è una sua valutazione). Senza fatturato
//   o senza mesi: nessun anello.
// - TFM = 100% se accantonato, 0% se no; nessun calcolo fiscale (decisione 67): «da valutare con il commercialista».
// - Welfare e passaggio dell'impresa = voci fatte ÷ voci della lista scelta dall'utente. Senza lista: nessun anello.
// - Un'area segnata «non pertinente» (in `Cliente.datiNonPertinenti`, chiave `azienda:<id>:<area>`) non ha anello.
// Le cifre del template (35%, 10%) sono dimostrative e non si riproducono.

/// Le quattro aree della scheda, nell'ordine del template.
enum AreaAzienda: String, CaseIterable, Identifiable {
    case personaChiave, tfm, welfare, passaggio

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .personaChiave: return "Persona chiave"
        case .tfm: return "TFM degli amministratori"
        case .welfare: return "Welfare aziendale"
        case .passaggio: return "Passaggio dell'impresa"
        }
    }

    /// Dove porta il collegamento in fondo alla scheda.
    enum Azione: Equatable {
        /// Pratiche › Proposta, con il bisogno detto nell'avviso.
        case proposta
        /// Il dettaglio della scheda (TFM: nessun simulatore, decisione 67).
        case dettaglio
        /// Analisi 360, la protezione e il passaggio del patrimonio.
        case pianificazione
    }

    var azione: Azione {
        switch self {
        case .personaChiave, .welfare: return .proposta
        case .tfm: return .dettaglio
        case .passaggio: return .pianificazione
        }
    }

    /// Il testo del collegamento. Per il TFM non «Simula il TFM» del template: un simulatore non c'è (decisione 67).
    var collegamento: String {
        switch self {
        case .personaChiave: return "Proponi una key man ›"
        case .tfm: return "I dati del TFM ›"
        case .welfare: return "Proponi un piano ›"
        case .passaggio: return "Apri la pianificazione ›"
        }
    }
}

/// Una riga del dettaglio di un'area: etichetta e valore.
struct RigaAzienda: Equatable, Hashable {
    let etichetta: String
    let valore: String
}

/// La valutazione di un'area dell'azienda.
struct ValutazioneAreaAzienda: Identifiable, Equatable {
    let area: AreaAzienda
    /// 0…100; nil = da completare o non pertinente (anello grigio «—»).
    let percentuale: Double?
    let nonPertinente: Bool
    let frase: String
    /// I dati che servono per valutarla (vuoto se c'è tutto).
    let mancano: [String]
    let righe: [RigaAzienda]

    var id: String { area.rawValue }
    var daCompletare: Bool { percentuale == nil && !nonPertinente }
}

enum MotoreAzienda {
    /// La chiave dell'area in `Cliente.datiNonPertinenti` (una per azienda: un cliente può averne più d'una).
    static func chiaveNonPertinente(azienda id: String, area: AreaAzienda) -> String {
        "azienda:\(id):\(area.rawValue)"
    }

    /// Fatturato × mesi a rischio ÷ 12. nil senza fatturato o senza mesi (o con valori non positivi).
    static func fabbisognoPersonaChiave(fatturato: Double?, mesi: Double?) -> Double? {
        guard let f = fatturato, let m = mesi, f > 0, m > 0 else { return nil }
        return f * m / 12
    }

    /// Le posizioni in essere del cliente che l'utente ha collegato alla persona chiave.
    static func coperturePersonaChiave(_ a: AziendaCliente, posizioni: [Posizione]) -> [Posizione] {
        let collegate = Set(a.personaChiave?.posizioniCollegate ?? [])
        return posizioni.filter { collegate.contains($0.id) && $0.stato == .inEssere }
    }

    /// Il capitale assicurato delle coperture collegate (quelle senza capitale contano 0).
    static func capitalePersonaChiave(_ a: AziendaCliente, posizioni: [Posizione]) -> Double {
        coperturePersonaChiave(a, posizioni: posizioni).reduce(0) { $0 + max(0, $1.capitaleAssicurato ?? 0) }
    }

    /// Voci fatte ÷ voci della lista, in %. nil senza voci.
    static func quota(_ lista: ListaAzienda?) -> Double? {
        guard let voci = lista?.voci, !voci.isEmpty else { return nil }
        return Double(voci.filter(\.fatta).count) / Double(voci.count) * 100
    }

    /// Le età dei figli del cliente (figli e figlie con la data di nascita), dalla più alta.
    static func etaFigli(_ c: Cliente, oggi: Date = Date()) -> [Int] {
        c.famiglia
            .filter { $0.relazione == .figlio || $0.relazione == .figlia }
            .compactMap { f in f.dataNascita.flatMap { Calendar.current.dateComponents([.year], from: $0, to: oggi).year } }
            .sorted(by: >)
    }

    /// Il primo cliente per nome con almeno un'azienda (il pannello Novità apre lui).
    static func primoConAzienda(_ clienti: [Cliente]) -> Cliente? {
        clienti
            .filter { !$0.elencoAziende.isEmpty }
            .sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
            .first
    }

    /// Le quattro valutazioni dell'azienda.
    static func valuta(_ a: AziendaCliente, cliente c: Cliente, posizioni: [Posizione], oggi: Date = Date()) -> [ValutazioneAreaAzienda] {
        let segnate = c.datiNonPertinenti ?? [:]
        return AreaAzienda.allCases.map { area in
            let np = segnate[chiaveNonPertinente(azienda: a.id, area: area)] != nil
            switch area {
            case .personaChiave: return personaChiave(a, cliente: c, posizioni: posizioni, nonPertinente: np)
            case .tfm: return tfm(a, nonPertinente: np)
            case .welfare: return welfare(a, nonPertinente: np)
            case .passaggio: return passaggio(a, cliente: c, oggi: oggi, nonPertinente: np)
            }
        }
    }

    // MARK: - Le quattro aree

    private typealias T = TestiAzienda

    private static func personaChiave(_ a: AziendaCliente, cliente c: Cliente, posizioni: [Posizione],
                                      nonPertinente: Bool) -> ValutazioneAreaAzienda {
        let mesi = a.personaChiave?.mesiARischio
        let fabbisogno = fabbisognoPersonaChiave(fatturato: a.fatturato, mesi: mesi)
        let coperture = coperturePersonaChiave(a, posizioni: posizioni)
        let capitale = capitalePersonaChiave(a, posizioni: posizioni)
        var mancano: [String] = []
        if (a.fatturato ?? 0) <= 0 { mancano.append("il fatturato") }
        if (mesi ?? 0) <= 0 { mancano.append("i mesi di fatturato a rischio se \(T.nome(c)) si ferma") }
        var righe = [
            RigaAzienda(etichetta: T.etichettaFatturato(a), valore: a.fatturato.map(T.euro) ?? "da inserire"),
            RigaAzienda(etichetta: "Mesi di fatturato a rischio (tua valutazione)", valore: mesi.map(T.mesi) ?? "da inserire"),
            RigaAzienda(etichetta: "Fabbisogno = fatturato × mesi ÷ 12", valore: fabbisogno.map(T.euro) ?? "—"),
        ]
        righe.append(RigaAzienda(etichetta: "Coperture collegate",
                                 valore: coperture.isEmpty ? "nessuna" : coperture.map(\.nome).joined(separator: ", ")))
        righe.append(RigaAzienda(etichetta: "Capitale delle coperture", valore: T.euro(capitale)))
        let percentuale = fabbisogno.map { min(100, capitale / $0 * 100) }
        if let percentuale { righe.append(RigaAzienda(etichetta: "Copertura", valore: T.percento(percentuale))) }
        let frase: String
        if nonPertinente {
            frase = T.nonPertinente
        } else if let m = mesi, fabbisogno != nil, let f = fabbisogno {
            frase = T.frasePersonaChiave(nome: T.nome(c), mesi: m, capitale: capitale, fabbisogno: f)
        } else {
            frase = T.servono(mancano)
        }
        return ValutazioneAreaAzienda(area: .personaChiave, percentuale: nonPertinente ? nil : percentuale,
                                      nonPertinente: nonPertinente, frase: frase, mancano: nonPertinente ? [] : mancano,
                                      righe: righe)
    }

    private static func tfm(_ a: AziendaCliente, nonPertinente: Bool) -> ValutazioneAreaAzienda {
        let t = a.tfm
        let accantonato = t?.accantonato
        var righe = [RigaAzienda(etichetta: "Accantonato", valore: accantonato.map { $0 ? "Sì" : "No" } ?? "da indicare")]
        if let i = t?.importo { righe.append(RigaAzienda(etichetta: "Importo accantonato", valore: T.euro(i))) }
        if let n = t?.nota.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
            righe.append(RigaAzienda(etichetta: "Nota", valore: n))
        }
        let mancano = accantonato == nil ? ["sapere se è accantonato un trattamento di fine mandato"] : []
        let frase: String
        if nonPertinente {
            frase = T.nonPertinente
        } else if let accantonato {
            frase = accantonato ? T.tfmAccantonato(importo: t?.importo) : T.tfmNonAccantonato
        } else {
            frase = T.servono(mancano)
        }
        let percentuale: Double? = accantonato.map { $0 ? 100 : 0 }
        return ValutazioneAreaAzienda(area: .tfm, percentuale: nonPertinente ? nil : percentuale, nonPertinente: nonPertinente,
                                      frase: frase, mancano: nonPertinente ? [] : mancano, righe: righe)
    }

    private static func welfare(_ a: AziendaCliente, nonPertinente: Bool) -> ValutazioneAreaAzienda {
        let voci = a.welfare?.voci ?? []
        var righe = [RigaAzienda(etichetta: "Dipendenti", valore: a.dipendenti.map { "\($0)" } ?? "da inserire")]
        righe += voci.map { RigaAzienda(etichetta: $0.titolo, valore: $0.fatta ? "attiva" : "da valutare") }
        let mancano = voci.isEmpty ? ["le voci di welfare da considerare"] : []
        let frase = nonPertinente ? T.nonPertinente : (voci.isEmpty ? T.servono(mancano) : T.fraseWelfare(voci))
        return ValutazioneAreaAzienda(area: .welfare, percentuale: nonPertinente ? nil : quota(a.welfare),
                                      nonPertinente: nonPertinente, frase: frase, mancano: nonPertinente ? [] : mancano,
                                      righe: righe)
    }

    private static func passaggio(_ a: AziendaCliente, cliente c: Cliente, oggi: Date,
                                  nonPertinente: Bool) -> ValutazioneAreaAzienda {
        let voci = a.continuita?.voci ?? []
        let figli = etaFigli(c, oggi: oggi)
        var righe = [RigaAzienda(etichetta: "Figli", valore: figli.isEmpty ? "nessuno in famiglia" : T.etaFigli(figli))]
        righe += voci.map { RigaAzienda(etichetta: $0.titolo, valore: $0.fatta ? "fatto" : "da fare") }
        let mancano = voci.isEmpty ? ["i passi della continuità da considerare"] : []
        let frase = nonPertinente ? T.nonPertinente : (voci.isEmpty ? T.servono(mancano) : T.frasePassaggio(voci, figli: figli))
        return ValutazioneAreaAzienda(area: .passaggio, percentuale: nonPertinente ? nil : quota(a.continuita),
                                      nonPertinente: nonPertinente, frase: frase, mancano: nonPertinente ? [] : mancano,
                                      righe: righe)
    }
}

// MARK: - Testi

/// I testi della scheda «L'azienda»: modelli fissi riempiti con i dati veri, mai frasi inventate.
enum TestiAzienda {
    static let piedeFiscale = "Le valutazioni fiscali vanno sempre verificate con il commercialista dell'azienda."
    static let piedeProva = "Dati aziendali di prova."
    static let nonPertinente = "Segnata come non pertinente per questa azienda."
    static let tfmNonAccantonato = "Nessun trattamento di fine mandato accantonato: un'occasione da valutare con il commercialista."
    static let notaTFM = "Prisma non fa calcoli fiscali sul trattamento di fine mandato: deducibilità e tassazione sono da valutare con il commercialista."
    static let nessunaAzienda = "Nessun cliente ha un'azienda registrata: aggiungila dal dossier"

    static func euro(_ v: Double) -> String { FormatoCifra.euro.testo(v) }
    static func percento(_ v: Double) -> String { FormatoCifra.percentuale.testo(v) }

    /// «6» o «4,5».
    static func mesi(_ m: Double) -> String { FormatoCifra.mesi.testo(m) }

    /// Il nome di battesimo del cliente («Marco»), o «il titolare».
    static func nome(_ c: Cliente) -> String {
        c.nome.split(separator: " ").first.map(String.init) ?? "il titolare"
    }

    /// «2,1 mln €» da un milione in su, altrimenti «850.000 €».
    static func fatturatoBreve(_ v: Double) -> String {
        guard v >= 1_000_000 else { return euro(v) }
        let milioni = (v / 100_000).rounded() / 10
        let testo = milioni.rounded() == milioni ? String(Int(milioni))
            : String(format: "%.1f", milioni).replacingOccurrences(of: ".", with: ",")
        return "\(testo) mln\u{00A0}€"
    }

    /// «Fatturato 2025» o «Fatturato».
    static func etichettaFatturato(_ a: AziendaCliente) -> String {
        a.annoFatturato.map { "Fatturato \($0)" } ?? "Fatturato"
    }

    /// «Azienda di prova · 14 dipendenti · Marco Bianchi socio al 70% e amministratore»: le parti che ci sono, e
    /// «dipendenti da inserire» quando mancano.
    static func sottotitolo(_ a: AziendaCliente, cliente c: Cliente) -> String {
        var parti: [String] = []
        if a.diProva == true { parti.append("Azienda di prova") }
        if let f = a.forma, !a.ragioneSociale.localizedCaseInsensitiveContains(f.nome) { parti.append(f.nome) }
        if let s = a.settore, !s.isEmpty { parti.append(s) }
        if let d = a.dipendenti {
            parti.append(d == 1 ? "1 dipendente" : "\(d) dipendenti")
        } else {
            parti.append("dipendenti da inserire")
        }
        if let r = ruolo(a, cliente: c) { parti.append(r) }
        return parti.joined(separator: " · ")
    }

    /// «Marco Bianchi socio al 70% e amministratore», «Marco Bianchi titolare»; nil senza ruolo.
    static func ruolo(_ a: AziendaCliente, cliente c: Cliente) -> String? {
        var ruoli: [String] = []
        if a.titolare == true { ruoli.append("titolare") }
        if let q = a.quota { ruoli.append("socio al \(percento(q))") }
        if a.amministratore == true { ruoli.append("amministratore") }
        guard !ruoli.isEmpty else { return nil }
        return "\(c.nome) \(elenco(ruoli))"
    }

    /// «a», «a e b», «a, b e c».
    static func elenco(_ voci: [String]) -> String {
        switch voci.count {
        case 0: return ""
        case 1: return voci[0]
        default: return voci.dropLast().joined(separator: ", ") + " e " + (voci.last ?? "")
        }
    }

    /// «Per valutarla servono il fatturato e i mesi di fatturato a rischio.»
    static func servono(_ mancano: [String]) -> String {
        guard !mancano.isEmpty else { return "" }
        // «serve sapere…», «servono le voci…»: plurale con più dati o con un dato al plurale (articolo «i», «gli», «le»)
        let plurale = mancano.count > 1 || ["i ", "gli ", "le "].contains { mancano[0].hasPrefix($0) }
        return "Per valutarla \(plurale ? "servono" : "serve") \(elenco(mancano))."
    }

    /// «Se Marco si ferma, l'azienda perde circa 6 mesi di fatturato. Oggi nessuna copertura.»
    static func frasePersonaChiave(nome: String, mesi m: Double, capitale: Double, fabbisogno: Double) -> String {
        let quanti = m == 1 ? "1 mese" : "\(mesi(m)) mesi"
        let inizio = "Se \(nome) si ferma, l'azienda perde circa \(quanti) di fatturato."
        if capitale <= 0 { return inizio + " Oggi nessuna copertura." }
        if capitale >= fabbisogno { return inizio + " Le coperture collegate (\(euro(capitale))) bastano." }
        return inizio + " Coperti \(euro(capitale)) su \(euro(fabbisogno))."
    }

    static func tfmAccantonato(importo: Double?) -> String {
        let quanto = importo.map { " (\(euro($0)))" } ?? ""
        return "Trattamento di fine mandato accantonato\(quanto). Ogni aspetto fiscale va verificato con il commercialista."
    }

    /// Il titolo della voce dentro la frase: la prima lettera minuscola, se non è una sigla.
    static func inFrase(_ titolo: String) -> String {
        let t = titolo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let primo = t.first, t.count > 1 else { return t }
        let secondo = t[t.index(after: t.startIndex)]
        guard primo.isUppercase, secondo.isLowercase else { return t }
        return primo.lowercased() + t.dropFirst()
    }

    /// «Attive: buoni pasto. Da valutare: premi di risultato e previdenza complementare per i dipendenti.»
    static func fraseWelfare(_ voci: [VoceAzienda]) -> String {
        let attive = voci.filter(\.fatta).map { inFrase($0.titolo) }
        let daValutare = voci.filter { !$0.fatta }.map { inFrase($0.titolo) }
        if daValutare.isEmpty { return "Attive tutte le voci scelte: \(elenco(attive))." }
        if attive.isEmpty { return "Nessuna voce attiva. Da valutare: \(elenco(daValutare))." }
        return "Attive: \(elenco(attive)). Da valutare: \(elenco(daValutare))."
    }

    /// «di 14 e 10 anni», «di 9 anni».
    static func etaFigli(_ eta: [Int]) -> String {
        let anni = eta.map { "\($0)" }
        let ultimo = eta.last ?? 0
        return "\(elenco(anni)) \(ultimo == 1 ? "anno" : "anni")"
    }

    /// «Figli di 14 e 10 anni: fatto 1 passo su 5 (statuto e clausole valutati).»
    static func frasePassaggio(_ voci: [VoceAzienda], figli: [Int]) -> String {
        let fatti = voci.filter(\.fatta)
        let corpo: String
        if fatti.isEmpty {
            corpo = voci.count == 1 ? "il passo della continuità scelto non è ancora fatto."
                : "nessuno dei \(voci.count) passi della continuità è ancora fatto."
        } else if fatti.count == voci.count {
            corpo = "fatti tutti i passi della continuità scelti."
        } else {
            let quali = elenco(fatti.map { inFrase($0.titolo) })
            corpo = "\(fatti.count == 1 ? "fatto 1 passo" : "fatti \(fatti.count) passi") su \(voci.count) (\(quali))."
        }
        if figli.isEmpty {
            return corpo.prefix(1).uppercased() + corpo.dropFirst()
        }
        let chi = figli.count == 1 ? "Un figlio" : "Figli"
        return "\(chi) di \(etaFigli(figli)): \(corpo)"
    }

    /// Il piede della scheda: «Dati aziendali di prova.» solo sui dati di prova, la nota fiscale sempre.
    static func piede(_ a: AziendaCliente) -> String {
        a.diProva == true ? "\(piedeProva) \(piedeFiscale)" : piedeFiscale
    }

    /// L'avviso del collegamento verso Pratiche (il bisogno non è ancora tra quelli che la proposta costruisce da sola).
    static func avvisoProposta(_ area: AreaAzienda, nome: String) -> String {
        let bisogno = area == .personaChiave ? "la persona chiave (key man)" : "il welfare per i dipendenti"
        return "Pratiche › Proposta per \(nome): scegli tu prodotto e canale per \(bisogno). Senza prodotti adatti in archivio la proposta non si costruisce."
    }
}
