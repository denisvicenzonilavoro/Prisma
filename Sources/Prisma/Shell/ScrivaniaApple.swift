import SwiftUI

// I riquadri della scrivania del tema Apple (Design/template-apple-specifica.md §3.6).
//
//   Buonasera, Denis.                              [▶︎ La tua settimana] [Cerca ovunque]
//   ┌──────────────────────── La mossa del giorno ────────────────────────┐
//   ┌──── Agenda di oggi ────┐┌─ Portafoglio clienti ─┐┌──────── Vera ────────┐
//   ┌── Il tuo studio (Mac) ───┐┌──────── In scadenza entro 90 giorni ────────┐
//
// - Riquadri di vetro (raggio 26, padding 18×20): al passaggio salgono di 3 con la molla di 0,45 s; un clic
//   apre la loro app. Larghezze e altezze sono quote dello spazio che c'è (palco del template 1440×900).
// - Ingresso: gli 8 blocchi entrano a cascata allo sblocco (`.entrataSblocco`, base 0,12); i numeri contano da
//   0,30 s dopo lo sblocco (`.allaSblocco`, EventiShell.swift), gli anelli partono a 0,60 / 0,73 / 0,86 s.
//   Senza sblocco i numeri ci sono subito e gli anelli partono a 0,20 / 0,33 / 0,46 s.
// - «Riduci movimento» (\.prismaCalmo) e istantanee (\.modoIstantanea): tutto fermo nello stato finale,
//   niente sollevamenti né cascate.
// - Con una finestra aperta davanti la scrivania scende al 25% in 0,5 s e non prende i clic (§3.5): l'opacità è
//   blocco per blocco (`EntrataBloccoScrivania`), mai sull'insieme (un livello fuori schermo grande quanto la
//   scrivania, con tutte le ombre dentro). Sotto una finestra ingrandita, a transizione finita, non si disegna.
// - Prestazioni: un vetro per riquadro (mai annidato: dentro solo fondi pieni); il contenuto di ogni riquadro
//   è una sottovista `Equatable` che si rifà solo con una `ChiaveVista` nuova, come i widget di prima.
// - Tutte le cifre vengono dai motori di Prisma: mossa del giorno (MotoreMossaDelGiorno), riepilogo delle
//   posizioni, stato del lavoro (MotoreStatoDelLavoro), agenda, attività e scadenze.

/// La disposizione dei riquadri e il loro ingresso. Osserva le finestre, ma della scrivania contano solo due cose
/// (Prisma bloccata, una finestra davanti): le passa a `CorpoRiquadriScrivania`, che si rifà solo quando cambiano.
/// Aprire, spostare, ridurre o portare davanti una finestra pubblica StatoFinestre più volte (voli, coperture,
/// passaggi di cornice): la disposizione dei riquadri non si ricalcola per nessuna di queste.
struct RiquadriScrivania: View {
    @Environment(StatoFinestre.self) var sistema

    var body: some View {
        CorpoRiquadriScrivania(sistema: sistema, bloccato: sistema.bloccato, davanti: !sistema.visibili.isEmpty)
            .equatable()
    }

    /// true sull'iPad quando la scrivania è più stretta della soglia (in verticale); sul Mac mai.
    static func dueColonne(_ larghezza: CGFloat) -> Bool { CorpoRiquadriScrivania.dueColonne(larghezza) }
}

/// I riquadri e il loro ingresso, con i due valori delle finestre che contano (`RiquadriScrivania`). `sistema` non è
/// osservato: serve solo a rileggere il blocco dopo l'attesa dello sblocco.
private struct CorpoRiquadriScrivania: View, Equatable {
    let sistema: StatoFinestre
    let bloccato: Bool
    /// Una finestra aperta davanti alla scrivania.
    let davanti: Bool
    @Environment(\.modoIstantanea) private var modoIstantanea
    /// Le istantanee di iPhone e iPad (schermo vero, senza `modoIstantanea`): anche lì tutto già al suo posto.
    @Environment(\.istantaneaSchermo) private var istantaneaSchermo
    @Environment(\.prismaCalmo) private var calmo
    /// Vero poco dopo la prima comparsa: all'apertura di Prisma i blocchi entrano uno dopo l'altro.
    @State private var avviato = false
    /// La prima entrata (all'apertura di Prisma) ha i tempi dell'avvio; le altre quelli dello sblocco.
    @State private var primaEntrata = true
    /// Numeri e anelli montati: non sotto il blocco; allo sblocco ricompaiono dopo 0,30 s e contano da capo.
    @State private var contaPronta = false
    /// Numeri e anelli sono ripartiti da uno sblocco (gli anelli aspettano fino a 0,60 s).
    @State private var dopoSblocco = false

    nonisolated static func == (a: CorpoRiquadriScrivania, b: CorpoRiquadriScrivania) -> Bool {
        a.sistema === b.sistema && a.bloccato == b.bloccato && a.davanti == b.davanti
    }

