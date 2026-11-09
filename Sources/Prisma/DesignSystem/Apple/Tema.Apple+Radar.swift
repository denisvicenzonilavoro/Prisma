import SwiftUI

// Posizioni › Radar (Design/template-luce-specifica.md §8.3.2-§8.3.3, «Luce» giro 2): misure, colori, caratteri e tempi
// del radar del portafoglio. Le viste stanno in Shell/RadarPortafoglio.swift; qui solo i valori.
// Il radar è scuro anche nell'aspetto chiaro (come la sala della presentazione, decisione 129): i suoi colori sono fissi.
// Colori delle classi: quelli della composizione di Analisi 360 (decisione 119), così la stessa classe ha lo stesso
// colore in tutta Prisma.

extension Tema.Apple.Posizioni {
    enum Radar {
        typealias C = Tema.Apple.Colore
        typealias K = Tema.Apple.Carattere

        // MARK: Fondo e geometria

        /// Radiale 600×420 al 50%/52% da #11283A a #081521, bordo bianco 6%: uguale in chiaro e scuro.
        static let fondoCentro = Color(hex: "#11283A")
        static let fondoBordo = Color(hex: "#081521")
        static let centroFondo = UnitPoint(x: 0.5, y: 0.52)
        static let raggioFondo: CGFloat = 520
        static let bordo = Color.white.opacity(0.06)
        static let raggioCard = Tema.Apple.Raggio.card
        /// R 260 su 654 di altezza: il raggio grande è 0,40 del lato del radar.
        static let quotaRaggio: CGFloat = 0.40
        /// 15 punti di distanza al bordo del cerchio grande; cerchi a 10 e 15; tolleranza disegnata dove vale.
        static let scalaPunti: Double = 15
        static let anelli: [Double] = [10, 15]
        /// Il radar non scende sotto questo lato (sotto, la colonna va sotto il radar).
        static let latoMinimo: CGFloat = 420

        // MARK: Fili e scritte

        static let filo = Color.white.opacity(0.08)
        static let spessoreFilo: CGFloat = 1
        static let scrittaCerchio = K(dimensione: 11, peso: .regular, tabellare: true)
        static let coloreScrittaCerchio = Color.white.opacity(0.40)
        /// Colore nuovo per la tolleranza (non c'è in TemaApple.swift): riempimento 6%, bordo 60% tratteggio 4 6.
        static let verdeRadar = Color(hex: "#34D399")
        static let riempimentoTolleranza = verdeRadar.opacity(0.06)
        static let bordoTolleranza = verdeRadar.opacity(0.60)
        static let tratteggioTolleranza: [CGFloat] = [4, 6]
        static let scrittaTolleranza = verdeRadar.opacity(0.85)
        static let nomeModello = K(dimensione: 13, peso: .bold, tracking: 0.4, maiuscolo: true)
        /// I nomi dei modelli stanno 24 fuori dal cerchio grande.
        static let distanzaNome: CGFloat = 24

        // MARK: Fascio

        static let ampiezzaFascio: Double = 0.55
        static let fascioFine = verdeRadar.opacity(0.28)
        static let bordoFascio = verdeRadar.opacity(0.70)
        static let spessoreBordoFascio: CGFloat = 1.5
        /// Nelle istantanee e con «Riduci movimento» il fascio sta fermo sopra il primo settore (−30°).
        static let angoloFermo: Double = -30

        // MARK: Punti

        /// Con iniziali: raggio 15, bordo bianco 70% da 2, iniziali 11 pt bold, nome 11,5 pt 600 bianco 85% sotto.
        static let puntoGrande: CGFloat = 15
        static let bordoPuntoGrande = Color.white.opacity(0.70)
        static let spessoreBordoGrande: CGFloat = 2
        static let iniziali = K(dimensione: 11, peso: .bold)
        static let nomePunto = K(dimensione: 11.5, peso: .semibold)
        static let coloreNomePunto = Color.white.opacity(0.85)
        static let sottoNome: CGFloat = 32
        /// Senza iniziali: raggio 7, #9FB3C2 → #6B8199, bordo 1.
        static let puntoPiccolo: CGFloat = 7
        static let puntoPiccoloAlto = Color(hex: "#9FB3C2")
        static let puntoPiccoloBasso = Color(hex: "#6B8199")
        static let bordoPuntoPiccolo = Color.white.opacity(0.35)
        /// Oltre questo numero di clienti fuori tolleranza gli avatar diventano pallini (200 clienti: si legge ancora).
        static let massimoAvatar = 24
        /// Composizione stimata: punto vuoto, solo il bordo.
        static let spessoreBordoStimato: CGFloat = 1.5
        /// Colore nuovo per l'anello fuori tolleranza: #FF9F0A (diverso da `Colore.arancio`, va sul fondo scuro).
        static let arancioRadar = Color(hex: "#FF9F0A")
        static let spessoreAnello: CGFloat = 2
        static let anelloGrande: CGFloat = 22
        static let anelloPiccolo: CGFloat = 14
        /// Il punto scelto con Tab (§8.3.4 «Tastiera»): anello bianco pieno 2,5 a 27 dal centro, attorno a quello arancio.
        static let anelloTastiera: CGFloat = 27
        static let spessoreAnelloTastiera: CGFloat = 2.5
        static let coloreAnelloTastiera = Color.white.opacity(0.9)
        /// «Proposta pronta» (decisione 2): anello tratteggiato verde e un trattino verso dove andrebbe il punto.
        static let tratteggioProposta: [CGFloat] = [3, 3]
        static let anelloProposta = verdeRadar
        static let trattinoProposta = verdeRadar.opacity(0.75)
        static let tratteggioTrattino: [CGFloat] = [2, 4]
        static let puntoProposta: CGFloat = 4
        /// Il punto sotto il puntatore cresce un poco.
        static let scalaSopra: CGFloat = 1.18
        /// Distanza minima per il clic su un punto.
        static let tolleranzaClic: CGFloat = 16

