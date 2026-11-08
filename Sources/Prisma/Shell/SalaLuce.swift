import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// Sala › Il prisma di luce (Design/template-luce-specifica.md §2.2, «Luce» giro 4).
//
//   IL PATRIMONIO FINANZIARIO DI GIULIA ROSSI          (Per investimento | Per obiettivo | Per canale)
//   204.050 € oggi
//                         ╱╲            ● Azionario
//   ━━━━━━━━━━━━━━━━━━━━ ╱  ╲ ═══════   38% · 77.539 €
//                       ╱────╲ ═══════  ● Obbligazionario …
//   ┌ PASSA SUI RAGGI ┐ ~~~~~~ riflesso ~~~~~~             OGGI ────●──── FRA VENT'ANNI
//
// Il palco è sempre notte. La scena la disegna lo shader (`TelaLuceMetal`, `ShaderLuce`); nelle istantanee, con
// «Riduci movimento» senza Metal o se lo shader non si compila, `PrismaDiLuceFermo`. Sopra, in SwiftUI: l'occhiello, il
// totale che si conta, il segmentato scuro, le etichette in fondo ai raggi, il pannello del dettaglio e il cursore degli
// anni. Le cifre vengono da `MotoreLuce` (composizione di Analisi 360, obiettivi, canali, linea della vita).
// - Puntatore sul ventaglio: la fascia si accende, le altre si spengono, il pannello dice la cifra. Clic: la scelta
//   resta (per parlarne con il cliente) finché non si clicca altrove (proposta del §2.2.4).
// - Trascinamento: ruota il cristallo (anche con «Riduci movimento»: è un gesto).
// - Per canale: le etichette portano anche l'etichetta del canale a parole.

/// Lo stato di prova per le istantanee (`StatoSala.provaLuce`).
struct ProvaLuce: Equatable {
    var vista: VistaLuce = .investimento
    /// true: l'anno all'estremo destro del cursore.
    var fraVentAnni = false
    /// Il nome della fascia scelta (per esempio «Azionario»).
    var scelta: String?
}

struct PalcoLuce: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    /// Sulla sala opaca della presentazione.
    var inSala = false
    @StateObject private var tela = StatoTelaLuce()

    var body: some View {
        let _ = ContaCorpi.segna()
        let id = cliente.id
        let esito = CacheLuce.esito(cliente: stato.cliente(id) ?? cliente, posizioni: stato.posizioniCliente(id),
                                    obiettivi: stato.obiettiviCliente(id), eventi: stato.eventiVitaCliente(id),
                                    analisi: stato.dati.analisi[id])
        CorpoLuce(cliente: cliente, esito: esito, tela: tela, prova: stato.sala.provaLuce,
                  aggiungiPosizione: { stato.apri(.posizioni) }, completaAnagrafica: { stato.apriCliente(id) })
            .environment(\.colorScheme, .dark)
    }
}

/// La memoria del calcolo: `MotoreLuce.calcola` prepara anche la linea della vita, non va rifatto a ogni passaggio del
/// puntatore.
enum CacheLuce {
    nonisolated(unsafe) private static var memoria: [Int: EsitoLuce] = [:]
    private static let massimo = 8

    static func esito(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], eventi: [EventoLineaVita],
                      analisi: Analisi360?, oggi: Date = Date()) -> EsitoLuce {
        var h = Hasher()
        h.combine(cliente)
        h.combine(posizioni)
        h.combine(obiettivi)
        h.combine(eventi)
        h.combine(analisi != nil)
        if let a = analisi {
            h.combine(a.previdenza.etaPensione)
            h.combine(a.previdenza.redditoDesiderato)
            h.combine(a.previdenza.pensionePubblica)
            h.combine(a.previdenza.rendimentoReale)
        }
        h.combine(Calendar.current.startOfDay(for: oggi))
        let chiave = h.finalize()
        if let e = memoria[chiave] { return e }
        let e = MotoreLuce.calcola(cliente: cliente, posizioni: posizioni, obiettivi: obiettivi, eventi: eventi,
                                   analisi: analisi, oggi: oggi)
        if memoria.count >= massimo { memoria.removeAll() }
        memoria[chiave] = e
        return e
    }
}

