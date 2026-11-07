import Foundation

/// I testi del report «Un anno insieme», ricavati dalle cifre di `MotoreAnnoInsieme`. Tono da documento per il
/// cliente e attento alla conformità: si racconta il passato come tale, niente promesse sul futuro, le stime sono
/// dette stime e ogni pagina porta le avvertenze («I rendimenti passati non sono indicativi di quelli futuri»).
struct TestiAnnoInsieme {
    static let titolo = "Un anno insieme"

    /// Le avvertenze del piede di ogni pagina (9 pt).
    static let avvertenza = "I rendimenti passati non sono indicativi di quelli futuri. I valori sono quelli registrati alle loro date "
        + "e, fra due valori noti, stimati in linea retta; le stime si basano su ipotesi e non costituiscono garanzia di risultato. "
        + "Documento informativo: non costituisce offerta né raccomandazione; fanno fede il KID e la documentazione contrattuale di ciascun prodotto."

    /// Un tono per la nota sotto una cifra (il colore lo sceglie la carta).
    enum Tono {
        case neutro, positivo, attenzione
    }

    /// Una cifra in un riquadro: etichetta, valore, nota.
    struct Cifra: Identifiable {
        let etichetta: String
        let valore: String
        var nota = ""
        var tono = Tono.neutro
        var id: String { etichetta }
    }

    let a: AnnoInsieme

    init(_ a: AnnoInsieme) {
        self.a = a
    }

    /// «Un anno insieme · 2026»: la voce di Prospetti, con l'anno in corso.
    static func nomeVoce(_ oggi: Date) -> String {
        "\(titolo) · \(Calendar.current.component(.year, from: oggi))"
    }

    var cliente: String { a.cliente.nome }
    var data: Date { a.oggi }
    var titoloDocumento: String { "\(Self.titolo) · \(a.anno)" }
    /// «nei prossimi 12 mesi»: il periodo vero di «cosa ci aspetta» (da oggi a `MotoreAnnoInsieme.mesiAvanti` mesi),
    /// che a fine anno comprende anche le date dell'anno in corso: per questo non si dice «nel» anno successivo.
    static var periodoAvanti: String { "nei prossimi \(MotoreAnnoInsieme.mesiAvanti) mesi" }
    /// «Nei prossimi 12 mesi»: il titolo della colonna della prima pagina.
    static var titoloPeriodoAvanti: String { "Nei prossimi \(MotoreAnnoInsieme.mesiAvanti) mesi" }
    var avvertenzaPiede: String { Self.avvertenza + " Preparato per \(cliente) il \(CifreDoc.data(a.oggi))." }

    // MARK: - Formati

    private static let formatoMese = Formati.formato("MMMM")
    private static let formatoMeseBreve = Formati.formato("MMM")
    private static let formatoMeseAnno = Formati.formato("MMMM yyyy")

    /// «GEN», «MAR»: il mese sulla linea dell'anno (senza il punto finale).
    static func meseBreve(_ d: Date) -> String {
        formatoMeseBreve.string(from: d).replacingOccurrences(of: ".", with: "").uppercased()
    }

    static func mese(_ d: Date) -> String { formatoMese.string(from: d) }
    static func meseAnno(_ d: Date) -> String { formatoMeseAnno.string(from: d) }

    /// «37%»: una quota (0–1) in percentuale intera.
    static func quota(_ q: Double) -> String { CifreDoc.percento(q * 100, decimali: 0) }

    // MARK: - Prima pagina

    var sopratitolo: String { "Il \(a.anno) di \(cliente)" }
    var titoloPrima: String { "\(Self.titolo)." }
    var sottotitolo: String { "Cosa è successo, cosa abbiamo costruito e cosa ci aspetta \(Self.periodoAvanti)." }

