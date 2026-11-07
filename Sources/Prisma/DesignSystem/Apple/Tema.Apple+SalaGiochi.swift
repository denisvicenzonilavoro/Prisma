import SwiftUI

// Gettoni delle esperienze «giochi» della Sala (Design/template-luce-specifica.md §4, «Luce» giro 4): il gioco del
// rischio (§4.1.2, §4.1.3) e una giornata della pensione (§4.2.2, §4.2.3). Misure in pt del palco 1440×900, tempi in
// secondi. Le tinte delle scene della giornata stanno con gli altri glifi (`Tema.Apple.Colore.Glifi`), qui sotto.

extension Tema.Apple.SalaEsperienze {
    // MARK: - Il gioco del rischio (§4.1.2)

    enum Rischio {
        typealias C = Tema.Apple.Carattere
        typealias K = Tema.Apple.Colore

        /// La scatola del gioco: padding 26 / 30.
        static let padding = EdgeInsets(top: 26, leading: 30, bottom: 26, trailing: 30)
        /// «SCENARIO 1 DI 3» `.lbl` rosso (il colore del tassello); l'avvertenza `.k` a destra.
        static let etichetta = C.etichetta
        static let coloreEtichetta = K.rosso
        static let avvertenza = C.secondario
        static let coloreAvvertenza = K.inchiostro2
        /// «Testi di prova»: la stessa capsula arancio delle altre etichette di prova.
        static let prova = Tema.Apple.Studio.Card.prova
        static let coloreProva = Tema.Apple.Studio.Card.coloreProva
        /// La domanda: 27 bold −0,5 interlinea 1,25, 12 sopra e 10 sotto, larga al più 900.
        static let domanda = C(dimensione: 27, peso: .bold, tracking: -0.5, interlinea: 1.25)
        static let coloreDomanda = K.inchiostro
        static let sopraDomanda: CGFloat = 12
        static let sottoDomanda: CGFloat = 10
        static let larghezzaDomanda: CGFloat = 900
        /// Il numero dello scenario: 44 bold, rosso se scende, verde se sale.
        static let numero = C.valoreCursoreAnalisi
        static let numeroScende = K.rosso
        static let numeroSale = K.verde
        /// Il grafico degli scenari 1-2: 760×300, dominio y 74-116; linea 3,5, area al 10%, riferimento tratteggiato 4 5.
        static let grafico = CGSize(width: 760, height: 300)
        static let dominioMinimo: Double = 74
        static let dominioMassimo: Double = 116
        static let spessoreLinea: CGFloat = 3.5
        static let opacitaArea: Double = 0.10
        static let tratteggioRiferimento: [CGFloat] = [4, 5]
        static let coloreRiferimento = K.inchiostro3
        static let etichettaRiferimento = C.asse
        static let spazioEtichettaRiferimento: CGFloat = 4
        /// Linea rossa se finisce sotto l'inizio, verde (#30B15C) se sopra.
        static let lineaScende = K.rosso
        static let lineaSale = K.anello1
        /// Il grafico dello scenario 3: 760×330, dominio y 90-170, due linee con il nome in fondo a destra (13 bold).
        static let graficoStrade = CGSize(width: 760, height: 330)
        static let dominioStradeMinimo: Double = 90
        static let dominioStradeMassimo: Double = 170
        static let coloriStrade = [K.anello2, K.anello3]
        static let etichettaStrada = C(dimensione: 13, peso: .bold)
        /// Spazio a destra del grafico per i nomi delle strade e l'etichetta del riferimento.
        static let margineEtichette: CGFloat = 80
        /// La colonna delle risposte: larga 380, 60 sopra (30 nello scenario 3), 28 dal grafico.
        static let larghezzaRisposte: CGFloat = 380
        static let sopraRisposte: CGFloat = 60
        static let sopraRisposteStrade: CGFloat = 30
        static let spazioGrafico: CGFloat = 28
        /// La risposta scelta: accento neutro, nessuna risposta «giusta» (decisione 84).
        static let bordoScelta = K.accento
        static let fondoScelta = K.selezioneVoce
        /// Il risultato: anello 220 tratto 22, colonna 340, 40 fra le colonne.
        static let anello: CGFloat = 220
        static let spessoreAnello: CGFloat = 22
        static let colonnaAnello: CGFloat = 340
        static let spazioRisultato: CGFloat = 40
        static let centroEtichetta = C.secondario
        static let coloreCentroEtichetta = K.inchiostro2
        /// Il nome del profilo dentro l'anello: 34 bold, si rimpicciolisce fino a 24 (`dimensioniCentroAnello`).
        static let nomeProfilo = C.centroAnello(34)
        static let riduzioneNome: CGFloat = 24.0 / 34.0
        static let larghezzaNome: CGFloat = 150
        /// «Come ha reagito Giulia»: 28 bold −0,5.
        static let titoloRisultato = C(dimensione: 28, peso: .bold, tracking: -0.5)
        static let coloreTitolo = K.inchiostro
        /// Le righe `.prep`: 13,5, 12 sopra e sotto, filo sotto, pallino 20.
        static let rigaReazione: CGFloat = 12
        static let pallino: CGFloat = 20
        static let testoReazione = C.voceLista
        static let testoReazioneForte = C(dimensione: 13.5, peso: .bold)
        static let coloreReazione = K.inchiostro
        static let secondi = C.secondario
        static let coloreSecondi = K.inchiostro2
        static let filo = K.separatore
        /// Il confronto con il profilo dichiarato: 14 sopra, arancio se diversi.
        static let confronto = C(dimensione: 13.5, peso: .semibold)
        static let confrontoDiverso = K.arancio
        static let confrontoUguale = K.inchiostro2
        static let sopraConfronto: CGFloat = 14
        /// L'avvertenza finale: 13,5 interlinea 1,5, 14 sopra.
        static let avvertenzaFinale = C(dimensione: 13.5, peso: .regular, interlinea: 1.5)
        static let sopraAvvertenza: CGFloat = 14
        /// I pulsanti: 18 sopra, 8 fra loro.
        static let sopraPulsanti: CGFloat = 18
        static let spazioPulsanti: CGFloat = 8
        /// Il riquadro «L'ultima volta…» prima dello scenario 1 (`.tile`).
        static let riquadro = Tema.Apple.Superficie.tile
        static let raggioRiquadro = Tema.Apple.Raggio.tile
        static let paddingRiquadro = Tema.Apple.Misura.Padding.tile
        static let larghezzaRiquadro: CGFloat = 520
        static let testoRiquadro = C.corpoGrande
        static let spazioRiquadro: CGFloat = 12

