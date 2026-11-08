import Foundation

// Quanto vale avermi accanto (Design/template-luce-specifica.md §4.4, «Luce» giro 8): il lavoro fatto con il cliente,
// in cifre, dai motori di Prisma. Il template moltiplica tre cifre fisse per il patrimonio: qui nessuna cifra di ripiego.
// Regole (decisioni 58 e 85):
// - contano SOLO le posizioni nate da raccomandazioni accettate dopo l'inizio del rapporto (`Cliente.clienteDal`; senza,
//   la prima raccomandazione accettata; in ultimo la data della scheda, segnata «dalla scheda»). Ciò che il cliente
//   aveva già, o che ha fatto da solo, non è «valore» del consulente;
// - tasse risparmiate: anno per anno, i contributi deducibili versati nei fondi pensione nati dal consiglio
//   (`RegoleFiscali.risparmioDeduzione`, al massimo `limiteDeducibilita` l'anno) e la detrazione del 19% dei premi delle
//   coperture (`RegoleFiscali.detraibili`), con il reddito lordo di oggi: è una STIMA, e lo si dice. I limiti sono per
//   contribuente: i contributi e i premi che il cliente versa già in posizioni sue (non nate dal consiglio) li consumano
//   per primi, e al consiglio va solo il beneficio in più (marginale);
// - costi tagliati: per ogni sostituzione (`AlternativaRaccomandazione.posizioneSostituitaId` o la scheda di
//   adeguatezza) (costo % della sostituita − costo % della nuova) × valore di oggi della nuova × anni dall'accettazione;
//   senza il costo di una delle due la voce non si conta e lo si dice;
// - rispetto all'alternativa: lo scarto del track record (`MotoreTrackRecord`) delle sole raccomandazioni del cliente;
// - «E in più, protetto»: solo il capitale caso morte delle coperture nate dal consiglio (non entra nel totale);
// - il compenso, diviso per canale: parcelle pagate (indipendente) e provvigioni stimate con le aliquote di
//   Impostazioni › Studio (Alleanza; senza aliquote «non stimate»). Per i clienti solo Alleanza «Valore e costi». Il
//   rapporto valore/compenso confronta grandezze dello stesso perimetro: con le provvigioni non stimate è solo il valore
//   del canale indipendente per euro di parcella (`rapportoSoloParcelle`), mai tutto il valore diviso le sole parcelle;
// - meno di 12 mesi, o nessuna raccomandazione accettata: «presto per misurare», senza totale;
// - il periodo (proposta di §4.4.4): «Dall'inizio» del rapporto o «Ultimi 12 mesi». Negli ultimi 12 mesi contano le
//   tasse degli ultimi 12 mesi di versamenti, i costi tagliati per i mesi del periodo, le parcelle e le provvigioni del
//   periodo; il track record misura solo dall'inizio, quindi «Rispetto all'alternativa» resta senza cifra e lo dice.
// Motore puro, senza SwiftUI. Nessuna richiesta di rete: i riferimenti sono quelli già in archivio.

/// Le tre voci che entrano nel totale.
enum TipoVoceValore: String, CaseIterable, Identifiable {
    case tasse, costi, alternativa

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .tasse: return "Tasse risparmiate"
        case .costi: return "Costi tagliati"
        case .alternativa: return "Rispetto all’alternativa"
        }
    }
}

/// Una riga del dettaglio di una voce (anno e posizione, sostituzione, raccomandazione misurata, copertura).
struct DettaglioValore: Identifiable, Equatable {
    let id: String
    let titolo: String
    let sottotitolo: String
    let cifra: Double
    let canale: Canale?
}

/// Una voce del valore: la cifra (nil = senza dati, con il motivo), le parti per canale e il dettaglio.
struct VoceValore: Equatable {
    let tipo: TipoVoceValore
    let totale: Double?
    let perCanale: [Canale: Double]
    let dettagli: [DettaglioValore]
    /// Sempre vera per tasse e alternativa: sono stime.
    let stima: Bool
    let motivoAssente: String?
}

