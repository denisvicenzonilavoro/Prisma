import SwiftUI

private typealias C = Tema.Apple.Studio.Spese.Carta

// Il riepilogo del mese per il commercialista (Design/template-luce-specifica.md §6.3.5 punto 6, «Luce» giro 9): A4
// verticale, sempre chiaro, carta bianca con i colori opachi della carta (niente vetro), come i documenti PDF di Prisma.
// Dall'alto: il logo e «Chilometri e spese · Ottobre 2026», il consulente, i totali (km, visite, spese per categoria),
// i giri (data, visite, km, senza nomi se `nomiNelPacchetto` è spento) e le spese. In fondo la frase che dice che sono
// solo fatti: deducibilità e IVA le valuta il commercialista. Con molte righe si continua sulla pagina dopo.

/// I testi del riepilogo, preparati dai motori (nessun calcolo qui).
struct TestiRiepilogoSpese {
    struct Riga {
        let data: String
        let testo: String
        let numero: String
    }

    let titolo: String
    let consulente: String
    let totali: [(etichetta: String, valore: String)]
    let righe: [(sezione: String?, riga: Riga)]
    let piede: String

    private static let formatoData = Formati.formato("d MMM")

    init(mese: Date, riepilogo: MotoreChilometri.Riepilogo, spese: [SpesaStudio], nomi: [String: String]?, consulente: String,
         euroPerKm: Double?) {
        titolo = "Chilometri e spese · " + Formati.meseAnno.string(from: mese).capitalizzaPrima
        self.consulente = consulente
        var t: [(String, String)] = [
            ("Chilometri", (riepilogo.completo ? "" : "almeno ") + FormatoCifra.migliaia(riepilogo.totale) + " km"),
            ("Visite", "\(riepilogo.visite)"),
            ("Spese", Formati.euroDecimali(MotoreSpese.totale(spese))),
        ]
        if let e = euroPerKm {
            t.append(("Km × valore scritto da te", Formati.euroDecimali(riepilogo.totale * e)))
        }
        for c in MotoreSpese.perCategoria(spese) { t.append((c.categoria.nome, Formati.euroDecimali(c.totale))) }
        totali = t
        var r: [(String?, Riga)] = []
        for (i, g) in riepilogo.giri.enumerated() {
            var testo = g.visite.count == 1 ? "1 visita" : "\(g.visite.count) visite"
            if let nomi {
                let n = g.visite.map { nomi[$0.clienteId] ?? "" }.filter { !$0.isEmpty }
                if !n.isEmpty { testo += " · " + n.joined(separator: " · ") }
            }
            if g.corretto { testo += " · corretto a mano" }
            r.append((i == 0 ? "I giri" : nil,
                      Riga(data: Self.formatoData.string(from: g.giorno), testo: testo,
                           numero: g.km.map { FormatoCifra.migliaia($0) + " km" } ?? "— km")))
        }
        for (i, s) in spese.enumerated() {
            var testo = s.descrizione.isEmpty ? s.categoria.nome : s.descrizione
            if !s.descrizione.isEmpty { testo += " · " + s.categoria.nome }
            if s.scontrino != nil { testo += " · scontrino" }
            r.append((i == 0 ? "Le spese" : nil,
                      Riga(data: Self.formatoData.string(from: s.data), testo: testo, numero: Formati.euroDecimali(s.importo))))
        }
        righe = r
        piede = "Preparato con Prisma dai dati che hai scritto. Solo fatti: deducibilità, IVA detraibile e regime fiscale li "
            + "valuta il tuo commercialista." + (nomi == nil ? " Senza i nomi dei clienti." : "")
    }
}

extension String {
    /// «ottobre 2026» → «Ottobre 2026».
    fileprivate var capitalizzaPrima: String { prefix(1).uppercased() + dropFirst() }
}