        /// Il colore di ogni propensione (decisione 84: verde, blu, viola, arancio come il template).
        static func colore(_ p: ProfiloInvestitore.Propensione) -> Color {
            switch p {
            case .prudente: return K.anello1
            case .moderata: return K.anello2
            case .dinamica: return K.anello3
            case .aggressiva: return K.arancio
            }
        }
    }

    // MARK: - Una giornata della pensione (§4.2.2)

    enum Giornata {
        typealias C = Tema.Apple.Carattere
        typealias K = Tema.Apple.Colore

        /// Il contenuto: padding 24 / 30.
        static let padding = EdgeInsets(top: 24, leading: 30, bottom: 24, trailing: 30)
        /// «Giulia, a 67 anni · la pensione al mese» 14 grigio; sotto la cifra 58.
        static let frase = C.corpo
        static let coloreFrase = K.inchiostro2
        static let pensione = C(dimensione: 58, peso: .bold, tracking: -2.2, interlinea: 1, tabellare: true)
        static let colorePensione = K.inchiostro
        /// Il segmentato: 10 sopra il fondo della testa; 24 fra la cifra e il segmentato.
        static let sottoSegmentato: CGFloat = 10
        static let spazioTesta: CGFloat = 24
        /// L'etichetta «da confermare» / «dati di prova» accanto alla frase.
        static let etichettaStato = Tema.Apple.Studio.Card.prova
        static let coloreEtichettaStato = Tema.Apple.Studio.Card.coloreProva
        /// La griglia: 5 colonne uguali (fino a 6 con una scena in più), spazio 14, 20 sotto la testa.
        static let colonne = 5
        static let spazioScene: CGFloat = 14
        static let sottoTesta: CGFloat = 20
        /// La scena `.scena`: raggio 20, fondo `cardPiena`, filo `separatore`, padding 16, alta almeno 270, spazio 6.
        static let raggioScena = Tema.Apple.Raggio.pannello
        static let fondoScena = K.cardPiena
        static let filoScena = K.separatore
        static let bordoScena = Tema.Apple.Misura.bordo
        static let paddingScena: CGFloat = 16
        static let altezzaScena: CGFloat = 270
        static let spazioScena: CGFloat = 6
        /// L'ora: 12,5 bold, spaziatura 0,5, grigia.
        static let ora = C(dimensione: 12.5, peso: .bold, tracking: 0.5)
        static let coloreOra = K.inchiostro2
        /// Il tassello della scena: 64, raggio 20, glifo 34 a tratto 1,8, 6 sopra e 8 sotto.
        static let tassello: CGFloat = 64
        static let raggioTassello: CGFloat = 20
        static let glifo: CGFloat = 34
        static let trattoGlifo: CGFloat = 1.8
        static let sopraTassello: CGFloat = 6
        static let sottoTassello: CGFloat = 8
        /// Titolo 19 bold, frase `.k`, cifra 15 bold, esito bold verde o rosso.
        static let titolo = C.perche
        static let coloreTitolo = K.inchiostro
        static let fraseScena = C.secondario
        static let coloreFraseScena = K.inchiostro2
        static let cifra = C.titoloRiga
        static let coloreCifra = K.inchiostro
        static let esito = C(dimensione: 12.5, peso: .bold)
        static let ciSta = K.verde
        static let nonCiSta = K.rosso
        static let senzaImporto = K.inchiostro2
        /// Il campo dell'importo nella scena da compilare.
        static let campo = C(dimensione: 13, peso: .semibold, tabellare: true)
        static let fondoCampo = K.chip
        static let raggioCampo = Tema.Apple.Raggio.giorno
        static let paddingCampo = Tema.Apple.Misura.padding(5, 8)
        static let invito = C.secondario
        static let coloreInvito = K.inchiostro2
        /// La scena spenta: opacità 0,55 e grigio all'85% (l'esito resta pieno, per il contrasto in scuro).
        static let opacitaSpenta: Double = 0.55
        static let grigioSpenta: Double = 0.85
        /// Scena in più (fino a 6): bordo tratteggiato.
        static let tratteggioNuova: [CGFloat] = [5, 5]
        static let coloreNuova = K.inchiostro3
        /// La striscia `.tile`: 18 sopra, 20 fra la barra e la cifra.
        static let superficieStriscia = Tema.Apple.Superficie.tile
        static let raggioStriscia = Tema.Apple.Raggio.tile
        static let paddingStriscia = Tema.Apple.Misura.Padding.tile
        static let sopraStriscia: CGFloat = 18
        static let spazioStriscia: CGFloat = 20
        /// La barra alta 14 raggio 8: spese fisse grigio-azzurre (#9FB3C2), scene verdi, binario.
        static let altezzaBarra: CGFloat = 14
        static let raggioBarra: CGFloat = 8
        static let coloreFisse = K.Composizione.liquidita
        static let coloreScene = K.verde
        static let binario = K.binario
        /// «Restano 90 € al mese»: 16 bold; sotto quanto manca per tutta la giornata (`.k`).
        static let resto = C(dimensione: 16, peso: .bold)
        static let coloreResto = K.inchiostro
        static let colorePositivo = K.verde
        static let coloreMancano = K.rosso
        static let manca = C.secondario
        static let coloreManca = K.inchiostro2
        /// La nota in fondo: `.k`, 10 sopra.
        static let nota = C.secondario
        static let coloreNota = K.inchiostro2
        static let sopraNota: CGFloat = 10
        /// Gli stati senza cifre: testo 15, pulsante 12 sotto.
        static let stato = C.corpoGrande
        static let coloreStato = K.inchiostro
        static let larghezzaStato: CGFloat = 560
        static let spazioStato: CGFloat = 12
        /// Il dettaglio della scena (scrivere l'importo, la priorità, togliere).
        static let larghezzaDettaglio: CGFloat = 300
        static let paddingDettaglio = Tema.Apple.Misura.padding(16, 18)
        static let spazioDettaglio: CGFloat = 10
        static let titoloDettaglio = C.titoloRiga
        static let etichettaDettaglio = C.secondario
    }
}