    /// Le tre cifre della prima pagina: patrimonio, messi da parte, l'obiettivo principale (o la protezione).
    var cifrePrima: [Cifra] {
        var c: [Cifra] = []
        let v = a.variazione
        c.append(Cifra(etichetta: "Patrimonio", valore: CifreDoc.euro(a.patrimonioFine),
                       nota: abs(v) < 0.5 ? "come a gennaio" : "\(CifreDoc.euroSegno(v)) da gennaio",
                       tono: v >= 0.5 ? .positivo : (v <= -0.5 ? .attenzione : .neutro)))
        let nota: String
        if a.versamentoMensile > 0.5 {
            nota = "\(CifreDoc.euro(a.versamentoMensile)) al mese"
        } else if a.versamenti > 0.5 {
            nota = "nei tuoi piani"
        } else {
            nota = "nessun versamento"
        }
        c.append(Cifra(etichetta: "Messi da parte", valore: CifreDoc.euro(a.versamenti), nota: nota))
        if let o = a.obiettivoPrincipale {
            c.append(Cifra(etichetta: o.obiettivo.titolo, valore: Self.quota(o.quotaFine),
                           nota: "era al \(Self.quota(o.quotaInizio))", tono: o.avvicinato ? .positivo : .neutro))
        } else {
            let n = a.coperture.count
            c.append(Cifra(etichetta: "Protezione", valore: n == 1 ? "1 copertura" : "\(n) coperture",
                           nota: a.scoperti.isEmpty ? "nessun rischio scoperto" : "\(a.scoperti.count) da completare",
                           tono: a.scoperti.isEmpty ? .neutro : .attenzione))
        }
        return c
    }

    /// «Come è andata»: il patrimonio, i versamenti, l'andamento, il momento più difficile, la protezione.
    var comeEAndata: String {
        var frasi: [String] = []
        if a.patrimonioInizio > 0.5 || a.patrimonioFine > 0.5 {
            frasi.append("Dal 1° gennaio il tuo patrimonio è passato da \(CifreDoc.euro(a.patrimonioInizio)) a \(CifreDoc.euro(a.patrimonioFine)).")
        }
        if a.versamenti > 0.5 {
            frasi.append(a.versamentoMensile > 0.5
                         ? "Hai messo da parte \(CifreDoc.euro(a.versamenti)) con i versamenti periodici, mese dopo mese."
                         : "Hai messo da parte \(CifreDoc.euro(a.versamenti)) nei tuoi piani.")
        }
        if a.esposte {
            frasi.append(fraseAndamento)
        }
        if let c = a.calo {
            frasi.append("A \(Self.mese(c.data)) i valori sono scesi di circa \(CifreDoc.percento(c.quota * 100, decimali: 0)) da un mese all'altro"
                         + (c.ripreso ? " e poi si sono ripresi." : "; li seguiamo insieme."))
        }
        frasi.append(fraseProtezione)
        return frasi.joined(separator: " ")
    }

    /// L'andamento delle posizioni finanziarie, al netto dei versamenti: un dato del passato.
    var fraseAndamento: String {
        let percento = a.andamentoPercento.map { " (\(CifreDoc.variazione($0)))" } ?? ""
        return "Al netto dei versamenti, l'andamento delle posizioni finanziarie è stato di \(CifreDoc.euroSegno(a.andamento))\(percento)."
    }

    var fraseProtezione: String {
        if a.coperture.isEmpty {
            return a.scoperti.isEmpty ? "Non ci sono coperture in essere." : "Non ci sono coperture in essere: ne parliamo insieme."
        }
        let tutto = a.coperture.filter(\.tuttoAnno).count
        let nuove = a.coperture.filter(\.nuova).count
        if tutto == a.coperture.count {
            return a.coperture.count == 1 ? "La tua copertura è rimasta attiva tutto l'anno." : "Le tue \(a.coperture.count) coperture sono rimaste attive tutto l'anno."
        }
        return "Hai \(a.coperture.count) coperture in essere" + (nuove > 0 ? ", \(nuove) partite quest'anno." : ".")
    }

    /// «Nei prossimi 12 mesi»: le prime cose che ci aspettano (al più tre).
    var nelProssimoAnno: [String] {
        Array((cosaCiAspetta + prossimiPassi).prefix(Self.righePrima))
    }

