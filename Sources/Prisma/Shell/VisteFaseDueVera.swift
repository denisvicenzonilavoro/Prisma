import SwiftUI
import UniformTypeIdentifiers

// Le viste della fase 2 di Vera (Design/template-vera.html): la cornice di «Lascia cadere qui» sulla finestra di Vera,
// la pagina della memoria (ricordi su di te e sui clienti, lezioni, interruttori), 👍 e 👎 sotto le risposte con la
// correzione che diventa una lezione, «Il cliente in 30 secondi» con le sue fonti e le citazioni delle norme.

private typealias F = Tema.Apple.FaseDueVera

// MARK: - Lascia cadere qui

private struct RilascioDocumentiVera: ViewModifier {
    @Environment(StatoShell.self) var stato
    @State private var sopra = false

    func body(content: Content) -> some View {
        content
            #if os(macOS)
            .onDrop(of: [UTType.fileURL], isTargeted: $sopra) { fornitori in
                guard !stato.solaLettura else { return false }
                let raccolta = RaccoltaRilascio()
                let gruppo = DispatchGroup()
                for f in fornitori {
                    gruppo.enter()
                    _ = f.loadObject(ofClass: URL.self) { url, _ in
                        DispatchQueue.main.async {
                            if let url { raccolta.urls.append(url) }
                            gruppo.leave()
                        }
                    }
                }
                gruppo.notify(queue: .main) { stato.lasciaCadere(raccolta.urls) }
                return true
            }
            .overlay {
                if sopra {
                    ZStack {
                        RoundedRectangle(cornerRadius: F.raggioCornice, style: .continuous).fill(F.fondoCornice)
                        RoundedRectangle(cornerRadius: F.raggioCornice, style: .continuous)
                            .strokeBorder(F.cornice, style: StrokeStyle(lineWidth: F.spessoreCornice, dash: F.trattino))
                        VStack(spacing: 6) {
                            Text("Lascia cadere qui").carattereApple(F.testoCornice).foregroundColor(Tema.Apple.Colore.inchiostro)
                            Text("PDF, foto o scansione: Vera lo legge sul Mac, riconosce il cliente e ti chiede conferma.")
                                .carattereApple(F.notaCornice).foregroundColor(Tema.Apple.Colore.inchiostro2)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            #endif
    }
}

extension View {
    func rilascioDocumentiVera() -> some View { modifier(RilascioDocumentiVera()) }

    func paginaMemoriaVera(_ memoria: StatoMemoriaVera) -> some View { modifier(PaginaMemoriaVera(memoria: memoria)) }
}

// MARK: - La memoria

private struct PaginaMemoriaVera: ViewModifier {
    @Bindable var memoria: StatoMemoriaVera
    @Environment(\.modoIstantanea) private var istantanea

    func body(content: Content) -> some View {
        // Nelle istantanee il foglio non si disegna: la pagina compare sopra la finestra, come le altre pagine di Vera
        content
            .sheet(isPresented: istantanea ? .constant(false) : $memoria.aperta) { MemoriaVeraVista(memoria: memoria) }
            .overlay {
                if istantanea && memoria.aperta {
                    ZStack {
                        Tema.Apple.SuMisura.velo
                        MemoriaVeraVista(memoria: memoria)
                            .superficieApple(Tema.Apple.SuMisura.superficiePagina, raggio: Tema.Apple.SuMisura.raggioPagina)
                    }
                }
            }
    }
}

/// La pagina dei ricordi: «Vera ricorda», su di te e sui clienti (✎ e ✕), le lezioni dalle correzioni.
struct MemoriaVeraVista: View {
    @Environment(StatoShell.self) var stato
    @Bindable var memoria: StatoMemoriaVera
    @State private var inModifica: String?
    @State private var testo = ""
    @State private var password = ""
    @State private var confermaRicomincia = false

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("La memoria di Vera").carattereApple(F.titoloPagina)
                Spacer()
                Button("Fine") { memoria.aperta = false }.buttonStyle(.applePrimario)
            }
            HStack(spacing: 12) {
                Toggle("Vera ricorda", isOn: Bindable(stato.dati).impostazioni.vera.memoriaAttiva).toggleStyle(.switch)
                Text("\(memoria.ricordi.count) ricordi · sul Mac, cifrati").carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
                Spacer()
                pillola("Non ricorda mai: numeri di documenti, conti, password")
            }
            if memoria.bloccata { bloccata } else { colonne }
        }
        .padding(F.paddingPagina)
        .frame(width: F.larghezzaPagina, height: F.altezzaPagina)
    }

    private var bloccata: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("La memoria non si apre su questo Mac").carattereApple(F.titoloColonna)
            Text("Arriva da un backup: scrivi la password dei backup per aprirla, oppure ricomincia da capo (i ricordi di prima si perdono).")
                .carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
            HStack {
                SecureField("Password dei backup", text: $password).textFieldStyle(.roundedBorder).frame(maxWidth: 280)
                Button("Apri") { if memoria.sblocca(password: password) { password = "" } else { stato.mostraAvviso("Password sbagliata") } }
                    .buttonStyle(.applePrimario)
                Button("Ricomincia da capo") { confermaRicomincia = true }.buttonStyle(.apple)
            }
            Spacer()
        }
        .alert("Cancellare la memoria di Vera?", isPresented: $confermaRicomincia) {
            Button("Annulla", role: .cancel) {}
            Button("Ricomincia da capo", role: .destructive) { memoria.ricomincia() }
        } message: {
            Text("I ricordi, le lezioni e gli esempi arrivati dal backup si perdono per sempre. Con la password dei backup puoi ancora aprirli.")
        }
    }

    private var colonne: some View {
        HStack(alignment: .top, spacing: F.spazioColonne) {
            colonna("Su di te", memoria.ricordi.filter { $0.clienteId == nil })
            colonna("Sui clienti", memoria.ricordi.filter { $0.clienteId != nil })
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Le lezioni di Vera").carattereApple(F.titoloColonna)
                    pillola("\(memoria.lezioni.count)")
                    Spacer()
                    Toggle("", isOn: Bindable(stato.dati).impostazioni.vera.imparaDalleCorrezioni).toggleStyle(.switch).labelsHidden()
                        .help("Impara dalle correzioni")
                }
                LezioniAndamentoVista(andamento: stato.approvazioniVera())
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if memoria.lezioni.isEmpty {
                            Text("Nessuna lezione: con 👎 sotto una risposta scrivi cosa non va, e Vera lo rilegge prima di rispondere.")
                                .carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
                        }
                        ForEach(memoria.lezioni.reversed()) { l in
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(l.testo).carattereApple(F.ricordo).opacity(l.attiva ? 1 : 0.5)
                                    Text("\(Formati.giornoMese.string(from: l.data)), \(l.fonte)").carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
                                }
                                Spacer(minLength: 0)
                                tasto(l.attiva ? "pause" : "play") { memoria.alternaLezione(l.id) }
                                tasto("xmark") { memoria.eliminaLezione(l.id) }
                            }
                            .padding(F.paddingRicordo)
                            .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private func colonna(_ titolo: String, _ ricordi: [RicordoVera]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titolo).carattereApple(F.titoloColonna)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if ricordi.isEmpty {
                        Text("Ancora niente: di' a Vera «ricorda che…» oppure conferma i ricordi che ti propone.")
                            .carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
                    }
                    ForEach(ricordi.reversed()) { r in voce(r) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func voce(_ r: RicordoVera) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if let id = r.clienteId, let c = stato.cliente(id) {
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: F.avatarRicordo)
            }
            VStack(alignment: .leading, spacing: 2) {
                if inModifica == r.id {
                    TextField("Ricordo", text: $testo, onCommit: {
                        memoria.modificaRicordo(r.id, testo: testo)
                        inModifica = nil
                    })
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(r.testo).carattereApple(F.ricordo)
                }
                Text("\(Formati.giornoMese.string(from: r.data)), \(r.fonte)").carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
            }
            Spacer(minLength: 0)
            tasto("pencil") { testo = r.testo; inModifica = r.id }
            tasto("xmark") { memoria.dimentica(r.id); stato.mostraAvviso("Dimenticato: Vera non lo userà più") }
        }
        .padding(F.paddingRicordo)
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
    }

    private func tasto(_ simbolo: String, _ fai: @escaping () -> Void) -> some View {
        Button(action: fai) {
            Image(systemName: simbolo).carattereApple(Tema.Apple.ConfermaVera.segnoCarattere).frame(width: F.tasto, height: F.tasto)
                .background(Circle().fill(F.fondoPillola))
        }
        .buttonStyle(.plain)
    }

    private func pillola(_ t: String) -> some View {
        Text(t).carattereApple(F.pillola).foregroundColor(F.testoPillola).padding(F.paddingPillola).background(Capsule().fill(F.fondoPillola))
    }
}

