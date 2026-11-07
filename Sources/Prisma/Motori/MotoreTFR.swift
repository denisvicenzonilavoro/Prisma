import Foundation

/// Le regole del TFR, tutte in un punto: se cambia la norma si cambia qui.
/// - Art. 2120 c.c.: quota annua = retribuzione / 13,5; rivalutazione al 31 dicembre dell'1,5% fisso più il 75%
///   dell'aumento dell'indice ISTAT dei prezzi al consumo per le famiglie di operai e impiegati rispetto a dicembre
///   dell'anno prima, esclusa la quota maturata nell'anno.
/// - Art. 3 L. 297/1982: contributo aggiuntivo IVS dello 0,50% della retribuzione, trattenuto sulla quota di TFR.
/// - Art. 11, c. 3, D.Lgs. 47/2000 (aliquota del 17% dalla L. 190/2014, art. 1, c. 623): imposta sostitutiva
///   sulla rivalutazione, trattenuta ogni anno dal fondo TFR.
/// - Art. 17, c. 1, lett. a), e art. 19 TUIR: tassazione separata del TFR, al netto delle rivalutazioni già tassate,
///   con l'aliquota del «reddito di riferimento» = TFR × 12 / anni di servizio.
/// - D.Lgs. 252/2005: art. 8 (conferimento del TFR, contributi, deducibilità nel limite dell'art. 8, c. 4),
///   art. 11, c. 6 (prestazioni al 15%, meno 0,30 punti per ogni anno oltre il 15°, fino al 9%), art. 17 (20% sui
///   rendimenti, 12,5% sulla parte in titoli di Stato).
/// Il fisco del fondo e l'IRPEF stanno in `RegoleFiscali`.
enum RegoleTFR {
    static let divisore = 13.5
    static let contributoIVS = 0.5
    /// % della retribuzione accantonata ogni anno: 100 / 13,5 − 0,5 = 6,9074% (la COVIP scrive «6,91%»).
    static var quotaAnnua: Double { 100 / divisore - contributoIVS }
    static let rivalutazioneFissa = 1.5
    static let quotaInflazione = 0.75
    static let impostaRivalutazione = 17.0
    /// Contributi previdenziali a carico del dipendente (FPLD INPS, 9,19%): tolti dalla retribuzione per
    /// stimare l'imponibile IRPEF su cui si calcola il risparmio della deduzione.
    static let contributiDipendente = 9.19
    /// Rendimento del fondo di partenza: netto di costi e imposta (come lo pubblicano la COVIP e le schede),
    /// e lordo per chi sceglie la base lorda.
    static let rendimentoNettoPredefinito = 2.5
    static let rendimentoFondoPredefinito = 3.5
    static let costoFondoPredefinito = 0.5
    /// Intervallo in cui si cerca il rendimento di pareggio (%, nella base scelta: netto o lordo).
    static let pareggioMinimo = -10.0
    static let pareggioMassimo = 30.0
    /// Precisione e passi massimi della ricerca del pareggio (bisezione).
    static let precisionePareggio = 1e-9
    static let passiPareggio = 200
    /// Età di pensione e del cliente quando non sono indicate (ipotesi di partenza dal dossier).
    static let etaPensionePredefinita = RegolePensione.etaVecchiaia
    static let etaPredefinita = 40
    /// Retribuzione e crescita oltre l'inflazione quando il dossier non le indica.
    static let retribuzionePredefinita = 30_000.0
    static let crescitaRealePredefinita = 1.0
    /// Aziende con almeno 50 dipendenti: il TFR non conferito va al Fondo di Tesoreria INPS (L. 296/2006).
    static let dipendentiTesoreria = 50
    /// Quota massima della prestazione ritirabile in capitale alla pensione (art. 11, c. 3, D.Lgs. 252/2005), %.
    static let quotaCapitaleMassima = 50.0
    /// Eccezione della rendita piccola (art. 11, c. 3): se convertendo il 70% del montante la rendita annua è
    /// meno del 50% dell'assegno sociale, si può ritirare tutto in capitale.
    static let quotaProvaRendita = 70.0
    static let quotaAssegnoSociale = 50.0
    /// Assegno sociale annuo di oggi (2026: 546,24 € al mese per 13 mensilità; da aggiornare ogni anno con la
    /// circolare INPS). Alla pensione si rivaluta con l'inflazione ipotizzata.
    static let assegnoSocialeMensile = 546.24
    static var assegnoSocialeAnnuo: Double { assegnoSocialeMensile * RegolePensione.mensilita }
    /// Coefficiente di conversione in rendita (% annua del capitale convertito): stima semplice e dichiarata
    /// di una rendita vitalizia immediata senza reversibilità verso i 67 anni. Il coefficiente vero è nel
    /// documento sulle rendite del fondo.
    static let coefficienteRendita = 4.5
    /// Rate della rendita all'anno (le rendite dei fondi si pagano di solito in 12 rate).
    static let rateRendita = 12.0
    /// Vecchi iscritti (prima del 29/4/1993): quota minima del TFR da conferire se il contratto non dice altro.
    static let quotaVecchiIscritti = 50.0

