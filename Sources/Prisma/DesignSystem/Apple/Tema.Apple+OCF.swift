import SwiftUI

// Studio › Esame OCF (Orizzonte giro 6, Design/template-novita-specifica.md §11): misure, caratteri, colori e tempi.
// La vista sta in Shell/StudioEsameOCF.swift; qui solo i valori, tutti ricavati dal tema Apple. Le percentuali
// arrivano da MotoreOCF, le domande dall'archivio del consulente.

extension Tema.Apple.Studio {
    enum OCF {
        // MARK: Disposizione

        enum Disposizione {
            /// Card 1 larga 520, la card 2 prende il resto; 16 fra loro.
            static let larghezzaPreparazione: CGFloat = 520
            static let spazio: CGFloat = 16
            /// Sotto questa larghezza le due card vanno una sotto l'altra (iPhone, finestre strette).
            static let larghezzaColonna: CGFloat = 900
            /// Nella colonna la card della domanda ha almeno questa altezza.
            static let altezzaMinimaDomanda: CGFloat = 520
        }

        // MARK: Colori (uguali in chiaro e in scuro, come nel template)

        enum Colore {
            /// Anello e materia sopra la domanda: viola #8B5CF6.
            static let anello = Tema.Apple.Colore.anello3
            static let materia = Tema.Apple.Colore.anello3
            /// Fasce delle materie: verde da 70, arancio da 55, rosso sotto; senza dato il binario resta vuoto.
            static let verde = Tema.Apple.Colore.anello1
            static let arancio = Tema.Apple.Colore.arancio
            static let rosso = Tema.Apple.Colore.rosso
            static let nessuna = Tema.Apple.Colore.inchiostro3
            /// Opzione giusta: bordo #30B15C, fondo verde al 10%, cerchio pieno verde con la lettera bianca.
            static let bordoGiusta = Tema.Apple.OpzioneLettera.bordoGiusta
            static let fondoGiusta = Tema.Apple.OpzioneLettera.fondoGiusta
            /// Opzione sbagliata scelta: bordo #E5484D, fondo rosso all'8%.
            static let bordoSbagliata = Tema.Apple.OpzioneLettera.bordoSbagliata
            static let fondoSbagliata = Tema.Apple.OpzioneLettera.fondoSbagliata
            static let letteraPiena = Tema.Apple.OpzioneLettera.letteraPiena
            /// Bordo della spiegazione: verde al 40% o rosso al 35%.
            static let bordoSpiegazioneGiusta = Color(r: 47, g: 163, b: 90, a: 0.40)
            static let bordoSpiegazioneSbagliata = Color(r: 229, g: 72, b: 77, a: 0.35)
            /// «Giusto.» in verde, «Non proprio…» in rosso.
            static let titoloGiusto = Tema.Apple.Colore.verde
            static let titoloSbagliato = Tema.Apple.Colore.rosso
            /// Le altre opzioni a domanda chiusa.
            static let opacitaAttenuata: Double = 0.5
            /// Fondo della materia scelta per allenarsi solo su quella.
            static let materiaScelta = Tema.Apple.Colore.selezioneVoce
        }

        /// Il colore della barra di una materia secondo la fascia.
        static func colore(_ f: MotoreOCF.Fascia) -> Color {
            switch f {
            case .verde: return Colore.verde
            case .arancio: return Colore.arancio
            case .rossa: return Colore.rosso
            case .nessuna: return Colore.nessuna
            }
        }

        // MARK: Card

        enum Card {
            static let superficie = Tema.Apple.Superficie.card
            static let raggio = Tema.Apple.Raggio.card
            /// Card 1: padding 22 / 24; card 2: 26 / 30.
            static let paddingPreparazione = Tema.Apple.Misura.Padding.cardGrande
            static let paddingDomanda = Tema.Apple.Misura.Padding.dettaglio
            static let etichetta = Tema.Apple.Carattere.etichetta
            static let coloreEtichetta = Tema.Apple.Colore.inchiostro2
            static let nota = Tema.Apple.Carattere.secondario
            static let coloreNota = Tema.Apple.Colore.inchiostro2
            /// «dati di prova» accanto all'etichetta (come le altre card di Studio).
            static let prova = Tema.Apple.Studio.Card.prova
            static let coloreProva = Tema.Apple.Studio.Card.coloreProva
            static let spazioProva = Tema.Apple.Studio.Card.spazioProva
        }

        // MARK: Card 1 · La tua preparazione