// MARK: - 👍 e 👎

/// Sotto una risposta di Vera: 👍 la segna come buona, 👎 apre la correzione che diventa una lezione.
struct PolliciVera: View {
    @Environment(StatoShell.self) var stato
    let messaggio: MessaggioVera
    @State private var correggi = false
    @State private var testo = ""
    @State private var salvata = false

    var body: some View {
        let _ = ContaCorpi.segna()
        // Con «Impara dalle correzioni» o la memoria spenti i pollici non ci sono
        if stato.dati.impostazioni.vera.imparaDalleCorrezioni && stato.dati.impostazioni.vera.memoriaAttiva { pollici }
    }

    private var pollici: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Button("👍") { stato.approvaRispostaVera(messaggio.id) }
                    .buttonStyle(StilePulsanteApple(messaggio.voto == true ? .principale : .secondaria))
                    .help("Va bene")
                Button("👎") { correggi = true }
                    .buttonStyle(StilePulsanteApple(messaggio.voto == false ? .principale : .secondaria))
                    .help("Non va: scrivi cosa correggere")
                // Anche riaprendo la conversazione: 👎 con una correzione salvata resta «Lezione salvata»
                if salvata || messaggio.voto == false {
                    Label("Lezione salvata", systemImage: "checkmark").carattereApple(F.fonteSezione).foregroundColor(F.votoDato)
                }
            }
            if correggi && !salvata && messaggio.voto != false {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Cosa non va?").carattereApple(Tema.Apple.Carattere.etichetta).foregroundColor(F.coloreFonte)
                    TextField("Per esempio: con i clienti Alleanza parla di «piano», non di «prodotto»", text: $testo)
                        .textFieldStyle(.plain)
                        .carattereApple(F.correzione)
                        .padding(F.paddingCorrezione)
                        .background(RoundedRectangle(cornerRadius: F.raggioCorrezione, style: .continuous).fill(F.fondoCorrezione))
                    HStack(spacing: 6) {
                        Button("Salva la lezione") {
                            if stato.correggiRispostaVera(messaggio.id, correzione: testo) != nil { salvata = true }
                        }
                        .buttonStyle(.applePrimario)
                        .disabled(testo.trimmingCharacters(in: .whitespaces).count < 4)
                        Text("Vale per tutte le risposte future, non solo per questa.").carattereApple(F.fonteSezione).foregroundColor(F.coloreFonte)
                    }
                }
            }
        }
    }
}

