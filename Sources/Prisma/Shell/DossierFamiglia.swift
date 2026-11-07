import SwiftUI

/// Apre il modulo di un familiare (nuovo o da modificare). Lo fornisce AppClienti, che tiene il foglio del modulo:
///
///     @Environment(\.azioneFamiliareDossier) private var familiare
///     Button("Modifica") { familiare?.apri(ModificaFamiliare(clienteId: c.id, familiare: f, nuovo: false)) }
struct AzioneFamiliareDossier {
    let apri: (ModificaFamiliare) -> Void

    func callAsFunction(_ modifica: ModificaFamiliare) { apri(modifica) }
}

private struct ChiaveAzioneFamiliareDossier: EnvironmentKey {
    static let defaultValue: AzioneFamiliareDossier? = nil
}

extension EnvironmentValues {
    /// Il modulo del familiare del dossier (nil fuori da Clienti).
    var azioneFamiliareDossier: AzioneFamiliareDossier? {
        get { self[ChiaveAzioneFamiliareDossier.self] }
        set { self[ChiaveAzioneFamiliareDossier.self] = newValue }
    }
}

// Scheda «Famiglia» del dossier nel tema Apple (Design/template-apple-specifica.md §4.2.5, PC C19-C21): griglia di
// `max(2, familiari + 1)` card (al massimo 4 colonne), il titolare con l'avatar 70 visibile e centrato (nel template
// manca, §4.9), i familiari inclinabili di 6° con la relazione e l'età. Sotto ogni persona le capsule delle scoperture
// (12 semibold, padding 4×10, testo nel tono e fondo nel tono al 12%): chi non è protetto, i beneficiari da indicare o
// da aggiornare, la successione da sistemare; ognuna porta alla scheda dove si risolve. Le cifre vengono dai motori
// della protezione della famiglia e del passaggio generazionale (`MotoreFamigliaDossier`).
// Restano di Prisma: «Modifica» sul familiare, il posto «Aggiungi un familiare» e i dati per l'analisi (reddito,
// sostegno, pensione stimata). Senza familiari: «Nessun familiare nel dossier.».
// Valori in DesignSystem/Apple/Tema.Apple+NelTempoFamiglia.swift.

struct FamigliaDossier: View {
    let cliente: Cliente
    @EnvironmentObject var stato: StatoShell
    @Environment(\.azioneFamiliareDossier) private var azione

