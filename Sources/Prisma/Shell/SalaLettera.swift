import SwiftUI

// La lettera dal futuro (Design/template-luce-specifica.md §3.1, «Luce» giro 8): il cliente legge la lettera che «lui
// stesso», all'età della pensione, gli scrive dal futuro.
//
//   ( Con il piano | Senza il piano )   ┌──────────────────────────────────────────────┐
//   Vera scrive la lettera con le        │ UNA LETTERA DAL FUTURO                       │
//   cifre dei motori di Prisma…          │ Cara Giulia,                                 │
//   ┌ Pensione stimata con il piano ┐    │ ti scrivo dal 2056. Ho 67 anni…  (serif)     │
//   │ 2.160 €                       │    │                                              │
//   └───────────────────────────────┘    │ Giulia, 67 anni                              │
//   ┌ Senza il piano  1.400 €       ┐    │ ───────────────────────────────────────────  │
//   [ ↻ Riscrivi ]                       │ Stime basate su ipotesi… (avvertenza)        │
//                                        └──────────────────────────────────────────────┘
//
// - Le cifre vengono da `MotoreLettera` (pensione da `PensioneEsperienze` con le ipotesi confermate, arrivo
//   dell'obiettivo da `CurvaObiettivo`); Vera (Qwen sul Mac, `LetteraVera`) la racconta in streaming e Prisma controlla
//   ogni cifra a fine flusso. Se Qwen non è pronto resta la lettera fissa di Prisma, che compare una parola ogni 26 ms
//   (`TestoProgressivo`), e Vera lo dice in arancio sotto il segmentato.
// - Il foglio è carta calda (#FFFDF8) anche nello scuro; nel PDF («Salva la lettera in PDF…» dal menu del foglio) la
//   carta è bianca (`Tema.Apple.Carta`). Niente esce dal Mac: «Mostra sul tavolo» e «Aggiungi al Prisma» arrivano dopo.
// - Le due stesure si tengono in memoria finché il palco è aperto; cambiare versione ferma il flusso in corso.
// - «Riduci movimento»: la lettera compare intera con la dissolvenza di 0,15 s (con Qwen a flusso finito). Istantanee:
//   la lettera fissa, intera, mai Qwen.

