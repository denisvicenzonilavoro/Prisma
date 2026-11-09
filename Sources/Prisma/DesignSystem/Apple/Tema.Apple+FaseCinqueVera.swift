import SwiftUI

// Gettoni della fase 5 di Vera (Vera/BRIEF.md, Design/template-vera.html): «Vera su misura» (22, le quattro tappe `.stg`,
// l'anteprima con i segnaposto in rubino), «Due velocità» (23, le due corsie `.lane` e la sfera che smista), «Il cervello
// grande» (25, i motori, le regole con l'interruttore bloccato `.sw.lock`, le bolle d'esempio) e l'etichetta del motore
// sotto ogni risposta. Il rubino del template (--ruby, #C2264B chiaro e #FF5C83 scuro) segna Vera; verde e blu vengono
// dal tema. Ogni funzione ha i suoi nomi, così una si può ritoccare senza toccare le altre.

extension Tema.Apple {
    /// La pagina «Vera su misura» sopra la chat (Shell/VisteSuMisuraVera.swift).
    enum SuMisura {
        static let rubino = Color.dinamico(chiaro: Color(hex: "#C2264B"), scuro: Color(hex: "#FF5C83"))
        /// Il fondo dei segnaposto (`rgba(194,38,75,.14)` del template).
        static let fondoSegnaposto = Color.dinamico(chiaro: Color(r: 194, g: 38, b: 75, a: 0.14), scuro: Color(r: 255, g: 92, b: 131, a: 0.20))
        static let velo = Color.dinamico(chiaro: Color(r: 220, g: 232, b: 240, a: 0.40), scuro: Color(r: 5, g: 12, b: 18, a: 0.50))
        static let fatto = Colore.verde
        static let spenta = Colore.inchiostro3
        static let barraOggi = Colore.inchiostro3
        static let avviso = Colore.arancio
        static let errore = Colore.rosso
        // La pagina
        static let marginePagina: CGFloat = 24
        static let larghezzaPagina: CGFloat = 980
        static let altezzaMassimaPagina: CGFloat = 640
        static let paddingPagina = Misura.padding(20, 22)
        static let superficiePagina = Superficie.dettaglio
        static let raggioPagina: CGFloat = Raggio.dettaglioAperto
        static let spazio: CGFloat = 14
        static let iconaIntestazione: CGFloat = 26
        static let titoloPagina = Carattere(dimensione: 17, peso: .bold)
        static let frase = Carattere.secondario
        static let durataCambio = 0.35
        // Le tappe (`.stg`: tratteggio spento, card accesa, numero verde «fatto»)
        static let paddingTappa = Misura.padding(16, 16)
        static let raggioTappa: CGFloat = Raggio.card
        static let superficieTappa = Superficie.cardPiatta
        static let trattoSpenta: CGFloat = 1.5
        static let trattino: [CGFloat] = [5, 4]
        static let opacitaSpenta: Double = 0.55
        static let numero: CGFloat = 26
        static let carattereNumero = Carattere(dimensione: 13, peso: .bold, tabellare: true)
        static let titoloTappa = Carattere(dimensione: 15, peso: .bold)
        static let testo = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.4)
        static let esempio = Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.6)
        static let segnaposto = Carattere(dimensione: 13.5, peso: .semibold)
        static let spazioTappa: CGFloat = 8
        static let paddingTile = Misura.padding(10, 12)
        static let superficieTile = Superficie.tile
        // La curva dell'errore e le barre
        static let altezzaCurva: CGFloat = 110
        static let spessoreCurva: CGFloat = 2.5
        static let altezzaBarra: CGFloat = 8
        static let altezzaBarraEsame: CGFloat = 12
        static let raggioBarra: CGFloat = 6
        static let percentuale = Carattere(dimensione: 13, peso: .bold, tabellare: true)
        static let rigaEsame = Carattere(dimensione: 13, peso: .regular)
        static let sfera: CGFloat = 34
        static let nomeVersione = Carattere(dimensione: 13.5, peso: .bold)
        // L'anteprima
        static let larghezzaAnteprima: CGFloat = 900
        static let spazioRighe: CGFloat = 8
        static let paddingRiga = Misura.padding(10, 14)
        static let raggioRiga: CGFloat = Raggio.voce
        static let fondoRiga = Color.dinamico(chiaro: Color(hex: "#FFFFFF"), scuro: Color(hex: "#283642"))
        static let bordoRiga = Color.dinamico(chiaro: Color(r: 0, g: 0, b: 0, a: 0.08), scuro: Color(r: 255, g: 255, b: 255, a: 0.09))
        static let domanda = Carattere(dimensione: 13, peso: .semibold, interlinea: 1.4)
        static let risposta = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.45)
        static let motivo = Carattere(dimensione: 11.5, peso: .regular)
        static let opacitaEsclusa: Double = 0.5
        static let righeRisposta = 4
    }

    /// La pagina «I motori di Vera», scheda «Due velocità» (Shell/VisteMotoriVera.swift).
    enum DueVelocita {
        static let veloce = Colore.verde
        static let profonda = Color.dinamico(chiaro: Color(hex: "#C2264B"), scuro: Color(hex: "#FF5C83"))
        static let spenta = Colore.inchiostro3
        static let paddingCorsia = Misura.padding(16, 16)
        static let superficieCorsia = Superficie.cardPiatta
        static let pallino: CGFloat = 12
        static let titoloCorsia = Carattere(dimensione: 16, peso: .bold)
        static let sottotitolo = Carattere.secondario
        static let spazioRighe: CGFloat = 7
        static let paddingRiga = Misura.padding(8, 12)
        static let superficieRiga = Superficie.tile
        static let riga = Carattere(dimensione: 13, peso: .regular)
        static let tempo = Carattere(dimensione: 12.5, peso: .bold, tabellare: true)
        static let piede = Carattere.secondario
        static let filoPiede: CGFloat = 1
        static let sopraPiede: CGFloat = 9
        static let colonnaCentro: CGFloat = 190
        static let sfera: CGFloat = 76
        static let sopraSfera: CGFloat = 30
        static let titoloCentro = Carattere(dimensione: 14, peso: .bold)
        static let spazioCorsie: CGFloat = 16
        static let nota = Carattere.secondario
        static let massimoRighe = 9
    }

    /// La pagina «I motori di Vera», scheda «Il cervello grande» (Shell/VisteMotoriVera.swift).
    enum CervelloGrande {
        static let larghezzaMotori: CGFloat = 470
        static let spazio: CGFloat = 10
        static let spazioColonne: CGFloat = 18
        static let paddingMotore = Misura.padding(14, 14)
        static let superficieMotore = Superficie.tile
        static let raggioMotore: CGFloat = Raggio.tile
        static let icona: CGFloat = 38
        static let raggioIcona: CGFloat = 12
        static let tratteggio: [CGFloat] = [5, 4]
        static let trattoTratteggio: CGFloat = 2
        static let trattoBordo: CGFloat = 1.5
        static let coloreTratteggio = Colore.inchiostro3
        /// Il quadrato del modello Apple nel template (`linear-gradient(135deg,#9FB3C2,#6B8199)`).
        static let appleChiaro = Color(hex: "#9FB3C2")
        static let appleScuro = Color(hex: "#6B8199")
        static let nomeMotore = Carattere(dimensione: 14.5, peso: .bold)
        static let sotto = Carattere.secondario
        static let paddingRegole = Misura.padding(4, 18)
        static let superficieRegole = Superficie.cardPiatta
        static let paddingRegola = Misura.padding(7, 0)
        static let titoloRegola = Carattere(dimensione: 13.5, peso: .bold)
        static let lucchetto = Carattere(dimensione: 10, peso: .bold)
        /// L'interruttore bloccato: acceso, grigio, con il lucchetto; un clic lo scuote.
        static let interruttoreBloccato = Colore.inchiostro3
        static let larghezzaInterruttore: CGFloat = 44
        static let altezzaInterruttore: CGFloat = 26
        static let manopola: CGFloat = 20
        static let scuotimento: CGFloat = 6
        static let scuotimenti: CGFloat = 3
        static let durataScuoti = 0.4
        static let paddingBolla = Misura.padding(10, 14)
        static let bolla = Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.45)
        static let fondoBollaMia = Colore.accento
        static let testoBollaMia = Color.white
        static let spazioBolle: CGFloat = 10
    }

    /// L'etichetta sotto ogni risposta di Vera (regola bloccata: sempre visibile).
    enum EtichettaMotore {
        static let sulMac = Colore.verde
        static let esterno = Colore.accento
        static let prisma = Colore.inchiostro3
        static let alfaFondo: Double = 0.13
        static let carattere = Carattere(dimensione: 11, peso: .semibold)
        static let padding = Misura.padding(3, 9)
        static let sopra: CGFloat = 8
    }
}
