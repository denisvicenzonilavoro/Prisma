import SwiftUI

// Gettoni delle Impostazioni a pagine (Design/tema-liquid-glass.html, impostazioni: .side-item con l'icona
// da 24, .set-h, .g-row, .pill, .g-note, kbd). Le pagine stanno in `SchedaImpostazioni` (StatoShell.swift);
// qui le loro icone di vetro, le misure della pagina e delle tessere della Panoramica.

extension Tema.Misura {
    enum Impostazioni {
        /// L'icona di vetro delle voci della barra laterale (.side-item .ic: 24).
        static let iconaVoce: CGFloat = 24
        /// L'icona di vetro di una riga (.ic piccola accanto al titolo) e delle tessere della Panoramica.
        static let iconaRiga: CGFloat = 26
        static let iconaTessera: CGFloat = 30
        /// Raggio dell'icona (.ic: 23,5% del lato) e grandezza del simbolo bianco sul vetro.
        static let raggioIcona: CGFloat = 0.235
        static let simboloIcona: CGFloat = 0.54
        /// L'ombra del simbolo bianco e il fondo a 165° (in proporzione al lato).
        static let ombraSimbolo: CGFloat = 0.02
        static let ombraSimboloY: CGFloat = 0.015
        static let inizioFondo = UnitPoint(x: 0.37, y: 0)
        static let fineFondo = UnitPoint(x: 0.63, y: 1)
        /// Oltre questi caratteri un sottotitolo può non stare nelle sue due righe: si legge intero al passaggio.
        static let caratteriSottotitolo = 70
        /// Spazio tra icona e titolo nelle voci e nelle righe.
        static let spazioIcona: CGFloat = 10
        /// La pagina: margini, spazio tra i gruppi, larghezza massima delle righe (oltre restano leggibili).
        static let marginePagina = EdgeInsets(top: 16, leading: 22, bottom: 22, trailing: 22)
        static let spazioGruppi: CGFloat = 18
        static let larghezzaPagina: CGFloat = 760
        /// Sotto il titolo della pagina (.set-h: margin 4px 0 16px).
        static let sottoTitolo: CGFloat = 2
        /// La nota sotto un gruppo (.g-note: margin -10px 6px): vicina al gruppo che spiega.
        static let notaSopra: CGFloat = -10
        static let rientroNota: CGFloat = 6
        /// Tessere di stato della Panoramica (.tile): larghezza minima di una colonna, spazio, margini.
        static let tesseraMinima: CGFloat = 200
        static let spazioTessere: CGFloat = Tema.Misura.Componenti.spazioTessere
        static let margineTessera = Tema.Misura.Componenti.tessera
        static let spazioTessera: CGFloat = 6
        /// L'avatar del profilo («DV» grande, .me.big).
        static let avatar: CGFloat = 52
        /// Il logo con il nome in fondo alla Panoramica.
        static let logo: CGFloat = Tema.Misura.Shell.logoImpostazioni
        /// La piccola griglia di una riga (Adeguata verifica: Alto, Medio, Basso; età di TCM e LTC).
        static let spazioGriglia: CGFloat = 10
        static let spazioEtichettaGriglia: CGFloat = 4
        static let menuGriglia: CGFloat = 118
        /// I numeri dell'archivio (clienti, appuntamenti, attività).
        static let spazioNumeri: CGFloat = 28
        /// Le scorciatoie: spazio tra i tasti di una combinazione.
        static let spazioTasti: CGFloat = 4
        /// Menu e campi delle righe.
        static let menuStretto: CGFloat = 140
        static let menuMedio: CGFloat = 170
        static let menuLargo: CGFloat = 210
        static let campoModello: CGFloat = 150
        static let campoIndirizzo: CGFloat = 190
        static let campoConfronto: CGFloat = 230
        static let campoNome: CGFloat = 200
        static let margineCampoNome: CGFloat = 14
    }
}

extension Tema.Testo {
    enum Impostazioni {
        /// Il titolo della pagina (.set-h: 22/700, -0,015em).
        static let titoloPagina = Tema.Testo.titoloImpostazioni
        static let spaziaturaTitolo = Tema.Testo.spaziaturaTitoloMedio
        /// La nota sotto il gruppo (.g-note: 12).
        static let nota = Tema.Testo.secondario
        /// Tessere della Panoramica: etichetta, valore 18/600, nota.
        static let etichettaTessera = Tema.Testo.occhiello
        static let valoreTessera = Tema.Testo.valoreTessera
        static let notaTessera = Tema.Testo.didascalia
        /// Nome nel profilo.
        static let nomeProfilo = Tema.Testo.nomeCliente
        /// Il simbolo bianco sull'icona di vetro, proporzionato al lato.
        static func simboloIcona(_ lato: CGFloat) -> Font {
            .system(size: lato * Tema.Misura.Impostazioni.simboloIcona, weight: .semibold)
        }
    }
}

