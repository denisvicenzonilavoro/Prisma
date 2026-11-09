import SwiftUI
#if os(macOS)
import AppKit
#endif

// Sala › Disegna il tuo futuro (Design/template-luce-specifica.md §3.3, «Luce» giro 4; prima fase solo sul Mac,
// decisione 113: l'iPad del tavolo in seconda fase).
//
//   ┌──────────── tela 900×520 ─────────────┐  Disegna come vorresti che
//   │1,4 milioni ┊      ┊      ┊      ┊     │  crescesse il tuo patrimonio.
//   │            ┊   ╭╌╌╌╌╌╌╮ fantasma      │  Con il dito sull'iPad, o con il mouse…
//   │  ●━━━━━━━━━━━━━━━●━━━━━━━ piano        │  ┌ Il tuo disegno, a 67 anni ┐
//   │0 €  40 anni   50 anni   …   90 anni   │  └ Il piano di oggi, a 67 anni ┘
//   └────────────────────────────────────────┘  Per arrivare al tuo disegno servono…
//                                               ↻ Ricomincia   Salva come obiettivo
//
// Stati: vuota → disegno → trasformazione (la curva verde passa dal disegno al piano in 1,3 s, `CurvaTrasformata`
// con `Animatable`) → risultato. Un tratto di meno di 4 punti torna vuota; un secondo tratto riparte da capo.
// «Salva come obiettivo» apre il modulo già compilato (area pensione, importo = il disegno alla pensione, scadenza =
// il giorno della pensione, versamento = quanto serve in più al mese): niente si salva in silenzio (decisione 88).
// Le cifre vengono da `MotoreDisegno` sulla linea della vita del cliente. «Riduci movimento»: la curva del piano
// compare subito con la dissolvenza; istantanee: il tratto di prova (`StatoSala.provaDisegno`) già trasformato.

struct DisegnaIlFuturo: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente

    var body: some View {
        let _ = ContaCorpi.segna()
        let id = cliente.id
        let attuale = stato.cliente(id) ?? cliente
        let prep = CacheLineaVita.preparazione(cliente: attuale, posizioni: stato.posizioniCliente(id),
                                               obiettivi: stato.dati.obiettivi.filter { $0.clienteId == id },
                                               eventi: stato.eventiVitaCliente(id), analisi: stato.dati.analisi[id])
        CorpoDisegno(cliente: attuale, preparazione: prep, prova: stato.sala.provaDisegno,
                     obiettivi: stato.obiettiviCliente(id),
                     salva: { stato.salvaObiettivo($0) },
                     completaAnagrafica: { stato.apriCliente(id) },
                     alTavolo: stato.sala.tavoloEsperienza == .disegna,
                     mandaAlTavolo: { assi, ingresso, risultato, frase in
                         stato.disegnoAlTavolo(cliente: id, assi: assi, ingresso: ingresso, risultato: risultato, frase: frase)
                     })
            .onDisappear { stato.lasciaTavolo(.disegna) }
    }
}

private enum FaseDisegno { case vuota, disegno, trasformazione, risultato }

