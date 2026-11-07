import Foundation

/// Una riga del prima e dopo di uno scenario: la voce, la cifra di oggi e quella con lo scenario.
struct RigaScenarioRuby: Codable, Equatable, Identifiable {
    /// Chiave stabile («pensionePubblica», «rendita», «divario»…).
    var chiave: String
    var voce: String
    var oggi: String
    var scenario: String
    var valoreOggi: Double
    var valoreScenario: Double
    /// La differenza già scritta («− 280 €», «+ 12 punti»); nil se non serve.
    var differenza: String?

    var id: String { chiave }
}

/// La scheda prima/dopo di uno scenario «E se…?»: le cifre le calcola Prisma con le ipotesi del cliente,
/// Ruby le racconta. Resta nella risposta di Ruby (nel dossier, con la conversazione) e si salva tra gli scenari.
struct SchedaScenarioRuby: Codable, Equatable {
    /// La conversazione in cui è nata (il cliente o il portafoglio).
    var chiave: String
    var clienteId: String
    var nomeCliente: String
    var area: AreaScenarioRuby
    /// «E se… pensione a 63 anni, senza versamenti».
    var titolo: String
    var colonnaOggi: String
    var colonnaScenario: String
    var righe: [RigaScenarioRuby]
    /// Cosa cambia, a parole e con le cifre («pensione a 63 anni invece che a 67»).
    var ipotesi: [String]
    /// Altre cifre che contano, fuori dalla tabella («per coprire il divario servirebbero…»).
    var altre: [String]
    var note: [String]
    /// Il racconto di Prisma: il testo della risposta senza Qwen (o se Qwen cambia una cifra).
    var racconto: String
    /// L'ipotesi per il simulatore di Analisi 360 (nil in protezione: lì si apre l'area).
    var simulazione: Simulazione?
    var parametri: ParametriScenarioRuby
    /// Dopo «Salva nel dossier»: lo scenario salvato o la nota del taccuino.
    var salvataId: String?
    var notaId: String?

    var salvata: Bool { salvataId != nil || notaId != nil }

    func riga(_ chiave: String) -> RigaScenarioRuby? { righe.first { $0.chiave == chiave } }

    /// Le cifre esatte per Qwen: ipotesi, righe con la differenza, altre cifre e note.
    var bozza: String {
        var parti = ["\(titolo) · \(nomeCliente) · area \(area.nome.lowercased())"]
        parti.append("Ipotesi: " + ipotesi.joined(separator: "; ") + ".")
        parti.append("Prima e dopo (\(colonnaOggi) → \(colonnaScenario)):\n" + righe.map { r in
            "• \(r.voce): \(r.oggi) → \(r.scenario)" + (r.differenza.map { " (\($0))" } ?? "")
        }.joined(separator: "\n"))
        if !altre.isEmpty { parti.append(altre.joined(separator: "\n")) }
        if !note.isEmpty { parti.append("Da sapere: " + note.joined(separator: " ")) }
        parti.append("Racconto di Prisma: " + racconto)
        return parti.joined(separator: "\n")
    }

    /// Il testo che va nel taccuino del cliente (protezione, o scenari senza simulatore).
    var testoNota: String {
        let testoIpotesi = InterpreteComandi.maiuscola(ipotesi.joined(separator: "; "))
        var r: [String] = [testoIpotesi + "."]
        r.append(righe.map { "\($0.voce): \($0.oggi) oggi, \($0.scenario) con lo scenario" }.joined(separator: "\n"))
        r += altre
        r += note
        r.append("Calcolato da Prisma con le ipotesi del cliente.")
        return r.joined(separator: "\n\n")
    }
}

/// Il motore degli scenari «E se…?». Prende i parametri (MotoreScenari non sa da dove vengono: da Qwen o dalle
/// regole) e restituisce il prima/dopo con gli stessi motori dei prospetti e delle aree di Analisi 360:
/// previdenza (MotorePrevidenza, MotorePensionePubblica, RegoleFiscali per il risparmio IRPEF), investimenti e
/// risparmio (MotoreAnalisi, cioè MotoreProiezione), protezione (MotoreProtezioneFamiglia). Le ipotesi sono quelle
/// del cliente (Analisi 360 e posizioni); cambia solo quello che dice lo scenario.
enum MotoreScenari {
    /// La scheda dello scenario; nil se manca l'area (prima va chiesta: `ScenariRuby.domandaMancante`).
    static func calcola(_ p: ParametriScenarioRuby, fonte f: FonteRuby, chiave: String) -> SchedaScenarioRuby? {
        guard let area = p.area else { return nil }
        let nome = f.cliente.nome.split(separator: " ").first.map(String.init) ?? f.cliente.nome
        var s: SchedaScenarioRuby
        switch area {
        case .previdenza: s = previdenza(p, f, nome: nome)
        case .investimenti: s = investimenti(p, f, nome: nome)
        case .risparmio: s = risparmio(p, f, nome: nome)
        case .protezione: s = protezione(p, f, nome: nome)
        }
        s.chiave = chiave
        s.parametri = p
        if var sim = s.simulazione {
            sim.titolo = String(s.titolo.prefix(titoloMassimo))
            s.simulazione = sim
        }
        return s
    }

