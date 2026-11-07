import Foundation

/// Le ipotesi del confronto «TFR in azienda o nel fondo» di un cliente (dalla versione 24 dell'archivio;
/// dalla 25 i campi facoltativi su rendimento netto, TFR maturato, vecchi iscritti, dipendenti e costo dei contributi).
/// Percentuali annue; importi in euro. Lettura tollerante con i limiti dei comandi della console del TFR.
/// Le ipotesi di partenza dai dati del cliente (`IpotesiTFR.dalCliente`) stanno nel motore (Motori/MotoreTFR.swift):
/// questo file resta solo dati.
struct IpotesiTFR: Codable, Equatable {
    /// Retribuzione annua utile al TFR di oggi (€): quella del contratto collettivo, di solito vicina alla RAL.
    var retribuzione: Double = 30_000
    /// Crescita della retribuzione oltre l'inflazione (% l'anno).
    var crescitaReale: Double = 1
    /// Anni con questo datore da qui alla pensione: gli anni in cui il TFR futuro matura (1–50).
    var anni: Int = 25
    /// Inflazione ipotizzata (% l'anno): rivaluta il TFR in azienda e la retribuzione.
    var inflazione: Double = IpotesiCalcolo.inflazione
    /// Rendimento annuo del fondo (%): netto di costi e imposta se `rendimentoNetto` (come lo pubblicano la COVIP
    /// e le schede dei fondi), altrimenti lordo, prima dei costi e dell'imposta del 20%.
    var rendimentoFondo: Double = RegoleTFR.rendimentoNettoPredefinito
    /// true: `rendimentoFondo` è già netto (costi, ISC e titoli di Stato non si usano). Gli archivi della
    /// versione 24 hanno il rendimento lordo: senza il campo si legge false se c'è `rendimentoFondo`.
    var rendimentoNetto = true
    /// Costi annui del fondo (ISC, %), solo con il rendimento lordo.
    var costoFondo: Double = RegoleTFR.costoFondoPredefinito
    /// Quota del fondo in titoli di Stato (0–100), per il 12,5%; nil = 20% su tutto.
    var titoliStatoFondo: Double?
    /// Contributo del lavoratore e del datore di lavoro, in % della retribuzione (0 = nessuno).
    var contributoLavoratore: Double = 0
    var contributoDatore: Double = 0
    /// Anni già maturati nella previdenza complementare (per l'aliquota 15% → 9%).
    var anniPartecipazione: Int = 0
    /// Anni di servizio già fatti con questo datore e TFR già maturato in azienda (€): entrano solo nell'aliquota
    /// della tassazione separata (il maturato resta in azienda in tutti e due i casi). nil = non indicati;
    /// con gli anni e senza il maturato Prisma lo stima (anni × quota di oggi).
    var anniServizio: Int?
    var tfrMaturato: Double?
    /// Azienda con almeno 50 dipendenti: il TFR non conferito va al Fondo di Tesoreria INPS (stesse regole).
    /// nil = non indicato (meno di 50).
    var aziendaGrande: Bool?
    /// Iscritto alla previdenza obbligatoria prima del 29 aprile 1993: può conferire solo una parte del TFR.
    var vecchioIscritto: Bool?
    /// % del TFR futuro conferita al fondo (solo per i vecchi iscritti; nil = `RegoleTFR.quotaVecchiIscritti`).
    var quotaConferita: Double?
    /// Rendimento netto annuo (%) a cui si valuta quanto costano i contributi del cliente (i soldi che resterebbero
    /// in busta paga); nil = l'inflazione (soldi messi da parte che tengono solo il passo dei prezzi).
    var tassoAlternativo: Double?
    /// Aliquota della tassazione separata del TFR indicata a mano (%); nil = calcolata da Prisma.
    var aliquotaTFR: Double?
    /// Quota della retribuzione accantonata ogni anno (%); nil = 100/13,5 − 0,5 (`RegoleTFR.quotaAnnua`).
    var quotaTFR: Double?
    /// Canale della consulenza (etichetta sullo schermo e sul PDF) e nome del fondo, se c'è.
    var canale: Canale = .indipendente
    var nomeFondo = ""

    /// Limiti dei comandi: un valore letto fuori limite si riporta al limite più vicino.
    enum Limiti {
        static let retribuzione: ClosedRange<Double> = 0...1_000_000
        static let crescitaReale: ClosedRange<Double> = -5...10
        static let anni: ClosedRange<Int> = 1...50
        static let inflazione: ClosedRange<Double> = -5...20
        static let rendimentoFondo: ClosedRange<Double> = -10...30
        static let costoFondo: ClosedRange<Double> = 0...5
        static let titoliStatoFondo: ClosedRange<Double> = 0...100
        static let contributo: ClosedRange<Double> = 0...50
        static let anniPartecipazione: ClosedRange<Int> = 0...60
        static let aliquotaTFR: ClosedRange<Double> = 0...50
        static let quotaTFR: ClosedRange<Double> = 0...10
        static let anniServizio: ClosedRange<Int> = 0...50
        static let tfrMaturato: ClosedRange<Double> = 0...2_000_000
        static let quotaConferita: ClosedRange<Double> = 0...100
        static let tassoAlternativo: ClosedRange<Double> = -5...20
    }