    static func rivalutazioneLorda(inflazione: Double) -> Double { rivalutazioneFissa + quotaInflazione * max(0, inflazione) }
    static func rivalutazioneNetta(inflazione: Double) -> Double { rivalutazioneLorda(inflazione: inflazione) * (1 - impostaRivalutazione / 100) }
}

/// Un anno del confronto (fine anno).
struct AnnoTFR: Identifiable {
    let anno: Int                 // 1…N
    let retribuzione: Double
    let quota: Double             // quota di TFR che va al fondo (tutta, o quella del vecchio iscritto)
    let contributoLavoratore: Double
    let contributoDatore: Double
    let risparmioIrpef: Double
    let azienda: Double           // fondo TFR in azienda a fine anno
    let fondo: Double             // fondo pensione con il solo TFR
    let fondoContributi: Double   // fondo pensione con TFR e contributi (= fondo se non ce ne sono)
    var id: Int { anno }
}

/// Una strada alla pensione: montante, imposta all'uscita e netto.
struct StradaTFR {
    let montante: Double
    let imponibile: Double
    let aliquota: Double          // %
    let imposta: Double
    var netto: Double { montante - imposta }
    let reale: Double             // netto / (1 + inflazione)^N
    /// Solo per il fondo: come si riceve il netto (capitale e rendita). nil per il TFR in azienda, tutto in capitale.
    var prestazione: PrestazioneTFR? = nil
}

/// La prestazione del fondo alla pensione (art. 11, c. 3, D.Lgs. 252/2005): al massimo il 50% in capitale,
/// il resto in rendita; tutto in capitale se la rendita sarebbe piccola. Importi netti, nominali.
struct PrestazioneTFR: Equatable {
    /// true: la rendita del 70% del montante sarebbe meno di metà dell'assegno sociale, tutto in capitale.
    let tuttoCapitale: Bool
    /// Netto ritirabile subito in capitale e netto che diventa rendita.
    let capitale: Double
    let inRendita: Double
    /// Rendita stimata al mese, netta (coefficiente `RegoleTFR.coefficienteRendita`), e in euro di oggi.
    let renditaMensile: Double
    let renditaMensileReale: Double
    /// La soglia della rendita piccola alla pensione (50% dell'assegno sociale rivalutato, annua).
    let sogliaRenditaPiccola: Double
}

enum PareggioTFR: Equatable {
    /// Rendimento lordo (prima di costi e imposta) e netto annuo del fondo a cui le due strade si equivalgono.
    /// Con la base netta il lordo è quello equivalente con i costi indicati (solo informativo).
    case a(lordo: Double, netto: Double)
    /// Il fondo resta avanti anche al −10% l'anno (nella base scelta).
    case sempre
    /// Il fondo resta indietro anche al +30% l'anno (nella base scelta).
    case mai

    /// Il rendimento di pareggio nella base delle ipotesi (netto o lordo); nil per `.sempre` e `.mai`.
    func nellaBase(netta: Bool) -> Double? {
        guard case .a(let lordo, let netto) = self else { return nil }
        return netta ? netto : lordo
    }
}

