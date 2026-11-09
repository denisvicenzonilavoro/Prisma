import SwiftUI

// Tempi e curve del tema «stile Apple» (Design/template-apple-specifica.md §1.8).
// Durate e ritardi in secondi, spostamenti in pt. Con «Riduci movimento» si passa da
// `Tema.Apple.Moto.animazione(_:calmo:)` (AmbienteMovimento.swift): dissolvenza di 0,15 s, nessun ritardo.

extension Tema.Apple {
    enum Moto {

        // MARK: Curve

        /// Bézier cubica come `cubic-bezier(x1, y1, x2, y2)` del CSS.
        struct Curva {
            let x1: Double
            let y1: Double
            let x2: Double
            let y2: Double

            /// L'animazione SwiftUI con questa curva.
            func animazione(_ durata: Double) -> Animation {
                .timingCurve(x1, y1, x2, y2, duration: durata)
            }

            /// `--spring`: superamento del 6,6%.
            static let molla = Curva(x1: 0.34, y1: 1.45, x2: 0.64, y2: 1)
            /// `--out`.
            static let uscita = Curva(x1: 0.22, y1: 1, x2: 0.36, y2: 1)
            /// `ease` del CSS.
            static let ease = Curva(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1)
            /// `ease-in` del CSS.
            static let easeIn = Curva(x1: 0.42, y1: 0, x2: 1, y2: 1)
            /// `ease-out` del CSS.
            static let easeOut = Curva(x1: 0, y1: 0, x2: 0.58, y2: 1)
            /// `ease-in-out` del CSS.
            static let easeInOut = Curva(x1: 0.42, y1: 0, x2: 0.58, y2: 1)
            /// Apertura del dettaglio (superamento 1,6%).
            static let dettaglioApre = Curva(x1: 0.32, y1: 1.22, x2: 0.5, y2: 1)
            /// Chiusura del dettaglio (superamento 0,1%).
            static let dettaglioChiude = Curva(x1: 0.32, y1: 1.08, x2: 0.5, y2: 1)
            /// Apertura della finestra dall'icona (superamento 0,4%).
            static let finestraApre = Curva(x1: 0.3, y1: 1.12, x2: 0.5, y2: 1)
            /// Chiusura della finestra e sblocco.
            static let finestraChiude = Curva(x1: 0.5, y1: 0, x2: 0.3, y2: 1)
            /// Anello del backup.
            static let backup = Curva(x1: 0.4, y1: 0, x2: 0.2, y2: 1)
            /// La molla leggera `cubic-bezier(.34,1.3,.64,1)`: l'iPhone di Inquadra, il volo delle schede dei potenziali
            /// («Luce» giro 12).
            static let mollaLeggera = Curva(x1: 0.34, y1: 1.3, x2: 0.64, y2: 1)
            /// Il raduno dei pallini nei gruppi delle campagne `cubic-bezier(.34,1.15,.5,1)` («Luce» giro 12).
            static let raduno = Curva(x1: 0.34, y1: 1.15, x2: 0.5, y2: 1)

            /// `1 − (1−t)^4`: numeri che si contano e `morphP` (si usa in `Animatable`, non come `Animation`).
            static func quartica(_ t: Double) -> Double {
                let u = 1 - min(max(t, 0), 1)
                return 1 - u * u * u * u
            }
        }

        /// Molla SwiftUI equivalente, dove una bézier con y > 1 non va bene (§5.3).
        struct Molla {
            let risposta: Double
            let smorzamento: Double
            var animazione: Animation { .spring(response: risposta, dampingFraction: smorzamento) }
        }

        /// Uscita di durata data.
        static func uscita(_ durata: Double) -> Animation { Curva.uscita.animazione(durata) }
        /// `--spring` di durata data.
        static func molla(_ durata: Double) -> Animation { Curva.molla.animazione(durata) }

        // MARK: Ingressi

