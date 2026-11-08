#if os(macOS)
// Solo Mac: la prova della fluidità usa AppKit e gira in un processo a parte.
import AppKit
import SwiftUI

/// «Misura la velocità su questo Mac» e «Misura Vera» (Impostazioni › Strumenti › Velocità, giro 0 di «Prisma
/// istantaneo»).
///
/// La velocità: la stessa prova della fluidità del workflow (`Prisma --prova-fluidita`, ProvaFluidita.swift), con i
/// clienti di prova (5 e 200), lanciata dall'app in un processo a parte con lo stesso eseguibile. Così l'app resta
/// libera mentre la prova misura (qualche minuto) e la prova lavora come sul runner: stato non persistente, shell
/// fuori schermo, e Application Support sostituita da una cartella vuota che alla fine deve essere ancora vuota
/// (`Archivio.cartellaDiProva`): l'archivio dell'utente non si tocca. Alla fine la tabella (azione, tempo sul thread
/// principale) e «Copia», che copia la tabella intera in Markdown.
///
/// Vera: MisuraVera con il fornitore delle impostazioni di Vera (FornitoriVera.crea, solo indirizzi locali).
///
/// Lo stato è un oggetto piccolo a sé, osservato solo dal gruppo Velocità: le misure non fanno ridisegnare il resto
/// dell'app (la strada proposta in Design/velocita-proposta.md). Si usa dal thread principale (pulsanti e istantanee):
/// le risposte del processo e di Vera ci tornano da sole.
final class MisuraVelocita: ObservableObject {
    static let condivisa = MisuraVelocita()
    /// L'ancora del gruppo in Impostazioni › Strumenti (`StatoShell.ancoraImpostazioni`).
    static let ancora = "impostazioni-velocita"

    /// Una riga della tabella: lo scenario, l'azione e i tempi come li scrive la prova.
    struct Riga: Equatable, Identifiable {
        var scenario: String
        var azione: String
        /// Mediana dell'aggiornamento (azione, run loop e impaginazione): il lavoro di Prisma sul thread principale.
        /// Il disegno completo (cacheDisplay fatto dalla CPU, 1,5-3 s per qualunque azione) resta nella tabella copiata.
        var tempo: String
        /// L'aggiornamento del giro di riscaldamento («—» se non c'è).
        var primaVolta: String
        var id: String { scenario + "·" + azione }
    }

    /// A che punto è la misura della velocità (nil se ferma).
    @Published private(set) var avanzamento: String?
    @Published private(set) var righe: [Riga] = []
    /// La tabella intera scritta dalla prova (Markdown), per «Copia».
    @Published private(set) var tabella: String?
    /// Un problema della misura (interrotta, verifiche non riuscite, prova non partita).
    @Published private(set) var problema: String?

    @Published private(set) var avanzamentoVera: String?
    @Published private(set) var esitoVera: MisuraVera.Esito?

    private var processo: Process?
    private var interrotta = false
    private var ricevuto = ""
    private var compitoVera: Task<Void, Never>?

    var inCorso: Bool { avanzamento != nil }
    var veraInCorso: Bool { avanzamentoVera != nil }

    /// Gli argomenti del processo: la prova della fluidità del workflow, che isola da sé l'archivio.
    static func argomenti(uscita: URL) -> [String] {
        ["--prova-fluidita", uscita.path]
    }

    // MARK: Velocità

    /// Avvia la misura o, se è in corso, la interrompe.
    func alterna() {
        if let processo {
            interrotta = true
            processo.terminate()
            return
        }
        guard let eseguibile = Bundle.main.executableURL else {
            problema = "Non trovo il programma di Prisma per far partire la prova."
            return
        }
        let uscita = FileManager.default.temporaryDirectory.appendingPathComponent("prisma-velocita-\(UUID().uuidString).md")
        let p = Process()
        p.executableURL = eseguibile
        p.arguments = Self.argomenti(uscita: uscita)
        let tubo = Pipe()
        p.standardOutput = tubo
        p.standardError = FileHandle.nullDevice
        tubo.fileHandleForReading.readabilityHandler = { [weak self] maniglia in
            let dati = maniglia.availableData
            guard !dati.isEmpty else {
                maniglia.readabilityHandler = nil
                return
            }
            let testo = String(decoding: dati, as: UTF8.self)
            DispatchQueue.main.async { self?.ricevi(testo) }
        }
        p.terminationHandler = { [weak self] finito in
            let codice = finito.terminationStatus
            DispatchQueue.main.async { self?.concludi(codice: codice, uscita: uscita) }
        }
        righe = []
        tabella = nil
        problema = nil
        ricevuto = ""
        interrotta = false
        avanzamento = "Preparo la prova…"
        do {
            try p.run()
            processo = p
        } catch {
            avanzamento = nil
            problema = "La prova non è partita: \(error.localizedDescription)"
        }
    }