    static let righePrima = 3

    // MARK: - Cosa è successo

    var cifreAnno: [Cifra] {
        [Cifra(etichetta: "Al 1° gennaio", valore: CifreDoc.euro(a.patrimonioInizio), nota: "patrimonio"),
         Cifra(etichetta: "Oggi", valore: CifreDoc.euro(a.patrimonioFine), nota: "patrimonio",
               tono: a.variazione >= 0.5 ? .positivo : .neutro),
         Cifra(etichetta: "Versamenti dell'anno", valore: CifreDoc.euro(a.versamenti),
               nota: a.incassi > 0.5 ? "incassati \(CifreDoc.euro(a.incassi))" : "sui piani finanziari"),
         Cifra(etichetta: "Andamento", valore: a.esposte ? CifreDoc.euroSegno(a.andamento) : "—",
               nota: a.esposte ? "al netto dei versamenti" : "nessuna posizione finanziaria")]
    }

    var sottotitoloAnno: String {
        "Dal 1° gennaio al \(CifreDoc.data(a.oggi)), con i valori registrati delle tue posizioni."
    }

    /// Le scelte dell'anno: proposte accettate e posizioni nuove.
    var scelte: [(nome: String, nota: String, canale: Canale)] {
        var elenco: [(nome: String, nota: String, canale: Canale)] = []
        for p in a.accettate {
            elenco.append((nome: p.nome, nota: "proposta accettata", canale: p.canale))
        }
        for p in a.nuove {
            let nota = p.decorrenza.map { "dal \(CifreDoc.data($0))" } ?? "nuova"
            elenco.append((nome: p.nome, nota: nota, canale: p.canale))
        }
        return elenco
    }

    // MARK: - Obiettivi

    var titoloObiettivi: String {
        let avvicinati = a.obiettivi.filter(\.avvicinato).count
        if avvicinati == 0 { return "I tuoi obiettivi." }
        return avvicinati == 1 ? "Un obiettivo più vicino." : "\(avvicinati) obiettivi più vicini."
    }

    func notaObiettivo(_ o: AnnoInsieme.ObiettivoAnno) -> String {
        "\(CifreDoc.euro(o.obiettivo.importo)) entro \(Self.meseAnno(o.obiettivo.scadenza)) · da parte \(CifreDoc.euro(o.accantonato))"
    }

    func confrontoObiettivo(_ o: AnnoInsieme.ObiettivoAnno) -> String {
        "era al \(Self.quota(o.quotaInizio)) · oggi \(Self.quota(o.quotaFine))"
    }

    // MARK: - Protezione

    var titoloProtezione: String {
        if a.coperture.isEmpty { return "La protezione da costruire." }
        return a.scoperti.isEmpty ? "La protezione, tutto l'anno." : "Cosa è protetto, cosa ancora no."
    }

    func statoCopertura(_ c: AnnoInsieme.CoperturaAnno) -> String {
        if c.nuova { return c.posizione.decorrenza.map { "attiva dal \(CifreDoc.data($0))" } ?? "nuova quest'anno" }
        return c.tuttoAnno ? "attiva tutto l'anno" : "attiva"
    }

    func fraseCasoMorte() -> String? {
        guard a.fabbisognoVita > 0.5 else { return nil }
        let gia = max(0, a.fabbisognoVita - a.divarioVita)
        if a.divarioVita < 0.5 { return "Il capitale caso morte copre il fabbisogno stimato della famiglia (\(CifreDoc.euro(a.fabbisognoVita)))." }
        return "Già assicurati \(CifreDoc.euro(gia)) su un fabbisogno stimato di \(CifreDoc.euro(a.fabbisognoVita)): mancano \(CifreDoc.euro(a.divarioVita))."
    }

    // MARK: - Mercati

    var titoloMercati: String { "I mercati nel \(a.anno)." }

