import SwiftUI

// Le pagine del PDF protetto del Prisma del cliente («Luce» giro 15, §2.1 punto 9; decisione 3: il file che esce sempre).
// A4 verticale, carta bianca, colori fissi (CLAUDE.md: i documenti restano chiari): la copertina con il nome, la data
// fino a cui vale (un invito, decisione 6) e gli obiettivi; «Se vai in pensione a…» con la tabella al posto del cursore;
// la lettera con `FoglioLettera` su carta; il prisma di luce e la giornata come immagini ferme; il sinistro; le posizioni
// con il canale a parole e il suo colore (niente logo Alleanza, decisione 57); «Il film del tuo piano: te l'ho mandato a
// parte»; in ogni piede il consulente e le avvertenze. Lo stesso `ContenutoPrismaCliente` della mini-app.

enum PaginePrismaCliente {
    /// Le posizioni per pagina (le altre vanno nelle pagine dopo).
    static let posizioniPerPagina = 16

    @MainActor
    static func documento(_ c: ContenutoPrismaCliente) -> DocumentoStampabile {
        let formato = Misure.Documento.prospetto
        var corpi: [AnyView] = [AnyView(Copertina(c: c))]
        if let l = c.lettera {
            corpi.append(AnyView(FoglioLettera(testo: l, avvertenza: c.avvertenze.first ?? ImpostazioniSala.segnapostoAvvertenza,
                                               carta: true)))
        }
        if c.luce != nil || c.giornata != nil {
            corpi.append(AnyView(PaginaImmagini(c: c)))
        }
        if c.sinistri?.isEmpty == false {
            corpi.append(AnyView(PaginaSinistri(sinistri: c.sinistri ?? [])))
        }
        let posizioni = c.posizioni ?? []
        var inizio = 0
        while inizio < posizioni.count {
            let fine = min(posizioni.count, inizio + posizioniPerPagina)
            corpi.append(AnyView(PaginaPosizioni(posizioni: Array(posizioni[inizio..<fine]), continua: inizio > 0)))
            inizio = fine
        }
        let totale = corpi.count
        let pagine = corpi.enumerated().map { i, corpo in
            AnyView(PaginaCartaPrisma(c: c, numero: i + 1, totale: totale) { corpo }
                .frame(width: formato.width, height: formato.height))
        }
        return DocumentoStampabile(titolo: "Il Prisma di \(c.nomeBattesimo)", cliente: c.nomeBattesimo, genere: "Report",
                                   formato: formato, pagine: pagine, tipo: .report)
    }

    /// L'immagine ferma da un PNG (nil se non si legge).
    static func immagine(_ png: Data?) -> Image? {
        guard let png, let cg = ProtocolloTavolo.immagine(png) else { return nil }
        return Image(decorative: cg, scale: 2)
    }
}

private typealias PG = Tema.Apple.PrismaCliente.Pagina
private typealias CT = Tema.Apple.Carta

/// La pagina su carta: il corpo e il piede (consulente, avvertenze, numero della pagina).
private struct PaginaCartaPrisma<Corpo: View>: View {
    let c: ContenutoPrismaCliente
    let numero: Int
    let totale: Int
    @ViewBuilder let corpo: () -> Corpo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            corpo()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Rectangle().fill(CT.filetto).frame(height: 1)
            HStack(alignment: .top, spacing: PG.spazio) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.consulente)
                    ForEach(Array(c.avvertenze.enumerated()), id: \.offset) { _, a in Text(a) }
                    if c.diProva { Text("Dati di prova") }
                }
                Spacer(minLength: PG.spazio)
                Text("\(numero) / \(totale)")
            }
            .carattereApple(PG.piede)
            .foregroundColor(CT.piede)
            .padding(.top, PG.paddingRiga)
        }
        .padding(PG.margine)
        .background(CT.fondo)
    }
}

