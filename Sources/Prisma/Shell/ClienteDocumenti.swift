import SwiftUI

/// Scheda «Documenti» del dossier del cliente: l'app accorpata Documenti vive qui
/// (`apri(.documenti)` porta in Clienti su questa scheda).
/// In alto le tessere dei conteggi (fanno da filtro); sotto l'elenco a gruppi (Personali, Dei prodotti per posizione,
/// Da Prisma, Da collegare) e il documento scelto, protagonista: l'elenco si stringe alle sole tessere per lasciargli
/// lo spazio e si riapre con un clic. Si importa con il pulsante o trascinando i file: vanno a questo cliente.
/// Sta fuori dallo scorrimento del dossier: elenco e dettaglio scorrono da soli.
struct DocumentiCliente: View {
    @EnvironmentObject var stato: StatoShell
    let cliente: Cliente
    /// La ricerca è della vista: scrivere non ridisegna le altre finestre.
    @State private var ricerca = ""
    @State private var daEliminare: Documento?
    /// Il pannello di sistema per scegliere i file su iPhone e iPad.
    @State private var sceltaFile = false

    private var filtro: MotoreDocumenti.Filtro {
        var f = MotoreDocumenti.Filtro()
        f.raccolta = stato.vistaDocumenti.raccolta
        f.categoria = stato.vistaDocumenti.categoria
        f.canale = stato.vistaDocumenti.canale
        f.testo = ricerca
        return f
    }

    private var filtroAttivo: Bool {
        let v = stato.vistaDocumenti
        let conFiltri: Bool = v.raccolta != .tutti || v.categoria != nil || v.canale != nil
        let conRicerca: Bool = !ricerca.trimmingCharacters(in: .whitespaces).isEmpty
        return conFiltri || conRicerca
    }

    /// I gruppi della scheda: quelli dell'elenco (filtri e ricerca) riordinati nelle cartelle del cliente.
    /// Il testo dei documenti si legge dal disco senza tenerlo in memoria, e solo se serve.
    private func raggruppa(_ voci: [MotoreDocumenti.Voce]) -> [MotoreDocumenti.Gruppo] {
        let perTipo = MotoreDocumenti.elenco(voci, filtro: filtro, pagine: { stato.testoDocumento($0, memorizza: false) })
        let posizioni = stato.posizioniCliente(cliente.id).sorted { a, b in
            if (a.stato == .inEssere) != (b.stato == .inEssere) { return a.stato == .inEssere }
            return a.nome.localizedCaseInsensitiveCompare(b.nome) == .orderedAscending
        }
        return MotoreDocumenti.cartelle(perTipo, posizioni: posizioni) { id in
            stato.prodotto(id).map { (nome: $0.nome, canale: $0.canale) }
        }
    }

