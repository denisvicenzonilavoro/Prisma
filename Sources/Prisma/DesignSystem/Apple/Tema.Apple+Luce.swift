import SwiftUI

// Gettoni della parte comune della versione «Luce» (Design/template-luce-specifica.md §1): il pannello «✦ Novità» a
// due gruppi (§1.1.2), i tasselli con i glifi e le loro tinte (§1.4.2), le testate delle quattro app nuove (§1.2.2) e i
// movimenti nuovi (§1.1.3, §1.4.3). La Sala ha il suo file (Tema.Apple+SalaEsperienze.swift). Misure in pt del palco
// 1440×900; i colori dei tasselli sono gli stessi in chiaro e in scuro (il template non li cambia).

// MARK: - Pannello Novità a due gruppi (§1.1.2)

extension Tema.Apple.Novita {
    /// Il pannello di Luce: largo 1180 (tre colonne), poi due colonne quando la finestra è stretta.
    static let larghezzaDueGruppi: CGFloat = 1180
    /// Testata: 4 sopra la prima etichetta (era 6).
    static let spazioTestataDueGruppi: CGFloat = 4
    /// Etichetta di gruppo `.lbl`: 10 sopra la prima, 14 sopra la seconda, 4 sotto.
    static let sopraPrimoGruppo: CGFloat = 10
    static let sopraSecondoGruppo: CGFloat = 14
    static let sottoGruppo: CGFloat = 4
    static let etichettaGruppo = Tema.Apple.Carattere.etichetta
    /// Griglia `.novG`: tre colonne uguali, 6 fra le colonne, 2 fra le righe (`spazioVoci`).
    static let colonne = 3
    static let colonneStrette = 2
    static let spazioColonne: CGFloat = 6
    /// Sotto questa larghezza di colonna la griglia passa a due colonne (decisione 117).
    static let larghezzaMinimaColonna: CGFloat = 300
    /// Voce `.novI` della griglia: padding 7×8, 10 fra tassello e testi, raggio 14; alta 44.
    static let paddingVoceGriglia = EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8)
    static let spazioVoceGriglia: CGFloat = 10
    static let titoloVoceGriglia = Tema.Apple.Carattere(dimensione: 13, peso: .bold)
    static let fraseVoceGriglia = Tema.Apple.Carattere(dimensione: 11.5, peso: .regular)
    /// Il tassello della voce: 30, raggio 9 (0,3 del lato).
    static let tasselloVoce: CGFloat = 30
}

extension Tema.Apple.Moto {
    /// Le voci della griglia a cascata: da y +8, 0,36 s con `uscita`, ritardo 0,04 + i·0,014 (i = 0…28).
    enum VoceNovitaGriglia {
        static let durata = 0.36
        static let spostamento: CGFloat = 8
        static let ritardoBase = 0.04
        static let passo = 0.014
        static var animazione: Animation { Curva.uscita.animazione(durata) }
        static func ritardo(indice: Int) -> Double { ritardoBase + Double(indice) * passo }
    }
}

extension Tema.Apple.Moto.PannelloNovita {
    /// Le voci che aprono prima l'app e poi la scena del telefono (Nuovo cliente, Nota vocale): 0,4 s con l'app già
    /// davanti, 0,9 s se no (il tempo del volo della finestra).
    static let attesaScenaAppDavanti = 0.4
    static let attesaScena = 0.9
}

extension Tema.Apple.Moto.StileEntrata {
    /// Voci della griglia del pannello Novità di Luce: da y +8, in 0,36 s, senza sfocatura.
    static let voceNovitaGriglia = Tema.Apple.Moto.StileEntrata(durata: Tema.Apple.Moto.VoceNovitaGriglia.durata,
                                                                curva: Tema.Apple.Moto.Curva.uscita,
                                                                spostamentoX: 0,
                                                                spostamentoY: Tema.Apple.Moto.VoceNovitaGriglia.spostamento,
                                                                scala: 1, sfocatura: 0)
}

// MARK: - Tasselli con i glifi (§1.4.1, §1.4.2)

