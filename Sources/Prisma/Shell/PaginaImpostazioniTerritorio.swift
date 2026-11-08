import SwiftUI

// Impostazioni › Territorio («Luce» giro 11, §5.1.3, decisioni 22, 70, 99, 127): la stima delle distanze (fattore strada,
// velocità, minuti minimi: sono stime in linea d'aria, Prisma non usa servizi di percorso), il giro (deviazione massima,
// visita breve), da dove parti (sede dello studio, un comune dell'elenco o la posizione a mano), le zone dell'utente
// (gruppi di comuni), le attenzioni che accendono l'anello arancio (nessuna di base) e la fonte delle mappe (ISTAT, CC BY
// 4.0, oppure la tabella di prova). Su iPhone e iPad si leggono soltanto: non sono campi sincronizzati.

struct PaginaImpostazioniTerritorio: View {
    @Environment(StatoShell.self) var stato
    @State private var sceltaComuni: SceltaComuniTerritorio?

    private typealias Riga = Tema.Apple.Impostazioni.Riga

    var body: some View {
        let _ = ContaCorpi.segna()
        let t = stato.dati.impostazioni.territorio
        let tabella = stato.territorio.tabella
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Pagina.spazioGruppi) {
            NotaImpostazioni("Territorio mette i clienti sulla mappa con il comune dell'indirizzo o con la posizione che metti a "
                             + "mano. Prisma non usa servizi di mappe o di percorso: distanze e tempi sono stime in linea d'aria.")
            VStack(alignment: .leading, spacing: Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Stima delle distanze") {
                    RigaImpostazione(titolo: "Fattore strada", sottotitolo: "La linea d'aria per questo numero: i km stimati") {
                        sceltaNumero(t.fattoreStrada, [1.1, 1.2, 1.3, 1.4, 1.5, 1.7, 2.0], testo: { String(format: "× %.1f", $0) }) { v in
                            stato.impostaTerritorio { $0.fattoreStrada = v }
                        }
                    }
                    RigaImpostazione(titolo: "Velocità nello stesso comune", sottotitolo: "Media stimata in città") {
                        sceltaNumero(t.velocitaCitta, [20, 30, 40, 50, 60], testo: { "\(Int($0)) km/h" }) { v in
                            stato.impostaTerritorio { $0.velocitaCitta = v }
                        }
                    }
                    RigaImpostazione(titolo: "Velocità fra comuni", sottotitolo: "Media stimata fuori città") {
                        sceltaNumero(t.velocitaFuori, [50, 60, 70, 80, 90, 100], testo: { "\(Int($0)) km/h" }) { v in
                            stato.impostaTerritorio { $0.velocitaFuori = v }
                        }
                    }
                    RigaImpostazione(titolo: "Minuti minimi di un tratto", sottotitolo: "Parcheggio e uscita compresi", ultima: true) {
                        sceltaIntero(t.minutiMinimiTratto, [0, 3, 5, 10, 15], testo: { "\($0) min" }) { v in
                            stato.impostaTerritorio { $0.minutiMinimiTratto = v }
                        }
                    }
                }
                NotaImpostazioni("Prisma non usa servizi di percorso: sono stime in linea d'aria. I km di Studio › Spese restano "
                                 + "quelli che scrivi tu.")
            }
            .cascataImpostazioni(1)
            GruppoImpostazioni(titolo: "Il giro") {
                RigaImpostazione(titolo: "Deviazione massima", sottotitolo: "Per proporre un cliente «lungo la strada»") {
                    sceltaIntero(t.deviazioneMassima, [5, 10, 15, 20, 30], testo: { "\($0) min" }) { v in
                        stato.impostaTerritorio { $0.deviazioneMassima = v }
                    }
                }
                RigaImpostazione(titolo: "Visita breve", sottotitolo: "La durata dell'appuntamento proposto dal Territorio", ultima: true) {
                    sceltaIntero(t.durataVisitaBreve, [15, 20, 30, 45, 60], testo: { "\($0) min" }) { v in
                        stato.impostaTerritorio { $0.durataVisitaBreve = v }
                    }
                }
            }
            .cascataImpostazioni(2)
            GruppoImpostazioni(titolo: "Da dove parti") {
                RigaImpostazione(titolo: "Partenza del giro", sottotitolo: descrizionePartenza(t, tabella)) {
                    HStack(spacing: Riga.spazioControllo / 2) {
                        Button("Scegli il comune") {
                            sceltaComuni = SceltaComuniTerritorio(zonaId: nil, scelti: Set([t.comunePartenza].compactMap { $0 }))
                        }
                        .buttonStyle(.apple)
                        .disabled(tabella == nil || stato.solaLettura)
                        Button("Mettila a mano") { stato.apriTerritorioSpostaPartenza() }
                            .buttonStyle(.apple)
                            .disabled(stato.solaLettura)
                    }
                    .fixedSize()
                }
                RigaImpostazione(titolo: "Torna alla sede dello studio",
                                 sottotitolo: "La sede si scrive in Impostazioni › Studio › Fatturazione", ultima: true) {
                    Button("Togli") {
                        stato.impostaTerritorio {
                            $0.partenza = nil
                            $0.comunePartenza = nil
                        }
                    }
                    .buttonStyle(.appleSobrio)
                    .disabled(stato.solaLettura || (t.partenza == nil && t.comunePartenza == nil))
                }
            }
            .cascataImpostazioni(3)
            GruppoImpostazioni(titolo: "Le tue zone") {
                if t.zone.isEmpty {
                    RigaImpostazione(titolo: "Le zone sono i comuni", sottotitolo: "Puoi raggruppare più comuni in una zona tua",
                                     ultima: true) {
                        bottoneAggiungiZona
                    }
                }
                ForEach(Array(t.zone.enumerated()), id: \.element.id) { i, z in
                    RigaImpostazione(titolo: z.nome.isEmpty ? "Zona senza nome" : z.nome, sottotitolo: comuniDi(z, tabella),
                                     ultima: i == t.zone.count - 1) {
                        HStack(spacing: Riga.spazioControllo / 2) {
                            TextField("Nome", text: Binding(get: { z.nome }, set: { nome in
                                stato.impostaTerritorio { imp in
                                    if let k = imp.zone.firstIndex(where: { $0.id == z.id }) { imp.zone[k].nome = nome }
                                }
                            }))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: Tema.Apple.Studio.Impostazioni.campoImporto)
                            Button("Comuni") { sceltaComuni = SceltaComuniTerritorio(zonaId: z.id, scelti: Set(z.comuni)) }
                                .buttonStyle(.apple)
                                .disabled(tabella == nil)
                            Button("Togli") {
                                stato.impostaTerritorio { imp in imp.zone.removeAll { $0.id == z.id } }
                            }
                            .buttonStyle(.appleSobrio)
                            if i == t.zone.count - 1 { bottoneAggiungiZona }
                        }
                        .fixedSize()
                        .disabled(stato.solaLettura)
                    }
                }
            }
            .cascataImpostazioni(4)
            GruppoImpostazioni(titolo: "L'anello arancio") {
                ForEach(Array(Attenzione.Tipo.allCases.enumerated()), id: \.element.rawValue) { i, tipo in
                    RigaImpostazione(titolo: "Attenzione: \(tipo.nome.lowercased())",
                                     sottotitolo: "Accende l'anello come le cose da fare del mese",
                                     ultima: i == Attenzione.Tipo.allCases.count - 1) {
                        Toggle(isOn: Binding(get: { t.attenzioniAlte.contains(tipo.rawValue) }, set: { acceso in
                            stato.impostaTerritorio { imp in
                                imp.attenzioniAlte.removeAll { $0 == tipo.rawValue }
                                if acceso { imp.attenzioniAlte.append(tipo.rawValue) }
                            }
                        })) { EmptyView() }
                        .toggleStyle(.appleSenzaEtichetta)
                        .disabled(stato.solaLettura)
                    }
                }
            }
            .cascataImpostazioni(5)
            VStack(alignment: .leading, spacing: Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Fonte delle mappe") {
                    RigaImpostazione(titolo: fonte(tabella), sottotitolo: "Niente CAP e niente indirizzi in rete: la posizione è quella del comune o quella che metti a mano.",
                                     ultima: true) {
                        if tabella?.diProva ?? false { EtichettaDatiDiProvaPratiche() }
                    }
                }
            }
            .cascataImpostazioni(6)
        }
        .onAppear { stato.territorio.caricaSeServe() }
        .sheet(item: $sceltaComuni) { s in
            FoglioComuniTerritorio(scelta: s, tabella: tabella) { codici in
                if let id = s.zonaId {
                    stato.impostaTerritorio { imp in
                        if let k = imp.zone.firstIndex(where: { $0.id == id }) { imp.zone[k].comuni = codici.sorted() }
                    }
                } else {
                    stato.impostaTerritorio { imp in
                        imp.comunePartenza = codici.first
                        imp.partenza = nil
                    }
                }
                sceltaComuni = nil
            } annulla: {
                sceltaComuni = nil
            }
        }
    }

    private var bottoneAggiungiZona: some View {
        Button("Aggiungi una zona") {
            stato.impostaTerritorio { imp in
                imp.zone.append(ZonaTerritorio(id: "zona-\(UUID().uuidString.prefix(8).lowercased())", nome: "Zona nuova", comuni: []))
            }
        }
        .buttonStyle(.apple)
        .disabled(stato.solaLettura)
    }

    private func sceltaNumero(_ valore: Double, _ scelte: [Double], testo: @escaping (Double) -> String,
                              imposta: @escaping (Double) -> Void) -> some View {
        let tutte = Array(Set(scelte + [valore])).sorted()
        return Picker("", selection: Binding(get: { valore }, set: imposta)) {
            ForEach(tutte, id: \.self) { v in Text(testo(v)).tag(v) }
        }
        .labelsHidden()
        .fixedSize()
        .disabled(stato.solaLettura)
    }

    private func sceltaIntero(_ valore: Int, _ scelte: [Int], testo: @escaping (Int) -> String,
                              imposta: @escaping (Int) -> Void) -> some View {
        let tutte = Array(Set(scelte + [valore])).sorted()
        return Picker("", selection: Binding(get: { valore }, set: imposta)) {
            ForEach(tutte, id: \.self) { v in Text(testo(v)).tag(v) }
        }
        .labelsHidden()
        .fixedSize()
        .disabled(stato.solaLettura)
    }

    private func descrizionePartenza(_ t: ImpostazioniTerritorio, _ tabella: TabellaComuni?) -> String {
        if let p = stato.partenzaTerritorio() { return p.descrizione }
        if tabella == nil { return "La tabella dei comuni si legge all'apertura" }
        return "Nessuna: il giro parte dalla prima visita"
    }

    private func comuniDi(_ z: ZonaTerritorio, _ tabella: TabellaComuni?) -> String {
        guard !z.comuni.isEmpty else { return "Nessun comune scelto" }
        let nomi = z.comuni.map { tabella?.perCodice[$0]?.nome ?? $0 }
        return nomi.joined(separator: ", ")
    }

    private func fonte(_ tabella: TabellaComuni?) -> String {
        guard let t = tabella else { return "Comuni e confini: ISTAT, licenza CC BY 4.0" }
        if t.diProva {
            return "Dati di prova: \(t.comuni.count) comuni con confini semplificati. La tabella ISTAT completa arriva con un prossimo aggiornamento."
        }
        return "Comuni e confini: ISTAT, \(t.edizione), licenza \(t.licenza.isEmpty ? "CC BY 4.0" : t.licenza)"
    }
}

