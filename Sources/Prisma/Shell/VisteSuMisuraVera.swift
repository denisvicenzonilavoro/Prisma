import SwiftUI

// La pagina «Vera su misura» (Vera/BRIEF.md, fase 5, funzione 22; Design/template-vera.html, «Ruby su misura»): sopra la
// chat di Vera, l'intestazione con «Rivedi le tappe» e la frase fissa sulla privacy, le quattro tappe in fila (tratteggio
// spento → card accesa → numero verde «fatto»), lo stato in una riga e l'anteprima degli esempi resi anonimi. Ogni azione
// che cambia qualcosa (esportare, usare, tornare indietro, eliminare) passa da una conferma che dice cosa succede.
// Calmo e istantanee: curve tracciate, barre piene e niente cascate (lo fanno i componenti del tema).

private typealias G = Tema.Apple.SuMisura
private typealias C = Tema.Apple.Colore

extension View {
    /// La pagina «Vera su misura» sopra la finestra di Vera (velo e pagina), quando `paginaSuMisuraAperta`.
    func paginaSuMisuraVera() -> some View { modifier(ModificatorePaginaSuMisura()) }
}

private struct ModificatorePaginaSuMisura: ViewModifier {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    func body(content: Content) -> some View {
        let aperta = stato.paginaSuMisuraAperta && !stato.inModoCliente
        content
            .overlay {
                if aperta {
                    ZStack {
                        G.velo
                            .contentShape(Rectangle())
                            .onTapGesture { stato.chiudiPaginaSuMisura() }
                        PaginaSuMisuraVista()
                            .padding(G.marginePagina)
                    }
                    .transition(.opacity)
                }
            }
            .animation(Tema.Apple.Moto.animazione(Tema.Apple.Moto.uscita(G.durataCambio), calmo: calmo, istantanea: istantanea), value: aperta)
    }
}

/// Le azioni da confermare (regola 2 del brief: prima di agire, conferma).
enum ConfermaSuMisura: Identifiable, Equatable {
    case esporta(Int)
    case usa(String)
    case tornaIndietro
    case elimina(String)

    var id: String {
        switch self {
        case .esporta: return "esporta"
        case .usa(let v): return "usa-" + v
        case .tornaIndietro: return "indietro"
        case .elimina(let v): return "elimina-" + v
        }
    }

    var titolo: String {
        switch self {
        case .esporta(let n): return "Esportare questi \(n) esempi?"
        case .usa: return "Usare la Vera su misura?"
        case .tornaIndietro: return "Tornare alla Vera di prima?"
        case .elimina: return "Eliminare il modello?"
        }
    }

    var pulsante: String {
        switch self {
        case .esporta: return "Esporta"
        case .usa: return "Usa la Vera su misura"
        case .tornaIndietro: return "Torna alla Vera di prima"
        case .elimina: return "Elimina il modello"
        }
    }

    /// Solo l'eliminazione è distruttiva.
    var ruolo: ButtonRole? {
        if case .elimina = self { return .destructive }
        return nil
    }

    var messaggio: String {
        switch self {
        case .esporta:
            return "Prisma salva uno zip dove scegli tu, con i soli esempi resi anonimi che hai visto nell'anteprima. Non lo invia a nessuno: lo porti tu all'addestramento. Le domande dell'esame restano sul Mac."
        case .usa:
            return "Da adesso risponde la Vera su misura, sul Mac. Puoi tornare alla Vera di prima quando vuoi."
        case .tornaIndietro:
            return "Torna a rispondere la Vera di prima. La versione su misura resta in Ollama e si può riprovare."
        case .elimina:
            return "Libera circa 3 GB sul Mac. Per riaverlo serve un nuovo addestramento."
        }
    }
}

/// Lo stato di una tappa.
enum StatoTappaSuMisura { case spenta, accesa, fatta }

struct PaginaSuMisuraVista: View {
    @Environment(StatoShell.self) var stato
    /// «Rivedi le tappe»: cambia l'identità delle tappe, che rientrano a cascata (niente dati nuovi).
    @State private var giro = 0
    @State private var conferma: ConfermaSuMisura?