    var body: some View {
        let d = Tema.Apple.Scrivania.Disposizione.self
        let pronto = istantanea || contaPronta
        let ritardoAnelli = dopoSblocco ? Tema.Apple.Scrivania.Moto.ritardoAnelliDopoSblocco : Tema.Apple.Scrivania.Moto.ritardoAnelli
        VStack(alignment: .leading, spacing: d.spazio) {
            TestataScrivania(nascosto: nascosto, base: base, sotto: davanti)
                .frame(minHeight: d.testata, alignment: .top)
            RiquadroMossa()
                .frame(height: d.mossa)
                .modifier(entrata(2))
            GeometryReader { geo in
                righe(geo.size, pronto: pronto, ritardoAnelli: ritardoAnelli)
            }
        }
        .padding(.top, d.alto)
        .padding(.bottom, d.basso)
        // Con una finestra davanti: senza clic (§3.5); il 25% è di ogni blocco (`entrata`)
        .allowsHitTesting(!davanti)
        .onAppear(perform: comparsa)
        .onChange(of: bloccato) { bloccato in
            guard bloccato else { return }
            // Sotto il blocco: alla prossima entrata numeri e anelli ripartono da capo
            primaEntrata = false
            guard !istantanea else { return }
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) { contaPronta = false }
        }
        .allaSblocco(sblocco)
    }

    /// Le righe sotto la mossa: sul Mac e sull'iPad largo le due del template; sull'iPad stretto (in verticale) tre
    /// righe a due colonne (`righeStrette`).
    @ViewBuilder private func righe(_ misura: CGSize, pronto: Bool, ritardoAnelli: Double) -> some View {
        if Self.dueColonne(misura.width) {
            righeStrette(misura, pronto: pronto, ritardoAnelli: ritardoAnelli)
        } else {
            righeLarghe(misura, pronto: pronto, ritardoAnelli: ritardoAnelli)
        }
    }

    /// true sull'iPad quando la scrivania è più stretta della soglia (in verticale); sul Mac mai.
    static func dueColonne(_ larghezza: CGFloat) -> Bool {
        #if os(iOS)
        return larghezza < Tema.Apple.Scrivania.iPad.sogliaDueColonne
        #else
        return false
        #endif
    }

    /// L'iPad in verticale, con gli stessi riquadri del Mac a due colonne:
    ///
    ///   ┌──── Agenda di oggi ────┐┌─ Portafoglio ─┐   300
    ///   ┌────────── Vera ─────────┐┌─ Da fare oggi ┐   270
    ///   ┌──────── In scadenza entro 90 giorni ──────┐  168
    private func righeStrette(_ misura: CGSize, pronto: Bool, ritardoAnelli: Double) -> some View {
        let d = Tema.Apple.Scrivania.Disposizione.self
        let p = Tema.Apple.Scrivania.iPad.self
        let s = d.spazio
        let disponibile = max(0, misura.height - 2 * s)
        let somma = d.rigaAlta + p.rigaMedia + d.rigaBassa
        let bassa = max(d.rigaBassaMinima, disponibile * d.rigaBassa / somma)
        let media = max(p.rigaMediaMinima, disponibile * p.rigaMedia / somma)
        let alta = max(d.rigaAltaMinima, disponibile - bassa - media)
        let alte = Self.larghezze(misura.width, quote: p.quoteRigaAlta, spazio: s)
        let medie = Self.larghezze(misura.width, quote: p.quoteRigaMedia, spazio: s)
        return VStack(alignment: .leading, spacing: s) {
            HStack(alignment: .top, spacing: s) {
                RiquadroAgendaOggi(pronto: pronto)
                    .frame(width: alte[0])
                    .modifier(entrata(3))
                RiquadroPortafoglioScrivania(pronto: pronto, ritardoAnelli: ritardoAnelli, altezza: alta)
                    .frame(width: alte[1])
                    .modifier(entrata(4))
            }
            .frame(height: alta)
            HStack(alignment: .top, spacing: s) {
                RiquadroVeraScrivania()
                    .frame(width: medie[0])
                    .modifier(entrata(5))
                RiquadroDaFare()
                    .frame(width: medie[1])
                    .modifier(entrata(6))
            }
            .frame(height: media)
            RiquadroScadenzeScrivania()
                .frame(height: bassa)
                .modifier(entrata(7))
        }
        .frame(width: misura.width, height: misura.height, alignment: .topLeading)
    }

    /// Le due righe sotto la mossa: alte in proporzione (300 / 168), larghe in proporzione (560/384/376 e 660/676).
    private func righeLarghe(_ misura: CGSize, pronto: Bool, ritardoAnelli: Double) -> some View {
        let d = Tema.Apple.Scrivania.Disposizione.self
        let s = d.spazio
        let disponibile = max(0, misura.height - s)
        let quotaAlta = d.rigaAlta / (d.rigaAlta + d.rigaBassa)
        let bassa = max(d.rigaBassaMinima, disponibile * (1 - quotaAlta))
        let alta = max(d.rigaAltaMinima, disponibile - bassa)
        let alte = Self.larghezze(misura.width, quote: d.quoteRigaAlta, spazio: s)
        let basse = Self.larghezze(misura.width, quote: d.quoteRigaBassa, spazio: s)
        return VStack(alignment: .leading, spacing: s) {
            HStack(alignment: .top, spacing: s) {
                RiquadroAgendaOggi(pronto: pronto)
                    .frame(width: alte[0])
                    .modifier(entrata(3))
                RiquadroPortafoglioScrivania(pronto: pronto, ritardoAnelli: ritardoAnelli, altezza: alta)
                    .frame(width: alte[1])
                    .modifier(entrata(4))
                RiquadroVeraScrivania()
                    .frame(width: alte[2])
                    .modifier(entrata(5))
            }
            // In alto: se un riquadro non ci stesse, crescerebbe verso il basso, mai sopra la mossa
            .frame(height: alta, alignment: .top)
            HStack(alignment: .top, spacing: s) {
                rigaBassaSinistra(pronto: pronto, ritardoAnelli: ritardoAnelli, altezza: bassa)
                    .frame(width: basse[0])
                    .modifier(entrata(6))
                RiquadroScadenzeScrivania()
                    .frame(width: basse[1])
                    .modifier(entrata(7))
            }
            .frame(height: bassa)
        }
        .frame(width: misura.width, height: misura.height, alignment: .topLeading)
    }

    /// In basso a sinistra: sul Mac «Il tuo studio» (versione «Orizzonte», StudioScrivania.swift) al posto di «Da fare
    /// oggi», le cui attività restano fra i «Prossimi incontri» e nell'Agenda; sull'iPad resta «Da fare oggi».
    private func rigaBassaSinistra(pronto: Bool, ritardoAnelli: Double, altezza: CGFloat) -> some View {
        #if os(macOS)
        return RiquadroStudioScrivania(pronto: pronto, ritardoAnelli: ritardoAnelli, altezza: altezza)
        #else
        return RiquadroDaFare()
        #endif
    }

    /// Le larghezze delle colonne di una riga, in proporzione alle quote del template.
    private static func larghezze(_ totale: CGFloat, quote: [CGFloat], spazio: CGFloat) -> [CGFloat] {
        let somma = quote.reduce(0, +)
        let libero = max(0, totale - spazio * CGFloat(max(quote.count - 1, 0)))
        return quote.map { somma > 0 ? libero * $0 / somma : 0 }
    }

    /// Istantanee (del Mac o dello schermo di iPhone e iPad): niente cascata, numeri e anelli subito completi.
    private var istantanea: Bool { modoIstantanea || istantaneaSchermo }

    /// Nascosti prima dell'avvio e con Prisma bloccata; nelle istantanee sempre al loro posto, fermi.
    private var nascosto: Bool { !istantanea && (bloccato || !avviato) }

    /// La base della cascata: quella dell'avvio alla prima entrata, quella dello sblocco poi.
    private var base: Double { primaEntrata ? Tema.Moto.Avvio.ritardo : Tema.Apple.Moto.Cascata.baseScrivania }

    /// L'entrata del blocco `indice` (0 saluto, 1 pulsanti, 2 mossa, 3-5 riga alta, 6-7 riga bassa), al 25% con
    /// una finestra aperta davanti.
    private func entrata(_ indice: Int) -> EntrataBloccoScrivania {
        EntrataBloccoScrivania(indice: indice, nascosto: nascosto, base: base, sotto: davanti)
    }

    private func comparsa() {
        guard !avviato else { return }
        // Nelle istantanee (e nella prova di fluidità) `istantanea` vale già da «avviato» e «pronto» (`nascosto`, `pronto`):
        // scriverli rifarebbe subito tutta la scrivania una seconda volta
        if istantanea { return }
        // Con la schermata di benvenuto davanti, la prima entrata è quella dello sblocco
        if bloccato {
            primaEntrata = false
        } else {
            contaPronta = true
        }
        // Il ritardo dell'avvio: il primo disegno della scrivania cade prima del primo fotogramma animato
        DispatchQueue.main.asyncAfter(deadline: .now() + Tema.Moto.Avvio.ritardo) { avviato = true }
    }

    /// Lo sblocco (EventiShell): numeri e anelli ricompaiono dopo 0,30 s e contano da capo (subito se calmo).
    private func sblocco() {
        guard !istantanea else { return }
        dopoSblocco = true
        let attesa = calmo ? 0 : Tema.Apple.Scrivania.Moto.ritardoNumeri
        DispatchQueue.main.asyncAfter(deadline: .now() + attesa) {
            if !sistema.bloccato { contaPronta = true }
        }
    }
}

