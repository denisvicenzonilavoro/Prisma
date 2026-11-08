import SwiftUI

// La scheda «Tre livelli» sotto la risposta di Vera (Design/template-vera.html, «// 17 · TRE LIVELLI»): il selettore
// «Per te / Per Marco / In una pagina», la versione tecnica in punti, quella semplice con le cifre essenziali in
// evidenza, la pagina su carta bianca con le barre delle cifre e l'avvertenza in fondo. Sotto, chi ha scritto (Qwen o
// Prisma) e i pulsanti «Salva nei Documenti» e «Manda a Marco», che preparano la scheda «Conferma».

private typealias F = Tema.Apple.FaseTreVera
private typealias T = Tema.Apple.TreLivelli
private typealias Carta = Tema.Apple.Carta

struct TreLivelliVeraVista: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    let id: String
    @State private var livello: LivelloTreLivelli

    init(id: String, livello: LivelloTreLivelli) {
        self.id = id
        _livello = State(initialValue: livello)
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        if let s = stato.trelivelliSpiegazione(id) {
            let nome = TreLivelliVera.primoNome(s.nomeCliente)
            VStack(alignment: .leading, spacing: T.spazio) {
                SegmentatoPillola(selezione: $livello, valori: LivelloTreLivelli.allCases,
                                  titolo: { $0.etichetta(cliente: nome) })
                    .fixedSize()
                Group {
                    switch livello {
                    case .tecnico: tecnico(s)
                    case .cliente: cliente(s, nome: nome)
                    case .pagina: pagina(s)
                    }
                }
                .id(livello)
                .transition(.opacity)
                piede(s, nome: nome)
            }
            .animation(Tema.Apple.Moto.animazione(Tema.Apple.Moto.Segmentato.animazioneTesto, calmo: calmo, istantanea: istantanea), value: livello)
            .padding(.top, F.sopraScheda)
        }
    }

    // MARK: Per te · tecnica

    private func tecnico(_ s: SpiegazioneTreLivelli) -> some View {
        VStack(alignment: .leading, spacing: T.spazioRighe) {
            Text("Per te · tecnica").carattereApple(T.etichettaLivello).foregroundColor(Tema.Apple.trelivelliRubino)
            ForEach(Array(s.tecnico.enumerated()), id: \.offset) { _, riga in
                HStack(alignment: .firstTextBaseline, spacing: T.spazioPunto) {
                    Text("•").carattereApple(T.rigaTecnica).foregroundColor(F.coloreDettaglio)
                    Text(riga).carattereApple(T.rigaTecnica).fixedSize(horizontal: false, vertical: true)
                }
            }
            // Le note (dati mancanti, ipotesi da confermare) solo nella versione per te: non vanno al cliente
            if !s.note.isEmpty {
                VStack(alignment: .leading, spacing: T.spazioNote) {
                    ForEach(Array(s.note.enumerated()), id: \.offset) { _, n in
                        HStack(alignment: .firstTextBaseline, spacing: T.spazioPunto) {
                            Image(systemName: "exclamationmark.circle").foregroundColor(F.arancio)
                            Text(n).carattereApple(F.dettaglioRiga).foregroundColor(F.coloreDettaglio).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, T.sopraNote)
            }
        }
        .padding(T.paddingScheda)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
    }

    // MARK: Per il cliente · semplice

    private func cliente(_ s: SpiegazioneTreLivelli, nome: String) -> some View {
        VStack(alignment: .leading, spacing: T.spazioRighe) {
            Text("Per \(nome) · semplice").carattereApple(T.etichettaLivello).foregroundColor(Tema.Apple.trelivelliRubino)
            Text(Self.conEvidenza(s.cliente, cifre: s.essenziali))
                .carattereApple(T.testoCliente)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: T.larghezzaTestoCliente, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(T.paddingScheda)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
    }

    /// Il testo semplice con le cifre essenziali in grassetto (template: «ti mancheranno circa **1.100 € al mese**»).
    static func conEvidenza(_ testo: String, cifre: [CifraTreLivelli]) -> AttributedString {
        var a = AttributedString(testo)
        for c in cifre where !c.testo.isEmpty {
            var da = a.startIndex
            while da < a.endIndex, let r = a[da...].range(of: c.testo) {
                a[r].inlinePresentationIntent = .stronglyEmphasized
                da = r.upperBound
            }
        }
        return a
    }

    // MARK: In una pagina

    private func pagina(_ s: SpiegazioneTreLivelli) -> some View {
        let barre = Self.barre(s)
        return VStack(alignment: .leading, spacing: 0) {
            Text("Per \(s.nomeCliente)").carattereApple(T.occhielloCarta).foregroundColor(Carta.sopratitolo)
            Text(s.pagina.titolo).carattereApple(T.titoloCarta).foregroundColor(Carta.testo)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, T.sottoOcchiello)
            ForEach(Array(s.pagina.sezioni.enumerated()), id: \.offset) { n, sezione in
                Text(sezione.titolo).carattereApple(T.sezioneCarta).foregroundColor(Carta.testo)
                    .padding(.top, T.sopraSezioneCarta)
                if n == 0, barre.count >= 2 {
                    // La prima sezione («Quanto ti servirà») con le barre delle stesse cifre
                    VStack(alignment: .leading, spacing: T.spazioBarre) {
                        ForEach(Array(barre.enumerated()), id: \.element.id) { i, b in riga(b, indice: i) }
                    }
                    .padding(.top, T.sopraBarre)
                } else {
                    VStack(alignment: .leading, spacing: T.spazioRigheCarta) {
                        ForEach(Array(sezione.righe.enumerated()), id: \.offset) { k, r in
                            HStack(alignment: .firstTextBaseline, spacing: T.spazioPunto) {
                                Text(n == 0 ? "•" : "\(k + 1).").carattereApple(T.testoCarta).foregroundColor(Carta.etichetta)
                                Text(r).carattereApple(T.testoCarta).foregroundColor(Carta.testoCorrente)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, T.sopraRigheCarta)
                }
            }
            Spacer(minLength: T.sopraPiede)
            VStack(alignment: .leading, spacing: T.sopraPiede) {
                Rectangle().fill(Carta.filetto).frame(height: T.filetto)
                Text(TreLivelliVera.avvertenza).carattereApple(T.piedeCarta).foregroundColor(Carta.piede)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(T.paddingCarta)
        .frame(maxWidth: T.larghezzaCarta, minHeight: T.altezzaMinimaCarta, alignment: .topLeading)
        .superficieApple(Tema.Apple.Superficie.carta, raggio: T.raggioCarta)
        // La carta resta chiara anche con l'app in scuro (PDF e anteprime: mai vetro)
        .environment(\.colorScheme, .light)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Una barra della pagina: etichetta, barra che si riempie (stessa animazione delle barre del tema) e cifra.
    private func riga(_ b: BarraTreLivelli, indice: Int) -> some View {
        HStack(spacing: T.spazioRigaBarra) {
            Text(b.etichetta).carattereApple(T.etichettaBarra).foregroundColor(Carta.etichetta)
                .lineLimit(2).frame(width: T.larghezzaEtichettaBarra, alignment: .leading)
            BarraPiena(frazione: b.frazione, colore: b.colore, indice: indice, altezza: T.altezzaBarra, raggio: T.raggioBarra,
                       binario: Carta.binario)
            Text(b.testo).carattereApple(T.valoreBarra).foregroundColor(Carta.testo)
                .lineLimit(1).frame(width: T.larghezzaValoreBarra, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    struct BarraTreLivelli: Identifiable {
        let id: String
        let etichetta: String
        let testo: String
        let frazione: Double
        let colore: Color
    }

    /// Le barre della prima sezione: le cifre in euro dell'argomento, nell'ordine del template (quanto serve, quanto
    /// c'è, quanto manca), in proporzione alla più grande. Vuoto se ce n'è meno di due.
    static func barre(_ s: SpiegazioneTreLivelli) -> [BarraTreLivelli] {
        let schema: [(String, Color)]
        switch s.argomento {
        case .previdenza:
            schema = [("desiderato", Tema.Apple.trelivelliBarraServe), ("pubblica", Tema.Apple.trelivelliBarraPubblica),
                      ("divario", Tema.Apple.trelivelliBarraManca)]
        case .protezione:
            schema = [("fabbisogno", Tema.Apple.trelivelliBarraServe), ("coperto", Tema.Apple.trelivelliBarraPubblica),
                      ("divario", Tema.Apple.trelivelliBarraManca)]
        case .liquidita:
            schema = [("totale", Tema.Apple.trelivelliBarraServe), ("riserva", Tema.Apple.trelivelliBarraPubblica),
                      ("eccedenza", Carta.positivo)]
        }
        let trovate = schema.compactMap { k, colore -> (CifraTreLivelli, Color)? in
            guard let c = s.cifre.first(where: { $0.id == k }), c.valore >= 1 else { return nil }
            return (c, colore)
        }
        guard trovate.count >= 2, let massimo = trovate.map({ $0.0.valore }).max(), massimo > 0 else { return [] }
        return trovate.map { c, colore in
            BarraTreLivelli(id: c.id, etichetta: c.etichetta, testo: c.testo, frazione: c.valore / massimo, colore: colore)
        }
    }

    // MARK: Piede: chi ha scritto e le azioni

    private func piede(_ s: SpiegazioneTreLivelli, nome: String) -> some View {
        let tornano = TreLivelliVera.stessiNumeri(s)
        return VStack(alignment: .leading, spacing: T.spazioRighe) {
            HStack(spacing: T.spazioPunto) {
                if s.livelliQwen.contains(livello) {
                    PillolaFaseTre(testo: "Parole di Qwen", colore: F.verde)
                } else {
                    PillolaFaseTre(testo: "Scritto da Prisma", colore: F.blu)
                }
                if !tornano {
                    PillolaFaseTre(testo: "Le cifre non tornano", colore: F.arancio)
                        .help("Un livello ha una cifra diversa dalle altre due: rileggi prima di usarlo.")
                }
                Text(livello == .pagina ? "La pagina si stampa o si manda a \(nome) così com'è. I numeri arrivano da Prisma, le parole da Vera."
                                        : "I numeri arrivano da Prisma (\(s.argomento.motore)), uguali nei tre livelli.")
                    .carattereApple(F.nota).foregroundColor(F.coloreDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !stato.inModoCliente {
                HStack(spacing: T.spazioPunto) {
                    if livello == .pagina {
                        if let d = stato.trelivelliDocumento(s.id) {
                            Button("Apri il PDF") { stato.apriDocumentoVera(d) }.buttonStyle(.apple).fixedSize()
                        }
                        Button("Salva nei Documenti") { stato.trelivelliProponiPagina(s.id, chiave: stato.chiaveConversazione) }
                            .buttonStyle(.apple).fixedSize()
                            .disabled(stato.veraInCorso || stato.solaLettura)
                            .help("Il PDF su carta bianca va nei Documenti di \(s.nomeCliente), dopo «Conferma»")
                    }
                    if livello != .tecnico {
                        Button("Manda a \(nome)") { stato.trelivelliProponiManda(s.id, chiave: stato.chiaveConversazione) }
                            .buttonStyle(.applePrimario).fixedSize()
                            .disabled(stato.veraInCorso || stato.solaLettura)
                            .help("Prepara la bozza del messaggio con la versione semplice: la spedisci tu")
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}