    static let titoloMassimo = 80

    // MARK: - Previdenza

    private static func previdenza(_ p: ParametriScenarioRuby, _ f: FonteRuby, nome: String) -> SchedaScenarioRuby {
        let c = f.cliente
        let base = f.analisi.previdenza
        // Le proposte restano fuori: lo scenario parla di quello che c'è oggi e di cosa cambia
        let inEssere = f.posizioni.filter { $0.stato != .proposta }
        let oggi = MotorePrevidenza.calcola(inEssere, cliente: c, analisi: base, data: f.oggi)
        var ip = base
        if let e = p.etaPensione { ip.etaPensione = e }
        var ipotesi: [String] = []
        var brevi: [String] = []
        var note: [String] = []
        let etaOggi = oggi.etaPensione

        // La pensione pubblica all'età nuova: quella dell'Analisi 360, cambiata come cambia la stima contributiva
        if let e = p.etaPensione, e != etaOggi {
            let anni = abs(etaOggi - e)
            ipotesi.append("pensione a \(e) anni invece che a \(etaOggi) (\(anni) \(anni == 1 ? "anno" : "anni") \(e < etaOggi ? "prima" : "dopo"))")
            brevi.append("pensione a \(e) anni")
            let eta = MotorePensionePubblica.etaAl(c.dataNascita, f.oggi) ?? base.eta
            if let lavoro = c.profilo.lavoro,
               let a = MotorePensionePubblica.stima(lavoro: lavoro, eta: eta, etaPensione: etaOggi, reddito: c.profilo.redditoLordoAnnuo),
               let b = MotorePensionePubblica.stima(lavoro: lavoro, eta: eta, etaPensione: e, reddito: c.profilo.redditoLordoAnnuo),
               a.nettaMensile > 0 {
                ip.pensionePubblica = MotoreFiscale.centesimi(base.pensionePubblica * b.nettaMensile / a.nettaMensile)
                // In percentuale: le cifre assolute della stima contributiva sembrerebbero un'altra pensione accanto a quella in tabella
                let delta = b.nettaMensile / a.nettaMensile - 1
                note.append("Pensione pubblica a \(e) anni: quella dell'Analisi 360 \(delta < 0 ? "ridotta" : "aumentata") del \(CifreDoc.percento(abs(delta) * 100, decimali: 1)), come cambia la stima contributiva di Prisma tra \(etaOggi) e \(e) anni.")
                if let avviso = b.avvisi.first(where: { $0.contains("requisiti") || $0.contains("anticipata") }) { note.append(avviso) }
            } else {
                note.append("Senza i dati del lavoro e dei contributi la pensione pubblica resta quella dell'Analisi 360: per l'uscita a \(e) anni va verificata sull'estratto conto INPS.")
            }
        }

        // I piani previdenziali in essere, con i versamenti, il capitale e il rendimento dello scenario
        var elenco = inEssere
        var indici = elenco.indices.filter { elenco[$0].regime == .previdenza && elenco[$0].stato == .inEssere }
        let mensileOggi = indici.reduce(0.0) { $0 + elenco[$1].premioAnnuo } / 12
        var nuovoMensile: Double?
        if p.smetteDiVersare {
            nuovoMensile = 0
            ipotesi.append("versamenti ai piani fermi da oggi (oggi \(mese(mensileOggi)))")
            brevi.append("senza versamenti")
            if indici.contains(where: { (elenco[$0].contributoDatore ?? 0) > 0 || (elenco[$0].tfrConferito ?? 0) > 0 }) {
                note.append("Il contributo del datore di lavoro e il TFR conferito restano come oggi.")
            }
        } else if let v = p.versamentoMensile {
            nuovoMensile = max(0, v)
            ipotesi.append("versamento ai piani di \(mese(max(0, v))) (oggi \(mese(mensileOggi)))")
            brevi.append("\(CifreDoc.euro(max(0, v))) al mese")
        } else if let d = p.variazioneVersamento {
            nuovoMensile = max(0, mensileOggi + d)
            ipotesi.append("versamento ai piani di \(mese(max(0, mensileOggi + d))) (\(CifreDoc.euroSegno(d)) al mese rispetto a oggi)")
            brevi.append("\(CifreDoc.euroSegno(d)) al mese")
        }
        if indici.isEmpty && ((nuovoMensile ?? 0) > 0 || (p.capitale ?? 0) > 0) {
            var nuovo = Posizione(clienteId: c.id, canale: c.canali.first ?? .indipendente, stato: .inEssere, area: .previdenza, nome: "Piano dello scenario")
            nuovo.decorrenza = f.oggi
            nuovo.controvalore = 0
            nuovo.totaleVersato = 0
            nuovo.rendimentoAtteso = p.rendimento ?? IpotesiCalcolo.rendimentoPredefinito
            elenco.append(nuovo)
            indici = [elenco.count - 1]
            note.append("\(nome) non ha piani previdenziali in essere: lo scenario ne ipotizza uno nuovo, senza costi, con il rendimento \(p.rendimento == nil ? "predefinito di Prisma" : "indicato").")
        }
        if let v = nuovoMensile {
            if mensileOggi > 0 {
                let k = v / mensileOggi
                for i in indici { elenco[i].premio *= k }
            } else if let i = indici.first {
                elenco[i].premio = v
                elenco[i].frequenza = .mensile
            }
        }
        if let k = p.capitale, k != 0, !indici.isEmpty {
            if k > 0 {
                let i = indici.max { elenco[$0].valore < elenco[$1].valore } ?? indici[0]
                let valore = elenco[i].valore
                elenco[i].controvalore = valore + k
                elenco[i].totaleVersato = (elenco[i].totaleVersato ?? elenco[i].versamentoIniziale) + k
                // Un versamento straordinario oltre il limite: non dedotto, non si tassa alla prestazione
                elenco[i].contributiNonDedotti = (elenco[i].contributiNonDedotti ?? 0) + k
                ipotesi.append("\(CifreDoc.euro(k)) in più nei piani")
                brevi.append("\(CifreDoc.euro(k)) in più")
            } else {
                let totale = indici.reduce(0.0) { $0 + elenco[$1].valore }
                if totale > 0 {
                    let quota = max(0, (totale + k) / totale)
                    for i in indici {
                        let valore = elenco[i].valore
                        elenco[i].controvalore = valore * quota
                        if let v = elenco[i].totaleVersato { elenco[i].totaleVersato = v * quota }
                    }
                }
                ipotesi.append("\(CifreDoc.euro(min(-k, totale))) ritirati dai piani")
                brevi.append("\(CifreDoc.euro(-k)) in meno")
            }
        }
        if let r = p.rendimento {
            for i in indici { elenco[i].rendimentoAtteso = r }
            ipotesi.append("piani al \(CifreDoc.condizione(r)) lordo l'anno")
            brevi.append("rendimento \(CifreDoc.condizione(r))")
        }
        if p.durata != nil {
            note.append("In previdenza conta l'età di pensione: la durata dello scenario non cambia i conti.")
        }
        if ipotesi.isEmpty { ipotesi.append("le ipotesi di oggi") }

        let dopo = MotorePrevidenza.calcola(elenco, cliente: c, analisi: ip, data: f.oggi)
        func capitale(_ e: EsitoPianoPrevidenziale) -> Double { e.inEssere.reduce(0) { $0 + $1.nettoReale } }
        func coperto(_ e: EsitoPianoPrevidenziale) -> Double { e.divario > 0 ? min(100, e.renditaInEssere / e.divario * 100) : 100 }

        var righe = [
            rigaEuro("capitale", "Capitale nei piani", capitale(oggi), capitale(dopo)),
            rigaMese("pensionePubblica", "Pensione pubblica", oggi.pensionePubblica, dopo.pensionePubblica),
            rigaMese("rendita", "Rendita dei piani", oggi.renditaInEssere, dopo.renditaInEssere),
            rigaPercento("copertura", "Divario coperto", coperto(oggi), coperto(dopo)),
            rigaMese("divario", "Divario da coprire", oggi.divarioResiduo, dopo.divarioResiduo),
        ]
        if oggi.reddito != nil {
            righe.append(rigaEuro("risparmioFiscale", "Risparmio IRPEF l'anno", oggi.risparmioOggi, dopo.risparmioOggi))
        }
        var altre: [String] = []
        if let v = dopo.versamentoMancante, dopo.divarioResiduo >= 1 {
            altre.append("Per coprire il divario dello scenario servirebbero circa \(mese(v)) in più fino alla pensione (oggi \(oggi.versamentoMancante.map { mese($0) } ?? "nessuno")).")
        }
        note.append("Importi in euro di oggi; capitale e rendita dei piani al netto dell'imposta sulla prestazione, rendita su \(base.anniIntegrazione) anni di integrazione.")

        let colonne = p.etaPensione.map { e -> (String, String) in
            e != etaOggi ? ("Oggi (\(etaOggi) anni)", "Scenario (\(e) anni)") : ("Oggi", "Con lo scenario")
        } ?? ("Oggi", "Con lo scenario")

        // Il racconto di Prisma
        var frase = "Se \(nome) " + raccontoIpotesi(p, etaOggi: etaOggi, mensileOggi: mensileOggi) + ", "
        var cifre: [String] = []
        if abs(dopo.pensionePubblica - oggi.pensionePubblica) >= 1 {
            cifre.append("la pensione pubblica \(verbo(oggi.pensionePubblica, dopo.pensionePubblica)) da \(CifreDoc.euro(oggi.pensionePubblica)) a \(mese(dopo.pensionePubblica))")
        }
        cifre.append("la rendita dei piani \(verbo(oggi.renditaInEssere, dopo.renditaInEssere)) da \(CifreDoc.euro(oggi.renditaInEssere)) a \(mese(dopo.renditaInEssere))")
        frase += cifre.joined(separator: " e ") + ": "
        frase += "il divario da coprire \(verbo(oggi.divarioResiduo, dopo.divarioResiduo)) da \(CifreDoc.euro(oggi.divarioResiduo)) a \(mese(dopo.divarioResiduo))"
        frase += " (coperto al \(CifreDoc.percento(coperto(dopo), decimali: 0)) invece che al \(CifreDoc.percento(coperto(oggi), decimali: 0)))."
        var racconto = [frase]
        racconto += altre
        // L'avviso passa nel racconto e lascia le note: compare una volta sola
        if let i = note.firstIndex(where: { $0.contains("requisiti") || $0.contains("anticipata") }) { racconto.append(note.remove(at: i)) }

        return SchedaScenarioRuby(
            chiave: "", clienteId: c.id, nomeCliente: c.nome, area: .previdenza,
            titolo: "E se… " + (brevi.isEmpty ? "previdenza" : brevi.joined(separator: ", ")),
            colonnaOggi: colonne.0, colonnaScenario: colonne.1, righe: righe, ipotesi: ipotesi, altre: altre, note: note,
            racconto: racconto.joined(separator: " "),
            simulazione: simulazionePrevidenza(elenco, indici: indici, etaPensione: dopo.etaPensione, eta: dopo.eta, p: p),
            parametri: p)
    }

