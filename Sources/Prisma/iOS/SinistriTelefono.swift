#if os(iOS)
import SwiftUI

/// I sinistri sull'iPhone («Luce» giro 15, §7.4.4 «iPhone/iPad»), in sola lettura dall'istantanea di «Prisma ovunque»
/// (titolo, fase, fatti e documenti senza file: niente descrizione, numeri, stime né importi) e nella gerarchia approvata
/// (Design/iphone.html): una cosa grande in alto (quanti sono aperti), poi un sinistro per scheda con la linea delle
/// fasi in piccolo e l'ultimo fatto. Fasi e fatti si segnano dal Mac (le modifiche dal giornale sono una domanda per
/// l'utente).
struct SinistriTelefono: View {
    @Environment(StatoShell.self) var stato

    private typealias E = Tema.Apple.Telefono.Elenco
    private typealias L = Tema.Apple.Pratiche.SinistriTelefono

    var body: some View {
        let _ = ContaCorpi.segna()
        let oggi = Date()
        let elenco = MotoreSinistri.elenco(stato.sinistriVisibili, oggi: oggi)
        let aperti = elenco.filter { !MotoreSinistri.chiuso($0) }.count
        FondoTelefono {
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(aperti == 1 ? "1 sinistro aperto" : "\(aperti) sinistri aperti")
                    .carattereApple(Tema.Apple.Carattere.valore)
                    .foregroundColor(E.coloreNome)
                Text("Sola lettura: le fasi e i fatti si segnano dal Mac")
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
            }
            .schedaTelefono()
            if elenco.isEmpty {
                VuotoTelefono(testo: TestiSinistri.fraseVuota)
            }
            ForEach(elenco) { s in
                VStack(alignment: .leading, spacing: E.spazioTesto) {
                    Text(stato.cliente(s.clienteId)?.nome ?? "Cliente")
                        .carattereApple(E.dettaglio)
                        .foregroundColor(E.coloreDettaglio)
                        .lineLimit(1)
                    Text(s.titolo)
                        .carattereApple(E.nome)
                        .foregroundColor(E.coloreNome)
                        .lineLimit(2)
                    LineaSinistroTelefono(sinistro: s)
                        .padding(.top, L.sopraLinea)
                    if let u = s.ultimoEvento {
                        Text("\(Formati.giornoMeseBreve.string(from: u.data)) · \(u.testo)")
                            .carattereApple(E.dettaglio)
                            .foregroundColor(E.coloreDettaglio)
                            .lineLimit(2)
                    }
                }
                .schedaTelefono()
            }
        }
        .navigationTitle("Sinistri")
    }
}

/// La linea delle fasi in piccolo: i nodi uniti da un filo, la fase di adesso scritta sotto.
private struct LineaSinistroTelefono: View {
    let sinistro: Sinistro

    private typealias S = Tema.Apple.Pratiche.Spedizione
    private typealias L = Tema.Apple.Pratiche.SinistriTelefono

    var body: some View {
        let nodi = MotoreSinistri.linea(sinistro)
        VStack(alignment: .leading, spacing: L.spazio) {
            HStack(spacing: 0) {
                ForEach(Array(nodi.enumerated()), id: \.offset) { i, n in
                    if i > 0 {
                        Rectangle()
                            .fill(n.stato == .futura ? S.binario : S.pieno)
                            .frame(height: L.filo)
                            .frame(maxWidth: .infinity)
                    }
                    cerchio(n.stato)
                }
            }
            Text(sinistro.fase.nome)
                .carattereApple(L.fase)
                .foregroundColor(sinistro.fase == .respinto ? S.etichettaRespinta : (sinistro.fase == .pagato ? S.fatto : S.etichettaAdesso))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Fase: \(sinistro.fase.nome)"))
    }

    @ViewBuilder private func cerchio(_ stato: SinistroMini.StatoFase) -> some View {
        switch stato {
        case .fatta:
            Circle().fill(S.fatto).frame(width: L.nodo, height: L.nodo)
        case .adesso:
            Circle().strokeBorder(S.adesso, lineWidth: L.bordoNodo).frame(width: L.nodo, height: L.nodo)
        case .futura:
            Circle().strokeBorder(S.futuro, lineWidth: L.bordoNodo).frame(width: L.nodo, height: L.nodo)
        case .respinta:
            Circle().fill(S.respinto).frame(width: L.nodo, height: L.nodo)
        }
    }
}
#endif