/// Il periodo misurato (§4.4.4).
enum PeriodoValore: String, CaseIterable, Identifiable {
    case inizio, ultimi12

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .inizio: return "Dall’inizio"
        case .ultimi12: return "Ultimi 12 mesi"
        }
    }
}

/// Da dove viene la data d'inizio del rapporto.
enum InizioRapporto: Equatable {
    case clienteDal, primaRaccomandazione, scheda
}

/// Il valore del lavoro con un cliente.
struct ValoreConsulente: Equatable {
    let dal: Date
    let inizio: InizioRapporto
    let al: Date
    /// I mesi misurati (dall'inizio del rapporto, o 12 negli ultimi 12 mesi).
    let mesi: Int
    var periodo: PeriodoValore = .inizio
    /// Da quando si misura: `dal` o 12 mesi fa.
    var misuraDal: Date? = nil
    let voci: [VoceValore]
    /// Meno di 12 mesi o nessuna raccomandazione accettata: niente totale.
    let presto: Bool
    /// Il capitale caso morte delle coperture nate dal consiglio (nil se nessuna) e il suo dettaglio.
    let protetto: Double?
    let protettoDettagli: [DettaglioValore]
    let parcellePagate: Double
    /// Provvigioni stimate delle posizioni Alleanza nate dal consiglio; nil se mancano le aliquote (o nessuna posizione).
    let provvigioniStimate: Double?
    /// Ci sono posizioni Alleanza ma le aliquote non sono scritte.
    let provvigioniNonStimate: Bool
    /// Il cliente è seguito solo con Alleanza: «Valore e costi».
    let soloAlleanza: Bool

    func voce(_ t: TipoVoceValore) -> VoceValore? { voci.first { $0.tipo == t } }

    /// Somma delle voci con dati; nil se nessuna (o se è presto).
    var totale: Double? {
        guard !presto else { return nil }
        let conDati = voci.compactMap(\.totale)
        return conDati.isEmpty ? nil : conDati.reduce(0, +)
    }

    /// Qualche voce non ha dati: il titolo dice «almeno».
    var parziale: Bool { voci.contains { $0.totale == nil } }

    /// Le parti per canale del totale.
    var totalePerCanale: [Canale: Double] {
        var r: [Canale: Double] = [:]
        for v in voci where v.totale != nil {
            for (c, x) in v.perCanale { r[c, default: 0] += x }
        }
        return r
    }

    var compenso: Double { parcellePagate + (provvigioniStimate ?? 0) }

    /// Il rapporto è solo valore indipendente per euro di parcella: le provvigioni Alleanza non sono stimate.
    var rapportoSoloParcelle: Bool { provvigioniNonStimate }

    /// Euro di valore per euro di compenso; nil con compenso zero o senza totale. Con le provvigioni non stimate il
    /// compenso è incompleto: si confrontano solo il valore del canale indipendente e le parcelle.
    var rapporto: Double? {
        guard totale != nil else { return nil }
        if rapportoSoloParcelle {
            guard parcellePagate > 0 else { return nil }
            return (totalePerCanale[.indipendente] ?? 0) / parcellePagate
        }
        guard let t = totale, compenso > 0 else { return nil }
        return t / compenso
    }
}

enum MotoreValoreConsulente {
    /// Sotto questi mesi di rapporto è presto per misurare.
    static let mesiMinimi = 12

    /// La data d'inizio del rapporto e da dove viene.
    static func inizio(_ c: Cliente, raccomandazioni: [Raccomandazione]) -> (Date, InizioRapporto) {
        if let d = c.clienteDal { return (d, .clienteDal) }
        let prima = raccomandazioni.filter { $0.clienteId == c.id }.compactMap(\.accettataIl).min()
        if let prima { return (prima, .primaRaccomandazione) }
        return (c.creatoIl, .scheda)
    }

    /// Le raccomandazioni accettate dal cliente dopo l'inizio del rapporto, con la loro posizione.
    static func attribuite(_ c: Cliente, raccomandazioni: [Raccomandazione], dal: Date) -> [Raccomandazione] {
        raccomandazioni.filter { r in
            r.clienteId == c.id && r.scelta == .accettata && (r.accettataIl ?? r.data) >= dal && r.posizioneId != nil
        }
    }