/// L'entrata a cascata di un blocco allo sblocco (`.entrataSblocco`), come modificatore da passare in giro.
struct EntrataBloccoScrivania: ViewModifier {
    let indice: Int
    let nascosto: Bool
    let base: Double
    /// Una finestra aperta davanti: il blocco al 25%.
    var sotto = false

    func body(content: Content) -> some View {
        content.entrataSblocco(indice, nascosto: nascosto, base: base, sotto: sotto)
    }
}

// MARK: - Testata: saluto e pulsanti

private struct TestataScrivania: View {
    @Environment(StatoShell.self) var stato
    // Valori, non una closure: la testata si confronta e si rifà solo quando cambiano
    let nascosto: Bool
    let base: Double
    let sotto: Bool

    var body: some View {
        let _ = ContaCorpi.segna()
        let s = Tema.Apple.Scrivania.Saluto.self
        HStack(alignment: .top, spacing: Tema.Apple.Scrivania.Disposizione.spazio) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: s.spazio) {
                    TimelineView(.everyMinute) { contesto in
                        Text(saluto(contesto.date))
                            .carattereApple(s.titolo)
                            .foregroundColor(s.colore)
                            .lineLimit(1)
                            .minimumScaleFactor(s.riduzioneMinima)
                    }
                    Text("Tutto il tuo lavoro, a portata di mano.")
                        .carattereApple(s.sottotitolo)
                        .foregroundColor(s.coloreSottotitolo)
                        .lineLimit(1)
                }
                .aloneSfondo()
                // La guida per cominciare: un piccolo vetro sotto il saluto, finché non è finita
                if stato.guidaVisibile && !stato.inModoCliente {
                    GuidaCompatta()
                        .padding(.top, s.guidaAlto)
                }
            }
            .modifier(entrata(0))
            Spacer(minLength: 0)
            pulsanti
                .padding(.top, s.pulsantiAlto)
                .modifier(entrata(1))
        }
    }

    private func entrata(_ indice: Int) -> EntrataBloccoScrivania {
        EntrataBloccoScrivania(indice: indice, nascosto: nascosto, base: base, sotto: sotto)
    }

    private func saluto(_ adesso: Date) -> String {
        let s = Tema.Apple.Scrivania.Saluto.self
        let ora = Calendar.current.component(.hour, from: adesso)
        let parola = ora < s.oraPomeriggio ? "Buongiorno" : ora < s.oraSera ? "Buon pomeriggio" : "Buonasera"
        return "\(parola), \(stato.nomeUtente)."
    }

    /// «▶︎ La tua settimana» (con l'invito del lunedì, giro 5) e «⌕ Cerca ovunque» (versione «Luce», §1.2.1). «Nuovo cliente» è nella testata di Clienti;
    /// «☾ Stanotte» resta nascosto finché non c'è il lavoro della notte (giro 14, decisione 30).
    private var pulsanti: some View {
        HStack(spacing: Tema.Apple.Scrivania.Saluto.spazioPulsanti) {
            // Il lunedì, finché la storia della settimana non è vista: l'invito (giro 5, StoriaLuce.swift)
            if stato.invitoSettimana() {
                let i = Tema.Apple.Storia.Invito.self
                HStack(spacing: i.spazio) {
                    Circle().fill(i.colore).frame(width: i.pallino, height: i.pallino)
                    Text(TestiStorie.invito)
                        .carattereApple(i.testo)
                        .foregroundColor(i.coloreTesto)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)
            }
            Button {
                stato.apriStoria(.settimana)
            } label: {
                Label("La tua settimana", systemImage: "play.fill")
            }
            .disabled(stato.inModoCliente)
            .help("La tua settimana in trenta secondi: incontri, incassi, chi chiamare e i traguardi")
            Button {
                stato.cercaOvunque()
            } label: {
                Label("Cerca ovunque", systemImage: "magnifyingglass")
            }
            .help("Cerca clienti, posizioni, documenti e comandi (⌘K)")
        }
        .buttonStyle(.appleVetro)
        .fixedSize()
    }
}

// MARK: - Cornice comune dei riquadri

extension View {
    /// Il riquadro di vetro della scrivania (raggio 26, padding 18×20): al passaggio sale di 3 (solo sul Mac, mai
    /// con «Riduci movimento» né nelle istantanee); `apre` è ciò che fa un clic sul riquadro fuori dai pulsanti.
    func riquadroScrivania(apre: (() -> Void)? = nil) -> some View {
        modifier(RiquadroScrivaniaApple(apre: apre))
    }
}

private struct RiquadroScrivaniaApple: ViewModifier {
    let apre: (() -> Void)?
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var sopra = false

