#if os(iOS)
import SwiftUI

// Le app dell'iPhone in sola lettura che arrivano col giro 3 (nella finestra di vetro sopra la scrivania): Attività,
// Note, Documenti e Impostazioni. Le cifre e i testi sono quelli del Mac; il canale resta sempre in vista.

private typealias E = Tema.Apple.Telefono.Elenco

// MARK: - Attività

/// Le attività aperte, per scadenza: scadute, oggi, domani, più avanti. La casella è ferma (si spunta sul Mac).
struct AttivitaTelefono: View {
    @EnvironmentObject var stato: StatoShell

    private enum Gruppo: Int, CaseIterable, Identifiable {
        case scadute, oggi, domani, avanti
        var id: Int { rawValue }
        var titolo: String {
            switch self {
            case .scadute: return "Scadute"
            case .oggi: return "Oggi"
            case .domani: return "Domani"
            case .avanti: return "Più avanti"
            }
        }
    }

    var body: some View {
        let aperte = stato.attivitaAperte.sorted { $0.scadenza < $1.scadenza }
        FondoTelefono {
            if aperte.isEmpty {
                VuotoTelefono(testo: "Tutto fatto: nessuna attività aperta.")
            }
            ForEach(Gruppo.allCases) { gruppo in
                let delGruppo = aperte.filter { Self.gruppo(di: $0) == gruppo }
                if !delGruppo.isEmpty {
                    SezioneTelefono(titolo: gruppo.titolo)
                    ForEach(delGruppo) { attivita in
                        RigaAttivitaTelefono(attivita: attivita, scaduta: gruppo == .scadute)
                    }
                }
            }
        }
        .navigationTitle("Attività")
    }

    private static func gruppo(di a: Attivita) -> Gruppo {
        let cal = Calendar.current
        if a.scadenza < cal.startOfDay(for: Date()) { return .scadute }
        if cal.isDateInToday(a.scadenza) { return .oggi }
        if cal.isDateInTomorrow(a.scadenza) { return .domani }
        return .avanti
    }
}

