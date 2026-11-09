#if os(macOS)
import AppKit
import SwiftUI
import UniformTypeIdentifiers

// «Nuovo cliente in 10 secondi» sul Mac (Design/template-luce-specifica.md §9.1, «Luce» giro 13):
//
//   ┌ velo scuro sfocato sopra barra, finestre e dock ──────────────────────────────────────────────┐
//   │      ┌──────────┐        ┌ ● NUOVO CLIENTE · PRISMA SUL MAC ────────── ✕ ┐                    │
//   │      │ ▬▬ tacca │        │ (EM) Elena Marchi               secondi 3,6   │                    │
//   │      │ ┌──────┐ │        │ ✓ Nome e cognome     Elena Marchi              │                    │
//   │      │ │carta │ │        │ ✓ Nata il            3 aprile 1990, a Bologna  │                    │
//   │      │ │fac-s.│ │        │ …                                              │                    │
//   │      │ └──────┘ │        │ [Moduli già pronti da firmare]                 │                    │
//   │      │ ✓ Fatto  │        │ [ Crea il dossier di Elena ]   Scrivi a mano   │                    │
//   │      └──────────┘        └────────────────────────────────────────────────┘                    │
//   └───────────────────────────────────────────────────────────────────────────────────────────────┘
//
// - Il testo arriva dall'iPhone sul ponte (attesa) o da una foto o un PDF trascinati sulla scena, letti sul Mac.
// - Sul telefono disegnato c'è **sempre la carta fac-simile** (dati di prova dichiarati): il documento vero non si disegna.
// - Il contatore mostra il tempo vero (TimelineView, niente Timer), fermo a lettura finita.
// - Movimento come Inquadra (§9.1.3): velo, telefono, linea, righe a cascata, tile e pulsante; chiusura 0,22 s.
//   «Riduci movimento»: tutto fermo con la dissolvenza; istantanee: stato finale, linea in alto, contatore fisso.
// - Esc chiude la scena (salvo durante la modifica di una riga: lì annulla la modifica). Un clic sul velo non fa nulla.

