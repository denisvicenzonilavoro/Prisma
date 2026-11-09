import SwiftUI

// Clienti › Potenziali (Design/template-luce-specifica.md §9.2.1 punto 1.1 e §9.2.4, «Luce» giro 12):
//
//   POTENZIALI · dati di prova
//   ┌ Potenziali clienti ┐ ┌ Patrimonio stimato ┐ ┌ Dal passaparola ┐ ┌ Probabile entro fine anno ┐
//   └────────────────────┘ └ 2 senza stima ─────┘ └─────────────────┘ └ 3 senza tutti i dati ─────┘
//   ┌ Da contattare 3 ┐ ┌ Primo incontro 2 ┐ ┌ Analisi 2 ┐ ┌ Proposta 1 ┐ ┌ Cliente 1 ┐   (ogni colonna scorre)
//   │ Paolo Ferretti  │ │ …                │ │ …         │ │ …          │ │ …         │
//   │ presentato da M │
//   │ 180.000 € · 20% │
//   │ ▬▬▬───────────  │
//   └─────────────────┘
//   Tocca una scheda per farla avanzare. …
//
// - Le cifre vengono da MotorePassaparola (decisione 94: stima, probabilità e data le scrive l'utente; il probabile
//   conta solo chi le ha tutte e chiude entro il 31 dicembre); qui solo la disposizione.
// - Clic sulla scheda: un passo avanti (volo con `matchedGeometryEffect`); clic sul nome: il dettaglio che nasce dalla
//   scheda; trascinamento fra le colonne; menu «Avanti · Indietro · Modifica… · Non interessato · Elimina»; frecce,
//   ⌘→ / ⌘←, Invio e Canc. L'arrivo in «Cliente» apre la scena del nuovo cliente con il nome già scritto e
//   «presentato da …» (`proponiCliente`, §9.2.4).
// - iPad (`potenzialiInSolaLettura`, §9.2.4: l'iPad è una copia) e archivio in sola lettura: si guarda soltanto, il clic
//   apre solo il dettaglio senza i pulsanti che scrivono.
// - «Riduci movimento» e istantanee: tutto fermo nello stato finale.

struct VistaPotenziali: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoPotenziali(stato: stato, dettaglioAperto: stato.potenziali.dettaglioIstantanea)
    }
}

