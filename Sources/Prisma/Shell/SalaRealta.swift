#if os(macOS)
import SwiftUI
import AppKit
import Combine
#if canImport(RealityKit)
import RealityKit
#endif

// Sala › La realtà aumentata sul Mac (Design/template-luce-specifica.md §2.3.1, «Luce» giro 16): l'anteprima simulata.
//
//   ┌──────────── iPad ────────────┐   SUL TAVOLO, DAVANTI A GIULIA
//   │ ◉ Prisma · AR   ✓ Tavolo trov│   Il patrimonio diventa un cristallo…
//   │        [204.050 €]           │   ┌ 204.050 € ┐ Patrimonio nel 2026
//   │           ╱╲  cristallo      │   ■ Azionario          38%
//   │  2026 ──●── Esploso ◯        │   Anteprima simulata…
//   └──────────────────────────────┘
//
// La scena è RealityKit virtuale (un solo codice del cristallo per Mac, iPad e iPhone: `CristalloRealta`), senza
// fotocamera né ARKit: la camera orbita intorno al cristallo sul tavolo di legno. Nelle istantanee, senza Metal o se
// RealityKit non riesce, il fermo-immagine `CristalloFermo`. Il trascinamento gira la camera (220 pt = 1 rad in
// orizzontale, 320 pt in verticale); lo scatto salva il cristallo su fondo neutro nel dossier (decisione 27).