/// Lo strato della scena nella shell: vuoto quando la scena è chiusa.
struct StratoNuovoCliente: View {
    let nuovoCliente: StatoNuovoCliente
    let aperta: Bool
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    var body: some View {
        ZStack {
            if aperta {
                ScenaNuovoCliente(nuovoCliente: nuovoCliente)
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

/// Il velo, l'iPhone disegnato con la carta e la scheda «Prisma sul Mac», centrati.
struct ScenaNuovoCliente: View {
    @Environment(StatoShell.self) var stato
    let nuovoCliente: StatoNuovoCliente

    private typealias D = Tema.Apple.NuovoCliente.Disposizione
    private typealias I = Tema.Apple.Inquadra.Disposizione
    private typealias A = Tema.Apple.Apparecchio

    var body: some View {
        let _ = ContaCorpi.segna()
        GeometryReader { geo in
            ZStack {
                VeloScena()
                HStack(alignment: .top, spacing: D.spazio) {
                    TelefonoCartaIdentita(nuovoCliente: nuovoCliente)
                    SchedaNuovoClienteMac(nuovoCliente: nuovoCliente)
                        .padding(.top, D.scartoScheda)
                }
                .scaleEffect(scala(geo.size))
                // Esc chiude la scena (non mentre si corregge una riga: lì Esc annulla la modifica)
                Button("Chiudi Nuovo cliente") { stato.chiudiNuovoCliente() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(StileSemplice())
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .disabled(nuovoCliente.inModifica != nil)
                    .accessibilityHidden(true)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onDrop(of: [.fileURL], isTargeted: Binding(get: { nuovoCliente.fileSopra },
                                                     set: { nuovoCliente.fileSopra = $0 && accetta })) { fornitori in
            guard accetta, let f = fornitori.first else { return false }
            _ = f.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async { stato.leggiFileNuovoCliente(url) }
            }
            return true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Nuovo cliente"))
    }

    private var accetta: Bool { nuovoCliente.fase != .lettura && !stato.solaLettura }

    private func scala(_ misura: CGSize) -> CGFloat {
        let larghezza = A.larghezza + D.spazio + Tema.Apple.NuovoCliente.Scheda.larghezza
        let altezza = A.altezza + D.scartoScheda
        let s = min(1, (misura.width - 2 * I.margine) / larghezza, (misura.height - 2 * I.margine) / altezza)
        return max(I.scalaMinima, s)
    }
}

// MARK: - L'iPhone disegnato con la carta

private struct TelefonoCartaIdentita: View {
    let nuovoCliente: StatoNuovoCliente
    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(\.prismaScatto) private var scatto
    @Environment(\.prismaCalmo) private var calmo
    @State private var entrato = false

    private typealias A = Tema.Apple.Apparecchio
    private typealias K = Tema.Apple.NuovoCliente.Carta

    var body: some View {
        let m = Tema.Apple.Moto.Inquadra.self
        let dentro = entrato || fermo || calmo
        return TelefonoDisegnato { schermo }
            .rotationEffect(.degrees(dentro ? 0 : m.rotazioneTelefono))
            .offset(y: dentro ? 0 : m.spostamentoTelefono)
            .opacity(dentro ? 1 : 0)
            .onAppear {
                guard !entrato, !scatto else { return }
                if fermo || calmo {
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
            if nuovoCliente.fase == .letto {
                CartaIdentitaDisegnata(accesi: nuovoCliente.campiAccesi)
                    .rotationEffect(.degrees(K.rotazione))
                    .padding(.horizontal, K.lati)
                    .padding(.top, K.dallAlto)
                LineaScansioneCarta(chiave: nuovoCliente.righe.count)
            }
            VStack {
                Spacer(minLength: 0)
                Text(scritta)
                    .carattereApple(A.scritta)
                    .foregroundColor(A.coloreScritta)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, K.lati)
                    .padding(.bottom, A.scrittaDalFondo)
            }
        }
        .clipShape(forma)
    }

    /// «Inquadra il documento» → «Riconosco i dati…» → «✓ Fatto».
    private var scritta: String {
        switch nuovoCliente.fase {
        case .attesa: return "Inquadra il documento"
        case .trascina: return "Trascina la foto sul Mac"
        case .lettura: return "Riconosco i dati…"
        case .illeggibile: return "Non riesco a leggere il documento: avvicinalo e cerca una luce senza riflessi"
        case .letto:
            if nuovoCliente.finito { return "✓ Fatto" }
            return nuovoCliente.mostrate > 0 ? "Riconosco i dati…" : "Inquadra il documento"
        }
    }
}

/// La linea verde sopra la carta: due corse da 110 a 420, poi ferma in alto. Con «Riduci movimento» non c'è; nelle
/// istantanee resta in alto.
private struct LineaScansioneCarta: View {
    let chiave: Int
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

    /// Due corse (giù e su, due volte), poi in alto.
    private func scorri() {
        guard !fermo else { return }
        giro += 1
        let g = giro
        let m = Tema.Apple.Moto.Inquadra.self
        for passo in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(passo) * m.durataLinea) {
                guard giro == g else { return }
                withAnimation(m.linea) { giu = passo % 2 == 0 }
            }
        }
    }
}

// MARK: - La scheda «Prisma sul Mac»

private struct SchedaNuovoClienteMac: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaScatto) private var scatto
    let nuovoCliente: StatoNuovoCliente

    private typealias I = Tema.Apple.Inquadra.Scheda
    private typealias S = Tema.Apple.NuovoCliente.Scheda

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: 0) {
            testa
            rigaCliente
                .padding(.top, S.rigaClienteSopra)
            contenuto
            Button("Scrivi a mano") { stato.scriviAManoDaCarta() }
                .buttonStyle(StileSemplice())
                .carattereApple(S.link)
                .foregroundColor(S.coloreLink)
                .padding(.top, S.linkSopra)
                .disabled(stato.solaLettura)
                .help("Apri il modulo del cliente con i dati letti fin qui")
        }
        .padding(I.padding)
        .frame(width: S.larghezza, alignment: .leading)
        .superficieApple(I.superficie)
    }

    private var testa: some View {
        HStack(spacing: I.spazioTesta) {
            SferaVera(misura: I.sfera, viva: true, pensa: nuovoCliente.fase == .lettura)
            Text("Nuovo cliente · Prisma sul Mac")
                .carattereApple(I.etichetta)
                .foregroundColor(I.coloreEtichetta)
            Spacer(minLength: 0)
            Button { stato.chiudiNuovoCliente() } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.apple)
            .help("Chiudi (Esc): i dati letti si scartano")
            .accessibilityLabel(Text("Chiudi"))
        }
    }

    // MARK: Riga del cliente con il contatore

    private var acceso: Bool { nuovoCliente.fase == .letto && nuovoCliente.mostrate > 0 }