extension Tema.Apple {
    /// Il tassello colorato con il glifo bianco a tratto (`glifo`, `ic` del template).
    enum Tassello {
        /// Raggio = 0,3 del lato (pannello Novità, `ic`); nella Sala raggio fisso 14, nel palco 10.
        static let quotaRaggio: CGFloat = 0.3
        /// Il glifo è disegnato a metà del lato, con il tratto di 2 su 24.
        static let quotaGlifo: CGFloat = 0.5
        static let trattoGlifo: CGFloat = 2.0 / 24.0
        static let coloreGlifo = Color.white
        /// `inset 0 1 0 rgba(255,255,255,.35)`: il filo di luce in alto.
        static let filoLuce = Color(r: 255, g: 255, b: 255, a: 0.35)
        static let spessoreFilo: CGFloat = 1
        /// `0 6 14 −6 rgba(0,0,0,.35)`: l'ombra sotto.
        static let ombra = Color(r: 0, g: 0, b: 0, a: 0.35)
        static let ombraRaggio: CGFloat = 7
        static let ombraY: CGFloat = 6
        /// Misure usate nel template.
        static let latoVoce: CGFloat = 30
        static let latoPalco: CGFloat = 32
        static let latoPredefinito: CGFloat = 36
        static let latoSala: CGFloat = 44
        static let latoSalaGrande: CGFloat = 60
    }
}

extension Tema.Apple.Colore {
    /// Le tinte dei 29 glifi di Luce (stesse in chiaro e in scuro). Dove la tinta c'è già nel tema si riusa.
    enum Glifi {
        static let prisma = Tema.Apple.Colore.anello2            // #0A84FF
        static let mappa = Color(hex: "#2A6FA0")
        static let lettera = Tema.Apple.Colore.Impegno.giulia    // #C45A75
        static let film = Tema.Apple.Colore.arancio              // #E08A00
        static let disegna = Tema.Apple.Colore.anello1           // #30B15C
        static let storia = Color(hex: "#1F5F99")
        static let palestra = Color(hex: "#3F5A78")
        static let luce = Color(hex: "#5B4BC8")
        static let capsula = Color(hex: "#9B6FB5")
        static let festa = Tema.Apple.Colore.rosso               // #E5484D
        static let rischio = Tema.Apple.Colore.rosso
        static let giornata = Color(hex: "#2A9BC8")
        /// #B06E12 come il cuoio dell'indipendente, ma fisso: è un tassello con un glifo, non un'etichetta di canale.
        static let dadi = Color(hex: "#B06E12")
        /// #2563EB come il blu di Alleanza, ma fisso (in scuro il canale diventa #6B95FF): non è un'etichetta di canale.
        static let valore = Color(hex: "#2563EB")
        static let ar = Color(hex: "#1E9E6A")
        static let notte = Color(hex: "#1F3A5F")
        static let proposta = Color(hex: "#3E7D69")
        static let modulo = Tema.Apple.Colore.anello1
        static let cartella = Tema.Apple.Colore.anello2
        static let sinistro = Tema.Apple.Colore.arancio
        static let libro = Color(hex: "#8A5A35")
        static let lente = Tema.Apple.Colore.rosso
        static let radar = Color(hex: "#1E9E6A")
        static let campagna = Tema.Apple.Colore.Impegno.giulia
        static let scan = Color(hex: "#5B4BC8")
        static let albero = Color(hex: "#2F7A4A")
        static let azienda = Color(hex: "#3F5A78")
        static let voce = Tema.Apple.Colore.rosso
        static let auto = Color(hex: "#5A6873")
    }
}

extension Tema.Apple.Moto {
    /// Il tassello al passaggio (nella Sala): scala 1,06 in 0,4 s con la molla.
    enum Tassello {
        static let durata = 0.4
        static let scala: CGFloat = 1.06
        static var passaggio: Animation { Curva.molla.animazione(durata) }
    }
}

// MARK: - Le quattro app nuove (§1.2.2)

extension Tema.Apple {
    /// La finestra di un'app di Luce il cui contenuto arriva in un giro successivo: la testata come le altre e, al
    /// centro, il messaggio sobrio («arriva con un prossimo aggiornamento»).
    enum AppLuce {
        static let larghezzaMessaggio: CGFloat = 440
        static let padding = Tema.Apple.Misura.padding(28, 30)
        static let spazio: CGFloat = 12
        static let icona: CGFloat = 64
        static let titolo = Tema.Apple.Carattere.titoloFinestra
        static let testo = Tema.Apple.Carattere.corpo
        static let nota = Tema.Apple.Carattere.secondario
        static let superficie = Tema.Apple.Superficie.card
        static let raggio = Tema.Apple.Raggio.card
    }
}

