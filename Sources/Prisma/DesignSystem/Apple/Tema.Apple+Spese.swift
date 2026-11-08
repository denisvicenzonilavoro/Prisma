import SwiftUI

// Studio › Spese, «Chilometri, spese e scadenze» (Design/template-luce-specifica.md §6.3.2 e §6.3.3, template righe
// 2050-2061): misure, caratteri, colori e tempi delle tre card, dei fogli e del riepilogo su carta. Le viste stanno in
// Shell/StudioSpese.swift e Shell/FogliSpese.swift; qui solo i valori, ricavati dal tema Apple.

extension Tema.Apple.Studio {
    enum Spese {
        typealias Colore = Tema.Apple.Colore
        typealias Carattere = Tema.Apple.Carattere

        // MARK: Disposizione

        enum Disposizione {
            /// Tre colonne 1,1fr · 1fr · 1fr, 14 fra loro (il Cruscotto usa 16), alte quanto l'area.
            static let quote: [CGFloat] = [1.1, 1, 1]
            static let spazio: CGFloat = 14
            /// Sotto questa larghezza le tre card vanno in colonna: più larga del Cruscotto, perché sotto i 1.180 i titoli
            /// delle scadenze e il pulsante del pacchetto si taglierebbero.
            static let larghezzaColonna: CGFloat = 1180
            /// Sotto questa altezza le card non scendono: il resto scorre.
            static let altezzaMinima: CGFloat = 520
        }

        // MARK: Card

        enum Card {
            /// `.card .st` con padding 20×22 e senza ombra (`box-shadow:none`): la card piatta del tema.
            static let superficie = Tema.Apple.Superficie.cardPiatta
            static let raggio = Tema.Apple.Raggio.card
            static let padding = Tema.Apple.Misura.Padding.cardMedia
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            static let nota = Carattere.secondario
            static let coloreNota = Colore.inchiostro2
            /// La nota arancio («3 visite senza chilometri: aggiungili», «da controllare»).
            static let coloreAvviso = Colore.arancio
            static let prova = Carattere.secondario
            static let coloreProva = Colore.arancio
            static let spazioProva: CGFloat = 8
            /// La frase di uno stato vuoto e il suo pulsante.
            static let vuotoSopra: CGFloat = 12
            static let pulsanteSopra: CGFloat = 12
            /// I collegamenti in fondo agli elenchi («+ altre 14 visite», «+ Aggiungi a mano»).
            static let collegamento = Carattere.secondario
            static let coloreCollegamento = Colore.accento
            static let collegamentoSopra: CGFloat = 8
            static let riduzioneTesto: CGFloat = 0.8
        }

        // MARK: Card 1 · I chilometri

        enum Km {
            /// «412»: display 50 bold, −2,2, cifre tabellari, interlinea 1; 8 sotto la riga del titolo.
            static let numero = Carattere(dimensione: 50, peso: .bold, tracking: -2.2, interlinea: 1, tabellare: true)
            static let coloreNumero = Colore.inchiostro
            static let numeroSopra: CGFloat = 8
            /// «km» 18, 600, 6 sopra la base del numero; 10 fra numero e unità.
            static let unita = Carattere(dimensione: 18, peso: .semibold)
            static let sopraBase: CGFloat = 6
            static let spazioUnita: CGFloat = 10
            /// «almeno» prima del numero quando mancano dei km.
            static let almeno = Carattere.secondario
            /// Le frecce ‹ › del mese accanto al titolo.
            static let freccia = Carattere(dimensione: 12, peso: .semibold)
            static let coloreFreccia = Colore.inchiostro2
            static let spazioFrecce: CGFloat = 4
            /// L'elenco dei giri, 14 sotto la riga «22 visite · 14 clienti».
            static let elencoSopra: CGFloat = 14
            /// Righe dei giri visibili prima di «+ altre … visite».
            static let righeVisibili = 5
            /// «Chilometri per mese»: 22 sopra.
            static let graficoSopra: CGFloat = 22
            /// Il km corretto a mano: in `accento`, con il fumetto «corretto a mano».
            static let coloreCorretto = Colore.accento
        }

