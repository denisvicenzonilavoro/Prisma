import SwiftUI

private typealias K = Tema.Apple.CartaFattura.Colore
private typealias F = Tema.Apple.CartaFattura.Testo
private typealias M = Tema.Apple.CartaFattura.Misura

// La fattura su carta (Design/template-novita-specifica.md §1.4 e §5.2.3): A4 verticale, sempre chiara, carta bianca
// con i colori opachi e fissi di `Tema.Apple.Carta`, niente vetro. Le stesse pagine servono all'anteprima di Studio ›
// Parcelle e fatture e al PDF (StampaCarta.pdf). Dall'alto: la testata del canale indipendente («Denis Vicenzoni ·
// Consulenza finanziaria», in cuoio), «FATTURA» con il numero e la data a sinistra e il cliente a destra, la tabella
// delle righe, le voci fiscali (o «secondo il regime impostato · da completare»), il totale, il pagamento e il piede con
// i dati del consulente, la dicitura scritta da lui e «Documento di prova» quando mancano dati. Con molte righe la
// tabella continua sulla pagina dopo («segue»).

enum FatturaCarta {
    static func pagine(_ t: TestiFattura) -> [AnyView] {
        let gruppi = Self.gruppi(t.righe)
        return gruppi.enumerated().map { i, righe in
            AnyView(PaginaFattura(t: t, righe: righe, prima: i == 0, ultima: i == gruppi.count - 1,
                                  numero: i + 1, totale: gruppi.count))
        }
    }

    /// Le righe divise per pagina: 8 sulla prima, 14 sulle altre (almeno una pagina, anche senza righe).
    static func gruppi(_ righe: [TestiFattura.Riga]) -> [[TestiFattura.Riga]] {
        var resto = righe[...]
        var gruppi: [[TestiFattura.Riga]] = [Array(resto.prefix(M.righePrimaPagina))]
        resto = resto.dropFirst(M.righePrimaPagina)
        while !resto.isEmpty {
            gruppi.append(Array(resto.prefix(M.righeAltrePagine)))
            resto = resto.dropFirst(M.righeAltrePagine)
        }
        return gruppi
    }
}

extension DocumentoStampabile {
    /// La fattura di una parcella (A4 verticale, su carta bianca).
    init(_ t: TestiFattura) {
        titolo = t.numero
        cliente = t.nomeCliente
        genere = "Fattura"
        formato = M.formato
        pagine = FatturaCarta.pagine(t)
        tipo = .altro
    }
}

/// Una pagina della fattura.
private struct PaginaFattura: View {
    let t: TestiFattura
    let righe: [TestiFattura.Riga]
    let prima: Bool
    let ultima: Bool
    let numero: Int
    let totale: Int

