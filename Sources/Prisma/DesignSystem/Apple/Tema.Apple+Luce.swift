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

// MARK: - Il prisma di luce (§2.2.2, giro 4)

extension Tema.Apple {
    /// Il prisma di luce della Sala: il palco è sempre notte (#05090D), in chiaro e in scuro; sopra la tela dello shader
    /// le scritte bianche. Misure in pt del palco (circa 1384×600).
    enum Luce {
        typealias C = Tema.Apple.Carattere
        static let fondoPalco = Color(hex: "#05090D")
        static let testo = Color.white
        static let testo2 = Color(r: 255, g: 255, b: 255, a: 0.6)
        static let testo3 = Color(r: 255, g: 255, b: 255, a: 0.55)
        /// «IL PATRIMONIO FINANZIARIO DI …»: 11,5, 700, spaziatura 1,6, opacità 0,55.
        static let occhiello = C(dimensione: 11.5, peso: .bold, tracking: 1.6, maiuscolo: true)
        /// Il totale: display 44, 700, −1,2, tabellari; accanto «oggi» / «nel 2034» 15 a 0,6, 12 di spazio.
        static let totale = C(dimensione: 44, peso: .bold, tracking: -1.2, tabellare: true)
        static let anno = C(dimensione: 15, peso: .regular)
        static let spazioTotaleAnno: CGFloat = 12
        /// Margini: 30 ai lati, 26 sopra e sotto (24 sopra e 26 a destra per il segmentato).
        static let margineLato: CGFloat = 30
        static let margineAlto: CGFloat = 26
        static let margineSegmentato: CGFloat = 24
        static let margineSegmentatoDestra: CGFloat = 26
        /// La tela non va oltre 1,6 pixel per punto (`glTela(...,1.6)`).
        static let scalaRisoluzione: CGFloat = 1.6

        /// Il segmentato scuro `.segScuro`: fondo bianco 0,10, pillola 0,22 senza ombra, testo 0,65, scelto pieno.
        enum Segmentato {
            static let fondo = Color(r: 255, g: 255, b: 255, a: 0.10)
            static let pillola = Color(r: 255, g: 255, b: 255, a: 0.22)
            static let testo = Color(r: 255, g: 255, b: 255, a: 0.65)
            static let testoScelto = Color.white
            static let carattere = Tema.Apple.Carattere.barra
            static let padding: CGFloat = 3
            static let paddingVoce = EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
            static let opacitaSpenta: Double = 0.35
        }

        /// Il pannello del dettaglio in basso a sinistra: largo 300, padding 16/18, raggio 18, fondo bianco 0,07, bordo
        /// bianco 0,12. La sfocatura 18 del template sul fondo notte quasi non si vede e nelle istantanee non esce:
        /// niente materiale.
        enum Dettaglio {
            static let larghezza: CGFloat = 300
            static let padding = EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18)
            static let raggio: CGFloat = 18
            static let fondo = Color(r: 255, g: 255, b: 255, a: 0.07)
            static let bordo = Color(r: 255, g: 255, b: 255, a: 0.12)
            static let spessoreBordo: CGFloat = 1
            /// «PASSA SUI RAGGI» 12, 600, spaziatura 0,4, opacità 0,55; sotto il testo 14 a 0,85, interlinea 1,45.
            static let invito = C(dimensione: 12, peso: .semibold, tracking: 0.4, maiuscolo: true)
            static let coloreInvito = Color(r: 255, g: 255, b: 255, a: 0.55)
            static let spiegazione = C(dimensione: 14, peso: .regular, interlinea: 1.45)
            static let coloreSpiegazione = Color(r: 255, g: 255, b: 255, a: 0.85)
            static let sottoInvito: CGFloat = 4
            /// Raggio scelto: pallino 10 con alone 14, nome 16 grassetto, cifra display 32 (−0,8), quota 13,5 a 0,7.
            static let pallino: CGFloat = 10
            static let alonePallino: CGFloat = 14
            static let nome = C(dimensione: 16, peso: .bold)
            static let cifra = C(dimensione: 32, peso: .bold, tracking: -0.8, tabellare: true)
            static let quota = C(dimensione: 13.5, peso: .regular)
            static let coloreQuota = Color(r: 255, g: 255, b: 255, a: 0.7)
            static let spazioPallino: CGFloat = 8
            static let sopraCifra: CGFloat = 6
            /// Le note (composizione stimata, ripartizione di oggi): 12 a 0,55, 8 sopra.
            static let nota = C(dimensione: 12, peso: .regular, interlinea: 1.35)
            static let sopraNota: CGFloat = 8
        }