    /// Il simulatore di Analisi 360 parte dal piano principale dello scenario: capitale e versamenti di tutti i piani,
    /// gli anni fino alla pensione dello scenario.
    private static func simulazionePrevidenza(_ elenco: [Posizione], indici: [Int], etaPensione: Int, eta: Int,
                                              p: ParametriScenarioRuby) -> Simulazione? {
        guard let principale = indici.max(by: { elenco[$0].valore < elenco[$1].valore }) else { return nil }
        var s = Simulazione(posizione: elenco[principale], orizzonteCliente: nil)
        s.capitale = indici.reduce(0.0) { $0 + elenco[$1].valore }.rounded()
        s.versamentoMensile = (indici.reduce(0.0) { $0 + elenco[$1].premioAnnuo } / 12).rounded()
        s.anni = max(1, etaPensione - eta)
        if let r = p.rendimento { s.rendimento = r }
        s.creataIl = Date()
        return s
    }

    /// «va in pensione a 63 anni invece che a 67 e smette di versare nei piani».
    private static func raccontoIpotesi(_ p: ParametriScenarioRuby, etaOggi: Int, mensileOggi: Double) -> String {
        var parti: [String] = []
        if let e = p.etaPensione, e != etaOggi { parti.append("va in pensione a \(e) anni invece che a \(etaOggi)") }
        if p.smetteDiVersare {
            parti.append(mensileOggi > 0 ? "smette di versare i \(mese(mensileOggi)) nei piani" : "non versa nei piani")
        } else if let v = p.versamentoMensile {
            parti.append("versa \(mese(max(0, v))) nei piani")
        } else if let d = p.variazioneVersamento {
            parti.append("versa \(CifreDoc.euro(abs(d))) al mese \(d >= 0 ? "in più" : "in meno") nei piani")
        }
        if let k = p.capitale, k != 0 { parti.append(k > 0 ? "aggiunge \(CifreDoc.euro(k)) ai piani" : "ritira \(CifreDoc.euro(-k)) dai piani") }
        if let r = p.rendimento { parti.append("i piani rendono il \(CifreDoc.condizione(r)) lordo l'anno") }
        return parti.isEmpty ? "resta con le ipotesi di oggi" : elenca(parti)
    }