extension Tema.Apple.Moto.SalaEsperienze {
    // MARK: - Movimento del gioco del rischio (§4.1.3)

    enum Rischio {
        /// Il primo scenario parte 0,2 s dopo il montaggio.
        static let attesaInizio = 0.2
        /// La linea degli scenari 1-2 si disegna in 2,2 s (`uscita`), il numero si conta insieme.
        static let durataLinea = 2.2
        /// Le linee dello scenario 3: `Moto.Linea` (1,5 s, ritardo 0,15 + i·0,12): finiscono a 1,77 s.
        static var fineLineeStrade: Double { Tema.Apple.Moto.Linea.durata + Tema.Apple.Moto.Linea.ritardo(indice: 1) }
        /// Le risposte entrano 0,2 s dopo la fine del grafico, da x +20, 0,45 s `uscita`, passo 0,09.
        static let attesaRisposte = 0.2
        static let durataRisposta = 0.45
        static let passoRisposte = 0.09
        static let spostamentoRisposta: CGFloat = 20
        static func risposta(indice: Int) -> Animation {
            Tema.Apple.Moto.Curva.uscita.animazione(durataRisposta).delay(Double(indice) * passoRisposte)
        }
        /// Dopo la scelta, lo scenario seguente arriva dopo 0,65 s (uscita a dissolvenza come la rimonta).
        static let pausaDopoScelta = 0.65
        static var cambioScenario: Animation { .easeOut(duration: Tema.Apple.Studio.Moto.durataRimonta) }
    }

