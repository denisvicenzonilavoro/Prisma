import SwiftUI

// Pratiche › Moduli · la revisione della mappa dei campi (Design/template-luce-specifica.md §7.2.4, «Luce» giro 10,
// decisione 61): dopo il caricamento di un PDF, una volta per modello. A sinistra la pagina con le caselle numerate, a
// destra l'elenco: per ogni casella l'etichetta letta, da dove viene l'associazione (campo del PDF, regole, Vera, a mano)
// e il dato del dossier, da confermare o cambiare; «Lascia vuota», «Risposta del cliente» (mai compilata, decisione 62) e
// «Firma» (solo evidenziata, decisione 63). Sui PDF piatti le caselle si aggiungono con un clic sulla pagina. Vera
// propone solo per le etichette che le regole non riconoscono, leggendo il testo del modulo vuoto (decisione 54).

struct RevisioneModulo: View {
    let stato: StatoShell
    let moduli: StatoModuli
    let revisione: ModelloModulo

    private typealias M = Tema.Apple.Pratiche.Moduli
    private typealias P = Tema.Apple.Pratiche

    var body: some View {
        HStack(alignment: .top, spacing: M.spazioColonne) {
            FoglioRevisione(stato: stato, moduli: moduli, modello: revisione)
                .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            ElencoRevisione(stato: stato, moduli: moduli, modello: revisione)
                .frame(width: M.colonnaRevisione)
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
        }
    }
}

/// La pagina con le caselle numerate; un clic sceglie la casella, o ne aggiunge una con «Aggiungi una casella».
private struct FoglioRevisione: View {
    let stato: StatoShell
    let moduli: StatoModuli
    let modello: ModelloModulo

    private typealias M = Tema.Apple.Pratiche.Moduli