    // MARK: - Investimenti

    private static func investimenti(_ p: ParametriScenarioRuby, _ f: FonteRuby, nome: String) -> SchedaScenarioRuby {
        let base = f.analisi.investimenti
        var s = base
        var ipotesi: [String] = [], brevi: [String] = [], note: [String] = []
        if let k = p.capitale, k != 0 {
            s.capitale = max(0, base.capitale + k)
            ipotesi.append(k > 0 ? "\(CifreDoc.euro(k)) in più da investire" : "\(CifreDoc.euro(min(-k, base.capitale))) ritirati")
            brevi.append(k > 0 ? "\(CifreDoc.euro(k)) in più" : "\(CifreDoc.euro(-k)) in meno")
        }
        applicaVersamento(p, attuale: base.versamentoMensile, a: &s.versamentoMensile, ipotesi: &ipotesi, brevi: &brevi)
        if let r = p.rendimento {
            s.rendimento = r
            ipotesi.append("rendimento del \(CifreDoc.condizione(r)) lordo l'anno (oggi \(CifreDoc.condizione(base.rendimento)))")
            brevi.append("rendimento \(CifreDoc.condizione(r))")
        }
        if let d = p.durata {
            s.anni = d
            ipotesi.append("orizzonte di \(anni(d)) (oggi \(anni(base.anni)))")
            brevi.append(anni(d))
        }
        if p.etaPensione != nil { note.append("L'età di pensione conta in previdenza: qui non cambia i conti.") }
        if ipotesi.isEmpty { ipotesi.append("le ipotesi di oggi") }
        let a = MotoreAnalisi.investimenti(base).esito
        let b = MotoreAnalisi.investimenti(s).esito
        let righe = [
            rigaEuro("capitaleIniziale", "Capitale investito", base.capitale, s.capitale),
            rigaMese("versamento", "Versamento", base.versamentoMensile, s.versamentoMensile),
            rigaEuro("capitaleScadenza", "Capitale a scadenza", a.netto, b.netto),
            rigaEuro("reale", "In euro di oggi", a.reale, b.reale),
            rigaEuro("guadagno", "Guadagno netto", a.guadagnoNetto, b.guadagnoNetto),
        ]
        note.append("Stesso modello delle posizioni: costi annui del \(CifreDoc.condizione(s.costoAnnuo)), imposta del \(CifreDoc.condizione(s.aliquota)) sulla plusvalenza, inflazione del \(CifreDoc.condizione(s.inflazione)). È una stima, non una previsione.")
        let colonne = p.durata.map { ("Oggi (\(anni(base.anni)))", "Scenario (\(anni($0)))") } ?? ("Oggi", "Con lo scenario")
        let racconto = "Con \(elenca(ipotesi)), il capitale di \(nome) a scadenza \(verbo(a.netto, b.netto)) da \(CifreDoc.euro(a.netto)) a \(CifreDoc.euro(b.netto)) netti (\(CifreDoc.euro(b.reale)) in euro di oggi): il guadagno netto passa da \(CifreDoc.euro(a.guadagnoNetto)) a \(CifreDoc.euro(b.guadagnoNetto))."
        var sim = Simulazione(clienteId: f.cliente.id, titolo: "")
        sim.capitale = s.capitale.rounded()
        sim.versamentoMensile = s.versamentoMensile.rounded()
        sim.anni = max(1, s.anni)
        sim.rendimento = s.rendimento
        sim.costoIngresso = s.costoIngresso
        sim.costoAnnuo = s.costoAnnuo
        sim.aliquota = s.aliquota
        sim.inflazione = s.inflazione
        return SchedaScenarioRuby(chiave: "", clienteId: f.cliente.id, nomeCliente: f.cliente.nome, area: .investimenti,
                                 titolo: "E se… " + (brevi.isEmpty ? "investimenti" : brevi.joined(separator: ", ")),
                                 colonnaOggi: colonne.0, colonnaScenario: colonne.1, righe: righe, ipotesi: ipotesi, altre: [],
                                 note: note, racconto: racconto, simulazione: sim, parametri: p)
    }