        // MARK: Colori dei modelli e delle classi

        static func colore(_ c: ColoreModello) -> Color {
            switch c {
            case .verde: return C.Area.liquidita        // #30B15C
            case .blu: return C.Area.investimenti       // #0A84FF
            case .viola: return C.stima                 // #8B5CF6
            case .arancio: return arancioRadar
            case .rosso: return C.rosso
            case .azzurro: return C.Composizione.obbligazionario
            }
        }

        static func colore(_ c: ComposizioneInvestimenti360.Classe) -> Color {
            switch c {
            case .azionario: return C.Composizione.azionario
            case .obbligazionario: return C.Composizione.obbligazionario
            case .gestioneSeparata: return C.Composizione.gestioneSeparata
            case .liquidita: return C.Composizione.liquidita
            }
        }

        // MARK: Colonna destra

        enum Colonna {
            /// Radar 820 : colonna 604 a finestra piena; spazio 16.
            static let quotaRadar: CGFloat = 820
            static let quotaColonna: CGFloat = 604
            static let larghezzaMinima: CGFloat = 340
            static let spazio: CGFloat = 16
            static let padding = Tema.Apple.Misura.Padding.cardMedia
            static let nomeModello = K(dimensione: 13.5, peso: .bold)
            static let pesi = Tema.Apple.Carattere.secondario
            /// Barre dei modelli: alte 9, raggio 6, spazio 2.
            static let altezzaBarra: CGFloat = 9
            static let raggioBarra: CGFloat = 6
            static let spazioBarra: CGFloat = 2
            static let sottoNome: CGFloat = 5
            static let fraModelli: CGFloat = 14
            static let fuori = K(dimensione: 40, peso: .bold, tracking: -1.2, tabellare: true)
            static let totale = K(dimensione: 22, peso: .bold, tracking: -0.4, tabellare: true)
            static let coloreFuori = C.arancio
            static let coloreTutti = C.verde
            static let spazioPulsante: CGFloat = 16
            static let avatarLontani: CGFloat = 28
            static let barraLontani = CGSize(width: 110, height: 6)
            static let colonnaDistanza: CGFloat = 62
            static let rigaLontani = EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
            static let distanzaLontani = K(dimensione: 13.5, peso: .bold, tabellare: true)
        }

        // MARK: Impostazioni › Portafogli modello

        enum Impostazioni {
            static let campoNome: CGFloat = 180
            static let sceltaColore: CGFloat = 130
            static let sceltaModello: CGFloat = 200
        }

        // MARK: Dettaglio

        enum Dettaglio {
            static let misura = CGSize(width: 880, height: 500)
            static let avatar = Tema.Apple.Misura.Avatar.grande
            static let nome = K(dimensione: 26, peso: .bold, tracking: -0.5)
            static let distanza = Tema.Apple.Carattere.valore
            /// 56 dal bordo destro per lasciare il ✕.
            static let margineChiudi: CGFloat = 56
            static let sopraRighe: CGFloat = 24
            static let spazioRighe: CGFloat = 12
            static let colonnaClasse: CGFloat = 150
            static let colonnaValori: CGFloat = 110
            static let binario: CGFloat = 16
            static let raggioBinario: CGFloat = 8
            static let lineaModello: CGFloat = 2
            static let sporgenza: CGFloat = 4
            static let coloreLinea = C.inchiostro
        }

        // MARK: Movimento (§8.3.3)

        enum Moto {
            /// I punti compaiono in 0,50 s, dopo 0,20 + k·0,045 s (k limitato a 24 con molti clienti).
            static let durataPunti = 0.50
            static let ritardoPunti = 0.20
            static let passoPunti = 0.045
            static let passiMassimi = 24
            static func ritardo(_ k: Int) -> Double { ritardoPunti + Double(min(k, passiMassimi)) * passoPunti }
            /// Il fascio gira in 4,5 s, lineare, all'infinito.
            static let giroFascio = 4.5
            static var animazioneFascio: Animation { .linear(duration: giroFascio).repeatForever(autoreverses: false) }
            /// Gli anelli fuori tolleranza pulsano in 1,9 s: da scala 0,75 opacità 0,95 a scala 1,7 opacità 0.
            static let durataPulso = 1.90
            static let scalaPulsoDa: CGFloat = 0.75
            static let scalaPulsoA: CGFloat = 1.7
            static let opacitaPulso = 0.95
            static var animazionePulso: Animation {
                Tema.Apple.Moto.Curva.easeOut.animazione(durataPulso).repeatForever(autoreverses: false)
            }
            /// Il punto sotto il puntatore cresce in 0,2 s.
            static var animazioneSopra: Animation { Tema.Apple.Moto.Curva.uscita.animazione(0.20) }
            /// «Riequilibra»: il segno della proposta entra con la molla di `cubic-bezier(.34,1.2,.5,1)` in 1,6 s, gli
            /// avvisi arrivano a 1,7 s.
            static let curvaRiequilibrio = Tema.Apple.Moto.Curva(x1: 0.34, y1: 1.2, x2: 0.5, y2: 1)
            static let durataRiequilibrio = 1.60
            static var animazioneRiequilibrio: Animation { curvaRiequilibrio.animazione(durataRiequilibrio) }
            static let esitoRiequilibrio = 1.70
            /// Entrata delle card della colonna (dentro l'app, da 0).
            static let baseCascata = Tema.Apple.Moto.Cascata.baseDentroApp
        }
    }
}