extension Tema.Colore {
    enum Impostazioni {
        /// Il simbolo sull'icona di vetro (.ic .gw: bianco).
        static let simboloIcona = Color.white
        /// Riflesso dall'alto dell'icona (.ic::after) e filo di luce interno.
        static let riflessoIcona = [Color(r: 255, g: 255, b: 255, a: 0.36), Color(r: 255, g: 255, b: 255, a: 0.07),
                                    Color(r: 255, g: 255, b: 255, a: 0)]
        static let filoIcona = Color(r: 255, g: 255, b: 255, a: 0.3)
        static let ombraIcona = Color(r: 0, g: 0, b: 0, a: 0.22)
        /// I fondi delle icone di vetro delle pagine che non hanno l'icona di un'app (stesso schema di `Tema.Icona`).
        static let panoramica = Tema.Icona.scrivania
        static let promemoria = ColoriIconaApp(alto: Color(hex: "#FF7A6E"), basso: Color(hex: "#D33A2F"), tinta: Color(hex: "#FF9A90"))
        static let conformita = ColoriIconaApp(alto: Color(hex: "#6CCB8B"), basso: Color(hex: "#2E8A52"), tinta: Color(hex: "#8FDCA8"))
        static let rendimenti = ColoriIconaApp(alto: Color(hex: "#5BB8C9"), basso: Color(hex: "#2B7484"), tinta: Color(hex: "#86D0DD"))
        static let archivio = ColoriIconaApp(alto: Color(hex: "#7E9BB8"), basso: Color(hex: "#3D5A76"), tinta: Color(hex: "#A6BED6"))
        /// iPhone e iPad (Prisma ovunque): il blu della nuvola di iCloud Drive.
        static let ovunque = ColoriIconaApp(alto: Color(hex: "#5AB0FF"), basso: Color(hex: "#0A6CD6"), tinta: Color(hex: "#8CC8FF"))
        static let scorciatoie = ColoriIconaApp(alto: Tema.Icona.scuraAlto, basso: Tema.Icona.scuraBasso, tinta: Color(hex: "#C6CDD5"))
        static let strumenti = ColoriIconaApp(alto: Color(hex: "#B9A57E"), basso: Color(hex: "#7A6643"), tinta: Color(hex: "#D3C19C"))
        /// Le righe con l'icona (Panoramica e Strumenti): gli stessi fondi.
        static let voce = ColoriIconaApp(alto: Color(hex: "#B9A3F2"), basso: Color(hex: "#6862C9"), tinta: Color(hex: "#C7B5FF"))
        static let dati = ColoriIconaApp(alto: Color(hex: "#C9A584"), basso: Color(hex: "#8C6849"), tinta: Color(hex: "#D9B48E"))
    }
}

extension SchedaImpostazioni {
    /// L'icona della pagina: quella dell'app quando la pagina la riguarda (Profilo → Clienti, Vera…),
    /// altrimenti un simbolo bianco sul vetro colorato.
    enum Icona {
        case app(AppPrisma)
        case simbolo(String, ColoriIconaApp)
    }

    var icona: Icona {
        let c = Tema.Colore.Impostazioni.self
        switch self {
        case .panoramica: return .simbolo("square.grid.2x2.fill", c.panoramica)
        case .profilo: return .app(.clienti)
        case .aspetto: return .app(.impostazioni)
        case .ovunque: return .simbolo("icloud.fill", c.ovunque)
        case .lavoro: return .app(.agenda)
        case .promemoria: return .simbolo("bell.fill", c.promemoria)
        case .conformita: return .simbolo("checkmark.shield.fill", c.conformita)
        case .proposte: return .app(.documenti)
        case .rendimenti: return .simbolo("chart.line.uptrend.xyaxis", c.rendimenti)
        case .vera: return .app(.vera)
        case .archivio: return .simbolo("externaldrive.fill", c.archivio)
        case .scorciatoie: return .simbolo("keyboard", c.scorciatoie)
        case .studio: return .app(.studio)
        case .mercato: return .app(.mercato)
        case .portafogliModello: return .app(.posizioni)
        case .pratiche: return .app(.pratiche)
        case .sala: return .app(.sala)
        case .moduli: return .simbolo("doc.text.fill", c.conformita)
        case .strumenti: return .simbolo("wrench.and.screwdriver.fill", c.strumenti)
        }
    }
}