    // MARK: - Movimento della giornata della pensione (§4.2.3)

    enum Giornata {
        /// La scena il cui esito cambia gira su sé stessa: 0 → 90° → 0 in 0,62 s, prospettiva 800, passo 0,08 s.
        static let giro = 0.62
        static let passoGiro = 0.08
        static let prospettiva: CGFloat = 800
        static let angoloGiro: Double = 90
        /// Lo spegnimento (opacità e grigio) in 0,5 s, insieme al giro.
        static let durataSpegnimento = 0.5
        static var spegnimento: Animation { Tema.Apple.Moto.Curva.ease.animazione(durataSpegnimento) }
        /// Mezzo giro (il contenuto cambia a metà).
        static func mezzoGiro(ritardo: Double) -> Animation {
            Tema.Apple.Moto.Curva.giro.animazione(giro / 2).delay(ritardo)
        }
    }
}

extension Tema.Apple.Moto.Curva {
    /// Il giro della scena della giornata: (0,4, 0, 0,2, 1).
    static let giro = Tema.Apple.Moto.Curva(x1: 0.4, y1: 0, x2: 0.2, y2: 1)
}

extension Tema.Apple.Colore.Glifi {
    /// Le tinte delle cinque scene della giornata (stesse in chiaro e in scuro).
    /// #B06E12 come il cuoio dell'indipendente, ma fisso: è un tassello con un glifo, non un'etichetta di canale.
    static let colazione = Color(hex: "#B06E12")
    /// #5A6873 = `Carta.etichetta`.
    static let casa = Tema.Apple.Carta.etichetta
    static let nipoti = Color(hex: "#E58BA0")
    static let cena = Tema.Apple.Colore.anello3
    static let viaggio = Tema.Apple.Colore.anello2
}
