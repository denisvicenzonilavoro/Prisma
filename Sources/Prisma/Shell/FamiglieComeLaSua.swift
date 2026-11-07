import SwiftUI

// Analisi 360 › «Rispetto alle famiglie come la sua» (Orizzonte, giro 6; Design/template-novita-specifica.md §10,
// template `famHTML`/`montaFam`):
//
//   [Le quattro aree | Rispetto alle famiglie come la sua]
//   ┌ card ────────────────────────────────────────────────────────────────────────────────────────────┐
//   │ Le famiglie con capofamiglia della sua età risparmiano in media il 28,7% del reddito; Giulia il 15,0%. │
//   │ A confronto con le famiglie con capofamiglia tra i 35 e i 44 anni (860 nel campione) e con le …  │
//   └──────────────────────────────────────────────────────────────────────────────────────────────────┘
//   ┌ RISPARMIO                                                                       Giulia 15,0% ┐
//   │ Capofamiglia tra i 35 e i 44 anni   28,7% sotto │ 4° quinto di reddito        31,3% sotto      │
//   │ ░░░(GR)▒▒▒▒▒|▓▓▓▓▓▓▓▓▓░░░                        │ ░░(GR)▒▒▒▒▒▒|▓▓▓▓▓▓▓▓░░░                 │
//   │        media del gruppo                          │       media del gruppo                    │
//   │ Con il 15,0% del reddito risparmiato sta sotto … │ …                                         │
//   │ È un rapporto tra medie: …                                                                     │
//   └────────────────────────────────────────────────────────────────────────────────────────────────┘
//   (patrimonio finanziario, ricchezza netta con «Tutte le famiglie italiane» e i decimi, polizze vita,
//   pensioni integrative)
//   Fonte: Banca d'Italia, … edizione 2022 (…). Le tavole danno una caratteristica alla volta … / avvisi
//
// - Le cifre vengono da MotoreFamiglie sulle tabelle in uso (`StatoShell.tabelleFamiglie`: quelle caricate da
//   Impostazioni o, senza, le tavole pubblicate dalla Banca d'Italia incluse, `Risorse/famiglie-bdi-2022.json`). Le
//   tavole sono a una dimensione: il confronto è doppio, con le famiglie della sua età e con quelle del suo quinto di
//   reddito, e dove c'è solo mediana, media o quota la barra non inventa percentili (`BarraFamiglie`). Un file nella
//   forma della versione 1 (celle età × reddito) si vede come nel template, con la griglia 2 × 2. Se il file in uso è
//   «di prova» l'etichetta «Dati di prova…» accanto al segmentato e la nota lo dicono in chiaro.
// - Movimento: cascata (card principale, voci, nota), cifre che si contano, avatar che scorrono dalla parte rossa al
//   loro posto con la molla. «Riduci movimento» e istantanee: tutto già al suo posto.
// - Prestazioni: la vista è `Equatable` sulla chiave dei dati e sul cliente (StatoShell pubblica spesso).
// Valori in DesignSystem/Apple/Tema.Apple+Famiglie.swift, testi in Motori/TestiFamiglieVista.swift.

// MARK: - La vista della panoramica

/// Le due viste della panoramica di Analisi 360 (segmentato sotto la testata).
enum VistaAnalisi360: Hashable {
    case aree, famiglie

    var titolo: String {
        switch self {
        case .aree: return TestiFamiglie.segmentoAree
        case .famiglie: return TestiFamiglie.segmentoFamiglie
        }
    }
}

extension StatoShell {
    /// Analisi 360 sulla vista «Rispetto alle famiglie come la sua» (dal pannello Novità e dalle istantanee).
    func apriFamiglieComeLaSua() {
        if areaAnalisi != nil { areaAnalisi = nil }
        scegliStrumentoAnalisi(nil)
        if vistaAnalisi360 != .famiglie { vistaAnalisi360 = .famiglie }
        apri(.analisi360)
    }

    /// Impostazioni › Rendimenti di confronto, sul gruppo «Famiglie italiane» (dall'etichetta dei dati di prova e da
    /// «Carica le tabelle in Impostazioni ›»).
    func apriImpostazioniFamiglie() {
        schedaImpostazioni = .rendimenti
        ancoraImpostazioni = TestiFamiglie.ancoraImpostazioni
        apri(.impostazioni)
    }
}