/// Il contenuto del palco per la lettera dal futuro.
struct LetteraDalFuturo: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    /// Nella presentazione la lettera si legge: niente «Riscrivi» né collegamenti.
    var modificabile = true

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    @State private var versione: VersioneLettera
    /// Le stesure di Vera (o fisse con l'avviso), per versione, finché il palco è aperto.
    @State private var stesure: [VersioneLettera: TestoLettera] = [:]
    /// Il testo che sta arrivando da Qwen (nil = nessun flusso in corso).
    @State private var inArrivo: String?
    @State private var compito: Task<Void, Never>?
    @State private var opacitaTesto: Double = 1
    /// Cambia a ogni nuova comparsa della lettera fissa (fa ripartire la scrittura parola per parola).
    @State private var giro = 0

    private typealias L = Tema.Apple.SalaRacconti.Lettera

    init(cliente: Cliente, versione: VersioneLettera, modificabile: Bool = true) {
        self.cliente = cliente
        self.modificabile = modificabile
        self._versione = State(initialValue: versione)
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let nome = StatoShell.nomeBreve(cliente)
        let scheda = MotoreLettera.scheda(cliente: cliente, posizioni: stato.posizioniCliente(cliente.id),
                                          obiettivi: stato.obiettiviCliente(cliente.id), analisi: stato.dati.analisi[cliente.id],
                                          oggi: Date())
        Group {
            if let scheda {
                ZStack(alignment: .topLeading) {
                    colonna(scheda, nome: nome)
                        .frame(width: L.larghezzaColonna, alignment: .topLeading)
                        .padding(.leading, L.margineColonna)
                        .padding(.top, L.margineColonna)
                        .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                    foglio(scheda)
                        .padding(.leading, L.foglioSinistra)
                        .padding(.trailing, L.foglioDestra)
                        .padding(.vertical, L.foglioSopraSotto)
                        .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .onAppear { avvia(scheda) }
                .onDisappear { compito?.cancel() }
                .onChange(of: versione) { _, nuova in
                    stato.sala.versioneLettera = nuova
                    cambia(scheda, riscrivi: false)
                }
            } else {
                manca(nome: nome)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: La colonna di sinistra

    @ViewBuilder
    private func colonna(_ s: SchedaLettera, nome: String) -> some View {
        let pronta = qwenPronta
        VStack(alignment: .leading, spacing: 0) {
            SegmentatoPillola(selezione: $versione, voci: VersioneLettera.allCases.map { ($0, $0.titolo) })
                .fixedSize()
                .disabled(!s.pianoPresente)
                .help(s.pianoPresente ? "Con il piano: le proposte e i versamenti previsti. Senza: la pensione pubblica e i piani che ha già"
                      : "Per confrontare serve un piano: una proposta o un versamento per un obiettivo")
            ForEach(Array(note(s, nome: nome).enumerated()), id: \.offset) { _, n in
                Text(n.testo)
                    .carattereApple(L.nota)
                    .foregroundColor(n.avviso ? L.coloreAvviso : L.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, L.sopraNota)
            }
            Text("Vera scrive la lettera con le cifre dei motori di Prisma: pensione, obiettivi, versamenti.")
                .carattereApple(L.spiegazione)
                .foregroundColor(L.coloreSpiegazione)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, L.sottoSegmentato)
            tile("Pensione stimata con il piano", valore: s.pensioneConPiano ?? (s.pianoPresente ? nil : s.pensioneSenzaPiano),
                 colore: L.coloreConPiano, indice: 0)
                .padding(.top, L.sopraTile)
            tile("Senza il piano", valore: s.pensioneSenzaPiano, colore: L.coloreSenzaPiano, indice: 1)
                .padding(.top, L.fraTile)
            if modificabile {
                if s.pensioneSenzaPiano == nil {
                    Button("Imposta la previdenza in Analisi 360 ›") {
                        stato.clienteAttivoId = cliente.id
                        stato.areaAnalisi = .previdenza
                        stato.apri(.analisi360)
                    }
                    .buttonStyle(.appleSobrio)
                    .padding(.top, L.fraTile)
                }
                Button { cambia(s, riscrivi: true) } label: { Text("↻ Riscrivi") }
                    .buttonStyle(.appleGrande)
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(!pronta || istantanea)
                    .help(pronta ? "Vera scrive una nuova stesura di questa versione (⌘R)" : "Vera non è pronta: la lettera è quella di Prisma")
                    .padding(.top, L.sopraPulsante)
            }
        }
    }

    private func tile(_ titolo: String, valore: Double?, colore: Color, indice: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titolo)
                .carattereApple(L.etichettaTile)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            Group {
                if let valore {
                    NumeroCheConta(valore, indice: indice)
                } else {
                    Text("—")
                }
            }
            .carattereApple(L.cifraTile)
            .foregroundColor(valore == nil ? Tema.Apple.Colore.inchiostro2 : colore)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(L.paddingTile)
        .superficieApple(L.superficieTile, raggio: L.raggioTile)
    }

    /// Le note sotto il segmentato: età ipotizzata, obiettivo mancante, previdenza da confermare, Vera non pronta.
    private func note(_ s: SchedaLettera, nome: String) -> [(testo: String, avviso: Bool)] {
        var r: [(String, Bool)] = []
        if StatoShell.clientiDiProva.contains(cliente.id) && stato.haDatiDiProva { r.append(("Dati di prova.", false)) }
        if s.etaIpotizzata { r.append(("\(s.etaTraguardo) anni: età di pensione ipotizzata.", false)) }
        if s.mancanti.contains(.previdenza) {
            r.append(("Senza le ipotesi di previdenza confermate la lettera non parla di pensione.", false))
        }
        if s.mancanti.contains(.obiettivo) { r.append(("Aggiungi un obiettivo per raccontarlo.", false)) }
        if let avviso = avvisoVera { r.append((avviso, true)) }
        if inArrivo != nil && calmo { r.append(("Vera sta scrivendo…", false)) }
        return r
    }

    // MARK: Il foglio

    private func foglio(_ s: SchedaLettera) -> some View {
        let avvertenza = ImpostazioniSala.avvertenza(stato.dati.impostazioni.sala.avvertenzaLettera)
        return FoglioLettera(testo: testoMostrato(s), avvertenza: avvertenza.testo, carta: false, progressivo: progressivo(s),
                             giro: giro)
            .opacity(opacitaTesto)
            .contextMenu {
                Button("Salva la lettera in PDF…") { salvaPDF(s) }
            }
            .accessibilityLabel(Text("Una lettera dal futuro"))
    }

    /// Il testo da mostrare: il flusso di Qwen, la stesura finita o la lettera fissa.
    private func testoMostrato(_ s: SchedaLettera) -> String {
        if let inArrivo, !calmo { return inArrivo }
        if let t = stesure[versione], inArrivo == nil { return t.testo }
        return MotoreLettera.conFirma(MotoreLettera.fissa(s, versione), s)
    }

    /// La lettera fissa (o una stesura di Prisma) compare parola per parola; il flusso di Qwen arriva già a pezzi.
    private func progressivo(_ s: SchedaLettera) -> Bool {
        guard !istantanea, !calmo, inArrivo == nil else { return false }
        return stesure[versione].map { $0.autore == .modelloFisso } ?? true
    }

    private var qwenPronta: Bool { !istantanea && stato.disponibilitaLocale.pronto }

    /// L'avviso arancio: Qwen non pronto o stesura scartata.
    private var avvisoVera: String? {
        if istantanea { return stato.sala.letteraNonProntaIstantanea ? LetteraVera.avvisoNonPronta(nil) : nil }
        if let a = stesure[versione]?.avviso { return a }
        return stato.disponibilitaLocale.pronto ? nil : LetteraVera.avvisoNonPronta(stato.disponibilitaLocale.motivo)
    }

    // MARK: Scrivere

    private func avvia(_ s: SchedaLettera) {
        guard !istantanea, qwenPronta, stesure[versione] == nil, compito == nil else { return }
        scrivi(s, dopo: Tema.Apple.Moto.Lettera.ritardoAvvio)
    }

    /// Cambio di versione o «Riscrivi»: il testo sfuma, il flusso in corso si ferma, poi la nuova stesura.
    private func cambia(_ s: SchedaLettera, riscrivi: Bool) {
        compito?.cancel()
        compito = nil
        inArrivo = nil
        if riscrivi { stesure[versione] = nil }
        let d = Tema.Apple.Moto.Lettera.dissolvenzaCambio
        if istantanea {
            giro += 1
            return
        }
        withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : .easeOut(duration: d)) { opacitaTesto = 0 }
        Movimenti.dopo(calmo ? 0 : d) {
            giro += 1
            withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : .easeIn(duration: d)) { opacitaTesto = 1 }
            if qwenPronta, stesure[versione] == nil { scrivi(s, dopo: 0) }
        }
    }

    private func scrivi(_ s: SchedaLettera, dopo attesa: Double) {
        let v = versione
        let vera = stato.dati.impostazioni.vera
        let motore = MotoriVera.qwen(vera, locale: stato.disponibilitaLocale)
        let posizioni = stato.posizioniCliente(cliente.id)
        compito = Task { @MainActor in
            if attesa > 0 { try? await Task.sleep(nanoseconds: UInt64(attesa * 1_000_000_000)) }
            guard !Task.isCancelled else { return }
            inArrivo = ""
            let r = await LetteraVera.scrivi(s, versione: v, posizioni: posizioni, motore: motore, vera: vera,
                                             aggiorna: { t in DispatchQueue.main.async { if versione == v, inArrivo != nil { inArrivo = t } } })
            guard !Task.isCancelled else { return }
            stesure[v] = r
            inArrivo = nil
            compito = nil
            if calmo { withAnimation(Tema.Moto.dissolvenzaCalma) { opacitaTesto = 1 } }
        }
    }

    // MARK: PDF

    @MainActor
    private func salvaPDF(_ s: SchedaLettera) {
        let testo = testoMostrato(s)
        let avvertenza = ImpostazioniSala.avvertenza(stato.dati.impostazioni.sala.avvertenzaLettera).testo
        let d = PaginaLettera.documento(testo: testo, avvertenza: avvertenza, cliente: cliente.nome)
        guard let dati = StampaCarta.pdf(d) else { return }
        StampaCarta.salva(dati, nome: StampaCarta.nomeFile(d))
    }

    // MARK: Senza data di nascita

    private func manca(nome: String) -> some View {
        VStack(spacing: L.spazioManca) {
            TasselloGlifo(glifo: .lettera, lato: Tema.Apple.Tassello.latoSalaGrande, raggio: Tema.Apple.Raggio.voce)
            Text("Per scrivere la lettera serve la data di nascita di \(nome).")
                .carattereApple(Tema.Apple.SalaEsperienze.Palco.titoloInArrivo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if modificabile {
                Button("Completa l’anagrafica ›") { stato.apriCliente(cliente.id) }
                    .buttonStyle(.apple)
            }
        }
        .frame(maxWidth: L.larghezzaManca)
        .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
    }
}

