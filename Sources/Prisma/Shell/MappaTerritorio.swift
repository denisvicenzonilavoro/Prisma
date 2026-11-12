import SwiftUI
#if os(macOS)
import AppKit
#endif

// Territorio · la mappa («Luce» giro 11, §5.1.2-§5.1.4): sempre scura, disegnata in `Canvas` dalle tabelle locali dei
// comuni (decisione 20: niente MapKit, niente servizi di mappe, nessuna richiesta di rete). Strati: fondo con i confini e
// i nomi delle zone, luci (aloni con un solo filtro di sfocatura per tutti), anelli «da fare» (al più 12 pulsano), il
// percorso del giro con le tappe e l'auto che fa un solo giro, il fumetto. Le animazioni si fermano da sole; con calmo e
// nelle istantanee tutto è già nello stato finale.

/// Quello che la mappa disegna, già calcolato dallo stato.
struct ContenutoMappa {
    let luci: [LuceCliente]
    let vista: VistaTerritorio
    /// La crescita: si vedono le luci nate fino a quest'anno; quelle nate proprio quest'anno fanno l'onda.
    let annoCrescita: Int?
    let giro: GiroGiorno?
    let confini: [String: ConfiniProvincia]
    /// Gli id dei clienti con il nome scritto accanto alla luce (preferiti e cliente attivo, al più 8).
    let conNome: Set<String>
    /// Margine a sinistra coperto dal pannello (0 se il pannello sta sotto la mappa).
    let coperto: CGFloat
}

/// Una luce già messa sulla mappa.
private struct LucePosata {
    let luce: LuceCliente
    let punto: CGPoint
    let raggio: CGFloat
    let alfa: Double
    let indice: Int
}

/// L'inquadratura della mappa: i confini della proiezione e il margine (diverso nel giro), senza zoom e spostamento.
private struct QuadroMappa: Equatable {
    let proiezione: ProiezioneMappa
    let margine: CGFloat
    let giro: Bool
}

struct MappaTerritorio: View {
    let contenuto: ContenutoMappa

    @Environment(StatoShell.self) private var stato
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var inizioEntrata = Date()
    @State private var entrataFinita = false
    @State private var inizioNascita = Date()
    @State private var nascitaFinita = true
    @State private var zoomBase: CGFloat?
    @State private var spostamentoBase: CGSize?
    /// Il passaggio animato fra le inquadrature: da dove parte (nil = nessun passaggio), l'ultima chiesta, quando è cominciato.
    @State private var quadroDa: QuadroMappa?
    @State private var quadroMostrato: QuadroMappa?
    @State private var inizioCambio = Date()

    private typealias T = Tema.Apple.Territorio
    private typealias L = Tema.Apple.Territorio.Luce
    private typealias M = Tema.Apple.Territorio.Mappa

