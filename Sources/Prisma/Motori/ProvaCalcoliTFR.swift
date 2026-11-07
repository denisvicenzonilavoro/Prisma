import Foundation

/// Prove del confronto «TFR in azienda o nel fondo» (giro 6, specifica 11 §8.1, casi T0–T8): regole del TFR,
/// le due strade con e senza contributi, aliquota indicata a mano, rendimento negativo, retribuzione nulla,
/// rendimento di pareggio, ipotesi dal dossier di Marco, lettura tollerante e testi.
/// I valori attesi vengono da `calcoli_tfr.py` (stesse formule). Chiamata da `ProvaCalcoli.esegui()`.
///
/// Revisione del consulente (archivio 25), casi T11–T16 e valori ricalcolati con lo stesso metodo in Python:
/// - i casi T1–T8 restano con il rendimento LORDO (`rendimentoNetto = false`): i valori non cambiano;
/// - il costo dei contributi si porta alla pensione al tasso alternativo (nil = l'inflazione) invece che alla
///   rivalutazione netta del TFR: costo = Σ (contributo − IRPEF risparmiata) × (1 + tasso)^(anni che restano).
///   Cambiano T2 (costo 16.075,5381; differenza con i contributi 72.022,5836; pareggio con i contributi 0,4750
///   lordo e −0,0274 netto) e T3 (inflazione 0: costo = 5 × (4.800 − 1.247) = 17.765);
/// - reddito di riferimento = (tutte le quote future + TFR maturato) × 12 / (anni futuri + anni già fatti);
/// - prestazione del fondo: capitale = 50% del montante × (1 − imposta / montante), il resto in rendita con il
///   coefficiente del 4,5% / 12; tutto in capitale se 70% × montante × 4,5% < 50% × assegno sociale annuo
///   (546,24 × 13) × (1 + inflazione)^anni.
enum ProvaCalcoliTFR {
    static func esegui(_ verifica: VerificaCalcoli) {
        regole(verifica)
        soloTFR(verifica)
        conContributi(verifica)
        casiLimite(verifica)
        provaPareggio(verifica)
        dalCliente(verifica)
        lettura(verifica)
        testi(verifica)
        nettoLordo(verifica)
        prestazione(verifica)
        maturato(verifica)
        lavoratore(verifica)
        costoContributi(verifica)
    }

    // MARK: - Aiuti

    /// Tolleranze: importi al centesimo, percentuali a 1e−4, rendimenti di pareggio a 0,001.
    private static let tEuro = 0.01
    private static let tPercento = 1e-4
    private static let tPareggio = 0.001

    private static func ipotesi(retribuzione: Double, crescita: Double, anni: Int, inflazione: Double, rendimento: Double,
                                costo: Double, lavoratore: Double = 0, datore: Double = 0, partecipazione: Int = 0) -> IpotesiTFR {
        var i = IpotesiTFR()
        i.retribuzione = retribuzione
        i.crescitaReale = crescita
        i.anni = anni
        i.inflazione = inflazione
        i.rendimentoFondo = rendimento
        i.costoFondo = costo
        i.contributoLavoratore = lavoratore
        i.contributoDatore = datore
        i.anniPartecipazione = partecipazione
        // I casi T1–T8 sono scritti con il rendimento lordo (prima di costi e imposta)
        i.rendimentoNetto = false
        return i
    }

    /// T1: 30.000 €, 10 anni, inflazione 2%, fondo al 4% lordo con lo 0,5% di costi, nessun contributo.
    private static var t1: IpotesiTFR {
        ipotesi(retribuzione: 30_000, crescita: 0, anni: 10, inflazione: 2, rendimento: 4, costo: 0.5)
    }

    /// Il pareggio come coppia (lordo, netto); (−99, −99) se `.sempre`, (99, 99) se `.mai`, nil se manca.
    private static func coppia(_ p: PareggioTFR?) -> (Double, Double)? {
        guard let p else { return nil }
        switch p {
        case .a(let lordo, let netto): return (lordo, netto)
        case .sempre: return (-99, -99)
        case .mai: return (99, 99)
        }
    }

    // MARK: - T0 Regole

    private static func regole(_ verifica: VerificaCalcoli) {
        verifica("T0 TFR: quota annua 100/13,5 − 0,5", RegoleTFR.quotaAnnua, 6.907407, tolleranza: 1e-6)
        verifica("T0 TFR: rivalutazione netta con inflazione 2%", RegoleTFR.rivalutazioneNetta(inflazione: 2), 2.49, tolleranza: tPercento)
        verifica("T0 TFR: rivalutazione netta con inflazione −1% (resta l'1,5% fisso)", RegoleTFR.rivalutazioneNetta(inflazione: -1), 1.245,
                 tolleranza: tPercento)
        verifica("T0 TFR: rivalutazione lorda con inflazione 11,3%", RegoleTFR.rivalutazioneLorda(inflazione: 11.3), 9.975, tolleranza: 1e-9)
    }