    static func calcola(cliente c: Cliente, posizioni: [Posizione], raccomandazioni: [Raccomandazione],
                        schede: [SchedaAdeguatezza], parcelle: [Parcella], studio: ImpostazioniStudio,
                        tabella: TabellaRiferimenti, oggi: Date, periodo: PeriodoValore = .inizio,
                        cal: Calendar = .current) -> ValoreConsulente {
        let (dal, origine) = inizio(c, raccomandazioni: raccomandazioni)
        let mesiRapporto = max(0, cal.dateComponents([.month], from: dal, to: oggi).month ?? 0)
        let dodiciMesiFa = cal.date(byAdding: .month, value: -12, to: oggi) ?? oggi
        let misura = periodo == .ultimi12 ? max(dal, dodiciMesiFa) : dal
        let mesi = periodo == .ultimi12 ? min(12, mesiRapporto) : mesiRapporto
        let accettate = attribuite(c, raccomandazioni: raccomandazioni, dal: dal)
        let perId = Dictionary(posizioni.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let nate = accettate.compactMap { r in r.posizioneId.flatMap { perId[$0] } }.filter { $0.stato == .inEssere }
        let presto = mesiRapporto < mesiMinimi || accettate.isEmpty
        let nome = ModelliMessaggi.primoNome(c.nome)

        let idNate = Set(accettate.compactMap(\.posizioneId))
        let altre = posizioni.filter { $0.clienteId == c.id && $0.stato != .proposta && !idNate.contains($0.id) }
        let tasse = voceTasse(c, nate: nate, altre: altre, dal: misura, oggi: oggi, nome: nome, cal: cal)
        let costi = voceCosti(accettate, perId: perId, schede: schede, oggi: oggi, nome: nome, dal: misura, cal: cal)
        let alternativa = periodo == .ultimi12
            ? VoceValore(tipo: .alternativa, totale: nil, perCanale: [:], dettagli: [], stima: true,
                         motivoAssente: "Il track record misura dall’inizio: negli ultimi 12 mesi non si scompone")
            : voceAlternativa(accettate, posizioni: posizioni, tabella: tabella, oggi: oggi, nome: nome, cal: cal)

        // Protetto: il capitale caso morte delle coperture nate dal consiglio
        let vita = nate.filter { $0.area == .protezione && $0.rischio == .vita && ($0.capitaleAssicurato ?? 0) > 0 }
        let protetto = vita.reduce(0) { $0 + ($1.capitaleAssicurato ?? 0) }
        let dettagliProtetto = vita.map {
            DettaglioValore(id: $0.id, titolo: $0.nome, sottotitolo: "Capitale caso morte", cifra: $0.capitaleAssicurato ?? 0, canale: $0.canale)
        }

        // Il compenso: parcelle pagate dall'inizio del rapporto, provvigioni stimate delle posizioni Alleanza nate dal consiglio
        let pagate = parcelle.filter { $0.clienteId == c.id && $0.stato == .pagata && ($0.incassataIl ?? $0.data) >= misura }
            .reduce(0) { $0 + MotoreParcelle.importo($1) }
        let alleanza = nate.filter { $0.canale == .alleanza }
        let eventi = alleanza.flatMap { MotoreStudio.eventi($0, studio: studio, da: misura, a: oggi, cal: cal) }
        let nonStimate = eventi.contains { $0.importo == nil } || (!alleanza.isEmpty && eventi.isEmpty && studio.aliquoteInserite(per: alleanza[0].area) == nil)
        let provvigioni: Double? = nonStimate || eventi.isEmpty ? nil : eventi.compactMap(\.importo).reduce(0, +)

        var v = ValoreConsulente(dal: dal, inizio: origine, al: oggi, mesi: mesi, voci: [tasse, costi, alternativa], presto: presto,
                                 protetto: protetto > 0 ? protetto : nil, protettoDettagli: dettagliProtetto,
                                 parcellePagate: pagate, provvigioniStimate: provvigioni, provvigioniNonStimate: nonStimate,
                                 soloAlleanza: c.canali == [.alleanza])
        v.periodo = periodo
        v.misuraDal = misura
        return v
    }

    // MARK: - Le voci

    /// I versamenti di una posizione fra `da` e `a` (compresi): il versamento iniziale alla decorrenza e le rate.
    static func versamenti(_ p: Posizione, da: Date, a: Date, cal: Calendar = .current) -> [(Date, Double)] {
        guard let d = p.decorrenza, d <= a else { return [] }
        var r: [(Date, Double)] = []
        if p.versamentoIniziale > 0, d >= da { r.append((d, p.versamentoIniziale)) }
        let volte = p.frequenza.volteAllAnno
        guard volte > 0, p.premio > 0 else { return r }
        let passo = 12 / volte
        var k = 0
        while k < 1_200, let data = cal.date(byAdding: .month, value: k * passo, to: d), data <= a {
            if let fine = p.scadenza, data >= fine { break }
            if data >= da { r.append((data, p.premio)) }
            k += 1
        }
        return r
    }

    /// Le coperture con i premi detraibili.
    static func detraibile(_ p: Posizione) -> Bool {
        p.area == .protezione && [.vita, .invalidita, .infortuni, .ltc].contains(p.rischio ?? .altro)
    }

    /// `altre`: le posizioni del cliente non nate dal consiglio, che consumano per prime i limiti per contribuente.
    static func voceTasse(_ c: Cliente, nate: [Posizione], altre: [Posizione] = [], dal: Date, oggi: Date, nome: String,
                          cal: Calendar) -> VoceValore {
        let previdenza = nate.filter { $0.regime == .previdenza }
        let coperture = nate.filter(detraibile)
        let altraPrevidenza = altre.filter { $0.regime == .previdenza }
        let altreCoperture = altre.filter(detraibile)
        func versatoNellAnno(_ p: Posizione, _ anno: Int) -> Double {
            versamenti(p, da: .distantPast, a: oggi, cal: cal).filter { cal.component(.year, from: $0.0) == anno }.reduce(0) { $0 + $1.1 }
        }
        guard !previdenza.isEmpty || !coperture.isEmpty else {
            return VoceValore(tipo: .tasse, totale: nil, perCanale: [:], dettagli: [], stima: true,
                              motivoAssente: "Nessuna deduzione: \(nome) non ha versamenti deducibili nati dal consiglio")
        }
        guard let reddito = c.profilo.redditoLordoAnnuo, reddito > 0 else {
            return VoceValore(tipo: .tasse, totale: nil, perCanale: [:], dettagli: [], stima: true,
                              motivoAssente: "Serve il reddito lordo di \(nome) per stimare le deduzioni")
        }
        var dettagli: [DettaglioValore] = []
        var perCanale: [Canale: Double] = [:]
        let annoDa = cal.component(.year, from: dal)
        let annoA = cal.component(.year, from: oggi)
        for anno in annoDa...max(annoDa, annoA) {
            // Previdenza: i contributi dell'anno, al massimo il limite di deducibilità, ripartiti fra le posizioni
            var perPosizione: [(Posizione, Double)] = []
            for p in previdenza {
                let v = versamenti(p, da: dal, a: oggi, cal: cal).filter { cal.component(.year, from: $0.0) == anno }.reduce(0) { $0 + $1.1 }
                if v > 0 { perPosizione.append((p, v)) }
            }
            let versato = perPosizione.reduce(0) { $0 + $1.1 }
            if versato > 0 {
                // Il limite è per contribuente: i contributi che versa già altrove lo consumano per primi
                let gia = min(altraPrevidenza.reduce(0) { $0 + versatoNellAnno($1, anno) }, RegoleFiscali.limiteDeducibilita)
                let deduzione = min(versato, max(0, RegoleFiscali.limiteDeducibilita - gia))
                let risparmio = RegoleFiscali.risparmioDeduzione(reddito: reddito, deduzione: gia + deduzione)
                    - RegoleFiscali.risparmioDeduzione(reddito: reddito, deduzione: gia)
                for (p, v) in perPosizione {
                    let quota = risparmio * v / versato
                    perCanale[p.canale, default: 0] += quota
                    dettagli.append(DettaglioValore(id: "tasse-\(anno)-\(p.id)", titolo: "\(anno) · \(p.nome)",
                                                    sottotitolo: "Deduzione di \(Formati.euro(deduzione * v / versato))", cifra: quota,
                                                    canale: p.canale))
                }
            }
            // Coperture: la detrazione del 19% dei premi dell'anno
            var vita = 0.0, ltc = 0.0
            var premi: [(Posizione, Double)] = []
            for p in coperture {
                let v = versamenti(p, da: dal, a: oggi, cal: cal).filter { cal.component(.year, from: $0.0) == anno }.reduce(0) { $0 + $1.1 }
                guard v > 0 else { continue }
                if p.rischio == .ltc { ltc += v } else { vita += v }
                premi.append((p, v))
            }
            // Anche il tetto dei premi detraibili è per contribuente: i premi delle sue coperture lo consumano per primi
            var giaVita = 0.0, giaLtc = 0.0
            for p in altreCoperture {
                let v = versatoNellAnno(p, anno)
                if p.rischio == .ltc { giaLtc += v } else { giaVita += v }
            }
            let detraibili = RegoleFiscali.detraibili(vita: giaVita + vita, ltc: giaLtc + ltc)
                - RegoleFiscali.detraibili(vita: giaVita, ltc: giaLtc)
            if detraibili > 0 {
                let detrazione = detraibili * RegoleFiscali.detrazionePremi / 100 * RegoleFiscali.quotaDetrazione(reddito: reddito)
                let totalePremi = premi.reduce(0) { $0 + $1.1 }
                for (p, v) in premi {
                    let quota = detrazione * v / totalePremi
                    perCanale[p.canale, default: 0] += quota
                    dettagli.append(DettaglioValore(id: "detrazione-\(anno)-\(p.id)", titolo: "\(anno) · \(p.nome)",
                                                    sottotitolo: "Detrazione del 19% sui premi", cifra: quota, canale: p.canale))
                }
            }
        }
        let totale = perCanale.values.reduce(0, +)
        guard totale > 0 else {
            return VoceValore(tipo: .tasse, totale: nil, perCanale: [:], dettagli: [], stima: true,
                              motivoAssente: "Nessuna deduzione: nessun versamento deducibile registrato per \(nome)")
        }
        return VoceValore(tipo: .tasse, totale: totale, perCanale: perCanale, dettagli: dettagli, stima: true, motivoAssente: nil)
    }

    static func voceCosti(_ accettate: [Raccomandazione], perId: [String: Posizione], schede: [SchedaAdeguatezza], oggi: Date,
                          nome: String, dal: Date = .distantPast, cal: Calendar) -> VoceValore {
        var dettagli: [DettaglioValore] = []
        var perCanale: [Canale: Double] = [:]
        var senzaCosto = 0
        var sostituzioni = 0
        for r in accettate {
            guard let id = r.posizioneId, let nuova = perId[id] else { continue }
            let sostituitaId = r.alternativa.posizioneSostituitaId ?? schede.first { $0.posizioneId == id }?.posizioneSostituitaId
            guard let sid = sostituitaId, let vecchia = perId[sid] else { continue }
            sostituzioni += 1
            guard let prima = vecchia.costoComplessivo, let dopo = nuova.costoComplessivo else {
                senzaCosto += 1
                continue
            }
            let giorni = max(0, cal.dateComponents([.day], from: max(r.accettataIl ?? r.data, dal), to: oggi).day ?? 0)
            let anni = Double(giorni) / 365.25
            let risparmio = (prima - dopo) / 100 * nuova.valore * anni
            perCanale[nuova.canale, default: 0] += risparmio
            dettagli.append(DettaglioValore(id: "costi-\(r.id)", titolo: "\(vecchia.nome) → \(nuova.nome)",
                                            sottotitolo: "dal \(CifreDoc.percento(prima)) al \(CifreDoc.percento(dopo)) l’anno · \(Formati.euro(nuova.valore)) · \(anniTesto(anni))",
                                            cifra: risparmio, canale: nuova.canale))
        }
        guard sostituzioni > 0 else {
            return VoceValore(tipo: .costi, totale: nil, perCanale: [:], dettagli: [], stima: false,
                              motivoAssente: "Nessuna sostituzione fatta insieme")
        }
        guard !dettagli.isEmpty else {
            return VoceValore(tipo: .costi, totale: nil, perCanale: [:], dettagli: [], stima: false,
                              motivoAssente: "Manca il costo delle posizioni sostituite: scrivilo in Posizioni")
        }
        let motivo = senzaCosto > 0 ? "\(senzaCosto) \(senzaCosto == 1 ? "sostituzione senza costo non contata" : "sostituzioni senza costo non contate")" : nil
        return VoceValore(tipo: .costi, totale: perCanale.values.reduce(0, +), perCanale: perCanale, dettagli: dettagli, stima: false,
                          motivoAssente: motivo)
    }

    static func voceAlternativa(_ accettate: [Raccomandazione], posizioni: [Posizione], tabella: TabellaRiferimenti, oggi: Date,
                                nome: String, cal: Calendar) -> VoceValore {
        let t = MotoreTrackRecord.calcola(raccomandazioni: accettate, posizioni: posizioni, tabella: tabella, oggi: oggi, cal: cal)
        var dettagli: [DettaglioValore] = []
        var perCanale: [Canale: Double] = [:]
        for v in t.voci {
            guard case .scarto(let s) = v.misura else { continue }
            let canale = v.raccomandazione.canale ?? v.posizione?.canale
            if let canale { perCanale[canale, default: 0] += s.differenza }
            dettagli.append(DettaglioValore(id: "alternativa-\(v.id)", titolo: v.raccomandazione.proposta,
                                            sottotitolo: "rispetto a: \(v.raccomandazione.alternativa.descrizione)", cifra: s.differenza,
                                            canale: canale))
        }
        guard let totale = t.differenzaTotale, !dettagli.isEmpty else {
            return VoceValore(tipo: .alternativa, totale: nil, perCanale: [:], dettagli: [], stima: true,
                              motivoAssente: "Il track record non ha ancora misure per \(nome)")
        }
        return VoceValore(tipo: .alternativa, totale: totale, perCanale: perCanale, dettagli: dettagli, stima: true, motivoAssente: nil)
    }

    static func anniTesto(_ anni: Double) -> String {
        let a = (anni * 10).rounded() / 10
        let testo = a == a.rounded() ? "\(Int(a))" : String(format: "%.1f", a).replacingOccurrences(of: ".", with: ",")
        return a == 1 ? "1 anno" : "\(testo) anni"
    }

    /// Il periodo per il titolo: «tre anni», «un anno e mezzo», «14 mesi».
    static func periodo(mesi: Int) -> String {
        let nomi = ["", "un anno", "due anni", "tre anni", "quattro anni", "cinque anni", "sei anni", "sette anni", "otto anni",
                    "nove anni", "dieci anni"]
        if mesi % 12 == 0, mesi / 12 < nomi.count, mesi >= 12 { return nomi[mesi / 12] }
        if mesi < 24 { return "\(mesi) mesi" }
        let anni = mesi / 12
        return anni < nomi.count ? "più di \(nomi[anni])" : "\(anni) anni"
    }

    /// Il titolo dal testo dell'utente (o quello di prova) con {valore} e {periodo}; «almeno» se qualche voce manca.
    static func titolo(_ modello: String, valore: String, mesi: Int, parziale: Bool) -> String {
        let v = parziale ? "almeno \(valore)" : valore
        let t = modello.replacingOccurrences(of: "{valore}", with: v).replacingOccurrences(of: "{periodo}", with: periodo(mesi: mesi))
        return parziale ? t.replacingOccurrences(of: "circa almeno", with: "almeno") : t
    }
}