        /// Le etichette in fondo ai raggi (`.lLab`).
        enum Etichetta {
            static let nome = C(dimensione: 15, peso: .semibold, tracking: -0.1)
            static let pallino: CGFloat = 8
            static let alone: CGFloat = 12
            static let spazioPallino: CGFloat = 8
            static let valore = C(dimensione: 12.5, peso: .regular, tabellare: true)
            static let opacitaValore: Double = 0.62
            static let rientro: CGFloat = 16
            static let sopraValore: CGFloat = 2
            static let distanzaMinima: CGFloat = 44
            static let oltreLaPunta: CGFloat = 16
            /// La cima dell'etichetta sta 20 sopra il punto calcolato (`top = y − 20`).
            static let sopraIlPunto: CGFloat = 20
            static let attenuata: Double = 0.22
            /// I giri di separazione verticale: il template ne fa 4, che con sei fasce strette lasciano etichette
            /// sovrapposte; 12 bastano sempre (scelta di Prisma, stesso metodo).
            static let giriSeparazione = 12
            /// L'etichetta del canale (vista «Per canale») sotto la cifra, 4 sopra.
            static let sopraCanale: CGFloat = 4
            /// Un'etichetta non esce dal palco: almeno 12 dal bordo destro e dal fondo.
            static let margineBordo: CGFloat = 12
        }

        /// Il cursore degli anni in basso a destra: largo 340, «OGGI» e «FRA VENT'ANNI» ai capi.
        enum Cursore {
            static let larghezza: CGFloat = 340
            static let capi = C(dimensione: 12, peso: .semibold, tracking: 0.4, maiuscolo: true)
            static let coloreCapi = Color(r: 255, g: 255, b: 255, a: 0.6)
            static let sopraBinario: CGFloat = 8
            /// Senza data di nascita: la frase al posto del cursore.
            static let manca = C(dimensione: 13.5, peso: .regular, interlinea: 1.4)
            static let colorePulsante = Color(hex: "#9CC3FF")
        }

        /// Il cristallo spento (nessuna posizione in essere): la frase sotto il cristallo, larga al più 460.
        enum Vuoto {
            static let testo = C(dimensione: 17, peso: .semibold, interlinea: 1.35)
            static let larghezza: CGFloat = 460
            static let spazio: CGFloat = 14
            /// La frase sta sotto il pavimento della scena.
            static let sottoPavimento: CGFloat = 24
        }

        /// I colori dei raggi sul fondo notte (decisioni 118 e 119): la tavolozza del template per le classi, il grigio
        /// chiaro per «Liquidità e altro», le varianti scure dei canali (sempre con il nome del canale a parole).
        enum Raggi {
            static let azionario = Color(hex: "#3B82F6")
            static let obbligazionario = Color(hex: "#5AC8FA")
            static let gestioneSeparata = Color(hex: "#A78BFA")
            static let liquidita = Color(hex: "#34D399")
            static let altro = Color(hex: "#CBD5E1")
            static let alleanza = Color(hex: "#6B95FF")
            static let indipendente = Color(hex: "#D0954A")
            /// Gli obiettivi: il colore dell'area come nel dossier; se due obiettivi hanno la stessa area, i seguenti
            /// di questa serie (scelta di Prisma, il template ha un colore per obiettivo).
            static let obiettiviAggiunti = [Color(hex: "#F472B6"), Color(hex: "#FBBF24"), Color(hex: "#2DD4BF"),
                                            Color(hex: "#F97316"), Color(hex: "#93C5FD")]
            static let massimo = 6
        }

