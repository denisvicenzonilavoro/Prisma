import SwiftUI

// MARK: - Gettoni dell'app Vera (tema Liquid Glass: .vera-ctx, .engine, .chat, .msg, .bub, .sugg, .composer, .ico-btn)

extension Tema.Colore {
    /// Colori della conversazione con Vera: tutti ricavati dai gettoni comuni del tema (chiaro e scuro).
    enum VeraChat {
        /// Colonna del contesto, a sinistra: appena più scura della conversazione, come una barra laterale.
        static let fondoContesto = Tema.Colore.rigaSopra
        /// Filo tra il contesto e la conversazione e sotto la barra.
        static let divisore = Tema.Colore.separatore

        // Inchiostri
        static let testo = Tema.Colore.inchiostro
        static let testoSecondario = Tema.Colore.inchiostroSecondario
        static let testoTerziario = Tema.Colore.inchiostroTerziario

        // Bolle (.msg.vera .bub, .msg.mine .bub)
        /// La bolla di Vera: grigia come i messaggi in arrivo del Mac, sul bianco della scheda.
        static let bollaVera = Tema.Colore.pozzetto
        static let bordoBollaVera = Tema.Colore.bordoScheda
        /// La tua bolla: piena dell'accento, testo bianco.
        static let bollaTua = Tema.Colore.accento
        static let testoTuo = Tema.Colore.Componenti.testoSuColore
        /// Riquadro delle proposte dentro la bolla di Vera.
        static let gruppoProposte = Tema.Colore.scheda
        static let bordoGruppoProposte = Tema.Colore.bordoScheda

        // Spunti (.sugg) e tasti tondi (.ico-btn)
        static let spunto = Tema.Colore.pozzetto
        static let spuntoSopra = Tema.Colore.pozzettoScuro
        static let bordoSpunto = Tema.Colore.separatore
        static let simboloSpunto = Tema.Colore.link
        static let tastoNeutro = Tema.Colore.pozzetto
        static let tastoNeutroSopra = Tema.Colore.pozzettoScuro
        static let simboloTastoNeutro = Tema.Colore.inchiostroSecondario

        // Scrittura (.composer)
        static let composer = Tema.Colore.finestraPiena
        static let bordoComposer = Tema.Colore.bordoScheda
        /// Microfono acceso, dettatura del Mac, errori della voce.
        static let ascolto = Tema.Colore.rosso

        // Stato di Qwen (.engine) e voce
        static let pronto = Tema.Colore.verde
        static let nonPronto = Tema.Colore.arancio
        static let voce = Tema.Colore.accento
        static let statoVoce = Tema.Colore.pozzetto

        // La giornata
        static let incontroSopra = Tema.Colore.pozzetto
        static let incontroScelto = Tema.Colore.selezione
        static let barraIncontro = Tema.Colore.pozzettoScuro
        static let barraIncontroScelto = Tema.Colore.accento
        /// «Da non dimenticare»: tessera appena tinta d'arancio, come le pillole delle proposte.
        static let promemoria: Color = Tema.Colore.arancio.opacity(0.13)
        static let bordoPromemoria: Color = Tema.Colore.arancio.opacity(0.3)
        static let occhielloPromemoria = Tema.Colore.testoProposta
        static let tesseraSopra = Tema.Colore.rigaSopra
    }
}

extension Tema.Raggio {
    /// Raggi della conversazione con Vera.
    enum VeraChat {
        /// Il contenitore unico (contesto + conversazione), come la rubrica di Clienti.
        static let contenitore = Tema.Raggio.scheda
        /// Bolle: 20 pt, l'angolo verso chi parla 6 pt.
        static let bolla = Tema.Raggio.bolla
        static let bollaAngolo = Tema.Raggio.bollaAngolo
        static let gruppoProposte = Tema.Raggio.riga
        /// Il campo di scrittura: capsula finché è su una riga, angoli morbidi quando cresce.
        static let composer: CGFloat = 23
        static let motore = Tema.Raggio.gruppo
        static let incontro = Tema.Raggio.voceLaterale
        static let tessera = Tema.Raggio.tessera
    }
}

