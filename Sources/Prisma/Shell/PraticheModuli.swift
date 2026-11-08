import SwiftUI
import UniformTypeIdentifiers

// Pratiche › Moduli, «Compila da solo» (Design/template-luce-specifica.md §7.2, «Luce» giro 10). A sinistra «I tuoi
// moduli» (larga 290), al centro la pagina del PDF vero dell'utente su un piano grigio con le caselle disegnate sopra, a
// destra «Compila per» con i clienti, «✦ Compila con i dati di …» e, dopo la compilazione, le tile: campi compilati,
// Vera con i dati che mancano, le firme da raccogliere, le risposte che dà il cliente. Le caselle si riempiono una alla
// volta e il valore si scrive lettera per lettera; con «Riduci movimento» e nelle istantanee tutto è già fermo. Lo stato
// sta in StatoModuli, i conti in CompilatoreModuli, i valori in Tema.Apple.Pratiche.Moduli.

struct PraticheModuli: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoPraticheModuli(stato: stato, moduli: stato.moduli)
    }
}

private struct CorpoPraticheModuli: View {
    let stato: StatoShell
    let moduli: StatoModuli
    @State private var importa = false

    private typealias P = Tema.Apple.Pratiche
    private typealias M = Tema.Apple.Pratiche.Moduli