private struct CorpoDisegno: View {
    let cliente: Cliente
    let preparazione: PreparazioneLineaVita
    let prova: [CGPoint]?
    let obiettivi: [Obiettivo]
    let salva: (Obiettivo) -> Void
    let completaAnagrafica: () -> Void
    /// Il tavolo a doppio senso (giro 16, decisione 113): il cliente disegna sull'iPad, il Mac calcola e rimanda.
    var alTavolo = false
    var mandaAlTavolo: (AssiDisegno, IngressoLineaVita, PaginaTavolo?, String?) -> Void = { _, _, _, _ in }

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaStatoFinale) private var statoFinale

    @State private var fase: FaseDisegno = .vuota
    @State private var tratto = TrattoDisegno()
    @State private var gradini = 0
    @State private var avanzamento: Double = 0
    @State private var esito: EsitoDisegno?
    @State private var risultatoVisibile = false
    @State private var generazione = 0
    @State private var modulo = false
    @State private var toast: String?
    @State private var preparato = false
    /// Gli assi e l'ingresso della tela mostrata (per convertire i punti che arrivano dall'iPad).
    @State private var assiTavolo: AssiDisegno?
    @State private var ingressoTavolo: IngressoLineaVita?

    private typealias D = Tema.Apple.SalaRacconti.Disegno

    private var nome: String { StatoShell.nomeBreve(cliente) }
    private var fermo: Bool { calmo || istantanea || statoFinale }

    var body: some View {
        GeometryReader { g in
            if let ingresso = preparazione.ingresso {
                let tela = misuraTela(g.size)
                let piano = MotoreLineaVita.calcola(ingresso)
                let assi = MotoreDisegno.assi(piano, area: areaGrafico(tela), gradini: gradini)
                ZStack(alignment: .topLeading) {
                    telaDisegno(tela, assi: assi, ingresso: ingresso, piano: piano)
                        .frame(width: tela.width, height: tela.height)
                        .offset(x: D.telaSinistra, y: D.telaAlto)
                    colonna(ingresso)
                        .frame(width: max(0, g.size.width - D.telaSinistra - tela.width - (D.colonnaSinistra - D.telaSinistra - D.tela.width) - D.colonnaDestra),
                               height: max(0, g.size.height - D.colonnaAlto - D.colonnaBasso), alignment: .topLeading)
                        .offset(x: D.telaSinistra + tela.width + (D.colonnaSinistra - D.telaSinistra - D.tela.width), y: D.colonnaAlto)
                    if modulo, let e = esito {
                        D.veloModulo
                            .contentShape(Rectangle())
                            .onTapGesture { modulo = false }
                        ModuloObiettivoDisegno(cliente: cliente, esito: e, esistente: obiettivoUguale,
                                               annulla: { modulo = false },
                                               salva: { o, nuovo in
                                                   salva(o)
                                                   modulo = false
                                                   toast = nuovo ? "Nuovo obiettivo nel dossier di \(nome)" : "Obiettivo aggiornato nel dossier di \(nome)"
                                               })
                            .frame(width: g.size.width, height: g.size.height)
                    }
                }
                .onAppear {
                    prepara(assi: assi, ingresso: ingresso)
                    assiTavolo = assi
                    ingressoTavolo = ingresso
                }
                .onChange(of: assi) { _, a in assiTavolo = a }
            } else {
                manca
                    .frame(width: g.size.width, height: g.size.height)
            }
        }
        .avvisoToast($toast)
        .dalTavolo { c in if case .tratto(let t) = c { disegnoDalTavolo(t) } }
        .onChange(of: alTavolo) { _, acceso in
            guard acceso, let a = assiTavolo, let i = ingressoTavolo else { return }
            mandaAlTavolo(a, i, nil, nil)
        }
    }

    // MARK: Il tavolo a doppio senso

    /// Il tratto dall'iPad (punti 0…1, y = 0 in basso): convertito come `prepara(assi:ingresso:)`, poi la stessa strada
    /// del rilascio sul Mac; il risultato disegnato torna all'iPad con la frase.
    private func disegnoDalTavolo(_ t: TrattoTavolo) {
        guard alTavolo, !modulo, t.valido(), let assi = assiTavolo, let ingresso = ingressoTavolo else { return }
        generazione += 1
        tratto = TrattoDisegno(punti: t.punti.map {
            CGPoint(x: Double(assi.etaOggi) + $0.x * assi.anni, y: $0.y * assi.massimo)
        })
        guard tratto.punti.count >= MotoreDisegno.puntiMinimi else { return ricomincia() }
        fase = .disegno
        trasforma(assi: assi, ingresso: ingresso)
        guard let e = esito else { return }
        mandaAlTavolo(assi, ingresso, paginaRisultato(e, assi: assi), fraseRisultato(e))
    }

    /// Il risultato per l'iPad: il disegno (tratteggiato) e la curva del piano, su carta bianca.
    private func paginaRisultato(_ e: EsitoDisegno, assi: AssiDisegno) -> PaginaTavolo? {
        let misura = CGSize(width: assi.area.maxX + assi.area.minX, height: assi.area.maxY + assi.area.minY)
        let vista = ZStack {
            D.fondoTela
            CurvaTrasformata(da: e.disegno, a: e.disegno, assi: assi, avanzamento: 1)
                .stroke(D.coloreDisegno.opacity(D.opacitaFantasma),
                        style: StrokeStyle(lineWidth: D.spessoreFantasma, lineCap: .round, dash: D.tratteggioFantasma))
            CurvaTrasformata(da: e.disegno, a: e.possibile, assi: assi, avanzamento: 1)
                .stroke(D.colorePossibile, style: StrokeStyle(lineWidth: D.curvaPossibile, lineCap: .round, lineJoin: .round))
        }
        .frame(width: misura.width, height: misura.height)
        .environment(\.colorScheme, .light)
        let r = ImageRenderer(content: vista)
        r.proposedSize = ProposedViewSize(misura)
        r.scale = Tema.Apple.Tavolo.scalaPagina
        guard let immagine = r.cgImage, let png = ProtocolloTavolo.png(immagine) else { return nil }
        return PaginaTavolo(numero: 1, totale: 1, larghezza: Double(misura.width), altezza: Double(misura.height), png: png)
    }

    private func fraseRisultato(_ e: EsitoDisegno) -> String {
        var f = "Il tuo disegno a \(e.etaPensione) anni: \(Formati.euro(e.alDisegno)). Il piano di oggi: \(Formati.euro(e.alPiano))."
        if let v = e.versamentoInPiu { f += " Per arrivarci servono circa \(Formati.euro(v)) in più al mese." }
        return f
    }

    // MARK: Misure

    /// La tela 900×520, più piccola se il palco è stretto (la colonna di destra resta larga almeno 300).
    private func misuraTela(_ palco: CGSize) -> CGSize {
        let colonnaMinima: CGFloat = 300
        let spazioColonna = D.colonnaSinistra - D.telaSinistra - D.tela.width
        let w = min(D.tela.width, palco.width - D.telaSinistra - spazioColonna - colonnaMinima - D.colonnaDestra)
        let h = min(D.tela.height, palco.height - D.telaAlto - D.colonnaBasso)
        return CGSize(width: max(320, w), height: max(240, h))
    }

    private func areaGrafico(_ tela: CGSize) -> CGRect {
        CGRect(x: D.margini.leading, y: D.margini.top, width: max(1, tela.width - D.margini.leading - D.margini.trailing),
               height: max(1, tela.height - D.margini.top - D.margini.bottom))
    }

    // MARK: Lo stato iniziale (istantanee)

    private func prepara(assi: AssiDisegno, ingresso: IngressoLineaVita) {
        guard !preparato else { return }
        preparato = true
        guard let prova, prova.count >= MotoreDisegno.puntiMinimi else { return }
        tratto = TrattoDisegno(punti: prova.map {
            CGPoint(x: Double(assi.etaOggi) + Double($0.x) * assi.anni, y: Double($0.y) * assi.massimo)
        })
        esito = MotoreDisegno.esito(tratto, ingresso: ingresso, assi: assi)
        avanzamento = 1
        fase = .risultato
        risultatoVisibile = true
    }

    // MARK: La tela

    private func telaDisegno(_ misura: CGSize, assi: AssiDisegno, ingresso: IngressoLineaVita, piano: EsitoLineaVita) -> some View {
        let partenza = CGPoint(x: assi.x(Double(assi.etaOggi)), y: assi.y(max(0, ingresso.patrimonioIniziale)))
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: D.raggioTela, style: .continuous)
                .fill(D.fondoTela)
            Canvas { ctx, _ in
                disegnaAssi(ctx, assi: assi)
                if fase == .disegno {
                    var p = Path()
                    for (i, d) in tratto.punti.enumerated() {
                        let q = assi.punto(d)
                        if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
                    }
                    ctx.stroke(p, with: .color(D.coloreDisegno), style: StrokeStyle(lineWidth: D.tratto, lineCap: .round, lineJoin: .round))
                }
            }
            if let e = esito, fase == .trasformazione || fase == .risultato {
                // Il fantasma del disegno, tratteggiato
                CurvaTrasformata(da: e.disegno, a: e.disegno, assi: assi, avanzamento: 1)
                    .stroke(D.coloreDisegno.opacity(D.opacitaFantasma),
                            style: StrokeStyle(lineWidth: D.spessoreFantasma, lineCap: .round, dash: D.tratteggioFantasma))
                // La curva verde: dal disegno al piano (dopo la pensione tratteggiata se indicativa)
                CurvaTrasformata(da: e.disegno, a: e.possibile, assi: assi, avanzamento: avanzamento,
                                 fino: e.dopoPensioneIndicativa ? e.etaPensione : nil)
                    .stroke(D.colorePossibile, style: StrokeStyle(lineWidth: D.curvaPossibile, lineCap: .round, lineJoin: .round))
                if e.dopoPensioneIndicativa {
                    CurvaTrasformata(da: e.disegno, a: e.possibile, assi: assi, avanzamento: avanzamento, dalla: e.etaPensione)
                        .stroke(D.colorePossibile, style: StrokeStyle(lineWidth: D.curvaPossibile, lineCap: .round, dash: D.tratteggioIndicativa))
                }
                PuntoTrasformato(da: e.disegno, a: e.possibile, indice: e.etaPensione - e.etaOggi, assi: assi,
                                 raggio: D.raggioPunto, avanzamento: avanzamento)
                    .fill(D.colorePossibile)
            }
            Circle()
                .fill(D.colorePartenza)
                .frame(width: D.raggioPunto * 2, height: D.raggioPunto * 2)
                .position(partenza)
            if alTavolo {
                Text(TestiRealta.disegnaSulliPad)
                    .carattereApple(D.invito)
                    .foregroundColor(D.coloreAssi)
                    .padding(D.invitoDestra)
                    .allowsHitTesting(false)
            }
            if fase == .vuota {
                Text("Disegna qui, partendo dal punto viola →")
                    .carattereApple(D.invito)
                    .foregroundColor(D.coloreAssi)
                    .fixedSize()
                    .offset(x: partenza.x + D.invitoDestra, y: partenza.y - D.invitoSopra - D.invito.dimensione)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: D.raggioTela, style: .continuous))
        .contentShape(Rectangle())
        .gesture(gestoDisegno(assi: assi, ingresso: ingresso))
        #if os(macOS)
        .onHover { dentro in if dentro { NSCursor.crosshair.push() } else { NSCursor.pop() } }
        #endif
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Tela per disegnare il patrimonio da \(assi.etaOggi) a \(assi.etaFine) anni"))
    }

    private func disegnaAssi(_ ctx: GraphicsContext, assi: AssiDisegno) {
        let a = assi.area
        var righe = Path()
        var eta = Int((Double(assi.etaOggi) / Double(D.passoAnni)).rounded(.up)) * D.passoAnni
        while eta <= assi.etaFine {
            let x = assi.x(Double(eta))
            righe.move(to: CGPoint(x: x, y: a.minY))
            righe.addLine(to: CGPoint(x: x, y: a.maxY))
            // L'ultima età non esce dalla tela: allineata a destra sulla sua riga
            let ultima = eta + D.passoAnni > assi.etaFine && a.maxX + D.margini.trailing - x < D.margini.leading
            ctx.draw(Text("\(eta) anni").font(D.scrittaAssi.font).foregroundColor(D.coloreAssi),
                     at: CGPoint(x: x, y: a.maxY + D.etaSotto), anchor: ultima ? .trailing : .center)
            eta += D.passoAnni
        }
        for k in 0..<D.righeOrizzontali {
            let v = assi.massimo * Double(k) / Double(D.righeOrizzontali - 1)
            let y = assi.y(v)
            righe.move(to: CGPoint(x: a.minX, y: y))
            righe.addLine(to: CGPoint(x: a.maxX, y: y))
            ctx.draw(Text(MotoreDisegno.etichettaAsse(v)).font(D.scrittaAssi.font).foregroundColor(D.coloreAssi),
                     at: CGPoint(x: D.asseSinistra, y: y), anchor: .leading)
        }
        ctx.stroke(righe, with: .color(D.righe), lineWidth: D.spessoreRighe)
    }

    private func gestoDisegno(assi: AssiDisegno, ingresso: IngressoLineaVita) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { v in
                guard !modulo else { return }
                if fase != .disegno {
                    // Un tratto nuovo riparte da capo (anche sopra il risultato)
                    generazione += 1
                    fase = .disegno
                    tratto = TrattoDisegno()
                    esito = nil
                    risultatoVisibile = false
                    avanzamento = 0
                    gradini = 0
                }
                MotoreDisegno.aggiungi(v.location, a: &tratto, assi: assi)
                if MotoreDisegno.toccaIlBordo(tratto, assi: assi), gradini < MotoreDisegno.gradiniMassimi { gradini += 1 }
            }
            .onEnded { _ in
                guard fase == .disegno else { return }
                if tratto.punti.count < MotoreDisegno.puntiMinimi {
                    ricomincia()
                    return
                }
                trasforma(assi: assi, ingresso: ingresso)
            }
    }

    private func trasforma(assi: AssiDisegno, ingresso: IngressoLineaVita) {
        esito = MotoreDisegno.esito(tratto, ingresso: ingresso, assi: assi)
        guard esito != nil else { ricomincia(); return }
        avanzamento = 0
        fase = .trasformazione
        if fermo {
            withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : nil) {
                avanzamento = 1
                fase = .risultato
                risultatoVisibile = true
            }
            return
        }
        withAnimation(Tema.Apple.Moto.Disegno.animazione) { avanzamento = 1 }
        generazione += 1
        let giro = generazione
        // A trasformazione finita (un solo rinvio, non un orologio): il risultato entra a cascata
        DispatchQueue.main.asyncAfter(deadline: .now() + Tema.Apple.Moto.Disegno.trasformazione) {
            guard giro == generazione, fase == .trasformazione else { return }
            fase = .risultato
            risultatoVisibile = true
        }
    }

    private func ricomincia() {
        generazione += 1
        fase = .vuota
        tratto = TrattoDisegno()
        esito = nil
        risultatoVisibile = false
        avanzamento = 0
        gradini = 0
    }

    // MARK: La colonna di destra

    private func colonna(_ ingresso: IngressoLineaVita) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Disegna come vorresti che crescesse il tuo patrimonio.")
                .carattereApple(D.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
            Text("Con il dito sull’iPad, o con il mouse qui, da sinistra a destra. Prisma lo trasforma nel piano che si può fare davvero.")
                .carattereApple(D.spiegazione)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, D.sottoTitolo)
            if ingresso.patrimonioIniziale <= 0 {
                Text("Il punto di partenza è 0 €: \(nome) non ha ancora posizioni in essere.")
                    .carattereApple(D.nota)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, D.sopraNota)
            }
            if risultatoVisibile, let e = esito {
                RisultatoDisegno(esito: e)
                    .padding(.top, D.sopraRisultato)
            }
            Spacer(minLength: D.sopraRisultato)
            HStack(spacing: D.spazioPulsanti) {
                Button("↻ Ricomincia") { ricomincia() }
                    .buttonStyle(.appleGrande)
                    .keyboardShortcut(.delete, modifiers: [])
                    .disabled(fase == .vuota)
                    .help("Cancella il disegno (⌫)")
                Button("Salva come obiettivo") { modulo = true }
                    .buttonStyle(.applePrimarioGrande)
                    .keyboardShortcut(.defaultAction)
                    .disabled(fase != .risultato || esito == nil || modulo)
                    .help("Apre il modulo dell'obiettivo già compilato (⏎): niente si salva da solo")
            }
        }
    }

    /// Un obiettivo con lo stesso titolo proposto: si propone di aggiornarlo.
    private var obiettivoUguale: Obiettivo? {
        obiettivi.first { $0.titolo.caseInsensitiveCompare(ModuloObiettivoDisegno.titoloProposto) == .orderedSame }
    }

    // MARK: Senza data di nascita

    private var manca: some View {
        VStack(spacing: 14) {
            TasselloGlifo(glifo: .disegna, lato: Tema.Apple.Tassello.latoSalaGrande, raggio: Tema.Apple.Raggio.voce)
            Text("Per disegnare il futuro serve la data di nascita di \(nome).")
                .carattereApple(Tema.Apple.SalaEsperienze.Palco.titoloInArrivo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Completa l’anagrafica ›", action: completaAnagrafica)
                .buttonStyle(.apple)
        }
        .frame(maxWidth: D.larghezzaManca)
    }
}

