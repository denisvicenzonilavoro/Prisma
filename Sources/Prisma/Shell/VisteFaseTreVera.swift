import SwiftUI

// Le schede della fase 3 di Vera sotto le risposte in chat (Design/template-vera.html): le promesse con «Fatto»,
// «Rimanda» e il promemoria; gli avvisi della seconda lettura (anche nel foglio prima di aprire un messaggio o salvare
// un PDF); la tabella del confronto; i quattro riquadri di «Cosa non copre» con l'articolo; il resoconto da firmare.

private typealias F = Tema.Apple.FaseTreVera

/// La pillola colorata di uno stato («In ritardo», «peggiora», «Fra 3 giorni»).
struct PillolaFaseTre: View {
    let testo: String
    let colore: Color

    var body: some View {
        Text(testo)
            .carattereApple(F.pillola)
            .foregroundColor(colore)
            .lineLimit(1)
            .fixedSize()
            .padding(F.paddingPillola)
            .background { Capsule(style: .continuous).fill(F.fondo(colore)) }
    }
}

/// Una riga a semaforo: il filo colorato a sinistra, il contenuto e le azioni.
private struct RigaSemaforo<Contenuto: View>: View {
    let colore: Color
    @ViewBuilder let contenuto: () -> Contenuto

    var body: some View {
        HStack(alignment: .center, spacing: 10) { contenuto() }
            .padding(F.paddingRiga)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: F.filoRiga / 2).fill(colore).frame(width: F.filoRiga).padding(.vertical, 8)
            }
            .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
    }
}

// MARK: - 8 · Le promesse

struct PromesseVeraVista: View {
    @Environment(StatoShell.self) var stato
    let ids: [String]

    private var oggi: Date { Date() }

    var body: some View {
        let _ = ContaCorpi.segna()
        let elenco = ids.compactMap { id in stato.dati.promesse.first { $0.id == id } }.filter { stato.visibileAlCliente($0.clienteId) }
        VStack(alignment: .leading, spacing: F.spazioRighe) {
            ForEach(elenco) { p in riga(p) }
            Text("Vera non inventa promesse: le prende solo da quello che hai scritto o detto tu.")
                .carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
        }
        .padding(.top, F.sopraScheda)
    }

    private func colore(_ p: PromessaCliente) -> Color {
        if p.stato == .fatta { return F.verde }
        switch PromesseVera.semaforo(p, oggi: oggi) {
        case .inRitardo: return F.rosso
        case .presto: return F.arancio
        case .inTempo: return F.verde
        case .senzaData: return F.neutro
        }
    }

    private func riga(_ p: PromessaCliente) -> some View {
        RigaSemaforo(colore: colore(p)) {
            if let c = stato.cliente(p.clienteId) {
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: F.avatar)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(p.testo).carattereApple(F.titoloRiga).fixedSize(horizontal: false, vertical: true)
                Text(([p.quando ?? p.scadenzaAttuale.map { "entro il \(Formati.dataEstesa.string(from: $0))" }].compactMap { $0 } + [p.fonteEtichetta]).joined(separator: " · "))
                    .carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio).lineLimit(2)
            }
            Spacer(minLength: 0)
            if p.stato == .fatta {
                PillolaFaseTre(testo: "Fatto ✓", colore: F.verde)
            } else if p.stato == .scartata {
                PillolaFaseTre(testo: "Tolta", colore: F.neutro)
            } else {
                PillolaFaseTre(testo: PromesseVera.etichetta(p, oggi: oggi), colore: colore(p))
                Button("Fatto") { stato.segnaPromessa(p.id, .fatta) }.buttonStyle(.apple).fixedSize()
                Button("Rimanda") { stato.rimandaPromessa(p.id) }.buttonStyle(.apple).fixedSize()
                    .help("Una settimana in più")
                Menu {
                    Button("Promemoria tra le attività…") { stato.promemoriaPromessa(p.id, chiave: stato.chiaveConversazione) }
                    Button("Non è una promessa", role: .destructive) { stato.segnaPromessa(p.id, .scartata) }
                } label: { Image(systemName: "ellipsis") }
                    .menuStyle(.borderlessButton).fixedSize()
                    .accessibilityLabel(Text("Altro sulla promessa"))
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - 10 · La seconda lettura

/// Gli avvisi numerati: rosso (frase a rischio, incoerenza), arancio (numero, allegato), verde (coerente).
struct AvvisiLetturaVista: View {
    let esito: EsitoSecondaLettura
    /// Applica una correzione (nil: si mostra solo la correzione proposta).
    var applica: ((AvvisoLettura) -> Void)? = nil
    var applicati: Set<String> = []

    static func colore(_ g: AvvisoLettura.Gravita) -> Color {
        switch g {
        case .rosso: return F.rosso
        case .arancio: return F.arancio
        case .verde: return F.verde
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: F.spazioRighe) {
            ForEach(Array(esito.avvisi.enumerated()), id: \.element.id) { n, a in
                let fatto = applicati.contains(a.id)
                RigaSemaforo(colore: fatto ? F.verde : Self.colore(a.gravita)) {
                    Text("\(n + 1)")
                        .carattereApple(F.numero).foregroundColor(.white)
                        .frame(width: F.cerchioNumero, height: F.cerchioNumero)
                        .background { Circle().fill(fatto ? F.verde : Self.colore(a.gravita)) }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.titolo).carattereApple(F.titoloRiga)
                        Text(a.dettaglio).carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio).fixedSize(horizontal: false, vertical: true)
                        if let c = a.correzione, applica == nil {
                            Text("Proposta: «\(c)»").carattereApple(F.dettaglioRiga).foregroundColor(F.blu)
                        }
                    }
                    Spacer(minLength: 0)
                    if let applica, a.trovato != nil, let c = a.correzione {
                        Button(fatto ? "Corretto ✓" : "Metti «\(c)»") { applica(a) }
                            .buttonStyle(.apple).fixedSize().disabled(fatto)
                    }
                }
            }
            Text("Vera segnala e propone: la valutazione resta tua.").carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
        }
    }
}