        enum Preparazione {
            /// Anello singolo da 130, spessore 14, 12 sotto l'etichetta, 20 dai testi a destra.
            static let anello: CGFloat = 130
            static let spessoreAnello: CGFloat = 14
            static let anelloSopra: CGFloat = 12
            static let spazioAnello: CGFloat = 20
            /// Il numero al centro: display 28 bold, cifre tabellari.
            static let centro = Tema.Apple.Carattere.centroAnello(28)
            static let coloreCentro = Tema.Apple.Colore.inchiostro
            /// «Esame OCF»: display 20 bold.
            static let titolo = Tema.Apple.Carattere(dimensione: 20, peso: .bold)
            static let coloreTitolo = Tema.Apple.Colore.inchiostro
            /// Le due righe sotto: `.k` a 13,5, interlinea 1,5.
            static let riga = Tema.Apple.Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.5)
            static let coloreRiga = Tema.Apple.Colore.inchiostro2
            static let spazioRighe: CGFloat = 2
            static let pulsanteSopra: CGFloat = 8
            /// Le materie: 16 sotto la riga, 12 fra loro; nome 13, percentuale 13 bold, barra da 8 a 5 dal testo.
            static let materieSopra: CGFloat = 16
            static let spazioMaterie: CGFloat = 12
            static let materia = Tema.Apple.Carattere(dimensione: 13, peso: .regular)
            static let percentuale = Tema.Apple.Carattere(dimensione: 13, peso: .bold, tabellare: true)
            static let coloreMateria = Tema.Apple.Colore.inchiostro
            static let barra: CGFloat = 8
            static let raggioBarra = Tema.Apple.Raggio.barra
            static let barraSopra: CGFloat = 5
            /// Il fondo della materia scelta sporge di poco attorno alla riga.
            static let paddingMateria = Tema.Apple.Misura.padding(4, 8)
            static let raggioMateria: CGFloat = 10
            /// La nota in fondo: `.k` 12,5, 14 sopra.
            static let notaSopra: CGFloat = 14
            /// Il riquadro della data dell'esame, 14 sotto le materie.
            static let riquadroSopra: CGFloat = 14
            static let riquadro = Tema.Apple.Superficie.tile
            static let raggioRiquadro = Tema.Apple.Raggio.tile
            static let paddingRiquadro = Tema.Apple.Misura.Padding.tile
            static let spazioRiquadro: CGFloat = 10
            static let titoloRiquadro = Tema.Apple.Carattere.titoloRiga
            static let coloreTitoloRiquadro = Tema.Apple.Colore.inchiostro
            static let spazioPulsanti: CGFloat = 8
        }

        // MARK: Card 2 · La domanda

        enum Domanda {
            /// Riga alta: materia in `.lbl` viola, «domanda 1 di 3» in `.k` 12,5.
            static let contatore = Tema.Apple.Carattere.secondario
            static let coloreContatore = Tema.Apple.Colore.inchiostro2
            static let spazioRigaAlta: CGFloat = 12
            /// Il testo: display 26 bold, −0,5, interlinea 1,25, 14 sopra e 18 sotto, al più 720.
            static let testo = Tema.Apple.Carattere(dimensione: 26, peso: .bold, tracking: -0.5, interlinea: 1.25)
            static let coloreTesto = Tema.Apple.Colore.inchiostro
            static let testoSopra: CGFloat = 14
            static let testoSotto: CGFloat = 18
            static let larghezzaTesto: CGFloat = 720
            /// «Solo: <materia> ✕» sopra la domanda quando ci si allena su una materia.
            static let filtroSopra: CGFloat = 10
            /// Il piede: 30 dai lati, 24 dal fondo; nota del ripasso `.k`, pulsante primario grande.
            static let piedeLati = Tema.Apple.Misura.Padding.piedeDettaglioLati
            static let piedeFondo = Tema.Apple.Misura.Padding.piedeDettaglioFondo
            static let piedeSopra: CGFloat = 14
            static let spazioPiede: CGFloat = 16
        }

        // MARK: Opzioni

        /// Le risposte con la lettera: i gettoni comuni di `OpzioneLettera` (DesignSystem/Apple/OpzioneLettera.swift).
        typealias Opzione = Tema.Apple.OpzioneLettera

        // MARK: Spiegazione

        enum Spiegazione {
            /// `.tile`: raggio 18, padding 14 / 16, 14 sotto le opzioni.
            static let superficie = Tema.Apple.Superficie.tile
            static let raggio = Tema.Apple.Raggio.tile
            static let padding = Tema.Apple.Misura.Padding.tile
            static let sopra: CGFloat = 14
            static let bordo: CGFloat = 1
            /// Titolo 16 bold colorato, con la spunta disegnata se è giusta; testo 14 interlinea 1,5, 4 sopra.
            static let titolo = Tema.Apple.Carattere(dimensione: 16, peso: .bold)
            static let testo = Tema.Apple.Carattere(dimensione: 14, peso: .regular, interlinea: 1.5)
            static let coloreTesto = Tema.Apple.Colore.inchiostro
            static let testoSopra: CGFloat = 4
            static let spunta: CGFloat = 18
            static let spazioTitolo: CGFloat = 8
            /// La fonte della domanda, in `.k` sotto la spiegazione.
            static let fonte = Tema.Apple.Carattere.secondario
            static let coloreFonte = Tema.Apple.Colore.inchiostro2
            static let fonteSopra: CGFloat = 6
            /// Il pulsante del caso vero, 10 sopra, con il segno ◎.
            static let casoSopra: CGFloat = 10
            static let segnoCaso = "◎"
        }