    // MARK: - T1 Solo TFR

    private static func soloTFR(_ verifica: VerificaCalcoli) {
        guard let e = MotoreTFR.calcola(t1) else {
            verifica.vero("T1 TFR: esito calcolato", false)
            return
        }
        verifica("T1 TFR: crescita nominale 2%", e.crescitaNominale, 2, tolleranza: tPercento)
        verifica("T1 TFR: rendimento netto del fondo", e.rendimentoNettoFondo, 2.784, tolleranza: tPercento)
        verifica("T1 TFR: quote accantonate", e.quote, 22_690.2552, tolleranza: tEuro)
        verifica("T1 TFR: montante in azienda", e.azienda.montante, 25_307.2504, tolleranza: tEuro)
        verifica("T1 TFR: reddito di riferimento", e.redditoRiferimento, 27_228.3062, tolleranza: tEuro)
        verifica("T1 TFR: aliquota della tassazione separata", e.azienda.aliquota, 23.0, tolleranza: tPercento)
        verifica("T1 TFR: imposta in azienda", e.azienda.imposta, 5_218.7587, tolleranza: tEuro)
        verifica("T1 TFR: netto in azienda", e.azienda.netto, 20_088.4918, tolleranza: tEuro)
        verifica("T1 TFR: netto in azienda in euro di oggi", e.azienda.reale, 16_479.5601, tolleranza: tEuro)
        verifica("T1 TFR: montante nel fondo", e.fondo.montante, 25_639.3459, tolleranza: tEuro)
        verifica("T1 TFR: aliquota del fondo 15%", e.fondo.aliquota, 15.0, tolleranza: tPercento)
        verifica("T1 TFR: imposta nel fondo", e.fondo.imposta, 3_403.5383, tolleranza: tEuro)
        verifica("T1 TFR: netto nel fondo", e.fondo.netto, 22_235.8076, tolleranza: tEuro)
        verifica("T1 TFR: netto nel fondo in euro di oggi", e.fondo.reale, 18_241.1070, tolleranza: tEuro)
        verifica("T1 TFR: differenza", e.differenza, 2_147.3159, tolleranza: tEuro)
        let p = coppia(e.pareggio)
        verifica("T1 TFR: pareggio lordo", p?.0 ?? -1, 1.5049, tolleranza: tPareggio)
        verifica("T1 TFR: pareggio netto", p?.1 ?? -1, 0.7979, tolleranza: tPareggio)
        verifica.vero("T1 TFR: senza contributi nessuna terza strada", e.fondoContributi == nil && e.pareggioContributi == nil
                      && e.differenzaContributi == nil && e.puntiFondoContributi == nil)
        verifica.vero("T1 TFR: 10 anni e 11 punti per grafico", e.anni.count == 10 && e.puntiAzienda.count == 11 && e.puntiFondo.count == 11
                      && e.puntiAzienda.first?.valore == 0)
        verifica("T1 TFR: l'ultimo punto del fondo è il montante", e.puntiFondo.last?.valore ?? 0, e.fondo.montante, tolleranza: tEuro)
        verifica("T1 TFR: il versato dell'ultimo punto sono le quote", e.puntiFondo.last?.versato ?? 0, e.quote, tolleranza: tEuro)
    }

    // MARK: - T2, T3 Con i contributi