    /// Le righe della prova mentre arrivano: l'azione in corso diventa l'avanzamento.
    private func ricevi(_ testo: String) {
        ricevuto += testo
        var righeComplete = ricevuto.components(separatedBy: "\n")
        ricevuto = righeComplete.removeLast()
        if let ultima = righeComplete.last(where: { $0.hasPrefix(ProvaFluidita.prefissoPasso) }) {
            avanzamento = "Misuro · " + ultima.dropFirst(ProvaFluidita.prefissoPasso.count) + "…"
        }
    }

    private func concludi(codice: Int32, uscita: URL) {
        processo = nil
        avanzamento = nil
        defer { try? FileManager.default.removeItem(at: uscita) }
        if interrotta {
            problema = "Misura interrotta."
            return
        }
        guard let testo = try? String(contentsOf: uscita, encoding: .utf8) else {
            problema = "La prova non ha scritto la tabella (codice \(codice))."
            return
        }
        tabella = testo
        righe = Self.leggi(testo)
        if codice != 0 {
            problema = "Alcune verifiche della prova non sono riuscite: i tempi qui sotto valgono lo stesso."
        }
    }

    /// Le righe della tabella Markdown della prova (Scenario | Azione | Mediana | Massimo | Aggiornamento | Disegno |
    /// Prima volta | …).
    static func leggi(_ testo: String) -> [Riga] {
        testo.components(separatedBy: "\n").compactMap { riga in
            guard riga.hasPrefix("| "), !riga.hasPrefix("| Scenario |") else { return nil }
            let celle = riga.split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .dropFirst().dropLast()
            let c = Array(celle)
            guard c.count >= 7 else { return nil }
            return Riga(scenario: c[0], azione: c[1], tempo: c[4], primaVolta: c[6])
        }
    }

    // MARK: Vera

    func misuraVera(_ vera: ImpostazioniVera) {
        guard compitoVera == nil else { return }
        esitoVera = nil
        avanzamentoVera = "Controllo il modello…"
        let fornitore = FornitoriVera.crea(vera)
        let opzioni = MisuraVera.opzioni(vera)
        compitoVera = Task { @MainActor [weak self] in
            let esito = await MisuraVera.esegui(fornitore: fornitore, opzioni: opzioni) { testo in
                Task { @MainActor in
                    if self?.avanzamentoVera != nil { self?.avanzamentoVera = testo }
                }
            }
            self?.esitoVera = esito
            self?.avanzamentoVera = nil
            self?.compitoVera = nil
        }
    }

    // MARK: Istantanee

    /// Le misure già fatte, per le istantanee: la tabella Markdown della prova e i tempi di Vera.
    static func diProva(tabella: String, vera: MisuraVera.Esito?) -> MisuraVelocita {
        let m = MisuraVelocita()
        m.tabella = tabella
        m.righe = leggi(tabella)
        m.esitoVera = vera
        return m
    }