private struct RigaAttivitaTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let attivita: Attivita
    let scaduta: Bool

    var body: some View {
        HStack(alignment: .top, spacing: E.spazioRiga) {
            CerchioAttivitaTelefono(fatta: attivita.completata)
                .padding(.top, E.spazioTesto * 2)
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(attivita.titolo)
                    .carattereApple(E.nome)
                    .foregroundColor(E.coloreNome)
                    .fixedSize(horizontal: false, vertical: true)
                Text(dettaglio)
                    .carattereApple(E.dettaglio)
                    .foregroundColor(scaduta ? E.coloreScaduto : E.coloreDettaglio)
                    .lineLimit(1)
                if attivita.priorita == .alta {
                    Text("Priorità alta")
                        .carattereApple(Tema.Apple.Telefono.StatoPosizione.carattere)
                        .foregroundColor(E.coloreVicino)
                }
            }
            Spacer(minLength: 0)
        }
        .schedaTelefono()
        .accessibilityElement(children: .combine)
    }

    private var dettaglio: String {
        let cliente = stato.cliente(attivita.clienteId)?.nome
        let quando = "\(Formati.giornoRelativo(attivita.scadenza))"
        return [cliente, quando].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

// MARK: - Note

/// Le note del taccuino, le fissate in cima e poi dalla più recente; un tocco apre il testo intero.
struct NoteTelefono: View {
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        let note = stato.dati.note.filter { !$0.vuota }.sorted(by: Nota.ordina)
        FondoTelefono {
            if note.isEmpty {
                VuotoTelefono(testo: "Nessuna nota: le note si scrivono in Prisma sul Mac.")
            }
            ForEach(note) { nota in
                NavigationLink {
                    DettaglioNotaTelefono(notaId: nota.id)
                } label: {
                    RigaNotaTelefono(nota: nota)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Note")
    }
}

private struct RigaNotaTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let nota: Nota

    var body: some View {
        HStack(alignment: .top, spacing: E.spazioRiga) {
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                HStack(spacing: E.spazioEtichette) {
                    if nota.fissata {
                        Image(systemName: "pin.fill")
                            .carattereApple(E.chevron)
                            .foregroundColor(E.coloreSimbolo)
                    }
                    Text(nota.titoloMostrato)
                        .carattereApple(E.nome)
                        .foregroundColor(E.coloreNome)
                        .lineLimit(1)
                }
                Text(nota.anteprima)
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                    .lineLimit(2)
                Text([stato.cliente(nota.clienteId)?.nome, Formati.dataBreve.string(from: nota.aggiornataIl)]
                        .compactMap { $0 }.joined(separator: " · "))
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreTerziario)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            ChevronTelefono()
        }
        .schedaTelefono(premibile: true)
    }
}

private struct DettaglioNotaTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let notaId: String

    var body: some View {
        let nota = stato.dati.note.first { $0.id == notaId }
        FondoTelefono {
            if let nota {
                VStack(alignment: .leading, spacing: E.spazioRiga) {
                    Text(nota.titoloMostrato)
                        .carattereApple(E.titolo)
                        .foregroundColor(E.coloreNome)
                    if let cliente = stato.cliente(nota.clienteId) {
                        DatoTelefono("Cliente", cliente.nome)
                    }
                    DatoTelefono("Aggiornata", Formati.dataBreve.string(from: nota.aggiornataIl))
                }
                .schedaTelefono()
                if !nota.testo.isEmpty {
                    Text(nota.testo)
                        .carattereApple(E.corpo)
                        .foregroundColor(E.coloreNome)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .schedaTelefono()
                }
            } else {
                VuotoTelefono(testo: "Questa nota non c'è più nell'archivio.")
            }
        }
        .navigationTitle(nota?.titoloMostrato ?? "Nota")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Documenti

/// I documenti dei clienti (KID, polizze, estratti, prospetti), per cliente: prima quello in primo piano.
struct DocumentiTelefono: View {
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        let attivo = stato.clienteAttivoId
        let clienti = stato.clienti.sorted { a, b in
            a.id == attivo ? true : b.id == attivo ? false : a.nome.localizedCaseInsensitiveCompare(b.nome) == .orderedAscending
        }
        let documenti = stato.dati.documenti
        FondoTelefono {
            if documenti.isEmpty {
                VuotoTelefono(testo: "Nessun documento: si importano in Prisma sul Mac.")
            }
            ForEach(clienti) { cliente in
                let delCliente = documenti.filter { $0.clienteId == cliente.id }.sorted { $0.importatoIl > $1.importatoIl }
                if !delCliente.isEmpty {
                    SezioneTelefono(titolo: cliente.nome)
                    ForEach(delCliente) { documento in
                        RigaDocumentoTelefono(documento: documento)
                    }
                }
            }
        }
        .navigationTitle("Documenti")
    }
}

struct RigaDocumentoTelefono: View {
    @EnvironmentObject var stato: StatoShell
    let documento: Documento

    var body: some View {
        HStack(spacing: E.spazioRiga) {
            Image(systemName: documento.tipo.creatoDaPrisma ? "doc.richtext" : "doc.text")
                .carattereApple(E.titolo)
                .foregroundColor(E.coloreSimbolo)
                .frame(width: E.icona)
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(documento.titolo)
                    .carattereApple(E.nome)
                    .foregroundColor(E.coloreNome)
                    .lineLimit(2)
                Text(dettaglio)
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                    .lineLimit(1)
                if let canale = canale {
                    EtichettaCanaleApple(canale: canale, compatta: true)
                        .padding(.top, E.spazioTesto)
                }
            }
            Spacer(minLength: 0)
        }
        .schedaTelefono()
        .accessibilityElement(children: .combine)
    }

    private var dettaglio: String {
        var parti = [documento.tipo.breve, Formati.dataBreve.string(from: documento.importatoIl)]
        if documento.pagine > 0 { parti.append(documento.pagine == 1 ? "1 pagina" : "\(documento.pagine) pagine") }
        return parti.joined(separator: " · ")
    }

    /// Il canale della posizione collegata, se c'è: Alleanza o indipendente sempre riconoscibile.
    private var canale: Canale? {
        guard let id = documento.posizioneId else { return nil }
        return stato.posizioni.first { $0.id == id }?.canale
    }
}

// MARK: - Impostazioni