// MARK: - Le lezioni di Vera e il filo lungo

/// «Risposte approvate al primo colpo»: la percentuale sui voti veri e le barre delle ultime settimane (una settimana senza
/// voti resta vuota). Senza voti lo dice.
struct LezioniAndamentoVista: View {
    let andamento: AndamentoApprovazioni

    var body: some View {
        VStack(alignment: .leading, spacing: F.spazioLezioni) {
            Text("Risposte approvate al primo colpo").carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
            if let p = andamento.percentuale {
                HStack(alignment: .bottom, spacing: F.spazioPercentualeLezioni) {
                    Text("\(p)%").carattereApple(F.percentualeLezioni).monospacedDigit()
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom, spacing: F.spazioBarreLezioni) {
                        ForEach(Array(andamento.perSettimana.enumerated()), id: \.offset) { _, q in
                            Capsule(style: .continuous)
                                .fill(q == nil ? F.binarioAnelloTrenta : F.coloreAnelloTrenta)
                                .frame(width: F.larghezzaBarraLezioni, height: max(F.larghezzaBarraLezioni, F.altezzaBarreLezioni * (q ?? 0)))
                        }
                    }
                    .frame(height: F.altezzaBarreLezioni, alignment: .bottom)
                    .accessibilityLabel(Text("Le ultime \(AndamentoApprovazioni.settimane) settimane"))
                }
                Text("\(andamento.approvate) su \(andamento.votate) risposte votate, con 👍 e 👎").carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
            } else {
                Text("Ancora nessun voto: con 👍 e 👎 sotto le risposte vedrai quante vanno bene al primo colpo.")
                    .carattereApple(F.fonteRicordo).foregroundColor(F.testoPillola)
            }
        }
        .padding(F.paddingRicordo)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
    }
}

