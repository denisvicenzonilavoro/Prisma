import SwiftUI

// Gettoni della scheda che si inclina e del dettaglio che nasce dall'elemento
// (Design/template-apple-specifica.md §2.6, §2.7). I componenti stanno in SchedeApple.swift e DettaglioApple.swift.

// MARK: - Misure

extension Tema.Apple.Misura {
    /// Riflesso di luce delle schede inclinabili (`.sheen`): `radial-gradient(260px 200px at x y, …, transparent 60%)`.
    enum RiflessoInclinazione {
        /// Raggio orizzontale dell'ellisse.
        static let raggioOrizzontale: CGFloat = 260
        /// Raggio verticale dell'ellisse.
        static let raggioVerticale: CGFloat = 200
        /// Il colore svanisce al 60% del raggio.
        static let fineSfumatura: CGFloat = 0.6
    }

    /// Dettaglio aperto: misure W×H del contenitore e pulsante ✕.
    enum DettaglioAperto {
        /// Predefinito.
        static let predefinito = CGSize(width: 900, height: 540)
        /// Scheda «Da fare».
        static let daFare = CGSize(width: 880, height: 520)
        static let obiettivo = CGSize(width: 920, height: 520)
        /// Aree Previdenza e Protezione di Analisi 360.
        static let previdenzaProtezione = CGSize(width: 940, height: 540)
        static let investimenti = CGSize(width: 900, height: 480)
        static let liquidita = CGSize(width: 900, height: 440)
        /// Impegno dell'agenda.
        static let impegno = CGSize(width: 860, height: 500)

        /// Area in cui il dettaglio si centra, dentro una finestra: il contenuto parte a 92 dall'alto
        /// e lascia 12 in basso (x = (larghezza − W)/2, y = 92 + (area − H)/2).
        static let areaFinestra = EdgeInsets(top: Tema.Apple.Misura.Finestra.altoContenuto, leading: 0,
                                             bottom: Tema.Apple.Misura.Finestra.margineContenuto, trailing: 0)

        /// ✕ del dettaglio: `.btn` con padding 7×11.
        static let paddingChiudi = Tema.Apple.Misura.padding(7, 11)
    }
}

// MARK: - Tempi

extension Tema.Apple.Moto.Inclinazione {
    /// Rotazione X = (0,5 − y)·massimo·0,8 gradi.
    static let fattoreX: Double = 0.8
    /// iPhone e iPad: scala alla pressione.
    static let scalaPressione: CGFloat = 0.98
    /// Pressione: durata minima irraggiungibile (la pressione resta «in corso» finché il dito è giù).
    static let durataPressione: Double = 60
    /// Pressione: oltre questo spostamento (scorrimento) la scheda torna a riposo.
    static let distanzaPressione: CGFloat = 10
    /// Ombra `inclinata` al passaggio (`box-shadow .4s`, curva `ease`).
    static var animazioneOmbra: Animation { Tema.Apple.Moto.Curva.ease.animazione(ombra) }
    /// Riflesso che compare (`opacity .3s`, curva `ease`).
    static var animazioneRiflesso: Animation { Tema.Apple.Moto.Curva.ease.animazione(riflesso) }
}

extension Tema.Apple.Moto.DettaglioApre {
    /// A 0,17 s il contenuto si monta e partono numeri, anelli, linee e barre (poi compare a 0,33 s).
    static let avvioContenuto = 0.17
}