/// I colori dei raggi sul fondo notte.
enum ColoriLuce {
    private typealias R = Tema.Apple.Luce.Raggi

    static func colori(_ fasce: [FasciaLuce]) -> [Color] {
        var usate: [AreaBisogno] = []
        return fasce.map { f in
            switch f.tinta {
            case .classe(let c):
                switch c {
                case .azionario: return R.azionario
                case .obbligazionario: return R.obbligazionario
                case .gestioneSeparata: return R.gestioneSeparata
                case .liquidita: return R.liquidita
                }
            case .obiettivo(let area, let i):
                defer { usate.append(area) }
                return usate.contains(area) ? R.obiettiviAggiunti[i % R.obiettiviAggiunti.count]
                    : Tema.Apple.Clienti.Obiettivi.colore(area)
            case .altro: return R.altro
            case .canale(let k): return k == .alleanza ? R.alleanza : R.indipendente
            }
        }
    }

    /// I valori sRGB 0…1 del colore, come `rgb()` del template (lo shader li usa così come sono).
    static func srgb(_ c: Color) -> SIMD3<Float> {
        #if os(macOS)
        let n = NSColor(c).usingColorSpace(.sRGB) ?? NSColor.white
        return SIMD3(Float(n.redComponent), Float(n.greenComponent), Float(n.blueComponent))
        #else
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3(Float(r), Float(g), Float(b))
        #endif
    }
}

