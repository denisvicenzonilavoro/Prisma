#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import SwiftUI

/// La presentazione all'incontro: le pagine di un documento a tutto schermo, una alla volta,
/// da sfogliare con le frecce mentre il cliente guarda. Si abbina alla modalità cliente.
struct Presentazione {
    let titolo: String
    let cliente: String
    let formato: CGSize
    let pagine: [AnyView]
    var pagina = 0
    /// Verso dell'ultimo giro di pagina (+1 avanti, −1 indietro): la pagina esce dal lato opposto.
    var direzione = 1
    /// La modalità cliente l'ha accesa la presentazione: all'uscita si spegne.
    var haAccesoModoCliente = false
    /// La finestra è passata a tutto schermo per la presentazione: all'uscita torna com'era.
    var haAccesoSchermoIntero = false
    /// Il cliente e l'appuntamento a cui vanno le annotazioni prese durante la presentazione.
    var clienteId: String?
    var appuntamentoId: String?
    var annotazioni = 0
    /// «Prospetto» o «Report», e il tipo del documento: servono al tavolo con l'iPad (la presa visione in Documenti).
    var genere = "Prospetto"
    var tipoDocumento: Documento.Tipo = .prospetto
    #if os(macOS)
    /// La finestra messa a tutto schermo: all'uscita si rimette com'era quella, non la finestra in primo piano.
    var finestra: NSWindow?
    #endif
}

