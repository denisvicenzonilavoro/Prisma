import SwiftUI

// Gettoni di «La tua settimana, il tuo anno» (versione «Luce», giro 5, Design/template-luce-specifica.md §5.2.2 e
// §5.2.3): la storia a tutto palco con il testo sempre bianco su fondi colorati fissi, uguali in chiaro e in scuro (è
// una «sala», come la presentazione dei prospetti). Misure in pt del palco 1440×900. Le viste stanno in
// Shell/StoriaLuce.swift e Shell/PagineStoria.swift.

extension Tema.Apple.Colore {
    /// #14202B: il testo scuro dei pulsanti pieni della storia e il fondo del biglietto dei traguardi (una costante sola).
    static let notteProfonda = Color(hex: "#14202B")
}

extension Tema.Apple {
    enum Storia {
        /// Le coppie di colori dei fondi (chiaro al centro → scuro ai bordi). Dove il chiaro c'è già nel tema si riusa.
        enum Tinta: String, CaseIterable {
            case blu, viola, verde, rosso, ambra, mare, notte, corallo, cielo, prato, cuoio, lavanda

            var chiaro: Color {
                switch self {
                case .blu: return Color(hex: "#1F5F99")
                case .viola, .notte: return Color(hex: "#5B4BC8")
                case .verde: return Color(hex: "#1E9E6A")
                case .rosso: return Color(hex: "#C2363B")
                case .ambra: return Colore.arancio            // #E08A00
                case .mare: return Color(hex: "#2A6FA0")
                case .corallo: return Colore.rosso            // #E5484D
                case .cielo: return Colore.anello2            // #0A84FF
                case .prato: return Colore.anello1            // #30B15C
                case .cuoio: return Color(hex: "#B06E12")
                case .lavanda: return Colore.anello3          // #8B5CF6
                }
            }

            var scuro: Color {
                switch self {
                case .blu, .mare, .notte: return Color(hex: "#0F2433")
                case .viola, .lavanda: return Color(hex: "#26164F")
                case .verde, .prato: return Color(hex: "#0B3B2E")
                case .rosso, .corallo: return Color(hex: "#4A1420")
                case .ambra, .cuoio: return Color(hex: "#3D2A07")
                case .cielo: return Color(hex: "#0B2A4A")
                }
            }
        }

        /// Il fondo radiale 1200×800 centrato al 30%/20%: il raggio è proporzionale alla larghezza (1200 su 1440).
        static let centroFondo = UnitPoint(x: 0.3, y: 0.2)
        static let quotaRaggio: CGFloat = 1200.0 / 1440.0
        static func fondo(_ t: Tinta, larghezza: CGFloat) -> RadialGradient {
            RadialGradient(colors: [t.chiaro, t.scuro], center: centroFondo, startRadius: 0,
                           endRadius: max(1, larghezza * quotaRaggio))
        }

        /// Il testo è sempre bianco.
        static let testo = Color.white
        /// `.sS` all'82% nel template; al 90% per il contrasto sui fondi chiari (decisione 128: proposta).
        static let opacitaTesto: Double = 0.90
        /// Le cifre sotto le colonne (`opacity:.75`).
        static let opacitaGiorni: Double = 0.75

        /// `.sT` titolo 58, 700, −1,8, interlinea 1,05; `.sN` numero 110, 700, −4, tabellare; anno 150; `.sS` testo 22.
        static let titolo = Carattere(dimensione: 58, peso: .bold, tracking: -1.8, interlinea: 1.05)
        /// Il titolo lungo del momento dell'anno: interlinea 1,2, largo al massimo 760.
        static let titoloLungo = Carattere(dimensione: 58, peso: .bold, tracking: -1.8, interlinea: 1.2)
        static let numero = Carattere(dimensione: 110, peso: .bold, tracking: -4, interlinea: 1, tabellare: true)
        static let anno = Carattere(dimensione: 150, peso: .bold, tracking: -4, interlinea: 1, tabellare: true)
        static let testoPagina = Carattere(dimensione: 22, peso: .regular)
        static let sopraTesto: CGFloat = 10
        /// Il titolo sotto il logo: 30 sopra.
        static let sopraTitoloLogo: CGFloat = 30
        /// Le righe lunghe: 640 (da chiamare), 760 (momento), 560 (pallini).
        static let larghezzaTesto: CGFloat = 640
        static let larghezzaMomento: CGFloat = 760
        /// «dati di prova» in piccolo sulla prima pagina.
        static let prova = Carattere(dimensione: 13, peso: .semibold)
        static let opacitaProva: Double = 0.7