/// Il foglio della lettera: sopratitolo, testo serif, piede con l'avvertenza. Sullo schermo carta calda (uguale in
/// chiaro e in scuro); con `carta` i colori della carta dei PDF.
struct FoglioLettera: View {
    let testo: String
    let avvertenza: String
    /// Vero nel PDF: carta bianca e colori di `Tema.Apple.Carta`, senza ombra.
    let carta: Bool
    /// La lettera compare una parola per volta.
    var progressivo = false
    var giro = 0

    private typealias L = Tema.Apple.SalaRacconti.Lettera

    var body: some View {
        let fondo = carta ? Tema.Apple.Carta.fondo : L.carta
        let inchiostro = carta ? Tema.Apple.Carta.testoCorrente : L.inchiostro
        ZStack(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: L.spazioSopraTesto) {
                Text("Una lettera dal futuro")
                    .carattereApple(L.carattereSopratitolo)
                    .foregroundColor(carta ? Tema.Apple.Carta.etichetta : L.sopratitolo)
                Group {
                    if progressivo {
                        TestoProgressivo(testo: testo, passo: Tema.Apple.Moto.Lettera.passoParola)
                            .id(giro)
                    } else {
                        Text(testo)
                    }
                }
                .carattereApple(L.testo)
                .foregroundColor(inchiostro)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                Spacer(minLength: L.spazioPiede)
            }
            .padding(L.margini)
            VStack(alignment: .leading, spacing: L.piedeSopraFiletto) {
                Rectangle()
                    .fill(carta ? Tema.Apple.Carta.filetto : L.filetto)
                    .frame(height: L.spessoreFiletto)
                Text(avvertenza)
                    .carattereApple(L.caratterePiede)
                    .foregroundColor(carta ? Tema.Apple.Carta.piede : L.piede)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, L.piedeLati)
            .padding(.bottom, L.piedeFondo)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: L.raggio, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: L.raggio, style: .continuous)
                .fill(fondo)
                .modifier(OmbraFoglio(attiva: !carta))
        )
        // Il foglio resta chiaro anche nello scuro
        .environment(\.colorScheme, .light)
    }
}

private struct OmbraFoglio: ViewModifier {
    let attiva: Bool
    func body(content: Content) -> some View {
        if attiva { content.ombraApple(Tema.Apple.SalaRacconti.Lettera.ombra) } else { content }
    }
}

/// La pagina A4 della lettera per il PDF: carta bianca, margini del prospetto.
enum PaginaLettera {
    @MainActor
    static func documento(testo: String, avvertenza: String, cliente: String) -> DocumentoStampabile {
        let formato = Misure.Documento.prospetto
        let pagina = FoglioLettera(testo: testo, avvertenza: avvertenza, carta: true)
            .padding(Misure.Documento.margineProspetto)
            .frame(width: formato.width, height: formato.height)
            .background(Tema.Apple.Carta.fondo)
        return DocumentoStampabile(titolo: "La lettera dal futuro", cliente: cliente, genere: "Lettera", formato: formato,
                                   pagine: [AnyView(pagina)], tipo: .altro)
    }
}
