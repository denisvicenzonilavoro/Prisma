import SwiftUI

// «Le routine» di Vera nel tema Apple (Design/template-vera.html, novità 3): sotto la risposta in chat i passi che si
// spuntano uno alla volta e il risultato pronto (la tile con la sfera, le righe numerate e i pulsanti); la pagina delle
// routine dentro Vera, con l'elenco a sinistra («Le tue routine», i passi e l'etichetta, «+ Nuova routine» tratteggiata)
// e a destra la routine scelta con l'ultimo lancio. Con «Riduci movimento» e nelle istantanee tutto è già spuntato.

private typealias F = Tema.Apple.FaseTreVera
private typealias D = Tema.Apple.FaseDueVera

private extension View {
    /// L'entrata di un passo o del risultato, solo per le risposte appena arrivate (le vecchie si vedono ferme).
    @ViewBuilder func entrataRoutine(_ anima: Bool, ritardo: Double) -> some View {
        if anima { self.entrataStile(.cascata, ritardo: ritardo) } else { self }
    }
}

// MARK: - La spunta di un passo

/// Il pallino del passo: vuoto finché il passo non tocca, poi pieno del colore dello stato con il segno.
private struct SpuntaRoutine: View {
    let stato: EsitoPassoRoutine.Stato
    let ritardo: Double
    let anima: Bool
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var acceso = false

    static func colore(_ s: EsitoPassoRoutine.Stato) -> Color {
        switch s {
        case .fatto, .vuoto: return Tema.Apple.routineFatto
        case .daConfermare: return Tema.Apple.routineDaConfermare
        case .inAttesa: return Tema.Apple.routineAttesa
        case .impossibile: return Tema.Apple.routineImpossibile
        }
    }

    private var simbolo: String {
        switch stato {
        case .fatto, .vuoto: return "checkmark"
        case .daConfermare: return "hand.raised.fill"
        case .inAttesa: return "clock"
        case .impossibile: return "xmark"
        }
    }

    var body: some View {
        let pieno = acceso || fermo || !anima
        ZStack {
            Circle().strokeBorder(Tema.Apple.routinePuntino, lineWidth: Tema.Apple.routineFiloPuntino)
                .opacity(pieno ? 0 : 1)
            Circle().fill(Self.colore(stato))
                .scaleEffect(pieno ? 1 : Tema.Apple.routineScalaSpunta)
                .opacity(pieno ? 1 : 0)
            Image(systemName: simbolo)
                .carattereApple(Tema.Apple.ConfermaVera.segnoCarattere)
                .foregroundColor(.white)
                .opacity(pieno ? 1 : 0)
        }
        .frame(width: Tema.Apple.routinePallino, height: Tema.Apple.routinePallino)
        .accessibilityHidden(true)
        .onAppear {
            guard anima, !fermo, !acceso else { return }
            withAnimation(Tema.Apple.Moto.molla(Tema.Apple.routineDurataSpunta).ritardoPrisma(ritardo)) { acceso = true }
        }
    }
}

// MARK: - I passi e il risultato (in chat e nella pagina)

/// Un lancio di una routine: i passi spuntati con la loro fonte, poi il risultato pronto con i pulsanti.
struct RoutineEsitoVista: View {
    @Environment(StatoShell.self) var stato
    let esito: EsitoRoutine
    /// Il messaggio di Vera che lo contiene (nella pagina lo cerca `messaggioConEsito`): serve ai pulsanti per sapere
    /// se la scheda aspetta.
    var messaggio: String? = nil
    /// Nella pagina, quando il messaggio non si trova più: se il lancio aveva preparato una bozza, non si sa se è stata
    /// confermata, quindi i pulsanti verso Messaggi restano spenti invece di aprire Messaggi forse vuota.
    var messaggioPerso = false

    private var bozzaSenzaScheda: Bool {
        messaggioPerso && esito.azioni.contains { $0.strumento == RegistroStrumenti.messaggiPrepara }
    }
    /// Solo per le risposte appena arrivate: i passi si spuntano uno alla volta.
    var anima = false

    private var ritmo: Double { Tema.Apple.routineRitmoPassi }

