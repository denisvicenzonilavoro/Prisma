import SwiftUI

// La traccia dell'impegno nel tema Apple (Design/template-apple-specifica.md §4.4.2, riferimenti analisi-agenda/
// G08-G14): nasce dall'impegno toccato nella giornata (PresentatoreDettaglio, 860×500).
//
//   ◯  REVISIONE PERIODICA · MARTEDÌ 3 NOVEMBRE                         [Alleanza]   ✕
//      Il punto sul progetto casa
//      Giulia Rossi · 09:30 – 10:15 · In studio
//   PUNTI DA TOCCARE                                   ┌ Patrimonio netto ┐
//   ○ Temi scelti: Previdenza, Risparmio               │ 184.300 €        │
//   ○ Dal riesame del 12 ottobre: …                    ├ Dati per l'analisi┤
//   ○ …                                                │ 92%  ▬▬▬▬▬▬▬▬▬   │
//   [Preparami l'incontro] [Apri il dossier] [Presenta al cliente]        Tutti i dettagli
//
// - I punti vengono dalla preparazione che Prisma ha già: i temi dell'incontro preparato (AppIncontri), la
//   proposta o la posizione di cui si parla, le priorità del cliente (MotoreBisogni), cosa è cambiato dal riesame
//   precedente (memoria del riesame) e l'ordine del giorno del riesame (MotoreRiesame), le priorità alte prima.
//   Nessuna cifra scritta a mano (§4.9 n. 8): patrimonio e completezza vengono dai motori.
// - «Preparami l'incontro»: i punti si spuntano uno alla volta (ListaTiPreparo); alla fine il fascicolo
//   dell'appuntamento (preparaFascicolo(per:)) si apre in Prospetti, già composto.
// - «Apri il dossier» apre il cliente dell'impegno; «Presenta al cliente» presenta il fascicolo dell'impegno,
//   di quel cliente (§4.9 n. 10), con la modalità cliente; «Tutti i dettagli» porta al dettaglio di sempre
//   (modifica, concluso, esito della proposta, attività collegate) nella vista Giorno.

extension StatoShell {
    /// I punti da toccare nell'incontro, dalla preparazione esistente (al massimo `Traccia.massimoPunti`).
    func puntiDaToccare(_ e: Appuntamento) -> [String] {
        var punti: [String] = []
        // I temi scelti nella preparazione dell'incontro, se l'incontro è già stato preparato
        if let i = dati.incontri.first(where: { $0.appuntamentoId == e.id }), !i.temi.isEmpty,
           i.temi.count < AreaAnalisi.allCases.count {
            punti.append("Temi scelti: " + i.temi.map(\.nome).joined(separator: ", "))
        }
        // La proposta o la posizione di cui si parla
        if let pid = e.posizioneId, let p = posizioni.first(where: { $0.id == pid }) {
            punti.append(p.stato == .proposta ? "La proposta: \(p.nome)" : "La posizione: \(p.nome)")
        }
        guard cliente(e.clienteId) != nil else { return Self.puntiOppureNote(punti, e) }
        // Le priorità del cliente
        let profilo = cliente(e.clienteId)?.bisogni ?? ProfiloBisogni()
        let priorita = Array(MotoreBisogni.priorita(bisogniRilevati(e.clienteId), profilo: profilo).prefix(3))
        if !priorita.isEmpty {
            punti.append("Priorità del cliente: " + priorita.map(\.nome).joined(separator: ", "))
        }
        // Cosa è cambiato dal riesame precedente (senza fotografie la memoria non si calcola)
        if dati.fotografie.contains(where: { $0.clienteId == e.clienteId }),
           let memoria = memoriaRiesame(e.clienteId), let precedente = memoria.precedente {
            let data = Formati.giornoMese.string(from: precedente.data)
            for v in memoria.variazioni.prefix(2) {
                punti.append("Dal riesame del \(data): \(v.testo)")
            }
        }
        // L'ordine del giorno del riesame: prima le priorità alte
        if let r = riesameCliente(e.clienteId) {
            let alte = r.punti.filter { $0.priorita == .alta }
            let altre = r.punti.filter { $0.priorita != .alta }
            for p in alte + altre where !punti.contains(p.titolo) {
                punti.append(p.titolo)
            }
        }
        return Self.puntiOppureNote(punti, e)
    }

