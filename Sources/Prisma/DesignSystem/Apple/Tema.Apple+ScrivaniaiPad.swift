import SwiftUI

// La scrivania del tema Apple sull'iPad (Design/template-apple-specifica.md §3.6 e §5.1): gli stessi riquadri del
// Mac (Shell/ScrivaniaApple.swift) fra la barra e il dock. Da 1100 punti di larghezza in su la disposizione del
// Mac; sotto (l'iPad in verticale) tre righe a due colonne. Qui solo i valori; le viste in iOS/ScrivaniaiPad.swift.

extension Tema.Apple.Scrivania {
    enum iPad {
        /// Sotto questa larghezza della scrivania i riquadri vanno su due colonne (@media 1100 del tema).
        static let sogliaDueColonne: CGFloat = 1100
        /// Riga alta a due colonne: Agenda di oggi e Portafoglio clienti, nelle quote del Mac (560 / 384).
        static let quoteRigaAlta: [CGFloat] = [560, 384]
        /// Riga di mezzo: Vera e Da fare oggi, larghi uguali.
        static let quoteRigaMedia: [CGFloat] = [1, 1]
        /// Altezza della riga di mezzo (in proporzione con la riga alta, 300, e la bassa, 168), e la minima.
        static let rigaMedia: CGFloat = 270
        static let rigaMediaMinima: CGFloat = 200
        /// Sotto queste altezze la scrivania scorre invece di schiacciare i riquadri (largo e stretto).
        static let altezzaMinimaLarga: CGFloat = 640
        static let altezzaMinimaStretta: CGFloat = 900
    }
}

extension Tema.Apple {
    /// Le app aperte sull'iPad (iOS/AppAperteiPad.swift): il pannello come la finestra del tema, le schede come `tile`.
    enum AppAperte {
        /// Sta sopra la scrivania: senza sfocatura (istantanee) coprente.
        static let superficie = Superficie.finestraSopra
        static let raggio: CGFloat = Raggio.finestra
        static let titolo = Carattere.h2
        static let vuoto = Carattere.secondario
        static let nome = Carattere.titoloRiga
        static let contesto = Carattere.secondario
        static let stato = Carattere.secondario
        static let coloreTitolo = Colore.inchiostro
        static let coloreContesto = Colore.inchiostro2
        static let coloreStato = Colore.inchiostro3
        /// La scheda dell'app nella finestra: il filo blu (2) e il fondo della selezione.
        static let schedaSuperficie = Superficie.tile
        static let raggioScheda: CGFloat = Raggio.tile
        static let filoDavanti = Colore.accento
        static let spessoreFiloDavanti: CGFloat = 2
        static let fondoDavanti = Colore.selezioneVoce
    }
}

extension Tema.Apple.Prospetti.Anteprima {
    /// Sull'iPad la carta si sfoglia col dito: il gesto parte dopo 24 punti e gira la pagina oltre i 60.
    static let distanzaSfoglia: CGFloat = 24
    static let sogliaSfoglia: CGFloat = 60
}
