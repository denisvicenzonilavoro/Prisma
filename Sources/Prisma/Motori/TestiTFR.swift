import Foundation

/// I testi del confronto «TFR in azienda o nel fondo», ricavati dai numeri (giro 6, specifica 11 §6.2–6.3;
/// rivisti con il rendimento netto, la prestazione metà in capitale e metà in rendita e il costo dei contributi).
/// Il report si rivolge al cliente con il tu. Nessun numero normativo scritto qui: aliquote, limiti e quote
/// si leggono da `RegoleTFR` e `RegoleFiscali`, così una norma nuova cambia anche i testi.
struct TestiTFR {
    let e: EsitoTFR
    let cliente: String
    let data: Date
    /// Età del cliente oggi, se nota (per la tabella anno per anno: «1 · 48 anni»).
    let eta: Int?

    init(_ e: EsitoTFR, cliente: Cliente?, data: Date = Date()) {
        self.e = e
        self.cliente = cliente?.nome ?? "Cliente"
        self.data = data
        self.eta = cliente?.dataNascita.flatMap { Calendar.current.dateComponents([.year], from: $0, to: data).year }
    }

    static let titolo = "TFR in azienda o nel fondo pensione"
    var piede: String { "\(Self.titolo) · \(cliente) · \(CifreDoc.data(data)) · \(TestiValutazione.consulente)" }
    static let avvertenza = "Stime con rendimenti e inflazione costanti e con le regole fiscali di oggi: non sono una previsione né un consiglio."

    var ruoloConsulente: String {
        switch e.ipotesi.canale {
        case .alleanza: return "Consulente Alleanza Assicurazioni"
        case .indipendente: return "Consulenza finanziaria"
        }
    }

    var canali: [Canale] { [e.ipotesi.canale] }

    var nomeFondo: String {
        let n = e.ipotesi.nomeFondo.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "Fondo pensione" : n
    }

    /// Anni alla pensione: «1 anno», «20 anni».
    var anniAllaPensione: String { e.ipotesi.anni == 1 ? "1 anno" : "\(e.ipotesi.anni) anni" }

    /// Sotto questa differenza (in euro) le due strade si equivalgono.
    static let sogliaEquivalenza = 0.5

    /// «netto» o «lordo»: la base in cui è scritto il rendimento del fondo (e il pareggio).
    var base: String { e.ipotesi.rendimentoNetto ? "netto" : "lordo" }

    /// I nomi delle strade, uguali a schermo, nel prospetto e nel report.
    static let stradaAzienda = "TFR in azienda"
    static let stradaFondo = "Nel fondo pensione"
    static let stradaContributi = "Fondo con contributi"
    /// Il vantaggio del fondo con contributi tolto quanto costano al cliente.
    static let vantaggioContributi = "Vantaggio, tolto il costo"

    /// Con 50 o più dipendenti il TFR non conferito va al Fondo di Tesoreria INPS: stesse regole, nessun rischio datore.
    var notaTesoreria: String? {
        guard e.ipotesi.aziendaGrande == true else { return nil }
        return "Con almeno \(RegoleTFR.dipendentiTesoreria) dipendenti il TFR non conferito va al Fondo di Tesoreria INPS: si rivaluta e si tassa allo stesso modo."
    }

    // MARK: - Il confronto

    var titoloConfronto: String {
        let d = e.differenza
        if d > Self.sogliaEquivalenza { return "Nel fondo pensione ti resterebbero circa \(CifreDoc.euro(d)) in più" }
        if d < -Self.sogliaEquivalenza { return "Lasciato in azienda, il TFR ti lascerebbe circa \(CifreDoc.euro(-d)) in più" }
        return "Le due strade si equivalgono"
    }

    /// Di che TFR si parla: «TFR futuro di 25 anni» (o «metà del TFR futuro» per il vecchio iscritto).
    var oggetto: String {
        let quota = e.ipotesi.quotaConferitaEffettiva
        if quota < 100 { return "\(Self.il(Formati.percentuale(quota))) del TFR futuro di \(anniAllaPensione)" }
        return "TFR futuro di \(anniAllaPensione)"
    }

    /// `oggetto` a inizio frase: «Il 50% del TFR futuro…», «TFR futuro di 25 anni».
    var oggettoInizio: String {
        let o = oggetto
        return o.prefix(1).uppercased() + o.dropFirst()
    }