    var body: some View {
        let pagina = min(moduli.pagina, max(0, modello.pagine - 1))
        let b = moduli.riquadroPagina(modello, pagina: pagina)
        let forma = RoundedRectangle(cornerRadius: M.raggioPiano, style: .continuous)
        GeometryReader { geo in
            let frecce: CGFloat = modello.pagine > 1 ? Tema.Apple.Pratiche.Moduli.altezzaFrecce : 0
            let k = min((geo.size.width - M.marginePiano * 2) / b.width,
                        (geo.size.height - M.margineAltoPiano - M.marginePiano - frecce) / b.height)
            VStack(spacing: M.spazioPagine) {
                ZStack(alignment: .topLeading) {
                    if let img = moduli.immagine(modello, pagina: pagina, larghezza: M.larghezzaDisegno) {
                        Image(decorative: img, scale: 1)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: b.width * k, height: b.height * k)
                    }
                    let campi = modello.campi.enumerated().filter { $0.element.pagina == pagina }
                    ForEach(campi, id: \.element.id) { i, c in
                        casella(c, numero: i + 1, k: k)
                            .frame(width: c.riquadro.width * k, height: c.riquadro.height * k)
                            .position(x: (c.riquadro.midX - b.minX) * k, y: (b.maxY - c.riquadro.midY) * k)
                    }
                }
                .frame(width: b.width * k, height: b.height * k, alignment: .topLeading)
                .background(M.fondoPagina)
                .contentShape(Rectangle())
                .onTapGesture(coordinateSpace: .local) { p in
                    guard moduli.aggiungiCasella else { return }
                    stato.aggiungiCasellaRevisione(pagina: pagina, punto: CGPoint(x: b.minX + p.x / k, y: b.maxY - p.y / k))
                }
                .shadow(color: M.ombraPagina, radius: M.ombraRaggio, x: 0, y: M.ombraY)
                if modello.pagine > 1 {
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
            .padding(.top, M.margineAltoPiano)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .background(forma.fill(M.fondoPiano))
        .clipShape(forma)
    }

    private func casella(_ c: ModelloModulo.Campo, numero: Int, k: CGFloat) -> some View {
        let scelta = moduli.campoRevisione == c.id
        let forma = RoundedRectangle(cornerRadius: M.raggioCampo * k, style: .continuous)
        let (fondo, bordo): (Color, Color) = {
            if scelta { return (M.campoScelto, M.bordoScelto) }
            if c.firma { return (M.firmaFondo, M.firmaBordo) }
            if c.risposta { return (Color.clear, M.riservatoBordo) }
            if c.dato == nil || c.daConfermare { return (M.campoManca, M.bordoManca.opacity(0.6)) }
            return (M.campoPieno, M.bordoPieno)
        }()
        return ZStack(alignment: .topLeading) {
            forma.fill(fondo)
            forma.strokeBorder(bordo, style: StrokeStyle(lineWidth: scelta ? M.bordoCasellaScelta : M.bordoCasella, dash: c.risposta ? M.riservatoTratteggio : []))
            Text("\(numero)")
                .font(.system(size: max(7, M.numeroCampo * k * 1.3), weight: .bold).monospacedDigit())
                .foregroundColor(scelta ? M.bordoScelto : M.testoCampo)
                .padding(2)
        }
        .contentShape(forma)
        .onTapGesture { moduli.campoRevisione = c.id }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Casella \(numero): \(c.etichetta)")
    }
}

/// L'elenco delle caselle con il loro dato, i comandi e la conferma.
private struct ElencoRevisione: View {
    let stato: StatoShell
    let moduli: StatoModuli
    let modello: ModelloModulo

    @State private var titolo = ""

    private typealias M = Tema.Apple.Pratiche.Moduli
    private typealias P = Tema.Apple.Pratiche

    var body: some View {
        let nonRiconosciute = RiconoscitoreModulo.nonRiconosciute(modello.campi)
        let daConfermare = modello.campi.filter { $0.daConfermare }.count
        VStack(alignment: .leading, spacing: M.spazioDestra) {
            Text("Controlla la mappa")
                .carattereApple(Tema.Apple.Carattere.etichetta)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            TextField("Nome del modulo", text: $titolo)
                .textFieldStyle(.roundedBorder)
                .onSubmit { stato.rinominaRevisione(titolo) }
                .onAppear { titolo = modello.titolo }
            HStack(spacing: M.spazioRighe) {
                Picker("Tipo", selection: Binding(get: { modello.tipo }, set: { stato.cambiaTipoRevisione($0) })) {
                    ForEach(TipoModulo.allCases) { Text($0.nome).tag($0) }
                }
                .labelsHidden()
                EtichettaCanale(canale: .indipendente, compatta: true)
            }
            Text(stato_frase(daConfermare: daConfermare))
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(modello.campi.isEmpty ? Tema.Apple.Colore.inchiostro : Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: Tema.Apple.Pratiche.Moduli.spazioStretto) {
                    ForEach(Array(modello.campi.enumerated()), id: \.element.id) { i, c in
                        riga(c, numero: i + 1)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            HStack(spacing: M.spazioRighe) {
                Button(moduli.aggiungiCasella ? "Tocca la pagina…" : "Aggiungi una casella") { moduli.aggiungiCasella.toggle() }
                    .buttonStyle(.apple)
                if !nonRiconosciute.isEmpty {
                    Button(moduli.veraInCorso ? "Vera legge…" : "✦ Chiedi a Vera") { stato.chiediAVeraModulo() }
                        .buttonStyle(.apple)
                        .disabled(moduli.veraInCorso)
                        .help("A Vera va solo il testo delle etichette del modulo vuoto, nessun dato dei clienti. Le sue proposte restano da confermare.")
                }
            }
            HStack(spacing: M.spazioRighe) {
                Button("Annulla") { stato.annullaRevisioneModulo() }
                    .buttonStyle(.apple)
                Spacer(minLength: 0)
                Button("Conferma la mappa") {
                    stato.rinominaRevisione(titolo)
                    stato.confermaRevisioneModulo()
                }
                .buttonStyle(.applePrimario)
                .disabled(stato.solaLettura)
            }
        }
        .padding(.top, M.margineAltoPiano)
    }

    private func stato_frase(daConfermare: Int) -> String {
        if modello.campi.isEmpty { return "Nessun campo riconosciuto: segna tu le caselle con «Aggiungi una casella»." }
        let n = modello.campi.count
        let base = "\(n) caselle riconosciute"
        let conferme = daConfermare == 0 ? "" : (daConfermare == 1 ? ", 1 da confermare" : ", \(daConfermare) da confermare")
        return base + conferme + ". Le risposte del cliente e le firme Prisma non le compila mai."
    }

    private func riga(_ c: ModelloModulo.Campo, numero: Int) -> some View {
        let scelta = moduli.campoRevisione == c.id
        let forma = RoundedRectangle(cornerRadius: M.raggioRiga, style: .continuous)
        return HStack(alignment: .top, spacing: Tema.Apple.Pratiche.Moduli.spazioMedio) {
            Text("\(numero)")
                .carattereApple(Tema.Apple.Carattere.badge)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .frame(width: M.colonnaNumero, alignment: .trailing)
            VStack(alignment: .leading, spacing: Tema.Apple.Pratiche.Moduli.spazioMinimo) {
                Text(c.etichetta)
                    .carattereApple(M.etichettaRiga)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(2)
                HStack(spacing: Tema.Apple.Pratiche.Moduli.spazioStretto) {
                    Text(c.origine.nome)
                        .carattereApple(M.origineRiga)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    if c.daConfermare {
                        Text("· da confermare")
                            .carattereApple(M.origineRiga)
                            .foregroundColor(M.coloreDaConfermare)
                    }
                }
                menu(c)
            }
            Spacer(minLength: 0)
            if c.origine == .mano {
                Button { stato.togliCasellaRevisione(c.id) } label: { Image(systemName: "trash") }
                    .buttonStyle(.appleSobrio)
                    .help("Togli la casella")
            }
        }
        .padding(M.rigaRevisione)
        .background(forma.fill(scelta ? M.fondoRigaScelta : M.fondoRiga))
        .contentShape(forma)
        .onTapGesture {
            moduli.campoRevisione = c.id
            if c.pagina != moduli.pagina { moduli.pagina = c.pagina }
        }
    }

    private func menu(_ c: ModelloModulo.Campo) -> some View {
        let attuale = c.risposta ? "Risposta del cliente" : (c.firma ? "Firma" : (c.dato.map { "\($0.nome) · \($0.fonte)" } ?? "Lascia vuota"))
        let dati = DatoModulo.allCases.filter { !modello.tipo.risposteDelCliente || $0.anagrafico }
        return Menu {
            Button("Lascia vuota") { stato.associaCampoRevisione(c.id, dato: nil) }
            Button("Risposta del cliente (Prisma non la compila)") { stato.associaCampoRevisione(c.id, dato: nil, risposta: true) }
            Button("Firma (solo evidenziata)") { stato.associaCampoRevisione(c.id, dato: nil, firma: true) }
            Divider()
            ForEach(dati) { d in
                Button(d.nome) { stato.associaCampoRevisione(c.id, dato: d) }
            }
        } label: {
            Text(attuale)
                .carattereApple(Tema.Apple.Carattere.secondario)
                .lineLimit(2)
        }
        .menuStyle(.button)
        .buttonStyle(.appleSobrio)
        .fixedSize(horizontal: false, vertical: true)
    }
}
