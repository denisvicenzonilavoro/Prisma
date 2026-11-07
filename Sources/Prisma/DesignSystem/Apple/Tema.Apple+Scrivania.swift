import SwiftUI

// La scrivania del tema Apple (Design/template-apple-specifica.md §3.6, riferimenti shell/03-scrivania,
// 13-riquadro-hover, movimento/19 e 20): misure, caratteri, colori e tempi dei riquadri. Le viste stanno in
// Shell/ScrivaniaApple.swift; qui solo i valori. Palco del template 1440×900: margini 44, colonne a 16;
// in Prisma le larghezze e le altezze sono quote dello spazio che c'è (niente coordinate fisse).

extension Tema.Apple {
    enum Scrivania {
        // MARK: Disposizione

        enum Disposizione {
            /// Margine ai lati (44 nel palco), che si stringe sulle finestre strette: 3% della larghezza, fra 16 e 44.
            static let margine: CGFloat = Misura.Spazio.margineScrivania
            static let margineMinimo: CGFloat = 16
            static let quotaMargine: CGFloat = 0.03
            /// Larghezza massima del contenuto (oltre, la scrivania resta centrata).
            static let larghezzaMassima: CGFloat = 1600
            /// Spazio fra i riquadri, in orizzontale e in verticale.
            static let spazio: CGFloat = Misura.Spazio.colonneScrivania
            /// Il saluto a 48 dall'alto dello schermo: 14 sotto la barra (34).
            static let alto: CGFloat = 14
            /// Spazio sotto l'ultima riga (la scrivania finisce a 780 nel palco, il dock comincia a 796).
            static let basso: CGFloat = 16
            /// Altezza della testata (saluto e sottotitolo): la mossa comincia a 132 nel palco.
            static let testata: CGFloat = 68
            /// La mossa del giorno: alta 148.
            static let mossa: CGFloat = 148
            /// Le due righe sotto la mossa: 300 e 168 nel palco, divise in proporzione allo spazio che c'è.
            static let rigaAlta: CGFloat = 300
            static let rigaBassa: CGFloat = 168
            /// Sotto questa altezza la riga bassa non scende (i titoli e una riga restano leggibili).
            static let rigaBassaMinima: CGFloat = 104
            static let rigaAltaMinima: CGFloat = 200
            /// Larghezze della riga alta (Agenda 560, Portafoglio 384, Vera il resto: 376) e della bassa (660 / 676).
            static let quoteRigaAlta: [CGFloat] = [560, 384, 376]
            static let quoteRigaBassa: [CGFloat] = [660, 676]
        }

        // MARK: Riquadro

        enum Riquadro {
            static let raggio: CGFloat = Raggio.riquadro
            /// Padding 18×20.
            static let padding = Misura.Padding.cardPiccola
            /// Testate dei riquadri («Prossimi incontri», «Portafoglio clienti», «Da fare oggi»…): 14 bold.
            static let titolo = Carattere(dimensione: 14, peso: .bold)
            /// Il collegamento a destra della testata («Apri Agenda», «Apri»): 13 semibold blu.
            static let collegamento = Carattere(dimensione: 13, peso: .semibold)
            static let coloreCollegamento = Colore.accento
            /// Spazio fra un simbolo e il titolo della testata.
            static let spazioSimbolo: CGFloat = 6
            /// Riga vuota di un elenco.
            static let vuoto = Carattere.secondario
        }

        // MARK: Saluto e pulsanti

        enum Saluto {
            static let titolo = Carattere.saluto
            static let sottotitolo = Carattere(dimensione: 15, peso: .regular)
            static let colore = Colore.inchiostroAcqua
            static let coloreSottotitolo = Colore.inchiostroAcqua2
            static let spazio: CGFloat = 2
            /// Sulle finestre strette il saluto si riduce fino al 70%.
            static let riduzioneMinima: CGFloat = 0.7
            /// Prima delle 13 «Buongiorno», prima delle 18 «Buon pomeriggio», poi «Buonasera».
            static let oraPomeriggio = 13
            static let oraSera = 18
            /// Pulsanti di vetro a 64 dall'alto dello schermo (16 sotto il saluto), a 8 l'uno dall'altro.
            static let pulsantiAlto: CGFloat = 16
            static let spazioPulsanti: CGFloat = 8
            /// La guida per cominciare, quando è visibile, sotto il sottotitolo.
            static let guidaAlto: CGFloat = 8
        }

        // MARK: La mossa del giorno