        /// La geometria della scena (`ESPM.luce`), in punti del palco.
        enum Scena {
            static let centroX: CGFloat = 0.43
            static let centroY: CGFloat = 0.47
            static let raggioMassimo: CGFloat = 150
            static let quotaRaggio: CGFloat = 0.25
            static let entrata: CGFloat = 0.57
            static let uscita: CGFloat = 0.60
            static let interno: CGFloat = 0.2
            static let pendenzaRaggio: CGFloat = -0.085
            static let apertura: CGFloat = 0.5
            static let direzioneBase: CGFloat = 0.08
            static let direzionePerRotazione: CGFloat = 1.55
            static let lunghezzaMassima: CGFloat = 560
            /// Sotto questa lunghezza il ventaglio non scende (palco stretto): scelta di Prisma.
            static let lunghezzaMinima: CGFloat = 140
            static let spazioDestra: CGFloat = 250
            static let quotaFissa: CGFloat = 0.72
            static let quotaAnni: CGFloat = 0.28
            static let pavimento: CGFloat = 100
            /// Il puntatore sceglie una fascia fra 70 da X e la lunghezza + 60.
            static let sceltaDa: CGFloat = 70
            static let sceltaOltre: CGFloat = 60
            /// Gli angoli del vetro arrotondati di 9.
            static let rientroAngoli: CGFloat = 9
        }

        /// Il fermo-immagine in SwiftUI (`PrismaDiLuceFermo`): aloni fatti con i gradienti (nelle istantanee i filtri
        /// di livello possono non uscire), nessun `Canvas`.
        enum Fermo {
            /// Il fondo: dal blu (0,10, 0,15, 0,21) al quasi nero (0,022, 0,036, 0,054), centrato al 38% / 32%.
            static let fondoCentro = Color(red: 0.10, green: 0.15, blue: 0.21)
            static let fondoBordo = Color(red: 0.022, green: 0.036, blue: 0.054)
            static let centroFondo = UnitPoint(x: 0.38, y: 0.32)
            static let quotaRaggioFondo: CGFloat = 1.05
            static let vignetta = Color(r: 0, g: 0, b: 0, a: 0.35)
            /// Il raggio che entra: bianco caldo, nucleo 2,4, alone 22.
            static let raggio = Color(red: 1, green: 0.985, blue: 0.96)
            static let nucleoRaggio: CGFloat = 2.4
            static let aloneRaggio: CGFloat = 22
            static let opacitaAlone: Double = 0.22
            /// Il vetro: facce a 0,20 / 0,13 / 0,075 della tinta (0,80, 0,90, 1), bordo (0,9, 0,95, 1), fili interni.
            static let tintaVetro = Color(red: 0.80, green: 0.90, blue: 1)
            static let facce: [Double] = [0.20, 0.13, 0.075]
            static let bordoVetro = Color(red: 0.9, green: 0.95, blue: 1)
            static let spessoreBordo: CGFloat = 1.4
            static let opacitaFili: Double = 0.55
            static let spessoreFili: CGFloat = 1
            static let opacitaVetroSpento: Double = 0.55
            /// L'uscita: bianco caldo (1, 0,97, 0,93); il ventaglio sfuma dal bianco al colore entro 210 punti.
            static let biancoUscita = Color(red: 1, green: 0.97, blue: 0.93)
            static let sfumaturaColore: CGFloat = 210
            static let opacitaVentaglio: Double = 0.88
            static let filo = Color(r: 5, g: 9, b: 13, a: 0.55)
            static let spessoreFilo: CGFloat = 1.2
            static let punto: CGFloat = 26
            /// Il riflesso sotto il pavimento: opacità 0,22, alto al più 120; il filo d'orizzonte (0,5, 0,6, 0,75) a 0,05.
            static let opacitaRiflesso: Double = 0.22
            static let orizzonte = Color(red: 0.5, green: 0.6, blue: 0.75)
            static let opacitaOrizzonte: Double = 0.05
        }
    }
}