    var body: some View {
        let _ = ContaCorpi.segna()
        let meta = quadroMeta()
        let inPassaggio = quadroDa != nil && !fermo
        // Il passaggio fra le inquadrature (0,6 s): un fotogramma per volta solo finché dura, poi la linea del tempo è
        // ferma. Sempre la stessa vista (niente `if`): gli strati non rinascono, e il percorso del giro non riparte.
        TimelineView(.animation(minimumInterval: 1 / 60, paused: !inPassaggio)) { ctx in
            strati(quadro(meta, adesso: inPassaggio ? ctx.date : nil))
        }
        .background(M.terra)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(etichettaAccessibile))
        .task(id: entrataFinita) { await chiudiEntrata() }
        .task(id: inizioNascita) { await chiudiNascita() }
        .task(id: inizioCambio) { await chiudiCambio() }
        .onAppear { if !fermo { quadroMostrato = meta } }
        .onChange(of: meta) { nuovo in cambiaQuadro(nuovo) }
        .onChange(of: contenuto.annoCrescita) { _ in
            guard !fermo else { return }
            inizioNascita = Date()
            nascitaFinita = false
        }
    }

    /// Tutti gli strati della mappa con una proiezione (e il suo margine) già decisa.
    private func strati(_ q: (proiezione: ProiezioneMappa?, margine: CGFloat)) -> some View {
        GeometryReader { g in
            let misura = g.size
            let proiezione = q.proiezione
            let margine = q.margine
            let posate = posa(proiezione, margine, misura)
            ZStack(alignment: .topLeading) {
                BaseMappa(contenuto: contenuto, proiezione: proiezione, margine: margine, misura: misura,
                          posate: posate.map(\.luce))
                luci(posate, misura)
                anelli(posate)
                if contenuto.vista == .giro, let giro = contenuto.giro, let p = proiezione {
                    StratoGiro(giro: giro, punti: giro.tappe.map { punto($0.coordinata, p, margine, misura) },
                               suggerimento: giro.suggerimenti.first.map { punto($0.coordinata, p, margine, misura) })
                        .id(giro.tappe.map(\.id).joined(separator: "|"))
                }
                if let id = stato.territorio.lucePuntata, let l = posate.first(where: { $0.luce.id == id }) {
                    FumettoLuce(luce: l.luce)
                        .frame(width: T.Fumetto.larghezzaMassima, height: 0, alignment: .bottom)
                        .position(x: min(max(l.punto.x, contenuto.coperto + T.Fumetto.larghezzaMassima / 2),
                                         misura.width - T.Fumetto.larghezzaMassima / 2),
                                  y: l.punto.y - l.raggio - T.Fumetto.distanza)
                        .allowsHitTesting(false)
                }
                if stato.territorio.spostando { bandaSposta(misura) }
            }
            .frame(width: misura.width, height: misura.height)
            .contentShape(Rectangle())
            .onContinuousHover(coordinateSpace: .local) { fase in
                switch fase {
                case .active(let p):
                    let id = luceSotto(p, posate)?.luce.id
                    if stato.territorio.lucePuntata != id { stato.territorio.lucePuntata = id }
                case .ended:
                    if stato.territorio.lucePuntata != nil { stato.territorio.lucePuntata = nil }
                }
            }
            .gesture(gestoTocco(posate, proiezione, margine, misura))
            .simultaneousGesture(gestoZoom)
            .simultaneousGesture(gestoSpostamento)
        }
    }

    private var etichettaAccessibile: String {
        let n = contenuto.luci.count
        return n == 1 ? "1 cliente sulla mappa" : "\(n) clienti sulla mappa"
    }

    // MARK: Proiezione

    /// L'inquadratura che la vista chiede, senza zoom e spostamento: nel giro le tappe e i suggerimenti (con i clienti in
    /// tutta Italia le tappe di Bologna sarebbero un punto), in Oggi e Crescita tutte le luci.
    private func quadroMeta() -> QuadroMappa? {
        var punti: [Coordinata]
        if contenuto.vista == .giro, let g = contenuto.giro, !g.tappe.isEmpty {
            punti = g.tappe.map(\.coordinata) + g.suggerimenti.map(\.coordinata)
        } else {
            punti = contenuto.luci.map(\.luogo.coordinata)
        }
        if punti.isEmpty, let g = contenuto.giro, let p = g.partenza { punti = [p] }
        guard let p = ProiezioneMappa.adatta(punti) else { return nil }
        let giro = contenuto.vista == .giro
        return QuadroMappa(proiezione: p, margine: giro ? T.Giro.margineProiezione : M.margine, giro: giro)
    }

    /// La proiezione da disegnare adesso: durante il passaggio, a metà strada fra l'inquadratura di prima e quella nuova
    /// (curva di uscita, 0,6 s); poi quella della vista, con lo zoom e lo spostamento dell'utente.
    private func quadro(_ meta: QuadroMappa?, adesso: Date?) -> (proiezione: ProiezioneMappa?, margine: CGFloat) {
        guard let meta else { return (nil, M.margine) }
        var q = meta
        if let adesso, let da = quadroDa { q = Self.mescola(da, meta, frazioneCambio(adesso)) }
        var p = q.proiezione
        p.zoom = stato.territorio.zoom
        p.spostamento = stato.territorio.spostamento
        return (p, q.margine)
    }

    private func frazioneCambio(_ adesso: Date) -> Double {
        let t = adesso.timeIntervalSince(inizioCambio) / T.Moto.cambioProiezione
        return Self.curva(T.Moto.curvaCambioProiezione, t)
    }

    private static func mescola(_ a: QuadroMappa, _ b: QuadroMappa, _ f: Double) -> QuadroMappa {
        let f = min(1, max(0, f))
        return QuadroMappa(proiezione: ProiezioneMappa.mescola(a.proiezione, b.proiezione, f),
                           margine: a.margine + (b.margine - a.margine) * CGFloat(f), giro: b.giro)
    }

    /// L'inquadratura cambia: fra Oggi/Crescita e il giro si passa con un'animazione (§5.1.3); negli altri casi (dati
    /// nuovi, un altro giorno del giro) e con calmo o nelle istantanee si salta subito.
    private func cambiaQuadro(_ nuovo: QuadroMappa?) {
        let prima = quadroMostrato
        quadroMostrato = nuovo
        guard !fermo, let prima, let nuovo, prima.giro != nuovo.giro else {
            if quadroDa != nil { quadroDa = nil }
            return
        }
        // Se un passaggio è ancora in corso si riparte dal punto in cui è arrivato
        let adesso = Date()
        let partenza = quadroDa.map { Self.mescola($0, prima, frazioneCambio(adesso)) } ?? prima
        quadroDa = partenza
        inizioCambio = adesso
    }

    private func chiudiCambio() async {
        guard quadroDa != nil else { return }
        try? await Task.sleep(nanoseconds: UInt64(T.Moto.cambioProiezione * 1_000_000_000))
        if !Task.isCancelled { quadroDa = nil }
    }

    /// Il punto sulla mappa: la proiezione lavora nell'area non coperta dal pannello.
    private func punto(_ c: Coordinata, _ p: ProiezioneMappa, _ margine: CGFloat, _ misura: CGSize) -> CGPoint {
        let area = CGSize(width: max(1, misura.width - contenuto.coperto), height: misura.height)
        let q = p.punto(c, in: area, margine: margine)
        return CGPoint(x: q.x + contenuto.coperto, y: q.y)
    }

    private func coordinata(_ q: CGPoint, _ p: ProiezioneMappa, _ margine: CGFloat, _ misura: CGSize) -> Coordinata {
        let area = CGSize(width: max(1, misura.width - contenuto.coperto), height: misura.height)
        return p.coordinata(CGPoint(x: q.x - contenuto.coperto, y: q.y), in: area, margine: margine)
    }

    // MARK: Luci

    private func posa(_ proiezione: ProiezioneMappa?, _ margine: CGFloat, _ misura: CGSize) -> [LucePosata] {
        guard let p = proiezione else { return [] }
        let t = stato.territorio
        let nelGiro: Set<String> = contenuto.vista == .giro
            ? Set((contenuto.giro?.tappe ?? []).compactMap(\.cliente?.id) + (contenuto.giro?.suggerimenti ?? []).map(\.cliente.id))
            : []
        var r: [LucePosata] = []
        for (i, l) in contenuto.luci.enumerated() {
            if let anno = contenuto.annoCrescita, contenuto.vista == .crescita, l.annoInizio > anno { continue }
            var alfa = 1.0
            if contenuto.vista == .giro {
                if !nelGiro.contains(l.id) { alfa = T.Giro.opacitaFuori }
            } else if t.soloDaFare {
                if l.daFare == nil { alfa = L.opacitaFuori }
            } else if let z = t.filtroZona, l.luogo.zona != z {
                alfa = L.opacitaFuori
            }
            r.append(LucePosata(luce: l, punto: punto(l.luogo.coordinata, p, margine, misura), raggio: L.raggio(patrimonio: l.patrimonio),
                                alfa: alfa, indice: i))
        }
        return r
    }

    private func luceSotto(_ q: CGPoint, _ posate: [LucePosata]) -> LucePosata? {
        var migliore: (LucePosata, CGFloat)?
        for l in posate {
            let d = hypot(l.punto.x - q.x, l.punto.y - q.y)
            guard d <= max(L.raggioTocco, l.raggio) else { continue }
            if migliore.map({ d < $0.1 }) ?? true { migliore = (l, d) }
        }
        return migliore?.0
    }

    @ViewBuilder private func luci(_ posate: [LucePosata], _ misura: CGSize) -> some View {
        let animata = !fermo && (!entrataFinita || !nascitaFinita)
        if animata {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { ctx in
                Canvas { g, _ in disegnaLuci(&g, posate, adesso: ctx.date) }
            }
        } else {
            Canvas { g, _ in disegnaLuci(&g, posate, adesso: nil) }
        }
    }

    /// Valore di una curva di Bézier cubica (x1, y1, x2, y2) in x, con qualche passo di Newton.
    private static func curva(_ c: Tema.Apple.Moto.Curva, _ x: Double) -> Double {
        guard x > 0 else { return 0 }
        guard x < 1 else { return 1 }
        func b(_ t: Double, _ p1: Double, _ p2: Double) -> Double {
            let u = 1 - t
            return 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t
        }
        func db(_ t: Double, _ p1: Double, _ p2: Double) -> Double {
            let u = 1 - t
            return 3 * u * u * p1 + 6 * u * t * (p2 - p1) + 3 * t * t * (1 - p2)
        }
        var t = x
        for _ in 0..<6 {
            let d = db(t, c.x1, c.x2)
            guard abs(d) > 1e-6 else { break }
            t = min(1, max(0, t - (b(t, c.x1, c.x2) - x) / d))
        }
        return b(t, c.y1, c.y2)
    }

    private func disegnaLuci(_ g: inout GraphicsContext, _ posate: [LucePosata], adesso: Date?) {
        let mo = T.Moto.self
        // Scala per luce: entrata a cascata e nascita della crescita
        func scala(_ l: LucePosata) -> CGFloat {
            guard let adesso else { return 1 }
            var s: CGFloat = 1
            if !entrataFinita {
                let t = adesso.timeIntervalSince(inizioEntrata) - Double(min(l.indice, mo.indiceMassimoLuce)) * mo.passoLuce
                s = CGFloat(Self.curva(mo.curvaLuce, t / mo.durataLuce))
            }
            if !nascitaFinita, contenuto.vista == .crescita, let anno = contenuto.annoCrescita, l.luce.annoInizio == anno {
                let t = adesso.timeIntervalSince(inizioNascita) / mo.nascita
                let picco = mo.frazionePicco
                if t < picco {
                    s *= CGFloat(t / picco) * mo.scalaPicco
                } else if t < 1 {
                    s *= mo.scalaPicco - (mo.scalaPicco - 1) * CGFloat((t - picco) / (1 - picco))
                }
            }
            return max(0, s)
        }
        let scale = posate.map(scala)
        // 1. Aloni: un solo filtro di sfocatura per tutti
        g.drawLayer { strato in
            strato.addFilter(.blur(radius: L.sfocaturaAlone))
            for (k, l) in posate.enumerated() where scale[k] > 0 {
                let r = l.raggio * L.quotaAlone * scale[k]
                strato.fill(Path(ellipseIn: CGRect(x: l.punto.x - r, y: l.punto.y - r, width: 2 * r, height: 2 * r)),
                            with: .color(L.colore(l.luce.canale).opacity(L.opacitaAlone * l.alfa)))
            }
        }
        // 2. Nuclei e centri
        let gradiente = Gradient(stops: L.nucleo)
        for (k, l) in posate.enumerated() where scale[k] > 0 {
            let r = l.raggio * scale[k]
            var c = g
            c.opacity = l.alfa
            c.fill(Path(ellipseIn: CGRect(x: l.punto.x - r, y: l.punto.y - r, width: 2 * r, height: 2 * r)),
                   with: .radialGradient(gradiente, center: l.punto, startRadius: 0, endRadius: r))
            let rc = r * L.quotaCentro
            c.fill(Path(ellipseIn: CGRect(x: l.punto.x - rc, y: l.punto.y - rc, width: 2 * rc, height: 2 * rc)), with: .color(L.centro))
        }
        // 3. Gli anelli «da fare» oltre i 12 che pulsano: fermi, disegnati qui
        let daFare = posate.filter { $0.luce.daFare != nil && contenuto.vista != .giro }
        for l in daFare.dropFirst(mo.pulsantiMassimi) {
            let r = l.raggio + L.distanzaDaFare
            var c = g
            c.opacity = l.alfa
            c.stroke(Path(ellipseIn: CGRect(x: l.punto.x - r, y: l.punto.y - r, width: 2 * r, height: 2 * r)),
                     with: .color(L.daFare), lineWidth: L.spessoreDaFare)
        }
        // 4. Onde della nascita
        if let adesso, !nascitaFinita, contenuto.vista == .crescita, let anno = contenuto.annoCrescita {
            let f = adesso.timeIntervalSince(inizioNascita) / mo.onda
            if f >= 0 && f < 1 {
                let cr = T.Crescita.self
                for l in posate where l.luce.annoInizio == anno {
                    let r = cr.ondaDa + (cr.ondaA - cr.ondaDa) * CGFloat(f)
                    var c = g
                    c.opacity = cr.opacitaOnda * (1 - f)
                    c.stroke(Path(ellipseIn: CGRect(x: l.punto.x - r, y: l.punto.y - r, width: 2 * r, height: 2 * r)),
                             with: .color(cr.onda), lineWidth: cr.spessoreOnda)
                }
            }
        }
        // 5. I nomi accanto alle luci (preferiti e cliente attivo, al più 8, senza sovrapposizioni)
        var occupati: [CGRect] = []
        var scritti = 0
        for (k, l) in posate.enumerated() where contenuto.conNome.contains(l.luce.id) && scale[k] > 0.5 && l.alfa >= 1 {
            guard scritti < L.nomiMassimi else { break }
            let testo = MotoreTerritorio.nomeBattesimo(l.luce.cliente)
            let bianco = g.resolve(Text(testo).font(L.nome.font).foregroundColor(L.coloreNome))
            let misura = bianco.measure(in: CGSize(width: 400, height: 100))
            let origine = CGPoint(x: l.punto.x + l.raggio + L.distanzaNome, y: l.punto.y + L.sottoNome)
            let riquadro = CGRect(x: origine.x, y: origine.y - misura.height / 2, width: misura.width, height: misura.height)
            guard !occupati.contains(where: { $0.intersects(riquadro) }) else { continue }
            occupati.append(riquadro)
            scritti += 1
            let contorno = g.resolve(Text(testo).font(L.nome.font).foregroundColor(L.contornoNome))
            let s = L.spessoreContornoNome / 2
            for (dx, dy) in [(-s, -s), (0, -s), (s, -s), (-s, 0), (s, 0), (-s, s), (0, s), (s, s)] {
                g.draw(contorno, at: CGPoint(x: origine.x + dx, y: origine.y + dy), anchor: .leading)
            }
            g.draw(bianco, at: origine, anchor: .leading)
        }
    }

    // MARK: Anelli «da fare» (al più 12 pulsano)

    @ViewBuilder private func anelli(_ posate: [LucePosata]) -> some View {
        if contenuto.vista != .giro {
            let daFare = Array(posate.filter { $0.luce.daFare != nil }.prefix(T.Moto.pulsantiMassimi))
            ForEach(daFare, id: \.luce.id) { l in
                AnelloPulsanteTerritorio(raggio: l.raggio + L.distanzaDaFare, colore: L.daFare, spessore: L.spessoreDaFare)
                    .opacity(l.alfa)
                    .position(l.punto)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: Interazioni

    private func clic(_ q: CGPoint, _ posate: [LucePosata], _ proiezione: ProiezioneMappa?, _ margine: CGFloat,
                      _ misura: CGSize) {
        if stato.territorio.spostando {
            guard let p = proiezione else { return }
            stato.fissaPosizione(coordinata(q, p, margine, misura))
            return
        }
        guard let l = luceSotto(q, posate) else {
            stato.territorio.lucePuntata = nil
            return
        }
        #if os(macOS)
        if NSEvent.modifierFlags.contains(.option) {
            // ⌥ clic: le Posizioni del cliente
            stato.clienteAttivoId = l.luce.id
            stato.apri(.posizioni)
            return
        }
        #endif
        stato.apriCliente(l.luce.id)
    }

    /// Doppio clic: torna a vedere tutti; clic: dossier (⌥ clic: Posizioni) o, in «Sposta», il punto.
    private func gestoTocco(_ posate: [LucePosata], _ proiezione: ProiezioneMappa?, _ margine: CGFloat,
                            _ misura: CGSize) -> some Gesture {
        let doppio = SpatialTapGesture(count: 2).onEnded { _ in tornaATutti() }
        let singolo = SpatialTapGesture().onEnded { v in clic(v.location, posate, proiezione, margine, misura) }
        return doppio.exclusively(before: singolo)
    }

    /// Pizzico: zoom fra i limiti del tema.
    private var gestoZoom: some Gesture {
        MagnifyGesture()
            .onChanged { v in
                let base = zoomBase ?? stato.territorio.zoom
                if zoomBase == nil { zoomBase = base }
                stato.territorio.zoom = min(M.zoomMassimo, max(M.zoomMinimo, base * v.magnification))
            }
            .onEnded { _ in zoomBase = nil }
    }

    /// Trascinamento: sposta la mappa.
    private var gestoSpostamento: some Gesture {
        DragGesture(minimumDistance: M.distanzaTrascinamento)
            .onChanged { v in
                let base = spostamentoBase ?? stato.territorio.spostamento
                if spostamentoBase == nil { spostamentoBase = base }
                stato.territorio.spostamento = CGSize(width: base.width + v.translation.width,
                                                      height: base.height + v.translation.height)
            }
            .onEnded { _ in spostamentoBase = nil }
    }

    private func tornaATutti() {
        let t = stato.territorio
        t.zoom = 1
        t.spostamento = .zero
        t.filtroZona = nil
        t.soloDaFare = false
    }

    private func bandaSposta(_ misura: CGSize) -> some View {
        let s = T.Sposta.self
        let nome = stato.territorio.spostaClienteId.flatMap { id in stato.dati.clienti.first { $0.id == id } }
            .map(MotoreTerritorio.nomeBattesimo) ?? "il cliente"
        let frase = stato.territorio.spostaPartenza ? "Fai clic sulla mappa da dove parti." : "Fai clic sulla mappa dove sta \(nome)."
        return HStack(spacing: T.Pannello.spazio) {
            Text(frase)
                .carattereApple(s.carattere)
                .foregroundColor(s.testo)
            Button("Annulla") {
                stato.territorio.spostaClienteId = nil
                stato.territorio.spostaPartenza = false
            }
                .buttonStyle(.appleSobrio)
        }
        .padding(s.padding)
        .background(RoundedRectangle(cornerRadius: s.raggio, style: .continuous).fill(s.fondo))
        .position(x: contenuto.coperto + (misura.width - contenuto.coperto) / 2, y: s.margineAlto + T.Pannello.spazioSezione)
    }

    // MARK: Fine delle animazioni (niente Timer: un Task che dorme)

    private func chiudiEntrata() async {
        guard !entrataFinita else { return }
        if fermo {
            entrataFinita = true
            return
        }
        let mo = T.Moto.self
        let durata = mo.durataLuce + Double(mo.indiceMassimoLuce) * mo.passoLuce
        try? await Task.sleep(nanoseconds: UInt64(durata * 1_000_000_000))
        if !Task.isCancelled { entrataFinita = true }
    }

    private func chiudiNascita() async {
        guard !nascitaFinita else { return }
        try? await Task.sleep(nanoseconds: UInt64(T.Moto.onda * 1_000_000_000))
        if !Task.isCancelled { nascitaFinita = true }
    }
}

// MARK: - Fondo della mappa

/// Terra, vignettatura, confini dei comuni e nomi delle zone: un `Canvas` statico.
private struct BaseMappa: View {
    let contenuto: ContenutoMappa
    let proiezione: ProiezioneMappa?
    let margine: CGFloat
    let misura: CGSize
    let posate: [LuceCliente]

    private typealias M = Tema.Apple.Territorio.Mappa

    var body: some View {
        Canvas { g, size in
            let rett = CGRect(origin: .zero, size: size)
            g.fill(Path(rett), with: .color(M.terra))
            let diagonale = hypot(size.width, size.height)
            g.fill(Path(rett), with: .radialGradient(Gradient(colors: [M.vignettaCentro, M.vignettaBordo]),
                                                     center: CGPoint(x: size.width * M.centroVignetta.x, y: size.height * M.centroVignetta.y),
                                                     startRadius: 0, endRadius: diagonale * M.raggioVignetta))
            guard let p = proiezione else { return }
            let area = CGSize(width: max(1, size.width - contenuto.coperto), height: size.height)
            func punto(_ lat: Double, _ lon: Double) -> CGPoint {
                let q = p.punto(Coordinata(lat: lat, lon: lon), in: area, margine: margine)
                return CGPoint(x: q.x + contenuto.coperto, y: q.y)
            }
            // Confini: «strada» per i comuni con clienti, «stradina» per gli altri della provincia
            let conClienti = Set(posate.compactMap { $0.luogo.comune?.codice })
            var forti = Path()
            var deboli = Path()
            for prov in contenuto.confini.values {
                for (codice, anelli) in prov.comuni {
                    for anello in anelli where anello.count >= 6 {
                        var path = Path()
                        var k = 0
                        while k + 1 < anello.count {
                            let q = punto(anello[k], anello[k + 1])
                            if k == 0 { path.move(to: q) } else { path.addLine(to: q) }
                            k += 2
                        }
                        path.closeSubpath()
                        if conClienti.contains(codice) { forti.addPath(path) } else { deboli.addPath(path) }
                    }
                }
            }
            g.stroke(deboli, with: .color(M.confineAltri), lineWidth: M.spessoreConfineAltri)
            g.stroke(forti, with: .color(M.confine), style: StrokeStyle(lineWidth: M.spessoreConfine, lineJoin: .round))
            // Nomi delle zone sul centro delle loro luci, in ordine di patrimonio, solo se c'è posto
            var zone: [String: (patrimonio: Double, x: CGFloat, y: CGFloat, n: Int)] = [:]
            for l in posate {
                let q = punto(l.luogo.coordinata.lat, l.luogo.coordinata.lon)
                let v = zone[l.luogo.zona] ?? (0, 0, 0, 0)
                zone[l.luogo.zona] = (v.patrimonio + l.patrimonio, v.x + q.x, v.y + q.y, v.n + 1)
            }
            var occupati: [CGRect] = []
            let ordinate = zone.sorted { $0.value.patrimonio != $1.value.patrimonio ? $0.value.patrimonio > $1.value.patrimonio : $0.key < $1.key }
            for (nome, v) in ordinate where v.n > 0 {
                let centro = CGPoint(x: v.x / CGFloat(v.n), y: v.y / CGFloat(v.n))
                let testo = g.resolve(Text(nome.uppercased()).font(M.zona.font).tracking(M.zona.tracking).foregroundColor(M.coloreZona))
                let m = testo.measure(in: CGSize(width: 600, height: 100))
                let riquadro = CGRect(x: centro.x - m.width / 2, y: centro.y - m.height / 2, width: m.width, height: m.height)
                    .insetBy(dx: -M.spazioNomiZona, dy: -M.spazioNomiZona)
                guard riquadro.minX >= contenuto.coperto, riquadro.maxX <= size.width,
                      !occupati.contains(where: { $0.intersects(riquadro) }) else { continue }
                occupati.append(riquadro)
                g.draw(testo, at: centro, anchor: .center)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Anello che pulsa

/// Un anello arancio che pulsa (1,8 s, scala 1,35, opacità 0,35) con l'animazione di SwiftUI ripetuta; fermo a scala 1
/// con calmo e nelle istantanee. Con Prisma non in vista (finestra coperta o ridotta, Mac a riposo) la pulsazione si
/// ferma, come le tele animate: nessuno la vede, e riparte quando Prisma torna in vista.
struct AnelloPulsanteTerritorio: View {
    let raggio: CGFloat
    let colore: Color
    let spessore: CGFloat

    @Environment(\.prismaStatoFinale) private var fermo
    @ObservedObject private var visibilita = VisibilitaPrisma.condivisa
    @State private var acceso = false

    private typealias Mo = Tema.Apple.Territorio.Moto

    var body: some View {
        let inVista = visibilita.visibile
        let pulsa = acceso && !fermo && inVista
        Circle()
            .stroke(colore, lineWidth: spessore)
            .frame(width: 2 * raggio, height: 2 * raggio)
            .scaleEffect(pulsa ? Mo.scalaPulsazione : 1)
            .opacity(pulsa ? Mo.opacitaPulsazione : 1)
            // Senza animazione (fermo, o Prisma non in vista) il valore nuovo toglie la pulsazione ripetuta in corso
            .animation(fermo || !inVista ? nil : Mo.animazionePulsazione, value: pulsa)
            .onAppear { if !fermo { acceso = true } }
    }
}

// MARK: - Il giro sulla mappa

/// Il percorso «in linea d'aria» (curve leggere dichiarate), le tappe numerate, un solo «⌂» per partenza e rientro,
/// l'auto che fa un solo giro e l'anello del suggerimento.
private struct StratoGiro: View {
    let giro: GiroGiorno
    let punti: [CGPoint]
    let suggerimento: CGPoint?

    @Environment(\.prismaStatoFinale) private var fermo
    @State private var tracciato: CGFloat = 0
    @State private var tappeDentro = false
    @State private var autoFinita = false

    private typealias G = Tema.Apple.Territorio.Giro
    private typealias Mo = Tema.Apple.Territorio.Moto

    var body: some View {
        let percorso = PercorsoGiro.percorso(punti)
        ZStack(alignment: .topLeading) {
            PercorsoGiro(punti: punti)
                .trim(from: 0, to: fermo ? 1 : tracciato)
                .stroke(G.percorso, style: StrokeStyle(lineWidth: G.spessorePercorso, lineCap: .round, lineJoin: .round))
            ForEach(Array(giro.tappe.enumerated()), id: \.element.id) { i, t in
                if t.genere != .rientro || giro.partenza == nil, i < punti.count {
                    tappa(t, numero: numeroVisita(i))
                        .scaleEffect(fermo || tappeDentro ? 1 : 0)
                        .animation(fermo ? nil : Tema.Apple.Moto.Curva.molla.animazione(Mo.tappa)
                                    .ritardoPrisma(Mo.ritardoTappa + Double(i) * Mo.passoTappa), value: tappeDentro)
                        .position(punti[i])
                }
            }
            if let s = suggerimento {
                AnelloPulsanteTerritorio(raggio: G.raggioSuggerimento, colore: Tema.Apple.Territorio.Luce.daFare, spessore: G.spessoreSuggerimento)
                    .position(s)
            }
            if punti.count >= 2 {
                if fermo || autoFinita {
                    Canvas { g, _ in disegnaAuto(&g, percorso, frazione: 1) }
                } else {
                    TelaAnimata(tempoFinale: Mo.partenzaAuto + Mo.giroAuto) { g, _, t in
                        disegnaAuto(&g, percorso, frazione: CGFloat(min(1, max(0, (t - Mo.partenzaAuto) / Mo.giroAuto))))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !fermo else { return }
            withAnimation(Mo.curvaTracciato.animazione(Mo.tracciato)) { tracciato = 1 }
            tappeDentro = true
        }
        .task {
            guard !fermo else { return }
            try? await Task.sleep(nanoseconds: UInt64((Mo.partenzaAuto + Mo.giroAuto) * 1_000_000_000))
            if !Task.isCancelled { autoFinita = true }
        }
    }

    /// Il numero della visita (1, 2, …): la partenza e il rientro non sono contati.
    private func numeroVisita(_ i: Int) -> Int {
        giro.tappe.prefix(i + 1).filter { $0.genere == .visita }.count
    }

    @ViewBuilder private func tappa(_ t: TappaGiro, numero: Int) -> some View {
        ZStack {
            Circle().fill(G.percorso)
            Circle().stroke(G.coloreBordoTappa, lineWidth: G.bordoTappa)
            if t.genere == .visita {
                Text("\(numero)").carattereApple(G.numeroTappa).foregroundColor(G.coloreNumero)
            } else {
                Text(G.casa).carattereApple(G.casaCarattere).foregroundColor(G.coloreNumero)
            }
        }
        .frame(width: 2 * G.raggioTappa, height: 2 * G.raggioTappa)
    }

    private func disegnaAuto(_ g: inout GraphicsContext, _ percorso: Path, frazione: CGFloat) {
        let f = max(0.0001, min(1, frazione))
        guard let q = percorso.trimmedPath(from: 0, to: f).currentPoint else { return }
        let r = G.raggioAuto
        let cerchio = Path(ellipseIn: CGRect(x: q.x - r, y: q.y - r, width: 2 * r, height: 2 * r))
        g.fill(cerchio, with: .color(G.fondoAuto))
        g.stroke(cerchio, with: .color(G.percorso), lineWidth: G.bordoAuto)
    }
}

/// Il percorso del giro: tratti leggermente curvi (punto di controllo a metà, spostato in perpendicolare di
/// `Giro.curvatura × lunghezza`, segno alterno), dichiarati «in linea d'aria» nel pannello.
struct PercorsoGiro: Shape {
    let punti: [CGPoint]

    func path(in rect: CGRect) -> Path { Self.percorso(punti) }

    static func percorso(_ punti: [CGPoint]) -> Path {
        var p = Path()
        guard let primo = punti.first else { return p }
        p.move(to: primo)
        for k in 1..<max(1, punti.count) {
            let a = punti[k - 1], b = punti[k]
            let dx = b.x - a.x, dy = b.y - a.y
            let lunghezza = hypot(dx, dy)
            guard lunghezza > 0 else { continue }
            let segno: CGFloat = k % 2 == 0 ? 1 : -1
            let spinta = Tema.Apple.Territorio.Giro.curvatura * lunghezza * segno
            let controllo = CGPoint(x: (a.x + b.x) / 2 - dy / lunghezza * spinta, y: (a.y + b.y) / 2 + dx / lunghezza * spinta)
            p.addQuadCurve(to: b, control: controllo)
        }
        return p
    }
}

// MARK: - Il fumetto di una luce

private struct FumettoLuce: View {
    let luce: LuceCliente

    private typealias F = Tema.Apple.Territorio.Fumetto

    var body: some View {
        VStack(alignment: .leading, spacing: F.spazio) {
            Text(luce.cliente.nome)
                .carattereApple(F.titolo)
                .foregroundColor(F.coloreTitolo)
            HStack(spacing: F.spazio) {
                switch luce.canale {
                case .alleanza: EtichettaCanale(canale: .alleanza, compatta: true)
                case .indipendente: EtichettaCanale(canale: .indipendente, compatta: true)
                case .entrambi:
                    EtichettaCanale(canale: .alleanza, compatta: true)
                    EtichettaCanale(canale: .indipendente, compatta: true)
                }
            }
            Text("\(Formati.euro(luce.patrimonio)) seguiti")
                .carattereApple(F.riga)
                .foregroundColor(F.coloreRiga)
            if let d = luce.daFare {
                Text(d.perche)
                    .carattereApple(F.riga)
                    .foregroundColor(Tema.Apple.Territorio.Pannello.testoDaFare)
            }
            Text(provenienza)
                .carattereApple(F.riga)
                .foregroundColor(F.coloreRiga)
        }
        .padding(F.padding)
        .frame(maxWidth: F.larghezzaMassima, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .superficieApple(F.superficie, raggio: F.raggio)
    }

    private var provenienza: String {
        switch luce.luogo.precisione {
        case .manuale:
            let prova = luce.cliente.luogo?.nota == TerritorioDiProva.nota ? " · dati di prova" : ""
            return "posizione a mano" + prova
        case .comune:
            return "posizione del comune di \(luce.luogo.comune?.nome ?? luce.luogo.zona)"
        }
    }
}
