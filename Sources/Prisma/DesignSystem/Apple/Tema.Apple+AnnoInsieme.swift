import SwiftUI

// Gettoni della carta del report «Un anno insieme» (Design/template-apple-specifica.md §1.2 «Carta» e §4.5.2;
// pagina di riferimento del template: `.paper`, `.pl`, `h3`, `.ps`, `.kp`, `.sec`, `.tx`, `.foot` e la linea
// «I momenti dell'anno»). La carta è sempre chiara: carta bianca, colori opachi e fissi, niente vetro.
// Le pagine stanno in Shell/ReportAnnoInsieme.swift. Il foglio del template è verticale (600×848); il report per
// il cliente, come tutti i report di Prisma, è A4 orizzontale: le stesse misure su due colonne.

extension Tema.Apple {
    enum CartaAnno {
        // MARK: Colori (dalla Carta del §1.2)

        enum Colore {
            static let fondo = Carta.fondo
            static let titolo = Carta.testo
            static let sottotitolo = Carta.sottotitolo
            static let testo = Carta.testoCorrente
            static let etichetta = Carta.etichetta
            static let piede = Carta.piede
            static let filetto = Carta.filetto
            static let linea = Carta.linea
            static let binario = Carta.binario
            static let binarioBlu = Carta.binarioBlu
            static let binarioRosso = Carta.binarioRosso
            static let sopratitolo = Carta.sopratitolo
            static let positivo = Carta.positivo
            static let ambra = Carta.ambra
            static let rosso = Carta.rosso
            static let bluGrafico = Carta.bluGrafico
            /// L'avanzamento al 1° gennaio, sotto quello di oggi: il blu del grafico schiarito al 32% sul bianco,
            /// già pieno (sulla carta niente trasparenze).
            static let bluInizio = Color(hex: "#B1D8FF")
            /// Il logo di Prisma sulla carta (#0F2433).
            static let logo = Color(hex: "#0F2433")
            /// I colori del canale da stampa (blu Alleanza, cuoio indipendente), opachi.
            static let alleanza = Tema.Colore.canaleAlleanzaStampa
            static let indipendente = Tema.Colore.canaleIndipendenteStampa

            /// Il colore di un momento sulla linea dell'anno.
            static func momento(_ tono: AnnoInsieme.TonoMomento) -> Color {
                switch tono {
                case .incontro, .novita: return sopratitolo
                case .mercato: return ambra
                case .traguardo: return positivo
                }
            }

            static func canale(_ c: Canale) -> Color { c == .alleanza ? alleanza : indipendente }
        }

        // MARK: Caratteri

        enum Testo {
            typealias C = Tema.Apple.Carattere
            /// `.pl`: «IL 2026 DI GIULIA ROSSI».
            static let sopratitolo = C(dimensione: 11, peso: .bold, tracking: 1.4, maiuscolo: true)
            /// `h3` della prima pagina: «Un anno insieme.».
            static let titolo = C.titoloCarta
            /// Titolo delle pagine interne (lo stesso `h3`, più piccolo per lasciare posto alle cifre).
            static let titoloPagina = C(dimensione: 26, peso: .bold, tracking: -0.6, interlinea: 1.05)
            /// `.ps`.
            static let sottotitolo = C(dimensione: 13, peso: .regular, interlinea: 1.5)
            /// Intestazione con il canale (11 semibold; spaziato 0,8 invece di 1: il testo del PDF resta una frase sola).
            static let intestazione = C(dimensione: 11, peso: .semibold, tracking: 0.8, maiuscolo: true)
            /// `.kp small` e `.kp b`.
            static let kpiEtichetta = C(dimensione: 10.5, peso: .regular)
            static let kpiValore = C(dimensione: 19, peso: .bold, tabellare: true)
            static let kpiNota = C(dimensione: 10.5, peso: .medium)
            /// `.sec`: «I MOMENTI DELL'ANNO».
            static let sezione = C(dimensione: 11.5, peso: .bold, tracking: 0.4, maiuscolo: true)
            /// `.tx`.
            static let corpo = C(dimensione: 12.5, peso: .regular, interlinea: 1.55)
            static let elenco = C(dimensione: 12.5, peso: .regular, interlinea: 1.8)
            /// Righe delle tabelle e degli elenchi.
            static let riga = C(dimensione: 11.5, peso: .regular)
            static let rigaForte = C(dimensione: 11.5, peso: .semibold)
            static let rigaCifra = C(dimensione: 11.5, peso: .semibold, tabellare: true)
            static let rigaNota = C(dimensione: 10, peso: .regular)
            static let testaTabella = C(dimensione: 9.5, peso: .bold, tracking: 0.6, maiuscolo: true)
            /// La percentuale degli obiettivi.
            static let percento = C(dimensione: 15, peso: .bold, tabellare: true)
            /// Linea dell'anno: mese (9,5 bold, colore del momento) e titolo (10,5).
            static let meseMomento = C(dimensione: 9.5, peso: .bold, maiuscolo: true)
            static let titoloMomento = C(dimensione: 10.5, peso: .regular)
            /// `.foot`: le avvertenze in 9 pt.
            static let piede = C(dimensione: 9, peso: .regular, interlinea: 1.4)
            static let numeroPagina = C(dimensione: 9, peso: .medium, tabellare: true)
        }