private struct CorpoLuce: View {
    let cliente: Cliente
    let esito: EsitoLuce
    /// La rotazione che cambia a ogni fotogramma la osservano solo le etichette e il puntatore.
    let tela: StatoTelaLuce
    let prova: ProvaLuce?
    let aggiungiPosizione: () -> Void
    let completaAnagrafica: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaStatoFinale) private var statoFinale
    @ObservedObject private var visibilita = VisibilitaPrisma.condivisa

    @State private var vista: VistaLuce = .investimento
    @State private var anno: Int?
    @State private var sotto: Int?
    @State private var fissata: Int?
    @State private var etichetteAccese = false
    @State private var dopoCambio = false
    @State private var preparato = false

    private typealias L = Tema.Apple.Luce
    private typealias M = Tema.Apple.Moto.Luce

    private var fermo: Bool { calmo || istantanea || statoFinale }
    private var fasce: [FasciaLuce] { esito.fasce(vista) }
    private var colori: [Color] { ColoriLuce.colori(fasce) }
    private var bordi: [Double] { GeometriaLuce.bordi(fasce.map(\.quota)) }
    private var scelta: Int? { fissata ?? sotto }
    private var annoMostrato: Int? { anno ?? esito.annoOggi }
    private var oggi: Bool { anno == nil || anno == esito.annoOggi }

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .topLeading) {
                L.fondoPalco
                scena(g.size)
                if esito.vuota {
                    vuoto(g.size)
                } else {
                    StratoEtichetteLuce(tela: tela, rotazione: tela.rotazione, misura: g.size, fasce: fasce, colori: colori, bordi: bordi,
                                        valori: fasce.map { esito.valore($0, anno: annoMostrato) },
                                        frazione: esito.frazione(anno: annoMostrato), vista: vista, scelta: scelta,
                                        accese: etichetteAccese, dopoCambio: dopoCambio, fermo: fermo,
                                        sotto: $sotto, fissata: $fissata)
                    testata
                        .padding(.leading, L.margineLato)
                        .padding(.top, L.margineAlto)
                    segmentato
                        .padding(.top, L.margineSegmentato)
                        .padding(.trailing, L.margineSegmentatoDestra)
                        .frame(width: g.size.width, alignment: .trailing)
                    dettaglio
                        .frame(width: L.Dettaglio.larghezza, alignment: .leading)
                        .padding(.leading, L.margineLato)
                        .padding(.bottom, L.margineAlto)
                        .frame(width: g.size.width, height: g.size.height, alignment: .bottomLeading)
                    cursore
                        .frame(width: L.Cursore.larghezza)
                        .padding(.trailing, L.margineLato)
                        .padding(.bottom, L.margineAlto)
                        .frame(width: g.size.width, height: g.size.height, alignment: .bottomTrailing)
                }
            }
            .frame(width: g.size.width, height: g.size.height)
            .clipped()
        }
        .onAppear(perform: prepara)
        .onChange(of: vista) { _ in cambiaVista() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Il prisma di luce di \(cliente.nome)"))
    }

    /// Lo stato iniziale: quello di prova delle istantanee, poi le etichette (subito se fermo, dopo il ventaglio se no).
    private func prepara() {
        guard !preparato else { return }
        preparato = true
        if let p = prova {
            vista = p.vista
            if p.fraVentAnni { anno = esito.annoFine }
            if let nome = p.scelta { fissata = esito.fasce(p.vista).firstIndex { $0.nome == nome } }
        }
        if fermo {
            etichetteAccese = true
        } else {
            DispatchQueue.main.async { etichetteAccese = true }
        }
    }

    private func cambiaVista() {
        sotto = nil
        fissata = nil
        dopoCambio = true
    }

    // MARK: La scena

    @ViewBuilder private func scena(_ misura: CGSize) -> some View {
        let geo = GeometriaLuce(misura: misura)
        let fermoImmagine = PrismaDiLuceFermo(
            fasce: zip(colori, fasce.indices).map { c, i in
                FasciaLuceFermo(colore: c, peso: scelta == nil ? 1 : (i == scelta ? Double(M.evidenzaScelto) : Double(M.evidenzaAltri)))
            },
            bordi: bordi, rotazione: 0, frazione: esito.frazione(anno: annoMostrato), spento: esito.vuota)
        #if os(macOS)
        if istantanea || !RendererLuce.disponibile || tela.rinunciato {
            fermoImmagine
        } else {
            TelaLuceMetal(tela: tela, scena: scenaMetal(geo), animato: !(calmo || statoFinale || !visibilita.visibile))
        }
        #else
        fermoImmagine
        #endif
    }

    private func scenaMetal(_ geo: GeometriaLuce) -> ScenaLuce {
        var b = bordi.map { Float($0) }
        while b.count < 7 { b.append(1) }
        var c = colori.map(ColoriLuce.srgb)
        while c.count < 6 { c.append(.zero) }
        return ScenaLuce(misura: geo.misura, bordi: Array(b.prefix(7)), colori: Array(c.prefix(6)), n: fasce.count,
                         scelta: scelta, lunghezza: Float(geo.lunghezza(rot: 0, frazione: esito.frazione(anno: annoMostrato))),
                         spento: esito.vuota, fermo: calmo || statoFinale)
    }

    // MARK: In alto

    private var testata: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Il patrimonio finanziario di \(cliente.nome)")
                .carattereApple(L.occhiello)
                .foregroundColor(L.testo3)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: L.spazioTotaleAnno) {
                NumeroCheConta(esito.totale(anno: annoMostrato), da: 0, durata: M.totaleDurata)
                    .carattereApple(L.totale)
                    .foregroundColor(L.testo)
                    .lineLimit(1)
                Text(oggi ? "oggi" : "nel \(String(annoMostrato ?? 0))")
                    .carattereApple(L.anno)
                    .foregroundColor(L.testo2)
            }
        }
        .allowsHitTesting(false)
    }

    private var segmentato: some View {
        SegmentatoNotte(selezione: $vista, voci: VistaLuce.allCases.map { v in
            let spenta = v == .obiettivo && esito.obiettivo.isEmpty
            return (v, v.titolo, spenta, spenta ? "Nessun obiettivo nel dossier" : nil)
        })
    }

    // MARK: In basso

    @ViewBuilder private var dettaglio: some View {
        let d = L.Dettaglio.self
        VStack(alignment: .leading, spacing: 0) {
            if let i = scelta, i < fasce.count {
                let f = fasce[i]
                HStack(spacing: d.spazioPallino) {
                    PallinoLuce(colore: colori[i], lato: d.pallino, alone: d.alonePallino)
                    Text(f.nome)
                        .carattereApple(d.nome)
                        .foregroundColor(L.testo)
                        .lineLimit(1)
                }
                NumeroCheConta(esito.valore(f, anno: annoMostrato), da: nil)
                    .carattereApple(d.cifra)
                    .foregroundColor(L.testo)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, d.sopraCifra)
                Text("\(percento(f.quota)) del patrimonio \(oggi ? "oggi" : "nel \(String(annoMostrato ?? 0))")")
                    .carattereApple(d.quota)
                    .foregroundColor(d.coloreQuota)
            } else {
                Text("Passa sui raggi")
                    .carattereApple(d.invito)
                    .foregroundColor(d.coloreInvito)
                Text("Ogni raggio è una parte del patrimonio: lo spessore è il suo peso. Trascina il cristallo per ruotarlo.")
                    .carattereApple(d.spiegazione)
                    .foregroundColor(d.coloreSpiegazione)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, d.sottoInvito)
            }
            ForEach(note, id: \.self) { n in
                Text(n)
                    .carattereApple(d.nota)
                    .foregroundColor(d.coloreInvito)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, d.sopraNota)
            }
        }
        .padding(d.padding)
        .frame(width: d.larghezza, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: d.raggio, style: .continuous)
                .fill(d.fondo)
                .overlay(RoundedRectangle(cornerRadius: d.raggio, style: .continuous).strokeBorder(d.bordo, lineWidth: d.spessoreBordo))
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    /// Le note del pannello: composizione stimata, ripartizione di oggi negli anni, obiettivi oltre il patrimonio.
    private var note: [String] {
        var n: [String] = []
        if esito.stimata && vista != .obiettivo { n.append("Composizione in parte stimata dalla tipologia dei prodotti.") }
        if vista == .obiettivo && esito.obiettiviOltreTotale {
            n.append("Le stesse posizioni contano per più obiettivi: le quote sono sul totale degli obiettivi.")
        }
        if !oggi { n.append("Nel \(String(annoMostrato ?? 0)) con la ripartizione di oggi: il patrimonio dalla linea della vita, in euro di oggi.") }
        return n
    }

    @ViewBuilder private var cursore: some View {
        let c = L.Cursore.self
        if let primo = esito.annoOggi, let ultimo = esito.annoFine, ultimo > primo {
            VStack(spacing: c.sopraBinario) {
                HStack {
                    Text("Oggi")
                    Spacer()
                    Text(ultimo - primo >= MotoreLuce.anniCursore ? "Fra vent’anni" : "A 90 anni")
                }
                .carattereApple(c.capi)
                .foregroundColor(c.coloreCapi)
                CursoreApple(valore: Binding(get: { Double(annoMostrato ?? primo) },
                                             set: { anno = Int($0.rounded()) }),
                             intervallo: Double(primo)...Double(ultimo), passo: 1, etichetta: "Anno del patrimonio")
            }
        } else {
            VStack(alignment: .trailing, spacing: c.sopraBinario) {
                Text(esito.motivoSenzaAnni ?? "Il patrimonio negli anni non si può calcolare.")
                    .carattereApple(c.manca)
                    .foregroundColor(L.testo2)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                if esito.motivoSenzaAnni != nil {
                    Button("Completa l’anagrafica ›", action: completaAnagrafica)
                        .buttonStyle(StileSemplice())
                        .carattereApple(c.manca)
                        .foregroundColor(c.colorePulsante)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: Vuoto

    private func vuoto(_ misura: CGSize) -> some View {
        let v = L.Vuoto.self
        let geo = GeometriaLuce(misura: misura)
        let nome = StatoShell.nomeBreve(cliente)
        return VStack(spacing: v.spazio) {
            Text("\(nome) non ha ancora posizioni in essere: il prisma si accende con il suo patrimonio.")
                .carattereApple(v.testo)
                .foregroundColor(L.testo)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Aggiungi una posizione ›", action: aggiungiPosizione)
                .buttonStyle(.apple)
        }
        .frame(maxWidth: v.larghezza)
        .frame(width: misura.width)
        .offset(y: geo.pavimento + v.sottoPavimento)
    }

    private func percento(_ q: Double) -> String { "\(Int((q * 100).rounded()))%" }
}

// MARK: - Le etichette e il puntatore

/// Le etichette in fondo ai raggi, il puntatore e il trascinamento: l'unica parte che osserva la rotazione mostrata.
private struct StratoEtichetteLuce: View {
    let tela: StatoTelaLuce
    @ObservedObject var rotazione: RotazioneLuce
    let misura: CGSize
    let fasce: [FasciaLuce]
    let colori: [Color]
    let bordi: [Double]
    let valori: [Double]
    let frazione: Double
    let vista: VistaLuce
    let scelta: Int?
    let accese: Bool
    let dopoCambio: Bool
    let fermo: Bool
    @Binding var sotto: Int?
    @Binding var fissata: Int?

    @State private var trascinando = false
    @Environment(\.prismaCalmo) private var calmo

    private typealias E = Tema.Apple.Luce.Etichetta
    private typealias M = Tema.Apple.Moto.Luce

    var body: some View {
        let geo = GeometriaLuce(misura: misura)
        let rot = rotazione.valore
        let lunghezza = geo.lunghezza(rot: rot, frazione: frazione)
        let punti = geo.etichette(rot: rot, bordi: bordi, lunghezza: lunghezza)
        ZStack(alignment: .topLeading) {
            superficie(geo, rot: rot, lunghezza: lunghezza)
            if accese {
                ForEach(Array(fasce.enumerated()), id: \.element.id) { i, f in
                    if i < punti.count {
                        EtichettaRaggio(nome: f.nome, colore: colori[i], quota: f.quota, valore: valori[i],
                                        canale: vista == .canale ? f.canale : nil)
                            .fixedSize()
                            .opacity(scelta != nil && scelta != i ? E.attenuata : 1)
                            .animation(fermo ? nil : M.attenuazione, value: scelta)
                            .offset(x: min(punti[i].x, misura.width - E.margineBordo - larghezzaStimata(f)),
                                    y: min(punti[i].y - E.sopraIlPunto, misura.height - E.margineBordo - E.distanzaMinima))
                            .transition(transizione(i))
                            .id("\(vista.rawValue)-\(f.id)")
                    }
                }
            }
        }
        .frame(width: misura.width, height: misura.height, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(fasce.enumerated().map { i, f in
            "\(f.nome), \(Int((f.quota * 100).rounded()))%, \(Formati.euro(valori[i]))"
        }.joined(separator: "; ")))
    }

    /// Le etichette entrano da sinistra a cascata: dopo il ventaglio all'apertura, 0,65 s dopo un cambio di vista.
    private func transizione(_ i: Int) -> AnyTransition {
        guard !fermo else { return calmo ? .opacity.animation(Tema.Moto.dissolvenzaCalma) : .identity }
        let sposta = dopoCambio ? M.cambioSpostamento : M.etichetteSpostamento
        let animazione = dopoCambio
            ? M.etichetteCambio.delay(M.cambioRitardoEtichette + Double(i) * M.cambioPasso)
            : M.etichette.delay(M.etichetteRitardo + Double(i) * M.etichettePasso)
        return .asymmetric(insertion: AnyTransition.modifier(active: EntrataEtichetta(x: sposta, opacita: 0),
                                                             identity: EntrataEtichetta(x: 0, opacita: 1)).animation(animazione),
                           removal: .identity)
    }

    /// Quanto è larga, più o meno, l'etichetta (per non uscire dal palco a destra).
    private func larghezzaStimata(_ f: FasciaLuce) -> CGFloat {
        CGFloat(max(f.nome.count, 14)) * E.nome.dimensione * 0.58 + E.rientro
    }

    /// La superficie che prende il puntatore e il trascinamento (tutta la tela).
    private func superficie(_ geo: GeometriaLuce, rot: Double, lunghezza: CGFloat) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(width: misura.width, height: misura.height)
            .onContinuousHover { fase in
                switch fase {
                case .active(let p):
                    guard !trascinando else { return }
                    let f = geo.fascia(p, rot: rot, bordi: bordi, lunghezza: lunghezza)
                    if f != sotto { sotto = f }
                    #if os(macOS)
                    NSCursor.openHand.set()
                    #endif
                case .ended:
                    if sotto != nil { sotto = nil }
                    #if os(macOS)
                    NSCursor.arrow.set()
                    #endif
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        if !trascinando && hypot(v.translation.width, v.translation.height) > 3 {
                            trascinando = true
                            tela.iniziaTrascinamento()
                            #if os(macOS)
                            NSCursor.closedHand.set()
                            #endif
                        }
                        if trascinando { tela.trascina(v.translation.width) }
                    }
                    .onEnded { v in
                        if trascinando {
                            trascinando = false
                            tela.fineTrascinamento()
                            #if os(macOS)
                            NSCursor.openHand.set()
                            #endif
                        } else {
                            // Un clic: tiene ferma la fascia sotto il puntatore, o la toglie
                            let f = geo.fascia(v.location, rot: rot, bordi: bordi, lunghezza: lunghezza)
                            fissata = (f == nil || f == fissata) ? nil : f
                        }
                    }
            )
    }
}

/// L'entrata di un'etichetta: da x spostata e trasparente.
private struct EntrataEtichetta: ViewModifier {
    let x: CGFloat
    let opacita: Double

    func body(content: Content) -> some View {
        content.offset(x: x).opacity(opacita)
    }
}

/// Un'etichetta in fondo al raggio: pallino con alone e nome, sotto «38% · 77.539 €» e (per canale) l'etichetta.
private struct EtichettaRaggio: View {
    let nome: String
    let colore: Color
    let quota: Double
    let valore: Double
    let canale: Canale?

    private typealias E = Tema.Apple.Luce.Etichetta

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: E.spazioPallino) {
                PallinoLuce(colore: colore, lato: E.pallino, alone: E.alone)
                Text(nome)
                    .carattereApple(E.nome)
                    .foregroundColor(Tema.Apple.Luce.testo)
                    .lineLimit(1)
            }
            Text("\(Int((quota * 100).rounded()))% · \(Formati.euro(valore))")
                .carattereApple(E.valore)
                .foregroundColor(Tema.Apple.Luce.testo.opacity(E.opacitaValore))
                .padding(.leading, E.rientro)
                .padding(.top, E.sopraValore)
            if let canale {
                EtichettaCanaleApple(canale: canale, compatta: true)
                    .padding(.leading, E.rientro)
                    .padding(.top, E.sopraCanale)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Il pallino del colore della fascia con l'alone dello stesso colore (gradiente, niente ombre: escono anche nelle
/// istantanee).
private struct PallinoLuce: View {
    let colore: Color
    let lato: CGFloat
    let alone: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [colore.opacity(0.7), colore.opacity(0)], center: .center,
                                     startRadius: lato / 2, endRadius: lato / 2 + alone))
                .frame(width: lato + alone * 2, height: lato + alone * 2)
            Circle()
                .fill(colore)
                .frame(width: lato, height: lato)
        }
        .frame(width: lato, height: lato)
    }
}

