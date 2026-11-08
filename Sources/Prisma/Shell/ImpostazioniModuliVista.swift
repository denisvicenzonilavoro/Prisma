import SwiftUI

// Impostazioni › Moduli (Design/template-luce-specifica.md §7.2.5 punto 8, «Luce» giro 10): i modelli di modulo caricati
// in Pratiche › Moduli con tipo, canale, pagine, caselle e versione, la revisione della mappa e «Togli»; l'interruttore
// «Conserva l'IBAN nel dossier» (decisione 40), spento di base: spegnendolo si tolgono gli IBAN già salvati, dopo una
// conferma. I moduli Alleanza non si caricano finché la compagnia non lo approva (decisione 60).

struct PaginaImpostazioniModuli: View {
    @Environment(StatoShell.self) var stato
    @State private var confermaSpegni = false
    @State private var daTogliere: ModelloModulo?

    private typealias Riga = Tema.Apple.Impostazioni.Riga
    private typealias M = Tema.Apple.Pratiche.Moduli

    var body: some View {
        let _ = ContaCorpi.segna()
        let modelli = stato.moduli.tutti
        let conIban = stato.clientiConIban
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Pagina.spazioGruppi) {
            NotaImpostazioni("I moduli che usi, caricati da te in Pratiche › Moduli: Prisma ne riconosce i campi e li "
                             + "compila con i dati del dossier. Restano sul Mac, entrano nei backup e non vanno su iPhone e iPad.")
            VStack(alignment: .leading, spacing: Riga.fraRighe) {
                GruppoImpostazioni(titolo: "I tuoi moduli") {
                    if modelli.isEmpty {
                        RigaImpostazione(titolo: "Moduli da preparare",
                                         sottotitolo: "Carica i PDF veri che usi per il canale indipendente", ultima: true) {
                            Button("Apri Pratiche › Moduli") { stato.apriPratiche(.moduli) }
                                .buttonStyle(.apple)
                        }
                    }
                    ForEach(Array(modelli.enumerated()), id: \.element.id) { i, m in
                        RigaImpostazione(titolo: m.titolo, sottotitolo: dettaglio(m),
                                         avvertenza: m.mappaConfermata ? nil : "La mappa dei campi è ancora da controllare",
                                         ultima: i == modelli.count - 1) {
                            HStack(spacing: M.spazioRighe) {
                                if m.diProva == true { EtichettaDatiDiProvaPratiche() }
                                EtichettaCanale(canale: m.canale ?? .indipendente, compatta: true)
                                Button("Rivedi la mappa") { stato.avviaRevisioneModulo(m.id) }
                                    .buttonStyle(.apple)
                                Button("Togli") { daTogliere = m }
                                    .buttonStyle(.appleSobrio)
                                    .disabled(stato.solaLettura)
                            }
                            .fixedSize()
                        }
                    }
                }
                NotaImpostazioni("Moduli Alleanza: non ancora. Finché la compagnia non conferma che i suoi moduli si possono "
                                 + "compilare fuori dai suoi strumenti, le proposte Alleanza si fanno con quelli.")
            }
            .cascataImpostazioni(1)
            VStack(alignment: .leading, spacing: Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Dati del cliente nei moduli") {
                    RigaImpostazione(titolo: "Conserva l'IBAN nel dossier",
                                     sottotitolo: conIban == 0 ? "Spento: l'IBAN si scrive solo sul modulo, ogni volta"
                                        : (conIban == 1 ? "1 cliente con l'IBAN salvato" : "\(conIban) clienti con l'IBAN salvato"),
                                     aiuto: "Acceso, l'IBAN si salva nell'anagrafica del cliente: mostrato mascherato, controllato con il "
                                        + "codice di controllo, nei backup (cifrati se c'è la password). Mai su iPhone e iPad né nei messaggi.",
                                     ultima: true) {
                        Toggle(isOn: Binding(get: { stato.dati.impostazioni.pratiche.ibanConservato },
                                             set: { acceso in
                                                 if !acceso && stato.clientiConIban > 0 { confermaSpegni = true } else { stato.impostaConservaIban(acceso) }
                                             })) { EmptyView() }
                            .toggleStyle(.appleSenzaEtichetta)
                            .disabled(stato.solaLettura)
                    }
                }
                NotaImpostazioni("Le risposte del questionario e delle dichiarazioni antiriciclaggio (titolare effettivo, persona "
                                 + "politicamente esposta, origine dei fondi) le dà il cliente ogni volta: Prisma non le compila. "
                                 + "Le firme sono caselle evidenziate da firmare a penna: niente firma elettronica.")
            }
            .cascataImpostazioni(2)
        }
        .onAppear { stato.moduli.carica() }
        .confirmationDialog("Togliere il modulo «\(daTogliere?.titolo ?? "")»?", isPresented: Binding(get: { daTogliere != nil }, set: { if !$0 { daTogliere = nil } }),
                            titleVisibility: .visible) {
            Button("Togli il modulo", role: .destructive) {
                if let m = daTogliere { stato.moduli.togli(m.id) }
                daTogliere = nil
            }
        } message: {
            Text("Il PDF vuoto e la sua mappa escono da Prisma. I moduli già compilati restano nei Documenti dei clienti.")
        }
        .confirmationDialog("Togliere gli IBAN salvati?", isPresented: $confermaSpegni, titleVisibility: .visible) {
            Button("Togli gli IBAN (\(conIban))", role: .destructive) { stato.impostaConservaIban(false) }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Spegnendo l'interruttore gli IBAN salvati nei dossier si tolgono. Restano nei backup già fatti.")
        }
    }

    /// «Proposta di polizza · 1 pagina · 17 caselle · fac-simile, ed. di prova».
    private func dettaglio(_ m: ModelloModulo) -> String {
        var parti = [m.tipo.nome, m.pagine == 1 ? "1 pagina" : "\(m.pagine) pagine",
                     m.campi.count == 1 ? "1 casella" : "\(m.campi.count) caselle"]
        if let v = m.versione { parti.append(v) }
        return parti.joined(separator: " · ")
    }
}