/// La seconda lettura in chat (dopo «Rileggi: …»).
struct SecondaLetturaVeraVista: View {
    let esito: EsitoSecondaLettura

    var body: some View {
        AvvisiLetturaVista(esito: esito).padding(.top, F.sopraScheda)
    }
}

/// Un testo riletto che aspetta la decisione del consulente (il passo successivo, se va avanti lo stesso).
struct LetturaInAttesa: Identifiable {
    let id = UUID()
    let esito: EsitoSecondaLettura
    let continua: () -> Void
}

/// Il foglio prima che un testo esca (messaggio, prospetto, report): correggi, torna indietro o vai avanti lo stesso.
struct FoglioSecondaLettura: View {
    let esito: EsitoSecondaLettura
    /// Il verbo del passo successivo: «Apri lo stesso», «Salva lo stesso».
    let avanti: String
    /// Le correzioni nel testo (nil se il testo non si corregge da qui, come un PDF).
    var correggi: ((EsitoSecondaLettura) -> Void)? = nil
    let continua: () -> Void
    @Environment(\.dismiss) private var chiudi

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                IconaApp(app: .vera, lato: 26)
                Text("Vera ha riletto: \(esito.oggetto.prefix(1).lowercased() + esito.oggetto.dropFirst())").carattereApple(F.titoloFoglio)
            }
            ScrollView { AvvisiLetturaVista(esito: esito) }
                .frame(maxHeight: 360)
            HStack {
                if let correggi, esito.avvisi.contains(where: { $0.correzione != nil && $0.trovato != nil }) {
                    Button("Applica le correzioni") { correggi(esito); chiudi() }.buttonStyle(.apple)
                }
                Spacer()
                Button("Torno a correggere") { chiudi() }.buttonStyle(.apple).keyboardShortcut(.cancelAction)
                Button(avanti) { chiudi(); continua() }.buttonStyle(.applePrimario)
            }
        }
        .padding(F.paddingFoglio)
        .frame(width: F.larghezzaFoglio)
    }
}

// MARK: - 11 · Trova le differenze

struct ConfrontoVeraVista: View {
    @Environment(StatoShell.self) var stato
    let id: String

    static func colore(_ e: RigaDifferenza.Esito) -> Color {
        switch e {
        case .migliora, .nuova: return F.verde
        case .peggiora, .costaDiPiu, .tolta: return F.rosso
        case .cambia: return F.blu
        case .uguale: return F.neutro
        }
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        if let c = stato.confronto(id), stato.visibileAlCliente(c.clienteId) {
            VStack(alignment: .leading, spacing: 8) {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 0) {
                    GridRow {
                        Text("Voce"); Text(c.titoloPrima).lineLimit(1); Text(c.titoloOra).lineLimit(1); Text("")
                    }
                    .carattereApple(F.intestazioneTabella).foregroundColor(F.coloreDettaglio)
                    .padding(F.paddingCella)
                    ForEach(c.righe) { r in
                        Divider().gridCellColumns(4)
                        GridRow {
                            Text(r.voce).carattereApple(F.cellaVoce)
                            Text(r.prima).carattereApple(F.cella).foregroundColor(F.coloreDettaglio)
                            Text(r.ora).carattereApple(F.cellaVoce)
                            PillolaFaseTre(testo: r.etichetta, colore: Self.colore(r.esito)).frame(width: F.colonnaEsito, alignment: .trailing)
                        }
                        .padding(F.paddingCella)
                    }
                }
                .padding(.vertical, 4)
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
                Text("Salvato nella scheda di \(stato.cliente(c.clienteId)?.nome ?? "del cliente") · Vera confronta il testo letto dai documenti, non l'impaginazione.")
                    .carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
            }
            .padding(.top, F.sopraScheda)
        }
    }
}