// MARK: - Il segmentato scuro

/// Il segmentato `.segScuro` del template sul fondo notte: fondo bianco 0,10, pillola 0,22 senza ombra. Una voce può
/// essere spenta, con il suo fumetto.
private struct SegmentatoNotte<Valore: Hashable>: View {
    @Binding var selezione: Valore
    let voci: [(Valore, String, Bool, String?)]

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Namespace private var spazio

    private typealias S = Tema.Apple.Luce.Segmentato

    var body: some View {
        HStack(spacing: 0) {
            ForEach(voci.indices, id: \.self) { i in
                let (valore, titolo, spenta, aiuto) = voci[i]
                let scelta = valore == selezione
                Button {
                    guard !spenta, !scelta else { return }
                    selezione = valore
                } label: {
                    Text(titolo)
                        .carattereApple(S.carattere)
                        .foregroundColor(scelta ? S.testoScelto : S.testo)
                        .lineLimit(1)
                        .padding(S.paddingVoce)
                        .background {
                            if scelta {
                                Capsule(style: .continuous)
                                    .fill(S.pillola)
                                    .matchedGeometryEffect(id: "pillola", in: spazio)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(StileSemplice())
                .opacity(spenta ? S.opacitaSpenta : 1)
                .help(aiuto ?? titolo)
                .accessibilityAddTraits(scelta ? .isSelected : [])
            }
        }
        .padding(S.padding)
        .background(Capsule(style: .continuous).fill(S.fondo))
        .animation(istantanea ? nil : (calmo ? Tema.Moto.dissolvenzaCalma : Tema.Apple.Moto.molla(0.5)), value: selezione)
        .fixedSize()
    }
}