// MARK: - Il telefono disegnato e il velo della scena, comuni (§1.4.2)

extension Tema.Apple {
    /// L'iPhone disegnato (300×620, raggio 50, corpo #0D0F12, tacca 92×26): lo stesso per Inquadra, Nuovo cliente,
    /// la Nota vocale, il Prisma del cliente e il sinistro. Prima viveva in `Tema.Apple.Inquadra.Apparecchio`, che ora
    /// è un sinonimo di questo.
    enum Apparecchio {
        typealias C = Tema.Apple.Carattere
        static let larghezza: CGFloat = 300
        static let altezza: CGFloat = 620
        static let raggio: CGFloat = 50
        static let corpo = Color(hex: "#0D0F12")
        /// Il filo del bordo (2).
        static let filo = Color(hex: "#2A2E34")
        static let spessoreFilo: CGFloat = 2
        /// `0 40px 80px −20px rgba(0,0,0,.55)`.
        static let ombra = Color(r: 0, g: 0, b: 0, a: 0.55)
        static let ombraRaggio: CGFloat = 40
        static let ombraY: CGFloat = 40
        /// La tacca 92×26 a 22 dall'alto, raggio 20.
        static let tacca = CGSize(width: 92, height: 26)
        static let raggioTacca: CGFloat = 20
        static let taccaDallAlto: CGFloat = 22
        static let coloreTacca = Color(hex: "#000000")
        /// Lo schermo rientra di 11, raggio 40.
        static let rientro: CGFloat = 11
        static let raggioSchermo: CGFloat = 40
        static let schermo = Color(hex: "#1A1D21")
        /// Il fondo «fotocamera» (Inquadra): radiale da #4A423B a #1F1B18 dal 40%/30%.
        static let fotocamera = [Color(hex: "#4A423B"), Color(hex: "#1F1B18")]
        static let centroFotocamera = UnitPoint(x: 0.4, y: 0.3)
        static let raggioFotocamera: CGFloat = 450
        /// La scritta in basso: 12,5 semibold bianca a 22 dal fondo.
        static let scritta = C(dimensione: 12.5, peso: .semibold)
        static let coloreScritta = Color.white
        static let scrittaDalFondo: CGFloat = 22
        /// La foto dentro lo schermo: 18 ai lati, 70 dall'alto, 60 dal fondo.
        static let margineImmagine: CGFloat = 18
        static let immagineDallAlto: CGFloat = 70
        static let immagineDalFondo: CGFloat = 60
    }

    /// Il velo della scena del telefono (`#scan`): rgba(6,14,20,.55) con la sfocatura; senza sfocatura (istantanee,
    /// vetro semplificato) più coprente. Prima `Tema.Apple.Inquadra.Velo`, ora un sinonimo di questo.
    enum VeloScena {
        static let colore = Color(r: 6, g: 14, b: 20, a: 0.55)
        static let coloreFermo = Color(r: 6, g: 14, b: 20, a: 0.72)
        static let materiale: Material = .ultraThinMaterial
    }
}

// MARK: - Tavole di controllo delle istantanee (617, 619)

extension Tema.Apple {
    /// Le tavole delle icone e dei glifi (solo istantanee, per confrontarle con il template): fondi come la tavola di
    /// `Design/Icone/Anteprima_icone.png`.
    enum TavoleLuce {
        static let fondoChiaro = Color(hex: "#E9EEF3")
        static let fondoScuro = Color(hex: "#14181D")
        static let testoChiaro = Color(hex: "#2A2F36")
        static let testoScuro = Color(hex: "#E6E9ED")
        static let margine: CGFloat = 32
        static let spazio: CGFloat = 20
        static let icona: CGFloat = 96
        static let cella: CGFloat = 130
        static let sottoIcona: CGFloat = 6
        static let colonneIcone = 4
        static let colonneGlifi = 10
        /// La tavola dei glifi: 14 fra le righe, 8 fra le colonne, 6 sotto il tassello, colonna larga il tassello + 52.
        static let spazioRigheGlifi: CGFloat = 14
        static let spazioColonneGlifi: CGFloat = 8
        static let sottoTassello: CGFloat = 6
        static let ariaColonnaGlifo: CGFloat = 52
    }
}