    func body(content: Content) -> some View {
        let r = Tema.Apple.Scrivania.Riquadro.self
        let forma = RoundedRectangle(cornerRadius: r.raggio, style: .continuous)
        let alzato = sopra && !fermo
        return content
            .padding(r.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .superficieApple(Tema.Apple.Superficie.vetro, raggio: r.raggio)
            .contentShape(forma)
            .onTapGesture { apre?() }
            .offset(y: alzato ? Tema.Apple.Scrivania.Moto.sollevamento : 0)
            .animation(fermo ? nil : Tema.Apple.Scrivania.Moto.sopra, value: alzato)
            .modifier(PassaggioRiquadro(sopra: $sopra))
            .modifier(PressioneRiquadro(raggio: r.raggio))
    }
}

/// Il tocco su iPhone e iPad (§2.3): niente passaggio né inclinazione, alla pressione il riquadro scende a 0,98
/// (la variante al tocco di `.inclinazione`). Sul Mac non fa niente: lì il riquadro sale al passaggio.
private struct PressioneRiquadro: ViewModifier {
    let raggio: CGFloat

    func body(content: Content) -> some View {
        #if os(iOS)
        content.inclinazione(raggio: raggio)
        #else
        content
        #endif
    }
}

/// Il passaggio del puntatore (solo Mac: su iPhone e iPad non c'è).
private struct PassaggioRiquadro: ViewModifier {
    @Binding var sopra: Bool

    func body(content: Content) -> some View {
        #if os(macOS)
        content.onHover { dentro in
            if sopra != dentro { sopra = dentro }
        }
        #else
        content
        #endif
    }
}

/// La testata di un riquadro: simbolo facoltativo, titolo 14 bold e un collegamento blu a destra.
private struct TestataRiquadro: View {
    let titolo: String
    var simbolo: String? = nil
    var collegamento: String? = nil
    var azione: (() -> Void)? = nil

    var body: some View {
        let r = Tema.Apple.Scrivania.Riquadro.self
        HStack(alignment: .firstTextBaseline, spacing: r.spazioSimbolo) {
            if let simbolo {
                Image(systemName: simbolo)
                    .carattereApple(r.titolo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
            }
            Text(titolo)
                .carattereApple(r.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let collegamento, let azione {
                Button(action: azione) {
                    Text(collegamento)
                        .carattereApple(r.collegamento)
                        .foregroundColor(r.coloreCollegamento)
                        .lineLimit(1)
                }
                .buttonStyle(StileSemplice())
            }
        }
    }
}

/// Un numero che si conta, o lo zero da cui partirà mentre aspetta lo sblocco.
struct CifraScrivania: View {
    let valore: Double
    let formato: FormatoCifra
    let indice: Int
    let pronto: Bool

    var body: some View {
        if pronto {
            NumeroCheConta(valore, formato: formato, indice: indice)
        } else {
            Text(formato.testo(0, finale: valore))
                .monospacedDigit()
        }
    }
}

// MARK: - La mossa del giorno

private struct RiquadroMossa: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoMossaScrivania(stato: stato, chiave: stato.chiaveVista)
            .equatable()
            .riquadroScrivania(apre: { apriPosizioni() })
    }

    /// Il riquadro porta in Posizioni: il dossier del cliente della mossa, o il portafoglio se non c'è una mossa.
    private func apriPosizioni() {
        if let m = stato.mossaDelGiorno().mossa {
            stato.clienteAttivoId = m.cliente.id
            stato.posizioneInDettaglio = nil
            stato.portafoglio = false
        } else {
            stato.portafoglio = true
        }
        stato.apri(.posizioni)
    }
}

private struct CorpoMossaScrivania: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista
    @State private var originePrepara = OrigineApertura()
    @State private var origineDossier = OrigineApertura()

    nonisolated static func == (a: CorpoMossaScrivania, b: CorpoMossaScrivania) -> Bool { a.chiave == b.chiave }

    var body: some View {
        let m = Tema.Apple.Scrivania.Mossa.self
        let esito = stato.mossaDelGiorno()
        return HStack(alignment: .center, spacing: m.spazio) {
            SferaMossaScrivania(iniziali: esito.mossa?.cliente.iniziali)
            testo(esito)
                .frame(maxWidth: .infinity, alignment: .leading)
            pulsanti(esito)
        }
        .padding(EdgeInsets(top: m.padding.top - Tema.Apple.Scrivania.Riquadro.padding.top,
                            leading: m.padding.leading - Tema.Apple.Scrivania.Riquadro.padding.leading,
                            bottom: m.padding.bottom - Tema.Apple.Scrivania.Riquadro.padding.bottom,
                            trailing: m.padding.trailing - Tema.Apple.Scrivania.Riquadro.padding.trailing))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func testo(_ esito: EsitoMossaDelGiorno) -> some View {
        let m = Tema.Apple.Scrivania.Mossa.self
        let titolo: String
        let frase: String
        switch esito {
        case .mossa(let mossa):
            titolo = mossa.titolo(oggi: Date())
            frase = mossa.motivo
        case .calma(let t, let f):
            titolo = t
            frase = f
        }
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: m.spazioCanale) {
                Text("La mossa del giorno")
                    .carattereApple(m.etichetta)
                    .foregroundColor(m.coloreEtichetta)
                    .lineLimit(1)
                // Il canale del motivo, sempre riconoscibile (nil: neutro, senza etichetta)
                if let c = esito.mossa?.canale {
                    EtichettaCanaleApple(canale: c, compatta: true)
                }
            }
            Text(titolo)
                .carattereApple(m.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .minimumScaleFactor(m.riduzioneTitolo)
                .padding(.top, m.titoloSopra)
                .padding(.bottom, m.titoloSotto)
            Text(frase)
                .carattereApple(m.corpo)
                .foregroundColor(m.coloreCorpo)
                .lineLimit(m.righeCorpo)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: m.larghezzaCorpo, alignment: .leading)
        }
    }

    @ViewBuilder private func pulsanti(_ esito: EsitoMossaDelGiorno) -> some View {
        let m = Tema.Apple.Scrivania.Mossa.self
        if let mossa = esito.mossa {
            VStack(alignment: .leading, spacing: m.spazioPulsanti) {
                // Compone il fascicolo dell'incontro con i report adatti (StatoMossaDelGiorno.preparaMossa)
                Button {
                    stato.preparaMossa(mossa)
                } label: {
                    Label("Preparami l'incontro", systemImage: m.simboloPrepara)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(StilePulsanteApple(.principale, grande: true))
                .misuraOrigine(originePrepara)
                .help(aiutoPrepara(mossa))
                Button {
                    stato.clienteAttivoId = mossa.cliente.id
                    stato.apri(.clienti, da: origineDossier.punto)
                } label: {
                    Text("Apri il dossier")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.apple)
                .misuraOrigine(origineDossier)
            }
            // I due pulsanti larghi uguali (quanto il più largo)
            .fixedSize(horizontal: true, vertical: false)
        } else {
            Button {
                stato.portafoglio = true
                stato.apri(.posizioni, da: origineDossier.punto)
            } label: {
                Text("Apri il portafoglio")
            }
            .buttonStyle(.apple)
            .misuraOrigine(origineDossier)
            .fixedSize()
        }
    }

    /// Cosa entra nel fascicolo (i report scelti dalla mossa, come il fascicolo dell'Agenda).
    private func aiutoPrepara(_ m: MossaDelGiorno) -> String {
        let nomi = m.reportOrdinati.map(\.nome)
        guard !nomi.isEmpty else { return "Prepara il fascicolo dell'incontro con \(m.cliente.nome)" }
        return "Il fascicolo dell'incontro con \(m.cliente.nome): " + nomi.joined(separator: ", ")
    }
}