    /// DATI DI PROVA DICHIARATI per le istantanee (non sono misure): poche righe nel formato della prova e i tempi di
    /// Vera della prova con l'orologio finto (ProvaMisuraVera).
    static var diProvaIstantanea: MisuraVelocita {
        let righe = [
            ("5 clienti", "avvio (stato, dati e primo disegno)", 200, 180),
            ("5 clienti", "apri Posizioni", 120, 260),
            ("5 clienti", "modifica una nota (un tasto)", 60, 70),
            ("5 clienti", "Luce · apri il prisma di luce", 90, 140),
            ("200 clienti", "apri Posizioni", 300, 420),
            ("200 clienti", "Luce · apri il radar", 150, 210),
        ]
        var tabella = ["### Fluidità (dati di prova)", "",
                       "| Scenario | Azione | Mediana | Massimo | Aggiornamento | Disegno | Prima volta | Corpi rivalutati | Avvisi StatoFinestre |",
                       "|---|---|---:|---:|---:|---:|---:|---:|---:|"]
        for (scenario, azione, tempo, prima) in righe {
            tabella.append("| \(scenario) | \(azione) | \(tempo) ms | \(tempo) ms | \(tempo) ms | — | \(prima) ms | — | — |")
        }
        var tempi = MisuraVera.Tempi(fornitore: "Ollama", modello: MotoreLocale.modelloPredefinito)
        tempi.caricamento = 2.5
        tempi.primaParolaDopoCaricamento = 0.8
        tempi.primaParola = 0.4
        tempi.parole = 5
        tempi.secondiScrittura = 2
        tempi.tokenAlSecondo = 20
        return diProva(tabella: tabella.joined(separator: "\n"), vera: .misurato(tempi))
    }

    // MARK: Copia

    static func copia(_ testo: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(testo, forType: .string)
    }
}

/// Il gruppo Velocità di Impostazioni › Strumenti: le due misure e, quando ci sono, le loro tabelle (nelle
/// istantanee quelle di prova di `StatoShell.misureIstantanea`).
struct GruppoVelocita: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoGruppoVelocita(misura: stato.misureIstantanea ?? MisuraVelocita.condivisa)
    }
}

private struct CorpoGruppoVelocita: View {
    @Environment(StatoShell.self) var stato
    @ObservedObject var misura: MisuraVelocita

    var body: some View {
        let _ = ContaCorpi.segna()
        let c = Tema.Colore.Impostazioni.self
        VStack(alignment: .leading, spacing: Tema.Misura.Impostazioni.spazioGruppi) {
            GruppoImpostazioni(titolo: "Velocità") {
                RigaImpostazione(titolo: "Misura la velocità su questo Mac",
                                 sottotitolo: misura.avanzamento ?? "La prova della fluidità con 5 e 200 clienti di prova",
                                 icona: IconaVetroImpostazioni(simbolo: "gauge.with.dots.needle.67percent", colori: c.rendimenti),
                                 aiuto: "La stessa prova della fluidità della build, su questo Mac: apre e chiude le app, cambia aspetto, modifica una nota… con i clienti di prova, in un processo a parte e senza toccare il tuo archivio. Dura qualche minuto; intanto puoi continuare a lavorare.") {
                    Button { misura.alterna() } label: {
                        Label(misura.inCorso ? "Interrompi" : "Misura", systemImage: misura.inCorso ? "stop.circle" : "gauge.with.dots.needle.33percent")
                    }
                    .buttonStyle(StilePulsanteRigaImpostazioni())
                }
                RigaImpostazione(titolo: "Misura Vera",
                                 sottotitolo: misura.avanzamentoVera ?? "Caricamento di Qwen, prima parola, parole al secondo",
                                 icona: IconaVetroImpostazioni(.app(.vera)),
                                 aiuto: "Libera e ricarica il modello di Vera sul Mac, poi le fa due volte la stessa domanda generica (nessun dato dei clienti): quanto ci mette a caricarsi, a dire la prima parola e quante parole scrive al secondo.",
                                 ultima: true) {
                    Button { misura.misuraVera(stato.dati.impostazioni.vera) } label: {
                        Label("Misura", systemImage: "stopwatch")
                    }
                    .buttonStyle(StilePulsanteRigaImpostazioni())
                    .disabled(misura.veraInCorso)
                }
            }
            if let p = misura.problema {
                NotaImpostazioni(p)
            }
            if !misura.righe.isEmpty, let tabella = misura.tabella {
                TabellaVelocita(righe: misura.righe, markdown: tabella)
            }
            if let esito = misura.esitoVera {
                switch esito {
                case .nonDisponibile(let motivo):
                    NotaImpostazioni("Vera non si può misurare: \(motivo)")
                case .misurato(let tempi):
                    TabellaTempiVera(tempi: tempi)
                }
            }
        }
    }
}

