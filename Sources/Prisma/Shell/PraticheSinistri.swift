import SwiftUI
import UniformTypeIdentifiers

// Pratiche › Sinistri, il sinistro come una spedizione (Design/template-luce-specifica.md §7.4, «Luce» giro 15). A
// sinistra «Sinistri aperti e recenti» (larga 300) con «+ Nuovo sinistro»; al centro la testata (tassello arancio,
// titolo, cliente e polizza o «polizza da collegare»), la card della spedizione (cinque fasi su una linea con la barra a
// gradiente fino alla fase di adesso, il nodo di adesso che respira, il nodo rosso «Respinto»; Stato, Indennizzo,
// Aperto da), «Cosa è successo» e «Documenti», «Aggiorna …» e «Sollecita la compagnia»; a destra «Così lo vede …», il
// telefono disegnato con lo schermo sempre chiaro (un'anteprima sul Mac: nulla parte da lì). Clic su un nodo = la
// fase, con il giorno (oggi di base) e, per «Pagato», l'importo. Con «Riduci movimento» e nelle istantanee tutto è già
// fermo (barra alla fase, nodo fermo con l'alone). Stato e azioni in StatoSinistri, conti in MotoreSinistri, valori in
// Tema.Apple.Pratiche.Spedizione.

struct PraticheSinistri: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoPraticheSinistri(stato: stato, sinistri: stato.sinistri)
    }
}

private struct CorpoPraticheSinistri: View {
    let stato: StatoShell
    let sinistri: StatoSinistri

    private typealias P = Tema.Apple.Pratiche
    private typealias S = Tema.Apple.Pratiche.Spedizione

