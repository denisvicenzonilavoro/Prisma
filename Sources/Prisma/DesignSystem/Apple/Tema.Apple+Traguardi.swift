import SwiftUI

// Gettoni dei traguardi festeggiati in Messaggi (versione «Luce», giro 5, Design/template-luce-specifica.md §5.4.2 e
// §5.4.3): il blocco `Tema.Apple.Messaggi.Traguardo` (biglietto, colonna «Il momento, già pronto») e i coriandoli
// (componente comune di §1.4, `Tema.Apple.Coriandoli` e `Tema.Apple.Moto.Coriandoli`). Il biglietto ha colori fissi nei
// due temi, come un oggetto da mandare; la colonna destra segue il tema. Le viste stanno in Shell/PannelloTraguardo.swift,
// Shell/BigliettoTraguardo.swift e DesignSystem/Apple/CoriandoliApple.swift.

extension Tema.Apple.Messaggi {
    enum Traguardo {
        // MARK: Biglietto

        /// 560×420, raggio 24, testo bianco, ombra 0 30 60 −24 nera al 45%.
        static let biglietto = CGSize(width: 560, height: 420)
        static let raggio = Tema.Apple.Raggio.finestra
        static let ombra = Color.black.opacity(0.45)
        static let ombraRaggio: CGFloat = 30
        static let ombraY: CGFloat = 30
        /// Fondo radiale 700×500 al 30%/20% dal colore del traguardo a #14202B.
        static let scuroFondo = Tema.Apple.Colore.notteProfonda
        static let centroFondo = UnitPoint(x: 0.3, y: 0.2)
        static let raggioFondo: CGFloat = 700
        static func fondo(_ colore: Color) -> RadialGradient {
            RadialGradient(colors: [colore, scuroFondo], center: centroFondo, startRadius: 0, endRadius: raggioFondo)
        }
        /// Il colore per tipo: obiettivo arancio, anniversario blu, mutuo verde, studi viola (proposte).
        static func tinta(_ t: TipoTraguardo) -> Color {
            switch t {
            case .obiettivoRaggiunto, .rendita: return Tema.Apple.Colore.arancio
            case .anniversario: return Tema.Apple.Colore.anello2
            case .mutuoEstinto: return Tema.Apple.Colore.anello1
            case .studiFigli: return Tema.Apple.Colore.anello3
            }
        }
        static let testo = Color.white
        /// 36 ai lati, 34 in alto.
        static let padding = EdgeInsets(top: 34, leading: 36, bottom: 34, trailing: 36)
        /// L'anello bianco pieno 96/10 con «✓» 34.
        static let anello: CGFloat = 96
        static let spessore: CGFloat = 10
        static let spunta = Tema.Apple.Carattere(dimensione: 34, peso: .bold)
        /// «Ce l’hai fatta, Sofia.»: display 42, 700, −1,2; 16 sopra.
        static let titolo = Tema.Apple.Carattere(dimensione: 42, peso: .bold, tracking: -1.2, interlinea: 1.05)
        static let sopraTitolo: CGFloat = 16
        /// La cifra 34/700 e la didascalia 17/500 all'80%.
        static let cifra = Tema.Apple.Carattere(dimensione: 34, peso: .bold, tabellare: true)
        static let didascalia = Tema.Apple.Carattere(dimensione: 17, peso: .medium)
        static let opacitaDidascalia: Double = 0.8
        static let spazioCifra: CGFloat = 8
        static let sopraCifra: CGFloat = 10
        /// La frase: 15, interlinea 1,55, al 90%, 14 sopra.
        static let frase = Tema.Apple.Carattere(dimensione: 15, peso: .regular, interlinea: 1.55)
        static let opacitaFrase: Double = 0.9
        static let sopraFrase: CGFloat = 14
        /// «— Denis»: 14 al 75%.
        static let firma = Tema.Apple.Carattere(dimensione: 14, peso: .regular)
        static let opacitaFirma: Double = 0.75
        static let sopraFirma: CGFloat = 10

        // MARK: Pannello

        /// «Da festeggiare · Obiettivo raggiunto ieri» sopra il titolo; 18 fra testata e colonne; 24 fra le colonne.
        static let sottoTestata: CGFloat = 18
        static let spazioColonne: CGFloat = 24
        /// Sotto questa larghezza del pannello la colonna destra va sotto il biglietto.
        static let larghezzaAffiancata: CGFloat = 900
        /// La colonna destra: righe con padding 13, filo sotto, 12 fra testo e pulsante.
        static let paddingRiga: CGFloat = 13
        static let spazioRiga: CGFloat = 12
        static let spazioTitoloRiga: CGFloat = 2
        static let titoloRiga = Tema.Apple.Carattere(dimensione: 14.5, peso: .bold)
        static let notaRiga = Tema.Apple.Carattere.secondario
        static let coloreTitoloRiga = Tema.Apple.Colore.inchiostro
        static let coloreNotaRiga = Tema.Apple.Colore.inchiostro2
        static let filo = Tema.Apple.Colore.separatore
        static let spessoreFilo = Tema.Apple.Misura.bordo
        static let etichetta = Tema.Apple.Carattere.etichetta
        static let coloreEtichetta = Tema.Apple.Colore.inchiostro2
        static let sottoEtichetta: CGFloat = 4
        /// La nota in fondo `.k`, interlinea 1,45.
        static let notaFondo = Tema.Apple.Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.45)
        static let coloreNotaFondo = Tema.Apple.Colore.inchiostro2
        static let sopraNotaFondo: CGFloat = 14
        /// «✓ In agenda», «✓ Annotata»: verde.
        static let coloreFatto = Tema.Apple.Colore.verde
        /// Il campo per scrivere l'idea del regalo.
        static let larghezzaCampo: CGFloat = 220
        /// «dati di prova» accanto al perché.
        static let prova = Tema.Apple.Messaggi.Pannello.prova
        static let coloreProva = Tema.Apple.Messaggi.Pannello.coloreProva
    }
}

// MARK: - Coriandoli (§1.4, §5.4.3)

extension Tema.Apple {
    /// I coriandoli dei traguardi: 70 rettangoli larghi 3-8 (alti la metà), nei colori del template.
    enum Coriandoli {
        static let numero = 70
        static let lato: ClosedRange<Double> = 3...8
        static let colori: [Color] = [Color.white, Color(hex: "#FFD60A"), Color(hex: "#5AC8FA"),
                                      Color(hex: "#FF9F0A"), Color(hex: "#C4B5FD")]
    }
}

extension Tema.Apple.Moto {
    /// Cadono a 40-100 pt/s, ondeggiano (sin(2t)·0,4 pt a fotogramma nel template: a 30 fotogrammi un'onda di 6 pt) e
    /// ruotano (2 rad/s); rientrano dall'alto fino a 6 s; svaniscono fra 5 e 8 s; poi la tela si ferma (niente ciclo
    /// infinito).
    enum Coriandoli {
        static let durataPioggia = 6.0
        static let inizioDissolvenza = 5.0
        static let fine = 8.0
        static let velocita: ClosedRange<Double> = 40...100
        static let rotazione = 2.0
        static let ondeggia = 6.0
        static let frequenzaOnda = 2.0
    }
}
