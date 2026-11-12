import SwiftUI

// Il pannello del traguardo in Messaggi (versione «Luce», giro 5, Design/template-luce-specifica.md §5.4.1 punto 1.2), al
// posto del compositore quando l'occasione scelta è un traguardo:
//
//   ◉  DA FESTEGGIARE · OBIETTIVO RAGGIUNTO IERI
//      Sofia Romano: ha raggiunto «Rendita integrativa»
//   ┌──────────── biglietto 560×420 ────────────┐   IL MOMENTO, GIÀ PRONTO
//   │ ◯✓  Ce l’hai fatta, Sofia.                 │   Il biglietto                 [⇪ Condividi…] […]
//   │ (120.000 €  messi al sicuro in …)          │     Mostra la cifra                         ( ○)
//   │ …                                — Denis   │   Una telefonata               [Aggiungi] → ✓ In agenda
//   └────────────────────────────────────────────┘   L’idea per un regalo         [Annota]   → ✓ Annotata
//                                                     [◉ La capsula del tempo di Sofia è pronta  Apri la capsula]
//                                                     Prisma si accorge da solo dei traguardi: …
//
// - «Luce» giro 15 (§5.4, decisioni 1, 9 e 115): «Condividi…» disegna il biglietto in PNG nella cartella delle uscite e
//   apre il foglio di condivisione del sistema (lo spedisce il consulente; WhatsApp solo con il consenso del dossier);
//   il file si cancella dopo l'esito, al blocco e alla chiusura. Dopo la condivisione il traguardo è festeggiato e il
//   dossier ne tiene traccia («Dato al cliente»). «Mostra la cifra» è spento di base e vale anche per l'anteprima: si
//   vede ciò che parte. Il menu «…» ha «Salva su file…». Un clic sulla frase la rende modificabile, con «Torna alla
//   frase di Prisma». Sotto le tre righe la tile della capsula del tempo pronta (TileCapsulaTraguardo, se c'è).
// - «Aggiungi» mette una telefonata nel primo spazio libero da domani (StatoTraguardi.swift); il clic dopo apre l'Agenda.
// - L'idea per il regalo viene solo da una frase delle note del dossier; senza, «Nessuna idea dalle note» e «Annota»
//   apre un campo per scriverla. È una nota privata del consulente: in modalità cliente la colonna destra non c'è.
// - «Riduci movimento» e istantanee: cifra completa, anello pieno, niente coriandoli (BigliettoTraguardo).
// - iPhone (§5.4.4, `compatto`, da iOS/MessaggiTelefono.swift): una sola colonna che scorre con la pagina, nella
//   gerarchia di Design/iphone.html: il biglietto in alto, ridotto alla larghezza dello schermo, e sotto le tre azioni
//   (condividi, telefonata, regalo). Niente tile della capsula: la Sala è solo sul Mac.
// Valori in DesignSystem/Apple/Tema.Apple+Traguardi.swift.

@MainActor
struct PannelloTraguardo: View {
    @Environment(StatoShell.self) var stato
    let occasione: OccasioneMessaggio
    let cliente: Cliente
    var base: Double = Tema.Apple.Messaggi.Moto.baseApertura
    var primoIndice = 0
    /// iPhone: una colonna sola, senza scorrimento proprio né superficie (li dà la pagina), biglietto ridotto.
    var compatto = false

    @Environment(\.modoIstantanea) private var istantanea
    @State private var scrivendoIdea = false
    @State private var idea = ""
    /// «Mostra la cifra»: spento di base (decisione 9).
    @State private var mostraCifra = false
    /// La frase scritta a mano (nil = quella di Prisma); vale solo per questo biglietto.
    @State private var fraseModificata: String?
    @State private var modificaFrase = false
    /// Se il biglietto preparato per l'ultima condivisione aveva la cifra (per la traccia nel dossier).
    @State private var cifraCondivisa = false

    private typealias P = Tema.Apple.Messaggi.Pannello
    private typealias T = Tema.Apple.Messaggi.Traguardo
    private typealias F = Tema.Apple.Messaggi.Traguardo.Frase
    private typealias C = Tema.Apple.Messaggi.Traguardo.Condividi

    var body: some View {
        let _ = ContaCorpi.segna()
        // Dai traguardi in cache (StatoTraguardi.swift): il motore non gira su tutto l'archivio a ogni passaggio
        let traguardo = stato.traguardo(occasione.origine.riferimento)
        if compatto {
            colonnaCompatta(traguardo)
        } else {
            affiancato(traguardo)
        }
    }