struct EsitoTFR {
    let ipotesi: IpotesiTFR
    let anni: [AnnoTFR]
    let quote: Double                     // Σ quote di TFR confrontate (quelle che andrebbero al fondo)
    /// Σ quote di TFR future intere (anche la parte che il vecchio iscritto lascia in azienda).
    let quoteTotali: Double
    /// TFR già maturato usato nell'aliquota (indicato o stimato) e anni di servizio totali.
    let tfrMaturato: Double
    let maturatoStimato: Bool
    let anniServizioTotali: Int
    /// Tasso (%) a cui si valuta il costo dei contributi del cliente.
    let tassoAlternativo: Double
    let crescitaNominale: Double          // %
    let rivalutazioneLorda: Double        // %
    let rivalutazioneNetta: Double        // %
    let rendimentoNettoFondo: Double      // %
    let redditoRiferimento: Double
    let azienda: StradaTFR
    let fondo: StradaTFR                  // solo il TFR
    let fondoContributi: StradaTFR?       // nil senza contributi
    let versatoLavoratore: Double
    let versatoDatore: Double
    let dedotti: Double
    var nonDedotti: Double { versatoLavoratore + versatoDatore - dedotti }
    let risparmioIrpef: Double
    /// Quanto sono costati i contributi del lavoratore (versati meno IRPEF risparmiata: i soldi che altrimenti
    /// resterebbero in busta paga, già tassati), portati alla pensione al `tassoAlternativo`.
    let costoContributi: Double
    /// I contributi del cliente meno l'IRPEF risparmiata, senza interessi: quanto ha messo «di tasca sua».
    var tascaPropria: Double { versatoLavoratore - risparmioIrpef }
    var differenza: Double { fondo.netto - azienda.netto }
    var differenzaContributi: Double? { fondoContributi.map { $0.netto - azienda.netto - costoContributi } }
    let pareggio: PareggioTFR
    let pareggioContributi: PareggioTFR?
    /// Punti per i grafici (anno 0 a zero): azienda, fondo, fondo con i contributi.
    var puntiAzienda: [PuntoProiezione]
    var puntiFondo: [PuntoProiezione]
    var puntiFondoContributi: [PuntoProiezione]?

    /// Anni di partecipazione alla previdenza complementare alla pensione (per l'aliquota del fondo).
    var anniPartecipazioneFinali: Int { ipotesi.anniPartecipazione + ipotesi.anni }
    /// true se nel confronto entrano contributi del lavoratore o del datore.
    var conContributi: Bool { fondoContributi != nil }
    /// true se si confronta solo una parte del TFR (vecchio iscritto).
    var conferimentoParziale: Bool { ipotesi.quotaConferitaEffettiva < 100 }
    /// Il contributo del datore senza quello del cliente: di norma il datore versa solo se versa anche il lavoratore.
    var datoreSenzaLavoratore: Bool { ipotesi.contributoDatore > 0 && ipotesi.contributoLavoratore <= 0 }
}

/// «TFR in azienda o nel fondo»: il netto alla pensione del TFR futuro lasciato in azienda contro quello versato
/// in un fondo pensione, con o senza contributi. Motore puro: nessun accesso ai dati.
enum MotoreTFR {
    /// I numeri del confronto senza pareggio (la ricerca del pareggio rifà il conto molte volte).
    private struct Conto {
        var anni: [AnnoTFR] = []
        var quote = 0.0
        var quoteTotali = 0.0
        var maturato = 0.0
        var maturatoStimato = false
        var anniServizio = 0
        var azienda = 0.0
        var fondo = 0.0
        var fondoContributi = 0.0
        var versatoLavoratore = 0.0
        var versatoDatore = 0.0
        var dedotti = 0.0
        var risparmio = 0.0
        var costoContributi = 0.0
        var crescita = 0.0       // frazione
        var rt = 0.0             // frazione
        var rf = 0.0             // frazione
        var ra = 0.0             // frazione: tasso del costo dei contributi

        /// Reddito di riferimento della tassazione separata: tutto il TFR (maturato e futuro, anche la parte non
        /// conferita) × 12 / tutti gli anni di servizio.
        var redditoRiferimento: Double {
            let n = anniServizio
            return n > 0 ? (quoteTotali + maturato) * 12 / Double(n) : 0
        }
    }

    /// Il rendimento netto annuo del fondo (%) dal valore nella base delle ipotesi: con la base netta è già lui.
    static func rendimentoNetto(_ i: IpotesiTFR, _ r: Double) -> Double {
        i.rendimentoNetto ? r : RegoleFiscali.rendimentoNettoPrevidenza(lordo: r, costo: i.costoFondo,
                                                                         quotaTitoliStato: i.titoliStatoFondo)
    }

