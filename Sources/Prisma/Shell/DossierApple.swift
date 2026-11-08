#if os(macOS)
import AppKit
#endif
import SwiftUI

// Clienti nel tema Apple: rubrica e dossier (Design/template-apple-specifica.md §4.2.1, PC C01-C05).
// - RubricaApple: `.lbl` «Rubrica» con il numero, ricerca a capsula che filtra a ogni tasto (nome e motto, senza
//   animazione), il filtro dei preferiti di Prisma, le voci (avatar 38, nome, motto) e il piede.
// - DossierApple: testata (avatar 56, «Dossier personale», nome, motto · età · professione; a destra canali,
//   preferito, «Modifica», «Analisi 360» e «Prospetti»), le quattro tessere che contano, le schede e il contenuto.
// - Le schede: le quattro del template nel segmentato a pillola, quelle di Prisma nel menu «Altro ▾».
//   Le schede del template (Shell/Dossier<Nome>.swift) disegnano da sé le loro card; quelle di Prisma entrano nella
//   cornice del tema (`corniceSchedaDossier()`), con il contenuto di prima.
// - Cambio cliente: il dossier esce a x +14 in 0,14 s ease-in, poi tutto rientra a cascata con base 0 e le cifre
//   ricontano da 0; la scheda attiva resta quella scelta. Cambio scheda: il contenuto esce a y +6 in 0,13 s
//   lineare, poi cascata. «Riduci movimento»: il cambio è una dissolvenza di 0,15 s; istantanee: di colpo.
// Valori in DesignSystem/Apple/Tema.Apple+Clienti.swift.

// MARK: - Le schede del dossier

extension SchedaCliente {
    /// Le schede del template, nel segmentato a pillola: Panoramica · Obiettivi · Linea della vita · Nel tempo · Famiglia
    /// (la linea della vita fra Obiettivi e Nel tempo: Orizzonte, parte comune §1.7).
    static let delSegmentato: [SchedaCliente] = [.panoramica, .obiettivi, .lineaVita, .nelTempo, .famiglia]
    /// Le schede di Prisma che il template non ha, nel menu «Altro ▾».
    static let dellAltro: [SchedaCliente] = [.bisogni, .documenti, .inRegola, .riesami, .anagrafica, .profilo, .note]

    /// Le schede del segmentato per il cliente: «L'azienda» in fondo solo se ha almeno un'azienda registrata («Luce»
    /// giro 7, decisione 3.1).
    static func delSegmentato(per c: Cliente?) -> [SchedaCliente] {
        (c?.elencoAziende.isEmpty ?? true) ? delSegmentato : delSegmentato + [.azienda]
    }

    /// Le schede di «Altro» per il cliente: chi non ha un'azienda la trova qui, per aggiungerla.
    static func dellAltro(per c: Cliente?) -> [SchedaCliente] {
        (c?.elencoAziende.isEmpty ?? true) ? dellAltro + [.azienda] : dellAltro
    }

    /// Il titolo nel menu «Altro»: «Azienda» (§9.3.1, stato 1.4).
    var titoloAltro: String { self == .azienda ? "Azienda" : titolo }

    /// Le schede del template (e «L'azienda» di Luce) disegnano da sé le loro card; le altre entrano nella cornice del tema.
    var delTemplate: Bool { Self.delSegmentato.contains(self) || self == .azienda }

    /// La scheda scorre dentro il dossier. Documenti (elenco e dettaglio scorrono da soli), Nel tempo e la linea
    /// della vita (il grafico prende tutta l'altezza) no.
    var scorreNelDossier: Bool { self != .documenti && self != .nelTempo && self != .lineaVita }
}

// MARK: - Cascata del contenuto delle schede

/// Da dove parte la cascata del contenuto della scheda: indice 6 e base 0 quando entra con il cliente
/// (dopo testata, tessere e segmentato), indice 0 quando cambia solo la scheda; base 0,14 all'apertura.
struct AvvioCascataDossier: Equatable {
    var primoIndice: Int
    var base: Double
}

private struct ChiaveAvvioCascataDossier: EnvironmentKey {
    static let defaultValue = AvvioCascataDossier(primoIndice: 0, base: Tema.Apple.Clienti.Moto.baseCambio)
}

