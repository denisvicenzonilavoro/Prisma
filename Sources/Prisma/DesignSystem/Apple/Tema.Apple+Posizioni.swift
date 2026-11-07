import SwiftUI

// Posizioni › Portafoglio del tema Apple (Design/template-apple-specifica.md §4.1, riferimenti posizioni-clienti/
// P01-P14 e movimento/02-12): misure, caratteri, colori e tempi della card del portafoglio, dello stato del lavoro,
// del nastro «Da fare» e del dettaglio di una scheda. Le viste stanno in Shell/PortafoglioApple.swift; qui solo
// i valori. Area del contenuto del template 1384×654: in Prisma le larghezze sono quote dello spazio che c'è.

extension Tema.Apple {
    enum Posizioni {
        // MARK: Disposizione

        enum Disposizione {
            /// Spazio fra le card e fra le righe (16 nel template).
            static let spazio: CGFloat = Misura.Spazio.colonneScrivania
            /// Larghezze della prima riga: card del portafoglio 870, stato del lavoro 498 (in proporzione).
            static let quoteRiga: [CGFloat] = [870, 498]
            /// Lo stato del lavoro non scende sotto questa larghezza (anelli e legenda leggibili).
            static let larghezzaMinimaLavoro: CGFloat = 380
            /// Altezza della prima riga: 296 nel template; qui 310, perché il totale di SF a 62 pt occupa la sua
            /// riga intera e il grafico (in fondo alla card) non deve coprire le cifre dei canali.
            static let altezzaRiga: CGFloat = 310
            /// Margine del contenuto (12, come nel resto della finestra).
            static let margine: CGFloat = Misura.Finestra.margineContenuto
            /// Spazio fra il nastro e i pannelli di Prisma che seguono sotto.
            static let spazioPannelli: CGFloat = 22
            /// Fondo del portafoglio: la carta chiara della finestra del tema.
            static let fondo = Colore.finestra
        }

        // MARK: Card del portafoglio

        enum Card {
            static let padding = Misura.Padding.cardPortafoglio
            static let raggio = Raggio.card
            static let superficie = Superficie.card
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            /// Il totale che si conta: 62 bold.
            static let totale = Carattere.numeroGrande
            static let riduzioneTotale: CGFloat = 0.55
            static let totaleSopra: CGFloat = 12
            /// Spazio fra il totale e il delta, che resta 7 sopra la linea di base del totale.
            static let spazioDelta: CGFloat = 18
            static let deltaSotto: CGFloat = 7
            static let delta = Carattere.delta
            static let coloreDelta = Colore.verde
            static let coloreDeltaNegativo = Colore.rosso
            static let coloreDeltaProposte = Colore.stima
            static let sottoDelta = Carattere.secondario
            static let coloreSottoDelta = Colore.inchiostro2
            /// Barra dei canali: 16 sopra, 8 sotto, larga 520 (o meno sulle card strette).
            static let barraSopra: CGFloat = 16
            static let barraSotto: CGFloat = 8
            static let larghezzaBarra: CGFloat = Grafico.Barra.larghezzaCanali
            /// Riga dei canali: 16 fra etichetta e cifra, 8 in più fra i due canali; cifre 13 bold.
            static let spazioCanale: CGFloat = 16
            static let spazioFraCanali: CGFloat = 8
            static let cifraCanale = Carattere(dimensione: 13, peso: .bold, tabellare: true)
            /// Il grafico: 26 dai lati della card, 30 dal fondo (i mesi stanno nei 20 sotto il grafico).
            static let graficoSotto: CGFloat = 10
            /// Indici dei numeri che contano (totale, Alleanza, indipendente): partono insieme.
            static let indiceTotale = 0
            static let indiceCanali = 1
            /// Indice della barra dei canali (ritardi 0,15 e 0,24).
            static let indiceBarra = 0
        }

        // MARK: Lo stato del tuo lavoro