    var sottotitoloConfronto: String {
        "\(oggettoInizio), netto: \(CifreDoc.euro(e.azienda.netto)) in azienda, \(CifreDoc.euro(e.fondo.netto)) nel fondo. Il TFR già maturato resta in azienda."
    }

    /// Come arriva il netto del fondo: «Subito 20.000 € in capitale, poi circa 150 € al mese di rendita».
    static func testoPrestazione(_ s: StradaTFR) -> String {
        guard let p = s.prestazione, !p.tuttoCapitale else {
            return "Tutto in capitale: la rendita sarebbe piccola"
        }
        return "Subito \(CifreDoc.euro(p.capitale)) in capitale, poi circa \(CifreDoc.euro(p.renditaMensile)) al mese di rendita"
    }

    /// La rivalutazione netta del TFR in azienda e l'inflazione: «del 2,49% netto con un'inflazione del 2%».
    private var rivalutazioneInParole: String {
        "\(Self.del(CifreDoc.percento(e.rivalutazioneNetta, decimali: 2))) netto con un'inflazione \(Self.del(Formati.percentuale(e.ipotesi.inflazione)))"
    }

    /// Le aliquote all'uscita: «il 13,5% invece del 28,4%».
    private var aliquoteInParole: (fondo: String, azienda: String) {
        (CifreDoc.percento(e.fondo.aliquota, decimali: 1), CifreDoc.percento(e.azienda.aliquota, decimali: 1))
    }

    /// Il pareggio in una frase breve: «Il fondo conviene se rende più del 2,10% netto l'anno».
    static func frase(pareggio p: PareggioTFR, base: String, netta: Bool) -> String {
        switch p {
        case .a:
            let soglia = CifreDoc.percento(p.nellaBase(netta: netta) ?? 0, decimali: 2)
            return "Il fondo conviene se rende più \(del(soglia)) \(base) l'anno"
        case .sempre:
            return "Il fondo conviene anche se perde \(il(Formati.percentuale(abs(RegoleTFR.pareggioMinimo)))) l'anno"
        case .mai:
            return "Il fondo non raggiunge il TFR nemmeno al \(Formati.percentuale(RegoleTFR.pareggioMassimo)) l'anno"
        }
    }

    var frasePareggio: String { Self.frase(pareggio: e.pareggio, base: base, netta: e.ipotesi.rendimentoNetto) }

    /// Perché il fondo può rendere meno (o deve rendere di più) del TFR in azienda.
    var perchePareggio: String {
        let (fondo, azienda) = aliquoteInParole
        switch e.pareggio {
        case .a(_, let netto):
            let tfr = "Il TFR in azienda si rivaluta \(rivalutazioneInParole): "
            if netto < e.rivalutazioneNetta - 0.005 {
                return tfr + "il fondo può rendere meno perché all'uscita paga \(Self.il(fondo)) invece \(Self.del(azienda))."
            } else if netto > e.rivalutazioneNetta + 0.005 {
                return tfr + "il fondo deve rendere di più perché all'uscita paga \(Self.il(fondo)) contro \(Self.il(azienda)) del TFR in azienda."
            }
            return tfr + "all'uscita le due strade pagano più o meno la stessa imposta."
        case .sempre:
            return "All'uscita il fondo paga \(Self.il(fondo)) invece \(Self.del(azienda)) del TFR in azienda."
        case .mai:
            return "Controlla le ipotesi: rendimento, aliquota e anni."
        }
    }

    var testoPareggio: String {
        var soglia = frasePareggio
        if case .a(_, let netto) = e.pareggio, !e.ipotesi.rendimentoNetto {
            soglia += " (\(CifreDoc.percento(netto, decimali: 2)) al netto di costi e imposta)."
        } else {
            soglia += "."
        }
        return soglia + " " + perchePareggio
    }

    /// Il titolo della slide del pareggio nel report.
    var titoloPareggio: String { frasePareggio }

    /// Il pareggio in breve, per la sintesi.
    var pareggioBreve: String {
        switch e.pareggio {
        case .a:
            return "\(frasePareggio), contro \(Self.il(CifreDoc.percento(e.rivalutazioneNetta, decimali: 2))) netto del TFR in azienda."
        case .sempre, .mai:
            return frasePareggio + "."
        }
    }