/// La sfera della mossa: le iniziali del cliente sul gradiente radiale del template (centro a 34% · 28%).
/// Senza una mossa, una spunta: niente di urgente.
private struct SferaMossaScrivania: View {
    let iniziali: String?

    var body: some View {
        let m = Tema.Apple.Scrivania.Mossa.self
        let lato = m.sfera
        ZStack {
            Circle()
                .fill(RadialGradient(stops: Tema.Apple.Colore.fermateSferaMossa, center: Tema.Apple.Colore.centroSfera,
                                     startRadius: 0, endRadius: lato * m.estensioneGradiente))
                .ombraApple(.sfera)
            Group {
                if let iniziali {
                    Text(iniziali)
                        .carattereApple(m.iniziali)
                } else {
                    Image(systemName: m.simboloCalma)
                        .carattereApple(m.iniziali)
                }
            }
            .foregroundColor(m.coloreIniziali)
            .shadow(color: m.ombraIniziali, radius: m.raggioOmbraIniziali, x: 0, y: m.yOmbraIniziali)
        }
        .frame(width: lato, height: lato)
        .accessibilityHidden(true)
    }
}

// MARK: - Agenda di oggi

private struct RiquadroAgendaOggi: View {
    @Environment(StatoShell.self) var stato
    let pronto: Bool

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoAgendaOggi(stato: stato, chiave: stato.chiaveVista, pronto: pronto)
            .equatable()
            .riquadroScrivania(apre: { stato.apri(.agenda) })
    }
}

