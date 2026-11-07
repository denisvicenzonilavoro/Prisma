import SwiftUI

// Gettoni dei simulatori dal vivo di Previdenza e Protezione di Analisi 360 (Design/template-apple-specifica.md
// §4.3.2, §4.3.3; riferimenti analisi-agenda A06-A16): il dettaglio 940×540 nato dall'area, con `.lbl` nel colore
// dell'area e il titolo 28, l'anello 210/20 con la percentuale 42, le cifre `.k`/`.v`, il versamento (o il
// capitale) 44 bold nel colore con il cursore, i risultati, le ipotesi scritte sotto e il piede. Le viste stanno in
// Shell/SimulatorePrevidenzaApple.swift e Shell/SimulatoreProtezioneApple.swift; i calcoli in
// Motori/MotoreSimulatoriAnalisi.swift.

extension Tema.Apple {
    enum SimulatoriAnalisi {
        static let misura = Tema.Apple.Misura.DettaglioAperto.previdenzaProtezione

        // MARK: Testata: `.lbl` nel colore e titolo 28 bold (−0,6)

        static let etichetta = Tema.Apple.Carattere.etichetta
        static let titolo = Tema.Apple.Carattere.titoloDettaglio(28)
        static let coloreTitolo = Tema.Apple.Colore.inchiostro
        static let spazioTestata: CGFloat = 2
        /// Lo spazio del ✕ del dettaglio, in alto a destra.
        static let margineChiudi: CGFloat = Tema.Apple.Misura.Padding.chiudiDettaglio * 2

        // MARK: Corpo: anello e colonna a 34, a 20 sotto il titolo

        static let sopraCorpo: CGFloat = 20
        static let spazioAnello: CGFloat = 34
        static let anello: CGFloat = 210
        static let spessoreAnello: CGFloat = 20
        static let centroAnello = Tema.Apple.Carattere.centroAnello(42)
        static let coloreCentro = Tema.Apple.Colore.inchiostro
        /// «del divario», «protetto» sotto la percentuale (`.k`).
        static let sottoCentro = Tema.Apple.Carattere.secondario
        static let coloreSottoCentro = Tema.Apple.Colore.inchiostro2

        // MARK: Cifre (`.k` 12,5 e `.v` 26 bold) a 30 l'una dall'altra

        static let spazioCifre: CGFloat = 30
        static let spazioEtichettaValore: CGFloat = 2
        static let etichettaCifra = Tema.Apple.Carattere.secondario
        static let coloreEtichetta = Tema.Apple.Colore.inchiostro2
        static let valoreCifra = Tema.Apple.Carattere.valore
        static let coloreValore = Tema.Apple.Colore.inchiostro
        /// Il risparmio fiscale (verde).
        static let colorePositivo = Tema.Apple.Colore.verde
        /// Una cifra che non si può calcolare dai dati.
        static let senzaValore = "—"

        /// «stima» accanto a un'etichetta: capsula viola chiara (il colore delle stime del tema).
        static let testoStima = Tema.Apple.Carattere(dimensione: 10.5, peso: .semibold)
        static let coloreStima = Tema.Apple.Colore.stima
        static let fondoStima = Tema.Apple.Colore.stima.opacity(0.12)
        static let paddingStima = Tema.Apple.Misura.padding(1, 7)
        static let spazioStima: CGFloat = 6

        // MARK: Cursore: etichetta 14 a 20, valore 44 bold nel colore, binario a 8

        static let sopraCursore: CGFloat = 20
        static let etichettaCursore = Tema.Apple.Carattere(dimensione: 14, peso: .regular)
        static let valoreCursore = Tema.Apple.Carattere.valoreCursoreAnalisi
        static let larghezzaCursore: CGFloat = 460
        static let spazioEtichettaCursore: CGFloat = 2
        static let margineCursore: CGFloat = 8
        /// I risultati a 8 sotto il cursore.
        static let sopraRisultati: CGFloat = 8

        // MARK: Ipotesi (sempre scritte sotto i risultati) e piede

        static let ipotesi = Tema.Apple.Carattere.secondario
        static let coloreIpotesi = Tema.Apple.Colore.inchiostro2
        static let righeIpotesi = 4
        static let sopraIpotesi: CGFloat = 16
        static let sopraPiede: CGFloat = 12
        static let spazioPiede: CGFloat = 8
        /// Fra i pulsanti e la scelta del canale della proposta.
        static let spazioCanale: CGFloat = 8
        /// «Chiedi a Vera di spiegarlo»: la domanda parte 0,7 s dopo l'apertura di Vera.
        static let ritardoDomandaVera = Tema.Apple.Moto.DomandaDaScrivania.ritardo

        // MARK: Le due aree

        enum Previdenza {
            static let colore = Tema.Apple.Colore.Area.previdenza
            /// Il cursore del versamento: da 0 a max(900; versamento per tutto il divario·1,2 arrotondato a 50;
            /// versamento di oggi), passo 10 (§4.9.9).
            static let passo: Double = 10
            static let massimoMinimo: Double = 900
            static let margineFabbisogno: Double = 1.2
            static let arrotondamento: Double = 50
        }

        enum Protezione {
            static let colore = Tema.Apple.Colore.Area.protezione
            /// Il cursore del capitale: da 0 a max(100.000; fabbisogno·1,1 arrotondato a 10.000), passo 10.000.
            static let passo: Double = 10_000
            static let massimoMinimo: Double = 100_000
            static let margineFabbisogno: Double = 1.1
        }
    }
}