    // MARK: - Risparmio

    private static func risparmio(_ p: ParametriScenarioRuby, _ f: FonteRuby, nome: String) -> SchedaScenarioRuby {
        let base = f.analisi.risparmio
        var s = base
        var ipotesi: [String] = [], brevi: [String] = [], note: [String] = []
        if let k = p.capitale, k != 0 {
            s.capitale = max(0, base.capitale + k)
            ipotesi.append(k > 0 ? "\(CifreDoc.euro(k)) in più già da parte" : "\(CifreDoc.euro(min(-k, base.capitale))) spesi")
            brevi.append(k > 0 ? "\(CifreDoc.euro(k)) in più" : "\(CifreDoc.euro(-k)) in meno")
        }
        applicaVersamento(p, attuale: base.versamentoMensile, a: &s.versamentoMensile, ipotesi: &ipotesi, brevi: &brevi)
        if let r = p.rendimento {
            s.rendimento = r
            ipotesi.append("rendimento del \(CifreDoc.condizione(r)) lordo l'anno (oggi \(CifreDoc.condizione(base.rendimento)))")
            brevi.append("rendimento \(CifreDoc.condizione(r))")
        }
        if let d = p.durata {
            s.anni = d
            ipotesi.append("\(anni(d)) per arrivare all'obiettivo (oggi \(anni(base.anni)))")
            brevi.append(anni(d))
        }
        if p.etaPensione != nil { note.append("L'età di pensione conta in previdenza: qui non cambia i conti.") }
        if ipotesi.isEmpty { ipotesi.append("le ipotesi di oggi") }
        let a = MotoreAnalisi.risparmio(base)
        let b = MotoreAnalisi.risparmio(s)
        let righe = [
            rigaEuro("capitaleIniziale", "Già da parte", base.capitale, s.capitale),
            rigaMese("versamento", "Versamento", base.versamentoMensile, s.versamentoMensile),
            rigaEuro("capitaleScadenza", "Capitale a scadenza", a.esito.netto, b.esito.netto),
            rigaPercento("copertura", "Obiettivo raggiunto", a.copertura, b.copertura),
            rigaEuro("mancante", "Mancano", a.mancante, b.mancante),
        ]
        var altre: [String] = []
        if let v = b.versamentoTeorico, b.mancante >= 1 {
            altre.append("Per arrivare all'obiettivo con lo scenario servirebbero circa \(mese(v)).")
        }
        note.append("Obiettivo di \(CifreDoc.euro(base.obiettivo)) in euro di oggi (Analisi 360), rivalutato all'inflazione del \(CifreDoc.condizione(s.inflazione)); stesso modello delle posizioni, senza garanzia di risultato.")
        let colonne = p.durata.map { ("Oggi (\(anni(base.anni)))", "Scenario (\(anni($0)))") } ?? ("Oggi", "Con lo scenario")
        var racconto = "Con \(elenca(ipotesi)), \(nome) arriverebbe a \(CifreDoc.euro(b.esito.netto)) netti invece di \(CifreDoc.euro(a.esito.netto)): "
        racconto += "l'obiettivo è raggiunto al \(CifreDoc.percento(b.copertura, decimali: 0)) invece che al \(CifreDoc.percento(a.copertura, decimali: 0))"
        racconto += b.mancante >= 1 ? " e mancano \(CifreDoc.euro(b.mancante))." : "."
        if let x = altre.first { racconto += " " + x }
        var sim = Simulazione(clienteId: f.cliente.id, titolo: "")
        sim.capitale = s.capitale.rounded()
        sim.versamentoMensile = s.versamentoMensile.rounded()
        sim.anni = max(1, s.anni)
        sim.rendimento = s.rendimento
        sim.costoIngresso = s.costoIngresso
        sim.costoAnnuo = s.costoAnnuo
        sim.aliquota = s.aliquota
        sim.inflazione = s.inflazione
        return SchedaScenarioRuby(chiave: "", clienteId: f.cliente.id, nomeCliente: f.cliente.nome, area: .risparmio,
                                 titolo: "E se… " + (brevi.isEmpty ? "risparmio" : brevi.joined(separator: ", ")),
                                 colonnaOggi: colonne.0, colonnaScenario: colonne.1, righe: righe, ipotesi: ipotesi, altre: altre,
                                 note: note, racconto: racconto, simulazione: sim, parametri: p)
    }

