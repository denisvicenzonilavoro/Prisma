import SwiftUI

/// Analisi 360 › TFR (giro 6, specifica 11 §7.5; rivista con la revisione del consulente): «TFR in azienda o
/// nel fondo pensione» per un lavoratore dipendente. Console a sinistra in tre gruppi (Lavoratore, Fondo, Fisco),
/// risultati a destra con la differenza fra le strade in alto, le barre affiancate e i KPI; tabella, metodo e
/// semplificazioni nel «Dettaglio». Prospetto e report in PDF dalla testata dei risultati.
///
/// Le ipotesi sul tavolo sono una bozza locale: i cursori scrivono la bozza e l'archivio si aggiorna solo dopo
/// una pausa (e quando la vista sparisce o cambia il cliente). Scrivere `dati` a ogni passo del cursore
/// ridisegnerebbe tutte le finestre aperte: sull'M1 da 8 GB si sente.
struct SchedaTFR: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.modoIstantanea) private var modoIstantanea
    @State private var report = false
    @State private var daSalvare: PDFDaSalvare?
    @State private var archiviato: String?
    @State private var mostraDettaglio = false
    /// Per un cliente non dipendente: il consulente sceglie di fare il confronto lo stesso (per esempio se cambia lavoro).
    @State private var confrontaComunque = false
    /// La bozza delle ipotesi e il cliente a cui appartiene (nil = si leggono quelle dell'archivio).
    @State private var bozza: IpotesiTFR?
    @State private var clienteBozza: String?

    private typealias M = Tema.Misura.TFR
    private typealias K = Tema.Colore.TFR
    private typealias F = Tema.Testo.TFR
    private typealias A = Tema.Apple.ConfrontoTFR
    private typealias S = Tema.Apple.Strumenti360

    /// Intervalli e passi dei comandi della console (la lettura dell'archivio ha limiti più larghi: `IpotesiTFR.Limiti`).
    private enum Console {
        static let retribuzione: ClosedRange<Double> = IpotesiTFR.Limiti.retribuzione
        static let passoRetribuzione = 500.0
        static let fineRetribuzione = 150_000.0
        static let crescita: ClosedRange<Double> = IpotesiTFR.Limiti.crescitaReale
        static let anni: ClosedRange<Double> = 1...50
        /// L'inflazione accetta tutto l'intervallo dell'archivio; il cursore arriva al 10%.
        static let inflazione: ClosedRange<Double> = IpotesiTFR.Limiti.inflazione
        static let fineInflazione = 10.0
        static let rendimento: ClosedRange<Double> = -10...15
        static let costo: ClosedRange<Double> = 0...3
        static let titoliStato: ClosedRange<Double> = IpotesiTFR.Limiti.titoliStatoFondo
        static let contributo: ClosedRange<Double> = 0...10
        static let partecipazione: ClosedRange<Double> = 0...50
        static let servizio: ClosedRange<Double> = 0...50
        static let maturato: ClosedRange<Double> = IpotesiTFR.Limiti.tfrMaturato
        static let conferita: ClosedRange<Double> = IpotesiTFR.Limiti.quotaConferita
        static let quota: ClosedRange<Double> = IpotesiTFR.Limiti.quotaTFR
        static let aliquota: ClosedRange<Double> = IpotesiTFR.Limiti.aliquotaTFR
        static let tasso: ClosedRange<Double> = -2...10
        static let passo = 0.1
        static let passoCosto = 0.05
    }

    private var cliente: String { stato.clienteAttivoId }

    /// Le ipotesi sul tavolo: la bozza del cliente attivo o quelle dell'archivio (salvate o dai dati del cliente).
    private var ipotesi: IpotesiTFR {
        if let b = bozza, clienteBozza == cliente { return b }
        return stato.ipotesiTFR(cliente)
    }

    /// Le ipotesi ricavate dai soli dati del cliente (per le note dei ripieghi), una volta per dati dei calcoli e giorno:
    /// la console le confronta a ogni passo del cursore. Solo dossier e posizioni, nessuna ipotesi salvata.
    private var partenza: IpotesiTFR {
        let id = cliente
        return stato.ricavato("tfr-partenza|\(id)") {
            IpotesiTFR.dalCliente(stato.cliente(id), posizioni: stato.posizioniCliente(id))
        }
    }

    private var legame: Binding<IpotesiTFR> {
        Binding(get: { ipotesi }, set: { nuove in
            if clienteBozza != cliente { clienteBozza = cliente }
            bozza = nuove
        })
    }

    var body: some View {
        let i = ipotesi
        let e = MotoreTFR.calcola(i)
        ColonneAffiancate(larghezza: Misure.ColonneStrumento.comandi) {
            console(i, e)
        } flessibile: {
            risultati(i, e)
        }
        .sheet(item: $daSalvare) { pdf in
            ModuloSalvaPDF(pdf: pdf, impostazioni: stato.dati.impostazioni.pdf)
                .environment(stato)
        }
        .onChange(of: stato.clienteAttivoId) { _ in
            // La bozza del cliente di prima si salva prima di passare al nuovo
            salvaBozza()
            bozza = nil
            clienteBozza = nil
            archiviato = nil
            confrontaComunque = false
        }
        .task(id: bozza) {
            guard bozza != nil else { return }
            try? await Task.sleep(nanoseconds: M.pausaSalvataggio)
            if !Task.isCancelled { salvaBozza() }
        }
        .onDisappear { salvaBozza() }
    }

    /// Scrive la bozza nell'archivio (se è cambiata: `salvaIpotesiTFR` non riscrive ipotesi uguali).
    private func salvaBozza() {
        guard let b = bozza, let c = clienteBozza else { return }
        stato.salvaIpotesiTFR(c, b)
    }

    // MARK: - Console

    private func console(_ i: IpotesiTFR, _ e: EsitoTFR?) -> some View {
        let b = legame
        // Ripieghi: la nota compare solo se il valore è ancora quello di partenza ricavato senza il dato
        let rip = stato.ripieghiTFR(cliente)
        let partenza = self.partenza
        let notaRetribuzione = rip.retribuzione && i.retribuzione == partenza.retribuzione
            ? "Stimata: manca il reddito da lavoro" : nil
        let notaAnni: String? = {
            guard i.anni == partenza.anni else { return nil }
            if rip.eta { return "Stimati: manca la data di nascita (\(RegoleTFR.etaPredefinita) anni)" }
            if rip.etaPensione { return "Stimati: pensione a \(RegoleTFR.etaPensionePredefinita) anni" }
            return nil
        }()
        return ScrollView {
            VStack(alignment: .leading, spacing: M.spazioConsole) {
                gruppo("Lavoratore") {
                    Group {
                        ComandoSimulatoreFermo(etichetta: "Retribuzione utile al TFR", valore: b.retribuzione, unita: "€",
                                               intervallo: Console.retribuzione, passo: Console.passoRetribuzione,
                                               fineCursore: Console.fineRetribuzione)
                            .equatable()
                        notaComando(notaRetribuzione)
                        ComandoSimulatoreFermo(etichetta: "Crescita oltre l'inflazione", valore: b.crescitaReale, unita: "%",
                                               intervallo: Console.crescita, passo: Console.passo, decimali: 1)
                            .equatable()
                        ComandoSimulatoreFermo(etichetta: "Anni con questo datore fino alla pensione", valore: intero(b.anni, Console.anni),
                                               unita: "anni", intervallo: Console.anni, passo: 1)
                            .equatable()
                        notaComando(notaAnni)
                        ComandoSimulatoreFermo(etichetta: "Inflazione ipotizzata", valore: b.inflazione, unita: "%",
                                               intervallo: Console.inflazione, passo: Console.passo, decimali: 1,
                                               fineCursore: Console.fineInflazione)
                            .equatable()
                    }
                    Group {
                        ComandoSimulatoreFermo(etichetta: "Anni già fatti con questo datore",
                                               valore: interoFacoltativo(b.anniServizio, Console.servizio),
                                               unita: "anni", intervallo: Console.servizio, passo: 1)
                            .equatable()
                        ComandoSimulatoreFermo(etichetta: "TFR già maturato in azienda",
                                               valore: facoltativo(b.tfrMaturato, Console.maturato), unita: "€",
                                               intervallo: Console.maturato, passo: M.passoMaturato, fineCursore: M.fineMaturato)
                            .equatable()
                        notaComando(e?.maturatoStimato == true
                                    ? "Stimato dagli anni: \(Formati.euro(e?.tfrMaturato ?? 0)). Conta solo per l'aliquota" : nil)
                        scelta("Dipendenti dell'azienda") {
                            SegmentiAnalisiFermi(opzioni: [(false, "Meno di \(RegoleTFR.dipendentiTesoreria)"),
                                                           (true, "\(RegoleTFR.dipendentiTesoreria) o più")],
                                                 selezione: vero(b.aziendaGrande))
                                .equatable()
                        }
                        scelta("Iscritto all'INPS prima del 29/4/1993") {
                            SegmentiAnalisiFermi(opzioni: [(false, "No"), (true, "Sì")], selezione: vero(b.vecchioIscritto))
                                .equatable()
                        }
                        if i.vecchioIscritto == true {
                            ComandoSimulatoreFermo(etichetta: "TFR conferito al fondo",
                                                   valore: Binding(get: { b.wrappedValue.quotaConferitaEffettiva },
                                                                   set: { b.wrappedValue.quotaConferita = $0 }),
                                                   unita: "%", intervallo: Console.conferita, passo: M.passoConferita)
                                .equatable()
                        }
                        ComandoSimulatoreFermo(etichetta: "Quota di TFR sulla retribuzione",
                                               valore: Binding(get: { b.wrappedValue.quotaTFR ?? RegoleTFR.quotaAnnua },
                                                               set: { v in
                                                                   b.wrappedValue.quotaTFR = abs(v - RegoleTFR.quotaAnnua) < M.passoQuota / 2 ? nil : v
                                                               }),
                                               unita: "%", intervallo: Console.quota, passo: M.passoQuota, decimali: 2)
                            .equatable()
                    }
                }
                filo
                gruppo("Fondo") {
                    Group {
                        scelta("Rendimento del fondo") {
                            SegmentiAnalisiFermi(opzioni: [(true, "Netto (COVIP)"), (false, "Lordo")], selezione: baseNetta(b))
                                .equatable()
                        }
                        ComandoSimulatoreFermo(etichetta: i.rendimentoNetto ? "Rendimento netto del fondo" : "Rendimento lordo del fondo",
                                               valore: b.rendimentoFondo, unita: "%",
                                               intervallo: Console.rendimento, passo: Console.passo, decimali: 1)
                            .equatable()
                        notaComando(i.rendimentoNetto
                                    ? "Già tolti costi e imposta, come nei dati COVIP e nelle schede"
                                    : "Prisma toglie costi (ISC) e imposta sui rendimenti")
                        if !i.rendimentoNetto {
                            ComandoSimulatoreFermo(etichetta: "Costi del fondo (ISC)", valore: b.costoFondo, unita: "%",
                                                   intervallo: Console.costo, passo: Console.passoCosto, decimali: 2)
                                .equatable()
                            ComandoSimulatoreFermo(etichetta: "Parte in titoli di Stato",
                                                   valore: facoltativo(b.titoliStatoFondo, Console.titoliStato), unita: "%",
                                                   intervallo: Console.titoliStato, passo: 1)
                                .equatable()
                        }
                    }
                    Group {
                        ComandoSimulatoreFermo(etichetta: "Contributo del cliente", valore: b.contributoLavoratore, unita: "%",
                                               intervallo: Console.contributo, passo: Console.passo, decimali: 1)
                            .equatable()
                        ComandoSimulatoreFermo(etichetta: "Contributo del datore", valore: b.contributoDatore, unita: "%",
                                               intervallo: Console.contributo, passo: Console.passo, decimali: 1)
                            .equatable()
                        notaComando(i.contributoDatore > 0 && i.contributoLavoratore <= 0
                                    ? "Di solito il datore versa solo se versa anche il cliente" : nil, avviso: true)
                        ComandoSimulatoreFermo(etichetta: "Anni già nella previdenza", valore: intero(b.anniPartecipazione, Console.partecipazione),
                                               unita: "anni", intervallo: Console.partecipazione, passo: 1)
                            .equatable()
                    }
                }
                filo
                gruppo("Fisco") {
                    scelta("Aliquota del TFR in azienda") {
                        SegmentiAnalisiFermi(opzioni: [(false, "Calcolata"), (true, "La indico io")], selezione: aliquotaAMano(b))
                            .equatable()
                    }
                    if i.aliquotaTFR != nil {
                        ComandoSimulatoreFermo(etichetta: "Aliquota della tassazione separata",
                                               valore: Binding(get: { b.wrappedValue.aliquotaTFR ?? 0 },
                                                               set: { b.wrappedValue.aliquotaTFR = min(max($0, Console.aliquota.lowerBound), Console.aliquota.upperBound) }),
                                               unita: "%", intervallo: Console.aliquota, passo: Console.passo, decimali: 1)
                            .equatable()
                    }
                    if i.contributoLavoratore > 0 {
                        scelta("Costo dei contributi valutato al") {
                            SegmentiAnalisiFermi(opzioni: [(false, "Inflazione"), (true, "Un tasso mio")], selezione: tassoAMano(b))
                                .equatable()
                        }
                        if i.tassoAlternativo != nil {
                            ComandoSimulatoreFermo(etichetta: "Rendimento netto alternativo",
                                                   valore: Binding(get: { b.wrappedValue.tassoAlternativo ?? 0 },
                                                                   set: { b.wrappedValue.tassoAlternativo = $0 }),
                                                   unita: "%", intervallo: Console.tasso, passo: Console.passo, decimali: 1)
                                .equatable()
                        }
                    }
                }
                Button {
                    bozza = nil
                    clienteBozza = nil
                    stato.ripartiTFR(cliente)
                } label: {
                    Label("Riparti dai dati del cliente", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.appleSobrio)
                .help("Toglie tutte le ipotesi salvate: retribuzione, anni, contributi, fondo, canale e aliquota ripartono dal dossier")
            }
            .padding(M.margineConsole)
        }
    }

    private var filo: some View {
        Rectangle().fill(S.filo).frame(height: Tema.Misura.filo)
    }

    /// Un gruppo della console con il suo titolo.
    private func gruppo<C: View>(_ titolo: String, @ViewBuilder _ contenuto: () -> C) -> some View {
        VStack(alignment: .leading, spacing: M.spazioGruppo) {
            Text(titolo)
                .carattereApple(S.gruppo)
                .foregroundColor(S.coloreGruppo)
                .padding(.bottom, M.spazioTitoloGruppo)
            contenuto()
        }
    }

    /// La nota sotto un comando (un ripiego o una stima); niente se nil.
    @ViewBuilder
    private func notaComando(_ testo: String?, avviso: Bool = false) -> some View {
        if let testo {
            Text(testo)
                .carattereApple(A.notaComando)
                .foregroundColor(avviso ? A.avviso : A.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Un campo intero letto e scritto dal cursore, nell'intervallo dei comandi.
    private func intero(_ b: Binding<Int>, _ r: ClosedRange<Double>) -> Binding<Double> {
        Binding(get: { Double(b.wrappedValue) },
                set: { b.wrappedValue = Int(min(max($0, r.lowerBound), r.upperBound).rounded()) })
    }

    /// Un intero facoltativo: zero vuol dire «non indicato».
    private func interoFacoltativo(_ b: Binding<Int?>, _ r: ClosedRange<Double>) -> Binding<Double> {
        Binding(get: { Double(b.wrappedValue ?? 0) },
                set: { v in
                    let n = Int(min(max(v, r.lowerBound), r.upperBound).rounded())
                    b.wrappedValue = n > 0 ? n : nil
                })
    }

    /// Un numero facoltativo: zero vuol dire «non indicato».
    private func facoltativo(_ b: Binding<Double?>, _ r: ClosedRange<Double>) -> Binding<Double> {
        Binding(get: { b.wrappedValue ?? 0 },
                set: { v in
                    let x = min(max(v, r.lowerBound), r.upperBound)
                    b.wrappedValue = x > 0 ? x : nil
                })
    }

    /// Un sì/no facoltativo: nil vale «no».
    private func vero(_ b: Binding<Bool?>) -> Binding<Bool> {
        Binding(get: { b.wrappedValue == true }, set: { b.wrappedValue = $0 ? true : nil })
    }

    /// Netto o lordo: cambiando base il rendimento si converte, così il risultato non salta.
    private func baseNetta(_ b: Binding<IpotesiTFR>) -> Binding<Bool> {
        Binding(get: { b.wrappedValue.rendimentoNetto },
                set: { netta in
                    var i = b.wrappedValue
                    guard i.rendimentoNetto != netta else { return }
                    let r = netta ? MotoreTFR.rendimentoNetto(i, i.rendimentoFondo)
                                  : MotoreTFR.lordoEquivalente(i, netto: i.rendimentoFondo)
                    let limiti = IpotesiTFR.Limiti.rendimentoFondo
                    i.rendimentoFondo = min(max((r * 10).rounded() / 10, limiti.lowerBound), limiti.upperBound)
                    i.rendimentoNetto = netta
                    b.wrappedValue = i
                })
    }

    /// «Calcolata» o «La indico io»: passando a mano si parte dall'aliquota che Prisma calcola.
    private func aliquotaAMano(_ b: Binding<IpotesiTFR>) -> Binding<Bool> {
        Binding(get: { b.wrappedValue.aliquotaTFR != nil },
                set: { aMano in
                    var i = b.wrappedValue
                    if aMano {
                        guard i.aliquotaTFR == nil else { return }
                        let calcolata = MotoreTFR.calcola(i)?.azienda.aliquota ?? 0
                        i.aliquotaTFR = (calcolata * 10).rounded() / 10
                    } else {
                        i.aliquotaTFR = nil
                    }
                    b.wrappedValue = i
                })
    }

    /// «Inflazione» o «Un tasso mio»: passando a mano si parte dall'inflazione.
    private func tassoAMano(_ b: Binding<IpotesiTFR>) -> Binding<Bool> {
        Binding(get: { b.wrappedValue.tassoAlternativo != nil },
                set: { aMano in
                    var i = b.wrappedValue
                    i.tassoAlternativo = aMano ? (i.tassoAlternativo ?? i.inflazione) : nil
                    b.wrappedValue = i
                })
    }

    private func scelta<C: View>(_ etichetta: String, @ViewBuilder _ contenuto: () -> C) -> some View {
        VStack(alignment: .leading, spacing: M.spazioScelta) {
            Text(etichetta)
                .carattereApple(S.etichettaScelta)
                .foregroundColor(S.coloreEtichettaScelta)
            contenuto()
        }
    }

    // MARK: - Risultati

    private func risultati(_ i: IpotesiTFR, _ e: EsitoTFR?) -> some View {
        let senza = confrontaComunque ? nil : stato.senzaTFR(cliente)
        return ScrollView {
            VStack(alignment: .leading, spacing: M.spazioRisultati) {
                testata(i, disponibile: e != nil && senza == nil)
                if let tipo = senza {
                    nessunTFR(tipo)
                } else if let e {
                    // Il cliente dal dizionario dei dati ricavati (`clienteAttivo` rifiltra tutta la rubrica a ogni passo)
                    let testi = TestiTFR(e, cliente: stato.cliente(cliente))
                    fondoGiaConferito
                    pillole(testi)
                    ForEach(Array(testi.avvisi.enumerated()), id: \.offset) { _, a in
                        Text(a)
                            .carattereApple(A.nota)
                            .foregroundColor(A.avviso)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    principale(e, testi)
                    indicatori(e, testi)
                    Text(testi.frasePareggio + ".")
                        .carattereApple(A.pareggio)
                        .foregroundColor(A.coloreTesto)
                        .fixedSize(horizontal: false, vertical: true)
                    grafico(e)
                    dettaglio(e, testi)
                    piede
                } else {
                    Text("Indica la retribuzione utile al TFR per confrontare le due strade.")
                        .carattereApple(A.testo)
                        .foregroundColor(A.coloreNota)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(M.margineRisultati)
        }
    }

    /// Il cliente non è dipendente: niente TFR, niente confronto (si può fare lo stesso, per esempio se cambia lavoro).
    private func nessunTFR(_ tipo: TipoLavoratore) -> some View {
        VStack(alignment: .leading, spacing: M.spazioRisultati) {
            TitoloStrumento(occhiello: "TFR in azienda o nel fondo", titolo: "Nessun TFR da confrontare",
                            testo: "Nel dossier: \(tipo.nome.lowercased()). Il TFR spetta solo ai lavoratori dipendenti.")
            Button {
                confrontaComunque = true
            } label: {
                Label("Confronta lo stesso", systemImage: "arrow.right.circle")
            }
            .buttonStyle(.appleSobrio)
            .help("Per esempio se il cliente sta per diventare dipendente")
        }
    }

    /// Se il TFR va già in un fondo la scelta è fatta e non si revoca: il confronto è solo retrospettivo.
    @ViewBuilder
    private var fondoGiaConferito: some View {
        if let p = stato.fondoConTFR(cliente), let tfr = p.tfrConferito {
            Text("Il TFR va già in «\(p.nome)»: \(Formati.euro(tfr)) l'anno. La scelta non si revoca: il confronto mostra cosa è cambiato rispetto a lasciarlo in azienda.")
                .carattereApple(A.testo)
                .foregroundColor(A.avviso)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Le semplificazioni che possono cambiare la conclusione, sempre visibili.
    private func pillole(_ t: TestiTFR) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: M.spazioPillole) {
                ForEach(t.pillole, id: \.self) { Pillola(testo: $0, tono: .neutro) }
            }
        }
    }

    // MARK: Testata: canale, fondo, prospetto o report, uscite del PDF

    private func testata(_ i: IpotesiTFR, disponibile: Bool) -> some View {
        let nome = i.nomeFondo.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = legame
        let identita = HStack(spacing: M.spazioTestata) {
            // Il canale si cambia toccando l'etichetta
            Button {
                b.wrappedValue.canale = i.canale == .alleanza ? .indipendente : .alleanza
            } label: {
                EtichettaCanale(canale: i.canale, compatta: false)
            }
            .buttonStyle(.plain)
            .help("Canale della consulenza: tocca per passare ad Alleanza o a indipendente")
            Text(nome.isEmpty ? "Fondo pensione" : nome)
                .carattereApple(A.fondo)
                .foregroundColor(A.coloreNota)
                .lineLimit(1)
        }
        let documenti = SegmentiAnalisi(opzioni: [(false, "Prospetto"), (true, "Report")], selezione: $report).fixedSize()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: M.spazioTestata) {
                identita
                Spacer(minLength: M.spazioTestata)
                documenti
                pulsanti(disponibile)
            }
            VStack(alignment: .leading, spacing: M.spazioTestata) {
                HStack(spacing: M.spazioTestata) {
                    identita
                    Spacer(minLength: M.spazioTestata)
                    documenti
                }
                HStack(spacing: M.spazioTestata) {
                    Spacer(minLength: 0)
                    pulsanti(disponibile)
                }
            }
        }
    }

    private func pulsanti(_ disponibile: Bool) -> some View {
        HStack(spacing: M.spazioTestata) {
            if let id = archiviato {
                Button {
                    stato.documentoSelezionato = id
                    stato.apri(.documenti)
                } label: {
                    HStack(spacing: Tema.Misura.Componenti.spazioSimboloPulsante) {
                        Text("Archiviato in Documenti")
                        Image(systemName: "arrow.up.right")
                    }
                }
                .buttonStyle(.appleSobrio)
                .fixedSize()
            }
            Button {
                if let d = documento() { stato.presenta(d) }
            } label: {
                Label("Presenta", systemImage: "play.fill")
            }
            .buttonStyle(.apple)
            .fixedSize()
            .help("Mostra il documento a tutto schermo, una pagina alla volta, in modalità cliente")
            Button {
                if let d = documento(), let dati = pdf(d) {
                    daSalvare = PDFDaSalvare(dati: dati, nome: StampaCarta.nomeFile(d), cliente: stato.clienteAttivo)
                }
            } label: {
                Label("Salva PDF…", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.apple)
            .fixedSize()
            Button {
                if let d = documento(), let dati = pdf(d) { archiviato = stato.archiviaProspetto(dati, documento: d) }
            } label: {
                Label("Archivia nei Documenti", systemImage: "archivebox")
            }
            .buttonStyle(.apple)
            .fixedSize()
        }
        .disabled(!disponibile)
    }

    /// Il documento delle ipotesi sul tavolo: prima si salva la bozza, perché il documento legge l'archivio.
    private func documento() -> DocumentoStampabile? {
        salvaBozza()
        guard let d = stato.documentoTFR(report: report) else {
            stato.mostraAvviso("Indica la retribuzione utile al TFR per preparare il documento.")
            return nil
        }
        return d
    }

    private func pdf(_ d: DocumentoStampabile) -> Data? {
        guard !modoIstantanea else { return nil }
        let dati = StampaCarta.pdf(d)
        if dati == nil { stato.mostraAvviso("Non sono riuscito a creare il PDF.") }
        return dati
    }

    // MARK: La cifra principale: la differenza e le barre affiancate

    private func principale(_ e: EsitoTFR, _ t: TestiTFR) -> some View {
        let n = e.ipotesi.anni
        return VStack(alignment: .leading, spacing: M.spazioCifra) {
            Text("TFR FUTURO, NETTO, TRA \(n) \(n == 1 ? "ANNO" : "ANNI")")
                .carattereApple(A.occhiello)
                .foregroundColor(A.coloreOcchiello)
            // La differenza si conta fino al valore, con il testo di sempre («+ 16.115 €»)
            NumeroCheConta(e.differenza, formato: .personalizzato({ CifreDoc.euroSegno($0) }))
                .carattereApple(A.cifra)
                .foregroundColor(A.segno(e.differenza))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(t.titoloConfronto + " · \(CifreDoc.euroSegno(e.fondo.reale - e.azienda.reale)) in euro di oggi")
                .carattereApple(A.notaCifra)
                .foregroundColor(A.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
            BarreStradeTFR(e: e)
                .padding(.top, M.spazioBarre)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Indicatori: le aliquote a confronto, il capitale e il vantaggio

    /// Tre tessere: cifra grande, etichetta e al massimo una riga breve; il resto nell'aiuto al passaggio del mouse.
    private func indicatori(_ e: EsitoTFR, _ t: TestiTFR) -> some View {
        FasciaKPI {
            TesseraAliquoteTFR(e: e)
            tesseraCapitale(e)
            if let d = e.differenzaContributi {
                TesseraTFR(titolo: TestiTFR.vantaggioContributi, valore: CifreDoc.euroSegno(d),
                           nota: "Di tasca sua \(CifreDoc.euro(e.tascaPropria))",
                           colore: A.segno(d), tinta: A.tintaVantaggio(d))
                    .help("Di tasca sua: i contributi del cliente meno l'IRPEF risparmiata. " + (t.pareggioContributiBreve ?? ""))
            }
        }
    }

    private func tesseraCapitale(_ e: EsitoTFR) -> some View {
        let p = e.fondo.prestazione
        let nota: String
        if let p, !p.tuttoCapitale {
            nota = "Poi \(CifreDoc.euro(p.renditaMensile)) al mese di rendita"
        } else {
            nota = "Tutto: la rendita sarebbe piccola"
        }
        return TesseraTFR(titolo: "Subito in capitale", valore: CifreDoc.euro(p?.capitale ?? e.fondo.netto), nota: nota)
            .help(TestiTFR.testoPrestazione(e.fondo))
    }

    // MARK: Grafico

    private func grafico(_ e: EsitoTFR) -> some View {
        var serie: [GraficoProiezione.Serie] = [
            .init(id: "azienda", punti: e.puntiAzienda, colore: K.azienda),
            .init(id: "fondo", punti: e.puntiFondo, colore: K.fondo, principale: true),
        ]
        if let c = e.puntiFondoContributi { serie.append(.init(id: "contributi", punti: c, colore: K.fondoContributi)) }
        return VStack(alignment: .leading, spacing: M.spazioScelta) {
            Text("Come crescono, prima delle imposte all'uscita")
                .carattereApple(A.etichettaSezione)
                .foregroundColor(A.coloreNota)
            GraficoProiezione(serie: serie)
            HStack(spacing: M.spazioLegenda) {
                LegendaLinea(colore: K.azienda, testo: TestiTFR.stradaAzienda)
                LegendaLinea(colore: K.fondo, testo: TestiTFR.stradaFondo)
                if e.puntiFondoContributi != nil { LegendaLinea(colore: K.fondoContributi, testo: TestiTFR.stradaContributi) }
                LegendaLinea(colore: K.quote, testo: "Quote di TFR", tratteggio: true)
            }
        }
    }

    // MARK: Dettaglio: perché, contributi, tabella, metodo

    private func dettaglio(_ e: EsitoTFR, _ t: TestiTFR) -> some View {
        VStack(alignment: .leading, spacing: M.spazioRisultati) {
            Button { mostraDettaglio.toggle() } label: {
                Label(mostraDettaglio ? "Nascondi il dettaglio" : "Dettaglio: anno per anno e metodo",
                      systemImage: mostraDettaglio ? "chevron.up" : "chevron.down")
            }
            .buttonStyle(.appleSobrio)
            if mostraDettaglio {
                Text(t.perchePareggio)
                    .carattereApple(A.testo)
                    .foregroundColor(A.coloreTesto)
                    .fixedSize(horizontal: false, vertical: true)
                if let c = t.testoContributi {
                    Text(c)
                        .carattereApple(A.testo)
                        .foregroundColor(A.coloreTesto)
                        .fixedSize(horizontal: false, vertical: true)
                }
                tabella(e, eta: t.eta)
                NotaMetodo(testo: TestiTFR.metodo.joined(separator: "\n"), titolo: "Come si calcola")
                NotaMetodo(testo: TestiTFR.semplificazioni.joined(separator: "\n"), titolo: "Semplificazioni")
            }
        }
    }

    // MARK: Tabella anno per anno

    /// Gli anni della tabella: tutti fino a 15, altrimenti il primo, uno ogni 5 e l'ultimo.
    static func anniTabella(_ n: Int) -> [Int] {
        guard n > M.anniTabellaCompleta else { return Array(1...max(1, n)) }
        var anni = [1]
        anni += stride(from: M.passoTabella, through: n, by: M.passoTabella).filter { $0 > 1 }
        if anni.last != n { anni.append(n) }
        return anni
    }

    private func tabella(_ e: EsitoTFR, eta: Int?) -> some View {
        let righe = Self.anniTabella(e.anni.count).compactMap { a in e.anni.first { $0.anno == a } }
        let contributi = e.conContributi
        let l = M.colonnaTabella
        return VStack(alignment: .leading, spacing: M.spazioScelta) {
            Text("Anno per anno, prima delle imposte all'uscita")
                .carattereApple(A.etichettaSezione)
                .foregroundColor(A.coloreNota)
            TabellaStrumento {
                CellaTesta(testo: "Anno", larghezza: M.colonnaAnnoTabella)
                CellaTesta(testo: "Retribuzione", destra: true)
                CellaTesta(testo: "Quota TFR", larghezza: l, destra: true)
                CellaTesta(testo: "In azienda", larghezza: l, destra: true)
                CellaTesta(testo: "Nel fondo", larghezza: l, destra: true)
                if contributi { CellaTesta(testo: TestiTFR.stradaContributi, larghezza: l, destra: true) }
            } righe: {
                ForEach(Array(righe.enumerated()), id: \.element.id) { indice, a in
                    RigaStrumento(indice: indice) {
                        CellaTabella(testo: eta.map { "\(a.anno) · \($0 + a.anno) anni" } ?? "\(a.anno)", larghezza: M.colonnaAnnoTabella)
                        CellaTabella(testo: Formati.euro(a.retribuzione), destra: true)
                        CellaTabella(testo: Formati.euro(a.quota), larghezza: l, destra: true)
                        CellaTabella(testo: Formati.euro(a.azienda), larghezza: l, destra: true)
                        CellaTabella(testo: Formati.euro(a.fondo), larghezza: l, destra: true)
                        if contributi { CellaTabella(testo: Formati.euro(a.fondoContributi), larghezza: l, destra: true) }
                    }
                }
            }
        }
    }

    // MARK: Da sapere

    private var piede: some View {
        VStack(alignment: .leading, spacing: M.spazioRisultati) {
            Text(TestiTFR.daSapere[0])
                .carattereApple(A.nota)
                .foregroundColor(A.avviso)
                .fixedSize(horizontal: false, vertical: true)
            NotaMetodo(testo: TestiTFR.avvertenza)
        }
    }
}

/// Le strade affiancate, nette alla pensione: TFR in azienda, nel fondo, fondo con contributi. Scala comune che
/// parte dallo zero (la linea a sinistra); la cifra e la differenza dal TFR in azienda stanno subito dopo la fine
/// della barra. Nel fondo la barra distingue la parte ritirabile in capitale (piena) da quella in rendita (più chiara).
private struct BarreStradeTFR: View {
    let e: EsitoTFR

    private typealias M = Tema.Misura.TFR
    private typealias K = Tema.Colore.TFR
    private typealias F = Tema.Testo.TFR
    private typealias A = Tema.Apple.ConfrontoTFR
    private typealias S = Tema.Apple.Strumenti360

    private var massimo: Double {
        max(e.azienda.netto, e.fondo.netto, e.fondoContributi?.netto ?? 0, 1)
    }

    /// La strada con una parte in rendita, per la legenda (con i contributi quella, altrimenti il fondo).
    private var conRendita: (strada: StradaTFR, colore: Color)? {
        if let c = e.fondoContributi, Self.haRendita(c) { return (c, K.fondoContributi) }
        if Self.haRendita(e.fondo) { return (e.fondo, K.fondo) }
        return nil
    }

    private static func haRendita(_ s: StradaTFR) -> Bool {
        guard let p = s.prestazione else { return false }
        return !p.tuttoCapitale
    }

    var body: some View {
        VStack(alignment: .leading, spacing: M.spazioBarre) {
            // Righe senza spazio tra loro: la linea dello zero resta continua
            VStack(alignment: .leading, spacing: 0) {
                riga(TestiTFR.stradaAzienda, e.azienda, colore: K.azienda, differenza: nil)
                riga(TestiTFR.stradaFondo, e.fondo, colore: K.fondo, differenza: e.differenza)
                if let c = e.fondoContributi {
                    riga(TestiTFR.stradaContributi, c, colore: K.fondoContributi, differenza: c.netto - e.azienda.netto)
                }
            }
            if let r = conRendita {
                legenda(r.strada, colore: r.colore)
                    .padding(.leading, M.etichettaBarra + Tema.Misura.filo)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func riga(_ etichetta: String, _ s: StradaTFR, colore: Color, differenza: Double?) -> some View {
        HStack(spacing: 0) {
            Text(etichetta)
                .carattereApple(A.etichettaBarra)
                .foregroundColor(A.coloreTesto)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: M.etichettaBarra, alignment: .leading)
            Rectangle()
                .fill(A.zero)
                .frame(width: Tema.Misura.filo)
            GeometryReader { geo in
                let spazio = max(0, geo.size.width - M.riservaCifraBarra)
                let lunghezza = max(M.barraMinima, spazio * CGFloat(max(0, s.netto) / massimo))
                HStack(spacing: M.spazioCifraBarra) {
                    barra(s, colore: colore, lunghezza: lunghezza)
                    Text(Formati.euro(s.netto))
                        .carattereApple(A.cifraBarra)
                        .foregroundColor(A.coloreTesto)
                        .lineLimit(1)
                        .fixedSize()
                    if let d = differenza { capsulaDifferenza(d) }
                    Spacer(minLength: 0)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            }
        }
        .frame(height: M.rigaBarra)
    }

    /// La barra di una strada, lunga `lunghezza`: piena la parte in capitale, più chiara quella in rendita.
    private func barra(_ s: StradaTFR, colore: Color, lunghezza: CGFloat) -> some View {
        let quota = quotaCapitale(s)
        let stacco: CGFloat = quota < 1 ? M.staccoBarra : 0
        let utile = max(0, lunghezza - stacco)
        return HStack(spacing: stacco) {
            RoundedRectangle(cornerRadius: M.raggioBarra, style: .continuous)
                .fill(colore)
                .frame(width: utile * CGFloat(quota))
            if quota < 1 {
                RoundedRectangle(cornerRadius: M.raggioBarra, style: .continuous)
                    .fill(colore.opacity(M.opacitaRendita))
                    .frame(width: utile * CGFloat(1 - quota))
            }
        }
        .frame(width: lunghezza, height: M.barra, alignment: .leading)
    }

    private func quotaCapitale(_ s: StradaTFR) -> Double {
        guard let p = s.prestazione, s.netto > 0 else { return 1 }
        return min(max(p.capitale / s.netto, 0), 1)
    }

    /// Quanto resta in più (o in meno) rispetto al TFR in azienda, nel colore del segno.
    private func capsulaDifferenza(_ d: Double) -> some View {
        Text(CifreDoc.euroSegno(d))
            .carattereApple(A.differenzaBarra)
            .foregroundColor(A.segno(d))
            .lineLimit(1)
            .padding(M.margineDifferenza)
            .background { Capsule(style: .continuous).fill(A.fondoDifferenza(d)) }
            .fixedSize()
            .help("Rispetto al TFR in azienda")
    }

    /// Capitale e rendita con i quadratini del colore della barra, e come arriva il netto.
    private func legenda(_ s: StradaTFR, colore: Color) -> some View {
        VStack(alignment: .leading, spacing: M.spazioQuadratino) {
            HStack(spacing: M.spazioLegenda) {
                quadratino(colore, "In capitale")
                quadratino(colore.opacity(M.opacitaRendita), "In rendita")
            }
            Text(TestiTFR.testoPrestazione(s))
                .carattereApple(A.legendaBarre)
                .foregroundColor(A.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, M.spazioCifraBarra)
    }

    private func quadratino(_ colore: Color, _ testo: String) -> some View {
        HStack(spacing: M.spazioQuadratino) {
            RoundedRectangle(cornerRadius: M.raggioQuadratino, style: .continuous)
                .fill(colore)
                .frame(width: M.quadratinoLegenda, height: M.quadratinoLegenda)
            Text(testo)
                .carattereApple(A.legendaBarre)
                .foregroundColor(A.coloreNota)
                .fixedSize()
        }
    }
}

/// Una tessera sotto le barre: etichetta, cifra grande e una riga breve che va a capo invece di troncarsi.
/// `tinta` evidenzia la tessera (il vantaggio).
private struct TesseraTFR: View {
    let titolo: String
    let valore: String
    let nota: String
    var colore: Color = Tema.Apple.ConfrontoTFR.coloreTesto
    var tinta: Color? = nil

    private typealias M = Tema.Misura.TFR
    private typealias K = Tema.Colore.TFR
    private typealias F = Tema.Testo.TFR
    private typealias A = Tema.Apple.ConfrontoTFR
    private typealias S = Tema.Apple.Strumenti360

    var body: some View {
        VStack(alignment: .leading, spacing: M.spazioTessera) {
            Text(titolo)
                .carattereApple(A.titoloTessera)
                .foregroundColor(A.coloreNota)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(valore)
                .carattereApple(A.valoreTessera)
                .foregroundColor(colore)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(nota)
                .carattereApple(A.notaTessera)
                .foregroundColor(A.coloreNota)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(A.paddingTessera)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            // La tinta del vantaggio sopra la tessera del tema Apple
            if let tinta {
                RoundedRectangle(cornerRadius: A.raggioTessera, style: .continuous).fill(tinta)
            }
        }
        .superficieApple(A.tessera)
    }
}

/// Le due aliquote all'uscita a confronto: «28,4% → 10,5%» e due barre sulla stessa scala, che parte da zero.
private struct TesseraAliquoteTFR: View {
    let e: EsitoTFR

    private typealias M = Tema.Misura.TFR
    private typealias K = Tema.Colore.TFR
    private typealias F = Tema.Testo.TFR
    private typealias A = Tema.Apple.ConfrontoTFR
    private typealias S = Tema.Apple.Strumenti360

    private var aiuto: String {
        let azienda = e.ipotesi.aliquotaTFR == nil
            ? "tassazione separata, \(e.anniServizioTotali) anni di servizio"
            : "indicata a mano"
        return "In azienda: \(azienda). Nel fondo: dopo \(e.anniPartecipazioneFinali) anni di partecipazione."
    }

    var body: some View {
        let a = e.azienda.aliquota
        let f = e.fondo.aliquota
        let massimo = max(a, f, 1)
        return VStack(alignment: .leading, spacing: M.spazioTessera) {
            Text("Imposta all'uscita")
                .carattereApple(A.titoloTessera)
                .foregroundColor(A.coloreNota)
            confronto(a, f)
            VStack(alignment: .leading, spacing: M.spazioAliquote) {
                barra("In azienda", a / massimo, colore: K.azienda)
                barra("Nel fondo", f / massimo, colore: K.fondo)
            }
            .padding(.top, M.spazioTessera)
        }
        .padding(A.paddingTessera)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(A.tessera)
        .help(aiuto)
    }

    /// «28,4% → 10,5%»: l'aliquota del fondo nel colore del vantaggio.
    private func confronto(_ a: Double, _ f: Double) -> some View {
        let prima = Text(CifreDoc.percento(a, decimali: 1)).foregroundColor(A.coloreNota)
        let freccia = Text("  →  ").foregroundColor(A.coloreNota)
        let dopo = Text(CifreDoc.percento(f, decimali: 1)).foregroundColor(A.segno(a - f))
        return (prima + freccia + dopo)
            .carattereApple(A.valoreTessera)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    private func barra(_ etichetta: String, _ quota: Double, colore: Color) -> some View {
        HStack(spacing: M.spazioCifraBarra) {
            Text(etichetta)
                .carattereApple(A.etichettaAliquota)
                .foregroundColor(A.coloreNota)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: M.etichettaAliquota, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(A.binario)
                    Capsule()
                        .fill(colore)
                        .frame(width: max(M.barraAliquota, geo.size.width * CGFloat(min(max(quota, 0), 1))))
                }
            }
            .frame(height: M.barraAliquota)
        }
    }
}
