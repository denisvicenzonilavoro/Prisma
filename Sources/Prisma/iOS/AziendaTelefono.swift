#if os(iOS)
import SwiftUI

/// L'azienda di un cliente imprenditore sull'iPhone («Luce» §9.3.4): in alto nome, forma e fatturato, poi le quattro aree
/// (persona chiave, TFM, welfare, passaggio dell'impresa) come elenco, ognuna con la sua percentuale, la frase di
/// MotoreAzienda e ciò che manca. Sola lettura: i dati si scrivono dal dossier sul Mac; il piede ricorda il commercialista.
struct AziendaTelefono: View {
    @Environment(StatoShell.self) var stato
    let clienteId: String
    let aziendaId: String

    private typealias E = Tema.Apple.Telefono.Elenco

    var body: some View {
        let cliente = stato.cliente(clienteId)
        let azienda = cliente?.elencoAziende.first { $0.id == aziendaId }
        FondoTelefono {
            if let c = cliente, let a = azienda {
                VStack(alignment: .leading, spacing: E.spazioTesto) {
                    Text(c.nome)
                        .carattereApple(E.dettaglio)
                        .foregroundColor(E.coloreDettaglio)
                    Text(a.ragioneSociale)
                        .carattereApple(Tema.Apple.Carattere.valore)
                        .foregroundColor(E.coloreNome)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(dettagli(a))
                        .carattereApple(E.dettaglio)
                        .foregroundColor(E.coloreDettaglio)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .pannelloTelefono()
                SezioneTelefono(titolo: "Le quattro aree")
                ForEach(MotoreAzienda.valuta(a, cliente: c, posizioni: stato.posizioniCliente(c.id))) { v in
                    VStack(alignment: .leading, spacing: E.spazioTesto) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(v.area.titolo)
                                .carattereApple(E.nome)
                                .foregroundColor(E.coloreNome)
                            Spacer(minLength: E.spazioRiga)
                            Text(v.nonPertinente ? "non pertinente" : (v.percentuale.map { TestiAzienda.percento($0) } ?? "da completare"))
                                .carattereApple(E.valore)
                                .foregroundColor(v.percentuale == nil ? E.coloreDettaglio : E.coloreNome)
                        }
                        Text(v.frase)
                            .carattereApple(E.dettaglio)
                            .foregroundColor(E.coloreDettaglio)
                            .fixedSize(horizontal: false, vertical: true)
                        if !v.mancano.isEmpty && !v.nonPertinente {
                            Text("Manca: " + v.mancano.joined(separator: ", "))
                                .carattereApple(E.dettaglio)
                                .foregroundColor(E.coloreVicino)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .schedaTelefono()
                }
                Text(TestiAzienda.piede(a))
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, E.spazioRiga)
            } else {
                VuotoTelefono(testo: "Questa azienda non c'è più nel dossier.")
            }
        }
        .navigationTitle("L'azienda")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// «S.r.l. · 14 dipendenti · fatturato 2,1 mln € nel 2025».
    private func dettagli(_ a: AziendaCliente) -> String {
        var parti: [String] = []
        if let f = a.forma { parti.append(f.nome) }
        if let d = a.dipendenti { parti.append(d == 1 ? "1 dipendente" : "\(d) dipendenti") }
        if let f = a.fatturato {
            parti.append("fatturato \(TestiAzienda.fatturatoBreve(f))" + (a.annoFatturato.map { " nel \($0)" } ?? ""))
        }
        return parti.isEmpty ? "Dati dell'azienda da inserire sul Mac" : parti.joined(separator: " · ")
    }
}
#endif