        // MARK: Stati della card 2 (vuoto, ripasso finito, riepilogo, errore)

        enum Stato {
            static let larghezza: CGFloat = 560
            static let titolo = Tema.Apple.Carattere.h2
            static let coloreTitolo = Tema.Apple.Colore.inchiostro
            static let testo = Tema.Apple.Carattere(dimensione: 14, peso: .regular, interlinea: 1.5)
            static let coloreTesto = Tema.Apple.Colore.inchiostro2
            static let spazio: CGFloat = 10
            static let pulsantiSopra: CGFloat = 8
            static let spazioPulsanti: CGFloat = 10
            /// Il riepilogo dell'importazione: `.tile` con le tre cifre (nuove, aggiornate, scartate).
            static let riepilogo = Tema.Apple.Superficie.tile
            static let raggioRiepilogo = Tema.Apple.Raggio.tile
            static let paddingRiepilogo = Tema.Apple.Misura.Padding.tile
            static let cifra = Tema.Apple.Carattere.valore
            static let coloreCifra = Tema.Apple.Colore.inchiostro
            static let coloreScartate = Tema.Apple.Colore.arancio
            static let spazioCifre: CGFloat = 24
            static let righeScartate = Tema.Apple.Carattere.secondario
            static let coloreRigheScartate = Tema.Apple.Colore.inchiostro2
            static let massimoScartateMostrate = 6
            /// L'errore: bordo arancio (`avvisoFondo` / `avvisoBordo`).
            static let fondoErrore = Tema.Apple.Colore.avvisoFondo
            static let bordoErrore = Tema.Apple.Colore.avvisoBordo
            static let raggioErrore = Tema.Apple.Raggio.voce
            static let paddingErrore = Tema.Apple.Misura.Padding.tile
            static let titoloErrore = Tema.Apple.Carattere.titoloRiga
        }

        // MARK: Movimento

        enum Moto {
            /// Colori e opacità delle opzioni e spostamento al passaggio: 0,30 s `ease`.
            static let durataOpzione = 0.30
            static var opzione: Animation { Tema.Apple.Moto.Curva.ease.animazione(durataOpzione) }
            /// Tremolio della risposta sbagliata: 0 → −8 → +8 → −5 → 0 in 0,38 s, a passo lineare.
            static let durataTremolio = 0.38
            static let passiTremolio: [CGFloat] = [0, -8, 8, -5, 0]
            static var animazioneTremolio: Animation { .linear(duration: durataTremolio) }
            /// Lo spostamento del tremolio a una fase 0…1 (interpolazione lineare fra i passi).
            static func spostamentoTremolio(fase: CGFloat) -> CGFloat {
                let t = min(max(fase, 0), 1)
                let segmenti = CGFloat(passiTremolio.count - 1)
                let x = t * segmenti
                let i = min(Int(x), passiTremolio.count - 2)
                let f = x - CGFloat(i)
                return passiTremolio[i] + (passiTremolio[i + 1] - passiTremolio[i]) * f
            }
            /// La spiegazione entra da y +10 in 0,45 s `uscita`.
            static let durataSpiegazione = 0.45
            static let spostamentoSpiegazione: CGFloat = 10
            static var spiegazione: Animation { Tema.Apple.Moto.uscita(durataSpiegazione) }
            /// Prossima domanda: la vecchia esce a x −30 in 0,16 s lineare, la nuova entra da x +40 in 0,48 s `uscita`.
            static let durataUscitaDomanda = 0.16
            static let spostamentoUscitaDomanda: CGFloat = -30
            static let durataEntrataDomanda = 0.48
            static let spostamentoEntrataDomanda: CGFloat = 40
            static var uscitaDomanda: Animation { .linear(duration: durataUscitaDomanda) }
            static var entrataDomanda: Animation {
                Tema.Apple.Moto.uscita(durataEntrataDomanda).delay(durataUscitaDomanda)
            }
            /// Il riquadro della data: entra come i riquadri che salgono (molla 0,45 s).
            static var riquadro: Animation { Tema.Apple.Moto.RiquadroSopra.animazione }
            /// Con «Riduci movimento»: dissolvenza di 0,15 s.
            static var calma: Animation { Tema.Moto.dissolvenzaCalma }
        }
    }
}
