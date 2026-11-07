import SwiftUI

// Il pannello del traguardo in Messaggi (versione «Luce», giro 5, Design/template-luce-specifica.md §5.4.1 punto 1.2), al
// posto del compositore quando l'occasione scelta è un traguardo:
//
//   ◉  DA FESTEGGIARE · OBIETTIVO RAGGIUNTO IERI
//      Sofia Romano: ha raggiunto «Rendita integrativa»
//   ┌──────────── biglietto 560×420 ────────────┐   IL MOMENTO, GIÀ PRONTO
//   │ ◯✓  Ce l’hai fatta, Sofia.                 │   Il biglietto animato         [Manda]  (arriva con il giro 15)
//   │ 120.000 €  messi al sicuro in …            │   Una telefonata               [Aggiungi] → ✓ In agenda
//   │ …                                — Denis   │   L’idea per un regalo         [Annota]   → ✓ Annotata
//   └────────────────────────────────────────────┘   Prisma si accorge da solo dei traguardi: …
//
// - Il biglietto si vede ma non si condivide ancora: «Manda» è spento e dice che arriva con un prossimo aggiornamento.
// - «Aggiungi» mette una telefonata nel primo spazio libero da domani (StatoTraguardi.swift); il clic dopo apre l'Agenda.
// - L'idea per il regalo viene solo da una frase delle note del dossier; senza, «Nessuna idea dalle note» e «Annota»
//   apre un campo per scriverla. È una nota privata del consulente: in modalità cliente la colonna destra non c'è.
// - «Riduci movimento» e istantanee: cifra completa, anello pieno, niente coriandoli (BigliettoTraguardo).
// Valori in DesignSystem/Apple/Tema.Apple+Traguardi.swift.

@MainActor
struct PannelloTraguardo: View {
    @EnvironmentObject var stato: StatoShell
    let occasione: OccasioneMessaggio
    let cliente: Cliente
    var base: Double = Tema.Apple.Messaggi.Moto.baseApertura
    var primoIndice = 0

    @State private var scrivendoIdea = false
    @State private var idea = ""

    private typealias P = Tema.Apple.Messaggi.Pannello
    private typealias T = Tema.Apple.Messaggi.Traguardo

