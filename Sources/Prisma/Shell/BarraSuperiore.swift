#if os(macOS)
import AppKit
#endif
import SwiftUI

/// Barra superiore del template Apple (Design/template-apple-specifica.md §3.3): alta 34, senza un fondo proprio;
/// ogni gruppo è una capsula di vetro a sé sopra l'acqua. A sinistra la pillola del marchio (porta alla scrivania)
/// e quella dell'app in primo piano (apre gli spazi di lavoro), al centro «lun 2 nov 23:09», a destra gli strumenti,
/// separati e a 6 l'uno dall'altro: Cerca ⌘K, la sfera di Vera, la campanella con il numero delle nuove, la guida,
/// il lucchetto, la modalità cliente e l'avatar. Il marchio comincia dopo i pulsanti veri della finestra del Mac,
/// alla loro altezza (`LettoreSemafori`). Al blocco svanisce e allo sblocco ricompare in 0,6 s (ShellView).
/// Dalla versione «Orizzonte», prima di Cerca, la pillola «✦ Novità» con il numero delle funzioni nuove (sul Mac).
struct BarraSuperiore: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.modoIstantanea) var modoIstantanea
    /// Dove sono i pulsanti veri della finestra del Mac (nil: non letti, o non ci sono).
    @State var semafori: PosizioneSemafori? = nil

    private typealias B = Tema.Apple.BarraAlta

    var body: some View {
        let _ = ContaCorpi.segna()
        let y = spostamentoVerticale
        ZStack {
            HStack(spacing: B.spazio) {
                marchio
                    .offset(y: y)
                appCorrente
                    .offset(y: y)
                Spacer(minLength: 20)
                // I vetri sono quasi alti quanto la barra: seguono i pulsanti finché resta un punto dal bordo
                strumenti
                    .offset(y: BarraSuperiore.limita(y, (Tema.Apple.Misura.Barra.altezza - B.tasto) / 2 - Tema.Misura.filo * 2))
            }
            // Fuori dallo schermo intero a sinistra ci sono i pulsanti della finestra del Mac
            .padding(.leading, margineSinistro)
            .padding(.trailing, B.margineDestro)
            .foregroundColor(Tema.Apple.Colore.inchiostroAcqua)

            orologio
                .offset(y: y)
        }
        .frame(height: Tema.Apple.Misura.Barra.altezza)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            // Nessun fondo (la barra sta sull'acqua): sul Mac solo il lettore dei semafori e la zona che trascina la finestra
            Color.clear
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
            #if os(macOS)
            if !modoIstantanea {
                ZStack(alignment: .top) {
                    // Legge dove sono i pulsanti veri della finestra (invisibile, non prende il mouse)
                    LettoreSemafori { nuova in
                        if semafori != nuova { semafori = nuova }
                    }
                    .allowsHitTesting(false)
                    AreaTrascinamento()
                }
                .frame(height: Tema.Apple.Misura.Barra.altezza)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            #endif
        }
    }

    /// Margine a sinistra: la pillola del marchio sta a `dopoSemafori` dal pulsante verde vero della finestra
    /// (letto da AppKit; se non si legge, dove sta di solito). A schermo intero i pulsanti non ci sono.
    private var margineSinistro: CGFloat {
        let m = Tema.Misura.Shell.self
        guard !stato.schermoIntero else { return B.margineDestro }
        let bordo = semafori?.bordoDestro ?? m.bordoSemaforiTipico
        return max(B.margineDestro, bordo + B.dopoSemafori)
    }

    /// Quanto spostare in verticale il contenuto della barra perché il suo centro stia su quello dei pulsanti
    /// veri della finestra; mai oltre lo spazio che il marchio ha nella barra.
    private var spostamentoVerticale: CGFloat {
        guard !stato.schermoIntero, let s = semafori else { return 0 }
        let altezza = Tema.Apple.Misura.Barra.altezza
        return BarraSuperiore.limita(s.centroVerticale - altezza / 2, (altezza - Tema.Misura.marchioBarra) / 2)
    }

    /// `valore` tenuto fra −`gioco` e +`gioco`.
    private static func limita(_ valore: CGFloat, _ gioco: CGFloat) -> CGFloat {
        min(max(valore, -gioco), gioco)
    }

    /// La pillola con il logo e «Prisma»: torna alla scrivania.
    private var marchio: some View {
        PulsanteBarra(aiuto: "Prisma: torna alla scrivania", forma: .pillola, azione: { stato.mostraScrivania() }) {
            HStack(spacing: B.spazioMarchio) {
                LogoPrisma(colore: Tema.Apple.Colore.logo)
                    .frame(height: B.logo)
                Text("Prisma")
                    .carattereApple(Tema.Apple.Carattere.barra)
            }
        }
    }

    /// La pillola con il nome dell'app in primo piano («Scrivania» se non ce n'è): apre gli spazi di lavoro.
    private var appCorrente: some View {
        PulsanteBarra(aiuto: "Spazi di lavoro", forma: .pillola, azione: {
            if stato.pannelloNotifiche { stato.pannelloNotifiche = false }
            if !stato.inModoCliente { stato.pannelloSpazi.toggle() }
        }) {
            TitoloAppAttiva()
        }
    }

    /// «lun 2 nov 23:09», 13 medium con le cifre tabellari.
    private var orologio: some View {
        TimelineView(.everyMinute) { contesto in
            // Nelle istantanee l'ora è ferma (la stessa della linea rossa dell'Agenda)
            let adesso = OraIstantanee.mostrata(contesto.date, istantanea: modoIstantanea)
            HStack(spacing: B.spazioOrologio) {
                Text(Formati.barraData.string(from: adesso))
                Text(Formati.ora.string(from: adesso))
            }
            .carattereApple(Tema.Apple.Carattere.orologio)
            .foregroundColor(Tema.Apple.Colore.inchiostroAcqua)
            .lineLimit(1)
        }
        .allowsHitTesting(false)
    }

    /// Gli strumenti a destra: ognuno è un vetro a sé sopra l'acqua (capsula per Cerca, cerchi da 28 per le icone),
    /// staccati l'uno dall'altro, senza una capsula comune che li raggruppi.
    private var strumenti: some View {
        HStack(spacing: B.spazio) {
            if stato.inModoCliente {
                ContrassegnoModoCliente()
            } else {
                #if os(macOS)
                // «✦ Novità» con il numero delle funzioni nuove, subito prima di Cerca (template-novita §1.1, §2.1)
                PulsanteBarra(aiuto: "Le novità di Prisma: \(NovitaLuce.allCases.count) funzioni da provare",
                              forma: .pillola, azione: { stato.alternaNovita() }) {
                    HStack(spacing: B.spazioNovita) {
                        Text("✦ Novità")
                            .carattereApple(Tema.Apple.Carattere.barra)
                            .foregroundColor(B.testoNovita)
                        Text("\(NovitaLuce.allCases.count)")
                            .carattereApple(B.pastigliaNovita)
                            .foregroundColor(B.testoSuColore)
                            .lineLimit(1)
                            .padding(B.paddingPastigliaNovita)
                            .background { Capsule(style: .continuous).fill(B.fondoPastigliaNovita) }
                            .fixedSize()
                    }
                }
                #endif

                PulsanteBarra(aiuto: "Cerca in Prisma (⌘K)", forma: .pillola, azione: { stato.alternaRicerca() }) {
                    HStack(spacing: B.spazioCerca) {
                        Image(systemName: "magnifyingglass")
                            .carattereApple(B.simbolo)
                        Text("Cerca")
                            .carattereApple(Tema.Apple.Carattere.barra)
                        Text("⌘K")
                            .carattereApple(B.scorciatoia)
                            .opacity(B.opacitaScorciatoia)
                    }
                }

                #if os(macOS)
                // La sfera di Vera: apre la mini finestra (anche ⌥ Spazio, da qualsiasi app)
                PulsanteSferaVera(mini: stato.miniVera)
                    .frame(width: B.tasto, height: B.tasto)
                    .vetro(.leggero, forma: .capsula)
                    .puntoAcqua(.sferaVeraBarra)
                #endif

                PulsanteBarra(aiuto: "Notifiche", azione: { stato.alternaNotifiche() }) {
                    simbolo("bell")
                }
                .overlay(alignment: .topTrailing) {
                    // Il numero sta sul bordo del cerchio, fuori dal vetro
                    let n = stato.notificheNuove
                    if n > 0 {
                        BadgeCampanella(numero: n)
                            .offset(x: B.spostamentoBadge.width, y: B.spostamentoBadge.height)
                            .allowsHitTesting(false)
                    }
                }
                // Una notifica nuova arriva come una goccia qui (OsservatoreAcqua) e porta la sua posizione
                // nell'evento «notifica nuova» (EventiShell.swift)
                .puntoAcqua(.campanella)
                .segnaCampanella()
            }

            // La guida di Prisma (anche in modalità cliente): come funziona, le app, le parole
            PulsanteBarra(aiuto: "Guida di Prisma: come funziona, le app, le parole (⌘?)",
                          azione: { stato.apriGuida(.app(stato.appAttiva ?? .clienti)) }) {
                simbolo("questionmark")
            }

            PulsanteBarra(aiuto: "Blocca Prisma: la schermata di benvenuto", azione: { stato.blocca() }) {
                simbolo("lock")
            }

            PulsanteBarra(aiuto: stato.inModoCliente ? "Esci dalla modalità cliente (⌥⌘M)"
                                                     : "Modalità cliente: mostra solo il cliente attivo, per girare lo schermo (⌥⌘M)",
                          azione: { if stato.inModoCliente { stato.esciModoCliente() } else { stato.entraModoCliente() } }) {
                simbolo(stato.inModoCliente ? "person.fill.checkmark" : "person.crop.rectangle")
            }

            // L'avatar è già un cerchio a sé: niente vetro attorno
            PulsanteBarra(aiuto: "Impostazioni", forma: nil, azione: { stato.apri(.impostazioni) }) {
                AvatarUtente(iniziali: stato.inizialiUtente)
            }
        }
        .foregroundColor(Tema.Apple.Colore.inchiostroAcqua)
        .frame(height: B.tasto)
        // Vetri separati (spazio 0: non si fondono), campionati insieme sul vetro nativo di macOS 26
        .gruppoVetro()
    }

    /// Un simbolo di sistema al centro di un tasto tondo.
    private func simbolo(_ nome: String) -> some View {
        Image(systemName: nome)
            .carattereApple(B.simbolo)
            .frame(width: Tema.Misura.iconaBarra, height: Tema.Misura.iconaBarra)
    }
}

