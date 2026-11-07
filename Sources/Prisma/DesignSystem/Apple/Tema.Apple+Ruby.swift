import SwiftUI

// Ruby nel tema Apple (Design/template-apple-specifica.md §4.7, §2.18-2.20; riferimenti PIE e01…e10).
// Le viste stanno in Shell/AppRuby.swift (colonna, chat, campo, testata), in DesignSystem/Apple/RubyApple.swift
// (sfera, puntini, testo parola per parola, entrate) e in DesignSystem/ComponentiQuadroRuby.swift (schede dei calcoli);
// le bolle e gli spunti condivisi con la Ruby della scrivania e con iPhone e iPad in ComponentiRubyVetro.swift.
// Qui solo i valori, tutti ricavati dal tema Apple.

extension Tema.Apple {
    enum Ruby {
        // MARK: Sfera (§2.18)

        enum Sfera {
            /// Barra superiore, riquadro della scrivania, app Ruby.
            static let barra: CGFloat = 24
            static let riquadro: CGFloat = 46
            static let ruby: CGFloat = 120
            /// Il riflesso conico esce del 30% per lato (`inset: -30%`).
            static let estensioneRiflesso: CGFloat = 1.6
            /// Il gradiente radiale (`circle at 34% 28%`) arriva all'angolo più lontano: 0,98 del lato.
            static let estensioneGradiente: CGFloat = 0.98
            /// Il riflesso conico parte dall'alto, come `conic-gradient(from 0deg)`.
            static let inizioRiflesso: Double = -90
            /// Fotogrammi al secondo del riflesso e del respiro (TimelineView, solo con la sfera visibile).
            static let fotogrammi: Double = 30
            /// Ombra interna (inset 0 −4 10): spessore del filo sfocato.
            static let spessoreOmbraInterna: CGFloat = 10
            /// La sfera si gonfia appena con la voce (mini finestra): +10% al livello pieno.
            static let gonfiaVoce: CGFloat = 0.1
            static let durataVoce = 0.12
            /// L'alone della voce: raggio in quota del lato, a riposo e in più al livello pieno.
            static let aloneVoce: CGFloat = 0.2
            static let aloneVoceCrescita: CGFloat = 0.25
        }

        // MARK: Colonna di sinistra (.side)

        enum Colonna {
            static let larghezza: CGFloat = Misura.Laterale.ruby
            static let superficie = Superficie.pannello
            static let raggio: CGFloat = Raggio.pannello
            /// Padding della barra laterale 14×12, in alto 30.
            static let padding = EdgeInsets(top: Misura.Padding.barraLateraleRubyAlto, leading: 12, bottom: 14, trailing: 12)
            /// La chat comincia a 316 da sinistra.
            static let spazioChat: CGFloat = 16
            /// In fondo alla colonna le card sfumano invece di finire tagliate.
            static let sfumatura: CGFloat = 20
            /// «Ciao, sono Ruby.» 22 bold (margin-top 18) e «Mettiamo in ordine le idee.» 14.
            static let saluto = Carattere.titoloGruppo
            static let salutoSopra: CGFloat = 18
            static let motto = Carattere(dimensione: 14, peso: .regular)
            static let coloreSaluto = Colore.inchiostro
            static let coloreMotto = Colore.inchiostro2
            /// Card della colonna: piatte, padding 14×16, la prima a 22 dal saluto, poi a 10 l'una dall'altra.
            static let superficieScheda = Superficie.cardPiatta
            static let raggioScheda: CGFloat = Raggio.card
            static let paddingScheda = Misura.padding(14, 16)
            static let primaScheda: CGFloat = 22
            static let fraSchede: CGFloat = 10
            /// Stato di Qwen: pallino 8 verde o arancio, riga 13 semibold, nota `.k` a 4.
            static let statoMotore = Carattere(dimensione: 13, peso: .semibold)
            static let spia: CGFloat = 8
            static let spazioSpia: CGFloat = 8
            static let notaMotore = Carattere.secondario
            static let notaSopra: CGFloat = 4
            static let verificaSopra: CGFloat = 10
            static let coloreTesto = Colore.inchiostro
            static let coloreNota = Colore.inchiostro2
            static let pronto = Colore.verde
            static let nonPronto = Colore.arancio
            /// «Oggi»: `.lbl`, gli impegni 13,5 con interlinea 1,9.
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            static let oggi = Carattere(dimensione: 13.5, peso: .regular)
            /// Interlinea 1,9 a 13,5: righe alte 25,65.
            static let altezzaRigaOggi: CGFloat = 25.65
            static let oggiSopra: CGFloat = 4
            static let coloreOggiSecondario = Colore.inchiostro3
            /// Al massimo tanti impegni nella card (poi «e altri n»).
            static let massimoOggi = 5
            /// L'impegno del cliente di cui si parla, nell'accento.
            static let coloreOggiScelto = Colore.accento
            /// «Da non dimenticare»: card d'avviso arancio.
            static let fondoAvviso = Colore.avvisoFondo
            static let bordoAvviso = Colore.avvisoBordo
            static let etichettaAvviso = Colore.scadenza
            static let testoAvviso = Carattere(dimensione: 13.5, peso: .semibold)
            static let notaAvviso = Carattere(dimensione: 12, peso: .regular)
            static let spazioAvviso: CGFloat = 3
            /// Il quadro del cliente: tile 2×2 con il numero 18 bold e la voce `.k`.
            static let superficieTessera = Superficie.tile
            static let raggioTessera: CGFloat = Raggio.tile
            static let paddingTessera = Misura.padding(10, 12)
            static let numeroTessera = Carattere(dimensione: 18, peso: .bold, tabellare: true)
            static let voceTessera = Carattere(dimensione: 12, peso: .regular)
            static let spazioTessere: CGFloat = 8
            /// Di chi si parla: il segmentato «Cliente / Portafoglio» e la tendina dei clienti, a 8.
            static let spazioAmbito: CGFloat = 8
            static let fondoSopra = Colore.chip
            static let raggioVoce: CGFloat = Raggio.voce
        }