    var body: some View {
        let traguardo = stato.traguardo(occasione.origine.riferimento)
        return GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    testata(traguardo)
                        .entrataCascata(primoIndice, base: base)
                    if let t = traguardo {
                        let affiancato = geo.size.width - P.padding.leading - P.padding.trailing >= T.larghezzaAffiancata
                        Group {
                            if affiancato {
                                HStack(alignment: .top, spacing: T.spazioColonne) {
                                    BigliettoTraguardo(traguardo: t, firma: firma)
                                    if !stato.inModoCliente { colonna(t).frame(maxWidth: .infinity, alignment: .leading) }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: T.spazioColonne) {
                                    BigliettoTraguardo(traguardo: t, firma: firma)
                                    if !stato.inModoCliente { colonna(t) }
                                }
                            }
                        }
                        .padding(.top, T.sottoTestata)
                        .entrataCascata(primoIndice + 1, base: base, sfocatura: false)
                    }
                }
                .padding(P.padding)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .superficieApple(P.superficie, raggio: P.raggio)
    }

    private var firma: String? {
        ModelliMessaggi.firma(nil, tono: .cordiale, impostazioni: stato.dati.impostazioni)
    }

    private var diProva: Bool {
        stato.haDatiDiProva && StatoShell.clientiDiProva.contains(cliente.id)
    }

    // MARK: Testata

    private func testata(_ t: Traguardo?) -> some View {
        HStack(alignment: .center, spacing: P.spazioTestata) {
            AvatarCliente(iniziali: cliente.iniziali, tinta: cliente.tinta.colori, lato: P.avatar)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: P.spazioTitolo) {
                HStack(spacing: P.spazioPillole) {
                    Text(GruppoMessaggio.festeggiare.titolo + " · " + occasione.perche)
                        .carattereApple(P.destinatario)
                        .foregroundColor(P.coloreDestinatario)
                        .lineLimit(1)
                    if diProva {
                        Text("· " + TestiTraguardi.datiDiProva)
                            .carattereApple(T.prova)
                            .foregroundColor(T.coloreProva)
                            .lineLimit(1)
                    }
                }
                Text(TestiTraguardi.testata(nome: cliente.nome, titolo: t?.titolo ?? occasione.titolo))
                    .carattereApple(P.titolo)
                    .foregroundColor(P.coloreTitolo)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Il momento, già pronto

    private func colonna(_ t: Traguardo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(TestiTraguardi.titoloMomento)
                .carattereApple(T.etichetta)
                .foregroundColor(T.coloreEtichetta)
                .padding(.bottom, T.sottoEtichetta)
                .accessibilityAddTraits(.isHeader)
            riga(TestiTraguardi.biglietto, nota: TestiTraguardi.bigliettoNota) {
                Button("Manda") {}
                    .buttonStyle(.apple)
                    .disabled(true)
                    .help("Il biglietto si potrà mandare con un prossimo aggiornamento: per ora si guarda qui")
            }
            rigaTelefonata(t)
            rigaRegalo(t)
            Text(TestiTraguardi.notaColonna)
                .carattereApple(T.notaFondo)
                .foregroundColor(T.coloreNotaFondo)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, T.sopraNotaFondo)
            Text(TestiTraguardi.scrittaDaPrisma)
                .carattereApple(T.notaFondo)
                .foregroundColor(T.coloreNotaFondo)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, T.sopraNotaFondo / 2)
        }
    }

    private func rigaTelefonata(_ t: Traguardo) -> some View {
        let messa = stato.telefonataTraguardo(t)
        let nota: String
        if let a = messa {
            nota = TestiTraguardi.quandoTelefonata(a.inizio, oggi: Date()) + ", in agenda"
        } else if let s = prossimoSpazio {
            nota = TestiTraguardi.quandoTelefonata(s, oggi: Date()) + ", in agenda"
        } else {
            nota = "nessuno spazio libero nei prossimi giorni"
        }
        return riga(TestiTraguardi.telefonata, nota: nota) {
            if messa != nil {
                Button {
                    stato.apriTelefonataTraguardo(t)
                } label: {
                    Text("✓ In agenda").foregroundColor(T.coloreFatto)
                }
                .buttonStyle(.apple)
                .help("Apri la telefonata in Agenda")
            } else {
                Button("Aggiungi") {
                    if let a = stato.aggiungiTelefonataTraguardo(t) {
                        stato.mostraAvviso("Telefonata in agenda: " + TestiTraguardi.quandoTelefonata(a.inizio, oggi: Date()))
                    }
                }
                .buttonStyle(.apple)
                .disabled(stato.solaLettura || prossimoSpazio == nil)
            }
        }
    }

    private var prossimoSpazio: Date? {
        let cal = Calendar.current
        let domani = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
        return MotorePianificazione.primoSpazio(durata: StatoShell.durataTelefonataTraguardo, da: domani,
                                               appuntamenti: stato.dati.appuntamenti, orari: stato.dati.impostazioni.orari)?.inizio
    }

    @ViewBuilder private func rigaRegalo(_ t: Traguardo) -> some View {
        let annotata = stato.notaRegaloTraguardo(t) != nil
        let nota = t.ideaRegalo.map { "\($0.testo) (\($0.fonte))" } ?? TestiTraguardi.senzaIdea
        riga(TestiTraguardi.regalo, nota: nota, ultima: true) {
            if annotata {
                Text("✓ Annotata")
                    .carattereApple(Tema.Apple.Carattere.corpo)
                    .foregroundColor(T.coloreFatto)
            } else if scrivendoIdea {
                TextField("L’idea, in una riga", text: $idea)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: T.larghezzaCampo)
                    .onSubmit { salvaIdea(t) }
            } else {
                Button("Annota") {
                    if let i = t.ideaRegalo {
                        stato.annotaRegaloTraguardo(t, testo: i.testo)
                    } else {
                        idea = ""
                        scrivendoIdea = true
                    }
                }
                .buttonStyle(.apple)
                .disabled(stato.solaLettura)
            }
        }
    }

    private func salvaIdea(_ t: Traguardo) {
        if stato.annotaRegaloTraguardo(t, testo: idea) { scrivendoIdea = false }
    }

    private func riga<Azione: View>(_ titolo: String, nota: String, ultima: Bool = false,
                                    @ViewBuilder azione: () -> Azione) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: T.spazioRiga) {
                VStack(alignment: .leading, spacing: T.spazioTitoloRiga) {
                    Text(titolo)
                        .carattereApple(T.titoloRiga)
                        .foregroundColor(T.coloreTitoloRiga)
                    Text(nota)
                        .carattereApple(T.notaRiga)
                        .foregroundColor(T.coloreNotaRiga)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                azione()
            }
            .padding(.vertical, T.paddingRiga)
            if !ultima {
                Rectangle().fill(T.filo).frame(height: T.spessoreFilo)
            }
        }
    }
}