    var body: some View {
        let voci = stato.vociDocumenti(cliente.id)
        Group {
            if voci.isEmpty {
                VuotoDocumenti(nome: cliente.nome, importa: importa)
            } else {
                let gruppi = raggruppa(voci)
                let mostrate = gruppi.flatMap { $0.voci.map(\.voce) }
                // Il documento scelto se è tra quelli mostrati, altrimenti il primo: documentoSelezionato non si riscrive
                let scelta = mostrate.first { $0.id == stato.documentoSelezionato } ?? mostrate.first
                VStack(spacing: 0) {
                    fascia(voci)
                        .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                    colonne(gruppi: gruppi, scelta: scelta, totale: voci.count)
                        .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Tema Apple: tessere, pulsanti, tendine, elenco ed etichette del canale come nel resto del dossier
        .altreAppApple()
        .gestioneDocumenti(nome: cliente.nome, scelta: $sceltaFile, daEliminare: $daEliminare, allinea: allinea)
    }

    // MARK: - Tessere dei conteggi

    /// Quanti documenti, quanti da leggere, con differenze, da collegare: un clic mostra solo quelli, un secondo
    /// clic torna a tutti. A destra «Importa…».
    private func fascia(_ voci: [MotoreDocumenti.Voce]) -> some View {
        let conti = MotoreDocumenti.conteggi(voci).raccolte
        let raccolta = stato.vistaDocumenti.raccolta
        let c = Tema.Colore.DossierCliente.self
        return HStack(spacing: Tema.Misura.Componenti.spazioTessere) {
            tessera("Documenti", conti[.tutti] ?? voci.count, tono: nil, raccolta: .tutti, attiva: raccolta == .tutti)
            tessera("Da leggere", conti[.daLeggere] ?? 0, tono: c.daLeggere, raccolta: .daLeggere, attiva: raccolta == .daLeggere)
            tessera("Con differenze", conti[.conDifferenze] ?? 0, tono: c.conDifferenze, raccolta: .conDifferenze,
                    attiva: raccolta == .conDifferenze)
            tessera("Da collegare", conti[.daCollegare] ?? 0, tono: c.daCollegare, raccolta: .daCollegare,
                    attiva: raccolta == .daCollegare)
            Spacer(minLength: 0)
            if stato.vistaDocumenti.categoria != nil || stato.vistaDocumenti.canale != nil {
                Button(action: mostraTutti) { Label("Togli i filtri", systemImage: "xmark.circle") }
                    .buttonStyle(StileVetro(taglia: .compatta))
            }
            Button(action: importa) { Label("Importa…", systemImage: "doc.badge.plus") }
                .buttonStyle(StileVetro())
                .disabled(stato.solaLettura)
                .help("Aggiungi documenti di \(cliente.nome): PDF o foto. Puoi anche trascinarli qui.")
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(Tema.Misura.DossierCliente.fasciaDocumenti)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bordoBasso(Tema.Apple.Colore.separatore)
    }

    private func tessera(_ titolo: String, _ valore: Int, tono: Color?, raccolta: RaccoltaDocumenti, attiva: Bool) -> some View {
        TesseraFiltroDocumenti(titolo: titolo, valore: valore, tono: tono, attiva: attiva && raccolta != .tutti) {
            // Un secondo clic sulla stessa raccolta torna a tutti i documenti
            stato.vistaDocumenti.raccolta = attiva ? .tutti : raccolta
        }
    }

    // MARK: - Elenco e dettaglio

    /// L'elenco e il documento. Con un documento aperto l'elenco resta stretto (le sole tessere) e il foglio prende
    /// lo spazio; si apre con il suo pulsante e da solo (scheda molto larga o filtro attivo) solo se alla pagina resta
    /// lo spazio minimo. Aperto dal consulente dove accanto la pagina non ci starebbe, l'elenco va sopra il documento.
    private func colonne(gruppi: [MotoreDocumenti.Gruppo], scelta: MotoreDocumenti.Voce?, totale: Int) -> some View {
        GeometryReader { g in
            if elencoAperto(g.size.width) {
                if g.size.width - Tema.Misura.Documenti.elencoAperto >= Tema.Misura.Documenti.anteprimaMinima {
                    HStack(spacing: 0) {
                        elenco(gruppi, scelta: scelta, totale: totale)
                            .colonnaFissa(Tema.Misura.Documenti.elencoAperto)
                        DivisoreColonne()
                        dettaglio(scelta)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        elenco(gruppi, scelta: scelta, totale: totale)
                            .frame(height: g.size.height * Tema.Misura.DossierCliente.quotaElencoImpilato)
                            .bordoBasso(Tema.Apple.Colore.separatore)
                        dettaglio(scelta)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                HStack(spacing: 0) {
                    ElencoStrettoDocumenti(gruppi: gruppi, scelta: scelta?.id, importa: importa) {
                        stato.vistaDocumenti.elenco = true
                    }
                    .colonnaFissa(Tema.Misura.Documenti.elencoStretto)
                    DivisoreColonne()
                    dettaglio(scelta)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    /// L'elenco è aperto se il consulente l'ha chiesto o, in automatico, se la scheda è molto larga o un filtro è
    /// attivo, ma solo se accanto all'elenco e al pannello dei dati la pagina ha ancora il suo spazio minimo:
    /// altrimenti si stringe da solo alle tessere e il documento resta grande.
    private func elencoAperto(_ larghezza: CGFloat) -> Bool {
        if let scelta = stato.vistaDocumenti.elenco { return scelta }
        let m = Tema.Misura.Documenti.self
        let allaPagina: CGFloat = larghezza - m.elencoAperto - m.scheda
        guard allaPagina >= m.anteprimaMinima else { return false }
        return filtroAttivo || larghezza >= m.elencoAutomatico
    }

    private func elenco(_ gruppi: [MotoreDocumenti.Gruppo], scelta: MotoreDocumenti.Voce?, totale: Int) -> some View {
        ElencoDocumenti(gruppi: gruppi, scelta: scelta?.id, totale: totale, ricerca: $ricerca,
                        filtrato: filtroAttivo, importa: importa, mostraTutti: mostraTutti, elimina: chiedi) {
            stato.vistaDocumenti.elenco = false
        }
    }

    @ViewBuilder private func dettaglio(_ scelta: MotoreDocumenti.Voce?) -> some View {
        if let v = scelta {
            DettaglioDocumento(voce: v, chiediEliminazione: chiedi)
        } else {
            Text("Nessun documento con questi filtri")
                .font(Tema.Apple.AltreApp.corpoPiccolo.fontLeggibile)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Azioni

    /// Un documento scelto da fuori (⌘K, notifiche, Vera, Prodotti) che i filtri nasconderebbero: i filtri tornano a
    /// «Tutti» e la ricerca si svuota, così si vede nell'elenco.
    private func allinea() {
        guard let id = stato.documentoSelezionato, let d = stato.documento(id), d.clienteId == cliente.id else { return }
        let visibili = raggruppa(stato.vociDocumenti(cliente.id)).flatMap { $0.voci.map(\.id) }
        guard !visibili.contains(id) else { return }
        mostraTutti()
    }

    private func mostraTutti() {
        stato.vistaDocumenti.raccolta = .tutti
        stato.vistaDocumenti.categoria = nil
        stato.vistaDocumenti.canale = nil
        ricerca = ""
    }

    private func chiedi(_ d: Documento) {
        daEliminare = d
    }

    private func importa() {
        ImportaDocumenti.scegli(stato, scelta: $sceltaFile)
    }
}

// MARK: - Elenco stretto

/// L'elenco stretto accanto al documento aperto: le sole tessere, gruppo per gruppo (un filo tra i gruppi), con il
/// cerchio «da leggere»; il titolo nell'aiuto. In cima il pulsante che riapre l'elenco, in fondo «+».
private struct ElencoStrettoDocumenti: View {
    @EnvironmentObject var stato: StatoShell
    let gruppi: [MotoreDocumenti.Gruppo]
    let scelta: String?
    let importa: () -> Void
    let apri: () -> Void

    var body: some View {
        let m = Tema.Misura.Documenti.self
        VStack(spacing: 0) {
            PulsanteIcona(simbolo: "sidebar.left", aiuto: "Mostra l'elenco dei documenti", azione: apri)
                .frame(maxWidth: .infinity)
                .frame(height: Misure.ColonneStrumento.testata)
                .bordoBasso(Tema.Apple.Colore.separatore)
            ScrollView {
                VStack(spacing: m.spazioTessereStrette) {
                    ForEach(Array(gruppi.enumerated()), id: \.element.id) { i, g in
                        if i > 0 {
                            Rectangle()
                                .fill(Tema.Apple.Colore.separatore)
                                .frame(width: m.filoGruppoStretto, height: Misure.ColonneStrumento.filo)
                        }
                        ForEach(g.voci) { t in tessera(t) }
                    }
                }
                .padding(m.margineTessereStrette)
                .frame(maxWidth: .infinity)
            }
            PulsanteIcona(simbolo: "plus", aiuto: "Aggiungi documenti (anche trascinandoli qui)", taglia: .compatta, azione: importa)
                .disabled(stato.solaLettura)
                .frame(maxWidth: .infinity)
                .frame(height: Misure.ColonneStrumento.piede)
                .background(Colori.ColonneStrumento.piede)
                .bordoAlto(Tema.Apple.Colore.separatore)
        }
    }

    private func tessera(_ t: MotoreDocumenti.VoceTrovata) -> some View {
        let m = Tema.Misura.Documenti.self
        let d = t.voce.documento
        let attiva: Bool = t.id == scelta
        let daLeggere: Bool = MotoreDocumenti.appartiene(t.voce, a: .daLeggere)
        let forma = FormaVetro.arrotondata(Tema.Raggio.Documenti.tesseraStretta)
        let fondo: Color = attiva ? Tema.Colore.Documenti.tesseraScelta : Color.clear
        return Button {
            stato.documentoSelezionato = d.id
        } label: {
            TesseraDocumento(categoria: d.genere, grande: true)
                .padding(m.spazioStatoRiga)
                .background { forma.fill(fondo) }
                .overlay {
                    if attiva {
                        forma.strokeBorder(Tema.Colore.Documenti.bordoTesseraScelta, lineWidth: m.bordoNuovo)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if daLeggere {
                        Circle()
                            .strokeBorder(Tema.Colore.Documenti.nuovo, lineWidth: m.bordoNuovo)
                            .frame(width: m.puntoNuovo, height: m.puntoNuovo)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .help(daLeggere ? "\(d.titolo) · da leggere" : d.titolo)
        .accessibilityLabel(d.titolo)
    }
}
