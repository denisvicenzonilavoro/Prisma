import SwiftUI

// «Scrive come te» (Design/template-vera.html, novità 15): a sinistra «Il tuo stile», le regole con la spunta rubino,
// da dove vengono («imparata da 214 messaggi», «scritta da te») e l'interruttore; «Modifica lo stile» apre il foglio.
// A destra la bozza con il segmentato «Bozza generica / Come la scrivi tu», il destinatario, la pillola «Nel tuo stile»
// e «Usa questa bozza» (la scheda «Conferma», mai un invio). Le stesse schede vivono sotto le risposte di Vera, in
// Impostazioni › Vera e, ridotte agli avvisi, nel pannello del messaggio. Tipografia e misure della fase 3
// (`Tema.Apple.FaseTreVera`), il rubino di Vera da `Tema.Apple.stileVera`.

private typealias F = Tema.Apple.FaseTreVera

// MARK: - Il tuo stile

/// Le regole del profilo con la provenienza e l'interruttore. `compatto` (in chat): senza interruttori.
struct ProfiloStileVista: View {
    @Environment(StatoShell.self) var stato
    var compatto = false
    @State private var modifica = false

    var body: some View {
        let _ = ContaCorpi.segna()
        let p = stato.dati.impostazioni.stileVera
        let voci = StileVera.voci(p, clienti: stato.dati.clienti)
        let tocca = !compatto && !stato.inModoCliente && !stato.solaLettura
        VStack(alignment: .leading, spacing: F.spazioRighe) {
            Text("IL TUO STILE").carattereApple(F.occhiello).foregroundColor(Tema.Apple.stileVera)
            Text(StileVera.intestazione(p)).carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(voci.enumerated()), id: \.element.id) { i, v in
                riga(v, tocca: tocca)
                    .entrataCascata(i, base: 0)
            }
            if !stato.inModoCliente {
                HStack(spacing: 8) {
                    Button("Modifica lo stile") { modifica = true }
                        .buttonStyle(.apple).fixedSize()
                        .disabled(stato.solaLettura)
                    if !compatto {
                        Button("Impara di nuovo") { stato.aggiornaStileVera() }
                            .buttonStyle(.apple).fixedSize()
                            .disabled(stato.solaLettura)
                            .help("Rilegge i messaggi aperti da Prisma in Mail e in Messaggi. Le regole scritte da te restano")
                    }
                }
                .padding(.top, F.sopraScheda / 2)
            }
        }
        .sheet(isPresented: $modifica) { FoglioStileVera() }
    }

    private func riga(_ v: VoceStile, tocca: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: v.attiva ? "checkmark" : "minus")
                .carattereApple(F.numero)
                .foregroundColor(v.attiva ? Tema.Apple.stileVera : F.neutro)
                .frame(width: F.cerchioNumero, height: F.cerchioNumero)
                .background { Circle().fill(F.fondo(v.attiva ? Tema.Apple.stileVera : F.neutro)) }
            VStack(alignment: .leading, spacing: 2) {
                Text(v.testo).carattereApple(F.titoloRiga)
                    .foregroundColor(v.attiva ? Tema.Apple.Colore.inchiostro : F.coloreDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
                // In modalità cliente niente eccezioni per cliente: nominano altri clienti
                Text(([v.attiva ? v.provenienza : v.provenienza + " · spenta"] + [stato.inModoCliente ? nil : v.dettaglio].compactMap { $0 }).joined(separator: " · "))
                    .carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if tocca {
                Toggle(isOn: Binding(get: { v.attiva }, set: { stato.accendiRegolaStile(v.id, attiva: $0) })) { EmptyView() }
                    .toggleStyle(.appleSenzaEtichetta)
                    .accessibilityLabel(Text(v.testo))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - La bozza

/// Quale versione della bozza si guarda.
enum VersioneBozzaStile: Hashable { case generica, tua }

/// La bozza generica e la stessa come la scrive il consulente, con il destinatario e «Usa questa bozza».
struct BozzaStileVista: View {
    @Environment(StatoShell.self) var stato
    let scheda: SchedaStileVera
    /// La conversazione in cui proporre la scheda «Conferma» (nil: quella del cliente, aprendo Vera).
    var chiave: String? = nil
    @State private var versione = VersioneBozzaStile.tua
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    private var testo: String {
        versione == .generica ? (scheda.generica ?? "") : (scheda.inStile ?? "")
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let c = scheda.clienteId.flatMap { stato.cliente($0) }
        VStack(alignment: .leading, spacing: F.spazioRighe + 4) {
            if scheda.generica != nil {
                SegmentatoPillola(selezione: $versione, voci: [(.generica, "Bozza generica"), (.tua, "Come la scrivi tu")])
                    .fixedSize()
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    IconaApp(app: .messaggi, lato: F.avatar)
                    Text("A:").carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio)
                    if let c {
                        AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: F.avatar)
                        Text(c.nome).carattereApple(F.titoloRiga).lineLimit(1)
                    } else {
                        Text("Nessun cliente").carattereApple(F.titoloRiga).foregroundColor(F.coloreDettaglio)
                    }
                    Spacer(minLength: 0)
                    if versione == .tua {
                        PillolaFaseTre(testo: scheda.conQwen ? "Nel tuo stile · Qwen" : "Nel tuo stile", colore: Tema.Apple.stileVera)
                    } else {
                        PillolaFaseTre(testo: "Generica", colore: F.neutro)
                    }
                }
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Tema.Apple.Colore.separatore).frame(height: Tema.Apple.Misura.bordo)
                }
                Text(testo)
                    .carattereApple(F.rigaResoconto)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(versione)
                    .transition(.opacity)
                if versione == .tua {
                    if !scheda.modifiche.isEmpty {
                        Text("Ritocchi: " + scheda.modifiche.joined(separator: " · "))
                            .carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(Array(scheda.violazioni.enumerated()), id: \.offset) { _, v in
                        AvvisoStileRiga(testo: v, colore: scheda.grave ? F.rosso : F.arancio)
                    }
                }
                HStack(spacing: 10) {
                    Button("Usa questa bozza") { stato.proponiBozzaStile(scheda, chiave: chiave) }
                        .buttonStyle(.applePrimario).fixedSize()
                        .disabled(scheda.grave || c == nil || stato.solaLettura || versione == .generica)
                        .help(scheda.grave ? "Prima sistema le regole segnate in rosso: Vera non propone un testo fuori dal tuo stile"
                                           : "La bozza va in Messaggi dopo «Conferma»: la apri e la spedisci tu")
                    Text("Vera non invia mai senza il tuo via.").carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
                }
            }
            .padding(F.paddingResoconto)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
        }
        .animation(calmo || istantanea ? nil : Animazioni.apertura, value: versione)
    }
}