extension Tema.Misura {
    /// Misure della conversazione con Vera.
    enum VeraChat {
        // Colonna del contesto (.side con .vera-ctx)
        static let contesto: CGFloat = 280
        /// Vera affiancata a un'altra app: sotto questa larghezza della finestra il contesto si stringe.
        static let sogliaContestoStretto: CGFloat = 700
        static let contestoStretto: CGFloat = 220
        /// In fondo alla colonna del contesto le tessere sfumano invece di finire tagliate.
        static let sfumaturaContesto: CGFloat = 24
        static let margineContesto: CGFloat = 14
        static let spazioContesto: CGFloat = 18
        static let spazioSezione: CGFloat = 8
        static let sferaContesto: CGFloat = 48
        static let spazioSaluto: CGFloat = 6
        static let margineMotore = EdgeInsets(top: 10, leading: 12, bottom: 11, trailing: 12)
        static let spia: CGFloat = 8
        /// La spia sta sulla prima riga del testo del motore.
        static let spiaAlto: CGFloat = 4
        static let margineVerifica = EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
        static let margineIncontro = EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 10)
        static let barraIncontro: CGFloat = 3
        static let barraIncontroRientro: CGFloat = 5
        static let spazioIncontri: CGFloat = 2
        static let marginePromemoria = EdgeInsets(top: 10, leading: 12, bottom: 11, trailing: 12)
        static let margineTessera = EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12)
        static let spazioTessere: CGFloat = 8
        static let altezzaAmbito: CGFloat = 28
        /// Spazio tra le righe di testo dentro una voce (titolo e nota): stretto, medio, del promemoria.
        static let righeStrette: CGFloat = 1
        static let righe: CGFloat = 2
        static let righePromemoria: CGFloat = 3

        // Barra della conversazione
        static let barra: CGFloat = 52
        static let margineBarra: CGFloat = 16
        static let statoVoce: CGFloat = 26
        static let margineStatoVoce: CGFloat = 10
        static let spiaVoce: CGFloat = 7
        static let scalaOnda: CGFloat = 0.7
        /// L'onda nella capsula della barra: le prime 14 barre, per lasciare spazio ai comandi della voce.
        static let barreOnda = 14
        /// L'onda a riposo quando Qwen non è pronto: spenta.
        static let opacitaOndaSpenta: Double = 0.35
        static let margineAzioneBarra = EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)

        // Conversazione (.chat, .msg, .bub)
        static let colonnaChat: CGFloat = 820
        static let margineChat: CGFloat = 20
        static let margineChatVerticale: CGFloat = 18
        static let spazioMessaggi: CGFloat = 14
        static let sferaMessaggio: CGFloat = 26
        static let spazioSfera: CGFloat = 10
        /// Spazio minimo lasciato libero accanto alle bolle: le tue a destra, quelle di Vera a sinistra.
        static let respiroBollaTua: CGFloat = 90
        static let respiroBollaVera: CGFloat = 36
        static let margineBolla = EdgeInsets(top: 10, leading: 14, bottom: 11, trailing: 14)
        static let spazioBolla: CGFloat = 6
        /// Interlinea del testo nelle bolle (line-height 1,45 del tema).
        static let interlinea: CGFloat = 3
        static let margineProposta = EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 6)
        static let azione: CGFloat = 24
        static let margineAzione: CGFloat = 10
        static let spazioAzioni: CGFloat = 6
        static let sferaBenvenuto: CGFloat = 52
        static let testoBenvenuto: CGFloat = 470
        static let margineBenvenuto: CGFloat = 36
        /// L'ultima risposta sfuma sopra la fila degli spunti.
        static let sfumaturaMessaggi: CGFloat = 24

        // Spunti (.sugg) e scrittura (.composer, .ico-btn)
        static let spunto: CGFloat = 30
        static let margineSpunto: CGFloat = 12
        static let spazioSpunto: CGFloat = 6
        static let spazioSpunti: CGFloat = 8
        static let sfumaturaSpunti: CGFloat = 40
        static let margineScrittura = EdgeInsets(top: 8, leading: 20, bottom: 12, trailing: 20)
        static let spazioScrittura: CGFloat = 8
        static let margineComposer = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 6)
        static let tasto: CGFloat = 34
        static let filoAscolto: CGFloat = 1.5
    }
}