/// «Il filo lungo» sopra la chat (template: «Memoria della conversazione» e «Riassunto che Vera tiene da parte»): quanta
/// finestra occupa la conversazione e, se delle battute sono uscite, l'inizio del riassunto che Vera porta con sé.
struct FiloConversazioneVista: View {
    @Environment(StatoShell.self) var stato
    let chiave: String

    var body: some View {
        if let f = stato.filoConversazione(chiave: chiave) {
            VStack(alignment: .leading, spacing: F.spazioFilo) {
                HStack(spacing: F.spazioTestataFilo) {
                    Text("IL FILO DELLA CONVERSAZIONE").carattereApple(F.titoloFilo).foregroundColor(F.coloreAnelloTrenta)
                    Spacer(minLength: 0)
                    Text("\(f.messaggi) messaggi · circa \(Formati.numeroFormatter.string(from: NSNumber(value: f.token)) ?? "\(f.token)") di \(Formati.numeroFormatter.string(from: NSNumber(value: f.finestra)) ?? "\(f.finestra)") token")
                        .carattereApple(F.titoloFilo).foregroundColor(F.coloreFonte).monospacedDigit()
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous).fill(F.binarioAnelloTrenta)
                        Capsule(style: .continuous).fill(F.coloreAnelloTrenta).frame(width: g.size.width * f.frazione)
                    }
                }
                .frame(height: F.altezzaBarraFilo)
                if let r = f.riassunto {
                    Text("Riassunto che Vera tiene da parte (\(f.uscite) battute): \(r.replacingOccurrences(of: "\n", with: " · "))")
                        .carattereApple(F.testoFilo).foregroundColor(F.coloreFonte)
                        .lineLimit(F.righeRiassunto)
                        .help(r)
                }
            }
            .padding(F.paddingFilo)
            .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            .padding(.bottom, F.sottoFilo)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Il cliente in 30 secondi

struct TrentaSecondiVista: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    let scheda: SchedaTrentaSecondi
    /// Il messaggio che porta la scheda: la lettura a voce si riconosce da qui.
    var messaggio: String? = nil

