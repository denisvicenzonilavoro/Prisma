import SwiftUI

// I fogli di Mercato (giro 7): le soglie degli avvisi (il pulsante blu della testata, al posto del «＋ Nuovo avviso»
// del template: gli avvisi nascono dalle soglie dell'utente), l'importazione di un file CSV (Design/mercato-csv.md) e un
// valore scritto a mano. Si chiudono rimettendo `sessioneMercato.foglio` a nil (nelle istantanee il foglio è disegnato
// sopra la finestra, non presentato). Valori in Tema.Apple+Mercato.swift.

/// Le cinque soglie degli avvisi, con titolo, spiegazione, unità e decimali.
enum SogliaMercato: String, CaseIterable, Identifiable {
    case calo, distanza, cedola, indici, tassi

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .calo: return TestiAppMercato.caloDalMassimo
        case .distanza: return TestiAppMercato.distanza
        case .cedola: return TestiAppMercato.cedola
        case .indici: return TestiAppMercato.variazioneIndici
        case .tassi: return TestiAppMercato.variazioneTassi
        }
    }

    var spiegazione: String {
        switch self {
        case .calo: return TestiAppMercato.caloDalMassimoSpiegazione
        case .distanza: return TestiAppMercato.distanzaSpiegazione
        case .cedola: return TestiAppMercato.cedolaSpiegazione
        case .indici: return TestiAppMercato.variazioneIndiciSpiegazione
        case .tassi: return TestiAppMercato.variazioneTassiSpiegazione
        }
    }

    var unita: String {
        switch self {
        case .calo, .indici: return "%"
        case .distanza, .tassi: return TestiAppMercato.unitaPunti
        case .cedola: return TestiAppMercato.unitaGiorni
        }
    }

    var decimali: Int {
        switch self {
        case .cedola: return 0
        case .tassi: return 2
        default: return 1
        }
    }
}

extension StatoShell {
    /// Il valore di una soglia: vuoto = nil (nessun avviso). Cambiandolo gli avvisi si ricalcolano.
    func legameSogliaMercato(_ s: SogliaMercato) -> Binding<Double?> {
        Binding<Double?>(
            get: {
                let m = self.dati.impostazioni.mercato
                switch s {
                case .calo: return m.caloDalMassimo
                case .distanza: return m.distanzaDalRiferimento
                case .cedola: return m.giorniCedola.map(Double.init)
                case .indici: return m.variazioneIndici
                case .tassi: return m.variazioneTassi
                }
            },
            set: { nuovo in
                // Una soglia zero o negativa resta spenta, come nella lettura dell'archivio
                let v = nuovo.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
                self.impostaSogliaMercato { m in
                    switch s {
                    case .calo: m.caloDalMassimo = v
                    case .distanza: m.distanzaDalRiferimento = v
                    case .cedola: m.giorniCedola = v.map { Int($0.rounded()) }.flatMap { $0 > 0 ? $0 : nil }
                    case .indici: m.variazioneIndici = v
                    case .tassi: m.variazioneTassi = v
                    }
                }
            })
    }
}

/// Un campo numerico: il valore (vuoto = nil) e l'unità accanto, cifre all'italiana.
struct CampoNumeroMercato: View {
    let unita: String
    let decimali: Int
    @Binding var valore: Double?

    var body: some View {
        let k = Tema.Apple.Mercato.Impostazioni.self
        HStack(spacing: k.spazio) {
            TextField("", value: $valore, format: formato, prompt: Text(verbatim: TestiAppMercato.senzaValore))
                .campoTesto()
                .multilineTextAlignment(.trailing)
                .frame(width: k.larghezzaCampo)
            Text(unita)
                .carattereApple(k.unita)
                .foregroundColor(k.coloreUnita)
                .lineLimit(1)
        }
    }

    private var formato: FloatingPointFormatStyle<Double> {
        FloatingPointFormatStyle<Double>.number.locale(Formati.localeImporti).precision(.fractionLength(0...max(0, decimali)))
    }
}

/// Il foglio aperto.
struct FoglioMercatoVista: View {
    @Environment(StatoShell.self) var stato
    let foglio: FoglioMercato

    var body: some View {
        let _ = ContaCorpi.segna()
        let f = Tema.Apple.Mercato.Foglio.self
        Group {
            switch foglio {
            case .soglie: FoglioSoglieMercato()
            case .importa: FoglioImportaMercato(sessione: stato.sessioneMercato)
            case .aMano: FoglioAManoMercato()
            }
        }
        .padding(f.padding)
        .frame(width: f.larghezza, alignment: .topLeading)
    }
}

/// Il titolo e la spiegazione in cima a un foglio.
private struct TestataFoglioMercato: View {
    let titolo: String
    let testo: String