/// Cosa si sta scegliendo nel foglio dei comuni: i comuni di una zona (più di uno) o il comune della partenza (uno).
struct SceltaComuniTerritorio: Identifiable {
    let zonaId: String?
    let scelti: Set<String>
    var id: String { zonaId ?? "partenza" }
}

/// Il foglio con l'elenco dei comuni della tabella, con la ricerca (la tabella ISTAT ne ha quasi 8.000).
private struct FoglioComuniTerritorio: View {
    let scelta: SceltaComuniTerritorio
    let tabella: TabellaComuni?
    let conferma: (Set<String>) -> Void
    let annulla: () -> Void

    @State private var cerca = ""
    @State private var scelti: Set<String> = []

    private typealias P = Tema.Apple.Territorio.Pannello
    private static let massimiMostrati = 200

    var body: some View {
        let multipla = scelta.zonaId != nil
        let chiave = TabellaTerritorio.normalizza(cerca)
        let comuni = (tabella?.comuni ?? [])
            .filter { chiave.isEmpty || TabellaTerritorio.normalizza($0.nome).contains(chiave) }
            .sorted { $0.nome.localizedCompare($1.nome) == .orderedAscending }
        VStack(alignment: .leading, spacing: P.spazioSezione) {
            Text(multipla ? "I comuni della zona" : "Il comune da cui parti")
                .carattereApple(P.titoloGiro)
                .foregroundColor(P.coloreTesto)
            TextField("Cerca un comune", text: $cerca)
                .textFieldStyle(.roundedBorder)
            ScrollView {
                VStack(alignment: .leading, spacing: P.spazio / 2) {
                    ForEach(comuni.prefix(Self.massimiMostrati), id: \.codice) { c in
                        Button {
                            if multipla {
                                if scelti.contains(c.codice) { scelti.remove(c.codice) } else { scelti.insert(c.codice) }
                            } else {
                                scelti = [c.codice]
                            }
                        } label: {
                            HStack {
                                Text("\(c.nome) (\(c.provincia))").carattereApple(P.testo).foregroundColor(P.coloreTesto)
                                Spacer()
                                if scelti.contains(c.codice) {
                                    Text("✓").carattereApple(P.testoForte).foregroundColor(Tema.Apple.Colore.accento)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    if comuni.count > Self.massimiMostrati {
                        Text("Altri \(comuni.count - Self.massimiMostrati) comuni: scrivi qualche lettera in più.")
                            .carattereApple(P.piccolo)
                            .foregroundColor(P.coloreTesto2)
                    }
                }
            }
            HStack {
                Spacer()
                Button("Annulla", action: annulla)
                    .buttonStyle(.apple)
                    .keyboardShortcut(.cancelAction)
                Button("Fatto") { conferma(scelti) }
                    .buttonStyle(.applePrimario)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!multipla && scelti.isEmpty)
            }
        }
        .padding(P.padding)
        .frame(minWidth: P.larghezza + P.larghezza / 2, minHeight: P.larghezza + P.larghezza / 2)
        .onAppear { scelti = scelta.scelti }
    }
}