// MARK: - Il risultato

private struct RisultatoDisegno: View {
    let esito: EsitoDisegno

    private typealias D = Tema.Apple.SalaRacconti.Disegno

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            riquadro("Il tuo disegno, a \(esito.etaPensione) anni", valore: esito.alDisegno, colore: D.coloreDisegno, indice: 0)
                .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            riquadro("Il piano di oggi, a \(esito.etaPensione) anni", valore: esito.alPiano, colore: D.colorePossibile, indice: 1)
                .padding(.top, D.fraTile)
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            Group {
                if let v = esito.versamentoInPiu {
                    Text("Per arrivare al tuo disegno servono circa \(Formati.euro(v)) in più al mese.")
                } else {
                    Text("Il tuo disegno è già alla portata del piano di oggi.")
                }
            }
            .carattereApple(D.frase)
            .foregroundColor(Tema.Apple.Colore.inchiostro)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, D.sopraFrase)
            .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            VStack(alignment: .leading, spacing: D.sopraAvvertenza) {
                if esito.sopraDopoPensione {
                    Text("Dopo la pensione il tuo disegno chiede più di quanto il piano lascia: ne parliamo.")
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                }
                Text("Stima in euro di oggi con un rendimento reale del \(Formati.percentuale(esito.rendimentoReale)) l’anno, non garantito.")
                if esito.dopoPensioneIndicativa {
                    Text("Dopo la pensione la curva è indicativa: manca il reddito desiderato in Analisi 360.")
                }
            }
            .carattereApple(D.avvertenza)
            .foregroundColor(Tema.Apple.Colore.inchiostro2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, D.sopraAvvertenza)
            .entrataCascata(3, base: Tema.Apple.Moto.Cascata.baseDentroApp)
        }
        .accessibilityElement(children: .combine)
    }

    private func riquadro(_ titolo: String, valore: Double, colore: Color, indice: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titolo)
                .carattereApple(D.etichettaTile)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            NumeroCheConta(valore, indice: indice)
                .carattereApple(D.cifraTile)
                .foregroundColor(colore)
                .lineLimit(1)
        }
        .padding(D.paddingTile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(D.superficieTile, raggio: D.raggioTile)
    }
}

