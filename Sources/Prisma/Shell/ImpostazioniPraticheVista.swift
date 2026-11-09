import SwiftUI

// Impostazioni › Pratiche (Design/template-luce-specifica.md §7.3, D3.2, «Luce» giro 3): dopo quanti giorni senza un
// passo nuovo una pratica dopo la firma è «ferma». 7 di base; il campo non resta mai vuoto (almeno un giorno). Le
// pratiche ferme compaiono solo dentro Prisma: nel centro notifiche, gruppo «Da sistemare», e nella scheda Dopo la firma.

struct PaginaImpostazioniPratiche: View {
    @Environment(StatoShell.self) var stato

    private typealias I = ImpostazioniPratiche

    var body: some View {
        let _ = ContaCorpi.segna()
        let giorni = stato.dati.impostazioni.pratiche.giorniFerma
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Pagina.spazioGruppi) {
            NotaImpostazioni("Una pratica nasce quando una proposta viene accettata e segue i passi fino alla consegna "
                             + "al cliente. Qui scegli quando una pratica senza passi nuovi diventa «ferma».")
            VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Pratiche ferme") {
                    RigaImpostazione(titolo: "Ferma dopo",
                                     sottotitolo: "Oltre questi giorni senza un passo nuovo la pratica è segnata in rosso",
                                     aiuto: "I giorni si contano dall'ultimo passo fatto (o dall'apertura, se non ce n'è "
                                        + "ancora uno). Con 7 giorni una pratica diventa ferma all'ottavo.",
                                     ultima: true) {
                        Stepper(value: Binding(
                            get: { stato.dati.impostazioni.pratiche.giorniFerma },
                            set: { stato.dati.impostazioni.pratiche.giorniFerma = min(I.giorniFermaMassimi, max(I.giorniFermaMinimi, $0)) }),
                                in: I.giorniFermaMinimi...I.giorniFermaMassimi) {
                            Text(giorni == 1 ? "1 giorno" : "\(giorni) giorni")
                                .carattereApple(Tema.Apple.Carattere.corpo.tabellari)
                                .foregroundColor(Tema.Apple.Colore.inchiostro)
                        }
                        .fixedSize()
                        .disabled(stato.solaLettura)
                    }
                }
                NotaImpostazioni("Le pratiche ferme restano dentro Prisma: compaiono nel centro notifiche, fra le cose da "
                                 + "sistemare, e in Pratiche › Dopo la firma. Nessuna notifica di macOS.")
            }
            .cascataImpostazioni(1)
            // «Luce» giro 15: i sinistri (Pratiche › Sinistri, §7.4.6): ciò che Prisma non può sapere lo scrivi qui
            ImpostazioniSinistri()
                .cascataImpostazioni(2)
        }
    }
}

/// La parte dei sinistri di Impostazioni › Pratiche («Luce» giro 15): dopo quanti giorni senza fatti un sinistro è
/// fermo (14 di base, da confermare), gli indirizzi dei sinistri delle compagnie (con «solo dal portale») e i documenti
/// richiesti per tipo di sinistro. Tutto scritto dall'utente: Prisma non è collegato alle compagnie.
private struct ImpostazioniSinistri: View {
    @Environment(StatoShell.self) var stato

    private typealias I = ImpostazioniPratiche
    private typealias F = Tema.Apple.Pratiche.ImpostazioniSinistri