extension StatoShell {
    /// Mostra il documento a tutto schermo. Per un documento di un cliente accende anche la modalità cliente.
    /// Prima la sala compare in dissolvenza sopra la scrivania, poi (a dissolvenza finita) la finestra passa a
    /// tutto schermo: sotto la sala non si reimpagina niente.
    /// `daPagina`: la pagina da cui si parte (quella dell'anteprima di Prospetti).
    func presenta(_ d: DocumentoStampabile, delCliente: Bool = true, daPagina: Int = 0) {
        guard !d.pagine.isEmpty else { return }
        var p = Presentazione(titolo: d.titolo, cliente: d.cliente, formato: d.formato, pagine: d.pagine)
        p.pagina = min(max(daPagina, 0), d.pagine.count - 1)
        p.genere = d.genere
        p.tipoDocumento = d.tipo
        if delCliente, let c = clienteAttivo {
            p.clienteId = c.id
            // Il fascicolo preparato dall'Agenda porta con sé l'appuntamento, se è proprio di questo cliente
            if case .fascicolo? = prospetto, let id = fascicoloAppuntamento,
               dati.appuntamenti.contains(where: { $0.id == id && $0.clienteId == c.id }) {
                p.appuntamentoId = id
            }
        }
        #if os(macOS)
        // La finestra da mettere a tutto schermo (nessuna se lo è già)
        var schermoIntero: NSWindow?
        if persistente, let finestra = NSApp.keyWindow, !finestra.styleMask.contains(.fullScreen) { schermoIntero = finestra }
        if let finestra = schermoIntero {
            p.haAccesoSchermoIntero = true
            p.finestra = finestra
        }
        #endif
        let accendeModoCliente = p.clienteId != nil && !inModoCliente
        // La sala per prima, con la sua dissolvenza; le modifiche senza animazione vengono dopo
        Movimenti.anima(Tema.Moto.Pannelli.presentazione, durata: Tema.Moto.Pannelli.durataPresentazione, animato: persistente) {
            presentazione = p
        }
        if accendeModoCliente {
            entraModoCliente(avviso: false)
            presentazione?.haAccesoModoCliente = inModoCliente
        }
        if pannelloNotifiche { pannelloNotifiche = false }
        if sistema.pannelloNovita { sistema.pannelloNovita = false }
        // La guida resterebbe sotto la sala con il suo Esc: si chiude (l'introduzione non si segna come vista)
        if sistema.guida != nil { sistema.guida = nil }
        // Nessun campo sotto il velo deve ricevere i tasti: il commento o la chat di Vera resterebbero scrivibili
        #if os(macOS)
        if persistente { NSApp.keyWindow?.makeFirstResponder(nil) }
        guard let finestra = schermoIntero else { return }
        let giro = sistema.giroPresentazione &+ 1
        sistema.giroPresentazione = giro
        Movimenti.dopo(Tema.Moto.Pannelli.durataPresentazione) { [weak self, weak finestra] in
            guard let self, let finestra, self.sistema.giroPresentazione == giro, self.presentazione != nil,
                  !finestra.styleMask.contains(.fullScreen) else { return }
            finestra.toggleFullScreen(nil)
        }
        #elseif os(iOS)
        // Su iPhone e iPad la sala è già a tutto schermo: basta togliere la tastiera dai campi sotto il velo
        if persistente { _ = UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        #endif
    }

    func paginaSeguente() {
        guard var p = presentazione, p.pagina < p.pagine.count - 1 else { return }
        p.pagina += 1
        p.direzione = 1
        mostraPagina(p)
    }

    func paginaPrecedente() {
        guard var p = presentazione, p.pagina > 0 else { return }
        p.pagina -= 1
        p.direzione = -1
        mostraPagina(p)
    }

    /// Le pagine girano come nel tema Apple (`.giroPaginaSala`): la transizione ha le sue curve, qui parte.
    private func mostraPagina(_ p: Presentazione) {
        guard persistente else {
            presentazione = p
            return
        }
        // La pagina che esce porta la transizione con cui è stata disegnata: se il verso cambia, prima il verso
        // (senza animazione), poi al giro dopo la pagina
        guard presentazione?.direzione == p.direzione else {
            presentazione?.direzione = p.direzione
            let pagina = p.pagina
            DispatchQueue.main.async { [weak self] in
                guard let self, var q = self.presentazione, pagina >= 0, pagina < q.pagine.count else { return }
                q.pagina = pagina
                withAnimation(Movimenti.curva(Tema.Moto.Pannelli.paginaPresentazione)) { self.presentazione = q }
            }
            return
        }
        withAnimation(Movimenti.curva(Tema.Moto.Pannelli.paginaPresentazione)) { presentazione = p }
    }

    /// Un'annotazione presa durante la presentazione: va negli appunti dell'incontro (quello dell'appuntamento,
    /// o quello di oggi, creato se manca) con il documento e la pagina; come attività, anche tra le cose da fare.
    func annotaPresentazione(_ testo: String, comeAttivita: Bool = false, oggi: Date = Date()) {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, var p = presentazione, let cliente = p.clienteId else { return }
        let cal = Calendar.current
        // Sempre e solo incontri e appuntamenti di questo cliente
        var incontro = dati.incontri.first { i in i.clienteId == cliente && (p.appuntamentoId.map { i.appuntamentoId == $0 } ?? false) }
            ?? dati.incontri.first { $0.clienteId == cliente && cal.isDate($0.data, inSameDayAs: oggi) }
        if incontro == nil {
            let a = p.appuntamentoId.flatMap { id in dati.appuntamenti.first { $0.id == id && $0.clienteId == cliente } }
            incontro = Incontro(clienteId: cliente, titolo: a?.titolo ?? "Incontro del \(CifreDoc.dataBreve(oggi))",
                                data: a?.inizio ?? Appuntamento.alMinuto(oggi), appuntamentoId: a?.id)
        }
        guard var i = incontro else { return }
        let riga = "• \(p.titolo), pagina \(p.pagina + 1): \(t)" + (comeAttivita ? " → attività" : "")
        i.appunti = i.appunti.isEmpty ? riga : i.appunti + "\n" + riga
        salvaIncontro(i)
        if comeAttivita {
            var a = Attivita.nuova(clienteId: cliente, scadenza: cal.date(byAdding: .day, value: 7, to: oggi) ?? oggi)
            a.titolo = t
            // Collegata all'appuntamento da cui nasce: si ritrova sotto di lui in Agenda
            a.appuntamentoId = p.appuntamentoId
            salvaAttivita(a)
        }
        p.annotazioni += 1
        presentazione = p
    }

    func chiudiPresentazione() {
        guard let p = presentazione else { return }
        sistema.giroPresentazione &+= 1
        Movimenti.anima(Tema.Moto.Pannelli.chiusuraPresentazione, durata: Tema.Moto.Pannelli.durataChiusuraPresentazione,
                        animato: persistente) {
            presentazione = nil
        }
        // Un genio o una chiusura in corso sotto la sala finiscono di colpo (dopo il cambio animato)
        annullaEffetti()
        if p.haAccesoModoCliente { esciModoCliente() }
        #if os(macOS)
        if p.haAccesoSchermoIntero, let finestra = p.finestra ?? NSApp.keyWindow, finestra.styleMask.contains(.fullScreen) {
            finestra.toggleFullScreen(nil)
        }
        #endif
    }
}


/// La sala della presentazione nel tema Apple (Design/template-apple-specifica.md §4.5.3): il velo
/// `rgba(6,14,20,.92)` sopra tutto (uguale in chiaro e in scuro), il foglio grande quanto lo spazio permette e in
/// basso i comandi del template: le frecce da 32, «1 di N», «Chiudi» bianco; in più «Annota» di Prisma.
/// Apertura: il velo in 0,40 s lineare (lo dà la shell), il foglio da scala 0,74/0,88 in 0,60 s con la curva
/// `uscita`; chiusura in 0,25 s. Le pagine girano con `.giroPaginaSala` (frecce a schermo, ← → della tastiera,
/// spazio e Invio, un clic sulla pagina). Sotto la sala opaca l'acqua si ferma (`StatoShell.scrivaniaCoperta`).
/// «Riduci movimento»: dissolvenze di 0,15 s; istantanee: tutto subito nello stato finale.
struct VistaPresentazione: View {
    @Environment(StatoShell.self) var stato
    let p: Presentazione
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var fermo
    /// Si sta scrivendo un'annotazione: le scorciatoie per sfogliare tacciono.
    @State private var scrivendo = false
    @State private var nota = ""
    @FocusState private var campo: Bool
    /// Il foglio è cresciuto fino alla scala a riposo.
    @State private var aperta = false

