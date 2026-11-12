import Foundation

// Ciò che Studio chiede allo stato: il cruscotto calcolato da MotoreStudio, tenuto da parte in DerivatiDati finché non
// cambiano i dati dei calcoli (comprese le impostazioni di Studio), il giorno o la modalità cliente.

extension StatoShell {
    /// I ricavi della consulenza indipendente per Studio, dalle parcelle dell'archivio (giro 2): le pagate alla data
    /// d'incasso e le emesse alla scadenza, con l'imponibile delle righe (`MotoreParcelle.ricaviConsulenza`). Bozze e
    /// annullate non contano. In modalità cliente solo le sue (`parcelle`). Le parcelle entrano nei calcoli: si tengono da
    /// parte con `ricavato` finché non cambiano (il riquadro della scrivania li chiede a ogni disegno).
    var ricaviConsulenzaStudio: [RicavoConsulenza] {
        ricavato("studio.ricavi") { () -> [RicavoConsulenza] in MotoreParcelle.ricaviConsulenza(parcelle) }
    }

    /// Il cruscotto di Studio dei clienti visibili (in modalità cliente solo il suo). Per oggi viene dalla cache
    /// (DerivatiDati); per un altro giorno si calcola.
    func cruscottoStudio(oggi: Date = Date()) -> CruscottoStudio {
        let calcola = {
            MotoreStudio.calcola(clienti: self.clienti, posizioni: self.posizioni, appuntamenti: self.appuntamenti,
                                 incontri: self.dati.incontri, studio: self.dati.impostazioni.studio,
                                 parcelle: self.ricaviConsulenzaStudio, oggi: oggi)
        }
        guard Calendar.current.isDateInToday(oggi) else { return calcola() }
        let d = derivatiValidi()
        if let c = d.cruscottoStudio { return c }
        let v = calcola()
        d.cruscottoStudio = v
        return v
    }
}
