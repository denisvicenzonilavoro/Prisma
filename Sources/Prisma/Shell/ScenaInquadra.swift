#if os(macOS)
import AppKit
import SwiftUI
import UniformTypeIdentifiers

// Inquadra e capisci sul Mac (Design/template-novita-specifica.md §9.1, §9.2, §9.3, §9.4):
//
//   ┌ velo scuro sfocato sopra barra, finestre e dock ─────────────────────────────────────────────┐
//   │      ┌──────────┐                                                                            │
//   │      │ ▬▬ tacca │        ┌ ● PRISMA SUL MAC ─────────────────────── ✕ ┐                     │
//   │      │ ┌──────┐ │        │ Polizza riconosciuta                         │                     │
//   │      │ │foglio│ │        │ ✓ Contraente          Giulia Rossi           │                     │
//   │      │ │ ──── │ │        │ ✓ Premio              90 € al mese           │                     │
//   │      │ └──────┘ │        │ …                                             │                     │
//   │      │ ✓ Fatto  │        │ [Aggiungi a Posizioni di Giulia] [Confronta] │                     │
//   │      └──────────┘        └──────────────────────────────────────────────┘                     │
//   └──────────────────────────────────────────────────────────────────────────────────────────────┘
//
// - Il testo arriva dall'iPhone sul ponte cifrato (attesa) oppure da una foto o un PDF trascinati sulla scena (o scelti
//   con «Scegli un file…»), letti sul Mac con LetturaDocumenti. Niente fotocamera sul Mac.
// - Il telefono disegnato mostra il foglio letto: la foto con i riquadri, o il foglio ricostruito dalle righe.
// - Movimento: velo in 0,3 s; iPhone da y +60 e −4° con la molla leggera in 0,7 s; linea della scansione giù e su in
//   2 × 1,1 s (si ferma in alto); righe a cascata (StatoInquadra); tabella da y +10 in 0,45 s; chiusura in 0,22 s.
//   «Riduci movimento»: tutto fermo con la dissolvenza di 0,15 s, niente linea. Istantanee: stato finale, linea in alto.
// - Esc chiude la scena (prima di tutto il resto); Invio è il pulsante principale. Un clic sul velo non fa nulla.

/// Lo strato della scena nella shell (sopra barra, finestre e dock): vuoto quando la scena è chiusa.
struct StratoInquadra: View {
    let inquadra: StatoInquadra
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    var body: some View {
        ZStack {
            if inquadra.aperto {
                ScenaInquadra(inquadra: inquadra)
                    .transition(transizione)
            }
        }
    }

    private var transizione: AnyTransition {
        guard !istantanea else { return .identity }
        let m = Tema.Apple.Moto.Inquadra.self
        return .asymmetric(insertion: AnyTransition.opacity.animation(calmo ? Tema.Moto.dissolvenzaCalma : m.velo),
                           removal: AnyTransition.opacity.animation(calmo ? Tema.Moto.dissolvenzaCalma : m.chiusura))
    }
}

/// Il velo, l'iPhone disegnato e la scheda «Prisma sul Mac», centrati; la scena si rimpicciolisce nelle finestre basse.
struct ScenaInquadra: View {
    @Environment(StatoShell.self) var stato
    let inquadra: StatoInquadra

    private typealias D = Tema.Apple.Inquadra.Disposizione
    private typealias A = Tema.Apple.Inquadra.Apparecchio

