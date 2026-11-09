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
        .onDisappear { stato.lasciaTavolo(.realtaAumentata) }
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

// MARK: - «▣ Mostra sul tavolo» dal palco (decisioni 48, 49, 111)

extension EsperienzaSala {
    /// Il genere a doppio senso dell'esperienza sull'iPad (nil = immagine del palco o pagina).
    var genereTavolo: MostraTavolo.Genere? {
        switch self {
        case .realtaAumentata: return .realtaAumentata
        case .giocoRischio: return .rischio
        case .lanciaAnno: return .lanciaAnno
        case .disegna: return .disegno
        case .capsula: return .capsula
        default: return nil
        }
    }

    /// L'esperienza porta cifre personali del cliente sull'iPad (tutte tranne il gioco del rischio, che è neutro).
    var cifreSulTavolo: Bool { self != .giocoRischio }
}

extension StatoShell {
    /// «▣ Mostra sul tavolo» dal palco: genere vivo per realtà aumentata, rischio, Lancia l'anno e disegno; il foglio
    /// già visto per la lettera; l'immagine ferma del palco per il prisma di luce e la giornata. Prima la conferma delle
    /// cifre (una volta per cliente e per tavolo), tranne per il gioco del rischio.
    @MainActor
    func mostraEsperienzaSulTavolo(_ e: EsperienzaSala, cliente id: String) {
        guard tavolo.collegato, let c = cliente(id) else { return }
        if e.cifreSulTavolo && tavolo.cifreDaConfermare(id) {
            sala.confermaCifreTavolo = e
            return
        }
        sala.confermaCifreTavolo = nil
        let contesto = ContestoTavolo(documento: nil, pagina: 0, clienteId: id)
        switch e {
        case .realtaAumentata:
            tavolo.mandaRealta(contesto)
        case .giocoRischio, .lanciaAnno, .disegna:
            // La vista del gioco manda il suo stato a ogni passo (e subito, al cambio)
            sala.tavoloEsperienza = e
        case .lettera:
            guard let stesura = sala.stesureLettera[id]?[sala.versioneLettera] else { return }
            let avvertenza = ImpostazioniSala.avvertenza(dati.impostazioni.sala.avvertenzaLettera).testo
            let d = PaginaLettera.documento(testo: stesura.testo, avvertenza: avvertenza, cliente: c.nome)
            tavolo.mandaPagina(ContestoTavolo(documento: d, pagina: 0, clienteId: id, dallaSala: false))
        default:
            mandaImmaginePalco(e, cliente: c)
        }
    }

    /// Conferma della riga in testa al palco: le cifre del cliente vanno sull'iPad, poi l'esperienza.
    @MainActor
    func confermaCifreSulTavolo(_ e: EsperienzaSala, cliente id: String) {
        tavolo.confermaCifre(id)
        sala.confermaCifreTavolo = nil
        mostraEsperienzaSulTavolo(e, cliente: id)
    }

    /// L'immagine ferma del palco (decisione 111): il palco disegnato nello stato finale, come una pagina.
    @MainActor
    private func mandaImmaginePalco(_ e: EsperienzaSala, cliente c: Cliente) {
        let misura = Tema.Apple.RealtaAumentata.ImmaginePalco.misura
        let vista = ContenutoPalco(esperienza: e, cliente: c, inSala: true)
            .environment(self)
            .environment(\.modoIstantanea, true)
            .environment(\.colorScheme, .dark)
            .frame(width: misura.width, height: misura.height)
            .background(Tema.Apple.RealtaAumentata.ImmaginePalco.fondo)
        let r = ImageRenderer(content: vista)
        r.proposedSize = ProposedViewSize(misura)
        r.scale = Tema.Apple.RealtaAumentata.ImmaginePalco.scala
        guard let immagine = r.cgImage, let png = ProtocolloTavolo.png(immagine) else {
            mostraAvviso("Non riesco a preparare l'immagine del palco per l'iPad.")
            return
        }
        tavolo.mandaImmagine(ContestoTavolo(documento: nil, pagina: 0, clienteId: c.id), titolo: e.titolo, png: png, misura: misura)
    }

    /// Il gioco del rischio al tavolo: lo scenario o il risultato, se il tavolo è per il gioco.
    func rischioAlTavolo(_ g: RischioTavolo, cliente id: String) {
        guard sala.tavoloEsperienza == .giocoRischio else { return }
        tavolo.mandaRischio(ContestoTavolo(documento: nil, pagina: 0, clienteId: id), stato: g)
    }

