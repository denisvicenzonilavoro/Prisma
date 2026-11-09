#if os(iOS)
import SwiftUI

/// Messaggi sull'iPhone, nella gerarchia approvata (Design/iphone.html): una cosa principale grande in alto (il
/// messaggio dell'occasione scelta, con il cliente, il titolo e il perché adesso), poi ciò che serve per decidere
/// (tono, canale, il testo con le cifre usate, «Apri in Mail» o «Apri in Messaggi»), il resto a un tocco: le altre
/// occasioni nel menu «Occasioni» a destra nella barra. Lo stesso pannello del Mac (PannelloMessaggio) in versione
/// compatta, che scorre tutto insieme. Il testo lo scrive Qwen del Mac attraverso il ponte in rete locale; se il Mac
/// non risponde resta il testo di Prisma e Vera lo dice. Prisma non spedisce mai: Mail e Messaggi si aprono già
/// compilati.
/// Un traguardo da festeggiare («Luce» §5.4.4) non apre il compositore: il pannello del traguardo in colonna, con il
/// biglietto in alto e le tre azioni sotto (`PannelloTraguardo(compatto: true)`).
@MainActor
struct MessaggiTelefono: View {
    @Environment(StatoShell.self) var stato
    @StateObject private var sessione = SessioneMessaggi()
    @Environment(\.prismaScatto) private var scatto

    private typealias T = Tema.Apple.Messaggi.Telefono

    var body: some View {
        let _ = ContaCorpi.segna()
        let richiesta = scatto ? RichiestaIstantaneaMessaggi.per(stato) : nil
        let elenco = sessione.elenco(stato.occasioniMessaggiConRichieste())
        let scelta = richiesta?.occasione(in: elenco) ?? sessione.occasione(in: elenco)
        return ScrollView {
            VStack(alignment: .leading, spacing: T.spazio) {
                if let o = scelta, let c = stato.cliente(o.clienteId) {
                    pannello(o, cliente: c, richiesta: richiesta)
                } else {
                    VuotoMessaggi()
                        .entrataCascata(0, base: Tema.Apple.Messaggi.Moto.baseApertura)
                }
            }
            .padding(T.margine)
        }
        .navigationTitle(AppPrisma.messaggi.titolo)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                menu(elenco, scelta: scelta?.id)
            }
        }
        .onAppear { prendiRichiesta() }
        .onChange(of: stato.richiestaMessaggi) { r in
            if r != nil { prendiRichiesta() }
        }
        .onDisappear { sessione.ferma() }
    }

    @ViewBuilder
    private func pannello(_ o: OccasioneMessaggio, cliente c: Cliente, richiesta: RichiestaIstantaneaMessaggi?) -> some View {
        if o.tipo == .traguardo {
            PannelloTraguardo(occasione: o, cliente: c, base: Tema.Apple.Messaggi.Moto.baseApertura, compatto: true)
                .id(o.id)
        } else {
            compositore(o, cliente: c, richiesta: richiesta)
        }
    }

    private func compositore(_ o: OccasioneMessaggio, cliente c: Cliente, richiesta: RichiestaIstantaneaMessaggi?) -> some View {
        let tono: Binding<TonoMessaggio> = richiesta.map { r in Binding.constant(r.tono) } ?? $sessione.tono
        let canale: Binding<CanaleMessaggio> = richiesta.map { r in Binding.constant(r.canale) } ?? $sessione.canale
        let fisso: TestoScrittoMessaggio? = scatto
            ? (richiesta?.scritto(o, cliente: c, stato: stato)
               ?? RichiestaIstantaneaMessaggi.testo(o, cliente: c, stato: stato, tono: sessione.tono, canale: sessione.canale,
                                                    vera: false, motivo: stato.disponibilitaLocale.motivo))
            : nil
        return PannelloMessaggio(sessione: sessione, occasione: o, cliente: c, tono: tono, canale: canale,
                                 compatto: true, incorniciato: false, base: Tema.Apple.Messaggi.Moto.baseApertura,
                                 primoIndice: 0, scrittoIstantanea: fisso)
            .id(o.id)
    }

    /// Le altre occasioni, a un tocco: per gruppo, con la spunta su quella scelta.
    private func menu(_ elenco: OccasioniMessaggi, scelta: String?) -> some View {
        Menu {
            ForEach(GruppoMessaggio.allCases, id: \.self) { g in
                let voci = elenco.voci(g)
                if !voci.isEmpty {
                    Section(g.titolo) {
                        ForEach(voci) { o in
                            Button {
                                sessione.scelta = o.id
                            } label: {
                                if o.id == scelta {
                                    Label(voce(o), systemImage: "checkmark")
                                } else {
                                    Text(voce(o))
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            Text(TestiMessaggi.occasioni)
                .carattereApple(T.menu)
                .foregroundColor(T.coloreMenu)
        }
        .disabled(elenco.tutte.count < 2)
    }

    /// «Giulia Rossi · Il riepilogo dell'incontro di ieri».
    private func voce(_ o: OccasioneMessaggio) -> String {
        let nome = stato.cliente(o.clienteId)?.nome ?? "Cliente"
        return "\(nome) · \(o.titolo)"
    }

    private func prendiRichiesta() {
        guard !scatto, let r = stato.prendiRichiestaMessaggi() else { return }
        sessione.applica(r, elenco: stato.occasioniMessaggiConRichieste(), stato: stato)
    }
}
#endif