    var body: some View {
        let _ = ContaCorpi.segna()
        GeometryReader { geo in
            ZStack {
                // Il velo comune della scena del telefono (DesignSystem/Apple/ScenaTelefono.swift)
                VeloScena()
                HStack(alignment: .top, spacing: D.spazio) {
                    TelefonoInquadra(inquadra: inquadra)
                    SchedaInquadraMac(inquadra: inquadra)
                        .padding(.top, D.scartoScheda)
                }
                .scaleEffect(scala(geo.size))
                // Esc chiude la scena, prima di Novità, dettaglio, notifiche e finestra
                Button("Chiudi Inquadra e capisci") { stato.chiudiInquadra() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(StileSemplice())
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        // Una foto o un PDF lasciati ovunque sulla scena vanno letti qui (non importati in Documenti)
        .onDrop(of: [.fileURL], isTargeted: Binding(get: { inquadra.fileSopra },
                                                     set: { inquadra.fileSopra = $0 && accetta })) { fornitori in
            guard accetta, let f = fornitori.first else { return false }
            _ = f.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async { stato.leggiFileInquadra(url) }
            }
            return true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Inquadra e capisci"))
    }

    /// Mentre il Mac legge un file non se ne accetta un altro.
    private var accetta: Bool { inquadra.fase != .lettura && !stato.solaLettura }

    private func scala(_ misura: CGSize) -> CGFloat {
        let larghezza = A.larghezza + D.spazio + Tema.Apple.Inquadra.Scheda.larghezza
        let altezza = A.altezza + D.scartoScheda
        let s = min(1, (misura.width - 2 * D.margine) / larghezza, (misura.height - 2 * D.margine) / altezza)
        return max(D.scalaMinima, s)
    }
}

// MARK: - L'iPhone disegnato

/// L'iPhone con la tacca: nello schermo l'inquadratura, il foglio letto, la linea della scansione e la scritta.
private struct TelefonoInquadra: View {
    let inquadra: StatoInquadra
    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(\.prismaScatto) private var scatto
    @State private var entrato = false

    private typealias A = Tema.Apple.Inquadra.Apparecchio
    private typealias F = Tema.Apple.Inquadra.Foglio

    var body: some View {
        let m = Tema.Apple.Moto.Inquadra.self
        let dentro = entrato || fermo
        // Il telefono disegnato comune (DesignSystem/Apple/ScenaTelefono.swift), con lo schermo di Inquadra
        return TelefonoDisegnato { schermo }
        .rotationEffect(.degrees(dentro ? 0 : m.rotazioneTelefono))
        .offset(y: dentro ? 0 : m.spostamentoTelefono)
        .opacity(dentro ? 1 : 0)
        .onAppear {
            guard !entrato, !scatto else { return }
            if fermo {
                entrato = true
            } else {
                withAnimation(m.telefono) { entrato = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("iPhone: \(scritta)"))
    }

    private var schermo: some View {
        let forma = RoundedRectangle(cornerRadius: A.raggioSchermo, style: .continuous)
        return ZStack(alignment: .top) {
            forma.fill(A.schermo)
            forma.fill(RadialGradient(colors: A.fotocamera, center: A.centroFotocamera, startRadius: 0, endRadius: A.raggioFotocamera))
            foglio
            if inquadra.dati != nil {
                LineaScansione(chiave: inquadra.dati?.testo ?? "")
            }
            VStack {
                Spacer(minLength: 0)
                Text(scritta)
                    .carattereApple(A.scritta)
                    .foregroundColor(A.coloreScritta)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, A.scrittaDalFondo)
            }
        }
        .clipShape(forma)
    }

    @ViewBuilder private var foglio: some View {
        if let d = inquadra.dati, !d.campi.isEmpty {
            if let img = inquadra.immagine {
                FoglioInquadra(righe: inquadra.righe, campi: d.campi, accesi: inquadra.campiAccesi, immagine: img)
                    .padding(.horizontal, A.margineImmagine)
                    .padding(.top, A.immagineDallAlto)
                    .padding(.bottom, A.immagineDalFondo)
                    .frame(maxHeight: .infinity, alignment: .top)
            } else {
                FoglioInquadra(righe: inquadra.righe, campi: d.campi, accesi: inquadra.campiAccesi)
                    .rotationEffect(.degrees(F.rotazione))
                    .padding(.horizontal, F.lati)
                    .padding(.top, F.dallAlto)
            }
        }
    }

    /// La scritta in basso: «Inquadra il documento», «Riconosco i dati…», «✓ Fatto».
    private var scritta: String {
        switch inquadra.fase {
        case .attesa: return "Inquadra il documento"
        case .trascina: return "Trascina la foto sul Mac"
        case .lettura: return "Riconosco i dati…"
        case .illeggibile: return "Riprova con più luce"
        case .letto:
            if inquadra.finito { return "✓ Fatto" }
            return inquadra.mostrate > 0 ? "Riconosco i dati…" : "Inquadra il documento"
        }
    }
}

/// La linea verde che scorre sul foglio: giù fino a 420 in 1,1 s e su in altri 1,1 s, poi resta in alto. Ferma in
/// alto nelle istantanee; con «Riduci movimento» non c'è. `chiave`: un foglio nuovo la fa ripartire.
private struct LineaScansione: View {
    let chiave: String
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var fermo
    @State private var giu = false
    @State private var giro = 0

    private typealias L = Tema.Apple.Inquadra.Linea

    var body: some View {
        if !calmo {
            LinearGradient(colors: [L.colore.opacity(0), L.colore, L.colore.opacity(0)], startPoint: .leading, endPoint: .trailing)
                .frame(height: L.altezza)
                .shadow(color: L.colore, radius: L.alone)
                .padding(.horizontal, L.lati)
                .offset(y: giu ? L.finoA : L.dallAlto)
                .frame(maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)
                .onAppear(perform: scorri)
                .onChange(of: chiave) { _ in scorri() }
        }
    }

    private func scorri() {
        guard !fermo else { return }
        giro += 1
        let g = giro
        let m = Tema.Apple.Moto.Inquadra.self
        withAnimation(m.linea) { giu = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + m.durataLinea) {
            guard giro == g else { return }
            withAnimation(m.linea) { giu = false }
        }
    }
}

// MARK: - La scheda «Prisma sul Mac»

private struct SchedaInquadraMac: View {
    @Environment(StatoShell.self) var stato
    let inquadra: StatoInquadra

    private typealias S = Tema.Apple.Inquadra.Scheda

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: 0) {
            testa
            Text(titolo)
                .carattereApple(S.titolo)
                .foregroundColor(S.coloreTitolo)
                .padding(.top, S.titoloSopra)
                .accessibilityAddTraits(.isHeader)
            if let frase {
                Text(frase)
                    .carattereApple(S.frase)
                    .foregroundColor(S.coloreFrase)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, S.fraseSopra)
            }
            contenuto
        }
        .padding(S.padding)
        .frame(width: S.larghezza, alignment: .leading)
        .superficieApple(S.superficie)
    }

    private var testa: some View {
        HStack(spacing: S.spazioTesta) {
            SferaVera(misura: S.sfera, viva: true, pensa: inquadra.fase == .lettura)
            Text("Prisma sul Mac")
                .carattereApple(S.etichetta)
                .foregroundColor(S.coloreEtichetta)
            Spacer(minLength: 0)
            Button { stato.chiudiInquadra() } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.apple)
            .help("Chiudi (Esc)")
            .accessibilityLabel(Text("Chiudi"))
        }
    }

