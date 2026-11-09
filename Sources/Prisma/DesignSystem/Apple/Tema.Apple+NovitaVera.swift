import SwiftUI

// Gettoni del pannello «Le 25 novità di Vera» (Design/template-vera.html, `#novP`): un vetro largo fino a 1200, in testa
// la sfera e il titolo con «Chiudi», sotto cinque colonne, una per gruppo, con il nome del gruppo nel suo colore e le voci
// con il numero nel pallino colorato (`.novI`, `.novN`). I cinque colori sono quelli dei gruppi del template (`GR`).

extension Tema.Apple {
    enum PannelloVeraNovita {
        static let larghezza: CGFloat = 1200
        static let bordo: CGFloat = 24
        static let padding = EdgeInsets(top: 18, leading: 20, bottom: 20, trailing: 20)
        static let raggio: CGFloat = 24
        static let superficie = Superficie.dettaglio
        static let sfera: CGFloat = 26
        static let titolo = Carattere(dimensione: 22, peso: .bold)
        static let spazioTestata: CGFloat = 10
        static let sopraGriglia: CGFloat = 12
        static let colonne = 5
        static let spazioColonne: CGFloat = 14
        static let gruppo = Carattere(dimensione: 12, peso: .bold)
        static let puntoGruppo: CGFloat = 7
        static let paddingGruppo = EdgeInsets(top: 0, leading: 8, bottom: 6, trailing: 0)
        static let voce = Carattere(dimensione: 13, peso: .semibold)
        static let paddingVoce = EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        static let raggioVoce: CGFloat = 12
        static let spazioVoce: CGFloat = 9
        static let pallino: CGFloat = 22
        static let numero = Carattere(dimensione: 11, peso: .bold)
        static let numeroColore = Color.white
        static let fondoPassaggio = Colore.chip
        static let nota = Carattere(dimensione: 12, peso: .regular)
        /// I colori dei cinque gruppi (template `GR`): fa le cose, conosce i clienti, legge e controlla, scrive come te,
        /// più intelligente.
        static let colori: [Color] = [Color(hex: "#0A84FF"), Color(hex: "#2FA35A"), Color(hex: "#E08A00"), Color(hex: "#8B5CF6"),
                                      Color(hex: "#C2264B")]
        /// Il pulsante nella testata del pannello «Le novità» e nella testata di Vera.
        static let pulsante = Carattere(dimensione: 13, peso: .semibold)
        static let colorePulsante = Color.dinamico(chiaro: Color(hex: "#C2264B"), scuro: Color(hex: "#FF5C83"))
    }
}
