import SwiftUI

// Le viste del tagliando dei dati (Vera/BRIEF.md, funzione 5; Design/template-vera.html, «Il tagliando dei dati»):
// la pagina sopra la chat di Vera (a sinistra l'anello «Salute dell'archivio» con le schede controllate, quando,
// quante cose da sistemare e «Sistema tutto»; a destra le voci a semaforo con la correzione e «Va bene così»), la
// scheda sotto la risposta in chat, la card nella colonna di Vera e il gruppo in Impostazioni › Vera.
// Le cifre sono quelle del motore (TagliandoVera); ogni correzione apre la scheda «Conferma», mai eseguita da sola.
// Calmo e istantanee: anello pieno e numero completo subito (Anello e NumeroCheConta), niente cascate.

private typealias G = Tema.Apple.Tagliando
private typealias C = Tema.Apple.Colore

/// Il colore di una voce per gravità (rosso, arancio, neutro).
private func coloreTagliando(_ g: VoceTagliando.Gravita) -> Color {
    switch g {
    case .rosso: return Tema.Apple.tagliandoRosso
    case .arancio: return Tema.Apple.tagliandoArancio
    case .neutro: return Tema.Apple.tagliandoNeutro
    }
}

/// Il colore dell'anello della salute: verde, arancio sotto la prima soglia, rosso sotto la seconda.
private func coloreSaluteTagliando(_ salute: Int) -> Color {
    if salute >= G.sogliaVerde { return Tema.Apple.tagliandoVerde }
    if salute >= G.sogliaArancio { return Tema.Apple.tagliandoArancio }
    return Tema.Apple.tagliandoRosso
}

/// «6 cose da sistemare», «1 cosa da sistemare», «In ordine».
private func riepilogoTagliando(_ n: Int, inOrdine: String = "Archivio in ordine") -> String {
    n == 0 ? inOrdine : (n == 1 ? "1 cosa da sistemare" : "\(n) cose da sistemare")
}

// MARK: - La pagina, sopra la chat di Vera

extension View {
    /// La pagina del tagliando sopra la finestra di Vera (velo e pagina), quando `paginaTagliandoAperta`.
    func paginaTagliandoVera() -> some View { modifier(ModificatorePaginaTagliando()) }
}

private struct ModificatorePaginaTagliando: ViewModifier {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    func body(content: Content) -> some View {
        let aperta = stato.paginaTagliandoAperta && !stato.inModoCliente
        content
            .overlay {
                if aperta {
                    ZStack {
                        Tema.Apple.tagliandoVelo
                            .contentShape(Rectangle())
                            .onTapGesture { stato.chiudiPaginaTagliando() }
                        PaginaTagliandoVista()
                            .padding(G.marginePagina)
                    }
                    .transition(.opacity)
                }
            }
            .animation(Tema.Apple.Moto.animazione(Tema.Apple.Moto.uscita(G.durataCambio), calmo: calmo, istantanea: istantanea), value: aperta)
    }
}

/// Una riga dell'elenco: una voce, oppure i campi vuoti di più schede in una riga sola (come nel template).
private enum RigaPaginaTagliando: Identifiable {
    case voce(VoceTagliando)
    case campiVuoti([VoceTagliando])

    var id: String {
        switch self {
        case .voce(let v): return v.id
        case .campiVuoti: return "campi-vuoti-insieme"
        }
    }

    static func righe(_ voci: [VoceTagliando]) -> [RigaPaginaTagliando] {
        let campi = voci.filter { $0.tipo == .campiVuoti }
        guard campi.count > 1, let primo = voci.firstIndex(where: { $0.tipo == .campiVuoti }) else { return voci.map { .voce($0) } }
        var righe: [RigaPaginaTagliando] = []
        for (i, v) in voci.enumerated() {
            if v.tipo == .campiVuoti {
                if i == primo { righe.append(.campiVuoti(campi)) }
            } else {
                righe.append(.voce(v))
            }
        }
        return righe
    }
}

