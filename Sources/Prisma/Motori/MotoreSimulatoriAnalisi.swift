import Foundation

/// I simulatori dal vivo di Previdenza e Protezione di Analisi 360 (Design/template-apple-specifica.md §4.3.2,
/// §4.3.3): a ogni passo del cursore si rifanno solo i numeri che cambiano, con le stesse formule di
/// `MotoreAnalisi` (una proiezione del montante, nessuna ricerca per bisezione, nessun Monte Carlo) e con le
/// regole fiscali di `RegoleFiscali` e `DeducibilitaPrevidenza`. Le formule semplificate del template (3% composto
/// diviso 300, premio `v·0,0012·età/37`) non si usano (§4.9.17).
enum MotoreSimulatoriAnalisi {

    // MARK: - Previdenza

    /// Un passo del cursore della previdenza: il versamento mensile e ciò che ne segue.
    struct PassoPrevidenza: Equatable {
        /// Versamento mensile nei piani (quello del cursore).
        let versamento: Double
        /// Montante dei piani alla pensione, in euro di oggi.
        let montante: Double
        /// Rendita in più al mese che il montante permette negli anni di integrazione.
        let integrazione: Double
        /// Divario fra reddito desiderato e pensione pubblica, e quello che resta dopo l'integrazione.
        let divario: Double
        let divarioResiduo: Double
        /// Quota del divario coperta dai piani (0…1; 1 se non c'è divario).
        let copertura: Double
        /// Versamenti dell'anno che il cliente deduce (entro il limite, al netto dei contributi del datore).
        let deducibili: Double
        /// IRPEF risparmiata in un anno (nil se il reddito lordo del cliente non è indicato).
        let risparmioFiscale: Double?
    }

    /// Il passo della previdenza con `versamento` al mese al posto di quello delle ipotesi.
    /// - Parameters:
    ///   - datore: contributi annui del datore di lavoro (contano nel limite di deducibilità).
    ///   - reddito: reddito complessivo lordo annuo del cliente (nil o 0 = non indicato).
    static func previdenza(_ i: IpotesiPrevidenza, versamento: Double, datore: Double = 0,
                           reddito: Double?) -> PassoPrevidenza {
        var q = i
        q.versamentoMensile = max(0, versamento)
        let netto = MotoreProiezione.calcola(MotoreAnalisi.parametriPrevidenza(q)).netto
        let integrazione = netto / MotoreAnalisi.mesiDiIntegrazione(q)
        let divario = max(0, q.redditoDesiderato - q.pensionePubblica)
        let copertura = divario > 0 ? min(1, max(0, integrazione / divario)) : 1
        let fisco = DeducibilitaPrevidenza(lavoratore: q.versamentoMensile * 12, datore: max(0, datore))
        let r = reddito.flatMap { $0 > 0 ? $0 : nil }
        return PassoPrevidenza(
            versamento: q.versamentoMensile, montante: netto, integrazione: integrazione,
            divario: divario, divarioResiduo: max(0, divario - integrazione), copertura: copertura,
            deducibili: fisco.deducibili, risparmioFiscale: r.map { fisco.risparmio(reddito: $0) }
        )
    }

    // MARK: - Protezione

    /// Il costo delle coperture caso morte, per stimare il premio di un capitale in più.
    struct TariffaCasoMorte: Equatable {
        enum Fonte: Equatable {
            /// Dalle coperture del cliente (stessa persona, età vicina).
            case cliente
            /// Dalla media delle coperture in archivio (età, durata e salute diverse).
            case archivio
        }
        /// Premio annuo ogni 1.000 € di capitale assicurato.
        let perMille: Double
        /// Quante coperture fanno la media.
        let coperture: Int
        let fonte: Fonte
    }