    /// iPhone: il biglietto in alto, le tre azioni sotto (la colonna destra resta fuori in modalità cliente).
    private func colonnaCompatta(_ traguardo: Traguardo?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            testata(traguardo)
                .entrataCascata(primoIndice, base: base)
            if let t = traguardo {
                VStack(alignment: .leading, spacing: T.spazioColonne) {
                    biglietto(t)
                    if !stato.inModoCliente { colonna(t) }
                }
                .padding(.top, T.sottoTestata)
                .entrataCascata(primoIndice + 1, base: base, sfocatura: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func affiancato(_ traguardo: Traguardo?) -> some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    testata(traguardo)
                        .entrataCascata(primoIndice, base: base)
                    if let t = traguardo {
                        let affiancato = geo.size.width - P.padding.leading - P.padding.trailing >= T.larghezzaAffiancata
                        Group {
                            if affiancato {
                                HStack(alignment: .top, spacing: T.spazioColonne) {
                                    biglietto(t)
                                    if !stato.inModoCliente { colonna(t).frame(maxWidth: .infinity, alignment: .leading) }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: T.spazioColonne) {
                                    biglietto(t)
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

    // MARK: Il biglietto e la sua frase

    /// La frase si cambia solo fuori dalla modalità cliente e fuori dalla sola lettura.
    private var fraseModificabile: Bool {
        !stato.inModoCliente && !stato.solaLettura
    }

    /// Il clic sulla frase apre il campo (nil = la frase non si tocca).
    private var aperturaFrase: (() -> Void)? {
        guard fraseModificabile else { return nil }
        return { modificaFrase = true }
    }

    private func biglietto(_ t: Traguardo) -> some View {
        VStack(alignment: .leading, spacing: F.spazio) {
            if compatto {
                // iPhone: lo stesso biglietto 560×420, ridotto alla larghezza disponibile (mai ingrandito)
                Color.clear
                    .aspectRatio(T.biglietto.width / T.biglietto.height, contentMode: .fit)
                    .frame(maxWidth: T.biglietto.width)
                    .overlay(alignment: .topLeading) {
                        GeometryReader { g in
                            BigliettoTraguardo(traguardo: t, firma: firma, mostraCifra: mostraCifra, frase: fraseModificata,
                                               suFrase: aperturaFrase)
                                .scaleEffect(min(1, g.size.width / T.biglietto.width), anchor: .topLeading)
                                .frame(width: g.size.width, height: g.size.height, alignment: .topLeading)
                        }
                    }
            } else {
                BigliettoTraguardo(traguardo: t, firma: firma, mostraCifra: mostraCifra, frase: fraseModificata,
                                   suFrase: aperturaFrase)
            }
            if modificaFrase && fraseModificabile {
                campoFrase(t)
            }
        }
    }

    private func campoFrase(_ t: Traguardo) -> some View {
        let testo = Binding<String>(
            get: { fraseModificata ?? t.frase },
            set: { nuovo in
                fraseModificata = String(nuovo.prefix(T.Esporta.massimoFrase))
            })
        let forma = RoundedRectangle(cornerRadius: F.raggio, style: .continuous)
        return VStack(alignment: .leading, spacing: F.spazioComandi) {
            TextEditor(text: testo)
                .carattereApple(F.carattere)
                .foregroundColor(F.coloreTesto)
                .scrollContentBackground(.hidden)
                .padding(F.padding)
                .frame(maxWidth: T.biglietto.width, minHeight: F.altezza, maxHeight: F.altezza)
                .background(forma.fill(F.fondo))
                .overlay(forma.strokeBorder(F.bordo, lineWidth: F.spessoreBordo))
                .accessibilityLabel(Text("Frase del biglietto"))
            HStack(spacing: F.spazioComandi) {
                Button(TestiBiglietto.fatto) {
                    fraseModificata = TestiBiglietto.fraseScritta(fraseModificata, traguardo: t)
                    modificaFrase = false
                }
                .buttonStyle(.apple)
                Button(TestiBiglietto.tornaAllaFrase) {
                    fraseModificata = nil
                }
                .buttonStyle(.appleSobrio)
                .disabled(TestiBiglietto.fraseScritta(fraseModificata, traguardo: t) == nil)
                Text(TestiBiglietto.notaFrase)
                    .carattereApple(F.nota)
                    .foregroundColor(F.coloreNota)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: T.biglietto.width, alignment: .leading)
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
            rigaBiglietto(t)
            rigaTelefonata(t)
            rigaRegalo(t)
            // «Luce» giro 15: la capsula del tempo pronta per questo traguardo (compare solo se c'è; la Sala è solo sul Mac)
            if !compatto {
                TileCapsulaTraguardo(traguardo: t)
                    .padding(.top, T.sopraNotaFondo)
            }
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

    // MARK: Il biglietto da condividere

    private func rigaBiglietto(_ t: Traguardo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            riga(TestiTraguardi.biglietto, nota: TestiTraguardi.bigliettoNota, ultima: true) {
                HStack(spacing: C.spazioAzioni) {
                    PulsanteCondividi(titolo: TestiBiglietto.condividi, consensoWhatsApp: cliente.consensi.whatsapp == true,
                                      prepara: { preparaCopia(t) },
                                      esito: { e in dopoCondivisione(e, traguardo: t) })
                        .disabled(stato.solaLettura || istantanea)
                    Menu {
                        Button(TestiBiglietto.salva) { salvaSuFile(t) }
                    } label: {
                        Image(systemName: C.altro)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .disabled(istantanea)
                    .accessibilityLabel(Text(TestiBiglietto.altro))
                }
            }
            VStack(alignment: .leading, spacing: C.spazioSotto) {
                if t.cifra != nil {
                    Toggle(isOn: $mostraCifra) {
                        Text(TestiBiglietto.mostraCifra)
                            .carattereApple(C.interruttore)
                            .foregroundColor(C.coloreInterruttore)
                    }
                    .toggleStyle(StileInterruttoreApple())
                }
                if stato.primaUscita(clienteId: cliente.id) {
                    Text(TestiBiglietto.avvisoPrimaVolta(nome: TestiTraguardi.primoNome(cliente.nome),
                                                         conCifra: mostraCifra && t.cifra != nil))
                        .carattereApple(C.nota)
                        .foregroundColor(C.coloreNota)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, T.paddingRiga)
            Rectangle().fill(T.filo).frame(height: T.spessoreFilo)
        }
    }

    /// Al clic su «Condividi…»: il PNG nella cartella delle uscite (mai in Download).
    private func preparaCopia(_ t: Traguardo) -> [URL]? {
        let conCifra = mostraCifra && t.cifra != nil
        guard let url = EsportaBiglietto.copiaDaCondividere(t, nome: cliente.nome, firma: firma, mostraCifra: mostraCifra,
                                                            frase: fraseModificata) else {
            stato.mostraAvviso(TestiBiglietto.nonDisegnato)
            return nil
        }
        cifraCondivisa = conCifra
        return [url]
    }

    /// Dopo il foglio: condiviso → festeggiato e traccia nel dossier (mai il file, mai il contenuto).
    private func dopoCondivisione(_ e: EsitoCondivisione, traguardo t: Traguardo) {
        switch e {
        case .condiviso(let via):
            stato.segnaFesteggiato(t)
            stato.registraUscita(clienteId: cliente.id, genere: .biglietto,
                                 descrizione: TestiBiglietto.descrizioneUscita(t, conCifra: cifraCondivisa),
                                 via: via, documentoId: nil, protetto: false)
        case .annullato:
            break
        case .nonRiuscito(let motivo):
            stato.mostraAvviso(motivo)
        }
    }

    /// «Salva su file…»: solo se lo sceglie il consulente; il file resta dove lo salva.
    private func salvaSuFile(_ t: Traguardo) {
        guard let dati = EsportaBiglietto.png(t, firma: firma, mostraCifra: mostraCifra, frase: fraseModificata) else {
            stato.mostraAvviso(TestiBiglietto.nonDisegnato)
            return
        }
        EsportaBiglietto.salvaSuFile(dati, nome: TestiBiglietto.nomeFile(t, nome: cliente.nome))
    }

    private func rigaTelefonata(_ t: Traguardo) -> some View {
        let messa = stato.telefonataTraguardo(t)
        // Una volta sola per passaggio: serve alla nota e a «Aggiungi»
        let spazio = prossimoSpazio
        let nota: String
        if let a = messa {
            nota = TestiTraguardi.quandoTelefonata(a.inizio, oggi: Date()) + ", in agenda"
        } else if let s = spazio {
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
                .disabled(stato.solaLettura || spazio == nil)
            }
        }
    }

    /// Il primo spazio libero da domani per la telefonata (lo stesso di `aggiungiTelefonataTraguardo`), una volta per dati
    /// dei calcoli e giorno: dipende solo dagli appuntamenti e dagli orari di lavoro (dati dei calcoli) e da domani, mentre
    /// il motore scorre tutti gli appuntamenti dell'archivio giorno per giorno.
    private var prossimoSpazio: Date? {
        stato.ricavato("traguardi-spazio-telefonata") { () -> Date? in
            let cal = Calendar.current
            let domani = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
            return MotorePianificazione.primoSpazio(durata: StatoShell.durataTelefonataTraguardo, da: domani,
                                                   appuntamenti: stato.dati.appuntamenti, orari: stato.dati.impostazioni.orari)?.inizio
        }
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
