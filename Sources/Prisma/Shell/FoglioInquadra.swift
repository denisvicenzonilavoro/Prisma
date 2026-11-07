import SwiftUI

// Il foglio di Inquadra e capisci (Design/template-novita-specifica.md §9.1.3, §9.2.3), sul Mac dentro l'iPhone
// disegnato e sull'iPhone sopra la scheda dei dati:
// - con una foto (trascinata sul Mac o scattata sull'iPhone) è la foto stessa, con il riquadro verde di ogni campo
//   letto nel punto in cui Vision l'ha trovato (`CampoInquadrato.riquadro`);
// - senza foto (testo arrivato dall'iPhone, un PDF, le istantanee) è il foglio di carta ricostruito: intestazione,
//   titolo e le righe da cui vengono i campi, che si illuminano; sotto, le righe finte del resto della polizza.
// Il foglio è carta: sempre chiaro, anche in scuro, come i PDF di Prisma. Le righe si accendono quando la scheda
// mostra il loro dato (`accesi`): la cascata la guida StatoInquadra, qui solo la transizione di 0,4 s.

struct FoglioInquadra: View {
    let righe: [RigaLetta]
    let campi: [CampoInquadrato]
    /// I campi già mostrati nella scheda: le loro righe sono accese.
    let accesi: Set<CampoDocumento>
    var immagine: ImmaginePiattaforma?

    private typealias F = Tema.Apple.Inquadra.Foglio

    var body: some View {
        if let immagine {
            foto(immagine)
        } else {
            carta
        }
    }

    // MARK: La foto con i riquadri

