import SwiftUI

// Gettoni della fase 3 di Vera (Design/template-vera.html: «Le promesse», «La seconda lettura», «Trova le differenze»,
// «Cosa non copre», «Il resoconto dell'incontro»), coerenti con le schede della fase 2: righe a semaforo (`.sev`) con
// la pillola dello stato, i numeri degli avvisi nel cerchio colorato, la tabella del confronto con la pillola
// dell'esito, i quattro riquadri dei limiti con il filo colorato in alto, il resoconto come foglio con le sezioni.

extension Tema.Apple {
    enum FaseTreVera {
        // MARK: Semaforo (rosso, arancio, verde, blu: gli stessi del template)

        static let rosso = Colore.rosso
        static let arancio = Colore.arancio
        static let verde = Colore.verde
        static let blu = Colore.accento
        static let neutro = Colore.inchiostro2
        static func fondo(_ c: Color) -> Color { c.opacity(0.13) }

        // MARK: Righe e pillole

        static let spazioRighe: CGFloat = 8
        static let paddingRiga = Misura.padding(10, 12)
        static let titoloRiga = Carattere(dimensione: 13.5, peso: .semibold)
        static let dettaglioRiga = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.4)
        static let coloreDettaglio = Colore.inchiostro2
        static let pillola = Carattere(dimensione: 11.5, peso: .semibold)
        static let paddingPillola = Misura.padding(3, 9)
        static let filoRiga: CGFloat = 3
        static let avatar: CGFloat = 30
        static let sopraScheda: CGFloat = 10
        static let nota = Carattere(dimensione: 12, peso: .regular)

        // MARK: La seconda lettura

        static let cerchioNumero: CGFloat = 20
        static let numero = Carattere(dimensione: 11.5, peso: .heavy)
        static let larghezzaFoglio: CGFloat = 520
        static let paddingFoglio: CGFloat = 20
        static let titoloFoglio = Carattere(dimensione: 17, peso: .bold)
        static let motivazione = Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.5)
        static let etichettaVera = Colore.rosso

        // MARK: Trova le differenze

        static let intestazioneTabella = Carattere(dimensione: 11.5, peso: .semibold)
        static let cellaVoce = Carattere(dimensione: 13, peso: .semibold)
        static let cella = Carattere(dimensione: 13, peso: .regular)
        static let paddingCella = Misura.padding(7, 8)
        static let colonnaEsito: CGFloat = 92

        // MARK: Cosa non copre

        static let spessoreFiloLimite: CGFloat = 4
        static let titoloLimite = Carattere(dimensione: 14.5, peso: .bold)
        static let voceLimite = Carattere(dimensione: 13, peso: .regular, interlinea: 1.4)
        static let paddingLimite = Misura.padding(12, 14)
        static let colonneLimiti: CGFloat = 230

        // MARK: Il resoconto

        static let occhiello = Carattere(dimensione: 11, peso: .semibold)
        static let titoloResoconto = Carattere(dimensione: 16, peso: .bold)
        static let sezioneResoconto = Carattere.etichetta
        static let rigaResoconto = Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.45)
        static let paddingResoconto: CGFloat = 16
        static let spazioSezioniResoconto: CGFloat = 10
        static let tastoTogli: CGFloat = 18
    }
}