        enum Mossa {
            /// Padding 20×24, spazio 22 fra sfera, testo e pulsanti.
            static let padding = Misura.padding(20, 24)
            static let spazio: CGFloat = 22
            static let sfera: CGFloat = 88
            /// Raggio del gradiente della sfera, in lati: dal centro (34% · 28%) all'angolo più lontano (CSS `circle`).
            static let estensioneGradiente: CGFloat = 0.98
            /// Le iniziali nella sfera: 26 bold bianche, con un'ombra blu leggera.
            static let iniziali = Carattere(dimensione: 26, peso: .bold)
            static let coloreIniziali = Color.white
            static let ombraIniziali = Color(r: 0, g: 40, b: 80, a: 0.4)
            static let raggioOmbraIniziali: CGFloat = 2
            static let yOmbraIniziali: CGFloat = 1
            /// «La mossa del giorno» (`.lbl` in #1D6FC4, in scuro #6EA7E2).
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.mossaDelGiorno
            static let titolo = Carattere.titoloMossa
            /// Un titolo lungo si riduce fino all'80%; il motivo resta su due righe al massimo.
            static let riduzioneTitolo: CGFloat = 0.8
            static let righeCorpo = 2
            /// Senza una mossa, nella sfera la spunta: niente di urgente.
            static let simboloCalma = "checkmark"
            static let titoloSopra: CGFloat = 4
            static let titoloSotto: CGFloat = 6
            /// Il motivo: 14,5 `inchiostro2`, largo al massimo 720.
            static let corpo = Carattere(dimensione: 14.5, peso: .regular, interlinea: 1.45)
            static let coloreCorpo = Colore.inchiostro2
            static let larghezzaCorpo: CGFloat = 720
            static let spazioPulsanti: CGFloat = 8
            /// Il simbolo di «Preparami l'incontro» (✦ del template).
            static let simboloPrepara = "sparkles"
            /// Etichetta del canale accanto all'etichetta della mossa.
            static let spazioCanale: CGFloat = 8
        }

        // MARK: Agenda di oggi

        enum Agenda {
            static let colonna: CGFloat = 120
            static let spazio: CGFloat = 18
            static let giornoSettimana = Carattere(dimensione: 14, peso: .semibold)
            static let coloreGiornoSettimana = Colore.rosso
            static let giorno = Carattere.giornoAgenda
            static let riduzioneGiorno: CGFloat = 0.6
            static let mese = Carattere.secondario
            /// «4 impegni oggi» 13 semibold, sotto «il prossimo alle 09:30».
            static let riepilogo = Carattere(dimensione: 13, peso: .semibold)
            static let prossimo = Carattere.secondario
            /// Righe degli incontri: barra di 3 nel colore del cliente, padding 3 · 0 · 3 · 10, 9 fra le righe.
            static let barra: CGFloat = 3
            static let paddingRiga = EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 0)
            static let spazioRighe: CGFloat = 9
            static let testataSotto: CGFloat = 10
            static let nome = Carattere(dimensione: 13, peso: .bold)
            static let dettaglio = Carattere(dimensione: 13, peso: .regular)
            /// Altezza di una riga (due righe di 13 più il padding e lo spazio): per sapere quante ne entrano.
            static let altezzaRiga: CGFloat = 47
            static let righeMassime = 4
        }

        // MARK: Portafoglio clienti

        enum Portafoglio {
            static let totale = Carattere.totaleScrivania
            static let totaleSopra: CGFloat = 10
            static let riduzioneTotale: CGFloat = 0.6
            static let anelli: CGFloat = 118
            /// Sugli schermi bassi gli anelli si rimpiccioliscono fino a 48: il riquadro tiene, oltre agli anelli, circa
            /// 152 punti (padding 36, testata, totale, «in essere», spazio sopra gli anelli e canali).
            static let anelliMinimi: CGFloat = 48
            static let altezzaSenzaAnelli: CGFloat = 152
            static let spessoreAnelli: CGFloat = 12
            static let anelliSopra: CGFloat = 16
            static let spazioAnelli: CGFloat = 18
            /// La legenda: 12,5 con interlinea 2.
            static let legenda = Carattere(dimensione: 12.5, peso: .regular)
            static let legendaForte = Carattere(dimensione: 12.5, peso: .bold, tabellare: true)
            static let spazioLegenda: CGFloat = 8
            static let pallino: CGFloat = 8
            static let spazioPallino: CGFloat = 6
            /// I canali sotto gli anelli: pallino 6 e quota, sempre distinti.
            static let canali = Carattere(dimensione: 12, peso: .medium, tabellare: true)
            static let spazioCanali: CGFloat = 14
            static let pallinoCanale: CGFloat = Misura.Controllo.pallinoCanale
            /// Colori degli anelli: in regola, riesami, proposte.
            static let coloreInRegola = Colore.anello1
            static let coloreRiesami = Colore.anello2
            static let coloreProposte = Colore.anello3
        }