    /// Il pareggio con i contributi, per la nota del KPI e del report.
    var pareggioContributiBreve: String? {
        guard let p = e.pareggioContributi else { return nil }
        return "Con i contributi, tolto quanto ti costano: " + Self.frase(pareggio: p, base: base, netta: e.ipotesi.rendimentoNetto)
            .replacingOccurrences(of: "Il fondo", with: "il fondo") + "."
    }

    /// «l'1,2% tuo e l'1,6% del datore»; nil senza contributi.
    var contributiInParole: String? {
        let i = e.ipotesi
        var parti: [String] = []
        if i.contributoLavoratore > 0 { parti.append("\(Self.il(Formati.percentuale(i.contributoLavoratore))) tuo") }
        if i.contributoDatore > 0 { parti.append("\(Self.il(Formati.percentuale(i.contributoDatore))) del datore") }
        return parti.isEmpty ? nil : parti.joined(separator: " e ")
    }

    /// «al 2% l'anno (l'inflazione)»: il tasso a cui si valuta quanto costano i contributi.
    var tassoAlternativoInParole: String {
        let t = Formati.percentuale(e.tassoAlternativo)
        return e.ipotesi.tassoAlternativo == nil ? "\(Self.al(t)) l'anno, come l'inflazione" : "\(Self.al(t)) l'anno"
    }

    /// Quanto ti costano i contributi, in parole: «Versi 20.047 € di tasca tua e risparmi 7.772 € di IRPEF».
    var tascaPropriaInParole: String? {
        guard e.versatoLavoratore > 0.5 else { return nil }
        return "Versi \(CifreDoc.euro(e.versatoLavoratore)) di tasca tua e risparmi \(CifreDoc.euro(e.risparmioIrpef)) di IRPEF: ti costano \(CifreDoc.euro(e.tascaPropria))."
    }

    var testoContributi: String? {
        guard let c = e.fondoContributi, let parole = contributiInParole, let d = e.differenzaContributi else { return nil }
        var testo = "Aggiungendo \(parole): \(CifreDoc.euro(c.netto)) netti."
        if let tasca = tascaPropriaInParole {
            testo += " " + tasca
            testo += " Se li tenessi da parte \(tassoAlternativoInParole), alla pensione varrebbero \(CifreDoc.euro(e.costoContributi))."
        }
        if d > Self.sogliaEquivalenza {
            testo += " Tolto questo, ti restano \(CifreDoc.euro(d)) in più che con il TFR in azienda."
        } else if d < -Self.sogliaEquivalenza {
            testo += " Tolto questo, ti restano \(CifreDoc.euro(-d)) in meno che con il TFR in azienda."
        } else {
            testo += " Tolto questo, le due strade si equivalgono."
        }
        return testo
    }

    /// I punti della sintesi (titolo, testo).
    var sintesi: [(String, String)] {
        var s: [(String, String)] = [("Le due strade", titoloConfronto + "."), ("Quanto deve rendere il fondo", pareggioBreve)]
        s.append(("Come lo ricevi", Self.testoPrestazione(e.fondo) + "."))
        if let c = e.fondoContributi, let d = e.differenzaContributi {
            s.append((Self.stradaContributi, "\(CifreDoc.euro(c.netto)) netti; tolto quanto ti costano, \(CifreDoc.euroSegno(d)) rispetto al TFR in azienda."))
        }
        s.append(("In euro di oggi", "In azienda \(CifreDoc.euro(e.azienda.reale)), nel fondo \(CifreDoc.euro(e.fondo.reale))."))
        s.append(("Da sapere", "La scelta di versare il TFR al fondo non si può revocare."))
        return s
    }

    /// Le semplificazioni che possono cambiare la conclusione, come pillole sopra i risultati.
    var pillole: [String] {
        let i = e.ipotesi
        var p = ["Solo TFR futuro"]
        if i.quotaConferitaEffettiva < 100 { p.append("\(Formati.percentuale(i.quotaConferitaEffettiva)) del TFR al fondo") }
        if let pr = e.fondo.prestazione, pr.tuttoCapitale {
            p.append("Fondo tutto in capitale")
        } else {
            p.append("Fondo: \(Formati.percentuale(RegoleTFR.quotaCapitaleMassima)) in capitale")
        }
        p.append(i.rendimentoNetto ? "Rendimento netto" : "Rendimento lordo")
        if i.aliquotaTFR != nil {
            p.append("Aliquota indicata")
        } else if e.maturatoStimato {
            p.append("Maturato stimato")
        } else if (i.anniServizio ?? 0) == 0 && i.tfrMaturato == nil {
            p.append("Senza anni già fatti")
        }
        return p
    }