    var body: some View {
        let _ = ContaCorpi.segna()
        let s = Tema.Apple.Prospetti.Sala.self
        GeometryReader { geo in
            let cresciuta = aperta || fermo
            ZStack(alignment: .top) {
                s.velo
                    .ignoresSafeArea()
                titolo
                    .frame(height: s.margineAlto)
                    .frame(maxWidth: .infinity)
                // Foglio e comandi in colonna: la striscia del tavolo, quando c'è, toglie altezza al foglio
                // invece di finirgli sotto
                VStack(spacing: 0) {
                    GeometryReader { area in
                        let alto = max(1, area.size.height - s.sopraComandi)
                        let largo = max(1, area.size.width - s.margineLati * 2)
                        let scala = max(0.1, min(largo / p.formato.width, alto / p.formato.height))
                        ZStack {
                            foglio(scala)
                                .id(p.pagina)
                                .transition(AnyTransition.giroPaginaSala(direzione: p.direzione, calmo: calmo))
                        }
                        .frame(width: area.size.width, height: alto)
                        .scaleEffect(cresciuta ? 1 : Tema.Apple.Moto.Sala.scalaApertura)
                        .opacity(cresciuta ? 1 : 0)
                    }
                    #if os(macOS)
                    // I comandi del tavolo con l'iPad, aperti da «Al tavolo» (Shell/AlTavolo.swift)
                    if !scrivendo { StrisciaTavoloSala(tavolo: stato.tavolo, contesto: contestoTavolo) }
                    #endif
                    Group { if scrivendo { editor } else { comandi } }
                        .frame(height: s.altezzaComandi)
                        .padding(.bottom, s.comandiFondo)
                }
                .padding(.top, s.margineAlto)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            // Un clic sulla pagina va avanti, come in Presentazioni
            .contentShape(Rectangle())
            .onTapGesture { if !scrivendo { stato.paginaSeguente() } }
        }
        .onAppear(perform: apri)
        #if os(macOS)
        // Chiusa la sala, l'iPad non resta su una sua pagina
        .onDisappear { stato.tavolo.salaChiusa() }
        #endif
    }

    #if os(macOS)
    /// La pagina mostrata, il documento e il cliente presente, per il tavolo con l'iPad.
    private var contestoTavolo: ContestoTavolo {
        let d = DocumentoStampabile(titolo: p.titolo, cliente: p.cliente, genere: p.genere, formato: p.formato,
                                    pagine: p.pagine, tipo: p.tipoDocumento)
        return ContestoTavolo(documento: d, pagina: p.pagina, clienteId: p.clienteId ?? stato.clienteAttivoId, dallaSala: true)
    }
    #endif

    private func apri() {
        guard !aperta else { return }
        if fermo {
            aperta = true
            return
        }
        withAnimation(Tema.Apple.Moto.Sala.foglio) { aperta = true }
    }

    /// La pagina sul velo, con l'ombra della carta: resta sempre bianca e chiara.
    private func foglio(_ scala: CGFloat) -> some View {
        p.pagine[min(p.pagina, p.pagine.count - 1)]
            // In sala le etichette piccole (valori finali dei grafici, piede) si leggono da lontano
            .environment(\.documentoInSala, true)
            // La carta resta come sulla carta: «Dimensione del testo» non la ingrandisce
            .prismaScalaTesto(1)
            .frame(width: p.formato.width, height: p.formato.height)
            .scaleEffect(scala)
            .frame(width: p.formato.width * scala, height: p.formato.height * scala)
            .superficieApple(Tema.Apple.Superficie.carta)
    }

    /// In alto, discreto: di quale documento e di chi.
    private var titolo: some View {
        let s = Tema.Apple.Prospetti.Sala.self
        return Text("\(p.titolo) · \(p.cliente)")
            .carattereApple(s.titolo)
            .foregroundColor(s.coloreTitolo)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, s.margineLati)
    }

