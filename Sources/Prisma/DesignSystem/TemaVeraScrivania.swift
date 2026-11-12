import SwiftUI

// MARK: - Gettoni della Vera della scrivania (Shell/VeraScrivania.swift)
// Due dita da destra a sinistra sulla scrivania: i widget scorrono via e sfumano, l'acqua resta viva dietro
// e al centro si apre Vera, piccola; con domande e risposte si allarga in una conversazione.
// Sotto le risposte il quadro visivo (DesignSystem/ComponentiQuadroVera.swift): barre e cifre che contano.

extension Tema.Misura {
    enum VeraScrivania {
        // Le due pagine
        /// Quanto scorre la scrivania (in larghezze) mentre si apre Vera: una pagina intera, così segue il dito
        /// uno a uno come gli spazi del Mac; con «Riduci movimento» niente, solo dissolvenza.
        static let corsaScrivania: CGFloat = 1
        /// Da quanto lontano arriva Vera (in larghezze): dal bordo destro, attaccata alla scrivania.
        static let corsaVera: CGFloat = 1
        /// Il gesto deve muoversi di tanto (pt) prima di decidere se è orizzontale.
        static let sogliaAvvio: CGFloat = 8
        /// È orizzontale se lo spostamento in x supera di tanto quello in y.
        static let rapportoOrizzontale: CGFloat = 1.3
        /// Il trascinamento col mouse parte dopo tanti punti (i clic sui widget restano clic). La pagina parte da lì,
        /// senza scatto: lo spazio di avvio non si recupera di colpo.
        static let distanzaTrascinamento: CGFloat = 12

        // I due puntini delle pagine, sopra il dock
        static let punto: CGFloat = 6
        static let puntoAttivo: CGFloat = 18
        static let spazioPunti: CGFloat = 6
        /// L'area cliccabile attorno ai puntini.
        static let areaPunti = EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        /// Il centro dei puntini sotto il bordo della scrivania (dentro lo spazio riservato al dock).
        static let puntiSottoScrivania: CGFloat = 4

        // Il pannello
        static let larghezzaPiccola: CGFloat = 470
        static let larghezzaAllargata: CGFloat = 780
        /// Margini del pannello allargato dentro la scrivania.
        static let margineLato: CGFloat = 40
        static let margineVerticale: CGFloat = 18
        static let margineInterno = EdgeInsets(top: 18, leading: 18, bottom: 16, trailing: 18)
        static let spazio: CGFloat = 12
        static let spazioPiccolo: CGFloat = 6
        static let sferaGrande: CGFloat = 68
        static let sferaPiccola: CGFloat = 30
        static let altezzaAmbito: CGFloat = 26
        static let larghezzaAmbito: CGFloat = 220
        static let spazioMessaggi: CGFloat = 14
        static let sfumaturaMessaggi: CGFloat = 20
        /// Il quadro visivo rientra come le bolle di Vera (sfera + spazio).
        static let rientroQuadro: CGFloat = Tema.Misura.VeraChat.sferaMessaggio + Tema.Misura.VeraChat.spazioSfera
        static let larghezzaQuadro: CGFloat = 460

        // Il quadro visivo: barre
        static let margineQuadro = EdgeInsets(top: 10, leading: 12, bottom: 11, trailing: 12)
        static let spazioQuadro: CGFloat = 8
        static let altezzaBarra: CGFloat = 8
        static let spazioBarre: CGFloat = 7
        static let etichettaBarra: CGFloat = 92
        static let cifraBarra: CGFloat = 92
        /// Una barra non è mai più corta di così (si vede anche l'area più piccola).
        static let barraMinima: CGFloat = 4
    }
}

extension Tema.Raggio {
    enum VeraScrivania {
        static let pannello = Tema.Raggio.scheda
        static let quadro = Tema.Raggio.MiniVera.lineaTempo
    }
}

extension Tema.Colore {
    enum VeraScrivania {
        /// Lo sfondo «in trasparenza» con Vera aperta: un velo leggero sopra l'acqua, che continua a muoversi.
        static let velo = Color.black.opacity(0.12)
        static let puntoAttivo = Tema.Colore.inchiostroSfondo
        static let puntoSpento = Tema.Colore.inchiostroSfondoSecondario.opacity(0.5)
        static let testo = Tema.Colore.VeraChat.testo
        static let testoSecondario = Tema.Colore.VeraChat.testoSecondario
        static let testoTerziario = Tema.Colore.VeraChat.testoTerziario
        static let nonPronto = Tema.Colore.VeraChat.nonPronto
        // Il quadro visivo, come la linea del tempo della mini Vera
        static let schedaQuadro = Tema.Colore.MiniVera.scheda
        static let bordoQuadro = Tema.Colore.MiniVera.bordoScheda
        static let binarioBarra = Tema.Colore.pozzetto

        /// Il colore di una barra: il canale (blu Alleanza, cuoio indipendente) o l'area.
        static func tinta(_ t: QuadroVera.Tinta) -> Color {
            switch t {
            case .canale(let c): return Tema.Colore.canale(c)
            case .area(let a): return Colori.Analisi.area(a)
            }
        }
    }
}

extension Tema.Testo {
    enum VeraScrivania {
        static let saluto = Tema.Testo.sf(20, .bold)
        static let spaziaturaSaluto = Tema.Testo.spaziatura(-0.015, 20)
        static let sottotitolo = Tema.Testo.sf(13)
        static let titolo = Tema.Testo.sf(13, .semibold)
        static let nota = Tema.Testo.sf(11.5)
        static let titoloQuadro = Tema.Testo.MiniVera.occhiello
        static let spaziaturaTitoloQuadro = Tema.Testo.MiniVera.spaziaturaOcchiello
        static let totaleQuadro = Tema.Testo.MiniVera.totale
        static let etichettaBarra = Tema.Testo.sf(12, .medium)
        static let cifraBarra = Tema.Testo.sf(12, .semibold)
    }
}

extension Tema.Moto {
    enum VeraScrivania {
        /// Il passaggio tra le pagine: molla senza rimbalzo, con la velocità del gesto.
        static func pagina(velocita: Double = 0) -> Animation {
            Tema.Moto.conMolla(risposta: 0.3, smorzamento: 1, velocita: velocita)
        }
        static let durataPagina: Double = 0.32
        /// Al rilascio si cambia pagina oltre metà corsa, oppure con un colpo più veloce di così (pagine al secondo).
        static let sogliaPagina: CGFloat = 0.5
        static let velocitaColpo: CGFloat = 0.5
        /// La velocità del dito si misura sugli ultimi tanti secondi del gesto.
        static let finestraVelocita: Double = 0.1
        /// Il pannello che si allarga: la stessa molla della mini Vera (da capsula a scheda).
        static let forma = Tema.Moto.MiniVera.forma
        /// Le barre del quadro crescono una dopo l'altra (la molla delle aste della mini Vera).
        static let barra = Tema.Moto.MiniVera.asta
        static let ritardoBarre: Double = 0.2
        static let passoBarra: Double = 0.12
        /// Le cifre contano fino al valore.
        static let conteggio = Animation.easeOut(duration: 0.9)
    }
}