        // MARK: Misure

        enum Misura {
            /// A4 orizzontale, come tutti i report per il cliente.
            static let formato = Misure.Documento.report
            /// `.paper{padding:40px 46px}`; il piede a 26 dal fondo.
            static let margineAlto: CGFloat = 40
            static let margineLati: CGFloat = 46
            static let piedeDalFondo: CGFloat = 24
            static let sopraPiede: CGFloat = 8
            /// Lo spazio tenuto per il piede (tre righe di avvertenze in 9 pt e il filetto): il contenuto si ferma prima.
            static let spazioPiede: CGFloat = 52
            static let filetto: CGFloat = 1
            /// Logo dell'intestazione (22) e spazio dal testo.
            static let logo: CGFloat = 22
            static let simboloAlleanza: CGFloat = 16
            static let spazioLogo: CGFloat = 8
            /// Dall'intestazione al sopratitolo (34 nel template; qualcosa meno sulle pagine interne).
            static let sottoIntestazione: CGFloat = 30
            static let sottoIntestazioneInterna: CGFloat = 22
            static let sottoSopratitolo: CGFloat = 6
            static let sottoTitolo: CGFloat = 8
            /// Le due colonne della prima pagina.
            static let colonnaSinistra: CGFloat = 352
            static let spazioColonne: CGFloat = 40
            /// Colonna destra delle pagine interne (incontri, da completare, prossimi passi).
            static let colonnaLaterale: CGFloat = 250
            /// `.kp`: bordo 1, raggio 10, padding 10×12; 10 fra un riquadro e l'altro, 22 sopra la fila.
            static let kpiRaggio: CGFloat = Raggio.kpiCarta
            static let kpiPadding = EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
            static let spazioKpi: CGFloat = 10
            static let sopraKpi: CGFloat = 22
            static let righeKpi: CGFloat = 3
            /// `.sec{margin-top:22px}` e `.tx{margin-top:6px}`.
            static let sopraSezione: CGFloat = 22
            static let sottoSezione: CGFloat = 6
            /// Linea dell'anno (svg 508×110): linea a 55, spessore 2, cerchi di raggio 7 con bordo 3; mese e titolo
            /// sopra (centri a 32 e 16) o sotto (78 e 94), alternati.
            static let lineaAltezza: CGFloat = 110
            static let lineaY: CGFloat = 55
            static let lineaSpessore: CGFloat = 2
            static let lineaRientro: CGFloat = 10
            static let cerchio: CGFloat = 14
            static let cerchioBordo: CGFloat = 3
            static let meseSopra: CGFloat = 32
            static let titoloSopra: CGFloat = 16
            static let meseSotto: CGFloat = 78
            static let titoloSotto: CGFloat = 94
            static let titoloMomentoMassimo: CGFloat = 150
            /// Righe di tabelle ed elenchi: altezza minima, spazio, filetto.
            static let riga: CGFloat = 24
            static let spazioRiga: CGFloat = 6
            /// Tra l'etichetta del canale e il nome della posizione (etichetta sopra, nome sotto).
            static let spazioNomeCanale: CGFloat = 2
            static let pallino: CGFloat = 7
            /// Barre degli obiettivi (`height:10px; border-radius:6px`) e della protezione (26, raggio 8).
            static let barra: CGFloat = 10
            static let raggioBarra: CGFloat = 6
            static let barraProtezione: CGFloat = 22
            static let raggioBarraProtezione: CGFloat = 8
            static let barraMinima: CGFloat = 3
            static let spazioBarre: CGFloat = 4
            static let colonnaPercento: CGFloat = 150
            /// Colonne delle cifre nelle tabelle.
            static let colonnaCifra: CGFloat = 92
            /// Larga per «30 settembre 2027» su una riga.
            static let colonnaData: CGFloat = 128
        }

        // MARK: Quante righe stanno in una pagina fissa

        enum Righe {
            /// Righe più alte (etichetta del canale sopra il nome): 5 stanno nella pagina.
            static let posizioni = 5
            static let incontri = 3
            static let scelte = 2
            static let obiettivi = 5
            static let coperture = 5
            static let daCompletare = 4
            static let scadenze = 7
            static let passi = 5
            static let primaPagina = 3
        }
    }
}