struct PaginaTagliandoVista: View {
    @Environment(StatoShell.self) var stato
    /// Il messaggio con la scheda «Conferma» appena proposta: si mostra in cima all'elenco.
    @State private var confermaInPagina: String?
    @State private var campiAperti = false
    @State private var ignorateAperte = false

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: G.spazioIntestazione) {
            intestazione
            if let e = stato.esitoTagliando {
                HStack(alignment: .top, spacing: G.spazioColonne) {
                    salute(e)
                    elenco(e)
                }
            } else {
                Text("Il tagliando non è ancora stato fatto.")
                    .carattereApple(G.quando).foregroundColor(C.inchiostro2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(G.paddingPagina)
        .frame(maxWidth: G.larghezzaPagina, maxHeight: G.altezzaMassimaPagina)
        .superficieApple(G.superficiePagina, raggio: G.raggioPagina)
        .onAppear { if stato.esitoTagliando == nil { stato.aggiornaEsitoTagliando() } }
        // Dopo una correzione confermata (o qualsiasi cambio dei dati dei calcoli) l'elenco si rifà
        .onChange(of: stato.versioneCalcoli) { _ in stato.aggiornaEsitoTagliando() }
    }

    private var intestazione: some View {
        HStack(spacing: G.spazioIntestazione) {
            IconaApp(app: .vera, lato: G.iconaIntestazione)
            Text(StatoShell.titoloTagliando).carattereApple(G.titoloPagina).foregroundColor(C.inchiostro)
            Spacer(minLength: 0)
            Button("Controlla adesso") { stato.controllaTagliandoAdesso() }
                .buttonStyle(.apple).fixedSize()
                .help("Rifà il controllo di tutto l'archivio adesso")
            Button("Fine") { stato.chiudiPaginaTagliando() }
                .buttonStyle(.applePrimario).fixedSize()
                .keyboardShortcut(.cancelAction)
        }
    }

    // MARK: Salute dell'archivio

    private var quando: String {
        if let r = stato.dati.tagliando.ultimo { return TagliandoVera.quando(r, oggi: Date()) }
        return "Controllate adesso."
    }

    private func salute(_ e: EsitoTagliando) -> some View {
        VStack(spacing: 0) {
            Text("Salute dell'archivio").carattereApple(G.etichetta).foregroundColor(C.inchiostro2)
            Anello(frazione: Double(e.salute) / 100, colore: coloreSaluteTagliando(e.salute), misura: G.anello, spessore: G.spessoreAnello) {
                VStack(spacing: G.spazioCentroAnello) {
                    NumeroCheConta(Double(e.salute), formato: .percentuale)
                        .carattereApple(G.percentuale).foregroundColor(C.inchiostro)
                    Text(TagliandoVera.schede(e.schede)).carattereApple(G.schede).foregroundColor(C.inchiostro2)
                }
            }
            .padding(.top, G.sopraAnello)
            .padding(.bottom, G.sottoAnello)
            Text(quando).carattereApple(G.quando).foregroundColor(C.inchiostro2)
            Text(TagliandoVera.riepilogo(e)).carattereApple(G.riepilogo).foregroundColor(C.inchiostro)
            Button("Sistema tutto") { confermaInPagina = stato.sistemaTuttoTagliando() }
                .buttonStyle(.applePrimarioGrande).fixedSize()
                .disabled(e.azioni.isEmpty || stato.solaLettura)
                .help(e.azioni.isEmpty ? "Le voci rimaste si sistemano dalla loro scheda" : "Tutte le correzioni in una scheda «Conferma»")
                .padding(.top, G.sopraSistema)
            Spacer(minLength: G.sopraSistema)
            Text("Vera non cancella mai nulla da sola: ogni correzione passa da te.")
                .carattereApple(G.nota).foregroundColor(C.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
        .padding(G.paddingSalute)
        .frame(width: G.larghezzaSalute)
        .frame(maxHeight: .infinity, alignment: .top)
        .superficieApple(G.superficieSalute)
        .accessibilityElement(children: .contain)
    }

    // MARK: Le voci

    private func elenco(_ e: EsitoTagliando) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: G.spazioRighe) {
                if let id = confermaInPagina, let s = stato.messaggioVera(id)?.conferma {
                    VStack(alignment: .leading, spacing: G.spazioRighe) {
                        Text("Da confermare").carattereApple(G.etichetta).foregroundColor(C.inchiostro2)
                        SchedaConfermaVeraVista(scheda: s, messaggio: id)
                        if s.stato != .daConfermare {
                            Button("Chiudi") { confermaInPagina = nil }.buttonStyle(.appleSobrio).fixedSize()
                        }
                    }
                    .padding(.bottom, G.spazioRighe)
                }
                if e.inOrdine {
                    RigaTagliandoVista(colore: Tema.Apple.tagliandoVerde, titolo: "Archivio in ordine",
                                       dettaglio: "\(TagliandoVera.schede(e.schede)) controllate: niente da sistemare.")
                }
                ForEach(Array(RigaPaginaTagliando.righe(e.voci).enumerated()), id: \.element.id) { i, r in
                    riga(r)
                        .entrataCascata(i, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
                }
                if !e.ignorate.isEmpty { ignorate(e.ignorate) }
            }
            .padding(.vertical, G.spazioRighe / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder private func riga(_ r: RigaPaginaTagliando) -> some View {
        switch r {
        case .voce(let v):
            rigaVoce(v)
        case .campiVuoti(let voci):
            VStack(alignment: .leading, spacing: G.spazioRighe) {
                let completabili = voci.contains { $0.correzione?.azione != nil }
                RigaTagliandoVista(colore: Tema.Apple.tagliandoNeutro, titolo: "Campi vuoti",
                                   dettaglio: TagliandoVera.riepilogoCampiVuoti(stato.esitoTagliando ?? EsitoTagliandoVuoto.esito, clienti: stato.dati.clienti)
                                    ?? "\(voci.count) schede da completare") {
                    if completabili {
                        Button("Completa dai documenti") { confermaInPagina = stato.completaCampiVuotiTagliando() }
                            .buttonStyle(.apple).fixedSize()
                            .disabled(stato.solaLettura)
                    }
                    Button(campiAperti ? "Nascondi" : "Le schede") { campiAperti.toggle() }
                        .buttonStyle(.appleSobrio).fixedSize()
                    Menu {
                        Button("Va bene così, per tutte") { stato.ignoraVociTagliando(voci.map(\.id)) }
                    } label: { Image(systemName: "ellipsis") }
                        .menuStyle(.borderlessButton).fixedSize()
                        .accessibilityLabel(Text("Altro sui campi vuoti"))
                }
                if campiAperti {
                    ForEach(voci) { v in rigaVoce(v).padding(.leading, G.rientroGruppo) }
                }
            }
        }
    }

    private func rigaVoce(_ v: VoceTagliando) -> some View {
        let inCorso = stato.correzioneTagliandoInCorso(v)
        return RigaTagliandoVista(colore: coloreTagliando(v.gravita), titolo: v.titolo, dettaglio: v.dettaglio, fatta: inCorso) {
            if inCorso {
                PillolaTagliando(testo: "Attività segnata ✓", colore: Tema.Apple.tagliandoVerde)
            } else if let c = v.correzione {
                Button(c.etichetta) { confermaInPagina = stato.correggiVoceTagliando(v.id) ?? confermaInPagina }
                    .buttonStyle(.apple).fixedSize()
                    .disabled(c.azione != nil && stato.solaLettura)
            }
            Menu {
                Button("Va bene così") { stato.ignoraVoceTagliando(v.id) }
                if let id = v.clienteId {
                    Button("Apri la scheda del cliente") { stato.vaiTagliando(.scheda(clienteId: id, sezione: .anagrafica)) }
                }
            } label: { Image(systemName: "ellipsis") }
                .menuStyle(.borderlessButton).fixedSize()
                .accessibilityLabel(Text("Altro sulla voce"))
        }
    }

    private func ignorate(_ voci: [VoceTagliando]) -> some View {
        VStack(alignment: .leading, spacing: G.spazioRighe) {
            Button(ignorateAperte ? "Nascondi quelle che vanno bene così" : "Vanno bene così: \(voci.count)") { ignorateAperte.toggle() }
                .buttonStyle(.appleSobrio).fixedSize()
                .padding(.top, G.spazioRighe)
            if ignorateAperte {
                ForEach(voci) { v in
                    RigaTagliandoVista(colore: Tema.Apple.tagliandoNeutro, titolo: v.titolo, dettaglio: v.dettaglio, fatta: true) {
                        Button("Rimetti") { stato.ripristinaVoceTagliando(v.id) }.buttonStyle(.apple).fixedSize()
                    }
                }
            }
        }
    }
}

/// Un esito vuoto, solo per chiamare `riepilogoCampiVuoti` quando l'esito manca (non succede: la riga nasce dall'esito).
private enum EsitoTagliandoVuoto {
    static let esito = EsitoTagliando(oggi: Date(timeIntervalSinceReferenceDate: 0), schede: 0, voci: [], ignorate: [], salute: 100, saluteSchede: [:])
}

// MARK: - La riga a semaforo

/// La pillola di uno stato («Attività segnata ✓»).
struct PillolaTagliando: View {
    let testo: String
    let colore: Color

    var body: some View {
        Text(testo)
            .carattereApple(G.pillola)
            .foregroundColor(colore)
            .lineLimit(1)
            .fixedSize()
            .padding(G.paddingPillola)
            .background { Capsule(style: .continuous).fill(colore.opacity(G.opacitaFondoPillola)) }
    }
}

/// La riga `.sev` del template: il filo colorato a sinistra, titolo e dettaglio, le azioni a destra.
struct RigaTagliandoVista<Azioni: View>: View {
    let colore: Color
    let titolo: String
    let dettaglio: String
    var fatta = false
    @ViewBuilder let azioni: () -> Azioni

    var body: some View {
        HStack(alignment: .center, spacing: G.spazioRiga) {
            VStack(alignment: .leading, spacing: G.spazioTitoloDettaglio) {
                Text(titolo).strikethrough(fatta).carattereApple(G.titoloRiga).foregroundColor(C.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
                Text(dettaglio).carattereApple(G.dettaglioRiga).foregroundColor(C.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            azioni()
        }
        .padding(G.paddingRiga)
        .padding(.leading, G.filo)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: G.raggioRiga, style: .continuous).fill(Tema.Apple.tagliandoFondoRiga)
        }
        .overlay(alignment: .leading) {
            Rectangle().fill(colore).frame(width: G.filo)
        }
        .clipShape(RoundedRectangle(cornerRadius: G.raggioRiga, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: G.raggioRiga, style: .continuous)
                .strokeBorder(Tema.Apple.tagliandoBordoRiga, lineWidth: Tema.Apple.Misura.bordo)
        }
        .opacity(fatta ? G.opacitaFatta : 1)
        .accessibilityElement(children: .contain)
    }
}

extension RigaTagliandoVista where Azioni == EmptyView {
    init(colore: Color, titolo: String, dettaglio: String, fatta: Bool = false) {
        self.init(colore: colore, titolo: titolo, dettaglio: dettaglio, fatta: fatta) { EmptyView() }
    }
}

// MARK: - In chat, sotto la risposta di Vera

/// La scheda del tagliando sotto la risposta (`MessaggioVera.tagliando`): "" = tutto l'archivio, altrimenti un cliente.
/// Mostra il controllo di adesso (lo stato si legge sempre aggiornato).
struct TagliandoChatVista: View {
    @Environment(StatoShell.self) var stato
    let clienteId: String

    var body: some View {
        let _ = ContaCorpi.segna()
        if let e = stato.esitoTagliando, !stato.inModoCliente {
            let tutto = clienteId.isEmpty
            let voci = tutto ? e.voci : e.voci(cliente: clienteId)
            let salute = tutto ? e.salute : (e.saluteSchede[clienteId] ?? 100)
            VStack(alignment: .leading, spacing: G.spazioRighe) {
                HStack(spacing: G.spazioRiga) {
                    Anello(frazione: Double(salute) / 100, colore: coloreSaluteTagliando(salute), misura: G.anelloChat, spessore: G.spessoreAnelloChat) {
                        NumeroCheConta(Double(salute), formato: .percentuale).carattereApple(G.percentualeChat).foregroundColor(C.inchiostro)
                    }
                    VStack(alignment: .leading, spacing: G.spazioTitoloDettaglio) {
                        Text(tutto ? "Salute dell'archivio" : "Salute della scheda").carattereApple(G.etichetta).foregroundColor(C.inchiostro2)
                        Text(riepilogoTagliando(voci.count, inOrdine: tutto ? "Archivio in ordine" : "Scheda in ordine"))
                            .carattereApple(G.riepilogo).foregroundColor(C.inchiostro)
                        if tutto { Text(TagliandoVera.schede(e.schede)).carattereApple(G.schede).foregroundColor(C.inchiostro2) }
                    }
                }
                ForEach(Array(voci.prefix(G.vociChat))) { v in
                    let inCorso = stato.correzioneTagliandoInCorso(v)
                    RigaTagliandoVista(colore: coloreTagliando(v.gravita), titolo: v.titolo, dettaglio: v.dettaglio, fatta: inCorso) {
                        if let c = v.correzione, !inCorso {
                            Button(c.etichetta) { correggi(v) }
                                .buttonStyle(.apple).fixedSize()
                                .disabled(c.azione != nil && stato.solaLettura)
                        }
                    }
                }
                if voci.count > G.vociChat {
                    Text("e altre \(voci.count - G.vociChat) nella pagina del tagliando")
                        .carattereApple(G.nota).foregroundColor(C.inchiostro2)
                }
                HStack(spacing: G.spazioRiga) {
                    Button("Apri il tagliando") { stato.apriPaginaTagliando() }.buttonStyle(.apple).fixedSize()
                    if tutto, !e.azioni.isEmpty {
                        Button("Sistema tutto") { stato.sistemaTuttoTagliando(chiave: stato.chiaveConversazione) }
                            .buttonStyle(.applePrimario).fixedSize()
                            .disabled(stato.solaLettura)
                    }
                }
                Text("Vera non cancella mai nulla da sola: ogni correzione passa da te.")
                    .carattereApple(G.nota).foregroundColor(C.inchiostro2)
            }
            .padding(.top, G.sopraScheda)
        }
    }

    /// La correzione di una voce dalla chat: la scheda «Conferma» arriva in questa conversazione.
    private func correggi(_ v: VoceTagliando) {
        guard let c = v.correzione else { return }
        switch c {
        case .naviga(_, let d): stato.vaiTagliando(d)
        case .conferma:
            if let s = TagliandoVera.scheda(v) {
                stato.proponiConfermaTagliando(s, testo: "\(v.titolo): ti preparo la correzione, la faccio solo con «Conferma».",
                                               chiave: stato.chiaveConversazione)
            }
        }
    }
}

// MARK: - Nella colonna di Vera

/// La card «Tagliando dei dati» nella colonna di Vera: l'anello piccolo e quante cose da sistemare; apre la pagina.
/// Legge il registro salvato (nessun calcolo nel body) o, se c'è, il controllo di adesso.
struct SchedaTagliandoColonnaVera: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let col = Tema.Apple.Vera.Colonna.self
        let registro = stato.dati.tagliando.ultimo
        let esito = stato.esitoTagliando
        if !stato.inModoCliente, registro != nil || esito != nil {
            let salute = esito?.salute ?? registro?.salute ?? 100
            let quante = esito?.voci.count ?? registro?.daSistemare ?? 0
            Button { stato.apriPaginaTagliando() } label: {
                HStack(spacing: G.spazioRiga) {
                    Anello(frazione: Double(salute) / 100, colore: coloreSaluteTagliando(salute), misura: G.anelloColonna, spessore: G.spessoreAnelloColonna) {
                        Text("\(salute)").carattereApple(G.percentualeColonna).foregroundColor(C.inchiostro)
                    }
                    VStack(alignment: .leading, spacing: G.spazioTitoloDettaglio) {
                        Text("Tagliando dei dati").carattereApple(col.etichetta).foregroundColor(col.coloreEtichetta)
                        Text(riepilogoTagliando(quante)).carattereApple(col.oggi).foregroundColor(col.coloreTesto)
                    }
                    Spacer(minLength: 0)
                }
                .multilineTextAlignment(.leading)
                .padding(col.paddingScheda)
                .frame(maxWidth: .infinity, alignment: .leading)
                .superficieApple(col.superficieScheda, raggio: col.raggioScheda)
                .contentShape(Rectangle())
            }
            .buttonStyle(StileSemplice())
            .help("Apri il tagliando dei dati")
            .accessibilityLabel(Text("Tagliando dei dati: salute \(salute) per cento, \(riepilogoTagliando(quante))"))
        }
    }
}

// MARK: - Impostazioni › Vera

/// Il gruppo «Il tagliando dei dati» in Impostazioni › Vera: acceso, l'ora del controllo notturno e l'ultimo controllo.
struct GruppoTagliandoImpostazioni: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let imp = Bindable(stato.dati).impostazioni.tagliando
        let attivo = stato.dati.impostazioni.tagliando.attivo
        let minuto = stato.dati.impostazioni.tagliando.minuto
        GruppoImpostazioni(titolo: "Il tagliando dei dati") {
            RigaImpostazione(titolo: "Controllo notturno", sottotitolo: "Doppioni, campi vuoti, consensi e documenti.",
                             aiuto: "Ogni notte, con Prisma aperto sul Mac, Vera controlla l'archivio. Se una notte salta, il controllo parte alla prima apertura. Ogni correzione passa da te: nulla si cancella da solo") {
                Toggle(isOn: imp.attivo) { EmptyView() }
                    .toggleStyle(.appleSenzaEtichetta)
            }
            RigaImpostazione(titolo: "Ora del controllo", sottotitolo: "Con il Mac acceso e Prisma aperto.") {
                MenuTendina(selezione: imp.ora, opzioni: (0..<24).map { ($0, "\($0):" + String(format: "%02d", minuto)) }, larghezza: G.menuOra)
                    .disabled(!attivo)
            }
            RigaImpostazione(titolo: "Ultimo controllo",
                             sottotitolo: stato.dati.tagliando.ultimo.map { TagliandoVera.quando($0, oggi: Date()) + " " + riepilogoTagliando($0.daSistemare) + "." }
                                ?? "Non ancora fatto.",
                             ultima: true) {
                ValoreRiga(testo: "Apri") { stato.apriPaginaTagliando() }
                    .disabled(stato.inModoCliente)
            }
        }
        .onChange(of: stato.dati.impostazioni.tagliando) { _ in stato.programmaTagliando() }
    }
}
