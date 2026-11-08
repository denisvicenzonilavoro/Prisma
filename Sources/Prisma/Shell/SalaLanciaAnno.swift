import SwiftUI

// Lancia l'anno (Design/template-luce-specifica.md §4.3, «Luce» giro 8): due vite affiancate, con e senza il piano.
//
//   L'anno                                   [⚂ Lancia l'anno] [Lancia 10 anni] [Gioca una carta ▾] [↻]
//   2026  37 anni
//   ┌ Con il piano        204.050 € ┐  ┌ Senza piano         204.050 € ┐
//   │ (area verde, pallino finale)  │  │ (area grigio-azzurra)         │
//   └───────────────────────────────┘  └───────────────────────────────┘
//   ┌▌2031 · Un anno brutto dei mercati ─────────────────────────────────┐
//   │ Con il piano: …                Senza: …                            │
//   └────────────────────────────────────────────────────────────────────┘
//   Stime basate su ipotesi, non garanzie di risultato.
//
// - Le cifre vengono da `MotoreLanciaAnno`: il mercato dell'anno dal Monte Carlo che esiste (una traiettoria, seme
//   per cliente e partita), lo stesso risparmio nelle due vite (decisione 78), gli eventi solo con probabilità e fonte
//   dell'utente, quelli della linea della vita all'età giusta, e le carte giocate a mano (decisione 69).
// - «Lancia 10 anni» con un `Task` legato alla vista (`Task.sleep`, niente Timer); «↻» la ferma e apre una partita
//   nuova (seme nuovo). Le partite non si salvano.
// - Movimento: cifre contate dal valore di prima (0,7 s), la carta nuova scende con la molla, quella di prima scende di
//   80 a opacità 0,4. «Riduci movimento»: dieci anni in un colpo, dissolvenza di 0,15 s. Istantanee: partita a seme
//   fisso già giocata.

extension StatoShell {
    /// La partita di Lancia l'anno di un cliente: numero 0 = la prima (seme per cliente), poi una nuova a ogni «↻».
    func partitaLanciaAnno(_ c: Cliente, numero: Int, seme: UInt64? = nil) -> Result<PartitaLanciaAnno, DatoLanciaMancante> {
        let tabella = MotoreLanciaAnno.eventi(risorsa: MotoreLanciaAnno.caricati?.eventi ?? [], utente: dati.impostazioni.sala.eventiAnno)
        return MotoreLanciaAnno.prepara(cliente: c, posizioni: posizioniCliente(c.id), obiettivi: obiettiviCliente(c.id),
                                        eventiCliente: dati.eventiVita.filter { $0.clienteId == c.id }, tabella: tabella,
                                        diProva: haDatiDiProva && StatoShell.clientiDiProva.contains(c.id),
                                        anniScelti: dati.impostazioni.sala.anniPartita, oggi: Date(),
                                        seme: seme ?? MotoreMonteCarlo.seme("\(c.id)-lancia-\(numero)"))
    }
}