struct PalcoRealtaAumentata: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    /// Sulla sala opaca della presentazione.
    var inSala = false

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo
    @StateObject private var controllo = ControlloScenaRealta()
    @State private var anno: Int?
    @State private var esploso = false
    @State private var lampo = false
    @State private var avviso: String?
    @State private var trovato = false
    @State private var targhetta = false
    @State private var inizioTrascinamento: (azimut: Float, elevazione: Float)?

    private typealias RA = Tema.Apple.RealtaAumentata
    private typealias I = Tema.Apple.RealtaAumentata.CorniceiPad
    private typealias M = Tema.Apple.Moto.RealtaAumentata

    var body: some View {
        let _ = ContaCorpi.segna()
        let id = cliente.id
        let esito = CacheRealta.esito(cliente: stato.cliente(id) ?? cliente, posizioni: stato.posizioniCliente(id),
                                      obiettivi: stato.obiettiviCliente(id), eventi: stato.eventiVitaCliente(id),
                                      analisi: stato.dati.analisi[id])
        let prova = istantanea ? stato.sala.realtaIstantanea : nil
        let annoMostrato = prova.map { $0.allaPensione ? esito.annoFine : ($0.anno ?? esito.annoOggi) } ?? (anno ?? esito.annoOggi)
        let esplosoMostrato = prova?.esploso ?? esploso
        let primo = TestiRealta.primoNome(cliente.nome)
        GeometryReader { geo in
            let colonnaMinima = RA.Colonna.larghezzaMinima
            let spazioiPad = geo.size.width - I.origine.x * 2 - colonnaMinima - RA.Colonna.margineDestro
            let scala = max(0.3, min(1, spazioiPad / I.dimensione.width, (geo.size.height - I.origine.y * 2) / I.dimensione.height))
            let larghezzaiPad = I.dimensione.width * scala
            ZStack(alignment: .topLeading) {
                RadialGradient(colors: [RA.Fondo.centro, RA.Fondo.bordo], center: RA.Fondo.punto, startRadius: 0,
                               endRadius: RA.Fondo.raggio)
                HStack(alignment: .top, spacing: I.origine.x) {
                    CorniceiPad { schermo(esito, primo: primo, anno: annoMostrato, esploso: esplosoMostrato, prova: prova) }
                        .scaleEffect(scala, anchor: .topLeading)
                        .frame(width: larghezzaiPad, height: I.dimensione.height * scala, alignment: .topLeading)
                    ColonnaRealta(esito: esito, primo: primo, anno: annoMostrato)
                        .padding(.top, RA.Colonna.alto)
                        .padding(.trailing, RA.Colonna.margineDestro)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(.leading, I.origine.x)
                .padding(.top, I.origine.y)
                ConfermaCifreTavolo(esperienza: .realtaAumentata, cliente: cliente)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.top, I.origine.y)
            }
        }
        .environment(\.colorScheme, .light)
        .onAppear {
            anno = esito.annoOggi
            if istantanea { trovato = true; targhetta = true; return }
            Task { @MainActor in
                let attesa = calmo ? 0 : M.puntiniInizio
                try? await Task.sleep(nanoseconds: UInt64(attesa * 1_000_000_000))
                withAnimation(Tema.Apple.Moto.animazione(.easeOut(duration: M.guidaUscita), calmo: calmo)) { trovato = true }
                let ritardo = calmo ? 0 : max(0, M.targhettaRitardo - attesa)
                try? await Task.sleep(nanoseconds: UInt64(ritardo * 1_000_000_000))
                withAnimation(Tema.Apple.Moto.animazione(.easeOut(duration: M.targhettaDurata), calmo: calmo)) { targhetta = true }
            }
        }
        .onChange(of: anno) { _, v in controllo.anno = v }
        .onChange(of: esploso) { _, v in controllo.esploso = v }
    }

    /// Lo schermo dell'iPad: la scena (o il fermo-immagine) e le sovrapposizioni comuni.
    @ViewBuilder
    private func schermo(_ esito: EsitoRealta, primo: String, anno annoMostrato: Int?, esploso esplosoMostrato: Bool,
                         prova: ScenaRealtaDiProva?) -> some View {
        let fermo = istantanea || controllo.guasto || !ShaderTela.disponibile || esito.vuota
        ZStack {
            if fermo {
                CristalloFermo(esito: esito, anno: annoMostrato, esploso: esplosoMostrato, scelto: prova?.scelto, fondo: .tavoloLegno)
            } else {
                #if canImport(RealityKit)
                ScenaRealtaMac(esito: esito, controllo: controllo, calmo: calmo)
                    .gesture(trascinamento)
                #else
                CristalloFermo(esito: esito, anno: annoMostrato, esploso: esplosoMostrato, fondo: .tavoloLegno)
                #endif
            }
            if !esito.vuota {
                if fermo {
                    EtichetteFermeRealta(esito: esito, nome: primo, anno: annoMostrato, esploso: esplosoMostrato,
                                         scelto: prova?.scelto, targhettaVisibile: targhetta || istantanea)
                } else {
                    EtichetteSopraRealta(etichette: controllo.etichette, esito: esito, nome: primo, anno: annoMostrato,
                                         esploso: esplosoMostrato, scelto: nil, targhettaVisibile: targhetta)
                }
            }
            VStack {
                HStack {
                    PillolaRealta(testo: TestiRealta.marchio)
                    Spacer()
                    PillolaRealta(testo: trovato ? TestiRealta.tavoloTrovato : TestiRealta.cercoSuperficie, verde: trovato)
                }
                .padding(RA.Pillola.margine)
                Spacer()
                if let avviso {
                    AvvisoRealta(testo: avviso).transition(.opacity)
                }
                if esito.vuota {
                    AvvisoRealta(testo: TestiRealta.senzaPosizioni(primo))
                } else {
                    if esito.anni.isEmpty, let motivo = esito.motivoSenzaAnni {
                        AvvisoRealta(testo: motivo)
                    }
                    BarraRealta(anni: esito.anni, anno: $anno, esploso: $esploso, scattoAcceso: !inSala,
                                aiutoScatto: nil) { scatta(esito, anno: annoMostrato) }
                        .disabled(prova != nil)
                }
            }
            .padding(.bottom, RA.Barra.distanzaFondo)
            if !trovato && !istantanea && !esito.vuota {
                GuidaRealta(testo: TestiRealta.guida).transition(.opacity)
            }
            LampoRealta(attivo: lampo)
        }
    }

    private var trascinamento: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { g in
                let inizio = inizioTrascinamento ?? (azimut: controllo.azimutTrascinato, elevazione: controllo.elevazione)
                if inizioTrascinamento == nil { inizioTrascinamento = inizio }
                let k = RA.Camera.self
                controllo.azimutTrascinato = inizio.azimut + Float(g.translation.width / k.puntiPerRadianteOrizzontale)
                controllo.elevazione = min(k.elevazioneMassima, max(k.elevazioneMinima,
                                                                   inizio.elevazione + Float(g.translation.height / k.puntiPerRadianteVerticale)))
                controllo.ultimoGesto = controllo.tempo
            }
            .onEnded { _ in inizioTrascinamento = nil }
    }

    /// Lo scatto: il cristallo su fondo neutro nel dossier del cliente (decisione 27), il lampo e l'avviso.
    private func scatta(_ esito: EsitoRealta, anno: Int?) {
        guard let immagine = CristalloFermo.scatto(esito, anno: anno, esploso: esploso) else {
            avviso = TestiRealta.scattoGuasto
            return
        }
        let annoScatto = anno ?? esito.annoOggi ?? Calendar.current.component(.year, from: Date())
        guard stato.archiviaScattoRealta(immagine, cliente: cliente.id, anno: annoScatto, esploso: esploso, conStanza: false,
                                         origine: .mac) != nil else { return }
        lampo = true
        avviso = TestiRealta.fotoSalvata(cliente.nome)
        DispatchQueue.main.async {
            withAnimation(Tema.Apple.Moto.animazione(.easeOut(duration: Tema.Apple.Moto.RealtaAumentata.lampo), calmo: calmo)) {
                lampo = false
            }
        }
    }
}