    private var comandi: some View {
        let s = Tema.Apple.Prospetti.Sala.self
        let ultima = p.pagine.count - 1
        return HStack(spacing: s.spazio) {
            FrecciaSalaApple(simbolo: "chevron.left", aiuto: "Pagina precedente") { stato.paginaPrecedente() }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(p.pagina == 0)
            Text("\(p.pagina + 1) di \(p.pagine.count)")
                .carattereApple(s.contatore)
                .foregroundColor(s.testo)
                .frame(minWidth: s.larghezzaContatore)
            FrecciaSalaApple(simbolo: "chevron.right", aiuto: "Pagina seguente") { stato.paginaSeguente() }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(p.pagina >= ultima)
            HStack(spacing: s.spazio) {
                #if os(macOS)
                PulsanteTavoloSala(tavolo: stato.tavolo)
                #endif
                if p.clienteId != nil {
                    Button { inizia() } label: {
                        Text(p.annotazioni == 0 ? "Annota" : "Annota · \(p.annotazioni)")
                    }
                    .buttonStyle(StileCapsulaSalaApple(chiara: false))
                    .keyboardShortcut("n", modifiers: [])
                    .help("Annota (N) una reazione o una decisione su questa pagina: va negli appunti dell'incontro")
                }
                Button("Chiudi") { stato.chiudiPresentazione() }
                    .buttonStyle(StileCapsulaSalaApple(chiara: true))
                    .keyboardShortcut(.cancelAction)
                    .help("Chiudi la presentazione (esc)")
            }
            .padding(.leading, s.sopraChiudi - s.spazio)
        }
        // Spazio e Invio vanno avanti, come in Keynote (pulsanti invisibili, solo per i tasti)
        .background {
            HStack(spacing: 0) {
                Button("") { stato.paginaSeguente() }.keyboardShortcut(.space, modifiers: [])
                Button("") { stato.paginaSeguente() }.keyboardShortcut(.return, modifiers: [])
            }
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)
        }
    }