    private static func conContributi(_ verifica: VerificaCalcoli) {
        let i2 = ipotesi(retribuzione: 35_000, crescita: 1, anni: 30, inflazione: 2, rendimento: 4, costo: 0.5, lavoratore: 1.2, datore: 1.6)
        if let e = MotoreTFR.calcola(i2) {
            verifica("T2 TFR: crescita nominale", e.crescitaNominale, 3.02, tolleranza: tPercento)
            verifica("T2 TFR: quote accantonate", e.quote, 115_391.3539, tolleranza: tEuro)
            verifica("T2 TFR: reddito di riferimento", e.redditoRiferimento, 46_156.5416, tolleranza: tEuro)
            verifica("T2 TFR: aliquota della tassazione separata", e.azienda.aliquota, 26.9337, tolleranza: tPercento)
            verifica("T2 TFR: imposta in azienda", e.azienda.imposta, 31_079.1468, tolleranza: tEuro)
            verifica("T2 TFR: netto in azienda", e.azienda.netto, 128_575.3439, tolleranza: tEuro)
            verifica("T2 TFR: montante nel fondo", e.fondo.montante, 166_292.3659, tolleranza: tEuro)
            verifica("T2 TFR: aliquota del fondo dopo 30 anni", e.fondo.aliquota, 10.5, tolleranza: tPercento)
            verifica("T2 TFR: netto nel fondo", e.fondo.netto, 154_176.2737, tolleranza: tEuro)
            verifica("T2 TFR: montante con i contributi", e.fondoContributi?.montante ?? 0, 233_700.9603, tolleranza: tEuro)
            verifica("T2 TFR: contributi dedotti", e.dedotti, 46_775.2620, tolleranza: tEuro)
            verifica("T2 TFR: imposta con i contributi", e.fondoContributi?.imposta ?? 0, 17_027.4947, tolleranza: tEuro)
            verifica("T2 TFR: netto con i contributi", e.fondoContributi?.netto ?? 0, 216_673.4656, tolleranza: tEuro)
            verifica("T2 TFR: versato dal lavoratore", e.versatoLavoratore, 20_046.5408, tolleranza: tEuro)
            verifica("T2 TFR: versato dal datore", e.versatoDatore, 26_728.7211, tolleranza: tEuro)
            verifica("T2 TFR: IRPEF risparmiata", e.risparmioIrpef, 7_772.0865, tolleranza: tEuro)
            verifica("T2 TFR: costo dei contributi (all'inflazione)", e.costoContributi, 16_075.5381, tolleranza: tEuro)
            verifica("T2 TFR: di tasca propria", e.tascaPropria, 12_274.4543, tolleranza: tEuro)
            verifica("T2 TFR: differenza con i contributi", e.differenzaContributi ?? 0, 72_022.5836, tolleranza: tEuro)
            let p = coppia(e.pareggio)
            verifica("T2 TFR: pareggio lordo", p?.0 ?? -1, 2.4538, tolleranza: tPareggio)
            verifica("T2 TFR: pareggio netto", p?.1 ?? -1, 1.5533, tolleranza: tPareggio)
            let pc = coppia(e.pareggioContributi)
            verifica("T2 TFR: pareggio lordo con i contributi", pc?.0 ?? -1, 0.4750, tolleranza: tPareggio)
            verifica("T2 TFR: pareggio netto con i contributi", pc?.1 ?? -1, -0.0274, tolleranza: tPareggio)
            verifica.vero("T2 TFR: 31 punti per la terza strada", e.puntiFondoContributi?.count == 31)
        } else {
            verifica.vero("T2 TFR: esito calcolato", false)
        }

        let i3 = ipotesi(retribuzione: 120_000, crescita: 0, anni: 5, inflazione: 0, rendimento: 3, costo: 1, lavoratore: 4, datore: 2,
                         partecipazione: 20)
        if let e = MotoreTFR.calcola(i3) {
            verifica("T3 TFR: dedotti nel limite di 5.300 € l'anno", e.dedotti, 26_500, tolleranza: tEuro)
            verifica("T3 TFR: non dedotti", e.nonDedotti, 9_500, tolleranza: tEuro)
            verifica("T3 TFR: IRPEF risparmiata (2.900 € l'anno al 43%)", e.risparmioIrpef, 6_235, tolleranza: tEuro)
            verifica("T3 TFR: aliquota in azienda", e.azienda.aliquota, 35.1582, tolleranza: tPercento)
            verifica("T3 TFR: aliquota del fondo dopo 25 anni", e.fondo.aliquota, 12.0, tolleranza: tPercento)
            verifica("T3 TFR: netto in azienda", e.azienda.netto, 27_918.2282, tolleranza: tEuro)
            verifica("T3 TFR: netto nel fondo", e.fondo.netto, 37_798.1905, tolleranza: tEuro)
            verifica("T3 TFR: netto con i contributi", e.fondoContributi?.netto ?? 0, 71_770.9350, tolleranza: tEuro)
            verifica("T3 TFR: costo dei contributi (inflazione 0: 5 × 3.553 €)", e.costoContributi, 17_765, tolleranza: tEuro)
        } else {
            verifica.vero("T3 TFR: esito calcolato", false)
        }
    }

    // MARK: - T4, T5, T6 Aliquota a mano, rendimento negativo, retribuzione nulla

