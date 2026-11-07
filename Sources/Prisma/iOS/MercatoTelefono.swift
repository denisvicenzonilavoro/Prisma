#if os(iOS)
import SwiftUI

/// Mercato sull'iPhone, nella gerarchia approvata (Design/iphone.html): una cosa principale grande in alto (la prima
/// tessera, con il valore che conta e la linea), poi ciò che serve per decidere (le altre tessere su due colonne e
/// «Chi è toccato oggi»), il resto a un tocco (gli avvisi sotto, la ricerca per ISIN nel campo di ricerca della barra).
/// In sola lettura: serie, quote e avvisi arrivano dal Mac; il telefono non scarica nulla e non esce su internet.
@MainActor
struct MercatoTelefono: View {
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        CorpoMercatoTelefono(sessione: stato.sessioneMercato)
    }
}

@MainActor
private struct CorpoMercatoTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var sessione: SessioneMercato

    private typealias T = Tema.Apple.Mercato.Telefono

    var body: some View {
        let tessere = stato.tessereMercato()
        let eventi = stato.eventiMercato()
        let avvisi = stato.avvisiMercato
        let attivo = stato.dati.impostazioni.mercato.attivo
        return FondoTelefono {
            Text(stato.occhielloMercato().uppercased())
                .carattereApple(Tema.Apple.Mercato.Riquadro.etichetta)
                .foregroundColor(Tema.Apple.Mercato.Riquadro.coloreEtichetta)
                .lineLimit(1)
                .entrataCascata(0)
            if let r = sessione.risultatoISIN {
                RisultatoISINMercato(risultato: r)
                    .id(sessione.giroRicerca)
            }
            if let prima = tessere.first {
                principale(prima)
                    .entrataCascata(1)
                let altre = Array(tessere.dropFirst())
                if !altre.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: T.spazio, alignment: .top), count: T.colonne),
                              alignment: .leading, spacing: T.spazio) {
                        ForEach(Array(altre.enumerated()), id: \.element.id) { i, t in
                            TesseraStrisciaMercato(tessera: t, indice: i + 1) {}
                        }
                    }
                    .entrataCascata(2)
                }
            } else {
                VuotoMercato(attivo: attivo)
                    .entrataCascata(1)
            }
            SezioneTelefono(titolo: TestiAppMercato.titoloToccati(vecchi: MotoreMercato.datiVecchi(tessere)))
            if eventi.isEmpty {
                VuotoTelefono(testo: stato.dati.impostazioni.mercato.senzaSoglie
                              ? TestiAppMercato.toccatiSenzaSoglie : TestiAppMercato.nessunoToccato)
            } else {
                ForEach(eventi) { e in
                    SchedaToccatiMercato(evento: e)
                }
            }
            SezioneTelefono(titolo: TestiAppMercato.avvisi.uppercased())
            if avvisi.isEmpty {
                VuotoTelefono(testo: TestiAppMercato.nessunAvviso)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(avvisi) { a in RigaAvvisoMercato(avviso: a) }
                }
                .pannelloTelefono()
            }
            FasciaRiservatezzaMercato(attivo: attivo)
        }
        .navigationTitle(AppPrisma.mercato.titolo)
        .searchable(text: $sessione.testoISIN, prompt: Text(TestiAppMercato.cercaISIN))
        .onSubmit(of: .search) { stato.cercaISINMercato() }
    }

    /// La prima tessera grande: nome, valore 34 che conta, variazione, la linea alta 56, la data e la fonte.
    private func principale(_ t: TesseraMercato) -> some View {
        let k = Tema.Apple.Mercato.Tessera.self
        return VStack(alignment: .leading, spacing: k.spazioRighe) {
            Text(t.nome)
                .carattereApple(k.nome)
                .foregroundColor(k.coloreNome)
            if let v = t.valore {
                let unita = t.unita
                let decimali = t.decimali
                NumeroCheConta(v, formato: .personalizzato({ MotoreMercato.testoValore($0, unita: unita, decimali: decimali) }))
                    .carattereApple(T.valorePrincipale)
                    .foregroundColor(k.coloreValore)
            }
            if let testo = t.variazioneTesto {
                Text(t.freschezza == .vecchia ? TestiAppMercato.alDato(t.dataTesto ?? "") : testo)
                    .carattereApple(k.variazione)
                    .foregroundColor(t.freschezza == .vecchia ? k.coloreNota : ColoriMercato.cifra(t.tono))
            }
            if t.linea.count >= 2 {
                let n = Double(t.linea.count - 1)
                TracciatoGrafico(punti: t.linea.enumerated().map { CGPoint(x: Double($0.offset) / n, y: $0.element) },
                                 colore: ColoriMercato.linea(t.tono), spessore: k.spessoreLinea)
                    .frame(height: T.altezzaLineaPrincipale)
                    .padding(.top, k.sopraLinea)
                    .accessibilityHidden(true)
            }
            Text(([t.dataTesto].compactMap { $0 } + [t.citazione]).joined(separator: " · "))
                .carattereApple(k.fonte)
                .foregroundColor(k.coloreFonte)
                .lineLimit(1)
                .padding(.top, k.sopraFonte)
        }
        .pannelloTelefono()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TestiAppMercato.voceTessera(t))
    }
}
#endif