    private var rigaCliente: some View {
        let lettura = nuovoCliente.letturaCorretta
        // Aperta da «Diventa cliente» (§9.2.4): il nome del potenziale è già scritto, l'avatar resta spento fino alla carta
        let scritto = nuovoCliente.potenzialeId.flatMap { id in stato.dati.potenziali.first { $0.id == id }?.nome }
        let nome = acceso ? (lettura.nomeCompleto ?? scritto ?? "…") : (scritto ?? "…")
        let iniziali = acceso ? Cliente.iniziali(di: lettura.nomeCompleto ?? scritto ?? "") : scritto.map { Cliente.iniziali(di: $0) } ?? ""
        return HStack(alignment: .center, spacing: S.spazioCliente) {
            AvatarCliente(iniziali: iniziali, tinta: stato.prossimaTinta.colori, lato: S.avatar)
                .opacity(acceso ? 1 : S.avatarSpento)
                .animation(calmo || scatto ? nil : Tema.Apple.Moto.NuovoCliente.avatar, value: acceso)
            VStack(alignment: .leading, spacing: S.spazioNome) {
                Text(nome)
                    .carattereApple(S.nome)
                    .foregroundColor(S.coloreNome)
                    .lineLimit(1)
                Text(sottotitolo)
                    .carattereApple(S.sottotitolo)
                    .foregroundColor(S.coloreSottotitolo)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: S.spazioNome) {
                Text("secondi")
                    .carattereApple(S.etichettaSecondi)
                    .foregroundColor(S.coloreSottotitolo)
                contatore
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// Il tempo vero della lettura: scorre mentre legge, poi resta fermo (con «Riduci movimento» solo il valore finale).
    @ViewBuilder private var contatore: some View {
        if let s = nuovoCliente.secondiImpiegati {
            testoSecondi(s)
        } else if let inizio = nuovoCliente.inizio, !calmo, !scatto,
                  nuovoCliente.fase == .lettura || nuovoCliente.fase == .letto {
            TimelineView(.periodic(from: inizio, by: Tema.Apple.Moto.NuovoCliente.passoContatore)) { contesto in
                testoSecondi(contesto.date.timeIntervalSince(inizio))
            }
        } else {
            testoSecondi(0)
        }
    }

    private func testoSecondi(_ s: Double) -> some View {
        Text(String(format: "%.1f", max(0, s)).replacingOccurrences(of: ".", with: ","))
            .carattereApple(S.secondi)
            .foregroundColor(S.coloreNome)
    }

    private var sottotitolo: String {
        switch nuovoCliente.fase {
        case .attesa: return "Inquadra la carta d’identità con l’iPhone: qui arrivano solo i dati letti"
        case .trascina: return "Trascina qui la foto o il PDF della carta d’identità"
        case .lettura: return "Leggo il documento"
        case .illeggibile: return "Nessun dato letto"
        case .letto:
            guard nuovoCliente.finito else { return "Leggo il documento" }
            return MotoreCartaIdentita.sottotitolo(nuovoCliente.letturaCorretta)
        }
    }

    // MARK: Contenuto secondo la fase

    @ViewBuilder private var contenuto: some View {
        // «Diventa cliente» da Clienti › Potenziali: prima della lettura la scheda dice già chi l'ha presentato
        if nuovoCliente.fase != .letto, nuovoCliente.potenzialeId != nil, let p = stato.potenzialeDaCarta {
            tilePotenziale(p, nota: TestiPassaparola.notaPotenzialeAttesa)
        }
        switch nuovoCliente.fase {
        case .attesa:
            ZonaNuovoCliente(nuovoCliente: nuovoCliente, testo: "oppure trascina qui una foto o un PDF del documento", nota: nil)
                .padding(.top, Tema.Apple.Inquadra.Zona.sopra)
        case .trascina:
            ZonaNuovoCliente(nuovoCliente: nuovoCliente, testo: "Trascina qui una foto o un PDF del documento",
                             nota: "Per usare l’iPhone accendi il collegamento in Impostazioni › Vera › iPhone e iPad")
                .padding(.top, Tema.Apple.Inquadra.Zona.sopra)
        case .lettura:
            EmptyView()
        case .illeggibile:
            HStack(spacing: I.spazioPulsanti) {
                Button("Scrivi a mano") { stato.scriviAManoDaCarta() }
                    .buttonStyle(.applePrimarioGrande)
                    .keyboardShortcut(.defaultAction)
                    .disabled(stato.solaLettura)
                Button("Riprova") { nuovoCliente.ricomincia(fase: stato.ponteInquadraAcceso ? .attesa : .trascina) }
                    .buttonStyle(.appleGrande)
            }
            .padding(.top, I.pulsantiSopra)
        case .letto:
            letto
        }
    }

    @ViewBuilder private var letto: some View {
        let righe = stato.righeNuovoCliente()
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(righe.prefix(nuovoCliente.mostrate)), id: \.id) { r in
                RigaSchedaNuovoCliente(nuovoCliente: nuovoCliente, riga: r)
                    .entrataStile(.rigaInquadra)
            }
        }
        .padding(.top, S.righeSopra)
        if nuovoCliente.finito {
            if let gia = stato.clienteGiaPresenteDaCarta {
                giaInPrisma(gia)
                    .entrataStile(.tabellaInquadra)
            } else {
                // «È un potenziale cliente» (§9.1.4): «Crea il dossier» porta con sé chi l'ha presentato
                if let p = stato.potenzialeDaCarta {
                    tilePotenziale(p, nota: TestiPassaparola.notaPotenzialeLetto)
                        .entrataStile(.tabellaInquadra)
                }
                tileModuli
                    .entrataStile(.tabellaInquadra)
                copia
                pulsante
                    .entrataStile(.tabellaInquadra)
            }
        }
    }

    /// «Elena Marchi è già in Prisma» con «Apri il suo dossier» e «Aggiorna il documento».
    private func giaInPrisma(_ c: Cliente) -> some View {
        VStack(alignment: .leading, spacing: I.spazioPulsanti) {
            Text("\(c.nome) è già in Prisma")
                .carattereApple(S.titoloTile)
                .foregroundColor(S.coloreTitoloTile)
            HStack(spacing: I.spazioPulsanti) {
                Button("Apri il suo dossier") { stato.apriDossierDaCarta(c.id) }
                    .buttonStyle(.applePrimarioGrande)
                    .keyboardShortcut(.defaultAction)
                Button("Aggiorna il documento") { stato.aggiornaDocumentoDaCarta(c.id) }
                    .buttonStyle(.appleGrande)
                    .disabled(stato.solaLettura)
                    .help("Cambia solo il documento d’identità del suo dossier")
            }
        }
        .padding(I.paddingConferma)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(I.superficieConferma)
        .padding(.top, S.tileSopra)
    }

    /// «Elena Marchi è tra i potenziali, presentata da Sofia» con la nota sotto (stessa tile dei moduli).
    private func tilePotenziale(_ p: PotenzialeCliente, nota: String) -> some View {
        VStack(alignment: .leading, spacing: S.paddingVoceModulo) {
            Text(stato.frasePotenzialeDaCarta(p))
                .carattereApple(S.titoloTile)
                .foregroundColor(S.coloreTitoloTile)
                .fixedSize(horizontal: false, vertical: true)
            Text(nota)
                .carattereApple(S.fraseTile)
                .foregroundColor(S.coloreFraseTile)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(I.paddingConferma)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(I.superficieConferma)
        .padding(.top, S.tileSopra)
        .accessibilityElement(children: .combine)
    }

    /// I moduli di privacy e adeguata verifica: pronti se i modelli ci sono, altrimenti «Moduli da preparare».
    private var tileModuli: some View {
        let modelli = stato.modelliPrivacyEVerifica
        let pronti = !modelli.isEmpty
        let privacy = modelli.contains { $0.tipo == .privacy }
        let verifica = modelli.contains { $0.tipo == .adeguataVerifica }
        return VStack(alignment: .leading, spacing: 0) {
            Text(pronti ? "Moduli già pronti da firmare" : "Moduli da preparare")
                .carattereApple(S.titoloTile)
                .foregroundColor(S.coloreTitoloTile)
            voceModulo(TipoModulo.privacy.nome, pronta: privacy)
            voceModulo(TipoModulo.adeguataVerifica.nome, pronta: verifica)
            if !pronti {
                Text("Carica i modelli dei moduli in Pratiche › Moduli: Prisma li compila con questi dati")
                    .carattereApple(S.fraseTile)
                    .foregroundColor(S.coloreFraseTile)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, S.paddingVoceModulo)
            }
        }
        .padding(I.paddingConferma)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(I.superficieConferma)
        .padding(.top, S.tileSopra)
    }

    private func voceModulo(_ nome: String, pronta: Bool) -> some View {
        HStack(spacing: S.spazioCampi) {
            if pronta {
                SpuntaDisegnata(disegnata: true, lato: S.spuntaModulo)
            } else {
                Circle()
                    .strokeBorder(S.coloreVoceSpenta, lineWidth: Tema.Apple.Misura.bordo)
                    .frame(width: S.spuntaModulo, height: S.spuntaModulo)
            }
            Text(nome)
                .carattereApple(S.voceModulo)
                .foregroundColor(pronta ? S.coloreVoceModulo : S.coloreVoceSpenta)
        }
        .padding(.vertical, S.paddingVoceModulo)
    }

    /// L'interruttore della copia (solo per un file trascinato sul Mac, decisione 38) o la riga grigia dell'iPhone.
    @ViewBuilder private var copia: some View {
        if nuovoCliente.fileOrigine != nil {
            HStack(spacing: S.spazioCampi) {
                Text("Salva la copia del documento nei Documenti di \(stato.nomeBreveDaCarta ?? "questo cliente")")
                    .carattereApple(S.copia)
                    .foregroundColor(S.coloreCopia)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Toggle(isOn: Binding(get: { nuovoCliente.salvaCopia }, set: { nuovoCliente.salvaCopia = $0 })) { EmptyView() }
                    .toggleStyle(.appleSenzaEtichetta)
                    .accessibilityLabel(Text("Salva la copia del documento"))
            }
            .padding(.top, S.copiaSopra)
        } else if nuovoCliente.cartaId != nil {
            Text("Dall’iPhone arriva solo il testo: la copia non c’è")
                .carattereApple(S.copia)
                .foregroundColor(S.coloreCopia)
                .padding(.top, S.copiaSopra)
        }
    }

    /// «Crea il dossier di Elena», o «Completa e crea il dossier» se mancano dati (apre il modulo con i dati letti).
    private var pulsante: some View {
        let mancano = !MotoreCartaIdentita.mancanti(nuovoCliente.letturaCorretta).isEmpty
        let nome = stato.nomeBreveDaCarta ?? "questo cliente"
        return Button(mancano ? "Completa e crea il dossier" : "Crea il dossier di \(nome)") {
            // Un `if` con rami di tipo diverso non diventa un'espressione: il risultato si scarta esplicitamente
            if mancano { stato.scriviAManoDaCarta() } else { _ = stato.creaClienteDaCarta() }
        }
        .buttonStyle(.applePrimarioGrande)
        .keyboardShortcut(.defaultAction)
        .disabled(stato.solaLettura || nuovoCliente.inModifica != nil)
        .help(stato.solaLettura ? "Archivio in sola lettura: aggiorna Prisma per creare il cliente." : "Crea il cliente con i dati letti")
        .padding(.top, S.pulsanteSopra)
    }
}

// MARK: - Una riga della scheda

/// «✓ Nome e cognome  Elena Marchi»: un clic la rende modificabile sul posto (Invio conferma, Esc annulla); il segno
/// diventa la matita grigia «scritto da te».
private struct RigaSchedaNuovoCliente: View {
    let nuovoCliente: StatoNuovoCliente
    let riga: RigaNuovoCliente
    @State private var testi: [CampoCarta: String] = [:]