extension DocumentoStampabile {
    /// Il riepilogo del mese per il commercialista (A4 verticale, su carta bianca).
    init(_ t: TestiRiepilogoSpese) {
        titolo = t.titolo
        cliente = t.consulente
        genere = "Riepilogo"
        formato = C.formato
        pagine = CartaRiepilogoSpese.pagine(t)
        tipo = .altro
    }
}

enum CartaRiepilogoSpese {
    static func pagine(_ t: TestiRiepilogoSpese) -> [AnyView] {
        var gruppi: [[(sezione: String?, riga: TestiRiepilogoSpese.Riga)]] = [Array(t.righe.prefix(C.righePrimaPagina))]
        var resto = t.righe.dropFirst(C.righePrimaPagina)
        while !resto.isEmpty {
            gruppi.append(Array(resto.prefix(C.righeAltrePagine)))
            resto = resto.dropFirst(C.righeAltrePagine)
        }
        return gruppi.enumerated().map { i, righe in
            AnyView(PaginaRiepilogoSpese(t: t, righe: righe, prima: i == 0, numero: i + 1, totale: gruppi.count))
        }
    }
}

private struct PaginaRiepilogoSpese: View {
    let t: TestiRiepilogoSpese
    let righe: [(sezione: String?, riga: TestiRiepilogoSpese.Riga)]
    let prima: Bool
    let numero: Int
    let totale: Int

    var body: some View {
        FoglioDocumento(formato: C.formato, sfondo: C.fondo) {
            VStack(alignment: .leading, spacing: C.spazioSezioni) {
                HStack(alignment: .center) {
                    LogoPrisma(colore: C.logo)
                        .frame(height: C.altezzaLogo)
                    Spacer(minLength: 0)
                    if totale > 1 {
                        Text(verbatim: "\(numero) / \(totale)")
                            .carattereApple(C.piede)
                            .foregroundColor(C.etichetta)
                    }
                }
                if prima {
                    VStack(alignment: .leading, spacing: C.paddingVoce) {
                        Text(verbatim: t.titolo)
                            .carattereApple(C.titolo)
                            .foregroundColor(C.testo)
                        Text(verbatim: t.consulente)
                            .carattereApple(C.sottotitolo)
                            .foregroundColor(C.etichetta)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: "Il mese")
                            .carattereApple(C.sezione)
                            .foregroundColor(C.sopratitolo)
                            .padding(.bottom, C.paddingVoce)
                        ForEach(Array(t.totali.enumerated()), id: \.offset) { _, v in
                            voce(data: nil, testo: v.etichetta, numero: v.valore)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(righe.enumerated()), id: \.offset) { _, r in
                        if let s = r.sezione {
                            Text(verbatim: s)
                                .carattereApple(C.sezione)
                                .foregroundColor(C.sopratitolo)
                                .padding(.top, C.spazioSezioni)
                                .padding(.bottom, C.paddingVoce)
                        }
                        voce(data: r.riga.data, testo: r.riga.testo, numero: r.riga.numero)
                    }
                }
                Spacer(minLength: 0)
                Text(verbatim: t.piede)
                    .carattereApple(C.piede)
                    .foregroundColor(C.etichetta)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(C.margine)
        }
        .prismaScalaTesto(1)
    }

    private func voce(data: String?, testo: String, numero: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if let data {
                Text(verbatim: data)
                    .carattereApple(C.voceForte)
                    .foregroundColor(C.testo)
                    .frame(width: C.colonnaData, alignment: .leading)
            }
            Text(verbatim: testo)
                .carattereApple(C.voce)
                .foregroundColor(C.testo)
                .lineLimit(1)
            Spacer(minLength: C.paddingVoce)
            Text(verbatim: numero)
                .carattereApple(C.voceForte)
                .foregroundColor(C.testo)
                .frame(minWidth: C.colonnaNumero, alignment: .trailing)
        }
        .padding(.vertical, C.paddingVoce)
        .overlay(alignment: .bottom) { Rectangle().fill(C.filetto).frame(height: 1) }
    }
}