/// La copertina: logo, nome, validità, obiettivi, la tabella della pensione e il film mandato a parte.
private struct Copertina: View {
    let c: ContenutoPrismaCliente

    var body: some View {
        VStack(alignment: .leading, spacing: PG.spazio) {
            LogoPrisma(colore: Tema.Colore.logoStampa)
                .frame(height: PG.logo)
            VStack(alignment: .leading, spacing: 4) {
                Text("Il Prisma di").carattereApple(PG.sopratitolo).foregroundColor(CT.sopratitolo)
                Text(c.nomeBattesimo).carattereApple(PG.titolo).foregroundColor(CT.testo)
                Text("Valido fino al \(Formati.dataEstesa.string(from: c.validoFinoAl)). \(TestiPrismaCliente.fraseScadenza)")
                    .carattereApple(PG.sottotitolo).foregroundColor(CT.sottotitolo)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let obiettivi = c.obiettivi, !obiettivi.isEmpty {
                sezione("I tuoi obiettivi")
                HStack(alignment: .top, spacing: PG.spazio) {
                    ForEach(Array(obiettivi.enumerated()), id: \.offset) { _, o in
                        VStack(spacing: 6) {
                            AnelloCarta(quota: o.quota, colore: Color(hex: o.coloreHex), misura: PG.anello, spessore: PG.spessoreAnello)
                            Text(o.titolo).carattereApple(PG.riga).foregroundColor(CT.testo)
                                .multilineTextAlignment(.center)
                            Text(TestiPrismaCliente.fraseObiettivo(o.quota)).carattereApple(PG.piede).foregroundColor(CT.etichetta)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: PG.larghezzaEtichettaAnello)
                    }
                }
            }
            if let l = c.lineaVita {
                sezione("Se vai in pensione a…")
                VStack(spacing: 0) {
                    ForEach(Array(CompositorePrismaCliente.righeTabella(l).enumerated()), id: \.offset) { _, r in
                        let serie = l.serie(r.eta)
                        HStack {
                            Text("\(r.eta) anni").carattereApple(PG.rigaForte).foregroundColor(CT.testo)
                            Spacer()
                            Text(r.frase).carattereApple(PG.riga)
                                .foregroundColor(serie?.etaEsaurimento == nil ? CT.positivo : CT.rosso)
                        }
                        .padding(.vertical, PG.paddingRiga)
                        .overlay(alignment: .bottom) { Rectangle().fill(CT.filetto).frame(height: 1) }
                    }
                }
                if l.indicativa {
                    Text(TestiPrismaCliente.lineaIndicativa).carattereApple(PG.testo).foregroundColor(CT.etichetta)
                }
            }
            if c.conFilm {
                sezione("Il film del tuo piano")
                Text(TestiPrismaCliente.filmAParte).carattereApple(PG.testo).foregroundColor(CT.testoCorrente)
            }
        }
    }

    private func sezione(_ titolo: String) -> some View {
        Text(titolo).carattereApple(PG.titoloSezione).foregroundColor(CT.testo).padding(.top, PG.spazioRighe)
    }
}

/// Un anello fermo su carta (niente animazione: il PDF è sempre nello stato finale).
struct AnelloCarta: View {
    let quota: Double
    let colore: Color
    let misura: CGFloat
    let spessore: CGFloat
    var binario: Color = Tema.Apple.Carta.binario

    var body: some View {
        ZStack {
            Circle().stroke(binario, lineWidth: spessore)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(quota, 0), 1)))
                .stroke(colore, style: StrokeStyle(lineWidth: spessore, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(spessore / 2)
        .frame(width: misura, height: misura)
    }
}

/// Il prisma di luce e la giornata della pensione, come immagini ferme.
private struct PaginaImmagini: View {
    let c: ContenutoPrismaCliente