    /// Avvisi sulle ipotesi (frasi brevi).
    var avvisi: [String] {
        var a: [String] = []
        if e.datoreSenzaLavoratore {
            a.append("Il datore di solito versa il suo contributo solo se versa anche il cliente: controlla il contratto.")
        }
        if let t = notaTesoreria { a.append(t) }
        return a
    }

    // MARK: - Metodo, semplificazioni, avvertenze

    /// "13,5", "0,30": un numero senza il segno di percentuale.
    private static func numero(_ v: Double, decimali: Int) -> String {
        String(CifreDoc.percento(v, decimali: decimali).dropLast())
    }

    /// L'anno di partecipazione dopo cui l'aliquota della prestazione comincia a scendere (15) e quello in cui
    /// arriva al minimo (35), ricavati da `RegoleFiscali.aliquotaPrevidenza`.
    private static var annoRiduzione: Int {
        (0...100).first { RegoleFiscali.aliquotaPrevidenza(anni: $0 + 1) < RegoleFiscali.previdenzaBase } ?? 0
    }

    static var metodo: [String] {
        let f = RegoleFiscali.self
        let r = RegoleTFR.self
        return [
            "Quota di TFR: retribuzione utile al TFR / \(numero(r.divisore, decimali: 1)), meno lo \(CifreDoc.percento(r.contributoIVS, decimali: 2)) di contributo IVS (art. 2120 c.c.; art. 3 L. 297/1982): \(il(CifreDoc.percento(r.quotaAnnua, decimali: 2))) della retribuzione.",
            "In azienda (o al Fondo di Tesoreria INPS nelle aziende con almeno \(r.dipendentiTesoreria) dipendenti): rivalutazione al 31 dicembre \(del(Formati.percentuale(r.rivalutazioneFissa))) più \(il(Formati.percentuale(r.quotaInflazione * 100))) dell'inflazione FOI, esclusa la quota dell'anno, con l'imposta sostitutiva \(del(Formati.percentuale(r.impostaRivalutazione))) trattenuta ogni anno (art. 11, c. 3, D.Lgs. 47/2000).",
            "Alla fine del rapporto il TFR, tolte le rivalutazioni già tassate, va in tassazione separata con l'aliquota media IRPEF del reddito di riferimento: tutto il TFR (maturato e futuro) × 12 / tutti gli anni di servizio (art. 17 e 19 TUIR). L'imposta trattenuta dal datore è provvisoria: l'Agenzia delle Entrate la riliquida e chiede o restituisce la differenza.",
            "Nel fondo pensione: rendimento netto come lo pubblicano la COVIP e le schede del fondo (già tolti costi e imposta); con il rendimento lordo Prisma toglie i costi (ISC) e l'imposta \(del(Formati.percentuale(f.previdenzaRendimenti))) sui risultati positivi, \(Formati.percentuale(f.titoliStato)) sulla parte in titoli di Stato (art. 17 D.Lgs. 252/2005). Alla prestazione si tassano TFR e contributi dedotti con \(il(Formati.percentuale(f.previdenzaBase))), che scende di \(numero(f.previdenzaRiduzione, decimali: 2)) punti per ogni anno di partecipazione oltre il \(annoRiduzione)° fino al \(Formati.percentuale(f.previdenzaMinima)) (art. 11, c. 6).",
            "Alla pensione al massimo \(il(Formati.percentuale(r.quotaCapitaleMassima))) del fondo si ritira in capitale, il resto diventa rendita; tutto in capitale se convertendo \(il(Formati.percentuale(r.quotaProvaRendita))) la rendita è meno \(del(Formati.percentuale(r.quotaAssegnoSociale))) dell'assegno sociale (art. 11, c. 3). Rendita stimata con un coefficiente \(del(CifreDoc.percento(r.coefficienteRendita, decimali: 1))) l'anno.",
            "Contributi del lavoratore e del datore deducibili insieme fino a \(CifreDoc.euro(f.limiteDeducibilita)) l'anno (art. 8, c. 4, D.Lgs. 252/2005; dal 2026); il contributo del datore spetta di norma solo se aderisci al fondo di categoria e versi il minimo del contratto collettivo.",
            "Chi era iscritto alla previdenza obbligatoria prima del 29 aprile 1993 può conferire solo una parte del TFR (almeno quella del contratto, altrimenti \(il(Formati.percentuale(r.quotaVecchiIscritti)))): il confronto riguarda solo quella parte.",
            "Rendimento di pareggio: il rendimento costante del fondo, netto o lordo come le ipotesi, a cui il netto alla pensione è uguale a quello del TFR in azienda.",
        ]
    }