private struct CorpoPotenziali: View {
    let stato: StatoShell
    @StateObject private var dettaglio: StatoDettaglio
    @Namespace private var volo
    @FocusState private var fuoco: Bool
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaScatto) private var scatto
    @Environment(\.modoIstantanea) private var modoIstantanea

    private typealias P = Tema.Apple.Potenziali
    private static let misuraDettaglio = CGSize(width: Tema.Apple.Potenziali.larghezzaDettaglio,
                                                height: Tema.Apple.Potenziali.altezzaDettaglio)

    init(stato: StatoShell, dettaglioAperto: String?) {
        self.stato = stato
        _dettaglio = StateObject(wrappedValue: dettaglioAperto.map { StatoDettaglio(aperto: $0, misura: CorpoPotenziali.misuraDettaglio) }
                                 ?? StatoDettaglio())
    }

    private var modificabile: Bool { !stato.potenzialiInSolaLettura }

    var body: some View {
        let oggi = Date()
        let potenziali = stato.dati.potenziali
        let clienti = stato.dati.clienti
        let colonne = MotorePassaparola.percorso(potenziali, oggi: oggi)
        let totali = MotorePassaparola.totali(potenziali, clienti: clienti, oggi: oggi)
        let nonInteressati = potenziali.filter { $0.fase == .nonInteressato }
        let ordine = FasePotenziale.colonne.flatMap { colonne[$0] ?? [] }.map(\.id)
        let d = dettaglio
        return VStack(alignment: .leading, spacing: P.spazioTile) {
            intestazione(prova: potenziali.contains { $0.diProva })
            tile(totali)
            HStack(alignment: .top, spacing: P.spazioColonne) {
                ForEach(Array(FasePotenziale.colonne.enumerated()), id: \.element) { i, fase in
                    ColonnaPotenziali(fase: fase, elenco: colonne[fase] ?? [], clienti: clienti, indice: i,
                                      modificabile: modificabile, vuota: potenziali.allSatisfy { $0.fase == .nonInteressato },
                                      scelto: stato.potenziali.scelto, volo: volo,
                                      azioni: azioniScheda, aggiungi: { apriModulo(nil) },
                                      arrivo: { id in sposta(id, a: fase) })
                }
            }
            .frame(maxHeight: .infinity)
            piede(nonInteressati: nonInteressati)
        }
        .padding(P.margine)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .focusable(modificabile)
        .focused($fuoco)
        .focusEffectDisabled()
        .onKeyPress(phases: .down) { tasto in tastiera(tasto, ordine: ordine) }
        .background {
            // ⌘N: un potenziale nuovo (solo dove si scrive)
            if modificabile {
                Button("") { apriModulo(nil) }
                    .keyboardShortcut("n", modifiers: .command)
                    .opacity(0)
                    .accessibilityHidden(true)
            }
        }
        .presentatoreDettaglio(dettaglio) { id in
            if let p = stato.dati.potenziali.first(where: { $0.id == id }) {
                DettaglioPotenziale(stato: stato, potenziale: p, modificabile: modificabile,
                                    modifica: { d.chiudi(subito: true); apriModulo(p) },
                                    chiudi: { d.chiudi() })
            }
        }
        .sheet(item: Bindable(stato.potenziali).modulo) { p in
            ModuloPotenziale(bozza: p, nuovo: !stato.dati.potenziali.contains { $0.id == p.id }, rubrica: stato.dati.clienti) { salvato in
                stato.salvaPotenziale(salvato)
            }
        }
        .confirmationDialog("Eliminare il potenziale cliente?", isPresented: Binding(
            get: { stato.potenziali.daEliminare != nil },
            set: { if !$0 { stato.potenziali.daEliminare = nil } }), titleVisibility: .visible) {
            Button("Elimina", role: .destructive) {
                if let id = stato.potenziali.daEliminare { stato.eliminaPotenziale(id) }
                stato.potenziali.daEliminare = nil
            }
            Button("Annulla", role: .cancel) { stato.potenziali.daEliminare = nil }
        } message: {
            Text("Si toglie dal percorso e dall'albero del passaparola. I clienti non cambiano.")
        }
        .onAppear {
            // Il dettaglio chiesto da fuori (clic su un potenziale nell'albero del passaparola) si apre una volta sola:
            // tornando in Potenziali non si riapre. Nelle istantanee resta (la scena può costruire la vista più volte).
            if !modoIstantanea, stato.potenziali.dettaglioIstantanea != nil { stato.potenziali.dettaglioIstantanea = nil }
        }
        .onDisappear { dettaglio.chiudi(subito: true) }
    }

    // MARK: Intestazione, tile, piede

    private func intestazione(prova: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: P.spazioPiccolo + 2) {
            Text("POTENZIALI")
                .carattereApple(Tema.Apple.Carattere.etichetta)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            if prova {
                Text("· " + TestiPassaparola.datiDiProva)
                    .carattereApple(Tema.Apple.Carattere.etichetta)
                    .foregroundColor(Tema.Apple.Colore.inchiostro3)
            }
        }
        .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
    }

    private func tile(_ t: TotaliPotenziali) -> some View {
        HStack(spacing: P.spazioTile) {
            TilePotenziali(titolo: TestiPassaparola.tilePotenziali, valore: Double(t.conteggio), formato: .intero, nota: nil, indice: 0)
            TilePotenziali(titolo: TestiPassaparola.tilePatrimonio, valore: t.patrimonioStimato, formato: .euro,
                           nota: t.senzaStima > 0 ? TestiPassaparola.senzaStima(t.senzaStima) : nil, indice: 1)
            TilePotenziali(titolo: TestiPassaparola.tilePassaparola, valore: Double(t.dalPassaparola), formato: .intero, nota: nil, indice: 2)
            TilePotenziali(titolo: TestiPassaparola.tileProbabile, valore: t.probabileEntroAnno, formato: .euro,
                           nota: t.esclusiDalProbabile > 0 ? TestiPassaparola.esclusi(t.esclusiDalProbabile) : nil, indice: 3)
        }
    }

    @ViewBuilder private func piede(nonInteressati: [PotenzialeCliente]) -> some View {
        VStack(alignment: .leading, spacing: P.spazioPiccolo + 2) {
            Text(modificabile ? TestiPassaparola.notaPercorso : TestiPassaparola.notaPercorsoSolaLettura)
                .carattereApple(P.nota)
                .foregroundColor(P.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
            if !nonInteressati.isEmpty {
                HStack(spacing: P.spazioMedio) {
                    Text(TestiPassaparola.nonInteressati + ":")
                        .carattereApple(P.nota)
                        .foregroundColor(P.coloreNota)
                    ForEach(nonInteressati) { p in
                        Button(p.nome) { dettaglio.apri(p.id, misura: Self.misuraDettaglio) }
                            .buttonStyle(.appleSobrio)
                            .origineDettaglio(id: p.id)
                    }
                }
            }
        }
        .entrataCascata(4, base: Tema.Apple.Moto.Cascata.baseDentroApp)
    }

    // MARK: Fare

    private var azioniScheda: AzioniSchedaPotenziale {
        AzioniSchedaPotenziale(
            avanti: { id in avanza(id) },
            indietro: { id in animato { stato.arretraPotenziale(id) } },
            dettaglio: { id in
                stato.potenziali.scelto = id
                dettaglio.apri(id, misura: Self.misuraDettaglio)
            },
            modifica: { id in
                if let p = stato.dati.potenziali.first(where: { $0.id == id }) { apriModulo(p) }
            },
            nonInteressato: { id in animato { stato.spostaPotenziale(id, a: .nonInteressato) } },
            elimina: { id in stato.potenziali.daEliminare = id },
            dossier: { cid in
                stato.clienteAttivoId = cid
                stato.schedaCliente = .panoramica
                stato.vistaClienti = .rubrica
            })
    }

    private func animato(_ cambio: () -> Void) {
        if let a = Tema.Apple.Moto.animazione(Tema.Apple.Moto.Potenziali.avanza, calmo: calmo, istantanea: scatto) {
            withAnimation(a) { cambio() }
        } else {
            cambio()
        }
    }

    private func avanza(_ id: String) {
        guard modificabile else {
            dettaglio.apri(id, misura: Self.misuraDettaglio)
            return
        }
        stato.potenziali.scelto = id
        animato { stato.avanzaPotenziale(id) }
    }

    private func sposta(_ id: String, a fase: FasePotenziale) {
        guard modificabile else { return }
        animato { stato.spostaPotenziale(id, a: fase) }
    }

    private func apriModulo(_ p: PotenzialeCliente?) {
        guard modificabile else { return }
        stato.potenziali.modulo = p ?? PotenzialeCliente(nome: "")
    }

    /// Frecce fra le schede, ⌘→ / ⌘← avanti e indietro, Invio il dettaglio, Canc l'eliminazione (con conferma).
    private func tastiera(_ tasto: KeyPress, ordine: [String]) -> KeyPress.Result {
        guard modificabile, !ordine.isEmpty else { return .ignored }
        let attuale = stato.potenziali.scelto.flatMap { ordine.firstIndex(of: $0) }
        let comando = tasto.modifiers.contains(.command)
        switch tasto.key {
        case .rightArrow where comando, .leftArrow where comando:
            guard let i = attuale else { return .ignored }
            let id = ordine[i]
            if tasto.key == .rightArrow { avanza(id) } else { animato { stato.arretraPotenziale(id) } }
            return .handled
        case .rightArrow, .downArrow:
            stato.potenziali.scelto = ordine[min(ordine.count - 1, (attuale ?? -1) + 1)]
            return .handled
        case .leftArrow, .upArrow:
            stato.potenziali.scelto = ordine[max(0, (attuale ?? 1) - 1)]
            return .handled
        case .return:
            guard let i = attuale else { return .ignored }
            dettaglio.apri(ordine[i], misura: Self.misuraDettaglio)
            return .handled
        case .delete, .deleteForward:
            guard let i = attuale else { return .ignored }
            stato.potenziali.daEliminare = ordine[i]
            return .handled
        default:
            return .ignored
        }
    }
}