/// La riga sotto la testata di Analisi 360: il segmentato delle due viste e, se il file in uso è di prova (caricato
/// da Impostazioni), l'etichetta che lo dice (un clic porta alle Impostazioni, non in modalità cliente).
struct RigaVisteAnalisi360: View {
    @Binding var vista: VistaAnalisi360
    let diProva: Bool
    let modoCliente: Bool
    let apriImpostazioni: () -> Void

    var body: some View {
        let f = Tema.Apple.Famiglie.self
        return HStack(alignment: .center, spacing: f.spazioRigaVista) {
            SegmentatoPillola(selezione: $vista, voci: [(.aree, VistaAnalisi360.aree.titolo),
                                                        (.famiglie, VistaAnalisi360.famiglie.titolo)])
                .fixedSize()
            if diProva && vista == .famiglie {
                if modoCliente {
                    etichetta
                } else {
                    Button(action: apriImpostazioni) { etichetta }
                        .buttonStyle(.plain)
                        .help(TestiFamiglie.aiutoEtichettaDiProva)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var etichetta: some View {
        let f = Tema.Apple.Famiglie.self
        return HStack(spacing: f.spazioSimboloProva) {
            Image(systemName: f.simboloProva)
            Text(TestiFamiglie.etichettaDiProva)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .carattereApple(f.etichettaProva)
        .foregroundColor(f.coloreEtichettaProva)
        .padding(f.paddingEtichettaProva)
        .background(Capsule(style: .continuous).fill(f.fondoEtichettaProva))
        .overlay(Capsule(style: .continuous).strokeBorder(f.bordoEtichettaProva, lineWidth: Tema.Apple.Misura.bordo))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Rispetto alle famiglie come la sua

/// La vista «Rispetto alle famiglie come la sua» per un cliente: card della frase grande, le voci e la nota.
struct FamiglieComeLaSuaApple: View, Equatable {
    let stato: StatoShell
    let clienteId: String
    let chiave: ChiaveVista
    /// Base della cascata: quella della finestra all'apertura, 0 dopo un cambio.
    let base: Double

    nonisolated static func == (a: FamiglieComeLaSuaApple, b: FamiglieComeLaSuaApple) -> Bool {
        a.clienteId == b.clienteId && a.chiave == b.chiave && a.base == b.base
    }

    var body: some View {
        let f = Tema.Apple.Famiglie.self
        let t = Tema.Apple.Famiglie.Tempi.self
        let cliente = stato.cliente(clienteId)
        let nome = cliente.map(StatoShell.nomeBreve) ?? "il cliente"
        let confronto = stato.confrontoFamiglie(clienteId)
        return VStack(alignment: .leading, spacing: 0) {
            if let c = confronto, c.haConfronto {
                principale(c, nome: nome)
                    .entrataCascata(t.indicePrincipale, base: base)
                griglia(c, nome: nome, cliente: cliente)
                    .padding(.top, f.sopraGriglia)
            } else {
                senzaConfronto(confronto, nome: nome)
                    .entrataCascata(t.indicePrincipale, base: base)
            }
            nota(confronto)
                .padding(.top, f.sopraNota)
                .entrataCascata(t.indiceNota, base: base)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var modoCliente: Bool { chiave.modo != nil }

    // MARK: La card principale

    private func principale(_ c: ConfrontoFamiglie, nome: String) -> some View {
        let f = Tema.Apple.Famiglie.self
        let sottotitolo = c.unaDimensione ? TestiFamiglie.sottotitoloGruppi(c)
            : TestiFamiglie.sottotitoloGruppo(eta: c.classeEta, reddito: c.classeReddito, famiglie: c.famiglieNellaCella)
        return VStack(alignment: .leading, spacing: 0) {
            frase(c, nome: nome)
                .carattereApple(f.frase)
                .foregroundColor(f.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: f.larghezzaFraseMax, alignment: .leading)
            if !sottotitolo.isEmpty {
                Text(sottotitolo)
                    .carattereApple(f.sottotitolo)
                    .foregroundColor(f.coloreSottotitolo)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, f.sopraSottotitolo)
            }
        }
        .padding(f.paddingPrincipale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(f.superficie, raggio: f.raggio)
        .accessibilityElement(children: .combine)
    }

    /// La frase grande: sempre il risparmio. Con i quantili la percentuale delle famiglie che si conta in blu; con le
    /// tavole a una dimensione il risparmio del gruppo della sua età (o del suo quinto) che si conta, e quello del
    /// cliente accanto.
    @ViewBuilder private func frase(_ c: ConfrontoFamiglie, nome: String) -> some View {
        let f = Tema.Apple.Famiglie.self
        let v = c.voce(.tassoRisparmio, ambito: .eta) ?? c.voce(.tassoRisparmio, ambito: .reddito) ?? c.voce(.tassoRisparmio)
        if let v, let p = v.percentile, v.metodo == .quantili {
            let ridotto = c.gruppo(v.ambito)?.campioneRidotto ?? false
            let parti = TestiFamiglie.fraseGrande(nome: nome, percentile: p, ridotto: ridotto, ambito: v.ambito)
            FraseCifraFamiglie(prima: parti.prima, numero: Double(parti.numero), dopo: parti.dopo, colore: f.cifraPrincipale,
                               indice: Tema.Apple.Famiglie.Tempi.indiceCifraPrincipale)
        } else if c.unaDimensione, let v, let g = v.riferimento, v.tipoGruppo != .quantili {
            let parti = TestiFamiglie.fraseGrandeValore(nome: nome, ambito: v.ambito, metodo: v.tipoGruppo, gruppo: g,
                                                        cliente: v.valoreCliente)
            FraseCifraFamiglie(prima: parti.prima, numero: parti.numero, dopo: parti.dopo, colore: f.cifraPrincipale,
                               formato: TestiFamiglie.formatoTasso, indice: Tema.Apple.Famiglie.Tempi.indiceCifraPrincipale)
        } else if let v, let sopra = v.sopra {
            Text(TestiFamiglie.fraseGrandeSenzaCifra(nome: nome, sopra: sopra, metodo: v.metodo))
        } else {
            Text(TestiFamiglie.fraseGrandeSenzaRisparmio(nome: nome))
        }
    }

    // MARK: Le voci

    /// Versione 1: griglia 2 × 2 delle voci della cella. Tavole a una dimensione: una card per voce a tutta larghezza,
    /// con i gruppi uno accanto all'altro.
    private func griglia(_ c: ConfrontoFamiglie, nome: String, cliente: Cliente?) -> some View {
        let f = Tema.Apple.Famiglie.self
        let voci = c.voci
        let colonne = c.unaDimensione ? f.colonneUnaDimensione : f.colonneCella
        let righe = Array(stride(from: 0, to: voci.count, by: colonne))
        return VStack(spacing: f.spazioGriglia) {
            ForEach(righe, id: \.self) { inizio in
                HStack(alignment: .top, spacing: f.spazioGriglia) {
                    ForEach(inizio..<min(inizio + colonne, voci.count), id: \.self) { i in
                        cardVoce(voci[i], indice: i, c, nome: nome, cliente: cliente)
                    }
                    // Un'ultima riga con una card sola resta a metà larghezza
                    if colonne > 1, inizio + colonne > voci.count {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
                // Le card di una riga alte uguali
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder private func cardVoce(_ v: VoceFamiglie, indice i: Int, _ c: ConfrontoFamiglie, nome: String,
                                       cliente: Cliente?) -> some View {
        let t = Tema.Apple.Famiglie.Tempi.self
        let gruppi = c.gruppi.filter { $0.voce(v) != nil }
        if !gruppi.isEmpty {
            CardVoceFamiglie(voce: v, gruppi: gruppi, nome: nome, indice: i, iniziali: cliente?.iniziali ?? "",
                             tinta: (cliente?.tinta ?? .blu).colori, completa: azioneCompleta(c.confronti(v)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .entrataCascata(t.indicePrimaVoce + min(i, t.ultimaVoce), base: base)
        }
    }

    /// «Completa nella scheda del cliente ›» quando manca la cifra del cliente (non la voce nelle tabelle), mai in
    /// modalità cliente.
    private func azioneCompleta(_ confronti: [ConfrontoVoceFamiglie]) -> (() -> Void)? {
        let manca = confronti.contains { $0.metodo == .nessuno && $0.frase == TestiFamiglie.manca($0.voce) }
        guard manca, !modoCliente else { return nil }
        let stato = self.stato
        let id = clienteId
        return { stato.apriCliente(id) }
    }

    // MARK: Senza confronto

    /// Senza età né reddito (o senza un gruppo per loro, o senza tabelle leggibili): la frase al posto della card
    /// principale e il pulsante per completare il dossier o caricare le tabelle.
    private func senzaConfronto(_ c: ConfrontoFamiglie?, nome: String) -> some View {
        let f = Tema.Apple.Famiglie.self
        let mancanoDati = c?.avvisi.contains(TestiFamiglie.servonoEtaReddito) ?? false
        let testo: String
        if c == nil {
            testo = TestiFamiglie.senzaTabelle
        } else if mancanoDati {
            testo = TestiFamiglie.servonoEtaRedditoDi(nome)
        } else {
            testo = TestiFamiglie.cellaNonTrovata
        }
        let id = clienteId
        let stato = self.stato
        return VStack(alignment: .leading, spacing: 0) {
            Text(testo)
                .carattereApple(f.frase)
                .foregroundColor(f.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: f.larghezzaFraseMax, alignment: .leading)
            if !modoCliente && (c == nil || mancanoDati) {
                Button {
                    if c == nil { stato.apriImpostazioniFamiglie() } else { stato.apriCliente(id) }
                } label: {
                    Text(c == nil ? TestiFamiglie.caricaInImpostazioni : TestiFamiglie.completaNellaScheda)
                }
                .buttonStyle(.apple)
                .padding(.top, f.sopraPulsante)
            }
        }
        .padding(f.paddingPrincipale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(f.superficie, raggio: f.raggio)
    }

    // MARK: Nota

    /// Dati di prova: lo dice in chiaro. Tabelle vere: fonte ed edizione (e la data del caricamento se il file è
    /// caricato), in piccolo; con le tavole a una dimensione perché i confronti sono due. Sotto, le avvertenze del
    /// confronto che non stanno già altrove (età o reddito mancanti, quinti del 2022, capofamiglia).
    private func nota(_ c: ConfrontoFamiglie?) -> some View {
        let f = Tema.Apple.Famiglie.self
        var righe: [String] = []
        if let c {
            righe.append(c.diProva ? TestiFamiglie.notaDiProva
                         : TestiFamiglie.notaFonte(c.fonte, edizione: c.edizione, caricateIl: stato.dati.famiglie?.caricateIl))
            if c.unaDimensione && c.haConfronto { righe.append(TestiFamiglie.notaUnaDimensione) }
            let gia: Set<String> = [TestiFamiglie.avvisoDiProva, TestiFamiglie.servonoEtaReddito, TestiFamiglie.cellaNonTrovata]
            righe += c.avvisi.filter { !gia.contains($0) }
        }
        return VStack(alignment: .leading, spacing: f.spazioNote) {
            ForEach(Array(righe.enumerated()), id: \.offset) { _, r in
                Text(r)
                    .carattereApple(f.nota)
                    .foregroundColor(f.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Card di una voce

/// Una voce: l'etichetta e la cifra del cliente; poi un gruppo accanto all'altro (la cella sola nella versione 1; età,
/// quinto di reddito e tutte le famiglie con le tavole a una dimensione), ciascuno con la sua etichetta e il suo valore,
/// la barra con l'avatar e la frase; sotto, le cautele (una volta sola) e, se manca la cifra del cliente, «Completa
/// nella scheda del cliente ›». Niente inclinazione né clic.
private struct CardVoceFamiglie: View {
    let voce: VoceFamiglie
    let gruppi: [GruppoConfrontoFamiglie]
    let nome: String
    /// Ordine della voce nella pagina.
    let indice: Int
    let iniziali: String
    let tinta: Colori.Avatar.Tinta
    let completa: (() -> Void)?

    private var confronti: [ConfrontoVoceFamiglie] { gruppi.compactMap { $0.voce(voce) } }
    /// Versione 1: la sola cella, come nel template (la percentuale in testa).
    private var soloCella: Bool { gruppi.count == 1 && gruppi.first?.ambito == .cella }

    var body: some View {
        let f = Tema.Apple.Famiglie.self
        let cautele = confronti.flatMap(\.cautele).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: f.spazioRigaVoce) {
                Text(TestiFamiglie.nome(voce))
                    .carattereApple(f.etichetta)
                    .foregroundColor(f.coloreEtichetta)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                if soloCella, let c = confronti.first {
                    cifraCella(c)
                } else {
                    cifraCliente
                }
            }
            HStack(alignment: .top, spacing: f.spazioGruppi) {
                ForEach(Array(gruppi.enumerated()), id: \.element.id) { k, g in
                    if let c = g.voce(voce) {
                        riga(c, gruppo: g, ordine: indice + k)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
            .padding(.top, soloCella ? 0 : f.sopraGruppi)
            if !cautele.isEmpty {
                VStack(alignment: .leading, spacing: f.spazioCautele) {
                    ForEach(Array(cautele.enumerated()), id: \.offset) { _, c in
                        Text(c)
                            .carattereApple(f.cautela)
                            .foregroundColor(f.coloreCautela)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, f.sopraCautele)
            }
            if let completa {
                Button(action: completa) { Text(TestiFamiglie.completaNellaScheda) }
                    .buttonStyle(.appleSobrio)
                    .padding(.top, f.sopraCompleta)
            }
            Spacer(minLength: 0)
        }
        .padding(f.paddingVoce)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(f.superficie, raggio: f.raggio)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(testoAccessibilita))
    }

    /// Per VoiceOver: una frase per gruppo, con l'etichetta del gruppo.
    private var testoAccessibilita: String {
        var frasi: [String] = []
        for g in gruppi {
            guard let c = g.voce(voce) else { continue }
            frasi.append(TestiFamiglie.accessibilitaVoce(c, gruppo: TestiFamiglie.etichettaGruppo(g)))
        }
        return frasi.joined(separator: " ")
    }

    /// Un gruppo: l'etichetta e il valore del gruppo (con «sopra» / «sotto», o la percentuale con i quantili), la barra
    /// e la frase.
    private func riga(_ c: ConfrontoVoceFamiglie, gruppo g: GruppoConfrontoFamiglie, ordine: Int) -> some View {
        let f = Tema.Apple.Famiglie.self
        return VStack(alignment: .leading, spacing: 0) {
            if let etichetta = TestiFamiglie.etichettaGruppo(g) {
                HStack(alignment: .firstTextBaseline, spacing: f.spazioValoreGruppo) {
                    Text(etichetta)
                        .carattereApple(f.etichettaGruppo)
                        .foregroundColor(f.coloreEtichettaGruppo)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    valoreGruppo(c, ordine: ordine)
                }
            }
            if let b = c.barra {
                BarraDistribuzione(posizione: b.cliente, tacca: b.tacca, scrittaTacca: TestiFamiglie.scrittaTacca(c),
                                   quartili: b.quantili, parteCentrale: b.parteCentrale,
                                   iniziali: iniziali, tinta: tinta, indice: ordine)
                    .padding(.top, f.sopraBarra)
            }
            Text(c.frase)
                .carattereApple(f.fraseVoce)
                .foregroundColor(f.coloreFraseVoce)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, c.barra == nil ? f.sopraCautele : f.sopraFrase)
        }
    }

    /// A destra dell'etichetta del gruppo: la percentuale con i quantili, altrimenti il valore del gruppo e «sopra» /
    /// «sotto».
    @ViewBuilder private func valoreGruppo(_ c: ConfrontoVoceFamiglie, ordine: Int) -> some View {
        let f = Tema.Apple.Famiglie.self
        if let p = c.percentile, c.metodo == .quantili {
            NumeroCheConta(Double(p), formato: .percentuale, indice: Tema.Apple.Famiglie.Tempi.indicePrimaVoce + ordine)
                .carattereApple(f.valoreGruppo)
                .foregroundColor(f.soglia(p))
                .fixedSize()
        } else {
            HStack(alignment: .firstTextBaseline, spacing: f.spazioCirca) {
                if let testo = TestiFamiglie.valoreGruppo(c) {
                    Text(testo)
                        .carattereApple(f.valoreGruppo)
                        .foregroundColor(f.coloreValoreGruppo)
                }
                if c.metodo != .quota, let parola = TestiFamiglie.parolaVoce(c), let sopra = c.sopra {
                    Text(parola)
                        .carattereApple(f.circa)
                        .foregroundColor(f.tono(sopra))
                }
            }
            .fixedSize()
        }
    }

    /// Tavole a una dimensione: la cifra del cliente in testa, con il nome davanti («Giulia 15,0%»; «sì» / «no» con la
    /// quota; «—» se manca).
    @ViewBuilder private var cifraCliente: some View {
        let f = Tema.Apple.Famiglie.self
        let c = confronti.first { $0.valoreCliente != nil }
        HStack(alignment: .firstTextBaseline, spacing: f.spazioCirca) {
            Text(nome)
                .carattereApple(f.nomeCliente)
                .foregroundColor(f.coloreNomeCliente)
                .lineLimit(1)
            if let c, let x = c.valoreCliente, c.metodo != .quota {
                NumeroCheConta(x, formato: voce == .tassoRisparmio ? TestiFamiglie.formatoTasso : .euro,
                               indice: Tema.Apple.Famiglie.Tempi.indicePrimaVoce + indice)
                    .carattereApple(f.parolaVoce)
                    .foregroundColor(f.coloreFrase)
            } else if let c, let sopra = c.sopra {
                Text(TestiFamiglie.valoreCliente(confronti))
                    .carattereApple(f.parolaVoce)
                    .foregroundColor(f.tono(sopra))
            } else {
                Text(TestiFamiglie.cifraMancante)
                    .carattereApple(f.parolaVoce)
                    .foregroundColor(f.coloreMancante)
            }
        }
        .fixedSize()
    }

    /// Versione 1: la percentuale che si conta (con «circa» per il campione piccolo), la parola o il trattino.
    @ViewBuilder private func cifraCella(_ c: ConfrontoVoceFamiglie) -> some View {
        let f = Tema.Apple.Famiglie.self
        let ridotto = gruppi.first?.campioneRidotto ?? false
        if let p = c.percentile, c.metodo == .quantili {
            HStack(alignment: .firstTextBaseline, spacing: f.spazioCirca) {
                if ridotto {
                    Text(TestiFamiglie.circa)
                        .carattereApple(f.circa)
                        .foregroundColor(f.coloreCirca)
                }
                NumeroCheConta(Double(p), formato: .percentuale, indice: Tema.Apple.Famiglie.Tempi.indicePrimaVoce + indice)
                    .carattereApple(f.percentuale)
                    .foregroundColor(f.soglia(p))
            }
            .fixedSize()
        } else if let parola = TestiFamiglie.parolaVoce(c), let sopra = c.sopra {
            Text(parola)
                .carattereApple(f.parolaVoce)
                .foregroundColor(f.tono(sopra))
                .fixedSize()
        } else {
            Text(TestiFamiglie.cifraMancante)
                .carattereApple(f.percentuale)
                .foregroundColor(f.coloreMancante)
        }
    }
}

// MARK: - La frase con la cifra che si conta

/// Una frase con una cifra dentro (percentuale intera o, con `formato`, per esempio «28,7%») che si conta da 0
/// (quartica, come `NumeroCheConta`) nel colore dato. Il testo resta uno solo, così va a capo come una frase. Nello
/// stato finale la cifra è subito completa. Niente Timer.
struct FraseCifraFamiglie: View {
    let prima: String
    let numero: Double
    let dopo: String
    let colore: Color
    var formato: FormatoCifra = .percentuale
    var indice: Int = 0

    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(\.prismaScatto) private var scatto
    @State private var avanzamento: Double = 0

    init(prima: String, numero: Double, dopo: String, colore: Color, formato: FormatoCifra = .percentuale, indice: Int = 0) {
        self.prima = prima
        self.numero = numero
        self.dopo = dopo
        self.colore = colore
        self.formato = formato
        self.indice = indice
    }

    var body: some View {
        Text(verbatim: "")
            .modifier(TestoFraseCifraFamiglie(prima: prima, numero: numero, dopo: dopo, colore: colore, formato: formato,
                                              avanzamento: fermo ? 1 : avanzamento))
            .onAppear(perform: parti)
            .onChange(of: numero) { _ in riparti() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(prima + formato.testo(numero) + dopo))
    }

    private func parti() {
        // Nelle istantanee la frase è già completa (`fermo`): niente da scrivere
        guard !(fermo && scatto), avanzamento == 0 else { return }
        if fermo {
            avanzamento = 1
            return
        }
        withAnimation(.linear(duration: Tema.Apple.Moto.Numero.durata(indice: indice))) { avanzamento = 1 }
    }

    private func riparti() {
        guard !fermo else { return }
        var senza = Transaction()
        senza.disablesAnimations = true
        withTransaction(senza) { avanzamento = 0 }
        withAnimation(.linear(duration: Tema.Apple.Moto.NumeroCambio.durata)) { avanzamento = 1 }
    }
}

/// Il testo mentre conta: SwiftUI interpola l'avanzamento, la quartica dà il numero del fotogramma.
private struct TestoFraseCifraFamiglie: ViewModifier, Animatable {
    let prima: String
    let numero: Double
    let dopo: String
    let colore: Color
    let formato: FormatoCifra
    var avanzamento: Double

    var animatableData: Double {
        get { avanzamento }
        set { avanzamento = newValue }
    }

    func body(content: Content) -> some View {
        let t = Tema.Apple.Moto.Curva.quartica(avanzamento)
        let cifra = formato.testo(numero * t, finale: numero)
        return Text(verbatim: prima) + Text(verbatim: cifra).foregroundColor(colore) + Text(verbatim: dopo)
    }
}
