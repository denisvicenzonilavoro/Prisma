import SwiftUI
import Observation

// La Vera della scrivania: sulla scrivania libera, due dita da destra a sinistra sul trackpad (o un trascinamento
// col mouse) fanno scorrere via i widget e aprono Vera. L'acqua resta viva dietro, il dock resta.
// Vera parte piccola al centro (la sfera, un saluto, gli spunti, il campo) e con domande e risposte si allarga
// in una conversazione. La conversazione è la stessa dell'app Vera (stessa chiave, stessa logica di StatoShell).
// Il gesto del trackpad e Esc sono in GestoVeraScrivania.swift (solo Mac); i gettoni in DesignSystem/TemaVeraScrivania.swift.

/// Il gesto in corso tra le due pagine: lo osservano solo le pagine, così seguire il dito non ridisegna la shell.
@Observable final class GestoPaginaVera {
    /// Quanto si è spostata la pagina dall'inizio del gesto, in pagine (+ verso Vera).
    var spostamento: CGFloat = 0
    /// Un gesto orizzontale è stato preso (trackpad o mouse).
    @ObservationIgnored var attivo = false
    /// La pagina da cui è partito.
    @ObservationIgnored var partenza: CGFloat = 0

    /// Segue il dito: `dito` è lo spostamento orizzontale dall'inizio (negativo = verso sinistra, verso Vera).
    /// Oltre le due pagine il movimento rallenta, come gli scorrimenti del Mac.
    func segui(dito: CGFloat, larghezza: CGFloat) {
        let w = max(larghezza, 1)
        let posizione = Movimenti.elastico(partenza * w - dito, minimo: 0, massimo: w)
        let nuovo = posizione / w - partenza
        guard abs(nuovo - spostamento) > 0.0005 else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { spostamento = nuovo }
    }
}

extension StatoShell {
    /// La scrivania è libera: nessuna finestra davanti, niente blocco, pannelli, ricerca, guida o presentazione.
    /// Solo così il gesto apre o chiude Vera.
    var scrivaniaPerVera: Bool {
        !bloccato && finestreVisibili.isEmpty && presentazione == nil && !pannelloRicerca && !pannelloSpazi
            && !pannelloNotifiche && !sistema.pannelloNovita && !pannelloAppAperte && sistema.guida == nil && appConsentita(.vera)
    }

    /// Vera è aperta sulla scrivania (o lo sarà a movimento finito).
    var veraScrivaniaAperta: Bool { sistema.paginaVera >= Tema.Moto.VeraScrivania.sogliaPagina }

    /// Apre Vera sulla scrivania. `velocita`: quella del gesto, in percorsi al secondo.
    func mostraVeraScrivania(velocita: Double = 0) {
        guard !bloccato, appConsentita(.vera) else { return vaiAPaginaVera(sistema.paginaVera.rounded(), velocita: 0) }
        vaiAPaginaVera(1, velocita: velocita)
        verificaMotoreLocale()
    }

    /// Torna ai widget. `animato == false`: di colpo (sotto la schermata di blocco).
    func nascondiVeraScrivania(velocita: Double = 0, animato: Bool = true) {
        vaiAPaginaVera(0, velocita: velocita, animato: animato)
    }

    func alternaVeraScrivania() {
        if veraScrivaniaAperta { nascondiVeraScrivania() } else { mostraVeraScrivania() }
    }

    /// Fine del gesto: oltre metà corsa o con un colpo veloce cambia pagina, altrimenti torna dov'era.
    /// `velocita`: in pagine al secondo, + verso Vera.
    func concludiGestoVera(velocita v: CGFloat, annullato: Bool = false) {
        let g = sistema.gestoVera
        guard g.attivo else { return }
        let posizione = g.partenza + g.spostamento
        var meta: CGFloat = posizione >= Tema.Moto.VeraScrivania.sogliaPagina ? 1 : 0
        if abs(v) >= Tema.Moto.VeraScrivania.velocitaColpo { meta = v > 0 ? 1 : 0 }
        if annullato || !scrivaniaPerVera { meta = g.partenza.rounded() }
        let distanza = meta - posizione
        let limite = Tema.Moto.Sblocco.velocitaMassima
        let molla = abs(distanza) > 0.01 ? Double(min(max(v / distanza, -limite), limite)) : 0
        if meta >= 1 { mostraVeraScrivania(velocita: molla) } else { nascondiVeraScrivania(velocita: molla) }
    }