        /// Entrata a cascata: da y +18, scala 0,985, sfocatura 6, opacità 0.
        enum Cascata {
            static let durata = 0.72
            static let passo = 0.048
            static let baseFinestra = 0.14
            static let baseScrivania = 0.12
            static let baseDentroApp = 0.0
            static let spostamento: CGFloat = 18
            static let scala: CGFloat = 0.985
            static let sfocatura: CGFloat = 6
            static var animazione: Animation { Curva.uscita.animazione(durata) }
            static func ritardo(indice: Int, base: Double) -> Double { base + Double(indice) * passo }
        }

        /// Impegni dell'agenda: da x +30.
        enum CascataLaterale {
            static let durata = 0.60
            static let spostamento: CGFloat = 30
            static let ritardoBase = 0.12
            static let passo = 0.08
            static var animazione: Animation { Curva.uscita.animazione(durata) }
            static func ritardo(indice: Int) -> Double { ritardoBase + Double(indice) * passo }
        }

        /// Voci delle notifiche: da x +20.
        enum VoceNotifica {
            static let durata = 0.40
            static let spostamento: CGFloat = 20
            static let ritardoBase = 0.08
            static let passo = 0.07
            static var animazione: Animation { Curva.uscita.animazione(durata) }
            static func ritardo(indice: Int) -> Double { ritardoBase + Double(indice) * passo }
        }

        /// Pannello delle notifiche: da y −10, scala 0,97.
        enum PannelloNotifiche {
            static let durata = 0.38
            static let spostamento: CGFloat = -10
            static let scala: CGFloat = 0.97
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static let ripiego = Molla(risposta: 0.38, smorzamento: 0.65)
        }

        // MARK: Numeri, anelli, grafici

        /// Numero che si conta da 0 (curva quartica).
        enum Numero {
            static let durataBase = 1.10
            static let passo = 0.06
            static let indiceMassimo = 6
            static func durata(indice: Int) -> Double { durataBase + Double(min(indice, indiceMassimo)) * passo }
        }

        /// Da valore a valore (proposte, legenda).
        enum NumeroCambio { static let durata = 0.90 }

        /// Valori del simulatore all'apertura.
        enum NumeroSimulatore { static let durata = 1.00 }

        /// Anelli: ritardo d + i·0,13.
        enum Anello {
            static let durata = 1.40
            static let passo = 0.13
            static let ritardoFinestra = 0.32
            static let ritardoDettaglio = 0.12
            static let ritardoCambio = 0.15
            /// Scrivania: 0,30 dopo 0,30.
            static let ritardoScrivania = 0.60
            static let ritardoPredefinito = 0.20
            static var animazione: Animation { Curva.uscita.animazione(durata) }
            static func ritardo(indice: Int, base: Double = ritardoPredefinito) -> Double { base + Double(indice) * passo }
        }

        /// Brillio dell'anello (ombra 10 del colore dell'anello).
        enum Brillio {
            static let durata = 0.60
            static let tenuto = 0.90
            static let sfocatura: CGFloat = 10
            static var animazione: Animation { Curva.ease.animazione(durata) }
        }

        /// Linea che si disegna.
        enum Linea {
            static let durata = 1.50
            static let ritardoBase = 0.15
            static let passo = 0.12
            static var animazione: Animation { Curva.uscita.animazione(durata) }
            static func ritardo(indice: Int) -> Double { ritardoBase + Double(indice) * passo }
        }

        /// Area sotto la linea.
        enum Area {
            static let durata = 0.90
            static let ritardo = 0.60
            static var animazione: Animation { Curva.ease.animazione(durata) }
        }

        /// Barra che si riempie.
        enum Barra {
            static let durata = 1.20
            static let ritardoBase = 0.15
            static let passo = 0.09
            static var animazione: Animation { Curva.uscita.animazione(durata) }
            static func ritardo(indice: Int) -> Double { ritardoBase + Double(indice) * passo }
        }

