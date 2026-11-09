import SwiftUI

// «Lascia cadere qui» (Vera/BRIEF.md, funzione 9; template «Lascia cadere qui») sotto le risposte di Vera: i dati letti da
// correggere uno per uno prima di «Conferma» (con la pagina da cui vengono, e il valore delle posizioni lette in un
// estratto conto), la scelta del cliente quando nel documento ce n'è più d'uno, e la card «Archiviati da Vera · oggi»
// nella colonna di Vera, con il foglietto colorato del tipo (template `rigaD`) e dove è andato ogni documento.

private typealias F = Tema.Apple.FaseDueVera

/// I dati letti di una scheda «Lascia cadere qui» ancora da confermare: ogni campo si corregge nel suo riquadro (Invio o
/// uscendo dal campo), la scheda si aggiorna (anche il promemoria della scadenza e il documento d'identità).
struct CampiLettiVeraVista: View {
    @Environment(StatoShell.self) var stato
    let messaggio: String
    let scheda: SchedaConfermaVera

    private var campi: [CampoEstratto] {
        let json = scheda.azioni.first { $0.strumento == RegistroStrumenti.documentiArchivia }?.argomenti["campi"]
        return (json?.data(using: .utf8)).flatMap { try? JSONDecoder().decode([CampoEstratto].self, from: $0) } ?? []
    }

    var body: some View {
        let posizioni = scheda.azioni.filter { $0.strumento == LasciaCadereVera.strumentoPosizione && !$0.tolta }
        if scheda.stato == .daConfermare, !campi.isEmpty || !posizioni.isEmpty {
            VStack(alignment: .leading, spacing: F.spazioCampi) {
                Text("Dati letti · correggili prima di confermare").carattereApple(F.titoloCampiLetti).foregroundColor(F.coloreTitoloSezione)
                ForEach(campi, id: \.chiave) { c in
                    RigaCampoLetto(etichetta: c.chiave.nome, pagina: c.pagina, valore: c.valore) { nuovo in
                        stato.correggiCampoCaduto(messaggio: messaggio, campo: c.chiave, valore: nuovo)
                    }
                }
                ForEach(posizioni) { a in
                    RigaCampoLetto(etichetta: a.argomenti["nome"] ?? "Posizione", pagina: Int(a.argomenti["pagina"] ?? "") ?? 1,
                                   valore: Double(a.argomenti["valore"] ?? "").map { String(format: "%.2f", $0).replacingOccurrences(of: ".", with: ",") } ?? "",
                                   larghezza: F.larghezzaValorePosizione, suffisso: "€") { nuovo in
                        if let v = EstrattoreDocumento.numero(nuovo) {
                            stato.correggiPosizioneCaduta(messaggio: messaggio, azione: a.id, valore: v)
                        }
                    }
                }
            }
            .padding(F.paddingCampiLetti)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            .padding(.top, F.sopraScheda)
        }
    }
}

/// Una riga dei dati letti: l'etichetta, il campo modificabile, la pagina.
private struct RigaCampoLetto: View {
    let etichetta: String
    let pagina: Int
    let valore: String
    var larghezza: CGFloat? = nil
    var suffisso: String? = nil
    let correggi: (String) -> Void
    @State private var testo = ""
    @FocusState private var attivo: Bool

    var body: some View {
        HStack(spacing: F.spazioScelta) {
            Text(etichetta).carattereApple(F.etichettaCampo).foregroundColor(F.coloreFonte)
                .lineLimit(1)
                .frame(width: F.larghezzaEtichettaCampo, alignment: .leading)
            TextField(etichetta, text: $testo)
                .textFieldStyle(.roundedBorder)
                .font(F.valoreCampo.font)
                .frame(maxWidth: larghezza ?? .infinity)
                .focused($attivo)
                .onSubmit { if testo != valore { correggi(testo) } }
                .onChange(of: attivo) { a in if !a, testo != valore { correggi(testo) } }
            if let suffisso { Text(suffisso).carattereApple(F.etichettaCampo).foregroundColor(F.coloreFonte) }
            Spacer(minLength: 0)
            Text("pag. \(pagina)").carattereApple(F.fonteSezione).foregroundColor(F.coloreFonte)
        }
        .onAppear { testo = valore }
        .onChange(of: valore) { v in if !attivo { testo = v } }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(etichetta), letto a pagina \(pagina)"))
    }
}