    /// Com'è andato il mercato per le posizioni del cliente: in modo neutro, senza giudizi sul futuro.
    var testoMercati: [String] {
        var t: [String] = []
        for e in a.crisi {
            t.append("Quest'anno i mercati hanno attraversato una fase difficile: \(e.crisi.titolo.lowercased()) (\(e.crisi.periodo)). "
                     + "Applicata alle tue posizioni di oggi, una fase così peserebbe circa \(CifreDoc.euro(e.perdita)), il \(CifreDoc.percento(e.quota * 100, decimali: 0)) del patrimonio finanziario: è una stima.")
        }
        if let c = a.calo {
            t.append("Il momento più difficile è stato \(Self.mese(c.data)): da un mese all'altro i valori registrati delle posizioni finanziarie sono scesi di circa \(CifreDoc.percento(c.quota * 100, decimali: 0)). "
                     + (c.ripreso ? "A oggi sono tornati sopra il livello di prima." : "A oggi non sono ancora tornati al livello di prima: i mercati hanno fasi di calo e di ripresa, e li guardiamo su un orizzonte più lungo di un anno."))
        } else if a.crisi.isEmpty {
            t.append("Nei valori registrati delle tue posizioni non ci sono stati cali oltre il \(CifreDoc.percento(MotoreAnnoInsieme.sogliaCalo * 100, decimali: 0)) da un mese all'altro.")
        }
        t.append(fraseAndamento)
        if a.versamentoMensile > 0.5 {
            t.append("I versamenti periodici sono continuati per tutto il periodo: entrano un po' alla volta, nei momenti alti e in quelli bassi.")
        }
        return t
    }

    /// Le crisi del passato da mettere accanto all'anno: solo se l'anno ha avuto un calo o una crisi.
    var crisiAConfronto: [CrisiStorica] {
        (a.calo != nil || !a.crisi.isEmpty) ? MotoreResistenza.crisiDelPassato : []
    }

    // MARK: - Cosa ci aspetta

    var titoloProssimo: String { "Cosa ci aspetta \(Self.periodoAvanti)." }

    /// Il prossimo incontro o il riesame annuale.
    var incontroProssimo: String {
        if let p = a.prossimoIncontro {
            return "\(p.tipo == .altro ? p.titolo : p.tipo.nome): \(CifreDoc.data(p.inizio))"
        }
        if let r = a.riesameEntro { return "Il riesame annuale, entro \(Self.meseAnno(r))" }
        return "Fissare insieme il riesame annuale"
    }

    /// Le scadenze dei prossimi 12 mesi, con la data, e il prossimo incontro.
    var cosaCiAspetta: [String] {
        [incontroProssimo] + a.scadenze.map { "\($0.titolo) · \(CifreDoc.data($0.data))" }
    }

    /// I prossimi passi da fare insieme: rischi scoperti, obiettivi da rivedere, proposte aperte.
    var prossimiPassi: [String] {
        var passi: [String] = []
        for r in a.scoperti.prefix(2) {
            passi.append("Parlare insieme della tutela «\(r.rischio.nome)»")
        }
        for o in a.obiettivi where !o.avvicinato && o.quotaFine < 1 {
            passi.append("Rivedere il piano per «\(o.obiettivo.titolo)»")
        }
        for p in a.proposteAperte.prefix(2) {
            passi.append("Decidere insieme sulla proposta «\(p.nome)»")
        }
        if a.obiettivi.isEmpty {
            passi.append("Dare un importo e una data ai tuoi progetti")
        }
        return Array(passi.prefix(Self.passiMassimi))
    }

    /// I prossimi passi al massimo (quelli che stanno nella pagina).
    static let passiMassimi = 5

    // MARK: - Parole da non usare

    /// Parole di promessa che il report non usa mai (la prova le cerca nel PDF): «garantito» si dice solo per le
    /// garanzie contrattuali vere, che questo report non tratta.
    static let paroleVietate = ["garantito", "garantita", "garantiti", "garantite", "sicuro", "sicura", "sicuri", "sicure",
                                "certo", "certa", "certi", "certe"]
}