        /// Grafico «In essere / Con le proposte»: parametro p 0 → 1 (quartica).
        enum MorphProposte { static let durata = 0.90 }

        // MARK: Controlli

        /// Segmentato a pillola (il colore del testo in 0,30).
        enum Segmentato {
            static let durata = 0.50
            static let durataTesto = 0.30
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static var animazioneTesto: Animation { .easeInOut(duration: durataTesto) }
            static let ripiego = Molla(risposta: 0.50, smorzamento: 0.65)
        }

        /// Interruttore (fondo in 0,30).
        enum Interruttore {
            static let durata = 0.35
            static let durataFondo = 0.30
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static var animazioneFondo: Animation { .easeInOut(duration: durataFondo) }
            static let ripiego = Molla(risposta: 0.35, smorzamento: 0.65)
        }

        /// Pulsante premuto: scala 0,95; al passaggio luminosità 0,97 in 0,2.
        enum PulsantePremuto {
            static let durata = 0.25
            static let scala: CGFloat = 0.95
            static let luminositaSopra: Double = 0.97
            static let durataSopra = 0.20
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static var animazioneSopra: Animation { .easeInOut(duration: durataSopra) }
            static let ripiego = Molla(risposta: 0.25, smorzamento: 0.65)
        }

        /// Scheda che si inclina: prospettiva 900, sollevamento −5, scala 1,02, ombra 0,4, riflesso 0,3.
        enum Inclinazione {
            static let durata = 0.50
            static let prospettiva: CGFloat = 900
            static let sollevamento: CGFloat = -5
            static let scala: CGFloat = 1.02
            static let ombra: Double = 0.4
            static let riflesso: Double = 0.3
            /// Gradi massimi: impegni 3, aree e «Prossimo incontro» 5, familiari 6, predefinito 10.
            static let massimoImpegni: Double = 3
            static let massimoAree: Double = 5
            static let massimoFamiliari: Double = 6
            static let massimoPredefinito: Double = 10
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static let ripiego = Molla(risposta: 0.50, smorzamento: 0.65)
        }

        /// Riquadro della scrivania al passaggio: −3 in y.
        enum RiquadroSopra {
            static let durata = 0.45
            static let spostamento: CGFloat = -3
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static let ripiego = Molla(risposta: 0.45, smorzamento: 0.65)
        }

        /// Suggerimento al passaggio: −2 in y.
        enum SuggerimentoSopra {
            static let durata = 0.25
            static let spostamento: CGFloat = -2
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static let ripiego = Molla(risposta: 0.25, smorzamento: 0.65)
        }

        // MARK: Dettaglio e finestra

        /// Dettaglio che nasce dall'elemento: raggio 22 → 28; il contenuto entra dopo 0,17 + 0,16 in 0,35.
        enum DettaglioApre {
            static let durata = 0.62
            static let raggioIniziale: CGFloat = 22
            static let raggioFinale: CGFloat = 28
            static let ritardoContenuto = 0.17 + 0.16
            static let durataContenuto = 0.35
            static var animazione: Animation { Curva.dettaglioApre.animazione(durata) }
            static var animazioneContenuto: Animation { .easeInOut(duration: durataContenuto) }
            static let ripiego = Molla(risposta: 0.62, smorzamento: 0.80)
        }

        /// Chiusura del dettaglio: il contenuto va via in 0,20.
        enum DettaglioChiude {
            static let durata = 0.46
            static let durataContenuto = 0.20
            static var animazione: Animation { Curva.dettaglioChiude.animazione(durata) }
            static var animazioneContenuto: Animation { .easeInOut(duration: durataContenuto) }
            static let ripiego = Molla(risposta: 0.46, smorzamento: 0.90)
        }

        /// Velo sotto il dettaglio: sfocatura 0 → 10.
        enum Velo {
            static let durata = 0.45
            static let sfocatura: CGFloat = 10
            static var animazione: Animation { Curva.ease.animazione(durata) }
        }