/// La scelta del cliente dalla risposta (più clienti nel documento): un pulsante per cliente. Dopo un riavvio la copia
/// non c'è più: Vera chiede di trascinarlo di nuovo.
struct SceltaClienteCadutoVista: View {
    @Environment(StatoShell.self) var stato
    let messaggio: String

    var body: some View {
        if let x = stato.scelteClienteCaduto[messaggio] {
            HStack(spacing: F.spazioScelta) {
                ForEach(x.possibili, id: \.self) { id in
                    if let c = stato.cliente(id) {
                        Button { _ = stato.scegliClienteCaduto(messaggio: messaggio, cliente: id, chiave: stato.chiaveConversazione) } label: {
                            HStack(spacing: F.spazioScelta) {
                                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: F.avatarScelta)
                                Text(c.nome)
                            }
                        }
                        .buttonStyle(.apple)
                        .fixedSize()
                        .disabled(stato.veraInCorso || stato.solaLettura)
                        .help("Archivia il documento in \(c.nome)")
                    }
                }
            }
            .padding(.top, F.sopraScheda)
        } else {
            Text("Trascinalo di nuovo su Vera per scegliere il cliente.")
                .carattereApple(F.fonti).foregroundColor(F.coloreFonte)
                .padding(.top, F.sopraScheda)
        }
    }
}

/// «Archiviati da Vera · oggi» nella colonna di Vera: gli ultimi documenti archiviati oggi con «Lascia cadere qui».
/// Un clic apre il documento. Senza archiviati la card non c'è.
struct ArchiviatiOggiVeraVista: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let col = Tema.Apple.Vera.Colonna.self
        let elenco = stato.archiviatiDaVeraOggi()
        if !elenco.isEmpty {
            VStack(alignment: .leading, spacing: F.spazioArchiviati) {
                HStack {
                    Text("Archiviati da Vera").carattereApple(col.etichetta).foregroundColor(col.coloreEtichetta)
                    Spacer(minLength: 0)
                    Text("oggi · \(elenco.count)").carattereApple(F.dettaglioArchiviato).foregroundColor(F.coloreFonte)
                }
                ForEach(elenco.prefix(F.massimoArchiviati)) { a in
                    Button { stato.apriDocumentoVera(a.documentoId) } label: { riga(a) }
                        .buttonStyle(StileSemplice())
                        .help("Apri «\(a.titolo)»")
                }
            }
            .multilineTextAlignment(.leading)
            .padding(col.paddingScheda)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(col.superficieScheda, raggio: col.raggioScheda)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Archiviati da Vera oggi: \(elenco.count)"))
        }
    }

    private func riga(_ a: ArchiviatoVera) -> some View {
        let colore = F.coloreTipo(a.tipo, categoria: a.categoria)
        return HStack(alignment: .top, spacing: F.spazioScelta) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1, style: .continuous).fill(colore).frame(height: F.testataFoglietto)
                Spacer(minLength: 0)
            }
            .padding(3)
            .frame(width: F.foglietto.width, height: F.foglietto.height)
            .background(RoundedRectangle(cornerRadius: F.raggioFoglietto, style: .continuous).fill(F.fondoFoglietto))
            .ombraApple(.carta)
            VStack(alignment: .leading, spacing: 1) {
                Text(a.titolo).carattereApple(F.titoloArchiviato).foregroundColor(Tema.Apple.Colore.inchiostro).lineLimit(1)
                Text("→ \(a.cliente) · \(a.dove)").carattereApple(F.dettaglioArchiviato).foregroundColor(colore).lineLimit(1)
                Text(a.dettaglio).carattereApple(F.dettaglioArchiviato).foregroundColor(F.coloreFonte).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}