    var body: some View {
        Group {
            if let r = moduli.revisione {
                RevisioneModulo(stato: stato, moduli: moduli, revisione: r)
            } else if stato.dati.clienti.isEmpty && moduli.tutti.isEmpty {
                VuotoPratiche(glifo: .modulo, frase: "Aggiungi un cliente per iniziare",
                              nota: "I moduli si compilano con i dati del dossier dei tuoi clienti.",
                              pulsante: "Apri Clienti") { stato.apri(.clienti) }
            } else {
                HStack(alignment: .top, spacing: P.spazioLaterale) {
                    BarraModuli(stato: stato, moduli: moduli, importa: $importa)
                        .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                    Group {
                        if let m = moduli.modelloScelto {
                            HStack(alignment: .top, spacing: M.spazioColonne) {
                                PianoPagina(stato: stato, moduli: moduli, modello: m)
                                ColonnaCompila(stato: stato, moduli: moduli, modello: m)
                                    .frame(width: M.colonnaDestra)
                            }
                        } else {
                            ZonaRilascio(stato: stato, moduli: moduli, importa: $importa)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
            }
        }
        .fileImporter(isPresented: $importa, allowedContentTypes: [.pdf], allowsMultipleSelection: true) { esito in
            if case .success(let urls) = esito { stato.importaModuli(urls) }
        }
    }
}

// MARK: - La barra «I tuoi moduli»

private struct BarraModuli: View {
    let stato: StatoShell
    let moduli: StatoModuli
    @Binding var importa: Bool
    @State private var daTogliere: ModelloModulo?

    private typealias P = Tema.Apple.Pratiche
    private typealias M = Tema.Apple.Pratiche.Moduli

    var body: some View {
        let elenco = moduli.tutti
        let scelto = moduli.modelloScelto?.id
        BarraLateralePratiche(titolo: "I tuoi moduli", larghezza: P.lateraleModuli, piede: AnyView(piede(vuota: elenco.isEmpty))) {
            if elenco.isEmpty {
                VStack(alignment: .leading, spacing: P.spazioVoce) {
                    TasselloGlifo(glifo: .modulo, lato: M.tassello, tinta: M.tasselloSpento)
                    Text("Moduli da preparare")
                        .carattereApple(P.titoloVoce)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                }
                .padding(P.paddingVoce)
            } else {
                ForEach(elenco) { m in
                    VoceLateralePratiche(titolo: m.titolo, sottotitolo: m.sottotitolo, scelta: m.id == scelto,
                                         azione: { stato.scegliModulo(m.id) }) {
                        TasselloGlifo(glifo: .modulo, lato: M.tassello, tinta: m.id == scelto ? M.tasselloScelto : M.tasselloSpento)
                    }
                    .contextMenu {
                        Button("Rivedi la mappa dei campi") { stato.avviaRevisioneModulo(m.id) }
                        Button("Togli il modulo…", role: .destructive) { daTogliere = m }
                    }
                }
            }
        }
        .overlay {
            if moduli.rilascioAttivo {
                RoundedRectangle(cornerRadius: P.raggioLaterale, style: .continuous)
                    .strokeBorder(M.rilascioAttivo, style: StrokeStyle(lineWidth: M.trattoRilascio, dash: M.tratteggioRilascio))
                    .allowsHitTesting(false)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            stato.importaModuli(urls)
            return !urls.isEmpty
        } isTargeted: { moduli.rilascioAttivo = $0 }
        .confirmationDialog("Togliere il modulo «\(daTogliere?.titolo ?? "")»?",
                            isPresented: Binding(get: { daTogliere != nil }, set: { if !$0 { daTogliere = nil } }),
                            titleVisibility: .visible) {
            Button("Togli il modulo", role: .destructive) {
                if let m = daTogliere { stato.moduli.togli(m.id) }
                daTogliere = nil
            }
        } message: {
            Text("Il PDF vuoto e la sua mappa escono da Prisma. I moduli già compilati restano nei Documenti dei clienti.")
        }
    }

    private func piede(vuota: Bool) -> some View {
        VStack(alignment: .leading, spacing: M.spazioPiede) {
            Text("Moduli Alleanza: non ancora. Si compilano con gli strumenti della compagnia finché Alleanza non conferma che si possono usare qui.")
                .carattereApple(M.notaAlleanza)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
            Text("Carichi una volta i moduli che usi: Prisma riconosce i campi e li compila con i dati del dossier.")
                .carattereApple(M.fraseBarra)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
            Button("Aggiungi un modulo") { importa = true }
                .buttonStyle(vuota ? .applePrimario : .apple)
                .disabled(stato.solaLettura)
        }
        .padding(.horizontal, P.paddingVoce.leading)
    }
}

/// Nessun modulo caricato: la zona tratteggiata dove trascinare il PDF.
private struct ZonaRilascio: View {
    let stato: StatoShell
    let moduli: StatoModuli
    @Binding var importa: Bool

    private typealias M = Tema.Apple.Pratiche.Moduli

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: M.raggioPiano, style: .continuous)
        VuotoPratiche(glifo: .modulo, frase: "Trascina qui il PDF di un modulo",
                      nota: "Proposta, privacy, mandato, questionario, adeguata verifica: i moduli veri che usi per il canale indipendente. Prisma riconosce i campi, tu controlli la mappa una volta.",
                      pulsante: "Aggiungi un modulo") { importa = true }
            .padding(M.marginePiano)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(forma.fill(M.fondoPiano))
            .overlay(forma.strokeBorder(moduli.rilascioAttivo ? M.rilascioAttivo : M.coloreRilascio,
                                        style: StrokeStyle(lineWidth: M.trattoRilascio, dash: M.tratteggioRilascio)))
            .dropDestination(for: URL.self) { urls, _ in
                stato.importaModuli(urls)
                return !urls.isEmpty
            } isTargeted: { moduli.rilascioAttivo = $0 }
    }
}

// MARK: - La pagina del modulo

/// Lo stato di una casella sulla pagina.
enum AspettoCasella: Equatable {
    case piena(String, aMano: Bool)
    case manca
    case firma
    case risposta
}

private struct PianoPagina: View {
    let stato: StatoShell
    let moduli: StatoModuli
    let modello: ModelloModulo

    private typealias M = Tema.Apple.Pratiche.Moduli
    /// La larghezza in pixel a cui si disegna la pagina (una sola misura: l'immagine resta in memoria).
    private static let larghezzaDisegno: CGFloat = 1000

    var body: some View {
        let pagina = min(moduli.pagina, max(0, modello.pagine - 1))
        let b = moduli.riquadroPagina(modello, pagina: pagina)
        let forma = RoundedRectangle(cornerRadius: M.raggioPiano, style: .continuous)
        GeometryReader { geo in
            let frecce: CGFloat = modello.pagine > 1 ? Tema.Apple.Pratiche.Moduli.altezzaFrecce : 0
            let k = min(M.scalaPagina * FacSimileModulo.formato.width / b.width,
                        (geo.size.width - M.marginePiano * 2) / b.width,
                        (geo.size.height - M.margineAltoPiano - M.marginePiano - frecce) / b.height)
            VStack(spacing: M.spazioPagine) {
                ZStack(alignment: .topLeading) {
                    if let img = moduli.immagine(modello, pagina: pagina, larghezza: Self.larghezzaDisegno) {
                        Image(decorative: img, scale: 1)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: b.width * k, height: b.height * k)
                    } else {
                        Rectangle().fill(M.fondoPagina).frame(width: b.width * k, height: b.height * k)
                    }
                    caselle(pagina: pagina, b: b, k: k)
                }
                .frame(width: b.width * k, height: b.height * k, alignment: .topLeading)
                .background(M.fondoPagina)
                .shadow(color: M.ombraPagina, radius: M.ombraRaggio, x: 0, y: M.ombraY)
                if modello.pagine > 1 { frecceDellePagine(pagina) }
            }
            .padding(.top, M.margineAltoPiano)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .background(forma.fill(M.fondoPiano))
        .clipShape(forma)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(modello.titolo), pagina \(pagina + 1) di \(modello.pagine)")
    }

    @ViewBuilder private func caselle(pagina: Int, b: CGRect, k: CGFloat) -> some View {
        if let a = moduli.anteprima {
            let ordine = modello.campi.filter { a.valori[$0.id] != nil || a.mancanti.contains($0) }.map(\.id)
            let ultimo = Double(max(ordine.count, 1))
            ForEach(modello.campi.filter { $0.pagina == pagina }) { c in
                if let aspetto = aspetto(c, a) {
                    let r = c.riquadro
                    let i = ordine.firstIndex(of: c.id)
                    let ritardo = Tema.Apple.Pratiche.Moto.Campo.ritardo(i ?? Int(ultimo))
                    CasellaModulo(campo: c, aspetto: aspetto, k: k, ritardo: ritardo, giro: moduli.giro,
                                  inModifica: modificaBinding(c), salva: { stato.correggiCampoModulo(c.id, $0) })
                        .frame(width: r.width * k, height: r.height * k)
                        .position(x: (r.midX - b.minX) * k, y: (b.maxY - r.midY) * k)
                }
            }
        }
    }

    private func aspetto(_ c: ModelloModulo.Campo, _ a: AnteprimaCompilazione) -> AspettoCasella? {
        if c.risposta { return .risposta }
        if c.firma { return .firma }
        if let v = a.valori[c.id] { return .piena(v.testo, aMano: v.aMano) }
        if a.mancanti.contains(c) { return .manca }
        return nil
    }

    private func modificaBinding(_ c: ModelloModulo.Campo) -> Binding<Bool> {
        Binding(get: { moduli.inModifica == c.id }, set: { moduli.inModifica = $0 ? c.id : nil })
    }

    private func frecceDellePagine(_ pagina: Int) -> some View {
        HStack(spacing: M.spazioPagine) {
            Button { stato.paginaModulo(-1) } label: { Image(systemName: "chevron.left") }
                .buttonStyle(.appleSobrio)
                .disabled(pagina == 0)
            Text("pagina \(pagina + 1) di \(modello.pagine)")
                .carattereApple(M.pagine.tabellari)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            Button { stato.paginaModulo(1) } label: { Image(systemName: "chevron.right") }
                .buttonStyle(.appleSobrio)
                .disabled(pagina >= modello.pagine - 1)
        }
    }
}

/// Una casella sopra la pagina: verde chiara con il valore che si scrive, rossa con «?» se il dato manca, gialla che
/// respira per la firma, tratteggiata grigia per le risposte del cliente. Si corregge a mano con un clic.
private struct CasellaModulo: View {
    let campo: ModelloModulo.Campo
    let aspetto: AspettoCasella
    let k: CGFloat
    let ritardo: Double
    let giro: Int
    @Binding var inModifica: Bool
    let salva: (String) -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var acceso = false
    @State private var scritto: Double = 0
    @State private var respira = false
    @State private var bozza = ""

    private typealias M = Tema.Apple.Pratiche.Moduli
    private typealias T = Tema.Apple.Pratiche.Moto

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: M.raggioCampo * k, style: .continuous)
        ZStack(alignment: .leading) {
            switch aspetto {
            case .piena(let testo, _):
                forma.fill(M.campoPieno)
                forma.strokeBorder(M.bordoPieno, lineWidth: 1)
                TestoScritto(testo: testo, avanzamento: scritto)
                    .font(.system(size: M.valoreCampo * k, weight: .regular))
                    .foregroundColor(M.testoCampo)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, Tema.Apple.Pratiche.Moduli.paddingCasella * k)
            case .manca:
                forma.inset(by: -M.spessoreAnello * k / 2).stroke(M.anelloManca, lineWidth: M.spessoreAnello * k)
                forma.fill(M.campoManca)
                forma.strokeBorder(M.bordoManca, lineWidth: 1)
                Text("?")
                    .font(.system(size: M.valoreCampo * k, weight: .bold))
                    .foregroundColor(M.testoManca)
                    .padding(.horizontal, Tema.Apple.Pratiche.Moduli.paddingCasella * k)
            case .firma:
                ZStack {
                    forma.inset(by: -M.spessoreAnello * k / 2).stroke(M.firmaAnello, lineWidth: M.spessoreAnello * k)
                    forma.fill(M.firmaFondo)
                    forma.strokeBorder(M.firmaBordo, lineWidth: 1)
                }
                .scaleEffect(respira ? T.RespiroFirma.scala : 1)
            case .risposta:
                forma.strokeBorder(M.riservatoBordo, style: StrokeStyle(lineWidth: 1, dash: M.riservatoTratteggio))
                Text("la risposta la dà il cliente")
                    .font(.system(size: M.riservatoCarattere * k, weight: .medium))
                    .foregroundColor(M.riservatoTesto)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, Tema.Apple.Pratiche.Moduli.paddingCasella * k)
            }
        }
        .opacity(acceso ? 1 : 0)
        .contentShape(forma)
        .onTapGesture {
            guard modificabile else { return }
            if case .piena(let t, _) = aspetto { bozza = t } else { bozza = "" }
            inModifica = true
        }
        .popover(isPresented: $inModifica) { correzione }
        .onAppear { avvia() }
        .onChange(of: giro) { _ in avvia() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(etichettaAccessibile)
        .help(modificabile ? "Clic per correggere a mano: vale solo per questo modulo" : "")
    }

    private var modificabile: Bool {
        switch aspetto {
        case .piena, .manca: return true
        case .firma, .risposta: return false
        }
    }

    private var etichettaAccessibile: String {
        switch aspetto {
        case .piena(let t, _): return "\(campo.etichetta): \(t)"
        case .manca: return "\(campo.etichetta): manca"
        case .firma: return "\(campo.etichetta): da firmare"
        case .risposta: return "\(campo.etichetta): la risposta la dà il cliente"
        }
    }

    private var correzione: some View {
        VStack(alignment: .leading, spacing: M.spazioRighe) {
            Text(campo.etichetta)
                .carattereApple(M.rigaManca)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            TextField(campo.dato == .iban ? "IT00 X000 0000 0000 0000 0000 000" : "Scrivi il valore", text: $bozza)
                .textFieldStyle(.roundedBorder)
                .frame(width: Tema.Apple.Pratiche.Moduli.larghezzaPopover)
                .onSubmit(conferma)
            Text(campo.dato == .iban && !bozza.isEmpty && !IBAN.valido(bozza)
                 ? "Il codice di controllo dell'IBAN non torna: ricontrollalo."
                 : "Vale solo per questo modulo: il dossier non cambia.")
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(campo.dato == .iban && !bozza.isEmpty && !IBAN.valido(bozza) ? Tema.Apple.Colore.rosso : Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: Tema.Apple.Pratiche.Moduli.larghezzaPopover, alignment: .leading)
            HStack {
                Spacer()
                Button("Annulla") { inModifica = false }
                    .buttonStyle(.apple)
                Button("Scrivi", action: conferma)
                    .buttonStyle(.applePrimario)
                    .disabled(campo.dato == .iban && !bozza.isEmpty && !IBAN.valido(bozza))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Tema.Apple.Pratiche.Moduli.paddingPopover)
    }

    private func conferma() {
        if campo.dato == .iban, !bozza.isEmpty, !IBAN.valido(bozza) { return }
        salva(campo.dato == .iban ? IBAN.aGruppi(bozza) : bozza)
    }

    private func avvia() {
        var lettere: Double = 0
        if case .piena(let t, let aMano) = aspetto {
            let passo: Double = aMano ? T.Campo.letteraAMano : T.Campo.lettera
            lettere = Double(t.count) * passo
        }
        if fermo {
            acceso = true
            scritto = 1
            respira = false
            return
        }
        if calmo {
            acceso = false
            scritto = 1
            withAnimation(Tema.Moto.dissolvenzaCalma) { acceso = true }
            return
        }
        acceso = false
        scritto = 0
        respira = false
        withAnimation(T.Campo.colore.delay(ritardo)) { acceso = true }
        withAnimation(.linear(duration: max(lettere, 0.01)).delay(ritardo)) { scritto = 1 }
        if aspetto == .firma {
            withAnimation(T.RespiroFirma.animazione.delay(ritardo + T.Campo.durataColore)) { respira = true }
        }
    }
}