/// Le azioni di una scheda (le stesse per tutte le colonne).
struct AzioniSchedaPotenziale {
    let avanti: (String) -> Void
    let indietro: (String) -> Void
    let dettaglio: (String) -> Void
    let modifica: (String) -> Void
    let nonInteressato: (String) -> Void
    let elimina: (String) -> Void
    let dossier: (String) -> Void
}

// MARK: - Tile

private struct TilePotenziali: View {
    let titolo: String
    let valore: Double
    let formato: FormatoCifra
    let nota: String?
    let indice: Int

    private typealias P = Tema.Apple.Potenziali

    var body: some View {
        VStack(alignment: .leading, spacing: P.spazioPiccolo) {
            Text(titolo)
                .carattereApple(P.tileEtichetta)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            NumeroCheConta(valore, formato: formato, indice: indice)
                .carattereApple(P.tileValore)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(nota ?? " ")
                .carattereApple(P.tilePiccolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro3)
                .lineLimit(1)
        }
        .padding(P.paddingColonna)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Superficie.tile)
        .entrataCascata(1 + indice / 2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Colonna

private struct ColonnaPotenziali: View {
    let fase: FasePotenziale
    let elenco: [PotenzialeCliente]
    let clienti: [Cliente]
    let indice: Int
    let modificabile: Bool
    /// Nessun potenziale in tutto il percorso: nella prima colonna l'invito ad aggiungere.
    let vuota: Bool
    let scelto: String?
    let volo: Namespace.ID
    let azioni: AzioniSchedaPotenziale
    let aggiungi: () -> Void
    let arrivo: (String) -> Void
    @State private var sopra = false

    private typealias P = Tema.Apple.Potenziali

    var body: some View {
        VStack(alignment: .leading, spacing: P.spazioSchede) {
            HStack(alignment: .firstTextBaseline) {
                Text(fase.titolo)
                    .carattereApple(P.titoloColonna)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Spacer(minLength: P.spazioPiccolo)
                Text("\(elenco.count)")
                    .carattereApple(P.contoColonna)
                    .foregroundColor(P.coloreConto)
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: P.spazioSchede) {
                    if fase == .daContattare && vuota {
                        Text(TestiPassaparola.vuoto)
                            .carattereApple(P.vuoto)
                            .foregroundColor(P.coloreNota)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(elenco) { p in
                        SchedaPotenziale(potenziale: p, fonte: TestiPassaparola.fonte(p, clienti: clienti),
                                         modificabile: modificabile, scelta: scelto == p.id, azioni: azioni)
                            .matchedGeometryEffect(id: p.id, in: volo)
                            .origineDettaglio(id: p.id)
                    }
                    if fase == .daContattare && modificabile {
                        Button(vuota ? TestiPassaparola.aggiungi : TestiPassaparola.aggiungiBreve, action: aggiungi)
                            .buttonStyle(.plain)
                            .carattereApple(P.aggiungi)
                            .foregroundColor(P.coloreAggiungi)
                            .help("Aggiungi un potenziale cliente (⌘N)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(P.paddingColonna)
        .frame(minWidth: P.larghezzaMinimaColonna, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(P.superficieColonna)
        .overlay {
            if sopra {
                RoundedRectangle(cornerRadius: P.superficieColonna.raggio, style: .continuous)
                    .strokeBorder(Tema.Apple.Colore.accento, lineWidth: P.spessoreScelta)
                    .allowsHitTesting(false)
            }
        }
        .modifier(DestinazionePotenziali(attiva: modificabile, sopra: $sopra, arrivo: arrivo))
        .entrataCascata(2 + indice / 2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
    }
}

/// Il rilascio di una scheda trascinata (solo dove si scrive).
private struct DestinazionePotenziali: ViewModifier {
    let attiva: Bool
    @Binding var sopra: Bool
    let arrivo: (String) -> Void

    @ViewBuilder func body(content: Content) -> some View {
        if attiva {
            content.dropDestination(for: String.self) { voci, _ in
                guard let id = voci.first else { return false }
                arrivo(id)
                return true
            } isTargeted: { sopra = $0 }
        } else {
            content
        }
    }
}

/// La scheda si trascina solo dove si scrive.
private struct TrascinabilePotenziale: ViewModifier {
    let attiva: Bool
    let id: String

    @ViewBuilder func body(content: Content) -> some View {
        if attiva {
            content.draggable(id)
        } else {
            content
        }
    }
}

// MARK: - Scheda

private struct SchedaPotenziale: View {
    let potenziale: PotenzialeCliente
    let fonte: String?
    let modificabile: Bool
    let scelta: Bool
    let azioni: AzioniSchedaPotenziale
    @State private var sopra = false

    private typealias P = Tema.Apple.Potenziali

    var body: some View {
        let p = potenziale
        VStack(alignment: .leading, spacing: P.spazioPiccolo + 1) {
            HStack(alignment: .firstTextBaseline, spacing: P.spazioPiccolo + 2) {
                Text(p.nome)
                    .carattereApple(P.nomeScheda)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
                    .onTapGesture { azioni.dettaglio(p.id) }
                    .help("Apri il dettaglio")
                Spacer(minLength: 0)
            }
            if let fonte {
                Text(fonte)
                    .carattereApple(P.fonteScheda)
                    .foregroundColor(P.coloreFonte)
                    .lineLimit(1)
            }
            HStack(spacing: P.spazioPiccolo) {
                Text(TestiPassaparola.stima(p.patrimonioStimato))
                Text("·")
                Text(TestiPassaparola.probabilita(p.probabilita))
            }
            .carattereApple(p.patrimonioStimato == nil ? P.fonteScheda : P.cifraScheda)
            .foregroundColor(p.patrimonioStimato == nil ? Tema.Apple.Colore.inchiostro3 : Tema.Apple.Colore.inchiostro)
            BarraPiena(frazione: Double(p.probabilita ?? 0) / 100, colore: P.coloreBarra(p.probabilita), altezza: P.altezzaBarra,
                       raggio: P.raggioBarra, binario: P.binarioBarra)
            if p.informativaIl == nil && p.fase != .cliente {
                Text(TestiPassaparola.informativaDaDare)
                    .carattereApple(P.segno)
                    .foregroundColor(P.coloreSegno)
                    .padding(P.paddingSegno)
                    .background(Capsule().fill(P.fondoSegno))
            }
        }
        .padding(P.paddingScheda)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: P.raggioScheda, style: .continuous)
                .fill(P.fondoScheda)
                .ombraApple(sopra ? .schedaPotenzialeSopra : .schedaPotenziale)
        }
        .overlay {
            RoundedRectangle(cornerRadius: P.raggioScheda, style: .continuous)
                .strokeBorder(scelta ? Tema.Apple.Colore.accento : P.bordoScheda, lineWidth: scelta ? P.spessoreScelta : 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: P.raggioScheda, style: .continuous))
        .onTapGesture {
            if p.fase == .cliente, let cid = p.clienteId {
                azioni.dossier(cid)
            } else {
                azioni.avanti(p.id)
            }
        }
        .modifier(TrascinabilePotenziale(attiva: modificabile && p.fase != .cliente, id: p.id))
        .contextMenu {
            if modificabile {
                if p.fase.successiva != nil { Button("Avanti") { azioni.avanti(p.id) } }
                if p.fase != .cliente, p.fase.precedente != nil { Button("Indietro") { azioni.indietro(p.id) } }
                Button("Modifica…") { azioni.modifica(p.id) }
                if p.fase != .cliente { Button("Non interessato") { azioni.nonInteressato(p.id) } }
                Divider()
                Button("Elimina", role: .destructive) { azioni.elimina(p.id) }
            } else {
                Button("Apri il dettaglio") { azioni.dettaglio(p.id) }
            }
        }
        #if os(macOS)
        .onHover { sopra = $0 }
        #endif
        .accessibilityElement(children: .combine)
        .accessibilityHint(modificabile ? "Tocca per farla avanzare" : "")
    }
}

// MARK: - Dettaglio

struct DettaglioPotenziale: View {
    let stato: StatoShell
    let potenziale: PotenzialeCliente
    let modificabile: Bool
    let modifica: () -> Void
    let chiudi: () -> Void

    private typealias P = Tema.Apple.Potenziali

    var body: some View {
        let p = potenziale
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: P.spazioDettaglio) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: P.spazioPiccolo) {
                        Text("POTENZIALE CLIENTE · " + p.fase.titolo.uppercased())
                            .carattereApple(P.etichettaDettaglio)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        Text(p.nome)
                            .carattereApple(P.titoloDettaglio)
                            .foregroundColor(Tema.Apple.Colore.inchiostro)
                        if let f = TestiPassaparola.fonte(p, clienti: stato.dati.clienti) {
                            Text(f).carattereApple(Tema.Apple.Carattere.secondario).foregroundColor(Tema.Apple.Colore.inchiostro2)
                        }
                    }
                    Spacer()
                    Button("Chiudi", action: chiudi).buttonStyle(.apple)
                }
                riga("Email", p.email.isEmpty ? "—" : p.email)
                riga("Telefono", p.telefono.isEmpty ? "—" : p.telefono)
                riga("Patrimonio stimato", TestiPassaparola.stima(p.patrimonioStimato))
                riga("Probabilità", TestiPassaparola.probabilita(p.probabilita))
                riga("Chiusura prevista", p.chiusuraPrevista.map { Formati.dataEstesa.string(from: $0) } ?? "—")
                riga("Informativa data il", p.informativaIl.map { Formati.dataEstesa.string(from: $0) } ?? TestiPassaparola.informativaDaDare)
                riga("Consenso al contatto", p.consensoContatto.map { $0 ? "Sì" : "No" } ?? "Non chiesto")
                if !p.nota.isEmpty { riga("Nota", p.nota) }
                if !p.storia.isEmpty {
                    VStack(alignment: .leading, spacing: P.spazioPiccolo) {
                        Text("STORIA").carattereApple(P.etichettaDettaglio).foregroundColor(Tema.Apple.Colore.inchiostro2)
                        ForEach(Array(p.storia.enumerated()), id: \.offset) { _, c in
                            Text(c.fase.titolo + " · " + Formati.dataEstesa.string(from: c.il))
                                .carattereApple(Tema.Apple.Carattere.secondario)
                                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        }
                    }
                }
                if modificabile { pulsanti(p) }
                if p.diProva {
                    Text(TestiPassaparola.datiDiProva)
                        .carattereApple(Tema.Apple.Carattere.secondario)
                        .foregroundColor(Tema.Apple.Colore.inchiostro3)
                }
            }
            .padding(P.paddingDettaglio)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func riga(_ etichetta: String, _ valore: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: P.spazioRiga) {
            Text(etichetta)
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .frame(width: P.larghezzaEtichetta, alignment: .leading)
            Text(valore)
                .carattereApple(P.rigaDettaglio)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder private func pulsanti(_ p: PotenzialeCliente) -> some View {
        VStack(alignment: .leading, spacing: P.spazioMedio) {
            HStack(spacing: P.spazioMedio) {
                if p.fase == .daContattare || p.fase == .primoIncontro {
                    Button("Fissa il primo incontro") { _ = stato.fissaPrimoIncontro(p.id) }
                        .buttonStyle(.apple)
                }
                Button("Scrivigli") {
                    let canale: CanaleMessaggio = p.email.isEmpty ? .messaggi : .mail
                    stato.scriviAPotenziale(p.id, canale: canale)
                }
                .buttonStyle(.apple)
                .disabled(!p.contattabile)
                .help(p.contattabile ? "Apri Mail o Messaggi con il saluto: lo spedisci tu" : TestiPassaparola.scrivigliNonPronto)
                if p.fase != .cliente {
                    Button("Diventa cliente") {
                        chiudi()
                        stato.proponiCliente(p.id)
                    }
                    .buttonStyle(.applePrimario)
                }
            }
            HStack(spacing: P.spazioMedio) {
                Button("Modifica…", action: modifica).buttonStyle(.appleSobrio)
                if p.fase == .nonInteressato {
                    Button("Ripristina") { stato.spostaPotenziale(p.id, a: .daContattare) }.buttonStyle(.appleSobrio)
                }
            }
            if !p.contattabile {
                Text(TestiPassaparola.scrivigliNonPronto)
                    .carattereApple(Tema.Apple.Carattere.secondario)
                    .foregroundColor(Tema.Apple.Colore.inchiostro3)
            }
        }
    }
}

// MARK: - Modulo

struct ModuloPotenziale: View {
    @Environment(\.dismiss) private var chiudi
    @State var bozza: PotenzialeCliente
    let nuovo: Bool
    let rubrica: [Cliente]
    let salva: (PotenzialeCliente) -> Void
    @State private var testoStima = ""
    @State private var testoProbabilita = ""

    private typealias P = Tema.Apple.Potenziali

    init(bozza: PotenzialeCliente, nuovo: Bool, rubrica: [Cliente], salva: @escaping (PotenzialeCliente) -> Void) {
        _bozza = State(initialValue: bozza)
        self.nuovo = nuovo
        self.rubrica = rubrica
        self.salva = salva
        _testoStima = State(initialValue: bozza.patrimonioStimato.map { String(Int($0.rounded())) } ?? "")
        _testoProbabilita = State(initialValue: bozza.probabilita.map(String.init) ?? "")
    }

    private var valido: Bool { !bozza.nome.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        CorniceModulo(titolo: nuovo ? "Aggiungi un potenziale cliente" : "Modifica il potenziale cliente") {
            VStack(alignment: .leading, spacing: P.spazioRiga) {
                CampoModulo(etichetta: "Nome e cognome") {
                    TextField("Per esempio Paolo Ferretti", text: $bozza.nome).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Email") {
                    TextField("", text: $bozza.email).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Telefono") {
                    TextField("", text: $bozza.telefono).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Presentato da") {
                    MenuTendina(selezione: $bozza.presentatoDa,
                                opzioni: [(String?.none, "Nessun cliente")] + rubrica.map { (Optional($0.id), $0.nome) },
                                larghezza: 240)
                }
                if bozza.presentatoDa == nil {
                    CampoModulo(etichetta: "Fonte") {
                        TextField("Per esempio dal sito dello studio", text: Binding(
                            get: { bozza.fonte ?? "" },
                            set: { bozza.fonte = $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }))
                            .textFieldStyle(.roundedBorder)
                    }
                }
                CampoModulo(etichetta: "Patrimonio stimato (€)") {
                    TextField("Facoltativo", text: $testoStima).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Probabilità (%)") {
                    TextField("La scrivi tu, da 0 a 100", text: $testoProbabilita).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Chiusura prevista") {
                    CampoDataFacoltativa(data: $bozza.chiusuraPrevista, predefinita: Date())
                }
                CampoModulo(etichetta: "Fase") {
                    MenuTendina(selezione: $bozza.fase,
                                opzioni: FasePotenziale.allCases.filter { $0 != .cliente || bozza.fase == .cliente }.map { ($0, $0.titolo) },
                                larghezza: 200)
                }
                CampoModulo(etichetta: "Informativa data il") {
                    CampoDataFacoltativa(data: $bozza.informativaIl, predefinita: Date())
                }
                CampoModulo(etichetta: "Consenso al contatto") {
                    MenuTendina(selezione: $bozza.consensoContatto,
                                opzioni: [(Bool?.none, "Non chiesto"), (Optional(true), "Sì"), (Optional(false), "No")],
                                larghezza: 160)
                }
                CampoModulo(etichetta: "Nota") {
                    TextField("", text: $bozza.nota, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(2...4)
                }
                Text("L'informativa ai terzi la dai tu: Prisma ne registra solo la data. Senza informativa e consenso «Scrivigli» resta spento.")
                    .font(Tipo.campoEtichetta)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } piede: {
            Button("Annulla") { chiudi() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button(nuovo ? "Aggiungi" : "Salva") {
                var p = bozza
                p.patrimonioStimato = Self.numero(testoStima).flatMap { $0 >= 0 ? $0 : nil }
                p.probabilita = Self.numero(testoProbabilita).map { Int($0.rounded()) }.flatMap { (0...100).contains($0) ? $0 : nil }
                if p.presentatoDa != nil { p.fonte = nil }
                salva(p)
                chiudi()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!valido)
        }
        .frame(minWidth: Tema.Apple.Potenziali.larghezzaModulo, minHeight: Tema.Apple.Potenziali.altezzaModulo)
    }

    /// «180.000», «180000», «12,5» → numero; vuoto o illeggibile → nil.
    static func numero(_ testo: String) -> Double? {
        let t = testo.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard !t.isEmpty else { return nil }
        let senzaMigliaia = t.contains(",") ? t.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                                            : t.replacingOccurrences(of: ".", with: "")
        return Double(senzaMigliaia).flatMap { $0.isFinite ? $0 : nil }
    }
}