    var body: some View {
        FoglioDocumento(formato: M.formato, sfondo: K.fondo) {
            ZStack(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    testata
                    if prima {
                        intestazioneDocumento
                            .padding(.top, M.sottoTestata)
                    }
                    tabella
                        .padding(.top, prima ? M.sopraTabella : M.sottoTestata)
                    if ultima {
                        conti
                        pagamento
                            .padding(.top, M.sopraSezione)
                    } else {
                        Text(verbatim: "segue")
                            .carattereApple(F.segue)
                            .foregroundColor(K.etichetta)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, M.paddingVoci)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.bottom, M.spazioPiede)
                .clipped()
                piede
                    .background(K.fondo)
            }
            .padding(EdgeInsets(top: M.margineAlto, leading: M.margineLati, bottom: M.piedeDalFondo, trailing: M.margineLati))
        }
        // La carta ha misure fisse: la «Dimensione del testo» dell'app non la ingrandisce
        .prismaScalaTesto(1)
    }

    // MARK: Testata del canale

    private var testata: some View {
        HStack(alignment: .center, spacing: M.spazioLogo) {
            LogoPrisma(colore: K.logo)
                .frame(height: M.logo)
            Text(verbatim: t.intestazione)
                .carattereApple(F.testata)
                .foregroundColor(K.canale)
                .lineLimit(1)
            Spacer(minLength: 0)
            if totale > 1 {
                Text(verbatim: "\(numero) / \(totale)")
                    .carattereApple(F.segue)
                    .foregroundColor(K.etichetta)
            }
        }
    }

    // MARK: Numero, data e cliente

    private var intestazioneDocumento: some View {
        HStack(alignment: .top, spacing: M.spazioColonne) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: t.sopratitolo)
                    .carattereApple(F.sopratitolo)
                    .foregroundColor(K.sopratitolo)
                Text(verbatim: t.numero)
                    .carattereApple(F.numero)
                    .foregroundColor(K.testo)
                    .lineLimit(1)
                    .minimumScaleFactor(M.riduzioneNumero)
                Text(verbatim: t.data)
                    .carattereApple(F.data)
                    .foregroundColor(K.sottotitolo)
                    .padding(.top, M.sopraData)
            }
            Spacer(minLength: M.spazioColonne)
            VStack(alignment: .trailing, spacing: 0) {
                campo(t.cliente, carattere: F.clienteNome)
                ForEach(Array(t.datiCliente.enumerated()), id: \.offset) { _, c in
                    campo(c, carattere: F.cliente)
                }
            }
            .multilineTextAlignment(.trailing)
        }
    }

    private func campo(_ c: TestiFattura.Campo, carattere: Tema.Apple.Carattere) -> some View {
        Text(verbatim: c.testo)
            .carattereApple(carattere)
            .foregroundColor(c.daCompletare ? K.daCompletare : K.testoCorrente)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Tabella

    private var tabella: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(K.testo).frame(height: M.filettoForte)
            HStack(spacing: M.spazioColonne) {
                Text(verbatim: "Descrizione")
                Spacer(minLength: 0)
                Text(verbatim: "Importo")
            }
            .carattereApple(F.testaTabella)
            .foregroundColor(K.etichetta)
            .padding(.top, M.sottoTestaTabella)
            ForEach(righe) { r in
                HStack(alignment: .firstTextBaseline, spacing: M.spazioColonne) {
                    VStack(alignment: .leading, spacing: M.spazioRiga) {
                        Text(verbatim: r.descrizione)
                            .carattereApple(F.riga)
                            .foregroundColor(K.testo)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(verbatim: r.sottotitolo)
                            .carattereApple(F.rigaSotto)
                            .foregroundColor(K.etichetta)
                    }
                    Spacer(minLength: 0)
                    Text(verbatim: r.importo)
                        .carattereApple(F.rigaImporto)
                        .foregroundColor(K.testo)
                        .lineLimit(1)
                }
                .padding(.vertical, M.paddingRiga)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(K.filetto).frame(height: M.filettoSottile)
                }
            }
        }
    }

    // MARK: Voci fiscali e totale

    private var conti: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(t.voci) { v in voce(v) }
            }
            .padding(.vertical, M.paddingVoci - M.paddingVoce)
            Rectangle().fill(K.testo).frame(height: M.filettoForte)
            HStack(spacing: M.spazioColonne) {
                Text(verbatim: t.etichettaTotale)
                Spacer(minLength: 0)
                Text(verbatim: t.totale)
                    .lineLimit(1)
            }
            .carattereApple(F.totale)
            .foregroundColor(K.testo)
            .padding(.vertical, M.paddingTotale)
            if let netto = t.netto {
                ForEach(t.dopoTotale) { v in voce(v) }
                Rectangle().fill(K.filetto).frame(height: M.filettoSottile)
                    .padding(.top, M.paddingVoce)
                HStack(spacing: M.spazioColonne) {
                    Text(verbatim: TestiFattura.etichettaNetto)
                    Spacer(minLength: 0)
                    Text(verbatim: netto)
                        .lineLimit(1)
                }
                .carattereApple(F.netto)
                .foregroundColor(K.testo)
                .padding(.vertical, M.paddingVoci)
            }
        }
    }

    private func voce(_ v: TestiFattura.VoceFiscale) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: M.spazioColonne) {
            Text(verbatim: v.etichetta)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(verbatim: v.valore)
                .lineLimit(1)
        }
        .carattereApple(F.voce)
        .foregroundColor(v.daCompletare ? K.daCompletare : K.etichetta)
        .padding(.vertical, M.paddingVoce)
    }

    // MARK: Pagamento e piede

    private var pagamento: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "Pagamento")
                .carattereApple(F.sezione)
                .foregroundColor(K.testo)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(t.pagamento.enumerated()), id: \.offset) { _, c in
                    Text(verbatim: c.testo)
                        .carattereApple(F.corpo)
                        .foregroundColor(c.daCompletare ? K.daCompletare : K.testoCorrente)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, M.sottoSezione)
        }
    }

    private var piede: some View {
        // Le parti del piede in una frase sola, separate da « · »; quelle da completare in ambra
        let testo = t.piede.enumerated().reduce(Text(verbatim: "")) { somma, voce in
            let parte = Text(verbatim: voce.element.testo)
                .foregroundColor(voce.element.daCompletare ? K.daCompletare : K.piede)
            return voce.offset == 0 ? parte : somma + Text(verbatim: " · ").foregroundColor(K.piede) + parte
        }
        return VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(K.filetto).frame(height: M.filettoSottile)
            testo
                .carattereApple(F.piede)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, M.paddingPiede)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