        /// Finestra che parte dall'icona del dock (scale x e y separate, opaca dal 35%).
        enum FinestraApre {
            static let durata = 0.60
            static let opacitaIniziale: Double = 0.35
            static var animazione: Animation { Curva.finestraApre.animazione(durata) }
            static let ripiego = Molla(risposta: 0.60, smorzamento: 0.87)
        }

        /// Chiusura della finestra: svanisce dopo il 60%.
        enum FinestraChiude {
            static let durata = 0.48
            static let inizioSvanire: Double = 0.60
            static var animazione: Animation { Curva.finestraChiude.animazione(durata) }
        }

        /// Contenuto della finestra al montaggio: 0,2 s lineare (§0 punto 1).
        enum ContenutoFinestra {
            static let durata = 0.20
            static var animazione: Animation { .linear(duration: durata) }
        }

        /// Cambio d'app: esce in 0,15 ease-in a scala 0,985, entra in 0,20 lineare.
        enum CambioApp {
            static let durataUscita = 0.15
            static let durataEntrata = 0.20
            static let scalaUscita: CGFloat = 0.985
            static var uscita: Animation { .easeIn(duration: durataUscita) }
            static var entrata: Animation { .linear(duration: durataEntrata) }
        }

        /// Scrivania sotto una finestra aperta: opacità 0,25.
        enum ScrivaniaSotto {
            static let durata = 0.50
            static let opacita: Double = 0.25
            static var animazione: Animation { Curva.ease.animazione(durata) }
        }

        // MARK: Dock, blocco, toast

        /// Rimbalzo dell'icona: passi uniformi 0, −16, 0, −7, 0.
        enum RimbalzoIcona {
            static let durata = 0.70
            static let passi: [CGFloat] = [0, -16, 0, -7, 0]
            /// Spostamento a una fase 0…1 (interpolazione lineare fra i passi, poi ease-out del totale).
            static func spostamento(fase: Double) -> CGFloat {
                let t = min(max(fase, 0), 1)
                let segmenti = Double(passi.count - 1)
                let x = t * segmenti
                let i = min(Int(x), passi.count - 2)
                let f = CGFloat(x - Double(i))
                return passi[i] + (passi[i + 1] - passi[i]) * f
            }
            static var animazione: Animation { .easeOut(duration: durata) }
        }

        /// Dock: sale da +140, ritardo 0,20 dallo sblocco.
        enum Dock {
            static let durata = 0.70
            static let spostamento: CGFloat = 140
            static let ritardo = 0.20
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static let ripiego = Molla(risposta: 0.70, smorzamento: 0.65)
        }

        /// Ingrandimento del dock: s = 1 + 0,36 · max(0, 1 − d/130).
        enum IngrandimentoDock {
            static let durata = 0.14
            static let aumento: CGFloat = 0.36
            static let portata: CGFloat = 130
            static var animazione: Animation { Curva.ease.animazione(durata) }
            static func scala(distanza: CGFloat) -> CGFloat { 1 + aumento * max(0, 1 - distanza / portata) }
        }

        /// Sblocco: sale di 60, scala 1,04, sfocatura 8; barra in 0,60.
        enum Sblocco {
            static let durata = 0.65
            static let salita: CGFloat = 60
            static let scala: CGFloat = 1.04
            static let sfocatura: CGFloat = 8
            static let durataBarra = 0.60
            static var animazione: Animation { Curva.finestraChiude.animazione(durata) }
        }

        /// Blocco: scende da −30.
        enum Blocco {
            static let durata = 0.50
            static let spostamento: CGFloat = -30
            static var animazione: Animation { Curva.uscita.animazione(durata) }
        }

        /// Luce sul pulsante del blocco: ciclo 2,6, attraversa nel 60%.
        enum LuceBlocco {
            static let ciclo = 2.60
            static let attraversamento: Double = 0.60
        }