        /// Il logo bianco 64×64.
        static let logo: CGFloat = 64

        enum Barre {
            static let margineSinistro: CGFloat = 30
            static let margineDestro: CGFloat = 80
            static let alto: CGFloat = 22
            static let altezza: CGFloat = 4
            static let raggio = Raggio.barra
            static let spazio: CGFloat = 6
            static let binario = Color.white.opacity(0.3)
            static let piena = Color.white
        }

        enum Chiudi {
            static let lato: CGFloat = 36
            static let destra: CGFloat = 26
            static let alto: CGFloat = 12
            static let fondo = Color.white.opacity(0.18)
            static let carattere = Carattere(dimensione: 15, peso: .semibold)
        }

        enum Contenuto {
            static let margini = EdgeInsets(top: 60, leading: 80, bottom: 60, trailing: 80)
            /// Le zone di tocco cominciano 60 sotto il bordo (sopra ci sono barre e «✕»).
            static let sopraZone: CGFloat = 60
        }

        /// Avatar 74 sovrapposti di 16 con il bordo bianco 4 al 90%; grande 120 con il bordo 5 e le iniziali 40.
        static let avatar: CGFloat = 74
        static let sovrapposizione: CGFloat = 16
        static let bordoAvatar: CGFloat = 4
        static let coloreBordoAvatar = Color.white.opacity(0.9)
        static let avatarGrande: CGFloat = 120
        static let bordoAvatarGrande: CGFloat = 5
        static let coloreBordoAvatarGrande = Color.white
        static let sopraAvatar: CGFloat = 18

        enum Colonne {
            static let larghezza: CGFloat = 54
            static let altezzaMassima: CGFloat = 160
            static let contenitore: CGFloat = 180
            static let raggioAlto: CGFloat = 10
            static let raggioBasso: CGFloat = 4
            static let spazio: CGFloat = 22
            static let colore = Color.white.opacity(0.85)
            /// L'altezza minima di una colonna con un importo (perché si veda), e quella di un giorno vuoto.
            static let minima: CGFloat = 6
            static let vuota: CGFloat = 2
            static let sottoColonne: CGFloat = 8
            static let giorno = Carattere(dimensione: 15, peso: .semibold)
        }

        enum Pallini {
            static let lato: CGFloat = 34
            static let spazio: CGFloat = 10
            static let spento: Double = 0.35
            static let larghezza: CGFloat = 560
            /// Al più tanti pallini (poi il numero basta).
            static let massimo = 40
        }

        /// L'anello bianco pieno 190/18 con «✓» 58.
        static let anello: CGFloat = 190
        static let spessoreAnello: CGFloat = 18
        static let spunta = Carattere(dimensione: 58, peso: .bold)
        static let binarioAnello = Color.white.opacity(0.2)

        /// La linea bianca 560×120, tratto 5.
        static let linea = CGSize(width: 560, height: 120)
        static let spessoreLinea: CGFloat = 5