    /// La lettura di questo messaggio (in corso o finita), se c'è.
    private var lettura: LetturaTrentaSecondi? {
        guard let messaggio, let l = stato.letturaTrenta, l.messaggioId == messaggio else { return nil }
        return l
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let l = lettura
        VStack(alignment: .leading, spacing: F.spazioSezioni) {
            HStack(spacing: 10) {
                if let c = stato.cliente(scheda.clienteId) {
                    AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: F.avatarTrenta)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(scheda.nome).carattereApple(F.titoloCitazione)
                    if !scheda.tema.isEmpty { Text(scheda.tema).carattereApple(F.tema).foregroundColor(F.coloreFonte) }
                }
                Spacer(minLength: 0)
                ForEach(scheda.canali, id: \.self) { EtichettaCanaleApple(canale: $0, compatta: true) }
                if messaggio != nil { ascolto(l) }
            }
            ForEach(Array(scheda.sezioni.enumerated()), id: \.offset) { n, s in
                // Mentre Vera parla: la sezione detta si accende, quelle che aspettano restano in trasparenza
                let inCorso = l.map { !$0.finita } ?? false
                let detta = inCorso && l?.sezione == n
                let attesa = inCorso && (l?.sezione ?? 0) < n
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(s.titolo).carattereApple(F.titoloSezione).foregroundColor(F.coloreTitoloSezione)
                        Spacer()
                        Text(s.fonte).carattereApple(F.fonteSezione).foregroundColor(F.coloreFonte)
                    }
                    Text(s.testo).carattereApple(F.testoSezione).fixedSize(horizontal: false, vertical: true)
                }
                .padding(F.paddingSezione)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    if detta { RoundedRectangle(cornerRadius: Tema.Apple.Raggio.tile, style: .continuous).fill(F.fondoSezioneDetta) }
                }
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
                .opacity(attesa ? F.opacitaAttesa : 1)
                .animation(Tema.Apple.Moto.animazione(Tema.Apple.Moto.uscita(F.cambioSezione), calmo: calmo, istantanea: istantanea), value: attesa)
            }
            Text("Da dove arriva: la scheda · \(scheda.incontri) incontri · \(scheda.messaggi) messaggi quest'anno · \(scheda.ricordi) ricordi · \(scheda.documenti) documenti")
                .carattereApple(F.fonti).foregroundColor(F.coloreFonte)
        }
        .padding(.top, F.sopraScheda)
    }

    /// L'anello del conto alla rovescia e il pulsante: «▶ Ascolta», «Ferma» mentre parla, «▶ Ascolta di nuovo» dopo.
    @ViewBuilder private func ascolto(_ l: LetturaTrentaSecondi?) -> some View {
        let inCorso = l.map { !$0.finita } ?? false
        HStack(spacing: F.spazioAscolto) {
            AnelloTrentaSecondi(avvio: l?.avvio ?? 0, inCorso: inCorso, finita: l?.finita ?? false,
                                fermo: l.map { 1 - Double($0.sezione) / Double(max($0.sezioni, 1)) })
            if inCorso {
                Button { stato.fermaLetturaTrenta() } label: { Label("Ferma", systemImage: "stop.fill") }
                    .buttonStyle(.apple).fixedSize()
                    .help("Vera smette di raccontare")
            } else if let messaggio {
                Button { stato.ascoltaTrentaSecondi(messaggio: messaggio) } label: {
                    Label(l == nil ? "Ascolta" : "Ascolta di nuovo", systemImage: "play.fill")
                }
                .buttonStyle(.apple).fixedSize()
                .help("Vera te lo racconta a voce in 30 secondi")
            }
        }
    }
}

/// L'anello del conto alla rovescia di «Il cliente in 30 secondi»: parte pieno con «30» e si svuota in 30 secondi
/// (animazione lineare di SwiftUI, niente Timer); a ogni «Ascolta di nuovo» riparte; finita la lettura si chiude.
/// Con «Riduci movimento» e nelle istantanee resta fermo sul punto della lettura (`fermo`: la parte ancora da dire).
struct AnelloTrentaSecondi: View {
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    let avvio: Int
    let inCorso: Bool
    let finita: Bool
    let fermo: Double?
    @State private var resto: Double = 1