    private static func casiLimite(_ verifica: VerificaCalcoli) {
        var i4 = t1
        i4.aliquotaTFR = 25
        if let e = MotoreTFR.calcola(i4) {
            verifica("T4 TFR: imposta in azienda con l'aliquota indicata", e.azienda.imposta, 5_672.5638, tolleranza: tEuro)
            verifica("T4 TFR: netto in azienda", e.azienda.netto, 19_634.6867, tolleranza: tEuro)
            verifica("T4 TFR: differenza", e.differenza, 2_601.1210, tolleranza: tEuro)
        } else {
            verifica.vero("T4 TFR: esito calcolato", false)
        }

        var i5 = t1
        i5.rendimentoFondo = -5
        if let e = MotoreTFR.calcola(i5) {
            verifica("T5 TFR: rendimento netto negativo, senza imposta", e.rendimentoNettoFondo, -5.475, tolleranza: tPercento)
            verifica("T5 TFR: montante nel fondo", e.fondo.montante, 18_006.2847, tolleranza: tEuro)
            verifica("T5 TFR: imponibile = montante (meno delle quote)", e.fondo.imponibile, e.fondo.montante, tolleranza: tEuro)
            verifica("T5 TFR: imposta nel fondo", e.fondo.imposta, 2_700.9427, tolleranza: tEuro)
            verifica("T5 TFR: netto nel fondo", e.fondo.netto, 15_305.3420, tolleranza: tEuro)
            verifica("T5 TFR: differenza", e.differenza, -4_783.1498, tolleranza: tEuro)
        } else {
            verifica.vero("T5 TFR: esito calcolato", false)
        }

        var i6 = t1
        i6.retribuzione = 0
        verifica.vero("T6 TFR: retribuzione nulla, nessun esito", MotoreTFR.calcola(i6) == nil)

        // Inflazione negativa: il TFR si rivaluta comunque dell'1,5% fisso (netto 1,245%)
        let negativa = ipotesi(retribuzione: 30_000, crescita: 0, anni: 1, inflazione: -1, rendimento: 3, costo: 0)
        if let e = MotoreTFR.calcola(negativa) {
            verifica("T6b TFR: rivalutazione netta con inflazione negativa", e.rivalutazioneNetta, 1.245, tolleranza: tPercento)
            verifica("T6b TFR: un anno, netto in azienda", e.azienda.netto, 1_595.6111, tolleranza: tEuro)
            verifica("T6b TFR: un anno, netto nel fondo", e.fondo.netto, 1_761.3889, tolleranza: tEuro)
        } else {
            verifica.vero("T6b TFR: esito calcolato", false)
        }
    }

    // MARK: - T7 Pareggio

    private static func provaPareggio(_ verifica: VerificaCalcoli) {
        var i7 = t1
        i7.rendimentoFondo = 1.5049002869
        if let e = MotoreTFR.calcola(i7) {
            verifica("T7 TFR: al rendimento di pareggio le due strade si equivalgono", e.differenza, 0, tolleranza: tEuro)
        } else {
            verifica.vero("T7 TFR: esito calcolato", false)
        }
        let sempre = ipotesi(retribuzione: 30_000, crescita: 0, anni: 5, inflazione: 2, rendimento: 3, costo: 0.5, lavoratore: 0, datore: 5)
        let e = MotoreTFR.calcola(sempre)
        verifica.vero("T7b TFR: con il 5% del datore il fondo resta sempre avanti", e?.pareggioContributi == .sempre)
        // Neanche al 30%: un'aliquota a mano nulla in azienda e un'imposta del fondo che non può scendere sotto il 9%
        var mai = t1
        mai.aliquotaTFR = 0
        mai.anni = 1
        verifica.vero("T7c TFR: con l'aliquota in azienda a zero il fondo non raggiunge mai il TFR in un anno",
                      MotoreTFR.calcola(mai)?.pareggio == .mai)
    }

    // MARK: - T8 Ipotesi dal dossier di Marco

