#if os(iOS)
import SwiftUI

/// Pratiche sull'iPhone («Luce» §7.3.4): «Dopo la firma» è la vista principale, nella gerarchia approvata
/// (Design/iphone.html): una cosa grande in alto (quante pratiche sono ferme), poi le ferme, poi le aperte, il dettaglio
/// a un tocco. In sola lettura dall'istantanea di «Prisma ovunque», più «segna il passo»: il segno passa dal giornale
/// cifrato del dispositivo (`EntitaOvunque.pratica`, solo i passi) e il Mac lo unisce, con i conflitti in «Da decidere».
/// Proposta, moduli e sinistri si lavorano sul Mac (i sinistri si leggono qui sotto, come in Clienti).
struct PraticheTelefono: View {
    @Environment(StatoShell.self) var stato

    private typealias E = Tema.Apple.Telefono.Elenco

    var body: some View {
        let _ = ContaCorpi.segna()
        let stati = stato.statiPratiche()
        let aperte = stati.filter { !$0.conclusa }
        let ferme = aperte.filter(\.ferma)
        let inCorso = aperte.filter { !$0.ferma }
        FondoTelefono {
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(ferme.count == 1 ? "1 pratica ferma" : "\(ferme.count) pratiche ferme")
                    .carattereApple(Tema.Apple.Carattere.valore)
                    .foregroundColor(ferme.isEmpty ? E.coloreNome : E.coloreScaduto)
                Text("\(aperte.count) \(aperte.count == 1 ? "aperta" : "aperte") · "
                     + (stato.passiDalTelefono ? "tocca una pratica per segnare un passo" : TestiPratiche.solaLetturaTelefono))
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .schedaTelefono()
            if aperte.isEmpty {
                VuotoTelefono(testo: TestiPratiche.nessuna)
            }
            if !ferme.isEmpty {
                SezioneTelefono(titolo: "Ferme")
                ForEach(ferme) { riga($0) }
            }
            if !inCorso.isEmpty {
                SezioneTelefono(titolo: "Aperte")
                ForEach(inCorso) { riga($0) }
            }
            SezioneTelefono(titolo: "Sinistri")
            NavigationLink { SinistriTelefono() } label: {
                HStack(spacing: E.spazioRiga) {
                    Text("I sinistri dei clienti")
                        .carattereApple(E.nome)
                        .foregroundColor(E.coloreNome)
                    Spacer(minLength: 0)
                    ChevronTelefono()
                }
                .schedaTelefono(premibile: true)
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Dopo la firma")
    }

    private func riga(_ s: StatoPratica) -> some View {
        NavigationLink { DettaglioPraticaTelefono(praticaId: s.id) } label: {
            HStack(spacing: E.spazioRiga) {
                VStack(alignment: .leading, spacing: E.spazioTesto) {
                    Text(stato.cliente(s.clienteId)?.nome ?? "Cliente")
                        .carattereApple(E.dettaglio)
                        .foregroundColor(E.coloreDettaglio)
                        .lineLimit(1)
                    Text(s.posizione.nome)
                        .carattereApple(E.nome)
                        .foregroundColor(E.coloreNome)
                        .lineLimit(2)
                    Text("\(s.testoStato) · \(s.nota)")
                        .carattereApple(E.dettaglio)
                        .foregroundColor(s.ferma ? E.coloreScaduto : E.coloreDettaglio)
                        .fixedSize(horizontal: false, vertical: true)
                    EtichettaCanaleApple(canale: s.canale, compatta: true)
                        .padding(.top, E.spazioTesto)
                }
                Spacer(minLength: 0)
                ChevronTelefono()
            }
            .schedaTelefono(premibile: true)
        }
        .buttonStyle(.plain)
    }
}

/// Il dettaglio di una pratica sull'iPhone: i passi con la data e da dove vengono, le note; «Segna fatto» o «Togli» su
/// ogni passo quando le modifiche dal telefono sono ammesse (il giornale porta il segno al Mac).
struct DettaglioPraticaTelefono: View {
    @Environment(StatoShell.self) var stato
    let praticaId: String

    private typealias E = Tema.Apple.Telefono.Elenco

    var body: some View {
        let s = stato.statiPratiche().first { $0.id == praticaId }
        FondoTelefono {
            if let s {
                VStack(alignment: .leading, spacing: E.spazioTesto) {
                    Text(stato.cliente(s.clienteId)?.nome ?? "Cliente")
                        .carattereApple(E.dettaglio)
                        .foregroundColor(E.coloreDettaglio)
                    Text(s.posizione.nome)
                        .carattereApple(Tema.Apple.Carattere.valore)
                        .foregroundColor(E.coloreNome)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(s.testoStato) · \(s.nota)")
                        .carattereApple(E.dettaglio)
                        .foregroundColor(s.ferma ? E.coloreScaduto : E.coloreDettaglio)
                        .fixedSize(horizontal: false, vertical: true)
                    EtichettaCanaleApple(canale: s.canale, compatta: true)
                        .padding(.top, E.spazioTesto)
                }
                .pannelloTelefono()
                SezioneTelefono(titolo: "I passi")
                ForEach(s.passi) { p in passo(p, pratica: s) }
                if let note = s.pratica.note, !note.isEmpty {
                    SezioneTelefono(titolo: "Note")
                    ForEach(Array(note.enumerated()), id: \.offset) { _, n in
                        VStack(alignment: .leading, spacing: E.spazioTesto) {
                            Text(Formati.dataBreve.string(from: n.data))
                                .carattereApple(E.dettaglio)
                                .foregroundColor(E.coloreDettaglio)
                            Text(n.testo)
                                .carattereApple(E.corpo)
                                .foregroundColor(E.coloreNome)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .schedaTelefono()
                    }
                }
                if !stato.passiDalTelefono {
                    VuotoTelefono(testo: TestiPratiche.solaLetturaTelefono)
                }
            } else {
                VuotoTelefono(testo: "Questa pratica non c'è più nell'archivio.")
            }
        }
        .navigationTitle("Pratica")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func passo(_ p: PassoCalcolato, pratica s: StatoPratica) -> some View {
        HStack(alignment: .center, spacing: E.spazioRiga) {
            PallinoPasso(stato: p.stato)
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(p.etichetta)
                    .carattereApple(E.nome)
                    .foregroundColor(E.coloreNome)
                Text(TestiPratiche.dettaglio(p))
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if stato.passiDalTelefono && !s.conclusa {
                if p.fatto {
                    Button("Togli") { stato.segnaPasso(s.id, p.passo, fatto: false) }
                        .buttonStyle(.apple)
                } else {
                    Button("Segna fatto") { stato.segnaPasso(s.id, p.passo, fatto: true) }
                        .buttonStyle(.applePrimario)
                }
            }
        }
        .schedaTelefono()
    }
}
#endif