extension Tema.Apple.Moto {
    /// Il movimento del prisma di luce (§2.2.3): le fasi dell'apertura sono calcolate nel renderer con il tempo vero
    /// dello schermo (niente Timer); etichette, totale e pannello sono animazioni di SwiftUI.
    enum Luce {
        struct Fase {
            let inizio: Double
            let durata: Double
            /// 0…1 con la cubica dentro-fuori (`eio` del template).
            func valore(_ t: Double) -> Double { Luce.dentroFuoriCubica((t - inizio) / durata) }
        }
        static let raggio = Fase(inizio: 0, durata: 1.1)
        static let vetro = Fase(inizio: 0.7, durata: 0.9)
        static let ventaglio = Fase(inizio: 1.15, durata: 1.3)
        /// Il totale si conta in 1,6 s.
        static let totaleDurata = 1.6
        /// Le etichette entrano quando il ventaglio è oltre 0,95: 0,6 s ciascuna, passo 0,09, da x −10.
        static let etichetteDurata = 0.6
        static let etichettePasso = 0.09
        static let etichetteSpostamento: CGFloat = -10
        static var etichetteRitardo: Double { ventaglio.inizio + ventaglio.durata * 0.95 }
        /// Oscillazione a riposo (±2°) inseguita con smorzamento 0,6/s; la rotazione segue con 7/s.
        static let oscillazioneAmpiezza = 0.035
        static let oscillazionePulsazione = 0.22
        static let oscillazioneInseguimento = 0.6
        static let inseguimentoRotazione = 7.0
        /// Trascinamento: 520 punti = 1 rad, limitato a ±0,22.
        static let puntiPerRadiante: CGFloat = 520
        static let rotazioneMassima = 0.22
        /// Il raggio scelto si accende (1,75), gli altri si spengono (0,22), smorzamento 7/s; etichette in 0,35 s.
        static let evidenzaScelto: Float = 1.75
        static let evidenzaAltri: Float = 0.22
        static let evidenzaInseguimento = 7.0
        static let durataEtichetteAttenuate = 0.35
        /// Cambio di vista: fasce interpolate in 0,85 s; etichette ricostruite dopo 0,65 s, 0,5 s, passo 0,07, da x −8.
        static let cambioVista = 0.85
        static let cambioRitardoEtichette = 0.65
        static let cambioDurataEtichette = 0.5
        static let cambioPasso = 0.07
        static let cambioSpostamento: CGFloat = -8
        /// Respiro della luce: 0,9 + 0,1·sin(1,3 t); il pulviscolo scorre a 26 punti al secondo (nello shader).
        static let respiroBase = 0.9
        static let respiroAmpiezza = 0.1
        static let respiroPulsazione = 1.3
        /// Il tempo del fotogramma fermo (istantanee, Riduci movimento): respiro quasi pieno, grana ferma.
        static let tempoFermo = 1.2
        /// Fotogrammi al secondo: 30 (20 in risparmio energetico), 60 nei trascinamenti e nelle transizioni (D6).
        static let fotogrammi = 30
        static let fotogrammiRisparmio = 20
        static let fotogrammiTransizione = 60
        /// Il dt più lungo considerato (dopo una pausa non si salta).
        static let dtMassimo = 0.25
        /// La rotazione mostrata si comunica alle etichette solo se cambia di più di così (rad).
        static let sogliaRotazione = 0.0004

        static func dentroFuoriCubica(_ x: Double) -> Double {
            let t = min(max(x, 0), 1)
            return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
        }
        static var etichette: Animation { Curva.uscita.animazione(etichetteDurata) }
        static var etichetteCambio: Animation { Curva.uscita.animazione(cambioDurataEtichette) }
        static var attenuazione: Animation { .easeInOut(duration: durataEtichetteAttenuate * Tema.Apple.Moto.ritmo) }
    }
}