        enum Lavoro {
            static let padding = Misura.Padding.cardGrande
            static let raggio = Raggio.card
            static let superficie = Superficie.card
            /// Anelli 190/16 (più piccoli se la card è stretta, mai sotto 120).
            static let anelli: CGFloat = 190
            static let anelliMinimi: CGFloat = 120
            static let spessoreAnelli: CGFloat = 16
            /// Spazio fra anelli e legenda.
            static let spazioAnelli: CGFloat = 22
            static let anelliSopra: CGFloat = 12
            /// Spazio minimo che resta alla legenda accanto agli anelli: 200, perché «Clienti in regola» col
            /// pallino e «1 su 5» stiano su una riga (a 170 i nomi uscivano tagliati con «…»).
            static let larghezzaLegenda: CGFloat = 200
            static let coloreInRegola = Colore.anello1
            static let coloreRiesami = Colore.anello2
            static let coloreProposte = Colore.anello3
            /// Legenda: righe con padding 10 e filetto, pallino 10, nome 14, numero 20 bold, «su 35» 13.
            static let rigaLegenda: CGFloat = 10
            static let spazioLegenda: CGFloat = 12
            static let pallino: CGFloat = 10
            static let nome = Carattere(dimensione: 14, peso: .regular)
            static let numero = Carattere(dimensione: 20, peso: .bold, tabellare: true)
            static let su = Carattere(dimensione: 13, peso: .medium)
            static let coloreSu = Colore.inchiostro2
            static let filetto = Colore.separatore
            /// L'invito sotto la legenda («Chiudi le cose da fare qui sotto…»), 10 sopra.
            static let invito = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.45)
            static let invitoSopra: CGFloat = 10
            static let coloreInvito = Colore.inchiostro2
        }

        // MARK: Nastro «Da fare»

        enum Nastro {
            /// Testata: titolo `.h2`, conteggio 13,5 `inchiostro2` a 6, frecce da 32 a destra; 18 sopra il nastro.
            static let titolo = Carattere.h2
            static let conteggio = Carattere(dimensione: 13.5, peso: .regular)
            static let coloreConteggio = Colore.inchiostro2
            static let spazioConteggio: CGFloat = 6
            static let spazioFrecce: CGFloat = 6
            static let freccia: CGFloat = Misura.Controllo.freccia
            static let testataSopra: CGFloat = 18
            /// Fra la testata e le schede.
            static let testataSotto: CGFloat = 2
            /// Padding interno del nastro (10×28: le ombre delle schede non vengono tagliate), spazio 14.
            static let padding = Misura.Padding.nastro
            static let spazio: CGFloat = Misura.Spazio.nastro
            /// Il nastro esce di 12 dai lati del contenuto, come nel template (left/right −12).
            static let sbordo: CGFloat = 12
            /// Maschera: 30 sfumati a sinistra, 60 a destra.
            static let sfumaturaSinistra: CGFloat = 30
            static let sfumaturaDestra: CGFloat = 60
            /// Una freccia sposta di due schede (2 × (232 + 14) = 492, il ±500 del template).
            static let schedePerFreccia = 2
            /// Gruppo: largo 112, 8 sopra, titolo 22 bold e conteggio 12,5.
            static let larghezzaGruppo: CGFloat = 112
            static let gruppoSopra: CGFloat = 8
            static let titoloGruppo = Carattere.titoloGruppo
            static let conteggioGruppo = Carattere.secondario
            static let coloreConteggioGruppo = Colore.inchiostro2
            static let vuoto = Carattere.corpo
            static let coloreVuoto = Colore.inchiostro2
        }

        // MARK: Scheda «Da fare»

