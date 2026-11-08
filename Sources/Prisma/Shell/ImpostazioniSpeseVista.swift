import SwiftUI

// Impostazioni › Studio › Chilometri, spese e scadenze («Luce» giro 9, Design/template-luce-specifica.md §6.3.5.3 e
// §6.3.6): da dove parti, i km di andata e ritorno per cliente (scritti una volta, decisione 22), le ore di aggiornamento
// richieste per l'anno e l'ente (nessun requisito nel codice, decisione 66), il giorno in cui Studio passa al mese
// nuovo, le visite senza cliente, il valore per km facoltativo e i nomi dei clienti nel pacchetto (spenti, decisione 14).
// Nessun valore predefinito inventato: un campo vuoto resta vuoto e Studio › Spese lo dice.

struct SezioneImpostazioniSpese: View {
    @Environment(StatoShell.self) var stato
    @State private var anno = Calendar.current.component(.year, from: Date())

    static var ancora: String { TestiSpese.ancoraImpostazioni }

    var body: some View {
        let _ = ContaCorpi.segna()
        let imp = stato.dati.impostazioni.studio.spese
        let annoCorrente = Calendar.current.component(.year, from: Date())
        let f = Tema.Apple.Studio.Impostazioni.self
        let clienti = stato.clienti.sorted { $0.nome.localizedCaseInsensitiveCompare($1.nome) == .orderedAscending }
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Pagina.spazioGruppi) {
            VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Chilometri, spese e scadenze") {
                    RigaImpostazione(titolo: "Da dove parti", sottotitolo: "Una descrizione, per esempio «Studio di via Roma»: nessuna coordinata") {
                        TextField("", text: legame(\.partenza), prompt: Text(verbatim: "—"))
                            .campoTesto()
                            .frame(width: Tema.Apple.Studio.Spese.Moduli.campoTesto)
                    }
                    RigaImpostazione(titolo: "Il mese di Studio › Spese",
                                     sottotitolo: "Fino a questo giorno Studio mostra il mese prima, quello da chiudere col commercialista") {
                        Stepper(value: legame(\.giornoCambioMese), in: ImpostazioniSpese.giorniCambio) {
                            Text("fino al \(imp.giornoCambioMese)")
                                .carattereApple(f.unita)
                                .foregroundColor(f.coloreUnita)
                        }
                        .fixedSize()
                    }
                    RigaImpostazione(titolo: "Appuntamenti senza cliente",
                                     sottotitolo: "Contali fra le visite: i loro km solo con la correzione del giorno") {
                        Toggle("", isOn: legame(\.contaVisiteSenzaCliente))
                            .toggleStyle(.appleSenzaEtichetta)
                    }
                    RigaImpostazione(titolo: "Valore per km nel pacchetto",
                                     sottotitolo: "Facoltativo: se lo vuoi, scrivilo tu (accordi o tabelle che usi). Vuoto: nessun euro per i km",
                                     ultima: true) {
                        CampoNumeroStudio(etichetta: nil, unita: "€/km", larghezza: f.campoPercentuale, decimali: 4,
                                          valore: legame(\.euroPerKm))
                    }
                }
                NotaImpostazioni("Prisma non calcola i km con servizi di percorso e non manda gli indirizzi dei clienti fuori dal Mac: "
                                 + "i km li scrivi tu una volta per cliente, e un giro lo correggi a mano.")
            }
            VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
                GruppoImpostazioni(titolo: "I km di andata e ritorno per cliente") {
                    if clienti.isEmpty {
                        RigaImpostazione(titolo: "Nessun cliente", sottotitolo: "I km si scrivono per i clienti che visiti", ultima: true) {
                            EmptyView()
                        }
                    }
                    ForEach(Array(clienti.enumerated()), id: \.element.id) { i, c in
                        RigaImpostazione(titolo: c.nome, sottotitolo: c.indirizzo.isEmpty ? nil : c.indirizzo,
                                         ultima: i == clienti.count - 1) {
                            CampoNumeroStudio(etichetta: nil, unita: "km", larghezza: f.campoNumero, decimali: 1,
                                              valore: Binding(get: { stato.dati.kmClienti[c.id] },
                                                              set: { stato.impostaKmCliente(c.id, $0) }))
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Aggiornamento professionale") {
                    RigaImpostazione(titolo: "Anno", sottotitolo: "Le ore richieste valgono per un anno solo") {
                        SegmentatoPillola(selezione: $anno,
                                          voci: [(annoCorrente, String(annoCorrente)), (annoCorrente + 1, String(annoCorrente + 1))])
                            .fixedSize()
                    }
                    RigaImpostazione(titolo: "Ore richieste", sottotitolo: "Le scrivi tu: Prisma non contiene i requisiti di IVASS o OCF") {
                        CampoNumeroStudio(etichetta: nil, unita: "ore", larghezza: f.campoNumero, decimali: 1,
                                          valore: Binding(get: { imp.oreAggiornamentoAnno[anno] },
                                                          set: { stato.impostaOreAggiornamento(anno: anno, $0) }))
                    }
                    RigaImpostazione(titolo: "Ente", sottotitolo: "Facoltativo: compare accanto all’anello delle ore", ultima: true) {
                        TextField("", text: legame(\.enteAggiornamento), prompt: Text(verbatim: "—"))
                            .campoTesto()
                            .frame(width: f.campoImporto)
                    }
                }
            }
            VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Il pacchetto per il commercialista") {
                    RigaImpostazione(titolo: "Nomi dei clienti nel pacchetto",
                                     sottotitolo: "Spento: dei giri solo data, km e numero di visite",
                                     aiuto: "Lo zip esce dal Mac per mano tua: senza nomi il commercialista vede solo date, km e quante visite.",
                                     ultima: true) {
                        Toggle("", isOn: legame(\.nomiNelPacchetto))
                            .toggleStyle(.appleSenzaEtichetta)
                    }
                }
                NotaImpostazioni("Il pacchetto lo salvi dove vuoi e lo consegni tu: Prisma non lo invia a nessuno.")
            }
        }
        .disabled(stato.solaLettura)
    }

    /// Il legame con un campo delle impostazioni delle spese.
    private func legame<T: Equatable>(_ k: WritableKeyPath<ImpostazioniSpese, T>) -> Binding<T> {
        let stato = self.stato
        return Binding(get: { stato.dati.impostazioni.studio.spese[keyPath: k] },
                       set: { nuovo in
                           guard stato.dati.impostazioni.studio.spese[keyPath: k] != nuovo else { return }
                           stato.dati.impostazioni.studio.spese[keyPath: k] = nuovo
                       })
    }
}