/// Il valore che si scrive lettera per lettera (Animatable: niente Timer).
private struct TestoScritto: View, Animatable {
    var testo: String
    var avanzamento: Double

    var animatableData: Double {
        get { avanzamento }
        set { avanzamento = newValue }
    }

    var body: some View {
        let n = Int((Double(testo.count) * min(max(avanzamento, 0), 1)).rounded(.down))
        Text(String(testo.prefix(n)))
    }
}

// MARK: - La colonna «Compila per»

private struct ColonnaCompila: View {
    let stato: StatoShell
    let moduli: StatoModuli
    let modello: ModelloModulo

    @State private var cerca = false
    @State private var testoCerca = ""
    @State private var daSalvare: PDFDaSalvare?

    private typealias P = Tema.Apple.Pratiche
    private typealias M = Tema.Apple.Pratiche.Moduli

    var body: some View {
        let cliente = stato.clienteModulo
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: M.spazioDestra) {
                HStack(spacing: M.spazioChip) {
                    Text("Compila per")
                        .carattereApple(Tema.Apple.Carattere.etichetta)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    Spacer(minLength: 0)
                    if modello.diProva == true { EtichettaDatiDiProvaPratiche() }
                }
                chip(cliente)
                if let cliente { proposta(cliente) }
                pulsante(cliente)
                if let a = moduli.anteprima, let cliente {
                    TileFinali(stato: stato, moduli: moduli, modello: modello, cliente: cliente, anteprima: a,
                               daSalvare: $daSalvare)
                        .id(moduli.giro)
                }
            }
            .padding(.top, M.margineAltoPiano)
        }
        .sheet(item: $daSalvare) { pdf in
            ModuloSalvaPDF(pdf: pdf, impostazioni: stato.dati.impostazioni.pdf, soloProtetto: true)
                .environment(stato)
        }
    }

    @ViewBuilder private func chip(_ scelto: Cliente?) -> some View {
        let recenti = stato.clientiRecentiModulo
        FlussoChip(spazio: M.spazioChip) {
            ForEach(recenti) { c in
                ChipClienteModulo(cliente: c, acceso: c.id == scelto?.id) { stato.scegliClienteModulo(c.id) }
            }
            if stato.dati.clienti.count > recenti.count {
                Button { cerca = true } label: {
                    Label("Altri", systemImage: "magnifyingglass")
                }
                .buttonStyle(.apple)
                .popover(isPresented: $cerca) { ricerca }
            }
        }
    }

    private var ricerca: some View {
        let t = testoCerca.trimmingCharacters(in: .whitespaces).lowercased()
        let trovati = stato.dati.clienti.filter { t.isEmpty || $0.nome.lowercased().contains(t) }
            .sorted { $0.nome < $1.nome }.prefix(12)
        return VStack(alignment: .leading, spacing: M.spazioRighe) {
            TextField("Cerca un cliente", text: $testoCerca)
                .textFieldStyle(.roundedBorder)
            ForEach(Array(trovati)) { c in
                Button(c.nome) {
                    stato.scegliClienteModulo(c.id)
                    cerca = false
                }
                .buttonStyle(.appleSobrio)
            }
        }
        .padding(Tema.Apple.Pratiche.Moduli.paddingPopover)
        .frame(width: Tema.Apple.Pratiche.Moduli.larghezzaPopover)
    }

    @ViewBuilder private func proposta(_ c: Cliente) -> some View {
        let proposte = stato.proposteModulo(c, modello)
        if !modello.tipo.risposteDelCliente {
            if proposte.isEmpty {
                Text("Nessuna proposta aperta del canale indipendente: premio, decorrenza e beneficiari resteranno da scrivere.")
                    .carattereApple(Tema.Apple.Carattere.secondario)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                let scelta = proposte.first { $0.id == moduli.posizioneId } ?? proposte[0]
                Menu {
                    ForEach(proposte) { p in
                        Button(p.nome) { stato.scegliPropostaModulo(p.id) }
                    }
                } label: {
                    Text("Per la proposta «\(scelta.nome)»")
                        .carattereApple(Tema.Apple.Carattere.secondario)
                        .lineLimit(2)
                }
                .menuStyle(.button)
                .buttonStyle(.appleSobrio)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder private func pulsante(_ c: Cliente?) -> some View {
        Group {
            if !modello.compilabile {
                Text("I moduli Alleanza non si compilano in Prisma finché la compagnia non lo approva.")
                    .carattereApple(M.notaAlleanza)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let c {
                Button("✦ Compila con i dati di \(StatoShell.nomeDiBattesimo(c))") { stato.compilaModulo() }
                    .buttonStyle(.applePrimarioGrande)
            } else {
                Button("Scegli un cliente") {}
                    .buttonStyle(.applePrimarioGrande)
                    .disabled(true)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Un chip del cliente: avatar 22 e nome di battesimo; acceso in blu pieno.
private struct ChipClienteModulo: View {
    let cliente: Cliente
    let acceso: Bool
    let azione: () -> Void

    private typealias M = Tema.Apple.Pratiche.Moduli

    var body: some View {
        let forma = Capsule(style: .continuous)
        Button(action: azione) {
            HStack(spacing: M.spazioChip) {
                AvatarCliente(iniziali: cliente.iniziali, tinta: cliente.tinta.colori, lato: M.avatarChip)
                Text(StatoShell.nomeDiBattesimo(cliente))
                    .carattereApple(M.chipCarattere)
                    .foregroundColor(acceso ? M.chipTestoAcceso : M.chipTesto)
                    .lineLimit(1)
            }
            .padding(M.chipPadding)
            .background(forma.fill(acceso ? M.chipAcceso : M.chipFondo))
            .overlay(forma.strokeBorder(acceso ? Color.clear : M.chipBordo, lineWidth: Tema.Apple.Misura.bordo))
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .accessibilityAddTraits(acceso ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }
}

/// I chip vanno a capo quando la riga è piena.
private struct FlussoChip: Layout {
    var spazio: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let larghezza = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, riga: CGFloat = 0, massimo: CGFloat = 0
        for s in subviews {
            let d = s.sizeThatFits(.unspecified)
            if x > 0 && x + d.width > larghezza { x = 0; y += riga + spazio; riga = 0 }
            x += d.width + spazio
            riga = max(riga, d.height)
            massimo = max(massimo, x - spazio)
        }
        return CGSize(width: proposal.width ?? massimo, height: y + riga)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, riga: CGFloat = 0
        for s in subviews {
            let d = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + d.width > bounds.maxX { x = bounds.minX; y += riga + spazio; riga = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(d))
            x += d.width + spazio
            riga = max(riga, d.height)
        }
    }
}

// MARK: - Le tile dopo la compilazione

private struct TileFinali: View {
    let stato: StatoShell
    let moduli: StatoModuli
    let modello: ModelloModulo
    let cliente: Cliente
    let anteprima: AnteprimaCompilazione
    @Binding var daSalvare: PDFDaSalvare?

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var visibili = false

    private typealias M = Tema.Apple.Pratiche.Moduli
    private typealias T = Tema.Apple.Pratiche.Moto

    var body: some View {
        let nome = StatoShell.nomeDiBattesimo(cliente)
        let fineCampi = T.Campo.ritardo(max(anteprima.totale - 1, 0)) + T.TileFinali.dopoUltimo
        VStack(alignment: .leading, spacing: M.spazioDestra) {
            contatore
                .modifier(EntrataTile(visibile: visibili, indice: 0, base: 0))
            if !anteprima.mancanti.isEmpty {
                tileVera(nome)
                    .modifier(EntrataTile(visibile: visibili, indice: 1, base: fineCampi))
            }
            if !anteprima.firme.isEmpty {
                tileFirme
                    .modifier(EntrataTile(visibile: visibili, indice: 2, base: fineCampi))
            }
            if !anteprima.risposte.isEmpty {
                tileRisposte(nome)
                    .modifier(EntrataTile(visibile: visibili, indice: 3, base: fineCampi))
            }
            Text(riepilogo)
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .modifier(EntrataTile(visibile: visibili, indice: 4, base: fineCampi))
            HStack(spacing: M.spazioRighe) {
                Button("Salva nel dossier") { stato.salvaModuloNelDossier() }
                    .buttonStyle(.applePrimario)
                    .disabled(stato.solaLettura)
                Button("Dai al cliente…") { daSalvare = stato.moduloPerCliente() }
                    .buttonStyle(.apple)
            }
            .frame(maxWidth: .infinity)
            .modifier(EntrataTile(visibile: visibili, indice: 5, base: fineCampi))
        }
        .onAppear { visibili = true }
    }

    private var riepilogo: String {
        let n = anteprima.compilati
        return n == 1 ? "1 campo preso dal dossier" : "\(n) campi presi dal dossier"
    }

    private var contatore: some View {
        VStack(alignment: .leading, spacing: Tema.Apple.Pratiche.Moduli.spazioMinimo) {
            Text("Campi compilati")
                .carattereApple(Tema.Apple.Carattere.etichetta)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            HStack(alignment: .firstTextBaseline, spacing: Tema.Apple.Pratiche.Moduli.spazioStretto) {
                ContatoreCampi(valore: anteprima.compilati, totale: anteprima.totale, giro: moduli.giro)
                Text("di \(anteprima.totale)")
                    .carattereApple(M.diTotale)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
        }
        .padding(M.paddingTile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(M.tile, raggio: M.raggioTile)
    }

    private func tileVera(_ nome: String) -> some View {
        let dati = anteprima.datiMancanti
        let elenco = dati.map(\.nomeInFrase)
        let frase = dati.count == 1
            ? "Manca \(articolo(dati[0]))\(elenco[0]). Lo chiedo a \(nome) con un messaggio?"
            : "Mancano \(dati.count) dati: \(elenco.joined(separator: ", ")). Li chiedo a \(nome) con un messaggio?"
        let forma = RoundedRectangle(cornerRadius: M.raggioTile, style: .continuous)
        let vera = stato.veraPerModuli
        return VStack(alignment: .leading, spacing: M.spazioTile) {
            if vera {
                HStack(spacing: Tema.Apple.Pratiche.Moduli.spazioMedio) {
                    SferaVera(misura: M.sferaVera, viva: true)
                    Text("Vera")
                        .carattereApple(M.nomeVera)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                }
            }
            Text(frase)
                .carattereApple(M.testoVera)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
            if moduli.richiestaPronta {
                Label("Messaggio pronto in Messaggi", systemImage: "checkmark")
                    .carattereApple(Tema.Apple.Carattere.barra)
                    .foregroundColor(Tema.Apple.Colore.verde)
            } else {
                HStack(spacing: M.spazioRighe) {
                    Button(dati.count == 1 ? "Sì, chiediglielo" : "Sì, chiediglieli") { stato.chiediDatiModulo() }
                        .buttonStyle(.applePrimario)
                    Button("Lo scrivo io") { stato.scriviDatoModulo() }
                        .buttonStyle(.apple)
                }
            }
            if dati.count > 1 {
                VStack(alignment: .leading, spacing: Tema.Apple.Pratiche.Moduli.spazioMinimo) {
                    ForEach(dati) { d in
                        HStack {
                            Text(d.nome)
                                .carattereApple(M.rigaManca)
                                .foregroundColor(Tema.Apple.Colore.inchiostro)
                            Spacer(minLength: Tema.Apple.Pratiche.Moduli.spazioStretto)
                            Button("Lo scrivo io") { stato.scriviDatoModulo(d) }
                                .buttonStyle(.appleSobrio)
                        }
                    }
                }
            }
        }
        .padding(M.paddingTile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(M.tile, raggio: M.raggioTile)
        .overlay(forma.strokeBorder(M.bordoVera, lineWidth: 1))
    }

    /// «l'», «il», «la»… davanti al nome del dato («Manca l'IBAN per l'addebito»).
    private func articolo(_ d: DatoModulo) -> String {
        switch d {
        case .iban, .indirizzo, .email: return "l'"
        case .beneficiari: return "i "
        case .dataNascita, .decorrenza, .scadenza, .professione, .provincia, .frequenza, .documentoRilascio, .documentoScadenza:
            return "la "
        case .cognome, .nome, .codiceFiscale, .luogoNascita, .cap, .comune, .telefono, .statoCivile, .documentoTipo,
             .documentoNumero, .premio, .capitale, .prodotto, .numeroContratto, .luogoData, .consulente:
            return "il "
        }
    }

    private var tileFirme: some View {
        let n = anteprima.firme.count
        let forma = RoundedRectangle(cornerRadius: M.raggioTile, style: .continuous)
        let quando: String = {
            guard let a = stato.appuntamentoFirma(cliente) else { return "Le caselle gialle, a penna: fissa l'incontro per la firma." }
            return "Le caselle gialle, a penna: all'incontro di \(Formati.giornoRelativo(a.inizio))."
        }()
        return VStack(alignment: .leading, spacing: Tema.Apple.Pratiche.Moduli.spazioStretto) {
            Text(n == 1 ? "1 firma da raccogliere" : "\(n) firme da raccogliere")
                .carattereApple(M.titoloTile)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            Text(quando)
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(M.paddingTile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(forma.fill(M.tileFirmeFondo))
        .overlay(forma.strokeBorder(M.tileFirmeBordo, lineWidth: 1))
    }

    private func tileRisposte(_ nome: String) -> some View {
        let n = anteprima.risposte.count
        let forma = RoundedRectangle(cornerRadius: M.raggioTile, style: .continuous)
        let ultima: String? = {
            let c = cliente.conformita
            let date = [c?.verificaIndipendente?.eseguitaIl, c?.verificaAlleanza?.eseguitaIl].compactMap { $0 }
            return date.max().map { "L'ultima adeguata verifica è del \(Formati.dataBreve.string(from: $0)): le risposte di allora sono sul modulo firmato, da confermare con \(nome)." }
        }()
        return VStack(alignment: .leading, spacing: Tema.Apple.Pratiche.Moduli.spazioStretto) {
            Text(n == 1 ? "1 risposta la dà \(nome)" : "\(n) risposte le dà \(nome)")
                .carattereApple(M.titoloTile)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            Text("Prisma non compila dichiarazioni e questionario: le chiedi a \(nome) all'incontro.")
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
            if let ultima {
                Text(ultima)
                    .carattereApple(Tema.Apple.Carattere.secondario)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(M.paddingTile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(M.tile, raggio: M.raggioTile)
        .overlay(forma.strokeBorder(M.tileRisposteBordo, lineWidth: 1))
    }
}

/// Il contatore «0 di 15» che sale di uno a ogni campo, allo stesso passo dei campi (Animatable: niente Timer).
private struct ContatoreCampi: View {
    let valore: Int
    let totale: Int
    let giro: Int

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var avanzamento: Double = 0

    private typealias T = Tema.Apple.Pratiche.Moto.Campo

    var body: some View {
        NumeroCampi(valore: Double(valore) * (fermo ? 1 : avanzamento))
            .onAppear(perform: avvia)
            .onChange(of: valore) { _ in avanzamento = 1 }
    }

    private func avvia() {
        guard !fermo, !calmo else {
            avanzamento = 1
            return
        }
        avanzamento = 0
        withAnimation(.linear(duration: T.passo * Double(max(valore, 1))).delay(T.base + T.durataColore / 2)) { avanzamento = 1 }
    }
}

private struct NumeroCampi: View, Animatable {
    var valore: Double

    var animatableData: Double {
        get { valore }
        set { valore = newValue }
    }

    var body: some View {
        Text("\(Int(valore.rounded(.down)))")
            .carattereApple(Tema.Apple.Pratiche.Moduli.numero)
            .foregroundColor(Tema.Apple.Colore.inchiostro)
    }
}

/// Le tile finali entrano dopo l'ultimo campo: da 10 più in basso, una ogni 0,12 s (subito con calma e nelle istantanee).
private struct EntrataTile: ViewModifier {
    let visibile: Bool
    let indice: Int
    let base: Double

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var fermo
    private typealias T = Tema.Apple.Pratiche.Moto.TileFinali

    func body(content: Content) -> some View {
        let mostra = visibile || fermo
        content
            .opacity(mostra ? 1 : 0)
            .offset(y: mostra || calmo ? 0 : T.spostamento)
            .animation(fermo ? nil : (calmo ? Tema.Moto.dissolvenzaCalma
                                             : T.animazione.delay(base + Double(indice) * T.passo)), value: visibile)
    }
}