extension Tema.Testo {
    /// Caratteri della conversazione con Vera (SF, come il tema).
    enum VeraChat {
        // Contesto
        static let nome = Tema.Testo.sf(15, .bold)
        static let ruolo = Tema.Testo.sf(12)
        static let sezione = Tema.Testo.sf(11.5, .semibold)
        static let data = Tema.Testo.sf(11.5, .medium)
        static let motore = Tema.Testo.sf(12.5, .semibold)
        static let motoreNota = Tema.Testo.sf(11.5)
        static let ambito = Tema.Testo.sf(12.5, .medium)
        static let incontroOra = Tema.Testo.sf(11, .medium).monospacedDigit()
        static let incontroTitolo = Tema.Testo.sf(12.5, .semibold)
        static let incontroNota = Tema.Testo.sf(11)
        static let promemoria = Tema.Testo.sf(12.5, .medium)
        static let quadroNumero = Tema.Testo.sf(18, .semibold, arrotondato: true)
        static let quadroVoce = Tema.Testo.sf(11)

        // Barra
        static let titoloBarra = Tema.Testo.sf(13, .semibold)
        static let sottotitoloBarra = Tema.Testo.sf(11.5)
        static let statoVoce = Tema.Testo.sf(10.5, .semibold)
        static let spaziaturaStatoVoce = Tema.Testo.spaziatura(0.06, 10.5)

        // Bolle
        static let autore = Tema.Testo.sf(11, .semibold)
        static let titoloRisposta = Tema.Testo.sf(14, .semibold)
        static let messaggio = Tema.Testo.sf(13.5)
        static let proposta = Tema.Testo.sf(12.5, .medium)
        static let azione = Tema.Testo.sf(11.5, .medium)
        static let benvenuto = Tema.Testo.sf(22, .bold)
        static let spaziaturaBenvenuto = Tema.Testo.spaziatura(-0.015, 22)
        static let benvenutoTesto = Tema.Testo.sf(13)
        static let benvenutoNota = Tema.Testo.sf(12)

        // Scrittura
        static let spunto = Tema.Testo.sf(12.5)
        static let campo = Tema.Testo.sf(14)
        static let suggerimento = Tema.Testo.sf(11)
        static let simboloTasto = Font.system(size: 15 * Tipo.fattore, weight: .semibold)
    }
}

extension Tema.Ombra {
    /// Ombre della conversazione con Vera.
    enum VeraChat {
        /// Il campo di scrittura galleggia appena (0 10px 30px -12px del tema, resa senza espansione).
        static let composer = StratoOmbra(colore: Color(r: 0, g: 0, b: 0, a: 0.14), y: 6, sfocatura: 18)
        /// Le bolle: un'ombra appena percettibile.
        static let bolla = StratoOmbra(colore: Color(r: 0, g: 0, b: 0, a: 0.05), y: 1, sfocatura: 2)
    }
}

// MARK: - Componenti

// Nel tema Apple (Design/template-apple-specifica.md §4.7) le bolle, gli spunti e i tasti tondi di Vera sono quelli
// del template: li usano l'app Vera, la Vera della scrivania e Vera su iPhone e iPad. Gettoni in Tema.Apple+Vera.swift.

/// Forma di una bolla: 20 agli angoli, 6 in basso dal lato di chi parla (Vera a sinistra, tu a destra).
func formaBollaVera(mia: Bool) -> RettangoloAngoli {
    let r = Tema.Apple.Vera.Bolla.raggio
    let a = Tema.Apple.Vera.Bolla.angolo
    return RettangoloAngoli(altoSinistra: r, altoDestra: r, bassoDestra: mia ? a : r, bassoSinistra: mia ? r : a)
}

extension View {
    /// Fondo della bolla: `chip` per Vera, pieno dell'accento per te (niente bordi né ombre, come nel template).
    func bollaVera(mia: Bool) -> some View {
        let b = Tema.Apple.Vera.Bolla.self
        return background {
            formaBollaVera(mia: mia).fill(mia ? b.fondoUtente : b.fondoVera)
        }
    }
}

/// Uno spunto (`.sugg` del template): capsula `card` col filo, 13 medium, padding 8×14; sotto il puntatore sale
/// di 2 con la molla di 0,25 s. Il simbolo resta per chi lo legge con VoiceOver: il template non lo disegna.
struct PillolaSpuntoVera: View {
    let simbolo: String
    let testo: String
    @State private var sopra = false
    @Environment(\.isEnabled) private var abilitato
    @Environment(\.prismaStatoFinale) private var fermo

    init(simbolo: String, testo: String) {
        self.simbolo = simbolo
        self.testo = testo
    }