    var body: some View {
        let _ = ContaCorpi.segna()
        if stato.routineVisibile(esito) {
            VStack(alignment: .leading, spacing: F.spazioRighe) {
                if esito.domanda == nil {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(esito.passi.enumerated()), id: \.offset) { i, p in
                            riga(p, indice: i)
                                .entrataRoutine(anima, ritardo: Double(i) * ritmo)
                        }
                    }
                    risultato
                        .entrataRoutine(anima, ritardo: Double(esito.passi.count) * ritmo)
                }
            }
            .padding(.top, F.sopraScheda)
        }
    }

    private func riga(_ p: EsitoPassoRoutine, indice: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            SpuntaRoutine(stato: p.stato, ritardo: Double(indice) * ritmo + ritmo / 2, anima: anima)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(p.titolo).carattereApple(F.titoloRiga).fixedSize(horizontal: false, vertical: true)
                Text(p.fonte.isEmpty ? p.dettaglio : "\(p.dettaglio) · \(p.fonte)")
                    .carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            switch p.stato {
            case .daConfermare: PillolaFaseTre(testo: "Da confermare", colore: Tema.Apple.routineDaConfermare)
            case .inAttesa: PillolaFaseTre(testo: "In attesa", colore: Tema.Apple.routineAttesa)
            case .impossibile: PillolaFaseTre(testo: "Non fatto", colore: Tema.Apple.routineImpossibile)
            case .fatto, .vuoto: EmptyView()
            }
        }
        .padding(.vertical, Tema.Apple.routineSpazioPasso)
        .accessibilityElement(children: .combine)
    }

    static let avvisoBozzaPersa = "La bozza si conferma nella chat di Vera, e quella conversazione non c'è più: rilancia la routine"

    private var risultato: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                SferaVera(misura: Tema.Apple.routineSfera, viva: false)
                Text(esito.risultato.titolo).carattereApple(F.titoloResoconto).fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(esito.risultato.righe.enumerated()), id: \.offset) { n, riga in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(n + 1).").carattereApple(F.rigaResoconto).foregroundColor(F.coloreDettaglio)
                        Text(riga).carattereApple(F.rigaResoconto).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if !esito.risultato.pulsanti.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(esito.risultato.pulsanti.enumerated()), id: \.offset) { i, p in
                        let spento = bozzaSenzaScheda && p.app == .messaggi
                        if i == 0 {
                            Button(p.titolo) { stato.apriPulsanteRoutine(p, messaggio: messaggio) }
                                .buttonStyle(.applePrimario).fixedSize()
                                .disabled(spento)
                                .help(spento ? Self.avvisoBozzaPersa : "")
                        } else {
                            Button(p.titolo) { stato.apriPulsanteRoutine(p, messaggio: messaggio) }
                                .buttonStyle(.apple).fixedSize()
                                .disabled(spento)
                                .help(spento ? Self.avvisoBozzaPersa : "")
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(F.paddingResoconto)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
        .overlay {
            RoundedRectangle(cornerRadius: Tema.Apple.Raggio.tile, style: .continuous)
                .strokeBorder(Tema.Apple.routineAlone, lineWidth: Tema.Apple.routineSpessoreAlone)
        }
        .padding(.top, 6)
    }
}

// MARK: - La pagina delle routine

extension View {
    /// La pagina delle routine sopra la finestra di Vera (si apre con `stato.apriPaginaRoutine()`).
    func paginaRoutineVera() -> some View { modifier(PaginaRoutineVeraModificatore()) }
}

private struct PaginaRoutineVeraModificatore: ViewModifier {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo

    func body(content: Content) -> some View {
        content.overlay {
            if stato.paginaRoutineVera {
                RoutineVeraPagina()
                    .transition(calmo ? .opacity : .opacity.combined(with: .scale(scale: Tema.Apple.Moto.Cascata.scala)))
            }
        }
        .animation(calmo ? .linear(duration: Tema.Apple.routineDissolvenzaCalma) : Tema.Apple.Moto.uscita(Tema.Apple.routineDurataPagina),
                   value: stato.paginaRoutineVera)
    }
}

/// Il pulsante della testata di Vera che apre la pagina delle routine.
struct PulsanteRoutineVera: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        Button { stato.apriPaginaRoutine() } label: {
            Label("Routine", systemImage: "list.bullet.rectangle")
        }
        .buttonStyle(StileVetro())
        .help("Le tue routine: sequenze di lavoro che lanci con una frase")
    }
}

/// «Le tue routine» a sinistra, la routine scelta a destra (Design/template-vera.html, «Le routine»).
struct RoutineVeraPagina: View {
    @Environment(StatoShell.self) var stato
    @State private var nuova = ""
    @State private var confermaElimina = false