    /// Il rendimento lordo equivalente (%) a un netto, con i costi e la quota in titoli di Stato delle ipotesi:
    /// l'inverso di `RegoleFiscali.rendimentoNettoPrevidenza`.
    static func lordoEquivalente(_ i: IpotesiTFR, netto n: Double) -> Double {
        let aliquota = RegoleFiscali.aliquotaRendimentiPrevidenza(quotaTitoliStato: i.titoliStatoFondo)
        let dopoCosti = n > 0 ? n / (1 - aliquota / 100) : n
        let costo = min(max(i.costoFondo, 0), 99) / 100
        return ((1 + dopoCosti / 100) / (1 - costo) - 1) * 100
    }

    /// Il conto anno per anno. `dettaglio` false salta le righe (per il pareggio).
    private static func conto(_ i: IpotesiTFR, rendimentoFondo: Double, dettaglio: Bool) -> Conto {
        var c = Conto()
        let n = max(1, i.anni)
        c.crescita = (1 + i.crescitaReale / 100) * (1 + i.inflazione / 100) - 1
        c.rt = RegoleTFR.rivalutazioneNetta(inflazione: i.inflazione) / 100
        c.rf = rendimentoNetto(i, rendimentoFondo) / 100
        c.ra = (i.tassoAlternativo ?? i.inflazione) / 100
        let quotaPercento = i.quotaTFR ?? RegoleTFR.quotaAnnua
        let conferita = i.quotaConferitaEffettiva / 100
        let servizio = max(0, i.anniServizio ?? 0)
        c.anniServizio = n + servizio
        if let m = i.tfrMaturato {
            c.maturato = max(0, m)
        } else if servizio > 0 {
            // Stima: gli anni già fatti con la quota di oggi (senza rivalutazioni, come vuole l'imponibile)
            c.maturato = Double(servizio) * i.retribuzione * quotaPercento / 100
            c.maturatoStimato = true
        }
        let limite = RegoleFiscali.limiteDeducibilita
        if dettaglio { c.anni.reserveCapacity(n) }
        for t in 1...n {
            let ral = i.retribuzione * pow(1 + c.crescita, Double(t - 1))
            let quotaIntera = ral * quotaPercento / 100
            let quota = quotaIntera * conferita
            let lavoratore = ral * i.contributoLavoratore / 100
            let datore = ral * i.contributoDatore / 100
            c.azienda = c.azienda * (1 + c.rt) + quota
            c.fondo = c.fondo * (1 + c.rf) + quota
            c.fondoContributi = c.fondoContributi * (1 + c.rf) + quota + lavoratore + datore
            c.quote += quota
            c.quoteTotali += quotaIntera
            c.dedotti += min(lavoratore + datore, limite)
            // Il contributo del datore è reddito del dipendente ma si deduce: conta solo la deduzione del proprio
            let deduzione = min(lavoratore, max(0, limite - datore))
            let risparmio = RegoleFiscali.risparmioDeduzione(reddito: ral * (1 - RegoleTFR.contributiDipendente / 100),
                                                             deduzione: deduzione)
            c.risparmio += risparmio
            c.versatoLavoratore += lavoratore
            c.versatoDatore += datore
            c.costoContributi = c.costoContributi * (1 + c.ra) + (lavoratore - risparmio)
            if dettaglio {
                c.anni.append(AnnoTFR(anno: t, retribuzione: ral, quota: quota, contributoLavoratore: lavoratore,
                                      contributoDatore: datore, risparmioIrpef: risparmio, azienda: c.azienda,
                                      fondo: c.fondo, fondoContributi: c.fondoContributi))
            }
        }
        return c
    }

    /// Aliquota della tassazione separata del TFR in azienda: quella indicata a mano o l'aliquota media IRPEF
    /// del reddito di riferimento (tutto il TFR, tutti gli anni di servizio).
    private static func aliquotaAzienda(_ i: IpotesiTFR, _ c: Conto) -> Double {
        if let a = i.aliquotaTFR { return a }
        let r = c.redditoRiferimento
        return r > 0 ? RegoleFiscali.irpef(r) / r * 100 : 0
    }

    private static func nettoAzienda(_ i: IpotesiTFR, _ c: Conto) -> Double {
        c.azienda - c.quote * aliquotaAzienda(i, c) / 100
    }