        // MARK: Chat

        enum Chat {
            /// Area a 40 dai lati e 10 dall'alto; i messaggi larghi al massimo 640, distanti 14.
            static let margineLati: CGFloat = 40
            static let margineAlto: CGFloat = 10
            /// Padding interno della chat (10×6): le ombre e le molle non vengono tagliate.
            static let paddingInterno = Misura.padding(10, 6)
            static let larghezzaMessaggio: CGFloat = 640
            static let spazioMessaggi: CGFloat = 14
            /// Dalla chat ai suggerimenti (la chat finisce a 120 dal fondo, i suggerimenti a 66).
            static let sopraSuggerimenti: CGFloat = 21
            /// Dai suggerimenti al campo e dal campo al fondo.
            static let sopraCampo: CGFloat = 8
            static let sottoCampo: CGFloat = 10
            /// In fondo l'ultima risposta sfuma sopra i suggerimenti.
            static let sfumatura: CGFloat = 18
            /// La capsula della voce (ascolto, risposta a voce) in alto a destra della chat.
            static let paddingVoce = Misura.padding(5, 12)
            static let spazioVoce: CGFloat = 8
            static let carattereVoce = Carattere(dimensione: 11.5, peso: .semibold, tracking: 0.4, maiuscolo: true)
            static let fondoVoce = Colore.chip
            static let coloreVoce = Colore.inchiostro2
            static let ascolto = Colore.rosso
            static let parla = Colore.accento
            static let spiaVoce: CGFloat = 7
            /// Errori e passaggi della voce sopra i suggerimenti.
            static let notaVoce = Carattere(dimensione: 11.5, peso: .regular)
            /// Il benvenuto della conversazione vuota.
            static let benvenuto = Carattere.fraseRuby
            static let benvenutoTesto = Carattere.corpoGrande
            static let larghezzaBenvenuto: CGFloat = 480
            static let margineBenvenuto: CGFloat = 40
            static let spazioBenvenuto: CGFloat = 8
        }

        // MARK: Bolle

        enum Bolla {
            /// Ruby: `chip`, padding 14×18, raggi 20/20/20/6; l'utente: accento, testo bianco, padding 10×16, 20/20/6/20.
            static let fondoRuby = Colore.chip
            static let fondoUtente = Colore.accento
            static let testoUtente = Color.white
            static let testo = Colore.inchiostro
            static let paddingRuby = Misura.padding(14, 18)
            static let paddingUtente = Misura.padding(10, 16)
            static let raggio: CGFloat = Raggio.pannello
            static let angolo: CGFloat = Raggio.bollaPiccola
            /// Messaggi 14,5 con interlinea 1,55.
            static let messaggio = Carattere(dimensione: 14.5, peso: .regular, interlinea: 1.55)
            /// Intestazione 12 semibold «Ruby» o «Ruby · Calcoli di Prisma», 4 sopra il testo.
            static let intestazione = Carattere(dimensione: 12, peso: .semibold)
            static let coloreIntestazione = Colore.inchiostro2
            static let sottoIntestazione: CGFloat = 4
            static let titolo = Carattere(dimensione: 14.5, peso: .semibold)
            /// La scheda dei calcoli e le azioni stanno a 12 dal testo; fra le azioni 6.
            static let sopraScheda: CGFloat = 12
            static let sopraAzioni: CGFloat = 10
            static let spazioAzioni: CGFloat = 6
            /// Le proposte di Ruby: una tile con le righe divise dal filo.
            static let paddingProposta = Misura.padding(8, 12)
            static let proposta = Carattere(dimensione: 13.5, peso: .medium)
            static let nota = Carattere.secondario
            static let coloreNota = Colore.inchiostro2
            /// Spazio minimo lasciato libero accanto alla bolla dell'utente.
            static let respiroUtente: CGFloat = 90
            /// «Ci sto pensando…» accanto ai puntini mentre Qwen ragiona.
            static let spazioPuntini: CGFloat = 10
        }