    private typealias I = Tema.Apple.Inquadra.Scheda
    private typealias S = Tema.Apple.NuovoCliente.Scheda

    private var inModifica: Bool { nuovoCliente.inModifica == riga.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: I.spazioTesta) {
                segno
                    .frame(width: I.larghezzaSpunta, alignment: .leading)
                Text(riga.etichetta)
                    .carattereApple(I.etichettaRiga)
                    .foregroundColor(I.coloreEtichettaRiga)
                    .frame(width: S.larghezzaEtichetta, alignment: .leading)
                if inModifica {
                    campi
                } else {
                    Text(riga.valore)
                        .carattereApple(riga.stato == .mancante ? I.etichettaRiga : I.valore)
                        .foregroundColor(colore)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
            if let nota = riga.nota, !inModifica {
                Text(nota)
                    .carattereApple(S.nota)
                    .foregroundColor(S.coloreDaGuardare)
                    .padding(.leading, I.larghezzaSpunta + I.spazioTesta + S.larghezzaEtichetta + I.spazioTesta)
                    .padding(.top, S.notaSopra)
            }
        }
        .padding(.vertical, I.paddingRiga)
        .overlay(alignment: .bottom) { Rectangle().fill(I.filo).frame(height: Tema.Apple.Misura.bordo) }
        .contentShape(Rectangle())
        .onTapGesture { if !inModifica { apri() } }
        .accessibilityElement(children: inModifica ? .contain : .ignore)
        .accessibilityLabel(Text("\(riga.etichetta), \(riga.valore), \(descrizioneStato)"))
        .accessibilityAddTraits(inModifica ? [] : .isButton)
        .accessibilityAction { if !inModifica { apri() } }
    }