// MARK: - Le curve che si trasformano

/// La curva che passa dalla serie `da` alla serie `a` (un valore per età): `avanzamento` 0…1 si anima con SwiftUI e la
/// quartica si applica qui, punto per punto. `fino` / `dalla` tagliano la curva prima o dopo un'età.
struct CurvaTrasformata: Shape {
    let da: [Double]
    let a: [Double]
    let assi: AssiDisegno
    var avanzamento: Double
    var fino: Int? = nil
    var dalla: Int? = nil

    var animatableData: Double {
        get { avanzamento }
        set { avanzamento = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let e = Tema.Apple.Moto.Curva.quartica(avanzamento)
        let n = min(da.count, a.count)
        var p = Path()
        var primo = true
        for i in 0..<n {
            let eta = assi.etaOggi + i
            if let fino, eta > fino { break }
            if let dalla, eta < dalla { continue }
            let v = da[i] + (a[i] - da[i]) * e
            let q = CGPoint(x: assi.x(Double(eta)), y: assi.y(max(0, v)))
            if primo { p.move(to: q); primo = false } else { p.addLine(to: q) }
        }
        return p
    }
}

/// Il punto verde sull'età di pensione, che segue la curva che si trasforma.
struct PuntoTrasformato: Shape {
    let da: [Double]
    let a: [Double]
    let indice: Int
    let assi: AssiDisegno
    let raggio: CGFloat
    var avanzamento: Double