    private var selezionata: RoutineVera? {
        let tutte = stato.routineTutte
        return tutte.first { $0.id == stato.routineSelezionataVera } ?? tutte.first
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Le routine").carattereApple(D.titoloPagina)
                Spacer()
                Button("Fine") { stato.chiudiPaginaRoutine() }
                    .buttonStyle(.applePrimario)
                    .keyboardShortcut(.cancelAction)
            }
            HStack(alignment: .top, spacing: Tema.Apple.routineSpazioColonne) {
                elenco
                    .frame(width: Tema.Apple.routineColonna)
                dettaglio
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(D.paddingPagina)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: Tema.Apple.Raggio.finestra, style: .continuous).fill(Tema.Apple.Colore.vetroSopra)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Tema.Apple.Raggio.finestra, style: .continuous).strokeBorder(Tema.Apple.Colore.separatore)
        }
    }

    // MARK: Elenco

    private var elenco: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: F.spazioRighe) {
                Text("Le tue routine").carattereApple(F.occhiello).foregroundColor(F.coloreDettaglio).padding(.leading, 4)
                ForEach(Array(stato.routineTutte.enumerated()), id: \.element.id) { i, r in
                    Button { stato.routineSelezionataVera = r.id } label: { voce(r) }
                        .buttonStyle(StileSemplice())
                        .entrataCascata(i, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
                nuovaRoutine
                    .entrataCascata(stato.routineTutte.count, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            }
        }
    }

    private func voce(_ r: RoutineVera) -> some View {
        let scelta = r.id == selezionata?.id
        return VStack(alignment: .leading, spacing: 3) {
            Text(r.titolo).carattereApple(F.titoloRiga)
            Text("«\(r.frase)»").carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio).lineLimit(2)
            HStack(spacing: 6) {
                PillolaFaseTre(testo: r.passi.count == 1 ? "1 passo" : "\(r.passi.count) passi", colore: F.neutro)
                Text(r.attiva ? r.etichetta : "Spenta").carattereApple(F.nota).foregroundColor(F.coloreDettaglio).lineLimit(1)
            }
            .padding(.top, 3)
        }
        .padding(F.paddingRiga)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(r.attiva ? 1 : Tema.Apple.routineOpacitaSpenta)
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
        .overlay {
            RoundedRectangle(cornerRadius: Tema.Apple.Raggio.tile, style: .continuous)
                .strokeBorder(Tema.Apple.routineRubino, lineWidth: Tema.Apple.routineSpessoreScelta)
                .opacity(scelta ? 1 : 0)
        }
        .contentShape(RoundedRectangle(cornerRadius: Tema.Apple.Raggio.tile, style: .continuous))
        .accessibilityAddTraits(scelta ? .isSelected : [])
    }

    /// «+ Nuova routine», tratteggiata: la crei a parole e Vera te la propone nella scheda «Conferma».
    private var nuovaRoutine: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("+ Nuova routine").carattereApple(F.titoloRiga)
            Text("La crei a parole: «ogni volta che firmo, archivia il contratto e fissa il controllo a sei mesi».")
                .carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio).fixedSize(horizontal: false, vertical: true)
            if !stato.inModoCliente {
                HStack(spacing: 6) {
                    TextField("Descrivila a parole…", text: $nuova, onCommit: crea)
                        .textFieldStyle(.roundedBorder)
                    Button("Crea", action: crea)
                        .buttonStyle(.apple).fixedSize()
                        .disabled(nuova.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || stato.veraInCorso || stato.solaLettura)
                }
            }
        }
        .padding(F.paddingRiga)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: Tema.Apple.Raggio.tile, style: .continuous)
                .strokeBorder(Tema.Apple.routineTratteggio, style: StrokeStyle(lineWidth: Tema.Apple.routineFiloTratteggio, dash: Tema.Apple.routineTrattino))
        }
    }

    private func crea() {
        let t = nuova.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !stato.veraInCorso, !stato.inModoCliente else { return }
        nuova = ""
        stato.chiudiPaginaRoutine()
        // La proposta va nella conversazione che si vede, con la scheda «Conferma»
        stato.proponiRoutineNuova(RoutineVera.eUnaFraseDiCreazione(t) ? t : "Crea una routine: \(t)", chiave: stato.chiaveConversazione)
    }

    // MARK: Dettaglio

    @ViewBuilder private var dettaglio: some View {
        if let r = selezionata {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    intestazione(r)
                    if let e = stato.ultimoEsitoRoutine(r.id) {
                        Text("Ultimo lancio: \(Formati.dataEstesa.string(from: e.data)), \(Formati.ora.string(from: e.data)) · «\(e.richiesta)»")
                            .carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
                        let m = stato.messaggioConEsito(e.id)
                        RoutineEsitoVista(esito: e, messaggio: m?.id, messaggioPerso: m == nil)
                    } else {
                        passi(r)
                    }
                }
                .padding(Tema.Apple.routinePaddingDettaglio)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.card)
            .id(r.id)
        }
    }

    private func intestazione(_ r: RoutineVera) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.titolo).carattereApple(F.titoloFoglio)
                    Text("«\(r.frase)» · \(r.etichetta)").carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio)
                }
                Spacer()
                Toggle("Attiva", isOn: Binding(get: { r.attiva }, set: { stato.impostaRoutineAttiva(r.id, $0) }))
                    .toggleStyle(.switch)
                    // In modalità cliente le routine del consulente non si accendono né si spengono
                    .disabled(stato.solaLettura || stato.inModoCliente)
                    .help("Spenta, Vera non la riconosce e non la lancia da sola")
            }
            HStack(spacing: 8) {
                lancia(r)
                if !r.pronta, !stato.inModoCliente {
                    Button("Togli", role: .destructive) { confermaElimina = true }
                        .buttonStyle(.apple).fixedSize()
                        .disabled(stato.solaLettura)
                }
                Spacer()
                Text(r.pronta ? "Una routine pronta di Prisma" : "Creata il \(Formati.dataEstesa.string(from: r.creataIl))")
                    .carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
            }
        }
        .alert("Togliere la routine «\(r.titolo)»?", isPresented: $confermaElimina) {
            Button("Annulla", role: .cancel) {}
            Button("Togli", role: .destructive) { stato.eliminaRoutine(r.id) }
        } message: {
            Text("Vera non la riconoscerà più. I lanci passati non cambiano.")
        }
    }

    /// «Lancia ora»: sul portafoglio, oppure per un cliente quando la routine lavora su un cliente.
    @ViewBuilder private func lancia(_ r: RoutineVera) -> some View {
        let fermo = stato.veraInCorso || !r.attiva
        if r.serveCliente {
            Menu {
                ForEach(stato.clienti) { c in
                    Button(c.nome) { stato.lanciaRoutineDaPagina(r.id, cliente: c.id) }
                }
            } label: {
                Label("Lancia per…", systemImage: "play.fill")
            }
            .menuStyle(.borderlessButton).fixedSize()
            .disabled(fermo)
        } else {
            Button { stato.lanciaRoutineDaPagina(r.id, cliente: nil) } label: { Label("Lancia ora", systemImage: "play.fill") }
                .buttonStyle(.applePrimario).fixedSize()
                .disabled(fermo || stato.inModoCliente)
        }
    }

    /// I passi della routine prima del primo lancio, con quello che fanno.
    private func passi(_ r: RoutineVera) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("I passi").carattereApple(F.occhiello).foregroundColor(F.coloreDettaglio).padding(.bottom, 6)
            ForEach(Array(r.passi.enumerated()), id: \.offset) { i, p in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1)")
                        .carattereApple(F.numero).foregroundColor(.white)
                        .frame(width: F.cerchioNumero, height: F.cerchioNumero)
                        .background { Circle().fill(Tema.Apple.routineRubino) }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.tipo.descrizione.prefix(1).uppercased() + p.tipo.descrizione.dropFirst()).carattereApple(F.titoloRiga)
                        if p.tipo.preparaAzioni {
                            Text("Prepara un'azione: la fa solo con la tua «Conferma»").carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, Tema.Apple.routineSpazioPasso)
            }
            Text("Vera esegue i passi con gli strumenti di Prisma: le cifre le calcola Prisma, e niente cambia senza «Conferma».")
                .carattereApple(F.nota).foregroundColor(F.coloreDettaglio).padding(.top, 8)
        }
    }
}

extension RoutineVera {
    /// La frase della pagina dice già che è una routine nuova (altrimenti la si fa precedere da «Crea una routine:»).
    static func eUnaFraseDiCreazione(_ testo: String) -> Bool {
        StatoShell.eUnaRoutineNuova(testo, InterpreteComandi.pulisci(testo))
    }
}