    // MARK: Testi

    private var titolo: String {
        switch inquadra.fase {
        case .attesa: return "Aspetto il documento…"
        case .trascina: return "Trascina la polizza"
        case .lettura: return "Sto leggendo…"
        case .illeggibile: return "Non riesco a leggere il documento"
        case .letto:
            guard inquadra.finito, let d = inquadra.dati else { return "Sto leggendo…" }
            return inquadra.pochiDati ? "Ho letto solo una parte" : MotoreInquadra.titoloRiconosciuto(d.tipoDocumento)
        }
    }

    private var frase: String? {
        switch inquadra.fase {
        case .attesa:
            return "Sull’iPhone apri Prisma › Posizioni › Inquadra: il testo letto arriva qui, cifrato in rete locale. Oppure trascina qui una foto o un PDF."
        case .trascina:
            return "L’iPhone non è collegato: attiva «iPhone e iPad» in Impostazioni › Vera, oppure trascina qui una foto o un PDF. Prisma lo legge sul Mac e non lo salva."
        case .lettura:
            return "Leggo «\(inquadra.origine)» sul Mac, senza mandarlo fuori."
        case .illeggibile:
            return inquadra.origine.isEmpty ? "Riprova con più luce, con il foglio intero e dritto."
                : "In «\(inquadra.origine)» non trovo i dati di una polizza: riprova con più luce, con il foglio intero e dritto."
        case .letto:
            guard inquadra.finito else { return nil }
            if inquadra.pochiDati { return "Le righe in grigio non sono sul foglio: completale nella posizione." }
            return inquadra.origine.isEmpty ? nil : "Letto da \(inquadra.origine). Controlla i dati prima di aggiungerli."
        }
    }

    // MARK: Contenuto

    @ViewBuilder private var contenuto: some View {
        switch inquadra.fase {
        case .attesa, .trascina:
            ZonaInquadra(inquadra: inquadra)
                .padding(.top, Tema.Apple.Inquadra.Zona.sopra)
        case .lettura:
            EmptyView()
        case .illeggibile:
            HStack(spacing: S.spazioPulsanti) {
                Button("Riprova") { stato.riprovaInquadra() }
                    .buttonStyle(.applePrimarioGrande)
                    .keyboardShortcut(.defaultAction)
                Button("Chiudi") { stato.chiudiInquadra() }
                    .buttonStyle(.appleGrande)
            }
            .padding(.top, S.pulsantiSopra)
        case .letto:
            letto
        }
    }