    var body: some View {
        let f = Tema.Apple.Clienti.Famiglia.self
        let persone = personeCliente
        let colonne = min(max(f.colonneMinime, persone.count), f.colonneMassime)
        // Il posto per un nuovo familiare entra nella griglia se l'ultima riga ha spazio, altrimenti va sotto
        let postoInGriglia = puoModificare && persone.count % colonne != 0
        let griglia = Array(repeating: GridItem(.flexible(), spacing: f.spazio, alignment: .top), count: colonne)
        return VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(columns: griglia, alignment: .leading, spacing: f.spazio) {
                ForEach(Array(persone.enumerated()), id: \.element.id) { i, p in
                    SchedaPersonaFamiglia(persona: p, tinta: Self.tinta(cliente, indice: i), modifica: modifica(p))
                        .entrataDossier(i)
                }
                if postoInGriglia {
                    SchedaAggiungiFamiliare(azione: aggiungi)
                        .entrataDossier(persone.count)
                }
            }
            if cliente.famiglia.isEmpty {
                Text("Nessun familiare nel dossier.")
                    .carattereApple(f.vuoto)
                    .foregroundColor(f.coloreVuoto)
                    .padding(.top, f.sopraVuoto)
                    .entrataDossier(persone.count + 1)
            }
            if puoModificare, !postoInGriglia {
                Button(action: aggiungi) {
                    Label("Aggiungi un familiare", systemImage: "plus")
                }
                .buttonStyle(.apple)
                .padding(.top, f.sopraVuoto)
                .entrataDossier(persone.count + 1)
            }
            Text("Le capsule vengono dalla protezione persona per persona dell'Analisi 360 e dal passaggio generazionale di Posizioni: toccale per aprire la scheda dove si sistemano.")
                .carattereApple(f.fonte)
                .foregroundColor(f.coloreFonte)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, f.sopraFonte)
                .entrataDossier(persone.count + 2)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .environment(\.apriScoperturaFamiglia, ApriScoperturaFamiglia(apri: apri))
    }

    /// Le persone con le scoperture: protezione persona per persona e passaggio generazionale (in cache nel dossier).
    private var personeCliente: [PersonaFamiglia] {
        let id = cliente.id
        let posizioni = stato.posizioniCliente(id)
        let protezione = CacheFamigliaDossier.protezione(cliente: cliente, posizioni: posizioni,
                                                         ipotesi: stato.analisi360(id).protezione)
        return MotoreFamigliaDossier.persone(cliente: cliente, protezione: protezione,
                                             successione: stato.analisiDossier(id).successione)
    }

    /// In sola lettura (e in modalità cliente) il nucleo non si modifica.
    private var puoModificare: Bool {
        azione != nil && !stato.solaLettura && !stato.inModoCliente
    }

    private func modifica(_ p: PersonaFamiglia) -> (() -> Void)? {
        guard puoModificare, let f = p.familiare else { return nil }
        let id = cliente.id
        let azione = self.azione
        return { azione?.apri(ModificaFamiliare(clienteId: id, familiare: f, nuovo: false)) }
    }

    private func aggiungi() {
        azione?.apri(ModificaFamiliare(clienteId: cliente.id, familiare: Familiare(nome: "", relazione: .coniuge), nuovo: true))
    }

    /// Porta alla scheda dove si risolve la scopertura.
    private func apri(_ d: ScoperturaFamiglia.Destinazione) {
        let id = cliente.id
        switch d {
        case .protezione:
            stato.clienteAttivoId = id
            stato.areaAnalisi = .protezione
            stato.apri(.analisi360)
        case .successione:
            stato.clienteAttivoId = id
            stato.portafoglio = false
            stato.posizioneInDettaglio = nil
            stato.ancoraPosizioni = "successione"
            stato.apri(.posizioni)
        case .posizione(let pid):
            if let p = stato.posizioniCliente(id).first(where: { $0.id == pid }) { stato.apriPosizione(p) }
        }
    }

    /// Il titolare con la sua tinta; i familiari con le altre, a giro.
    static func tinta(_ c: Cliente, indice: Int) -> Colori.Avatar.Tinta {
        let tinte: [TintaAvatar] = [.blu, .rosa, .verde, .viola, .oro]
        let partenza = tinte.firstIndex(of: c.tinta) ?? 0
        return tinte[(partenza + indice) % tinte.count].colori
    }

    /// I dati del familiare per la protezione per persona e la pensione: reddito netto, sostegno, pensione stimata
    /// con il contributivo (una stima). nil se non c'è niente di indicato.
    static func datiAnalisi(_ f: Familiare) -> String? {
        var parti: [String] = []
        if let r = f.redditoNettoAnnuo, r > 0 { parti.append("reddito netto \(Formati.euro(r)) l'anno") }
        if f.nonAutosufficiente == true {
            parti.append("non autosufficiente: sostegno per tutta la vita")
        } else if let fine = f.etaFineCarico {
            parti.append("a carico fino a \(fine) anni")
        } else if f.aCarico {
            parti.append("a carico")
        }
        if let s = MotorePensionePubblica.stima(familiare: f) {
            parti.append("pensione stimata circa \(Formati.euro(s.nettaMensile)) netti al mese a \(s.etaPensione) anni (stima contributiva)")
        }
        let nota = f.nota.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nota.isEmpty { parti.append(nota) }
        return parti.isEmpty ? nil : parti.joined(separator: " · ")
    }
}

// MARK: - Dove porta una scopertura

/// Chi apre la scheda di una scopertura (lo mette `FamigliaDossier` per le sue card).
struct ApriScoperturaFamiglia {
    let apri: (ScoperturaFamiglia.Destinazione) -> Void
}

private struct ChiaveApriScoperturaFamiglia: EnvironmentKey {
    static let defaultValue: ApriScoperturaFamiglia? = nil
}

extension EnvironmentValues {
    var apriScoperturaFamiglia: ApriScoperturaFamiglia? {
        get { self[ChiaveApriScoperturaFamiglia.self] }
        set { self[ChiaveApriScoperturaFamiglia.self] = newValue }
    }
}

// MARK: - Card di una persona

/// Una persona: avatar 70 centrato, nome 19 bold, «Coniuge · 43 anni», i dati per l'analisi e le capsule.
/// I familiari si inclinano di 6° verso il puntatore; il titolare resta fermo, come nel template.
struct SchedaPersonaFamiglia: View {
    let persona: PersonaFamiglia
    let tinta: Colori.Avatar.Tinta
    /// «Modifica» del familiare (nil per il titolare, in sola lettura e in modalità cliente).
    let modifica: (() -> Void)?