    var body: some View {
        let oggi = Date()
        let elenco = MotoreSinistri.elenco(stato.sinistriVisibili, oggi: oggi)
        let scelto = sceltoEffettivo(elenco)
        ZStack {
            HStack(alignment: .top, spacing: P.spazioLaterale) {
                BarraSinistri(stato: stato, elenco: elenco, scelto: scelto?.id, oggi: oggi)
                    .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                Group {
                    if let s = scelto {
                        SpedizioneSinistro(stato: stato, sinistri: sinistri, sinistro: s, oggi: oggi)
                            .id(s.id)
                    } else {
                        VuotoPratiche(glifo: .sinistro, frase: TestiSinistri.fraseVuota, nota: TestiSinistri.notaVuota,
                                      pulsante: stato.solaLettura || stato.clienti.isEmpty ? nil : TestiSinistri.titoloModulo) {
                            stato.apriNuovoSinistro()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            }
            if sinistri.moduloAperto {
                VeloModuloSinistro()
                ModuloSinistro(stato: stato, sinistri: sinistri)
                    .transition(.opacity)
            }
        }
    }

    /// Il sinistro da mostrare: quello delle istantanee, poi quello scelto (anche un chiuso più vecchio, aperto dal
    /// dossier), poi il primo della barra.
    private func sceltoEffettivo(_ elenco: [Sinistro]) -> Sinistro? {
        let visibili = stato.sinistriVisibili
        if let id = sinistri.istantanea, let s = visibili.first(where: { $0.id == id }) { return s }
        if let id = sinistri.scelto, let s = visibili.first(where: { $0.id == id }) { return s }
        return elenco.first
    }
}

/// Il velo sotto il modulo «Nuovo sinistro» (il clic non chiude: si chiude con «Annulla»).
private struct VeloModuloSinistro: View {
    var body: some View {
        Rectangle()
            .fill(Tema.Apple.Colore.velo)
            .contentShape(Rectangle())
            .onTapGesture {}
            .accessibilityHidden(true)
    }
}

// MARK: - La barra «Sinistri aperti e recenti»

private struct BarraSinistri: View {
    let stato: StatoShell
    let elenco: [Sinistro]
    let scelto: String?
    let oggi: Date

    private typealias P = Tema.Apple.Pratiche

    var body: some View {
        BarraLateralePratiche(titolo: TestiSinistri.titoloBarra) {
            Button(TestiSinistri.nuovo) { stato.apriNuovoSinistro() }
                .buttonStyle(.apple)
                .disabled(stato.solaLettura || stato.clienti.isEmpty)
                .padding(.horizontal, P.paddingVoce.leading)
                .padding(.bottom, P.spazioVoce)
            if elenco.allSatisfy({ MotoreSinistri.chiuso($0) }) {
                Text(TestiSinistri.nessunoAperto)
                    .carattereApple(P.motivoVoce)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .padding(.horizontal, P.paddingVoce.leading)
                    .padding(.bottom, P.spazioVoce)
            }
            ForEach(elenco) { s in
                let cliente = stato.cliente(s.clienteId)
                VoceLateralePratiche(titolo: cliente?.nome ?? "Cliente", sottotitolo: TestiSinistri.voce(s), scelta: s.id == scelto,
                                     azione: { stato.sinistri.scelto = s.id }) {
                    AvatarCliente(iniziali: cliente?.iniziali ?? "", tinta: (cliente?.tinta ?? .blu).colori, lato: P.avatarVoce)
                }
            }
        }
    }
}

// MARK: - La colonna principale

private struct SpedizioneSinistro: View {
    let stato: StatoShell
    let sinistri: StatoSinistri
    let sinistro: Sinistro
    let oggi: Date

    private typealias P = Tema.Apple.Pratiche
    private typealias S = Tema.Apple.Pratiche.Spedizione

    var body: some View {
        let cliente = stato.cliente(sinistro.clienteId)
        let nome = ModelliMessaggi.primoNome(cliente?.nome ?? "il cliente")
        HStack(alignment: .top, spacing: S.spazio) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    TestataSinistro(stato: stato, sinistro: sinistro, cliente: cliente)
                        .padding(.bottom, S.spazioTestata)
                        .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                    CardSpedizione(stato: stato, sinistro: sinistro, oggi: oggi)
                        .padding(.bottom, S.sottoCard)
                        .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                    ColonneProporzionaliDossier(proporzione: S.proporzioneCard, spazio: S.spazioCard, larghezzaMinima: S.larghezzaDueCard) {
                        CardEventiSinistro(stato: stato, sinistro: sinistro, oggi: oggi)
                        CardDocumentiSinistro(stato: stato, sinistri: sinistri, sinistro: sinistro)
                    }
                    .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                    PulsantiSinistro(stato: stato, sinistro: sinistro, nome: nome)
                        .padding(.top, S.sopraPulsanti)
                        .entrataCascata(3, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            AnteprimaTelefonoSinistro(sinistro: sinistro, nome: nome, consulente: stato.nomeConsulenteSinistri, oggi: oggi)
                .frame(width: S.colonnaTelefono)
                .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
        }
    }
}

/// Tassello arancio, titolo, «Marco Bianchi · Infortuni famiglia» con il canale (o «polizza da collegare») e il menu.
private struct TestataSinistro: View {
    let stato: StatoShell
    let sinistro: Sinistro
    let cliente: Cliente?

    @State private var confermaElimina = false
    @State private var respingi = false
    @State private var giornoRespinto = Date()

    private typealias P = Tema.Apple.Pratiche
    private typealias S = Tema.Apple.Pratiche.Spedizione

    var body: some View {
        let polizza = stato.polizzaSinistro(sinistro)
        HStack(alignment: .center, spacing: S.spazioTestata) {
            TasselloGlifo(glifo: .sinistro, lato: S.tassello, tinta: S.tinta)
            VStack(alignment: .leading, spacing: P.spazioSopraTitolo) {
                HStack(alignment: .firstTextBaseline, spacing: S.spazioEtichetta) {
                    Text(sinistro.titolo)
                        .carattereApple(P.titolo)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .lineLimit(2)
                    if sinistro.id.hasPrefix(SinistriDiProva.prefisso) { EtichettaDatiDiProvaPratiche() }
                }
                HStack(spacing: S.spazioEtichetta) {
                    Text((cliente?.nome ?? "Cliente") + " · ")
                        .carattereApple(S.sottotitolo)
                        .foregroundColor(S.coloreSottotitolo)
                    if let p = polizza {
                        Text("polizza \(p.nome)")
                            .carattereApple(S.sottotitolo)
                            .foregroundColor(S.coloreSottotitolo)
                            .lineLimit(1)
                        EtichettaCanale(canale: p.canale, compatta: true)
                    } else {
                        Text(TestiSinistri.polizzaDaCollegare)
                            .carattereApple(S.sottotitolo)
                            .foregroundColor(S.coloreDaCollegare)
                    }
                }
            }
            Spacer(minLength: 0)
            Menu {
                Button(TestiSinistri.titoloModifica) { stato.modificaSinistro(sinistro.id) }
                if sinistro.fase != .respinto {
                    Button("Segna come respinto…") {
                        giornoRespinto = Date()
                        respingi = true
                    }
                }
                Button("Elimina il sinistro…", role: .destructive) { confermaElimina = true }
            } label: {
                Text("Altro")
            }
            .menuStyle(.button)
            .buttonStyle(.appleSobrio)
            .fixedSize()
            .disabled(stato.solaLettura)
            .popover(isPresented: $respingi) {
                PopoverFase(titolo: "Respinto dalla compagnia", conImporto: false, giorno: $giornoRespinto, importo: .constant(nil)) { conferma in
                    if conferma { stato.avanzaSinistro(sinistro.id, a: .respinto, il: giornoRespinto, pagato: nil) }
                    respingi = false
                }
            }
        }
        .confirmationDialog("Eliminare il sinistro «\(sinistro.titolo)»?", isPresented: $confermaElimina, titleVisibility: .visible) {
            Button("Elimina il sinistro", role: .destructive) { stato.eliminaSinistro(sinistro.id) }
        } message: {
            Text("Fasi, fatti e documenti del sinistro escono da Prisma. I file restano nei Documenti del cliente.")
        }
    }
}

// MARK: - La spedizione

private struct CardSpedizione: View {
    let stato: StatoShell
    let sinistro: Sinistro
    let oggi: Date

    private typealias S = Tema.Apple.Pratiche.Spedizione

    var body: some View {
        let soglia = stato.dati.impostazioni.pratiche.sogliaSinistroFermo
        let fermo = MotoreSinistri.fermo(sinistro, oggi: oggi, soglia: soglia)
        VStack(alignment: .leading, spacing: 0) {
            LineaSpedizione(stato: stato, sinistro: sinistro)
            HStack(alignment: .top, spacing: S.spazioCifre) {
                cifra(TestiSinistri.stato, sinistro.fase.nome)
                cifra(TestiSinistri.indennizzo, MotoreSinistri.indennizzo(sinistro))
                VStack(alignment: .leading, spacing: S.spazioCifra) {
                    HStack(spacing: S.spazioEtichetta) {
                        Text(TestiSinistri.apertoDa)
                            .carattereApple(S.etichettaCifra)
                            .foregroundColor(S.coloreEtichettaCifra)
                        if fermo {
                            Text(TestiSinistri.fermo)
                                .carattereApple(S.fermo)
                                .foregroundColor(S.coloreFermo)
                        }
                    }
                    Text(TestiSinistri.giorni(MotoreSinistri.giorniAperto(sinistro, oggi: oggi)))
                        .carattereApple(S.cifra)
                        .foregroundColor(S.coloreCifra)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, S.sopraCifre)
        }
        .padding(S.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(S.superficie, raggio: S.raggio)
    }

    private func cifra(_ etichetta: String, _ valore: String) -> some View {
        VStack(alignment: .leading, spacing: S.spazioCifra) {
            Text(etichetta)
                .carattereApple(S.etichettaCifra)
                .foregroundColor(S.coloreEtichettaCifra)
            Text(valore)
                .carattereApple(S.cifra)
                .foregroundColor(S.coloreCifra)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

/// La linea delle fasi: nodi a distanza uguale (34 di margine ai lati), la barra sottile che li unisce e si riempie dal
/// verde all'arancio fino alla fase di adesso (tutta verde a «Pagato», verso il rosso per un respinto), le etichette sotto.
/// Clic su un nodo del percorso: quella fase, con il giorno e, per «Pagato», l'importo.
private struct LineaSpedizione: View {
    let stato: StatoShell
    let sinistro: Sinistro

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var avanzamento: CGFloat = 0
    @State private var faseScelta: FaseSinistro? = nil
    @State private var giorno = Date()
    @State private var importo: Double? = nil

    private typealias S = Tema.Apple.Pratiche.Spedizione

    var body: some View {
        let nodi = MotoreSinistri.linea(sinistro)
        let meta = CGFloat(MotoreSinistri.riempimento(sinistro))
        let colori: [Color] = sinistro.fase == .pagato ? [S.pieno, S.pieno]
            : (sinistro.fase == .respinto ? [S.pieno, S.respinto] : S.gradiente)
        GeometryReader { geo in
            let larghezza = max(0, geo.size.width - S.margine * 2)
            let passo = nodi.count > 1 ? larghezza / CGFloat(nodi.count - 1) : 0
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: S.raggioBarra, style: .continuous)
                    .fill(S.binario)
                    .frame(width: larghezza, height: S.barra)
                    .offset(x: S.margine, y: (S.nodo - S.barra) / 2)
                RoundedRectangle(cornerRadius: S.raggioBarra, style: .continuous)
                    .fill(LinearGradient(colors: colori, startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, larghezza * avanzamento), height: S.barra)
                    .offset(x: S.margine, y: (S.nodo - S.barra) / 2)
                ForEach(Array(nodi.enumerated()), id: \.offset) { i, nodo in
                    let x = S.margine + passo * CGFloat(i)
                    NodoSpedizione(stato: nodo.stato)
                        .contentShape(Circle())
                        .onTapGesture { scegli(nodo.fase) }
                        .popover(isPresented: Binding(get: { faseScelta == nodo.fase && nodo.fase != .respinto },
                                                      set: { if !$0 { faseScelta = nil } })) {
                            PopoverFase(titolo: nodo.fase.nome, conImporto: nodo.fase == .pagato, giorno: $giorno, importo: $importo) { conferma in
                                if conferma { stato.avanzaSinistro(sinistro.id, a: nodo.fase, il: giorno, pagato: importo) }
                                faseScelta = nil
                            }
                        }
                        .position(x: x, y: S.nodo / 2)
                        .accessibilityLabel(Text(nodo.fase.nome))
                        .accessibilityAddTraits(.isButton)
                    Text(nodo.fase.nome)
                        .carattereApple(S.etichetta)
                        .foregroundColor(colore(nodo.stato))
                        .fixedSize()
                        .position(x: x, y: S.nodo + S.sottoNodo + S.etichetta.dimensione / 2 + 1)
                }
            }
        }
        .frame(height: S.altezza)
        .onAppear { avvia(meta) }
        .onChange(of: meta) { _, nuovo in
            if Tema.Apple.Moto.statoFinale(calmo: calmo, istantanea: istantanea) {
                avanzamento = nuovo
            } else {
                withAnimation(Tema.Apple.Pratiche.Moto.Spedizione.nodo) { avanzamento = nuovo }
            }
        }
    }

    private func avvia(_ meta: CGFloat) {
        if Tema.Apple.Moto.statoFinale(calmo: calmo, istantanea: istantanea) {
            avanzamento = meta
            return
        }
        avanzamento = 0
        withAnimation(Tema.Apple.Pratiche.Moto.Spedizione.animazione) { avanzamento = meta }
    }

    private func scegli(_ fase: FaseSinistro) {
        guard !stato.solaLettura, fase != .respinto, fase != sinistro.fase else { return }
        giorno = Date()
        importo = fase == .pagato ? sinistro.pagato : nil
        faseScelta = fase
    }

    private func colore(_ s: SinistroMini.StatoFase) -> Color {
        switch s {
        case .fatta: return S.etichettaFatta
        case .adesso: return S.etichettaAdesso
        case .futura: return S.etichettaFutura
        case .respinta: return S.etichettaRespinta
        }
    }
}

/// Un nodo della linea: fatto verde pieno, adesso con il bordo arancio, l'alone e il respiro (fermo con calma e nelle
/// istantanee), futuro con il bordo del binario, respinto rosso con l'alone.
private struct NodoSpedizione: View {
    let stato: SinistroMini.StatoFase

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var respira = false

    private typealias S = Tema.Apple.Pratiche.Spedizione
    private typealias R = Tema.Apple.Pratiche.Moto.RespiroNodo

    var body: some View {
        ZStack {
            switch stato {
            case .fatta:
                Circle().fill(S.fatto)
            case .adesso:
                Circle().fill(S.aloneAdesso).frame(width: S.nodo + S.alone * 2, height: S.nodo + S.alone * 2)
                Circle().fill(S.fondoNodo)
                Circle().strokeBorder(S.adesso, lineWidth: S.bordoNodo)
            case .futura:
                Circle().fill(S.fondoNodo)
                Circle().strokeBorder(S.futuro, lineWidth: S.bordoNodo)
            case .respinta:
                Circle().fill(S.aloneRespinto).frame(width: S.nodo + S.alone * 2, height: S.nodo + S.alone * 2)
                Circle().fill(S.respinto)
            }
        }
        .frame(width: S.nodo, height: S.nodo)
        .scaleEffect(respira ? R.scala : 1)
        .onAppear {
            guard stato == .adesso, !Tema.Apple.Moto.statoFinale(calmo: calmo, istantanea: istantanea) else { return }
            withAnimation(R.animazione) { respira = true }
        }
        .animation(Tema.Apple.Moto.animazione(Tema.Apple.Pratiche.Moto.Spedizione.nodo, calmo: calmo, istantanea: istantanea), value: stato)
    }
}

/// Il popover della fase (e del fatto nuovo): il giorno, per «Pagato» l'importo, «Segna» e «Annulla».
private struct PopoverFase: View {
    let titolo: String
    let conImporto: Bool
    @Binding var giorno: Date
    @Binding var importo: Double?
    let fine: (Bool) -> Void

    private typealias S = Tema.Apple.Pratiche.Spedizione
    private static let numero = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...2))

    var body: some View {
        VStack(alignment: .leading, spacing: S.spazioPopover) {
            Text(titolo)
                .carattereApple(S.titoloPopover)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            DatePicker("Il giorno", selection: $giorno, displayedComponents: .date)
            if conImporto {
                HStack(spacing: S.spazioEtichetta) {
                    Text("Importo pagato")
                    TextField("€", value: $importo, format: Self.numero)
                        .textFieldStyle(.roundedBorder)
                    Text("€")
                }
            }
            HStack(spacing: S.spazioPulsanti) {
                Spacer(minLength: 0)
                Button("Annulla") { fine(false) }
                    .buttonStyle(.apple)
                    .keyboardShortcut(.cancelAction)
                Button("Segna") { fine(true) }
                    .buttonStyle(.applePrimario)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(S.paddingPopover)
        .frame(width: S.larghezzaPopover)
    }
}

// MARK: - Cosa è successo

private struct CardEventiSinistro: View {
    let stato: StatoShell
    let sinistro: Sinistro
    let oggi: Date

    @State private var nuovo = false
    @State private var giorno = Date()
    @State private var testo = ""

    private typealias S = Tema.Apple.Pratiche.Spedizione

    var body: some View {
        let eventi = sinistro.eventi.enumerated().sorted { a, b in
            a.element.data != b.element.data ? a.element.data < b.element.data : a.offset < b.offset
        }.map(\.element)
        VStack(alignment: .leading, spacing: S.sottoTitoloCard) {
            Text(TestiSinistri.cosaESuccesso)
                .carattereApple(S.titoloCard)
                .foregroundColor(S.coloreTitoloCard)
            if eventi.isEmpty {
                Text(TestiSinistri.nessunFatto)
                    .carattereApple(S.nota)
                    .foregroundColor(S.coloreNota)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(eventi) { e in
                    RigaFattoSinistro(stato: stato, sinistro: sinistro, evento: e, futuro: e.data > oggi)
                }
            }
            Button(TestiSinistri.aggiungi) {
                giorno = Date()
                testo = ""
                nuovo = true
            }
            .buttonStyle(.appleSobrio)
            .disabled(stato.solaLettura)
            .popover(isPresented: $nuovo) {
                VStack(alignment: .leading, spacing: S.spazioPopover) {
                    Text(TestiSinistri.cosaESuccesso)
                        .carattereApple(S.titoloPopover)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    DatePicker("Il giorno", selection: $giorno, displayedComponents: .date)
                    TextField("Un fatto breve", text: $testo)
                        .textFieldStyle(.roundedBorder)
                    Text(TestiSinistri.notaBreve)
                        .carattereApple(S.nota)
                        .foregroundColor(S.coloreNota)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: S.spazioPulsanti) {
                        Spacer(minLength: 0)
                        Button("Annulla") { nuovo = false }
                            .buttonStyle(.apple)
                            .keyboardShortcut(.cancelAction)
                        Button("Aggiungi") {
                            stato.aggiungiFattoSinistro(sinistro.id, data: giorno, testo: testo)
                            nuovo = false
                        }
                        .buttonStyle(.applePrimario)
                        .keyboardShortcut(.defaultAction)
                        .disabled(testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(S.paddingPopover)
                .frame(width: S.larghezzaPopover)
            }
            Spacer(minLength: 0)
        }
        .padding(S.paddingCardPiccola)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(S.superficie, raggio: S.raggio)
    }
}

/// Una riga di «Cosa è successo»: la data in grassetto (larga 52) e il fatto; un fatto futuro con «Mettilo in Agenda».
private struct RigaFattoSinistro: View {
    let stato: StatoShell
    let sinistro: Sinistro
    let evento: EventoSinistro
    let futuro: Bool

    private typealias S = Tema.Apple.Pratiche.Spedizione

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: S.spazioRiga) {
            Text(Formati.giornoMeseBreve.string(from: evento.data))
                .carattereApple(S.data)
                .foregroundColor(S.coloreData)
                .frame(width: S.colonnaData, alignment: .leading)
            VStack(alignment: .leading, spacing: S.spazioCifra) {
                Text(evento.testo)
                    .carattereApple(S.fatto13)
                    .foregroundColor(futuro ? S.futuroFatto : S.coloreFatto)
                    .fixedSize(horizontal: false, vertical: true)
                if futuro && !stato.fattoInAgenda(sinistro, evento: evento) {
                    Button(TestiSinistri.mettiInAgenda) { stato.mettiInAgendaFattoSinistro(sinistro.id, evento: evento.id) }
                        .buttonStyle(.appleSobrio)
                        .disabled(stato.solaLettura)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, S.paddingRiga)
        .overlay(alignment: .bottom) {
            Rectangle().fill(S.filo).frame(height: Tema.Apple.Misura.bordo)
        }
        .contextMenu {
            Button("Togli il fatto", role: .destructive) { stato.togliFattoSinistro(sinistro.id, evento: evento.id) }
                .disabled(stato.solaLettura)
        }
    }
}

// MARK: - Documenti

private struct CardDocumentiSinistro: View {
    let stato: StatoShell
    let sinistri: StatoSinistri
    let sinistro: Sinistro

    @State private var nuovo = false
    @State private var titolo = ""

    private typealias S = Tema.Apple.Pratiche.Spedizione

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: S.raggio, style: .continuous)
        VStack(alignment: .leading, spacing: S.sottoTitoloCard) {
            Text(TestiSinistri.documenti)
                .carattereApple(S.titoloCard)
                .foregroundColor(S.coloreTitoloCard)
            if sinistro.documenti.isEmpty {
                Text(TestiSinistri.nessunDocumento)
                    .carattereApple(S.nota)
                    .foregroundColor(S.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sinistro.documenti) { d in
                    RigaDocumentoSinistro(stato: stato, sinistro: sinistro, documento: d)
                }
            }
            Button(TestiSinistri.aggiungi) {
                titolo = ""
                nuovo = true
            }
            .buttonStyle(.appleSobrio)
            .disabled(stato.solaLettura)
            .popover(isPresented: $nuovo) {
                VStack(alignment: .leading, spacing: S.spazioPopover) {
                    Text("Documento richiesto")
                        .carattereApple(S.titoloPopover)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    TextField("Il nome del documento", text: $titolo)
                        .textFieldStyle(.roundedBorder)
                    HStack(spacing: S.spazioPulsanti) {
                        Spacer(minLength: 0)
                        Button("Annulla") { nuovo = false }
                            .buttonStyle(.apple)
                            .keyboardShortcut(.cancelAction)
                        Button("Aggiungi") {
                            stato.aggiungiDocumentoSinistro(sinistro.id, titolo: titolo)
                            nuovo = false
                        }
                        .buttonStyle(.applePrimario)
                        .keyboardShortcut(.defaultAction)
                        .disabled(titolo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(S.paddingPopover)
                .frame(width: S.larghezzaPopover)
            }
            if !sinistro.documenti.isEmpty {
                Text(TestiSinistri.trascinaQui)
                    .carattereApple(S.nota)
                    .foregroundColor(S.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(S.paddingCardPiccola)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(S.superficie, raggio: S.raggio)
        .overlay {
            if sinistri.rilascioAttivo {
                forma.strokeBorder(S.rilascio, style: StrokeStyle(lineWidth: S.trattoRilascio, dash: S.tratteggioRilascio))
                    .allowsHitTesting(false)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            stato.importaFileSinistro(sinistro.id, documento: nil, urls: urls)
            return !urls.isEmpty
        } isTargeted: { sinistri.rilascioAttivo = $0 }
    }
}

/// Un documento richiesto: spunta verde se ricevuto, cerchio vuoto se manca. Clic sul cerchio = ricevuto oggi (un
/// secondo clic lo torna mancante); un file trascinato sulla riga va nei Documenti del cliente e lo segna ricevuto.
private struct RigaDocumentoSinistro: View {
    let stato: StatoShell
    let sinistro: Sinistro
    let documento: DocumentoSinistro

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    private typealias S = Tema.Apple.Pratiche.Spedizione

    var body: some View {
        let ricevuto = documento.ricevutoIl != nil
        let mancaFile = documento.documentoId.map { id in !stato.dati.documenti.contains { $0.id == id } } ?? false
        HStack(spacing: S.spazioRiga) {
            Button {
                stato.segnaDocumentoRicevuto(sinistro.id, documento: documento.id)
            } label: {
                ZStack {
                    Circle().fill(ricevuto ? S.ricevuto : Color.clear)
                    Circle().strokeBorder(ricevuto ? S.ricevuto : S.mancante, lineWidth: S.bordoCerchietto)
                    SpuntaPiccolaApple()
                        .stroke(S.spuntaNodo, style: StrokeStyle(lineWidth: S.spuntaTratto, lineCap: .butt, lineJoin: .miter))
                        .opacity(ricevuto ? 1 : 0)
                }
                .frame(width: S.cerchietto, height: S.cerchietto)
                .contentShape(Circle())
            }
            .buttonStyle(StileSemplice())
            .disabled(stato.solaLettura)
            .accessibilityLabel(Text(documento.titolo))
            .accessibilityValue(Text(ricevuto ? "ricevuto" : "mancante"))
            VStack(alignment: .leading, spacing: S.spazioCifra) {
                Text(documento.titolo)
                    .carattereApple(S.fatto13)
                    .foregroundColor(S.coloreFatto)
                    .fixedSize(horizontal: false, vertical: true)
                if let r = documento.ricevutoIl {
                    Text("ricevuto il \(Formati.giornoMeseBreve.string(from: r))" + (mancaFile ? " · " + TestiSinistri.nonPiuNeiDocumenti : ""))
                        .carattereApple(S.nota)
                        .foregroundColor(S.coloreNota)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, S.paddingRiga)
        .overlay(alignment: .bottom) {
            Rectangle().fill(S.filo).frame(height: Tema.Apple.Misura.bordo)
        }
        .animation(Tema.Apple.Moto.animazione(Tema.Apple.Pratiche.Moto.Spedizione.nodo, calmo: calmo, istantanea: istantanea), value: ricevuto)
        .contentShape(Rectangle())
        .dropDestination(for: URL.self) { urls, _ in
            stato.importaFileSinistro(sinistro.id, documento: documento.id, urls: urls)
            return !urls.isEmpty
        }
        .contextMenu {
            Button("Togli il documento", role: .destructive) { stato.togliDocumentoSinistro(sinistro.id, documento: documento.id) }
                .disabled(stato.solaLettura)
        }
    }
}

// MARK: - I pulsanti

private struct PulsantiSinistro: View {
    let stato: StatoShell
    let sinistro: Sinistro
    let nome: String

    private typealias S = Tema.Apple.Pratiche.Spedizione

    var body: some View {
        HStack(spacing: S.spazioPulsanti) {
            Button(TestiSinistri.aggiorna(nome)) { stato.aggiornaClienteSinistro(sinistro.id) }
                .buttonStyle(.applePrimarioGrande)
                .disabled(sinistro.mostraAlCliente != true)
                .help(sinistro.mostraAlCliente == true ? "Prepara in Messaggi l'aggiornamento: fase e ultimo fatto, niente referti né numeri di polizza"
                                                      : TestiSinistri.aggiornamentiSpenti(nome))
            Button(stato.titoloSollecito(sinistro)) { sollecita() }
                .buttonStyle(.appleGrande)
                .disabled(stato.solaLettura)
                .help("Bozza in Mail all'indirizzo dei sinistri della compagnia: solo numero di polizza, numero di sinistro e assicurato")
            Spacer(minLength: 0)
        }
    }

    private func sollecita() {
        let esito = stato.sollecitaCompagnia(sinistro.id)
        stato.mostraAvviso(esito.messaggio)
    }
}

// MARK: - Così lo vede …

/// La colonna «Così lo vede …»: il telefono disegnato (scala 0,82 dall'alto) con lo schermo del cliente, sempre chiaro;
/// con gli aggiornamenti spenti la frase al posto dell'anteprima.
struct AnteprimaTelefonoSinistro: View {
    let sinistro: Sinistro
    let nome: String
    let consulente: String
    let oggi: Date

    private typealias T = Tema.Apple.Pratiche.TelefonoCliente

    var body: some View {
        VStack(alignment: .center, spacing: T.sottoTitoloColonna) {
            Text(TestiSinistri.cosiLoVede(nome))
                .carattereApple(T.titoloColonna)
                .foregroundColor(T.coloreTitoloColonna)
            if sinistro.mostraAlCliente == true {
                TelefonoDisegnato {
                    SchermoSinistroCliente(mini: sinistro.perIlCliente(consulente: consulente, oggi: oggi), nome: nome)
                }
                .scaleEffect(T.scala, anchor: .top)
                .frame(width: T.larghezza * T.scala, height: T.altezza * T.scala, alignment: .top)
                Text(TestiSinistri.anteprima)
                    .carattereApple(T.notaColonna)
                    .foregroundColor(T.coloreNotaColonna)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: T.sottoTitoloColonna) {
                    Text(TestiSinistri.aggiornamentiSpenti(nome))
                        .carattereApple(T.spenta)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    Text(TestiSinistri.comeAccenderli)
                        .carattereApple(T.notaSpenta)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: T.larghezzaSpenta)
                .padding(.top, T.sopra)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

/// Lo schermo del cliente sul telefono: «IL PRISMA DI MARCO», il titolo, la card bianca con le fasi in colonna,
/// l'ultimo fatto e «Aggiornato da Denis · 29 ott». Colori fissi (sempre chiaro, `Tema.Apple.MiniCliente`).
struct SchermoSinistroCliente: View {
    let mini: SinistroMini
    let nome: String

    private typealias T = Tema.Apple.Pratiche.TelefonoCliente

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(T.fondo)
            VStack(alignment: .leading, spacing: 0) {
                Text(TestiSinistri.ilPrismaDi(nome))
                    .carattereApple(T.occhielloCarattere)
                    .foregroundColor(T.occhiello)
                Text(mini.titolo)
                    .carattereApple(T.titolo)
                    .foregroundColor(T.testo)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, T.spazioTitolo)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(mini.fasi.enumerated()), id: \.offset) { _, f in
                        HStack(spacing: T.spazioFase) {
                            CerchioFaseCliente(stato: f.stato)
                            Text(f.nome)
                                .carattereApple(f.stato == .futura ? T.fase : T.faseForte)
                                .foregroundColor(f.stato == .futura ? T.futuro : T.testo)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, T.paddingFase)
                    }
                }
                .padding(T.paddingCard)
                .background(
                    RoundedRectangle(cornerRadius: T.raggioCard, style: .continuous)
                        .fill(T.card)
                        .shadow(color: T.ombra, radius: T.ombraRaggio, x: 0, y: T.ombraY)
                )
                .padding(.top, T.sopraCard)
                if let u = mini.ultimoFatto {
                    Text(ModelliMessaggi.frase(u))
                        .carattereApple(T.ultimo)
                        .foregroundColor(T.occhiello)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, T.sopraUltimo)
                }
                if let p = mini.pagato {
                    Text("Pagati \(p).")
                        .carattereApple(T.faseForte)
                        .foregroundColor(T.testo)
                        .padding(.top, T.spazioPiede)
                }
                Text(TestiSinistri.aggiornatoDa(mini.consulente, il: mini.aggiornatoIl))
                    .carattereApple(T.aggiornato)
                    .foregroundColor(T.piede)
                    .padding(.top, T.spazioPiede)
            }
            .padding(.top, T.sopra)
            .padding(.horizontal, T.lati)
        }
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .combine)
    }
}

/// Il cerchio di una fase sullo schermo del cliente: 16, verde (fatta), arancio con l'alone 4 (adesso), vuoto con il
/// bordo 2 (futura), rosso (respinta).
private struct CerchioFaseCliente: View {
    let stato: SinistroMini.StatoFase

    private typealias T = Tema.Apple.Pratiche.TelefonoCliente

    var body: some View {
        ZStack {
            switch stato {
            case .fatta:
                Circle().fill(T.fatta)
            case .adesso:
                Circle().fill(T.aloneAdesso).frame(width: T.cerchio + T.aloneCerchio * 2, height: T.cerchio + T.aloneCerchio * 2)
                Circle().fill(T.adesso)
            case .futura:
                Circle().strokeBorder(T.cerchioVuoto, lineWidth: T.bordoVuoto)
            case .respinta:
                Circle().fill(T.respinta)
            }
        }
        .frame(width: T.cerchio, height: T.cerchio)
    }
}

// MARK: - Nel dossier

/// I sinistri del cliente nella panoramica del dossier: «Sinistri aperti: 1 · Perizia ›» (apre Pratiche › Sinistri sul
/// sinistro) e «Apri un sinistro…». Solo per i clienti che hanno un sinistro; mai in modalità cliente.
struct SinistriDossierApple: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente

    var body: some View {
        let _ = ContaCorpi.segna()
        let p = Tema.Apple.Clienti.Panoramica.self
        let d = Tema.Apple.Pratiche.DossierSinistri.self
        let suoi = MotoreSinistri.elenco(stato.dati.sinistri.filter { $0.clienteId == cliente.id }, oggi: Date())
        let aperti = suoi.filter { !MotoreSinistri.chiuso($0) }
        VStack(alignment: .leading, spacing: d.spazio) {
            Text("Sinistri")
                .carattereApple(p.titolo)
                .foregroundColor(p.coloreTitolo)
            if let primo = aperti.first ?? suoi.first {
                Button(TestiSinistri.rigaDossier(aperti: aperti.count, fase: aperti.first?.fase)) { stato.mostraSinistro(primo.id) }
                    .buttonStyle(.appleSobrio)
                Text(primo.titolo)
                    .carattereApple(d.dettaglio)
                    .foregroundColor(d.coloreDettaglio)
                    .lineLimit(1)
            }
            Button(TestiSinistri.apriUnSinistro) { stato.apriNuovoSinistro(cliente: cliente.id) }
                .buttonStyle(.appleSobrio)
                .disabled(stato.solaLettura)
        }
        .padding(p.paddingLaterali)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .superficieApple(p.superficie)
    }
}
