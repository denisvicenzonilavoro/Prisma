import SwiftUI

// Gettoni dei controlli del tema Apple: segmentato a pillola, interruttore, cursore, toast, pulsanti ed
// etichetta del canale (Design/template-apple-specifica.md §2.8-§2.10, §2.15-§2.17).
// I componenti stanno in ControlliApple.swift e PulsantiApple.swift. I tempi sono in TemaAppleMoto.swift
// (`Segmentato`, `Interruttore`, `PulsantePremuto`, `Toast`); qui solo ciò che lì manca.

extension Tema.Apple {
    /// Gettoni propri dei controlli (raccolti qui per non scontrarsi con gli altri gruppi del tema).
    enum Controlli {
        /// Manopole dell'interruttore e del cursore: bianche anche nell'aspetto scuro.
        static let manopola = Color.white
        /// Controllo disattivato: opacità dell'insieme (il template non ne ha; scelta del porting).
        static let opacitaDisattivato: Double = 0.4

        /// `.seg` (§2.8).
        enum Segmentato {
            /// Voce con l'avatar (clienti di Analisi 360): `padding: 4px 12px 4px 4px`.
            static let paddingVoceIcona = EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 12)
            /// Spazio fra l'avatar e il nome (`gap: 6px`).
            static let spazioIcona: CGFloat = 6
            /// Lato dell'avatar nella voce (`avatar(c, 24)`).
            static let latoIcona: CGFloat = Misura.Avatar.minimo
        }

        /// `.sw` (§2.9).
        enum Interruttore {
            /// Spazio minimo fra l'etichetta e l'interruttore spinto a destra.
            static let spazioEtichetta: CGFloat = 12
        }

        /// `input[type=range]` (§2.10).
        enum Cursore {
            /// Spazio fra il valore mostrato e il binario (`margin: 10px 0 6px`).
            static let spazioValore: CGFloat = 10
        }

        /// `#toast` (§2.15).
        enum Toast {
            /// Dall'alto della scena: 10 sotto la barra superiore da 34.
            static let dallAlto: CGFloat = 44
            static let padding = Misura.padding(9, 16)
            /// `font-size: 13px`, peso del corpo (normale).
            static let carattere = Carattere(dimensione: 13, peso: .regular)
        }

        /// `.btn` (§2.16).
        enum Pulsante {
            /// Spazio fra icona e testo (`gap: 6px`).
            static let spazio: CGFloat = 6
            /// Testo della variante principale.
            static let testoPrincipale = Color.white
        }

        /// `.chA` / `.chI` (§2.17).
        enum Etichetta {
            /// Altezza del simbolo Alleanza al posto del pallino (allineato al carattere 11,5).
            static let simboloAlleanza: CGFloat = 11
        }
    }
}

// MARK: - Superfici dei pulsanti

extension Tema.Apple.Superficie {
    /// `.btn.glass`: pulsanti della scrivania (Nuovo cliente, Cerca ovunque). È il vetro del tema con il bordo
    /// `separatore` del pulsante (nel CSS `.btn` viene dopo `.glass` e ne sostituisce il bordo).
    /// Il raggio va dato a metà dell'altezza del pulsante (capsula).
    static let pulsanteVetro = Tema.Apple.Superficie(
        riempimento: vetro.riempimento, sfocatura: vetro.sfocatura, saturazione: vetro.saturazione,
        bordo: Tema.Apple.Colore.separatore, spessoreBordo: Tema.Apple.Misura.bordo, ombra: .vetro,
        raggio: Tema.Apple.Raggio.pillola, filoInterno: true)
}