/// Un avviso di stile: il filo colorato e la spiegazione della regola non rispettata.
struct AvvisoStileRiga: View {
    let testo: String
    let colore: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: F.filoRiga / 2).fill(colore).frame(width: F.filoRiga)
            Text(testo).carattereApple(F.dettaglioRiga).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - In chat

/// La scheda sotto una risposta di Vera: il profilo o la bozza riscritta.
struct SchedaStileVeraChat: View {
    @Environment(StatoShell.self) var stato
    let scheda: SchedaStileVera

    var body: some View {
        Group {
            switch scheda.tipo {
            case .profilo:
                ProfiloStileVista(compatto: true)
                    .padding(F.paddingResoconto)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            case .bozza:
                BozzaStileVista(scheda: scheda, chiave: stato.chiaveConversazione)
            }
        }
        .padding(.top, F.sopraScheda)
    }
}

// MARK: - In Impostazioni › Vera

/// Il gruppo «Il tuo stile» di Impostazioni › Vera: il profilo e l'esempio sulla prima occasione dei Messaggi di oggi.
struct GruppoStileVeraImpostazioni: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.modoIstantanea) private var istantanea
    @State private var esempio: SchedaStileVera?

    var body: some View {
        VStack(alignment: .leading, spacing: F.spazioRighe + 4) {
            ProfiloStileVista()
                .padding(F.paddingResoconto)
                .frame(maxWidth: .infinity, alignment: .leading)
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            if let esempio {
                BozzaStileVista(scheda: esempio)
            }
            Text("Vera impara solo dai messaggi che apri da Prisma in Mail o in Messaggi: regole, mai i testi. Le regole scritte da te non le cambia più.")
                .carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
                .fixedSize(horizontal: false, vertical: true)
        }
        .id(StatoShell.ancoraStileVera)
        .task(id: stato.dati.impostazioni.stileVera) {
            // Fuori dal corpo: impara se sono usciti messaggi nuovi e prepara l'esempio (nelle istantanee niente scritture)
            if !istantanea { stato.aggiornaStileVeraSeServe() }
            esempio = stato.esempioStileVera()
        }
    }
}

// MARK: - Nel pannello del messaggio

/// Le regole dello stile che il testo del messaggio non rispetta (sotto il testo, prima di «Apri»). Vuota se il testo
/// segue il profilo o se il profilo non ha regole.
struct AvvisiStileMessaggioVista: View {
    @Environment(StatoShell.self) var stato
    let testo: String
    let clienteId: String
    @State private var violazioni: [ViolazioneStile] = []

