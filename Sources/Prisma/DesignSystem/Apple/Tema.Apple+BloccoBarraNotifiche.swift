import SwiftUI

// Blocco, barra superiore e notifiche della shell nel tema Apple
// (Design/template-apple-specifica.md §3.2, §3.3, §3.8). Misure in pt, durate in secondi.
// I tempi di blocco, sblocco, luce del pulsante e pannello delle notifiche stanno in `Tema.Apple.Moto`
// (TemaAppleMoto.swift); qui solo ciò che manca.

// MARK: - Blocco (§3.2)

extension Tema.Apple {
    /// La schermata di blocco: velo, logo, ora grande e sottile, data, «Tocca per entrare in Prisma».
    enum Lucchetto {
        /// Il logo vettoriale: alto 40, a 70 dal bordo in alto.
        static let logo: CGFloat = 40
        static let logoDallAlto: CGFloat = 70
        /// L'ora (`Carattere.oraBlocco`) comincia 150 sotto il logo; la data sta 10 sotto l'ora.
        static let oraSottoLogo: CGFloat = 150
        static let dataSottoOra: CGFloat = 10
        /// Data: 22 medium all'80%.
        static let data = Carattere(dimensione: 22, peso: .medium)
        static let opacitaData: Double = 0.8
        /// Il pulsante di vetro: a 70 dal fondo, padding 12×22, 14 semibold.
        static let pulsanteDalFondo: CGFloat = 70
        static let paddingPulsante = Misura.padding(12, 22)
        static let pulsante = Carattere(dimensione: 14, peso: .semibold)
        /// Il vetro del pulsante senza sfocatura propria: allo sblocco la schermata intera si sfoca
        /// (`Moto.Sblocco.sfocatura`) e le sfocature non si annidano. Sopra l'acqua ferma non si nota la differenza.
        static let superficiePulsante = Superficie(riempimento: Colore.vetro, sfocatura: 0, saturazione: 1,
                                                   bordo: Colore.bordoVetro, spessoreBordo: 1, ombra: .vetro,
                                                   raggio: Raggio.pillola, filoInterno: true)
        /// La luce che attraversa il pulsante: gradiente a 100°, trasparente fino al 30%, bianco al 70% di
        /// opacità al centro, di nuovo trasparente dal 70% (uguale nei due aspetti).
        static let fermateLuce: [Gradient.Stop] = [
            Gradient.Stop(color: Color(r: 255, g: 255, b: 255, a: 0), location: 0.30),
            Gradient.Stop(color: Color(r: 255, g: 255, b: 255, a: 0.70), location: 0.50),
            Gradient.Stop(color: Color(r: 255, g: 255, b: 255, a: 0), location: 0.70),
        ]
        /// I due capi del gradiente a 100° (appena inclinato rispetto all'orizzontale).
        static let inizioLuce = UnitPoint(x: 0, y: 0.41)
        static let fineLuce = UnitPoint(x: 1, y: 0.59)

        // Il trascinamento (resta valido come prima del tema Apple: oltre al clic, si entra anche trascinando)
        /// Quanto la schermata segue il dito (0,35 della strada fatta).
        static let seguito: CGFloat = 0.35
        /// Oltre questa distanza (pt del gesto) il rilascio fa entrare.
        static let sogliaTrascinamento: CGFloat = 90
        /// Oppure se la previsione del gesto va oltre questo multiplo della soglia (colpo rapido).
        static let quotaPrevista: CGFloat = 2
    }
}

extension Tema.Apple.Moto.LuceBlocco {
    /// Al massimo 30 fotogrammi al secondo per la luce del pulsante (TimelineView, niente Timer).
    static let intervallo: Double = 1.0 / 30
}

extension Tema.Apple.Moto.Sblocco {
    /// La barra superiore compare (e svanisce al blocco) in 0,6 s con `ease`, come `transition: opacity .6s`.
    static var animazioneBarra: Animation { Tema.Apple.Moto.Curva.ease.animazione(durataBarra) }
}

// MARK: - Barra superiore (§3.3)