        // MARK: Righe degli elenchi

        enum Riga {
            /// Righe con padding 9, filo sotto, 13,5, spazio 12 (10 nelle spese).
            static let testo = Carattere(dimensione: 13.5, peso: .regular)
            static let forte = Carattere(dimensione: 13.5, peso: .bold, tabellare: true)
            static let colore = Colore.inchiostro
            static let padding: CGFloat = 9
            static let spazio: CGFloat = 12
            static let spazioSpese: CGFloat = 10
            static let filo = Colore.separatore
            /// La data del giro, larga 44, in grassetto.
            static let data: CGFloat = 44
            /// La data sotto la descrizione di una spesa: 12 `inchiostro2`.
            static let sotto = Carattere(dimensione: 12, peso: .regular)
            static let coloreSotto = Colore.inchiostro2
            /// La riga evidenziata (scontrino nuovo, da controllare): raggio 8, 6 di margine dentro.
            static let raggioEvidenza: CGFloat = 8
            static let margineEvidenza: CGFloat = 6
        }

        // MARK: Colonne dei km per mese

        enum Colonne {
            /// Area alta 110, 10 sotto l'etichetta; colonne fino a 86, 8 fra loro, raggi 5 sopra e 2 sotto.
            static let altezza: CGFloat = 110
            static let sopra: CGFloat = 10
            static let massima: CGFloat = 86
            static let spazio: CGFloat = 8
            static let raggioSopra: CGFloat = 5
            static let raggioSotto: CGFloat = 2
            /// La scala di partenza della colonna che cresce dal basso (quasi zero: a zero la forma non si disegna).
            static let scalaIniziale: CGFloat = 0.001
            /// L'iniziale del mese: 10,5 `inchiostro2`, 4 sopra.
            static let etichetta = Carattere(dimensione: 10.5, peso: .regular)
            static let coloreEtichetta = Colore.inchiostro2
            static let etichettaSopra: CGFloat = 4
            /// Il mese mostrato in `accento`, gli altri in `binario`.
            static let mese = Colore.accento
            static let altri = Colore.binario
        }

        // MARK: Card 2 · Le spese

        enum Spesa {
            /// Il totale `.v` (26 bold), 10 sopra.
            static let totale = Carattere.valore
            static let coloreTotale = Colore.inchiostro
            static let totaleSopra: CGFloat = 10
            static let elencoSopra: CGFloat = 12
            static let righeVisibili = 5
            /// Il pulsante «◎ Inquadra lo scontrino» (padding 5×11).
            static let paddingPulsante = Tema.Apple.Misura.padding(5, 11)
            /// La riga dello scontrino appena inquadrato: rgba(0,122,255,.08).
            static let evidenzaNuovo = Color(r: 0, g: 122, b: 255, a: 0.08)
            /// La riga da controllare: arancio all'8%.
            static let evidenzaControllo = Color(r: 224, g: 138, b: 0, a: 0.10)
        }

        enum Scontrino {
            /// La miniatura 26×32, raggio 4, fondo `chip`, bordo `separatore`.
            static let miniatura = CGSize(width: 26, height: 32)
            static let raggio: CGFloat = 4
            static let fondo = Colore.chip
            static let bordo = Colore.separatore
            static let simbolo = Carattere(dimensione: 11, peso: .regular)
            static let coloreSimbolo = Colore.inchiostro3
            /// L'anteprima grande nel dettaglio della spesa.
            static let anteprima = CGSize(width: 220, height: 300)
            static let raggioAnteprima: CGFloat = 10
        }

        // MARK: Card 3 · Le scadenze