    @ViewBuilder private var segno: some View {
        switch riga.stato {
        case .letta:
            Text("✓").carattereApple(I.spunta).foregroundColor(I.coloreSpunta)
        case .scrittaDaTe:
            Image(systemName: S.segnoScrittoDaTe).foregroundColor(S.coloreScrittoDaTe)
        case .mancante:
            Text("—").carattereApple(I.spunta).foregroundColor(S.coloreMancante)
        case .daGuardare:
            Text("!").carattereApple(I.spunta).foregroundColor(S.coloreDaGuardare)
        }
    }

    private var colore: Color {
        switch riga.stato {
        case .letta, .scrittaDaTe: return I.coloreValore
        case .mancante: return S.coloreMancante
        case .daGuardare: return S.coloreDaGuardare
        }
    }

    private var descrizioneStato: String {
        switch riga.stato {
        case .letta: return "letto dal documento"
        case .scrittaDaTe: return "scritto da te"
        case .mancante: return "non letto"
        case .daGuardare: return "da controllare"
        }
    }

    /// Un campo per ogni dato della riga (nome e cognome, data e luogo…).
    private var campi: some View {
        VStack(alignment: .leading, spacing: S.spazioCampi) {
            ForEach(riga.campi, id: \.self) { c in
                TextField(c.etichetta, text: Binding(get: { testi[c] ?? "" }, set: { testi[c] = $0 }))
                    .textFieldStyle(.roundedBorder)
                    .font(S.campo.font)
                    .onSubmit(conferma)
                    .onExitCommand(perform: annulla)
            }
        }
    }