    // MARK: - Protezione

    private static func protezione(_ p: ParametriScenarioRuby, _ f: FonteRuby, nome: String) -> SchedaScenarioRuby {
        let c = f.cliente
        let base = f.analisi.protezione
        var ip = base
        var posizioni = f.posizioni
        var ipotesi: [String] = [], brevi: [String] = [], note: [String] = []
        if let k = p.capitale, k != 0 {
            if k > 0 {
                var nuova = Posizione(clienteId: c.id, canale: c.canali.first ?? .indipendente, stato: .inEssere, area: .protezione, nome: "Copertura dello scenario")
                nuova.rischio = .vita
                nuova.capitaleAssicurato = k
                nuova.controvalore = 0
                posizioni.append(nuova)
                ipotesi.append("\(CifreDoc.euro(k)) di capitale caso morte in più")
                brevi.append("\(CifreDoc.euro(k)) di copertura in più")
                note.append("Il premio della copertura in più dipende dal prodotto scelto: lo scenario non lo stima.")
            } else {
                let vita = MotoreAnalisi.capitaleVita(posizioni)
                let quota = vita > 0 ? max(0, (vita + k) / vita) : 1
                for i in posizioni.indices where posizioni[i].area == .protezione && posizioni[i].stato == .inEssere && posizioni[i].rischio == .vita {
                    if let v = posizioni[i].capitaleAssicurato { posizioni[i].capitaleAssicurato = v * quota }
                }
                ipotesi.append("\(CifreDoc.euro(min(-k, vita))) di capitale caso morte in meno")
                brevi.append("\(CifreDoc.euro(-k)) di copertura in meno")
            }
        }
        if let d = p.durata {
            ip.anniSostegno = d
            ipotesi.append("\(anni(d)) di sostegno alla famiglia (oggi \(anni(base.anniSostegno)))")
            brevi.append("\(anni(d)) di sostegno")
        }
        if p.etaPensione != nil || p.smetteDiVersare || p.versamentoMensile != nil || p.variazioneVersamento != nil || p.rendimento != nil {
            note.append("In protezione contano il capitale caso morte e gli anni di sostegno: età di pensione, versamenti e rendimento non cambiano questi conti.")
        }
        if ipotesi.isEmpty { ipotesi.append("le ipotesi di oggi") }
        let a = MotoreProtezioneFamiglia.calcola(f.posizioni, cliente: c, analisi: base, data: f.oggi)
        let b = MotoreProtezioneFamiglia.calcola(posizioni, cliente: c, analisi: ip, data: f.oggi)
        func copertura(_ e: EsitoProtezioneFamiglia) -> Double { e.fabbisogno > 0 ? min(100, e.capitaleVita / e.fabbisogno * 100) : 100 }
        let righe = [
            rigaEuro("fabbisogno", "Fabbisogno caso morte", a.fabbisogno, b.fabbisogno),
            rigaEuro("capitaleVita", "Capitale caso morte", a.capitaleVita, b.capitaleVita),
            rigaPercento("copertura", "Copertura", copertura(a), copertura(b)),
            rigaEuro("divario", "Divario", a.divario, b.divario),
            rigaAnni("anniCoperti", "Anni di sostegno coperti", a.anniCoperti, b.anniCoperti),
        ]
        note.append("Fabbisogno = debiti + spese immediate + sostegno mensile per gli anni scelti − capitale già disponibile (ipotesi dell'Analisi 360); coperture caso morte in essere nelle Posizioni.")
        let colonne = p.durata.map { ("Oggi (\(anni(base.anniSostegno)))", "Scenario (\(anni($0)))") } ?? ("Oggi", "Con lo scenario")
        let racconto = "Con \(elenca(ipotesi)), la famiglia di \(nome) sarebbe coperta al \(CifreDoc.percento(copertura(b), decimali: 0)) invece che al \(CifreDoc.percento(copertura(a), decimali: 0)): il divario \(verbo(a.divario, b.divario)) da \(CifreDoc.euro(a.divario)) a \(CifreDoc.euro(b.divario))."
        return SchedaScenarioRuby(chiave: "", clienteId: c.id, nomeCliente: c.nome, area: .protezione,
                                 titolo: "E se… " + (brevi.isEmpty ? "protezione" : brevi.joined(separator: ", ")),
                                 colonnaOggi: colonne.0, colonnaScenario: colonne.1, righe: righe, ipotesi: ipotesi, altre: [],
                                 note: note, racconto: racconto, simulazione: nil, parametri: p)
    }