    /// I punti trovati (al massimo quelli che stanno nella traccia) oppure, se non ce ne sono, le note dell'impegno.
    private static func puntiOppureNote(_ punti: [String], _ e: Appuntamento) -> [String] {
        let massimo = Tema.Apple.Agenda.Traccia.massimoPunti
        if !punti.isEmpty { return Array(punti.prefix(massimo)) }
        let note = e.note.trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? ["Ascoltare il cliente: cosa è cambiato e cosa vuole fare"] : [note]
    }

    /// «Presenta al cliente»: il fascicolo dell'impegno, con i report adatti al tipo d'incontro, a tutto schermo
    /// in modalità cliente (le annotazioni vanno all'appuntamento).
    func presentaImpegno(_ e: Appuntamento) {
        clienteAttivoId = e.clienteId
        let posizione = e.posizioneId.flatMap { id in posizioni.first { $0.id == id } }
        sceltaFascicolo = TipoProspetto.perIncontro(e, posizione: posizione)
        fascicoloAppuntamento = e.id
        prospetto = .fascicolo
        guard let d = documentoFascicolo() else {
            mostraAvviso("Il fascicolo dell'incontro non ha ancora report da mostrare")
            return
        }
        presenta(d)
    }

    /// «Tutti i dettagli»: il dettaglio di sempre dell'appuntamento, nella vista Giorno.
    func mostraDettaglioImpegno(_ e: Appuntamento) {
        giornoAgenda = Calendar.current.startOfDay(for: e.inizio)
        vistaAgenda = .giorno
        occasioneSelezionata = nil
        attivitaSelezionata = nil
        appuntamentoSelezionato = e.id
    }
}

/// La traccia di un impegno, dentro il dettaglio aperto (già a misura piena).
struct TracciaImpegnoApple: View {
    let idDettaglio: String
    @Environment(StatoShell.self) var stato
    @Environment(\.statoDettaglioApple) private var dettaglio
    @State private var preparando = false

    private static let prefisso = "impegno-"

    /// L'id del dettaglio nato dall'impegno `eventoId`.
    static func id(per eventoId: String) -> String { prefisso + eventoId }

    private var eventoId: String { String(idDettaglio.dropFirst(Self.prefisso.count)) }

    var body: some View {
        let _ = ContaCorpi.segna()
        if let e = stato.appuntamento(eventoId) {
            corpo(e)
        }
    }