        // MARK: Vera

        enum Vera {
            static let sfera: CGFloat = 46
            static let spazioTesta: CGFloat = 10
            static let nome = Carattere(dimensione: 15, peso: .bold)
            static let stato = Carattere.secondario
            static let frase = Carattere.fraseVera
            static let fraseSopra: CGFloat = 18
            static let fraseSotto: CGFloat = 16
            /// La frase sta al massimo su 4 righe (meno se il riquadro è basso).
            static let righeFrase = 4
            /// Suggerimenti a capsula: padding 8×14, 13 medium, fondo `card` col filo `separatore`, spazio 6.
            static let suggerimento = Carattere(dimensione: 13, peso: .medium)
            static let paddingSuggerimento = Misura.padding(8, 14)
            static let fondoSuggerimento = Colore.card
            static let bordoSuggerimento = Colore.separatore
            static let spazioSuggerimenti: CGFloat = 6
            /// Un clic su un suggerimento apre Vera e manda la domanda dopo 0,7 s.
            static let attesaDomanda: Double = 0.7
            static let coloreNonPronto = Colore.arancio
        }

        // MARK: Da fare oggi

        enum DaFare {
            static let simbolo = "list.bullet"
            static let elencoSopra: CGFloat = 12
            /// Righe 13,5 con interlinea 2: 27 l'una.
            static let voce = Carattere.voceLista
            static let altezzaRiga: CGFloat = 27
            static let righeMassime = 4
            static let cerchio: CGFloat = 11
            static let trattoCerchio: CGFloat = 1.4
            static let spazioCerchio: CGFloat = 8
            static let coloreCliente = Colore.inchiostro3
            static let coloreScaduta = Colore.rosso
        }

        // MARK: In scadenza

        enum Scadenze {
            static let simbolo = "hourglass"
            static let elencoSopra: CGFloat = 12
            static let spazioRighe: CGFloat = 8
            /// Il blocco della data largo 40: «DIC» 10 bold rosso, «17» 21 semibold.
            static let data: CGFloat = 40
            static let mese = Carattere(dimensione: 10, peso: .bold)
            static let coloreMese = Colore.rosso
            static let giorno = Carattere(dimensione: 21, peso: .semibold, tabellare: true)
            static let spazio: CGFloat = 14
            static let testo = Carattere(dimensione: 13, peso: .regular)
            static let prodotto = Carattere(dimensione: 13, peso: .bold)
            static let coloreQuando = Colore.scadenza
            static let coloreScaduta = Colore.rosso
            /// Mese 10 bold + giorno 21 semibold ≈ 37 pt: la riga vera, così entrano tutte quelle che ci stanno
            static let altezzaRiga: CGFloat = 37
            static let righeMassime = 3
        }

        // MARK: Movimento

        enum Moto {
            /// I numeri cominciano a contare 0,30 s dopo lo sblocco.
            static let ritardoNumeri: Double = 0.30
            /// Gli anelli dopo lo sblocco partono a 0,60 / 0,73 / 0,86 s: montati con i numeri (a 0,30), aspettano il resto.
            static let ritardoAnelliDopoSblocco: Double = Tema.Apple.Moto.Anello.ritardoScrivania - ritardoNumeri
            /// Senza sblocco (la scrivania che c'è già): anelli a 0,20 / 0,33 / 0,46 s (§0, punto 3).
            static let ritardoAnelli: Double = Tema.Apple.Moto.Anello.ritardoPredefinito
            /// Il riquadro sotto il puntatore sale di 3 con la molla di 0,45 s.
            static var sopra: Animation { Tema.Apple.Moto.RiquadroSopra.animazione }
            static let sollevamento: CGFloat = Tema.Apple.Moto.RiquadroSopra.spostamento
            /// Il suggerimento di Vera sotto il puntatore sale di 2 con la molla di 0,25 s.
            static var sopraSuggerimento: Animation { Tema.Apple.Moto.SuggerimentoSopra.animazione }
            static let sollevamentoSuggerimento: CGFloat = Tema.Apple.Moto.SuggerimentoSopra.spostamento
            /// Con una finestra aperta davanti la scrivania scende al 25% in 0,5 s.
            static let opacitaSotto: Double = Tema.Apple.Moto.ScrivaniaSotto.opacita
            static var sotto: Animation { Tema.Apple.Moto.ScrivaniaSotto.animazione }
        }
    }
}