/// La tabella della velocità: per ogni scenario le azioni con il tempo del thread principale e la prima volta.
private struct TabellaVelocita: View {
    let righe: [MisuraVelocita.Riga]
    let markdown: String
    private typealias V = Tema.Apple.Impostazioni.Velocita

    private var scenari: [String] {
        var visti = Set<String>()
        return righe.map(\.scenario).filter { visti.insert($0).inserted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            IntestazioneTabellaVelocita(titolo: "Velocità su questo Mac", markdown: markdown)
            ForEach(Array(scenari.enumerated()), id: \.element) { i, scenario in
                Text(scenario)
                    .carattereApple(V.scenario)
                    .foregroundColor(V.coloreScenario)
                    .padding(.top, i == 0 ? 0 : V.sopraScenario)
                    .padding(.bottom, V.sottoScenario)
                RigaTabellaVelocita(voce: "Azione", valore: "Tempo", secondo: "Prima volta", intestazione: true)
                ForEach(righe.filter { $0.scenario == scenario }) { r in
                    RigaTabellaVelocita(voce: r.azione, valore: r.tempo, secondo: r.primaVolta)
                }
            }
            Text("Tempo = mediana del lavoro di Prisma sul thread principale (azione e impaginazione); prima volta = il primo giro. «Copia» copia la tabella completa, con il disegno.")
                .carattereApple(V.nota)
                .foregroundColor(V.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, V.sopraNota)
        }
        .padding(V.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(V.superficie, raggio: V.raggio)
    }
}

/// La tabella dei tempi di Vera.
private struct TabellaTempiVera: View {
    let tempi: MisuraVera.Tempi
    private typealias V = Tema.Apple.Impostazioni.Velocita

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            IntestazioneTabellaVelocita(titolo: "Tempi di Vera · \(tempi.modello)", markdown: MisuraVera.markdown(tempi))
            ForEach(MisuraVera.righe(tempi), id: \.voce) { r in
                RigaTabellaVelocita(voce: r.voce, valore: r.valore, secondo: nil)
            }
            Text(tempi.errore.map { "Problema durante le domande: \($0)" }
                 ?? "Due volte la stessa domanda generica, senza dati dei clienti: se la prima parola dopo il caricamento è molto più lenta, il modello si è ricaricato.")
                .carattereApple(V.nota)
                .foregroundColor(V.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, V.sopraNota)
        }
        .padding(V.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(V.superficie, raggio: V.raggio)
    }
}

private struct IntestazioneTabellaVelocita: View {
    let titolo: String
    let markdown: String
    private typealias V = Tema.Apple.Impostazioni.Velocita

    var body: some View {
        HStack(alignment: .center) {
            Text(titolo)
                .carattereApple(V.titolo)
                .foregroundColor(V.coloreTitolo)
                .lineLimit(1)
            Spacer(minLength: 0)
            Button { MisuraVelocita.copia(markdown) } label: { Label("Copia", systemImage: "doc.on.doc") }
                .buttonStyle(StilePulsanteRigaImpostazioni())
        }
        .padding(.bottom, V.sottoTitolo)
    }
}

private struct RigaTabellaVelocita: View {
    let voce: String
    let valore: String
    let secondo: String?
    var intestazione = false
    private typealias V = Tema.Apple.Impostazioni.Velocita

    var body: some View {
        HStack(spacing: 0) {
            Text(voce)
                .carattereApple(intestazione ? V.intestazione : V.voce)
                .foregroundColor(intestazione ? V.coloreIntestazione : V.coloreVoce)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(valore)
                .carattereApple(intestazione ? V.intestazione : V.cifre)
                .foregroundColor(intestazione ? V.coloreIntestazione : V.coloreCifre)
                .lineLimit(1)
                .frame(width: V.larghezzaColonna, alignment: .trailing)
            if let secondo {
                Text(secondo)
                    .carattereApple(intestazione ? V.intestazione : V.cifre)
                    .foregroundColor(intestazione ? V.coloreIntestazione : V.coloreCifreSecondarie)
                    .lineLimit(1)
                    .frame(width: V.larghezzaColonna, alignment: .trailing)
            }
        }
        .frame(minHeight: V.altezzaRiga)
        .overlay(alignment: .bottom) {
            Rectangle().fill(V.coloreFilo).frame(height: V.filo)
        }
    }
}
#endif