    var body: some View {
        let c = Tema.Apple.Vera.Campo.self
        let alzato = sopra && abilitato && !fermo
        Text(testo)
            .carattereApple(c.suggerimento)
            .foregroundColor(c.coloreSuggerimento)
            .lineLimit(1)
            .padding(c.paddingSuggerimento)
            .background {
                Capsule(style: .continuous)
                    .fill(c.fondoSuggerimento)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(c.bordoSuggerimento, lineWidth: Tema.Apple.Misura.bordo)
                    }
            }
            .contentShape(Capsule(style: .continuous))
            .opacity(abilitato ? 1 : c.opacitaSpento)
            .offset(y: alzato ? Tema.Apple.Moto.SuggerimentoSopra.spostamento : 0)
            .animation(fermo ? nil : Tema.Apple.Moto.SuggerimentoSopra.animazione, value: alzato)
            .onHover { sopra = $0 }
            .accessibilityLabel(Text(testo))
    }
}

/// Piccola capsula d'azione sotto una risposta di Vera (Crea attività, Copia, Apri in Agenda…).
struct ChipAzioneVera: View {
    let titolo: String
    @State private var sopra = false

    init(titolo: String) {
        self.titolo = titolo
    }

    var body: some View {
        let m = Tema.Misura.VeraChat.self
        Text(titolo)
            .font(Tema.Testo.VeraChat.azione)
            .foregroundColor(Tema.Colore.VeraChat.testo)
            .lineLimit(1)
            .padding(.horizontal, m.margineAzione)
            .frame(height: m.azione)
            .vetro(.chip, forma: .capsula, riempimento: sopra ? Tema.Colore.chipControlloSopra : nil)
            .contentShape(FormaVetro.capsula)
            .onHover { sopra = $0 }
    }
}

/// Tasto tondo del campo di scrittura: invio da 36 pieno dell'accento («↑»), microfono `chip`, rosso mentre
/// Vera ascolta. Premuto: scala 0,95 con la molla di 0,25 s.
struct StileTastoVera: ButtonStyle {
    enum Aspetto { case neutro, invio, ascolto }
    let aspetto: Aspetto

    func makeBody(configuration: Configuration) -> some View {
        TastoTondoVera(etichetta: configuration.label, aspetto: aspetto, premuto: configuration.isPressed)
    }
}

/// Il corpo del tasto tondo: cerchio pieno, luminosità sotto il puntatore e pressione a molla.
struct TastoTondoVera<Etichetta: View>: View {
    let etichetta: Etichetta
    let aspetto: StileTastoVera.Aspetto
    let premuto: Bool
    @State private var sopra = false
    @Environment(\.isEnabled) private var abilitato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    init(etichetta: Etichetta, aspetto: StileTastoVera.Aspetto, premuto: Bool) {
        self.etichetta = etichetta
        self.aspetto = aspetto
        self.premuto = premuto
    }

    var body: some View {
        let c = Tema.Apple.Vera.Campo.self
        let p = Tema.Apple.Moto.PulsantePremuto.self
        etichetta
            .carattereApple(c.simboloTasto)
            .foregroundColor(aspetto == .neutro ? c.simboloMicrofono : c.simboloInvio)
            .frame(width: c.tasto, height: c.tasto)
            .background { Circle().fill(fondo) }
            .brightness(sopra && abilitato && !istantanea ? p.luminositaSopra - 1 : 0)
            .contentShape(Circle())
            .scaleEffect(premuto && !istantanea ? p.scala : 1)
            .animation(Tema.Apple.Moto.animazione(p.animazione, calmo: calmo, istantanea: istantanea), value: premuto)
            .opacity(abilitato ? 1 : c.opacitaSpento)
            .onHover { sopra = $0 }
    }

    private var fondo: Color {
        let c = Tema.Apple.Vera.Campo.self
        switch aspetto {
        case .neutro: return c.fondoMicrofono
        case .invio: return c.fondoInvio
        case .ascolto: return c.fondoAscolto
        }
    }
}

/// Titolo di una sezione della colonna del contesto (.side-sec del tema), con un testo facoltativo a destra.
struct SezioneContestoVera: View {
    let titolo: String
    var dettaglio: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tema.Misura.VeraChat.spazioSezione) {
            Text(titolo)
                .font(Tema.Testo.VeraChat.sezione)
                .foregroundColor(Tema.Colore.VeraChat.testoTerziario)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let dettaglio {
                Text(dettaglio)
                    .font(Tema.Testo.VeraChat.data)
                    .foregroundColor(Tema.Colore.VeraChat.testoSecondario)
                    .lineLimit(1)
            }
        }
    }
}