    private static func aliquotaFondo(_ i: IpotesiTFR) -> Double {
        RegoleFiscali.aliquotaPrevidenza(anni: i.anniPartecipazione + max(1, i.anni))
    }

    private static func nettoFondo(_ i: IpotesiTFR, _ c: Conto) -> Double {
        c.fondo - min(c.quote, c.fondo) * aliquotaFondo(i) / 100
    }

    private static func nettoFondoContributi(_ i: IpotesiTFR, _ c: Conto) -> Double {
        c.fondoContributi - min(c.quote + c.dedotti, c.fondoContributi) * aliquotaFondo(i) / 100
    }

    /// Il rendimento del fondo (nella base delle ipotesi) a cui le strade si equivalgono: bisezione tra
    /// `pareggioMinimo` e `pareggioMassimo`.
    private static func pareggio(_ i: IpotesiTFR, conContributi: Bool) -> PareggioTFR {
        func scarto(_ r: Double) -> Double {
            let c = conto(i, rendimentoFondo: r, dettaglio: false)
            let fondo = conContributi ? nettoFondoContributi(i, c) - c.costoContributi : nettoFondo(i, c)
            return fondo - nettoAzienda(i, c)
        }
        var basso = RegoleTFR.pareggioMinimo
        var alto = RegoleTFR.pareggioMassimo
        if scarto(basso) > 0 { return .sempre }
        if scarto(alto) < 0 { return .mai }
        var passi = 0
        while alto - basso >= RegoleTFR.precisionePareggio && passi < RegoleTFR.passiPareggio {
            let medio = (basso + alto) / 2
            if scarto(medio) > 0 { alto = medio } else { basso = medio }
            passi += 1
        }
        let r = (basso + alto) / 2
        if i.rendimentoNetto { return .a(lordo: lordoEquivalente(i, netto: r), netto: r) }
        return .a(lordo: r, netto: rendimentoNetto(i, r))
    }

    /// Come si riceve il netto del fondo: al massimo il 50% in capitale, il resto in rendita, salvo la rendita
    /// piccola. L'imposta si ripartisce in proporzione tra capitale e rendita.
    static func prestazione(montante: Double, imposta: Double, inflazione: Double, anni n: Int) -> PrestazioneTFR {
        let netto = montante - imposta
        let rivalutazione = pow(1 + inflazione / 100, Double(n))
        let deflatore = rivalutazione > 0 ? rivalutazione : 1
        let soglia = RegoleTFR.assegnoSocialeAnnuo * RegoleTFR.quotaAssegnoSociale / 100 * deflatore
        let renditaProva = montante * RegoleTFR.quotaProvaRendita / 100 * RegoleTFR.coefficienteRendita / 100
        if montante <= 0 || renditaProva < soglia {
            return PrestazioneTFR(tuttoCapitale: true, capitale: netto, inRendita: 0, renditaMensile: 0,
                                  renditaMensileReale: 0, sogliaRenditaPiccola: soglia)
        }
        let quotaNetta = 1 - imposta / montante
        let capitale = montante * RegoleTFR.quotaCapitaleMassima / 100 * quotaNetta
        let inRendita = netto - capitale
        let mensile = inRendita * RegoleTFR.coefficienteRendita / 100 / RegoleTFR.rateRendita
        return PrestazioneTFR(tuttoCapitale: false, capitale: capitale, inRendita: inRendita, renditaMensile: mensile,
                              renditaMensileReale: mensile / deflatore, sogliaRenditaPiccola: soglia)
    }