/// Il nome dell'app in primo piano («Scrivania» se non ce n'è): osserva solo le finestre,
/// così il resto della barra non si ridisegna quando si cambia app.
private struct TitoloAppAttiva: View {
    @Environment(StatoFinestre.self) var sistema

    var body: some View {
        Text(sistema.appAttiva?.titolo ?? "Scrivania")
            .carattereApple(Tema.Apple.Carattere.barra)
            .lineLimit(1)
    }
}

/// Pulsante della barra: un vetro a sé sopra l'acqua (cerchio da 28 per le icone, pillola per marchio, app e
/// Cerca), che si schiarisce al passaggio del mouse. `forma` nil: niente vetro (l'avatar).
private struct PulsanteBarra<Etichetta: View>: View {
    let aiuto: String
    /// .pillola: larga quanto il contenuto (padding 5×11); il cerchio (predefinito) è un tasto da 28.
    var forma: FormaElementoBarra? = .cerchio
    let azione: () -> Void
    @ViewBuilder let etichetta: () -> Etichetta
    @State var sopra = false

    var body: some View {
        Button(action: azione) {
            corpo
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(StileSemplice())
        .onHover { s in withAnimation(Tema.Moto.passaggio) { sopra = s } }
        .help(aiuto)
    }

    @ViewBuilder private var corpo: some View {
        let B = Tema.Apple.BarraAlta.self
        let tinta: Color? = sopra ? B.passaggio : nil
        switch forma {
        case .some(.cerchio):
            etichetta()
                .frame(width: B.tasto, height: B.tasto)
                .vetro(.leggero, forma: .capsula, tinta: tinta, interattivo: true)
        case .some(.pillola):
            etichetta()
                .padding(B.paddingPillola)
                .frame(minHeight: Tema.Misura.marchioBarra)
                .vetro(.leggero, forma: .capsula, tinta: tinta, interattivo: true)
        case .none:
            etichetta()
                .frame(minWidth: B.tasto, minHeight: B.tasto)
        }
    }
}

/// Forma del vetro di un pulsante della barra.
private enum FormaElementoBarra {
    case cerchio, pillola
}

/// Il numero delle notifiche nuove sulla campanella: capsula `#FF3B30`, 9 bold bianco, padding 1×4.
private struct BadgeCampanella: View {
    let numero: Int