        /// Pulsante pieno bianco con il testo #14202B, 15 pt, 12/22; pulsante vetro bianco .18 con il bordo .3.
        static let pulsante = Carattere(dimensione: 15, peso: .semibold)
        static let paddingPulsante = EdgeInsets(top: 12, leading: 22, bottom: 12, trailing: 22)
        static let fondoPieno = Color.white
        static let testoPieno = Colore.notteProfonda
        static let fondoVetro = Color.white.opacity(0.18)
        static let bordoVetro = Color.white.opacity(0.3)
        static let spessoreBordoVetro: CGFloat = 1
        static let sopraPulsante: CGFloat = 26
        /// «Apri ›» discreto in fondo alle pagine che portano dove nasce la cifra (proposta).
        static let apri = Carattere(dimensione: 14, peso: .semibold)
        static let opacitaApri: Double = 0.8
    }
}

// MARK: - Invito sulla scrivania (§5.2.4, lunedì)

extension Tema.Apple.Storia {
    /// «La tua settimana è pronta»: il pallino accanto al pulsante della scrivania (blu della voce `storia`).
    enum Invito {
        static let pallino: CGFloat = 8
        static let colore = Tema.Apple.Colore.Glifi.storia
        static let testo = Tema.Apple.Carattere(dimensione: 12, peso: .semibold)
        static let coloreTesto = Tema.Apple.Colore.inchiostro2
        static let spazio: CGFloat = 6
    }
}

// MARK: - Movimento (§5.2.3)

extension Tema.Apple.Moto {
    enum Storia {
        /// Apertura 0,35 s (`ease`), chiusura 0,30 s.
        static let apre = 0.35
        static let chiude = 0.30
        static var animazioneApre: Animation { Curva.ease.animazione(apre) }
        static var animazioneChiude: Animation { Curva.ease.animazione(chiude) }
        /// Ogni pagina dura 5,2 s, anche con «Riduci movimento» (decisione 128: il tempo serve per leggere).
        static let durataPagina = 5.2
        /// Le barre nelle istantanee: la pagina corrente piena a metà.
        static let barraIstantanea: CGFloat = 0.5
        /// Elementi in cascata: da y +30, scala 0,96, sfocatura 10, in 0,85 s con `uscita`, ritardo 0,12 + i·0,17.
        static let durataEntrata = 0.85
        static let ritardoEntrata = 0.12
        static let passoEntrata = 0.17
        static let spostamentoEntrata: CGFloat = 30
        static let scalaEntrata: CGFloat = 0.96
        static let sfocaturaEntrata: CGFloat = 10
        static func ritardo(indice: Int) -> Double { ritardoEntrata + Double(indice) * passoEntrata }
        /// Salto (`.sP`): scala 0 → 1 in 0,6 s con la curva dei punti; avatar 0,5 + i·0,15, pallini 0,5 + i·0,08.
        static let salto = 0.6
        static var animazioneSalto: Animation { Tema.Apple.Studio.Moto.curvaPunti.animazione(salto) }
        static let ritardoSalti = 0.5
        static let passoAvatar = 0.15
        static let passoPallini = 0.08
        /// Colonne (`.sB`): dal basso in 0,8 s con la curva delle colonne, ritardo 0,6 + i·0,12.
        static let durataColonne = 0.8
        static var animazioneColonne: Animation { Tema.Apple.Studio.Moto.curvaColonne.animazione(durataColonne) }
        static let ritardoColonne = 0.6
        static let passoColonne = 0.12
        /// L'anello: 1,4 s dopo 0,5 s.
        static let ritardoAnello = 0.5
    }
}

extension Tema.Apple.Moto.StileEntrata {
    /// Gli elementi delle pagine della storia (`.sA`).
    static let storia = Tema.Apple.Moto.StileEntrata(durata: Tema.Apple.Moto.Storia.durataEntrata,
                                                     curva: Tema.Apple.Moto.Curva.uscita, spostamentoX: 0,
                                                     spostamentoY: Tema.Apple.Moto.Storia.spostamentoEntrata,
                                                     scala: Tema.Apple.Moto.Storia.scalaEntrata,
                                                     sfocatura: Tema.Apple.Moto.Storia.sfocaturaEntrata)
}