    @ViewBuilder private var letto: some View {
        let canale = stato.canaleEAreaInquadra.canale
        let righe = inquadra.righeScheda(canale: canale)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(righe.prefix(inquadra.mostrate).enumerated()), id: \.element.id) { _, r in
                RigaSchedaInquadra(riga: r)
                    .entrataStile(.rigaInquadra)
            }
        }
        .padding(.top, S.righeSopra)
        if inquadra.finito {
            cliente(canale: canale)
            if let c = inquadra.confronto {
                TabellaConfrontoInquadra(confronto: c, tipo: inquadra.dati?.tipo)
                    .entrataStile(.tabellaInquadra)
            }
            if inquadra.conferma {
                conferma(canale: canale)
            } else {
                pulsanti
            }
        }
    }

    /// Il cliente a cui va la polizza (scelto dal contraente, si può cambiare) e il canale proposto.
    private func cliente(canale: Canale) -> some View {
        let c = stato.clienteInquadra
        return HStack(spacing: S.spazioCliente) {
            Text("Cliente")
                .carattereApple(S.carattereCliente)
                .foregroundColor(S.coloreCliente)
            Menu {
                ForEach(stato.clienti) { x in
                    Button(x.nome) { inquadra.clienteScelto = x.id }
                }
            } label: {
                Text(c?.nome ?? "Scegli il cliente")
                    .carattereApple(Tema.Apple.Carattere.pulsante)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(stato.solaLettura)
            Spacer(minLength: 0)
            EtichettaCanaleApple(canale: canale, compatta: true)
        }
        .padding(.top, S.clienteSopra)
    }

    private var pulsanti: some View {
        let c = stato.clienteInquadra
        let giaPresente = stato.posizioneGiaInquadrata != nil
        let nome = c.map { StatoShell.nomeBreveInquadra($0) } ?? "…"
        return HStack(spacing: S.spazioPulsanti) {
            if giaPresente {
                Button("Aggiorna la posizione") { stato.confrontaInquadrataConPosizione() }
                    .buttonStyle(.applePrimarioGrande)
                    .keyboardShortcut(.defaultAction)
                    .help("La polizza è già nelle posizioni del cliente: confronta i dati letti con quelli in Prisma")
                    .disabled(stato.solaLettura)
            } else {
                Button("Aggiungi a Posizioni di \(nome)") { inquadra.conferma = true }
                    .buttonStyle(.applePrimarioGrande)
                    .keyboardShortcut(.defaultAction)
                    .disabled(c == nil || stato.solaLettura)
                    .help(stato.solaLettura ? "Archivio in sola lettura: aggiorna Prisma per creare posizioni." : "Aggiungi la polizza alle posizioni del cliente, dopo la conferma")
            }
            if inquadra.confronto == nil && !giaPresente {
                Button("Confronta") { withAnimation(nil) { stato.confrontaInquadrata() } }
                    .buttonStyle(.appleGrande)
                    .help("La polizza letta a confronto con una temporanea caso morte")
            } else {
                Button("Chiudi") { stato.chiudiInquadra() }
                    .buttonStyle(.appleGrande)
            }
        }
        .padding(.top, S.pulsantiSopra)
    }

    /// Niente entra nel dossier senza conferma: la frase dice cosa succede, poi «Conferma e aggiungi».
    private func conferma(canale: Canale) -> some View {
        let c = stato.clienteInquadra
        let area = stato.canaleEAreaInquadra.area
        let nome = c.map { StatoShell.nomeBreveInquadra($0) } ?? "cliente"
        let frase = "Aggiungo a Posizioni di \(nome) una polizza in essere, canale \(canale.nomeBreve.lowercased()), area \(area.nome.lowercased()), con i dati qui sopra: entrano nel dossier come confermati. Il documento resta in Documenti, senza la foto."
        return VStack(alignment: .leading, spacing: S.spazioPulsanti) {
            Text(frase)
                .carattereApple(S.fraseConferma)
                .foregroundColor(S.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: S.spazioPulsanti) {
                Button("Conferma e aggiungi") { stato.aggiungiInquadrata() }
                    .buttonStyle(.applePrimarioGrande)
                    .keyboardShortcut(.defaultAction)
                Button("Annulla") { inquadra.conferma = false }
                    .buttonStyle(.appleGrande)
            }
        }
        .padding(S.paddingConferma)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(S.superficieConferma)
        .padding(.top, S.confermaSopra)
    }
}

/// La tabella «La sua vita intera / Una temporanea» (§9.1.7) e la nota.
struct TabellaConfrontoInquadra: View {
    let confronto: ConfrontoTemporanea
    let tipo: String?