        enum Scheda {
            static let misura = CGSize(width: 232, height: 270)
            static let raggio = Raggio.card
            static let superficie = Superficie.card
            /// Padding 16, fascia superiore di 4 nel tono.
            static let padding: CGFloat = 16
            static let fascia: CGFloat = 4
            static let quando = Carattere.quando
            static let perche = Carattere.perche
            static let percheSopra: CGFloat = 12
            static let righePerche = 5
            static let spazioCanali: CGFloat = 5
            static let canaliSopra: CGFloat = 10
            /// Il cliente: avatar 34, nome 13,5 bold, patrimonio 12 `inchiostro2`, 12 sopra.
            static let avatar: CGFloat = Misura.Avatar.voce
            static let spazioCliente: CGFloat = 9
            static let clienteSopra: CGFloat = 12
            /// Fra il nome del cliente e il suo patrimonio.
            static let spazioNomePatrimonio: CGFloat = 1
            static let nome = Carattere(dimensione: 13.5, peso: .bold)
            static let patrimonio = Carattere(dimensione: 12, peso: .regular, tabellare: true)
            static let colorePatrimonio = Colore.inchiostro2
            static let inclinazione = Moto.Inclinazione.massimoPredefinito

            /// Il colore del tono: rosso oggi, arancio in settimana, verde dopo.
            static func colore(_ t: VoceDaFare.Tono) -> Color {
                switch t {
                case .urgente: return Colore.rosso
                case .presto: return Colore.arancio
                case .sereno: return Colore.verde
                }
            }
        }

        // MARK: Dettaglio di una scheda (880×520)

        enum Dettaglio {
            static let misura = Misura.DettaglioAperto.daFare
            static let avatar: CGFloat = Misura.Avatar.grande
            static let spazioTestata: CGFloat = 14
            static let quando = Carattere.etichetta
            static let nome = Carattere.titoloDettaglio(26)
            /// Le etichette dei canali lasciano 56 a destra per la ✕.
            static let margineChiudi: CGFloat = 56
            static let spazioCanali: CGFloat = 5
            static let perche = Carattere(dimensione: 22, peso: .bold, tracking: -0.4, interlinea: 1.25)
            static let percheSopra: CGFloat = 20
            static let percheSotto: CGFloat = 6
            static let larghezzaTesto: CGFloat = 760
            static let spiegazione = Carattere.corpoGrande
            static let coloreSpiegazione = Colore.inchiostro2
            /// Le due colonne (1,1 e 1), 26 fra l'una e l'altra, 22 sotto il testo.
            static let spazioColonne: CGFloat = 26
            static let colonneSopra: CGFloat = 22
            static let quotaSinistra: CGFloat = 1.1
            /// Le tre cifre: etichetta `.k`, valore 26 bold, 34 fra l'una e l'altra.
            static let etichettaCifra = Carattere.secondario
            static let coloreEtichettaCifra = Colore.inchiostro2
            static let cifra = Carattere.valore
            static let spazioCifre: CGFloat = 34
            /// Il grafico del cliente: 440×110 (linea 2,5, area al 12%), 16 sopra; etichette 11 `inchiostro3`.
            static let grafico = CGSize(width: 440, height: 110)
            static let graficoSopra: CGFloat = 16
            static let spessoreGrafico: CGFloat = 2.5
            static let opacitaAreaGrafico: Double = 0.12
            static let asse = Carattere.asse
            static let coloreAsse = Colore.inchiostro3
            static let asseSopra: CGFloat = 6
            /// Piede: pulsanti grandi a 8 l'uno dall'altro, 30 dai lati e 24 dal fondo; nota `.k` a destra.
            static let spazioPulsanti: CGFloat = 8
            static let nota = Carattere.secondario
            static let coloreNota = Colore.inchiostro2
        }

        // MARK: Il colore del cliente (avatar e grafico del dettaglio)

        /// Il colore del cliente nel tema: la tinta dell'avatar, con i toni degli impegni dell'Agenda.
        static func coloreCliente(_ t: TintaAvatar) -> Color {
            switch t {
            case .blu: return Colore.Impegno.marco
            case .rosa: return Colore.Impegno.giulia
            case .viola: return Colore.Impegno.laura
            case .verde: return Colore.Impegno.andrea
            case .oro: return Colore.Impegno.sofia
            }
        }
    }
}