    /// Porta la pagina (0 o 1) con la molla: il gesto si azzera nella stessa transazione, così la pagina
    /// riparte da dove l'ha lasciata il dito.
    private func vaiAPaginaVera(_ pagina: CGFloat, velocita: Double, animato: Bool = true) {
        let g = sistema.gestoVera
        g.attivo = false
        guard sistema.paginaVera != pagina || g.spostamento != 0 else { return }
        Movimenti.anima(Tema.Moto.VeraScrivania.pagina(velocita: velocita), durata: Tema.Moto.VeraScrivania.durataPagina,
                        animato: animato && persistente) {
            sistema.paginaVera = pagina
            g.spostamento = 0
        }
    }
}

// MARK: - Le due pagine

/// La scrivania con i widget e, a destra, Vera. Sta dove prima c'era solo `Scrivania()` (ShellView.livelliScrivania).
struct PagineScrivania: View {
    @Environment(StatoShell.self) var stato
    let sistema: StatoFinestre
    let gesto: GestoPaginaVera
    let misura: CGSize
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea
    /// Vera resta montata finché la pagina torna del tutto ai widget (poi si smonta: memoria).
    @State private var veraMontata = false

    init(sistema: StatoFinestre, gesto: GestoPaginaVera, misura: CGSize) {
        self.sistema = sistema
        self.gesto = gesto
        self.misura = misura
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let m = Tema.Misura.VeraScrivania.self
        let p = sistema.paginaVera + gesto.spostamento
        let visibile = min(max(p, 0), 1)
        let w = misura.width
        let altezza = max(0, misura.height - Misure.Barra.altezza - Misure.Dock.riservato)
        let nascosti = sistema.bloccato || sistema.scrivaniaNascosta
        let calmo = movimentoRidotto
        ZStack(alignment: .topLeading) {
            // Lo sfondo va in trasparenza: un velo leggero, l'acqua sotto continua a muoversi
            Tema.Colore.VeraScrivania.velo
                .opacity(nascosti ? 0 : Double(visibile))
                .frame(width: w, height: misura.height)
                .allowsHitTesting(false)

            Scrivania()
                .frame(width: w, height: altezza)
                .offset(x: calmo ? 0 : -p * w * m.corsaScrivania, y: Misure.Barra.altezza)
                // Sotto una finestra ingrandita, a transizione finita, la scrivania non si disegna (resta montata)
                .opacity(nascosti ? 0 : Double(1 - visibile))
                .allowsHitTesting(!sistema.scrivaniaNascosta && p < Tema.Moto.VeraScrivania.sogliaPagina)
                .gesture(trascinamento(larghezza: w))

            if veraMontata || visibile > 0 {
                ZStack {
                    // Fuori dal pannello si trascina per tornare ai widget
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(trascinamento(larghezza: w))
                    VeraScrivania(attiva: sistema.paginaVera >= 1 && gesto.spostamento == 0)
                }
                .frame(width: w, height: altezza)
                .offset(x: calmo ? 0 : (1 - p) * w * m.corsaVera, y: Misure.Barra.altezza)
                .opacity(nascosti ? 0 : Double(visibile))
                .allowsHitTesting(p >= Tema.Moto.VeraScrivania.sogliaPagina && !sistema.scrivaniaNascosta)
            }

            if sistema.visibili.isEmpty && stato.appConsentita(.vera) {
                PuntiPagineVera(pagina: visibile) { stato.alternaVeraScrivania() }
                    .position(x: w / 2, y: Misure.Barra.altezza + altezza + m.puntiSottoScrivania)
                    .opacity(nascosti ? 0 : 1)
            }
        }
        .onAppear { if visibile > 0 { veraMontata = true } }
        .onChange(of: visibile > 0) { aperta in
            if aperta { veraMontata = true }
        }
        .onChange(of: sistema.paginaVera) { pagina in
            if pagina != 0 {
                veraMontata = true
                return
            }
            if modoIstantanea {
                veraMontata = false
                return
            }
            // A molla finita Vera si smonta, se nel frattempo non è ripartito un gesto
            Movimenti.dopo(Tema.Moto.VeraScrivania.durataPagina) {
                if sistema.paginaVera == 0 && gesto.spostamento == 0 { veraMontata = false }
            }
        }
    }