// MARK: - 12 · Cosa non copre

struct CoperturaVeraVista: View {
    @Environment(StatoShell.self) var stato
    let documentoId: String
    @State private var perCliente = false

    static func colore(_ t: LimiteCopertura.Tipo) -> Color {
        switch t {
        case .esclusione: return F.rosso
        case .carenza: return F.verde
        case .franchigia: return F.arancio
        case .massimale: return F.blu
        }
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        if let c = stato.copertura(documentoId), stato.visibileAlCliente(c.clienteId) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("", selection: $perCliente) {
                    Text("Per te").tag(false)
                    Text("Con le parole del cliente").tag(true)
                }
                .pickerStyle(.segmented).labelsHidden().fixedSize()
                LazyVGrid(columns: [GridItem(.adaptive(minimum: F.colonneLimiti), spacing: 10, alignment: .top)], alignment: .leading, spacing: 10) {
                    ForEach(LimiteCopertura.Tipo.allCases, id: \.self) { t in riquadro(t, voci: c.voci(t)) }
                }
                HStack {
                    Text("\(c.articoliLetti) articoli letti in «\(c.titolo)»\(c.conQwen ? " · spiegati da Qwen, controllati con gli articoli" : "")")
                        .carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
                    Spacer()
                    if !c.voci.isEmpty, !stato.inModoCliente {
                        Button("Spiegalo al cliente") { stato.spiegaCoperturaAlCliente(c.documentoId, chiave: stato.chiaveConversazione) }
                            .buttonStyle(.apple)
                    }
                }
            }
            .padding(.top, F.sopraScheda)
        }
    }

    private func riquadro(_ t: LimiteCopertura.Tipo, voci: [LimiteCopertura]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(t.titolo).carattereApple(F.titoloLimite)
            if voci.isEmpty {
                Text("Nessuna voce trovata negli articoli").carattereApple(F.voceLimite).foregroundColor(F.coloreDettaglio)
            }
            ForEach(voci) { v in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(perCliente ? v.perCliente : v.voce).carattereApple(F.voceLimite).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    PillolaFaseTre(testo: "art. \(v.articolo)", colore: F.neutro)
                        .help("«\(v.frase)» · pagina \(v.pagina)")
                }
            }
        }
        .padding(F.paddingLimite)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(Self.colore(t)).frame(height: F.spessoreFiloLimite) }
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
        .clipShape(RoundedRectangle(cornerRadius: Tema.Apple.Raggio.tile, style: .continuous))
    }
}

// MARK: - 16 · Il resoconto dell'incontro

struct ResocontoVeraVista: View {
    @Environment(StatoShell.self) var stato
    let incontroId: String