    /// nil se la retribuzione non è positiva.
    static func calcola(_ i: IpotesiTFR) -> EsitoTFR? {
        guard i.retribuzione > 0, i.retribuzione.isFinite else { return nil }
        let n = max(1, i.anni)
        let c = conto(i, rendimentoFondo: i.rendimentoFondo, dettaglio: true)
        let deflatore = pow(1 + i.inflazione / 100, Double(n))
        func reale(_ netto: Double) -> Double { deflatore > 0 ? netto / deflatore : netto }

        let aliquotaA = aliquotaAzienda(i, c)
        let impostaA = c.quote * aliquotaA / 100
        let azienda = StradaTFR(montante: c.azienda, imponibile: c.quote, aliquota: aliquotaA, imposta: impostaA,
                                reale: reale(c.azienda - impostaA))
        let aliquotaF = aliquotaFondo(i)
        let imponibileB = min(c.quote, c.fondo)
        let impostaB = imponibileB * aliquotaF / 100
        let fondo = StradaTFR(montante: c.fondo, imponibile: imponibileB, aliquota: aliquotaF, imposta: impostaB,
                              reale: reale(c.fondo - impostaB),
                              prestazione: prestazione(montante: c.fondo, imposta: impostaB, inflazione: i.inflazione, anni: n))
        let conContributi = i.contributoLavoratore + i.contributoDatore > 0
        var fondoContributi: StradaTFR?
        if conContributi {
            let imponibileC = min(c.quote + c.dedotti, c.fondoContributi)
            let impostaC = imponibileC * aliquotaF / 100
            let prestazioneC = prestazione(montante: c.fondoContributi, imposta: impostaC, inflazione: i.inflazione, anni: n)
            fondoContributi = StradaTFR(montante: c.fondoContributi, imponibile: imponibileC, aliquota: aliquotaF,
                                        imposta: impostaC, reale: reale(c.fondoContributi - impostaC),
                                        prestazione: prestazioneC)
        }

        // Punti dei grafici: anno 0 a zero, poi i montanti di fine anno
        var puntiA = [PuntoProiezione(anno: 0, versato: 0, valore: 0)]
        var puntiB = puntiA
        var puntiC = puntiA
        var quote = 0.0
        var versati = 0.0
        for a in c.anni {
            quote += a.quota
            versati += a.quota + a.contributoLavoratore + a.contributoDatore
            puntiA.append(PuntoProiezione(anno: a.anno, versato: quote, valore: a.azienda))
            puntiB.append(PuntoProiezione(anno: a.anno, versato: quote, valore: a.fondo))
            puntiC.append(PuntoProiezione(anno: a.anno, versato: versati, valore: a.fondoContributi))
        }

        // Valori preparati prima: una sola chiamata con ternari e conti dentro pesa sul controllo dei tipi
        let crescitaNominale = c.crescita * 100
        let rivalutazioneLorda = RegoleTFR.rivalutazioneLorda(inflazione: i.inflazione)
        let rivalutazioneNetta = c.rt * 100
        let rendimentoNettoFondo = c.rf * 100
        let redditoRiferimento = c.redditoRiferimento
        let tassoAlternativo = c.ra * 100
        let pareggioSolo: PareggioTFR = pareggio(i, conContributi: false)
        var pareggioConContributi: PareggioTFR?
        var puntiConContributi: [PuntoProiezione]?
        if conContributi {
            pareggioConContributi = pareggio(i, conContributi: true)
            puntiConContributi = puntiC
        }
        return EsitoTFR(ipotesi: i, anni: c.anni, quote: c.quote, quoteTotali: c.quoteTotali, tfrMaturato: c.maturato,
                        maturatoStimato: c.maturatoStimato, anniServizioTotali: c.anniServizio,
                        tassoAlternativo: tassoAlternativo, crescitaNominale: crescitaNominale,
                        rivalutazioneLorda: rivalutazioneLorda,
                        rivalutazioneNetta: rivalutazioneNetta, rendimentoNettoFondo: rendimentoNettoFondo,
                        redditoRiferimento: redditoRiferimento,
                        azienda: azienda, fondo: fondo, fondoContributi: fondoContributi,
                        versatoLavoratore: c.versatoLavoratore, versatoDatore: c.versatoDatore, dedotti: c.dedotti,
                        risparmioIrpef: c.risparmio, costoContributi: c.costoContributi,
                        pareggio: pareggioSolo, pareggioContributi: pareggioConContributi,
                        puntiAzienda: puntiA, puntiFondo: puntiB, puntiFondoContributi: puntiConContributi)
    }
}