    var animatableData: Double {
        get { avanzamento }
        set { avanzamento = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard indice >= 0, indice < min(da.count, a.count) else { return Path() }
        let e = Tema.Apple.Moto.Curva.quartica(avanzamento)
        let v = da[indice] + (a[indice] - da[indice]) * e
        let c = CGPoint(x: assi.x(Double(assi.etaOggi + indice)), y: assi.y(max(0, v)))
        return Path(ellipseIn: CGRect(x: c.x - raggio, y: c.y - raggio, width: raggio * 2, height: raggio * 2))
    }
}

// MARK: - Il modulo dell'obiettivo

/// «Salva come obiettivo»: il modulo già compilato. Titolo e versamento si possono cambiare; importo, area e scadenza
/// vengono dal disegno. Se c'è già un obiettivo con lo stesso titolo si propone di aggiornarlo.
private struct ModuloObiettivoDisegno: View {
    let cliente: Cliente
    let esito: EsitoDisegno
    let esistente: Obiettivo?
    let annulla: () -> Void
    let salva: (Obiettivo, Bool) -> Void

    static let titoloProposto = "Il patrimonio che ho disegnato"

    @State private var titolo = ModuloObiettivoDisegno.titoloProposto
    @State private var versamento: Double = 0
    @State private var pronto = false