    private static func dalCliente(_ verifica: VerificaCalcoli) {
        let dati = DatiPrisma.demo()
        guard let marco = dati.clienti.first(where: { $0.id == "marco" }) else {
            verifica.vero("T8 TFR: Marco tra i clienti di prova", false)
            return
        }
        let posizioni = dati.posizioni.filter { $0.clienteId == "marco" }
        let i = IpotesiTFR.dalCliente(marco, posizioni: posizioni)
        verifica("T8 TFR: retribuzione di Marco", i.retribuzione, 48_000, tolleranza: tEuro)
        verifica("T8 TFR: crescita oltre l'inflazione", i.crescitaReale, 1, tolleranza: tPercento)
        verifica("T8 TFR: anni alla pensione = 67 − età", Double(i.anni), Double(67 - (marco.eta ?? 0)), tolleranza: 0)
        let pip = posizioni.first { $0.regime == .previdenza && $0.stato == .inEssere }
        verifica("T8 TFR: anni nella previdenza dal suo PIP", Double(i.anniPartecipazione),
                 Double(pip.map { MotoreFiscale.anniPartecipazione($0) } ?? -1), tolleranza: 0)
        verifica.vero("T8 TFR: nessun contributo (il PIP non riceve il TFR)", i.contributoLavoratore == 0 && i.contributoDatore == 0)
        verifica.vero("T8 TFR: canale Alleanza (Marco ha solo Alleanza)", i.canale == .alleanza)

        // Un fondo che riceve già il TFR: contributi in % della retribuzione, nome e canale del fondo
        var fondo = AiutiProva.posizione("Fondo negoziale", .previdenza, 20_000, canale: .indipendente) {
            $0.clienteId = "marco"
            $0.premio = 624
            $0.frequenza = .annuale
            $0.contributoDatore = 720
            $0.tfrConferito = 3_300
        }
        fondo.tipologia = "Fondo pensione negoziale"
        let conFondo = IpotesiTFR.dalCliente(marco, posizioni: posizioni + [fondo])
        verifica("T8b TFR: contributo del lavoratore 624 / 48.000", conFondo.contributoLavoratore, 1.3, tolleranza: tPercento)
        verifica("T8b TFR: contributo del datore 720 / 48.000", conFondo.contributoDatore, 1.5, tolleranza: tPercento)
        verifica.vero("T8b TFR: nome e canale del fondo", conFondo.nomeFondo == "Fondo negoziale" && conFondo.canale == .indipendente)

        // Senza cliente: i valori di partenza
        let vuoto = IpotesiTFR.dalCliente(nil, posizioni: [])
        verifica.vero("T8c TFR: senza cliente 30.000 €, 27 anni, canale indipendente",
                      vuoto.retribuzione == 30_000 && vuoto.anni == 27 && vuoto.canale == .indipendente)
    }

    // MARK: - Lettura tollerante