    var body: some View {
        let f = Tema.Apple.Clienti.Famiglia.self
        let contenuto = VStack(spacing: 0) {
            AvatarCliente(iniziali: persona.iniziali, tinta: tinta, lato: f.avatar)
            Text(persona.nome)
                .carattereApple(f.nome)
                .foregroundColor(f.coloreNome)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.top, f.sopraNome)
            Text(persona.descrizione)
                .carattereApple(f.descrizione)
                .foregroundColor(f.coloreDescrizione)
                .lineLimit(2)
                .padding(.top, f.spazioNomeDescrizione)
            if let dati = persona.familiare.flatMap(FamigliaDossier.datiAnalisi) {
                Text(dati)
                    .carattereApple(f.descrizione)
                    .foregroundColor(f.coloreFonte)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, f.spazioNomeDescrizione)
            }
            if !persona.scoperture.isEmpty {
                VStack(spacing: f.fraCapsule) {
                    ForEach(persona.scoperture) { s in
                        CapsulaScopertura(scopertura: s)
                    }
                }
                .padding(.top, f.sopraCapsule)
            }
            Spacer(minLength: 0)
            if let modifica {
                Button("Modifica", action: modifica)
                    .buttonStyle(.appleSobrio)
                    .padding(.top, f.sopraModifica)
            }
        }
        .multilineTextAlignment(.center)
        .padding(f.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .superficieApple(f.superficie)
        .accessibilityElement(children: .contain)

        if persona.titolare {
            contenuto
        } else {
            contenuto.inclinazione(massimo: f.inclinazione, raggio: f.raggio)
        }
    }
}

/// La capsula di una scopertura: testo nel tono, fondo nel tono al 12%; porta alla scheda dove si risolve.
struct CapsulaScopertura: View {
    let scopertura: ScoperturaFamiglia
    @Environment(\.apriScoperturaFamiglia) private var apri

    var body: some View {
        let f = Tema.Apple.Clienti.Famiglia.self
        let tono = colore
        return Button {
            apri?.apri(scopertura.destinazione)
        } label: {
            HStack(spacing: f.spazioFreccia) {
                Text(scopertura.testo)
                    .lineLimit(1)
                Text("›")
            }
            // Larghezza naturale: tutte le capsule allo stesso carattere, mai rimpicciolite
            .fixedSize(horizontal: true, vertical: false)
            .carattereApple(f.capsula)
            .foregroundColor(tono)
            .padding(f.paddingCapsula)
            .background { Capsule(style: .continuous).fill(tono.opacity(f.opacitaFondoCapsula)) }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(StileSemplice())
        .help(scopertura.aiuto)
        .accessibilityLabel(Text(scopertura.testo))
        .accessibilityHint(Text(scopertura.aiuto))
    }

    private var colore: Color {
        let f = Tema.Apple.Clienti.Famiglia.self
        switch scopertura.tono {
        case .rosso: return f.rosso
        case .arancio: return f.arancio
        case .verde: return f.verde
        }
    }
}

/// Il posto per un nuovo familiare: card tratteggiata senza fondo con «＋ Aggiungi un familiare».
struct SchedaAggiungiFamiliare: View {
    let azione: () -> Void

    var body: some View {
        let f = Tema.Apple.Clienti.Famiglia.self
        let forma = RoundedRectangle(cornerRadius: f.raggio, style: .continuous)
        return Button(action: azione) {
            VStack(spacing: f.spazioNuovo) {
                Text("＋")
                    .carattereApple(f.segnoNuovo)
                Text("Aggiungi un familiare")
                    .carattereApple(f.testoNuovo)
            }
            .foregroundColor(f.coloreNuovo)
            .padding(f.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                forma.strokeBorder(f.bordoNuovo, style: StrokeStyle(lineWidth: f.spessoreNuovo, dash: f.tratteggioNuovo))
            }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .help("Apre il modulo del nuovo familiare")
    }
}

// MARK: - Cache della protezione

/// La protezione della famiglia del cliente già calcolata (persona per persona): si rifà quando cambiano cliente,
/// posizioni, ipotesi o giorno. Solo dal thread principale (le viste).
enum CacheFamigliaDossier {
    nonisolated(unsafe) private static var memoria: (chiave: Int, ipotesi: IpotesiProtezione, valore: EsitoProtezioneFamiglia)?

    static func protezione(cliente: Cliente, posizioni: [Posizione], ipotesi: IpotesiProtezione) -> EsitoProtezioneFamiglia {
        var h = Hasher()
        h.combine(cliente)
        h.combine(posizioni)
        h.combine(Calendar.current.startOfDay(for: Date()))
        let chiave = h.finalize()
        if let m = memoria, m.chiave == chiave, m.ipotesi == ipotesi { return m.valore }
        let valore = MotoreProtezioneFamiglia.calcola(posizioni, cliente: cliente, analisi: ipotesi)
        memoria = (chiave, ipotesi, valore)
        return valore
    }
}