    var body: some View {
        let fase = stato.faseSuMisura
        VStack(alignment: .leading, spacing: G.spazio) {
            intestazione
            avvisi(fase)
            #if os(macOS)
            if stato.anteprimaSuMisuraAperta {
                AnteprimaSuMisuraVista(esporta: { conferma = .esporta($0) })
            } else {
                tappe(fase)
                Text(stato.statoSuMisuraInBreve)
                    .carattereApple(G.testo).foregroundColor(C.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            #else
            Text("Vera su misura si fa da Prisma sul Mac.")
                .carattereApple(G.testo).foregroundColor(C.inchiostro2)
            #endif
        }
        .padding(G.paddingPagina)
        .frame(maxWidth: G.larghezzaPagina, maxHeight: G.altezzaMassimaPagina)
        .superficieApple(G.superficiePagina, raggio: G.raggioPagina)
        .onAppear { stato.memoriaVera.carica() }
        .confirmationDialog(conferma?.titolo ?? "", isPresented: Binding(get: { conferma != nil }, set: { if !$0 { conferma = nil } }),
                            titleVisibility: .visible, presenting: conferma) { c in
            Button(c.pulsante, role: c.ruolo) { esegui(c) }
            Button("Annulla", role: .cancel) { conferma = nil }
        } message: { c in
            Text(c.messaggio)
        }
    }

    private func esegui(_ c: ConfermaSuMisura) {
        conferma = nil
        switch c {
        case .esporta:
            #if os(macOS)
            stato.scegliDoveEsportareSuMisura()
            stato.anteprimaSuMisuraAperta = false
            #endif
        case .usa(let id): _ = stato.installaSuMisura(id)
        case .tornaIndietro: _ = stato.tornaAllaVeraDiPrima()
        case .elimina(let id): stato.eliminaSuMisura(id)
        }
    }

    // MARK: Intestazione

    private var intestazione: some View {
        HStack(spacing: G.spazio) {
            IconaApp(app: .vera, lato: G.iconaIntestazione)
            VStack(alignment: .leading, spacing: G.spazioTesti) {
                Text(StatoShell.titoloSuMisura).carattereApple(G.titoloPagina).foregroundColor(C.inchiostro)
                Text("Dal Mac escono solo esempi resi anonimi che hai approvato. I dati dei clienti restano qui.")
                    .carattereApple(G.frase).foregroundColor(C.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button("▶ Rivedi le tappe") {
                stato.anteprimaSuMisuraAperta = false
                giro += 1
            }
            .buttonStyle(.apple).fixedSize()
            .help("Le tappe rientrano una dopo l'altra")
            Button("Fine") { stato.chiudiPaginaSuMisura() }
                .buttonStyle(.applePrimario).fixedSize()
                .keyboardShortcut(.cancelAction)
        }
    }

    @ViewBuilder
    private func avvisi(_ fase: FaseSuMisura) -> some View {
        if fase == .soloOllama {
            RigaAvvisoSuMisura(colore: G.avviso, testo: "Vera su misura funziona solo con Ollama: in Impostazioni › Vera il fornitore è «Compatibile OpenAI».")
        } else if fase == .memoriaBloccata {
            RigaAvvisoSuMisura(colore: G.avviso, testo: "La memoria di Vera è bloccata (ripristino su un altro Mac): aprila dalla pagina dei ricordi con la password dei backup.")
        } else if stato.suMisuraMancaInOllama {
            RigaAvvisoSuMisura(colore: G.errore, testo: "La Vera su misura non è in Ollama su questo Mac (dopo un ripristino il modello non viaggia con il backup): torna a \(stato.dati.impostazioni.vera.suMisura.modelloPrecedente ?? MotoreLocale.modelloPredefinito).")
        }
        if stato.esempiSuMisuraFermi {
            RigaAvvisoSuMisura(colore: G.spenta, testo: "«Impara dalle correzioni» o la memoria sono spenti: niente esempi nuovi. Quelli che ci sono restano.")
        }
    }

    // MARK: Le quattro tappe

    private func statoTappa(_ n: Int, _ fase: FaseSuMisura) -> StatoTappaSuMisura {
        if case .inUso = fase { return .fatta }
        if n < fase.tappa { return .fatta }
        return n == fase.tappa ? .accesa : .spenta
    }

    private func tappe(_ fase: FaseSuMisura) -> some View {
        HStack(alignment: .top, spacing: G.spazio) {
            TappaSuMisuraVista(numero: 1, titolo: "Raccolgo gli esempi", stato: statoTappa(1, fase)) { raccolta(fase) }
                .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
            TappaSuMisuraVista(numero: 2, titolo: "Addestro", stato: statoTappa(2, fase)) { addestramento(fase) }
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
            TappaSuMisuraVista(numero: 3, titolo: "L'esame", stato: statoTappa(3, fase)) { esame(fase) }
                .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
            TappaSuMisuraVista(numero: 4, titolo: "Installo", stato: statoTappa(4, fase)) { installazione(fase) }
                .entrataCascata(3, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
        }
        .id(giro)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    /// La versione da mostrare nelle tappe 2-4: quella in uso, altrimenti l'ultima non eliminata.
    private var versione: VersioneSuMisura? {
        let s = stato.dati.impostazioni.vera.suMisura
        return s.inUso ?? s.versioni.last { $0.stato != .eliminata }
    }

    @ViewBuilder
    private func raccolta(_ fase: FaseSuMisura) -> some View {
        let esempi = stato.memoriaVera.esempi.count
        let lezioni = stato.memoriaVera.lezioni.filter(\.attiva).count
        Text(esempi == 1 ? "1 conversazione che hai approvato" : "\(esempi) conversazioni che hai approvato" + (lezioni > 0 ? ", con le tue \(lezioni) correzioni." : "."))
            .carattereApple(G.testo).foregroundColor(C.inchiostro2)
            .fixedSize(horizontal: false, vertical: true)
        EsempioSegnapostoVista(testo: esempioMostrato)
        Text("Nomi, indirizzi e numeri di documenti vengono tolti prima di partire.")
            .carattereApple(G.testo).foregroundColor(C.inchiostro2)
            .fixedSize(horizontal: false, vertical: true)
        switch fase {
        case .pochiEsempi(_, let mancano):
            Text(mancano == 1 ? "Ne manca 1 per il primo addestramento." : "Ne mancano \(mancano) per il primo addestramento.")
                .carattereApple(G.testo).foregroundColor(G.rubino)
        case .nessunEsempio:
            Text("Segna con 👍 le risposte che ti piacciono: diventano esempi.")
                .carattereApple(G.testo).foregroundColor(G.rubino)
                .fixedSize(horizontal: false, vertical: true)
        default:
            EmptyView()
        }
        if esempi > 0 {
            Button("Guarda l'anteprima") { stato.anteprimaSuMisuraAperta = true }
                .buttonStyle(.apple).fixedSize()
                .disabled(stato.memoriaVera.bloccata)
        }
    }

    /// La prima frase resa anonima con dei segnaposto; senza esempi, la frase del template (segnata «Esempio»).
    private var esempioMostrato: String {
        let id = stato.identificativiSuMisura
        for e in stato.memoriaVera.esempi.reversed().prefix(20) {
            let a = AnonimizzatoreVera.anonimizza(e.domanda, identificativi: id)
            if !a.sostituzioni.isEmpty, AnonimizzatoreVera.residui(a.testo, identificativi: id).isEmpty { return a.testo }
        }
        return "Esempio: [Cliente], 37 anni, [Indirizzo], versa 550 € al mese per la casa."
    }

    @ViewBuilder
    private func addestramento(_ fase: FaseSuMisura) -> some View {
        Text("Su una GPU gratuita in cloud, per circa due ore.")
            .carattereApple(G.testo).foregroundColor(C.inchiostro2)
            .fixedSize(horizontal: false, vertical: true)
        if let c = versione?.curva, c.count > 1 {
            CurvaErroreVista(curva: c)
            Text("L'errore scende a ogni giro").carattereApple(G.testo).foregroundColor(C.inchiostro2)
        } else if case .inAttesaModello(let d) = fase {
            Text("Pacchetto del \(Formati.dataLunga.string(from: d)) · \(stato.dati.impostazioni.vera.suMisura.esempiNelPacchetto) esempi: in attesa del modello addestrato.")
                .carattereApple(G.testo).foregroundColor(C.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("La curva dell'errore arriva con il modello addestrato.")
                .carattereApple(G.testo).foregroundColor(C.inchiostro3)
                .fixedSize(horizontal: false, vertical: true)
        }
        BarraPiena(frazione: statoTappa(2, fase) == .fatta ? 1 : 0, colore: G.rubino, altezza: G.altezzaBarra, raggio: G.raggioBarra)
        #if os(macOS)
        switch fase {
        case .pronti(let n):
            Button("Esporta questi \(n) esempi") { conferma = .esporta(n) }
                .buttonStyle(.applePrimario).fixedSize()
                .disabled(stato.solaLettura)
        case .inAttesaModello, .nonSuperata, .ritirata, .superata:
            Button("Importa il modello addestrato") { stato.scegliModelloDaImportare() }
                .buttonStyle(.apple).fixedSize()
        default:
            EmptyView()
        }
        if case .lavoro(let l) = fase, !stato.esameSuMisuraInCorso {
            Text(l).carattereApple(G.testo).foregroundColor(G.rubino)
            Button("Ferma") { stato.fermaSuMisura() }.buttonStyle(.appleSobrio).fixedSize()
        }
        #endif
    }

    @ViewBuilder
    private func esame(_ fase: FaseSuMisura) -> some View {
        let e = versione?.esame
        let domande = e?.domande ?? stato.divisioneSuMisura().esame.count
        Text("\(domande) domande vere del tuo lavoro, con le risposte che hai approvato.")
            .carattereApple(G.testo).foregroundColor(C.inchiostro2)
            .fixedSize(horizontal: false, vertical: true)
        if stato.esameSuMisuraInCorso, case .lavoro(let l) = fase {
            Text(l).carattereApple(G.percentuale).foregroundColor(G.rubino)
            Text("Un modello alla volta: intanto la chat di Vera aspetta.").carattereApple(G.testo).foregroundColor(C.inchiostro2)
            Button("Ferma l'esame") { stato.fermaSuMisura() }.buttonStyle(.appleSobrio).fixedSize()
        } else if let e {
            RigaEsameSuMisura(nome: "Vera di oggi", percentuale: e.percentualeAttuale, colore: G.barraOggi, indice: 0)
            RigaEsameSuMisura(nome: "Vera su misura", percentuale: e.percentualeNuova, colore: G.rubino, indice: 1)
            if e.cifreInventateNuova > 0 || e.cifreInventateAttuale > 0 {
                Text("Cifre inventate: \(e.cifreInventateAttuale) oggi, \(e.cifreInventateNuova) su misura.")
                    .carattereApple(G.testo).foregroundColor(C.inchiostro2)
            }
            if versione?.diProva == true {
                Text("Numeri di esempio").carattereApple(G.testo).foregroundColor(C.inchiostro3)
            }
        }
        if case .daEsaminare(let v) = fase {
            Button("Fai l'esame") { stato.esaminaSuMisura(v.id) }
                .buttonStyle(.applePrimario).fixedSize()
                .disabled(stato.veraInCorso)
        }
    }

    @ViewBuilder
    private func installazione(_ fase: FaseSuMisura) -> some View {
        Text("La nuova Vera prende il posto di quella di oggi solo se supera l'esame.")
            .carattereApple(G.testo).foregroundColor(C.inchiostro2)
            .fixedSize(horizontal: false, vertical: true)
        if let v = versione {
            HStack(spacing: G.spazioTappa) {
                SferaVera(misura: G.sfera, viva: false)
                VStack(alignment: .leading, spacing: G.spazioTesti) {
                    Text(SuMisuraVera.nomeVersione(v)).carattereApple(G.nomeVersione).foregroundColor(C.inchiostro)
                    Text("circa 3 GB · sul Mac").carattereApple(G.testo).foregroundColor(C.inchiostro2)
                }
            }
            .padding(G.paddingTile)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(G.superficieTile)
        }
        switch fase {
        case .superata(let v):
            Button("Usa la Vera su misura") { conferma = .usa(v.id) }
                .buttonStyle(.applePrimario).fixedSize()
        case .inUso:
            Button("Torna alla Vera di prima") { conferma = .tornaIndietro }
                .buttonStyle(.apple).fixedSize()
        case .nonSuperata(let v):
            Text("Resta la Vera di oggi: la sostituzione è bloccata.").carattereApple(G.testo).foregroundColor(G.errore)
            Button("Elimina il modello") { conferma = .elimina(v.id) }
                .buttonStyle(.apple).fixedSize()
        case .ritirata(let v):
            if v.esame?.superato == true {
                Button("Usa di nuovo la Vera su misura") { conferma = .usa(v.id) }
                    .buttonStyle(.apple).fixedSize()
            }
            Button("Elimina il modello") { conferma = .elimina(v.id) }
                .buttonStyle(.appleSobrio).fixedSize()
        default:
            EmptyView()
        }
    }
}

// MARK: - Componenti della pagina

/// Una tappa (`.stg`): spenta (tratteggio), accesa (card), fatta (numero verde).
struct TappaSuMisuraVista<Contenuto: View>: View {
    let numero: Int
    let titolo: String
    let stato: StatoTappaSuMisura
    @ViewBuilder let contenuto: () -> Contenuto

    var body: some View {
        VStack(alignment: .leading, spacing: G.spazioTappa) {
            HStack(spacing: G.spazioTappa) {
                Text(stato == .fatta ? "✓" : "\(numero)")
                    .carattereApple(G.carattereNumero)
                    .foregroundColor(stato == .spenta ? C.inchiostro3 : G.numeroAcceso)
                    .frame(width: G.numero, height: G.numero)
                    .background(Circle().fill(stato == .fatta ? G.fatto : (stato == .accesa ? G.rubino : C.binario)))
                Text(titolo).carattereApple(G.titoloTappa).foregroundColor(C.inchiostro)
            }
            contenuto()
            Spacer(minLength: 0)
        }
        .padding(G.paddingTappa)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            if stato == .spenta {
                RoundedRectangle(cornerRadius: G.raggioTappa, style: .continuous)
                    .strokeBorder(G.spenta, style: StrokeStyle(lineWidth: G.trattoSpenta, dash: G.trattino))
            }
        }
        .superficieAppleSe(stato != .spenta, G.superficieTappa, raggio: G.raggioTappa)
        .opacity(stato == .spenta ? G.opacitaSpenta : 1)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tappa \(numero), \(titolo), " + (stato == .fatta ? "fatta" : (stato == .accesa ? "in corso" : "da fare")))
    }
}

private extension View {
    /// La superficie della card solo quando la tappa è accesa o fatta.
    @ViewBuilder
    func superficieAppleSe(_ si: Bool, _ s: Tema.Apple.Superficie, raggio: CGFloat) -> some View {
        if si { self.superficieApple(s, raggio: raggio) } else { self }
    }
}

/// Una frase con i segnaposto in rubino («[Cliente]», «[Indirizzo]»).
struct EsempioSegnapostoVista: View {
    let testo: String
    var carattere = G.esempio

    var body: some View {
        Self.testo(testo)
            .carattereApple(carattere)
            .foregroundColor(C.inchiostro)
            .fixedSize(horizontal: false, vertical: true)
            .padding(G.paddingTile)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(G.superficieTile)
    }

    static func testo(_ t: String) -> Text {
        var r = Text("")
        var resto = t[...]
        while let a = resto.range(of: #"\[[^\]]{1,24}\]"#, options: .regularExpression) {
            r = r + Text(String(resto[..<a.lowerBound]))
            r = r + Text(String(resto[a])).fontWeight(.semibold).foregroundColor(G.rubino)
            resto = resto[a.upperBound...]
        }
        return r + Text(String(resto))
    }
}

/// La curva dell'errore che si disegna (TracciatoGrafico del tema).
struct CurvaErroreVista: View {
    let curva: [Double]

    var body: some View {
        let massimo = curva.max() ?? 1, minimo = curva.min() ?? 0
        let ampiezza = max(massimo - minimo, 0.000_1)
        let punti = curva.enumerated().map { i, v in
            CGPoint(x: Double(i) / Double(max(curva.count - 1, 1)), y: (v - minimo) / ampiezza)
        }
        TracciatoGrafico(punti: punti, colore: G.rubino, spessore: G.spessoreCurva)
            .frame(height: G.altezzaCurva)
            .accessibilityLabel("Curva dell'errore: scende a ogni giro")
    }
}

/// Una riga dell'esame: nome, percentuale, barra.
struct RigaEsameSuMisura: View {
    let nome: String
    let percentuale: Int
    let colore: Color
    let indice: Int

    var body: some View {
        VStack(alignment: .leading, spacing: G.spazioRigaEsame) {
            HStack {
                Text(nome).carattereApple(G.rigaEsame).foregroundColor(C.inchiostro)
                Spacer(minLength: 0)
                NumeroCheConta(Double(percentuale), formato: .percentuale, indice: indice)
                    .carattereApple(G.percentuale).foregroundColor(colore)
            }
            BarraPiena(frazione: Double(percentuale) / 100, colore: colore, indice: indice, altezza: G.altezzaBarraEsame, raggio: G.raggioBarra)
        }
    }
}

/// Un avviso in una riga, con il pallino colorato.
struct RigaAvvisoSuMisura: View {
    let colore: Color
    let testo: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: G.spazioTappa) {
            Circle().fill(colore).frame(width: G.pallino, height: G.pallino)
            Text(testo).carattereApple(G.testo).foregroundColor(C.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(G.paddingTile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(G.superficieTile)
    }
}

// MARK: - L'anteprima

/// Gli esempi resi anonimi, uno per riga, con i segnaposto evidenziati, «da guardare», esclusi e il motivo di chi non entra.
struct AnteprimaSuMisuraVista: View {
    @Environment(StatoShell.self) var stato
    let esporta: (Int) -> Void

    var body: some View {
        let voci = stato.anteprimaSuMisura()
        let entrano = stato.esempiPerPacchettoSuMisura().count
        VStack(alignment: .leading, spacing: G.spazio) {
            HStack(spacing: G.spazio) {
                VStack(alignment: .leading, spacing: G.spazioTesti) {
                    Text("Anteprima degli esempi anonimi").carattereApple(G.titoloTappa).foregroundColor(C.inchiostro)
                    Text("\(entrano) entrano nel pacchetto · \(voci.filter(\.escluso).count) esclusi da te · le domande dell'esame non sono qui")
                        .carattereApple(G.testo).foregroundColor(C.inchiostro2)
                }
                Spacer(minLength: 0)
                Button("Torna alle tappe") { stato.anteprimaSuMisuraAperta = false }
                    .buttonStyle(.apple).fixedSize()
                Button("Esporta questi \(entrano) esempi") { esporta(entrano) }
                    .buttonStyle(.applePrimario).fixedSize()
                    .disabled(entrano < SuMisuraVera.minimoEsempi || stato.solaLettura || stato.dati.impostazioni.vera.fornitore != .ollama)
                    .help(entrano < SuMisuraVera.minimoEsempi ? "Servono almeno \(SuMisuraVera.minimoEsempi) esempi" : "Prima una conferma, poi scegli dove salvare lo zip")
            }
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: G.spazioRighe) {
                    ForEach(voci) { v in
                        RigaAnteprimaSuMisura(voce: v) { stato.escludiEsempioSuMisura(v.id, !v.escluso) }
                    }
                }
            }
        }
    }
}

struct RigaAnteprimaSuMisura: View {
    let voce: VoceAnteprimaSuMisura
    let alterna: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: G.spazio) {
            VStack(alignment: .leading, spacing: G.spazioRigaEsame) {
                EsempioSegnapostoVista.testo(voce.esempio.domanda)
                    .carattereApple(G.domanda).foregroundColor(C.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
                EsempioSegnapostoVista.testo(voce.esempio.risposta)
                    .carattereApple(G.risposta).foregroundColor(C.inchiostro2)
                    .lineLimit(G.righeRisposta)
                if !voce.esempio.daGuardare.isEmpty {
                    Text("Da guardare: " + voce.esempio.daGuardare.joined(separator: ", ") + " (non è nell'archivio: escludilo se è un nome)")
                        .carattereApple(G.motivo).foregroundColor(G.avviso)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let m = voce.motivo {
                    Text(m).carattereApple(G.motivo).foregroundColor(C.inchiostro3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Button(voce.escluso ? "Riammetti" : "Escludi", action: alterna)
                .buttonStyle(.appleSobrio).fixedSize()
        }
        .padding(G.paddingRiga)
        .background(RoundedRectangle(cornerRadius: G.raggioRiga, style: .continuous).fill(G.fondoRiga))
        .overlay(RoundedRectangle(cornerRadius: G.raggioRiga, style: .continuous).strokeBorder(G.bordoRiga, lineWidth: Tema.Apple.Misura.bordo))
        .opacity(voce.escluso ? G.opacitaEsclusa : 1)
    }
}
