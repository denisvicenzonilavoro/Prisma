import SwiftUI

// Clienti › Potenziali e Passaparola e Messaggi › Campagne («Luce» giro 12, Design/template-luce-specifica.md §9.2.2 e
// §9.4.2): misure, caratteri, colori e tempi delle colonne del percorso, delle schede, dell'albero del passaparola, della
// colonna degli ambasciatori, della mappa dei bisogni e del pannello della campagna. Le viste stanno in
// Shell/ClientiPotenziali.swift, Shell/ClientiPassaparola.swift e Shell/MessaggiCampagne.swift; qui solo i valori, tutti
// ricavati dal tema Apple.

extension Tema.Apple {
    // MARK: - Potenziali (§9.2.2)

    enum Potenziali {
        static let paddingColonna: CGFloat = 14
        static let spazioColonne: CGFloat = 12
        static let titoloColonna = Tema.Apple.Carattere(dimensione: 14, peso: .bold)
        static let contoColonna = Tema.Apple.Carattere(dimensione: 12, peso: .semibold, tabellare: true)
        static let coloreConto = Tema.Apple.Colore.inchiostro3
        static let superficieColonna = Tema.Apple.Superficie.pannello
        static let larghezzaMinimaColonna: CGFloat = 170
        static let paddingScheda: CGFloat = 12
        static let spazioSchede: CGFloat = 8
        static let raggioScheda = Tema.Apple.Raggio.voce
        static let fondoScheda = Tema.Apple.Colore.card
        static let bordoScheda = Tema.Apple.Colore.separatore
        static let nomeScheda = Tema.Apple.Carattere(dimensione: 13.5, peso: .semibold)
        static let fonteScheda = Tema.Apple.Carattere(dimensione: 11.5, peso: .regular)
        static let coloreFonte = Tema.Apple.Colore.inchiostro2
        static let cifraScheda = Tema.Apple.Carattere(dimensione: 12.5, peso: .semibold, tabellare: true)
        static let altezzaBarra: CGFloat = 5
        static let raggioBarra: CGFloat = 3
        static let binarioBarra = Tema.Apple.Colore.chip
        /// Il colore della barra della probabilità: ≥ 70 verde, ≥ 40 accento, sotto grigio.
        static let sogliaAlta = 70
        static let sogliaMedia = 40
        static func coloreBarra(_ p: Int?) -> Color {
            guard let p else { return Tema.Apple.Colore.inchiostro3 }
            if p >= sogliaAlta { return Tema.Apple.Colore.verde }
            if p >= sogliaMedia { return Tema.Apple.Colore.accento }
            return Tema.Apple.Colore.inchiostro3
        }
        /// Il segno grigio «informativa da dare».
        static let segno = Tema.Apple.Carattere(dimensione: 10.5, peso: .semibold)
        static let coloreSegno = Tema.Apple.Colore.inchiostro2
        static let fondoSegno = Tema.Apple.Colore.chip
        static let paddingSegno = Tema.Apple.Misura.padding(2, 7)
        static let nota = Tema.Apple.Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.45)
        static let coloreNota = Tema.Apple.Colore.inchiostro2
        static let spazioTile: CGFloat = 12
        static let tileValore = Tema.Apple.Carattere(dimensione: 26, peso: .bold, tracking: -0.5, tabellare: true)
        static let tileEtichetta = Tema.Apple.Carattere.etichetta
        static let tilePiccolo = Tema.Apple.Carattere(dimensione: 11.5, peso: .regular)
        static let aggiungi = Tema.Apple.Carattere(dimensione: 12.5, peso: .semibold)
        static let coloreAggiungi = Tema.Apple.Colore.accento
        static let vuoto = Tema.Apple.Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.45)
        static let margine: CGFloat = 20
        // Dettaglio e modulo
        static let titoloDettaglio = Tema.Apple.Carattere.titoloDettaglio(26)
        static let rigaDettaglio = Tema.Apple.Carattere.corpo
        static let etichettaDettaglio = Tema.Apple.Carattere.etichetta
        static let paddingDettaglio: CGFloat = 26
        static let spazioDettaglio: CGFloat = 14
        static let larghezzaDettaglio: CGFloat = 560
        static let altezzaDettaglio: CGFloat = 620
    }

    // MARK: - Passaparola (§9.2.2)

    enum Passaparola {
        static let larghezzaAlbero: CGFloat = 900
        static let larghezzaAlberoMinima: CGFloat = 640
        static let larghezzaColonnaDestra: CGFloat = 320
        static let raggioTu: CGFloat = 30
        static let xTu: CGFloat = 90
        static let xPrimo: CGFloat = 330
        static let passoPrimo: CGFloat = 120
        static let raggioBase: CGFloat = 14
        static let fattoreRaggio: CGFloat = 0.9
        static let bordoPrimo: CGFloat = 3
        static let xSecondo: CGFloat = 640
        static let xTerzo: CGFloat = 820
        static let scartoAlterno: CGFloat = 56
        static let passoSecondo: CGFloat = 52
        static let raggioBaseSecondo: CGFloat = 8
        static let fattoreSecondo: CGFloat = 0.8
        static let margineSopra: CGFloat = 36
        static let distanzaGruppi: CGFloat = 64
        /// Il raggio di un cerchio: base + √(k€) · fattore (primo livello 14 + √k · 0,9; dopo 8 + √k · 0,8).
        static func raggio(patrimonio: Double?, livello: Int) -> CGFloat {
            let k = max(0, (patrimonio ?? 0) / 1000).squareRoot()
            return livello <= 1 ? raggioBase + CGFloat(k) * fattoreRaggio : raggioBaseSecondo + CGFloat(k) * fattoreSecondo
        }
        /// Già clienti: pieno #30B15C con il legame pieno; potenziali: `chip` con il bordo `inchiostro3`, legame tratteggiato.
        static let cliente = Tema.Apple.Colore.Area.liquidita
        static let potenziale = Tema.Apple.Colore.chip
        static let bordoPotenziale = Tema.Apple.Colore.inchiostro3
        static let tratteggio: [CGFloat] = [4, 5]
        static let spessorePotenziale: CGFloat = 1.4
        static let opacitaPotenziale: Double = 0.45
        static let spessoreTronco: CGFloat = 1.6
        static let opacitaSpenta: Double = 0.30
        static let nomePrimo = Tema.Apple.Carattere(dimensione: 13, peso: .semibold)
        static let nomeSecondo = Tema.Apple.Carattere(dimensione: 11.5, peso: .medium)
        static let cifra = Tema.Apple.Carattere(dimensione: 11, peso: .regular, tabellare: true)
        static let coloreCifra = Tema.Apple.Colore.inchiostro2
        static let iniziali = Tema.Apple.Carattere(dimensione: 11, peso: .bold)
        static let somma = Tema.Apple.Carattere(dimensione: 15, peso: .bold, tabellare: true)
        static let tuAlto = Tema.Apple.Colore.avatarDVAlto
        static let tuBasso = Tema.Apple.Colore.avatarDVBasso
        static let testoTu = Tema.Apple.BarraAlta.testoSuColore
        static let bordoMomento = Tema.Apple.Colore.arancio.opacity(0.40)
        static let fondoMomento = Tema.Apple.Colore.arancio.opacity(0.06)
        static let etichettaMomento = Tema.Apple.Carta.ambra
        static let altezzaColonne: CGFloat = 96
        static let raggioColonna: CGFloat = 6
        static let raggioColonnaBasso: CGFloat = 3
        static let colonna = Tema.Apple.Colore.chip
        static let colonnaUltima = Tema.Apple.Colore.verde
        static let etichettaAnno = Tema.Apple.Carattere.asse
        static let padding: CGFloat = 20
        static let spazio: CGFloat = 14
        static let rigaAmbasciatore = Tema.Apple.Carattere(dimensione: 13, peso: .semibold)
        static let cifraAmbasciatore = Tema.Apple.Carattere(dimensione: 12, peso: .regular, tabellare: true)
        static let avvisoCiclo = Tema.Apple.Carattere(dimensione: 11.5, peso: .regular)
        static let coloreCiclo = Tema.Apple.Colore.arancio
        /// Oltre tanti nodi visibili, il resto va nei «+ N» (M1 8 GB).
        static let nodiMassimi = 80
    }

    // MARK: - Campagne (§9.4.2)

    enum Campagne {
        static let larghezzaMappa: CGFloat = 860
        static let quotaMappa: CGFloat = 0.62
        static let altezzaMappa: CGFloat = 560
        static let raggioFondo: CGFloat = 600
        static let etichettaMargine = Tema.Apple.Misura.padding(18, 22)
        static let raggioBase: CGFloat = 46
        static let raggioPerCliente: CGFloat = 7
        static let raggioMassimo: CGFloat = 120
        static let fondoGruppo: Double = 0.07
        static let tratto: Double = 0.35
        static let trattoScelto: Double = 0.9
        static let trattoAltri: Double = 0.25
        static let tratteggio: [CGFloat] = [3, 6]
        static let spessoreTratto: CGFloat = 1.5
        static let nomeGruppo = Tema.Apple.Carattere(dimensione: 13, peso: .bold)
        static let contoGruppo = Tema.Apple.Carattere(dimensione: 11.5, peso: .regular, tabellare: true)
        static let sottoCerchio: CGFloat = 20
        static let sottoNome: CGFloat = 18
        static let avatar: CGFloat = 26
        static let bordoAvatar: CGFloat = 2
        static let pallino: CGFloat = 6
        static let opacitaPallino: Double = 0.85
        static let pallinoLibero: CGFloat = 4
        static let opacitaLibero: Double = 0.4
        static let coloreLibero = Tema.Apple.Colore.inchiostro3
        static let avatarMassimi = 6
        static let etichetta = Tema.Apple.Carattere.etichetta
        static let coloreEtichetta = Tema.Apple.Colore.inchiostro2
        // Pannello
        static let larghezzaPannello: CGFloat = 400
        static let titolo = Tema.Apple.Carattere(dimensione: 23, peso: .bold, tracking: -0.4)
        static let sottotitolo = Tema.Apple.Carattere.secondario
        static let anteprima = Tema.Apple.Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.55)
        static let fondoAnteprima = Tema.Apple.Colore.chip
        static let raggioAnteprima = Tema.Apple.Raggio.voce
        static let paddingAnteprima: CGFloat = 14
        static let paddingRiga: CGFloat = 7
        static let avatarRiga: CGFloat = 28
        static let nomeRiga = Tema.Apple.Carattere(dimensione: 13, peso: .semibold)
        static let statoRiga = Tema.Apple.Carattere(dimensione: 11.5, peso: .regular)
        static let coloreStato = Tema.Apple.Colore.inchiostro2
        static let pillolaConsenso = Tema.Apple.Colore.arancio
        static let fondoPillola = Tema.Apple.Colore.arancio.opacity(0.12)
        static let pillola = Tema.Apple.Carattere(dimensione: 10.5, peso: .semibold)
        static let lampo = Tema.Apple.Colore.verde.opacity(0.12)
        static let pronta = Tema.Apple.Colore.verde
        static let marginePulsante = Tema.Apple.Misura.padding(20, 22)
        static let chip = Tema.Apple.Carattere(dimensione: 12, peso: .semibold, tabellare: true)
        static let fondoChip = Tema.Apple.Colore.chip
        static let padding: CGFloat = 20
        static let spazio: CGFloat = 12
        static let nota = Tema.Apple.Carattere(dimensione: 11.5, peso: .regular, interlinea: 1.4)
        static let coloreNota = Tema.Apple.Colore.inchiostro2

        /// Il colore di un gruppo nella mappa.
        static func tinta(_ t: TipoGruppoCampagna) -> Color {
            switch t {
            case .protezioneFamiglia: return Tema.Apple.Colore.Area.protezione
            case .scadenzaNelMese: return Tema.Apple.Colore.Area.investimenti
            case .etaTonda: return Tema.Apple.Colore.stima
            case .previdenzaFerma: return Tema.Apple.Colore.arancio
            case .previdenzaAssente: return Tema.Apple.Colore.Glifi.campagna
            case .liquiditaFerma: return Tema.Apple.Colore.Area.liquidita
            }
        }
    }
}

