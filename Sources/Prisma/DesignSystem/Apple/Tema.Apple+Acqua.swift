import Foundation

// «L'acqua risponde» (Design/template-apple-specifica.md §3.6 e §3.7): un clic sul fondo libero, una notifica nuova,
// Vera che parla e lo sblocco toccano l'acqua della scrivania. L'acqua resta quella di oggi (SfondoAcqua*.swift,
// la stessa fisica e lo stesso shader): qui ci sono solo i pesi delle gocce e i tempi della vibrazione.
// Il template usa un'altra simulazione (forze 32 / 90 sulla griglia d'onda): i pesi sono la traduzione nella fisica
// di Prisma, dove la pioggia ha peso 0,4…1.

extension Tema.Apple {
    enum Acqua {
        /// Le gocce che cadono dove si chiede.
        enum Goccia {
            /// Clic o tocco sul fondo libero della scrivania (template: forza 32, raggio 3): una goccia piena.
            static let pesoTocco: Float = 1.0
            /// Una notifica nuova, sulla campanella della barra: più piccola, non deve distrarre.
            static let pesoNotifica: Float = 0.7
            /// Lo sblocco (template: forza 90, raggio 6): la goccia più grande, al centro della scrivania.
            static let pesoSblocco: Float = 1.6
            /// Oltre questo peso la conca e il getto escono dalle tarature della fisica.
            static let pesoMassimo: Float = 2.0
        }

        /// L'acqua che vibra piano intorno alla sfera di Vera mentre risponde.
        enum Vibrazione {
            /// Un piccolo impatto ogni tanti secondi.
            static let intervallo: Float = 0.45
            /// Gli impatti cadono entro questo raggio dal centro della sfera (pt).
            static let raggio: Float = 12
            /// Raggio dell'impatto (pt) e pendenza dell'onda: molto meno di una goccia (4,5…6,5 e 1,1).
            static let ampiezzaImpatto: Float = 2.4
            static let pendenza: Float = 0.22
            /// Vita di ogni impatto (s): le onde si spengono presto, la superficie resta calma intorno.
            static let vita: Float = 3.5
            /// Quanto può durare una vibrazione senza essere rinnovata (s): una risposta lunga di Qwen.
            static let durataMassima: Double = 120
            /// Vibrazioni contemporanee al massimo (una per sfera).
            static let massime = 3
            /// Due vibrazioni più vicine di così (pt) sono la stessa: si allunga quella che c'è.
            static let stessoPunto: Float = 24
        }

        /// Eventi in attesa del prossimo fotogramma, al massimo (gli altri si lasciano cadere).
        static let eventiInCoda = 8
    }
}