    var body: some View {
        let p = stato.dati.impostazioni.pratiche
        let giorni = p.sogliaSinistroFermo
        let indirizzi = p.indirizziSinistri ?? []
        let tipi = p.documentiPerSinistro ?? []
        VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
            GruppoSinistriFermi(giorni: giorni, cambia: { v in modifica { $0.giorniSinistroFermo = v } })
            GruppoImpostazioni(titolo: "Indirizzi dei sinistri") {
                ForEach(indirizzi) { c in
                    RigaImpostazione(titolo: c.compagnia.isEmpty ? "Compagnia" : c.compagnia,
                                     sottotitolo: c.soloPortale ? "Solo dal portale: il pulsante lascia un promemoria" : "Il sollecito apre una bozza in Mail",
                                     ultima: false) {
                        HStack(spacing: F.spazioCampi) {
                            TextField("compagnia (come nella polizza)", text: Binding(
                                get: { c.compagnia },
                                set: { v in cambiaIndirizzo(c.id) { $0.compagnia = v } }))
                                .frame(width: F.campoCompagnia)
                            TextField("indirizzo email dei sinistri", text: Binding(
                                get: { c.email },
                                set: { v in cambiaIndirizzo(c.id) { $0.email = v } }))
                                .frame(width: F.campoEmail)
                                .disabled(c.soloPortale)
                            Toggle("Solo dal portale", isOn: Binding(
                                get: { c.soloPortale },
                                set: { v in cambiaIndirizzo(c.id) { $0.soloPortale = v } }))
                                .toggleStyle(.apple)
                            Button {
                                modifica { x in x.indirizziSinistri = (x.indirizziSinistri ?? []).filter { $0.id != c.id }.nonVuoto }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(StileSemplice())
                            .help("Togli la compagnia")
                        }
                        .textFieldStyle(.roundedBorder)
                        .carattereApple(F.carattereCampi)
                        .disabled(stato.solaLettura)
                    }
                }
                RigaImpostazione(titolo: "Aggiungi una compagnia",
                                 sottotitolo: "Il nome come scritto nelle polizze (l'emittente), l'indirizzo dei sinistri che ti ha dato la compagnia",
                                 ultima: true) {
                    Button("Aggiungi") {
                        modifica { x in x.indirizziSinistri = (x.indirizziSinistri ?? []) + [IndirizzoCompagnia()] }
                    }
                    .buttonStyle(.apple)
                    .disabled(stato.solaLettura)
                }
            }
            GruppoImpostazioni(titolo: "Documenti per tipo di sinistro") {
                ForEach(tipi) { t in
                    RigaImpostazione(titolo: t.tipo.isEmpty ? "Tipo di sinistro" : t.tipo,
                                     sottotitolo: "I documenti separati da una virgola: il nuovo sinistro di questo tipo li chiede tutti",
                                     ultima: false) {
                        HStack(spacing: F.spazioCampi) {
                            TextField("tipo (furto, infortunio…)", text: Binding(
                                get: { t.tipo },
                                set: { v in cambiaTipo(t.id) { $0.tipo = v } }))
                                .frame(width: F.campoTipo)
                            TextField("denuncia, fattura, …", text: Binding(
                                get: { t.documenti.joined(separator: ",") },
                                set: { v in cambiaTipo(t.id) { $0.documenti = v.split(separator: ",", omittingEmptySubsequences: false).map(String.init) } }))
                                .frame(width: F.campoDocumenti)
                            Button {
                                modifica { x in x.documentiPerSinistro = (x.documentiPerSinistro ?? []).filter { $0.id != t.id }.nonVuoto }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(StileSemplice())
                            .help("Togli il tipo")
                        }
                        .textFieldStyle(.roundedBorder)
                        .carattereApple(F.carattereCampi)
                        .disabled(stato.solaLettura)
                    }
                }
                RigaImpostazione(titolo: "Aggiungi un tipo",
                                 sottotitolo: "Gli elenchi li dai tu, per tipo e compagnia: Prisma non li inventa",
                                 ultima: true) {
                    Button("Aggiungi") {
                        modifica { x in x.documentiPerSinistro = (x.documentiPerSinistro ?? []) + [DocumentiSinistro()] }
                    }
                    .buttonStyle(.apple)
                    .disabled(stato.solaLettura)
                }
            }
            NotaImpostazioni("Prisma non è collegato alle compagnie: fasi, date e importi dei sinistri li segni tu. Il "
                             + "sollecito è una bozza in Mail con solo numero di polizza, numero di sinistro e assicurato; "
                             + "lo controlli e lo spedisci tu.")
        }
    }

    private func modifica(_ cambia: (inout ImpostazioniPratiche) -> Void) {
        guard !stato.solaLettura else { return }
        var p = stato.dati.impostazioni.pratiche
        cambia(&p)
        stato.dati.impostazioni.pratiche = p
    }

    private func cambiaIndirizzo(_ id: String, _ cambia: (inout IndirizzoCompagnia) -> Void) {
        modifica { p in
            var elenco = p.indirizziSinistri ?? []
            guard let i = elenco.firstIndex(where: { $0.id == id }) else { return }
            cambia(&elenco[i])
            p.indirizziSinistri = elenco
        }
    }

    private func cambiaTipo(_ id: String, _ cambia: (inout DocumentiSinistro) -> Void) {
        modifica { p in
            var elenco = p.documentiPerSinistro ?? []
            guard let i = elenco.firstIndex(where: { $0.id == id }) else { return }
            cambia(&elenco[i])
            p.documentiPerSinistro = elenco
        }
    }
}

/// «Sinistri fermi»: dopo quanti giorni senza un fatto nuovo un sinistro aperto è fermo.
private struct GruppoSinistriFermi: View {
    let giorni: Int
    let cambia: (Int) -> Void
    @Environment(StatoShell.self) var stato

    private typealias I = ImpostazioniPratiche

    var body: some View {
        GruppoImpostazioni(titolo: "Sinistri fermi") {
            RigaImpostazione(titolo: "Fermo dopo",
                             sottotitolo: "Oltre questi giorni senza un fatto nuovo il sinistro compare fra le cose da sistemare",
                             aiuto: "I giorni si contano dall'ultimo fatto già accaduto (o dalla denuncia). Con 14 giorni un "
                                + "sinistro diventa fermo al quindicesimo. 14 è una proposta: scegli tu.",
                             ultima: true) {
                Stepper(value: Binding(get: { giorni },
                                       set: { cambia(min(I.giorniSinistroFermoMassimi, max(I.giorniSinistroFermoMinimi, $0))) }),
                        in: I.giorniSinistroFermoMinimi...I.giorniSinistroFermoMassimi) {
                    Text(giorni == 1 ? "1 giorno" : "\(giorni) giorni")
                        .carattereApple(Tema.Apple.Carattere.corpo.tabellari)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                }
                .fixedSize()
                .disabled(stato.solaLettura)
            }
        }
    }
}

private extension Array {
    /// nil se vuoto (le impostazioni tengono nil per «nessuno»).
    var nonVuoto: [Element]? { isEmpty ? nil : self }
}