    // MARK: - Aiuti

    /// Il versamento al mese dello scenario (investimenti e risparmio).
    private static func applicaVersamento(_ p: ParametriScenarioRuby, attuale: Double, a valore: inout Double,
                                          ipotesi: inout [String], brevi: inout [String]) {
        if p.smetteDiVersare {
            valore = 0
            ipotesi.append("versamenti fermi da oggi (oggi \(mese(attuale)))")
            brevi.append("senza versamenti")
        } else if let v = p.versamentoMensile {
            valore = max(0, v)
            ipotesi.append("versamento di \(mese(max(0, v))) (oggi \(mese(attuale)))")
            brevi.append("\(CifreDoc.euro(max(0, v))) al mese")
        } else if let d = p.variazioneVersamento {
            valore = max(0, attuale + d)
            ipotesi.append("versamento di \(mese(max(0, attuale + d))) (\(CifreDoc.euroSegno(d)) al mese rispetto a oggi)")
            brevi.append("\(CifreDoc.euroSegno(d)) al mese")
        }
    }

    static func mese(_ v: Double) -> String { "\(CifreDoc.euro(v)) al mese" }

    static func anni(_ n: Int) -> String { n == 1 ? "1 anno" : "\(n) anni" }

    /// «sale», «scende» o «resta» secondo il verso del cambiamento (sotto l'euro resta).
    static func verbo(_ prima: Double, _ dopo: Double) -> String {
        if abs(dopo - prima) < 0.5 { return "resta" }
        return dopo > prima ? "sale" : "scende"
    }