    /// Lancia l'anno al tavolo dopo ogni lancio.
    func lanciaAlTavolo(_ p: PartitaLanciaAnno, cliente id: String) {
        guard sala.tavoloEsperienza == .lanciaAnno else { return }
        let avvertenza = ImpostazioniSala.avvertenza(dati.impostazioni.sala.avvertenzaLancia).testo
        tavolo.mandaLancia(ContestoTavolo(documento: nil, pagina: 0, clienteId: id), partita: p, avvertenza: avvertenza)
    }

    /// Il disegno al tavolo: la tela vuota o il risultato disegnato dal Mac.
    func disegnoAlTavolo(cliente id: String, assi: AssiDisegno, ingresso: IngressoLineaVita, risultato: PaginaTavolo?, frase: String?) {
        guard sala.tavoloEsperienza == .disegna else { return }
        tavolo.mandaDisegno(ContestoTavolo(documento: nil, pagina: 0, clienteId: id), assi: assi, ingresso: ingresso,
                            risultato: risultato, frase: frase)
    }

    /// Il palco dell'esperienza si chiude: l'iPad torna neutro se mostrava quella esperienza.
    func lasciaTavolo(_ e: EsperienzaSala) {
        if sala.tavoloEsperienza == e { sala.tavoloEsperienza = nil }
        if sala.confermaCifreTavolo == e { sala.confermaCifreTavolo = nil }
        if let g = e.genereTavolo, tavolo.mostraAttivo?.genere == g { tavolo.schermataNeutra() }
    }
}

/// «▣ Mostra sul tavolo» nella testata del palco: osserva il tavolo (si accende quando l'iPad si collega). A tavolo
/// chiuso o senza iPad apre il pannello del tavolo con l'avviso.
struct PulsanteMostraSulTavolo: View {
    @Environment(StatoShell.self) var stato
    @ObservedObject var tavolo: TavoloMac
    let esperienza: EsperienzaSala
    let cliente: Cliente
    @State private var pannello = false

    var body: some View {
        let senzaLettera = esperienza == .lettera && stato.sala.stesureLettera[cliente.id]?[stato.sala.versioneLettera] == nil
        Button {
            if tavolo.collegato { stato.mostraEsperienzaSulTavolo(esperienza, cliente: cliente.id) } else { pannello = true }
        } label: { Text("▣ Mostra sul tavolo") }
            .buttonStyle(.apple)
            .disabled(!esperienza.disponibile || !esperienza.tavoloPronto || senzaLettera)
            .help(aiuto(senzaLettera: senzaLettera))
            .popover(isPresented: $pannello, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: Tema.Apple.Tavolo.spazioPannello) {
                    Text(TestiRealta.attesaTavolo)
                        .carattereApple(Tema.Apple.Carattere.secondario)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    PannelloAlTavolo(tavolo: tavolo, contesto: ContestoTavolo(documento: nil, pagina: 0, clienteId: cliente.id))
                }
                .environment(stato)
            }
    }

    private func aiuto(senzaLettera: Bool) -> String {
        if senzaLettera { return TestiRealta.scriviPrimaLettera }
        if !tavolo.collegato { return TestiRealta.attesaTavolo }
        return esperienza.genereTavolo == nil
            ? "Sull'iPad del tavolo: l'immagine di questo palco"
            : "Sull'iPad del tavolo: il cliente guarda e risponde da lì"
    }
}

/// La riga di conferma delle cifre in testa al palco (decisione 49): «Sull'iPad compaiono le cifre di Giulia. Vanno
/// bene per chi è al tavolo?» Mostra / Annulla. Una riga nel palco (le istantanee la disegnano), non un dialogo.
struct ConfermaCifreTavolo: View {
    @Environment(StatoShell.self) var stato
    let esperienza: EsperienzaSala
    let cliente: Cliente

    private typealias K = Tema.Apple.RealtaAumentata.Conferma

    var body: some View {
        if stato.sala.confermaCifreTavolo == esperienza {
            HStack(spacing: K.spazio) {
                Text(TestiRealta.confermaCifre(TestiRealta.primoNome(cliente.nome)))
                    .carattereApple(K.testo)
                    .foregroundColor(K.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: K.spazio)
                Button("Annulla") { stato.sala.confermaCifreTavolo = nil }
                    .buttonStyle(.apple)
                Button("Mostra") { stato.confermaCifreSulTavolo(esperienza, cliente: cliente.id) }
                    .buttonStyle(.applePrimario)
            }
            .padding(K.padding)
            .frame(maxWidth: K.larghezza)
            .background(RoundedRectangle(cornerRadius: K.raggio, style: .continuous).fill(K.fondo))
            .overlay(RoundedRectangle(cornerRadius: K.raggio, style: .continuous).strokeBorder(K.bordo, lineWidth: 1))
            .environment(\.colorScheme, .light)
            .transition(.opacity)
        }
    }
}
#endif
