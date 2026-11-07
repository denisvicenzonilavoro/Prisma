import SwiftUI

// MARK: - Multiramo: i fondi uno per uno e la media ponderata (dalla versione 25 dell'archivio)

/// L'elenco dei fondi di una multiramo nel modulo della posizione: nome, quota sul totale del contratto,
/// rendimento lordo e costi di ogni fondo, con «Togli» e «Fondo» per aggiungere una riga. Sotto, il
/// controllo delle quote: gestione separata più fondi deve fare 100%.
struct ElencoFondiMultiramo: View {
    @Binding var posizione: Posizione

    private typealias M = Tema.Misura.Multiramo
    private typealias C = Tema.Colore.Multiramo
    private typealias T = Tema.Testo.Multiramo

    var body: some View {
        let elenco = posizione.fondi ?? []
        VStack(alignment: .leading, spacing: M.spazioFondi) {
            GruppoCampi(titolo: "I fondi, uno per uno",
                        spiegazione: "Quota sul totale del contratto e rendimento di ogni fondo: Prisma fa la media ponderata.")
            if !elenco.isEmpty {
                intestazione
                ForEach(elenco.indices, id: \.self) { i in riga(i) }
            }
            HStack(spacing: M.spazioCampiFondo) {
                Button { aggiungi() } label: { Label("Fondo", systemImage: "plus") }
                    .buttonStyle(StileCollegamento())
                Spacer(minLength: M.spazioCampiFondo)
                if let totale = posizione.totaleQuote {
                    Text(testoTotale(totale))
                        .font(T.quota)
                        .foregroundColor(posizione.quoteDaRivedere ? C.avviso : C.conferma)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var intestazione: some View {
        HStack(spacing: M.spazioCampiFondo) {
            Text("Fondo").frame(minWidth: M.nomeFondo, maxWidth: .infinity, alignment: .leading)
            Text("Quota").frame(width: M.campoFondo, alignment: .trailing)
            Text("Rendimento").frame(width: M.campoFondo * 2, alignment: .leading)
            Text("Costi").frame(width: M.campoFondo * 2, alignment: .leading)
        }
        .font(T.intestazione)
        .foregroundColor(C.etichetta)
    }

    /// Una riga: nome, quota (% del contratto), rendimento lordo (%), costi (%), «Togli».
    private func riga(_ i: Int) -> some View {
        HStack(spacing: M.spazioCampiFondo) {
            TextField("Fondo \(i + 1)", text: binding(i, \.nome))
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: M.nomeFondo, maxWidth: .infinity)
            CampoCifraFacoltativa(valore: binding(i, \.quota), unita: "%", larghezza: M.campoFondo)
            CampoCifraFacoltativa(valore: binding(i, \.rendimento), unita: "% lordo", larghezza: M.campoFondo)
            CampoCifraFacoltativa(valore: binding(i, \.costo), unita: "% costi", larghezza: M.campoFondo)
            Button("Togli") { togli(i) }
                .buttonStyle(StileSemplice())
                .font(T.azione)
                .foregroundColor(C.togli)
        }
    }

    private func binding<V>(_ i: Int, _ campo: WritableKeyPath<FondoMultiramo, V>) -> Binding<V> {
        Binding(
            get: {
                guard let elenco = posizione.fondi, elenco.indices.contains(i) else { return FondoMultiramo()[keyPath: campo] }
                return elenco[i][keyPath: campo]
            },
            set: { nuovo in
                guard var elenco = posizione.fondi, elenco.indices.contains(i) else { return }
                elenco[i][keyPath: campo] = nuovo
                posizione.fondi = elenco
            }
        )
    }

    /// «Gestione separata 40% + fondi 60% = 100%», oppure quanto manca o avanza.
    private func testoTotale(_ totale: Double) -> String {
        let t = (totale * 10).rounded() / 10
        guard posizione.quoteDaRivedere else { return "Quote: \(Formati.percentuale(t)) ✓" }
        let scarto = Formati.percentuale(abs(((100 - totale) * 10).rounded() / 10))
        return totale < 100 ? "Quote: \(Formati.percentuale(t)), manca il \(scarto)"
                            : "Quote: \(Formati.percentuale(t)), il \(scarto) in più"
    }

    /// Il primo fondo prende i dati della parte in fondi (quota e rendimento); i successivi la quota che manca.
    private func aggiungi() {
        var elenco = posizione.fondi ?? []
        if elenco.isEmpty {
            elenco.append(FondoMultiramo(quota: (posizione.parteFondi * 1000).rounded() / 10,
                                         rendimento: posizione.rendimentoFondi))
            // Il rendimento unico dei fondi diventa quello del primo fondo: non resta un valore nascosto
            posizione.rendimentoFondi = nil
        } else {
            let manca = 100 - (posizione.totaleQuote ?? posizione.parteGestione * 100)
            elenco.append(FondoMultiramo(quota: manca > 0 ? (manca * 10).rounded() / 10 : nil))
        }
        posizione.fondi = elenco
    }

    /// Togliendo l'ultimo fondo, il suo rendimento torna il rendimento unico dei fondi.
    private func togli(_ i: Int) {
        guard var elenco = posizione.fondi, elenco.indices.contains(i) else { return }
        let tolto = elenco.remove(at: i)
        if elenco.isEmpty {
            posizione.rendimentoFondi = posizione.rendimentoFondi ?? tolto.rendimento
            posizione.fondi = nil
        } else {
            posizione.fondi = elenco
        }
    }
}

/// Il rendimento complessivo di una multiramo divisa, in sola lettura: «Media ponderata: 40% × 3,00% +
/// 60% × 5,50% = 4,60%» con la barra della composizione sotto.
struct RigaMediaPonderata: View {
    let posizione: Posizione

    private typealias M = Tema.Misura.Multiramo

    var body: some View {
        VStack(alignment: .leading, spacing: M.spazioMedia) {
            Text("Media ponderata: \(posizione.testoMediaPonderata)")
                .font(Tema.Testo.Multiramo.media)
                .foregroundColor(Tema.Colore.Multiramo.media)
                .fixedSize(horizontal: false, vertical: true)
            BarraComposizione(gestione: posizione.parteGestione, conEtichette: false)
                .frame(maxWidth: M.larghezzaCursore * 2)
        }
        .accessibilityElement(children: .combine)
    }
}

/// La media ponderata del rendimento lordo nel dettaglio, come piccola equazione visiva: una riga per parte
/// (gestione separata e ogni fondo) con la barra larga quanto la sua quota, «40% × 3,00%», e in alto il
/// risultato grande. La formula per esteso e i costi di ogni fondo stanno nei tooltip.
struct EquazioneMediaPonderata: View {
    let posizione: Posizione

    private typealias M = Tema.Misura.Multiramo
    private typealias C = Tema.Colore.Multiramo
    private typealias T = Tema.Testo.Multiramo

    var body: some View {
        let voci = posizione.vociMediaPonderata
        VStack(alignment: .leading, spacing: M.spazioMediaVisiva) {
            HStack(alignment: .firstTextBaseline, spacing: M.spazioMediaVisiva) {
                Text("Rendimento lordo della polizza")
                    .font(T.titoloSezione)
                    .foregroundColor(C.etichetta)
                Spacer(minLength: M.spazioMediaVisiva)
                Text(CifreDoc.percento(posizione.rendimentoLordoComposto, decimali: 2))
                    .font(T.risultatoMedia)
                    .foregroundColor(C.media)
            }
            ForEach(Array(voci.enumerated()), id: \.offset) { i, v in
                riga(nome: v.nome, quota: v.quota, rendimento: v.rendimento,
                     colore: i == 0 ? C.gestione : C.fondi, aiuto: aiuto(i, voci: voci.count))
            }
        }
        .help("Media ponderata: \(posizione.testoMediaPonderata)")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rendimento lordo della polizza, media ponderata: \(posizione.testoMediaPonderata)")
    }

    /// Pallino, nome, barra della quota, «40%», «× 3,00%».
    private func riga(nome: String, quota: Double, rendimento: Double, colore: Color, aiuto: String?) -> some View {
        HStack(spacing: M.spazioMediaVisiva) {
            Circle()
                .fill(colore)
                .frame(width: M.pallino, height: M.pallino)
            Text(nome)
                .foregroundColor(C.etichetta)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: M.nomeMediaVisiva, alignment: .leading)
            BarraQuotaMultiramo(quota: quota / 100, colore: colore)
            Text(Formati.percentuale((quota * 10).rounded() / 10))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: M.quotaMediaVisiva, alignment: .trailing)
            Text("× " + CifreDoc.percento(rendimento, decimali: 2))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: M.rendimentoMediaVisiva, alignment: .trailing)
        }
        .font(T.rigaMediaVisiva)
        .foregroundColor(C.media)
        .help(aiuto ?? nome)
    }

    /// I costi di un fondo dell'elenco, nel tooltip della sua riga (le voci dopo la gestione separata
    /// sono i fondi uno per uno quando l'elenco c'è).
    private func aiuto(_ i: Int, voci: Int) -> String? {
        guard i > 0, let elenco = posizione.fondi, elenco.count == voci - 1 else { return nil }
        guard let c = elenco[i - 1].costo else { return "\(nomeFondo(elenco[i - 1], i - 1)): costi non indicati" }
        return "\(nomeFondo(elenco[i - 1], i - 1)): costi \(CifreDoc.percento(c, decimali: 2)) l'anno"
    }

    private func nomeFondo(_ f: FondoMultiramo, _ i: Int) -> String {
        let n = f.nome.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "Fondo \(i + 1)" : n
    }
}