    var body: some View {
        Text("\(numero)")
            .carattereApple(Tema.Apple.Carattere.badge)
            .foregroundColor(Tema.Apple.BarraAlta.testoSuColore)
            .lineLimit(1)
            .padding(Tema.Apple.BarraAlta.paddingBadge)
            .background { Capsule(style: .continuous).fill(Tema.Apple.Colore.rossoBadge) }
            .fixedSize()
            .accessibilityLabel(numero == 1 ? "1 notifica nuova" : "\(numero) notifiche nuove")
    }
}

/// Avatar del consulente: cerchio da 28 con il gradiente verticale del template e le iniziali bianche.
private struct AvatarUtente: View {
    let iniziali: String

    var body: some View {
        let lato = Tema.Apple.BarraAlta.avatar
        Text(iniziali)
            .carattereApple(Tema.Apple.BarraAlta.iniziali)
            .foregroundColor(Tema.Apple.BarraAlta.testoSuColore)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: lato, height: lato)
            .background {
                Circle()
                    .fill(LinearGradient(colors: [Tema.Apple.Colore.avatarDVAlto, Tema.Apple.Colore.avatarDVBasso],
                                         startPoint: .top, endPoint: .bottom))
            }
    }
}

/// Tasto della scorciatoia (kbd): pozzetto arrotondato con il testo secondario.
struct TastoBarra: View {
    let testo: String