        enum Scadenza {
            /// Righe con padding 10, filo, spazio 12; blocco data largo 44 centrato.
            static let padding: CGFloat = 10
            static let spazio: CGFloat = 12
            static let blocco: CGFloat = 44
            /// Il mese 10, 700 maiuscolo nel colore del tipo; il giorno 20, 600.
            static let mese = Carattere(dimensione: 10, peso: .bold, maiuscolo: true)
            static let giorno = Carattere(dimensione: 20, peso: .semibold, tabellare: true)
            static let coloreGiorno = Colore.inchiostro
            /// Titolo 14 bold, riga 12 `inchiostro2`.
            static let titolo = Carattere(dimensione: 14, peso: .bold)
            static let coloreTitolo = Colore.inchiostro
            static let riga = Carattere(dimensione: 12, peso: .regular)
            static let coloreRiga = Colore.inchiostro2
            /// Una scadenza passata e non segnata fatta: la riga in arancio.
            static let colorePassata = Colore.arancio
            /// Il cerchio per segnarla fatta.
            static let spunta: CGFloat = 18
            static let coloreSpunta = Colore.inchiostro3

            /// Il colore del mese secondo il tipo: fiscale #E08A00, polizza #0A84FF, aggiornamento #8B5CF6, altra `inchiostro2`.
            static func colore(_ t: TipoScadenza) -> Color {
                switch t {
                case .fiscale: return Colore.arancio
                case .polizza: return Colore.Area.investimenti
                case .aggiornamento: return Colore.stima
                case .altra: return Colore.inchiostro2
                }
            }
        }

        enum Ore {
            /// Anello da 70, spessore 8, viola #8B5CF6; al centro 13, 700; 12 sopra, 14 fra anello e testo.
            static let anello: CGFloat = 70
            static let spessore: CGFloat = 8
            static let colore = Colore.stima
            static let centro = Carattere(dimensione: 13, peso: .bold, tabellare: true)
            static let coloreCentro = Colore.inchiostro
            static let sopra: CGFloat = 12
            static let spazio: CGFloat = 14
            /// Il testo accanto: `.k` 12,5 con interlinea 1,45.
            static let testo = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.45)
            static let coloreTesto = Colore.inchiostro2
        }

        enum Pacchetto {
            /// La barra alta 8 (raggio 9) e la tile con il bordo verde al 40%, 10 sopra.
            static let barra: CGFloat = 8
            static let raggioBarra = Tema.Apple.Raggio.barra
            static let coloreBarra = Colore.accento
            static let sopra: CGFloat = 10
            static let tile = Tema.Apple.Superficie.tile
            static let raggioTile = Tema.Apple.Raggio.tile
            static let paddingTile = Tema.Apple.Misura.Padding.tile
            static let bordoFatto = Color(r: 47, g: 163, b: 90, a: 0.4)
            static let titolo = Carattere(dimensione: 13.5, peso: .bold)
            static let coloreFatto = Colore.verde
            static let coloreErrore = Colore.rosso
            static let spazioTile: CGFloat = 4
        }

        // MARK: Fogli e moduli

        enum Moduli {
            /// I fogli dello scontrino, della spesa, della scadenza, dei corsi e delle visite.
            static let foglio = CGSize(width: 560, height: 620)
            static let foglioLargo = CGSize(width: 640, height: 640)
            static let correzione = CGSize(width: 380, height: 230)
            /// La zona dove trascinare lo scontrino.
            static let zona: CGFloat = 180
            static let raggioZona = Tema.Apple.Raggio.tile
            static let bordoZona = Colore.separatore
            static let bordoZonaAttiva = Colore.accento
            static let fondoZona = Colore.chip
            static let tratteggioZona: [CGFloat] = [6, 5]
            static let spessoreZona: CGFloat = 1.5
            static let testoZona = Carattere.corpo
            static let coloreTestoZona = Colore.inchiostro2
            /// Larghezze dei campi.
            static let campoTesto: CGFloat = 300
            static let campoImporto: CGFloat = 120
            static let campoKm: CGFloat = 80
            static let sceltaPresso: CGFloat = 160
            static let spazio: CGFloat = 12
            static let spazioRighe: CGFloat = 8
            /// Le righe degli elenchi dei fogli (visite, corsi, spese).
            static let riga = Carattere(dimensione: 13, peso: .regular)
            static let rigaForte = Carattere(dimensione: 13, peso: .semibold)
            static let coloreRiga = Colore.inchiostro
            static let rigaSotto = Carattere(dimensione: 11.5, peso: .regular)
            static let coloreRigaSotto = Colore.inchiostro2
            static let coloreAvviso = Colore.arancio
            static let titoloGruppo = Carattere(dimensione: 12, peso: .semibold, tracking: 0.6, maiuscolo: true)
            static let coloreTitoloGruppo = Colore.inchiostro2
            static let filo = Colore.separatore
            static let paddingRiga: CGFloat = 7
            /// Fra la scelta della categoria e la nota «proposta da Prisma» sotto.
            static let spazioNota: CGFloat = 2
            /// Il pulsante principale finché il modulo non è completo.
            static let opacitaDisattivo: Double = 0.5
            /// Il velo sotto il modulo disegnato nelle istantanee (i fogli di sistema non si fotografano).
            static let velo = Color(r: 5, g: 12, b: 18, a: 0.30)
        }