    private func foto(_ img: ImmaginePiattaforma) -> some View {
        Image(piattaforma: img)
            .resizable()
            .interpolation(.medium)
            .aspectRatio(contentMode: .fit)
            .overlay {
                GeometryReader { g in
                    ForEach(campi.filter { $0.riquadro != nil }) { c in
                        riquadro(c, in: g.size)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: F.raggio, style: .continuous))
            .accessibilityLabel(Text("La foto del documento, con i dati letti evidenziati"))
    }

    @ViewBuilder private func riquadro(_ c: CampoInquadrato, in misura: CGSize) -> some View {
        if let r = c.riquadro {
            let acceso = accesi.contains(c.campo)
            let forma = RoundedRectangle(cornerRadius: F.raggioRiquadro, style: .continuous)
            forma
                .fill(F.fondoLetto)
                .overlay(forma.strokeBorder(Tema.Apple.Inquadra.verdeLettura, lineWidth: F.contornoLetto))
                .frame(width: CGFloat(r.larghezza) * misura.width + 2 * F.ariaRiquadro,
                       height: CGFloat(r.altezza) * misura.height + 2 * F.ariaRiquadro)
                .position(x: CGFloat(r.x + r.larghezza / 2) * misura.width, y: CGFloat(r.y + r.altezza / 2) * misura.height)
                .opacity(acceso ? 1 : 0)
        }
    }

    // MARK: Il foglio ricostruito

    /// Una riga del foglio: la riga letta divisa in etichetta e valore («Premio: 90,00 € al mese»), con i campi che
    /// vengono da lei.
    private struct RigaFoglio: Identifiable {
        let id: Int
        let etichetta: String
        let valore: String
        let campi: Set<CampoDocumento>
    }

    /// Le righe da cui vengono i campi, nell'ordine del foglio (una riga sola anche se dà due campi).
    private var righeFoglio: [RigaFoglio] {
        var perRiga: [Int: Set<CampoDocumento>] = [:]
        for c in campi {
            for i in c.righe where righe.indices.contains(i) { perRiga[i, default: []].insert(c.campo) }
        }
        return perRiga.keys.sorted().map { i in
            let (e, v) = Self.dividi(righe[i].testo)
            return RigaFoglio(id: i, etichetta: e, valore: v, campi: perRiga[i] ?? [])
        }
    }

    /// «Etichetta: valore»; senza i due punti tutta la riga è l'etichetta.
    private static func dividi(_ s: String) -> (String, String) {
        guard let i = s.firstIndex(of: ":") else { return (s, "") }
        let e = s[..<i].trimmingCharacters(in: .whitespaces)
        let v = s[s.index(after: i)...].trimmingCharacters(in: .whitespaces)
        return (e, v)
    }

    /// Le prime righe che non danno campi: intestazione (la compagnia) e titolo.
    private var testata: (intestazione: String?, titolo: String) {
        let usate = Set(campi.flatMap(\.righe))
        let libere = righe.indices.filter { !usate.contains($0) }.prefix(2).map { righe[$0].testo }
        if libere.count >= 2 { return (libere[0], libere[1]) }
        return (libere.first, "Polizza")
    }

    private var carta: some View {
        let t = testata
        return VStack(alignment: .leading, spacing: 0) {
            if let intestazione = t.intestazione {
                Text(intestazione)
                    .carattereApple(F.intestazione)
                    .foregroundColor(F.coloreIntestazione)
                    .lineLimit(1)
            }
            Text(t.titolo)
                .carattereApple(F.titolo)
                .foregroundColor(F.inchiostroForte)
                .lineLimit(2)
                .padding(.top, F.titoloSopra)
                .padding(.bottom, F.titoloSotto)
            ForEach(righeFoglio) { r in
                riga(r)
            }
            ForEach(Array(F.larghezzeFinte.enumerated()), id: \.offset) { i, quota in
                GeometryReader { g in
                    RoundedRectangle(cornerRadius: F.raggioFinta, style: .continuous)
                        .fill(F.righeFinte)
                        .frame(width: g.size.width * quota, height: F.altezzaFinta)
                }
                .frame(height: F.altezzaFinta)
                .padding(.top, i == 0 ? F.primaFintaSopra : F.fintaSopra)
            }
        }
        .padding(F.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: F.raggio, style: .continuous)
                .fill(F.fondo)
                .shadow(color: F.ombra, radius: F.ombraRaggio, x: 0, y: F.ombraY)
        }
        // Carta: sempre chiara, anche in scuro
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .combine)
    }

    private func riga(_ r: RigaFoglio) -> some View {
        let acceso = !r.campi.isDisjoint(with: accesi)
        let forma = RoundedRectangle(cornerRadius: F.raggioRiga, style: .continuous)
        return HStack(alignment: .firstTextBaseline, spacing: F.paddingRiga) {
            Text(r.etichetta)
                .carattereApple(F.riga)
                .foregroundColor(F.inchiostro)
                .lineLimit(1)
            Spacer(minLength: F.paddingRiga)
            Text(r.valore)
                .carattereApple(F.valoreRiga)
                .foregroundColor(F.inchiostroForte)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
        }
        .padding(F.paddingRiga)
        .background(forma.fill(acceso ? F.fondoLetto : Color.clear))
        .overlay(forma.strokeBorder(Tema.Apple.Inquadra.verdeLettura, lineWidth: F.contornoLetto).opacity(acceso ? 1 : 0))
    }
}

// MARK: - Una riga della scheda (Mac e iPhone)

/// Una riga dei dati: ✓ verde, l'etichetta in grigio (150) e il valore in grassetto; il dato che manca in grigio.
struct RigaSchedaInquadra: View {
    let riga: RigaInquadra

    private typealias S = Tema.Apple.Inquadra.Scheda

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(riga.trovata ? "✓" : "")
                .carattereApple(S.spunta)
                .foregroundColor(S.coloreSpunta)
                .frame(width: S.larghezzaSpunta, alignment: .leading)
            Text(riga.etichetta)
                .carattereApple(S.etichettaRiga)
                .foregroundColor(riga.trovata ? S.coloreEtichettaRiga : S.coloreMancante)
                .frame(width: S.larghezzaEtichetta, alignment: .leading)
            Text(riga.valore ?? "non letto")
                .carattereApple(riga.trovata ? S.valore : S.etichettaRiga)
                .foregroundColor(riga.trovata ? S.coloreValore : S.coloreMancante)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, S.paddingRiga)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(S.filo)
                .frame(height: Tema.Apple.Misura.bordo)
        }
        .accessibilityElement(children: .combine)
    }
}

extension StatoInquadra {
    /// I campi accesi sul foglio: quelli delle righe che la scheda mostra già.
    var campiAccesi: Set<CampoDocumento> {
        Set(MotoreInquadra.righeScheda.prefix(mostrate).flatMap { $0.campi })
    }
}