    var body: some View {
        Text(testo)
            .font(Tema.Testo.Shell.tastoBarra)
            .foregroundColor(Tema.Colore.inchiostroSecondario)
            .padding(Tema.Misura.Shell.tastoMargine)
            .background(RoundedRectangle(cornerRadius: Tema.Raggio.tasto, style: .continuous).fill(Tema.Colore.pozzetto))
    }
}

/// Campanella della barra (tracciato SVG del template, viewBox 24).
struct SimboloCampanella: Shape {
    func path(in r: CGRect) -> Path {
        let s = min(r.width, r.height) / 24
        var p = Path()
        p.move(to: CGPoint(x: 6, y: 17))
        p.addLine(to: CGPoint(x: 18, y: 17))
        p.addLine(to: CGPoint(x: 16.5, y: 14))
        p.addLine(to: CGPoint(x: 16.5, y: 9))
        p.addArc(center: CGPoint(x: 12, y: 9), radius: 4.5, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
        p.addLine(to: CGPoint(x: 7.5, y: 14))
        p.closeSubpath()
        p.move(to: CGPoint(x: 10, y: 20))
        p.addLine(to: CGPoint(x: 14, y: 20))
        p.move(to: CGPoint(x: 12, y: 3))
        p.addLine(to: CGPoint(x: 12, y: 4))
        return p.applying(CGAffineTransform(scaleX: s, y: s).concatenating(CGAffineTransform(translationX: r.minX, y: r.minY)))
    }
}

/// Lucchetto della barra (tracciato SVG del template, viewBox 24).
struct SimboloLucchetto: Shape {
    func path(in r: CGRect) -> Path {
        let s = min(r.width, r.height) / 24
        var p = Path()
        p.addRoundedRect(in: CGRect(x: 6, y: 10, width: 12, height: 10), cornerSize: CGSize(width: 2, height: 2))
        p.move(to: CGPoint(x: 9, y: 10))
        p.addLine(to: CGPoint(x: 9, y: 6))
        p.addArc(center: CGPoint(x: 12, y: 6), radius: 3, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: 15, y: 10))
        return p.applying(CGAffineTransform(scaleX: s, y: s).concatenating(CGAffineTransform(translationX: r.minX, y: r.minY)))
    }
}

#if os(macOS)
/// Zona della barra che trascina la finestra macOS (doppio clic: ingrandisce, come la barra del titolo).
struct AreaTrascinamento: NSViewRepresentable {
    final class Vista: NSView {
        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 {
                window?.zoom(nil)
            } else {
                window?.performDrag(with: event)
            }
        }
    }

    func makeNSView(context: Context) -> Vista { Vista() }
    func updateNSView(_ nsView: Vista, context: Context) {}
}
#endif
