import SwiftUI

// Impostazioni › Mercato (giro 7, Design/template-novita-specifica.md §12.6 e §14.9): come le altre pagine del tema
// Apple, righe come card senza ombra con il titolo e la spiegazione a sinistra e il controllo a destra.
//
// - «Dati di mercato»: l'interruttore, SPENTO di base. Acceso, Prisma scarica le serie pubbliche di BCE ed Eurostat;
//   escono solo i codici pubblici delle serie (ClienteMercato.richiesta), mai dati dei clienti. Spento, niente rete.
// - L'ultimo aggiornamento, «Aggiorna ora» e l'errore dell'ultimo scaricamento (serie per serie).
// - Le serie della configurazione (serie-mercato.json) da accendere o spegnere, con il codice, la fonte e il dato di
//   terzi quando c'è.
// - Le soglie degli avvisi, tutte vuote all'inizio (nessuna soglia = nessun avviso), e il riferimento di ogni ISIN.
// - I dati importati e a mano: importa un CSV, inserisci un valore, aggiorna le posizioni dalle quote.
// Su iPhone e iPad la pagina si legge soltanto: le scelte e i dati arrivano dal Mac.

struct PaginaImpostazioniMercato: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        // SessioneMercato è @Observable: la pagina si aggiorna da sola quando cambiano configurazione e aggiornamento
        corpo
    }

    @ViewBuilder private var corpo: some View {
        let _ = ContaCorpi.segna()
        let m = stato.dati.impostazioni.mercato
        let archivio = stato.dati.mercato
        let configurazione = stato.sessioneMercato.configurazione
        let k = Tema.Apple.Mercato.Impostazioni.self
        let pagina = Tema.Apple.Impostazioni.Pagina.self
        let riga = Tema.Apple.Impostazioni.Riga.self
        return VStack(alignment: .leading, spacing: pagina.spazioGruppi) {
            NotaImpostazioni(TestiAppMercato.notaPagina)
            VStack(alignment: .leading, spacing: riga.fraRighe) {
                GruppoImpostazioni(titolo: TestiAppMercato.interruttore) {
                    RigaImpostazione(titolo: TestiAppMercato.interruttore, sottotitolo: TestiAppMercato.interruttoreSpiegazione,
                                     aiuto: TestiAppMercato.interruttoreAiuto) {
                        Toggle(isOn: Binding(get: { stato.dati.impostazioni.mercato.attivo },
                                             set: { stato.impostaDatiDiMercato($0) })) { EmptyView() }
                            .toggleStyle(.appleSenzaEtichetta)
                            .accessibilityLabel(TestiAppMercato.interruttore)
                            .disabled(!modificabile)
                    }
                    RigaImpostazione(titolo: TestiAppMercato.ultimoAggiornamento,
                                     sottotitolo: TestiAppMercato.ultimo(archivio.ultimoAggiornamento),
                                     avvertenza: m.attivo ? archivio.ultimoErrore.map { TestiAppMercato.ultimoErrore + ": " + $0 } : nil,
                                     ultima: true) {
                        #if os(macOS)
                        Button(TestiAppMercato.aggiornaOra) { stato.aggiornaMercato(forza: true) }
                            .buttonStyle(.apple)
                            .disabled(!m.attivo || stato.solaLettura || stato.sessioneMercato.inAggiornamento)
                        #else
                        EmptyView()
                        #endif
                    }
                }
                .cascataImpostazioni(1)
            }
            VStack(alignment: .leading, spacing: riga.fraRighe) {
                GruppoImpostazioni(titolo: TestiAppMercato.serieGruppo) {
                    if let c = configurazione {
                        let attive = Set(c.attive(m).map(\.id))
                        ForEach(Array(c.serie.enumerated()), id: \.element.id) { i, s in
                            RigaImpostazione(titolo: s.nome, sottotitolo: descrizione(s), ultima: i == c.serie.count - 1) {
                                Toggle(isOn: Binding(get: { attive.contains(s.id) },
                                                     set: { stato.impostaSerieMercato(s.id, attiva: $0) })) { EmptyView() }
                                    .toggleStyle(.appleSenzaEtichetta)
                                    .accessibilityLabel(s.nome)
                                    .disabled(!modificabile)
                            }
                        }
                    } else {
                        RigaImpostazione(titolo: TestiAppMercato.configurazioneMancante, ultima: true) { EmptyView() }
                    }
                }
                NotaImpostazioni(TestiAppMercato.serieNota)
            }
            .cascataImpostazioni(2)
            VStack(alignment: .leading, spacing: riga.fraRighe) {
                GruppoImpostazioni(titolo: TestiAppMercato.soglieGruppo) {
                    ForEach(Array(SogliaMercato.allCases.enumerated()), id: \.element) { i, s in
                        RigaImpostazione(titolo: s.titolo, sottotitolo: s.spiegazione, ultima: i == SogliaMercato.allCases.count - 1) {
                            CampoNumeroMercato(unita: s.unita, decimali: s.decimali, valore: stato.legameSogliaMercato(s))
                                .disabled(!modificabile)
                        }
                    }
                }
                NotaImpostazioni(TestiAppMercato.soglieNota)
            }
            .cascataImpostazioni(3)
            VStack(alignment: .leading, spacing: riga.fraRighe) {
                GruppoImpostazioni(titolo: TestiAppMercato.riferimentiGruppo) {
                    let indici = archivio.serie.filter { $0.unita.variazioneInPercentuale && !$0.punti.isEmpty }
                    if archivio.quote.isEmpty {
                        RigaImpostazione(titolo: TestiAppMercato.nessunISIN, ultima: true) { EmptyView() }
                    } else {
                        ForEach(Array(archivio.quote.enumerated()), id: \.element.isin) { i, q in
                            RigaImpostazione(titolo: q.nome.isEmpty ? q.isin : q.nome, sottotitolo: q.isin,
                                             ultima: i == archivio.quote.count - 1) {
                                Picker("", selection: legameRiferimento(q.isin)) {
                                    Text(TestiAppMercato.nessunRiferimento).tag("")
                                    ForEach(indici) { s in Text(s.nome).tag(s.id) }
                                }
                                .labelsHidden()
                                .frame(width: k.larghezzaScelta)
                                .disabled(!modificabile)
                            }
                        }
                    }
                }
                NotaImpostazioni(TestiAppMercato.riferimentiNota)
            }
            .cascataImpostazioni(4)
            #if os(macOS)
            VStack(alignment: .leading, spacing: riga.fraRighe) {
                GruppoImpostazioni(titolo: TestiAppMercato.datiGruppo) {
                    RigaImpostazione(titolo: TestiAppMercato.importaFile, sottotitolo: TestiAppMercato.importaSpiegazione) {
                        Button(TestiAppMercato.scegliFile) { stato.scegliFileMercato() }
                            .buttonStyle(.apple)
                            .disabled(stato.solaLettura)
                    }
                    RigaImpostazione(titolo: TestiAppMercato.aMano, sottotitolo: TestiAppMercato.datiNota) {
                        Button(TestiAppMercato.aMano) {
                            stato.sessioneMercato.foglio = .aMano
                            stato.apri(.mercato)
                        }
                        .buttonStyle(.apple)
                        .disabled(stato.solaLettura)
                    }
                    let daAggiornare = stato.valoriDaQuoteMercato().filter { $0.valore != nil }.count
                    RigaImpostazione(titolo: TestiAppMercato.aggiornaPosizioni,
                                     sottotitolo: TestiAppMercato.posizioniDaAggiornare(daAggiornare), ultima: true) {
                        Button(TestiAppMercato.aggiornaPosizioni) { stato.aggiornaPosizioniDaQuote() }
                            .buttonStyle(.apple)
                            .disabled(stato.solaLettura || daAggiornare == 0)
                    }
                }
            }
            .cascataImpostazioni(5)
            #endif
        }
    }

    /// Sul Mac, fuori dalla sola lettura (su iPhone e iPad le scelte arrivano dal Mac).
    private var modificabile: Bool {
        #if os(macOS)
        return !stato.solaLettura
        #else
        return false
        #endif
    }

    /// «BCE · FM.D.U2.EUR.4F.KR.DFR.LEV · Dato di EMMI, ridistribuito dalla fonte».
    private func descrizione(_ s: ConfigurazioneMercato.Serie) -> String {
        var parti = [s.fonte.nome, s.codice]
        if let f = s.filtri, !f.isEmpty { parti.append(f.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")) }
        if let t = s.terzi { parti.append(TestiAppMercato.datoDiTerzi(t)) }
        return parti.joined(separator: " · ")
    }

    private func legameRiferimento(_ isin: String) -> Binding<String> {
        let stato = self.stato
        return Binding<String>(
            get: { stato.dati.impostazioni.mercato.riferimenti[isin] ?? "" },
            set: { nuovo in
                stato.impostaSogliaMercato { m in m.riferimenti[isin] = nuovo.isEmpty ? nil : nuovo }
            })
    }
}