extension EnvironmentValues {
    /// L'avvio della cascata per il contenuto della scheda del dossier (lo imposta `DossierApple`).
    var avvioCascataDossier: AvvioCascataDossier {
        get { self[ChiaveAvvioCascataDossier.self] }
        set { self[ChiaveAvvioCascataDossier.self] = newValue }
    }
}

extension View {
    /// Entrata a cascata di un blocco nel contenuto di una scheda del dossier: `indice` conta dall'alto della
    /// scheda (0, 1, 2…); il dossier ci aggiunge da dove parte (dopo il cliente o dopo il cambio di scheda).
    /// `sfocatura: false` per i blocchi che hanno già un vetro dentro.
    func entrataDossier(_ indice: Int, sfocatura: Bool = true) -> some View {
        modifier(EntrataDossierApple(indice: indice, sfocatura: sfocatura))
    }

    /// La cornice delle schede di Prisma nel dossier: card senza ombra, padding 20×22, corpo 14.
    func corniceSchedaDossier() -> some View {
        modifier(CorniceSchedaDossier())
    }
}

private struct EntrataDossierApple: ViewModifier {
    let indice: Int
    let sfocatura: Bool
    @Environment(\.avvioCascataDossier) private var avvio

    func body(content: Content) -> some View {
        content.entrataCascata(avvio.primoIndice + indice, base: avvio.base, sfocatura: sfocatura)
    }
}

private struct CorniceSchedaDossier: ViewModifier {
    func body(content: Content) -> some View {
        let s = Tema.Apple.Clienti.Schede.self
        return content
            .font(s.corpo.font)
            .foregroundColor(s.coloreCorpo)
            .padding(s.paddingCornice)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .superficieApple(s.cornice)
    }
}

private struct FondoSuperficieDossier: ViewModifier {
    let superficie: Tema.Apple.Superficie?

    func body(content: Content) -> some View {
        content.background {
            if let s = superficie {
                Color.clear.superficieApple(s)
            }
        }
    }
}

extension View {
    /// La superficie del tema dietro la vista, se c'è (sul Mac la card del dossier; su iPad il vetro della finestra).
    func fondoSuperficie(_ superficie: Tema.Apple.Superficie?) -> some View {
        modifier(FondoSuperficieDossier(superficie: superficie))
    }
}

// MARK: - Rubrica

/// La rubrica del tema Apple: `.lbl` con il numero dei clienti, ricerca a capsula, filtro dei preferiti, voci e piede.
struct RubricaApple: View {
    @Environment(StatoShell.self) var stato
    @Binding var ricerca: String
    @Binding var soloPreferiti: Bool

    /// Filtra a ogni tasto su nome e motto (senza animazione), in ordine alfabetico.
    private var elenco: [Cliente] {
        let testo = ricerca.trimmingCharacters(in: .whitespaces).lowercased()
        return stato.clienti
            .filter { !soloPreferiti || $0.preferito }
            .filter { testo.isEmpty || $0.nome.lowercased().contains(testo) || $0.tema.lowercased().contains(testo) }
            .sorted { $0.nome.localizedCaseInsensitiveCompare($1.nome) == .orderedAscending }
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let r = Tema.Apple.Clienti.Rubrica.self
        // Filtrato e ordinato una volta per disegno, non a ogni uso
        let elenco = self.elenco
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: r.spazioTitolo) {
                Text("Rubrica")
                Spacer(minLength: r.spazioTitolo)
                Text("\(stato.clienti.count)")
                    .monospacedDigit()
            }
            .carattereApple(r.titolo)
            .foregroundColor(r.coloreTitolo)

            CampoRicercaApple(testo: $ricerca, segnaposto: "Cerca nome o progetto")
                .padding(.top, r.sopraRicerca)
                .padding(.bottom, r.sottoRicerca)

            SegmentatoPillola(selezione: $soloPreferiti, voci: [(false, "Tutti"), (true, "★ Preferiti")],
                              larghezzaPiena: true)
                .padding(.bottom, r.sottoFiltro)

            ScrollView(.vertical, showsIndicators: false) {
                ElencoRubricaApple(clienti: elenco, attivo: stato.clienteAttivoId, ricercaVuota: ricerca.isEmpty,
                                   scegli: { stato.clienteAttivoId = $0 })
                    .equatable()
            }