    /// Col mouse: un trascinamento orizzontale sulla scrivania (o fuori dal pannello di Vera) cambia pagina.
    private func trascinamento(larghezza w: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: Tema.Misura.VeraScrivania.distanzaTrascinamento,
                    coordinateSpace: .named(ShellView.spazioShell))
            .onChanged { v in
                let dx = v.translation.width
                if !gesto.attivo {
                    guard stato.scrivaniaPerVera, abs(dx) > abs(v.translation.height) * Tema.Misura.VeraScrivania.rapportoOrizzontale
                    else { return }
                    let partenza = sistema.paginaVera
                    // Verso Vera dalla scrivania, verso la scrivania da Vera
                    guard (dx < 0 && partenza < 0.5) || (dx > 0 && partenza >= 0.5) else { return }
                    gesto.partenza = partenza
                    gesto.attivo = true
                }
                gesto.segui(dito: dx, larghezza: w)
            }
            .onEnded { v in
                guard gesto.attivo else { return }
                // Velocità del dito dalla previsione del gesto (DragGesture.Value.velocity c'è solo da macOS 14)
                let dito = (v.predictedEndTranslation.width - v.translation.width) / Tema.Moto.Sblocco.orizzontePrevisione
                stato.concludiGestoVera(velocita: -dito / max(w, 1))
            }
    }
}

/// I due puntini delle pagine sopra il dock: la scrivania e Vera. Fanno scoprire il gesto; un clic cambia pagina.
struct PuntiPagineVera: View {
    /// 0 = widget, 1 = Vera (anche a metà, durante il gesto).
    let pagina: CGFloat
    let azione: () -> Void

    var body: some View {
        let m = Tema.Misura.VeraScrivania.self
        let c = Tema.Colore.VeraScrivania.self
        Button(action: azione) {
            HStack(spacing: m.spazioPunti) {
                punto(attivo: 1 - pagina)
                punto(attivo: pagina)
            }
            .padding(m.areaPunti)
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .help(pagina < 0.5 ? "Vera: scorri con due dita verso sinistra" : "Torna ai widget: scorri verso destra o premi Esc")
        .accessibilityLabel(pagina < 0.5 ? "Apri Vera sulla scrivania" : "Torna ai widget")
        .foregroundColor(c.puntoAttivo)
    }

    /// Un puntino che si allunga in capsula quando la sua pagina è davanti.
    private func punto(attivo a: CGFloat) -> some View {
        let m = Tema.Misura.VeraScrivania.self
        let c = Tema.Colore.VeraScrivania.self
        let quota = min(max(a, 0), 1)
        return Capsule()
            .fill(quota > 0.5 ? c.puntoAttivo : c.puntoSpento)
            .frame(width: m.punto + (m.puntoAttivo - m.punto) * quota, height: m.punto)
            .aloneSfondo()
    }
}

// MARK: - Il pannello di Vera

/// Vera sulla scrivania: vetro trasparente (l'acqua si vede e si muove dietro), piccola finché non si parla,
/// poi si allarga con la molla della mini Vera in una conversazione comoda. Solo testo (Qwen), niente microfono.
struct VeraScrivania: View {
    @Environment(StatoShell.self) var stato
    /// La pagina di Vera è davanti, ferma: il cursore va nel campo.
    let attiva: Bool
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea
    @FocusState private var campoAttivo: Bool

    init(attiva: Bool) {
        self.attiva = attiva
    }

    private var portafoglio: Bool { stato.veraPortafoglio }
    private var messaggi: [MessaggioVera] { stato.conversazione(stato.chiaveConversazione) }
    private var allargata: Bool { !messaggi.isEmpty || stato.veraInCorso }
    private var pronta: Bool { stato.qwen.disponibilita.pronto }