private struct CorpoAgendaOggi: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista
    let pronto: Bool

    nonisolated static func == (a: CorpoAgendaOggi, b: CorpoAgendaOggi) -> Bool {
        a.chiave == b.chiave && a.pronto == b.pronto
    }

    var body: some View {
        let a = Tema.Apple.Scrivania.Agenda.self
        HStack(alignment: .top, spacing: a.spazio) {
            TimelineView(.everyMinute) { contesto in
                giorno(contesto.date)
            }
            .frame(width: a.colonna)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Tema.Apple.Colore.separatore)
                    .frame(width: Tema.Apple.Misura.bordo)
            }
            incontri
        }
    }

    /// Il giorno grande: «Lunedì» in rosso, «2», «novembre»; in basso quanti impegni e il prossimo.
    private func giorno(_ adesso: Date) -> some View {
        let a = Tema.Apple.Scrivania.Agenda.self
        let quanti = stato.appuntamentiDiOggi.count
        let prossimo = stato.prossimiAppuntamenti.first { $0.inizio >= adesso }
        let mese = Formati.meseAnno.string(from: adesso).components(separatedBy: " ").first ?? ""
        return VStack(alignment: .leading, spacing: 0) {
            Text(Formati.giornoSettimana.string(from: adesso).capitalized)
                .carattereApple(a.giornoSettimana)
                .foregroundColor(a.coloreGiornoSettimana)
            Text(Formati.giorno.string(from: adesso))
                .carattereApple(a.giorno)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .minimumScaleFactor(a.riduzioneGiorno)
            Text(mese)
                .carattereApple(a.mese)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            Spacer(minLength: 0)
            riepilogo(quanti)
            Text(testoProssimo(prossimo))
                .carattereApple(a.prossimo)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.trailing, Tema.Apple.Scrivania.Riquadro.padding.trailing / 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private func riepilogo(_ quanti: Int) -> some View {
        let a = Tema.Apple.Scrivania.Agenda.self
        if quanti == 0 {
            Text("Nessun impegno oggi")
                .carattereApple(a.riepilogo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
        } else {
            HStack(spacing: 0) {
                CifraScrivania(valore: Double(quanti), formato: .intero, indice: 0, pronto: pronto)
                Text(quanti == 1 ? " impegno oggi" : " impegni oggi")
            }
            .carattereApple(a.riepilogo)
            .foregroundColor(Tema.Apple.Colore.inchiostro)
            .lineLimit(1)
        }
    }

    private func testoProssimo(_ p: Appuntamento?) -> String {
        guard let p else { return "niente in programma" }
        let ora = Formati.ora.string(from: p.inizio)
        if Calendar.current.isDateInToday(p.inizio) { return "il prossimo alle \(ora)" }
        return "il prossimo \(Formati.giornoRelativo(p.inizio)) alle \(ora)"
    }

    private var incontri: some View {
        let a = Tema.Apple.Scrivania.Agenda.self
        return VStack(alignment: .leading, spacing: 0) {
            TestataRiquadro(titolo: "Prossimi incontri", collegamento: "Apri Agenda") { stato.apri(.agenda) }
                .padding(.bottom, a.testataSotto)
            GeometryReader { geo in
                let entrano = max(0, min(a.righeMassime, Int((geo.size.height + a.spazioRighe) / a.altezzaRiga)))
                let eventi = Array(stato.prossimiAppuntamenti.prefix(entrano))
                VStack(alignment: .leading, spacing: a.spazioRighe) {
                    if eventi.isEmpty {
                        Text("Nessun appuntamento in programma.")
                            .carattereApple(Tema.Apple.Scrivania.Riquadro.vuoto)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    }
                    ForEach(eventi) { e in
                        RigaIncontroScrivania(evento: e, cliente: stato.cliente(e.clienteId)) {
                            if !e.clienteId.isEmpty { stato.clienteAttivoId = e.clienteId }
                            stato.mostraInAgenda(e)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Un incontro: barra di 3 nel colore del cliente, nome e titolo, giorno e ora · luogo a destra.
private struct RigaIncontroScrivania: View {
    let evento: Appuntamento
    let cliente: Cliente?
    let azione: () -> Void

    var body: some View {
        let a = Tema.Apple.Scrivania.Agenda.self
        Button(action: azione) {
            HStack(alignment: .top, spacing: a.spazio / 2) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(cliente?.nome ?? evento.titolo)
                        .carattereApple(a.nome)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    Text(cliente == nil ? evento.luogo : evento.titolo)
                        .carattereApple(a.dettaglio)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(Formati.giornoRelativo(evento.inizio))
                        .carattereApple(a.nome)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    Text(dove)
                        .carattereApple(a.dettaglio)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                }
            }
            .lineLimit(1)
            .padding(a.paddingRiga)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(cliente?.tinta.colori.basso ?? Tema.Apple.Colore.accento)
                    .frame(width: a.barra)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
    }

    private var dove: String {
        let ora = Formati.ora.string(from: evento.inizio)
        return evento.luogo.isEmpty ? ora : "\(ora) · \(evento.luogo)"
    }
}

// MARK: - Portafoglio clienti

private struct RiquadroPortafoglioScrivania: View {
    @Environment(StatoShell.self) var stato
    let pronto: Bool
    let ritardoAnelli: Double
    /// L'altezza della riga: sugli schermi bassi gli anelli si rimpiccioliscono per restare nel riquadro.
    let altezza: CGFloat

    var body: some View {
        let _ = ContaCorpi.segna()
        let p = Tema.Apple.Scrivania.Portafoglio.self
        let lato = min(p.anelli, max(p.anelliMinimi, altezza - p.altezzaSenzaAnelli))
        CorpoPortafoglioScrivania(stato: stato, chiave: stato.chiaveVista, pronto: pronto, ritardoAnelli: ritardoAnelli,
                                  latoAnelli: lato)
            .equatable()
            .riquadroScrivania(apre: { apriPortafoglio() })
    }

    private func apriPortafoglio() {
        stato.posizioneInDettaglio = nil
        stato.portafoglio = true
        stato.apri(.posizioni)
    }
}

private struct CorpoPortafoglioScrivania: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista
    let pronto: Bool
    let ritardoAnelli: Double
    let latoAnelli: CGFloat

    nonisolated static func == (a: CorpoPortafoglioScrivania, b: CorpoPortafoglioScrivania) -> Bool {
        a.chiave == b.chiave && a.pronto == b.pronto && a.ritardoAnelli == b.ritardoAnelli && a.latoAnelli == b.latoAnelli
    }

    var body: some View {
        let p = Tema.Apple.Scrivania.Portafoglio.self
        let r = stato.riepilogoTuttePosizioni
        let lavoro = stato.statoDelLavoro()
        let clienti = stato.clienti.count
        return VStack(alignment: .leading, spacing: 0) {
            TestataRiquadro(titolo: "Portafoglio clienti", collegamento: "Apri") {
                stato.posizioneInDettaglio = nil
                stato.portafoglio = true
                stato.apri(.posizioni)
            }
            CifraScrivania(valore: r.attivita, formato: .euro, indice: 1, pronto: pronto)
                .carattereApple(p.totale)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .minimumScaleFactor(p.riduzioneTotale)
                .padding(.top, p.totaleSopra)
            Text("in essere · \(clienti) \(clienti == 1 ? "cliente seguito" : "clienti seguiti")")
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .lineLimit(1)
            HStack(alignment: .center, spacing: p.spazioAnelli) {
                anelli(lavoro)
                legenda(lavoro)
            }
            .padding(.top, p.anelliSopra)
            Spacer(minLength: 0)
            if r.attivita > 0 {
                canali(r)
            }
        }
    }

    @ViewBuilder private func anelli(_ l: StatoDelLavoro) -> some View {
        let p = Tema.Apple.Scrivania.Portafoglio.self
        // Lo spessore resta in proporzione (12 su 118)
        let spessore = p.spessoreAnelli * latoAnelli / p.anelli
        if pronto {
            AnelliConcentrici(voci: Self.voci(l), misura: latoAnelli, spessore: spessore, ritardo: ritardoAnelli)
        } else {
            Color.clear.frame(width: latoAnelli, height: latoAnelli)
        }
    }

    /// Dall'esterno: in regola (verde), riesami dell'anno (blu), proposte concluse (viola).
    private static func voci(_ l: StatoDelLavoro) -> [VoceAnello] {
        let p = Tema.Apple.Scrivania.Portafoglio.self
        return [
            VoceAnello(id: "inRegola", valore: Double(l.inRegola.fatti), massimo: Double(l.inRegola.totale), colore: p.coloreInRegola),
            VoceAnello(id: "riesami", valore: Double(l.riesami.fatti), massimo: Double(l.riesami.totale), colore: p.coloreRiesami),
            VoceAnello(id: "proposte", valore: Double(l.proposte.fatti), massimo: Double(l.proposte.totale), colore: p.coloreProposte),
        ]
    }

    private func legenda(_ l: StatoDelLavoro) -> some View {
        let p = Tema.Apple.Scrivania.Portafoglio.self
        return VStack(alignment: .leading, spacing: p.spazioLegenda) {
            voce("In regola", l.inRegola, colore: p.coloreInRegola,
                 aiuto: "Clienti senza scadenze di conformità da sistemare")
            voce("Riesami", l.riesami, colore: p.coloreRiesami,
                 aiuto: "Clienti con posizioni in essere visti negli ultimi 12 mesi")
            voce("Proposte", l.proposte, colore: p.coloreProposte,
                 aiuto: "Proposte presentate concluse, accettate o rifiutate")
        }
        .fixedSize()
    }

    private func voce(_ nome: String, _ c: StatoDelLavoro.Conteggio, colore: Color, aiuto: String) -> some View {
        let p = Tema.Apple.Scrivania.Portafoglio.self
        let prima = Text(nome + " ").font(p.legenda.font)
        let fatti = Text("\(c.fatti)").font(p.legendaForte.font)
        let totale = Text("/\(c.totale)").font(p.legenda.font)
        let testo = prima + fatti + totale
        return HStack(spacing: p.spazioPallino) {
            Circle()
                .fill(colore)
                .frame(width: p.pallino, height: p.pallino)
            testo
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
        }
        .help(aiuto)
    }

    /// I due canali, sempre distinti: pallino del canale e quota del valore in essere.
    private func canali(_ r: RiepilogoPosizioni) -> some View {
        let p = Tema.Apple.Scrivania.Portafoglio.self
        return HStack(spacing: p.spazioCanali) {
            ForEach(Canale.allCases) { c in
                HStack(spacing: p.spazioPallino) {
                    Circle()
                        .fill(c == .alleanza ? Tema.Apple.Colore.canaleAlleanza : Tema.Apple.Colore.canaleIndipendente)
                        .frame(width: p.pallinoCanale, height: p.pallinoCanale)
                    Text("\(c.nomeBreve) \(Formati.percentuale((r.quota(c) * 100).rounded()))")
                        .carattereApple(p.canali)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        .lineLimit(1)
                }
                .help("\(c.nomeBreve): \(Formati.euro(r.perCanale[c] ?? 0))")
            }
        }
    }
}

// MARK: - Vera

private struct RiquadroVeraScrivania: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        // Le finestre stanno in `StatoFinestre`, che StatoShell non inoltra: le osserva SferaScrivaniaScoperta
        SferaScrivaniaScoperta(sistema: stato.sistema) { scoperta in corpo(viva: scoperta) }
    }

    private func corpo(viva: Bool) -> some View {
        CorpoVeraScrivaniaApple(stato: stato, chiave: stato.chiaveVista, pronta: stato.qwen.disponibilita.pronto,
                               nomeMotore: stato.qwen.nome, inCorso: stato.veraInCorso,
                               consentita: stato.appConsentita(.vera),
                               // La sfera respira solo con la scrivania scoperta: sotto le finestre resta ferma
                               viva: viva)
            .equatable()
            .riquadroScrivania(apre: {
                guard stato.appConsentita(.vera) else { return }
                #if os(iOS)
                // Sull'iPad Vera non ha la pagina a destra della scrivania: si apre la sua app
                stato.apri(.vera)
                #else
                stato.mostraVeraScrivania()
                #endif
            })
    }
}

/// Ridisegna il riquadro di Vera quando la scrivania si copre o si scopre (le finestre aperte o ridotte).
private struct SferaScrivaniaScoperta<C: View>: View {
    let sistema: StatoFinestre
    let contenuto: (Bool) -> C

    var body: some View {
        contenuto(sistema.visibili.isEmpty)
    }
}

private struct CorpoVeraScrivaniaApple: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista
    let pronta: Bool
    let nomeMotore: String
    let inCorso: Bool
    let consentita: Bool
    let viva: Bool

    nonisolated static func == (a: CorpoVeraScrivaniaApple, b: CorpoVeraScrivaniaApple) -> Bool {
        a.chiave == b.chiave && a.pronta == b.pronta && a.nomeMotore == b.nomeMotore && a.inCorso == b.inCorso
            && a.consentita == b.consentita && a.viva == b.viva
    }

    var body: some View {
        let e = Tema.Apple.Scrivania.Vera.self
        let suggerimenti = stato.suggerimentiVeraScrivania()
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: e.spazioTesta) {
                SferaVera(misura: e.sfera, viva: viva, pensa: inCorso)
                    // Mentre Vera risponde l'acqua vibra intorno a questa sfera (OsservatoreAcqua)
                    .puntoAcqua(.sferaVera)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Vera")
                        .carattereApple(e.nome)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    Text(pronta ? "\(nomeMotore) · pronto" : "\(nomeMotore) · non pronto")
                        .carattereApple(e.stato)
                        .foregroundColor(pronta ? Tema.Apple.Colore.inchiostro2 : e.coloreNonPronto)
                        .lineLimit(1)
                }
            }
            // Sugli schermi bassi la frase cede righe alle domande (niente altezza fissa: resta nel riquadro)
            Text(suggerimenti.frase)
                .carattereApple(e.frase)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(e.righeFrase)
                .padding(.top, e.fraseSopra)
                .padding(.bottom, e.fraseSotto)
                // La frase cede lo spazio per prima: le domande prendono quello che serve
                .layoutPriority(-1)
            if consentita {
                // Sugli schermi bassi restano le domande che stanno nel riquadro (3, poi 2, poi 1): mai fuori dal vetro
                ViewThatFits(in: .vertical) {
                    domande(suggerimenti.domande)
                    domande(Array(suggerimenti.domande.prefix(2)))
                    domande(Array(suggerimenti.domande.prefix(1)))
                }
            }
        }
    }

    private func domande(_ elenco: [DomandaScrivania]) -> some View {
        DisposizioneAcapoRicerca(spazio: Tema.Apple.Scrivania.Vera.spazioSuggerimenti) {
            ForEach(elenco) { d in
                SuggerimentoVeraScrivania(testo: d.testo) { stato.chiediDallaScrivania(d) }
                    .disabled(inCorso)
            }
        }
    }
}

/// Una domanda suggerita: capsula `card` col filo, 13 medium; al passaggio sale di 2.
private struct SuggerimentoVeraScrivania: View {
    let testo: String
    let azione: () -> Void
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var sopra = false

    var body: some View {
        let e = Tema.Apple.Scrivania.Vera.self
        let alzato = sopra && !fermo
        Button(action: azione) {
            Text(testo)
                .carattereApple(e.suggerimento)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .padding(e.paddingSuggerimento)
                .background {
                    Capsule(style: .continuous)
                        .fill(e.fondoSuggerimento)
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(e.bordoSuggerimento, lineWidth: Tema.Apple.Misura.bordo)
                        }
                }
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(StileSemplice())
        .offset(y: alzato ? Tema.Apple.Scrivania.Moto.sollevamentoSuggerimento : 0)
        .animation(fermo ? nil : Tema.Apple.Scrivania.Moto.sopraSuggerimento, value: alzato)
        .modifier(PassaggioRiquadro(sopra: $sopra))
        .help("Apre Vera sulla scrivania e le chiede: \(testo)")
    }
}

// MARK: - Da fare oggi

private struct RiquadroDaFare: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoDaFareScrivania(stato: stato, chiave: stato.chiaveVista)
            .equatable()
            .riquadroScrivania(apre: { apriAttivita() })
    }

    /// Sul Mac le attività stanno nell'Agenda (vista mese); su iPhone e iPad sono un'app a sé.
    private func apriAttivita() {
        #if os(macOS)
        stato.selezionaAttivitaInAgenda(nil)
        stato.apri(.agenda)
        #else
        stato.apri(.attivita)
        #endif
    }
}