    private typealias D = Tema.Apple.SalaRacconti.Disegno

    private var scadenza: Date {
        MotoreDisegno.dataPensione(nascita: cliente.dataNascita, eta: esito.etaPensione) ?? Date()
    }

    private var aggiorna: Bool {
        esistente != nil && titolo.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(Self.titoloProposto) == .orderedSame
    }

    var body: some View {
        VStack(alignment: .leading, spacing: D.spazioModulo) {
            Text(aggiorna ? "Aggiorna l’obiettivo" : "Nuovo obiettivo")
                .carattereApple(D.titoloModulo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            campo("Titolo") {
                TextField("Titolo", text: $titolo)
                    .textFieldStyle(.roundedBorder)
            }
            riga("Area", AreaBisogno.pensione.nome)
            riga("Importo, in euro di oggi", Formati.euro(esito.alDisegno))
            riga("Scadenza: a \(esito.etaPensione) anni", scadenza.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "it_IT"))))
            campo("Versamento mensile previsto") {
                TextField("Versamento", value: $versamento, format: .number.precision(.fractionLength(0)))
                    .textFieldStyle(.roundedBorder)
            }
            if aggiorna {
                Text("C’è già un obiettivo con questo titolo: salvando lo aggiorni.")
                    .carattereApple(D.etichettaModulo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
            HStack(spacing: D.spazioPulsanti) {
                Spacer()
                Button("Annulla", action: annulla)
                    .buttonStyle(.apple)
                Button(aggiorna ? "Aggiorna" : "Salva") { conferma() }
                    .buttonStyle(.applePrimario)
                    .disabled(titolo.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(D.paddingModulo)
        .frame(width: D.larghezzaModulo)
        .superficieApple(D.superficieModulo, raggio: D.raggioModulo)
        .onAppear {
            guard !pronto else { return }
            pronto = true
            versamento = esito.versamentoInPiu ?? 0
        }
    }

    private func campo<V: View>(_ etichetta: String, @ViewBuilder contenuto: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(etichetta)
                .carattereApple(D.etichettaModulo)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            contenuto()
                .carattereApple(D.campoModulo)
        }
    }

    private func riga(_ etichetta: String, _ valore: String) -> some View {
        HStack {
            Text(etichetta)
                .carattereApple(D.etichettaModulo)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            Spacer()
            Text(valore)
                .carattereApple(D.campoModulo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
        }
    }

    private func conferma() {
        let t = titolo.trimmingCharacters(in: .whitespaces)
        var o = aggiorna ? esistente! : Obiettivo(clienteId: cliente.id, titolo: t, area: .pensione,
                                                   importo: esito.alDisegno, scadenza: scadenza)
        o.titolo = t
        o.area = .pensione
        o.importo = esito.alDisegno.rounded()
        o.scadenza = scadenza
        o.versamentoMensile = max(0, versamento.isFinite ? versamento : 0)
        if o.note.isEmpty { o.note = "Dal disegno del futuro nella Sala." }
        salva(o, !aggiorna)
    }
}