    private typealias T = Tema.Apple.Inquadra.Tabella
    private typealias S = Tema.Apple.Inquadra.Scheda

    var body: some View {
        let larghezza = S.larghezza - S.padding.leading - S.padding.trailing
        let somma = T.pesi.reduce(0, +)
        let colonne = T.pesi.map { larghezza * $0 / somma }
        let p = confronto.polizza, t = confronto.temporanea
        let vitaIntera = MotoreConfrontoDossier.normaleTesto(tipo ?? "").contains("vita intera")
        let righe: [[String]] = [
            ["Spesa l’anno", p.spesaAnnua.map { MotoreInquadra.importo($0) } ?? "—", t.spesaAnnua.map { "circa " + Formati.euro($0) } ?? "—"],
            ["Capitale caso morte", p.capitaleCasoMorte.map { Formati.euro($0) } ?? "—", t.capitaleCasoMorte.map { Formati.euro($0) } ?? "—"],
            ["Valore di riscatto", MotoreInquadra.testoRiscatto(p.riscatto), MotoreInquadra.testoRiscatto(t.riscatto)],
        ]
        return VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                riga(["", vitaIntera ? "La sua vita intera" : "La sua polizza", "Una temporanea"], colonne: colonne, testa: true)
                ForEach(Array(righe.enumerated()), id: \.offset) { _, r in
                    riga(r, colonne: colonne, testa: false)
                        .overlay(alignment: .top) {
                            Rectangle().fill(T.filo).frame(height: Tema.Apple.Misura.bordo)
                        }
                }
            }
            .frame(width: larghezza)
            .clipShape(RoundedRectangle(cornerRadius: T.raggio, style: .continuous))
            .superficieApple(T.superficie, raggio: T.raggio)
            Text(MotoreInquadra.notaConfronto(confronto))
                .carattereApple(T.nota)
                .foregroundColor(T.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, T.notaSopra)
        }
        .padding(.top, T.sopra)
    }

    private func riga(_ celle: [String], colonne: [CGFloat], testa: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(celle.enumerated()), id: \.offset) { i, testo in
                Text(testo)
                    .carattereApple(testa ? T.carattereTesta : (i == 2 ? T.carattereForte : T.carattere))
                    .foregroundColor(i == 0 ? T.colorePrima : (i == 2 ? T.coloreTerza : T.coloreSeconda))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(T.padding)
                    .frame(width: colonne.indices.contains(i) ? colonne[i] : 0, alignment: .leading)
            }
        }
        .background(testa ? T.fondoTesta : Color.clear)
    }
}

/// La zona dove trascinare la foto o il PDF della polizza, con «Scegli un file…».
private struct ZonaInquadra: View {
    @Environment(StatoShell.self) var stato
    let inquadra: StatoInquadra

    private typealias Z = Tema.Apple.Inquadra.Zona

    var body: some View {
        let _ = ContaCorpi.segna()
        let sopra = inquadra.fileSopra
        let forma = RoundedRectangle(cornerRadius: Z.raggio, style: .continuous)
        return VStack(spacing: Z.spazio) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: Z.icona, weight: .regular))
                .foregroundColor(sopra ? Z.coloreTrattoSopra : Z.coloreIcona)
            Text(sopra ? "Rilascia per leggere" : "Trascina qui una foto o un PDF")
                .carattereApple(Z.testo)
                .foregroundColor(Z.coloreTesto)
            Button("Scegli un file…") { stato.scegliFileInquadra() }
                .buttonStyle(.appleSobrio)
                .disabled(stato.solaLettura)
        }
        .frame(maxWidth: .infinity, minHeight: Z.altezza)
        .background(forma.fill(sopra ? Z.fondoSopra : Z.fondo))
        .overlay(forma.strokeBorder(sopra ? Z.coloreTrattoSopra : Z.coloreTratto,
                                    style: StrokeStyle(lineWidth: Z.tratto, dash: Z.trattino)))
    }
}

// MARK: - Il pulsante della testata di Posizioni

/// «◎ Inquadra con l’iPhone» accanto ai segmenti del Portafoglio (§9.1.1).
struct PulsanteInquadra: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        Button { stato.apriInquadra() } label: {
            Label("Inquadra con l’iPhone", systemImage: "viewfinder")
        }
        .buttonStyle(.apple)
        .help("Leggi una polizza con la fotocamera dell’iPhone, oppure da una foto o un PDF trascinati sul Mac")
    }
}
#endif