    /// Le coperture che danno una tariffa: caso morte, in essere o in proposta aperta, non scadute, a capitale
    /// costante, con capitale e premio indicati.
    static func copertureConTariffa(_ posizioni: [Posizione]) -> [Posizione] {
        // Condizioni una per riga: un'unica espressione lunga rallenta (o blocca) il controllo dei tipi
        posizioni.filter { (p: Posizione) -> Bool in
            guard p.area == AreaPosizione.protezione, p.rischio == RischioCoperto.vita else { return false }
            guard !p.scaduta, p.capitaleDecrescente != true else { return false }
            let capitale: Double = p.capitaleAssicurato ?? 0
            guard capitale > 0, p.premioAnnuo > 0 else { return false }
            switch p.stato {
            case .inEssere:
                return true
            case .proposta:
                return p.esito != EsitoProposta.rifiutata && p.esito != EsitoProposta.accettata
            case .chiusa:
                return false
            }
        }
    }

    /// Premi annui diviso capitali (× 1.000): prima le coperture del cliente, se non ce ne sono quelle
    /// dell'archivio. nil se nessuna copertura ha capitale e premio.
    static func tariffaCasoMorte(cliente: [Posizione], archivio: [Posizione]) -> TariffaCasoMorte? {
        func media(_ elenco: [Posizione], _ fonte: TariffaCasoMorte.Fonte) -> TariffaCasoMorte? {
            let capitali = elenco.reduce(0) { $0 + ($1.capitaleAssicurato ?? 0) }
            guard !elenco.isEmpty, capitali > 0 else { return nil }
            let premi = elenco.reduce(0) { $0 + $1.premioAnnuo }
            return TariffaCasoMorte(perMille: premi / capitali * 1_000, coperture: elenco.count, fonte: fonte)
        }
        return media(copertureConTariffa(cliente), .cliente) ?? media(copertureConTariffa(archivio), .archivio)
    }

    /// Un passo del cursore della protezione: il capitale caso morte da aggiungere e ciò che ne segue.
    struct PassoProtezione: Equatable {
        let aggiunta: Double
        /// Capitale che servirebbe alla famiglia (fabbisogno) e coperture caso morte in essere.
        let fabbisogno: Double
        let giaAssicurato: Double
        /// Scoperto che resta con il capitale in più.
        let scoperto: Double
        /// Quota del fabbisogno coperta (0…1; 1 se non c'è fabbisogno).
        let copertura: Double
        /// Premio stimato del capitale in più (nil se non c'è una tariffa).
        let premioAnnuo: Double?
        var premioMensile: Double? { premioAnnuo.map { $0 / 12 } }
    }

    /// Il passo della protezione con `aggiunta` di capitale caso morte (una temporanea in più).
    static func protezione(_ e: MotoreAnalisi.EsitoProtezione, aggiunta: Double,
                           tariffa: TariffaCasoMorte?) -> PassoProtezione {
        let a = max(0, aggiunta)
        let assicurato = e.capitaleVita + a
        let copertura = e.fabbisogno > 0 ? min(1, max(0, assicurato / e.fabbisogno)) : 1
        return PassoProtezione(
            aggiunta: a, fabbisogno: e.fabbisogno, giaAssicurato: e.capitaleVita,
            scoperto: max(0, e.fabbisogno - assicurato), copertura: copertura,
            premioAnnuo: tariffa.map { a * $0.perMille / 1_000 }
        )
    }
}

extension MotoreAnalisi {
    /// I parametri della proiezione del montante della previdenza (li usano `previdenza(_:)` e il simulatore).
    static func parametriPrevidenza(_ i: IpotesiPrevidenza) -> ParametriProiezione {
        ParametriProiezione(capitaleIniziale: i.capitale, versamento: i.versamentoMensile, frequenza: .mensile,
                            anni: max(0, i.etaPensione - i.eta), rendimento: i.rendimentoReale,
                            aliquotaFiscale: 0, inflazione: 0)
    }

    /// I mesi in cui il montante integra la pensione (almeno 12).
    static func mesiDiIntegrazione(_ i: IpotesiPrevidenza) -> Double {
        Double(max(1, i.anniIntegrazione) * 12)
    }
}