/// Impostazioni sull'iPhone: in cima la copia cifrata del Mac (Prisma ovunque), poi l'aspetto (chiaro, scuro,
/// automatico), l'acqua della scrivania e la pioggia, poi l'archivio (il backup dal Mac e quello da rimandare al Mac).
/// Le altre scelte stanno in Prisma sul Mac.
struct ImpostazioniTelefono: View {
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        FondoTelefono {
            // Prisma ovunque (giro 8): la copia cifrata del Mac in iCloud Drive, la stessa pagina del Mac in una colonna
            SezioneTelefono(titolo: "iPhone e iPad")
            PaginaImpostazioniOvunque(compatta: true)

            SezioneTelefono(titolo: "Aspetto")
            VStack(alignment: .leading, spacing: E.spazioRiga) {
                scelta("Aspetto", sottotitolo: "Automatico segue l'iPhone, di giorno e di sera") {
                    SegmentatoTelefono(selezione: $stato.dati.impostazioni.aspetto,
                                       voci: AspettoInterfaccia.allCases.map { ($0, $0.nome) })
                }
                scelta("Sfondo", sottotitolo: "L'acqua della scrivania con le gocce al rallentatore") {
                    SegmentatoTelefono(selezione: $stato.dati.impostazioni.sfondoAnimato,
                                       voci: [(true, "Animato"), (false, "Fermo")])
                }
                scelta("Pioggia", sottotitolo: stato.dati.impostazioni.sfondoAnimato ? "Quante gocce cadono sull'acqua"
                                                                                     : "Con lo sfondo fermo non piove") {
                    SegmentatoTelefono(selezione: $stato.dati.impostazioni.pioggia,
                                       voci: IntensitaPioggia.allCases.map { ($0, $0.nome) })
                        .disabled(!stato.dati.impostazioni.sfondoAnimato)
                        .allowsHitTesting(stato.dati.impostazioni.sfondoAnimato)
                        .opacity(stato.dati.impostazioni.sfondoAnimato ? 1 : Tema.Misura.Shell.opacitaDisabilitato)
                }
                acquaDellaScrivania
                riduciMovimento
            }
            .schedaTelefono()

            SezioneTelefono(titolo: "Vera")
            VStack(alignment: .leading, spacing: E.spazioRiga) {
                VStack(alignment: .leading, spacing: E.spazioEtichette) {
                    Text("Codice del Mac")
                        .carattereApple(E.nome)
                        .foregroundColor(E.coloreNome)
                    Text(stato.dati.impostazioni.vera.ponte.abbinato
                         ? (stato.disponibilitaLocale.motivo ?? "Collegata: Vera risponde con Qwen del tuo Mac, in Wi‑Fi e cifrato")
                         : "Sul Mac apri Impostazioni › Vera, attiva «iPhone e iPad» e scrivi qui il codice che compare (arriva anche aprendo un backup del Mac)")
                        .carattereApple(E.dettaglio)
                        .foregroundColor(stato.disponibilitaLocale.pronto ? Tema.Apple.Colore.verde : E.coloreDettaglio)
                        .fixedSize(horizontal: false, vertical: true)
                    TextField("ABCD-EFGH-JKLM", text: $stato.dati.impostazioni.vera.ponte.codice)
                        .carattereApple(E.valore)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { stato.verificaMotoreLocale() }
                        .padding(.horizontal, E.padding.leading)
                        .frame(height: Tema.Apple.Telefono.tocco)
                        .background(RoundedRectangle(cornerRadius: E.raggioCampo, style: .continuous).fill(E.fondoCampo))
                }
                Button { stato.verificaMotoreLocale() } label: {
                    Label("Collega al Mac", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity, minHeight: Tema.Apple.Telefono.tocco)
                }
                .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
            }
            .schedaTelefono()

            SezioneTelefono(titolo: "Archivio")
            ArchivioMobile()
        }
        .navigationTitle("Impostazioni")
    }

    /// «L'acqua della scrivania» (SfondoAcquaRisposta.swift): toccando il fondo libero cade una goccia, le notifiche
    /// arrivano come gocce e l'acqua vibra piano mentre Vera risponde. Come in Impostazioni › Aspetto del Mac.
    private var acquaDellaScrivania: some View {
        let animato = stato.dati.impostazioni.sfondoAnimato
        return HStack(alignment: .center, spacing: E.spazioRiga) {
            VStack(alignment: .leading, spacing: E.spazioEtichette) {
                Text("L'acqua della scrivania")
                    .carattereApple(E.nome)
                    .foregroundColor(E.coloreNome)
                Text(animato ? "Toccando l'acqua cade una goccia" : "Con lo sfondo fermo l'acqua non risponde")
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Toggle(isOn: $stato.dati.impostazioni.acquaDellaScrivania) { EmptyView() }
                .toggleStyle(.appleSenzaEtichetta)
                .accessibilityLabel("L'acqua della scrivania")
                .disabled(!animato)
                .opacity(animato ? 1 : Tema.Misura.Shell.opacitaDisabilitato)
        }
    }

    /// «Riduci movimento» di Prisma: si somma a quello dell'iPhone; tutto compare già fermo e l'acqua si ferma.
    private var riduciMovimento: some View {
        HStack(alignment: .center, spacing: E.spazioRiga) {
            VStack(alignment: .leading, spacing: E.spazioEtichette) {
                Text("Riduci movimento")
                    .carattereApple(E.nome)
                    .foregroundColor(E.coloreNome)
                Text("Animazioni brevi e acqua ferma, anche se l'iPhone non lo chiede")
                    .carattereApple(E.dettaglio)
                    .foregroundColor(E.coloreDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Toggle(isOn: $stato.dati.impostazioni.riduciMovimento) { EmptyView() }
                .toggleStyle(.appleSenzaEtichetta)
                .accessibilityLabel("Riduci movimento")
        }
    }

    private func scelta<C: View>(_ titolo: String, sottotitolo: String, @ViewBuilder _ controllo: () -> C) -> some View {
        VStack(alignment: .leading, spacing: E.spazioEtichette) {
            Text(titolo)
                .carattereApple(E.nome)
                .foregroundColor(E.coloreNome)
            Text(sottotitolo)
                .carattereApple(E.dettaglio)
                .foregroundColor(E.coloreDettaglio)
                .fixedSize(horizontal: false, vertical: true)
            controllo()
                .padding(.top, E.spazioTesto)
        }
    }
}
#endif
