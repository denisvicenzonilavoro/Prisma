import SwiftUI

private typealias SSP = StileScelteProspetto

/// Le scelte di «Un anno insieme» in Prospetti: che cosa racconta il report e da dove vengono le cifre.
extension AppProspetti {
    var sceltaAnnoInsieme: some View {
        let voci = ["Il tuo anno in una pagina: le tre cifre, i momenti, come è andata, il prossimo anno",
                    "Cosa è successo: valori al 1° gennaio e oggi, versamenti, scelte e incontri",
                    "Gli obiettivi avvicinati, dal 1° gennaio a oggi",
                    "La protezione: coperture e rischi da completare",
                    "I mercati attraversati, con i valori registrati",
                    "Cosa ci aspetta: scadenze, il prossimo incontro, i prossimi passi"]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Report per il cliente: A4 orizzontale su carta bianca, da consegnare al riesame di fine anno. Le avvertenze sono a piè di ogni pagina.")
                .font(SSP.nota).foregroundColor(SSP.coloreNota).fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 7) {
                ForEach(voci, id: \.self) { voce in
                    HStack(alignment: .top, spacing: 7) {
                        Text("•").foregroundColor(SSP.punto)
                        Text(voce).fixedSize(horizontal: false, vertical: true)
                    }
                    .font(SSP.testo)
                    .foregroundColor(SSP.coloreTesto)
                }
            }
            Text("Valori di inizio anno dallo storico delle Posizioni (ogni controvalore aggiornato resta nello storico), incontri dall'Agenda, obiettivi dal dossier, protezione dall'Analisi 360. Nessuna cifra scritta a mano.")
                .font(SSP.nota).foregroundColor(SSP.coloreNota).fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
    }
}