    private static func lettura(_ verifica: VerificaCalcoli) {
        let fuori = try? Archivio.decodificatore.decode(IpotesiTFR.self, from: Data(#"{"anni": 99, "retribuzione": "molta"}"#.utf8))
        verifica.vero("T9 TFR: lettura tollerante (anni 99 → 50, retribuzione illeggibile → 30.000)",
                      fuori?.anni == 50 && fuori?.retribuzione == 30_000)
        let vuoto = try? Archivio.decodificatore.decode(IpotesiTFR.self, from: Data("{}".utf8))
        verifica.vero("T9 TFR: un archivio senza campi prende i predefiniti", vuoto == IpotesiTFR())
        var i = t1
        i.contributoDatore = 1.6
        i.nomeFondo = "Fondo di prova"
        i.aliquotaTFR = 25
        let dati = try? Archivio.codificatore.encode(i)
        let riletta = dati.flatMap { try? Archivio.decodificatore.decode(IpotesiTFR.self, from: $0) }
        verifica.vero("T9 TFR: le ipotesi tornano uguali dall'archivio", riletta == i)
        verifica.vero("T9 TFR: nuove ipotesi con il rendimento netto", IpotesiTFR().rendimentoNetto
                      && IpotesiTFR().rendimentoFondo == RegoleTFR.rendimentoNettoPredefinito)
        // Un archivio della versione 24 ha il rendimento lordo: senza il campo nuovo resta lordo
        let v24 = try? Archivio.decodificatore.decode(IpotesiTFR.self, from: Data(#"{"rendimentoFondo": 3.5, "anni": 20}"#.utf8))
        verifica.vero("T9b TFR: archivio 24, rendimento letto come lordo e campi nuovi assenti",
                      v24?.rendimentoNetto == false && v24?.rendimentoFondo == 3.5 && v24?.anniServizio == nil
                      && v24?.tfrMaturato == nil && v24?.vecchioIscritto == nil && v24?.tassoAlternativo == nil)
        var nuove = t1
        nuove.rendimentoNetto = true
        nuove.anniServizio = 12
        nuove.tfrMaturato = 25_000
        nuove.aziendaGrande = true
        nuove.vecchioIscritto = true
        nuove.quotaConferita = 60
        nuove.tassoAlternativo = 3
        let datiNuove = try? Archivio.codificatore.encode(nuove)
        let rilette = datiNuove.flatMap { try? Archivio.decodificatore.decode(IpotesiTFR.self, from: $0) }
        verifica.vero("T9b TFR: i campi della versione 25 tornano uguali dall'archivio", rilette == nuove)
        let fuoriNuove = try? Archivio.decodificatore.decode(IpotesiTFR.self,
                                                            from: Data(#"{"quotaConferita": 150, "anniServizio": 99, "tfrMaturato": -5}"#.utf8))
        verifica.vero("T9b TFR: campi nuovi fuori limite riportati ai limiti",
                      fuoriNuove?.quotaConferita == 100 && fuoriNuove?.anniServizio == 50 && fuoriNuove?.tfrMaturato == 0)
    }

    // MARK: - Testi

    private static func testi(_ verifica: VerificaCalcoli) {
        // Coppie (ottenuto, atteso): niente catene lunghe di && con le stringhe (controllo dei tipi)
        let articoli: [(String, String)] = [(TestiTFR.del("1,5%"), "dell'1,5%"), (TestiTFR.del("2%"), "del 2%"),
                                            (TestiTFR.il("8%"), "l'8%"), (TestiTFR.il("11,3%"), "l'11,3%"),
                                            (TestiTFR.il("12%"), "il 12%"), (TestiTFR.del("1.500 €"), "del 1.500 €"),
                                            (TestiTFR.del("0,80%"), "dello 0,80%"), (TestiTFR.al("1,5%"), "all'1,5%")]
        verifica.vero("T10 TFR: «dell'1,5%», «del 2%», «l'8%», «l'11,3%», «il 12%»", articoli.allSatisfy { $0.0 == $0.1 })
        guard let e = MotoreTFR.calcola(t1) else { return }
        let t = TestiTFR(e, cliente: nil)
        verifica.vero("T10 TFR: titolo del confronto con il fondo avanti", t.titoloConfronto.hasPrefix("Nel fondo pensione ti resterebbero circa"))
        verifica.vero("T10 TFR: il pareggio nel testo", t.testoPareggio.contains("dell'1,50% lordo") && t.testoPareggio.contains("2,49%"))
        verifica.vero("T10 TFR: senza contributi nessun testo dei contributi", t.testoContributi == nil)
        verifica.vero("T10 TFR: sintesi in cinque punti senza contributi", t.sintesi.count == 5)
        verifica.vero("T10 TFR: pillole con il TFR futuro e il rendimento lordo",
                      t.pillole.contains("Solo TFR futuro") && t.pillole.contains("Rendimento lordo"))
        verifica.vero("T10 TFR: nessun avviso senza contributi", t.avvisi.isEmpty)
        verifica.vero("T10 TFR: il metodo legge le regole (6,91%, 5.300 €)",
                      TestiTFR.metodo.joined().contains("6,91%") && TestiTFR.metodo.joined().contains("5.300 €"))
        var i5 = t1
        i5.rendimentoFondo = -5
        if let e5 = MotoreTFR.calcola(i5) {
            verifica.vero("T10 TFR: titolo con l'azienda avanti", TestiTFR(e5, cliente: nil).titoloConfronto.hasPrefix("Lasciato in azienda"))
        }
    }

    // MARK: - T11 Rendimento netto o lordo

    private static func nettoLordo(_ verifica: VerificaCalcoli) {
        // Lo stesso fondo di T1 (4% lordo, 0,5% di costi = 2,784% netto) scritto in netto: stessi netti
        var netto = t1
        netto.rendimentoNetto = true
        netto.rendimentoFondo = 2.784
        if let e = MotoreTFR.calcola(netto) {
            verifica("T11 TFR: con il netto il rendimento non si tocca", e.rendimentoNettoFondo, 2.784, tolleranza: tPercento)
            verifica("T11 TFR: netto nel fondo uguale al caso lordo T1", e.fondo.netto, 22_235.8076, tolleranza: tEuro)
            verifica("T11 TFR: pareggio nella base netta", e.pareggio.nellaBase(netta: true) ?? -1, 0.7979, tolleranza: tPareggio)
            verifica("T11 TFR: pareggio lordo equivalente", e.pareggio.nellaBase(netta: false) ?? -1, 1.5049, tolleranza: tPareggio)
            let t = TestiTFR(e, cliente: nil)
            verifica.vero("T11 TFR: la frase del pareggio dice «dello 0,80% netto»", t.frasePareggio.contains("dello 0,80% netto"))
        } else {
            verifica.vero("T11 TFR: esito calcolato", false)
        }
        // Il 4% netto della COVIP non perde di nuovo costi e imposta (prima diventava 2,784%)
        var covip = t1
        covip.rendimentoNetto = true
        covip.rendimentoFondo = 4
        if let e = MotoreTFR.calcola(covip) {
            verifica("T11b TFR: 4% netto resta 4%", e.rendimentoNettoFondo, 4, tolleranza: tPercento)
            verifica("T11b TFR: netto nel fondo al 4% netto", e.fondo.netto, 23_664.8505, tolleranza: tEuro)
        } else {
            verifica.vero("T11b TFR: esito calcolato", false)
        }
        verifica("T11c TFR: lordo equivalente all'inverso del netto", MotoreTFR.lordoEquivalente(t1, netto: 2.784), 4, tolleranza: 1e-9)
    }

    // MARK: - T12 Prestazione: metà in capitale, metà in rendita

    private static func prestazione(_ verifica: VerificaCalcoli) {
        let i2 = ipotesi(retribuzione: 35_000, crescita: 1, anni: 30, inflazione: 2, rendimento: 4, costo: 0.5, lavoratore: 1.2, datore: 1.6)
        guard let e = MotoreTFR.calcola(i2), let c = e.fondoContributi?.prestazione, let f = e.fondo.prestazione else {
            verifica.vero("T12 TFR: prestazioni calcolate", false)
            return
        }
        verifica("T12 TFR: soglia della rendita piccola (50% assegno sociale rivalutato)", c.sogliaRenditaPiccola, 6_431.3480, tolleranza: tEuro)
        verifica.vero("T12 TFR: con i contributi la rendita non è piccola", !c.tuttoCapitale)
        verifica("T12 TFR: subito in capitale (50%)", c.capitale, 108_336.7328, tolleranza: tEuro)
        verifica("T12 TFR: in rendita", c.inRendita, 108_336.7328, tolleranza: tEuro)
        verifica("T12 TFR: rendita al mese (4,5% / 12)", c.renditaMensile, 406.2627, tolleranza: tEuro)
        verifica("T12 TFR: capitale + rendita = netto", c.capitale + c.inRendita, e.fondoContributi?.netto ?? 0, tolleranza: tEuro)
        // Solo TFR: 70% × 166.292 € × 4,5% = 5.238 € < 6.431 €: tutto in capitale
        verifica.vero("T12 TFR: solo TFR, rendita piccola: tutto in capitale", f.tuttoCapitale && f.renditaMensile == 0)
        verifica("T12 TFR: tutto in capitale = netto", f.capitale, e.fondo.netto, tolleranza: tEuro)
        verifica.vero("T12 TFR: il TFR in azienda è tutto in capitale", e.azienda.prestazione == nil)
        if let t1e = MotoreTFR.calcola(t1) {
            verifica.vero("T12 TFR: pillola «Fondo tutto in capitale» con la rendita piccola",
                          TestiTFR(t1e, cliente: nil).pillole.contains("Fondo tutto in capitale"))
        }
    }

    // MARK: - T13 TFR maturato e anni di servizio nell'aliquota

    private static func maturato(_ verifica: VerificaCalcoli) {
        var i = t1
        i.anniServizio = 10
        i.tfrMaturato = 30_000
        if let e = MotoreTFR.calcola(i) {
            verifica("T13 TFR: reddito di riferimento su tutto il TFR e 20 anni", e.redditoRiferimento, 31_614.1531, tolleranza: tEuro)
            verifica("T13 TFR: aliquota con il maturato", e.azienda.aliquota, 24.1432, tolleranza: tPercento)
            verifica("T13 TFR: netto in azienda", e.azienda.netto, 19_829.0951, tolleranza: tEuro)
            verifica("T13 TFR: il maturato non entra nei netti del fondo", e.fondo.netto, 22_235.8076, tolleranza: tEuro)
            verifica("T13 TFR: differenza", e.differenza, 2_406.7125, tolleranza: tEuro)
            verifica.vero("T13 TFR: 20 anni di servizio, maturato indicato", e.anniServizioTotali == 20 && !e.maturatoStimato)
        } else {
            verifica.vero("T13 TFR: esito calcolato", false)
        }
        var stimato = t1
        stimato.anniServizio = 10
        if let e = MotoreTFR.calcola(stimato) {
            verifica("T13b TFR: maturato stimato (10 × 30.000 × 6,907%)", e.tfrMaturato, 20_722.2222, tolleranza: tEuro)
            verifica("T13b TFR: reddito di riferimento con il maturato stimato", e.redditoRiferimento, 26_047.4864, tolleranza: tEuro)
            verifica.vero("T13b TFR: maturato segnato come stimato", e.maturatoStimato
                          && TestiTFR(e, cliente: nil).pillole.contains("Maturato stimato"))
        } else {
            verifica.vero("T13b TFR: esito calcolato", false)
        }
    }

    // MARK: - T14 Chi non ha il TFR, ripieghi, vecchi iscritti, fondo con più TFR

    private static func lavoratore(_ verifica: VerificaCalcoli) {
        let dati = DatiPrisma.demo()
        guard var marco = dati.clienti.first(where: { $0.id == "marco" }) else {
            verifica.vero("T14 TFR: Marco tra i clienti di prova", false)
            return
        }
        marco.profilo.lavoro = DatiLavoro(tipo: .autonomo)
        verifica.vero("T14 TFR: un artigiano non ha TFR", IpotesiTFR.senzaTFR(marco) == .autonomo)
        marco.profilo.lavoro = DatiLavoro(tipo: .cassaProfessionale)
        verifica.vero("T14 TFR: un professionista non ha TFR", IpotesiTFR.senzaTFR(marco) == .cassaProfessionale)
        marco.profilo.lavoro = DatiLavoro(tipo: .dipendente)
        verifica.vero("T14 TFR: un dipendente sì", IpotesiTFR.senzaTFR(marco) == nil)
        verifica.vero("T14 TFR: tipo non indicato: si confronta", IpotesiTFR.senzaTFR(nil) == nil)

        let vuoto = IpotesiTFR.ripieghi(nil)
        verifica.vero("T14 TFR: senza cliente tutti i ripieghi segnalati", vuoto.retribuzione && vuoto.eta && vuoto.etaPensione)
        verifica.vero("T14 TFR: Marco ha la data di nascita", !IpotesiTFR.ripieghi(marco).eta)

        // Vecchio iscritto: conferisce il 50%, l'aliquota resta quella di tutto il TFR
        var vecchio = t1
        vecchio.vecchioIscritto = true
        vecchio.quotaConferita = 50
        if let e = MotoreTFR.calcola(vecchio) {
            verifica("T15 TFR: quote confrontate, metà", e.quote, 11_345.1276, tolleranza: tEuro)
            verifica("T15 TFR: quote intere per l'aliquota", e.quoteTotali, 22_690.2552, tolleranza: tEuro)
            verifica("T15 TFR: aliquota di tutto il TFR", e.azienda.aliquota, 23.0, tolleranza: tPercento)
            verifica("T15 TFR: netto in azienda", e.azienda.netto, 10_044.2459, tolleranza: tEuro)
            verifica("T15 TFR: netto nel fondo", e.fondo.netto, 11_117.9038, tolleranza: tEuro)
            verifica.vero("T15 TFR: conferimento parziale", e.conferimentoParziale)
        } else {
            verifica.vero("T15 TFR: esito calcolato", false)
        }
        var nuovoIscritto = vecchio
        nuovoIscritto.vecchioIscritto = nil
        verifica("T15 TFR: senza vecchia iscrizione si conferisce tutto", nuovoIscritto.quotaConferitaEffettiva, 100, tolleranza: 0)

        // Due fondi che ricevono il TFR: vale quello che ne riceve di più, non il primo
        let posizioni = dati.posizioni.filter { $0.clienteId == "marco" }
        let poco = AiutiProva.posizione("Fondo piccolo", .previdenza, 5_000, canale: .alleanza) {
            $0.clienteId = "marco"
            $0.tfrConferito = 500
        }
        let tanto = AiutiProva.posizione("Fondo grande", .previdenza, 20_000, canale: .indipendente) {
            $0.clienteId = "marco"
            $0.tfrConferito = 3_300
        }
        let scelte = IpotesiTFR.dalCliente(marco, posizioni: posizioni + [poco, tanto])
        verifica.vero("T8d TFR: il fondo con più TFR conferito", scelte.nomeFondo == "Fondo grande" && scelte.canale == .indipendente)

        // Il datore senza il contributo del cliente: avviso
        let soloDatore = ipotesi(retribuzione: 30_000, crescita: 0, anni: 5, inflazione: 2, rendimento: 3, costo: 0.5, datore: 1.5)
        if let e = MotoreTFR.calcola(soloDatore) {
            verifica.vero("T14 TFR: avviso del datore senza il cliente", e.datoreSenzaLavoratore && !TestiTFR(e, cliente: nil).avvisi.isEmpty)
        }
    }

    // MARK: - T16 Costo dei contributi a un tasso dichiarato

    private static func costoContributi(_ verifica: VerificaCalcoli) {
        var i = ipotesi(retribuzione: 35_000, crescita: 1, anni: 30, inflazione: 2, rendimento: 4, costo: 0.5, lavoratore: 1.2, datore: 1.6)
        i.tassoAlternativo = 0
        if let e = MotoreTFR.calcola(i) {
            verifica("T16 TFR: al tasso 0 il costo è quanto messo di tasca propria", e.costoContributi, e.tascaPropria, tolleranza: tEuro)
            verifica("T16 TFR: costo al tasso 0", e.costoContributi, 12_274.4543, tolleranza: tEuro)
            verifica("T16 TFR: vantaggio con i contributi", e.differenzaContributi ?? 0, 75_823.6674, tolleranza: tEuro)
            verifica("T16 TFR: tasso dichiarato nell'esito", e.tassoAlternativo, 0, tolleranza: tPercento)
        } else {
            verifica.vero("T16 TFR: esito calcolato", false)
        }
    }
}