    private func invia(_ testo: String) {
        if portafoglio { stato.chiediVeraPortafoglio(testo) } else { stato.chiediVera(testo) }
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let m = Tema.Misura.VeraScrivania.self
        let grande = allargata
        let moto: Animation? = modoIstantanea ? nil : (movimentoRidotto ? Tema.Moto.dissolvenzaCalma : Tema.Moto.VeraScrivania.forma)
        return GeometryReader { geo in
            let larghezza = grande ? min(m.larghezzaAllargata, max(m.larghezzaPiccola, geo.size.width - 2 * m.margineLato))
                                   : m.larghezzaPiccola
            let altezza = max(0, geo.size.height - 2 * m.margineVerticale)
            let forma = FormaVetro.arrotondata(Tema.Raggio.VeraScrivania.pannello)
            Group {
                if grande {
                    conversazione
                        .frame(height: altezza)
                } else {
                    benvenuto
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(m.margineInterno)
            .frame(width: larghezza)
            .clipShape(forma)
            .vetro(.pannello, forma: forma)
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(moto, value: grande)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Vera")
        .onAppear { if attiva && !modoIstantanea { campoAttivo = true } }
        .onChange(of: attiva) { a in if !modoIstantanea { campoAttivo = a } }
    }

    // MARK: Piccola

    /// La sfera, un saluto, di chi si parla, gli spunti e il campo.
    private var benvenuto: some View {
        let m = Tema.Misura.VeraScrivania.self
        let c = Tema.Colore.VeraScrivania.self
        return VStack(spacing: m.spazio) {
            SferaVera(misura: m.sferaGrande, viva: true, pensa: stato.veraInCorso)
                .puntoAcqua(.sferaVera)
                .padding(.top, m.spazioPiccolo)
            VStack(spacing: m.spazioPiccolo) {
                Text("Ciao, sono Vera.")
                    .font(Tema.Testo.VeraScrivania.saluto)
                    .tracking(Tema.Testo.VeraScrivania.spaziaturaSaluto)
                    .foregroundColor(c.testo)
                Text(portafoglio ? "Chiedimi del portafoglio: ti mostro le cifre di Prisma."
                                 : "Chiedimi di \(stato.clienteAttivo?.nome ?? "un cliente"): ti mostro le cifre di Prisma.")
                    .font(Tema.Testo.VeraScrivania.sottotitolo)
                    .foregroundColor(c.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
            ambito
            if !pronta { motoreNonPronto }
            spunti(centrati: true)
            campo
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Allargata

    private var conversazione: some View {
        let m = Tema.Misura.VeraScrivania.self
        return VStack(spacing: m.spazio) {
            testata
            messaggiVista
                .frame(maxHeight: .infinity)
            if !pronta { motoreNonPronto }
            spunti(centrati: false)
            campo
        }
    }

    /// In alto: la sfera piccola (si muove mentre Vera pensa), di chi si parla, nuova conversazione, «Apri in Vera».
    private var testata: some View {
        let m = Tema.Misura.VeraScrivania.self
        let c = Tema.Colore.VeraScrivania.self
        return HStack(spacing: m.spazio) {
            SferaVera(misura: m.sferaPiccola, viva: true, pensa: stato.veraInCorso)
                .puntoAcqua(.sferaVera)
            VStack(alignment: .leading, spacing: Tema.Misura.VeraChat.righeStrette) {
                Text("Vera")
                    .font(Tema.Testo.VeraScrivania.titolo)
                    .foregroundColor(c.testo)
                Text(stato.veraInCorso ? "Sto pensando…" : (pronta ? stato.qwen.nome : "\(stato.qwen.nome) · non pronto"))
                    .font(Tema.Testo.VeraScrivania.nota)
                    .foregroundColor(pronta ? c.testoSecondario : c.nonPronto)
                    .lineLimit(1)
            }
            Spacer(minLength: m.spazio)
            ambito
            PulsanteIcona(simbolo: "square.and.pencil", aiuto: "Nuova conversazione") { stato.nuovaConversazione() }
                .disabled(messaggi.isEmpty || stato.veraInCorso)
                .fixedSize()
            Button { stato.apri(.vera) } label: { Label("Apri in Vera", systemImage: "arrow.up.forward") }
                .buttonStyle(StileVetro())
                .fixedSize()
                .help("La stessa conversazione nell'app Vera")
        }
    }

    private var messaggiVista: some View {
        let m = Tema.Misura.VeraScrivania.self
        let elenco = messaggi
        // Il quadro visivo va sotto l'ultima risposta di Vera: le cifre le calcola Prisma
        let ultima = elenco.last.flatMap { $0.autore == .vera ? $0 : nil }
        let quadro = stato.veraInCorso ? nil : ultima.flatMap { stato.quadroVera(per: $0, in: elenco, portafoglio: portafoglio) }
        let domandaBiblioteca = stato.domandaPerBiblioteca(in: elenco)
        return ScrollViewReader { lettore in
            ScrollView {
                VStack(spacing: m.spazioMessaggi) {
                    ForEach(elenco) { msg in
                        // La scheda dei calcoli sta nella bolla dell'ultima risposta, come nell'app Vera
                        NuvolaVera(messaggio: msg, nomeUtente: stato.nomeUtente, azioniCliente: !portafoglio,
                                  creaAttivita: { stato.attivitaDaVera(msg) }, aggiungiNota: { stato.notaDaVera(msg) },
                                  attivitaProposta: { stato.attivitaDaProposta($0, messaggio: msg.id) },
                                  posizioneProposta: { stato.posizioneDaProposta($0, messaggio: msg.id) },
                                  apriAzione: { stato.apriAzioneVera($0) },
                                  annullaAzione: { stato.annullaAzioneVera($0, messaggio: msg.id) },
                                  quadro: msg.id == ultima?.id ? quadro : nil,
                                  domandaBiblioteca: msg.id == ultima?.id ? domandaBiblioteca : nil,
                                  cercaBiblioteca: { stato.cercaNellaBiblioteca($0) })
                            .id(msg.id)
                    }
                    if stato.veraInCorso {
                        NuvolaInArrivo(flusso: stato.flussoVera, portafoglio: portafoglio) {
                            withAnimation { lettore.scrollTo("pensa", anchor: .top) }
                        }
                        .id("pensa")
                    }
                }
                .padding(.vertical, m.spazioPiccolo)
            }
            .sfumaturaBordiScorrimento(sopra: m.sfumaturaMessaggi, sotto: m.sfumaturaMessaggi)
            .onAppear { if let u = elenco.last { lettore.scrollTo(u.id, anchor: u.autore == .utente ? .bottom : .top) } }
            .onChange(of: elenco.count) { _ in
                if let u = messaggi.last {
                    withAnimation { lettore.scrollTo(u.id, anchor: u.autore == .utente ? .bottom : .top) }
                }
            }
            .onChange(of: stato.veraInCorso) { pensa in
                if pensa { withAnimation { lettore.scrollTo("pensa", anchor: .bottom) } }
            }
        }
    }

    // MARK: Pezzi comuni

    /// Di chi si parla: un cliente o tutto il portafoglio (in modalità cliente solo il cliente).
    private var ambito: some View {
        var opzioni: [(String, String)] = []
        if !stato.inModoCliente { opzioni.append((VeraPortafoglio.chiave, "Tutto il portafoglio")) }
        opzioni += stato.clienti.map { c -> (String, String) in (c.id, c.nome) }
        let scelta = Binding<String>(
            get: { stato.veraPortafoglio ? VeraPortafoglio.chiave : stato.clienteAttivoId },
            set: { v in
                if v == VeraPortafoglio.chiave {
                    stato.veraPortafoglio = true
                } else {
                    if stato.veraPortafoglio { stato.veraPortafoglio = false }
                    if stato.clienteAttivoId != v { stato.clienteAttivoId = v }
                }
            })
        return MenuTendina(selezione: scelta, opzioni: opzioni, stile: .vetro, larghezza: Tema.Misura.VeraScrivania.larghezzaAmbito)
            .disabled(stato.veraInCorso)
            .help("Vera parla di un cliente o di tutto il tuo portafoglio")
    }

    /// Qwen non è pronto: Vera lo dice e non risponde (come nell'app Vera), con «Verifica».
    private var motoreNonPronto: some View {
        let m = Tema.Misura.VeraScrivania.self
        let c = Tema.Colore.VeraScrivania.self
        let q = stato.qwen
        return HStack(spacing: m.spazioPiccolo) {
            Circle().fill(c.nonPronto)
                .frame(width: Tema.Misura.VeraChat.spia, height: Tema.Misura.VeraChat.spia)
            Text("\(q.nome) · non pronto. \(q.disponibilita.motivo ?? q.descrizione)")
                .font(Tema.Testo.VeraScrivania.nota)
                .foregroundColor(c.testoSecondario)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button { stato.verificaMotoreLocale() } label: { Label("Verifica", systemImage: "arrow.clockwise") }
                .buttonStyle(StileVetro(margine: Tema.Misura.VeraChat.margineVerifica))
                .fixedSize()
                .help("Chiede di nuovo a Ollama se Qwen è pronto")
        }
    }

    /// Tre o quattro spunti in pillole, come nell'app Vera.
    private func spunti(centrati: Bool) -> some View {
        let m = Tema.Misura.VeraScrivania.self
        return DisposizioneAcapoRicerca(spazio: m.spazioPiccolo) {
            if portafoglio {
                ForEach(Array(Self.spuntiPortafoglio.enumerated()), id: \.offset) { _, voce in
                    Button { stato.chiediVeraPortafoglio(voce.0.domanda, spunto: voce.0) } label: { PillolaSpuntoVera(simbolo: voce.0.simbolo, testo: voce.1) }
                        .buttonStyle(StileSemplice())
                        .disabled(stato.veraInCorso)
                }
            } else {
                ForEach(Array(Self.spuntiCliente.enumerated()), id: \.offset) { _, voce in
                    Button { stato.chiediVera(voce.0.domanda, spunto: voce.0) } label: { PillolaSpuntoVera(simbolo: voce.0.simbolo, testo: voce.1) }
                        .buttonStyle(StileSemplice())
                        .disabled(stato.veraInCorso)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: centrati ? .center : .leading)
    }

    static let spuntiCliente: [(SpuntoVera, String)] = [
        (.riepilogo, "Riassumi il dossier"),
        (.scadenze, "Cosa scade?"),
        (.checkUp, "Check-up completo"),
        (.incontro, "Prepara l'incontro"),
    ]

    static let spuntiPortafoglio: [(SpuntoPortafoglio, String)] = [
        (.quadro, "Il quadro del portafoglio"),
        (.scadenze, "Cosa scade"),
        (.ricontattare, "Chi ricontattare"),
        (.settimana, "La settimana"),
    ]

    /// Il campo a capsula del tema Apple (`cardPiena`, ombra `card`) con il tasto d'invio tondo da 36
    /// (niente microfono: qui Vera scrive soltanto).
    private var campo: some View {
        let c = Tema.Apple.Vera.Campo.self
        return HStack(alignment: .bottom, spacing: c.spazio) {
            TextField(portafoglio ? "Chiedi del portafoglio…" : c.segnaposto,
                      text: Bindable(stato).domandaVera, axis: .vertical)
                .textFieldStyle(.plain)
                .carattereApple(c.testo)
                .foregroundColor(c.coloreTesto)
                .lineLimit(1...4)
                .focused($campoAttivo)
                .onSubmit { invia(stato.domandaVera) }
                .frame(maxWidth: .infinity, minHeight: c.tasto, alignment: .leading)
            Button { invia(stato.domandaVera) } label: { Image(systemName: "arrow.up") }
                .buttonStyle(StileTastoVera(aspetto: .invio))
                .disabled(stato.veraInCorso || stato.domandaVera.trimmingCharacters(in: .whitespaces).isEmpty)
                .help("Invia (↩)")
        }
        .padding(c.padding)
        .background {
            Capsule(style: .continuous)
                .fill(c.fondo)
                .ombraApple(c.ombra)
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(c.bordo, lineWidth: Tema.Apple.Misura.bordo)
                .allowsHitTesting(false)
        }
    }
}