    /// «a, b e c».
    static func elenca(_ parti: [String]) -> String {
        guard parti.count > 1 else { return parti.first ?? "" }
        return parti.dropLast().joined(separator: ", ") + " e " + parti[parti.count - 1]
    }

    private static func rigaEuro(_ chiave: String, _ voce: String, _ a: Double, _ b: Double) -> RigaScenarioRuby {
        RigaScenarioRuby(chiave: chiave, voce: voce, oggi: CifreDoc.euro(a), scenario: CifreDoc.euro(b), valoreOggi: a, valoreScenario: b,
                        differenza: abs(b - a) >= 0.5 ? CifreDoc.euroSegno(b - a) : nil)
    }

    private static func rigaMese(_ chiave: String, _ voce: String, _ a: Double, _ b: Double) -> RigaScenarioRuby {
        RigaScenarioRuby(chiave: chiave, voce: voce, oggi: mese(a), scenario: mese(b), valoreOggi: a, valoreScenario: b,
                        differenza: abs(b - a) >= 0.5 ? CifreDoc.euroSegno(b - a) + " al mese" : nil)
    }

    private static func rigaPercento(_ chiave: String, _ voce: String, _ a: Double, _ b: Double) -> RigaScenarioRuby {
        let punti = (b - a).rounded()
        return RigaScenarioRuby(chiave: chiave, voce: voce, oggi: CifreDoc.percento(a, decimali: 0), scenario: CifreDoc.percento(b, decimali: 0),
                               valoreOggi: a, valoreScenario: b,
                               differenza: punti != 0 ? (punti > 0 ? "+" : CifreDoc.meno) + "\(Int(abs(punti))) punti" : nil)
    }

    private static func rigaAnni(_ chiave: String, _ voce: String, _ a: Double, _ b: Double) -> RigaScenarioRuby {
        func testo(_ v: Double) -> String {
            let n = CifreDoc.percento(v, decimali: 1).replacingOccurrences(of: "%", with: "")
            return n == "1,0" ? "1 anno" : "\(n) anni"
        }
        return RigaScenarioRuby(chiave: chiave, voce: voce, oggi: testo(a), scenario: testo(b), valoreOggi: a, valoreScenario: b, differenza: nil)
    }
}