extension Tema.Apple {
    /// La barra in alto: senza fondo proprio, ogni gruppo nella sua capsula di vetro.
    enum BarraAlta {
        /// Pillole del marchio e dell'app: padding 5×11, spazio 7 fra logo e nome, logo 15.
        static let paddingPillola = Misura.padding(5, 11)
        static let spazioMarchio: CGFloat = 7
        static let logo: CGFloat = 15
        /// Fra una pillola e l'altra a sinistra (`margin-right: 6`) e fra gli strumenti a destra (`gap: 6`).
        static let spazio: CGFloat = 6
        /// Margine a destra (padding 0×12 della barra).
        static let margineDestro: CGFloat = 12
        /// Fra il pulsante verde vero della finestra del Mac e il bordo della pillola del marchio.
        static let dopoSemafori: CGFloat = 14
        /// Cerca: spazio fra lente, parola e scorciatoia; la scorciatoia al 50%.
        static let spazioCerca: CGFloat = 5
        static let opacitaScorciatoia: Double = 0.5
        static let scorciatoia = Carattere(dimensione: 11, peso: .medium)
        /// Data e ora al centro: «lun 2 nov 23:09».
        static let spazioOrologio: CGFloat = 4
        /// Gli strumenti: tasti tondi da 28; la sfera di Vera dentro è da 24.
        static let tasto: CGFloat = 28
        static let sferaVera: CGFloat = 24
        /// I simboli dentro i tasti (campanella, lucchetto, guida, modalità cliente).
        static let simbolo = Carattere(dimensione: 13, peso: .medium)
        /// Badge della campanella: `#FF3B30`, 9 bold, padding 1×4, a −3 dall'alto e −4 da destra.
        static let paddingBadge = EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4)
        static let spostamentoBadge = CGSize(width: 4, height: -3)
        /// Avatar «DV»: cerchio da 28 con il gradiente verticale, iniziali 11.
        static let avatar: CGFloat = 28
        static let iniziali = Carattere(dimensione: 11, peso: .semibold)
        /// Testo bianco del badge e dell'avatar.
        static let testoSuColore = Color(r: 255, g: 255, b: 255)
        /// Tinta del vetro sotto il puntatore.
        static let passaggio = Color(r: 255, g: 255, b: 255, a: 0.14)
    }
}

// MARK: - Notifiche (§3.8)

extension Tema.Apple {
    /// Il pannello delle notifiche: scende dalla campanella, le voci entrano una dopo l'altra.
    enum CentroNotifiche {
        /// Di vetro, largo 360, raggio 22, padding 14, a 12 dal bordo destro e 40 dall'alto.
        static let larghezza: CGFloat = 360
        static let raggio: CGFloat = Raggio.card
        static let padding: CGFloat = 14
        static let destra: CGFloat = 12
        static let alto: CGFloat = 40
        /// Sotto, lo spazio del dock: il pannello non ci arriva.
        static let basso: CGFloat = 98
        /// Intestazione: «Notifiche» 15 bold e il conteggio a destra (`.k`).
        static let titolo = Carattere(dimensione: 15, peso: .bold)
        static let conteggio = Carattere.secondario
        /// Voci: padding 10, raggio 14, fondo `card`, 8 fra una voce e l'altra, testo 13 con interlinea 1,4.
        static let paddingVoce: CGFloat = 10
        static let raggioVoce: CGFloat = Raggio.voce
        static let spazioVoci: CGFloat = 8
        static let spazioVoce: CGFloat = 10
        static let nome = Carattere(dimensione: 13, peso: .bold, interlinea: 1.4)
        static let testo = Carattere(dimensione: 13, peso: .regular, interlinea: 1.4)
        /// Il pallino colorato: 8, a 6 dall'alto della voce.
        static let pallino: CGFloat = 8
        static let pallinoAlto: CGFloat = 6
        static let pallinoUrgente = Colore.rosso
        static let pallinoAvviso = Colore.arancio
        static let pallinoInformazione = Colore.accento
        /// Fondo della voce sotto il puntatore (sopra `card`).
        static let voceSopra = Colore.chip
        /// Titoli dei gruppi (`.lbl`): sopra il primo 4, sopra gli altri 12.
        static let gruppo = Carattere.etichetta
        static let gruppoPrimo: CGFloat = 4
        static let gruppoAltri: CGFloat = 12
        /// Fino a quante voci il pannello è alto quanto il contenuto; oltre, scorre ed è alto quanto può.
        static let vociSenzaScorrere = 12
        /// Le voci oltre questa entrano senza cascata (sono fuori vista all'apertura).
        static let vociInCascata = 8
    }
}