    var body: some View {
        let _ = ContaCorpi.segna()
        if let i = stato.incontro(incontroId), let r = i.resoconto, stato.visibileAlCliente(i.clienteId) {
            VStack(alignment: .leading, spacing: F.spazioSezioniResoconto) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("RESOCONTO DELL'INCONTRO").carattereApple(F.occhiello).foregroundColor(F.etichettaVera)
                    Text(r.titolo).carattereApple(F.titoloResoconto)
                    Text("\(stato.cliente(i.clienteId)?.nome ?? "") · \(Formati.dataLunga.string(from: i.data)), \(Formati.ora.string(from: i.data))")
                        .carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio)
                    // Il consenso alla registrazione si vede nella scheda, prima della firma (non solo nel PDF)
                    if let x = ResocontoVera.consensoDaMostrare(r, cliente: stato.cliente(i.clienteId)) {
                        Label(ResocontoVera.testoConsenso(x), systemImage: "checkmark.shield")
                            .carattereApple(F.dettaglioRiga).foregroundColor(F.verde)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if !r.firmato {
                    Picker("", selection: Binding(get: { r.formato }, set: { stato.formatoResoconto(incontroId, $0) })) {
                        Text("Completo").tag(ResocontoIncontro.Formato.completo)
                        Text("Breve").tag(ResocontoIncontro.Formato.breve)
                    }
                    .pickerStyle(.segmented).labelsHidden().fixedSize()
                }
                ForEach(Array(r.sezioniMostrate.enumerated()), id: \.offset) { n, s in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(s.titolo).carattereApple(F.sezioneResoconto).foregroundColor(F.etichettaVera)
                        ForEach(Array(s.righe.enumerated()), id: \.offset) { k, riga in
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("•").carattereApple(F.rigaResoconto).foregroundColor(F.coloreDettaglio)
                                Text(riga).carattereApple(F.rigaResoconto).fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                                // ✕ solo nel formato completo (il breve è un estratto) e prima della firma
                                if !r.firmato, r.formato == .completo, n > 0 {
                                    Button { stato.togliRigaResoconto(incontroId, sezione: n, riga: k) } label: {
                                        Image(systemName: "xmark").frame(width: F.tastoTogli, height: F.tastoTogli)
                                    }
                                    .buttonStyle(.plain).foregroundColor(F.coloreDettaglio)
                                    .help("Togli dal resoconto")
                                }
                            }
                        }
                    }
                }
                HStack {
                    Text(fonti(r)).carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
                    Spacer()
                    // «Manda una sintesi a …»: la bozza in Messaggi, nel tuo stile, dalla scheda «Conferma»
                    if !stato.inModoCliente, let c = stato.cliente(i.clienteId),
                       ResocontoVera.sintesiCliente(r, incontro: i, nome: c.nome) != nil {
                        Button("Manda una sintesi a \(c.nome.split(separator: " ").first.map(String.init) ?? c.nome)") {
                            _ = stato.mandaSintesiResoconto(incontroId, chiave: stato.chiaveConversazione)
                        }
                        .buttonStyle(.apple)
                        .disabled(stato.veraInCorso || stato.solaLettura)
                        .help("Le decisioni e i prossimi passi in una bozza in Messaggi: niente parte senza la tua conferma")
                    }
                    if r.firmato {
                        PillolaFaseTre(testo: "Firmato\(r.firmatoIl.map { " il \(Formati.dataEstesa.string(from: $0))" } ?? "") ✓", colore: F.verde)
                        if let d = r.documentoId {
                            Button("Apri il PDF") { stato.apriDocumentoVera(d) }.buttonStyle(.apple)
                        }
                    } else if !stato.inModoCliente {
                        Button("Firma") {
                            if stato.firmaResoconto(incontroId) != nil {
                                stato.proponiPassiResoconto(incontroId, chiave: stato.chiaveConversazione)
                            }
                        }
                        .buttonStyle(.applePrimario)
                        .disabled(stato.veraInCorso || stato.solaLettura)
                        .help("Con il tuo nome e la data: il PDF va nei Documenti del cliente")
                    }
                }
            }
            .padding(F.paddingResoconto)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            .padding(.top, F.sopraScheda)
        }
    }

    private func fonti(_ r: ResocontoIncontro) -> String {
        let nomi = r.fonti.map { f -> String in
            switch f {
            case .appunti: return "dagli appunti"
            case .copilota: return "dal copilota"
            case .notaVocale: return "dalla nota vocale (l'audio non è conservato)"
            }
        }
        return nomi.isEmpty ? "Scritto con Vera" : "Scritto con Vera " + nomi.joined(separator: ", ")
    }
}

// MARK: - La seconda lettura nella scheda di adeguatezza

/// «Rileggi la scheda»: i controlli del profilo, le cifre, le parole e i documenti mancanti; poi la bozza della
/// motivazione (di Prisma, riscritta da Qwen se è pronto) che entra nella scheda solo con «Inserisci», mai se è firmata.
struct LetturaAdeguatezzaVista: View {
    @Environment(StatoShell.self) var stato
    let posizione: Posizione
    let firmata: Bool
    @State private var esito: EsitoSecondaLettura?
    @State private var bozza: (testo: String, conQwen: Bool)?
    @State private var scrive = false
    @State private var inserita = false

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: F.spazioRighe) {
            HStack(spacing: 8) {
                Button(esito == nil ? "Rileggi con Vera" : "Rileggi di nuovo") {
                    esito = stato.secondaLetturaAdeguatezza(posizione)
                }
                .buttonStyle(.apple).fixedSize()
                Button(scrive ? "Vera scrive…" : "Abbozza la motivazione") {
                    scrive = true
                    inserita = false
                    Task { @MainActor in
                        bozza = await stato.bozzaMotivazione(posizione)
                        scrive = false
                    }
                }
                .buttonStyle(.apple).fixedSize().disabled(scrive || firmata)
            }
            if let esito { AvvisiLetturaVista(esito: esito) }
            if let b = bozza {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MOTIVAZIONE DI ADEGUATEZZA · BOZZA").carattereApple(F.occhiello).foregroundColor(F.etichettaVera)
                    Text(b.testo).carattereApple(F.motivazione).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button(inserita ? "Inserita ✓" : "Inserisci nella scheda") {
                            stato.modificaScheda(posizione) { $0.motivazione = b.testo }
                            inserita = true
                        }
                        .buttonStyle(.applePrimario).disabled(firmata || inserita)
                        Text(b.conQwen ? "Scritta da Qwen con le sole cifre di Prisma" : "Scritta da Prisma con i controlli della scheda")
                            .carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
                    }
                }
                .padding(F.paddingRiga)
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            }
        }
    }
}