    private func corpo(_ e: Appuntamento) -> some View {
        let t = Tema.Apple.Agenda.Traccia.self
        let cliente = stato.cliente(e.clienteId)
        let punti = stato.puntiDaToccare(e)
        return VStack(alignment: .leading, spacing: 0) {
            testata(e, cliente: cliente)
            HStack(alignment: .top, spacing: t.spazioColonne) {
                ScrollView(.vertical, showsIndicators: false) {
                    ListaTiPreparo(titolo: TestiAgendaApple.puntiDaToccare, voci: punti, avviata: preparando,
                                   poi: { fascicoloPronto(e, cliente: cliente) })
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                if let c = cliente {
                    tile(c)
                        .frame(width: t.larghezzaTile)
                }
            }
            .padding(.top, t.corpoSopra)
            .frame(maxHeight: .infinity, alignment: .top)
            piede(e, cliente: cliente)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Testata

    private func testata(_ e: Appuntamento, cliente: Cliente?) -> some View {
        let t = Tema.Apple.Agenda.Traccia.self
        let colore = Tema.Apple.Agenda.colore(cliente)
        let margine = max(0, t.margineChiudi - Tema.Apple.Misura.Padding.dettaglio.trailing)
        let canale = stato.canaleAppuntamento(e)
        return HStack(alignment: .center, spacing: t.spazioTestata) {
            avatar(cliente, colore: colore)
            VStack(alignment: .leading, spacing: t.spazioTesti) {
                Text(etichetta(e))
                    .carattereApple(t.etichetta)
                    .foregroundColor(colore)
                    .lineLimit(1)
                Text(e.titolo)
                    .carattereApple(t.titolo)
                    .foregroundColor(t.coloreTitolo)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(sotto(e, cliente: cliente))
                    .carattereApple(t.sotto)
                    .foregroundColor(t.coloreSotto)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if let canale {
                EtichettaCanaleApple(canale: canale)
            }
        }
        .padding(.trailing, margine)
    }

    @ViewBuilder private func avatar(_ cliente: Cliente?, colore: Color) -> some View {
        let t = Tema.Apple.Agenda.Traccia.self
        if let c = cliente {
            AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: t.avatar)
        } else {
            Image(systemName: "checkmark")
                .carattereApple(t.spuntaSenzaCliente)
                .foregroundColor(t.coloreSpunta)
                .frame(width: t.avatar, height: t.avatar)
                .background { Circle().fill(colore) }
                .accessibilityHidden(true)
        }
    }

    /// «REVISIONE PERIODICA · MARTEDÌ 3 NOVEMBRE» (il maiuscolo lo fa il carattere).
    private func etichetta(_ e: Appuntamento) -> String {
        let base = "\(e.tipo.nome) · \(TestiAgendaApple.titoloGiorno(e.inizio))"
        return e.stato == .concluso ? base + " · concluso" : base
    }

    /// «Giulia Rossi · 09:30 – 10:15 · In studio».
    private func sotto(_ e: Appuntamento, cliente: Cliente?) -> String {
        let quando = TestiAgendaApple.quando(e)
        guard let c = cliente else { return quando }
        return "\(c.nome) · \(quando)"
    }

    // MARK: Tile del cliente

    private func tile(_ c: Cliente) -> some View {
        let t = Tema.Apple.Agenda.Traccia.self
        let r = stato.riepilogoPosizioniCliente(c.id)
        let completezza = stato.completezzaCliente(c.id)
        return VStack(alignment: .leading, spacing: t.spazioTile) {
            riquadro("Patrimonio netto") {
                NumeroCheConta(r.patrimonioNetto, formato: .euro, indice: 0)
                    .carattereApple(t.cifraTile)
                    .foregroundColor(t.coloreCifraTile)
                    .lineLimit(1)
                    .minimumScaleFactor(t.scalaMinimaCifra)
            }
            if let comp = completezza {
                riquadro("Dati per l'analisi") {
                    NumeroCheConta(Double(comp.percentuale), formato: .percentuale, indice: 1)
                        .carattereApple(t.cifraTile)
                        .foregroundColor(t.coloreCifraTile)
                        .lineLimit(1)
                    BarraPiena(frazione: Double(comp.percentuale) / 100,
                               colore: comp.percentuale >= t.sogliaVerde ? t.barraCompleta : t.barraParziale)
                        .frame(height: Tema.Apple.Grafico.Barra.altezza)
                        .padding(.top, t.barraSopra)
                }
            }
            Text(TestiPortafoglioApple.cifreDaiMotori)
                .carattereApple(t.nota)
                .foregroundColor(t.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func riquadro<Contenuto: View>(_ nome: String, @ViewBuilder contenuto: () -> Contenuto) -> some View {
        let t = Tema.Apple.Agenda.Traccia.self
        return VStack(alignment: .leading, spacing: t.spazioTesti) {
            Text(nome)
                .carattereApple(t.nomeTile)
                .foregroundColor(t.coloreNomeTile)
                .lineLimit(1)
            contenuto()
        }
        .padding(t.paddingTile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(t.superficieTile, raggio: t.raggioTile)
    }

    // MARK: Piede

    private func piede(_ e: Appuntamento, cliente: Cliente?) -> some View {
        let t = Tema.Apple.Agenda.Traccia.self
        return HStack(spacing: t.spazioPulsanti) {
            Button { preparando = true } label: { Text("Preparami l'incontro") }
                .buttonStyle(.applePrimarioGrande)
                .disabled(preparando)
            if cliente != nil {
                Button {
                    dettaglio?.chiudi(subito: true)
                    stato.apriCliente(e.clienteId)
                } label: { Text("Apri il dossier") }
                    .buttonStyle(.appleGrande)
                Button {
                    dettaglio?.chiudi(subito: true)
                    stato.presentaImpegno(e)
                } label: { Text("Presenta al cliente") }
                    .buttonStyle(.appleGrande)
                    .help("Il fascicolo dell'incontro a tutto schermo, in modalità cliente")
            }
            Spacer(minLength: 0)
            Button {
                dettaglio?.chiudi(subito: true)
                stato.mostraDettaglioImpegno(e)
            } label: { Text("Tutti i dettagli") }
                .buttonStyle(.appleSobrio)
                .help("Modifica, segna concluso, esito della proposta e attività collegate")
        }
    }

    /// I punti sono spuntati: la traccia si chiude e il fascicolo dell'appuntamento si apre in Prospetti.
    private func fascicoloPronto(_ e: Appuntamento, cliente: Cliente?) {
        guard preparando else { return }
        preparando = false
        dettaglio?.chiudi(subito: true)
        stato.preparaFascicolo(per: e)
        stato.mostraAvviso("Fascicolo per \(cliente?.nome ?? e.titolo) pronto in Prospetti")
    }
}