        // MARK: Puntini «sta scrivendo» (§2.19)

        enum Puntini {
            static let lato: CGFloat = 7
            static let spazio: CGFloat = 4
            static let colore = Colore.inchiostro3
            /// `padding: 4px 0`.
            static let paddingVerticale: CGFloat = 4
            static let fotogrammi: Double = 30
        }

        // MARK: Suggerimenti e campo

        enum Campo {
            /// Suggerimenti a capsula: padding 8×14, 13 medium, `card` col filo `separatore`, spazio 8.
            static let suggerimento = Carattere(dimensione: 13, peso: .medium)
            static let paddingSuggerimento = Misura.padding(8, 14)
            static let fondoSuggerimento = Colore.card
            static let bordoSuggerimento = Colore.separatore
            static let coloreSuggerimento = Colore.inchiostro
            static let spazioSuggerimenti: CGFloat = 8
            /// La fila dei suggerimenti sfuma a destra: si capisce che continua.
            static let sfumaturaSuggerimenti: CGFloat = 40
            /// Il campo: capsula `cardPiena` col filo, ombra `card`, padding 6/6/6/18, testo 14,5.
            static let fondo = Colore.cardPiena
            static let bordo = Colore.separatore
            static let ombra = Ombra.card
            static let padding = EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 6)
            static let testo = Carattere(dimensione: 14.5, peso: .regular)
            static let coloreTesto = Colore.inchiostro
            static let spazio: CGFloat = 8
            /// Il pulsante d'invio tondo da 36 (accento, «↑») e il microfono (chip).
            static let tasto: CGFloat = Misura.Controllo.invio
            static let simboloTasto = Carattere(dimensione: 15, peso: .bold)
            static let fondoInvio = Colore.accento
            static let simboloInvio = Color.white
            static let fondoMicrofono = Colore.chip
            static let simboloMicrofono = Colore.inchiostro2
            static let fondoAscolto = Colore.rosso
            /// Il filo del campo mentre Ruby ascolta.
            static let filoAscolto: CGFloat = 1.5
            /// Spento (disabilitato): opacità.
            static let opacitaSpento: Double = 0.45
            static let segnaposto = "Chiedi una sintesi, un incontro, uno scenario…"
        }

        // MARK: Schede dei calcoli (§4.7)

        /// Modelli grafici fissi riempiti con le cifre dei motori di Prisma: tile col filo, `.lbl` e il totale 22 bold,
        /// le barre da 8 che si riempiono, le cifre che contano; sotto, la fonte in `.k`.
        enum SchedaCalcoli {
            static let superficie = Superficie.tile
            static let raggio: CGFloat = Raggio.tile
            static let padding = Misura.Padding.tile
            static let titolo = Carattere.etichetta
            static let coloreTitolo = Colore.inchiostro2
            static let totale = Carattere(dimensione: 22, peso: .bold, tracking: -0.4, tabellare: true)
            static let coloreTotale = Colore.inchiostro
            static let sottoTitolo: CGFloat = 12
            /// Una riga: etichetta `.k` larga 96, la barra, la cifra 13,5 semibold larga 96.
            static let etichetta = Carattere.secondario
            static let coloreEtichetta = Colore.inchiostro2
            static let larghezzaEtichetta: CGFloat = 96
            static let cifra = Carattere(dimensione: 13.5, peso: .semibold, tabellare: true)
            static let coloreCifra = Colore.inchiostro
            static let larghezzaCifra: CGFloat = 96
            static let fraRighe: CGFloat = 10
            static let fraColonne: CGFloat = 12
            /// La fonte delle cifre sotto la scheda.
            static let fonte = Carattere.secondario
            static let coloreFonte = Colore.inchiostro3
            static let simboloFonte = "doc.text"
            static let sopraFonte: CGFloat = 8
            static let spazioFonte: CGFloat = 5
            /// Larghezza massima della scheda dentro la bolla.
            static let larghezzaMassima: CGFloat = 520

            /// Il colore di una barra: quello del canale (Alleanza blu, indipendente cuoio) o quello dell'area.
            static func tinta(_ t: QuadroRuby.Tinta) -> Color {
                switch t {
                case .canale(let c): return AltreApp.canale(c)
                case .area(let a): return Tema.Colore.RubyScrivania.tinta(.area(a))
                }
            }
        }

        // MARK: Testata

        enum Testata {
            /// Fra il segmentato «Lavoro / Conversazione» e «Nuova conversazione».
            static let spazio: CGFloat = 8
        }
    }
}