    /// Gli avvisi si rifanno quando cambia il testo, il cliente o il profilo dello stile (una regola spenta in
    /// Impostazioni, una firma riscritta, Vera che impara di nuovo dopo un invio): il profilo si legge nel body,
    /// così l'osservazione lo segue anche con il pannello aperto.
    private struct ChiaveAvvisi: Equatable {
        let testo: String
        let clienteId: String
        let profilo: ProfiloStile
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !violazioni.isEmpty {
                Text("IL TUO STILE").carattereApple(F.occhiello).foregroundColor(Tema.Apple.stileVera)
                ForEach(Array(violazioni.enumerated()), id: \.offset) { _, v in
                    AvvisoStileRiga(testo: v.spiegazione, colore: v.grave ? F.rosso : F.arancio)
                }
            }
        }
        .task(id: ChiaveAvvisi(testo: testo, clienteId: clienteId, profilo: stato.dati.impostazioni.stileVera)) {
            violazioni = stato.violazioniStile(testo, clienteId: clienteId)
        }
    }
}

// MARK: - Modifica lo stile

/// Il foglio «Modifica lo stile»: ogni regola si accende, si spegne o si riscrive. Un valore cambiato diventa
/// «scritta da te» e l'apprendimento non lo tocca più.
struct FoglioStileVera: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.dismiss) private var chiudi

    @State private var conCortesia = false
    @State private var predefinita = Allocuzione.lei
    @State private var conSoglia = false
    @State private var soglia = 40
    @State private var conLunghezza = false
    @State private var lunghezza = 14
    @State private var unaCosaPerRiga = false
    @State private var primaGiornoEOra = false
    @State private var conFirma = false
    @State private var firma = ""
    @State private var conEmoji = false
    @State private var emoji = UsoEmoji.soloClientiNoti
    @State private var conAperture = false
    @State private var aperture = ""
    @State private var conChiusure = false
    @State private var chiusure = ""
    @State private var conFormule = false
    @State private var formule = ""
    @State private var letto = false
    /// Le eccezioni del tu o Lei per cliente: ✕ toglie solo dalla copia, «Salva» la scrive, «Annulla» la lascia.
    @State private var perCliente: [String: Allocuzione] = [:]
    @State private var tolte: Set<String> = []

    var body: some View {
        let p = stato.dati.impostazioni.stileVera
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                IconaApp(app: .vera, lato: F.avatar)
                Text("Modifica lo stile").carattereApple(F.titoloFoglio)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: F.spazioRighe + 4) {
                    sezione("Tu o Lei", acceso: $conCortesia) {
                        SegmentatoPillola(selezione: $predefinita, voci: [(.tu, "Del tu"), (.lei, "Del Lei")]).fixedSize()
                        HStack {
                            Text("Del tu solo sotto una certa età").carattereApple(F.dettaglioRiga)
                            Spacer(minLength: 0)
                            Toggle(isOn: $conSoglia) { EmptyView() }.toggleStyle(.appleSenzaEtichetta)
                                .accessibilityLabel(Text("Del tu solo sotto una certa età"))
                        }
                        if conSoglia {
                            Stepper(value: $soglia, in: 18...90) {
                                Text("Del tu sotto i \(soglia) anni, del Lei agli altri").carattereApple(F.dettaglioRiga)
                            }
                        }
                        eccezioni()
                    }
                    sezione("Lunghezza delle frasi", acceso: $conLunghezza) {
                        Stepper(value: $lunghezza, in: 4...60) {
                            Text("Al massimo \(lunghezza) parole per frase").carattereApple(F.dettaglioRiga)
                        }
                    }
                    sezione("Una cosa per riga", acceso: $unaCosaPerRiga) { EmptyView() }
                    sezione("Prima il giorno e l'ora", acceso: $primaGiornoEOra) { EmptyView() }
                    sezione("Firma", acceso: $conFirma) {
                        TextField("Denis", text: $firma).campoTesto()
                    }
                    sezione("Emoji", acceso: $conEmoji) {
                        SegmentatoPillola(selezione: $emoji, voci: [(.mai, "Mai"), (.soloClientiNoti, "Non ai clienti nuovi"), (.libere, "Quando servono")])
                            .fixedSize()
                    }
                    sezione("Saluti d'apertura", acceso: $conAperture, nota: "Uno per riga. ‹nome› e ‹cognome› diventano quelli del cliente.") {
                        TextField("Ciao ‹nome›,", text: $aperture, axis: .vertical).campoTesto().lineLimit(1...4)
                    }
                    sezione("Saluti di chiusura", acceso: $conChiusure, nota: "Uno per riga.") {
                        TextField("A presto!", text: $chiusure, axis: .vertical).campoTesto().lineLimit(1...4)
                    }
                    sezione("Formule da ufficio da non usare", acceso: $conFormule, nota: "Una per riga.") {
                        TextField("cordiali saluti", text: $formule, axis: .vertical).campoTesto().lineLimit(1...8)
                    }
                }
            }
            .frame(maxHeight: 460)
            HStack {
                Spacer()
                Button("Annulla") { chiudi() }.buttonStyle(.apple).keyboardShortcut(.cancelAction)
                Button("Salva lo stile") { salva(); chiudi() }.buttonStyle(.applePrimario).keyboardShortcut(.defaultAction)
                    .disabled(stato.solaLettura)
            }
        }
        .padding(F.paddingFoglio)
        .frame(width: F.larghezzaFoglio)
        .onAppear { if !letto { leggi(p); letto = true } }
    }

    private func sezione<C: View>(_ titolo: String, acceso: Binding<Bool>, nota: String? = nil, @ViewBuilder _ contenuto: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(titolo).carattereApple(F.titoloRiga)
                Spacer(minLength: 0)
                Toggle(isOn: acceso) { EmptyView() }.toggleStyle(.appleSenzaEtichetta).accessibilityLabel(Text(titolo))
            }
            if acceso.wrappedValue {
                contenuto()
                if let nota { Text(nota).carattereApple(F.nota).foregroundColor(F.coloreDettaglio) }
            }
        }
        .padding(F.paddingRiga)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
    }

    @ViewBuilder private func eccezioni() -> some View {
        let elenco = perCliente.sorted { $0.key < $1.key }
        ForEach(elenco, id: \.key) { id, a in
            HStack(spacing: 6) {
                Text("Del \(a.nome) a \(stato.cliente(id)?.nome ?? "un cliente non più in archivio")")
                    .carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio)
                Spacer(minLength: 0)
                Button { perCliente[id] = nil; tolte.insert(id) } label: {
                    Image(systemName: "xmark").frame(width: F.tastoTogli, height: F.tastoTogli)
                }
                .buttonStyle(.plain).foregroundColor(F.coloreDettaglio)
                .help("Togli l'eccezione")
            }
        }
    }

    private func leggi(_ p: ProfiloStile) {
        if let r = p.cortesia {
            conCortesia = r.attiva
            predefinita = r.valore.predefinita
            conSoglia = r.valore.sogliaEta != nil
            soglia = r.valore.sogliaEta ?? 40
            perCliente = r.valore.perCliente
        }
        if let r = p.lunghezzaFrasi { conLunghezza = r.attiva; lunghezza = r.valore }
        if let r = p.unaCosaPerRiga { unaCosaPerRiga = r.attiva && r.valore }
        if let r = p.primaGiornoEOra { primaGiornoEOra = r.attiva && r.valore }
        if let r = p.firma { conFirma = r.attiva; firma = r.valore }
        if let r = p.emoji { conEmoji = r.attiva; emoji = r.valore }
        if let r = p.aperture { conAperture = r.attiva; aperture = r.valore.joined(separator: "\n") }
        if let r = p.chiusure { conChiusure = r.attiva; chiusure = r.valore.joined(separator: "\n") }
        if let r = p.formuleVietate { conFormule = r.attiva; formule = r.valore.joined(separator: "\n") }
    }

    private func salva() {
        let firmaPulita = firma.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = ScritturaStileVera.elenco(aperture), c = ScritturaStileVera.elenco(chiusure), f = ScritturaStileVera.elenco(formule)
        stato.scriviProfiloStileVera { p in
            var cortesia = p.cortesia?.valore ?? CortesiaStile(predefinita: predefinita)
            cortesia.predefinita = predefinita
            cortesia.sogliaEta = conSoglia ? soglia : nil
            // Le eccezioni tolte con ✕ si tolgono solo adesso, con «Salva»
            for id in tolte { cortesia.perCliente[id] = nil }
            ScritturaStileVera.metti(\.cortesia, attiva: conCortesia, valore: cortesia, in: &p)
            ScritturaStileVera.metti(\.lunghezzaFrasi, attiva: conLunghezza, valore: lunghezza, in: &p)
            ScritturaStileVera.metti(\.unaCosaPerRiga, attiva: unaCosaPerRiga, valore: true, in: &p)
            ScritturaStileVera.metti(\.primaGiornoEOra, attiva: primaGiornoEOra, valore: true, in: &p)
            ScritturaStileVera.metti(\.firma, attiva: conFirma && !firmaPulita.isEmpty, valore: firmaPulita.isEmpty ? nil : firmaPulita, in: &p)
            ScritturaStileVera.metti(\.emoji, attiva: conEmoji, valore: emoji, in: &p)
            ScritturaStileVera.metti(\.aperture, attiva: conAperture && !a.isEmpty, valore: a.isEmpty ? nil : a, in: &p)
            ScritturaStileVera.metti(\.chiusure, attiva: conChiusure && !c.isEmpty, valore: c.isEmpty ? nil : c, in: &p)
            ScritturaStileVera.metti(\.formuleVietate, attiva: conFormule && !f.isEmpty, valore: f.isEmpty ? nil : f, in: &p)
        }
    }
}