/// Il contenuto del palco per Lancia l'anno.
struct LanciaAnnoVista: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    var modificabile = true

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    @State private var esito: Result<PartitaLanciaAnno, DatoLanciaMancante>
    @State private var numero = 0
    @State private var corsa: Task<Void, Never>?
    @State private var giroDado: Double = 0

    private typealias L = Tema.Apple.SalaEsperienze.Lancia
    private typealias M = Tema.Apple.Moto.SalaEsperienze.Lancia

    init(cliente: Cliente, esito: Result<PartitaLanciaAnno, DatoLanciaMancante>, modificabile: Bool = true) {
        self.cliente = cliente
        self.modificabile = modificabile
        self._esito = State(initialValue: esito)
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let nome = StatoShell.nomeBreve(cliente)
        Group {
            switch esito {
            case .success(let p):
                partita(p, nome: nome)
            case .failure:
                mancano(nome: nome)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onDisappear { corsa?.cancel() }
    }

    // MARK: La partita

    private func partita(_ p: PartitaLanciaAnno, nome: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            testa(p)
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            HStack(alignment: .top, spacing: L.spazioRiquadri) {
                riquadro(p, conPiano: true, nome: nome)
                riquadro(p, conPiano: false, nome: nome)
            }
            .padding(.top, L.sottoTesta)
            .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            Group {
                if p.finita {
                    fine(p)
                } else if p.anni.isEmpty {
                    Text(frase(p))
                        .carattereApple(L.frase)
                        .foregroundColor(L.coloreFrase)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    mazzo(p)
                }
            }
            .frame(height: L.altezzaCarte)
            .frame(maxWidth: .infinity)
            .padding(.top, L.sopraCarte)
            .entrataCascata(3, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            Spacer(minLength: 0)
            piede(p, nome: nome)
        }
        .padding(L.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func testa(_ p: PartitaLanciaAnno) -> some View {
        HStack(alignment: .bottom, spacing: L.spazioAnnoEta) {
            VStack(alignment: .leading, spacing: 0) {
                Text("L’anno")
                    .carattereApple(L.etichettaAnno)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                Text(String(p.annoCorrente))
                    .carattereApple(L.anno)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .contentTransition(.numericText())
            }
            if let eta = p.etaCorrente {
                Text("\(eta) anni")
                    .carattereApple(L.eta)
                    .foregroundColor(L.coloreEta)
                    .padding(.bottom, L.spazioAnnoEta / 2)
            }
            if StatoShell.clientiDiProva.contains(cliente.id) && stato.haDatiDiProva {
                Text("dati di prova")
                    .carattereApple(L.prova)
                    .foregroundColor(L.coloreProva)
                    .padding(.bottom, L.spazioAnnoEta / 2)
            }
            Spacer(minLength: L.spazioAnnoEta)
            // Anche nella presentazione il cliente lancia; le carte a mano restano al consulente
            pulsanti(p)
        }
    }

    private func pulsanti(_ p: PartitaLanciaAnno) -> some View {
        let fermo = p.finita || corsa != nil
        return HStack(spacing: L.spazioPulsanti) {
            Button { lancia(nil, animato: true) } label: {
                HStack(spacing: L.spazioPulsanti / 2) {
                    GlifoLuceVista(glifo: .dadi, lato: L.latoDado, colore: .white)
                        .rotationEffect(.degrees(giroDado))
                    Text("Lancia l’anno")
                }
            }
            .buttonStyle(.applePrimarioGrande)
            .keyboardShortcut(.space, modifiers: [])
            .disabled(fermo)
            .help("Un anno in più: i mercati dal Monte Carlo, gli eventi della vita del cliente (spazio)")
            Button { dieci() } label: { Text("Lancia 10 anni") }
                .buttonStyle(.appleGrande)
                .disabled(fermo)
                .help("Dieci anni di fila, uno ogni 0,7 secondi")
            if modificabile {
                Menu {
                    ForEach(p.tabella) { e in
                        Button(e.titolo) { lancia(e, animato: true) }
                    }
                } label: { Text("Gioca una carta") }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .disabled(fermo || p.tabella.isEmpty)
                    .help("Il prossimo anno porta l’imprevisto che scegli tu (le carte di Impostazioni › Sala)")
            }
            Button { nuova() } label: { Text("↻") }
                .buttonStyle(.appleGrande)
                .help("Un’altra partita, con anni diversi")
        }
        .fixedSize()
    }

    // MARK: Le due vite

    private func riquadro(_ p: PartitaLanciaAnno, conPiano: Bool, nome: String) -> some View {
        let vita = conPiano ? p.con : p.senza
        let massimo = max(1, (p.con.serie + p.senza.serie).max() ?? 1) * L.margineScala
        let asse = Double(max(p.anniMassimi, 1))
        let punti = vita.serie.enumerated().map { i, v in CGPoint(x: Double(i) / asse, y: max(0, v) / massimo) }
        let vuoto = conPiano && p.senzaPiano
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(conPiano ? "Con il piano" : "Senza piano")
                    .carattereApple(L.titoloRiquadro)
                    .foregroundColor(conPiano ? L.coloreConPiano : L.coloreSenzaPiano)
                Spacer(minLength: L.spazioPulsanti)
                if !vuoto {
                    NumeroCheConta(vita.valore, da: nil, durataCambio: M.numero)
                        .carattereApple(L.cifra)
                        .foregroundColor(conPiano ? L.coloreCifraCon : L.coloreCifraSenza)
                        .lineLimit(1)
                }
            }
            ZStack {
                if vuoto {
                    Text("Nessuna proposta aperta per \(nome): le due vite sarebbero uguali.")
                        .carattereApple(L.frase)
                        .foregroundColor(L.coloreFrase)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, L.spazioRiquadri)
                } else {
                    TracciatoGrafico(punti: punti.count == 1 ? [punti[0], punti[0]] : punti,
                                     colore: conPiano ? L.lineaCon : L.lineaSenza, spessore: L.spessoreLinea,
                                     area: true, opacitaArea: L.opacitaArea, puntoFinale: true, indice: conPiano ? 0 : 1)
                        .id("\(numero)-\(conPiano)")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: L.altezzaGrafico)
            .padding(.top, L.sopraGrafico)
        }
        .padding(L.paddingRiquadro)
        .frame(maxWidth: .infinity)
        .superficieApple(L.superficieRiquadro, raggio: L.raggioRiquadro)
    }

    // MARK: Le carte

    private func mazzo(_ p: PartitaLanciaAnno) -> some View {
        let ultime = Array(p.anni.suffix(2).reversed())
        return ZStack(alignment: .top) {
            ForEach(Array(ultime.enumerated()).reversed(), id: \.element.anno) { i, a in
                CartaAnno(anno: a, nome: StatoShell.nomeBreve(cliente))
                    .scaleEffect(i == 0 ? 1 : M.scalaStorico, anchor: .top)
                    .offset(y: i == 0 ? 0 : M.passoStorico)
                    .opacity(i == 0 ? 1 : M.opacitaStorico)
                    .zIndex(Double(-i))
                    .transition(calmo || istantanea ? .opacity : .modifier(active: EntrataCarta(fatto: 0), identity: EntrataCarta(fatto: 1)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func fine(_ p: PartitaLanciaAnno) -> some View {
        let anni = p.anni.count
        let con = p.con.valore
        let senza = p.senza.valore
        return VStack(spacing: L.spazioPiede) {
            Text("In \(anni) anni: con il piano \(Formati.euro(con)), senza \(Formati.euro(senza)).")
                .carattereApple(L.titoloFine)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            Text("In euro di oggi: \(Formati.euro(MotoreLanciaAnno.euroDiOggi(con, anni: anni))) e \(Formati.euro(MotoreLanciaAnno.euroDiOggi(senza, anni: anni))), con l’inflazione al \(Int(IpotesiCalcolo.inflazione))% l’anno.")
                .carattereApple(L.frase)
                .foregroundColor(L.coloreFrase)
            Button { nuova() } label: { Text("↻ Un’altra partita") }
                .buttonStyle(.apple)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: L.larghezzaFine)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func piede(_ p: PartitaLanciaAnno, nome: String) -> some View {
        let avvertenza = ImpostazioniSala.avvertenza(stato.dati.impostazioni.sala.avvertenzaLancia)
        var righe: [String] = []
        if p.pianoOltreRisparmio {
            righe.append("Il piano chiede \(Formati.euro(p.chiedeIlPiano)) l’anno, \(nome) ne mette da parte \(Formati.euro(p.risparmioLibero)): nelle due vite contano \(Formati.euro(p.chiedeIlPiano)).")
        }
        righe.append("Stesso risparmio nelle due vite; senza piano il risparmio resta sul conto. Euro nominali. " + avvertenza.testo)
        return VStack(alignment: .leading, spacing: L.spazioPiede / 2) {
            ForEach(righe, id: \.self) { r in
                Text(r)
                    .carattereApple(L.avvertenza)
                    .foregroundColor(L.coloreAvvertenza)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, L.spazioPiede)
    }

    private func frase(_ p: PartitaLanciaAnno) -> String {
        p.eventiACaso
            ? "Premi «Lancia l’anno»: ogni anno i mercati fanno la loro parte e può capitare un imprevisto, con le probabilità di Impostazioni › Sala."
            : "Premi «Lancia l’anno»: ogni anno i mercati fanno la loro parte; gli imprevisti li scegli tu con «Gioca una carta»."
    }

    // MARK: Lanci

    private func lancia(_ carta: EventoAnno?, animato: Bool) {
        guard case .success(var p) = esito, !p.finita else { return }
        MotoreLanciaAnno.lancia(&p, cartaAMano: carta)
        if animato && !calmo && !istantanea {
            withAnimation(M.dado) { giroDado += 360 }
            withAnimation(M.carta) { esito = .success(p) }
        } else {
            withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : nil) { esito = .success(p) }
        }
    }

    private func dieci() {
        guard corsa == nil else { return }
        if calmo {
            for _ in 0..<10 { lancia(nil, animato: false) }
            return
        }
        corsa = Task { @MainActor in
            for _ in 0..<10 {
                try? await Task.sleep(nanoseconds: UInt64(M.intervalloDieci * 1_000_000_000))
                guard !Task.isCancelled else { break }
                guard case .success(let p) = esito, !p.finita else { break }
                lancia(nil, animato: true)
            }
            corsa = nil
        }
    }

    private func nuova() {
        corsa?.cancel()
        corsa = nil
        numero += 1
        let nuovo = stato.partitaLanciaAnno(cliente, numero: numero)
        withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : .easeOut(duration: Tema.Apple.Studio.Moto.durataRimonta)) { esito = nuovo }
    }

    // MARK: Senza dati

    private func mancano(nome: String) -> some View {
        VStack(spacing: L.spazioPiede) {
            TasselloGlifo(glifo: .dadi, lato: Tema.Apple.Tassello.latoSalaGrande, raggio: Tema.Apple.Raggio.voce)
            Text("Per giocare servono il patrimonio e quanto \(nome) mette da parte ogni anno.")
                .carattereApple(Tema.Apple.SalaEsperienze.Palco.titoloInArrivo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if modificabile {
                Button("Completa il profilo ›") { stato.apriCliente(cliente.id) }
                    .buttonStyle(.apple)
            }
        }
        .frame(maxWidth: L.larghezzaStato)
        .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
    }
}

/// La carta nuova: scende da −40 ruotata di −2° e grande 1,05, poi si ferma.
private struct EntrataCarta: ViewModifier {
    let fatto: Double
    private typealias M = Tema.Apple.Moto.SalaEsperienze.Lancia
    func body(content: Content) -> some View {
        content
            .offset(y: M.spostamentoCarta * (1 - fatto))
            .rotationEffect(.degrees(M.rotazioneCarta * (1 - fatto)))
            .scaleEffect(1 + (M.scalaCarta - 1) * (1 - fatto))
            .opacity(fatto)
    }
}

/// Una carta dell'anno: il filo del tono, il titolo, gli effetti con e senza il piano (o il mercato).
private struct CartaAnno: View {
    let anno: AnnoLanciato
    let nome: String

    private typealias L = Tema.Apple.SalaEsperienze.Lancia

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(L.tono(anno.tono))
                .frame(width: L.filoCarta)
            VStack(alignment: .leading, spacing: L.sopraEffetti) {
                HStack(spacing: L.spazioPulsanti) {
                    Text(anno.titolo)
                        .carattereApple(L.titoloCarta)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .lineLimit(1)
                    if anno.aMano {
                        Text("a mano")
                            .carattereApple(L.prova)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    }
                    if anno.diProva {
                        Text("dati di prova")
                            .carattereApple(L.prova)
                            .foregroundColor(L.coloreProva)
                    }
                    if let c = anno.copertura {
                        EtichettaCanaleApple(canale: c.canale, compatta: true)
                    }
                }
                if anno.soloMercato {
                    Text(anno.effettoCon.frase)
                        .carattereApple(L.effetti)
                        .foregroundColor(L.coloreEffettoSenza)
                } else if anno.effettoCon == anno.effettoSenza {
                    Text(anno.effettoCon.frase)
                        .carattereApple(L.effetti)
                        .foregroundColor(L.coloreEffettoSenza)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: L.spazioEffetti) {
                        Text("Con il piano: \(anno.effettoCon.frase)")
                            .carattereApple(L.effettoCon)
                            .foregroundColor(L.coloreEffettoCon)
                        Text("Senza: \(anno.effettoSenza.frase)")
                            .carattereApple(L.effetti)
                            .foregroundColor(L.coloreEffettoSenza)
                    }
                    .lineLimit(2)
                }
            }
            .padding(L.paddingCarta)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(L.fondoCarta)
        .clipShape(RoundedRectangle(cornerRadius: L.raggioCarta, style: .continuous))
        .ombraApple(.card)
        .accessibilityElement(children: .combine)
    }
}