// MARK: - Movimento (§9.2.3, §9.4.3)

extension Tema.Apple.Moto {
    enum Potenziali {
        /// Il volo della scheda fra le colonne (`matchedGeometryEffect`) con la molla leggera.
        static var avanza: Animation { Curva.mollaLeggera.animazione(0.65) }
    }

    enum Passaparola {
        static let indiceMassimo = 12
        /// I legami pieni si tracciano in 0,9 s, con ritardo 0,2 + i·0,06.
        static let legame = 0.9
        static func ritardoLegame(_ i: Int) -> Double { 0.2 + Double(min(i, indiceMassimo)) * 0.06 }
        /// I legami tratteggiati compaiono in dissolvenza in 0,6 s.
        static let tratteggio = 0.6
        /// I nodi da scala 0,6 in 0,5 s, ritardo 0,3 + i·0,055.
        static let nodo = 0.5
        static let scalaNodo: CGFloat = 0.6
        static func ritardoNodo(_ i: Int) -> Double { 0.3 + Double(min(i, indiceMassimo)) * 0.055 }
        /// Le colonne degli anni da 0 in 0,9 s, ritardo 0,3 + i·0,08.
        static let colonna = 0.9
        static func ritardoColonna(_ i: Int) -> Double { 0.3 + Double(min(i, indiceMassimo)) * 0.08 }
        static var animazioneLegame: Animation { Curva.uscita.animazione(legame) }
        static var animazioneNodo: Animation { Curva.molla.animazione(nodo) }
        static var animazioneColonna: Animation { Curva.uscita.animazione(colonna) }
    }

    enum Campagne {
        /// I pallini aspettano 0,7 s, poi si radunano nei gruppi in 1,6 s.
        static let attesa = 0.7
        static var raduno: Animation { Curva.raduno.animazione(1.6) }
        static var gruppi: Animation { Curva.ease.animazione(0.8) }
        static var scelta: Animation { Curva.ease.animazione(0.25) }
        static let lampo = 0.9
        /// Le righe diventano «✓ bozza pronta» una dopo l'altra (passo).
        static let passoBozze = 0.12
    }
}