    var body: some View {
        VStack(alignment: .leading, spacing: PG.spazio) {
            if let luce = PaginePrismaCliente.immagine(c.luce) {
                Text("Il prisma di luce").carattereApple(PG.titoloSezione).foregroundColor(CT.testo)
                luce.resizable().aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: PG.altezzaImmagine)
                    .clipShape(RoundedRectangle(cornerRadius: PG.raggioImmagine, style: .continuous))
            }
            if let giornata = PaginePrismaCliente.immagine(c.giornata) {
                Text("Una giornata della pensione").carattereApple(PG.titoloSezione).foregroundColor(CT.testo)
                giornata.resizable().aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: PG.altezzaImmagine)
                    .clipShape(RoundedRectangle(cornerRadius: PG.raggioImmagine, style: .continuous))
            }
        }
    }
}

/// «Il tuo sinistro»: titolo, fasi, ultimo fatto, aggiornato da… (mai referti, diagnosi, polizza; l'importo solo se scelto).
private struct PaginaSinistri: View {
    let sinistri: [SinistroMini]

    var body: some View {
        VStack(alignment: .leading, spacing: PG.spazio) {
            ForEach(Array(sinistri.enumerated()), id: \.offset) { _, s in
                VStack(alignment: .leading, spacing: PG.spazioRighe) {
                    Text("Il tuo sinistro").carattereApple(PG.sopratitolo).foregroundColor(CT.sopratitolo)
                    Text(s.titolo).carattereApple(PG.titoloSezione).foregroundColor(CT.testo)
                    ForEach(Array(s.fasi.enumerated()), id: \.offset) { _, f in
                        HStack(spacing: 8) {
                            Circle().fill(colore(f.stato)).frame(width: PG.fase, height: PG.fase)
                            Text(f.nome).carattereApple(PG.riga)
                                .foregroundColor(f.stato == .futura ? CT.etichetta : CT.testo)
                        }
                    }
                    if let u = s.ultimoFatto { Text(u).carattereApple(PG.testo).foregroundColor(CT.testoCorrente) }
                    if let p = s.pagato { Text("Pagati \(p)").carattereApple(PG.rigaForte).foregroundColor(CT.testo) }
                    Text("Aggiornato da \(s.consulente.components(separatedBy: " · ").first ?? s.consulente) · \(Formati.dataEstesa.string(from: s.aggiornatoIl))")
                        .carattereApple(PG.piede).foregroundColor(CT.etichetta)
                }
            }
        }
    }

    private func colore(_ s: SinistroMini.StatoFase) -> Color {
        switch s {
        case .fatta: return Tema.Apple.MiniCliente.fatta
        case .adesso: return Tema.Apple.MiniCliente.adesso
        case .futura: return Tema.Apple.MiniCliente.cerchioVuoto
        case .respinta: return Tema.Apple.MiniCliente.nonBasta
        }
    }
}

/// Le posizioni nel dettaglio: nome, canale a parole e colore, valore, data (niente numero di contratto, IBAN, CF).
private struct PaginaPosizioni: View {
    let posizioni: [PosizioneMini]
    let continua: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(continua ? "Le tue posizioni (continua)" : "Le tue posizioni")
                .carattereApple(PG.titoloSezione).foregroundColor(CT.testo)
                .padding(.bottom, PG.spazioRighe)
            ForEach(Array(posizioni.enumerated()), id: \.offset) { _, p in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.nome).carattereApple(PG.riga).foregroundColor(CT.testo)
                        Text(p.canale).carattereApple(PG.piede).foregroundColor(Color(hex: p.coloreCanaleHex))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Formati.euro(p.valore)).carattereApple(PG.rigaForte).foregroundColor(CT.testo)
                        Text(Formati.dataEstesa.string(from: p.data)).carattereApple(PG.piede).foregroundColor(CT.etichetta)
                    }
                }
                .padding(.vertical, PG.paddingRiga)
                .overlay(alignment: .bottom) { Rectangle().fill(CT.filetto).frame(height: 1) }
            }
        }
    }
}