    static var semplificazioni: [String] {
        [
            "Rendimenti, inflazione e crescita della retribuzione costanti; quote e contributi a fine anno (per il fondo è prudente: nella realtà entrano ogni mese o trimestre).",
            "Il TFR già maturato resta in azienda in tutti e due i casi e non entra nel confronto: conta solo per l'aliquota.",
            "Aliquota della tassazione separata con gli scaglioni IRPEF di oggi sugli importi nominali (l'aliquota si può anche indicare a mano); la riliquidazione dell'Agenzia delle Entrate non si stima.",
            "Rendita stimata con un coefficiente fisso (\(CifreDoc.percento(RegoleTFR.coefficienteRendita, decimali: 1)) l'anno): quello vero dipende dal fondo, dall'età e dal tipo di rendita.",
            "Risparmio IRPEF sul reddito da lavoro meno \(il(Formati.percentuale(RegoleTFR.contributiDipendente))) di contributi INPS, senza detrazioni né addizionali; il costo dei tuoi contributi è valutato all'inflazione, o al tasso indicato, fino alla pensione.",
            "Anticipazioni, riscatti, cambi di lavoro e garanzie dei comparti non considerati.",
        ]
    }

    static let daSapere: [String] = [
        "La scelta di versare il TFR futuro al fondo pensione non si può revocare (art. 8 D.Lgs. 252/2005).",
        "Nel fondo il valore oscilla con i mercati secondo il comparto; il TFR in azienda non scende mai.",
        "Le anticipazioni sono possibili in tutti e due i casi, con regole e imposte diverse.",
    ]

    // MARK: - Articoli davanti ai numeri

    /// true se il numero scritto si legge con una vocale: 1 («uno»), 8 («otto», «ottanta»), 11 («undici»).
    static func iniziaConVocale(_ numero: String) -> Bool {
        let c = Array(numero)
        guard let primo = c.first else { return false }
        if primo == "8" { return true }
        guard primo == "1" else { return false }
        // «1», «1,5%»: uno; «11», «11,3%»: undici; «1.500», «12», «150»: no
        let secondo: Character? = c.count > 1 ? c[1] : nil
        if secondo == nil || secondo == "," || secondo == "%" || secondo == " " { return true }
        if secondo == "1" {
            let terzo: Character? = c.count > 2 ? c[2] : nil
            return terzo == nil || terzo == "," || terzo == "%" || terzo == " "
        }
        return false
    }

    /// true se il numero si legge «zero»: vuole «lo», «dello», «allo».
    private static func iniziaConZero(_ numero: String) -> Bool { numero.first == "0" }

    /// «del 2%», «dell'1,5%», «dello 0,8%».
    static func del(_ numero: String) -> String {
        if iniziaConZero(numero) { return "dello \(numero)" }
        return iniziaConVocale(numero) ? "dell'\(numero)" : "del \(numero)"
    }
    /// «il 2%», «l'8%», «lo 0,8%».
    static func il(_ numero: String) -> String {
        if iniziaConZero(numero) { return "lo \(numero)" }
        return iniziaConVocale(numero) ? "l'\(numero)" : "il \(numero)"
    }
    /// «al 2%», «all'1,5%», «allo 0,8%».
    static func al(_ numero: String) -> String {
        if iniziaConZero(numero) { return "allo \(numero)" }
        return iniziaConVocale(numero) ? "all'\(numero)" : "al \(numero)"
    }
}