        /// Toast: da y −20, tenuto 2,4.
        enum Toast {
            static let durata = 0.45
            static let spostamento: CGFloat = -20
            static let tenuto = 2.40
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static let ripiego = Molla(risposta: 0.45, smorzamento: 0.65)
        }

        // MARK: Sequenze

        /// Spunta che si disegna: cerchio 0,50, segno 0,35 dopo 0,35, velo verde in 0,40.
        enum Spunta {
            static let durataCerchio = 0.50
            static let durataSegno = 0.35
            static let ritardoSegno = 0.35
            static let durataVelo = 0.40
            static var cerchio: Animation { Curva.uscita.animazione(durataCerchio) }
            static var segno: Animation { Curva.uscita.animazione(durataSegno).delay(ritardoSegno) }
        }

        /// «Ti preparo»: una molla da 0,35 per voce, ritmo 0,22 + i·0,36; toast a 0,32 + n·0,36.
        enum TiPreparo {
            static let durataVoce = 0.35
            static let ritmoBase = 0.22
            static let passo = 0.36
            static let toastBase = 0.32
            static var animazione: Animation { Curva.molla.animazione(durataVoce) }
            static let ripiego = Molla(risposta: 0.35, smorzamento: 0.65)
            static func ritardo(indice: Int) -> Double { ritmoBase + Double(indice) * passo }
            static func ritardoToast(voci: Int) -> Double { toastBase + Double(voci) * passo }
        }

        /// «Segna come fatto»: +0,60 anello, +1,15 la scheda si stringe, +0,56 viene tolta.
        enum Fatto {
            static let anello = 0.60
            static let stringe = 1.15
            static let tolta = 0.56
            static let durataLarghezza = 0.55
            static let durataTrasformazione = 0.50
            static let durataOpacita = 0.40
            static var larghezza: Animation { Curva.molla.animazione(durataLarghezza) }
            static var trasformazione: Animation { Curva.molla.animazione(durataTrasformazione) }
            static var opacita: Animation { .easeInOut(duration: durataOpacita) }
        }

        /// Nastro orizzontale: frecce ±500.
        enum Nastro {
            static let durata = 0.70
            static let passoFrecce: CGFloat = 500
            static var animazione: Animation { Curva.uscita.animazione(durata) }
        }

        /// Cambio cliente: esce in 0,14 ease-in verso x +14, poi cascata con base 0.
        enum CambioCliente {
            static let durataUscita = 0.14
            static let spostamento: CGFloat = 14
            static var uscita: Animation { .easeIn(duration: durataUscita) }
        }

        /// Cambio scheda: esce in 0,13 lineare verso y +6, poi cascata con base 0.
        enum CambioScheda {
            static let durataUscita = 0.13
            static let spostamento: CGFloat = 6
            static var uscita: Animation { .linear(duration: durataUscita) }
        }

        /// Cambio della griglia di Analisi 360: esce in 0,14 lineare a scala 0,99.
        enum CambioGriglia {
            static let durataUscita = 0.14
            static let scala: CGFloat = 0.99
            static var uscita: Animation { .linear(duration: durataUscita) }
        }

        /// Blocchi dei mesi: da scala y 0,2, ritardo 0,20 + i·0,06.
        enum BlocchiMese {
            static let durata = 0.50
            static let scalaIniziale: CGFloat = 0.2
            static let ritardoBase = 0.20
            static let passo = 0.06
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static let ripiego = Molla(risposta: 0.50, smorzamento: 0.65)
            static func ritardo(indice: Int) -> Double { ritardoBase + Double(indice) * passo }
        }

        /// Pagina che cambia: esce in 0,18 ease-in (y ∓30, scala 0,70), entra in 0,52 uscita (y ±40, scala 0,68).
        enum Pagina {
            static let durataUscita = 0.18
            static let durataEntrata = 0.52
            static let spostamentoUscita: CGFloat = 30
            static let spostamentoEntrata: CGFloat = 40
            static let scalaUscita: CGFloat = 0.70
            static let scalaEntrata: CGFloat = 0.68
            static var uscita: Animation { .easeIn(duration: durataUscita) }
            static var entrata: Animation { Curva.uscita.animazione(durataEntrata) }
        }