    private func inizia() {
        nota = ""
        scrivendo = true
        // Il campo esiste solo dal prossimo giro: lì prende il fuoco
        DispatchQueue.main.async { campo = true }
    }

    private func salva(comeAttivita: Bool) {
        stato.annotaPresentazione(nota, comeAttivita: comeAttivita)
        scrivendo = false
    }

    /// La riga per scrivere: Invio salva negli appunti, ⌘Invio anche come attività, esc annulla.
    private var editor: some View {
        let s = Tema.Apple.Prospetti.Sala.self
        return HStack(spacing: s.spazio) {
            Text("Pagina \(p.pagina + 1)")
                .carattereApple(s.contatore)
                .foregroundColor(s.testo)
            TextField("", text: $nota, prompt: Text("Una reazione, una decisione, una cosa da fare…").foregroundColor(s.segnapostoCampo))
                .textFieldStyle(.plain)
                .carattereApple(s.contatore)
                .foregroundColor(s.testo)
                .focused($campo)
                .onSubmit { salva(comeAttivita: false) }
                .padding(s.paddingCampo)
                .frame(maxWidth: s.larghezzaCampo)
                .background { Capsule(style: .continuous).fill(s.fondoCampo) }
            Button("Salva come attività  ⌘↩") { salva(comeAttivita: true) }
                .buttonStyle(StileCapsulaSalaApple(chiara: false))
                .keyboardShortcut(.return, modifiers: .command)
            Button("Annulla") { scrivendo = false }
                .buttonStyle(StileCapsulaSalaApple(chiara: true))
                .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, s.margineLati)
    }
}

/// La freccia tonda della sala (`.arr` su fondo bianco al 12%, segno bianco).
private struct FrecciaSalaApple: View {
    let simbolo: String
    let aiuto: String
    let azione: () -> Void
    @Environment(\.isEnabled) private var abilitata

    var body: some View {
        let s = Tema.Apple.Prospetti.Sala.self
        Button(action: azione) {
            Image(systemName: simbolo)
                .carattereApple(s.carattereFreccia)
                .foregroundColor(s.testo)
                .frame(width: s.freccia, height: s.freccia)
                .background { Circle().fill(s.fondoFreccia) }
                .contentShape(Circle())
        }
        .buttonStyle(StileSemplice())
        .opacity(abilitata ? 1 : Tema.Apple.Prospetti.Anteprima.opacitaFrecciaSpenta)
        .help(aiuto)
        .accessibilityLabel(Text(aiuto))
    }
}

/// I pulsanti a capsula della sala: «Chiudi» bianco con il testo scuro, gli altri bianchi al 12% con il testo bianco.
/// Colori fissi: la sala è sempre scura.
/// Anche per «Al tavolo» e i comandi del tavolo nella sala (Shell/AlTavolo.swift).
struct StileCapsulaSalaApple: ButtonStyle {
    let chiara: Bool

    func makeBody(configuration: Configuration) -> some View {
        CapsulaSalaApple(etichetta: configuration.label, premuto: configuration.isPressed, chiara: chiara)
    }
}

struct CapsulaSalaApple: View {
    let etichetta: ButtonStyleConfiguration.Label
    let premuto: Bool
    let chiara: Bool
    @Environment(\.prismaStatoFinale) private var fermo

    var body: some View {
        let s = Tema.Apple.Prospetti.Sala.self
        let m = Tema.Apple.Moto.PulsantePremuto.self
        let forma = Capsule(style: .continuous)
        return etichetta
            .carattereApple(s.carattereChiudi)
            .foregroundColor(chiara ? s.testoChiudi : s.testo)
            .lineLimit(1)
            .padding(s.paddingChiudi)
            .background { forma.fill(chiara ? s.fondoChiudi : s.fondoAnnota) }
            .contentShape(forma)
            .scaleEffect(premuto && !fermo ? m.scala : 1)
            .animation(fermo ? nil : m.animazione, value: premuto)
            .fixedSize()
    }
}