    var body: some View {
        let statico = calmo || istantanea
        let frazione = statico ? (finita ? 0 : (inCorso ? (fermo ?? 1) : 1)) : resto
        ZStack {
            Circle().stroke(F.binarioAnelloTrenta, lineWidth: F.spessoreAnelloTrenta)
            Circle()
                .trim(from: 0, to: frazione)
                .stroke(F.coloreAnelloTrenta, style: StrokeStyle(lineWidth: F.spessoreAnelloTrenta, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Color.clear
                .modifier(SecondiTrenta(resto: frazione))
        }
        .frame(width: F.anelloTrenta, height: F.anelloTrenta)
        .onAppear { if !statico && inCorso { parti() } }
        .onChange(of: avvio) { _ in if !statico { parti() } }
        .onChange(of: finita) { f in
            guard f, !statico else { return }
            withAnimation(Tema.Apple.Moto.uscita(F.fineAnello)) { resto = 0 }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(inCorso ? "Vera sta raccontando" : "30 secondi"))
    }

    private func parti() {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { resto = 1 }
        DispatchQueue.main.async {
            withAnimation(.linear(duration: TrentaSecondiVera.durata)) { resto = 0 }
        }
    }
}

/// I secondi al centro dell'anello, contati fotogramma per fotogramma dalla frazione animata.
private struct SecondiTrenta: ViewModifier, Animatable {
    var resto: Double
    var animatableData: Double {
        get { resto }
        set { resto = newValue }
    }

    func body(content: Content) -> some View {
        content.overlay {
            Text("\(Int((TrentaSecondiVera.durata * resto).rounded(.up)))")
                .carattereApple(F.secondiTrenta)
                .monospacedDigit()
        }
    }
}

/// La card «Il cliente in 30 secondi» nella Panoramica del dossier: con un tocco Vera racconta il cliente a voce (template:
/// «Lo chiedi a voce o con un tocco dalla scheda»). Mai in modalità cliente (le preferenze sono appunti del consulente).
struct TrentaSecondiDossierVista: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente

    private typealias P = Tema.Apple.Clienti.Panoramica

    var body: some View {
        let _ = ContaCorpi.segna()
        if !stato.inModoCliente {
            let primo = cliente.nome.split(separator: " ").first.map(String.init) ?? cliente.nome
            HStack(spacing: F.spazioAscolto) {
                SferaVera(misura: F.sferaCardTrenta, viva: true, pensa: false)
                VStack(alignment: .leading, spacing: F.spazioTitoliCardTrenta) {
                    Text("Il cliente in 30 secondi").carattereApple(F.titoloCardTrenta).foregroundColor(F.coloreAnelloTrenta)
                    Text("Prima di chiamarlo, te lo racconto io").carattereApple(F.sottotitoloCardTrenta).foregroundColor(F.coloreFonte)
                }
                Spacer(minLength: 0)
                Button { stato.trentaSecondiDallaScheda(cliente.id) } label: { Label("Raccontami \(primo)", systemImage: "play.fill") }
                    .buttonStyle(.apple).fixedSize()
                    .disabled(stato.veraInCorso)
                    .help("Apre Vera e ti racconta \(primo) a voce in 30 secondi")
            }
            .padding(P.paddingLaterali)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(P.superficie)
        }
    }
}

// MARK: - Le norme citate

struct NormeVeraVista: View {
    @Environment(StatoShell.self) var stato
    let risposta: RispostaNorme

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: 6) {
            if risposta.nonRisponde {
                Label("Cercato in \(risposta.articoliCercati) articoli: la norma non risponde", systemImage: "magnifyingglass")
                    .carattereApple(F.fonti).foregroundColor(F.nonRisponde)
            }
            ForEach(risposta.citazioni) { c in
                HStack(spacing: 11) {
                    IconaApp(app: .biblioteca, lato: F.iconaCitazione)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.etichetta + (c.rubrica.isEmpty ? "" : " · \(c.rubrica)")).carattereApple(F.titoloCitazione)
                        Text("\(c.sigla.isEmpty ? "" : c.sigla + " · ")\(c.edizione) · pagina \(c.pagina) · dal testo che hai caricato nella biblioteca")
                            .carattereApple(F.dettaglioCitazione).foregroundColor(F.coloreFonte).lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Button("Apri l'articolo") { stato.apriArticolo(c) }.buttonStyle(.apple)
                }
                .padding(F.paddingCitazione)
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            }
        }
        .padding(.top, F.sopraScheda)
    }
}