    /// % del TFR futuro che va al fondo: tutto, o la quota scelta dal vecchio iscritto.
    var quotaConferitaEffettiva: Double {
        guard vecchioIscritto == true else { return 100 }
        return min(max(quotaConferita ?? RegoleTFR.quotaVecchiIscritti, Limiti.quotaConferita.lowerBound),
                   Limiti.quotaConferita.upperBound)
    }

    init() {}

    private enum CodingKeys: String, CodingKey {
        case retribuzione, crescitaReale, anni, inflazione, rendimentoFondo, costoFondo, titoliStatoFondo
        case contributoLavoratore, contributoDatore, anniPartecipazione, aliquotaTFR, quotaTFR, canale, nomeFondo
        case rendimentoNetto, anniServizio, tfrMaturato, aziendaGrande, vecchioIscritto, quotaConferita, tassoAlternativo
    }

    /// Lettura tollerante: un campo illeggibile prende il predefinito, uno fuori limite il limite più vicino.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let p = IpotesiTFR()
        retribuzione = Self.limita(try? c.decodeIfPresent(Double.self, forKey: .retribuzione),
                                   Limiti.retribuzione, altrimenti: p.retribuzione)
        crescitaReale = Self.limita(try? c.decodeIfPresent(Double.self, forKey: .crescitaReale),
                                    Limiti.crescitaReale, altrimenti: p.crescitaReale)
        let anniLetti = try? c.decodeIfPresent(Int.self, forKey: .anni)
        anni = anniLetti.map { min(max($0, Limiti.anni.lowerBound), Limiti.anni.upperBound) } ?? p.anni
        inflazione = Self.limita(try? c.decodeIfPresent(Double.self, forKey: .inflazione),
                                 Limiti.inflazione, altrimenti: p.inflazione)
        rendimentoFondo = Self.limita(try? c.decodeIfPresent(Double.self, forKey: .rendimentoFondo),
                                      Limiti.rendimentoFondo, altrimenti: p.rendimentoFondo)
        costoFondo = Self.limita(try? c.decodeIfPresent(Double.self, forKey: .costoFondo),
                                 Limiti.costoFondo, altrimenti: p.costoFondo)
        titoliStatoFondo = Self.limitaFacoltativo(try? c.decodeIfPresent(Double.self, forKey: .titoliStatoFondo),
                                                  Limiti.titoliStatoFondo)
        contributoLavoratore = Self.limita(try? c.decodeIfPresent(Double.self, forKey: .contributoLavoratore),
                                           Limiti.contributo, altrimenti: p.contributoLavoratore)
        contributoDatore = Self.limita(try? c.decodeIfPresent(Double.self, forKey: .contributoDatore),
                                       Limiti.contributo, altrimenti: p.contributoDatore)
        let partecipazione = try? c.decodeIfPresent(Int.self, forKey: .anniPartecipazione)
        anniPartecipazione = partecipazione.map {
            min(max($0, Limiti.anniPartecipazione.lowerBound), Limiti.anniPartecipazione.upperBound)
        } ?? p.anniPartecipazione
        aliquotaTFR = Self.limitaFacoltativo(try? c.decodeIfPresent(Double.self, forKey: .aliquotaTFR),
                                             Limiti.aliquotaTFR)
        quotaTFR = Self.limitaFacoltativo(try? c.decodeIfPresent(Double.self, forKey: .quotaTFR),
                                          Limiti.quotaTFR)
        canale = (try? c.decodeIfPresent(Canale.self, forKey: .canale)) ?? p.canale
        nomeFondo = (try? c.decodeIfPresent(String.self, forKey: .nomeFondo)) ?? p.nomeFondo
        // Versione 25: tutti facoltativi. Senza `rendimentoNetto` un rendimento già salvato era lordo (versione 24)
        let netto = try? c.decodeIfPresent(Bool.self, forKey: .rendimentoNetto)
        rendimentoNetto = netto ?? (c.contains(.rendimentoFondo) ? false : p.rendimentoNetto)
        let servizio = try? c.decodeIfPresent(Int.self, forKey: .anniServizio)
        anniServizio = servizio.map { min(max($0, Limiti.anniServizio.lowerBound), Limiti.anniServizio.upperBound) }
        tfrMaturato = Self.limitaFacoltativo(try? c.decodeIfPresent(Double.self, forKey: .tfrMaturato), Limiti.tfrMaturato)
        aziendaGrande = (try? c.decodeIfPresent(Bool.self, forKey: .aziendaGrande))
        vecchioIscritto = (try? c.decodeIfPresent(Bool.self, forKey: .vecchioIscritto))
        quotaConferita = Self.limitaFacoltativo(try? c.decodeIfPresent(Double.self, forKey: .quotaConferita),
                                                Limiti.quotaConferita)
        tassoAlternativo = Self.limitaFacoltativo(try? c.decodeIfPresent(Double.self, forKey: .tassoAlternativo),
                                                  Limiti.tassoAlternativo)
    }

    /// Il valore letto riportato nei limiti; il predefinito se manca o non è un numero finito.
    private static func limita(_ v: Double?, _ r: ClosedRange<Double>, altrimenti predefinito: Double) -> Double {
        guard let v, v.isFinite else { return predefinito }
        return min(max(v, r.lowerBound), r.upperBound)
    }

    /// Come `limita`, per un campo facoltativo: nil se manca o non è un numero finito.
    private static func limitaFacoltativo(_ v: Double?, _ r: ClosedRange<Double>) -> Double? {
        guard let v, v.isFinite else { return nil }
        return min(max(v, r.lowerBound), r.upperBound)
    }
}