            piede
                .padding(.top, r.sopraPiede)
        }
        .padding(r.padding)
    }

    /// «5 contatti» e, finché i 30 clienti fittizi non ci sono, «+ 30 clienti di prova» (il comando di Impostazioni).
    private var piede: some View {
        let r = Tema.Apple.Clienti.Rubrica.self
        let n = stato.clienti.count
        let contatti = "\(n) \(n == 1 ? "contatto" : "contatti")"
        return VStack(spacing: r.fraRighePiede) {
            if mostraClientiDiProva {
                Button("+ 30 clienti di prova") {
                    stato.schedaImpostazioni = .strumenti
                    stato.apri(.impostazioni)
                }
                .buttonStyle(.appleSobrio)
                .help("Impostazioni › Strumenti: i 35 clienti di prova completi")
            }
            Text(contatti)
                .carattereApple(r.piede)
                .foregroundColor(r.colorePiede)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    /// Il comando c'è solo sul Mac, con i clienti di prova del template e senza quelli fittizi.
    private var mostraClientiDiProva: Bool {
        #if os(macOS)
        guard !stato.inModoCliente, stato.haDatiDiProva else { return false }
        return !stato.dati.clienti.contains { $0.id.hasPrefix(ClientiFittizi.prefisso) }
        #else
        return false
        #endif
    }
}

/// Le voci della rubrica: pigre (con centinaia di clienti si costruiscono solo quelle in vista) e rifatte solo
/// quando cambiano i clienti mostrati o quello scelto, non a ogni avviso di StatoShell.
struct ElencoRubricaApple: View, Equatable {
    let clienti: [Cliente]
    let attivo: String
    let ricercaVuota: Bool
    let scegli: (String) -> Void

    nonisolated static func == (a: ElencoRubricaApple, b: ElencoRubricaApple) -> Bool {
        a.attivo == b.attivo && a.ricercaVuota == b.ricercaVuota && a.clienti == b.clienti
    }

    var body: some View {
        let r = Tema.Apple.Clienti.Rubrica.self
        return LazyVStack(spacing: r.fraVoci) {
            ForEach(clienti) { c in
                VoceRubricaApple(cliente: c, scelta: c.id == attivo) { scegli(c.id) }
            }
            if clienti.isEmpty {
                Text(ricercaVuota ? "Nessun cliente in rubrica: aggiungine uno con «Nuovo cliente» in alto." : "Nessun cliente trovato.")
                    .carattereApple(r.piede)
                    .foregroundColor(r.colorePiede)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(r.paddingVoce)
            }
        }
    }
}

/// Una voce della rubrica: avatar 38, nome 14 bold, motto 12 troncato; sotto il puntatore `chip`,
/// scelta `rgba(0,122,255,.13)`, il fondo cambia in 0,25 s.
struct VoceRubricaApple: View {
    let cliente: Cliente
    let scelta: Bool
    let azione: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var sopra = false

    var body: some View {
        let r = Tema.Apple.Clienti.Rubrica.self
        let forma = RoundedRectangle(cornerRadius: r.raggioVoce, style: .continuous)
        return Button(action: azione) {
            HStack(spacing: r.spazioVoce) {
                AvatarCliente(iniziali: cliente.iniziali, tinta: cliente.tinta.colori, lato: r.avatar)
                VStack(alignment: .leading, spacing: r.spazioNomeMotto) {
                    Text(cliente.nome)
                        .carattereApple(r.nome)
                        .foregroundColor(r.coloreNome)
                    Text(cliente.tema)
                        .carattereApple(r.motto)
                        .foregroundColor(r.coloreMotto)
                }
                .lineLimit(1)
                Spacer(minLength: 2)
                if cliente.preferito {
                    Text("★")
                        .carattereApple(r.stella)
                        .foregroundColor(r.coloreStella)
                }
            }
            .padding(r.paddingVoce)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { fondo }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .onHover { dentro in sopra = dentro && !istantanea }
        .animation(animazione, value: scelta)
        .animation(animazione, value: sopra)
        .accessibilityAddTraits(scelta ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    @ViewBuilder private var fondo: some View {
        let r = Tema.Apple.Clienti.Rubrica.self
        let forma = RoundedRectangle(cornerRadius: r.raggioVoce, style: .continuous)
        if scelta {
            forma.fill(r.fondoScelta)
        } else if sopra {
            forma.fill(r.fondoSopra)
        }
    }

    private var animazione: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Clienti.Rubrica.animazioneFondo, calmo: calmo, istantanea: istantanea)
    }
}

/// La ricerca a capsula della rubrica: fondo `chip`, padding 8×14, 13; la ✕ cancella.
struct CampoRicercaApple: View {
    @Binding var testo: String
    let segnaposto: String

    var body: some View {
        let r = Tema.Apple.Clienti.Rubrica.self
        return HStack(spacing: r.spazioSegnoRicerca) {
            Image(systemName: "magnifyingglass")
                .font(r.carattereRicerca.font)
                .foregroundColor(r.segnoRicerca)
            TextField(segnaposto, text: $testo)
                .textFieldStyle(.plain)
                .font(r.carattereRicerca.font)
                .foregroundColor(r.coloreRicerca)
            if !testo.isEmpty {
                Button { testo = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(r.carattereRicerca.font)
                        .foregroundColor(r.segnoRicerca)
                }
                .buttonStyle(StileSemplice())
                .help("Cancella la ricerca")
                .accessibilityLabel("Cancella la ricerca")
            }
        }
        .padding(r.paddingRicerca)
        .background { Capsule(style: .continuous).fill(r.fondoRicerca) }
    }
}

// MARK: - Dossier

/// Il dossier del cliente attivo: testata, tessere, schede e contenuto della scheda, con il cambio di cliente e di
/// scheda del template. `contenuto` disegna la scheda (lo fornisce AppClienti, che tiene i fogli dei moduli).
struct DossierApple<Contenuto: View>: View {
    @Environment(StatoShell.self) var stato
    /// La superficie del dossier: sul Mac la card senza ombra; su iPad nil (sta già sul vetro della finestra).
    let superficie: Tema.Apple.Superficie?
    let modifica: (Cliente) -> Void
    let contenuto: (SchedaCliente, Cliente) -> Contenuto

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    /// Il cliente e la scheda mostrati: restano quelli di prima finché il dossier esce.
    @State private var clienteMostrato: String?
    @State private var schedaMostrata: SchedaCliente?
    @State private var esceCliente = false
    @State private var esceScheda = false
    /// Base della cascata di testata, tessere e segmentato: 0,14 all'apertura della finestra, poi 0.
    @State private var baseDossier = Tema.Apple.Clienti.Moto.baseApertura
    @State private var avvio = AvvioCascataDossier(primoIndice: Tema.Apple.Clienti.Moto.primoIndiceScheda,
                                                   base: Tema.Apple.Clienti.Moto.baseApertura)

    init(superficie: Tema.Apple.Superficie?, modifica: @escaping (Cliente) -> Void,
         @ViewBuilder contenuto: @escaping (SchedaCliente, Cliente) -> Contenuto) {
        self.superficie = superficie
        self.modifica = modifica
        self.contenuto = contenuto
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let id = clienteMostrato ?? stato.clienteAttivoId
        let scheda = schedaMostrata ?? stato.schedaCliente
        return Group {
            if let c = stato.cliente(id) ?? stato.clienteAttivo {
                dossier(c, scheda: scheda)
                    // Un altro cliente: tutto si rifà, entra a cascata e le cifre ricontano da 0
                    .id(c.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            // Nelle istantanee (e nella prova di fluidità) il cambio è sempre di colpo (`cambiaCliente`, `cambiaScheda`):
            // finché non cambia niente, nil vuol dire «quelli dello stato», e scriverli rifarebbe subito tutto il dossier
            guard !istantanea else { return }
            clienteMostrato = stato.clienteAttivoId
            schedaMostrata = stato.schedaCliente
        }
        .onChange(of: stato.clienteAttivoId) { nuovo in cambiaCliente(nuovo) }
        .onChange(of: stato.schedaCliente) { nuova in cambiaScheda(nuova) }
    }

    private func dossier(_ c: Cliente, scheda: SchedaCliente) -> some View {
        let k = Tema.Apple.Clienti.self
        return VStack(alignment: .leading, spacing: 0) {
            TestataDossierApple(cliente: c, modifica: { modifica(c) })
                .entrataCascata(0, base: baseDossier)
            TessereDossierApple(clienteId: c.id, base: baseDossier)
                .padding(.top, k.Tessere.sopra)
            SchedeDossierApple(selezione: Bindable(stato).schedaCliente, cliente: c)
                .entrataCascata(k.Moto.indiceSchede, base: baseDossier)
                .padding(.top, k.Schede.sopra)
                .padding(.bottom, k.Schede.sotto)
            schedaCorrente(c, scheda: scheda)
        }
        .padding(k.Testata.paddingDossier)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .fondoSuperficie(superficie)
        .opacity(esceCliente ? 0 : 1)
        .offset(x: esceCliente ? Tema.Apple.Moto.CambioCliente.spostamento : 0)
    }

    /// Il contenuto della scheda: scorre dentro il dossier (tranne Documenti e Nel tempo); le schede di Prisma
    /// nella cornice del tema, come un solo blocco della cascata.
    private func schedaCorrente(_ c: Cliente, scheda: SchedaCliente) -> some View {
        Group {
            if scheda.scorreNelDossier {
                ScrollView(.vertical, showsIndicators: true) {
                    vistaScheda(c, scheda: scheda)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            } else {
                vistaScheda(c, scheda: scheda)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .environment(\.avvioCascataDossier, avvio)
        // Un'altra scheda: il contenuto si rifà ed entra a cascata
        .id(scheda)
        .opacity(esceScheda ? 0 : 1)
        .offset(y: esceScheda ? Tema.Apple.Moto.CambioScheda.spostamento : 0)
    }

    @ViewBuilder private func vistaScheda(_ c: Cliente, scheda: SchedaCliente) -> some View {
        if scheda.delTemplate {
            contenuto(scheda, c)
        } else {
            contenuto(scheda, c)
                .corniceSchedaDossier()
                .entrataDossier(0, sfocatura: false)
        }
    }

    // MARK: Cambi

    private func cambiaCliente(_ nuovo: String) {
        // «L'azienda» non c'è per un cliente senza azienda: si torna a «Panoramica» (riga 561 del template)
        if stato.schedaCliente == .azienda, stato.cliente(nuovo)?.elencoAziende.isEmpty ?? true {
            stato.schedaCliente = .panoramica
        }
        guard nuovo != clienteMostrato else {
            esceCliente = false
            return
        }
        let m = Tema.Apple.Clienti.Moto.self
        if istantanea || calmo {
            let mostra: () -> Void = {
                baseDossier = m.baseCambio
                avvio = AvvioCascataDossier(primoIndice: m.primoIndiceScheda, base: m.baseCambio)
                clienteMostrato = nuovo
                schedaMostrata = stato.schedaCliente
                esceCliente = false
                esceScheda = false
            }
            if istantanea {
                mostra()
            } else {
                withAnimation(Tema.Moto.dissolvenzaCalma) { mostra() }
            }
            return
        }
        withAnimation(Tema.Apple.Moto.CambioCliente.uscita) { esceCliente = true }
        Movimenti.dopo(Tema.Apple.Moto.CambioCliente.durataUscita) {
            // Un clic su un altro cliente nel frattempo: entra quello, con il suo giro
            guard stato.clienteAttivoId == nuovo else { return }
            baseDossier = m.baseCambio
            avvio = AvvioCascataDossier(primoIndice: m.primoIndiceScheda, base: m.baseCambio)
            clienteMostrato = nuovo
            schedaMostrata = stato.schedaCliente
            esceScheda = false
            esceCliente = false
        }
    }

    private func cambiaScheda(_ nuova: SchedaCliente) {
        guard nuova != schedaMostrata else {
            esceScheda = false
            return
        }
        let m = Tema.Apple.Clienti.Moto.self
        if istantanea || calmo {
            let mostra: () -> Void = {
                avvio = AvvioCascataDossier(primoIndice: 0, base: m.baseCambio)
                schedaMostrata = nuova
                esceScheda = false
            }
            if istantanea {
                mostra()
            } else {
                withAnimation(Tema.Moto.dissolvenzaCalma) { mostra() }
            }
            return
        }
        // Il dossier sta già uscendo per un altro cliente: la scheda nuova entra con lui
        guard !esceCliente else { return }
        withAnimation(Tema.Apple.Moto.CambioScheda.uscita) { esceScheda = true }
        Movimenti.dopo(Tema.Apple.Moto.CambioScheda.durataUscita) {
            guard stato.schedaCliente == nuova else { return }
            avvio = AvvioCascataDossier(primoIndice: 0, base: m.baseCambio)
            schedaMostrata = nuova
            esceScheda = false
        }
    }
}

// MARK: - Testata

/// Avatar 56, «Dossier personale» 11, nome 27 bold, motto · età · professione 13,5; a destra i canali, il
/// preferito, «Modifica», «Analisi 360» e «Prospetti» (primario). Se non sta su una riga, prima le etichette
/// dei canali diventano compatte e «Modifica» un'icona, poi i comandi scendono sotto il nome.
struct TestataDossierApple: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    let modifica: () -> Void

    var body: some View {
        let _ = ContaCorpi.segna()
        let t = Tema.Apple.Clienti.Testata.self
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: t.spazioAvatar) {
                identita
                Spacer(minLength: t.spazioComandi)
                comandi(compatti: false)
            }
            HStack(alignment: .center, spacing: t.spazioAvatar) {
                identita
                Spacer(minLength: t.spazioComandi)
                comandi(compatti: true)
            }
            VStack(alignment: .leading, spacing: t.spazioDueRighe) {
                HStack(alignment: .center, spacing: t.spazioAvatar) { identita }
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    comandi(compatti: true)
                }
            }
        }
    }

    @ViewBuilder private var identita: some View {
        let t = Tema.Apple.Clienti.Testata.self
        AvatarCliente(iniziali: cliente.iniziali, tinta: cliente.tinta.colori, lato: t.avatar)
        VStack(alignment: .leading, spacing: t.spazioRighe) {
            Text("Dossier personale")
                .carattereApple(t.occhiello)
                .foregroundColor(t.coloreOcchiello)
            Text(cliente.nome)
                .carattereApple(t.nome)
                .foregroundColor(t.coloreNome)
            if !sottotitolo.isEmpty {
                Text(sottotitolo)
                    .carattereApple(t.motto)
                    .foregroundColor(t.coloreMotto)
            }
        }
        .lineLimit(1)
    }

    /// «Una casa, un nuovo inizio. · 37 anni · Architetta»: le parti che ci sono.
    private var sottotitolo: String {
        let parti: [String] = [cliente.tema, cliente.eta.map { "\($0) anni" } ?? "", cliente.professione]
        return parti
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private func comandi(compatti: Bool) -> some View {
        let t = Tema.Apple.Clienti.Testata.self
        return HStack(spacing: t.spazioComandi) {
            ForEach(cliente.canali) { EtichettaCanaleApple(canale: $0, compatta: compatti) }
            // «Luce» giro 13 (§9.1.6): il cliente nato dalla carta d'identità non ha ancora un canale
            if cliente.canali.isEmpty { EtichettaCanaleDaScegliere() }
            stella
            if compatti {
                Button(action: modifica) { Image(systemName: "pencil") }
                    .buttonStyle(.apple)
                    .help("Modifica la scheda del cliente")
                    .accessibilityLabel("Modifica")
            } else {
                Button(action: modifica) { Label("Modifica", systemImage: "pencil") }
                    .buttonStyle(.apple)
            }
            Button("Analisi 360") { apri(.analisi360) }
                .buttonStyle(.apple)
            // Il report di fine anno per il cliente, in Prospetti
            if compatti {
                Button(action: apriAnnoInsieme) { Image(systemName: "calendar.badge.clock") }
                    .buttonStyle(.apple)
                    .help("\(TestiAnnoInsieme.titolo): il report dell'anno per il cliente")
                    .accessibilityLabel(TestiAnnoInsieme.titolo)
            } else {
                Button(TestiAnnoInsieme.titolo, action: apriAnnoInsieme)
                    .buttonStyle(.apple)
                    .help("Il report dell'anno per il cliente, in Prospetti")
            }
            Button("Prospetti") { apri(.presentazioni) }
                .buttonStyle(.applePrimario)
        }
        .fixedSize()
    }

    private var stella: some View {
        let t = Tema.Apple.Clienti.Testata.self
        let preferito = cliente.preferito
        return Button {
            stato.alternaPreferito(cliente.id)
        } label: {
            Text(preferito ? "★" : "☆")
                .carattereApple(t.stella)
                .foregroundColor(preferito ? t.coloreStellaPiena : t.coloreStellaVuota)
        }
        .buttonStyle(StileSemplice())
        .help(preferito ? "Togli dai preferiti" : "Aggiungi ai preferiti")
        .accessibilityLabel(preferito ? "Togli dai preferiti" : "Aggiungi ai preferiti")
    }

    private func apri(_ app: AppPrisma) {
        stato.clienteAttivoId = cliente.id
        stato.apri(app)
    }

    /// «Un anno insieme» del cliente, in Prospetti.
    private func apriAnnoInsieme() {
        stato.clienteAttivoId = cliente.id
        stato.apriProspetto(.annoInsieme)
    }
}

// MARK: - Tessere

/// Quattro tessere 258×76 con spazio 12: Patrimonio netto, Capitale assicurato, Premi annui, Proposte aperte
/// (numero e «· importo»). Le cifre vengono dal quadro delle posizioni (`RiepilogoPosizioni`, in cache in
/// DerivatiDati) e si contano fino al valore. Strette, vanno su due colonne.
struct TessereDossierApple: View {
    @Environment(StatoShell.self) var stato
    let clienteId: String
    var base: Double = Tema.Apple.Clienti.Moto.baseCambio

    var body: some View {
        let _ = ContaCorpi.segna()
        let r = stato.riepilogoPosizioniCliente(clienteId)
        let t = Tema.Apple.Clienti.Tessere.self
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: t.spazio) {
                ForEach(0..<4, id: \.self) { i in tessera(i, r) }
            }
            VStack(spacing: t.spazio) {
                HStack(spacing: t.spazio) {
                    tessera(0, r)
                    tessera(1, r)
                }
                HStack(spacing: t.spazio) {
                    tessera(2, r)
                    tessera(3, r)
                }
            }
            // Strettissime: una sotto l'altra, mai tagliate
            VStack(spacing: t.spazio) {
                ForEach(0..<4, id: \.self) { i in tessera(i, r) }
            }
        }
    }

    private static let titoli = ["Patrimonio netto", "Capitale assicurato", "Premi annui", "Proposte aperte"]

    private func tessera(_ i: Int, _ r: RiepilogoPosizioni) -> some View {
        let t = Tema.Apple.Clienti.Tessere.self
        return VStack(alignment: .leading, spacing: t.spazioEtichetta) {
            Text(Self.titoli[i])
                .carattereApple(t.etichetta)
                .foregroundColor(t.coloreEtichetta)
                .lineLimit(1)
            valore(i, r)
        }
        .padding(t.padding)
        .frame(minWidth: t.larghezzaMinima, maxWidth: .infinity, minHeight: t.altezza, alignment: .topLeading)
        .superficieApple(Tema.Apple.Superficie.tile)
        .entrataCascata(Tema.Apple.Clienti.Moto.indiceTessere + i, base: base)
    }

    @ViewBuilder private func valore(_ i: Int, _ r: RiepilogoPosizioni) -> some View {
        let t = Tema.Apple.Clienti.Tessere.self
        switch i {
        case 0:
            cifra(NumeroCheConta(r.patrimonioNetto, indice: 0))
        case 1:
            cifra(NumeroCheConta(r.capitaleAssicurato, indice: 1))
        case 2:
            cifra(NumeroCheConta(r.premiAnnui, indice: 2))
        default:
            HStack(alignment: .firstTextBaseline, spacing: t.spazioImporto) {
                cifra(NumeroCheConta(Double(r.proposteAperte), formato: .intero, indice: 3))
                if r.proposteAperte > 0 {
                    Text("· " + FormatoCifra.euro.testo(r.valoreProposte))
                        .carattereApple(t.importoProposte)
                        .foregroundColor(t.coloreImportoProposte)
                        .lineLimit(1)
                }
            }
        }
    }

    private func cifra(_ n: NumeroCheConta) -> some View {
        let t = Tema.Apple.Clienti.Tessere.self
        return n
            .carattereApple(t.valore)
            .foregroundColor(t.coloreValore)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

// MARK: - Schede

/// Il segmentato a pillola con le quattro schede del template e, accanto, «Altro ▾» con le schede di Prisma.
/// Quando è aperta una scheda di Prisma, la pillola del segmentato sparisce e «Altro» ne prende il nome, sulla
/// pillola bianca.
struct SchedeDossierApple: View {
    @Binding var selezione: SchedaCliente
    /// Il cliente del dossier: decide se «L'azienda» sta nel segmentato o in «Altro».
    var cliente: Cliente? = nil

    var body: some View {
        HStack(spacing: Tema.Apple.Clienti.Schede.spazioAltro) {
            SegmentatoPillola(selezione: $selezione, valori: SchedaCliente.delSegmentato(per: cliente), titolo: { $0.titolo })
            AltroSchedeDossier(selezione: $selezione, voci: SchedaCliente.dellAltro(per: cliente))
        }
    }
}

/// «Altro ▾»: la capsula `chip` come il segmentato; il clic apre il menu delle schede di Prisma (sul Mac il menu
/// del sistema con la scheda aperta spuntata, su iPad un `Menu`).
struct AltroSchedeDossier: View {
    @Binding var selezione: SchedaCliente
    var voci: [SchedaCliente] = SchedaCliente.dellAltro

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    /// La scheda di Prisma aperta (nil se è aperta una del template).
    private var scelta: SchedaCliente? {
        voci.contains(selezione) ? selezione : nil
    }

    var body: some View {
        #if os(macOS)
        Button(action: apri) { capsula }
            .buttonStyle(StileSemplice())
            .help("Le altre schede del dossier")
            .accessibilityLabel(scelta.map { "Altre schede, \($0.titoloAltro)" } ?? "Altre schede")
        #elseif os(iOS)
        Menu {
            Picker(selection: $selezione) {
                ForEach(voci, id: \.self) { s in
                    Text(verbatim: s.titoloAltro).tag(s)
                }
            } label: {
                Text("Altre schede")
            }
            .pickerStyle(.inline)
        } label: {
            capsula
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel(scelta.map { "Altre schede, \($0.titoloAltro)" } ?? "Altre schede")
        #endif
    }

    private var capsula: some View {
        let s = Tema.Apple.Clienti.Schede.self
        let attiva = scelta != nil
        return HStack(spacing: s.spazioFreccia) {
            Text(scelta?.titoloAltro ?? "Altro")
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(s.freccia.font)
        }
        .carattereApple(Tema.Apple.Carattere.barra)
        .foregroundColor(attiva ? Tema.Apple.Colore.inchiostro : Tema.Apple.Colore.inchiostro2)
        .padding(Tema.Apple.Misura.Padding.voceSegmentato)
        .background {
            if attiva {
                Capsule(style: .continuous)
                    .fill(Tema.Apple.Colore.cardPiena)
                    .ombraApple(.pillola)
            }
        }
        .padding(Tema.Apple.Misura.Padding.segmentato)
        .background { Capsule(style: .continuous).fill(Tema.Apple.Colore.chip) }
        .contentShape(Capsule(style: .continuous))
        .animation(animazione, value: attiva)
    }

    private var animazione: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Moto.Segmentato.animazione, calmo: calmo, istantanea: istantanea)
    }

    #if os(macOS)
    /// Il menu del Mac: modale finché non si sceglie, quindi il bersaglio delle voci vive abbastanza.
    private func apri() {
        let voci = self.voci
        let menu = NSMenu()
        let bersaglio = BersaglioMenuAltro { i in
            if i >= 0, i < voci.count { selezione = voci[i] }
        }
        for (i, v) in voci.enumerated() {
            let voce = NSMenuItem(title: v.titoloAltro, action: #selector(BersaglioMenuAltro.scegli(_:)), keyEquivalent: "")
            voce.target = bersaglio
            voce.tag = i
            voce.state = v == selezione ? .on : .off
            menu.addItem(voce)
        }
        _ = withExtendedLifetime(bersaglio) {
            menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        }
    }
    #endif
}

#if os(macOS)
private final class BersaglioMenuAltro: NSObject {
    let scelto: (Int) -> Void
    init(_ scelto: @escaping (Int) -> Void) { self.scelto = scelto }
    @objc func scegli(_ voce: NSMenuItem) { scelto(voce.tag) }
}
#endif

/// «Canale da scegliere»: l'etichetta grigia del cliente senza canale («Luce» giro 13, §9.1.6). La scheda della carta
/// d'identità non sceglie il canale: lo indica l'utente nella scheda del cliente.
struct EtichettaCanaleDaScegliere: View {
    var body: some View {
        let s = Tema.Apple.NuovoCliente.Scheda.self
        Text("Canale da scegliere")
            .carattereApple(s.canaleDaScegliere)
            .foregroundColor(s.coloreCanaleDaScegliere)
            .padding(s.paddingCanaleDaScegliere)
            .background(Capsule().fill(s.fondoCanaleDaScegliere))
            .help("Indica il canale (Alleanza, indipendente o entrambi) nella scheda del cliente")
    }
}