extension IpotesiTFR {
    /// Le ipotesi di partenza dai dati del cliente:
    /// - retribuzione = `profilo.redditoDaLavoro` ?? 30.000;
    /// - crescitaReale = `profilo.lavoro?.crescitaReddito` ?? 1;
    /// - anni = (`profilo.lavoro?.etaPensione` ?? 67) − (età ?? 40), tra 1 e 50;
    /// - anniPartecipazione = il massimo di `MotoreFiscale.anniPartecipazione` delle posizioni previdenza in essere;
    /// - contributi, fondo e canale dalla posizione previdenza in essere che riceve più TFR (`tfrConferito` più alto);
    ///   senza, nessun contributo e il canale `.alleanza` se il cliente ha solo Alleanza, altrimenti `.indipendente`.
    /// I valori di ripiego (30.000 €, 40 anni, 67 anni) li segnala `Ripieghi`.
    static func dalCliente(_ c: Cliente?, posizioni: [Posizione], data: Date = Date()) -> IpotesiTFR {
        var i = IpotesiTFR()
        let profilo = c?.profilo
        let retribuzione = profilo?.redditoDaLavoro ?? RegoleTFR.retribuzionePredefinita
        i.retribuzione = retribuzione.isFinite
            ? min(max(retribuzione, Limiti.retribuzione.lowerBound), Limiti.retribuzione.upperBound)
            : RegoleTFR.retribuzionePredefinita
        let crescita = profilo?.lavoro?.crescitaReddito ?? RegoleTFR.crescitaRealePredefinita
        i.crescitaReale = crescita.isFinite
            ? min(max(crescita, Limiti.crescitaReale.lowerBound), Limiti.crescitaReale.upperBound)
            : RegoleTFR.crescitaRealePredefinita
        let etaPensione = profilo?.lavoro?.etaPensione ?? RegoleTFR.etaPensionePredefinita
        let eta = c?.dataNascita.flatMap { Calendar.current.dateComponents([.year], from: $0, to: data).year }
            ?? RegoleTFR.etaPredefinita
        i.anni = min(max(etaPensione - eta, Limiti.anni.lowerBound), Limiti.anni.upperBound)

        let previdenza = posizioni.filter { $0.stato == .inEssere && $0.regime == .previdenza }
        let partecipazione = previdenza.map { MotoreFiscale.anniPartecipazione($0, data: data) }.max() ?? 0
        i.anniPartecipazione = min(max(partecipazione, Limiti.anniPartecipazione.lowerBound),
                                   Limiti.anniPartecipazione.upperBound)

        if let p = Self.fondoConPiuTFR(previdenza) {
            func percento(_ v: Double) -> Double {
                guard i.retribuzione > 0 else { return 0 }
                let x = (v / i.retribuzione * 100 * 10).rounded() / 10
                return min(max(x, Limiti.contributo.lowerBound), Limiti.contributo.upperBound)
            }
            i.contributoLavoratore = percento(max(0, p.premioAnnuo))
            i.contributoDatore = percento(max(0, p.contributoDatore ?? 0))
            i.nomeFondo = p.nome
            i.canale = p.canale
        } else {
            i.canale = (c?.canali ?? []) == [Canale.alleanza] ? .alleanza : .indipendente
        }
        return i
    }
}

extension IpotesiTFR {
    /// La posizione previdenza in essere che riceve più TFR (a parità, la prima): non decide l'ordine delle posizioni.
    static func fondoConPiuTFR(_ posizioni: [Posizione]) -> Posizione? {
        var scelta: Posizione?
        for p in posizioni where p.stato == .inEssere && p.regime == .previdenza && (p.tfrConferito ?? 0) > 0 {
            if (p.tfrConferito ?? 0) > (scelta?.tfrConferito ?? 0) { scelta = p }
        }
        return scelta
    }

    /// I dati che mancano nel dossier e che `dalCliente` sostituisce con un valore di ripiego.
    struct Ripieghi: Equatable {
        var retribuzione = false
        var eta = false
        var etaPensione = false
        var nessuno: Bool { !retribuzione && !eta && !etaPensione }
    }

    static func ripieghi(_ c: Cliente?) -> Ripieghi {
        let profilo = c?.profilo
        return Ripieghi(retribuzione: profilo?.redditoDaLavoro == nil,
                        eta: c?.dataNascita == nil,
                        etaPensione: profilo?.lavoro?.etaPensione == nil)
    }

    /// Il tipo di lavoratore del cliente se non è dipendente (autonomo, professionista, collaboratore): il TFR
    /// non ce l'ha e il confronto non ha senso. nil se è dipendente o il tipo non è indicato.
    static func senzaTFR(_ c: Cliente?) -> TipoLavoratore? {
        guard let tipo = c?.profilo.lavoro?.tipo, tipo != .dipendente else { return nil }
        return tipo
    }
}
