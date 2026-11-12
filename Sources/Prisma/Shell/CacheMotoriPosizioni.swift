import Foundation

/// L'incidenza dei costi come nel KID di ogni posizione del dossier Posizioni (la coerenza con il profilo
/// sta in DerivatiDati, per versione dei dati). Si ricalcola solo quando cambiano la posizione, la sua scheda
/// del catalogo o il giorno: la vista si ridisegna spesso. Si usa solo dalle schermate (mai dai calcoli che legge Vera).
enum CacheMotoriPosizioni {
    /// Una voce per posizione, non una per elenco: tornando a un cliente già visto (A → B → A) non si rifà nulla, e a
    /// ogni disegno si confrontano le posizioni (gli array non toccati condividono la memoria) invece di fare l'impronta
    /// di tutte le posizioni e di tutto il catalogo.
    private struct Voce {
        let posizione: Posizione
        let prodotto: Prodotto?
        let valore: IncidenzaCostiKID?
    }

    nonisolated(unsafe) private static var voci: [String: Voce] = [:]
    /// Il giorno delle voci: con un giorno nuovo si rifanno tutte (l'incidenza guarda gli anni da oggi).
    nonisolated(unsafe) private static var giorno: Date = .distantPast
    /// Quante posizioni tiene al massimo (oltre, si svuota: la memoria resta piccola anche con molti clienti).
    private static let vociMassime = 512

    /// L'incidenza annua dei costi come nel KID (RIY) per ogni posizione che la ha, per id della posizione.
    static func incidenze(_ posizioni: [Posizione], prodotti: [Prodotto]) -> [String: IncidenzaCostiKID] {
        let oggi = Calendar.current.startOfDay(for: Date())
        if oggi != giorno || voci.count > vociMassime {
            voci = [:]
            giorno = oggi
        }
        var valore: [String: IncidenzaCostiKID] = [:]
        for p in posizioni {
            let scheda: Prodotto? = p.prodottoId.flatMap { id in prodotti.first { $0.id == id } }
            let incidenza: IncidenzaCostiKID?
            if let v = voci[p.id], v.posizione == p, v.prodotto == scheda {
                incidenza = v.valore
            } else {
                incidenza = MotoreCosti.incidenzaKID(p, prodotto: scheda)
                voci[p.id] = Voce(posizione: p, prodotto: scheda, valore: incidenza)
            }
            if let incidenza { valore[p.id] = incidenza }
        }
        return valore
    }
}