        // MARK: Movimento

        enum Moto {
            /// Le colonne dei km: scala y 0 → 1 dal basso in 0,9 s, curva (.34, 1.3, .64, 1), ritardo 0,20 + i·0,05.
            static let colonne = 0.90
            static let ritardo = 0.20
            static let passo = 0.05
            static var animazioneColonne: Animation { Tema.Apple.Studio.Moto.curvaColonne.animazione(colonne) }
            static func ritardoColonna(_ i: Int) -> Double { ritardo + Double(i) * passo }
            /// La riga dello scontrino nuovo: da y −14 e scala 0,96, opacità 0, in 0,5 s con la molla (.34, 1.4, .64, 1).
            static let scontrino = 0.50
            static let spostamento: CGFloat = -14
            static let scala: CGFloat = 0.96
            static let curvaScontrino = Tema.Apple.Moto.Curva(x1: 0.34, y1: 1.4, x2: 0.64, y2: 1)
            static var animazioneScontrino: Animation { curvaScontrino.animazione(scontrino) }
        }

        // MARK: Il riepilogo su carta (PDF del pacchetto)

        enum Carta {
            /// A4 verticale, sempre chiara: i colori e i caratteri della carta della fattura.
            static let formato = Tema.Apple.CartaFattura.Misura.formato
            static let fondo = Tema.Apple.Carta.fondo
            static let testo = Tema.Apple.Carta.testo
            static let etichetta = Tema.Apple.Carta.etichetta
            static let filetto = Tema.Apple.Carta.filetto
            static let spessoreFiletto = Tema.Apple.Misura.bordo
            static let sopratitolo = Tema.Apple.Carta.sopratitolo
            static let logo = Tema.Apple.CartaFattura.Colore.logo
            static let altezzaLogo: CGFloat = 22
            static let margine = EdgeInsets(top: 48, leading: 52, bottom: 40, trailing: 52)
            static let titolo = Carattere(dimensione: 22, peso: .bold, tracking: -0.4)
            static let sottotitolo = Carattere(dimensione: 11, peso: .regular)
            static let sezione = Carattere(dimensione: 10, peso: .semibold, tracking: 0.6, maiuscolo: true)
            static let voce = Carattere(dimensione: 10.5, peso: .regular)
            static let voceForte = Carattere(dimensione: 10.5, peso: .semibold, tabellare: true)
            static let piede = Carattere(dimensione: 8.5, peso: .regular)
            static let spazioSezioni: CGFloat = 18
            static let paddingVoce: CGFloat = 4
            static let colonnaData: CGFloat = 70
            static let colonnaNumero: CGFloat = 70
            // La paginazione per altezza (le righe che non stanno continuano sulla pagina dopo), con stime prudenti dei
            // blocchi disegnati: una voce (10,5 pt più il padding 2 × 4), un'intestazione di sezione (con lo spazio sopra),
            // il titolo con il consulente, «Il mese» e il piede (fino a tre righe da 8,5 pt).
            static let altezzaVoce: CGFloat = 22
            static let altezzaSezione: CGFloat = 36
            static let altezzaTitoli: CGFloat = 50
            static let altezzaIlMese: CGFloat = 18
            static let altezzaPiede: CGFloat = 36
        }
    }
}
