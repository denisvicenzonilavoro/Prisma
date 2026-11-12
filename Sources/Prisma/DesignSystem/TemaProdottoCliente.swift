import SwiftUI

// MARK: - Gettoni di «Il prodotto sul cliente» (Shell/ModuloProdottoSulCliente.swift)
// Il modulo in due passi: scegli il prodotto dal catalogo, scrivi i pochi dati del cliente. Stessa cornice,
// stessi campi e stessi colori dei moduli di Posizioni; qui solo le misure in più.

extension Tema.Misura {
    enum ProdottoCliente {
        /// Il modulo: come quello della posizione.
        static let modulo = Misure.Analisi.modulo
        /// Il campo di ricerca nel catalogo.
        static let ricerca: CGFloat = 300
        /// Una riga del catalogo.
        static let altezzaRiga: CGFloat = 46
        static let spazioRiga: CGFloat = 10
        static let margineRiga = EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10)
        /// Le cifre della scheda nel riquadro del prodotto scelto.
        static let spazioCifre: CGFloat = 18
        static let margineRiquadro = EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        /// Campi numerici.
        static let campoEuro: CGFloat = 120
        static let campoAnni: CGFloat = 56
        static let tendinaFrequenza: CGFloat = 160
        static let tendinaCliente: CGFloat = 320
    }
}

extension Tema.Raggio {
    enum ProdottoCliente {
        static let riga = Tema.Raggio.voceRicerca
    }
}

extension Tema.Colore {
    enum ProdottoCliente {
        static let rigaScelta = Tema.Colore.selezione
        static let riquadro = Tema.Colore.pozzetto
        static let testoSecondario = Colori.Rubrica.secondario
        static let avviso = Tema.Apple.Colore.rosso
    }
}