#if canImport(RealityKit)
/// La scena RealityKit del Mac: sempre virtuale (nessuna fotocamera, nessun ARKit).
struct ScenaRealtaMac: NSViewRepresentable {
    let esito: EsitoRealta
    let controllo: ControlloScenaRealta
    let calmo: Bool

    func makeCoordinator() -> CoordinatoreScenaRealta { CoordinatoreScenaRealta() }

    func makeNSView(context: Context) -> ARView {
        let vista = ARView(frame: .zero)
        controllo.calmo = calmo
        context.coordinator.avvia(vista, esito: esito, controllo: controllo)
        return vista
    }

    func updateNSView(_ vista: ARView, context: Context) {
        controllo.calmo = calmo
        if context.coordinator.esito != esito { context.coordinator.avvia(vista, esito: esito, controllo: controllo) }
    }

    static func dismantleNSView(_ vista: ARView, coordinator: CoordinatoreScenaRealta) {
        coordinator.ferma(vista)
    }
}
#endif

extension StatoShell {
    /// Il foglio dello scatto nei Documenti del cliente (PDF di una pagina su carta bianca) con `Documento.scattoRealta`
    /// (decisione 27). Il titolo porta l'ora: `archiviaPDF` sostituisce un documento con lo stesso titolo dello stesso
    /// giorno, e due scatti dello stesso anno non devono cancellarsi.
    @MainActor @discardableResult
    func archiviaScattoRealta(_ immagine: CGImage, cliente id: String, anno: Int, esploso: Bool, conStanza: Bool,
                              origine: ScattoRealta.Origine) -> String? {
        guard let c = cliente(id) else { return nil }
        let esito = CacheRealta.esito(cliente: c, posizioni: posizioniCliente(id), obiettivi: obiettiviCliente(id),
                                      eventi: eventiVitaCliente(id), analisi: dati.analisi[id])
        let annoEsito = esito.anni.contains { $0.anno == anno } ? anno : nil
        let titolo = TestiRealta.titoloDocumento(anno: anno, ora: Formati.ora.string(from: Date()))
        let foglio = FoglioScattoRealta(cliente: c.nome, anno: anno, immagine: immagine, esito: esito, annoEsito: annoEsito,
                                        conStanza: conStanza)
        let documento = DocumentoStampabile(titolo: titolo, cliente: c.nome, genere: "Report",
                                            formato: Tema.Apple.RealtaAumentata.Foglio.formato, pagine: [AnyView(foglio)], tipo: .report)
        guard let pdf = StampaCarta.pdf(documento) else {
            mostraAvviso("Non sono riuscito a creare il PDF dello scatto.")
            return nil
        }
        return archiviaPDF(pdf, titolo: titolo, tipo: .report, cliente: id,
                           scattoRealta: ScattoRealta(anno: anno, esploso: esploso, conStanza: conStanza, origine: origine))
    }
}
#endif