private struct CorpoDaFareScrivania: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista

    nonisolated static func == (a: CorpoDaFareScrivania, b: CorpoDaFareScrivania) -> Bool { a.chiave == b.chiave }

    var body: some View {
        let f = Tema.Apple.Scrivania.DaFare.self
        let aperte = stato.attivitaAperte
        let cal = Calendar.current
        let domani = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
        // Oggi e le rimaste indietro; se non ce ne sono, le prossime
        let oggi = aperte.filter { $0.scadenza < domani }
        let elenco = oggi.isEmpty ? aperte : oggi
        return VStack(alignment: .leading, spacing: 0) {
            TestataRiquadro(titolo: oggi.isEmpty ? "Da fare" : "Da fare oggi", simbolo: f.simbolo)
            GeometryReader { geo in
                // Almeno una riga anche sugli schermi più bassi
                let entrano = max(1, min(f.righeMassime, Int(geo.size.height / f.altezzaRiga)))
                VStack(alignment: .leading, spacing: 0) {
                    if elenco.isEmpty {
                        Text("Niente da fare: tutto in ordine.")
                            .carattereApple(Tema.Apple.Scrivania.Riquadro.vuoto)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    }
                    ForEach(Array(elenco.prefix(entrano))) { a in
                        RigaDaFareScrivania(attivita: a, cliente: stato.cliente(a.clienteId), scaduta: a.scadenza < cal.startOfDay(for: Date())) {
                            stato.alternaCompletata(a.id)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
            .padding(.top, f.elencoSopra)
        }
    }
}

/// «○ Preparare il riepilogo per l'incontro · Giulia Rossi»: il cerchio segna l'attività come fatta.
private struct RigaDaFareScrivania: View {
    let attivita: Attivita
    let cliente: Cliente?
    let scaduta: Bool
    let completa: () -> Void

    var body: some View {
        let f = Tema.Apple.Scrivania.DaFare.self
        HStack(spacing: f.spazioCerchio) {
            Button(action: completa) {
                Circle()
                    .strokeBorder(Tema.Apple.Colore.inchiostro, lineWidth: f.trattoCerchio)
                    .frame(width: f.cerchio, height: f.cerchio)
                    .contentShape(Rectangle())
            }
            .buttonStyle(StileSemplice())
            .help("Segna come fatta")
            testo
                .lineLimit(1)
        }
        .frame(height: f.altezzaRiga, alignment: .leading)
    }

    private var testo: Text {
        let f = Tema.Apple.Scrivania.DaFare.self
        var t = Text(attivita.titolo).font(f.voce.font).foregroundColor(Tema.Apple.Colore.inchiostro)
        if let c = cliente {
            t = t + Text(" · \(c.nome)").font(f.voce.font).foregroundColor(f.coloreCliente)
        }
        if scaduta {
            t = t + Text(" · scaduta").font(f.voce.font).foregroundColor(f.coloreScaduta)
        }
        return t
    }
}

// MARK: - In scadenza entro 90 giorni

private struct RiquadroScadenzeScrivania: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoScadenzeScrivania(stato: stato, chiave: stato.chiaveVista)
            .equatable()
            .riquadroScrivania(apre: {
                stato.posizioneInDettaglio = nil
                stato.portafoglio = true
                stato.apri(.posizioni)
            })
    }
}

private struct CorpoScadenzeScrivania: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista

    nonisolated static func == (a: CorpoScadenzeScrivania, b: CorpoScadenzeScrivania) -> Bool { a.chiave == b.chiave }

    var body: some View {
        let s = Tema.Apple.Scrivania.Scadenze.self
        let scadenze = stato.riepilogoTuttePosizioni.inScadenza
        return VStack(alignment: .leading, spacing: 0) {
            TestataRiquadro(titolo: "In scadenza entro \(RiepilogoPosizioni.giorniScadenza) giorni", simbolo: s.simbolo)
            GeometryReader { geo in
                // Almeno una riga anche sugli schermi più bassi
                let entrano = max(1, min(s.righeMassime, Int((geo.size.height + s.spazioRighe) / (s.altezzaRiga + s.spazioRighe))))
                VStack(alignment: .leading, spacing: s.spazioRighe) {
                    if scadenze.isEmpty {
                        Text("Niente in scadenza nei prossimi \(RiepilogoPosizioni.giorniScadenza) giorni.")
                            .carattereApple(Tema.Apple.Scrivania.Riquadro.vuoto)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    }
                    ForEach(Array(scadenze.prefix(entrano))) { p in
                        RigaScadenzaScrivania(posizione: p, cliente: stato.cliente(p.clienteId)) { stato.apriPosizione(p) }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
            .padding(.top, s.elencoSopra)
        }
    }
}

/// Una scadenza: il blocco della data («DIC 17»), cliente, prodotto e fra quanto, l'etichetta del canale.
private struct RigaScadenzaScrivania: View {
    let posizione: Posizione
    let cliente: Cliente?
    let azione: () -> Void

    var body: some View {
        let s = Tema.Apple.Scrivania.Scadenze.self
        let data = posizione.scadenza ?? Date()
        Button(action: azione) {
            HStack(alignment: .center, spacing: s.spazio) {
                VStack(spacing: 0) {
                    Text(Formati.meseBreve.string(from: data).uppercased())
                        .carattereApple(s.mese)
                        .foregroundColor(s.coloreMese)
                    Text(Formati.giorno.string(from: data))
                        .carattereApple(s.giorno)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                }
                .frame(width: s.data)
                VStack(alignment: .leading, spacing: 0) {
                    Text(cliente?.nome ?? "")
                        .carattereApple(s.testo)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    prodottoEQuando
                }
                .lineLimit(1)
                Spacer(minLength: 0)
                EtichettaCanaleApple(canale: posizione.canale, compatta: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
    }

    /// «Infortuni famiglia · tra 45 giorni»: il prodotto in grassetto, i giorni nel colore della scadenza.
    private var prodottoEQuando: Text {
        let s = Tema.Apple.Scrivania.Scadenze.self
        let prodotto = Text(posizione.nome).font(s.prodotto.font).foregroundColor(Tema.Apple.Colore.inchiostro)
        let punto = Text(" · ").font(s.testo.font).foregroundColor(Tema.Apple.Colore.inchiostro2)
        let giorni = Text(quando).font(s.testo.font).foregroundColor(posizione.scaduta ? s.coloreScaduta : s.coloreQuando)
        return prodotto + punto + giorni
    }

    private var quando: String {
        if posizione.scaduta { return "scaduta" }
        guard let s = posizione.scadenza else { return "" }
        let cal = Calendar.current
        let giorni = max(0, cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: s)).day ?? 0)
        switch giorni {
        case 0: return "scade oggi"
        case 1: return "domani"
        default: return "tra \(giorni) giorni"
        }
    }
}