    var body: some View {
        let f = Tema.Apple.Mercato.Foglio.self
        VStack(alignment: .leading, spacing: f.spazioCampo) {
            Text(titolo)
                .carattereApple(f.titolo)
                .foregroundColor(f.coloreTitolo)
            Text(testo)
                .carattereApple(f.testo)
                .foregroundColor(f.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Un campo con l'etichetta sopra.
private struct CampoFoglioMercato<Contenuto: View>: View {
    let etichetta: String
    @ViewBuilder let contenuto: () -> Contenuto

    var body: some View {
        let f = Tema.Apple.Mercato.Foglio.self
        VStack(alignment: .leading, spacing: f.spazioCampo) {
            Text(etichetta)
                .carattereApple(f.etichetta)
                .foregroundColor(f.coloreEtichetta)
            contenuto()
        }
    }
}

// MARK: - Soglie

struct FoglioSoglieMercato: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        let f = Tema.Apple.Mercato.Foglio.self
        VStack(alignment: .leading, spacing: f.spazio) {
            TestataFoglioMercato(titolo: TestiAppMercato.soglieGruppo, testo: TestiAppMercato.soglieNota)
            ForEach(SogliaMercato.allCases) { s in
                HStack(alignment: .center, spacing: f.spazio) {
                    VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.sottoTitolo) {
                        Text(s.titolo)
                            .carattereApple(Tema.Apple.Impostazioni.Riga.titolo)
                            .foregroundColor(Tema.Apple.Impostazioni.Riga.coloreTitolo)
                        Text(s.spiegazione)
                            .carattereApple(f.testo)
                            .foregroundColor(f.coloreTesto)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: f.spazio)
                    CampoNumeroMercato(unita: s.unita, decimali: s.decimali, valore: stato.legameSogliaMercato(s))
                        .disabled(!stato.mercatoModificabile)
                }
            }
            HStack {
                Spacer(minLength: 0)
                Button(TestiAppMercato.fine) { stato.sessioneMercato.foglio = nil }
                    .buttonStyle(.applePrimario)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}

// MARK: - Importazione di un file

struct FoglioImportaMercato: View {
    @Environment(StatoShell.self) var stato
    let sessione: SessioneMercato

    @State private var fonte = ""
    @State private var nome = ""
    @State private var tipo = TipoSerieMercato.indiceAzionario
    @State private var unita = UnitaMercato.punti
    @State private var frequenza = FrequenzaMercato.giornaliera

    var body: some View {
        let _ = ContaCorpi.segna()
        let f = Tema.Apple.Mercato.Foglio.self
        VStack(alignment: .leading, spacing: f.spazio) {
            TestataFoglioMercato(titolo: TestiAppMercato.importaTitolo, testo: TestiAppMercato.importaSpiegazione)
            if let i = sessione.importazione {
                lettura(i)
            } else {
                #if os(macOS)
                Button(TestiAppMercato.scegliFile) { stato.scegliFileMercato() }
                    .buttonStyle(.apple)
                #endif
            }
            HStack(spacing: f.spazio) {
                Spacer(minLength: 0)
                Button(TestiAppMercato.annulla) { chiudi() }
                    .buttonStyle(.apple)
                    .keyboardShortcut(.cancelAction)
                Button(TestiAppMercato.registra) { registra() }
                    .buttonStyle(.applePrimario)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!pronto)
            }
        }
    }

    private func lettura(_ i: ImportazioneMercatoInAttesa) -> some View {
        let f = Tema.Apple.Mercato.Foglio.self
        let e = i.esito
        return VStack(alignment: .leading, spacing: f.spazio) {
            Text(i.file + " · " + TestiAppMercato.letti(e.valoriLetti, righe: e.righe))
                .carattereApple(f.etichetta)
                .foregroundColor(f.coloreTitolo)
            if !e.errori.isEmpty {
                VStack(alignment: .leading, spacing: f.spazioRighe) {
                    ForEach(Array(e.errori.prefix(f.righeErroriMassime).enumerated()), id: \.offset) { _, err in
                        Text(TestiAppMercato.erroreRiga(err))
                            .carattereApple(f.errore)
                            .foregroundColor(f.coloreErrore)
                            .lineLimit(1)
                    }
                }
            }
            CampoFoglioMercato(etichetta: TestiAppMercato.fonteFile) {
                TextField("", text: $fonte, prompt: Text(TestiAppMercato.fonteFileAiuto))
                    .campoTesto()
            }
            if e.forma == .serie {
                CampoFoglioMercato(etichetta: TestiAppMercato.nomeSerie) {
                    TextField("", text: $nome)
                        .campoTesto()
                }
                HStack(alignment: .top, spacing: f.spazio) {
                    CampoFoglioMercato(etichetta: TestiAppMercato.tipoSerie) {
                        Picker("", selection: $tipo) {
                            ForEach(TipoSerieMercato.allCases, id: \.self) { Text(TestiAppMercato.nomeTipo($0)).tag($0) }
                        }
                        .labelsHidden()
                    }
                    CampoFoglioMercato(etichetta: TestiAppMercato.unitaSerie) {
                        Picker("", selection: $unita) {
                            ForEach(UnitaMercato.allCases, id: \.self) { Text(TestiAppMercato.nomeUnita($0)).tag($0) }
                        }
                        .labelsHidden()
                    }
                    CampoFoglioMercato(etichetta: TestiAppMercato.frequenzaSerie) {
                        Picker("", selection: $frequenza) {
                            ForEach(FrequenzaMercato.allCases, id: \.self) { Text(TestiAppMercato.nomeFrequenza($0)).tag($0) }
                        }
                        .labelsHidden()
                    }
                }
            }
        }
    }

    private var pronto: Bool {
        guard !stato.solaLettura, let i = sessione.importazione, i.esito.valoriLetti > 0,
              !fonte.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return i.esito.forma == .quote || !nome.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func registra() {
        guard pronto, let i = sessione.importazione else { return }
        let n = stato.registraImportazioneMercato(i.esito, fonte: fonte, nome: nome, tipo: tipo, unita: unita, frequenza: frequenza)
        chiudi()
        stato.mostraAvviso(n > 0 ? TestiAppMercato.registrati(n) : TestiAppMercato.nienteDaRegistrare)
    }

    private func chiudi() {
        sessione.importazione = nil
        sessione.foglio = nil
    }
}

// MARK: - A mano

struct FoglioAManoMercato: View {
    @Environment(StatoShell.self) var stato

    private enum Cosa: Hashable { case serie, quota }

    @State private var cosa = Cosa.serie
    @State private var serie = ""
    @State private var isin = ""
    @State private var data = Formati.dataBreve.string(from: Date())
    @State private var valore = ""
    @State private var fonte = ""
    @State private var errore = false

    var body: some View {
        let f = Tema.Apple.Mercato.Foglio.self
        let elenco = serieDisponibili
        VStack(alignment: .leading, spacing: f.spazio) {
            TestataFoglioMercato(titolo: TestiAppMercato.manoTitolo, testo: TestiAppMercato.datiNota)
            SegmentatoPillola(selezione: $cosa, voci: [(Cosa.serie, TestiAppMercato.manoSerie), (Cosa.quota, TestiAppMercato.manoQuota)])
                .fixedSize()
            if cosa == .serie {
                CampoFoglioMercato(etichetta: TestiAppMercato.nomeSerie) {
                    Picker("", selection: $serie) {
                        ForEach(elenco) { Text($0.nome).tag($0.id) }
                    }
                    .labelsHidden()
                }
            } else {
                CampoFoglioMercato(etichetta: TestiAppMercato.isin) {
                    TextField("", text: $isin, prompt: Text(TestiAppMercato.isinInvito))
                        .campoTesto()
                }
            }
            HStack(alignment: .top, spacing: f.spazio) {
                CampoFoglioMercato(etichetta: TestiAppMercato.data) {
                    TextField("", text: $data, prompt: Text(verbatim: "gg/mm/aaaa"))
                        .campoTesto()
                }
                CampoFoglioMercato(etichetta: TestiAppMercato.valore) {
                    TextField("", text: $valore)
                        .campoTesto()
                }
            }
            CampoFoglioMercato(etichetta: TestiAppMercato.fonteFile) {
                TextField("", text: $fonte, prompt: Text(TestiAppMercato.fonteFileAiuto))
                    .campoTesto()
            }
            if errore {
                Text(cosa == .quota ? TestiMercato.isinNonValido + " " + TestiAppMercato.valoreNonValido : TestiAppMercato.valoreNonValido)
                    .carattereApple(f.errore)
                    .foregroundColor(f.coloreErrore)
            }
            HStack(spacing: f.spazio) {
                Spacer(minLength: 0)
                Button(TestiAppMercato.annulla) { stato.sessioneMercato.foglio = nil }
                    .buttonStyle(.apple)
                    .keyboardShortcut(.cancelAction)
                Button(TestiAppMercato.registra) { registra() }
                    .buttonStyle(.applePrimario)
                    .keyboardShortcut(.defaultAction)
                    .disabled(stato.solaLettura || valore.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear { if serie.isEmpty { serie = elenco.first?.id ?? "" } }
    }

    /// Le serie a cui aggiungere un valore: quelle dell'archivio e quelle della configurazione.
    private var serieDisponibili: [VoceSerieMercato] {
        var elenco = stato.dati.mercato.serie.map { VoceSerieMercato(id: $0.id, nome: $0.nome) }
        for s in stato.sessioneMercato.configurazione?.serie ?? [] where !elenco.contains(where: { $0.id == s.id }) {
            elenco.append(VoceSerieMercato(id: s.id, nome: s.nome))
        }
        return elenco
    }

    private func registra() {
        let fatto: Bool
        switch cosa {
        case .serie: fatto = stato.registraValoreAMano(serie: serie, data: data, valore: valore, fonte: fonte)
        case .quota: fatto = stato.registraQuotaAMano(isin: isin, data: data, valore: valore, fonte: fonte)
        }
        guard fatto else {
            errore = true
            return
        }
        stato.sessioneMercato.foglio = nil
        stato.mostraAvviso(TestiAppMercato.registrati(1))
    }
}

/// Una serie da scegliere nel foglio del valore a mano.
struct VoceSerieMercato: Identifiable, Hashable {
    let id: String
    let nome: String
}