    private func apri() {
        let l = nuovoCliente.letturaCorretta
        var t: [CampoCarta: String] = [:]
        for c in riga.campi { t[c] = nuovoCliente.correzioni[c] ?? l[c]?.valore ?? "" }
        testi = t
        nuovoCliente.inModifica = riga.id
    }

    /// Invio: le correzioni entrano (il codice fiscale si ricontrolla da solo nelle righe).
    private func conferma() {
        let l = nuovoCliente.lettura
        for c in riga.campi {
            let t = (testi[c] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            // Un valore uguale a quello letto non è una correzione
            if t == l[c]?.valore { nuovoCliente.correzioni[c] = nil } else { nuovoCliente.correzioni[c] = t }
        }
        nuovoCliente.inModifica = nil
    }

    private func annulla() {
        nuovoCliente.inModifica = nil
    }
}

/// La zona tratteggiata dove trascinare la foto o il PDF della carta, con «Scegli un file…».
private struct ZonaNuovoCliente: View {
    @Environment(StatoShell.self) var stato
    let nuovoCliente: StatoNuovoCliente
    let testo: String
    let nota: String?

    private typealias Z = Tema.Apple.Inquadra.Zona

    var body: some View {
        let sopra = nuovoCliente.fileSopra
        let forma = RoundedRectangle(cornerRadius: Z.raggio, style: .continuous)
        return VStack(spacing: Z.spazio) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: Z.icona, weight: .regular))
                .foregroundColor(sopra ? Z.coloreTrattoSopra : Z.coloreIcona)
            Text(sopra ? "Rilascia per leggere" : testo)
                .carattereApple(Z.testo)
                .foregroundColor(Z.coloreTesto)
                .multilineTextAlignment(.center)
            if let nota {
                Text(nota)
                    .carattereApple(Z.sottotesto)
                    .foregroundColor(Z.coloreSottotesto)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Scegli un file…") { stato.scegliFileNuovoCliente() }
                .buttonStyle(.appleSobrio)
                .disabled(stato.solaLettura)
        }
        .padding(.horizontal, Tema.Apple.NuovoCliente.Scheda.paddingZona)
        .frame(maxWidth: .infinity, minHeight: Z.altezza)
        .background(forma.fill(sopra ? Z.fondoSopra : Z.fondo))
        .overlay(forma.strokeBorder(sopra ? Z.coloreTrattoSopra : Z.coloreTratto,
                                    style: StrokeStyle(lineWidth: Z.tratto, dash: Z.trattino)))
    }
}
#endif