        /// Sala della presentazione: velo 0,40 lineare, foglio 0,60 uscita (scala 0,74 → 0,88); chiude in 0,25.
        enum Sala {
            static let durataVelo = 0.40
            static let durataFoglio = 0.60
            static let durataChiusura = 0.25
            static let scalaIniziale: CGFloat = 0.74
            static let scalaFinale: CGFloat = 0.88
            static var velo: Animation { .linear(duration: durataVelo) }
            static var foglio: Animation { Curva.uscita.animazione(durataFoglio) }
            static var chiude: Animation { .easeInOut(duration: durataChiusura) }
        }

        /// Giro di pagina: 0,22 ease-in verso x −d·120, poi 0,52 uscita da +d·160; scala 0,85.
        enum GiroPagina {
            static let durataUscita = 0.22
            static let durataEntrata = 0.52
            static let spostamentoUscita: CGFloat = 120
            static let spostamentoEntrata: CGFloat = 160
            static let scala: CGFloat = 0.85
            static var uscita: Animation { .easeIn(duration: durataUscita) }
            static var entrata: Animation { Curva.uscita.animazione(durataEntrata) }
        }

        /// Anello del backup: 1,60; ✓ a 1,70 con molla 0,5 da scala 0,3.
        enum Backup {
            static let durata = 1.60
            static let ritardoSpunta = 1.70
            static let durataSpunta = 0.50
            static let scalaSpunta: CGFloat = 0.3
            static var animazione: Animation { Curva.backup.animazione(durata) }
            static var spunta: Animation { Curva.molla.animazione(durataSpunta) }
        }

        // MARK: Vera

        /// Sfera di Vera: gira in 6 s lineare, respira in 4 s (scala 1,045 a metà); pensa 0,90 × 2 (1 → 1,1 → 1).
        enum Sfera {
            static let giro = 6.0
            static let respiro = 4.0
            static let scalaRespiro: CGFloat = 1.045
            static let pensa = 0.90
            static let ripetizioniPensa = 2
            static let scalaPensa: CGFloat = 1.1
        }

        /// Bolla dell'utente: da y +14, scala 0,96.
        enum BollaUtente {
            static let durata = 0.42
            static let spostamento: CGFloat = 14
            static let scala: CGFloat = 0.96
            static var animazione: Animation { Curva.molla.animazione(durata) }
            static let ripiego = Molla(risposta: 0.42, smorzamento: 0.65)
        }

        /// Puntini «sta scrivendo»: ciclo 1,0, sfasati di 0,15, a 30% del ciclo y −5; con calma fermi a 0,4.
        enum Puntini {
            static let ciclo = 1.0
            static let sfasamento = 0.15
            static let picco: Double = 0.30
            static let salita: CGFloat = -5
            static let opacitaCalma: Double = 0.4
        }

        /// Attesa della risposta e testo parola per parola; con calma tutto insieme dopo 0,05.
        enum Testo {
            static let attesaRisposta = 0.90
            static let parola = 0.038
            static let ritardoCalmo = 0.05
        }

        /// Scheda dei calcoli di Vera: da y +10.
        enum SchedaCalcoli {
            static let durata = 0.50
            static let spostamento: CGFloat = 10
            static var animazione: Animation { Curva.uscita.animazione(durata) }
        }

        /// Domanda partita dalla scrivania.
        enum DomandaDaScrivania { static let ritardo = 0.70 }

        // MARK: Acqua

        /// Pioggia con «Riduci movimento»: forza 3 ogni 2,5 + rand·1,1 s; goccia al tocco di forza 10.
        enum PioggiaCalma {
            static let intervalloMinimo = 2.5
            static let intervalloCasuale = 1.1
            static let forza: Double = 3
            static let forzaTocco: Double = 10
        }
    }
}
